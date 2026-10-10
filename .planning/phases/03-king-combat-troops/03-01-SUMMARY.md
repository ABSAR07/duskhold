---
phase: 03-king-combat-troops
plan: 01
subsystem: simulation
tags: [godot, gdscript, squads, units, determinism, pending-hits, kenney-mini-characters]

requires:
  - phase: 02-night-combat-loop
    provides: "EnemySystem, TowerSystem, PendingHits decide-then-resolve queue, SimClock flight ticks, SimRecorder and ReplayDriver goldens"
provides:
  - "UnitDef, squad fields on BuildingTierDef/BuildingDef/MapConfig, footman/archer/barracks/archery_range data"
  - "SquadSystem, UnitSystem, Squad, SquadFormation on the fixed step; NightSim.step_day for every non-night phase"
  - "PendingHits.KIND_UNIT and enemies that target living units before buildings"
  - "unit_spawned, unit_damaged, unit_died in SimEvents, SimSignals.ALL and SimRecorder.HANDLED"
  - "UnitViews puppets (Kenney Mini Characters, sword or bow primitive) interpolated in every phase"
  - "barracks_1 and archery_1 appended after the eight Phase 1 plots; fixture_map_squads.tres"
affects: [03-02, 03-03, 03-04, 03-05, 03-06, 03-07, 03-08, 03-09, 03-10, 03-11, 03-12, phase-04-pathfinding, phase-08-animation]

actuals:
  tokens: 29600
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Pull-based squad sync: SquadSystem polls BuildingSystem tiers each step, no listener inside the simulation"
    - "Squad keyed by military spot id, created once, never deleted"
    - "Guard/commit/leash with the staggered rescan (EnemySystem.is_rescan_tick reused)"
    - "Unit puppets interpolate with RunContext.alpha() in EVERY phase (units walk by day)"

key-files:
  created:
    - simulation/defs/unit_def.gd
    - simulation/squads/squad_system.gd
    - simulation/squads/unit_system.gd
    - simulation/squads/squad.gd
    - simulation/squads/squad_formation.gd
    - presentation/units/unit_views.gd
    - data/units/footman.tres
    - data/units/archer.tres
    - data/buildings/barracks.tres
    - data/buildings/archery_range.tres
    - tests/fixtures/fixture_map_squads.tres
    - tests/unit/test_squad_guard.gd
    - tests/unit/test_enemy_targets_units.gd
    - tests/unit/test_squad_archers.gd
    - tests/integration/test_squad_determinism.gd
    - tests/e2e/test_squad_tracer_scene.gd
    - tests/e2e/test_unit_views.gd
    - assets/third_party/kenney_mini_characters/models/character-male-a.glb
    - assets/third_party/kenney_mini_characters/models/character-female-a.glb
  modified:
    - simulation/night/enemy_system.gd
    - simulation/night/night_sim.gd
    - simulation/night/pending_hits.gd
    - simulation/run/run_context.gd
    - simulation/events/sim_events.gd
    - simulation/defs/building_tier_def.gd
    - simulation/defs/building_def.gd
    - simulation/defs/map_config.gd
    - data/maps/prototype_map.tres
    - presentation/map/prototype_map.tscn
    - presentation/vfx/projectile_vfx.gd
    - presentation/debug/enemy_path_gizmo.gd
    - presentation/buildings/building_views.gd
    - ui/overlay/night_overlay_sections.gd
    - tools/replay/sim_recorder.gd
    - tests/support/sim_signals.gd
    - tests/unit/test_sim_rules_guard.gd
    - tests/unit/test_prototype_map_data.gd
    - tests/e2e/test_upgrade_at_spot.gd
    - assets/attribution.json
    - ASSETS.md

key-decisions:
  - "SquadSystem.begin_night() also fills free seats (one _sync(false)), so a building finished in the very step the night starts (the bots do this) still fields its squad; seats are otherwise only raised by day"
  - "A unit with no valid target looks for one only on its staggered rescan tick; a committed target is kept until it dies or is farther than leash_range from the squad anchor, never swapped for a nearer enemy"
  - "Enemies scan living units before buildings in _pick_nearest_structure with a strict-less compare, so a unit wins an equal-edge tie and buildings keep spot order"
  - "EnemySystem keeps the step's UnitSystem in a private field instead of widening every helper signature; null keeps Phase 2 behaviour byte for byte"
  - "UnitSystem exposes 19 public methods (gdlint cap is 20); later plans add a new file rather than raising the cap"
  - "Military plot markers get their own colour (data-driven off BuildingDef.unit_id) so the new plots are not read as House plots"

