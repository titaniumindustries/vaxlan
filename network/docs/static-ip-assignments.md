# Static IP Assignments

**Snapshot Date:** 2026-04-16
**Source:** Router DHCP static leases (`/ip dhcp-server lease print where dynamic=no`)

> **Keep this file in sync.** When adding, removing, or changing static DHCP reservations on the router, update this file to match. See the DHCP Changes checklist in `configuration-validation-checklist.md`.

---

## IP Addressing Convention (all VLANs)

| Range | Purpose |
|-------|---------|
| .1 | Router gateway |
| .2–.9 | Reserved for explicit, intentional use |
| .10–.99 | Static DHCP reservations |
| .100–.250 | Dynamic DHCP pool |

---

## VLAN 10 — Infrastructure (dhcp-infra)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.10.11 | AP Upstairs Office | 74:4D:28:5F:80:1E | MikroTik cAP ac Upstairs Office |
| 10.0.10.12 | AP Downstairs Den | 74:4D:28:D4:7E:3F | MikroTik cAP ac Downstairs Den |
| 10.0.10.13 | AP Master Bedroom | 18:FD:74:5C:C6:8A | MikroTik cAP ac Master Bedroom |
| 10.0.10.20 | Switch GS305EP | 94:18:65:6E:46:C8 | GS305EP |

## VLAN 30 — Shared (dhcp-shared)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.30.10 | NAS Synology DS224+ | 90:09:D0:63:C3:5A | synology |
| 10.0.30.11 | Home Assistant RPi | DC:A6:32:AA:FE:ED | homeassistant |
| 10.0.30.12 | Brother HL-L2360DW Printer | 30:05:5C:60:A0:F6 | BROTHER-HL-L2360DW |

*Note: Ooma VoIP (10.0.30.104) uses device-side static — no router reservation.*

## VLAN 20 — Trusted (dhcp-trusted)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.20.10 | Pixel 6 Pro | 22:FD:E3:21:18:81 | Pixel-6-Pro |

*Note: Android uses per-SSID randomized MACs. This reservation is tied to the COLLECTIVE SSID.*

## VLAN 40 — IoT (dhcp-iot)

### LIFX Bulbs (.11–.17)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.11 | LIFX - Garage Hanging North | D0:73:D5:12:9A:2A | LIFX Color 1000 |
| 10.0.40.12 | LIFX - Garage Hanging South | D0:73:D5:12:74:F0 | LIFX_Color_1000_1274f0_AJ |
| 10.0.40.13 | LIFX - Garage Spot North | D0:73:D5:12:B0:AA | *(never seen)* |
| 10.0.40.14 | LIFX - Garage Attic | D0:73:D5:12:1D:E1 | LIFX_Color_1000_BR30_121de1_AJ |
| 10.0.40.15 | LIFX - Living Room Table Lamp | D0:73:D5:12:65:B8 | LIFX_Color_1000_1265b8_AJ |
| 10.0.40.16 | LIFX - Office Table Lamp | D0:73:D5:12:78:30 | LIFX_Color_1000_127830_AJ |
| 10.0.40.17 | LIFX - Unknown BR30 (identify location) | D0:73:D5:12:55:5A | LIFX Color 1000 BR30 |

### Brother Scanner (.35)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.35 | Brother Scanner (WiFi) | A8:A7:95:B6:69:76 | Brother-ADS1500W-Scanner |

### Kasa Devices (.20–.34)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.20 | Kasa HS200 - Front Door | 98:25:4A:F8:72:99 | HS200 |
| 10.0.40.21 | Kasa HS200 - Back Door | 98:25:4A:F8:88:8E | HS200 |
| 10.0.40.22 | Kasa KP405 - Outdoor Kitchen Lights | B0:19:21:21:9D:A6 | KP405 |
| 10.0.40.23 | Kasa KP405 - Firepit Lights | 54:AF:97:21:1C:91 | KP405 |
| 10.0.40.24 | Kasa EP10 - Ham Radio | B4:B0:24:EA:A4:74 | EP10 |
| 10.0.40.25 | Kasa EP10 - Garage Fan 1 | 54:AF:97:84:42:91 | EP10 |
| 10.0.40.26 | Kasa EP10 - Garage Fan 2 | 54:AF:97:84:59:CC | EP10 |
| 10.0.40.27 | Kasa EP10 - Garage Stereo | B4:B0:24:EA:A4:85 | EP10 |
| 10.0.40.28 | Kasa EP10 - Garage Party Lights | 54:AF:97:84:3E:1B | EP10 |
| 10.0.40.29 | Kasa EP10 - Laser Lamp | B4:B0:24:EA:A4:98 | EP10 |
| 10.0.40.30 | Kasa EP10 - TV | 78:8C:B5:A4:2A:42 | EP10 |
| 10.0.40.31 | Kasa EP10 - Porch Speakers | 78:8C:B5:A4:07:EE | EP10 |
| 10.0.40.32 | Kasa EP40 - Outdoor Outlet 1 | B4:B0:24:80:66:73 | EP40 |
| 10.0.40.33 | Kasa EP40 - Outdoor Outlet 2 | 5C:62:8B:AA:1C:B6 | EP40 |
| 10.0.40.34 | Kasa HS300 - Power Strip | 5C:62:8B:A9:74:8C | HS300 |

### Chromecasts (.40–.41)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.40 | Chromecast - Guest Bedroom TV | E4:F0:42:82:F4:A2 | Chromecast |
| 10.0.40.41 | Chromecast Audio Kitchen | A4:77:33:F8:98:6E | Chromecast-Audio |
| 10.0.40.42 | Chromecast - Den | F4:F5:D8:75:87:F8 | Chromecast |

