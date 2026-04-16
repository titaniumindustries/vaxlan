# Hardware & Software Inventory

Last updated: 2026-04-05

## Router

| Property | Value |
|----------|-------|
| Model | MikroTik RB5009UPr+S+IN |
| RouterOS Version | **7.19.6 (stable)** |
| Architecture | arm64 |
| CPU | ARM64 (4 cores @ 1400MHz) |
| RAM | 1024 MB |
| Storage | 1024 MB |
| Ports | ether1 (2.5G), ether2-8 (1G), sfp-sfpplus1 (10G SFP+) |
| PoE-out | All 8 ethernet ports (802.3af/at, ~130W total) |
| Management IP | 10.0.20.1 (VLAN 20) |
| SSH | Enabled on port 22 |
| WebFig | http://10.0.20.1 |
| Extra Packages | `wireless` (for legacy CAPsMAN with cAP ac APs) |

### RouterOS 7 Notes

- CAPsMAN uses `/caps-man` path (requires `wireless` package for cAP ac compatibility)
- The new `/interface/wifi` system does NOT support cAP ac (legacy wireless driver)
- mDNS reflection: `/ip dns set mdns-repeat-ifaces=...` (enabled on Trusted, Shared, IoT, Guest)

### Previous Router (kept for rollback reference)

| Property | Value |
|----------|-------|
| Model | MikroTik hEX S (RB760iGS) |
| RouterOS | 6.49.19 (long-term) |
| Architecture | mmips |
| Status | Powered off, config intact for emergency rollback |

## Access Points

| Location | Model | MAC (Ethernet/Base) | Radio MACs (2.4/5) | Management IP |
|----------|-------|---------------------|---------------------|---------------|
| Upstairs Office | MikroTik cAP ac | 74:4D:28:5F:80:1E | 74:4D:28:5F:80:20 / 74:4D:28:5F:80:21 | 10.0.10.11 (static DHCP) |
| Downstairs Den | MikroTik cAP ac | 74:4D:28:D4:7E:3F | 74:4D:28:D4:7E:41 / 74:4D:28:D4:7E:42 | 10.0.10.12 (static DHCP) |
| Master Bedroom | MikroTik cAP ac | 18:FD:74:5C:C6:8A | 18:FD:74:5C:C6:8C / 18:FD:74:5C:C6:8D | 10.0.10.13 (static DHCP) |

### AP Specifications

| Property | Value |
|----------|-------|
| Model | cAP ac (RBcAPGi-5acD2nD) |
| Wireless | 802.11a/b/g/n/ac |
| 2.4 GHz | 2x2 MIMO, max 300 Mbps |
| 5 GHz | 2x2 MIMO, max 867 Mbps |
| PoE | 802.3af/at (passive 18-57V) |
| Max SSIDs | 4 per radio (8 total) |
| Management | CAPsMAN (centralized) |

## Switches

### Netgear GS305EP (PoE+ Switch) — CCTV

| Property | Value |
|----------|-------|
| Model | Netgear GS305EP |
| Ports | 5× Gigabit (4 PoE+, 63W total) |
| Management IP | 10.0.10.20 (DHCP reservation on VLAN 10) |
| Router Port | ether3 (PVID=70, VLAN 70 untagged) |
| VLAN | 70 (CCTV) — 10.0.70.0/24 |
| Status | **Connected to ether3** — no cameras yet |
| 802.1Q Config | Not needed — single VLAN, ether3 PVID=70 handles tagging. Leave switch in default mode. |
| Purpose | Reolink PoE cameras (wired only). Internet blocked, NAS-only recording, web UI from Trusted. |

### Netgear GS108 (Unmanaged Switch)

| Property | Value |
|----------|-------|
| Location | Office |
| Model | Netgear GS108 |
| Ports | 8× Gigabit |
| PoE | No |
| VLAN Support | No (unmanaged) |
| Purpose | VLAN 30 (Shared) services - NAS, Home Assistant, Brother printer, Ooma VoIP |

## Key Network Addresses

| Device | IP Address | VLAN | Notes |
|--------|------------|------|-------|
| Router | 10.0.20.1 | 20 | Primary management |
| NAS (Synology) | 10.0.30.10 | 30 | Static |
| Home Assistant | 10.0.30.11 | 30 | Static |
| Brother HL-L2360DW Printer | 10.0.30.12 | 30 | Wired MAC: 30:05:5C:60:A0:F6, WiFi MAC: 38:B1:DB:BE:FF:5D. On GS108. mDNS discoverable. **WiFi must be disabled — enables wired.** |
| Brother ADS-1500W Scanner | 10.0.40.88 | 40 | WiFi MAC: A8:A7:95:B6:69:76. On COLLECTIVE-IOT. Separate device from printer. |
| LG ThinQ Clothes Dryer | 10.0.40.99 | 40 | COLLECTIVE-IOT. MAC: 74:40:BE:37:B0:3E. |
| LG ThinQ Clothes Washer | (dynamic / verify current lease) | 40 | COLLECTIVE-IOT. MAC: 00:51:ED:79:DA:50. |
| Ooma VoIP | 10.0.30.104 | 30 | Static |

## Backup Locations

| Type | Location | Notes |
|------|----------|-------|
| Router flash | `/` on router | Binary (.backup) and text (.rsc) exports |
| Local copy | `mikrotik/backups/` | Downloaded copies |
| Naming convention | `export-YYYYMMDD-HHMMSS.rsc` | Timestamp format |
