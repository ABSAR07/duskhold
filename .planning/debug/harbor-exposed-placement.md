---
status: diagnosed
trigger: "G-05-7 (Phase 5 UAT test 7): the owner wants the Fishing Harbor moved to a much more exposed position with enemy threat but not complete tower coverage, so it is a bit awkward to defend, and its health reduced a bit"
created: 2026-10-24T19:31:07Z
updated: 2026-10-24T20:00:43Z
goal: find_root_cause_only
gap_id: G-05-7
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: CONFIRMED. The Harbor is risk-free because its plot and pond were placed, by a Phase 5 plan rule, outside every enemy's notice and inside the castle arrow; nothing in the targeting code excludes it
test: done (geometry over the shipped data, the targeting and reach code read, two scratch probes running the balanced and army bots over seeds 1 to 10 with the Harbor and pond moved on a deep copy)
expecting: n/a
next_action: return ROOT CAUSE FOUND to the /gsd-plan-phase 5 --gaps caller (goal find_root_cause_only: no source, data or test file changed)
bug_class: Bohrbug (deterministic map data), a design gap not a code defect
known_pattern_candidate: none (no knowledge-base.md in .planning/debug; MemPalace not queried, absent in this checkout)
reasoning_checkpoint:
  hypothesis: "No enemy ever attacks the Harbor because harbor_1 (0, 20.5) sits 19.3 m from the west and east roads and 20.5 m from the north road (all straight spawn-to-castle lines), while a target-less enemy only takes a building whose edge is within its aggro range (grunt 6 m, skirmisher 9 m; Harbor body radius 1.5 m, so 7.5 / 10.5 m centre to centre), and the plot is inside the castle arrow's 22 m; the placement is the intended outcome of the 12 m road-clearance rule test_prototype_map_economy pins for every Phase 5 plot"
  confirming_evidence:
    - "probe on the shipped map, balanced bot seeds 1 to 10: 8 of 10 wins, 30.0 gold, Harbor built in 9 seeds, 0 strikes, 0 destroyed, 7.2 gold a run from boats (matches 05-BALANCE-REPORT.md)"
    - "same probe with only harbor_1 and the pond moved beside the west road (9.5 to 10.3 m off it): the Harbor is struck on the nights tower_1 falls (5 to 8), by west skirmishers, and destroyed 17 to 22 times over 10 runs; at 7.5 m off the road grunts strike it too"
    - "test_every_phase_five_plot_is_twelve_metres_from_every_road (MIN_ROAD_CLEARANCE_M 12, 'a grunt notices a building within 6 m, a skirmisher within 9 m') and RESEARCH E5 (Harbor (0, 20.5), every non-shrine plot at least 16.1 m from every road)"
  falsification_test: "an enemy strike on harbor_1 in a shipped-map run, or no strike after moving the plot within 10.5 m of a road; neither happened"
  fix_rationale: "move the plot and its pond into the skirmisher notice band of a road outside tower and castle reach and relax the 12 m rule for harbor_1 only; the targeting already handles the rest"
  blind_spots: "the bots never ride out to defend the Harbor (KING_DEFEND_NEAREST_THREAT stays near the castle), so the probe numbers are the undefended worst case; how awkward it feels for a human is the owner's call; the full 10-strategy sweep and the squad value ratio were not re-run"
  candidate_causes:
    - "data: harbor_1 position and pond_center/pond_radius in data/maps/prototype_map.tres (CONFIRMED, the cause)"
    - "config/test rule: the 12 m Phase 5 road clearance in test_prototype_map_economy plus the pond pins in test_pond_layout and the contract (CONFIRMED, the lock that keeps it there)"
    - "code: enemy targeting skipping economy buildings (ELIMINATED: StructureIndex holds every standing building and the moved Harbor is struck)"
  and_gate: "yes: the data placement and the test rule that pins it both have to change; neither alone exposes the Harbor (moving the plot fails the 12 m test; relaxing the test moves nothing)"

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

