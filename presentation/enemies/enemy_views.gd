class_name EnemyViews
extends Node3D
## Every live enemy drawn as one instance of its archetype's batch (PLAT-01): one MultiMesh per
## archetype, so hundreds of enemies cost a handful of draw calls and no node per enemy. Each frame
## every enemy sits at the interpolation of its previous and current simulation positions by the
## clock's alpha, so the 30 Hz simulation looks smooth at any frame rate. The types differ in
## colour and silhouette (the skirmisher is violet, taller and narrower than the grunt), a hit
## flashes the body through the instance's custom data, a hurt enemy shows a billboard bar from a
## bar batch and a death leaves a small puff from a puff batch. The per-enemy fill (the ground
## point, the flash and the bar of every drawn enemy) runs in native/src/native_enemy_views.cpp
## (NativeEnemyViews, plan 04-26: a line-by-line port of the GDScript loop pinned by
## tests/unit/test_enemy_fill_pins.gd); this node keeps the batches and the event handlers and
## uploads what the native fill wrote. Purely visual: it reads the simulation and the event bus and
## never writes either (D-13).

## Cap on enemies drawn in total across the archetype batches (it was 256 puppets). A spawn past
## it is not drawn; the simulation still has the enemy and keeps stepping it.
const MAX_VIEWS: int = 512
const PUPPET_HEIGHT: float = 1.6
const RANGED_ID: StringName = &"ranged"
const GRUNT_ID: StringName = &"grunt"
const GRUNT_COLOR := Color(0.75, 0.18, 0.15)
const SKIRMISHER_COLOR := Color(0.55, 0.3, 0.85)
const FALLBACK_COLOR := Color(0.6, 0.25, 0.65)
## The skirmisher is taller than the grunt and slimmer by this factor of its collision radius.
const SKIRMISHER_HEIGHT: float = 2.0
const SKIRMISHER_RADIUS_FACTOR: float = 0.7
const FALLBACK_RADIUS: float = 0.5
const EMISSION_ENERGY: float = 0.35
const FLASH_ENERGY: float = 3.0
const FLASH_SECONDS: float = 0.15
const BAR_WIDTH: float = 0.9
const BAR_CLEARANCE: float = 0.5
## How long a death puff stands, in real seconds; DeathPuffBatch.MAX_PUFFS caps how many at once.
const PUFF_SECONDS: float = 0.6
const PUFF_HEIGHT: float = 0.8
## A low-poly capsule: 8 sides and 2 rings are 144 triangles (RESEARCH F2).
const CAPSULE_SIDES: int = 8
const CAPSULE_RINGS: int = 2
## The culling box of every batch reaches this high above the ground.
const BOUNDS_HEIGHT: float = 8.0
const KIND_GRUNT: int = 0
const KIND_SKIRMISHER: int = 1
const KIND_FALLBACK: int = 2
## The bar batch's index in NativeEnemyViews (the archetype batches are 0 to 2).
const BAR_BATCH: int = 3
const CROWD_SHADER: Shader = preload("res://presentation/crowd/crowd_instance.gdshader")

var _ctx: RunContext
## The millisecond clock the flash and the puffs read: the engine's by default, replaceable only
## through set_clock (the test seam that lets the fill be pinned deterministically).
var _clock_ms: Callable = Callable(Time, &"get_ticks_msec")
var _batches: Array[CrowdBatch] = []
var _lifts: PackedFloat32Array = PackedFloat32Array()
## The per-enemy state (archetype, max health, hit points, last hit) and the per-frame fill, in C++.
var _native: NativeEnemyViews
var _bars: HealthBarBatch
var _puffs: DeathPuffBatch


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_build_batches(ctx.map)
	_native = NativeEnemyViews.new()
	_native.configure(MAX_VIEWS, _lifts, BAR_CLEARANCE, FLASH_SECONDS)
	for index: int in range(_batches.size()):
		_hand_over(index, _batches[index])
	_hand_over(BAR_BATCH, _bars)
	ctx.events.enemy_spawned.connect(_on_enemy_spawned)
	ctx.events.enemy_damaged.connect(_on_enemy_damaged)
	ctx.events.enemy_died.connect(_on_enemy_died)


