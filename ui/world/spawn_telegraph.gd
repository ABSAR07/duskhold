class_name SpawnTelegraph
extends Control
## LOOP-02: by day, every spawn point that will send enemies in the coming night wears a red disc
## carrying that night's enemy count. A spawn point on screen gets its disc over it; one off screen
## (they sit about 70 m out and the camera sees about 30 m across) gets the disc clamped to the
## screen edge with an arrow pointing toward it. Display only: it reads the map data and the camera
## and never writes the simulation. Mouse input is ignored.

## How far inside the screen edge a clamped marker sits, in pixels.
const EDGE_MARGIN_PX: float = 48.0
## A window so small that the margin would eat the screen keeps the margin to this share of the
## shorter side instead (the headless test window is 64 px square).
const MAX_MARGIN_SHARE: float = 0.25
const MARKER_SIZE := Vector2(44.0, 44.0)
const DISC_CENTER_COLOR := Color(1.0, 0.42, 0.34)
const DISC_EDGE_COLOR := Color(0.72, 0.1, 0.1)
const DISC_RIM_START: float = 0.8
const DISC_RIM_END: float = 0.9
const COUNT_FONT_SIZE: int = 20
const COUNT_OUTLINE_SIZE: int = 6
## The arrow triangle in marker space, pointing along +x, drawn just outside the disc.
const ARROW_POINTS: PackedVector2Array = [
	Vector2(26.0, -9.0),
	Vector2(40.0, 0.0),
	Vector2(26.0, 9.0),
]
const ARROW_COLOR := Color(1.0, 0.85, 0.5)

var _ctx: RunContext
var _disc_texture: GradientTexture2D
## One entry per marker, in MapConfig spawn-point order:
## {id: StringName, world: Vector3, root: Control, arrow: Polygon2D, text: String}.
var _entries: Array[Dictionary] = []
var _on_screen: Dictionary = {}


## The markers a night needs: one per spawn point that sends at least one enemy, as
## {spawn_point_id, count, world_position}, in MapConfig order. Empty for a waveless map and for a
## night number outside the authored nights. Pure.
static func markers_for(map: MapConfig, next_night: int) -> Array:
	var markers: Array = []
	var counts: Dictionary = WaveSchedule.preview_counts(map, next_night)
	for spawn_point: SpawnPointDef in map.spawn_points:
		if spawn_point == null or not counts.has(spawn_point.id):
			continue
		(
			markers
			. append(
				{
					"spawn_point_id": spawn_point.id,
					"count": counts[spawn_point.id],
					"world_position": spawn_point.position,
				}
			)
		)
	return markers


## The margin to use for a viewport: EDGE_MARGIN_PX, or less on a window too small to afford it.
static func edge_margin(viewport: Rect2) -> float:
	return minf(EDGE_MARGIN_PX, minf(viewport.size.x, viewport.size.y) * MAX_MARGIN_SHARE)


## Where a marker goes on screen. `projected` is the camera's unproject_position of the spawn point,
## `behind` whether the point is behind the camera (the projection then lies on the opposite side of
## the screen, so it is mirrored through the centre first). A point inside the viewport inset by
## `margin` (edges included) stays where it is and is on screen; any other, and every point behind
## the camera, goes to the inset rectangle's edge on the line from the centre toward it.
## Returns {position: Vector2, on_screen: bool, angle: float}, the angle (radians, screen axes)
## pointing from the centre toward the point.
static func place(projected: Vector2, behind: bool, viewport: Rect2, margin: float) -> Dictionary:
	var centre: Vector2 = viewport.get_center()
	var half: Vector2 = (viewport.size * 0.5 - Vector2(margin, margin)).max(Vector2.ZERO)
	var point: Vector2 = centre * 2.0 - projected if behind else projected
	var finite: bool = is_finite(point.x) and is_finite(point.y)
	var offset: Vector2 = point - centre if finite else Vector2.ZERO
	if finite and not behind and absf(offset.x) <= half.x and absf(offset.y) <= half.y:
		return {"position": point, "on_screen": true, "angle": offset.angle()}
	# A zero direction (exactly behind the centre, or no usable projection) points down the screen.
	var direction: Vector2 = offset if offset.length_squared() > 0.0 else Vector2.DOWN
	var reach_x: float = half.x / absf(direction.x) if direction.x != 0.0 else INF
	var reach_y: float = half.y / absf(direction.y) if direction.y != 0.0 else INF
	var reach: float = minf(reach_x, reach_y)
	return {"position": centre + direction * reach, "on_screen": false, "angle": direction.angle()}


