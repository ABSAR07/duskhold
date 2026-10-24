---
status: diagnosed
trigger: "G-05-2 (Phase 5 UAT test 2): Commander's +25% unit damage rounds back to 1 at the shipped unit numbers; Prosperity's +1 gold a dawn seems weak; every card at a castle tier should be a viable pick"
created: 2026-10-24T19:15:15Z
updated: 2026-10-24T19:28:18Z
goal: find_root_cause_only
---

## Current Focus

hypothesis: CONFIRMED. (1) Percent and multiplier cards on per-hit integer stats whose shipped base is 1 or 2 round back to the base (Commander damage, Warded Mail) or overshoot (Iron Discipline x1.5 -> x2); (2) a second quantization: enemies die in 1 to 6 hits, so damage percents only matter at hits-to-kill breakpoints (Engineers' and Golden Age's damage halves, Headsman's Edge after Royal Training) and a uniform rescale does not move those; (3) dawn-income cards are worth flat x (8 - pick day) gold, so Prosperity (+1, castle II bought day 6 by the bot, day 3 at the earliest) and Golden Age (+2 at tier IV, 0 or 1 paying dawn) are weak by construction
bug_class: Bohrbug (deterministic data/rounding; no flakiness)
test: done (card_probe.gd through the real StatStack; tier2_probe.gd: balanced bot seeds 1-10 with each tier II card and Prosperity +1/+2/+3)
expecting: n/a
next_action: return ROOT CAUSE FOUND to the orchestrator (goal find_root_cause_only); /gsd-plan-phase 5 --gaps plans the fix

## Symptoms

expected: all four cards at a castle tier are viable picks, each card's effect lands as its text says
actual: (owner, verbatim, 2026-10-24) (a) on Commander's "+25% unit damage" rounding back to 1 at the shipped unit numbers: "perhaps we need to scale all damage and health numbers up by a factor of 100. then percentages and rounding to nearest unit will work more as intended i think"; (b) on Prosperity's +1 gold a dawn: "seems weak. we want to make sure that all alternatives at an upgrade level are mostly viable options, stronger in particular cases but not overly weak even in a case where its not an ideal option"
errors: none (no crash; a tuning-resolution and balance gap)
reproduction: Test 2 in .planning/phases/05-castle-center-economy-depth/05-UAT.md; measured in a real window by the orchestrator: with Commander armed, StatStack.int_value(&"unit.max_health", 10) = 13 and int_value(&"unit.attack_damage", 3) = 4, but the shipped units have attack_damage 1 (footman and archer: data/units/*.tres), so +25% of 1 rounds half-up back to 1 and the damage half of the card does nothing; Prosperity adds +1 castle base income a dawn (about 7 gold over an eight-night run) against its tier's 6-gold price
started: discovered during the Phase 5 UAT on 2026-10-24

## Eliminated

## Evidence

- timestamp: 2026-10-24T19:15:15Z
  checked: .planning/debug/knowledge-base.md
  found: no knowledge base file exists; no prior resolved session to match
  implication: proceed without a known-pattern candidate

- timestamp: 2026-10-24T19:19:28Z
  checked: simulation/stats/stat_stack.gd _int_from, docs/STAT_MODIFIERS.md, simulation/stats/stat_modifier_def.gd
  found: int stats are one exact fraction (base+flat)*(100+pct)*m1../(100*100^k) rounded once half up via (num*2+den)/(2*den), floored at 1 when base>=1. Bucket enum FLAT=0 (omitted in .tres), PERCENT=1, MULTIPLIER=2. Every read site (king_state 137/159/173/280/283, unit_system 228, squad_system 323/590, building_system 270, wall_system 64/207, tower_system 54/68, castle_state 105/113/135/171) calls int_value on a per-hit or per-unit base, so the rounding resolution is the base integer itself
  implication: any percent/multiplier whose base*change is below 0.5 in absolute value rounds to no change; one at exactly 0.5 rounds up (half up), so a decrease of 0.5 vanishes and an increase of 0.5 becomes a full +1

- timestamp: 2026-10-24T19:19:28Z
  checked: scratch probe card_probe.gd (real StatStack, real data/abilities/*.tres, shipped bases from data/units, data/king, data/enemies, data/buildings, castle_center.tres, prototype_map.tres); output saved as scratchpad/exec/debugger-g2/card_probe.out
  found: NO-OP modifiers: Commander +25% unit damage 1->1 (footman and archer, 0% of the intended 25%); Warded Mail x0.75 king damage taken 2->2 on both enemy types (grunt and skirmisher both hit for 2; 1.5 rounds half up to 2; 0% of the intended -25%, the whole card does nothing); Golden Age +25% shrine damage 3->4 alone but 4->4 once two Shrines are awake (synergy +20% already gives 3.6->4; synergy + Golden Age 4.35->4). DISPROPORTIONATE: Iron Discipline x1.5 unit damage 1->2 (+100%, double the text); Engineers +25% tower damage 3->4 and 6->8 (+33%); Golden Age +25% shrine 3->4 (+33%, when it lands); Commander +25% unit health footman 10->13 (+30%), archer 6->8 (+33%); Iron Discipline x1.3 archer 6->8 (+33%); Masons +30% field 8->10 (+25%), house I 12->16 (+33%), mill I 15->20 (+33%). LAND AS WRITTEN: Royal Training (50->63, 5->6), Masons (towers, barracks, walls exact 30%), Headsman's Edge (5->10, 0.7->1.05 s), Engineers range (float), War Horns (float 10/7/4 -> 6/4.2/2.4), Arrow Storm (5->10, 22->27.5), Master Builders (+50%, mill +52-53%), Prosperity and Golden Age income (flat)
  implication: three cards are partly or wholly dead at the shipped numbers (Commander's damage half, Warded Mail entirely, Golden Age's shrine half with two awake Shrines); the root cause is integer per-hit bases of 1 and 2 that cannot resolve a 25% change, not the stack's formula

- timestamp: 2026-10-24T19:26:00Z
  checked: native/src/enemy_step.cpp:543 (strikes push def.attack_damage), night_sim._resolve_hits -> KingState.take_damage -> int_value(king.damage_taken, amount); data/enemies grunt.tres and ranged.tres attack_damage 2 each; no per-night scaling (NightDef has only groups)
  found: every hit the king ever takes is exactly 2, so Warded Mail's x0.75 always yields 2 (1.5 half up)
  implication: Warded Mail is dead in every run at the shipped numbers, not just in some cases

- timestamp: 2026-10-24T19:26:00Z
  checked: hits-to-kill against grunt 6 hp and skirmisher 4 hp for every damage source with and without the cards (ceil(hp/dmg))
  found: units 1 -> 6/4 hits; Commander 1 -> 6/4 (no change); Iron Discipline 2 -> 3/2. King 5 -> 2/1; Royal Training 6 -> 1/1; Headsman's Edge 10 -> 1/1 at x1.5 interval (21 -> 32 ticks), so it is +31% kill rate on grunts but -34% on skirmishers, and after Royal Training (already 1/1) it is -34% on both. Tower I 3 -> 2/2; Engineers 4 -> 2/1 (grunt unchanged). Tower II 6 -> 1/1; Engineers 8 -> 1/1 (no change). Shrine 3 -> 2/2; Golden Age or synergy 4 -> 2/1. Castle IV 5 -> 2/1; Arrow Storm 10 -> 1/1. Under an exact x100 (enemy 600/400, tower 300 -> 375, unit 100 -> 125): Commander 6 -> 5 hits on grunts; Engineers tower I 2/2 -> 2/2 (no change on either), Golden Age shrine 2/2 -> 2/2
  implication: a second, deeper quantization: enemies die in 1 to 6 hits, so a percent damage bonus is felt only where it crosses a hits-to-kill breakpoint. A uniform rescale (x100 or x10) preserves every ratio and therefore every breakpoint; it fixes the rounding of the bonus but not the breakpoint granularity (Engineers' and Golden Age's damage halves would still do nothing on kills; Headsman's Edge stays a loss after Royal Training)

- timestamp: 2026-10-24T19:26:00Z
  checked: tools/replay/sim_recorder.gd (digest lines record enemy_damaged/castle_damaged/king_damaged/unit_damaged/wall_damaged amounts and hp); tests/fixtures/fixture_map_replay_{smoke,army,walls,economy}.tres (0 res://data references each; economy carries inline copies of the four tier II cards and picks Masons)
  found: any shipped health/damage rescale moves the full_idle digest by construction (amounts and hp are in the digest lines); the four fixture goldens cannot see shipped data, so a data-only rescale leaves smoke 2599c7c2, army f7a967ed, walls bfb05fc7, economy f4b98093 unmoved; a code change in the int rounding or hit pipeline moves them only if it changes the output for an empty stack or for Masons' health percents
  implication: D-08 stop rule applies to the fixtures only for code changes; full_idle is expected to move for any data rescale and needs the before/after report

- timestamp: 2026-10-24T19:28:18Z
  checked: scratch tier2_probe.gd (real ReplayDriver + PlaytestStrategies balanced order, seeds 1-10, tier II pick swapped in memory; Prosperity value edited in memory only, nothing saved); output scratchpad/exec/debugger-g2/tier2_probe.out
  found: Masons (shipped) 8/10 wins, mean gold earned 30.0, buildings lost 8.6; Royal Training 8/10, 28.6, 11.7; Commander 7/10, 27.3, 12.8 (the balanced build has no squads, so Commander is a null card here: the no-card baseline); Prosperity +1 7/10, 28.8, 12.3; Prosperity +2 8/10, 31.7, 11.0; Prosperity +3 8/10, 33.1, 11.0. Castle II is bought on day 6 (day 8 in seed 8) so the card pays at two dawns; the dawn totals show Masons also pays (days 6-7 dawns 8,8 against 6,6 for the null card) because a fallen income building pays nothing at its rebuild dawn
  implication: Prosperity +1 is dominated by Masons on wins, gold and losses for the tower build (+1.5 gold over the null card against Masons' +2.7); it needs about +2 to match Masons on gold and still loses more buildings; seven dawns pay in a run (no payout after the last night, run_manager._end_night), so a flat income card is worth value x (8 - pick day)

- timestamp: 2026-10-24T19:28:18Z
  checked: why not caught: tests/unit/test_ability_data.gd (pins each card's stat/bucket/value only), tests/unit/test_stat_stack.gd and test_stat_combined.gd (synthetic bases 3, 6, 10), 05-03-PLAN (numbers '[ASSUMED] starting points, research Ability Draft'), 05-BALANCE-REPORT (bots pick only Masons; tiers III and IV never reached; army bot never buys the castle), tests/unit/test_military_data_contract.gd:30-33 (footman damage 1 is Phase 3 D-07, 'the integer nearest a fifth of the king's passive 5')
  found: no gate applies a card to the shipped bases it touches; the unit damage base of 1 predates the cards by two phases
  implication: recurrence guard candidate: a contract test that, for every card modifier and every shipped base of its stat, asserts the stack moves the value and stays within a band of the written effect

- timestamp: 2026-10-24T19:28:18Z
  checked: blast radius greps (tests/ literals, display format strings, fixtures referencing res://data/, tools/stress/data)
  found: shipped health/damage fields: enemies grunt/ranged (max_health, attack_damage), units footman/archer (max_health, attack_damage), king.tres max_health, sword.tres attack_damage and slam_damage, 11 building files (every tier max_health; tower, shrine and castle_center attack_damage; shrine wake_threshold_hp), prototype_map.tres castle_max_health and castle_attack_damage, royal_training.tres flat +1; seven non-golden fixtures (castle, gate, one_night, shrine, squads, walls, walls_gap) load shipped defs and move with them; tools/stress/data stress_grunt/stress_footman must match shipped attack_damage (test_stress_map_data). Displays printing raw numbers: ui/hud/king_widget.gd:251, ui/overlay/night_overlay_sections.gd:66, ui/overlay/stat_overlay_sections.gd:41, ui/world/spot_label_model.gd:103/114/122, simulation/defs/building_tier_def.gd:60, simulation/defs/building_def.gd:88, ui/overlay/economy_overlay_sections.gd:54, StatModifierDef.effect_text flat values; the results screen prints no health or damage. Literal pins: test_military_data_contract, test_economy_data_contract, test_castle_data_contract, test_wall_data_contract, test_weapon_def, test_balance_acceptance (GRUNT_MAX_HEALTH 6, owner-ruled), test_stress_map_data, test_ability_data, test_king_regen (50), test_castle_label ('Health 100 · Arrow 3 · 2 gold at dawn'), test_spot_label_model ('30/60/90 health each'), test_economy_overlay_sections ('asleep 30 of 100'), test_king_widget ('50 / 50', '38 / 50', '0 / 50', '5 / 50'), test_map_validate_castle (GRUNT_HEALTH 6); test_order_markers KILL_DAMAGE 999 on fixture_map_squads (shipped footman) stops killing at footman 1000
  implication: x100 is a cross-cutting retune (about 20 data files, 5 stress files, about 15 pinned tests plus derived-value tests, 10 display sites, a full bot re-measure); the four goldens stay because their fixtures are inline; full_idle moves

## Resolution

root_cause: Integer per-hit bases too small to resolve the cards' percents, compounded by coarse hits-to-kill, plus income cards whose value shrinks with the pick day. (a) Commander's +25% unit damage acts on attack_damage 1 (footman, archer; Phase 3 D-07) and rounds 1.25 -> 1; Warded Mail's x0.75 acts on every king hit, which is always 2 (both enemies), and rounds 1.5 -> 2, so the whole card does nothing; Golden Age's +25% shrine damage is masked once two Shrines are awake (3 x 1.2 = 3.6 -> 4 and 3 x 1.45 = 4.35 -> 4); Iron Discipline's x1.5 rounds 1 -> 2 (+100%). StatStack is correct to its contract (one half-up rounding of an exact fraction); the data bases are the defect. (b) Enemies die in 1 to 6 hits (grunt 6 hp, skirmisher 4), so damage percents only matter at breakpoints: Engineers' damage half changes no grunt kill and nothing at Tower II, Golden Age's shrine half changes no grunt kill, Headsman's Edge is -34% kill rate on skirmishers and on everything after Royal Training; a uniform rescale keeps every breakpoint. (c) Prosperity +1 and Golden Age +2 are flat dawn income worth value x (8 - pick day): castle II is bought on day 6 by the bot (day 3 at the earliest), tier IV only at the end, so Prosperity is worth about 2 gold (measured 7/10 and +1.5 gold against Masons' 8/10 and +2.7) and Golden Age about 0-2
fix: (diagnose only; directions in the return)
verification: n/a (diagnose only)
files_changed: []
