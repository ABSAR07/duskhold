---
phase: 05-castle-center-economy-depth
plan: 01
subsystem: simulation
tags: [godot, gdscript, stat-modifiers, stat-stack, determinism, debug-overlay, gut]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: frozen replay goldens, native step behind unchanged GDScript APIs, BuildingSystem/KingState/UnitSystem at the public-method cap
provides:
  - "StatStack: the one bucketed modifier stack (flat, percent, multiplier) with a single half-up rounding, named sources, limits and a changed signal"
  - "StatModifierDef (data) and StatIds (registry of 18 legal stat ids with kind and label)"
  - "docs/STAT_MODIFIERS.md: the written stacking order, pinned by test_stat_contract"
  - "Every modifiable stat (king, units, squads, buildings, walls, tower, castle, dawn base income) read through RunContext.stat_stack, identity while empty"
  - "Health refresh rule: a raised maximum lifts current health by the gain, never beyond the maximum"
  - "CastleState.arrow_damage/arrow_range/arrow_interval/arrow_speed/base_income; RunManager without base_dawn_income"
  - "Stats section in the F3 debug overlay (read-only)"
affects: [05-02 castle tiers and cards, 05-09 shrine, phase-06 tower specialisations, phase-10 perks and mutators, phase-12 research]

actuals:
  tokens: 27000
  tasks: 2
  commits: 3
plan_head_before: ac2d363b25ac5ba79d8944cd5d69fd47fd082871
plan_head_after: 48c4438230cfa48e9ab6268e6b16a11b7eae6025

tech-stack:
  added: []
  patterns:
    - "Every bonus is a StatModifierDef list under a named source id handed to StatStack.add_source; a consumer never multiplies by hand"
    - "Trailing optional stat_stack constructor parameter; a null stack becomes an empty private StatStack, so every older call site behaves as before"
    - "Health-owning classes connect StatStack.changed to a private handler and apply int_value minus previous_int_value as the gain"
    - "Sorted id lists go through StatIds.sorted (Array.sort on StringName is not alphabetical)"

key-files:
  created:
    - simulation/stats/stat_stack.gd
    - simulation/stats/stat_modifier_def.gd
    - simulation/stats/stat_ids.gd
    - docs/STAT_MODIFIERS.md
    - ui/overlay/stat_overlay_sections.gd
    - tests/unit/test_stat_stack.gd
    - tests/unit/test_stat_contract.gd
    - tests/unit/test_stat_combined.gd
    - tests/unit/test_stat_consumers.gd
    - tests/unit/test_stat_refresh.gd
    - tests/integration/test_stat_tracer.gd
  modified:
    - simulation/run/run_context.gd
    - simulation/run/run_manager.gd
    - simulation/night/night_sim.gd
    - simulation/night/tower_system.gd
    - simulation/night/castle_attack.gd
    - simulation/king/king_state.gd
    - simulation/squads/unit_system.gd
    - simulation/squads/squad_system.gd
    - simulation/buildings/building_system.gd
    - simulation/walls/wall_system.gd
    - simulation/castle/castle_state.gd
    - presentation/units/unit_views.gd
    - ui/overlay/debug_overlay.gd
    - tests/unit/test_sim_rules_guard.gd
    - tests/unit/test_debug_overlay_night_sections.gd

key-decisions:
  - "StatStack keeps the plan's API names and signatures exactly (add_source, remove_source, has_source, source_ids, int_value, float_value, previous_int_value, is_modified, modified_stats, sums_of, changed) so plan 05-02 can build on it"
  - "The percent sum is clamped to -90..1000 when read, because a removal can leave a raw sum below -90 (two -80 sources stay legal only while a positive source offsets them)"
  - "All sorted id lists use StatIds.sorted (String comparison); Array.sort() on Array[StringName] came out non-alphabetical in this engine build"
  - "Multiplier text is built by StatModifierDef.multiplier_text so 200 reads x2 and 150 reads x1.5 (String.num(2.0) prints 2.0)"
  - "King, unit, building, wall and castle refresh compute the gain as int_value minus previous_int_value (wall uses its stored maximum), emit no damage or heal event, and leave a downed king, a fallen building and a broken segment at 0"
  - "Unit bars follow unit.max_health through ctx.stat_stack in unit_views (research P7) and re-set the native bar maximum when the stat changes"

