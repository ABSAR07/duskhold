class_name EnemyViews
extends Node3D
## One puppet per live enemy. Puppets appear on enemy_spawned, leave on enemy_died, and each frame
## sit at the interpolation of the enemy's previous and current simulation positions by the
## clock's alpha, so the 30 Hz simulation looks smooth at any frame rate. Each type has its own
## colour and silhouette (the skirmisher is violet, taller and narrower than the grunt), a hurt-only
## health bar follows enemy_damaged, a hit flashes the body and a death leaves a small puff. Purely
## visual: it reads the simulation and never writes it.

## Visual cap: a spawn past it gets no puppet (the simulation still has the enemy).
const MAX_VIEWS: int = 256
## Visual cap on death puffs standing at once; each frees itself after PUFF_SECONDS.
const MAX_PUFFS: int = 64
const PUPPET_HEIGHT: float = 1.6
const RANGED_ID: StringName = &"ranged"
const GRUNT_COLOR := Color(0.75, 0.18, 0.15)
const SKIRMISHER_COLOR := Color(0.55, 0.3, 0.85)
const FALLBACK_COLOR := Color(0.6, 0.25, 0.65)
## The skirmisher is taller than the grunt and slimmer by this factor of its collision radius.
const SKIRMISHER_HEIGHT: float = 2.0
const SKIRMISHER_RADIUS_FACTOR: float = 0.7
const EMISSION_ENERGY: float = 0.35
const FLASH_ENERGY: float = 3.0
const FLASH_SECONDS: float = 0.15
const BAR_WIDTH: float = 0.9
const BAR_CLEARANCE: float = 0.5
const PUFF_SECONDS: float = 0.6
const PUFF_PARTICLES: int = 12
const PUFF_HEIGHT: float = 0.8

var _ctx: RunContext
var _views: Dictionary = {}
var _flash_tweens: Dictionary = {}
var _puff_mesh: SphereMesh


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	ctx.events.enemy_spawned.connect(_on_enemy_spawned)
	ctx.events.enemy_damaged.connect(_on_enemy_damaged)
	ctx.events.enemy_died.connect(_on_enemy_died)


## Puppets currently alive.
func view_count() -> int:
	return _views.size()


## Death puffs still showing. Test hook, read-only.
func puff_count() -> int:
	var count: int = 0
	for child: Node in get_children():
		if child.has_meta(&"puff") and not child.is_queued_for_deletion():
			count += 1
	return count


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


## The bar fills to hp / max and shows from the first hit; the body flashes and settles.
func _on_enemy_damaged(enemy_id: int, _amount: int, hp: int) -> void:
	var view: Node3D = _views.get(enemy_id) as Node3D
	if view == null:
		return
	var bar: HealthBar3D = view.get_node("HealthBar") as HealthBar3D
	bar.set_health(hp, int(view.get_meta(&"max_health", 0)))
	_flash(enemy_id, view)


func _on_enemy_died(enemy_id: int, def_id: StringName, pos: Vector2, _killer: StringName) -> void:
	var view: Node3D = _views.get(enemy_id) as Node3D
	if view == null:
		return
	_views.erase(enemy_id)
	_flash_tweens.erase(enemy_id)
	remove_child(view)
	view.queue_free()
	_spawn_puff(pos, _color_for(def_id))


func _flash(enemy_id: int, view: Node3D) -> void:
	var body: MeshInstance3D = view.get_node("Body") as MeshInstance3D
	var material: StandardMaterial3D = (body.mesh as CapsuleMesh).material as StandardMaterial3D
	var previous: Tween = _flash_tweens.get(enemy_id) as Tween
	if previous != null:
		previous.kill()
	material.emission_energy_multiplier = FLASH_ENERGY
	var tween: Tween = view.create_tween()
	tween.tween_property(material, "emission_energy_multiplier", EMISSION_ENERGY, FLASH_SECONDS)
	_flash_tweens[enemy_id] = tween


## A burst of small spheres where the enemy fell; frees itself after PUFF_SECONDS.
func _spawn_puff(pos: Vector2, color: Color) -> void:
	if puff_count() >= MAX_PUFFS:
		return
	var puff: CPUParticles3D = CPUParticles3D.new()
	puff.name = "DeathPuff"
	puff.set_meta(&"puff", true)
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.amount = PUFF_PARTICLES
	puff.lifetime = PUFF_SECONDS * 0.75
	puff.direction = Vector3.UP
	puff.spread = 70.0
	puff.initial_velocity_min = 1.2
	puff.initial_velocity_max = 2.4
	puff.gravity = Vector3(0.0, -4.0, 0.0)
	puff.mesh = _puff_mesh_for(color)
	add_child(puff)
	puff.position = Vector3(pos.x, PUFF_HEIGHT, pos.y)
	puff.emitting = true
	get_tree().create_timer(PUFF_SECONDS).timeout.connect(puff.queue_free)


func _puff_mesh_for(color: Color) -> SphereMesh:
	if _puff_mesh == null:
		_puff_mesh = SphereMesh.new()
		_puff_mesh.radius = 0.1
		_puff_mesh.height = 0.2
	var mesh: SphereMesh = _puff_mesh.duplicate() as SphereMesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	return mesh


func _make_puppet(def: EnemyDef, def_id: StringName) -> Node3D:
	var ranged: bool = def_id == RANGED_ID
	var radius: float = def.radius if def != null else 0.5
	var height: float = PUPPET_HEIGHT
	if ranged:
		radius *= SKIRMISHER_RADIUS_FACTOR
		height = SKIRMISHER_HEIGHT
	var root: Node3D = Node3D.new()
	root.name = "Enemy_%s" % def_id
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.material = _new_material(_color_for(def_id))
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Body"
	body.mesh = mesh
	root.add_child(body)
	body.position = Vector3(0.0, height * 0.5, 0.0)
	var bar: HealthBar3D = HealthBar3D.new()
	bar.name = "HealthBar"
	bar.bar_width = BAR_WIDTH
	bar.height_offset = height + BAR_CLEARANCE
	root.add_child(bar)
	root.set_meta(&"max_health", def.max_health if def != null else 0)
	return root


func _color_for(def_id: StringName) -> Color:
	if def_id == &"grunt":
		return GRUNT_COLOR
	if def_id == RANGED_ID:
		return SKIRMISHER_COLOR
	return FALLBACK_COLOR


## Every puppet owns its material, so one enemy's flash never lights up the rest of its type.
func _new_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = EMISSION_ENERGY
	return material
