class_name SquadPlanView
extends Node3D
## One selected squad's plan drawn on the ground (UI-SPEC "Patrol path" and "Queued orders", D-10,
## D-25): the dashed #FFE073 patrol line (0.12 m wide, 0.4 m dash, 0.3 m gap, alpha 0.8) with a
## 0.4 m disc at each end, and the waiting orders as numbered 0.4 m discs joined by a thin line in
## the verb colour (cyan move, #FF7A59 attack-move, #FFE073 patrol), the running order skipped and
## at most MAX_DISCS discs shown. The geometry is rebuilt only when the squad's orders or patrol
## path change; the discs and their Label3D numbers are pooled nodes reused between rebuilds.
## OrderMarkers owns one of these per squad and shows it for selected squads only. Display only: it
## is handed snapshots and writes nothing back.

## Most numbered discs shown for one squad.
const MAX_DISCS: int = OrderMarkers.MAX_DISCS_SHOWN
const DISC_RADIUS: float = 0.2
const DISC_THICKNESS: float = 0.02
const DISC_HEIGHT: float = 0.07
const LINE_HEIGHT: float = 0.05
const PATROL_WIDTH: float = 0.12
const DASH_LENGTH: float = 0.4
const GAP_LENGTH: float = 0.3
const QUEUE_LINE_WIDTH: float = 0.05
const LINE_ALPHA: float = 0.8
const DISC_ALPHA: float = 0.9
## A flashing patrol line blinks between full strength and this alpha.
const FLASH_LOW_ALPHA: float = 0.25
const FLASH_BLINKS_PER_SECOND: float = 4.0
const LABEL_HEIGHT: float = 0.15
const LABEL_PIXEL_SIZE: float = 0.02
const LABEL_FONT_SIZE: int = 18
const LABEL_OUTLINE_SIZE: int = 12
const MOVE_COLOR := Color(0.549, 0.9216, 1.0)
const ATTACK_COLOR := Color(1.0, 0.4784, 0.349)
const PATROL_COLOR := Color(1.0, 0.8784, 0.451)

var _orders_hash: int = 0
var _path_hash: int = 0
var _patrol_line: MeshInstance3D
var _patrol_material: StandardMaterial3D
var _queue_line: MeshInstance3D
var _discs: Array[Node3D] = []
var _disc_colors: Array[Color] = []
var _shown_discs: int = 0
var _patrol_discs: Array[MeshInstance3D] = []
var _patrol_corners: PackedVector3Array = PackedVector3Array()
var _flash_phase_high: bool = true


func _ready() -> void:
	_patrol_material = _line_material()
	_patrol_line = _make_line("PatrolLine", _patrol_material)
	_queue_line = _make_line("QueueLine", _line_material())
	for index: int in range(2):
		var end_disc: MeshInstance3D = _make_disc_mesh(PATROL_COLOR)
		end_disc.name = "PatrolEnd%d" % index
		end_disc.visible = false
		add_child(end_disc)
		_patrol_discs.append(end_disc)


## Brings the drawing up to date: `orders` as SquadSystem.orders_of answers (the running order
## first), `path` as patrol_path_of answers (centroid first, empty when not patrolling),
## `flashing` while a fresh patrol line blinks, `clock` the presentation time in seconds.
func show_plan(
	orders: Array[Dictionary], path: Array[Vector2], flashing: bool, clock: float
) -> void:
	visible = true
	var orders_hash: int = hash(orders)
	if orders_hash != _orders_hash:
		_orders_hash = orders_hash
		_rebuild_queue(orders)
	var path_hash: int = hash(path)
	if path_hash != _path_hash:
		_path_hash = path_hash
		_rebuild_patrol(path)
	_apply_flash(flashing, clock)


## Hides the whole drawing and forgets what it showed, so the next show_plan rebuilds it.
func hide_plan() -> void:
	if not visible:
		return
	visible = false
	_orders_hash = 0
	_path_hash = 0
	_rebuild_queue([] as Array[Dictionary])
	_rebuild_patrol([] as Array[Vector2])


