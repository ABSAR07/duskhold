---
phase: 01-foundation-day-loop
reviewed: 2026-10-02T13:15:07Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - data/tuning/loop_tuning.tres
  - input/build_hold_controller.gd
  - presentation/vfx/coin_drip_vfx.gd
  - simulation/defs/loop_tuning.gd
  - tests/e2e/e2e_support.gd
  - tests/e2e/test_build_hold_cap.gd
  - tests/e2e/test_build_hold_cap.gd.uid
  - tests/e2e/test_build_hold_timing.gd
  - tests/e2e/test_coin_drip.gd
  - tests/e2e/test_coin_drip_burst.gd
  - tests/e2e/test_coin_drip_burst.gd.uid
  - tests/e2e/test_debug_overlay_toggle.gd
  - tests/e2e/test_hold_pacing_sandbox.gd
  - tests/e2e/test_hold_pacing_sandbox.gd.uid
  - tests/e2e/test_spot_label.gd
  - tests/e2e/test_start_night_hold.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/e2e/test_walking_skeleton.gd
  - tests/integration/test_build_hold_refund.gd
  - tests/unit/test_coin_drip_flight.gd
  - tests/unit/test_coin_drip_flight.gd.uid
  - tests/unit/test_e2e_support_tuning.gd
  - tests/unit/test_e2e_support_tuning.gd.uid
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_loop_tuning_curve.gd
  - tests/unit/test_loop_tuning_curve.gd.uid
  - tools/sandbox/hold_pacing_sandbox.gd
  - tools/sandbox/hold_pacing_sandbox.gd.uid
  - tools/sandbox/hold_pacing_sandbox.tscn
  - tools/screenshot/shot_scenarios.gd
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 1: Code Review Report (gap-closure plans 01-14 to 01-16, G-01-58)

**Reviewed:** 2026-10-02T13:15:07Z
**Depth:** standard
**Files Reviewed:** 30

## Summary

I reviewed the diff `fe3dc81..HEAD` for the accelerating, capped build hold: the controller, the pure
schedule helpers in `LoopTuning`, the coin VFX, the tuning data, the test fixtures and the sandbox.
I traced the hold loop by hand, including the arithmetic of the owner table, and also re-ran
`tools/lint.sh` (clean, 84 files). I found no production defects in the hold logic.

Checked and found correct:

- `coin_due_seconds` is monotonic. Every coin whose running sum reaches the cap returns exactly the
  cap, so one `_hold_elapsed >= due` comparison pays them all in the cap frame. The
  `LoopTuning.coin_due_seconds` loop is bounded by about cap / floor iterations.
- The release, range and day checks run before any coin in `_advance_hold`, so a release on the cap
  frame still refunds (D-06). The single `BuildIntent` goes out once, on the finish frame.
- The sanitising in `coin_interval` guards the zero, negative, decay-above-one and floor-above-first
  cases. The curve numbers (0.5, 0.725, 0.9275, ..., 2.2055 s, coin 24 last before the cap) match
  hand arithmetic.
- The new `.gd.uid` files are all present and tracked. The `tools/*` export exclusion covers the
  sandbox.

Verification of the two review claims:

- **WR-01 (hold timing on the hold clock): confirmed closed.** `test_build_hold_timing.gd` stamps
  coins with `BuildHoldController.get_hold_elapsed()`, never wall time. It also cross-checks that
  clock against an independent `process_frame` accumulator. Real time now only bounds the
  `wait_until` timeouts.
- **IN-02 (flight ceiling derived, not duplicated): confirmed closed.** `MAX_FLIGHT_SECONDS` is
  `FLIGHT_FRACTION_OF_INTERVAL * LoopTuning.COIN_DRIP_INTERVAL_MAX_S`. No `0.27` literal remains.
  It derives from D-05's documented upper bound, not from the live tuned interval. That is
  consistent with the contract test that pins the shipped interval inside that range.

The remaining findings are test robustness and maintainability, not behaviour bugs.

## Warnings

### WR-01: New scene tests still assume no single frame is longer than a few hundred milliseconds

**File:** `tests/e2e/test_build_hold_cap.gd:147-170`, `tests/e2e/test_coin_drip_burst.gd:307-320`
**Issue:** WR-01 removed wall-clock measurement from the timing test, but these new tests keep an
implicit dependence on frame length.

- `test_releasing_just_before_the_cap_refunds_everything` polls `_clock_reached(cap - 0.3)` once per
  frame, then releases. If a single frame has a delta of 0.3 s or more, the hold clock jumps from
  below cap - 0.3 straight past the cap. The controller then completes and builds, and the test
  fails on `hold_completed` or `paid < PRICEY_COST`. A 300 ms stall is plausible on a loaded CI
  runner (shader compile, GC, antivirus), and the stall would be the test's fault, not the game's.
- `test_a_normal_drip_launches_immediately` asserts the group is exactly one coin. A frame delta of
  0.25 s or more after the first frame of the hold pays two coins in one frame, and the group size
  becomes 2.
- `test_a_huge_rush_draws_only_the_visual_cap` bounds `live_coin_count()` by `MAX_BURST_COINS + 2`.
  The `2` rests on the 0.08 s floor and the 0.12 s minimum flight at 60 fps frame granularity, not
  on the code.

