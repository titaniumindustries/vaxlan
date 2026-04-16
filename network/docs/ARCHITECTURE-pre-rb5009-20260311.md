# Network Architecture & Intent (Pre-RB5009 Migration Snapshot)

**Snapshot Date:** 2026-03-11 (state immediately before RB5009 migration)  
**Last Updated:** 2026-03-01  
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
| 30 | Shared | 10.0.30.0/24 | Multi-VLAN services | Medium | NAS, Home Assistant, printers, Chromecasts |
| 40 | IoT | 10.0.40.0/24 | Smart home devices | Low | Smart bulbs, plugs, speakers, cameras |
| 50 | Guest | 10.0.50.0/24 | Visitor devices | Low | Guest phones/laptops |
| 60 | VPN | 10.0.60.0/24 | VPN-routed traffic | Medium | Reserved (not configured) |

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

| Source → Dest | Internet | Infra (10) | Trusted (20) | Shared (30) | IoT (40) | Guest (50) |
|---------------|----------|------------|--------------|-------------|----------|------------|
| **Infra (10)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Trusted (20)** | ✅ | ✅ | ✅ | ✅ | ✅ LIFX* | ❌ |
| **Shared (30)** | ✅ | ❌ | ❌ | ✅ | ✅ Control* | ❌ |
| **IoT (40)** | ✅ | ❌ | ❌ LIFX resp* | ⚠️ Selective** | ✅ | ❌ |
| **Guest (50)** | ✅ | ❌ | ❌ | ⚠️ Cast/Print** | ❌ | ✅ |

**Legend:**
- ✅ = Allowed
- ❌ = Blocked
- ⚠️ = Selective (specific ports/IPs only)
- *LIFX = UDP 56700 bidirectional for smart bulb control
- **Selective = Specific services (NAS SMB, Chromecast, Home Assistant API, printers)

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

### INPUT Chain
Order is critical - rules are processed top to bottom, first match wins.

1. Accept established/related/untracked
2. Drop invalid packets
3. **Allow DNS from all VLANs (UDP 53)** ← Must come before IoT/Guest blocks
4. **Allow DHCP from all VLANs (UDP 67-68)** ← Must come before IoT/Guest blocks
5. Accept ICMP (ping)
6. Block IoT from router management (SSH/WebFig/WinBox)
7. Block Guest from router management
8. Accept Plex traffic (TCP 32400) - if applicable
9. Drop all not from LAN interface list

### FORWARD Chain
Order is critical for security and functionality.

1. Log (optional, for debugging)
2. Fasttrack established connections (performance)
3. Accept IPsec policy (if applicable)
4. **Allow Trusted → Management network (10.0.0.0/16)**
5. **Allow Trusted → Shared (src=10.0.20.0/24 dst=10.0.30.0/24)**
6. **Allow Trusted → IoT for LIFX control (src=10.0.20.0/24 dst=10.0.40.0/24 proto=udp dst-port=56700)**
7. **Allow Shared → IoT for Home Assistant control (src=10.0.30.0/24 dst=10.0.40.0/24)**
8. Block IoT → Management network
9. Block IoT → Trusted (except LIFX responses)
10. Block IoT → Shared (except selective access)
11. Block Guest → Management
12. Block Guest → Trusted
13. Block Guest → IoT
14. **Allow LIFX responses (src=10.0.40.0/24 proto=udp src-port=56700 dst=10.0.20.0/24 or 10.0.30.0/24)**
15. Accept established/related/untracked
16. Drop invalid packets
17. Allow Guest → specific Shared IPs (Chromecast/Printer)
18. **Allow LAN → WAN (internet access)** ← Critical for all VLANs
19. Drop WAN → LAN (except DSTNAT)

**Key Configuration Notes:**
- Use `src-address`/`dst-address` for inter-VLAN rules, NOT `in-interface`/`out-interface` (VLANs are on bridge)
- Place specific rules BEFORE general block rules
- DNS/DHCP rules in INPUT chain MUST come before "Block IoT/Guest" rules

---

## Required Services

### DNS
- **Service:** Router acts as DNS resolver
- **Port:** UDP 53
- **Requirement:** All VLANs must be able to query router
- **Configuration:** `/ip dns` - `allow-remote-requests=yes`
- **Validation:** `nslookup google.com` from each VLAN