## Numbered discs showing. Test hook.
func disc_count() -> int:
	return _shown_discs if visible else 0


## The numbers on the showing discs, in order. Test hook.
func disc_labels() -> PackedStringArray:
	var labels: PackedStringArray = PackedStringArray()
	for index: int in range(disc_count()):
		labels.append((_discs[index].get_node("Number") as Label3D).text)
	return labels


## The colours of the showing discs, in order. Test hook.
func disc_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for index: int in range(disc_count()):
		colors.append(_disc_colors[index])
	return colors


## True when a patrol line is showing. Test hook.
func has_patrol_line() -> bool:
	return visible and _patrol_line.visible


## Patrol end discs showing (0 or 2). Test hook.
func patrol_disc_count() -> int:
	var count: int = 0
	if visible:
		for end_disc: MeshInstance3D in _patrol_discs:
			if end_disc.visible:
				count += 1
	return count


## The corner points of the patrol line's dashes. Test hook.
func patrol_line_points() -> PackedVector3Array:
	if not has_patrol_line():
		return PackedVector3Array()
	return _patrol_corners


func _rebuild_queue(orders: Array[Dictionary]) -> void:
	var points: Array[Vector2] = []
	var colors: Array[Color] = []
	for index: int in range(1, orders.size()):
		if points.size() >= MAX_DISCS:
			break
		var order_points: Array = orders[index]["points"]
		if order_points.is_empty():
			continue
		points.append(order_points[0])
		colors.append(color_for(orders[index]["verb"]))
	_shown_discs = points.size()
	_disc_colors = colors
	_ensure_discs(_shown_discs)
	for index: int in range(_discs.size()):
		var disc: Node3D = _discs[index]
		disc.visible = index < _shown_discs
		if index >= _shown_discs:
			continue
		disc.position = _flat(points[index], DISC_HEIGHT)
		(disc.get_node("Disc") as MeshInstance3D).material_override = _disc_material(colors[index])
		(disc.get_node("Number") as Label3D).text = str(index + 1)
	# The line starts where the running order ends.
	var start: Array = orders[0]["points"] if not orders.is_empty() else []
	var corners: Array[Vector2] = []
	var corner_colors: Array[Color] = []
	if not start.is_empty() and not points.is_empty():
		corners.append(start.back())
		for index: int in range(points.size()):
			corners.append(points[index])
			corner_colors.append(colors[index])
	_queue_line.mesh = _solid_line_mesh(corners, corner_colors)
	_queue_line.visible = not corner_colors.is_empty()


func _rebuild_patrol(path: Array[Vector2]) -> void:
	var showing: bool = path.size() >= 2
	_patrol_line.visible = showing
	_patrol_corners = PackedVector3Array()
	_patrol_line.mesh = null
	if showing:
		var builder: _QuadBuilder = _dashes(path)
		_patrol_corners = builder.vertices()
		_patrol_line.mesh = builder.build()
	_patrol_discs[0].visible = showing
	_patrol_discs[1].visible = showing
	if showing:
		_patrol_discs[0].position = _flat(path[0], DISC_HEIGHT)
		_patrol_discs[1].position = _flat(path.back(), DISC_HEIGHT)


func _apply_flash(flashing: bool, clock: float) -> void:
	var high: bool = true
	if flashing:
		high = int(clock * FLASH_BLINKS_PER_SECOND * 2.0) % 2 == 0
	if high == _flash_phase_high:
		return
	_flash_phase_high = high
	_patrol_material.albedo_color = Color(
		1.0, 1.0, 1.0, 1.0 if high else FLASH_LOW_ALPHA / LINE_ALPHA
	)


## The colour a verb is drawn in.
static func color_for(verb: StringName) -> Color:
	if verb == SquadOrder.VERB_ATTACK_MOVE:
		return ATTACK_COLOR
	if verb == SquadOrder.VERB_PATROL:
		return PATROL_COLOR
	return MOVE_COLOR


