---
phase: 05-castle-center-economy-depth
reviewed: 2026-10-22T09:55:05Z
depth: standard
files_reviewed: 279
files_reviewed_list:
  - .github/workflows/ci.yml
  - ASSETS.md
  - assets/first_party/card_icons/arrow_storm.svg
  - assets/first_party/card_icons/arrow_storm.svg.import
  - assets/first_party/card_icons/commander.svg
  - assets/first_party/card_icons/commander.svg.import
  - assets/first_party/card_icons/engineers.svg
  - assets/first_party/card_icons/engineers.svg.import
  - assets/first_party/card_icons/golden_age.svg
  - assets/first_party/card_icons/golden_age.svg.import
  - assets/first_party/card_icons/headsmans_edge.svg
  - assets/first_party/card_icons/headsmans_edge.svg.import
  - assets/first_party/card_icons/iron_discipline.svg
  - assets/first_party/card_icons/iron_discipline.svg.import
  - assets/first_party/card_icons/masons.svg
  - assets/first_party/card_icons/masons.svg.import
  - assets/first_party/card_icons/master_builders.svg
  - assets/first_party/card_icons/master_builders.svg.import
  - assets/first_party/card_icons/prosperity.svg
  - assets/first_party/card_icons/prosperity.svg.import
  - assets/first_party/card_icons/royal_training.svg
  - assets/first_party/card_icons/royal_training.svg.import
  - assets/first_party/card_icons/war_horns.svg
  - assets/first_party/card_icons/war_horns.svg.import
  - assets/first_party/card_icons/warded_mail.svg
  - assets/first_party/card_icons/warded_mail.svg.import
  - data/abilities/arrow_storm.tres
  - data/abilities/commander.tres
  - data/abilities/engineers.tres
  - data/abilities/golden_age.tres
  - data/abilities/headsmans_edge.tres
  - data/abilities/iron_discipline.tres
  - data/abilities/masons.tres
  - data/abilities/master_builders.tres
  - data/abilities/prosperity.tres
  - data/abilities/royal_training.tres
  - data/abilities/war_horns.tres
  - data/abilities/warded_mail.tres
  - data/buildings/archery_range.tres
  - data/buildings/barracks.tres
  - data/buildings/castle_center.tres
  - data/buildings/field.tres
  - data/buildings/fishing_harbor.tres
  - data/buildings/gold_mine.tres
  - data/buildings/house.tres
  - data/buildings/mill.tres
  - data/buildings/shrine.tres
  - data/buildings/tower.tres
  - data/buildings/wall.tres
  - data/maps/prototype_map.tres
  - docs/STAT_MODIFIERS.md
  - input/build_hold_controller.gd
  - input/card_picker.gd
  - input/card_picker.gd.uid
  - input/command_key_controller.gd
  - presentation/buildings/building_view_catalog.tres
  - presentation/buildings/building_views.gd
  - presentation/buildings/models/castle_center_t2.tscn
  - presentation/buildings/models/castle_center_t3.tscn
  - presentation/buildings/models/castle_center_t4.tscn
  - presentation/buildings/models/field_t1.tscn
  - presentation/buildings/models/fishing_harbor_t1.tscn
  - presentation/buildings/models/fishing_harbor_t2.tscn
  - presentation/buildings/models/gold_mine_t1.tscn
  - presentation/buildings/models/mill_t1.tscn
  - presentation/buildings/models/mill_t2.tscn
  - presentation/buildings/models/mill_t3.tscn
  - presentation/buildings/models/shrine_t1.tscn
  - presentation/environment/pond_view.gd
  - presentation/environment/pond_view.gd.uid
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/units/unit_views.gd
  - presentation/vfx/projectile_vfx.gd
  - simulation/buildings/building_system.gd
  - simulation/buildings/choice_ledger.gd
  - simulation/buildings/choice_ledger.gd.uid
  - simulation/castle/castle_state.gd
  - simulation/commands/build_intent.gd
  - simulation/commands/build_requirements.gd
  - simulation/commands/build_requirements.gd.uid
  - simulation/commands/command_processor.gd
  - simulation/defs/build_requirement_validation.gd
  - simulation/defs/build_requirement_validation.gd.uid
  - simulation/defs/build_spot_def.gd
  - simulation/defs/building_def.gd
  - simulation/defs/building_tier_def.gd
  - simulation/defs/castle_validation.gd
  - simulation/defs/castle_validation.gd.uid
  - simulation/defs/choice_def.gd
  - simulation/defs/choice_def.gd.uid
  - simulation/defs/choice_validation.gd
  - simulation/defs/choice_validation.gd.uid
  - simulation/defs/economy_validation.gd
  - simulation/defs/economy_validation.gd.uid
  - simulation/defs/map_config.gd
  - simulation/economy/income_state.gd
  - simulation/economy/income_state.gd.uid
  - simulation/events/sim_events.gd
  - simulation/king/king_state.gd
  - simulation/night/castle_attack.gd
  - simulation/night/night_sim.gd
  - simulation/night/tower_system.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - simulation/squads/squad_system.gd
  - simulation/squads/unit_system.gd
  - simulation/stats/stat_ids.gd
  - simulation/stats/stat_ids.gd.uid
  - simulation/stats/stat_modifier_def.gd
  - simulation/stats/stat_modifier_def.gd.uid
  - simulation/stats/stat_stack.gd
  - simulation/stats/stat_stack.gd.uid
  - simulation/walls/wall_system.gd
  - tests/e2e/e2e_support.gd
  - tests/e2e/test_build_denied.gd
  - tests/e2e/test_building_models.gd
  - tests/e2e/test_card_digit_handover.gd
  - tests/e2e/test_card_digit_handover.gd.uid
  - tests/e2e/test_card_mouse.gd
  - tests/e2e/test_card_mouse.gd.uid
  - tests/e2e/test_card_row.gd
  - tests/e2e/test_card_row.gd.uid
  - tests/e2e/test_castle_gate.gd
  - tests/e2e/test_castle_gate.gd.uid
  - tests/e2e/test_castle_three_picks.gd
  - tests/e2e/test_castle_three_picks.gd.uid
  - tests/e2e/test_castle_views.gd
  - tests/e2e/test_castle_views.gd.uid
  - tests/e2e/test_gold_mine_scene.gd
  - tests/e2e/test_gold_mine_scene.gd.uid
  - tests/e2e/test_harbor_scene.gd
  - tests/e2e/test_harbor_scene.gd.uid
  - tests/e2e/test_mill_fields_scene.gd
  - tests/e2e/test_mill_fields_scene.gd.uid
  - tests/e2e/test_rebuilt_economy_marker.gd
  - tests/e2e/test_rebuilt_economy_marker.gd.uid
  - tests/e2e/test_shrine_look.gd
  - tests/e2e/test_shrine_look.gd.uid
  - tests/e2e/test_shrine_scene.gd
  - tests/e2e/test_shrine_scene.gd.uid
  - tests/e2e/test_spot_label.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/e2e/test_wall_views.gd
  - tests/fixtures/fixture_map_castle.tres
  - tests/fixtures/fixture_map_gate.tres
  - tests/fixtures/fixture_map_replay_economy.tres
  - tests/fixtures/fixture_map_shrine.tres
  - tests/golden/economy.json
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_report.gd
  - tests/integration/test_balance_report_castle.gd
  - tests/integration/test_balance_report_castle.gd.uid
  - tests/integration/test_build_flow.gd
  - tests/integration/test_dawn_payout_economy.gd
  - tests/integration/test_dawn_payout_economy.gd.uid
  - tests/integration/test_economy_destroyed.gd
  - tests/integration/test_economy_destroyed.gd.uid
  - tests/integration/test_economy_replay_golden.gd
  - tests/integration/test_economy_replay_golden.gd.uid
  - tests/integration/test_field_independence.gd
  - tests/integration/test_field_independence.gd.uid
  - tests/integration/test_shrine_destroyed.gd
  - tests/integration/test_shrine_destroyed.gd.uid
  - tests/integration/test_shrine_night.gd
  - tests/integration/test_shrine_night.gd.uid
  - tests/integration/test_stat_tracer.gd
  - tests/integration/test_stat_tracer.gd.uid
  - tests/integration/test_upgrade_flow.gd
  - tests/support/sim_signals.gd
  - tests/unit/test_ability_data.gd
  - tests/unit/test_ability_data.gd.uid
  - tests/unit/test_bot_card_picks.gd
  - tests/unit/test_bot_card_picks.gd.uid
  - tests/unit/test_bot_defers_locked.gd
  - tests/unit/test_bot_defers_locked.gd.uid
  - tests/unit/test_build_choice.gd
  - tests/unit/test_build_choice.gd.uid
  - tests/unit/test_build_requirement_validation.gd
  - tests/unit/test_build_requirement_validation.gd.uid
  - tests/unit/test_build_requirements.gd
  - tests/unit/test_build_requirements.gd.uid
  - tests/unit/test_build_spot.gd
  - tests/unit/test_card_icons.gd
  - tests/unit/test_card_icons.gd.uid
  - tests/unit/test_card_row_model.gd
  - tests/unit/test_card_row_model.gd.uid
  - tests/unit/test_castle_data_contract.gd
  - tests/unit/test_castle_data_contract.gd.uid
  - tests/unit/test_castle_label.gd
  - tests/unit/test_castle_label.gd.uid
  - tests/unit/test_castle_tiers.gd
  - tests/unit/test_castle_tiers.gd.uid
  - tests/unit/test_choice_validation.gd
  - tests/unit/test_choice_validation.gd.uid
  - tests/unit/test_dawn_rebuild.gd
  - tests/unit/test_debug_overlay_night_sections.gd
  - tests/unit/test_economy_data_contract.gd
  - tests/unit/test_economy_data_contract.gd.uid
  - tests/unit/test_economy_overlay_sections.gd
  - tests/unit/test_economy_overlay_sections.gd.uid
  - tests/unit/test_economy_validation.gd
  - tests/unit/test_economy_validation.gd.uid
  - tests/unit/test_fishing_harbor.gd
  - tests/unit/test_fishing_harbor.gd.uid
  - tests/unit/test_gate_data_contract.gd
  - tests/unit/test_gate_data_contract.gd.uid
  - tests/unit/test_gold_mine.gd
  - tests/unit/test_gold_mine.gd.uid
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_mill_fields.gd
  - tests/unit/test_mill_fields.gd.uid
  - tests/unit/test_nav_layout_pin.gd
  - tests/unit/test_nav_layout_pin.gd.uid
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_playtest_strategies_castle.gd
  - tests/unit/test_playtest_strategies_castle.gd.uid
  - tests/unit/test_pond_layout.gd
  - tests/unit/test_pond_layout.gd.uid
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_prototype_map_economy.gd
  - tests/unit/test_prototype_map_economy.gd.uid
  - tests/unit/test_prototype_map_walls.gd
  - tests/unit/test_replay_cli_args.gd
  - tests/unit/test_shot_list.gd
  - tests/unit/test_shot_list_gate.gd
  - tests/unit/test_shot_list_gate.gd.uid
  - tests/unit/test_shrine.gd
  - tests/unit/test_shrine.gd.uid
  - tests/unit/test_shrine_plots.gd
  - tests/unit/test_shrine_plots.gd.uid
  - tests/unit/test_shrine_synergy.gd
  - tests/unit/test_shrine_synergy.gd.uid
  - tests/unit/test_shrine_validation.gd
  - tests/unit/test_shrine_validation.gd.uid
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spot_label_locked.gd
  - tests/unit/test_spot_label_locked.gd.uid
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_stat_combined.gd
  - tests/unit/test_stat_combined.gd.uid
  - tests/unit/test_stat_consumers.gd
  - tests/unit/test_stat_consumers.gd.uid
  - tests/unit/test_stat_contract.gd
  - tests/unit/test_stat_contract.gd.uid
  - tests/unit/test_stat_refresh.gd
  - tests/unit/test_stat_refresh.gd.uid
  - tests/unit/test_stat_stack.gd
  - tests/unit/test_stat_stack.gd.uid
  - tests/unit/test_structure_decision_pins.gd
  - tools/playtest.sh
  - tools/replay.sh
  - tools/replay/balance_report.gd
  - tools/replay/playtest_bot.gd
  - tools/replay/playtest_strategies.gd
  - tools/replay/replay_driver.gd
  - tools/replay/replay_scenarios.gd
  - tools/replay/sim_recorder.gd
  - tools/screenshot.sh
  - tools/screenshot/shot_army_scenarios.gd
  - tools/screenshot/shot_crowd_scenarios.gd
  - tools/screenshot/shot_economy_scenarios.gd
  - tools/screenshot/shot_economy_scenarios.gd.uid
  - tools/screenshot/shot_scenarios.gd
  - ui/hud/dawn_no_income_marker.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
  - ui/overlay/economy_overlay_sections.gd
  - ui/overlay/economy_overlay_sections.gd.uid
  - ui/overlay/stat_overlay_sections.gd
  - ui/overlay/stat_overlay_sections.gd.uid
  - ui/world/card_row.gd
  - ui/world/card_row.gd.uid
  - ui/world/card_row_model.gd
  - ui/world/card_row_model.gd.uid
  - ui/world/spot_label.gd
  - ui/world/spot_label.tscn
  - ui/world/spot_label_model.gd
