extends GutTest
## PLAT-01 (plan 04-17, exact_port_rules 7): the wall solid test pinned on the GDScript that shipped
## before any native wall code existed. Four worlds (the prototype map with all four wall runs
## bought at tier I, the stress map's gate wall, the sealed ring fixture and the gap fixture), each
## in three health patterns (all intact, every third segment broken, the first run broken, all
## through damage_segment), answer seeded queries: 2,000 each of WallSystem.segments_near,
## WallSolids.first_blocking (radii 0.0, 0.4, 0.5 and 0.6, castle lines included),
## WallSolids.push_out and WallSolids.closest_point (every segment against seeded points), plus the
## tangent case of
## review item WR-02: points that push_out just placed, line-tested along and away from the wall as
## the GDScript behaves today. The sha256 of each packed result is compared with a pinned hex
## string.
## The pins were computed on the GDScript implementation and are never edited: the native version of
## the wall solid test must reproduce them unchanged.
##
## Gap round G-05-2 (owner UAT decision 2026-10-25): every health and damage number is 100 times
## larger; this test's own amounts moved with them so it checks what it checked before. The pins
## were not edited: their inputs moved with the scale (or, for the wall decision, keep the Phase 4
## numbers the pins were computed on).

const BASE_SEED: int = 41700
const QUERIES: int = 2000
const BREAK_DAMAGE: int = 100000000
const BOUNDS_MARGIN: float = 10.0
const POINTS_PER_SEGMENT: int = 40
const CASTLE_LINES: int = 40
const RADII: Array[float] = [0.0, 0.4, 0.5, 0.6]
const BAD_REACHES: Array[float] = [INF, -INF, NAN, -1.0, -0.0001, -0.0]
const WORLDS: Array[String] = ["prototype", "stress", "ring", "gap"]
const PATTERNS: Array[String] = ["intact", "third", "first_run"]
const KINDS: Array[String] = ["near", "blocking", "push", "closest", "tangent"]
const PROTOTYPE_MAP := "res://data/maps/prototype_map.tres"
const STRESS_MAP := "res://tools/stress/stress_map.tres"
const RING_MAP := "res://tests/fixtures/fixture_map_walls.tres"
const GAP_MAP := "res://tests/fixtures/fixture_map_walls_gap.tres"
const PINS: Dictionary = {
	"prototype_intact_near": "5a90872716cb4470be34aaa4ef63fda529684b5841034022d3d851cff2379f0c",
	"prototype_intact_blocking": "402da96b6f4779950330257a416f89391866fd458252b3aed570e07ad54e6bac",
	"prototype_intact_push": "70766155708e9e3394e1351a9a58a511739a97c9324ab15c23849cfd28c6490b",
	"prototype_intact_closest": "3220a96595797409e7101bdf50ca48497c3adbfd38e327aa2da1110b88e0f080",
	"prototype_intact_tangent": "d7368763c09059010c083f1625daefa34e789ccbcd6538b7d8fc83a48be6539f",
	"prototype_third_near": "5a90872716cb4470be34aaa4ef63fda529684b5841034022d3d851cff2379f0c",
	"prototype_third_blocking": "6e1df388b87abed36a168a93e3f8042440f74db8bb55eb6cdd47b04ae3eae5ca",
	"prototype_third_push": "4e7aadcf9a068c14001cc215fa62de1075f5d8c5cf345263108dcea768d9f730",
	"prototype_third_closest": "3220a96595797409e7101bdf50ca48497c3adbfd38e327aa2da1110b88e0f080",
	"prototype_third_tangent": "b391c366d756f4d6a6978e7d32e42a14231928d559c87447b760a09c11b83156",
	"prototype_first_run_near": "5a90872716cb4470be34aaa4ef63fda529684b5841034022d3d851cff2379f0c",
	"prototype_first_run_blocking":
	"2bea506fc8c78abe81bacf6783c71d6b79895cf86a4871f63f7389985e111b45",
	"prototype_first_run_push": "1efa000d3d5b5c96e91d5f134e04521e71a5995f6fed591278194d8d5d7ea2b5",
	"prototype_first_run_closest":
	"3220a96595797409e7101bdf50ca48497c3adbfd38e327aa2da1110b88e0f080",
	"prototype_first_run_tangent":
	"d96788b7213b42343ae16f949643f97079e879dbcc001b4cfead9bc131526c52",
	"stress_intact_near": "5908392430e730f74d86757ab02a0877fe63b574283514edee4c151c2c342708",
	"stress_intact_blocking": "b7ce9f7c06a3bc1d3268a65c46270d3604b2fd39143be716a341c6392a29cecd",
	"stress_intact_push": "f8ecdc8977740ed07f1e6201396db9e65369bb7e526c7c7490926ecf983eb3c1",
	"stress_intact_closest": "4bafdb97a07a63813932832673eb4faa2b06d2f6cd8477fe43553f02cb8c781f",
	"stress_intact_tangent": "7890f8d1806264e938d97b1f13acfa834938b37a88ca289f64ddd3ebad0cd2cf",
	"stress_third_near": "5908392430e730f74d86757ab02a0877fe63b574283514edee4c151c2c342708",
	"stress_third_blocking": "367aa77bd244b1feedb1dd1dbf62357992287bb8cc5d8db0c1d511e230682c0b",
	"stress_third_push": "7f4ede58aaaa8ee5bd415fc8e381a5e51dc5c53b3bcd178d97a1827a6601a5cf",
	"stress_third_closest": "4bafdb97a07a63813932832673eb4faa2b06d2f6cd8477fe43553f02cb8c781f",
	"stress_third_tangent": "17d4d940d8f006244c3c53532316153d5310daa25cb60b82c782c29cacb051dc",
	"stress_first_run_near": "5908392430e730f74d86757ab02a0877fe63b574283514edee4c151c2c342708",
	"stress_first_run_blocking": "07109e9d35716a7cf5774f648d87ca5bf488401e4f9bb3fc918cd85b234aa86f",
	"stress_first_run_push": "b1f08967bd09dc66867bde184409287fade3d1f2519370b26fb2baf462fd4809",
	"stress_first_run_closest": "4bafdb97a07a63813932832673eb4faa2b06d2f6cd8477fe43553f02cb8c781f",
	"stress_first_run_tangent": "729b69eed7c2f81b24ab18425434ed7f8f0656a1e45ddfcab29987cbf14fa8c5",
	"ring_intact_near": "6d9136319c20995b9ad6b85094e4a1ccb7593f1e20db3c84abca24c0864c8e04",
	"ring_intact_blocking": "3d1bc93509e29362f3fa461fd38f4f3aa7744b3c6b5936385d323d142a28e63a",
	"ring_intact_push": "76e8790c9a7560b9225ebd645525399906e6c4fedf79cfbd655a48df4f759533",
	"ring_intact_closest": "d1f96e976c3bdb3df57a0f3a22af4b91526660a2c43e3b4b1d3523eb72770a2f",
	"ring_intact_tangent": "d91435aae20238dbbbb7ed0ab931b67e8d08278fb0f20abfd7bcdf03078302d6",
	"ring_third_near": "6d9136319c20995b9ad6b85094e4a1ccb7593f1e20db3c84abca24c0864c8e04",
	"ring_third_blocking": "bc6eb3cb20b8e247b98de6f23d133ae5853535b624c2c8f76042089cfc5f77cc",
	"ring_third_push": "6b1cf21790a98056283ed90ac07861ef32f842ed4948f2841bd511cf1d3d6bb7",
	"ring_third_closest": "d1f96e976c3bdb3df57a0f3a22af4b91526660a2c43e3b4b1d3523eb72770a2f",
	"ring_third_tangent": "37dbbb3349bceb0ad00915325da38b6bff03475032ff1f14fe25c0968ba20275",
	"ring_first_run_near": "6d9136319c20995b9ad6b85094e4a1ccb7593f1e20db3c84abca24c0864c8e04",
	"ring_first_run_blocking": "18dfdaa864cd41ba9233607f1f51a06d76aeb255d67f5abfcd19f2c533c814fd",
	"ring_first_run_push": "79b6569b308a1432a526b8f930c614307c169bb9efce62638879bc48ac61ba7c",
	"ring_first_run_closest": "d1f96e976c3bdb3df57a0f3a22af4b91526660a2c43e3b4b1d3523eb72770a2f",
	"ring_first_run_tangent": "ce48b09f9828caedc6d0e297b7d1df386538d4ed5903769a135807e0399e9ecb",
	"gap_intact_near": "bf3d3a441f965896d9e75577b6a851e4efa9733b6ddf72059efd917bbb03317c",
	"gap_intact_blocking": "5b28b2407c680f34f99bf34eef68c96dda90c0d91a6b7a7c8c0d95ab86658c52",
	"gap_intact_push": "02f47ece37e5548a061d0b63ca2322ff3d647a1b77d6f483521eeb738cc0f81b",
	"gap_intact_closest": "9354b49587d4e1c5405e3fc0653638a18eaf100ea3986cefddc1262e08cd5bb1",
	"gap_intact_tangent": "8f3eef2cf44c7cf729f2e5b4260e7628250b832e04c7e88769c1cabed97ae4ad",
	"gap_third_near": "bf3d3a441f965896d9e75577b6a851e4efa9733b6ddf72059efd917bbb03317c",
	"gap_third_blocking": "ea2175e379620b7c554816c01b54a3be516fd552b3d15241dce891e1d33c5192",
	"gap_third_push": "03c65353016a5eca6378c0a2f246e4b52bb448907d9fcaad6837f75edf2dc610",
	"gap_third_closest": "9354b49587d4e1c5405e3fc0653638a18eaf100ea3986cefddc1262e08cd5bb1",
	"gap_third_tangent": "6ff90731f8b3cb2cd67cef473d3dd0452cddf014c3c9a15d5f2da51e76ded911",
	"gap_first_run_near": "bf3d3a441f965896d9e75577b6a851e4efa9733b6ddf72059efd917bbb03317c",
	"gap_first_run_blocking": "18dfdaa864cd41ba9233607f1f51a06d76aeb255d67f5abfcd19f2c533c814fd",
	"gap_first_run_push": "4fe4d3b8a7bdd5dac750859a8b90a48d17fbe626451642d16abee4ec0efdeaaa",
	"gap_first_run_closest": "9354b49587d4e1c5405e3fc0653638a18eaf100ea3986cefddc1262e08cd5bb1",
	"gap_first_run_tangent": "ef4b32503483a377dc8dd6415dde06861ff3ece396ec08a767fdfd28ed8edeba",
}


