# Network Implementation Plan - Incremental Approach

**Date:** 2026-02-15  
**Router:** MikroTik hEX S (RB760iGS)  
**RouterOS:** 6.49.19 (long-term)  
**Current Network:** Flat 10.0.0.0/16  
**Target:** VLAN segmentation + CAPsMAN + Firewall + VPN

---

## Objectives

1. **Security:** Segment network into VLANs (Trusted, IoT, Guest, Shared, VPN)
2. **Centralized WiFi:** Implement CAPsMAN for unified AP management
3. **Zero IoT disruption:** Existing devices continue working without reconfiguration
4. **Minimal downtime:** Incremental rollout with validation at each step
5. **Rollback capability:** Ability to revert at any phase

---

## Pre-Implementation Checklist

### ✓ Completed
- [x] Full router backup (binary + export)
- [x] DHCP leases exported
- [x] WiFi password confirmed: x2230dallas!!
- [x] Router admin access verified
- [x] Current network state documented

### ⏸ Pending (Can proceed without, but needed for complete implementation)
- [ ] **Surfshark WireGuard config** (for VPN tunnel - Phase 5)
  - Required: Private key, Server public key, Endpoint IP:port, VPN IP
  - Location: https://my.surfshark.com/vpn/manual-setup/router
  - **DECISION:** Proceed without VPN, add in Phase 5 later

- [ ] **cAP ac Access Points status**
  - Found devices at 10.0.0.2 and 10.0.0.3
  - Need: SSH access or confirmation they're set to auto-discover CAPsMAN
  - **DECISION:** Enable CAPsMAN and see if they auto-connect, or manually configure

### 🔍 Questions Before Starting
1. **Timing:** Is now a good time for 30-60 min of network disruption?
2. **Critical devices:** Any devices that MUST stay online (e.g., security cameras, medical equipment)?
3. **Remote access:** Are you physically present, or do you need to maintain remote access?
4. **AP access:** Can you physically access APs if they need reset/reconfiguration?

---

## Implementation Phases

### Phase 0: Final Preparation (5 min)
**Objective:** Ensure we can recover if something goes wrong

**Steps:**
1. Verify backup files exist locally
2. Create implementation log file
3. Document current IP of this Mac for emergency access
4. Open router web interface in browser (backup access method)

**Validation:**
- [ ] Can access router via SSH
- [ ] Can access router via web browser
- [ ] Backup files readable and not corrupted

**Rollback:** Restore from backup-20260215-014947.backup

---

### Phase 1: VLAN Infrastructure (10 min)
**Objective:** Create VLANs and DHCP servers WITHOUT disrupting existing network

**Steps:**
1. Create VLAN interfaces on bridge (10, 20, 30, 40, 50, 60)
2. Assign IP addresses to VLAN interfaces
3. Create DHCP servers for each VLAN (disabled initially)
4. Configure DHCP pools and options
5. **DO NOT enable bridge VLAN filtering yet**

**Validation:**
- [ ] All VLAN interfaces created and UP
- [ ] DHCP servers configured but disabled
- [ ] Existing network still works (ping 8.8.8.8)
- [ ] Can still access router from current IP

**Rollback:** Delete VLAN interfaces, delete DHCP servers

**Status:** ⏸ Not started  
**Issues:** None expected

---

### Phase 2: CAPsMAN Setup (10 min)
**Objective:** Enable centralized AP management and create SSIDs

**Steps:**
1. Enable CAPsMAN manager on router
2. Create security profiles for SSIDs
3. Create CAPsMAN configurations (channel plans, datapaths)
4. Create provisioning rules for APs
5. Configure 5 SSIDs with VLAN mappings:
   - COLLECTIVE → VLAN 20 (Trusted)
   - COLLECTIVE-2G → VLAN 40 (IoT, 2.4GHz only)
   - COLLECTIVE-IOT → VLAN 40 (IoT, dual-band)
   - COLLECTIVE-GUEST → VLAN 50 (Guest)
   - COLLECTIVE-VPN-CA → VLAN 60 (VPN) - placeholder for Phase 5
6. Wait for APs to connect and adopt configuration

**Validation:**
- [ ] CAPsMAN manager enabled and running
- [ ] APs appear in `/caps-man interface print`
- [ ] APs show as "running" status
- [ ] Can see SSIDs broadcasting (scan from phone)
- [ ] **DO NOT connect to new SSIDs yet**

**Rollback:** Disable CAPsMAN, APs revert to standalone mode

