# Stat modifiers (META-08)

Every bonus in the game (castle abilities, the Shrine buff, and later perks, mutators and research)
is a stat modifier, and every modifier goes through one stack, `StatStack`
(`simulation/stats/stat_stack.gd`). No consumer multiplies a stat by hand. This document is the
written contract; `tests/unit/test_stat_contract.gd` fails if the formula line or the rounding
sentence below disappears, and `test_stat_stack.gd` and `test_stat_combined.gd` pin the numbers.

## Formula

For one stat, the stack holds three buckets filled by named sources:

```
final = (base + sum(flat)) * (1 + sum(percent) / 100) * product(multiplier / 100)
```

The order in which sources were added never changes a result, only the bucket a modifier sits in
does. `base` is the value the game already had for that stat (a tier's data value, the king's
definition): building upgrades keep their per-tier values as the base the stack applies to.

A stat with no modifier returns its base untouched, bit for bit, so an empty stack moves no number
and no replay digest.

## Buckets and units

| Bucket | Unit of `value` | Example | Meaning |
|--------|-----------------|---------|---------|
| FLAT | the stat's own unit (hit points, gold, metres, seconds) | `+2` on tower damage | added to the base first |
| PERCENT | whole percent | `+25` is +25% | all percents are summed, then applied once |
| MULTIPLIER | percent of x1 (100 is x1) | `150` is x1.5, `75` is x0.75, `200` is x2 | each multiplier is applied on its own, last |

Modifiers are integers in the `.tres` data (`StatModifierDef`: a stat id, a bucket, a value).
Two +20% percents are one +40%, not 1.2 times 1.2; two x1.5 multipliers are x2.25.

## Rounding

Integer stats are computed exactly and rounded once, half up, at the end; a stat whose base is 1 or more never falls below 1.

Details:

- The result is one exact integer fraction, `(base + flat) * (100 + percent) * m1 * m2 ...` over
  `100 * 100^k` for `k` multipliers, rounded half up in a single step. There is no rounding per
  bucket and none per modifier, which is what makes pickup order irrelevant.
- A stat whose base is 0 or less never falls below 0.
- If `base + sum(flat)` is negative it counts as 0 before the percent and multipliers apply.
- Float stats (ranges, intervals, seconds) are not rounded: `(base + flat) * (1.0 + percent / 100.0)`
  times each `multiplier / 100.0`, using only `+ - * /`.
- Ties go up: base 3 with +50% is 5 (4.5), base 6 with +25% is 8 (7.5), two x1.5 multipliers on
  base 10 give 23 (22.5).

Worked example: base 3, a +1 flat source and a x2 multiplier source give `(3 + 1) * 2 = 8`, whether
the flat source or the multiplier source was added first. Base 10 with +2 flat and +50% gives 18;
with a x2 multiplier as well it gives 36.

## Sources

A source is a named list of modifiers (a castle ability, the Shrine synergy, a perk).

- `add_source(source_id, mods)` gives a source its list. A source id added again **replaces** its
  earlier list; it never stacks twice. It returns false and changes nothing when any modifier is
  refused (see Limits).
- `remove_source(source_id)` drops the source; an unknown id changes nothing and emits nothing.
- `changed(stats)` fires once per add or remove with the sorted ids of the stats whose sums moved
  (not for a no-op). A handler can read `previous_int_value` for the value before the change; the
  health stats use this to raise current health by the gain of the maximum.
- `is_modified`, `modified_stats` and `sums_of` are read-only views used by the debug overlay's
  Stats section.

## Registry

Only registered stat ids are accepted (`simulation/stats/stat_ids.gd`). Each is read at the point the
game already read the raw value.

| Stat id | Kind | Read by |
|---------|------|---------|
| `king.max_health` | int | `KingState.get_max_health` (`simulation/king/king_state.gd`) |
| `king.attack_damage` | int | `KingState._passive_attack` |
| `king.slam_damage` | int | `KingState.resolve_ability` |
| `king.damage_taken` | int | `KingState.take_damage` |
| `king.attack_interval` | float | `KingState._passive_attack` |
| `unit.max_health` | int | `UnitSystem.spawn` and the dawn heal (`simulation/squads/unit_system.gd`); unit bars in `presentation/units/unit_views.gd` |
| `unit.attack_damage` | int | `SquadSystem` hit enqueue (`simulation/squads/squad_system.gd`) |
| `squad.respawn_seconds` | float | `SquadSystem` respawn assignment |
| `building.max_health` | int | `BuildingSystem._max_health_of` (`simulation/buildings/building_system.gd`) |
| `wall.max_health` | int | `WallSystem.on_building_built` (`simulation/walls/wall_system.gd`) |
| `tower.damage` | int | `TowerSystem.step` (`simulation/night/tower_system.gd`) |
| `tower.range` | float | `TowerSystem.step` |
| `shrine.damage` | int | `TowerSystem.step`, for a Shrine (plan 05-09) |
| `shrine.range` | float | `TowerSystem.step`, for a Shrine (plan 05-09) |
| `castle.max_health` | int | `CastleState` (`simulation/castle/castle_state.gd`) |
| `castle.arrow_damage` | int | `CastleState.arrow_damage`, read by `CastleAttack` |
| `castle.arrow_range` | float | `CastleState.arrow_range`, read by `CastleAttack` |
| `castle.base_income` | int | `CastleState.base_income`, paid by `RunManager` at dawn |

The stack is global per stat id: one `tower.damage` for every tower. Per-tower stats wait for the
tower specialisations of a later phase.

## Limits

`add_source` refuses a whole source (applies none of it) when any of these holds:

- a modifier names a stat id that is not registered;
- a FLAT value is outside -100000..100000;
- a PERCENT value is outside -90..1000, or a stat's percent sum would leave -90..1000;
- a MULTIPLIER value is outside 10..400, or a stat would carry more than 4 multipliers.

`|base + sum(flat)|` is clamped to 100000 before multiplying. With these limits the largest product
is `100000 * 1100 * 400^4 = 2.8e18`, below the int64 maximum of 9.2e18, so no read can overflow.
A later phase that widens a limit must recheck this bound. A removal can leave a raw percent sum
below -90 (when a positive source leaves); the sum is clamped to -90..1000 when read.