truth: "The owner decides whether the Harbor should be weaker or the Mine, Mill and Fields stronger, and whether the Shrine needs a nearer plot, a longer reach, a lower threshold or a different wake rule"
expected: the Fishing Harbor is a real risk-and-reward building: its income is the best in the game (one new boat each surviving dawn, 1 gold a boat, cap 3 then 5), so it should stand where enemies threaten it and towers do not fully cover it, so that defending it is a little awkward
actual: (owner, verbatim, 2026-10-25) "pass as is, but I think move the harbor into a much more exposed position that have enemy threat but not complete tower coverage so it is a bit awkward to defend or something. perhaps reduce its hp a bit too." The numbers (cost 3, caps 3 and 5, 1 gold a boat), the Mine, Mill, Fields and the Shrine plots and wake rule stay as shipped.
errors: none (a map-design gap, not a defect)
reproduction: Test 7 in .planning/phases/05-castle-center-economy-depth/05-UAT.md; the orchestrator measured in a real window that the Harbor at (0, 20.5) on the north shore of the visual-only pond (centre (0, 30), radius 8) south of the castle is never on an enemy path: four dawns with Mine, Mill, Field, Harbor and Shrine built paid +7 each with the Harbor untouched, and the balance report (05-BALANCE-REPORT.md) shows the balanced bot earning 30 gold a run, almost all from boats, with no Harbor loss recorded
started: discovered during the Phase 5 UAT on 2026-10-25 (local); the placement shipped with plan 05-08

## Eliminated
<!-- APPEND only - prevents re-investigating -->

- hypothesis: the enemy targeting filters economy buildings out (a code defect)
  evidence: StructureIndex.rebuild adds every standing building in spot order (structure_index.gd); the probe with harbor_1 moved beside the west road shows it struck and destroyed by west skirmishers and grunts
  timestamp: 2026-10-24T19:58:21Z

- hypothesis: no Harbor loss is recorded because the bots never build it
  evidence: shipped-map probe, balanced bot: harbor_1 built before night 4 or 5 in 9 of 10 seeds, 3 boats, 7.2 gold a run, 0 strikes and 0 destructions
  timestamp: 2026-10-24T19:58:21Z

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-10-24T19:31:07Z
  checked: Phase 0 knowledge base (.planning/debug/knowledge-base.md)
  found: the file does not exist; no prior resolved session covers plot placement or enemy exposure
  implication: no known-pattern candidate; investigate from the data

- timestamp: 2026-10-24T19:35:32Z
  checked: data/maps/prototype_map.tres (the whole file)
  found: 23 plots. castle_plot (0, 4.2), castle_position (0, 0) radius 3.5; house_1 (-9, 9), house_2 (9, 9), house_3 (-18, -12), house_4 (18, -12), house_5 (0, -24); tower_1 (-55, 20), tower_2 (55, 20), tower_3 (0, -55); barracks_1 (-16, -2), archery_1 (16, -2); wall_west run (-54, 38.79) to (-66.3, 4.96) gap 16..20 m, label (-58.27, 21.19); wall_east the mirror; wall_north run (-18, -60.5) to (18, -60.5) gap 16..20, label (0, -58.5); wall_ring a radius-9 ring round (0, 0) with three 4 m gaps, label (0, -6.5); gold_mine_1 (-30, 30), mill_1 (30, 28), field_1 (25.5, 30.5), field_2 (30, 33), field_3 (34.5, 30.5), harbor_1 (0, 20.5), shrine_west (-46, 30), shrine_east (46, 30). Spawns west (-66, 24), east (66, 24), north (0, -66), scatter 3 m. Nights 1 to 5 come only from west and east; north joins on nights 6 to 8. castle_attack_range 22 m. pond_center (0, 30), pond_radius 8. ground_half_extent 90. The map holds no road polyline or waypoints at all: a road is the straight spawn-to-castle segment (EconomyValidation._check_pond uses exactly that)
  implication: the three roads are straight lines into (0, 0) from the west, east and north; the whole south half (z > 0) between the two side roads is behind the castle and carries no road

