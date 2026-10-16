# Phase 4: Crowd-Scale Battles & Walls - Pattern Map

**Mapped:** 2026-10-16
**Files analyzed:** 44 new/modified (grouped where one analog serves many)
**Analogs found:** 40 / 44 (all analog paths verified git-tracked via `git ls-files`; none is a gitignored mirror)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `simulation/walls/wall_run_def.gd` (new) | model (Resource) | transform | `simulation/defs/build_spot_def.gd` | exact |
| `simulation/defs/build_spot_def.gd` (mod: `wall_run`) | model | CRUD | itself | exact |
| `simulation/walls/wall_system.gd` (new) | service | CRUD + event-driven | `simulation/buildings/building_system.gd` | exact |
| `simulation/walls/wall_solids.gd` (new) | utility (static pure) | transform | `simulation/squads/separation.gd` | role-match |
| `simulation/nav/nav_grid.gd`, `flow_field.gd`, `pathing.gd`, `wall_decision.gd`, `stuck_tracker.gd` (new) | utility / service | transform, batch | `separation.gd` (static, deterministic) + `EnemySystem.desired_step` seam | role-match |
| `simulation/night/enemy_index.gd`, `structure_index.gd` (new) | utility | transform | `simulation/night/target_query.gd` + `EnemySystem._pick_nearest_structure` | role-match |
| `simulation/squads/separation.gd` (mod: grid variant) | utility | transform | itself | exact |
| `simulation/night/enemy_system.gd` (mod) | service | request-response (per tick) | itself | exact |
| `simulation/night/night_sim.gd` (mod) | orchestrator | event-driven | itself | exact |
| `simulation/night/pending_hits.gd` (mod: `KIND_WALL`) | utility | event-driven | itself | exact |
| `simulation/buildings/building_system.gd` (mod: wall filters) | service | CRUD | itself (at the 20 public-method cap) | exact |
| `simulation/run/run_manager.gd` (mod: dawn restore) | service | event-driven | itself `_enter_dawn` | exact |
| `simulation/defs/map_config.gd` (mod: validate walls) | model | transform | itself `validate()` | exact |
| `simulation/defs/building_tier_def.gd` (mod: `effect_line` wall branch) | model | transform | itself | exact |
| `simulation/events/sim_events.gd` + `tests/support/sim_signals.gd` + `tools/replay/sim_recorder.gd` (mod: 3 wall signals) | events | pub-sub | existing `building_*` signals | exact |
| `data/buildings/wall.tres` (new) | config | - | `data/buildings/tower.tres` | exact |
| `data/maps/prototype_map.tres` (mod: 4 wall plots) | config | - | itself (existing spots) | exact |
| `presentation/crowd/crowd_batch.gd` (new) | component | streaming (per frame) | `presentation/enemies/enemy_views.gd` | role-match |
| `presentation/enemies/enemy_views.gd` (rewrite) | component | event-driven + per-frame | itself | exact |
| `presentation/units/unit_views.gd` (rewrite) | component | event-driven + per-frame | `enemy_views.gd` | role-match |
| `presentation/vfx/projectile_vfx.gd` (rewrite arrows) | component | event-driven | itself | exact |
| `presentation/vfx/health_bar_batch.gd`, `death_puff_batch.gd` (new) | component | streaming | `health_bar_3d.gd`, `EnemyViews._spawn_puff` | role-match |
| `presentation/walls/wall_views.gd` (new) | component | event-driven | `presentation/buildings/building_views.gd` + `presentation/vfx/rubble_view.gd` | role-match |
| `presentation/king/king.gd` (mod: push-out) | component | request-response | itself `_physics_process` | exact |
| `presentation/debug/enemy_path_gizmo.gd` (mod/extend: field, stuck) | component | streaming | itself | exact |
| `ui/overlay/debug_overlay.gd` (+ `debug_overlay_model.gd`) (mod) | component | request-response | itself | exact |
| `tools/replay/playtest_bot.gd`, `playtest_strategies.gd`, `replay_scenarios.gd`, `replay_cli.gd`, `balance_report.gd` (mod) | utility | batch | themselves | exact |
| `tests/golden/walls.json` (new) | test fixture | - | `tests/golden/smoke.json` | exact |
| `tools/stress/stress_night.gd/.tscn`, `stress_map.tres`, `frame_report.gd` (new) | tool | batch, file-I/O | `tools/sandbox/hold_pacing_sandbox.gd/.tscn` | role-match |
| `tools/stress/gate_stress.gd` (new, headless) | tool/test | batch | `tools/replay/replay_cli.gd` + `tools/playtest/playtest_cli.gd` | role-match |
| Tests: `test_military_data_contract.gd` (SPOT_COUNT), `test_prototype_map_data.gd`, view tests, new unit tests | test | - | themselves | exact |