**Fix:** Make each test self-checking against the observed frame. For the release test, read the
last frame delta and skip with `pending` or re-run when `delta > RELEASE_BEFORE_CAP_S`. Better, drop
the poll and drive the controller deterministically by calling `_process(delta)` in fixed steps on
the controller (the hold clock is frame-delta based, so this is exact). For the group-size test,
assert `delays[0] == 0.0 and delays.size() <= 2`, or compare against the number of coins paid in
that frame (`_hold.get_coins_paid()`).

### WR-02: A cap of zero silently removes the hold cap, and the shipped data is only guarded for the cap

**File:** `simulation/defs/loop_tuning.gd:28-30, 44-53, 62-67`
**Issue:** `max_build_hold_seconds <= 0` means "no cap". A mistyped `0` or a lost field in
`loop_tuning.tres` therefore reintroduces gap G-01-58 (an unbounded hold) with no error or warning.
The contract test `test_shipped_cap_is_set_and_at_most_the_owner_maximum` does guard the shipped
value. Nothing guards the other sanitised fields: `coin_drip_decay`, `coin_drip_min_interval` and
`coin_drip_steady_coins` are clamped silently. A shipped decay of `1.5` or a floor above the first
interval would pass every test except the incidental acceleration check, and would flatten the curve
without any signal. There are also no `@export_range` hints, so the inspector accepts nonsense
values.

**Fix:** Add contract assertions that the shipped data is already in the sane range, so sanitising
is never what makes it valid:

```gdscript
func test_shipped_pacing_fields_are_already_in_range() -> void:
	var tuning: LoopTuning = _tuning()
	assert_gt(tuning.coin_drip_decay, 0.0)
	assert_lt(tuning.coin_drip_decay, 1.0)
	assert_gte(tuning.coin_drip_steady_coins, 1)
	assert_gt(tuning.coin_drip_min_interval, 0.0)
	assert_lte(tuning.coin_drip_min_interval, tuning.coin_drip_interval)
```

Optionally add `@export_range` hints on the five pacing fields.

## Info

### IN-01: Hard-coded pacing numbers in comments will drift from the data (D-09)

**File:** `input/build_hold_controller.gd:4-5`, `presentation/vfx/coin_drip_vfx.gd:3-6, 32-33`,
`simulation/defs/loop_tuning.gd:5-8`
**Issue:** The doc comments state "0.25 s", "3 s" and "0.08 s" as facts. D-09 puts these numbers in
`loop_tuning.tres` precisely so they can be retuned at the playtest gate. After a retune these
comments become wrong with no test to flag them.
**Fix:** Say "the tuned first interval" and "the tuned cap" in comments, and keep the numbers only
in the `.tres` and the tuning doc.

### IN-02: Tautological and redundant test assertions

**File:** `tests/unit/test_coin_drip_flight.gd:200-206`, `tests/e2e/test_build_hold_timing.gd:140-148`
**Issue:**

- `test_the_ceiling_is_derived_from_the_d05_bound` asserts that a constant equals the expression it
  is defined as, so it can never fail. It does not guard IN-02. The real guard is that no literal
  exists, which a test cannot see.
- `test_house_one_hold_lasts_at_least_the_minimum` repeats what
  `test_shortest_shipped_hold_is_at_least_the_minimum` in the contract test already pins from the
  data, and the last-coin stamp it uses is the controller's own bookkeeping.

**Fix:** Replace the first with a behavioural check, for example that `flight_seconds_for(0.3)`
returns `0.9 * 0.3` and that a gap above `COIN_DRIP_INTERVAL_MAX_S` is clamped. Drop or merge the
second. Also note that `LoopTuning.COIN_DRIP_INTERVAL_MIN_S` is only referenced by tests.

### IN-03: Delayed burst and refund coins are visible, stacked, before they launch

**File:** `presentation/vfx/coin_drip_vfx.gd:92-102, 126-141`
**Issue:** `_spawn_coin` adds the coin at its start position immediately, and `_fly` then waits
`tween_interval(delay)` (up to `BURST_WINDOW_SECONDS` = 0.3 s). The delayed coins therefore sit
visible and stacked at the king (burst) or at the spot (refund) until their turn, which defeats part
of the staggered, one-by-one read that the stagger is for. The refund path had the same behaviour
before this change, so this is inherited, but the burst makes it more visible (up to 12 coins).
**Fix:** Set `coin.visible = false` when `delay > 0.0` and add
`tween.tween_callback(coin.set_visible.bind(true))` after the interval. The count semantics of
`live_coin_count()` are unchanged.

### IN-04: Duplicated scaffolding and literals across the new tests and sandbox test

**File:** `tests/e2e/test_build_hold_cap.gd:47-72`, `tests/e2e/test_coin_drip_burst.gd:215-233`,
`tests/e2e/test_hold_pacing_sandbox.gd:78-79`
**Issue:**

- `_focused`, `_tier_built` and the "stand at the plot" setup are copied between the cap and burst
  tests, and `PRICEY_COST`, `GOLD_MARGIN`, `NEAR_OFFSET` and `SPOT` are redeclared in each.
- The sandbox test re-types `15, 30, 50` and `15 + 30 + 50 + 5` instead of reading
  `HoldPacingSandbox.SANDBOX_HOUSE_COSTS` and `GOLD_MARGIN`. This is deliberate as a pin, but the
  gold figure is derived and can drift out of step when the sandbox constants change.
**Fix:** Move the stand-at-plot helper into `E2eSupport`. Compute `EXPECTED_GOLD` from the
sandbox's own constants, keeping `EXPECTED_COSTS` as the literal pin.

---

_Reviewed: 2026-10-02T13:15:07Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
