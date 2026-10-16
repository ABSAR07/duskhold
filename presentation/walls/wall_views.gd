class_name WallViews
extends Node3D
## Draws the wall segments from the wall state (BLDG-10). Each tier has its own look (D-03): tier I
## a wooden palisade built from primitives, tier II the Kenney Castle Kit wall piece, tier III the
## same wall with a Castle Kit tower-base pillar at both ends of every segment. A segment is tiled
## with pieces about a metre long, scaled to fill it exactly and laid along it. A broken segment
## sinks over COLLAPSE_SECONDS and leaves rubble in RubbleView's fixed slab pattern (D-05); a hurt
## segment shows a hurt-only bar; dawn raises the rebuilt pieces back. Every look is one CrowdBatch
## (instances = pieces), redrawn only when WallSystem.version() changes, a wall takes a hit or a
## collapse or a rise is still playing.
## Display only: it reads the simulation through getters and never writes it (DR-11). Rubble never
## blocks (D-05). The plot marker of a wall plot belongs to BuildingViews.

const WALL_MODEL: PackedScene = preload(
	"res://assets/third_party/kenney_castle_kit/models/wall.glb"
)
const PILLAR_MODEL: PackedScene = preload(
	"res://assets/third_party/kenney_castle_kit/models/tower-square-base.glb"
)

const LOOK_BARRICADE: StringName = &"barricade"
const LOOK_STONE: StringName = &"stone"
const LOOK_REINFORCED: StringName = &"reinforced"
## Index 0 is tier I.
const LOOKS: Array[StringName] = [LOOK_BARRICADE, LOOK_STONE, LOOK_REINFORCED]

const WOOD_COLOR := Color(0.55, 0.38, 0.22)
const FALLBACK_STONE_COLOR := Color(0.62, 0.62, 0.6)
## Pieces are about this long, in metres; each segment is cut into whole pieces that fill it.
const TILE_LENGTH: float = 1.0
## The palisade: four posts and two rails across one metre of length. Sizes are for the unit piece
## (one metre long, thickness scaled to twice the half thickness of the run).
const POST_COUNT: int = 4
const POST_SIZE := Vector3(0.14, 1.3, 0.3)
const RAIL_HEIGHTS: Array[float] = [0.35, 0.95]
const RAIL_SIZE := Vector3(1.0, 0.1, 0.36)
## A tower-base pillar stands on both ends of every reinforced segment: its width in metres and how
## much taller than the model it is drawn.
const PILLAR_WIDTH: float = 1.1
const PILLAR_HEIGHT_SCALE: float = 1.7
## The collapse: a broken segment sinks this far over this long, in presentation time.
const SINK_DEPTH: float = 1.2
const COLLAPSE_SECONDS: float = 0.4
## One rubble heap per piece of a broken segment, the slab pattern scaled to this share.
const RUBBLE_SCALE: float = 0.62
## A hurt segment's bar floats this high over the middle of the segment and is this wide.
const BAR_HEIGHT: float = 1.6
const BAR_WIDTH: float = 1.6
const BOUNDS_HEIGHT: float = 8.0
const UNBUILT: int = 0
const STANDING: int = 1
const BROKEN: int = 2

var _ctx: RunContext
var _palisade: CrowdBatch
var _wall: CrowdBatch
var _pillars: CrowdBatch
var _rubble: CrowdBatch
var _bars: HealthBarBatch
var _drawn_version: int = -1
var _dirty: bool = false
## Per segment: unbuilt, standing or broken at the latest redraw.
var _last_state: PackedByteArray = PackedByteArray()
## Per segment: flag drawn as a standing (or sinking) piece at the latest redraw.
var _standing: PackedByteArray = PackedByteArray()
## Per segment: seconds of the collapse and of the rise still to play.
var _sink_left: PackedFloat32Array = PackedFloat32Array()
var _rise_left: PackedFloat32Array = PackedFloat32Array()
var _piece_segments: int = 0
var _rubble_segments: int = 0
var _pillar_pieces: int = 0
var _looks: Dictionary = {}


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	var segments: int = ctx.walls.segment_count()
	var tiles: int = maxi(_tile_total(ctx.walls), 1)
	_palisade = _make_batch("Palisade", _build_palisade(), tiles, ctx.map)
	_wall = _make_batch("StoneWall", _model_or_block(WALL_MODEL), tiles, ctx.map)
	_pillars = _make_batch("Pillars", _model_or_block(PILLAR_MODEL), maxi(segments * 2, 1), ctx.map)
	_rubble = _make_batch("Rubble", _build_rubble(), tiles, ctx.map)
	_bars = HealthBarBatch.new()
	_bars.setup_bars(BAR_WIDTH, maxi(segments, 1))
	_bars.name = "Bars"
	_bars.set_bounds(_bounds(ctx.map))
	add_child(_bars)
	_last_state.resize(segments)
	_standing.resize(segments)
	_sink_left.resize(segments)
	_rise_left.resize(segments)
	for segment: int in range(segments):
		_last_state[segment] = _state_of(ctx.walls, segment)
	ctx.events.wall_damaged.connect(_on_wall_damaged)
	ctx.events.walls_restored.connect(_on_walls_restored)
	_redraw()


