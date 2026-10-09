# Phase 3: King Combat & Troops - Pattern Map

**Mapped:** 2026-10-09
**Files analyzed:** 52 (new and modified, grouped where they share one analog)
**Analogs found:** 48 / 52 (all analog paths verified git-tracked via `git ls-files`)

Line numbers refer to the files as read this session. Full excerpts are given for the load-bearing patterns; for the rest the planner should open the cited range.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `simulation/squads/unit_system.gd` | service (manager) | CRUD + transform | `simulation/night/enemy_system.gd` | exact |
| `simulation/squads/squad_system.gd` | service (orchestrator) | event-driven / batch | `simulation/night/tower_system.gd` + `enemy_system.gd` | role-match |
| `simulation/squads/squad.gd`, `squad_order.gd` | model | CRUD | `EnemySystem.Record` (enemy_system.gd:349-362) | role-match |
| `simulation/squads/squad_orders.gd`, `squad_formation.gd` | utility (pure static) | transform | `simulation/night/target_query.gd` | role-match |
| `simulation/commands/squad_order_intent.gd`, `activate_ability_intent.gd` | model (intent) | request-response | `simulation/commands/build_intent.gd` | exact |
| `simulation/commands/command_processor.gd` (modify) | controller (gate) | request-response | itself (lines 44-68) | exact |
| `simulation/defs/unit_def.gd` | model (resource) | config | `simulation/defs/enemy_def.gd` | exact |
| `simulation/defs/weapon_def.gd` | model (resource) | config | `simulation/defs/king_def.gd` (lines 24-29 move out) | exact |
| `simulation/defs/building_tier_def.gd`, `building_def.gd`, `king_def.gd`, `map_config.gd` (modify) | config | config | themselves | exact |
| `simulation/king/king_state.gd` (modify) | service | event-driven | itself (lines 63-142) | exact |
| `simulation/night/enemy_system.gd`, `night_sim.gd`, `pending_hits.gd` (modify) | service | event-driven | themselves | exact |
| `simulation/run/run_context.gd`, `run_manager.gd` (modify) | service | batch | themselves (run_context.gd:54-62, run_manager.gd:170-181) | exact |
| `data/units/footman.tres`, `archer.tres` | config | config | `data/enemies/ranged.tres`, `grunt.tres` | exact |
| `data/buildings/barracks.tres`, `archery_range.tres` | config | config | `data/buildings/tower.tres` | exact |
| `data/king/sword.tres` (+ `king.tres`, smoke fixture) | config | config | `data/king/king.tres`, `tests/fixtures/fixture_king_replay_smoke.tres` | exact |
| `data/maps/prototype_map.tres` (modify) | config | config | itself (sub_resources lines 15-62) | exact |
| `input/selection_model.gd`, `selection_math.gd`, `ground_pick.gd`, `ground_cursor.gd` | utility / model (pure) | transform | `simulation/night/target_query.gd` (pure static style); RESEARCH Code Examples | partial |
| `input/command_key_controller.gd`, `ability_controller.gd` | controller | polled request-response | `input/start_night_hold_controller.gd` | exact |
| `input/selection_controller.gd`, `pad_cursor_controller.gd` | controller | event-driven | `input/build_hold_controller.gd` (bind_run, node shape) + RESEARCH Pitfall 6/8 | partial |
| `input/last_device_tracker.gd` | provider | event-driven | `input/fast_forward_controller.gd` (latch node with signal) | partial |
| `project.godot` Input Map (modify) | config | config | `fast_forward={...}` block (lines 79-84) | exact |
| `presentation/units/unit_views.gd` | component | event-driven | `presentation/enemies/enemy_views.gd` | exact |
| `presentation/units/selection_rings.gd`, `order_markers.gd`, `slam_vfx.gd` | component | event-driven | `presentation/vfx/projectile_vfx.gd` | role-match |
| `presentation/vfx/projectile_vfx.gd`, `presentation/debug/enemy_path_gizmo.gd` (modify) | component | event-driven | themselves | exact |
| `presentation/buildings/building_view_catalog.tres` (modify) | config | config | itself | exact |
| `ui/hud/hud_root.gd`, `king_widget.gd`, `squad_strip.gd`, `squad_slot.gd`, `command_hints.gd`, `toast.gd`, `day_counter.gd` | component | event-driven + polling | `ui/hud/hud.gd` | role-match |
| `ui/hud/glyph_resolver.gd`, `prompt_glyph.gd`, `stance_glyph.gd` | utility / component | transform | `ui/hud/hud.gd` lines 29-47, 241-297 | role-match |
| `ui/overlay/debug_overlay.gd` squads section | component | request-response | `ui/overlay/night_overlay_sections.gd` | role-match |
| `tools/replay/playtest_bot.gd`, `playtest_strategies.gd`, `replay_scenarios.gd`, `replay_driver.gd`, `sim_recorder.gd` (modify) | utility | batch | themselves | exact |
| `tests/support/sim_signals.gd` (modify) | test support | config | itself | exact |
| `tests/unit/test_squad_*.gd`, `test_slam_*.gd`, `test_king_regen.gd` | test | unit | `tests/unit/test_enemy_targeting.gd`, `test_king_combat.gd` | exact |
| `tests/unit/test_input_map.gd` (modify) | test | unit | itself | exact |
| `tests/e2e/test_squad_*.gd`, `test_selection_*.gd` | test | e2e | `tests/e2e/test_start_night_hold.gd`, `e2e_support.gd` | role-match |
| `tests/integration/test_balance_acceptance.gd`, `test_replay_golden.gd`, `tests/golden/army.json` | test | integration | themselves | exact |
| Kenney Input Prompts assets, `ASSETS.md`, `assets/attribution.json` | asset / config | file-I/O | existing `kenney-mini-characters` entry | exact |

