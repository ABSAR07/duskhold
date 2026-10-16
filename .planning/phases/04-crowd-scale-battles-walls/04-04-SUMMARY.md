---
phase: 04-crowd-scale-battles-walls
plan: 04
subsystem: simulation
tags: [godot, gdscript, walls, wall-segments, push-out, determinism, tracer, tdd, recorder]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: CrowdBatch and the crowd_instance shader WallViews reuses (04-01), the cheap enemy step with StructureIndex, read_view and the rescan period on the Record (04-03)
  - phase: 03-king-combat-troops
    provides: SquadSystem, UnitSystem.set_position_of, the bots and the replay driver the wall tests run through
provides:
  - WallRunDef and BuildSpotDef.wall_run, the run-of-segments-per-plot schema (D-01), and EnemyDef.ignores_walls, the Phase 6 passability hook
  - data/buildings/wall.tres with three linear tiers (cost 2 / 4 / 6, 30 / 60 / 90 health per segment)
  - WallSystem (segments with their own health, version, break, free dawn restore, 4 m bucket grid), WallSolids (push-out, closest point, first-blocking) and the Pathing facade
  - PendingHits.KIND_WALL; wall_damaged, wall_segment_broken and walls_restored in SimEvents, SimSignals.ALL and SimRecorder.HANDLED
  - EnemySystem that attacks the intact segment in its way and is pushed out of intact segments; SquadSystem, King and PlaytestBot pushed out through the same Pathing.push_out
  - RunManager dawn restore (walls_restored once, before buildings_rebuilt and the payout)
  - WallViews (box pieces per tier colour, rubble slabs) in the real scene, wall plots excluded from building targets, income and models
  - tests/fixtures/fixture_map_walls.tres (the sealed ring case of D-07)
affects: [04-05 wall data on the prototype map and hold label, 04-06 flow field (builds on Pathing and WallSolids), 04-07 smart break-or-detour rule, 04-10 bot walls and the walls golden]

actuals:
  tokens: 21800
  tasks: 2
  commits: 3

plan_head_before: 778fbe09e6372afec527ed795c855dcf87f32fd2
plan_head_after: 3a5706eff107d64c8e16c18cf609d8eee5ad3278

tech-stack:
  added: []
  patterns:
    - "Sibling system for a capped class: WallSystem learns of a purchase through the building_built signal and never adds a public method to BuildingSystem"
    - "One pure solid rule shared by simulation and presentation: Pathing.push_out returns its input bit for bit with no intact segment, so maps without walls replay exactly as before"
    - "Static bucket grid keyed by integer cell coordinates over inflated segment boxes, candidates sorted ascending so every move is order-stable"
    - "Tracer first (data, system, events, recorder, views, fixture, scene test), then a RED commit and a GREEN commit for the expansion"

key-files:
  created:
    - simulation/walls/wall_run_def.gd
    - simulation/walls/wall_system.gd
    - simulation/walls/wall_solids.gd
    - simulation/nav/pathing.gd
    - data/buildings/wall.tres
    - presentation/walls/wall_views.gd
    - tests/fixtures/fixture_map_walls.tres
    - tests/unit/test_wall_system.gd
    - tests/unit/test_wall_solids.gd
    - tests/unit/test_wall_plot_isolation.gd
    - tests/unit/test_wall_blocking.gd
    - tests/integration/test_wall_determinism.gd
    - tests/integration/test_wall_dawn.gd
    - tests/e2e/test_wall_tracer_scene.gd
  modified:
    - simulation/defs/build_spot_def.gd
    - simulation/defs/enemy_def.gd
    - simulation/night/enemy_system.gd
    - simulation/night/night_sim.gd
    - simulation/night/pending_hits.gd
    - simulation/run/run_context.gd
    - simulation/run/run_manager.gd
    - simulation/buildings/building_system.gd
    - simulation/squads/squad_system.gd
    - simulation/events/sim_events.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - tools/replay/playtest_bot.gd
    - presentation/buildings/building_views.gd
    - presentation/king/king.gd
    - presentation/vfx/projectile_vfx.gd
    - presentation/debug/enemy_path_gizmo.gd
    - presentation/map/prototype_map.tscn
    - ui/overlay/night_overlay_sections.gd
    - tests/unit/test_sim_rules_guard.gd

