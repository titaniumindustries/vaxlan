# Firewall Rules Reference

**Last Updated:** 2026-03-20
**Router:** MikroTik RB5009UPr+S+IN — RouterOS 7.19.6

---

## Philosophy

Zero-trust model: all inter-VLAN traffic is **denied by default**. Access is explicitly granted. Rules are processed top-to-bottom — **first match wins**.

Key rule-writing principles:
- Allow rules for specific services **must appear BEFORE** blanket drop rules for the same source
- Use `src-address`/`dst-address` for inter-VLAN rules — prefer this over `in-interface`/`out-interface` for reliability on bridged VLANs
- DNS and DHCP must be permitted from every VLAN or those VLANs lose internet entirely

---

## INPUT Chain — Access to the Router

Protects SSH, WebFig, WinBox, DNS, and DHCP services on the router itself.

| # | Action | Source | Service | Reason |
|---|--------|--------|---------|--------|
| 1 | ✅ Allow | All | Established/related/untracked | Connection tracking |
| 2 | ❌ Drop | All | Invalid packets | Drop malformed traffic |
| 3 | ✅ Allow | Guest (10.0.50.0/24) | DNS UDP 53 | Required for internet |
| 4 | ✅ Allow | Guest (10.0.50.0/24) | DHCP UDP 67-68 | Required for IP assignment |
| 5 | ✅ Allow | Guest (10.0.50.0/24) | DNS TCP 53 | Required for internet |
| 6 | ✅ Allow | IoT (10.0.40.0/24) | DNS UDP 53 | Required for internet |
| 7 | ✅ Allow | IoT (10.0.40.0/24) | DHCP UDP 67-68 | Required for IP assignment |
| 8 | ✅ Allow | IoT (10.0.40.0/24) | mDNS UDP 5353 | Required for cross-VLAN mDNS reflection |
| 9 | ❌ Drop | IoT VLAN (in-interface) | Everything else | Block router management from IoT |
| 10 | ✅ Allow | Guest (10.0.50.0/24) | mDNS UDP 5353 | Required for cross-VLAN mDNS reflection |
| 11 | ❌ Drop | Guest VLAN (in-interface) | Everything else | Block router management from Guest |
| 12 | ✅ Allow | CCTV (10.0.70.0/24) | DNS UDP 53 | Required for DHCP/hostname resolution |
| 13 | ✅ Allow | CCTV (10.0.70.0/24) | DHCP UDP 67-68 | Required for IP assignment |
| 14 | ❌ Drop | CCTV VLAN (in-interface) | Everything else | Block router management from CCTV |
| 15 | ✅ Allow | All | ICMP | Diagnostics / ping |
| 16 | ✅ Allow | All | dst 127.0.0.1 | CAPsMAN loopback requirement |
| 17 | ✅ Allow | All (WAN) | TCP 32400 inbound | Plex external access |
| 18 | ❌ Drop | Non-LAN interfaces | All | Default WAN drop |

> **Critical ordering:** Rules 3–8 (DNS/DHCP allow) **must** precede rules 9 and 11 (IoT/Guest management drops). Without this order, IoT and Guest devices cannot resolve DNS or receive DHCP → no internet.

---

## FORWARD Chain — Inter-VLAN Routing

### Preamble (connection tracking)

| Action | Traffic | Reason |
|--------|---------|--------|
| ✅ Allow | IPsec policy (in/out) | VPN pass-through |
| ✅ Fasttrack | Established/related | Hardware-offloaded performance |
| ✅ Allow | Established/related/untracked | Connection tracking |
| ❌ Drop | Invalid packets | Drop malformed traffic |

---

### Infrastructure (VLAN 10)

| Action | Source → Destination | Notes |
|--------|----------------------|-------|
| ✅ Allow | Trusted (20) → Infra (10) | Full access — manage switches, APs |
| ❌ Drop | IoT (40) → Infra (10.0.10.0/24) | No IoT access to network equipment |
| ❌ Drop | Guest (50) → Infra (10.0.10.0/24) | No guest access to network equipment |

---

### Trusted (VLAN 20) — Full LAN access

