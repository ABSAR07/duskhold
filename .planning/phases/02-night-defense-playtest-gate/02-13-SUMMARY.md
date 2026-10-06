---
phase: 02-night-defense-playtest-gate
plan: 13
subsystem: input
tags: [godot, gdscript, sprint, fast-forward, engine-time-scale, input-map, hud, gap-closure, g-02-1]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: the king movement data (01), StartNightHoldController input pattern (01), RunContext.advance clamp and SimClock (01), the owner playtest diagnosis G-02-1 (02-UAT.md)
provides:
  - A 12 m/s sprint (sprint_multiplier 2.4 at walk 5.0) with 60 m/s^2 acceleration so a full-sprint stop (1.2 m) stays inside the 2.5 m build radius
  - The fast_forward input action (F, gamepad left trigger; no mouse, no shared binding)
  - LoopTuning.fast_forward_scale (2.0 shipped, written in loop_tuning.tres) and LoopTuning.FAST_FORWARD_MAX_SCALE (4.0)
  - FastForwardController, the night-only fast-forward and the single writer of Engine.time_scale, in the prototype map as the FastForward node
  - A HUD Fast-forward 2x label that shows only while the night is sped up
affects: [phase-2-verification, playtest-gate, 02-14, 02-15, 02-16, balance]

actuals:
  tokens: 6800
  tasks: 3
  commits: 6

plan_head_before: 5bdef8648ffcfdf044286226fbaf963469ffae36
plan_head_after: 3d6c2a465e14fdcf95c9e5952e4c7d078af464aa

tech-stack:
  added: []
  patterns:
    - "Presentation speed-up through Engine.time_scale from one input node, never inside simulation/: the engine scales the delta MapRoot feeds RunContext.advance, so the simulation runs more fixed steps per real second and each step is unchanged"
    - "A scale-changing input node restores the neutral value in _exit_tree and re-applies it from phase_changed, so it drops inside the simulation step that leaves the phase"
    - "A source scan test pins the single writer of a global engine setting"

key-files:
  created:
    - input/fast_forward_controller.gd
    - input/fast_forward_controller.gd.uid
    - tests/unit/test_fast_forward_rules.gd
    - tests/unit/test_fast_forward_rules.gd.uid
    - tests/e2e/test_fast_forward.gd
    - tests/e2e/test_fast_forward.gd.uid
  modified:
    - data/king/king.tres
    - simulation/defs/king_def.gd
    - simulation/defs/loop_tuning.gd
    - data/tuning/loop_tuning.tres
    - project.godot
    - presentation/map/prototype_map.tscn
    - ui/hud/hud.gd
    - ui/hud/hud.tscn
    - tests/unit/test_king_movement_config.gd
    - tests/unit/test_input_map.gd
    - tests/unit/test_loop_tuning_contract.gd
    - tests/e2e/test_king_ride.gd

key-decisions:
  - "Sprint is 12 m/s (walk_speed 5.0 x sprint_multiplier 2.4, 1.5x the 8 m/s the owner played) with acceleration 60: the stopping distance v^2/2a is 1.2 m, under the 2.5 m interaction radius. Walk speed stays 5.0 for the ride-time budget (D-03)"
  - "Fast-forward acts only in NIGHT (recorded for the owner, who left it open): by day there is nothing to wait for and riding is what the sprint is for, dawn is two seconds of payout coins, and the loss beat (1.2 s) and results grace (0.6 s) must stay real seconds. Leaving NIGHT drops the scale to 1.0 in the same simulation step through phase_changed. A key held across dawn resumes fast-forward when the next night starts (a hold, not a toggle). It also works while the king is knocked out"
  - "Bindings chosen for the owner to rebind later: keyboard F (physical key 70) and the gamepad left trigger (JOY_AXIS_TRIGGER_LEFT, +1.0), deadzone 0.5. Both were free; test_input_map.gd proves no sharing and no mouse binding"
  - "scale_for clamps the data value to 1.0 .. FAST_FORWARD_MAX_SCALE (4.0) and treats NaN and infinities as 1.0 (T-02-29)"
  - "The label text drops a trailing .0 from String.num(scale, 2), because Godot prints 2.0 as 2.0, not 2"

