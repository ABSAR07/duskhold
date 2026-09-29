---
phase: 01-foundation-day-loop
plan: 04
subsystem: king-controls-camera
tags: [godot, gdscript, gut, king-movement, camera-rig, input-map, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "Plan 01-02 walking skeleton: King, KingDef, Input Map, E2eSupport, run_bound/bind_run wiring"
provides:
  - "King riding feel: velocity accelerates toward the target (KingDef.acceleration), Model pivot turns to face the heading (KingDef.turn_speed)"
  - "CameraRig: detached, smoothed, fixed-angle follow camera (offset (0,16,11), fov 40, follow_sharpness 6) with no rotate/zoom/mouse handling"
  - "Input Map contract test (keyboard + gamepad per action, values checked against engine constants, no mouse, build/start_night conflict-free)"
  - "Headless ride, sprint-ratio, diagonal, deadzone, facing and fixed-camera proofs through real Input.action_press"
affects: [01-05, 01-07, 01-08, 01-09, phase-02-playtest]

actuals:
  tokens: 5300
  tasks: 2
  commits: 4
plan_head_before: f0e665b81f4544220aca46632d87bf5378875a24
plan_head_after: 6fb92c349fc3020d8003cb443272c35f8373a530

tech-stack:
  added: []
  patterns:
    - "Presentation nodes that follow the run bind via group run_bound + bind_run(ctx, map_root); CameraRig reads map_root.get_king()"
    - "Camera angle is written exactly once (bind_run look_at); _physics_process only lerps position with 1 - exp(-k * delta)"
    - "Contract tests compare Input Map events to KEY_* / JOY_BUTTON_* / JOY_AXIS_* constants, never integer literals"

key-files:
  created:
    - presentation/camera/camera_rig.gd
    - tests/unit/test_king_movement_config.gd
    - tests/unit/test_input_map.gd
    - tests/e2e/test_king_ride.gd
  modified:
    - simulation/defs/king_def.gd
    - data/king/king.tres
    - presentation/king/king.gd
    - presentation/king/king.tscn
    - presentation/map/prototype_map.tscn

key-decisions:
  - "Camera stays perspective (fov 40) at yaw 0, offset (0,16,11), north up; angle/offset are exported for the Phase 2 playtest"
  - "acceleration 40 m/s^2 and turn_speed 12 rad/s chosen as first-pass feel values in KingDef; walk 5.0 and sprint 1.6 untouched"
  - "The 01-02 Input Map values were all correct against the engine constants; no project.godot fix was needed"

patterns-established:
  - "King root never rotates; only the Model pivot turns, so movement stays screen-aligned"
  - "Camera-rig tests locate the rig by node name and read its exported offset rather than hard-coding it"

requirements-completed: [KING-01, KING-02]

coverage:
  - id: D1
    description: "King rides with WASD/arrows/left stick; walk 5.0 m/s, sprint about 1.6x, reaches the first build spot within the walk-time budget"
    requirement: "KING-01"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_ride_reaches_the_first_spot_within_the_walk_time_budget"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_sprint_covers_about_the_sprint_multiplier_more_ground"
        status: pass
      - kind: unit
        ref: "tests/unit/test_king_movement_config.gd#test_move_speed_sprints_at_walk_speed_times_multiplier"
        status: pass
    human_judgment: false
  - id: D2
    description: "Diagonal input is not faster than cardinal; input below the 0.2 deadzone does not move the king"
    requirement: "KING-01"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_diagonal_input_is_not_faster_than_cardinal"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_stick_input_below_the_deadzone_does_not_move_the_king"
        status: pass
    human_judgment: false
  - id: D3
    description: "King accelerates smoothly and the Model turns to face its heading while the body root never rotates"
    requirement: "KING-01"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_velocity_ramps_up_instead_of_jumping_to_full_speed"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_model_turns_to_face_the_ride_direction_and_the_body_does_not"
        status: pass
    human_judgment: true
    rationale: "The assertions prove ramping and facing exist; whether the acceleration and turn rates feel right is a subjective playtest call (human-check item in the plan)"
  - id: D4
    description: "Detached smoothed follow camera at a fixed angle: rotation never changes, it settles at king + offset, trails a jump and catches up, and the player cannot rotate it"
    requirement: "KING-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_camera_rotation_never_changes_while_riding_in_all_directions"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_camera_settles_at_the_rig_offset_when_the_king_stands_still"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_camera_trails_a_sudden_king_jump_and_then_catches_up"
        status: pass
    human_judgment: true
    rationale: "Framing, trail smoothness and king readability near screen centre are visual judgments; the plan's human-check (keyboard and gamepad in a visible window) was not performed by this executor"
  - id: D5
    description: "Input Map contract: keyboard + gamepad per gameplay action matching the binding table, no mouse events, build and start_night share no key or button"
    requirement: "KING-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_input_map.gd#test_no_project_action_has_a_mouse_binding"
        status: pass
      - kind: unit
        ref: "tests/unit/test_input_map.gd#test_build_and_start_night_share_no_key"
        status: pass
      - kind: unit
        ref: "tests/unit/test_input_map.gd#test_keyboard_bindings_match_the_binding_table"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-29
status: complete
---

# Phase 1 Plan 04: King Riding Feel and Fixed Follow Camera Summary

**Accelerating, heading-facing king ride plus a detached exp()-smoothed fixed-angle CameraRig (no player rotation), with the Input Map contract and headless ride/sprint/camera proofs enforced by 26 new GUT tests.**

## Performance

- **Duration:** about 5 min
- **Started:** 2026-09-29T08:30:25Z
- **Completed:** 2026-09-29T08:35:00Z
- **Tasks:** 2 (both TDD)
- **Files modified:** 9 first-party files (4 created, 5 modified), plus `.gd.uid` files

## Accomplishments

- `KingDef` gained `acceleration` (40 m/s^2) and `turn_speed` (12 rad/s); `King` now moves velocity toward the target with `move_toward` and turns only the `Model` pivot with `lerp_angle`, so the body root and screen alignment are untouched.
- `CameraRig` replaces the king-parented camera: detached, snaps once in `bind_run`, then only lerps position with `1 - exp(-follow_sharpness * delta)`. Rotation, basis and `look_at` appear only inside `bind_run`.
- `test_input_map.gd` locks T-01-09: every gameplay action has keyboard and gamepad bindings equal to the 01-02 table (compared to engine constants), no mouse events on any non-`ui_` action, and build/start_night are conflict-free.
- `test_king_ride.gd` proves through real input: ride-to-spot within `distance / walk_speed + 1.5` s, sprint ratio within 15% of 1.6, ramped (not instant) velocity, diagonal speed equals walk speed, sub-deadzone input is ignored, facing, unchanged camera basis after 2 s in each direction, camera settles at king + offset, and the camera trails then catches a 25 m teleport.

## Task Commits

1. **Task 1 RED:** `31ddc13` (test) - failing KingDef config test plus Input Map contract test
2. **Task 1 GREEN:** `9eb8e8d` (feat) - acceleration and facing in King, new KingDef fields and data
3. **Task 2 RED:** `a7b25f3` (test) - king ride, sprint and fixed-camera e2e tests
4. **Task 2 GREEN:** `6fb92c3` (feat) - CameraRig, camera removed from king.tscn, rig added to the prototype map

**Plan metadata:** recorded in the docs(01-04) closeout commit.

## Files Created/Modified

- `presentation/camera/camera_rig.gd` - fixed-angle smoothed follow camera (KING-02)
- `presentation/king/king.gd` - acceleration via `move_toward`, Model facing via `lerp_angle`
- `presentation/king/king.tscn` - 01-02 camera child removed
- `presentation/map/prototype_map.tscn` - `CameraRig` (fov 40 `Camera3D` child) in group `run_bound`
- `simulation/defs/king_def.gd`, `data/king/king.tres` - `acceleration`, `turn_speed`
- `tests/unit/test_king_movement_config.gd`, `tests/unit/test_input_map.gd`, `tests/e2e/test_king_ride.gd` - contract and proof tests

## Decisions Made

- Kept the perspective camera (fov 40, offset (0,16,11), yaw 0, about -55 deg pitch) per the plan; angle and offset are exported so the Phase 2 playtest can tune them.
- `acceleration = 40` and `turn_speed = 12` are first-pass feel values (the plan gave only "> 0"); at 40 m/s^2 the king reaches walk speed in 0.125 s and sprint in 0.2 s, so measured 1 s sprint/walk distance ratio is about 1.5, inside the 15% band around 1.6.
- No `project.godot` correction was needed: all 01-02 Input Map values matched the engine constants.

## Deviations from Plan

### Additions within plan scope

- **Extra e2e assertions (not a rule deviation):** the plan's behavior list for Task 2 named four proofs. I also added ramped-velocity, diagonal-speed, sub-deadzone, model-facing, detached-rig and camera-trail-then-catch-up tests, because these are must_haves truths of the plan (diagonal, deadzone, smooth acceleration/facing, smoothed follow) that the four listed proofs did not cover.
- In the RED commit for Task 2 the rig is looked up by node name and as a plain `Node`; after GREEN I tightened it to `CameraRig` in the same feat commit.

**Total deviations:** 0 auto-fixed (no Rule 1-4 events).
**Impact on plan:** none; only test coverage beyond the listed behaviors.

## TDD Gate Compliance

- **Task 1:** RED commit `31ddc13`: the target tests `test_acceleration_is_defined_and_positive` and `test_turn_speed_is_defined_and_positive` failed on their assertions (2 failing of 37 total), so this RED is valid. The Input Map contract tests passed on first run because the bindings were already correct in 01-02; per the unexpected-GREEN rule this was investigated: the test is a characterization/contract guard for T-01-09, not a feature gap (an unexpected GREEN here means "no defect", documented). GREEN `9eb8e8d`: 37/37 pass. No REFACTOR commit.
- **Task 2:** RED commit `a7b25f3`: 3 of 10 tests failed on assertions (`the map has a CameraRig`, `the camera does not ride on the king`). The other 7 (ride, sprint ratio, ramp, diagonal, deadzone, facing, basis-unchanged) passed because Task 1 and the 01-02 fixed child camera already satisfied them; they are regression guards that must also hold after the camera is replaced. GREEN `6fb92c3`: 47/47 pass. No REFACTOR commit.
- A formal `gsd_run check tdd-red-evidence` record was not produced for either RED; the failing test names and assertion messages above stand as the evidence.

## Issues Encountered

None. A one-line gdlint max-line-length finding in the RED test was fixed before commit. Git warned that the Write tool produced CRLF in `tests/e2e/test_king_ride.gd`; git normalizes it to LF on commit.

## Known Stubs

None. The king remains a capsule primitive by design (D-01); plan 01-07 owns the models.

## Threat Flags

None. No new network, auth, file-access or schema surface. T-01-09 (Input Map tampering) is mitigated by `test_input_map.gd`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The plan's `<human-check>` (run the game in a window with keyboard and a gamepad and judge feel and camera readability) was not performed by this executor; coverage items D3 and D4 carry `human_judgment: true` for that reason. The orchestrator or owner should do that pass, or fold it into the Phase 1 verification.
- Plan 01-05's ride-time data test can read `walk_speed` 5.0 and `sprint_multiplier` 1.6 unchanged from `data/king/king.tres`.
- `KING-01` is also declared by 01-02, which is complete, so the shared-ID gate allows it to be marked complete now.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*

## Self-Check: PASSED
