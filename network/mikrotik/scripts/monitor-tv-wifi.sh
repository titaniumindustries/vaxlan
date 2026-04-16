#!/bin/bash
# Monitor TCL TV WiFi connection quality
#
# Updated: 2026-04-14 — Removed hardcoded router password, migrated from
#   sshpass/10.0.0.1 to SSH key auth via 'vaxlan-router' host alias.
#   Requires ~/.ssh/config (run setup-ssh.sh on a new Mac). UNTESTED after update.

TV_MAC="D8:13:99:3C:6D:5B"
TV_NAME="55\" TCL Roku TV"

echo "=== $TV_NAME WiFi Monitor ==="
echo "MAC: $TV_MAC"
echo ""

OUTPUT=$(ssh vaxlan-router \
  "/caps-man registration-table print stats where mac-address=\"$TV_MAC\"")

echo "$OUTPUT" | grep -o 'tx-rate="[^"]*"' | cut -d'"' -f2 | while read TX; do
  RX=$(echo "$OUTPUT" | grep -o 'rx-rate="[^"]*"' | cut -d'"' -f2)
  SIG=$(echo "$OUTPUT" | grep -o 'rx-signal=-[0-9]*' | cut -d'=' -f2)
  UP=$(echo "$OUTPUT" | grep -o 'uptime=[^ ]*' | cut -d'=' -f2)
  
  echo "TX Rate (AP → TV): $TX"
  echo "RX Rate (TV → AP): $RX"
  echo "Signal Strength:   $SIG dBm"
  echo "Uptime:            $UP"
  echo ""
  
  # Alert if RX rate is suspiciously low
  if [[ "$RX" == "6Mbps" ]] || [[ ! "$RX" =~ Mbps ]]; then
    echo "⚠️  WARNING: TV WiFi degraded!"
    echo "   RX rate is only $RX"
    echo "   Recommended: Power cycle the TV"
  else
    echo "✓ Connection looks healthy"
  fi
done
