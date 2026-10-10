---
phase: 03-king-combat-troops
plan: 07
subsystem: simulation
tags: [godot, gdscript, squad-orders, order-queue, patrol, attack-move, ground-pick, input-map, order-pings, selection-routing]

requires:
  - phase: 03-king-combat-troops
    provides: "03-06 SquadOrderIntent, CommandProcessor squad-order gate, SquadSystem.apply_order with its points and queued parameters, SelectionModel/SelectionController, CommandKeyController, Toast with set_line/clear_line and the SubViewport push_input test technique; 03-05 SquadStrip stance glyphs; 03-04 dispatch-table gate; 03-02/03-01 squads, begin_night and the dawn restore"
provides:
  - "SquadSystem order queue (SquadOrder.MAX_QUEUE 9): move and attack-move walks, patrol ping-pong from the centroid, Shift queue, rally as move plus hold; orders_of() and patrol_path_of() snapshots; executing_verb() reports attack_move"
  - "CommandProcessor gate: BAD_POINT, TOO_MANY_POINTS, QUEUE_CLOSED as returned values; points are Vector2i centimetres checked against MapConfig.ground_half_extent and divided by 100.0 once"
  - "MapConfig.ground_half_extent (90 m, validated, bounded at 10000 m) and the simulation input-API source scan (Input, InputEvent, Camera3D, Viewport, get_viewport, DisplayServer)"
  - "GroundPick (camera ray to ground plane, to_centimetres, in_bounds), SelectionController point commands (right click move, Shift queue, armed attack-move, P-held patrol, Escape), OrderMarkers pings"
  - "Input Map: squad_move (right mouse), squad_attack_move (A), squad_patrol (P), command_queue (Shift), command_cancel (Escape, pad B)"
  - "Owner routing rule: while a squad is selected the king takes no movement input; Escape with nothing armed clears the selection"
affects: [03-08, 03-09, 03-10, 03-11, 03-12]

actuals:
  tokens: 24850
  tasks: 3
  commits: 5

plan_head_before: 6724b4a64d2d3f9e52f4656c36a142e34fe0b050
plan_head_after: 1fb04c518840997fe9799ceff832a18b1fb354a9
commits: 5

tech-stack:
  added: []
  patterns:
    - "The squad queue holds only walks while they run: hold, follow and patrol act at once and leave it, so a terminal verb sits in the queue only while it waits behind a walk and 'last entry is terminal' is the whole QUEUE_CLOSED test"
    - "A leg budget (walk time plus 2 s grace) counts down only on steps where no unit of the squad is engaged, so a fight never uses up an attack-move or a patrol leg"
    - "Attack-move and patrol measure guard and leash from each unit own position; move, hold, follow and post measure from the anchor"
    - "Presentation controllers declare feedback(text, is_error) and prompt(text) signals; Toast.bind_run connects every node that has them"
    - "Cursor shape is a test hook on the controller because the headless display keeps no cursor to read back"

key-files:
  created:
    - input/ground_pick.gd
    - presentation/units/order_markers.gd
    - tests/unit/test_squad_point_orders.gd
    - tests/unit/test_squad_patrol.gd
    - tests/unit/test_squad_queue.gd
    - tests/unit/test_squad_point_validation.gd
    - tests/unit/test_ground_pick.gd
    - tests/unit/test_king_selection_steering.gd
    - tests/e2e/test_mouse_commands.gd
    - tests/e2e/test_selection_steering.gd
  modified:
    - simulation/squads/squad_order.gd
    - simulation/squads/squad_orders.gd
    - simulation/squads/squad.gd
    - simulation/squads/squad_system.gd
    - simulation/commands/command_processor.gd
    - simulation/run/run_context.gd
    - simulation/defs/map_config.gd
    - data/maps/prototype_map.tres
    - presentation/map/prototype_map.tscn
    - presentation/king/king.gd
    - input/selection_controller.gd
    - input/command_key_controller.gd
    - ui/hud/toast.gd
    - project.godot
    - tests/unit/test_input_map.gd
    - tests/unit/test_sim_rules_guard.gd
    - tests/unit/test_map_validate_squads.gd
    - tests/unit/test_squad_order_intent.gd
    - .planning/phases/03-king-combat-troops/03-CONTEXT.md

