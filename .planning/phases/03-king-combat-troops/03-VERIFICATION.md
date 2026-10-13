---
phase: 03-king-combat-troops
verified: 2026-10-13T20:11:11Z
status: human_needed
score: 5/5 roadmap success criteria verified in code and tests (0 failed); 6/6 UAT round-1 gap truths closed in code, tests and probes (0 failed); 11/11 requirement IDs have implementation evidence; owner feel gate (UAT test 15), the physical pad (test 9) and the E6 decision (test 12) not yet done
must_haves:
  roadmap_truths: 5
  roadmap_truths_verified: 5
  roadmap_truths_failed: 0
  gap_truths: 6
  gap_truths_closed: 6
  gap_truths_failed: 0
  plan_truths_declared: 188
  plan_artifacts_checked: "81/81 pass (gsd-tools verify.artifacts over all 19 plans)"
  plan_key_links_checked: "52/52 wired (gsd-tools verify.key-links over all 19 plans)"
  prohibitions_declared: 25
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass. The 11 new ones (plans 03-13 to 03-19) were read against git: no file under simulation/, project.godot, tests/golden or tests/fixtures changed since 90f54c6, and the only data files moved are tower.tres and prototype_map.tres"
  requirement_ids: 11
  requirement_ids_satisfied: 11
  requirement_ids_orphaned: 0
re_verification:
  previous_status: human_needed
  previous_score: "5/5 roadmap success criteria verified in code and tests; 11/11 requirement IDs; 16 human items (the report of 2026-10-12T09:16:48Z at HEAD 008a9b0)"
  report_number: "second report: re-verification after the UAT round-1 gap closure (plans 03-13 to 03-19, executed 2026-10-13); the first report was the initial verification"
  gaps_closed:
    - "G-03-4 / WR-01: the floating bar over the king follows regeneration (king.gd connects king_healed, line 54, handler lines 101-103; test_king_knockout 5/5 re-run by me)"
    - "G-03-8: Shift (pad RT) queues the F, H and R verbs behind queued walks (command_key_controller.gd _give reads QUEUE_ACTION; test_command_keys 14/14 and test_pad_commands 18/18 re-run by me)"
    - "G-03-13: the knocked-out '0 / 50' stays opaque on its own outline (king_widget.gd _apply_knocked_out dims only the bar, plate, icon and glyph; test_king_widget 15/15 re-run; contrast probe re-run by me: CONTRAST_OK ratio=5.88 on screenshots/hud_king_down.png)"
    - "G-03-14: singular copy at a count of one (Hud.enemy_count_text; test_spawn_telegraph 22/22 re-run; hud_king_down.png read by me: 'Night 7 of 8 - 1 enemy left')"
    - "G-03-14b: a plate behind the start-night prompt (StartNightPlate in hud.tscn; test_start_night_plate 6/6 re-run; hud_day_squads.png read by me: the plated prompt sits below the slots)"
    - "G-03-11: Round 2 retune, balanced 8 of 10, army_balanced 8 of 10, squad_value_ratio 0.915 (bar 0.8, D-26), night 8 at 40 above night 7 at 39 (tower.tres tier 1 attack_interval 0.8 to 0.9, prototype_map.tres night 8 north grunts 10 to 11; test_balance_acceptance 12/12, test_night_data_contract 16/16, test_military_data_contract 7/7, test_balance_value_metric 5/5 re-run by me)"
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
  - tests/unit/test_shot_list.gd
  - tests/unit/test_shot_protected_centre.gd
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_squad_archers.gd
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
  - ui/hud/dawn_payout_vfx.gd
