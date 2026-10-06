---
status: diagnosed
trigger: "UAT Test 1 (owner playtest gate, ROADMAP SC4) of Phase 2 failed. The owner played the exported build and reported four tuning/feel problems; see symptoms."
created: 2026-10-06T10:28:19Z
updated: 2026-10-06T12:10:00Z
goal: find_root_cause_only
---

## Current Focus

bug_class: Bohrbug (deterministic: data values and missing features, reproduced exactly by reading the data and by the seeded bot matrix)
hypothesis: CONFIRMED for all four points (see Resolution). Point 4 is an AND of the point-1 economy trap and a night-3 human-vs-bot gap.
test: done (code and data read, bash tools/playtest.sh on HEAD, smoke golden replay, 700-run in-memory variant probe)
expecting: n/a
next_action: Return ROOT CAUSE FOUND to the orchestrator; fixes go to plan-phase --gaps (diagnosis only, nothing applied)

reasoning_checkpoint:
  hypothesis: "(1) a day-1 tower leaves 0 gold forever because the only income is House dawn_income; (2) the castle has no attacker; (3) the only speed-up is the 1.6x sprint (8 m/s); (4) the owner cannot win because the tower-first opening is an economy dead end AND a human king is weaker than the bots on night 3, the one night the data is tight"
  confirming_evidence:
    - "run_manager.gd:191-198 grants only sum(dawn_income_by_spot()); tower tiers have dawn_income 0; no other grant() caller in non-test code; towers_first and tower_opening earn 0 gold and lose 10/10"
    - "castle_state.gd has no attack; night_sim.gd:74-79 steps no castle attacker"
    - "project.godot has no game-speed action; no code writes Engine.time_scale; king.gd:27-30 x king.tres:7-8 = 8.0 m/s"
    - "probe: +1 base gold per dawn takes tower_opening from 0/10 to 10/10 (also at walk speed); balanced@walk loses 2/10 on night 3 at baseline and 0/10 with any of base+1 / castle attack"
  falsification_test: "A gold source other than House dawn income (none found by grep), a game-speed control in the input map or code (none), or a tower-first run that wins on shipped data (0/10 for bots). Point 4 would be wrong if the probe showed the owner-like opening still losing with base income (it wins 10/10)."
  fix_rationale: "Base income removes the zero-income dead end directly; a castle attacker and a faster sprint relieve the night-3 pinch where a weaker king loses; together they make owner-like runs winnable while greedy and idle play still lose"
  blind_spots: "The owner's run count and loss night are unknown (assumed from their tower-first report). 'The speed up' is read as the sprint; if the owner meant a game-speed fast-forward, none exists and point 3 is a new feature. The probe injects base gold and castle hits from outside the sim (one tick of position lag, base gold not in RunStats); a real implementation must be re-measured with tools/playtest.sh. Walk-speed and idle kings are crude human proxies."
  candidate_causes:
    - "data: no base income value; Houses the only income; sprint_multiplier 1.6; night 3 counts 6+5 before a tower is affordable"
    - "code: no non-building income path in _apply_dawn_payout; no castle attacker in NightSim; no game-speed control"
    - "environment/human: bots build without riding and react perfectly (assumption 12); a first-time player opens with a tower"
  and_gate: "yes for point 4: the zero-income opening AND the human night-3 gap; either alone is enough to lose some runs (tower_opening 0/10 with a perfect bot; balanced@walk 2/10 losses), together they make the owner's run unwinnable. Points 1-3 are single-cause."

known_pattern_candidate: none (knowledge-base.md does not exist; MemPalace not used)

## Symptoms

expected: A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change
actual: "(1) there needs to be some base gold gain at each wave. I made a tower the first wave and then had 0 gold for all waves after that. (2) castle should also have a simple attack, not too strong though. Maybe takes three shots to kill a grunt and two to kill the ranged units. (3) the speed up should be at least 1.5x faster too (4) i cant currently win lol make it just a bit easier"
errors: none reported
reproduction: Test 1 in UAT (.planning/phases/02-night-defense-playtest-gate/02-UAT.md); gap id G-02-1
started: discovered during UAT (2026-10-06), first owner playtest of the Phase 2 build

## Eliminated

