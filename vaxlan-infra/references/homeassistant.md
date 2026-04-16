# Home Assistant CLI Reference (HAOS on RPi 4)

## Connection

```
ssh ha
```

Auth: SSH key (`.ssh-keys/id_ed25519_vaxlan`, iCloud-synced via `~/Documents/`). Host alias defined in `~/.ssh/config`.
Backup password: `purple bucket car jumping potatoe pumpkin red`
New Mac setup: `bash homeassistant/scripts/setup-ssh.sh`

## ha CLI (Host-Level Management)

The `ha` command manages HAOS, Supervisor, and add-ons from the SSH shell.

```
# System info
ha info
ha os info
ha supervisor info
ha core info

# Core (Home Assistant) control
ha core start
ha core stop
ha core restart
ha core update
ha core check    # Validate config before restart

# Supervisor
ha supervisor update
ha supervisor reload

# Host / OS
ha host reboot
ha host shutdown
ha os update

# Add-on management
ha addons list         # JSON, pipe to jq for readability
ha addons info SLUG
ha addons start SLUG
ha addons stop SLUG
ha addons restart SLUG
ha addons update SLUG
ha addons logs SLUG

# Common add-on slugs:
#   a0d7b954_ssh          → Advanced SSH & Web Terminal
#   5c53de3b_esphome      → ESPHome Device Builder
#   core_configurator     → File Editor
#   core_mosquitto        → Mosquitto MQTT Broker
#   core_zwave_js         → Z-Wave JS
#   77b2833f_matter_server → Matter Server
#   a0d7b954_lets_encrypt → Let's Encrypt
#   a0d7b954_tasmoadmin   → TasmoAdmin

# Backups
ha backups list
ha backups new --name "backup-YYYYMMDD"
ha backups restore SLUG

# Network
ha network info
ha dns info

# Hardware
ha hardware info

# Logs
ha core logs
ha supervisor logs
ha host logs
```

## Config File Paths

All relative to `/config/` on the HA system:

- `configuration.yaml` — Main config
- `automations.yaml` — Automations
- `scripts.yaml` — Scripts
- `scenes.yaml` — Scenes
- `secrets.yaml` — Credentials (not in repo)
- `esphome/` — ESPHome device configs
- `.storage/core.config_entries` — Integration storage
- `home-assistant_v2.db` — SQLite database
- `custom_components/` — HACS integrations

## Config Validation

Always validate before restarting:
```
ha core check
```

Or from within the config directory:
```
hass --script check_config -c /config
```

## API (from other devices)

```
# Check if HA is running (no auth needed)
curl -s http://10.0.30.11:8123/api/ -H "Authorization: Bearer LONG_LIVED_TOKEN"

# Get entity state
curl -s http://10.0.30.11:8123/api/states/ENTITY_ID -H "Authorization: Bearer TOKEN"

# Call a service
curl -X POST http://10.0.30.11:8123/api/services/DOMAIN/SERVICE \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entity_id": "ENTITY_ID"}'
```

## ESPHome

```
# ESPHome configs live at:
ls /config/esphome/

# Compile and upload from HA (usually done via web UI at port 6052)
# CLI alternative:
esphome compile /config/esphome/DEVICE.yaml
esphome upload /config/esphome/DEVICE.yaml
esphome logs /config/esphome/DEVICE.yaml
```

## MQTT (Mosquitto)

```
# Mosquitto config
cat /config/mosquitto/mosquitto.conf

# Test MQTT from HA shell
mosquitto_pub -h localhost -t "test/topic" -m "hello"
mosquitto_sub -h localhost -t "test/topic"

# Tasmota devices use MQTT auto-discovery
# Topic prefix: tasmota/discovery/
```

## Useful Diagnostics

```
# Check HA database size
ls -lh /config/home-assistant_v2.db

# Check disk space
df -h

# Show running containers (HAOS uses Docker)
docker ps

# Network test from HA
ping -c 3 10.0.40.10    # ESPHome device
ping -c 3 10.0.30.10    # NAS
ping -c 3 10.0.40.1     # IoT gateway
```
