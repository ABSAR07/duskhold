---
phase: 03-king-combat-troops
verified: 2026-10-12T09:16:48Z
status: human_needed
score: 5/5 roadmap success criteria verified in code and tests (0 failed); 11/11 requirement IDs have implementation evidence; owner feel gate (UAT) not yet run
must_haves:
  roadmap_truths: 5
  roadmap_truths_verified: 5
  roadmap_truths_failed: 0
  plan_truths_declared: 149
  plan_artifacts_checked: "55/55 pass (gsd-tools verify.artifacts over all 12 plans)"
  plan_key_links_checked: "38/38 wired (gsd-tools verify.key-links over all 12 plans)"
  prohibitions_declared: 14
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass"
  requirement_ids: 11
  requirement_ids_satisfied: 11
  requirement_ids_orphaned: 0
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
  - .planning/phases/03-king-combat-troops/03-BALANCE-REPORT.md
  - .planning/phases/03-king-combat-troops/03-CONTEXT.md
  - .planning/phases/03-king-combat-troops/03-PLAYTEST-GATE.md
  - .planning/phases/03-king-combat-troops/03-RESEARCH.md
  - .planning/phases/03-king-combat-troops/03-REVIEW-DISPOSITION.md
  - .planning/phases/03-king-combat-troops/03-REVIEW.md
  - .planning/phases/03-king-combat-troops/03-SECURITY.md
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
  - tests/e2e/test_king_widget.gd
  - tests/e2e/test_mouse_commands.gd
  - tests/e2e/test_order_markers.gd
  - tests/e2e/test_pad_commands.gd
  - tests/e2e/test_pad_cursor.gd
  - tests/e2e/test_prompt_switch.gd
  - tests/e2e/test_select_one_type.gd
  - tests/e2e/test_selection_steering.gd
  - tests/e2e/test_squad_selection.gd
  - tests/e2e/test_squad_strip.gd
  - tests/e2e/test_squad_tracer_scene.gd
  - tests/e2e/test_start_night_hold.gd
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
covered_digest: "v2:sha256:ae0c9a4d1880e10ce7dbfed7b66820a2da1ffd2561a06ebf4851995139b9771c"
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
  - id: "CR-01 (03-REVIEW, OPEN)"
    where: "simulation/squads/squad_system.gd _fill and restore_for_dawn (while loops), simulation/squads/unit_system.gd spawn (health = def.max_health, unclamped), simulation/run/run_context.gd (push_error only)"
    issue: "I re-read all four spots at HEAD and confirm the finding. A UnitDef with max_health <= 0 is reported by MapConfig validation but RunContext only push_errors; spawn stores the health unclamped, is_alive is health > 0, and both loops run until the living count reaches the cap, which a born-dead unit never allows. The first day step after a military building stands (or the first dawn) hangs the main thread and grows memory without bound. The shipped data (footman 10, archer 6) cannot trigger it, so no roadmap truth fails. 03-SECURITY.md closes T-03-04 and T-03-05 on the strength of the validation, which this finding shows is only advisory on the consumer side; that closure should be reopened until the loops are bounded."
    decision_requested: "Fix in the review-fix pass (bound both loops by the missing seats, floor the stored health at 1, add a test that builds a Barracks over a max_health = 0 footman and expects the step to return). Not a gap: hand-corrupted .tres only, and the shipped data validates clean. I weighed it as a WARNING, not a BLOCKER, because no success criterion depends on corrupted data; it is still the one finding that must not ship."
  - id: "WR-01 (03-REVIEW, OPEN)"
    where: "presentation/king/king.gd bind_run (lines 51-54)"
    issue: "Confirmed: king_healed is emitted by KingState._regenerate and has no consumer outside the recorder, so the king's floating HealthBar3D freezes at the damaged value while the HUD KingWidget (which polls) climbs back. Success criterion 3 (health regenerates) is true in the simulation and on the HUD; the in-world bar disagrees until the next hit, respawn or dawn."
    decision_requested: "Fix in the review-fix pass (connect king_healed to set_health, plus an e2e assertion that the bar hides again). Not a gap."
  - id: "WR-02 (03-REVIEW, OPEN)"
    where: "tools/screenshot.sh lines 97-116"
    issue: "Confirmed by reading: the wrapper passes a shot on exit status 0 plus a non-blank PNG and, unlike tools/replay.sh and tools/playtest.sh, does not scan the Godot output for SCRIPT ERROR or Parse Error. A script error in a HUD node would leave the CI screenshots job green. Tooling only."
    decision_requested: "Fix in the review-fix pass or accept."
  - id: "WR-03 (03-REVIEW, OPEN)"
    where: "input/selection_controller.gd _order, input/pad_cursor_controller.gd _confirm, simulation/commands/command_processor.gd"
    issue: "Confirmed: a repo-wide search of input/, presentation/ and ui/ finds no consumer of command_rejected, and both controllers drop the reason submit returns. A Shift-queued order behind a pending hold, follow or patrol is refused silently while the patrol disc on the ground suggests the queue is open. The refusal is also all-or-nothing for a mixed selection. Success criterion 2 is met (the order set works and the gate is tested); this is a feedback gap on a reachable edge."
    decision_requested: "Fix in the review-fix pass (toast for QUEUE_CLOSED, per-squad skip) and add the copy to UI-SPEC, or accept and tell the owner at UAT."
  - id: "IN-01 to IN-06 (03-REVIEW, all OPEN)"
    where: "squad_system.gd (dead patrol budget), command_processor.gd and ground_pick.gd (ground bound twice), unit_system.gd and enemy_system.gd (35-line separate pass duplicated), test-only accessors, three unused ext_resource lines, the eighth patrol click dropped silently"
    issue: "Info only; none changes a success criterion. Listed so the review-fix pass has the full ledger. All ten review findings are open per 03-REVIEW-DISPOSITION.md."
    decision_requested: "Fix or defer in the review-fix pass."
  - id: "D-08 reading (judgment call, flagged)"
    where: "03-CONTEXT.md D-08, 03-11-SUMMARY, 03-BALANCE-REPORT.md"
    issue: "D-08 reads that the balanced bot still wins 7 or 8 of 10. The retune pinned the bar on the new army_balanced bot (8 of 10) and left the balanced bot at 9 of 10 (it loses 1, not the 2 or 3 the owner asked for in G-02-15). The report states this plainly and says counts alone cannot reach both bars. It also states that squads are not stronger than towers per gold under the bots. These are measurements, not the failure of a roadmap truth."
    decision_requested: "Owner decides at the gate which bar the nights serve and whether the army is worth its gold."
  - id: "E6 toast width (known, human_needed)"
    where: "ui/hud/toast.gd CANT_GO_THERE"
    issue: "526 px wide at x 377..903, 7 px past the UI-SPEC literal x 384..896 band on each side, on one line below the protected rectangle (y 504..536; the centre band ends at y 500). The runner's clear-centre check passes. Recorded in .planning/WINDOWS.md. I treat it as a human decision, not an automated failure: it never enters the clear centre, which is what success criterion 5 protects."
    decision_requested: "Owner: accept, shorten the copy (UI-REVIEW suggests a shorter line) or amend the bound."
