---
phase: 03-king-combat-troops
plan: 06
subsystem: simulation
tags: [godot, gdscript, squad-orders, selection, multimesh, input-map, toast, command-gate]

requires:
  - phase: 03-king-combat-troops
    provides: "03-05 SquadStrip/SquadSlot (set_selected stub), SquadOrder verb and stance constants, resting_stance()/executing_verb(); 03-04 dispatch-table CommandProcessor, king position; 03-03 HudRoot and the protected-centre contract; 03-02/03-01 squads, UnitViews puppets, the recorder and SimSignals rule"
provides:
  - "SquadOrderIntent (ids, verb, centimetre Vector2i points, queued) and the CommandProcessor gate: RUN_OVER, NO_SQUADS, UNKNOWN_SQUAD, UNKNOWN_VERB as returned values with command_rejected"
  - "SquadSystem.apply_order: follow (anchor = king each step), hold (anchor = living centroid, post when nobody is alive), rally (walk to the king ignoring enemies, then hold); stance, anchor and walk state persist across begin_night and the dawn restore"
  - "SimEvents.squad_ordered with the resolved points, in SimSignals.ALL and the SimRecorder (HANDLED, connect, handler)"
  - "SelectionModel, SelectionMath, SelectionController (click, Ctrl-click, double-click, empty ground), SelectionRings (two MultiMeshInstance3D layers), SquadSlot click/hover/selected styling"
  - "Input Map: squad_follow F / D-pad up, squad_hold H / D-pad down, squad_rally R / D-pad left, squad_cycle Tab / D-pad right, select_all F2 / R3; fast_forward moved F to T"
  - "CommandKeyController (polled verbs, cycle, select all) and Toast (one-line hint-slot toast with an armed-line fallback)"
  - "ROADMAP overview, .claude/CLAUDE.md Platform and Input rows and .planning/research/STACK.md rows recording the 2026-10-09 mouse decision"
affects: [03-07, 03-08, 03-09, 03-10, 03-12]

actuals:
  tokens: 33500
  tasks: 3
  commits: 6

plan_head_before: 1cd4fc54fa32c48b5a6c939a2407f702d6225cdb
plan_head_after: d7ab7b29a26a3b5f7283de5a6f1e3a1bf2975812
commits: 6

tech-stack:
  added: []
  patterns:
    - "A whole-squad order is applied at submit, between two steps, in creation order whatever order the ids arrive in; CommandProcessor is the only place centimetres become metres"
    - "Mouse tests push events into a 1280x720 SubViewport with push_input: the GUT output panel covers the root window and the headless root window is stretched from 64 px, so Input.parse_input_event cannot aim at HUD controls there"
    - "A MultiMesh with a fixed instance_count (set after transform_format and use_colors) and a per-frame visible_instance_count, so a changing selection never reallocates the buffer"
    - "A per-step scratch flag on the squad (settled) lets a following formation stay still within arrival distance without extra stored state"

key-files:
  created:
    - simulation/commands/squad_order_intent.gd
    - simulation/squads/squad_orders.gd
    - input/selection_model.gd
    - input/selection_math.gd
    - input/selection_controller.gd
    - input/command_key_controller.gd
    - presentation/units/selection_rings.gd
    - ui/hud/toast.gd
    - tests/unit/test_squad_orders.gd
    - tests/unit/test_squad_order_intent.gd
    - tests/unit/test_squad_stance_persistence.gd
    - tests/unit/test_selection_model.gd
    - tests/unit/test_selection_math.gd
    - tests/e2e/test_squad_selection.gd
    - tests/e2e/test_command_keys.gd
  modified:
    - simulation/squads/squad.gd
    - simulation/squads/squad_order.gd
    - simulation/squads/squad_system.gd
    - simulation/commands/command_processor.gd
    - simulation/night/night_sim.gd
    - simulation/events/sim_events.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - presentation/map/map_root.gd
    - presentation/map/prototype_map.tscn
    - ui/hud/squad_slot.gd
    - ui/hud/squad_strip.gd
    - ui/hud/hud.tscn
    - project.godot
    - tests/unit/test_input_map.gd
    - .planning/ROADMAP.md
    - .claude/CLAUDE.md
    - .planning/research/STACK.md

