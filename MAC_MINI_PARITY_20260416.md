# Mac Mini Parity Checklist — 2026-04-16

**Purpose**: apply the changes made on the MacBook Air today to the Mac Mini so both devices can drive vaxlan infrastructure work equivalently. This file can be deleted after both devices are confirmed in parity.

## What changed on 2026-04-16 (Air)
1. New SSH host alias: `nas` → `vaxocentric@10.0.30.10` (Synology NAS).
2. AWS CLI `vaxocentric` profile configured (was previously Air-missing).
3. Infrastructure Change Standard hardened in `_init.md` (per-system backup gate).
4. `setup-ssh.sh` updated to include the `nas` alias.
5. `AGENTS.md` added to this repo for Warp-native project rules.

The first two are **per-device** (not synced). The rest travel through the repo / Synology Drive.

## Run on the Mac Mini

### Step 1: Confirm identity and current state
```zsh
scutil --get ComputerName
sw_vers -productVersion
aws configure list-profiles
grep -E '^Host ' ~/.ssh/config
```

Expected before changes: you should see `default` and `vaxocentric` AWS profiles (the Mac Mini already had `vaxocentric`), and only `ha` + `vaxlan-router` SSH aliases.

### Step 2: Add the `nas` SSH alias
The repo is synced via Synology Drive so `setup-ssh.sh` will have the new `nas` block. Just re-run it:

```zsh
bash "/Users/titanium/Documents/Warp Personal/vaxlan/homeassistant/scripts/setup-ssh.sh"
```

The script is idempotent — it will skip `ha` and `vaxlan-router` (already present) and add only `nas`.

### Step 3: Verify SSH to NAS
The public key was installed on the NAS from the Air, but since the private key is the same (`id_ed25519_vaxlan` in Synology Drive), the Mini should authenticate with no extra work:

```zsh
ssh nas "hostname && uname -a"
```

Expected: `synology` / `Linux synology 4.4.302+ ... x86_64 GNU/Linux synology_geminilake_224+`.

If it fails with "permission denied (publickey,password)":
- The key didn't sync, or Keychain hasn't loaded it yet. Run `ssh-add --apple-use-keychain "~/Documents/Warp Personal/vaxlan/.ssh-keys/id_ed25519_vaxlan"` and retry.

### Step 4: Verify AWS profile
```zsh
aws sts get-caller-identity --profile vaxocentric
```

Expected: `"Arn": "arn:aws:iam::823704761294:user/vaxocentric"`.

### Step 5: Verify the updated storage report script runs
```zsh
bash "/Users/titanium/Documents/Warp Personal/vaxlan/synology/backup/scripts/get_aws_storage_report.sh" 3
```

Expected: output now shows Personal bucket broken into `IntelligentTieringFAStorage`, `IntelligentTieringIAStorage`, `IntelligentTieringAIAStorage` (the dominant tier, ~1,681 GB).

### Step 6: Update `DEVICE_DEPS.md` Mac Mini section
The Mac Mini's entry in `/Users/titanium/Documents/DEVICE_DEPS.md` is from 2026-04-16T04:46Z. Add a note confirming `nas` alias works and that parity is achieved. Suggested addition under "MacMiniM4-Jonathan":

```markdown
### SSH host aliases (`~/.ssh/config`) — last verified YYYY-MM-DD
- `ha` → 10.0.30.11
- `vaxlan-router` → 10.0.20.1
- `nas` → 10.0.30.10 (added 2026-04-16 via setup-ssh.sh)
```

## Delete this file when done
Once steps 2–5 pass on the Mac Mini and DEVICE_DEPS.md is updated, `rm MAC_MINI_PARITY_20260416.md` and commit the removal.
