#!/bin/bash
# Apply management network security rules to MikroTik router
#
# Updated: 2026-04-14 — Migrated from password SSH / 10.0.0.1 to SSH key auth
#   via 'vaxlan-router' host alias (10.0.20.1). Requires ~/.ssh/config
#   (run setup-ssh.sh on a new Mac). UNTESTED after update.

echo "Applying management network security rules..."
echo ""
echo "This will:"
echo "  ✓ Block IoT VLAN from accessing router management (SSH/WinBox/WebFig)"
echo "  ✓ Block Guest VLAN from accessing router management"
echo "  ✓ Block IoT VLAN from accessing management network"
echo "  ✓ Block Guest VLAN from accessing management network"
echo "  ✓ Block Guest from Trusted and IoT VLANs"
echo "  ✓ Allow Trusted VLAN full access to management network"
echo "  ✓ Allow Trusted VLAN access to all other VLANs"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read

scp secure-management-network.rsc vaxlan-router:/
ssh vaxlan-router 'import secure-management-network.rsc'

echo ""
echo "✓ Security rules applied!"
echo ""
echo "Verifying firewall rules..."
ssh vaxlan-router '/ip firewall filter print where comment~"Management|Trusted"'
