# 2026-03-11 15:26:52 by RouterOS 7.19.6
# software id = FCDU-HW5Q
#
# model = RB5009UPr+S+
# serial number = HKJ0AJ9GZSQ
/caps-man channel
add band=5ghz-a/n/ac extension-channel=Ceee frequency=5745 name=ch-5ghz-wide
add band=2ghz-g/n frequency=2412 name=ch-2ghz
add band=2ghz-g/n frequency=2462 name=ch-2ghz-ch11
/interface bridge
add admin-mac=04:F4:1C:F1:8C:54 auto-mac=no comment=defconf name=bridge \
    vlan-filtering=yes
/interface vlan
add comment=Infrastructure interface=bridge name=vlan10-infra vlan-id=10
add comment="Trusted Clients" interface=bridge name=vlan20-trusted vlan-id=20
add comment="Shared Services" interface=bridge name=vlan30-shared vlan-id=30
add comment="IoT Devices" interface=bridge name=vlan40-iot vlan-id=40
add comment=Guest interface=bridge name=vlan50-guest vlan-id=50
add comment="VPN Canada" interface=bridge name=vlan60-vpn vlan-id=60
add comment="CCTV VLAN" interface=bridge name=vlan70-cctv vlan-id=70
/caps-man datapath
add bridge=bridge comment="VLAN 20 - Trusted" name=datapath-trusted vlan-id=\
    20 vlan-mode=use-tag
add bridge=bridge client-to-client-forwarding=no comment="VLAN 40 - IoT" \
    name=datapath-iot vlan-id=40 vlan-mode=use-tag
add bridge=bridge comment="VLAN 50 - Guest" name=datapath-guest vlan-id=50 \
    vlan-mode=use-tag
add bridge=bridge comment="VLAN 60 - VPN" name=datapath-vpn vlan-id=60 \
    vlan-mode=use-tag
/caps-man security
add authentication-types=wpa2-psk comment="Trusted & VPN" name=sec-trusted
add authentication-types=wpa2-psk comment="IoT Networks" name=sec-iot
add authentication-types=wpa2-psk comment="Guest Network" name=sec-guest
add authentication-types=wpa2-psk comment="IoT 2.4GHz Legacy" name=sec-iot-2g
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
add name=default-dhcp ranges=192.168.88.10-192.168.88.254
add comment="Infrastructure DHCP Pool" name=pool-infra ranges=\
    10.0.10.100-10.0.10.250
add comment="Trusted DHCP Pool" name=pool-trusted ranges=\
    10.0.20.100-10.0.20.250
add comment="Shared DHCP Pool" name=pool-shared ranges=\
    10.0.30.100-10.0.30.250
add comment="IoT DHCP Pool" name=pool-iot ranges=10.0.40.100-10.0.40.250
add comment="Guest DHCP Pool" name=pool-guest ranges=10.0.50.100-10.0.50.250
add comment="VPN DHCP Pool" name=pool-vpn ranges=10.0.60.100-10.0.60.250
add name=pool-cctv ranges=10.0.70.100-10.0.70.250
/ip dhcp-server
# No IP address on interface
add address-pool=default-dhcp interface=bridge name=defconf
add address-pool=pool-infra interface=vlan10-infra name=dhcp-infra
add address-pool=pool-trusted interface=vlan20-trusted lease-time=1d name=\
    dhcp-trusted
add address-pool=pool-shared interface=vlan30-shared lease-time=1d name=\
    dhcp-shared
add address-pool=pool-iot interface=vlan40-iot lease-time=1d name=dhcp-iot
add address-pool=pool-guest interface=vlan50-guest lease-time=1d name=\
    dhcp-guest
add address-pool=pool-vpn interface=vlan60-vpn name=dhcp-vpn
add address-pool=pool-cctv interface=vlan70-cctv lease-time=1d name=dhcp-cctv
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
/disk settings
set auto-media-interface=bridge auto-media-sharing=yes auto-smb-sharing=yes
/interface bridge port
add bridge=bridge comment="Brother Printer (Trusted temp)" interface=ether2 \
    pvid=20
add bridge=bridge comment="GS305EP - CCTV (VLAN 70)" interface=ether3 pvid=70
add bridge=bridge comment="AP Master Bedroom (future)" interface=ether4 pvid=\
    10
