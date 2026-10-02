---
phase: 01-foundation-day-loop
plan: 11
subsystem: camera-and-input
tags: [godot, gdscript, gut, camera, zoom, input-map, spot-label, gap-closure, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "01-04 CameraRig (fixed-angle smoothed follow, aimed once in bind_run), the Input Map contract test and E2eSupport; 01-06/01-08 SpotLabel (D-07 world-space label)"
provides:
  - "zoom_in / zoom_out Input Map actions: = and keypad +, - and keypad -, right stick Y (up in, down out), deadzone 0.3, no mouse, no button"
  - "CameraRig zoom: continuous while held, clamped to 0.7x-1.5x of the offset, sliding along the fixed offset ray (get_zoom, get_effective_offset, zoom_min/zoom_max/zoom_speed exports)"
  - "Default camera offset (0, 20.8, 14.3): exactly 1.3x the UAT framing on the same angle (about 25.2 m from the king)"
  - "SpotLabel distance compensation (LEGIBLE_CAMERA_DISTANCE 16.9 m): labels keep the UAT-6 on-screen size at every zoom-out level"
  - "Input Map contract extended to the zoom actions plus a no-shared-key/button/stick-direction check"
affects: [phase-02-playtest-tuning, phase-03-unit-hotkeys, 01-12-camera-occlusion]

actuals:
  tokens: 5500
  tasks: 2
  commits: 4
plan_head_before: 80e66137a195165d57e4e93dab576676d6fe970a
plan_head_after: 54cc51ebabb8d6096055b25c4e96259bae4cda31

tech-stack:
  added: []
  patterns:
    - "Zoom moves only the rig's position along the fixed offset ray; the Camera3D child's orientation is written once in bind_run, enforced by a region-scoped grep gate"
    - "Follow smoothing is the only smoothing stage: zoom eases in and out through the existing exp() lerp"
    - "World-space labels compensate for camera distance by scaling, never below 1.0"
    - "Zoom bounds sampled in tests as an Array[float], not a Vector2 (Vector2 is float32 and breaks exact clamp comparisons)"

key-files:
  created:
    - tests/e2e/test_camera_zoom.gd
    - tests/e2e/test_camera_zoom.gd.uid
  modified:
    - project.godot
    - presentation/camera/camera_rig.gd
    - ui/world/spot_label.gd
    - tests/unit/test_input_map.gd
    - tests/e2e/test_king_ride.gd

key-decisions:
  - "Keep every design default from the plan unchanged (offset 1.3x, zoom 0.7-1.5, speed 0.6/s, deadzone 0.3, label reference 16.9 m); none needed adjusting"
  - "RED commit for task 2 carries a one-constant interface stub (SpotLabel.LEGIBLE_CAMERA_DISTANCE) so the typed tests fail on assertions instead of a parse error"
  - "Spawn framing still crops the castle's upper rows at 1280x720 (see Issues); left to the owner / Phase 2 playtest rather than changing the plan's fixed default"

patterns-established:
  - "Gameplay Input Map contract now asserts no two actions share a physical key, joypad button or (axis, sign)"

requirements-completed: [KING-02]

coverage:
  - id: D1
    description: "zoom_in / zoom_out exist with keyboard (main row and keypad) and right-stick bindings, no mouse, no clash with any other action"
    requirement: "KING-02"
    verification:
      - kind: unit
        ref: "tests/unit/test_input_map.gd#test_keyboard_bindings_match_the_binding_table"
        status: pass
      - kind: unit
        ref: "tests/unit/test_input_map.gd#test_no_two_gameplay_actions_share_a_key_button_or_stick_direction"
        status: pass
    human_judgment: false
  - id: D2
    description: "Holding zoom moves the camera along its fixed angle and stops at 0.7x / 1.5x; the angle never changes; real key and stick events zoom and a sub-deadzone stick does not; the simulation is untouched"
    requirement: "KING-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_camera_zoom.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "The default camera sits 1.3x further out on the same angle, and spot labels keep their approved on-screen size at the new default and at full zoom-out"
    requirement: "KING-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_camera_zoom.gd#test_the_title_keeps_its_on_screen_height_when_zoomed_all_the_way_out"
        status: pass
    human_judgment: true
    rationale: "Whether the new framing and zoom limits feel right is the owner's call at the end-of-phase playtest (the plan's human-check); tests prove the numbers, not the feel"

duration: 11min
completed: 2026-10-02
status: complete
---

# Phase 1 Plan 11: Camera framing and zoom (G-01-3 parts 2 and 3) Summary

**Clamped camera zoom on the keyboard (-/= and keypad) and right stick along the unchanged fixed angle, a default view 1.3x further out, and spot labels that scale with camera distance to keep their UAT-approved on-screen size.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-02T06:51:13Z
- **Completed:** 2026-10-02T07:02:24Z
- **Tasks:** 2 (both TDD: RED then GREEN)
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments

- `zoom_in` (`=`, keypad `+`, right stick up) and `zoom_out` (`-`, keypad `-`, right stick down) added to `project.godot` in the existing serialized format; deadzone 0.3; physical keycodes; no mouse; no joypad button, so Q/R/F/1-4, the face buttons and the bumpers stay free for Phase 3.
- `CameraRig` reads `Input.get_axis(&"zoom_in", &"zoom_out")` each physics tick, clamps `_zoom` to `[zoom_min 0.7, zoom_max 1.5]` and lerps toward king + `get_effective_offset()` (`offset * zoom`). The camera's orientation is still written only inside `bind_run`; the region-scoped KING-02 gate prints nothing.
- Default `offset` is now `(0, 20.8, 14.3)`: exactly 1.3x the UAT `(0, 16, 11)` on the same angle; the scene does not override it.
- `SpotLabel._process` scales the label by `max(1.0, camera distance / 16.9)`.
- Input Map contract extended (zoom keys, stick axes, zero buttons, deadzone, no shared key/button/stick direction); follow tests read `rig.get_effective_offset()`.

### Self-check numbers (windowed Forward+ run, 1280x720)

| Measurement | Value |
|-------------|-------|
| Camera to king, default | 25.24 m |
| Title on-screen height, default zoom (king beside house_3) | 60.35 px (label scale 1.34) |
| Title on-screen height, full zoom-out (zoom 1.5) | 60.23 px (label scale 2.09) |
| Title on-screen height, full zoom-in (zoom 0.7, scale clamps at 1.0) | 67.84 px |
| Camera basis after out and in | identical to start (is_equal_approx true) |

The four self-check PNGs were opened:
- (a) King at spawn, default zoom: the king centred, the castle's front, gate and four blue-roofed towers above him, both House plots at (+-9, 9) fully inside the frame left and right. The castle's top rows are cropped by the upper frame edge.
- (b) King beside house_3, default zoom: "House I / +1 gold at dawn" with two coin discs above the plot, crisp and legible, one more plot visible top right.
- (c) After holding zoom_out to the limit: same view angle, much more ground visible, the castle appears at the bottom-right corner, label text about the same size as (b).
- (d) After holding zoom_in to the limit: same angle, king and plot larger, label slightly larger than (b) (zooming in only enlarges labels).

`bash tools/screenshot.sh day_overview spot_label` saved both PNGs; both opened and frame sensibly (day_overview: castle, two built Houses and the king; spot_label: label over the plot).

## Task Commits

1. **Task 1 (tracer): zoom along the fixed angle through the Input Map**
   - RED: `6ee96a1` (test) - failing contract tests: Input Map assertions failed on the missing actions; test_camera_zoom failed on the missing rig API
   - GREEN: `da6cd3a` (feat) - actions in `project.godot`, zoom in `CameraRig`
2. **Task 2: further default camera and distance-compensated labels**
   - RED: `b52730c` (test) - default-framing and label-size tests failing on assertions (offset ratio 1.0, label scale 1.0 vs expected 1.57, Title 3.38 px vs 5.38 px)
   - GREEN: `54cc51e` (feat) - offset `(0, 20.8, 14.3)` and `SpotLabel._process` scaling

**Plan metadata:** recorded in the docs commit that carries this file.

## Tracer gate

Task 1's `<verify>` (full suite, XML presence of the three suites, region-scoped angle gate, lint) was re-run end to end after the GREEN commit and passed (300/300 at that point); expansion (task 2) then proceeded. Final suite: 303/303.

## Files Created/Modified

- `project.godot` - `zoom_in` and `zoom_out` actions.
- `presentation/camera/camera_rig.gd` - zoom state and API, clamped zoom along the offset ray, new default offset, rewritten class doc.
- `ui/world/spot_label.gd` - `LEGIBLE_CAMERA_DISTANCE`, per-frame distance scale, doc sentence.
- `tests/unit/test_input_map.gd` - zoom actions in every table, `ZOOM_DEADZONE`, deadzone test, no-shared-binding test.
- `tests/e2e/test_king_ride.gd` - follow tests compare against `get_effective_offset()`.
- `tests/e2e/test_camera_zoom.gd` (+ `.gd.uid`) - 11 real-scene proofs (clamps, fixed ray, angle, real key and stick events, deadzone, simulation untouched, default framing, label scale, Title height).

## Design Defaults (from the plan; none changed)

| Choice | Default | Why |
|--------|---------|-----|
| Default camera distance | `offset = (0, 20.8, 14.3)`: 1.3x the UAT framing, same angle (about 55.5 deg down, yaw 0), about 25.2 m from the king | "A bit further away"; debugger range 1.25-1.5x |
| Zoom range | `zoom_min 0.7` (about 17.7 m) to `zoom_max 1.5` (about 37.9 m) | Slightly closer than UAT; far enough to see the base core |
| Zoom step | Continuous while held, `zoom_speed 0.6` units/s at full input; right stick analog | One model for keys and stick |
| Zoom smoothing | No second stage; the follow lerp (`follow_sharpness 6.0`) eases it | Zoom only moves the lerp target along the ray |
| Keyboard | `zoom_in`: `=` (61), keypad `+` (4194437); `zoom_out`: `-` (45), keypad `-` (4194435); physical keycodes | No mouse; clear of every other binding |
| Gamepad | Right stick Y (axis 3): up = in, down = out; deadzone 0.3 | Face buttons, bumpers and D-pad stay free |
| Label legibility | `SpotLabel` scale = camera distance / 16.9 m, never below 1.0 | Keeps the UAT-6 size at every zoom-out level |
| Not done | Building collision and the minimap | Phase 4 obstacles / backlog 999.1 |

## Decisions Made

None beyond the plan's defaults; see key-decisions for the two execution-level choices (interface stub in the RED commit, castle crop left to the owner).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Zoom-clamp test lost double precision through a Vector2**
- **Found during:** Task 1 GREEN
- **Issue:** `_hold_sampling` returned `Vector2(lowest, highest)`; Vector2 stores float32, so a zoom of exactly `zoom_min` (0.7) read back as 0.69999998 and "never below zoom_min" failed although the rig was correct.
- **Fix:** returned an `Array[float]` instead.
- **Files modified:** `tests/e2e/test_camera_zoom.gd`
- **Verification:** all 8 then-current camera tests passed, then the full suite.
- **Commit:** `da6cd3a`

**2. [Rule 3 - Blocking] Task 2 RED could not load without the constant**
- **Found during:** Task 2 RED
- **Issue:** the tests read `SpotLabel.LEGIBLE_CAMERA_DISTANCE`; with the constant missing, the whole test script failed to parse, which would have made the RED INVALID_RED (a parse error, not an assertion on the behavior).
- **Fix:** the RED commit also declares that one constant (the planned value and doc comment) so the scripts load and the tests fail on the planned behavior (offset ratio, label scale, Title height).
- **Files modified:** `ui/world/spot_label.gd`
- **Commit:** `b52730c`

**Total deviations:** 2 auto-fixed (1 bug in test code, 1 blocking). **Impact:** none on scope or behavior.

### TDD notes

Task 1's RED: the Input Map file failed 6 tests on assertions (missing actions). test_camera_zoom.gd failed 8/8 on "Nonexistent function 'get_zoom'" / "Invalid access to property 'zoom_max'" runtime errors, which is the missing-rig-API failure the plan names; it is not an assertion-level RED for that file.

## Issues Encountered

- **Castle crop at spawn (for the owner):** at 1280x720 and default zoom, the spawn view shows the castle's front and towers but the upper rows are cut by the top frame edge; the plots at (+-9, 9) are fully visible. The plan fixes the default at 1.3x and the zoom-out reaches the full base, so the value was not changed. If the owner wants the whole castle in the spawn frame, raise `offset` (for example 1.5x) or lower `zoom` default at the Phase 2 playtest.
- At full zoom-out the label's coin discs and "+1 gold at dawn" sit close under the title (offsets scale with the label); legible in (c).

## Known Stubs

None.

## Threat Flags

None. T-01-18 (binding drift) is mitigated by `test_input_map.gd`; T-01-19 (unbounded camera) by the clamp and `test_camera_zoom.gd`.

## Next Phase Readiness

G-01-3 parts 2 and 3 are closed. Part 1 (king hidden behind buildings) is plan 01-12. End-of-phase human check: ride, hold `-` / `=` (or keypad, or right stick), confirm the framing, limits and legible labels. No Godot process left running; nothing pushed.

## Self-Check: PASSED

- Files found: `tests/e2e/test_camera_zoom.gd`, `tests/e2e/test_camera_zoom.gd.uid`, `presentation/camera/camera_rig.gd`, `ui/world/spot_label.gd`, `project.godot`.
- Commits found: `6ee96a1`, `da6cd3a`, `b52730c`, `54cc51e`.
- Acceptance gates re-run: `zoom_in={`/`zoom_out={` present, `"axis":3` count 2, no `rig.offset` in test_king_ride, angle gate empty, `Vector3(0.0, 20.8, 14.3)` present, scene has no `offset =` override, full suite 303/303, lint clean.
