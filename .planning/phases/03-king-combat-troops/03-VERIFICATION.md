---
phase: 03-king-combat-troops
verified: 2026-10-14T06:30:48Z
status: passed
score: 5/5 roadmap success criteria verified in code and tests (0 failed); 6/6 UAT round-1 gap truths closed in code, tests and probes (0 failed); 13/13 review-fix-pass findings fixed and re-verified (0 regressions); 11/11 requirement IDs have implementation evidence; owner feel gate (UAT test 24), the physical pad (test 23, DualShock 4), the E6 decision (test 22, D-29) and the new toast and mixed-selection judgement (test 25) all passed in UAT round 3 (03-UAT.md complete, 25 passed, 0 issues, 2026-10-15)
must_haves:
  roadmap_truths: 5
  roadmap_truths_verified: 5
  roadmap_truths_failed: 0
  gap_truths: 6
  gap_truths_closed: 6
  gap_truths_failed: 0
  review_fix_findings: 13
  review_fix_findings_fixed: 13
  review_fix_findings_regressed: 0
  plan_truths_declared: 188
  plan_artifacts_checked: "81/81 pass (gsd-tools verify.artifacts over all 19 plans, re-run by me)"
  plan_key_links_checked: "51/52 by the tool, 52/52 wired by reading (gsd-tools verify.key-links over all 19 plans; the one tool miss is 03-13 link 1, whose literal regex `SquadOrderIntent.new\\(ids, verb` no longer matches because the WR-03 fix reformatted the call across lines; the link itself is intact, see Key Link Verification)"
  prohibitions_declared: 25
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass. The 25 are plan-scoped (plans 03-01 to 03-19). Review-fix pass 1 is outside any plan: it did change six files under simulation/ (squad_system.gd, unit_system.gd, enemy_system.gd, command_processor.gd, map_config.gd and the new separation.gd), which the earlier note said no commit did, so that sentence of the second report no longer holds for HEAD. Both replay goldens are byte-identical (re-run by me) and git shows no change to project.godot, data/, tests/golden or tests/fixtures since 4da6799"
  requirement_ids: 11
  requirement_ids_satisfied: 11
  requirement_ids_orphaned: 0
re_verification:
  previous_status: human_needed
  previous_score: "5/5 roadmap success criteria verified in code and tests; 6/6 UAT round-1 gap truths closed; 11/11 requirement IDs; 9 human items (the second report of 2026-10-13T20:11:11Z at HEAD e925538, 13 open review findings)"
  report_number: "third report: re-verification after review-fix pass 1 (13 commits 56b2828 to e01971e, 2026-10-13), which made the second report stale; the first report was the initial verification and the second the re-verification after the UAT round-1 gap closure (plans 03-13 to 03-19)"
  gaps_closed:
    - "G-03-4 / WR-01: the floating bar over the king follows regeneration (king.gd connects king_healed, line 54, handler lines 101-103; test_king_knockout 5/5 re-run by me again in this report)"
    - "G-03-8: Shift (pad RT) queues the F, H and R verbs behind queued walks (command_key_controller.gd _give reads the queue action; test_command_keys 17/17 and test_pad_commands 18/18 re-run by me; the pass-1 IN-08 rename to SelectionController.QUEUE_ACTION kept it working)"
    - "G-03-13: the knocked-out '0 / 50' stays opaque on its own outline (king_widget.gd _apply_knocked_out dims only the bar, plate, icon and glyph; test_king_widget 15/15 in the ca8086a full run; contrast probe CONTRAST_OK ratio=5.88 on screenshots/hud_king_down.png as re-run in the second report, no file it reads changed since)"
    - "G-03-14: singular copy at a count of one (Hud.enemy_count_text; test_spawn_telegraph 22/22 in the ca8086a full run)"
    - "G-03-14b: a plate behind the start-night prompt (StartNightPlate in hud.tscn; test_start_night_plate 6/6 re-run by me after the IN-09 edit to the test and the scene comment)"
    - "G-03-11: Round 2 retune, balanced 8 of 10, army_balanced 8 of 10, squad_value_ratio 0.915 (bar 0.8, D-26), night 8 at 40 above night 7 at 39 (no data file changed in the fix pass; test_balance_acceptance 12/12 re-run in the ca8086a full run, test_balance_value_metric 6/6 re-run by me)"
  review_findings_closed:
    - "CR-01 (critical): SquadSystem._fill (line 148) and restore_for_dawn (line 462) loop once per missing seat, UnitSystem.spawn and heal_to_full floor stored health at 1; test_squad_bad_unit_health 3/3 re-run by me; T-03-04 and T-03-05 closed in 03-SECURITY.md (commit 56b2828)"
    - "WR-02: tools/screenshot.sh tees each shot to build/screenshot-<shot>.log and fails on SCRIPT ERROR, Parse Error or Failed to load script; ci.yml uploads the logs (commit 8d28079); one real shot and a synthetic error-line check per the fix report, not re-run by me (I did not run the game window)"
    - "WR-03: a refused queued order is shown as Toast.QUEUE_CLOSED on the Shift+F/H/R, Shift right-click and pad RT paths; the gate refuses only when every ordered squad is closed and apply_order skips the closed ones (commit 8ad0158); test_squad_queue 17/17, test_command_keys 17/17, test_mouse_commands 16/16, test_pad_cursor 10/10, test_pad_commands 18/18 re-run by me"
    - "WR-04: tests/unit/test_contrast_probe.gd pins the probe's path guard and measurement (commit 2e863c8); 10/10 re-run by me"
    - "IN-01: dead patrol-leg budget assignment removed (67122e9); goldens byte-identical, re-run by me"
    - "IN-02: one MapConfig.ground_limit_cm rule behind the gate and the ground picker (06b3e5c)"
    - "IN-03: Separation.displacements shared by UnitSystem and EnemySystem (14f898d); test_separation 7/7 re-run by me, goldens byte-identical"
    - "IN-04: the two test-only accessors are marked Test hook (9d2d15d)"
    - "IN-05: three unused ext_resource entries removed from the barracks and archery range scenes (2b7d443)"
    - "IN-06: the eighth patrol click toasts Toast.PATROL_FULL (b6ff96f); test_mouse_commands 16/16 re-run by me"
    - "IN-07: BalanceReport._mean reads run keys tolerantly (8adbc3b); test_balance_value_metric 6/6 re-run by me"
    - "IN-08: one SelectionController.QUEUE_ACTION constant for the three order controllers (0ceb7c8)"
    - "IN-09: the plate test reads KingWidget.PLATE_COLOR (e01971e)"
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
covered_digest: "v2:sha256:2e257ae83edea25d3f57e1743cb281c7f304d09e9a3e1573e202dc623bab057a"
behavior_unverified: 0
overrides_applied: 0
gaps: []
deferred:
  - truth: "Glyphs for non-Xbox gamepads and the rebinding UI"
    addressed_in: "Phase 13"
    evidence: "03-CONTEXT.md Deferred Ideas; ROADMAP Phase 13 success criterion 1: the settings menu offers key/button rebinding. Phase 3 ships Xbox-style tiles only (D-24 discretion)"
  - truth: "Animated puppets and final Barracks / Archery Range art (units are static bind-pose models, buildings are kit-piece placeholders)"
    addressed_in: "Phase 8"
    evidence: "ROADMAP Phase 8 'Art, Readability & Sound'; 03-01 and 03-02 SUMMARY D8 and the PLAYTEST-GATE 'what nobody has checked' list. Informational only, no roadmap truth of Phase 3 depends on animation"
  - truth: "Hundreds of units, batched rendering, flow-field pathing, 200-unit stress test"
    addressed_in: "Phase 4"
    evidence: "03-CONTEXT.md 'Not in this phase'; ROADMAP Phase 4 success criterion 2 (200+ enemies through a gate). Phase 3 keeps units in the manager so the switch needs no simulation change"
