class_name ProjectileVfx
extends Node3D
## Makes every attack the simulation decides visible (KING-03, D-13). A tower, castle, skirmisher
## or archer shot flies a thin emissive arrow from the attacker to the target's current position for
## exactly SimClock.flight_ticks of simulation time, arcing on the way. Every arrow in the air is
## one instance of a single batch (PLAT-01): the flights live in a ring of MAX_PROJECTILES slots
## held in parallel arrays, and each frame the live ones are written into the batch in slot order
## and uploaded once. The king's passive strike has no flight, so it shows a short flat slash at
## the king pointing at his target instead (a node, capped at MAX_SLASHES).
## Purely visual: the simulation has already decided the hit by the target's id (RESEARCH Pattern
## 2), so an arrow cannot miss, cannot hit anything else and, when its target is gone, finishes at
## the target's last known position. Arrows are capped at MAX_PROJECTILES (T-02-10, T-04-03) and a
## shot past the cap is simply not drawn.

const MAX_PROJECTILES: int = 512
## Slashes live a fraction of a second; this only bounds a pathological burst.
const MAX_SLASHES: int = 8
## Peak height of an arrow's arc per metre of distance, and the highest peak any arrow reaches.
const ARC_PER_METRE: float = 0.12
const MAX_ARC_HEIGHT: float = 2.5
const TOWER_COLOR := Color(1.0, 0.85, 0.25)
const SKIRMISHER_COLOR := Color(0.6, 0.3, 0.9)
## Friendly archers shoot a pale blue arrow, readable against both the gold tower arrows and the
## violet skirmisher arrows.
const UNIT_ARROW_COLOR := Color(0.55, 0.85, 1.0)
const SLASH_COLOR := Color(1.0, 0.95, 0.8)
const EMISSION_ENERGY: float = 2.0
const ARROW_SIZE := Vector3(0.15, 0.15, 1.0)
const SLASH_SIZE := Vector3(0.3, 0.05, 1.8)
const SLASH_SECONDS: float = 0.15
## Heights above the ground an arrow leaves from (a tower's top, the castle keep's top, a unit's
## chest) and arrives at.
const TOWER_LAUNCH_HEIGHT: float = 3.2
## The top of the castle model: the keep with its turret on it (BuildingViews).
const CASTLE_LAUNCH_HEIGHT: float = BuildingViews.KEEP_SIZE.y + BuildingViews.TURRET_HEIGHT
const UNIT_HEIGHT: float = 1.2
const BUILDING_TARGET_HEIGHT: float = 1.5
## An arrow at a wall segment lands at this height above the segment's middle.
const WALL_TARGET_HEIGHT: float = 0.8
const SLASH_HEIGHT: float = 1.1
## A position that could not be resolved (an attacker that is already gone).
const NO_POSITION := Vector3(INF, INF, INF)
## The arrow's heading is the slope of its path between these two progress values either side.
const HEADING_STEP: float = 0.02
## The culling box of the arrow batch reaches this high above the ground.
const BOUNDS_HEIGHT: float = 8.0
const CROWD_SHADER: Shader = preload("res://presentation/crowd/crowd_instance.gdshader")

var _ctx: RunContext
var _batch: CrowdBatch
var _slash_mesh: BoxMesh
## The ring of flights, parallel arrays indexed by slot. A slot is free while `_active` is 0.
var _origins: PackedVector3Array = PackedVector3Array()
var _last_targets: PackedVector3Array = PackedVector3Array()
var _elapsed: PackedFloat32Array = PackedFloat32Array()
var _durations: PackedFloat32Array = PackedFloat32Array()
var _target_kinds: Array[StringName] = []
var _target_ids: PackedInt32Array = PackedInt32Array()
var _colors: PackedColorArray = PackedColorArray()
var _active: PackedByteArray = PackedByteArray()
var _live: int = 0
var _cursor: int = 0
## Arrows written into the batch by the latest frame; an idle frame after an idle frame uploads
## nothing.
var _drawn: int = 0
## The launch point of each arrow drawn by the latest frame, in drawn order (test hook mirror).
var _drawn_launches: PackedVector3Array = PackedVector3Array()


