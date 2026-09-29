---
phase: 01-foundation-day-loop
reviewed: 2026-09-29T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - simulation/buildings/building_system.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_map_binding.gd
  - tests/e2e/test_start_night_hold.gd
  - tests/unit/test_building_system_data_errors.gd
  - tests/unit/test_building_system_data_errors.gd.uid
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-29
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed the building system, the dawn payout VFX, the HUD, the debug overlay model and their unit and e2e tests. I cross-checked `RunContext`, `MapRoot`, `MapConfig.validate`, `BuildingDef.tier_def`, `E2eSupport` and `loop_tuning.tres`.

No crashes, data-loss or security defects were found. The coin/lag accounting holds up:
- Coin shares sum to each spot's amount.
- The HUD lag is capped by what coins can carry.
- Stale generations are ignored.

The remaining problems are latent bugs and test reliability:
- An unguarded second bind on the VFX node.
- A prompt hint that does not follow rebinds.
- A wall-clock assertion, which is the same class of timing race the IN-04 fix set out to remove.
- Some inconsistent duplicate-handling in `BuildingSystem`.

## Warnings

### WR-01: DawnPayoutVfx.bind_run is not idempotent, and the "bind again" test does not cover it

**File:** `ui/hud/dawn_payout_vfx.gd:44-47`, `tests/e2e/test_map_binding.gd:73-86`
**Issue:**
- `Hud.bind_run` returns early on a repeat call ("so no signal is ever connected twice").
- `DawnPayoutVfx.bind_run` has no such guard. A second call runs `ctx.events.dawn_payout.connect(_on_dawn_payout)` again, which raises Godot's "already connected" error. It also rebuilds the coin texture.
- `test_binding_the_hud_again_connects_nothing_twice` only calls `hud.bind_run(...)`. That returns on its first line and never reaches the VFX node. The test asserts unchanged connection counts, but it exercises only the HUD guard.
- `payout_vfx.coin_landed.get_connections()` is unaffected by any `bind_run` call, so that assertion can never fail.
- `MapRoot._ready` binds every `run_bound` node in its subtree, and `DawnPayoutVfx` is such a node. Any re-bind path (a future scene reload or a second `_ready`) breaks it.

**Fix:**
```gdscript
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_coin_texture = _make_coin_texture()
	ctx.events.dawn_payout.connect(_on_dawn_payout)
```
Have the test also call `payout_vfx.bind_run(ctx, map_root)` and assert the `dawn_payout` connection count is unchanged. Consider guarding the other `bind_run` implementations the same way.

### WR-02: Start-night prompt hint goes stale after a runtime rebind

**File:** `ui/hud/hud.gd:114-151`, `tests/e2e/test_start_night_hold.gd:303-312`
**Issue:**
- `_start_night_hint` reads the InputMap "so a runtime rebind shows up in the prompt". The text is only rebuilt in `_refresh_loop`, which runs on phase, night and day signals.
- A rebind during the day therefore leaves the old key on screen until the next phase change.
- The test hides this by manually emitting `day_started` after the rebind. It never checks that a rebind alone updates the prompt.
- No rebind UI exists yet, but the CLAUDE.md constraints require runtime rebinding, so this will surface as soon as it does.

**Fix:** Refresh the prompt when the map changes. Either:
- Connect to a rebind signal or hook (for example a `Settings`/`InputRebinder` signal) and call `_refresh_loop()`.
- Or rebuild the hint every time the day prompt is shown or the pause menu closes.

Change the test to rebind without emitting `day_started` and assert the new text.

### WR-03: Wall-clock timing assertion in the short-dawn payout test

**File:** `tests/e2e/test_dawn_payout.gd:220-250`
**Issue:**
- `test_a_real_payout_lands_every_coin_inside_a_short_dawn_window` asserts `elapsed_s <= dawn_seconds + LAND_SLACK_S`. That is 1.0 s + 0.5 s, measured with `Time.get_ticks_msec()`.
- The nominal landing time is about 1.0 s, so a frame hitch or a slow CI runner can exceed the 0.5 s slack and fail the test. It has no relation to product correctness.
- The commit history says IN-04 "removed timing races from payout e2e tests", so this is the same class of defect.
- The payout is emitted while the run is still in DAY (`dawn_payout.emit` directly). No real dawn window exists, so the test measures tween speed, not a dawn boundary.
- `test_the_night_hands_back_to_a_new_day_through_dawn` has a similar structure. It uses fixed `wait_seconds(night + 0.5)` and `wait_seconds(dawn + 0.3)` while `MapRoot` clamps the sim step to 0.25 s per frame. At low frame rates the sim clock runs slower than wall time.

