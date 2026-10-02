---
phase: 01-foundation-day-loop
reviewed: 2026-10-02T20:50:30Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - data/tuning/loop_tuning.tres
  - input/build_hold_controller.gd
  - presentation/vfx/coin_drip_vfx.gd
  - simulation/defs/loop_tuning.gd
  - tests/e2e/e2e_support.gd
  - tests/e2e/test_build_hold_long.gd
  - tests/e2e/test_build_hold_long.gd.uid
  - tests/e2e/test_coin_drip_burst.gd
  - tests/e2e/test_hold_pacing_sandbox.gd
  - tests/unit/test_coin_drip_flight.gd
  - tests/unit/test_e2e_support_tuning.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_loop_tuning_curve.gd
  - tools/sandbox/hold_pacing_sandbox.gd
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 1: Code Review Report (gap-closure plans 01-17 and 01-18, G-01-59)

**Reviewed:** 2026-10-02T20:50:30Z
**Depth:** standard
**Files Reviewed:** 14

## Summary

I reviewed the uncapped, accelerating build hold (floor 0.05 s, `max_build_hold_seconds = 0.0`) across
the pure schedule in `LoopTuning`, the hold controller, the coin VFX, the shipped data, the shared
test support, the rewritten long-hold and burst suites, and the sandbox. I found no production
defects.

Checked and found correct:

- `coin_due_seconds` and `coin_interval` are monotonic and sanitised. The uncapped path returns the
  plain running sum, and the dormant capped path still clamps every coin whose sum reaches the cap.
  The `pow(decay, coin_index - steady)` exponent is always at least 1 there, so a decay of 0 never
  hits `pow(0, 0)`.
- `_advance_hold` checks release, range and day state before paying any coin, so a release on the
  completing frame still refunds (D-06). One `BuildIntent` is sent, on the finish frame.
- The stepped tests are deterministic. `begin_stepped_hold` takes the controller's own processing
  away, so the `_was_pressed` edge fallback starts the hold on the zero step. `STEP_S` (1/64) is
  exact in binary and below the 0.05 s floor, so at most one coin is paid per step. Tests that
  step by `coin_due_seconds(n)` or `build_hold_seconds(n)` compare against the value the controller
  computes itself, so they have no rounding edge.
- Hand arithmetic matches the owner table: the floor is first reached at coin 18 (coin 17 is
  0.05147 s), and a 3-coin overlap bound at 0.12 s minimum flight against 0.05 s gaps holds.
- `test_build_hold_long.gd.uid` is tracked and carries the old `cap` file's uid, and nothing in code
  or tests still references `test_build_hold_cap`.
- The O(coins paid) cost of `coin_due_seconds` is the recorded, accepted risk (T-01-27 / AR-06). I
  found nothing beyond that analysis.

Previous report: WR-01, WR-02, IN-01 and IN-04 are closed. IN-02 and IN-03 still apply and are
re-reported below as IN-01 and IN-02 with current line numbers.

## Warnings

### WR-01: The "helper is uncapped" test cannot fail, so the cap guard in `flat_drip_tuning` is unpinned

**File:** `tests/unit/test_e2e_support_tuning.gd:19-23` (guards `tests/e2e/e2e_support.gd:49`)
**Issue:** `flat_drip_tuning` promises independence from "any cap a later retune might set", and
`test_a_long_hold_is_not_capped` is the only test of that line. The shipped cap is `0.0`, so the
helper's `tuning.max_build_hold_seconds = 0.0` writes the value that is already there. Deleting
that line leaves every test in the file green. The decay line is pinned by the flat-interval test,
but the cap line is not, so the property the docstring advertises is unverified until someone
actually sets a cap, which is when it would matter.
**Fix:** Let the helper take its base from a parameter so a test can feed it a capped tuning
without touching the cached resource:

```gdscript
static func flat_drip_tuning(seconds_per_coin: float, base: LoopTuning = null) -> LoopTuning:
	var source: LoopTuning = base if base != null else load(TUNING_PATH)
	var tuning: LoopTuning = source.duplicate(true)
	# ... same three assignments
```

```gdscript
func test_a_long_hold_is_not_capped_even_from_a_capped_base() -> void:
	var capped: LoopTuning = LoopTuning.new()
	capped.max_build_hold_seconds = 1.0
	var tuning: LoopTuning = E2eSupport.flat_drip_tuning(PACE_S, capped)
	assert_almost_eq(tuning.build_hold_seconds(COST_CHECKED), PACE_S * COST_CHECKED, 0.0001)
```