add bridge=bridge comment="AP Downstairs Den" interface=ether5 pvid=10
add bridge=bridge comment="AP Upstairs Office" interface=ether6 pvid=10
add bridge=bridge comment="GS108 switch (Shared)" interface=ether7 pvid=30
add bridge=bridge comment="Break-glass / reserved (2.5G)" interface=ether1 \
    pvid=20
/ip neighbor discovery-settings
set discover-interface-list=LAN
/interface bridge vlan
add bridge=bridge comment="Infra VLAN" tagged=bridge untagged=\
    ether4,ether5,ether6 vlan-ids=10
add bridge=bridge comment="Trusted VLAN" tagged=ether4,ether5,ether6,bridge \
    untagged=ether1,ether2 vlan-ids=20
add bridge=bridge comment="Shared VLAN" tagged=bridge untagged=ether7 \
    vlan-ids=30
add bridge=bridge comment="IoT VLAN" tagged=ether4,ether5,ether6,bridge \
    vlan-ids=40
add bridge=bridge comment="Guest VLAN" tagged=ether4,ether5,ether6,bridge \
    vlan-ids=50
add bridge=bridge comment="VPN VLAN" tagged=bridge vlan-ids=60
add bridge=bridge comment="CCTV VLAN" tagged=bridge untagged=ether3 vlan-ids=\
    70
/interface list member
add comment=defconf interface=bridge list=LAN
add comment="WAN interface" interface=ether8 list=WAN
add comment="Infra VLAN" interface=vlan10-infra list=LAN
add comment="Trusted VLAN" interface=vlan20-trusted list=LAN
add comment="Shared VLAN" interface=vlan30-shared list=LAN
add comment="IoT VLAN" interface=vlan40-iot list=LAN
add comment="Guest VLAN" interface=vlan50-guest list=LAN
add comment="VPN VLAN" interface=vlan60-vpn list=LAN
add comment="CCTV VLAN" interface=vlan70-cctv list=LAN
/ip address
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
add address=10.0.70.1/24 comment="CCTV gateway" interface=vlan70-cctv \
    network=10.0.70.0
/ip dhcp-client
add comment="WAN DHCP" interface=ether8
/ip dhcp-server lease
add address=10.0.10.11 comment="AP Upstairs Office" mac-address=\
    74:4D:28:5F:80:1E server=dhcp-infra
add address=10.0.10.12 comment="AP Downstairs Den" mac-address=\
    74:4D:28:D4:7E:3F server=dhcp-infra
add address=10.0.10.13 comment="AP Master Bedroom (reserved)" mac-address=\
    18:FD:74:5C:C6:8A server=dhcp-infra
add address=10.0.10.20 comment="Switch GS305EP" mac-address=94:18:65:6E:46:C8 \
    server=dhcp-infra
add address=10.0.30.10 comment="NAS Synology DS224+" mac-address=\
    90:09:D0:63:C3:5A server=dhcp-shared
add address=10.0.30.11 comment="Home Assistant RPi" mac-address=\
    DC:A6:32:AA:FE:ED server=dhcp-shared
add address=10.0.40.212 comment="Kasa HS200 - Front Door" mac-address=\
    98:25:4A:F8:72:99 server=dhcp-iot
add address=10.0.40.232 comment="Kasa EP10 - Garage Fan 2" mac-address=\
    54:AF:97:84:59:CC server=dhcp-iot
add address=10.0.40.249 comment="Kasa EP10 - Porch Speakers" mac-address=\
    78:8C:B5:A4:07:EE server=dhcp-iot
add address=10.0.40.214 comment="Kasa KP405 - Outdoor Kitchen Lights" \
    mac-address=B0:19:21:21:9D:A6 server=dhcp-iot
add address=10.0.40.234 comment="LIFX - Garage Hanging South" mac-address=\
    D0:73:D5:12:74:F0 server=dhcp-iot
add address=10.0.40.245 comment="Kasa EP10 - TV" mac-address=\
    78:8C:B5:A4:2A:42 server=dhcp-iot
