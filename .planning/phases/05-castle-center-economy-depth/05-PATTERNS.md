# Phase 5: Castle Center & Economy Depth - Pattern Map

**Mapped:** 2026-10-21
**Files analyzed:** 22
**Analogs found:** 20 / 22 (all analogs verified git-tracked)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `simulation/stats/stat_stack.gd` (+ `stat_modifier_def.gd`, `stat_ids.gd`) | utility/model | transform | `simulation/walls/wall_system.gd` (pure, int arithmetic, version counter) | role-match |
| `simulation/economy/income_state.gd` | service | event-driven | `simulation/walls/wall_system.gd` (sibling listening to `building_built`) | exact |
| `simulation/defs/choice_def.gd` | model (Resource) | config | `simulation/defs/building_tier_def.gd` | exact |
| `simulation/defs/build_requirement_validation.gd`, `economy_validation.gd` | utility | transform | `simulation/walls/wall_validation.gd` | exact |
| `simulation/defs/building_tier_def.gd`, `building_def.gd`, `build_spot_def.gd`, `map_config.gd` (modify) | model | config | self | exact |
| `simulation/commands/build_intent.gd` (modify: choice id) | model | request-response | self | exact |
| `simulation/commands/command_processor.gd` (modify: `validate_build`) | controller | request-response | self lines 52-71 | exact |
| `simulation/night/shrine_system.gd` (or in tower_system) | service | event-driven | `simulation/night/tower_system.gd` | exact |
| `simulation/night/night_sim.gd`, `simulation/run/run_manager.gd` (modify) | service | batch | self (`_apply_dawn_payout`) | exact |
| `simulation/events/sim_events.gd` + `tests/support/sim_signals.gd` + `SimRecorder.HANDLED` | config | pub-sub | existing signals | exact |
| `data/buildings/{castle_center,gold_mine,mill,field,fishing_harbor,shrine}.tres` | config | config | `data/buildings/tower.tres` / `house.tres` | exact |
| `data/abilities/*.tres` (12 ChoiceDef) | config | config | `data/buildings/tower.tres` sub_resource style | role-match |
| `data/maps/prototype_map.tres` (modify) | config | config | self | exact |
| `ui/world/card_row.gd` / `card_row_model.gd` | component | request-response | `ui/world/spot_label.gd` + `spot_label_model.gd` | exact |
| `ui/world/spot_label_model.gd` (modify: status lines) | utility | transform | self | exact |
| `input/card_picker.gd` | controller | event-driven | `input/command_key_controller.gd` (polled digits, Input fallback) | role-match |
| `input/build_hold_controller.gd` (modify) | controller | event-driven | self | exact |
| `presentation/buildings/building_views.gd`, `building_view_catalog.tres`, models | component | transform | self | exact |
| `presentation/environment/pond_view.gd` | component | transform | `presentation/map/map_root.gd` views | partial |
| `ui/overlay/debug_overlay.gd` sections | component | request-response | `ui/overlay/crowd_overlay_sections.gd` | exact |
| `tools/replay/playtest_strategies.gd` (+ bot, report, scenarios) | utility | batch | self | exact |
| `tests/golden/economy.json` + `tests/fixtures/fixture_map_replay_economy.tres` | test | batch | `tests/golden/walls.json` + `fixture_map_replay_walls.tres` | exact |
| new unit tests | test | - | `tests/unit/test_military_data_contract.gd` | exact |

## Pattern Assignments

### `simulation/economy/income_state.gd` (service, event-driven)
**Analog:** `simulation/walls/wall_system.gd` lines 1-60. RefCounted, no tree or clock, takes `(map, buildings, events)`, connects `events.building_built` in `_init`, keeps per-plot state in typed arrays or dictionaries in MapConfig spot order, never calls BuildingSystem back except to read a tier.
```gdscript
func _init(map: MapConfig, buildings: BuildingSystem, events: SimEvents) -> void:
	_events = events
	_buildings = buildings
	...
	events.building_built.connect(_on_building_built)
```
Public-method cap: BuildingSystem is at gdlint cap, so Mine decline, Harbor boats and Shrine kills live here. It also listens to `enemy_died(enemy_id, def_id, pos, killer_kind)` for Shrine kill credit.

