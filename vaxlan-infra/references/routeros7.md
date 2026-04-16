# RouterOS 7 Syntax Reference (RB5009UPr+S+IN)

RouterOS 7.19.6 on the MikroTik RB5009. All commands shown as RouterOS CLI — wrap in single quotes for SSH.

## Firewall Filter

```
# List rules by chain
/ip firewall filter print where chain=input
/ip firewall filter print where chain=forward

# Filter by comment
/ip firewall filter print where comment~"keyword"

# Filter by address
/ip firewall filter print where src-address~"10.0.40" or dst-address~"10.0.40"

# Show only drop rules
/ip firewall filter print where chain=forward and action=drop

# Check for invalid rules
/ip firewall filter print where invalid

# Add rule before a specific rule (by rule ID number)
/ip firewall filter add chain=forward action=accept protocol=tcp \
  src-address=10.0.40.X dst-address=10.0.30.10 dst-port=32400 \
  comment="Allow Device to NAS (Plex)" place-before=RULE_ID

# Add INPUT rule
/ip firewall filter add chain=input action=accept protocol=udp \
  src-address=10.0.X.0/24 dst-port=53 \
  comment="Allow DNS from VLAN" place-before=DROP_RULE_ID

# Move rule to new position (before destination rule)
/ip firewall filter move SOURCE destination=TARGET

# Remove rule by ID
/ip firewall filter remove RULE_ID

# Remove rule by find
/ip firewall filter remove [find where comment="exact comment"]

# Disable/enable rule
/ip firewall filter disable RULE_ID
/ip firewall filter enable RULE_ID

# Edit existing rule
/ip firewall filter set RULE_ID src-address=NEW_IP comment="Updated comment"
```

## Firewall NAT

```
# List NAT rules
/ip firewall nat print

# Add DSTNAT (port forward)
/ip firewall nat add chain=dstnat action=dst-nat protocol=tcp \
  dst-port=EXTERNAL_PORT to-addresses=INTERNAL_IP to-ports=INTERNAL_PORT \
  comment="Description"

# Masquerade (srcnat)
/ip firewall nat add chain=srcnat action=masquerade out-interface-list=WAN
```

## Firewall Address Lists

```
# Print a specific list
/ip firewall address-list print where list=shared-devices

# Add entry
/ip firewall address-list add list=LIST_NAME address=IP comment="Description"

# Remove entry
/ip firewall address-list remove [find where list=LIST_NAME and address=IP]

# Find all references to an IP
/ip firewall address-list print where address=IP
```

## Firewall Connections (live)

```
# All connections from a source
/ip firewall connection print where src-address~"10.0.40.60"

# Count connections from a subnet
/ip firewall connection print count-only where src-address~"10.0.40"

# Connections to a specific destination
/ip firewall connection print where dst-address~"10.0.30.10"
```

## DHCP Server

```
# List all DHCP servers
/ip dhcp-server print

# List all leases on a server
/ip dhcp-server lease print where server=dhcp-iot

# List static leases only
/ip dhcp-server lease print where dynamic=no

# List dynamic leases only
/ip dhcp-server lease print where dynamic=yes

# Search by hostname
/ip dhcp-server lease print where host-name~"keyword"

# Search by comment
/ip dhcp-server lease print where comment~"keyword"

# Search by MAC
/ip dhcp-server lease print where mac-address=AA:BB:CC:DD:EE:FF

# Add static lease
/ip dhcp-server lease add address=10.0.40.60 mac-address=AA:BB:CC:DD:EE:FF \
  server=dhcp-iot comment="Device Name"

# Remove dynamic lease (force device to pick up static)
/ip dhcp-server lease remove [find where dynamic=yes and mac-address=AA:BB:CC:DD:EE:FF]

# Make existing dynamic lease static
/ip dhcp-server lease make-static [find where mac-address=AA:BB:CC:DD:EE:FF]

# Show DHCP pools
/ip pool print
```

### DHCP Server Names
- `dhcp-infra` — VLAN 10
- `dhcp-trusted` — VLAN 20
- `dhcp-shared` — VLAN 30
- `dhcp-iot` — VLAN 40
- `dhcp-guest` — VLAN 50
- `dhcp-vpn` — VLAN 60
- `dhcp-cctv` — VLAN 70

## CAPsMAN (Wireless Management)

Requires `wireless` package on RouterOS 7 for cAP ac compatibility.