add address=10.0.40.229 comment="LIFX - Garage Attic" mac-address=\
    D0:73:D5:12:1D:E1 server=dhcp-iot
add address=10.0.40.246 comment="Kasa EP10 - Garage Party Lights" \
    mac-address=54:AF:97:84:3E:1B server=dhcp-iot
add address=10.0.40.237 comment="WLED LED Controller" mac-address=\
    00:4B:12:4A:7F:28 server=dhcp-iot
add address=10.0.40.216 comment="Kasa HS200 - Back Door" mac-address=\
    98:25:4A:F8:88:8E server=dhcp-iot
add address=10.0.40.247 comment="Kasa HS300 - Power Strip" mac-address=\
    5C:62:8B:A9:74:8C server=dhcp-iot
add address=10.0.40.215 comment="Kasa KP405 - Firepit Lights" mac-address=\
    54:AF:97:21:1C:91 server=dhcp-iot
add address=10.0.40.238 comment="Kasa EP10 - Laser Lamp" mac-address=\
    B4:B0:24:EA:A4:98 server=dhcp-iot
add address=10.0.40.225 comment="Kasa EP10 - Ham Radio" mac-address=\
    B4:B0:24:EA:A4:74 server=dhcp-iot
add address=10.0.40.230 comment="Kasa EP10 - Garage Fan 1" mac-address=\
    54:AF:97:84:42:91 server=dhcp-iot
add address=10.0.40.248 comment="Kasa EP40 - Outdoor Outlet 2" mac-address=\
    5C:62:8B:AA:1C:B6 server=dhcp-iot
add address=10.0.40.206 comment="LIFX - Den Floor Lamp" mac-address=\
    D0:73:D5:12:65:B8 server=dhcp-iot
add address=10.0.40.10 comment="ESPHome Energy Monitor 1 - CircuitSetup" \
    mac-address=94:3C:C6:32:CB:94 server=dhcp-iot
add address=10.0.40.228 comment="Kasa EP40 - Outdoor Outlet 1" mac-address=\
    B4:B0:24:80:66:73 server=dhcp-iot
add address=10.0.40.231 comment="Kasa EP10 - Garage Stereo" mac-address=\
    B4:B0:24:EA:A4:85 server=dhcp-iot
add address=10.0.40.204 comment="LIFX - Garage Hanging North" mac-address=\
    D0:73:D5:12:9A:2A server=dhcp-iot
add address=10.0.40.227 comment="LIFX - Garage Spot North" mac-address=\
    D0:73:D5:12:B0:AA server=dhcp-iot
add address=10.0.40.236 comment="LIFX - Office Table Lamp" mac-address=\
    D0:73:D5:12:78:30 server=dhcp-iot
add address=10.0.40.185 comment="Chromecast Audio Kitchen" mac-address=\
    A4:77:33:F8:98:6E server=dhcp-iot
/ip dhcp-server network
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
add address=10.0.70.0/24 comment="CCTV DHCP network" dns-server=10.0.70.1 \
    gateway=10.0.70.1
add address=192.168.88.0/24 comment=defconf dns-server=192.168.88.1 gateway=\
    192.168.88.1
/ip dns
set allow-remote-requests=yes mdns-repeat-ifaces=\
    vlan20-trusted,vlan30-shared,vlan40-iot,vlan50-guest servers=\
    1.1.1.1,1.0.0.1
/ip dns static
add address=10.0.30.10 name=synology type=A
add address=10.0.40.10 name=ESPEnergyMonitor1 type=A
add address=10.0.40.10 name=ESP-EMon-1 type=A
add address=10.0.30.11 name=homeassistant type=A
/ip firewall address-list
add address=10.0.30.0/24 comment="Shared Services VLAN" list=shared-devices
add address=10.0.40.185 comment="Chromecast Audio (Kitchen)" list=\
    shared-devices
/ip firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="Allow DNS from Guest" dst-port=53 \
    protocol=udp src-address=10.0.50.0/24
add action=accept chain=input comment="Allow DHCP from Guest" dst-port=67-68 \
    protocol=udp src-address=10.0.50.0/24
add action=accept chain=input comment="Allow DNS from Guest (TCP)" dst-port=\
    53 protocol=tcp src-address=10.0.50.0/24
