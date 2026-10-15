---
phase: 03-king-combat-troops
reviewed: 2026-10-15T19:40:06Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - simulation/squads/separation.gd
  - tests/unit/test_contrast_probe.gd
  - tests/unit/test_separation.gd
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 03: Code Review Report (fifth review, scope: review-fix pass 2)

**Reviewed:** 2026-10-15T19:40:06Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** clean

## Summary

Scope was the two commits of review-fix pass 2 (db5e138 IN-10, 2471438 IN-11). Both fixes do what the fourth review asked, and the new code has no defect I could prove. No finding was opened, so no new id was needed; the disposition ledger keeps its 16 fixed rows and the ids stay CR-01, WR-01 to WR-04, IN-01 to IN-11.

All claims below were checked against the code and by running the allowed commands. `git status` was clean before and after (only this REVIEW.md changes):

- `bash tools/test.sh -gselect=test_contrast_probe`: 10/10, 68 asserts.
- `bash tools/test.sh -gselect=test_separation`: 7/7, 40 asserts.
- `bash tools/lint.sh`: 269 files unchanged, no problems.
- `bash tools/replay.sh` smoke (703 ticks, digest 2599c7c2...f31f) and army (1353 ticks, digest f7a967ed...8959c4): REPLAY_OK, twice each, equal to the committed goldens.

## Verification of the 2 fixes

### IN-10: the "outside the project" path case is really outside - fixed

`tests/unit/test_contrast_probe.gd:108-114,129`. The old variable localized to `res://x.png` (inside the project). The new `in_parent_folder` is `globalize_path("res://").path_join("../outside/x.png").simplify_path()`, and the test asserts before the loop that `localize_path` of it does not begin with `res://`. The case is also in the `bad` list, so it goes through `ContrastProbe.parse_args` and must be rejected with an empty `image`.

I probed `ProjectSettings` with a scratch script (outside the repo) to check the path expression:

- Windows: `globalize_path("res://")` returns `C:/Users/burha/Desktop/Projects/Thronefall-like Game/` (forward slashes, trailing slash). `path_join` copes with the trailing slash. `simplify_path` collapses the `..` and gives `C:/Users/burha/Desktop/Projects/outside/x.png`. `localize_path` returns it unchanged, so the assertion holds. It is absolute, has no `..` segment (so it is rejected by the folder rule, not by the `..` rule), and cannot reach the `res://screenshots/` prefix.
- Linux runner: the same shape with a `/home/runner/work/<repo>/<repo>/` base gives `/home/runner/work/<repo>/outside/x.png`; absolute on Linux too, which is the point of the fix (the literal `C:/Windows` and `/etc` cases are each absolute on one platform only). CI run 38774381177 passed.
- Project at a filesystem root: `simplify_path` clamps an over-reaching `..` instead of keeping it (`C:/../outside/x.png` gives `C:/outside/x.png`, `/../outside/x.png` gives `/outside/x.png`). Both are still absolute and outside `res://`, so the assertion and the rejection still hold; the assertion would only be a false red if a platform returned the `..` unsimplified, and none of the three behaviours probed does.
- Prefix siblings, which the new case does not cover but the production code depends on: `.../Thronefall-like Game-evil/screenshots/a.png` and `.../Thronefall-like Game2/screenshots/a.png` both stay unlocalized (the engine matches the project folder with its trailing slash). An upper-cased spelling of the project path on Windows is also left unlocalized, i.e. rejected, which is the safe direction.

### IN-11: test_separation pinned to radii written in the test, and the seam - fixed

`tests/unit/test_separation.gd:13-16,62-71,138-175` and `simulation/squads/separation.gd:15-25`.

- The inline `UnitDef.new()` / `EnemyDef.new()` set only `radius`. `UnitSystem.spawn` reads `def.max_health` (script default 10, `maxi(.,1)`) and `def.id` (event payload only); `EnemySystem.spawn` reads `def.max_health` (script default 1) and `def.id`. Neither default can change the pinned positions: `separate` and `_separate` filter on `health > 0` (true for both defaults) and feed only `position`, `def.radius` and `id` into `Separation.displacements`. No other def field is read on this path.
- The header claim is true today: `data/units/footman.tres` 0.45, `archer.tres` 0.4, `data/enemies/grunt.tres` 0.5, `ranged.tres` 0.45 equal `FOOTMAN_RADIUS`, `ARCHER_RADIUS`, `GRUNT_RADIUS`, `RANGED_RADIUS`. The footman/archer and grunt/ranged radii differ from each other, so a swapped mapping would still fail the pins. The 7/7 run with unchanged `UNIT_RESULT` / `ENEMY_RESULT` confirms the constants reproduce the captured values.
- `enemies.call("_separate")` stays and is commented as deliberate. A rename makes `call` error and move nothing, so the pinned-position asserts go red; the seam cannot silently pass.
- The new `assert` in `Separation.displacements` (lines 22-25) checks `radii.size() == positions.size() and ids.size() == positions.size()`, with a message that names the routine and the precondition. It is debug-only; the header states the precondition as the durable note, which is the finding's own "or document it" option. `PackedFloat64Array` / `PackedInt64Array` have `size()` like any packed array, and both callers (`unit_system.gd:175-182`, `enemy_system.gd:355-362`) append to the three arrays in one loop, so the sizes are equal by construction. The assert has no side effect on the arithmetic: both replay goldens are unchanged.

## Review of the new code for its own defects

No bug, security gap or quality defect found in the added code. Specifically considered and rejected:

- The new IN-10 case is rejected by the `res://screenshots/` prefix rule rather than by any absolute-path-only branch, so it is a regression guard on `localize_path` leaving outside paths alone, not a discriminator of the `is_absolute_path` branch. That is what the finding asked for, and the inside-the-folder absolute case already covers the accepting side; not worth a finding.
- The assert text and the header note agree; no stale comment (the file-level comment about both systems sharing the routine still matches `unit_system.gd` and `enemy_system.gd`).
- No unused constant, import or helper was introduced (`_unit_def`, `_enemy_def` and the four radius constants are all used).

---

_Reviewed: 2026-10-15T19:40:06Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