patterns-established:
  - "Only input/fast_forward_controller.gd assigns Engine.time_scale; nothing under simulation/ mentions time_scale (both scanned in test_fast_forward_rules.gd)"

requirements-completed: [LOOP-03, KING-03]

coverage:
  - id: D1
    description: "The king sprints at 12 m/s (multiplier 2.4, at least 1.5x the original 8 m/s), acceleration is 60, and a king letting go at full sprint stops inside the build radius"
    requirement: KING-03
    verification:
      - kind: unit
        ref: "tests/unit/test_king_movement_config.gd#test_sprint_is_at_least_one_and_a_half_times_the_original_sprint"
        status: pass
      - kind: unit
        ref: "tests/unit/test_king_movement_config.gd#test_a_king_letting_go_at_full_sprint_stops_inside_the_build_radius"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_sprint_covers_about_the_sprint_multiplier_more_ground"
        status: pass
    human_judgment: false
  - id: D2
    description: "fast_forward is bound to F and the gamepad left trigger with deadzone 0.5, no mouse binding, shared with no other gameplay action"
    requirement: LOOP-03
    verification:
      - kind: unit
        ref: "tests/unit/test_input_map.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "Holding fast_forward at night runs the game at the tuning scale (2.0), by day, at dawn, in defeat and on release it is 1.0 (dropped inside the same step), a freed controller restores 1.0, and bad scale data is clamped"
    requirement: LOOP-03
    verification:
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_loop_tuning_contract.gd#test_shipped_fast_forward_is_set_in_the_data_file_and_at_least_one_and_a_half"
        status: pass
    human_judgment: false
  - id: D4
    description: "Fast-forward never changes results: doubled frame deltas run the same steps and digest, the MAX_ADVANCE_SECONDS clamp still bounds a frame, only the controller writes Engine.time_scale and simulation/ never mentions it, the smoke golden is unchanged"
    verification:
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd#test_doubled_frame_deltas_run_the_same_steps_and_the_same_digest"
        status: pass
      - kind: unit
        ref: "tests/unit/test_fast_forward_rules.gd#test_only_the_fast_forward_controller_assigns_the_engine_time_scale"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (digest 2599c7c2 unchanged)"
        status: pass
    human_judgment: false
  - id: D5
    description: "In the real scene the label reads Fast-forward 2x only while the night is sped up, the king covers 1.7-2.3x the ground and the simulation 1.6-2.4x the steps per real second"
    requirement: LOOP-03
    verification:
      - kind: e2e
        ref: "tests/e2e/test_fast_forward.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "Whether 12 m/s and 2x feel right to the owner, and the label's position and readability in the top right during a real night"
    verification: []
    human_judgment: true
    rationale: "Feel and on-screen legibility are judgments; the tests prove the numbers, the pace and the label text and visibility only"

duration: 45min
completed: 2026-10-06
status: complete
---

# Phase 02 Plan 13: Faster sprint and night fast-forward Summary

**The king sprints at 12 m/s (2.4 x 5.0, acceleration 60 so he still stops on a plot), and holding F or the left trigger during a night runs the game at 2x through `Engine.time_scale` from one night-only controller, with the same simulation steps, a hard drop to real time the moment the night ends, and a Fast-forward 2x HUD label.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-10-06T12:09:07Z
- **Completed:** 2026-10-06T12:54:00Z
- **Tasks:** 3 (all TDD: RED then GREEN)
- **Files modified:** 18 (6 created)

## Accomplishments

