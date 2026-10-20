---
phase: 04-crowd-scale-battles-walls
verified: 2026-10-20T06:48:56Z
status: gaps_found
score: "3/4 roadmap success criteria verified in code and tests (criterion 3, PLAT-01, FAILED by measurement: median-run p95 10.95 ms against the unchanged 8.0 ms budget, down from 37.04 ms); 127/131 plan truths verified, 3 failed (04-09 p95 budget, 04-21 p95 budget, 04-21 owner packet and export not produced; all three roll up into the one gap below), 1 insufficient_spec (04-09 GTX 970 transfer, backstop tier); 2/3 requirement IDs have implementation evidence (BLDG-10, ENMY-04 satisfied; PLAT-01 NOT satisfied, left Pending)"
must_haves:
  roadmap_truths: 4
  roadmap_truths_verified: 3
  roadmap_truths_failed: 1
  plan_truths_declared: 131
  plan_truths_declared_note: "76 in plans 04-01 to 04-11 and 55 in the twelve gap-closure plans 04-12 to 04-23 (7, 4, 5, 4, 4, 4, 4, 5, 5, 5, 4, 4)"
  plan_truths_verified: 127
  plan_truths_failed: 3
  plan_truths_insufficient_spec: 1
  plan_artifacts_checked: "88/92 by gsd-tools verify artifacts over all 23 plans, re-run by me. The four tool misses are location or sequencing facts, none is a stub: 04-03 simulation/night/enemy_index.gd (deleted on purpose by plan 04-19, commit 8b8a30d; the index now lives in native/src/native_enemies.cpp behind EnemySystem), 04-10 tests/fixtures/fixture_map_replay_walls.tres pattern WallRunDef (literal-string miss, the run is an inline sub_resource through its script path, unchanged from the first verification), 04-12 simulation/night/enemy_system.gd pattern behind_kind (the held-for-target memory moved into the native store: native/src/enemy_step.cpp lines 366-482 and native/src/native_enemies.cpp lines 53 and 183, bound as behind_kind_of; the GDScript facade no longer holds the field), 04-21 04-PLAYTEST-GATE.md pattern 'Update after the gap plans' (a REAL miss: Task 2 of 04-21 never ran, so the owner re-check update was never written; it is part of the gap below)"
  plan_key_links_checked: "55/55 by gsd-tools verify key-links over all 23 plans, re-run by me"
  prohibitions_declared: 33
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass. 20 in plans 04-01 to 04-11 (carried from the first verification, no change) and 13 in plans 04-12 to 04-23 (2, 1, 2, 0, 2, 0, 0, 2, 2, 1, 1, 0). My reading found no violation; the process prohibitions (no push or gh outside the named task, no system-wide install) cannot be verified from the tree and are taken from the SUMMARYs and the CI record. Details in the Plan must_haves section"
  requirement_ids: 3
  requirement_ids_satisfied: 2
  requirement_ids_failed: 1
  requirement_ids_orphaned: 0
re_verification:
  previous_status: gaps_found
  previous_score: "3/4 roadmap success criteria; 74/76 plan truths; PLAT-01 failed at p95 37.04 ms (verified 2026-10-16T21:04:00Z at HEAD 1d29358, before the owner's UAT and before the native port)"
  gaps_closed: []
  gaps_narrowed:
    - "ROADMAP criterion 3 / PLAT-01: p95 37.04 ms to 10.95 ms against the 8.0 ms budget (p50 20.92 to 6.25 ms, about 43 to about 142 fps); the cause moved from the simulation step (22 ms headless) to the three per-frame view loops (step 2.33 ms headless, real-window ablation with the loops off p95 4.55 ms)"
  gaps_remaining:
    - "ROADMAP criterion 3 / PLAT-01 (narrowed, one entry below)"
  regressions: []
  owner_items_closed_by_code: "UAT G-04-6 (overlay below the banner, 04-13) and G-04-7 (melee enemies break through to targets, 04-12) are closed in code and tests; the owner's re-judgement of both is still due (human_verification)"