patterns-established:
  - "Identity first: with an empty stack every consumer returns the exact old value, proven by four byte-identical replays and the gate stress"
  - "The overlay reads the stack only through modified_stats, sums_of and int_value/float_value, never a write method"

requirements-completed: [META-08]

coverage:
  - id: D1
    description: "One pure StatStack applies flat, percent and multiplier buckets in a fixed order with one half-up rounding, clamp to 1, limits and order-independent pickup"
    requirement: META-08
    verification:
      - kind: unit
        ref: "tests/unit/test_stat_stack.gd (19 tests) and tests/unit/test_stat_combined.gd (12 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The stacking order is documented and a contract test fails if the formula or rounding sentence is lost"
    requirement: META-08
    verification:
      - kind: unit
        ref: "tests/unit/test_stat_contract.gd (7 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every modifiable stat is read through the stack: tower (tracer), king, unit, squad, building, wall, castle and dawn base income, identical to the old value with no source"
    requirement: META-08
    verification:
      - kind: integration
        ref: "tests/integration/test_stat_tracer.gd (7 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_stat_consumers.gd (13 tests)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh smoke, army, walls with --expect-file and full_idle --twice (digests unchanged); bash tools/gate_stress.sh --twice"
        status: pass
    human_judgment: false
  - id: D4
    description: "A raised maximum lifts current health by the gain, a hurt thing stays hurt, a broken wall segment and a fallen building stay down, removal clamps"
    requirement: META-08
    verification:
      - kind: unit
        ref: "tests/unit/test_stat_refresh.gd (10 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The F3 overlay lists each modified stat with base and final value, read-only"
    requirement: META-08
    verification:
      - kind: integration
        ref: "tests/integration/test_stat_tracer.gd#test_the_stats_rows_list_a_modified_stat_with_base_and_final_and_none_after_removal"
        status: pass
    human_judgment: true
    rationale: "The row text is asserted, but how the Stats block reads in the live overlay window is a look-and-feel judgment left to the end-of-phase check"

duration: 65min
completed: 2026-10-21
status: complete
---

# Phase 5 Plan 01: Stat Stack Summary

**One documented, order-independent stat-modifier stack (flat, percent, multiplier, a single half-up rounding) that every modifiable stat in the game now reads through, with the four replay digests and the gate stress unchanged**

## Performance

- **Duration:** about 65 min (started about 10:08Z, completed 2026-10-21T11:13Z; the start was not stamped, estimated from the first command and the two 11 to 12 min full-suite runs)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd consumers and refresh)
- **Files modified:** 36 (11 created, 15 modified source and test files, plus 10 `.gd.uid` files)
- **Commits:** 3 task commits (feat tracer, test RED, feat GREEN)

## Accomplishments

