# Synology NAS CLI Reference (DS224+, DSM 7)

## Connection

```
ssh titanium@10.0.30.10
```

Most admin commands require `sudo`. DSM 7 uses its own package/service management layer.

## System Info

```
# DSM version
cat /etc/VERSION

# Hostname
hostname

# Uptime
uptime

# Disk usage
df -h

# Volume status
cat /proc/mdstat

# CPU / memory
free -m
top -bn1

# Network interfaces
ifconfig
ip addr show
```

## Storage & Volumes

```
# List shared folders
ls /volume1/

# Disk health (SMART)
sudo smartctl -a /dev/sda
sudo smartctl -a /dev/sdb

# RAID status
sudo mdadm --detail /dev/md2

# Volume usage
du -sh /volume1/*
```

## Package & Service Management

```
# List installed packages
synopkg list --name

# Package status
synopkg status PACKAGE_NAME

# Start/stop/restart a package
sudo synopkg start PACKAGE_NAME
sudo synopkg stop PACKAGE_NAME
sudo synopkg restart PACKAGE_NAME

# Common package names:
#   Plex Media Server   → PlexMediaServer
#   Hyper Backup        → HyperBackup
#   Cloud Sync          → CloudSync
#   Surveillance Station → SurveillanceStation
#   Docker              → Docker (ContainerManager in DSM 7.2+)
```

## Plex Media Server

```
# Plex service control
sudo synopkg restart PlexMediaServer
sudo synopkg status PlexMediaServer

# Plex data location (typical)
ls /volume1/PlexMediaServer/

# Plex logs
ls /volume1/PlexMediaServer/AppData/Plex\ Media\ Server/Logs/

# Test Plex HTTP API (from NAS or another device)
curl -s http://10.0.30.10:32400/identity

# Check Plex port listening
sudo netstat -tlnp | grep 32400
```

## Docker / Container Manager

```
# List running containers
sudo docker ps

# List all containers
sudo docker ps -a

# Container logs
sudo docker logs CONTAINER_NAME

# Start/stop container
sudo docker start CONTAINER_NAME
sudo docker stop CONTAINER_NAME

# Docker compose (if used)
sudo docker-compose -f /path/to/compose.yml up -d
```

## Network

```
# Show IP config
ip addr show

# Show routes
ip route show

# DNS config
cat /etc/resolv.conf

# Test connectivity
ping -c 3 10.0.30.1    # Gateway
ping -c 3 8.8.8.8      # Internet
nslookup google.com     # DNS

# Show listening ports
sudo netstat -tlnp

# Show active connections
sudo netstat -tnp
```

## File Operations

```
# Shared folder paths (typical)
/volume1/homes/          # User home directories
/volume1/media/          # Media files
/volume1/backups/        # Backup destination
/volume1/surveillance/   # Surveillance recordings

# Permissions
ls -la /volume1/FOLDER/
sudo chown -R USER:GROUP /volume1/FOLDER/
sudo chmod -R 755 /volume1/FOLDER/
```

## Backup (Hyper Backup)

```
# Hyper Backup CLI
sudo synopkg status HyperBackup

# List backup tasks (via synobackup)
sudo /usr/syno/bin/synobackup --list

# AWS S3 buckets (see synology/backup/ docs):
#   vaxlan-synology-personal (Intelligent-Tiering)
#   vaxlan-synology-media (Deep Archive)
#   vaxlan-synology-surveillance (lifecycle tiered)
```

## Logs

```
# System log
cat /var/log/messages

# DSM log
cat /var/log/synolog/synobackup.log

# Auth log
cat /var/log/auth.log
```

## Useful Paths

- DSM config: `/etc/synoinfo.conf`
- Network config: `/etc/sysconfig/network-scripts/`
- Scheduled tasks: DSM Control Panel → Task Scheduler (no direct CLI equivalent)
- SSL certs: `/usr/syno/etc/certificate/`