| Action | Source → Destination | Service | Notes |
|--------|----------------------|---------|-------|
| ✅ Allow | Trusted → Shared (30) | All | NAS, Home Assistant, printers, VoIP |
| ✅ Allow | Trusted → IoT (40) | All | Device management, troubleshooting |
| ✅ Allow | Trusted → CCTV (70) | TCP 80, 443 | Camera web UI only |
| ✅ Allow | Trusted → IoT (40) | UDP 56700 (dst) | LIFX smart bulb control |

---

### Shared (VLAN 30) — Outbound to IoT only

| Action | Source → Destination | Service | Notes |
|--------|----------------------|---------|-------|
| ✅ Allow | Shared → IoT (40) | All | Home Assistant controls IoT devices |
| ✅ Allow | Shared → IoT (40) | UDP 56700 (dst) | LIFX control from Home Assistant |
| ✅ Allow | IoT (40) → Shared (30) | UDP src 56700 | LIFX response to Trusted/HA (return path) |
| ✅ Allow | HA (10.0.30.11) → ESPHome (10.0.40.10) | TCP 6053 | Energy monitor polling |

---

### IoT (VLAN 40) — Restricted; internet + explicit exceptions only

| Action | Source → Destination | Service | Notes |
|--------|----------------------|---------|-------|
| ✅ Allow | IoT (40) → Trusted (20) | UDP src 56700 | LIFX response (return path) |
| ✅ Allow | IoT (40) → Shared (30) | UDP src 56700 | LIFX response to HA (return path) |
| ✅ Allow | ESPHome (10.0.40.10) → HA (10.0.30.11) | TCP 6053, 8123 | ESPHome → Home Assistant API |
| ❌ Drop | IoT → Trusted (in-interface) | All | Block pivot to personal devices |
| ✅ Allow | **SHOWFINDER (10.0.40.50) → NAS (10.0.30.10)** | **TCP 445** | **SMB file transfer — torrent laptop** |
| ✅ Allow | **Chromecast Audio (10.0.40.41) → NAS (10.0.30.10)** | **TCP 32400** | **Plex streaming — Chromecast pulls media from Plex server** |
| ✅ Allow | **Den Chromecast (10.0.40.42) → NAS (10.0.30.10)** | **TCP 32400** | **Plex streaming — Chromecast pulls media from Plex server** |
| ✅ Allow | **Den TV (10.0.40.60) → NAS (10.0.30.10)** | **TCP 32400** | **Plex streaming — TV pulls media from Plex server** |
| ✅ Allow | **Master Bedroom TV (10.0.40.61) → NAS (10.0.30.10)** | **TCP 32400** | **Plex streaming — TV pulls media from Plex server** |
| ✅ Allow | **IoT (10.0.40.0/24) → HA (10.0.30.11)** | **TCP 1883** | **MQTT — Tasmota and other IoT devices connect to Mosquitto broker** |
| ❌ Drop | IoT → Shared (in-interface) | All | Block remaining IoT → Shared access |

> IoT→Shared exceptions are placed **between** the IoT→Trusted drop and the IoT→Shared drop. Device-specific rules (SHOWFINDER, TVs) are scoped to one source IP, one destination IP, and one port. The MQTT rule uses subnet-wide source (10.0.40.0/24) since MQTT is a core HA service any IoT device may need — destination is still tightly scoped to one IP and one port. **All device-specific firewall rules MUST reference static DHCP reservations** — never use dynamic IPs.

---

### Guest (VLAN 50) — Internet + casting only

| Action | Source → Destination | Service | Notes |
|--------|----------------------|---------|-------|
| ✅ Allow | Guest → Internet | All | Internet access |
| ❌ Drop | Guest | TCP/UDP 6881-6999, 51413 | Block bittorrent |
| ❌ Drop | Guest → Trusted (in-interface) | All | No access to personal devices |
| ❌ Drop | Guest → IoT (in-interface) | All | No IoT control from guest |
| ✅ Allow | Guest → `shared-devices` list | All | Casting and printing (see address list below) |
| ❌ Drop | Guest → LAN (out-interface-list=LAN) | All | Block remaining LAN access |

---

### CCTV (VLAN 70) — NAS recording only; no internet

| Action | Source → Destination | Service | Notes |
|--------|----------------------|---------|-------|
| ✅ Allow | CCTV → NAS (10.0.30.10) | TCP 554, 9000 | RTSP stream + Reolink recording protocol |
| ❌ Drop | CCTV → Any LAN (10.0.0.0/16) | All | No lateral movement |
| ❌ Drop | CCTV → Internet (out-interface-list=WAN) | All | No phoning home |

