# Configuration Validation Checklist

This document captures lessons learned from configuration issues and provides validation steps to run **before** and **after** implementing changes.

## Lessons Learned

### 1. Firewall Rule Ordering (2026-02-21)
**Issue**: Guest VLAN DNS/DHCP allow rules were added after the "Block Guest from router management" drop rule, causing guest clients to timeout on DNS queries.

**Root Cause**: Firewall rules are processed top-to-bottom. Allow rules placed after a drop rule on the same interface are never evaluated.

**Prevention**: Always verify rule ordering after adding firewall rules. Allow rules for specific services must come BEFORE blanket drop rules for the same traffic source.

### 2. Legacy Subnet Overlap During Migration (2026-02-21)
**Issue**: APs remained on old 10.0.0.x addresses while network was migrated to VLAN-based 10.0.10.x addressing, causing devices to be unreachable or routing to fail.

**Root Cause**: Devices with static IPs or long DHCP leases don't automatically move to new subnets. Legacy helper addresses (e.g., 10.0.0.1/16 on ether2) created overlapping routes.

**Prevention**: 
- Before migration, document all devices on legacy subnet
- Plan for device lease renewal or manual IP updates
- Remove legacy interface addresses and DHCP scopes only after all devices migrated
- Use `/ip address print` and `/ip dhcp-server lease print` to verify no devices remain on old subnet

### 3. DHCP Static Reservations Not Immediately Effective (2026-02-21)
**Issue**: After creating DHCP static reservations, devices continued using old dynamic IPs until lease expired or device restarted.

**Root Cause**: DHCP reservations only take effect when a device requests a new lease. Existing leases remain valid until expiration.

**Prevention**:
- After creating reservation, either wait for lease expiry or force renewal on device
- On MikroTik: Can remove the dynamic lease to force re-request
- On client: Release and renew (`ipconfig /release && ipconfig /renew` on Windows, restart network on other devices)

### 4. Device-Specific Firewall Rules Must Reference Static IPs (2026-03-16)
**Issue**: TCL TV on IoT VLAN had no firewall rule allowing Plex access to NAS. It fell back to Plex relay (slow, intermittent). Separately, documentation referenced stale IPs after the 2026-03-14 IP consolidation because firewall rule docs weren't updated alongside the IP changes.

**Root Cause**: The TV was moved to a restricted VLAN (IoT) without creating a static DHCP reservation or a corresponding firewall rule. When device-specific firewall rules reference dynamic IPs, the rules break silently when the IP changes on DHCP renewal.

**Prevention**:
- **Mandatory**: Before creating any device-specific firewall rule, the device MUST have a static DHCP reservation in the .10–.99 range
- **Mandatory**: When changing a static IP, update ALL of: router firewall rules, address lists, `static-ip-assignments.md`, `firewall-rules.md`
- **Mandatory**: When moving a device to a restricted VLAN (IoT, Guest, CCTV), audit what services it needs and create firewall rules BEFORE or AT THE SAME TIME as the VLAN move
- Verify with: `/ip firewall filter print where src-address~"OLD_IP" or dst-address~"OLD_IP"` and `/ip firewall address-list print where address="OLD_IP"`

### 5. Home Assistant Integration IPs Must Be Updated When Device IPs Change (2026-03-20)
**Issue**: After consolidating IoT static IPs from .100–.250 to .10–.99 range on 2026-03-14, all 22 TP-Link/Kasa, LIFX, and Brother Printer devices became `unavailable` in Home Assistant. The integration entries still referenced old IPs.

**Root Cause**: HA integrations that use IP-based config (TP-Link, LIFX, IPP/printers, LinkPlay/WiiM, ESPHome, WLED) store the device IP in `core.config_entries`. When the router DHCP reservation IP changes, HA doesn't automatically discover the new IP.