add action=accept chain=input comment="Allow DNS from IoT" dst-port=53 \
    protocol=udp src-address=10.0.40.0/24
add action=accept chain=input comment="Allow DHCP from IoT" dst-port=67-68 \
    protocol=udp src-address=10.0.40.0/24
add action=accept chain=input comment="Allow mDNS from IoT" dst-port=5353 \
    protocol=udp src-address=10.0.40.0/24
add action=drop chain=input comment="Block IoT from router management" \
    in-interface=vlan40-iot
add action=accept chain=input comment="Allow mDNS from Guest" dst-port=5353 \
    protocol=udp src-address=10.0.50.0/24
add action=drop chain=input comment="Block Guest from router management" \
    in-interface=vlan50-guest
add action=accept chain=input comment="Allow DNS from CCTV" dst-port=53 \
    protocol=udp src-address=10.0.70.0/24
add action=accept chain=input comment="Allow DHCP from CCTV" dst-port=67-68 \
    protocol=udp src-address=10.0.70.0/24
add action=drop chain=input comment="Block CCTV from router management" \
    in-interface=vlan70-cctv
add action=accept chain=input comment="defconf: accept ICMP" protocol=icmp
add action=accept chain=input comment=\
    "defconf: accept to local loopback (for CAPsMAN)" dst-address=127.0.0.1
add action=accept chain=input comment=\
    "Accept Inbound Plex Traffic (TCP 32400)" dst-port=32400 protocol=tcp
add action=drop chain=input comment="defconf: drop all not coming from LAN" \
    in-interface-list=!LAN
add action=accept chain=forward comment="defconf: accept in ipsec policy" \
    ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" \
    ipsec-policy=out,ipsec
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related hw-offload=yes
add action=accept chain=forward comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=accept chain=forward comment="Allow Guest to Internet" \
    out-interface-list=WAN src-address=10.0.50.0/24
add action=drop chain=forward comment="Guest: block bittorrent TCP" dst-port=\
    6881-6999,51413 protocol=tcp src-address=10.0.50.0/24
add action=drop chain=forward comment="Guest: block bittorrent UDP" dst-port=\
    6881-6999,51413 protocol=udp src-address=10.0.50.0/24
add action=drop chain=forward comment="Block IoT from Infrastructure" \
    dst-address=10.0.10.0/24 src-address=10.0.40.0/24
add action=drop chain=forward comment="Block Guest from Infrastructure" \
    dst-address=10.0.10.0/24 src-address=10.0.50.0/24
add action=accept chain=forward comment="Allow Trusted to Infrastructure" \
    dst-address=10.0.10.0/24 src-address=10.0.20.0/24
add action=accept chain=forward comment="Allow Trusted to IoT" dst-address=\
    10.0.40.0/24 src-address=10.0.20.0/24
add action=accept chain=forward comment="Allow Trusted to Shared" \
    dst-address=10.0.30.0/24 src-address=10.0.20.0/24
add action=accept chain=forward comment="Allow Trusted to CCTV web UI" \
    dst-address=10.0.70.0/24 dst-port=80,443 protocol=tcp src-address=\
    10.0.20.0/24
add action=accept chain=forward comment="Allow LIFX control from Trusted" \
    dst-address=10.0.40.0/24 dst-port=56700 protocol=udp src-address=\
    10.0.20.0/24
add action=accept chain=forward comment="Allow LIFX control from Shared" \
    dst-address=10.0.40.0/24 dst-port=56700 protocol=udp src-address=\
    10.0.30.0/24
add action=accept chain=forward comment="Allow LIFX response to Trusted" \
    dst-address=10.0.20.0/24 protocol=udp src-address=10.0.40.0/24 src-port=\
    56700
add action=accept chain=forward comment="Allow LIFX response to Shared" \
    dst-address=10.0.30.0/24 protocol=udp src-address=10.0.40.0/24 src-port=\
    56700
add action=accept chain=forward comment=\
    "Allow Shared to IoT (Home Assistant)" in-interface=vlan30-shared \
    out-interface=vlan40-iot
add action=accept chain=forward comment="Allow IoT to NAS" dst-address=\
    10.0.30.0/24 dst-port=445,139,2049,548 in-interface=vlan40-iot \
    out-interface=vlan30-shared protocol=tcp
