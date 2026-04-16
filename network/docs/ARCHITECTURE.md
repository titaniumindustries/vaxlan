# Network Architecture & Intent

**Last Updated:** 2026-03-11  
**Purpose:** Define network intent, validate configuration alignment, document implementation

---

## Network Intent & Security Model

### Core Principle
Zero-trust network segmentation: isolate untrusted devices (IoT, guests) from trusted devices (personal) and sensitive services (NAS, Home Assistant) while maintaining required functionality.

### Trust Levels
1. **High Trust** - Infrastructure (VLAN 10), Trusted clients (VLAN 20)
2. **Medium Trust** - Shared services (VLAN 30)
3. **Low Trust (Isolated)** - IoT devices (VLAN 40), Guests (VLAN 50)

---

## Network Segmentation

### VLAN Design
| VLAN | Name | Subnet | Purpose | Trust | Example Devices |
|------|------|--------|---------|-------|-----------------|
| 10 | Infrastructure | 10.0.10.0/24 | Network equipment management | High | Router, switches, AP management |
| 20 | Trusted | 10.0.20.0/24 | Personal devices | High | Laptops, phones, tablets |
| 30 | Shared | 10.0.30.0/24 | Multi-VLAN services | Medium | NAS, Home Assistant, Brother printer, Chromecasts |
| 40 | IoT | 10.0.40.0/24 | Smart home devices | Low | Smart bulbs, plugs, speakers, cameras |
| 50 | Guest | 10.0.50.0/24 | Visitor devices | Low | Guest phones/laptops |
| 60 | VPN | 10.0.60.0/24 | VPN-routed traffic | Medium | Reserved (not configured) |
| 70 | CCTV | 10.0.70.0/24 | Surveillance cameras | Low (Isolated) | Reolink PoE cameras (wired only) |

### SSID to VLAN Mapping
| SSID | VLAN | Bands | Purpose |
|------|------|-------|---------|
| COLLECTIVE | 20 | 2.4/5GHz | Trusted personal devices |
| COLLECTIVE-IOT | 40 | 2.4/5GHz | New IoT devices |
| COLLECTIVE-2G | 40 | 2.4GHz only | Legacy IoT (maintains old password) |
| COLLECTIVE-GUEST | 50 | 2.4/5GHz | Guest network |

---

## Access Control Matrix

### FORWARD Chain (Inter-VLAN Traffic)

| Source → Dest | Internet | Infra (10) | Trusted (20) | Shared (30) | IoT (40) | Guest (50) | CCTV (70) |
|---------------|----------|------------|--------------|-------------|----------|------------|------------|
| **Infra (10)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Trusted (20)** | ✅ | ✅ | ✅ | ✅ | ✅ LIFX* | ❌ | ✅ WebUI* |
| **Shared (30)** | ✅ | ❌ | ❌ | ✅ | ✅ Control* | ❌ | ❌ |
| **IoT (40)** | ✅ | | **Guest (50)** | ✅ | ❌ | ❌ | ⚠️ Cast/Print** | ❌ | ✅ | ❌ |
| **CCTV (70)** | ❌ | ❌ | ❌ | ⚠️ NAS only** | ❌ | ❌ | ✅ |

**Legend:**
- ✅ = Allowed
- ❌ = Blocked
- ⚠️ = Selective (specific ports/IPs only)
- *LIFX = UDP 56700 bidirectional for smart bulb control
- **Selective = Specific services (NAS SMB, Chromecast, Home Assistant API, printers)
- *WebUI = HTTP/HTTPS for camera configuration
- *NAS only = RTSP 554, Reolink 9000/TCP for recording to NAS

### INPUT Chain (Access to Router Services)

| Source | DNS (UDP 53) | DHCP (UDP 67-68) | ICMP | SSH/WebFig/WinBox | Reason |
|--------|--------------|------------------|------|-------------------|--------|
| **All VLANs** | ✅ | ✅ | ✅ | - | Required for network function |
| **Trusted (20)** | ✅ | ✅ | ✅ | ✅ | Administrative access |
| **IoT (40)** | ✅ | ✅ | ✅ | ❌ | Security isolation |
| **Guest (50)** | ✅ | ✅ | ✅ | ❌ | Security isolation |

**Critical:** IoT and Guest VLANs MUST be able to reach router for DNS/DHCP. Blocking these breaks internet access.

---

## Firewall Rule Order

