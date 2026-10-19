---
status: diagnosed
trigger: "UAT Phase 04, Test 13, gap G-04-7 (owner rule change, 2026-10-19): a melee enemy whose target (a tower or other building, a unit, the king) is behind a wall must break through the wall to reach it, not drop the target and march on the castle; only some enemy types introduced in later phases go for the castle directly. Ranged enemies shooting over walls stays."
created: 2026-10-19T04:45:35Z
updated: 2026-10-19T05:11:09Z
goal: find_root_cause_only
---

## Current Focus

hypothesis: The drop rule is three LOS gates in EnemySystem (king pull _can_see at enemy_system.gd:277, StructureIndex.nearest_visible via _pick_nearest_structure at :500-506, held-target drop via _target_in_sight at :268), and the KIND_WALL keep/give-up path (_keeps_breaking / _wall_ticks / wall_given_up) is keyed only on the castle (straight_ticks/detour_ticks to the castle).
bug_class: Bohrbug (deterministic rule; owner rule change, not a defect)
test: Read-only probe (scratch GDScript) that replays walls, full_idle and the with-walls bot runs and counts, per tick, melee enemies whose king pull / nearest-structure choice / held target differs because of a blocked line (the only places the new rule could act).
expecting: walls golden fixture and gate stress 0 triggers (no target within aggro across the wall); prototype map with road walls bought >0 possible (tower_1 is 5.48 m inside the west run line, edge 5.38 m from the outer face < 6 m aggro).
next_action: Diagnosis returned to the orchestrator (goal find_root_cause_only); the gap plan for G-04-7 implements the rule change.
reasoning_checkpoint:
  hypothesis: "Blocked melee targets are dropped because of three LOS gates in EnemySystem (king pull _can_see, nearest_visible, rescan _target_in_sight), and a target-wall cannot be held because the KIND_WALL keep/give-up rule is castle-keyed."
  confirming_evidence:
    - "repro: wall up -> target {} and a march to the castle; wall down -> target {building, 1}"
    - "test_los_targets 11/11 pins the drop for the king and held targets; the code paths at enemy_system.gd 266-281, 450-476, 498-517"
  falsification_test: "If removing the gates for melee did not make the grunt target the tower behind the wall, the hypothesis would be wrong (not run: no source edits in this mode)"
  fix_rationale: "Removing the gates for default melee and remembering the target behind the blocking segment addresses the rule, not a symptom"
  blind_spots: "The probe counts trigger conditions under the current rule; after the change balanced seed 2 diverges and its later ticks are not predicted; the gate stress and the stress night were reasoned about from geometry, not probed"
  candidate_causes:
    - "code: the LOS gates (confirmed)"
    - "data: a per-type flag or shipped def value forcing the castle (eliminated: EnemyDef has only ignores_walls, false everywhere)"
  and_gate: "yes, two contributing conditions: removing only the gates, a chosen tower behind the wall goes through _target_walls_in_the_way -> _take_wall (KIND_WALL), but on the next rescan _keeps_breaking compares with the castle detour, gives the segment up (wall_given_up) and the base choice re-picks the tower and re-takes the wall (wall_given_up is checked only in _breaking_is_faster, not in _take_wall): a flip-flop every rescan_ticks (15), and the target behind the wall is never remembered"

## Symptoms

expected: A melee enemy that has chosen a target (tower, building, unit, king) and finds an intact wall segment between itself and that target attacks the blocking segment, breaks it, and continues to the same target. Ranged enemies keep shooting over walls at targets within range. The castle-first behaviour becomes a per-enemy-type property for enemy types added in later phases (Phase 6 roster), not the default for every melee enemy.
actual: Plan 04-06 implemented RESEARCH Open Question 3 as "targets behind walls are dropped": a melee attacker needs a clear line to its target; a blocked target is dropped and the enemy marches on the castle (then the 04-07 break-or-detour rule applies against the walls on the castle path). 04-PLAYTEST-GATE.md assumption 8 records this; the owner has now rejected it.
errors: None reported (rule change, not a crash).
reproduction: Test 13 in UAT. Read the target choice and wall logic; a scenario with a tower behind an intact wall run and a melee grunt that would otherwise target the tower shows the enemy dropping the tower and heading for the castle.
started: Introduced by plan 04-06 (commit range of Phase 4, base 75183fe); the pre-Phase-4 code had no walls.

