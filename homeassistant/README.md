# Home Assistant

## System Overview

| Property | Value |
|----------|-------|
| **IP Address** | 10.0.30.11 |
| **VLAN** | 30 (Shared Services) |
| **Hostname** | homeassistant |
| **Hardware** | Raspberry Pi 4 |
| **OS** | Home Assistant OS 17.1 (aarch64) |
| **Core Version** | 2026.2.3 |
| **Supervisor Version** | 2026.02.2 |
| **Location** | Richmond, VA (America/New_York) |

## Network Configuration

- **Interface**: end0
- **IP**: 10.0.30.11/24
- **Gateway**: 10.0.30.1 (router)
- **DHCP**: Static reservation via MikroTik
- **MAC Address**: DC:A6:32:AA:FE:ED

### Internal Docker Networks
- hassio bridge: 172.30.32.1/23
- docker0: 172.30.232.1/23

### Network Placement

Home Assistant runs on VLAN 30 (Shared Services), allowing it to:
- Communicate with trusted clients (VLAN 20)
- Control IoT devices (VLAN 40)
- Access shared services like printers and TVs

## SSH Access

```bash
ssh ha
```

- **Username**: root
- **Host alias**: `ha` (defined in `~/.ssh/config`)
- **Authentication**: SSH key (`.ssh-keys/id_ed25519_vaxlan`, iCloud-synced)
- **Backup password**: `purple bucket car jumping potatoe pumpkin red`
- **Add-on**: Advanced SSH & Web Terminal 23.0.2
- **SFTP**: Enabled on port 22
- **New Mac setup**: Run `bash homeassistant/scripts/setup-ssh.sh`

### Config Paths (on HA system)
| Path | Description |
|------|-------------|
| `/config/configuration.yaml` | Main config |
| `/config/automations.yaml` | Automations |
| `/config/secrets.yaml` | Secrets/credentials |
| `/config/esphome/` | ESPHome device configs |
| `/config/.storage/core.config_entries` | Integration storage |
| `/config/home-assistant_v2.db` | Database |

## Installed Add-ons

| Add-on | Version | Status |
|--------|---------|--------|
| Advanced SSH & Web Terminal | 23.0.2 | Started |
| ESPHome Device Builder | 2026.2.1 | Started |
| File Editor | 5.8.0 | Started |
| Let's Encrypt | 6.0.4 | Started |
| Matter Server | 8.2.2 | Started |
| Mosquitto Broker | 6.5.2 | Started |
| TasmoAdmin | 0.33.0 | Started |
| Z-Wave JS | 1.0.0 | Started |

## Key Integrations

- **ESPHome** - IoT device management
- **Z-Wave JS** - Z-Wave device control
- **MQTT** (Mosquitto) - Message broker for IoT
- **Tasmota** - Tasmota device integration via MQTT discovery
- **Matter** - Smart home standard
- **TPLink/Kasa** - Smart plugs and switches
- **WLED** - LED strip controllers
- **Flume** - Water monitoring
- **NUT** - UPS monitoring
- **Raspberry Pi** - Hardware monitoring

## ESPHome Devices

| Device | Config File | IP Address | VLAN |
|--------|-------------|------------|------|
| EnergyMeter (CircuitSetup) | `esphome-web-32cb94.yaml` | 10.0.40.10 | 40 (IoT) |

## Tasmota Devices (MQTT)

KMC Smart Tap (Model 30608) outlets managed via TasmoAdmin and MQTT discovery.
Module: KMC 4 Outlet (0). Firmware: Tasmota 15.3.0 (full) — ESP8266, 2MB flash. HLW8012 energy monitoring enabled.
MQTT: Connected to Mosquitto broker (10.0.30.11:1883, user `tasmota`). Firewall rule allows IoT (VLAN 40) → HA TCP 1883.
Timezone: `Timezone 99; TimeDST 0,2,3,1,2,-240; TimeSTD 0,1,11,1,2,-300` (US Eastern with DST).

| Device Name | IP | Assignment | VLAN |
|-------------|-----|------------|------|
| Tasmota-Outlet-01 | 10.0.40.81 | Workshop Radios | 40 (IoT) |
| Tasmota-Outlet-02 | 10.0.40.82 | Workshop Charging Station | 40 (IoT) |
| Tasmota-Outlet-03 | 10.0.40.83 | Unused | 40 (IoT) |
| Tasmota-Outlet-04 | 10.0.40.84 | Kneewall Dehumidifier | 40 (IoT) |
| Tasmota-Outlet-05 | 10.0.40.85 | Unused | 40 (IoT) |
| Tasmota-Outlet-06 | 10.0.40.86 | Network Infrastructure | 40 (IoT) |
| Tasmota-Outlet-07 | 10.0.40.87 | Jonathan's Computer & Treadmill | 40 (IoT) |

### Next Steps
- **Add power gauge cards to Erin's Dashboard** — same style as the CircuitSetup energy monitor gauges. Each KMC device has one power meter covering all three switched outlets.
- **Optional tuning**: `SetOption19 0` (modern discovery), `TelePeriod 300` (5-min telemetry), `PowerOnState 3` (already set). Consider `MaxPower` for overcurrent protection on Outlet-04 (dehumidifier).
- **Ensure TasmoAdmin naming aligns to outlets 06/07** so MQTT discovery creates `sensor.tasmota_outlet_06_*` and `sensor.tasmota_outlet_07_*` entities used by Erin's Dashboard and daily-kWh helpers.
- **Optional tuning**: `SetOption19 0` (modern discovery), `TelePeriod 300` (5-min telemetry), `PowerOnState 3` (already set). Consider `MaxPower` for overcurrent protection on Outlet-04 (dehumidifier).

## Web Access

- **URL**: http://10.0.30.11:8123
- **Mobile App**: Home Assistant Companion

## Firewall Rules

See [`network/docs/firewall-rules.md`](../network/docs/firewall-rules.md) — Shared and IoT sections.

Relevant rules: `Allow Shared to IoT (Home Assistant)`, `Allow Home Assistant to ESPHome`, `Allow ESPHome to Home Assistant API`, `Allow IoT to Home Assistant MQTT`.

## Directory Structure (this repo)

- **config/** - Home Assistant configuration files
- **automations/** - Automation scripts and scenes
- **docs/** - Documentation and setup guides

## Backup

Local backups are stored in `backups/` with timestamps (YYYYMMDD-HHMMSS).

To create a backup:
```bash
./scripts/backup-ha.sh
```

See `docs/backup-process.md` for full documentation.

---

*Last updated: 2026-04-01*