key-decisions:
  - "A rally reports its resting stance (hold) from the apply tick and executing_verb stays empty for follow, hold and rally, so the stance glyph shows hold while the squad walks (the UI-SPEC glyph set has no move shape)"
  - "A walk is also abandoned WALK_GRACE_SECONDS (2 s) after the farthest unit could have arrived: two squads sent to one point push each other off their slots and would otherwise ignore enemies for ever"
  - "A following squad whose units are all within ARRIVE_DISTANCE of their slots keeps still (Squad.settled); the formation therefore rests within 0.25 m of its slots rather than exactly on them"
  - "SquadOrders.is_supported is the one allow-list of verbs the state machine carries out; the gate and apply_order both read it, so 03-07 widens one place"
  - "Selection is presentation state on MapRoot (get_selection); orders carry explicit ids, and a squad that falls to 0 alive stays selected"
  - "Tab cycles from the squad cycled last, not from the squad clicked last (the plan's literal reading)"

patterns-established:
  - "RED with an inert API skeleton committed with the failing tests, then GREEN replaces the skeleton, for all three tasks"
  - "A new SimEvents signal lands with its SimSignals.ALL entry and its recorder HANDLED entry, connect and handler in the same commit"

requirements-completed: [UNIT-05, UNIT-06, UNIT-09, UNIT-10, INPT-01]

