# Network Infrastructure

vaxlan network infrastructure documentation and configuration.

## Directory Contents

- **mikrotik/** - RouterOS configuration scripts for MikroTik devices
- **diagrams/** - Network topology and VLAN diagrams
- **docs/** - Architecture documentation and design decisions

## Configuration Files

### mikrotik/rb5009-full-config.rsc
Complete configuration for MikroTik RB5009UPr+S+IN router including:
- VLAN setup (10, 20, 30, 40, 50)
- CAPsMAN wireless management
- DHCP servers
- Firewall rules
- NAT configuration

### mikrotik/capsman-configuration.rsc
Standalone CAPsMAN configuration (included in full config above).

## Deployment

⚠️ **Always backup before applying configurations**

```
/export file=backup-$(date +%Y%m%d)
```

Review the configuration file and customize:
- Wi-Fi passphrases
- Port assignments
- WAN interface
- Static IP reservations

## VLAN Design

| VLAN | Purpose | Subnet | Notes |
|------|---------|--------|-------|
| 10 | Infrastructure | 10.0.10.0/24 | Router, switches, AP management |
| 20 | Trusted | 10.0.20.0/24 | Personal devices, NAS |
| 30 | Shared | 10.0.30.0/24 | Home Assistant, printers, TVs |
| 40 | IoT | 10.0.40.0/24 | Smart devices, cameras |
| 50 | Guest | 10.0.50.0/24 | Guest network with limited access |

## SSIDs

- **COLLECTIVE** - Trusted clients (dual-band)
- **COLLECTIVE-2G** - Legacy IoT devices (2.4 GHz only) - unchanged to avoid re-pairing
- **COLLECTIVE-IOT** - New IoT devices (dual-band)
- **COLLECTIVE-GUEST** - Guest access (dual-band)
