---
phase: 03-king-combat-troops
reviewed: 2026-10-14T06:19:41Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - .github/workflows/ci.yml
  - input/command_key_controller.gd
  - input/ground_pick.gd
  - input/pad_cursor_controller.gd
  - input/selection_controller.gd
  - presentation/buildings/models/archery_range_t1.tscn
  - presentation/buildings/models/barracks_t1.tscn
  - presentation/buildings/models/barracks_t2.tscn
  - simulation/commands/command_processor.gd
  - simulation/defs/map_config.gd
  - simulation/night/enemy_system.gd
  - simulation/squads/separation.gd
  - simulation/squads/separation.gd.uid
  - simulation/squads/squad_system.gd
  - simulation/squads/unit_system.gd
  - tests/e2e/test_command_keys.gd
  - tests/e2e/test_mouse_commands.gd
  - tests/e2e/test_pad_cursor.gd
  - tests/e2e/test_start_night_plate.gd
  - tests/integration/test_balance_value_metric.gd
  - tests/unit/test_contrast_probe.gd
  - tests/unit/test_contrast_probe.gd.uid
  - tests/unit/test_ground_pick.gd
  - tests/unit/test_separation.gd
  - tests/unit/test_separation.gd.uid
  - tests/unit/test_squad_bad_unit_health.gd
  - tests/unit/test_squad_bad_unit_health.gd.uid
  - tests/unit/test_squad_queue.gd
  - tools/replay/balance_report.gd
  - tools/screenshot.sh
  - ui/hud/hud.tscn
  - ui/hud/toast.gd
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: issues_found
---

# Phase 3: Code Review Report (fourth review, scope: review-fix pass 1, commits 56b2828..e01971e)

**Reviewed:** 2026-10-14T06:19:41Z
**Depth:** standard
**Files Reviewed:** 32
**Status:** issues_found (two info items, no blocker, no warning)

## Summary

This review covers the 13 commits of review-fix pass 1. I read the full diff `4da6799..abdf730` for every file in scope, then read the surrounding code each change calls (SquadSystem `_run_queue` / `_begin` / `apply_order` / `orders_of` / `_raise_unit` / `_trickle`, UnitSystem, EnemySystem `remove_dead`, CommandProcessor `_squad_order_rejection`, the three order controllers, Toast, the contrast probe, `tools/screenshot.sh` end to end). I found no incorrect behaviour, no security defect and no regression in the new code. All 13 fixes are correct as described. `bash tools/lint.sh` is clean (269 files). I re-ran `test_squad_bad_unit_health` and `test_contrast_probe`: both pass. I did not re-run the full suite or the goldens (the orchestrator did).

Two info items follow: a test case in the WR-04 contrast-probe test that is mislabelled and does not test what its name says (the intent is covered by other cases), and a characterization test that is coupled to shipped tuning data.

## Verification of the 13 fixes

**CR-01 (unbounded spawn loop): correctly fixed.** `_fill` and `restore_for_dawn` now iterate `range(maxi(cap - living, 0))`, evaluated once, so each loop raises at most the number of missing seats whatever the unit definition. `UnitSystem.spawn` and `heal_to_full` floor the stored health at `maxi(max_health, 1)`, so the raised units also count as living (the squad really fills, `_lowest_free_slot` sees them, the trickle stops). The only other `while` in the squad code (`_lowest_free_slot`) is bounded by the taken set; `_trickle` raises one unit per call. I checked the same data fault on the enemy side: an enemy with `max_health <= 0` spawns dead and `EnemySystem.remove_dead` removes anything with `health <= 0`, so it cannot hang a loop (not a finding). Nothing in `presentation/` or `ui/` reads a unit's `max_health`, so the floor cannot make a bar or ratio disagree. `MapConfig.validate()` still reports the bad value (the advisory rule stays). The new test covers 0, -5 and the dawn restore, and passes.

**WR-02 (screenshot wrapper blind to script errors): correctly fixed.** The pipeline `... 2>&1 | tee "${shot_log}"` is followed directly by `status="${PIPESTATUS[0]}"`, so the exit status is Godot's (or `timeout`'s 124), not `tee`'s. The script uses `set -u` only (no `-e`, no `pipefail`), so a failing shot still reaches the status check. `build/` is created before the loop. The filter is the same as in `tools/replay.sh`. `ci.yml` uploads `build/screenshot-*.log` under `if: always()` next to the existing import log (the glob overlaps the import log; upload-artifact de-duplicates). The "33 scripted shots" comment still matches `ALL_SHOTS` (15 + 12 + 6).

**WR-03 (refused squad order silent): correctly fixed.** All three call sites that build a `SquadOrderIntent` in shipped code (`CommandKeyController._give`, `SelectionController._order`, `PadCursorController._confirm`) run the `submit` result through `Toast.refusal_text`; the only other builder is the playtest bot. `_every_queue_is_closed` refuses only when every ordered squad's queue ends in a terminal order, and returns false for an empty queue, so a mixed selection goes through. It agrees with `apply_order`, which skips a squad for a queued order when `squad.queue.back()` is terminal (`orders_of` returns exactly `squad.queue`), so no closed squad is ever appended to. An empty id list cannot reach it (NO_SQUADS is checked first) and would return false anyway. The mixed-selection behaviour matches the owner's pin and the UI-SPEC row. Tests: the unit pair in test_squad_queue, the Shift+F/H/R case, the mixed case, the click case and the RT case. In each e2e test the action is released before the assertions run, so a failing assertion cannot leave Shift held for the next test.

**WR-04 (contrast probe untested): correctly fixed**, with one mislabelled case (IN-10). The measurement cases (black outline about 6.06, grey about 1.14, no fill, all fill, rect outside) and the WCAG constants are right by hand calculation, and the path cases include the ones that matter: `screenshots/../screenshots/a.png` is the case that only the `..` guard rejects, and `res://screenshots_evil/x.png` pins the sibling-prefix rule.

