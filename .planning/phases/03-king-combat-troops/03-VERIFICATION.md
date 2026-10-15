---
phase: 03-king-combat-troops
verified: 2026-10-15T19:51:19Z
status: passed
score: 5/5 roadmap success criteria verified in code and tests (0 failed); 6/6 UAT round-1 gap truths closed in code, tests and probes (0 failed); 13/13 review-fix pass-1 findings and 2/2 pass-2 findings (IN-10, IN-11) fixed and re-verified (0 regressions, ledger 0 of 16 open, fifth review clean); 11/11 requirement IDs have implementation evidence; the ten owner judgements of the third report are UAT tests 16 to 25, all passed (03-UAT.md complete, 25 passed, 0 issues, 2026-10-15)
must_haves:
  roadmap_truths: 5
  roadmap_truths_verified: 5
  roadmap_truths_failed: 0
  gap_truths: 6
  gap_truths_closed: 6
  gap_truths_failed: 0
  review_fix_findings: 15
  review_fix_findings_fixed: 15
  review_fix_findings_regressed: 0
  plan_truths_declared: 188
  plan_artifacts_checked: "81/81 pass (gsd-tools verify.artifacts over all 19 plans, re-run by me again in this report)"
  plan_key_links_checked: "51/52 by the tool, 52/52 wired by reading (gsd-tools verify.key-links over all 19 plans, re-run by me; the one tool miss is 03-13 link 1, whose literal regex `SquadOrderIntent.new\\(ids, verb` no longer matches because the WR-03 fix reformatted the call across lines; the link itself is intact, unchanged since the third report)"
  prohibitions_declared: 25
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass. The 25 are plan-scoped (plans 03-01 to 03-19). Review-fix pass 1 changed six simulation files outside any plan (squad_system.gd, unit_system.gd, enemy_system.gd, command_processor.gd, map_config.gd and the new separation.gd); pass 2 added one debug-only assert and one comment block to separation.gd (db5e138 and 2471438 touch no other simulation file). Both replay goldens are byte-identical (re-run by me in this report) and git shows no change to project.godot, data/, tests/golden or tests/fixtures since 4da6799"
  requirement_ids: 11
  requirement_ids_satisfied: 11
  requirement_ids_orphaned: 0
re_verification:
  previous_status: passed
  previous_score: "5/5 roadmap success criteria; 6/6 UAT round-1 gap truths; 13/13 review-fix pass-1 findings; 11/11 requirement IDs; 10 human items (the third report of 2026-10-14T06:30:48Z at HEAD a67956e, written human_needed and canonicalized to passed by /gsd-verify-work on 2026-10-15 after the UAT closed; 2 open info review findings IN-10 and IN-11)"
  report_number: "fourth report: re-verification after review-fix pass 2 (commits db5e138 for IN-10 and 2471438 for IN-11, 2026-10-15), which changed two covered test files and simulation/squads/separation.gd and made the third report stale, and after the owner completed the UAT (03-UAT.md status complete, 25 of 25 passed, 2026-10-15) and the phase was marked complete and transitioned (ROADMAP.md, STATE.md, PROJECT.md, 2026-10-15). The first report was the initial verification, the second the re-verification after the UAT round-1 gap closure (plans 03-13 to 03-19), the third the re-verification after review-fix pass 1 (13 commits 56b2828 to e01971e)"
  gaps_closed:
    - "G-03-4 / WR-01: the floating bar over the king follows regeneration (king.gd connects king_healed, line 54, handler lines 101-103; test_king_knockout 5/5 re-run by me in the third report; no source file of it changed since; owner re-check passed as UAT test 16)"
    - "G-03-8: Shift (pad RT) queues the F, H and R verbs behind queued walks (command_key_controller.gd _give reads the queue action; test_command_keys 17/17 and test_pad_commands 18/18 re-run by me in the third report; owner re-check passed as UAT test 17)"
    - "G-03-13: the knocked-out '0 / 50' stays opaque on its own outline (king_widget.gd _apply_knocked_out dims only the bar, plate, icon and glyph; test_king_widget 15/15 in the full runs; contrast probe CONTRAST_OK ratio=5.88, re-measured on a fresh real-window capture in UAT test 19)"
    - "G-03-14: singular copy at a count of one (Hud.enemy_count_text; test_spawn_telegraph 22/22 in the full runs; read in a real window in UAT test 20)"
    - "G-03-14b: a plate behind the start-night prompt (StartNightPlate in hud.tscn; test_start_night_plate 6/6; the owner judged the focal point from the real-window crop in UAT test 21)"
    - "G-03-11: Round 2 retune, balanced 8 of 10, army_balanced 8 of 10, squad_value_ratio 0.915 (bar 0.8, D-26), night 8 at 40 above night 7 at 39 (no data file changed since; test_balance_acceptance 12/12 in the full runs; the owner played the fixed build and passed UAT test 18)"
  review_findings_closed:
    - "CR-01 (critical): SquadSystem._fill (line 148) and restore_for_dawn (line 462) loop once per missing seat, UnitSystem.spawn and heal_to_full floor stored health at 1; test_squad_bad_unit_health 3/3; T-03-04 and T-03-05 closed in 03-SECURITY.md (commit 56b2828)"
    - "WR-02: tools/screenshot.sh tees each shot to build/screenshot-<shot>.log and fails on SCRIPT ERROR, Parse Error or Failed to load script; ci.yml uploads the logs (commit 8d28079); one real shot and a synthetic error-line check per the fix report, not re-run by me (I did not run the game window); CI run 38774381177 ran the screenshots job green on HEAD 7f5cb65"
    - "WR-03: a refused queued order is shown as Toast.QUEUE_CLOSED on the Shift+F/H/R, Shift right-click and pad RT paths; the gate refuses only when every ordered squad is closed and apply_order skips the closed ones (commit 8ad0158); test_squad_queue 17/17, test_command_keys 17/17, test_mouse_commands 16/16, test_pad_cursor 10/10, test_pad_commands 18/18 (third report); the owner accepted the toast and the mixed-selection rule in UAT test 25"
    - "WR-04: tests/unit/test_contrast_probe.gd pins the probe's path guard and measurement (commit 2e863c8); 10/10 re-run by me in this report"
    - "IN-01: dead patrol-leg budget assignment removed (67122e9); goldens byte-identical"
    - "IN-02: one MapConfig.ground_limit_cm rule behind the gate and the ground picker (06b3e5c)"
    - "IN-03: Separation.displacements shared by UnitSystem and EnemySystem (14f898d); test_separation 7/7 re-run by me in this report, goldens byte-identical"
    - "IN-04: the two test-only accessors are marked Test hook (9d2d15d)"
    - "IN-05: three unused ext_resource entries removed from the barracks and archery range scenes (2b7d443)"
    - "IN-06: the eighth patrol click toasts Toast.PATROL_FULL (b6ff96f); test_mouse_commands 16/16; shown in a real window in UAT test 25"
    - "IN-07: BalanceReport._mean reads run keys tolerantly (8adbc3b)"
    - "IN-08: one SelectionController.QUEUE_ACTION constant for the three order controllers (0ceb7c8)"
    - "IN-09: the plate test reads KingWidget.PLATE_COLOR (e01971e)"
    - "IN-10 (pass 2, db5e138): the 'outside the project' path case in tests/unit/test_contrast_probe.gd is now globalize_path(\"res://\").path_join(\"../outside/x.png\").simplify_path(), asserted before the loop to localize outside res:// and listed in the rejected set; I read lines 104-135 at HEAD and re-ran test_contrast_probe 10/10, 68 asserts (was 67); the orchestrator's mutation probe with the old inside-the-project expression failed 1 of 10 (9/10, 67/68 asserts)"
    - "IN-11 (pass 2, 2471438): tests/unit/test_separation.gd builds its unit and enemy definitions inline from four test constants (FOOTMAN 0.45, ARCHER 0.4, GRUNT 0.5, RANGED 0.45) instead of loading res://data/, the private _separate seam is kept with a comment, and Separation.displacements asserts in debug builds that positions, radii and ids are parallel arrays (separation.gd lines 14-24, read at HEAD, with a header note because assert is stripped from release exports); test_separation 7/7, 40 asserts re-run by me; the orchestrator's probes: retuning the shipped footman radius leaves it 7/7, a routine that pushes nothing fails it 5 of 7 (2/7 passing), the assert is a documented debug-only guard no suite exercises by design"
  gaps_remaining: []
  regressions: []
