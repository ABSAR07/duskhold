extends GutTest
## The push-apart pass shared by UnitSystem.separate and the enemy step (review IN-03), one routine
## in Separation. Determinism-sensitive: the displacements are summed pair by pair in
## ascending id order from one snapshot, a zero difference uses a fixed axis chosen by the lower
## id's parity, and the replay goldens depend on every bit of it. The first group pins the pure
## routine; the second pins the end positions both systems reach on one overlapping cluster over
## three passes (captured from the two copies of the routine before they were merged).

const TOLERANCE: float = 0.000001
## The radii the two system cases pin, written here rather than loaded from res://data/ so a retune
## of a shipped definition cannot fail them (review IN-11). They equal the shipped footman, archer,
## grunt and ranged values at the time the positions below were captured.
const FOOTMAN_RADIUS: float = 0.45
const ARCHER_RADIUS: float = 0.4
const GRUNT_RADIUS: float = 0.5
const RANGED_RADIUS: float = 0.45
const CLUSTER: Array[Vector2] = [
	Vector2(0.0, 0.0),
	Vector2(0.0, 0.0),
	Vector2(0.0, 0.0),
	Vector2(0.3, 0.1),
	Vector2(0.5, 0.4),
	Vector2(5.0, 5.0),
	Vector2(5.2, 5.1),
	Vector2(-3.0, 2.0),
	Vector2(-3.1, 2.05),
	Vector2(-3.0, 2.0),
	Vector2(10.0, 10.0),
	Vector2(0.45, -0.2),
]
const PASSES: int = 3
const UNIT_RESULT: Array[Vector2] = [
	Vector2(-0.4747125, -0.9193777),
	Vector2(-0.99079657, 0.34225273),
	Vector2(-0.090796545, 0.34225273),
	Vector2(0.7585594, 0.26280743),
	Vector2(0.9592506, 1.0887754),
	Vector2(4.719868, 4.8599343),
	Vector2(5.4801316, 5.2400656),
	Vector2(-3.0836494, 1.8236033),
	Vector2(-3.7826238, 2.391312),
	Vector2(-2.2337267, 1.8350848),
	Vector2(10, 10),
	Vector2(1.0884956, -0.81671065)
]
const ENEMY_RESULT: Array[Vector2] = [
	Vector2(-0.60688066, -1.0461168),
	Vector2(-1.1729648, 0.3655135),
	Vector2(-0.17296475, 0.3655135),
	Vector2(0.85337794, 0.3356897),
	Vector2(1.1056565, 1.2515802),
	Vector2(4.675147, 4.8375735),
	Vector2(5.5248528, 5.2624264),
	Vector2(-3.0889323, 1.8012588),
	Vector2(-3.8720665, 2.4360332),
	Vector2(-2.1390011, 1.8127079),
	Vector2(10, 10),
	Vector2(1.2437756, -0.97218007)
]


func _unit_def(radius: float) -> UnitDef:
	var def: UnitDef = UnitDef.new()
	def.radius = radius
	return def


func _enemy_def(radius: float) -> EnemyDef:
	var def: EnemyDef = EnemyDef.new()
	def.radius = radius
	return def


func _positions(points: Array[Vector2]) -> PackedVector2Array:
	return PackedVector2Array(points)


func _radii(values: Array[float]) -> PackedFloat64Array:
	return PackedFloat64Array(values)


func _ids(values: Array[int]) -> PackedInt64Array:
	return PackedInt64Array(values)


func test_two_overlapping_circles_are_pushed_apart_by_half_the_overlap_each() -> void:
	var pushed: PackedVector2Array = Separation.displacements(
		_positions([Vector2(0.0, 0.0), Vector2(0.6, 0.0)]), _radii([0.5, 0.5]), _ids([1, 2])
	)
	assert_eq(pushed.size(), 2, "one displacement per circle")
	assert_almost_eq(pushed[0], Vector2(-0.2, 0.0), Vector2(TOLERANCE, TOLERANCE), "left one left")
	assert_almost_eq(pushed[1], Vector2(0.2, 0.0), Vector2(TOLERANCE, TOLERANCE), "right one right")


func test_circles_that_do_not_overlap_do_not_move() -> void:
	var pushed: PackedVector2Array = Separation.displacements(
		_positions([Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)]),
		_radii([0.5, 0.5, 0.5]),
		_ids([1, 2, 3])
	)
	for displacement: Vector2 in pushed:
		assert_eq(displacement, Vector2.ZERO, "touching is not overlapping")