### Roku TVs (.60–.62)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.60 | Roku TV - Den 55in | D8:13:99:3C:6D:5B | 55TCLRokuTV |
| 10.0.40.61 | Roku TV - Master Bedroom 40in | C4:8B:66:88:D6:D6 | MasterBedroom40TCLRokuTV |
| 10.0.40.62 | Roku TV - Guest Bedroom 43in | F8:4F:AD:C9:69:43 | GuestBedroom-43TCLRokuTV |

### Misc/Overflow IoT (.63–.69)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.64 | Amazon Echo Dot - Living Room | B0:73:9C:94:A4:8B | *(no hostname)* |
| 10.0.40.65 | Amazon Echo - Kitchen | AC:41:6A:81:0E:E9 | *(no hostname)* |

### Audio Streamers (.70–.79)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.70 | WiiM Mini - Porch | 40:FD:F3:1C:76:00 | WiiM Mini-7600 |

### ESPHome Athom Temp/Humidity Sensors (.71–.80 reserved)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.71 | ESPHome Athom Temp/Humidity-48 | FC:01:2C:60:9F:48 | athom-tem-hum-sensor-609f48 |
| 10.0.40.72 | ESPHome Athom Temp/Humidity-D8 | FC:01:2C:60:9F:D8 | athom-tem-hum-sensor-609fd8 |

*Reserved for future Athom temp/humidity sensors: 10.0.40.73–10.0.40.80.*

### Tasmota Outlets (.81–.87)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.81 | Tasmota-Outlet-01 - Workshop Radios | A4:CF:12:CC:13:77 | tasmota-01-CC1377 |
| 10.0.40.82 | Tasmota-Outlet-02 - Workshop Charging Station | BC:DD:C2:15:58:54 | tasmota-02-155854 |
| 10.0.40.83 | Tasmota-Outlet-03 - Unused | EC:FA:BC:49:40:A6 | tasmota-03-4940A6 |
| 10.0.40.84 | Tasmota-Outlet-04 - Kneewall Dehumidifier | A4:CF:12:CC:20:A9 | tasmota-04-CC20A9 |
| 10.0.40.85 | Tasmota-Outlet-05 - Unused | 98:F4:AB:C2:E5:87 | tasmota-05-C2E587 |
| 10.0.40.86 | Tasmota-Outlet-06 - Network Infrastructure (new) | 78:42:1C:F2:7B:40 | tasmota-F27B40-6976 |
| 10.0.40.87 | Tasmota-Outlet-07 - Jonathan's Computer & Treadmill | 78:42:1C:F2:77:A4 | tasmota-F277A4-6052 |

### Other IoT (.90–.99)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.90 | Flume Water Monitor Gateway | 24:A1:60:2F:47:CD | Flume-GW-47CD |
| 10.0.40.91 | Nest Hello Doorbell | 64:16:66:6F:07:83 | Nest-Hello-0783 |
| 10.0.40.92 | Amazon Echo/Alexa 1 | 7C:ED:C6:92:B6:E5 | amazon-f1aae73a0 |
| 10.0.40.93 | Amazon Echo/Alexa 2 | B8:5F:98:7B:72:DA | *(no hostname)* |
| 10.0.40.94 | Amazon Echo/Alexa 3 | E8:D8:7E:0A:5F:FB | *(no hostname)* |
| 10.0.40.95 | Amazon Echo/Alexa 4 | 48:B4:23:F3:67:0C | *(no hostname)* |
| 10.0.40.96 | Amazon Echo/Alexa 5 | 68:B6:91:01:FC:4C | *(no hostname)* |
| 10.0.40.97 | Amazon Echo/Alexa 6 | 44:6D:7F:84:A4:C9 | *(no hostname)* |
| 10.0.40.98 | Amazon Echo/Alexa 7 | A0:85:E3:FB:D1:64 | *(no hostname)* |
| 10.0.40.99 | LG ThinQ Clothes Dryer | 74:40:BE:37:B0:3E | QCA4002 |

*Washer = `00:51:ED:79:DA:50` (LG Innotek / QCA4002, dynamic IP — needs a static IP mapping).*

### Nest Cams (.52–.53)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.52 | Nest Cam - Driveway | 18:B4:30:5D:76:BF | *(no hostname)* |
| 10.0.40.53 | Nest Cam - Backyard | 18:B4:30:5D:03:66 | *(no hostname)* |

### Nest Protects (.55–.58)

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.55 | Nest Protect - Kids Room | 18:B4:30:9E:56:F0 | *(no hostname)* |
| 10.0.40.56 | Nest Protect - Master Bedroom | 18:B4:30:A8:09:C6 | *(no hostname)* |
| 10.0.40.57 | Nest Protect - Office | 18:B4:30:A8:0E:23 | *(no hostname)* |
| 10.0.40.58 | Nest Protect - Kitchen | 18:B4:30:AB:3B:42 | *(no hostname)* |

### Other / Controllers

| IP | Device | MAC | Hostname |
|----|--------|-----|----------|
| 10.0.40.10 | ESPHome Energy Monitor 1 - CircuitSetup | 94:3C:C6:32:CB:94 | circuitsetup-energy-mon-32cb94 |
| 10.0.40.50 | SHOWFINDER - torrent laptop | 3C:55:76:54:87:DD | showfinder |
| 10.0.40.51 | WLED LED Controller | 00:4B:12:4A:7F:28 | wled-WLED |

## VLAN 70 — CCTV (dhcp-cctv)

*No static reservations yet (no cameras connected).*