covered_files:
  - .claude/CLAUDE.md
  - .github/workflows/ci.yml
  - .planning/phases/03-king-combat-troops/03-01-PLAN.md
  - .planning/phases/03-king-combat-troops/03-01-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-02-PLAN.md
  - .planning/phases/03-king-combat-troops/03-02-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-03-PLAN.md
  - .planning/phases/03-king-combat-troops/03-03-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-04-PLAN.md
  - .planning/phases/03-king-combat-troops/03-04-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-05-PLAN.md
  - .planning/phases/03-king-combat-troops/03-05-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-06-PLAN.md
  - .planning/phases/03-king-combat-troops/03-06-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-07-PLAN.md
  - .planning/phases/03-king-combat-troops/03-07-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-08-PLAN.md
  - .planning/phases/03-king-combat-troops/03-08-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-09-PLAN.md
  - .planning/phases/03-king-combat-troops/03-09-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-10-PLAN.md
  - .planning/phases/03-king-combat-troops/03-10-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-11-PLAN.md
  - .planning/phases/03-king-combat-troops/03-11-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-12-PLAN.md
  - .planning/phases/03-king-combat-troops/03-12-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-13-PLAN.md
  - .planning/phases/03-king-combat-troops/03-13-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-14-PLAN.md
  - .planning/phases/03-king-combat-troops/03-14-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-15-PLAN.md
  - .planning/phases/03-king-combat-troops/03-15-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-16-PLAN.md
  - .planning/phases/03-king-combat-troops/03-16-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-17-PLAN.md
  - .planning/phases/03-king-combat-troops/03-17-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-18-PLAN.md
  - .planning/phases/03-king-combat-troops/03-18-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-19-PLAN.md
  - .planning/phases/03-king-combat-troops/03-19-SUMMARY.md
  - .planning/phases/03-king-combat-troops/03-BALANCE-REPORT.md
  - .planning/phases/03-king-combat-troops/03-CONTEXT.md
  - .planning/phases/03-king-combat-troops/03-DISCUSSION-LOG.md
  - .planning/phases/03-king-combat-troops/03-PATTERNS.md
  - .planning/phases/03-king-combat-troops/03-PLAYTEST-GATE.md
  - .planning/phases/03-king-combat-troops/03-RESEARCH.md
  - .planning/phases/03-king-combat-troops/03-REVIEW-DISPOSITION.md
  - .planning/phases/03-king-combat-troops/03-REVIEW-FIX.md
  - .planning/phases/03-king-combat-troops/03-REVIEW.md
  - .planning/phases/03-king-combat-troops/03-SECURITY.md
  - .planning/phases/03-king-combat-troops/03-UAT.md
  - .planning/phases/03-king-combat-troops/03-UI-REVIEW.md
  - .planning/phases/03-king-combat-troops/03-UI-SPEC.md
  - .planning/phases/03-king-combat-troops/03-VALIDATION.md
  - ASSETS.md
  - assets/attribution.json
  - assets/third_party/kenney_input_prompts/License.txt
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_0.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_1.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_2.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_3.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_4.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_5.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_6.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_7.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_8.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_9.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_a.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_arrow_down.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_arrow_left.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_arrow_right.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_arrow_up.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_b.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_c.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_ctrl.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_d.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_e.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_enter.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_equals.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_escape.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_f.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_f2.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_f3.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_g.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_h.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_i.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_j.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_k.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_l.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_m.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_minus.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_n.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_numpad_plus.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_o.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_p.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_q.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_r.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_s.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_shift.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_space.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_t.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_tab.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_u.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_v.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_w.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_x.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_y.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/keyboard_z.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/mouse_left.png
  - assets/third_party/kenney_input_prompts/keyboard_mouse/mouse_right.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_a.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_b.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_back.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_color_a.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_color_b.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_color_x.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_color_y.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_start.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_x.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_button_y.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_dpad_down.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_dpad_left.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_dpad_right.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_dpad_up.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_lb.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_ls.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_lt.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_rb.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_rs.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_rt.png
  - assets/third_party/kenney_input_prompts/xbox/xbox_stick_r_press.png
  - assets/third_party/kenney_mini_characters/models/character-female-a.glb
  - assets/third_party/kenney_mini_characters/models/character-male-a.glb
  - data/buildings/archery_range.tres
  - data/buildings/barracks.tres
  - data/buildings/tower.tres
  - data/king/king.tres
  - data/king/sword.tres
  - data/maps/prototype_map.tres
  - data/units/archer.tres
  - data/units/footman.tres
  - input/ability_controller.gd
  - input/command_key_controller.gd
  - input/device_model.gd
  - input/ground_cursor.gd
  - input/ground_pick.gd
  - input/last_device_tracker.gd
  - input/pad_chords.gd
  - input/pad_cursor_controller.gd
  - input/selection_controller.gd
  - input/selection_math.gd
  - input/selection_model.gd
  - presentation/buildings/building_view_catalog.tres
  - presentation/buildings/building_views.gd
  - presentation/buildings/models/archery_range_t1.tscn
  - presentation/buildings/models/archery_range_t2.tscn
  - presentation/buildings/models/archery_range_t3.tscn
  - presentation/buildings/models/barracks_t1.tscn
  - presentation/buildings/models/barracks_t2.tscn
  - presentation/buildings/models/barracks_t3.tscn
  - presentation/camera/camera_rig.gd
  - presentation/debug/enemy_path_gizmo.gd
  - presentation/king/king.gd
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/units/order_markers.gd
  - presentation/units/pad_cursor_view.gd
  - presentation/units/selection_rings.gd
  - presentation/units/squad_plan_view.gd
  - presentation/units/unit_views.gd
  - presentation/vfx/projectile_vfx.gd
  - presentation/vfx/slam_vfx.gd
  - project.godot
  - simulation/commands/activate_ability_intent.gd
  - simulation/commands/command_processor.gd
  - simulation/commands/squad_order_intent.gd
  - simulation/defs/building_def.gd
  - simulation/defs/building_tier_def.gd
  - simulation/defs/king_def.gd
  - simulation/defs/map_config.gd
  - simulation/defs/unit_def.gd
  - simulation/defs/weapon_def.gd
  - simulation/events/sim_events.gd
  - simulation/king/king_state.gd
  - simulation/night/enemy_system.gd
  - simulation/night/night_sim.gd
  - simulation/night/pending_hits.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - simulation/squads/separation.gd
  - simulation/squads/squad.gd
  - simulation/squads/squad_formation.gd
  - simulation/squads/squad_order.gd
  - simulation/squads/squad_orders.gd
  - simulation/squads/squad_system.gd
  - simulation/squads/unit_system.gd
  - tests/e2e/test_ability_input.gd
  - tests/e2e/test_box_select.gd
  - tests/e2e/test_building_models.gd
  - tests/e2e/test_command_hints.gd
  - tests/e2e/test_command_keys.gd
  - tests/e2e/test_control_group_keys.gd
  - tests/e2e/test_hud_contract.gd
  - tests/e2e/test_king_knockout.gd
  - tests/e2e/test_king_widget.gd
  - tests/e2e/test_mouse_commands.gd
  - tests/e2e/test_order_markers.gd
  - tests/e2e/test_pad_commands.gd
  - tests/e2e/test_pad_cursor.gd
  - tests/e2e/test_prompt_switch.gd
  - tests/e2e/test_select_one_type.gd
  - tests/e2e/test_selection_steering.gd
  - tests/e2e/test_spawn_telegraph.gd
  - tests/e2e/test_squad_selection.gd
  - tests/e2e/test_squad_strip.gd
  - tests/e2e/test_squad_tracer_scene.gd
  - tests/e2e/test_start_night_hold.gd
  - tests/e2e/test_start_night_plate.gd
  - tests/e2e/test_stretch_coordinates.gd
  - tests/e2e/test_unit_views.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/fixtures/fixture_king_replay_army.tres
  - tests/fixtures/fixture_king_replay_smoke.tres
  - tests/fixtures/fixture_map_replay_army.tres
  - tests/fixtures/fixture_map_squads.tres
  - tests/golden/army.json
  - tests/integration/test_army_replay_golden.gd
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_report.gd
  - tests/integration/test_balance_value_metric.gd
  - tests/integration/test_replay_golden.gd
  - tests/integration/test_squad_determinism.gd
  - tests/integration/test_squad_lifecycle.gd
  - tests/support/sim_signals.gd
  - tests/unit/test_contrast_probe.gd
  - tests/unit/test_control_groups.gd
  - tests/unit/test_debug_overlay_night_sections.gd
  - tests/unit/test_debug_overlay_squad_section.gd
  - tests/unit/test_device_model.gd
  - tests/unit/test_enemy_targets_units.gd
  - tests/unit/test_glyph_resolver.gd
  - tests/unit/test_ground_cursor.gd
  - tests/unit/test_ground_pick.gd
  - tests/unit/test_input_capabilities.gd
  - tests/unit/test_input_map.gd
  - tests/unit/test_input_map_groups.gd
  - tests/unit/test_king_combat.gd
  - tests/unit/test_king_regen.gd
  - tests/unit/test_king_respawn.gd
  - tests/unit/test_king_selection_steering.gd
  - tests/unit/test_king_slam.gd
  - tests/unit/test_map_validate_squads.gd
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_night_data_contract.gd
  - tests/unit/test_pad_chords.gd
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_prompt_glyph.gd
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_replay_cli_args.gd
  - tests/unit/test_selection_math.gd
  - tests/unit/test_selection_model.gd
  - tests/unit/test_separation.gd
  - tests/unit/test_shot_list.gd
  - tests/unit/test_shot_protected_centre.gd
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_squad_archers.gd
  - tests/unit/test_squad_bad_unit_health.gd
  - tests/unit/test_squad_guard.gd
  - tests/unit/test_squad_order_intent.gd
  - tests/unit/test_squad_orders.gd
  - tests/unit/test_squad_patrol.gd
  - tests/unit/test_squad_point_orders.gd
  - tests/unit/test_squad_point_validation.gd
  - tests/unit/test_squad_queue.gd
  - tests/unit/test_squad_respawn.gd
  - tests/unit/test_squad_stance_persistence.gd
  - tests/unit/test_stance_glyph.gd
  - tests/unit/test_weapon_def.gd
  - tools/contrast_probe.sh
  - tools/playtest.sh
  - tools/replay.sh
  - tools/replay/balance_report.gd
  - tools/replay/playtest_bot.gd
  - tools/replay/playtest_strategies.gd
  - tools/replay/replay_driver.gd
  - tools/replay/replay_scenarios.gd
  - tools/replay/sim_recorder.gd
  - tools/screenshot.sh
  - tools/screenshot/contrast_probe.gd
  - tools/screenshot/shot_army_scenarios.gd
  - tools/screenshot/shot_runner.gd
  - tools/screenshot/shot_scenarios.gd
  - ui/hud/bow_icon.gd
  - ui/hud/command_hints.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/day_counter.gd
  - ui/hud/drag_box.gd
  - ui/hud/glyph_resolver.gd
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/hud/hud_root.gd
  - ui/hud/king_widget.gd
  - ui/hud/prompt_glyph.gd
  - ui/hud/squad_slot.gd
  - ui/hud/squad_slot.tscn
  - ui/hud/squad_strip.gd
  - ui/hud/stance_glyph.gd
  - ui/hud/sword_icon.gd
  - ui/hud/toast.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/night_overlay_sections.gd
  - ui/overlay/squad_overlay_sections.gd
  - ui/theme/hud_theme.tres
