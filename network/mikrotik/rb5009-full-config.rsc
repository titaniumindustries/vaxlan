# vaxlan Network - Complete Configuration
# MikroTik RB5009UPr+S+IN - RouterOS 7
# 
# WARNING: This is a complete network reconfiguration
# Expected downtime: 5-10 minutes
# Backup current config before applying: /export file=backup-before-vaxlan

# ============================================
# STEP 1: Bridge and VLAN Setup
# ============================================

# Create main bridge
/interface bridge
add name=bridge-main vlan-filtering=no comment="Main bridge - enable VLAN filtering after config complete"

# Add all LAN ports to bridge (adjust port names based on your RB5009)
# PoE ports: ether1-ether8
# Non-PoE ports: ether9-ether10
# SFP+: sfp-sfpplus1
/interface bridge port
add bridge=bridge-main interface=ether1 comment="AP/Camera trunk"
add bridge=bridge-main interface=ether2 comment="AP/Camera trunk"
add bridge=bridge-main interface=ether3 comment="AP/Camera trunk"
add bridge=bridge-main interface=ether4 comment="AP/Camera trunk"
add bridge=bridge-main interface=ether5 comment="AP/Camera trunk"
add bridge=bridge-main interface=ether6 comment="AP/Camera trunk"
add bridge=bridge-main interface=ether7 comment="AP/Camera trunk"
add bridge=bridge-main interface=ether8 comment="AP/Camera trunk"
add bridge=bridge-main interface=ether9 comment="Trusted devices"
add bridge=bridge-main interface=ether10 comment="Downstream switch"

# Create VLAN interfaces
/interface vlan
add interface=bridge-main vlan-id=10 name=vlan-10-infra comment="Infrastructure"
add interface=bridge-main vlan-id=20 name=vlan-20-trusted comment="Trusted Clients"
add interface=bridge-main vlan-id=30 name=vlan-30-shared comment="Shared Services"
add interface=bridge-main vlan-id=40 name=vlan-40-iot comment="IoT Devices"
add interface=bridge-main vlan-id=50 name=vlan-50-guest comment="Guest"

# Configure VLAN filtering on bridge ports
# Ports 1-8: Trunk for APs (VLANs 20, 40, 50) and Cameras (VLAN 40)
/interface bridge vlan
add bridge=bridge-main vlan-ids=20,40,50 tagged=ether1,ether2,ether3,ether4,ether5,ether6,ether7,ether8,bridge-main
add bridge=bridge-main vlan-ids=10 tagged=bridge-main
add bridge=bridge-main vlan-ids=20 tagged=ether9,ether10,bridge-main
add bridge=bridge-main vlan-ids=30 tagged=ether10,bridge-main
add bridge=bridge-main vlan-ids=40 tagged=ether10,bridge-main
add bridge=bridge-main vlan-ids=50 tagged=ether10,bridge-main

# Configure PVID for untagged ports (adjust as needed for your devices)
# Example: ether9 for direct-connected trusted devices
/interface bridge port
set [find interface=ether9] pvid=20

# ============================================
# STEP 2: IP Addressing
# ============================================

/ip address
add address=10.0.10.1/24 interface=vlan-10-infra comment="Infra gateway"
add address=10.0.20.1/24 interface=vlan-20-trusted comment="Trusted gateway"
add address=10.0.30.1/24 interface=vlan-30-shared comment="Shared gateway"
add address=10.0.40.1/24 interface=vlan-40-iot comment="IoT gateway"
add address=10.0.50.1/24 interface=vlan-50-guest comment="Guest gateway"

# ============================================
# STEP 3: DHCP Server Configuration
# ============================================

# VLAN 10 - Infrastructure
/ip pool
add name=pool-infra ranges=10.0.10.100-10.0.10.200
/ip dhcp-server
add name=dhcp-infra interface=vlan-10-infra address-pool=pool-infra disabled=no
/ip dhcp-server network
add address=10.0.10.0/24 gateway=10.0.10.1 dns-server=10.0.10.1 comment="Infrastructure"

# VLAN 20 - Trusted
/ip pool
add name=pool-trusted ranges=10.0.20.100-10.0.20.250
/ip dhcp-server
add name=dhcp-trusted interface=vlan-20-trusted address-pool=pool-trusted disabled=no
/ip dhcp-server network
add address=10.0.20.0/24 gateway=10.0.20.1 dns-server=10.0.20.1 comment="Trusted clients"