## Pattern Assignments

### `simulation/squads/unit_system.gd` (service, id-addressed manager)

**Analog:** `simulation/night/enemy_system.gd`

**Header and storage** (lines 1-20): copy verbatim in spirit.
```gdscript
class_name EnemySystem
extends RefCounted
var _events: SimEvents
var _records: Dictionary = {}
var _order: Array[int] = []
var _next_id: int = 1
func _init(events: SimEvents) -> void:
	_events = events
```

**Id-based read API** (lines 49-99): `ids()` returns `_order.duplicate()`, `is_alive`, `position_of`, `previous_position_of`, `def_of`, `health_of`, each `_records.get(id) as Record` with a safe default for an unknown id. Add `squad_of(id)`.

**Spawn + event** (lines 35-46): `Record.new()`, assign id from `_next_id`, `_records[id]`, `_order.append(id)`, `_events.enemy_spawned.emit(...)` -> use `unit_spawned`.

**Damage (drops silently on gone target)** (lines 105-112):
```gdscript
func damage(id: int, amount: int, killer_kind: StringName) -> void:
	var record: Record = _records.get(id) as Record
	if record == null or record.health <= 0 or amount <= 0:
		return
	record.health = maxi(record.health - amount, 0)
	...
	_events.enemy_damaged.emit(id, amount, record.health)
```

**Remove dead** (lines 144-155): collect ids in `_order` order, then `_records.erase`, `_order.erase`, emit died event.

**Separation pass** (lines 311-346): snapshot positions, ascending-id pair loop, `absf(delta.x) >= min_gap` early-out, zero-delta fixed axis by id parity (never random), displacements applied together. Reuse for friendly units (research Pattern 1: units take the lowest free formation slot).

**Rule:** no `sin/cos/atan2/pow/lerp_angle` (add `res://simulation/squads` to `MATH_ROOTS` in `tests/unit/test_sim_rules_guard.gd:9-14`).

---

