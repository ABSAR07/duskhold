---
phase: 05-castle-center-economy-depth
verified: 2026-10-22T10:20:15Z
status: human_needed
score: "4/4 roadmap success criteria verified in code, tests and replays; 108/111 plan truths verified, 0 failed, 3 insufficient_spec (05-12's three owner-judgement truths, backstop tier); 9/9 requirement IDs have implementation evidence (BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08, UI-02 satisfied); 10 owner-judgement items remain, 0 gaps"
must_haves:
  roadmap_truths: 4
  roadmap_truths_verified: 4
  roadmap_truths_failed: 0
  plan_truths_declared: 111
  plan_truths_declared_note: "108 quoted truths in plans 05-01 to 05-12 (10, 12, 8, 7, 9, 13, 8, 12, 12, 6, 8, 3) plus the three `verification: backstop` statements of 05-12 (the owner judges the cards, the twelve abilities, and that the day is deeper and still fun)"
  plan_truths_verified: 108
  plan_truths_failed: 0
  plan_truths_insufficient_spec: 3
  plan_artifacts_checked: "53/53 by gsd-tools verify artifacts over all 12 plans (6, 7, 5, 6, 3, 5, 3, 4, 5, 4, 4, 1), re-run by me; no tool miss"
  plan_key_links_checked: "32/32 by gsd-tools verify key-links over all 12 plans (4, 5, 2, 3, 3, 3, 2, 2, 3, 2, 2, 1), re-run by me; no tool miss"
  prohibitions_declared: 22
  prohibitions_note: "judgment-tier, non-authoritative reading, flagged unverified-prohibition - human review recommended; never absorbed into the pass. 2, 3, 2, 2, 1, 2, 1, 2, 2, 2, 2, 1 across plans 05-01 to 05-12. My reading found no violation; the process prohibitions (no push or gh outside the named task) cannot be verified from the tree and are taken from the SUMMARYs and the CI record. Details in the Plan must_haves section"
  requirement_ids: 9
  requirement_ids_satisfied: 9
  requirement_ids_failed: 0
  requirement_ids_orphaned: 0
covered_files:
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
  - .planning/phases/05-castle-center-economy-depth/05-BALANCE-REPORT.md
  - .planning/phases/05-castle-center-economy-depth/05-CONTEXT.md
  - .planning/phases/05-castle-center-economy-depth/05-DISCUSSION-LOG.md
  - .planning/phases/05-castle-center-economy-depth/05-PATTERNS.md
  - .planning/phases/05-castle-center-economy-depth/05-PLAYTEST-GATE.md
  - .planning/phases/05-castle-center-economy-depth/05-RESEARCH.md
  - .planning/phases/05-castle-center-economy-depth/05-REVIEW-DISPOSITION.md
  - .planning/phases/05-castle-center-economy-depth/05-REVIEW.md
  - .planning/phases/05-castle-center-economy-depth/05-SECURITY.md
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
  - data/maps/prototype_map.tres
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
  - tests/e2e/test_mill_fields_scene.gd
  - tests/e2e/test_rebuilt_economy_marker.gd
  - tests/e2e/test_shrine_look.gd
  - tests/e2e/test_shrine_scene.gd
  - tests/e2e/test_spot_label.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/e2e/test_wall_views.gd
  - tests/fixtures/fixture_map_castle.tres
  - tests/fixtures/fixture_map_gate.tres
  - tests/fixtures/fixture_map_replay_economy.tres
  - tests/fixtures/fixture_map_shrine.tres
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
  - tests/integration/test_stat_tracer.gd
  - tests/integration/test_upgrade_flow.gd
  - tests/support/sim_signals.gd
  - tests/unit/test_ability_data.gd
  - tests/unit/test_bot_card_picks.gd
  - tests/unit/test_bot_defers_locked.gd
  - tests/unit/test_build_choice.gd
  - tests/unit/test_build_requirement_validation.gd
  - tests/unit/test_build_requirements.gd
  - tests/unit/test_build_spot.gd
  - tests/unit/test_card_icons.gd
  - tests/unit/test_card_row_model.gd
  - tests/unit/test_castle_data_contract.gd
  - tests/unit/test_castle_label.gd
  - tests/unit/test_castle_tiers.gd
  - tests/unit/test_choice_validation.gd
  - tests/unit/test_dawn_rebuild.gd
  - tests/unit/test_debug_overlay_night_sections.gd
  - tests/unit/test_economy_data_contract.gd
  - tests/unit/test_economy_overlay_sections.gd
  - tests/unit/test_economy_validation.gd
  - tests/unit/test_fishing_harbor.gd
  - tests/unit/test_gate_data_contract.gd
  - tests/unit/test_gold_mine.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_mill_fields.gd
  - tests/unit/test_nav_layout_pin.gd
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_playtest_strategies_castle.gd
  - tests/unit/test_pond_layout.gd
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_prototype_map_economy.gd
  - tests/unit/test_prototype_map_walls.gd
  - tests/unit/test_replay_cli_args.gd
  - tests/unit/test_shot_list.gd
  - tests/unit/test_shot_list_gate.gd
  - tests/unit/test_shrine.gd
  - tests/unit/test_shrine_plots.gd
  - tests/unit/test_shrine_synergy.gd
  - tests/unit/test_shrine_validation.gd
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spot_label_locked.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_stat_combined.gd
  - tests/unit/test_stat_consumers.gd
  - tests/unit/test_stat_contract.gd
  - tests/unit/test_stat_refresh.gd
  - tests/unit/test_stat_stack.gd
  - tests/unit/test_structure_decision_pins.gd
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
  - ui/hud/dawn_no_income_marker.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
  - ui/overlay/economy_overlay_sections.gd
  - ui/overlay/stat_overlay_sections.gd
  - ui/world/card_row.gd
  - ui/world/card_row_model.gd
  - ui/world/spot_label.gd
  - ui/world/spot_label.tscn
  - ui/world/spot_label_model.gd
