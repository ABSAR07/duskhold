class_name EnemyViews
extends Node3D
## Every live enemy drawn as one instance of its archetype's batch (PLAT-01): one MultiMesh per
## archetype, so hundreds of enemies cost a handful of draw calls and no node per enemy. Each frame
## every enemy sits at the interpolation of its previous and current simulation positions by the
## clock's alpha, so the 30 Hz simulation looks smooth at any frame rate. The types differ in
## colour and silhouette (the skirmisher is violet, taller and narrower than the grunt), a hit
## flashes the body through the instance's custom data, and a death leaves a small puff. Purely
## visual: it reads the simulation and the event bus and never writes either (D-13).

## Cap on enemies drawn in total across the archetype batches (it was 256 puppets). A spawn past
## it is not drawn; the simulation still has the enemy and keeps stepping it.
const MAX_VIEWS: int = 512
## Visual cap on death puffs standing at once; each frees itself after PUFF_SECONDS.
const MAX_PUFFS: int = 64
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
const PUFF_SECONDS: float = 0.6
const PUFF_PARTICLES: int = 12
const PUFF_HEIGHT: float = 0.8
## A low-poly capsule: 8 sides and 2 rings are 144 triangles (RESEARCH F2).
const CAPSULE_SIDES: int = 8
const CAPSULE_RINGS: int = 2
## The culling box of every batch reaches this high above the ground.
const BOUNDS_HEIGHT: float = 8.0
const KIND_GRUNT: int = 0
const KIND_SKIRMISHER: int = 1
const KIND_FALLBACK: int = 2
const CROWD_SHADER: Shader = preload("res://presentation/crowd/crowd_instance.gdshader")

var _ctx: RunContext
var _batches: Array[CrowdBatch] = []
var _lifts: PackedFloat32Array = PackedFloat32Array()
## Enemy id -> archetype index, set on enemy_spawned and dropped on enemy_died.
var _kind_of: Dictionary = {}
## Enemy id -> real milliseconds of its last hit, for the flash.
var _hit_ms: Dictionary = {}
var _frame_ms: int = 0
## The enemies drawn this frame, ascending by id: the CPU mirror the test hooks read.
var _drawn_ids: PackedInt32Array = PackedInt32Array()
var _drawn_origins: PackedVector3Array = PackedVector3Array()
var _drawn: int = 0
var _puff_mesh: SphereMesh


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_drawn_ids.resize(MAX_VIEWS)
	_drawn_origins.resize(MAX_VIEWS)
	_build_batches(ctx.map)
	ctx.events.enemy_spawned.connect(_on_enemy_spawned)
	ctx.events.enemy_damaged.connect(_on_enemy_damaged)
	ctx.events.enemy_died.connect(_on_enemy_died)


## Enemies drawn this frame, across all archetypes.
func view_count() -> int:
	return _drawn


## True when enemy `enemy_id` is drawn this frame.
func has_view(enemy_id: int) -> bool:
	return _find(enemy_id) >= 0


## The ground point (y = 0) where enemy `enemy_id` is drawn this frame; the zero vector when it is
## not drawn.
func puppet_position(enemy_id: int) -> Vector3:
	var slot: int = _find(enemy_id)
	return _drawn_origins[slot] if slot >= 0 else Vector3.ZERO


## The flash of a drawn enemy: 1.0 at its last hit, falling linearly to 0.0 over FLASH_SECONDS of
## real time; 0.0 when it was not hit lately or is not drawn.
func flash_of(enemy_id: int) -> float:
	if not has_view(enemy_id):
		return 0.0
	return _flash_amount(enemy_id)


## The body colour of an enemy type: grunt red, skirmisher violet, anything else the fallback.
func archetype_color_of(def_id: StringName) -> Color:
	if def_id == GRUNT_ID:
		return GRUNT_COLOR
	if def_id == RANGED_ID:
		return SKIRMISHER_COLOR
	return FALLBACK_COLOR


