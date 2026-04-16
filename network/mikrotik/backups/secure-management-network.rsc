# Management Network Security Rules
# Protects 10.0.0.0/16 management network from IoT and Guest VLANs
# Allows Trusted VLAN full access to all management devices
# Created: 2026-02-16

# ========================================
# INPUT CHAIN - Protect Router Management
# ========================================
# Add BEFORE existing "drop all not from LAN" rule (position 4)

/ip firewall filter
add action=drop chain=input comment="Block IoT from router management" \
    in-interface=vlan40-iot place-before=4

add action=drop chain=input comment="Block Guest from router management" \
    in-interface=vlan50-guest place-before=4


# ========================================
# FORWARD CHAIN - Protect Management Network & Inter-VLAN
# ========================================
# Add AFTER the "Allow ESPHome to Home Assistant API" rule (position 9)

# Allow Trusted VLAN full access to Management Network (switches, APs, router)
add action=accept chain=forward comment="Allow Trusted to Management Network" \
    dst-address=10.0.0.0/16 in-interface=vlan20-trusted place-before=10

# Allow Trusted to Shared VLAN
add action=accept chain=forward comment="Allow Trusted to Shared" \
    in-interface=vlan20-trusted out-interface=vlan30-shared place-before=10

# Allow Trusted to IoT (for management/troubleshooting)
add action=accept chain=forward comment="Allow Trusted to IoT" \
    in-interface=vlan20-trusted out-interface=vlan40-iot place-before=10

# Block IoT from Management Network
add action=drop chain=forward comment="Block IoT from Management Network" \
    dst-address=10.0.0.0/16 in-interface=vlan40-iot place-before=10

# Block Guest from Management Network
add action=drop chain=forward comment="Block Guest from Management Network" \
    dst-address=10.0.0.0/16 in-interface=vlan50-guest place-before=10

# Block Guest from Trusted VLAN
add action=drop chain=forward comment="Block Guest from Trusted" \
    in-interface=vlan50-guest out-interface=vlan20-trusted place-before=10

# Block Guest from IoT VLAN
add action=drop chain=forward comment="Block Guest from IoT" \
    in-interface=vlan50-guest out-interface=vlan40-iot place-before=10