### `simulation/squads/squad_system.gd` (service, step per tick; guard / commit / leash)

**Analogs:** `simulation/night/tower_system.gd` (shape, ready-at map, building polling) and `enemy_system.gd` (commit + rescan).

**System shape** (tower_system.gd:9-23): constructor takes `BuildingSystem` and `SimEvents`; `begin_night()` clears per-night state; `step(tick, enemies, hits)`.

**Polling the building tier (pull-based sync, no listeners in sim)** (tower_system.gd:28-30, 57-61):
```gdscript
for spot_id: StringName in _buildings.standing_spot_ids():
	var tier: BuildingTierDef = _current_tier(spot_id)
...
func _current_tier(spot_id: StringName) -> BuildingTierDef:
	var building_def: BuildingDef = _buildings.get_building_def_for_spot(spot_id)
	if building_def == null:
		return null
	return building_def.tier_def(_buildings.current_tier(spot_id))
```

**Staggered rescan (reuse the static, do not reinvent)** (enemy_system.gd:30-31):
```gdscript
static func is_rescan_tick(tick: int, id: int, rescan_ticks: int) -> bool:
	return rescan_ticks > 0 and (tick + id) % rescan_ticks == 0
```

**Commit rule** (enemy_system.gd:177-194): `valid = target_kind != &"" and _target_valid(...)`; `if valid and not is_rescan_tick(...): return`. Units keep the target until dead or beyond leash (Pitfall 5); acquire with `TargetQuery.nearest_enemy(enemies, anchor, guard_radius)`.

**Walk + stop distance + cooldown + hit enqueue** (enemy_system.gd:280-303): copy `stop_distance = goal_radius + attack_range`, `ARRIVE_EPSILON`, `desired_step`, then:
```gdscript
var flight: int = SimClock.flight_ticks(record.position.distance_to(goal), record.def.projectile_speed)
hits.enqueue(tick + flight, PendingHits.KIND_ENEMY, record.id, record.target_kind, record.target_id, record.def.attack_damage)
_events.attack_fired.emit(PendingHits.KIND_ENEMY, record.id, record.target_kind, record.target_id, flight)
record.cooldown_ready_tick = tick + SimClock.ticks(record.def.attack_interval)
```
Archers use the same `flight_ticks` path as towers (tower_system.gd:39-54). Add `PendingHits.KIND_UNIT`.

**Day step:** new `NightSim.step_day(tick)` against an empty enemy set; called from `RunContext.step` in non-NIGHT phases (see run_context below).

---

### `simulation/squads/squad.gd`, `squad_order.gd` (model records)

**Analog:** `EnemySystem.Record` (enemy_system.gd:349-362): inner `class Record: extends RefCounted` with plain typed vars and doc comments. Squad is keyed by the military spot id (`barracks_1`), never deleted (research Pattern 1).

### `simulation/squads/squad_orders.gd`, `squad_formation.gd` (pure statics)

**Analog:** `simulation/night/target_query.gd` (all `static func`, no stored state, documented tie rule "lower id wins"). Formation is an axis-aligned grid (`columns = ceili(sqrt(cap))`), no trig.

---

### `simulation/commands/squad_order_intent.gd`, `activate_ability_intent.gd` (intent)

**Analog:** `simulation/commands/build_intent.gd` (lines 1-10)
```gdscript
class_name BuildIntent
extends RefCounted
var spot_id: StringName = &""
func _init(target_spot: StringName) -> void:
	spot_id = target_spot
```
Points are `Vector2i` centimetres only (research Pattern 6); no `Vector2` from mouse, no raw events.

### `simulation/commands/command_processor.gd` (modify)