key-decisions:
  - "WallSystem is a BuildingSystem sibling (BuildingSystem stays at its 20 public methods); a tier purchase raises every segment's maximum but refills only unbuilt and standing segments, so a broken segment stays at 0 until restore_all at dawn (D-05)"
  - "A marching enemy takes its cached castle-line blocker only while the segment is within aggro_range; a leash-range gate made the target flip between wall and clear every tick"
  - "A held target is line-tested again on the enemy's own rescan tick, not only when chosen, so a king that walks behind a wall pulls the enemy onto the wall instead of leaving it pressed against it"
  - "Pathing.push_out, WallSolids.push_out and first_blocking return their input unchanged and -1 with no intact segment, which is why smoke, army and full_idle did not move"
  - "WallSolids.first_blocking measures the nearest blocking segment by point-to-segment distance from the start of the line and queries the bucket grid with a circle around the line's midpoint (a superset of the swept box)"
  - "WallViews redraws only when WallSystem.version() changes and reuses CrowdBatch plus crowd_instance.gdshader with the glow turned down (calm_energy 0.04)"

patterns-established:
  - "Every new SimEvents signal lands with its SimSignals.ALL entry, HANDLED entry, attach connection and handler in the commit of its first emit"
  - "A kind switch in presentation (projectile target, path gizmo, overlay rows, building views) gains its KIND_WALL branch in the same commit as the kind"

requirements-completed: [BLDG-10]

coverage:
  - id: D1
    description: "Holding at a wall plot builds every segment of its run at the tier's per-segment health; each upgrade raises every segment and refills standing ones; the authored gaps never hold a segment"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_system.gd#test_one_purchase_builds_every_segment_at_the_tiers_per_segment_health"
        status: pass
      - kind: unit
        ref: "tests/unit/test_wall_system.gd#test_a_gap_stays_exactly_as_wide_as_authored"
        status: pass
      - kind: unit
        ref: "tests/unit/test_wall_system.gd#test_each_upgrade_raises_every_segment"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each segment keeps its own health: exact-remaining and overkill hits report the points lost and break once; hits on a broken, unbuilt or unknown segment drop silently; a broken segment stays broken through an upgrade until dawn"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_system.gd#test_a_hit_for_exactly_the_remaining_health_breaks_the_segment_once"
        status: pass
      - kind: unit
        ref: "tests/unit/test_wall_system.gd#test_a_broken_segment_stays_broken_through_an_upgrade_until_dawn"
        status: pass
    human_judgment: false
  - id: D3
    description: "An intact segment is solid to enemies, units, the king and the bot king; a broken or unbuilt segment and an enemy with ignores_walls are not stopped"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_solids.gd#test_a_circle_walking_straight_at_the_wall_never_gets_through"
        status: pass
      - kind: unit
        ref: "tests/unit/test_wall_blocking.gd#test_a_squad_ordered_across_a_wall_is_held_in_front_of_it"
        status: pass
      - kind: unit
        ref: "tests/unit/test_wall_blocking.gd#test_the_bot_king_is_held_in_front_of_a_wall"
        status: pass
      - kind: unit
        ref: "tests/unit/test_wall_blocking.gd#test_an_enemy_that_ignores_walls_crosses_the_line_and_never_attacks_a_segment"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_wall_tracer_scene.gd#test_the_king_dropped_on_a_segment_is_pushed_out_of_it"
        status: pass
    human_judgment: false
  - id: D4
    description: "An enemy whose line to its goal crosses an intact segment attacks it through KIND_WALL until it breaks, then walks on through the hole into the ring, in the real scene, to dawn"
    requirement: BLDG-10
    verification:
      - kind: e2e
        ref: "tests/e2e/test_wall_tracer_scene.gd#test_a_bought_ring_is_drawn_broken_into_rubble_and_walked_through"
        status: pass
      - kind: integration
        ref: "tests/integration/test_wall_determinism.gd#test_the_log_records_the_walls_being_hit_and_broken"
        status: pass
    human_judgment: false
  - id: D5
    description: "Dawn heals every hurt segment and rebuilds every broken one for free, announced once as walls_restored before buildings_rebuilt and the payout; a second restore or a dawn with nothing to restore emits nothing; the rebuilt wall blocks again on the next night"
    requirement: BLDG-10
    verification:
      - kind: integration
        ref: "tests/integration/test_wall_dawn.gd#test_dawn_restores_every_segment_once_before_the_rebuilt_list_and_the_payout"
        status: pass
      - kind: integration
        ref: "tests/integration/test_wall_dawn.gd#test_the_rebuilt_wall_blocks_again_on_the_next_night"
        status: pass
    human_judgment: false
  - id: D6
    description: "A wall plot is never a building target, never pays dawn income and has no model; its plot marker stays"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_plot_isolation.gd#test_a_built_wall_plot_is_not_a_standing_building_and_pays_nothing"
        status: pass
      - kind: e2e
        ref: "tests/unit/test_wall_plot_isolation.gd#test_the_scene_draws_no_model_for_a_wall_plot_but_keeps_its_marker"
        status: pass
    human_judgment: false
  - id: D7
    description: "Maps without a wall replay exactly as before (smoke, army, full_idle digests unchanged) and two seeded runs of the wall fixture agree while seed 2 differs"
    requirement: BLDG-10
    verification:
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json"
        status: pass
      - kind: integration
        ref: "tests/integration/test_wall_determinism.gd#test_two_runs_of_the_same_seed_give_identical_digests"
        status: pass
    human_judgment: false
  - id: D8
    description: "The wall pieces and the rubble look right in the real renderer (placeholder boxes in tier colours; the Kenney Castle Kit look and the collapse belong to plan 04-05)"
    requirement: BLDG-10
    verification: []
    human_judgment: true
    rationale: "A MultiMesh reads back zeros on the dummy renderer, so the tests assert the CPU mirror; one real-window screenshot pair (ring bought by day, ring after 13 s of night with dark rubble slabs on the west side) was inspected by the executor, but whether the placeholder look reads well is the owner's call at the Phase 4 gate"