See [`firewall-rules.md`](firewall-rules.md) for the complete INPUT/FORWARD/NAT rules reference.

**Key principles:**
- Allow rules for specific services must appear BEFORE blanket drop rules for the same source
- Use `src-address`/`dst-address` for inter-VLAN rules, NOT `in-interface`/`out-interface` (VLANs are on bridge)
- DNS/DHCP INPUT rules for IoT/Guest/CCTV must come before their management block rules

---

## Required Services

### DNS
- **Service:** Router acts as DNS resolver
- **Port:** UDP 53
- **Requirement:** All VLANs must be able to query router
- **Configuration:** `/ip dns` - `allow-remote-requests=yes`
- **mDNS Reflection:** Enabled via `mdns-repeat-ifaces` on Trusted, Shared, IoT, Guest VLANs
  - Enables cross-VLAN Bonjour discovery (printers, Chromecast, ESPHome)
- **Validation:** `nslookup google.com` from each VLAN

### DHCP
- **Service:** Router provides DHCP for all VLANs
- **Ports:** UDP 67 (server), UDP 68 (client)
- **Lease Time:** 24 hours (prevents frequent renewal interruptions)
- **IP Addressing Convention (all VLANs):**
  - **.1** — Router gateway
  - **.2–.9** — Reserved for explicit, intentional use
  - **.10–.99** — Static DHCP reservations
  - **.100–.250** — Dynamic DHCP pool
- **Networks:**
  - VLAN 10: 10.0.10.0/24, gateway 10.0.10.1, pool .100-.250
  - VLAN 20: 10.0.20.0/24, gateway 10.0.20.1, pool .100-.250
  - VLAN 30: 10.0.30.0/24, gateway 10.0.30.1, pool .100-.250
  - VLAN 40: 10.0.40.0/24, gateway 10.0.40.1, pool .100-.250
  - VLAN 50: 10.0.50.0/24, gateway 10.0.50.1, pool .100-.250
  - VLAN 70: 10.0.70.0/24, gateway 10.0.70.1, pool .100-.250
- **Static IP Reference:** See [`static-ip-assignments.md`](static-ip-assignments.md) for full device-to-IP mapping
- **Validation:** New device gets IP automatically on each VLAN

### NAT (Internet Access)
- **Service:** Source NAT (masquerade) for all VLANs to WAN
- **Configuration:** `/ip firewall nat` - `chain=srcnat action=masquerade out-interface-list=WAN`
- **Validation:** `ping 8.8.8.8` succeeds from all VLANs

### CAPsMAN (Wireless Management)
- **Service:** Centralized AP management
- **Configuration:**
  - Datapaths with VLAN tagging: `vlan-mode=use-tag vlan-id=X bridge=bridge`
  - Security profiles per SSID
  - Provisioning rules for automatic AP adoption
- **Bridge VLAN Filtering:** Enabled - requires proper VLAN configuration on bridge ports
- **Client-to-Client Forwarding (AP Isolation):**
  - **VLAN 20 (Trusted):** Default (disabled) - clients cannot communicate at L2
  - **VLAN 30 (Shared):** No wireless SSID configured
  - **VLAN 40 (IoT):** Default (disabled) - Chromecast casting works cross-VLAN via mDNS reflection + L3 routing; c2c forwarding no longer needed. Disabled 2026-03-11 to prevent L2 lateral movement between IoT devices.
  - **VLAN 50 (Guest):** Default (disabled) - clients cannot communicate at L2
  - Configuration: `/caps-man datapath set [find name="datapath-X"] client-to-client-forwarding=yes/no`

---

## Hardware & Physical Topology

See [`hardware-software-inventory.md`](hardware-software-inventory.md) for full specs, MAC addresses, and DHCP reservations.

### Equipment Summary
- **Router:** MikroTik RB5009UPr+S+IN (RouterOS 7.19.6) — 10.0.20.1
- **Access Points:** 3× MikroTik cAP ac (CAPsMAN, router PoE) — 10.0.10.11, 10.0.10.12, 10.0.10.13
- **Switches:** Netgear GS108 (unmanaged, Shared/ether7), Netgear GS305EP (PoE, CCTV/ether3)