- timestamp: 2026-10-24T19:35:32Z
  checked: native/src/enemy_step.cpp (choose_base_target, pick_nearest_structure, advance_and_strike), native/src/native_structures.cpp scan, simulation/night/structure_index.gd, data/enemies/grunt.tres and ranged.tres, BuildingSystem.radius_of
  found: a target-less enemy walks desired_step straight at castle_position (the route's march_step only when the castle line is blocked by an intact wall and the world is solid). It takes a structure only when target-less (or its target went invalid) via scan: edge = distance(enemy, building centre) - body_radius, taken when edge <= aggro_range and nearest. A valid target is held (only the king inside aggro overrides it). Grunt aggro 6, leash 10, speed 3.2, attack 2 every 1.0 s; Skirmisher (ranged) aggro 9, leash 12, attack range 7, 2 every 1.6 s. Harbor body_radius 1.5. So a grunt takes the Harbor from 7.5 m centre to centre and a skirmisher from 10.5 m. A building target stays valid while edge <= leash (grunt 11.5 m centre, skirmisher 13.5 m)
  implication: exposure needs the Harbor within about 7.5 m of where grunts walk, or 10.5 m of where skirmishers walk, before anything nearer (another building, the castle, the king, a unit) is taken first

- timestamp: 2026-10-24T19:35:32Z
  checked: simulation/night/tower_system.gd, data/buildings/tower.tres, castle_center.tres, data/abilities/engineers.tres, arrow_storm.tres, shrine.tres
  found: a tower shoots the nearest enemy whose centre is within attack_range of the tower plot centre: tier I 9 m, tier II 10.5 m; Engineers adds +15% tower.range (10.35 / 12.075 m). The castle arrow reaches 22 m from (0, 0) at every tier (Arrow Storm +25% = 27.5 m). An awake Shrine reaches 9 m
  implication: the shipped Harbor at 20.5 m from the castle is inside the castle arrow; a candidate must be beyond 22 m (27.5 m with Arrow Storm) of (0, 0) to be outside the keep's cover, and beyond 9 to 10.5 m of the tower plots to be outside one tower's cover

- timestamp: 2026-10-24T19:41:04Z
  checked: scratch geometry (scratchpad debugger-g7/geom.py) of every plot against the three spawn-to-castle segments, the castle and the three towers
  found: harbor_1 (0, 20.5) is 19.27 m from the west and east roads, 20.50 m from the north road (its nearest road point is the castle end) and 20.5 m from the castle centre; 55 m from tower_1 and tower_2, 75.5 m from tower_3. The towers stand ON their roads (tower_1, tower_2, tower_3 at 0.00 m), house_5 on the north road, house_1/house_2 5.4 m off the side roads, barracks/archery 7.35 m. Economy plots: gold_mine_1 17.9 m (west), mill_1 16.1, fields 16.9 to 20.8 (east), shrines 12.47 m. The west road is uncovered by tower I between road metre 20.7 and 48.2 from the spawn (tower_1 at metre 11.7, castle arrow from metre 48.2); Tower II pushes the first edge to 22.2 m, Engineers to 23.8 m, Arrow Storm pulls the castle edge to 42.7 m. West wall gap (16 to 20 m along the run) is at (-59.5, 23.8) to (-60.8, 20.0)
  implication: the Harbor is about 1.8 times the skirmisher take distance (10.5 m) and 2.6 times the grunt take distance (7.5 m) from any road, and sits inside the keep's arrow: no marcher can ever choose it and anything that wandered there would be shot by the castle

- timestamp: 2026-10-24T19:41:04Z
  checked: tests/unit/test_prototype_map_economy.gd header and test_every_phase_five_plot_is_twelve_metres_from_every_road; .planning/phases/05-castle-center-economy-depth/05-RESEARCH.md E5 and P3; 05-CONTEXT.md D-09, D-11
  found: the test pins every Phase 5 plot (harbor_1 included, PHASE_FIVE_PLOT_IDS) at >= 12 m from every spawn-to-castle segment, with the stated reason 'a grunt notices a building within 6 m, a skirmisher within 9 m'. RESEARCH E5 placed the Harbor (0, 20.5) on the north shore of a pond at (0, 30) r 8 with 'every non-shrine, non-castle plot at least 16.1 m from every road'. D-09 asks 'no plot on a road ... nothing that changes the routes or the flow field' and D-11 'the pond sits off the three roads ... the enemy paths untouched'. The same test pins the content box (|x| <= 66.3, -66 <= z <= 38.79, NavGrid layout origin (-82, -82) 82 x 67, recomputed: z max 38.79 comes from the wall runs), 3 m from every wall run and gap, and test_pond_layout pins the pond r + 10 m from every road (MIN_ROAD_CENTRE_M 18 as a literal), the Harbor within 3 m of the water's edge and on the north shore (harbor.z < pond.z)
  implication: the risk-free Harbor is the intended outcome of a plan-level rule, not a code defect; an exposed Harbor needs harbor_1 exempted from (or given its own band under) the 12 m rule, and the pond rule then forces the Harbor at least 7 m off the road when it sits on the road-facing shore (r + 10 - (r + 3))

- timestamp: 2026-10-24T19:58:21Z
  checked: scratch probes (scratchpad debugger-g7/probe.gd, probe2.gd, probe3.gd, run with bash tools/godot.sh --headless --path . -s <abs path>): ReplayDriver.run with PlaytestStrategies.make(balanced or army_balanced), seeds 1 to 10, the shipped tuning and king, on a deep copy of prototype_map.tres with harbor_1 and the pond moved and the Harbor health set; listens to building_damaged, building_destroyed, attack_fired, enemy_spawned and dawn_payout. Every copy passed map.validate() (pond rules included)
  found: shipped (0, 20.5): 8/10 wins, gold 30.0, harbor gold 7.2, 0 strikes. P1a west-south 7.5 m (-40.88, 22.85) pond (-38.39, 29.71) r 4.5: 6/10, gold 24.2, harbor gold 1.7, destroyed 23 (grunts and skirmishers). P1b 9.5 m (-40.20, 24.73): 8/10, 25.4, 2.3, destroyed 22. P1d 10.3 m (-39.93, 25.48) pond (-38.22, 30.18) r 4.5: 8/10 (lost seeds 3 and 9, as shipped), 26.4, 3.5, destroyed 18, struck only by west skirmishers and only on nights tower_1 fell (5 to 8), untouched in seeds 2 and 10. P2b west-north 9.5 m (-44.81, 6.19) pond (-47.85, -2.18) r 8: 8/10, 25.6, 2.5. P2d 10.3 m (-45.09, 5.43) pond (-47.92, -2.37) r 8: 8/10, 26.8, 3.3. P2a 7.5 m: 7/10. P2c (-50.71, 10.46), 10.5 m from tower_1 (inside Tower II reach only): 7/10, 1.3. P3a north road 8 m (-8, -40) pond (-18.6, -38.6) r 8: 7/10, 29.3, 6.4, destroyed 5, struck only from night 6 (north spawns) by north grunts and skirmishers. P4a east-north 7.5 m (44.13, 8.07): 6/10, harbor gold 0.9, destroyed from night 4 (east skirmishers). Health 14/20 instead of 18/24: P1a 7/10 destroyed 26; P1b 8/10 destroyed 24; P1d unchanged (18); P2d 8/10 destroyed 20; P3a 8/10 destroyed 8, harbor gold 5.5. army_balanced: 8/10 on shipped, P1d, P1d at 14/20, P2d and P3a alike; it buys the Harbor only on day 7 or 8 in 3 seeds, where it is destroyed at once
  implication: the targeting needs no change; the distance to a road sets the threat: about 7.5 m lets grunts take it and breaks the bar, 9.5 to 10.3 m (inside a skirmisher's 10.5 m, outside a grunt's 7.5 m) keeps 8 of 10 with the Harbor lost on most nights from night 5; the bot never defends it, so these are undefended worst cases

- timestamp: 2026-10-24T19:58:21Z
  checked: blast radius (grep of every pin of harbor_1, (0, 20.5), pond_center, pond_radius, fishing_harbor.tres and prototype_map.tres across tests, tools and fixtures; the fixture ext_resources; the Harbor model; BuildSpotDef fields)
  found: must change with a move: tests/unit/test_prototype_map_economy.gd (HARBOR_AT line 41 asserted line 219; test_every_phase_five_plot_is_twelve_metres_from_every_road covers harbor_1), tests/unit/test_economy_data_contract.gd (plot position line 259, POND_CENTER/POND_RADIUS lines 59-60 asserted 261-262, HARBOR_HEALTHS [18, 24] line 55 asserted line 237 for the health lever), tests/unit/test_pond_layout.gd (MIN_ROAD_CENTRE_M is a literal 18 = radius 8 + 10, so a smaller pond needs it derived; the north-shore assert harbor.z < pond.z holds for the P1 family only), tests/e2e/test_harbor_scene.gd (POND_CENTER (0, 30) and POND_RADIUS 8, lines 10-11, asserted 97-106), tools/screenshot/shot_economy_scenarios.gd (POND_STAND_OFFSET (-2.5, 0, 6.5) relative to the plot, DAY_STAND (0, 0, 26) absolute; re-aim both shots by eye). Unmoved: the fixture replay maps (smoke, army, walls, economy) list only Script ext_resources (inline defs); fixture_map_replay_economy.tres has its own harbor_1 at (0, 0, 22), an inline 18 hp Harbor and no pond; no fixture references fishing_harbor.tres or prototype_map.tres. test_nav_layout_pin stays (every candidate inside the content box |x| <= 66.3, -66 <= z <= 38.79), test_structure_decision_pins builds no Phase 5 plot, the ride-time test keeps its farthest pair (116.5 m, 15.5 s), tests/fixtures/trace/enemy_step_refs.txt is read by no test. full_idle (shipped map, balanced, seed 1, no golden file; CI runs it --twice) moves. The Harbor model's deck points +z (fishing_harbor_t1.tscn Deck at z 2.1, posts to z 3.4) and BuildSpotDef has no facing field, so a pond south of the Harbor (the P1 family) needs no model change; P2 and P3 put the water north or west of the deck
  implication: the change is two data files plus four test files and one shot tool; the four fixture goldens and the economy golden stay, full_idle moves (owner-sanctioned)

- timestamp: 2026-10-24T20:00:43Z
  checked: the test_balance_acceptance pins against the probe (scratchpad debugger-g7/probe3.gd and probe4.gd): BALANCED_LOST_SEEDS [3, 9], BALANCED_FIRST_LOSS_NIGHT 3, ARMY_BALANCED_LOST_SEEDS [1, 9], SHIPPED_EARLIEST_CASTLE_DAY 6, BALANCED_WALL_SEEDS_MIN 1; only the balanced and army_balanced orders list harbor_1 (playtest_strategies.gd lines 227 and 267), so the twins, greedy_economy, houses_first, towers_first and no_build are untouched by an unbuilt plot's position
  found: P1d (18/24 and 14/20 alike): balanced loses seeds 3 and 9 (night 3 for seed 9), castle bought first on day 6 (seeds 1, 2, 4, 5, 7, 10), day 7 and 8 in two seeds, walls bought in 3 seeds (6 shipped); army_balanced loses seeds 1 and 9 as shipped. P1b, P2b and P2d also lose exactly 3 and 9; P3a at 18/24 loses 3, 8 and 9 (breaks the lost-seed pin while inside the 7 to 8 bar) and at 14/20 loses 3 and 9; P1a, P2a, P2c and P4a lose extra seeds
  implication: at the 9.5 to 10.3 m band the shipped order (harbor_1 fifth) keeps every balance pin without the Harbor surviving; the gold the Harbor no longer pays comes out of walls and tower upgrades, not out of wins; the full 10-strategy sweep and the squad value ratio still need the planner's real run

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: harbor_1 at (0, 20.5) and its pond at (0, 30) r 8 sit behind the castle (south, where no road runs), 19.3 m from the west and east roads and 20.5 m from the north road, and inside the castle arrow's 22 m; enemies march straight from their spawn to the castle and only take a building whose edge is within aggro_range (grunt 6 m, skirmisher 9 m; with the Harbor's 1.5 m body that is 7.5 / 10.5 m centre to centre), so no enemy can ever choose it; and that placement is locked in by the Phase 5 rule that every new plot keeps 12 m from every road (test_prototype_map_economy, RESEARCH E5, 'a grunt notices a building within 6 m, a skirmisher within 9 m'), written to keep the D-09/D-11 'enemy paths untouched' promise and the D-08 same-outcomes regeneration
fix: (not applied: goal find_root_cause_only; /gsd-plan-phase 5 --gaps plans the change)
verification: (diagnosis only) shipped-map probe 0 strikes in 10 seeds; moved-plot probes show strikes and the bar
files_changed: []