## Segments drawn as a standing piece at the latest redraw (a sinking one still counts). Test hook,
## read-only.
func piece_count() -> int:
	return _piece_segments


## Broken segments drawn as rubble at the latest redraw, once their collapse has played. Test hook,
## read-only.
func rubble_count() -> int:
	return _rubble_segments


## Hurt-only bars drawn at the latest redraw. Test hook, read-only.
func bar_count() -> int:
	return _bars.count() if _bars != null else 0


## Tower-base pillars drawn at the latest redraw. Test hook, read-only.
func pillar_count() -> int:
	return _pillar_pieces


## True when `segment` was drawn as a standing piece at the latest redraw.
func is_piece_drawn(segment: int) -> bool:
	return segment >= 0 and segment < _standing.size() and _standing[segment] == 1


## The look the plot wore at the latest redraw: &"barricade", &"stone" or &"reinforced"; &"" for a
## plot with nothing built or one that is not a wall plot. Test hook, read-only.
func tier_look_of(spot_id: StringName) -> StringName:
	return _looks.get(spot_id, &"") as StringName


func _process(delta: float) -> void:
	if _ctx == null:
		return
	var animating: bool = _advance(delta)
	if _dirty or animating or _ctx.walls.version() != _drawn_version:
		_redraw()


func _on_wall_damaged(
	_spot_id: StringName, _segment: int, _amount: int, _hp: int, _max_hp: int
) -> void:
	_dirty = true


func _on_walls_restored(_spot_ids: Array[StringName]) -> void:
	_dirty = true


## Counts the running collapses and rises down by `delta`; true while any ran this frame, so the
## frame it ends on is drawn too.
func _advance(delta: float) -> bool:
	var running: bool = false
	for segment: int in range(_sink_left.size()):
		if _sink_left[segment] > 0.0:
			_sink_left[segment] = maxf(_sink_left[segment] - delta, 0.0)
			running = true
		if _rise_left[segment] > 0.0:
			_rise_left[segment] = maxf(_rise_left[segment] - delta, 0.0)
			running = true
	return running


## Rewrites every batch from the wall state: standing and sinking segments as tiled pieces of
## their tier's look, settled broken ones as rubble, hurt standing ones as a bar.
func _redraw() -> void:
	var walls: WallSystem = _ctx.walls
	_drawn_version = walls.version()
	_dirty = false
	var batches: Array[CrowdBatch] = _all_batches()
	for batch: CrowdBatch in batches:
		batch.begin()
	_standing.fill(0)
	_piece_segments = 0
	_rubble_segments = 0
	_looks.clear()
	for segment: int in range(walls.segment_count()):
		var state: int = _state_of(walls, segment)
		_track(segment, state)
		var spot_id: StringName = walls.spot_of(segment)
		if state == STANDING or _sink_left[segment] > 0.0:
			_draw_piece(walls, segment, spot_id)
			_standing[segment] = 1
			_piece_segments += 1
			if state == STANDING and _sink_left[segment] <= 0.0:
				_draw_bar(walls, segment)
		elif state == BROKEN:
			_draw_rubble(walls, segment)
			_rubble_segments += 1
	_pillar_pieces = _pillars.count()
	for batch: CrowdBatch in batches:
		batch.commit()