findings:
  critical: 0
  warning: 5
  info: 9
  total: 14
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-10-22T09:55:05Z
**Depth:** standard
**Files Reviewed:** 279
**Status:** issues_found

## Summary

Reviewed the whole Phase 5 scope: the StatStack and its consumers (king, units, buildings, walls, towers,
castle), the castle plot with its four tiers and twelve cards, the requirement gate, IncomeState (Mine,
Harbor, Shrine), the card row and picker, the pond, the castle-aware bots, the economy replay scenario and
the screenshot tooling. The 72 `.uid` files each sit beside their script, scene or resource, the 12 `.import`
files each sit beside their SVG, and the 12 SVGs are plain shapes (no script, no external reference), are each
referenced by exactly one card in `data/abilities/` and are covered by the "First-party assets" paragraph of
ASSETS.md. The CI workflow keeps `permissions: contents: read`, every `uses:` is SHA-pinned, there are no
secrets, and the only Phase 5 edits are the two economy replay lines and the comment.

The core arithmetic holds up under tracing: `StatStack._int_from` rounds once, half up, and the worst-case
product (`100000 * 1100 * 400^4`, doubled for the rounding add) stays under int64; every handler of
`changed` reads `previous_int_value` only for a stat that moved, so the stale-snapshot window is not
reachable; the gate is checked in `validate_build` before any spend and `apply_next_tier` has no other
production caller; IncomeState and `BuildingSystem.dawn_income_by_spot` partition the curves so nothing is
paid twice; no float enters a decision other than the existing metre-space distance tests. No security
finding and no correctness defect reachable with the shipped data was found, so there is no BLOCKER. The
findings below are latent robustness gaps (data that validates but silently disarms or silently drops an
effect), one misleading UI marker, one hot-path allocation, and cleanups.

