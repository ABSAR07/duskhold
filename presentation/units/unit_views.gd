class_name UnitViews
extends Node3D
## Every living friendly unit drawn as one instance of its unit type's batch (PLAT-01): one
## MultiMesh per type, so a whole army costs a handful of draw calls and no node per unit. Each
## frame every unit sits at the interpolation of its previous and current simulation positions by
## the clock's alpha in EVERY phase (units walk by day, unlike enemies), so the 30 Hz simulation
## looks smooth at any frame rate. Each type wears its Kenney Mini Characters model baked once into
## one mesh (static bind pose, animation is Phase 8) with a small code-built weapon merged in, a
## sword for melee units and a bow for ranged ones; where the bake is not available (headless) the
## type wears a capsule instead. A hurt unit shows a billboard bar from one shared bar batch. Purely
## visual: it reads the simulation and the event bus and never writes either (D-13).

## Cap on units drawn in total across the type batches (it was 256 puppets). A unit past it is not
## drawn; the simulation still has it.
const MAX_VIEWS: int = 256
const PUPPET_HEIGHT: float = 1.4
## Colour of the capsule that stands in for a model that cannot be baked.
const FRIENDLY_COLOR := Color(0.25, 0.5, 0.95)
const BAR_WIDTH: float = 0.8
const BAR_CLEARANCE: float = 0.4
const MODEL_DIR := "res://assets/third_party/kenney_mini_characters/models/"
## Model file per unit type id (a unit type with no entry gets the capsule).
const MODEL_FILES: Dictionary = {
	&"footman": "character-male-a.glb",
	&"archer": "character-female-a.glb",
}
## Height in metres of each model at scale 1.0 (measured from its meshes), so every unit is
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
const SOURCE_BAKED: StringName = &"baked"
const SOURCE_CAPSULE: StringName = &"capsule"
## The culling box of every batch reaches this high above the ground.
const BOUNDS_HEIGHT: float = 8.0
const FALLBACK_RADIUS: float = 0.45

var _ctx: RunContext
## Unit type id -> its CrowdBatch, once the type's mesh is ready.
var _batch_of: Dictionary = {}
## Unit type id -> &"baked" or &"capsule".
var _source_of: Dictionary = {}
## Unit type id -> the model kept in the tree until its bake succeeds or the one retry fails.
var _waiting: Dictionary = {}
var _bounds: AABB = AABB()
var _bars: HealthBarBatch
## Unit id -> its hit points as of its last hit; a unit never hit has no entry.
var _hp_of: Dictionary = {}
## Unit id -> its max health, set on unit_spawned for the bars.
var _max_hp_of: Dictionary = {}
## The units drawn this frame, ascending by id: the CPU mirror the test hooks read.
var _drawn_ids: PackedInt32Array = PackedInt32Array()
var _drawn_origins: PackedVector3Array = PackedVector3Array()
var _drawn: int = 0


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_drawn_ids.resize(MAX_VIEWS)
	_drawn_origins.resize(MAX_VIEWS)
	var half: float = ctx.map.ground_half_extent
	_bounds = AABB(
		Vector3(ctx.map.castle_position.x - half, 0.0, ctx.map.castle_position.z - half),
		Vector3(half * 2.0, BOUNDS_HEIGHT, half * 2.0)
	)
	_bars = HealthBarBatch.new()
	_bars.setup_bars(BAR_WIDTH, MAX_VIEWS)
	_bars.name = "Bars"
	_bars.set_bounds(_bounds)
	add_child(_bars)
	for def: UnitDef in ctx.map.units:
		_prepare_type(def)
	var units: UnitSystem = ctx.squads.get_units()
	for unit_id: int in units.ids():
		_max_hp_of[unit_id] = units.def_of(unit_id).max_health
	ctx.events.unit_spawned.connect(_on_unit_spawned)
	ctx.events.unit_damaged.connect(_on_unit_damaged)
	ctx.events.unit_died.connect(_on_unit_died)
	ctx.events.squad_restored.connect(_on_squad_restored)


## Units drawn this frame, across all types.
func view_count() -> int:
	return _drawn


## True when unit `unit_id` is drawn this frame.
func has_view(unit_id: int) -> bool:
	return _find(unit_id) >= 0


## The ground point (y = 0) where unit `unit_id` is drawn this frame (selection rings and the
## order markers hang on it); the zero vector when it is not drawn.
func puppet_position(unit_id: int) -> Vector3:
	var slot: int = _find(unit_id)
	return _drawn_origins[slot] if slot >= 0 else Vector3.ZERO


## What unit type `def_id` is drawn with: &"baked" (its model) or &"capsule"; the empty name for a
## type that is unknown or whose mesh is not decided yet.
func mesh_source_of(def_id: StringName) -> StringName:
	return _source_of.get(def_id, &"")


## The fill ratio (hp / max health) of a drawn, hurt unit's bar; -1.0 when it has none.
func bar_ratio_of(unit_id: int) -> float:
	if not has_view(unit_id) or not _hp_of.has(unit_id):
		return -1.0
	var hp: int = _hp_of[unit_id]
	var max_hp: int = _max_hp_of.get(unit_id, 0)
	if not HealthBar3D.should_show(hp, max_hp):
		return -1.0
	return float(hp) / float(max_hp)