**Dispatch** (lines 44-49) and **rejection-as-value** (lines 52-68):
```gdscript
func submit(intent: RefCounted) -> StringName:
	if intent is BuildIntent:
		return _submit_build(intent as BuildIntent)
	...
	return UNKNOWN_INTENT

if reason != OK:
	_events.command_rejected.emit(&"build", spot_id, reason)
	return reason
```
Keep `submit` flat (max-returns 6): switch to a dispatch table or one `match`. New reason consts follow lines 6-11 (`OK`, `NOT_DAY`, ...). Never `push_error`. `CommandProcessor._init` gains the squad system and king (constructed in `run_context.gd:48`).

---

### `simulation/defs/unit_def.gd` (resource)

**Analog:** `simulation/defs/enemy_def.gd` (lines 1-27): `@export var` per field with a `##` doc comment and a unit (metres, seconds). Fields: id, display_name, max_health, move_speed, radius, attack_range, attack_damage, attack_interval, guard_range, leash_range, retarget_interval_seconds, projectile_speed (0.0 = melee). Seconds convert to ticks once via `SimClock.ticks`.

### `simulation/defs/weapon_def.gd` + `king_def.gd` (modify)

**Analog:** `king_def.gd:24-29` (the three passive fields that move): `attack_range = 3.0`, `attack_damage`, `attack_interval`. Add slam radius/damage/cooldown (cooldown 0 = no ability). Migrate in one task: `king.tres`, `tests/fixtures/fixture_king_replay_smoke.tres` (3.0 / 3 / 0.8 identical), `king_state.gd:125,129,132`, `tests/unit/test_king_combat.gd` (45, 51, 73, 96). `KingState` falls back to a default `WeaponDef` when `weapon` is null (Pitfall 2). Opt-in defaults keep the smoke golden (Pitfall 1).

### `simulation/defs/building_tier_def.gd` (modify)

**Analog:** itself (lines 5-27): add `squad_size` and `squad_respawn_seconds` with `##` docs; extend `effect_line()` with a squad branch (`"Squad of %d"`) after the income and attack branches (lines 22-27).

---

### `simulation/king/king_state.gd` (modify: slam, cooldown, regeneration)

**Counters decremented once per step, no tick base** (lines 118-122):
```gdscript
if _down:
	_respawn_ticks_left -= 1
	if _respawn_ticks_left <= 0:
		_respawn()
	return
```
Ability cooldown, regen delay and heal accumulator follow this counter style, in a new `tick_timers()` called every phase (DAY, NIGHT, DAWN). Regeneration never runs while `_down`.

**Hit enqueue and event** (lines 125-132): the slam enqueues one `PendingHits` entry per enemy in radius (ascending id, `PendingHits.KIND_KING`) with arrival tick = now, then emits `king_ability_used(hit_count)`. Heal emits `king_healed(amount, hp, max_hp)` only when integer hp changed; float accumulator with `+ - * /` only (DR-7).

**Damage event shape** (lines 66-78): `_events.king_damaged.emit(lost, _health, get_max_health())`; reset the regen delay inside `take_damage`. `restore_for_dawn()` (lines 101-104) stays (assumption A7). Update the class doc comment at lines 9-11 ("health never regenerates").

### `simulation/night/enemy_system.gd` (modify: enemies target units)

Add `units: UnitSystem = null` as a **trailing optional** param to `step` (signature at lines 122-128) so existing call sites and tests keep working. Add the unit scan in `_pick_nearest_structure` (lines 200-216) **before** the building loop, edge = centre distance minus `UnitDef.radius`; add a `KIND_UNIT` branch in `_target_valid` (228-242) and `_advance_and_strike` (262-278, goal = unit position, radius = unit radius). Mirror `_building_target_valid` (246-252).

### `simulation/night/night_sim.gd` (modify)

Step order (lines 70-85) becomes: spawn, king, **squads**, towers, castle, enemies, resolve hits, remove dead enemies, **remove dead units**. Resolver (lines 141-150) gains:
```gdscript
elif hit.target_kind == PendingHits.KIND_UNIT:
	_squads.damage_unit(hit.target_id, hit.amount)
```
`begin_night` (lines 56-66) must NOT reset stance/queue/anchor (D-14). `_init` builds the squad system next to `TowerSystem` (line 41). Add `step_day(tick)`.