covered_digest: "v2:sha256:dcff2126dbe66b173faed4b8e391d2cf2d8b2d8783131986d5ddeee2e863f2a3"
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
  - id: "CR-01 (03-REVIEW-DISPOSITION, OPEN, critical)"
    where: "simulation/squads/squad_system.gd lines 147 (_fill) and 457 (restore_for_dawn), simulation/squads/unit_system.gd line 29 (record.health = def.max_health, unclamped), simulation/run/run_context.gd (push_error only)"
    issue: "Re-checked at HEAD e925538: the two `while _living_count(squad) < squad.cap` loops are unchanged and spawn still stores the health unclamped. A UnitDef with max_health <= 0 (reported by MapConfig validation but not refused by RunContext) spawns born-dead units and the loops never end. The gap round did not touch it (03-13 SUMMARY says so; no file under simulation/ changed since 90f54c6). The shipped footman (10) and archer (6) cannot trigger it and Round 2 changed no unit health (T-03-27), so no roadmap truth fails. 03-SECURITY.md still lists T-03-04 and T-03-05 as open (medium, below the high block threshold)."
    decision_requested: "Fix in the review-fix pass (bound both loops by the missing seats, floor the stored health at 1, add a test that builds a Barracks over a max_health = 0 footman and expects the step to return). It remains the one finding that must not ship. Not a gap."
  - id: "WR-02 (OPEN)"
    where: "tools/screenshot.sh lines 97-116"
    issue: "The wrapper still passes a shot on exit 0 plus a non-blank PNG and does not scan the Godot output for SCRIPT ERROR or Parse Error, unlike replay.sh and playtest.sh. Tooling only; the new tools/contrast_probe.sh does have the script-error guard."
    decision_requested: "Fix in the review-fix pass or accept."
  - id: "WR-03 (OPEN, widened by 03-13)"
    where: "input/selection_controller.gd _order, input/pad_cursor_controller.gd _confirm, input/command_key_controller.gd _give, simulation/commands/command_processor.gd"
    issue: "A repo-wide search of input/, presentation/ and ui/ still finds no consumer of command_rejected. 03-REVIEW notes that 03-13 gives the player a new way to reach it: Shift+F, Shift+H or Shift+R behind a queue that already ends in a hold, follow or patrol is refused with QUEUE_CLOSED and nothing says so."
    decision_requested: "Fix in the review-fix pass (a toast for QUEUE_CLOSED, a per-squad skip for a mixed selection; add the copy to UI-SPEC) or accept and tell the owner at the gate. Not a gap."
  - id: "WR-04 (OPEN, new in the 2026-10-13 review)"
    where: "tools/screenshot/contrast_probe.gd lines 57-90 and 141-215 (parse_args, _safe_image, _parse_rect, measure, luminance, contrast_ratio)"
    issue: "The probe is the sole real-window evidence for the G-03-13 legibility claim and its path guard decides which file the script opens, yet no test under tests/ exercises either. I re-ran the probe on the shipped capture (CONTRAST_OK 5.88) but that is one sample, not a regression guard."
    decision_requested: "Add tests/unit/test_contrast_probe.gd in the review-fix pass (red text on black passes, on grey fails, no red pixels gives the error; `..`, a sibling prefix, an absolute path outside the project and a non-png name are rejected)."
  - id: "IN-01 to IN-06 and IN-07 to IN-09 (all OPEN)"
    where: "squad_system.gd (dead patrol budget), command_processor.gd and ground_pick.gd (ground bound twice), unit_system.gd and enemy_system.gd (35-line separate pass duplicated), test-only accessors, three unused ext_resource lines, the eighth patrol click dropped silently; balance_report.gd _mean strict versus summary tolerant; the queue action name literal in two controllers and a constant in a third; the #14141A 0.78 panel colour written in three places"
    issue: "Info only. 03-REVIEW-DISPOSITION.md records open: 13 of 14 (CR-01, WR-02, WR-03, WR-04, IN-01 to IN-09); WR-01 is the only fixed one. I do not describe any open finding as addressed."
    decision_requested: "Fix or defer in the review-fix pass."
  - id: "Round 2 balance: what it cost (judgment call, flagged)"
    where: "data/buildings/tower.tres tier 1 attack_interval 0.9, tests/integration/test_balance_acceptance.gd, 03-BALANCE-REPORT.md Round 2 'What the numbers say'"
    issue: "All four owner goals are met on the measured data (balanced 8 of 10, army_balanced 8 of 10, ratio 0.915 against the 0.8 bar, night 8 at 40 against 39) and I reproduced the pinned results (test_balance_acceptance 12/12 in 201 s). The report itself says what it cost: (1) towers_first wins 0 of 10 (was 3 of 10) and houses_first 4 of 10 (was 9). The Phase 2 acceptance pin 'the owner's tower opening wins at least 2 of 3' (plan 02-16, which said not to loosen it) was re-pinned to 'survives at least 6 nights on every pinned seed'; this was a documented, plan-allowed route (29 candidates searched), but it is a relaxed Phase 2 pin. (2) The ratio rose mainly because the tower denominator fell (tower kills per tower gold 5.93 to 4.70) while squads only moved from 4.04 to 4.31 unit kills per military gold, so the squads were not made stronger, the towers were made weaker. (3) army_balanced loses 17.6 buildings a run and the balanced bot 10.4 (was 5.8). (4) The full_idle digest moved by design (6199 to 6941 ticks, no golden). The smoke and army goldens are byte-identical (re-run by me)."
    decision_requested: "Owner judges at the gate whether a tier 1 tower firing every 0.9 s still feels rewarding, whether the lost tower-route wins matter, and whether squads feel worth their gold."
  - id: "E6 toast width (known, unchanged, human_needed)"
    where: "ui/hud/toast.gd CANT_GO_THERE"
    issue: "Still 526 px wide at x 377..903, 7 px past the UI-SPEC literal x 384..896 band on each side, one line below the protected rectangle (y 504..536). The gap round did not touch it (03-19 SUMMARY, D-28: decided after the owner plays the fixed build). UI-REVIEW lists it as open Fix 2. UAT test 12 is pending."
    decision_requested: "Owner: accept, shorten the copy (UI-REVIEW suggests 'Can't go there. Click visible ground.') or amend the bound."
  - id: "Payout line: two records disagree (informational)"
    where: "ui/hud/dawn_payout_vfx.gd TOTAL_SHOWN_SECONDS = 2.0 (a wall-clock tween), UAT test 14 p14, 03-UI-REVIEW.md Top 3 fix 1"
    issue: "UAT p14 measured the '+N gold' line expiring within 1 s of the day starting in real time and called the night captures a fast-forward artefact; the 2026-10-13 UI review reads the same line under the gold counter in night captures and names the 2 s real-time tween as the cause. The code agrees with both (nothing hides it on a phase change; it is only the 2 s tween). It is Phase 1 and 2 code outside this phase's files and no success criterion depends on it."
    decision_requested: "Owner glance at the re-check of test 14; fix later or in the review-fix pass if it shows in play."
  - id: "Exported Windows build is stale (informational)"
    where: "build/windows/Duskhold.exe (exported 2026-10-12 from c418b6c)"
    issue: "It predates plans 03-13 to 03-19, so it holds none of the fixes or the retune. 03-PLAYTEST-GATE.md says so and tells the owner to run the editor binary or `bash tools/export.sh` first."
    decision_requested: "Re-export (or use the editor binary) before the gate, or the owner would re-test the old build."
  - id: "Shift is both sprint and queue (behaviour note from 03-13)"
    where: "input/command_key_controller.gd _give, project.godot command_queue"
    issue: "Pressing F, H or R while sprinting with Shift held now queues the verb behind the selection's walks instead of replacing them. It is consistent with D-09 and with Shift right-click moves; with nothing queued the verb runs at once, so it only shows when walks are queued."
    decision_requested: "Owner to say at the gate whether this surprises in play."
