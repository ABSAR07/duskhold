---
phase: 02-night-defense-playtest-gate
plan: 18
subsystem: fast-forward-input
tags: [godot, input, fast-forward, toggle, gap-closure, g-02-14, wr-01, determinism]
status: complete

requires:
  - phase: 02-night-defense-playtest-gate
    provides: 02-13 hold-to-fast-forward (FastForwardController, scale_for, the HUD label and the 2x pace)
provides:
  - Night fast-forward is a toggle on the unchanged bindings (F, left trigger): one press at night switches it on at LoopTuning.fast_forward_scale and it stays on after release, the next press switches it off
  - The switch resets inside the simulation step that leaves NIGHT (dawn, victory, defeat), so every night starts at real time and the loss beat and results grace stay real seconds
  - One trigger pull toggles once and a trigger hovering at its 0.5 deadzone cannot re-toggle until the raw strength falls below FastForwardController.REARM_STRENGTH (0.25)
  - Fourth review WR-01 closed: every test controller is owned by its test (add_child_autofree), and a probe that drops the phase_changed connection now fails three unit tests and one e2e test
affects: [02-20-round-3-packet, phase-2-verification, owner-playtest-gate]

requirements-completed: [LOOP-03, DEV-05]

actuals:
  tokens: 7900
  tasks: 2
  commits: 4

plan_head_before: fadd0c04603125ea1cbfd4441c0ee837ef31a236
plan_head_after: af4fccca82bfd5670ed23b4d084427b94794932b

tech-stack:
  added: []
  patterns:
    - "A latched switch flipped on a press edge read in _process (Input.is_action_just_pressed or a level rise against a stored previous level), fed to the unchanged pure rule function, never toggled per input event"
    - "A re-arm guard on analog-axis toggles: a counted press needs the action's raw strength (before the deadzone) to fall below a fraction of the deadzone first, because Godot has no deadzone hysteresis"
    - "A latch that must not outlive its window is cleared inside the phase_changed that ends the window, before the dependent value is re-applied"

key-files:
  created:
    - tests/unit/test_fast_forward_toggle.gd
    - tests/unit/test_fast_forward_toggle.gd.uid
  modified:
    - input/fast_forward_controller.gd
    - tests/unit/test_fast_forward_rules.gd
    - tests/e2e/test_fast_forward.gd
    - simulation/defs/loop_tuning.gd
    - tests/unit/test_input_map.gd
    - tests/unit/test_loop_tuning_contract.gd

key-decisions:
  - "The toggle lives entirely inside FastForwardController; scale_for keeps its body (its bool parameter is renamed held -> on), the HUD changed(active, scale) contract, the bindings, the 0.5 deadzone, the 2.0 scale and the night-only rule are untouched"
  - "REARM_STRENGTH = 0.25 is a code constant, not tuning data: it is an input-device guard like the action deadzone in project.godot, and a test pins it above 0 and below the deadzone"
  - "The raw-strength re-arm guard worked on Godot 4.7.2 (Input.get_action_raw_strength reports a sub-deadzone trigger value), so the recorded real-time-gap fallback was not needed"

