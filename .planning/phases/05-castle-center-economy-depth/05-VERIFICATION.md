---
phase: 05-castle-center-economy-depth
verified: 2026-10-26T00:21:48Z
status: gaps_found
score: "4/4 roadmap success criteria verified in code, tests and replays; 166/171 plan truths verified (107 of 111 first-run truths carried and re-checked where the round moved them, 59 of 60 gap-round truths of plans 05-13 to 05-24), 1 failed (partial: 05-19 truth 1, two tests that fell nothing after the rescale, test-only), 1 pending (05-12 truth 2: no CI run covers the round until it is pushed), 3 insufficient_spec (05-12's backstop truths, now human items 1, 2, 3 and 5 below); 9/9 requirement IDs have implementation evidence; 6 owner-judgement items remain, 1 gap (low severity, test files only)"
must_haves:
  roadmap_truths: 4
  roadmap_truths_verified: 4
  roadmap_truths_failed: 0
  plan_truths_declared: 171
  plan_truths_declared_note: "111 from plans 05-01 to 05-12 (108 quoted plus the three `verification: backstop` statements of 05-12) and 60 from plans 05-13 to 05-24 (6, 5, 5, 5, 4, 3, 2, 5, 5, 8, 7, 5)"
  plan_truths_verified: 166
  plan_truths_failed: 1
  plan_truths_pending: 1
  plan_truths_pending_note: "05-12 truth 2 (the latest CI run on the branch is for HEAD and green, with the REPLAY_OK, GATE_OK and screenshot lines): the round is not pushed (origin 570ff8d), so no CI run covers HEAD; the orchestrator pushes after this report and the next verification reads that run"
  plan_truths_insufficient_spec: 3
  plan_artifacts_checked: "92/92 by gsd-tools verify artifacts over all 24 plans (first run 53, gap round 39: 4, 3, 3, 3, 3, 3, 2, 3, 5, 5, 3, 2), re-run by me; no tool miss"
  plan_key_links_checked: "55/58 by the tool over all 24 plans (first run 32/32, gap round 23 of 26); the 3 misses are tool artefacts, each verified by reading the code (see Key Link Verification): 05-15 (regex special characters in the pattern), 05-20 (the all-digit pattern 12000 is coerced to a number by the tool's frontmatter parser and its pattern compiler then rejects it as empty), 05-21 (a pattern the tool's regex engine rejects)"
  prohibitions_declared: 47
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass. 22 from 05-01 to 05-12 (carried, no violation found) and 25 from 05-13 to 05-24 (3, 2, 2, 2, 1, 2, 1, 2, 2, 2, 3, 3). My reading found no violation of the 25 new ones: no golden input changed (`git diff --quiet ce3fcea -- tests/golden` exits 0, and the seven golden fixture resources are untouched), no .gd file outside the plans' lists changed, no PINS table or digest edited in the four *_pins scripts, no gold number moved, no bar constant lowered, no push (origin still 570ff8d, branch 62 ahead). The process prohibitions (no push or gh) are taken from `git rev-parse origin/...` and the SUMMARYs"
  requirement_ids: 9
  requirement_ids_satisfied: 9
  requirement_ids_failed: 0
  requirement_ids_orphaned: 0
