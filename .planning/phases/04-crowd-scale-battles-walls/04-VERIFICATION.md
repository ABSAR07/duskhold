---
phase: 04-crowd-scale-battles-walls
verified: 2026-10-16T21:04:00Z
status: gaps_found
score: "3/4 roadmap success criteria verified in code and tests (criterion 3, PLAT-01, FAILED by measurement); 74/76 plan truths verified, 1 failed (04-09 p95 budget), 1 insufficient_spec (04-09 GTX 970 transfer, backstop tier); 2/3 requirement IDs have implementation evidence (BLDG-10, ENMY-04 satisfied; PLAT-01 NOT satisfied, left Pending)"
must_haves:
  roadmap_truths: 4
  roadmap_truths_verified: 3
  roadmap_truths_failed: 1
  plan_truths_declared: 76
  plan_truths_verified: 74
  plan_truths_failed: 1
  plan_truths_insufficient_spec: 1
  plan_artifacts_checked: "49/50 by gsd-tools verify.artifacts over all 11 plans, re-run by me; the one tool miss is 04-10 artifact tests/fixtures/fixture_map_replay_walls.tres pattern WallRunDef (a literal-string miss: the fixture holds the run as an inline sub_resource whose script is res://simulation/walls/wall_run_def.gd, lines 9, 76-81, and wall_west carries wall_run = SubResource(Resource_run_west); the artifact is intact and the walls replay runs on it)"
  plan_key_links_checked: "34/34 by gsd-tools verify.key-links over all 11 plans, re-run by me"
  prohibitions_declared: 20
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass. The 20 are plan-scoped (plans 04-01 to 04-11). My reading found no violation (details in the Plan must_haves section)"
  requirement_ids: 3
  requirement_ids_satisfied: 2
  requirement_ids_failed: 1
  requirement_ids_orphaned: 0
re_verification: false
covered_files:
  - .github/workflows/ci.yml
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
  - .planning/phases/04-crowd-scale-battles-walls/04-VALIDATION.md
  - data/buildings/wall.tres
  - data/maps/prototype_map.tres
  - data/tuning/nav_tuning.tres
  - input/selection_controller.gd
  - presentation/buildings/building_views.gd
  - presentation/crowd/crowd_batch.gd
  - presentation/crowd/crowd_instance.gdshader
  - presentation/crowd/mesh_baker.gd
  - presentation/debug/enemy_path_gizmo.gd
  - presentation/debug/flow_field_gizmo.gd
  - presentation/enemies/enemy_views.gd
  - presentation/king/king.gd
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
  - simulation/night/enemy_index.gd
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
  - tests/golden/walls.json
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_report.gd
  - tests/integration/test_balance_report_walls.gd
  - tests/integration/test_gate_stress.gd
  - tests/integration/test_wall_behaviour.gd
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
  - tests/unit/test_flow_field.gd
  - tests/unit/test_frame_report.gd
  - tests/unit/test_goal_field_cache.gd
  - tests/unit/test_health_bar_batch.gd
  - tests/unit/test_los_targets.gd
  - tests/unit/test_map_nav_validation.gd
  - tests/unit/test_map_wall_validation.gd
  - tests/unit/test_mesh_baker.gd
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_nav_grid.gd
  - tests/unit/test_nav_tuning_contract.gd
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_projectile_vfx.gd
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_prototype_map_walls.gd
  - tests/unit/test_replay_cli_args.gd
  - tests/unit/test_separation_grid.gd
  - tests/unit/test_shot_list.gd
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spatial_index.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_stress_map_data.gd
  - tests/unit/test_stress_tool_args.gd
  - tests/unit/test_stuck_tracker.gd
  - tests/unit/test_wall_blocking.gd
  - tests/unit/test_wall_data_contract.gd
  - tests/unit/test_wall_decision.gd
  - tests/unit/test_wall_plot_isolation.gd
  - tests/unit/test_wall_solids.gd
  - tests/unit/test_wall_system.gd
  - tools/gate_stress.sh
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
  - tools/stress/frame_report.gd
  - tools/stress/frame_report_cli.gd
  - tools/stress/gate_stress.gd
  - tools/stress/gate_stress_cli.gd
  - tools/stress/step_bench.gd
  - tools/stress/stress_map.tres
  - tools/stress/stress_night.gd
  - tools/stress/stress_night.tscn
  - ui/overlay/crowd_overlay_sections.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay.tscn
  - ui/overlay/night_overlay_sections.gd
  - ui/world/spot_label_model.gd
