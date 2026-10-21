---
phase: 04-crowd-scale-battles-walls
verified: 2026-10-20T16:41:25Z
status: passed
score: "4/4 roadmap success criteria verified (criterion 3, PLAT-01, now VERIFIED by the committed real-window measurement: median-run p95 5.37 ms against the unchanged 8.0 ms budget, within=true); 154/155 plan truths verified, 0 failed, 1 insufficient_spec (04-09 GTX 970 transfer, backstop tier); 3/3 requirement IDs have implementation evidence (BLDG-10, ENMY-04, PLAT-01 satisfied); 6 owner-judgement items remain, 0 gaps"
must_haves:
  roadmap_truths: 4
  roadmap_truths_verified: 4
  roadmap_truths_failed: 0
  plan_truths_declared: 155
  plan_truths_declared_note: "76 in plans 04-01 to 04-11, 55 in the twelve gap-closure plans 04-12 to 04-23 (7, 4, 5, 4, 4, 4, 4, 5, 5, 5, 4, 4) and 24 in the five round-2 plans 04-24 to 04-28 (4, 5, 5, 5, 5)"
  plan_truths_verified: 154
  plan_truths_failed: 0
  plan_truths_insufficient_spec: 1
  plan_truths_resolved_since_last_verification: "the three that failed on 2026-10-20T06:48:56Z now hold: 04-09 truth 4 and 04-21 truth 1 (median-run p95 at or under 8.0 ms: 5.37 ms, plan 04-28) and 04-21 truth 5 (fresh launch-checked export and the dated owner update at the top of 04-PLAYTEST-GATE.md: produced by 04-28 Task 2, both read by me)"
  plan_artifacts_checked: "110/113 by gsd-tools verify artifacts over all 28 plans, re-run by me. The three tool misses are location or literal-string facts, none is a stub: 04-03 simulation/night/enemy_index.gd (deleted on purpose by plan 04-19, commit 8b8a30d; the index lives in native/src/native_enemies.cpp behind EnemySystem), 04-10 tests/fixtures/fixture_map_replay_walls.tres pattern WallRunDef (the run is an inline sub_resource through its script path, unchanged), 04-12 simulation/night/enemy_system.gd pattern behind_kind (the held-for-target memory lives in native/src/enemy_step.cpp and native_enemies.cpp, bound as behind_kind_of). The fourth miss of the last report (04-21 'Update after the gap plans') is closed: the heading is now at the top of 04-PLAYTEST-GATE.md. All five round-2 plans pass 21/21 artifacts (04-24 4/4, 04-25 5/5, 04-26 5/5, 04-27 5/5, 04-28 2/2)"
  plan_key_links_checked: "68/69 by gsd-tools verify key-links over all 28 plans, re-run by me; the five round-2 plans pass 14/14 (3, 3, 3, 3, 2). The one miss is 04-01 presentation/enemies/enemy_views.gd to presentation/crowd/crowd_batch.gd, pattern '\\.commit\\(' not found: since plan 04-26 EnemyViews calls CrowdBatch.commit_buffer (enemy_views.gd lines 146 and 147), which calls commit() inside crowd_batch.gd (lines 138 to 145). The link holds through the new entry point; the plan's literal pattern is stale"
  prohibitions_declared: 50
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass. 20 in plans 04-01 to 04-11, 13 in plans 04-12 to 04-23, 17 in plans 04-24 to 04-28 (3, 4, 4, 3, 3). My reading found no violation; the process prohibitions (no push or gh outside the named task, no system-wide install) cannot be verified from the tree and are taken from the SUMMARYs and the CI record. Details in the Plan must_haves section"
  requirement_ids: 3
  requirement_ids_satisfied: 3
  requirement_ids_failed: 0
  requirement_ids_orphaned: 0
re_verification:
  previous_status: gaps_found
  previous_score: "3/4 roadmap success criteria; 127/131 plan truths (3 failed, 1 insufficient_spec); PLAT-01 failed at median-run p95 10.95 ms (verified 2026-10-20T06:48:56Z at HEAD 0997db1, before the view-layer port)"
  gaps_closed:
    - "ROADMAP criterion 3 / PLAT-01 (G-04-5): median-run p95 10.95 ms to 5.37 ms against the unchanged 8.0 ms budget (p50 6.25 to 3.70 ms, about 142 to about 256 fps), by porting the per-frame view fills of the arrows, enemies and death puffs, and units to C++ (plans 04-25 to 04-27) and re-measuring in a real window (plan 04-28); the committed view ablation reads 0.22 ms for all three loops off against 3.80 ms before the round"
    - "04-21 Task 2 (fresh launch-checked export, three re-captured screenshots, dated owner update for UAT tests 5, 6 and 13): produced by plan 04-28 Task 2"
    - "Review CR-01 (a failed library copy left a valid-looking stamp): fixed by plan 04-24 (commit 9ccc0d7), verified by the reviewer and by my read of tools/native_build.sh and tools/_common.sh and my run of tools/native_stamp_probe.sh (7 of 7 cases)"
  gaps_remaining: []
  regressions: []
  owner_items_closed_by_code: "UAT G-04-6 (overlay below the banner, 04-13) and G-04-7 (melee enemies break through to targets, 04-12) were closed in code and tests in the first gap round; the owner's re-judgement of both, and of the stress night (G-04-5) after this round, is still due (human_verification)"
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
  - .planning/phases/04-crowd-scale-battles-walls/04-24-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-24-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-25-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-25-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-26-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-26-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-27-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-27-SUMMARY.md
  - .planning/phases/04-crowd-scale-battles-walls/04-28-PLAN.md
  - .planning/phases/04-crowd-scale-battles-walls/04-28-SUMMARY.md
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
  - .planning/phases/04-crowd-scale-battles-walls/COVERAGE.md
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
  - native/src/native_arrows.cpp
  - native/src/native_arrows.h
  - native/src/native_enemies.cpp
  - native/src/native_enemies.h
  - native/src/native_enemy_views.cpp
  - native/src/native_enemy_views.h
  - native/src/native_field.cpp
  - native/src/native_field.h
  - native/src/native_mirror.h
  - native/src/native_puffs.cpp
  - native/src/native_puffs.h
  - native/src/native_separation.cpp
  - native/src/native_separation.h
  - native/src/native_sim.cpp
  - native/src/native_sim.h
  - native/src/native_structures.cpp
  - native/src/native_structures.h
  - native/src/native_stuck.cpp
  - native/src/native_stuck.h
  - native/src/native_unit_views.cpp
  - native/src/native_unit_views.h
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
  - simulation/squads/unit_read_view.gd
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
  - tests/unit/test_enemy_fill_pins.gd
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
  - tests/unit/test_native_arrows.gd
  - tests/unit/test_native_enemy_views.gd
  - tests/unit/test_native_extension.gd
  - tests/unit/test_native_field.gd
  - tests/unit/test_native_math_contract.gd
  - tests/unit/test_native_rules_guard.gd
  - tests/unit/test_native_separation.gd
  - tests/unit/test_native_structures.gd
  - tests/unit/test_native_unit_views.gd
  - tests/unit/test_native_view_math_contract.gd
  - tests/unit/test_native_walls.gd
  - tests/unit/test_nav_grid.gd
  - tests/unit/test_nav_tuning_contract.gd
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_projectile_fill_pins.gd
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
  - tests/unit/test_unit_fill_pins.gd
  - tests/unit/test_unit_read_view.gd
  - tests/unit/test_view_ablation.gd
  - tests/unit/test_view_fill_bench_args.gd
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
  - tools/native_stamp_probe.sh
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
  - tools/stress/view_ablation.gd
  - tools/stress/view_fill_bench.gd
  - tools/test.sh
  - ui/overlay/crowd_overlay_sections.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay.tscn
  - ui/overlay/night_overlay_sections.gd
  - ui/world/spot_label_model.gd