warnings:
  - id: "E6 widened by the fix pass: the new Toast.QUEUE_CLOSED is the longest toast, 540 px (NEW, owner decision, not a gap)"
    where: "ui/hud/toast.gd QUEUE_CLOSED = \"Nothing can be queued after Hold, Follow or Patrol\" (added by WR-03, commit 8ad0158); 03-UI-SPEC.md E6 long-text row (line 331), .planning/WINDOWS.md ledger row 4, 03-UI-REVIEW.md Spacing and Top 3 fix 2, 03-PLAYTEST-GATE.md line 146 and 167"
    issue: "I measured the toast widths in the real HUD scene (a scratch script in the session scratchpad, headless, hud.tscn instantiated, the Toast label at 22 px): CANT_GO_THERE 526 px (matches the 526 every document quotes, so the method is sound), QUEUE_CLOSED 540 px, PATROL_FULL 299 px, SELECT_FIRST 201 px. At 1280x720 the new toast spans about x 370..910, 14 px past the UI-SPEC literal band x 384..896 on each side (E6 was 7 px). It sits in the same slot, y 504..536, so it stays below the protected rectangle (y 96..500) and the clear-centre rule holds by construction, but every record of E6 still says the longest toast is 526 px (UI-SPEC says about 460 px), no test pins either number and no screenshot shows the new toast (the 33 shots contain only hud_long_toast for the Can't go there line). 03-UI-REVIEW.md, kept as is because the fix pass 'changed no pixel', does not know about the two new toasts. It is the same spec-versus-taste call as E6 and goes to the same owner decision, now over two toasts."
    decision_requested: "Owner at UAT test 22 (and 25): accept both, shorten the copy (for example QUEUE_CLOSED to 'Can't queue after Hold, Follow or Patrol', about 440 px, together with the CANT_GO_THERE suggestion in UI-REVIEW), or amend the UI-SPEC bound to the real longest line. If the copy or bound changes, update UI-SPEC rows 281-283 and 331, the WINDOWS.md ledger row and the UI review together."
  - id: "IN-10 (OPEN, info, 03-REVIEW.md fourth review)"
    where: "tests/unit/test_contrast_probe.gd line 121"
    issue: "The 'outside the project' path case is built from ProjectSettings.globalize_path(\"res://\").get_base_dir().path_join(\"x.png\"), which resolves to res://x.png (inside the project, outside screenshots/), so it does not test an absolute path outside the project. The probe code is correct and the intent is still covered by the literal cases /etc/a.png and C:/Windows/a.png. 03-REVIEW-DISPOSITION.md row IN-10: open. I do not describe it as addressed."
    decision_requested: "Fix in a review-fix pass 2 (build a path that really leaves the project) or defer. Not a gap."
  - id: "IN-11 (OPEN, info, 03-REVIEW.md fourth review)"
    where: "tests/unit/test_separation.gd lines 98-124; simulation/squads/separation.gd"
    issue: "UNIT_RESULT and ENEMY_RESULT were captured with the shipped footman, archer, grunt and ranged radii, so retuning any radius fails the test with a position mismatch that points at the separation routine; the enemy case calls the private _separate by string; Separation.displacements has no size check on its three parallel arrays (both callers build them in lockstep, so unreachable today). 03-REVIEW-DISPOSITION.md row IN-11: open."
    decision_requested: "Fix in a review-fix pass 2 (inline the radii, comment the private seam, add an assert) or defer. Not a gap."
  - id: "gsd-tools key-link miss on 03-13 link 1 (tooling drift, informational)"
    where: ".planning/phases/03-king-combat-troops/03-13-PLAN.md key_links[0] pattern `SquadOrderIntent.new\\(ids, verb`"
    issue: "verify.key-links reports 51 of 52 verified (the second report said 52/52). The WR-03 fix reformatted the call in input/command_key_controller.gd _give to `SquadOrderIntent.new(\\n ids, verb, no_points, Input.is_action_pressed(SelectionController.QUEUE_ACTION)\\n)`, so the one-line literal pattern no longer matches. I read the code: the link is intact (_give submits the intent with the queue flag through CommandProcessor, SquadSystem.apply_order appends a queued verb) and test_command_keys 17/17 pins it. The plan file is a closed historical document; I did not edit it."
    decision_requested: "None needed; mention if a later tool run flags 03-13."
  - id: "Round 2 balance: what it cost (judgment call, flagged, unchanged by the fix pass)"
    where: "data/buildings/tower.tres tier 1 attack_interval 0.9, tests/integration/test_balance_acceptance.gd, 03-BALANCE-REPORT.md Round 2 'What the numbers say'"
    issue: "No data file moved in the fix pass (git diff 4da6799 HEAD -- data/ is empty) and the ca8086a full run kept test_balance_acceptance 12/12, so the numbers stand: balanced 8 of 10, army_balanced 8 of 10, squad_value_ratio 0.915 against the 0.8 bar, night 8 at 40 against 39. The cost is as the report states: towers_first wins 0 of 10 (was 3) and houses_first 4 of 10 (was 9), the Phase 2 pin 'the owner's tower opening wins at least 2 of 3' was re-pinned to 'survives at least 6 nights on every pinned seed', the ratio rose mainly because towers got weaker (kills per tower gold 5.93 to 4.70) while squads moved only from 4.04 to 4.31, and the army bot loses 17.6 buildings a run (balanced bot 10.4, was 5.8)."
    decision_requested: "Owner judges at the gate whether a tier 1 tower firing every 0.9 s still feels rewarding, whether the lost tower-route wins matter, and whether squads feel worth their gold."
  - id: "Payout line: two records disagree (informational, unchanged)"
    where: "ui/hud/dawn_payout_vfx.gd TOTAL_SHOWN_SECONDS = 2.0 (a wall-clock tween), UAT test 14 p14, 03-UI-REVIEW.md Top 3 fix 1"
    issue: "UAT p14 measured the '+N gold' line expiring within 1 s of the day starting in real time and called the night captures a fast-forward artefact; the UI review reads the same line under the gold counter in night captures and names the 2 s real-time tween as the cause. Phase 1 and 2 code outside this phase's files; no success criterion depends on it; untouched by the fix pass."
    decision_requested: "Owner glance at the re-check of test 14 (UAT test 20); fix later if it shows in play."
  - id: "Exported Windows build: stale text in the gate packet, mtime says current (informational)"
    where: "build/windows/Duskhold.exe and Duskhold.pck (git-ignored), 03-PLAYTEST-GATE.md line 7 and 03-UAT.md footer"
    issue: "The packet still says the export dates from c418b6c and holds none of the fixes; the UAT footer says it was re-exported from HEAD e925538 on 2026-10-13. The files on disk are dated 2026-10-13T21:51:09Z, 14 minutes after the last fix-pass commit (e01971e, 2026-10-13T21:37:13Z), so by time order the build was exported after the fix pass and should hold CR-01 and the two new toasts. I cannot confirm which commit it was built from (the .pck is compressed; a string search finds none of the strings, not even a Phase 1 one), and I did not launch it."
    decision_requested: "Before the gate, re-run `bash tools/export.sh` (or use the editor binary) so the build is known to be the current tree, and correct the stale sentence in 03-PLAYTEST-GATE.md."
  - id: "Shift is both sprint and queue (behaviour note from 03-13, unchanged)"
    where: "input/command_key_controller.gd _give, project.godot command_queue"
    issue: "Pressing F, H or R while sprinting with Shift held queues the verb behind the selection's walks instead of replacing them. Consistent with D-09 and with Shift right-click moves; with nothing queued the verb runs at once, so it only shows when walks are queued. Since WR-03, a verb behind a queue that already ends in a hold, follow or patrol now shows the QUEUE_CLOSED toast instead of being silently refused."
    decision_requested: "Owner to say at the gate whether this surprises in play."
