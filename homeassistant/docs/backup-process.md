# Home Assistant Backup Process

## Overview

This document describes the backup strategy for Home Assistant to enable full recovery from hardware or storage failure.

## Backup Location

```
homeassistant/
└── backups/
    └── YYYYMMDD-HHMMSS/      # One folder per backup
        ├── manifest.txt       # Backup metadata
        ├── config/            # YAML configuration files
        ├── storage/           # Integration & registry data
        ├── esphome/           # ESPHome device configs
        ├── blueprints/        # Automation blueprints
        └── ha-backup/         # Full HA backup (.tar)
```

## What's Backed Up

| Component | Location on HA | Description |
|-----------|----------------|-------------|
| YAML configs | `/config/*.yaml` | Main configuration, automations, scripts, scenes |
| Storage | `/config/.storage/` | Integrations, device/entity registries, auth, dashboards |
| ESPHome | `/config/esphome/` | ESPHome device YAML configurations |
| Blueprints | `/config/blueprints/` | Automation and script blueprints |
| Full backup | `/backup/*.tar` | Complete HA backup including add-ons and database |

## Running a Backup

### Quick Command

```bash
cd ~/Documents/WarpProjects\ \(Personal\)/vaxlan/homeassistant
./scripts/backup-ha.sh
```

### What the Script Does

1. Creates a timestamped backup folder (e.g., `20260221-205800`)
2. Copies YAML configuration files via SCP
3. Copies `.storage` directory (integrations, registries)
4. Copies ESPHome device configurations
5. Copies blueprints (if any)
6. Downloads the latest full HA backup (.tar file)
7. Creates a manifest file listing all backed up files

## When to Backup

Create a backup:
- **Before** making significant configuration changes
- **After** successfully completing configuration changes
- Before upgrading Home Assistant Core or OS
- Before adding/removing integrations
- Weekly as a routine practice

## Recovery Process

### Full Recovery (New Hardware)

1. Install Home Assistant OS on new hardware
2. During initial setup, choose "Restore from backup"
3. Upload the `.tar` file from `ha-backup/` folder
4. Wait for restore to complete

### Partial Recovery (Config Only)

If only configuration files are corrupted:

```bash
# Copy config files back to HA
scp backups/YYYYMMDD-HHMMSS/config/*.yaml root@10.0.30.11:/config/

# Copy storage files (integrations, registries)
scp -r backups/YYYYMMDD-HHMMSS/storage/* root@10.0.30.11:/config/.storage/

# Restart Home Assistant
ssh root@10.0.30.11 "ha core restart"
```

### ESPHome Recovery

```bash
scp -r backups/YYYYMMDD-HHMMSS/esphome/* root@10.0.30.11:/config/esphome/
```

## Home Assistant's Built-in Backups

Home Assistant creates automatic backups daily at 5:00 AM. These are stored in `/backup/` on the HA system.

Current automatic backups:
- Retained: Last 3 days
- Location: `/backup/`
- Format: `.tar` (includes everything)

To manually trigger a backup in HA:
1. Go to Settings → System → Backups
2. Click "Create Backup"
3. Choose full or partial backup

## Backup Retention

Suggested retention policy:
- Keep last 5 local backups
- Archive monthly backups to cloud storage (optional)

To clean up old backups:
```bash
# List backups by date
ls -lt backups/

# Remove old backup (example)
rm -rf backups/20260101-120000
```

## Prerequisites

- SSH access to Home Assistant (configured via Advanced SSH & Web Terminal addon)
- SSH key added to ssh-agent: `ssh-add ~/.ssh/id_ed25519`

## Troubleshooting

### SSH Connection Failed
```bash
# Verify HA is reachable
ping 10.0.30.11

# Test SSH connection
ssh root@10.0.30.11 "echo OK"

# If key not loaded, add it
ssh-add ~/.ssh/id_ed25519
```

### Backup Script Permission Denied
```bash
chmod +x scripts/backup-ha.sh
```

### No HA Backup Found
Create a backup manually in HA UI first:
Settings → System → Backups → Create Backup

---

*Last updated: 2026-02-21*