### DHCP
- **Service:** Router provides DHCP for all VLANs
- **Ports:** UDP 67 (server), UDP 68 (client)
- **Lease Time:** 24 hours (prevents frequent renewal interruptions)
- **Networks:**
  - VLAN 10: 10.0.10.0/24, gateway 10.0.10.1, pool .100-.250
  - VLAN 20: 10.0.20.0/24, gateway 10.0.20.1, pool .100-.250
  - VLAN 30: 10.0.30.0/24, gateway 10.0.30.1, pool .100-.250
  - VLAN 40: 10.0.40.0/24, gateway 10.0.40.1, pool .100-.250
  - VLAN 50: 10.0.50.0/24, gateway 10.0.50.1, pool .100-.250
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
  - **VLAN 40 (IoT):** **ENABLED** (`client-to-client-forwarding=yes`) - Required for Chromecast setup/casting and device discovery. Security trade-off: allows lateral movement between IoT devices at L2, but L3 isolation from Trusted/Shared maintained.
  - **VLAN 50 (Guest):** Default (disabled) - clients cannot communicate at L2
  - Configuration: `/caps-man datapath set [find name="datapath-X"] client-to-client-forwarding=yes/no`

---

## Hardware & Physical Topology

### Equipment
- **Router:** MikroTik hEX S (RB760iGS) - RouterOS 6.49.19
  - Management: 10.0.20.1 (reachable from VLAN 20)
  - Legacy: 10.0.0.1 (for AP management compatibility)
- **Access Points:** 2× MikroTik cAP ac (10.0.10.11, 10.0.10.12) - CAPsMAN managed
- **Switches:**
  - Netgear GS305EP (PoE) - Powers APs, VLAN trunk on ether3
  - Netgear GS108 - Shared services on ether2

### Physical Connections
```
Router (MikroTik hEX S)
├─ ether1 → WAN (ISP)
├─ ether2 → GS108 → Shared Services (VLAN 30)
│   ├─ NAS (10.0.30.10)
│   ├─ Home Assistant (10.0.30.11)
│   └─ Ooma VoIP (10.0.30.104)
├─ ether3 → GS305EP → APs (VLAN trunk - all VLANs tagged)
│   ├─ cAP ac Upstairs (10.0.10.11)
│   └─ cAP ac Downstairs (10.0.10.12)
├─ ether4 → Brother Printer (PVID=20, Trusted - mDNS workaround)
└─ ether5 → Break-glass / reserved (PVID=20, Trusted)
```

### Bridge Configuration
- **Bridge:** All VLANs as tagged interfaces on bridge
- **VLAN Filtering:** Enabled (`vlan-filtering=yes`)
- **Ingress Filtering:** Disabled (`ingress-filtering=no`)
- **Bridge Ports:** ether2-5 with appropriate PVIDs (ether1 is WAN)
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
nc -zv 10.0.40.234 56700             # LIFX control (if applicable)
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
ping -c 2 10.0.40.234                # IoT control access
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
**Validation:** `nc -zv 10.0.40.234 56700` from Trusted VLAN

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

### Plex streaming at 480p despite good WiFi
**Root Cause:** NAT rules pointing to old IP after VLAN migration  
**Symptoms:** TV can't reach local Plex server, falls back to relay  
**Fix:** Update DSTNAT rules to point to current NAS IP (10.0.30.10)  
**Validation:** `curl -I http://10.0.30.10:32400` from Trusted VLAN

---

## Key IPs & Credentials

### Infrastructure
- **Router:** 10.0.20.1 (VLAN 20 access), 10.0.0.1 (legacy)
- **AP Upstairs:** 10.0.10.11
- **AP Downstairs:** 10.0.10.12
- **PoE Switch:** 10.0.10.20

### Services
- **NAS (Synology):** 10.0.30.10 (hostname: synology)
- **Home Assistant:** 10.0.30.11 (hostname: homeassistant)
- **Brother Printer:** on Trusted VLAN (mDNS workaround)
- **Ooma VoIP:** 10.0.30.104

### IoT Devices (Selected)
- **Chromecast Audio (Kitchen):** 10.0.40.185 - Static IP, accessible from Trusted and Guest VLANs

### Router Access
- **User:** admin
- **Password:** x2230dallas!!!
- **SSH:** `ssh admin@10.0.20.1` or use sshpass
- **WebFig:** http://10.0.20.1
- **Backup command:** `SSHPASS='x2230dallas!!!' sshpass -e ssh admin@10.0.20.1 "/system backup save name=backup-$(date +%Y%m%d)"`

---

## Recent Changes

### 2026-03-01
- **Enabled IoT client-to-client forwarding:** Set `client-to-client-forwarding=yes` on datapath-iot to support Chromecast Audio setup and casting
- **Added Chromecast Audio device:** Static IP 10.0.40.185, added to shared-devices address list for Guest casting access
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