- hypothesis: A player-facing game-speed control (hold or toggle) exists and its multiplier is too low (the orchestrator's anchor for point 3)
  evidence: project.godot [input] has no such action; no non-test code writes Engine.time_scale; MapRoot._process passes the unscaled delta to RunContext.advance (map_root.gd:42); no requirement, roadmap item or plan mentions one. The only speed modifier is the sprint.
  timestamp: 2026-10-06T10:44:00Z

- hypothesis: The 0-gold run is a payout bug (dawn payout not granted, or gold reset at day start)
  evidence: _apply_dawn_payout grants the summed House income (run_manager.gd:191-198) and nothing rebases gold (ECON-07); House openings earn 18 gold over a run in the bot matrix. The tower-first run gets 0 because no tower tier has dawn_income, which is the design (D-10), not a fault.
  timestamp: 2026-10-06T10:32:00Z

- hypothesis: The owner loses on the late nights (6 to 8) because the waves outscale the defences
  evidence: balanced and houses_first keep the castle within 0.2 hp of full from night 4 to night 8 on every seed; the only bot pinch is night 3, and the only weak-king losses (balanced@walk) are on night 3. Late-night losses only occur for economy-trapped openings (tower-first, N6-7) and greedy (N4-6).
  timestamp: 2026-10-06T12:05:00Z

## Evidence

- timestamp: 2026-10-06T10:32:00Z
  checked: every gold source in non-test code (grep "\.grant(" / starting_gold / dawn_income), simulation/run/run_manager.gd:187-198, simulation/buildings/building_system.gd:75-90, simulation/economy/economy.gd:9-11, simulation/run/run_context.gd:38, data/maps/prototype_map.tres:345, data/buildings/house.tres, data/buildings/tower.tres
  found: Gold enters the ledger in exactly two places - Economy._init(starting_gold) (run_context.gd:38, map starting_gold = 4 at prototype_map.tres:345) and RunManager._apply_dawn_payout (run_manager.gd:191-198), which grants only the sum of BuildingSystem.dawn_income_by_spot(). dawn_income_by_spot (building_system.gd:78-90) lists only standing, non-rebuilt buildings whose tier dawn_income > 0. House tiers pay 1/2/3 (costs 2/3/5); both Tower tiers have no dawn_income line, so the default 0 (building_tier_def.gd:8) applies. There is no per-dawn base income, no kill bounty, no castle income, and no tuning field for one (LoopTuning and MapConfig have none).
  implication: Point 1 reproduced by reading. Day 1: 4 gold - Tower I (cost 4) = 0. Every later dawn: dawn_income_by_spot() is {} so total = 0 and nothing is granted (run_manager.gd:196 guard). Gold stays 0 for the whole run; no House (cost 2) is ever affordable again. This is the towers_first bot row in 02-BALANCE-REPORT.md (gold earned 0.0, dies night 6), and it is the trap the report already flagged.

- timestamp: 2026-10-06T10:40:00Z
  checked: simulation/castle/castle_state.gd (whole file), simulation/night/night_sim.gd:66-81 and 137-146, simulation/night/tower_system.gd (whole file), simulation/night/pending_hits.gd:8-11, simulation/night/target_query.gd:11-22, data/enemies/grunt.tres, data/enemies/ranged.tres, simulation/defs/map_config.gd:27-30
  found: CastleState is health only (position, radius, health, damage, repair); it has no attack, no cooldown and no step(). NightSim.step runs spawn -> king.step -> towers.step -> enemies.step -> resolve hits -> remove dead (night_sim.gd:74-79); nothing steps the castle. The only castle data on MapConfig are castle_max_health (70 in prototype_map.tres:353) and castle_radius (3.5, :354). The closest attacker is TowerSystem.step (tower_system.gd:27-54): per-attacker ready tick, TargetQuery.nearest_enemy(origin, range) on centre distance, SimClock.flight_ticks(distance, projectile_speed), PendingHits.enqueue(tick + flight, attacker_kind, attacker_id, KIND_ENEMY, target_id, damage), events.attack_fired.emit(...), ready = tick + SimClock.ticks(interval). PendingHits already defines KIND_CASTLE (used today only as a target kind). Grunt max_health 6, Skirmisher (id ranged) max_health 4.
  implication: Point 2 is a missing feature, not a regression. Castle damage 2 is the only integer that gives exactly 3 shots on a grunt (ceil(6/2)=3) and 2 on a skirmisher (ceil(4/2)=2); damage 3 gives 2 and 2, damage 1 gives 6 and 4.

- timestamp: 2026-10-06T10:44:00Z
  checked: project.godot [input] (all actions), grep for Engine.time_scale / .advance( / time_scale / speed-up in non-test code, presentation/map/map_root.gd:39-42, simulation/run/run_context.gd:63-73, simulation/clock/sim_clock.gd:9-12, presentation/king/king.gd:26-30 and 60-71, data/king/king.tres, simulation/defs/king_def.gd:3-7
  found: The input map has move_left/right/forward/back, sprint, action_build, start_night, ui_accept, ui_left, ui_right, toggle_debug_overlay, zoom_in, zoom_out. There is NO game-speed / fast-forward action, and no non-test code writes Engine.time_scale; MapRoot._process feeds the unscaled frame delta straight into ctx.advance(delta) (map_root.gd:42), which clamps it to MAX_ADVANCE_SECONDS = 0.25 s and runs whole 1/30 s steps. The only player-facing speed-up is the king's sprint: action sprint = Shift (physical 4194325) / gamepad button 10 (right shoulder); King._physics_process uses King.move_speed(def, Input.is_action_pressed(&"sprint")) = walk_speed * sprint_multiplier = 5.0 * 1.6 = 8.0 m/s (king.tres walk_speed 5.0, sprint_multiplier 1.6; king_def.gd:3-4 documents 1.6 as the source game's ratio). The 02-PLAYTEST-GATE.md controls table lists exactly this Sprint row as the only speed control the owner was given.
  implication: The orchestrator's anchor (a hold/toggle that raises the sim step rate) does not exist in the code. "The speed up" the owner played with can only be the sprint; "at least 1.5x faster" against today's 8.0 m/s means >= 12.0 m/s, i.e. sprint_multiplier >= 2.4 at walk 5.0 (it is already 1.6x walk, so a ratio-to-walk reading would already be satisfied, which argues for the sprint-speed reading).

- timestamp: 2026-10-06T10:55:00Z
  checked: presentation/vfx/projectile_vfx.gd:102-135 and 172-183, tools/replay/replay_driver.gd:133-139, simulation/night/enemy_system.gd:103-111 and 262-303, ui/hud/dawn_payout_vfx.gd:151-197 and 325-338
  found: (castle attack reuse) EnemySystem.damage(id, amount, killer_kind) accepts any killer kind, so a castle hit with attacker_kind KIND_CASTLE needs no EnemySystem change. ProjectileVfx._on_attack_fired drops every attacker kind other than KIND_BUILDING / KIND_ENEMY (line 113) and _attacker_position resolves only those two, so castle arrows would be invisible until both learn KIND_CASTLE. ReplayDriver.Tally counts kills only for KIND_KING and KIND_BUILDING (lines 136-139), so castle kills would vanish from the balance report without a kills_castle column. Stop distances from the castle centre: grunt 3.5 + 1.2 = 4.7 m, skirmisher 3.5 + 7.0 = 10.5 m (enemy_system.gd:280-281), so a castle range under ~10.5 m (centre-to-centre, TargetQuery) never reaches a skirmisher that is shooting the castle. (base income) DawnPayoutVfx expects total == sum(per_spot): a total with no matching per_spot entry triggers push_warning, flies no coin for the difference and shows no "+X gold" for it (lines 152-191); an unknown per_spot key (not a BuildSpotDef) is drawn from the middle of the screen (spot_screen_point fallback, lines 325-334).
  implication: A castle attack is a small new attacker in the sim (TowerSystem pattern) plus two presentation/tool touch points; a base income must be carried in per_spot (or the VFX taught about it) or the HUD/VFX contract breaks.

- timestamp: 2026-10-06T11:02:00Z
  checked: bash tools/playtest.sh --out=build/playtest_debug_probe on HEAD 23cdd29 (42 s, PLAYTEST_OK runs=50)
  found: Identical to 02-BALANCE-REPORT.md: no_build 0% (lost N1), greedy_economy 0% (median loss N4, survived 3-4), houses_first 100%, towers_first 0% (survived 5-6, median loss N6, gold earned 0.0), balanced 100%. Balanced per night: castle ends N3 at 49.6/70 (the only night it loses hp), 2 Houses lost N3, 0.6 knockouts N3, 0.8 on N5; N4-N8 castle within 0.2 of 70.
  implication: The report still describes HEAD. Bot margins: the House-opening strategies win with a full castle from N4; the only bot pinch is N3. towers_first (the owner's opening) loses 10/10 even with perfect bot play, because its income is 0.

- timestamp: 2026-10-06T11:15:00Z
  checked: scratch probe scratchpad/probe_variants.gd (quick pass, seeds 1-3), run headless with the pinned Godot binary; shipped data duplicated in memory; base income injected with Economy.grant on dawn_payout; castle attack injected as PendingHits KIND_CASTLE hits (TowerSystem pattern from the castle centre, 2 dmg / 1.0 s / range 11 m / 18 m/s, one tick of position lag); sprint via KingDef copy
  found: The probe's baseline reproduces the shipped matrix shape (towers_first loses N6 3/3, balanced wins 3/3, greedy loses N4-N5). towers_first: base+1 -> 1/3 wins (others lose N8), base+2 -> 3/3, castle2 alone -> 0/3 (losses N7-N8), base+1 + castle2 -> 3/3. greedy_economy keeps losing (N4-N6) in every variant. no_build with castle2 clears night 1 (castle kills ~10 over N1-N2) and loses N2. balanced@idle (king never leaves the castle front) loses N1-N3 in almost every variant because an idle king at king_spawn cannot reach grunts at the castle's west edge.
  implication: The owner's own asks 1 and 2 (base income and a castle attack) already turn the owner's tower-first run from a guaranteed loss into a win for a perfect bot while greedy and no_build still lose, so they are themselves the main "a bit easier" levers. A 1.0 s castle interval lets an empty map survive night 1, which may be stronger than "not too strong"; test a slower interval and a human-proxy king.

- timestamp: 2026-10-06T11:25:00Z
  checked: .planning/REQUIREMENTS.md / ROADMAP.md / PROJECT.md / phase 02 docs for any game-speed feature; 01-CONTEXT.md:123; tests/unit/test_king_movement_config.gd:6,19-21; tests/e2e/test_king_ride.gd:9-10,57,62-69; tests/unit/test_playtest_strategies.gd:124-127; tools/replay/playtest_bot.gd:121-125; presentation/camera/camera_rig.gd:13,48
  found: No requirement, roadmap item or plan mentions a game-speed or fast-forward control; the only speed modifier the project ever specified is KING-01's "sprint modifier", and 01-CONTEXT.md:123 records Thronefall's ~1.6x walk-to-sprint ratio as the reference that became sprint_multiplier = 1.6. test_king_movement_config.gd pins it twice: assert_eq(sprint_multiplier, 1.6) (:20) and assert_between(1.4, 1.8) (:21). test_king_ride.gd compares the measured ratio with def.sprint_multiplier (data-driven, follows a change). The ride-time contract (test_prototype_map_data.gd:72-86, 20-30 s edge to edge) uses walk_speed only. The defending bot moves at walk_speed * sprint_multiplier (playtest_bot.gd:125), so a sprint change moves bot balance numbers and the full_idle replay digest (not the smoke golden, which runs on tests/fixtures/fixture_king_replay_smoke.tres). Acceleration 40 m/s^2 is also the braking rate (king.gd:69 move_toward), so stopping from 8 m/s takes 0.8 m and from 12 m/s 1.8 m against an interaction_radius of 2.5 m; camera lag at steady speed is about v / follow_sharpness = 1.3 m now, 2.0 m at 12 m/s.
  implication: Point 3 is a data value (king.tres sprint_multiplier 1.6) held in place by a unit test that pins the Thronefall ratio. Meeting ">= 1.5x faster" is sprint_multiplier >= 2.4 (12 m/s), plus the two asserts in test_king_movement_config.gd; acceleration may need a matching raise so the king still stops on a plot.

- timestamp: 2026-10-06T11:27:00Z
  checked: tests/unit/test_prototype_map_data.gd:89-100 and 111-121, tests/unit/test_dawn_income.gd:102,118, tests/integration/test_loop_gold_carryover.gd:63-77, tests/integration/test_night_loop.gd:82, tools/replay/replay_scenarios.gd:20-32
  found: test_starting_gold_buys_two_houses_or_one_tower_but_not_both pins 2*house_cost <= starting_gold < 2*house_cost + tower_cost, i.e. starting gold 4..7 (D-09). test_tower_has_two_tiers_with_attack_data_and_no_income pins tower dawn_income == 0 (D-10). test_dawn_income.gd "a dawn with no houses pays nothing" and test_loop_gold_carryover "dawn 1 payout == 2 x House I income" run on the shipped loop_tuning.tres. The smoke replay loads frozen fixtures (fixture_map_replay_smoke.tres, fixture_king_replay_smoke.tres, fixture_tuning_replay_smoke.tres); full_idle loads the shipped data.
  implication: Base income cannot come from giving towers income without overturning D-10; it has to be a separate source (a per-map or per-tuning base payout). A new field whose script default is 0 and whose shipped value is set only in data keeps the smoke golden unchanged; the "no Houses, no income" tests change by design.

- timestamp: 2026-10-06T12:05:00Z
  checked: full probe (scratchpad/probe_variants.gd, seeds 1-10, 10 variants x 7 strategies, 700 runs; log scratchpad/probe_full.log). Extra strategies: tower_opening = Tower I on day 1 then Houses (the owner's opening, then sensible play); "@walk" = the defending bot king moves at walk speed (sprint_multiplier 1.0), a proxy for a human who does not react perfectly. Castle attack = 2 dmg, range 11 m, 18 m/s, interval 1.0 s or 1.5 s.
  found: |
    win rate / loss nights (castle hp at end of N3 for balanced in brackets):
    baseline:            tower_opening 0/10 (N6-7), towers_first 0/10 (N6-7), greedy 0/10 (N4-5), balanced 10/10 [49.6], balanced@walk 8/10 (2 losses on N3), tower_opening@walk 0/10, no_build N1
    base+1:              tower_opening 10/10, tower_opening@walk 10/10, towers_first 3/10 (N8), greedy 0/10 (N4-5), balanced 10/10 [70.0, 0 knockouts], balanced@walk 10/10, no_build N1
    base+2:              everything except greedy (0/10, N4-5) and no_build (N1) wins 10/10
    castle2/1.0s:        tower_opening 0/10 (N7-8), greedy 0/10 (N5-6), balanced 10/10 [69.8], balanced@walk 10/10, no_build survives N1 and loses N2 on every seed (castle kills ~10)
    castle2/1.5s:        tower_opening 0/10 (N7-8), greedy 0/10 (N4-6), balanced 10/10 [69.0], balanced@walk 10/10, no_build loses N1 7/10, N2 3/10
    base+1,castle2/1.5s: tower_opening 10/10, tower_opening@walk 10/10, towers_first 9/10, greedy 0/10 (N4-5), balanced 10/10 [70.0], no_build N1-N2
    base+1,castle2/1.5s,sprint2.4: same as above, towers_first 10/10, greedy 0/10 (N5)
    sprint2.4 alone:     balanced [56.6, knockouts 1.4 -> 1.1], greedy N3 castle 49.6 -> 56.6, economy-trapped openings still 0/10
  implication: |
    (a) The economy trap is the decisive cause of the owner's loss: no combat change rescues a tower-first opening (castle attack alone only delays its loss to N7-8; sprint alone changes nothing), while +1 base gold per dawn makes it 10/10 even with a walk-speed king.
    (b) Night 3 is the only place a weaker king loses on the shipped data (balanced@walk loses 2/10 there); each of base+1, the castle attack and a faster sprint relieves it.
    (c) Greed and doing nothing keep losing in every variant (greedy N4-N6, no_build N1-N2), so asks 1-3 do not flatten the punish-greed shape of the curve. They do remove the night-3 pinch for a perfect bot: with base+1 the balanced order affords its first tower on day 3 instead of day 4, so its castle ends N3 at 70 instead of 49.6.
    (d) A castle interval of 1.0 s lets an empty map clear night 1; 1.5 s keeps no_build losing on night 1 in 7 of 10 seeds, which fits "not too strong".

## Resolution

root_cause: |
  (1) Income. Gold enters the run in exactly two places: MapConfig.starting_gold (4, data/maps/prototype_map.tres:345, read once by Economy.new at simulation/run/run_context.gd:38) and RunManager._apply_dawn_payout (simulation/run/run_manager.gd:191-198), which grants only the sum of BuildingSystem.dawn_income_by_spot() (simulation/buildings/building_system.gd:78-90): standing, non-rebuilt buildings whose tier dawn_income > 0. Only House tiers pay (1/2/3 at data/buildings/house.tres:9/15/21); Tower tiers have no dawn_income (default 0, simulation/defs/building_tier_def.gd:8; pinned at 0 by tests/unit/test_prototype_map_data.gd:121, D-10). No base, castle or per-night income exists in code or data. A day-1 Tower I (cost 4, tower.tres:8) spends the whole 4; every later dawn_income_by_spot() is {} and the `if total > 0` guard (run_manager.gd:196) grants nothing, so gold is 0 for the rest of the run and no House (cost 2) is ever affordable. Bots confirm: towers_first earns 0.0 gold and loses 10 of 10 on night 6.
  (2) Castle attack. Missing feature, not a regression: CastleState (simulation/castle/castle_state.gd) is health only and NightSim.step (simulation/night/night_sim.gd:74-79) steps spawn, king, towers, enemies, hits; nothing attacks from the castle. With Grunt 6 hp (data/enemies/grunt.tres:9) and Skirmisher 4 hp (data/enemies/ranged.tres:9), damage 2 is the only integer giving 3 shots and 2 shots. Skirmishers shoot the castle from 3.5 + 7.0 = 10.5 m (castle_radius + attack_range, centre to centre), so the castle's range must be at least about 11 m to answer them.
  (3) Speed-up. No game-speed or fast-forward control exists (input map has no such action, no code writes Engine.time_scale, MapRoot._process feeds the unscaled frame delta to ctx.advance at presentation/map/map_root.gd:42). The only speed-up the owner was given is the king's sprint (action sprint: Shift / gamepad right shoulder): King.move_speed (presentation/king/king.gd:27-30) = walk_speed 5.0 x sprint_multiplier 1.6 (data/king/king.tres:7-8) = 8.0 m/s, the Thronefall walk-to-sprint ratio adopted in 01-CONTEXT.md:123 and pinned by tests/unit/test_king_movement_config.gd:20-21. ">= 1.5x faster" means a sprint of >= 12.0 m/s (sprint_multiplier >= 2.4).
  (4) Difficulty. An AND of two conditions: (a) the owner's tower-first opening is unwinnable by design because of (1): towers_first and a tower-then-Houses opening both lose 10 of 10 even as perfect bots (night 6 to 7); (b) a human is weaker than the bots exactly where the data is tight, night 3 (king alone against 6 west + 5 east grunts, prototype_map.tres:100-114 and 316-318, before the first tower, which House openings first afford on day 4; the bot castle ends night 3 at 49.6 of 70 with 2 Houses lost, the only night it loses hp). A walk-speed king with the balanced build (a slower human proxy) loses 2 of 10 runs on night 3. From night 4 on the bots keep the castle within 0.2 hp of full. Probe: +1 base gold per dawn alone makes the owner-like opening win 10 of 10 (also at walk speed); a castle attack or a 2.4 sprint relieves night 3; greedy (N4-N6) and no_build (N1-N2) keep losing in every variant.
fix: (diagnosis only; not applied) Suggested direction, non-binding: (1) a non-building dawn income field (default 0 in script, 1 in the shipped prototype map), added in RunManager._apply_dawn_payout and carried in the dawn_payout per_spot (or the VFX taught about it) so total still equals the coins that fly; (2) castle attack data on MapConfig (damage 2, range ~11 m, interval ~1.5 s, projectile ~18 m/s, defaults 0 = off) and a small TowerSystem-style attacker stepped in NightSim, with ProjectileVfx and ReplayDriver.Tally taught KIND_CASTLE; (3) king.tres sprint_multiplier 1.6 -> 2.4 (12 m/s) with test_king_movement_config.gd updated and acceleration possibly 40 -> 60; (4) land 1-3, re-run tools/playtest.sh, and touch waves only if the owner still finds it hard (night 3 east group or castle_max_health first).
verification: (diagnosis only)
files_changed: []