## The world named `world` with every wall run bought at tier I: {map, events, buildings, walls}.
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
	return {"map": map, "events": events, "buildings": buildings, "walls": walls}


## Breaks segments through damage_segment: "intact" none, "third" every third one, "first_run" every
## segment of the first wall plot in map order.
static func apply_pattern(walls: WallSystem, pattern: String) -> void:
	if pattern == "third":
		for segment: int in range(walls.segment_count()):
			if segment % 3 == 1:
				walls.damage_segment(segment, BREAK_DAMAGE)
	elif pattern == "first_run":
		for segment: int in walls.segments_of(walls.spot_of(0)):
			walls.damage_segment(segment, BREAK_DAMAGE)


## The sha256 of `bytes`, as lowercase hex.
static func digest_of(bytes: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():
		context.update(bytes)
	return context.finish().hex_encode()


## The digest of one query kind on a world in a health pattern.
static func digest_for(world: String, pattern: String, kind: String) -> String:
	var built: Dictionary = build_world(world)
	var walls: WallSystem = built["walls"]
	apply_pattern(walls, pattern)
	var world_index: int = WORLDS.find(world)
	var map: MapConfig = built["map"]
	match kind:
		"near":
			return digest_of(_near_results(walls, world_index).to_byte_array())
		"blocking":
			return digest_of(_blocking_results(walls, map, world_index).to_byte_array())
		"push":
			return digest_of(_push_results(walls, world_index).to_byte_array())
		"closest":
			return digest_of(_closest_results(walls, world_index).to_byte_array())
	var tangent: Dictionary = _tangent_results(walls, world_index)
	var points: PackedVector2Array = tangent["points"]
	var hits: PackedInt32Array = tangent["hits"]
	return digest_of(points.to_byte_array() + hits.to_byte_array())


## Every pin key ("world_pattern_kind") with the digest the current implementation gives, in a
## fixed order (used by the pin tests and to print the pins).
static func all_digests() -> Dictionary:
	var digests: Dictionary = {}
	for world: String in WORLDS:
		for pattern: String in PATTERNS:
			for kind: String in KINDS:
				digests[pin_key(world, pattern, kind)] = digest_for(world, pattern, kind)
	return digests


static func pin_key(world: String, pattern: String, kind: String) -> String:
	return "%s_%s_%s" % [world, pattern, kind]


func _check_world(world: String) -> void:
	for pattern: String in PATTERNS:
		for kind: String in KINDS:
			var key: String = pin_key(world, pattern, kind)
			assert_eq(digest_for(world, pattern, kind), PINS.get(key, ""), key)


func test_the_prototype_map_answers_as_pinned() -> void:
	_check_world("prototype")


func test_the_stress_gate_wall_answers_as_pinned() -> void:
	_check_world("stress")


func test_the_sealed_ring_answers_as_pinned() -> void:
	_check_world("ring")


func test_the_gap_fixture_answers_as_pinned() -> void:
	_check_world("gap")


func test_every_pin_is_present_and_distinct_per_kind() -> void:
	assert_eq(PINS.size(), WORLDS.size() * PATTERNS.size() * KINDS.size(), "one pin per case")
	var seen: Dictionary = {}
	for world: String in WORLDS:
		for kind: String in KINDS:
			var key: String = pin_key(world, "intact", kind)
			assert_false(seen.has(PINS.get(key, "")), "%s differs from the other kinds" % key)
			seen[PINS.get(key, "")] = true


func test_the_worlds_have_the_shapes_the_pins_assume() -> void:
	var counts: Dictionary = {}
	for world: String in WORLDS:
		var walls: WallSystem = build_world(world)["walls"]
		counts[world] = walls.segment_count()
		assert_eq(walls.intact_count(), walls.segment_count(), "%s: all bought" % world)
	assert_eq(counts["ring"], 32, "the sealed ring is 32 segments")
	assert_gt(counts["prototype"], 40, "the prototype map's four runs")
	assert_gt(counts["stress"], 10, "the stress gate wall")
	assert_gt(counts["gap"], 5, "the gap fixture")
	var broken: WallSystem = build_world("ring")["walls"]
	apply_pattern(broken, "third")
	assert_eq(broken.intact_count(), 32 - 11, "every third segment of 32 is broken")


func test_the_queries_exercise_blocking_pushing_and_misses() -> void:
	for world: String in WORLDS:
		var built: Dictionary = build_world(world)
		var walls: WallSystem = built["walls"]
		var world_index: int = WORLDS.find(world)
		var blocked: int = 0
		var clear: int = 0
		for hit: int in _blocking_results(walls, built["map"], world_index):
			if hit >= 0:
				blocked += 1
			else:
				clear += 1
		assert_gt(blocked, 100, "%s: many lines are blocked" % world)
		assert_gt(clear, 100, "%s: many lines are clear" % world)
		var pushes: PackedVector2Array = _push_results(walls, world_index)
		var queries: PackedVector2Array = _push_queries(walls, world_index)
		var moved: int = 0
		for index: int in range(pushes.size()):
			if pushes[index] != queries[index]:
				moved += 1
		assert_gt(moved, 100, "%s: many points are pushed" % world)
		assert_lt(moved, pushes.size(), "%s: and many are not" % world)


static func _bounds_of(walls: WallSystem) -> Rect2:
	var low: Vector2 = walls.segment_start(0)
	var high: Vector2 = low
	for segment: int in range(walls.segment_count()):
		for end: Vector2 in [walls.segment_start(segment), walls.segment_end(segment)]:
			low = Vector2(minf(low.x, end.x), minf(low.y, end.y))
			high = Vector2(maxf(high.x, end.x), maxf(high.y, end.y))
	var margin: Vector2 = Vector2(BOUNDS_MARGIN, BOUNDS_MARGIN)
	return Rect2(low - margin, high - low + margin * 2.0)


static func _rng_for(world_index: int, kind: String) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + world_index * 1000 + KINDS.find(kind) * 100
	return rng


static func _uniform_point(rng: RandomNumberGenerator, bounds: Rect2) -> Vector2:
	return Vector2(
		rng.randf_range(bounds.position.x, bounds.end.x),
		rng.randf_range(bounds.position.y, bounds.end.y)
	)


## A point on a seeded segment moved by up to `spread` metres on each axis.
static func _point_near(rng: RandomNumberGenerator, walls: WallSystem, spread: float) -> Vector2:
	var segment: int = rng.randi_range(0, walls.segment_count() - 1)
	var start: Vector2 = walls.segment_start(segment)
	var end: Vector2 = walls.segment_end(segment)
	var on_segment: Vector2 = start + (end - start) * rng.randf()
	return on_segment + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))