## Seconds a projectile of `flight_ticks` simulation ticks stays in the air.
static func flight_seconds(flight_ticks: int) -> float:
	return SimClock.seconds(flight_ticks)


## Height above the straight line at progress `t` (0 at launch, 1 at landing) of a shot over
## `distance` metres: a parabola that is 0 at both ends and peaks halfway at distance *
## ARC_PER_METRE, never above MAX_ARC_HEIGHT. Progress outside 0 to 1 is on the ground.
static func arc_height(t: float, distance: float) -> float:
	if t <= 0.0 or t >= 1.0:
		return 0.0
	var peak: float = minf(maxf(distance, 0.0) * ARC_PER_METRE, MAX_ARC_HEIGHT)
	return 4.0 * t * (1.0 - t) * peak


## Where an arrow flying from `origin` to `target` is at progress `t` (clamped to 0 to 1), turned
## along its path: the origin on the straight line plus the arc, the basis z axis along the
## direction of travel (the arc's slope included), y as upright as that allows and x across. The
## identity basis when origin and target coincide.
static func arrow_transform(origin: Vector3, target: Vector3, t: float) -> Transform3D:
	var progress: float = clampf(t, 0.0, 1.0)
	var distance: float = origin.distance_to(target)
	var here: Vector3 = _path_point(origin, target, progress, distance)
	var behind: Vector3 = _path_point(origin, target, maxf(progress - HEADING_STEP, 0.0), distance)
	var ahead: Vector3 = _path_point(origin, target, minf(progress + HEADING_STEP, 1.0), distance)
	var heading: Vector3 = ahead - behind
	if heading.length() < 0.0001:
		heading = target - origin
	if heading.length() < 0.0001:
		return Transform3D(Basis.IDENTITY, here)
	var forward: Vector3 = heading.normalized()
	var across: Vector3 = Vector3.UP.cross(forward)
	across = across.normalized() if across.length() > 0.001 else Vector3.RIGHT
	var upright: Vector3 = forward.cross(across)
	return Transform3D(Basis(across, upright, forward), here)


static func _path_point(origin: Vector3, target: Vector3, t: float, distance: float) -> Vector3:
	return origin.lerp(target, t) + Vector3.UP * arc_height(t, distance)


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_allocate_ring()
	_build_batch(ctx.map)
	_slash_mesh = _make_box(SLASH_SIZE, SLASH_COLOR)
	ctx.events.attack_fired.connect(_on_attack_fired)


## Arrows in the air. Test hook, read-only.
func live_count() -> int:
	return _live


## Arrows drawn by the latest frame. Test hook, read-only.
func arrow_count() -> int:
	return _batch.count() if _batch != null else 0


## The colour of arrow `index` of the latest frame, from the batch mirror; white past the last.
func arrow_color_at(index: int) -> Color:
	return _batch.color_of(index) if _batch != null else Color.WHITE


## Where arrow `index` of the latest frame left from, launch height included; the zero vector past
## the last. Test hook, read-only.
func arrow_launch_at(index: int) -> Vector3:
	if index < 0 or index >= _drawn:
		return Vector3.ZERO
	return _drawn_launches[index]


## Slashes showing. Test hook, read-only.
func slash_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if child.has_meta(&"slash") and not child.is_queued_for_deletion():
			count += 1
	return count


func _process(delta: float) -> void:
	if _ctx == null:
		return
	if _live == 0 and _drawn == 0:
		return
	_batch.begin()
	_drawn = 0
	for slot: int in range(MAX_PROJECTILES):
		if _active[slot] == 0:
			continue
		_elapsed[slot] += delta
		_last_targets[slot] = _target_position(
			_target_kinds[slot], _target_ids[slot], _last_targets[slot]
		)
		var t: float = clampf(_elapsed[slot] / _durations[slot], 0.0, 1.0)
		var xform: Transform3D = arrow_transform(_origins[slot], _last_targets[slot], t)
		if _batch.add_transform(xform, Color(0.0, 0.0, 0.0, 0.0), _colors[slot]):
			_drawn_launches[_drawn] = _origins[slot]
			_drawn += 1
		if t >= 1.0:
			_active[slot] = 0
			_live -= 1
	_batch.commit()


