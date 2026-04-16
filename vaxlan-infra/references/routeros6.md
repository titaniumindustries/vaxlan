# RouterOS 6 Syntax Reference (cAP ac APs)

RouterOS 6.48.6 on MikroTik cAP ac access points. Key syntax differences from RouterOS 7.

## Connection

```
SSHPASS='x2230dallas!!!' sshpass -e ssh admin@10.0.10.11 '<COMMAND>'
```

APs: 10.0.10.11 (Upstairs Office), 10.0.10.12 (Den), 10.0.10.13 (Master Bedroom)

## Key Syntax Differences from RouterOS 7

### Path separators
- ROS6: `/ip firewall filter` (same as ROS7 for most paths)
- ROS6 CAPsMAN client: `/interface wireless cap` (not `/caps-man`)
- ROS7 CAPsMAN server: `/caps-man` (on the router, not the APs)

### Print formatting
- ROS6: `print` shows all columns by default
- ROS7: `print` shows selected columns; use `print detail` for all fields

### Find syntax
- ROS6: `[find name="X"]` (same keyword-based, but some filter options differ)
- ROS7: `[find where name="X"]` (`where` keyword sometimes required)

## Common AP Operations

```
# Show system identity
/system identity print

# Set system identity
/system identity set name="cAP-ac-DEN"

# Show firmware/version
/system resource print

# Show interfaces
/interface print

# Show IP address (should be DHCP from VLAN 10)
/ip address print

# Show DHCP client status
/ip dhcp-client print

# Show wireless interfaces
/interface wireless print

# Show CAP status (connection to CAPsMAN)
/interface wireless cap print

# Enable/disable CAP mode
/interface wireless cap set enabled=yes
/interface wireless cap set enabled=no

# Set CAP manager discovery
/interface wireless cap set discovery-interfaces=ether1 caps-man-addresses=10.0.20.1

# Show bridge config
/interface bridge print

# Show system LEDs
/system leds print

# Disable LEDs
/system leds set [find] disabled=yes

# Check for firmware updates
/system package update check-for-updates

# Show installed packages
/system package print

# Reboot AP
/system reboot

# Show log
/log print
```

## AP Configuration Notes

- APs are managed centrally via CAPsMAN on the RB5009 router
- Do NOT configure SSIDs, security, or wireless settings directly on APs
- AP-side config is limited to: identity, passwords, CAP mode, LED settings
- The `wireless` package on the router (ROS7) enables CAPsMAN compatibility with ROS6 APs
- APs receive PoE from the router (ether4/5/6)
- AP bridge ports are set with PVID=10 (Infrastructure VLAN) for management
- Tagged VLANs (20, 40, 50) are handled by CAPsMAN datapaths

## Factory Reset Procedure

If an AP needs reconfiguration:
```
# From the AP itself
/system reset-configuration no-defaults=yes skip-backup=yes

# After reset, configure:
/interface wireless cap set enabled=yes discovery-interfaces=ether1 \
  caps-man-addresses=10.0.20.1
/ip dhcp-client add interface=ether1 disabled=no
/system identity set name="cAP-ac-LOCATION"
/user set admin password="x2230dallas!!!"
/system leds set [find] disabled=yes
```
