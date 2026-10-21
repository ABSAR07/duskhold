extends GutTest
## Review WR-01: a gap that WallValidation accepts keeps a cell centre of the 2 m nav grid open
## whatever its alignment, so the castle field reaches the castle from outside the ring through it;
## the 3 m gap the old minimum allowed can seal the ring at some alignments, and is now refused.
## The ring of the walls fixture (a closed square) is shifted along y and given one gap that is
## moved along its north edge, both in quarter metres across one cell pitch.

const RING_FIXTURE := "res://tests/fixtures/fixture_map_walls.tres"
const RING: StringName = &"wall_ring"
const CASTLE := Vector2(0.0, 0.0)
## Outside the ring, north of its shifted north edge.
const OUTSIDE := Vector2(0.0, -20.0)
## One 2 m cell plus twice (0.4 m half thickness + 0.5 m largest agent radius), and a hair more.
const ACCEPTED_WIDTH: float = 3.85
const OLD_MINIMUM: float = 3.0
## Arc length of the first point of the north edge, where the gap starts to move.
const FIRST_START: float = 8.0
## A 3 m gap that seals the ring with no shift (found by sweeping, pinned here).
const SEALING_START: float = 8.25
const ALIGNMENTS: int = 9
const ALIGNMENT_STEP: float = 0.25


func _map_with_gap(shift_y: float, start: float, width: float) -> MapConfig:
	var shipped: MapConfig = load(RING_FIXTURE)
	var map: MapConfig = shipped.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for spot: BuildSpotDef in map.spots:
		if spot.id == RING:
			var points: PackedVector2Array = spot.wall_run.points.duplicate()
			for index: int in range(points.size()):
				points[index] += Vector2(0.0, shift_y)
			spot.wall_run.points = points
			spot.wall_run.gaps = PackedVector2Array([Vector2(start, start + width)])
	return map


func _reaches_the_castle(map: MapConfig) -> bool:
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var walls: WallSystem = WallSystem.new(map, buildings, events)
	buildings.apply_next_tier(RING)
	var grid: NavGrid = NavGrid.new(map)
	grid.rebuild(walls)
	var field: FlowField = FlowField.new()
	field.build(grid, CASTLE, map.castle_radius, 0.8)
	return field.is_reached(OUTSIDE)


func test_an_accepted_gap_is_routable_at_every_grid_alignment() -> void:
	for shift_step: int in range(ALIGNMENTS):
		for start_step: int in range(ALIGNMENTS):
			var shift_y: float = float(shift_step) * ALIGNMENT_STEP
			var start: float = FIRST_START + float(start_step) * ALIGNMENT_STEP
			var map: MapConfig = _map_with_gap(shift_y, start, ACCEPTED_WIDTH)
			var label: String = "ring shifted %s m, gap from %s m" % [shift_y, start]
			assert_eq(WallValidation.errors(map), PackedStringArray(), "%s is accepted" % label)
			assert_true(_reaches_the_castle(map), "%s: the castle is reachable" % label)


func test_the_three_metre_gap_the_old_minimum_allowed_can_seal_the_ring() -> void:
	var map: MapConfig = _map_with_gap(0.0, SEALING_START, OLD_MINIMUM)
	assert_false(_reaches_the_castle(map), "a 3 m gap at this alignment leaves no routable cell")
	var errors: PackedStringArray = WallValidation.errors(map)
	assert_eq(errors.size(), 1, "and validation refuses it: %s" % [errors])
	if errors.size() == 1:
		assert_string_contains(errors[0], "gap 1", "naming the gap")