behavior_unverified_items: []
human_verification:
  - name: "G-03-4 re-check: the floating bar over the king and the bottom-left widget agree after a heal"
    requirement: "KING-05, UI-01"
    test: "Take a hit or two at night (or from an enemy by day), stop being hit, and watch the small bar floating over the king and the health bar bottom-left while the king regenerates; look at the moment he is whole again"
    expected: "Both climb together, one point at a time, to the same number; the floating bar disappears once he is at full health (it used to freeze at the last damaged value while the widget climbed; fixed by plan 03-14, 10 heals measured equal in a real window)"
    why_human: "The tests and the scripted real-window probe show the numbers agree; whether the two readouts read as one in motion, over the real scene, is a by-eye judgement (UAT test 4 re-check)"
  - name: "G-03-8 re-check: Shift-queued hold (and RT on the pad)"
    requirement: "UNIT-10, INPT-01, INPT-02"
    test: "Select a squad, Shift + right-click three points, then press Shift + H; repeat with Shift + F and Shift + R; press plain H after a queued walk; on a pad hold RT and press D-pad down"
    expected: "The squad walks all three points and then holds at the last one (move here, then hold); plain H still stops it at once and holds where it stands; Shift + F and Shift + R queue the follow and the rally the same way; Shift while sprinting now queues a verb, which should not surprise. A hold pressed behind a queue that already ends in a hold, follow or patrol is silently refused (open finding WR-03)"
    why_human: "Real keys and a real window were driven by the executor (03-13 probe lines: orders move, move, move, hold, held at the third point), but the gesture's feel, the hint row's 'Queue' wording and the silent refusal behind a terminal order are the owner's to judge (UAT test 8 re-check)"
  - name: "G-03-11 re-check: Round 2 balance feel (0.9 s first tower, nights 5 to 8 at 25 / 31 / 39 / 40)"
    requirement: "UNIT-04, UNIT-07"
    test: "Play three nights with an army, including nights 5 to 8, and read the Round 2 section of 03-BALANCE-REPORT.md; open with a tower on day 1 and see whether a first tower that fires every 0.9 s (was 0.8 s) still feels like a good opening"
    expected: "Nights feel tense with squads; the owner accepts or rejects the reported trade: the balanced bot wins 8 of 10 and the army bot 8 of 10 (goals met), squads score 0.915 against the 0.8 bar mostly because towers got weaker, towers_first wins 0 of 10 and houses_first 4 of 10, the army bot loses 17.6 buildings a run, night 8 is now 40 against 39"
    why_human: "The bots build instantly and react perfectly and cannot judge tension or whether an opening feels rewarding; the report states the numbers measure the data only (D-08, Phase 2 D-18, UAT test 11 re-check)"
  - name: "G-03-13 re-check: the knocked-out king's '0 / 50'"
    requirement: "UI-01"
    test: "Get the king knocked out at night and read the bottom-left widget (count, the dimmed bar and sword plate, the Slam caption) and the 'Knocked out, back in N s' label"
    expected: "The red 0 / 50 and the Slam caption are crisp and readable, the bar and sword plate are visibly dimmed; the knocked-out state still reads as knocked out (measured 5.88:1 on the real capture, was 1.62:1; I viewed hud_king_down.png and the count is legible)"
    why_human: "A contrast number and one capture approximate legibility; the owner's eyes on a real monitor and a real night decide (UAT test 13 re-check). Note the probe's own guard and measurement rule have no unit test (WR-04)"
  - name: "G-03-14 re-check: singular copy at a count of one (and the payout line)"
    requirement: "UI-01"
    test: "Leave exactly one enemy at night and read the banner; on a day whose night has one enemy read the preview; after a dawn watch the '+N gold' line under the gold counter"
    expected: "'Night N of 8 - 1 enemy left' and 'Night N: 1 enemy from 1 direction' (and plural for any other count); the payout line goes away by the time the day is under way and does not sit under the gold counter at night (UI-REVIEW saw it in fast-forwarded night captures; UAT p14 saw it expire within 1 s in real time)"
    why_human: "The copy is test-pinned and I viewed the banner shot; whether the payout line behaves in real play, and whether it matters, is the owner's call (UAT test 14 re-check)"
  - name: "G-03-14b re-check: the plated start-night prompt leads the day's bottom centre"
    requirement: "UI-01"
    test: "On a day with a squad selected (cyan slot border) look at the bottom-centre stack: hint row, squad slots, the plated 'Hold N to start Night N' prompt with its fill bar, and the preview line below it"
    expected: "The start-night prompt reads as the day's focal point beside the selected slot (it now has a #14141A plate at y 624..690 below the strip, preview unplated below it); the five-layer column does not feel cluttered. UI-REVIEW still sees the cyan 4 px border as the most saturated element in the column and scores Visuals 3/4"
    why_human: "Hierarchy and clutter are a visual judgement; the geometry is test-pinned (test_start_night_plate 6/6) and the clear-centre check passes on 33 of 33 shots, but whether the prompt leads is the owner's (UAT test 14 re-check, UI-REVIEW fix 3)"
  - name: "E6: longest toast inside x 384..896"
    requirement: "UI-01"
    test: "Select a squad, ride to the edge of the ground and right-click off the map to raise the Can't go there toast"
    expected: "The owner accepts a 526 px toast (x 377..903, one line, entirely below the clear centre), or has the copy shortened, or amends the UI-SPEC bound"
    why_human: "A 7 px per side miss of a literal band that never touches the protected rectangle is a spec-versus-taste call (03-12 D4, .planning/WINDOWS.md, D-28: decided after the owner plays the fixed build; UAT test 12 pending)"
  - name: "Gamepad on a physical pad"
    requirement: "INPT-02"
    test: "Play one full night on a real pad: ride, sprint (RB), build (A), start night (Y), slam (X), D-pad verbs, hold RT for the queue (new: RT + D-pad now queues the verb), LB layer for move / attack-move / patrol with the right-stick cursor (900 px/s), R3 select all, LB+R3 select type, Start group mode, B to cancel, D-pad right to cycle"
    expected: "Every in-run action is reachable on the pad with nothing needing a pointer; cursor speed, button feel, trigger edges and the chord layout feel right"
    why_human: "No gamepad is connected to this machine, so every pad event in every test, probe and screenshot was synthetic; the pad layout was chosen by Claude, not the owner (UAT test 9 blocked on physical-device; 03-09 D6, assumption 8)"
  - name: "Owner Phase 3 gate: two or three full runs on both devices, then sign off or name fixes"
    requirement: "UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, KING-04, KING-05, INPT-01, INPT-02, UI-01"
    test: "Re-export first (`bash tools/export.sh`; build/windows/Duskhold.exe dates from c418b6c and holds none of the 03-13 to 03-19 fixes or the retune) or launch the editor binary; play two or three full 8-night runs with an army, once on keyboard and mouse and once on a gamepad, switching device at least once per run, following 03-PLAYTEST-GATE.md"
    expected: "A recorded decision through /gsd-verify-work: sign off (squads guard and commit, selection and commands feel right on both devices, slam and regeneration suit the game, the HUD reads at night with the centre clear, the Round 2 nights are tense) or a list of fixes and any of assumptions 1 to 15 to change. No Phase 4 work starts before it"
    why_human: "The feel clauses of the success criteria (fun, tension, readability, commands that feel right) and the delegated playtest gate (D-08, Phase 2 D-18) are the owner decision; bots, CI, 1397 green tests, probes and screenshot reviews are not the sign-off (UAT test 15)"
