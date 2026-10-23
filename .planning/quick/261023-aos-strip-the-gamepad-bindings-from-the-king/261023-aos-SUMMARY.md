---
phase: quick-261023-aos
plan: 01
subsystem: input
tags: [godot, input-map, gamepad, king, tests]
status: complete
requires: []
provides:
  - "move_left, move_right, move_forward, move_back and sprint carry keyboard events only"
affects: [king movement, input map contract, capability table, glyph resolver contract]
tech-stack:
  added: []
  patterns: ["KEYBOARD_ONLY_ACTIONS / KEYBOARD_ONLY_CAPABILITIES lists in the contract tests"]
key-files:
  created: []
  modified:
    - project.godot
    - tests/unit/test_input_map.gd
    - tests/e2e/test_king_ride.gd
    - tests/unit/test_input_capabilities.gd
    - tests/unit/test_glyph_resolver.gd
key-decisions:
  - "Pad events of the four move actions and sprint removed 2026-10-23; every other action keeps its pad events"
completed: 2026-10-23
commit: 876ca95
plan_head_before: 3d1e6cec7372e8047321c3b3760e9a036cd0860b
plan_head_after: 876ca9547666abdeb42f39dd708af9c560b142a0
actuals:
  tokens: 2800
  tasks: 2
  commits: 1
---

# Quick 261023-aos: strip the gamepad bindings from the king's movement and sprint

Deleted the five pad events (four left-stick `InputEventJoypadMotion`, one RB `InputEventJoypadButton`) from the
king's move and sprint actions in `project.godot`; a connected pad's stick noise can no longer walk the king off
his plot. The contract tests follow, and a new e2e test proves it with real parsed joypad events.

## Commit

- `876ca95` `chore(quick-261023-aos): strip the pad bindings from the king movement and sprint`
  (5 files: project.godot 0/-5, test_king_ride +39, test_input_map +15/-10, test_input_capabilities +27/-10,
  test_glyph_resolver +31/-3). `plan_head_before: 3d1e6ce`. One commit, as planned (Task 1 made no commit).

## Evidence

RED (Task 1 step 3, against the unedited project.godot):
- `-gselect=test_king_ride`: 10/11 passed. The new test failed on all three asserts: sprint read pressed after RB,
  and with the full stick push the king ended 2.616 m off in x (expected within 0.001 of start) and 4.384 vs 7.0 in z
  (2.616 m off in z), so he rode about 3.7 m in 0.4 s.
- `-gselect=test_input_map`: 20 of 22 passed. The renamed gamepad test failed for move_left, move_right,
  move_forward, move_back and sprint (1 pad event each, expected 0), and the button-count test failed for sprint
  (1, expected 0).

GREEN (after `sed -i '38d;45d;52d;59d;65d' project.godot`, after sed printed the five expected lines):
- `bash tools/test.sh -gselect=test_king_ride`: tests=11 failures=0.
- `bash tools/test.sh -gselect=test_input_map`: test_input_map.gd tests=20 failures=0; test_input_map_groups.gd tests=2 failures=0 (22 passing).
- `bash tools/test.sh -gselect=test_input_capabilities`: tests=11 failures=0.
- `bash tools/test.sh -gselect=test_glyph_resolver`: tests=13 failures=0.
- `bash tools/test.sh -gselect=test_pad_`: test_pad_chords 9, test_pad_commands 18, test_pad_cursor 10, all failures=0 (the two e2e files unedited).
- `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`:
  `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`.
- Full suite (`bash tools/test.sh`, background, exit 0), copied to `build/test-results/quick_aos_full_junit.xml`:
  `<testsuites name="GutTests" failures="0" tests="2655">` (2653 at 3d1e6ce plus the king-ride test and the capability test).
- `bash tools/lint.sh`: exit 0, "446 files would be left unchanged", "Success: no problems found" (gdformat reformatted
  the new `assert_almost_eq` calls of test_king_ride.gd once, via `--fix`).
- `project.godot` equals `git show 3d1e6ce:project.godot` with lines 38, 45, 52, 59, 65 deleted, LF kept; the EXPECTED_KEYS
  block of test_input_map.gd is byte-identical to 3d1e6ce; `git diff --name-only 3d1e6ce` over input, ui, presentation,
  simulation and the two pad e2e files is empty.

## Scope findings (from planning)

- tests/unit/test_glyph_resolver.gd resolves sprint and move_* tiles through the InputMap, so it joined the scope:
  the RB and left-stick tiles are now pinned on raw events, and the five actions are asserted unbound on the pad.
- tests/unit/test_input_map.gd was at the 20-public-test cap, so an existing test was renamed
  (`test_every_gameplay_action_but_the_keyboard_only_ones_has_a_gamepad_binding`), not added.
  test_input_capabilities went 10 to 11 (new pin test) and test_king_ride 10 to 11.
- ui_left and ui_right keep identical-looking left-stick lines (base lines 165 and 172); the delete was line-addressed.
- The pad e2e suites, test_start_night_hold.gd and test_device_model.gd do not read these bindings.

## Behaviour consequence

A pad player can no longer ride or sprint the king. The D-pad verbs, the LB layer, the pad cursor, the face buttons,
zoom and fast-forward keep their pad events (owner decision 2026-10-16: pad code stays, unsupported).

## Deviations from Plan

None - plan executed exactly as written. Minor notes: the header comment of test_input_map.gd was re-wrapped by hand
to keep lines at 100 characters or less; gdformat reflowed two asserts in test_king_ride.gd.

## Residual wording left alone (for the orchestrator and owner)

- The 2026-10-23 working-tree edits to `.claude/CLAUDE.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`
  and `.planning/STATE.md` appeared during execution and are not mine; they are unstaged and uncommitted.
- Any remaining "pad bindings stay in the project unsupported" wording, the KING-01 "with WASD or the left stick" clause,
  and the Quick 261016-1o5 STATE.md bullet listing "pad bindings in project.godot" as kept should be checked against
  the amended text those edits introduce.

## Known Stubs

None.

## Self-Check: PASSED

- project.godot, tests/unit/test_input_map.gd, tests/e2e/test_king_ride.gd, tests/unit/test_input_capabilities.gd,
  tests/unit/test_glyph_resolver.gd: modified and present.
- Commit 876ca95 exists on gsd/phase-01-foundation-day-loop and holds exactly those five files;
  `.planning/phases/05-castle-center-economy-depth/05-UAT.md` was never staged.
