#!/bin/bash
# Home Assistant Backup Script
# Downloads configuration and full backup from Home Assistant to local storage
#
# Updated: 2026-04-14 — Use 'ha' SSH host alias instead of hardcoded root@10.0.30.11.
#   Requires ~/.ssh/config (run setup-ssh.sh on a new Mac).

set -e

# Configuration — uses SSH host alias 'ha' from ~/.ssh/config
HA_HOST="ha"
BACKUP_BASE_DIR="$(dirname "$0")/../backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/${TIMESTAMP}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Home Assistant Backup ===${NC}"
echo "Timestamp: ${TIMESTAMP}"
echo "Backup directory: ${BACKUP_DIR}"
echo ""

# Create backup directory
mkdir -p "${BACKUP_DIR}/config"
mkdir -p "${BACKUP_DIR}/storage"
mkdir -p "${BACKUP_DIR}/esphome"
mkdir -p "${BACKUP_DIR}/ha-backup"

# 1. Backup YAML configuration files
echo -e "${YELLOW}[1/5] Backing up configuration files...${NC}"
scp ${HA_HOST}:/config/*.yaml "${BACKUP_DIR}/config/" 2>/dev/null || true
echo "  - YAML files copied"

# 2. Backup .storage directory (integrations, registries, etc.)
echo -e "${YELLOW}[2/5] Backing up .storage directory...${NC}"
scp -r ${HA_HOST}:/config/.storage/* "${BACKUP_DIR}/storage/" 2>/dev/null || true
echo "  - Storage files copied"

# 3. Backup ESPHome configurations
echo -e "${YELLOW}[3/5] Backing up ESPHome configs...${NC}"
scp -r ${HA_HOST}:/config/esphome/* "${BACKUP_DIR}/esphome/" 2>/dev/null || true
echo "  - ESPHome configs copied"

# 4. Backup blueprints (if any custom ones exist)
echo -e "${YELLOW}[4/5] Backing up blueprints...${NC}"
if ssh ${HA_HOST} "test -d /config/blueprints" 2>/dev/null; then
    mkdir -p "${BACKUP_DIR}/blueprints"
    scp -r ${HA_HOST}:/config/blueprints/* "${BACKUP_DIR}/blueprints/" 2>/dev/null || true
    echo "  - Blueprints copied"
else
    echo "  - No blueprints found"
fi

# 5. Download the latest HA full backup (.tar file)
echo -e "${YELLOW}[5/5] Downloading latest Home Assistant full backup...${NC}"
LATEST_BACKUP=$(ssh ${HA_HOST} "ls -t /backup/*.tar 2>/dev/null | head -1")
if [ -n "${LATEST_BACKUP}" ]; then
    BACKUP_FILENAME=$(basename "${LATEST_BACKUP}")
    scp "${HA_HOST}:${LATEST_BACKUP}" "${BACKUP_DIR}/ha-backup/${BACKUP_FILENAME}"
    echo "  - Downloaded: ${BACKUP_FILENAME}"
else
    echo -e "${RED}  - No HA backup found. Consider creating one in HA UI first.${NC}"
fi

# Create backup manifest
echo -e "${YELLOW}Creating backup manifest...${NC}"
cat > "${BACKUP_DIR}/manifest.txt" << EOF
Home Assistant Backup Manifest
==============================
Timestamp: ${TIMESTAMP}
Date: $(date)
HA Host: ${HA_HOST}

Contents:
- config/        : YAML configuration files
- storage/       : Integration and registry data
- esphome/       : ESPHome device configurations
- blueprints/    : Automation blueprints
- ha-backup/     : Full Home Assistant backup (.tar)

Files backed up:
$(find "${BACKUP_DIR}" -type f | sort)
EOF

# Calculate backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)

echo ""
echo -e "${GREEN}=== Backup Complete ===${NC}"
echo "Location: ${BACKUP_DIR}"
echo "Size: ${BACKUP_SIZE}"
echo ""
echo "Backup manifest saved to: ${BACKUP_DIR}/manifest.txt"