### Physical Connections
```
Router (MikroTik RB5009UPr+S+IN)
├─ ether1 → Break-glass / reserved (2.5G, VLAN 20 untagged)
├─ ether2 → Available (VLAN 20 untagged)
├─ ether3 → GS305EP → CCTV Cameras (VLAN 70 untagged, future)
├─ ether4 → AP Master Bedroom (PoE, VLAN 10 untagged + 20,40,50 tagged)
├─ ether5 → AP Downstairs Den (PoE, VLAN 10 untagged + 20,40,50 tagged)
├─ ether6 → AP Upstairs Office (PoE, VLAN 10 untagged + 20,40,50 tagged)
├─ ether7 → GS108 → Shared Services (VLAN 30 untagged)
│   ├─ NAS (10.0.30.10)
│   ├─ Home Assistant (10.0.30.11)
│   ├─ Brother HL-L2360DW Printer (10.0.30.12, mDNS discoverable from Trusted)
│   └─ Ooma VoIP (10.0.30.104)
└─ ether8 → WAN (ISP, NOT on bridge, DHCP client)
```

### Bridge Configuration
- **Bridge:** All VLANs as tagged interfaces on bridge
- **VLAN Filtering:** Enabled (`vlan-filtering=yes`)
- **Ingress Filtering:** Enabled (`ingress-filtering=yes`)
- **Bridge Ports:** ether1-7 with appropriate PVIDs (ether3 PVID=70 for CCTV, ether8 is WAN, not on bridge)
- **VLAN Table:** Each VLAN tagged on bridge + relevant ports

---

## Configuration Validation Checklist

Run these tests after any firewall or VLAN changes:

### From Trusted VLAN (COLLECTIVE)
```bash
ping -c 2 8.8.8.8                    # Internet
ping -c 2 10.0.30.10                 # NAS access
nslookup google.com                  # DNS
ssh admin@10.0.20.1                  # Router management
nc -zv 10.0.40.12 56700              # LIFX control (if applicable)
```

### From IoT VLAN (COLLECTIVE-IOT)
```bash
ping -c 2 8.8.8.8                    # Internet
nslookup google.com                  # DNS
ping -c 2 10.0.20.1                  # Should FAIL (no management access)
```

### From Shared VLAN (via SSH to NAS/HA)
```bash
ping -c 2 8.8.8.8                    # Internet
ping -c 2 10.0.40.12                 # IoT control access
ping -c 2 10.0.20.244                # Should FAIL (no access to Trusted)
```

### From Router
```bash
ssh admin@10.0.20.1
/ip firewall connection print count-only where src-address~"10.0.40"
# Should show active connections from IoT to internet
```

**Expected Results:**
- ✅ All VLANs have internet
- ✅ All VLANs can resolve DNS
- ✅ Trusted can access Shared and IoT (LIFX)
- ✅ Shared can access IoT
- ❌ IoT CANNOT access Trusted or router management
- ❌ Guest CANNOT access Trusted, IoT, or router management

---

## Common Issues & Root Causes

### IoT devices have no internet
**Root Cause:** INPUT chain blocking DNS/DHCP from IoT before allowing them  
**Symptoms:** Devices connect, get IP, but cannot resolve hostnames or route  
**Fix:** Ensure "Allow DNS from all VLANs" and "Allow DHCP from all VLANs" rules come BEFORE "Block IoT from router management" in INPUT chain  
**Validation:** `nslookup google.com` from IoT device

### Cannot control LIFX bulbs from Trusted/Shared
**Root Cause:** Firewall blocking UDP 56700 bidirectional  
**Symptoms:** LIFX app cannot discover or control bulbs  
**Fix:** Add FORWARD rules allowing Trusted/Shared → IoT UDP 56700 AND IoT → Trusted/Shared from UDP 56700  
**Validation:** `nc -zv 10.0.40.12 56700` from Trusted VLAN

### Frequent WiFi disconnections
**Root Cause:** DHCP lease time too short (e.g., 10 minutes)  
**Symptoms:** Devices show "disconnected" briefly every few minutes  
**Fix:** Set DHCP lease time to 24 hours: `/ip dhcp-server set [find name=dhcp-X] lease-time=1d`  
**Validation:** Check lease: `/ip dhcp-server lease print detail`

### Cannot ping cross-VLAN but internet works
**Root Cause:** Firewall rules using `in-interface`/`out-interface` instead of IP addresses  
**Symptoms:** Inter-VLAN traffic blocked, but internet (LAN→WAN) works  
**Fix:** Use `src-address=10.0.X.0/24 dst-address=10.0.Y.0/24` for inter-VLAN rules  
**Why:** VLANs are on bridge, so in/out interfaces both show as "bridge" for inter-VLAN routing

