extends GutTest
## PLAT-01 (plan 04-23, threats T-04-59 and T-04-60): the native structure index and wall decision
## beyond the pins. The pins hold the answers on well-formed worlds; this file proves the twins of
## the five static integer rules equal to the GDScript on the pins' exhaustive grid, and exercises
## the native entry points directly with bad ids, bad sizes and unusual input, so a mistake in a
## bound method fails here and not as an out-of-range read in a replay.

const Pins := preload("res://tests/unit/test_structure_decision_pins.gd")


## The probe's answers for the five rules over their grids, against the GDScript statics.
func _probe(
	op: int, a: Array[int], b: Array[int], c: Array[int], d: Array[int]
) -> PackedInt64Array:
	return NativeSim.probe_rules(
		op, PackedInt64Array(a), PackedInt64Array(b), PackedInt64Array(c), PackedInt64Array(d)
	)


func _fill(count: int) -> Array[int]:
	var zeros: Array[int] = []
	zeros.resize(count)
	zeros.fill(0)
	return zeros


func test_damage_per_300_twin_equals_the_gdscript_on_the_grid() -> void:
	var a: Array[int] = []
	var b: Array[int] = []
	var expected: PackedInt64Array = PackedInt64Array()
	for damage: int in Pins.DAMAGES:
		for interval: int in Pins.INTERVALS:
			a.append(damage)
			b.append(interval)
			expected.append(WallDecision.damage_per_300(damage, interval))
	var zeros: Array[int] = _fill(a.size())
	assert_eq(_probe(NativeSim.OP_RULE_DAMAGE_PER_300, a, b, zeros, zeros), expected, "damage")
	assert_eq(expected.size(), 90, "the grid is 9 by 10")


func test_ttd_ticks_twin_equals_the_gdscript_on_the_grid() -> void:
	var a: Array[int] = []
	var b: Array[int] = []
	var expected: PackedInt64Array = PackedInt64Array()
	for health: int in Pins.healths():
		for total: int in Pins.sums():
			a.append(health)
			b.append(total)
			expected.append(WallDecision.ttd_ticks(health, total))
	var zeros: Array[int] = _fill(a.size())
	assert_eq(_probe(NativeSim.OP_RULE_TTD_TICKS, a, b, zeros, zeros), expected, "ttd_ticks")
	assert_eq(expected.size(), Pins.healths().size() * Pins.sums().size(), "every pair")


func test_walk_ticks_twin_equals_the_gdscript_on_the_grid() -> void:
	var a: Array[int] = []
	var b: Array[int] = []
	var expected: PackedInt64Array = PackedInt64Array()
	for distance: int in Pins.DISTANCES:
		for speed: int in Pins.SPEEDS:
			a.append(distance)
			b.append(speed)
			expected.append(WallDecision.walk_ticks(distance, speed))
	var zeros: Array[int] = _fill(a.size())
	assert_eq(_probe(NativeSim.OP_RULE_WALK_TICKS, a, b, zeros, zeros), expected, "walk_ticks")


func test_should_break_and_keep_breaking_twins_equal_the_gdscript_on_the_grid() -> void:
	var ttds: Array[int] = []
	var straights: Array[int] = []
	var detours: Array[int] = []
	var hysteresis: Array[int] = []
	var breaks: PackedInt64Array = PackedInt64Array()
	var keeps: PackedInt64Array = PackedInt64Array()
	for ttd: int in Pins.TTDS:
		for straight: int in Pins.STRAIGHTS:
			for detour: int in Pins.DETOURS:
				for slack: int in Pins.HYSTERESES:
					ttds.append(ttd)
					straights.append(straight)
					detours.append(detour)
					hysteresis.append(slack)
					breaks.append(1 if WallDecision.should_break(ttd, straight, detour) else 0)
					keeps.append(
						1 if WallDecision.keep_breaking(ttd, straight, detour, slack) else 0
					)
	assert_eq(
		_probe(NativeSim.OP_RULE_SHOULD_BREAK, ttds, straights, detours, hysteresis),
		breaks,
		"should_break"
	)
	assert_eq(
		_probe(NativeSim.OP_RULE_KEEP_BREAKING, ttds, straights, detours, hysteresis),
		keeps,
		"keep_breaking"
	)
	assert_gt(breaks.count(1), 20, "the grid takes the wall sometimes")
	assert_gt(breaks.count(0), 20, "and goes round sometimes")
	assert_gt(keeps.count(0), 20, "and lets go sometimes")