## Pattern Assignments

### `simulation/defs/build_spot_def.gd` + `simulation/walls/wall_run_def.gd` (model)

**Analog:** `simulation/defs/build_spot_def.gd` lines 1-9 (full file):
```gdscript
class_name BuildSpotDef
extends Resource
## A fixed build plot. Each spot allows exactly one building type, fixed in map data (D-02).

@export var id: StringName = &""
## World position; only the XZ components matter (y = 0).
@export var position: Vector3 = Vector3.ZERO
## The one building type this spot allows.
@export var building_id: StringName = &""
```
Add `@export var wall_run: WallRunDef` (null = ordinary plot); `WallRunDef` follows the same `class_name X / extends Resource / ## doc / @export typed` shape (fields per RESEARCH Pattern 4). Static typing is mandatory (`untyped_declaration=2`).

### `simulation/walls/wall_system.gd` (service, CRUD + events)

**Analog:** `simulation/buildings/building_system.gd`. BuildingSystem has exactly 20 public methods (the gdlint cap), so walls go in a sibling; do not add public methods to BuildingSystem.

**Constructor/signal emit shape** (`_init` at line 17; `apply_next_tier` lines 112-128):
```gdscript
func apply_next_tier(spot_id: StringName) -> BuildingInstance:
	...
	instance.health = _max_health_of(instance)
	_events.building_built.emit(spot_id, instance.building_id, instance.tier)
	return _snapshot(instance)
```
`WallSystem.on_tier(spot_id, tier)` is driven from `building_built` (composition in `RunContext`) and copies this emit discipline.

**Index addressing** (lines 131-140): hits name targets by index, never by position.
```gdscript
func spot_index(spot_id: StringName) -> int:
	return _order.find(spot_id)
func spot_at_index(index: int) -> StringName:
	if index < 0 or index >= _order.size():
		return &""
	return _order[index]
```
Segment indices are global, ascending, never reused.

**Damage with silent drop and one-shot destroyed event** (lines 179-191):
```gdscript
func damage_building(spot_id: StringName, amount: int) -> void:
	var instance: BuildingInstance = _instances.get(spot_id) as BuildingInstance
	if instance == null or instance.destroyed or amount <= 0:
		return
	var lost: int = mini(amount, instance.health)
	instance.health -= lost
	_events.building_damaged.emit(spot_id, lost, instance.health, _max_health_of(instance))
	if instance.health == 0:
		instance.destroyed = true
		_events.building_destroyed.emit(spot_id, instance.building_id, instance.tier)
```
Copy for `damage_segment` -> `wall_damaged` / `wall_segment_broken`.

**Dawn restore** (lines 194-214): `rebuild_destroyed()` returns ids in MapConfig order; `repair_standing()` heals to `_max_health_of`. `restore_all()` does both for segments and emits `walls_restored(spot_ids)`.

**Pitfall (RESEARCH P5):** a wall plot is a standing building to BuildingSystem; filter it from `EnemySystem._pick_nearest_structure` (`standing_spot_ids()` at lines 143-150), `dawn_income_by_spot` (78), `BuildingViews`, tower/squad systems.

### `simulation/walls/wall_solids.gd`, `simulation/nav/*.gd` (static pure utilities)

