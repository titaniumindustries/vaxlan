# Home Assistant Configuration

Home Assistant configuration and documentation for the vaxlan network.

## Network Placement

Home Assistant runs on a Raspberry Pi in **VLAN 30 (Shared Services)** at 10.0.30.x

This placement allows it to:
- Communicate with trusted clients (VLAN 20)
- Control IoT devices (VLAN 40)
- Access shared services like printers and TVs

## Directory Structure

- **config/** - Home Assistant configuration files
- **automations/** - Automation scripts and scenes
- **docs/** - Documentation and setup guides

## Firewall Rules

The router firewall allows:
- Shared (VLAN 30) → IoT (VLAN 40) for device control
- Trusted (VLAN 20) → Shared (VLAN 30) for HA access

IoT devices cannot initiate connections back to Home Assistant (blocked by firewall).

## Setup Notes

Add setup instructions, integration documentation, and device configurations here.