# VLAN 30 - Shared Services
/ip pool
add name=pool-shared ranges=10.0.30.100-10.0.30.200
/ip dhcp-server
add name=dhcp-shared interface=vlan-30-shared address-pool=pool-shared disabled=no
/ip dhcp-server network
add address=10.0.30.0/24 gateway=10.0.30.1 dns-server=10.0.30.1 comment="Shared services"

# VLAN 40 - IoT
/ip pool
add name=pool-iot ranges=10.0.40.100-10.0.40.250
/ip dhcp-server
add name=dhcp-iot interface=vlan-40-iot address-pool=pool-iot disabled=no
/ip dhcp-server network
add address=10.0.40.0/24 gateway=10.0.40.1 dns-server=10.0.40.1 comment="IoT devices"

# VLAN 50 - Guest
/ip pool
add name=pool-guest ranges=10.0.50.100-10.0.50.200
/ip dhcp-server
add name=dhcp-guest interface=vlan-50-guest address-pool=pool-guest disabled=no
/ip dhcp-server network
add address=10.0.50.0/24 gateway=10.0.50.1 dns-server=10.0.50.1 comment="Guest network"

# ============================================
# STEP 4: DNS Configuration
# ============================================

/ip dns
set allow-remote-requests=yes servers=1.1.1.1,1.0.0.1

# ============================================
# STEP 5: CAPsMAN Configuration
# ============================================

# Enable CAPsMAN Manager
/caps-man manager
set enabled=yes

# Security Profiles
/caps-man security
add name=sec-trusted \
    authentication-types=wpa2-psk,wpa3-psk \
    encryption=aes-ccm,ccmp-256 \
    passphrase="YOUR_TRUSTED_PASSWORD_HERE"

add name=sec-iot \
    authentication-types=wpa2-psk \
    encryption=aes-ccm \
    passphrase="YOUR_IOT_PASSWORD_HERE"

add name=sec-guest \
    authentication-types=wpa2-psk,wpa3-psk \
    encryption=aes-ccm,ccmp-256 \
    passphrase="YOUR_GUEST_PASSWORD_HERE"

# Channel Configuration
/caps-man channel
add name=ch-2ghz \
    band=2ghz-g/n \
    frequency=2412 \
    width=20mhz \
    extension-channel=disabled

add name=ch-5ghz \
    band=5ghz-a/n/ac \
    frequency=5180 \
    width=40mhz \
    extension-channel=Ce

# Datapath Configuration (VLAN Mapping)
/caps-man datapath
add name=dp-trusted vlan-mode=use-tag vlan-id=20
add name=dp-iot vlan-mode=use-tag vlan-id=40
add name=dp-guest vlan-mode=use-tag vlan-id=50

# SSID Configuration
/caps-man configuration
add name=cfg-collective \
    ssid=COLLECTIVE \
    security=sec-trusted \
    datapath=dp-trusted \
    channel=ch-2ghz \
    country=unitedstates

add name=cfg-collective-5ghz \
    ssid=COLLECTIVE \
    security=sec-trusted \
    datapath=dp-trusted \
    channel=ch-5ghz \
    country=unitedstates

add name=cfg-collective-2g \
    ssid=COLLECTIVE-2G \
    security=sec-iot \
    datapath=dp-iot \
    channel=ch-2ghz \
    country=unitedstates

add name=cfg-collective-iot \
    ssid=COLLECTIVE-IOT \
    security=sec-iot \
    datapath=dp-iot \
    channel=ch-2ghz \
    country=unitedstates

add name=cfg-collective-iot-5ghz \
    ssid=COLLECTIVE-IOT \
    security=sec-iot \
    datapath=dp-iot \
    channel=ch-5ghz \
    country=unitedstates

add name=cfg-collective-guest \
    ssid=COLLECTIVE-GUEST \
    security=sec-guest \
    datapath=dp-guest \
    channel=ch-2ghz \
    country=unitedstates

add name=cfg-collective-guest-5ghz \
    ssid=COLLECTIVE-GUEST \
    security=sec-guest \
    datapath=dp-guest \
    channel=ch-5ghz \
    country=unitedstates

# Provisioning Rules
/caps-man provisioning
add action=create-dynamic-enabled \
    master-configuration=cfg-collective \
    name-format=prefix-identity \
    name-prefix=cap

# ============================================
# STEP 6: Firewall Configuration
# ============================================

# Define address lists for convenience
/ip firewall address-list
add list=trusted-services address=10.0.30.0/24 comment="Shared services VLAN"