func _ensure_discs(count: int) -> void:
	while _discs.size() < count:
		var holder: Node3D = Node3D.new()
		holder.name = "Disc%d" % _discs.size()
		holder.add_child(_make_disc_mesh(MOVE_COLOR))
		holder.get_child(0).name = "Disc"
		var label: Label3D = Label3D.new()
		label.name = "Number"
		label.font_size = LABEL_FONT_SIZE
		label.outline_size = LABEL_OUTLINE_SIZE
		label.pixel_size = LABEL_PIXEL_SIZE
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.shaded = false
		label.modulate = Color.WHITE
		label.outline_modulate = Color.BLACK
		label.position = Vector3(0.0, LABEL_HEIGHT, 0.0)
		holder.add_child(label)
		add_child(holder)
		_discs.append(holder)


func _make_disc_mesh(color: Color) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = DISC_RADIUS
	mesh.bottom_radius = DISC_RADIUS
	mesh.height = DISC_THICKNESS
	mesh.radial_segments = 24
	mesh.rings = 1
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _disc_material(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func _make_line(line_name: String, material: StandardMaterial3D) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = line_name
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visible = false
	add_child(instance)
	return instance


func _line_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _disc_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, DISC_ALPHA)
	return material


## The dashes of a polyline: every segment starts with a dash, and the last dash of each segment
## ends exactly on its end point so the line visibly passes through every waypoint.
func _dashes(path: Array[Vector2]) -> _QuadBuilder:
	var builder: _QuadBuilder = _QuadBuilder.new()
	var color: Color = Color(PATROL_COLOR, LINE_ALPHA)
	for index: int in range(path.size() - 1):
		var from: Vector2 = path[index]
		var span: Vector2 = path[index + 1] - from
		var length: float = span.length()
		if length < 0.001:
			continue
		var direction: Vector2 = span / length
		var at: float = 0.0
		var last_end: float = 0.0
		while at < length:
			last_end = minf(at + DASH_LENGTH, length)
			builder.add(
				from + direction * at, from + direction * last_end, PATROL_WIDTH, LINE_HEIGHT, color
			)
			at += DASH_LENGTH + GAP_LENGTH
		if last_end < length - 0.001:
			builder.add(
				from + direction * maxf(length - DASH_LENGTH, 0.0),
				path[index + 1],
				PATROL_WIDTH,
				LINE_HEIGHT,
				color
			)
	return builder


## A solid thin line through `corners`; segment i runs corner i to i + 1 in `colors[i]`.
func _solid_line_mesh(corners: Array[Vector2], colors: Array[Color]) -> ArrayMesh:
	var builder: _QuadBuilder = _QuadBuilder.new()
	for index: int in range(colors.size()):
		var color: Color = Color(colors[index], LINE_ALPHA)
		builder.add(corners[index], corners[index + 1], QUEUE_LINE_WIDTH, LINE_HEIGHT, color)
	return builder.build()


static func _flat(point: Vector2, height: float) -> Vector3:
	return Vector3(point.x, height, point.y)


## Collects flat quads (two triangles each) with a vertex colour and builds one ArrayMesh.
class _QuadBuilder:
	var _vertices: PackedVector3Array = PackedVector3Array()
	var _colors: PackedColorArray = PackedColorArray()
	var _normals: PackedVector3Array = PackedVector3Array()
	var _indices: PackedInt32Array = PackedInt32Array()

	func add(from: Vector2, to: Vector2, width: float, height: float, color: Color) -> void:
		var direction: Vector2 = (to - from).normalized()
		var side: Vector2 = Vector2(-direction.y, direction.x) * (width * 0.5)
		var base: int = _vertices.size()
		for corner: Vector2 in [from - side, from + side, to + side, to - side]:
			_vertices.append(Vector3(corner.x, height, corner.y))
			_colors.append(color)
			_normals.append(Vector3.UP)
		_indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	func vertices() -> PackedVector3Array:
		return _vertices

	func build() -> ArrayMesh:
		var mesh: ArrayMesh = ArrayMesh.new()
		if _vertices.is_empty():
			return mesh
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = _vertices
		arrays[Mesh.ARRAY_NORMAL] = _normals
		arrays[Mesh.ARRAY_COLOR] = _colors
		arrays[Mesh.ARRAY_INDEX] = _indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh
