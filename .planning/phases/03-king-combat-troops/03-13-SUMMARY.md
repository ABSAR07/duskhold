---
phase: 03-king-combat-troops
plan: 13
subsystem: input
tags: [godot, gdscript, squad-orders, order-queue, command-keys, gamepad, gap-closure]
gap_closure: true
gap_ids: [G-03-8]

requires:
  - phase: 03-king-combat-troops
    provides: "03-07 squad order queue and the queued flag on SquadOrderIntent / SquadSystem.apply_order; 03-06 CommandKeyController and the F/H/R verbs; 03-09 PadChords (D-pad twins) and the command_queue Input Map action (Shift, pad RT)"
provides:
  - "CommandKeyController.QUEUE_ACTION and a queue-aware _give: F, H and R (and the D-pad twins) append behind the selection's queued walks while Shift / RT is held (D-09)"
  - "Real-scene tests of the Shift queue on the keyboard (three cases) and the RT queue on the pad (one case)"
affects: [03-18]

actuals:
  tokens: 3085
  tasks: 2
  commits: 3

plan_head_before: 90f54c6250f02c694db94aad46ef6b1088dc4125
plan_head_after: cddfec18c8d191ad32ac5fe117a08cc102b4d984
commits: 3

tech-stack:
  added: []
  patterns:
    - "The queue flag is read from Input.is_action_pressed(command_queue) at the moment of the press, in the input layer only; the simulation gate is untouched"

key-files:
  created: []
  modified:
    - input/command_key_controller.gd
    - tests/e2e/test_command_keys.gd
    - tests/e2e/test_pad_commands.gd

key-decisions:
  - "One line of behaviour in _give closes G-03-8: the simulation, the Input Map and the hint-row copy were already right (prohibitions honoured, nothing under simulation/ and no project.godot change in any of the three commits)"
  - "No new code for the pad: the D-pad verbs reach _give through PadChords, so RT held already queues them; the pad test passed on Task 1's code as the plan predicted"

patterns-established:
  - "Tests that need a queued string of walks submit three SquadOrderIntent moves (first not queued, next two queued, 4 m legs from the anchor) through ctx.commands and clear the event recorder, then press the verb with command_queue held"

requirements-completed: [UNIT-10, UNIT-05, INPT-01, INPT-02]

coverage:
  - id: D1
    description: "Shift+H after three queued moves appends a hold behind them: orders read move, move, move, hold, the squad keeps walking and holds at the third point once the walks end"
    requirement: UNIT-10
    verification:
      - kind: e2e
        ref: "tests/e2e/test_command_keys.gd#test_shift_hold_after_three_queued_moves_waits_behind_the_walks"
        status: pass
    human_judgment: false
  - id: D2
    description: "Plain H still clears the queue and holds at once; Shift+H on a squad with nothing queued holds at once"
    requirement: UNIT-05
    verification:
      - kind: e2e
        ref: "tests/e2e/test_command_keys.gd#test_hold_without_shift_still_clears_the_queue_and_holds_at_the_centroid"
        status: pass
    human_judgment: false
  - id: D3
    description: "Shift+F and Shift+R queue the follow and the rally (move to the king then hold) behind the walks, with queued true on the event"
    requirement: UNIT-10
    verification:
      - kind: e2e
        ref: "tests/e2e/test_command_keys.gd#test_shift_follow_and_shift_rally_queue_behind_the_walks"
        status: pass
    human_judgment: false
  - id: D4
    description: "Gamepad parity: RT held with D-pad down queues the hold behind the walks through the same CommandKeyController path; without RT the press still replaces the queue"
    requirement: INPT-02
    verification:
      - kind: e2e
        ref: "tests/e2e/test_pad_commands.gd#test_rt_held_with_d_pad_down_queues_the_hold_behind_the_walks"
        status: pass
    human_judgment: false
  - id: D5
    description: "Real window, real mouse and key events: the queued hold sits behind three Shift right-click moves and the squad holds at the last point"
    requirement: INPT-01
    verification:
      - kind: other
        ref: "probe_queued_hold.gd run windowed through bash tools/godot.sh (lines quoted in this SUMMARY)"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-10-13
