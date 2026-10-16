class_name WallViews
extends Node3D
## Draws the wall segments from the wall state (BLDG-10): one box per intact segment, tinted by the
## tier of its run, and a flat slab of rubble where a segment is broken. Both are one CrowdBatch
## each, redrawn only when WallSystem.version() changes (a purchase, a break or a dawn restore).
## Boxes are placeholders; the Kenney Castle Kit look and the collapse come with plan 04-05.
## Display only: it reads the simulation through getters and never writes it (DR-11). Rubble never
## blocks (D-05). The plot marker of a wall plot belongs to BuildingViews.

## Tier I barricade, tier II stone wall, tier III reinforced wall.
const TIER_COLORS: Array[Color] = [
	Color(0.55, 0.38, 0.22), Color(0.62, 0.62, 0.6), Color(0.4, 0.4, 0.42)
]
const RUBBLE_COLOR := Color(0.32, 0.3, 0.28)
## Metres a standing piece rises.
const PIECE_HEIGHT: float = 1.2
## Metres a rubble slab rises, and how much longer and wider than its segment it lies.
const RUBBLE_HEIGHT: float = 0.25
const RUBBLE_LENGTH_SHARE: float = 0.9
const RUBBLE_WIDTH_SHARE: float = 1.4
## Walls are lit like everything else; this keeps the shared crowd shader's glow near zero.
const CALM_ENERGY: float = 0.04
const BOUNDS_HEIGHT: float = 8.0

var _ctx: RunContext
var _pieces: CrowdBatch
var _rubble: CrowdBatch
var _drawn_version: int = -1
## One flag per segment: drawn as a standing piece at the latest redraw.
var _standing: PackedByteArray = PackedByteArray()


func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _ctx != null:
		return
	_ctx = ctx
	var capacity: int = maxi(ctx.walls.segment_count(), 1)
	_pieces = _make_batch("Pieces", capacity, ctx.map)
	_rubble = _make_batch("Rubble", capacity, ctx.map)
	_standing.resize(ctx.walls.segment_count())
	_redraw()


## Standing pieces at the latest redraw. Test hook, read-only.
func piece_count() -> int:
	return _pieces.count() if _pieces != null else 0


## Rubble slabs at the latest redraw, one per broken segment. Test hook, read-only.
func rubble_count() -> int:
	return _rubble.count() if _rubble != null else 0


## True when `segment` was drawn as a standing piece at the latest redraw.
func is_piece_drawn(segment: int) -> bool:
	return segment >= 0 and segment < _standing.size() and _standing[segment] == 1


## RED stub (plan 04-05 task 2): the look of a plot, still unset.
func tier_look_of(_spot_id: StringName) -> StringName:
	return &""


## RED stub: hurt-only bars, still none.
func bar_count() -> int:
	return 0


## RED stub: tower-base pillars, still none.
func pillar_count() -> int:
	return 0


func _process(_delta: float) -> void:
	if _ctx != null and _ctx.walls.version() != _drawn_version:
		_redraw()


## Rewrites both batches from the wall state: every standing segment as a piece, every broken one
## as rubble, unbuilt ones as nothing.
func _redraw() -> void:
	var walls: WallSystem = _ctx.walls
	_drawn_version = walls.version()
	_pieces.begin()
	_rubble.begin()
	_standing.fill(0)
	for segment: int in range(walls.segment_count()):
		if walls.is_intact(segment):
			var tier: int = _ctx.buildings.current_tier(walls.spot_of(segment))
			var xform: Transform3D = _segment_transform(walls, segment, PIECE_HEIGHT, 1.0, 1.0)
			_pieces.add_transform(xform, Color(0.0, 0.0, 0.0, 0.0), _tier_color(tier))
			_standing[segment] = 1
		elif walls.max_health_of(segment) > 0:
			var slab: Transform3D = _segment_transform(
				walls, segment, RUBBLE_HEIGHT, RUBBLE_LENGTH_SHARE, RUBBLE_WIDTH_SHARE
			)
			_rubble.add_transform(slab, Color(0.0, 0.0, 0.0, 0.0), RUBBLE_COLOR)
	_pieces.commit()
	_rubble.commit()


## A unit box laid along the segment: x along it by its length, y `height` tall, z across it by
## twice its half thickness, each scaled by a share, standing on the ground.
func _segment_transform(
	walls: WallSystem, segment: int, height: float, length_share: float, width_share: float
) -> Transform3D:
	var start: Vector2 = walls.segment_start(segment)
	var end: Vector2 = walls.segment_end(segment)
	var along: Vector2 = end - start
	var length: float = along.length()
	var direction: Vector2 = along / length if length > 0.0 else Vector2.RIGHT
	var width: float = walls.half_thickness_of(segment) * 2.0 * width_share
	var basis: Basis = Basis(
		Vector3(direction.x, 0.0, direction.y) * length * length_share,
		Vector3(0.0, height, 0.0),
		Vector3(-direction.y, 0.0, direction.x) * width
	)
	var middle: Vector2 = (start + end) * 0.5
	return Transform3D(basis, Vector3(middle.x, height * 0.5, middle.y))


func _tier_color(tier: int) -> Color:
	return TIER_COLORS[clampi(tier, 1, TIER_COLORS.size()) - 1]


func _make_batch(batch_name: String, capacity: int, map: MapConfig) -> CrowdBatch:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3.ONE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://presentation/crowd/crowd_instance.gdshader")
	material.set_shader_parameter(&"albedo", Color.WHITE)
	material.set_shader_parameter(&"calm_energy", CALM_ENERGY)
	material.set_shader_parameter(&"flash_energy", CALM_ENERGY)
	var batch: CrowdBatch = CrowdBatch.new()
	batch.setup(mesh, material, capacity, true)
	batch.name = batch_name
	var half: float = map.ground_half_extent
	batch.set_bounds(
		AABB(
			Vector3(map.castle_position.x - half, 0.0, map.castle_position.z - half),
			Vector3(half * 2.0, BOUNDS_HEIGHT, half * 2.0)
		)
	)
	add_child(batch)
	return batch