func test_a_zero_difference_pushes_along_a_fixed_axis_chosen_by_the_lower_id() -> void:
	var even_first: PackedVector2Array = Separation.displacements(
		_positions([Vector2.ZERO, Vector2.ZERO]), _radii([0.5, 0.5]), _ids([2, 3])
	)
	assert_almost_eq(even_first[0], Vector2(-0.5, 0.0), Vector2(TOLERANCE, TOLERANCE), "x axis")
	assert_almost_eq(even_first[1], Vector2(0.5, 0.0), Vector2(TOLERANCE, TOLERANCE), "x axis")
	var odd_first: PackedVector2Array = Separation.displacements(
		_positions([Vector2.ZERO, Vector2.ZERO]), _radii([0.5, 0.5]), _ids([3, 4])
	)
	assert_almost_eq(odd_first[0], Vector2(0.0, -0.5), Vector2(TOLERANCE, TOLERANCE), "z axis")
	assert_almost_eq(odd_first[1], Vector2(0.0, 0.5), Vector2(TOLERANCE, TOLERANCE), "z axis")


func test_fewer_than_two_circles_give_zero_displacements() -> void:
	assert_eq(Separation.displacements(_positions([]), _radii([]), _ids([])).size(), 0, "none")
	var one: PackedVector2Array = Separation.displacements(
		_positions([Vector2.ZERO]), _radii([0.5]), _ids([1])
	)
	assert_eq(one.size(), 1, "one circle, one entry")
	assert_eq(one[0], Vector2.ZERO, "that does not move")


func test_the_displacements_come_from_one_snapshot_and_are_summed() -> void:
	var pushed: PackedVector2Array = Separation.displacements(
		_positions([Vector2(0.0, 0.0), Vector2(0.4, 0.0), Vector2(0.8, 0.0)]),
		_radii([0.5, 0.5, 0.5]),
		_ids([1, 2, 3])
	)
	assert_almost_eq(pushed[1], Vector2.ZERO, Vector2(TOLERANCE, TOLERANCE), "pushed both ways")
	assert_almost_eq(pushed[0].x, -pushed[2].x, TOLERANCE, "the ends mirror each other")
	assert_lt(pushed[0].x, 0.0, "the first goes left")


func test_unit_system_separates_the_cluster_to_the_pinned_positions() -> void:
	var events: SimEvents = SimEvents.new()
	var units: UnitSystem = UnitSystem.new(events)
	var footman: UnitDef = _unit_def(FOOTMAN_RADIUS)
	var archer: UnitDef = _unit_def(ARCHER_RADIUS)
	for index: int in range(CLUSTER.size()):
		units.spawn(footman if index % 3 != 0 else archer, &"s", index, CLUSTER[index])
	for _pass: int in range(PASSES):
		units.separate()
	var ids: Array[int] = units.ids()
	for index: int in range(ids.size()):
		assert_almost_eq(
			units.position_of(ids[index]),
			UNIT_RESULT[index],
			Vector2(TOLERANCE, TOLERANCE),
			"unit %d" % ids[index]
		)


func test_enemy_system_separates_the_cluster_to_the_pinned_positions() -> void:
	var events: SimEvents = SimEvents.new()
	var enemies: EnemySystem = EnemySystem.new(events)
	var grunt: EnemyDef = _enemy_def(GRUNT_RADIUS)
	var ranged: EnemyDef = _enemy_def(RANGED_RADIUS)
	for index: int in range(CLUSTER.size()):
		enemies.spawn(grunt if index % 3 != 0 else ranged, CLUSTER[index])
	for _pass: int in range(PASSES):
		# The native push-apart pass, called on the store on purpose: the enemy system runs it inside
		# its tick and has no public seam for it. A rename breaks this line at run time (review
		# IN-11). Walls are not solid here, so only the push-apart runs.
		enemies._native.separate_pass(false)
	var ids: Array[int] = enemies.ids()
	for index: int in range(ids.size()):
		assert_almost_eq(
			enemies.position_of(ids[index]),
			ENEMY_RESULT[index],
			Vector2(TOLERANCE, TOLERANCE),
			"enemy %d" % ids[index]
		)
