extends GutTest
## PLAT-01 (plan 04-23, exact_port_rules 7): the structure index and the wall decision pinned on the
## GDScript that shipped before any native structure or decision code existed.
##
## Structure part: three seeded worlds (the prototype map with no wall bought, the prototype map
## with its four wall runs bought, some units dead, a building fallen and a few segments broken, and
## a world of integer positions full of exact ties) are put through 2,000 queries each of nearest,
## nearest_visible (radius 0.0 and 0.5, ranged reach -1 and 7) and nearest_through_walls. The
## answers, Vector3i(kind, id, found), are packed in query order and pinned as sha256.
##
## Decision part: the prototype map's wall runs (shipped tuning, then a tuning with a cadence of one
## tick and a span of four) and the sealed ring fixture, with seeded segment health, go through 300
## ticks of begin_tick, seeded add_attacker calls and end_tick, and the published times to
## destruction of every segment plus evaluated_count after every tick are pinned. The five static
## integer rules are pinned over a grid of inputs (see the VALUES constants, read by
## test_native_structures to prove the native twins equal on the same grid).
##
## The pins were computed on the GDScript implementation and are never edited: the native structure
## index and decision state must reproduce them unchanged.

const BASE_SEED: int = 42300
const QUERIES: int = 2000
const AGGROS: Array[float] = [6.0, 10.0, 22.0]
const RADII: Array[float] = [0.0, 0.5]
const REACHES: Array[float] = [-1.0, 7.0]
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const RING_MAP := "res://tests/fixtures/fixture_map_walls.tres"
const TUNING_PATH := "res://data/tuning/nav_tuning.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const HOUSE_PATH := "res://data/buildings/house.tres"
const WALL_PLOTS: Array[StringName] = [&"wall_west", &"wall_east", &"wall_north", &"wall_ring"]
const UNIT_COUNT: int = 60
const SPREAD: float = 70.0
const TIE_UNITS: int = 40
const TIE_SPREAD: int = 12
const DECISION_TICKS: int = 300
const FIRST_TICK: int = 7
const BREAK_DAMAGE: int = 1000000
const PINS: Dictionary = {
	"proto_nearest": "080cca05ca43b65eff85724edc40c52a9f65277e56c5c39c63d9fc37f7981339",
	"proto_visible": "d7fcf23122c112e3a06cb1b530838b738ba910078be0c216ce8319689d55ebfc",
	"proto_through": "d347dbc8d7acb18156fa931ebd9a0889eb48b0e1c78fde5aad82269ab9decdbd",
	"walled_nearest": "b4471a0c5a418afdc227f3e9b8e293478f7fbdebb3edf1423569e42f5fb54115",
	"walled_visible": "1a075ca6b7a3a6aa3bee3cfda85b7da794222cadae1865c8162e793581088368",
	"walled_through": "e9864640592eeeb2ffbcb676823af6e86970498f29ffdc9b0e793a0179ef0e95",
	"ties_nearest": "29eeb0e6187bb6e78c3687a5d9b1ba520b8aace0bc262acdb05a12924f5c6f97",
	"ties_visible": "77b690541586657e2170a698e8da45bc4285e8f28b3b91707db3005114bfa219",
	"ties_through": "ee1b9572ac2db3d2f72073754c33ce7738df3f01a569aecd185cfa741981a300",
	"decision_prototype": "9fb1a92bc324cbed8d4dcf78aa33aa90d1edbbf014735bd2b7fe90037930f0e8",
	"decision_fast": "3a6ae0c2f37cbdf349875c6404f5f9e176b0e98c69ad1132028916742982ee8d",
	"decision_ring": "f3289cc79454fc3124853b2b95143ee88df43a504e72f9dc4b65d5da29ea789c",
	"rules": "d5b455acb877e67d4f8340c5165e4083341b7b5878659c2bbe2650a0e753c098",
}