key-decisions:
  - "Attack-move key: keep-a, chosen by the owner at the checkpoint (not auto-mode); squad_attack_move is bound to physical_keycode 65 (A), shared with move_left through an explicit SHARED_BINDINGS_ALLOWED entry beside (sprint, command_queue) on Shift"
  - "Movement routing (owner amendment to D-15 and D-11): while the selection is non-empty the king receives no movement input from the keyboard or the stick (King.steered_direction); with nothing selected he is the implicit selection and steers as before; sprint, build, ability and start-night are not movement and are untouched"
  - "Escape (command_cancel) cancels an armed command; with nothing armed it clears the selection and hands the king back at once; 03-06 empty-ground click-clear stays"
  - "A hold reached at the end of a walk keeps the point the walk ended on; a hold that runs at its apply tick freezes the centroid as in 03-06 (a rally is a move to the king then a hold, so it still holds exactly at the king position)"
  - "QUEUE_CLOSED is decided at the gate from orders_of() before anything applies, so a multi-squad order is refused whole (nothing changes) instead of half applied"
  - "A queued order that would overflow MAX_QUEUE makes room by dropping the last entries: a single order replaces the ninth, a queued rally (two entries) replaces the last two so both halves fit"

patterns-established:
  - "RED with an inert skeleton committed beside the failing tests, then GREEN, for both code tasks"
  - "Owner-decided scope additions get their own tests and a dated line in 03-CONTEXT.md"

requirements-completed: [UNIT-10, INPT-01]