func test_the_rule_probe_refuses_an_unknown_op_and_mismatched_arrays() -> void:
	var one: PackedInt64Array = PackedInt64Array([1])
	assert_true(NativeSim.probe_rules(99, one, one, one, one).is_empty(), "unknown op")
	assert_true(
		NativeSim.probe_rules(0, one, PackedInt64Array(), one, one).is_empty(), "sizes differ"
	)


func test_a_decision_with_mismatched_runs_holds_no_segments() -> void:
	var decision: NativeWallDecision = NativeWallDecision.new()
	decision.setup(null, 15, 2, 15, 12.0, PackedInt32Array([0, 1]), PackedInt32Array([1]))
	decision.begin_tick(0)
	decision.add_attacker(0, 20)
	decision.end_tick()
	assert_eq(decision.ttd_of(0), SimClock.MAX_TICKS, "no segment 0")
	assert_eq(decision.evaluated_count(), 0, "nothing evaluated")
	assert_eq(decision.hysteresis_ticks(), 15, "the numbers are kept")
	assert_almost_eq(decision.notice_range(), 12.0, 0.0001, "the notice range is kept")


func test_a_decision_without_walls_reads_zero_health_and_unknown_segments_are_never() -> void:
	var decision: NativeWallDecision = NativeWallDecision.new()
	decision.setup(null, 1, 1, 0, 0.0, PackedInt32Array([0, 0, 0]), PackedInt32Array([2, 2, 2]))
	decision.begin_tick(4)
	decision.add_attacker(1, 20)
	decision.add_attacker(-1, 20)
	decision.add_attacker(3, 20)
	decision.add_attacker(1, 0)
	decision.end_tick()
	assert_eq(decision.evaluated_count(), 3, "span one from the middle reaches all three")
	assert_eq(decision.ttd_of(1), 0, "no wall mirror: health reads 0, gone at once")
	assert_eq(decision.ttd_of(-1), SimClock.MAX_TICKS, "unknown")
	assert_eq(decision.ttd_of(3), SimClock.MAX_TICKS, "unknown")
	assert_eq(decision.ttd_of(1 << 40), SimClock.MAX_TICKS, "far outside")


func test_the_wall_mirror_reports_health_and_zero_outside_the_segments() -> void:
	var map: MapConfig = load(Pins.RING_MAP)
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var walls: WallSystem = WallSystem.new(map, buildings, events)
	buildings.apply_next_tier(&"wall_ring")
	walls.damage_segment(3, 10)
	walls.damage_segment(4, 100000)
	for segment: int in range(walls.segment_count()):
		assert_eq(walls.native().health_of(segment), walls.health_of(segment), "seg %d" % segment)
	assert_eq(walls.native().health_of(-1), 0, "below")
	assert_eq(walls.native().health_of(walls.segment_count()), 0, "above")
	assert_eq(walls.native().health_of(1 << 40), 0, "far above")


func test_a_decision_through_the_facade_reads_the_live_wall_health() -> void:
	var map: MapConfig = load(Pins.RING_MAP)
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var walls: WallSystem = WallSystem.new(map, buildings, events)
	buildings.apply_next_tier(&"wall_ring")
	var decision: WallDecision = WallDecision.new(walls, load(Pins.TUNING_PATH))
	var due: int = 30
	while (due + 5) % 15 != 0:
		due += 1
	decision.begin_tick(due)
	decision.add_attacker(5, 20)
	decision.end_tick()
	var full: int = decision.ttd_of(5)
	walls.damage_segment(5, walls.health_of(5) / 2)
	decision.begin_tick(due + 15)
	decision.add_attacker(5, 20)
	decision.end_tick()
	assert_lt(decision.ttd_of(5), full, "half the health, a shorter time")
	assert_eq(decision.native().ttd_of(5), decision.ttd_of(5), "the facade reads the native state")


