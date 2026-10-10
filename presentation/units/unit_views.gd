class_name UnitViews
extends Node3D
## One puppet per living friendly unit. Puppets appear on unit_spawned, leave on unit_died, and each
## frame sit at the interpolation of the unit's previous and current simulation positions by the
## clock's alpha in EVERY phase (units walk by day, unlike enemies), so the 30 Hz simulation looks
## smooth at any frame rate. A hurt-only health bar follows unit_damaged. Purely visual: it reads
## the simulation and never writes it.

## Visual cap: a spawn past it gets no puppet (the simulation still has the unit).
const MAX_VIEWS: int = 256
const PUPPET_HEIGHT: float = 1.4
const FRIENDLY_COLOR := Color(0.25, 0.5, 0.95)
const BAR_WIDTH: float = 0.8
const BAR_CLEARANCE: float = 0.4

var _ctx: RunContext
var _views: Dictionary = {}


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.unit_spawned.connect(_on_unit_spawned)
	ctx.events.unit_damaged.connect(_on_unit_damaged)
	ctx.events.unit_died.connect(_on_unit_died)


## Puppets currently alive.
func view_count() -> int:
	return _views.size()


## Null when the unit has no puppet.
func get_view(unit_id: int) -> Node3D:
	return _views.get(unit_id) as Node3D


## Where the unit's puppet stands now (later plans hang selection rings on it); the zero vector
## when the unit has no puppet.
func puppet_position(unit_id: int) -> Vector3:
	var view: Node3D = _views.get(unit_id) as Node3D
	return view.position if view != null else Vector3.ZERO


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	var blend: float = _ctx.alpha()
	var units: UnitSystem = _ctx.squads.get_units()
	for unit_id: int in _views.keys():
		var view: Node3D = _views[unit_id]
		var ground: Vector2 = units.previous_position_of(unit_id).lerp(
			units.position_of(unit_id), blend
		)
		view.position = Vector3(ground.x, 0.0, ground.y)


func _on_unit_spawned(
	unit_id: int, _squad_id: StringName, def_id: StringName, pos: Vector2
) -> void:
	if _views.size() >= MAX_VIEWS:
		return
	var view: Node3D = _make_puppet(_ctx.map.find_unit(def_id), def_id)
	view.set_meta(&"unit_id", unit_id)
	add_child(view)
	view.position = Vector3(pos.x, 0.0, pos.y)
	_views[unit_id] = view


## The bar fills to hp / max and shows from the first hit.
func _on_unit_damaged(unit_id: int, _amount: int, hp: int) -> void:
	var view: Node3D = _views.get(unit_id) as Node3D
	if view == null:
		return
	var bar: HealthBar3D = view.get_node("HealthBar") as HealthBar3D
	bar.set_health(hp, int(view.get_meta(&"max_health", 0)))


func _on_unit_died(unit_id: int, _squad_id: StringName, _pos: Vector2, _killer: StringName) -> void:
	var view: Node3D = _views.get(unit_id) as Node3D
	if view == null:
		return
	_views.erase(unit_id)
	remove_child(view)
	view.queue_free()


func _make_puppet(def: UnitDef, def_id: StringName) -> Node3D:
	var radius: float = def.radius if def != null else 0.45
	var root: Node3D = Node3D.new()
	root.name = "Unit_%s" % def_id
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = PUPPET_HEIGHT
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = FRIENDLY_COLOR
	mesh.material = material
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Body"
	body.mesh = mesh
	root.add_child(body)
	body.position = Vector3(0.0, PUPPET_HEIGHT * 0.5, 0.0)
	var bar: HealthBar3D = HealthBar3D.new()
	bar.name = "HealthBar"
	bar.bar_width = BAR_WIDTH
	bar.height_offset = PUPPET_HEIGHT + BAR_CLEARANCE
	root.add_child(bar)
	root.set_meta(&"max_health", def.max_health if def != null else 0)
	return root
