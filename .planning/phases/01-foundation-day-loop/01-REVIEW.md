---
phase: 01-foundation-day-loop
reviewed: 2026-09-29T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - .github/workflows/ci.yml
  - presentation/buildings/building_views.gd
  - simulation/buildings/building_system.gd
  - simulation/defs/map_config.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_map_binding.gd
  - tests/unit/test_building_view_catalog.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - tests/unit/test_prototype_map_data.gd
  - tools/screenshot.sh
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-29
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Reviewed the recent hardening pass (null-entry skipping, payout/HUD lag reconciliation, provider-return validation, CI/screenshot diagnostics) plus the tests around it. No blockers: the payout arithmetic (`_coins_for_amount`, `_coin_share`, `launch_stagger`, HUD `carried` clamp) checks out for zero, single-spot and many-spot payouts, and the shell script's shot names are whitelisted before they reach `rm -f`. The remaining problems are all the same class the hardening targeted: the fixes cover one malformed-data case while the adjacent case still crashes or desyncs.

## Warnings

### WR-01: Unknown spot id in `per_spot` crashes coin launch and strands the HUD readout

**File:** `ui/hud/dawn_payout_vfx.gd:191`
**Issue:** `_start_point` does `_ctx.buildings.get_spot(spot_id).position`. `get_spot` returns null for an unknown id, so this is a null dereference at launch time. `_on_dawn_payout` has already incremented `_expected_coins` for that spot and `Hud._on_dawn_payout` has already counted its amount in `_payout_pending`. The coin never lands, `_show_total` never fires, and the HUD readout stays short by that gold until the next payout. This is exactly the "readout short for good" failure the latest change to `hud.gd` and the `_expected_coins == 0` branch set out to remove, but only for the empty-dict case.
**Fix:**
```gdscript
func _start_point(spot_id: StringName) -> Vector2:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var spot: BuildSpotDef = _ctx.buildings.get_spot(spot_id)
	if camera == null or spot == null:
		return get_viewport_rect().size * 0.5
	return camera.unproject_position(spot.position + SPOT_ANCHOR)
```

### WR-02: BuildingSystem null-skip hardening leaves duplicate ids and unknown building ids unhandled

**File:** `simulation/buildings/building_system.gd:20-24, 81`
**Issue:** The new null skip says data errors are "already reported by validate()" so the system should not crash, but two other errors `validate()` reports still corrupt state. (1) A duplicate spot id is appended to `_order` twice (line 23) while `_spots` keeps only the last def. `spot_ids()` then yields the id twice, so `BuildingViews.bind_run` creates two `Spot_<id>` markers, one carrying the wrong colour if the building ids differ. (2) `dawn_income_by_spot` hard-indexes `_defs[instance.building_id]` (line 81), which errors on a spot whose building id is unknown. `CommandProcessor` rejects the build in the normal path, but nothing enforces that here.
**Fix:**
```gdscript
for spot: BuildSpotDef in map.spots:
	if spot == null or _spots.has(spot.id):
		continue
	_order.append(spot.id)
	_spots[spot.id] = spot
...
var building_def: BuildingDef = _defs.get(instance.building_id) as BuildingDef
if building_def == null:
	continue
var tier_def: BuildingTierDef = building_def.tier_def(instance.tier)
```

### WR-03: Debug overlay only validates the top-level provider return, not the row shape

**File:** `ui/overlay/debug_overlay_model.gd:35-37` (consumer at `ui/overlay/debug_overlay.gd:54`)
**Issue:** The change skips a provider that returns a non-Array, but `collect` still passes any Array through. The overlay then does `row[0]` / `row[1]` on every row. A provider returning `["Wave", "3"]` (a flat pair), rows with fewer than two entries, or a non-Array row raises a script error on every refresh. That is the same "crashes every refresh" outcome the surrounding comment says to avoid, and the contract in the doc comment (Array of `[String, String]`) is unenforced. The test only covers null and String returns.
**Fix:** Normalise rows in `collect`:
```gdscript
var clean: Array = []
for row: Variant in rows:
	if row is Array and row.size() >= 2:
		clean.append([str(row[0]), str(row[1])])
sections.append(_section(entry["title"], clean))
```
and add a test for a malformed row.

## Info

### IN-01: `Hud.bind_run` is only partly idempotent

**File:** `ui/hud/hud.gd:24-41`
**Issue:** The comment justifies guarding `coin_landed` against a second `bind_run`, but every other `connect` in the method (hold signals, all `ctx.events` signals, `progress_changed`) is unguarded, and a second call would emit connect errors for those. The guard is inconsistent: either `bind_run` is called once (guard unneeded) or it is not (most connections are unprotected).
**Fix:** Drop the guard and document single-call, or early-return with `if _ctx != null: return`.

### IN-02: Player-facing strings hard-code the key hint and a placeholder

**File:** `ui/hud/hud.gd:105, 112`
**Issue:** "Hold N / (Y)" ignores runtime rebinding, which the project constraints require. "Night %d — no enemies yet" is Phase-1 placeholder copy that will ship stale once waves exist.
**Fix:** Build the hint from `InputMap.action_get_events` for the start-night action, and move both strings to constants that Phase 2 replaces.

### IN-03: Read-only test watches only 4 of 7 simulation signals

**File:** `tests/unit/test_debug_overlay_readonly.gd:8-10`
**Issue:** `SIM_SIGNALS` omits `night_started`, `day_started` and `dawn_payout`, so "emits no events" is only partly asserted. A provider or model change that starts a night would not be caught by the signal check (only by the phase check).
**Fix:** Add the three missing signal names, or enumerate them from `ctx.events.get_signal_list()`.

### IN-04: Timing-sensitive e2e assertions and CI trigger overlap

**File:** `tests/e2e/test_dawn_payout.gd:105, 231`; `.github/workflows/ci.yml:9-13`
**Issue:** (a) `test_a_real_payout_lands_every_coin_inside_a_short_dawn_window` designs the last coin to land at exactly `dawn_seconds` (1.0 s) and waits only `LAND_SLACK_S = 0.2` of real time; tween delays are frame-quantised, so a slow llvmpipe/CI runner can flake it. The early-dawn lag test likewise relies on `wait_seconds(0.25)` being shorter than one 0.6 s trip. (b) Push to `gsd/**` plus `pull_request` means a phase branch with an open PR builds twice (the header comment says feature branches are not built twice, which holds only for non-`gsd/` branches). Also `launch_stagger` (`dawn_payout_vfx.gd:72`) dereferences `_ctx` and would crash if called before `bind_run`.
**Fix:** (a) Widen the slack to about 0.5 s or drive the check off the `coin_landed` signal via `wait_for_signal`; (b) correct the comment, or add a `pull_request`-exists guard; guard `_ctx` in `launch_stagger`.

---

_Reviewed: 2026-09-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