covered_digest: "v2:sha256:fc3df99ef89d66c14583f07788cad8bbc7a1dac0be76f51f917b11e266ad78cf"
behavior_unverified: 0
overrides_applied: 0
behavior_unverified_items: []
human_verification:
  - name: "The cards read clearly in world space and picking by key and by mouse feels right (UI-02, BLDG-05)"
    requirement: "UI-02, BLDG-05"
    test: "Play a run on build/windows/Duskhold.exe (instructions in 05-PLAYTEST-GATE.md, 'How to play'). Ride to the castle by day with 6 or more gold; four cards stand above the keep. Highlight each with keys 1 to 4, then with the mouse (hover, then click), and hold the action key to buy"
    expected: "Icon, name and flavour read from the riding camera; the pointed-at card rises and shows its yellow effect line; a click highlights and never buys; the hold buys the highlighted card and the pick is locked for the run; digits 1 to 4 pick cards while they show and recall control groups again after you ride away"
    why_human: "Legibility from the real camera and the feel of picking are perceptual. The mechanics are pinned (test_card_row 12/12, test_card_mouse 12/12, test_card_digit_handover 6/6 in the full run) and I read castle_cards.png, but whether the row reads well is the owner's call"
  - name: "The twelve abilities are distinct and worth a pick (BLDG-08)"
    requirement: "BLDG-08"
    test: "Over two or three runs take different cards at tiers II, III and IV (Royal Training, Commander, Masons, Prosperity; Headsman's Edge, Engineers, War Horns, Warded Mail; Iron Discipline, Arrow Storm, Master Builders, Golden Age) and read the Stats section of the F3 overlay"
    expected: "Each card's effect is felt and no card is one you would never take or always take; or the owner names cards to rename, rebalance or replace (the numbers are data plus one contract test each)"
    why_human: "Backstop-tier truth (05-12, D-02: the owner judges the set at the UAT). The data, the numbers line generated from the modifiers, the stack and the pick-order invariance are tested (test_ability_data 15/15, test_stat_combined, test_build_choice in the full run); whether a card is worth its pick is design taste"
  - name: "The castle gate reads as a trade-off, not a wall (BLDG-09)"
    requirement: "BLDG-09"
    test: "Ride to a Tower, House, Barracks, Archery Range or Wall plot at its second-to-last tier before the castle is at tier II, read 'Needs Castle II', hold, then buy castle II (6 gold) and return"
    expected: "The label reads as a choice to make (castle first or more defences first), the hold gives the denied bump and spends nothing, and the tier unlocks the moment castle II stands; or the owner softens the gate (fewer gated tiers or a lower gate)"
    why_human: "The gate is pinned (test_build_requirements 15/15, test_gate_data_contract, test_castle_gate e2e; seven shipped top tiers carry requires_castle_tier = 2, read by me in data/buildings) and the bots lose the castle-less build (balanced_no_castle 3 of 10); whether it feels like a trade-off or an obstacle is the owner's judgement"
  - name: "Each new building reads and is worth its gold (ECON-03, ECON-04, ECON-05, ECON-06)"
    requirement: "ECON-03, ECON-04, ECON-05, ECON-06"
    test: "In a run build the Gold Mine at (-30, 30), the Mill at (30, 28) and one Field, the Fishing Harbor on the pond's shore at (0, 20.5) and a Shrine at (-46, 30) or (46, 30); read each label before buying and watch the dawn payouts across several days (F3 Economy section shows the next payout)"
    expected: "The Mine's falling payout (3, 2, 1, 1), the Fields' 'Needs a Mill' lock, the Harbor's boat per dawn up to its cap and the Shrine's wake are readable before purchase and each building feels worth its price; none feels pointless or too strong"
    why_human: "The payout curves, the lock, the boats and the wake rule are pinned by unit, integration and e2e tests and the economy golden (all green in my full run), but worth and readability are judgements; the bots only measure"
  - name: "The day's decisions feel deeper and the game is still fun (core value)"
    requirement: "BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06"
    test: "Play two or three full runs climbing the castle with picks and building the new economy (05-PLAYTEST-GATE.md, 'What to judge' 5)"
    expected: "The day offers richer gold trade-offs (castle versus defences versus income) without being merely busier, and the night defence stays tense"
    why_human: "Backstop-tier truth (05-12): fun and depth cannot be measured. The bots measured: balanced (castle-aware) wins 8 of 10, army_balanced 8 of 10 (value ratio 0.888 against the 0.8 bar), balanced_no_castle 3 of 10, greedy_economy 0 and no_build 0 (05-BALANCE-REPORT.md, not re-run by me)"
  - name: "Three presentation points: night banner over a raised card, cropped tier IV roof, small buildings in economy_day"
    requirement: "UI-02, BLDG-08"
    test: "Open castle_cards.png, castle_tier_four.png and economy_day.png (screenshots/ or the CI artifacts) and look in the exported build: the 'Night 1 of 8' banner over the raised card, the tier IV keep's roof tip and flag at the default zoom, the Mine and the Mill from the far camera"
    expected: "Rule on each: fix now (a presentation offset on the card row, a camera or model tweak, larger models) or wait for Phase 8 (Art, Readability and Sound)"
    why_human: "Pure look. I read castle_cards.png (the banner text sits over the top of the raised card, legible but untidy) and economy_day.png (the Mine and the Mill are small at the far camera), matching the packet's open points 1 and 3; the owner decides"
  - name: "The economy mix and the Shrine's wake rule (ECON-03, ECON-05, ECON-06)"
    requirement: "ECON-03, ECON-05, ECON-06"
    test: "Compare what the Harbor, the Mine, the Mill and the Fields pay across a run, and watch whether a Shrine wakes and fires in play (packet 'Open points' 4 and 5)"
    expected: "The owner decides whether the Harbor should be weaker or the Mine, Mill and Fields stronger, and whether the Shrine needs a nearer plot, a longer reach, a lower threshold or a different wake rule. The bot sweep: the Shrine wakes in a minority of seeds and almost never fires; the Harbor dominates income"
    why_human: "A balance call the bots flagged and the plans deliberately did not change (D-12 fixes the shapes, the numbers are free). The Shrine's rules are proven on fixtures and in the economy golden (test_shrine_night, test_shrine_destroyed, test_shrine_synergy); how often it matters on the shipped map is the owner's decision"
  - name: "How far the castle ladder should reach (BLDG-08)"
    requirement: "BLDG-08"
    test: "Note how often a run affords castle III (10 gold) and IV (16 gold) and whether the army build can afford the castle at all (packet 'Open points' 6)"
    expected: "Keep tiers III and IV as late-game goals, or lower their costs or raise income so they happen mid-run; and whether the army build should be able to afford the castle"
    why_human: "Costs and income are data and the bots cannot reach tiers III and IV (about 30 gold a run) or afford the castle on the army build; whether that reads as a goal or a dead end is a feel call"
  - name: "The card row's dismiss and pre-highlight (UI-02)"
    requirement: "UI-02"
    test: "Ride past the castle repeatedly with enough gold; try buying with no highlight (denied bump) and then with a highlight"
    expected: "Rule whether cards re-appearing on every pass needs a dismiss, and whether the first card should be pre-highlighted (research A7 and A10 chose neither: no highlight means the hold is refused with choice_required and the denied bump)"
    why_human: "A UX call: both behaviours are pinned (test_card_row, test_castle_gate) and neither was chosen by the owner yet"
  - name: "The exported build and the owner's packet hand-off"
    requirement: "UI-02, BLDG-08, ECON-03, ECON-06"
    test: "Launch build/windows/Duskhold.exe (Duskhold.pck and libduskhold_sim.windows.x86_64.dll beside it, dated 2026-10-22) on the owner's machine and open 05-PLAYTEST-GATE.md (23 assumptions, 7 open points, 5 decisions)"
    expected: "The build launches and plays a full run, and the packet's numbers (balanced 8 of 10, army 8 of 10, ratio 0.888, goldens, 44 shots) match 05-BALANCE-REPORT.md and 05-12-SUMMARY.md; the owner signs off or lists what must land before Phase 6 through /gsd-verify-work 5"
    why_human: "A hand-off: the export files exist (listed by me, dated 2026-10-22 13:57 local) and the executor and orchestrator launch-checked it, but the launch on the owner's machine is the check and I did not launch it"
