class_name RubbleView
extends Node3D
## What a destroyed building leaves on its plot until dawn (D-12): a few low grey-brown slabs laid
## out from a fixed pattern (no randomness) and a one-shot puff of dust while they settle.
## Primitives only, so no asset needs a licence entry. Presentation only: it is told to collapse
## and never reads or writes the simulation. Plan 02-06 swaps it back for the model at dawn.

## Seconds the slabs take to settle and the building above them to sink away.
const COLLAPSE_SECONDS: float = 0.45
const RUBBLE_COLOR := Color(0.43, 0.38, 0.33)
const RUBBLE_DARK_COLOR := Color(0.32, 0.29, 0.27)
const DUST_COLOR := Color(0.7, 0.66, 0.6, 0.8)
const DUST_AMOUNT: int = 14
const DUST_LIFETIME: float = 0.7
const DUST_RADIUS: float = 0.22
const DUST_SPEED_MIN: float = 1.0
const DUST_SPEED_MAX: float = 2.4
const DUST_SPREAD_DEGREES: float = 55.0
const DUST_GRAVITY := Vector3(0.0, -1.2, 0.0)
## One slab each: centre offset (y is the slab's own half height), size, and yaw in degrees. The
## same pattern every time, so two runs draw the same rubble.
const SLABS: Array[Dictionary] = [
	{"offset": Vector3(0.0, 0.2, 0.0), "size": Vector3(1.5, 0.4, 1.3), "yaw": 12.0},
	{"offset": Vector3(0.85, 0.15, 0.4), "size": Vector3(0.7, 0.3, 0.6), "yaw": -28.0},
	{"offset": Vector3(-0.8, 0.12, -0.5), "size": Vector3(0.8, 0.24, 0.5), "yaw": 40.0},
	{"offset": Vector3(-0.3, 0.1, 0.85), "size": Vector3(0.6, 0.2, 0.5), "yaw": -8.0},
	{"offset": Vector3(0.4, 0.08, -0.9), "size": Vector3(0.5, 0.16, 0.5), "yaw": 63.0},
]

var _slabs: Node3D


func _ready() -> void:
	_slabs = Node3D.new()
	_slabs.name = "Slabs"
	add_child(_slabs)
	for index: int in range(SLABS.size()):
		var slab: Dictionary = SLABS[index]
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = slab["size"]
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = RUBBLE_COLOR if index % 2 == 0 else RUBBLE_DARK_COLOR
		mesh.material = material
		var piece: MeshInstance3D = MeshInstance3D.new()
		piece.name = "Slab%d" % index
		piece.mesh = mesh
		_slabs.add_child(piece)
		piece.position = slab["offset"]
		piece.rotation_degrees.y = slab["yaw"]


## Settles the slabs up from nothing over COLLAPSE_SECONDS and puffs the dust once. Call it once the
## node is in the tree.
func play_collapse() -> void:
	_slabs.scale = Vector3(1.0, 0.01, 1.0)
	var settle: Tween = create_tween()
	settle.tween_property(_slabs, "scale", Vector3.ONE, COLLAPSE_SECONDS)
	_puff_dust()


## The slab container; tests read its scale to see the collapse finish.
func get_slabs() -> Node3D:
	return _slabs


func _puff_dust() -> void:
	var puff: CPUParticles3D = CPUParticles3D.new()
	puff.name = "Dust"
	puff.one_shot = true
	puff.amount = DUST_AMOUNT
	puff.lifetime = DUST_LIFETIME
	puff.explosiveness = 1.0
	puff.direction = Vector3.UP
	puff.spread = DUST_SPREAD_DEGREES
	puff.initial_velocity_min = DUST_SPEED_MIN
	puff.initial_velocity_max = DUST_SPEED_MAX
	puff.gravity = DUST_GRAVITY
	puff.mesh = _make_dust_mesh()
	puff.finished.connect(puff.queue_free)
	add_child(puff)
	puff.position.y = 0.4
	puff.emitting = true


func _make_dust_mesh() -> SphereMesh:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = DUST_RADIUS
	mesh.height = DUST_RADIUS * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = DUST_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	return mesh
