# Phase 2: Night Defense & Playtest Gate - Pattern Map

**Mapped:** 2026-10-03
**Files analyzed:** 46 new or modified (grouped below)
**Analogs found:** 40 exact or role-match / 46; 6 have no close analog

All analog paths were verified with `git ls-files` (tracked). `.tools/`, `.godot/`, `build/` are not used. New filenames come from RESEARCH.md "Recommended Project Structure" and may be renamed by the planner; the analog and excerpt matter more than the name.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `simulation/defs/enemy_def.gd`, `spawn_point_def.gd`, `spawn_group_def.gd`, `night_def.gd` | model (Resource def) | config | `simulation/defs/building_tier_def.gd`, `king_def.gd` | exact |
| `simulation/defs/map_config.gd` (+enemies, spawn_points, nights, validate) | model | config | itself (extend) | exact |
| `simulation/defs/building_tier_def.gd`, `king_def.gd`, `loop_tuning.gd` (+fields) | model | config | themselves | exact |
| `data/enemies/grunt.tres`, `ranged.tres` | config | config | `data/buildings/tower.tres` | exact |
| `data/maps/prototype_map.tres`, `data/buildings/*.tres`, `data/king/king.tres`, `data/tuning/loop_tuning.tres` | config | config | themselves | exact |
| `simulation/night/night_sim.gd`, `enemy_system.gd`, `tower_system.gd`, `pending_hits.gd`, `target_query.gd`, `wave_schedule.gd` | service (sim system) | event-driven / batch | `simulation/buildings/building_system.gd` | role-match |
| `simulation/king/king_state.gd`, `simulation/castle/castle_state.gd`, `simulation/run/run_stats.gd` | service (state) | CRUD + events | `simulation/buildings/building_system.gd`, `simulation/economy/economy.gd` | role-match |
| `simulation/clock/sim_clock.gd`, `sim_rng.gd` | utility | transform | none (use RESEARCH snippets) | no analog |
| `simulation/run/run_manager.gd`, `run_context.gd` | service / composition root | request-response | themselves | exact |
| `simulation/buildings/building_system.gd`, `building_instance.gd` | service / model | CRUD | themselves | exact |
| `simulation/events/sim_events.gd` | event bus | pub-sub | itself | exact |
| `tests/support/sim_signals.gd` | test support | n/a | itself | exact |
| `presentation/enemies/enemy_views.gd` | component (view) | event-driven | `presentation/buildings/building_views.gd`, `presentation/vfx/coin_drip_vfx.gd` | role-match |
| `presentation/vfx/health_bar_3d.gd`, `rubble_view.gd`, `projectile_vfx.gd` | component (vfx) | event-driven | `presentation/vfx/coin_drip_vfx.gd` | role-match |
| `presentation/buildings/building_views.gd` (rubble, castle hp) | component | event-driven | itself | exact |
| `presentation/map/map_root.gd` (fixed-step `advance`) | controller | request-response | itself | exact |
| `presentation/king/king.gd` (`bind_run`, downed) | component | event-driven | `ui/hud/hud.gd` bind_run | partial |
| `presentation/debug/enemy_path_gizmo.gd` | component | event-driven | none close (`xray_silhouette.gd` for a node helper) | weak |
| `ui/world/spawn_telegraph.gd` | component | event-driven | `ui/hud/dawn_payout_vfx.gd` (projects anchors) | role-match |
| `ui/results/results_screen.gd/.tscn` | component | request-response | `ui/hud/hud.gd/.tscn` | role-match |
| `ui/hud/hud.gd`, `dawn_payout_vfx.gd` | component | event-driven | themselves | exact |
| `ui/overlay/night_overlay_sections.gd` | component | request-response | `ui/overlay/debug_overlay.gd` `register_section` | exact |
| `tools/replay/replay_driver.gd`, `sim_recorder.gd`, `playtest_bot.gd`, `replay_cli.gd` | utility / CLI | batch | `tools/sandbox/hold_pacing_sandbox.gd`, `tools/screenshot/shot_runner.gd` | partial (replay recorder: none) |
| `tools/replay.sh`, `tools/playtest.sh` | script | batch | `tools/screenshot.sh`, `tools/test.sh`, `tools/_common.sh` | exact |
| `tools/screenshot/shot_scenarios.gd` + `tools/screenshot.sh` (new shots) | script | request-response | themselves | exact |
| `.github/workflows/ci.yml` (replay step) | config | batch | its `test` job | exact |
| New unit tests (sim, defs contracts, determinism scan) | test | n/a | `tests/unit/test_run_manager.gd`, `test_loop_tuning_contract.gd`, `test_dawn_income.gd` | exact |
| New e2e tests, migrated Phase 1 tests | test | n/a | `tests/e2e/e2e_support.gd` + `tests/e2e/test_dawn_payout.gd` | exact |