covered_digest: "v2:sha256:270d8c92f082ec639c5252bd07fdb7874719ae0ee2fac4141240da245a373506"
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "ROADMAP success criterion 3 / PLAT-01: a scripted stress night with hundreds of units, enemies and projectiles on screen holds 60 fps on GTX 970-class hardware, or within a documented equivalent frame-time budget on the dev machine (the documented budget is a median-run p95 at or under 8.0 ms, D-12); plan 04-09 truth 4"
    status: failed
    reason: "Measured and committed as NOT met. 04-FRAME-REPORT.md: median-run p95 37.04 ms against the 8.0 ms budget (4.6 times over; runs 36.58, 37.04, 38.89), p50 20.92 ms (about 43 fps), at 300 enemies, 50 units and at least 239 arrows in view at every sampled frame (the D-10 on-screen bar is met in full). The cause is the simulation step (18 to 25 ms on a step frame, 22.2 ms in the headless profile: enemies 15.6 ms of which target choice 7.5 and push-apart 3.7; the wall logic adds 8 to 10 ms once 300 enemies queue at a gate), not the renderer (render CPU 0.70 ms, GPU 4.46 ms, 230 draw calls). Lever (a), packed storage inside EnemySystem, was not pulled because the measurement bounded its gain at about 1 ms of the 22 ms step; 04-09 halted at its stop rule and the budget was not raised. No GTX 970 was measured. Owner decision 2026-10-16 (STATE.md Decisions and Blockers, 04-PLAYTEST-GATE.md 'Your decision' 1): run 04-10 and 04-11 on the missed budget and choose the performance route (a GDExtension for the enemy and wall step, a documented higher budget with the owner's number, or a GDScript optimisation plan for target choice, push-apart and wall logic, including slicing) after /gsd-verify-work 4, from a profiling-driven gap plan. I re-ran the headless step bench in this report and it read 29.0 and 33.6 ms mean (one run 47.9) at 300 enemies on a possibly loaded machine, 4.71 ms at 40 enemies: consistent with the miss, not a new measurement (the committed report is the evidence)"
    artifacts:
      - path: ".planning/phases/04-crowd-scale-battles-walls/04-FRAME-REPORT.md"
        issue: "records the miss: p95 37.04 ms against 8.0 ms, with the step profile and the three options"
      - path: "simulation/night/enemy_system.gd"
        issue: "target choice (7.5 ms), push-apart (3.7 ms) and move-and-strike (2.4 ms) per step at 300 enemies; the dominant cost"
      - path: "simulation/walls/wall_solids.gd"
        issue: "wall line tests and the visible-structure query, with simulation/nav/ (the castle field march, wall decisions, stuck tracker) are the 8 to 10 ms the walls add"
    missing:
      - "A profiling-driven gap plan, run through /gsd-plan-phase 4 --gaps after the owner chooses the route at /gsd-verify-work 4: GDExtension (C++) for the enemy and wall step, OR a documented higher budget for the stress night with the owner's number, OR a GDScript optimisation plan (target choice, push-apart, wall line tests, hot-path allocations from review IN-01, first_blocking cost from IN-02), each re-measured with bash tools/stress.sh --runs=3 --duration=20 into a new 04-FRAME-REPORT.md and held to the smoke, army and walls goldens (slicing needs its own golden decision)"
      - "PLAT-01 stays Pending in REQUIREMENTS.md until a stress-night median-run p95 meets whatever budget the owner documents; it is re-verified on real campaign battles in Phase 13"
deferred:
  - truth: "Night readability under hundreds of units (individual enemies are small from the stress camera; the palisade is low contrast against the dark night ground; tier I and II palisades look alike from the riding camera)"
    addressed_in: "Phase 8"
    evidence: "ROADMAP Phase 8 'Art, Readability & Sound' goal: 'nights that stay readable in big battles'; UI-05 maps to Phase 8 (Pending). 04-PLAYTEST-GATE.md assumption 25 records it as observed and left for that pass. Informational: no Phase 4 roadmap criterion depends on it"
advisory: []
warnings:
  - id: "Owner gate has not run (no 04-UAT.md)"
    where: ".planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md"
    issue: "Every feel and tuning judgement of the phase (13 entries below) is open. The roadmap clauses that depend on feel (walls 'funnel enemies into chokepoints', 'never jam', a stress night that is smooth) are verified here only as far as tests, replays, the gate stress and screenshots can observe them."
    decision_requested: "Run the packet, then /gsd-verify-work 4; turn the entries below into UAT tests 1:1."
  - id: "Code review: 13 of 13 findings open (0 critical, 7 warning, 6 info)"
    where: "04-REVIEW.md, 04-REVIEW-DISPOSITION.md"
    issue: "Recorded facts carried here, not re-reviewed. None changes a verified roadmap truth on shipped data; WR-01, WR-03 and WR-06 name latent traps. See 'Code-review findings'."
    decision_requested: "Triage through the review-fix loop (execute-phase, then code-review --fix --all) per the owner's recorded process, or fold into the performance gap plan where they overlap (IN-01, IN-02)."
  - id: "Validation is partial by design: nyquist_compliant false"
    where: "04-VALIDATION.md (status validated, 24 task checks, 4-09-02 red)"
    issue: "The one red check is the PLAT-01 budget (4-09-02), the same fact as the gap above."
    decision_requested: "None beyond the gap."
  - id: "CI, export launch and the 37-screenshot pass were taken from the orchestrator, not re-run by me"
    where: "CI run 38959046206 on a8c57ab, 04-11-SUMMARY.md, 04-PLAYTEST-GATE.md"
    issue: "I cannot run gh or the game window in this role. Nothing outside .planning/ has changed since a8c57ab (git diff a8c57ab HEAD --name-only shows only .planning/ files), so the CI result applies to the current code."
    decision_requested: "None."
  - id: "Bots buy walls only late; 0 segments were broken in the whole balance sweep"
    where: "04-BALANCE-REPORT.md, 04-PLAYTEST-GATE.md 'Honest limit', review WR-06"
    issue: "D-15's neutral-balance result (8 of 10 wins with and without walls) says walls do not break the Phase 2 bar when bought late; it says nothing about mid-game walls. The break-or-detour rule is pinned by the walls golden and test_wall_behaviour, not by the sweep. The army bot loses 4 seeds even with free walls (assumption 22, cause not isolated)."
    decision_requested: "Owner open points 4 (walls worth their gold) and 22."
  - id: "gsd-tools artifact miss on 04-10 (tooling, informational)"
    where: "04-10-PLAN.md artifacts[2] pattern WallRunDef vs tests/fixtures/fixture_map_replay_walls.tres"
    issue: "See the must_haves note: the run is present as an inline sub_resource through its script path; the literal class name never appears in the file."
    decision_requested: "None; the plan is a closed historical document and I did not edit it."
behavior_unverified_items:
  - truth: "04-07 deviation: an enemy that gives up on a segment never takes that same segment again while a way round exists (EnemySystem._breaking_is_faster, Record.wall_given_up, enemy_system.gd lines 310 and 365)"
    test: "Run a night with a long weak wall and a crowd near the break-even; watch an individual enemy that walks away from a segment while its neighbours keep hitting it"
    expected: "It never turns back to the same segment while the gap is still reachable; it still breaks in when sealed (the detour is MAX_TICKS)"
    why_human: "No test names wall_given_up or pins this per-enemy invariant. It is exercised only through its effect (test_nobody_flips_between_breaking_and_walking_round_more_than_twice, 8/8 test_wall_behaviour re-run by me, switches per enemy at most 2 on seeds 1 to 3), and presence plus wiring cannot show that the rule rather than the 15-tick hysteresis holds the bound. Rolled into human_verification entry 9"