## Eliminated

## Evidence

- timestamp: 2026-10-19T04:57:55Z
  checked: knowledge base (.planning/debug/knowledge-base.md)
  found: does not exist; no MemPalace; no prior pattern
  implication: open-ended investigation

- timestamp: 2026-10-19T04:57:55Z
  checked: 04-06-PLAN Task 2 action 3, 04-06-SUMMARY D6, RESEARCH Pattern 8 / Open Question 3, PLAYTEST-GATE assumption 8, 04-07-PLAN Flagged Assumptions
  found: 04-06 decided "LOS-gated targets": king pull and _pick_nearest_structure accept a candidate only when first_blocking == -1 or the enemy is ranged and the edge is within attack_range; _target_valid re-checks on rescan and drops; 04-07 states "enemies with another target are line-of-sight gated (04-06), so the castle is the only goal the comparison needs" (detour/straight are castle-keyed by design)
  implication: two layers move: the LOS gates (choice + held drop) and the castle-only KIND_WALL keep/give-up arithmetic

- timestamp: 2026-10-19T04:57:55Z
  checked: simulation/night/enemy_system.gd (full read, 710 lines)
  found: |
    _choose_target (253-258) = _choose_base_target then _target_walls_in_the_way (only while _walls_are_solid and not def.ignores_walls).
    Drop gate 1, held target: _choose_base_target 266-269: on a rescan tick a valid held target that fails _target_in_sight (466-476 -> _can_see) is invalidated.
    Drop gate 2, king pull: 274-281 requires _can_see(record, king pos, body_radius).
    Drop gate 3, structures: _pick_nearest_structure 498-517 uses StructureIndex.nearest_visible(pos, aggro, pathing, radius, ranged_reach) while walls stand (ranged_reach = attack_range for projectile_speed > 0, else -1).
    _can_see 450-455: true when no wall / ignores_walls / first_blocking < 0 / _shoots_over. _shoots_over 460-463: projectile_speed > 0 and centre distance - target radius <= attack_range (the ranged-over-walls rule).
    _target_walls_in_the_way 298-326: KIND_WALL holder on rescan runs _keeps_breaking (castle-keyed) else sets wall_given_up and clears target; target-less -> _aim_at_walls (castle line, notice range, should_break); held non-wall target: wall_seg = -1, then on chosen-or-rescan _take_wall(first_blocking(pos, goal, radius), leash) unless _shoots_over -- effectively dead for melee today because every melee target already passed a clear-line test; _take_wall (404-411) REPLACES target_kind/target_id with the wall (the original target is not remembered).
    _keeps_breaking 371-375 / _breaking_is_faster 363-367 / _wall_ticks 380-385: ttd_of(segment), straight_ticks(pos -> castle), detour_ticks(pos -> castle field).
    _publish_wall_times 390-400: every living record with wall_seg >= 0 on an intact segment is counted into WallDecision.add_attacker.
    _advance_and_strike 602-652: KIND_WALL goal = closest point on the segment, stop = half_thickness + attack_range; castle_blocked marchers use pathing.march_step; every other move is desired_step (straight).
    Record 682-710: castle_blocker, castle_blocked, per_300, speed_cm, wall_seg, wall_given_up; no field remembers a target behind a wall.
  implication: the new rule needs (1) the three gates removed for melee (kept for ranged), (2) a remembered "target behind the wall" so the enemy resumes the same target after the break, and (3) a target-wall keep/release rule not driven by the castle detour