covered_files:
  - .claude/CLAUDE.md
  - .github/workflows/ci.yml
  - .planning/phases/05-castle-center-economy-depth/05-01-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-01-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-02-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-02-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-03-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-03-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-04-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-04-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-05-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-05-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-06-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-06-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-07-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-07-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-08-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-08-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-09-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-09-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-10-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-10-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-11-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-11-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-12-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-12-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-13-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-13-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-14-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-14-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-15-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-15-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-16-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-16-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-17-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-17-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-18-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-18-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-19-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-19-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-20-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-20-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-21-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-21-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-22-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-22-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-23-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-23-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-24-PLAN.md
  - .planning/phases/05-castle-center-economy-depth/05-24-SUMMARY.md
  - .planning/phases/05-castle-center-economy-depth/05-BALANCE-REPORT.md
  - .planning/phases/05-castle-center-economy-depth/05-CONTEXT.md
  - .planning/phases/05-castle-center-economy-depth/05-DISCUSSION-LOG.md
  - .planning/phases/05-castle-center-economy-depth/05-PATTERNS.md
  - .planning/phases/05-castle-center-economy-depth/05-PLAYTEST-GATE.md
  - .planning/phases/05-castle-center-economy-depth/05-RESEARCH.md
  - .planning/phases/05-castle-center-economy-depth/05-REVIEW-DISPOSITION.md
  - .planning/phases/05-castle-center-economy-depth/05-REVIEW.md
  - .planning/phases/05-castle-center-economy-depth/05-SECURITY.md
  - .planning/phases/05-castle-center-economy-depth/05-UAT.md
  - .planning/phases/05-castle-center-economy-depth/05-UI-REVIEW.md
  - .planning/phases/05-castle-center-economy-depth/05-VALIDATION.md
  - ASSETS.md
  - assets/first_party/card_icons/arrow_storm.svg
  - assets/first_party/card_icons/commander.svg
  - assets/first_party/card_icons/engineers.svg
  - assets/first_party/card_icons/golden_age.svg
  - assets/first_party/card_icons/headsmans_edge.svg
  - assets/first_party/card_icons/iron_discipline.svg
  - assets/first_party/card_icons/masons.svg
  - assets/first_party/card_icons/master_builders.svg
  - assets/first_party/card_icons/prosperity.svg
  - assets/first_party/card_icons/royal_training.svg
  - assets/first_party/card_icons/war_horns.svg
  - assets/first_party/card_icons/warded_mail.svg
  - data/abilities/arrow_storm.tres
  - data/abilities/commander.tres
  - data/abilities/engineers.tres
  - data/abilities/golden_age.tres
  - data/abilities/headsmans_edge.tres
  - data/abilities/iron_discipline.tres
  - data/abilities/masons.tres
  - data/abilities/master_builders.tres
  - data/abilities/prosperity.tres
  - data/abilities/royal_training.tres
  - data/abilities/war_horns.tres
  - data/abilities/warded_mail.tres
  - data/buildings/archery_range.tres
  - data/buildings/barracks.tres
  - data/buildings/castle_center.tres
  - data/buildings/field.tres
  - data/buildings/fishing_harbor.tres
  - data/buildings/gold_mine.tres
  - data/buildings/house.tres
  - data/buildings/mill.tres
  - data/buildings/shrine.tres
  - data/buildings/tower.tres
  - data/buildings/wall.tres
  - data/enemies/grunt.tres
  - data/enemies/ranged.tres
  - data/king/king.tres
  - data/king/sword.tres
  - data/maps/prototype_map.tres
  - data/units/archer.tres
  - data/units/footman.tres
  - docs/STAT_MODIFIERS.md
  - input/build_hold_controller.gd
  - input/card_picker.gd
  - input/command_key_controller.gd
  - presentation/buildings/building_view_catalog.tres
  - presentation/buildings/building_views.gd
  - presentation/buildings/models/castle_center_t2.tscn
  - presentation/buildings/models/castle_center_t3.tscn
  - presentation/buildings/models/castle_center_t4.tscn
  - presentation/buildings/models/field_t1.tscn
  - presentation/buildings/models/fishing_harbor_t1.tscn
  - presentation/buildings/models/fishing_harbor_t2.tscn
  - presentation/buildings/models/gold_mine_t1.tscn
  - presentation/buildings/models/mill_t1.tscn
  - presentation/buildings/models/mill_t2.tscn
  - presentation/buildings/models/mill_t3.tscn
  - presentation/buildings/models/shrine_t1.tscn
  - presentation/environment/pond_view.gd
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/units/unit_views.gd
  - presentation/vfx/projectile_vfx.gd
  - project.godot
  - simulation/buildings/building_system.gd
  - simulation/buildings/choice_ledger.gd
  - simulation/castle/castle_state.gd
  - simulation/commands/build_intent.gd
  - simulation/commands/build_requirements.gd
  - simulation/commands/command_processor.gd
  - simulation/defs/build_requirement_validation.gd
  - simulation/defs/build_spot_def.gd
  - simulation/defs/building_def.gd
  - simulation/defs/building_tier_def.gd
  - simulation/defs/castle_validation.gd
  - simulation/defs/choice_def.gd
  - simulation/defs/choice_validation.gd
  - simulation/defs/economy_validation.gd
  - simulation/defs/map_config.gd
  - simulation/economy/income_state.gd
  - simulation/events/sim_events.gd
  - simulation/king/king_state.gd
  - simulation/night/castle_attack.gd
  - simulation/night/night_sim.gd
  - simulation/night/tower_system.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - simulation/squads/squad_system.gd
  - simulation/squads/unit_system.gd
  - simulation/stats/stat_ids.gd
  - simulation/stats/stat_modifier_def.gd
  - simulation/stats/stat_stack.gd
  - simulation/walls/wall_system.gd
  - tests/e2e/e2e_support.gd
  - tests/e2e/test_build_denied.gd
  - tests/e2e/test_building_models.gd
  - tests/e2e/test_card_digit_handover.gd
  - tests/e2e/test_card_mouse.gd
  - tests/e2e/test_card_row.gd
  - tests/e2e/test_castle_gate.gd
  - tests/e2e/test_castle_three_picks.gd
  - tests/e2e/test_castle_views.gd
  - tests/e2e/test_gold_mine_scene.gd
  - tests/e2e/test_harbor_scene.gd
  - tests/e2e/test_king_knockout.gd
  - tests/e2e/test_king_ride.gd
  - tests/e2e/test_king_widget.gd
  - tests/e2e/test_mill_fields_scene.gd
  - tests/e2e/test_order_markers.gd
  - tests/e2e/test_rebuilt_economy_marker.gd
  - tests/e2e/test_shrine_look.gd
  - tests/e2e/test_shrine_scene.gd
  - tests/e2e/test_spot_label.gd
  - tests/e2e/test_squad_strip.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/e2e/test_wall_views.gd
  - tests/fixtures/fixture_map_castle.tres
  - tests/fixtures/fixture_map_gate.tres
  - tests/fixtures/fixture_map_one_night.tres
  - tests/fixtures/fixture_map_replay_economy.tres
  - tests/fixtures/fixture_map_shrine.tres
  - tests/fixtures/fixture_map_squads.tres
  - tests/fixtures/fixture_map_walls.tres
  - tests/fixtures/fixture_map_walls_gap.tres
  - tests/golden/economy.json
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_report.gd
  - tests/integration/test_balance_report_castle.gd
  - tests/integration/test_build_flow.gd
  - tests/integration/test_dawn_payout_economy.gd
  - tests/integration/test_economy_destroyed.gd
  - tests/integration/test_economy_replay_golden.gd
  - tests/integration/test_field_independence.gd
  - tests/integration/test_shrine_destroyed.gd
  - tests/integration/test_shrine_night.gd
  - tests/integration/test_squad_lifecycle.gd
  - tests/integration/test_stat_tracer.gd
  - tests/integration/test_upgrade_flow.gd
  - tests/integration/test_wall_dawn.gd
  - tests/integration/test_wall_detour.gd
  - tests/support/sim_signals.gd
  - tests/unit/test_ability_data.gd
  - tests/unit/test_bot_card_picks.gd
  - tests/unit/test_bot_defers_locked.gd
  - tests/unit/test_build_choice.gd
  - tests/unit/test_build_requirement_validation.gd
  - tests/unit/test_build_requirements.gd
  - tests/unit/test_build_spot.gd
  - tests/unit/test_card_icons.gd
  - tests/unit/test_card_resolution.gd
  - tests/unit/test_card_row_model.gd
  - tests/unit/test_castle_attack.gd
  - tests/unit/test_castle_data_contract.gd
  - tests/unit/test_castle_label.gd
  - tests/unit/test_castle_tiers.gd
  - tests/unit/test_choice_validation.gd
  - tests/unit/test_dawn_rebuild.gd
  - tests/unit/test_debug_overlay_crowd_sections.gd
  - tests/unit/test_debug_overlay_night_sections.gd
  - tests/unit/test_debug_overlay_squad_section.gd
  - tests/unit/test_economy_data_contract.gd
  - tests/unit/test_economy_overlay_sections.gd
  - tests/unit/test_economy_validation.gd
  - tests/unit/test_enemy_targeting.gd
  - tests/unit/test_field_route_pins.gd
  - tests/unit/test_fishing_harbor.gd
  - tests/unit/test_gate_data_contract.gd
  - tests/unit/test_glyph_resolver.gd
  - tests/unit/test_goal_field_cache.gd
  - tests/unit/test_gold_mine.gd
  - tests/unit/test_harbor_exposure.gd
  - tests/unit/test_input_capabilities.gd
  - tests/unit/test_input_map.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_map_validate_castle.gd
  - tests/unit/test_melee_breaks_to_target.gd
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_mill_fields.gd
  - tests/unit/test_nav_grid.gd
  - tests/unit/test_nav_layout_pin.gd
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_playtest_strategies_castle.gd
  - tests/unit/test_pond_layout.gd
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_prototype_map_economy.gd
  - tests/unit/test_prototype_map_walls.gd
  - tests/unit/test_replay_cli_args.gd
  - tests/unit/test_run_stats.gd
  - tests/unit/test_shot_list.gd
  - tests/unit/test_shot_list_gate.gd
  - tests/unit/test_shrine.gd
  - tests/unit/test_shrine_plots.gd
  - tests/unit/test_shrine_synergy.gd
  - tests/unit/test_shrine_validation.gd
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spot_label_locked.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_squad_archers.gd
  - tests/unit/test_squad_respawn.gd
  - tests/unit/test_stat_combined.gd
  - tests/unit/test_stat_consumers.gd
  - tests/unit/test_stat_contract.gd
  - tests/unit/test_stat_refresh.gd
  - tests/unit/test_stat_stack.gd
  - tests/unit/test_stress_map_data.gd
  - tests/unit/test_structure_decision_pins.gd
  - tests/unit/test_unit_fill_pins.gd
  - tests/unit/test_wall_data_contract.gd
  - tests/unit/test_wall_decision.gd
  - tests/unit/test_wall_geometry_pins.gd
  - tests/unit/test_wall_solids.gd
  - tests/unit/test_weapon_def.gd
  - tools/playtest.sh
  - tools/replay.sh
  - tools/replay/balance_report.gd
  - tools/replay/playtest_bot.gd
  - tools/replay/playtest_strategies.gd
  - tools/replay/replay_driver.gd
  - tools/replay/replay_scenarios.gd
  - tools/replay/sim_recorder.gd
  - tools/screenshot.sh
  - tools/screenshot/shot_army_scenarios.gd
  - tools/screenshot/shot_crowd_scenarios.gd
  - tools/screenshot/shot_economy_scenarios.gd
  - tools/screenshot/shot_scenarios.gd
  - tools/stress/data/stress_barracks.tres
  - tools/stress/data/stress_footman.tres
  - tools/stress/data/stress_grunt.tres
  - tools/stress/data/stress_tower.tres
  - tools/stress/data/stress_wall.tres
  - tools/stress/step_attribution.gd
  - tools/stress/step_bench.gd
  - tools/stress/stress_map.tres
  - tools/stress/stress_night.gd
  - ui/hud/dawn_no_income_marker.gd
  - ui/hud/king_widget.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
  - ui/overlay/economy_overlay_sections.gd
  - ui/overlay/stat_overlay_sections.gd
  - ui/world/card_row.gd
  - ui/world/card_row_model.gd
  - ui/world/spot_label.gd
  - ui/world/spot_label.tscn
  - ui/world/spot_label_model.gd
covered_digest: "v2:sha256:af295458d321fe2b94e580c94e29d86fe60f3cae7f211e8a492b6d647838f3c4"
behavior_unverified: 0
overrides_applied: 0
behavior_unverified_items: []
re_verification:
  previous_status: human_needed
  previous_score: "108/111 plan truths, 4/4 roadmap criteria, 10 owner items"
  gaps_closed:
    - "UAT G-05-2 (cards lose their percent to integer rounding; Prosperity too weak): every health and damage number is x100 in the shipped data, the seven non-golden fixtures and the stress data; the three cards recut (Prosperity +2, Golden Age +4, Headsman's Edge x1.25); the recurrence guard test_card_resolution (8 tests) lands. Code-level truths all verified; the owner's 're-judge every card' remains a human item"
    - "UAT G-05-7 (Harbor risk-free): harbor_1 and its pond moved beside the west road, health 1400 / 2000, exposure pinned by test_harbor_exposure and seen in the shipped full_idle replay (building_damaged harbor_1 events). The owner's 'worth its risk' judgement remains a human item"
  gaps_remaining:
    - "05-19 truth 1 (partial): tests/integration/test_squad_lifecycle.gd and tests/unit/test_goal_field_cache.gd no longer fell what they fell before the rescale"
  regressions: []
