extends GutTest
## PLAT-01 (plan 04-18, exact_port_rules 7): the flow-field reads and the castle routing pinned on
## the GDScript that shipped before any native field code existed. Four worlds (the prototype map
## with all four wall runs bought at tier I, the stress map's gate wall, the sealed ring fixture and
## the gap fixture) each go through three states: all segments intact, a seeded handful broken
## through damage_segment and the grid and fields rebuilt, and a stale state (the lazy direction
## cache primed on half the points, more segments broken, the grid rebuilt WITHOUT rebuilding the
## fields, then every point read: a direction is computed from the live blocked mask the first time
## a cell is asked and kept until the field is rebuilt). In each state 2,000 seeded points (inside
## blocked bands, on the border, on cell edges and far outside the grid) are read through
## FlowField.cost_at, is_reached and direction_at of the castle field and of three goal fields from
## a GoalFieldCache, through Pathing.walk_step, and through Pathing's is_sealed, castle_cost_at,
## castle_distance_cm, detour_ticks and straight_ticks (speeds 300 and 320 cm/s) and march_step
## (reaches 0.0, 0.107 and 1.0). The sha256 of each packed result is compared with a pinned hex
## string.
## The pins were computed on the GDScript implementation and are never edited: the native field
## and route must reproduce them unchanged.