covered_digest: "v2:sha256:c6f4fb38b516a8b71880a6b293cd079ba990acc7ec96f745a2b9ebcb45013779"
behavior_unverified: 0
overrides_applied: 0
gaps: []
deferred:
  - truth: "Glyphs for non-Xbox gamepads and the rebinding UI"
    addressed_in: "Phase 13"
    evidence: "03-CONTEXT.md Deferred Ideas; ROADMAP Phase 13 success criterion 1: the settings menu offers key/button rebinding. Phase 3 ships Xbox-style tiles only (D-24 discretion); the owner passed the physical DualShock 4 in UAT test 23 reading the Xbox glyphs with the PS equivalents"
  - truth: "Animated puppets and final Barracks / Archery Range art (units are static bind-pose models, buildings are kit-piece placeholders)"
    addressed_in: "Phase 8"
    evidence: "ROADMAP Phase 8 'Art, Readability & Sound'; 03-01 and 03-02 SUMMARY D8 and the PLAYTEST-GATE 'what nobody has checked' list. Informational only, no roadmap truth of Phase 3 depends on animation"
  - truth: "Hundreds of units, batched rendering, flow-field pathing, 200-unit stress test"
    addressed_in: "Phase 4"
    evidence: "03-CONTEXT.md 'Not in this phase'; ROADMAP Phase 4 success criterion 2 (200+ enemies through a gate). Phase 3 keeps units in the manager so the switch needs no simulation change"