- timestamp: 2026-10-19T04:57:55Z
  checked: simulation/night/structure_index.gd, simulation/walls/wall_solids.gd, simulation/nav/pathing.gd, simulation/nav/wall_decision.gd
  found: nearest_visible (76-79) = _scan with pathing; _seen (107-112) skips a candidate whose first_blocking >= 0 unless ranged_reach >= 0 and edge <= ranged_reach; nearest() is the Phase 3 scan. WallSolids.first_blocking (52-70) returns the intact segment a circle of radius r would hit on the straight line, the one nearest `from` (ties lower index) -- exactly "the first intact segment on the straight line from enemy to target". Pathing.first_blocking (203-206) is -1 with no intact segment. Pathing.detour_ticks/straight_ticks/castle_cost_at/is_sealed are castle-only; walk_step + GoalFieldCache are the only per-goal routing (squads, bot king).
  implication: the blocking segment for a target is pathing.first_blocking(record.position, goal, record.def.radius); no new geometry is needed

- timestamp: 2026-10-19T04:57:55Z
  checked: simulation/defs/enemy_def.gd, data/enemies/grunt.tres, data/enemies/ranged.tres, tools/stress/data/stress_grunt.tres
  found: EnemyDef has ignores_walls (Phase 6 flyer hook, default false, no shipped def sets it); ranged is projectile_speed > 0 (skirmisher 14 m/s, attack_range 7, aggro 9); grunt and stress_grunt melee (projectile_speed 0, aggro 6, leash 10)
  implication: a castle-first flag belongs beside ignores_walls with default false so no shipped def carries it

- timestamp: 2026-10-19T04:57:55Z
  checked: tools/stress/stress_map.tres, tools/stress/gate_stress.gd
  found: gate harness builds only gate_wall (towers, barracks unbuilt), parks the king at (0,-60); wall plots are excluded from BuildingSystem.standing_spot_ids (building_system.gd:151), so the only target candidate is the castle at (0,0), 30 m south of the wall line z=30; test_gate_stress also asserts wall_hits == 0
  implication: the new rule cannot fire in the gate stress (no target within 6 m aggro across the wall); the castle march + 04-07 detour must stay as is so 100000-hp segments are walked round

- timestamp: 2026-10-19T05:11:09Z
  checked: reproduction, scratchpad/exec/debug-g7/repro_tower_behind_wall.gd (hand-built world in the shape of test_los_targets: wall x=102 z 80..120 tier I, shipped tower at (105,100), shipped grunt at (100,100), castle at the origin)
  found: wall up -> first_blocking = segment 6, target {} on ticks 0, 1, 15, 30, position walking diagonally to the castle (99.92,99.92) ... (97.66,97.66); wall down -> target {building, 1} every tick, walking +x to (102.8,100)
  implication: symptom reproduced: the tower 4 m (edge) away is dropped and the grunt marches on the castle

