---
phase: 02-night-defense-playtest-gate
reviewed: 2026-10-07T11:26:46Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - data/king/king.tres
  - simulation/defs/king_def.gd
  - tests/unit/test_king_movement_config.gd
  - tests/unit/test_prototype_map_data.gd
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-10-07T11:26:46Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Scope is the incremental diff 55c094f..HEAD (gap-closure plan 02-21: walk 5.0 -> 7.5 m/s, sprint
multiplier 2.4 -> 1.6, ride-time band 20-30 s -> 12-18 s). I read the full diff and the four files,
cross-checked every consumer of `walk_speed` / `sprint_multiplier` (`King.move_speed`,
`tests/e2e/test_king_ride.gd`, `tests/unit/test_playtest_strategies.gd`,
`tools/replay/playtest_bot.gd`, the replay fixture), and ran the two changed suites
(`test_king_movement_config.gd` 9/9, `test_prototype_map_data.gd` 20/20 passing).

Verified correct:

- `king.tres` and the `KingDef` script defaults agree (7.5 / 1.6 / 60.0), and the new
  `test_the_script_defaults_are_the_shipped_movement` pins that agreement.
- 7.5 * 1.6 == 12.0 and 5.0 * 2.4 == 12.0 hold exactly in IEEE doubles (checked), so the
  tolerance-free `assert_eq` in `test_the_sprint_stays_exactly_twelve_metres_per_second` is sound.
- Doc arithmetic is right: 12^2 / (2*60) = 1.2 m, 7.5^2 / 120 = 0.47 m, both under the 2.5 m
  `interaction_radius`; 7.5 / 60 = 0.125 m per physics step is far below the build radius, so no
  trigger tunnelling. 1.5x claims (5.0 -> 7.5, 8 -> 12) are correct.
- `tests/unit/test_prototype_map_data.gd` stays at exactly 20 `func test_` (gdlint cap), the rename
  keeps the test intact, and the 12-18 s band brackets the measured 14.67 s; the band still rejects
  the old 5 m/s (22 s) and rejects walk speeds outside roughly 6.1-9.2 m/s.
- No line over 100 characters in any of the four files. The frozen replay fixture
  (walk 5.0, multiplier 1.6, acceleration 40) does not share state with `king.tres`.
- No bugs, security issues, or logic defects found in the scoped changes.

## Info

### IN-01: Redundant multiplier assertion left inside the "1.5x original sprint" test

**File:** `tests/unit/test_king_movement_config.gd:32-39`
**Issue:** `test_sprint_is_at_least_one_and_a_half_times_the_original_sprint` still opens with
`assert_eq(_def.sprint_multiplier, OWNER_SPRINT_MULTIPLIER, ...)`, which has nothing to do with
the test's name and now partly duplicates `test_the_sprint_stays_exactly_twelve_metres_per_second`
(exact 12.0 implies the 1.6 multiplier at walk 7.5). A future retune that changes only the
multiplier would fail two tests for one cause, and the test named for the 1.5x rule would fail on
a multiplier check rather than the rule it names.
**Fix:** Drop the multiplier `assert_eq` from the 1.5x test (the exact-12 test and
`test_move_speed_sprints_at_walk_speed_times_multiplier` already pin the multiplier path), or move
it into a dedicated multiplier test when the 20-function cap allows. Not urgent.

### IN-02: Script-defaults test covers three of the four movement fields, with no note on the omission

**File:** `tests/unit/test_king_movement_config.gd:80-96`
**Issue:** `test_the_script_defaults_are_the_shipped_movement` checks `walk_speed`,
`sprint_multiplier` and `acceleration` but not `turn_speed`, which the same file treats as a
movement number (`test_turn_speed_is_defined_and_positive`) and which currently also matches
(12.0 in both places). The script default for `turn_speed` can therefore drift from `king.tres`
unnoticed, and a reader cannot tell whether the omission is deliberate (the review context says
the combat defaults max_health/attack_* differ on purpose, but `turn_speed` is not among them).
Separately, the "a walking stop (0.47 m) inside the build radius" claim added to the `acceleration`
doc comment in `simulation/defs/king_def.gd:15` has no test; it is implied by the sprint-stop test
since the walking stop is shorter, so this is cosmetic.
**Fix:** Add a `turn_speed` assertion to the same test (one more `assert_eq(fresh.turn_speed,
_def.turn_speed, ...)`), or add a one-line comment saying the combat fields are excluded on purpose
and `turn_speed` is left out because it is not a playtest-tuned value.

---

_Reviewed: 2026-10-07T11:26:46Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