## The test seam for the millisecond clock the flash and the puffs read (the frame sample, the
## hit time, the puff birth and the puff refresh). Production keeps the engine's clock; an invalid
## Callable is ignored.
func set_clock(clock_ms: Callable) -> void:
	if clock_ms.is_valid():
		_clock_ms = clock_ms


## Enemies drawn this frame, across all archetypes.
func view_count() -> int:
	return _native.drawn_count() if _native != null else 0


## True when enemy `enemy_id` is drawn this frame.
func has_view(enemy_id: int) -> bool:
	return _native != null and _native.has_view(enemy_id)


## The ground point (y = 0) where enemy `enemy_id` is drawn this frame; the zero vector when it is
## not drawn.
func puppet_position(enemy_id: int) -> Vector3:
	return _native.puppet_position(enemy_id) if _native != null else Vector3.ZERO


## The flash of a drawn enemy: 1.0 at its last hit, falling linearly to 0.0 over FLASH_SECONDS of
## real time; 0.0 when it was not hit lately or is not drawn.
func flash_of(enemy_id: int) -> float:
	return _native.flash_of(enemy_id) if _native != null else 0.0


## The body colour of an enemy type: grunt red, skirmisher violet, anything else the fallback.
func archetype_color_of(def_id: StringName) -> Color:
	if def_id == GRUNT_ID:
		return GRUNT_COLOR
	if def_id == RANGED_ID:
		return SKIRMISHER_COLOR
	return FALLBACK_COLOR


## Hurt-only bars drawn this frame.
func bar_count() -> int:
	return _bars.count() if _bars != null else 0


## The fill ratio (hp / max health) of a drawn, hurt enemy's bar; -1.0 when it has none.
func bar_ratio_of(enemy_id: int) -> float:
	if not has_view(enemy_id):
		return -1.0
	var hp: int = _native.hp_of(enemy_id)
	var max_hp: int = _native.max_hp_of(enemy_id)
	if hp < 0 or not HealthBar3D.should_show(hp, max_hp):
		return -1.0
	return float(hp) / float(max_hp)


## Death puffs still standing. Test hook, read-only.
func puff_count() -> int:
	return _puffs.active_count() if _puffs != null else 0


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	var frame_ms: int = _clock_ms.call()
	var night_running: bool = _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
	var blend: float = _ctx.alpha() if night_running else 1.0
	var enemies: EnemySystem = _ctx.night.get_enemies()
	var view: CrowdReadView = enemies.read_view()
	_native.fill(frame_ms, blend, view.ids, view.previous, view.current)
	for index: int in range(_batches.size()):
		_batches[index].commit_buffer(_native.mirror(index), _native.count(index))
	_bars.commit_buffer(_native.mirror(BAR_BATCH), _native.count(BAR_BATCH))
	var puff_ms: int = _clock_ms.call()
	_puffs.refresh(float(puff_ms) / 1000.0)
	if enemies.count() == 0 and _native.known_count() > 0:
		_native.clear()


func _on_enemy_spawned(enemy_id: int, def_id: StringName, _pos: Vector2) -> void:
	var def: EnemyDef = _ctx.map.find_enemy(def_id)
	_native.on_spawned(enemy_id, _kind_for(def_id), def.max_health if def != null else 0)


## A hit flashes the body and keeps the hit points for the bar.
func _on_enemy_damaged(enemy_id: int, _amount: int, hp: int) -> void:
	var hit_ms: int = _clock_ms.call()
	_native.on_damaged(enemy_id, hp, hit_ms)


