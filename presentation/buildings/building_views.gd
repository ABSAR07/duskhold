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
## A building's health bar floats this far above the top of its model.
const BUILDING_BAR_CLEARANCE: float = 0.6
const BUILDING_BAR_WIDTH: float = 2.0
## The collapsing building sinks by this much and squashes to this scale on its way down.
const COLLAPSE_SINK_DEPTH: float = 0.6
const COLLAPSE_SQUASH_SCALE := Vector3(1.12, 0.04, 1.12)
const BAR_NODE_NAME := "HealthBar"
## A rebuilt building grows up from the ground over this long, from this flat scale.
const RISE_SECONDS: float = 0.4
const RISE_START_SCALE := Vector3(1.0, 0.05, 1.0)
## The fallen keep sinks and squashes over this long, then rubble sized to the keep (a RubbleView is
## about one building wide) stays where it stood. Kept inside the loss beat (D-17).
const CASTLE_COLLAPSE_SECONDS: float = 0.9
const CASTLE_RUBBLE_SCALE: float = 3.5

## Model lookup; assign before bind_run. A null catalog means primitives everywhere.
@export var catalog: BuildingViewCatalog = DEFAULT_CATALOG

var _ctx: RunContext
var _views: Dictionary = {}
var _bars: Dictionary = {}
var _castle_bar: HealthBar3D
var _castle_view: Node3D
var _castle_rubble: RubbleView


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	_ctx = ctx
	_add_castle(ctx.map.castle_position)
	for spot_id: StringName in ctx.buildings.spot_ids():
		_add_marker(spot_id)
	ctx.events.building_built.connect(_on_building_built)
	ctx.events.building_damaged.connect(_on_building_damaged)
	ctx.events.building_destroyed.connect(_on_building_destroyed)
	ctx.events.buildings_rebuilt.connect(_on_buildings_rebuilt)


## The rubble the keep collapsed into once the castle has fallen (D-17); null until then.
func get_castle_rubble() -> RubbleView:
	return _castle_rubble


## The castle's health bar: hidden at full health, shown once the castle is hurt (D-12 rule).
func get_castle_health_bar() -> HealthBar3D:
	return _castle_bar


## The health bar over the spot's building: hidden at full health, shown once hurt (D-12). Null when
## the spot has no standing building (empty, or fallen into rubble).
func get_health_bar(spot_id: StringName) -> HealthBar3D:
	return _bars.get(spot_id) as HealthBar3D


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
		_castle_view = castle
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
	_castle_view = castle
	_add_castle_bar(castle)


func _add_castle_bar(castle: Node3D) -> void:
	_castle_bar = HealthBar3D.new()
	_castle_bar.name = "HealthBar"
	_castle_bar.bar_width = CASTLE_BAR_WIDTH
	_castle_bar.height_offset = CASTLE_BAR_HEIGHT
	castle.add_child(_castle_bar)
	_castle_bar.set_health(_ctx.castle.get_health(), _ctx.castle.get_max_health())
	_ctx.events.castle_damaged.connect(_on_castle_damaged)
	_ctx.events.castle_destroyed.connect(_on_castle_destroyed)


func _on_castle_damaged(_amount: int, hp: int, max_hp: int) -> void:
	_castle_bar.set_health(hp, max_hp)


## The loss beat (D-17): the keep sinks and squashes away while rubble settles where it stood, and
## its bar goes. The simulation is already over, so nothing else on the field moves.
func _on_castle_destroyed() -> void:
	if _castle_rubble != null:
		return
	_castle_bar.visible = false
	var sink: Tween = create_tween().set_parallel(true)
	sink.tween_property(_castle_view, "scale", COLLAPSE_SQUASH_SCALE, CASTLE_COLLAPSE_SECONDS)
	sink.tween_property(
		_castle_view,
		"position:y",
		_castle_view.position.y - COLLAPSE_SINK_DEPTH,
		CASTLE_COLLAPSE_SECONDS
	)
	var rubble: RubbleView = RubbleView.new()
	rubble.name = "Rubble_Castle"
	rubble.set_meta(&"rubble", true)
	rubble.scale = Vector3.ONE * CASTLE_RUBBLE_SCALE
	add_child(rubble)
	rubble.position = _castle_view.position
	_castle_rubble = rubble
	rubble.play_collapse()


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
	_place_building(spot_id, building_id, new_tier)