duration: 55min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 04: Wall Tracer Summary

**A wall run is bought whole on one plot, held in segments that each keep their own health, attacked and broken segment by segment by the enemies in their way, solid to enemies, squads, the king and the bots, rebuilt free at every dawn, and invisible to every map without walls (smoke, army and full_idle digests unchanged)**

## Performance

- **Duration:** 55 min
- **Started:** 2026-10-16T05:13:18Z
- **Completed:** 2026-10-16T06:08:00Z
- **Tasks:** 2 (Task 2 as RED, GREEN)
- **Files modified:** 34 (14 created sources, tests, data and fixtures counted with 20 modified; 12 new `.uid` files not counted)

## Accomplishments

- Data and system: `WallRunDef` expands a polyline with gaps into integer-centimetre segments (the 24 m closed square gives 32 segments of 3.0 m ending on its corners; a 16 m stretch makes six equal pieces and the gap keeps its authored width; NaN, non-positive lengths and more than 200 pieces expand to nothing). `WallSystem` keeps per-segment health, a version, one-shot `wall_segment_broken`, the free `restore_all()` and a static 4 m bucket grid; `BuildingSystem` gained no public method (it stays at 20).
- Solidity: `WallSolids.push_out` leaves a circle exactly half thickness plus radius from a segment (a centre on the segment goes to its fixed left normal, three passes settle a joint), `first_blocking` returns the nearest blocking segment or -1, and `Pathing` is the facade. Enemies are pushed out after the push-apart, squads after `separate()`, the king after `move_and_slide()` and the bot king after each step, all through one function that returns its input bit for bit when no segment stands.
- Combat: `KIND_WALL` hits resolve through `damage_segment`; an enemy whose line to its goal (target, or the castle) crosses an intact segment attacks that segment until it breaks and then walks on through the hole. The marching case is cached on the Record per rescan period.
- Events and recorder: `wall_damaged`, `wall_segment_broken` and `walls_restored` are in SimEvents, `SimSignals.ALL` and `SimRecorder.HANDLED` with handlers; `walls_restored` is emitted once at dawn before `buildings_rebuilt` and the payout and never empty.
- Presentation: `WallViews` draws one box per intact segment tinted by tier and one rubble slab per broken one from two CrowdBatches, redrawn on version change; `BuildingViews` gives a wall plot no model, no stand-in and no bar and a stone-grey marker; the KIND_WALL branches of the projectile target, the path gizmo (orange) and the overlay ("To wall") are in.
- Evidence in the real scene: bought by day, 32 pieces within a second; during night 1 of the wall fixture the grunts break segments, rubble appears and an enemy walks into the ring; dawn within the 90 s bound (the e2e run takes about 19 s).

