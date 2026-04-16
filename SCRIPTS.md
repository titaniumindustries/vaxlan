# Script Registry

Catalog of all scripts in the vaxlan project. Each entry documents purpose, creation date, usage, and known issues.

Last updated: 2026-04-16

## Home Assistant Scripts

### homeassistant/scripts/backup-ha.sh
- **Purpose**: Download HA configuration, storage, ESPHome configs, blueprints, and full backup (.tar) to local timestamped folder.
- **Created**: 2026-02-21 | **Updated**: 2026-04-14 (migrated to `ha` SSH host alias)
- **Usage**: `bash homeassistant/scripts/backup-ha.sh`
- **Prerequisites**: SSH access to HA (`ssh ha`).
- **Notes**: Creates manifest.txt with file listing. See `homeassistant/docs/backup-process.md` for full documentation.

### homeassistant/scripts/setup-ssh.sh
- **Purpose**: Idempotent SSH config setup for vaxlan infrastructure on a new Mac. Adds `~/.ssh/config` Host entries for `ha`, `vaxlan-router`, and `nas`, loads the Synology Drive-synced ed25519 key into macOS Keychain.
- **Created**: 2026-04-14 | **Updated**: 2026-04-16 (added `nas` host alias, fixed iCloud→Synology Drive references)
- **Usage**: `bash homeassistant/scripts/setup-ssh.sh`
- **Prerequisites**: The keypair must exist at `.ssh-keys/id_ed25519_vaxlan` (synced via Synology Drive ~/Documents/).
- **Notes**: Run once per new Mac. Safe to re-run — skips existing entries.

### homeassistant/scripts/tasmota-set-timezone.sh
- **Purpose**: Set US Eastern timezone (with DST rules) on all Tasmota devices via MQTT group topic. Fixes EnergyToday resetting at 7 PM instead of midnight.
- **Created**: 2026-04-14
- **Origin**: Extracted from KMC Outlets TODO item (root cause: Tasmota defaults to UTC).
- **Usage**: `TASMOTA_MQTT_PASS='<password>' bash homeassistant/scripts/tasmota-set-timezone.sh`
- **Prerequisites**: `mosquitto_pub` installed, MQTT broker at 10.0.30.11.
- **Notes**: Run on any new Tasmota device or after firmware reset. Applies to ALL devices via group topic `cmnd/tasmotas/Backlog`.

## Network / MikroTik Scripts

### network/mikrotik/scripts/monitor-lifx.py
- **Purpose**: Multi-layer LIFX bulb connectivity monitor. Checks ICMP ping (30s), LIFX LAN protocol (60s), and CAPsMAN WiFi association (60s). Logs to CSV, displays live terminal dashboard with state change alerts.
- **Created**: 2026-03-19 (approx.) | **Updated**: 2026-04-14 (migrated to SSH key auth, untested)
- **Usage**: `python3 network/mikrotik/scripts/monitor-lifx.py`
- **Prerequisites**: Python 3.8+, SSH key auth via `vaxlan-router` host alias.
- **Notes**: Logs to `network/mikrotik/scripts/logs/` (gitignored). No longer requires `sshpass` or `ROUTER_PASS`.

### network/mikrotik/scripts/monitor-mac-connectivity.sh
- **Purpose**: Continuous monitoring of Mac Mini network connectivity — pings gateway, internet (8.8.8.8), tests DNS resolution, checks WiFi status. Logs failures.
- **Created**: 2026-03 (approx.)
- **Usage**: `bash network/mikrotik/scripts/monitor-mac-connectivity.sh`
- **Prerequisites**: None (uses standard macOS tools).
- **Notes**: Logs to `~/network-monitor.log`. Gateway hardcoded as `10.0.20.1`.

### network/mikrotik/scripts/monitor-tv-wifi.sh
- **Purpose**: One-shot check of TCL TV WiFi connection quality via CAPsMAN registration stats (TX/RX rate, signal, uptime).
- **Created**: 2026-03 (approx.) | **Updated**: 2026-04-14 (removed hardcoded password, migrated to SSH key auth, untested)
- **Usage**: `bash network/mikrotik/scripts/monitor-tv-wifi.sh`
- **Prerequisites**: SSH key auth via `vaxlan-router` host alias.

### network/mikrotik/scripts/apply-security-rules.sh
- **Purpose**: Upload and import management network security rules (.rsc) to MikroTik router.
- **Created**: 2026-02 (approx.) | **Updated**: 2026-04-14 (migrated to SSH key auth, untested)
- **Usage**: `bash network/mikrotik/scripts/apply-security-rules.sh`
- **Prerequisites**: SSH key auth via `vaxlan-router` host alias. Expects `secure-management-network.rsc` in current directory.

### network/mikrotik/scripts/diagnose-internet-speed.sh
- **Purpose**: Comprehensive internet connection diagnostic — WAN status, DHCP client, ping test, CPU load, connection count, fasttrack, interface stats, queue check.
- **Created**: 2026-02 (approx.) | **Updated**: 2026-04-14 (migrated to SSH key auth, untested)
- **Usage**: `bash network/mikrotik/scripts/diagnose-internet-speed.sh`
- **Prerequisites**: SSH key auth via `vaxlan-router` host alias. No longer requires `sshpass` or `ROUTER_PASS`.

### Removed Scripts (2026-04-14)
- **`network/mikrotik/scripts/get-firewall-rules.sh`** — Trivial one-liner (`ssh vaxlan-router '/ip firewall filter export'`). Command is documented in SKILL.md.
- **`network/mikrotik/scripts/setup-ssh-keys.sh`** — Superseded by `homeassistant/scripts/setup-ssh.sh` (ed25519, macOS Keychain, multi-device).

## Synology Backup Scripts

### synology/backup/scripts/get_aws_storage_report.sh
- **Purpose**: Fetch S3 storage metrics from AWS CloudWatch for all three backup buckets (personal, media, surveillance). Shows daily storage sizes and estimated costs.
- **Created**: 2026-03 (approx.)
- **Usage**: `bash synology/backup/scripts/get_aws_storage_report.sh [DAYS]` (default: 30)
- **Prerequisites**: AWS CLI configured with `vaxocentric` profile, `jq`.
- **Notes**: Uses CloudWatch metrics (no S3 list operations). Tracks Standard, Glacier IR, and Deep Archive storage classes.

### synology/backup/scripts/track_s3_usage.sh
- **Purpose**: Daily S3 storage usage tracker. Queries all three backup buckets, calculates costs, appends to CSV log.
- **Created**: 2026-03 (approx.)
- **Usage**: `bash synology/backup/scripts/track_s3_usage.sh`
- **Prerequisites**: AWS CLI configured with `vaxocentric` profile, `jq`, `bc`.
- **Notes**: Logs to `synology/backup/logs/s3_usage_log.csv`. Intended for daily cron/launchd execution.

## Known Systemic Issues

1. **Stale router IP**: ~~Scripts referencing `10.0.0.1`~~ — All scripts updated to use `vaxlan-router` SSH host alias as of 2026-04-14. If new scripts are created, always use the host alias, never hardcode IPs.
2. **Password-based SSH**: ~~Several scripts use `sshpass` or hardcoded passwords~~ — All scripts migrated to SSH key auth as of 2026-04-14. The `sshpass` tool is no longer required for any vaxlan script.
3. **Untested updates**: `monitor-lifx.py`, `monitor-tv-wifi.sh`, `diagnose-internet-speed.sh`, and `apply-security-rules.sh` were updated 2026-04-14 but not yet tested end-to-end.
