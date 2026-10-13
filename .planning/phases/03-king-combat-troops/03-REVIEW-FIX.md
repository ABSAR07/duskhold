---
phase: 03-king-combat-troops
fixed_at: 2026-10-13T21:38:17Z
review_path: .planning/phases/03-king-combat-troops/03-REVIEW.md
iteration: 1
findings_in_scope: 13
fixed: 13
skipped: 0
status: all_fixed
---

# Phase 3: Code Review Fix Report

**Fixed at:** 2026-10-13T21:38:17Z
**Source review:** .planning/phases/03-king-combat-troops/03-REVIEW.md (the full text of the nine carried-forward findings CR-01, WR-02, WR-03 and IN-01 to IN-06 was read from the orchestrator's carried_findings.md, reproduced from commit 86e60eb)
**Iteration:** 1

**Summary:**
- Findings in scope: 13
- Fixed: 13
- Skipped: 0

**Where verification ran:** in the main checkout (`C:/Users/burha/Desktop/Projects/Thronefall-like Game`, branch `gsd/phase-01-foundation-day-loop`), not in a worktree. The orchestrator resolved `workflow.use_worktrees` to false for this pass because the Godot toolchain and the Python venv live in the git-ignored `.tools/` directory. The numbers below are reproducible from the working tree. Every commit carries the Co-Authored-By trailer.

**Per-finding gates.** Each fix ran `bash tools/lint.sh` (gdlint and gdformat, exit 0, final state 269 files clean) and the scoped GUT suites named in its entry. Every fix under `simulation/` (CR-01, WR-03, IN-01, IN-02, IN-03) also ran both replay goldens. After the last commit, both still match unchanged:

- `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`: REPLAY_OK, ticks=703, digest 2599c7c2...f31f
- `bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json`: REPLAY_OK, ticks=1353, digest f7a967ed...8959c4

The full suite was not run (the orchestrator does that). No shipped data value or golden file was touched, no file under `.planning/` other than this report and the UI-SPEC copy table was edited, and nothing was pushed.

## Fixed Issues

### CR-01: A unit with `max_health <= 0` hangs the game in an unbounded spawn loop; the validation only reports it

**Status:** fixed: requires human verification (loop bound and a clamp, both logic changes; a test covers them)
**Files modified:** `simulation/squads/squad_system.gd`, `simulation/squads/unit_system.gd`, `tests/unit/test_squad_bad_unit_health.gd` (new), `tests/unit/test_squad_bad_unit_health.gd.uid` (new)
**Commit:** 56b2828
**Applied fix:** `SquadSystem._fill` and `restore_for_dawn` now loop `for _seat in range(maxi(cap - living, 0))` instead of `while living < cap`, so a unit that can never count as living cannot make them run forever. `UnitSystem.spawn` and `heal_to_full` floor the stored health at `maxi(def.max_health, 1)`. The new test builds the barracks over a footman with `max_health` 0 and -5 and expects exactly one spawn per seat and a full living squad, and bounds the dawn restore to the one missing seat. RED first: before the fix the test run hung until killed by `timeout 90` with no result line (the unbounded loop reproduced). Runs after the fix: test_squad_bad_unit_health 3/3, test_map_validate_squads 14/14 (its "a run context still builds on bad squad data" pin still passes), test_squad_respawn 14/14. Goldens match.

### WR-02: `tools/screenshot.sh` cannot see script errors, unlike the replay and playtest wrappers

**Files modified:** `tools/screenshot.sh`, `.github/workflows/ci.yml`
**Commit:** 8d28079
**Applied fix:** each shot's Godot output is now tee'd to `build/screenshot-<shot>.log`; the exit status is read from `PIPESTATUS[0]`; the log is filtered for `SCRIPT ERROR|Parse Error|Failed to load script` (excluding `addons/gut`) exactly as `replay.sh` does, and a hit fails the shot. The header documents it. `ci.yml` uploads `build/screenshot-*.log` with the screenshots artifact. Checks: `bash -n tools/screenshot.sh` clean; one real shot captured with the wrapper (`day_overview`, Vulkan Forward+, exit 0, PNG saved, log written, zero SCRIPT ERROR lines); the filter was shown to fire on a synthetic `SCRIPT ERROR` line; test_shot_list 9/9.

### WR-03: A refused squad order is silent; nothing in the player-facing code reports it

**Status:** fixed: requires human verification (gate semantics changed for a mixed selection; the feel of the toast is a human item)
**Files modified:** `input/command_key_controller.gd`, `input/selection_controller.gd`, `input/pad_cursor_controller.gd`, `ui/hud/toast.gd`, `simulation/commands/command_processor.gd`, `simulation/squads/squad_system.gd` (comment only), `tests/unit/test_squad_queue.gd`, `tests/e2e/test_command_keys.gd`, `tests/e2e/test_mouse_commands.gd`, `tests/e2e/test_pad_cursor.gd`, `.planning/phases/03-king-combat-troops/03-UI-SPEC.md`
**Commit:** 8ad0158
**Applied fix:** `Toast` gets `QUEUE_CLOSED` ("Nothing can be queued after Hold, Follow or Patrol") and a static `refusal_text(reason)`. All three paths now read the result of `submit` and emit `feedback(text, true)`: `CommandKeyController._give` (the Shift+F / Shift+H / Shift+R path the review called out), `SelectionController._order` (Shift right click) and `PadCursorController._confirm` (RT with a pad point verb). The all-or-nothing refusal is gone: the gate (`_every_queue_is_closed`) refuses with `QUEUE_CLOSED` only when every ordered squad is closed, otherwise the order goes through and `SquadSystem.apply_order` skips the closed squads. The Copywriting Contract table in 03-UI-SPEC.md gained the row for the new toast and states the mixed-selection rule. New tests: two cases in test_squad_queue (a mixed selection queues for the open squad only and announces nothing; all closed is refused with the reason and one `command_rejected`), `test_shift_a_verb_behind_a_queued_hold_is_refused_and_the_toast_says_so` and a mixed-selection case in test_command_keys (also pins the copy string), a queued click behind a queued hold in test_mouse_commands, and an RT case in test_pad_cursor. RED: the mixed-selection unit test failed on the unfixed gate (queue_closed returned instead of ok); the e2e cases could not compile before `Toast.QUEUE_CLOSED` existed. Runs: test_squad_queue 17/17, test_command_keys 16/16, test_mouse_commands 15/15, test_pad_cursor 10/10, test_pad_commands 18/18, test_squad_order_intent 12/12, test_squad_selection 8/8, test_selection_steering 7/7, test_hud_contract 15/15. Goldens match.

### WR-04: The contrast probe's pure functions (path guard and measurement) have no automated test

**Files modified:** `tests/unit/test_contrast_probe.gd` (new), `tests/unit/test_contrast_probe.gd.uid` (new)
**Commit:** 2e863c8
**Applied fix:** the new test preloads the probe script and calls its statics. `parse_args` accepts `--image=screenshots/a.png --rect=1,2,3,4` (also a res:// path, `--min`, and an absolute path inside the project's screenshots folder) and rejects fifteen unsafe image paths (`..` segments, `res://screenshots_evil/x.png`, a bare `res://screenshots/.png`, non-.png names, other folders, `C:/Windows/a.png`, `/etc/a.png`, an absolute path outside the project, the empty string) and eleven bad argument sets (missing or malformed rect, non-positive size, `--min` at or below 1.0, unknown argument). `measure` is pinned with in-memory images: red #FF4040 text on a black outline measures about 6.1 (at or above 4.5), the same text on mid-grey about 1.15 (below), no red gives "no fill pixels in the rect", a rect that is all fill gives "no backdrop pixels", a rect outside the image gives an error; `luminance` and `contrast_ratio` are checked against WCAG values (21 for black on white, either order). 10/10 pass. The test is not vacuous: removing the `..` guard and raising `FILL_KEY` in the probe (reverted afterwards) made it fail on the measurement cases. No production code changed.

### IN-01: Patrol leg budget is assigned and immediately overwritten

**Files modified:** `simulation/squads/squad_system.gd`
**Commit:** 67122e9
**Applied fix:** deleted the `squad.moving_ticks_left = _walk_budget_ticks(squad)` line in the patrol branch of `_begin` (the review's first option) and left a comment saying the first leg ends at once by design. `_walk_budget_ticks` is pure, so behaviour is byte-identical. test_squad_patrol 9/9, test_squad_queue 17/17, test_squad_point_orders 10/10. Goldens match.

### IN-02: The ground-bounds rule exists twice

**Files modified:** `simulation/defs/map_config.gd`, `simulation/commands/command_processor.gd`, `input/ground_pick.gd`, `tests/unit/test_ground_pick.gd`
**Commit:** 06b3e5c
**Applied fix:** `MapConfig.ground_limit_cm(half_extent_m)` (static) holds the rule: -1 for a non-finite or non-positive extent, otherwise `roundi(minf(extent, MAX_GROUND_HALF_EXTENT) * 100.0)`. `CommandProcessor._ground_limit_cm` and `GroundPick.in_bounds` both call it. A new case in test_ground_pick pins the helper (capping, bad extents) and checks that `in_bounds` agrees at the edge and one centimetre beyond for several extents. Runs: test_ground_pick 9/9, test_squad_point_validation 11/11, the five test_map_validate_* scripts 70/70, test_mouse_commands 15/15, test_sim_rules_guard 4/4, test_pad_cursor 10/10. Goldens match.

### IN-03: `UnitSystem.separate` and `EnemySystem._separate` are the same 35 lines

**Files modified:** `simulation/squads/separation.gd` (new), `simulation/squads/separation.gd.uid` (new), `simulation/squads/unit_system.gd`, `simulation/night/enemy_system.gd`, `tests/unit/test_separation.gd` (new), `tests/unit/test_separation.gd.uid` (new)
**Commit:** 14f898d
**Applied fix:** the pass is now `Separation.displacements(positions, radii, ids)`, a static routine over parallel packed arrays (radii as `PackedFloat64Array`, ids as `PackedInt64Array`, so no precision is lost) that returns the displacements with the same operations in the same order as the two copies. Each system builds the arrays from its living records, keeps its own `< 2` early return, and adds the result to its positions. Before touching the code, the end positions of both systems on a 12-unit overlapping cluster over three passes were captured with a scratch script and pinned in test_separation, which also covers the pure routine (half-overlap push, touching circles, the id-parity axis for a zero difference, fewer than two circles, the one-snapshot sum). The characterization values were identical before and after the merge. Runs: test_separation 7/7 (RED before `Separation` existed), test_enemy_targeting 15/15, test_squad_guard 14/14, test_squad_orders 13/13, test_sim_rules_guard 4/4, test_squad_respawn 14/14. Both goldens match unchanged (digests as above), so the finding was not rolled back.

### IN-04: Test-only accessors on production classes

**Files modified:** `simulation/squads/squad_system.gd`, `simulation/squads/unit_system.gd`
**Commit:** 9d2d15d
**Applied fix:** the review's own suggestion: `SquadSystem.anchor_of` and `UnitSystem.squad_of` stay (the tests use them heavily) and their doc comments now say "Test hook: nothing in the game reads it, the tests do." No method was added or removed, so `SquadSystem` stays at its public-method count. Comment-only change; lint clean.

### IN-05: Unused `ext_resource` entries in three building scenes

**Files modified:** `presentation/buildings/models/barracks_t1.tscn`, `presentation/buildings/models/barracks_t2.tscn`, `presentation/buildings/models/archery_range_t1.tscn`
**Commit:** 2b7d443
**Applied fix:** removed the `2_base` (tower-square-base.glb) entry from both barracks scenes and the `2_door` (wall-door.glb) entry from the archery range scene, and lowered `load_steps` from 4 to 3 in each (two remaining ext_resources plus one). Each id was confirmed to be referenced nowhere else in its file. test_building_models 8/8.

### IN-06: The eighth patrol click is dropped without a word

**Files modified:** `input/selection_controller.gd`, `ui/hud/toast.gd`, `tests/e2e/test_mouse_commands.gd`, `.planning/phases/03-king-combat-troops/03-UI-SPEC.md`
**Commit:** b6ff96f
**Applied fix:** while patrol is armed, a right click past the seventh point now emits `Toast.PATROL_FULL % 7` ("A patrol takes up to 7 points", the 7 read from `SquadOrder.MAX_PATROL_POINTS - 1`) as an error toast and still adds no point. UI-SPEC got its copy-table row. New test: hold P, right click eight points, assert the toast copy on the eighth and that the seven points commit as one patrol per squad; it fails with the emit removed (checked by mutation, then restored). Runs: test_mouse_commands 16/16, test_squad_selection 8/8, test_hud_contract 15/15.

### IN-07: `to_markdown` indexes the new run keys strictly while `summary` reads them tolerantly

**Files modified:** `tools/replay/balance_report.gd`, `tests/integration/test_balance_value_metric.gd`
**Commit:** 8adbc3b
**Applied fix:** `_mean` now sums `float(entry.get(key, 0))`, so `to_markdown` accepts every report `summary` accepts. The new case in test_balance_value_metric builds a run entry without the value keys, renders the markdown and checks the summary and squad rows (a missing value reads 0.00); before the fix it failed with four "Invalid access to property or key" script errors. The case lives in test_balance_value_metric because test_balance_report.gd is already at the 20-public-method lint cap. Runs: test_balance_value_metric 6/6, test_balance_report 19/19, test_balance_acceptance 12/12.

### IN-08: The queue action name is a literal in two controllers and a constant in a third

**Files modified:** `input/selection_controller.gd`, `input/pad_cursor_controller.gd`, `input/command_key_controller.gd`, `tests/e2e/test_command_keys.gd`
**Commit:** 0ceb7c8
**Applied fix:** `SelectionController.QUEUE_ACTION` (`&"command_queue"`) is the one definition; `CommandKeyController` dropped its own constant and `PadCursorController` and `SelectionController` stopped using the literal. A test in test_command_keys checks the constant equals `command_queue` and exists in the Input Map. The literals in `ui/hud/command_hints.gd` (a data table of hint rows) and in the screenshot scenario script were left alone as outside the three controllers the finding names. Runs: test_command_keys 17/17, test_mouse_commands 16/16, test_pad_cursor 10/10, test_pad_commands 18/18.

### IN-09: The panel colour #14141A at alpha 0.78 is written out in three places

**Files modified:** `tests/e2e/test_start_night_plate.gd`, `ui/hud/hud.tscn`
**Commit:** 5001367
**Applied fix:** the plate test's `PLATE_COLOR` is now `KingWidget.PLATE_COLOR`, and hud.tscn carries a `;` comment above the sub_resource naming the dependency. Retuning the widget's alpha (temporarily, reverted) failed the plate test. The same colour is also written in `ui/hud/prompt_glyph.gd` and `ui/hud/squad_slot.gd`; the finding did not name them and they were left unchanged. Runs: test_start_night_plate 6/6, test_king_widget 15/15, test_hud_contract 15/15.

---

_Fixed: 2026-10-13T21:38:17Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