warnings:
  - id: "Owner gate (UAT test 24) was passed without the full two-or-three-run playtest (owner decision, recorded, not a gap)"
    where: "03-UAT.md test 24 note; 03-PLAYTEST-GATE.md"
    issue: "The owner signed off on 2026-10-14 with 'I dont want to go through the playtest and it seems fine. might come back and change stuff later though.' The fixed build (exe from ca8086a) was launched and played for test 18 only; the pad was played for a full night on a physical DualShock 4 (test 23). So the feel clauses of the roadmap criteria (fun, tension, command feel over a whole run on both devices) rest on a lighter owner check than the packet asked for, plus bots, 1427 green tests, probes and screenshot reads. The owner reserves the right to revisit assumptions 1 to 15 later."
    decision_requested: "None. This is the owner's recorded decision and I weigh it as given. If play later shows a problem, it re-opens as a new gap, not as a defect of this verification."
  - id: "Round 2 balance: what it cost (accepted by the owner at UAT test 18, informational)"
    where: "data/buildings/tower.tres tier 1 attack_interval 0.9, tests/integration/test_balance_acceptance.gd, 03-BALANCE-REPORT.md Round 2 'What the numbers say'"
    issue: "No data file has moved since 4da6799 (git diff is empty for data/) and the full run at HEAD 7f5cb65 kept test_balance_acceptance green, so the numbers stand: balanced 8 of 10, army_balanced 8 of 10, squad_value_ratio 0.915 against the 0.8 bar, night 8 at 40 against 39. The cost remains: towers_first wins 0 of 10 (was 3) and houses_first 4 of 10 (was 9), the Phase 2 pin 'the owner's tower opening wins at least 2 of 3' was re-pinned to 'survives at least 6 nights on every pinned seed', and the army bot loses 17.6 buildings a run. The owner played the fixed build and passed this trade on 2026-10-14."
    decision_requested: "None."
  - id: "gsd-tools key-link miss on 03-13 link 1 (tooling drift, informational, unchanged)"
    where: ".planning/phases/03-king-combat-troops/03-13-PLAN.md key_links[0] pattern `SquadOrderIntent.new\\(ids, verb`"
    issue: "verify.key-links reports 51 of 52 verified (re-run by me). The WR-03 fix reformatted the call in input/command_key_controller.gd _give across lines, so the one-line literal pattern no longer matches. The link is intact (_give submits the intent with the queue flag through CommandProcessor, SquadSystem.apply_order appends a queued verb) and test_command_keys 17/17 pins it. The plan file is a closed historical document; I did not edit it."
    decision_requested: "None."
  - id: "Payout line: two records disagree (informational, unchanged, owner passed UAT test 20)"
    where: "ui/hud/dawn_payout_vfx.gd TOTAL_SHOWN_SECONDS = 2.0 (a wall-clock tween), UAT test 14, 03-UI-REVIEW.md Top 3 fix 1"
    issue: "UAT p14 and p20 measured the '+N gold' line expiring within 1 s of the day starting in real time; the UI review reads the same line under the gold counter in fast-forwarded night captures. Phase 1 and 2 code outside this phase's files; no success criterion depends on it; the owner passed test 20."
    decision_requested: "None; fix later if it shows in play."
  - id: "Stale sentence in the gate packet about the exported build (informational, documentation only)"
    where: "03-PLAYTEST-GATE.md 'How to play' first bullet"
    issue: "The packet still says build/windows/Duskhold.exe was exported on 2026-10-12 from c418b6c. 03-UAT.md (Round 3 note, footer and test 23 and 24 notes) records that it was re-exported from ca8086a on 2026-10-13T21:51Z and that the owner played that build. The file on disk is dated Oct 14 02:51 local, which is that export. Nothing in code depends on the sentence; I did not launch the exe."
    decision_requested: "None; correct the sentence if the packet is reused for a later gate."
  - id: "Shift is both sprint and queue (behaviour note from 03-13, unchanged, owner passed UAT test 17)"
    where: "input/command_key_controller.gd _give, project.godot command_queue"
    issue: "Pressing F, H or R while sprinting with Shift held queues the verb behind the selection's walks instead of replacing them. Consistent with D-09 and with Shift right-click moves; with nothing queued the verb runs at once. A verb behind a queue that already ends in a hold, follow or patrol shows the QUEUE_CLOSED toast."
    decision_requested: "None."
