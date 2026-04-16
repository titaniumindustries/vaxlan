# LIFX Bulb Connectivity Monitoring

**Status:** Active (temporary diagnostic)
**Created:** 2026-02-22
**Purpose:** Diagnose intermittent LIFX WiFi disconnections

## Problem

LIFX bulbs intermittently become non-responsive in the LIFX app and Home Assistant. Power cycling fixes them. The issue is not always the same bulbs. Other IoT devices on the same WiFi remain connected, suggesting it's not a WiFi coverage issue. This is a [known LIFX firmware issue](https://support.lifx.com/hc/en-us/articles/36434861480727-LIFX-Appears-Disconnected) affecting many users.

## LIFX Bulb Inventory

All bulbs connect to **COLLECTIVE-2G** SSID (2.4GHz, WPA2) → VLAN 40 (IoT, 10.0.40.0/24), managed via CAPsMAN on the downstairs AP (cap210, channel 1).

| MAC Address | DHCP IP | Name | Notes |
|---|---|---|---|
| D0:73:D5:12:74:F0 | 10.0.40.234 | Garage Hanging South | Static DHCP lease |
| D0:73:D5:12:55:5A | 10.0.40.219 | (unnamed in DHCP) | Dynamic lease — needs static reservation + name |
| D0:73:D5:12:1D:E1 | 10.0.40.229 | Garage Attic | Static DHCP lease |
| D0:73:D5:12:9A:2A | 10.0.40.204 | Garage Hanging North | Static DHCP lease |
| D0:73:D5:12:65:B8 | 10.0.40.206 | Den Floor Lamp | Static DHCP lease |
| D0:73:D5:12:B0:AA | 10.0.40.227 | Garage Spot North | Static DHCP lease |
| D0:73:D5:12:78:30 | 10.0.40.236 | Office Table Lamp | Static DHCP lease |
| D0:73:D5:12:68:F4 | — | (unknown) | In old DHCP config, no current VLAN lease |
| D0:73:D5:12:A0:D3 | — | (unknown) | In old DHCP config, no current VLAN lease |

## Monitoring Components

### 1. RouterOS CAPsMAN Logger (on router)

**Script:** `lifx-capsman-monitor`
**Scheduler:** Runs every 60 seconds
**Log prefix:** `LIFX-MON:`

Iterates the CAPsMAN registration table and logs signal strength, uptime, and AP interface for all LIFX MACs (D0:73:D5 prefix). Runs directly on the router, providing data even when the external script isn't active.

**View logs:**
```
/log print where message~"LIFX-MON"
```

**Remove when no longer needed:**
```
/system script remove lifx-capsman-monitor
/system scheduler remove lifx-capsman-monitor
```

**Setup file:** `mikrotik/scripts/lifx-monitor-setup.rsc`

### 2. Python Monitoring Script (on Mac)

**Script:** `mikrotik/scripts/monitor-lifx.py`
**Logs:** `mikrotik/scripts/logs/lifx-YYYY-MM-DD.csv`

Three monitoring layers:
- **Layer 1 — ICMP ping (every 30s):** Basic IP reachability
- **Layer 2 — LIFX LAN protocol (every 60s):** Sends GetService (UDP 56700) to test firmware responsiveness. Also retrieves bulb names via GetLabel.
- **Layer 3 — CAPsMAN WiFi (every 60s):** SSHs to router to check WiFi association status, signal strength, tx/rx rates, and uptime.

#### Usage

```bash
export ROUTER_PASS='your_router_password'
python3 mikrotik/scripts/monitor-lifx.py
```

Press Ctrl+C to stop. A session summary is printed on exit.

#### Requirements
- Python 3.8+
- `sshpass` (`brew install sshpass`)
- Network access to router (10.0.20.1) and IoT VLAN (10.0.40.0/24)

## Interpreting Results

### Bulb States

