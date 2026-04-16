# RouterOS 7 Upgrade Plan

Last updated: 2026-02-20

## Executive Summary

| Item | Details |
|------|---------|
| Current Version | RouterOS 6.49.19 (long-term) |
| Target Version | RouterOS 7.x (stable) |
| Estimated Downtime | 10-15 minutes |
| Total Time (with prep & verification) | **3-4 hours** |
| Risk Level | Medium (complex CAPsMAN + VLAN setup) |

## Why Upgrade?

**Benefits for your network:**
- Native mDNS reflector (enables Bonjour/AirPlay across VLANs)
- Improved wireless performance and features
- Better firewall performance
- Ongoing security updates (v6 is in maintenance mode)
- Required for future RB5009 upgrade

**Current blockers resolved by upgrade:**
- mDNS reflection for printer/Chromecast discovery
- Native WiFi 6 support (when upgrading APs)

## Pre-Upgrade Preparation (1-2 hours)

### 1. Documentation Review
- [ ] Export current running config to text file
- [ ] Document all static DHCP leases
- [ ] Document all firewall rules (create firewall-rules.md)
- [ ] Screenshot CAPsMAN configuration
- [ ] Note any custom scripts or schedulers

### 2. Backup Strategy
```
# On router - create timestamped backups
/export file=pre-ros7-export-YYYYMMDD
/system backup save name=pre-ros7-backup-YYYYMMDD

# Download to local machine
scp admin@10.0.20.1:/pre-ros7-export-*.rsc ./mikrotik/backups/
scp admin@10.0.20.1:/pre-ros7-backup-*.backup ./mikrotik/backups/
```

### 3. Verify Current State
- [ ] All VLANs routing correctly
- [ ] All SSIDs broadcasting
- [ ] DHCP working on all VLANs
- [ ] Internet connectivity from each VLAN
- [ ] Firewall rules functioning (test inter-VLAN blocking)

### 4. Download Required Packages
For cAP ac APs (mmips architecture), you'll need the `wireless` package to maintain CAPsMAN compatibility:
- RouterOS 7.x main package (mmips)
- wireless-7.x-mmips.npk (for CAPsMAN with legacy APs)

## CAPsMAN Considerations

⚠️ **Critical:** RouterOS 7.13+ introduced a new WiFi system (`/interface/wifi`) separate from legacy CAPsMAN (`/caps-man`).

**Your cAP ac APs use the legacy "ac" wireless driver**, which means:

| Option | Description | Recommendation |
|--------|-------------|----------------|
| **Keep CAPsMAN** | Install `wireless` package, continue using `/caps-man` | ✅ Recommended for now |
| **Migrate to WiFi** | Use new `/interface/wifi` system | Not supported on cAP ac |

**Action:** After upgrading to RouterOS 7, install the `wireless` package to maintain CAPsMAN functionality.

## Upgrade Procedure (30-45 minutes)

### Phase 1: Update to Latest v6 (if needed)
```
# Already on 6.49.19 - skip this step
/system package update check-for-updates
```

### Phase 2: Switch to Upgrade Channel
```
/system package update set channel=upgrade
/system package update check-for-updates
```

### Phase 3: Download and Install
```
# Download packages
/system package update download

# Verify download completed
/system package print

# Reboot to install (causes downtime)
/system reboot
```

### Phase 4: Post-Upgrade Verification
```
# Verify version
/system resource print

# Update firmware/bootloader
/system routerboard upgrade
/system reboot
```

### Phase 5: Install Wireless Package (for CAPsMAN)
```
# Download wireless package for your AP architecture
/tool fetch url="https://download.mikrotik.com/routeros/7.x/wireless-7.x-mmips.npk"

# Reboot to install
/system reboot
```

### Phase 6: Verify CAPsMAN
```
/caps-man manager print
/caps-man remote-cap print
/caps-man interface print
```

## Post-Upgrade Configuration

### Enable mDNS Reflector
```
# RouterOS 7 native mDNS
/ip dns set mdns=yes

# Configure which interfaces participate
/ip dns set mdns-interfaces=vlan-20-trusted,vlan-30-shared
```

### Syntax Changes to Note

| Feature | RouterOS 6 | RouterOS 7 |
|---------|------------|------------|
| Package check | `/system package update check-for-updates` | Same |
| CAPsMAN | `/caps-man` | `/caps-man` (with wireless pkg) |
| New WiFi | N/A | `/interface/wifi` |
| Container | N/A | `/container` (new feature) |

## Rollback Plan

If upgrade fails:

1. **Netinstall recovery** (worst case):
   - Download Netinstall from MikroTik
   - Boot router in recovery mode (hold reset)
   - Reinstall RouterOS 6.49.19
   - Restore from .backup file

2. **Config restore** (if router boots but config broken):
   ```
   /system backup load name=pre-ros7-backup-YYYYMMDD
   /system reboot
   ```

## Time Allocation

| Phase | Duration | Notes |
|-------|----------|-------|
| Documentation & backup | 45-60 min | Can be done in advance |
| Pre-flight verification | 15-20 min | Test current functionality |
| Actual upgrade | 10-15 min | Network downtime |
| Post-upgrade verification | 30-45 min | Test all VLANs, SSIDs, firewall |
| Troubleshooting buffer | 60-90 min | If issues arise |
| **Total** | **3-4 hours** | Plan for a maintenance window |

## Recommended Approach

**Option A: Upgrade Current Hardware (hEX S)**
- Upgrade RouterOS 6 → 7 on existing router
- Keep CAPsMAN with wireless package
- Lower risk, familiar hardware
- **Time: 3-4 hours**

**Option B: Combine with RB5009 Upgrade** ⭐ Recommended
- Set up RB5009 with RouterOS 7 fresh
- Build new config based on documented settings
- Test in parallel before cutover
- Swap hardware in 5-10 minutes
- **Time: 4-6 hours total, but only 5-10 min downtime**

## Pre-Upgrade Checklist

- [ ] All documentation complete
- [ ] Backups created and downloaded locally
- [ ] Wireless package downloaded for cAP ac
- [ ] Netinstall downloaded (recovery option)
- [ ] Maintenance window scheduled (evening/weekend)
- [ ] All household members notified of potential outage
- [ ] Test devices ready for post-upgrade verification
- [ ] Phone hotspot available as backup internet

## Post-Upgrade Tasks

- [ ] Verify all VLANs have internet
- [ ] Verify all SSIDs broadcasting
- [ ] Verify DHCP working on all VLANs
- [ ] Verify firewall rules (inter-VLAN blocking)
- [ ] Test printer access from VLAN 20
- [ ] Configure mDNS reflector
- [ ] Update hardware-software-inventory.md with new version
- [ ] Run ping test for latency verification