### `simulation/night/pending_hits.gd` (modify)

Add `const KIND_UNIT := &"unit"` beside lines 8-11 and document the id meaning in the `enqueue` doc (lines 17-18).

### `simulation/run/run_context.gd`, `run_manager.gd` (modify)

`RunContext.step` (lines 54-62) currently gates `night.step` on NIGHT only. Pattern: call `king.tick_timers()` and, outside NIGHT, `night.step_day(tick_count)` every step; keep the castle-destroyed check after the night step. `get_unit_count()` (lines 84-86) returns the real count. `RunManager._enter_dawn` (lines 170-181): add `squads.restore_for_dawn()` next to `_king.restore_for_dawn()` (lines 178-179).

---

### `data/units/footman.tres`, `archer.tres`

**Analog:** `data/enemies/ranged.tres` (full file read): `[gd_resource type="Resource" script_class="EnemyDef" load_steps=2 format=3]`, one `ext_resource` for the script, `[resource]` block with `script = ExtResource("1_enemy")` then plain `key = value` lines. Starter numbers are assumption A1 in RESEARCH.

### `data/buildings/barracks.tres`, `archery_range.tres`

**Analog:** `data/buildings/tower.tres` (full file read): `sub_resource` per tier with `script = ExtResource("1_tier")`, `cost`, `max_health`, then `[resource]` with `tiers = Array[ExtResource("1_tier")]([SubResource(...), ...])`. Three tiers, costs 4/8/16, `squad_size` 4/8/14, respawn 10/7/4 s.

### `data/maps/prototype_map.tres` (modify)

**Analog:** itself, spot sub_resources at lines 15-62. **Append** the two `BuildSpotDef`s at the end of `MapConfig.spots` (Pitfall 11) so hit indices, payout order and tie-breaks for the eight existing plots do not change. Amend `tests/unit/test_prototype_map_data.gd:58`. Night counts (D-08) are retuned in the group sub_resources (lines 84-228) and `test_night_data_contract.gd`. Regenerating goldens: `full_idle` has no golden; `smoke` uses its own fixture and must stay byte-identical.

---

### `input/command_key_controller.gd`, `ability_controller.gd` (polled controllers)

**Analog:** `input/start_night_hold_controller.gd` (full file read).

**Node shape and bind** (lines 1-23):
```gdscript
class_name StartNightHoldController
extends Node
var _ctx: RunContext
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx
```
**Polling + submit** (lines 30-53): `Input.is_action_pressed(ACTION)` in `_process`, guard `_ctx == null`, then
```gdscript
if _ctx.commands.submit(StartNightIntent.new()) == CommandProcessor.OK:
	night_requested.emit()
```
Verbs and digits are polled (`is_action_just_pressed` plus a `_was_pressed` fallback, see `FastForwardController._was_pressed`), because `Input.action_press` produces no `InputEvent` (Pitfall 6). Ten digit actions plus one `selection_modifier` action branch on the modifier (RESEARCH Code Examples "Modifier-aware digit handling").

### `input/selection_controller.gd`, `pad_cursor_controller.gd` (event-driven)

**Analog:** same `bind_run(ctx, map_root)` Node shape as above; mouse via `_unhandled_input` so STOP HUD panels block clicks (Pitfall 8). Ground pick uses `Camera3D.project_ray_origin/normal` + `Plane(Vector3.UP, 0.0).intersects_ray`, quantised with `roundi(x * 100.0)` to `Vector2i` (RESEARCH Code Examples; `SimRecorder.POSITION_SCALE = 100.0`). Tests drive with `Input.parse_input_event`.

### `input/last_device_tracker.gd`