**Analog:** `simulation/squads/separation.gd` lines 1-48 (static class, `extends RefCounted`, doc header stating determinism contract, parallel packed arrays, no randomness, fixed tie-break by id parity):
```gdscript
class_name Separation
extends RefCounted
static func displacements(
	positions: PackedVector2Array, radii: PackedFloat64Array, ids: PackedInt64Array
) -> PackedVector2Array:
	...
	if d2 == 0.0:
		direction = Vector2.RIGHT if ids[first] % 2 == 0 else Vector2.DOWN
```
Order of operations per enemy step (RESEARCH P6): move, `Separation.displacements`, then `WallSolids.push_out`. Integer-centimetre quantisation for stored geometry: `roundi(x * 100.0)` as in `MapConfig.ground_limit_cm` (map_config.gd line ~103-106). Gotcha: `(buckets[d] as PackedInt32Array).append(x)` appends to a copy; use flat arrays or Array of Arrays.

### `simulation/night/enemy_system.gd` (service, per-tick)

**Seams to change:**
- `desired_step` (lines 24-27) is the labelled steering seam; keep the exact expression when no intact wall exists (golden protection):
```gdscript
static func desired_step(pos: Vector2, goal: Vector2, max_distance: float) -> Vector2:
	return pos.move_toward(goal, maxf(max_distance, 0.0)) - pos
```
- `_pick_nearest_structure` (lines 207-232): the exact-preserving index must reproduce this scan order (units by ascending id, buildings in spot order, castle last) and test `edge <= aggro and edge < best_edge`. The hot path is lines 200 and 212 (`_units.ids()` copy per enemy per tick).
- Rescan stagger (lines 32-34, 184-185): `is_rescan_tick`, `maxi(SimClock.ticks(def.retarget_interval_seconds), 1)` - cache per def.
- `step` (lines 125-145): `previous = position` snapshot, `_choose_target`, `_advance_and_strike`, then `_separate()`; add the wall decision pass before and `WallSolids.push_out` + stuck tracker after `_separate`.
- Strike enqueue (lines 327-341) is where a `KIND_WALL` strike goes: `hits.enqueue(tick + flight, KIND_ENEMY, record.id, record.target_kind, record.target_id, record.def.attack_damage)` then `_events.attack_fired.emit(...)`.
- `Record` inner class (368-380) gains cached blocker/stuck fields; Pattern 3 comment (lines 3-5) says callers never touch storage, so a packed read accessor (prev/cur `PackedVector2Array`) is the allowed swap.
- `_separate` (347-364) builds parallel arrays in ascending id order; the grid variant must keep ascending-partner accumulation (bit-identical, measured).

### `simulation/night/pending_hits.gd` and `night_sim.gd` (KIND_WALL)

**Analog:** itself. Add alongside lines 8-12:
```gdscript
const KIND_BUILDING := &"building"
const KIND_UNIT := &"unit"
```
-> `const KIND_WALL := &"wall"`; update the `enqueue` doc (lines 18-19). In `night_sim.gd` `_resolve_hits` (163-174) add a branch in the same elif chain:
```gdscript
elif hit.target_kind == PendingHits.KIND_BUILDING:
	_buildings.damage_building(_buildings.spot_at_index(hit.target_id), hit.amount)
```
-> `elif hit.target_kind == PendingHits.KIND_WALL: _walls.damage_segment(hit.target_id, hit.amount)`. NightSim construction (lines 28-46) builds all systems in `_init`; add `WallSystem`, plus `restore_walls()` (RunManager already has 9 `_init` params, cap 10, so reach walls through NightSim). Fixed step order is documented in the file header lines 3-7; insert index rebuild and the wall decision pass between `_castle_attack.step` (line 86) and `_enemies.step` (line 87).

### `simulation/run/run_manager.gd` (dawn restore)

**Analog:** `_enter_dawn` lines 86-99 (file lines, from the `sed 90,219` output offset +89):
```gdscript
var rebuilt: Array[StringName] = _buildings.rebuild_destroyed()
_buildings.repair_standing()
if _castle != null:
	_castle.repair()
...
_events.buildings_rebuilt.emit(rebuilt)
_apply_dawn_payout()
```
Insert `_night.restore_walls()` right after `repair_standing()`, before `buildings_rebuilt.emit` (RESEARCH P5).

### `simulation/events/sim_events.gd`, `tests/support/sim_signals.gd`, `tools/replay/sim_recorder.gd` (new signals)