- `StatStack` computes `final = (base + sum(flat)) * (1 + sum(percent) / 100) * product(multiplier / 100)` as one exact integer fraction rounded once, half up; a base of 1 or more never falls below 1; a stat with no modifier returns its base untouched, so an empty stack moves no number. Sources are named, a source id added again replaces its earlier list, and a refused source (unknown stat, out-of-range value, a fifth multiplier, a percent sum outside -90..1000) changes nothing.
- `docs/STAT_MODIFIERS.md` writes the order down (Formula, Buckets and units, Rounding, Sources, Registry, Limits, the int64 bound `1e5 * 1100 * 400^4 = 2.8e18`); `test_stat_contract` fails if the formula line, the rounding sentence, a heading or a registered id is lost.
- The tower reads `tower.damage` and `tower.range` through the stack (tracer, end to end through `RunContext -> NightSim -> TowerSystem`), and the king (health, damage, slam, attack interval, damage taken), units (health, damage), squads (respawn seconds), buildings, wall segments, castle (health, arrow damage and reach, base income) and the dawn base income all read through it at the point they read the def value.
- Raised maxima lift current health by the gain (a hurt House at 7/12 becomes 13/18, a broken segment stays broken, a fallen House stays at 0 until the dawn rebuild); removing the source lowers the maximum and clamps to at least 1 for a standing thing. No damage or heal event is emitted by a refresh.
- The F3 overlay gained a read-only Stats section (`tower.damage: 3 -> 5`, or the bucket sums where no single base exists).
- `RunManager` lost `base_dawn_income` (now 8 parameters, the freed slot is available to plan 05-06); `CastleState` gained `arrow_damage`, `arrow_range`, `arrow_interval`, `arrow_speed`, `base_income` (12 public methods).

## Task Commits

1. **Task 1: Tracer, stack + registry + document + tower read + Stats overlay** - `6952eb5` (feat)
2. **Task 2 RED: failing consumer/refresh tests and the combined cases** - `e0948bb` (test)
3. **Task 2 GREEN: every consumer through the stack, refresh rule** - `48c4438` (feat)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Verification (measured)

- Precondition before the first edit: `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (matches RESEARCH E3).
- After Task 1 and again after Task 2 (identical lines both times):
  - `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c2...` (expect-file golden)
  - `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967ed...` (golden)
  - `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7...` (golden)
  - `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`
- Gate stress after Task 2: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdb...`, identical on both runs.
- Full suite after Task 1: 228 scripts / 2121 tests / 55213 asserts, exit 0. After Task 2: **231 scripts / 2156 tests / 55729 asserts, exit 0** (baseline 225 / 2088 / 55320; +6 scripts, +68 tests: stack 19, contract 7, tracer 7, combined 12, consumers 13, refresh 10). The assert total is timing dependent in some e2e scripts (the Task 1 run counted fewer asserts than the baseline despite +204 new ones); every test passed in every run and the cause was not chased.
- `bash tools/lint.sh`: clean (384 files). `grep -c '^func [a-z]'` prints 20 for king_state, unit_system and building_system (no public method added).

## TDD record (Task 2)

- RED (`e0948bb`): `test_stat_consumers` (13 tests) and `test_stat_refresh` (10 tests) failed to load with `Parse Error: Too many arguments for "new()" call` on every consumer constructor that was about to gain the trailing `stat_stack` parameter, so the failure is a load error and not a per-assertion failure (it would classify as INVALID_RED under the strict reading of tdd.md; this plan is `type: execute`, not `type: tdd`, so no red-evidence gate applies). `test_stat_combined` (12 tests) passed at once, as it pins the stack Task 1 already built.
- GREEN (`48c4438`): consumers 13/13, refresh 10/10, combined 12/12 on the first run after wiring.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Array.sort() on StringName is not alphabetical**
- **Found during:** Task 1 (test_stat_stack, sorted source ids came out `[c, d, a, b]`)
- **Issue:** `Array[StringName].sort()` orders by interned name, not alphabetically, so "sorted" lists of stat and source ids would differ between runs.
- **Fix:** `StatIds.sorted(ids)` sorts through String and every sorted result (`all`, `source_ids`, `modified_stats`, the `changed` payload) uses it; test_stat_contract checks alphabetical order by String comparison.
- **Files modified:** simulation/stats/stat_ids.gd, simulation/stats/stat_stack.gd, tests/unit/test_stat_contract.gd
- **Committed in:** 6952eb5

**2. [Rule 1 - Bug] String.num(2.0) prints "2.0"**
- **Found during:** Task 1 (effect text for a x2 multiplier)
- **Fix:** `StatModifierDef.multiplier_text` prints whole multipliers as integers ("x2") and others via String.num ("x1.5"); the overlay uses it.
- **Files modified:** simulation/stats/stat_modifier_def.gd, ui/overlay/stat_overlay_sections.gd
- **Committed in:** 6952eb5

