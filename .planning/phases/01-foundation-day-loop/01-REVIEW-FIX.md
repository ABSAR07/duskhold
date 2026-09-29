---
phase: 01-foundation-day-loop
fixed_at: 2026-09-29T17:15:00Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 9
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-29T17:15:00Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 9
- Fixed: 9
- Skipped: 0

**Verification:** run in the main checkout (no worktree, per orchestrator instruction) on branch `gsd/phase-01-foundation-day-loop`. `bash tools/lint.sh` was green before every commit. After the last fix the full `bash tools/test.sh` run passed 218/218 (was 215; three tests added).

## Fixed Issues

### WR-01: DawnPayoutVfx.bind_run is not idempotent, and the "bind again" test does not cover it

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_map_binding.gd`
**Commit:** 2d8dd35
**Applied fix:** `bind_run` returns early when already bound (same guard as `Hud.bind_run`). The re-bind test (renamed `test_binding_the_hud_and_payout_view_again_connects_nothing_twice`) now also calls `payout_vfx.bind_run(...)`. Other `bind_run` implementations were not touched.

### WR-02: Start-night prompt hint goes stale after a runtime rebind

**Files modified:** `ui/hud/hud.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** e701095
**Applied fix:** The HUD remembers the `start_night` event list the prompt text was built from. A `_process` check, only while the prompt is visible, compares the current event list to it (one small array, no string building) and calls the new `_refresh_prompt_text()` when it differs. The default text is unchanged ("Hold N / (Y) to start Night 1"). The rebind test now rebinds and waits two frames, with no `day_started` emit. A rebind that mutates an existing event in place, instead of replacing the events, would not be noticed by this trigger.

### WR-03: Wall-clock timing assertion in the short-dawn payout test

**Files modified:** `tests/e2e/test_dawn_payout.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** 32c62fa
**Applied fix:** Removed the `Time.get_ticks_msec()` elapsed-time assertion and the `LAND_SLACK_S` constant from the short-dawn payout test. It now asserts the end state after `wait_until`, and the landing schedule stays proven by `launch_stagger`. In `test_the_night_hands_back_to_a_new_day_through_dawn` the fixed `wait_seconds` calls were replaced by `E2eSupport.wait_until` on the DAWN and DAY phases through a new `_in_phase` helper.

### WR-04: BuildingSystem duplicate handling is inconsistent (spots keep first, buildings keep last)

**Files modified:** `simulation/buildings/building_system.gd`, `tests/unit/test_building_system_data_errors.gd`
**Commit:** c0c7870
**Applied fix:** A duplicate building id is now skipped, so the first def is kept, matching spots. Added `test_a_duplicate_building_id_keeps_the_first_definition` (asserts reference identity and the first def's tier cost).

### WR-05: spot_ids() exposes the internal order array

**Files modified:** `simulation/buildings/building_system.gd`, `tests/unit/test_build_spot.gd`
**Commit:** 5d3576d
**Applied fix:** `spot_ids()` returns `_order.duplicate()`. Added `test_changing_the_returned_spot_ids_does_not_change_the_system`.

### IN-01: DebugOverlayModel robustness gaps

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** b495b87
**Applied fix:** The phase name comes from `RunPhase.find_key(phase)`. Providers that need an argument (`get_argument_count() > 0`) are skipped along with invalid ones, and a test covers this. The NIGHT_TRANSITION timer question was decided deliberately: no Timer row, because the phase has no clock and passes straight through to NIGHT (`get_phase_time_remaining` returns 0 for it). A code comment records this.

### IN-02: Missing null guards in test_start_night_hold

**Files modified:** `tests/e2e/test_start_night_hold.gd`
**Commit:** 2fe6dc1 (shared with IN-03, both edit the same test file)
**Applied fix:** `spot_label` and the fill bar are fetched up front, asserted with `assert_not_null`, and included in the early-return guard.

### IN-03: Magic literals and a hidden coupling to tuning in test_start_night_hold

**Files modified:** `tests/e2e/test_start_night_hold.gd`
**Commit:** 2fe6dc1 (shared with IN-02)
**Applied fix:** `PARTIAL_HOLD_S` is replaced by `PARTIAL_HOLD_FRACTION` (0.3), and the partial hold is derived from `_tuning.start_night_hold_seconds`. The `+ 0.1` literals became `PAST_END_S`. The `+ 0.2` literal cited by the review was already removed by the WR-03 fix.

### IN-04: Weak identity assertion in the duplicate-spot test

**Files modified:** `tests/unit/test_building_system_data_errors.gd`
**Commit:** b82282b
**Applied fix:** `assert_eq` replaced with `assert_same` so the test proves the first spot object was kept.

---

_Fixed: 2026-09-29T17:15:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