coverage:
  - id: D1
    description: "Move walks every unit to its slot around a ground point ignoring enemies and then guards the spot as post; attack-move walks to the point engaging what comes within guard_range of each unit on the way, finishes the walk after the fight and then guards the spot (a fight does not use up the walk budget); executing_verb reads attack_move until arrival; a squad with nobody alive accepts a move and its replacements walk to the new anchor"
    requirement: UNIT-10
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_point_orders.gd (10 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Patrol starts its path at the squad centroid when it becomes active and visits start, p1, p2, p1, start, p1; engages what comes close and resumes when the enemy is dead; the stance and path survive begin_night and the dawn restore; a queued patrol starts at the centroid when it becomes active; nobody alive waits"
    requirement: UNIT-10
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_patrol.gd (9 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Shift queue runs orders in turn and ends in hold; at most 9 orders (a tenth replaces the last, a queued rally replaces enough of the tail to fit both halves); a queued order behind hold, follow or patrol is refused with QUEUE_CLOSED and changes nothing; a non-queued order clears the queue; re-issuing an order is idempotent; two orders between steps apply in submission order; a squad whose building falls keeps executing; an order after the run ended is refused with RUN_OVER"
    requirement: UNIT-10
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_queue.gd (15 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Points cross into the simulation only as Vector2i centimetres: BAD_POINT for a missing, extra or off-ground point (inclusive at the extent, one centimetre beyond refused), TOO_MANY_POINTS at 8 patrol points, 7 accepted, (1234, -567) arrives as exactly Vector2(12.34, -5.67); ground_half_extent 0, negative, NaN, INF and 1e30 are reported; a source scan fails on Input, InputEvent, Camera3D, Viewport, get_viewport or DisplayServer under simulation/"
    requirement: UNIT-10
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_point_validation.gd (11 tests), tests/unit/test_map_validate_squads.gd (14 tests), tests/unit/test_sim_rules_guard.gd (4 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "GroundPick: a projected ground point picked back lands within 1 mm at the centre and near each corner, a ray that cannot reach the plane returns null, to_centimetres is roundi(x * 100.0) per axis, in_bounds is inclusive at the extent"
    requirement: INPT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_ground_pick.gd (8 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "With squads selected a right click on the visible ground orders a move for both squads at the clicked centimetre point and pings once, Shift queues it, the attack-move key arms attack-move (line, cross cursor) for the next left click without changing the selection, holding P and right-clicking collects points that commit on release, Escape or a right click cancels, a right click with nothing selected shows Select a squad first, an off-ground point issues nothing, pings nothing and shows the Can't go there message, a toast replaces the armed line and the line returns, and the camera never moves"
    requirement: UNIT-10
    verification:
      - kind: e2e
        ref: "tests/e2e/test_mouse_commands.gd (14 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_input_map.gd (20 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Owner routing rule: with a squad selected, holding A for 0.5 s moves the king 0.0 m and arms attack-move; with the selection cleared the same hold moves him and shows no error; Escape (twice when attack-move was armed) hands the king back; the ability, the build hold and sprint are unaffected; the smoke golden is unchanged and every king ride test is green"
    requirement: INPT-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_selection_steering.gd (7 tests), tests/unit/test_king_selection_steering.gd (2 tests)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Whether the pings, the armed line, the right-click-to-move feel, the king standing still while a squad is selected and the A shared with move_left read well in play; the owner judges them at the Phase 3 UAT"
    verification: []
    human_judgment: true
    rationale: "Feel and legibility are the owner's; real-window probe captures (Forward+, RTX 3060) showed the cyan move ring at the clicked ground point, the red ring with crossed blades for attack-move and the armed line in the hint slot, and plan 03-12 captures the formal screenshots"

duration: 45min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 07: Point Orders, Shift Queue and Mouse Commands Summary

**Move, attack-move and patrol to bounded centimetre points through a Shift order queue in the deterministic simulation, right-click and armed-click commands with ground pings by mouse, A kept for attack-move by the owner, and the king standing still while a squad is selected**

## Performance

- **Duration:** 45 min
- **Started:** 2026-10-10T14:04:02Z
- **Completed:** 2026-10-10T14:49:00Z (code at 14:47); SUMMARY and tracking follow
- **Tasks:** 3 (Task 1 a checkpoint decision resolved by the owner; Tasks 2 and 3 TDD, RED then GREEN each)
- **Files modified:** 39 (per `git diff --name-only 6724b4a HEAD`, `.uid` files included)

## Task 1 decision: keep-a, chosen by the owner at the checkpoint (not auto-mode)

The owner chose to keep A for attack-move ("Keep A. When a unit is selected, only that unit receives orders. King is auto selected when no other unit selected.") and, asked which keys stop steering the king while a squad is selected, chose "All movement goes to the selection".

- **Physical keycode bound:** `squad_attack_move` is `physical_keycode` 65 (A). `test_input_map` allow-lists (move_left, squad_attack_move) on `key 65` beside (sprint, command_queue) on `key 4194325` (Shift).
- **Movement-routing rule:** while the selection is non-empty the king receives no movement input from the keyboard (W/A/S/D and the arrows) or the left stick; pressing A arms attack-move without any king drift. With nothing selected the king is the implicit selection and steers as before. Escape with nothing armed clears the selection and gives the king back at once (the first Escape cancels an armed command, the second clears). Sprint, the build hold, the ability and start-night are not movement and work whatever is selected.
- **Recorded:** a dated amendment line under D-15 in `03-CONTEXT.md` (commit `8c43bc6`). The 03-12 owner packet lists A as a confirmed owner choice, not a defaulted one.

## Accomplishments

- **Simulation (Task 2):** `SquadSystem` keeps a bounded order queue. Move and attack-move are walks that wait in it and run in turn, each ending in post at its point; hold, follow and patrol act at once. A move ignores enemies on the way; attack-move and patrol acquire with the guard and leash measured from each unit's own position and resume after the fight; the leg budget (walk time plus 2 s grace) is not spent while a unit is engaged. Patrol walks `[centroid] + points` ping-pong. A queued rally is a move to the king then a hold. `orders_of()` (verb and points, head first) and `patrol_path_of()` return copies; `executing_verb()` reports attack_move. SquadSystem is at 19 of 20 public methods.
- **Gate (Task 2):** `CommandProcessor` returns BAD_POINT, TOO_MANY_POINTS and QUEUE_CLOSED as values with `command_rejected`, checks every point against `MapConfig.ground_half_extent` (inclusive, both axes) and divides centimetres by 100.0 once. Check order: RUN_OVER, NO_SQUADS, UNKNOWN_SQUAD, UNKNOWN_VERB, points, queue. `MapConfig.ground_half_extent` is 90 m on the prototype map and validated. The source scan now fails on Input, InputEvent, Camera3D, Viewport, get_viewport and DisplayServer under `simulation/`.
- **Mouse commands (Task 3):** `GroundPick` turns a screen point into a ground point and centimetres; `SelectionController` orders a move on a right click (Shift queues), arms attack-move for the next left click, collects patrol points while P is held and commits on release, cancels on Escape or a right click, and shows the armed line and the cross cursor; `OrderMarkers` pings each accepted move, attack-move or rally (cyan ring 0.3 to 0.8 m over 0.5 s; #FF7A59 with crossed blades for attack-move); the off-ground message is the only feedback for a bad point.
- **Owner routing rule (scope addition):** `King.steered_direction` zeroes the movement read while a squad is selected, at the one point where the king polls `move_*`, so the stick is covered without waiting for 03-09.
- **Self-verification:** a real-window probe (Forward+, RTX 3060) on the squad fixture showed the move ring at the clicked ground point, the red ring with crossed blades for attack-move, and the line "Click a point to attack-move" above the squad strip in the hint slot.
- Suite: 122 scripts / 1094 tests at baseline to 130 scripts / 1175 tests, all passing (13165 asserts, exit 0); lint clean; the smoke replay digest `2599c7c2...` is byte-identical (`REPLAY_OK scenario=smoke`). A mutation probe (the steering rule disabled) failed 4 of the 7 steering e2e tests, then the rule was restored.

## Task Commits

1. **Task 1: attack-move key decision (keep A) and routing rule recorded** - `8c43bc6` (docs)
2. **Task 2 RED: point-order, patrol, queue and validation tests + inert skeleton** - `4f2ee08` (test)
3. **Task 2 GREEN: point orders, patrol, queue, gate and ground extent** - `2137c11` (feat)
4. **Task 3 RED: ground pick, mouse command and steering tests + inert skeleton** - `b7728ec` (test)
5. **Task 3 GREEN: Input Map, GroundPick, mouse commands, pings, king routing** - `1fb04c5` (feat)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md, ROADMAP.md and REQUIREMENTS.md (see `git log --grep "docs(03-07)"`).

RED evidence: Task 2 RED had 10 of 10 (point orders), 9 of 9 (patrol), 14 of 15 (queue), 9 of 11 (validation) and 1 of 14 (map validation) failing on assertions against the stubs; Task 3 RED had 3 of 19 (input map, run against the pre-binding `project.godot`), 6 of 8 (ground pick), 1 of 2 (steering unit), 14 of 14 (mouse commands) and 4 of 7 (steering e2e) failing.

## TDD Gate Compliance

RED (`test(03-07)`) precedes GREEN (`feat(03-07)`) for both code tasks. Each RED commit carries an inert skeleton (constants, stub methods, an empty ping counter, a `steered_direction` that returns its input) so the tests compile and fail on an assertion. No REFACTOR commit was needed; lint formatting was applied with each commit.

## Files Created/Modified

See `key-files` above. Notable: `simulation/squads/squad_system.gd` (queue, walks, patrol, mobile guard), `simulation/commands/command_processor.gd` (point and queue gate), `input/selection_controller.gd` (point commands), `presentation/units/order_markers.gd` (pings), `presentation/king/king.gd` (routing rule).

## Decisions Made

See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] A finished walk left the squad flagged as moving**
- **Found during:** Task 2 (`test_a_move_ignores_an_enemy_on_the_way_and_then_guards_the_spot` failed after the first GREEN)
- **Issue:** when the last walk left the queue nothing cleared `Squad.moving`, so a squad that arrived at a move point went on ignoring enemies for ever.
- **Fix:** `_run_queue` clears `moving` and the leg budget when the queue empties.
- **Files modified:** `simulation/squads/squad_system.gd`
- **Verification:** the same test and `test_squad_point_orders` (10 tests)
- **Committed in:** `2137c11`

**2. [Rule 3 - Blocking] The 03-06 allow-list test named the point verbs as unknown**
- **Found during:** Task 2
- **Issue:** `test_a_verb_outside_the_allow_list_is_rejected` listed move, attack_move and patrol as unsupported; they are supported now.
- **Fix:** the list is now `dance`, empty and `teleport`.
- **Files modified:** `tests/unit/test_squad_order_intent.gd`
- **Committed in:** `4f2ee08`

**3. [Rule 2 - Missing critical] A huge `ground_half_extent` would overflow the centimetre limit**
- **Found during:** Task 2 (design of the gate, after the fifth-review lesson on huge finite values)
- **Issue:** the plan reports only non-finite or non-positive extents; `1e30 * 100` overflows `roundi`.
- **Fix:** `MapConfig.MAX_GROUND_HALF_EXTENT` (10000 m) is reported by `validate()` and clamped in the gate and in `GroundPick.in_bounds`; a bad extent bounds nothing.
- **Files modified:** `simulation/defs/map_config.gd`, `simulation/commands/command_processor.gd`, `input/ground_pick.gd`
- **Verification:** `test_map_validate_squads` (extent 1e30), `test_ground_pick#test_a_bad_extent_bounds_nothing`
- **Committed in:** `2137c11`, `1fb04c5`

**4. [Rule 2 - Missing critical] A pad player would be stranded by the owner's routing rule**
- **Found during:** Task 3
- **Issue:** R3 (select all) is on the pad since 03-06; with the rule in place a pad player who selects squads cannot steer the king and the pad has no way to deselect until 03-09.
- **Fix:** `command_cancel` also carries pad button B, the one pad binding of the five new actions; `test_input_map` pins it.
- **Files modified:** `project.godot`, `tests/unit/test_input_map.gd`
- **Committed in:** `1fb04c5`

**5. [Owner-decided scope addition] King movement consults the selection**
- **Found during:** checkpoint resolution before Task 3
- **Issue:** the plan left A's king drift as a known cost; the owner chose instead to route all movement to the selection.
- **Fix:** `King.steered_direction`, wired through `MapRoot.get_selection()` in `King.bind_run`; unit and e2e tests as the checkpoint required; 03-CONTEXT D-15 amended.
- **Files modified (outside the plan's files_modified):** `presentation/king/king.gd`, `tests/unit/test_king_selection_steering.gd`, `tests/e2e/test_selection_steering.gd`, `.planning/phases/03-king-combat-troops/03-CONTEXT.md`
- **Committed in:** `8c43bc6`, `b7728ec`, `1fb04c5`

### Differences from the plan text (no behaviour lost)

- **QUEUE_CLOSED at the gate, not through `apply_order`'s return:** the gate reads `orders_of()` and refuses before anything applies, which keeps a multi-squad order atomic; `apply_order` also skips a closed squad defensively. Needed one optional trailing `map` parameter on `CommandProcessor` (and `RunContext` passes it) to read the ground extent.
- **The A key with nothing selected is silent:** the plan says every command key with nothing selected shows "Select a squad first", but A is the king's move_left then and a toast on every step left would break steering. Right click and P still show it.
- **A hold after a walk keeps the walk's point** instead of freezing the centroid, so a rally still holds exactly at the king position.
- **The cursor test reads `SelectionController.cursor_shape()`** because the headless display keeps no cursor to read back.
- **Not in the plan's files list:** `simulation/run/run_context.gd` (the map parameter), the two steering test files, `king.gd` and `03-CONTEXT.md`.

---

**Total deviations:** 5 auto-fixed or owner-decided (1 Rule 1, 1 Rule 3, 2 Rule 2, 1 owner scope addition) plus 5 wording differences
**Impact on plan:** none on scope or the owner decisions; one latent bug caught by a test, one overflow guard, one pad safety binding.

## Authentication Gates

None.

## Known Stubs

None. The 03-06 stubs are lifted: `Squad.queue`, the `points` and `queued` parameters of `apply_order`, `executing_verb()` and `SelectionController.feedback` all do something now. Still ahead by design: `SquadSlot.set_group()` (03-08), patrol lines and queued discs (03-08), the drag box and groups (03-08), the pad cursor and pad bindings of the five new actions (03-09).

## Threat Flags

None. T-03-12 (mitigate) holds: MAX_QUEUE 9, MAX_PATROL_POINTS 8 (TOO_MANY_POINTS), points bounded by the ground extent (BAD_POINT), integer centimetres, the extent itself bounded; each limit is pinned by a test. T-03-13 (mitigate) holds: the source scan fails on the input and camera APIs under `simulation/`, points cross only as `Vector2i` inside `SquadOrderIntent`, and `squad_ordered` records the resolved points in the digest. T-03-SC (accept): no packages and no assets.

## Issues Encountered

- `Input.get_current_cursor_shape()` returns the arrow under the headless display, so the cursor is verified through a controller hook.
- The shell rejects heredocs with apostrophes; larger edit scripts were written with the Write tool.
- The first Escape after A is pressed with a squad selected only cancels the armed attack-move (the second clears the selection); the steering e2e tests press it twice.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **03-08:** `orders_of()` gives the queued discs and `patrol_path_of()` the patrol line; `OrderMarkers` already owns the move, attack and rally pings; the drag box beside `CLICK_SLOP_PX`, groups on `SelectionModel` and `SquadSlot.set_group` are still open.
- **03-09 (pad):** the king's stick is already covered, because `King.steered_direction` sits where the king reads `move_*`. The five command actions have keyboard and mouse bindings and `command_cancel` has pad B; 03-09 owns the final pad layout and must keep a pad way to cancel and clear the selection. Pad cursor points must go through `GroundPick.to_centimetres` and `GroundPick.in_bounds` and call `SelectionController.arm_attack_move`, `begin_patrol`, `commit_patrol` and `escape`.
- **03-10:** hint and prompt text reads keys from the Input Map; A, P, Shift and Escape display as bound. **03-11:** nothing here changes balance.
- **03-12 packet:** list A (shared with move_left) as an owner-confirmed key; the rule that a selected squad stops the king (and that Escape clears it) as an owner decision to confirm in play; Shift as both sprint and queue; the pad B interim.

## Self-Check: PASSED

All created files exist on disk, commits `8c43bc6`, `4f2ee08`, `2137c11`, `b7728ec` and `1fb04c5` are in `git log`, both tasks' acceptance criteria pass (greps, `bash tools/test.sh` exit 0 with 1175/1175, `bash tools/lint.sh` clean, the required suite names in the JUnit XML), and `REPLAY_OK scenario=smoke` shows the unchanged digest.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-10*