- timestamp: 2026-10-19T05:11:09Z
  checked: read-only probe scratchpad/exec/debug-g7/probe_blocked_targets.gd (replays exactly as ReplayDriver.run; before each night step with an intact segment counts, per melee enemy: a = king up within aggro and line blocked; b = StructureIndex.nearest != nearest_visible; c = held non-wall target with a blocked line; d = the same for ranged, informational; at aggro+0 and aggro+1 m)
  found: |
    Probe is read-only: walls digest bfb05fc7... (1961 ticks) and full_idle 4385f569... (6911 ticks) reproduced exactly; also bash tools/replay.sh --scenario=walls --twice --expect-file=tests/golden/walls.json -> REPLAY_OK bfb05fc7.
    walls golden scenario: a=b=c=0 at +0 and +1 m (37 wall_damaged, 2 broken, all from castle marchers).
    full_idle (balanced seed 1, west+east walls): a=b=c=0; d (ranged skipping a building behind a wall beyond its 7 m range) 21 enemy-ticks, 1 enemy.
    Sweep with walls, seeds 1-10: balanced 3, 8, 9 and army 1, 5-10 never had an intact segment at night; balanced 1, 4, 5, 6, 7, 10 and army 2, 3, 4: a=b=c=0 at exact aggro (b near-misses within +1 m in balanced 5, 7, 10 and army 2 are buildings, static, so the +0 count is exact); balanced seed 2 ONLY: a 10 enemy-ticks (1 enemy), b building 3 (1 enemy: spot index 7 = tower_3), c held king 15 (2 enemies), all night 8 at the north wall gap mouth: enemy 187 at (1.22,-61.00), inside the gap's x range -2..2 and 0.5 m north of the line z=-60.5, line to tower_3 (0,-55) grazes the gap-edge segment within half_thickness + radius = 0.9 m.
    Test fixtures: ring (fixture_map_walls) a=b=c=0 at +0 (199 enemy-ticks of 4 enemies within +1 m of tower_1 at (-6,4)); gap fixture seeds 1-4 zero; long 80 m wall (test_wall_behaviour) 12 grunts tier I seeds 1, 2, 3, 5 and 1 grunt tier I/III zero.
  implication: under a change that is a no-op whenever no melee choice or held target is blocked (and leaves ranged and the castle path alone), the walls golden, full_idle, test_wall_behaviour, test_wall_detour and the ring tests keep their behaviour; the bot sweep can move only in balanced seed 2 (night 8); the only shipped-map triggers today are gap-mouth grazes, so a naive "break the first blocking segment" would make a grunt standing in a gap chew the gap's edge segment

- timestamp: 2026-10-19T05:11:09Z
  checked: bash tools/test.sh -gselect=test_los_targets
  found: 11/11 pass today; the three that pin the drop rule are test_a_melee_enemy_does_not_target_a_king_behind_the_wall_and_marches_on (82-89), test_a_held_target_that_walks_behind_the_wall_is_dropped_on_a_rescan (100-113) and, depending on the choice design, test_a_nearer_unit_behind_the_wall_loses_to_a_farther_one_in_sight (133-139); the ranged (116, 124), no-wall (142), nearest_enemy_clear (154-199, squads) and footman/archer (202) tests stay
  implication: test_los_targets is the only suite that asserts a blocked target is dropped; test_wall_behaviour does not pin it

- timestamp: 2026-10-19T05:11:09Z
  checked: tests/fixtures/fixture_map_replay_smoke.tres and fixture_map_replay_army.tres (grep wall_run: 0 and 0); every wall branch in EnemySystem gated by _walls_are_solid() (step 167/176, _choose_target 257, _can_see 451, _pick_nearest_structure 500, _advance_and_strike 631)
  found: smoke and army never have an intact segment, so none of the wall code runs
  implication: smoke 2599c7c2 (703) and army f7a967ed (1353) stay byte-identical by construction if every new branch stays behind _walls_are_solid()

## Resolution

root_cause: |
  Deliberate 04-06 rule (RESEARCH Open Question 3), implemented as three line-of-sight gates in simulation/night/enemy_system.gd that only melee enemies fail: (1) the king pull in _choose_base_target (274-281) requires _can_see; (2) _pick_nearest_structure (498-517) asks StructureIndex.nearest_visible (structure_index.gd 76-79, filter _seen 107-112) instead of nearest() while walls stand; (3) a held target is invalidated on its rescan tick by _target_in_sight -> _can_see (266-269, 450-476). With no target the enemy falls to _aim_at_walls (333-356), the 04-07 castle-line rule. In addition the KIND_WALL machinery is castle-keyed by design (04-07 Flagged Assumption 3): _take_wall (404-411) replaces target_kind/target_id with the segment and remembers nothing, and _keeps_breaking / _breaking_is_faster / _wall_ticks (363-385) plus wall_given_up (310, 365) compare ttd with straight_ticks/detour_ticks to the castle only, so even a forced target-wall would be released toward the castle detour on the next rescan.
fix:
verification:
files_changed: []
