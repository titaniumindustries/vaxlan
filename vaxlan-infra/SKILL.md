---
name: vaxlan-infra
description: >
  MikroTik RouterOS, Synology NAS, and Home Assistant infrastructure management for the vaxlan
  home network. Use this skill when working with: MikroTik router or AP configuration (RouterOS 7
  on RB5009, RouterOS 6 on cAP ac APs), firewall rules, DHCP, VLANs, CAPsMAN wireless, Synology
  DSM CLI, Home Assistant CLI/config, or any network infrastructure changes in the vaxlan repo.
  Provides correct CLI syntax, SSH connection patterns, and mandatory change workflows.
---

# vaxlan Infrastructure Management

## Device Access

### MikroTik RB5009 Router (RouterOS 7.19.6)
```
ssh vaxlan-router '<COMMAND>'
```
- Single-quote the RouterOS command to prevent shell interpolation
- Chain commands with ` ; ` inside quotes
- Escape inner double quotes: `\"value\"`
- Use SSH key auth only; do not use inline passwords or `sshpass`.

### MikroTik cAP ac APs (RouterOS 6.48.6)
```
ssh admin@<AP_IP> '<COMMAND>'
```
- Upstairs Office: 10.0.10.11 | Den: 10.0.10.12 | Master Bedroom: 10.0.10.13
- RouterOS 6 syntax differs from 7 — see [references/routeros6.md](references/routeros6.md)

### Synology NAS (DSM 7) — 10.0.30.10
```
ssh titanium@10.0.30.10
```
See [references/synology.md](references/synology.md)

### Home Assistant (HAOS) — 10.0.30.11
```
ssh ha
```
Auth: SSH key (`.ssh-keys/id_ed25519_vaxlan`, iCloud-synced). See [references/homeassistant.md](references/homeassistant.md)

## Mandatory Change Workflow

Follow for ALL infrastructure changes (router, HA, NAS). Never skip steps.

### 1. Backup
Run the appropriate backup BEFORE any changes. Changes must be rollback-capable.

**Router:**
```
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ssh vaxlan-router \"/export file=export-$TIMESTAMP\"
```

**Home Assistant:**
```
bash homeassistant/scripts/backup-ha.sh
```

### 2. Verify current state
Print relevant config BEFORE changes:
```
/ip firewall filter print where chain=forward and comment~"IoT"
```

### 3. Make changes
Apply using correct syntax from reference docs.

### 4. Verify new state
Print same config AFTER changes. Confirm:
- No `I` (invalid) flags: `/ip firewall filter print where invalid`
- Correct rule order (allow before drop)
- Expected values present

### 5. Update documentation
After ANY router change, update corresponding files in `vaxlan` repo:
- **DHCP** → `network/docs/static-ip-assignments.md` (+ snapshot date)
- **Firewall** → `network/docs/firewall-rules.md` (rules table + change log)
- **VLAN/bridge** → `network/docs/ARCHITECTURE.md` (recent changes)
- **Wireless** → `network/docs/wireless-channel-config.md`
- **Hardware** → `network/docs/hardware-software-inventory.md`

## Mandatory Rules

### Static IPs before firewall rules
- NEVER create a device-specific firewall rule referencing a dynamic IP
- ALWAYS create a static DHCP reservation FIRST, then the firewall rule
- Static reservations: .10–.99 range; dynamic pool: .100–.250

### When changing a static IP, update ALL:
1. Router DHCP lease
2. Firewall rules: `/ip firewall filter print where src-address~"OLD" or dst-address~"OLD"`
3. Address lists: `/ip firewall address-list print where address="OLD"`
4. `static-ip-assignments.md`
5. `firewall-rules.md`

### When moving a device to a restricted VLAN
Audit service dependencies BEFORE the move. Create firewall exceptions AT THE SAME TIME.

### Firewall rule placement
- Allow rules BEFORE drop rules for the same source
- Use `place-before=<RULE_ID>` to insert before a drop rule
- After placement, verify order; use `move SRC destination=TGT` to reposition
- Prefer `src-address`/`dst-address` over `in-interface`/`out-interface` for inter-VLAN rules

## RouterOS 7 Quick Reference

See [references/routeros7.md](references/routeros7.md) for complete syntax.

Most common operations:
```
# Firewall: add rule before a drop rule
/ip firewall filter add chain=forward action=accept protocol=tcp \
  src-address=10.0.40.X dst-address=10.0.30.10 dst-port=PORT \
  comment="Description" place-before=RULE_ID

# Firewall: move a misplaced rule
/ip firewall filter move SOURCE destination=TARGET

# DHCP: add static lease
/ip dhcp-server lease add address=IP mac-address=MAC server=SERVER comment="Description"

# DHCP: remove dynamic lease to force renewal
/ip dhcp-server lease remove [find where dynamic=yes and mac-address=MAC]

# Address list: add entry
/ip firewall address-list add list=LIST address=IP comment="Description"

# CAPsMAN: check registered wireless clients
/caps-man registration-table print

# Export full config
/export file=export-YYYYMMDD
```

## Key Pitfalls
- DNS/DHCP INPUT rules for IoT/Guest/CCTV MUST precede their management block rules
- LIFX needs bidirectional UDP 56700 (outbound control + inbound response)
- CAPsMAN on RouterOS 7 requires `wireless` package for cAP ac compatibility
- AP SSIDs are managed via CAPsMAN — never configure SSIDs directly on APs
- `find` uses `where` for filtering: `[find where name="X"]`
- Chain SSH commands with ` ; ` (space-semicolon-space)
- RouterOS does NOT support `&&` or `||` — only ` ; ` for command chaining
