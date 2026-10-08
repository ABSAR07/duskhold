---
phase: 02-night-defense-playtest-gate
fixed_at: 2026-10-08T05:05:00Z
review_path: .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 2: Code Review Fix Report

**Fixed at:** 2026-10-08T05:05:00Z
**Source review:** .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### IN-01: Redundant multiplier assertion left inside the "1.5x original sprint" test

**Files modified:** `tests/unit/test_king_movement_config.gd`
**Commit:** eeafe56
**Applied fix:** Removed the `sprint_multiplier` `assert_eq` from
`test_sprint_is_at_least_one_and_a_half_times_the_original_sprint`, so that test now checks only the
1.5x rule it is named for. Also removed the `OWNER_SPRINT_MULTIPLIER` constant, which had no other
use. The multiplier stays pinned by `test_the_sprint_stays_exactly_twelve_metres_per_second` and
`test_move_speed_sprints_at_walk_speed_times_multiplier`. Test count in the file is unchanged (9).

### IN-02: Script-defaults test covers three of the four movement fields, with no note on the omission

**Files modified:** `tests/unit/test_king_movement_config.gd`
**Commit:** 00b9894
**Applied fix:** Added `assert_eq(fresh.turn_speed, _def.turn_speed, ...)` to
`test_the_script_defaults_are_the_shipped_movement`, so all four movement fields (walk speed, sprint
multiplier, acceleration, turn speed) are pinned between the `KingDef` script defaults and
`data/king/king.tres`. The doc comment in `simulation/defs/king_def.gd` was left alone (cosmetic
note in the finding, no gameplay value changed).

## Verification

Run in the main checkout (no worktree; `workflow.use_worktrees` pinned off by the caller), so the
numbers are reproducible from the tree as it stands.

- `bash tools/test.sh -gselect=test_king_movement_config.gd`: 9/9 passing after each fix.
- `bash tools/lint.sh` (gdlint + gdformat check): clean after each fix (167 files unchanged).
- Full suite `bash tools/test.sh` after both fixes: 95 scripts, 831 tests, 831 passing, 0 failures,
  8947 asserts.

---

_Fixed: 2026-10-08T05:05:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