## Count, then members, for each of QUERIES seeded (point, reach) pairs, then one count for each
## bad reach.
static func _near_results(walls: WallSystem, world_index: int) -> PackedInt32Array:
	var rng: RandomNumberGenerator = _rng_for(world_index, "near")
	var bounds: Rect2 = _bounds_of(walls)
	var out: PackedInt32Array = PackedInt32Array()
	for index: int in range(QUERIES):
		var pos: Vector2 = _uniform_point(rng, bounds)
		if index % 2 == 1:
			pos = _point_near(rng, walls, 3.0)
		var reach: float = (
			rng.randf_range(0.0, 60.0) if index % 3 == 0 else rng.randf_range(0.0, 8.0)
		)
		if index % 50 == 0:
			reach = float(index % 7) * 4.0
		var found: PackedInt32Array = walls.segments_near(pos, reach)
		out.append(found.size())
		out.append_array(found)
	for reach: float in BAD_REACHES:
		out.append(walls.segments_near(Vector2(1.0, 2.0), reach).size())
	return out


## One segment index (or -1) per seeded line, then the lines from far out to the castle and from
## every spawn point to it, in all four radii.
static func _blocking_results(
	walls: WallSystem, map: MapConfig, world_index: int
) -> PackedInt32Array:
	var rng: RandomNumberGenerator = _rng_for(world_index, "blocking")
	var bounds: Rect2 = _bounds_of(walls)
	var diagonal: float = bounds.size.length()
	var out: PackedInt32Array = PackedInt32Array()
	for index: int in range(QUERIES):
		var from: Vector2 = _uniform_point(rng, bounds)
		if index % 2 == 1:
			from = _point_near(rng, walls, 4.0)
		var direction: Vector2 = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		var length: float = rng.randf_range(0.5, diagonal)
		var radius: float = RADII[index % RADII.size()]
		out.append(
			WallSolids.first_blocking(walls, from, from + direction.normalized() * length, radius)
		)
	var castle: Vector2 = Vector2(map.castle_position.x, map.castle_position.z)
	for index: int in range(CASTLE_LINES):
		var heading: Vector2 = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		var far: Vector2 = castle + heading.normalized() * rng.randf_range(20.0, 90.0)
		out.append(WallSolids.first_blocking(walls, far, castle, RADII[index % RADII.size()]))
	for spawn: SpawnPointDef in map.spawn_points:
		var spawn_at: Vector2 = Vector2(spawn.position.x, spawn.position.z)
		for radius: float in RADII:
			out.append(WallSolids.first_blocking(walls, spawn_at, castle, radius))
	return out


