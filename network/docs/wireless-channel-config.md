# Wireless Channel Configuration

Last updated: 2026-02-20

## Current Configuration

### Channel Assignments

| AP Location | Band | Channel | Frequency | Width | Justification |
|-------------|------|---------|-----------|-------|---------------|
| Upstairs | 2.4 GHz | 11 | 2462 MHz | 20 MHz | Non-overlapping channel; avoids congestion on Ch 7 from neighbors |
| Downstairs | 2.4 GHz | 1 | 2412 MHz | 20 MHz | Non-overlapping channel; no visible neighbor congestion |
| Upstairs | 5 GHz | 149 | 5745 MHz | 80 MHz | UNII-3 band; non-DFS; less congested than UNII-1 (Ch 36) |
| Downstairs | 5 GHz | 149 | 5745 MHz | 80 MHz | UNII-3 band; non-DFS; less congested than UNII-1 (Ch 36) |

### CAPsMAN Channel Objects

| Name | Band | Frequency | Extension | Purpose |
|------|------|-----------|-----------|---------|
| ch-5ghz-wide | 5 GHz | 5745 | Ceee (80 MHz) | All 5 GHz SSIDs |
| ch-2ghz-ch11 | 2.4 GHz | 2462 | disabled | Upstairs AP 2.4 GHz (Ch 11) |
| ch-2ghz | 2.4 GHz | 2412 | disabled | Downstairs AP 2.4 GHz (Ch 1) |

### CAPsMAN Provisioning Rules

| Rule | Match | Master Config | Slave Configs | Comment |
|------|-------|---------------|---------------|--------|
| 2 | hw-supported-modes=ac | cfg-collective-5ghz | cfg-collective-iot-5ghz, cfg-collective-guest-5ghz | 5GHz radios |
| 3 | radio-mac=74:4D:28:5F:80:20 | cfg-collective-2ghz-ups | cfg-collective-iot-2ghz-ups, cfg-collective-guest-2ghz-ups, cfg-collective-2g-ups | Upstairs 2.4GHz - Ch 11 |
| 4 | radio-mac=74:4D:28:D4:7E:41 | cfg-collective-2ghz-down | cfg-collective-iot-2ghz-down, cfg-collective-guest-2ghz-down, cfg-collective-2g-down | Downstairs 2.4GHz - Ch 1 |

## Design Decisions

### 2.4 GHz Channel Selection

**Constraint:** Only channels 1, 6, and 11 are non-overlapping in 2.4 GHz (in the US regulatory domain).

**Site Survey Findings (2026-02-19):**
- Channel 7: Heavy congestion (5+ neighbor networks detected)
- Channel 1: Clear (no visible neighbors)
- Channel 11: Not scanned but expected to be less congested than 7

**Decision:**
- Upstairs AP: Channel 11 (avoids Ch 7 congestion, provides separation from Downstairs on Ch 1)
- Downstairs AP: Channel 1 (already clear, no change needed)

**Why 20 MHz width:** 
- Best practice for 2.4 GHz in residential environments
- 40 MHz channels in 2.4 GHz cause excessive overlap and interference
- Only 3 non-overlapping 20 MHz channels exist; 40 MHz would reduce to 1

### 5 GHz Channel Selection

**Constraint:** Avoid DFS channels (52-144) due to radar detection requirements causing:
- Delayed AP startup (1+ minute CAC scan)
- Potential channel switches mid-session
- Latency spikes during radar detection events

**Site Survey Findings (2026-02-19):**
- Channel 36 (UNII-1): 3-4 neighbor networks, one at -39 dBm (strong)
- Channel 149 (UNII-3): No visible neighbors

**Decision:**
- Both APs: Channel 149 with 80 MHz width (uses 149, 153, 157, 161)

**Why same channel for both APs:**
- Co-channel interference between your own APs is manageable
- CAPsMAN handles client roaming efficiently
- Simpler configuration and troubleshooting
- 80 MHz requires 4 contiguous channels; using different primary channels would cause overlap

**Why 80 MHz width:**
- Maximizes throughput for 802.11ac clients (MacBook, iPhone, etc.)
- UNII-3 has sufficient spectrum for 80 MHz without DFS concerns
- cAP ac hardware supports 80 MHz operation

### Non-DFS Channel Rationale

| Channel Range | Band | DFS Required | Notes |
|---------------|------|--------------|-------|
| 36-48 | UNII-1 | No | Low power (max 200mW indoor) |
| 52-64 | UNII-2A | **Yes** | Radar detection required |
| 100-144 | UNII-2C | **Yes** | Radar detection required |
| 149-165 | UNII-3 | No | Higher power allowed (1W) |

**Incident (2026-02-19):** Mac Mini experienced 500-1300ms latency spikes while connected to Channel 128 (DFS). Switching to Channel 36 (non-DFS) resolved the issue. Subsequently moved to Channel 149 to avoid UNII-1 congestion.

## Configuration Backups

| Date | Backup Files | Reason |
|------|--------------|--------|
| 2026-02-19 | `export-20260219-192959.rsc`, `backup-20260219-192959.backup` | Before channel optimization |
| 2026-02-19 | `export-20260215-014947.rsc`, `backup-20260215-014947.backup` | Initial VLAN implementation |

## Change History

### 2026-02-20: Channel Optimization
- Changed 5 GHz from Channel 36 to Channel 149
- Changed Upstairs 2.4 GHz from Channel 7 to Channel 11
- Added per-AP 2.4 GHz channel configurations
- **Justification:** Site survey showed congestion on Ch 36 and Ch 7

### 2026-02-19: DFS Channel Fix
- Changed 5 GHz from Channel 128 (DFS) to Channel 36 (non-DFS)
- Increased width capability from 20 MHz to 80 MHz
- Created band-specific provisioning rules
- **Justification:** DFS radar detection causing latency spikes on Mac Mini

## Future Considerations

1. **Periodic site surveys:** Re-scan for neighbors quarterly or when issues arise
2. **WiFi 6 upgrade:** cAP ax supports 160 MHz channels; would require channel re-planning
3. **Third AP:** When installed, consider Channel 6 for 2.4 GHz to maintain separation (1, 6, 11 pattern)
