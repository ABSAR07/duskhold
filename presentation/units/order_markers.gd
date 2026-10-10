class_name OrderMarkers
extends Node3D
## Pings the ground where an order lands (UI-SPEC "Move", "Attack-move", "Rally"). On squad_ordered
## a move or a rally puts a cyan ring (#8CEBFF) on the resolved point that grows from 0.3 m to 0.8 m
## across the ring over PING_SECONDS while its alpha falls from 0.9 to nothing; an attack-move does
## the same in #FF7A59 and holds a 0.3 m crossed-blade mark for the same time. Several squads given
## one order in the same frame share one ping. Hold, follow and patrol draw nothing here (patrol
## lines and queued discs are plan 03-08). Pings free themselves and are capped at MAX_PINGS, so a
## burst of orders cannot pile up nodes. Display only: it reads the simulation and writes nothing.

## Most pings alive at once; one past the cap is not drawn.
const MAX_PINGS: int = 16
const PING_SECONDS: float = 0.5
const START_RADIUS: float = 0.3
const END_RADIUS: float = 0.8
const START_ALPHA: float = 0.9
## Width of the ring band as a share of its radius.
const BAND_SHARE: float = 0.14
const RING_SEGMENTS: int = 32
## Height above the ground, so the ping is not z-fought by the terrain.
const PING_HEIGHT: float = 0.06
## The blade mark: two bars crossing, each this long and wide.
const BLADE_LENGTH: float = 0.3
const BLADE_WIDTH: float = 0.05
const MOVE_COLOR := Color(0.549, 0.9216, 1.0)
const ATTACK_COLOR := Color(1.0, 0.4784, 0.349)
const PING_META: StringName = &"order_ping"
## Most queued-order discs shown for one squad (UI-SPEC "Queued orders").
const MAX_DISCS_SHOWN: int = 6

var _ctx: RunContext
var _frame_seen: Dictionary = {}
var _frame: int = -1


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.squad_ordered.connect(_on_squad_ordered)


## Pings showing right now. Test hook, read-only.
func active_ping_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if child.has_meta(PING_META) and not child.is_queued_for_deletion():
			count += 1
	return count


## Numbered queued-order discs showing for the selected squads. Test hook, read-only.
func disc_count() -> int:
	return 0


## Patrol lines showing for the selected squads. Test hook, read-only.
func patrol_line_count() -> int:
	return 0


## The labels of the queued-order discs, selected squads in creation order. Test hook.
func disc_labels() -> PackedStringArray:
	return PackedStringArray()


## The colours of the queued-order discs in the same order. Test hook.
func disc_colors() -> Array[Color]:
	return [] as Array[Color]


## The 0.4 m discs that mark the ends of the patrol lines showing. Test hook.
func patrol_disc_count() -> int:
	return 0


## True while a freshly set patrol line is flashing. Test hook.
func patrol_flashing() -> bool:
	return false


## The corner points of the patrol line drawn for `squad_id`; empty when none shows. Test hook.
func patrol_line_points(_squad_id: StringName) -> PackedVector3Array:
	return PackedVector3Array()


func _on_squad_ordered(
	_squad_id: StringName, verb: StringName, _queued: bool, points: Array
) -> void:
	var attack: bool = verb == SquadOrder.VERB_ATTACK_MOVE
	if not (attack or verb == SquadOrder.VERB_MOVE or verb == SquadOrder.VERB_RALLY):
		return
	if points.is_empty() or not points[0] is Vector2:
		return
	var point: Vector2 = points[0]
	var now: int = Engine.get_process_frames()
	if now != _frame:
		_frame = now
		_frame_seen.clear()
	var key: String = "%s|%s" % [verb, point]
	if _frame_seen.has(key) or active_ping_count() >= MAX_PINGS:
		return
	_frame_seen[key] = true
	_ping(point, ATTACK_COLOR if attack else MOVE_COLOR, attack)


func _ping(point: Vector2, color: Color, with_blades: bool) -> void:
	var material: StandardMaterial3D = _material(Color(color, START_ALPHA))
	var ping: Node3D = Node3D.new()
	ping.name = "Ping"
	ping.set_meta(PING_META, true)
	add_child(ping)
	ping.global_position = Vector3(point.x, PING_HEIGHT, point.y)
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = _ring_mesh(material)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.scale = Vector3.ONE * START_RADIUS
	ping.add_child(ring)
	if with_blades:
		_add_blades(ping, _material(color))
	var tween: Tween = ping.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * END_RADIUS, PING_SECONDS)
	tween.tween_property(material, "albedo_color:a", 0.0, PING_SECONDS)
	tween.chain().tween_callback(ping.queue_free)


func _ring_mesh(material: StandardMaterial3D) -> TorusMesh:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.outer_radius = 1.0
	mesh.inner_radius = 1.0 - BAND_SHARE
	mesh.rings = RING_SEGMENTS
	mesh.ring_segments = 4
	mesh.material = material
	return mesh


## Two flat bars crossing at the ping's centre, held at full strength while the ring grows.
func _add_blades(ping: Node3D, material: StandardMaterial3D) -> void:
	for angle_sign: float in [1.0, -1.0]:
		var bar: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(BLADE_LENGTH, BLADE_WIDTH, BLADE_WIDTH)
		box.material = material
		bar.mesh = box
		bar.name = "Blade"
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bar.rotation.y = angle_sign * PI / 4.0
		ping.add_child(bar)


func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material