coverage:
  - id: D1
    description: "One press at night switches fast-forward on and it stays on after release; the next press switches it off"
    requirement: "LOOP-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd#test_a_press_at_night_switches_fast_forward_on_and_the_next_press_switches_it_off"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_fast_forward.gd#test_the_label_stays_after_release_and_hides_on_the_second_press"
        status: pass
    human_judgment: true
    rationale: "The owner decides whether the toggle feels right on a real keyboard and gamepad (round-3 playtest)"
  - id: D2
    description: "The switch resets in the step that leaves NIGHT (dawn, victory, defeat); each night starts at real time; day presses and a key held into the night switch nothing on"
    requirement: "LOOP-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd#test_the_switch_resets_in_the_dawn_step_and_the_next_night_starts_at_real_time"
        status: pass
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd#test_the_switch_resets_inside_the_step_that_wins_the_run"
        status: pass
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd#test_the_scale_drops_inside_the_step_that_ends_the_run_in_defeat"
        status: pass
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd#test_a_key_held_from_day_into_the_night_does_not_switch_it_on"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_fast_forward.gd#test_the_label_is_hidden_at_dawn_and_the_next_night_starts_at_real_time"
        status: pass
    human_judgment: false
  - id: D3
    description: "One trigger pull toggles once; a trigger hovering at the deadzone does not re-toggle; a long hold and a sub-frame tap each toggle once"
    requirement: "LOOP-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_fast_forward_toggle.gd#test_a_trigger_hovering_at_its_deadzone_does_not_toggle_again"
        status: pass
      - kind: unit
        ref: "tests/unit/test_fast_forward_toggle.gd#test_one_trigger_pull_toggles_once"
        status: pass
    human_judgment: true
    rationale: "Axis edges were fed as synthetic InputEventJoypadMotion; a real gamepad trigger has not been exercised by automation"
  - id: D4
    description: "WR-01: test controllers are owned by their test, and removing the phase_changed connection fails tests"
    verification:
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd (add_child_autofree in _controller_on; mutation probe b)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Determinism untouched: single writer of Engine.time_scale, nothing under simulation/ mentions it, smoke replay matches its golden"
    requirement: "DEV-05"
    verification:
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd#test_only_the_fast_forward_controller_assigns_the_engine_time_scale"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (REPLAY_OK digest 2599c7c2...)"
        status: pass
    human_judgment: false

duration: 28min
completed: 2026-10-07
---

# Phase 2 Plan 18: Night fast-forward toggle Summary

**Night fast-forward is now a press-on, press-off latch inside FastForwardController (edge read in _process, cleared in the phase_changed that leaves NIGHT, trigger chatter guarded by a raw-strength re-arm), with the leaked-controller test masking (WR-01) fixed.**

## Performance

- **Duration:** about 28 min (start estimated from the first RED commit, 2026-10-06T23:32Z; end 2026-10-06T23:47Z for the last code commit, plus the docs commit)
- **Tasks:** 2 (each as a RED test commit then a GREEN change commit)
- **Files modified:** 8 (7 modified, 1 new test script with its .uid sidecar)
- **Suite:** 827 tests in 95 scripts, all passing (821 in 94 before: 5 new input-edge tests and 1 new victory test); lint clean; smoke replay matches tests/golden/smoke.json

## Accomplishments

- G-02-14 closed: the hold became a toggle with the owner's exact semantics (press once on, press again off, reset when the night ends, day presses do nothing, same bindings F and left trigger, the label shows while on). The HUD needed no change.
- The press is detected with the build-hold edge idiom (`Input.is_action_just_pressed` or a level rise against the stored previous level, stored every frame in every phase), so a sub-frame tap counts, a long hold counts once, and a key held from day into the night shows no edge.
- A guard against a trigger hovering at its 0.5 deadzone: after a counted press the next one counts only once `Input.get_action_raw_strength` has fallen below `REARM_STRENGTH` (0.25).
- WR-01 closed in the same change: `_controller_on` uses `add_child_autofree`, and a victory test was added (`...resets_inside_the_step_that_wins_the_run`).
- The hold wording is gone from the controller, `loop_tuning.gd` and the two test doc comments (history mentions such as "replacing the 2026-10-06 hold" remain on purpose).

## Task Commits

1. **Task 1: Press at night switches fast-forward on, next press off, night's end off (WR-01 fixed)**
   - RED `d27aec5` (test): rules and e2e tests rewritten for the toggle; 6 of 15 unit and 4 of 5 e2e tests failed on the hold code
   - GREEN `da26e7f` (feat): `_switched_on` latch, press edge in `_process`, clear in `_on_phase_changed`
