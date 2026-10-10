---
phase: 03-king-combat-troops
plan: 09
subsystem: input
tags: [godot, gdscript, gamepad, d-pad, chords, group-mode, ground-cursor, input-map, capability-table]

requires:
  - phase: 03-king-combat-troops
    provides: "03-08 SelectionModel control groups, group digit actions, CommandKeyController store/recall branch, SquadSlot badge; 03-07 GroundPick, SelectionController arm_attack_move/begin_patrol/commit_patrol/escape, the command_cancel INTERIM pad B and the owner routing rule (a selected squad takes all movement); 03-06 SelectionModel, Toast, the F/H/R/Tab/F2 verbs on the bare D-pad"
provides:
  - "PadChords: pure resolution of the D-pad twin pairs (up follow/move, down hold/patrol, right cycle/attack-move) and R3 (select all/select type) from the LB layer and the Start group mode; is_pad_press tells a pad press from a keyboard key"
  - "Input Map pad bindings: squad_move D-pad up, squad_attack_move D-pad right, squad_patrol D-pad down, command_queue RT, command_cancel B; pad-only actions command_layer (LB), group_mode (Start), select_type (R3), cursor_left/right/up/down (right stick)"
  - "CommandKeyController runs the resolved commands, hands a pad point verb to the cursor through pad_point_verb, selects every squad of the cycled squad's type on LB + R3, and runs the Start group mode (step 1..9,0 on the badge, D-pad up recalls, release stores)"
  - "SquadStrip.set_group_edit / SquadSlot.set_group_edit: the badge shows the digit being chosen with a pulsing #8CEBFF border"
  - "GroundCursor (pure screen-space aim point), PadCursorController (right-stick cursor, release confirms through GroundPick centimetres, RT queues, B cancels), PadCursorView (1.2 m ring, dark under-ring, 0.12 m line from the king), CameraRig.set_zoom_suppressed, Toast.ARMED_PAD"
  - "test_input_capabilities: a 21-row table proving a keyboard-and-mouse path and a gamepad path for every in-run capability, with a gesture marker for the double-click backed by test_select_one_type"
affects: [03-10, 03-11, 03-12]

actuals:
  tokens: 20700
  tasks: 2
  commits: 4

plan_head_before: 46cca19c19dc08be623bc4814824dda68d067dc7
plan_head_after: f351b8d60c2e78a2382fc508d5bf523f3c9fda44
commits: 4

tech-stack:
  added: []
  patterns:
    - "A D-pad button bound to two actions makes both just-pressed together; that pair is the pad press, so the LB layer picks one in code (PadChords) and a lone action is a keyboard key that keeps its meaning whatever the pad holds"
    - "A pad point verb is handed to the cursor over a signal (pad_point_verb) instead of a direct call, so the command layer and the cursor stay separate nodes"
    - "The cancel key is owned by CommandKeyController: it asks the pad cursor to cancel first and only falls through to the pointer's escape (which clears the selection), so B while aiming never deselects"
    - "The cursor is confirmed by a held-action level read each frame (Input.is_action_pressed on the D-pad twin) and never by an event, so scripted and real presses behave the same"

key-files:
  created:
    - input/pad_chords.gd
    - input/ground_cursor.gd
    - input/pad_cursor_controller.gd
    - presentation/units/pad_cursor_view.gd
    - tests/unit/test_pad_chords.gd
    - tests/unit/test_input_capabilities.gd
    - tests/unit/test_ground_cursor.gd
    - tests/e2e/test_pad_commands.gd
    - tests/e2e/test_select_one_type.gd
    - tests/e2e/test_pad_cursor.gd
  modified:
    - project.godot
    - input/command_key_controller.gd
    - input/selection_model.gd
    - ui/hud/squad_slot.gd
    - ui/hud/squad_strip.gd
    - ui/hud/toast.gd
    - presentation/camera/camera_rig.gd
    - presentation/map/prototype_map.tscn
    - tests/unit/test_input_map.gd

