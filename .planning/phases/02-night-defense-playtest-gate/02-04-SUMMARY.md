---
phase: 02-night-defense-playtest-gate
plan: 04
subsystem: simulation
tags: [godot, gdscript, building-health, enemy-targeting, rubble, health-bar, gut]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: EnemySystem._choose_target, PendingHits.KIND_BUILDING, HealthBar3D, CastleState, SimRecorder (plans 02-01 and 02-03)
provides:
  - Building health from data (BuildingTierDef.max_health, BuildingDef.body_radius) with BuildingSystem health, damage_building, standing_spot_ids and spot index helpers
  - building_damaged and building_destroyed events (destroyed fires exactly once; a destroyed building pays no dawn income)
  - D-11 targeting extended to standing buildings: nearest structure by edge distance, ties to the earlier spot, castle last
  - Hurt-only health bars on buildings and a RubbleView (collapse effect, primitives only) left on the plot of a fallen building
affects: [02-05, 02-06, 02-07, 02-08, 02-09, 02-10, 02-11]

actuals:
  tokens: 11000
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Structure choice in one function (_pick_nearest_structure): smallest edge distance (centre distance minus radius) inside aggro_range, strictly-smaller replaces so spot order breaks ties and the castle, tried last, loses them"
    - "Hit events report the points actually lost (clamped), as castle_damaged and king_damaged do"
    - "Destroyed-building rubble is a Node3D in BuildingViews._views carrying meta rubble == true; the old view is renamed Collapsing_*, tweened down and freed"
    - "Optional trailing constructor/step arguments (buildings) so earlier hand-built tests keep compiling"

key-files:
  created:
    - presentation/vfx/rubble_view.gd
    - tests/unit/test_building_damage.gd
    - tests/unit/test_building_targeting.gd
    - tests/e2e/test_building_rubble.gd
  modified:
    - simulation/defs/building_tier_def.gd
    - simulation/defs/building_def.gd
    - simulation/defs/map_config.gd
    - data/buildings/house.tres
    - data/buildings/tower.tres
    - simulation/buildings/building_instance.gd
    - simulation/buildings/building_system.gd
    - simulation/night/enemy_system.gd
    - simulation/night/night_sim.gd
    - simulation/run/run_context.gd
    - simulation/events/sim_events.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - presentation/buildings/building_views.gd

key-decisions:
  - "building_damaged reports the points actually lost, so a clamped overkill reports less than the swing and event amounts sum to the health lost"
  - "Targeting is committed: a valid castle or building target is kept until it falls or the enemy is beyond leash_range; the nearest-structure search runs only when there is no valid target (per 02-03's 'between keep a valid target and the castle')"
  - "A building target's leash and aggro are measured to its edge (centre distance minus body_radius), the same rule the castle already used"
  - "The rubble view is in _views the moment the building falls (meta rubble true at once); the old model collapses beside it over COLLAPSE_SECONDS and is then freed"
  - "Building-targeting tests live in a new tests/unit/test_building_targeting.gd because test_enemy_targeting.gd already sits at gdlint's max-public-methods (20)"

patterns-established:
  - "New SimEvents signals go into SimSignals.ALL and SimRecorder (handler plus HANDLED) in the same task (continued)"
  - "TDD tasks commit a RED test commit carrying only the stubs needed to fail on assertions, then a GREEN feat commit (continued)"

requirements-completed: [BLDG-07]

coverage:
  - id: D1
    description: "Every building tier has integer max_health in data; a newly built or upgraded building stands at its tier's full health (House 8/12/16, Tower 20/30)"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_building_damage.gd#test_a_new_building_stands_at_its_tier_one_health"
        status: pass
      - kind: unit
        ref: "tests/unit/test_building_damage.gd#test_an_upgrade_stands_at_the_new_tiers_full_health"
        status: pass
    human_judgment: false
  - id: D2
    description: "A building at 1 hp stands, a hit to exactly 0 destroys it, overkill clamps at 0, building_destroyed fires once and later hits are dropped; max_health <= 0 is reported by validate()"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_building_damage.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "Several strikes on one tick destroy a House exactly once with one building_destroyed; damage events add up to the health lost; a destroyed building is not struck again, not a target and not in the dawn payout"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_building_damage.gd#test_two_strikes_on_one_tick_destroy_the_house_once"
        status: pass
      - kind: unit
        ref: "tests/unit/test_building_damage.gd#test_a_dawn_after_a_loss_pays_only_the_survivors"
        status: pass
    human_judgment: false
  - id: D4
    description: "Enemies choose the nearest of the standing buildings and the castle by edge distance inside aggro_range (inclusive); a tie goes to a building over the castle and to the earlier spot; a fallen target is dropped and the next candidate takes over; the king still pulls an enemy off a House"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_building_targeting.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "In the real scene a hurt House shows a health bar (fill = hp / max_hp) while an untouched Tower shows none; a fallen House becomes a RubbleView on its plot within COLLAPSE_SECONDS + 0.5 s, loses its bar and the old model is freed; upgrading still replaces the view and gives the new one a bar"
    requirement: BLDG-07
    verification:
      - kind: e2e
        ref: "tests/e2e/test_building_rubble.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "Whether the bars, the collapse and the rubble read clearly on screen"
    requirement: BLDG-07
    verification: []
    human_judgment: true
    rationale: "Readability is a visual judgement; the tests prove state, not looks. The screenshot tool needs a real renderer and has no building-damage shot; the owner judges it at the playtest gate."