```
# List registered wireless clients
/caps-man registration-table print

# List with stats (signal, tx/rx rates, uptime)
/caps-man registration-table print stats

# Find specific client by MAC
/caps-man registration-table print where mac-address=AA:BB:CC:DD:EE:FF

# List all managed APs (CAPs)
/caps-man remote-cap print

# List CAPsMAN interfaces (virtual radio interfaces)
/caps-man interface print

# List configurations
/caps-man configuration print

# List datapaths
/caps-man datapath print

# List provisioning rules
/caps-man provisioning print

# List security profiles
/caps-man security print

# List channels
/caps-man channel print

# Modify client-to-client forwarding on a datapath
/caps-man datapath set [find name="datapath-iot"] client-to-client-forwarding=yes

# Disconnect a wireless client
/caps-man registration-table remove [find where mac-address=AA:BB:CC:DD:EE:FF]
```

## Bridge & VLANs

```
# Show bridge status
/interface bridge print

# Show bridge ports with PVIDs
/interface bridge port print

# Show VLAN table
/interface bridge vlan print

# Show VLAN interfaces
/interface vlan print

# Add VLAN to bridge
/interface bridge vlan add bridge=bridge vlan-ids=XX tagged=bridge,etherY comment="VLAN Name"

# Set port PVID
/interface bridge port set [find interface=etherX] pvid=XX
```

### VLAN Interface Names
- `vlan10-infra` | `vlan20-trusted` | `vlan30-shared`
- `vlan40-iot` | `vlan50-guest` | `vlan60-vpn` | `vlan70-cctv`

## IP Addresses & Routing

```
# Show all IP addresses
/ip address print

# Show routes
/ip route print

# Show DNS config
/ip dns print

# Show mDNS repeat interfaces
/ip dns print | grep mdns
```

## Interface & Diagnostics

```
# Show all interfaces with status
/interface print

# Show interface stats
/interface print stats

# Show ether port speeds/status
/interface ethernet print

# Ping from router
/ping IP count=3

# Ping from specific source IP (test from a VLAN)
/ping IP src-address=10.0.X.1 count=3

# DNS resolve test
:resolve "google.com"

# Show system resources
/system resource print

# Show uptime
/system resource print | grep uptime

# Show RouterOS version
/system resource print | grep version

# Show PoE status
/interface ethernet poe print
```

## System & Backup

```
# Export full config to file (text, re-importable)
/export file=export-YYYYMMDD

# Binary backup (includes passwords)
/system backup save name=backup-YYYYMMDD

# Download via SCP (from local machine)
sshpass -p 'x2230dallas!!!' scp admin@10.0.20.1:/export-YYYYMMDD.rsc mikrotik/backups/

# Show stored files
/file print

# Remove old backup
/file remove "filename"

# Reboot
/system reboot

# Show log
/log print
/log print where topics~"dhcp"
/log print where topics~"firewall"
```

## Interface Lists

```
# Show interface lists
/interface list print

# Show list members
/interface list member print

# Current lists: WAN (ether8), LAN (all VLANs + bridge)
```

## Common Patterns

### Add IoT device with Plex NAS access
```
# 1. Static DHCP reservation
/ip dhcp-server lease add address=10.0.40.XX mac-address=MAC server=dhcp-iot comment="Device Name"

# 2. Remove dynamic lease
/ip dhcp-server lease remove [find where dynamic=yes and mac-address=MAC]

# 3. Find the IoT→Shared drop rule ID
/ip firewall filter print where chain=forward and comment~"Block IoT to Shared"

# 4. Add allow rule before the drop (use the ID from step 3)
/ip firewall filter add chain=forward action=accept protocol=tcp \
  src-address=10.0.40.XX dst-address=10.0.30.10 dst-port=32400 \
  comment="Allow DeviceName to NAS (Plex)" place-before=DROP_RULE_ID

# 5. Verify placement
/ip firewall filter print where chain=forward and (comment~"DeviceName" or comment~"Block IoT to Shared")
```

### Check what VLAN/IP a device is on
```
# By MAC address
/ip dhcp-server lease print where mac-address=AA:BB:CC:DD:EE:FF

# By hostname
/ip dhcp-server lease print where host-name~"keyword"

# Wireless client details
/caps-man registration-table print stats where mac-address=AA:BB:CC:DD:EE:FF
```