covered_files:
  - .github/workflows/ci.yml
  - .gitignore
  - .planning/phases/04-crowd-scale-battles-walls/04-01-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-01-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-02-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-02-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-03-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-03-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-04-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-04-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-05-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-05-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-06-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-06-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-07-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-07-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-08-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-08-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-09-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-09-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-10-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-10-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-11-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-11-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-12-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-12-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-13-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-13-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-14-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-14-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-15-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-15-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-16-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-16-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-17-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-17-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-18-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-18-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-19-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-19-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-20-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-20-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-21-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-21-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-22-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-22-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-23-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-23-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-BALANCE-REPORT.md
  - .planning/phases/04-crowd-scale-battles-walls/04-CONTEXT.md
  - .planning/phases/04-crowd-scale-battles-walls/04-DISCUSSION-LOG.md
  - .planning/phases/04-crowd-scale-battles-walls/04-FRAME-REPORT.md
  - .planning/phases/04-crowd-scale-battles-walls/04-PATTERNS.md
  - .planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md
  - .planning/phases/04-crowd-scale-battles-walls/04-RESEARCH.md
  - .planning/phases/04-crowd-scale-battles-walls/04-REVIEW-DISPOSITION.md
  - .planning/phases/04-crowd-scale-battles-walls/04-REVIEW.md
  - .planning/phases/04-crowd-scale-battles-walls/04-SECURITY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-UAT.md
  - .planning/phases/04-crowd-scale-battles-walls/04-VALIDATION.md
  - ASSETS.md
  - addons/duskhold_sim/duskhold_sim.gdextension
  - assets/attribution.json
  - data/buildings/wall.tres
  - data/maps/prototype_map.tres
  - data/tuning/nav_tuning.tres
  - export_presets.cfg
  - input/selection_controller.gd
  - native/.gdignore
  - native/CMakeLists.txt
  - native/src/enemy_step.cpp
  - native/src/gd_math.h
  - native/src/native_enemies.cpp
  - native/src/native_enemies.h
  - native/src/native_field.cpp
  - native/src/native_field.h
  - native/src/native_separation.cpp
  - native/src/native_separation.h
  - native/src/native_sim.cpp
  - native/src/native_sim.h
  - native/src/native_structures.cpp
  - native/src/native_structures.h
  - native/src/native_stuck.cpp
  - native/src/native_stuck.h
  - native/src/native_wall_decision.cpp
  - native/src/native_wall_decision.h
  - native/src/native_walls.cpp
  - native/src/native_walls.h
  - native/src/register_types.cpp
  - native/src/register_types.h
  - presentation/buildings/building_views.gd
  - presentation/crowd/crowd_batch.gd
  - presentation/crowd/crowd_instance.gdshader
  - presentation/crowd/mesh_baker.gd
  - presentation/debug/enemy_path_gizmo.gd
  - presentation/debug/flow_field_gizmo.gd
  - presentation/enemies/enemy_views.gd
  - presentation/king/king.gd
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/units/selection_rings.gd
  - presentation/units/unit_views.gd
  - presentation/vfx/death_puff.gdshader
  - presentation/vfx/death_puff_batch.gd
  - presentation/vfx/health_bar_batch.gd
  - presentation/vfx/health_bar_batch.gdshader
  - presentation/vfx/projectile_vfx.gd
  - presentation/walls/wall_views.gd
  - simulation/buildings/building_system.gd
  - simulation/defs/build_spot_def.gd
  - simulation/defs/enemy_def.gd
  - simulation/defs/map_config.gd
  - simulation/defs/nav_tuning.gd
  - simulation/events/sim_events.gd
  - simulation/nav/flow_field.gd
  - simulation/nav/goal_field_cache.gd
  - simulation/nav/nav_grid.gd
  - simulation/nav/pathing.gd
  - simulation/nav/stuck_tracker.gd
  - simulation/nav/wall_decision.gd
  - simulation/night/crowd_read_view.gd
  - simulation/night/enemy_system.gd
  - simulation/night/night_sim.gd
  - simulation/night/pending_hits.gd
  - simulation/night/structure_index.gd
  - simulation/night/target_query.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - simulation/squads/separation.gd
  - simulation/squads/squad_system.gd
  - simulation/squads/unit_system.gd
  - simulation/walls/wall_run_def.gd
  - simulation/walls/wall_solids.gd
  - simulation/walls/wall_system.gd
  - simulation/walls/wall_validation.gd
  - tests/e2e/test_enemy_views.gd
  - tests/e2e/test_overlay_banner_layout.gd
  - tests/e2e/test_overlay_field.gd
  - tests/e2e/test_projectiles_visible.gd
  - tests/e2e/test_results_screen.gd
  - tests/e2e/test_squad_tracer_scene.gd
  - tests/e2e/test_unit_views.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/e2e/test_wall_tracer_scene.gd
  - tests/e2e/test_wall_views.gd
  - tests/fixtures/fixture_map_replay_walls.tres
  - tests/fixtures/fixture_map_walls.tres
  - tests/fixtures/fixture_map_walls_gap.tres
  - tests/fixtures/trace/enemy_step_refs.txt
  - tests/golden/walls.json
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_report.gd
  - tests/integration/test_balance_report_walls.gd
  - tests/integration/test_gate_stress.gd
  - tests/integration/test_wall_behaviour.gd
  - tests/integration/test_wall_break_to_target.gd
  - tests/integration/test_wall_dawn.gd
  - tests/integration/test_wall_determinism.gd
  - tests/integration/test_wall_detour.gd
  - tests/integration/test_walls_replay_golden.gd
  - tests/support/sim_signals.gd
  - tests/unit/test_crowd_batch.gd
  - tests/unit/test_crowd_read_view.gd
  - tests/unit/test_death_puff_batch.gd
  - tests/unit/test_debug_overlay_crowd_sections.gd
  - tests/unit/test_debug_overlay_night_sections.gd
  - tests/unit/test_enemy_store_native.gd
  - tests/unit/test_enemy_trace.gd
  - tests/unit/test_enemy_wall_flags_contract.gd
  - tests/unit/test_field_route_pins.gd
  - tests/unit/test_flow_field.gd
  - tests/unit/test_frame_report.gd
  - tests/unit/test_goal_field_cache.gd
  - tests/unit/test_health_bar_batch.gd
  - tests/unit/test_los_targets.gd
  - tests/unit/test_map_nav_validation.gd
  - tests/unit/test_map_wall_validation.gd
  - tests/unit/test_melee_breaks_to_target.gd
  - tests/unit/test_mesh_baker.gd
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_native_extension.gd
  - tests/unit/test_native_field.gd
  - tests/unit/test_native_math_contract.gd
  - tests/unit/test_native_rules_guard.gd
  - tests/unit/test_native_separation.gd
  - tests/unit/test_native_structures.gd
  - tests/unit/test_native_walls.gd
  - tests/unit/test_nav_grid.gd
  - tests/unit/test_nav_tuning_contract.gd
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_projectile_vfx.gd
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_prototype_map_walls.gd
  - tests/unit/test_replay_cli_args.gd
  - tests/unit/test_separation.gd
  - tests/unit/test_separation_grid.gd
  - tests/unit/test_separation_pins.gd
  - tests/unit/test_shot_list.gd
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spatial_index.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_step_attribution.gd
  - tests/unit/test_step_bench_args.gd
  - tests/unit/test_stress_map_data.gd
  - tests/unit/test_stress_tool_args.gd
  - tests/unit/test_structure_decision_pins.gd
  - tests/unit/test_stuck_pins.gd
  - tests/unit/test_stuck_tracker.gd
  - tests/unit/test_target_query_pins.gd
  - tests/unit/test_wall_blocking.gd
  - tests/unit/test_wall_data_contract.gd
  - tests/unit/test_wall_decision.gd
  - tests/unit/test_wall_geometry_pins.gd
  - tests/unit/test_wall_plot_isolation.gd
  - tests/unit/test_wall_solids.gd
  - tests/unit/test_wall_system.gd
  - tools/_common.sh
  - tools/export.sh
  - tools/gate_stress.sh
  - tools/godot_cpp_pin.txt
  - tools/native_build.sh
  - tools/playtest.sh
  - tools/replay.sh
  - tools/replay/balance_report.gd
  - tools/replay/playtest_bot.gd
  - tools/replay/playtest_strategies.gd
  - tools/replay/replay_driver.gd
  - tools/replay/replay_scenarios.gd
  - tools/replay/sim_recorder.gd
  - tools/screenshot.sh
  - tools/screenshot/shot_crowd_scenarios.gd
  - tools/screenshot/shot_runner.gd
  - tools/screenshot/shot_scenarios.gd
  - tools/stress.sh
  - tools/stress/data/stress_barracks.tres
  - tools/stress/data/stress_footman.tres
  - tools/stress/data/stress_grunt.tres
  - tools/stress/data/stress_tower.tres
  - tools/stress/data/stress_wall.tres
  - tools/stress/enemy_trace.gd
  - tools/stress/frame_report.gd
  - tools/stress/frame_report_cli.gd
  - tools/stress/gate_stress.gd
  - tools/stress/gate_stress_cli.gd
  - tools/stress/step_attribution.gd
  - tools/stress/step_bench.gd
  - tools/stress/stress_map.tres
  - tools/stress/stress_night.gd
  - tools/stress/stress_night.tscn
  - tools/test.sh
  - ui/overlay/crowd_overlay_sections.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay.tscn
  - ui/overlay/night_overlay_sections.gd
  - ui/world/spot_label_model.gd