## Pattern Assignments

### Resource def classes: `enemy_def.gd`, `spawn_point_def.gd`, `spawn_group_def.gd`, `night_def.gd` (+ new fields on `BuildingTierDef`, `KingDef`, `LoopTuning`)

**Analog:** `simulation/defs/building_tier_def.gd` (data only, `@export` with typed defaults, `##` doc comment on every field, no logic beyond a pure helper).

```gdscript
class_name BuildingTierDef
extends Resource
## One purchasable tier of a building. Data only: every number lives in .tres (D-09).

## Gold price of this tier.
@export var cost: int = 1
## Attack range in metres (0.0 for non-defense buildings).
@export var attack_range: float = 0.0
## Damage per hit (0 for non-defense buildings).
@export var attack_damage: int = 0
```

Add `max_health`, `attack_interval`, `projectile_speed` the same way. Keep sentinels documented as "0 means melee" etc. `class-definitions-order` in `.gdlintrc`: signal, enum, const, then vars.

**Tuning field analog** (`simulation/defs/loop_tuning.gd` lines 33-40): scalar `@export` plus a doc comment that names the decision (D-xx). Add respawn start/step/cap (D-01/D-02), loss beat seconds (D-17), re-scan interval here. A `const` min/max pair with a pure helper (lines 10-16, 47) is the precedent for a sanitising helper such as `respawn_seconds(knockout_n)`.

### `data/enemies/grunt.tres`, `ranged.tres`

**Analog:** `data/buildings/tower.tres` (script ExtResource, flat property list; sub_resources for nested defs).

```
[gd_resource type="Resource" script_class="BuildingDef" load_steps=5 format=3]
[ext_resource type="Script" path="res://simulation/defs/building_tier_def.gd" id="1_tier"]
...
[resource]
script = ExtResource("2_def")
id = &"tower"
tiers = Array[ExtResource("1_tier")]([SubResource("Resource_tier1"), SubResource("Resource_tier2")])
```

Typed arrays are written `Array[ExtResource("id")]([...])`. The same form applies to `MapConfig.enemies/spawn_points/nights`. `data/tuning/loop_tuning.tres` shows the flat-scalar form.

### `simulation/defs/map_config.gd` (extend `validate()`)

**Analog:** itself, lines 19-60. `validate()` returns a `PackedStringArray`, never blocks, skips null entries with `continue`, and tracks ids in a `Dictionary`. Copy:

```gdscript
var spot_ids: Dictionary = {}
for spot: BuildSpotDef in spots:
	if spot == null:
		errors.append("a spot entry is empty")
		continue
	if spot_ids.has(spot.id):
		errors.append("duplicate spot id '%s'" % spot.id)
	spot_ids[spot.id] = true
	if not building_ids.has(spot.building_id):
		errors.append("spot '%s' uses unknown building id '%s'" % [spot.id, spot.building_id])
```

Order-significance comment (line 14) applies to the new arrays. `RunContext._init` pushes each error with `push_error` (lines 16-17), so test fixtures with bad data must not use the shipped path.

### Contract tests that pin shipped values

