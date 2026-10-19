extends GutTest
## PLAT-01 (plan 04-20, exact_port_rules 7): every "nearest enemy" answer pinned on the GDScript
## query that shipped before EnemySystem.nearest_living existed. Seeded crowds of 50, 300 and 1000
## enemies (positions on a half-metre lattice so many are exactly equally far, a repeated position
## now and then, every 37th enemy damaged to death and not removed yet) stand on the prototype map;
## 2,000 seeded queries per crowd (reaches 0, 2.5, 9, 11, 22 and 30 m, half of them around the
## castle ring) go through TargetQuery.nearest_enemy and through TargetQuery.nearest_enemy_clear
## for walkers of radius 0.5 and 0.4 in three worlds: no wall bought, all four wall runs intact,
## and four seeded segments broken. The sha256 of each answer list is compared with a pinned hex
## string. The pins were computed on the GDScript loops and are never edited: the native query
## must reproduce them unchanged.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const BASE_SEED: int = 42000
const QUERIES: int = 2000
const SIZES: Array[int] = [50, 300, 1000]
const REACHES: Array[float] = [0.0, 2.5, 9.0, 11.0, 22.0, 30.0]
const RADII: Array[float] = [0.5, 0.4]
const STATES: Array[String] = ["none", "intact", "broken"]
const PLOTS: Array[StringName] = [&"wall_west", &"wall_east", &"wall_north", &"wall_ring"]
const WIDE: float = 70.0
const NEAR: float = 14.0
const LATTICE: float = 0.5
const BREAK_DAMAGE: int = 1000000
const HANDFUL: int = 4
const DEAD_EVERY: int = 37
const REPEAT_EVERY: int = 10
const PINS: Dictionary = {
	"50_plain": "3368e2f300b3cab69736b6611e42fae962880e1e3f0c89f977e72cb17b8a9ac1",
	"50_clear_5_none": "3368e2f300b3cab69736b6611e42fae962880e1e3f0c89f977e72cb17b8a9ac1",
	"50_clear_4_none": "3368e2f300b3cab69736b6611e42fae962880e1e3f0c89f977e72cb17b8a9ac1",
	"50_clear_5_intact": "8897022b4d32d88b89d8e6956c528cc1b2e6e8eff6c6bed6c34abd777252c84e",
	"50_clear_4_intact": "c068eafc235903c254edf10ac20f24ec6543c8467fca3e3f7055c103a131625b",
	"50_clear_5_broken": "4aaae32ded6c1d9182af9667d7aecdf0df5ffe2a1ba25384d8c177c10a126603",
	"50_clear_4_broken": "077a8a3a37cd7343d12f2db316cfd1a1e3db8bc6b3093dc225663a3b4466adf5",
	"300_plain": "395b2db1f4f61dbbebee9be123809b98e56225e158e540c3ceace268a80e939a",
	"300_clear_5_none": "395b2db1f4f61dbbebee9be123809b98e56225e158e540c3ceace268a80e939a",
	"300_clear_4_none": "395b2db1f4f61dbbebee9be123809b98e56225e158e540c3ceace268a80e939a",
	"300_clear_5_intact": "7b195ed0e0b23e1e85b85d67be2d1186c8a89f6387fcdbcca9b9453b14e2b71c",
	"300_clear_4_intact": "adeb698cec1363101120609f3dd47c47041ad4f2ac2694546a2534833cc53b16",
	"300_clear_5_broken": "2ab63e205e901299e1d422d8d62d8ef8db8295a683edfc82d43192e9ade416b2",
	"300_clear_4_broken": "1aa9d282113d7e3747c284e3d554aeac19a81642b91315d6d66fbdf241a2105c",
	"1000_plain": "50ad6ff5540b7a2b0b949833b080ce248d0bc4404cf7bc8eed0e5e6e821621b1",
	"1000_clear_5_none": "50ad6ff5540b7a2b0b949833b080ce248d0bc4404cf7bc8eed0e5e6e821621b1",
	"1000_clear_4_none": "50ad6ff5540b7a2b0b949833b080ce248d0bc4404cf7bc8eed0e5e6e821621b1",
	"1000_clear_5_intact": "b90b683e16dae90e55e1bc6cbab550f1c633854222aa8e568603ad9acc125015",
	"1000_clear_4_intact": "8cd0dacce196c8d620d661322e99d6a7ee28435417c85a99e46399ac8fc7a92e",
	"1000_clear_5_broken": "92cc9095d41e467ab052f1dd1de2d172b174be651f21bb7c52eaafc7dea84b3b",
	"1000_clear_4_broken": "6b4cb82052d69779717f0bfd03c925f113a715330303c4571668d34eaf4a2d87",
}


