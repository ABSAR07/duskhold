---
phase: 03-king-combat-troops
plan: 08
subsystem: presentation
tags: [godot, gdscript, selection, box-select, control-groups, order-markers, drag-box, multimesh, input-map, toast]

requires:
  - phase: 03-king-combat-troops
    provides: "03-07 GroundPick, OrderMarkers pings, SelectionController point commands with escape(), SquadSystem.orders_of() and patrol_path_of(), the owner routing rule (a selected squad takes all movement; Escape clears), the SHARED_BINDINGS_ALLOWED list; 03-06 SelectionModel, SelectionMath, SelectionRings, CommandKeyController, Toast; 03-05 SquadSlot with its hidden GroupBadge"
provides:
  - "SquadPlanView: per-squad patrol line (dashed #FFE073, 0.12 m, end discs, flashing 1.5 s when set) and numbered queued discs (verb colours, joining line, at most 6), drawn for selected squads only through OrderMarkers"
  - "SelectionController.hovered_squad() and SelectionRings hover preview at alpha 0.4"
  - "SelectionMath.squads_in_rect, DragBox, and box select with the 8 px threshold, Ctrl add, Escape/right-click cancel and the off-ground release drop"
  - "SelectionModel control groups (ten groups of squad ids): store_group, recall_group, group_members, lowest_group_of, badge_digit, group_recalled"
  - "Input Map group_1..group_9, group_0 and selection_modifier; CommandKeyController store/recall branch; Toast GROUP_SAVED and GROUP_EMPTY; SquadSlot group badge; SelectionRings recall flash"
affects: [03-09, 03-10, 03-11, 03-12]

actuals:
  tokens: 21700
  tasks: 3
  commits: 8

plan_head_before: 587c317ade0d683f2ad124a286f3f9b8b919d768
plan_head_after: 1c2ba0046418f51289684eb926111e198a693311
commits: 8

tech-stack:
  added: []
  patterns:
    - "A plan view per squad rebuilds its mesh only when hash(orders) or hash(path) changes; discs and Label3D numbers are pooled nodes"
    - "Once a left press is held, motion and release are read in _input (before the GUI), so a drag that wanders over a STOP squad slot still ends; the press itself stays in _unhandled_input so a slot swallows it (Pitfall 8)"
    - "Presentation hooks keep their own copies of per-instance data (ring alpha, scale, position, patrol corner points) because the headless dummy renderer cannot be read back"
    - "Ten digit actions plus one modifier action, with the modifier read at the moment of the digit press, instead of Ctrl+digit chord actions (Pitfall 5)"

key-files:
  created:
    - presentation/units/squad_plan_view.gd
    - ui/hud/drag_box.gd
    - tests/e2e/test_order_markers.gd
    - tests/e2e/test_box_select.gd
    - tests/e2e/test_control_group_keys.gd
    - tests/unit/test_control_groups.gd
    - tests/unit/test_input_map_groups.gd
  modified:
    - presentation/units/order_markers.gd
    - presentation/units/selection_rings.gd
    - input/selection_controller.gd
    - input/selection_math.gd
    - input/selection_model.gd
    - input/command_key_controller.gd
    - ui/hud/hud.tscn
    - ui/hud/squad_slot.gd
    - ui/hud/squad_slot.tscn
    - ui/hud/squad_strip.gd
    - ui/hud/toast.gd
    - project.godot
    - tests/unit/test_selection_math.gd
    - tests/unit/test_input_map.gd
    - tests/e2e/test_squad_strip.gd

key-decisions:
  - "Control-group semantics (RESEARCH A12, the UI-SPEC's unresolved row, decided here): groups hold squad ids; squads are never deleted so a member never drops at 0 alive; a newly built squad joins no group; storing replaces the group's members; storing an empty selection is refused with 'Select a squad first' and leaves the group untouched; recalling an empty group keeps the selection and shows 'Group N is empty'. The owner may ask for auto-join at the UAT"
  - "The store and empty-recall toasts name the key digit, so key 0 reads 'Group 0 saved' and 'Group 0 is empty', matching the badge; group 10 is the internal number"
  - "A drag released with no ground under it (ray misses the plane or the centimetre point is outside ground_half_extent) is dropped like a cancel: the selection stays and no toast shows; a drag released on ground over no unit still clears the selection without Ctrl"
  - "A drag may begin from a press that hits the ground plane even when that point is outside ground_half_extent; only the release point is bounds-checked"
  - "A badge shows the lowest group number the squad is in (1..9 then 0 for group 10); storing the same members again is a no-op and emits no changed"
  - "Hover is computed from the last unhandled mouse position every frame, suppressed while a drag is active, and cleared when the pointer leaves the window"