patterns-established:
  - "Squad sync by polling, in MapConfig spot order, creation order kept in an array"
  - "Test worlds put the plot on the x axis with the castle at the origin so the post and guard distances land on exact floats"
  - "A new SimEvents signal is added to SimEvents, SimSignals.ALL and SimRecorder.HANDLED in the same task"

requirements-completed: [UNIT-04]

coverage:
  - id: D1
    description: "A Barracks built by day raises a squad equal to its tier squad_size at formation slots around the post in front of the building; an Archery Range does the same; the two plots are appended after the eight Phase 1 plots"
    requirement: UNIT-04
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_guard.gd#test_a_built_barracks_raises_its_tier_squad_at_the_formation_slots"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_data.gd#test_the_first_eight_spots_are_unchanged_and_military_plots_come_after"
        status: pass
    human_judgment: false
  - id: D2
    description: "Guard, commit and leash: inclusive guard range from the anchor, lower id wins ties, a committed unit never swaps to a nearer enemy, a target past the leash is dropped and the unit walks back to its slot, strikes once per attack_interval arriving that tick"
    requirement: UNIT-04
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_guard.gd (14 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Enemies target units like structures (unit wins an equal-edge tie with a building), hits resolve through KIND_UNIT, a unit at 0 hp is removed with unit_died naming the killer kind"
    requirement: UNIT-04
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_targets_units.gd (8 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Archers stop at attack_range and fire arrows that land SimClock.flight_ticks(distance, projectile_speed) later; a dead target drops the arrow silently; a skirmisher can target and wound an archer; unit strengths follow D-06 and D-07"
    requirement: UNIT-04
    verification:
      - kind: unit
        ref: "tests/unit/test_squad_archers.gd (6 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Squads step in every phase and two in-process runs with the same seed and bot give identical digests while another seed differs; the smoke golden is byte-identical"
    requirement: UNIT-04
    verification:
      - kind: integration
        ref: "tests/integration/test_squad_determinism.gd (3 tests)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (REPLAY_OK digest 2599c7c2...)"
        status: pass
    human_judgment: false
  - id: D6
    description: "In the real scene every living unit has exactly one puppet (male-a footmen, female-a archers, sword or bow primitive) interpolated in every phase; archer arrows appear on the projectile layer"
    requirement: UNIT-04
    verification:
      - kind: e2e
        ref: "tests/e2e/test_squad_tracer_scene.gd#test_a_built_barracks_raises_four_puppets_and_the_squad_fights_the_night"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_unit_views.gd (2 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Provenance of the two new GLBs: CC0 only, owned by one attribution entry, zip hash checked, listed in ASSETS.md"
    verification:
      - kind: unit
        ref: "tests/unit/test_attribution_log.gd (17 tests)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Commit-versus-thrash readability of the guard rules and how the puppets, weapons and arrows look in play"
    verification: []
    human_judgment: true
    rationale: "The edge probe could not classify UNIT-04; the contract is pinned by tests but the owner judges how the commit behaviour reads and how the static bind-pose puppets look at the Phase 3 UAT"

duration: 39min
completed: 2026-10-10
status: complete
plan_head_before: fb2e0cd1c71c72c479834d565fc0e746facbaa46
plan_head_after: 625714aa1df79dc8c40a7c9267215f5dc20f7327
commits: 3
---

# Phase 3 Plan 01: Barracks and Archery Range Squads Summary

**Two military buildings field footman and archer squads that guard, commit, shoot and die on the deterministic fixed step in every phase, with enemies that target them, Kenney Mini Characters puppets, and an untouched smoke golden**

## Performance

- **Duration:** 39 min
- **Started:** 2026-10-10T08:22:44Z
- **Completed:** 2026-10-10T09:02:08Z
- **Tasks:** 2 (Task 1 tracer, Task 2 TDD: RED then GREEN)
- **Files modified:** 54 (including 19 new files and 2 LFS models)

## Accomplishments

- A thin, production-quality slice through every layer the army touches: data (UnitDef, squad fields on BuildingTierDef/BuildingDef/MapConfig), `SquadSystem`/`UnitSystem`/`Squad`/`SquadFormation`, `NightSim.step_day` called from `RunContext.step` in every non-night phase, `PendingHits.KIND_UNIT`, three recorded events and `UnitViews`.
- UNIT-04 guard/commit/leash on the staggered rescan, pinned with exact-float tests: guard range inclusive from the anchor, lower id wins equal distance, a committed unit never swaps, a target past the leash is dropped and the unit walks back to its slot.
- Enemies scan living units before buildings (unit wins an equal-edge tie), strike them through `KIND_UNIT`, and dead units leave in the step cleanup with `unit_died` naming the killer kind. `EnemySystem.step` without the trailing `units` argument is the Phase 2 behaviour.
- Archers stop at `attack_range` and fire arrows landing `SimClock.flight_ticks(distance, projectile_speed)` later (pale blue arrows via `ProjectileVfx`, `UNIT_ARROW_COLOR`); a skirmisher can target and wound an archer.
- `barracks_1` (-16,0,-2) and `archery_1` (16,0,-2) sit after the eight Phase 1 plots so every spot index, payout order and nearest-spot tie is unchanged; the smoke golden digest `2599c7c2...` did not move.
- Suite: 95 scripts / 836 tests at baseline to 101 scripts / 870 tests, all passing (10350 asserts), lint clean.

## Task Commits

1. **Task 1: Tracer, a Barracks squad end to end** - `4b23549` (feat)
2. **Task 2 RED: failing tests for archers, arrows and models** - `0ee6654` (test)
3. **Task 2 GREEN: archers, Mini Characters models, unit attack-kind sites** - `625714a` (feat)

Tracer gate (auto-approvable, `end-of-phase` mode, automated-only verify): the Task 1 verify (full suite, five suite names in the JUnit XML, smoke replay, lint) was re-run end to end before expansion and passed, so Task 2 proceeded.

RED evidence for Task 2: `gsd check tdd-red-evidence` returned `RED_EVIDENCE_OK` (`target_test_failed`, target `test_an_arrow_lands_exactly_flight_ticks_after_it_was_fired`, 0/6 passing on assertions about the missing archer data and archery_1 plot).

**Plan metadata:** recorded in the following docs commit.

## Files Created/Modified

- `simulation/squads/squad_system.gd` - sync with buildings, day fill, guard/commit/leash step, melee and ranged strikes, `begin_night` (also fills free seats)
- `simulation/squads/unit_system.gd` - id-addressed unit records, read API, damage, removal, friendly separation (19 public methods)
- `simulation/squads/squad.gd`, `squad_formation.gd` - squad record and pure axis-aligned slot grid
- `simulation/night/enemy_system.gd`, `night_sim.gd`, `pending_hits.gd`, `simulation/run/run_context.gd` - unit targeting, step order (spawn, king, squads, towers, castle, enemies, resolve, remove enemies, remove units), `step_day`
- `presentation/units/unit_views.gd`, `presentation/map/prototype_map.tscn` - puppets, `UnitViews` node in `run_bound`
- `presentation/vfx/projectile_vfx.gd`, `presentation/debug/enemy_path_gizmo.gd`, `ui/overlay/night_overlay_sections.gd` - `KIND_UNIT` sites
- `data/units/*.tres`, `data/buildings/barracks.tres`, `archery_range.tres`, `data/maps/prototype_map.tres`, `tests/fixtures/fixture_map_squads.tres` - data
- `assets/third_party/kenney_mini_characters/models/character-male-a.glb`, `character-female-a.glb` (+ `.import`, LFS), `assets/attribution.json`, `ASSETS.md`

## Decisions Made

See `key-decisions` above. Notable: seats filled at `begin_night` (the bots build and start the night in the same tick, so without it their squad never exists), the private `_units` field in `EnemySystem`, and unit strengths per the plan data (footman 10 hp / 1 dmg, archer 6 hp / 1 dmg / 8.5 m, barracks tiers cost 4/8/16, squads 4/8/14, respawn 10/7/4 s, building health 40/60/80).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Two Phase 1 e2e tests pinned the eight-plot map**
- **Found during:** Task 1 (first full-suite run)
- **Issue:** `tests/e2e/test_upgrade_at_spot.gd` asserted exactly 8 spots and that every non-House plot has the tower marker colour; appending `barracks_1` broke both, and the barracks marker also fell through to the House colour in `BuildingViews._marker_color`
- **Fix:** `BuildingViews` now gives military plots (non-empty `BuildingDef.unit_id`) `MILITARY_MARKER_COLOR`; the two tests now require at least the 8 Phase 1 plots and three distinct plot kinds
- **Files modified:** `presentation/buildings/building_views.gd`, `tests/e2e/test_upgrade_at_spot.gd`
- **Verification:** `test_upgrade_at_spot` 4/4, full suite green
- **Committed in:** `4b23549`

**2. [Rule 3 - Blocking] A squad built in the same step the night starts had no seats**
- **Found during:** Task 1 (writing the determinism test)
- **Issue:** the plan's bot (`build_order [barracks_1]`) builds and starts the night in one `think()`, so no day step runs and the squad (created, but not filled at night) would never field a unit; the required `unit_spawned` log line could not exist
- **Fix:** `SquadSystem.begin_night()` runs one `_sync(false)` before clearing targets and cooldowns, filling free seats; the 03-02 night respawn trickle is not affected (it only needs seats that die after the night began)
- **Files modified:** `simulation/squads/squad_system.gd` (+ `test_a_new_night_fills_a_squad_built_in_the_same_step`)
- **Verification:** `test_squad_guard`, `test_squad_determinism`
- **Committed in:** `4b23549`

**3. [Rule 1 - Bug] Archer stop assertion ignored friendly separation**
- **Found during:** Task 2 GREEN
- **Issue:** my first assertion required every archer at exactly `attack_range`; the push-apart pass nudges the archers that arrive on the same line a little closer than range, which is correct behaviour
- **Fix:** test now requires every archer within range and the rearmost archer at `attack_range`
- **Files modified:** `tests/unit/test_squad_archers.gd`
- **Committed in:** `625714a`

---

**Total deviations:** 3 auto-fixed (2 Rule 1, 1 Rule 3)
**Impact on plan:** all necessary for correctness or to reach the plan's own acceptance criteria; no scope creep. `building_views.gd` and `test_upgrade_at_spot.gd` are outside the plan's `files_modified` list.

## Issues Encountered

- Bash heredocs containing apostrophes or very long bodies were rejected by the tool shell; the larger files and edit scripts were written with the file tool instead. No effect on the result.
- `core.autocrlf` left several working files CRLF while the index is LF; edits were applied through a normalising helper, so every committed file is LF.

## Known Stubs

- `presentation/buildings/building_views.gd` primitive fallback: Barracks and Archery Range buildings draw as the House-style box (no `building_view_catalog.tres` entry yet); only the plot marker is distinct. Intentional for the tracer; a later Phase 3 plan owns the military building visuals.
- `BuildingTierDef.squad_respawn_seconds` is authored (10/7/4 s) but not read yet; the night respawn rule is plan 03-02.
- `UnitViews` puppets are static bind-pose models facing one direction with a primitive weapon; animation and facing are Phase 8.

## Threat Flags

None. No new network endpoint, auth path or trust-boundary file access: the only external input is the hash-checked CC0 zip (T-03-03), copied into scratch, never into the repo.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03-02 can add `MapConfig.validate()` rules for `UnitDef`, `squad_size` (guard constant `SquadSystem.MAX_UNITS_PER_SQUAD = 50` already exists) and the night respawn trickle on top of `SquadSystem`; `UnitSystem` has one public method of headroom (19 of 20), `SquadSystem` has 12.
- The squad `anchor` equals `home` for now; orders (plan 03-06) move it. `Squad` has no stance or queue yet by design.
- Open for the owner at UAT: guard/commit readability, puppet look, the unit and enemy numbers (plan 03-11 retunes them).

## Self-Check: PASSED

- 19 key files present on disk (all `FOUND`), including both LFS GLBs
- commits `4b23549`, `0ee6654`, `625714a` exist
- full suite 870/870 passing, smoke replay `REPLAY_OK` with the unchanged digest, `bash tools/lint.sh` clean

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-10*