# INPUT chain - protect router itself
/ip firewall filter
add chain=input action=accept connection-state=established,related comment="Allow established/related"
add chain=input action=accept in-interface=vlan-10-infra comment="Allow from infrastructure"
add chain=input action=accept in-interface=vlan-20-trusted comment="Allow from trusted"
add chain=input action=accept in-interface=vlan-30-shared protocol=icmp comment="Allow ping from shared"
add chain=input action=drop in-interface=vlan-40-iot comment="Drop IoT to router"
add chain=input action=drop in-interface=vlan-50-guest comment="Drop guest to router except DHCP/DNS"
add chain=input action=accept protocol=udp dst-port=53 comment="Allow DNS"
add chain=input action=accept protocol=udp dst-port=67-68 comment="Allow DHCP"

# FORWARD chain - inter-VLAN rules
/ip firewall filter

# Allow established/related everywhere
add chain=forward action=accept connection-state=established,related comment="Allow established/related"

# Trusted -> Anywhere
add chain=forward action=accept in-interface=vlan-20-trusted comment="Trusted to anywhere"

# Shared -> IoT (for Home Assistant)
add chain=forward action=accept in-interface=vlan-30-shared out-interface=vlan-40-iot comment="Shared to IoT"

# Guest -> specific shared services (casting/printing)
# TODO: Replace with specific IPs for TVs and printers
add chain=forward action=accept in-interface=vlan-50-guest out-interface=vlan-30-shared dst-address=10.0.30.0/24 protocol=tcp dst-port=9000,8008,8009 comment="Guest casting to shared"
add chain=forward action=accept in-interface=vlan-50-guest out-interface=vlan-30-shared dst-address=10.0.30.0/24 protocol=udp dst-port=5353 comment="Guest mDNS to shared"
add chain=forward action=accept in-interface=vlan-50-guest out-interface=vlan-30-shared dst-address=10.0.30.0/24 protocol=tcp dst-port=631,9100 comment="Guest printing to shared"

# Block IoT -> Trusted/Shared
add chain=forward action=drop in-interface=vlan-40-iot out-interface=vlan-20-trusted comment="Block IoT to Trusted"
add chain=forward action=drop in-interface=vlan-40-iot out-interface=vlan-30-shared comment="Block IoT to Shared"
add chain=forward action=drop in-interface=vlan-40-iot out-interface=vlan-10-infra comment="Block IoT to Infra"

# Block Guest -> LAN (except allowed above)
add chain=forward action=drop in-interface=vlan-50-guest dst-address=10.0.0.0/8 comment="Block guest to LAN"

# Allow all to internet (assuming WAN interface is named differently)
add chain=forward action=accept out-interface=!bridge-main comment="Allow to internet"

# Default drop for safety
add chain=forward action=drop comment="Drop everything else"

# NAT Configuration (assuming ether11 or sfp-sfpplus1 is WAN)
# TODO: Adjust out-interface to match your WAN interface
/ip firewall nat
add chain=srcnat out-interface=ether11 action=masquerade comment="NAT to internet"

# ============================================
# STEP 7: mDNS Reflector for Guest Casting
# ============================================

# Enable mDNS repeater between Guest and Shared VLANs
/ip firewall service-port
set sip disabled=yes

/interface bridge
set bridge-main igmp-snooping=yes

# Note: RouterOS 7 mDNS reflection requires additional configuration
# or a package installation. Consider using Avahi on a separate device
# or configuring per-service firewall rules (shown above).

# ============================================
# STEP 8: Enable VLAN Filtering
# ============================================
# DO THIS LAST - after verifying all config above

# /interface bridge set bridge-main vlan-filtering=yes

# ============================================
# POST-CONFIGURATION CHECKLIST
# ============================================
# [ ] Replace all password placeholders
# [ ] Adjust port assignments (ether1-10) based on your setup
# [ ] Set correct WAN interface in NAT rule
# [ ] Assign static IPs for critical devices (NAS, Home Assistant, printers, TVs)
# [ ] Add specific TV/printer IPs to guest firewall rules
# [ ] Test each SSID on each band
# [ ] Verify firewall rules with actual traffic
# [ ] Enable VLAN filtering on bridge (commented out above)
# [ ] Configure mDNS reflection properly for guest casting
# [ ] Update DNS settings if using Pi-hole or custom DNS
# [ ] Document DHCP reservations
# [ ] Run site survey and optimize channel selection