## Warnings

### WR-01: A refused `add_source` is ignored after the gold is spent and the pick is recorded

**File:** `simulation/buildings/choice_ledger.gd:71` (also `simulation/economy/income_state.gd:221`)
**Issue:** `StatStack.add_source` returns `false` and changes nothing when a stat would exceed four
multipliers or a percent sum would leave -90..1000 (`stat_stack.gd:42-61`). `ChoiceLedger._on_choice_picked`
discards that result and goes on to append the card to `_picks` and `_all`, so the spot label's Picks line,
the Economy overlay and the replay `picks` list report a card whose modifiers were never armed, and the player
has already paid for the tier. `ChoiceValidation` checks each modifier alone (`stat_modifier_def.gd:26`) and
never the stacking of every card of the map, so nothing reports the case. `IncomeState._refresh_synergy` has
the same blind spot: when Golden Age's +25% on `shrine.damage` plus the capped synergy would pass 1000, the
replacement is refused and the previous synergy value silently stays. Not reachable with the shipped 12 cards
and two Shrines, but the data-driven design invites it as Phases 6 and 7 add cards.
**Fix:** Have the ledger record the pick only when the stack accepted it, and make `ChoiceValidation` prove the
worst case:
```gdscript
if not _stats.add_source(choice_id, card.modifiers):
    push_warning("card '%s' refused by the stat stack" % choice_id)  # or an event the recorder digests
    return
```
and in `ChoiceValidation.problems` build a scratch `StatStack`, `add_source` every card of the map once, and
report `"cards together exceed the stat limits"` when any call returns false. In `_refresh_synergy` keep the cap
at `PERCENT_SUM_MAX - (the other sources' percent)` or report through `EconomyValidation`.