**Analog:** `tests/unit/test_loop_tuning_contract.gd` (lines 1-40). Header doc names the decisions pinned; values come from `load(TUNING)` / `load(PROTOTYPE_MAP)`, helpers derive from data (`_tier_costs()`), constants carry the owner reasoning (`OWNER_FLOOR_S`, with "retuning it means updating this pin with the owner"). Use it for: `SimClock.STEP`, respawn cap 15 s, 8 nights, 1..3 spawn points, the first three RNG outputs for seed 12345 (DR-4). Companion: `tests/unit/test_prototype_map_data.gd` for map shape pins.

### Simulation systems: `night_sim.gd`, `enemy_system.gd`, `tower_system.gd`, `pending_hits.gd`, `king_state.gd`, `castle_state.gd`, `run_stats.gd`

**Analog:** `simulation/buildings/building_system.gd`. `RefCounted`, constructed with `(map, events)`, private `_events`, `_order` plus `Dictionary` state, reads return copies or snapshots, one mutation entry point, events emitted after the state change, null-tolerant against data errors that `validate()` already reported.

```gdscript
class_name BuildingSystem
extends RefCounted
var _events: SimEvents
var _order: Array[StringName] = []
var _spots: Dictionary = {}
func _init(map: MapConfig, events: SimEvents) -> void:
	_events = events
	for spot: BuildSpotDef in map.spots:
		if spot == null or spot.id == &"" or _spots.has(spot.id):
			continue
		_order.append(spot.id)
```

```gdscript
func spot_ids() -> Array[StringName]:
	return _order.duplicate()      # reads return copies (lines 35-37)
func apply_next_tier(spot_id: StringName) -> BuildingInstance:
	...
	_events.building_built.emit(spot_id, instance.building_id, instance.tier)
	return _snapshot(instance)     # snapshots, lines 135-143
```

Apply to: id-ordered iteration (use `_order`-style arrays, never Dictionary-sorted), snapshot getters (`position_of(id)`), a `_snapshot` copy helper. Typed `for x: Type in ...` is mandatory (`untyped_declaration=2`). `.gdlintrc` limit `max-public-methods: 20`, so split into systems. Near-spot query (lines 99-111) is the pattern for `TargetQuery.nearest`: squared or plain XZ distance, `INF` initial best, strict `<` so the earlier index wins ties.

For `KingState`/`CastleState` (hp + events): `simulation/economy/economy.gd` is the small-state-owner precedent (not read this session; open it for the `_events.gold_changed.emit` shape before writing).

`BuildingInstance` (`simulation/buildings/building_instance.gd`) is three plain vars; add `health: int`, `destroyed: bool`, `rebuilt_this_dawn: bool` there and copy them in `BuildingSystem._snapshot`.

### `simulation/run/run_manager.gd` (WON/LOST, night hooks, dawn rebuild)

**Analog:** itself. Exact extension points:

- `enum RunPhase { DAY, NIGHT_TRANSITION, NIGHT, DAWN }` (line 9): append `WON`, `LOST`.
- `_night_should_end()` (lines 93-94): becomes `night.is_cleared()` with the waveless fallback `_phase_elapsed >= _tuning.placeholder_night_seconds`.
- `_enter_dawn()` (97-99) and `_apply_dawn_payout()` (111-118): call `rebuild_destroyed()` before payout.
- `start_night()` (66-73): `begin_night(_night_number)` before `night_started.emit`.
- `_change_phase` (121-125) is the only place `_phase` is assigned.

```gdscript
func _enter_dawn() -> void:
	_change_phase(RunPhase.DAWN)
	_apply_dawn_payout()
```

Constraint: `_phase =` may appear only in `run_manager.gd` (source-scan test, below). Name other fields differently (e.g. `_king_state`, not `_phase`). The constructor takes explicit collaborators `(events, economy, buildings, tuning)`; add `night`/`king`/`castle`/`stats` as trailing args or setters and keep `RunContext.new(map, tuning)` 2-arg compatible (15 test files use it).

### `simulation/run/run_context.gd` (step/advance, systems)

**Analog:** itself (lines 14-23): composition root, builds `SimEvents` first, then each system receives `events`. Add `SimRecorder` connection first (DR-11), then new systems, with `step()` and `advance(real_delta)` per RESEARCH Pattern 1. `get_enemy_count()` (lines 31-33) returns 0 today; wire it to `night.enemy_count()` (feeds the Agents overlay row).