**Prevention**:
- **Mandatory**: When changing any static IP on the router, also update the corresponding HA integration config entry
- IP-based HA integrations to check: `tplink`, `lifx`, `ipp`, `esphome`, `wled`, `linkplay`
- MQTT-based integrations (Tasmota, Z-Wave) are NOT affected
- To update: edit `/config/.storage/core.config_entries` on HA (back up first!), change the `host` field, restart HA Core
- Add to DHCP Changes checklist below

### 6. RouterOS Script Syntax Errors in SSH Commands (2026-02-21)
**Issue**: Complex multi-line RouterOS commands via SSH failed with cryptic "syntax error" messages or silent failures, especially with variable interpolation.

**Root Cause**: Shell escaping conflicts with RouterOS scripting syntax. Variables like `$gdrop` get interpolated by the local shell before reaching RouterOS.

**Prevention**:
- Use single quotes for SSH command strings to prevent local shell interpolation
- Test complex scripts in WebFig/Winbox terminal first
- Break complex operations into multiple simpler commands
- Use `place-before=N` with numeric position instead of variable references when possible

---

## Pre-Implementation Validations

### Firewall Changes

Before adding INPUT chain rules:
```routeros
# Show current INPUT chain with rule numbers
/ip firewall filter print where chain=input

# Identify drop rules that might block new allow rules
/ip firewall filter print where chain=input and action=drop
```

**Checklist:**
- [ ] Identify existing drop rules for the target interface/source
- [ ] Plan to insert allow rules BEFORE relevant drop rules
- [ ] Use `place-before=` parameter when adding rules

**Checklist (device-specific rules):**
- [ ] Target device has a static DHCP reservation (not dynamic)
- [ ] Static IP is documented in `static-ip-assignments.md`
- [ ] Rule uses the static IP, not a dynamic one

Before adding FORWARD chain rules:
```routeros
# Show current FORWARD chain
/ip firewall filter print where chain=forward

# Check for drop rules that might affect new traffic flows
/ip firewall filter print where chain=forward and action=drop
```

### VLAN/Interface Changes

Before modifying VLAN assignments:
```routeros
# Verify current bridge VLAN configuration
/interface bridge vlan print

# Check port PVID assignments
/interface bridge port print
```

**Checklist:**
- [ ] Document current port assignments before changes
- [ ] Verify DHCP server exists for the target VLAN
- [ ] Confirm firewall rules allow required traffic for the VLAN

### DHCP Changes

Before modifying DHCP:
```routeros
# Show all DHCP servers and their interfaces
/ip dhcp-server print

# Show address pools
/ip pool print

# Show existing leases on target network
/ip dhcp-server lease print where address~"10.0.XX"
```

**Checklist:**
- [ ] Verify pool range doesn't overlap with static assignments
- [ ] Confirm gateway and DNS settings are correct for the VLAN
- [ ] Check for existing static leases that might conflict
- [ ] New static reservations MUST use .10–.99 range (see convention in `docs/static-ip-assignments.md`)
- [ ] After any static reservation add/remove/change, update `docs/static-ip-assignments.md` and its snapshot date
- [ ] Check firewall rules and address lists for any references to the old IP that need updating
- [ ] **Check Home Assistant integration config entries** for references to the old IP (`tplink`, `lifx`, `ipp`, `esphome`, `wled`, `linkplay`). Update `/config/.storage/core.config_entries` and restart HA Core if needed.
- [ ] **Audit firewall rules and address lists** for references to the old IP: `/ip firewall filter print where src-address~"OLD_IP" or dst-address~"OLD_IP"` and `/ip firewall address-list print where address="OLD_IP"`. Update any matches.

> **These last three checklist items (docs, HA, firewall) are MANDATORY after ANY static IP change — do not wait to be asked.**

---

## Post-Implementation Validations

### After Firewall Changes

```routeros
# Verify no rules are marked invalid (I flag)
/ip firewall filter print where invalid

# Confirm rule ordering - allow rules before drops
/ip firewall filter print where chain=input

# Test connectivity from affected VLAN (replace X.X.X.X with VLAN gateway)
/ping 1.1.1.1 src-address=X.X.X.X count=3
```