behavior_unverified_items: []
human_verification:
  - name: "Guard and commit readability at night"
    requirement: "UNIT-04"
    test: "Build a Barracks and an Archery Range, play a night and watch the squads: footmen holding the ground in front of the plot, picking one grunt and staying on it, then walking back to the post; archers staying back and shooting"
    expected: "Units read as footmen and archers, guard rather than wander, commit to one target instead of flip-flopping and return to their formation after the fight, even as static bind-pose puppets"
    why_human: "Commit and leash rules are pinned by test_squad_guard (14/14, re-run by me), but whether the behaviour reads as intelligent or as thrashing, and how small plain-coloured units read at night, is a visual judgement (03-01 D8)"
  - name: "Barracks and Archery Range models and replacement pace"
    requirement: "UNIT-07"
    test: "Build each military plot to tier 3 and look at the models; lose units at night and watch the 10 / 7 / 4 s trickle at the building, then the full restore at dawn"
    expected: "Each tier reads bigger than the last next to the House and Tower models, the trickle pace feels right for the gold spent, and dawn visibly makes every squad whole"
    why_human: "Headless Godot cannot render; tests assert scene use and tier growth only (03-02 D8)"
  - name: "HUD in a real window at 1920x1080 and 16:10"
    requirement: "UI-01"
    test: "Open the exported build at 1920x1080 and at a 16:10 resolution, play a day and a night, and compare with screenshots hud_day_squads_1080p, hud_night_squad_down_16x10 and hud_day_counter_long"
    expected: "The HUD scales uniformly, Night N of 8 reads over the 3D scene, nothing overlaps and the middle of the screen stays clear"
    why_human: "The look over the real scene is a judgement; headless proves only the 1280x720 base space (03-03 D6)"
  - name: "Slam and regeneration feel"
    requirement: "KING-04, KING-05"
    test: "Press Q (pad X) amid enemies and by day; watch the ring, the sword icon fill and the ready flash; take a hit, stop being hit and watch health return"
    expected: "The 4 m / 4 damage / 9 s slam feels useful, the ring and flash read, and regeneration (1 s delay, 10 percent of max per second) feels Thronefall-like and not too generous. The floating bar over the king and the bottom-left widget agree after a heal (see WR-01: today they do not)"
    why_human: "Animation and balance feel (03-04 D8); the mechanics are test-pinned (test_king_slam 16/16 and test_king_regen 16/16, re-run by me)"
  - name: "Squad slot look at 1280x720"
    requirement: "UI-01"
    test: "Compare the bottom-centre squad strip with 03-UI-SPEC.md in play: icon weight, alive / max, stance glyph at 20 px, replacement fill and the dawn border flash"
    expected: "Slots read at a glance and the post, hold, follow, patrol and attack-move glyphs are tellable apart at slot size (03-UI-REVIEW notes post, hold and patrol look alike at that size)"
    why_human: "Legibility is visual (03-05 D7)"
  - name: "Selection, follow, hold and rally feel"
    requirement: "UNIT-05, UNIT-06, UNIT-09"
    test: "Click a squad, double-click a unit (every squad of that type), Tab, F2; press F, H and R; watch the rings and the slot highlight; end a night and check a held or following squad keeps its stance the next day"
    expected: "Selection and the three verbs respond at once and read clearly; hold-at-centroid and rally-ignores-enemies match what the owner meant; stances persist across dawn"
    why_human: "Feel and legibility (03-06 D9); persistence itself is test-pinned (test_squad_stance_persistence 3/3, re-run by me)"
  - name: "Right-click move, attack-move on A, and the king standing still while a squad is selected"
    requirement: "UNIT-10, INPT-01"
    test: "Select a squad and hold A: the king must not move; then left-click ground to attack-move. Press Escape once to cancel an armed command and again to clear the selection. With nothing selected hold A and the king rides left. Right-click ground to move"
    expected: "The D-15 amendment (keep A, movement goes to the selection, the king is the implicit selection, Escape clears) feels right in play, and the pings and the armed line read"
    why_human: "The owner decided this routing at the 03-07 checkpoint and must confirm it in play (03-07 D8); the rule is test-pinned (test_selection_steering e2e, test_king_selection_steering 2/2 re-run by me)"
  - name: "Patrol, Shift queue, drag box and control groups"
    requirement: "UNIT-09, UNIT-10"
    test: "Hold P and right-click points, release P; Shift-queue several moves then a hold; drag a box over both squads; Ctrl+1 to store and 1 to recall; build a new squad while a group exists"
    expected: "The patrol line, numbered queue discs (nine orders kept, six drawn), hover rings, drag box, recall flash and slot badges read well. The owner decides whether a newly built squad should auto-join a group (today it joins none, assumption 9)"
    why_human: "Feel, legibility and one open product question (03-08 D7)"
  - name: "Gamepad on a physical pad"
    requirement: "INPT-02"
    test: "Play one full night on a real pad: ride, sprint (RB), build (A), start night (Y), slam (X), D-pad verbs, LB layer for move / attack-move / patrol with the right-stick cursor (900 px/s), R3 select all, LB+R3 select type, Start group mode, RT to queue, B to cancel, D-pad right to cycle"
    expected: "Every in-run action is reachable on the pad with nothing needing a pointer; cursor speed, button feel, trigger edges and the chord layout feel right"
    why_human: "Every pad event in every test and screenshot was synthetic; no physical pad was available to the executors (03-09 D6). The pad layout was chosen by Claude, not the owner (assumption 8)"
  - name: "Prompts follow the device; glyph legibility at 24 px"
    requirement: "INPT-02, UI-01"
    test: "Switch between keyboard-and-mouse and the pad mid-run several times, in a day and in a fight, and read the start-night line, the slam badge and the hint row"
    expected: "Every prompt flips at once on any press or stick move of the other device (mouse counts as keyboard); 24 px tiles are readable (the D-pad tile is a cross with one arm lit, the Shift and Q tiles are small); Xbox tiles are acceptable on a non-Xbox pad (deferred to Phase 13)"
    why_human: "Legibility and taste on a real monitor and pad (03-10 D7); the switching logic is test-pinned (test_device_model, test_prompt_switch)"
  - name: "Balance feel with an army"
    requirement: "UNIT-04"
    test: "Play three nights with an army, including nights 5 to 8 (now 25 / 31 / 39 / 39 enemies), and read 03-BALANCE-REPORT.md"
    expected: "The owner says which balance finding to accept: squads are not stronger than towers per gold under the bots; the balanced bot loses 1 of 10, not the 2 or 3 asked for in G-02-15; night 8 equals night 7. Nights feel tense with squads"
    why_human: "The bots build instantly and cannot judge tension; they measure the data only (03-11 D7, D-08, Phase 2 D-18)"
  - name: "E6: longest toast inside x 384..896"
    requirement: "UI-01"
    test: "Select a squad, ride to the edge of the ground and right-click off the map to raise the Can't go there toast"
    expected: "The owner accepts a 526 px toast (x 377..903, one line, entirely below the clear centre), or has the copy shortened, or amends the UI-SPEC bound"
    why_human: "A 7 px per side miss of a literal band that never touches the protected rectangle is a spec-versus-taste call (03-12 D4, .planning/WINDOWS.md)"
  - name: "Knocked-out king widget legibility"
    requirement: "UI-01"
    test: "Get the king knocked out at night and read the bottom-left widget and the Knocked out countdown label (screenshot hud_king_down)"
    expected: "The red 0 / 50 is readable (KNOCKED_OUT_ALPHA 0.4 gives about 1.6:1 contrast per 03-UI-REVIEW.md); otherwise raise the alpha or keep the label opaque"
    why_human: "Contrast on the real scene is a visual judgement; 03-UI-REVIEW.md priority fix 1"
  - name: "Bottom-centre hierarchy, plural copy and the lingering payout line"
    requirement: "UI-01"
    test: "On a day with a squad selected look at the bottom-centre stack (hint row, slots, start-night prompt, fill bar, preview); at one enemy left read the banner; after a dawn look for the +2 gold line"
    expected: "The start-night prompt still reads as the day focal point beside a cyan selected slot; the banner says 1 enemy and not 1 enemies left; the payout line expires at the next day start. These are owner-flagged open points (UI-REVIEW fix 3, PLAYTEST-GATE open readability points); the plural and payout lines are Phase 1 and 2 copy outside the files of this phase"
    why_human: "Taste and clutter judgement, plus the owner decision whether they block Phase 4"
  - name: "Owner Phase 3 gate: two or three full runs on both devices, then sign off or name fixes"
    requirement: "UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, KING-04, KING-05, INPT-01, INPT-02, UI-01"
    test: "Launch build/windows/Duskhold.exe (exported 2026-10-12 from c418b6c, launch-checked, exit 0) or the editor binary, play two or three full 8-night runs with an army, once on keyboard and mouse and once on a gamepad, switching device at least once per run, following 03-PLAYTEST-GATE.md"
    expected: "A recorded decision through /gsd-verify-work: sign off (squads guard and commit, selection and commands feel right on both devices, slam and regeneration suit the game, the HUD reads at night with the centre clear, the retuned nights are tense) or a list of fixes and any of assumptions 1 to 15 to change. No Phase 4 work starts before it"
    why_human: "The feel clauses of the success criteria (fun, tension, readability, commands that feel right) and the delegated playtest gate (D-08, Phase 2 D-18) are the owner decision; bots, CI, 1373 green tests and screenshot reviews are not the sign-off"