### Brother printer not printing / wired interface inactive
**Root Cause:** Brother HL-L2360DW disables wired ethernet when WiFi is enabled (mutual exclusion)
**Symptoms:** Wired IP unreachable, web admin shows "Ethernet 10/100BASE-TX (Inactive)", printing fails from all devices
**Fix:** In printer web admin, ensure wired interface is set as the only active interface. Disable WiFi.
**Note:** The printer has separate wired (30:05:5C:60:A0:F6) and WiFi (38:B1:DB:BE:FF:5D) MACs. The WiFi MAC is different from the scanner (A8:A7:95:B6:69:76). Static DHCP reservation must include `client-id` to match correctly.

### Plex streaming at 480p despite good WiFi
**Root Cause:** NAT rules pointing to old IP after VLAN migration  
**Symptoms:** TV can't reach local Plex server, falls back to relay  
**Fix:** Update DSTNAT rules to point to current NAS IP (10.0.30.10)  
**Validation:** `curl -I http://10.0.30.10:32400` from Trusted VLAN

---

## Key IPs & Credentials

### Infrastructure
- **Router:** 10.0.20.1 (VLAN 20 access)
- **AP Upstairs Office:** 10.0.10.11
- **AP Downstairs Den:** 10.0.10.12
- **AP Master Bedroom:** 10.0.10.13

### Services
- **NAS (Synology):** 10.0.30.10 (hostname: synology)
- **Home Assistant:** 10.0.30.11 (hostname: homeassistant)
- **Brother HL-L2360DW Printer:** 10.0.30.12 (wired MAC: 30:05:5C:60:A0:F6, on GS108)
- **Ooma VoIP:** 10.0.30.104

### IoT Devices (Selected)
- **WiiM Mini (Porch):** 10.0.40.70 - Static IP, controlled from Trusted via mDNS (`_linkplay._tcp.local`)
- **Brother ADS-1500W Scanner:** 10.0.40.85 (WiFi MAC: A8:A7:95:B6:69:76, COLLECTIVE-IOT)
- **LG ThinQ Clothes Dryer:** 10.0.40.99 (MAC: 74:40:BE:37:B0:3E, COLLECTIVE-IOT)
- **LG ThinQ Clothes Washer:** Dynamic IP (MAC: 00:51:ED:79:DA:50, COLLECTIVE-IOT)

### Router Access
- **User:** admin
- **SSH:** `ssh vaxlan-router` (preferred) or `ssh admin@10.0.20.1` with key auth
- **WebFig:** http://10.0.20.1
- **Backup command:** `ssh vaxlan-router "/system backup save name=backup-$(date +%Y%m%d)"`

---

## Recent Changes
### 2026-04-05
- **Clarified LG laundry appliance mapping on COLLECTIVE-IOT:** Dryer is MAC `74:40:BE:37:B0:3E` (static 10.0.40.99). Washer is the other LG device with MAC `00:51:ED:79:DA:50`. Updated static-IP and inventory docs/comments for explicit MAC-based identification.

### 2026-03-22
- **Fixed Brother printer connectivity:** Wired ethernet was inactive because WiFi had been enabled (Brother disables wired when WiFi is active). Set wired as only active interface in printer web admin.
- **Fixed printer DHCP reservation:** Old static reservation at 10.0.30.12 never matched because it lacked `client-id`. Removed stale entries, recreated with correct `client-id="1:30:5:5c:60:a0:f6"`. Printer will get 10.0.30.12 on next renewal.
- **Identified Brother ADS-1500W Scanner:** Separate device on COLLECTIVE-IOT WiFi (10.0.40.85, MAC A8:A7:95:B6:69:76). Not the printer.
- **Confirmed firewall is correct for printing:** Trusted→Shared (rule 13) allows all traffic. mDNS reflection on Shared VLAN enables Bonjour discovery. No changes needed.

### 2026-03-20
- **Added MQTT firewall rule:** IoT (10.0.40.0/24) → HA (10.0.30.11) TCP 1883. Tasmota outlets (and any future MQTT IoT devices) need to initiate connections to the Mosquitto broker on Home Assistant. Placed before IoT→Shared drop rule. Subnet-wide source since MQTT is a core HA service.

