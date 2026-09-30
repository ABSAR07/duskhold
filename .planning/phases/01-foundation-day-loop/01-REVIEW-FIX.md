---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T11:17:28Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T11:17:28Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

**Verification ran in the main checkout** (branch `gsd/phase-01-foundation-day-loop`), not in an isolated worktree. A hand-rolled worktree has no `.godot/` import cache, so it cannot run the project's gates, and the orchestrator's notes describe editing and committing in the main checkout. Every number below is reproducible from the current tree: `bash tools/test.sh` reports 260/260 tests in 34 scripts, and `bash tools/lint.sh` is clean (69 files, no problems). `.planning/config.json` still carries its unrelated uncommitted change and was never staged. `.github/workflows/ci.yml` and the start-night prompt text were not touched.

## Fixed Issues

### WR-01: `SIM_SIGNALS` is duplicated, and only one copy has a drift guard

**Files modified:** `tests/support/sim_signals.gd` (new), `tests/support/sim_signals.gd.uid` (new), `tests/unit/test_debug_overlay_readonly.gd`, `tests/unit/test_debug_overlay_timed_phases.gd`
**Commit:** 24f0e1e
**Applied fix:** Created `SimSignals` (`class_name SimSignals`, `const ALL`) in `tests/support/`. It is not named `test_*`, so GUT does not collect it, and its Godot-generated `.gd.uid` is committed with it. Both overlay suites now iterate `SimSignals.ALL`, and both local `SIM_SIGNALS` constants are gone. The drift-guard test `test_the_watched_signals_are_every_signal_the_simulation_declares` stays in `test_debug_overlay_readonly.gd` and compares `SimSignals.ALL` with the signals `SimEvents` declares, so one guard now covers every consumer. The public-method counts are unchanged (20 and 8).

**Mutation probe (test-only fix, so the "unfixed code" was the old duplicated list):** I added a `probe_added` signal to `SimEvents` and to `SimSignals.ALL`, and made `DebugOverlayModel.collect` emit it.
- With the fixed tests, all three read-only tests failed: the day test plus the night and dawn tests in `test_debug_overlay_timed_phases.gd` ("Expected ... to NOT emit signal [probe_added]").
- With the pre-fix `test_debug_overlay_timed_phases.gd` (restored from `HEAD`) under the same probe, all 7 of its tests stayed green. This confirms the under-watching the review described.
- `SimEvents`, `DebugOverlayModel`, `SimSignals` and the test files were restored from backup copies afterwards, and `git diff` showed no residue.

### IN-01: Control flow in `DebugOverlayModel` depends on free-text reason strings

**Files modified:** `ui/overlay/debug_overlay_model.gd`
**Commit:** ab99a82
**Applied fix:** `_skip_reason` (returned prose) became `_skip_code`, returning a new `Skip` enum (`NONE`, `OWNER_FREED`, `CALLABLE_INVALID`, `DECLARES_PARAMETERS`). All message text now lives in one `SKIP_MESSAGES` table, and a `GONE_FOR_GOOD` list names the codes that drop a section. `collect` warns with `SKIP_MESSAGES[skip]` and erases the entry when `skip in GONE_FOR_GOOD`. `_is_gone` and the `REASON_*` string constants are removed (nothing else referenced them). Warning text is byte-for-byte unchanged, so the existing tests that pin it did not need edits. `gdformat` re-wrapped the long `DECLARES_PARAMETERS` message entry.

**Mutation probe:** Removing `Skip.CALLABLE_INVALID` from `GONE_FOR_GOOD` (making it transient) failed `test_a_provider_with_an_invalid_callable_is_dropped_after_its_one_warning` in `test_debug_overlay_readonly.gd` (`["Perf","Loop","Agents","Ghost","Live"]` != `[..."Live","Ghost"]`), so the new structure is pinned by the existing tests. The source was restored from a backup copy.

### IN-02: Dead tuning setup in the hardening e2e test

**Files modified:** `tests/e2e/test_dawn_payout_hardening.gd`
**Commit:** a39c356
**Applied fix:** Deleted `FAST_NIGHT_S` and the `_tuning.placeholder_night_seconds = FAST_NIGHT_S` line. `before_each` keeps the duplicated tuning resource. All 7 tests in the file still pass, which confirms the setting had no effect.

### IN-03: Test name and message use "owner freed" for a case with no owner

**Files modified:** `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 14cfed2
**Applied fix:** Renamed `test_a_provider_whose_owner_was_freed_is_dropped_after_its_one_warning` to `test_a_provider_with_an_invalid_callable_is_dropped_after_its_one_warning`. "Owner freed" now appears only on the `lifetime_owner` test. Its assertion messages already say "callable is no longer valid" and needed no change. I did not merge or remove the overlapping `test_a_freed_section_provider_is_skipped_instead_of_crashing`, because the review only asked for the rename and that test also pins the skipped-instead-of-crashing behaviour. The public-method count stays at 20.

### IN-04: The clamp e2e test does not check what it claims about the amounts

**Files modified:** `tests/e2e/test_dawn_payout_hardening.gd`
**Commit:** 3f3ee45
**Applied fix:** In `test_absurdly_large_amounts_are_clamped_so_the_coin_cap_still_holds`:
- `assert_lte(get_launch_delays().size(), MAX_COINS)` became `assert_eq(..., MAX_COINS)`. Two spots at the clamped amount plan exactly 12 coins.
- After the flight, the test asserts `vfx.get_last_total() == clamped_total`.
- It asserts the two spots' spawned counts sum to `MAX_COINS`, and that they are equal (an even 6 and 6). This replaces the two `assert_gte(..., 1)` checks and avoids integer division.

**Mutation probes** (each restored from a backup copy of `ui/hud/dawn_payout_vfx.gd`):
- Shrinking the split budget in `_coins_for_amount` to `MAX_COINS - 2` gives 10 coins per payout. The new test failed on "plan exactly the coin budget" (`[10] expected to equal [12]`) and "exactly the budget of coins flew". By inspection the old `<= MAX_COINS` and `>= 1` assertions would have passed.
- Making `_show_total` set `_last_total = _pending_total - 1` failed the new test with `[1999999] expected to equal [2000000]`. The old test never read `get_last_total()` after the flight.

`ui/hud/dawn_payout_vfx.gd` is unchanged in the final tree (`git status` clean for it), so the CR-01 guard `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window` was not affected and its probe was not re-run.

## Skipped Issues

None. All in-scope findings were fixed.

---

_Fixed: 2026-09-30T11:17:28Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