**Analog:** `input/fast_forward_controller.gd`: a Node with a documented signal (lines 36-37 `signal changed(active: bool, scale: float)`), constants for input-device guards (`REARM_STRENGTH`, lines 41-45) and a pure static helper (`scale_for`, lines 54-62) for the testable rule. Same split: pure `DeviceModel.feed(event, now_s)` plus a thin Node emitting `device_changed`. Do not add any new `Engine.time_scale` writer (source scan in `tests/unit/test_fast_forward_rules.gd`).

### `project.godot` Input Map (modify)

**Analog:** the `fast_forward` block (lines 79-84): `deadzone` plus `events` list of `Object(InputEventKey, ... "physical_keycode":N ...)` and `Object(InputEventJoypadMotion, ...)`. Fast-forward moves off F (default T, assumption A3). Use `physical_keycode` for keys, `device: -1`. Pitfall 14: `move_left` already owns physical A; attack-move needs the owner decision (Open Question 1). Update `tests/unit/test_input_map.gd` constants (lines 8-50: `GAMEPLAY_ACTIONS`, `EXPECTED_KEYS`, `EXPECTED_BUTTONS`, `EXPECTED_AXES`), the no-mouse test (line 173) and the shared-binding test with an explicit allow-list.

---

### `presentation/units/unit_views.gd` (component)

**Analog:** `presentation/enemies/enemy_views.gd`

**Binding and signals** (lines 37-44):
```gdscript
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.enemy_spawned.connect(_on_enemy_spawned)
	ctx.events.enemy_damaged.connect(_on_enemy_damaged)
	ctx.events.enemy_died.connect(_on_enemy_died)
```
**Interpolation** (lines 65-77). **Deviation required:** do NOT copy line 69 `blend = alpha if NIGHT else 1.0`; units move by day, so use `_ctx.alpha()` in every phase.
**Other reusable bits:** `MAX_VIEWS` cap (line 11), puppet dictionary by id, hurt-only `HealthBar3D` update on damage (lines 89-96), flash tween (110-119), death puff. Models: Kenney Mini Characters (other GLBs than `character-male-b`), logged in `ASSETS.md`.

### `presentation/units/selection_rings.gd`, `order_markers.gd`, `slam_vfx.gd`

**Analog:** `presentation/vfx/projectile_vfx.gd` (constants block lines 14-40, `bind_run`, self-freeing effects with caps `MAX_PROJECTILES`/`MAX_SLASHES`). Rings: one `MultiMeshInstance3D`, set `use_colors` and `transform_format` before `instance_count` (Pitfall 9).

### `presentation/vfx/projectile_vfx.gd`, `presentation/debug/enemy_path_gizmo.gd` (modify)

Each switches on attacker/target kinds and must learn `KIND_UNIT` (lines listed in RESEARCH Pattern 2: projectile_vfx.gd:144-145,183,188,209,213; enemy_path_gizmo.gd:121,131; also `tools/replay/replay_driver.gd:139,141`, `ui/overlay/night_overlay_sections.gd:86,88`). Archer arrow colour and the king slam ring are new constants beside `TOWER_COLOR`.

---

### `ui/hud/*` (HUD widgets)

**Analog:** `ui/hud/hud.gd` (+ `hud.tscn`).

**Node shape**: `class_name Hud extends CanvasLayer`, `bind_run(ctx, map_root)` (line 68), `@onready var _x: Label = %X` unique-name nodes (lines 56-60), signal-driven refresh plus a `_process` poll for continuously changing values (line 100, `_refresh_respawn` 111).
**Player-facing copy as `const` strings** (lines 14-27), e.g. `NIGHT_BANNER := "Night %d of %d — %d enemies left"`; the king-health "38 / 50" and group slot "alive / max" texts follow this.
**Mouse filter rule** (Pitfall 8): new full-rect controls `mouse_filter = 2` (IGNORE); only `SquadSlot` is STOP; `hud.tscn` already sets IGNORE on its overlays.

