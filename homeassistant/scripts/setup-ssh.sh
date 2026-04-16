#!/bin/bash
# setup-ssh.sh — Configure SSH for vaxlan infrastructure on a new Mac
# Created: 2026-04-14
#
# What it does:
#   1. Ensures ~/.ssh/config exists with correct permissions
#   2. Adds Host entries for 'ha' (Home Assistant), 'vaxlan-router' (MikroTik RB5009), and 'nas' (Synology NAS)
#   3. Points IdentityFile to the Synology Drive-synced ed25519 key in this repo
#   4. Adds the key to the macOS Keychain
#
# Prerequisites:
#   - The keypair must already exist at .ssh-keys/id_ed25519_vaxlan (synced via Synology Drive)
#   - Run this script from any directory — it resolves paths automatically
#
# Usage:
#   bash homeassistant/scripts/setup-ssh.sh

set -euo pipefail

# Resolve the key path relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
KEY_PATH="$REPO_ROOT/.ssh-keys/id_ed25519_vaxlan"

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== vaxlan SSH Setup ===${NC}"

# Check that the key exists (should be synced via Synology Drive)
if [ ! -f "$KEY_PATH" ]; then
    echo -e "${RED}ERROR: Key not found at $KEY_PATH${NC}"
    echo "The key should sync via Synology Drive from your other Mac."
    echo "If this is a brand new setup, generate the key first:"
    echo "  ssh-keygen -t ed25519 -C vaxlan-infra -f '$KEY_PATH'"
    exit 1
fi

# Ensure ~/.ssh exists with correct permissions
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Ensure config file exists
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

# Function to add a host block if not already present
add_host_if_missing() {
    local host_alias="$1"
    local host_block="$2"

    if grep -q "^Host ${host_alias}$" "$SSH_CONFIG" 2>/dev/null; then
        echo -e "${YELLOW}  Host '${host_alias}' already exists in config — skipping${NC}"
    else
        echo "" >> "$SSH_CONFIG"
        echo "$host_block" >> "$SSH_CONFIG"
        echo -e "${GREEN}  Added Host '${host_alias}'${NC}"
    fi
}

echo "Checking SSH config entries..."

# Use ~ in the config so it's portable across usernames
KEY_CONFIG_PATH="~/Documents/Warp Personal/vaxlan/.ssh-keys/id_ed25519_vaxlan"

add_host_if_missing "ha" "Host ha
    HostName 10.0.30.11
    User root
    IdentityFile \"$KEY_CONFIG_PATH\"
    AddKeysToAgent yes
    UseKeychain yes"

add_host_if_missing "vaxlan-router" "Host vaxlan-router
    HostName 10.0.20.1
    User admin
    IdentityFile \"$KEY_CONFIG_PATH\"
    AddKeysToAgent yes
    UseKeychain yes"

add_host_if_missing "nas" "Host nas
    HostName 10.0.30.10
    User vaxocentric
    IdentityFile \"$KEY_CONFIG_PATH\"
    AddKeysToAgent yes
    UseKeychain yes"

# Add key to macOS Keychain
echo ""
echo "Adding key to macOS Keychain..."
if ssh-add -l 2>/dev/null | grep -q "vaxlan-infra"; then
    echo -e "${YELLOW}  Key already loaded in agent${NC}"
else
    ssh-add --apple-use-keychain "$KEY_PATH"
    echo -e "${GREEN}  Key added to Keychain${NC}"
fi

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo "Test with:"
echo "  ssh ha 'echo OK'"
echo "  ssh vaxlan-router '/system identity print'"
echo "  ssh nas 'hostname'"