const BASE_SEED: int = 41800
const POINTS: int = 2000
const BREAK_DAMAGE: int = 1000000
const HANDFUL: int = 4
const FAR_METRES: float = 300.0
const GOAL_RADII: Array[float] = [1.0, 0.5, 2.0]
const SPEEDS: Array[int] = [300, 320]
const REACHES: Array[float] = [0.0, 0.107, 1.0]
const WALK_RADIUS: float = 0.4
const WALK_REACH: float = 0.5
const WORLDS: Array[String] = ["prototype", "stress", "ring", "gap"]
const STATES: Array[String] = ["intact", "broken", "stale"]
const KINDS: Array[String] = ["castle", "goals", "route"]
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const STRESS_MAP := "res://tools/stress/stress_map.tres"
const RING_MAP := "res://tests/fixtures/fixture_map_walls.tres"
const GAP_MAP := "res://tests/fixtures/fixture_map_walls_gap.tres"
const PINS: Dictionary = {
	"prototype_intact_castle": "e4f738b6c7143ca39eea6b0230f486886036d03a9044a49c513ae85bdb9e9f60",
	"prototype_intact_goals": "c82a545266108c02536fde62b0393c288b4d4102b4b6932b7f4c28afd8ef72fe",
	"prototype_intact_route": "b09ccac8bdc6c646860b116eb1bdc73782fbdc4d54ce39f617a31529d8b853c1",
	"prototype_broken_castle": "9825d44b6c5f79544a0ddaa95e91bb99cf2ed8b0ddcb1a327cc9539916e26be6",
	"prototype_broken_goals": "f06ad1d49046dd0cb32417c17df747f08a6c05c859f2529bf6be8acff5398e7c",
	"prototype_broken_route": "9a7d0c4a83cd1770a875b953bdf2d8cd4f201abce2258a87db548cf30b88198e",
	"prototype_stale_castle": "ccfb0c0fee121520b67f03c7080b47cf2d3b40a43a17f526ce8ffb551711c7e6",
	"prototype_stale_goals": "3d463bae9f3a19acd1c55411c84733f59b4a70207811c1d8f3ef080f97b77efe",
	"prototype_stale_route": "fbc5fc0411d6926132411689d2ba730ab7ef1126ac8dedfc18b2e3cb41560c59",
	"stress_intact_castle": "fec2408e705a5d9d140c32d960abddc06e4897727168befcfca8251a89931535",
	"stress_intact_goals": "84a96beb31604623cbf6bb8332d6307f3c5b83941e1c001322e82bc96e59c925",
	"stress_intact_route": "c9191a0d6d893c723f2a060cc70e6c238ac95c279c62ddc7bc552e83dfc8ce47",
	"stress_broken_castle": "cf38f49f89784a31fe2d3c4fd9543b6a4c88c90aadae0e607a8f0af31e81b347",
	"stress_broken_goals": "923d4da9b0ce8ce2cc38860cc66295af8769dea74b22843bf7defc9ed2dc59eb",
	"stress_broken_route": "5bacd651c86800d1fa90430200fe6e03e314d60254f1539940733d8c7b8a5aa5",
	"stress_stale_castle": "43b63abfaf87f6b3072ed883919ae46a3389c1ba3d01c8a2452231280cf4f592",
	"stress_stale_goals": "57880fdbed419e7d9a528c2b576ce0310cd145c1cb076c80c088a65e938ce88f",
	"stress_stale_route": "768fcf09b5413ef56b2ae1b5f9d618f5ff107a89088cb75f1364b79f7306ae83",
	"ring_intact_castle": "aedc4cfa85777b529cebaa911eb650848c8180136f971e0bcecf0ea7281439e5",
	"ring_intact_goals": "8d4c4be8ff253c9c7d18edd9ad3c0b60e4b9c15af585a87b87b1c0b4893bc110",
	"ring_intact_route": "11d122b65b169bc0ff0018c072e69c3cf600b2395a6c23e8cad454e676969080",
	"ring_broken_castle": "65eea7ec3a66c456139a2669757e783a42053e6acf6f067fc855af2997eaa515",
	"ring_broken_goals": "1807fce992f79cce08ec85857356c7816f8514411faffad8a42fc1670471a756",
	"ring_broken_route": "5130060de903e242e2204e2cbfb746a230b8d629bfe54c1fbce1c7aa5977b049",
	"ring_stale_castle": "70f7522aaa934fc2d01ed2bbfc6958ef3361fc88f169cceff7fa105c9e993eed",
	"ring_stale_goals": "b74de1576d0145618586d07711a964a973bf79eb23e65aaca8a6452303b79e66",
	"ring_stale_route": "f7c9c022907e4548a9450c888079c3c84654bb1bc230d606673c62130879f5ed",
	"gap_intact_castle": "38de23723d3cdba45639740aab4fbc35efe097961733140f57dad16734f11824",
	"gap_intact_goals": "facb158cbd2af8ce85b67637bdc3ad89b67ba85b8e0d7e42568cab9adde748b5",
	"gap_intact_route": "2957e3c4242d8cdabb50e3754e67868e6c2f20ff41ce7399057a9114ac35c2cc",
	"gap_broken_castle": "c34e5bfeb81a2ec1aa924ca2c4cdd7a223876db0ee3b468dd8f7329d4ba89eaf",
	"gap_broken_goals": "ff073a24efb6f9cf457423422ae45d2e4d94f21b189f54a082bcb8d7e92bf312",
	"gap_broken_route": "8efec8ee2b60bb5f37a34b98f6fd715cb9147d37d96bb8fe5b661a142acff9f2",
	"gap_stale_castle": "f288a22029e20b46f62b2a14812c9e9ee227830620ca33338fccafb496349de7",
	"gap_stale_goals": "5e6e5d97802cf98169f9b59d9d08c95a4e74f0ca7938e7ed8cace143cc42283c",
	"gap_stale_route": "bc4d079a8cc9e19557cb211b38c90ae511b965c934d097a0465981ba4cc2277e",
}


## The world named `world` with every wall run bought at tier I: {map, walls, pathing}.
static func build_world(world: String) -> Dictionary:
	var path: String = RING_MAP
	var plots: Array[StringName] = [&"wall_ring"]
	match world:
		"prototype":
			path = PROTOTYPE_MAP
			plots = [&"wall_west", &"wall_east", &"wall_north", &"wall_ring"]
		"stress":
			path = STRESS_MAP
			plots = [&"gate_wall"]
		"gap":
			path = GAP_MAP
			plots = [&"wall_west"]
	var map: MapConfig = load(path)
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var walls: WallSystem = WallSystem.new(map, buildings, events)
	for plot: StringName in plots:
		buildings.apply_next_tier(plot)
	var pathing: Pathing = Pathing.new(map, walls)
	pathing.refresh()
	return {"map": map, "walls": walls, "pathing": pathing}