### `simulation/events/sim_events.gd` and `tests/support/sim_signals.gd`

**Analog:** `sim_events.gd` lines 6-19: one `##` doc line then one `signal` per event, typed args.

```gdscript
## Dawn income was paid. `per_spot` maps spot_id to amount in MapConfig order, amount > 0 only.
signal dawn_payout(total: int, per_spot: Dictionary)
```

Drift guard: `tests/support/sim_signals.gd` `ALL` (lines 9-17) lists the 7 current names. Every new signal must be added to `SimSignals.ALL` in the same task, or `test_the_watched_signals_are_every_signal_the_simulation_declares` in `tests/unit/test_debug_overlay_readonly.gd` fails.

### Presentation views: `enemy_views.gd`, `health_bar_3d.gd`, `rubble_view.gd`, `projectile_vfx.gd`, updated `building_views.gd`

**Analog:** `presentation/buildings/building_views.gd`. Pattern: `bind_run(ctx, _map_root)` stores `_ctx`, builds initial views, connects to `ctx.events.*`; views keyed by id in a `Dictionary`; a single seam picks catalog model else primitive; materials built in a helper.

```gdscript
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx
	_add_castle(ctx.map.castle_position)
	for spot_id: StringName in ctx.buildings.spot_ids():
		_add_marker(spot_id)
	ctx.events.building_built.connect(_on_building_built)

func _on_building_built(spot_id: StringName, building_id: StringName, new_tier: int) -> void:
	var old_view: Node3D = get_view(spot_id)
	if old_view != null:
		remove_child(old_view)
		old_view.queue_free()
	var view: Node3D = _make_visual(building_id, new_tier)
	view.set_meta(&"tier", new_tier)
	add_child(view)
	view.position = _ctx.buildings.get_spot(spot_id).position
	_views[spot_id] = view
```

Integration points: `_on_building_built` is where `building_destroyed` (swap to rubble) and `buildings_rebuilt` (re-instance at same tier) hook; `_add_castle` (line 49 comment "Landmark only in Phase 1") gains hp bar and collapse. Nodes become run-bound by being in group `run_bound` (see `MapRoot._ready`, below), which is how `EnemyViews` gets `bind_run`.

**VFX analog:** `presentation/vfx/coin_drip_vfx.gd` (lines 13-32 const block with named caps `MAX_BURST_COINS`, lines 34-40 private state, lines 45-52 `static` pure helpers testable without a scene, lines 55-62 `bind_run`, a read-only test hook `get_last_burst_delays()` lines 76-78, `live_coin_count()` skipping `is_queued_for_deletion()`). Copy for `ProjectileVfx` / enemy puppet pool: cap visuals, expose static pure helpers (flight time, interpolation alpha) with unit tests like `tests/unit/test_coin_drip_flight.gd`, never touch sim state.

### `presentation/map/map_root.gd` (fixed-step clock)

**Analog:** itself. The line to replace:

```gdscript
const MAX_SIM_STEP: float = 0.25
...
func _process(delta: float) -> void:
	_ctx.run_manager.tick(minf(delta, MAX_SIM_STEP))
```

Becomes `_ctx.advance(delta)` (keep the clamp). Binding loop (lines 22-25) is the pattern for `king.bind_run`/`EnemyViews`:

```gdscript
for node: Node in get_tree().get_nodes_in_group(&"run_bound"):
	if node != self and is_ancestor_of(node):
		node.call(&"bind_run", _ctx, self)
```

`MapRoot` builds `RunContext.new(map_config, loop_tuning)` at line 20; pass the king def and a run seed as the trailing optional args.

### `ui/results/results_screen.gd/.tscn`, `ui/world/spawn_telegraph.gd`, HUD changes

**Analog:** `ui/hud/hud.gd`: `CanvasLayer`, `bind_run` guarded against repeat (`if _ctx != null: return`, lines 55-58), `%UniqueName` `@onready` labels, player copy as top-level `const` strings (lines 13-16; the night banner `"Night %d — no enemies yet"` is the one to replace), connects to `ctx.events.phase_changed` and `gold_changed`, a `_refresh()` entry point. Mouse is for menus only, so give the results buttons `grab_focus()` for keyboard/gamepad. Test handler signals, never call `get_tree().quit()` in GUT.