status: complete
---

# Phase 03 Plan 13: Shift queues the follow, hold and rally keys Summary

**CommandKeyController._give now reads the command_queue action (Shift / pad RT) at the press, so Shift+H after a string of Shift right-click moves queues the hold behind the walks and the squad holds at the last point (D-09), closing UAT gap G-03-8.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-10-13T15:33:40Z
- **Completed:** 2026-10-13T15:53:19Z (last task commit; SUMMARY follows)
- **Tasks:** 2
- **Files modified:** 3 (one production file, two test files)

## Accomplishments

- Root cause fixed where it lived: `_give(verb)` built `SquadOrderIntent.new(ids, verb)` with the queued flag left false and never read `command_queue`, while the pointer and pad cursor already did. It now declares an empty typed point array and passes `Input.is_action_pressed(QUEUE_ACTION)` as the fourth argument. The class header documents the Shift / RT rule.
- Three keyboard cases and one pad case pin it in the real scene: Shift+H behind three queued moves (queue reads move, move, move, hold; resting stance hold; after the walks the squad holds at the third point within 0.01 m), plain H still replacing the queue, Shift+H on an empty queue holding at once, Shift+F and Shift+R appending (rally shape pinned: move, move, move, move to the king, hold), and RT + D-pad down on the pad.
- Real-window proof with real mouse and key events (below).

## Behaviour change for the owner's gate packet (plan 03-18 quotes this)

