---
phase: 02-night-defense-playtest-gate
reviewed: 2026-10-07T00:45:45Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - data/maps/prototype_map.tres
  - input/fast_forward_controller.gd
  - simulation/defs/loop_tuning.gd
  - simulation/defs/map_config.gd
  - simulation/events/sim_events.gd
  - simulation/night/castle_attack.gd
  - tests/e2e/test_fast_forward.gd
  - tests/integration/test_balance_acceptance.gd
  - tests/unit/test_castle_attack.gd
  - tests/unit/test_fast_forward_rules.gd
  - tests/unit/test_fast_forward_toggle.gd
  - tests/unit/test_fast_forward_toggle.gd.uid
  - tests/unit/test_input_map.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_map_validate_castle.gd
  - tests/unit/test_night_data_contract.gd
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 02: Code Review Report (incremental, since 3517f83)

**Reviewed:** 2026-10-07T00:45:45Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Reviewed the round-3 gap-closure changes: castle reach 22 m / arrows 27 m/s with the hardened
arming and validation (02-17), the night fast-forward toggle with its re-arm guard (02-18) and
the "full wall" night counts with the balanced-bot pins (02-19). The toggle logic
(`_press_counts`, the latch, the reset inside the phase-change step, the `_exit_tree` restore)
traced clean for key hold, sub-frame tap, day-to-night held key, trigger pull and trigger hover.
The night totals in prototype_map.tres match the pins (5, 12, 21, 21, 21, 22, 27, 33), and the
castle doc claims (22/27 s edge flight of 25 ticks, grunt and skirmisher kill timing, House plot
coverage) check out against the shipped data. No structural findings were supplied.

The WR-02 hardening is incomplete: the one remaining way to make the castle fire every tick (a
huge finite interval) still passes both validate() and is_armed(). I reproduced it headless.
The "single writer of Engine.time_scale" scan can also be bypassed by a compound assignment.

## Warnings

### WR-01: A huge finite castle_attack_interval passes validate(), arms the castle and fires it every tick

**File:** `simulation/defs/map_config.gd:172-194`, `simulation/night/castle_attack.gd:38-45`, root cause `simulation/clock/sim_clock.gd:20-23`
**Issue:** The WR-02 fix rejects INF, NaN and sub-step intervals, and the doc claims "neither bad nor
unvalidated data can make the castle fire every tick". A finite but enormous interval still does.
`SimClock.ticks(1e30)` overflows `ceili` and returns 1 (the `maxi(..., 1)` floor swallows the
overflowed value). Probe run with Godot 4.7.2 headless on a map with damage 2, range 22 and
interval 1e30: `ticks(1e30)=1`, `ticks(1e300)=1`, `validate()` returned `[]`, `is_armed()` returned
true. `CastleAttack.step` then sets `_ready_at = tick + 1`, so the castle shoots every tick, which is
the exact failure T-02-33 / WR-02 exist to prevent. A typo such as `castle_attack_interval = 1e30` or
an unvalidated resource reaches this silently. The same overflow makes any projectile speed tiny
enough (1e-300) land in 1 tick instead of never.
**Fix:** Saturate the conversion once so every timer benefits, and bound the data:
```gdscript
# sim_clock.gd
const MAX_TICKS: int = 1 << 30
static func ticks(duration: float) -> int:
	if duration <= 0.0:
		return 0
	return clampi(ceili(minf(duration / STEP, float(MAX_TICKS)) - TICK_ROUNDING_SLACK), 1, MAX_TICKS)
```
and add an upper bound (for example `castle_attack_interval > MAX_CASTLE_INTERVAL_S`, 3600 s) to
`_validate_castle_attack()` and to `is_armed()`, plus a DISARMING case (`["castle_attack_interval", 1e30]`)
in test_castle_attack.gd and a validate case in test_map_validate_castle.gd.

### WR-02: The single-writer scan for Engine.time_scale misses compound assignments and set()

**File:** `tests/unit/test_fast_forward_rules.gd:20` (WRITE_PATTERN), scan at lines 275-286
**Issue:** `Engine\.time_scale\s*=[^=]` only matches a plain `=`. `Engine.time_scale *= 2.0`,
`Engine.time_scale += x` and `Engine.set("time_scale", x)` are not matched (after the name there is a
`*`, `+` or `(`, not an `=`), so a second writer of the time scale added that way passes the guard
that the controller doc advertises as "the only writer". The same pattern then requires one character
after the `=`, so a line that ends right after it also slips through.
**Fix:** Match any assignment operator and the reflective setters, for example
`WRITE_PATTERN := "Engine\.time_scale\s*([-+*/%]?=(?!=)|\b)"` (or simply flag every non-comment
occurrence of `time_scale` outside WRITER_PATH, as test_nothing_under_simulation_mentions_the_time_scale
already does for simulation/), and extend the self-check lines 277-278 with `*=`, `+=` and `set(` samples.

## Info

### IN-01: BALANCED_MIN_WINS = 7 is unreachable and one test name is stale

**File:** `tests/integration/test_balance_acceptance.gd:14,62-66`, `tests/unit/test_night_data_contract.gd:313`
**Issue:** test_balanced_loses_only_seeds_three_and_nine pins exactly two losses (8 wins), so the
7-or-8 window in test_balanced_wins_seven_or_eight_of_seeds_one_to_ten can never fail on the low side
and BALANCED_MIN_WINS is dead tolerance. Separately, `test_the_per_night_totals_are_unchanged_by_the_ranged_type`
now pins the whole new ramp (21 21 21 on nights 3 to 5), so "unchanged" is stale.
**Fix:** Drop the two tests' overlap (keep the exact-seed pin and derive the win count, or keep 7 to 8 and
remove the seed pin if seed-exactness is not wanted) and rename the totals test to
`test_the_per_night_totals_match_the_owner_s_wall`.

### IN-02: CastleAttack.is_armed() does not check the projectile speed, unlike the doc's "unvalidated data" claim

**File:** `simulation/night/castle_attack.gd:38-45`
**Issue:** A NaN `castle_projectile_speed` (reported by validate()) still arms the castle, and
`SimClock.flight_ticks(d, NAN)` returns 1 (probe run) from an undefined `ceili(NaN)`, so the arrow
lands next tick regardless of distance. Benign in effect, but it contradicts "neither bad nor
unvalidated data".
**Fix:** Add `and is_finite(_map.castle_projectile_speed)` to is_armed() and a DISARMING case for
NaN/INF speed, or make flight_ticks reject non-finite input.

### IN-03: MapConfig.validate() accepts a NaN castle_radius (same defect class as the fixed WR-02)

**File:** `simulation/defs/map_config.gd:137` (outside the incremental diff, noted for the next pass)
**Issue:** `castle_radius <= 0.0` is false for NaN, so a NaN radius validates clean; the enemy fields in
`_validate_enemy` (`<= 0.0` / `< 0.0` checks) have the same hole.
**Fix:** Reuse `_castle_number_errors`-style `is_finite` checks for radius and the enemy floats.

### IN-04: Orphaned line in the fast_forward_scale doc comment

**File:** `simulation/defs/loop_tuning.gd:54-57`
**Issue:** The reflow left "## Read through" alone on its own line before the `FastForwardController.scale_for` sentence.
**Fix:** Reflow to "## Read through FastForwardController.scale_for, which clamps it to 1.0 .. FAST_FORWARD_MAX_SCALE."

---

_Reviewed: 2026-10-07T00:45:45Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