---

# Phase 3: King Combat & Troops Verification Report

**Phase Goal:** The king leads an army. The player builds a Barracks and an Archery Range whose squads fight on their own, commands them RTS-style with hotkeys, mouse selection and control groups, and fires the weapon active ability. All of it is fully playable on keyboard and mouse or on gamepad with a complete in-run HUD.
**Verified:** 2026-10-12T09:16:48Z
**Status:** human_needed
**Re-verification:** No, initial verification (no earlier 03-VERIFICATION.md existed)

## Verdict

The engineering part of the goal is achieved and I found no FAILED roadmap truth, no missing or stubbed artifact, no unwired key link and no debt marker. I read the squad, king, command-gate, run-step, input-map and HUD code at HEAD (008a9b0; the last non-planning change is c418b6c, `git diff c418b6c HEAD` outside `.planning/` is empty and `git status` is clean), and re-ran the replays and eleven test scripts in my own process. The phase is not `passed` because the evidence it needs for that does not exist yet: UAT has not been run, and the feel half of the success criteria (squads that read as intelligent rather than thrashing, commands that feel right, a HUD that stays readable in a fight, nights that are tense with an army) is the owner delegated playtest gate (D-08, Phase 2 D-18). Every one of the twelve SUMMARYs also marks coverage items `human_judgment: true`; I harvested them into the 15 `human_verification` entries in the frontmatter so the orchestrator can turn them into 03-UAT.md one to one. Nothing here is the owner sign-off.

