class_name PondView
extends Node3D
## The visual-only pond and the Fishing Harbor's boats on it (D-11, ECON-05). A flat water disc of
## MapConfig.pond_radius at MapConfig.pond_center, drawn a few centimetres above the ground with no
## collision shape, plus one small boat (a hull, a mast and a sail, all engine primitives) for each
## boat a Harbor has. Nothing is drawn when pond_radius is 0 (no pond).
##
## Display only (DR-11): it reads the simulation through IncomeState.boats_of and follows the
## harbor_boats_changed event, and it never writes the simulation. The pond is not a plot and never
## enters the nav grid, so nobody is blocked, slowed or rerouted by it. Boat i of a Harbor is always
## drawn at the same fixed spot on the pond, a pure function of the index (boat_position), so a boat
## never moves when another one arrives and two runs draw the same pond.

const WATER_COLOR := Color(0.2, 0.46, 0.74)
const WATER_EMISSION := Color(0.04, 0.12, 0.22)
## The disc is this high and its middle sits this far above the ground, so it floats a few
## centimetres clear of the ground plane.
const WATER_HEIGHT: float = 0.05
const WATER_CENTER_Y: float = 0.045
const WATER_SEGMENTS: int = 64
## Where the boats float: a ring at this fraction of the radius.
const BOAT_RING_FRACTION: float = 0.6
## The angle between boat i and boat i + 1 (the golden angle), so the boats spread evenly round the
## ring however many there are, and boat 0 sits at angle 0.
const BOAT_ANGLE_STEP: float = 2.399963
## A second Harbor on the same pond starts its boats a little round the ring from the first.
const SLOT_ANGLE_OFFSET: float = 1.0
const BOAT_Y: float = 0.1
const HULL_SIZE := Vector3(1.5, 0.3, 0.6)
const MAST_SIZE := Vector3(0.06, 1.1, 0.06)
const SAIL_SIZE := Vector2(0.8, 0.8)
const HULL_COLOR := Color(0.5, 0.32, 0.16)
const MAST_COLOR := Color(0.3, 0.2, 0.1)
const SAIL_COLOR := Color(0.96, 0.94, 0.86)

var _ctx: RunContext
var _center: Vector2 = Vector2.ZERO
var _radius: float = 0.0
var _water: MeshInstance3D
## Harbor plot id -> the boat nodes drawn for it, in boat order.
var _boats: Dictionary = {}
## Harbor plot ids in MapConfig order; the index is the slot.
var _slots: Array[StringName] = []
var _hull_mesh: BoxMesh
var _mast_mesh: BoxMesh
var _sail_mesh: QuadMesh
var _hull_material: StandardMaterial3D
var _mast_material: StandardMaterial3D
var _sail_material: StandardMaterial3D


## Called once per run by MapRoot. A second call is ignored, so a rebind never doubles the pond or
## connects the event twice.
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_center = ctx.map.pond_center
	_radius = ctx.map.pond_radius
	if _radius <= 0.0 or not is_finite(_radius):
		return
	_make_shared_resources()
	_add_water()
	for spot: BuildSpotDef in ctx.map.spots:
		var building_def: BuildingDef = ctx.buildings.get_building_def_for_spot(spot.id)
		if building_def != null and building_def.income_curve == BuildingDef.IncomeCurve.BOATS:
			_slots.append(spot.id)
			_boats[spot.id] = []
			_show_boats(spot.id, ctx.income.boats_of(spot.id))
	ctx.events.harbor_boats_changed.connect(_on_harbor_boats_changed)


## True when a pond is drawn: the map names a radius above 0.
func has_pond() -> bool:
	return _water != null


## The radius of the drawn water disc in metres; 0 with no pond. Test hook, read-only.
func water_radius() -> float:
	return _radius if _water != null else 0.0


## The middle of the drawn water disc in world metres (x, z). Test hook, read-only.
func water_center() -> Vector2:
	return _center