coincidental_reliance_items: []
human_verification:
  - name: "Walls worth their gold, readable by tier, and the barricade price (assumptions 5, 7, 20; decision 4)"
    requirement: "BLDG-10"
    test: "Play two or three full runs buying walls (Space or E held at the west, east, north and ring plots; barricade 2, stone 4, reinforced 6 gold). From the riding camera compare the three tiers and a hurt segment's bar. Say whether a barricade should cost 1 (D-03 allows it), whether prices or the economy should move, and whether the late-only bot purchase means mid-game walls matter. See 04-PLAYTEST-GATE.md 'What to judge' 1 and 'Your decision' 4"
    expected: "Tiers I, II and III are tell-apart-able from the riding camera (primitive palisade, Castle Kit stone wall, stone with tower-base pillars), a damaged segment's bar reads, and a wall is worth 2, 4 or 6 gold against a House or a tower; or the owner names the price or look fix that must land before Phase 5"
    why_human: "Worth and readability are by-eye and economic judgements. The code pins cost 2 / 4 / 6 and health 30 / 60 / 90 (data/buildings/wall.tres; test_wall_data_contract 7/7 re-run by me), but the screenshots show the segments thin and tier I and II alike, and the bots (about 15 to 22 gold a run) buy walls only in the last days"
  - name: "Gates funnel enemies into the towers"
    requirement: "BLDG-10, ENMY-04"
    test: "With a wall across a road and a tower behind it, watch whether the crowd bunches at the 4 m gap inside the tower's range or spreads and chews through (04-PLAYTEST-GATE.md 'What to judge' 2; the stress night shows 300 funnelling through one gate under 20 towers)"
    expected: "The crowd bunches at the gap in front of the towers, which is the roadmap's 'funnel enemies into chokepoints'"
    why_human: "Code and tests prove 300 of 300 cross a 4 m gate and that the walls replay detours and breaks (GATE_OK, test_wall_detour 12/12, test_wall_behaviour 8/8); whether that reads as a satisfying funnel into the defence is a feel judgement"
  - name: "Break-or-go-around looks smart, and a breach reads"
    requirement: "ENMY-04"
    test: "Watch a crowd meet a weak wall and a lone enemy meet a strong wall; watch a segment break, sink to rubble and rise again at dawn (04-PLAYTEST-GATE.md 'What to judge' 3; assumptions 8, 11, 12)"
    expected: "A crowd at a weak segment breaks it and walks on, a strong wall sends enemies round, the choice looks intentional, and the breach (sink, rubble blocking nothing, free dawn rebuild) is readable"
    why_human: "The rule is pinned (test_wall_decision 12/12, test_wall_behaviour 8/8 re-run by me); whether it looks intentional rather than twitchy, and whether the dark low-contrast rubble reads at night (walls_night_breach), is by eye"
  - name: "Squads and the king get round walls without fuss"
    requirement: "ENMY-04, BLDG-10"
    test: "Take an army through the gaps of a built run, ride the king through them, try to get stuck against a segment (04-PLAYTEST-GATE.md 'What to judge' 4, assumption 22). The army bot still loses 4 seeds with free walls; the suspected cause, squads following the king round the walls, is not isolated"
    expected: "Squads route through the gaps on the goal-keyed flow field and the king is pushed out of standing segments without sticking; the army holds up, or the owner names the squad fix"
    why_human: "Squads and the bot king route through gaps by tests (the squad path is covered in test_wall_detour and test_wall_system), but feel and the unexplained army-bot loss are judgements; the player-steered king is pushed out, not routed (assumption 21)"
  - name: "The stress night feels smooth and the crowd reads"
    requirement: "PLAT-01"
    test: "Run the stress night in the editor binary (& .\\.tools\\godot\\4.7.2-stable\\Godot_v4.7.2-stable_win64.exe --path . res://tools/stress/stress_night.tscn -- --duration=30) and watch 300 enemies, 50 footmen, 20 towers and the arrows (04-PLAYTEST-GATE.md 'What to judge' 5)"
    expected: "On the owner's machine the crowd, arrows and towers are legible and the frame time is tolerable, or the owner says where it hurts; Claude measured about 43 fps at the median and a 37.04 ms p95"
    why_human: "Smoothness and crowd legibility are perceptual; the measurement is in 04-FRAME-REPORT.md and is the failed gap, but how bad it feels on the real machine is the owner's call"
  - name: "The drawn field and the two-column overlay read well"
    requirement: "ENMY-04"
    test: "Press F3 at night (stress night or a prototype night with walls): look at the flow-field arrows, blocked-cell crosses, enemy paths, magenta stuck enemies, and the Walls, Field and Crowd sections (screenshots overlay_field_gate, overlay_paths)"
    expected: "The field and paths are readable, the panel does not hide what matters, and the sections answer 'where are they going and who is stuck'; this is the 'paths are visible in the debug overlay' clause of criterion 2"
    why_human: "The wiring and numbers are tested (test_debug_overlay_crowd_sections 12/12 re-run by me; FlowFieldGizmo and EnemyPathGizmo added by CrowdOverlaySections and NightOverlaySections), legibility of arrows and layout is by eye (the overlay panel covers the right part of the wall by design)"
  - name: "Nights still feel tense with walls available"
    requirement: "BLDG-10, PLAT-01"
    test: "Play the eight nights with walls on top (04-PLAYTEST-GATE.md 'What to judge' 6): no night count, cost or other data moved in Phase 4"
    expected: "Walls do not make the nights trivially easy and are not bought too late to matter, or the owner says which number should move"
    why_human: "The bots measure data only: balanced and army_balanced win 8 of 10 with and without walls and the Phase 3 per-seed rows reproduce byte-identically (md5 001778e71f38ecd0424f65e0ef9977f8), but tension is a feel judgement and the bots buy walls late"
  - name: "D-14 reading: same outcomes, not digests"
    requirement: "BLDG-10, ENMY-04"
    test: "Read 04-PLAYTEST-GATE.md assumption 18 and 04-BALANCE-REPORT.md; confirm the reading or ask for the literal one (every digest regenerated in one new commit)"
    expected: "The owner confirms that smoke (2599c7c2, 703 ticks) and army (f7a967ed, 1353 ticks) never moved, the new walls golden bfb05fc7 (1961 ticks) pins the wall rules, and full_idle (unpinned) moved once in 94fff12 from f417c7f5 (6941 ticks) to 4385f569 (6911 ticks); or asks for the literal regeneration"
    why_human: "It is the owner's reading of their own D-14 and a decision to confirm; verified fact: I re-ran all four replays and they match"
  - name: "The give-up rule of plan 04-07"
    requirement: "ENMY-04"
    test: "Watch crowds at a long weak wall near the break-even (assumption 13): an enemy that gives up on a segment should not return to it while a way round exists"
    expected: "No grunt flips between a wall and the gap, and sealed enemies still break in; or the owner wants the rule changed"
    why_human: "A rule the plan did not specify (it was added after a 15-tick hysteresis alone still let one grunt flip four times) and no test pins it directly; see behavior_unverified_items"
  - name: "The wall-break rebuild hitch: keep it accepted or slice it"
    requirement: "ENMY-04, PLAT-01"
    test: "Break a wall in play (or read 04-FRAME-REPORT.md 'Wall-break rebuild') and notice whether the break drops a frame: 11.74 ms mean and 13.22 ms maximum per synchronous grid and castle-field rebuild on 5,494 cells, a 34.14 ms break-frame estimate against 16.7 ms"
    expected: "The owner keeps the hitch accepted, or asks for count-based time slicing of the rebuild (a rule change: enemies take more ticks to see a breach) to be planned"
    why_human: "The measurement is committed; whether one dropped frame at a break matters in play, and whether to change a rule to remove it, is the owner's decision (04-PLAYTEST-GATE.md 'Your decision' 2)"
  - name: "The PLAT-01 performance route"
    requirement: "PLAT-01"
    test: "Choose, from 04-FRAME-REPORT.md 'Verdict and the open decision' and 04-PLAYTEST-GATE.md 'Your decision' 1: (1) a GDExtension (C++) for the enemy and wall step, (2) a documented higher budget with a number the owner chooses, or (3) a targeted GDScript optimisation plan for the wall logic, target choice and push-apart, including slicing"
    expected: "A recorded route that becomes the profiling-driven gap plan for the gap above (the owner's decision of 2026-10-16 deferred this choice to /gsd-verify-work 4)"
    why_human: "A project decision with cost and rule trade-offs, explicitly reserved to the owner"
  - name: "GTX 970 transfer of the dev-machine budget (insufficient_spec, backstop tier)"
    requirement: "PLAT-01"
    test: "If a GTX 970-class machine is ever available, run bash tools/stress.sh --runs=3 --duration=20 on it; otherwise accept the written projection"
    expected: "The budget transfers to at most 16.7 ms per frame under RESEARCH A1 (GPU about 3 to 4 times slower, GDScript step about 1.3 to 1.6 times slower); the committed projection is the opposite: 30 to 37 fps at the median and a 48 to 59 ms p95, because the step is CPU-bound"
    why_human: "Plan 04-09 truth 5 is a backstop-tier truth: no GTX 970 exists here, presence and wiring never qualify, and no wired held-out test can stand in for hardware; I abstain (insufficient_spec). It is moot while the dev-machine budget itself is missed"
  - name: "The 25 assumptions made for the owner, and the Phase 5 fix list"
    requirement: "BLDG-10, ENMY-04, PLAT-01"
    test: "Read the 25 assumptions in 04-PLAYTEST-GATE.md (view caps, enemy look, baked unit meshes, wall numbers and geometry, targets behind walls dropped, pathing tunables, D-07 and D-09 numbers, stress-night settings, the bots' wall placement, edge cases); change any; list the readability, tier-look, gate and squad fixes that must land before Phase 5"
    expected: "Each assumption confirmed or changed; anything listed becomes a gap plan through /gsd-verify-work 4. Note review IN-03: UnitViews.MAX_VIEWS is 256, below the 50-per-squad times several squads the simulation can field; assumption 1 states the cap"
    why_human: "Nothing in the packet was confirmed with the owner"
---

# Phase 4: Crowd-Scale Battles & Walls Verification Report

**Phase Goal:** Nights scale to Thronefall-size battles, with hundreds of units, enemies, and projectiles at 60 fps. Walls and barricades shape enemy paths without gridlock. This lands before any content breadth is added.
**Verified:** 2026-10-16T21:04:00Z
**Status:** gaps_found
**Re-verification:** No. Initial verification (no earlier 04-VERIFICATION.md existed).

## Verdict

The goal is half achieved and one clause of it is measurably not. Walls and barricades exist, block ground movement, upgrade linearly (30 / 60 / 90 health per segment at 2 / 4 / 6 gold), and shape enemy paths: 300 of 300 enemies cross an 80 m wall through a 4 m gate with zero stuck, no wall hit, in 14.9 s median and 21.9 s worst, re-run by me. Batched simulation and rendering landed without moving a Phase 1 to 3 outcome: the smoke and army digests are byte-identical to goldens that were never touched in the phase. But "hundreds of units, enemies, and projectiles at 60 fps" is not true. The committed measurement (04-FRAME-REPORT.md) puts the median-run p95 at 37.04 ms against the 8.0 ms budget at 300 enemies, 50 units and 239 or more arrows, about 43 fps at the median. The renderer is healthy (render CPU 0.70 ms, 230 draw calls); the GDScript simulation step is the cost (18 to 25 ms). The phase's data layout work (the batches) delivered the rendering half of PLAT-01, and the step half is open.