## The points _push_results pushes: near and inside segments, and exactly on them.
static func _push_queries(walls: WallSystem, world_index: int) -> PackedVector2Array:
	var rng: RandomNumberGenerator = _rng_for(world_index, "push")
	var bounds: Rect2 = _bounds_of(walls)
	var out: PackedVector2Array = PackedVector2Array()
	for index: int in range(QUERIES):
		var pos: Vector2 = _point_near(rng, walls, 1.2)
		if index % 5 == 4:
			pos = _uniform_point(rng, bounds)
		elif index % 10 == 3:
			var segment: int = rng.randi_range(0, walls.segment_count() - 1)
			var start: Vector2 = walls.segment_start(segment)
			var end: Vector2 = walls.segment_end(segment)
			pos = start + (end - start) * (0.5 if index % 20 == 3 else float(index % 4) * 0.5)
		out.append(pos)
	return out


static func _push_results(walls: WallSystem, world_index: int) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var queries: PackedVector2Array = _push_queries(walls, world_index)
	for index: int in range(queries.size()):
		out.append(WallSolids.push_out(walls, queries[index], RADII[index % RADII.size()]))
	return out


## closest_point of every segment index from -1 to one past the end (the bad ones answer zero)
## against POINTS_PER_SEGMENT seeded points each.
static func _closest_results(walls: WallSystem, world_index: int) -> PackedVector2Array:
	var rng: RandomNumberGenerator = _rng_for(world_index, "closest")
	var bounds: Rect2 = _bounds_of(walls)
	var out: PackedVector2Array = PackedVector2Array()
	for segment: int in range(-1, walls.segment_count() + 2):
		for point_index: int in range(POINTS_PER_SEGMENT):
			var pos: Vector2 = _point_near(rng, walls, 3.0)
			if point_index % 8 == 7:
				pos = _uniform_point(rng, bounds)
			out.append(WallSolids.closest_point(walls, segment, pos))
	return out


