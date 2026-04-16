# feb/19/2026 20:41:25 by RouterOS 6.49.19
# software id = K1LH-4GM7
#
# model = RB760iGS
# serial number = AE370B7E823F
/caps-man channel
add band=5ghz-a/n/ac extension-channel=Ceee frequency=5745 name=ch-5ghz-wide
add band=2ghz-g/n frequency=2412 name=ch-2ghz
add band=2ghz-g/n frequency=2462 name=ch-2ghz-ch11
/interface bridge
add admin-mac=C4:AD:34:17:3A:55 auto-mac=no comment=defconf name=bridge \
    vlan-filtering=yes
/interface vlan
add comment=Infrastructure interface=bridge name=vlan10-infra vlan-id=10
add comment="Trusted Clients" interface=bridge name=vlan20-trusted vlan-id=20
add comment="Shared Services" interface=bridge name=vlan30-shared vlan-id=30
add comment="IoT Devices" interface=bridge name=vlan40-iot vlan-id=40
add comment=Guest interface=bridge name=vlan50-guest vlan-id=50
add comment="VPN Canada" interface=bridge name=vlan60-vpn vlan-id=60
/caps-man datapath
add bridge=bridge comment="VLAN 20 - Trusted" name=datapath-trusted vlan-id=\
    20 vlan-mode=use-tag
add bridge=bridge comment="VLAN 40 - IoT" name=datapath-iot vlan-id=40 \
    vlan-mode=use-tag
add bridge=bridge comment="VLAN 50 - Guest" name=datapath-guest vlan-id=50 \
    vlan-mode=use-tag
add bridge=bridge comment="VLAN 60 - VPN" name=datapath-vpn vlan-id=60 \
    vlan-mode=use-tag
/caps-man security
add authentication-types=wpa2-psk comment="Trusted & VPN" name=sec-trusted \
    passphrase="i said i would fix it"
add authentication-types=wpa2-psk comment="IoT Networks" name=sec-iot \
    passphrase="stay in your lane"
add authentication-types=wpa2-psk comment="Guest Network" name=sec-guest \
    passphrase="cooper the pooper"
add authentication-types=wpa2-psk comment="IoT 2.4GHz Legacy" name=sec-iot-2g \
    passphrase=x2230dallas!!
/caps-man configuration
add comment="Trusted - Dual Band" country="united states" datapath=\
    datapath-trusted name=cfg-collective security=sec-trusted ssid=COLLECTIVE
add comment="IoT - 2.4GHz Only" country="united states" datapath=datapath-iot \
    name=cfg-collective-2g security=sec-iot-2g ssid=COLLECTIVE-2G
add comment="IoT - Dual Band" country="united states" datapath=datapath-iot \
    name=cfg-collective-iot security=sec-iot ssid=COLLECTIVE-IOT
add comment="Guest - Dual Band" country="united states" datapath=\
    datapath-guest name=cfg-collective-guest security=sec-guest ssid=\
    COLLECTIVE-GUEST
add comment="VPN Canada - Dual Band" country="united states" datapath=\
    datapath-vpn name=cfg-collective-vpn security=sec-trusted ssid=\
    COLLECTIVE-VPN-CA
add channel=ch-5ghz-wide comment="Trusted - 5GHz" country="united states" \
    datapath=datapath-trusted name=cfg-collective-5ghz security=sec-trusted \
    ssid=COLLECTIVE
add channel=ch-5ghz-wide comment="IoT - 5GHz" country="united states" \
    datapath=datapath-iot name=cfg-collective-iot-5ghz security=sec-iot ssid=\
    COLLECTIVE-IOT
add channel=ch-5ghz-wide comment="Guest - 5GHz" country="united states" \
    datapath=datapath-guest name=cfg-collective-guest-5ghz security=sec-guest \
    ssid=COLLECTIVE-GUEST
add channel=ch-2ghz-ch11 comment="Trusted - 2.4GHz Upstairs" country=\
    "united states" datapath=datapath-trusted name=cfg-collective-2ghz-ups \
    security=sec-trusted ssid=COLLECTIVE
add channel=ch-2ghz-ch11 comment="IoT - 2.4GHz Upstairs" country=\
    "united states" datapath=datapath-iot name=cfg-collective-iot-2ghz-ups \
    security=sec-iot ssid=COLLECTIVE-IOT
add channel=ch-2ghz-ch11 comment="Guest - 2.4GHz Upstairs" country=\
    "united states" datapath=datapath-guest name=\
    cfg-collective-guest-2ghz-ups security=sec-guest ssid=COLLECTIVE-GUEST