duration: 26min
completed: 2026-10-05
status: complete
plan_head_before: a67723230df3a174dde039babcbef3fc22029f75
plan_head_after: aab1dfffba5926091f7252a00c797220d13f9ef7
commits: 4
---

# Phase 2 Plan 04: Buildings Take the Hits Summary

**Houses and towers now carry data-driven health, enemies attack the nearest building or the castle by edge distance, a building at zero falls exactly once into rubble that stays until dawn, and hurt buildings show a bar.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-10-05T08:17:56Z
- **Completed:** 2026-10-05T08:44:00Z
- **Tasks:** 2 (4 commits: RED and GREEN for each)
- **Files modified:** 22 (including `.gd.uid` files)

## Accomplishments

- **Data:** `BuildingTierDef` gained `max_health` (default 10), `attack_interval` and `projectile_speed` (the last two for plan 02-05); `BuildingDef` gained `body_radius`. `house.tres`: 8/12/16 hp, radius 1.5. `tower.tres`: 20/30 hp, interval 1.0/0.8, arrow speed 18/20, radius 1.0. `MapConfig.validate()` reports a tier whose `max_health` is 0 or less; every fixture and shipped map still validates clean.
- **BuildingSystem:** instances carry `health`, `destroyed` and `rebuilt_this_dawn` (the last for 02-06); `apply_next_tier` stands the new tier at full health; `damage_building` clamps at 0, reports the points actually lost through `building_damaged`, and emits `building_destroyed` once; a hit on an unknown, empty or destroyed spot drops silently. `standing_spot_ids`, `is_destroyed`, `health_of`, `max_health_of`, `radius_of`, `spot_index` and `spot_at_index` are the read side; `dawn_income_by_spot` skips destroyed buildings; snapshots carry the new fields.
- **Targeting:** `EnemySystem.step` takes an optional `buildings` argument (NightSim and RunContext wire it). `_pick_nearest_structure` chooses the standing building or castle with the smallest edge distance inside `aggro_range`; ties go to the earlier spot and the castle last. A building target is dropped on the next tick once it falls and the next candidate is picked immediately. The king still wins any rescan inside aggro range. `NightSim` resolves `building` hits into `damage_building(spot_at_index(id), amount)` in `(arrival_tick, seq)` order, so same-tick strikes destroy once.
- **Events:** `building_damaged` and `building_destroyed` are in `SimEvents`, `SimSignals.ALL` and `SimRecorder` (handler plus `HANDLED`); `test_determinism` is green.
- **Presentation:** `BuildingViews` attaches a hurt-only `HealthBar3D` above each model (height from the model's highest mesh point), updated on `building_damaged`. On `building_destroyed` the old view is renamed, squashed and sunk over `RubbleView.COLLAPSE_SECONDS`, then freed, and a `RubbleView` (five fixed-pattern grey-brown slabs plus a one-shot dust puff, primitives only) takes its place in `_views` with meta `rubble = true` and no bar.

## Task Commits

1. **Task 1 RED:** failing tests for building health, targets and destruction - `aad5924` (test)
2. **Task 1 GREEN:** building health, nearest-structure targeting, destruction at zero - `c7a512a` (feat)
3. **Task 2 RED:** failing tests for hurt-building bars and rubble - `5d2105f` (test)
4. **Task 2 GREEN:** bars and rubble in `BuildingViews`, full `RubbleView` - `aab1dff` (feat)

**Plan metadata:** recorded in the final docs commit.

## Verification

- Full suite after Task 2: 63 scripts, 517 tests, 0 failures (baseline 486 in 60 scripts); `bash tools/lint.sh` clean.
- `test_building_damage`, `test_building_targeting`, `test_enemy_targeting`, `test_dawn_income`, `test_building_rubble`, `test_building_models`, `test_upgrade_at_spot` and `test_determinism` are all present and passing in the JUnit XML.
- RED runs failed on assertions for the planned behavior (55 failed asserts in 13 of 16 damage tests, 8 of 11 targeting tests, 4 of 4 e2e tests; the tests that passed in RED are negative guards that hold before and after, such as "castle is nearer so the castle is chosen").
- Mutation probe: changing the castle tie-break in `_pick_nearest_structure` from `<` to `<=` made `test_building_targeting` fail on both tie tests; the code was restored (`git checkout`).
- Acceptance strings checked: `max_health = 8/12/16` in house.tres, `max_health = 20`, `attack_interval = 0.8`, `projectile_speed = 18.0` in tower.tres, `func damage_building(` and `func standing_spot_ids()`, `rebuilt_this_dawn`, both signal names in sim_signals.gd, `class_name RubbleView`, `const COLLAPSE_SECONDS`, `building_destroyed.connect` and `HealthBar3D` in building_views.gd.

## Deviations from Plan

### Auto-fixed Issues

None: no bug or blocker surfaced in existing code.

### Interface details that differ from the plan's sketch (no behavior change)

- **Targeting tests in a new file.** The plan puts the new cases in `tests/unit/test_enemy_targeting.gd`, but that file already holds the gdlint maximum of 20 public methods, so the building cases (11 tests) live in `tests/unit/test_building_targeting.gd` with its own small setup. `test_enemy_targeting.gd` is unchanged and still green, and the verify command's JUnit greps all find their suites.
- **Optional `buildings` arguments.** `EnemySystem.step(tick, castle, king, hits, buildings = null)` and `NightSim._init(..., castle = null, buildings = null)` default to null / their own `BuildingSystem`, as 02-03 did for the castle and king, so hand-built tests keep compiling.
- **`building_damaged` amount** is the points actually lost (the plan's behavior line only shows an unclamped example), matching `castle_damaged` and `king_damaged`.
- **Rubble placement.** The plan says the old view is tweened down, freed, and then the rubble put in `_views`; the rubble goes into `_views` immediately and the old model collapses beside it, so `get_view(spot)` reports `rubble == true` at the moment of destruction (the plan's behavior bound of COLLAPSE_SECONDS + 0.5 s holds with a wide margin).
- **Accessor for tests.** `BuildingViews.get_health_bar(spot_id)` and `RubbleView.get_slabs()` were added; both read-only.

---

**Total deviations:** 0 auto-fixed; 5 interface details noted above.
**Impact on plan:** none; every behavior-list case holds.

## Issues Encountered

- A first Python edit script for `map_config.gd` assumed one tab level too many and failed after the data files were already edited; the remaining edits were re-run without re-applying the data changes (checked with `git diff`, no duplicated lines).
- gdformat rewrites files to CRLF in the working tree; all scripted edits normalise to LF on write so git sees no spurious diffs.

## Known Stubs

None. The RED-phase stubs (empty `BuildingSystem` methods, `RubbleView` shell, null `get_health_bar`) were replaced by the GREEN commits.

## Threat Flags

None. T-02-08 (health data tampering) is mitigated as planned: `validate()` reports `max_health <= 0`, damage clamps at 0 and a destroyed building ignores further hits (`test_building_damage.gd`). T-02-09 (asset provenance): rubble and dust are primitives, no third-party asset was added. T-02-SC: no packages installed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Plan 02-06** can rebuild through `BuildingSystem`: `BuildingInstance.destroyed`, `health` and `rebuilt_this_dawn` exist, `dawn_income_by_spot` already skips destroyed buildings, and `BuildingViews._on_building_destroyed` leaves a `RubbleView` in `_views` for it to swap back. Two things to know: `apply_next_tier` on a destroyed building is not guarded (building is refused at night and 02-06 rebuilds at dawn, so a destroyed building never reaches a day), and `BuildingSystem` now has 18 public methods, so 02-06's four planned additions will exceed gdlint's `max-public-methods` of 20 and need a helper class or a trimmed surface.
- **Plan 02-05** can read `BuildingTierDef.attack_interval` and `projectile_speed`, `BuildingSystem.radius_of` and `standing_spot_ids` (a destroyed tower must stop shooting).
- Not run: the screenshot tool (no building-damage shot exists and it needs a real renderer), so the bars, collapse and rubble are verified by state, not by eye; the owner judges readability at the playtest gate.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*

## Self-Check: PASSED

- Created files verified present: rubble_view.gd, test_building_damage.gd, test_building_targeting.gd, test_building_rubble.gd.
- Commits `aad5924`, `c7a512a`, `5d2105f`, `aab1dff` exist; `git rev-list --count a677232..HEAD` is 4.
- Full suite: 63 scripts, 517 tests, all passing; lint clean.