behavior_unverified_items: []
human_verification:
  - name: "G-03-4 re-check: the floating bar over the king and the bottom-left widget agree after a heal"
    requirement: "KING-05, UI-01"
    test: "Take a hit or two at night (or from an enemy by day), stop being hit, and watch the small bar floating over the king and the health bar bottom-left while the king regenerates; look at the moment he is whole again"
    expected: "Both climb together, one point at a time, to the same number; the floating bar disappears once he is at full health (it used to freeze at the last damaged value while the widget climbed; fixed by plan 03-14, 10 heals measured equal in a real window; test_king_knockout 5/5 re-run by me)"
    why_human: "The tests and the scripted real-window probe show the numbers agree; whether the two readouts read as one in motion, over the real scene, is a by-eye judgement (UAT test 4 re-check)"
  - name: "G-03-8 re-check: Shift-queued hold (and RT on the pad)"
    requirement: "UNIT-10, INPT-01, INPT-02"
    test: "Select a squad, Shift + right-click three points, then press Shift + H; repeat with Shift + F and Shift + R; press plain H after a queued walk; on a pad hold RT and press D-pad down"
    expected: "The squad walks all three points and then holds at the last one (move here, then hold); plain H still stops it at once and holds where it stands; Shift + F and Shift + R queue the follow and the rally the same way; Shift while sprinting now queues a verb, which should not surprise. A hold pressed behind a queue that already ends in a hold, follow or patrol is now refused with a toast (review-fix WR-03; judged in item 10), no longer silently"
    why_human: "Real keys and a real window were driven by the executor (03-13 probe lines: orders move, move, move, hold, held at the third point; test_command_keys 17/17 and test_pad_commands 18/18 re-run by me), but the gesture's feel and the hint row's 'Queue' wording are the owner's to judge (UAT test 8 re-check)"
  - name: "G-03-11 re-check: Round 2 balance feel (0.9 s first tower, nights 5 to 8 at 25 / 31 / 39 / 40)"
    requirement: "UNIT-04, UNIT-07"
    test: "Play three nights with an army, including nights 5 to 8, and read the Round 2 section of 03-BALANCE-REPORT.md; open with a tower on day 1 and see whether a first tower that fires every 0.9 s (was 0.8 s) still feels like a good opening"
    expected: "Nights feel tense with squads; the owner accepts or rejects the reported trade: the balanced bot wins 8 of 10 and the army bot 8 of 10 (goals met), squads score 0.915 against the 0.8 bar mostly because towers got weaker, towers_first wins 0 of 10 and houses_first 4 of 10, the army bot loses 17.6 buildings a run, night 8 is now 40 against 39"
    why_human: "The bots build instantly and react perfectly and cannot judge tension or whether an opening feels rewarding; the report states the numbers measure the data only (D-08, Phase 2 D-18, UAT test 11 re-check)"
  - name: "G-03-13 re-check: the knocked-out king's '0 / 50'"
    requirement: "UI-01"
    test: "Get the king knocked out at night and read the bottom-left widget (count, the dimmed bar and sword plate, the Slam caption) and the 'Knocked out, back in N s' label"
    expected: "The red 0 / 50 and the Slam caption are crisp and readable, the bar and sword plate are visibly dimmed; the knocked-out state still reads as knocked out (measured 5.88:1 on the real capture, was 1.62:1)"
    why_human: "A contrast number and one capture approximate legibility; the owner's eyes on a real monitor and a real night decide (UAT test 13 re-check). The probe's guard and measurement are now unit-tested (WR-04 fixed, 10/10 re-run by me)"
  - name: "G-03-14 re-check: singular copy at a count of one (and the payout line)"
    requirement: "UI-01"
    test: "Leave exactly one enemy at night and read the banner; on a day whose night has one enemy read the preview; after a dawn watch the '+N gold' line under the gold counter"
    expected: "'Night N of 8 - 1 enemy left' and 'Night N: 1 enemy from 1 direction' (and plural for any other count); the payout line goes away by the time the day is under way and does not sit under the gold counter at night (UI-REVIEW saw it in fast-forwarded night captures; UAT p14 saw it expire within 1 s in real time)"
    why_human: "The copy is test-pinned and I viewed the banner shot in the second report; whether the payout line behaves in real play, and whether it matters, is the owner's call (UAT test 14 re-check)"
  - name: "G-03-14b re-check: the plated start-night prompt leads the day's bottom centre"
    requirement: "UI-01"
    test: "On a day with a squad selected (cyan slot border) look at the bottom-centre stack: hint row, squad slots, the plated 'Hold N to start Night N' prompt with its fill bar, and the preview line below it"
    expected: "The start-night prompt reads as the day's focal point beside the selected slot (it now has a #14141A plate at y 624..690 below the strip, preview unplated below it); the five-layer column does not feel cluttered. UI-REVIEW still sees the cyan 4 px border as the most saturated element in the column and scores Visuals 3/4"
    why_human: "Hierarchy and clutter are a visual judgement; the geometry is test-pinned (test_start_night_plate 6/6 re-run by me after the IN-09 edit) and the clear-centre check passed on 33 of 33 shots, but whether the prompt leads is the owner's (UAT test 14 re-check, UI-REVIEW fix 3)"
  - name: "E6: longest toast inside x 384..896"
    requirement: "UI-01"
    test: "Select a squad, ride to the edge of the ground and right-click off the map to raise the Can't go there toast; then select a squad, press Shift + H, and press Shift + F (or Shift + right-click) to raise the Nothing can be queued after Hold, Follow or Patrol toast"
    expected: "The owner accepts the two one-line toasts (Can't go there: 526 px, x 377..903; Nothing can be queued: 540 px, x about 370..910, both entirely below the clear centre at y 504..536), or has the copy shortened, or amends the UI-SPEC bound to the real longest line. The 540 px figure is new in this report: the fix pass added the toast and no record or test measured it"
    why_human: "A 7 to 14 px per side miss of a literal band that never touches the protected rectangle is a spec-versus-taste call (03-12 D4, .planning/WINDOWS.md, D-28: decided after the owner plays the fixed build; UAT test 22 pending)"
  - name: "Gamepad on a physical pad"
    requirement: "INPT-02"
    test: "Play one full night on a real pad: ride, sprint (RB), build (A), start night (Y), slam (X), D-pad verbs, hold RT for the queue (RT + D-pad queues the verb; RT + a cursor point verb behind a closed queue now shows the refusal toast), LB layer for move / attack-move / patrol with the right-stick cursor (900 px/s), R3 select all, LB+R3 select type, Start group mode, B to cancel, D-pad right to cycle"
    expected: "Every in-run action is reachable on the pad with nothing needing a pointer; cursor speed, button feel, trigger edges and the chord layout feel right"
    why_human: "No gamepad is connected to this machine, so every pad event in every test, probe and screenshot was synthetic; the pad layout was chosen by Claude, not the owner (UAT test 9 blocked on physical-device; 03-09 D6, assumption 8)"
  - name: "Owner Phase 3 gate: two or three full runs on both devices, then sign off or name fixes"
    requirement: "UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, KING-04, KING-05, INPT-01, INPT-02, UI-01"
    test: "Make sure the build is the current tree (re-run `bash tools/export.sh`, or launch the editor binary; the exe on disk is dated 2026-10-13T21:51Z, after the fix pass, but its source commit is unconfirmed and 03-PLAYTEST-GATE.md still says it is stale); play two or three full 8-night runs with an army, once on keyboard and mouse and once on a gamepad, switching device at least once per run, following 03-PLAYTEST-GATE.md"
    expected: "A recorded decision through /gsd-verify-work: sign off (squads guard and commit, selection and commands feel right on both devices, slam and regeneration suit the game, the HUD reads at night with the centre clear, the Round 2 nights are tense) or a list of fixes and any of assumptions 1 to 15 to change. No Phase 4 work starts before it"
    why_human: "The feel clauses of the success criteria (fun, tension, readability, commands that feel right) and the delegated playtest gate (D-08, Phase 2 D-18) are the owner decision; bots, CI, 1427 green tests, probes and screenshot reviews are not the sign-off (UAT test 15)"
  - name: "Refused-queue and patrol-full toasts, and the mixed-selection rule (review-fix pass 1: WR-03, IN-06)"
    requirement: "UNIT-10, INPT-01, INPT-02, UI-01"
    test: "Select a squad, Shift + right-click a point, press Shift + H, then press Shift + F (or Shift + right-click again): read the toast. Arm patrol (P) and right-click eight points: read the toast on the eighth. Select two squads, give both a move, queue a hold on only one of them, then Shift + right-click a point: watch which squads take it"
    expected: "'Nothing can be queued after Hold, Follow or Patrol' shows once when every selected squad already ends in a hold, follow or patrol (1.5 s, one line, in the hint-strip slot) and reads at the moment you needed it; 'A patrol takes up to 7 points' shows on the eighth patrol click and adds no point; in a mixed selection the open squad queues the new order and the closed squad is skipped with no toast, which should read as sensible rather than as a missed command (width of both lines is decided in item 7)"
    why_human: "Copy, timing and the refusal paths are pinned by tests (test_squad_queue 17/17, test_command_keys 17/17, test_mouse_commands 16/16, test_pad_cursor 10/10 re-run by me) and the 03-VALIDATION manual-only table lists this check; whether the line reads in the moment, whether the silent skip of a closed squad in a mixed selection is the right call, and whether the 540 px line is acceptable are judgements (new UAT test 25)"