gaps:
  - truth: "05-19 truth 1: The tests that fell a shipped building, wall segment or unit with a blow of their own fell it again at the x100 scale (a Barracks (4000) and a wall segment (3000) fall to 100000 instead of 1000 ...), so every test checks what it checked before the rescale"
    status: partial
    reason: "Two tests outside plan 05-19's seven-script list still fell a shipped building or wall segment with the old blow, so after the x100 rescale they fell nothing and pass vacuously. Plan 05-19's objective is the universal 'make every test that fells a shipped building, wall segment or unit with its own blow fell it again'; its list was built from the scripts that FAILED, and these two pass. Severity low: test files only, no shipped code, data, golden, replay or balance pin is affected, and the rebuild stays covered at unit level by test_squad_respawn (Barracks felled with 100000 and rebuilt, the night trickle resumes), but none of its restore_for_dawn tests involves a fallen building, so the dawn order of rebuild before restore is now covered only by the army golden replay on its frozen inputs, with no live unit or integration test. Both are already recorded open as WR-07 and IN-12 in 05-REVIEW-DISPOSITION.md, so the owner's standing fix pass (`/gsd-code-review 5 --fix --all`) closes the same two edits; a one-task gap plan would close them equally"
    artifacts:
      - path: "tests/integration/test_squad_lifecycle.gd"
        issue: "KILL_DAMAGE is 1000 (line 12); test_an_emptied_squad_whose_building_fell_is_rebuilt_and_restored_at_dawn hits the shipped Barracks (fixture_map_squads.tres loads data/buildings/barracks.tres, tier I 4000) for 1000, so it is never destroyed. 'dawn rebuilt the barracks', '_stood_at_restore' and 'the squad is full again' hold with no fall and no rebuild in the path: RunManager calls rebuild_destroyed() then restore_for_dawn() at every dawn, so the restore still runs and refills the squad, and the test no longer checks that the building is back up before its squad is restored; nothing asserts the fall"
      - path: "tests/unit/test_goal_field_cache.gd"
        issue: "line 83 damage_segment(1, 1000) against the shipped 3000-health wall leaves 2000, so the grid rebuild re-rasterises the same wall; the assertions pass because NavGrid.rebuild bumps its version unconditionally, so invalidation after a real wall change is no longer checked"
    missing:
      - "test_squad_lifecycle: fell the Barracks with its own health (damage_building(BARRACKS, max_health_of(BARRACKS))) and assert is_destroyed before dawn; keep KILL_DAMAGE for the unit blows only (the fix of WR-07)"
      - "test_goal_field_cache: break the segment with 100000 (or max_health_of(1)) so the rebuild sees a real change (the fix of IN-12)"
advisory:
  - finding: "tools/stress/step_bench.gd CASTLE_HEALTH (raised to 1000000000 by plan 05-16) never reaches the castle: the prototype castle plot is built to tier II, whose 10000 replaces it (WR-06, cause predates the round)"
    category: other
    reason: "Plan 05-16's truth is met as written (the constant is x100) and the default bench run never reaches the castle's fall; only a long --warmup/--steps run could read too-low timings. Tools-only; the review's two-line fix is open"
    evidence_status: "read from the code by the reviewer and by me; no failing run"
  - finding: "castle_tier_four and crowd_stress_night shots press zoom_out without _drop_pad_zoom_events, so a connected pad can leave them at the default zoom (WR-08)"
    category: other
    reason: "The two PNGs the UI audit read may be un-zoomed on a machine with a pad connected; the shipped game is unaffected and the presentation points were ruled 'revisit in phase 8'"
    evidence_status: "none provided beyond the review's reading of the call sites"
  - finding: "StatStack clamps base plus flat to MAX_ABS_BASE 100000 when a stat has a modifier; the largest shipped base is castle tier IV's 20000 (five times headroom)"
    category: architectural
    reason: "Phase 6's heavier enemies or bosses with a base above 100000 would silently clamp under a modifier; test_card_resolution test 7 pins the bound over every shipped base so a future data change fails loudly instead"
    evidence_status: "none provided (no shipped base is near the bound)"
human_verification:
  - name: "Every card at a tier is a viable pick after the rescale and the recuts (UAT test 2, G-05-2)"
    requirement: "BLDG-08"
    test: "On the fresh build/windows/Duskhold.exe (exported 2026-10-25, instructions in 05-PLAYTEST-GATE.md, 'Gap round' section) take different cards over two or three runs at every tier you reach (Royal Training, Commander, Masons, Prosperity; Headsman's Edge, Engineers, War Horns, Warded Mail; Iron Discipline, Arrow Storm, Master Builders, Golden Age) and read the Stats section of the F3 overlay. Rule on the nine cards the bots could not judge (Commander and the eight tier III and IV cards, set by arithmetic with no measurement) using the packet's table: Commander keep or change; Headsman's Edge x2 damage at x1.25 (recommended) or the old x1.5 or no slowdown; Engineers keep (recommended) or +34% damage; War Horns, Warded Mail, Iron Discipline, Arrow Storm, Master Builders keep or name a change; Golden Age +4 (recommended), +3 or the old +2"
    expected: "Each card's effect is felt, no card is one you would never take or always take (your words: 'stronger in particular cases but not overly weak even in a case where its not an ideal option'); percentages now land as written (Commander's soldiers hit 125, a grunt dies in 5 blows instead of 6; Warded Mail turns a 200 blow into 150), and you accept or rename or rebalance the nine cards"
    why_human: "Backstop-tier truth (05-12 D-02, G-05-2): whether a card is worth its pick is design taste. The mechanism is verified (every card lands exactly as written at every shipped base: test_card_resolution 8/8, test_ability_data 15/15, run by me) but no bot reaches tiers III and IV (a whole run earns about 26 gold against costs 10 and 16) and the balanced bot fields no squads, so those nine rows are 'owner-judged, no measurement' in 05-BALANCE-REPORT.md"
  - name: "Prosperity's measured shortfall (UAT test 2, G-05-2)"
    requirement: "BLDG-08"
    test: "Buy castle II with Prosperity on a run or two beside runs with Masons, and rule on the packet's four choices: keep +2 (recommended), raise to +3, give Prosperity a second effect beside the gold, or bring Masons' +30% down"
    expected: "Prosperity feels like a real alternative at tier II; or you pick one of the four changes. The measured basis: with only the tier II card swapped the balanced bot wins 8 of 10 with Masons (26.4 gold, 10.6 buildings lost), 6 of 10 with Prosperity +2 (25.4, 14.2) and 6 of 10 with +3 (26.6, 14.2): neither value met the pre-registered rule (at least Masons' gold and at most one win fewer), so +2 shipped"
    why_human: "The pre-registered viability rule failed at both +2 and +3, and the plan's fallback ships +2 and hands the call to the owner (05-23, 05-24). Your G-05-2 requirement was 'every alternative mostly viable'; whether 6 of 10 against 8 of 10 for a tower bot reads as viable, and whether the Harbor's new exposure (which Masons' health helps, the report's unmeasured reading) is the cause, is a judgement and a design choice, not something a test can settle"
  - name: "The day's decisions feel deeper and the game is still fun (UAT test 5, core value, deferred until these fixes)"
    requirement: "BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06"
    test: "Play two or three full runs on the fresh build, climbing the castle with picks and building the new economy (05-PLAYTEST-GATE.md, 'What to re-judge' 2)"
    expected: "The day offers richer gold trade-offs (castle versus defences versus income) without being merely busier, and the night defence stays tense. The bots measured: balanced wins 8 of 10, army_balanced 8 of 10 (value ratio 0.882 against the 0.8 bar), balanced_no_castle 3 of 10, greedy_economy 0, no_build 0, and the bar was not lowered and no bot order moved"
    why_human: "Backstop-tier truth (05-12): fun and depth cannot be measured. I re-ran test_balance_acceptance (17/17) which pins the bar, but the sweep cannot say whether the day feels deeper"
  - name: "The exposed Harbor is worth its risk (UAT test 7, G-05-7)"
    requirement: "ECON-05"
    test: "Build the Fishing Harbor on its new pond beside the west road (-39.93, 25.48), between the first tower and the Gold Mine, and play a few nights with it, trying to defend it by riding out"
    expected: "It feels worth the risk: awkward to defend without being unfair, and you do not lose it so often that the boats never pay; or you ask for another spot (the packet's B, dock facing away from its water, or C, the north road, safe until night 6), a different health (1400 / 2000 now) or a different price. Measured by the bots, which never ride out to defend it (the worst case): built in 9 of 10 balanced games, struck in 7 of those, destroyed 18 times in ten runs; skirmishers notice it from the road and grunts do not; no tower or keep arrow reaches it. In the shipped full_idle replay (seed 1, balanced bot) four enemy hits take it from 1820 to 1020 and it survives"
    why_human: "How awkward it is to defend is a play feel no test asserts: the geometry is pinned (test_harbor_exposure 4/4, with a mutation proof in the SUMMARY) and the strikes happen in the replay, but whether the risk is the owner's 'a bit awkward' or too punishing is the owner's call"
  - name: "The numbers are shown as they are, not divided by 100 (UAT test 2 decision, UI-02, META-08)"
    requirement: "UI-02, META-08, BLDG-08"
    test: "Look at the king's bar (5000 / 5000, 6250 / 6250 with Royal Training), a tower plot ('Range 9.0 · Damage 300'), the castle label ('Health 14000 · Arrow 400 · 3 gold at dawn') and a card's numbers line ('+25% king health, +100 king damage') in the real window"
    expected: "Keep the numbers as they are so the screen and the data agree (recommended, and the choice made in plans 05-17 and 05-20 as a reversible Flagged Assumption); or ask for display-only division by 100 (the screen would read a king of 50 again). Also note whether a label such as 'Range 9.0 · Damage 300' mixing a metre and a x100 damage reads oddly (the UI audit's copywriting note)"
    why_human: "A perception and taste call on how the numbers read at 1280x720; I read hud_king_120, harbor_pond and the Royal Training and Headsman's Edge card crops and the label fits on one line and the card line fits inside its card, but whether the large numbers read well is the owner's"
  - name: "The fresh build hand-off"
    requirement: "UI-02, BLDG-08, ECON-05"
    test: "Launch build/windows/Duskhold.exe (Duskhold.pck and libduskhold_sim.windows.x86_64.dll beside it, exported 2026-10-25 22:08 UTC) on your machine, play a full run, and open 05-PLAYTEST-GATE.md's 'Gap round' section"
    expected: "The build launches and plays a full run; the section's numbers match 05-BALANCE-REPORT.md (the main bot 8 of 10, the army bot 8 of 10, a squad value ratio of 0.88 against the 0.8 bar, the four recorded runs unchanged, 281 test files and 2668 tests); you sign off or list what must land before Phase 6 through /gsd-verify-work 5"
    why_human: "A hand-off: I launched it headless (`build/windows/Duskhold.exe --headless --quit-after 120` started and quit with exit 0 in 2 s; the files are dated after the last non-.planning commit 55180ac), but a full run on the owner's machine is the check"