### WR-02: Castle tiers II to IV are not validated, so a bad row silently disarms the keep; the CastleAttack header still claims otherwise

**File:** `simulation/defs/castle_validation.gd:28` and `simulation/defs/map_config.gd:512`; stale claim at
`simulation/night/castle_attack.gd:14-18`
**Issue:** Since 05-02 `CastleAttack.is_armed` and `step` read the arrow from `CastleState.arrow_*`, which for
tier II and above come from the castle building's tier data (`castle_state.gd`, `_upgraded_tier()`). The tier
numbers are checked only by `MapConfig._validate_tier_combat` (range >= 0, interval > 0, speed >= 0). A tier
with `attack_damage = 0` (the `BuildingTierDef` default), an `attack_range` of 0, an interval below
`SimClock.STEP` or above `MAX_CASTLE_ATTACK_INTERVAL_S`, or a non-finite value passes `validate()` and then
fails `is_armed()`, so buying that castle tier turns the keep's arrow off with no report. The Shrine got exactly
this check (`EconomyValidation._check_awakened`), the castle did not. The `CastleAttack` header still says
"MapConfig.validate() reports every other value, so neither bad nor unvalidated data can make the castle fire
every tick", which is no longer true for the upgraded tiers.
**Fix:** In `CastleValidation._check_building`, for every tier index >= 1 of the castle building report
`attack_damage < 1`, a non-finite or non-positive `attack_range`, `attack_interval` outside
`[SimClock.STEP, MapConfig.MAX_CASTLE_ATTACK_INTERVAL_S]` and a non-finite or negative `projectile_speed`
(the same bounds `is_armed` applies), and rewrite the header comment to say the tier data is validated by
`CastleValidation`.