patterns-established:
  - "RED with an inert skeleton committed beside the failing tests, then GREEN, for all three tasks (the Input Map actions are configuration and landed with the Task 3 RED skeleton so polled e2e tests fail on assertions, not on unknown actions)"
  - "A mutation probe on the off-ground drag drop (the bounds check disabled) failed the matching e2e test, then the check was restored"

requirements-completed: [UNIT-09, UNIT-10, INPT-01]

coverage:
  - id: D1
    description: "A selected patrolling squad shows a dashed #FFE073 line whose geometry reaches every waypoint, with a 0.4 m disc at each end, flashing for 1.5 s after a new patrol order; deselecting removes line, discs and geometry"
    requirement: UNIT-10
    verification:
      - kind: e2e
        ref: "tests/e2e/test_order_markers.gd#test_a_patrolling_selected_squad_shows_a_dashed_line_through_its_path and #test_a_new_patrol_flashes_the_line_for_one_and_a_half_seconds"
        status: pass
    human_judgment: false
  - id: D2
    description: "Queued orders show as numbered 0.4 m discs (the running order skipped), cyan move, #FF7A59 attack-move, #FFE073 patrol, at most 6 of the 9 the simulation keeps, for selected squads only and nothing with nothing selected"
    requirement: UNIT-10
    verification:
      - kind: e2e
        ref: "tests/e2e/test_order_markers.gd (three queued moves, ten queued orders, each verb colour, unselected and nothing selected)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Hovering within 32 px of an unselected squad's unit previews its rings at alpha 0.4 without changing the selected squads' rings; a selected squad is not previewed; off-screen selected units keep their rings and slot highlight; a squad down to one unit has one ring"
    requirement: UNIT-09
    verification:
      - kind: e2e
        ref: "tests/e2e/test_order_markers.gd (hover, hovered-never-recolours, walked off screen, one unit)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Dragging past 8 px from a press on the ground draws the DragBox (#8CEBFF fill 0.16, 2 px border 0.9, no radius, mouse IGNORE) and the release selects every squad with a unit inside it; Ctrl adds; an empty box clears (Ctrl keeps); Escape or a right click mid-drag cancels; a press on a slot or while attack-move is armed never starts a drag; a release off the ground changes nothing and shows no toast; hover rings are suppressed while the box is up"
    requirement: UNIT-09
    verification:
      - kind: unit
        ref: "tests/unit/test_selection_math.gd (6 squads_in_rect tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_box_select.gd (13 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Ctrl + 1..9 / 0 stores the selection as group 1..10 ('Group N saved'), the bare digit recalls it and flashes the rings once (alpha 1.0 and scale 1.0 to 1.2 to 1.0 over 0.15 s), an empty group says 'Group N is empty' and keeps the selection, storing nothing says 'Select a squad first'; ten digit actions plus one modifier action branched in code"
    requirement: UNIT-09
    verification:
      - kind: unit
        ref: "tests/unit/test_control_groups.gd (14 tests), tests/unit/test_input_map_groups.gd (2 tests), tests/unit/test_input_map.gd (shared-binding scan now covers the group actions)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_control_group_keys.gd (9 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Each squad slot shows its lowest group number in the 20x20 badge (group 10 as 0), hidden when in no group, without growing the 72 px slot; a squad at 0 alive keeps its group and badge; a squad built later is in no group"
    requirement: UNIT-09
    verification:
      - kind: e2e
        ref: "tests/e2e/test_squad_strip.gd#test_the_group_badge_is_a_twenty_by_twenty_box_hidden_until_a_group_digit_is_set, tests/e2e/test_control_group_keys.gd"
        status: pass
    human_judgment: false
  - id: D7
    description: "Whether the plan lines, numbered discs, hover rings, drag box, recall flash and slot badges read well in play and whether control groups should auto-join a newly built squad; the owner judges them at the Phase 3 UAT"
    verification: []
    human_judgment: true
    rationale: "Feel and legibility are the owner's; real-window probe captures (Forward+, RTX 3060) showed the patrol line with end discs, numbered cyan, red and yellow discs on their joining lines, the translucent drag box, the 'Group 1 saved' toast and the '1' badges, and plan 03-12 captures the formal screenshots including the ten-order overflow shot"

