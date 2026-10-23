---
phase: quick-261023-aos
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - project.godot
  - tests/unit/test_input_map.gd
  - tests/e2e/test_king_ride.gd
  - tests/unit/test_input_capabilities.gd
  - tests/unit/test_glyph_resolver.gd
autonomous: true
requirements: [KING-01, INPT-01, INPT-02]

estimate:
  tokens: 70000
  raw_tokens: 70000
  tasks: 2
  confidence: low

must_haves:
  truths:
    - "With a pad connected, a left-stick push at full travel and an RB press no longer move or sprint the king: move_left, move_right, move_forward, move_back and sprint carry no InputEventJoypadMotion or InputEventJoypadButton (pinned by the renamed gamepad-binding test of tests/unit/test_input_map.gd and by the new e2e test of tests/e2e/test_king_ride.gd, which parses real joypad events and sees the king stay put)"
    - "The keyboard bindings are intact: move_left A and Left, move_right D and Right, move_forward W and Up, move_back S and Down, sprint Shift, with the deadzones 0.2 and 0.5 unchanged; the EXPECTED_KEYS table of test_input_map.gd is byte-identical to 3d1e6ce and its test passes"
    - "Every other action keeps its pad events (owner decision 2026-10-16: pad code stays in the project unsupported): project.godot equals its 3d1e6ce content with only lines 38, 45, 52, 59 and 65 (the five pad events) deleted, so ui_left and ui_right keep their left-stick axis-0 events, and tests/e2e/test_pad_commands.gd and tests/e2e/test_pad_cursor.gd pass unedited"
    - "The capability table and the glyph contract agree with the new map: the move and sprint rows have an empty pad column, listed in KEYBOARD_ONLY_CAPABILITIES; GlyphResolver.first_event returns null for the five actions on the pad, while the xbox_rb and xbox_ls tiles still resolve for raw events (the glyph tiles are kept)"
    - "bash tools/lint.sh exits 0, the smoke replay prints REPLAY_OK against the unchanged golden, the full GUT suite reports failures=0 at 2655 tests (2653 plus 2 new), and the work lands as one commit"
  artifacts:
    - path: "project.godot"
      provides: "The four move actions and sprint with their keyboard events only"
      contains: "\"physical_keycode\":4194325"
    - path: "tests/unit/test_input_map.gd"
      provides: "KEYBOARD_ONLY_ACTIONS and the re-pinned button and stick tables"
      contains: "const KEYBOARD_ONLY_ACTIONS: Array[StringName]"
    - path: "tests/e2e/test_king_ride.gd"
      provides: "End-to-end proof that real pad events no longer ride or sprint the king"
      contains: "func test_a_left_stick_push_and_rb_no_longer_ride_or_sprint_the_king"
    - path: "tests/unit/test_input_capabilities.gd"
      provides: "Keyboard-only move and sprint rows and their pin"
      contains: "const KEYBOARD_ONLY_CAPABILITIES: Array[String] = [\"move\", \"sprint\"]"
    - path: "tests/unit/test_glyph_resolver.gd"
      provides: "RB and left-stick tiles pinned on raw events; the five actions unbound on the pad"
      contains: "JOY_BUTTON_RIGHT_SHOULDER"
  key_links:
    - from: "project.godot [input] move_left / move_right / move_forward / move_back"
      to: "presentation/king/king.gd"
      via: "the king reads Input.get_vector of the four move actions; with no joypad event bound to them, no stick value can reach it"
      pattern: "Input.get_vector(&\"move_left\""
    - from: "project.godot [input] sprint"
      to: "presentation/king/king.gd"
      via: "move_speed reads Input.is_action_pressed(&\"sprint\"), which RB no longer presses"
      pattern: "is_action_pressed(&\"sprint\")"
    - from: "project.godot [input]"
      to: "ui/hud/glyph_resolver.gd"
      via: "first_event walks InputMap.action_get_events, so a pad lookup of the five actions now returns null"
      pattern: "static func first_event"
---

<objective>
Strip the gamepad events from the king's movement actions. That means move_left, move_right, move_forward and move_back (one left-stick InputEventJoypadMotion each) and sprint (the RB InputEventJoypadButton, button_index 10). The change is in project.godot only, and the contract tests that pin those events follow it.

Why: the Phase 5 UAT (2026-10-22) ran a real window with a PS4 controller connected. With nothing pressed, the king walked 1 to 5 m off his plot between stands, because the stick noise reached `Input.get_vector` through these unsupported pad events. That cancelled a build hold. A probe that erased the same five events from the InputMap in memory fixed it (`erased_pad_events=5`).