### Dawn payout merge (`simulation/run/run_manager.gd` 205-215)
Extend, do not replace. Keep the single `dawn_payout(total, per_spot)` event and the rule that the total equals the sum of `per_spot`. `CASTLE_PAYOUT_KEY` is listed last.
```gdscript
var per_spot: Dictionary = _buildings.dawn_income_by_spot()
if _base_dawn_income > 0:
	per_spot[MapConfig.CASTLE_PAYOUT_KEY] = _base_dawn_income
var total: int = 0
for amount: int in per_spot.values():
	total += amount
if total > 0:
	_economy.grant(total)
_events.dawn_payout.emit(total, per_spot)
```
Merge IncomeState amounts into `per_spot` before summing. Skip rebuilt-this-dawn plots as `BuildingSystem.dawn_income_by_spot()` does (D-14).

### `simulation/night/shrine_system.gd` (service, request-response)
**Analog:** `simulation/night/tower_system.gd` (whole file, 1-60).
- `begin_night()` clears `_ready_at`; `step(tick, enemies, hits)` iterates `_buildings.standing_spot_ids()` and reads the current tier through `building_def.tier_def(current_tier)`.
- Core: `TargetQuery.nearest_enemy(enemies, origin, tier.attack_range)`, then `SimClock.flight_ticks(dist, tier.projectile_speed)`, `hits.enqueue(tick + flight, PendingHits.KIND_BUILDING, spot_index, PendingHits.KIND_ENEMY, target_id, dmg)`, then `_events.attack_fired.emit(...)` and `_ready_at[spot_id] = tick + SimClock.ticks(tier.attack_interval)`.
- Pitfall 2: a dormant Shrine must `continue` before any enqueue. Slot it in `night_sim.gd` beside the towers and castle step in the fixed order.

### `simulation/defs/choice_def.gd` and tier-def additions (model, config)
**Analog:** `simulation/defs/building_tier_def.gd`. `extends Resource`, every number an `@export` with a `##` doc line, "data only: every number lives in .tres (D-09)". New tier fields (requirement castle tier, choices array, income curve) follow that style. Update `effect_line()` for new effects.

### `simulation/defs/build_requirement_validation.gd` / `economy_validation.gd`
**Analog:** `simulation/walls/wall_validation.gd`. `class_name X extends RefCounted`, a header on what `MapConfig.validate()` reports, const bounds with a doc line, static functions returning an `Array[String]` of readable problems, and it never mutates. Call it from `MapConfig.validate()`.

### `simulation/commands/command_processor.gd` (modify)
The current `validate_build` (lines 52-71) has check order NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD. Insert the new requirement rejections (castle tier, Field lock, missing choice) as new `const X := &"..."` reasons. Per the research, put the lock check before CANNOT_AFFORD, and keep the read-only `validate_build(spot_id)` signature backward compatible by adding an optional `choice_id: StringName = &""`. Rejections return the reason and announce `command_rejected`, never `push_error`; copy the shape of `_submit_ability` (lines 83-100). Register handlers through the `_handlers` dictionary keyed by intent script. `BuildIntent` (`_init(target_spot)`) gains `choice_id: StringName = &""` as a defaulted second param.

### `input/build_hold_controller.gd` (modify)
Key spots: `_try_start_hold` (calls `validate_build`, emits `hold_denied`, captures `_active`, `_cost`), and `_finish_hold` (`submit(BuildIntent.new(spot_id))`). Capture the highlighted choice id at hold start, pass it to validation and the intent, and refuse to start without a highlighted card at a branching tier (`hold_denied` with the new reason). Reset it in `_reset_hold`.

### `ui/world/card_row_model.gd` and `spot_label_model.gd` (modify)
**Analog:** `ui/world/spot_label_model.gd`. A static pure `describe(ctx, spot_id, coins_paid) -> Dictionary` with fixed keys, no Nodes, reading RunContext only. Extend the dictionary with the "Needs Castle II" / "Needs a Mill" text through `status_line`. The card row model follows the same pure-dictionary style and takes supplied rects for hit tests.