## Starts the collapse of a segment that has just broken and the rise of one that is back.
func _track(segment: int, state: int) -> void:
	var before: int = _last_state[segment]
	if before == STANDING and state == BROKEN:
		_sink_left[segment] = COLLAPSE_SECONDS
		_rise_left[segment] = 0.0
	elif state == STANDING and before != STANDING:
		_rise_left[segment] = BuildingViews.RISE_SECONDS
		_sink_left[segment] = 0.0
	elif state == UNBUILT:
		_sink_left[segment] = 0.0
		_rise_left[segment] = 0.0
	_last_state[segment] = state


func _state_of(walls: WallSystem, segment: int) -> int:
	if walls.is_intact(segment):
		return STANDING
	return BROKEN if walls.max_health_of(segment) > 0 else UNBUILT


## The tiles of one segment lie along it; `y_scale` is the rise and `y_offset` the sink.
func _draw_piece(walls: WallSystem, segment: int, spot_id: StringName) -> void:
	var tier: int = _ctx.buildings.current_tier(spot_id)
	var look: StringName = LOOKS[clampi(tier, 1, LOOKS.size()) - 1]
	_looks[spot_id] = look
	var start: Vector2 = walls.segment_start(segment)
	var end: Vector2 = walls.segment_end(segment)
	var along: Vector2 = end - start
	var length: float = along.length()
	if length <= 0.0:
		return
	var direction: Vector2 = along / length
	var thickness: float = walls.half_thickness_of(segment) * 2.0
	var y_scale: float = _rise_scale(segment)
	var y_offset: float = _sink_offset(segment)
	var batch: CrowdBatch = _palisade if look == LOOK_BARRICADE else _wall
	var tiles: int = _tiles_of(length)
	var tile_length: float = length / float(tiles)
	for tile: int in range(tiles):
		var middle: Vector2 = start + direction * (tile_length * (float(tile) + 0.5))
		var xform: Transform3D = _laid(direction, tile_length, y_scale, thickness, middle, y_offset)
		batch.add_transform(xform, Color(0.0, 0.0, 0.0, 0.0))
	if look == LOOK_REINFORCED:
		var ends: Array[Vector2] = [start, end]
		for post: Vector2 in ends:
			var pillar: Transform3D = _laid(
				direction, PILLAR_WIDTH, y_scale * PILLAR_HEIGHT_SCALE, PILLAR_WIDTH, post, y_offset
			)
			_pillars.add_transform(pillar, Color(0.0, 0.0, 0.0, 0.0))


## A unit piece laid along `direction`: x runs along it by `length`, y is `height` times the model,
## z runs across it by `width`; its origin is on the ground at `at`, lowered by `y_offset`.
func _laid(
	direction: Vector2, length: float, height: float, width: float, at: Vector2, y_offset: float
) -> Transform3D:
	var basis: Basis = Basis(
		Vector3(direction.x, 0.0, direction.y) * length,
		Vector3(0.0, height, 0.0),
		Vector3(-direction.y, 0.0, direction.x) * width
	)
	return Transform3D(basis, Vector3(at.x, y_offset, at.y))


## One rubble heap per piece of the broken segment, once its collapse has played.
func _draw_rubble(walls: WallSystem, segment: int) -> void:
	var start: Vector2 = walls.segment_start(segment)
	var end: Vector2 = walls.segment_end(segment)
	var along: Vector2 = end - start
	var length: float = along.length()
	if length <= 0.0:
		return
	var direction: Vector2 = along / length
	var tiles: int = _tiles_of(length)
	var tile_length: float = length / float(tiles)
	for tile: int in range(tiles):
		var middle: Vector2 = start + direction * (tile_length * (float(tile) + 0.5))
		var xform: Transform3D = _laid(
			direction, RUBBLE_SCALE, RUBBLE_SCALE, RUBBLE_SCALE, middle, 0.0
		)
		_rubble.add_transform(xform, Color(0.0, 0.0, 0.0, 0.0))


func _draw_bar(walls: WallSystem, segment: int) -> void:
	var middle: Vector2 = (walls.segment_start(segment) + walls.segment_end(segment)) * 0.5
	_bars.add_if_hurt(
		Vector3(middle.x, BAR_HEIGHT, middle.y),
		walls.health_of(segment),
		walls.max_health_of(segment)
	)


## 0.05 to 1.0 over BuildingViews.RISE_SECONDS from BuildingViews.RISE_START_SCALE.
func _rise_scale(segment: int) -> float:
	if _rise_left[segment] <= 0.0:
		return 1.0
	var start: float = BuildingViews.RISE_START_SCALE.y
	var done: float = 1.0 - _rise_left[segment] / BuildingViews.RISE_SECONDS
	return lerpf(start, 1.0, clampf(done, 0.0, 1.0))


