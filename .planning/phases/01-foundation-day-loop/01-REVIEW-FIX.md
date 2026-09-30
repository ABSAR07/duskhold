---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T08:09:33Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T08:09:33Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

Verification ran in the main checkout on branch `gsd/phase-01-foundation-day-loop` (no worktree, per the orchestrator note), so the numbers are reproducible from the tree as it stands. After the last fix: `bash tools/test.sh` 235/235 passing (was 232; +3 new tests), `bash tools/lint.sh` clean.

## Fixed Issues

### WR-01: A provider that returns a non-Array is skipped silently, contradicting the "warn once" design

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** b789dde
**Applied fix:** `collect` now calls `_warn_once` with "it returned <Type>, not an Array of rows" when a provider returns a non-Array. The existing non-Array test now also asserts both warnings (`Null` returns Nil, `Text` returns String) and that exactly two were pushed. Not mutation-probed; without the new `else` branch no warning is pushed, so the added `assert_push_warning` calls cannot pass.

### WR-02: `_warned` is never cleared when a provider is re-registered

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** b650073
**Applied fix:** The replace branch of `register_section` now does `_warned.erase(title)`. New test `test_replacing_a_warned_provider_lets_the_new_one_warn_again` registers a provider with a parameter, refreshes, replaces it with one returning null, refreshes twice, and expects two warnings in total. Mutation probe: deleting the `_warned.erase(title)` line made exactly that test fail (14/15); restored and 15/15 green.

### WR-03: Wall-clock-dependent e2e assertions can flake on a slow or loaded runner

**Files modified:** `tests/e2e/test_dawn_payout.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** 9ff7068
**Applied fix:**
- `test_coins_are_in_flight_and_the_counter_lags_early_in_dawn` no longer waits for a real dawn. A new helper `_night_with_two_houses()` returns the map with the night just started; the test ticks `ctx.run_manager` past the night by hand and asserts in the same frame, with no await before the checks, so no real time can pass between the first coin launching and the assertions. `_dawn_with_two_houses()` (used by the other tests) now builds on that helper. One `await wait_process_frames(1)` was added after the assertions only, so the House view replaced by the tier II upgrade finishes freeing (otherwise GUT reports 13 orphans).
- `test_a_tap_fills_the_prompt_but_releasing_early_keeps_the_day` now runs on a duplicate tuning with `start_night_hold_seconds = 6.0` (`SLOW_HOLD_S`) and taps for 0.4 s (`TAP_S`), so the ratio only reaches 1.0 if the run stalls about 5.6 s instead of about 1 s.

Mutation probes (all restored afterwards):
- Removing the HUD hold-back (`_payout_pending = 0` in `Hud._on_payout_started`): `test_coins_are_in_flight_and_the_counter_lags_early_in_dawn` fails, along with four other dawn tests that share the guard.
- Making the start-night threshold 0.1 s (`_held >= 0.1`) in `StartNightHoldController`: `test_a_tap_fills_the_prompt_but_releasing_early_keeps_the_day` fails (1/14).
- CR-01 dawn-window guard: replacing `stagger` with `STAGGER_SECONDS` in the coin schedule (`float(launches.size()) * STAGGER_SECONDS`) still fails `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window` (1 failure); restored.

### IN-01: `BuildingSystem.get_instance` hands out the live mutable instance, contradicting the "reads never mutate" contract

**Files modified:** `simulation/buildings/building_system.gd`, `tests/unit/test_build_spot.gd`
**Commit:** bfdb0cf
**Applied fix:** Every caller was checked first. Outside `BuildingSystem`, all callers of `get_instance` only null-check it or read `building_id`/`tier` (unit, integration and e2e tests plus `DebugOverlayModel._count_buildings`); the only mutation path is `apply_next_tier`, called by `CommandProcessor`. `get_instance` now returns a copy through a small private `_snapshot` helper. The internal paths that need the live object (`current_tier`, `dawn_income_by_spot`, `apply_next_tier`) read `_instances` directly, so gameplay is unchanged. `apply_next_tier` also returns a snapshot (its only non-test caller ignores the return value). The class header now says instances are snapshots and that `BuildSpotDef` and `BuildingDef` are shared with the `MapConfig`, returned by reference, and to be treated as read-only (those resources were not copied; the contract is documented instead). New test `test_a_reader_changing_the_instance_it_was_given_does_not_change_the_building` mutates both the `get_instance` and `apply_next_tier` results and checks the standing tier and type are unchanged. Mutation probe: making `_snapshot` return the live instance failed only that test (8/9); restored.

### IN-02: `DawnPayoutVfx._on_dawn_payout` trusts untyped Dictionary values as `int`

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 21ae6e0
**Applied fix:** New `_whole_amounts(per_spot)` coerces each value once (`int(amount)` for an int or float; anything else is dropped with a `push_warning`), and `_on_dawn_payout` uses that dictionary for the carried-gold sum, the coin counts and the launch plan. Handler behaviour for int payouts is unchanged. New test `test_a_payout_amount_that_is_a_float_or_not_a_number_does_not_abort_the_payout` emits `{house_1: 4.0, house_2: null}`, expects `payout_started(4)`, four coins from house_1, none from house_2, the warning, and the HUD settling. Mutation probe: with the original `vfx` file restored, that test failed (16/17); the fixed file passes 17/17.

### IN-03: Redundant HUD refresh triggers and a test that emits synthetic phase transitions

**Files modified:** `ui/hud/hud.gd`, `tests/e2e/test_dawn_payout.gd`, `tests/e2e/test_map_binding.gd`
**Commit:** d4ef4f5
**Applied fix:** Dropped `Hud._on_night_started` / `_on_day_started` and their two connections. `RunManager` updates the phase and the night and day numbers before every `phase_changed`, so `_on_phase_changed` alone refreshes the prompt and banner (commented at the call). `test_map_binding.gd` no longer lists those two signals among those the HUD connects. `test_the_hud_releases_a_held_back_readout_when_dawn_ends` no longer emits a fake `phase_changed`: it starts a real night, ticks to a real dawn, emits `payout_started(7)`, then ticks `dawn_seconds` so a genuine DAWN to DAY transition fires. Mutation probe: neutralising the HUD's dawn-end backstop failed that test (16/17); restored. The full suite (235/235) and the start-night prompt and banner tests pass, and the default prompt text "Hold N / (Y) to start Night 1" is untouched.

---

_Fixed: 2026-09-30T08:09:33Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
