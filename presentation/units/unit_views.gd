class_name UnitViews
extends Node3D
## One puppet per living friendly unit. Puppets appear on unit_spawned, leave on unit_died, and each
## frame sit at the interpolation of the unit's previous and current simulation positions by the
## clock's alpha in EVERY phase (units walk by day, unlike enemies), so the 30 Hz simulation looks
## smooth at any frame rate. Each type wears a Kenney Mini Characters model (static bind pose,
## animation is Phase 8) with a small code-built weapon: a sword for melee units, a bow for ranged
## ones. A hurt-only health bar follows unit_damaged. Purely visual: it reads the simulation and
## never writes it.

## Visual cap: a spawn past it gets no puppet (the simulation still has the unit).
const MAX_VIEWS: int = 256
const PUPPET_HEIGHT: float = 1.4
## Colour of the capsule that stands in for a model that failed to load.
const FRIENDLY_COLOR := Color(0.25, 0.5, 0.95)
const BAR_WIDTH: float = 0.8
const BAR_CLEARANCE: float = 0.4
const MODEL_DIR := "res://assets/third_party/kenney_mini_characters/models/"
## Model file per unit type id (a unit type with no entry gets the capsule).
const MODEL_FILES: Dictionary = {
	&"footman": "character-male-a.glb",
	&"archer": "character-female-a.glb",
}
## Height in metres of each model at scale 1.0 (measured from its meshes), so every puppet is
## scaled to PUPPET_HEIGHT whatever the model.
const MODEL_NATIVE_HEIGHTS: Dictionary = {
	&"footman": 0.671,
	&"archer": 0.776,
}
const SWORD_COLOR := Color(0.82, 0.84, 0.9)
const SWORD_SIZE := Vector3(0.06, 0.06, 0.7)
const SWORD_POSITION := Vector3(-0.3, 0.75, 0.35)
const BOW_COLOR := Color(0.55, 0.35, 0.15)
const BOW_RADIUS: float = 0.03
const BOW_HEIGHT: float = 0.9
const BOW_POSITION := Vector3(0.3, 0.8, 0.3)

var _ctx: RunContext
var _views: Dictionary = {}


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.unit_spawned.connect(_on_unit_spawned)
	ctx.events.unit_damaged.connect(_on_unit_damaged)
	ctx.events.unit_died.connect(_on_unit_died)
	ctx.events.squad_restored.connect(_on_squad_restored)


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


## Dawn made the squad whole: every unit of it stands at full health, so its bar fills and hides
## again (the hurt-only rule).
func _on_squad_restored(squad_id: StringName, _alive: int) -> void:
	for unit_id: int in _ctx.squads.unit_ids_of(squad_id):
		var view: Node3D = _views.get(unit_id) as Node3D
		if view == null:
			continue
		var bar: HealthBar3D = view.get_node("HealthBar") as HealthBar3D
		var max_health: int = int(view.get_meta(&"max_health", 0))
		bar.set_health(max_health, max_health)


func _on_unit_died(unit_id: int, _squad_id: StringName, _pos: Vector2, _killer: StringName) -> void:
	var view: Node3D = _views.get(unit_id) as Node3D
	if view == null:
		return
	_views.erase(unit_id)
	remove_child(view)
	view.queue_free()


func _make_puppet(def: UnitDef, def_id: StringName) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Unit_%s" % def_id
	var model: Node3D = _load_model(def_id)
	if model != null:
		model.name = "Model"
		model.scale = Vector3.ONE * (PUPPET_HEIGHT / float(MODEL_NATIVE_HEIGHTS[def_id]))
		root.add_child(model)
	else:
		root.add_child(_make_capsule(def))
	var ranged: bool = def != null and def.projectile_speed > 0.0
	root.add_child(_make_bow() if ranged else _make_sword())
	var bar: HealthBar3D = HealthBar3D.new()
	bar.name = "HealthBar"
	bar.bar_width = BAR_WIDTH
	bar.height_offset = PUPPET_HEIGHT + BAR_CLEARANCE
	root.add_child(bar)
	root.set_meta(&"max_health", def.max_health if def != null else 0)
	return root


## The unit type model instanced from its imported file; null when the type has none or the file
## cannot be loaded (the caller then uses the capsule).
func _load_model(def_id: StringName) -> Node3D:
	if not MODEL_FILES.has(def_id):
		return null
	var path: String = MODEL_DIR + String(MODEL_FILES[def_id])
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = load(path) as PackedScene
	return scene.instantiate() as Node3D if scene != null else null


func _make_capsule(def: UnitDef) -> MeshInstance3D:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = def.radius if def != null else 0.45
	mesh.height = PUPPET_HEIGHT
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = FRIENDLY_COLOR
	mesh.material = material
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Body"
	body.mesh = mesh
	body.position = Vector3(0.0, PUPPET_HEIGHT * 0.5, 0.0)
	return body


## A thin box held out in front of the right hand.
func _make_sword() -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = SWORD_SIZE
	mesh.material = _plain_material(SWORD_COLOR)
	var sword: MeshInstance3D = MeshInstance3D.new()
	sword.name = "Weapon"
	sword.mesh = mesh
	sword.position = SWORD_POSITION
	return sword


## A thin vertical cylinder in front of the left hand.
func _make_bow() -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = BOW_RADIUS
	mesh.bottom_radius = BOW_RADIUS
	mesh.height = BOW_HEIGHT
	mesh.material = _plain_material(BOW_COLOR)
	var bow: MeshInstance3D = MeshInstance3D.new()
	bow.name = "Weapon"
	bow.mesh = mesh
	bow.position = BOW_POSITION
	return bow


func _plain_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	return material