**Analog:** `building_damaged`/`building_destroyed`/`buildings_rebuilt` (sim_events.gd lines 40-45, each with a `##` doc line). Same-task rule (sim_recorder.gd header lines 8-9): every new signal needs a `SimSignals.ALL` entry, a `SimRecorder.HANDLED` entry (line 12 array), a connection in `attach` (e.g. line 55 `events.building_built.connect(recorder._on_building_built)`) and a handler (lines 144-145):
```gdscript
func _on_building_built(spot_id: StringName, building_id: StringName, new_tier: int) -> void:
	_record("building_built", [spot_id, building_id, new_tier])
```
Integers only in recorded payloads. `test_determinism.gd` fails when one is missing; `test_debug_overlay_readonly.gd` has the drift guard.

### `simulation/defs/map_config.gd` (validate) and `building_tier_def.gd`

**Analog:** `validate()` lines 110-175 collects `errors.append(...)` strings per spot/building (spot loop at ~152-166) and delegates to `_validate_*` helpers; add `errors.append_array(_validate_walls())` next to `_validate_squads()` (line 175-176). Minimum gap 3 m error and gap/segment checks go there; tests mutate the map and assert on the error list (`test_prototype_map_data.gd` lines 180-250).
`effect_line()` (building_tier_def.gd 26-33) is an if-chain returning `""` as fallback; add a wall branch before the fallback.

### `data/buildings/wall.tres` (config)

**Analog:** `data/buildings/tower.tres` (full file): `[gd_resource type="Resource" script_class="BuildingDef" load_steps=...]`, `ext_resource` for `building_tier_def.gd` and `building_def.gd`, one `sub_resource` per tier (`cost`, `max_health`, ...), `[resource]` with `id = &"wall"`, `display_name`, `body_radius`, `tiers = Array[ExtResource("1_tier")]([...])`. Wall tiers set only `cost` and `max_health`. Register the def in `prototype_map.tres` `buildings` array; append 4 `BuildSpotDef` sub-resources AFTER the existing ten (test pins first-N order and positions: `test_prototype_map_data.gd` lines 56-88).

### Tests pinning the plot list

- `tests/unit/test_military_data_contract.gd` line 22 `const SPOT_COUNT: int = 10` and line 104 `assert_eq(map.spots.size(), SPOT_COUNT, "ten plots (D-03)")`: becomes 14 (or counts non-wall plots plus `WALL_PLOT_COUNT = 4`).
- `tests/unit/test_prototype_map_data.gd`: `HOUSE_SPOT_COUNT`/`TOWER_SPOT_COUNT` (lines 8-9, 82-83) stay; lines 84-88 assert each appended plot has a building with `unit_id != &""` - wall plots break this loop; filter by `wall_run == null`. Lines 95-115 (ride-time bounds over all spots) also need a wall-plot decision.

### `presentation/crowd/crowd_batch.gd`, `enemy_views.gd`, `unit_views.gd` (MultiMesh)

**Analog:** `presentation/enemies/enemy_views.gd` (200 lines).
**bind_run + signal wiring** (lines 37-44) is the pattern to keep:
```gdscript
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.enemy_spawned.connect(_on_enemy_spawned)
```
**Interpolation to preserve** (lines 65-76): `blend = _ctx.alpha() if night_running else 1.0`, `previous_position_of(id).lerp(position_of(id), blend)`; moves into the batch fill from packed prev/cur arrays.
**Cap/degrade** (lines 10-11, 80-81): `MAX_VIEWS` -> per-archetype capacity 512; over-capacity spawns are simply not drawn.
**Visual constants to carry** (16-28): `GRUNT_COLOR`, `SKIRMISHER_COLOR`, `SKIRMISHER_HEIGHT`, `SKIRMISHER_RADIUS_FACTOR`, `FLASH_SECONDS = 0.15`, `EMISSION_ENERGY`, `FLASH_ENERGY`.
**Hurt-only bar rule** and `HealthBar3D.should_show` in `presentation/vfx/health_bar_3d.gd`.
**Test hooks to keep as thin mirror readers:** `view_count()` (47), `puff_count()` (52), `get_view()` (61). Tests that touch puppet internals (`get_view(id).get_node("HealthBar")`, `emission_energy_multiplier`) must be rewritten against the CPU mirror (headless MultiMesh returns nothing). Files that reference these hooks include `tests/e2e/test_unit_views.gd`, `test_projectiles_visible.gd`, `test_spawn_telegraph.gd`, `test_overlay_paths.gd`, `test_night_tracer_scene.gd`, `test_squad_tracer_scene.gd`, `test_order_markers.gd`, `test_selection_steering.gd`, `test_stretch_coordinates.gd`, `test_king_knockout.gd` and about 20 more (grep `get_view\|puff_count\|view_count\|HealthBar\|live_count` in `tests/`; RESEARCH counts ~107 refs in 25 files).
**UnitViews** (`MAX_VIEWS` line 12, `MODEL_DIR`/`MODEL_FILES` 18-24, `_load_model` 147, `_make_capsule` 157 is the headless fallback): bake via `bake_mesh_from_current_skeleton_pose()` in a real renderer, capsule fallback when null. `SelectionRings.MAX_RINGS` (presentation/units/selection_rings.gd line 11) is tied to `UnitViews.MAX_VIEWS`.
**Death puff** to replace (EnemyViews 122-155): `CPUParticles3D` + `create_timer`, `MAX_PUFFS = 64`.