### WR-02: A shipped-data test asserts a property the design deliberately does not hold at the floor

**File:** `tests/unit/test_coin_drip_flight.gd:69-80` (premise in the header, lines 2-6)
**Issue:** `test_every_shipped_coin_lands_before_the_next_one_leaves` requires
`flight_seconds_for(gap) < gap` for every coin of every shipped tier. `MIN_FLIGHT_SECONDS` (0.12 s)
makes that false once a gap drops below about 0.133 s, which is coin 8 of any tier. It passes today
only because the dearest shipped tier is 6 coins (Tower II). The same file's last test, and the
VFX header, state that overlap at the floor is intended, and the 15/30/50-coin sandbox tiers
overlap by design. The first shipped tier of 8 or more coins (likely when later phases add
buildings) turns this test red even though nothing regressed, and the failure message ("coin 7 of
an 8-coin tier lands before coin 8 leaves") points at the VFX rather than at the stale premise.
**Fix:** Pin only what is true at any cost, for example restrict the loop to coins whose gap is
above the minimum-flight break-even, and say so:

```gdscript
var break_even_s: float = CoinDripVfx.MIN_FLIGHT_SECONDS / CoinDripVfx.FLIGHT_FRACTION_OF_INTERVAL
...
if gap_s > break_even_s:
	assert_lt(CoinDripVfx.flight_seconds_for(gap_s), gap_s, "...")
```

The airborne-bound test already covers the floor region.

## Info

### IN-01: Tautological ceiling test, and a constant referenced only by tests (open from the previous IN-02)

**File:** `tests/unit/test_coin_drip_flight.gd:60-66`, `simulation/defs/loop_tuning.gd:12`
**Issue:** `test_the_ceiling_is_derived_from_the_d05_bound` asserts that `MAX_FLIGHT_SECONDS` equals
`FLIGHT_FRACTION_OF_INTERVAL * LoopTuning.COIN_DRIP_INTERVAL_MAX_S`, which is the constant's own
definition (`coin_drip_vfx.gd:26`), so it can never fail. `test_a_huge_gap_flies_for_the_ceiling`
compares against the same constant, so a wrong ceiling would slip through both.
`COIN_DRIP_INTERVAL_MIN_S` is still read only by the contract test.
**Fix:** Replace it with a value check, for example
`assert_almost_eq(CoinDripVfx.flight_seconds_for(HUGE_GAP_S), 0.9 * 0.3, EPSILON)`, using the D-05
number as an explicit literal pin.

### IN-02: Delayed burst and refund coins sit visible and stacked before they launch (open from the previous IN-03)

**File:** `presentation/vfx/coin_drip_vfx.gd:94-107, 126-132, 141-143`
**Issue:** `_spawn_coin` adds the coin at its start position at once and `_fly` then waits
`tween_interval(delay)`, up to `BURST_WINDOW_SECONDS` (0.3 s). A later coin of a same-frame group
(or of a refund) is therefore drawn, stationary and stacked on the king (or the spot), until its
turn. With the floor now 0.05 s and a long frame paying several coins, this is the visible
"coins hidden inside the king" read the staggering is meant to avoid.
**Fix:** In `_fly`, when `delay > 0.0` set `coin.visible = false` before the interval and add
`tween.tween_callback(coin.set_visible.bind(true))` after it. `live_coin_count()` is unaffected.

### IN-03: The sandbox's starting gold covers one plot's upgrade chain, but the map has five House plots

**File:** `tools/sandbox/hold_pacing_sandbox.gd:16-17, 54-58` (mirrored in `tests/e2e/test_hold_pacing_sandbox.gd:14-20`)
**Issue:** Starting gold is the sum of the three repriced tiers plus 5 (100), but the House def is
shared by `house_1` to `house_5`, and every plot pays the repriced cost. Building tier I on four
other plots (15 each) leaves too little for the 50-coin tier II or III on the plot the owner wants
to feel, and `hold_denied` fires instead. The tool exists to feel the long holds, so a stray build
can block it. The test pins "enough gold for all three tiers", which holds only for one plot.
**Fix:** Either size the gold by plot count (`total * house_plot_count + GOLD_MARGIN`, counting
`config.spots` with `building_id == HOUSE_ID`), or say in the class comment and startup line that
the gold covers one plot's chain.

---

_Reviewed: 2026-10-02T20:50:30Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