## The tangent case (review item WR-02): the midpoint of every segment pushed out to exactly its
## reach and then line-tested a segment's length along and against the wall, in all four radii; and
## seeded points pushed out and line-tested in a random direction. {points, hits}.
static func _tangent_results(walls: WallSystem, world_index: int) -> Dictionary:
	var rng: RandomNumberGenerator = _rng_for(world_index, "tangent")
	var points: PackedVector2Array = PackedVector2Array()
	var hits: PackedInt32Array = PackedInt32Array()
	for segment: int in range(walls.segment_count()):
		var start: Vector2 = walls.segment_start(segment)
		var end: Vector2 = walls.segment_end(segment)
		var along: Vector2 = end - start
		for radius: float in RADII:
			var pushed: Vector2 = WallSolids.push_out(walls, (start + end) * 0.5, radius)
			points.append(pushed)
			hits.append(WallSolids.first_blocking(walls, pushed, pushed + along, radius))
			hits.append(WallSolids.first_blocking(walls, pushed, pushed - along, radius))
			hits.append(WallSolids.first_blocking(walls, pushed + along, pushed - along, radius))
	for index: int in range(QUERIES):
		var radius: float = RADII[index % RADII.size()]
		var pushed: Vector2 = WallSolids.push_out(walls, _point_near(rng, walls, 1.5), radius)
		var heading: Vector2 = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		var target: Vector2 = pushed + heading.normalized() * rng.randf_range(0.5, 12.0)
		points.append(pushed)
		hits.append(WallSolids.first_blocking(walls, pushed, target, radius))
	return {"points": points, "hits": hits}