behavior_unverified_items: []
human_verification:
  - name: "G-03-4 re-check: the floating bar over the king and the bottom-left widget agree after a heal"
    requirement: "KING-05, UI-01"
    test: "Take a hit or two at night (or from an enemy by day), stop being hit, and watch the small bar floating over the king and the health bar bottom-left while the king regenerates; look at the moment he is whole again"
    expected: "Both climb together, one point at a time, to the same number; the floating bar disappears once he is at full health (it used to freeze at the last damaged value while the widget climbed; fixed by plan 03-14, 10 heals measured equal in a real window; test_king_knockout 5/5 re-run by me)"
    why_human: "The tests and the scripted real-window probe show the numbers agree; whether the two readouts read as one in motion, over the real scene, is a by-eye judgement (UAT test 4 re-check)"
    uat_test: 16
    uat_result: pass
  - name: "G-03-8 re-check: Shift-queued hold (and RT on the pad)"
    requirement: "UNIT-10, INPT-01, INPT-02"
    test: "Select a squad, Shift + right-click three points, then press Shift + H; repeat with Shift + F and Shift + R; press plain H after a queued walk; on a pad hold RT and press D-pad down"
    expected: "The squad walks all three points and then holds at the last one (move here, then hold); plain H still stops it at once and holds where it stands; Shift + F and Shift + R queue the follow and the rally the same way; Shift while sprinting now queues a verb, which should not surprise. A hold pressed behind a queue that already ends in a hold, follow or patrol is now refused with a toast (review-fix WR-03; judged in item 10), no longer silently"
    why_human: "Real keys and a real window were driven by the executor (03-13 probe lines: orders move, move, move, hold, held at the third point; test_command_keys 17/17 and test_pad_commands 18/18 re-run by me), but the gesture's feel and the hint row's 'Queue' wording are the owner's to judge (UAT test 8 re-check)"
    uat_test: 17
    uat_result: pass
  - name: "G-03-11 re-check: Round 2 balance feel (0.9 s first tower, nights 5 to 8 at 25 / 31 / 39 / 40)"
    requirement: "UNIT-04, UNIT-07"
    test: "Play three nights with an army, including nights 5 to 8, and read the Round 2 section of 03-BALANCE-REPORT.md; open with a tower on day 1 and see whether a first tower that fires every 0.9 s (was 0.8 s) still feels like a good opening"
    expected: "Nights feel tense with squads; the owner accepts or rejects the reported trade: the balanced bot wins 8 of 10 and the army bot 8 of 10 (goals met), squads score 0.915 against the 0.8 bar mostly because towers got weaker, towers_first wins 0 of 10 and houses_first 4 of 10, the army bot loses 17.6 buildings a run, night 8 is now 40 against 39"
    why_human: "The bots build instantly and react perfectly and cannot judge tension or whether an opening feels rewarding; the report states the numbers measure the data only (D-08, Phase 2 D-18, UAT test 11 re-check)"
    uat_test: 18
    uat_result: pass
  - name: "G-03-13 re-check: the knocked-out king's '0 / 50'"
    requirement: "UI-01"
    test: "Get the king knocked out at night and read the bottom-left widget (count, the dimmed bar and sword plate, the Slam caption) and the 'Knocked out, back in N s' label"
    expected: "The red 0 / 50 and the Slam caption are crisp and readable, the bar and sword plate are visibly dimmed; the knocked-out state still reads as knocked out (measured 5.88:1 on the real capture, was 1.62:1)"
    why_human: "A contrast number and one capture approximate legibility; the owner's eyes on a real monitor and a real night decide (UAT test 13 re-check). The probe's guard and measurement are now unit-tested (WR-04 fixed, 10/10 re-run by me)"
    uat_test: 19
    uat_result: pass
  - name: "G-03-14 re-check: singular copy at a count of one (and the payout line)"
    requirement: "UI-01"
    test: "Leave exactly one enemy at night and read the banner; on a day whose night has one enemy read the preview; after a dawn watch the '+N gold' line under the gold counter"
    expected: "'Night N of 8 - 1 enemy left' and 'Night N: 1 enemy from 1 direction' (and plural for any other count); the payout line goes away by the time the day is under way and does not sit under the gold counter at night (UI-REVIEW saw it in fast-forwarded night captures; UAT p14 saw it expire within 1 s in real time)"
    why_human: "The copy is test-pinned and I viewed the banner shot in the second report; whether the payout line behaves in real play, and whether it matters, is the owner's call (UAT test 14 re-check)"
    uat_test: 20
    uat_result: pass
  - name: "G-03-14b re-check: the plated start-night prompt leads the day's bottom centre"
    requirement: "UI-01"
    test: "On a day with a squad selected (cyan slot border) look at the bottom-centre stack: hint row, squad slots, the plated 'Hold N to start Night N' prompt with its fill bar, and the preview line below it"
    expected: "The start-night prompt reads as the day's focal point beside the selected slot (it now has a #14141A plate at y 624..690 below the strip, preview unplated below it); the five-layer column does not feel cluttered. UI-REVIEW still sees the cyan 4 px border as the most saturated element in the column and scores Visuals 3/4"
    why_human: "Hierarchy and clutter are a visual judgement; the geometry is test-pinned (test_start_night_plate 6/6 re-run by me after the IN-09 edit) and the clear-centre check passed on 33 of 33 shots, but whether the prompt leads is the owner's (UAT test 14 re-check, UI-REVIEW fix 3)"
    uat_test: 21
    uat_result: pass
  - name: "E6: longest toast inside x 384..896"
    requirement: "UI-01"
    test: "Select a squad, ride to the edge of the ground and right-click off the map to raise the Can't go there toast; then select a squad, press Shift + H, and press Shift + F (or Shift + right-click) to raise the Nothing can be queued after Hold, Follow or Patrol toast"
    expected: "The owner accepts the two one-line toasts (Can't go there: 526 px, x 377..903; Nothing can be queued: 540 px, x about 370..910, both entirely below the clear centre at y 504..536), or has the copy shortened, or amends the UI-SPEC bound to the real longest line. The 540 px figure is new in this report: the fix pass added the toast and no record or test measured it"
    why_human: "A 7 to 14 px per side miss of a literal band that never touches the protected rectangle is a spec-versus-taste call (03-12 D4, .planning/WINDOWS.md, D-28: decided after the owner plays the fixed build; UAT test 22 pending)"
    uat_test: 22
    uat_result: pass
    uat_note: "Owner decision 2026-10-14: accept both toasts as they are (526 px and 540 px, y 504..536) and amend the UI-SPEC toast bound; recorded as D-29 in 03-CONTEXT.md"
  - name: "Gamepad on a physical pad"
    requirement: "INPT-02"
    test: "Play one full night on a real pad: ride, sprint (RB), build (A), start night (Y), slam (X), D-pad verbs, hold RT for the queue (RT + D-pad queues the verb; RT + a cursor point verb behind a closed queue now shows the refusal toast), LB layer for move / attack-move / patrol with the right-stick cursor (900 px/s), R3 select all, LB+R3 select type, Start group mode, B to cancel, D-pad right to cycle"
    expected: "Every in-run action is reachable on the pad with nothing needing a pointer; cursor speed, button feel, trigger edges and the chord layout feel right"
    why_human: "No gamepad is connected to this machine, so every pad event in every test, probe and screenshot was synthetic; the pad layout was chosen by Claude, not the owner (UAT test 9 blocked on physical-device; 03-09 D6, assumption 8)"
    uat_test: 23
    uat_result: pass
    uat_note: "Owner passed on a physical DualShock 4 (known SDL mapping, 29 pad-bound actions) playing the fixed build (exe from ca8086a), 2026-10-15T16:27:11Z; the HUD Xbox glyph set was read with the PS equivalents"
  - name: "Owner Phase 3 gate: two or three full runs on both devices, then sign off or name fixes"
    requirement: "UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, KING-04, KING-05, INPT-01, INPT-02, UI-01"
    test: "Make sure the build is the current tree (re-run `bash tools/export.sh`, or launch the editor binary; the exe on disk is dated 2026-10-13T21:51Z, after the fix pass, but its source commit is unconfirmed and 03-PLAYTEST-GATE.md still says it is stale); play two or three full 8-night runs with an army, once on keyboard and mouse and once on a gamepad, switching device at least once per run, following 03-PLAYTEST-GATE.md"
    expected: "A recorded decision through /gsd-verify-work: sign off (squads guard and commit, selection and commands feel right on both devices, slam and regeneration suit the game, the HUD reads at night with the centre clear, the Round 2 nights are tense) or a list of fixes and any of assumptions 1 to 15 to change. No Phase 4 work starts before it"
    why_human: "The feel clauses of the success criteria (fun, tension, readability, commands that feel right) and the delegated playtest gate (D-08, Phase 2 D-18) are the owner decision; bots, CI, 1427 green tests, probes and screenshot reviews are not the sign-off (UAT test 15)"
    uat_test: 24
    uat_result: pass
    uat_note: "Owner signed off 2026-10-14 WITHOUT the full two-or-three-run playtest (it seems fine, might come back and change stuff later, in the owner's words); the fixed build was played for test 18 only; the owner reserves the right to revisit assumptions 1 to 15"
  - name: "Refused-queue and patrol-full toasts, and the mixed-selection rule (review-fix pass 1: WR-03, IN-06)"
    requirement: "UNIT-10, INPT-01, INPT-02, UI-01"
    test: "Select a squad, Shift + right-click a point, press Shift + H, then press Shift + F (or Shift + right-click again): read the toast. Arm patrol (P) and right-click eight points: read the toast on the eighth. Select two squads, give both a move, queue a hold on only one of them, then Shift + right-click a point: watch which squads take it"
    expected: "'Nothing can be queued after Hold, Follow or Patrol' shows once when every selected squad already ends in a hold, follow or patrol (1.5 s, one line, in the hint-strip slot) and reads at the moment you needed it; 'A patrol takes up to 7 points' shows on the eighth patrol click and adds no point; in a mixed selection the open squad queues the new order and the closed squad is skipped with no toast, which should read as sensible rather than as a missed command (width of both lines is decided in item 7)"
    why_human: "Copy, timing and the refusal paths are pinned by tests (test_squad_queue 17/17, test_command_keys 17/17, test_mouse_commands 16/16, test_pad_cursor 10/10 re-run by me) and the 03-VALIDATION manual-only table lists this check; whether the line reads in the moment, whether the silent skip of a closed squad in a mixed selection is the right call, and whether the 540 px line is acceptable are judgements (new UAT test 25)"
    uat_test: 25
    uat_result: pass