## Binds the telegraph to one run. A repeat call is ignored so no signal is connected twice.
func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	_disc_texture = _make_disc_texture()
	ctx.events.phase_changed.connect(_on_phase_changed)
	ctx.events.day_started.connect(_on_day_started)
	_rebuild()


## Markers showing right now; none outside the day.
func marker_count() -> int:
	return _entries.size()


## The count a spawn point's marker shows; "" when it has no marker.
func marker_text(spawn_point_id: StringName) -> String:
	for entry: Dictionary in _entries:
		if entry["id"] == spawn_point_id:
			return entry["text"]
	return ""


## True when the spawn point's marker sits over the spawn point itself (not clamped to an edge).
func is_marker_on_screen(spawn_point_id: StringName) -> bool:
	return _on_screen.get(spawn_point_id, false)


func _process(_delta: float) -> void:
	if _entries.is_empty():
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var viewport_rect: Rect2 = get_viewport_rect()
	for entry: Dictionary in _entries:
		var world: Vector3 = entry["world"]
		var placed: Dictionary = place(
			camera.unproject_position(world),
			camera.is_position_behind(world),
			viewport_rect,
			edge_margin(viewport_rect)
		)
		var root: Control = entry["root"]
		var arrow: Polygon2D = entry["arrow"]
		root.position = (placed["position"] as Vector2) - MARKER_SIZE * 0.5
		arrow.visible = not placed["on_screen"]
		arrow.rotation = placed["angle"]
		_on_screen[entry["id"]] = placed["on_screen"]


func _on_phase_changed(_old_phase: int, _new_phase: int) -> void:
	_rebuild()


func _on_day_started(_day_number: int) -> void:
	_rebuild()


## Replaces every marker: by day, one per spawn point of the coming night, in map order; otherwise
## none. Markers leave the tree at once so marker_count() never lags a frame behind.
func _rebuild() -> void:
	for entry: Dictionary in _entries:
		var old_root: Control = entry["root"]
		remove_child(old_root)
		old_root.queue_free()
	_entries.clear()
	_on_screen.clear()
	if _ctx.run_manager.get_phase() != RunManager.RunPhase.DAY:
		return
	for marker: Dictionary in markers_for(_ctx.map, _ctx.run_manager.get_night_number() + 1):
		_entries.append(_add_marker(marker))


func _add_marker(marker: Dictionary) -> Dictionary:
	var root: Control = Control.new()
	root.size = MARKER_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var disc: TextureRect = TextureRect.new()
	disc.texture = _disc_texture
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.size = MARKER_SIZE
	root.add_child(disc)
	var text: String = str(marker["count"])
	var label: Label = Label.new()
	label.text = text
	label.size = MARKER_SIZE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", COUNT_FONT_SIZE)
	label.add_theme_color_override("font_outline_color", DISC_EDGE_COLOR.darkened(0.5))
	label.add_theme_constant_override("outline_size", COUNT_OUTLINE_SIZE)
	root.add_child(label)
	var arrow: Polygon2D = Polygon2D.new()
	arrow.polygon = ARROW_POINTS
	arrow.color = ARROW_COLOR
	arrow.position = MARKER_SIZE * 0.5
	arrow.visible = false
	root.add_child(arrow)
	add_child(root)
	return {
		"id": marker["spawn_point_id"],
		"world": marker["world_position"],
		"root": root,
		"arrow": arrow,
		"text": text,
	}


func _make_disc_texture() -> GradientTexture2D:
	# Red in the middle, a darker rim, then transparent so the square texture reads as a disc.
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, DISC_RIM_START, DISC_RIM_END])
	gradient.colors = PackedColorArray(
		[DISC_CENTER_COLOR, DISC_EDGE_COLOR, Color(DISC_EDGE_COLOR, 0.0)]
	)
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	return texture