**Status:** ⏸ Not started  
**Issues to track:**
- If APs don't auto-connect, may need manual configuration or reset
- May need to set CAPsMAN address on APs if they're not discovering

---

### Phase 3: Test VLAN with Single Device (10 min)
**Objective:** Validate VLAN + DHCP + Internet works before full cutover

**Steps:**
1. Enable DHCP server for VLAN 20 (Trusted) only
2. Connect test device (phone) to COLLECTIVE SSID
3. Verify device gets IP in 10.0.20.0/24 range
4. Test internet connectivity from test device
5. Test access to router from test device
6. If successful, enable DHCP for all VLANs

**Validation:**
- [ ] Test device receives IP in correct VLAN (10.0.20.x)
- [ ] Test device can access internet (browse, ping 8.8.8.8)
- [ ] Test device can access router web interface
- [ ] Existing devices on old network still work

**Rollback:** Disable DHCP server, reconnect test device to old network

**Status:** ⏸ Not started  
**Issues:** If test fails, troubleshoot before proceeding

---

### Phase 4: Enable Bridge VLAN Filtering (5 min) ⚠️ CRITICAL
**Objective:** Enforce VLAN segmentation (point of no return for existing devices)

**This is the most disruptive step - all devices will lose connectivity temporarily**

**Steps:**
1. Configure bridge VLAN filtering settings
   - Set PVID for untagged traffic (VLAN 40 for IoT backward compatibility)
   - Configure tagged VLANs on bridge ports
2. Enable bridge VLAN filtering
3. **EXPECTED:** All devices on old network disconnect
4. Devices on CAPsMAN SSIDs should maintain connectivity