coverage:
  - id: D1
    description: "Follow, hold and rally act on whole squads through SquadOrderIntent and the CommandProcessor gate; the gate returns NO_SQUADS, UNKNOWN_SQUAD, UNKNOWN_VERB or RUN_OVER as values (check order as listed, RUN_OVER first) with command_rejected and no state change; ids are applied and squad_ordered is emitted in creation order whatever order they arrive in; squad_ordered carries none for follow, the frozen anchor for hold, the king position for rally"
    requirement: UNIT-06
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_order_intent.gd (12 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Follow keeps the anchor on the king every step by day and at night and the squad guards around him; hold freezes the anchor at the living centroid at the apply tick (the post when nobody is alive), fights inside guard_range of it and returns; rally walks to the king position ignoring enemies and then holds there; a following squad at its slots does not move; two squads following the king stay apart; two squads rallied to one point stop ignoring enemies"
    requirement: UNIT-05
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_orders.gd (13 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Stances, anchors and orders persist across begin_night and the dawn restore and into the next day; a night replacement spawns at the building post and walks to the following squad"
    requirement: UNIT-10
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_stance_persistence.gd (3 tests)"
        status: pass
      - kind: command
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (REPLAY_OK digest 2599c7c2... unchanged)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Left click within 32 px (inclusive) of a unit selects its squad, Ctrl-click toggles, double-click selects every squad of the same unit type, empty ground clears (Ctrl keeps), a slot click selects that squad, a STOP HUD control swallows the click; the selection list is always in creation order; Tab cycles in creation order and wraps"
    requirement: UNIT-09
    verification:
      - kind: unit
        ref: "tests/unit/test_selection_model.gd (13 tests), tests/unit/test_selection_math.gd (8 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_squad_selection.gd (8 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every unit of a selected squad shows a cyan ring over a dark under-ring drawn by two MultiMeshInstance3D layers that follow the interpolated puppets, and the squad slot shows the 4 px #8CEBFF border over the bluer plate; hover shows the 2 px grey border; nothing selected draws no ring"
    requirement: UNIT-09
    verification:
      - kind: e2e
        ref: "tests/e2e/test_squad_selection.gd#test_a_click_on_a_footman_selects_its_squad_and_rings_its_units and #test_hovering_a_slot_draws_the_grey_border_and_selected_keeps_the_cyan_one"
        status: pass
    human_judgment: false
  - id: D6
    description: "F follow, H hold, R rally, Tab cycle and F2 select all work on the selection by key and by bare D-pad / R3; fast-forward is on T; a verb with nothing selected issues no order and shows 'Select a squad first'; every gameplay action still has a keyboard and a pad binding and no two share one"
    requirement: INPT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_input_map.gd (17 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_command_keys.gd (11 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "One toast at a time in the hint-strip slot (y 504..536), a toast replaces the one showing and the armed line returns after it; the longest toast is one line centred on x 640, below the protected centre"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_command_keys.gd#test_the_longest_toast_is_one_centred_line_in_the_hint_slot"
        status: pass
    human_judgment: false
  - id: D8
    description: "The ROADMAP overview controls paragraph, the .claude/CLAUDE.md Platform bullet (equal to PROJECT.md's) and Input rows, and the two STACK.md rows state the 2026-10-09 decision"
    verification:
      - kind: command
        ref: "the task 3 grep chain over .planning/ROADMAP.md, .claude/CLAUDE.md and .planning/research/STACK.md (DOC_GREPS_OK, PLATFORM_EQUAL)"
        status: pass
    human_judgment: false
  - id: D9
    description: "Whether the selection ring, slot highlight, F/H/R feel and the follow, hold and rally behaviour read well in play; the owner judges the assumed hold-at-centroid and rally-ignores-enemies contracts at the Phase 3 UAT"
    verification: []
    human_judgment: true
    rationale: "Feel and legibility are the owner's to judge; a real-window capture showed rings under all eight units, cyan slot borders, the follow glyph and the toast above the strip, and plan 03-12 captures the formal screenshots"

duration: 72min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 06: Squad Orders, Selection and Command Keys Summary

**Whole-squad follow, hold and rally through one validated gate with persistent stances, mouse selection with ground rings and a highlighted slot, and F/H/R/Tab/F2 keys with a "Select a squad first" toast**

## Performance

- **Duration:** 72 min
- **Started:** 2026-10-10T12:07:01Z
- **Completed:** 2026-10-10T13:19:25Z (code); SUMMARY and tracking follow
- **Tasks:** 3 (all TDD: RED then GREEN each)
- **Files modified:** 48 (per `git diff --name-only 1cd4fc5 HEAD`, `.uid` files included)

## Accomplishments

- **Orders (Task 1):** `SquadOrderIntent` goes through the dispatch-table `CommandProcessor` (RUN_OVER, NO_SQUADS, UNKNOWN_SQUAD, UNKNOWN_VERB, each a returned value plus `command_rejected`, nothing changed). `SquadSystem.apply_order` acts in creation order and emits `squad_ordered` with the resolved points, which the recorder quantises. Follow keeps the anchor on the king each step; hold freezes it at the living centroid (the post when nobody is alive); rally walks to the king position ignoring enemies, then holds. `begin_night` and `restore_for_dawn` never touch stance, anchor or the walk, and a night replacement still spawns at the post and walks to the squad's current anchor. SquadSystem is at 17 public methods; KingState and UnitSystem were not touched.
- **Selection (Task 2):** `SelectionModel` (creation order, one `changed` per mutation, none for a no-op, Tab wraps) and `SelectionMath` (inclusive 32 px, first-created wins ties) are pure. `SelectionController` handles click, Ctrl-click, double-click and empty ground from `_unhandled_input`, so a STOP control blocks it. `SelectionRings` draws a cyan ring (outer 1.1 m, 0.1 m thick) over a dark under-ring from two MultiMesh layers; `SquadSlot` takes the click, a 2 px grey hover border and the 4 px #8CEBFF selected border over a bluer plate with no layout jump.
- **Command keys (Task 3):** five new Input Map actions with keyboard and pad bindings, fast-forward on T, `CommandKeyController` polling them (Pitfall 6) and `Toast` in the hint-strip slot with the armed-line fallback 03-07 needs. The ROADMAP overview, `.claude/CLAUDE.md` and `.planning/research/STACK.md` now state the 2026-10-09 mouse decision.
- **Self-verification:** a real-window capture (Forward+, RTX 3060) of the squad fixture showed `select_all` ringing all eight units with both slots bordered cyan, `squad_follow` on the barracks walking the footmen to the king with the `>>` glyph on its slot, and the toast "Select a squad first" in the hint slot above the strip.
- Suite: 115 scripts / 1024 tests at baseline to 122 scripts / 1094 tests, all passing (12471 asserts, exit 0); lint clean; the smoke replay digest `2599c7c2...` is byte-identical.

## Task Commits

1. **Task 1 RED: order, gate and persistence tests + inert skeleton** - `c8a3a63` (test)
2. **Task 1 GREEN: follow, hold, rally, gate, persistence** - `4d45799` (feat)
3. **Task 2 RED: selection tests + inert skeletons** - `cfaa56e` (test)
4. **Task 2 GREEN: selection model, picking, controller, rings, slot styling** - `cb9b778` (feat)
5. **Task 3 RED: Input Map, command-key and toast tests + inert skeletons** - `bc27113` (test)
6. **Task 3 GREEN: bindings, CommandKeyController, Toast, docs sync** - `d7ab7b2` (feat)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md, ROADMAP.md and REQUIREMENTS.md (see `git log --grep "docs(03-06)"`).

RED evidence: `gsd check tdd-red-evidence` returned `RED_EVIDENCE_OK` (`target_test_failed`) for `test_follow_puts_the_anchor_on_the_king_every_step_by_day_and_at_night`, `test_follow_carries_no_point` and `test_a_following_squad_still_follows_the_king_the_next_day` (Task 1), `test_cycle_next_walks_the_squads_in_creation_order_and_wraps`, `test_a_point_exactly_32_px_away_hits` and `test_a_click_on_a_footman_selects_its_squad_and_rings_its_units` (Task 2), `test_keyboard_bindings_match_the_binding_table` and `test_a_verb_with_nothing_selected_issues_no_order_and_says_so` (Task 3).

## TDD Gate Compliance

RED (`test(03-06)`) precedes GREEN (`feat(03-06)`) for all three tasks. Each RED commit carries inert skeletons (class names, stub methods, an empty `ring_count`) so the tests compile and fail on an assertion. In the Task 1 RED, `test_a_squad_that_is_not_ordered_stays_at_its_post` and one gate test passed immediately because the stub changes nothing (the default already satisfies them). No REFACTOR commit was needed; lint formatting was applied with each commit.

## Files Created/Modified

See `key-files` above. Notable: `simulation/squads/squad_system.gd` (apply_order, walk and follow handling), `simulation/commands/command_processor.gd` (the squad-order gate), `presentation/units/selection_rings.gd` (two MultiMesh layers), `ui/hud/toast.gd`, `input/command_key_controller.gd`.

## Decisions Made

See `key-decisions` above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] A rally walk could never end for two squads sent to one point**
- **Found during:** Task 1 (design of the arrival rule, then pinned by a test)
- **Issue:** the plan ends a walk when every unit is within `ARRIVE_DISTANCE` of its slot. Two squads rallied to the king overlap, so `separate()` keeps pushing units off their slots (about 0.3 m short of arrival); the squads would then ignore enemies for ever, a defence-breaking bug after "F2, R".
- **Fix:** `Squad.moving_ticks_left` is set at the apply tick to the ticks the farthest unit needs plus `SquadOrders.WALK_GRACE_SECONDS` (2 s, a guard like `MAX_UNITS_PER_SQUAD`, not a tuning value); the walk ends on arrival or when it runs out. `SquadOrders.farthest_from_slot` is the shared measure.
- **Files modified:** `simulation/squads/squad.gd`, `simulation/squads/squad_orders.gd`, `simulation/squads/squad_system.gd`
- **Verification:** `test_squad_orders#test_two_squads_rallied_to_one_point_do_not_ignore_enemies_for_ever`
- **Committed in:** `c8a3a63` (test), `4d45799`

**2. [Rule 1 - Bug] A literal "stays still within arrival distance" needs a deadband, and the settled formation is within 0.25 m, not 0.05 m**
- **Found during:** Task 1 (the [edge UNIT-06 adjacency] must-have)
- **Issue:** the plain walk-to-slot moves a unit that is 0.1 m off its slot, which contradicts "a following squad whose units stand within arrival distance of their slots does not move".
- **Fix:** a following squad computes `Squad.settled` at the start of its turn (every unit within `ARRIVE_DISTANCE`); units with nothing to fight then keep still. The settled formation therefore rests within 0.25 m of its slots, so the follow tests use `ARRIVE_DISTANCE` as their tolerance; hold and post still settle exactly (0.05 m).
- **Files modified:** `simulation/squads/squad.gd`, `simulation/squads/squad_system.gd`, `tests/unit/test_squad_orders.gd`, `tests/unit/test_squad_stance_persistence.gd`
- **Verification:** `test_a_following_squad_already_at_its_slots_does_not_move`, `test_a_following_squad_walks_to_slots_around_the_king`
- **Committed in:** `4d45799`

**3. [Rule 1 - Bug] A private helper named `_set` clashes with Object's virtual `_set`**
- **Found during:** Task 2 (first GREEN run; the whole MapRoot failed to parse)
- **Issue:** `SelectionModel._set(...)` overrides `Object._set(StringName, Variant) -> bool` with a different signature.
- **Fix:** renamed to `_store`.
- **Files modified:** `input/selection_model.gd`
- **Verification:** `test_selection_model` (13 tests) and the full suite
- **Committed in:** `cb9b778`

**4. [Rule 3 - Blocking] Pointer tests cannot aim at the HUD through Input.parse_input_event in the headless runner**
- **Found during:** Task 2
- **Issue:** the plan suggests `Input.parse_input_event` in the stretched 2D space. In the headless GUT run the root window is 64x64 stretched to a 1280x1280 visible rect, so event positions are multiplied by 20 on the way in, and GUT's own output panel (a `RichTextLabel`) covers the root window and takes a click aimed at the squad strip.
- **Fix:** `test_squad_selection` lays the real map scene out in a 1280x720 `SubViewport` and sends events with `push_input`, which runs the same GUI-then-unhandled chain with exact coordinates. The click-blocking, double-click, Ctrl and slot paths are all exercised through the real controller and slot.
- **Files modified:** `tests/e2e/test_squad_selection.gd`
- **Verification:** `test_squad_selection` (8 tests)
- **Committed in:** `cb9b778`

**5. [Rule 1 - Bug in the plan's measurement] The longest toast measures 526 px, not "about 460 px / at most 512 px"**
- **Found during:** Task 3
- **Issue:** the must-have and UI-SPEC estimate the line "Can't go there. Click a point on the visible ground." at about 460 px and test for at most 512 px inside x 384..896. Godot's default font at size 22 measures it at 526 px (x 377..903 when centred), so that bound can never pass without changing the UI-SPEC copy or size.
- **Fix:** the copy, size and slot are unchanged. The test now checks what the estimate was protecting: one line, centred on x 640, rect `y 504..536`, not intersecting the protected centre `Rect2(384, 96, 512, 404)` (the toast sits wholly below its bottom edge y 500), and a text width of at most 640 px. Plan 03-12's `hud_long_toast` screenshot should expect a 526 px line, a little wider than the UI-SPEC says.
- **Files modified:** `tests/e2e/test_command_keys.gd`
- **Verification:** `test_command_keys#test_the_longest_toast_is_one_centred_line_in_the_hint_slot`
- **Committed in:** `d7ab7b2`

---

**Total deviations:** 5 auto-fixed (2 Rule 1 in code, 1 Rule 1 in the plan's measurement, 1 Rule 2, 1 Rule 3)
**Impact on plan:** none on scope or the owner decisions. Two additions to the order state machine (walk budget, settled flag), one renamed method, one test harness change, one corrected measurement.

## Authentication Gates

None.

## Known Stubs

None that block the plan's goal. By the plan's design: `SelectionController.feedback` is declared but never emitted (later plans report with it, and the Toast already connects); `Squad.queue` and the `points` and `queued` parameters of `SquadSystem.apply_order` carry no behaviour until 03-07; `executing_verb()` returns empty until 03-07 adds the point verbs; `SquadSlot.set_group()` still only remembers its value (03-08). The UI-SPEC hover preview (rings at alpha 0.4), group-recall flash and drag box are not in this plan.

## Threat Flags

None. T-03-10 (mitigate) holds: the gate rejects an empty list, an unknown squad and a verb outside `SquadOrders.is_supported` as returned reasons before any state changes, each pinned by `test_squad_order_intent`. T-03-11 (mitigate) holds: every accepted order emits `squad_ordered` with its resolved points and the recorder writes them (`SimSignals.ALL`, `SimRecorder.HANDLED`, the connect and the handler), so the drift test in `test_determinism` covers it. T-03-SC (accept): no packages and no assets.

## Issues Encountered

- `bash` resolves to WSL inside a Python `subprocess`; the RED-evidence helper had to call Git Bash by its full path, otherwise the test run it wrapped silently did not run and the JUnit XML was stale.
- `Input.parse_input_event` coordinates and the GUT overlay (deviation 4), found by logging the event positions the controller received.
- The shell rejects heredocs with apostrophes; edit scripts were written with the Write tool.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 03-07 can add move, attack-move and patrol by widening `SquadOrders.is_supported`, giving `apply_order` real use of `points` and `queued`, filling `Squad.queue` and `executing_verb`, registering the mouse actions, and using `Toast.set_line`/`clear_line` for the armed-point prompt.
- 03-08 can add the drag box beside the 8 px click slop in `SelectionController`, groups on `SelectionModel`, and fill `SquadSlot.set_group`.
- 03-12: `hud_long_toast` should expect a 526 px line (deviation 5); the pointer-test pattern (SubViewport and `push_input`) is the one to reuse for mouse scenarios.

## Self-Check: PASSED

All created files exist on disk, commits `c8a3a63`, `4d45799`, `cfaa56e`, `cb9b778`, `bc27113` and `d7ab7b2` are in `git log`, the three tasks' acceptance criteria pass (greps, the documentation grep chain, `bash tools/test.sh` exit 0 with 1094/1094, `bash tools/lint.sh` clean, the required suite names in the JUnit XML), and the smoke replay digest is unchanged.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-10*
