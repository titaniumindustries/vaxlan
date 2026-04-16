# Management Network Security Implementation
**Date:** 2026-02-16  
**Status:** ✅ Active

---

## Overview

Implemented comprehensive firewall rules to protect the management network (10.0.0.0/16) and network infrastructure devices from untrusted VLANs (IoT and Guest).

---

## Management Network Devices

**Network:** 10.0.0.0/16 (untagged on ether2)

| Device | IP | Access |
|--------|-----|--------|
| MikroTik hEX S Router | 10.0.0.1 | WinBox, SSH, WebFig |
| Netgear GS305EP Switch | 10.0.0.101 | Web Management |
| cAP ac (Den) | 10.0.0.2 | WebFig |
| cAP ac (Living Room) | 10.0.0.3 | WebFig |
| cAP ac (Master Bedroom) | 10.0.0.4 | WebFig |

---

## Security Rules Applied

### **INPUT Chain (Router Protection)**

**Rule 0:** Block IoT VLAN from router management
- Action: DROP
- Interface: vlan40-iot
- **Protects:** Router management (SSH, WinBox, WebFig)

**Rule 1:** Block Guest VLAN from router management
- Action: DROP
- Interface: vlan50-guest
- **Protects:** Router management (SSH, WinBox, WebFig)

---

### **FORWARD Chain (Network Segmentation)**

**Rule 5:** Allow Trusted to Management Network
- Action: ACCEPT
- Source: vlan20-trusted
- Destination: 10.0.0.0/16
- **Purpose:** Trusted devices can access all infrastructure

**Rule 6:** Allow Trusted to Shared
- Action: ACCEPT
- Source: vlan20-trusted → vlan30-shared
- **Purpose:** Trusted devices can access NAS, printers, Home Assistant

**Rule 7:** Allow Trusted to IoT
- Action: ACCEPT
- Source: vlan20-trusted → vlan40-iot
- **Purpose:** Trusted devices can manage/troubleshoot IoT devices

**Rule 8:** Block IoT from Management Network
- Action: DROP
- Source: vlan40-iot
- Destination: 10.0.0.0/16
- **Protects:** Switches, APs from compromised IoT devices

**Rule 9:** Block Guest from Management Network
- Action: DROP
- Source: vlan50-guest
- Destination: 10.0.0.0/16
- **Protects:** Infrastructure from guest WiFi users

**Rule 10:** Block Guest from Trusted
- Action: DROP
- Source: vlan50-guest → vlan20-trusted
- **Protects:** Personal devices from guest access

**Rule 11:** Block Guest from IoT
- Action: DROP
- Source: vlan50-guest → vlan40-iot
- **Protects:** IoT devices from guest interference

**Rule 16:** Block IoT from Trusted
- Action: DROP
- Source: vlan40-iot → vlan20-trusted
- **Protects:** Personal devices from IoT pivot attacks

---

## Access Matrix

| Source VLAN | Management (10.0.0.x) | Trusted (20) | Shared (30) | IoT (40) | Guest (50) | Internet |
|-------------|----------------------|--------------|-------------|----------|------------|----------|
| **Trusted (20)** | ✅ Full Access | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Shared (30)** | ❌ Blocked | ❌ | ✅ | ✅ Selective* | ❌ | ✅ |
| **IoT (40)** | ❌ **BLOCKED** | ❌ **BLOCKED** | ✅ Selective* | ✅ | ❌ | ✅ |
| **Guest (50)** | ❌ **BLOCKED** | ❌ **BLOCKED** | ✅ Selective* | ❌ **BLOCKED** | ✅ | ✅ |

*Selective = Only specific devices/ports allowed (NAS, Chromecasts, Home Assistant API)

---

## Security Benefits

### **Before (Vulnerable):**
- ❌ IoT devices could access router at 10.0.0.1
- ❌ IoT devices could access switch management (.101)
- ❌ IoT devices could access AP management (.2, .3, .4)
- ❌ Guest WiFi users could access all infrastructure
- ❌ Compromised smart bulb could pivot to trusted devices
- ❌ No defense-in-depth for management plane

### **After (Secured):**
- ✅ Router management isolated from untrusted VLANs
- ✅ Switch/AP management isolated from IoT and Guest
- ✅ Trusted VLAN has full infrastructure access (no restrictions)
- ✅ IoT devices trapped in VLAN 40 (no pivot possible)
- ✅ Guest WiFi completely isolated (internet + cast only)
- ✅ Defense-in-depth: VLAN segmentation + firewall enforcement
- ✅ Management network (10.0.0.x) protected by out-of-band separation

---

## Verification Commands

### Test from Trusted VLAN (should work):
```bash
# Access router
ssh admin@10.0.0.1

# Access switch
open http://10.0.0.101

# Access APs
open http://10.0.0.2
```

### Test from IoT device (should fail):
```bash
# Try to ping router (will timeout)
ping 10.0.0.1

# Try to access switch (no route/blocked)
curl http://10.0.0.101
```

### View firewall logs:
```bash
ssh admin@10.0.0.1 "/log print where topics~\"firewall\""
```

---

## Architecture Decision: Untagged Management Network

**Decision:** Keep 10.0.0.0/16 as untagged management network (not VLAN 10)

**Rationale:**
- **Out-of-Band Management:** Industry best practice for enterprise networks
- **Disaster Recovery:** If VLAN config breaks, infrastructure remains accessible
- **Simplicity:** No chicken-and-egg issues during troubleshooting
- **CAPsMAN:** Standard MikroTik pattern for AP management
- **Safety:** Cannot lock yourself out of router via VLAN misconfiguration

**Trade-off:** Slightly less "pure" VLAN design, but significantly more robust and maintainable.

---

## Files
- `secure-management-network.rsc` - Firewall rules
- `apply-security-rules.sh` - Deployment script
- `firewall-rules-current.rsc` - Current config export

---

## Notes
- Rules applied: 2026-02-16 17:42 UTC
- Zero downtime implementation
- No devices required reconfiguration
- All existing services continue working
- Trusted VLAN retains full access as required
