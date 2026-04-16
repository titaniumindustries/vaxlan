# RB5009 Migration Plan — hEX S Rip-and-Replace

**Created:** 2026-03-10
**Purpose:** AI context document for configuring and migrating to MikroTik RB5009UPr+S+IN
**Excludes:** All passwords (stored separately in router configs)

---

## Current State — hEX S (RB760iGS)

### Router Info
- Model: MikroTik hEX S (RB760iGS)
- RouterOS: 6.49.19 (long-term)
- Bridge MAC: C4:AD:34:17:3A:55
- Bridge VLAN filtering: enabled
- System identity: "MikroTik hEX S"
- Timezone: America/Denver
- Serial: AE370B7E823F

### Current Port Assignments (hEX S) — RECORD FOR ROLLBACK

| hEX S Port | Connected To | Bridge PVID | VLAN Config | Notes |
|------------|-------------|-------------|-------------|-------|
| ether1 | ISP (WAN) | N/A | Not on bridge | DHCP client, WAN interface list |
| ether2 | GS108 unmanaged switch | 30 | VLAN 30 untagged; VLANs 10,20,40,50,60 tagged | Also has legacy 10.0.0.1/16 address |
| ether3 | GS305EP PoE switch (port 1) | 10 | VLAN 10 untagged; VLANs 20,30,40,50,60 tagged | Trunk to AP switch |
| ether4 | Brother Printer | 20 | PVID=20 (Trusted), but NOT in VLAN 20 untagged list — works due to ingress-filtering=no | Temporary — should move to Shared (VLAN 30) after mDNS on ROS7 |
| ether5 | Nothing (break-glass) | 20 | VLAN 20 untagged (properly configured) | Emergency trusted LAN access |
| sfp1 | Nothing | 1 (default) | On bridge | Unused |

### GS305EP PoE Switch Port Assignments — RECORD FOR ROLLBACK

| GS305EP Port | Connected To | PoE | Notes |
|-------------|-------------|-----|-------|
| 1 | hEX S ether3 (uplink) | No | Trunk - all VLANs |
| 2 | AP Upstairs Office | Yes | cAP ac, MAC 74:4D:28:5F:80:1E |
| 3 | AP Downstairs Den | Yes | cAP ac, MAC 74:4D:28:D4:7E:3F |
| 4 | Available | Yes | Reserved for AP Master Bedroom |
| 5 | Unused | Yes | — |

### GS108 Unmanaged Switch (connected to hEX S ether2)
- NAS (Synology DS224+) — 10.0.30.10 (MAC 90:09:D0:63:C3:5A)
- Home Assistant (RPi) — 10.0.30.11 (MAC DC:A6:32:AA:FE:ED)
- Ooma VoIP — legacy 10.0.0.103 (MAC 00:18:61:5E:EB:E1) — needs static lease on new router

### Brother Printer (connected to hEX S ether4, NOT GS108)
- MAC: 30:05:5C:60:A0:F6
- Currently on Trusted VLAN (PVID=20) as workaround for mDNS not crossing VLANs on ROS6
- After RB5009 migration: move to Shared VLAN (VLAN 30) via GS108, enable mDNS reflection for Bonjour

### IP Addressing
- 10.0.0.1/16 on ether2 (legacy — DO NOT migrate)
- 10.0.10.1/24 on vlan10-infra
- 10.0.20.1/24 on vlan20-trusted
- 10.0.30.1/24 on vlan30-shared
- 10.0.40.1/24 on vlan40-iot
- 10.0.50.1/24 on vlan50-guest
- 10.0.60.1/24 on vlan60-vpn

### DNS
- Upstream servers: 1.1.1.1, 1.0.0.1
- allow-remote-requests=yes
- Static entries: synology→10.0.30.10, homeassistant→10.0.30.11, ESPEnergyMonitor1→10.0.40.10

### CAPsMAN
- 4 SSIDs: COLLECTIVE (VLAN 20), COLLECTIVE-2G (VLAN 40), COLLECTIVE-IOT (VLAN 40), COLLECTIVE-GUEST (VLAN 50)
- Plus COLLECTIVE-VPN-CA (VLAN 60, placeholder)
- Per-AP 2.4GHz channel assignments: Upstairs=Ch11, Downstairs=Ch1
- 5GHz: channel 5745 (149), Ceee (80MHz)
- IoT datapath has client-to-client-forwarding=yes (for Chromecast)
- Band-specific provisioning rules with radio-mac matching