**Checklist:**
- [ ] No rules show `I` (invalid) flag
- [ ] Allow rules appear before related drop rules
- [ ] Connectivity test passes from affected VLAN source IP

### After VLAN Changes

```routeros
# Verify VLAN is properly configured on bridge
/interface bridge vlan print where vlan-ids=XX

# Check interface is up
/interface print where name~"vlanXX"

# Verify DHCP is serving on the VLAN
/ip dhcp-server print where interface~"vlanXX"
```

From client device:
```bash
# Verify IP assignment
ipconfig getifaddr en0  # or appropriate interface

# Test DNS resolution
nslookup google.com

# Test internet connectivity
curl -I https://www.google.com --max-time 10
```

### After DHCP Changes

```routeros
# Verify DHCP server status
/ip dhcp-server print

# Check for lease assignments
/ip dhcp-server lease print where server="dhcp-XX"
```

---

## Common Pitfalls

| Issue | Symptom | Prevention |
|-------|---------|------------|
| Firewall rule ordering | Traffic blocked despite allow rule existing | Always use `place-before=` to insert before drop rules |
| Invalid firewall rules | Rule shows `I` flag, not working | Verify interface/address-list names exist before referencing |
| DHCP not serving | Clients get 169.254.x.x | Verify DHCP server interface matches VLAN interface name |
| DNS not resolving | Can ping IPs but not domains | Check `allow-remote-requests=yes` on router DNS settings |
| Inter-VLAN routing blocked | VLANs can't reach each other | Check FORWARD chain rules and connection tracking |
| Subnet overlap | Devices unreachable, asymmetric routing | Remove legacy addresses before adding new overlapping ranges |
| DHCP reservation not applied | Device keeps old IP | Force lease renewal or remove dynamic lease on router |
| SSH script syntax errors | "syntax error" or silent failure | Use single quotes, avoid shell variable interpolation |
| Firewall rule on dynamic IP | Rule silently stops matching after IP change | Always create static DHCP reservation before device-specific firewall rule |
| VLAN move without firewall audit | Device loses access to required services | Audit service dependencies before moving device to restricted VLAN |
| HA integrations unavailable after IP change | Devices `unavailable` in HA despite being on network | Update HA `core.config_entries` host IPs when changing router static reservations |

---

## Validation Commands Quick Reference

```routeros
# === FIREWALL ===
/ip firewall filter print where chain=input
/ip firewall filter print where chain=forward
/ip firewall filter print where invalid
/ip firewall nat print where chain=srcnat

# === INTERFACES ===
/interface print
/interface bridge vlan print
/interface bridge port print

# === DHCP ===
/ip dhcp-server print
/ip dhcp-server lease print
/ip pool print

# === DNS ===
/ip dns print

# === CONNECTIVITY TESTS ===
/ping 1.1.1.1 src-address=10.0.XX.1 count=3
:resolve "google.com"
```

---

## Change Log

| Date | Change Type | Issue | Resolution |
|------|-------------|-------|------------|
| 2026-02-21 | Firewall INPUT | Guest DNS/DHCP blocked | Reordered allow rules before drop rule |
| 2026-02-21 | IP Migration | APs stuck on 10.0.0.x | Removed legacy addresses, renewed DHCP leases |
| 2026-02-21 | DHCP | Static reservations not taking effect | Restarted APs to force lease renewal |
| 2026-02-21 | Scripting | SSH commands failing with syntax errors | Used numeric positions instead of variables |
| 2026-03-16 | Firewall / DHCP | TV on IoT had no Plex rule; docs had stale IPs after consolidation | Added static reservations + firewall rules; established mandatory static-IP-before-firewall-rule policy |
| 2026-03-20 | DHCP / HA | 22 HA integrations unavailable after 2026-03-14 IP consolidation | Bulk-updated `core.config_entries` host IPs; added HA IP check to DHCP checklist; created 10 new static reservations (Printer, Tasmota, Flume, Nest, Amazon, extra LIFX, WiiM) |