### `ui/hud/glyph_resolver.gd`

**Analog:** `ui/hud/hud.gd:241-297` (move, keep tests): iterate `InputMap.action_get_events(action)`, branch on `InputEventKey` / `InputEventMouseButton` / `InputEventJoypadButton` / `InputEventJoypadMotion`; layout-safe key naming:
```gdscript
var label_key: int = physical_label_resolver.call(key_event.physical_keycode)
...
OS.get_keycode_string((label_key | key_event.get_modifiers_mask()) as Key)
```
`physical_label_resolver` is an injectable Callable (line 49) so tests stand in a non-QWERTY layout; `_layout_label` (273-279) returns the physical key under headless. `PAD_BUTTON_NAMES` / `AXIS_NAMES` (29-47) become the text fallback when no glyph tile exists. Glyph tiles are white on transparent: always draw on a dark plate (RESEARCH Kenney facts).

---

### `tools/replay/*` (bots, recorder, scenarios)

**`sim_recorder.gd`:** every new `SimEvents` signal needs (a) a `HANDLED` entry (lines 13-34), (b) a `events.x.connect(recorder._on_x)` in `attach` (lines 43-67), (c) a handler:
```gdscript
func _on_king_damaged(amount: int, hp: int, max_hp: int) -> void:
	_record("king_damaged", [amount, hp, max_hp])
```
Only ints, ids and names (positions quantised by `_token`). Also add the signal to `tests/support/sim_signals.gd` `ALL` (lines 9-30) and declare it in `simulation/events/sim_events.gd` with a `##` doc (style at lines 20-36). Suggested: `unit_spawned`, `unit_damaged`, `unit_died`, `squad_ordered`, `squad_restored`, `king_healed`, `king_ability_used`.

**`playtest_bot.gd`:** intents plus king position only, no randomness (lines 1-6); `think(ctx)` (lines 33-40) is one decision per tick before `ctx.step()`; add squad commands (follow, hold) via `ctx.commands.submit(SquadOrderIntent...)`. **`replay_scenarios.gd`:** `NAMES` allowlist (line 24) gains `&"army"`; constants block (lines 26-48) shows the SMOKE_* shape; goldens live in `tests/golden/`. `tools/screenshot.sh` `ALL_SHOTS` and `tools/screenshot/shot_scenarios.gd` `ALL_SHOTS` change together (Pitfall 13).

---

### Tests

**Unit analog:** `tests/unit/test_enemy_targeting.gd` (lines 1-40): `extends GutTest`, doc comment naming the decision, `const X_PATH := "res://data/..."` loaded from shipped `.tres`, hand-built systems (`SimEvents.new()`, `EnemySystem.new(_events)`, `PendingHits.new()`), tick counter, no RunContext. Keep each script under 20 test functions (gdlint cap), lines at most 100 chars, static typing.
**E2E analog:** `tests/e2e/test_start_night_hold.gd` with `tests/e2e/e2e_support.gd`; scripted real-window input with `Input.action_press`; mouse via `Input.parse_input_event`.
**Contract/pin tests to amend deliberately:** `test_input_map.gd`, `test_prototype_map_data.gd:58`, `test_night_data_contract.gd` (`NIGHT_TOTALS`, `ROUND_THREE_COUNTS`), `test_balance_acceptance.gd` (`BALANCED_LOST_SEEDS = [3, 9]`, first loss night 3), `test_sim_rules_guard.gd` `MATH_ROOTS`, `test_attribution_log.gd` ordering (`kenney-input-prompts` sorts between `kenney-fantasy-town-kit` and `kenney-mini-characters`).

## Shared Patterns

### Decide-then-resolve damage
**Source:** `simulation/night/pending_hits.gd` (lines 19-36) and `NightSim._resolve_hits` (night_sim.gd:141-150)
**Apply to:** squad attacks, archer arrows, king slam, enemies hitting units. A hit names its target by id; the resolver drops it silently if gone.

