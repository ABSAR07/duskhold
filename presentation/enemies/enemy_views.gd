class_name EnemyViews
extends Node3D
## One puppet per live enemy. Puppets appear on enemy_spawned, leave on enemy_died, and each frame
## sit at the interpolation of the enemy's previous and current simulation positions by the
## clock's alpha, so the 30 Hz simulation looks smooth at any frame rate. Purely visual: it reads
## the simulation and never writes it.

## Visual cap: a spawn past it gets no puppet (the simulation still has the enemy).
const MAX_VIEWS: int = 256
const PUPPET_HEIGHT: float = 1.6
const GRUNT_COLOR := Color(0.75, 0.18, 0.15)
const FALLBACK_COLOR := Color(0.6, 0.25, 0.65)
const SKIRMISHER_COLOR := Color(0.55, 0.3, 0.85)
const EMISSION_ENERGY: float = 0.35
const PUFF_SECONDS: float = 0.6

var _ctx: RunContext
var _views: Dictionary = {}
var _materials: Dictionary = {}


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.enemy_spawned.connect(_on_enemy_spawned)
	ctx.events.enemy_died.connect(_on_enemy_died)


## Puppets currently alive.
func view_count() -> int:
	return _views.size()


## Death puffs still showing. RED-phase shell.
func puff_count() -> int:
	return 0


## Null when the enemy has no puppet.
func get_view(enemy_id: int) -> Node3D:
	return _views.get(enemy_id) as Node3D


func _process(_delta: float) -> void:
	if _ctx == null:
		return
	var night_running: bool = _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
	var blend: float = _ctx.alpha() if night_running else 1.0
	var enemies: EnemySystem = _ctx.night.get_enemies()
	for enemy_id: int in _views.keys():
		var view: Node3D = _views[enemy_id]
		var ground: Vector2 = enemies.previous_position_of(enemy_id).lerp(
			enemies.position_of(enemy_id), blend
		)
		view.position = Vector3(ground.x, 0.0, ground.y)


func _on_enemy_spawned(enemy_id: int, def_id: StringName, pos: Vector2) -> void:
	if _views.size() >= MAX_VIEWS:
		return
	var view: Node3D = _make_puppet(_ctx.map.find_enemy(def_id), def_id)
	view.set_meta(&"enemy_id", enemy_id)
	add_child(view)
	view.position = Vector3(pos.x, 0.0, pos.y)
	_views[enemy_id] = view


func _on_enemy_died(enemy_id: int, _def_id: StringName, _pos: Vector2, _killer: StringName) -> void:
	var view: Node3D = _views.get(enemy_id) as Node3D
	if view == null:
		return
	_views.erase(enemy_id)
	remove_child(view)
	view.queue_free()


func _make_puppet(def: EnemyDef, def_id: StringName) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Enemy_%s" % def_id
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = def.radius if def != null else 0.5
	mesh.height = PUPPET_HEIGHT
	mesh.material = _material_for(def_id)
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Body"
	body.mesh = mesh
	root.add_child(body)
	body.position = Vector3(0.0, PUPPET_HEIGHT * 0.5, 0.0)
	return root


func _material_for(def_id: StringName) -> StandardMaterial3D:
	var cached: StandardMaterial3D = _materials.get(def_id) as StandardMaterial3D
	if cached != null:
		return cached
	var color: Color = GRUNT_COLOR if def_id == &"grunt" else FALLBACK_COLOR
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = EMISSION_ENERGY
	_materials[def_id] = material
	return material