func test_unknown_ids_and_indices_answer_the_zero_vector_and_nothing_found() -> void:
	var built: Dictionary = Pins.build_world("proto")
	var native: NativeStructures = (built["index"] as StructureIndex).native()
	assert_eq(native.unit_position(-1), Vector2.ZERO, "negative id")
	assert_eq(native.unit_position(1 << 40), Vector2.ZERO, "huge id")
	assert_eq(native.unit_radius(999999), 0.0, "unknown radius")
	assert_false(native.has_unit(999999), "no such unit")
	assert_eq(native.building_centre(-1), Vector2.ZERO, "negative index")
	assert_eq(native.building_centre(1 << 40), Vector2.ZERO, "huge index")
	assert_eq(native.building_radius(1 << 40), 0.0, "huge radius")
	assert_false(native.is_standing(-1), "no such building")
	assert_false(native.is_standing(1 << 40), "none out there")
	var fresh: NativeStructures = NativeStructures.new()
	assert_eq(fresh.candidate_count(), 0, "nothing before the first rebuild")
	assert_eq(fresh.nearest(Vector2.ZERO, 100.0), Vector3i.ZERO, "nothing to find")
	assert_eq(fresh.nearest_through_walls(Vector2.ZERO, 100.0), Vector3i.ZERO, "nor through walls")
	assert_eq(
		fresh.nearest_visible(Vector2.ZERO, 100.0, null, 0.0, -1.0), Vector3i.ZERO, "nor seen"
	)


func test_the_snapshot_lookups_agree_with_the_systems_they_were_taken_from() -> void:
	var built: Dictionary = Pins.build_world("walled")
	var native: NativeStructures = (built["index"] as StructureIndex).native()
	var units: UnitSystem = built["units"]
	var buildings: BuildingSystem = built["buildings"]
	var living: int = 0
	for unit_id: int in units.ids():
		var alive: bool = units.is_alive(unit_id)
		assert_eq(native.has_unit(unit_id), alive, "unit %d is a candidate when alive" % unit_id)
		if alive:
			living += 1
			assert_eq(native.unit_position(unit_id), units.position_of(unit_id), "position")
			assert_eq(native.unit_radius(unit_id), units.def_of(unit_id).radius, "radius")
	var standing: Array[StringName] = buildings.standing_spot_ids()
	for spot_id: StringName in buildings.spot_ids():
		var index: int = buildings.spot_index(spot_id)
		assert_eq(native.is_standing(index), standing.has(spot_id), "standing %s" % spot_id)
		if standing.has(spot_id):
			var spot: BuildSpotDef = buildings.get_spot(spot_id)
			assert_eq(
				native.building_centre(index),
				Vector2(spot.position.x, spot.position.z),
				"centre of %s" % spot_id
			)
			assert_eq(native.building_radius(index), buildings.radius_of(spot_id), "radius")
	assert_eq(native.candidate_count(), living + standing.size() + 1, "units, buildings, castle")


func test_a_huge_or_odd_range_answers_as_a_scan_of_every_candidate() -> void:
	var built: Dictionary = Pins.build_world("walled")
	var index: StructureIndex = built["index"]
	var native: NativeStructures = index.native()
	var positions: PackedVector2Array = built["positions"]
	var mismatches: int = 0
	var found: int = 0
	for query: int in range(0, positions.size(), 10):
		var pos: Vector2 = positions[query]
		var expected: Vector3i = _brute_force(built, pos, 1000.0)
		if index.nearest(pos, 1000.0) != expected:
			mismatches += 1
		if expected.z == 1:
			found += 1
		assert_eq(index.nearest(pos, INF), index.nearest(pos, 1000.0), "an infinite range")
		assert_eq(native.nearest(pos, NAN), Vector3i.ZERO, "a NaN range finds nothing")
		assert_eq(native.nearest(pos, -1.0), Vector3i.ZERO, "a negative range finds nothing")
	assert_eq(mismatches, 0, "a range over the whole map is the scan of every candidate")
	assert_gt(found, 100, "and it finds something")
	assert_eq(native.nearest(Vector2(NAN, 0.0), 10.0), Vector3i.ZERO, "a NaN position")
	assert_eq(native.nearest(Vector2(INF, 0.0), 10.0), Vector3i.ZERO, "an infinite position")