### `presentation/vfx/projectile_vfx.gd`

**Analog:** itself. Keep `flight_seconds`/`arc_height` statics (lines 49-60, `ARC_PER_METRE`, `MAX_ARC_HEIGHT`), `_on_attack_fired` (111) and `_draws_arrows` (148) logic; replace the `Flight` node list (`_flights`, line 41; `MAX_PROJECTILES = 128`, line 13) with a ring batch of 512 with per-instance colour (TOWER/SKIRMISHER/UNIT_ARROW colours lines 19-23). Slashes stay nodes (`MAX_SLASHES = 8`). `live_count()` (75) becomes a mirror reader.

### `presentation/walls/wall_views.gd`

**Analogs:** `presentation/buildings/building_views.gd` (per-spot view bound to events; swaps rubble back for the model at dawn) and `presentation/vfx/rubble_view.gd` lines 1-30 (deterministic fixed `SLABS` pattern, no randomness, primitives only, visual only, never blocks). Models: Kenney Castle Kit `wall.glb` already imported and logged in `ASSETS.md`.

### `presentation/king/king.gd` (solidity)

**Analog:** itself lines 75-85:
```gdscript
var speed: float = move_speed(def, Input.is_action_pressed(&"sprint"))
var target: Vector3 = Vector3(direction.x * speed, 0.0, direction.y * speed)
velocity = velocity.move_toward(target, def.acceleration * delta)
velocity.y = 0.0
move_and_slide()
global_position.y = 0.0
```
Call `WallSolids.push_out` (static, pure) on the XZ position right after `move_and_slide()`. The bot twin is `tools/replay/playtest_bot.gd` `_move_king` (lines 180-200), which does `here.move_toward(goal, pace)`; apply the same pure function there so bots and player are identical.

### `presentation/debug/enemy_path_gizmo.gd` and `ui/overlay/debug_overlay.gd`

**Analog:** `enemy_path_gizmo.gd` lines 1-115: `ImmediateMesh` + unshaded vertex-colour material (24-32), `refresh()` clears, gates on `_overlay.is_overlay_visible()` and NIGHT, builds `Array[Dictionary]` of `{"from","to","color"}` then one `surface_begin(PRIMITIVE_LINES)` (57-80), colour constants per kind (9-15), `_lifted(Vector2)` helper. Add field arrows (cache per field version) and stuck-enemy colour as more segment kinds in `_segments()`. It reads via getters only (DR-11); new sim getters must be read-only. Overlay text sections: follow `tests/unit/test_debug_overlay_*` and `ui/overlay/debug_overlay_model.gd` (frame-time and field readouts); `test_debug_overlay_readonly.gd` asserts no SimEvents signal fires.

### Tools: `tools/stress/*`

