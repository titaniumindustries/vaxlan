# Home Network Architecture – Final Summary

## Objectives
- Improve security and clarity by segmenting the home network using VLANs.
- Avoid reconfiguring ~30 existing IoT devices immediately.
- Enable guest casting/printing while maintaining isolation.
- Prepare for a future router upgrade (MikroTik RB5009UPr+S+IN) with minimal downtime.
- Centralize Wi‑Fi management and reduce ongoing admin overhead.
- Preserve human‑readable IP addressing to simplify troubleshooting.

---

## Key Decisions (with Rationale)

### Router
**Chosen (future):** MikroTik RB5009UPr+S+IN

**Why**
- RouterOS 7 with full VLAN, firewall, DHCP, and CAPsMAN support
- Built‑in PoE (8 ports, ~130 W) removes need for a separate PoE switch
- 1×2.5GbE + 1×10Gb SFP+ for future expansion
- Simplifies physical topology and reduces failure points

---

### Wi‑Fi Management
**Chosen:** CAPsMAN (centralized AP management via RouterOS)

**Why**
- Multiple APs now, more later → manual config doesn’t scale
- Single place to manage SSIDs, VLAN mapping, security, channels
- Seamless integration with MikroTik APs (cAP ac now, cAP ax later)

---

### SSID Strategy
**Do NOT rename existing IoT SSID yet.**

Final SSID plan:

| SSID | Band(s) | VLAN | Purpose |
|------|---------|------|---------|
| COLLECTIVE | 2.4 + 5 GHz | 20 (Trusted) | User devices |
| COLLECTIVE‑2G | 2.4 GHz only | 40 (IoT) | Legacy IoT (unchanged) |
| COLLECTIVE‑IOT | 2.4 + 5 GHz | 40 (IoT) | New IoT devices |
| COLLECTIVE‑GUEST | 2.4 + 5 GHz | 50 (Guest) | Guest access |

**Why**
- Zero disruption to existing IoT
- Clean migration path over time
- Avoids mass re‑pairing effort

---

### VLAN Architecture
VLAN IDs aligned to IP subnets for readability and reduced errors.

| VLAN | Purpose | Subnet |
|------|---------|--------|
| 10 | Infra (router, switches, AP mgmt) | 10.0.10.0/24 |
| 20 | Trusted Clients | 10.0.20.0/24 |
| 30 | Shared Services | 10.0.30.0/24 |
| 40 | IoT Devices | 10.0.40.0/24 |
| 50 | Guest | 10.0.50.0/24 |

Notes:
- No quarantine VLAN implemented now (number reserved only)
- /24 everywhere for simplicity and easy expansion

---

### Device Placement

| Device | VLAN | Reason |
|------|------|--------|
| NAS | Trusted (20) | Sensitive data |
| Home Assistant (Raspberry Pi) | Shared (30) | Needs to talk to Trusted + IoT |
| Printers / Scanners | Shared (30) | Used by Trusted + Guests |
| Smart TVs / Chromecasts | Shared (30) | Casting targets |
| Cameras, plugs, bulbs | IoT (40) | Untrusted but required |
| Torrent / Sonarr box | IoT (40) | Reduced blast radius |

---

### Guest Casting & Printing
- Guests remain in Guest VLAN (50)
- TVs and printers remain in Shared VLAN (30)
- Enabled via narrow exceptions:
  - mDNS reflection between VLAN 50 ↔ VLAN 30
  - Firewall allows Guest → specific TV/printer IPs only
- All other Guest → LAN traffic remains blocked

---

### Firewall Model (High‑Level)
- Trusted → anywhere: allowed
- Shared → IoT: allowed (for HA)
- IoT → Trusted/Shared: blocked
- Guest → LAN: blocked
- Guest → specific TVs/printers: allowed
- All VLANs → Internet: allowed
- Stateful firewall (return traffic allowed)

---

### Physical Topology (Future State)

ONT  
└── RB5009UPr+S+IN  
  ├── PoE ports → APs (VLAN trunks)  
  ├── PoE ports → Cameras (IoT VLAN)  
  ├── Ethernet → NAS (Trusted)  
  ├── Ethernet → Home Assistant (Shared)  
  └── Ethernet → Non‑PoE switch (Trusted fan‑out)

---

### Switching
**Recommended non‑PoE VLAN switch:** TP‑Link TL‑SG116E (16‑port Easy Smart)

**Why**
- Inexpensive, reliable, VLAN‑aware
- Router handles all L3 logic

---

### Cabling
- Existing Cat5e acceptable for 1GbE and likely 2.5GbE
- New runs: Cat6 UTP solid copper
- Same RJ45 crimper usable with Cat6‑rated connectors

---

### Migration Strategy
- Wait for RB5009 and do a single cutover
- Build full config offline:
  - VLANs
  - DHCP
  - Firewall
  - CAPsMAN
- Expected downtime: ~5–10 minutes
- No need to pre‑stage on current hEX router

---

### CAPsMAN Configuration Highlights
- VLAN‑tagged datapaths per SSID
- WPA2/WPA3 for Trusted; WPA2 for IoT
- Legacy COLLECTIVE‑2G preserved (2.4 GHz only)
- Central provisioning of all APs
- Central channel planning

---

### Notes for Importing into Another AI Tool
- Treat this document as authoritative
- Append future changes instead of rewriting
- Ask the tool for validation, diagrams, or config review