---

# Phase 3: King Combat & Troops Verification Report (third report, after review-fix pass 1)

**Phase Goal:** The king leads an army. The player builds a Barracks and an Archery Range whose squads fight on their own, commands them RTS-style with hotkeys, mouse selection and control groups, and fires the weapon's active ability. All of it is fully playable on keyboard and mouse or on gamepad with a complete in-run HUD.
**Verified:** 2026-10-14T06:30:48Z
**Status:** human_needed
**Re-verification:** Yes. This is the third report. It supersedes the second report of 2026-10-13T20:11:11Z (HEAD e925538) and checks the 13 commits of review-fix pass 1 (56b2828 to e01971e) against HEAD a67956e. `git diff ca8086a HEAD -- . ':!.planning/'` is empty, so the orchestrator's full run at ca8086a is the full-suite evidence for the current code.

## Verdict

The engineering part of the goal is still achieved, and the fix pass is clean. I found no FAILED roadmap truth, no FAILED gap truth, no missing or stubbed artifact, no unwired link, no debt marker and no regression of the Phase 1 or Phase 2 suites. All 13 review findings the pass claimed are fixed in code, each with a test (three new scripts and new cases in five others); I read the full source diff `4da6799..HEAD` of the simulation, input and toast code, re-ran thirteen test scripts, both golden replays and lint in my own process, and measured the toast widths in the real HUD scene. The status stays `human_needed`, not `passed`: the owner has not re-checked the six fixed items by eye, decided E6, played on a physical pad or run the gate, and the fix pass added something new to judge (two toasts and a mixed-selection rule). Ten items are in the frontmatter, in the same order as the second report's nine with one new last entry, so the orchestrator can map them onto UAT tests 16 to 25. Nothing here is the owner sign-off.

