---
phase: 01-foundation-day-loop
plan: 02
subsystem: gameplay-core
tags: [godot, gdscript, gut, walking-skeleton, command-gate, event-bus, tres-data]

requires:
  - phase: 01-foundation-day-loop
    provides: "Plan 01-01 pinned Godot 4.7.2 toolchain, vendored GUT 9.7.1, headless test.sh and lint.sh harness"
provides:
  - "Bootable prototype map: ride the king, hold the action key on the House plot, a House is built through CommandProcessor and HUD gold drops"
  - "Headless simulation (RunContext) constructible with no scene tree: SimEvents, Economy, BuildingSystem, RunManager, CommandProcessor"
  - "Data-as-.tres defs (BuildingDef/TierDef/BuildSpotDef/MapConfig/LoopTuning/KingDef) and prototype data files"
  - "Input Map with keyboard + gamepad for move/sprint/action_build/start_night/toggle_debug_overlay (no mouse)"
  - "run_bound group + bind_run(ctx, map_root) wiring convention"
  - "E2eSupport shared helpers for scene-level tests"
affects: [01-03, 01-04, 01-05, 01-06, 01-07, 01-08, 01-09, 01-10]

actuals:
  tokens: 14800
  tasks: 2
  commits: 3
plan_head_before: 8c5f7d02a6aab2940c933720a1a72dcd2631af00
plan_head_after: 23b1a81e341f18e6b4d42ed2d2f4f994360ae4d1

tech-stack:
  added: []
  patterns:
    - "Simulation layer is RefCounted-only (no Node); scenes bind to it via group run_bound + bind_run(ctx, map_root)"
    - "Single mutation gate: input emits BuildIntent, CommandProcessor.submit re-validates then mutates; rejections are returned reasons, never push_error"
    - "Every number lives in .tres data; tests derive expectations from loaded data, not literals"
    - "Hold-to-build is ephemeral input-layer state: gold moves only when the last coin lands"