## Task Commits

1. **Task 1: Tracer, wall run to broken segment and walked-through hole** - `4eb078e` (feat)
2. **Task 2 RED: failing tests for squad, king and bot solidity and the free dawn rebuild** - `db774e5` (test)
3. **Task 2 GREEN: walls block squads, the king and the bots, dawn rebuilds every segment free** - `3a5706e` (feat)

**Plan metadata:** committed after this file (docs: complete plan). No refactor commit was needed.

## Files Created/Modified

- `simulation/walls/wall_run_def.gd` - authored run and its deterministic expansion
- `simulation/walls/wall_system.gd` - segments, health, version, break, restore, buckets (15 public)
- `simulation/walls/wall_solids.gd` - static pure push-out, closest point, first-blocking
- `simulation/nav/pathing.gd` - the steering and solidity facade (walls only for now)
- `data/buildings/wall.tres` - Wall, three tiers, cost and per-segment health only
- `presentation/walls/wall_views.gd` - pieces and rubble from the wall state
- `simulation/night/enemy_system.gd` - wall target kind, castle-line cache, push-out (18 public)
- `simulation/night/night_sim.gd` - walls, pathing, KIND_WALL resolution, `get_walls`, `get_pathing`, `restore_walls` (18 public)
- `simulation/run/run_manager.gd` - `restore_walls()` in `_enter_dawn`
- `simulation/squads/squad_system.gd`, `presentation/king/king.gd`, `tools/replay/playtest_bot.gd` - the push-out for squads, king and bots
- `tests/fixtures/fixture_map_walls.tres` - the sealed ring (castle 200 health, ring of 32 segments, eight grunts then six)
- `tests/unit/test_wall_system.gd` (17), `test_wall_solids.gd` (15), `test_wall_plot_isolation.gd` (3), `test_wall_blocking.gd` (3), `tests/integration/test_wall_determinism.gd` (3), `test_wall_dawn.gd` (5), `tests/e2e/test_wall_tracer_scene.gd` (2)

## Decisions Made

See `key-decisions` above. Readings the plan leaves open, none a deviation:

- The fixture is the plan's, unchanged: no tuning was needed. Seeds 1, 2 and 3 each breach the west side of the ring (night 1: two segments broke for seed 1), a few grunts reach the inside and the night is cleared with the castle at 200 of 200.
- The plan's "an enemy left with no target tests its line to the castle only on its own rescan tick" is implemented with an aggro-range gate on adopting the cached blocker (see key decisions); targets chosen this call are tested at once as planned.
- `test_wall_plot_isolation.gd` holds one scene-level test (the BuildingViews check); the file sits under tests/unit as the plan lists it.

## TDD Gate Compliance

Task 2 (`tdd="true"`): RED `db774e5` then GREEN `3a5706e`; no refactor commit. RED evidence was reproduced from the committed RED state and verified with `gsd-tools check tdd-red-evidence` (record built from the JUnit XML of `bash tools/test.sh -gselect=test_wall_dawn`): `RED_EVIDENCE_OK`, target test `test_dawn_restores_every_segment_once_before_the_rebuilt_list_and_the_payout` failing on its assertions (3 of 5 failed). The squad and bot-king tests of `test_wall_blocking` and the King test of `test_wall_tracer_scene` failed on their clearance assertions in RED. Two tests pass in RED by design: `test_an_enemy_that_ignores_walls_crosses_the_line_and_never_attacks_a_segment` (the enemy half of solidity was delivered by Task 1) and the two "announces nothing" dawn tests (the absence is true before and after).

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0.

