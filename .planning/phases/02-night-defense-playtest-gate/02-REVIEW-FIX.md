---
phase: 02-night-defense-playtest-gate
fixed_at: 2026-10-08T05:47:58Z
review_path: .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-10-08T05:47:58Z
**Source review:** .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (2 warnings, 4 info; fix_scope all)
- Fixed: 6
- Skipped: 0

## Fixed Issues

### WR-01: A huge finite castle_attack_interval passes validate(), arms the castle and fires it every tick

**Files modified:** `simulation/clock/sim_clock.gd`, `simulation/defs/map_config.gd`, `simulation/night/castle_attack.gd`, `tests/unit/test_sim_clock.gd`, `tests/unit/test_castle_attack.gd`, `tests/unit/test_map_validate_castle.gd`
**Commit:** 7b58ca9
**Applied fix:** `SimClock.ticks` and `flight_ticks` now share one `_whole_ticks` helper that clamps the rounded-up quotient to `[1, MAX_TICKS]` (`MAX_TICKS = 1 << 30`), so a huge or infinite duration saturates instead of overflowing `ceili` into the one-tick floor, and NaN input (and a NaN or non-positive speed) returns 0. The rounding slack and the 1-tick floor are unchanged, so every ordinary finite duration converts exactly as before. `MapConfig` gained `MAX_CASTLE_ATTACK_INTERVAL_S = 3600.0`; `_validate_castle_attack()` reports a longer finite interval and `CastleAttack.is_armed()` refuses to arm above it. The `CastleAttack` doc comment is updated. Tests (written first, seen failing): `test_a_huge_duration_saturates_instead_of_wrapping_to_one_tick`, two new DISARMING cases (1e30 and 3600.5), and `test_a_castle_interval_above_the_longest_allowed_is_reported` (also pins that exactly 3600 is clean). Requires human verification: logic fix (saturating conversion), though both replay goldens are unchanged.

### WR-02: The single-writer scan for Engine.time_scale misses compound assignments and reflective setters

**Files modified:** `tests/unit/test_fast_forward_rules.gd`
**Commit:** 162644d
**Applied fix:** `WRITE_PATTERN` is now `ASSIGN_PATTERN` (`Engine\.time_scale\s*[-+*/%]?=(?!=)`, any assignment operator including one that ends the line) joined with `REFLECT_PATTERN` (`Engine.set(` and `Engine.set_indexed(` with `"time_scale"` or `'time_scale'`). New `test_the_write_pattern_finds_every_form_of_assignment_and_no_read` pins ten write samples (`=`, `*=`, `+=`, `-=`, `/=`, line-ending `=`, both setters) and six read samples (`==`, `!=`, `<=`, `>=`, a plain read, `Engine.get`). A headless probe confirmed the old pattern missed `*=`, `+=`, the line-ending `=` and `Engine.set`. The real scan still reports only `input/fast_forward_controller.gd`. Requires human verification: logic fix (regex).

### IN-01: BALANCED_MIN_WINS = 7 is unreachable, and one test name is stale

**Files modified:** `tests/integration/test_balance_acceptance.gd`, `tests/unit/test_night_data_contract.gd`
**Commit:** 13af2b3
**Applied fix:** Kept the exact-seed pin (`BALANCED_LOST_SEEDS = [3, 9]`) and removed the dead `BALANCED_MIN_WINS` / `BALANCED_MAX_WINS` window. The win test is now `test_balanced_wins_every_seed_it_is_not_pinned_to_lose`: every seed outside the lost set must be won, and the win count must equal `BALANCED_SEEDS.size() - BALANCED_LOST_SEEDS.size()` (8). `test_the_per_night_totals_are_unchanged_by_the_ranged_type` is renamed `test_the_per_night_totals_match_the_owner_s_wall`. Test counts unchanged (8 and 12).

### IN-02: CastleAttack.is_armed() does not check the projectile speed, contradicting its "unvalidated data" claim

**Files modified:** `simulation/night/castle_attack.gd`, `tests/unit/test_castle_attack.gd`
**Commit:** 4b25e89
**Applied fix:** `is_armed()` now also requires a finite `castle_projectile_speed` of 0 or more (0 stays valid: a hit that lands at once). Four DISARMING cases added (NaN, INF, -INF, -1.0), covering both the armed check and the never-fires run. `flight_ticks` already returns 0 for a NaN speed since WR-01. Doc comments updated.

### IN-03: MapConfig.validate() accepts a NaN or infinite castle_radius and NaN enemy floats

**Files modified:** `simulation/defs/map_config.gd`, `tests/unit/test_map_validate_enemies.gd`
**Commit:** 61a918a
**Applied fix:** `castle_radius` that is not finite is reported as "not finite", once. `_validate_enemy` checks the eight enemy floats (move_speed, radius, attack_range, attack_interval, aggro_range, leash_range, retarget_interval_seconds, projectile_speed) with `is_finite`, reports each non-finite one, and returns early so the range comparisons never double-report. Two new tests cover INF, -INF and NaN for the radius and for every enemy field, each reporting exactly one error that names the field and says "finite". Tower tier floats were not in the finding and are untouched.

### IN-04: Orphaned line in the fast_forward_scale doc comment

**Files modified:** `simulation/defs/loop_tuning.gd`
**Commit:** 16628a4
**Applied fix:** Rejoined "Read through FastForwardController.scale_for, which clamps it to 1.0 .. FAST_FORWARD_MAX_SCALE." onto one line. No shipped data value changed.

## Verification

Run in the main checkout on branch gsd/phase-01-foundation-day-loop (no worktree), after all six commits:

- `bash tools/lint.sh`: gdformat 167 files unchanged, gdlint no problems.
- Full suite `bash tools/test.sh`: 95 scripts, 836 tests, 836 passing, 0 failing, 9076 asserts (831 before; +5 tests: test_sim_clock +1, test_fast_forward_rules +1, test_map_validate_castle +1, test_map_validate_enemies +2). Script test-function counts stay under the gdlint cap of 20 (fast_forward_rules is now 16).
- Replay goldens, `--twice`: `REPLAY_OK scenario=smoke ticks=703 digest=2599c7c2...` (matches tests/golden/smoke.json) and `REPLAY_OK scenario=full_idle ticks=5140 digest=bb9059c8...`, both unchanged.

No shipped data value was touched; 02-SECURITY.md was not edited (the T-02-33 claim in the CastleAttack doc comment now lists WR-01 and IN-02 and is truthful).

---

_Fixed: 2026-10-08T05:47:58Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
