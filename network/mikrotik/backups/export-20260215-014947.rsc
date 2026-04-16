# feb/15/2026 01:47:47 by RouterOS 6.49.19
# software id = K1LH-4GM7
#
# model = RB760iGS
# serial number = AE370B7E823F
/interface bridge
add admin-mac=C4:AD:34:17:3A:55 auto-mac=no comment=defconf name=bridge
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=dhcp ranges=10.0.255.1-10.0.255.254
/ip dhcp-server
add address-pool=dhcp disabled=no interface=bridge name=defconf
/port
set 0 name=serial0
/user group
set full policy="local,telnet,ssh,ftp,reboot,read,write,policy,test,winbox,pas\
    sword,web,sniff,sensitive,api,romon,dude,tikapp"
/interface bridge port
add bridge=bridge comment=defconf interface=ether2
add bridge=bridge comment=defconf interface=ether3
add bridge=bridge comment=defconf interface=ether4
add bridge=bridge comment=defconf interface=ether5
add bridge=bridge comment=defconf interface=sfp1
/ip neighbor discovery-settings
set discover-interface-list=LAN
/interface list member
add comment=defconf interface=bridge list=LAN
add comment=defconf interface=ether1 list=WAN
/ip address
add address=10.0.0.1/16 comment=defconf interface=ether2 network=10.0.0.0
/ip dhcp-client
add comment=defconf disabled=no interface=ether1
/ip dhcp-server lease
add address=10.0.0.101 client-id=1:94:18:65:6e:46:c8 comment="LAYER 2/3 NETWOR\
    K DEVICES /// Switch (POE) - Netgear GS305EP - Gigabit POE Switch for POE \
    WAPs (Network Closet)" mac-address=94:18:65:6E:46:C8 server=defconf
add address=10.0.2.2 client-id=1:d0:11:e5:6b:16:cb mac-address=\
    D0:11:E5:6B:16:CB server=defconf
add address=10.0.0.102 client-id=1:90:9:d0:63:c3:5a comment="NAS - Synology Di\
    skStation DS224+ - 2-Bay NAS and Plex Server (Network Closet)" \
    mac-address=90:09:D0:63:C3:5A server=defconf
add address=10.0.8.50 mac-address=BC:DD:C2:15:58:54 server=defconf
add address=10.0.7.4 comment="Alexa Echo Garage" mac-address=\
    E8:D8:7E:0A:5F:FB server=defconf
add address=10.0.8.104 comment="Kasa EP10 Smart Plug - Garage Fan 1" \
    mac-address=54:AF:97:84:42:91 server=defconf
add address=10.0.8.102 comment="Kasa EP10 Smart Plug - Garage Stereo" \
    mac-address=B4:B0:24:EA:A4:85 server=defconf
add address=10.0.8.101 comment="Kasa EP10 Smart Plug - Garage Party Lights" \
    mac-address=54:AF:97:84:3E:1B server=defconf
add address=10.0.8.105 comment="Kasa EP10 Smart Plug - Garage Fan 2" \
    mac-address=54:AF:97:84:59:CC server=defconf
add address=10.0.8.103 comment="Kasa EP10 Smart Plug - Ham Radio" \
    mac-address=B4:B0:24:EA:A4:74 server=defconf
add address=10.0.8.6 mac-address=78:8C:B5:A4:2A:42 server=defconf
add address=10.0.7.1 comment=\
    "IOT (SMART SPEAKERS/MEDIA) /// Google Chromecast Den" mac-address=\
    F4:F5:D8:75:87:F8 server=defconf
add address=10.0.7.7 comment="Alexa Echo Downstairs Bedroom" mac-address=\
    48:B4:23:F3:67:0C server=defconf
add address=10.0.7.8 comment="Alexa Echo Living Room" mac-address=\
    B0:73:9C:94:A4:8B server=defconf
add address=10.0.7.2 comment="Alexa Echo Kitchen" mac-address=\
    AC:41:6A:81:0E:E9 server=defconf
add address=10.0.7.3 client-id=1:7c:ed:c6:92:b6:e5 comment="Alexa Echo Den" \
    mac-address=7C:ED:C6:92:B6:E5 server=defconf
add address=10.0.4.3 mac-address=D8:13:99:3C:6D:5B server=defconf
add address=10.0.4.1 client-id=1:30:5:5c:60:a0:f6 comment=\
    "IT PERIPHERALS ///" mac-address=30:05:5C:60:A0:F6 server=defconf
add address=10.0.4.4 mac-address=F8:4F:AD:C9:69:43 server=defconf
add address=10.0.7.5 comment="Alexa Echo Upstairs Bedroom" mac-address=\
    44:6D:7F:84:A4:C9 server=defconf
add address=10.0.7.6 comment="Alexa Echo Upstairs Bathroom" mac-address=\
    68:B6:91:01:FC:4C server=defconf
add address=10.0.8.100 comment="Kasa EP10 Smart Plug - Laser Lamp" \
    mac-address=B4:B0:24:EA:A4:98 server=defconf
add address=10.0.9.4 mac-address=D0:73:D5:12:78:30 server=defconf
add address=10.0.8.51 mac-address=A4:CF:12:CC:13:77 server=defconf
add address=10.0.2.4 client-id=1:dc:a6:32:aa:fe:ed mac-address=\
    DC:A6:32:AA:FE:ED server=defconf
add address=10.0.2.65 client-id=1:3c:55:76:54:87:dd mac-address=\
    3C:55:76:54:87:DD server=defconf
add address=10.0.8.52 mac-address=A4:CF:12:CC:20:A9 server=defconf
add address=10.0.9.5 mac-address=D0:73:D5:12:65:B8 server=defconf
add address=10.0.2.1 client-id=1:d2:f3:44:0:89:96 comment=\
    "USER DEVICES (COMPUTERS, PHONES, TABLETS) ///" mac-address=\
    D2:F3:44:00:89:96 server=defconf
