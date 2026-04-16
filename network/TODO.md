# Network TODO List

Last updated: 2026-04-01

## High Priority

### Security & Maintenance
- [ ] **Change router password** - Current password should be rotated
- [ ] **Refresh router and AP passwords** - Rotate passwords for RB5009 and all cAP ac APs, then update secure credential storage and recovery notes.
- [ ] **Define cross-device SSH key sharing strategy** - Decide and document how SSH keys are generated, distributed, and trusted across primary machines for router/AP management.
- [ ] **Remove plaintext/hard-coded passwords from scripts** - Eliminate inline credentials and `sshpass` usage in active scripts; standardize on SSH key auth for router/AP automation.
- [ ] **Create alerts when new devices connect to the network** - DHCP lease notifications

### Troubleshooting
- [ ] **Verify WiiM Mini cross-VLAN control from COLLECTIVE** - 2026-03-19. WiiM Mini (10.0.40.70) on COLLECTIVE-IOT (VLAN 40). Static DHCP reservation created. No new firewall rules — Trusted→IoT already open, mDNS reflection carries `_linkplay._tcp.local`. Move phone back to COLLECTIVE (VLAN 20) and confirm WiiM Home app discovers and controls the device. If app shows "On other networks" or fails discovery: (1) confirm VPN is off on phone, (2) verify WiiM has picked up static IP .70 (may need power cycle), (3) check `dns-sd -B _linkplay._tcp` from Mac on COLLECTIVE to confirm mDNS reflection. WiiM devices default to Google DNS 8.8.8.8 — if issues persist, check device DNS settings via app while on same VLAN.
- [ ] **Test YouTube casting to Roku TVs (retest needed)** - 2026-03-18. YouTube app on phone (Trusted VLAN 20) cannot discover Roku TVs on IoT VLAN (40). Initial hypothesis was SSDP-only discovery, but Plexamp on phone (same VLAN) sees all cast devices including Roku TVs via mDNS — confirming TCL TVs advertise `_googlecast._tcp` and mDNS reflection works. YouTube may use DIAL/SSDP instead of mDNS for discovery. **Needs retest with TVs powered on.** If YouTube still can't find them: **Workaround:** YouTube app "Link with TV code" (Settings → Watch on TV). **Proper fix if needed:** SSDP relay on Home Assistant.
- [ ] **Plexamp desktop (macOS) cannot cast to WiiM Mini** - 2026-03-30. Root cause identified: WiiM Mini does not support Google Cast (`_googlecast._tcp` not advertised). Plexamp desktop uses Google Cast for casting. **Workaround:** Use macOS AirPlay system output to route audio through the WiiM. **Permanent fix:** Upgrade to WiiM Amp or WiiM Pro (see Hardware Upgrades below).
- [ ] **Fix Master Bedroom TV (10.0.40.61) DHCP** - 2026-03-18. CAPsMAN shows TV connected to COLLECTIVE-IOT for 2+ days (MAC C4:8B:66:88:D6:D6) but DHCP lease status is "waiting / last-seen=never". TV has never obtained an IP from dhcp-iot. Likely has a static IP configured from its previous VLAN. Needs factory reset (see "Factory reset TCL TV" item below) to clear old network config.
- [ ] **Diagnose LIFX bulb WiFi disconnections**

## Medium Priority

### Cross-VLAN Device Control
- [ ] **Ensure Roku mobile app (Android) can discover and control Den and Guest Bedroom Roku TVs from Trusted and Guest VLANs** - Roku TVs are on IoT VLAN (40). Android phones on Trusted (VLAN 20) or Guest (VLAN 50) need to discover and operate these TVs via the Roku mobile app. Likely requires verifying/adding mDNS service advertisement (`_roku._tcp`), SSDP relay or DIAL discovery, and any necessary firewall rules to allow Roku ECP (External Control Protocol, TCP 8060) from Trusted/Guest → IoT. Related: existing YouTube casting to-do (also SSDP/DIAL dependent). Check VPN-off on test devices first.

