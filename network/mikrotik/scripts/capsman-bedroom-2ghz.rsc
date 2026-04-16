# CAPsMAN - Master Bedroom AP 2.4GHz provisioning
# Radio MAC: 18:FD:74:5C:C6:8C
# Channel 6 (2437 MHz) - non-overlapping with Ch1 (Down) and Ch11 (Up)

# 1. Create 2.4GHz channel 6
/caps-man channel add name=ch-2ghz-ch6 frequency=2437 band=2ghz-g/n comment="2.4GHz Channel 6"

# 2. Create CAPsMAN configurations (matching pattern of other APs)
/caps-man configuration add name=cfg-collective-2ghz-bed ssid=COLLECTIVE country="united states" security=sec-trusted datapath=datapath-trusted channel=ch-2ghz-ch6 comment="Trusted - 2.4GHz Bedroom"

/caps-man configuration add name=cfg-collective-iot-2ghz-bed ssid=COLLECTIVE-IOT country="united states" security=sec-iot datapath=datapath-iot channel=ch-2ghz-ch6 comment="IoT - 2.4GHz Bedroom"

/caps-man configuration add name=cfg-collective-guest-2ghz-bed ssid=COLLECTIVE-GUEST country="united states" security=sec-guest datapath=datapath-guest channel=ch-2ghz-ch6 comment="Guest - 2.4GHz Bedroom"

/caps-man configuration add name=cfg-collective-2g-bed ssid=COLLECTIVE-2G country="united states" security=sec-iot-2g datapath=datapath-iot channel=ch-2ghz-ch6 comment="Legacy IoT - 2.4GHz Bedroom"

# 3. Create provisioning rule for this AP's 2.4GHz radio
/caps-man provisioning add radio-mac=18:FD:74:5C:C6:8C action=create-dynamic-enabled master-configuration=cfg-collective-2ghz-bed slave-configurations=cfg-collective-iot-2ghz-bed,cfg-collective-guest-2ghz-bed,cfg-collective-2g-bed comment="Bedroom 2.4GHz - Ch 6"

# 4. Remove the unprovisioned cap29 interface so re-provisioning can create it fresh
/caps-man interface remove [find where name=cap29]
