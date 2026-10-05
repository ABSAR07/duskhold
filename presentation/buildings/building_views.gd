class_name BuildingViews
extends Node3D
## World views for spots, buildings and the castle landmark. A BuildingViewCatalog supplies CC0
## model scenes (plan 01-07); anything the catalog lacks falls back to a primitive stand-in.

const DEFAULT_CATALOG: BuildingViewCatalog = preload(
	"res://presentation/buildings/building_view_catalog.tres"
)
const VIEW_SOURCE_PRIMITIVE := "primitive"
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
## The castle's health bar floats this high above its centre, clear of the turret.
const CASTLE_BAR_HEIGHT: float = KEEP_SIZE.y + TURRET_HEIGHT + 1.2
const CASTLE_BAR_WIDTH: float = 5.0

## Model lookup; assign before bind_run. A null catalog means primitives everywhere.
@export var catalog: BuildingViewCatalog = DEFAULT_CATALOG

var _ctx: RunContext
var _views: Dictionary = {}
var _castle_bar: HealthBar3D


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx
	_add_castle(ctx.map.castle_position)
	for spot_id: StringName in ctx.buildings.spot_ids():
		_add_marker(spot_id)
	ctx.events.building_built.connect(_on_building_built)


## The castle's health bar: hidden at full health, shown once the castle is hurt (D-12 rule).
func get_castle_health_bar() -> HealthBar3D:
	return _castle_bar


## Null if no building stands on the spot.
func get_view(spot_id: StringName) -> Node3D:
	return _views.get(spot_id) as Node3D


## The castle landmark (no interaction) with a hurt-only health bar fed by castle_damaged.
func _add_castle(castle_position: Vector3) -> void:
	var castle: Node3D = _instance_model(catalog.find_castle() if catalog != null else null)
	if castle != null:
		castle.name = "CastleCenter"
		add_child(castle)
		castle.position = castle_position
		_add_castle_bar(castle)
		return
	castle = Node3D.new()
	castle.name = "CastleCenter"
	castle.set_meta(&"view_source", VIEW_SOURCE_PRIMITIVE)
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
	_add_castle_bar(castle)


func _add_castle_bar(castle: Node3D) -> void:
	_castle_bar = HealthBar3D.new()
	_castle_bar.name = "HealthBar"
	_castle_bar.bar_width = CASTLE_BAR_WIDTH
	_castle_bar.height_offset = CASTLE_BAR_HEIGHT
	castle.add_child(_castle_bar)
	_castle_bar.set_health(_ctx.castle.get_health(), _ctx.castle.get_max_health())
	_ctx.events.castle_damaged.connect(_on_castle_damaged)


func _on_castle_damaged(_amount: int, hp: int, max_hp: int) -> void:
	_castle_bar.set_health(hp, max_hp)


func _add_marker(spot_id: StringName) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = MARKER_RADIUS
	mesh.bottom_radius = MARKER_RADIUS
	mesh.height = MARKER_HEIGHT
	var spot: BuildSpotDef = _ctx.buildings.get_spot(spot_id)
	mesh.material = _make_material(_marker_color(spot.building_id))
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "Spot_%s" % spot_id
	marker.mesh = mesh
	add_child(marker)
	marker.position = spot.position


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


## The single seam where a building's look is chosen: a catalog model if one is assigned for
## this building and tier, else the primitive. Meta `view_source` records which.
func _make_visual(building_id: StringName, tier: int) -> Node3D:
	if catalog != null:
		var model: Node3D = _instance_model(catalog.find(building_id, tier))
		if model != null:
			return model
	return _make_primitive_visual(building_id, tier)


## Instances a model scene and tags it with its source path; null if there is no scene or its
## root is not a Node3D (warned about, and freed so a mis-authored catalog entry does not leak).
func _instance_model(scene: PackedScene) -> Node3D:
	if scene == null:
		return null
	var instance: Node = scene.instantiate()
	var model: Node3D = instance as Node3D
	if model == null:
		push_warning(
			"BuildingViews: '%s' root is not a Node3D; using the primitive" % scene.resource_path
		)
		instance.free()
		return null
	model.set_meta(&"view_source", scene.resource_path)
	return model


func _make_primitive_visual(building_id: StringName, tier: int) -> Node3D:
	var view: Node3D = Node3D.new()
	view.set_meta(&"view_source", VIEW_SOURCE_PRIMITIVE)
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