**Telegraph analog:** `ui/hud/dawn_payout_vfx.gd` (a `Control` overlay that projects world anchors to screen; also the dawn crossed-out coin, D-14, goes here). Read it before writing the telegraph: it is the existing `unproject_position` precedent.

### `ui/overlay/night_overlay_sections.gd`

**Analog:** `ui/overlay/debug_overlay.gd` lines 61-92: `register_section(title: String, provider: Callable, lifetime_owner: Variant = null)` is safe before or after `bind_run`; replays pending entries in order; title replaces in place. Default titles `Perf/Loop/Agents` cannot be reused. Register from a helper called by `DebugOverlay.bind_run`, so `DebugOverlayModel` is unchanged and the bare-model default-section test still passes. Check `tests/unit/test_debug_overlay_registration.gd` before changing live overlay output.

### Tests

**Pure-sim unit test (no scene tree):** `tests/unit/test_run_manager.gd` lines 1-30.

```gdscript
extends GutTest
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const TUNING := "res://data/tuning/loop_tuning.tres"
func before_each() -> void:
	_tuning = load(TUNING)
func _context() -> RunContext:
	return RunContext.new(load(PROTOTYPE_MAP), _tuning)
func _into_night(ctx: RunContext) -> void:
	assert_eq(ctx.commands.submit(StartNightIntent.new()), CommandProcessor.OK, "the night starts")
```

`_into_dawn` (lines 26-29) ticks `_tuning.placeholder_night_seconds + 0.1`: this and about a dozen other Phase 1 tests rely on the placeholder night; migrate by giving them a waveless map copy (`E2eSupport.waveless_prototype_map()`, to add, using the deep-copy pattern below). Durations always come from `loop_tuning.tres`.

**Source-scan test (copy for the DR-5 forbidden-token scan):** `tests/unit/test_run_manager.gd` lines 189-205: `_gd_files(dir)` recursive `DirAccess` walk (lines 32-42), `RegEx.create_from_string`, per-line search, asserts `scanned > 20` (proves the scan read files) and that the pattern matches the real owner (proves the pattern is not vacuous). Keep both sanity assertions in the new scan.

**Data-isolation pattern:** `tests/e2e/e2e_support.gd` lines 21-35: `shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` then mutate a tier. A shallow `duplicate(true)` leaks edits through shared `house.tres`/`tower.tres`. Note `tests/unit/test_dawn_income.gd` line 23 uses shallow `duplicate(true)` only to change `starting_gold` (a scalar), which is safe. Use deep for any new test that edits a def (DR-12). `E2eSupport.spawn_map(test, map_config, tuning)` (lines 56-67) is the scene-level entry; `wait_until` (72-77) polls by real time; `teleport_king` (87-88) is how e2e places the king.

**Derived-from-data expectations:** `tests/unit/test_dawn_income.gd` (header: "Expectations come from house.tres and tower.tres so Phase 2 tuning cannot break them", `_income(tier)` reads the `.tres`). Apply the same to combat tests so balance retunes do not break them.

**Signal assertions:** `watch_signals(ctx.events)` then assert (test_run_manager line 54).

### Tools: `tools/replay.sh`, `tools/playtest.sh`

**Analog:** `tools/screenshot.sh` and `tools/test.sh`, both sourcing `_common.sh`.

```bash
set -u
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)/_common.sh"
GODOT_BIN="$(duskhold_godot_bin)"
if [ ! -x "${GODOT_BIN}" ] && [ ! -f "${GODOT_BIN}" ]; then
  echo "Godot ${DUSKHOLD_GODOT_VERSION} is not installed; run: python tools/bootstrap.py --godot --yes (after owner approval)" >&2
  exit 3
fi
```