add action=accept chain=forward comment="Allow Home Assistant to ESPHome" \
    dst-address=10.0.40.10 dst-port=6053 in-interface=vlan30-shared \
    out-interface=vlan40-iot protocol=tcp src-address=10.0.30.11
add action=accept chain=forward comment="Allow ESPHome to Home Assistant API" \
    dst-address=10.0.30.11 dst-port=6053,8123 protocol=tcp src-address=\
    10.0.40.10
add action=drop chain=forward comment="Block IoT to Trusted" in-interface=\
    vlan40-iot out-interface=vlan20-trusted
add action=drop chain=forward comment="Block IoT to Shared" in-interface=\
    vlan40-iot out-interface=vlan30-shared
add action=drop chain=forward comment="Block Guest from Trusted" \
    in-interface=vlan50-guest out-interface=vlan20-trusted
add action=drop chain=forward comment="Block Guest from IoT" in-interface=\
    vlan50-guest out-interface=vlan40-iot
add action=accept chain=forward comment=\
    "Allow Guest to Shared Devices (TV/Cast/Print)" dst-address-list=\
    shared-devices in-interface=vlan50-guest
add action=drop chain=forward comment="Block Guest to LAN" in-interface=\
    vlan50-guest out-interface-list=LAN
add action=accept chain=forward comment="Allow CCTV to NAS (recording)" \
    dst-address=10.0.30.10 dst-port=554,9000 protocol=tcp src-address=\
    10.0.70.0/24
add action=drop chain=forward comment="Block CCTV lateral movement" \
    dst-address=10.0.0.0/16 src-address=10.0.70.0/24
add action=drop chain=forward comment="Block CCTV to Internet" \
    out-interface-list=WAN src-address=10.0.70.0/24
add action=accept chain=forward comment="Allow LAN to WAN" in-interface-list=\
    LAN out-interface-list=WAN
add action=drop chain=forward comment=\
    "defconf: drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN
/ip firewall nat
add action=masquerade chain=srcnat comment="defconf: masquerade" \
    ipsec-policy=out,none out-interface-list=WAN
add action=dst-nat chain=dstnat comment=\
    "Forward Plex traffic to NAS (VLAN 30)" dst-port=32400 protocol=tcp \
    to-addresses=10.0.30.10 to-ports=32400
/ipv6 firewall address-list
add address=::/128 comment="defconf: unspecified address" list=bad_ipv6
add address=::1/128 comment="defconf: lo" list=bad_ipv6
add address=fec0::/10 comment="defconf: site-local" list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped" list=bad_ipv6
add address=::/96 comment="defconf: ipv4 compat" list=bad_ipv6
add address=100::/64 comment="defconf: discard only " list=bad_ipv6
add address=2001:db8::/32 comment="defconf: documentation" list=bad_ipv6
add address=2001:10::/28 comment="defconf: ORCHID" list=bad_ipv6
add address=3ffe::/16 comment="defconf: 6bone" list=bad_ipv6
/ipv6 firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=input comment="defconf: accept UDP traceroute" \
    dst-port=33434-33534 protocol=udp
add action=accept chain=input comment=\
    "defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=\
    udp src-address=fe80::/10
add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 \
    protocol=udp
add action=accept chain=input comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=input comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=input comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
add action=fasttrack-connection chain=forward comment="defconf: fasttrack6" \
    connection-state=established,related
add action=accept chain=forward comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop packets with bad src ipv6" src-address-list=bad_ipv6
add action=drop chain=forward comment=\
    "defconf: drop packets with bad dst ipv6" dst-address-list=bad_ipv6
add action=drop chain=forward comment="defconf: rfc4890 drop hop-limit=1" \
    hop-limit=equal:1 protocol=icmpv6
add action=accept chain=forward comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=forward comment="defconf: accept HIP" protocol=139
add action=accept chain=forward comment="defconf: accept IKE" dst-port=\
    500,4500 protocol=udp
add action=accept chain=forward comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=forward comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=forward comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=forward comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !LAN
/system clock
set time-zone-name=America/Denver
/system identity
set name="MikroTik RB5009"
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