covered_digest: "v2:sha256:a8d23d51a77eaf44cd79aaa2d04f82fdadf38b63e1da2ad0ffcc8bf8c9d495ac"
behavior_unverified: 1
overrides_applied: 0
gaps: []
deferred:
  - truth: "Night readability under hundreds of units (individual enemies are small from the stress camera; the palisade is low contrast against the dark night ground; tier I and II palisades look alike from the riding camera)"
    addressed_in: "Phase 8"
    evidence: "ROADMAP Phase 8 'Art, Readability & Sound' goal: 'nights that stay readable in big battles'; UI-05 maps to Phase 8 (Pending). 04-PLAYTEST-GATE.md assumption 25 records it as observed and left for that pass; the owner signed the looks off at UAT test 13. Informational: no Phase 4 roadmap criterion depends on it"
advisory: []
warnings:
  - id: "REQUIREMENTS.md still shows BLDG-10 and ENMY-04 unchecked and 'Gaps Found'; only PLAT-01 was marked Complete by 04-28"
    where: ".planning/REQUIREMENTS.md lines 41 and 74 (checkbox `[ ]`) and lines 205 and 229 (traceability 'Gaps Found'); line 130 and line 261 read PLAT-01 Complete"
    issue: "Commit c962bb7 ('revert premature Complete requirements after gaps found') put the two back after the last verification, and 04-28 changed only PLAT-01. The implementation evidence for both is complete (criteria 1 and 2, below), so this is bookkeeping, not a code gap. I did not edit REQUIREMENTS.md (verifier role)"
    decision_requested: "Mark BLDG-10 and ENMY-04 Complete when the phase is closed (phase.complete), after the owner's /gsd-verify-work 4"
  - id: "Code review: 33 of 36 findings open (0 critical, 13 warning, 20 info); CR-01, IN-07 and IN-08 fixed"
    where: "04-REVIEW.md (standard depth, reviewed 2026-10-20T16:16:53Z, 50 files with .uid siblings), 04-REVIEW-DISPOSITION.md (open 33, fixed 3)"
    issue: "Facts carried, not re-reviewed by me. New this round: WR-12 (the stamp's source half is taken at install time, not at build start), WR-13 (tools/native_stamp_probe.sh is run by nothing: I grepped .github, tools/*.sh and tests, no caller; the probe itself passes 7 of 7 by hand) and IN-17 to IN-22 (raw CR and newline bytes inside quoted strings in tools/_common.sh, small native-view items). None contradicts a verified truth. WR-08 (the MapRoot missing-library message may never show) and the other carried findings are unchanged"
    decision_requested: "The review-fix loop (/gsd-code-review 4 --fix --all) per the owner's recorded process; not a verification gap"
  - id: "The 5.37 ms p95, the view-ablation numbers, the view bench medians, CI run 39445109146, the export launch and the screenshot passes were taken from the committed evidence, not re-run by me"
    where: "04-FRAME-REPORT.md section 'After the view-layer port', 04-28-SUMMARY.md, CI run 39445109146 (green on e0ecde0 for lint, native-linux GCC, native-windows MSVC, test 2076 of 2076, screenshots, export)"
    issue: "By the brief I ran no real-window tool, no bench set, no CI build and no full suite. My independent evidence for criterion 3 is structural and byte-level: the budget constant (tools/stress/frame_report.gd line 20, 8.0), the stress map, data and tools untouched since 04-09's first commit (git log empty), the three view-fill pins and the four replays byte-identical on the library I built, the four native view classes registered and called from every per-frame view, no GDScript loop left in them, and the report and packet read in full. Everything after e0ecde0 changes .planning/ only (git diff 9282d64 HEAD outside .planning is empty)"
    decision_requested: "None; the owner's own run (UAT test 5) is the independent confirmation"
  - id: "The overlay_field_gate capture shows the panel stale next to a drawn crowd"
    where: "screenshots/overlay_field_gate.png (git-ignored, re-captured by 04-28)"
    issue: "Read by me: the banner reads whole above the panel (the test 6 fix holds), but the panel's own text says Phase DAY, Enemies 0, Drawn enemies 0 while purple enemies are drawn at the lower left. The panel refreshes every 0.25 s of real time (REFRESH_INTERVAL_S, debug_overlay.gd line 9, untouched this round) and the capture harness fast-forwards the night, so I read it as a harness timing artefact, not a defect; I did not prove it. test_debug_overlay_night_sections and test_debug_overlay_crowd_sections pin the readouts against a real night"
    decision_requested: "Owner to glance at a live F3 panel at night in UAT test 6; no action otherwise"
  - id: "Bots buy walls only late; 0 segments were broken in the whole balance sweep (carried)"
    where: "04-BALANCE-REPORT.md, review WR-06"
    issue: "D-15's neutral-balance result says walls do not break the Phase 2 bar when bought late; it says nothing about mid-game walls. The owner passed UAT test 7 (nights still tense) and test 1"
    decision_requested: "None"
  - id: "gsd-tools artifact and key-link misses (tooling and sequencing, informational)"
    where: "04-03 (enemy_index.gd), 04-10 (WallRunDef), 04-12 (behind_kind), 04-01 key link ('.commit(' now commit_buffer)"
    issue: "See plan_artifacts_checked and plan_key_links_checked: all four are location or literal-string facts after the native ports"
    decision_requested: "None"
behavior_unverified_items:
  - truth: "04-07 deviation, ported to C++ by 04-19: an enemy that gives up on a segment never takes that same segment again while a way round exists (the wall_given_up flag in native/src/enemy_step.cpp)"
    test: "Run a night with a long weak wall and a crowd near the break-even; watch an individual enemy that walks away from a segment while its neighbours keep hitting it"
    expected: "It never turns back to the same segment while the gap is still reachable; it still breaks in when sealed (the detour is MAX_TICKS)"
    why_human: "No test names wall_given_up or pins this per-enemy invariant (grep over tests/ is empty, re-checked today); it is exercised only through its effect (test_nobody_flips_between_breaking_and_walking_round_more_than_twice, test_wall_behaviour) and, since 04-19, through the five committed enemy-trace digests that keep the port tick-identical to the GDScript step. The owner passed UAT test 9 on 2026-10-19 (the rule stays), so this is carried as evidence quality, not an open owner question"