### 2026-03-11
- **Migrated from hEX S to RB5009UPr+S+IN:**
- **APs now powered directly by router PoE:** Eliminated GS305EP from AP path
- **Enabled mDNS reflection:** `mdns-repeat-ifaces` on Trusted, Shared, IoT, Guest VLANs
- **mDNS verified working:** Brother printer, Chromecast Audio, and ESPHome all discoverable cross-VLAN. Required adding firewall rules to allow UDP 5353 from IoT/Guest before management block rules.
- **Disabled IoT client-to-client forwarding:** No longer needed — Chromecast casting works cross-VLAN via mDNS reflection + L3 routing. Improves IoT security by preventing L2 lateral movement.
- **Printer moved to GS108:** Brother printer moved from ether2 (Trusted) to GS108 (Shared VLAN 30), discoverable from Trusted via Bonjour
- **Installed wireless package:** Required for legacy CAPsMAN with cAP ac APs on RouterOS 7
- **New port layout:** ether1=break-glass (2.5G), ether3=GS305EP (CCTV), ether5/6=APs, ether7=GS108, ether8=WAN
- **Removed legacy 10.0.0.1/16 address:** Clean VLAN-only addressing
- **Pre-migration architecture archived:** `docs/ARCHITECTURE-pre-rb5009-20260311.md`
- **CCTV VLAN 70 planned:** Dedicated isolated VLAN for Reolink cameras on ether3 (GS305EP). Internet blocked, NAS-only recording access, web UI from Trusted. No cameras connected yet.

### 2026-03-14
- **Consolidated IoT static IPs to .10–.99 range:** Moved 24 static DHCP reservations out of the dynamic pool (.100–.250) into .10–.99. Grouped by device type: LIFX .11–.16, Kasa .20–.34, Chromecast .40–.41, WLED .51. Updated firewall rule and address-list entry for Chromecast Audio (.185→.41). Established IP addressing convention for all VLANs: .1 gateway, .2–.9 reserved, .10–.99 static, .100–.250 dynamic.
- **Added Chromecast Guest Bedroom TV:** Static reservation 10.0.40.40, MAC E4:F0:42:82:F4:A2. Previously unlabeled dynamic lease.
- **Set interface comments on all ethernet ports:** Descriptive labels for ether1–8 and sfp-sfpplus1 visible in WebFig interface list.

### 2026-03-12
- **Connected third AP (Master Bedroom):** ether4, 1Gbps, PoE. CAPsMAN fully provisioned: 2.4GHz Ch6 (COLLECTIVE, COLLECTIVE-IOT, COLLECTIVE-GUEST, COLLECTIVE-2G) + 5GHz Ch149/80MHz (COLLECTIVE, COLLECTIVE-IOT, COLLECTIVE-GUEST).
- **AP local config complete:** Factory reset, DHCP client (10.0.10.13), identity set, password synced, LEDs off. AP runs RouterOS 6.48.6 (compatible with CAPsMAN on RouterOS 7 via wireless package).
- **CCTV VLAN 70 pushed to router:** Bridge VLAN, DHCP, firewall rules all configured. Untested (no cameras yet).

### 2026-03-01
- **Enabled IoT client-to-client forwarding:** Set `client-to-client-forwarding=yes` on datapath-iot to support Chromecast Audio setup and casting
- **Added Chromecast Audio device:** Static IP 10.0.40.185 (moved to 10.0.40.41 on 2026-03-14), added to shared-devices address list for Guest casting access
- **Documented AP isolation settings:** Added client-to-client forwarding configuration for all VLANs in CAPsMAN section

### 2026-02-20
- **Fixed IoT internet access:** Added DNS (UDP 53) and DHCP (UDP 67-68) INPUT chain rules before IoT block
- **Added LIFX control:** UDP 56700 bidirectional rules for Trusted/Shared ↔ IoT
- **Fixed Plex NAT:** Updated DSTNAT rules to point to 10.0.30.10
- **Increased DHCP lease times:** 10min → 24 hours (all VLANs)
- **Created ARCHITECTURE.md:** Consolidated intent and implementation

### 2026-02-19
- Switched 5GHz from DFS channel 128 to non-DFS channel 36
- Created band-specific CAPsMAN provisioning rules
- Increased 5GHz channel width to 80MHz

---

## Future Work

See `TODO.md` for current action items and known issues.