## Dawn (LOOP-04): the rubble of every rebuilt building is replaced by its model at the tier it had,
## which grows up from the ground. Then every bar is read again, because the dawn repair made the
## survivors and the castle whole without a damage event to say so.
func _on_buildings_rebuilt(spot_ids: Array) -> void:
	for spot_id: StringName in spot_ids:
		var instance: BuildingInstance = _ctx.buildings.get_instance(spot_id)
		if instance == null:
			continue
		var view: Node3D = _place_building(spot_id, instance.building_id, instance.tier)
		view.scale = RISE_START_SCALE
		create_tween().tween_property(view, "scale", Vector3.ONE, RISE_SECONDS)
	for spot_id: StringName in _bars:
		var bar: HealthBar3D = _bars[spot_id]
		bar.set_health(_ctx.buildings.health_of(spot_id), _ctx.buildings.max_health_of(spot_id))
	_castle_bar.set_health(_ctx.castle.get_health(), _ctx.castle.get_max_health())


## Puts the model of `building_id` at `new_tier` on the plot in place of whatever the spot showed
## (an older tier, or rubble), with a fresh bar, and returns it.
func _place_building(spot_id: StringName, building_id: StringName, new_tier: int) -> Node3D:
	var old_view: Node3D = get_view(spot_id)
	if old_view != null:
		remove_child(old_view)
		old_view.queue_free()
	_bars.erase(spot_id)
	var view: Node3D = _make_visual(building_id, new_tier)
	view.name = "Building_%s" % spot_id
	view.set_meta(&"tier", new_tier)
	view.set_meta(&"building_id", building_id)
	add_child(view)
	view.position = _ctx.buildings.get_spot(spot_id).position
	_views[spot_id] = view
	_attach_bar(view, spot_id)
	return view


## One hurt-only bar above the building's model, told the building's current health.
func _attach_bar(view: Node3D, spot_id: StringName) -> void:
	var bar: HealthBar3D = HealthBar3D.new()
	bar.name = BAR_NODE_NAME
	bar.bar_width = BUILDING_BAR_WIDTH
	bar.height_offset = _top_of(view) + BUILDING_BAR_CLEARANCE
	view.add_child(bar)
	bar.set_health(_ctx.buildings.health_of(spot_id), _ctx.buildings.max_health_of(spot_id))
	_bars[spot_id] = bar


## Height of the highest mesh point under `view`, in the view's own space; 0.0 when it has no mesh.
## The view must already be in the tree.
func _top_of(view: Node3D) -> float:
	var top: float = 0.0
	var to_local: Transform3D = view.global_transform.affine_inverse()
	for node: Node in view.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var box: AABB = to_local * mesh_instance.global_transform * mesh_instance.get_aabb()
		top = maxf(top, box.end.y)
	return top


func _on_building_damaged(spot_id: StringName, _amount: int, hp: int, max_hp: int) -> void:
	var bar: HealthBar3D = get_health_bar(spot_id)
	if bar != null:
		bar.set_health(hp, max_hp)


## The building sinks and squashes away while rubble takes its place on the plot (D-12). The
## fallen building keeps no bar. The dawn rebuild swaps the rubble back for a model.
func _on_building_destroyed(spot_id: StringName, building_id: StringName, tier: int) -> void:
	_bars.erase(spot_id)
	var fallen: Node3D = get_view(spot_id)
	var plot: Vector3 = _ctx.buildings.get_spot(spot_id).position
	if fallen != null:
		_collapse(fallen)
	var rubble: RubbleView = RubbleView.new()
	rubble.name = "Rubble_%s" % spot_id
	rubble.set_meta(&"rubble", true)
	rubble.set_meta(&"tier", tier)
	rubble.set_meta(&"building_id", building_id)
	add_child(rubble)
	rubble.position = plot
	_views[spot_id] = rubble
	rubble.play_collapse()


## Tweens the fallen view down over RubbleView.COLLAPSE_SECONDS and frees it. Its bar goes at once.
func _collapse(fallen: Node3D) -> void:
	fallen.name = "Collapsing_%s" % fallen.name
	var bar: Node = fallen.get_node_or_null(BAR_NODE_NAME)
	if bar != null:
		fallen.remove_child(bar)
		bar.queue_free()
	var sink: Tween = create_tween().set_parallel(true)
	sink.tween_property(fallen, "scale", COLLAPSE_SQUASH_SCALE, RubbleView.COLLAPSE_SECONDS)
	sink.tween_property(
		fallen, "position:y", fallen.position.y - COLLAPSE_SINK_DEPTH, RubbleView.COLLAPSE_SECONDS
	)
	sink.chain().tween_callback(fallen.queue_free)


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