add channel=ch-2ghz-ch11 comment="Legacy IoT - 2.4GHz Upstairs" country=\
    "united states" datapath=datapath-iot name=cfg-collective-2g-ups \
    security=sec-iot-2g ssid=COLLECTIVE-2G
add channel=ch-2ghz comment="Trusted - 2.4GHz Downstairs" country=\
    "united states" datapath=datapath-trusted name=cfg-collective-2ghz-down \
    security=sec-trusted ssid=COLLECTIVE
add channel=ch-2ghz comment="IoT - 2.4GHz Downstairs" country="united states" \
    datapath=datapath-iot name=cfg-collective-iot-2ghz-down security=sec-iot \
    ssid=COLLECTIVE-IOT
add channel=ch-2ghz comment="Guest - 2.4GHz Downstairs" country=\
    "united states" datapath=datapath-guest name=\
    cfg-collective-guest-2ghz-down security=sec-guest ssid=COLLECTIVE-GUEST
add channel=ch-2ghz comment="Legacy IoT - 2.4GHz Downstairs" country=\
    "united states" datapath=datapath-iot name=cfg-collective-2g-down \
    security=sec-iot-2g ssid=COLLECTIVE-2G
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=dhcp ranges=10.0.255.1-10.0.255.254
add comment="Infrastructure DHCP Pool" name=pool-infra ranges=\
    10.0.10.100-10.0.10.250
add comment="Trusted DHCP Pool" name=pool-trusted ranges=\
    10.0.20.100-10.0.20.250
add comment="Shared DHCP Pool" name=pool-shared ranges=\
    10.0.30.100-10.0.30.250
add comment="IoT DHCP Pool" name=pool-iot ranges=10.0.40.100-10.0.40.250
add comment="Guest DHCP Pool" name=pool-guest ranges=10.0.50.100-10.0.50.250
add comment="VPN DHCP Pool" name=pool-vpn ranges=10.0.60.100-10.0.60.250
/ip dhcp-server
add address-pool=dhcp disabled=no interface=bridge name=defconf
add address-pool=pool-infra disabled=no interface=vlan10-infra name=\
    dhcp-infra
add address-pool=pool-trusted disabled=no interface=vlan20-trusted \
    lease-time=1d name=dhcp-trusted
add address-pool=pool-shared disabled=no interface=vlan30-shared lease-time=\
    1d name=dhcp-shared
add address-pool=pool-iot disabled=no interface=vlan40-iot lease-time=1d \
    name=dhcp-iot
add address-pool=pool-guest disabled=no interface=vlan50-guest lease-time=1d \
    name=dhcp-guest
add address-pool=pool-vpn interface=vlan60-vpn name=dhcp-vpn
/port
set 0 name=serial0
/user group
set full policy="local,telnet,ssh,ftp,reboot,read,write,policy,test,winbox,pas\
    sword,web,sniff,sensitive,api,romon,dude,tikapp"
/caps-man manager
set enabled=yes
/caps-man provisioning
add action=create-dynamic-enabled comment="All SSIDs" disabled=yes \
    master-configuration=cfg-collective slave-configurations="cfg-collective-i\
    ot,cfg-collective-guest,cfg-collective-vpn,cfg-collective-2g"
add action=create-dynamic-enabled comment="2.4GHz radios" disabled=yes \
    hw-supported-modes=gn master-configuration=cfg-collective \
    slave-configurations=\
    cfg-collective-iot,cfg-collective-guest,cfg-collective-2g
add action=create-dynamic-enabled comment="5GHz radios" hw-supported-modes=ac \
    master-configuration=cfg-collective-5ghz slave-configurations=\
    cfg-collective-iot-5ghz,cfg-collective-guest-5ghz
add action=create-dynamic-enabled comment="Upstairs 2.4GHz - Ch 11" \
    master-configuration=cfg-collective-2ghz-ups radio-mac=74:4D:28:5F:80:20 \
    slave-configurations="cfg-collective-iot-2ghz-ups,cfg-collective-guest-2gh\
    z-ups,cfg-collective-2g-ups"
add action=create-dynamic-enabled comment="Downstairs 2.4GHz - Ch 1" \
    master-configuration=cfg-collective-2ghz-down radio-mac=74:4D:28:D4:7E:41 \
    slave-configurations="cfg-collective-iot-2ghz-down,cfg-collective-guest-2g\
    hz-down,cfg-collective-2g-down"