---

# Phase 5: Castle Center & Economy Depth Verification Report (re-verification after gap-closure round 1)

**Phase Goal:** Day decisions gain real depth. The castle center grows through tiers with run-defining ability picks that gate higher building tiers, and four new economic buildings each pay out on a different income curve. All bonuses stack in one tested order.
**Verified:** 2026-10-26T00:21:48Z
**Status:** gaps_found
**Re-verification:** Yes, after gap closure round 1 (plans 05-13 to 05-24, UAT gaps G-05-2 and G-05-7). The previous report (2026-10-22, human_needed, 108/111) is overwritten. Every number and verdict describes HEAD 2e466a4; nothing outside `.planning/` changed after 55180ac (the last data, test or tool commit of the round), and the fresh export is dated after it.

## Verdict

The phase goal is achieved in the codebase and by measurement, and the gap round did what the owner required. The one finding I count as a gap is minor and test-only: two tests that were never in plan 05-19's list now fell nothing after the x100 rescale and pass vacuously. Per the decision tree (a must-have truth is false in the code) the status is `gaps_found`, with the low severity and the cheap closure stated plainly below. No shipped data, simulation, replay, golden or balance pin is wrong.

What I verified rather than read:

- **The rescale is exact and complete.** `git diff ce3fcea HEAD -U0` over `data/units`, `data/enemies`, `data/king`, `data/buildings`, `data/abilities` and the map shows only: every health and damage line x100 (king 5000; sword 500 and slam 400; footman 1000 and 100; archer 600 and 100; grunt 600 and 200; skirmisher 400 and 200; Tower I 300 and 5000, II 600 and 7000; Shrine 300, 3000 and wake threshold 10000; castle II to IV arrows 300, 400, 500 and health 10000, 14000, 20000; map castle 7000 and arrow 200; walls 3000, 6000, 9000; House 1200, 1800, 2400; Barracks and Archery Range 4000, 6000, 8000; Field 800; Mine 2000; Mill 1500, 2000, 2500; Harbor 1400 and 2000 after its step), Royal Training's flat +1 to +100, the three recuts, and the Harbor's plot and pond lines. A grep of every `max_health`, `attack_damage`, `slam_damage`, `wake_threshold_hp`, `castle_max_health` and `castle_attack_damage` line in `data/` leaves no unscaled health or damage number. No gold number, range, interval, percent or def script default moved: the only non-test code changes of the round are `ui/hud/king_widget.gd` (the label width constant and doc), doc comments in `ui/world/spot_label_model.gd` and `ui/overlay/economy_overlay_sections.gd`, and tools-only files.
- **The four goldens are byte-identical and the frozen inputs are untouched.** I re-ran smoke 2599c7c2 (703 ticks), army f7a967ed (1353), walls bfb05fc7 (1961) and economy f4b98093 (1842) with `--twice --expect-file`: four `REPLAY_OK`. `git diff --quiet ce3fcea -- tests/golden` exits 0 and the seven golden fixture resources do not appear in the diff; the seven non-golden fixtures changed by exactly their health and damage lines.
- **full_idle and the gate stress reproduce the recorded values.** `full_idle --twice`: `outcome=won ticks=6993 digest=c68254cda9eb986d0dcb40a3ac83d29d23f24444ed525fcfc025c9d2c656c441`, the digest 05-BALANCE-REPORT.md records. `gate_stress.sh --twice`: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=eb319f092e059b341cd186ce3c75306e1703a46913310d2f5b563119143efaa8`.
- **The bar holds without being lowered.** I ran `test_balance_acceptance` myself: 17 of 17 (the playtest sweep itself was not re-run). Its diff against ce3fcea is `GRUNT_MAX_HEALTH` 6 to 600, a test rename and header paragraphs; every bar constant (BALANCED 7 to 8, ARMY_BALANCED 7 to 8, SQUAD_VALUE_BAR 0.8, the lost-seed lists, the earliest castle day) is unchanged.
- **Sixty-eight test scripts I ran by name all passed** (`bash tools/test.sh -gselect=<name>.gd`, one at a time): the gap round's new and re-pinned contracts and labels, the PLAT-01 pin scripts, the wall and squad suites, the Shrine, Harbor, stat and card suites, the e2e king widget, knockout, squad strip, order markers, Harbor scene and card row. Lint: 448 files unchanged, no problems. The full suite (281 scripts, 2668 tests) is the orchestrator's measurement and was not re-run by me.

## What I ran and read

| Check | Command or read | Result |
|---|---|---|
| Plan artifacts and key links | `gsd-tools verify artifacts` and `verify key-links` on all 24 plans | 92/92 artifacts; links 55 of 58 by the tool, the three misses read by me and wired (Key Link Verification) |
| Golden smoke, army, walls, economy, twice each | `bash tools/replay.sh --scenario=<s> --twice --expect-file=tests/golden/<s>.json` | `REPLAY_OK` x4: 2599c7c2 (703), f7a967ed (1353), bfb05fc7 (1961), f4b98093 (1842) |
| full_idle, twice (unpinned by design) | `bash tools/replay.sh --scenario=full_idle --twice` | won, 6993 ticks, c68254cda9eb986d0dcb40a3ac83d29d23f24444ed525fcfc025c9d2c656c441 |
| Gate stress, twice | `bash tools/gate_stress.sh --twice` | `GATE_OK` with the pre-round statistics, digest eb319f09 |
| Exact-x100 check | `git diff ce3fcea HEAD -U0` over the data files and the stress data; grep of every health and damage line | only x100 lines, the three recuts, Royal Training +100, the Harbor and pond lines; no unscaled number |
| Frozen inputs | `git diff --quiet ce3fcea -- tests/golden`; `git diff ce3fcea HEAD --name-only -- tests/fixtures` | exit 0; only castle, gate, one_night, shrine, squads, walls, walls_gap |
| Bar re-pin | `bash tools/test.sh -gselect=test_balance_acceptance.gd` | 17/17; bar constants unchanged in the diff |
| PLAT-01 pins unedited | `git diff ce3fcea HEAD -U0` on the four `*_pins` scripts, grep for digests, PINS, frames | no digest or PINS line changed; test_structure_decision_pins 8/8, test_unit_fill_pins 4/4, test_field_route_pins 9/9, test_wall_geometry_pins 7/7, test_enemy_fill_pins 5/5, test_projectile_fill_pins 4/4 |
| 68 named test scripts | `bash tools/test.sh -gselect=...` one by one | all passed (named in the sections below) |
| Lint | `bash tools/lint.sh` | `448 files would be left unchanged`, `Success: no problems found` |
| Debt markers | grep TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER over the 244 non-md, non-asset files changed since fab9485~1 | none |
| Export | `ls build/windows`; `build/windows/Duskhold.exe --headless --quit-after 120` | Duskhold.exe 109,268,480 bytes, Duskhold.pck, libduskhold_sim.windows.x86_64.dll, dated 2026-10-25 22:08 UTC (after 55180ac); launched headless, exit 0 in 2 s |
| Not pushed | `git rev-parse origin/gsd/phase-01-foundation-day-loop`; `git status -sb` | 570ff8d; branch ahead 62; so no CI run covers the round yet |
| Screenshots read | `screenshots/harbor_pond.png`, `screenshots/hud_king_120.png`, the orchestrator's `rt_tier2_rt_raised_crop.png`, `rt_tier3_he_raised_crop.png`, `rt_after_buy.png` | Harbor on a small pond with its three boats (the scenario captures at POND_DAWNS 3), king label '5000 / 5000'; '9000 / 12000' on one line; Royal Training's raised card shows '+25% king health, +100 king damage' inside the card on two lines; Headsman's Edge shows 'x2 king damage, x1.25 king attack interval'; 'Castle III / Health 14000 · Arrow 400 · 3 gold at dawn' and '6250 / 6250' read clear |

Taken from the orchestrator or the committed evidence without re-running, marked as such: the full suite (281 / 2668, the wave-11 gate at de92f91 and the closing pass of plan 05-24), the playtest sweep (`bash tools/playtest.sh --seeds=10`, PLAYTEST_OK runs=100, plan 05-23), the 05-22 Harbor exposure probe's strike table, the ten shots of plan 05-20, and the regression gate (all 164 Phase 1 to 4 test scripts green in the wave-11 run; nothing outside `.planning/` changed since).

## Goal Achievement

### ROADMAP success criteria (the contract), re-checked after the round

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | At a branching upgrade tier, the player picks one of the offered choice cards (icon, name, short description) with keyboard or mouse. The choice stays locked for the rest of the run | VERIFIED in code and tests; the read and the feel are human item 1 and 5 | Unchanged mechanism (`CardPicker`, `CardRowModel.hit_test`, `ChoiceLedger`, `CommandProcessor` choice_required and bad_choice): test_card_row 12/12, test_build_choice 18/18, test_castle_three_picks 3/3 re-run by me after the rescale. The cards read at the new numbers: Royal Training's raised card shows '+25% king health, +100 king damage' and Headsman's Edge 'x2 king damage, x1.25 king attack interval' inside their cards (my reads of rt_tier2_rt_raised_crop.png and rt_tier3_he_raised_crop.png) |
| 2 | The player can upgrade the castle center through its tiers for more health, choosing one of four run-wide abilities or passives at each tier. Higher building tiers stay locked until the castle reaches the required tier | VERIFIED | `data/buildings/castle_center.tres` now 10000, 14000, 20000 health and 300, 400, 500 arrows above the map's 7000 and 200, dawn income 2, 3, 4, tiers II to IV each with four cards (test_castle_data_contract 8/8, test_castle_tiers 16/16, test_ability_data 15/15, test_card_resolution 8/8). The seven gated top tiers still carry `requires_castle_tier = 2` (test_castle_gate 3/3, test_build_requirements 15/15). After the recuts every card lands as written at every shipped base (the new guard, run by me) |
| 3 | The player can build four new economic buildings (Gold Mine, Mill with Fields, Fishing Harbor, Shrine) on four income curves | VERIFIED | Curves and the economy golden untouched (golden f4b98093 reproduced). The Harbor moved to (-39.93, 25.48) with its pond (-37.71, 31.59) radius 4.5 and health 1400 / 2000 (map lines 191, pond lines, fishing_harbor.tres); test_fishing_harbor 12/12, test_harbor_scene 4/4, test_pond_layout 13/13, test_prototype_map_economy 20/20, test_economy_data_contract 20/20, test_shrine 17/17, test_shrine_synergy 10/10, test_shrine_night 13/13, test_shrine_destroyed 8/8, test_economy_destroyed 5/5, test_economy_replay_golden 9/9 all pass at the scaled numbers (Shrine wake threshold 10000) |
| 4 | Bonuses from building upgrades and castle abilities combine in one fixed, documented order, with single- and combined-modifier tests | VERIFIED | `StatStack` untouched by the round (D-15): `git diff ce3fcea HEAD --name-only` lists no `simulation/` file. test_stat_stack, test_stat_combined 12/12, test_stat_consumers 13/13, test_stat_contract 7/7 pass. The rescale is what lets the formula's one half-up rounding show: at the old bases a +25% on 1 rounded to no change; the new `test_card_resolution` pins every card at every shipped base (negative control: +25% on a base of 1 fails the band, on 100 passes) |

### Gap-round plan must_haves (05-13 to 05-24): 59 of 60 verified, 1 partial

Each plan's truths were checked against the code, data, tests and replays, not the SUMMARYs.

- **05-13 (6 of 6).** The ten shipped data files hold exactly the numbers the truth lists (my diff above); every other line is untouched (the diff shows nothing else); Phase 3 D-07 holds as 100 against 500 and the footman is 1000 against the king's 5000 (a fifth); no `.gd` file changed in the plan (`git diff` shows no simulation or def script change; the def script defaults are 30, 10, 1, 3 and 40 still, so a frozen fixture that omits a field reads what it read); the shipped map validates (test_prototype_map_data 20/20); the four goldens replay identical.
- **05-14 (5 of 5).** The nine remaining data files at x100 and Royal Training +100 (diff above, plus the Harbor's 1400 / 2000 from 05-22 as the truth itself says); only `GRUNT_MAX_HEALTH` is re-pinned in test_balance_acceptance and all bar constants stand (diff read, 17/17 run); full_idle recorded cec3eb71 after the rescale (history) and now c68254cd after the Harbor, both consistent with the report; the goldens identical.
- **05-15 (5 of 5, one tool link miss).** The seven non-golden fixtures carry exactly the numbers listed (my diff of `tests/fixtures`); the four golden fixtures and the king and tuning copies are untouched; test_wall_decision keeps its expected tick counts with `GRUNT_PER_300 = 2000` (12/12), test_wall_dawn 5/5, test_wall_detour 12/12, test_wall_determinism 3/3; the Shrine, castle-tier, squad and build-requirement-validation suites pass.
- **05-16 (5 of 5).** The stress grunt strikes for 200 and the footman for 100; every huge health is 10000000, the tower's real hits 100, the stress castle unarmed (diff of `tools/stress`); KING_HEALTH 10000000 in step_attribution, step_bench and stress_night and the bench castle 1000000000 (as written; see Advisory on WR-06); the gate stress reproduces its crossing statistics with the new digest eb319f09 (re-run by me); the PLAT-01 fill pins pass unedited (test_enemy_fill_pins 5/5, test_projectile_fill_pins 4/4); test_stress_map_data pins HUGE_HEALTH 10000000 (16/16).
- **05-17 (4 of 4).** The contract tests pin the x100 numbers with a G-05-2 header and the labels show them undivided: test_military_data_contract 7/7 (FOOTMAN_DAMAGE 100), test_castle_data_contract 8/8, test_wall_data_contract 7/7, test_economy_data_contract 20/20, test_ability_data 15/15, test_spot_label_model 15/15, test_economy_overlay_sections 18/18, test_castle_label 12/12 (the string 'Health 10000 · Arrow 300 · 2 gold at dawn' is in the test), test_map_validate_castle 14/14, test_weapon_def 10/10; no data, simulation or UI code changed in the plan (the UI diff is doc comments and the widget width belonging to 05-20).
- **05-18 (3 of 3).** The four PLAT-01 pin scripts changed only inputs and header notes: no digest, PINS table, frame or 'most' count line moved in the diff, and `test_structure_decision_pins` freezes the Phase 4 wall health 30, 60, 90 on a `duplicate_deep` copy (the added `PHASE_FOUR_WALL_HEALTH`); the combat tests pass at the scaled numbers (test_castle_attack 14/14, test_enemy_targeting 15/15, test_squad_archers 6/6, test_melee_breaks_to_target 10/10, test_debug_overlay_crowd_sections 12/12).
- **05-19 (1 of 2, partial).** Truth 2 holds (only kill amounts and header notes changed; the still-hurting blows stay: test_dawn_rebuild 15/15, test_run_stats 10/10, test_nav_grid 12/12, test_build_requirements 15/15, test_squad_respawn 14/14 with `damage_building(BARRACKS, 100000)`, test_debug_overlay_squad_section 10/10, test_order_markers 10/10 with KILL_DAMAGE 99900). **Truth 1 is only partly true**; see the next subsection and the gap.
- **05-20 (5 of 5).** The king widget's `LABEL_MIN_WIDTH` is 128.0 and the row spans x 16 to 408 (test_king_widget 16/16 including `test_royal_trainings_king_fits_the_label_without_moving_the_right_edge`, `WIDGET_RIGHT` 408); the screen shows the numbers undivided (my reads: '5000 / 5000' in harbor_pond.png, '9000 / 12000' in hud_king_120.png, '6250 / 6250' and the castle label in rt_after_buy.png); the hurt-king and crowd shots moved to the scaled numbers (`KING_120_HEALTH 12000`, test_shot_list 20/20 and test_shot_list_gate 3/3 keep the 44 names and order); test_king_knockout 5/5 and test_squad_strip 16/16 pass; the doc examples show the scaled numbers and no code line changed in `spot_label_model.gd` or `economy_overlay_sections.gd` (diff read). The ten shots' per-PNG review lines are in the SUMMARY (I read the three in the table above).
- **05-21 (5 of 5).** Prosperity `value = 2`, Golden Age income `value = 4` beside its +25% shrine damage, Headsman's Edge x2 damage and `value = 125` on the interval, only these three card files changed in data; every percent and multiplier card lands as written (test_card_resolution 8/8: exact value from the documented formula, a 0.5 to 1.5 band of the written effect, the Shrine synergy case, every integer health and damage base between 100 and `StatStack.MAX_ABS_BASE`, the negative control at the old scale); test_castle_label reads the Prosperity value from data and Headsman's Edge's line 'x2 king damage, x1.25 king attack interval' (12/12, and the raised card in my read). full_idle unchanged by the recut (no bot picks the three) per the report's table.
- **05-22 (8 of 8).** harbor_1 at (-39.93, 0, 25.48) with the pond at (-37.71, 31.59) radius 4.5 (map lines); the Harbor 6.50 m from the pond centre and the footprint rule is `body_radius` read from the shipped building (test_pond_layout 13/13); skirmishers notice it and grunts do not, no tower reaches it even at Tower II through Engineers and the keep's arrow does not reach it even through Arrow Storm (test_harbor_exposure 4/4, whose negative controls show the checks do cover a point beside a tower or the keep); health 1400 and 2000 with every other economy number as shipped (diff); the pond rules hold (MapConfig.validate and EconomyValidation clean: test_prototype_map_data 20/20, test_economy_data_contract 20/20; the pond never enters the nav grid, the gate stress digest is a pure health-scale move); harbor_1 alone has the 9 to 10.5 m road band with the reason in the test (test_prototype_map_economy 20/20). The bot-play exposure (struck in 7 of the 9 balanced seeds in which it is built, destroyed 18 times) is the executor's scratch-probe table, not re-run by me; independent evidence I did gather: the shipped `full_idle` replay log (balanced bot, seed 1) contains `building_damaged harbor_1 200 ...` four times (1820 down to 1020, after Masons' +30% on 1400), so enemies do strike it in the real game.
- **05-23 (7 of 7).** The bar re-measured on the final data without lowering it (PLAYTEST_OK runs=100 in the report; 17/17 pins re-run by me); the re-pin has the gap round header naming every pinned value old and new; the lever was not pulled (no bot order moved: `git diff ce3fcea HEAD` over `tools/replay/` and over both test_playtest_strategies scripts is empty, and test_playtest_strategies 19/19 and test_playtest_strategies_castle 8/8 pass); Prosperity at +2 was measured against the other tier II cards and neither +2 nor +3 passed the pre-registered rule, so +2 shipped and it is an owner item exactly as the truth says (see human items 1 and 2); every card at tiers II to IV has a viability row, the nine unmeasurable ones marked 'owner-judged, no measurement'; the report carries the new section with full_idle before and after (afc11cd0, cec3eb71, 6fd6121e, c68254cd), the four goldens, the gate stress, the rescale, the per-card before and after, the Harbor and the numbers changed; harbor_pond and economy_day re-aimed and re-captured (harbor_pond.png shows the Harbor on the pond's near shore with its three boats, as the scenario's capture gate requires).
- **05-24 (5 of 5).** The closing local pass is green on the final data (the orchestrator's 281 / 2668, my own re-runs of the goldens, full_idle, gate stress and lint); `05-PLAYTEST-GATE.md` opens with a dated '## Gap round (G-05-2 and G-05-7): what changed and what to re-judge' section in plain words with no digests or plan ids; it asks the owner to re-judge tests 2, 5 and 7 with what to look for; it has the sentence that a bigger percent only changes a fight when it saves a whole blow, with Commander (five blows, not six) and Engineers (two arrows still) and the later enemy-health lever; the nine cards each carry their numbers, basis and a recommended choice (Golden Age +4, +3 or +2; Headsman's Edge x1.25, x1.5 or no slowdown; Engineers keep or +34%, which I checked: 300 times 1.34 is 402 against a 400-health skirmisher; the other six keep); and the other choices (numbers divided by 100, Harbor spots B and C, a different Harbor health, more enemy health) each carry a recommendation. The fresh export exists and launches (above).

### The one partial truth: 05-19's tests that fell nothing (the orchestrator's question)

The orchestrator asked me to judge whether `tests/integration/test_squad_lifecycle.gd` (WR-07) and `tests/unit/test_goal_field_cache.gd` (IN-12) make a 05-19 truth false or are a review finding outside the plan's declared scope. **My judgement: they make 05-19's truth 1 false in letter, so I count a gap, with the low severity stated.**

Why a gap and not only a review finding:

1. Truth 1 is universally worded: 'the tests that fell a shipped building, wall segment or unit with a blow of their own fell it again at the x100 scale ... so every test checks what it checked before the rescale', and the plan's `<objective>` is 'Make every test that fells a shipped building, wall segment or unit with its own blow fell it again at the x100 scale'. The seven-script list was built from the scripts that failed; the objective does not scope itself to that list.
2. I confirmed both counter-examples in the code, not from the review. `fixture_map_squads.tres` loads `data/buildings/barracks.tres` (tier I 4000); `test_squad_lifecycle.gd` line 12 keeps `KILL_DAMAGE = 1000`, and line 174 hits the Barracks with it, so it is never destroyed; the three assertions that follow (not destroyed after dawn, `_stood_at_restore`, squad of 4) hold with no fall and no rebuild in the path (the dawn restore still runs at every dawn and refills the squad, so `_stood_at_restore` is true without a building ever having been down). 05-19's Flagged Assumption lists test_squad_lifecycle among the scripts that 'fell a 1000-health footman with exactly 1000'; that reading missed line 174, `damage_building(BARRACKS, KILL_DAMAGE)`, which did fell the 40-health Barracks at ce3fcea. `test_goal_field_cache.gd` line 83 hits a 3000-health segment for 1000; the assertions pass because `NavGrid.rebuild` bumps its version unconditionally.
3. This is exactly the failure class that G-05-2 was about (a number that silently stopped doing its job after a change of scale), and the plan's own header sentence ('so every test checks what it checked before') is the guard against it.

Why the severity is low and not a blocker for the phase goal: no product file, datum, golden, replay digest or balance pin is affected. The rebuild is still exercised at unit level (test_squad_respawn fells the Barracks with 100000 and rebuilds it), but none of its restore_for_dawn tests involves a fallen building, so the dawn order of rebuild before restore is covered only by the army golden, which replays the real lifecycle on its frozen inputs; the coverage loss is that ordering's live test, slightly more than the fall alone; the wall-break invalidation is covered by the flow-field and wall suites. I did look for further vacuous sites: a grep of every literal-amount `damage_building`, `damage_segment`, `take_damage` and `KILL_DAMAGE` call in `tests/` found the other 1000-valued calls kill units of 1000 health or fewer, are hurts that are meant to hurt, or are dropped-hit tests; the review's two are the only two. The closure is two literal edits, both already written up by 05-REVIEW.md (WR-07, IN-12) and open in 05-REVIEW-DISPOSITION.md, so the owner's standing fix pass (`/gsd-code-review 5 --fix --all`) closes the gap, or a one-task gap plan does; a re-verification afterwards only has to re-read those two tests.

### Carried first-run truths whose numbers the round moved, re-checked

The previous report's verdicts stand where nothing they rest on changed (the stack, the picker, the gate mechanism, the curves, the validators, the economy golden; no `simulation/` file changed in the round). I re-checked the ones the rescale, the recuts and the Harbor move touched:

- **05-02, 05-03 (castle tiers and cards).** Health 70, 100, 140, 200 and arrows 3, 4, 5 became 7000, 10000, 14000, 20000 and 200, 300, 400, 500 (test_castle_data_contract, test_castle_tiers, test_map_validate_castle pass); the twelve distinct cards still pass test_ability_data 15/15 with Prosperity, Golden Age and Headsman's Edge at their recut values.
- **05-08 (Harbor).** The one-boat-per-dawn, the cap and the destroyed-building rules are unchanged (test_fishing_harbor 12/12); the pond is still visual only and out of the nav grid (test_nav_layout_pin is in the covered list and the gate stress statistics are identical); only its place, radius and health moved.
- **05-09 (Shrine).** Wake threshold 100 became 10000 and credit counts the summed health of the enemies that died; test_shrine 17/17 (wake at exactly the radius and the threshold), test_shrine_synergy 10/10, test_shrine_night 13/13, test_shrine_destroyed 8/8 pass on the scaled fixture and data.
- **05-10, 05-11.** The economy golden is a frozen fixture and replays byte-identical; the bots' balance numbers moved to the report's new rows (balanced 8 of 10 with 26.4 gold and 10.6 buildings lost, army_balanced 8 of 10 with ratio 0.882, first castle on day 6) and the old rows are history. The old 'full_idle afc11cd0 in 7000 ticks' is now c68254cd in 6993 (owner-sanctioned by G-05-2 and G-05-7, recorded before and after).
- **05-12 truths 1 and 2 (the screenshot sweep and CI).** Truth 2 ('the latest CI run on the branch is for HEAD and concluded success on every job, with REPLAY_OK lines ... and the GATE_OK line') is **pending**, not verified: the round is not pushed (origin at 570ff8d, HEAD 62 commits ahead, 25 of them outside `.planning/`), so no CI run covers it; in the first report it held because nothing outside `.planning/` had changed since 570ff8d. The orchestrator pushes after this report and the next verification reads that run. Truth 1's 44-shot sweep is carried from the 05-12 sitting: 12 PNGs were re-captured in the round (the ten of 05-20 and the two of 05-23), the other 32 date from 2026-10-22, before the rescale, and plan 05-24's closing pass covers no screenshots.
- **05-12 (the three backstop truths).** Still `insufficient_spec`: the cards read and pick well, the twelve abilities are worth a pick, the day is deeper and still fun. They are human items 1, 3 and 5 (and 2) below; I abstain on them again.

Decision check against 05-CONTEXT.md: D-02 (original card names, stat modifiers only, the owner judges the set) honoured, the three recuts are data only; D-07 (numbers lines generated from the modifiers) honoured, the lines read the new values; D-08 (goldens) honoured exactly: four goldens byte-identical and full_idle moved by owner-sanctioned steps, reported before and after; D-11 (the pond is visual only and keeps clear of plots, spawns, roads and the nav grid) honoured at the new place with the pond shrunk to 4.5 m; D-15 (one stacking order, StatStack untouched) honoured. The owner's G-05-2 decision (the rescale is a hard requirement, display undivided) and G-05-7 decision (an exposed Harbor with less health) are honoured as written. The G-05-2 owner requirement 'every alternative viable' is not met by measurement for Prosperity; that is the plan's own pre-registered fallback and is human item 2, not a code defect.

### Key Link Verification

Tool: 55 of 58 across all 24 plans (first run 32/32 carried and re-run, gap round 23 of 26). The three misses, each checked by reading:

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `tests/unit/test_wall_decision.gd` | `data/enemies/grunt.tres` | `GRUNT_PER_300` is the grunt's damage per 10 s: `WallDecision.damage_per_300(200, 30)` | WIRED | The tool treated the parentheses in the pattern as regex; line 79 of the test is `WallDecision.damage_per_300(200, 30)` equal to `GRUNT_PER_300 = 2000`, and grunt.tres has `attack_damage = 200` and `attack_interval = 1.0` (30 ticks) |
| `tests/unit/test_shot_list.gd` | `tools/screenshot/shot_army_scenarios.gd` | the `hud_king_120` copy holds `KING_120_HEALTH` 12000 and the shipped king keeps 5000 (05-20's second link; the plan's pattern is `"12000"`, which the tool's frontmatter parser turns into a number and its pattern compiler then rejects as empty: a tool artefact, not a plan defect) | WIRED | `shot_army_scenarios.gd` line 43 `KING_120_HEALTH = 12000` and its king-def copy line 102; test_shot_list line 174 asserts `king_def_for(HUD_KING_120).max_health == 12000`; the shipped king asserted 5000; 20/20 pass |
| `tests/unit/test_card_resolution.gd` | `simulation/stats/stat_stack.gd` | integer modifiers through `int_value`, floats through `float_value`, the bound through `StatStack.MAX_ABS_BASE` | WIRED | The tool's regex engine rejected the pattern `int_value(`; lines 196 and 198 call `stack.int_value(stat, ...)` and `stack.float_value(stat, ...)`, line 335 asserts `lte(base, StatStack.MAX_ABS_BASE)` |

The links that carry the round (all verified by the tool and by my runs): the stress test pins to the shipped grunt's attack, the pins' frozen wall health, the castle contract to the map's 7000 and the tier rows, the balance pins to the report's measured values, and `test_pond_layout` to `EconomyValidation.POND_ROAD_CLEARANCE` and the Harbor's `body_radius`.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| King widget label | king current and max health | `ctx.king` health through `StatStack` (`king.max_health`), drawn at 128 px | yes: '5000 / 5000', '6250 / 6250', '9000 / 12000' in the screenshots | FLOWING |
| Castle label and card numbers lines | tier health, arrow, income; each card's effect text | the stack and the card's own modifiers (`ChoiceDef.effect_line()`) | yes: 'Health 14000 · Arrow 400 · 3 gold at dawn', '+25% king health, +100 king damage' read in the PNGs | FLOWING |
| Harbor and pond | plot, pond centre and radius | `prototype_map.tres` into `PondView` and the Harbor's spot | yes: harbor_pond.png shows the Harbor on the pond with boats; the replay log shows `harbor_1` built, boats changed and struck | FLOWING |
| Card effects | every modifier's result at its shipped base | `StatStack.int_value` and `float_value` over bases read from the shipped files | yes: test_card_resolution reads every base from the `.tres` files | FLOWING |

### Behavioral Spot-Checks and Replays

| Behavior | Command | Result | Status |
|---|---|---|---|
| Four golden replays identical | `replay.sh --twice --expect-file` x4 | REPLAY_OK x4 | PASS |
| full_idle deterministic, matches the report | `replay.sh --scenario=full_idle --twice` | c68254cd, won, 6993 | PASS |
| Gate stress statistics unchanged | `gate_stress.sh --twice` | GATE_OK, eb319f09 | PASS |
| Enemies strike the moved Harbor in the shipped game | read `build/replay/full_idle.log` after my run | four `building_damaged harbor_1 200 ...` (1820 to 1020), boats still rise to 3 | PASS |
| The bar holds | `test_balance_acceptance` | 17/17 | PASS |
| Exported build launches | `Duskhold.exe --headless --quit-after 120` | exit 0 | PASS |

### Probe Execution

No `probe-*.sh` is declared by the phase plans and none exists under `scripts/`: SKIPPED. The replays, the gate stress and the named test scripts are the phase's runnable checks.

### Requirements Coverage

Plans 05-13 to 05-24 declare BLDG-08, META-08 and ECON-05 (05-22 declares ECON-05 alone; 05-23 and 05-24 BLDG-08, ECON-05, META-08). With the first run's plans, all nine IDs are accounted for against REQUIREMENTS.md and none is orphaned (REQUIREMENTS.md's traceability maps exactly BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08 and UI-02 to Phase 5, all marked Complete, set by plan 05-12 and not changed by the gap round).

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| BLDG-05 | 05-02, 05-03, 05-04, 05-10, 05-12 | Branching tier offers choice cards by keyboard or mouse; the choice is permanent | SATISFIED | Criterion 1; test_card_row, test_build_choice re-run |
| BLDG-08 | 05-02 to 05-04, 05-10 to 05-12, 05-13 to 05-21, 05-23, 05-24 | Upgrade the castle through its tiers, one of four run-wide abilities per tier | SATISFIED in code (every card lands as written); viability of the nine unmeasured cards and Prosperity is human items 1 and 2 | Criterion 2; test_card_resolution, test_ability_data |
| BLDG-09 | 05-05, 05-11, 05-12 | The castle tier gates higher building tiers | SATISFIED | test_castle_gate 3/3, test_build_requirements 15/15; the gate feel was passed by the owner in UAT test 3 |
| ECON-03 | 05-06, 05-10 to 05-12 | Gold Mine pays a high income that declines each night | SATISFIED | Economy golden; test_gold_mine in the covered list; Mine at health 2000 |
| ECON-04 | 05-07, 05-10 to 05-12 | Mill unlocks Fields, each paying flat income | SATISFIED | test_mill_fields, test_field_independence in the covered list |
| ECON-05 | 05-08, 05-10 to 05-12, 05-22 to 05-24 | Harbor gains a boat each night up to a cap, each boat pays | SATISFIED; the exposed placement and lowered health are G-05-7's decision, built and measured; the owner's worth-its-risk call is human item 4 | test_fishing_harbor 12/12, test_harbor_exposure 4/4, test_harbor_scene 4/4 |
| ECON-06 | 05-09 to 05-12 | Shrine wakes by nearby kills, attacks, pays, strengthens other Shrines | SATISFIED on fixtures and the economy golden at the scaled numbers | test_shrine, _synergy, _night, _destroyed all pass |
| META-08 | 05-01, 05-12, 05-13 to 05-21, 05-23, 05-24 | Stat bonuses combine in a fixed, documented order, tests verify | SATISFIED | Criterion 4; the new guard pins every card at every shipped base |
| UI-02 | 05-02 to 05-04, 05-12 | Choice cards show an icon, name and short description | SATISFIED | twelve SVG icons; the card crops I read show icon, name, flavour and the numbers line |

### Anti-Patterns Found

None blocking. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in any non-md file changed in the phase scope (244 files scanned). Grep for empty or stub implementations in the round's non-test code (the widget constant, three doc-comment files and the tools) found none. The two vacuous tests are the gap above. Notes recorded as advisory, none a blocker: the step_bench castle constant (WR-06), the two shots without the pad-zoom drop (WR-08) and the 100000 stack bound's headroom.

## Code-review findings (26 OPEN, 0 fixed)

05-REVIEW.md (standard depth, 93 files, run after the round): 0 critical, 3 new warnings (WR-06, WR-07, WR-08), 9 new info (IN-10 to IN-18), the 14 earlier findings carried open; 05-REVIEW-DISPOSITION.md records all 26 `open` for the owner's `/gsd-code-review 5 --fix --all` pass, the project's standing practice. My weighting against this verdict: WR-07 and IN-12 are the gap above; WR-06 and WR-08 are advisory (tools only); WR-01 to WR-05 and IN-01 to IN-09 are as weighed in the first report (none fires on shipped data). The close-out documents are as the orchestrator stated: 05-VALIDATION.md `status: validated`, `nyquist_compliant: true` (state A, 51 of 51 task checks, four whole-feature-off mutation probes caught), 05-SECURITY.md `status: verified`, `threats_open: 0` (T-05-25 to T-05-45 closed at ASVS L1), 05-UI-REVIEW.md advisory 15 of 24 unchanged; I carried these as facts and did not re-review them.

## Human Verification

Six entries, in the structure the orchestrator turns 1:1 into UAT tests 11 onward (frontmatter `human_verification`): (1) every card at a tier is a viable pick after the rescale and the recuts, including the nine cards the bots cannot judge (UAT test 2); (2) Prosperity's measured shortfall and its four choices (UAT test 2); (3) the day is deeper and still fun (UAT test 5, deferred until these fixes); (4) the exposed Harbor is worth its risk (UAT test 7); (5) the numbers shown as they are rather than divided by 100; (6) the fresh build hand-off. Tests 1, 3, 4, 6, 8, 9 and 10 of the previous UAT were passed by the owner and are not reopened (the presentation points wait for Phase 8; the castle ladder stays 6 / 10 / 16). Nothing here is a code defect: every mechanism the entries judge is pinned by a test that passed.

## Gaps Summary

One gap, low severity, test files only: `tests/integration/test_squad_lifecycle.gd` (its 'building fell' test hits the 4000-health Barracks for 1000) and `tests/unit/test_goal_field_cache.gd` (its wall 'break' hits a 3000-health segment for 1000) no longer fell what they fell before the x100 rescale and pass without exercising the rebuild-and-restore path or a real grid change. They falsify the universal wording of plan 05-19's truth 1 ('every test checks what it checked before the rescale'), they were outside the plan's seven-script list because they pass, and they are the review's WR-07 and IN-12. Closing it is two literal edits and one re-read; the owner's standing fix pass does it, or a single-task gap plan. Nothing else blocks: the four ROADMAP criteria hold, the rescale is exact, the goldens are byte-identical, the bar is unlowered, the Harbor is exposed and struck in the real game, the cards land as written, and the six owner judgements above (cards, Prosperity, depth and fun, the Harbor, the undivided numbers, the fresh build) are what remains of the phase.

### Corrections after the cross-check (2026-10-26T00:49:15Z)

Four independent auditors re-checked this report against the code; eight discrepancies survived three skeptics each and are applied above. One changes the score: 05-12 truth 2 (CI at HEAD) is pending until the round is pushed, so 166 of 171 truths are verified, not 167. The rest correct evidence only: the WR-07 test still runs the dawn restore (only the fall and the rebuild are missing) and the dawn order of rebuild before restore has no live test besides the army golden; 05-20's key-link miss is the tool coercing an all-digit pattern, not a plan defect; META-08's source plans exclude 05-22; harbor_pond.png shows three boats and no road; human item 6 no longer asks the owner to match a digest the owner section does not hold. No verdict on a must-have changed and the status stays gaps_found.

---

_Verified: 2026-10-26T00:21:48Z_
_Verifier: Claude (gsd-verifier); cross-checked and corrected by the execute-phase orchestrator 2026-10-26T00:49:15Z_