## Death puffs still showing. Test hook, read-only.
func puff_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if child.has_meta(&"puff") and not child.is_queued_for_deletion():
			count += 1
	return count


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	_frame_ms = Time.get_ticks_msec()
	var night_running: bool = _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
	var blend: float = _ctx.alpha() if night_running else 1.0
	var enemies: EnemySystem = _ctx.night.get_enemies()
	for batch: CrowdBatch in _batches:
		batch.begin()
	_drawn = 0
	for enemy_id: int in enemies.ids():
		if _drawn >= MAX_VIEWS:
			break
		var kind: int = _kind_of.get(enemy_id, -1)
		if kind < 0:
			continue
		var ground: Vector2 = enemies.previous_position_of(enemy_id).lerp(
			enemies.position_of(enemy_id), blend
		)
		var origin: Vector3 = Vector3(ground.x, _lifts[kind], ground.y)
		var flash: Color = Color(_flash_amount(enemy_id), 0.0, 0.0, 0.0)
		if not _batches[kind].add(origin, flash):
			continue
		_drawn_ids[_drawn] = enemy_id
		_drawn_origins[_drawn] = Vector3(ground.x, 0.0, ground.y)
		_drawn += 1
	for batch: CrowdBatch in _batches:
		batch.commit()
	if enemies.count() == 0 and not _kind_of.is_empty():
		_kind_of.clear()
		_hit_ms.clear()


func _on_enemy_spawned(enemy_id: int, def_id: StringName, _pos: Vector2) -> void:
	_kind_of[enemy_id] = _kind_for(def_id)


func _on_enemy_damaged(enemy_id: int, _amount: int, _hp: int) -> void:
	if _kind_of.has(enemy_id):
		_hit_ms[enemy_id] = Time.get_ticks_msec()


func _on_enemy_died(enemy_id: int, def_id: StringName, pos: Vector2, _killer: StringName) -> void:
	_kind_of.erase(enemy_id)
	_hit_ms.erase(enemy_id)
	_spawn_puff(pos, archetype_color_of(def_id))


## The flash amount from the last hit, measured against the clock sampled at the start of the
## latest frame so a hit landing after that frame reads exactly 1.0 until the next one.
func _flash_amount(enemy_id: int) -> float:
	var hit: int = _hit_ms.get(enemy_id, -1)
	if hit < 0:
		return 0.0
	var elapsed_s: float = float(maxi(_frame_ms - hit, 0)) / 1000.0
	var amount: float = 1.0 - elapsed_s / FLASH_SECONDS
	if amount <= 0.0:
		_hit_ms.erase(enemy_id)
		return 0.0
	return amount


## Slot of `enemy_id` among the drawn enemies (ascending ids), or -1.
func _find(enemy_id: int) -> int:
	var low: int = 0
	var high: int = _drawn - 1
	while low <= high:
		var middle: int = (low + high) >> 1
		var found: int = _drawn_ids[middle]
		if found == enemy_id:
			return middle
		if found < enemy_id:
			low = middle + 1
		else:
			high = middle - 1
	return -1


func _kind_for(def_id: StringName) -> int:
	if def_id == GRUNT_ID:
		return KIND_GRUNT
	if def_id == RANGED_ID:
		return KIND_SKIRMISHER
	return KIND_FALLBACK


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
	batch.setup(mesh, material, MAX_VIEWS, false)
	return batch


## A burst of small spheres where the enemy fell; frees itself after PUFF_SECONDS.
func _spawn_puff(pos: Vector2, color: Color) -> void:
	if puff_count() >= MAX_PUFFS:
		return
	var puff: CPUParticles3D = CPUParticles3D.new()
	puff.name = "DeathPuff"
	puff.set_meta(&"puff", true)
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.amount = PUFF_PARTICLES
	puff.lifetime = PUFF_SECONDS * 0.75
	puff.direction = Vector3.UP
	puff.spread = 70.0
	puff.initial_velocity_min = 1.2
	puff.initial_velocity_max = 2.4
	puff.gravity = Vector3(0.0, -4.0, 0.0)
	puff.mesh = _puff_mesh_for(color)
	add_child(puff)
	puff.position = Vector3(pos.x, PUFF_HEIGHT, pos.y)
	puff.emitting = true
	get_tree().create_timer(PUFF_SECONDS).timeout.connect(puff.queue_free)


func _puff_mesh_for(color: Color) -> SphereMesh:
	if _puff_mesh == null:
		_puff_mesh = SphereMesh.new()
		_puff_mesh.radius = 0.1
		_puff_mesh.height = 0.2
	var mesh: SphereMesh = _puff_mesh.duplicate() as SphereMesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	return mesh