| State | Ping | LIFX Protocol | CAPsMAN | Meaning |
|---|---|---|---|---|
| **ONLINE** | ✓ | ✓ | ✓ | Fully operational |
| **ZOMBIE** | ✓ or ✗ | ✗ | ✓ | WiFi connected but LIFX firmware hung. Most common failure mode. Power cycle required. |
| **OFFLINE** | ✗ | ✗ | ✗ | Not connected to WiFi at all. May indicate power loss, WiFi deauth, or DHCP failure. |
| **Partial** | ✓ | ✗ | ✗ | Responds to ping but not on CAPsMAN or LIFX — rare, possibly stale ARP/DHCP. |

### Key Diagnostic Patterns

**Zombie bulbs (WiFi up, LIFX down):**
- The bulb's WiFi stack is running but the application firmware has crashed/hung
- This is the most common LIFX failure mode
- Only fix is power cycling
- Monitoring data: CAPsMAN shows registered with good signal, but LIFX GetService times out

**WiFi deauth (all three down simultaneously):**
- Bulb dropped from CAPsMAN registration table
- Could be AP-initiated or client-initiated
- Check signal strength trend before dropout — degrading signal suggests interference
- Check if multiple bulbs drop at the same time — suggests AP issue, not bulb issue

**DHCP lease failure:**
- DHCP status changes from "bound" to "waiting"
- Bulb may still be WiFi-associated but has no IP
- Check if DHCP pool is exhausted

### CSV Log Fields

| Field | Description |
|---|---|
| `timestamp` | UTC timestamp |
| `mac` | Bulb MAC address |
| `name` | Human-readable bulb name |
| `ip` | Current IP from DHCP |
| `dhcp_status` | DHCP lease status (bound/waiting) |
| `ping_ok` | ICMP ping reachable |
| `ping_ms` | Ping latency in ms |
| `lifx_ok` | LIFX GetService response received |
| `lifx_power` | Light power state (on/off) |
| `capsman_registered` | In CAPsMAN registration table |
| `signal_dbm` | WiFi signal strength (dBm) |
| `tx_rate` / `rx_rate` | WiFi data rates |
| `uptime` | WiFi association uptime |
| `ap_interface` | Connected AP CAPsMAN interface |
| `ssid` | Connected SSID |

## Initial Findings (2026-02-22)

1. **"Garage Hanging South" responds normally** — Ping (2.58ms), LIFX LAN protocol (GetService + GetLabel), and CAPsMAN registration all working. The bulb is on the network at 10.0.40.234 with signal -61dBm. If the LIFX app/HA report it as non-responsive, the issue may be cloud-side, or the HA/app integration may need restarting.

2. **D0:73:D5:12:55:5A has no DHCP comment** — This bulb has a dynamic lease but no static reservation or name. It should be identified (via LIFX GetLabel in the monitoring script) and given a static DHCP reservation.

3. **"Garage Spot North" is offline** — DHCP status is "waiting" (lease expired), not in CAPsMAN registration table. This bulb has fully disconnected from WiFi and needs power cycling.

4. **"Office Table Lamp" has DHCP lease but not in CAPsMAN** — Bound DHCP lease at 10.0.40.236 but not appearing in CAPsMAN registration. Could indicate the bulb connected, got an IP, then lost WiFi association. The DHCP lease persists until it expires (1 day).

5. **Two old MACs missing entirely** — D0:73:D5:12:68:F4 and D0:73:D5:12:A0:D3 had leases in the old flat-network config but have no current VLAN 40 DHCP leases. These bulbs may have been removed/replaced or may need to be reconnected to COLLECTIVE-2G.

6. **All connected bulbs are on cap210** (downstairs AP, channel 1) — No LIFX bulbs are connecting to the upstairs AP. This is expected if all bulbs are in the garage/den area.

## Pre-Monitoring Router Backup

- Router export: `mikrotik/backups/backup-pre-lifx-monitor-20260222.rsc`
- Router binary backup: stored on router as `backup-pre-lifx-monitor.backup`

## Cleanup

When monitoring is no longer needed:

1. Stop the Python script (Ctrl+C)
2. Remove router script and scheduler:
   ```
   /system script remove lifx-capsman-monitor
   /system scheduler remove lifx-capsman-monitor
   ```
3. Optionally remove log files: `rm mikrotik/scripts/logs/lifx-*.csv`