The one new fact the fix pass produced is a warning, not a gap. WR-03's `Toast.QUEUE_CLOSED` ("Nothing can be queued after Hold, Follow or Patrol") is 540 px wide in the real HUD, wider than the 526 px "Can't go there" line that every record (UI-SPEC, WINDOWS.md ledger, UI review, playtest gate, UAT test 12) calls the longest toast. It stays below the protected rectangle, so the clear-centre rule is not broken, but it passes the literal x 384..896 band by 14 px per side and no test or screenshot covers it. The E6 owner decision now covers two toasts, and the documents that name 526 px as the longest are stale on that point.

Open code-review findings: IN-10 and IN-11, both info, both from the fourth review (03-REVIEW.md: 0 critical, 0 warning, 2 info, confirming all 13 fixes correct). 03-REVIEW-DISPOSITION.md records 14 rows fixed and 2 open. Neither fails a truth. I describe them as open, not addressed. CR-01, the one finding the second report said must not ship, is fixed and T-03-04 and T-03-05 are closed (`threats_open: 0`).

ROADMAP marks Phase 3 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form (as in Phase 2), so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD a67956e (Godot 4.7.2, Windows). `git status` was clean before and after (the replays write nothing); I modified no source, data or test file, killed no process and committed nothing. The only artefact outside this report is a scratch measuring script in the session scratchpad, outside the repository.

