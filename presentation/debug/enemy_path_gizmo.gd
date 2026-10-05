class_name EnemyPathGizmo
extends MeshInstance3D
## 3D debug lines for the night: a dim road from every spawn point the night uses to the castle, and
## a bright line from each living enemy to what it is heading for, coloured by target kind. It shows
## only while the debug overlay is open and the phase is NIGHT. Presentation only: it reads the
## simulation through getters and never writes it (DR-11; T-01-15 carried: the overlay ships in all
## builds and is read-only).

const ROAD_COLOR := Color(0.75, 0.75, 0.8, 0.55)
const KING_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const CASTLE_COLOR := Color(1.0, 0.35, 0.3, 1.0)
const BUILDING_COLOR := Color(0.35, 0.75, 1.0, 1.0)
## Lines float a little above the ground so they are not lost in it.
const LINE_HEIGHT: float = 0.4

var _ctx: RunContext
var _overlay: DebugOverlay
var _mesh: ImmediateMesh = ImmediateMesh.new()
var _material: StandardMaterial3D = StandardMaterial3D.new()
var _lines: int = 0


func _init() -> void:
	mesh = _mesh
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.no_depth_test = true
	_material.vertex_color_use_as_albedo = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


## Binds the gizmo to one run and the overlay whose visibility it follows.
func bind(ctx: RunContext, overlay: DebugOverlay) -> void:
	_ctx = ctx
	_overlay = overlay


func _ready() -> void:
	# Vertices are written in world coordinates, so the gizmo ignores its parent's transform.
	top_level = true
	global_transform = Transform3D.IDENTITY


func _process(_delta: float) -> void:
	refresh()


## Lines drawn at the last refresh; 0 while hidden.
func line_count() -> int:
	return _lines


## Rebuilds the lines from the simulation as it is right now, or hides and clears them when the
## overlay is closed or it is not night. Called every frame; tests call it to sync on demand.
func refresh() -> void:
	_mesh.clear_surfaces()
	_lines = 0
	var show_lines: bool = (
		_ctx != null
		and _overlay != null
		and _overlay.is_overlay_visible()
		and _ctx.run_manager.get_phase() == RunManager.RunPhase.NIGHT
	)
	visible = show_lines
	if not show_lines:
		return
	var segments: Array[Dictionary] = _segments()
	_lines = segments.size()
	if segments.is_empty():
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material)
	for segment: Dictionary in segments:
		var color: Color = segment["color"]
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(segment["from"])
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(segment["to"])
	_mesh.surface_end()


## Every line to draw: the roads first (spawn points in map order), then the enemies in id order.
func _segments() -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var castle: Vector2 = _ctx.castle.get_position()
	var night_number: int = _ctx.run_manager.get_night_number()
	for spawn_point_id: StringName in WaveSchedule.preview_counts(_ctx.map, night_number):
		var spawn_point: SpawnPointDef = _ctx.map.find_spawn_point(spawn_point_id)
		(
			segments
			. append(
				{
					"from": _lifted(Vector2(spawn_point.position.x, spawn_point.position.z)),
					"to": _lifted(castle),
					"color": ROAD_COLOR,
				}
			)
		)
	var enemies: EnemySystem = _ctx.night.get_enemies()
	for id: int in enemies.ids():
		var target: Dictionary = enemies.target_of(id)
		if target.is_empty():
			continue
		(
			segments
			. append(
				{
					"from": _lifted(enemies.position_of(id)),
					"to": _lifted(_target_position(target)),
					"color": _target_color(target["kind"]),
				}
			)
		)
	return segments


func _target_position(target: Dictionary) -> Vector2:
	var kind: StringName = target["kind"]
	if kind == PendingHits.KIND_KING:
		return _ctx.king.get_position()
	if kind == PendingHits.KIND_BUILDING:
		var spot: BuildSpotDef = _ctx.buildings.get_spot(_ctx.buildings.spot_at_index(target["id"]))
		if spot != null:
			return Vector2(spot.position.x, spot.position.z)
	return _ctx.castle.get_position()


func _target_color(kind: StringName) -> Color:
	if kind == PendingHits.KIND_KING:
		return KING_COLOR
	if kind == PendingHits.KIND_BUILDING:
		return BUILDING_COLOR
	return CASTLE_COLOR


func _lifted(ground: Vector2) -> Vector3:
	return Vector3(ground.x, LINE_HEIGHT, ground.y)