**Analog (scene, real window, map swap):** `tools/sandbox/hold_pacing_sandbox.gd` lines 1-40: header doc with launch command `bash tools/godot.sh --path . res://tools/sandbox/hold_pacing_sandbox.tscn`, "tools/ is excluded from the export (export_presets.cfg exclude_filter)", deep-copy the shipped map, `scene.instantiate()`, set `_map_root.map_config`, `add_child`. Stress map is a separate `.tres` under `tools/stress/`.
**Analog (headless CLI gate):** `tools/replay/replay_cli.gd`, `tools/playtest/playtest_cli.gd`, wrappers `tools/replay.sh`, `tools/playtest.sh`, `tools/_common.sh`, `tools/godot.sh`. CLI accepts only fixed scenario names, no path arguments (`replay_scenarios.gd` header lines 1-26: `NAMES` array, `GOLDEN_DIR`, per-platform key `DEFAULT_KEY`). A `walls` scenario adds a name to `NAMES`, constants like `SMOKE_MAP/SMOKE_BUILD_ORDER` and `SMOKE_MAX_TICKS`, and `tests/golden/walls.json` (same shape as `smoke.json`). Frame-time report writes JSON via `FileAccess` + `JSON.stringify`, screenshots via `tools/screenshot.sh`/`shot_runner`.
**Bots:** `tools/replay/playtest_strategies.gd` build orders and `playtest_bot.gd`; balance reporting in `balance_report.gd` and `tests/integration/test_balance_acceptance.gd` / `test_balance_report.gd` (7 or 8 of seeds 1-10 bar). Goldens tests: `tests/integration/test_replay_golden.gd`, `test_army_replay_golden.gd`.

## Shared Patterns

### Determinism (sim code)
**Source:** `separation.gd` header (lines 3-13), `pending_hits.gd` header (1-6), `night_sim.gd` header (1-7).
**Apply to:** everything under `simulation/`: integer ticks via `SimClock.ticks(...)`, seeded RNG only, ids only grow, iterate in id order, no scene tree/OS/Input/`NavigationServer`/time scale. Verify with `bash tools/replay.sh --scenario=<x> --twice --expect-file=tests/golden/<x>.json`; `smoke`/`army` digests must stay byte-identical through the MultiMesh and hot-path plans (D-13).

### Decide-then-resolve damage
**Source:** `pending_hits.gd` + `night_sim.gd` `_resolve_hits`. Hits name targets by id/index, dropped silently when gone.

### Presentation reads, never writes
**Source:** `enemy_views.gd` `bind_run`, `enemy_path_gizmo.gd`. Guarded by `test_debug_overlay_readonly.gd`.

### Lint/format caps
`.gdlintrc`: `max-public-methods: 20`, `max-file-lines: 1000`, `max-line-length: 100`, `function-arguments-number: 10`, `max-returns: 6`; 20 tests per script. `enemy_system.gd` has 16 public methods (room for ~4); `map_config.gd` is 541 lines. Run `tools/lint.sh`.

### Data tunables in `.tres`
**Source:** `data/buildings/tower.tres`, `data/tuning/loop_tuning.tres` (+ `simulation/defs/loop_tuning.gd`). Wall costs/health, N (stuck seconds), decision cadence (0.5 s as whole ticks) are data; add exports to `LoopTuning` or `EnemyDef` rather than constants.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `simulation/nav/flow_field.gd` (Dial buckets) | utility | batch | No grid/pathfinding code exists; use RESEARCH F4/F5 prototypes (flat parallel arrays, 2 m cells, 10/14 costs, no diagonal squeeze) |
| `simulation/nav/nav_grid.gd` (Bresenham `line_blocked`) | utility | transform | No spatial grid exists yet |
| `presentation/crowd/crowd_batch.gd` MultiMesh buffer fill | component | streaming | No MultiMesh use in the repo; layout is stride 16/20 per RESEARCH F6 |
| Instance shader (flash, billboard bar, puff) | shader | - | No `.gdshader` in the repo; see RESEARCH F6 |
| `tools/stress/frame_report.gd` | tool | file-I/O | No frame-time tooling; RESEARCH F2 `stress_frames.gd` probe (scratchpad, untracked) is the only source |

## Metadata

**Analog search scope:** `simulation/`, `presentation/`, `ui/overlay/`, `tools/`, `data/`, `tests/` (git-tracked files only).
**Files read:** enemy_system, night_sim, pending_hits, separation, build_spot_def, building_system (signatures and 105-215), run_manager (90-219), enemy_views, enemy_path_gizmo (1-120), plus signature greps of unit_views, projectile_vfx, map_config, replay_scenarios, sim_recorder, hold_pacing_sandbox, king, rubble_view, tower.tres.
**Pattern extraction date:** 2026-10-16