**3. [Rule 3 - Blocking] Existing overlay order test pinned the section list**
- **Found during:** Task 1 (test_debug_overlay_night_sections expected `Squads, Walls, Field, Crowd`)
- **Fix:** the expected order now lists `Stats` right after `Squads`, as the plan registers it.
- **Files modified:** tests/unit/test_debug_overlay_night_sections.gd
- **Committed in:** 6952eb5

**4. [Rule 3 - Blocking] gdlint counts before_each as a public method**
- **Found during:** Task 1 (test_stat_stack had 20 tests + before_each = 21 public functions, cap 20)
- **Fix:** the modifier-resource text test moved from test_stat_stack to test_stat_contract (stack 19 tests, contract 7).
- **Committed in:** 6952eb5

**5. [Rule 2 - Missing critical] Percent sum clamped when read**
- **Found during:** Task 1 design (a removal can leave a raw percent sum below -90 when a positive source that offset several negatives leaves)
- **Fix:** `int_value` and `float_value` clamp the percent sum to -90..1000 when evaluating; `sums_of` still reports the raw sums. Documented in docs/STAT_MODIFIERS.md (Limits) and pinned by test_stat_combined.
- **Committed in:** 6952eb5

---

**Total deviations:** 5 auto-fixed (2 bug, 2 blocking, 1 missing critical). **Impact on plan:** none on scope; the API names and behaviour listed in the plan's interfaces block are unchanged.

## Decisions Made

See key-decisions above. Also: `CastleAttack` keeps its `map` parameter and `_map` field (unused now) so its constructor and the many existing tests are untouched; `CastleState` reads the map live, so a test that edits `castle_attack_*` after construction still disarms the castle.

## Issues Encountered

None blocking. Two minor environment notes: a Python heredoc turned a `\r` escape into a real carriage return (replaced with `String.chr(13)`), and edits to files with multi-level tabs were done through scripts written with the Write tool so indentation survived.

## Known Stubs

None. `shrine.damage`, `shrine.range` and `castle.arrow_range`'s base for later tiers are registered in `StatIds` and documented, but their consumers arrive in plans 05-09 and 05-02 (registration ahead of use, not a stub in this plan's goal).

## Known Limitations (carried to later plans)

- `ui/world/spot_label_model.gd` ("%d segments, %d health each") and `BuildingTierDef.effect_line()` still print the tier's base numbers, not the stacked ones. No source exists yet in the shipped game, so nothing disagrees today; plan 05-02 (cards and labels) should read the stack when it shows numbers.
- The stack is global per stat id (one `tower.damage` for every tower), as the plan's Flagged Assumptions say.

## Threat Flags

None: the Stats overlay and unit_views only call read methods (`modified_stats`, `sums_of`, `int_value`, `float_value`), pinned by `test_collecting_the_stats_rows_never_writes_the_stack`.

## Next Phase Readiness

- Plan 05-02 (castle tiers and cards) can call `ctx.stat_stack.add_source(choice_id, choice.modifiers)` and read `CastleState` getters; the API is exactly as the plan's interfaces block.
- `RunManager._init` has 8 of 10 parameters (one freed for plan 05-06); `BuildingSystem`, `UnitSystem` and `KingState` are still at the 20 public-method cap, so later plans must add only private helpers there.
- `docs/STAT_MODIFIERS.md` registry must be updated in the same task whenever a stat id is added (test_stat_contract enforces it).

## Self-Check: PASSED

All created files exist, commits 6952eb5, e0948bb and 48c4438 exist, `StatOverlaySections.register(` is in debug_overlay.gd, `"res://simulation/stats"` is in MATH_ROOTS, `var stat_stack: StatStack` is in run_context.gd, and docs/STAT_MODIFIERS.md contains `rounded once, half up`. Both tasks' verify chains were run (full suite, four replays, gate stress, lint).

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-21*