key-decisions:
  - "Pad layout (RESEARCH A11): D-pad up follow, down hold, left rally, right cycle; LB turns up/right/down into move/attack-move/patrol with the right-stick cursor; R3 select all, LB + R3 select one type; Start held is the group mode; RT held queues; B cancels; X slams. The owner judges the feel at the UAT"
  - "Group mode: the first step from nothing goes to digit 1 (right) or 0 (left); steps wrap 1..9,0; D-pad up recalls the shown group and ends the edit (releasing Start then stores nothing more); a recall of an empty group says 'Group N is empty' and keeps the edit; with no digit shown D-pad up does nothing; stepping with nothing selected says 'Select a squad first'; a keyboard R pressed while Start is held also steps left (rally has no twin)"
  - "Select one type anchors on the squad cycled last when it is still selected, else the first selected squad; with nothing selected it says 'Select a squad first'"
  - "A pad point order carries one point: a pad patrol is a single point and its path starts where the squad stands; multi-point patrols stay a mouse feature (P held, right click each point)"
  - "The cursor confirms on the release of the D-pad button, not of LB, and it only starts when a squad is selected; B or Escape puts it away through CommandKeyController so the selection survives"

patterns-established:
  - "RED with an inert skeleton committed beside the failing tests, then GREEN, for both tasks (the pad bindings and scene nodes are configuration and land with the RED skeleton)"
  - "A mutation probe on the zoom suppression (set_zoom_suppressed made a no-op) failed the matching e2e assertion, then the real code was restored"

requirements-completed: [INPT-02, INPT-01, UNIT-09, UNIT-10]

coverage:
  - id: D1
    description: "A gamepad player commands squads from the D-pad: up follow, down hold, left rally, right cycle to the next squad; holding LB turns them into the move, patrol and attack-move cursor verbs; a keyboard key keeps its meaning whatever the pad holds; PadChords resolves each twin pair from the layer and group mode"
    requirement: INPT-02
    verification:
      - kind: unit
        ref: "tests/unit/test_pad_chords.gd (9 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_pad_commands.gd#test_d_pad_right_selects_the_barracks_then_the_archery, #test_d_pad_down_orders_hold_and_d_pad_up_follow_and_left_rally, #test_lb_and_d_pad_down_does_not_hold_it_hands_patrol_to_the_cursor, #test_keyboard_keys_keep_their_meaning_whatever_the_pad_is_holding"
        status: pass
    human_judgment: false
  - id: D2
    description: "R3 selects all squads and LB + R3 selects every squad of the cycled squad's type; the mouse double-click selects every squad of the clicked squad's type, shown on a map copy with two footman squads so a single click cannot produce the result"
    requirement: UNIT-09
    verification:
      - kind: e2e
        ref: "tests/e2e/test_select_one_type.gd (2 tests), tests/e2e/test_pad_commands.gd#test_r3_selects_both_squads_and_lb_r3_selects_the_type_of_the_cycled_squad"
        status: pass
    human_judgment: false
  - id: D3
    description: "Holding Start enters group mode: D-pad left/right steps the group number 1..9,0 (wrapping) on the selected squad's badge with a #8CEBFF pulse, releasing Start stores the selection ('Group N saved'), Start + D-pad up recalls the shown group, bare D-pad verbs are suppressed, keyboard use afterwards leaves the selection and groups alone"
    requirement: UNIT-09
    verification:
      - kind: e2e
        ref: "tests/e2e/test_pad_commands.gd (the group-mode, wrap, recall, empty-recall, silent-verbs, no-step and nothing-selected tests, and test_using_the_keyboard_after_the_pad_leaves_the_selection_and_the_groups_alone)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The pad aims move, attack-move and patrol with a right-stick ground cursor: it starts on the king, moves at 900 px/s, stays 48 px inside the screen edge, shows the line 'Aim with the right stick, release to confirm', suppresses camera zoom while up, and releasing the D-pad button submits one order at the GroundPick centimetre point (RT queues); B cancels with no order and keeps the selection; invalid ground gives no order and the 'Can't go there' toast; nothing selected never starts it"
    requirement: UNIT-10
    verification:
      - kind: unit
        ref: "tests/unit/test_ground_cursor.gd (10 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_pad_cursor.gd (9 tests); tests/e2e/test_camera_zoom.gd and tests/e2e/test_mouse_commands.gd unchanged and green"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every in-run capability (move, sprint, build, start night, ability, follow, hold, rally, move order, attack-move, patrol, queue, cancel, cycle, select all, select one type, store group, recall group, fast-forward, zoom, overlay) has a keyboard-and-mouse path and a gamepad path; every project action belongs to a capability; the pad bindings and shared D-pad / R3 / stick bindings are pinned"
    requirement: INPT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_input_capabilities.gd (9 tests), tests/unit/test_input_map.gd (shared-binding scan extended, pad button and RT trigger table)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Whether the pad layout (LB layer, Start group mode, R3 chords), the cursor speed and feel, the badge pulse and the aiming line read well on a real pad; the owner judges them at the Phase 3 UAT and confirms that nothing in a run needs a pointer"
    verification: []
    human_judgment: true
    rationale: "Feel and legibility are the owner's; a real pad was not available, so the cursor was driven with scripted joypad events in a real window (Forward+, RTX 3060) and the captures showed the ring and the line from the king, the aiming line above the squad strip, the badge '2' during group mode and the 'Group 2 saved' toast"