func _on_attack_fired(
	attacker_kind: StringName,
	attacker_id: int,
	target_kind: StringName,
	target_id: int,
	flight_ticks: int
) -> void:
	if flight_ticks <= 0:
		if attacker_kind == PendingHits.KIND_KING:
			_spawn_slash(target_kind, target_id)
		return
	if not _draws_arrows(attacker_kind):
		return
	if _live >= MAX_PROJECTILES:
		return
	var origin: Vector3 = _attacker_position(attacker_kind, attacker_id)
	if not origin.is_finite():
		return
	var slot: int = _free_slot()
	if slot < 0:
		return
	_origins[slot] = origin
	_last_targets[slot] = _target_position(target_kind, target_id, origin)
	_elapsed[slot] = 0.0
	_durations[slot] = maxf(flight_seconds(flight_ticks), SimClock.STEP)
	_target_kinds[slot] = target_kind
	_target_ids[slot] = target_id
	_colors[slot] = _color_for(attacker_kind)
	_active[slot] = 1
	_live += 1


## Towers, the castle, enemies and friendly archers shoot arrows; the king and melee units strike
## without a flight (a unit hit with no flight draws nothing).
func _draws_arrows(attacker_kind: StringName) -> bool:
	return (
		attacker_kind == PendingHits.KIND_BUILDING
		or attacker_kind == PendingHits.KIND_CASTLE
		or attacker_kind == PendingHits.KIND_ENEMY
		or attacker_kind == PendingHits.KIND_UNIT
	)


func _color_for(attacker_kind: StringName) -> Color:
	if attacker_kind == PendingHits.KIND_ENEMY:
		return SKIRMISHER_COLOR
	if attacker_kind == PendingHits.KIND_UNIT:
		return UNIT_ARROW_COLOR
	return TOWER_COLOR


## The next free slot at or after the cursor (the ring), or -1 when every slot is taken.
func _free_slot() -> int:
	for step: int in range(MAX_PROJECTILES):
		var slot: int = (_cursor + step) % MAX_PROJECTILES
		if _active[slot] == 0:
			_cursor = (slot + 1) % MAX_PROJECTILES
			return slot
	return -1


func _allocate_ring() -> void:
	_origins.resize(MAX_PROJECTILES)
	_last_targets.resize(MAX_PROJECTILES)
	_elapsed.resize(MAX_PROJECTILES)
	_durations.resize(MAX_PROJECTILES)
	_target_kinds.resize(MAX_PROJECTILES)
	_target_ids.resize(MAX_PROJECTILES)
	_colors.resize(MAX_PROJECTILES)
	_active.resize(MAX_PROJECTILES)
	_drawn_launches.resize(MAX_PROJECTILES)


## The one arrow batch: a thin box per arrow, tinted per instance through the crowd shader, white
## albedo, the same emission the arrows had as nodes, no shadow.
func _build_batch(map: MapConfig) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = ARROW_SIZE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CROWD_SHADER
	material.set_shader_parameter(&"albedo", Color.WHITE)
	material.set_shader_parameter(&"calm_energy", EMISSION_ENERGY)
	material.set_shader_parameter(&"flash_energy", EMISSION_ENERGY)
	_batch = CrowdBatch.new()
	_batch.setup(mesh, material, MAX_PROJECTILES, true)
	_batch.name = "Arrows"
	_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var half: float = map.ground_half_extent
	_batch.set_bounds(
		AABB(
			Vector3(map.castle_position.x - half, 0.0, map.castle_position.z - half),
			Vector3(half * 2.0, BOUNDS_HEIGHT, half * 2.0)
		)
	)
	add_child(_batch)


