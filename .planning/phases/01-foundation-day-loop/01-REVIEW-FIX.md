---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T09:04:22Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 01: Code Review Fix Report

**Fixed at:** 2026-09-30T09:04:22Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

**Verification:** run in the main checkout (no worktree, per the orchestrator), Git Bash. `bash tools/lint.sh` clean (66 files) and the full `bash tools/test.sh` suite green at 241/241 (237 before this pass plus 4 new tests) after the last commit. Each commit was preceded by lint plus the relevant test file.

## Fixed Issues

### WR-01: Integer overflow in `carried_gold` defeats the coin cap and can spawn a huge number of coins

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout_hardening.gd` (new), `tests/e2e/test_dawn_payout_hardening.gd.uid` (new)
**Commit:** 7cd97d9
**Applied fix:** added `MAX_AMOUNT = 1_000_000`; `_whole_amounts` now clamps each amount as a float to +/-MAX_AMOUNT before `int()`, so a huge float never reaches an undefined `int()` conversion and the sum of several amounts cannot wrap. The review's second suggestion (`mini(amount, MAX_COINS)` in `_coins_for_amount`) was not applied: with clamped amounts, `carried_gold <= MAX_COINS` already implies `amount <= MAX_COINS`, so it would be dead code.
**New test:** `test_absurdly_large_amounts_are_clamped_so_the_coin_cap_still_holds` (a float 1e30 and an int 9e18 in one payout; asserts `payout_started` carries 2 * MAX_AMOUNT, at most MAX_COINS coins are scheduled, both spots still send a coin, and the HUD settles). It went in a new file because `tests/e2e/test_dawn_payout.gd` is at gdlint's 20-public-method cap (18 tests plus `before_each` and `after_each`).
**Mutation probe:** reverted the clamp to `int(amount)`; the test FAILED (`payout_started` carried 9000000000000000000 instead of 2000000). Restored; passes. The probe avoided the two-large-ints wrap case on purpose, since unclamped that would schedule an enormous coin count and hang the run.

### WR-02: `get_launch_tweens()` returns finished tweens, contradicting its documentation

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout_hardening.gd`
**Commit:** 534b895
**Applied fix:** `get_launch_tweens()` now returns only tweens that are still valid (a fired tween is finished and invalid), built with an explicit loop so the result stays a typed `Array[Tween]`.
**New test:** `test_launch_tweens_that_have_fired_are_no_longer_reported_as_waiting` (12-coin payout, waits for the total, asserts no tween is reported waiting).
**Mutation probe:** replaced the `is_valid()` filter with `if true:`; the test FAILED ("no launch is waiting once every coin left"). Restored; passes.

### WR-03: Camera test dereferences a possibly-null `vfx`

**Files modified:** `tests/e2e/test_dawn_payout.gd`
**Commit:** 433e30d
**Applied fix:** added the `assert_not_null(vfx, ...)` plus early return used by every other test in the file, before `vfx.get_viewport()`. The private `_start_point` access the review also mentions is handled under IN-02.
**Mutation probe:** none. This is a failure-mode guard (a missing node now fails readably instead of a script error), not behaviour that a production bug can regress; the test itself still passes.

### IN-01: `_last_total` is not reset between payouts

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout_hardening.gd`
**Commit:** 6500c3f
**Applied fix:** `_reset_for_new_payout` now sets `_last_total = 0`, and the `get_last_total()` doc says it is the current payout's total, 0 until shown and 0 again when a new payout begins. Chose the reset over rewording the test messages, so the accessor matches what the assertions claim.
**New test:** `test_a_payout_with_no_coins_does_not_report_the_previous_payouts_total` (a 3-gold payout lands and shows its total, then an empty payout must report 0).
**Mutation probe:** removed the reset; the test FAILED ("the next payout, with nothing to show, starts from 0"). Restored; passes.

### IN-02: Test-only accessors and private access widen the production surface

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** e6761b5
**Applied fix:** kept the read-only accessors and documented `get_launch_delays` and `get_launch_tweens` as test hooks (`get_spawned_count` is also used internally, so its doc just says tests read it too). Renamed `_start_point` to the public `start_point` (with a doc line) and updated its two callers in the camera test, so no test reaches for a private member any more.
**Guard probe (per orchestrator note):** `get_launch_delays()` is unchanged, so the CR-01 dawn-window guard `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window` keeps its observation point. Re-ran the mutation after the change: replaced `stagger` with `STAGGER_SECONDS` in the coin schedule; the guard FAILED (last launch delay 0.88 vs expected 0.4, and 1.48 > 1.001 dawn window). Restored precisely (`git diff` shows only the intended IN-02 changes); all 18 tests in the file pass.

### IN-03: Unreachable providers stay registered for the model's lifetime

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 1a0bb93
**Applied fix:** `collect()` iterates a copy of `_registered`; a provider whose Callable is no longer valid is warned about once and then removed (and its warn-once flag cleared). A provider that merely declares parameters is still kept, since replacing it is a valid recovery path and it is warned once as before.
**New test:** `test_a_provider_whose_owner_was_freed_is_dropped_after_its_one_warning` (one warning across two refreshes; re-registering the dead title then appends it after "Live" instead of replacing in place, which is the observable sign that the dead entry was dropped).
**Mutation probe:** replaced the `_registered.erase(entry)` with `pass`; the test FAILED (two warnings, and Ghost stayed ahead of Live). Restored; passes.

---

_Fixed: 2026-09-30T09:04:22Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
