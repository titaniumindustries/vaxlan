#!/bin/bash
# Monitor Mac Mini network connectivity for brief disconnections

LOG_FILE="$HOME/network-monitor.log"
PING_TARGET="8.8.8.8"
DNS_TARGET="google.com"
GATEWAY="10.0.20.1"

echo "=== Network Connectivity Monitor ===" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "Monitoring for connection drops (Ctrl-C to stop)..." | tee -a "$LOG_FILE"
echo ""

while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Test gateway connectivity
    if ! ping -c 1 -W 1 $GATEWAY &>/dev/null; then
        echo "$TIMESTAMP - ⚠️  GATEWAY UNREACHABLE ($GATEWAY)" | tee -a "$LOG_FILE"
    fi
    
    # Test internet connectivity
    if ! ping -c 1 -W 2 $PING_TARGET &>/dev/null; then
        echo "$TIMESTAMP - ⚠️  INTERNET UNREACHABLE (ping $PING_TARGET failed)" | tee -a "$LOG_FILE"
    fi
    
    # Test DNS resolution
    if ! host -W 2 $DNS_TARGET &>/dev/null; then
        echo "$TIMESTAMP - ⚠️  DNS FAILURE (cannot resolve $DNS_TARGET)" | tee -a "$LOG_FILE"
    fi
    
    # Check WiFi status
    WIFI_STATUS=$(ifconfig en0 | grep "status:" | awk '{print $2}')
    if [ "$WIFI_STATUS" != "active" ]; then
        echo "$TIMESTAMP - ⚠️  WIFI STATUS: $WIFI_STATUS" | tee -a "$LOG_FILE"
    fi
    
    sleep 5
done