> Cameras not yet connected. Config is live and ready.

---

### Default

| Action | Traffic | Notes |
|--------|---------|-------|
| ✅ Allow | LAN → WAN | Internet for all VLANs (CCTV excluded above) |
| ❌ Drop | WAN → LAN (new, non-DSTNATed) | Default inbound block |

---

## NAT Rules

| Rule | Chain | Match | Action |
|------|-------|-------|--------|
| Masquerade | srcnat | All outbound via WAN | Replace source IP with WAN IP |
| Plex forward | dstnat | Inbound TCP 32400 | Forward → NAS 10.0.30.10:32400 |

---

## Address Lists

| List | Members | Used By |
|------|---------|---------|
| `shared-devices` | 10.0.30.0/24 (Shared VLAN) | Guest → casting/printing allow rule |

---

## Known Quirks

1. **DNS/DHCP INPUT ordering is critical** — IoT/Guest management drops are broad; DNS/DHCP allows must come first or those VLANs lose internet.
2. **LIFX requires bidirectional UDP 56700** — both the outbound control rule AND the inbound response rule are needed. Without the response rule, bulbs appear offline despite control packets being sent.
3. **`in-interface`/`out-interface` on bridge** — Some rules (particularly IoT/Guest block rules and the Shared→IoT HA rule) use interface matchers. These work in practice with the current VLAN interface setup. For new rules, prefer `src-address`/`dst-address` for reliability.
4. **IoT→Shared exceptions (SHOWFINDER, Den TV, Master Bedroom TV, MQTT)** — IoT devices with explicit Shared VLAN access. Placed before the broad IoT→Shared drop. Device-specific rules scoped to a single source IP, destination IP, and port (each device MUST have a static DHCP reservation). The MQTT rule is subnet-wide since it's a core HA service.
5. **Device-specific firewall rules require static IPs** — Never create a firewall rule referencing a dynamic IP. Always create a static DHCP reservation first, then create the firewall rule pointing to that static IP. When changing a static IP, update all firewall rules and address lists referencing the old IP.

---

## Change Log

| Date | Change | Reason |
|------|--------|--------|
|| 2026-03-24 | Removed Chromecast devices: deleted firewall rules (.41 and .42 → NAS Plex), address-list entry (.41), static leases (.40, .41, .42). Added Guest Bedroom 43in Roku TV (.62). | Chromecasts physically removed. Third TCL Roku TV identified. |
|| 2026-03-20 | Added IoT (10.0.40.0/24) → HA (10.0.30.11) TCP 1883 | MQTT — Tasmota outlets and future IoT devices need to reach Mosquitto broker on Home Assistant |
| 2026-03-20 | Added Den Chromecast (10.0.40.42) → NAS (10.0.30.10) TCP 32400 | Plex streaming — Den Chromecast needs direct NAS access |
| 2026-03-16 | Added Den TV (10.0.40.60) and Master Bedroom TV (10.0.40.61) → NAS (10.0.30.10) TCP 32400 | Plex streaming — TVs were using Plex relay (no direct NAS access). Static reservations created first. |
| 2026-03-16 | Fixed stale Chromecast Audio IP in docs (.185 → .41) and address list description | Docs out of sync with router after 2026-03-14 IP consolidation |
| 2026-03-12 | Added Chromecast Audio (10.0.40.41) → NAS (10.0.30.10) TCP 32400 | Plex casting — Chromecast needs to pull media from Plex server |
| 2026-03-11 | Added SHOWFINDER (10.0.40.50) → NAS (10.0.30.10) TCP 445; removed broad IoT → Shared SMB rule | Torrent laptop NAS access, scoped tightly |
| 2026-03-11 | Added CCTV VLAN 70 firewall rules | New isolated CCTV VLAN |
| 2026-03-11 | Added mDNS UDP 5353 allow rules for IoT/Guest before management drop rules | Required for cross-VLAN mDNS reflection |
| 2026-02-20 | Added LIFX bidirectional UDP 56700 rules | Smart bulb control from Trusted/HA |
| 2026-02-20 | Added DNS/DHCP INPUT allow rules for IoT before management drop | Fixed IoT internet access |
| 2026-02-16 | Initial VLAN segmentation firewall rules | Network security implementation |