### Infrastructure Upgrades
- [ ] **Update Master Bedroom AP (10.0.10.13) identity and firmware** - AP runs RouterOS 6.48.6. Check for latest 6.x firmware update. Verify system identity is set correctly (should match other APs' naming convention). MAC: 18:FD:74:5C:C6:8A, ether4.

### Hardware Upgrades
- [ ] **Upgrade Porch WiiM Mini to WiiM Amp** - 2026-03-30. The WiiM Mini does not support Google Cast — only AirPlay 2, Spotify Connect, TIDAL Connect, and LinkPlay. This prevents Plexamp (desktop and mobile) from casting to it. The WiiM Amp supports Google Cast + AirPlay 2 + all Connect protocols, and also eliminates the need for the separate Kasa smart plug (`switch.porch_speakers`) since it has a built-in amplifier. When upgrading: update static DHCP reservation (10.0.40.70), HA LinkPlay integration, and the porch speaker automation (can remove the Kasa plug power-on/off logic since the amp handles standby natively).

### Configuration & Best Practices
- [ ] **Check all configuration against best practices** - Review AP, firewall rules, VLANs, DHCP, static IP mapping, DNS settings for both general best practices and MikroTik-specific recommendations
- [ ] **Determine how to use static hostnames or implement static IPs on service devices** - Printer, NAS, Home Assistant, etc.
- [x] **Move Brother scanner to a low-conflict IoT static IP** - ✅ Done 2026-04-16. Moved from 10.0.40.88 to 10.0.40.35 (between Kasa and Chromecast ranges). Static IP docs updated. Scanner will pick up new IP on next DHCP renewal or power cycle.

### Network Segmentation
- [ ] **Factory reset TCL TV** - TV moved to IoT (COLLECTIVE-IOT) but remembers old WiFi passwords. Factory reset to prevent attacker from reconnecting to Trusted/Shared WLANs.
- [ ] **Configure CCTV VLAN 70 on router** - VLAN 70 (10.0.70.0/24) planned for Reolink cameras on ether3 (GS305EP). Needs: bridge VLAN entry, DHCP server, IP address 10.0.70.1/24, firewall rules (Trusted→CCTV web UI, CCTV→NAS recording, block CCTV→internet). See ARCHITECTURE.md for full design. GS305EP stays in default unmanaged mode — no 802.1Q needed since all ports are CCTV-only; ether3 PVID=70 handles VLAN assignment.

## Lower Priority / Future Enhancements

### New Network Features
- [ ] **Create child-friendly WiFi network (COLLECTIVE-KIDS)** - 5GHz-only SSID, new VLAN (TBD, likely 80). Two phases:
  - **Phase 1: VLAN + NextDNS + DNS enforcement** — New VLAN, DHCP, CAPsMAN 5GHz-only SSID, NextDNS as DNS (custom block lists: adult content + social media like Facebook, TikTok, Instagram, Snapchat), NAT rule to force all DNS through NextDNS (prevent bypass by changing device DNS). ~30 min.
  - **Phase 2: WireGuard VPN** — RouterOS 7 native WireGuard with ProtonVPN or Surfshark. Routing marks + mangle to force kid VLAN through tunnel. Kill switch firewall rule (drop if tunnel down). NextDNS queries routed through tunnel.
- [ ] **Configure WireGuard VPN on router** - RouterOS 7 native WireGuard. Shared between kid-friendly VLAN and future VLAN 60 (general VPN WiFi). Requires: VPN provider WireGuard credentials, key generation, WireGuard interface, routing marks, mangle rules, kill switch.

### Monitoring & Observability
- [ ] **Establish high-level network/infrastructure monitoring in Home Assistant** - Router stats, AP status, device counts, bandwidth usage

---

## Completed
- [x] **Document firewall rules** - 2026-03-11. Created `docs/firewall-rules.md` with plain-English INPUT/FORWARD/NAT reference.
- [x] **Configure SHOWFINDER NAS access** - 2026-03-11. Static IP 10.0.40.50 (MAC 3C:55:76:54:87:DD). Scoped SMB rule: IoT→NAS TCP 445, SHOWFINDER only. Replaced broad IoT→Shared file-sharing rule.
- [x] **Disable IoT client-to-client forwarding** - 2026-03-11. No longer needed; Chromecast casting works cross-VLAN via mDNS + L3 routing. Improves IoT security.
- [x] **Verify cross-VLAN Chromecast casting** - 2026-03-11. Working from Trusted VLAN via mDNS reflection.
- [x] **Verify ESPHome Builder mDNS** - 2026-03-11. Working after adding UDP 5353 firewall allow rules for IoT/Guest.
- [x] **Migrate to RB5009UPr+S+IN (RouterOS 7.19.6)** - 2026-03-11. Full rip-and-replace from hEX S. All VLANs, firewall, CAPsMAN, DHCP, DNS migrated. APs powered directly by router PoE.
- [x] **Enable mDNS reflection** - 2026-03-11. `mdns-repeat-ifaces` on Trusted, Shared, IoT, Guest VLANs.
- [x] **Get Brother printer working cross-VLAN** - 2026-03-11. Moved to GS108 (Shared VLAN 30), mDNS Bonjour discovery confirmed working from Trusted VLAN.
- [x] **Fix AP management access from VLAN 20** - 2026-03-11. Resolved by migration: APs now on VLAN 10 (10.0.10.11/12), no legacy 10.0.0.0/16 overlap.
- [x] **Repurpose GS305EP** - 2026-03-11. APs moved to RB5009 direct PoE. GS305EP assigned to ether3 for CCTV VLAN 70.
- [x] **Determine surveillance camera VLAN** - 2026-03-11. Dedicated CCTV VLAN 70 (10.0.70.0/24). Reolink cameras isolated: no internet, NAS-only recording, web UI from Trusted.
- [x] **Upgrade to RouterOS 7** - 2026-03-11. RB5009 ships with RouterOS 7.19.6 (stable).
- [x] **Remove legacy 10.0.0.1/16 address** - 2026-03-11. Clean VLAN-only addressing on RB5009.
- [x] **Switch 5GHz from DFS channel 128 to non-DFS channel 36** - 2026-02-19
- [x] **Create band-specific CAPsMAN provisioning rules** - 2026-02-19
- [x] **Increase 5GHz channel width to 80MHz** - 2026-02-19

---

## Notes

### Dependencies
- Child-friendly network → NextDNS account + WireGuard VPN + new SSID/VLAN + CAPsMAN config
- VPN network → WireGuard setup on router (shared with kid-friendly network)
- CCTV VLAN → Camera hardware (router config already pushed, GS305EP in default mode)

### Hardware Reference
- Router: MikroTik RB5009UPr+S+IN (RouterOS 7.19.6, arm64)
- APs: 3× MikroTik cAP ac (managed via CAPsMAN, powered by router PoE)
- Switches: Netgear GS108 (unmanaged, Shared VLAN 30), Netgear GS305EP (ether3, CCTV VLAN 70)
- Previous: hEX S (powered off, config intact for emergency rollback)

---

### Troubleshooting Notes: VPN Interference (IMPORTANT)

**Always check for active VPN before troubleshooting local network device discovery.** A VPN on the client machine can break mDNS/SSDP discovery and local routing, causing devices to appear unreachable even when the network config is correct. Confirm VPN is disconnected first.

### Troubleshooting Notes: AP Management Access (RESOLVED 2026-03-11)

**Resolved by RB5009 migration.** Legacy 10.0.0.0/16 address no longer exists. APs are on VLAN 10 at 10.0.10.11/12, directly reachable from Trusted VLAN (10.0.20.0/24) via firewall rule allowing Trusted → Infrastructure.
