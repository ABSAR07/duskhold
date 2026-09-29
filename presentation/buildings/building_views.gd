class_name BuildingViews
extends Node3D
## World views for spots and buildings. Placeholder primitives until the CC0 models (plan 01-07).

const MARKER_RADIUS: float = 1.6
const MARKER_HEIGHT: float = 0.1
const MARKER_COLOR := Color(0.55, 0.55, 0.58)
const BUILDING_COLOR := Color(0.78, 0.66, 0.45)

var _ctx: RunContext
var _views: Dictionary = {}


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx
	for spot_id: StringName in ctx.buildings.spot_ids():
		_add_marker(spot_id)
	ctx.events.building_built.connect(_on_building_built)


## Null if no building stands on the spot.
func get_view(spot_id: StringName) -> Node3D:
	return _views.get(spot_id) as Node3D


func _add_marker(spot_id: StringName) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = MARKER_RADIUS
	mesh.bottom_radius = MARKER_RADIUS
	mesh.height = MARKER_HEIGHT
	mesh.material = _make_material(MARKER_COLOR)
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Spot_%s" % spot_id
	marker.mesh = mesh
	add_child(marker)
	marker.position = _ctx.buildings.get_spot(spot_id).position


func _on_building_built(spot_id: StringName, _building_id: StringName, new_tier: int) -> void:
	var old_view: Node3D = get_view(spot_id)
	if old_view != null:
		remove_child(old_view)
		old_view.queue_free()
	var view: Node3D = Node3D.new()
	view.name = "Building_%s" % spot_id
	view.set_meta(&"tier", new_tier)
	var height: float = 1.2 + 0.6 * float(new_tier - 1)
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.6 + 0.4 * float(new_tier - 1), height, 1.6 + 0.4 * float(new_tier - 1))
	box.material = _make_material(BUILDING_COLOR)
	var body: MeshInstance3D = MeshInstance3D.new()
	body.mesh = box
	view.add_child(body)
	body.position = Vector3(0.0, height * 0.5, 0.0)
	add_child(view)
	view.position = _ctx.buildings.get_spot(spot_id).position
	_views[spot_id] = view


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	return material