- `king.tres` and the `KingDef` defaults: `sprint_multiplier = 2.4`, `acceleration = 60.0`, `walk_speed` stays 5.0. The source-ratio pin (1.6) in `test_king_movement_config.gd` is replaced on purpose by the owner's 2.4 and the 12 m/s floor; `test_king_ride.gd`'s data-driven ratio test passes unchanged.
- `fast_forward` input action (`project.godot`), `LoopTuning.fast_forward_scale` (2.0 shipped) and `FAST_FORWARD_MAX_SCALE` (4.0), and `FastForwardController` with `scale_for`, `bind_run`, `is_active`, `get_scale`, a `changed` signal, a phase_changed handler that re-applies the scale at once, and an `_exit_tree` that restores 1.0.
- A `FastForward` node (group run_bound) in `prototype_map.tscn`; MapRoot, RunContext, SimClock and the King are untouched.
- `Hud.bind_run` finds the `FastForward` node and a hidden, outlined `%FastForwardLabel` in the top right shows `Fast-forward 2x` while the night is sped up. No new public method.

## Task Commits

1. **Task 1 RED** - `538d1a3` test(02-13): add failing tests for the 12 m/s sprint and 60 m/s^2 acceleration
2. **Task 1 GREEN** - `9451f98` feat(02-13): sprint at 12 m/s with 60 m/s^2 acceleration
3. **Task 2 RED** - `1b10481` test(02-13): add failing tests for night fast-forward
4. **Task 2 GREEN** - `8faf914` feat(02-13): hold F or the left trigger to run the night at 2x
5. **Task 3 RED** - `4407559` test(02-13): add failing e2e tests for the fast-forward HUD label and pace
6. **Task 3 GREEN** - `3d6c2a4` feat(02-13): show Fast-forward 2x in the HUD while the night is sped up

## TDD Gate Compliance

RED then GREEN for all three tasks.

- **Task 1 RED:** `test_sprint_is_at_least_one_and_a_half_times_the_original_sprint` failed on its assertions (multiplier 1.6 vs 2.4, sprint 8.0 vs 12.0) and the acceleration test failed on 40.0 vs 60.0. The full-sprint stopping-distance test passed in RED because the old numbers also stop inside 2.5 m (0.8 m); it guards the new pair against overshooting.
- **Task 2 RED:** `test_input_map.gd` failed 6 tests on assertions (no `fast_forward` action, key, axis or deadzone). `test_loop_tuning_contract.gd` and `test_fast_forward_rules.gd` did not parse, because they name `LoopTuning.FAST_FORWARD_MAX_SCALE` and `FastForwardController`, which did not exist yet. That is a parse-level RED for those two files, not an assertion-level one; the input map failures are the assertion-level evidence. Unlike 02-12, no empty declarations were added to the RED commit to make them parse.
- **Task 3 RED:** `test_holding_fast_forward_by_day_changes_nothing` and the label tests failed on "the HUD has a FastForwardLabel" (assertion). The king-pace and tick-rate tests passed in RED, since the controller from Task 2 already produced that behavior; they are regression proof for the real scene, not RED drivers.

## Mutation probes

- **Task 1:** set `sprint_multiplier` back to 1.6 in `king.tres`; `test_sprint_is_at_least_one_and_a_half_times_the_original_sprint` failed (multiplier 1.6 vs 2.4, sprint 8.0 below 12.0). Restored.
- **Task 2:** changed `scale_for`'s guard `if phase != NIGHT or not held` to `if not held`, so the tuning scale applies in any phase; 4 of 14 tests in `test_fast_forward_rules.gd` failed (the every-other-phase table, held by day, the same-step drop in defeat, the same-step drop at dawn). Restored.
- **Task 3:** forced the handler to `_fast_forward_label.visible = false`; `test_the_label_shows_while_a_night_is_fast_forwarded_and_hides_on_release` and `test_the_label_is_hidden_at_dawn_even_while_the_key_is_still_held` failed (2 of 5 in `test_fast_forward.gd`). Restored.

