extends GutTest
## PLAT-01 (plan 04-15, T-04-38 and T-04-39): the native push-apart pass answers what the GDScript
## answered. NativeSim.separation_displacements and separation_displacements_bucketed are called
## directly on every seeded case of test_separation_pins (whose sha256 pins were computed on the
## GDScript before any native code existed) and must reproduce them; arrays of different sizes give
## an all-zero result of positions.size() instead of a read past an array (exact_port_rules 10).

const Pins := preload("res://tests/unit/test_separation_pins.gd")


func _missing_native() -> bool:
	if ClassDB.class_exists(&"NativeSim"):
		return false
	fail_test("NativeSim is missing; run: bash tools/native_build.sh")
	return true


func _zeros(count: int) -> PackedVector2Array:
	var zeros: PackedVector2Array = PackedVector2Array()
	zeros.resize(count)
	return zeros


func test_the_native_pairwise_pass_reproduces_every_pin() -> void:
	if _missing_native():
		return
	var cases: Dictionary = Pins.all_cases()
	for key: String in cases:
		var circles: Dictionary = cases[key]
		var pushes: PackedVector2Array = NativeSim.separation_displacements(
			circles["positions"], circles["radii"], circles["ids"]
		)
		assert_eq(Pins.digest_of(pushes), Pins.PINS[key], "%s: native pairwise is pinned" % key)


func test_the_native_bucketed_pass_reproduces_every_pin() -> void:
	if _missing_native():
		return
	var cases: Dictionary = Pins.all_cases()
	for key: String in cases:
		var circles: Dictionary = cases[key]
		var pushes: PackedVector2Array = NativeSim.separation_displacements_bucketed(
			circles["positions"], circles["radii"], circles["ids"], Pins.cell_of(circles)
		)
		assert_eq(Pins.digest_of(pushes), Pins.PINS[key], "%s: native bucketed is pinned" % key)


func test_the_cell_size_never_changes_an_answer() -> void:
	if _missing_native():
		return
	var circles: Dictionary = Pins.crowd(50, 5, "mixed")
	var expected: PackedVector2Array = NativeSim.separation_displacements(
		circles["positions"], circles["radii"], circles["ids"]
	)
	for cell: float in [0.0, 0.001, 0.2, 0.3, 0.5, 1.001, 3.0, 100.0]:
		var pushes: PackedVector2Array = NativeSim.separation_displacements_bucketed(
			circles["positions"], circles["radii"], circles["ids"], cell
		)
		assert_eq(pushes.to_byte_array(), expected.to_byte_array(), "cell %s" % cell)


func test_mismatched_array_sizes_give_all_zero_results() -> void:
	if _missing_native():
		return
	var positions: PackedVector2Array = PackedVector2Array(
		[
			Vector2(0.0, 0.0),
			Vector2(0.1, 0.0),
			Vector2(0.2, 0.0),
			Vector2(0.3, 0.0),
			Vector2(0.4, 0.0)
		]
	)
	var radii_short: PackedFloat64Array = PackedFloat64Array([0.5, 0.5, 0.5, 0.5])
	var radii: PackedFloat64Array = PackedFloat64Array([0.5, 0.5, 0.5, 0.5, 0.5])
	var ids_short: PackedInt64Array = PackedInt64Array([1, 2, 3])
	var ids: PackedInt64Array = PackedInt64Array([1, 2, 3, 4, 5])
	var zeros: PackedVector2Array = _zeros(5)
	assert_eq(NativeSim.separation_displacements(positions, radii_short, ids), zeros, "radii short")
	assert_eq(NativeSim.separation_displacements(positions, radii, ids_short), zeros, "ids short")
	assert_eq(
		NativeSim.separation_displacements_bucketed(positions, radii_short, ids, 1.001),
		zeros,
		"bucketed, radii short"
	)
	assert_eq(
		NativeSim.separation_displacements_bucketed(positions, radii, ids_short, 1.001),
		zeros,
		"bucketed, ids short"
	)
	var ok: PackedVector2Array = NativeSim.separation_displacements(positions, radii, ids)
	assert_ne(ok, zeros, "the same crowd with matching arrays does push")


func test_more_radii_or_ids_than_positions_give_all_zero_results() -> void:
	if _missing_native():
		return
	var positions: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.1, 0.0)])
	var radii_long: PackedFloat64Array = PackedFloat64Array([0.5, 0.5, 0.5])
	var ids: PackedInt64Array = PackedInt64Array([1, 2])
	assert_eq(
		NativeSim.separation_displacements(positions, radii_long, ids), _zeros(2), "radii long"
	)
	assert_eq(
		NativeSim.separation_displacements_bucketed(positions, radii_long, ids, 1.001),
		_zeros(2),
		"bucketed, radii long"
	)


func test_no_circles_and_one_circle_give_arrays_of_that_size() -> void:
	if _missing_native():
		return
	var none: PackedVector2Array = NativeSim.separation_displacements(
		PackedVector2Array(), PackedFloat64Array(), PackedInt64Array()
	)
	assert_eq(none.size(), 0, "no circles")
	var one: PackedVector2Array = NativeSim.separation_displacements_bucketed(
		PackedVector2Array([Vector2(1.0, 2.0)]),
		PackedFloat64Array([0.5]),
		PackedInt64Array([7]),
		1.001
	)
	assert_eq(one, _zeros(1), "one circle pushes nothing")