**Fix:**
- For the payout test, drop the wall-clock bound. The schedule is already proven by `test_the_last_coin_lands_inside_the_dawn_window_however_many_spots_pay` through `launch_stagger`.
- Assert only the observable end state after `wait_until`.
- Replace fixed waits in the hand-back test with `E2eSupport.wait_until(... phase == DAWN / DAY ...)`.

### WR-04: BuildingSystem duplicate handling is inconsistent (spots keep first, buildings keep last)

**File:** `simulation/buildings/building_system.gd:16-25`
**Issue:**
- Duplicate spot ids are skipped, and the comment says "keep the first def".
- Duplicate building ids are silently overwritten by the last definition: `_defs[building_def.id] = building_def` runs with no `has` check.
- `MapConfig.validate()` reports both as data errors. The two collections then behave oppositely, which is surprising.
- A tier table can quietly change under a running map depending on list order.
- The new data-error test covers only the spot case.

**Fix:**
```gdscript
if building_def == null or _defs.has(building_def.id):
	continue
_defs[building_def.id] = building_def
```
Add a matching test for a duplicate building id.

### WR-05: spot_ids() exposes the internal order array

**File:** `simulation/buildings/building_system.gd:29-30`
**Issue:**
- `spot_ids()` returns `_order` itself, not a copy.
- The class promises "Reads never mutate", but any caller can `append`, `sort` or `clear` the result and corrupt `nearest_spot_in_range`, `dawn_income_by_spot` and the payout ordering. `nearest_spot_in_range` would then hit a missing key in `_spots[spot_id]` and raise a script error.
- Presentation code and the debug overlay hold this array.

**Fix:** `return _order.duplicate()`. The arrays are small and read per frame at most. Alternatively document it as read-only and accept the risk.

## Info

### IN-01: DebugOverlayModel robustness gaps

**File:** `ui/overlay/debug_overlay_model.gd:35, 56, 64-66`
**Issue:**
- `provider.call()` is guarded only by `is_valid()`. A provider with a required argument, or one that errors, still raises a script error every refresh.
- `RunManager.RunPhase.keys()[phase]` indexes by enum value and only works while the enum stays contiguous from 0. `NIGHT_TRANSITION` is also the only non-DAY phase that shows no Timer row.

**Fix:** Look the name up with `RunManager.RunPhase.find_key(phase)`, and decide deliberately whether NIGHT_TRANSITION should show a timer.

### IN-02: Missing null guards in test_start_night_hold

**File:** `tests/e2e/test_start_night_hold.gd:117-121, 137-139`
**Issue:**
- Other nodes use the `assert_not_null` plus early-return pattern.
- `spot_label` is dereferenced (`spot_label.visible`) with no null check, and `_fill(map_root).visible` is called on a possibly-null Control. A scene change turns these into a script error instead of a clear assertion.

**Fix:** Add `assert_not_null(spot_label)` and include it in the early-return guard.

### IN-03: Magic literals and a hidden coupling to tuning in test_start_night_hold

**File:** `tests/e2e/test_start_night_hold.gd:157, 239, 283`
**Issue:**
- `+ 0.2` and `+ 0.1` are inline literals next to named `SETTLE_SLACK_S` and `OVERSHOOT_S`.
- `test_a_tap_fills_the_prompt_but_releasing_early_keeps_the_day` relies on `PARTIAL_HOLD_S` (0.5) being below `start_night_hold_seconds` (1.5 in `loop_tuning.tres`). If tuning drops below 0.5, the night starts and the test fails with a confusing message.

**Fix:** Name the constants. Derive the partial hold as `_tuning.start_night_hold_seconds * 0.3` instead of hard-coding it.

### IN-04: Weak identity assertion in the duplicate-spot test

**File:** `tests/unit/test_building_system_data_errors.gd:34`
**Issue:**
- `assert_eq(ctx.buildings.get_spot(&"a"), map.spots[0], ...)` is meant to prove the first definition was kept. The twin is field-identical, so a value comparison cannot tell them apart.
- The test would still pass if the twin replaced the original.

**Fix:** Use `assert_same(...)` (reference identity), or give the twin a distinct `position` and assert on that.

---

_Reviewed: 2026-09-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