# The input grids of the five static rules. Health 0 to 120 by 7 and sums 0 to 900 by 11 as the
# plan asks, plus negative, one, huge and overflowing values.
const DAMAGES: Array[int] = [-3, 0, 1, 2, 5, 17, 100, 1 << 40, 1 << 62]
const INTERVALS: Array[int] = [-2, 0, 1, 7, 30, 48, 299, 300, 301, 1 << 20]
const DISTANCES: Array[int] = [-50, 0, 1, 29, 30, 31, 59, 60, 2000, 2001, 99999, 1 << 40, 1 << 61]
const SPEEDS: Array[int] = [-3, 0, 1, 29, 30, 300, 320, 1000, 1 << 20]
const TTDS: Array[int] = [0, 1, 50, 100, SimClock.MAX_TICKS - 1, SimClock.MAX_TICKS]
const STRAIGHTS: Array[int] = [0, 40, 50, SimClock.MAX_TICKS]
const DETOURS: Array[int] = [
	0, 1, 89, 90, 91, 100, 101, 150, 151, SimClock.MAX_TICKS - 1, SimClock.MAX_TICKS
]
const HYSTERESES: Array[int] = [0, 15, 30, SimClock.MAX_TICKS]


## Health 0 to 120 by 7, then values outside the small grid.
static func healths() -> Array[int]:
	var values: Array[int] = []
	for health: int in range(0, 121, 7):
		values.append(health)
	values.append_array([-5, 1000000, 1 << 40, 1 << 60])
	return values


## Summed damage 0 to 900 by 11, then values outside the small grid.
static func sums() -> Array[int]:
	var values: Array[int] = []
	for total: int in range(0, 901, 11):
		values.append(total)
	values.append_array([-7, 1, 899, 1000, 20000, 1 << 40])
	return values


## The five static rules over every grid, in a fixed order, as one packed result.
static func rule_results() -> PackedInt64Array:
	var out: PackedInt64Array = PackedInt64Array()
	for damage: int in DAMAGES:
		for interval: int in INTERVALS:
			out.append(WallDecision.damage_per_300(damage, interval))
	for health: int in healths():
		for total: int in sums():
			out.append(WallDecision.ttd_ticks(health, total))
	for distance: int in DISTANCES:
		for speed: int in SPEEDS:
			out.append(WallDecision.walk_ticks(distance, speed))
	for ttd: int in TTDS:
		for straight: int in STRAIGHTS:
			for detour: int in DETOURS:
				out.append(1 if WallDecision.should_break(ttd, straight, detour) else 0)
				for hysteresis: int in HYSTERESES:
					out.append(
						1 if WallDecision.keep_breaking(ttd, straight, detour, hysteresis) else 0
					)
	return out