## The shipped scan over a world dictionary of Pins.build_world, kept verbatim as the reference.
func _brute_force(built: Dictionary, pos: Vector2, aggro: float) -> Vector3i:
	var units: UnitSystem = built["units"]
	var buildings: BuildingSystem = built["buildings"]
	var castle: CastleState = built["castle"]
	var best_edge: float = INF
	var found: Vector3i = StructureIndex.NONE
	for unit_id: int in units.ids():
		if not units.is_alive(unit_id):
			continue
		var edge: float = pos.distance_to(units.position_of(unit_id)) - units.def_of(unit_id).radius
		if edge <= aggro and edge < best_edge:
			best_edge = edge
			found = Vector3i(StructureIndex.KIND_UNIT, unit_id, 1)
	for spot_id: StringName in buildings.standing_spot_ids():
		var spot: BuildSpotDef = buildings.get_spot(spot_id)
		var centre: Vector2 = Vector2(spot.position.x, spot.position.z)
		var edge: float = pos.distance_to(centre) - buildings.radius_of(spot_id)
		if edge <= aggro and edge < best_edge:
			best_edge = edge
			found = Vector3i(StructureIndex.KIND_BUILDING, buildings.spot_index(spot_id), 1)
	var castle_edge: float = pos.distance_to(castle.get_position()) - castle.get_radius()
	if castle_edge <= aggro and castle_edge < best_edge:
		found = Vector3i(StructureIndex.KIND_CASTLE, 0, 1)
	return found


func test_mismatched_snapshot_arrays_leave_only_the_castle() -> void:
	var native: NativeStructures = NativeStructures.new()
	native.rebuild(
		PackedInt64Array([1, 2]),
		PackedVector2Array([Vector2(1.0, 1.0)]),
		PackedFloat64Array([0.5, 0.5]),
		PackedInt32Array([3]),
		PackedVector2Array([Vector2(2.0, 2.0)]),
		PackedFloat64Array([1.0, 1.0]),
		Vector2(10.0, 10.0),
		4.0
	)
	assert_eq(native.candidate_count(), 1, "both groups refused, the castle stays")
	assert_eq(native.nearest(Vector2(10.0, 10.0), 5.0), Vector3i(2, 0, 1), "the castle")
	assert_false(native.has_unit(1), "no unit kept")
	assert_false(native.is_standing(3), "no building kept")


func test_an_unsorted_snapshot_still_finds_ids_and_keeps_the_given_order() -> void:
	var native: NativeStructures = NativeStructures.new()
	native.rebuild(
		PackedInt64Array([7, 3]),
		PackedVector2Array([Vector2(1.0, 0.0), Vector2(-1.0, 0.0)]),
		PackedFloat64Array([0.5, 0.5]),
		PackedInt32Array([5, 2]),
		PackedVector2Array([Vector2(0.0, 3.0), Vector2(0.0, -3.0)]),
		PackedFloat64Array([1.0, 1.0]),
		Vector2(50.0, 50.0),
		4.0
	)
	assert_eq(native.unit_position(3), Vector2(-1.0, 0.0), "id 3 found out of order")
	assert_eq(native.unit_position(7), Vector2(1.0, 0.0), "id 7")
	assert_eq(native.building_centre(2), Vector2(0.0, -3.0), "spot 2 found out of order")
	assert_true(native.is_standing(5), "spot 5")
	assert_eq(
		native.nearest(Vector2.ZERO, 5.0), Vector3i(0, 7, 1), "a tie goes to the earlier candidate"
	)
