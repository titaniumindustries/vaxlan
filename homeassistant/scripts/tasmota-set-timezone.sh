#!/bin/bash
# tasmota-set-timezone.sh — Set US Eastern timezone on all Tasmota devices
# Created: 2026-04-14
#
# Background:
#   Tasmota devices default to UTC. This caused EnergyToday counters to reset
#   at 7 PM Eastern (midnight UTC) instead of midnight local time.
#
# What it does:
#   Sends a Backlog command via MQTT group topic 'cmnd/tasmotas/Backlog' to ALL
#   Tasmota devices at once, setting:
#     - Timezone 99        → Use TimeDST/TimeSTD rules instead of fixed offset
#     - TimeDST 0,2,3,1,2,-240  → DST: 2nd Sunday March, 2AM, UTC-4 (EDT)
#     - TimeSTD 0,1,11,1,2,-300 → STD: 1st Sunday November, 2AM, UTC-5 (EST)
#
# Prerequisites:
#   - mosquitto_pub installed (brew install mosquitto)
#   - MQTT broker at 10.0.30.11 (Home Assistant Mosquitto add-on)
#   - Tasmota MQTT user credentials
#
# Usage:
#   TASMOTA_MQTT_PASS='<password>' bash homeassistant/scripts/tasmota-set-timezone.sh
#
# Verification:
#   After running, check any Tasmota device console or:
#     mosquitto_sub -h 10.0.30.11 -u tasmota -P "$TASMOTA_MQTT_PASS" \
#       -t 'stat/+/STATUS' --retained-only -C 1
#   Confirm EnergyToday resets at midnight Eastern (next day).

set -euo pipefail

MQTT_HOST="10.0.30.11"
MQTT_USER="tasmota"
MQTT_TOPIC="cmnd/tasmotas/Backlog"
MQTT_PAYLOAD="Timezone 99; TimeDST 0,2,3,1,2,-240; TimeSTD 0,1,11,1,2,-300"

if [ -z "${TASMOTA_MQTT_PASS:-}" ]; then
    echo "ERROR: Set TASMOTA_MQTT_PASS environment variable first."
    echo "  export TASMOTA_MQTT_PASS='<your-mqtt-password>'"
    exit 1
fi

echo "Setting US Eastern timezone on all Tasmota devices..."
echo "  Host:    $MQTT_HOST"
echo "  Topic:   $MQTT_TOPIC"
echo "  Payload: $MQTT_PAYLOAD"
echo ""

mosquitto_pub -h "$MQTT_HOST" -u "$MQTT_USER" -P "$TASMOTA_MQTT_PASS" \
    -t "$MQTT_TOPIC" \
    -m "$MQTT_PAYLOAD"

echo "Done. Verify EnergyToday resets at midnight Eastern."