2. **Task 2: One trigger pull toggles once, hold wording gone from docs**
   - RED `29557bc` (test): `tests/unit/test_fast_forward_toggle.gd` (+ .uid); on the Task 1 code the chatter test failed (extra on and off changes) and the REARM_STRENGTH test failed (with the constant stubbed to 0.0; with the real reference the script does not compile, which is the plan's "fails to compile" case)
   - GREEN `af4fccc` (feat): `REARM_STRENGTH`, `_rearmed`, `_press_counts`, doc sweep

**Plan metadata:** the docs(02-18) commit that follows this summary.

## Mutation probes

Each probe was applied to the GREEN code, the named tests were run, the file was restored from a backup copy and diffed identical.

| Probe | Change | Result |
|-------|--------|--------|
| (a) Task 1: live level again | `_apply` feeds `Input.is_action_pressed(ACTION)` to `scale_for` instead of `_switched_on` | Unit: 6 of 15 failed (press-on/press-off, held-into-night, defeat, dawn, victory, free). E2e: 4 of 5 failed (label stays after release, king pace, tick rate, dawn) |
| (b) Task 1, WR-01: no phase_changed | `bind_run` no longer connects `phase_changed` (replaced by `pass`) | Unit: 3 failed (defeat same-step, dawn same-step, victory same-step); 12 passed. E2e: 1 failed (dawn and next night). This is the check the fourth review asked for |
| (c) Task 2: re-arm ignored | `var counted: bool = edge` (a detected press counts regardless of `_rearmed`) | `test_a_trigger_hovering_at_its_deadzone_does_not_toggle_again` failed; 4 of 5 passed |

## Raw-strength guard or fallback

The raw-strength re-arm guard was used. `Input.get_action_raw_strength` reports the sub-deadzone trigger value on Godot 4.7.2: the chatter values 0.45 and 0.55 keep the guard disarmed (they never fall below 0.25) and a 0.0 reading re-arms it. The recorded fallback (a real-time gap between toggles via `Time.get_ticks_msec`) was not needed.

## Decisions Made

- Toggle logic stays in FastForwardController only; `scale_for` keeps its body and its single-writer, night-only clamp.
- REARM_STRENGTH is a code constant (input-device guard like the project.godot deadzone), pinned between 0 and the action deadzone by a test.
- A latch survives window focus loss (Godot releases held actions on focus-out, which used to cancel the hold); the next press switches it off. Documented in the class doc.

## Deviations from Plan

None - plan executed exactly as written. Two small notes, neither a deviation: the dawn test name was shortened to fit the 100-character gdlint limit (`test_the_switch_resets_in_the_dawn_step_and_the_next_night_starts_at_real_time`), and the RED run of the new toggle file needed the `REARM_STRENGTH` reference stubbed to 0.0 temporarily (a backup was restored afterwards) so that the chatter test could be seen failing on the Task 1 code instead of the whole script failing to compile.

## Issues Encountered

None. `tests/unit/test_input_map.gd` has CRLF line endings in the working tree (index is LF); the doc edit preserved them and git only warns.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file surface; T-02-39 (trigger chatter) and T-02-40 (latch outliving the night, the run or a test) are mitigated and covered by the tests and probes above.

## Self-Check: PASSED

- Files present: input/fast_forward_controller.gd, tests/unit/test_fast_forward_toggle.gd, tests/unit/test_fast_forward_toggle.gd.uid, tests/unit/test_fast_forward_rules.gd, tests/e2e/test_fast_forward.gd.
- Commits present: d27aec5, da26e7f, 29557bc, af4fccc (`git rev-list --count fadd0c0..HEAD` = 4 before this summary).
- `git diff fadd0c0 HEAD -- project.godot data tests/golden tests/fixtures` is empty.
- Full suite 827/827, lint clean, smoke replay REPLAY_OK against tests/golden/smoke.json.

## Final toggle semantics (for the round-3 owner packet)

During a night, press F (keyboard) or pull the left trigger (gamepad) once and the game switches to 2x speed and stays there after you let go, with the "Fast-forward 2x" label showing; press it again and the game returns to normal speed and the label disappears. Each press counts once however long you hold it, and a trigger that hovers around halfway counts once until you let it go nearly all the way. The switch turns itself off the moment the night ends (dawn, victory or defeat), so every night starts at normal speed and the loss beat and results screen run in real seconds; pressing the key by day, at dawn or on the results screen does nothing, and a key you are still holding when the night begins does not switch it on (you need a fresh press). The simulation is unchanged, so seeded nights replay identically.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-07*