Conventions to copy: usage comment block at the top, `set -u`, every expansion quoted (repo path contains a space), `DUSKHOLD_ROOT` vs `DUSKHOLD_ROOT_NATIVE` (use the native form for `--path` and for paths passed to Godot), exit 3 for missing Godot, exit 64 for bad usage (screenshot.sh line 43), output under git-ignored `build/` (`mkdir -p`), logs kept for diagnosis (screenshot.sh lines 48-59), `timeout` around the run (line 80), propagate the Godot exit status. Unlike screenshots, replay runs **can** be `--headless` (no renderer needed). Pattern for the headless run: `test.sh` lines 26-36 (import warm-up, then the run, `PIPESTATUS`, a missing-output-file check, and the first-party parse-error grep, lines 47-52, which `replay.sh` should reuse because a script parse error otherwise drops silently). User args after `--` as in screenshot.sh line 83 (`-- "--shot=${shot}" "--out=${OUT_DIR_NATIVE}"`). Unknown-name validation loop: screenshot.sh lines 37-46.

### `tools/replay/replay_cli.gd` and bots

**Analog (CLI scene/script skeleton):** `tools/sandbox/hold_pacing_sandbox.gd` (class doc with the exact launch command, `tools/ is excluded from the export`, builds a `MapConfig` via `duplicate_deep(DEEP_DUPLICATE_ALL)`, instantiates `MAP_SCENE_PATH`). For a headless script with no scene, RESEARCH verified `extends SceneTree` with `-s`, user args via `OS.get_cmdline_user_args()`, and `quit(code)` propagation. Bots drive the sim only through `ctx.commands.submit(BuildIntent.new(spot_id))` / `StartNightIntent.new()` and `KingState.report_position`, as `ShotScenarios` does ("through the Input Map actions or the command intents in `ctx.commands`, never by writing simulation state directly", `tools/screenshot/shot_scenarios.gd` lines 3-5).

### `tools/screenshot/shot_scenarios.gd` + `tools/screenshot.sh` (new shots: night combat, telegraph, results, rubble)

**Analog:** itself. A shot is registered in three places that must agree: the `StringName` const + `ALL_SHOTS` array (lines 24-39), the `match` in `run()` (lines 44-58), and the bash `ALL_SHOTS=(...)` array and header comment (screenshot.sh lines 4-6, 21). `test_shot_blank_check.gd` guards blank images. Existing scenarios rely on the 4 s placeholder night (`NIGHT_BANNER`, `DAWN_PAYOUT`, `BANNER_WAIT_S`): they need a waveless map or updating (RESEARCH Pitfall 2).

### `.github/workflows/ci.yml`

**Analog:** the `test` job (lines 43-78): checkout (`lfs: false`), LFS cache, `setup-python`, Godot cache keyed on `tools/godot_version.txt` + `godot_sha512sums.txt`, `python tools/bootstrap.py --godot --yes --platform linux`, then `bash tools/test.sh`, then `upload-artifact` with `if: always()`. Add the replay determinism step after "Headless import and GUT" in the same job (reuses the cached Godot) and upload the report from `build/`. Every action stays pinned to a full commit SHA with a trailing version comment; copy the SHAs verbatim, do not retype them. The `screenshots` job (118-165) is the model if a rendered check is added.

## Shared Patterns

### Read-only presentation bound through `bind_run`
**Source:** `presentation/buildings/building_views.gd` lines 36-42, `ui/hud/hud.gd` lines 55-58, `presentation/map/map_root.gd` lines 22-25. **Apply to:** every new view, HUD piece, overlay section, results screen. Views join group `run_bound`, take `(ctx: RunContext, map_root: MapRoot)`, connect to `ctx.events`, ignore a repeat bind, and never mutate sim state. The sim never listens to presentation (`sim_events.gd` header).

### Rejections return a reason, never `push_error`
**Source:** `command_rejected(command, spot_id, reason)` in `sim_events.gd` line 11; `building_system.gd` returns `null` with nothing changed (lines 116-121); `start_night()` returns `false` (line 67). GUT counts engine errors as failures. **Apply to:** all new sim entry points (damage on a gone target drops silently, per Pattern 2).