---

# Phase 3: King Combat & Troops Verification Report (fourth report, after review-fix pass 2 and the UAT completion)

**Phase Goal:** The king leads an army. The player builds a Barracks and an Archery Range whose squads fight on their own, commands them RTS-style with hotkeys, mouse selection and control groups, and fires the weapon's active ability. All of it is fully playable on keyboard and mouse or on gamepad with a complete in-run HUD.
**Verified:** 2026-10-15T19:51:19Z
**Status:** passed
**Re-verification:** Yes. This is the fourth report. It supersedes the third report of 2026-10-14T06:30:48Z (HEAD a67956e; written `human_needed`, canonicalized to `passed` on 2026-10-15 after the UAT closed). Since then: review-fix pass 2 (db5e138 IN-10, 2471438 IN-11) changed `tests/unit/test_contrast_probe.gd`, `tests/unit/test_separation.gd` and `simulation/squads/separation.gd`; the fifth code review (scope: those three files) found nothing; the owner completed the UAT (25 of 25 passed); the phase was marked complete and transitioned. `git diff 7f5cb65 HEAD -- . ':!.planning/'` is empty, so the orchestrator's full run at 7f5cb65 is the full-suite evidence for the current code, and `git diff ca8086a HEAD --stat -- . ':!.planning/'` lists exactly those three files (43 insertions, 7 deletions).

## Verdict

The goal is achieved and nothing remains open. I found no FAILED roadmap truth, no FAILED gap truth, no missing or stubbed artifact, no unwired link, no debt marker and no regression of the Phase 1 or Phase 2 suites. The two info findings that kept the third report from being clean (IN-10, IN-11) are fixed in code: I read the three changed files at HEAD, re-ran both test scripts, both golden replays and lint in my own process, and re-ran `verify.artifacts` and `verify.key-links` over all 19 plans. The ledger on disk reads `open: 0`, `total: 16`, every row `fixed`, and the fifth review (2026-10-15T19:40:06Z, three files) is `status: clean` with 0 findings.

The status is `passed` because the only evidence that was ever an owner judgement now exists as the owner's recorded decision. The ten `human_verification` items of the third report are UAT tests 16 to 25 one to one, and 03-UAT.md (`status: complete`, 25 passed, 0 issues, 0 blocked) records each as `pass`. Pass 2 changed two test files and a debug-only assert, no pixel and no gameplay value, so there is nothing new for the owner to judge and I added no human item. I weighed three owner decisions as recorded and did not re-open them: test 24 (the gate) was passed without the full two-or-three-run playtest ("it seems fine, might come back and change stuff later"), test 23 was passed on a physical DualShock 4, and test 22 accepted both long toasts, which is D-29 in 03-CONTEXT.md and removes the E6 warning of the third report (UI-SPEC lines 133 and 331 carry the amended bound; `Toast.CANT_GO_THERE` and `Toast.QUEUE_CLOSED` are unchanged in `ui/hud/toast.gd`).

The one thing worth saying plainly: the feel clauses of the roadmap criteria rest on a lighter owner check than the playtest packet asked for (test 24 was a sign-off, not a three-run playtest). That is the owner's call and it is recorded as a warning in the frontmatter, not a gap.

ROADMAP marks Phase 3 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form (as in Phase 2), so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD ef413ee (Godot 4.7.2, Windows). `git status` was clean before and after (the replays write nothing); I modified no source, data or test file, killed no process and committed nothing. The only artefacts outside this report are two scratch assembly files in the session scratchpad, outside the repository.