## Replay results

- `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (matches the golden, checked after Task 1 and again after Task 2)
- `bash tools/replay.sh --scenario=full_idle --twice` after the sprint change: `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435` (was ticks 4178, digest 26542325... after 02-12; the change is expected because the defending bot sprints at the shipped 12 m/s). No golden file changed.

## Verification

- Full suite after each GREEN: 759 (Task 1), 775 (Task 2), 780 (Task 3) tests, 0 failures; baseline was 758. Lint clean each time.
- Acceptance greps all pass: `fast_forward=` in `project.godot`, `class_name FastForwardController`, `static func scale_for(` and `func _exit_tree(` in the controller, `fast_forward_scale = 2.0` in `loop_tuning.tres`, `name="FastForward"` in the scene, `FastForwardLabel` in `hud.tscn`, `FastForward` and `changed.connect` in `hud.gd`, `Engine.time_scale = 1.0` in `test_fast_forward.gd`'s `after_each`.
- Real-time checks measured on the headless run: king ground ratio and tick-rate ratio both land within their loose bounds (1.7-2.3 and 1.6-2.4), and no suite leaked a time scale into the next.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Label text printed "2.0x", not "2x"**
- **Found during:** Task 3 GREEN
- **Issue:** the plan says to format with `String.num(scale, 2)` so 2.0 reads 2, but Godot's `String.num(2.0, 2)` returns `2.0`, so the label read `Fast-forward 2.0x` and the e2e test caught it.
- **Fix:** trim a trailing `.0` (`String.num(scale, 2).trim_suffix(".0")`): 2.0 reads 2, 1.5 reads 1.5, 2.25 reads 2.25.
- **Files modified:** ui/hud/hud.gd
- **Commit:** 3d6c2a4

**2. [Judgment] Parse-level RED for two new test files in Task 2**
- **Found during:** Task 2 RED
- **Issue:** the plan wants new tests first, but they type against `FastForwardController` and `LoopTuning.FAST_FORWARD_MAX_SCALE`, which do not exist before GREEN. See TDD Gate Compliance.
- **Fix:** none; recorded. The input map suite supplies the assertion-level RED.

**3. [Judgment] Unused controller references in the rules test**
- **Found during:** Task 2 lint
- **Issue:** gdlint rejects a leading-underscore local name, so the three tests that only need the controller in the tree call `_controller_on(ctx)` without keeping the result.
- **Commit:** 1b10481

**Total deviations:** 1 auto-fixed (bug), 2 judgments. **Impact:** none on behavior.

## Decision recorded for the owner (copied into 02-16's packet)

Fast-forward acts only during NIGHT. Not by day (no timer to wait for; the sprint is for riding), not at dawn (two seconds of payout coins), not during the loss beat or on the results screen (they must run in real seconds). It drops to 1.0 in the same simulation step that leaves NIGHT. A key held across dawn resumes fast-forward when the next night starts, because it is a hold, not a toggle. It also works while the king is knocked out, which shortens the wait for his respawn. Bindings: F and the gamepad left trigger; both can be rebound in the Input Map.

## Known Stubs

None.

## Threat Flags

None. The only new trust-boundary surfaces (the data scale driving the engine time scale, and a held key changing game speed) are the plan's T-02-29, T-02-30 and T-02-31, each mitigated and tested.

## Self-Check: PASSED

- Created files exist: `input/fast_forward_controller.gd`, `tests/unit/test_fast_forward_rules.gd`, `tests/e2e/test_fast_forward.gd` (each with its `.uid`).
- Commits `538d1a3`, `9451f98`, `1b10481`, `8faf914`, `4407559`, `3d6c2a4` all present on `gsd/phase-01-foundation-day-loop`.
- Plan verification: full suite 780/780 and lint clean; the smoke replay matches its golden; `full_idle` agrees across both runs.