Scope rule: the owner decided on 2026-10-16 that pad code stays in the project unsupported. So exactly these five events go. Every other action, every keyboard binding, every deadzone, the glyph tiles, PadChords, PadCursorController and the pad e2e suites stay as they are.

Shape:
- Task 1 is the tracer. It writes an end-to-end check first (a real parsed joypad event, then Input, then the InputMap from project.godot, then king.gd, then the king's position) plus the input-map re-pin. It runs them red, deletes the five lines and runs them green.
- Task 2 expands to the two other contracts that read these events: the capability table and the glyph resolver. It then runs every gate and makes the single commit.

Planned at 2026-10-23T02:50:24Z against HEAD 3d1e6ce.

Planning-time findings beyond the orchestrator's brief (authorized from the files as read):
- tests/unit/test_glyph_resolver.gd resolves `_tile(&"sprint", PAD_DEVICE)` to xbox_rb and `_tile(&"move_left" / &"move_back", PAD_DEVICE)` to xbox_ls through `GlyphResolver.first_event`. It reads the InputMap, so it breaks too and joins the scope.
- tests/unit/test_input_map.gd is at the gdlint cap of 20 public methods. Its own comment says so, and `grep -c '^func test_'` prints 20. Its re-pin must rename an existing test, not add one.
- The menu actions ui_left and ui_right (project.godot lines 165 and 172) carry left-stick axis-0 lines identical in form to move_left's and move_right's. So the delete is line-addressed, never content-matched.
- tests/e2e/test_pad_commands.gd and tests/e2e/test_pad_cursor.gd drive only the triggers, the right stick and the D-pad and shoulder buttons. They never touch the five actions. tests/e2e/test_start_night_hold.gd builds its own left-stick events for a rebind render. tests/unit/test_device_model.gd builds its own pad events. None of the four reads these bindings.
</objective>

<execution_context>
@C:/Users/burha/Desktop/Projects/Thronefall-like Game/.claude/gsd-core/workflows/execute-plan.md
@C:/Users/burha/Desktop/Projects/Thronefall-like Game/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@project.godot
@tests/unit/test_input_map.gd
@tests/unit/test_input_capabilities.gd
@tests/unit/test_glyph_resolver.gd
@tests/e2e/test_king_ride.gd

Environment facts (binding for every step):
- Shell: Git Bash only, from the checkout root. Never PowerShell or WSL.
- Wrappers:
  - `bash tools/lint.sh` runs gdlint and gdformat and must exit 0; `bash tools/lint.sh --fix` reformats.
  - `bash tools/test.sh -gselect=<name>` takes one filter per call (the last -gselect wins), matches by substring and exits non-zero on a failure. `-gselect=test_input_map` also runs test_input_map_groups.gd. Each call takes 20 to 90 s.
  - `bash tools/test.sh` is the full suite: 279 scripts and 2653 tests at 3d1e6ce, 892 s. That exceeds the 600000 ms foreground cap, so run it in the background.
  - `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` must print REPLAY_OK.
- GDScript rules (.gdlintrc):
  - static typing everywhere;
  - 100 chars per line, 20 public methods per class, 1000 lines per file;
  - tests follow the GUT 9.7.1 patterns of their neighbours.
- Checkout: the main checkout, branch gsd/phase-01-foundation-day-loop, HEAD 3d1e6ce at planning time. The Godot toolchain lives in the git-ignored .tools/, so there is no worktree.
- The tree carries ` M .planning/phases/05-castle-center-economy-depth/05-UAT.md`, which belongs to the orchestrator. Never stage, edit or commit it.
- project.godot is LF (`.gitattributes` text eol=lf) and must stay LF.
- Commits:
  - never `git stash`, `--no-verify`, push, gh or `git add -A`;
  - never commit this PLAN.md or the SUMMARY.md (the orchestrator does);
  - do not edit .planning/STATE.md, .planning/ROADMAP.md, .planning/PROJECT.md, .planning/REQUIREMENTS.md or .claude/CLAUDE.md. Residual wording in those files goes into the SUMMARY for the orchestrator and the owner.
</context>

<interfaces>
Contracts extracted at planning time (no further exploration needed):

project.godot `[input]` at 3d1e6ce. Each action is a block `name={`, `"deadzone": N,`, `"events": [Object(...)` with one line per further event starting `, Object(`, then `]` and `}`. The five lines to delete, by line number:
- 38: move_left, `, Object(InputEventJoypadMotion,...,"axis":0,"axis_value":-1.0,"script":null)`
- 45: move_right, the same with `"axis":0,"axis_value":1.0`
- 52: move_forward, the same with `"axis":1,"axis_value":-1.0`
- 59: move_back, the same with `"axis":1,"axis_value":1.0`
- 65: sprint, `, Object(InputEventJoypadButton,...,"button_index":10,"pressure":0.0,"pressed":false,"script":null)`

Each of the five is the last event of its block, so the `]` line that follows stays valid. Lines 165 (ui_left, axis 0 value -1.0) and 172 (ui_right, axis 0 value 1.0) look the same and MUST stay.

tests/unit/test_input_map.gd (20 public tests, at the cap):
- GAMEPLAY_ACTIONS (lines 15 to 33) includes the five.
- EXPECTED_KEYS (lines 35 to 53) stays as is.
- EXPECTED_BUTTONS line 56 is `&"sprint": [JOY_BUTTON_RIGHT_SHOULDER],`.
- EXPECTED_AXES (lines 72 to 80) has the four move rows at lines 73 to 76, plus zoom_in, zoom_out and fast_forward.
- `test_every_gameplay_action_has_a_gamepad_binding` (line 195) asserts more than 0 pad events for every GAMEPLAY_ACTIONS entry.
- `test_gamepad_button_bindings_match_the_binding_table` asserts the exact button count per EXPECTED_BUTTONS row.
- `test_stick_bindings_match_the_binding_table` only checks that a listed axis is present.

tests/unit/test_input_capabilities.gd (10 public tests):
- CAPABILITIES row `"move": {"keys": MOVE_ACTIONS, "pad": MOVE_ACTIONS},` (line 34).
- CAPABILITIES row `"sprint": {"keys": [&"sprint"], "pad": [&"sprint"]},` (line 35).
- `test_every_capability_has_a_gamepad_path_and_every_action_on_it_has_a_pad_event` (line 184) asserts a non-empty pad list per row and a joypad event per entry.
- `test_the_table_has_the_rows_the_plan_names` pins 21 rows.
- `test_every_project_action_belongs_to_a_capability` reads both sides; the keys side already holds the five.
- The PAD_ONLY_BUTTONS and PAD_ONLY_AXES stick section (lines 125 to 136, test at 249) covers the right-stick cursor actions only: untouched.
- Helpers: `_has_pad_event(action)` and `_has_keyboard_or_mouse_event(action)`.

tests/unit/test_glyph_resolver.gd (13 public tests):
- Helpers `_key(physical: Key)` and `_tile(action, device)`; consts PAD (the tile path prefix), KEYBOARD and PAD_DEVICE.
- Line 91, in `test_pad_buttons_map_to_the_xbox_tiles`: `assert_eq(_tile(&"sprint", PAD_DEVICE), PAD + "xbox_rb.png", "RB")`.
- Lines 107 and 108, in `test_the_triggers_and_sticks_map_to_their_tiles`: move_left and move_back on PAD_DEVICE map to `PAD + "xbox_ls.png"`.
- `test_an_action_with_no_binding_on_a_device_is_unbound_there` asserts `first_event` is null for unbound pairs.
- `GlyphResolver.tile_path(event, label_resolver)` maps a raw event to its tile.

tests/e2e/test_king_ride.gd (10 public tests, 163 lines):
- `after_each` calls `E2eSupport.release_all_actions()`.
- `_start_map() -> MapRoot` (awaits 2 frames); `map_root.get_king()`.
- The pattern to mirror is `test_stick_input_below_the_deadzone_does_not_move_the_king` (line 92): start position, input, `await wait_seconds(0.4)`, `assert_almost_eq(king.global_position.x, start.x, 0.001, ...)`.
- tests/e2e/test_pad_cursor.gd line 97 shows the stick-event idiom: a new InputEventJoypadMotion with axis and axis_value set, passed to `Input.parse_input_event`.

presentation/king/king.gd line 76 reads `Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")`, and line 79 reads `Input.is_action_pressed(&"sprint")`. It is not edited.
</interfaces>

<tasks>

<task type="tracer">
  <name>Task 1: End-to-end, a pad stick push and RB no longer ride or sprint the king (project.godot, input-map re-pin, king-ride e2e)</name>
  <files>tests/e2e/test_king_ride.gd, tests/unit/test_input_map.gd, project.godot</files>
  <precondition>`git rev-parse --abbrev-ref HEAD` prints gsd/phase-01-foundation-day-loop; `git diff --quiet 3d1e6ce -- project.godot tests/unit/test_input_map.gd tests/unit/test_input_capabilities.gd tests/unit/test_glyph_resolver.gd tests/e2e/test_king_ride.gd` exits 0; the pinned Godot binary exists under .tools/ (tools/test.sh exits 3 with "Godot 4.7.2 is not installed" otherwise).</precondition>
  <action>
Tests first (RED), then the binding edit (GREEN). Task 1 makes NO commit: test_input_capabilities and test_glyph_resolver are red until Task 2, and the change lands as one commit.

Step 1. tests/e2e/test_king_ride.gd. This is the end-to-end check of the UAT finding.
- Add two private helpers next to `_ride_distance`:
  - `_pad_axis(axis: JoyAxis, value: float) -> void` builds an InputEventJoypadMotion with that axis and axis_value and passes it to `Input.parse_input_event`, mirroring `_stick` in tests/e2e/test_pad_cursor.gd.
  - `_pad_button(index: JoyButton, pressed: bool) -> void` does the same with an InputEventJoypadButton (button_index and pressed set).
- Add `test_a_left_stick_push_and_rb_no_longer_ride_or_sprint_the_king`:
  - `await _start_map()`, take the king and its start `global_position`.
  - Send `_pad_axis(JOY_AXIS_LEFT_X, 1.0)`, `_pad_axis(JOY_AXIS_LEFT_Y, -1.0)` and `_pad_button(JOY_BUTTON_RIGHT_SHOULDER, true)`.
  - `await wait_seconds(0.4)`, then record `Input.is_action_pressed(&"sprint")` and the king's position.
  - Then reset, BEFORE asserting: send both axes back to 0.0 and RB released, then `await wait_process_frames(1)`. The menu actions ui_left and ui_right keep their own left-stick events, so a held axis must not leak into a later test.
  - Assert the recorded sprint state is false, with a message saying RB no longer reads as sprint since 2026-10-23.
  - Assert the recorded x and z each `assert_almost_eq` the start within 0.001, with messages saying a full stick push no longer rides the king (Phase 5 UAT stick drift).
- Add one `##` header line, at most 100 chars: since 2026-10-23 a full left-stick push and RB move and sprint nothing, because those pad events were removed after the Phase 5 UAT.
- The file goes from 10 to 11 tests.

Step 2. tests/unit/test_input_map.gd. The file stays at exactly 20 public tests (the cap), so rename, do not add.
- Directly above `const EXPECTED_KEYS`, add a `##` doc line and a new const.
  - The doc line is exactly this text, with nothing else on the line: `## Pad events of the four move actions and sprint removed 2026-10-23 (Phase 5 UAT stick drift).`
  - The const is `KEYBOARD_ONLY_ACTIONS: Array[StringName]` holding `&"move_left"`, `&"move_right"`, `&"move_forward"`, `&"move_back"` and `&"sprint"`. Let gdformat lay it out.
- Leave the EXPECTED_KEYS block byte-for-byte unchanged. It is the keyboard-intact proof.
- In EXPECTED_BUTTONS, the sprint row becomes `&"sprint": [],`. The exact-count test then pins zero pad buttons on sprint.
- In EXPECTED_AXES, delete the four move rows. Three rows remain: zoom_in, zoom_out and fast_forward.
- Rename `test_every_gameplay_action_has_a_gamepad_binding` to `test_every_gameplay_action_but_the_keyboard_only_ones_has_a_gamepad_binding`, and make its loop branch:
  - an action in KEYBOARD_ONLY_ACTIONS must have exactly 0 pad events (`assert_eq`, with a message naming the action as keyboard only since 2026-10-23);
  - every other action keeps the existing `assert_gt(pad_events, 0, ...)`.
- Reword header lines 2 to 3 so they no longer claim every gameplay action has a gamepad binding. Every gameplay action has a keyboard binding, and every one but KEYBOARD_ONLY_ACTIONS has a gamepad binding. Keep each line at 100 chars or less.

Step 3. RED. Run `bash tools/test.sh -gselect=test_king_ride` and `bash tools/test.sh -gselect=test_input_map`. Both must FAIL against the unedited project.godot:
- the king rides several metres and sprint reads pressed;
- the five actions still have 1 pad event each, and sprint's button count is 1, not 0.
If either passes, stop and report: the test does not prove the fix.

Step 4. project.godot, line-addressed so ui_left and ui_right keep their identical-looking stick lines.
- First run `sed -n '38p;45p;52p;59p;65p' project.godot` and confirm it prints, in order:
  - the JoypadMotion line with axis 0 value -1.0;
  - axis 0 value 1.0;
  - axis 1 value -1.0;
  - axis 1 value 1.0;
  - the JoypadButton line with button_index 10.
  If anything differs, stop and report; do not guess.
- Then run `sed -i '38d;45d;52d;59d;65d' project.godot`. sed addresses input line numbers, so the five deletes do not shift each other.
- Touch nothing else in project.godot: no key event, no deadzone, no other action. Do not open the Godot editor, which may re-save the file.

Step 5. GREEN. Re-run `bash tools/test.sh -gselect=test_king_ride` and `bash tools/test.sh -gselect=test_input_map`; both pass. The headless run also proves the engine still parses project.godot. Then run `bash tools/lint.sh`; if gdformat reports a diff, run `bash tools/lint.sh --fix` and re-check.
  </action>
  <verify>
    <automated>git show 3d1e6ce:project.godot > build/test-results/aos_base_project.txt && git show 3d1e6ce:tests/unit/test_input_map.gd > build/test-results/aos_base_input_map.txt && test -z "$(sed -n '38p;45p;52p;59p;65p' build/test-results/aos_base_project.txt | grep -v -e '^, Object(InputEventJoypadMotion,' -e '^, Object(InputEventJoypadButton,.*"button_index":10,')" && test "$(sed '38d;45d;52d;59d;65d' build/test-results/aos_base_project.txt)" = "$(cat project.godot)" && ! grep -q $'\r' project.godot && test "$(sed -n '/^const EXPECTED_KEYS/,/^}/p' build/test-results/aos_base_input_map.txt)" = "$(sed -n '/^const EXPECTED_KEYS/,/^}/p' tests/unit/test_input_map.gd)" && grep -Fq '&"sprint": [],' tests/unit/test_input_map.gd && grep -Fxq '## Pad events of the four move actions and sprint removed 2026-10-23 (Phase 5 UAT stick drift).' tests/unit/test_input_map.gd && grep -q '^const KEYBOARD_ONLY_ACTIONS: Array\[StringName\]' tests/unit/test_input_map.gd && bash tools/test.sh -gselect=test_king_ride && grep -q 'test_a_left_stick_push_and_rb_no_longer_ride_or_sprint_the_king' build/test-results/gut-junit.xml && grep -Fq '<testsuite name="tests/e2e/test_king_ride.gd" tests="11" failures="0"' build/test-results/gut-junit.xml && bash tools/test.sh -gselect=test_input_map && grep -q 'test_every_gameplay_action_but_the_keyboard_only_ones_has_a_gamepad_binding' build/test-results/gut-junit.xml && grep -Fq '<testsuite name="tests/unit/test_input_map.gd" tests="20" failures="0"' build/test-results/gut-junit.xml && bash tools/lint.sh</automated>
  </verify>
  <done>
- A parsed full left-stick push plus RB leaves the king within 1 mm of his start, and sprint reads released, in the real map scene.
- The input-map contract pins the five actions at zero pad events, with their keyboard table unchanged.
- project.godot equals its 3d1e6ce content with lines 38, 45, 52, 59 and 65 deleted, and nothing else. Those five base lines are the four JoypadMotion events and the button-10 event. The file stays LF, so ui_left and ui_right (base lines 165 and 172) keep their stick events.
- test_king_ride.gd runs 11 tests and test_input_map.gd runs 20 (still the cap), all passing, per their junit testsuite lines.
- Lint is clean. Nothing is committed yet.
  </done>
</task>

<task type="auto">
  <name>Task 2: Bring the capability table and the glyph contract to the new map, run every gate, commit once</name>
  <files>tests/unit/test_input_capabilities.gd, tests/unit/test_glyph_resolver.gd</files>
  <precondition>Task 1's verify passed, and its three files are uncommitted edits on top of 3d1e6ce.</precondition>
  <action>
Step 1. tests/unit/test_input_capabilities.gd. Planner's choice: a named keyboard-only list, rather than skipping by row name inline. A later keyboard-only action then has a place to go. That answers the 1o5 SUMMARY's "future friction" note for these two rows only, without changing any other row.
- Directly above `const CAPABILITIES` (after the PAD_COLUMN_STATUS const), add:
  - the same exact one-line `##` note as in test_input_map.gd: `## Pad events of the four move actions and sprint removed 2026-10-23 (Phase 5 UAT stick drift).`
  - then `const KEYBOARD_ONLY_CAPABILITIES: Array[String] = ["move", "sprint"]`.
- In CAPABILITIES:
  - the move row becomes `"move": {"keys": MOVE_ACTIONS, "pad": []},`;
  - the sprint row becomes `"sprint": {"keys": [&"sprint"], "pad": []},`.
  - Every other row stays unchanged, and the table keeps its 21 rows.
- Rename `test_every_capability_has_a_gamepad_path_and_every_action_on_it_has_a_pad_event` to `test_every_capability_but_the_keyboard_only_ones_has_a_gamepad_path`.
  - Its loop skips (continue) any capability in KEYBOARD_ONLY_CAPABILITIES.
  - The rest of its body is unchanged: a non-empty pad list, and a joypad event per entry.
- Add `test_the_keyboard_only_rows_have_no_pad_column_and_no_pad_event`. For each name in KEYBOARD_ONLY_CAPABILITIES, assert:
  - `CAPABILITIES.has(name)`;
  - its "pad" list has size 0;
  - every action in its "keys" list fails `_has_pad_event` and passes `_has_keyboard_or_mouse_event`.
- Header: reword line 2 so it says every in-run capability has a keyboard-and-mouse path and, but for KEYBOARD_ONLY_CAPABILITIES, a gamepad path. Add one line saying the move and sprint rows have had an empty pad column since 2026-10-23. Keep each line at 100 chars or less.
- Leave the PAD_ONLY_BUTTONS and PAD_ONLY_AXES section and its test untouched (the right-stick cursor only).
- The file goes from 10 to 11 tests.

Step 2. tests/unit/test_glyph_resolver.gd. The 13 public tests stay 13; the tiles are kept and pinned on raw events.
- Add private helpers beside `_key`:
  - `_pad_button(index: JoyButton) -> InputEventJoypadButton`;
  - `_stick(axis: JoyAxis, value: float) -> InputEventJoypadMotion`.
- In `test_pad_buttons_map_to_the_xbox_tiles`, replace the sprint line with `GlyphResolver.tile_path(_pad_button(JOY_BUTTON_RIGHT_SHOULDER), _identity)` equal to `PAD + "xbox_rb.png"`, with the message "RB".
- In `test_the_triggers_and_sticks_map_to_their_tiles`, replace the move_left and move_back lines with `tile_path(_stick(JOY_AXIS_LEFT_X, -1.0), _identity)` and `tile_path(_stick(JOY_AXIS_LEFT_Y, 1.0), _identity)`, each equal to `PAD + "xbox_ls.png"`. Keep the messages "left stick" and "left stick, other axis".
- In `test_an_action_with_no_binding_on_a_device_is_unbound_there`, loop over move_left, move_right, move_forward, move_back and sprint. For each, assert `GlyphResolver.first_event(action, PAD_DEVICE)` is null, with a message saying it has no pad binding since 2026-10-23, and that `first_event(action, KEYBOARD)` is not null.

Step 3. Gates, all from Git Bash at the checkout root; every one must pass before the commit:
1. `bash tools/lint.sh`. On a format diff, run `bash tools/lint.sh --fix` and re-run.
2. `bash tools/test.sh -gselect=test_input_capabilities`, `bash tools/test.sh -gselect=test_glyph_resolver`, `bash tools/test.sh -gselect=test_input_map` and `bash tools/test.sh -gselect=test_pad_`, one per call. The last runs test_pad_commands.gd and test_pad_cursor.gd unedited.
3. `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` prints REPLAY_OK. Input never reaches the simulation in a replay, so the digest cannot move.
4. The full suite, `bash tools/test.sh`, in the background (run_in_background) with output redirected to build/test-results/quick_aos_full.out. When it exits:
   - copy build/test-results/gut-junit.xml to build/test-results/quick_aos_full_junit.xml, because every later -gselect run rewrites gut-junit.xml and the verify reads the copy;
   - check that its testsuites line reads `failures="0"`;
   - check that its `tests=` count is 2655 (2653 at 3d1e6ce plus the king-ride test and the capability test).
   Explain any other count in the SUMMARY. If a failure appears outside the five files, stop and report it, with the junit testcase name; do not widen the scope.

Step 4. Commit once:
1. Run `node ".claude/gsd-core/bin/gsd-tools.cjs" query commit "chore(quick-261023-aos): strip the pad bindings from the king movement and sprint" --files project.godot tests/unit/test_input_map.gd tests/e2e/test_king_ride.gd tests/unit/test_input_capabilities.gd tests/unit/test_glyph_resolver.gd`.
2. Confirm `git log -1 --format=%s` prints exactly that subject. If it does not, stop and report instead of amending, so you never amend 3d1e6ce or another commit.
3. Amend with `git commit --amend -m "<same subject>" -m "<body>" --trailer "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"`. If your own system reminder names a different attribution line, use that one.
4. Suggested body: "A connected PS4 pad's stick noise reached Input.get_vector through the unsupported left-stick events on the four move actions and walked the king off his plot, cancelling build holds (Phase 5 UAT, 2026-10-22). project.godot drops those four events and sprint's RB button; keyboard bindings and every other action's pad events are unchanged. The input-map, capability and glyph contracts follow, and a king-ride e2e test proves real pad events no longer ride or sprint the king."
5. Confirm `git show --stat HEAD` lists exactly the five files, and that .planning/phases/05-castle-center-economy-depth/05-UAT.md is still an unstaged modification.
  </action>
  <verify>
    <automated>bash tools/lint.sh && grep -Fq 'const KEYBOARD_ONLY_CAPABILITIES: Array[String] = ["move", "sprint"]' tests/unit/test_input_capabilities.gd && grep -Fq '"move": {"keys": MOVE_ACTIONS, "pad": []},' tests/unit/test_input_capabilities.gd && grep -Fq '"sprint": {"keys": [&"sprint"], "pad": []},' tests/unit/test_input_capabilities.gd && grep -Fxq '## Pad events of the four move actions and sprint removed 2026-10-23 (Phase 5 UAT stick drift).' tests/unit/test_input_capabilities.gd && grep -Fq 'JOY_BUTTON_RIGHT_SHOULDER' tests/unit/test_glyph_resolver.gd && bash tools/test.sh -gselect=test_input_capabilities && grep -q 'test_the_keyboard_only_rows_have_no_pad_column_and_no_pad_event' build/test-results/gut-junit.xml && grep -Fq '<testsuite name="tests/unit/test_input_capabilities.gd" tests="11" failures="0"' build/test-results/gut-junit.xml && bash tools/test.sh -gselect=test_glyph_resolver && grep -Fq '<testsuite name="tests/unit/test_glyph_resolver.gd" tests="13" failures="0"' build/test-results/gut-junit.xml && bash tools/test.sh -gselect=test_pad_ && grep -Fq '<testsuites name="GutTests" failures="0" tests="2655"' build/test-results/quick_aos_full_junit.xml && test -z "$(git diff --name-only 3d1e6ce -- tests/e2e/test_pad_commands.gd tests/e2e/test_pad_cursor.gd input ui presentation simulation)" && test "$(git log -1 --format=%s)" = "chore(quick-261023-aos): strip the pad bindings from the king movement and sprint" && test "$(git show --name-only --format= HEAD)" = "$(printf 'project.godot\ntests/e2e/test_king_ride.gd\ntests/unit/test_glyph_resolver.gd\ntests/unit/test_input_capabilities.gd\ntests/unit/test_input_map.gd')"</automated>
  </verify>
  <done>
- The capability table marks move and sprint as keyboard only, with an empty pad column and a pin test. The other 19 rows and the 21-row count are unchanged.
- The glyph contract finds no pad binding for the five actions, still resolves the xbox_rb and xbox_ls tiles from raw events, and still finds every keyboard glyph.
- Lint is clean, the pad e2e suites pass unedited, the smoke replay prints REPLAY_OK, and the full suite reports failures=0 at 2655 tests.
- One commit with the planned subject holds exactly the five files.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| OS joypad events to the InputMap | Untrusted analog stick values from a connected pad enter Input. This change narrows the surface: no stick or shoulder event can press the king's movement or sprint actions any more. |
| project.godot to the engine | The engine parses the INI-like file at boot. A malformed edit breaks every action, not just the five. |
| presentation to simulation | King movement is presentation input. The simulation is driven through CommandProcessor, and replays never read live input (STATE.md 03-10). |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-Qaos-01 | Tampering | project.godot menu actions ui_left / ui_right, whose left-stick lines look the same as move_left's | medium | mitigate | Line-addressed delete after a content check of lines 38, 45, 52, 59 and 65 (Task 1 step 4). The verify demands that project.godot equal the 3d1e6ce blob with exactly those five lines deleted, and that those five base lines are all pad events, so base lines 165 and 172 survive. |
| T-Qaos-02 | Denial of service | project.godot parse (the whole InputMap) | high | mitigate | Headless `bash tools/test.sh -gselect=test_input_map` and the full suite boot the engine on the edited file, and test_every_gameplay_action_exists plus the keyboard-table test must pass. The no-CR check keeps the file LF, and the Godot editor is never opened on it. |
| T-Qaos-03 | Denial of service | Keyboard play (move, sprint) | high | mitigate | The EXPECTED_KEYS block must be identical to 3d1e6ce, and its exact-count test must pass. project.godot must equal the base minus five pad-event lines, so no key event, deadzone or other action can have moved. |
| T-Qaos-04 | Tampering | Simulation determinism | low | mitigate | No simulation file is touched (`git diff --name-only 3d1e6ce -- simulation` is empty), and the smoke replay must print REPLAY_OK against the unchanged tests/golden/smoke.json before the commit. |
| T-Qaos-05 | Repudiation | Commit history (`git commit --amend` after the gsd-tools commit) | medium | mitigate | Amend only after `git log -1 --format=%s` equals the planned subject. HEAD must hold exactly the five files. Never --no-verify, stash, push or gh. Never stage 05-UAT.md, PLAN.md or SUMMARY.md. |
| T-Qaos-06 | Denial of service | A pad player can no longer ride or sprint the king | low | accept | Owner decision 2026-10-16: the pad is unsupported. The UAT showed these events actively harm keyboard play when a pad is merely connected. The D-pad verbs, the pad cursor and the other pad paths still work. |
| T-Qaos-SC | Tampering | npm/pip/cargo installs | low | accept | This plan installs no package, so the package-legitimacy gate has nothing to check. |
</threat_model>

<verification>
Run from Git Bash at the checkout root after both tasks:
- `git log -1 --format=%s` prints `chore(quick-261023-aos): strip the pad bindings from the king movement and sprint`, and `git show --stat HEAD` lists the five files only.
- `git diff --numstat 3d1e6ce -- project.godot` prints 0 added and 5 deleted, and project.godot equals `git show 3d1e6ce:project.godot` with lines 38, 45, 52, 59 and 65 deleted.
- `bash tools/lint.sh` exits 0.
- `bash tools/test.sh -gselect=test_input_map`, `-gselect=test_input_capabilities`, `-gselect=test_glyph_resolver`, `-gselect=test_king_ride` and `-gselect=test_pad_` each pass, one per call.
- `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` prints REPLAY_OK.
- The full suite (`bash tools/test.sh`, background) leaves gut-junit.xml, copied to build/test-results/quick_aos_full_junit.xml, with failures="0" and tests="2655".
- `git status --porcelain` shows only the orchestrator's ` M .planning/phases/05-castle-center-economy-depth/05-UAT.md` (if still uncommitted) and the quick task directory.
</verification>

<success_criteria>
- The five pad events are gone from project.godot, and nothing else in the file changed.
- A connected pad's left stick or RB can no longer move or sprint the king. This is proven through real parsed joypad events in the map scene.
- Keyboard movement and sprint are unchanged, proven by the identical keyboard table and its test.
- Every other action's pad events, the glyph tiles, PadChords, PadCursorController and the pad e2e suites are untouched and green.
- Lint, the smoke replay and the full suite are green, and the change is one commit.
</success_criteria>

<output>
Create `.planning/quick/261023-aos-strip-the-gamepad-bindings-from-the-king/261023-aos-SUMMARY.md` with `status: complete` in its frontmatter. Do not commit it; the orchestrator commits PLAN.md, SUMMARY.md and STATE.md. The SUMMARY must record:

1. The commit hash and subject, and `plan_head_before: 3d1e6ce`.
2. The RED evidence from Task 1 step 3 (which assertions failed before the project.godot edit, with the distance the king rode), and the GREEN runs.
3. The full-suite tests= count and failures=0, and the REPLAY_OK line.
4. The planning-time scope findings:
   - test_glyph_resolver.gd joined the scope;
   - test_input_map.gd is at the 20-method cap, so a test was renamed;
   - ui_left and ui_right keep identical-looking stick lines;
   - the pad e2e suites, test_start_night_hold.gd and test_device_model.gd do not read these bindings.
5. Behaviour consequence: a pad player can no longer ride or sprint the king. The D-pad verbs, the LB layer, the pad cursor, the face buttons, zoom and fast-forward keep their pad events.
6. Residual wording the executor left alone, for the orchestrator and the owner to decide:
   - PROJECT.md and .claude/CLAUDE.md Constraints > Platform say "the pad bindings shipped in Phases 1 to 3 stay in the project unsupported", and five of them are now removed;
   - REQUIREMENTS.md KING-01 still says "with WASD or the left stick", and the 2026-10-16 amendment note says the KING-01 left-stick clause "describe[s] shipped behaviour", which it no longer does;
   - the STATE.md decision bullet of Quick 261016-1o5 lists "pad bindings in project.godot" as kept.
</output>