### WR-03: `StatModifierDef.problems()` accepts a bucket that is not one of the three

**File:** `simulation/stats/stat_modifier_def.gd:26-47`
**Issue:** `bucket` is an exported enum stored as an int in the `.tres`. A hand-edited `bucket = 3` (the
project edits `.tres` as text) passes `problems()` (the `match` has no default arm), is accepted by
`StatStack.add_source`, counts as a modifier for `is_modified`, `modified_stats` and the debug Stats row, and
contributes nothing in `_compute_sums` (`stat_stack.gd:190-196` has no arm for it), while
`effect_text()` prints it as a flat bonus. The card would show "+2 king damage" and do nothing, and no test or
validation report catches it. This is the typo class the "unknown stat id" check exists for.
**Fix:** Add a default arm that reports it:
```gdscript
_:
    found.append("unknown bucket %d for '%s'" % [bucket, stat])
```

### WR-04: The "no income" coin is drawn over a rebuilt Shrine that has not woken and pays nothing anyway

**File:** `ui/hud/dawn_no_income_marker.gd:60-76` with `simulation/defs/building_def.gd:57-63`
**Issue:** The marker asks `BuildingDef.pays_income(tier)`, which for every curve except BOATS is
`tier.dawn_income > 0`. The Shrine tier carries `dawn_income = 1` (`data/buildings/shrine.tres`) but
`IncomeState.dawn_payouts` pays an AWAKENED plot only while `is_awake` is true (`income_state.gd`, the
`AWAKENED and is_awake(spot_id)` arm). A Shrine that fell and was rebuilt before it ever woke therefore gets
the crossed-out coin ("you lose this morning's gold") although it had no gold to lose. No test covers a
rebuilt Shrine in `test_rebuilt_economy_marker.gd` (Mine, House, Tower and wall plots only).
**Fix:** Make the marker ask the income model, not the raw field: add `IncomeState.would_pay(spot_id)` (true
for a FLAT plot with `dawn_income > 0`, for a DECLINING plot, for a BOATS plot with `boat_income > 0`, and for
an AWAKENED plot only when `is_awake`) and call it from `_pays_income`; add a rebuilt-dormant-Shrine case to
the e2e test.