**Validation:**
- [ ] Devices on new SSIDs maintain internet connectivity
- [ ] Can still access router (from VLAN 20 or via cable on correct VLAN)
- [ ] VLAN isolation working (IoT can't ping Trusted devices)

**Rollback:** Disable bridge VLAN filtering, restore old bridge config

**Status:** ⏸ Not started  
**Issues:** 
- May lose access to router if not on correct VLAN - have web interface open
- Expect devices to start reconnecting to appropriate SSIDs

---

### Phase 5: Device Migration (20 min)
**Objective:** Move devices to appropriate VLANs/SSIDs

**Priority order:**
1. **Infrastructure** (VLAN 10)
   - PoE Switch (10.0.0.101) → 10.0.10.101
   - Management devices

2. **Trusted** (VLAN 20)
   - User devices → COLLECTIVE SSID
   - NAS (10.0.0.102) → 10.0.20.102 or static

3. **Shared Services** (VLAN 30)
   - Home Assistant (Raspberry Pi) → 10.0.30.x
   - Printers/Scanners → 10.0.30.x
   - Chromecasts/Smart TVs → 10.0.30.x

4. **IoT** (VLAN 40)
   - Existing IoT devices should auto-connect to COLLECTIVE-2G
   - Verify Alexa devices, Kasa plugs, etc. reconnect

5. **Guest** (VLAN 50)
   - Test with guest device later

**Validation:**
- [ ] Critical devices online and working (NAS, Home Assistant)
- [ ] User devices have internet connectivity
- [ ] IoT devices reconnected and responding
- [ ] Printers accessible from user devices

**Rollback:** Per-device basis, can reconnect to old SSIDs if needed

**Status:** ⏸ Not started  
**Issues to track:**
- Some IoT devices may need manual reconnection
- May need to create DHCP reservations for static devices
- Document any devices that fail to migrate

---

### Phase 6: Firewall Rules (15 min)
**Objective:** Implement inter-VLAN security policies

**Steps:**
1. Create firewall rules for input chain (router access)
2. Create firewall rules for forward chain (inter-VLAN traffic)
3. Implement rules incrementally:
   - Allow established/related first
   - Allow Trusted → anywhere
   - Allow Shared → IoT (for Home Assistant)
   - Block IoT → Trusted/Shared
   - Block Guest → LAN (except specific IPs)
4. Test after each rule set

**Validation:**
- [ ] Trusted devices can access IoT (ping, http)
- [ ] IoT devices CANNOT access Trusted devices
- [ ] Guest devices CANNOT access LAN (except allowed services)
- [ ] All devices can access Internet
- [ ] Home Assistant can control IoT devices

**Rollback:** Disable firewall rules, use default accept-all

**Status:** ⏸ Not started  
**Issues:** May need to add exceptions for specific applications/protocols

---

### Phase 7: Guest Network Features (10 min)
**Objective:** Enable guest printing/casting with mDNS reflection

**Steps:**
1. Configure mDNS proxy/reflection between VLAN 50 ↔ VLAN 30
2. Add firewall exceptions for Guest → specific Shared devices
3. Test guest casting to Chromecast
4. Test guest printing

**Validation:**
- [ ] Guest device can discover Chromecast via mDNS
- [ ] Guest can cast to TV/Chromecast
- [ ] Guest can discover and print to printer
- [ ] Guest CANNOT access other LAN resources

**Rollback:** Remove mDNS reflection, remove firewall exceptions

**Status:** ⏸ Not started  
**Issues:** mDNS can be finicky, may need adjustment

---

### Phase 8: VPN Tunnel (Later - requires Surfshark config)
**Objective:** Set up WireGuard VPN to Canada for COLLECTIVE-VPN-CA SSID

**Blocked by:** Surfshark WireGuard configuration

**Steps (when ready):**
1. Create WireGuard interface on router
2. Configure peer (Surfshark Canada endpoint)
3. Create routing rule: VLAN 60 → WireGuard
4. Configure NAT masquerading for WireGuard
5. Set DNS for VLAN 60 to Surfshark DNS
6. Add kill switch firewall rule (block VLAN 60 → WAN if VPN down)
7. Enable DHCP for VLAN 60
8. Test connection to COLLECTIVE-VPN-CA SSID

**Validation:**
- [ ] Device on VPN SSID receives IP in 10.0.60.0/24
- [ ] Internet works through VPN
- [ ] Public IP shows as Canada (check with whatismyip.com)
- [ ] Kill switch works (disconnect VPN, verify no internet)

**Rollback:** Disable WireGuard, disable DHCP for VLAN 60

**Status:** ⏸ Blocked - awaiting Surfshark config  
**Issues:** None expected

---

## Emergency Rollback Procedure

**If something goes wrong and you lose access:**

### Option 1: Full Restore (Nuclear option)
1. Connect laptop directly to router via Ethernet (ether2-5)
2. Access router via emergency IP or default gateway
3. Upload backup: `scp backup-20260215-014947.backup admin@10.0.0.1:`
4. SSH to router: `ssh admin@10.0.0.1`
5. Run: `/system backup load name=backup-20260215-014947.backup`
6. Router will reboot to previous state

### Option 2: Reset to Factory (Last resort)
1. Hold reset button on router for 10 seconds
2. Router resets to 192.168.88.1
3. Reconfigure from backup

---

## Known Issues / Circle Back Items

**Track issues here as they arise:**

1. **cAP ac APs not found** - May need manual configuration or reset
   - Status: Pending investigation
   - Workaround: Can proceed with CAPsMAN, configure APs manually if needed

2. **VPN tunnel** - Blocked on Surfshark config
   - Status: Awaiting user to provide WireGuard configuration
   - Impact: COLLECTIVE-VPN-CA SSID will exist but not functional until Phase 8

3. **(Add issues during implementation)**

---

## Progress Tracking

| Phase | Status | Start Time | End Time | Duration | Notes |
|-------|--------|------------|----------|----------|-------|
| 0: Preparation | ⏸ Not started | - | - | - | - |
| 1: VLAN Infrastructure | ⏸ Not started | - | - | - | - |
| 2: CAPsMAN Setup | ⏸ Not started | - | - | - | - |
| 3: Test VLAN | ⏸ Not started | - | - | - | - |
| 4: Enable VLAN Filtering | ⏸ Not started | - | - | - | - |
| 5: Device Migration | ⏸ Not started | - | - | - | - |
| 6: Firewall Rules | ⏸ Not started | - | - | - | - |
| 7: Guest Features | ⏸ Not started | - | - | - | - |
| 8: VPN Tunnel | ⏸ Blocked | - | - | - | Awaiting Surfshark config |

---

## Final Pre-Flight Checklist

**Answer these before starting:**

- [ ] **Physical access:** Are you at home with physical access to router and APs?
- [ ] **Time availability:** Do you have 1-2 hours available for this work?
- [ ] **Backup verified:** Backup files exist and are valid?
- [ ] **Critical services:** Any services that MUST stay online identified?
- [ ] **Rollback plan understood:** Know how to restore from backup if needed?
- [ ] **WiFi password confirmed:** x2230dallas!! is correct?
- [ ] **Accept VPN delay:** OK to implement VPN in Phase 8 later?

**Ready to proceed?** Review this plan, answer questions, then we start with Phase 0.