**IN-01 (dead patrol budget): correctly fixed.** `_begin` zeroes `moving_ticks_left` first, a patrol is popped by `_run_queue` right after `_begin`, and `_run_queue` zeroes the counters again when the queue empties; the first `_advance_patrol` then sees `moving_ticks_left <= 0` and sets the first real budget. The comment states this. Behaviour is unchanged, as the goldens confirm.

**IN-02 (ground limit twice): correctly fixed.** `MapConfig.ground_limit_cm` is one rule. `GroundPick.in_bounds` returns false for a negative limit, the gate's comparison `x < -limit or x > limit` rejects everything for -1, and both accept exactly the same points for any extent, including the tiny-extent case (`0.004` gives limit 0: only the origin). The new test checks the agreement at the edge and one centimetre beyond.

**IN-03 (duplicated push-apart): correctly fixed.** `Separation.displacements` keeps the operation order of the two copies. Radii and ids travel in `PackedFloat64Array` / `PackedInt64Array`, so no precision is lost, and the zero-difference axis still comes from `ids[first] % 2`. Both callers keep their `< 2` early return and build the arrays in ascending id order (`_order`). The replay goldens being byte-identical is the strongest evidence. The test pins the pure routine and the end positions of both systems.

**IN-04 (test-only accessors): correctly fixed.** `anchor_of` has no caller outside tests (checked by grep); `squad_of` likewise. The "Test hook" comments are accurate.

**IN-05 (unused ext_resources): correctly fixed.** Each of the three scenes now has two `ext_resource` entries, no `sub_resource`, `load_steps=3`, and every remaining id is referenced.

**IN-06 (eighth patrol point silent): correctly fixed.** The branch toasts only when the collected count is already at the limit, adds no point, and the copy reads the limit from `SquadOrder.MAX_PATROL_POINTS - 1`. The test checks that no earlier click toasts, the eighth does, and seven points commit.

**IN-07 (`to_markdown` strict key read): correctly fixed.** `_mean` reads `entry.get(key, 0)` as `summary` does; the test renders a run without the keys.

**IN-08 (queue action name): correctly fixed.** One constant, `SelectionController.QUEUE_ACTION`, is read by all three controllers; the test ties it to the Input Map. The two remaining literals (`ui/hud/command_hints.gd` hint table, `tools/screenshot/shot_army_scenarios.gd`) are the known, deliberately left ones and are harmless; a follow-up could point both at the constant, but I do not count them as unfixed.

**IN-09 (panel colour in three places): correctly fixed for the named files.** The plate test reads `KingWidget.PLATE_COLOR`; the `;` comment in `hud.tscn` names the dependency and the scene still loads (hud suites pass in the orchestrator's run). The two other copies (`prompt_glyph.gd`, `squad_slot.gd`) are the known, left-alone ones.

## Info

### IN-10: The "outside the project" path case in test_contrast_probe is actually inside the project

**File:** `tests/unit/test_contrast_probe.gd:121`
**Issue:** `var outside: String = ProjectSettings.globalize_path("res://").get_base_dir().path_join("x.png")`. `globalize_path("res://")` returns the project root with a trailing slash, and `get_base_dir()` of a path with a trailing slash strips only that slash. I ran it against the pinned Godot 4.7.2: the value is `C:/Users/.../Thronefall-like Game/x.png`, and `localize_path` turns it into `res://x.png`. So the case tests "inside the project, outside `screenshots/`", not "outside the project". The code under test is correct and the intended behaviour is still covered by the literal cases `/etc/a.png` and `C:/Windows/a.png` (on Windows, which is the dev and CI-export platform; on the Linux CI runner `C:/Windows/a.png` is not an absolute path and is rejected as a relative one, and `/etc/a.png` is absolute and outside), so no regression is unprotected. The fix report describes the set as including "an absolute path outside the project"; that claim is carried by the literals, not by this variable.
**Fix:** Build a path that really leaves the project, for example `ProjectSettings.globalize_path("res://").path_join("../outside/x.png").simplify_path()` (which gives the project's parent directory), or `OS.get_user_data_dir().path_join("x.png")`, and rename the variable to say what it is.

### IN-11: test_separation pins results that depend on shipped unit radii, and calls a private method by name

**File:** `tests/unit/test_separation.gd:98-124`
**Issue:** `UNIT_RESULT` and `ENEMY_RESULT` were captured with the shipped `footman`/`archer` (radius 0.45 / 0.4) and `grunt`/`ranged` (0.5 / 0.45) definitions, loaded from `res://data/`. A future retune of any of those four radii fails the test with a position mismatch that points at the separation routine, not at the data change, and the file is the only characterization of the merge (the golden replays would catch a behavioural drift, but only through the digest). The enemy case also calls `enemies.call("_separate")`, a string call to a private method that a rename would break with a runtime error rather than a parse error. A smaller point on `Separation.displacements` itself: it indexes `radii` and `ids` by the position index with no size check, so a caller passing arrays of different lengths gets a script error at the first out-of-range read. Both callers build the three arrays in lockstep, so this is not reachable today.
**Fix:** In the two system cases, build the definitions inline (`var footman := UnitDef.new(); footman.radius = 0.45`, the same for the enemy defs) so the pinned numbers depend only on the values written in the test, and keep the `call("_separate")` with a comment that it is the private seam on purpose (or expose a documented `separate_for_test`). Optionally add `assert(radii.size() == positions.size() and ids.size() == positions.size())` at the top of `Separation.displacements`, or document the precondition in its header (it already says "parallel arrays").

---

_Reviewed: 2026-10-14T06:19:41Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
