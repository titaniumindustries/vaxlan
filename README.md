# vaxlan

Home network infrastructure documentation and configuration management.

## Repository Structure

```
vaxlan/
├── network/              # Network infrastructure
│   ├── mikrotik/        # MikroTik router configurations
│   ├── diagrams/        # Network topology diagrams
│   └── docs/            # Network architecture documentation
│
├── homeassistant/       # Home Assistant configuration
│   ├── config/          # HA configuration files
│   ├── automations/     # Automation scripts
│   └── docs/            # HA documentation
│
└── README.md            # This file
```

## Network Architecture

The vaxlan network uses VLAN segmentation for security and organization:

- **VLAN 10** - Infrastructure (10.0.10.0/24)
- **VLAN 20** - Trusted Clients (10.0.20.0/24)
- **VLAN 30** - Shared Services (10.0.30.0/24)
- **VLAN 40** - IoT Devices (10.0.40.0/24)
- **VLAN 50** - Guest (10.0.50.0/24)

See [network/docs/home_network_architecture_final_summary.md](network/docs/home_network_architecture_final_summary.md) for complete architecture details.

## Hardware

- **Router:** MikroTik RB5009UPr+S+IN (RouterOS 7)
- **Access Points:** MikroTik cAP ac (CAPsMAN managed)
- **Home Automation:** Raspberry Pi running Home Assistant (VLAN 30)

## Quick Start

### Deploying Network Configuration

1. Backup current router config: `/export file=backup-before-vaxlan`
2. Review and customize [network/mikrotik/rb5009-full-config.rsc](network/mikrotik/rb5009-full-config.rsc)
3. Import configuration to router
4. Enable VLAN filtering as final step

### Home Assistant

Documentation and configuration for Home Assistant instance located in the `homeassistant/` directory.

## Notes

- All configurations use lowercase "vaxlan"
- Network changes may require Home Assistant configuration updates
- Keep this repository private (contains network topology and security information)
