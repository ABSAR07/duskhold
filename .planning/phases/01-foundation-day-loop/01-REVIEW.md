---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - simulation/buildings/building_system.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_map_binding.gd
  - tests/e2e/test_start_night_hold.gd
  - tests/unit/test_building_system_data_errors.gd
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed the building system, the HUD and dawn-payout VFX, the debug overlay model, and the tests that cover them. I traced the dawn payout flow through `RunManager._apply_dawn_payout`, `DawnPayoutVfx` and `Hud`, and checked the `MapConfig.validate()` error strings the data-error tests depend on. The payout accounting holds up. Coin shares sum to each spot's amount, the announced `carried_total` equals the sum of landed shares, and the `_generation` guard stops a stale payout from touching the counters. The HUD's `_payout_pending = carried_total` assignment resets the lag on every payout. I found no crashes, security issues or data-loss paths. The findings below are robustness and correctness edges, mostly in how the code handles data errors and non-default input setups.

## Warnings

### WR-01: Start-night hint names the wrong key on non-QWERTY keyboard layouts

**File:** `ui/hud/hud.gd:183-185`
**Issue:** `_key_text` prefers `as_text_physical_keycode()`. Godot's physical-keycode text names the key by its US-QWERTY position, not by the label printed on the user's keycap. Default bindings are stored as `physical_keycode` (the tests use `KEY_N`). For a player on Dvorak, AZERTY or similar, the prompt "Hold N to start Night 2" can point at a key whose cap reads something else. The prompt is the only place the player learns this binding, so a wrong hint means they cannot start the night.
**Fix:** Resolve the layout-specific label for physical keys before falling back to the QWERTY name.
```gdscript
if key_event.physical_keycode != KEY_NONE:
	var label_key: Key = DisplayServer.keyboard_get_label_from_physical(key_event.physical_keycode)
	var text: String = OS.get_keycode_string(label_key | key_event.get_modifiers_mask())
	return text if not text.is_empty() else key_event.as_text_physical_keycode()
```
Verify the API name and modifier handling against 4.7 before adopting.

### WR-02: Debug-overlay providers with default arguments are silently dropped

**File:** `ui/overlay/debug_overlay_model.gd:39-40`
**Issue:** `provider.get_argument_count() > 0` also counts parameters that have defaults. A provider such as `func _wave_rows(verbose := false) -> Array` can be called with no arguments, yet it is skipped on every refresh without any message. This is the extension point Phase 2 will use for wave and path sections, and the failure mode is a section that quietly never appears. The invalid-Callable and needs-an-argument paths are equally silent.
**Fix:** Warn once per skipped provider so a misregistered section is discoverable, for example by keeping a `_warned: Dictionary` of titles and calling `push_warning("debug overlay section '%s' skipped: ..." % entry["title"])` on first skip. Alternatively, validate in `register_section` where the caller is on the stack.

### WR-03: BuildingSystem does not skip an empty building id, unlike spots

**File:** `simulation/buildings/building_system.gd:16-20`
**Issue:** The constructor skips spots with an empty id because it "could not be told apart from 'no spot in range'". A `BuildingDef` with `id == &""` is not skipped. It is stored as `_defs[&""]`, and any spot whose `building_id` is `&""` (the unset default) then resolves to that def. `MapConfig.validate()` reports both cases as errors, but `RunContext` only pushes the error and carries on, so the game builds it anyway. The two data-error paths are inconsistent, and the "data error is reported and skipped" contract is only half implemented. There is also no test for it in `test_building_system_data_errors.gd`.
**Fix:**
```gdscript
if building_def == null or building_def.id == &"" or _defs.has(building_def.id):
	continue
```
Add a test alongside the empty-spot-id one.

## Info

### IN-01: Rebind detection relies on event object identity

**File:** `ui/hud/hud.gd:79`
**Issue:** `InputMap.action_get_events(...) != _hint_events` compares the arrays element by element, so it detects only added, removed or replaced event objects. A rebind UI that edits an existing event in place (for example setting `physical_keycode` on the stored `InputEventKey`) leaves the prompt stale. Nothing in Phase 1 rebinds this way, but a later remapping screen might.
**Fix:** Compare a derived signature instead, such as the resulting hint string, or document that rebinding must replace events.

### IN-02: Joypad axis hint hides the direction

**File:** `ui/hud/hud.gd:173-175`
**Issue:** Every `InputEventJoypadMotion` shows as `(Axis N)` or `(LT)`/`(RT)` regardless of `axis_value` sign. A stick bound to "left" and one bound to "right" read identically. This is cosmetic, and the Xbox-only naming is already documented as a known limitation.
**Fix:** Append the direction for non-trigger axes, or accept and document.

### IN-03: Tautological test of the stagger formula

**File:** `tests/e2e/test_dawn_payout.gd:197-214`
**Issue:** `test_the_last_coin_lands_inside_the_dawn_window_however_many_spots_pay` recomputes `(n-1) * stagger + TRIP_SECONDS` from `launch_stagger`'s own output. It checks the formula against itself, not real scheduling. It also spawns a full map it does not use. The next test (`test_a_real_payout_schedules_its_last_coin...`) is the meaningful one. Consider dropping the first test or reducing it to the `launch_stagger` clamp assertions.
**Fix:** Delete the redundant last-lands assertion, or construct the vfx directly instead of spawning a map.

### IN-04: Double-bind test does not cover most HUD connections

**File:** `tests/e2e/test_map_binding.gd:73-91`
**Issue:** `test_binding_the_hud_and_payout_view_again_connects_nothing_twice` counts only `gold_changed`, `dawn_payout`, `coin_landed` and `payout_started`. `Hud.bind_run` also connects `phase_changed`, `night_started`, `day_started`, the three `BuildHoldController` signals and the start-night `progress_changed`. A regression in the repeat-call guard that only affected those would go unnoticed.
**Fix:** Add connection-count assertions for `phase_changed`, `night_started`, `day_started` and the hold signals.

### IN-05: Coin start point is not guarded against a position behind the camera

**File:** `ui/hud/dawn_payout_vfx.gd:230-235`
**Issue:** `Camera3D.unproject_position` returns a mirrored screen point for a world position behind the camera. The fallback only covers a missing camera or spot. With the current fixed top-down camera this cannot happen, so it is a latent issue for later camera work.
**Fix:** `if camera.is_position_behind(world_pos): return get_viewport_rect().size * 0.5`.

---

_Reviewed: 2026-09-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
