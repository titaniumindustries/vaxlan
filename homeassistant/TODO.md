# Home Assistant TODO

## Z-Wave: Factory Reset & Re-Include Dead Nodes
**Date added:** 2026-02-22

Nodes 6, 7, 8, 9, 10 show as "dead" in Z-Wave JS. They are stale entries on the Zooz ZST39 stick from a prior HA instance that crashed. They need to be factory reset and re-included.

**Known devices (unmapped to node numbers):**
- 2× Garage tilt sensors (different models; one is Ecolink TILT-ZWAVE2.5-ECO on Node 11, the other is unknown)
- 2× Temperature/motion/humidity sensors (wired/powered mode)
- 1× Wired smart switch
- 1× Wired smart plug
- 1× Battery-powered thermostat (possibly Node 5, shows "asleep")

**Steps for each device:**
1. Physically locate the device and note brand/model from label
2. Look up factory reset procedure in device manual
3. Factory reset the device
4. In HA: Settings → Devices & Services → Z-Wave JS → Configure → Add Device
5. Trigger inclusion on the device (usually single button press)
6. Verify the device appears in HA with correct entity names

**After all devices are re-included:**
- Remove any remaining stale dead nodes from the Z-Wave network
- Update `docs/zwave-keys.md` with the device inventory

**Notes:**
- Node 11 (Ecolink garage tilt sensor) is working — shows "asleep" (normal for battery device)
- Node 5 is also "asleep" — likely the battery-powered thermostat
- Security keys are documented in `docs/zwave-keys.md`
- The current HA instance uses auto-generated keys (not the old keys from the prior instance)
- Old keys were tested and did not help — the issue is RF/physical, not encryption

## Home Assistant Task Backlog (Requested 2026-04-11)
**Date added:** 2026-04-11

### New tasks (not previously tracked)
1. ~~Implement a simple, secure, and reliable way for agent SSH access into Home Assistant.~~ ✅ Done 2026-04-14. ed25519 key in `.ssh-keys/`, `ssh ha` alias, macOS Keychain, setup script.
2. ~~Create automation to turn off the back door light at midnight.~~ ✅ Done 2026-04-14. See `automations/back-door-light-midnight-off.yaml`.
3. Fix Kasa outlet controls.
4. ~~Create automation to turn on porch speakers every day at 8:00 AM, then turn them off 1 minute later.~~ ✅ Done 2026-04-14. See `automations/porch-speakers-morning-wake.yaml`.
5. ~~Create automation to turn off the WiiM if porch speakers turn off and the WiiM is on.~~ ✅ Done 2026-04-14. See `automations/wiim-off-when-speakers-off.yaml`.
6. ~~Create automation to fade the living room lamp to warm white over 10 minutes, starting 45 minutes before sunset.~~ ✅ Done 2026-04-16. See `automations/living-room-lamp-sunset-fade.yaml`. Entity renamed from `light.den_floor_lamp` to `light.living_room_table_lamp`.
7. Create automation to turn off the Den TV (the TV itself, not the smart plug) when it has not been playing content for 10 minutes. **Blocked:** No Roku integration configured — only `media_player.chromecast_den_tv` (Cast) exists, which doesn't reflect native Roku app activity. **Next step:** Add Roku integration (Settings → Integrations → Add → Roku → IP `10.0.40.60`) to get a proper `media_player` with playing/idle/standby states.

## Completed

### KMC Outlets: Fix Daily Energy Totals
**Date added:** 2026-03-25 | **Completed:** 2026-04-14

**Problem**: KMC Smart Tap outlets (Tasmota-Outlet-01 through 07) reset daily energy totals at 7 PM Eastern instead of midnight.
**Root cause**: Tasmota devices default to UTC. Midnight UTC = 7 PM EST.
**Fix**: Applied US Eastern timezone rules via MQTT group topic. Script preserved at `scripts/tasmota-set-timezone.sh` (see `SCRIPTS.md` registry).
**Lesson learned**: Always set `Timezone 99` + `TimeDST`/`TimeSTD` on new Tasmota devices immediately after flashing.

**Remaining optional tuning** (not blocking):
- `TelePeriod` (default 300s) — reduce to 60s for more frequent updates
- `PowerDelta` (default 0/disabled) — set to 10 for immediate reports on 10% power change
- HLW8012 calibration — verify with a known load using `PowerSet`, `VoltageSet`, `CurrentSet`

### Already tracked (no duplicate created)
- Get the Z-Wave motion sensors working — covered by **Z-Wave: Factory Reset & Re-Include Dead Nodes**.
- Reconnect to the Z-Wave thermostat — covered by **Z-Wave: Factory Reset & Re-Include Dead Nodes**.
- Reconnect to the Z-Wave porch switch — covered by **Z-Wave: Factory Reset & Re-Include Dead Nodes**.