/interface bridge port
add bridge=bridge comment=defconf interface=ether2 pvid=30
add bridge=bridge comment=defconf interface=ether3
add bridge=bridge comment=defconf interface=ether4
add bridge=bridge comment=defconf interface=ether5
add bridge=bridge comment=defconf interface=sfp1
/ip neighbor discovery-settings
set discover-interface-list=all
/interface bridge vlan
add bridge=bridge comment="Infra VLAN" tagged=ether3,bridge vlan-ids=10
add bridge=bridge comment="Trusted VLAN" tagged=ether3,bridge vlan-ids=20
add bridge=bridge comment="Shared VLAN" tagged=ether3,bridge untagged=ether2 \
    vlan-ids=30
add bridge=bridge comment="IoT VLAN" tagged=ether3,bridge vlan-ids=40
add bridge=bridge comment="Guest VLAN" tagged=ether3,bridge vlan-ids=50
add bridge=bridge comment="VPN VLAN" tagged=ether3,bridge vlan-ids=60
/interface list member
add comment=defconf interface=bridge list=LAN
add comment=defconf interface=ether1 list=WAN
add comment="Trusted VLAN" interface=vlan20-trusted list=LAN
add comment="Shared VLAN" interface=vlan30-shared list=LAN
add comment="IoT VLAN" interface=vlan40-iot list=LAN
add comment="Guest VLAN" interface=vlan50-guest list=LAN
add comment="VPN VLAN" interface=vlan60-vpn list=LAN
/ip address
add address=10.0.0.1/16 comment=defconf interface=ether2 network=10.0.0.0
add address=10.0.10.1/24 comment="Infra Gateway" interface=vlan10-infra \
    network=10.0.10.0
add address=10.0.20.1/24 comment="Trusted Gateway" interface=vlan20-trusted \
    network=10.0.20.0
add address=10.0.30.1/24 comment="Shared Gateway" interface=vlan30-shared \
    network=10.0.30.0
add address=10.0.40.1/24 comment="IoT Gateway" interface=vlan40-iot network=\
    10.0.40.0
add address=10.0.50.1/24 comment="Guest Gateway" interface=vlan50-guest \
    network=10.0.50.0
add address=10.0.60.1/24 comment="VPN Gateway" interface=vlan60-vpn network=\
    10.0.60.0
/ip dhcp-client
add comment=defconf disabled=no interface=ether1
/ip dhcp-server lease
add address=10.0.0.101 client-id=1:94:18:65:6e:46:c8 comment="LAYER 2/3 NETWOR\
    K DEVICES /// Switch (POE) - Netgear GS305EP - Gigabit POE Switch for POE \
    WAPs (Network Closet)" mac-address=94:18:65:6E:46:C8 server=defconf
add address=10.0.6.6 client-id=1:24:a1:60:2f:47:cd comment=\
    "Flume Water Flow Monitor" mac-address=24:A1:60:2F:47:CD
add address=10.0.30.217 mac-address=E4:F0:42:82:F4:A2 server=dhcp-iot
add address=10.0.30.211 mac-address=F4:F5:D8:75:87:F8 server=dhcp-iot
add address=10.0.30.10 client-id=1:90:9:d0:63:c3:5a mac-address=\
    90:09:D0:63:C3:5A server=dhcp-shared
add address=10.0.40.10 comment="ESPHome Energy Monitor 1 - CircuitSetup" \
    mac-address=94:3C:C6:32:CB:94 server=dhcp-iot
add address=10.0.30.11 comment="Home Assistant - Home Automation Hub" \
    mac-address=DC:A6:32:AA:FE:ED server=dhcp-shared
add address=10.0.0.4 comment="MikroTik cAP ac - Master Bedroom" mac-address=\
    18:FD:74:5C:C6:8A server=defconf
/ip dhcp-server network
add address=10.0.0.0/16 comment=defconf dns-server=1.1.1.2 gateway=10.0.0.1 \
    netmask=16
add address=10.0.10.0/24 comment="Infrastructure Network" dns-server=\
    10.0.10.1 gateway=10.0.10.1
add address=10.0.20.0/24 comment="Trusted Network" dns-server=10.0.20.1 \
    gateway=10.0.20.1
add address=10.0.30.0/24 comment="Shared Network" dns-server=10.0.30.1 \
    gateway=10.0.30.1
add address=10.0.40.0/24 comment="IoT Network" dns-server=10.0.40.1 gateway=\
    10.0.40.1
add address=10.0.50.0/24 comment="Guest Network" dns-server=10.0.50.1 \
    gateway=10.0.50.1