## The enemy leaves its batch (its state is dropped) and a puff stands where it was last drawn, or
## at the event position when it never was.
func _on_enemy_died(enemy_id: int, def_id: StringName, pos: Vector2, _killer: StringName) -> void:
	var ground: Vector3 = Vector3(pos.x, 0.0, pos.y)
	if _native.has_view(enemy_id):
		ground = _native.puppet_position(enemy_id)
	_native.forget(enemy_id)
	var now_ms: int = _clock_ms.call()
	var now_s: float = float(now_ms) / 1000.0
	_puffs.spawn(Vector3(ground.x, PUFF_HEIGHT, ground.z), now_s, archetype_color_of(def_id))


func _kind_for(def_id: StringName) -> int:
	if def_id == GRUNT_ID:
		return KIND_GRUNT
	if def_id == RANGED_ID:
		return KIND_SKIRMISHER
	return KIND_FALLBACK


## Gives the native fill batch `index`'s mirror and layout; it refuses a mirror of the wrong shape.
func _hand_over(index: int, batch: CrowdBatch) -> void:
	if not _native.set_mirror(index, batch.mirror(), batch.layout()):
		push_error("EnemyViews: the native enemy fill refused the mirror of batch %d" % index)


## One batch per archetype, sized as the puppets were: the grunt at its def radius, the skirmisher
## taller and narrower, any other type the fallback colour.
func _build_batches(map: MapConfig) -> void:
	var grunt: EnemyDef = map.find_enemy(GRUNT_ID)
	var ranged: EnemyDef = map.find_enemy(RANGED_ID)
	var grunt_radius: float = grunt.radius if grunt != null else FALLBACK_RADIUS
	var ranged_radius: float = ranged.radius if ranged != null else FALLBACK_RADIUS
	var half: float = map.ground_half_extent
	var bounds: AABB = AABB(
		Vector3(map.castle_position.x - half, 0.0, map.castle_position.z - half),
		Vector3(half * 2.0, BOUNDS_HEIGHT, half * 2.0)
	)
	var specs: Array[Dictionary] = [
		{"name": "Grunts", "radius": grunt_radius, "height": PUPPET_HEIGHT, "id": GRUNT_ID},
		{
			"name": "Skirmishers",
			"radius": ranged_radius * SKIRMISHER_RADIUS_FACTOR,
			"height": SKIRMISHER_HEIGHT,
			"id": RANGED_ID,
		},
		{"name": "Others", "radius": FALLBACK_RADIUS, "height": PUPPET_HEIGHT, "id": &""},
	]
	for spec: Dictionary in specs:
		var height: float = spec["height"]
		var batch: CrowdBatch = _make_batch(spec["radius"], height, archetype_color_of(spec["id"]))
		batch.name = spec["name"]
		batch.set_bounds(bounds)
		add_child(batch)
		_batches.append(batch)
		_lifts.append(height * 0.5)
	_build_overlays(bounds)


func _make_batch(radius: float, height: float, color: Color) -> CrowdBatch:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = CAPSULE_SIDES
	mesh.rings = CAPSULE_RINGS
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CROWD_SHADER
	material.set_shader_parameter(&"albedo", color)
	material.set_shader_parameter(&"calm_energy", EMISSION_ENERGY)
	material.set_shader_parameter(&"flash_energy", FLASH_ENERGY)
	var batch: CrowdBatch = CrowdBatch.new()
	# Instance colours stay on although every enemy passes white: the Compatibility renderer reads
	# a missing vertex colour as black, which would paint every body black through the tint.
	batch.setup(mesh, material, MAX_VIEWS, true)
	return batch


## The shared bar batch and the puff ring, built once beside the archetype batches.
func _build_overlays(bounds: AABB) -> void:
	_bars = HealthBarBatch.new()
	_bars.setup_bars(BAR_WIDTH, MAX_VIEWS)
	_bars.name = "Bars"
	_bars.set_bounds(bounds)
	add_child(_bars)
	_puffs = DeathPuffBatch.new()
	_puffs.setup_puffs()
	_puffs.name = "Puffs"
	_puffs.set_bounds(bounds)
	add_child(_puffs)