### Rejection as value, never push_error
**Source:** `simulation/commands/command_processor.gd:54, 64-66`
**Apply to:** every new intent. `_events.command_rejected.emit(&"<verb>", &"<subject>", reason)` then `return reason`.

### Determinism rules (DR-1 to DR-10)
**Source:** `enemy_system.gd` header, `tests/unit/test_sim_rules_guard.gd`
**Apply to:** everything under `simulation/`: integer ticks, `Vector2` XZ, ascending-id iteration, no wall-clock/OS/`get_tree`, no global RNG, no trig in squad code, float `+ - * /` only. Mouse points enter only as `Vector2i` centimetres in an intent.

### Opt-in new rules keep the smoke golden
**Source:** RESEARCH Pitfall 1; `tests/fixtures/fixture_king_replay_smoke.tres:13-15`
**Apply to:** regeneration (default 0), slam (cooldown 0), military spots (absent from the fixture map). `tests/golden/smoke.json` digest `2599c7c2...` must not change; new rules get the `army` golden.

### Bind-run node convention
**Source:** `input/start_night_hold_controller.gd:21-22`, `presentation/enemies/enemy_views.gd:37-44`, `ui/hud/hud.gd:68`
**Apply to:** all new controllers, views and HUD widgets: `func bind_run(ctx: RunContext, map_root: MapRoot) -> void`, early return if already bound, connect to `ctx.events`, read sim getters in `_process`, never write the sim from presentation.

### Data-driven numbers
**Source:** `simulation/defs/enemy_def.gd` header ("Data only: every number lives in .tres")
**Apply to:** unit, weapon, regen, guard radius, caps, respawn intervals. Add to `MapConfig.validate()` so bad data reports instead of arming.

### Pure model plus thin node
**Source:** `FastForwardController.scale_for` (static, line 54) and the `Hud.physical_label_resolver` injectable Callable
**Apply to:** `SelectionModel`, `DeviceModel`, `GroundCursor`, `GlyphResolver`: pure `RefCounted` with injected clock/layout so GUT tests run without a window.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `input/selection_model.gd` / `selection_math.gd` (box select, 10 control groups, cycling) | model | transform | No selection or group state exists; use RESEARCH Code Examples ("Pure box select") and `target_query.gd` for the pure-static style |
| `input/ground_pick.gd` / `ground_cursor.gd` (ray to ground plane, pad cursor in screen space) | utility | transform | No camera ray picking exists yet; use RESEARCH Pattern 6 and the Code Examples block |
| `ui/hud/king_widget.gd` radial cooldown (`TextureProgressBar` FILL_CLOCKWISE) | component | polling | HUD has only `Label` and `ProgressBar` (start-night fill, `hud.gd:56-60`); follow 03-UI-SPEC.md |
| Mouse/glyph prompt textures (Kenney Input Prompts) | asset | file-I/O | New pack; follow the existing `kenney-mini-characters` entry in `assets/attribution.json` and `ASSETS.md`, PNGs are LFS |

## Metadata

**Analog search scope:** `simulation/`, `input/`, `presentation/`, `ui/hud/`, `data/`, `tools/replay/`, `tests/` (tracked files via `git ls-files`)
**Files read in full or targeted:** enemy_system, tower_system, target_query, pending_hits, night_sim, king_state, king_def, enemy_def, building_tier_def, command_processor, build_intent, run_context (30-91), run_manager (`_enter_dawn`), start_night_hold_controller, fast_forward_controller (1-60), enemy_views (1-120), projectile_vfx (1-60), hud.gd (1-60, 241-300), playtest_bot (1-80), sim_recorder (1-110), replay_scenarios (1-50), sim_signals, sim_events, tower.tres, ranged.tres, test_input_map (1-50), test_enemy_targeting (1-40), project.godot fast_forward block
**Pattern extraction date:** 2026-10-09