## The sha256 of `bytes`, as lowercase hex.
static func digest_of(bytes: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():
		context.update(bytes)
	return context.finish().hex_encode()


## Everything a structure world needs: {index, positions, pathing, walls, castle, buildings, units}.
static func build_world(world: String) -> Dictionary:
	var events: SimEvents = SimEvents.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + ["proto", "walled", "ties"].find(world) * 100
	var map: MapConfig = _ties_map() if world == "ties" else load(PROTOTYPE_MAP)
	var castle: CastleState = CastleState.new(map, events)
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var walls: WallSystem = WallSystem.new(map, buildings, events)
	for spot_id: StringName in buildings.spot_ids():
		if world == "walled" or not WALL_PLOTS.has(spot_id):
			buildings.apply_next_tier(spot_id)
	var units: UnitSystem = UnitSystem.new(events)
	_spawn_units(world, units, rng)
	if world == "walled":
		_wound(units, buildings, walls, rng)
	var index: StructureIndex = StructureIndex.new()
	index.rebuild(units, buildings, castle)
	return {
		"index": index,
		"pathing": Pathing.new(map, walls),
		"walls": walls,
		"castle": castle,
		"buildings": buildings,
		"units": units,
		"positions": _query_positions(world, rng),
	}


## The packed answers of one world: {nearest, visible, through} to PackedByteArray.
static func world_bytes(world: String) -> Dictionary:
	var built: Dictionary = build_world(world)
	var index: StructureIndex = built["index"]
	var pathing: Pathing = built["pathing"]
	var positions: PackedVector2Array = built["positions"]
	var nearest: PackedInt32Array = PackedInt32Array()
	var visible: PackedInt32Array = PackedInt32Array()
	var through: PackedInt32Array = PackedInt32Array()
	for query: int in range(positions.size()):
		var pos: Vector2 = positions[query]
		var aggro: float = AGGROS[query % AGGROS.size()]
		_append(nearest, index.nearest(pos, aggro))
		_append(through, index.nearest_through_walls(pos, aggro))
		for radius: float in RADII:
			for reach: float in REACHES:
				_append(visible, index.nearest_visible(pos, aggro, pathing, radius, reach))
	return {
		"nearest": nearest.to_byte_array(),
		"visible": visible.to_byte_array(),
		"through": through.to_byte_array(),
	}


## The packed published times and evaluated counts of one decision scenario.
static func decision_bytes(scenario: String) -> PackedByteArray:
	var map: MapConfig = load(RING_MAP) if scenario == "ring" else load(PROTOTYPE_MAP)
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var walls: WallSystem = WallSystem.new(map, buildings, events)
	for spot_id: StringName in buildings.spot_ids():
		buildings.apply_next_tier(spot_id)
	var tuning: NavTuning = (load(TUNING_PATH) as NavTuning).duplicate()
	if scenario == "fast":
		tuning.wall_decision_seconds = 0.0
		tuning.wall_neighbour_span = 4
	if scenario == "ring":
		tuning.wall_neighbour_span = 1
	var decision: WallDecision = WallDecision.new(walls, tuning)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + 900 + ["prototype", "fast", "ring"].find(scenario)
	var count: int = walls.segment_count()
	for segment: int in range(count):
		walls.damage_segment(segment, rng.randi_range(0, walls.max_health_of(segment) - 1))
	var out: PackedInt32Array = PackedInt32Array()
	for step: int in range(DECISION_TICKS):
		if step % 10 == 3:
			var victim: int = rng.randi_range(0, count - 1)
			walls.damage_segment(victim, rng.randi_range(1, maxi(walls.health_of(victim), 1)))
		decision.begin_tick(FIRST_TICK + step)
		for _attacker: int in range(rng.randi_range(0, 40)):
			decision.add_attacker(rng.randi_range(-2, count + 1), rng.randi_range(-3, 60))
		decision.end_tick()
		for segment: int in range(-1, count + 1):
			out.append(decision.ttd_of(segment))
		out.append(decision.evaluated_count())
	return out.to_byte_array()


static func _append(into: PackedInt32Array, found: Vector3i) -> void:
	into.append(found.x)
	into.append(found.y)
	into.append(found.z)


## A map of house plots at integer positions, so edges tie exactly.
static func _ties_map() -> MapConfig:
	var map: MapConfig = MapConfig.new()
	map.buildings = [load(HOUSE_PATH)]
	var spots: Array[BuildSpotDef] = []
	var at: Array[Vector3] = [
		Vector3(4, 0, 0),
		Vector3(-4, 0, 0),
		Vector3(0, 0, 4),
		Vector3(0, 0, -4),
		Vector3(8, 0, 8),
		Vector3(-8, 0, 8),
		Vector3(8, 0, -8),
		Vector3(-8, 0, -8),
	]
	for index: int in range(at.size()):
		var spot: BuildSpotDef = BuildSpotDef.new()
		spot.id = StringName("plot_%d" % index)
		spot.position = at[index]
		spot.building_id = &"house"
		spots.append(spot)
	map.spots = spots
	return map


static func _spawn_units(world: String, units: UnitSystem, rng: RandomNumberGenerator) -> void:
	var footman: UnitDef = load(FOOTMAN_PATH)
	if world == "ties":
		var tied: UnitDef = footman.duplicate()
		tied.radius = 0.5
		for _unit: int in range(TIE_UNITS):
			var pos: Vector2 = Vector2(
				float(rng.randi_range(-TIE_SPREAD, TIE_SPREAD)),
				float(rng.randi_range(-TIE_SPREAD, TIE_SPREAD))
			)
			units.spawn(tied, &"squad", 0, pos)
		return
	for _unit: int in range(UNIT_COUNT):
		var pos: Vector2 = Vector2(
			rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD)
		)
		units.spawn(footman, &"squad", 0, pos)


## Kills every third unit, drops two buildings and breaks a few wall segments.
static func _wound(
	units: UnitSystem, buildings: BuildingSystem, walls: WallSystem, rng: RandomNumberGenerator
) -> void:
	for unit_id: int in units.ids():
		if unit_id % 3 == 0:
			units.damage(unit_id, 100000, &"enemy")
	buildings.damage_building(&"house_2", 100000)
	buildings.damage_building(&"tower_1", 100000)
	for _attempt: int in range(6):
		walls.damage_segment(rng.randi_range(0, walls.segment_count() - 1), BREAK_DAMAGE)


