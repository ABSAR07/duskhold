class_name ProjectileVfx
extends Node3D
## Makes every attack the simulation decides visible (KING-03, D-13). A tower or skirmisher shot
## spawns a thin emissive arrow that flies from the attacker to the target's current position for
## exactly SimClock.flight_ticks of simulation time, arcing on the way. The king's passive strike
## has no flight, so it shows a short flat slash at the king pointing at his target instead.
## Purely visual: the simulation has already decided the hit by the target's id (RESEARCH Pattern
## 2), so an arrow cannot miss, cannot hit anything else and, when its target is gone, finishes at
## the target's last known position. Every arrow and slash frees itself; arrows are capped at
## MAX_PROJECTILES (T-02-10) and a shot past the cap is simply not drawn.

const MAX_PROJECTILES: int = 128
## Slashes live a fraction of a second; this only bounds a pathological burst.
const MAX_SLASHES: int = 8
## Peak height of an arrow's arc per metre of distance, and the highest peak any arrow reaches.
const ARC_PER_METRE: float = 0.12
const MAX_ARC_HEIGHT: float = 2.5
const TOWER_COLOR := Color(1.0, 0.85, 0.25)
const SKIRMISHER_COLOR := Color(0.6, 0.3, 0.9)
const SLASH_COLOR := Color(1.0, 0.95, 0.8)
const EMISSION_ENERGY: float = 2.0
const ARROW_SIZE := Vector3(0.07, 0.07, 0.8)
const SLASH_SIZE := Vector3(0.3, 0.05, 1.8)
const SLASH_SECONDS: float = 0.15
## Heights above the ground an arrow leaves from (a tower's top, a unit's chest) and arrives at.
const TOWER_LAUNCH_HEIGHT: float = 3.2
const UNIT_HEIGHT: float = 1.2
const BUILDING_TARGET_HEIGHT: float = 1.5
const SLASH_HEIGHT: float = 1.1
## A position that could not be resolved (an attacker that is already gone).
const NO_POSITION := Vector3(INF, INF, INF)

var _ctx: RunContext
var _flights: Array[Flight] = []
var _tower_mesh: BoxMesh
var _skirmisher_mesh: BoxMesh
var _slash_mesh: BoxMesh


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


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_tower_mesh = _make_box(ARROW_SIZE, TOWER_COLOR)
	_skirmisher_mesh = _make_box(ARROW_SIZE, SKIRMISHER_COLOR)
	_slash_mesh = _make_box(SLASH_SIZE, SLASH_COLOR)
	ctx.events.attack_fired.connect(_on_attack_fired)


## Arrows in the air. Test hook, read-only.
func live_count() -> int:
	return _flights.size()


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
	var index: int = _flights.size() - 1
	while index >= 0:
		var flight: Flight = _flights[index]
		if not is_instance_valid(flight.node):
			_flights.remove_at(index)
		else:
			flight.elapsed += delta
			flight.last_target = _target_position(
				flight.target_kind, flight.target_id, flight.last_target
			)
			var t: float = clampf(flight.elapsed / flight.duration, 0.0, 1.0)
			var distance: float = flight.origin.distance_to(flight.last_target)
			var along: Vector3 = flight.origin.lerp(flight.last_target, t)
			_place(flight.node, along + Vector3.UP * arc_height(t, distance))
			if t >= 1.0:
				flight.node.queue_free()
				_flights.remove_at(index)
		index -= 1


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
	if attacker_kind != PendingHits.KIND_BUILDING and attacker_kind != PendingHits.KIND_ENEMY:
		return
	if _flights.size() >= MAX_PROJECTILES:
		return
	var origin: Vector3 = _attacker_position(attacker_kind, attacker_id)
	if not origin.is_finite():
		return
	var flight: Flight = Flight.new()
	flight.origin = origin
	flight.target_kind = target_kind
	flight.target_id = target_id
	flight.last_target = _target_position(target_kind, target_id, origin)
	flight.duration = maxf(flight_seconds(flight_ticks), SimClock.STEP)
	var arrow: MeshInstance3D = MeshInstance3D.new()
	arrow.name = "Arrow"
	arrow.mesh = _tower_mesh if attacker_kind == PendingHits.KIND_BUILDING else _skirmisher_mesh
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arrow)
	arrow.global_position = origin
	_place(arrow, origin)
	flight.node = arrow
	_flights.append(flight)


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


## Moves the node to `point` and turns it along the direction it just travelled.
func _place(node: MeshInstance3D, point: Vector3) -> void:
	var heading: Vector3 = point - node.global_position
	node.global_position = point
	if heading.length() > 0.001 and absf(heading.normalized().y) < 0.99:
		node.look_at(point + heading, Vector3.UP)


## Where the attacker stands, launch height included; NO_POSITION when it is gone.
func _attacker_position(kind: StringName, id: int) -> Vector3:
	if kind == PendingHits.KIND_BUILDING:
		var spot_id: StringName = _ctx.buildings.spot_at_index(id)
		if spot_id == &"":
			return NO_POSITION
		return _ctx.buildings.get_spot(spot_id).position + Vector3.UP * TOWER_LAUNCH_HEIGHT
	var enemies: EnemySystem = _ctx.night.get_enemies()
	if not enemies.is_alive(id):
		return NO_POSITION
	var ground: Vector2 = enemies.position_of(id)
	return Vector3(ground.x, UNIT_HEIGHT, ground.y)


## Where the target stands now, or `fallback` when it cannot be found (already dead or fallen).
func _target_position(kind: StringName, id: int, fallback: Vector3) -> Vector3:
	var found: Vector3 = fallback
	if kind == PendingHits.KIND_ENEMY:
		var enemies: EnemySystem = _ctx.night.get_enemies()
		if enemies.is_alive(id):
			var ground: Vector2 = enemies.position_of(id)
			found = Vector3(ground.x, UNIT_HEIGHT, ground.y)
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


## One arrow in the air. Private to the node.
class Flight:
	extends RefCounted
	var node: MeshInstance3D
	var origin: Vector3 = Vector3.ZERO
	var last_target: Vector3 = Vector3.ZERO
	var target_kind: StringName = &""
	var target_id: int = 0
	var elapsed: float = 0.0
	var duration: float = 0.0
