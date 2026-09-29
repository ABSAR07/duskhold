class_name BuildingViews
extends Node3D
## World views for spots, buildings and the castle landmark. Placeholder primitives until the
## CC0 models (plan 01-07), which swap in at _make_visual.

const MARKER_RADIUS: float = 1.6
const MARKER_HEIGHT: float = 0.1
## D-02: one building type per plot, so the plot colour says which type it takes.
const HOUSE_MARKER_COLOR := Color(0.82, 0.7, 0.48)
const TOWER_MARKER_COLOR := Color(0.36, 0.44, 0.62)
const HOUSE_COLOR := Color(0.78, 0.66, 0.45)
const TOWER_COLOR := Color(0.42, 0.5, 0.68)
const KEEP_COLOR := Color(0.55, 0.55, 0.58)
const KEEP_SIZE := Vector3(6.0, 5.0, 6.0)
const TURRET_RADIUS: float = 1.6
const TURRET_HEIGHT: float = 3.0
const HOUSE_BASE_WIDTH: float = 1.6
const HOUSE_WIDTH_PER_TIER: float = 0.5
const HOUSE_BASE_HEIGHT: float = 1.2
const HOUSE_HEIGHT_PER_TIER: float = 0.6
const TOWER_RADIUS: float = 0.9
const TOWER_BASE_HEIGHT: float = 3.0
const TOWER_HEIGHT_PER_TIER: float = 2.0

var _ctx: RunContext
var _views: Dictionary = {}


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx
	_add_castle(ctx.map.castle_position)
	for spot_id: StringName in ctx.buildings.spot_ids():
		_add_marker(spot_id)
	ctx.events.building_built.connect(_on_building_built)


## Null if no building stands on the spot.
func get_view(spot_id: StringName) -> Node3D:
	return _views.get(spot_id) as Node3D


## Landmark only in Phase 1 (D-03): no health, no interaction.
func _add_castle(castle_position: Vector3) -> void:
	var castle: Node3D = Node3D.new()
	castle.name = "CastleCenter"
	add_child(castle)
	castle.position = castle_position
	var keep_mesh: BoxMesh = BoxMesh.new()
	keep_mesh.size = KEEP_SIZE
	keep_mesh.material = _make_material(KEEP_COLOR)
	var keep: MeshInstance3D = MeshInstance3D.new()
	keep.name = "Keep"
	keep.mesh = keep_mesh
	castle.add_child(keep)
	keep.position = Vector3(0.0, KEEP_SIZE.y * 0.5, 0.0)
	var turret_mesh: CylinderMesh = CylinderMesh.new()
	turret_mesh.top_radius = TURRET_RADIUS
	turret_mesh.bottom_radius = TURRET_RADIUS
	turret_mesh.height = TURRET_HEIGHT
	turret_mesh.material = _make_material(KEEP_COLOR.darkened(0.15))
	var turret: MeshInstance3D = MeshInstance3D.new()
	turret.name = "Turret"
	turret.mesh = turret_mesh
	castle.add_child(turret)
	turret.position = Vector3(0.0, KEEP_SIZE.y + TURRET_HEIGHT * 0.5, 0.0)


func _add_marker(spot_id: StringName) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = MARKER_RADIUS
	mesh.bottom_radius = MARKER_RADIUS
	mesh.height = MARKER_HEIGHT
	mesh.material = _make_material(_marker_color(_ctx.buildings.get_spot(spot_id).building_id))
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Spot_%s" % spot_id
	marker.mesh = mesh
	add_child(marker)
	marker.position = _ctx.buildings.get_spot(spot_id).position


func _marker_color(building_id: StringName) -> Color:
	if building_id == &"tower":
		return TOWER_MARKER_COLOR
	return HOUSE_MARKER_COLOR


func _on_building_built(spot_id: StringName, building_id: StringName, new_tier: int) -> void:
	var old_view: Node3D = get_view(spot_id)
	if old_view != null:
		remove_child(old_view)
		old_view.queue_free()
	var view: Node3D = _make_visual(building_id, new_tier)
	view.name = "Building_%s" % spot_id
	view.set_meta(&"tier", new_tier)
	view.set_meta(&"building_id", building_id)
	add_child(view)
	view.position = _ctx.buildings.get_spot(spot_id).position
	_views[spot_id] = view


## The single seam where a building's look is chosen; plan 01-07 swaps in CC0 models here.
func _make_visual(building_id: StringName, tier: int) -> Node3D:
	var view: Node3D = Node3D.new()
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Body"
	var height: float
	if building_id == &"tower":
		height = TOWER_BASE_HEIGHT + TOWER_HEIGHT_PER_TIER * float(tier)
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = TOWER_RADIUS
		cylinder.bottom_radius = TOWER_RADIUS
		cylinder.height = height
		cylinder.material = _make_material(TOWER_COLOR)
		body.mesh = cylinder
	else:
		height = HOUSE_BASE_HEIGHT + HOUSE_HEIGHT_PER_TIER * float(tier)
		var width: float = HOUSE_BASE_WIDTH + HOUSE_WIDTH_PER_TIER * float(tier)
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(width, height, width)
		box.material = _make_material(HOUSE_COLOR)
		body.mesh = box
	view.add_child(body)
	body.position = Vector3(0.0, height * 0.5, 0.0)
	return view


func _make_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	return material