coincidental_reliance_items:
  - truth: "04-22 and 04-24: a stale native library is a hard, named error in every wrapper (the stamp binds the library bytes and the source hash)"
    reason: undeclared-precondition
    harden: "CR-01 is fixed (the stamp is removed before the copy, the copy is checked, the library's sha256 is the stamp's second line and the guard recomputes it), so the byte half no longer relies on an unchecked cp. What is left is review WR-12: the source half of the stamp is computed at install time, so a source edit made while a build runs yields a library stamped as current. Declare the precondition (no source edit during a build) or take the source half at build start, and run tools/native_stamp_probe.sh from a test or CI step (WR-13) so the guard's proof does not depend on someone remembering it"
human_verification:
  - name: "The stress night feels smooth and the crowd reads, now on the native step (UAT test 5)"
    requirement: "PLAT-01"
    test: "After bash tools/native_build.sh in Git Bash, run the stress night from the editor binary in PowerShell: & \".\\.tools\\godot\\4.7.2-stable\\Godot_v4.7.2-stable_win64.exe\" --path . res://tools/stress/stress_night.tscn -- --duration=30 (04-28 human-check 2; the step AND the arrows, enemies, bars, puffs and units are native now)"
    expected: "300 enemies, 50 footmen, 20 towers and the arrows are legible as a crowd and the frame time feels smooth, or the owner says where it still hurts. Claude measured about 256 fps at the median and a 5.37 ms p95 against the 8.0 ms budget (it was 142 fps and 10.95 ms before the view port)"
    why_human: "Smoothness and crowd legibility are perceptual; the measurement is committed and is the closed gap, how it feels on the owner's machine is the owner's call"
  - name: "The debug overlay sits below the night banner at 720p (UAT test 6, plan 04-13)"
    requirement: "ENMY-04"
    test: "Press F3 on a night (the stress night or a prototype night with walls) in a 1280x720-based window and read the night banner ('Night 8 of 8 - 300 enemies left'), the fast-forward label and the last overlay row; look at the re-captured shots overlay_on, overlay_paths and overlay_field_gate (re-taken by 04-28) and the CI Linux fallback-font overlay_field_gate.png"
    expected: "The banner reads whole above the panel, nothing that matters is hidden, the last row is on screen, and overlay_paths shows a night. In a live window the panel's Phase, Enemies and Drawn rows follow the night (see the stale-panel note in warnings)"
    why_human: "Layout adequacy and legibility are by eye; the y-only layout test (test_overlay_banner_layout 4/4 re-run by me, panel offset_top 104.0 in ui/overlay/debug_overlay.tscn line 19) pins the geometry but not the look"
  - name: "Melee enemies chew through a wall to reach a tower, unit or the king (UAT test 13, plan 04-12)"
    requirement: "ENMY-04"
    test: "Play a run on build/windows/Duskhold.exe with a wall bought in front of a tower (04-28 human-check 1) and watch a night: a grunt whose tower, unit or king is behind a standing wall should attack the segment in front of it until it breaks and then walk on to the target; ranged enemies still shoot over; a grunt in a gap mouth walks through"
    expected: "The rule reads as the owner meant it on 2026-10-19 (melee breaks through to its target; only later enemy types go castle-first), or the owner names a change; the wall-break rebuild hitch stays accepted (UAT test 10, 11.61 ms mean per rebuild after this round)"
    why_human: "The rule is pinned (test_wall_break_to_target, test_melee_breaks_to_target, test_los_targets, test_enemy_wall_flags_contract) and the four replays did not move, but whether it looks right in play is the owner's judgement"
  - name: "The owner's re-check packet and fresh export after the view-loop port"
    requirement: "PLAT-01"
    test: "Open the dated update at the top of 04-PLAYTEST-GATE.md ('Update after the gap plans 04-12 to 04-28 (2026-10-20T15:51Z)') and launch build/windows/Duskhold.exe (exported 2026-10-20 at HEAD a482e3f, with libduskhold_sim.windows.x86_64.dll and Duskhold.pck beside it; the executor's launch check exited 0 in about 4 s)"
    expected: "The build launches and plays a full run, the packet names UAT tests 5, 6 and 13 and the native build step, and the numbers it quotes (p95 5.37 ms, 256 fps) match 04-FRAME-REPORT.md"
    why_human: "It is a hand-off to the owner; the packet and the export exist (read and listed by me) but the owner's own launch on the owner's machine is the check, and the export launch itself was not re-run by me"
  - name: "GTX 970 transfer of the dev-machine budget (insufficient_spec, backstop tier; UAT test 12 blocked by hardware)"
    requirement: "PLAT-01"
    test: "If a GTX 970-class machine is ever available, run bash tools/stress.sh --runs=3 --duration=20 on it; otherwise accept the written projection"
    expected: "The RESEARCH A1 projection recorded in 04-FRAME-REPORT.md after the view-layer port: p50 about 4.8 to 5.9 ms and p95 about 7.0 to 8.6 ms on a GTX 970-class machine (the pre-port projections were 14.2 to 17.5 ms and 48 to 59 ms at the p95); PLAT-01 is re-verified on real campaign battles in Phase 13 whatever this reads"
    why_human: "A backstop-tier truth: no GTX 970 exists here, presence and wiring never qualify, and no wired held-out test can stand in for hardware; I abstain (insufficient_spec)"
  - name: "The view-layer port draws the night as before (by-eye screenshot comparison)"
    requirement: "PLAT-01"
    test: "Compare the arrows, the enemy crowd with its hit flashes and hurt-only bars, the death puffs and the friendly units and their bars in a night on the exported build (or the crowd_stress_night and walls_night_breach captures) with what the owner saw at UAT tests 5 and 13; the coverage items with human_judgment true in the SUMMARYs of 04-25, 04-26 and 04-27 record the executors' own comparison"
    expected: "Nothing is missing, doubled, recoloured, mis-sized or popping; the arrows arc from the tower to the target as before; flashes last 0.15 s; puffs fade over 0.6 s; bars show only on hurt enemies and units"
    why_human: "The view fills are pinned byte-for-byte on the batch mirrors (test_projectile_fill_pins 4/4, test_enemy_fill_pins 5/5, test_unit_fill_pins 4/4, SHA-256 over the instance buffers, computed on the GDScript before any native code, never edited) and the goldens did not move, so any difference could only be in how the buffer is drawn, which only an eye can judge. I read crowd_stress_night.png and overlay_field_gate.png and saw the purple crowd, pink flashes, red hurt-only bars, yellow arrows and blue units as described"
