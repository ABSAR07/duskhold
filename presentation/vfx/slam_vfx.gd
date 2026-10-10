class_name SlamVfx
extends Node3D
## Makes the king's slam visible (KING-04, D-17). On king_ability_used a flat, unshaded white ring
## appears at the king's feet and grows from nothing to the weapon's slam radius over RING_SECONDS
## while it fades from RING_ALPHA to clear, so the player sees exactly how far the slam reached.
## The radius is read from the king's weapon, never a literal.
## Purely visual: the simulation has already decided every hit. Rings free themselves and are
## capped at MAX_RINGS, so a burst of events cannot pile up nodes; one past the cap is not drawn.

const MAX_RINGS: int = 4
const RING_SECONDS: float = 0.25
const RING_ALPHA: float = 0.85
## Width of the ring's band at full size, in metres.
const RING_THICKNESS: float = 0.15
## Height above the ground, so the ring is not z-fought by the terrain.
const RING_HEIGHT: float = 0.08
## Where a ring starts: not zero, so its scale is never degenerate.
const START_SCALE: float = 0.01
const RING_SEGMENTS: int = 48
const RING_META: StringName = &"slam_ring"

var _ctx: RunContext


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.king_ability_used.connect(_on_king_ability_used)


## Rings showing. Test hook, read-only.
func active_ring_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if child.has_meta(RING_META) and not child.is_queued_for_deletion():
			count += 1
	return count


func _on_king_ability_used(_hit_count: int) -> void:
	if active_ring_count() >= MAX_RINGS:
		return
	var radius: float = _ctx.king.get_weapon().slam_radius
	if not is_finite(radius) or radius <= 0.0:
		return
	var ground: Vector2 = _ctx.king.get_position()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 1.0, 1.0, RING_ALPHA)
	var mesh: TorusMesh = TorusMesh.new()
	mesh.outer_radius = 1.0
	mesh.inner_radius = maxf(1.0 - RING_THICKNESS / radius, 0.0)
	mesh.rings = RING_SEGMENTS
	mesh.ring_segments = 4
	mesh.material = material
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = mesh
	ring.set_meta(RING_META, true)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	ring.global_position = Vector3(ground.x, RING_HEIGHT, ground.y)
	ring.scale = Vector3.ONE * START_SCALE
	var tween: Tween = ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * radius, RING_SECONDS)
	tween.tween_property(material, "albedo_color:a", 0.0, RING_SECONDS)
	tween.chain().tween_callback(ring.queue_free)