### Firewall (evolved from initial setup)
Key rules beyond defaults:
- DNS/DHCP INPUT allowed from IoT and Guest BEFORE management block
- LIFX UDP 56700 bidirectional (Trusted/Shared ↔ IoT)
- ESPHome ↔ Home Assistant (TCP 6053, 8123)
- IoT → NAS (TCP 445,139,2049,548)
- Guest → shared-devices address list
- Guest bittorrent blocking
- Plex DSTNAT to 10.0.30.10:32400


---

## Target State — RB5009UPr+S+IN

### Hardware
- Model: MikroTik RB5009UPr+S+IN
- RouterOS: 7.x (ships with 7.x, update to latest stable)
- Ports: ether1-ether7 (1G), ether8 (2.5G), sfp-sfpplus1 (10G SFP+)
- All 8 ethernet ports support PoE-out (802.3af/at, ~130W total)
- APs connect directly to RB5009 PoE ports (GS305EP no longer needed for APs)

### Planned Port Assignments (RB5009)

| RB5009 Port | Connected To | Bridge | PVID | VLAN Config | Notes |
|-------------|-------------|--------|------|-------------|-------|
| ether1 | Break-glass / reserved | Yes | 20 | VLAN 20 untagged | **2.5G.** Emergency access + Mac during setup. First port = easy to remember. Reserved for future 2.5G device |
| ether2 | Brother Printer (temporary) | Yes | 20 | VLAN 20 untagged | 1G. Stays on Trusted until mDNS verified, then move to GS108 (VLAN 30) |
| ether3 | Available | — | — | — | 1G. Future use |
| ether4 | AP Master Bedroom (future) | Yes | 10 | VLAN 10 untagged; 20,40,50 tagged | 1G. Direct PoE, ready when needed |
| ether5 | AP Downstairs Den | Yes | 10 | VLAN 10 untagged; 20,40,50 tagged | 1G. Direct PoE from RB5009 |
| ether6 | AP Upstairs Office | Yes | 10 | VLAN 10 untagged; 20,40,50 tagged | 1G. Direct PoE from RB5009 |
| ether7 | GS108 switch (Shared) | Yes | 30 | VLAN 30 untagged | 1G. NAS, HA, Ooma (and printer after mDNS setup) |
| ether8 | ISP (WAN) | No | N/A | DHCP client | 1G. WAN interface list |
| sfp-sfpplus1 | Available (10G) | — | — | — | Future use |

### Key Differences from hEX S
1. **No legacy 10.0.0.1/16 address** — clean start, all traffic properly VLANed
2. **No defconf DHCP server** — only per-VLAN DHCP servers
3. **APs direct to router** — eliminates GS305EP from AP path
4. **RouterOS 7** — new CAPsMAN syntax needs `wireless` package for cAP ac compatibility
5. **mDNS reflection** — native support via `/ip dns set mdns=yes`
6. **PoE built-in** — RB5009 powers APs directly

### RouterOS 7 Migration Notes
- CAPsMAN: still uses `/caps-man` path WITH the `wireless` package installed
- The new `/interface/wifi` system does NOT support cAP ac (legacy wireless driver)
- Must download and install `wireless-7.x-mmips.npk` on the RB5009
- Bridge VLAN syntax is the same
- Firewall filter syntax is the same
- DHCP syntax is the same

---

## DHCP Static Leases to Migrate

### Infrastructure (VLAN 10, dhcp-infra)
- 10.0.10.11 — AP Upstairs Office (74:4D:28:5F:80:1E)
- 10.0.10.12 — AP Downstairs Den (74:4D:28:D4:7E:3F)
- 10.0.10.13 — AP Master Bedroom reserved (18:FD:74:5C:C6:8A)
- 10.0.10.20 — Switch GS305EP (94:18:65:6E:46:C8)

### Shared (VLAN 30, dhcp-shared)
- 10.0.30.10 — NAS Synology DS224+ (90:09:D0:63:C3:5A)
- 10.0.30.11 — Home Assistant RPi (DC:A6:32:AA:FE:ED)
- 10.0.30.104 — Ooma VoIP (00:18:61:5E:EB:E1) — NEW static lease needed