duration: 68min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 09: Gamepad Parity for the Command Layer Summary

**D-pad verbs with an LB layer, R3 and LB + R3 selection, a Start group mode with a pulsing badge, and a right-stick ground cursor that confirms on release through the same validated centimetre points as the mouse, with a capability table that pins a keyboard-and-mouse path and a gamepad path for every in-run action**

## Performance

- **Duration:** 68 min
- **Started:** 2026-10-10T17:50:45Z
- **Completed:** 2026-10-10T18:58:21Z (code at 18:57); SUMMARY and tracking follow
- **Tasks:** 2 (both TDD, RED then GREEN each)
- **Files modified:** 29 (per `git diff --name-only 46cca19 HEAD`, `.uid` files included)

## Accomplishments

- **Pad chords (Task 1):** a D-pad button is bound to a bare verb and to the point verb of the LB layer (and R3 to select all and select one type), so one press makes two actions just-pressed together. `PadChords.resolve` takes that pair as the pad press and lets the LB layer pick the member; a lone member is a keyboard key (or the right mouse button) and keeps its meaning whatever the pad holds; while Start is held the D-pad verbs and rally resolve to nothing. `PadChords.is_pad_press` is how `CommandKeyController` tells a pad press of a point verb (handed to the cursor over `pad_point_verb`) from the A key (which arms attack-move) and the P key (which opens a mouse patrol).
- **Select one type and group mode (Task 1):** LB + R3 selects every squad of the type of the squad cycled last (else the first selected). Holding Start edits a group: D-pad right/left step the digit 1..9, 0 (wrapping) on the first selected squad's badge, which pulses #8CEBFF through `SquadStrip.set_group_edit`; D-pad up recalls the shown group; releasing Start stores the selection ('Group N saved'). A badge border of 2 px was added to the 20x20 badge without growing it (fixed zero content margins).
- **Capability table (Task 1):** `test_input_capabilities` lists 21 capabilities with their keyboard-and-mouse actions (or the `double_click` gesture marker) and their pad actions, and fails if an action does not exist, a capability lacks a key/mouse or a joypad event, a marker has no backing scene test, or any project action is left out of the table. `test_select_one_type` drives the real double-click on a copy of the squad fixture with a second barracks (`barracks_2`, 6 m away, `MapConfig.validate()` clean) so the double-click's result differs from a single click's.
- **Ground cursor (Task 2):** `GroundCursor` is the pure screen-space aim point (start, move at 900 px/s, clamp 48 px inside the rect, a small-rect guard). `PadCursorController` starts it on the king's projected ground point when a pad press resolves to move, attack-move or patrol, moves it with the right stick, and on the release of the D-pad button picks the ground with `GroundPick`, bounds-checks it against the map, quantises it with `GroundPick.to_centimetres` and submits one `SquadOrderIntent` (queued while RT is held). Invalid ground gives the 'Can't go there' toast and no order; nothing selected gives 'Select a squad first' and never starts. `CameraRig.set_zoom_suppressed` ignores zoom while it is up and `PadCursorView` draws the 1.2 m #8CEBFF ring, the dark under-ring and the 0.12 m line from the king.
- **Self-verification:** a real-window probe (Forward+, RTX 3060, scratch script outside the repo) with scripted joypad events captured the ring and the line from the king with 'Aim with the right stick, release to confirm' above the squad strip, the badge '2' on the selected squad's slot during group mode and the 'Group 2 saved' toast. A mutation probe (`set_zoom_suppressed` made a no-op) failed `test_the_right_stick_moves_the_cursor_and_zoom_is_suppressed_until_release`, then the real code was restored.
- Suite: 136 scripts / 1250 tests at baseline to 142 scripts / 1306 tests, all passing (14538 asserts, exit 0); lint clean; the smoke replay digest `2599c7c2...` and the army digest `f7a967ed...` are byte-identical (`REPLAY_OK` for both, `--twice`).

