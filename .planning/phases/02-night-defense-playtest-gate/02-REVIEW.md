---
phase: 02-night-defense-playtest-gate
reviewed: 2026-10-08T05:19:25Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - simulation/clock/sim_clock.gd
  - simulation/defs/loop_tuning.gd
  - simulation/defs/map_config.gd
  - simulation/night/castle_attack.gd
  - tests/integration/test_balance_acceptance.gd
  - tests/unit/test_castle_attack.gd
  - tests/unit/test_fast_forward_rules.gd
  - tests/unit/test_map_validate_castle.gd
  - tests/unit/test_night_data_contract.gd
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-10-08T05:19:25Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Whole-file review of the castle attack, its validation, the tick conversions, the loop tuning
helpers and the five test scripts. The prior review's six findings (2 warnings, 4 info) were each
re-checked against the current tree; all six still hold. The two headline ones were reproduced with
a headless probe on Godot 4.7.2 (`SimClock.ticks(1e30)` returns 1, `validate()` returns `[]` and
`is_armed()` returns true for a 1e30 interval). No new defects turned up in the shipped tuning
values, the test logic or the loop-tuning helpers. All reviewed test scripts are under the gdlint cap
of 20 `func test_` functions (castle_attack 14, fast_forward_rules 15, map_validate_castle 13,
night_data_contract 12, balance_acceptance 8), so fixes can add tests. No structural findings were
supplied.

## Warnings

### WR-01: A huge finite castle_attack_interval passes validate(), arms the castle and fires it every tick

**File:** `simulation/clock/sim_clock.gd:20-23` (root cause), `simulation/defs/map_config.gd:172-194`, `simulation/night/castle_attack.gd:38-45,74`
**Issue:** The castle's hardening (T-02-33) rejects INF, NaN and sub-step intervals, and the
CastleAttack doc claims neither bad nor unvalidated data can make it fire every tick. A finite but
enormous interval still does. Probe output: `ticks(1e30)=1`, `ticks(1e300)=1`, `ticks(INF)=1`,
`ticks(NAN)=1`. `ceili` overflows on a huge quotient, and the `maxi(..., 1)` floor then swallows the
garbage result. With damage 2, range 22, interval 1e30, `MapConfig.validate()` returned `[]` and
`CastleAttack.is_armed()` returned true. `step()` then sets `_ready_at = tick + 1`, so the castle
shoots every tick, the exact failure the arming guard exists to prevent. A typo such as an extra
exponent digit in `castle_attack_interval` triggers it silently. The same overflow makes
`flight_ticks` return 1 for a speed of 1e-300 or a distance of 1e30, instead of a very long flight.
**Fix:** Saturate the conversion once so every timer benefits, and bound the data:
```gdscript
# sim_clock.gd
const MAX_TICKS: int = 1 << 30
static func ticks(duration: float) -> int:
	if duration <= 0.0:
		return 0
	return clampi(ceili(minf(duration / STEP, float(MAX_TICKS)) - TICK_ROUNDING_SLACK), 1, MAX_TICKS)
```
Apply the same saturation in `flight_ticks`. Add an upper bound (for example
`castle_attack_interval > MAX_CASTLE_INTERVAL_S`, 3600 s) to `_validate_castle_attack()` and to
`is_armed()`. Add `["castle_attack_interval", 1e30]` to DISARMING in test_castle_attack.gd and a
validate case in test_map_validate_castle.gd. NaN input to `ticks` should also be handled
explicitly (`if not duration > 0.0: return 0` makes NaN return 0 rather than 1).

### WR-02: The single-writer scan for Engine.time_scale misses compound assignments and reflective setters

**File:** `tests/unit/test_fast_forward_rules.gd:20` (WRITE_PATTERN), scan at lines 275-286
**Issue:** `Engine\.time_scale\s*=[^=]` only matches a plain `=` followed by one more character.
`Engine.time_scale *= 2.0`, `Engine.time_scale += x`, `Engine.set("time_scale", x)` and a line that
ends right after the `=` do not match, so a second writer added in any of those forms passes the
guard that the controller's doc advertises as "the only writer". The self-check at lines 277-278 only
covers `=` and `==`, so the gap is not noticed.
**Fix:** Match any assignment operator and the reflective setters, for example
`WRITE_PATTERN := "Engine\.time_scale\s*([-+*/%]?=(?!=)|$)|Engine\.set\(\s*[\"']time_scale"`
(or flag every non-comment mention of `time_scale` outside WRITER_PATH, as
test_nothing_under_simulation_mentions_the_time_scale already does for simulation/). Extend the
self-check with `*=`, `+=`, `set(` and end-of-line samples. The test file has room (15 of 20).

## Info

### IN-01: BALANCED_MIN_WINS = 7 is unreachable, and one test name is stale

**File:** `tests/integration/test_balance_acceptance.gd:14,62-66`, `tests/unit/test_night_data_contract.gd:190`
**Issue:** test_balanced_loses_only_seeds_three_and_nine_and_never_before_night_three pins exactly
two losses (8 wins), so the 7-to-8 window in test_balanced_wins_seven_or_eight_of_seeds_one_to_ten
can never fail on the low side and BALANCED_MIN_WINS is dead tolerance. Separately,
`test_the_per_night_totals_are_unchanged_by_the_ranged_type` now pins the whole round-three ramp
(21, 21, 21 on nights 3 to 5), so "unchanged" is stale.
**Fix:** Either drop the win-window test (the exact-seed pin implies it) or keep it and note it as a
looser, redundant guard. Rename the totals test to
`test_the_per_night_totals_match_the_owner_s_wall`.

### IN-02: CastleAttack.is_armed() does not check the projectile speed, contradicting its "unvalidated data" claim

**File:** `simulation/night/castle_attack.gd:38-45`
**Issue:** Probe: with `castle_projectile_speed = NAN`, `validate()` reports it but `is_armed()` is
still true, and `SimClock.flight_ticks(10, NAN)` returns 1 (undefined `ceili(NaN)`), so the arrow
lands next tick whatever the distance. Benign in effect, but it contradicts the doc's "neither bad
nor unvalidated data".
**Fix:** Add `and is_finite(_map.castle_projectile_speed)` to `is_armed()` plus NaN and INF speed
cases in DISARMING, or make `flight_ticks` reject non-finite input.

### IN-03: MapConfig.validate() accepts a NaN or infinite castle_radius and NaN enemy floats

**File:** `simulation/defs/map_config.gd:137,212-247`
**Issue:** Probe: `castle_radius = NAN` and `castle_radius = INF` both validate to `[]`, because
`castle_radius <= 0.0` is false for both. The enemy checks in `_validate_enemy` (`<= 0.0`,
`< 0.0`, `<= attack_range`) have the same hole for NaN. This is the defect class the castle
attack numbers were hardened against.
**Fix:** Reuse the `_castle_number_errors` `is_finite` pattern for `castle_radius` and the enemy
floats (move_speed, attack_interval, radius, ranges, retarget interval, projectile speed).

### IN-04: Orphaned line in the fast_forward_scale doc comment

**File:** `simulation/defs/loop_tuning.gd:54-57`
**Issue:** The reflow left "## Read through" alone on its own line before the
`FastForwardController.scale_for` sentence.
**Fix:** Reflow to "## Read through FastForwardController.scale_for, which clamps it to 1.0 ..
FAST_FORWARD_MAX_SCALE."

---

_Reviewed: 
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