| Check | Command | Result |
|---|---|---|
| IN-10 fix | `bash tools/test.sh -gselect=test_contrast_probe` | 10/10 passing, 68 asserts (the fix added one assert) |
| IN-11 fix and IN-03 routine | `bash tools/test.sh -gselect=test_separation` | 7/7 passing, 40 asserts |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` |
| Army replay vs golden | `bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json` | `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (both unchanged by pass 2) |
| Lint and format | `bash tools/lint.sh` | `269 files would be left unchanged`, `Success: no problems found` |
| Plan artifacts | `gsd-tools query verify.artifacts` on each of the 19 plans | 81/81 pass |
| Plan key links | `gsd-tools query verify.key-links` on each of the 19 plans | 51/52 (only 03-13 link 1, the regex drift described in the warnings; wiring intact by reading) |
| Debt markers | grep TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER over the three files pass 2 changed | none |
| Source scope since the third report | `git diff --stat ca8086a HEAD -- . ':!.planning/'` and `git diff 7f5cb65 HEAD -- . ':!.planning/'` | exactly separation.gd, test_contrast_probe.gd, test_separation.gd; the second diff is empty |
| Requirements | plan frontmatter `requirements:` vs REQUIREMENTS.md | the same 11 IDs in both, 11 `\| Phase 3 \| Complete \|` rows |
| Regression gate | 29 Phase 1 and Phase 2 test script names that appear in 01- and 02-VERIFICATION.md and exist under tests/, checked by name against the full-run log | all 29 appear in `postfix2_full.log` |

Taken from the orchestrator without re-running: the full suite at HEAD 7f5cb65 (153 scripts, 1427/1427 tests, 15886 asserts, 510.6 s, exit 0, which I confirmed from the tail of `postfix2_full.log`); the mutation probes of 2026-10-15 for pass 2 (log `mutate_fix2.log`, paragraph in 03-VALIDATION.md): IN-10 with the old inside-the-project expression fails 1 of 10, IN-11 stays 7/7 with the footman radius retuned and fails 5 of 7 when the routine pushes nothing, and the new precondition assert is a documented debug-only guard no suite exercises by design (a mismatched-length call is a script error, not behaviour); CI run 38774381177 on 7f5cb65 (lint, test, screenshots, export all green); the pass-1 mutation probes of 2026-10-14 listed in the third report. I did not run the full suite, the game window, the playtest bots or `tools/screenshot.sh`.

## Goal Achievement

### ROADMAP success criteria (the contract), re-checked at HEAD

| # | Success criterion | Status | Evidence (delta since the third report) |
|---|---|---|---|
| 1 | Barracks and Archery Range; units guard and commit; night trickle back; full restore at dawn | VERIFIED in code and tests; owner passed the feel at UAT tests 1, 2, 24 | Pass 2 touched `Separation.displacements` only by adding a debug-only `assert` on the parallel-array precondition and a header note (separation.gd lines 14-24); the loop body, operation order and arithmetic are the ones the goldens pin, and both goldens are byte-identical (703 and 1353 ticks, same digests). test_separation 7/7 re-run. Squad guard, respawn, lifecycle and stance tests were green in the 7f5cb65 full run |
| 2 | Select squads (click, box, Ctrl; pad cycling); control groups; hold, follow, rally, move, attack-move, patrol, Shift queue; stances persist | VERIFIED in code and tests; owner passed UAT tests 6, 7, 8, 17, 25 | No file of the order controllers or the simulation's order code changed in pass 2. The refusal toast, the all-closed gate and the per-squad skip of a closed squad were shown in a real window in UAT tests 17 and 25 |
| 3 | Active ability with visible cooldown; king health regenerates after a short time | VERIFIED in code and tests; owner passed UAT tests 4 and 16 | Unchanged by pass 2 |
| 4 | Every in-run action on keyboard and mouse and on gamepad; switch devices any time; prompts follow the device | VERIFIED in code and tests; owner passed a full night on a physical DualShock 4 (UAT test 23) | Unchanged by pass 2. The earlier caveat that every pad event was synthetic no longer holds: UAT test 23 records the physical pad |
| 5 | HUD shows gold, night N of total, king health, ability cooldown and unit status without cluttering the play area | VERIFIED in code, tests and the runner check; owner passed UAT tests 3, 13, 21, 22 | Unchanged by pass 2. D-29 (UAT test 22) accepts the two long one-line toasts at y 504..536 below the protected centre and amends the UI-SPEC bound; the UI review is reused unchanged because pass 2 changed no pixel |

### UAT round-1 gaps (the second contract)

| Gap | Truth | Status | Evidence |
|---|---|---|---|
| G-03-4 (WR-01) | The floating bar over the king and the widget agree after a heal | VERIFIED | king.gd not changed since; test_king_knockout in the full runs; real-window probe of 10 heals equal (UAT test 16, passed) |
| G-03-8 | Shift-queue several moves then a hold: the hold runs after the walks (D-09) | VERIFIED | test_command_keys and test_pad_commands in the full runs; real-window probe verbs `[move, move, move, hold]` (UAT test 17, passed) |
| G-03-13 | The knocked-out '0 / 50' is readable | VERIFIED | contrast 5.88:1 on a fresh real-window capture (UAT test 19, passed); the probe's guard and measurement are unit-tested (test_contrast_probe 10/10, re-run by me, now with the corrected outside-the-project case) |
| G-03-14 | Singular copy at a count of one | VERIFIED | test_spawn_telegraph in the full runs; real-window read (UAT test 20, passed) |
| G-03-14b | The start-night prompt reads as the day focal point beside a cyan selected slot | VERIFIED | test_start_night_plate in the full runs; the owner judged the real-window crop (UAT test 21, passed) |
| G-03-11 | Nights 5 to 8 serve the four owner goals at once | VERIFIED as pinned measurements; feel passed by the owner | No data file moved; test_balance_acceptance, test_night_data_contract and test_military_data_contract green in the full run; the owner played the fixed build (UAT test 18, passed) |

### Review-fix passes (the third contract)

| Finding | Claim | Status | Evidence |
|---|---|---|---|
| CR-01, WR-01 to WR-04, IN-01 to IN-09 (pass 1) | As in the third report | FIXED, unchanged | No source or test file of them changed after the third report except the three below; the full run at 7f5cb65 is green |
| IN-10 (pass 2) | The 'outside the project' path case really leaves the project | FIXED, verified | test_contrast_probe.gd lines 104-135 at HEAD: `in_parent_folder` = `globalize_path("res://").path_join("../outside/x.png").simplify_path()`, an `assert_false(localize_path(...).begins_with("res://"))` before the loop, and the case sits in the `bad` list that must produce an error and an empty image. 10/10, 68 asserts, re-run by me |
| IN-11 (pass 2) | The separation characterization is decoupled from shipped radii; the private seam is commented; the precondition is asserted | FIXED, verified | test_separation.gd lines 10-18: `FOOTMAN_RADIUS`, `ARCHER_RADIUS`, `GRUNT_RADIUS`, `RANGED_RADIUS` constants with a comment naming review IN-11 and `_unit_def` / `_enemy_def` helpers that build inline defs (no `load("res://data/...")` remains in the header section I read); separation.gd lines 14-24: header note plus `assert(radii.size() == positions.size() and ids.size() == positions.size(), ...)`. 7/7, 40 asserts, re-run by me; goldens identical |

### Plan must_haves