## Task Commits

1. **Task 1 RED: pad chords, group mode, capability and select-one-type tests + inert skeleton, pad bindings** - `0296efc` (test)
2. **Task 1 GREEN: PadChords, D-pad verbs, select one type, Start group mode, badge pulse** - `57ad095` (feat)
3. **Task 2 RED: ground cursor and zoom-suppression tests + inert skeleton, scene nodes** - `7b3344a` (test)
4. **Task 2 GREEN: GroundCursor, PadCursorController, PadCursorView, zoom suppression** - `f351b8d` (feat)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md, ROADMAP.md and REQUIREMENTS.md (see `git log --grep "docs(03-09)"`).

RED evidence: Task 1 RED had 7 of 9 (`test_pad_chords`) and 12 of 17 (`test_pad_commands`) failing on assertions against the inert skeleton, and the R3-type assertion of `test_select_one_type` failing (its double-click test passes at RED because the 03-06 branch already exists; it is the gesture's first scene test). The pad bindings are configuration and landed with the skeleton, so `test_input_map` and `test_input_capabilities` were green at RED (the 03-08 precedent). Task 2 RED had 6 of 10 (`test_ground_cursor`) and every pad cursor test that starts, moves, confirms, cancels or clamps failing (the 'Out of bounds' index errors in the e2e RED log come from reading `_ordered[0]` after a failed size assertion).

## TDD Gate Compliance

RED (`test(03-09)`) precedes GREEN (`feat(03-09)`) for both tasks, each RED commit carrying an inert skeleton so the tests compile and fail on assertions. No REFACTOR commit was needed; lint formatting was applied with each commit.

## Files Created/Modified

See `key-files` above. Notable: `input/pad_chords.gd` (new, pure), `input/command_key_controller.gd` (resolution, group mode, point-verb handoff, cancel), `input/pad_cursor_controller.gd` (new), `presentation/units/pad_cursor_view.gd` (new), `project.godot` (pad bindings and seven pad-only actions), `ui/hud/squad_slot.gd` (edit pulse).

## Decisions Made

See `key-decisions` above. The pad layout is the RESEARCH A11 suggestion the plan adopted; the group-mode and select-one-type details are the executor's reading of the UI-SPEC rows.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `PadCursorView` needed a `bind_run`**
- **Found during:** Task 2 RED (the scene run printed `Nonexistent function 'bind_run'` for the new `run_bound` node)
- **Issue:** `MapRoot` calls `bind_run` on every node in the `run_bound` group; the plan puts the view in that group.
- **Fix:** `PadCursorView.bind_run` hides the cursor.
- **Files modified:** `presentation/units/pad_cursor_view.gd`
- **Committed in:** `7b3344a`, `f351b8d`

**2. [Rule 1 - Bug, avoided before it shipped] B while aiming would also have cleared the selection**
- **Found during:** Task 2 design (the plan has the cursor poll `command_cancel` itself, while `CommandKeyController` also polls it and calls `SelectionController.escape()`, which clears the selection when nothing is armed)
- **Issue:** a B press while the cursor is up would have cancelled the cursor and, in the same frame, deselected the squads.
- **Fix:** `CommandKeyController` owns the cancel key: it calls `PadCursorController.cancel()` first and only falls through to `escape()` when the cursor was not up. `test_b_while_held_hides_the_cursor_orders_nothing_and_keeps_the_selection` pins it.
- **Files modified:** `input/command_key_controller.gd`, `input/pad_cursor_controller.gd`
- **Committed in:** `f351b8d`

**3. [Rule 3 - Blocking] Two Task 1 LB tests became wrong when the cursor landed**
- **Found during:** Task 2 full-suite run
- **Issue:** `test_lb_and_d_pad_down_...` and `test_lb_and_d_pad_up_and_right_...` asserted no order at all after an LB + D-pad tap, because the cursor did not exist yet; with it, a tap aims and releases at the king's feet and orders there.
- **Fix:** they now assert the patrol (and the move and attack-move) the tap orders and that no hold, follow or cycle happened.
- **Files modified:** `tests/e2e/test_pad_commands.gd`
- **Committed in:** `f351b8d`

### Differences from the plan text (no behaviour lost)

- **Signal handoff:** `CommandKeyController` emits `pad_point_verb(verb, action)` and `PadCursorController` connects to it in `bind_run`, instead of the controller calling the cursor directly, so Task 1 stands on its own with the point verbs observable before the cursor exists.
- **`PadCursorController.prompt` signal:** the plan lists only `feedback`; the aiming line is a persistent toast-slot line, which `Toast` takes from any node's `prompt` signal, so the cursor declares both.
- **Added helpers not in the interface list:** `PadChords.is_pad_press`, `SelectionModel.last_cycled`, `SquadSlot.set_group_edit` / `is_group_editing` / `badge_border_color`, `PadCursorController.cancel` / `is_active` / `cursor_position`, and the `PadCursorView` hooks `cursor_ground` / `line_length`.
- **The capability and shared-binding tests absorb the pad-only actions:** the pad-only binding table lives in `test_input_capabilities.gd` because `test_input_map.gd` is at the public-method cap; `test_input_map.gd` gained constants and its existing pad-button test was extended and renamed in place.
- **Not in the plan's files list:** `input/selection_model.gd` (`last_cycled`).

---

**Total deviations:** 3 auto-fixed (1 Rule 1 avoided in design, 2 Rule 3) plus 5 wording differences
**Impact on plan:** none on scope or the owner decisions; one latent double-action bug designed out, one missing hook, two stale tests updated.

## Authentication Gates

None.

## Known Stubs

None. The inert skeletons committed at RED are all replaced by their real implementations in the GREEN commits.

## Threat Flags

None. T-03-15 (mitigate) holds: the cursor is clamped 48 px inside the visible rect, its point goes through the same `GroundPick.in_bounds` check and the command gate's `BAD_POINT` validation as the mouse, and `test_pad_cursor` covers release, cancel, the clamp and the invalid-ground toast. T-03-SC (accept): no packages and no assets.

## Issues Encountered

- A mutation probe restored `presentation/camera/camera_rig.gd` with `git checkout --` while it still held uncommitted work, which reset it to the RED skeleton; the file had been copied aside first and was put straight back (the next `git diff` and the suite confirm it).
- The `Write` tool created CRLF files; they were converted to LF before the lint and the commits (the repo's `eol=lf` attribute normalises them on add anyway, and gdlint counts the carriage return towards the 100-character limit).
- Pad button 4 (Back) stays the debug overlay and Start (button 6) is the group mode; neither collides with anything else, and no pause action exists yet (Phase 13 may want Start back).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **03-10:** hint and prompt text can read the new actions from the Input Map (`command_layer`, `group_mode`, `select_type`, `cursor_*`); the command hint strip should teach LB + D-pad and Start. The `Toast.ARMED_PAD` line already shows while aiming.
- **03-11:** nothing here changes balance; both replay goldens are unchanged.
- **03-12 packet:** capture the cursor ring and line, the group-mode badge pulse and the aiming line; list the pad layout (LB layer, Start group mode, R3 chords, one-point pad patrol, no auto-join) as owner decisions to confirm on a real pad, along with the cursor speed (`cursor_speed_px_per_s`, 900) and the flagged assumption that "entirely on keyboard and mouse" means each capability has a keyboard or mouse path.

## Self-Check: PASSED

All created files exist on disk, commits `0296efc`, `57ad095`, `7b3344a` and `f351b8d` are in `git log`, every acceptance criterion passes (the literal greps for `class_name PadChords`, `static func resolve(`, `command_layer={`, `group_mode={`, `select_type={`, `cursor_left={`, `cursor_down={`, `PadChords.resolve(`, `group_mode`, the `"select one type"` and `"store group"` rows and `GESTURE_MARKERS`, `double_click = true` and `barracks_2`, `class_name GroundCursor`, `func clamp_to(`, `class_name PadCursorController`, `cursor_speed_px_per_s`, `to_centimetres(`, `func set_zoom_suppressed(` and the `ARMED_PAD` string; `bash tools/test.sh` exit 0 with 1306/1306; `bash tools/lint.sh` clean; the six new suite names and `test_input_map`, `test_command_keys`, `test_control_group_keys`, `test_camera_zoom`, `test_mouse_commands` in the JUnit XML), and the smoke and army replays show their unchanged digests.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-10*