## Issues Encountered

- A `bash` heredoc containing an apostrophe was refused by the tool shell twice; the files were written with the Write tool and python edit scripts instead. No effect on the result.
- The wall validation of `MapConfig` (gap width, segment caps) is plan 04-05's job (T-04-08 here is mitigated by `WallRunDef.expand()` returning nothing for bad data).

## Verification (final state, HEAD 3a5706e)

- `bash tools/test.sh`: 169 scripts, 1549 tests, 24218 asserts, exit 0 (baseline at dispatch 162 scripts, 1501 tests, 20592 asserts; +7 scripts, +48 tests). `test_wall_system`, `test_wall_solids`, `test_wall_plot_isolation`, `test_wall_blocking`, `test_wall_dawn`, `test_wall_determinism`, `test_wall_tracer_scene`, `test_sim_rules_guard`, `test_determinism`, `test_squad_lifecycle`, `test_dawn_rebuild` and `test_balance_acceptance` are in the JUnit XML. After Task 1 the same command gave 167 scripts, 1540 tests, 21454 asserts, exit 0.
- `bash tools/replay.sh`: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks) and army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks) `REPLAY_OK` against their goldens, full_idle `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` at 6941 ticks twice, after Task 1 and again after Task 2; no golden touched.
- `bash tools/lint.sh`: clean. Public functions: WallSystem 15, NightSim 18, EnemySystem 18, SquadSystem 19, BuildingSystem 20.
- Real-window check (RTX 3060 Laptop, Forward+, 1280x720): the ring renders as brown box walls; after 13 s of night the broken west segments are dark rubble slabs with grunts beside them.
- Wall fixture, seed 1 (headless): night 1 breaks segments 27 and 28 and is cleared with the castle at 200; night 2 attacks the rebuilt wall again now that dawn restores it.

## Known Stubs

None. The wall pieces are code-built boxes on purpose (the Kenney Castle Kit look, the hold label and the collapse are plan 04-05's); that is a placeholder look, not an unwired data source.

## Threat Flags

None. No new network, auth or file surface; T-04-08 (bad run data expands to nothing and is capped at 200 segments), T-04-09 (simulation/walls and simulation/nav join MATH_ROOTS, integer-centimetre geometry, recorded integers only, double-run determinism test) and T-04-10 (static bucket grid, code skipped entirely with no intact segment) are mitigated as planned.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 04-05 to 04-07 build on `Pathing` and `WallSolids`: the flow field and the smart break-or-detour rule only have to add going around behind the same calls; the sealed ring fixture stays the "no way round" case.
- BLDG-10 stays open in REQUIREMENTS.md until the plans that also declare it finish (the shared-ID gate refused it: 0 of 1 ready).
- The hold label still reads "Wall I/II/III" and the plot sits at the fixture's hand-placed position; the prototype map has no wall plot yet (plan 04-05).
- Open for the verifier (D8): one look at the placeholder wall and rubble in a real window; headless cannot read a MultiMesh back.

## Self-Check: PASSED

- Created files exist with their `.uid`: wall_run_def.gd, wall_system.gd, wall_solids.gd, pathing.gd, wall_views.gd, the six new test scripts and fixture_map_walls.tres, wall.tres.
- Commits `4eb078e`, `db774e5` and `3a5706e` are in `git log`; `git rev-list --count 778fbe0..HEAD` was 3 before this file.
- Acceptance criteria re-run: `class_name WallRunDef`, `MAX_SEGMENTS_PER_RUN: int = 200`, `func expand(`, `var wall_run: WallRunDef`, `var ignores_walls: bool = false`, three `max_health` lines 30, 60, 90, `class_name WallSystem`, `func damage_segment(`, `func restore_all(`, `static func push_out(`, `static func first_blocking(`, `KIND_WALL := &"wall"`, `damage_segment(` and `func restore_walls(` in night_sim.gd, the three signal names in sim_signals.gd and sim_recorder.gd, both MATH_ROOTS, the `WallViews` node, `restore_walls()` (line 185) before `buildings_rebuilt.emit` (line 190) in run_manager.gd, and `push_out(` in squad_system.gd, king.gd and playtest_bot.gd.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