Shift is both sprint and `command_queue` (the Input Map's explicit allowance). Sprinting with Shift held and pressing F, H or R now queues the verb behind the selection's walks instead of replacing them. This is consistent with D-09 ("Shift queues commands") and with Shift right-click moves, which already queue while sprinting. With nothing queued, a Shift-queued verb runs at once, so the visible difference only appears when the squad has queued walks. A verb behind a terminal order is still refused by the simulation gate (QUEUE_CLOSED), unchanged.

## Real-window evidence

Run: a throwaway `extends SceneTree` probe (kept in the scratch directory, not in the repository), windowed (1280x720, Vulkan Forward+, RTX 3060 Laptop) through `bash tools/godot.sh --path . -s <probe>`. It loads `presentation/map/prototype_map.tscn` on `tests/fixtures/fixture_map_squads.tres` with seed 1, builds barracks_1 through BuildIntent, selects it, holds `command_queue`, sends three real right-click `InputEventMouseButton` events at the camera projection of the ground points (-4, 5), (-12, 6) and (-3, -6), then a real `InputEventKey` H press with `command_queue` still held. Printed lines, verbatim:

```
window=(1280, 720) build=ok
puppets=4
squad_ordered barracks_1 move queued=true points=[(-4.0, 5.0)]
squad_ordered barracks_1 move queued=true points=[(-12.0, 6.0)]
squad_ordered barracks_1 move queued=true points=[(-3.0, -6.0)]
shift_held=true
orders_before=["move", "move", "move"]
squad_ordered barracks_1 hold queued=true points=[]
orders_after_shift_h=["move", "move", "move", "hold"]
stance_after_shift_h=hold
png_saved=0 C:/Users/burha/AppData/Local/Temp/claude/C--Users-burha-Desktop-Projects-Thronefall-like-Game/f8b6d77d-09df-4298-8835-f2870e4d8fc3/scratchpad/executor-03-13/queued_hold.png
steps_to_drain=221
final_stance=hold
final_anchor=(-3.0, -6.0)
third_point=(-3.0, -6.0)
```

The saved PNG (outside the repository, session scratch only) shows the queued path from the squad through discs 1 and 2 with the third disc, the selected squad slot and the hint row with "Queue" naming Shift. After the walks drained (221 steps) the squad rested in hold exactly at the third point.

## Task Commits

1. **Task 1: Shift+H after three queued moves waits behind the walks** (tracer, TDD)
   - RED: `1b6ad62` test(03-13): failing Shift-queue cases for the verb keys
   - GREEN: `1f8082c` fix(03-13): Shift queues the follow, hold and rally keys (G-03-8)
2. **Task 2: The pad RT queues the D-pad hold too, plus the real-window run** - `cddfec1` test(03-13): the pad RT queues the D-pad hold

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md follows.

## TDD Gate Compliance

- RED (`1b6ad62`): the three Shift cases failed on assertions for the planned behaviour, not on script errors or discovery (11 of 14 passing, 3 failing: "marked queued", orders_of empty instead of [move, move, move, hold] / [..., follow], rally queue [move, hold] instead of five entries, held at the centroid instead of the third point). The plain-H and non-Shift cases passed already (they pin unchanged behaviour). One out-of-bounds read in the first RED draft of the rally case was guarded before the RED commit so the failure is a clean assertion.
- GREEN (`1f8082c`): `bash tools/test.sh -gselect=test_command_keys.gd` 14 of 14 passing, 140 asserts; lint clean.
- REFACTOR: not needed.
- Task 2 (tdd="true", test-only): the pad case passed on Task 1's code with no production change, as the plan states, so there is no separate RED for it. Its "without the trigger the press is not queued" half and the `queued true` assertion prove the trigger event reaches `command_queue`.

Tracer gate: Task 1's `<verify>` (automated only) re-run end to end after the GREEN commit passed, so "Tracer verified end-to-end — expanding" and Task 2 proceeded.

## Files Created/Modified

- `input/command_key_controller.gd` - `QUEUE_ACTION`, queue-aware `_give`, header doc
- `tests/e2e/test_command_keys.gd` - three Shift cases (14 test functions), helpers `_verbs_of`, `_queue_three_moves`, `_tap_queued`
- `tests/e2e/test_pad_commands.gd` - the RT case (18 test functions), helpers `_trigger`, `_queue_three_moves`, `_verbs_of`, trigger release in `after_each`

## Decisions Made

None beyond the plan. The rally shape the plan asked to pin is `[move, move, move, move(to the king), hold]`, with the fourth entry's point equal to the king's position and resting stance hold.

## Deviations from Plan

None - plan executed exactly as written. Minor notes, not deviations: the plan said the pad script had 17 functions before the change; it had 17 and has 18 now (the count in the plan text was one off in the other direction for no consequence); the plan commit ledger file was written right after the RED commit instead of before it, using the RED commit's parent (`90f54c6`, the dispatch HEAD), so the measured count of 3 commits is exact.

## Issues Encountered

None. Verification results:

- `bash tools/test.sh` (full suite, own run): 148 scripts, 1377 tests, 1377 passing, 0 failing, exit 0, 15259 asserts, 574 s. That is the 1373-test baseline plus the four new cases. The assert total reads 108 below the 15367 baseline although four tests were added; GUT's assert count depends on timing-driven loops (wait-until predicates assert per poll), not on the number of tests, and no test failed.
- JUnit XML names found: `test_rt_held_with_d_pad_down_queues_the_hold_behind_the_walks`, `test_shift_hold_after_three_queued_moves_waits_behind_the_walks`, and `test_squad_queue` (16 matches).
- `bash tools/lint.sh`: 262 files left unchanged, no problems found.
- Acceptance: `QUEUE_ACTION` and `Input.is_action_pressed(QUEUE_ACTION)` present in `_give`; the three named test functions present; `git show --stat` of all three commits lists nothing under `simulation/` and no `project.godot`.

## Known Stubs

None.

## Threat Flags

None. T-03-22 (tampering via the queued flag) is mitigated as planned: the flag is a plain bool inside the existing intent, CommandProcessor still re-validates and SquadOrder.MAX_QUEUE still caps the queue; the full `test_squad_queue` suite passes.

## Next Phase Readiness

G-03-8 is closed in code, tests and a real window; the Shift sprint-versus-queue note above is for plan 03-18's owner packet. The CR-01 spawn loops in `squad_system.gd` were not touched.

## Self-Check: PASSED

- FOUND: `input/command_key_controller.gd`, `tests/e2e/test_command_keys.gd`, `tests/e2e/test_pad_commands.gd`
- FOUND commits: `1b6ad62`, `1f8082c`, `cddfec1` (all matched by `git log --grep="03-13"`)
- Plan `<verification>` re-run: full suite exit 0, lint clean, probe lines quoted above.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-13*