add address=10.0.60.0/24 comment="VPN Network" dns-server=10.0.60.1 gateway=\
    10.0.60.1
/ip dns
set allow-remote-requests=yes
/ip dns static
add address=10.0.0.1 name=router.lan
add address=10.0.30.10 name=synology
add address=10.0.40.10 name=ESPEnergyMonitor1
add address=10.0.40.10 name=ESP-EMon-1
add address=10.0.30.11 name=homeassistant
add address=10.0.0.4 name=cap-master-bedroom
/ip firewall address-list
add address=10.0.30.0/24 comment="Shared Services VLAN" list=shared-devices
add address=10.0.0.102 comment="Synology NAS" list=nas-servers
/ip firewall filter
add action=log chain=forward log-prefix=IoT-210: src-address=10.0.40.210
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=drop chain=input comment="Block IoT from router management" \
    in-interface=vlan40-iot
add action=drop chain=input comment="Block Guest from router management" \
    in-interface=vlan50-guest
add action=accept chain=input comment="defconf: accept ICMP" protocol=icmp
add action=accept chain=input comment=\
    "Accept Inbound Plex Traffic (TCP, >>:32400)" dst-port=32400 protocol=tcp
add action=drop chain=input comment="defconf: drop all not coming from LAN" \
    in-interface-list=!LAN
add action=accept chain=forward comment="defconf: accept in ipsec policy" \
    ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" \
    ipsec-policy=out,ipsec
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related
add action=accept chain=forward comment="Allow Trusted to Management Network" \
    dst-address=10.0.0.0/16 in-interface=vlan20-trusted
add action=accept chain=forward comment="Allow Trusted to Shared" \
    in-interface=vlan20-trusted out-interface=vlan30-shared
add action=accept chain=forward comment="Allow Trusted to IoT" in-interface=\
    vlan20-trusted out-interface=vlan40-iot
add action=drop chain=forward comment="Block IoT from Management Network" \
    dst-address=10.0.0.0/16 in-interface=vlan40-iot
add action=drop chain=forward comment="Block Guest from Management Network" \
    dst-address=10.0.0.0/16 in-interface=vlan50-guest
add action=drop chain=forward comment="Block Guest from Trusted" \
    in-interface=vlan50-guest out-interface=vlan20-trusted
add action=drop chain=forward comment="Block Guest from IoT" in-interface=\
    vlan50-guest out-interface=vlan40-iot
add action=accept chain=forward comment=\
    "defconf: accept established,related, untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=accept chain=forward comment=\
    "Allow Shared to IoT (Home Assistant)" in-interface=vlan30-shared \
    out-interface=vlan40-iot
add action=accept chain=forward comment="Allow IoT to NAS" dst-address=\
    10.0.30.0/24 dst-port=445,139,2049,548 in-interface=vlan40-iot log=yes \
    log-prefix=IoT-to-NAS: out-interface=vlan30-shared protocol=tcp
add action=drop chain=forward comment="Block IoT to Trusted" in-interface=\
    vlan40-iot out-interface=vlan20-trusted
add action=accept chain=forward comment="Allow ESPHome to Home Assistant API" \
    dst-address=10.0.30.11 dst-port=6053,8123 protocol=tcp src-address=\
    10.0.40.10
add action=drop chain=forward comment="Block IoT to Shared" in-interface=\
    vlan40-iot out-interface=vlan30-shared
add action=accept chain=forward comment=\
    "Allow Guest to Shared Devices (TV/Cast/Print)" dst-address-list=\
    shared-devices in-interface=vlan50-guest
add action=drop chain=forward comment="Block Guest to LAN" in-interface=\
    vlan50-guest out-interface-list=LAN
add action=accept chain=forward comment="Allow LAN to WAN" in-interface-list=\
    LAN out-interface-list=WAN
add action=drop chain=forward comment=\
    "defconf:  drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN
/ip firewall nat
add action=masquerade chain=srcnat comment="defconf: masquerade" \
    ipsec-policy=out,none out-interface-list=WAN
add action=dst-nat chain=dstnat comment=\
    "Forward Plex traffic to NAS (VLAN 30)" dst-port=32400 protocol=tcp \
    to-addresses=10.0.30.10 to-ports=32400
add action=dst-nat chain=dstnat comment="Plex remote access port forwarding" \
    dst-port=32400 protocol=tcp to-addresses=10.0.30.10 to-ports=32400
/system clock
set time-zone-name=America/Denver
/system identity
set name="MikroTik hEX S"
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
