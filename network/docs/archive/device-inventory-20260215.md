# Network Device Inventory
Generated: $(date)

## 📡 VLAN 10 - INFRASTRUCTURE (10.0.10.0/24)
**Total: 0 devices**
- (Empty - infrastructure devices need to be moved here)

## 👤 VLAN 20 - TRUSTED CLIENTS (10.0.20.0/24)  
**Total: 1 device**
- 10.0.20.250 - Pixel phone (22:FD:E3:21:18:81)

## 🏠 VLAN 30 - SHARED SERVICES (10.0.30.0/24)
**Total: 0 devices**
- (Empty - TVs, Chromecasts, Printers need to be moved here)

## 🔌 VLAN 40 - IoT DEVICES (10.0.40.0/24)
**Total: 38 devices (auto-migrated from COLLECTIVE-2G SSID!)**

### Smart Plugs (Kasa):
- 10.0.40.212 - HS200 Smart Switch
- 10.0.40.216 - HS200 Smart Switch  
- 10.0.40.232 - EP10 Smart Plug
- 10.0.40.249 - EP10 Smart Plug
- 10.0.40.245 - EP10 Smart Plug
- 10.0.40.246 - EP10 Smart Plug (Garage Party Lights)
- 10.0.40.230 - EP10 Smart Plug (Garage Fan 1)
- 10.0.40.231 - EP10 Smart Plug (Garage Stereo)
- 10.0.40.238 - EP10 Smart Plug
- 10.0.40.225 - EP10 Smart Plug (Ham Radio)
- 10.0.40.228 - EP40 Smart Plug
- 10.0.40.248 - EP40 Smart Plug
- 10.0.40.247 - HS300 Smart Strip
- 10.0.40.214 - KP405 Smart Plug
- 10.0.40.215 - KP405 Smart Plug

### Smart Bulbs (LIFX):
- 10.0.40.234 - LIFX Bulb
- 10.0.40.229 - LIFX Bulb
- 10.0.40.219 - LIFX Bulb
- 10.0.40.236 - LIFX Bulb
- 10.0.40.227 - LIFX Bulb

### Tasmota Devices:
- 10.0.40.223 - Tasmota Device
- 10.0.40.226 - Tasmota Device
- 10.0.40.224 - Tasmota Device
- 10.0.40.233 - Tasmota Device

### Smart Speakers (Alexa):
- 10.0.40.240 - Alexa Echo (48:B4:23:F3:67:0C)
- 10.0.40.244 - Alexa Echo (B0:73:9C:94:A4:8B)
- 10.0.40.213 - Alexa Echo (44:6D:7F:84:A4:C9)

### Chromecast:
- 10.0.40.211 - Chromecast Den
- 10.0.40.217 - Chromecast

### Other IoT:
- 10.0.40.250 - Circle (WiFi device)
- 10.0.40.220 - Smart device (18:B4:30:5D:03:66)
- 10.0.40.222 - Smart device (68:B6:91:01:FC:4C)
- 10.0.40.235 - Smart device (18:B4:30:5D:76:BF)
- 10.0.40.218 - Smart device (A0:85:E3:FB:D1:64)
- 10.0.40.221 - QCA device
- 10.0.40.237 - wle device
- 10.0.40.243 - Device (B8:5F:98:7B:72:DA)
- 10.0.40.242 - Eri device

## 👥 VLAN 50 - GUEST (10.0.50.0/24)
**Total: 0 devices**
- (Empty - no guests currently connected)

## 🌐 VLAN 60 - VPN (10.0.60.0/24)
**Total: 0 devices**  
- (VPN tunnel not yet configured)

## 📊 LEGACY/FLAT NETWORK (10.0.0.x - 10.0.9.x) - NEEDS MIGRATION
**Total: 6 devices on old "defconf" DHCP**

### Network Infrastructure:
- 10.0.0.102 - **NAS** - Synology DiskStation DS224+ → Should move to VLAN 20 or 30
- 10.0.0.103 - **Ooma VoIP** Interface → Should stay on infrastructure

### Computers/Devices:
- 10.0.2.2 - Mac (D0:11:E5:6B:16:CB) → Should move to VLAN 20
- 10.0.2.4 - homepi (Home Assistant?) → Should move to VLAN 30

### IT Peripherals:
- 10.0.4.1 - Brother Printer → Should move to VLAN 30

### Monitoring:
- 10.0.6.6 - Flume Water Flow Monitor → Should move to VLAN 40 (IoT)

---

## 📝 ACTION ITEMS

### High Priority - Shared Services (for guest casting/printing):
1. Move Chromecasts to VLAN 30:
   - Currently at 10.0.40.211, 10.0.40.217
   - Reconnect to COLLECTIVE SSID (Trusted)
   - Or create static assignments in VLAN 30

2. Move Printers to VLAN 30:
   - Brother Printer at 10.0.4.1
   - Should be at 10.0.30.x for guest access

### Medium Priority - Infrastructure:
1. Move NAS to appropriate VLAN:
   - Currently at 10.0.0.102
   - Options: VLAN 20 (Trusted) or VLAN 30 (Shared)
   
2. Move Home Assistant to VLAN 30:
   - Currently at 10.0.2.4
   - Needs to be at 10.0.30.x to control IoT devices

### Low Priority:
1. Disable old "defconf" DHCP server after migration complete
2. Add third AP (Master Bedroom)
3. Configure VPN tunnel (Phase 8)

---

## 🎯 QUICK WINS
1. **Chromecasts**: Forget current network, connect to COLLECTIVE, they'll be in VLAN 20 (Trusted). For guest access, we can add firewall exception or move to VLAN 30.
2. **Home Assistant**: Needs wired connection to VLAN 30 or static assignment
3. **NAS**: Can stay where it is for now, or move to VLAN 20 for better isolation