## QUERIES positions: uniform over the world, then a share exactly on the integer lattice.
static func _query_positions(world: String, rng: RandomNumberGenerator) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for query: int in range(QUERIES):
		if world == "ties":
			out.append(
				Vector2(
					float(rng.randi_range(-2 * TIE_SPREAD, 2 * TIE_SPREAD)) * 0.5,
					float(rng.randi_range(-2 * TIE_SPREAD, 2 * TIE_SPREAD)) * 0.5
				)
			)
		elif query % 5 == 0:
			out.append(Vector2(float(rng.randi_range(-70, 70)), float(rng.randi_range(-70, 70))))
		else:
			out.append(Vector2(rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD)))
	return out


func _check_world(world: String) -> void:
	var bytes: Dictionary = world_bytes(world)
	for kind: String in ["nearest", "visible", "through"]:
		var key: String = "%s_%s" % [world, kind]
		assert_eq(digest_of(bytes[kind]), PINS.get(key, ""), key)


func test_the_prototype_map_without_walls_answers_as_pinned() -> void:
	_check_world("proto")


func test_the_walled_world_with_the_dead_and_the_fallen_answers_as_pinned() -> void:
	_check_world("walled")


func test_the_world_of_integer_ties_answers_as_pinned() -> void:
	_check_world("ties")


func test_the_published_times_to_destruction_answer_as_pinned() -> void:
	assert_eq(digest_of(decision_bytes("prototype")), PINS.get("decision_prototype", ""), "shipped")
	assert_eq(digest_of(decision_bytes("fast")), PINS.get("decision_fast", ""), "cadence one")
	assert_eq(digest_of(decision_bytes("ring")), PINS.get("decision_ring", ""), "sealed ring")


func test_the_five_static_rules_answer_as_pinned_over_the_grid() -> void:
	assert_eq(digest_of(rule_results().to_byte_array()), PINS.get("rules", ""), "rules")


func test_every_pin_is_present_and_distinct() -> void:
	var seen: Dictionary = {}
	for key: String in PINS:
		var pin: String = PINS[key]
		assert_eq(pin.length(), 64, "%s is a sha256" % key)
		assert_false(seen.has(pin), "%s differs from the others" % key)
		seen[pin] = true
	assert_eq(PINS.size(), 13, "nine structure pins, three decisions and the rules")


func test_the_walled_world_really_hides_and_skips_candidates() -> void:
	var built: Dictionary = build_world("walled")
	var index: StructureIndex = built["index"]
	var pathing: Pathing = built["pathing"]
	var positions: PackedVector2Array = built["positions"]
	var seen_less: int = 0
	var through_not_castle: int = 0
	var found: int = 0
	for query: int in range(positions.size()):
		var aggro: float = AGGROS[query % AGGROS.size()]
		var plain: Vector3i = index.nearest(positions[query], aggro)
		var visible: Vector3i = index.nearest_visible(positions[query], aggro, pathing, 0.5, -1.0)
		var through: Vector3i = index.nearest_through_walls(positions[query], aggro)
		if plain.z == 1:
			found += 1
		if visible != plain:
			seen_less += 1
		if through != plain and plain.x == StructureIndex.KIND_CASTLE:
			through_not_castle += 1
	assert_gt(found, 500, "many queries find something")
	assert_gt(seen_less, 20, "walls change the visible answer for some queries")
	assert_gt(through_not_castle, 5, "the castle is never the answer through walls")


func test_the_tie_world_has_exact_ties_and_the_decision_scenarios_publish_times() -> void:
	var built: Dictionary = build_world("ties")
	var index: StructureIndex = built["index"]
	var units: UnitSystem = built["units"]
	var positions: PackedVector2Array = built["positions"]
	var unit_answers: int = 0
	var building_answers: int = 0
	for pos: Vector2 in positions:
		var answer: Vector3i = index.nearest(pos, 6.0)
		if answer.x == StructureIndex.KIND_UNIT:
			unit_answers += 1
		elif answer.x == StructureIndex.KIND_BUILDING:
			building_answers += 1
	assert_gt(unit_answers, 100, "units win many ties world queries")
	assert_gt(building_answers, 100, "and so do buildings")
	assert_eq(units.count(), TIE_UNITS, "the units are all there")
	var published: int = 0
	var times: PackedInt32Array = decision_bytes("prototype").to_int32_array()
	for value: int in times:
		if value > 0 and value < SimClock.MAX_TICKS:
			published += 1
	assert_gt(published, 100, "the decision scenario publishes real times")