---

**Canonicalization note (2026-10-21).** `status` was set from `human_needed` to `passed` by /gsd-verify-work 4 after the UAT session closed (04-UAT.md complete: 17 of 19 tests passed, 0 issues, 2 deferred follow-ups; the six human items of this report are UAT tests 14 to 19: 15, 17 and 19 self-verified by the orchestrator with evidence, 14 and 16 passed by the owner on the numbers and the pinned rule, 18 deferred to Phase 13 with test 12; the round-1 issue rows 5, 6 and 13 were superseded with the owner's approval). No source, data or test file changed after this report was written (`git diff ca81c03 HEAD -- . ':!.planning/'` is empty); the covered document that changed is 04-UAT.md (results), so `covered_digest` was recomputed over the same 289 paths.

# Phase 4: Crowd-Scale Battles & Walls Verification Report

**Phase Goal:** Nights scale to Thronefall-size battles, with hundreds of units, enemies, and projectiles at 60 fps. Walls and barricades shape enemy paths without gridlock. This lands before any content breadth is added.
**Verified:** 2026-10-20T16:41:25Z
**Status:** human_needed
**Re-verification:** Yes. This replaces the second verification (2026-10-20T06:48:56Z, `gaps_found`, written at HEAD 0997db1, before the view-layer port). Every number, location and verdict below describes HEAD ca81c03 (the last code commit is e0ecde0, plan 04-27; everything after it is planning documents).

## Verdict

The phase goal is achieved in the codebase and by the committed measurement, and what remains is the owner's judgement. Walls and barricades exist, block ground movement, upgrade linearly (30 / 60 / 90 health per segment at 2 / 4 / 6 gold) and shape enemy paths; 300 of 300 enemies cross an 80 m wall through a 4 m gate with zero stuck and no wall hit (14.93 s median, 21.93 s worst), re-run by me twice. The simulation runs in a pinned, from-source C++ GDExtension behind unchanged GDScript facades, and since this round the three per-frame view layers (arrows, enemies with their bars and death puffs, units with their bars) run there too: `NativeArrows`, `NativeEnemyViews`, `NativePuffs` and `NativeUnitViews` are registered (register_types.cpp lines 36 to 39), each view calls its native `fill` once per frame and commits the filled mirror through `CrowdBatch.commit_buffer`, and the GDScript per-instance loops are deleted (enemy_views.gd 253 lines, unit_views.gd 278, projectile_vfx.gd 330, none with a loop over instances). All four replays and the gate stress are byte-identical to goldens that no commit of the phase touched except the one walls golden added in 04-10, which is the evidence that the views only read.

**Criterion 3 (PLAT-01) is now VERIFIED.** The committed real-window re-measurement (04-FRAME-REPORT.md, `## After the view-layer port`, plan 04-28, 2026-10-20) reads `FRAME_REPORT_OK runs=3 median_run=2 p95_ms=5.37 budget_ms=8.0 within=true enemies=300 units=50 arrows=237` (runs 5.00 / 5.37 / 5.56 ms; median-run p50 3.70 ms, about 256 fps; before the view port 10.95 ms at 04-21 and 37.04 ms at 04-09), with the D-10 on-screen bar met in full (300 enemies, 50 units, 237 or more arrows in view). The committed view ablation after the port saves 0.09 / 0.02 / 0.10 ms for enemy views, unit views and projectile VFX (all three off 0.22 ms), against 1.32 / 0.42 / 2.13 (3.80 ms) before it. I did not reproduce the number (the brief forbids a real-window run); I verified what makes it true and what could falsify it: `FrameReport.BUDGET_P95_MS` is still 8.0, the stress map, its data, `stress_night.gd`, `frame_report.gd` and the CLI have no commit after plan 04-09's first one (git log empty), the draw caps are unchanged (MAX_PROJECTILES 512, MAX_SLASHES 8, MAX_VIEWS 512 for enemies and 256 for units, MAX_PUFFS 128), and the three view-fill pins pass on the library I built. PLAT-01 stays re-verified on real campaign battles in Phase 13.

Status follows the agent's decision tree: no truth FAILED, no artifact missing or stubbed, no key link unwired, no blocker anti-pattern (rule 1 does not fire). Step 8 produced six owner-judgement items (the stress night by feel, the overlay at 720p, melee breakthrough, the packet and export, the GTX 970 projection, the by-eye look of the view port), so rule 2 fires: `human_needed`, 0 gaps. The give-up-rule invariant stays in `behavior_unverified_items` (the owner passed it at UAT test 9).

ROADMAP marks Phase 4 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form (same as Phases 2 and 3), so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD ca81c03 (Godot 4.7.2, Windows, MSVC native build). `git status` was clean before and after; I modified no source, data, tool or test file, started no real-window process and committed nothing.

| Check | Command | Result |
|---|---|---|
| Native build | `bash tools/native_build.sh` | `NATIVE_BUILD_OK platform=windows lib=libduskhold_sim.windows.x86_64.dll godot_cpp=2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec api=4.7.2` (incremental: `ninja: no work to do`; the compile-command and dumpbin checks passed; the `vswhere.exe` line on stderr is the script's own probe and is harmless) |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` |
| Army replay vs golden | `... --scenario=army --twice --expect-file=tests/golden/army.json` | `REPLAY_OK ... ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` |
| Walls replay vs golden | `... --scenario=walls --twice --expect-file=tests/golden/walls.json` | `REPLAY_OK ... ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` |
| full_idle twice | `... --scenario=full_idle --twice` | `REPLAY_OK ... ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (unpinned by design, D-14; unchanged since its one regeneration commit 94fff12) |
| Gate stress (criterion 2) | `bash tools/gate_stress.sh --twice` | `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a` |
| Lint and format | `bash tools/lint.sh` | `369 files would be left unchanged`, `Success: no problems found` |
| Stamp guard probe (CR-01) | `bash tools/native_stamp_probe.sh` | `NATIVE_STAMP_PROBE_OK cases=7` (install_missing_source, install_ok, changed_library, swapped_library, one_line_stamp, missing_library, missing_stamp, each `ok`); hermetic, no Godot process |
| View-fill pins (G-04-5, byte identity) | `bash tools/test.sh -gselect=<name>` | test_projectile_fill_pins 4/4 (17 asserts), test_enemy_fill_pins 5/5 (30), test_unit_fill_pins 4/4 (20) |
| Native rules guard | `-gselect=test_native_rules_guard` | 10/10 (118 asserts) |
| Round-2 suites | `-gselect=<name>` one per call | test_native_view_math_contract 11, test_native_arrows 15, test_native_enemy_views 18, test_native_unit_views 14, test_unit_read_view 9, test_view_ablation 5, test_view_fill_bench_args 8, test_crowd_batch 13, test_projectile_vfx 10, test_enemy_views 12, test_unit_views 5, test_death_puff_batch 5, test_sim_rules_guard 4, test_native_extension 5, test_frame_report 11, test_stress_map_data 16, test_native_structures 14, test_hud_contract 15, test_overlay_banner_layout 4: all passing, 0 failing |
| Plan artifacts | `node .../gsd-tools.cjs verify artifacts` on each of the 28 plans | **110 of 113**; the three misses are location or literal-string facts (see must_haves) |
| Plan key links | `node .../gsd-tools.cjs verify key-links` on each of the 28 plans | **68 of 69**; the one miss is the 04-01 `.commit(` pattern, now `commit_buffer` |
| Golden history | `git log 75183fe..HEAD -- tests/golden` | one commit, e3b8a74 (04-10, adds walls.json); smoke.json and army.json never changed in the phase |
| Pins-first order and immutability | `git log -- <pin test>` and the commit order of the round | test_projectile_fill_pins (5c78be5, then the native code af0a80b), test_enemy_fill_pins (b7f29f6 before b27e082 and d521b38), test_unit_fill_pins (e3a5b4a before c681c79 and e0ecde0): one commit each, never edited. Earlier pin files unchanged from the last report |
| Budget and stress tools unchanged | read `tools/stress/frame_report.gd`; `git log 2d1248a..HEAD -- tools/stress/stress_map.tres tools/stress/data tools/stress/stress_night.gd tools/stress/stress_night.tscn tools/stress/frame_report.gd tools/stress/frame_report_cli.gd` | line 20 `const BUDGET_P95_MS: float = 8.0`; the log is empty |
| Caps and rules unchanged | grep of the constants | MAX_PROJECTILES 512, MAX_SLASHES 8, MAX_VIEWS 512 (enemies) and 256 (units), MAX_PUFFS 128 |
| Code changed since the last verification | `git diff --name-status 0997db1 HEAD -- . ':!.planning'` | 40 files: ci.yml, gd_math.h, native_sim, register_types, the four view classes plus native_mirror.h (new), crowd_batch, the four views, unit_system and the new unit_read_view, the new pins and native tests, native_build.sh, _common.sh, native_stamp_probe.sh, view_fill_bench.gd and view_ablation.gd; no golden, no stress tool, no rule file, no other test edited |
| Native view classes read nothing impure | grep of the four view `.cpp` files and `native_mirror.h` for Time, Engine, OS, randi, randf, get_singleton | no match; the one `std::min` (native_enemy_views.cpp line 202) is on `int64_t`, not on a float |
| No binary committed | carried from the last report; `git ls-files` for dll, so, lib | only the .gdextension and its .uid |
| Debt markers | grep TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER over the code files changed since 0997db1 | none |
| Export on disk | `ls -la build/windows` | Duskhold.exe, Duskhold.pck, libduskhold_sim.windows.x86_64.dll, all dated 2026-10-20 15:49Z (not launched by me) |
| Requirements | plan frontmatter `requirements:` vs REQUIREMENTS.md | BLDG-10, ENMY-04, PLAT-01 in both; see Requirements Coverage and the first warning |

Taken from the orchestrator or the committed evidence without re-running, and marked as such: the full GUT suite at 9282d64 (221 scripts, 2076 tests, 54,978 asserts, exit 0, lint clean on 369 files; 04-28 and everything after it changed only `.planning/`); CI run 39445109146 (https://github.com/ABSAR07/duskhold/actions/runs/39445109146, green on e0ecde0 for lint, native-linux GCC, native-windows MSVC, test 2076 of 2076, screenshots and export); the regression gate (all 99 Phase 1, 2 and 3 test scripts named in their VERIFICATION.md files ran green); the stress night's three real-window runs, the view ablation, the step attribution and the bench sets (04-24 to 04-28); the screenshot re-captures. I did not run the full suite, the stress night, the bench sets, the ablation, the playtest sweep, a game window, `tools/screenshot.sh`, `tools/export.sh` or a CI build, and I could not run `gh`.

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | The player can build walls and barricades that block enemy movement, upgrade them linearly in health, and use them to funnel enemies into chokepoints | VERIFIED in code and tests; the funnel and tier-readability feel passed the owner at UAT tests 1 and 2 | Unchanged by the round: four wall plots on the prototype map; hold-to-build buys a whole run at once; health linear by tier (wall.tres cost 2 / 4 / 6, max_health 30 / 60 / 90, test_wall_data_contract); blocking through the native wall solids path and the KIND_WALL hit path; funnel through the 4 m gap and 300 of 300 across one gate (GATE_OK, re-run by me); a default melee enemy breaks the wall in front of a tower, unit or king behind it (04-12) |
| 2 | Enemies path around walls or break through and never jam; a headless stress test with 200+ enemies through a single gate finishes with zero permanently stuck agents; paths visible in the debug overlay | VERIFIED in code and tests | `GATE_OK enemies=300 crossed=300 stuck=0 ... wall_hits=0` twice by me, digest e448ffdb unchanged across both native rounds. Break-or-go-around and the stuck tracker are native and pinned first (test_stuck_pins, test_stuck_tracker; test_wall_decision, test_wall_behaviour from the last verification, nothing under them changed). Overlay: panel offset_top 104.0 below the banner (test_overlay_banner_layout 4/4); its look stays a re-check |
| 3 | A scripted stress night with hundreds of units, enemies and projectiles holds 60 fps on GTX 970-class hardware, or within a documented equivalent frame-time budget on the dev machine | **VERIFIED** on the dev machine (the GTX 970 transfer stays a projection, insufficient_spec) | `FRAME_REPORT_OK runs=3 median_run=2 p95_ms=5.37 budget_ms=8.0 within=true enemies=300 units=50 arrows=237` (04-FRAME-REPORT.md, plan 04-28; runs 5.00 / 5.37 / 5.56, p50 3.70 ms, about 256 fps; one frame over 16.7 ms per run), budget `FrameReport.BUDGET_P95_MS` still 8.0 (read by me), stress map and load untouched (git log empty), view fills native and wired (below), view pins and goldens byte-identical (run by me). Before: 10.95 ms (04-21), 37.04 ms (04-09). The measurement is the executor's and the orchestrator's (not reproduced here by instruction); UAT test 5 is the owner's confirmation |
| 4 | Nights from Phases 1 to 3 play the same after the switch to batched simulation and rendering; all existing headless loop and combat tests still pass | VERIFIED | smoke (703 ticks, 2599c7c2), army (1353, f7a967ed), walls (1961, bfb05fc7) and full_idle (6911, 4385f569) replay byte-identical on the native step and the native views (run by me), also on GCC and MSVC in CI (orchestrator); gate digest e448ffdb unchanged; the full suite is green at 9282d64 (2076 of 2076) and the regression gate ran every Phase 1, 2 and 3 test script named in their VERIFICATION.md files |

### Plan must_haves

155 plan truths and 50 prohibitions are declared across the 28 plans. I verified them against code, tests and replays rather than against the SUMMARYs.

**04-01 to 04-23 (carried forward from the last verification).** 127 of 131 then (3 failed, 1 insufficient_spec). Nothing in the round touched their subject code except the view layer's per-frame fills, whose public hooks, constants and event handlers the round kept (test_enemy_views 12/12, test_unit_views 5/5, test_projectile_vfx 10/10, test_crowd_batch 13/13, test_death_puff_batch 5/5 re-run by me). The three that failed now hold: **04-09 truth 4 and 04-21 truth 1** (median-run p95 at or under 8.0 ms, the budget not raised) are met by 04-28's measurement, 5.37 ms, `within=true`; **04-21 truth 5** (a fresh launch-checked export and a dated update at the top of 04-PLAYTEST-GATE.md for tests 5, 6 and 13) was produced by 04-28 Task 2: I read the update (heading 'Update after the gap plans 04-12 to 04-28 (2026-10-20T15:51Z)', it names the three re-checks, the native build step and the verdict line) and listed the export. 04-21's other truths (the report section, the attribution rerun, stop-without-lowering) hold as before and the plan's own status was resolved by the owner's route. 04-09 truth 5 (GTX 970 transfer) stays **insufficient_spec**. 04-22's coincidental-reliance item is narrowed (CR-01 fixed; WR-12 remains), see frontmatter. The two earlier halts (04-09, 04-21) carry `halt_resolution` lines.

**04-24 (CR-01 and the round's instruments), 4 of 4 verified.** (1) `tools/native_build.sh` ends with `duskhold_native_install "${BUILD_DIR}/out/${LIB_NAME}" "${OUT_DIR}" "${PLATFORM}" || exit 1` (line 294), prints `NATIVE_BUILD_FAIL` on failure, and `duskhold_native_install` (tools/_common.sh line 102) removes the stamp first, checks the copy and writes the two-line stamp that `duskhold_native_stamp_for` (line 86) and `duskhold_require_native` (line 126) recompute; (2) the probe prints `NATIVE_STAMP_PROBE_OK cases=7` (run by me); the executor's real-tree case (a DLL with one byte appended makes replay exit 3, the restored one passes) is from the SUMMARY; (3) `tools/stress/view_fill_bench.gd` and `view_ablation.gd` exist and their argument parsing is pinned (test_view_fill_bench_args 8/8, test_view_ablation 5/5), the baseline (3.80 ms) is in 04-24-SUMMARY.md and was quoted by 04-28; (4) nothing the round is measured against moved (replays, gate, budget, stress tools, run by me or read).

**04-25 (arrows), 5 of 5 verified.** (1) test_projectile_fill_pins 4/4 on the native fill, the pin computed on the GDScript flight in its own earlier commit; (2) the 3.0x gain rule: 2280.07 us to 74.44 us, 30.6 times, 04-25's executor measurement, re-measured at 57.44 us by 04-28 (not re-run by me); (3) the Vector3 bit-equality contract, test_native_view_math_contract 11/11 and the operation table in `native/src/gd_math.h` (modified in this round); (4) one implementation: projectile_vfx.gd holds `NativeArrows` and calls `_native.fill(delta, king position, view.ids, view.current, view.living)` then `_batch.commit_buffer(...)` (lines 155 and 156), the ring arrays and slot search are gone, the statics delegate to `NativeArrows.arc_height` and `arrow_transform`, constants unchanged; replays and gate unchanged (run by me); (5) the look, on the executors' by-eye comparison and my own read of the stress-night capture (human_verification, last entry).

**04-26 (enemies, bars, puffs), 5 of 5 verified.** (1) test_enemy_fill_pins 5/5 with a deterministic clock (`set_clock` seam) on the GDScript before any native enemy-view code; (2) enemies 758.89 us to 73.12 us (10.4 times), puffs 140.05 to 4.63 us (30.2 times), both over the 3.0x rule, executor-measured and re-measured by 04-28 (38.97 and 6.36 us); (3) the 128-slot puff scan runs in `NativePuffs` (death_puff_batch.gd line 36, `_native.refresh`) and an idle batch uploads nothing (reviewer: 'Fix IN-08 verified'); (4) one implementation: the per-enemy loop and its dictionaries are gone, `EnemyViews` calls `_native.fill(frame_ms, blend, view.ids, view.previous, view.current)` (line 144) and commits four mirrors, MAX_VIEWS 512 and MAX_PUFFS 128 unchanged; (5) the look, as for 04-25.

**04-27 (units), 5 of 5 verified.** (1) test_unit_fill_pins 4/4 (stress shape with 50 footmen and the army replay), one commit, never edited; (2) `UnitReadView` (`simulation/squads/unit_read_view.gd`, test_unit_read_view 9/9) is refilled only on change, read-only; `unit_system.gd` carries the 20-method gdlint cap and the caller-less `squad_of` is gone (no caller left in the tree; lint passes on 369 files); (3) units 273.88 to 30.16 us, 9.1 times over the 2.0x rule; (4) one implementation: unit_views.gd calls `_native.fill(_ctx.alpha(), view.ids, view.previous, view.current, view.def_slots, batch_of_def)` (line 143), MAX_VIEWS stays 256; (5) CI run 39445109146 is green on every job for e0ecde0, from the orchestrator's record (the final push of the round is the one that ran `bash tools/prepush_check.sh`).

**04-28 (the measurement), 5 of 5 verified.** (1) the verdict line is quoted verbatim in 04-FRAME-REPORT.md and reads `within=true` (I read it and the budget constant); PLAT-01 is marked Complete in REQUIREMENTS.md lines 130 and 261, which the plan allows only on `within=true`; (2) the dated section sits above the kept native-port and 04-09 sections and carries the median run, all runs, on-screen counts, step and render times, the PHASE lines, the step_bench medians, the view bench medians per plan, the rebuild line (11.61 ms mean, 13.48 ms max, UAT test 10 accepted) and the restated GTX 970 projection; (3) the committed ablation's `ABLATION_SAVED` (0.09, 0.02, 0.10, all off 0.22) and `VIEW_ABLATION_OK trials=2 slice_s=5` lines are quoted beside the 04-24 baseline (report lines 173 to 177); (4) the stop rule (nothing lowered or raised if missed) was not triggered and nothing was lowered or raised (budget, map, load and tools untouched, checked); (5) the export, three screenshots and the dated update exist (read, listed).

Prohibitions (all judgment-tier; my reading is NON-AUTHORITATIVE and flagged `unverified-prohibition - human review recommended`; none is absorbed into the pass): I found no violation of the 17 new ones. Reads that cite the tree: no golden regenerated or edited, the three new pin files are single commits never edited, `FrameReport.BUDGET_P95_MS` still 8.0 and the stress map, data and tools have no later commit, the draw caps are unchanged, there is no GDScript fallback and no second implementation of any view (the `if _native != null else` guards in the accessors are null-safety before `_ready`, not a second path), the native view classes read no clock, randomness or singleton and take the frame milliseconds as arguments (grep above), no simulation state is written by a view (the replays do not move), the native guard still fails closed (probe 7/7) and no wrapper fallback was added, UnitSystem changed only by the read view, its change counter and the `squad_of` removal (diff read at the name level, tests green). The process prohibitions (no push or gh before 04-27 Task 2, only the named push command, no system-wide install) are not checkable from the tree; the SUMMARYs, STATE.md and the CI record say they were followed and I have no contrary evidence.

Decision check against 04-CONTEXT.md and the owner's recorded decisions: D-12 honoured and now met (budget not raised); D-13 and D-14 honoured by the byte-identical goldens; D-10's on-screen bar met; the owner's rule change of 2026-10-19 (UAT test 13) implemented as 04-12; route (3) GDExtension of UAT test 11 implemented as 04-14 to 04-23, extended by the owner's 2026-10-20 decision (port the view fills, budget unchanged, a higher budget and the squad per-unit port rejected) as 04-24 to 04-28; option A of 04-16 honoured; the give-up rule of 04-07 stays (UAT test 9); the wall-break rebuild hitch is accepted for now (UAT test 10; 11.61 ms mean per rebuild after this round); MAX_VIEWS 256 for units signed off (UAT test 13; review IN-03 out of scope).

### Where the GDScript went (a location change, not a missing artifact)

The table of the last report still holds for the simulation (EnemySystem, Separation, WallSolids, WallSystem buckets, NavGrid and FlowField reads, Pathing routing, StructureIndex, WallDecision, StuckTracker, TargetQuery, `behind_kind` all in `native/src/`). Added by this round:

| Function or class (per-frame view work) | Now lives in | Facade that kept the API |
|---|---|---|
| `ProjectileVfx` ring of 512 arrows, flight, re-aim and the batch write | `native/src/native_arrows.cpp` (`NativeArrows`) | `presentation/vfx/projectile_vfx.gd` (330 lines; node, constants, `attack_fired` handler and every public hook kept) |
| `EnemyViews` per-enemy body, flash and hurt-only bar write, four per-enemy dictionaries | `native/src/native_enemy_views.cpp` (`NativeEnemyViews`) | `presentation/enemies/enemy_views.gd` (253 lines) |
| `DeathPuffBatch` 128-slot ring and its per-frame scan | `native/src/native_puffs.cpp` (`NativePuffs`) | `presentation/vfx/death_puff_batch.gd` (64 lines) |
| `UnitViews` per-unit body and hurt-only bar write | `native/src/native_unit_views.cpp` (`NativeUnitViews`) over `UnitSystem.read_view()` | `presentation/units/unit_views.gd` (278 lines) |
| `CrowdBatch` instance layout and writers | `native/src/native_mirror.h` (mirror, layout), `CrowdBatch.mirror()`, `layout()` and `commit_buffer()` | `presentation/crowd/crowd_batch.gd` (206 lines) |

### Key Link Verification

68 of 69 links from the 28 plans' `key_links` are verified by `gsd-tools verify key-links` (the miss is explained above and holds through `commit_buffer`). The ones that carry the round:

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `ProjectileVfx._process` | `NativeArrows.fill` then `CrowdBatch.commit_buffer` | the delta, the king position and the enemy read view in; the filled mirror and count out | WIRED | projectile_vfx.gd lines 155 and 156 |
| `EnemyViews._process` | `NativeEnemyViews.fill` then three archetype batches and the bar batch | frame clock, blend and the enemy read view in; four mirrors out | WIRED | enemy_views.gd lines 144 to 147 |
| `DeathPuffBatch` | `NativePuffs` | spawn, refresh and active_count delegate; the ring buffer commits through `commit_buffer` | WIRED | death_puff_batch.gd lines 36 and 59 |
| `UnitViews._process` | `UnitSystem.read_view()` and `NativeUnitViews.fill` | one packed read per frame, the def-to-batch map, then the type batches and the bar batch | WIRED | unit_views.gd lines 143 to 146 |
| `register_types.cpp` | the four view classes | `GDREGISTER_CLASS` | WIRED | lines 36 to 39 |
| `tools/native_build.sh` | `tools/_common.sh` stamp functions | step 7 installs through `duskhold_native_install`; the guard recomputes `duskhold_native_stamp_for` | WIRED | native_build.sh line 294; _common.sh lines 86, 102, 126 |
| `tools/stress/view_ablation.gd` | the unchanged stress night | `StressNight.parse_args` | WIRED | test_view_ablation 5/5 |
| `04-FRAME-REPORT.md` | `FrameReport.BUDGET_P95_MS` and the committed ablation | the 8.0 ms the report is judged against; the quoted ABLATION_SAVED and VIEW_ABLATION_OK lines | WIRED | frame_report.gd line 20; report lines 173 to 177 |
| `EnemySystem.step` and the native simulation links of the last report | `NativeEnemies`, `NativeWalls`, `NativeRoute`, `NativeStructures`, `NativeWallDecision` | unchanged by the round | WIRED | replays, gate and pins hold |
| `ci.yml` jobs | `tools/native_build.sh` | native-linux and native-windows build and hand the library to test, screenshots and export | WIRED | CI run 39445109146 green (orchestrator) |
| `FrameReport.BUDGET_P95_MS` | `tools/stress.sh` verdict | 8.0 ms, unchanged | WIRED | frame_report.gd line 20; test_frame_report 11/11 |

### Requirements Coverage

Every ID from the plans' `requirements:` is accounted for against REQUIREMENTS.md (BLDG-10 in 04-04, 04-05, 04-10, 04-11; ENMY-04 in 04-06, 04-07, 04-08, 04-10, 04-11, 04-12, 04-13; PLAT-01 in 04-01, 04-02, 04-03, 04-09, 04-11, 04-14 to 04-28). REQUIREMENTS.md maps no other ID to Phase 4, so none is orphaned.

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| BLDG-10 | 04-04, 04-05, 04-10, 04-11 | Walls and barricades that block enemy movement and upgrade linearly in health | SATISFIED by implementation evidence (REQUIREMENTS.md still reads unchecked line 41 and 'Gaps Found' line 205: see the first warning) | Criterion 1 evidence; UAT test 1 passed with the owner; native wall solids pinned and replayed; nothing in round 2 touched it |
| ENMY-04 | 04-06, 04-07, 04-08, 04-10, 04-11, 04-12, 04-13 | Enemies path around or through defenses without jamming indefinitely | SATISFIED by implementation evidence (REQUIREMENTS.md still reads unchecked line 74 and 'Gaps Found' line 229: see the first warning) | Criterion 2 evidence: GATE_OK 300 of 300, stuck 0, break-or-detour tests, the walls golden, the 04-12 target rule; the owner's re-judgement of tests 6 and 13 is due (human_verification) |
| PLAT-01 | 04-01, 04-02, 04-03, 04-09, 04-11, 04-14 to 04-28 | 60 fps on GTX 970-class hardware during the largest battles | SATISFIED on the documented dev-machine budget (REQUIREMENTS.md: Complete, lines 130 and 261, set by 04-28 after `within=true`) | Criterion 3 evidence: median-run p95 5.37 ms against 8.0 ms with the D-10 counts met; the GTX 970 transfer is a projection (insufficient_spec) and the requirement is re-verified on real campaign battles in Phase 13 |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| EnemyViews / UnitViews / ProjectileVfx / DeathPuffBatch batches | instance transforms, flash, bar ratio, puff age | the simulation's packed read views (`EnemyReadView` from the native store, `UnitSystem.read_view()`) and the event bus, written by the native fills into the batch mirrors | yes: the 300-enemy, 50-unit and 237-arrow counts in the frame report are counted from drawn positions in the camera frustum; the pins hash the mirrors byte for byte against the GDScript fill | FLOWING (and no longer the cost owner: ablation 0.22 ms) |
| Debug overlay Walls / Field / Crowd rows | segment counts, field arrows, stuck flags | `WallSystem`, `Pathing.castle_field()`, `StuckTracker` getters (native-backed) | yes: pinned by test_debug_overlay_crowd_sections against a real night | FLOWING |
| WallViews | segment state, tier look, rubble | `WallSystem` signals recorded in `SimRecorder.HANDLED` | yes: test_wall_views and the walls screenshots | FLOWING |
| Native mirrors (walls, nav grid, field, structures, decision) | segment health, grid costs, unit and building snapshots | kept in step by `WallSystem`, `NavGrid.rebuild` and `StructureIndex.rebuild` | yes: a stale mirror would move the replays and pins, which do not move | FLOWING |

### Behavioral Spot-Checks and Replays

See 'What I ran and read'. State-transition and ordering truths each have a named passing test I re-ran in this or the last verification (break emits once and stays broken until dawn, the held-for-target wall released on break, the decision on its own staggered tick, the stuck tracker flagging at exactly 90 updates, the native step equal to the GDScript step tick by tick through the committed enemy-trace digests and the four replays). The view fills are state-free per frame and are pinned by byte-level digests of their output buffers. The one invariant with no direct test is the give-up rule (`behavior_unverified: 1`).

### Probe Execution

No `probe-*.sh` is declared by the phase plans and none exists under `scripts/`: SKIPPED. The replays, the gate stress, the committed step-attribution probe (test_step_attribution) and the hermetic `tools/native_stamp_probe.sh` (run by me, 7 of 7) are the phase's runnable checks.

### Anti-Patterns Found

None. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in the code files changed since the last verification and none in the earlier ones; no stub artifact. Informational: tools/native_build.sh still has only `set -u` (the install is now checked through `duskhold_native_install || exit 1`, so the CR-01 failure is closed); `tools/_common.sh` carries raw CR and newline bytes inside quoted strings (review IN-17); the stress-night camera at 119.5 m draws the crowd smaller than in play, which the frame report discloses.

## Code-review findings (33 OPEN, 3 FIXED)

04-REVIEW-DISPOSITION.md on disk: 36 rows, `open: 33`, `fixed: 3`. 04-REVIEW.md: standard depth, 50 files (the 37 round-2 files with their .uid siblings), reviewed 2026-10-20T16:16:53Z: 0 critical, 13 warning, 20 info. The reviewer verified CR-01, IN-07 and IN-08 as fixed under 'Fix <ID> verified' headings. New: WR-12 (the stamp's source half is taken at install time), WR-13 (native_stamp_probe.sh is run by nothing, confirmed by my grep), IN-17 (raw CR and newline bytes in tools/_common.sh lines 92 to 94 and 135) and IN-18 to IN-22 (small native-view items: `layout_from` offset overlap, non-positive or NaN time constants, numeric codes declared twice with no agreement test, small per-frame allocations, a member write pointer). The carried findings are WR-01 to WR-11 and IN-01 to IN-06, IN-09 to IN-16. These are committed facts carried here; I did not re-review and did not change any disposition. None contradicts a verified roadmap truth on the shipped data, and a verification gap entry is not needed for review findings: the review-fix loop is their route.

04-SECURITY.md: `status: verified`, `threats_open: 0`, 77 threats closed at ASVS level 1 (T-04-62 to T-04-74 added for this round). 04-VALIDATION.md: `status: validated`, `nyquist_compliant: true`, 61 task rows, the 04-21 escalation resolved.

## Human Verification

The structured list in the frontmatter has 6 entries. Tests 1 to 4, 7, 8, 9, 10 and 11 passed with the owner (UAT 2026-10-16 to 2026-10-19) and do not come back unless a code change touched them; round 2 changed only the view layer, the stamp and the tools, which those tests did not judge. The entries are, in order: UAT test 5 (the stress night on the native step and views), UAT test 6 (the overlay below the banner at 720p), UAT test 13 (melee enemies breaking through to their targets), the owner's re-check packet and fresh export (now produced, so the entry is the owner's launch and read), the GTX 970 transfer (insufficient_spec) and the by-eye comparison of the view-layer port. The give-up rule is carried in `behavior_unverified_items`: the owner already passed it at UAT test 9, so it is evidence quality, not an open question. 04-UAT.md is NOT complete yet (status `diagnosed`, 13 tests: 9 passed, 3 issue, 1 blocked); the owner runs `/gsd-verify-work 4` after this report.

## Gaps Summary

No gap blocks the phase goal. The one gap of the last report, ROADMAP criterion 3 / PLAT-01, is closed by measurement: the per-frame view fills went to C++ pins-first and byte-identical (04-25 to 04-27), the stress night was re-measured in a real window with the unchanged method and budget (04-28), and the median-run p95 is 5.37 ms against 8.0 ms with the stress load untouched. 04-21's unfinished Task 2 is produced (export, screenshots, dated owner update) and review CR-01 is fixed. What is left is the owner's judgement (six items), the GTX 970 projection that no machine here can confirm, one invariant (the give-up rule) pinned only by its effect and the tick-identical enemy traces, 33 open code-review findings for the review-fix loop, and one bookkeeping item for phase close-out: REQUIREMENTS.md still shows BLDG-10 and ENMY-04 unchecked after commit c962bb7, although their implementation evidence is complete. If any file in the covered list changes, re-run `verification.status` to refresh the fingerprint.

---

_Verified: 2026-10-20T16:41:25Z_
_Verifier: Claude (gsd-verifier)_
