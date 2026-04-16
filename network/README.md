# vaxlan Network Infrastructure

**Type:** Enterprise-grade home network with VLAN segmentation and zero-trust security  
**Hardware:** MikroTik RB5009UPr+S+IN (RouterOS 7.19.6), 2× cAP ac APs, managed switches  
**Status:** Production

---

## Quick Start for AI Context

When starting a new conversation about this network in Warp:

1. **Read** `docs/ARCHITECTURE.md` for network intent and configuration
2. **Read** `TODO.md` for current tasks and known issues
3. **Router access:** use SSH key auth only (no inline passwords)
4. **Validation:** use `docs/configuration-validation-checklist.md` before/after changes

### Router Access Standard (Key-Based)

- Canonical router target: `admin@10.0.20.1`
- Do not use `sshpass` or plaintext passwords in commands/docs.
- Recommended SSH config alias:

```sshconfig
Host vaxlan-router
  HostName 10.0.20.1
  User admin
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes
```

- Connectivity preflight:
  - `ssh -o BatchMode=yes -o ConnectTimeout=5 vaxlan-router ':put "ok"'`
- If using direct host without alias:
  - `ssh -i "${ROUTER_SSH_KEY}" -o BatchMode=yes -o ConnectTimeout=5 admin@10.0.20.1 ':put "ok"'`

---

## Key Documentation

| File | Purpose |
|------|---------|
| **docs/ARCHITECTURE.md** | Network design intent, VLAN design, access control matrix, common issues, change log |
|| **docs/firewall-rules.md** | Complete firewall rules reference — INPUT, FORWARD, NAT |
|| **docs/hardware-software-inventory.md** | Hardware specs, port assignments, MAC addresses |
|| **docs/static-ip-assignments.md** | Static DHCP reservations snapshot (all VLANs) |
|| **docs/wireless-channel-config.md** | WiFi channel assignments and design decisions |
|| **docs/configuration-validation-checklist.md** | Validation steps, lessons learned, common pitfalls |
|| **TODO.md** | Open tasks and known issues |
|| **mikrotik/backups/** | Router configuration backups (.backup, .rsc) |
|| **mikrotik/scripts/** | Utility scripts (monitoring, diagnostics) |
|| **docs/archive/** | Historical and completed planning documents |

---

## Network Overview

### VLANs
- **10:** Infrastructure (router, switches, AP management)
- **20:** Trusted (laptops, phones) - Full access
  - Break-glass: ether1 (2.5G) is untagged VLAN 20 for emergency access
- **30:** Shared (NAS, Home Assistant, printers, VoIP) - Multi-VLAN services
- **40:** IoT (smart devices) - **Isolated** from Trusted/Shared
- **50:** Guest (visitors) - **Isolated** except internet + casting
- **60:** VPN Canada (reserved, not configured)
- **70:** CCTV (Reolink cameras) - **Isolated**, no internet, NAS-only recording

### SSIDs → VLANs
- COLLECTIVE → VLAN 20 (Trusted, 2.4/5GHz)
- COLLECTIVE-IOT → VLAN 40 (IoT, 2.4/5GHz)
- COLLECTIVE-2G → VLAN 40 (IoT, legacy 2.4GHz only)
- COLLECTIVE-GUEST → VLAN 50 (Guest, 2.4/5GHz)
- COLLECTIVE-VPN-CA → VLAN 60 (VPN, reserved)

---

## Quick Commands

### Backup Router
```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ssh vaxlan-router "/system backup save name=backup-$TIMESTAMP"
scp vaxlan-router:/backup-$TIMESTAMP.backup mikrotik/backups/
```

### Monitor TV WiFi
```bash
./mikrotik/scripts/monitor-tv-wifi.sh
```

### Monitor Mac Connectivity
```bash
./mikrotik/scripts/monitor-mac-connectivity.sh
```

### Check IoT Internet Access
```bash
ssh vaxlan-router '/ip firewall connection print count-only where src-address~"10.0.40"'
```

---

## Key IPs

### Infrastructure
- Router: 10.0.20.1 (VLAN 20) — WAN on ether8
- Switch (GS305EP): 10.0.10.20 (VLAN 10, ether3 → CCTV VLAN 70)
- Switch (GS108): unmanaged, ether7, Shared VLAN 30
- AP Upstairs Office: 10.0.10.11 (VLAN 10, ether6)
- AP Downstairs Den: 10.0.10.12 (VLAN 10, ether5)
- AP Master Bedroom (planned): 10.0.10.13 (VLAN 10, ether4)

### Services
- NAS (Synology DS224+): 10.0.30.10
- Home Assistant (RPi): 10.0.30.11
- Brother Printer: DHCP on VLAN 30 (mDNS discoverable from Trusted)
- Ooma VoIP: 10.0.30.104

### CCTV
- Gateway: 10.0.70.1 (VLAN 70, no cameras connected yet)

---

For validation tests, configuration notes, and change history see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
For firewall rules see [`docs/firewall-rules.md`](docs/firewall-rules.md).