key-files:
  created:
    - simulation/defs/*.gd (six Resource scripts)
    - data/buildings/house.tres
    - data/maps/prototype_map.tres
    - data/tuning/loop_tuning.tres
    - data/king/king.tres
    - simulation/events/sim_events.gd
    - simulation/economy/economy.gd
    - simulation/buildings/building_instance.gd
    - simulation/buildings/building_system.gd
    - simulation/run/run_manager.gd
    - simulation/run/run_context.gd
    - simulation/commands/build_intent.gd
    - simulation/commands/command_processor.gd
    - input/build_hold_controller.gd
    - presentation/map/prototype_map.tscn
    - presentation/map/map_root.gd
    - presentation/king/king.tscn
    - presentation/king/king.gd
    - presentation/buildings/building_views.gd
    - ui/hud/hud.tscn
    - ui/hud/hud.gd
    - tests/e2e/test_walking_skeleton.gd
    - tests/e2e/e2e_support.gd
    - tests/integration/test_build_flow.gd
    - tests/unit/test_economy_gold.gd
    - tests/fixtures/fixture_map_poor.tres
    - tests/fixtures/fixture_map_one_tier.tres
  modified:
    - project.godot

key-decisions:
  - "RunManager.get_elapsed() added so the tick (sole simulation time source) is observable"
  - "BuildingSystem.apply_next_tier returns null for an unknown spot instead of crashing (CommandProcessor is still its only caller)"
  - "CommandProcessor.UNKNOWN_INTENT (&\"unknown_intent\") added as the rejection for unrecognized intent types"
  - "test_build_is_revalidated_when_applied_outside_day sets RunManager._phase directly until plan 01-08 adds a public start_night; 01-08 should switch it to the public call"

patterns-established:
  - "Use wait_process_frames / wait_physics_frames (GUT 9.7.1 deprecates wait_frames and prints a deprecation line per call)"
  - "Reach the HUD gold label via map_root.get_node(\"HUD\").get_node(\"%GoldLabel\")"
  - "Commit each .gd.uid with its script"

requirements-completed: [BLDG-01, BLDG-03, ECON-01, KING-01, DEV-01]

coverage:
  - id: D1
    description: "Project boots into the prototype map; the king rides with keyboard/gamepad (WASD/arrows/left stick, Shift/RB sprint) on a fixed follow camera"
    requirement: "KING-01"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_walking_skeleton.gd#test_main_scene_is_prototype_map"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_walking_skeleton.gd#test_teleported_king_focuses_the_plot"
        status: pass
    human_judgment: true
    rationale: "Camera framing and movement feel are subjective; verified by orchestrator scripted visible-window run (see Tracer Gate Outcome) but not by an assertion"
  - id: D2
    description: "Hold the action key on the House plot to build tier I through CommandProcessor; HUD gold drops by the tier I cost from house.tres"
    requirement: "BLDG-01"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_walking_skeleton.gd#test_ride_to_house_plot_and_hold_builds_it"
        status: pass
    human_judgment: false
  - id: D3
    description: "BuildIntent is re-validated on apply: unknown spot, unaffordable, max tier and not-day are rejected with a reason and change nothing; unknown intent rejected"
    requirement: "BLDG-03"
    verification:
      - kind: integration
        ref: "tests/integration/test_build_flow.gd#test_build_on_unknown_spot_is_rejected_and_changes_nothing"
        status: pass
      - kind: integration
        ref: "tests/integration/test_build_flow.gd#test_build_below_cost_is_rejected_and_changes_nothing"
        status: pass
      - kind: integration
        ref: "tests/integration/test_build_flow.gd#test_second_build_on_a_single_tier_building_hits_max_tier"
        status: pass
      - kind: integration
        ref: "tests/integration/test_build_flow.gd#test_build_is_revalidated_when_applied_outside_day"
        status: pass
    human_judgment: false
  - id: D4
    description: "Gold is the only currency, changes only via CommandProcessor/Economy, and never goes negative"
    requirement: "ECON-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_economy_gold.gd#test_random_operations_never_drive_gold_negative"
        status: pass
      - kind: unit
        ref: "tests/unit/test_economy_gold.gd#test_try_spend_above_gold_is_refused_and_changes_nothing"
        status: pass
    human_judgment: false
  - id: D5
    description: "Whole simulation (RunContext) constructed and exercised with no scene tree; scene e2e runs headless"
    requirement: "DEV-01"
    verification:
      - kind: integration
        ref: "tests/integration/test_build_flow.gd#test_context_is_built_without_touching_the_scene_tree"
        status: pass
      - kind: command
        ref: "bash tools/test.sh"
        status: pass
    human_judgment: false

duration: ~4h wall clock (includes the tracer feedback-gate wait)
completed: 2026-09-29
status: complete
---

# Phase 1 Plan 02: Walking Skeleton Summary

**Bootable Godot prototype map where the keyboard/gamepad king rides to a House plot and a hold-to-build press goes through a re-validating CommandProcessor into a scene-tree-free RunContext, proven by headless e2e, integration and unit tests.**

## Performance

- **Duration:** ~4h wall clock (Task 1 tracer at 04:28Z, gate wait, Task 2 closeout ended 08:21Z)
- **Started:** 2026-09-29T04:22:00Z (approximate; follows plan 01-01 completion)
- **Completed:** 2026-09-29T08:21:00Z
- **Tasks:** 2 (Task 1 tracer, Task 2 TDD hardening)
- **Files modified:** 33 first-party files (56 including .gd.uid)

## Accomplishments

- Locked the SKELETON architecture with one real path: `.tres` data, RefCounted simulation, intent/command gate, SimEvents bus, input hold, 3D scene and HUD (Task 1, 1d0d93b).
- Simulation layer has zero scene-tree dependency: `RunContext.new(map, tuning)` is built and exercised in tests with no Node added.
- Command path hardened with headless tests for all rejection reasons plus 200 seeded random Economy operations (gold never negative).
- `E2eSupport` gives later plans a shared ride/teleport/hold/release harness for scene-level tests.

## Tracer Gate Outcome

Tracer feedback gate for Task 1: the owner replied verbatim "can you test this yourself?" and delegated the human-check to the orchestrator. Recorded outcome: **verified by orchestrator scripted run; all 5 items pass.** The orchestrator drove the real prototype map in a visible window with scripted `Input.action_press` and screenshots:

1. Map opens: green-grey ground, blue-grey capsule king, fixed high camera following the king (camera offset (0,16,11) constant before and after movement). HUD "Gold: 4".
2. Riding toward the plot reaches focus on the House spot.
3. Full hold (~0.9 s) builds tier I: gold 4 to 2, HUD "Gold: 2", BuildingViews has a view (tan block visible on the plot).
4. Sprint visibly faster: walk 5.24 m/s, sprint 8.01 m/s (5.0 x 1.6 expected).
5. Early release (0.15 s) leaves tier 0 and gold 4; leaving range mid-hold with the key still held (king 9.3 m away vs 2.5 m radius) leaves tier 0 and gold 4.

No errors or warnings in the Godot console log. Gate treated as APPROVED; Task 2 proceeded.

## Task Commits

1. **Task 1: Tracer - ride the king to the House plot and hold to build it** - `1d0d93b` (feat)
2. **Task 2 (tdd) RED-equivalent: command-path and economy tests + fixtures** - `053ed67` (test)
3. **Task 2 (tdd) GREEN/support: E2eSupport + walking-skeleton refactor** - `23b1a81` (feat)

**Plan metadata:** recorded in the docs(01-02) closeout commit.

## TDD Gate Compliance

Task 2 is `tdd="true"`, but the behavior it specifies was already implemented by the Task 1 tracer, so the RED gate could not fail on a missing feature. The tests passed on first run against Task 1 code (20/20). Per the fail-fast rule for an unexpected GREEN, this was investigated rather than ignored: the tests were confirmed non-vacuous with a mutation check (temporarily making `Economy.can_afford` accept negative costs and disabling the max-tier check in `CommandProcessor.validate_build`), which turned 4 of the new tests red (16 passing, 4 failing); both files were then restored with `git checkout -- <file>` and never committed. A formal `RED_EVIDENCE_OK` record was not produced, so this is a characterization/hardening RED, not a canonical one. The `test(01-02)` commit therefore contains passing tests, and no defect in the simulation was found (no fix commit was needed). E2eSupport was written after its consumer test was refactored to use it in the same commit rather than as a separate failing commit. No REFACTOR commit (formatter-only changes were folded into the `feat` commit).

## Files Created/Modified

- `simulation/defs/*.gd` - six Resource definitions (BuildingTierDef, BuildingDef, BuildSpotDef, MapConfig, LoopTuning, KingDef)
- `data/**/*.tres` - House (tiers 2/3/5 gold, income 1/2/3), prototype map (starting gold 4, spot house_1), loop tuning, king
- `simulation/{events,economy,buildings,run,commands}/*.gd` - headless simulation and the single mutation gate
- `input/build_hold_controller.gd` - ephemeral hold-to-build state emitting BuildIntent when the last coin lands
- `presentation/{map,king,buildings}/*` and `ui/hud/*` - scene composition root, king, building views, HUD
- `project.godot` - main scene and full Input Map (keyboard + gamepad, no mouse)
- `tests/e2e/{test_walking_skeleton,e2e_support}.gd`, `tests/integration/test_build_flow.gd`, `tests/unit/test_economy_gold.gd`, `tests/fixtures/*.tres` - test suite

## Decisions Made

- Added `RunManager.get_elapsed()` so the tick is observable.
- `BuildingSystem.apply_next_tier` returns null for an unknown spot.
- `CommandProcessor.UNKNOWN_INTENT` constant for unrecognized intents.
- The not-day integration test writes `RunManager._phase` directly because no public way to leave DAY exists until plan 01-08; that plan should switch it to `start_night`.

## Deviations from Plan

None - plan executed exactly as written (the three small additions above are interface-additive and sit within the plan's contracts; Task 1 had no Rule 1-3 deviations, and Task 2 exposed no simulation defects). The TDD RED-phase situation is documented under TDD Gate Compliance.

## Known Stubs

- `presentation/buildings/building_views.gd` and `presentation/king/king.tscn`: grey/tan primitive shapes stand in for models. Intentional per D-01; plan 01-07 swaps in CC0 models.

## Issues Encountered

- GUT 9.7.1 deprecates `wait_frames`; helpers use `wait_process_frames` instead.
- A heredoc-based multi-file write failed on a shell parse error early in Task 2 and created nothing; files were written with the Write tool instead.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Command gate, event bus, data defs and `bind_run` wiring are in place for plan 01-03 onward; later plans extend the contracts additively.
- Plan 01-08 should replace the direct `_phase` write in `test_build_flow.gd` with the public start_night call.
- Requirement IDs KING-01 and DEV-01 are also declared by other incomplete plans (01-04, and 01-01 is already done); BLDG-01, BLDG-03 and ECON-01 are shared with 01-05, 01-06 and 01-09, so the shared-ID gate governs which are marked complete now.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*

## Self-Check: PASSED