---

# Phase 3: King Combat & Troops Verification Report (second report, after the UAT round-1 gap closure)

**Phase Goal:** The king leads an army. The player builds a Barracks and an Archery Range whose squads fight on their own, commands them RTS-style with hotkeys, mouse selection and control groups, and fires the weapon's active ability. All of it is fully playable on keyboard and mouse or on gamepad with a complete in-run HUD.
**Verified:** 2026-10-13T20:11:11Z
**Status:** human_needed
**Re-verification:** Yes. This is the second report; it supersedes the initial report of 2026-10-12T09:16:48Z (HEAD 008a9b0) and checks plans 03-13 to 03-19 (executed 2026-10-13) against HEAD e925538.

## Verdict

The engineering part of the goal is still achieved and the gap round closed every gap it claimed. I found no FAILED roadmap truth, no FAILED gap truth, no missing or stubbed artifact, no unwired key link, no debt marker and no regression of the Phase 1 or Phase 2 suites. I read the changed code at HEAD (command_key_controller.gd, king.gd, king_widget.gd, hud.gd, hud.tscn, tower.tres, the night 8 diff in prototype_map.tres, test_balance_acceptance.gd), re-ran eleven test scripts, both golden replays, lint and the contrast probe in my own process, and viewed two of the re-captured screenshots. The status stays `human_needed`, not `passed`, because the evidence a pass needs does not exist yet: the owner has not re-checked the six fixed items by eye, has not decided the E6 toast, has not played on a physical pad and has not run the gate. Those nine items are in the frontmatter, one per owner judgement, so the orchestrator can append them to 03-UAT.md one to one. Nothing here is the owner sign-off.

Every one of the six UAT gap entries is closed in code and in a test that fails when the fix is switched off: the orchestrator's mutation probes (mutate_all.log, summarised in 03-VALIDATION.md) took each fix out and the named suite failed (3 of 14, 1 of 5, 1 of 6, 1 of 5, 2 of 15, 2 of 22). G-03-11, a data retune, is covered by its own recorded RED run and by the pinned goal tests, which I re-ran green.

Thirteen code-review findings are OPEN (CR-01, WR-02, WR-03, WR-04, IN-01 to IN-09; 03-REVIEW-DISPOSITION.md `open: 13`); only WR-01 is fixed, by plan 03-14. CR-01 is unchanged at HEAD and is still the one finding that must not ship. None fails a roadmap truth, so they are WARNINGS with a decision requested, not gaps. A review-fix pass is the next step and is independent of the owner replay.

ROADMAP marks Phase 3 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form (as in Phase 2), so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD e925538 (Godot 4.7.2, Windows). `git status` was clean before and after; I modified no source, data or test file, killed no process and committed nothing. `git diff 2b43d84 HEAD -- . ':!.planning/'` is empty, so the orchestrator's full run at 2b43d84 is the full-suite evidence for the current code.

