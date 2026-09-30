---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T08:38:20Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T08:38:20Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

**Verification:** `bash tools/test.sh` (full GUT suite) and `bash tools/lint.sh` ran in the main checkout on branch `gsd/phase-01-foundation-day-loop` (`workflow.use_worktrees` was off for this pass, so no worktree was used). Both were green before every commit; the suite went 235 -> 237 tests as two tests were added (one in IN-01, one in IN-03) and one existing test was reworked.

## Fixed Issues

### WR-01: `_whole_amounts` validates amounts but not spot keys, so a bad key still aborts the payout

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 60d4881
**Applied fix:** `_whole_amounts` now checks the key (must be a `StringName` or `String`, stored as `StringName`) and rejects a non-finite float amount (`NAN`/`INF`) in the same pass. Each rejected entry is dropped with a `push_warning` of the form `dawn payout for '<key>' ignored: <reason>`; the existing `'house_2' ignored` wording is unchanged. The float/null test became `test_a_malformed_payout_entry_does_not_abort_the_payout` and now also feeds a `NAN` amount and an `int` key, asserting `payout_started(4)`, the three warnings and that the bad entries send no coin. The reviewer suggested a separate test; it was folded into the existing one because `test_dawn_payout.gd` sits close to gdlint's 20-public-method cap.
**Mutation probe:** replacing the key check with `if false:` made `test_a_malformed_payout_entry_does_not_abort_the_payout` fail (16/17); restored byte-identical.

### WR-02: The "+X gold" label shows the claimed total while the coins and the HUD readout use the carried gold

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 982b071
**Applied fix:** Decision: the label shows the carried gold, the same figure the HUD readout is held back by and the coins fly with. `_pending_total` is now set to `carried` after the planning loop and before `payout_started.emit`. When `carried != total` a `push_warning` ("dawn payout claims X gold but its per-spot amounts carry Y; showing Y") makes the divergence visible. With no coin to fly (`carried == 0`, malformed `per_spot`) no total is shown at all, since there is no gold in the air to attribute and the readout is not held back; this replaces the old "show it now" branch. `get_last_total()` is documented as the carried figure. For the shipped `per_spot` source (amounts sum to `total`) behaviour is identical, and no e2e test on the real RunManager path changed.
Tests updated to the new intent:
- `test_the_vfx_announces_the_gold_its_coins_carry_and_the_hud_lags_by_exactly_that` renamed `test_the_label_the_coins_and_the_hud_readout_all_use_the_gold_that_flies`; claimed 9 vs carried 4 now asserts the warning, the label `+4 gold` and `get_last_total() == 4`.
- `test_the_coin_cap_follows_the_gold_that_flies_not_the_claimed_total` (claimed 5, carried 120) asserts the warning and the label `+120 gold`.
- `test_a_payout_with_no_coin_to_fly_does_not_leave_the_hud_short` renamed `..._shows_no_total_and_does_not_leave_the_hud_short`; it now asserts the label stays hidden, `get_last_total() == 0` and the warning, alongside the readout staying settled.
**Mutation probe:** temporarily restoring `_pending_total = total` failed `test_the_coin_cap_follows_the_gold_that_flies_not_the_claimed_total` and the reworked label test (15/17). The CR-01 dawn-window guard was also probed: changing the coin schedule to `STAGGER_SECONDS` instead of `stagger` still fails `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window` (delay 0.88 vs 0.4, land time 1.48 vs 1.001). All probes restored byte-identical.
**Status note:** this is a display-semantics decision; worth a human glance that "carried gold" is the figure the owner wants on the label.

### IN-01: `_launch` tweens from an earlier payout are never killed on reset

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 3c29bd2
**Applied fix:** `_schedule_launch` records each delay tween in a new `_launch_tweens: Array[Tween]`, and `_reset_for_new_payout` kills and clears them. The generation guard stays as a backstop. A read-only `get_launch_tweens()` accessor (same style as `get_launch_delays()`) lets the new test `test_a_new_payout_stops_the_pending_launches_of_the_one_it_supersedes` hold the tweens of a 12-coin payout, supersede it with an empty payout, and assert each is no longer valid.
**Mutation probe:** replacing the `tween.kill()` in reset with `pass` failed that test (17/18). A first version of the test counted the array's contents and did not fail under the mutation (the array is cleared either way), so it was rewritten to hold the tween objects.

### IN-02: `_count_buildings` allocates a snapshot per spot on every overlay refresh just to test for emptiness

**Files modified:** `ui/overlay/debug_overlay_model.gd`
**Commit:** 6240e20
**Applied fix:** `_count_buildings` now tests `_ctx.buildings.current_tier(spot_id) > 0`, exactly as suggested. Covered by the existing "Buildings" row assertion in `test_default_rows_report_fps_phase_gold_buildings_units_enemies`.
**Mutation probe:** changing the test to `>= 0` made that test fail (`8` vs `1`).

### IN-03: A registered section named like a default ("Perf", "Loop", "Agents") shows twice

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 30d0dd4
**Applied fix:** Added `DebugOverlayModel.DEFAULT_TITLES`; `register_section` refuses a title in it with a `push_warning` and returns, and its docstring says so. New test `test_registering_a_default_section_title_is_refused_instead_of_showing_it_twice` registers each default title, asserts the warning, and asserts `collect` still lists exactly Perf, Loop, Agents once each.
**Mutation probe:** disabling the guard (`if false:`) failed the new test (three missing warnings and the duplicated section list).

---

_Fixed: 2026-09-30T08:38:20Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