duration: 64min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 08: Patrol Lines, Queued Discs, Box Select and Control Groups Summary

**Each selected squad's patrol path and numbered queued orders drawn on the ground, hover ring previews, drag-box selection with Ctrl add and clean cancels, and ten Ctrl+digit control groups with slot badges, toasts and a recall flash, completing the keyboard-and-mouse command layer**

## Performance

- **Duration:** 64 min
- **Started:** 2026-10-10T14:57:37Z
- **Completed:** 2026-10-10T16:01:31Z (code at 15:55); SUMMARY and tracking follow
- **Tasks:** 3 (all TDD, RED then GREEN each, plus two small follow-up commits)
- **Files modified:** 29 (per `git diff --name-only 587c317 HEAD`, `.uid` files included)

## Accomplishments

- **Ground feedback (Task 1):** `SquadPlanView` draws, per selected squad, the patrol path as a dashed #FFE073 ground line (every dash starts a segment and the last one ends on the waypoint, so the line visibly passes through each point) with 0.4 m end discs, flashing for 1.5 s after a new patrol order, and the waiting orders (running order skipped) as numbered 0.4 m discs joined by a thin line coloured by verb, at most six shown. Meshes rebuild only when `hash(orders)` or `hash(path)` changes; discs and `Label3D` numbers are pooled. `OrderMarkers` owns one view per squad and hides the views of unselected squads. `SelectionController.hovered_squad()` and `SelectionRings` add the alpha-0.4 hover preview, never recolouring the selected squads.
- **Box select (Task 2):** `SelectionMath.squads_in_rect` (inclusive edges, corners in either order, creation order). `DragBox` (Panel under `HudRoot`, mouse IGNORE) shows between the press and the cursor once motion passes `DRAG_THRESHOLD_PX := 8.0` from a press on the ground. The release replaces the selection (Ctrl unions, an empty box clears, Ctrl keeps). Escape or a right click mid-drag cancels; a release with no ground under it is dropped like a cancel with no toast; hover is suppressed while dragging.
- **Control groups (Task 3):** `SelectionModel` stores ten groups of squad ids. `CommandKeyController` polls the ten digit actions and branches on `selection_modifier` at the moment of the press (Pitfall 5): Ctrl stores ('Group N saved' or 'Select a squad first'), bare recalls (or 'Group N is empty'). `SquadStrip` feeds `SquadSlot.set_group` the lowest group's badge digit on every selection or group change. `SelectionRings` flashes the recalled squads' rings once (alpha 1.0, scale 1.0 to 1.2 to 1.0 over 0.15 s).
- **Self-verification:** a real-window probe (Forward+, RTX 3060, scratch script outside the repo) showed the patrol line with end discs, the numbered discs 1 (cyan), 2 (#FF7A59) and 3 (#FFE073) on their joining lines, the translucent drag box with its 2 px border, the 'Group 1 saved' toast and a '1' badge on each slot. The first capture showed the numbers a few pixels tall, so the pixel size went from 0.012 to 0.02 and the label sits on the disc (commit `dcacbd6`).
- Suite: 130 scripts / 1175 tests at baseline to 135 scripts / 1229 tests, all passing (13671 asserts, exit 0); lint clean; the smoke replay digest `2599c7c2...` is byte-identical (`REPLAY_OK scenario=smoke`). A mutation probe (the off-ground drop disabled) failed `test_a_drag_released_beyond_the_ground_selects_nothing_and_shows_no_toast`, then the check was restored.

## Task Commits

1. **Task 1 RED: patrol line, queued disc and hover ring tests + inert hooks** - `b3604e7` (test)
2. **Task 1 GREEN: SquadPlanView, hover rings** - `721d93f` (feat)
3. **Task 2 RED: squads_in_rect and box select tests + inert DragBox** - `443290f` (test)
4. **Task 2 GREEN: drag box select, Ctrl add, cancels** - `bcccdef` (feat)
5. **Task 3 RED: control group, digit key and badge tests + Input Map actions** - `1087138` (test)
6. **Task 3 GREEN: control groups, badges, toasts, recall flash** - `4ef4f7a` (feat)
7. **Legible disc numbers after the real-window probe** - `dcacbd6` (fix)
8. **One disc cap constant** - `1c2ba00` (refactor)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md, ROADMAP.md and REQUIREMENTS.md (see `git log --grep "docs(03-08)"`).

RED evidence: Task 1 RED had 10 of 10 failing on assertions against the inert hooks; Task 2 RED had 11 of 13 e2e and 4 of 14 math tests failing (the slot-press and armed-attack-move guards pass trivially before a box exists and stay as regression guards); Task 3 RED had every control-group, digit-key and badge test that stores or recalls failing on assertions (the pure model tests that exercise the inert stubs, the nine key tests and the badge test). `test_input_map_groups` was green at RED because the Input Map actions are configuration and landed with the skeleton so the polled e2e tests did not fail on unknown-action engine errors.

## TDD Gate Compliance

RED (`test(03-08)`) precedes GREEN (`feat(03-08)`) for all three tasks, each RED commit carrying an inert skeleton so the tests compile and fail on assertions. The two follow-up commits (`fix`, `refactor`) are polish after the real-window probe and a literal-constant acceptance check.

## Files Created/Modified

See `key-files` above. Notable: `presentation/units/squad_plan_view.gd` (new, the ground plan drawing), `input/selection_controller.gd` (drag state, hover), `input/selection_model.gd` (control groups), `ui/hud/drag_box.gd` (new), `ui/hud/squad_slot.tscn` (badge box).

## Decisions Made

See `key-decisions` above. The control-group semantics are the planner decision recorded for RESEARCH A12 and the UI-SPEC's unresolved row.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The group badge grew the slot**
- **Found during:** Task 3 (`test_squad_strip` badge test measured the badge at 20 x 26)
- **Issue:** the bold 18 px digit label has a line height above 20 px, so a visible badge would have grown the bottom row and the 72 px slot to 78 px.
- **Fix:** the label sits in a plain clipped 20 x 20 `GroupBadgeBox` Control (a non-container parent) and is centred on it, so the badge and the slot keep their size; `SquadSlot.get_badge_label()` is the test accessor.
- **Files modified:** `ui/hud/squad_slot.tscn`, `ui/hud/squad_slot.gd`
- **Verification:** `test_squad_strip` badge test (badge 20x20, slot 72 tall, digit inside the box)
- **Committed in:** `4ef4f7a`

**2. [Rule 3 - Blocking] The 03-05 badge test pinned the placeholder**
- **Found during:** Task 3
- **Issue:** `test_the_group_badge_is_a_hidden_twenty_by_twenty_box_for_plan_03_08` asserted the badge stays hidden after `set_group(3)`.
- **Fix:** rewritten as `test_the_group_badge_is_a_twenty_by_twenty_box_hidden_until_a_group_digit_is_set` (hidden by default, shows the digit, 0 for group 10, hides for -1).
- **Files modified:** `tests/e2e/test_squad_strip.gd`
- **Committed in:** `1087138`, `4ef4f7a`

**3. [Rule 3 - Blocking] `test_input_map.gd` was at the gdlint public-method cap**
- **Found during:** Task 3
- **Issue:** two new key-table tests would have made 22 public functions (cap 20).
- **Fix:** the group key table and its two tests live in the new `tests/unit/test_input_map_groups.gd`; `test_input_map.gd` only gained the `GROUP_ACTIONS` constant so its no-shared-binding scan covers the group actions.
- **Files modified:** `tests/unit/test_input_map.gd`, `tests/unit/test_input_map_groups.gd`
- **Committed in:** `1087138`

**4. [Rule 1 - Bug, in my own test] The one-unit ring test depended on day refill**
- **Found during:** Task 1 (the full suite failed it once: by day a squad below its cap refills within a few frames)
- **Fix:** the test starts the night first (the night trickle takes 10 s) and asserts the alive count before and after the frames.
- **Files modified:** `tests/e2e/test_order_markers.gd`
- **Committed in:** `721d93f`

### Differences from the plan text (no behaviour lost)

- **New file `presentation/units/squad_plan_view.gd`** (not in `files_modified`): `OrderMarkers` holds one per squad so the patrol line and discs are pooled and rebuilt only on change; `OrderMarkers.MAX_DISCS_SHOWN := 6` is the single cap.
- **Motion and release of a held press are read in `_input`:** the press stays in `_unhandled_input` (a STOP slot swallows it), but a release over a slot would otherwise never arrive and leave the drag stuck. A right click mid-drag is also taken in `_input`.
- **A release far from the press with no motion seen counts as a drag** (a test or a lost motion event), starting only when the press hit the ground plane.
- **Test hooks hold their own copies** of ring alpha, scale and position and of the patrol line's corner points, because the headless dummy renderer cannot be read back.
- **Not in the plan's files list:** `tests/unit/test_input_map_groups.gd`, `presentation/units/squad_plan_view.gd`, `ui/hud/squad_slot.tscn`, `tests/e2e/test_squad_strip.gd`.

---

**Total deviations:** 4 auto-fixed (2 Rule 1, 2 Rule 3) plus 5 wording differences
**Impact on plan:** none on scope or the owner decisions; one latent layout bug caught by a test, one stale placeholder test updated.

## Authentication Gates

None.

## Known Stubs

None. The 03-06 `SquadSlot.set_group()` stub is lifted (the badge shows). Still ahead by design: the pad group mode, the pad cursor and the pad bindings of the new keyboard-only group actions (03-09), the formal screenshots including the ten-order overflow shot (03-12), and the command hint strip and prompt glyphs (03-10).

## Threat Flags

None. T-03-14 (accept) holds: work is bounded by the living unit count (two squads of at most 14 units in Phase 3), discs by `MAX_DISCS_SHOWN` 6 and the queue by 9, pings by `MAX_PINGS` 16; `SquadPlanView` rebuilds only on change. T-03-SC (accept): no packages and no assets.

## Issues Encountered

- A hover that began over the playfield stays until the next unhandled mouse motion if the pointer then moves straight onto a HUD slot (a STOP control swallows the motion); leaving the window clears it. The effect is a ring preview that lingers for a moment, and a later plan can clear it on slot hover.
- The shell rejects heredocs with apostrophes or doubled backslashes; larger edit scripts were written to the scratchpad with the Write tool.
- `Rect2.has_point` excludes the far edges, so `squads_in_rect` compares explicitly and includes all four edges.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **03-09 (pad):** the group actions are keyboard-only. The pad group mode must call `SelectionModel.store_group`/`recall_group` (and `lowest_group_of` for the badge) and keep a pad way to cancel; `command_cancel` still has pad B. The pad cursor must go through `GroundPick.to_centimetres`/`in_bounds` and the controller's `arm_attack_move`, `begin_patrol`, `commit_patrol`, `escape`; `SelectionController.escape()` now also cancels a held press.
- **03-10:** hint and prompt text reads keys from the Input Map; the digits and Ctrl are bound as `group_*` and `selection_modifier`. **03-11:** nothing here changes balance.
- **03-12 packet:** capture the ten-order overflow shot (E9 overflow backstop), the drag box mid-drag, the patrol line and disc shots and a badge shot; list the control-group semantics (no auto-join) and Ctrl as the store modifier as owner decisions to confirm in play.

## Self-Check: PASSED

All created files exist on disk, commits `b3604e7`, `721d93f`, `443290f`, `bcccdef`, `1087138`, `4ef4f7a`, `dcacbd6` and `1c2ba00` are in `git log`, every task's acceptance criteria pass (the literal greps for `func disc_count()`, `func patrol_line_count()`, `MAX_DISCS_SHOWN := 6`, `func hovered_squad()`, `static func squads_in_rect(`, `DRAG_THRESHOLD_PX := 8.0`, `class_name DragBox`, the `DragBox` node with `mouse_filter = 2`, `func store_group(`, `func recall_group(`, `func lowest_group_of(`, `const GROUP_COUNT: int = 10`, `group_0={`, `group_9={`, `selection_modifier={` and the two toast strings; `bash tools/test.sh` exit 0 with 1229/1229; `bash tools/lint.sh` clean; the required suite names in the JUnit XML), and `REPLAY_OK scenario=smoke` shows the unchanged digest.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-10*