### IoT (VLAN 40, dhcp-iot)
All existing static leases from backup-pre-lifx-monitor-20260222.rsc (30+ devices)
Including: Kasa plugs/switches, LIFX bulbs, Tasmota devices, Alexa echos, Chromecasts, ESPHome energy monitor, Nest cameras, WLED controller

### Chromecast Audio
- 10.0.40.185 — Chromecast Audio Kitchen (MAC A4:77:33:F8:98:6E, in shared-devices address list)

### Config Items NOT Being Migrated
- Legacy 10.0.0.1/16 address on ether2 (defconf) — replaced by proper VLAN addressing
- defconf DHCP server (10.0.255.x pool) — no longer needed
- LIFX CAPsMAN monitoring script/scheduler — temporary diagnostic, not needed on new router
- Two anomalous DHCP leases with 10.0.30.x addresses on dhcp-iot server (E4:F0:42:82:F4:A2, F4:F5:D8:75:87:F8) — investigate after migration
- Old NAS address list entry (10.0.0.102 in nas-servers list) — NAS is now at 10.0.30.10


---

## Pre-Migration Preparation (User Steps)

### Step 1: Verify You Have Everything
- [ ] RB5009UPr+S+IN router (unboxed)
- [ ] Power cable for RB5009
- [ ] Ethernet cable to connect Mac to RB5009 (any spare cable)
- [ ] Note which RouterOS version is printed on the box or check after boot

### Step 2: Take a Fresh Backup of the hEX S
Before touching anything, create a current backup:
```
# SSH to current router and create backup + export
# Then download both files to mikrotik/backups/
```

### Step 3: Power On the RB5009 (Separate from Existing Network)
- Plug in power to RB5009 — do NOT connect any network cables yet
- Wait 60 seconds for it to boot
- Connect an ethernet cable from your Mac to RB5009 **ether1** (this will become the break-glass port, first port, 2.5G)
- Your Mac gets internet from existing WiFi (hEX S still running)
- Your Mac talks to RB5009 via the wired ethernet connection

### Step 4: Verify Mac Can Reach RB5009
- RB5009 default IP: 192.168.88.1
- Open browser: http://192.168.88.1 — should see WebFig
- Or: `ping 192.168.88.1` from terminal
- If Mac's ethernet doesn't get an IP, manually set it to 192.168.88.2/24