## The sha256 of `bytes`, as lowercase hex.
static func digest_of(bytes: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():
		context.update(bytes)
	return context.finish().hex_encode()


static func pin_key(world: String, state: String, kind: String) -> String:
	return "%s_%s_%s" % [world, state, kind]


## Every pin of one world, "world_state_kind" to digest, in a fixed order.
static func world_digests(world: String) -> Dictionary:
	var digests: Dictionary = {}
	var world_index: int = WORLDS.find(world)
	var built: Dictionary = build_world(world)
	var pathing: Pathing = built["pathing"]
	var walls: WallSystem = built["walls"]
	var points: PackedVector2Array = _points_of(walls, pathing, world_index)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + world_index * 100 + 7
	var goals: Array[Vector2] = _goals_of(built["map"], walls)
	var cache: GoalFieldCache = pathing.new_goal_cache()
	var walk_cache: GoalFieldCache = pathing.new_goal_cache()
	_record(digests, world, "intact", pathing, points, goals, [cache, walk_cache], 0)
	_break_some(walls, rng)
	pathing.refresh()
	_record(digests, world, "broken", pathing, points, goals, [cache, walk_cache], 100)
	var stale: Dictionary = _stale_digests(world, points)
	for kind: String in KINDS:
		digests[pin_key(world, "stale", kind)] = stale[kind]
	return digests


## Every pin of every world.
static func all_digests() -> Dictionary:
	var digests: Dictionary = {}
	for world: String in WORLDS:
		digests.merge(world_digests(world))
	return digests


func _check_world(world: String) -> void:
	var digests: Dictionary = world_digests(world)
	for state: String in STATES:
		for kind: String in KINDS:
			var key: String = pin_key(world, state, kind)
			assert_eq(digests[key], PINS.get(key, ""), key)


func test_the_prototype_map_answers_as_pinned() -> void:
	_check_world("prototype")


func test_the_stress_gate_wall_answers_as_pinned() -> void:
	_check_world("stress")


func test_the_sealed_ring_answers_as_pinned() -> void:
	_check_world("ring")


func test_the_gap_fixture_answers_as_pinned() -> void:
	_check_world("gap")


func test_every_pin_is_present_and_distinct_per_kind() -> void:
	assert_eq(PINS.size(), WORLDS.size() * STATES.size() * KINDS.size(), "one pin per case")
	for world: String in WORLDS:
		var seen: Dictionary = {}
		for kind: String in KINDS:
			var key: String = pin_key(world, "intact", kind)
			assert_false(seen.has(PINS.get(key, "")), "%s differs from the other kinds" % key)
			seen[PINS.get(key, "")] = true


func test_the_worlds_have_the_shapes_the_pins_assume() -> void:
	for world: String in WORLDS:
		var built: Dictionary = build_world(world)
		var walls: WallSystem = built["walls"]
		var pathing: Pathing = built["pathing"]
		assert_eq(walls.intact_count(), walls.segment_count(), "%s: all bought" % world)
		assert_true(pathing.grid().is_ready(), "%s: the grid is built" % world)
		assert_not_null(pathing.castle_field(), "%s: the castle field exists" % world)
		assert_gt(pathing.castle_field().reached_count(), 100, "%s: the field reaches" % world)
	var ring: Dictionary = build_world("ring")
	var ring_walls: WallSystem = ring["walls"]
	assert_eq(ring_walls.segment_count(), 32, "the sealed ring is 32 segments")


func test_the_points_reach_open_blocked_border_and_outside_cells() -> void:
	for world: String in WORLDS:
		var built: Dictionary = build_world(world)
		var pathing: Pathing = built["pathing"]
		var grid: NavGrid = pathing.grid()
		var counts: Dictionary = {"open": 0, "blocked": 0, "border": 0, "outside": 0}
		for pos: Vector2 in _points_of(built["walls"], pathing, WORLDS.find(world)):
			var cell: int = grid.cell_of(pos)
			if cell < 0:
				counts["outside"] += 1
			elif grid.is_border(cell):
				counts["border"] += 1
			elif grid.is_blocked(cell):
				counts["blocked"] += 1
			else:
				counts["open"] += 1
		for kind: String in counts:
			assert_gt(counts[kind], 50, "%s: many points are %s" % [world, kind])


func test_the_reads_cover_costs_directions_and_sealed_enemies() -> void:
	for world: String in WORLDS:
		var built: Dictionary = build_world(world)
		var pathing: Pathing = built["pathing"]
		var field: FlowField = pathing.castle_field()
		var reached: int = 0
		var unreached: int = 0
		var steered: int = 0
		var sealed: int = 0
		for pos: Vector2 in _points_of(built["walls"], pathing, WORLDS.find(world)):
			if field.is_reached(pos):
				reached += 1
			else:
				unreached += 1
			if field.direction_at(pos) != Vector2.ZERO:
				steered += 1
			if pathing.route().is_sealed(pos):
				sealed += 1
		assert_gt(reached, 100, "%s: many points are reached" % world)
		assert_gt(unreached, 100, "%s: and many are not" % world)
		assert_gt(steered, 100, "%s: many have a direction" % world)
		assert_lt(steered, POINTS - 100, "%s: and many have none" % world)
		if world == "ring":
			assert_gt(sealed, 100, "the sealed ring seals the enemies outside it")
	var ring: Dictionary = build_world("ring")
	var ring_pathing: Pathing = ring["pathing"]
	var ring_walls: WallSystem = ring["walls"]
	var points: PackedVector2Array = _points_of(ring_walls, ring_pathing, WORLDS.find("ring"))
	var sealed_before: int = _count_sealed(ring_pathing, points)
	_break_some(ring_walls, RandomNumberGenerator.new())
	ring_pathing.refresh()
	assert_lt(_count_sealed(ring_pathing, points), sealed_before, "breaking the ring unseals it")


func test_a_stale_field_reads_the_live_grid_the_first_time_a_cell_is_asked() -> void:
	var built: Dictionary = build_world("gap")
	var pathing: Pathing = built["pathing"]
	var walls: WallSystem = built["walls"]
	var field: FlowField = pathing.castle_field()
	var points: PackedVector2Array = _points_of(walls, pathing, WORLDS.find("gap"))
	var before: PackedVector2Array = PackedVector2Array()
	for index: int in range(0, points.size(), 2):
		before.append(field.direction_at(points[index]))
	for segment: int in range(walls.segment_count()):
		walls.damage_segment(segment, BREAK_DAMAGE)
	pathing.grid().rebuild(walls)
	var kept: int = 0
	var changed: int = 0
	for index: int in range(0, points.size(), 2):
		if field.direction_at(points[index]) == before[index / 2]:
			kept += 1
	for index: int in range(1, points.size(), 2):
		if field.direction_at(points[index]) != Vector2.ZERO:
			changed += 1
	assert_eq(kept, before.size(), "a cell asked before the rebuild keeps its cached direction")
	assert_gt(changed, 0, "a cell asked for the first time reads the live grid")


func _count_sealed(pathing: Pathing, points: PackedVector2Array) -> int:
	var sealed: int = 0
	for pos: Vector2 in points:
		if pathing.route().is_sealed(pos):
			sealed += 1
	return sealed


## Breaks HANDFUL seeded segments through damage_segment.
static func _break_some(walls: WallSystem, rng: RandomNumberGenerator) -> void:
	for _attempt: int in range(HANDFUL):
		walls.damage_segment(rng.randi_range(0, walls.segment_count() - 1), BREAK_DAMAGE)


## Three goals: a spawn point (else a point near the castle) and a point 3 m to either side of the
## first segment's middle.
static func _goals_of(map: MapConfig, walls: WallSystem) -> Array[Vector2]:
	var goals: Array[Vector2] = []
	if not map.spawn_points.is_empty():
		var spawn: SpawnPointDef = map.spawn_points[0]
		goals.append(Vector2(spawn.position.x, spawn.position.z))
	else:
		goals.append(Vector2(map.castle_position.x + 14.0, map.castle_position.z + 6.0))
	var middle: Vector2 = (walls.segment_start(0) + walls.segment_end(0)) * 0.5
	goals.append(middle + Vector2(0.0, 3.0))
	goals.append(middle + Vector2(0.0, -3.0))
	return goals


## POINTS seeded points: in the grid and around it, near segments (inside blocked bands), on the
## border ring, on cell edges and centres, and far outside the grid.
static func _points_of(walls: WallSystem, pathing: Pathing, world_index: int) -> PackedVector2Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + world_index * 100
	var grid: NavGrid = pathing.grid()
	var size: float = grid.cell_size()
	var low: Vector2 = grid.origin()
	var extent: Vector2 = Vector2(float(grid.width()) * size, float(grid.height()) * size)
	var out: PackedVector2Array = PackedVector2Array()
	for index: int in range(POINTS):
		var pos: Vector2 = Vector2.ZERO
		match index % 10:
			0, 1, 2, 3:
				pos = Vector2(
					rng.randf_range(low.x - 12.0, low.x + extent.x + 12.0),
					rng.randf_range(low.y - 12.0, low.y + extent.y + 12.0)
				)
			4, 5, 6:
				var segment: int = rng.randi_range(0, walls.segment_count() - 1)
				var start: Vector2 = walls.segment_start(segment)
				var end: Vector2 = walls.segment_end(segment)
				pos = start + (end - start) * rng.randf()
				pos += Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5))
			7:
				var ring_x: int = rng.randi_range(0, grid.width() - 1)
				var ring_y: int = rng.randi_range(0, grid.height() - 1)
				if index % 4 == 3:
					ring_x = 0 if index % 8 == 3 else grid.width() - 1
				else:
					ring_y = 0 if index % 8 == 7 else grid.height() - 1
				pos = low + Vector2((float(ring_x) + 0.5) * size, (float(ring_y) + 0.5) * size)
				pos += Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2))
			8:
				var edge: float = 0.0 if index % 20 == 8 else 0.5
				pos = (
					low
					+ Vector2(
						(float(rng.randi_range(0, grid.width())) + edge) * size,
						(float(rng.randi_range(0, grid.height())) + edge) * size
					)
				)
			_:
				pos = Vector2(
					rng.randf_range(-FAR_METRES, FAR_METRES),
					rng.randf_range(-FAR_METRES, FAR_METRES)
				)
		out.append(pos)
	return out


