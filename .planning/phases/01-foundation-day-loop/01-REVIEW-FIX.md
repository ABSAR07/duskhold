---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T07:39:06Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T07:39:06Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8
- Fixed: 8
- Skipped: 0

**Verification:** run in the main checkout on branch gsd/phase-01-foundation-day-loop (no worktree). After the last fix `bash tools/test.sh` passed 232/232 (was 227) and `bash tools/lint.sh` was clean. Each fix was also checked with the single-file run `bash tools/test.sh -gselect=<file>.gd` before its commit.

## Fixed Issues

### WR-01: Start-night hint names the wrong key on non-QWERTY keyboard layouts

**Files modified:** `ui/hud/hud.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** b591214
**Applied fix:** `_key_text` now resolves a physical key through `physical_label_resolver` (default `_layout_label`, which calls `DisplayServer.keyboard_get_label_from_physical`) and names it with `OS.get_keycode_string(label | modifiers)`, falling back to `as_text_physical_keycode()` if the label is empty. The headless display server errors on that call, so `_layout_label` returns the key unchanged there; the default text stays "Hold N / (Y) to start Night 1" and the existing default-binding test still passes. The resolver is a public Callable so a test can stand in for a non-QWERTY layout.
**Status:** fixed: requires human verification. Headless Godot cannot switch layout, so the real `DisplayServer` path (a Dvorak or AZERTY desktop) is not exercised by any test; the seam is. Please check the prompt once on a non-QWERTY layout.
**Test:** new `test_the_prompt_names_the_key_by_the_layout_label_not_the_qwerty_position` (fake layout printing B where QWERTY has N, with Ctrl held, expects "Hold Ctrl+B ...").
**Mutation probe:** made `_key_text` use the physical keycode directly instead of the resolver; the new test failed ("Hold Ctrl+N" vs "Hold Ctrl+B"). Restored, 13/13 green.

### WR-02: Debug-overlay providers with default arguments are silently dropped

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 56fbdf7
**Applied fix:** `collect` now asks `_skip_reason(provider)` (invalid callable, or any declared parameter, defaults included) and calls `_warn_once(title, reason)`, which does one `push_warning("debug overlay section '<title>' skipped: <reason>")` per title, tracked in `_warned`. Skip behaviour is unchanged; it is now discoverable.
**Test:** new `test_a_skipped_provider_is_warned_about_once_however_often_the_overlay_refreshes` (a `func(verbose: bool = false)` provider, three `collect` calls, expects the named warning and a warning count of exactly 1).
**Mutation probes:** removing the once-guard gave "Expected 1 push_warning errors. Got 3"; removing the warning gave "Got 0". Both failed the new test; restored, 14/14 green.

### WR-03: BuildingSystem does not skip an empty building id, unlike spots

**Files modified:** `simulation/buildings/building_system.gd`, `tests/unit/test_building_system_data_errors.gd`
**Commit:** 723080f
**Applied fix:** the constructor now also skips a `BuildingDef` whose `id == &""`, as it does for spots, so a spot with an unset `building_id` no longer resolves to a nameless def.
**Test:** new `test_a_building_with_an_empty_id_is_skipped_and_never_matches_an_unset_building_id` (nameless def plus a spot with an unset building id; expects no def for the spot, `apply_next_tier` returning null and no instance).
**Mutation probe:** removed the new `id == &""` clause; the test failed on all three assertions. Restored, 6/6 green.

### IN-01: Rebind detection relies on event object identity

**Files modified:** `ui/hud/hud.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** 9a29bce
**Applied fix:** `_process` now compares the derived hint text (`_start_night_hint()`) with the stored `_hint` instead of comparing event arrays, so an `InputEventKey` edited in place refreshes the prompt. `_hint_events` was removed.
**Test:** new `test_the_prompt_follows_a_bound_key_edited_in_place` (same event object edited from N to M, expects "Hold M ...").
**Mutation probe:** restored the event-array comparison; the test failed ("Hold N" vs "Hold M"). Restored, 14/14 green.

### IN-02: Joypad axis hint hides the direction

**Files modified:** `ui/hud/hud.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** 51aa002
**Applied fix:** new `_axis_text` keeps LT/RT for triggers and shows other axes as "Axis N-" or "Axis N+" by the sign of `axis_value`.
**Test:** extended `test_the_prompt_names_a_trigger_or_mouse_button_binding` with a left-stick-negative and a left-stick-positive binding, expecting "(Axis 0-)" and "(Axis 0+)".
**Mutation probe:** dropped the direction suffix; both new assertions failed ("(Axis 0)"). Restored, 14/14 green.

### IN-03: Tautological test of the stagger formula

**Files modified:** `tests/e2e/test_dawn_payout.gd`
**Commit:** b683e10
**Applied fix:** renamed to `test_a_crowded_payout_tightens_the_stagger_to_exactly_fill_the_dawn_window` and rewrote it to compare `launch_stagger(40)` with `(dawn_seconds - TRIP_SECONDS) / 39` computed from the tuning, instead of recomputing the landing time from `launch_stagger`'s own output. The small-payout default assertion is kept. It still spawns a map, because `launch_stagger` needs a bound context to read the dawn length.
**Mutation probe:** made `launch_stagger` return `STAGGER_SECONDS`; the rewritten test failed (0.08 vs 0.0103), as did the CR-01 real-payout test (`test_a_real_payout_schedules_its_last_coin...`, "1.48 <= 1.001"). That CR-01 test was not edited and still fails against the old-stagger bug. `ui/hud/dawn_payout_vfx.gd` restored, 15/15 green.

### IN-04: Double-bind test does not cover most HUD connections

**Files modified:** `tests/e2e/test_map_binding.gd`
**Commit:** 07a3fb5
**Applied fix:** the test now snapshots the connection count of all 11 signals the two `bind_run` calls connect (`gold_changed`, `dawn_payout`, `phase_changed`, `night_started`, `day_started`, `coin_landed`, `payout_started`, the three hold signals and the start-night `progress_changed`), asserts each is bound (> 0) beforehand so it cannot pass vacuously, then binds again and expects equal counts.
**Mutation probe:** disabled `Hud.bind_run`'s repeat-call guard; the test failed (engine "already connected" errors, so it fails as unexpected errors rather than on a count). Restored, 4/4 green.

### IN-05: Coin start point is not guarded against a position behind the camera

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 1c3e320
**Applied fix:** `_start_point` returns the screen centre when `camera.is_position_behind(world_pos)`.
**Test:** new `test_a_coin_starts_mid_screen_when_its_plot_is_behind_the_camera` (checks the plot has its own screen point first, then moves the camera 1000 units along its view direction and expects the centre).
**Mutation probe:** replaced the `is_position_behind` condition with `false`; the test failed with the mirrored point (32.80, 31.98) instead of (32, 32). Restored, 16/16 green.

---

_Fixed: 2026-09-30T07:39:06Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
