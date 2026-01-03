# vaxlan CAPsMAN Configuration
# MikroTik RB5009UPr+S+IN - RouterOS 7

# ============================================
# 1. Enable CAPsMAN Manager
# ============================================
/caps-man manager
set enabled=yes

# ============================================
# 2. Security Profiles
# ============================================

# Trusted Network (WPA2/WPA3)
/caps-man security
add name=sec-trusted \
    authentication-types=wpa2-psk,wpa3-psk \
    encryption=aes-ccm,ccmp-256 \
    passphrase="YOUR_TRUSTED_PASSWORD_HERE"

# IoT Network (WPA2 only - legacy compatibility)
/caps-man security
add name=sec-iot \
    authentication-types=wpa2-psk \
    encryption=aes-ccm \
    passphrase="YOUR_IOT_PASSWORD_HERE"

# Guest Network (WPA2/WPA3)
/caps-man security
add name=sec-guest \
    authentication-types=wpa2-psk,wpa3-psk \
    encryption=aes-ccm,ccmp-256 \
    passphrase="YOUR_GUEST_PASSWORD_HERE"

# ============================================
# 3. Channel Configuration
# ============================================

# 2.4 GHz Channel Plan
/caps-man channel
add name=ch-2ghz \
    band=2ghz-g/n \
    frequency=2412 \
    width=20mhz \
    extension-channel=disabled

# 5 GHz Channel Plan
/caps-man channel
add name=ch-5ghz \
    band=5ghz-a/n/ac \
    frequency=5180 \
    width=40mhz \
    extension-channel=Ce

# ============================================
# 4. Datapath Configuration (VLAN Mapping)
# ============================================

# Trusted Clients (VLAN 20)
/caps-man datapath
add name=dp-trusted \
    vlan-mode=use-tag \
    vlan-id=20

# IoT Devices (VLAN 40)
/caps-man datapath
add name=dp-iot \
    vlan-mode=use-tag \
    vlan-id=40

# Guest (VLAN 50)
/caps-man datapath
add name=dp-guest \
    vlan-mode=use-tag \
    vlan-id=50

# ============================================
# 5. SSID Configuration
# ============================================

# COLLECTIVE - Trusted (2.4 + 5 GHz)
/caps-man configuration
add name=cfg-collective \
    ssid=COLLECTIVE \
    security=sec-trusted \
    datapath=dp-trusted \
    channel=ch-2ghz \
    country=unitedstates

/caps-man configuration
add name=cfg-collective-5ghz \
    ssid=COLLECTIVE \
    security=sec-trusted \
    datapath=dp-trusted \
    channel=ch-5ghz \
    country=unitedstates

# COLLECTIVE-2G - Legacy IoT (2.4 GHz ONLY)
/caps-man configuration
add name=cfg-collective-2g \
    ssid=COLLECTIVE-2G \
    security=sec-iot \
    datapath=dp-iot \
    channel=ch-2ghz \
    country=unitedstates

# COLLECTIVE-IOT - New IoT (2.4 + 5 GHz)
/caps-man configuration
add name=cfg-collective-iot \
    ssid=COLLECTIVE-IOT \
    security=sec-iot \
    datapath=dp-iot \
    channel=ch-2ghz \
    country=unitedstates

/caps-man configuration
add name=cfg-collective-iot-5ghz \
    ssid=COLLECTIVE-IOT \
    security=sec-iot \
    datapath=dp-iot \
    channel=ch-5ghz \
    country=unitedstates

# COLLECTIVE-GUEST - Guest (2.4 + 5 GHz)
/caps-man configuration
add name=cfg-collective-guest \
    ssid=COLLECTIVE-GUEST \
    security=sec-guest \
    datapath=dp-guest \
    channel=ch-2ghz \
    country=unitedstates

/caps-man configuration
add name=cfg-collective-guest-5ghz \
    ssid=COLLECTIVE-GUEST \
    security=sec-guest \
    datapath=dp-guest \
    channel=ch-5ghz \
    country=unitedstates

# ============================================
# 6. Provisioning Rules
# ============================================

# Provision all APs with all SSIDs
/caps-man provisioning
add action=create-dynamic-enabled \
    master-configuration=cfg-collective \
    name-format=prefix-identity \
    name-prefix=cap

# ============================================
# NOTES:
# ============================================
# 1. Replace all passphrase placeholders with actual passwords
# 2. Adjust channel frequencies based on site survey
# 3. Adjust country code if not in United States
# 4. This assumes bridge with VLAN filtering is already configured
# 5. AP ports must be configured as trunk ports with VLANs 20,40,50 tagged
