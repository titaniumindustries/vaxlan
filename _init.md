# vaxlan `_init.md`

## Project
- Name: vaxlan
- Scope: personal
- Root path: `/Users/titanium/Documents/Warp Personal/vaxlan`
- Primary objective: manage home network/router changes safely with consistent validation and documentation.

## Fast Start
- Typical tasks:
  - router firewall/DHCP/VLAN changes
  - static lease updates
  - network diagnostics and validation
- Success criteria:
  - secure router connection succeeds on first attempt
  - pre/post validation is completed
  - docs are updated in the same session

## Routing Metadata
- Canonical name: `vaxlan`
- Aliases: `vaxlan`, `home network`, `router`, `mikrotik`, `dhcp`, `static lease`
- Intent keywords: `router`, `firewall`, `vlan`, `dhcp`, `static ip`, `capsman`
- Related projects: `Local Network Tools`, `homeassistant`

## Context Loading Rules
- Read this file first for vaxlan tasks.
- Router-only tasks: prioritize `network/README.md`, `network/docs/ARCHITECTURE.md`, and `network/docs/configuration-validation-checklist.md`.
- Home Assistant is out of scope unless explicitly requested.
- Parent context boundary: `/Users/titanium/Documents/_init.md`.

## Infrastructure Change Standard (Mandatory)
Applies to ALL substantive configuration changes across router, Home Assistant, and NAS. Never skip steps.
**Each target system requires its own independent pass through this checklist.** If a single task touches multiple systems (e.g., router + HA), run the full before/after cycle separately for each. Do not batch.

### Access
1. Use SSH keys only. Do not use plaintext passwords in commands, scripts, or docs.
2. Use SSH host aliases: `vaxlan-router` (router), `ha` (Home Assistant), `nas` (Synology NAS). Never hardcode IPs in new scripts.
3. If secrets are needed, load them into environment variables first; never inline them in commands.

### Before making changes (per target system — mandatory visible gate)
1. Verify SSH connectivity to the target system.
2. **Print the backup command you are about to run to the user.** Do not proceed until the backup command is shown and executed successfully.
3. **Run the appropriate backup** — changes must be rollback-capable:
   - **Router**: `TIMESTAMP=$(date +%Y%m%d-%H%M%S) && ssh vaxlan-router "/export file=export-$TIMESTAMP"`
   - **Home Assistant**: `bash homeassistant/scripts/backup-ha.sh`
   - **NAS**: use Synology Hyper Backup or manual export as appropriate.
4. Capture current config state (print/export relevant sections).
5. **Only after steps 1–4 succeed for this system, proceed to edits.**

### After making changes (per target system)
1. Run validation checks (router: check for invalid rules; HA: `ha core check`).
2. Update documentation files listed below.

## Required Documentation Writeback (Infrastructure Changes)
- DHCP/static lease changes → `network/docs/static-ip-assignments.md` (+ snapshot date)
- Firewall changes → `network/docs/firewall-rules.md`
- Architecture/topology changes → `network/docs/ARCHITECTURE.md`
- Always review `network/docs/configuration-validation-checklist.md`

## Device Context
- MacBook Air M4 15" (Black): `Jonathan Pearl MacBook Air M4 15 Black` — primary portable
- Mac Mini: shares `~/Documents/` via Synology Drive — always check which device you're on before SSH or local-path assumptions.
- To detect current device: `scutil --get ComputerName`

### Troubleshooting: SSH or local device connections failing
1. **Check VPN status first.** A home VPN is used for privacy; when active, it can prevent access to local devices (router, HA, NAS). Disconnect VPN before retrying.
2. **SSH not working?** If `ssh ha` or `ssh vaxlan-router` fails after VPN is off, the most likely cause is a missing `~/.ssh/config` on this device. Run `bash homeassistant/scripts/setup-ssh.sh` to configure host aliases and load the Synology Drive-synced key into macOS Keychain. The private key itself syncs via Synology Drive in `.ssh-keys/` — only the SSH config and Keychain entry are per-machine.

## Change Log
- 2026-04-16: hardened Infrastructure Change Standard — per-system backup gate with visible handshake, added `nas` SSH alias, fixed iCloud→Synology Drive references.
- 2026-04-16: added SSH/connectivity troubleshooting block (VPN check + setup-ssh.sh) to Device Context.
- 2026-04-14: broadened "Router Access Standard" to "Infrastructure Change Standard" covering HA/NAS/router with mandatory pre-change backup requirement.
- 2026-04-14: added SSH key infrastructure (ed25519, iCloud-synced, macOS Keychain), setup-ssh.sh, device context section, SCRIPTS.md registry.
- 2026-04-04: initialized vaxlan bootstrap with key-based router access standard and mandatory writeback rules.