add address=10.0.9.1 comment="IOT (LIGHTBULBS) ///" mac-address=\
    78:42:1C:6A:65:F4 server=defconf
add address=10.0.9.2 mac-address=D0:73:D5:12:68:F4 server=defconf
add address=10.0.2.129 client-id=1:1e:54:d5:2e:fa:a8 mac-address=\
    1E:54:D5:2E:FA:A8 server=defconf
add address=10.0.2.6 client-id=1:3c:a6:f6:2a:50:69 mac-address=\
    3C:A6:F6:2A:50:69 server=defconf
add address=10.0.2.130 client-id=1:1a:9e:b4:3d:57:f8 mac-address=\
    1A:9E:B4:3D:57:F8 server=defconf
add address=10.0.6.4 client-id=1:18:b4:30:5c:ff:c1 comment=\
    "Google Nest Cam Driveway" mac-address=18:B4:30:5C:FF:C1 server=defconf
add address=10.0.6.3 client-id=1:18:b4:30:5d:76:bf comment=\
    "Google Nest Cam Backyard" mac-address=18:B4:30:5D:76:BF server=defconf
add address=10.0.6.2 client-id=1:18:b4:30:5d:3:66 comment=\
    "Google Nest Cam Doorbell" mac-address=18:B4:30:5D:03:66 server=defconf
add address=10.0.8.12 comment=\
    "Kasa HS300 Smart Plug (Strip) - Garage Attic (Lights 1-4, Fans 3-4)" \
    mac-address=5C:62:8B:A9:74:8C server=defconf
add address=10.0.6.1 client-id=1:94:3c:c6:32:cb:94 comment=\
    "IOT /// NodeMCU ESP32 for CircuitSetup energy monitor" mac-address=\
    94:3C:C6:32:CB:94 server=defconf
add address=10.0.8.11 comment="Dimmer Plug - Outdoor Kitchen Lights" \
    mac-address=B0:19:21:21:9D:A6 server=defconf
add address=10.0.8.1 comment="IOT - POWER DEVICES (SMART PLUGS / SWITCHES) ///\
    \_Kasa HS200 Smart Switch - Front Door Porch Light" mac-address=\
    98:25:4A:F8:72:99 server=defconf
add address=10.0.8.41 comment="Kasa EP40 Smart Outlet - Outdoor Outlet 2-x" \
    mac-address=5C:62:8B:AA:1C:B6 server=defconf
add address=10.0.9.8 mac-address=D0:73:D5:12:1D:E1 server=defconf
add address=10.0.7.50 mac-address=E4:F0:42:82:F4:A2 server=defconf
add address=10.0.0.103 client-id=1:0:18:61:5e:eb:e1 comment=\
    "Oooma VoIP Telephone Interface (Network Closet)" mac-address=\
    00:18:61:5E:EB:E1 server=defconf
add address=10.0.8.40 comment="Kasa EP40 Smart Outlet - Outdoor Outlet 1-x" \
    mac-address=B4:B0:24:80:66:73 server=defconf
add address=10.0.9.9 mac-address=D0:73:D5:12:74:F0 server=defconf
add address=10.0.9.11 mac-address=D0:73:D5:12:A0:D3 server=defconf
add address=10.0.9.10 mac-address=D0:73:D5:12:9A:2A server=defconf
add address=10.0.9.6 mac-address=D0:73:D5:12:55:5A server=defconf
add address=10.0.9.7 mac-address=D0:73:D5:12:B0:AA server=defconf
add address=10.0.2.131 client-id=1:92:ae:be:65:5:cf mac-address=\
    92:AE:BE:65:05:CF server=defconf
add address=10.0.8.14 comment="Kasa EP10 Smart Plug - Christmas Lights" \
    mac-address=78:8C:B5:A4:37:42 server=defconf
add address=10.0.6.5 client-id=1:64:16:66:6f:7:83 comment=\
    "Google Nest Hello - Doorbell" mac-address=64:16:66:6F:07:83 server=\
    defconf
add address=10.0.6.6 client-id=1:24:a1:60:2f:47:cd comment=\
    "Flume Water Flow Monitor" mac-address=24:A1:60:2F:47:CD
add address=10.0.10.1 client-id=1:ec:71:db:b3:e6:f comment=\
    "Surveillance Cameras /// SC-01-5 - RLC-820A" mac-address=\
    EC:71:DB:B3:E6:0F server=defconf
add address=10.0.8.53 mac-address=98:F4:AB:C2:E5:87 server=defconf
/ip dhcp-server network
add address=10.0.0.0/16 comment=defconf dns-server=1.1.1.2 gateway=10.0.0.1 \
    netmask=16
/ip dns
set allow-remote-requests=yes
/ip dns static
add address=10.0.0.1 name=router.lan
/ip firewall filter
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
add action=drop chain=forward comment=\
    "defconf:  drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN
/ip firewall nat
add action=masquerade chain=srcnat comment="defconf: masquerade" \
    ipsec-policy=out,none out-interface-list=WAN
add action=dst-nat chain=dstnat comment=\
    "Forward Plex traffic to Plex Media Server on Synology NAS" dst-port=\
    32400 protocol=tcp to-addresses=10.0.0.102 to-ports=32400
add action=dst-nat chain=dstnat comment=\
    "Plex Public Internet Access - Port Forwarding (TCP 32400 >> NAS IP)" \
    dst-port=32400 protocol=tcp to-addresses=10.0.2.1 to-ports=32400
/system clock
set time-zone-name=America/New_York
/system identity
set name="MikroTik hEX S"
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