Status follows the agent's decision tree as written: criterion 3 FAILED fires rule 1 (`gaps_found`), which takes precedence over the 13 owner items and the one behavior-unverified truth; the full `human_verification` and `behavior_unverified_items` lists are kept so nothing is lost. The miss is not a verification defect of the phase's work: the owner decided on 2026-10-16 to run 04-10 and 04-11 on the missed budget and to choose the performance route (GDExtension, a documented higher budget, or a GDScript optimisation plan) after `/gsd-verify-work 4`, from a profiling-driven gap plan. The gap below carries that route. I did not mark PLAT-01 satisfied and REQUIREMENTS.md still reads `PLAT-01 | Phase 4 | Pending`.

Everything else is implemented, wired, tested and replayed: no missing or stubbed artifact (49 of 50 by the tool, the one miss a literal-string drift, see below), no unwired link (34 of 34), no debt marker, lint clean on 334 files. The owner's gate has not run (no `04-UAT.md`), so every feel and tuning judgement is an open human item.

ROADMAP marks Phase 4 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form (the same as Phases 2 and 3, and the orchestrator's brief asked for the standard method), so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD 1d29358 (Godot 4.7.2, Windows). `git status` was clean before (the working tree held no change); I modified no source, data or test file, killed no process and committed nothing. I did not run the full suite, the stress night or the playtest sweep.

| Check | Command | Result |
|---|---|---|
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` |
| Army replay vs golden | `... --scenario=army --twice --expect-file=tests/golden/army.json` | `REPLAY_OK scenario=army ... ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` |
| Walls replay vs golden | `... --scenario=walls --twice --expect-file=tests/golden/walls.json` | `REPLAY_OK scenario=walls ... ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` |
| full_idle twice | `... --scenario=full_idle --twice` | `REPLAY_OK ... ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (unpinned by design) |
| Gate stress (criterion 2) | `bash tools/gate_stress.sh --twice` | `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a` |
| Lint and format | `bash tools/lint.sh` | `334 files would be left unchanged`, `Success: no problems found` |
| Golden history | `git log 75183fe..HEAD -- tests/golden/smoke.json tests/golden/army.json` and their fixtures | empty: neither golden nor fixture changed in the phase (criterion 4); only `walls.json` was added (e3b8a74) |
| Data scope | `git diff --stat 75183fe HEAD -- data/` | 3 files only: wall.tres (new), prototype_map.tres (+66, wall plots), nav_tuning.tres (new); no night, unit, tower, castle or economy file moved |
| Plan artifacts | `gsd-tools query verify.artifacts` on each of the 11 plans | 49/50 (the one miss explained in the frontmatter note and warnings) |
| Plan key links | `gsd-tools query verify.key-links` on each of the 11 plans | 34/34 |
| Tests (one named suite per call, never the full suite) | `bash tools/test.sh -gselect=<name>` | test_wall_behaviour 8/8 (412 asserts), test_wall_detour 12/12, test_wall_decision 12/12, test_stuck_tracker 11/11 (1070), test_wall_system 17/17, test_wall_dawn 5/5, test_wall_data_contract 7/7, test_map_wall_validation 20/20, test_prototype_map_walls 16/16, test_flow_field 9/9, test_gate_stress 10/10, test_walls_replay_golden 8/8, test_crowd_batch 9/9, test_enemy_views 12/12 (844), test_unit_views 5/5, test_projectile_vfx 10/10, test_spatial_index 12/12 (3021), test_separation_grid 7/7, test_debug_overlay_crowd_sections 12/12; 19 scripts, all passing |
| Debt markers | grep TBD, FIXME, XXX over the 140 non-planning covered files | none; TODO, HACK, PLACEHOLDER also none |
| NavigationServer3D / NavigationAgent3D under simulation/ | grep | none (prohibition of 04-06 holds) |
| Export exclusion | `export_presets.cfg` exclude_filter | `tests/*, addons/gut/*, tools/*` (the stress and gate tools stay out of the export) |
| Step bench (corroboration only) | `bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- --enemies=300 --steps=30` (three runs) and `--enemies=40` | 47.89, 29.00, 33.56 ms mean at 300 (noisy: higher than the committed 20.1 to 22.9, likely a loaded machine); 4.71 ms at 40. Both far from the 5 to 6 ms the budget needs |
| Requirements | plan frontmatter `requirements:` vs REQUIREMENTS.md | BLDG-10, ENMY-04, PLAT-01 in both; see Requirements Coverage |

Taken from the orchestrator without re-running, and marked as such: the full suite at a8c57ab (190 scripts, 1794 tests, 27554 asserts, all passing, lint clean on 334 files); CI run 38959046206 (green for lint, test, export and screenshots on a8c57ab, https://github.com/ABSAR07/duskhold/actions/runs/38959046206); the fresh Windows export launching and exiting in about 3 s; the 37-screenshot real-window pass; the stress night's three runs; the balance sweep of 80 runs; the regression gate (93 of 93 prior-phase scripts still present ran green in the wave-10 full run). `git diff a8c57ab HEAD --name-only` shows only `.planning/` files, so those results apply to the code I read. I did not run the game window, `tools/screenshot.sh` or the playtest bots.

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | The player can build walls and barricades that block enemy movement, upgrade them linearly in health, and use them to funnel enemies into chokepoints | VERIFIED in code and tests; the funnel and tier-readability feel is an owner item (human entries 1, 2) | Wall plots: four on the prototype map (data/maps/prototype_map.tres; test_prototype_map_walls 16/16). Hold-to-build buys a whole run at once (WallSystem.on_building_built; test_wall_system 17/17). Health linear in tiers: wall.tres cost 2 / 4 / 6, max_health 30 / 60 / 90 (read directly; test_wall_data_contract 7/7). Blocking: WallSolids push-out for everyone on the ground and the KIND_WALL hit path (test_wall_blocking, test_wall_solids, test_wall_behaviour 8/8). Funnel: enemies detour through the 4 m gap (test_wall_detour 12/12) and 300 of 300 cross one gate (GATE_OK) |
| 2 | Enemies path around walls or break through and never jam; a headless stress test with 200+ enemies through a single gate finishes with zero permanently stuck agents; paths visible in the debug overlay | VERIFIED in code and tests | `GATE_OK enemies=300 crossed=300 stuck=0 ... wall_hits=0` re-run twice by me; `GateStress.passes` requires crossed == enemies and stuck_at_end == 0 and not hit_limit (tools/stress/gate_stress.gd line 62-63); the sink removes only enemies already crossed and within the castle sink radius (lines 115-116, prohibition honoured); `StuckTracker` flags 3 s without 0.5 m (test_stuck_tracker 11/11). Break-or-go-around: test_wall_decision 12/12, test_wall_behaviour 8/8 (a crowd of 12 breaks a weak wall, a lone grunt goes round a strong one, a sealed ring is still broken into). Overlay: FlowFieldGizmo added by CrowdOverlaySections and EnemyPathGizmo by NightOverlaySections, rows tested (test_debug_overlay_crowd_sections 12/12); legibility is human entry 6 |
| 3 | A scripted stress night with hundreds of units, enemies and projectiles holds 60 fps on GTX 970-class hardware, or within a documented equivalent frame-time budget | **FAILED** (BLOCKER) | 04-FRAME-REPORT.md: median-run p95 **37.04 ms** against the 8.0 ms budget (`FrameReport.BUDGET_P95_MS = 8.0`, tools/stress/frame_report.gd line 20; the budget was not raised), p50 20.92 ms (about 43 fps), three runs 36.58 / 37.04 / 38.89 ms; the D-10 on-screen bar met (300 enemies, 50 units, 239 arrows minimum). Cause: the simulation step, 22.2 ms in the profile. Owner route recorded; one gap entry in the frontmatter |
| 4 | Nights from Phases 1 to 3 play the same after the switch to batched simulation and rendering; all existing headless loop and combat tests still pass | VERIFIED | smoke (703 ticks, 2599c7c2) and army (1353 ticks, f7a967ed) replay byte-identical to goldens that no commit of the phase touched (re-run by me); the data diff holds only wall.tres, nav_tuning.tres and the prototype map's wall plots; Phase 3's balance rows reproduce byte-identically on the Phase 4 code (md5 001778e71f38ecd0424f65e0ef9977f8 of report.json, orchestrator); the full suite at a8c57ab, 1794 of 1794, includes 93 of 93 prior-phase scripts (orchestrator). full_idle moved once, intentionally and unpinned, in the single D-14 commit 94fff12 (6941 to 6911 ticks) because the balanced bot's order changed |

### Plan must_haves

76 plan truths and 20 prohibitions are declared across the 11 plans. I verified them against code, tests and replays rather than against the SUMMARYs.

- **04-01 to 04-03 (batched rendering and exact-preserving crowd step).** Enemies are drawn as one `CrowdBatch` MultiMesh per archetype (presentation/enemies/enemy_views.gd: batches added at lines 261-264, `MAX_VIEWS` 512, bars and puffs from batches, no Node3D per enemy), units and arrows likewise (test_unit_views 5/5, test_projectile_vfx 10/10, ring of 512). The structure and enemy grids equal the reference scans on seeded worlds with ties (test_spatial_index 12/12, 3021 asserts) and the bucketed push-apart equals the reference (test_separation_grid 7/7). The goldens are byte-identical. Truth 5 of 04-03 (step at or under 10.0 ms on the bench, from 50.1 ms) was met at the time of that plan (8.4 to 9.2 ms recorded); the walls then added the cost the frame report measures. VERIFIED.
- **04-04 and 04-05 (BLDG-10).** Segment health, break once, hole, dawn restore for free and idempotent, solid for everyone on the ground, plots never a target (test_wall_system 17/17, test_wall_dawn 5/5, test_wall_blocking, test_wall_solids, test_wall_plot_isolation); four wall runs authored, validated and priced (test_prototype_map_walls 16/16, test_map_wall_validation 20/20, test_wall_data_contract 7/7). Screenshots and looks per tier are the orchestrator's real-window pass. VERIFIED.
- **04-06 to 04-08 (ENMY-04).** Integer Dial flow field, goal cache, sealed enemies break in, blocked targets dropped (test_flow_field 9/9, test_nav_grid, test_wall_detour 12/12); per-segment break-or-detour with hysteresis and the integer overflow bound (test_wall_decision 12/12, including a million health against a thousand attackers); stuck tracker read-only (the file states it emits no event; test_stuck_tracker 11/11 including 'a real night is read and nothing about it changes'); the gate harness and CI step; overlay sections that emit nothing and build no goal field (test_debug_overlay_crowd_sections: 'collecting every section emits nothing and builds no goal field'). VERIFIED.
- **04-09 (PLAT-01).** Of its 8 truths: the stress night holds 300 / 50 / 200+ in view (VERIFIED by the report), runs in a real window with the declared method (VERIFIED), tools/stress.sh runs three times and publishes the median (VERIFIED), the wall-break rebuild is measured and recorded (VERIFIED), the crowd_stress_night screenshot exists (orchestrator pass). **Truth 4, the median-run p95 at or under 8.0 ms: FAILED.** **Truth 5, the GTX 970 transfer: insufficient_spec** (backstop tier, no GTX 970 exists here). **Truth 6** (if the budget is missed, the first lever is packed storage inside EnemySystem, and if it is still missed the plan stops with the numbers for the owner instead of raising the budget): the stop and 'do not raise the budget' halves hold (budget still 8.0, report committed, plan `status: halted`); the lever itself was not pulled because the measured gain was bounded at about 1 ms of 22 ms. I read that as a documented deviation that the owner's decision of 2026-10-16 accepts, not a separate gap, and I count truth 6 verified on the stop rule; it is carried in the gap's `missing` as option 3 and in human entry 11. The summary correctly lists `requirements-completed: []`.
- **04-10 and 04-11.** The walls golden is pinned, checked twice in CI (e3b8a74; test_walls_replay_golden 8/8); the strategies, no-walls twins, balance report and the single regeneration commit 94fff12 exist; the Phase 2 bar holds with walls (8 of 10 for both bots). Truths 1, 2 and 3 of 04-11 (full local pass, CI green, export launch) are the orchestrator's measured facts, flagged as not re-run by me. VERIFIED, with the PLAT-01 line of the playtest packet stating the miss plainly.

Prohibitions (all judgment-tier; my reading is NON-AUTHORITATIVE and flagged `unverified-prohibition - human review recommended`; none is absorbed into the pass): I found no violation. Reads that cite code: no write from a view into simulation state (views take read accessors and the read view; test_enemy_views 12/12 and the identical goldens support it); no enemy is dropped or frozen to hold the budget (the cap only stops drawing beyond 512, and 04-09 explicitly did not lower fidelity); no enemy is removed because it is stuck (the gate sink removes only crossed enemies at the castle, lines 113-116); no NavigationServer3D or NavigationAgent3D under simulation/ (grep empty); the stuck tracker emits nothing (file header and test); the stress tools stay out of the export (exclude_filter `tools/*`); smoke and army goldens not regenerated (git log empty); no gamepad binding, prompt or test added by 04-11 (the packet's controls table is keyboard and mouse only); the existing ten prototype plots untouched (test_wall_plot_isolation green; the map diff adds plots). The wall prices stay inside D-03 (2 / 4 / 6).

Decision check against 04-CONTEXT.md: D-13 (the view switch moves no number) honoured by the identical goldens; D-14 honoured under the owner-pending reading 'same outcomes, not digests' (smoke and army never regenerated, one deliberate commit, walls golden added; human entry 8 asks the owner to confirm); D-15 honoured (the bots' order was the lever, wall costs unchanged, 133 measurements); D-12 honoured and failed by measurement (the budget was not raised); D-10's on-screen bar met.

### Key Link Verification

34 of 34 links from the 11 plans' `key_links` are verified by `gsd-tools verify.key-links`. The ones that carry the phase:

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `EnemySystem.step` | `Pathing` (`first_blocking`, `is_sealed`, `decision()`, `march_step`) | the pathing facade passed into the step | WIRED | enemy_system.gd lines 31, 156-159, 324-416; NightSim builds `Pathing.new(map, _walls)` (night_sim.gd line 48) |
| `SquadSystem` | `Pathing.walk_step` and the goal cache | squads walk through gaps | WIRED | squad_system.gd lines 222, 632; test_wall_detour |
| `WallSystem` | dawn restore and `walls_restored` before the payout | `restore_all()` in the dawn sequence | WIRED | test_wall_dawn 5/5 |
| `EnemyViews` | `CrowdBatch` per archetype | batches added as children | WIRED | enemy_views.gd lines 261-299 |
| `CrowdOverlaySections` / `NightOverlaySections` | `FlowFieldGizmo` / `EnemyPathGizmo` | gizmos added under the map root | WIRED | ui/overlay/crowd_overlay_sections.gd line 37, night_overlay_sections.gd line 31 |
| `tools/gate_stress.sh` | `GateStress` and CI | `GATE_OK` printed, the same step in ci.yml | WIRED | re-run by me; CI line from the orchestrator |
| `tools/stress.sh` | `FrameReport` | three runs, the median published | WIRED | produced 04-FRAME-REPORT.md |

### Requirements Coverage

Every ID from the plans' `requirements:` is accounted for against REQUIREMENTS.md, and REQUIREMENTS.md maps no other ID to Phase 4, so none is orphaned.

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| BLDG-10 | 04-04, 04-05, 04-10, 04-11 | Walls and barricades that block enemy movement and upgrade linearly in health | SATISFIED (REQUIREMENTS.md: Complete, line 41 and 205) | Criterion 1 evidence: wall.tres 2 / 4 / 6 gold and 30 / 60 / 90 health, four runs on the prototype map, blocking and break/restore tested. Feel of worth and tiers is human entry 1 |
| ENMY-04 | 04-06, 04-07, 04-08, 04-10, 04-11 | Enemies path around or through defenses without jamming indefinitely | SATISFIED (REQUIREMENTS.md: Complete, lines 74 and 229) | Criterion 2 evidence: GATE_OK 300 of 300, stuck 0, break-or-detour tests, the walls golden. Feel and the overlay's legibility are human entries 2, 3, 6, 9 |
| PLAT-01 | 04-01, 04-02, 04-03, 04-09, 04-11 | 60 fps on GTX 970-class hardware during the largest battles | **NOT SATISFIED** (REQUIREMENTS.md: Pending, line 130 unchecked and line 261; I did not change it) | The batched rendering and exact-preserving crowd step shipped; the stress-night budget is missed by measurement (p95 37.04 ms against 8.0 ms). Gap entry in the frontmatter |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| EnemyViews / UnitViews / ProjectileVfx batches | instance transforms, flash, bar ratio | the simulation's read view and event bus (`previous_position_of(id).lerp(position_of(id), alpha)`, `SimEvents`) | yes: the 300-enemy and 50-unit counts in the frame report are counted from drawn positions inside the camera frustum | FLOWING |
| Debug overlay Walls / Field / Crowd rows | segment counts, field arrows, stuck flags | `WallSystem`, `Pathing.castle_field()`, `StuckTracker` getters | yes: rows pinned by test_debug_overlay_crowd_sections against a real night | FLOWING |
| WallViews | segment state, tier look, rubble | `WallSystem` signals (`wall_damaged`, `wall_segment_broken`, `walls_restored`) recorded in `SimRecorder.HANDLED` | yes: test_wall_views and the walls screenshots | FLOWING |
| Wall plot hold label | tier, segment count, health per segment | `BuildSpotDef.wall_run` and the tier data | yes: 'Wall II / 12 segments, 60 health each' read in the walls_day capture (orchestrator) | FLOWING |

### Behavioral Spot-Checks and Replays

See 'What I ran and read'. The state-transition and ordering truths of the phase each have a named passing test I re-ran: a break emits once and a broken segment stays broken until dawn (test_wall_system 17/17), dawn restore is once, idempotent and ordered before the payout (test_wall_dawn 5/5), the rebuild happens at most once per step (plan 04-06; test_flow_field and test_wall_detour green), the decision runs on its own staggered tick and returns to 'never' with nobody near (test_wall_decision 12/12), and the stuck tracker flags at exactly 90 updates and starts over when a target appears (test_stuck_tracker 11/11). The one invariant with no direct test is the give-up rule (`behavior_unverified: 1`, above).

### Probe Execution

No `probe-*.sh` is declared by the phase plans and none exists under `scripts/`: SKIPPED. (The gate stress and the replays above are the phase's runnable checks and were run.)

### Anti-Patterns Found

None. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in the 140 non-planning files the phase changed; no stub artifact. One observation, not a finding: the stress-night camera at 119.5 m draws the crowd smaller than in play, which the report discloses (a small fragment-cost trim).

## Code-review findings (13 OPEN, 0 FIXED)

04-REVIEW-DISPOSITION.md on disk: `open: 13`, `total: 13`, every row `open`. 04-REVIEW.md: `status: issues_found`, 0 critical, 7 warning, 6 info, 208 files reviewed (68 `.uid` files not analysed). These are committed facts carried here; I did not re-review the code and did not change any disposition.

| ID | Severity | Title | Disposition |
|---|---|---|---|
| WR-01 | warning | MIN_GAP_METRES (3 m) does not keep a gap routable on the 2 m grid; the documented guarantee is wrong (latent data trap; shipped 4 m gaps are safe) | open |
| WR-02 | warning | A circle resting exactly on a wall is reported as blocked by the wall behind it (no tangency epsilon in `first_blocking`) | open |
| WR-03 | warning | An enemy outside the nav grid counts as walled off from the castle | open |
| WR-04 | warning | `WallValidation` never checks that a wall plot's tiers have health | open |
| WR-05 | warning | `tools/stress.sh` accepts `--duration=08` and then dies in bash arithmetic; `STRESS_EXTRA_TIMEOUT_S` is evaluated as arithmetic | open |
| WR-06 | warning | Balance acceptance for the wall bots passes whether or not walls were ever bought or mattered | open |
| WR-07 | warning | `test_wall_tracer_scene` bounds a night by wall-clock time | open |
| IN-01 | info | Hot-path allocations in the enemy phase, with the concrete fixes | open |
| IN-02 | info | `segments_near` cost grows with the square of the query reach in `first_blocking` | open |
| IN-03 | info | `UnitViews.MAX_VIEWS` (256) is smaller than the simulation can field | open |
| IN-04 | info | The nav grid ignores the king's radius | open |
| IN-05 | info | Key-packing code is copied into six classes | open |
| IN-06 | info | `frame_report_cli._write` can leave a file handle open on a partial failure | open |

How they touch this report: none contradicts a verified roadmap truth on the shipped data (WR-01, WR-02, WR-03 and WR-04 concern authored or edge geometry; WR-06 matches the 'bots buy walls late' warning above and weakens how much the D-14 balance check proves; WR-07 is a CI flake risk). IN-01 and IN-02 are performance levers that overlap the PLAT-01 gap and should be folded into its plan. 04-SECURITY.md: `status: verified`, `threats_open: 0`, 30 threats at ASVS L1 (orchestrator-run at grep depth, no auditor subagent); WR-05's shell-arithmetic finding is a tools-only hardening note that the register did not carry.

## Human Verification

The structured list in the frontmatter has 13 entries, each pointing at 04-PLAYTEST-GATE.md for the play instructions (build/windows/Duskhold.exe from a8c57ab, or the editor binary command in the packet; the stress night only from the editor binary). They are, in order: walls worth their gold and readable by tier; gates funnelling into the towers; break-or-go-around and breach readability; squads and the king getting round walls; the stress night's smoothness and crowd legibility; the drawn field and two-column overlay; nights still tense with walls; the D-14 reading; the 04-07 give-up rule (the behavior-unverified truth); the wall-break rebuild hitch; the PLAT-01 route; the GTX 970 transfer (insufficient_spec); and the 25 assumptions with the Phase 5 fix list. The owner's decision on entry 11 is the input the gap plan needs.

## Gaps Summary

One gap blocks the phase goal and it is the one the orchestrator and the owner already know: ROADMAP criterion 3 / PLAT-01 is not met (median-run p95 37.04 ms against 8.0 ms, about 43 fps at 300 enemies, 50 units and 239 or more arrows; the simulation step is the cost, the renderer is not). The batches, the exact-preserving crowd step, the walls, the flow field and the gate are in and replay-identical; what is missing is a faster enemy and wall step, or a budget the owner documents. The recorded route is a profiling-driven gap plan after `/gsd-verify-work 4` (GDExtension, a documented higher budget, or a GDScript optimisation plan), seeded by the step profile in 04-FRAME-REPORT.md (enemies 15.6 ms of 22.2 ms; target choice 7.5, push-apart 3.7, walls 8 to 10) and by review IN-01 and IN-02. Beyond that: 13 code-review findings are open, 13 owner judgements wait on the gate that has not run, and one invariant (the give-up rule) is pinned only by its effect. If any file in the covered list changes, re-run `verification.status` to refresh the fingerprint.

---

_Verified: 2026-10-16T21:04:00Z_
_Verifier: Claude (gsd-verifier)_