## "size_plain" for nearest_enemy, "size_clear_<radius>_<state>" for nearest_enemy_clear.
static func plain_key(size: int) -> String:
	return "%d_plain" % size


static func clear_key(size: int, radius: float, state: String) -> String:
	return "%d_clear_%d_%s" % [size, roundi(radius * 10.0), state]


## The sha256 of `bytes`, as lowercase hex.
static func digest_of(bytes: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():
		context.update(bytes)
	return context.finish().hex_encode()


static func _snap(value: float) -> float:
	return roundf(value / LATTICE) * LATTICE


## A seeded point on the lattice: wide over the whole map or tight around the castle ring.
static func _point(rng: RandomNumberGenerator, tight: bool) -> Vector2:
	var span: float = NEAR if tight else WIDE
	return Vector2(_snap(rng.randf_range(-span, span)), _snap(rng.randf_range(-span, span)))


## `count` grunts at seeded lattice positions in a fresh EnemySystem, some at the position of the
## one before, some dead and not yet removed.
static func build_crowd(count: int) -> EnemySystem:
	var enemies: EnemySystem = EnemySystem.new(SimEvents.new())
	var grunt: EnemyDef = load(GRUNT_PATH)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + count
	var last: Vector2 = Vector2.ZERO
	for index: int in range(count):
		var pos: Vector2 = _point(rng, index % 2 == 0)
		if index % REPEAT_EVERY == REPEAT_EVERY - 1:
			pos = last
		last = pos
		var id: int = enemies.spawn(grunt, pos)
		if index % DEAD_EVERY == DEAD_EVERY - 1:
			enemies.damage(id, grunt.max_health + 1, &"test")
	return enemies


## QUERIES seeded (position, reach) pairs for the crowd of `count`: positions as index parity
## picks wide or tight, reaches cycling through REACHES.
static func build_queries(count: int) -> Array[Vector3]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + count + 1
	var queries: Array[Vector3] = []
	for index: int in range(QUERIES):
		var pos: Vector2 = _point(rng, index % 3 != 0)
		queries.append(Vector3(pos.x, pos.y, REACHES[index % REACHES.size()]))
	return queries


## The prototype map's Pathing with the wall runs of `state` bought: none, intact or broken.
static func build_pathing(state: String) -> Pathing:
	var map: MapConfig = load(MAP_PATH)
	var events: SimEvents = SimEvents.new()
	var buildings: BuildingSystem = BuildingSystem.new(map, events)
	var walls: WallSystem = WallSystem.new(map, buildings, events)
	if state != "none":
		for plot: StringName in PLOTS:
			buildings.apply_next_tier(plot)
	if state == "broken":
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = BASE_SEED
		for _attempt: int in range(HANDFUL):
			walls.damage_segment(rng.randi_range(0, walls.segment_count() - 1), BREAK_DAMAGE)
	var pathing: Pathing = Pathing.new(map, walls)
	pathing.refresh()
	return pathing


static func plain_digest(enemies: EnemySystem, queries: Array[Vector3]) -> String:
	var answers: PackedInt64Array = PackedInt64Array()
	for query: Vector3 in queries:
		answers.append(TargetQuery.nearest_enemy(enemies, Vector2(query.x, query.y), query.z))
	return digest_of(answers.to_byte_array())


static func clear_digest(
	enemies: EnemySystem, queries: Array[Vector3], pathing: Pathing, radius: float
) -> String:
	var answers: PackedInt64Array = PackedInt64Array()
	for query: Vector3 in queries:
		answers.append(
			TargetQuery.nearest_enemy_clear(
				enemies, Vector2(query.x, query.y), query.z, pathing, radius
			)
		)
	return digest_of(answers.to_byte_array())


## Every pin of the crowd of `count`, key to digest.
static func digests_of(count: int) -> Dictionary:
	var digests: Dictionary = {}
	var enemies: EnemySystem = build_crowd(count)
	var queries: Array[Vector3] = build_queries(count)
	digests[plain_key(count)] = plain_digest(enemies, queries)
	for state: String in STATES:
		var pathing: Pathing = build_pathing(state)
		for radius: float in RADII:
			digests[clear_key(count, radius, state)] = clear_digest(
				enemies, queries, pathing, radius
			)
	return digests


func _check_size(count: int) -> void:
	var digests: Dictionary = digests_of(count)
	for key: String in digests:
		assert_eq(digests[key], PINS.get(key, ""), key)


func test_the_crowd_of_50_answers_as_pinned() -> void:
	_check_size(50)


func test_the_crowd_of_300_answers_as_pinned() -> void:
	_check_size(300)


func test_the_crowd_of_1000_answers_as_pinned() -> void:
	_check_size(1000)


func test_every_pin_is_present_and_the_walls_change_the_answers() -> void:
	assert_eq(PINS.size(), SIZES.size() * (1 + STATES.size() * RADII.size()), "one pin per case")
	for size: int in SIZES:
		var seen: Dictionary = {}
		for key: String in digests_keys(size):
			assert_true(PINS.has(key), "%s is pinned" % key)
			seen[PINS.get(key, "")] = true
		assert_gt(seen.size(), 2, "%d: the cases do not all answer alike" % size)
		assert_eq(
			PINS.get(clear_key(size, 0.5, "none"), "none"),
			PINS.get(plain_key(size), "plain"),
			"%d: no wall bought is exactly the plain query" % size
		)
		assert_ne(
			PINS.get(clear_key(size, 0.5, "intact"), "a"),
			PINS.get(plain_key(size), "b"),
			"%d: standing walls change some answer" % size
		)


static func digests_keys(size: int) -> Array[String]:
	var keys: Array[String] = [plain_key(size)]
	for state: String in STATES:
		for radius: float in RADII:
			keys.append(clear_key(size, radius, state))
	return keys


func test_the_crowds_have_the_shapes_the_pins_assume() -> void:
	for size: int in SIZES:
		var enemies: EnemySystem = build_crowd(size)
		assert_eq(enemies.count(), size, "%d: all spawned" % size)
		var dead: int = 0
		var repeats: int = 0
		var seen: Dictionary = {}
		for id: int in enemies.ids():
			if not enemies.is_alive(id):
				dead += 1
			var pos: Vector2 = enemies.position_of(id)
			if seen.has(pos):
				repeats += 1
			seen[pos] = true
		assert_eq(dead, size / DEAD_EVERY, "%d: dead and not removed" % size)
		assert_gt(repeats, size / REPEAT_EVERY - 2, "%d: positions repeat" % size)


func test_the_queries_find_enemies_at_every_reach_and_miss_at_some() -> void:
	var enemies: EnemySystem = build_crowd(300)
	var queries: Array[Vector3] = build_queries(300)
	var found: Dictionary = {}
	var missed: int = 0
	for query: Vector3 in queries:
		var id: int = TargetQuery.nearest_enemy(enemies, Vector2(query.x, query.y), query.z)
		if id < 0:
			missed += 1
		else:
			found[query.z] = int(found.get(query.z, 0)) + 1
	assert_gt(missed, 100, "many queries find nothing")
	for reach: float in REACHES:
		if reach >= 9.0:
			assert_gt(int(found.get(reach, 0)), 50, "reach %s finds enemies" % reach)


func test_the_walls_stand_and_break_as_the_states_say() -> void:
	var none: Pathing = build_pathing("none")
	var intact: Pathing = build_pathing("intact")
	var broken: Pathing = build_pathing("broken")
	assert_false(none.has_intact_walls(), "none: no wall")
	assert_true(intact.has_intact_walls(), "intact: walls stand")
	var all: int = intact.walls().segment_count()
	assert_eq(intact.walls().intact_count(), all, "intact: every segment")
	assert_lt(broken.walls().intact_count(), all, "broken: some fell")
	assert_gt(broken.walls().intact_count(), all / 2, "broken: most stand")