### Step 5: Tell Oz to Push the Configuration
At this point, say "RB5009 is powered on and reachable at 192.168.88.1 on my ethernet interface" and I will:
1. SSH into the RB5009 at 192.168.88.1 (default user: admin, no password)
2. Check the RouterOS version
3. Push the full configuration (VLANs, DHCP, CAPsMAN, firewall, NAT, DNS, static leases)
4. Verify the config is applied
5. **NOT enable VLAN filtering yet** (so we don't lose access)

### Step 6: Download and Install Wireless Package (if needed)
- I'll check if the `wireless` package is already present
- If not, I'll download it from MikroTik and install it
- Router will need one reboot for the package

### Step 7: Final Pre-Cutover Verification
- I'll verify all config sections are correct
- Enable VLAN filtering
- Verify Mac still has access via ether1 (break-glass, VLAN 20)
- At this point: RB5009 is fully configured but has no WAN or devices

---

## Migration Phases

### Phase 1: Core Cable Swap (Move Direct Router Cables)
**Estimated time: 2-3 minutes**
**During this phase: internet is down, WiFi stays up (APs still powered by GS305EP)**

#### Cable Moves:
1. **Unplug WAN cable** from hEX S ether1 → **plug into RB5009 ether8**
2. **Unplug GS108 cable** from hEX S ether2 → **plug into RB5009 ether7**
3. **Unplug printer cable** from hEX S ether4 → **plug into RB5009 ether2** (stays on Trusted VLAN 20 for now)
4. Leave hEX S powered on (for rollback)
5. Leave GS305EP connected to hEX S ether3 for now (APs still get PoE)

#### Verify Phase 1:
- [ ] Mac (on RB5009 ether1) can ping 8.8.8.8 (internet via new router)
- [ ] Mac can ping 10.0.30.10 (NAS reachable on VLAN 30 via GS108)
- [ ] `nslookup google.com` works (DNS)
- [ ] Mac can SSH to RB5009 at 10.0.20.1

#### Phase 1 Rollback:
Move all three cables back to hEX S (WAN→ether1, GS108→ether2, printer→ether4). Everything returns to previous state immediately.

---

### Phase 2: AP Migration (Move APs from GS305EP to RB5009 Direct)
**Estimated time: 5-10 minutes**
**During this phase: WiFi goes down briefly as APs reboot on new PoE source**

#### Cable Moves:
1. **Unplug AP Upstairs cable** from GS305EP port 2 → **plug into RB5009 ether6**
2. **Unplug AP Downstairs cable** from GS305EP port 3 → **plug into RB5009 ether5**
3. Wait 60-90 seconds for APs to boot (PoE now from RB5009)
4. APs should auto-discover CAPsMAN on the new router

#### Verify Phase 2:
- [ ] `/caps-man remote-cap print` shows both APs connected
- [ ] `/caps-man interface print` shows all SSIDs running
- [ ] Phone can see and connect to COLLECTIVE SSID
- [ ] Phone gets IP in 10.0.20.x range
- [ ] Phone has internet
- [ ] IoT devices start reconnecting (check DHCP leases filling in over next few minutes)

#### Phase 2 Rollback:
Move AP cables back to GS305EP ports 2 and 3. APs reconnect to hEX S CAPsMAN.
Also move WAN and GS108 cables back to hEX S (full rollback to Phase 0).

---

### Phase 3: Full Validation
**Estimated time: 10-15 minutes**

#### Test from Trusted VLAN (COLLECTIVE WiFi or ether6):
- [ ] `ping 8.8.8.8` — internet
- [ ] `ping 10.0.30.10` — NAS access
- [ ] `nslookup google.com` — DNS
- [ ] SSH to router at 10.0.20.1

#### Test from IoT (check via router):
- [ ] `/ip dhcp-server lease print where server=dhcp-iot` — devices getting IPs
- [ ] IoT devices have internet (check firewall connections)
- [ ] IoT CANNOT reach 10.0.20.1 (management blocked)

#### Test specific services:
- [ ] LIFX bulbs controllable from Trusted VLAN
- [ ] Home Assistant reachable at 10.0.30.11
- [ ] Plex working (DSTNAT rule)
- [ ] Chromecast Audio discoverable

#### If all tests pass:
- Power off the hEX S
- Disconnect GS305EP from hEX S ether3 (no longer needed for APs)
- GS305EP can be stored for future camera VLAN use

---

### Phase 4: Post-Migration Cleanup
- [ ] Configure mDNS reflection: `/ip dns set mdns=yes`
- [ ] Update system identity: `/system identity set name="MikroTik RB5009"`
- [ ] Create full backup of new router config
- [ ] Update documentation (ARCHITECTURE.md, hardware-software-inventory.md)
- [ ] Monitor for 24-48 hours for any device issues
- [ ] Address Ooma VoIP — verify it gets 10.0.30.x IP from new DHCP

---

## Full Rollback Procedure

If anything goes seriously wrong at any phase:

1. **Unplug all cables from RB5009**
2. **Reconnect cables to hEX S in original positions:**
   - ISP → hEX S ether1
   - GS108 → hEX S ether2
   - GS305EP → hEX S ether3 (if APs were moved)
   - Brother Printer → hEX S ether4
3. **Reconnect APs to GS305EP** (if moved):
   - AP Upstairs → GS305EP port 2
   - AP Downstairs → GS305EP port 3
4. hEX S still has its full working config — network restores immediately
5. Total rollback time: 2-3 minutes

---

## Questions Before We Begin

1. **Do you physically have the RB5009 already?** (docs say "planned/future")
2. **Physical location:** Is the RB5009 going in the same spot as the hEX S (network closet)? Can the existing AP cables reach it?
3. **RouterOS version:** What version does the RB5009 ship with? (check box or we'll see after boot)
4. **ISP connection:** Confirmed ethernet handoff with DHCP? (config shows DHCP client on ether1)
5. **Must-stay-online devices:** Anything critical during the 5-10 min WiFi outage? (Ooma phone, security cameras, etc.)
6. **Maintenance window:** Best time? Evening/weekend recommended.
7. **Cable lengths:** The AP cables currently go to the GS305EP in the network closet — will they reach the RB5009 in its planned location?