| Check | Command | Result |
|---|---|---|
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (unchanged by the fix pass, including the merged separation routine) |
| Army replay vs golden | `bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json` | `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (unchanged) |
| CR-01 bounded fill | `-gselect=test_squad_bad_unit_health` | 3/3, 7 asserts (max_health 0 and -5, dawn restore bounded to one seat) |
| WR-04 contrast probe | `-gselect=test_contrast_probe` | 10/10, 67 asserts |
| IN-03 shared separation | `-gselect=test_separation` | 7/7, 40 asserts |
| WR-03 gate and mixed selection | `-gselect=test_squad_queue` | 17/17, 80 asserts |
| WR-03 / IN-08 keyboard path | `-gselect=test_command_keys` | 17/17, 171 asserts |
| WR-03 / IN-06 mouse path | `-gselect=test_mouse_commands` | 16/16, 171 asserts |
| WR-03 pad cursor path | `-gselect=test_pad_cursor` | 10/10, 108 asserts |
| G-03-8 pad RT queue | `-gselect=test_pad_commands` | 18/18, 200 asserts |
| G-03-4 king bar follows heals | `-gselect=test_king_knockout` | 5/5, 52 asserts |
| G-03-14b plate after IN-09 | `-gselect=test_start_night_plate` | 6/6, 44 asserts |
| IN-07 balance report | `-gselect=test_balance_value_metric` | 6/6, 48 asserts |
| Lint and format | `bash tools/lint.sh` | `269 files would be left unchanged`, `Success: no problems found` |
| Plan artifacts | `gsd-tools query verify.artifacts` on all 19 plans | 81/81 pass |
| Plan key links | `gsd-tools query verify.key-links` on all 19 plans | 51/52 (the 03-13 regex drift described in the warnings; wiring intact by reading) |
| Debt markers | grep TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER over every non-planning file changed since 4da6799 (the .uid files hold no code) | none |
| Scope of the fix pass | `git diff --name-only 4da6799 HEAD -- . ':!.planning/'` | 32 files; no change to project.godot, data/, tests/golden or tests/fixtures; hud.tscn gained a comment only |
| Toast widths (new) | headless scratch script: instantiate res://ui/hud/hud.tscn, set the Toast label text, read its minimum width | CANT_GO_THERE 526, QUEUE_CLOSED 540, PATROL_FULL 299, SELECT_FIRST 201 |

Taken from reports without re-running: the full suite at ca8086a (153 scripts, 1427/1427 tests, 15885 asserts, 535 s, which I confirmed from the tail of `build/test-results/postmerge_test_stdout.log`), the orchestrator's mutation probes of 2026-10-14 (each behaviour-changing fix switched off, the named suite failed: CR-01 3 of 3 twice, WR-03 1 of 17 and 1 of 17, IN-02 1 of 9, IN-03 5 of 7, IN-06 1 of 16, IN-07 1 of 6, IN-08 10 of 17, IN-09 1 of 6, WR-04 3 of 10; IN-01, IN-04 and IN-05 change no behaviour and were not probed), the WR-02 shell check (one real shot and a synthetic error line, per 03-REVIEW-FIX.md, not re-run by me), CI run 38473757849 on abdf730, and the 33 screenshots from the second report (no pixel changed in the fix pass except the two new toasts, which are not in any capture). I did not run the full suite, the game window, the playtest bots or `tools/screenshot.sh`.

Regression gate: all 29 Phase 1 and Phase 2 test script names that appear in 01-VERIFICATION.md and 02-VERIFICATION.md and exist on disk appear in the ca8086a full run log (checked by name against `build/test-results/postmerge_test_stdout.log`); that run passed 1427 of 1427. Both earlier reports are `status: passed` in their own frontmatter and nothing in the fix pass touches data or goldens.

## Goal Achievement

### ROADMAP success criteria (the contract), re-checked at HEAD

| # | Success criterion | Status | Evidence (delta since the second report) |
|---|---|---|---|
| 1 | Barracks and Archery Range; units guard and commit; night trickle back; full restore at dawn | VERIFIED in code and tests; feel is a human item | The fix pass touched the spawn path only to bound it: `SquadSystem._fill` (line 148) and `restore_for_dawn` (line 462) loop `range(maxi(cap - living, 0))` and `UnitSystem.spawn` / `heal_to_full` floor health with `maxi(max_health, 1)`; for the shipped footman (10) and archer (6) nothing changes, which the byte-identical army golden shows (1353 ticks, same digest). `Separation.displacements` replaced two copies of the push-apart pass with the same operations in the same order; the squad and enemy goldens and test_separation pin it. test_squad_guard, test_squad_respawn, test_squad_lifecycle and test_squad_stance_persistence are green in the ca8086a run. CR-01 is closed |
| 2 | Select squads (click, box, Ctrl; pad cycling); control groups; hold, follow, rally, move, attack-move, patrol, Shift queue; stances persist | VERIFIED in code and tests; feel is a human item | The order controllers (`CommandKeyController._give`, `SelectionController._order`, `PadCursorController._confirm`) now read the result of `submit` and toast a closed queue. `CommandProcessor._every_queue_is_closed` refuses a queued order only when every ordered squad ends in a terminal order (and an empty id list returns false); `SquadSystem.apply_order` skips a closed squad on the same condition, so the gate and the system agree (test_squad_queue 17/17 pins mixed-selection skip and all-closed refusal). The eighth patrol click toasts and still adds no point. G-03-8 (the queue gesture on F, H, R) still passes after the IN-08 constant rename (test_command_keys 17/17, test_pad_commands 18/18, test_pad_cursor 10/10) |
| 3 | Active ability with visible cooldown; king health regenerates after a short time | VERIFIED in code and tests | Unchanged by the fix pass. king.gd line 54 connects `king_healed`, handler at lines 101-103 (read in the second report; the file is not in the fix pass's diff); test_king_knockout 5/5 re-run |
| 4 | Every in-run action on keyboard and mouse and on gamepad; switch devices any time; prompts follow the device | VERIFIED in code and tests; the pad is untested on hardware | The pad cursor confirm path gained the same refusal toast as the mouse and keys, so a pad point verb behind a closed queue is no longer silent (test_pad_cursor 10/10). test_input_capabilities, test_device_model, test_prompt_switch and test_command_hints are in the ca8086a run. UAT test 9 stays blocked on a physical pad |
| 5 | HUD shows gold, night N of total, king health, ability cooldown and unit status without cluttering the play area | VERIFIED in code, tests and the runner check; E6 and by-eye hierarchy are human items | `ui/hud/hud.tscn` changed by one `;` comment (IN-09) and `ui/hud/toast.gd` gained two constants and `refusal_text`; the two new toasts use the existing slot (y 504..536), so the clear centre x 384..896, y 96..500 is untouched by construction. The new `QUEUE_CLOSED` line is 540 px wide, wider than the old longest toast: see the first warning. test_start_night_plate 6/6 re-run |

### UAT round-1 gaps (the second contract)

| Gap | Truth | Status | Evidence |
|---|---|---|---|
| G-03-4 (WR-01) | The floating bar over the king and the widget agree after a heal | VERIFIED | king.gd is not in the fix pass diff; test_king_knockout 5/5 re-run |
| G-03-8 | Shift-queue several moves then a hold: the hold runs after the walks (D-09) | VERIFIED | `_give` submits `SquadOrderIntent.new(ids, verb, no_points, Input.is_action_pressed(SelectionController.QUEUE_ACTION))` (command_key_controller.gd, read at HEAD); test_command_keys 17/17 and test_pad_commands 18/18 re-run |
| G-03-13 | The knocked-out '0 / 50' is readable | VERIFIED (by measurement and one viewed capture in the second report) | king_widget.gd is not in the fix pass diff; the probe's guard and measurement are now unit-tested (WR-04, test_contrast_probe 10/10), which closes the weakness the second report flagged |
| G-03-14 | Singular copy at a count of one | VERIFIED | hud.gd is not in the fix pass diff; test_spawn_telegraph 22/22 in the ca8086a run |
| G-03-14b | The start-night prompt reads as the day focal point beside a cyan selected slot | VERIFIED in code and geometry; the hierarchy is a human item | test_start_night_plate 6/6 re-run after the test now reads `KingWidget.PLATE_COLOR` |
| G-03-11 | Nights 5 to 8 serve the four owner goals at once | VERIFIED as pinned measurements; feel is a human item | No data file moved in the fix pass; test_balance_acceptance 12/12, test_night_data_contract and test_military_data_contract green in the ca8086a run; both goldens byte-identical |

### Review-fix pass 1 (the third contract of this re-verification)

| Finding | Claim | Status | Evidence |
|---|---|---|---|
| CR-01 | Spawn loops bounded, stored health floored at 1 | FIXED, verified | Read squad_system.gd 148 and 462 and unit_system.gd 29 and 126 at HEAD; test_squad_bad_unit_health 3/3 re-run (the unfixed code hung, per the fix report; the orchestrator's mutation probe failed 3 of 3 with the clamp removed and 3 of 3 with the loop over-spawning) |
| WR-02 | screenshot.sh fails on script errors | FIXED, not re-run | The fix report and the fourth review read the `PIPESTATUS[0]` logic; I did not run a real shot (no game window); the shell filter was shown to fire on a synthetic line by the orchestrator |
| WR-03 | A refused queued order is announced; a mixed selection goes through | FIXED, verified | Diff read; five test scripts re-run green; `Toast.refusal_text` is called from all three order controllers (grep: command_key_controller.gd 207, pad_cursor_controller.gd 114, selection_controller.gd 290) and the only other `SquadOrderIntent` builder is the playtest bot |
| WR-04 | The contrast probe's guard and measurement are tested | FIXED, verified, with one mislabelled case (IN-10) | test_contrast_probe 10/10 re-run; mutation probe failed 3 of 10 with the fill key raised |
| IN-01 | Dead patrol budget assignment removed | FIXED | Diff read (a comment replaces the line); goldens identical |
| IN-02 | One ground-limit rule | FIXED | `MapConfig.ground_limit_cm` read; `CommandProcessor._ground_limit_cm` and `GroundPick.in_bounds` both call it |
| IN-03 | One push-apart routine | FIXED | `Separation.displacements` read; callers build the arrays in ascending id order; goldens identical |
| IN-04 | Test-only accessors marked | FIXED | Doc comments read |
| IN-05 | Unused ext_resources removed | FIXED | Per the fourth review; test_building_models 8/8 in the ca8086a run |
| IN-06 | The eighth patrol click says so | FIXED, verified | selection_controller.gd 260-267 read; test_mouse_commands 16/16 re-run |
| IN-07 | `_mean` tolerant | FIXED, verified | test_balance_value_metric 6/6 re-run |
| IN-08 | One queue-action constant | FIXED | `SelectionController.QUEUE_ACTION` read by the other two controllers (grep); pinned against the Input Map in test_command_keys |
| IN-09 | Plate colour test follows the widget | FIXED | test_start_night_plate 6/6 re-run |

### Plan must_haves

188 plan truths and 25 prohibitions are declared. All 81 declared artifacts pass gsd-tools; key links are 51/52 by the tool and 52/52 by reading (see the warning on 03-13). The fix pass is outside the plans, so its truths are the thirteen findings above rather than frontmatter truths; none of the 188 plan truths concerns a file the pass changed in a way that alters behaviour for shipped data (goldens byte-identical).

New-decision check against 03-CONTEXT.md: D-26 (squad value bar 0.8) honored (`SQUAD_VALUE_BAR 0.8` in test_balance_acceptance, no override exists, no data moved); D-27 (all four goals, nights 1 to 4 untouched) honored (no data file moved); D-28 honored (`Toast.CANT_GO_THERE` still untouched, so E6 stays pending; no auto-join of control groups; tests 9 and 15 left to the owner). The fix pass respects the rest of the locked decisions: D-09 (queue ends at a terminal order) is unchanged in the simulation; only the mixed-selection refusal changed from whole-order to per-squad, which is recorded in the UI-SPEC copywriting contract and is the owner's to confirm (item 10).

Prohibitions (all judgment-tier or backstop; my reading is NON-AUTHORITATIVE and flagged `unverified-prohibition - human review recommended`, none is absorbed into the pass): see the frontmatter note. The 25 are plan-scoped and read against git as in the second report; the fix pass's simulation edits are not covered by any plan prohibition and are guarded instead by the byte-identical goldens.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| command_key_controller.gd `_give` | command_processor.gd `submit` | `SquadOrderIntent.new(...)` with the queue flag, then `Toast.refusal_text(reason)` | WIRED | The tool misses the 03-13 literal because the call spans three lines now; read at HEAD and pinned by test_command_keys |
| selection_controller.gd `_order` / `_right_click` | `submit` and `Toast.PATROL_FULL` | result of `submit` to `refusal_text`; eighth patrol click to `feedback.emit` | WIRED | grep and diff |
| pad_cursor_controller.gd `_confirm` | `submit` | result to `refusal_text` | WIRED | grep and diff |
| `Toast.bind_run` | the three controllers' `feedback` signal | `find_children` + `connect` | WIRED | unchanged; test_mouse_commands reads `current_text()` after a real right-click |
| `CommandProcessor._every_queue_is_closed` | `SquadSystem.apply_order` | same terminal-order test, gate refuses all-closed only, system skips closed squads | WIRED | test_squad_queue pins both halves |
| `UnitSystem.separate` and `EnemySystem._separate` | `Separation.displacements` | packed arrays in ascending id order | WIRED | goldens identical |
| `MapConfig.ground_limit_cm` | `CommandProcessor._ground_limit_cm` and `GroundPick.in_bounds` | one static rule | WIRED | test_ground_pick pins agreement at the edge |

### Requirements Coverage

All 11 phase IDs appear in at least one plan `requirements:` field and REQUIREMENTS.md maps exactly these 11 to Phase 3 (11 lines with `| Phase 3 |`, each ticked Complete); I extracted the IDs from the plan frontmatter and they are the same 11. No ID is orphaned or missing from a plan. INPT-03 stays open by design (Phase 13, not a Phase 3 ID).

| Requirement | Plans (fix pass touches in bold) | Status | Evidence |
|---|---|---|---|
| UNIT-04 | 03-01, 03-02, 03-11, 03-12, 03-16, 03-17, 03-18; **CR-01, IN-03** | SATISFIED in code and tests; feel at the gate | Criterion 1; goldens identical |
| UNIT-05 | 03-06, 03-12, 03-13 | SATISFIED | Hold on H and pad D-pad down; Shift+H queues a hold behind walks |
| UNIT-06 | 03-06, 03-12 | SATISFIED | Follow on F / D-pad up; select all and select type |
| UNIT-07 | 03-02, 03-05, 03-11, 03-12, 03-16, 03-17, 03-18; **CR-01, IN-05** | SATISFIED | Trickle and dawn restore green; dawn restore now bounded |
| UNIT-09 | 03-06, 03-08, 03-09, 03-12 | SATISFIED | Unchanged; test_selection_* and test_control_group* green in the full run |
| UNIT-10 | 03-07, 03-08, 03-09, 03-11, 03-12, 03-13; **WR-03, IN-01, IN-02, IN-06, IN-08** | SATISFIED | Criterion 2 |
| KING-04 | 03-04, 03-10, 03-11, 03-12, 03-17, 03-18 | SATISFIED | Slam values unchanged |
| KING-05 | 03-04, 03-12, 03-14, 03-17, 03-18 | SATISFIED | Criterion 3 |
| INPT-01 | 03-06 to 03-09, 03-12, 03-13; **WR-03, IN-08** | SATISFIED in code | Criteria 2 and 4 |
| INPT-02 | 03-09, 03-10, 03-12, 03-13; **WR-03, IN-08** | SATISFIED in code; synthetic pad events only | Criterion 4; UAT test 9 blocked |
| UI-01 | 03-03, 03-04, 03-05, 03-10, 03-12, 03-14, 03-15, 03-19; **WR-03, IN-06, IN-09** | SATISFIED in code, tests and the runner check | Criterion 5; E6 now covers two toasts |

REQUIREMENTS.md ticks reflect implementation, not the owner gate.

### Data-Flow Trace (Level 4)

FLOWING for everything the fix pass touched. `CommandProcessor.submit` returns a reason `StringName` -> `Toast.refusal_text` -> `feedback(text, true)` -> `Toast._on_feedback` -> `show_error` -> the label in the hint slot (the same chain the Can't go there toast uses; test_mouse_commands reads the text after a real right-click). `SquadOrder.MAX_PATROL_POINTS - 1` -> `Toast.PATROL_FULL % limit`. `UnitDef.max_health` -> `maxi(..., 1)` -> record health -> `_living_count`. No hardcoded empty value reaches the UI.

### Behavioral Spot-Checks and Replays

See "What I ran". Behavior-dependent truths of the fix pass (a fill loop that ends for a born-dead unit; a mixed selection queues for the open squads and skips the closed; an all-closed selection is refused once with the reason; the eighth patrol click toasts and adds no point; the shared separation pass equals the two copies) each have a passing named test I re-ran, and the orchestrator's mutation probes show each fails when its fix is removed. `behavior_unverified: 0`. What is not behaviorally verified is everything that needs a human or hardware, plus the two new toasts as rendered on screen (no capture exists): see Human Verification.

### Probe Execution

No `probe-*.sh` files are declared by the phase plans or exist under `scripts/`: SKIPPED. (`tools/contrast_probe.sh` is a measurement tool, now unit-tested, not a declared verification probe.)

### Anti-Patterns Found

None blocking. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in the 32 non-planning files changed by the fix pass. The one real defect class the second report named (CR-01) is closed. The two open info findings are test-quality notes (IN-10 mislabelled path case, IN-11 coupling to shipped radii and a private call), not defects in shipped behaviour.

## Code-review findings (2 OPEN, 14 FIXED)

| ID | Severity (review) | State | My weighing |
|---|---|---|---|
| IN-10 | info | OPEN (fourth review) | INFO. A test case is mislabelled; the probe's behaviour is correct and the intent is covered by literal cases |
| IN-11 | info | OPEN (fourth review) | INFO. A characterization test depends on shipped radii and a private method name |
| CR-01 | critical | FIXED (56b2828), re-verified by the fourth review and by me | Closed; T-03-04 and T-03-05 closed |
| WR-01 | warning | FIXED by 03-14 (ee21f6f) | Closed (G-03-4) |
| WR-02 | warning | FIXED (8d28079) | Closed; not re-run in a window |
| WR-03 | warning | FIXED (8ad0158) | Closed; adds the E6-widening toast and the mixed-selection rule to the human list |
| WR-04 | warning | FIXED (2e863c8) | Closed |
| IN-01 to IN-09 | info | FIXED (67122e9 to e01971e) | Closed |

03-REVIEW-DISPOSITION.md on disk: 14 fixed, 2 open, 16 total.

## Human Verification Required

The structured list is in the frontmatter: ten entries. The first nine keep the names and order of the second report (the by-eye re-checks of G-03-4, G-03-8, G-03-11, G-03-13, G-03-14 and G-03-14b, the E6 toast decision, the physical pad and the gate), with the text adjusted where the fix pass changed what the owner judges: item 2 no longer says the refusal behind a terminal order is silent, item 4 no longer notes that the probe is untested, item 7 (E6) now covers two toasts and the 540 px figure, and items 8 and 9 mention the pad refusal toast and the unconfirmed export commit. Item 10 is new and last (it becomes UAT test 25): the refused-queue toast, the patrol-full toast and the mixed-selection rule. I did not repeat the seven items the owner passed in UAT round 1 (tests 1, 2, 3, 5, 6, 7, 10): the fix pass changed no code behind them for shipped data (goldens identical), and the only test-6/7 path it touched, the order controllers, is covered by the re-run suites. The decisive entry remains the owner gate in 03-PLAYTEST-GATE.md.

## Gaps Summary

No gaps and no blockers. All five roadmap success criteria are implemented, wired and tested at HEAD; all six UAT round-1 gaps are closed with a test that fails when the fix is removed; all 13 findings of review-fix pass 1 are fixed and re-verified; the replays are byte-identical to their goldens, lint is clean and the 1427-test suite was green on the code that is still current (no source file differs between ca8086a and HEAD). The status is `human_needed` because the owner has not yet re-checked the fixed items, decided E6 (now two toasts, the longer one a fresh 540 px), played on a pad or run the gate, and because two info findings (IN-10, IN-11) remain open. The Round 2 retune still carries its cost (towers_first 0 of 10, houses_first 4 of 10, a relaxed Phase 2 pin) and the owner should say whether it is acceptable. Do not treat the green tests, the replay digests, the balance table, the contrast probe, the screenshot reads or this report as the sign-off, and do not start Phase 4 before the owner decides. Suggested order: confirm or redo the export, then the owner re-checks and the gate (UAT tests 16 to 25); independently, an optional review-fix pass 2 for IN-10 and IN-11, and a one-line copy or bound decision for the toast width that also updates UI-SPEC, WINDOWS.md and the UI review. If any file in the covered list changes, re-run `verification.status` to refresh the fingerprint.

**Canonicalization note (2026-10-15).** `status` was set from `human_needed` to `passed` by /gsd-verify-work 3 after the UAT session closed (25 of 25 tests passed, 0 issues; the ten human items of this report are UAT tests 16 to 25; the five round-1 issue rows and the two blocked pad rows were superseded or passed with the owner's approval). No source, data or test file changed after this report was written (`git diff 6069f00 HEAD -- . ':!.planning/'` is empty); the covered documents that changed are 03-UAT.md (results), 03-CONTEXT.md (D-29), 03-UI-SPEC.md (E6 bound) and .planning/WINDOWS.md, so `covered_digest` was recomputed over the same 314 paths.

**Coverage fingerprint note.** `covered_files` is the orchestrator's 315-path list minus 03-VERIFICATION.md itself (a report cannot cover its own bytes), 314 paths. `03-UAT.md` and the other phase documents stay covered, so appending the tenth human item to 03-UAT.md changes the digest: after that edit, recompute it with `verification.fingerprint` over the frontmatter list and replace `covered_digest`, or `verification.status` will read `stale`.

---

_Verified: 2026-10-14T06:30:48Z_
_Verifier: Claude (gsd-verifier)_