## Hurt-only bars drawn this frame. Test hook, read-only.
func bar_count() -> int:
	return _bars.count() if _bars != null else 0


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	_settle_waiting_types()
	for batch: CrowdBatch in _batch_of.values():
		batch.begin()
	_bars.begin()
	_drawn = 0
	var blend: float = _ctx.alpha()
	var units: UnitSystem = _ctx.squads.get_units()
	for unit_id: int in units.ids():
		if _drawn >= MAX_VIEWS:
			break
		var def: UnitDef = units.def_of(unit_id)
		var batch: CrowdBatch = _batch_of.get(def.id) as CrowdBatch if def != null else null
		if batch == null:
			continue
		var ground: Vector2 = units.previous_position_of(unit_id).lerp(
			units.position_of(unit_id), blend
		)
		var origin: Vector3 = Vector3(ground.x, 0.0, ground.y)
		if not batch.add(origin, Color(0.0, 0.0, 0.0, 0.0)):
			continue
		_drawn_ids[_drawn] = unit_id
		_drawn_origins[_drawn] = origin
		_drawn += 1
		if _hp_of.has(unit_id):
			var bar_origin: Vector3 = origin + Vector3.UP * (PUPPET_HEIGHT + BAR_CLEARANCE)
			_bars.add_if_hurt(bar_origin, _hp_of[unit_id], _max_hp_of.get(unit_id, 0))
	for batch: CrowdBatch in _batch_of.values():
		batch.commit()
	_bars.commit()


func _on_unit_spawned(
	unit_id: int, _squad_id: StringName, def_id: StringName, _pos: Vector2
) -> void:
	var def: UnitDef = _ctx.map.find_unit(def_id)
	_max_hp_of[unit_id] = def.max_health if def != null else 0


## The bar fills to hp / max and shows from the first hit.
func _on_unit_damaged(unit_id: int, _amount: int, hp: int) -> void:
	if _max_hp_of.has(unit_id):
		_hp_of[unit_id] = hp


## Dawn made the squad whole: every unit of it stands at full health, so its bar hides again (the
## hurt-only rule).
func _on_squad_restored(squad_id: StringName, _alive: int) -> void:
	for unit_id: int in _ctx.squads.unit_ids_of(squad_id):
		_hp_of.erase(unit_id)


func _on_unit_died(unit_id: int, _squad_id: StringName, _pos: Vector2, _killer: StringName) -> void:
	_hp_of.erase(unit_id)
	_max_hp_of.erase(unit_id)


## Slot of `unit_id` among the drawn units (ascending ids), or -1.
func _find(unit_id: int) -> int:
	var low: int = 0
	var high: int = _drawn - 1
	while low <= high:
		var middle: int = (low + high) >> 1
		var found: int = _drawn_ids[middle]
		if found == unit_id:
			return middle
		if found < unit_id:
			low = middle + 1
		else:
			high = middle - 1
	return -1


## Decides the mesh of one unit type: its model baked at once when that works, else kept in the
## tree for one more frame (a skeleton only poses once its node is in the tree), else a capsule.
func _prepare_type(def: UnitDef) -> void:
	var model: Node3D = _load_model(def.id)
	if model == null:
		_finish_type(def, null)
		return
	model.name = "Model_%s" % def.id
	add_child(model)
	var baked: ArrayMesh = MeshBaker.bake(model, _model_scale(def.id))
	if baked != null:
		model.queue_free()
		_finish_type(def, baked)
		return
	_waiting[def.id] = model


## The one retry for every model that could not be baked at bind; whatever still fails here wears
## the capsule.
func _settle_waiting_types() -> void:
	if _waiting.is_empty():
		return
	var pending: Dictionary = _waiting
	_waiting = {}
	for def_id: StringName in pending.keys():
		var model: Node3D = pending[def_id]
		var baked: ArrayMesh = MeshBaker.bake(model, _model_scale(def_id))
		model.queue_free()
		_finish_type(_ctx.map.find_unit(def_id), baked)


## Builds the type's batch from the baked body (or a capsule when `baked` is null) with its weapon
## merged in.
func _finish_type(def: UnitDef, baked: ArrayMesh) -> void:
	var mesh: ArrayMesh = baked
	var source: StringName = SOURCE_BAKED
	if mesh == null:
		mesh = ArrayMesh.new()
		var lift: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.0, PUPPET_HEIGHT * 0.5, 0.0))
		MeshBaker.append_primitive(mesh, _make_capsule(def), lift)
		source = SOURCE_CAPSULE
	var ranged: bool = def.projectile_speed > 0.0
	var weapon: Mesh = _make_bow() if ranged else _make_sword()
	var weapon_at: Vector3 = BOW_POSITION if ranged else SWORD_POSITION
	MeshBaker.append_primitive(mesh, weapon, Transform3D(Basis.IDENTITY, weapon_at))
	var batch: CrowdBatch = CrowdBatch.new()
	# No material override: every surface keeps the material it was baked with. Colours stay off,
	# the model materials read none.
	batch.setup(mesh, null, MAX_VIEWS, false)
	batch.name = "Units_%s" % def.id
	batch.set_bounds(_bounds)
	add_child(batch)
	_batch_of[def.id] = batch
	_source_of[def.id] = source


## Scale that brings the type's model to PUPPET_HEIGHT.
func _model_scale(def_id: StringName) -> float:
	return PUPPET_HEIGHT / float(MODEL_NATIVE_HEIGHTS.get(def_id, PUPPET_HEIGHT))


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


func _make_capsule(def: UnitDef) -> CapsuleMesh:
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = def.radius if def != null else FALLBACK_RADIUS
	mesh.height = PUPPET_HEIGHT
	mesh.material = _plain_material(FRIENDLY_COLOR)
	return mesh


## A thin box held out in front of the right hand.
func _make_sword() -> BoxMesh:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = SWORD_SIZE
	mesh.material = _plain_material(SWORD_COLOR)
	return mesh


## A thin vertical cylinder in front of the left hand.
func _make_bow() -> CylinderMesh:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = BOW_RADIUS
	mesh.bottom_radius = BOW_RADIUS
	mesh.height = BOW_HEIGHT
	mesh.material = _plain_material(BOW_COLOR)
	return mesh


func _plain_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	return material