### Data errors are reported by `validate()` and tolerated at runtime
**Source:** `map_config.gd` `validate()`; `building_system.gd` lines 17-31 skip null, empty and duplicate ids. **Apply to:** every system that indexes into the new `enemies`, `spawn_points`, `nights` arrays.

### Phase writer is unique
**Source:** `run_manager.gd` `_change_phase`; guarded by the source-scan test. **Apply to:** terminal states and the castle-destroyed handler, which must be inside `RunManager` (update the "one phase change per tick" doc comment at lines 4-7 and the one at line 12 of RESEARCH).

### Everything tunable lives in `.tres`
**Source:** `building_tier_def.gd` header (D-09), `loop_tuning.gd`, `data/*`. **Apply to:** all combat numbers, respawn cap, loss-beat seconds, wave compositions.

### Static typing is a compile error to omit
**Source:** `project.godot:19 gdscript/warnings/untyped_declaration=2`. Every `var`, `for` iterator and lambda parameter needs a type. Lint: `max-line-length 100`, `max-returns 6`, `function-arguments-number 10`, `max-file-lines 1000`, `max-public-methods 20`.

### Deep-copy test data, never mutate the loaded `.tres`
**Source:** `tests/e2e/e2e_support.gd` lines 16-35. **Apply to:** all tests and tools that vary maps or defs (DR-12).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `simulation/clock/sim_clock.gd` (fixed-step accumulator, tick helpers) | utility | transform | The only time code is `MapRoot._process` clamp and `RunManager._elapsed` floats. Use RESEARCH Pattern 1 and DR-2/DR-3. Contract-test `STEP` like `test_loop_tuning_contract.gd`. |
| `simulation/clock/sim_rng.gd` (splitmix mixer, per-stream RNG) | utility | transform | No seeded randomness exists anywhere. Use the RESEARCH "Seed mixing" snippet (signed constants; a hex literal is a parse error). Pin the first three PCG32 outputs for seed 12345 in a contract test. |
| `tools/replay/sim_recorder.gd` (canonical event log + sha256) | utility | event-driven | No recorder exists. Connect to every `SimEvents` signal first in `RunContext._init`; iterate `SimSignals.ALL`-style names to avoid drift, integers only, `roundi(x * 100.0)` for positions. |
| `simulation/night/target_query.gd` / enemy steering (`EnemyMover`) | service | batch | Nearest-spot loop in `building_system.gd` lines 99-111 is the only spatial query; reuse its shape (strict `<`, id order tie-break), not a full analog. |
| `presentation/debug/enemy_path_gizmo.gd` (ImmediateMesh lines) | component | event-driven | No 3D debug drawing exists; `presentation/vfx/xray_silhouette.gd` is only a loose node-helper precedent. Visible only while the overlay is visible. |
| Golden digest files `tests/golden/*.json` | test data | n/a | No golden-file test exists; `tests/fixtures/*.tres` (e.g. `fixture_map_tie.tres`) is the closest fixture-loading precedent. |

## Metadata

**Analog search scope:** `simulation/`, `presentation/`, `ui/`, `data/`, `tests/unit`, `tests/e2e`, `tests/support`, `tools/`, `.github/workflows/`
**Files read this session:** building_tier_def, map_config, run_context, sim_events, tower.tres, run_manager, building_system, building_instance, map_root, building_views, coin_drip_vfx (lines 1-90), king_def, loop_tuning (+.tres), debug_overlay (1-120), hud (1-80), shot_scenarios (1-70), screenshot.sh, test.sh, _common.sh, hold_pacing_sandbox (1-50), sim_signals, e2e_support (1-90), test_run_manager (selected), test_loop_tuning_contract (1-40), test_dawn_income (1-40), ci.yml
**Not opened (open before relying on them):** `simulation/economy/economy.gd`, `ui/hud/dawn_payout_vfx.gd`, `presentation/king/king.gd`, `tools/screenshot/shot_runner.gd`, `ui/overlay/debug_overlay_model.gd` (it is not in the tracked list under `ui/overlay/`; confirm its location with `git ls-files | grep overlay_model` before citing)
**Pattern extraction date:** 2026-10-03