### `input/card_picker.gd` (controller, event-driven)
**Analog:** `input/command_key_controller.gd`. Extends Node, polls in `_process` with `Input.is_action_just_pressed` plus an action-level fallback so scripted `Input.action_press` works (Pitfall 6: the digit keys also serve control groups, so gate on card visibility). Mouse clicks on cards must be consumed before the SelectionController drag (Pitfall 7).

### `ui/overlay` debug sections
**Analog:** `ui/overlay/crowd_overlay_sections.gd` lines 20-40.
```gdscript
overlay.register_section(
	WALLS_TITLE, func() -> Array: return CrowdOverlaySections.wall_rows(ctx)
)
```
Add stat, Shrine and castle tier sections the same way, with a static `*_rows(ctx) -> Array` per section.

### `data/buildings/*.tres`
**Analog:** `data/buildings/tower.tres`. `script_class="BuildingDef"`, ext_resources for `building_tier_def.gd` and `building_def.gd`, one `[sub_resource type="Resource"]` per tier with `script = ExtResource("1_tier")` and only non-default fields, and `[resource]` with `id = &"..."`, `display_name`, `body_radius`, and `tiers = Array[ExtResource("1_tier")]([...])`. Bump `load_steps` for each added sub_resource. Hand-written ids, no uid.

### `tools/replay/playtest_strategies.gd` (modify)
Add the new names to the `NAMES` array and a `const _X: Array[StringName]` build order (a repeated spot id means an upgrade). Per Pitfall 1, a locked entry must not stall a bot, so order the castle upgrade before the dependent plots. Keep the `_no_walls` style of frozen legacy orders so older goldens stay stable. Update the doc comment list at the top.

### Golden `tests/golden/economy.json`
**Analog:** `tests/golden/walls.json`, with this shape:
```json
{ "scenario": "walls", "seed": 1, "digests": { "default": "<sha256>" } }
```
Fixture analog is `tests/fixtures/fixture_map_replay_walls.tres`; register the scenario in `tools/replay/replay_scenarios.gd`. Native route stays untouched (Pitfall 11).

### New unit tests
**Analog:** `tests/unit/test_military_data_contract.gd`. `extends GutTest`, a long `##` header explaining why numbers are pinned, `const *_PATH := "res://data/..."` loads, const arrays of pinned numbers, and a note on deliberate re-pins. Apply to the data contract of the economy buildings and abilities. Keep scripts within the test-script and lint caps (Pitfall 10).

## Shared Patterns

- **Events:** add each new signal to `simulation/events/sim_events.gd`, `tests/support/sim_signals.gd` and `SimRecorder.HANDLED` in the same task.
- **Rejections:** return a reason `StringName`, emit `command_rejected(kind, id, reason)`, never `push_error`.
- **Data over code:** every tunable lives in `.tres`; new fields get a `##` doc line and a bounds check in the matching validation helper.
- **Determinism:** simulation classes extend RefCounted, take no tree or clock, use integer arithmetic (`CENTIMETRES` style) and no randomness outside SimRng.
- **Static typing and gdlint public-method caps:** BuildingSystem is at the cap, so add sibling systems rather than methods.

## No Analog Found

| File | Role | Reason |
|---|---|---|
| `simulation/stats/stat_stack.gd` | utility | No modifier-bucket system exists; use RESEARCH Pattern 1 and the E1 integer evaluation sketch (code examples section). |
| `presentation/environment/pond_view.gd` | component | No visual-only environment view exists; copy the construction style of `presentation/map/map_root.gd` and `building_views.gd`. |

## Metadata

**Analog search scope:** `simulation/`, `input/`, `ui/`, `data/buildings`, `tools/replay`, `tests/golden`, `tests/fixtures`, via `git ls-files`
**Files scanned:** about 12 read in full or in part
**Pattern extraction date:** 2026-10-21