All ten findings of the code review (03-REVIEW.md, 2026-10-12: 1 critical, 3 warnings, 6 info) are OPEN (03-REVIEW-DISPOSITION.md: `open: 10`). I re-read the code behind CR-01, WR-01, WR-02 and WR-03 and confirm each one; none fails a roadmap truth (CR-01 needs a hand-corrupted unit file, the shipped footman and archer have 10 and 6 health), so they are carried as WARNINGS with a decision requested, not as gaps. A review-fix pass is the next step and is independent of the owner replay. CR-01 is the one that must not ship, and it contradicts the closed status of T-03-04 and T-03-05 in 03-SECURITY.md.

ROADMAP marks Phase 3 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form (same as Phase 2), so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD 008a9b0 (Godot 4.7.2, Windows). `git status` was clean before and after; no source file was modified, no process was killed, nothing was committed.

| Check | Command | Result |
|---|---|---|
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` |
| Army replay vs golden | `bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json` | `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` |
| Input capability table | `-gselect=test_input_capabilities` | 9/9, 296 asserts |
| Guard, commit, leash | `-gselect=test_squad_guard` | 14/14, 169 asserts |
| Night trickle and freeze | `-gselect=test_squad_respawn` | 14/14, 648 asserts |
| Stances persist across dawn | `-gselect=test_squad_stance_persistence` | 3/3, 35 asserts |
| King regeneration | `-gselect=test_king_regen` | 16/16, 43 asserts |
| Slam and cooldown | `-gselect=test_king_slam` | 16/16, 69 asserts |
| King stops while a squad is selected | `-gselect=test_king_selection_steering` | 2/2, 8 asserts |
| Lint and format | `bash tools/lint.sh` | `262 files would be left unchanged`, `Success: no problems found` |
| Plan artifacts | `gsd-tools query verify.artifacts` on all 12 plans | 55/55 pass |
| Plan key links | `gsd-tools query verify.key-links` on all 12 plans | 38/38 verified |
| Debt markers | grep TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER over the 173 text files of the phase scope | none |
| Phase file scope | `git diff --name-only fb2e0cd HEAD` minus `.planning/`, `screenshots/`, `.uid` and `.import` | 250 files, identical to the 173 text files of build/review_scope_filtered.txt plus 77 binary assets (2 GLB, 74 PNG, 1 licence); all are in `covered_files` |

Taken from reports without re-running: the full suite at HEAD b7db3d5 (`build/test-results/postmerge_test_stdout.log`, which I read: Scripts 148, Tests 1373, Passing 1373, Asserts 15367, exit 0), CI run 38219154906 (lint, test, export and screenshots green, REPLAY_OK for smoke, army and full_idle, 33 of 33 screenshots; I did not query GitHub), the 33 screenshots and the screenshot reads in 03-PLAYTEST-GATE.md (not viewed by me), the plan-level truths beyond the ones listed below (149 declared; each rests on its named test being green in the gate run, not on my reading), and the mutation probes recorded in the SUMMARYs. I did not run the whole suite, the game window or the playtest bots. `build/test-results/gut-junit.xml` on disk now holds my last single-file run, not the full suite.

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | Barracks and Archery Range; units guard their post and commit; night trickle back; full restore at dawn | VERIFIED in code and tests; feel is a human item | `data/buildings/barracks.tres` and `archery_range.tres`: costs 4 / 8 / 16, squads 4 / 8 / 14, respawn 10 / 7 / 4 s, unit ids footman and archer; two plots `barracks_1` and `archery_1` appended to the ten-spot list in `prototype_map.tres`. `SquadSystem._choose_target` keeps a live target inside leash_range of the anchor and only rescans on the unit own staggered tick (never swaps to a nearer enemy); `_step_unit` fires through PendingHits once per attack_interval; `_trickle` raises one unit at the post per respawn interval while the building stands and freezes if it fell; `RunManager._enter_dawn` calls `_squads.restore_for_dawn()` after the rebuild (survivors healed, every missing seat raised, anchor and orders untouched). `NightSim.step` and `step_day` both step the squads; `RunContext.step` runs them in every phase. Tests re-run by me: test_squad_guard 14/14 (including committed target kept when a nearer enemy appears, target beyond leash dropped), test_squad_respawn 14/14. Dawn restore and next-day settle are in test_squad_lifecycle (4 tests, green in the gate run) |
| 2 | Select squads (click, box, Ctrl, pad cycling); control groups; hold, follow (all or one type), rally, move, attack-move, patrol, Shift queue; stances persist across dawn | VERIFIED in code and tests; feel is a human item | `project.godot` binds squad_follow F, squad_hold H, squad_rally R, squad_cycle Tab, select_all F2, squad_move right mouse, squad_attack_move A (kept, D-15 amendment), squad_patrol P, command_queue Shift, command_cancel Escape, group_0 to group_9, plus the pad-only command_layer, group_mode, select_type and cursor actions. `SquadSystem.apply_order`, `_enqueue` (MAX_QUEUE 9, rally as move then hold), `_begin` and `_advance_patrol` (ping-pong) implement the verbs; `CommandProcessor._submit_squad_order` gates ids, verbs, points (BAD_POINT, TOO_MANY_POINTS) and QUEUE_CLOSED and converts centimetres to metres. `SelectionController` handles click, drag box, Ctrl, double-click for one type, Escape; control groups live in `SelectionModel` (store_group, recall_group) and are covered by test_control_groups and test_control_group_keys. `restore_for_dawn` never touches `resting_stance`, queue or anchor; test_squad_stance_persistence 3/3 re-run by me (held squad keeps stance and spot through night, dawn and the next day; following squad still follows; a replacement appears at the post and walks to the squad) |
| 3 | Active ability with visible cooldown; king health regenerates after a short time without damage | VERIFIED in code and tests; WR-01 is a presentation inconsistency | `data/king/sword.tres`: slam_radius 4.0, slam_damage 4, slam_cooldown_seconds 9.0; `data/king/king.tres`: regen_delay_seconds 1.0, regen_fraction_per_second 0.1, weapon = sword. `AbilityController` submits `ActivateAbilityIntent` on the ability action (Q, pad X); `CommandProcessor._ability_rejection` returns RUN_OVER, NO_ABILITY, KING_DOWN or ABILITY_COOLING; `KingState.activate_ability/resolve_ability` hit enemies only (no squads, buildings or castle) and `tick_timers` runs the cooldown and `_regenerate` in every phase (called first in `RunContext.step`). `KingWidget` polls `ability_cooldown_ratio()` for the radial fill and the ready flash. test_king_slam 16/16 and test_king_regen 16/16 re-run by me. WR-01: the floating king bar never listens to `king_healed` (confirmed by search) |
| 4 | Every in-run action on keyboard and mouse and on gamepad; switch devices any time; prompts follow the device | VERIFIED in code and tests; the pad is untested on hardware | Move, sprint, build, start_night, ability, the three verbs, move, attack-move, patrol, queue, cancel, cycle, select_all and select_type, groups and cursor each have a keyboard-or-mouse binding and a joypad binding in `project.godot`; `test_input_capabilities` (9/9, re-run by me) pins a path per capability per device and fails if a project action is missing from the table. `LastDeviceTracker`/`DeviceModel` (debounce 0.25 s, axis threshold above the deadzone) and `GlyphResolver` re-render the start-night prompt, slam badge and hint row on a device change (test_device_model, test_prompt_switch, test_command_hints in the gate run). The selection-steering rule from the D-15 amendment is implemented in `King.steered_direction` (all movement input zeroed while the selection is non-empty) with Escape clearing it |
| 5 | HUD shows gold, night N of total, king health, ability cooldown, unit group status without cluttering the play area | VERIFIED in code, tests and the runner check; E6 and legibility are human items | `ui/hud/hud.tscn` holds GoldLabel (top-left), `DayCounter` (top-centre, "Night %d of %d", shown by day and dawn, reads `RunManager.get_total_nights()`), `KingWidget` (bottom-left: health bar and number, sword icon with clockwise fill and ready flash), `SquadStrip` (bottom-centre: one `SquadSlot` per squad with icon, alive / max, stance glyph, group badge, selection highlight, replacement fill), Toast, CommandHints and DragBox, all under a mouse_filter IGNORE `HudRoot` and all in the `run_bound` group so `MapRoot` calls `bind_run` on them. `ShotRunner.protected_violations` fails any hud_ or cmd_ shot with a HUD control in x 384..896, y 96..500 (test_shot_protected_centre in the gate run; 33 of 33 shots passed in CI per the report) |

### Plan must_haves

149 plan truths and 14 prohibitions are declared across the twelve plans. Beyond the roadmap contract above, I checked all 55 declared artifacts and 38 key links with gsd-tools (all pass), and spot-read the decisive code for D-01 to D-07, D-09, D-14, D-15 (amended), D-17, D-18, D-20, D-21 to D-23 against 03-CONTEXT.md:

| Decision | Honored? | Evidence |
|---|---|---|
| D-01 / D-02 squad caps 4 / 8 / 14, costs 4 / 8 / 16 | Yes | barracks.tres and archery_range.tres as read; pinned by test_military_data_contract |
| D-03 two plots added, the eight existing untouched | Yes | the spot list ends with barracks_1 and archery_1; the smoke golden is byte-identical (re-run by me) |
| D-04 post guard, commit | Yes | `_choose_target`, `_walk_to_slot`, `_make_squad` (post is post_distance 3.5 toward the castle) |
| D-05 trickle 10 / 7 / 4 s, dawn restore | Yes | `_trickle`, `restore_for_dawn`, data above |
| D-06 / D-07 unit roles and strength | Yes | footman 10 hp, 1 damage, reach 1.2; archer 6 hp, range 8.5, arrow 16 m/s; a fifth of the king (50 hp, 5 damage) |
| D-09 whole-squad verbs, Shift queues | Yes | `SquadOrderIntent` carries squad ids only; no per-unit command path exists (judgment prohibition read: no unit-id order API) |
| D-14 stances persist | Yes | test_squad_stance_persistence |
| D-15 amendment (keep A, movement goes to the selection, king implicit selection, Escape clears) | Yes | squad_attack_move = A in project.godot; `King.steered_direction`; test_selection_steering e2e has the A-hold, Escape and cleared-selection cases; test_king_selection_steering 2/2 re-run |
| D-17 / D-18 slam and WeaponDef | Yes | `WeaponDef` read via `KingDef.weapon`; sword.tres |
| D-20 regeneration 1 s then 10 percent per second, day and night | Yes | king.tres and `_regenerate`; `tick_timers` runs in every phase |
| D-21 to D-23 HUD layout and slots | Yes | hud.tscn node list and KingWidget, SquadStrip, SquadSlot headers as read |
| D-24 glyphs follow the active device | Yes in code; legibility is human | `GlyphResolver`, `PromptGlyph`, `LastDeviceTracker`; Kenney Input Prompts logged in the attribution file |
| D-08 retune | Yes with a flagged reading | see the D-08 warning: the bar was pinned on the new army_balanced bot (8 of 10); the balanced bot sits at 9 of 10 |

Prohibitions (all judgment-tier or backstop; my reading is NON-AUTHORITATIVE and flagged `unverified-prohibition - human review recommended`, none is absorbed into the pass): no gold from kills (a search of `simulation/` finds no economy credit on `enemy_died`), the slam queues hits on enemies only, no `Input`, `InputEvent`, `Camera3D`, `Viewport` or `DisplayServer` under `simulation/` (grep: 0 hits, plus test_sim_rules_guard), no mouse build or king aim (the mouse only reaches `SelectionController`), the camera is not moved by commands (not read in code; covered by the owner decision D-13 and screenshot reads), no economy tuning in the 03-11 retune (the military data contract is green; the balance report states only night counts moved), CC0-only assets (the attribution test is green; I did not inspect licence texts). The seven backstop rows (UI-SPEC E1, E2, E3, E5, E6, E7, E9) were lifted into plan 03-12 and confirmed from screenshots by the executor, except E6 (see warnings and human item).

### Requirements Coverage

All 11 phase IDs appear in at least one plan `requirements:` field (plan 03-12 lists all 11) and REQUIREMENTS.md maps exactly these 11 to Phase 3 (traceability lines 191 to 248, each ticked Complete). No ID is orphaned; none is missing from a plan. INPT-03 stays open in REQUIREMENTS.md by design (menus, a later phase); it is not a Phase 3 ID.

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| UNIT-04 | 03-01, 03-02, 03-11, 03-12 | SATISFIED in code and tests | Truth 1 above |
| UNIT-05 | 03-06, 03-12 | SATISFIED | hold on H and pad D-pad down; `_begin` VERB_HOLD freezes the anchor at the living centroid (the post when nobody is alive) |
| UNIT-06 | 03-06, 03-12 | SATISFIED | follow on F / D-pad up; select_all (F2, R3) and select_type (double-click, LB+R3) give "all squads or one unit type"; the selection form is the default |
| UNIT-07 | 03-02, 03-05, 03-11, 03-12 | SATISFIED | `_trickle`, `restore_for_dawn`, `replacement_progress` drives the slot fill |
| UNIT-09 | 03-06, 03-08, 03-09, 03-12 | SATISFIED | click, box, Ctrl, double-click, Tab and pad cycling; groups Ctrl+digit store and digit recall; rings and highlighted slots with the group number |
| UNIT-10 | 03-07, 03-08, 03-09, 03-11, 03-12 | SATISFIED | move, rally, attack-move, patrol and Shift queue in `SquadSystem`; points from the mouse or the right-stick cursor through `GroundPick` and the gate; stances persist |
| KING-04 | 03-04, 03-10, 03-11, 03-12 | SATISFIED | Truth 3 |
| KING-05 | 03-04, 03-12 | SATISFIED in the simulation and on the HUD; WR-01 for the in-world bar | Truth 3 |
| INPT-01 | 03-06 to 03-09, 03-12 | SATISFIED in code; not played by a human | Truth 4 |
| INPT-02 | 03-09, 03-10, 03-12 | SATISFIED in code; synthetic pad events only | Truth 4 |
| UI-01 | 03-03, 03-04, 03-05, 03-10, 03-12 | SATISFIED in code and the runner check | Truth 5 |

REQUIREMENTS.md ticks reflect implementation, not the owner gate.

### Data-Flow Trace (Level 4)

FLOWING: `BuildingSystem` tier and `UnitDef` -> `SquadSystem._sync` (cap, respawn seconds) -> `UnitSystem` records -> `SquadStrip`/`SquadSlot.refresh` (alive_count, max_count, resting_stance, replacement_progress) and `UnitViews` puppets. `KingState` health and `ability_cooldown_ratio()` -> `KingWidget._sync_health/_sync_ability` (polled each frame). `RunManager.get_total_nights()` and the phase -> `DayCounter`. Selection lives in `SelectionModel` (input layer) -> `SquadOrderIntent` -> `CommandProcessor` -> `SquadSystem.apply_order`; the simulation never reads `Input`. One broken link: `KingState` regeneration -> `king_healed` -> nothing in presentation (WR-01), so the floating `HealthBar3D` is the only HOLLOW readout. No hardcoded empty data reaches the UI.

### Behavioral Spot-Checks and Replays

See "What I ran". Behavior-dependent truths (commit instead of swap, leash drop, stance persistence across dawn, selection steering, cooldown gating, dawn restore) each have a passing named test that exercises the transition, so none is left PRESENT_BEHAVIOR_UNVERIFIED (`behavior_unverified: 0`). What is not behaviorally verified is everything that needs a human or hardware: see Human Verification.

### Probe Execution

No `probe-*.sh` files are declared by the phase plans or exist under `scripts/`: SKIPPED.

### Anti-Patterns Found

None blocking. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in the 173 text files of the phase. The grep for empty stubs hits only intentional defaults. One real defect class: unbounded `while _living_count(squad) < squad.cap` loops over unvalidated data (CR-01, below). The review INFO items (dead patrol-budget assignment, duplicated ground-bounds rule and 35-line separate pass, test-only accessors, unused ext_resource lines) are non-blocking.

## Open code-review findings (all OPEN, none fixed)

| ID | Severity (review) | My weighing |
|---|---|---|
| CR-01 | critical | WARNING. Confirmed by reading `_fill`, `restore_for_dawn`, `UnitSystem.spawn` and `RunContext._init`. Hang and unbounded memory growth on a unit with `max_health <= 0`. Needs a hand-corrupted `.tres`; shipped data is safe; no roadmap truth depends on it. Must be fixed before release; reopens T-03-04 / T-03-05 |
| WR-01 | warning | WARNING. Confirmed (no `king_healed` consumer in `presentation/`). Two disagreeing health readouts mid-night |
| WR-02 | warning | WARNING. Confirmed by reading `tools/screenshot.sh` against `replay.sh`; CI can stay green over a HUD script error |
| WR-03 | warning | WARNING. Confirmed (no `command_rejected` consumer under `input/`, `presentation/`, `ui/`); refused queued orders are silent |
| IN-01 to IN-06 | info | INFO. Not re-derived one by one; they do not touch a success criterion |

## Human Verification Required

The structured list is in the frontmatter (15 entries: one per `human_judgment: true` item in the twelve SUMMARYs, the E6 toast, the two UI-REVIEW legibility fixes and the owner gate itself). The orchestrator turns them into 03-UAT.md one to one. The decisive entry is the owner gate in 03-PLAYTEST-GATE.md: two or three full runs with an army on both devices, then sign off or name fixes, recorded through `/gsd-verify-work`. E6 (the 526 px toast) is a human item, not a failure, as agreed.

## Gaps Summary

No gaps and no blockers: all five roadmap success criteria are implemented, wired and tested, the replays are byte-identical to their goldens, lint is clean and the 1373-test suite was green at the last code change. The status is `human_needed` because the feel clauses of the criteria and the owner playtest gate have not happened, and because ten open review findings (one critical, three warnings) are waiting for a review-fix pass. Do not treat the 1373 green tests, the replay digests, the balance table, the screenshot review or this report as the sign-off, and do not start Phase 4 before the owner decides. Suggested order: run the review-fix pass (CR-01 first, then WR-01, WR-03, WR-02, then the info items), then the owner UAT. If the fix pass changes any file under the covered list, re-run `verification.status` to refresh the fingerprint.

---

_Verified: 2026-10-12T09:16:48Z
_Verifier: Claude (gsd-verifier)_