| Check | Command | Result |
|---|---|---|
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (unchanged) |
| Army replay vs golden | `bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json` | `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (unchanged) |
| G-03-8 keyboard queue | `-gselect=test_command_keys` | 14/14, 140 asserts |
| G-03-8 pad RT queue | `-gselect=test_pad_commands` | 18/18, 200 asserts |
| G-03-4 king bar follows heals | `-gselect=test_king_knockout` | 5/5, 52 asserts |
| G-03-13 knocked-out widget | `-gselect=test_king_widget` | 15/15, 106 asserts |
| G-03-14b plate | `-gselect=test_start_night_plate` | 6/6, 44 asserts |
| G-03-14 singular copy | `-gselect=test_spawn_telegraph` | 22/22 (2 scripts matched), 358 asserts |
| G-03-11 value metric | `-gselect=test_balance_value_metric` | 5/5, 45 asserts |
| G-03-11 night totals and Phase 2 wall | `-gselect=test_night_data_contract` | 16/16, 136 asserts |
| G-03-11 data pins | `-gselect=test_military_data_contract` | 7/7, 54 asserts |
| G-03-11 four goals (runs the bots over seeds 1 to 10) | `-gselect=test_balance_acceptance` | 12/12, 38 asserts, 201 s, including `test_the_balanced_bot_wins_seven_or_eight_of_ten_seeds`, `test_squads_are_worth_their_gold_against_towers` and `test_the_army_building_bot_wins_seven_or_eight_of_ten_seeds` |
| Order queue gate unchanged | `-gselect=test_squad_queue` | 15/15, 65 asserts |
| Real-window contrast (G-03-13) | `bash tools/contrast_probe.sh --image=screenshots/hud_king_down.png --rect=280,648,96,56 --min=4.5` | `CONTRAST_OK ratio=5.88 min=4.50 text_luminance=0.2530 backdrop_luminance=0.0015 fill_pixels=443` |
| Lint and format | `bash tools/lint.sh` | `265 files would be left unchanged`, `Success: no problems found` |
| Plan artifacts | `gsd-tools query verify.artifacts` on all 19 plans | 81/81 pass |
| Plan key links | `gsd-tools query verify.key-links` on all 19 plans | 52/52 verified |
| Debt markers | grep TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER over every non-planning source, data and test file changed since 008a9b0 (the .uid files hold no code) | none |
| Scope of the gap round | `git diff --name-only 90f54c6 HEAD -- . ':!.planning/' ':!screenshots/'` | 25 files: two data files, five input, presentation and ui sources, thirteen test files (two of them .uid), five tools files (one .uid); nothing under `simulation/`, no `project.godot`, no golden, no fixture |
| Screenshots viewed | `screenshots/hud_day_squads.png`, `screenshots/hud_king_down.png` | the plated "Hold N to start Night 1" prompt below the slot strip with the preview under it; "Night 7 of 8 - 1 enemy left" and a legible red "0 / 50" beside a dimmed bar |

Taken from reports without re-running: the post-merge full suites (wave 1 at 2841128: 1389/1389; wave 2 at b9c0d3d: 1392/1392; wave 3 at 2b43d84: 150 scripts, 1397/1397, 15664 asserts, 578 s, which I confirmed from the tail of `build/test-results/postmerge_test_stdout.log`), the orchestrator's mutation probes, the executors' scripted real-window probe lines quoted in the 03-13, 03-14 and 03-19 SUMMARYs, the 29-candidate Round 2 search log in 03-17-SUMMARY.md, the 33 screenshots (of which I viewed two) and CI. I did not run the full suite, the game window, the playtest bots or `tools/screenshot.sh`. `build/test-results/gut-junit.xml` on disk holds a recent single-script run, not the full suite.

Regression gate: all 29 Phase 1 and Phase 2 test script names that appear in 01-VERIFICATION.md and 02-VERIFICATION.md and exist on disk (the orchestrator counted 22 distinct scripts; my grep also catches helpers named in prose) appear in the 2b43d84 full run, which passed 1397 of 1397. One Phase 2 pin was relaxed on purpose and is flagged below (the tower opening).

## Goal Achievement

### ROADMAP success criteria (the contract), re-checked at HEAD

| # | Success criterion | Status | Evidence (delta since the first report) |
|---|---|---|---|
| 1 | Barracks and Archery Range; units guard and commit; night trickle back; full restore at dawn | VERIFIED in code and tests; feel is a human item | Unchanged by the gap round: nothing under `simulation/` or in the squad data changed since 90f54c6 (only `tower.tres` and `prototype_map.tres`). The full run at 2b43d84 carries test_squad_guard, test_squad_respawn, test_squad_lifecycle and test_squad_stance_persistence green. The owner's UAT probes confirmed guard and commit in a real window (UAT test 1 passed, with 0 target switches while the target lived). CR-01 (unbounded spawn loops on a hand-corrupted unit file) is still open, see warnings |
| 2 | Select squads (click, box, Ctrl; pad cycling); control groups; hold, follow, rally, move, attack-move, patrol, Shift queue; stances persist | VERIFIED in code and tests, now including the keyboard queue gesture; feel is a human item | `CommandKeyController._give` now submits `SquadOrderIntent.new(ids, verb, no_points, Input.is_action_pressed(QUEUE_ACTION))`, so Shift (pad RT) queues F, H and R behind queued walks; the simulation gate is untouched and still returns QUEUE_CLOSED behind a terminal order (test_squad_queue 15/15 re-run). test_command_keys 14/14 pins orders `[move, move, move, hold]` with the squad still walking, plain H still replacing the queue, Shift+F and Shift+R queuing, and test_pad_commands 18/18 pins RT + D-pad down. UAT tests 6 and 7 passed with real events. G-03-8 closed |
| 3 | Active ability with visible cooldown; king health regenerates after a short time | VERIFIED in code and tests; the in-world bar now agrees | `King.bind_run` connects `ctx.events.king_healed` (king.gd:54); `_on_king_healed` (lines 101-103) calls `_health_bar.set_health(hp, max_hp)`; `KingState._regenerate` emits `king_healed` only when integer health changed (king_state.gd:242), and `HealthBar3D.should_show` hides it at full health. test_king_knockout 5/5 re-run checks the bar ratio at every heal event, the widget label and the hide at full. The executor's real-window probe lines show ten heals with sim, bar and widget equal (0.820 to 1.000). The weak link flagged last time (WR-01, a HOLLOW readout) is closed |
| 4 | Every in-run action on keyboard and mouse and on gamepad; switch devices any time; prompts follow the device | VERIFIED in code and tests; the pad is untested on hardware | Unchanged: test_input_capabilities, test_device_model, test_prompt_switch, test_command_hints in the 2b43d84 run; UAT test 10 passed (8 of 8 alternating switches within one frame). RT-queue parity for the new gesture is in test_pad_commands. UAT test 9 stays blocked on a physical pad |
| 5 | HUD shows gold, night N of total, king health, ability cooldown and unit status without cluttering the play area | VERIFIED in code, tests and the runner check; E6 and by-eye hierarchy are human items | `ui/hud/hud.tscn` now holds `StartNightPlate` (a PanelContainer with `StyleBoxFlat_start_night_plate`, #14141A at 0.78) inside `StartNightBox`; `Hud._start_night_plate.visible = by_day`; test_start_night_plate 6/6 pins the rect (top y 624, 8 px below the strip, bottom at most y 700, preview bottom at most 716), 8 px inset, mouse IGNORE and day-only visibility, clear of the protected centre x 384..896 y 96..500. `KingWidget._apply_knocked_out` dims only the bar, plate panel (self_modulate), icon bar and glyph, leaving the count and caption at alpha 1.0 (test_king_widget 15/15, contrast 5.88:1 re-run). `Hud.enemy_count_text` gives "1 enemy" / "N enemies" to the banner and both preview patterns (test_spawn_telegraph 22/22). The clear-centre check passed on 33 of 33 shots per 03-18-SUMMARY (not re-run by me); the two shots I viewed show the plate, the singular copy and the legible count |

### UAT round-1 gaps (the second contract of this re-verification)

| Gap | Truth | Status | Evidence |
|---|---|---|---|
| G-03-4 (WR-01) | The floating bar over the king and the widget agree after a heal | VERIFIED | king.gd lines 54 and 101-103 read at HEAD; test_king_knockout 5/5 re-run; executor probe lines in 03-14-SUMMARY; mutation probe M2 (listener removed) failed 1 of 5 |
| G-03-8 | Shift-queue several moves then a hold: the hold runs after the walks (D-09) | VERIFIED | command_key_controller.gd `_give` reads `QUEUE_ACTION`; test_command_keys 14/14 and test_pad_commands 18/18 re-run; the executor's real-window probe (real right-click and key events) printed `orders_after_shift_h=["move","move","move","hold"]` and the squad held at (-3,-6); mutation probe M1 failed 3 of 14 |
| G-03-13 | The knocked-out '0 / 50' is readable | VERIFIED (by measurement and one viewed capture) | king_widget.gd lines 263-271 read; test_king_widget 15/15; probe re-run CONTRAST_OK 5.88 (unfixed 1.62 per the 03-19 SUMMARY); I viewed hud_king_down.png; mutation probe M5 failed 2 of 15. The probe itself is untested (WR-04) |
| G-03-14 | Singular copy at a count of one | VERIFIED | hud.gd lines 20-24 and 188-189 read (`ENEMY_ONE`, `ENEMY_MANY`, `enemy_count_text`, used at lines 204, 206, 224); test_spawn_telegraph 22/22; hud_king_down.png shows "1 enemy left"; mutation probe M6 failed 2 of 22 |
| G-03-14b | The start-night prompt reads as the day focal point beside a cyan selected slot | VERIFIED in code and geometry; the hierarchy itself is a human item | hud.tscn plate nodes read; test_start_night_plate 6/6; hud_day_squads.png viewed (the prompt sits on its own dark plate below the strip); mutation probe M3 failed 1 of 6. 03-UI-REVIEW still scores Visuals 3/4 because the cyan border is the most saturated element in the column, and leaves the call to the owner (D-28 made the plate the fix, the owner judges the result) |
| G-03-11 | Nights 5 to 8 serve the four owner goals at once | VERIFIED as pinned measurements; feel is a human item | `git diff 008a9b0 HEAD -- data/` shows exactly two values moved: tower tier 1 `attack_interval` 0.8 to 0.9 and the night 8 north grunt `count` 10 to 11. test_balance_acceptance 12/12 re-run (balanced 8 wins with lost seeds 3 and 9; army_balanced 8; squad_value_ratio at or above 0.8; the Phase 2 wall of nights 1 to 4 pinned in test_night_data_contract 16/16); both goldens byte-identical; MapConfig validate clean. Plan 03-18's report numbers equal 03-17's (balanced 8, army 8, ratio 0.915, nights 25 / 31 / 39 / 40). See the Round 2 warning for what it cost |

### Plan must_haves

188 plan truths (149 in 03-01 to 03-12, 39 in 03-13 to 03-19) and 25 prohibitions are declared. All 81 declared artifacts and 52 key links pass gsd-tools. The 39 new truths rest on the named tests above (green in the 2b43d84 run; I re-ran the script behind each gap plan, see the table) and on the documents I read: 03-BALANCE-REPORT.md Round 2 (outcome, what changed, search log, after-Round-2 tables, determinism section) and 03-PLAYTEST-GATE.md (the six fixed gap ids, question 6 with the new night totals, and the stale-export warning), which I read in full.

New-decision check against 03-CONTEXT.md: D-26 (squad value bar 0.8) honored (`SQUAD_VALUE_BAR 0.8` in test_balance_acceptance, no override exists); D-27 (all four goals, nights 1 to 4 untouched, locked D-01, D-05, D-07 values unmoved) honored (night totals 5 / 12 / 21 / 21 unchanged, only two values moved); D-28 honored (plate in 03-15, opaque count in 03-19, `Toast.CANT_GO_THERE` untouched so E6 stays pending, no auto-join of control groups, tests 9 and 15 left to the owner). Plan 03-15 relaxed the gap entry's "inside y 616..700" so the 18 px preview sits unplated below the plate (y 690..716): a recorded key decision, the plate itself ends at y 690, and the clear-centre bound holds.

Prohibitions (all judgment-tier or backstop; my reading is NON-AUTHORITATIVE and flagged `unverified-prohibition - human review recommended`, none is absorbed into the pass): the new ones were read against git. No simulation, golden, fixture or input-map change in the gap round (the command-key queue flag is a plain bool in an existing intent; the gate re-validates it); the balance search edited no repository data (the SUMMARY states each candidate ran in a private project copy; I did not re-derive this, but `git diff` shows only the two intended data edits); no unit health moved (so the CR-01 loop is not made reachable by Round 2); the plate ignores the mouse (test pins it); E6 is untouched. The 14 prohibitions of the first report are unchanged and were not re-read beyond confirming that no file they concern was edited.

### Requirements Coverage

All 11 phase IDs appear in at least one plan `requirements:` field (03-12 lists all 11; the gap plans add UNIT-10, UNIT-05, INPT-01, INPT-02, KING-05, UI-01, UNIT-04, UNIT-07 and KING-04 on top) and REQUIREMENTS.md maps exactly these 11 to Phase 3 (traceability lines 191 to 248, each ticked Complete). I re-read the requirement text for KING-04, KING-05, UNIT-04 to UNIT-07, UNIT-09, UNIT-10, INPT-01, INPT-02 and UI-01 against the criteria above. No ID is orphaned and none is missing from a plan. INPT-03 stays open by design (Phase 13, not a Phase 3 ID).

| Requirement | Source plans (gap round in bold) | Status | Evidence |
|---|---|---|---|
| UNIT-04 | 03-01, 03-02, 03-11, 03-12, **03-16, 03-17, 03-18** | SATISFIED in code and tests; feel at the gate | Criterion 1; Round 2 balance pinned |
| UNIT-05 | 03-06, 03-12, **03-13** | SATISFIED | Hold on H and pad D-pad down; Shift+H now also queues a hold behind walks; plain H unchanged |
| UNIT-06 | 03-06, 03-12 | SATISFIED | Follow on F / D-pad up; select all and select type; Shift+F queues (03-13) |
| UNIT-07 | 03-02, 03-05, 03-11, 03-12, **03-16, 03-17, 03-18** | SATISFIED | Trickle and dawn restore unchanged and green |
| UNIT-09 | 03-06, 03-08, 03-09, 03-12 | SATISFIED | Unchanged by the gap round; test_selection_*, test_control_group* green in the full run |
| UNIT-10 | 03-07, 03-08, 03-09, 03-11, 03-12, **03-13** | SATISFIED | Criterion 2 |
| KING-04 | 03-04, 03-10, 03-11, 03-12, **03-17, 03-18** | SATISFIED | Slam values unchanged (4 m / 4 damage / 9 s; the 03-17 search moved no slam value) |
| KING-05 | 03-04, 03-12, **03-14, 03-17, 03-18** | SATISFIED in the simulation, on the widget and now on the floating bar | Criterion 3 |
| INPT-01 | 03-06 to 03-09, 03-12, **03-13** | SATISFIED in code; the 03-13 gesture driven with real events in a window | Criterion 2 and 4 |
| INPT-02 | 03-09, 03-10, 03-12, **03-13** | SATISFIED in code; synthetic pad events only | Criterion 4; UAT test 9 blocked |
| UI-01 | 03-03, 03-04, 03-05, 03-10, 03-12, **03-14, 03-15, 03-19** | SATISFIED in code, tests and the runner check | Criterion 5 |

REQUIREMENTS.md ticks reflect implementation, not the owner gate.

### Data-Flow Trace (Level 4)

FLOWING for everything the gap round touched. `KingState._regenerate` -> `king_healed(gained, hp, max_hp)` -> `King._on_king_healed` -> `HealthBar3D.set_health` (the one HOLLOW link of the first report, now connected; `KingWidget` still polls the same state). `Input.is_action_pressed(command_queue)` at the press -> `SquadOrderIntent.queued` -> `CommandProcessor` -> `SquadSystem.apply_order` (queue kept behind walks, QUEUE_CLOSED behind a terminal verb). `KingState.is_down()` -> `KingWidget._apply_knocked_out` -> per-part alpha. `NightSim.remaining_count()` and the night total -> `Hud.enemy_count_text` -> banner and preview. `ReplayDriver.Tally` (a read-only listener on `building_built`) -> run entries -> `BalanceReport.summary` -> `squad_value_ratio` -> the report and the acceptance test; both goldens replay unchanged, which is the proof it writes nothing back. No hardcoded empty value reaches the UI. The payout line is Phase 1 and 2 code and unchanged (see the warning).

### Behavioral Spot-Checks and Replays

See "What I ran". Behavior-dependent truths of the gap round (a queued verb waits behind the walks and a plain verb replaces the queue; the bar follows each heal and hides at full health; the knocked-out count keeps alpha 1.0; the plate is mouse-transparent and day-only) each have a passing named test that exercises the transition, and the orchestrator's mutation probes show each test fails when its fix is removed. `behavior_unverified: 0`. What is not behaviorally verified is everything that needs a human or hardware: see Human Verification.

### Probe Execution

No `probe-*.sh` files are declared by the phase plans or exist under `scripts/`: SKIPPED. (The phase's own `tools/contrast_probe.sh` is a measurement tool, run above, not a declared verification probe.)

### Anti-Patterns Found

None blocking. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in the non-planning files changed by the gap round. The one real defect class remains CR-01 (unbounded `while _living_count(squad) < squad.cap` over unvalidated data), untouched. The new review items (WR-04, IN-07 to IN-09) are test-coverage and consistency notes, not defects in shipped behaviour.

## Open code-review findings (13 OPEN, 1 FIXED)

| ID | Severity (review) | State | My weighing |
|---|---|---|---|
| CR-01 | critical | OPEN, re-confirmed unchanged at HEAD | WARNING. Hang and unbounded memory on a unit with `max_health <= 0`; shipped data safe; must be fixed before release; T-03-04 and T-03-05 still open |
| WR-01 | warning | FIXED by 03-14 (ee21f6f), re-verified by the 2026-10-13 review and by me | Closed (G-03-4) |
| WR-02 | warning | OPEN | WARNING. screenshot.sh cannot see script errors |
| WR-03 | warning | OPEN, widened by 03-13 | WARNING. Refused queued orders, including Shift+verb behind a terminal order, are silent |
| WR-04 | warning | OPEN (new) | WARNING. The contrast probe's guard and measurement have no test |
| IN-01 to IN-06 | info | OPEN | INFO |
| IN-07 to IN-09 | info | OPEN (new) | INFO |

## Human Verification Required

The structured list is in the frontmatter: nine entries, one per owner judgement left after this round. They are the by-eye re-checks of the six fixed items (G-03-4, G-03-8, G-03-11, G-03-13, G-03-14, G-03-14b), the E6 toast decision, the physical pad and the gate itself. I did not repeat the seven items the owner passed in UAT round 1 (tests 1, 2, 3, 5, 6, 7, 10): the gap round did not change the code behind them (nothing under `simulation/` moved, and the only input change is the added queue flag in `_give`, which test 6 and 7's paths do not use). Test 11's data did change, so its re-check carries the new numbers. The decisive entry remains the owner gate in 03-PLAYTEST-GATE.md; re-export or use the editor binary first, because the exported build is stale.

## Gaps Summary

No gaps and no blockers. All five roadmap success criteria are implemented, wired and tested at HEAD; all six UAT round-1 gaps are closed in code with a test that fails when the fix is removed; the replays are byte-identical to their goldens, lint is clean, and the 1397-test suite was green on the code that is still current. The status is `human_needed` because the owner has not yet re-checked the fixed items, decided E6, played on a pad or run the gate, and because thirteen open review findings (one critical) wait for a review-fix pass. The Round 2 retune met its four measured goals but did so by slowing the first tower, which took the tower routes' wins with it (towers_first 0 of 10, houses_first 4 of 10) and relaxed a Phase 2 pin; the report is candid about it and the owner should say whether that is acceptable. Do not treat the 1397 green tests, the replay digests, the balance table, the contrast probe, the screenshot reads or this report as the sign-off, and do not start Phase 4 before the owner decides. Suggested order: the owner re-checks and the gate (UAT tests 4, 8, 11, 13, 14, 12, 9, 15) on a fresh export, and independently the review-fix pass (CR-01 first, then WR-03, WR-04, WR-02, then the info items). If the fix pass changes any file under the covered list, re-run `verification.status` to refresh the fingerprint.

**Coverage fingerprint note.** `covered_files` is the orchestrator's 309-path list with two changes: 03-VERIFICATION.md itself was removed (a report cannot cover its own bytes, so its digest could never match) and `ui/hud/dawn_payout_vfx.gd` was added (I read it for the payout-line finding). `03-UAT.md` and the other phase documents stay covered, so appending the nine human items to 03-UAT.md changes the digest: after that edit, recompute it with `verification.fingerprint` over the frontmatter list and replace `covered_digest`, or `verification.status` will read `stale`.

---

_Verified: 2026-10-13T20:11:11Z
_Verifier: Claude (gsd-verifier)_