## Records the three kinds of one state; `caches` is [the goal-field cache, the walk cache] and
## `tick` is where the goal-field ticks start.
static func _record(
	digests: Dictionary,
	world: String,
	state: String,
	pathing: Pathing,
	points: PackedVector2Array,
	goals: Array[Vector2],
	caches: Array,
	tick: int
) -> void:
	var cache: GoalFieldCache = caches[0]
	var walk_cache: GoalFieldCache = caches[1]
	digests[pin_key(world, state, "castle")] = digest_of(
		_field_bytes(pathing.castle_field(), points)
	)
	var bytes: PackedByteArray = PackedByteArray()
	for index: int in range(goals.size()):
		var field: FlowField = cache.field_for(goals[index], GOAL_RADII[index], tick + index * 20)
		bytes.append_array(_field_bytes(field, points))
	bytes.append_array(_walk_bytes(pathing, walk_cache, points, goals, tick).to_byte_array())
	digests[pin_key(world, state, "goals")] = digest_of(bytes)
	digests[pin_key(world, state, "route")] = digest_of(_route_bytes(pathing, points))


## The stale state of one world: {kind: digest}.
static func _stale_digests(world: String, points: PackedVector2Array) -> Dictionary:
	var world_index: int = WORLDS.find(world)
	var built: Dictionary = build_world(world)
	var pathing: Pathing = built["pathing"]
	var walls: WallSystem = built["walls"]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + world_index * 100 + 13
	var goals: Array[Vector2] = _goals_of(built["map"], walls)
	var cache: GoalFieldCache = pathing.new_goal_cache()
	_break_some(walls, rng)
	pathing.refresh()
	var fields: Array[FlowField] = [pathing.castle_field()]
	for index: int in range(goals.size()):
		fields.append(cache.field_for(goals[index], GOAL_RADII[index], index * 20))
	for field: FlowField in fields:
		for index: int in range(0, points.size(), 2):
			field.direction_at(points[index])
	_break_some(walls, rng)
	pathing.grid().rebuild(walls)
	var goal_bytes: PackedByteArray = PackedByteArray()
	for index: int in range(1, fields.size()):
		goal_bytes.append_array(_field_bytes(fields[index], points))
	return {
		"castle": digest_of(_field_bytes(fields[0], points)),
		"goals": digest_of(goal_bytes),
		"route": digest_of(_route_bytes(pathing, points)),
	}