## How many boats are drawn for the Harbor on `spot_id`; 0 for a plot that is not a Harbor.
func boat_count(spot_id: StringName) -> int:
	var drawn: Array = _boats.get(spot_id, [])
	return drawn.size()


## Where boat `index` (0-based) of the Harbor on `spot_id` floats, in world metres. A pure function
## of the index and the Harbor's slot: it never changes while the map is the same.
func boat_position(spot_id: StringName, index: int) -> Vector3:
	var slot: int = maxi(_slots.find(spot_id), 0)
	var angle: float = float(index) * BOAT_ANGLE_STEP + float(slot) * SLOT_ANGLE_OFFSET
	var reach: float = _radius * BOAT_RING_FRACTION
	return Vector3(_center.x + cos(angle) * reach, BOAT_Y, _center.y + sin(angle) * reach)


func _on_harbor_boats_changed(spot_id: StringName, boats: int) -> void:
	if _boats.has(spot_id):
		_show_boats(spot_id, boats)


## Grows the Harbor's drawn boats to `count`. Boats already drawn keep their place; a count below
## the drawn number removes the extra ones from the end.
func _show_boats(spot_id: StringName, count: int) -> void:
	var drawn: Array = _boats[spot_id]
	while drawn.size() < count:
		var boat: Node3D = _make_boat()
		boat.name = "Boat_%s_%d" % [spot_id, drawn.size()]
		boat.position = boat_position(spot_id, drawn.size())
		boat.rotation.y = float(drawn.size()) * 0.7
		add_child(boat)
		drawn.append(boat)
	while drawn.size() > count:
		var gone: Node3D = drawn.pop_back() as Node3D
		gone.queue_free()


func _add_water() -> void:
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = _radius
	disc.bottom_radius = _radius
	disc.height = WATER_HEIGHT
	disc.radial_segments = WATER_SEGMENTS
	disc.rings = 1
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = WATER_COLOR
	material.roughness = 0.25
	material.emission_enabled = true
	material.emission = WATER_EMISSION
	_water = MeshInstance3D.new()
	_water.name = "Water"
	_water.mesh = disc
	_water.material_override = material
	_water.position = Vector3(_center.x, WATER_CENTER_Y, _center.y)
	# No collision body is ever added: the pond blocks and slows nobody (D-11).
	add_child(_water)


func _make_shared_resources() -> void:
	_hull_mesh = BoxMesh.new()
	_hull_mesh.size = HULL_SIZE
	_mast_mesh = BoxMesh.new()
	_mast_mesh.size = MAST_SIZE
	_sail_mesh = QuadMesh.new()
	_sail_mesh.size = SAIL_SIZE
	_hull_material = _flat_material(HULL_COLOR)
	_mast_material = _flat_material(MAST_COLOR)
	_sail_material = _flat_material(SAIL_COLOR)
	_sail_material.cull_mode = BaseMaterial3D.CULL_DISABLED


func _flat_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


## One boat: a hull, a mast and a quad sail, sharing the meshes and materials of every boat.
func _make_boat() -> Node3D:
	var boat: Node3D = Node3D.new()
	var hull: MeshInstance3D = MeshInstance3D.new()
	hull.name = "Hull"
	hull.mesh = _hull_mesh
	hull.material_override = _hull_material
	hull.position = Vector3(0.0, HULL_SIZE.y * 0.5, 0.0)
	boat.add_child(hull)
	var mast: MeshInstance3D = MeshInstance3D.new()
	mast.name = "Mast"
	mast.mesh = _mast_mesh
	mast.material_override = _mast_material
	mast.position = Vector3(0.0, HULL_SIZE.y + MAST_SIZE.y * 0.5, 0.0)
	boat.add_child(mast)
	var sail: MeshInstance3D = MeshInstance3D.new()
	sail.name = "Sail"
	sail.mesh = _sail_mesh
	sail.material_override = _sail_material
	sail.position = Vector3(0.0, HULL_SIZE.y + SAIL_SIZE.y * 0.5 + 0.2, 0.0)
	boat.add_child(sail)
	return boat
