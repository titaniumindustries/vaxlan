# VLAN 70 (CCTV) Configuration
# Reolink PoE cameras on ether3 (GS305EP)
# Internet blocked, NAS-only recording, web UI from Trusted
# Status: UNTESTED - no cameras connected yet

# 1. Update ether3 bridge port - set PVID to 70
/interface bridge port set [find interface=ether3] pvid=70 comment="GS305EP - CCTV (VLAN 70)"

# 2. Add VLAN 70 to bridge VLAN table (tagged on bridge, untagged on ether3)
/interface bridge vlan add bridge=bridge vlan-ids=70 tagged=bridge untagged=ether3 comment="CCTV VLAN"

# 3. Create VLAN 70 interface on bridge
/interface vlan add name=vlan70-cctv vlan-id=70 interface=bridge comment="CCTV VLAN"

# 4. Add gateway IP
/ip address add address=10.0.70.1/24 interface=vlan70-cctv comment="CCTV gateway"

# 5. Add to LAN interface list (required: INPUT rule 44 drops all not from LAN)
/interface list member add list=LAN interface=vlan70-cctv comment="CCTV VLAN"

# 6. DHCP pool
/ip pool add name=pool-cctv ranges=10.0.70.100-10.0.70.250

# 7. DHCP network
/ip dhcp-server network add address=10.0.70.0/24 gateway=10.0.70.1 dns-server=10.0.70.1 comment="CCTV DHCP network"

# 8. DHCP server (24h lease like all other VLANs)
/ip dhcp-server add name=dhcp-cctv interface=vlan70-cctv address-pool=pool-cctv lease-time=1d disabled=no

# === INPUT CHAIN ===
# Allow DNS/DHCP from CCTV, then block management
# Placed before ICMP accept (after IoT/Guest blocks)

/ip firewall filter add chain=input action=accept protocol=udp src-address=10.0.70.0/24 dst-port=53 comment="Allow DNS from CCTV" place-before=[find where chain=input and comment~"accept ICMP"]

/ip firewall filter add chain=input action=accept protocol=udp src-address=10.0.70.0/24 dst-port=67-68 comment="Allow DHCP from CCTV" place-before=[find where chain=input and comment~"accept ICMP"]

/ip firewall filter add chain=input action=drop in-interface=vlan70-cctv comment="Block CCTV from router management" place-before=[find where chain=input and comment~"accept ICMP"]

# === FORWARD CHAIN ===

# Allow Trusted -> CCTV web UI (placed after Allow Trusted to Shared)
/ip firewall filter add chain=forward action=accept protocol=tcp src-address=10.0.20.0/24 dst-address=10.0.70.0/24 dst-port=80,443 comment="Allow Trusted to CCTV web UI" place-before=[find where chain=forward and comment~"Allow LIFX control from Trusted"]

# Allow CCTV -> NAS only for recording (placed before LAN->WAN)
/ip firewall filter add chain=forward action=accept protocol=tcp src-address=10.0.70.0/24 dst-address=10.0.30.10 dst-port=554,9000 comment="Allow CCTV to NAS (recording)" place-before=[find where chain=forward and comment="Allow LAN to WAN"]

# Block CCTV lateral movement to any LAN subnet (placed before LAN->WAN)
/ip firewall filter add chain=forward action=drop src-address=10.0.70.0/24 dst-address=10.0.0.0/16 comment="Block CCTV lateral movement" place-before=[find where chain=forward and comment="Allow LAN to WAN"]

# Block CCTV to internet - no phoning home (placed before LAN->WAN)
/ip firewall filter add chain=forward action=drop src-address=10.0.70.0/24 out-interface-list=WAN comment="Block CCTV to Internet" place-before=[find where chain=forward and comment="Allow LAN to WAN"]