## Cost, reached flag and direction of `field` at every point, as bytes.
static func _field_bytes(field: FlowField, points: PackedVector2Array) -> PackedByteArray:
	var costs: PackedInt32Array = PackedInt32Array()
	var reached: PackedByteArray = PackedByteArray()
	var directions: PackedVector2Array = PackedVector2Array()
	for pos: Vector2 in points:
		costs.append(field.cost_at(pos))
		reached.append(1 if field.is_reached(pos) else 0)
		directions.append(field.direction_at(pos))
	return costs.to_byte_array() + reached + directions.to_byte_array()


## Pathing.walk_step of every point toward the goals in turn, with its own cache; the tick advances
## every 25 points so the cache's build budget is spent and refilled.
static func _walk_bytes(
	pathing: Pathing,
	walk_cache: GoalFieldCache,
	points: PackedVector2Array,
	goals: Array[Vector2],
	tick: int
) -> PackedVector2Array:
	var steps: PackedVector2Array = PackedVector2Array()
	for index: int in range(points.size()):
		var goal: Vector2 = goals[index % goals.size()]
		var at_tick: int = tick + 1000 + index / 25
		steps.append(
			pathing.walk_step(
				points[index], goal, WALK_REACH, WALK_RADIUS, 1.0, at_tick, walk_cache
			)
		)
	return steps


## Pathing's castle routing at every point: sealed flag, castle cost, straight distance in
## centimetres, detour and straight ticks at both speeds, then the march steps at three reaches.
static func _route_bytes(pathing: Pathing, points: PackedVector2Array) -> PackedByteArray:
	var numbers: PackedInt64Array = PackedInt64Array()
	var steps: PackedVector2Array = PackedVector2Array()
	for pos: Vector2 in points:
		numbers.append(1 if pathing.route().is_sealed(pos) else 0)
		numbers.append(pathing.route().castle_cost_at(pos))
		numbers.append(pathing.route().castle_distance_cm(pos))
		for speed: int in SPEEDS:
			numbers.append(pathing.route().detour_ticks(pos, speed))
			numbers.append(pathing.route().straight_ticks(pos, speed))
		for reach: float in REACHES:
			steps.append(pathing.route().march_step(pos, reach))
	return numbers.to_byte_array() + steps.to_byte_array()