### WR-05: IncomeState's per-death handler allocates and rescans every plot for each enemy death

**File:** `simulation/economy/income_state.gd:182` (loop), `:225` (`_synergy_percent`)
**Issue:** `_on_enemy_died` runs once per death (hundreds per late night) and each time calls
`_buildings.spot_ids()`, which returns `_order.duplicate()` (`building_system.gd:46`, a fresh 23-element
array), then for each of the 23 plots does `_shrine_tier` (`get_building_def_for_spot` -> `get_spot` ->
dictionary lookups, then `tier_def`, `current_tier`) only to discover that 21 of them are not Shrines;
`_map.find_enemy(def_id)` is a linear search on top. `_synergy_percent` repeats the full scan on every wake.
The set of AWAKENED plots is fixed by the map at construction.
**Fix:** Build `_shrine_plots: Array[StringName]` (and each plot's `Vector2` position) once in `_init` from
`map.spots` whose building has `IncomeCurve.AWAKENED`, in MapConfig order, and iterate only that list in
`_on_enemy_died` and `_synergy_percent`; cache `EnemyDef.max_health` by `def_id` in a Dictionary built in
`_init`. The golden digests are unaffected because the iteration order and arithmetic stay identical.

## Info

### IN-01: `CastleAttack._map` is a dead field after 05-02

**File:** `simulation/night/castle_attack.gd:23,31`
**Issue:** Every `_map.castle_*` read was replaced by `_castle.arrow_*`; `_map` is assigned in `_init` and
never read.
**Fix:** Drop the field (keep the `map` parameter only if callers still pass it) and fix the header (see
WR-02).

### IN-02: A digit key above the card count clears the highlight instead of being ignored

**File:** `input/card_picker.gd:62` with `ui/world/card_row_model.gd:46`
**Issue:** `CardRowModel.index_for_digit(index + 1, _ids.size())` returns -1 for a digit above the number of
shown cards and `set_highlight(-1)` is legal ("-1 clears it"), so pressing 4 on a three-card row deselects the
current card. Unreachable today (the castle always offers four, enforced by `ChoiceValidation`), but
`CardPicker` is documented as generic for Phase 6 and 7 tiers.
**Fix:** Only act on a valid index: `var picked: int = ...; if picked >= 0: set_highlight(picked)`.

### IN-03: `StatStack` allocates an empty Dictionary on every read, and `CastleAttack` reads the stack several times per tick

**File:** `simulation/stats/stat_stack.gd:91,97,130,224`; `simulation/night/castle_attack.gd:40-47,62-81`
**Issue:** `_sums.get(stat, {})` builds a throwaway `{}` on every `int_value`, `float_value`, `sums_of` and
`_apply`. `CastleAttack.step` runs every night tick and calls `is_armed()` (range, interval, speed, damage:
four reads) and then, with an enemy in reach, three more. That is up to seven allocations per tick for a value
that only changes when a card is picked or the tier changes.
**Fix:** Use a shared `const _NO_SUMS: Dictionary = {}` (never mutated) or `_sums.get(stat)` with a null test
in the four places; optionally cache the armed flag in `CastleAttack` and refresh it on `stat_stack.changed`
and on `building_built` of the castle plot.

### IN-04: The card picker and the requirement check do avoidable work every frame near a plot

**File:** `input/card_picker.gd:132-147`; `simulation/commands/build_requirements.gd:13,32,41`
**Issue:** While the king is in range of any plot `CardPicker._refresh` runs each frame and calls
`validate_build`, which calls `BuildRequirements.rejection`; that scans `map.spots` for the castle plot up to
twice (`_castle_plot(map)` at line 32 and again inside `castle_tier`). When the row shows it also rebuilds four
Dictionaries through `CardRowModel.cards` every frame only to copy their ids.
**Fix:** Resolve the castle plot once (`CastleState.plot_id()` already exists; pass it or the plot to
`BuildRequirements`), and in `CardPicker` rebuild `_ids` only when the shown spot or tier changes.

### IN-05: `dawn_income` set on a BOATS tier is silently never paid and not reported

**File:** `simulation/defs/economy_validation.gd:166-185` (`_check_unused`), `:85` (`_check_boats`)
**Issue:** The "field set on the wrong curve" rule lists `income_step`, `income_floor`, the boat fields and
the wake fields, but not `dawn_income` for a BOATS tier. IncomeState pays a BOATS plot only
`boats * boat_income` and `BuildingSystem.dawn_income_by_spot` skips non-FLAT curves, so a Harbor authored with
`dawn_income = 2` shows no error and never pays it.
**Fix:** In `_check_boats` report `tier.dawn_income != 0` ("dawn_income is ignored on a boats curve").

### IN-06: The castle-raising helper exists twice, fails silently, and the shot version writes the economy directly

**File:** `tests/e2e/e2e_support.gd:126-141`, `tools/screenshot/shot_crowd_scenarios.gd:89-102`
**Issue:** `E2eSupport.raise_castle` and `ShotCrowdScenarios._raise_castle` are the same loop. The test helper
returns without any failure when a purchase is refused, so a gate regression shows up as a confusing
downstream assertion in whichever test called it. Both call `ctx.economy.grant`, while
`ShotEconomyScenarios` states that scenes reach their state "through the command intents and the Input Map,
never by writing simulation state".
**Fix:** Move the loop to one shared helper (for example `tools/screenshot` and `tests/e2e` both calling a
`RunContext`-level test hook), have the test version `push_error`/return a bool the caller asserts, and align
the header comment with the grant.

### IN-07: `PondView.bind_run` dereferences spot entries without a null check

**File:** `presentation/environment/pond_view.gd:67-70`
**Issue:** `for spot: BuildSpotDef in ctx.map.spots: ... spot.id` crashes on a null entry, while
`BuildingSystem._init` skips null spots because `MapConfig.validate()` only reports them. A map with an empty
spot entry therefore fails in the view with a script error instead of the reported data error.
**Fix:** `if spot == null: continue`, or iterate `ctx.buildings.spot_ids()` like the other views.

### IN-08: A wall-clock loop in an e2e test makes the shake assertion machine-dependent

**File:** `tests/e2e/test_castle_gate.gd:99-108`
**Issue:** The denied-shake test samples the label for `SHAKE_WINDOW_S` of real time with
`Time.get_ticks_msec()` and asserts `widest > 0.02`. On a busy machine a few long frames can skip every
displaced sample of the 0.3 s tween (same class as the known hover/box-select flake).
**Fix:** Drive the tween with frames (`await wait_process_frames(n)`) or assert on `label._shake_x` through
the `hold_denied` handler instead of sampling the position against the wall clock.

### IN-09: The transcendental guard does not scan the Phase 5 simulation folders that make decisions

**File:** `tests/unit/test_sim_rules_guard.gd:9-19`
**Issue:** `MATH_ROOTS` gained `simulation/stats` and `simulation/economy` but not `simulation/buildings`
(which now holds `ChoiceLedger` and the build rules), `simulation/commands` (the gate) or `simulation/run`
(the dawn payout merge). A `sin`, `cos` or `sqrt` introduced there would pass the guard even though the
determinism rules cover them.
**Fix:** Add `res://simulation/buildings`, `res://simulation/commands` and `res://simulation/run` (and
`res://simulation/defs` if no definition legitimately uses one) to `MATH_ROOTS`.

---

_Reviewed: 2026-10-22T09:55:05Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