## A flat bar from the king toward his target that shrinks away in SLASH_SECONDS.
func _spawn_slash(target_kind: StringName, target_id: int) -> void:
	if slash_count() >= MAX_SLASHES:
		return
	var king_ground: Vector2 = _ctx.king.get_position()
	var start: Vector3 = Vector3(king_ground.x, SLASH_HEIGHT, king_ground.y)
	var aim: Vector3 = _target_position(target_kind, target_id, NO_POSITION)
	var slash: MeshInstance3D = MeshInstance3D.new()
	slash.name = "Slash"
	slash.mesh = _slash_mesh
	slash.set_meta(&"slash", true)
	slash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(slash)
	slash.global_position = start
	var flat: Vector3 = Vector3(aim.x - start.x, 0.0, aim.z - start.z)
	if aim.is_finite() and flat.length() > 0.01:
		slash.look_at(start + flat, Vector3.UP)
		slash.global_position = start + flat.normalized() * SLASH_SIZE.z * 0.5
	var tween: Tween = slash.create_tween()
	tween.tween_property(slash, "scale", Vector3(1.0, 1.0, 0.2), SLASH_SECONDS)
	tween.tween_callback(slash.queue_free)


## Where the attacker stands, launch height included; NO_POSITION when it is gone.
func _attacker_position(kind: StringName, id: int) -> Vector3:
	if kind == PendingHits.KIND_BUILDING:
		var spot_id: StringName = _ctx.buildings.spot_at_index(id)
		if spot_id == &"":
			return NO_POSITION
		return _ctx.buildings.get_spot(spot_id).position + Vector3.UP * TOWER_LAUNCH_HEIGHT
	if kind == PendingHits.KIND_CASTLE:
		var castle_ground: Vector2 = _ctx.castle.get_position()
		return Vector3(castle_ground.x, CASTLE_LAUNCH_HEIGHT, castle_ground.y)
	if kind == PendingHits.KIND_UNIT:
		return _unit_position(id)
	var enemies: EnemySystem = _ctx.night.get_enemies()
	if not enemies.is_alive(id):
		return NO_POSITION
	var ground: Vector2 = enemies.position_of(id)
	return Vector3(ground.x, UNIT_HEIGHT, ground.y)


## Where friendly unit `id` stands, chest height; NO_POSITION when it is gone.
func _unit_position(id: int) -> Vector3:
	var units: UnitSystem = _ctx.squads.get_units()
	if not units.is_alive(id):
		return NO_POSITION
	var ground: Vector2 = units.position_of(id)
	return Vector3(ground.x, UNIT_HEIGHT, ground.y)


## Where the target stands now, or `fallback` when it cannot be found (already dead or fallen).
func _target_position(kind: StringName, id: int, fallback: Vector3) -> Vector3:
	var found: Vector3 = fallback
	if kind == PendingHits.KIND_ENEMY:
		var enemies: EnemySystem = _ctx.night.get_enemies()
		if enemies.is_alive(id):
			var ground: Vector2 = enemies.position_of(id)
			found = Vector3(ground.x, UNIT_HEIGHT, ground.y)
	elif kind == PendingHits.KIND_UNIT:
		var unit_found: Vector3 = _unit_position(id)
		if unit_found.is_finite():
			found = unit_found
	elif kind == PendingHits.KIND_KING:
		var king_ground: Vector2 = _ctx.king.get_position()
		found = Vector3(king_ground.x, UNIT_HEIGHT, king_ground.y)
	elif kind == PendingHits.KIND_BUILDING:
		var spot_id: StringName = _ctx.buildings.spot_at_index(id)
		if spot_id != &"":
			found = _ctx.buildings.get_spot(spot_id).position + Vector3.UP * BUILDING_TARGET_HEIGHT
	elif kind == PendingHits.KIND_CASTLE:
		var castle_ground: Vector2 = _ctx.castle.get_position()
		found = Vector3(castle_ground.x, BUILDING_TARGET_HEIGHT, castle_ground.y)
	elif kind == PendingHits.KIND_WALL and id >= 0 and id < _ctx.walls.segment_count():
		var middle: Vector2 = (_ctx.walls.segment_start(id) + _ctx.walls.segment_end(id)) * 0.5
		found = Vector3(middle.x, WALL_TARGET_HEIGHT, middle.y)
	return found


func _make_box(size: Vector3, color: Color) -> BoxMesh:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = EMISSION_ENERGY
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	return mesh
