# AGENTS.md — vaxlan project rules

Warp-native project rules file. These rules apply to any agent session working inside the `vaxlan` repository. Broader personal rules and the full bootstrap live at `_init.md`; this file is the short, policy-oriented contract.

## Scope of this repo
Home infrastructure configuration and automation: MikroTik router, Home Assistant, Synology NAS, and the AWS S3 backup pipeline. All changes must favour safety and rollback capability over speed.

## SSH host aliases (`~/.ssh/config`)
Always use aliases. Never hardcode IPs in new scripts.
- `vaxlan-router` → MikroTik RB5009 (`admin@10.0.20.1`)
- `ha` → Home Assistant (`root@10.0.30.11`)
- `nas` → Synology NAS (`vaxocentric@10.0.30.10`)

If any alias fails on a new device, run `bash homeassistant/scripts/setup-ssh.sh`.

## Infrastructure Change Standard (MANDATORY)
The authoritative version lives in `_init.md` §"Infrastructure Change Standard (Mandatory)". Summary of the non-negotiable gates:

1. **Per-system, per-task**. If a task touches router + HA + NAS, run the full pre-change / post-change cycle once for each system. Do not batch.
2. **Visible backup handshake**. Before editing ANY file on a target system, print the exact backup command to the user and execute it. Do not proceed to edits until the backup succeeds.
3. **Hard stop**. Only after SSH connectivity, backup, and config capture all succeed for that system, proceed to edits.
4. **Post-change validation**. Router: check for invalid rules. HA: `ha core check`. S3: verify via list or CloudWatch.
5. **Doc writeback**. Same session. See `_init.md` §"Required Documentation Writeback".

## S3 / AWS rules
- CLI profile: `vaxocentric` (account `823704761294`, region `us-east-1`).
- Never run destructive S3 commands (`rm`, `rb`, `delete-object*`, `abort-multipart-upload` in bulk) without:
  1. Capturing the full list of targets to `synology/backup/logs/s3-cleanup-<date>/` as JSON first.
  2. Printing counts and sampling 3+ entries to the user.
  3. Explicit user confirmation to proceed.
- Lifecycle edits are allowed without a manual backup (S3 versions the policy internally), but print the new policy JSON before applying.

## Script discipline
- All new scripts must use SSH key auth (never `sshpass`, never hardcoded passwords).
- Register every new script in `SCRIPTS.md` with purpose, creation date, usage, prerequisites.
- Scripts must be idempotent where practical.

## Git / GitHub discipline
- Remote: `github.com/titaniumindustries/vaxlan.git` (private).
- After any completed Infrastructure Change Standard cycle, commit the writeback and push.
- Commit messages: imperative, subject ≤72 chars, body wraps at 72. Include `Co-Authored-By: Oz <oz-agent@warp.dev>` on agent-authored commits.
- Never commit: `.ssh-keys/**`, `**/secrets.yaml`, `**/*.hbk/**`, `**/ha-backup/**`, credential material, raw router `.backup` files. See `.gitignore`.

## Device awareness
Always check which device the session is running on before making local-path assumptions:
```bash
scutil --get ComputerName
```
Parity gaps between Mac Mini and MacBook Air are tracked in `/Users/titanium/Documents/DEVICE_DEPS.md`. If a tool is missing, offer the install command; do not auto-install.

## VPN gotcha
If a local device SSH (`ha`, `vaxlan-router`, `nas`) fails unexpectedly, check the home privacy VPN first. It can route local traffic out and break LAN access. See `_init.md` §"Troubleshooting".

## Out of scope by default
- Home Assistant is out of scope for router-only tasks. If asked to touch HA, confirm the intent first.
- Plex / media library content is off-limits unless explicitly requested (Media S3 bucket is fair game for admin/cost work).
- Work projects under `_PEARL/` are separate context; do not cross-reference.

## When in doubt
Stop and ask. NAS is the most critical infrastructure component; unintentional data loss is the single worst outcome for this project.
