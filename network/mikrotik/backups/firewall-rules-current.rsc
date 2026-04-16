# feb/16/2026 10:38:19 by RouterOS 6.49.19
# software id = K1LH-4GM7
#
# model = RB760iGS
# serial number = AE370B7E823F
/ip firewall filter
add action=log chain=forward log-prefix=IoT-210: src-address=10.0.40.210
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
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
