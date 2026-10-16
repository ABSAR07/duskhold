---
phase: 04-crowd-scale-battles-walls
plan: 06
subsystem: pathing
tags: [godot, gdscript, nav-grid, flow-field, dial, pathfinding, walls, line-of-sight, goal-cache, determinism, tracer, tdd]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: Pathing facade, WallSystem.version(), WallSolids, the cached castle_blocker and the sealed ring fixture (04-04); the four prototype wall plots and WallValidation (04-05); StructureIndex and TargetQuery.living_within (04-03)
provides:
  - NavTuning and data/tuning/nav_tuning.tres (seven pathing numbers), MapConfig.nav_tuning, referenced by the prototype map
  - NavGrid (blocked mask and segment owners over the map's content, capped at 40000 cells), FlowField (integer Dial field, steps 10 and 14, lazy bilinear directions) and GoalFieldCache (8 goal fields, one build per tick)
  - Pathing.refresh() once per changed step, field_version(), castle_field(), is_sealed(), castle_cost_at(), march_step(), walk_step(), new_goal_cache(), goal_key()
  - Enemies that follow the castle field through the gaps and attack the segment only when sealed
  - Line-of-sight-gated targets (EnemySystem, StructureIndex.nearest_visible, TargetQuery.nearest_enemy_clear)
  - Squads and the bot king routed through the gaps; WallValidation reports a grid over the cap and out-of-range pathing numbers
  - tests/fixtures/fixture_map_walls_gap.tres
affects: [04-07 break-or-detour rule (reads castle_cost_at and the sealed test), 04-08 overlay and gate stress, 04-09 rebuild probe, 04-10 bot walls and the walls golden]

actuals:
  tokens: 26200
  tasks: 2
  commits: 3

plan_head_before: 4642f8c488a07883ea7ffe90be466f4ada872133
plan_head_after: 8d3dc6931ee0f19ef953e6473516709a3a0289af

tech-stack:
  added: []
  patterns:
    - "Dial's algorithm on a ring of 15 buckets over flat parallel arrays; a field is a pure function of the grid, so two builds give identical cost arrays"
    - "A blocked mask made leak-free by also blocking the first cell of every grid move that cuts a segment's centre line, with joint extension, instead of widening the band"
    - "Exact-preserving fallbacks: every new walk, target and bot-king path returns the Phase 3 expression bit for bit when no segment stands"
    - "Per-caller bounded caches: the squads' GoalFieldCache lives in Pathing, the bot king's in the bot, the line-test cache in SquadSystem"

key-files:
  created:
    - simulation/defs/nav_tuning.gd
    - data/tuning/nav_tuning.tres
    - simulation/nav/nav_grid.gd
    - simulation/nav/flow_field.gd
    - simulation/nav/goal_field_cache.gd
    - tests/fixtures/fixture_map_walls_gap.tres
    - tests/unit/test_nav_tuning_contract.gd
    - tests/unit/test_nav_grid.gd
    - tests/unit/test_flow_field.gd
    - tests/unit/test_goal_field_cache.gd
    - tests/unit/test_los_targets.gd
    - tests/unit/test_map_nav_validation.gd
    - tests/integration/test_wall_detour.gd
  modified:
    - simulation/defs/map_config.gd
    - data/maps/prototype_map.tres
    - simulation/nav/pathing.gd
    - simulation/night/enemy_system.gd
    - simulation/night/night_sim.gd
    - simulation/night/structure_index.gd
    - simulation/night/target_query.gd
    - simulation/squads/squad_system.gd
    - simulation/walls/wall_validation.gd
    - tools/replay/playtest_bot.gd
    - tests/unit/test_wall_blocking.gd

key-decisions:
  - "The plan's centre-distance rasterisation leaks at 2 m cells (the gap fixture's wall sits exactly between two columns of centres, 1.0 m from each, outside the 0.9 m band, so nothing was blocked); NavGrid also blocks the first cell of every move that properly cuts a segment's centre line, with a 0.02 m extension at shared joints so a move through a joint cannot slip between two touching segments"
  - "Pathing.is_sealed is true while walls stand and no castle field exists (unarmed grid, or not refreshed yet) as well as when the cell is unreached, so a map over the cell cap keeps the 04-04 behaviour of attacking the segment in the way"
  - "A position in a blocked cell reads the cheapest open neighbour for cost_at, and a blocked cell's direction points at its cheapest open neighbour, so an enemy pressed against a wall is never mistaken for a sealed one"
  - "The grid-cap and pathing-number checks run only for maps that have a wall plot, because a map with no wall never builds a grid; the new checks live in WallValidation, with bounds_margin, goal_margin and goal_quantum ranges added beside the four the plan lists"
  - "A ranged enemy's held target that is behind a wall but within attack range is shot over the wall instead of the enemy attacking the segment (the 04-04 rule would have taken the wall)"

patterns-established:
  - "A reader of a field never trusts the grid's masks before rebuild(): FlowField.direction_at and GoalFieldCache.field_for check NavGrid.is_ready()"
  - "Over-budget requests degrade for one tick, not for ever: GoalFieldCache returns null (or a still-valid older field) and the caller takes the straight step"

requirements-completed: [ENMY-04]

coverage:
  - id: D1
    description: "NavTuning data holds the seven pathing numbers, a fresh NavTuning reads like the shipped data, the prototype map references nav_tuning.tres and a map with none gets the defaults"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_nav_tuning_contract.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "The nav grid blocks the cells within half thickness plus agent radius of an intact segment, also blocks the moves that cut a wall between two columns of centres, keeps the 4 m gap open, opens a broken segment after a rebuild, never leaks through a ring at 45, 30 degrees or any axis-aligned offset at 1, 2 and 3 m cells, and is capped at 40000 cells without allocating"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_nav_grid.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Dial field: goal cells cost 0, steps 10 and 14, a cell behind the wall pays for the detour through the gap, a walled-off region is INF_COST with no direction, directions beside the wall bend toward the gap, following the field from the spawn crosses the wall line inside the gap, two builds give identical cost arrays"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_flow_field.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every enemy of the gap fixture's night that crosses the wall line does so inside the gap (z 2 to 6), none hits a wall, the night clears, the same seed repeats the same crossings, the sealed ring is still broken into, two breaks in one tick rebuild the field once, and a map with no wall (or an unbought run) builds no field"
    requirement: ENMY-04
    verification:
      - kind: integration
        ref: "tests/integration/test_wall_detour.gd#test_every_enemy_crosses_the_wall_line_inside_the_gap"
        status: pass
      - kind: integration
        ref: "tests/integration/test_wall_detour.gd#test_a_sealed_ring_still_gets_broken_into"
        status: pass
      - kind: integration
        ref: "tests/integration/test_wall_detour.gd#test_two_breaks_in_one_tick_rebuild_the_field_once"
        status: pass
      - kind: integration
        ref: "tests/integration/test_wall_detour.gd#test_a_map_with_no_wall_plot_builds_no_field"
        status: pass
    human_judgment: false
  - id: D5
    description: "Smoke, army and full_idle replay twice with unchanged digests: no field, grid, line test or route runs where no segment stands"
    requirement: ENMY-04
    verification:
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=full_idle --twice"
        status: pass
    human_judgment: false
  - id: D6
    description: "Targets behind an intact wall are dropped: a melee enemy does not take or keep a king, unit, building or castle target without a clear line, a ranged one also within attack range; a melee unit takes an enemy only with a clear line, an archer regardless; with no wall every choice is the Phase 3 one"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_los_targets.gd"
        status: pass
    human_judgment: true
    rationale: "RESEARCH Open Question 3 was decided as recommended, and whether enemies that ignore a unit just behind a wall feel right is the owner's call at the UAT"
  - id: D7
    description: "A squad ordered beyond the run and the bot king holding a point beyond it cross the wall line inside the gap and arrive; with the goal-field budget spent a unit takes the straight step for that tick only; walk_step is the exact straight step on a clear line or with no wall"
    requirement: ENMY-04
    verification:
      - kind: integration
        ref: "tests/integration/test_wall_detour.gd#test_a_squad_ordered_beyond_the_wall_walks_through_the_gap_and_arrives"
        status: pass
      - kind: integration
        ref: "tests/integration/test_wall_detour.gd#test_the_bot_king_holding_a_point_beyond_the_wall_reaches_it_through_the_gap"
        status: pass
      - kind: integration
        ref: "tests/integration/test_wall_detour.gd#test_with_the_field_budget_spent_a_unit_takes_the_straight_step_for_that_tick_only"
        status: pass
    human_judgment: false
  - id: D8
    description: "GoalFieldCache shares fields inside a goal-quantum square, builds one per tick, evicts the oldest past 8, refreshes after 0.5 s and drops every field on a grid rebuild; validate() reports a nav grid over 40000 cells and out-of-range pathing numbers"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_goal_field_cache.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_map_nav_validation.gd"
        status: pass
    human_judgment: false

duration: 56 min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 06: Everyone on the Ground Goes Round Walls Summary

**An integer Dial castle field over a leak-free nav grid sends enemies through the authored gaps (sealed ones still break in), melee targets behind walls are dropped, squads and the bot king route on a bounded goal-field cache, an oversized grid is refused, and smoke, army and full_idle replay byte-identical**

## Performance

- **Duration:** 56 min
- **Started:** 2026-10-16T07:20:20Z
- **Completed:** 2026-10-16T08:16:00Z
- **Tasks:** 2 (Task 1 the tracer, Task 2 as RED, GREEN)
- **Files modified:** 35 in the plan range (13 created sources, tests and data, 11 modified, 11 new `.uid` files)

## Accomplishments

- Grid and field (ENMY-04, D-04, D-05): `NavGrid` covers the map's content plus a 10 m margin at 2 m cells; the prototype map has **5494 cells**, far under the 40000 cap. `FlowField` is Dial's algorithm over a 15-slot bucket ring and flat arrays (10 and 14, no diagonal past a blocked orthogonal neighbour, every cell finalised once), with lazily computed directions blended bilinearly. `Pathing.refresh()` runs at the start of `NightSim.step` and `step_day`, rebuilds only when `WallSystem.version()` changed and builds nothing while no segment stands.
- Enemies: a target-less marcher whose line to the castle is blocked and who is not sealed follows `Pathing.march_step` through the gap; a sealed one (unreached cell, or no field at all) attacks the segment as in 04-04. On the gap fixture every crossing of the wall line in nights with seeds 1 to 4 lies in z 2 to 6, no `wall_damaged` is recorded and the night clears; the same seed repeats the same crossings.
- Sight (RESEARCH Open Question 3, decided): while a wall stands a melee enemy chooses or keeps a king, unit, building or castle target only with a clear line, a ranged one also while the target's edge is within its attack range (and then shoots over the wall rather than attacking the segment). A held target is line-tested again on its rescan tick. `StructureIndex.nearest_visible` and `TargetQuery.nearest_enemy_clear` pay a line test only for a candidate that would improve the best.
- Squads and the king: every unit walk goes through `Pathing.walk_step` with a per-unit cached line test (repeated only when the goal changes goal-quantum square or on the unit's rescan tick); the bot king routes on a `GoalFieldCache` of its own and keeps the exact `move_toward` on a clear line. A squad ordered to (-25, 0) and the bot king both cross the gap and arrive; with the one-per-tick build budget spent a unit takes the straight step for that tick and is routed on the next.
- Cap and validation (T-04-13, T-04-15): `WallValidation` reports `nav grid of N cells exceeds 40000` and every NavTuning number outside its range (cell 0.5 to 8 m, cache 1 to 32, builds 1 to 4, refresh 0.1 to 10 s, plus margin, goal margin and quantum).

## Task Commits

1. **Task 1: Tracer, enemies go round walls on an integer castle field and sealed ones break in** - `a88f87f` (feat)
2. **Task 2 RED: failing tests for sight-gated targets, routed squads and king, the goal cache and the grid cap** - `67941cb` (test)
3. **Task 2 GREEN: sight-gated targets, squads and the bot king routed through the gaps, and the grid cap** - `8d3dc69` (feat)

**Plan metadata:** committed after this file (docs: complete plan). No refactor commit was needed.

## Files Created/Modified

- `simulation/defs/nav_tuning.gd`, `data/tuning/nav_tuning.tres` - the seven pathing numbers
- `simulation/nav/nav_grid.gd` - blocked mask, owners, crossing rule, cell cap (14 public)
- `simulation/nav/flow_field.gd` - Dial field, directions, cost reads (7 public)
- `simulation/nav/goal_field_cache.gd` - bounded goal fields (3 public)
- `simulation/nav/pathing.gd` - refresh, castle field reads, march_step, walk_step, caches (15 public)
- `simulation/night/enemy_system.gd` - field marching, sealed attack, sight gating (18 public, unchanged)
- `simulation/night/structure_index.gd`, `target_query.gd` - `nearest_visible`, `nearest_enemy_clear`
- `simulation/squads/squad_system.gd`, `tools/replay/playtest_bot.gd` - routed walks
- `simulation/walls/wall_validation.gd` - grid cap and tuning ranges
- `tests/fixtures/fixture_map_walls_gap.tres` - castle (0,0), run (-20,-10) to (-20,10) with a gap at 12 to 16 m, tower_1 at (-8,0,3), spawn west (-30,0)
- Tests: `test_nav_tuning_contract` (4), `test_nav_grid` (12), `test_flow_field` (9), `test_goal_field_cache` (7), `test_los_targets` (11), `test_map_nav_validation` (9), `test_wall_detour` (12)

## Decisions Made

See `key-decisions` above. Readings the plan leaves open, none a deviation:

- The researcher's F5 no-leak finding covered 45 degree walls and 1 m cells only; at 2 m cells an axis-aligned wall 1.0 m from two columns of centres is outside a 0.9 m band, which is exactly the gap fixture, so the crossing rule below was added (see Deviations).
- The wall decision cadence and stuck seconds are 04-07's; NavTuning stays extensible and its contract test pins the seven values here.
- `castle_blocked` is refreshed with the cached `castle_blocker` on the rescan tick, while the sealed test (`is_sealed`) is read every tick for the wall-attack choice, since it is a single cell lookup.
- The rebuild hitch is not measured here (plan 04-09's `--rebuilds` probe does it). The only size figure recorded is the prototype map's grid: 5494 cells.

## TDD Gate Compliance

Task 2 (`tdd="true"`): RED `67941cb`, GREEN `8d3dc69`; no refactor commit. RED evidence was built from the JUnit XML of `bash tools/test.sh -gselect=test_los_targets` (exit 1) and verified with `gsd-tools check tdd-red-evidence`: `RED_EVIDENCE_OK`, target test `test_a_melee_enemy_does_not_target_a_king_behind_the_wall_and_marches_on` failing on its assertions (6 of 11 failed). The RED commit carries stubs (`GoalFieldCache`, `Pathing.walk_step` and `new_goal_cache`, `TargetQuery.nearest_enemy_clear`) so the new tests parse and fail on assertions; in `test_goal_field_cache` some tests also failed on a null dereference of the stub, with the first tests failing on assertions. RED also failed on `test_wall_detour` (squad and king arrival, routed step), `test_map_nav_validation` (no error reported) and the footman case; three tests there pass in RED by design. GREEN made all four suites pass. A mutation probe (nearest_enemy_clear swapped back to nearest_enemy in SquadSystem) failed the footman test again, and one for Task 1 (field marching disabled) failed four detour tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The centre-distance blocked rule leaks at 2 m cells**
- **Found during:** Task 1 (first test_nav_grid run)
- **Issue:** The plan blocks a cell when its centre lies within half_thickness + inflate (0.9 m) of a segment. On the gap fixture the wall at x = -20 sits exactly 1.0 m from the columns of centres at -21 and -19, so no cell was blocked and the field would have led enemies through the middle of the wall (the researcher's no-leak probe covered a 45 degree wall at any cell size, and axis-aligned walls at 1 m cells only).
- **Fix:** Besides the plan's rule, `NavGrid` blocks the first cell of every move to a forward neighbour (east, south, south-east, south-west, both cells open) that properly crosses a segment's centre line; a segment is lengthened by 0.02 m at an end it shares with another intact segment so a move through a joint is caught. A touch of a free end does not count, so a 4 m gap with 2 m cells keeps an open row at every grid alignment.
- **Files modified:** `simulation/nav/nav_grid.gd`, `tests/unit/test_nav_grid.gd`
- **Verification:** test_nav_grid pins the plan's band rule on a shifted square, the new rule on the gap fixture, and no leak into a 45 degree diamond at 1, 2 and 3 m cells, into 8 shifts of an axis-aligned square at 2 m and into a 30 degree rectangle. With the crossing pass disabled three of those tests fail, so they discriminate.
- **Committed in:** `a88f87f`

**2. [Rule 3 - Blocking] test_wall_blocking asserted that a squad is held in front of the wall**
- **Found during:** Task 2 (GREEN, full-suite pre-check)
- **Issue:** The 04-04 test asserted that units ordered across a straight run never cross its line; this plan deliberately routes squads round it, so they now go round an end of the run.
- **Fix:** The test keeps the clearance assertion and now requires that a unit whose x is past the line went round an end first (its z has reached the run's half length).
- **Files modified:** `tests/unit/test_wall_blocking.gd`
- **Verification:** 3 of 3 pass; the sealed-ring bot king test is unchanged and still passes.
- **Committed in:** `8d3dc69`

**3. [Rule 3 - Blocking] test_map_wall_validation is at the 20-test cap**
- **Found during:** Task 2 (RED)
- **Issue:** The plan adds a case to `test_map_wall_validation.gd`, which already holds 20 tests (the project cap per script).
- **Fix:** The grid-cap case and the tuning-range cases live in a new `tests/unit/test_map_nav_validation.gd` (9 tests); `test_map_wall_validation.gd` is untouched and still runs.
- **Files modified:** `tests/unit/test_map_nav_validation.gd`
- **Committed in:** `67941cb`

---

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking)
**Impact on plan:** The first is a correctness fix without which the field would have led enemies through walls on the plan's own fixture; the others are test housekeeping. No scope creep.

## Issues Encountered

- A first draft of the footman test put the wall between the barracks post and the enemy, but the squad's units stand on the castle side of their plot, so they were legitimately on the enemy's side; the wall moved to x = -3 and the enemy to (-1.5, 0).
- The first routed-step assertion ("more north than the straight step") was a wrong guess about the field's slope; it now asserts that the routed step differs from the straight one and is one full step long.
- Several files in the working copy had CRLF endings; edits were made with the file's own line ending and `gdformat` normalised them, so diffs stay LF.
- The assert total varies between full runs (25102 after Task 1, 24780 after Task 2, 24679 at dispatch) because e2e tests loop on frame conditions; the test count only grows.

## Verification (final state, HEAD 8d3dc69)

- `bash tools/test.sh`: 180 scripts, 1668 tests, 24780 asserts, exit 0 (baseline at dispatch 173 scripts, 1604 tests, 24679 asserts; +7 scripts, +64 tests). After Task 1 alone: 177 scripts, 1637 tests, 25102 asserts. `test_nav_tuning_contract`, `test_nav_grid`, `test_flow_field`, `test_goal_field_cache`, `test_los_targets`, `test_map_nav_validation`, `test_wall_detour`, `test_map_wall_validation`, `test_wall_determinism`, `test_wall_tracer_scene`, `test_wall_blocking`, `test_sim_rules_guard`, `test_squad_point_orders`, `test_enemy_targeting` and `test_spatial_index` are in the JUnit XML.
- `bash tools/replay.sh`: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks) and army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks) REPLAY_OK against their goldens, full_idle `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` (6941 ticks) twice; after Task 1 and again after Task 2; no golden touched.
- `bash tools/lint.sh`: clean. Public functions: Pathing 15, NavGrid 14, FlowField 7, GoalFieldCache 3, EnemySystem 18, SquadSystem 19 (unchanged), StructureIndex 3.
- Tracer gate: the Task 1 verify was run end to end on the tree that was committed (full suite, the three replays, lint); "Tracer verified end-to-end, expanding".
- Prototype map nav grid: 5494 cells (cap 40000).

## Known Stubs

None. The RED-commit stubs were replaced in GREEN.

## Threat Flags

None. No new network, auth or file surface. T-04-13 (grid bounds from content, refused above 40000 and reported by validate), T-04-14 (one rebuild per changed step, pinned by the two-breaks test), T-04-15 (cache size, builds per tick and ranges validated) and T-04-16 (integer costs, insertion-ordered cache, `simulation/nav` scanned by the rules guard, three replays unchanged) are mitigated as planned.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 04-07 can add the break-or-detour rule on `Pathing.castle_cost_at` and `is_sealed`; NavTuning takes its cadence and stuck fields beside the seven here.
- Plan 04-09 should measure the rebuild hitch with its `--rebuilds` probe (the grid is 5494 cells on the prototype map; not measured here).
- Plan 04-10 owns the bots buying walls and the one deliberate golden regeneration; until then no replay map has an intact segment, which is why no digest moved.
- ENMY-04 stays open in REQUIREMENTS.md until plans 04-07 and 04-08 (which also declare it) finish.
- Open for the verifier (D6): the owner judges at the UAT whether dropping targets behind a wall feels right.

## Self-Check: PASSED

- Created files exist with their `.uid` where Godot makes one: nav_tuning.gd, nav_tuning.tres, nav_grid.gd, flow_field.gd, goal_field_cache.gd, fixture_map_walls_gap.tres and the seven test scripts.
- Commits `a88f87f`, `67941cb` and `8d3dc69` are in `git log`; `git rev-list --count 4642f8c..HEAD` was 3 before this file.
- Acceptance criteria re-run: `class_name NavGrid` and `MAX_NAV_CELLS: int = 40000`, `class_name FlowField` and `INF_COST: int = 1 << 30`, `func refresh(`, `func march_step(`, `func is_sealed(`, `_pathing.refresh()` in both `step` and `step_day`, `cell_size = 2.0` in nav_tuning.tres and `nav_tuning.tres` in prototype_map.tres, `class_name GoalFieldCache` and `func field_for(`, `func walk_step(` and `func new_goal_cache(`, `static func nearest_enemy_clear(`, `func nearest_visible(`, `walk_step(` in squad_system.gd and playtest_bot.gd, `MAX_NAV_CELLS` in wall_validation.gd, and the three replays with unchanged digests.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
