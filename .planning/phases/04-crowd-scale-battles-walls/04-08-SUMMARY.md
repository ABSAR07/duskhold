---
phase: 04-crowd-scale-battles-walls
plan: 08
subsystem: stress-and-overlay
tags: [godot, gdscript, gate-stress, stress-map, flow-field, debug-overlay, ci, determinism, tracer, tdd]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: StuckTracker (stuck_ids, stuck_count, longest_streak_ticks, is_stuck), WallDecision (ttd_of, evaluated_count) and the shipped nav_tuning.tres (04-07); NavGrid, FlowField, Pathing.castle_field and field_version, the gap fixture (04-06); ShotCrowdScenarios and the 35-shot lists (04-05); the export exclude filter tools/* and the step bench (04-03)
provides:
  - The tools-only stress map (one 80 m wall, one 4 m gate, a 300-grunt night) and its two data defs, export-excluded
  - GateStress, the headless harness and pass rule shared by the GUT test and the CLI, with the finish line and the sink read from the map data
  - gate_stress_cli.gd and tools/gate_stress.sh (GATE_OK sentinel, allowlisted arguments, bounded) and the CI step Gate stress (ENMY-04)
  - FlowFieldGizmo, the stuck post on EnemyPathGizmo, FlowField.reached_count and CrowdOverlaySections (Walls, Field, Crowd)
  - The overlay_field_gate real-window shot on the stress map (36 shots)
affects: [04-09 stress night and frame report (adds towers and squads to the stress map), 04-10 bot walls and the walls golden, 04-11 phase gate and the push that first runs the CI step]

actuals:
  tokens: 22900
  tasks: 2
  commits: 3

plan_head_before: ab9aa9d285aeb31066a7c7622549dea2b55860eb
plan_head_after: 034a0502ef9ed7889a490d181791217f98314af4

tech-stack:
  added: []
  patterns:
    - "A tools-only harness reads its pass geometry from the map data (finish line from the gate wall's z, sink from castle_radius) and keeps only three pass-rule thresholds as documented code constants"
    - "A pass rule with a clause of its own: the stuck count is taken over every living enemy at the final tick, crossed or not, so a stall after the gate fails the gate even when everyone crossed"
    - "A debug gizmo that caches its mesh per field version, clears itself when hidden, and reads the field and grid through getters only"
    - "Overlay sections laid out in two columns by whole sections, get_text() still returns every row in reading order"

key-files:
  created:
    - tools/stress/stress_map.tres
    - tools/stress/data/stress_wall.tres
    - tools/stress/data/stress_grunt.tres
    - tools/stress/gate_stress.gd
    - tools/stress/gate_stress_cli.gd
    - tools/gate_stress.sh
    - presentation/debug/flow_field_gizmo.gd
    - ui/overlay/crowd_overlay_sections.gd
    - tests/integration/test_gate_stress.gd
    - tests/unit/test_stress_map_data.gd
    - tests/unit/test_debug_overlay_crowd_sections.gd
    - tests/e2e/test_overlay_field.gd
  modified:
    - .github/workflows/ci.yml
    - simulation/nav/flow_field.gd
    - presentation/debug/enemy_path_gizmo.gd
    - ui/overlay/debug_overlay.gd
    - ui/overlay/debug_overlay.tscn
    - tools/screenshot/shot_crowd_scenarios.gd
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot.sh
    - tests/unit/test_stress_tool_args.gd
    - tests/unit/test_shot_list.gd
    - tests/unit/test_debug_overlay_night_sections.gd

key-decisions:
  - "The gate passed on the first run with no pathing change: 300 of 300 crossed, nobody flagged at the end, and two runs in one process agree on the digest. 04-06 and 04-07 code, the three replays and the harness rule were left alone"
  - "The overlay is laid out in two columns (whole sections fill the left column to half the lines, the rest go right) because Walls, Field and Crowd pushed a 720p panel off the bottom of the window; get_text() joins both columns so every test that parses rows is unchanged"
  - "A goal cell of the castle field has no direction, so FlowFieldGizmo draws a short pin there and counts it as an arrow: arrow_count() equals the reached open cells, as the plan states"
  - "The stuck post is drawn for every living enemy the tracker flags, a vertical magenta line 2.2 m tall at its feet; it is a separate segment kind in EnemyPathGizmo and is counted in line_count()"
  - "Fastest breach reads the shortest published time to destruction over standing segments of built runs, so on the stress map (100000 hp segments) it shows hundreds of seconds, which is the point: nobody is going to break that wall"

patterns-established:
  - "New overlay sections are registered in bind_run after the previous ones and their labels are new, so the flattened row table never collides (test_the_new_row_labels_are_the_planned_ones_and_unique)"
  - "Gizmos hide and clear on overlay off or day, and rebuild once per field version"

requirements-completed: [ENMY-04]

coverage:
  - id: D1
    description: "The stress map validates clean, has one wall plot gate_wall whose run leaves one 4 m gap at x -2 to 2 on z 30, a 300-enemy night of stress grunts from four spawn points beyond the wall, a stress grunt equal to the shipped grunt but for 100000 health, an unarmed castle on the low-z side, a one-tier 100000 hp stress wall, and finish_z 28.0 / sink_radius 7.5 read from the data (38.0 after the wall moves to z 40)"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_stress_map_data.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "GateStress.run on the stress map with seed 1 and 60 s: 300 enemies, 300 crossed, 0 stuck at the end, last crossing 21.93 s, 0 wall hits, passed true; the pass rule has a stuck clause of its own (300, 300, 1 fails) and fails on 299 crossed or a hit time limit; a map without the gate reports no_gate_wall; 5 s is too short; the same seed repeats the digest"
    requirement: ENMY-04
    verification:
      - kind: integration
        ref: "tests/integration/test_gate_stress.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "bash tools/gate_stress.sh --twice prints GATE_OK enemies=300 crossed=300 stuck=0 with both digests equal; the CLI accepts --twice, --seed, --max-seconds 10 to 300 and --out under build/ and refuses --max-seconds 5 and 301, --out ../x, C:/x, a map flag and unknown flags; the CI test job runs the wrapper after the replays and uploads build/stress/"
    requirement: ENMY-04
    verification:
      - kind: e2e
        ref: "bash tools/gate_stress.sh --twice"
        status: pass
      - kind: unit
        ref: "tests/unit/test_stress_tool_args.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "Walls, Field and Crowd overlay rows: built runs, 6 segments intact and 0 broken, 5 and 1 after a break, evaluated count and shortest breach, field version, grid and reached cells, stuck count and longest streak, frame ms and the drawn counts; 14 new labels, unique and new to the flattened overlay; collecting emits no SimEvents signal and builds no goal field; the overlay lists the three sections after the squads"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_debug_overlay_crowd_sections.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_debug_overlay_night_sections.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "On the real scene at night with the overlay open FlowFieldGizmo draws one arrow per reached open cell and one cross per blocked cell, rebuilds when a break changes the field version, draws nothing with the overlay off or by day, and a held enemy is drawn as a stuck post after stuck_seconds"
    requirement: ENMY-04
    verification:
      - kind: e2e
        ref: "tests/e2e/test_overlay_field.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "Smoke, army and full_idle replay twice with unchanged digests and the existing overlay toggle, path, read-only and shot-list suites pass with the 36-shot list"
    requirement: ENMY-04
    verification:
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=full_idle --twice"
        status: pass
      - kind: unit
        ref: "tests/unit/test_shot_list.gd"
        status: pass
    human_judgment: false
  - id: D7
    description: "Whether the field arrows, the crosses, the stuck posts and the two-column overlay read well to the owner in play, beyond what the agent's own look at overlay_field_gate shows"
    verification: []
    human_judgment: true
    rationale: "Readability of a debug drawing is a judgement; the counts and the screenshot are checked, the feel is the owner's call at the phase UAT"

duration: 66 min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 08: No-Gridlock Proof and the Paths on Screen Summary

**A tools-only stress map sends 300 enemies at one 4 m gate and a headless harness proves every one crosses with nobody left stuck (twice, same digest, in CI), and the debug overlay now draws the castle flow field, the blocked cells and stuck enemies and reports the walls, the field and the crowd**

## Performance

- **Duration:** 66 min
- **Started:** 2026-10-16T09:33:21Z
- **Completed:** 2026-10-16T10:40Z
- **Tasks:** 2 (Task 1 the tracer; Task 2 as RED then GREEN)
- **Files modified:** 31 in the plan range (12 created sources and tests, 11 modified, 8 new `.uid` files)

## Accomplishments

- **The gate (ENMY-04, D-09, D-11):** `tools/stress/stress_map.tres` has one 80 m wall at z 30 with a 4 m gate, four spawn points beyond it and one night of 300 stress grunts (the shipped grunt's speed, size and attack, 100000 health); the stress wall's one tier has 100000 health, so the D-07 rule always prefers the gate. `GateStress.run` raises the wall, parks the king at (0, -60), starts the night, finds each enemy's crossing tick, sinks only enemies that crossed and reached the castle, and passes only when all 300 crossed, no living enemy (crossed or not) is flagged stuck at the final tick and the time limit was not hit. The finish line (28.0) and the sink radius (7.5) are read from the map data.
- **The local GATE_OK line (run `bash tools/gate_stress.sh --twice`, both runs in one process agree):** `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`. The median crossing took 14.9 s and the last one 21.9 s, inside the 14 to 21 s order of the researcher's 200-enemy probe; the longest stuck streak was 3.4 s (just past the 3 s flag) and nobody was flagged at the end. About 18 s wall clock per run on this machine.
- **CLI, wrapper, CI:** `gate_stress_cli.gd` allowlists `--seed`, `--twice`, `--max-seconds` (10 to 300) and `--out` (through `ReplayCli.safe_dir`, under `build/`); no map or data path can be passed. `tools/gate_stress.sh` copies the replay wrapper (import warm-up, `GATE_TIMEOUT_S` 600, passes only on a `^GATE_OK ` line and a clean log). CI gets one step, "Gate stress (ENMY-04)", after the replays and `build/stress/` in the artifact; `permissions: contents: read`, the pinned SHAs and no secrets are untouched and the YAML parses.
- **The paths on screen:** `FlowFieldGizmo` draws an arrow on every reached open cell (a pin on a goal cell), a cross on every blocked cell, rebuilt only when `Pathing.field_version()` changes, drawn only at night with the overlay open, cleared when hidden. `EnemyPathGizmo` posts every enemy the stuck tracker flags in magenta. `CrowdOverlaySections` adds Walls, Field and Crowd (14 new row labels, unique across the flattened overlay), read-only.
- **overlay_field_gate** (36th shot): captured in a real window (NVIDIA RTX 3060 laptop, Forward+, 1280x720). Review line: the cyan field arrows south of the wall bend toward the gate and the arrows north of it point on to the castle, orange crosses mark the wall cells, about 25 purple grunts are bunched into the gate mouth with the rest still marching in, the king stands clear on the castle side, and the Walls, Field and Crowd sections (26 segments intact, field version 1, 1962 reached cells, 300 enemies drawn, 7.7 ms frame) read at the right in two columns. The file is `screenshots/overlay_field_gate.png` (git-ignored output).

## Task Commits

1. **Task 1: Tracer, 300 enemies at one gate, all cross, none stuck, in CI** - `eff31f0` (feat)
2. **Task 2 RED: failing tests for the overlay field, stuck markers and crowd sections** - `4d89495` (test)
3. **Task 2 GREEN: the flow field, stuck enemies and the three readouts in the overlay** - `034a050` (feat)

**Plan metadata:** committed after this file (docs: complete plan). No refactor commit was needed.

## Files Created/Modified

- `tools/stress/stress_map.tres`, `tools/stress/data/stress_wall.tres`, `tools/stress/data/stress_grunt.tres` - the tools-only map and its defs (export-excluded by `tools/*`)
- `tools/stress/gate_stress.gd` - `GateStress`: `run`, `passes`, `finish_z`, `sink_radius`, `has_gate`
- `tools/stress/gate_stress_cli.gd`, `tools/gate_stress.sh` - the allowlisted CLI and the bounded wrapper
- `.github/workflows/ci.yml` - the Gate stress (ENMY-04) step and `build/stress/` in the artifact
- `presentation/debug/flow_field_gizmo.gd`, `presentation/debug/enemy_path_gizmo.gd` - the field drawing and the stuck post
- `ui/overlay/crowd_overlay_sections.gd`, `ui/overlay/debug_overlay.gd`, `ui/overlay/debug_overlay.tscn` - the three sections, their registration and the two-column layout
- `simulation/nav/flow_field.gd` - `reached_count()`
- `tools/screenshot/shot_crowd_scenarios.gd`, `shot_scenarios.gd`, `tools/screenshot.sh` - `overlay_field_gate` (36 shots)
- Tests: `test_gate_stress` (10), `test_stress_map_data` (10), `test_stress_tool_args` (+5, 11), `test_debug_overlay_crowd_sections` (12), `test_overlay_field` (5), `test_shot_list` (+1, 36 shots), `test_debug_overlay_night_sections` (section order)

## Decisions Made

See `key-decisions` above. Readings the plan leaves open, none a deviation:

- The stress map uses the shipped `nav_tuning.tres`; the wall plot sits at (0, 0, 27), 3 m inside the wall on the castle side, as the plan gives it.
- `GateStress.run` also returns `hit_limit` and `reason` besides the keys the plan lists; `reason` is "" for a run that happened and `no_gate_wall` or `night_did_not_start` otherwise.
- `--max-seconds` accepts whole seconds only (the bounds 10 to 300 and `is_valid_int`), which is what the plan's examples use.
- The shot runs the night for 8 s as the plan says; at that point the first grunts are at the gate and about 25 are bunched, which already shows the funnel.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The debug overlay no longer fitted a 720p window**
- **Found during:** Task 2 (first overlay_field_gate capture)
- **Issue:** With Walls, Field and Crowd added the single-column overlay ran off the bottom of the 1280x720 window after "Segments broken", so the Field and Crowd sections the shot must show were not on screen.
- **Fix:** The overlay panel got a two-column layout: `Panel/Columns` holds `OverlayText` and a new `OverlayTextRight`; whole sections fill the left column until it holds half the lines. `get_text()` joins both columns in reading order, so every test that parses rows is unchanged.
- **Files modified:** `ui/overlay/debug_overlay.tscn`, `ui/overlay/debug_overlay.gd`
- **Verification:** the overlay_field_gate PNG shows all sections; test_debug_overlay_toggle, test_overlay_paths, test_debug_overlay_registration, test_debug_overlay_night_sections and test_debug_overlay_squad_section pass in the full suite.
- **Committed in:** `034a050`

**2. [Rule 1 - Stale test] A test pinned the old section order**
- **Found during:** Task 2 (first full run, 1 failing test of 1748)
- **Issue:** `test_debug_overlay_night_sections` expected the overlay to end at Squads; this plan's planned change appends Walls, Field and Crowd.
- **Fix:** The expected order now ends `Squads, Walls, Field, Crowd`.
- **Files modified:** `tests/unit/test_debug_overlay_night_sections.gd`
- **Verification:** 14 of 14 in that script, then the full suite green (1748 of 1748).
- **Committed in:** `034a050`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 stale test)
**Impact on plan:** Both follow directly from adding three sections to the overlay. No scope creep; the overlay change is layout only and no row or test contract moved.

## Issues Encountered

- Several files had CRLF endings; `gdformat` and the Python edits normalise them to LF.
- The first RED run of `test_shot_list` was a parse error (a constant array indexed out of range); the new assertion reads the array through a variable so the RED fails on assertions.
- Two of the 12 RED crowd-section tests also raised a script error from reading a null row (the stub returns no rows); the target test fails on its assertion and the verdict was RED_EVIDENCE_OK.
- The CI test job has `timeout-minutes: 20`; the full GUT run is about 10 min here plus about 40 s for the two gate runs. The new step first runs on plan 04-11's push, so the margin on a slower runner is untested.

## Verification (final state, HEAD 034a050)

- `bash tools/test.sh`: 187 scripts, 1748 tests, 26797 asserts, exit 0 (baseline at dispatch 183 scripts, 1705 tests; +4 scripts, +43 tests). After Task 1 alone: 185 scripts, 1730 tests, 26678 asserts. `test_gate_stress`, `test_stress_map_data`, `test_stress_tool_args`, `test_debug_overlay_crowd_sections`, `test_overlay_field`, `test_debug_overlay_readonly`, `test_debug_overlay_toggle`, `test_overlay_paths` and `test_shot_list` are in the JUnit XML.
- `bash tools/gate_stress.sh --twice`: the GATE_OK line above, run after each task.
- `bash tools/replay.sh`: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks), army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks) REPLAY_OK against their goldens, full_idle `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` (6941 ticks) twice; run after each task; no golden touched.
- `bash tools/screenshot.sh overlay_field_gate`: saved, no script error in its log.
- `bash tools/lint.sh`: clean (328 files). `.tools/venv/Scripts/python` parses `.github/workflows/ci.yml`; `permissions` reads `{'contents': 'read'}` and the test job lists the new step after Seeded replay determinism.
- Tracer gate: the Task 1 verify (full suite, JUnit names, gate twice, GATE_OK line, CI greps, the three replays, lint) was run end to end on the tree that was committed; "Tracer verified end-to-end, expanding".

## TDD Gate Compliance

Task 2 (`tdd="true"`): RED `4d89495`, GREEN `034a050`; no refactor commit. RED evidence was built from the JUnit XML of `bash tools/test.sh -gselect=test_debug_overlay_crowd_sections` (exit 1) and verified with `gsd-tools check tdd-red-evidence`: `RED_EVIDENCE_OK`, target test `test_a_bought_run_counts_its_six_segments_intact` failing on its assertion (11 of 12 failed; the twelfth, the older-labels test, passes against empty rows by design). The RED commit carries stubs (empty rows, zero counts, a `reached_count` of 0, a stuck count of 0) so the tests parse and fail on assertions; `test_overlay_field` (5 of 5) and the 36-shot `test_shot_list` also failed on assertions. GREEN made all of them pass and the full suite stayed green. Task 1 is a tracer, not a TDD task.

## Known Stubs

None. The RED-commit stubs were replaced in GREEN.

## Threat Flags

None. The new CLI surface is the one the plan's threat model covers: T-04-20 (four allowlisted flags, `--max-seconds` 10 to 300, `--out` through `ReplayCli.safe_dir`, no map or data path, usage errors exit 64; pinned by `test_stress_tool_args`), T-04-21 (the run stops at `SimClock.ticks(max_seconds)` and the wrapper times out at 600 s), T-04-22 (everything lives under `tools/`, excluded by `exclude_filter` `tools/*`; the overlay sections ship like the existing overlay) and T-04-23 (one run step and one artifact path added, `permissions: contents: read`, the pinned SHAs and no secrets kept, the YAML parsed) are mitigated as planned.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 04-09 adds its towers and squads to `tools/stress/stress_map.tres`; the stress grunt's 100000 health keeps the 300 on screen. `GateStress` reads the gate from the map, so adding plots does not move the finish line.
- Plan 04-11's push is the first run of the CI Gate stress step; watch the test job against its 20-minute timeout.
- ENMY-04 is complete with this plan (the gate stress in CI and the paths in the overlay); the owner's judgement of the drawing's readability is D7 for the phase UAT.

## Self-Check: PASSED

- Created files exist: the stress map and its two defs, `gate_stress.gd`, `gate_stress_cli.gd`, `gate_stress.sh`, `flow_field_gizmo.gd`, `crowd_overlay_sections.gd` and the four test scripts, plus `screenshots/overlay_field_gate.png`.
- Commits `eff31f0`, `4d89495` and `034a050` are in `git log`; `git rev-list --count ab9aa9d..HEAD` was 3 before this file.
- Acceptance criteria re-run: `gate_wall` in the map and `max_health = 100000` in the wall def; `class_name GateStress`, `static func finish_z(`, `static func sink_radius(`, `castle_radius`, `static func passes(`, `static func run(` and no `FINISH_Z` or `SINK_RADIUS`; the three margin constants carry the tools-only exemption comment; `^GATE_OK ` in the wrapper; the CI step and `contents: read`; `class_name FlowFieldGizmo`, `func arrow_count(`, `field_version()`; `STUCK_COLOR` and `func stuck_marker_count(`; `class_name CrowdOverlaySections` with `"Segments broken"`, `"Reached cells"` and `"Frame ms"`; `CrowdOverlaySections.register(` in `debug_overlay.gd`; the screenshot and its review line above.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
