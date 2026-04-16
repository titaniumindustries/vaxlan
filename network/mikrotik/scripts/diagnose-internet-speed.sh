#!/bin/bash
# Diagnose internet speed issues on MikroTik router
#
# Updated: 2026-04-14 — Removed sshpass/ROUTER_PASS dependency, migrated from
#   10.0.0.1 to SSH key auth via 'vaxlan-router' host alias (10.0.20.1).
#   Requires ~/.ssh/config (run setup-ssh.sh on a new Mac). UNTESTED after update.

echo "=== Internet Connection Diagnostics ==="
echo ""

echo "1. WAN Interface Status (ether1):"
ssh vaxlan-router '/interface ethernet monitor ether1 once'
echo ""

echo "2. DHCP Client Status (ISP connection):"
ssh vaxlan-router '/ip dhcp-client print detail'
echo ""

echo "3. WAN IP Address:"
ssh vaxlan-router '/ip address print where interface=ether1'
echo ""

echo "4. Test Internet from Router (ping Cloudflare):"
ssh vaxlan-router '/ping 1.1.1.1 count=5'
echo ""

echo "5. Router CPU Load:"
ssh vaxlan-router '/system resource print'
echo ""

echo "6. Active Connections Count:"
ssh vaxlan-router '/ip firewall connection print count-only'
echo ""

echo "7. Check Fasttrack Status (performance optimization):"
ssh vaxlan-router '/ip firewall filter print stats where action=fasttrack-connection'
echo ""

echo "8. Interface Traffic Stats:"
ssh vaxlan-router '/interface print stats where name~"ether1|bridge"'
echo ""

echo "9. Check for Traffic Queues (bandwidth limiting):"
ssh vaxlan-router '/queue simple print'
echo ""

echo "10. Check WAN Link Speed:"
ssh vaxlan-router '/interface ethernet print where name=ether1'
echo ""