188 plan truths and 25 prohibitions are declared. All 81 declared artifacts pass gsd-tools; key links are 51/52 by the tool and 52/52 by reading. The fix passes are outside the plans, so their truths are the fifteen findings above rather than frontmatter truths; none of the 188 plan truths concerns a file pass 2 changed in a way that alters behaviour for shipped data (goldens byte-identical).

Decision check against 03-CONTEXT.md: D-26 (squad value bar 0.8) honored (no override, no data moved); D-27 honored (nights 1 to 4 untouched); D-28 honored; D-29 (E6) honored: `Toast.CANT_GO_THERE` and `Toast.QUEUE_CLOSED` are unchanged, UI-SPEC row 133 and the E6 row at 331 carry the measured 526 px and 540 px lines and the amended bound.

Prohibitions (all judgment-tier or backstop; my reading is NON-AUTHORITATIVE and flagged `unverified-prohibition - human review recommended`, none is absorbed into the pass): see the frontmatter note. Pass 2 did not touch any file a plan prohibition names beyond separation.gd, where it added only a debug-only assert and a comment.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| command_key_controller.gd `_give` | command_processor.gd `submit` | `SquadOrderIntent.new(...)` with the queue flag, then `Toast.refusal_text(reason)` | WIRED | The tool misses the 03-13 literal because the call spans several lines; unchanged since the third report |
| selection_controller.gd `_order` / `_right_click` | `submit` and `Toast.PATROL_FULL` | result to `refusal_text`; eighth patrol click to `feedback.emit` | WIRED | Unchanged; shown in a real window (UAT test 25) |
| pad_cursor_controller.gd `_confirm` | `submit` | result to `refusal_text` | WIRED | Unchanged |
| `UnitSystem.separate` and `EnemySystem._separate` | `Separation.displacements` | packed arrays in ascending id order (the precondition the new assert states) | WIRED | Both callers build the three arrays in lockstep; goldens identical |
| `MapConfig.ground_limit_cm` | `CommandProcessor._ground_limit_cm` and `GroundPick.in_bounds` | one static rule | WIRED | Unchanged |
| `CommandProcessor._every_queue_is_closed` | `SquadSystem.apply_order` | same terminal-order test | WIRED | Unchanged |

### Requirements Coverage

All 11 phase IDs appear in at least one plan `requirements:` field (I extracted them from the 19 plans' frontmatter and they are exactly KING-04, KING-05, UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, INPT-01, INPT-02, UI-01), and REQUIREMENTS.md maps exactly these 11 to Phase 3, each `Complete`. No ID is orphaned or missing from a plan. INPT-03 stays open by design (Phase 13).

| Requirement | Status | Evidence |
|---|---|---|
| UNIT-04 | SATISFIED | Criterion 1; goldens identical; UAT tests 1, 24 |
| UNIT-05 | SATISFIED | Hold on H and pad D-pad down; Shift+H queues a hold behind walks (UAT 17) |
| UNIT-06 | SATISFIED | Follow on F / D-pad up; select all and select type |
| UNIT-07 | SATISFIED | Trickle and dawn restore (UAT 2) |
| UNIT-09 | SATISFIED | Selection and control groups (UAT 6, 7) |
| UNIT-10 | SATISFIED | Criterion 2 (UAT 8, 17, 25) |
| KING-04 | SATISFIED | Slam values unchanged; UAT 5 |
| KING-05 | SATISFIED | Criterion 3 (UAT 4, 16) |
| INPT-01 | SATISFIED | Criteria 2 and 4 |
| INPT-02 | SATISFIED | Criterion 4, including the physical pad (UAT 23) |
| UI-01 | SATISFIED | Criterion 5 (UAT 3, 13, 21, 22) |

### Data-Flow Trace (Level 4)

FLOWING for everything pass 2 touched, which is test-only plus one debug assert: `Separation.displacements` still returns the summed per-circle displacements the two systems add to their records; nothing in the data path changed. The pass-1 chain (`CommandProcessor.submit` reason to `Toast.refusal_text` to `feedback` to the toast label) is unchanged and was exercised in a real window in UAT tests 17 and 25.

### Behavioral Spot-Checks and Replays

See "What I ran". The behavior-dependent truths of pass 2 each have a named passing test I re-ran (the outside path is rejected and really outside; the shared routine reaches the pinned positions with inline radii; the routine's pure cases), and the orchestrator's mutation probes show the IN-10 assertion fails against the old path and the IN-11 characterization fails when the routine stops pushing while ignoring a shipped radius retune. `behavior_unverified: 0`. The debug-only precondition assert is the one change no test can exercise, by design (a mismatched call is a script error in a debug build and stripped from a release export); it is documented in the file header and in 03-VALIDATION.md, and it guards a precondition both callers satisfy.

### Probe Execution

No `probe-*.sh` files are declared by the phase plans or exist under `scripts/`: SKIPPED. (`tools/contrast_probe.sh` is a measurement tool, unit-tested, not a declared verification probe.)

### Anti-Patterns Found

None. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in the three files pass 2 changed.

## Code-review findings (0 OPEN, 16 FIXED)

03-REVIEW-DISPOSITION.md on disk: `open: 0`, `total: 16`, every row `fixed` (IN-10, IN-11, WR-04, IN-07, IN-08, IN-09, CR-01, WR-01, WR-02, WR-03, IN-01 to IN-06). 03-REVIEW.md on disk is the fifth review: `status: clean`, 0 critical, 0 warning, 0 info, files reviewed 3 (separation.gd, test_contrast_probe.gd, test_separation.gd), re-verifying both pass-2 fixes. 03-SECURITY.md: `threats_open: 0`, 32 of 32 threats closed, the 2026-10-15 re-audit adds no new surface.

## Human Verification

The structured list in the frontmatter keeps the ten entries of the third report with the same names and order. Each now carries `uat_test` (16 to 25) and `uat_result: pass`; tests 22, 23 and 24 also carry the owner's note. There is no pending human item and I added none: pass 2 changed no behaviour, no data and no pixel. The list is kept as the audit trail of what the owner judged, not as work to do. The first-round items (UAT tests 1 to 15) were passed, superseded with the owner's approval, or covered by tests 16 to 25, as recorded in 03-UAT.md.

## Gaps Summary

No gaps and no blockers. All five roadmap success criteria are implemented, wired and tested at HEAD; all six UAT round-1 gaps are closed with a test that fails when the fix is removed; all 15 review findings of the two fix passes are fixed and re-verified (ledger 0 of 16 open, fifth review clean); the replays are byte-identical to their goldens, lint is clean and the 1427-test suite was green on the code that is still current (no non-planning file differs between 7f5cb65 and HEAD); the owner's UAT sign-off is recorded (25 of 25). Phase 4 is not blocked by anything in this report. If any file in the covered list changes, re-run `verification.status` to refresh the fingerprint.

---

_Verified: 2026-10-15T19:51:19Z_
_Verifier: Claude (gsd-verifier)_