covered_digest: "v2:sha256:bb2307855edd2e01ad89f1bff4490a146032bc51ba7109402c7d459eb1c6c9ca"
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "ROADMAP success criterion 3 / PLAT-01: a scripted stress night with hundreds of units, enemies and projectiles on screen holds 60 fps on GTX 970-class hardware, or within a documented equivalent frame-time budget on the dev machine (the documented budget is a median-run p95 at or under 8.0 ms, D-12); plan 04-09 truth 4, plan 04-21 truth 1 (G-04-5), plan 04-21 truth 5 (the owner's fresh export, three re-captured screenshots and the dated re-check list, Task 2, not run)"
    status: failed
    reason: "Measured and committed as NOT met, twice. After the native port (plan 04-21, 2026-10-19, same machine and method as 04-09): FRAME_REPORT_OK runs=3 median_run=2 p95_ms=10.95 budget_ms=8.0 within=false enemies=300 units=50 arrows=239 (runs 10.88 / 10.95 / 11.11 ms, 2.1 percent spread; p50 6.25 ms, about 142 fps; the D-10 on-screen bar met in full). Before the port the same method read p95 37.04 ms and p50 20.92 ms. The step is no longer the cost: 2.33 ms headless (towers 0.49, squads 1.34, enemies 0.48; was 22.2 ms), frames that run a step are no slower than frames that do not, and a real-window ablation that switched the _process of ProjectileVfx, EnemyViews and UnitViews off read p95 4.55 ms in both trials (arrows about 2.0 ms of mean frame, enemy views about 1.1 ms, unit views about 0.5 ms). FrameReport.BUDGET_P95_MS is still 8.0 (tools/stress/frame_report.gd line 20, read by me); nothing was lowered or raised. Plan 04-21 halted at its stop rule; its Task 2 never ran, so 04-PLAYTEST-GATE.md still opens with the 37.04 ms packet and no fresh export or re-captured screenshots exist for the owner's re-check. Owner decision 2026-10-20 (STATE.md): one more gap round that ports the per-frame view fills to C++, pins-first and byte-identical, with the 8.0 ms budget unchanged; a documented higher budget and the squad per-unit port were rejected on the numbers. No GTX 970 was measured (RESEARCH A1 projection only: p50 8.1 to 10.0 ms, p95 14.2 to 17.5 ms, a projection, and it was not re-checked by me)"
    artifacts:
      - path: ".planning/phases/04-crowd-scale-battles-walls/04-FRAME-REPORT.md"
        issue: "records the miss in the new '## After the native port' section (p95 10.95 ms against 8.0 ms) with the ablation; the ablation was a scratch probe, not committed (like the 04-09 profile)"
      - path: "presentation/vfx/projectile_vfx.gd"
        issue: "per-frame GDScript multimesh fill, about 2.0 ms of mean frame in the real window (review IN-07 and IN-08 quantify the view-layer per-frame costs)"
      - path: "presentation/enemies/enemy_views.gd"
        issue: "per-frame GDScript fill of the enemy batches, about 1.1 ms"
      - path: "presentation/units/unit_views.gd"
        issue: "per-frame GDScript fill of the unit batches, about 0.5 ms"
      - path: ".planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md"
        issue: "still the pre-port packet (37.04 ms at the top); 04-21 Task 2 (fresh export, three re-captured screenshots, the dated owner re-check list for UAT tests 5, 6 and 13) was never run"
    missing:
      - "The owner's recorded route (STATE.md, 2026-10-20), planned through /gsd-plan-phase 4 --gaps: port the per-frame view fills (ProjectileVfx _process about 2.0 ms, EnemyViews about 1.1 ms, UnitViews about 0.5 ms) to C++ over the already packed read view, pins-first and byte-identical (the views only read, so no digest can move; check the drawn result against the current screenshots), animate arrows from origin, target and launch time natively or on the GPU; keep FrameReport.BUDGET_P95_MS at 8.0, the stress map and its load numbers, and the native-rule guards of test_native_rules_guard"
      - "Then 04-21's unfinished Task 2 (bash tools/export.sh with the DLL check and the 90 s launch, bash tools/screenshot.sh crowd_stress_night walls_night_breach overlay_field_gate, and the dated update at the top of 04-PLAYTEST-GATE.md that names UAT tests 5, 6 and 13 and the native build step) and the re-measurement bash tools/stress.sh --runs=3 --duration=20 into a new dated section of 04-FRAME-REPORT.md, ablation numbers and the step attribution included; PLAT-01 stays Pending in REQUIREMENTS.md until a stress-night median-run p95 meets 8.0 ms, and it is re-verified on real campaign battles in Phase 13"
      - "Next-steps note for the gap planner: open review finding CR-01 (tools/native_build.sh has only set -u, line 290 cp -f of the library is unchecked, so a failed copy, for example while a Godot process holds the DLL open, still writes a current stamp and prints NATIVE_BUILD_OK and a stale local library passes duskhold_require_native) bites exactly the workflow this gap round repeats (rebuild, replay, stress, export on a developer machine); the planner should fold its fix (remove the stamp first, verify the copy, bind the stamp to the library bytes) into the round or run it before. WR-08 (the MapRoot missing-library message may never show) and WR-09 to WR-11 and IN-07 to IN-16 are in 04-REVIEW.md and 04-REVIEW-DISPOSITION.md (28 findings, all open)"
deferred:
  - truth: "Night readability under hundreds of units (individual enemies are small from the stress camera; the palisade is low contrast against the dark night ground; tier I and II palisades look alike from the riding camera)"
    addressed_in: "Phase 8"
    evidence: "ROADMAP Phase 8 'Art, Readability & Sound' goal: 'nights that stay readable in big battles'; UI-05 maps to Phase 8 (Pending). 04-PLAYTEST-GATE.md assumption 25 records it as observed and left for that pass; the owner signed the looks off at UAT test 13 (all other 24 assumptions confirmed). Informational: no Phase 4 roadmap criterion depends on it"
advisory: []
warnings:
  - id: "Owner re-checks after the gap round are due and the packet for them was never written"
    where: ".planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md (top still shows 37.04 ms)"
    issue: "UAT tests 5, 6 and 13 came back 'issue' on 2026-10-19; their fixes are in (G-04-6, G-04-7) or partly in (G-04-5), but the owner has not re-judged them and 04-21 Task 2 (the dated re-check list and a fresh export) did not run. A known, recorded unmet item, not a new finding"
    decision_requested: "Re-check list belongs after the view-loop port; see human_verification"
  - id: "Code review: 28 of 28 findings open (1 critical, 11 warning, 16 info)"
    where: "04-REVIEW.md (standard depth, 86 files, reviewed 2026-10-20), 04-REVIEW-DISPOSITION.md"
    issue: "Recorded facts carried here, not re-reviewed by me. CR-01 is real in the tree (tools/native_build.sh line 20 'set -u' only, line 290 unchecked 'cp -f', I read both): a stale local library can pass the stamp guard. CI is unaffected (it builds from source into a clean checkout). WR-08 says the missing-library boot message in MapRoot._ready can never run because typed native members stop the dependent scripts from compiling first; the 04-22 executor did observe 'push_error plus rc 1' with the DLL moved away from an export, so the no-fallback behaviour holds and only the friendly message is in doubt; I did not repeat that launch (it would change a build directory)"
    decision_requested: "Triage through the review-fix loop per the owner's recorded process, or fold CR-01 into the next gap round (see the gap's missing list)"
  - id: "Validation is partial by design: nyquist_compliant false"
    where: "04-VALIDATION.md (status validated, 50 task rows: 46 green, 1 resolved owner checkpoint 4-16-01, 2 red by design 4-09-02 and 4-21-01, 1 not run 4-21-02)"
    issue: "The red and not-run rows are the PLAT-01 budget and 04-21 Task 2, the same facts as the gap"
    decision_requested: "None beyond the gap"
  - id: "04-21 is status halted by its own stop rule"
    where: "04-21-SUMMARY.md"
    issue: "Honest and intended outcome, not a defect: the budget miss was committed with numbers and nothing was lowered or raised. It is the only plan of the 23 not complete, and 04-09 (halted in the first round) now reads complete with a halt_resolution line"
    decision_requested: "None; the route is recorded"
  - id: "Full-suite flake: tests/e2e/test_select_one_type.gd"
    where: "post-merge gate at 920674a: 211 scripts, 1979 tests, 1978 passing"
    issue: "One script failed once in the full run under the audit agents' load (a single click selected nothing) and then passed 4 of 4 isolated reruns with no code change; it passed again in my own isolated run (2 of 2 tests); the same suite is green on CI at b5a6f57. Timing flake of a full run, not a regression. Taken from the orchestrator; I did not run the full suite"
    decision_requested: "None"
  - id: "CI, the export launch and the real-window screenshot passes were taken from the orchestrator and the SUMMARYs, not re-run by me"
    where: "CI run 39310876191 (green on b5a6f57, lint, test, export, screenshots, native-linux GCC, native-windows MSVC, both from source); 04-13 and 04-16 screenshot reviews; the 04-22 export launch"
    issue: "I cannot run gh or a game window in this role. Everything after b5a6f57 is planning documents only (HEAD 0997db1; git status clean), so the CI result applies to the code I read"
    decision_requested: "None"
  - id: "Bots buy walls only late; 0 segments were broken in the whole balance sweep (carried)"
    where: "04-BALANCE-REPORT.md, review WR-06"
    issue: "D-15's neutral-balance result says walls do not break the Phase 2 bar when bought late; it says nothing about mid-game walls. The owner passed UAT test 7 (nights still tense) and test 1. The 04-12 rule change moved one bot run (balanced seed 2, night 8, recorded in 04-BALANCE-REPORT.md and the 04-12 summary); outcomes and nights survived are unchanged"
    decision_requested: "None"
  - id: "gsd-tools artifact misses (tooling and sequencing, informational)"
    where: "04-03 (enemy_index.gd), 04-10 (WallRunDef), 04-12 (behind_kind), 04-21 ('Update after the gap plans')"
    issue: "See plan_artifacts_checked; three are location or literal-string facts, the fourth is the real unmet Task 2"
    decision_requested: "None beyond the gap"
