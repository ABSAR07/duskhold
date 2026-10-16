extends GutTest
## PLAT-01 / T-04-05: the bucketed push-apart pass returns the O(n^2) pass's displacements bit for
## bit. Both are run on the same circles and the two PackedVector2Arrays must be equal, which is
## only true when every partner is accumulated in the same ascending order with the same
## expressions (float addition is not associative, and the replay goldens depend on every bit).

const WORLD_SEED: int = 7311
const LOW_RADIUS: float = 0.4
const HIGH_RADIUS: float = 0.5


## `count` circles at seeded positions inside a square `spread` metres wide, ids ascending from 1.
## `mixed` alternates the radii between LOW_RADIUS and HIGH_RADIUS, else all are HIGH_RADIUS.
func _circles(count: int, spread: float, mixed: bool, rng_seed: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed
	var positions: PackedVector2Array = PackedVector2Array()
	var radii: PackedFloat64Array = PackedFloat64Array()
	var ids: PackedInt64Array = PackedInt64Array()
	for index: int in range(count):
		var half: float = spread * 0.5
		positions.append(Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half)))
		radii.append(LOW_RADIUS if mixed and index % 2 == 0 else HIGH_RADIUS)
		ids.append(index + 1)
	return {"positions": positions, "radii": radii, "ids": ids}


func _cell_for(circles: Dictionary) -> float:
	var radii: PackedFloat64Array = circles["radii"]
	var largest: float = 0.0
	for radius: float in radii:
		largest = maxf(largest, radius)
	return 2.0 * largest + 0.001


func _same(circles: Dictionary, cell: float) -> bool:
	var positions: PackedVector2Array = circles["positions"]
	var radii: PackedFloat64Array = circles["radii"]
	var ids: PackedInt64Array = circles["ids"]
	var shipped: PackedVector2Array = Separation.displacements(positions, radii, ids)
	var bucketed: PackedVector2Array = Separation.displacements_bucketed(
		positions, radii, ids, cell
	)
	return shipped == bucketed


func _pushes_something(circles: Dictionary) -> bool:
	var positions: PackedVector2Array = circles["positions"]
	var radii: PackedFloat64Array = circles["radii"]
	var ids: PackedInt64Array = circles["ids"]
	for push: Vector2 in Separation.displacements(positions, radii, ids):
		if push != Vector2.ZERO:
			return true
	return false


func test_100_circles_spread_over_60_m_push_apart_the_same() -> void:
	var circles: Dictionary = _circles(100, 60.0, false, WORLD_SEED)
	assert_true(_same(circles, _cell_for(circles)), "bit-identical displacements")


func test_300_circles_spread_over_60_m_push_apart_the_same() -> void:
	var circles: Dictionary = _circles(300, 60.0, false, WORLD_SEED + 1)
	assert_true(_pushes_something(circles), "the set really overlaps")
	assert_true(_same(circles, _cell_for(circles)), "bit-identical displacements")


func test_300_circles_clumped_within_12_m_push_apart_the_same() -> void:
	var circles: Dictionary = _circles(300, 12.0, false, WORLD_SEED + 2)
	assert_true(_pushes_something(circles), "the clump really overlaps")
	assert_true(_same(circles, _cell_for(circles)), "bit-identical displacements")


func test_mixed_radii_push_apart_the_same() -> void:
	var circles: Dictionary = _circles(300, 30.0, true, WORLD_SEED + 3)
	assert_true(_pushes_something(circles), "the set really overlaps")
	assert_true(_same(circles, _cell_for(circles)), "bit-identical displacements")
	var clumped: Dictionary = _circles(300, 12.0, true, WORLD_SEED + 4)
	assert_true(_same(clumped, _cell_for(clumped)), "and clumped")


func test_coincident_pairs_of_even_and_odd_ids_push_apart_the_same() -> void:
	var positions: PackedVector2Array = PackedVector2Array()
	var radii: PackedFloat64Array = PackedFloat64Array()
	var ids: PackedInt64Array = PackedInt64Array()
	for index: int in range(40):
		# Every pair shares one point; the pairs' lower ids alternate odd and even.
		var point: Vector2 = Vector2(float(index / 2) * 0.7, float(index / 4) * 0.3)
		positions.append(point)
		radii.append(HIGH_RADIUS if index % 3 == 0 else LOW_RADIUS)
		ids.append(index + 1)
	var circles: Dictionary = {"positions": positions, "radii": radii, "ids": ids}
	assert_true(_same(circles, _cell_for(circles)), "bit-identical displacements")


func test_fewer_than_two_circles_return_all_zeros() -> void:
	var none: PackedVector2Array = Separation.displacements_bucketed(
		PackedVector2Array(), PackedFloat64Array(), PackedInt64Array(), 1.0
	)
	assert_eq(none.size(), 0, "no circles, no displacements")
	var lone: PackedVector2Array = Separation.displacements_bucketed(
		PackedVector2Array([Vector2(3.0, 4.0)]),
		PackedFloat64Array([HIGH_RADIUS]),
		PackedInt64Array([1]),
		1.001
	)
	assert_eq(lone, PackedVector2Array([Vector2.ZERO]), "one circle does not move")


func test_a_larger_or_smaller_cell_changes_the_cost_never_the_answer() -> void:
	var circles: Dictionary = _circles(150, 14.0, true, WORLD_SEED + 5)
	assert_true(_same(circles, 8.0), "a cell much wider than two radii")
	assert_true(_same(circles, 0.3), "a cell narrower than a radius still finds every partner")