---

# Phase 5: Castle Center & Economy Depth Verification Report

**Phase Goal:** Day decisions gain real depth. The castle center grows through tiers with run-defining ability picks that gate higher building tiers, and four new economic buildings each pay out on a different income curve. All bonuses stack in one tested order.
**Verified:** 2026-10-22T10:20:15Z
**Status:** human_needed
**Re-verification:** No, initial verification (no earlier 05-VERIFICATION.md existed). Every number and verdict describes HEAD cb1389a; nothing outside `.planning/` changed since 570ff8d (plan 05-12's CI comment commit), and no native file or Phase 2 to 4 golden or replay fixture changed in the whole phase.

## Verdict

The phase goal is achieved in the codebase and by measurement, and what remains is the owner's judgement. The castle is a tiered plot (health 70, 100, 140, 200; arrow and dawn income per tier), the three upgrade tiers each offer four cards that arrive as one `BuildIntent` carrying `choice_id` and are locked by `ChoiceLedger` into the one `StatStack`; the seven shipped top tiers (House III, Tower II, Barracks III, Archery Range III, Wall III, Mill III, Harbor II) need castle II and are refused at the build gate with the denied bump; the Gold Mine, Mill with three locked Fields, Fishing Harbor and Shrines pay out on four different curves through the one `IncomeState` and the one dawn payout; and every modifiable stat is read through `StatStack` under the documented order in `docs/STAT_MODIFIERS.md`, pinned by single-modifier and combined-modifier tests. I re-ran what is cheap and the full suite once.

Status follows the decision tree: no truth FAILED, no artifact missing or stubbed, no key link unwired, no blocker anti-pattern (rule 1 does not fire). Step 8 produced ten owner-judgement items (the cards by key and mouse, the twelve abilities, the castle gate, each new building, depth and fun, three presentation points, the economy mix and the Shrine's wake rule, the castle ladder's reach, the card row's dismiss and pre-highlight, the export hand-off); three of them are the `backstop` truths of plan 05-12 that I abstain on (`insufficient_spec`). Rule 2 fires: `human_needed`, 0 gaps. The owner's gate (05-12 Task 3) has not been run: no 05-UAT.md exists.

ROADMAP marks Phase 5 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form (`user-story.validate` answers false, the same as Phases 2 to 4, which carry the same marker), so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

| Check | Command or read | Result |
|---|---|---|
| Plan artifacts and key links | `gsd-tools verify artifacts` and `verify key-links` on all 12 plans | 53/53 artifacts, 32/32 links; no miss to explain |
| Golden smoke, twice | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK ... ticks=703 digest=2599c7c2...` |
| Golden army, twice | same with army | `REPLAY_OK ... ticks=1353 digest=f7a967ed...` |
| Golden walls, twice | same with walls | `REPLAY_OK ... ticks=1961 digest=bfb05fc7...` |
| Golden economy, twice (new, 05-10) | same with economy | `REPLAY_OK ... outcome=won ticks=1842 digest=f4b98093...` |
| full_idle, twice (unpinned by design) | `bash tools/replay.sh --scenario=full_idle --twice` | `REPLAY_OK ... outcome=won ticks=7000 digest=afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14`, exactly the 'after' value recorded in 05-BALANCE-REPORT.md |
| Gate stress, twice | `bash tools/gate_stress.sh --twice` | `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdb...`, unchanged from Phase 4 |
| Goldens untouched | `git log -- tests/golden`; `git diff --name-only fab9485~1 HEAD -- tests/golden tests/fixtures native simulation/night/enemy_system.gd` | the only phase commit under tests/golden is 061e51b (economy.json, new); no smoke, army or walls golden, no Phase 2 to 4 replay fixture and no native file or enemy step changed; the four new fixtures are castle, gate, economy and shrine |
| Full suite, once | `bash tools/test.sh` (my `-gtest=` list was ignored by `.gutconfig.json`, so it ran everything, my one full run) | 279 scripts, 2653 tests, 2653 passing, 60396 asserts, 892 s, exit 0 (the same 279 and 2653 as the orchestrator's wave-11 gate; the assert count varies by a few hundred between runs) |
| Lint | `bash tools/lint.sh` | `446 files would be left unchanged`, `Success: no problems found` |
| Debt markers | grep TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER over every non-`.md` file the phase changed (195 text files from `git diff --name-only fab9485~1 HEAD`) | none |
| Covered-files completeness | `comm` of the 195 changed text files against the covered list | none missing; 35 are `.planning/` phase documents |
| CI wiring | read `.github/workflows/ci.yml` | `contents: read` (line 26); `replay.sh --scenario=economy --twice --expect-file=tests/golden/economy.json` at lines 160 (Linux test job) and 219 (Windows native job) |
| Shot list | read `tests/unit/test_shot_list.gd` | `EXPECTED_SHOT_COUNT = 44`; the seven phase shots castle_cards, castle_tier_four, field_locked, harbor_pond, shrine_awake_night, castle_gate_locked, economy_day are listed |
| Screenshots | read `screenshots/castle_cards.png` and `screenshots/economy_day.png` | the four cards (key tile, icon, name, flavour; card 2 raised with its yellow numbers line) above 'Castle II' with its label; the south side with the Mine, Mill, two Fields, the pond with two boats and a Shrine |
| Export on disk | `ls -la build/windows` | Duskhold.exe, Duskhold.pck, libduskhold_sim.windows.x86_64.dll (not launched by me) |

Taken from the orchestrator or the committed evidence without re-running, and marked as such: CI run 39751537305 (https://github.com/ABSAR07/duskhold/actions/runs/39751537305), green on 570ff8d for lint, test, native-linux, native-windows, export and screenshots with REPLAY_OK for smoke, army, walls, economy and full_idle and GATE_OK on Linux and on the Windows library (I may not run `gh`); the 44 screenshots and the per-PNG review of 05-12 (I read two); the playtest sweep (`bash tools/playtest.sh --seeds=10`, 100 runs, about seven minutes, not re-run); the regression gate (164 of the 166 prior-phase test script names exist and ran green in the full run; the other two names are false suffix matches of tool scripts).

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | At a branching upgrade tier, the player picks one of the offered choice cards (icon, name, short description) with keyboard or mouse. The choice stays locked for the rest of the run | VERIFIED in code and tests; the read and the feel are owner items | `CardPicker` (`input/card_picker.gd`): keys 1 to 4 via `DIGIT_ACTIONS`, mouse hover and left click via `_input` with `CardRowModel.hit_test`, a click consumed only on a card, highlight frozen while a hold runs; `CommandKeyController` hands digits over while `is_showing()`. `CommandProcessor.validate_build` answers CHOICE_REQUIRED and BAD_CHOICE; `_submit_build` emits `building_built` then `choice_picked`; `ChoiceLedger._on_choice_picked` adds the card as a named stack source and appends the pick (nothing removes it). Each card carries icon, name, flavour and a numbers line generated from its modifiers; twelve first-party CC0 SVGs logged in ASSETS.md (line 90). Tests green in the full run: test_card_row 12, test_card_mouse 12, test_card_digit_handover 6, test_build_choice 18, test_card_row_model, test_card_icons. `castle_cards.png` shows it |
| 2 | The player can upgrade the castle center through its tiers for more health, choosing one of four run-wide abilities or passives at each tier. Higher building tiers stay locked until the castle reaches the required tier | VERIFIED | `data/buildings/castle_center.tres`: four tiers, max health 70 (map) then 100, 140, 200, arrow damage 3, 4, 5, dawn income 2, 3, 4, tiers II to IV each with four `choices` (0, 4, 4, 4 pinned by test_ability_data); twelve distinct ids, each a `.tres` of stat modifiers. `BuildRequirements.rejection` returns CASTLE_TIER when `next_tier.requires_castle_tier` exceeds the castle's tier, ordered after MAX_TIER and before CANNOT_AFFORD; the seven shipped top tiers carry `requires_castle_tier = 2` (house, tower, barracks, archery_range, wall, mill, fishing_harbor `.tres`) and no other; the label reads 'Needs Castle II' (test_spot_label_locked, test_castle_gate). Bots: balanced wins 8 of 10 with the castle first bought on day 6 at the earliest (D-01) |
| 3 | The player can build four new economic buildings: a Gold Mine (high income that drops each night), a Mill (opens nearby Field spots that each pay a flat income), a Fishing Harbor (gains a paying boat each night up to an upgradeable cap), a Shrine (activates after enough nearby enemy deaths, then attacks, pays and strengthens other active Shrines) | VERIFIED | `IncomeState` (230 lines) pays every non-FLAT curve: DECLINING `maxi(income_floor, dawn_income - income_step * paid)` (data: 3, step 1, floor 1; pinned 3, 2, 1, 1, 1 by test_gold_mine), BOATS one boat per standing dawn to `boat_cap` 3 then 5 at 1 gold per boat (test_fishing_harbor), AWAKENED wake by kill credit within `wake_radius` 18 reaching `wake_threshold_hp` 100 with `shrine_woke` once and the `shrine_synergy` PERCENT source on `shrine.damage` replaced whenever the awake count changes (test_shrine, test_shrine_synergy). The Mill (`mill.tres` three tiers paying 1, 2, 3) and three Fields (`requires_spot = &"mill_1"`, tier 1, prototype_map.tres lines 169 to 186; Field pays 1) with the lock tested (test_mill_fields 11). The Shrine fires in the existing towers slot of the night step: `TowerSystem.step` skips an AWAKENED spot unless `_income.is_awake(spot)` (tower_system.gd lines 43 to 44 and 88 to 93) and reads `shrine.damage` and `shrine.range` through the stack (lines 54 and 68). A destroyed building loses nothing it accumulated and skips only that dawn (test_economy_destroyed 5, test_shrine_destroyed 8). The prototype map has 23 spots (castle plot and 22 buildable). `economy_day.png` shows all four |
| 4 | Bonuses from building upgrades and castle abilities combine in one fixed, documented order. Automated tests verify single-modifier and combined-modifier cases | VERIFIED | `docs/STAT_MODIFIERS.md` (113 lines: Formula, Buckets and units, Rounding, Sources, Registry, Limits) and the same formula line heads `simulation/stats/stat_stack.gd`: `final = (base + sum(flat)) * (1 + sum(percent) / 100) * product(multiplier / 100)`, integers computed as one exact fraction and rounded once, half up (`_int_from`, lines 168 to 178), floats on `+ - * /` only. Every modifiable stat is read through `int_value` or `float_value` at the point it was read (king, unit, squad respawn, building, wall, tower, shrine, castle: my grep lists each consumer in `simulation/`); the diff of simulation, presentation, ui and input contains no ad hoc bonus (`*=` or percent arithmetic) outside the stack. test_stat_stack, test_stat_combined (12 cases including pickup-order permutations and a Shrine synergy replacement), test_stat_contract (fails if the doc loses the formula or the rounding sentence), test_stat_consumers and test_stat_refresh green in the full run |

### Plan must_haves

111 plan truths and 22 prohibitions are declared across the 12 plans. I verified them against code, tests, replays and the full run rather than against the SUMMARYs. Every state-transition and ordering truth is backed by a named test that passed in my full run, so none is left PRESENT_BEHAVIOR_UNVERIFIED:

- **05-01 (META-08), 10 of 10.** The stack, its buckets, one half-up rounding with the clamps (base 3 with +50% is 5, base 10 with +2 flat, +50% and x2 is 36), the limits (`MAX_ABS_BASE` 100000, at most 4 multipliers, percent sum -90..1000), `docs/STAT_MODIFIERS.md`, every consumer through the stack with identity values (smoke, army and walls byte-identical, full_idle at the time 4385f569), a max-health change raising current health by the gain only (`previous_int_value` in king, unit, building, wall and castle code; test_stat_refresh), the Stats overlay rows (`stat_overlay_sections.gd`).
- **05-02 (BLDG-08, BLDG-05, UI-02), 12 of 12.** Castle plot as spot 15 (`is_castle = true`, prototype_map.tres line 150, the first 14 plots unmoved, nav layout pin passing), `CardPicker` modal digit rule with `CommandKeyController`, the highlight frozen during a hold, `choice_picked` after `building_built` and in the digest (test_build_choice `test_building_built_comes_before_choice_picked`, `test_the_pick_is_one_line_of_the_replay_digest`), no pad bindings or prompts (diff of `input/` and `ui/` has no joypad or gamepad addition).
- **05-03 (cards, label, validation), 8 of 8.** Twelve unique card ids and four different stat sets per tier (test_ability_data), numbers line generated from the modifiers (`effect_line`), label naming the next tier and the picks, `ChoiceValidation` and `CastleValidation` wired into `MapConfig.validate()`, the shipped map validating clean, a card never named after a Thronefall perk (`test_no_card_is_named_after_a_draft_name_that_echoes_a_thronefall_perk`; the draft names Assassin's Training, Rallying Banner and Magic Armor became Headsman's Edge, War Horns and Warded Mail, and the reflect effect became a 25% damage-taken reduction).
- **05-04 (mouse, icons, keep look), 7 of 7.** Hover and consumed click (test_card_mouse), `hit_test` edge rule (lower index), twelve SVG icons plus key tiles, `castle_center_t2/t3/t4.tscn` swapped by `BuildingViews` through the catalog, shot list 37 to 39 (here 44 after 05-11).
- **05-05 (BLDG-09), 9 of 9.** `BuildRequirements` with the order NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CASTLE_TIER or NEEDS_SPOT, CANNOT_AFFORD, CHOICE_REQUIRED, BAD_CHOICE (read at command_processor.gd lines 75 to 90), spot requirement on the first build only (a destroyed Mill never relocks a Field: `test_a_destroyed_required_plot_does_not_relock_a_built_plot`), requirement validation incl. cycles, the bots' defer-on-locked rule (`test_bot_defers_locked`), no castle gate on a map without a castle plot.
- **05-06 (ECON-03), 13 of 13.** `IncomeCurve` data, `IncomeState` as the only non-FLAT payer, one `dawn_payout` with the castle key last, the rebuilt Mine paying nothing and not advancing, the crossed-coin marker, `EconomyValidation`, the Economy overlay, gold_mine_1 as index 15 on the 16-spot step.
- **05-07 (ECON-04), 8 of 8.** Mill three tiers 1/2/3, Mill III gated at castle II, three Fields locked until the Mill stands and independent afterwards (test_field_independence), the plot-distance rules, the `field_locked` shot.
- **05-08 (ECON-05), 12 of 12.** One boat per surviving dawn to the cap, `harbor_boats_changed` only on change (`test_the_event_is_emitted_for_each_new_count_and_never_at_the_cap`), boats kept on rebuild and upgrade, the pond visual only (`PondView`, `MapConfig.pond_center` and `pond_radius`, test_pond_layout; the gate stress digest e448ffdb is unchanged by me today), pond and boat validation.
- **05-09 (ECON-06), 12 of 12.** Wake by kill credit at exactly the radius and exactly the threshold (`test_a_death_exactly_at_the_wake_radius_counts`, `test_a_credit_exactly_equal_to_the_threshold_wakes_the_shrine`), dormant never fires, one `shrine_woke`, synergy source replaced not appended (`test_repeated_deaths_and_wakes_never_pile_the_source_up`), destroyed Shrine keeps credit and awake state, validation, two Shrine plots (indices 21 and 22), `shrine_awake_night` shot. No native file changed in the phase (`git diff --name-only fab9485~1 HEAD -- native` is empty), so the Shrine never touches the native enemy step.
- **05-10 (economy golden), 6 of 6.** `tests/golden/economy.json` on `fixture_map_replay_economy.tres` (no `res://data` reference, grep empty), twice-agree and the family coverage in test_economy_replay_golden, D-14 across all five buildings in one night (test_economy_destroyed), the CI lines (read), `PlaytestBot` card picks skipping an unoffered pick (test_bot_card_picks); smoke, army and walls untouched (re-run by me).
- **05-11 (castle-aware bots, balance), 8 of 8.** `balanced_no_castle` and `army_balanced_no_castle` twins, the D-03 gate on the seven shipped top tiers (test_gate_data_contract), the first castle upgrade costing 6 against 4 starting gold plus 1 base income (`starting_gold = 4`, `base_dawn_income = 1`, prototype_map.tres lines 496 and 497) so never a day-1 buy, 05-BALANCE-REPORT.md with the full_idle before (6911, 4385f569...) and after (7000, afc11cd0...; my replay reproduces it) and the statement that smoke, army and walls were never regenerated, test_balance_acceptance re-pinned, 44 shots. The sweep numbers (balanced 8 of 10, army_balanced 8 of 10 at ratio 0.888, castle first bought on day 6) are the report's and are not re-run by me.
- **05-12 (phase gate), 3 of 3 verified and 3 insufficient_spec.** The local pass (my replays, gate stress, full suite and lint match its claims), the CI and launch-checked export and the packet (05-PLAYTEST-GATE.md has the six headings, 23 assumptions, 7 open points and 5 decisions) are verified from the files and the carried CI record. The three `backstop` truths (the cards read and pick well, the twelve abilities are worth a pick, the day is deeper and still fun) are abstained on: no wired test can stand in for the owner, so each is a human_verification entry (1, 2 and 5).

Prohibitions (all judgment-tier; my reading is NON-AUTHORITATIVE and each is flagged `unverified-prohibition - human review recommended`; none is absorbed into the pass): I found no violation of the 22. Reads that cite the tree: no bonus applied outside the stack and no per-bucket rounding (the diff grep above; `_int_from` rounds once); no gold spent or modifier armed by a highlight and a click buys nothing (`CardPicker` only calls `set_highlight`, test_card_mouse `test_holding_the_action_key_buys_the_clicked_card`); a locked pick never changes (`ChoiceLedger` has no removal); no pad work (diff grep); card names original (the contract test) and the numbers lines generated, not written by hand; icons first-party CC0 and logged; a mouse click never buys; a locked tier or plot spends nothing (`test_submitting_the_gated_tier_announces_it_and_spends_nothing`, `test_submitting_a_locked_plot_announces_needs_spot_and_spends_nothing`); a Mine never pays 0 (`_amount` takes `maxi(income_floor, ...)`); a destroyed economic building loses nothing (test_economy_destroyed `test_what_each_building_built_up_survives_the_fall`); the pond is not in the nav grid (nav layout pin passes, gate digest unchanged); the Shrine never goes dormant again (`_awake` is never cleared); no smoke, army or walls re-pin and no economy fixture reference to `data/`; no night count moved (BALANCE-REPORT 'Numbers fitted': only the gate and the bot orders moved). The process prohibitions (no push or `gh` outside the named task, 05-12's 'do not ask the owner to verify what a script can check') cannot be verified from the tree; the packet lists only feel items and the SUMMARYs record no other push.

Decision check against 05-CONTEXT.md: D-01 (four tiers, three picks, first upgrade a real trade-off) honoured and measured (day 6); D-02 (twelve abilities, original names, stat modifiers only) honoured; D-03 (one gate on every top tier, authored per tier, impossible requirements reported) honoured; D-04 (castle tiers raise health, arrow and income) honoured; D-05 to D-07 (approach, pick, then hold; a row of four cards in world space; icon, name, flavour, numbers on highlight) honoured; D-09 to D-11 (eight plots, Fields locked behind the Mill, visual-only pond) honoured; D-12 to D-14 (curve shapes, Mill and Field rule, destroyed buildings lose nothing) honoured; D-15 (one stacking order, built first) honoured. **D-08 is honoured in intent but not in letter, by design:** the context asked for smoke, army, full_idle and walls to be regenerated once; research P1 found that the three fixture goldens carry inline copies of every def and cannot move, so none was regenerated, economy is the one new golden and full_idle (unpinned) moved once and is reported before and after. The stop rule never fired. This is better than the decision and recorded in 05-BALANCE-REPORT.md, so it is not a gap.

### Key Link Verification

32 of 32 links from the 12 plans' `key_links` are verified by `gsd-tools verify key-links`. The ones that carry the phase:

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `CommandProcessor._submit_build` | `SimEvents.choice_picked` | emitted after `apply_next_tier` | WIRED | command_processor.gd line 263 |
| `ChoiceLedger` | `StatStack` | `add_source(choice_id, card.modifiers)` on `choice_picked` | WIRED | choice_ledger.gd, `_on_choice_picked` |
| `CommandProcessor.validate_build` | `BuildRequirements.rejection` | after MAX_TIER, before the price | WIRED | command_processor.gd lines 83 to 86 |
| `RunManager._apply_dawn_payout` | `IncomeState.dawn_payouts()` | merged into `per_spot` with the castle key last | WIRED | run_manager.gd lines 209 to 218 |
| `TowerSystem.step` | `IncomeState.is_awake` and the stack | AWAKENED spots skipped while dormant; damage and range read through the stack | WIRED | tower_system.gd lines 43, 54, 68, 88 to 93 |
| `IncomeState` | `StatStack` | `shrine_synergy` PERCENT source replaced on a count change | WIRED | income_state.gd `_refresh_synergy` |
| `IncomeState` | `SimEvents.harbor_boats_changed` and `shrine_woke` | emitted on change and once | WIRED | income_state.gd `_pay_boats` and `_on_enemy_died` |
| `CardPicker` and `CommandKeyController` | each other | digits 1 to 4 skip the control-group call while the cards show | WIRED | command_key_controller.gd line 138 |
| `MapConfig.validate()` | choice, castle, requirement, economy and shrine validators | appended problems | WIRED | test_choice_validation, test_build_requirement_validation, test_economy_validation, test_shrine_validation |
| `tools/replay/replay_scenarios.gd` | `fixture_map_replay_economy.tres` and `.github/workflows/ci.yml` | `_run_economy`; two CI replay lines | WIRED | my replay run; ci.yml lines 160 and 219 |
| `tools/screenshot/shot_scenarios.gd` | `shot_economy_scenarios.gd` | handles, map_for and run dispatch for the seven shots | WIRED | test_shot_list 44 entries |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Castle label and card numbers line | next tier health, arrow and income; each card's effect text | `stack.int_value(&"castle.max_health", tier.max_health)` and so on (spot_label_model.gd lines 111 to 113); `ChoiceDef.effect_line()` from the card's own modifiers | yes, the same stack the simulation reads; `castle_cards.png` reads 'Health 100 - Arrow 3 - 2 gold at dawn' and '+25% unit health, +25% unit damage' | FLOWING |
| Dawn payout and the Economy overlay | per-plot payouts, next payout, boats, awake state | `IncomeState.dawn_payouts()`, `next_payout`, `boats_of`, `is_awake` | yes, fed by `BuildingSystem` getters and the `enemy_died` signal | FLOWING |
| Boat views | boat count per Harbor | `harbor_boats_changed(spot_id, boats)` into `PondView` | yes, emitted only by `IncomeState` on a changed count; `economy_day.png` shows two boats | FLOWING |
| Stats overlay rows | base and final value of each modified stat | `StatOverlaySections.stat_rows` over `ctx.stat_stack` | yes (test_stat_tracer) | FLOWING |
| Castle health, arrow and base income | max health, arrow damage and range, base income | `CastleState` reading `MapConfig` fields at tier I and tier data afterwards, through the stack | yes (test_castle_tiers, test_dawn_payout_castle) | FLOWING |

### Behavioral Spot-Checks and Replays

See 'What I ran and read'. The state-transition and ordering truths each have a named test I saw pass in the full run: break-or-rebuild skipping a dawn (`test_a_rebuilt_mine_pays_nothing_and_makes_no_progress`, `test_a_rebuilt_harbor_gains_no_boat_pays_nothing_and_keeps_every_boat`), the wake boundary, the highlight frozen during a hold, building_built before choice_picked, pickup-order invariance (`test_every_arrival_order_of_three_sources_gives_the_same_result`), the synergy source replaced not stacked, and the five goldens (re-run by me).

### Probe Execution

No `probe-*.sh` is declared by the phase plans and none exists under `scripts/` (there is no such directory): SKIPPED. The replays, the gate stress and the full suite are the phase's runnable checks.

### Requirements Coverage

Every ID from the plans' `requirements:` is accounted for against REQUIREMENTS.md (META-08 in 05-01 and 05-12; BLDG-08, BLDG-05, UI-02 in 05-02 to 05-04 and 05-12; BLDG-09 in 05-05, 05-11, 05-12; ECON-03 in 05-06, 05-10 to 05-12; ECON-04 in 05-07, 05-10 to 05-12; ECON-05 in 05-08, 05-10 to 05-12; ECON-06 in 05-09 to 05-12). REQUIREMENTS.md's traceability table maps exactly these nine IDs to Phase 5 and no other, so none is orphaned.

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| BLDG-05 | 05-02, 05-03, 05-04, 05-10, 05-12 | A branching tier offers choice cards picked by keyboard or mouse; the choice is permanent for the run | SATISFIED by implementation evidence (REQUIREMENTS.md line 36 `[x]`, line 200 Complete) | Criterion 1 evidence; the feel is human_verification 1 |
| BLDG-08 | 05-02, 05-03, 05-04, 05-10, 05-11, 05-12 | Upgrade the castle center through its tiers for more health, one of four run-wide abilities per tier | SATISFIED (line 39 `[x]`, line 203 Complete) | Criterion 2 evidence; abilities, ladder reach and gate feel are human_verification 2, 3 and 8 |
| BLDG-09 | 05-05, 05-11, 05-12 | The castle center's tier gates which higher building tiers can be purchased | SATISFIED (line 40 `[x]`, line 204 Complete) | Criterion 2 evidence; the seven gated top tiers, `BuildRequirements`; feel is human_verification 3 |
| ECON-03 | 05-06, 05-10, 05-11, 05-12 | Gold Mine pays a high income that declines each night | SATISFIED (line 50 `[x]`, line 211 Complete) | Criterion 3; 3, 2, 1, 1, 1 pinned |
| ECON-04 | 05-07, 05-10, 05-11, 05-12 | Mill pays per tier and unlocks nearby Fields, each paying flat income | SATISFIED (line 51 `[x]`, line 212 Complete) | Criterion 3; test_mill_fields, test_field_independence |
| ECON-05 | 05-08, 05-10, 05-11, 05-12 | Fishing Harbor gains a boat each night up to a cap raised by upgrading; each boat pays | SATISFIED (line 52 `[x]`, line 213 Complete) | Criterion 3; test_fishing_harbor, test_harbor_scene |
| ECON-06 | 05-09, 05-10, 05-11, 05-12 | Shrine activates after enough nearby kills, then attacks and pays, and each additional active Shrine strengthens the others | SATISFIED on fixtures and the economy golden (line 53 `[x]`, line 214 Complete); how often it matters on the shipped map is the owner's call (human_verification 7) | Criterion 3; test_shrine, test_shrine_night, test_shrine_synergy |
| META-08 | 05-01, 05-12 | Stat bonuses combine in a fixed, documented order that automated tests verify | SATISFIED (line 96 `[x]`, line 245 Complete) | Criterion 4; docs/STAT_MODIFIERS.md, test_stat_contract |
| UI-02 | 05-02, 05-03, 05-04, 05-12 | Choice cards show an icon, name and short description per option | SATISFIED (line 114 `[x]`, line 251 Complete) | Criterion 1; twelve SVGs, test_card_row_model, test_card_icons, `castle_cards.png` |

REQUIREMENTS.md already reads Complete for all nine, set by plan 05-12 before the owner's gate (the file's own convention in this project). If the owner's UAT returns gaps in any of the feel items, the corresponding rows are the ones to reopen.

### Anti-Patterns Found

None blocking. No TBD, FIXME, XXX, TODO, HACK or PLACEHOLDER in any non-`.md` file the phase changed; no stub artifact (53/53 artifacts exist and are substantive, `IncomeState` 230 lines, `StatStack` 238 lines, `docs/STAT_MODIFIERS.md` 113 lines, twelve ability `.tres`, twelve SVGs); no empty handler on the card path. One accepted post-merge fix: after wave 10 the orchestrator changed three tests and one screenshot script outside plan 05-11's edit list to meet the new castle-II gate (commit f39b578, recorded in 05-11-SUMMARY.md); not a gap.

## Code-review findings (14 OPEN, 0 fixed)

05-REVIEW-DISPOSITION.md: every finding is `open`, held for the owner's fix pass (`/gsd-code-review 5 --fix` after the UAT, the project's standing practice). 05-REVIEW.md: standard depth, 279 files, 0 critical, 5 warnings and 9 info. None contradicts a must_have on the shipped data; the warnings I weigh as follows:

| ID | Finding | Effect on this verdict |
|---|---|---|
| WR-01 | A refused `add_source` is ignored by `ChoiceLedger` (and `IncomeState`) after the gold is spent and the pick is recorded | The stack refuses only out-of-range data (unknown stat, more than 4 multipliers, a percent sum outside -90..1000). `test_every_modifier_is_valid_and_the_stack_accepts_every_card` pins that all twelve shipped cards are accepted, so it cannot fire on shipped data; a future card could trip it silently |
| WR-02 | Castle tiers II to IV with attack 0 pass `validate()` yet disarm the keep | Shipped tiers carry attack 3, 4, 5 (castle_center.tres); a data-hygiene gap in the validator, not a shipped defect |
| WR-03 | `StatModifierDef.problems()` accepts a bucket value that is not one of the three | Shipped cards use buckets 0, 1, 2 only; validator gap |
| WR-04 | The no-income marker is drawn over a rebuilt, dormant Shrine that pays nothing anyway | Cosmetic; the payout is right |
| WR-05 | `IncomeState._on_enemy_died` rescans every plot per death | A per-death cost on 23 plots, not near the Phase 4 budget; the gate stress, which has no Shrine, is unchanged |

IN-01 to IN-09 are info items (a dead field, a digit above the card count clearing the highlight, allocation on each stack read, per-frame work near a plot, and similar). 05-SECURITY.md: `status: verified`, `threats_open: 0`, 25 threats at ASVS level 1. 05-VALIDATION.md: `status: validated`, `nyquist_compliant: true`, 26 task checks green. 05-UI-REVIEW.md (advisory): 15 of 24 on the six-pillar standard, no blocker, 3 priority fixes and 9 minor recommendations, which overlap the owner's presentation points.

## Human Verification

The structured list in the frontmatter has 10 entries, in this order: (1) the cards read and pick well by key and by mouse (also an `insufficient_spec` backstop truth), (2) the twelve abilities are distinct and worth a pick (backstop), (3) the castle gate reads as a trade-off, (4) each new building reads and is worth its gold, (5) the day is deeper and still fun (backstop), (6) the three presentation points (banner over a raised card, the cropped tier IV roof, small buildings in `economy_day`), (7) the economy mix and the Shrine's wake rule, (8) the castle ladder's reach, (9) the card row's dismiss and pre-highlight, (10) the exported build and the packet hand-off. The owner plays from `05-PLAYTEST-GATE.md` ('How to play', 'What to judge', 'Open points', 'Your decision') and rules through `/gsd-verify-work 5`; the orchestrator turns these entries 1:1 into UAT tests. Nothing here is a code defect: every mechanism the entries judge is pinned by a test that passed.

## Gaps Summary

No gap blocks the phase goal. The four ROADMAP criteria hold in the code and under test: the stack and its documented order, the castle with its twelve cards and its gate, the four buildings on four curves, and the goldens (smoke, army and walls byte-identical for the whole phase; economy new and reproduced; full_idle moved once on purpose to 7000 ticks and reported). What is left is the owner's feel and decision gate, which was never run, and the open review findings, which the standing practice defers to a fix pass after the UAT. Two non-blocking notes: the Shrine rarely wakes and almost never fires in bot play on the shipped map (a balance decision recorded in the packet, not a defect in the rule), and the presentation points (banner overlap, cropped tier IV roof, small buildings at the far camera) may be left for Phase 8 (Art, Readability and Sound) if the owner chooses.

---

_Verified: 2026-10-22T10:20:15Z_
_Verifier: Claude (gsd-verifier)_