## 0 down to -SINK_DEPTH over COLLAPSE_SECONDS.
func _sink_offset(segment: int) -> float:
	if _sink_left[segment] <= 0.0:
		return 0.0
	var done: float = 1.0 - _sink_left[segment] / COLLAPSE_SECONDS
	return -SINK_DEPTH * clampf(done, 0.0, 1.0)


func _all_batches() -> Array[CrowdBatch]:
	var batches: Array[CrowdBatch] = [_palisade, _wall, _pillars, _rubble, _bars]
	return batches


func _tile_total(walls: WallSystem) -> int:
	var total: int = 0
	for segment: int in range(walls.segment_count()):
		total += _tiles_of(walls.segment_start(segment).distance_to(walls.segment_end(segment)))
	return total


func _tiles_of(length: float) -> int:
	return maxi(ceili(length / TILE_LENGTH), 1)


func _bounds(map: MapConfig) -> AABB:
	var half: float = map.ground_half_extent
	return AABB(
		Vector3(map.castle_position.x - half, -SINK_DEPTH, map.castle_position.z - half),
		Vector3(half * 2.0, BOUNDS_HEIGHT, half * 2.0)
	)


## A batch of `mesh` pieces that keep the materials the mesh carries.
func _make_batch(batch_name: String, mesh: Mesh, capacity: int, map: MapConfig) -> CrowdBatch:
	var batch: CrowdBatch = CrowdBatch.new()
	batch.setup(mesh, null, capacity, false)
	batch.name = batch_name
	batch.set_bounds(_bounds(map))
	add_child(batch)
	return batch


## The unit palisade piece: four posts and two rails across one metre, standing on the ground.
static func _build_palisade() -> ArrayMesh:
	var wood: StandardMaterial3D = StandardMaterial3D.new()
	wood.albedo_color = WOOD_COLOR
	wood.roughness = 0.9
	var post: BoxMesh = BoxMesh.new()
	post.size = POST_SIZE
	post.material = wood
	var rail: BoxMesh = BoxMesh.new()
	rail.size = RAIL_SIZE
	rail.material = wood
	var target: ArrayMesh = ArrayMesh.new()
	var spacing: float = 1.0 / float(POST_COUNT)
	for index: int in range(POST_COUNT):
		var x: float = -0.5 + spacing * (float(index) + 0.5)
		MeshBaker.append_primitive(
			target, post, Transform3D(Basis.IDENTITY, Vector3(x, POST_SIZE.y * 0.5, 0.0))
		)
	for height: float in RAIL_HEIGHTS:
		MeshBaker.append_primitive(
			target, rail, Transform3D(Basis.IDENTITY, Vector3(0.0, height, 0.0))
		)
	return target


## RubbleView's fixed slab pattern as one mesh, the same every time and never a collider.
static func _build_rubble() -> ArrayMesh:
	var target: ArrayMesh = ArrayMesh.new()
	for index: int in range(RubbleView.SLABS.size()):
		var slab: Dictionary = RubbleView.SLABS[index]
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = (
			RubbleView.RUBBLE_COLOR if index % 2 == 0 else RubbleView.RUBBLE_DARK_COLOR
		)
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = slab["size"]
		mesh.material = material
		var basis: Basis = Basis(Vector3.UP, deg_to_rad(float(slab["yaw"])))
		MeshBaker.append_primitive(target, mesh, Transform3D(basis, slab["offset"]))
	return target


## The baked Castle Kit model, or a plain stone block when the model cannot be baked.
static func _model_or_block(scene: PackedScene) -> Mesh:
	var baked: ArrayMesh = _bake(scene)
	if baked != null:
		return baked
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = FALLBACK_STONE_COLOR
	var block: BoxMesh = BoxMesh.new()
	block.size = Vector3(1.0, 1.3, 1.0)
	block.material = material
	var target: ArrayMesh = ArrayMesh.new()
	MeshBaker.append_primitive(target, block, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.65, 0.0)))
	return target


static func _bake(scene: PackedScene) -> ArrayMesh:
	if scene == null:
		return null
	var root: Node3D = scene.instantiate() as Node3D
	if root == null:
		return null
	var baked: ArrayMesh = MeshBaker.bake(root, 1.0)
	root.free()
	return baked