behavior_unverified_items:
  - truth: "04-07 deviation, now ported to C++ by 04-19: an enemy that gives up on a segment never takes that same segment again while a way round exists (the wall_given_up flag in native/src/enemy_step.cpp)"
    test: "Run a night with a long weak wall and a crowd near the break-even; watch an individual enemy that walks away from a segment while its neighbours keep hitting it"
    expected: "It never turns back to the same segment while the gap is still reachable; it still breaks in when sealed (the detour is MAX_TICKS)"
    why_human: "No test names wall_given_up or pins this per-enemy invariant (grep over tests/ is empty); it is exercised only through its effect (test_nobody_flips_between_breaking_and_walking_round_more_than_twice, test_wall_behaviour 8/8 re-run by me) and, since 04-19, through the five committed enemy-trace digests that keep the port tick-identical to the GDScript step. The owner passed UAT test 9 on 2026-10-19 (the rule stays), so this is carried as evidence quality, not an open owner question"
coincidental_reliance_items:
  - truth: "04-22: a stale native library is a hard, named error in every wrapper (the stamp equals the source hash)"
    reason: undeclared-precondition
    harden: "The guard holds only while tools/native_build.sh actually installs the library it stamps: line 290 'cp -f' is unchecked and the script has only 'set -u', and duskhold_require_native compares stamp text to the source hash, never the library bytes to the stamp (review CR-01). Declare the precondition: remove the stamp before the copy, check the copy, write the library sha256 into the stamp and recompute it in the guard"
human_verification:
  - name: "The stress night feels smooth and the crowd reads, now on the native step (UAT test 5)"
    requirement: "PLAT-01"
    test: "After bash tools/native_build.sh in Git Bash, run the stress night from the editor binary in PowerShell: & \".\\.tools\\godot\\4.7.2-stable\\Godot_v4.7.2-stable_win64.exe\" --path . res://tools/stress/stress_night.tscn -- --duration=30 (04-21 human-check; repeat after the view-loop port that the gap asks for, since the measured p95 is still 10.95 ms)"
    expected: "300 enemies, 50 footmen, 20 towers and the arrows are legible as a crowd and the frame time is tolerable, or the owner says where it still hurts. Claude measured about 142 fps at the median and a 10.95 ms p95 against the 8.0 ms budget"
    why_human: "Smoothness and crowd legibility are perceptual; the measurement is committed and is the failed gap, how it feels on the owner's machine is the owner's call"
  - name: "The debug overlay sits below the night banner at 720p (UAT test 6, plan 04-13)"
    requirement: "ENMY-04"
    test: "Press F3 on a night (the stress night or a prototype night with walls) in a 1280x720-based window and read the night banner ('Night 8 of 8 - 300 enemies left'), the fast-forward label and the last overlay row; look at the three re-captured shots overlay_on, overlay_paths, overlay_field_gate and the CI Linux fallback-font overlay_field_gate.png (04-13 human-check, 04-16 D5)"
    expected: "The banner reads whole above the panel, nothing that matters is hidden, the last row is on screen, and overlay_paths shows a night"
    why_human: "Layout adequacy and legibility are by eye; the y-only layout test (test_overlay_banner_layout 4/4 re-run by me, panel offset_top 104.0 in ui/overlay/debug_overlay.tscn line 19) pins the geometry but not the look"
  - name: "Melee enemies chew through a wall to reach a tower, unit or the king (UAT test 13, plan 04-12)"
    requirement: "ENMY-04"
    test: "Play a run on a fresh export with a wall bought in front of a tower (04-21 human-check 2) and watch a night: a grunt whose tower, unit or king is behind a standing wall should attack the segment in front of it until it breaks and then walk on to the target; ranged enemies still shoot over; a grunt in a gap mouth walks through"
    expected: "The rule reads as the owner meant it on 2026-10-19 (melee breaks through to its target; only later enemy types go castle-first), or the owner names a change; the wall-break rebuild hitch stays accepted (UAT test 10)"
    why_human: "The rule is pinned (test_wall_break_to_target 2/2, test_melee_breaks_to_target 10/10, test_los_targets 11/11, test_enemy_wall_flags_contract 5/5, all re-run by me) and the four replays did not move, but whether it looks right in play is the owner's judgement"
  - name: "The owner's re-check packet and fresh export after the view-loop port"
    requirement: "PLAT-01"
    test: "When the gap round has landed: run 04-21's Task 2 (export, 90 s launch, three re-captured screenshots, the dated update at the top of 04-PLAYTEST-GATE.md), then play and re-judge UAT tests 5, 6 and 13 from it (04-21 human-check 2)"
    expected: "A launch-checked build/windows with the DLL next to Duskhold.exe and a packet that names the three re-checks and the native build step"
    why_human: "It is a hand-off to the owner; the artifacts do not exist yet (gap above)"
  - name: "GTX 970 transfer of the dev-machine budget (insufficient_spec, backstop tier; UAT test 12 blocked by hardware)"
    requirement: "PLAT-01"
    test: "If a GTX 970-class machine is ever available, run bash tools/stress.sh --runs=3 --duration=20 on it; otherwise accept the written projection"
    expected: "The RESEARCH A1 projection recorded in 04-FRAME-REPORT.md after the port: p50 8.1 to 10.0 ms and p95 14.2 to 17.5 ms on a GTX 970-class machine (the earlier pre-port projection was 48 to 59 ms p95)"
    why_human: "A backstop-tier truth: no GTX 970 exists here, presence and wiring never qualify, and no wired held-out test can stand in for hardware; I abstain (insufficient_spec). Moot while the dev-machine budget itself is missed"
---

# Phase 4: Crowd-Scale Battles & Walls Verification Report

**Phase Goal:** Nights scale to Thronefall-size battles, with hundreds of units, enemies, and projectiles at 60 fps. Walls and barricades shape enemy paths without gridlock. This lands before any content breadth is added.
**Verified:** 2026-10-20T06:48:56Z
**Status:** gaps_found
**Re-verification:** Yes. This replaces the first verification (2026-10-16T21:04:00Z, `gaps_found`, written at HEAD 1d29358 before the owner's UAT and before the native port). Every number, location and verdict below describes HEAD 0997db1 (the last code commit is b5a6f57; everything after it is planning documents).

## Verdict

The goal is still not fully achieved, and the one clause that fails is narrower and closer than before. Walls and barricades exist, block ground movement, upgrade linearly (30 / 60 / 90 health per segment at 2 / 4 / 6 gold) and shape enemy paths; 300 of 300 enemies cross an 80 m wall through a 4 m gate with zero stuck, no wall hit, 14.93 s median and 21.93 s worst, re-run by me. The native port is real: the enemy store and step, the push-apart, the wall solid test, the flow-field reads and castle routing, the structure index, the wall decision state, the nearest-enemy queries and the stuck tracker all run in a pinned, from-source C++ GDExtension behind unchanged GDScript facades, and all four replays plus the gate stress are byte-identical to goldens that no commit of the phase touched except the one walls golden added in 04-10. But "hundreds of units, enemies, and projectiles at 60 fps" is still not true on the budget the phase set itself. The committed re-measurement (04-FRAME-REPORT.md, `## After the native port`) puts the median-run p95 at **10.95 ms against the unchanged 8.0 ms budget** at 300 enemies, 50 units and 239 or more arrows in view (p50 6.25 ms, about 142 fps; it was p95 37.04 ms, about 43 fps). The simulation step is no longer the cost (2.33 ms headless, was 22 ms); what is left is the per-frame GDScript of the three view layers (arrows about 2.0 ms of mean frame, enemies about 1.1, units about 0.5), and a real-window ablation with those loops off reads p95 4.55 ms. Plan 04-21 halted at its stop rule and nothing was lowered or raised.

Status follows the agent's decision tree as written: criterion 3 FAILED fires rule 1 (`gaps_found`), which takes precedence over the owner re-checks (human_verification, 5 entries) and the one behavior-unverified truth; both lists are kept in full so nothing is lost. The miss is not a defect of the port: the owner decided on 2026-10-20 to run one more gap round that ports the view fills to C++ with the 8.0 ms budget unchanged (STATE.md), and the single gap entry below carries that route, the ablation and the unfinished Task 2 of 04-21. I did not mark PLAT-01 satisfied and REQUIREMENTS.md still reads `PLAT-01 | Phase 4 | Pending`.

Everything else is implemented, wired, tested and replayed: no stubbed artifact, no unwired link (55 of 55), no debt marker, lint clean on 356 files. The two UAT gaps that are not PLAT-01 are closed in code and tests (G-04-6, the overlay below the banner; G-04-7, melee enemies break through to targets behind walls) and wait on the owner's re-judgement.

ROADMAP marks Phase 4 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form (same as Phases 2 and 3), so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD 0997db1 (Godot 4.7.2, Windows, MSVC native build). `git status` was clean before and after; I modified no source, data, tool or test file, started no process I did not stop, killed none and committed nothing.

| Check | Command | Result |
|---|---|---|
| Native build | `bash tools/native_build.sh` | `NATIVE_BUILD_OK platform=windows lib=libduskhold_sim.windows.x86_64.dll godot_cpp=2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec api=4.7.2` (incremental: `ninja: no work to do`; configure ran, compile-command and dumpbin checks passed) |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` |
| Army replay vs golden | `... --scenario=army --twice --expect-file=tests/golden/army.json` | `REPLAY_OK ... ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` |
| Walls replay vs golden | `... --scenario=walls --twice --expect-file=tests/golden/walls.json` | `REPLAY_OK ... ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` |
| full_idle twice | `... --scenario=full_idle --twice` | `REPLAY_OK ... ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (unpinned by design, D-14) |
| Gate stress (criterion 2) | `bash tools/gate_stress.sh --twice` | `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a` |
| Lint and format | `bash tools/lint.sh` | `356 files would be left unchanged`, `Success: no problems found` |
| Golden history | `git log 75183fe..HEAD -- tests/golden` | one commit, e3b8a74 (04-10, adds walls.json); smoke.json and army.json never changed in the phase |
| Pins-first order and immutability | `git log -- <pin test> <native file>` | each pin test or trace fixture is committed before its C++ and is a single commit never edited since: test_separation_pins (0efb1dc before 1306b6e), test_wall_geometry_pins (af9beaa before 23019a6), test_field_route_pins (d333f5b before 0f5a85b), test_target_query_pins (7aba0b0) and test_stuck_pins (5bf16da) before b5a6f57, test_structure_decision_pins (a4308cb before c4c09ba), tests/fixtures/trace/enemy_step_refs.txt (27b82f8 before 8b8a30d) |
| Budget unchanged | read `tools/stress/frame_report.gd` | line 20 `const BUDGET_P95_MS: float = 8.0` |
| No binary committed | `git ls-files` for dll, so, lib, obj and `addons/duskhold_sim` | only the .gdextension and its .uid; nothing binary |
| Native 04-12 flag | read `simulation/defs/enemy_def.gd`, grep of data, fixtures and tools `.tres` | `drops_blocked_targets: bool = false` (line 36); no resource sets it |
| Overlay position | read `ui/overlay/debug_overlay.tscn` | `offset_top = 104.0` (line 19) |
| Facade API caps | grep of public funcs | EnemySystem 19 (17 instance plus two statics; plan 04-20 says 19 of 20), Pathing 20 (the cap) |
| Plan artifacts | `node .../gsd-tools.cjs verify artifacts` on each of the 23 plans | **88 of 92**; the four misses are explained under must_haves (three location or literal facts, one real unmet item) |
| Plan key links | `node .../gsd-tools.cjs verify key-links` on each of the 23 plans | **55 of 55** |
| Debt markers | grep TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER over the 197 non-planning covered files | none |
| Tests (one named suite per call, never the full suite) | `bash tools/test.sh -gselect=<name>` | 33 scripts, all passing: test_native_extension 5, test_native_rules_guard 10, test_separation_pins 10, test_wall_geometry_pins 7, test_field_route_pins 9, test_target_query_pins 7, test_stuck_pins 4, test_native_math_contract 19, test_enemy_store_native 14, test_overlay_banner_layout 4, test_wall_break_to_target 2, test_melee_breaks_to_target 10, test_los_targets 11, test_enemy_wall_flags_contract 5, test_step_attribution 14, test_wall_behaviour 8, test_wall_detour 12, test_wall_decision 12, test_flow_field 9, test_walls_replay_golden 8, test_balance_acceptance 15, test_sim_rules_guard 4, test_stuck_tracker 11, test_gate_stress 10, test_frame_report 11, test_attribution_log 17, test_select_one_type 2, test_enemy_trace 9, test_native_walls 7, test_native_field 13, test_native_structures 14, test_native_separation 6, test_hud_contract 15 |
| Requirements | plan frontmatter `requirements:` vs REQUIREMENTS.md | BLDG-10, ENMY-04, PLAT-01 in both; see Requirements Coverage |

Taken from the orchestrator or the committed evidence without re-running, and marked as such: the full GUT suite at 920674a (211 scripts, 1979 tests, 1978 passing; the one failure, tests/e2e/test_select_one_type.gd, passed 4 of 4 isolated reruns for the orchestrator and 2 of 2 in mine, and is green on CI at b5a6f57); CI run 39310876191 (https://github.com/ABSAR07/duskhold/actions/runs/39310876191, green on b5a6f57 for lint, test, export, screenshots, native-linux GCC and native-windows MSVC, both from source); the regression gate (every Phase 1, 2 and 3 test script named in their VERIFICATION.md files, 9, 14 and 77, ran in the gate); the stress night's three real-window runs and the view-loop ablation (04-21, 04-FRAME-REPORT.md); the bench medians per plan; the screenshot re-captures of 04-13. I did not run the full suite, the stress night, the bench sets, the playtest sweep, the game window, `tools/screenshot.sh`, `tools/export.sh` or a CI build, and I could not run `gh`.

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | The player can build walls and barricades that block enemy movement, upgrade them linearly in health, and use them to funnel enemies into chokepoints | VERIFIED in code and tests; the funnel and tier-readability feel passed the owner at UAT tests 1 and 2 | Wall plots: four on the prototype map (test_prototype_map_walls). Hold-to-build buys a whole run at once (test_wall_system). Health linear by tier: wall.tres cost 2 / 4 / 6, max_health 30 / 60 / 90 (test_wall_data_contract). Blocking: the native WallSolids path for everyone on the ground and the KIND_WALL hit path (test_wall_blocking, test_wall_solids, test_native_walls 7/7, test_wall_behaviour 8/8). Funnel: enemies detour through the 4 m gap (test_wall_detour 12/12) and 300 of 300 cross one gate (GATE_OK, re-run by me). New in the gap round: a default melee enemy breaks the wall in front of a tower, unit or king behind it (test_wall_break_to_target 2/2, test_melee_breaks_to_target 10/10) |
| 2 | Enemies path around walls or break through and never jam; a headless stress test with 200+ enemies through a single gate finishes with zero permanently stuck agents; paths visible in the debug overlay | VERIFIED in code and tests | `GATE_OK enemies=300 crossed=300 stuck=0 ... wall_hits=0` run twice by me on the native library, digest unchanged across the port. Break-or-go-around: test_wall_decision 12/12, test_wall_behaviour 8/8; the stuck tracker is now C++ but pinned first (test_stuck_pins 4/4, test_stuck_tracker 11/11) and still read-only (the contract is in the file header and the tests). Overlay: gizmos added by CrowdOverlaySections and NightOverlaySections; the panel now starts below the banner box (offset_top 104.0; test_overlay_banner_layout 4/4). Legibility of the field is the owner's UAT test 6 (passed on content, failed on the banner overlap, since fixed) and stays a re-check |
| 3 | A scripted stress night with hundreds of units, enemies and projectiles holds 60 fps on GTX 970-class hardware, or within a documented equivalent frame-time budget on the dev machine | **FAILED** (BLOCKER) | 04-FRAME-REPORT.md after the port: median-run p95 **10.95 ms** against the unchanged 8.0 ms (`FrameReport.BUDGET_P95_MS = 8.0`, read by me), p50 6.25 ms, three runs 10.88 / 10.95 / 11.11 ms, `within=false`; D-10 on-screen bar met (300 enemies, 50 units, 239 arrows minimum). The headless step is 2.33 ms (towers 0.49, squads 1.34, enemies 0.48), so the remaining miss is the view layers' per-frame loops (ablation p95 4.55 ms with them off). Before the port: p95 37.04 ms. Owner route recorded; one gap entry in the frontmatter |
| 4 | Nights from Phases 1 to 3 play the same after the switch to batched simulation and rendering; all existing headless loop and combat tests still pass | VERIFIED | smoke (703 ticks, 2599c7c2) and army (1353 ticks, f7a967ed) replay byte-identical to goldens that no commit of the phase touched, now also on the native step and on GCC and MSVC (CI), re-run by me; walls bfb05fc7 (1961 ticks) and full_idle 4385f569 (6911 ticks) unchanged by the entire gap round, as is the gate digest e448ffdb. Phase 3's balance rows reproduce byte-identically (orchestrator). The orchestrator's regression gate ran every Phase 1, 2 and 3 test script named in their VERIFICATION.md files (9, 14 and 77 names; the 78th Phase 3 name, tests/support/sim_signals.gd, is a helper). The only recorded movement in the gap round is 04-12's bot re-measure (balanced seed 2, night 8, one run; outcomes and nights survived unchanged) |

### Plan must_haves

131 plan truths and 33 prohibitions are declared across the 23 plans. I verified them against code, tests and replays rather than against the SUMMARYs.

**04-01 to 04-11 (the first round, carried forward).** 74 of 76 verified in the first verification; nothing since contradicts them, and the gap round moved the code underneath several. Batched rendering (one `CrowdBatch` MultiMesh per archetype, 512 caps, hit-flash, hurt-only bars, death puffs; test_crowd_batch, test_enemy_views, test_unit_views, test_projectile_vfx), the exact-preserving crowd step (test_spatial_index, test_separation_grid; their result now delivered by C++), walls (BLDG-10: test_wall_system, test_wall_dawn, test_wall_blocking, test_prototype_map_walls, test_map_wall_validation, test_wall_data_contract), the Dial flow field, break-or-detour with hysteresis, the stuck tracker, the gate harness and the overlay sections (ENMY-04: test_flow_field, test_wall_decision, test_wall_detour, test_wall_behaviour, test_stuck_tracker, test_gate_stress), the walls golden and the balance sweep (04-10, 04-11). The two exceptions stand: 04-09 truth 4 (median-run p95 at or under 8.0 ms) is **FAILED** and is superseded by 04-21 truth 1 below, and 04-09 truth 5 (GTX 970 transfer) is **insufficient_spec**. 04-09 truth 6 (the lever, then stop and do not raise the budget) holds on the stop rule, as in the first verification. 04-03 truth 5 (step at or under 10.0 ms on the bench, from 50.1 ms) was met at the time and is now far below it (2.3 ms at the stress shape).

**04-12 (G-04-7, ENMY-04), 7 of 7 verified.** The melee rule: `EnemyDef.drops_blocked_targets` defaults false and no `.tres` sets it (read, test_enemy_wall_flags_contract 5/5); the held-for-target memory, the three sub-rules and the release rules (test_melee_breaks_to_target 10/10, test_wall_break_to_target 2/2); the old 04-06 assertions survive on flagged copies (test_los_targets 11/11); ranged enemies and the castle march untouched; the four replays and the gate unchanged (re-run by me).

**04-13 (G-04-6, ENMY-04), 4 of 4 verified; truth 4 on the executor's evidence.** Panel at offset_top 104.0 (read), y-only layout test 4/4 (re-run), HUD nodes untouched (test_hud_contract 15/15 re-run). The re-captured screenshots are the executor's and the owner's to judge (human_verification entry 2).

**04-14, 04-22 (toolchain and guards), 9 of 9 verified.** The pin file, the CMake build with `/fp:precise` or `-ffp-contract=off`, `NATIVE_BUILD_OK` printed by me, `test_native_extension` 5/5 and `test_native_rules_guard` 10/10 (re-run); attribution for godot-cpp (test_attribution_log 17/17); the shared stamp function in tools/_common.sh and the guard in the seven wrappers (my own wrappers refused nothing because the stamp was current; the exit-3 behaviour is the executor's recorded probe with a corrupted stamp); the export check and the boot guard (`presentation/map/map_root.gd` lines 26 to 31 quit with no fallback; review WR-08 says the message may not show, see warnings). **Coincidental reliance flagged** on 04-22's stale-library truth (CR-01).

**04-15, 04-17, 04-18, 04-23, 04-19, 04-20 (the port), 26 of 26 verified.** Every swap is pinned first on the GDScript (single-commit pin files, checked above) and the native code passes them unchanged (test_separation_pins 10/10, test_wall_geometry_pins 7/7, test_field_route_pins 9/9, test_target_query_pins 7/7, test_stuck_pins 4/4, test_structure_decision_pins via the 04-23 suite; test_native_math_contract 19/19 proves the bit-equality of every Vector2 and GDScript utility the port uses; test_enemy_trace 9/9). The whole enemy phase is behind the EnemySystem facade (`var _native: NativeEnemies`, enemy_system.gd line 39; `attack_fired` still emitted from GDScript, line 327, in ascending attacker id), the GDScript bodies are deleted (enemy_system.gd is 329 lines, separation.gd 51, wall_solids.gd 35, target_query.gd 27, structure_index.gd 93; enemy_index.gd is gone), the public API caps hold (EnemySystem 19 of 20, Pathing 20), and the replays, gate and every earlier pin are unchanged. The bench claims (stress-shape step median 39.37 ms before 04-15, 2.18 ms after 04-20, 2.47 ms at 04-21) are the executors' measured numbers; I confirmed their direction through the headless attribution in the report, not by re-running the bench.

**04-16 (CI, owner's option A), 4 of 4 verified on the orchestrator's record.** The workflow builds both libraries from the pinned sources and passes them between jobs by artifact; nothing binary is in git (checked); the owner's choice is recorded in STATE.md; CI run 39310876191 is green on b5a6f57. I did not re-read the whole workflow; I confirmed the `native-linux` and `native-windows` jobs and the `bash tools/native_build.sh --fetch` steps exist.

**04-21 (the re-measurement), truths 2, 3 and 4 verified, truths 1 and 5 FAILED.** Truth 2 (04-FRAME-REPORT.md carries the dated section above the kept 04-09 one, with all runs, counts, attribution, bench medians, the rebuild probe and the GTX 970 projection) and truth 3 (the attribution probe rerun before the real-window runs, PHASE lines quoted) are present in the report. Truth 4 (if still missed, nothing is lowered or raised and the plan halts) holds: budget unchanged, `status: halted`. **Truth 1** (median-run p95 at or under 8.0 ms) is the failed criterion. **Truth 5** (a fresh launch-checked export and a dated update at the top of 04-PLAYTEST-GATE.md for tests 5, 6 and 13) is unmet because Task 2 never ran (the tool miss on 'Update after the gap plans' is real). Both roll into the one gap.

Prohibitions (all judgment-tier; my reading is NON-AUTHORITATIVE and flagged `unverified-prohibition - human review recommended`; none is absorbed into the pass): I found no violation. Reads that cite the tree: no golden regenerated or edited after the walls golden (git log of tests/golden shows e3b8a74 only), the pin files and the trace fixture are single commits never edited, `FrameReport.BUDGET_P95_MS` is still 8.0 and no commit after 04-09's first (2d1248a) touches the stress map, the stress data, stress_night.gd or frame_report.gd, no binary or build directory is committed, no GDScript fallback for a missing library exists (MapRoot quits, the wrappers exit 3), the ranged rule and the castle march were not changed by 04-12 (the replays and test_los_targets on flagged copies hold), the HUD banner nodes are untouched (test_hud_contract 15/15), the stuck tracker still emits nothing (header and tests), and the API caps hold. The process prohibitions (push or gh only in the named task, no system-wide install, no binary route before the owner's choice) are not checkable from the tree; the SUMMARYs and STATE.md say they were followed and I have no contrary evidence.

Decision check against 04-CONTEXT.md and the owner's recorded decisions: D-12 honoured and failed by measurement (budget not raised); D-13 and D-14 honoured by the byte-identical goldens (D-14 confirmed by the owner at UAT test 8); D-10's on-screen bar met; the owner's rule change of 2026-10-19 (UAT test 13) implemented as 04-12; route (3) GDExtension of UAT test 11 implemented as 04-14 to 04-23; option A of 04-16 honoured; the give-up rule of 04-07 stays (UAT test 9); the wall-break rebuild hitch is accepted for now (UAT test 10; the 04-21 bench reads a 10.00 ms mean and 11.74 ms maximum per rebuild, a 17.99 ms break-frame estimate against 16.7 ms).

### Where the first-round GDScript went (a location change, not a missing artifact)

| Function or class (named in 04-01 to 04-11 must_haves) | Now lives in | Facade that kept the API |
|---|---|---|
| `EnemySystem` records, target choice, march, strike, push-apart | `native/src/enemy_step.cpp`, `native/src/native_enemies.cpp` (`NativeEnemies` store) | `simulation/night/enemy_system.gd` (329 lines, 19 public funcs) |
| `EnemyIndex` (04-03) | `native/src/native_enemies.cpp` | file deleted by 04-19 (commit 8b8a30d) |
| `Separation.displacements`, `displacements_bucketed` | `native/src/native_separation.cpp` | `simulation/squads/separation.gd` (static API delegating to `NativeSim`) |
| `WallSolids.first_blocking`, `push_out`, `closest_point`; `WallSystem.segments_near` and its bucket grid | `native/src/native_walls.cpp` | `simulation/walls/wall_solids.gd`, `wall_system.gd` (`native()`) |
| `NavGrid` mirror, `FlowField` reads (`cost_at`, `is_reached`, `direction_at`), `Pathing` castle routing (`is_sealed`, `castle_cost_at`, `detour_ticks`, `march_step`, ...) | `native/src/native_field.cpp` (`NativeGrid`, `NativeField`, `NativeRoute`) | `simulation/nav/nav_grid.gd`, `flow_field.gd`, `pathing.gd` |
| `StructureIndex` scans (`nearest`, `nearest_visible`, `nearest_through_walls`) | `native/src/native_structures.cpp` | `simulation/night/structure_index.gd` |
| `WallDecision` per-tick state | `native/src/native_wall_decision.cpp` | `simulation/nav/wall_decision.gd` |
| `StuckTracker`, `TargetQuery.nearest_enemy` | `native/src/native_stuck.cpp`, `NativeEnemies.nearest_living` | `simulation/nav/stuck_tracker.gd`, `simulation/night/target_query.gd` |
| Record `behind_kind` / `behind_id` (04-12) | `native/src/enemy_step.cpp` lines 366 to 482 | the facade holds no such field |

### Key Link Verification

55 of 55 links from the 23 plans' `key_links` are verified by `gsd-tools verify key-links`. The ones that carry the phase:

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `EnemySystem.step` | `NativeEnemies` and `NativeWalls`, `NativeRoute`, `NativeStructures`, `NativeWallDecision` | the native target-and-walk pass, strikes enqueued and `attack_fired` emitted in GDScript, then the native push-apart pass | WIRED | enemy_system.gd lines 39, 163, 327; enemy_step.cpp calls the wall, route, structure and decision classes directly (04-19) |
| `Separation` / `WallSolids` / `FlowField` / `Pathing` / `StructureIndex` / `WallDecision` / `StuckTracker` / `TargetQuery` | their native classes | static or instance API delegating, GDScript bodies deleted | WIRED | grep in the facades; pins and replays hold |
| `tools/_common.sh` stamp function | `tools/native_build.sh` and the seven wrappers | one shared function writes and checks the stamp | WIRED (see CR-01 for the copy precondition) | 04-22 |
| `ci.yml` jobs | `tools/native_build.sh` | native-linux and native-windows build the library and hand it to test, screenshots and export | WIRED | ci.yml; run 39310876191 green (orchestrator) |
| `EnemyViews` / `UnitViews` / `ProjectileVfx` | `CrowdBatch` per archetype | batches added as children, per-frame GDScript fill in `_process` | WIRED, and the cost owner of the remaining miss | presentation/*; 04-21 ablation |
| `DebugOverlay` panel | the night banner | panel placed below the banner box | WIRED | debug_overlay.tscn line 19 |
| `FrameReport.BUDGET_P95_MS` | `tools/stress.sh` verdict | 8.0 ms, unchanged | WIRED | frame_report.gd line 20 |

### Requirements Coverage

Every ID from the plans' `requirements:` is accounted for against REQUIREMENTS.md (BLDG-10 in 04-04, 04-05, 04-10, 04-11; ENMY-04 in 04-06, 04-07, 04-08, 04-10, 04-11, 04-12, 04-13; PLAT-01 in 04-01, 04-02, 04-03, 04-09, 04-11, 04-14 to 04-23). REQUIREMENTS.md maps no other ID to Phase 4, so none is orphaned.

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| BLDG-10 | 04-04, 04-05, 04-10, 04-11 | Walls and barricades that block enemy movement and upgrade linearly in health | SATISFIED (REQUIREMENTS.md: Complete, lines 41 and 205) | Criterion 1 evidence; UAT test 1 passed with the owner; native wall solids pinned and replayed |
| ENMY-04 | 04-06, 04-07, 04-08, 04-10, 04-11, 04-12, 04-13 | Enemies path around or through defenses without jamming indefinitely | SATISFIED (REQUIREMENTS.md: Complete, lines 74 and 229) | Criterion 2 evidence: GATE_OK 300 of 300, stuck 0, break-or-detour tests, the walls golden, the 04-12 target rule; the owner's re-judgement of tests 6 and 13 is due (human_verification) but does not change the requirement's implementation evidence |
| PLAT-01 | 04-01, 04-02, 04-03, 04-09, 04-11, 04-14 to 04-23 | 60 fps on GTX 970-class hardware during the largest battles | **NOT SATISFIED** (REQUIREMENTS.md: Pending, line 130 unchecked and line 261; I did not change it) | Batched rendering and the native simulation step shipped; the stress-night budget is still missed by measurement (p95 10.95 ms against 8.0 ms, was 37.04). Gap entry in the frontmatter; re-verified on real campaign battles in Phase 13 |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| EnemyViews / UnitViews / ProjectileVfx batches | instance transforms, flash, bar ratio | the simulation's read view (now packed from the native store) and the event bus | yes: the 300-enemy, 50-unit and 239-arrow counts in the frame report are counted from drawn positions in the camera frustum | FLOWING (and the per-frame cost owner, see gap) |
| Debug overlay Walls / Field / Crowd rows | segment counts, field arrows, stuck flags | `WallSystem`, `Pathing.castle_field()`, `StuckTracker` getters (now native-backed) | yes: pinned by test_debug_overlay_crowd_sections against a real night | FLOWING |
| WallViews | segment state, tier look, rubble | `WallSystem` signals recorded in `SimRecorder.HANDLED` | yes: test_wall_views and the walls screenshots | FLOWING |
| Native mirrors (walls, nav grid, field, structures, decision) | segment health, grid costs, unit and building snapshots | kept in step by `WallSystem` (`set_health`), `NavGrid.rebuild` and `StructureIndex.rebuild` | yes: a stale mirror would move the replays and pins, which do not move | FLOWING |

### Behavioral Spot-Checks and Replays

See 'What I ran and read'. The state-transition and ordering truths each have a named passing test I re-ran: a break emits once and a broken segment stays broken until dawn (test_wall_system via the 04-04 round and test_native_walls 7/7), the held-for-target wall is released when the segment breaks, the target dies or leaves the leash, or the centre line stops crossing (test_melee_breaks_to_target 10/10), the decision runs on its own staggered tick (test_wall_decision 12/12), the stuck tracker flags at exactly 90 updates (test_stuck_tracker 11/11), the native step equals the GDScript step tick by tick (test_enemy_trace 9/9 against the committed reference digests, plus the four replays and the gate). The one invariant with no direct test is the give-up rule (`behavior_unverified: 1`).

### Probe Execution

No `probe-*.sh` is declared by the phase plans and none exists under `scripts/`: SKIPPED. The replays, the gate stress and the committed step-attribution probe (`tools/stress/step_attribution.gd`, test_step_attribution 14/14) are the phase's runnable checks; the first two were run.

### Anti-Patterns Found

None. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in the non-planning files the phase changed (197 files, including native/src); no stub artifact. Informational: tools/native_build.sh has no `set -e` and an unchecked library copy (CR-01, below); the stress-night camera at 119.5 m draws the crowd smaller than in play, which the frame report discloses.

## Code-review findings (28 OPEN, 0 FIXED)

04-REVIEW-DISPOSITION.md on disk: `open: 28`, `total: 28`, every row `open`. 04-REVIEW.md: standard depth, 86 files reviewed 2026-10-20, 1 critical, 11 warning, 16 info (the 13 findings of the 2026-10-16 review carried and relocated: WR-01 to WR-07 and IN-01 to IN-06, with WR-02, WR-03 and IN-02 now located in native/src; WR-02 and WR-03 were deliberately ported unchanged). These are committed facts carried here; I did not re-review and did not change any disposition, except that I read CR-01's two lines in the tree and they match the finding.

| ID | Severity | Title | Disposition |
|---|---|---|---|
| CR-01 | critical | A failed library copy leaves a valid-looking stamp, so a stale native library passes every guard and can be exported (tools/native_build.sh line 290; local builds only, CI is from source) | open |
| WR-08 | warning | The 'no native library, no game' guard in `MapRoot._ready` cannot run in the case it guards (the quit still happens, the message may not show) | open |
| WR-09 | warning | `test_native_rules_guard.gd` does not scan for the `std::max/min/clamp` rule `gd_math.h` documents | open |
| WR-10 | warning | `native_build.sh` verifies the godot-cpp commit but not that the checkout is unmodified | open |
| WR-11 | warning | An unbounded loop is reachable from a bound native method | open |
| IN-07 to IN-16 | info | include IN-07 and IN-08, the quantified per-frame costs of the view layer that the next gap round ports | open |
| WR-01 to WR-07, IN-01 to IN-06 | warning / info | the 13 carried findings (gap-width trap, tangency epsilon, outside-grid enemies, tier health validation, stress.sh arithmetic, bot balance acceptance, wall-clock bound in a test, hot-path allocations, bucket cost, view cap 256, nav grid ignores the king radius, key-packing copies, file-handle on partial failure) | open |

None contradicts a verified roadmap truth on the shipped data. CR-01 is the one that matters for the next round (see the gap's last `missing` item). 04-SECURITY.md: `status: verified`, `threats_open: 0`, 63 threats closed at ASVS level 1 (the plan-time register of all 23 plans, read at grep depth, no auditor subagent).

## Human Verification

The structured list in the frontmatter has 5 entries. Tests 1 to 4, 7, 8, 9, 10 and 11 passed with the owner (UAT 2026-10-16 to 2026-10-19) and do not come back unless a code change touched them; the gap round did not change anything those tests judged except through the three below. The entries are, in order: UAT test 5 (the stress night on the native step), UAT test 6 (the overlay below the banner at 720p), UAT test 13 (melee enemies breaking through to their targets), the owner's re-check packet and fresh export after the view-loop port (04-21 Task 2), and the GTX 970 transfer (insufficient_spec). The give-up rule is carried in `behavior_unverified_items`: the owner already passed it at UAT test 9, so it is recorded as evidence quality, not an open question.

## Gaps Summary

One gap blocks the phase goal, and it is the one the orchestrator and the owner already know: ROADMAP criterion 3 / PLAT-01 is not met on the 8.0 ms budget (median-run p95 10.95 ms, about 142 fps at the median, with 300 enemies, 50 units and 239 or more arrows in view; the port took it from 37.04 ms). The remaining cost has moved from the simulation step (2.33 ms headless) to the three view layers' per-frame GDScript loops (about 3.5 ms of mean frame; p95 4.55 ms with them off). The owner's recorded route (2026-10-20) is one more gap round that ports those view fills to C++, pins-first and byte-identical, with the budget unchanged, followed by 04-21's unfinished Task 2 (fresh export, three re-captured screenshots, the dated owner re-check list) and a repeat of the stress measurement. That is what `/gsd-plan-phase 4 --gaps` has to plan; the gap entry carries the numbers and the review findings IN-07 and IN-08 that quantify the loops. Review CR-01 (a stale local native library can pass the stamp guard after a failed copy) should be fixed before or inside that round because the round rebuilds the library repeatedly on a developer machine with Godot processes holding the DLL. Beyond that: 28 code-review findings are open, the owner's re-judgement of UAT tests 5, 6 and 13 is due after the round, and one invariant (the give-up rule) is pinned only by its effect and by the tick-identical enemy traces. If any file in the covered list changes, re-run `verification.status` to refresh the fingerprint.

---

_Verified: 2026-10-20T06:48:56Z_
_Verifier: Claude (gsd-verifier)_
