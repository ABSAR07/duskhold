extends GutTest
## PLAT-01 (plan 04-15, exact_port_rules 7): the push-apart pass pinned on the GDScript that shipped
## before any native code existed. Seeded crowds (sizes 0, 1, 2, 50, 300 and 1000, spreads of 5, 20
## and 60 m, radii all 0.5, all 0.4 and mixed, exact duplicates and exactly touching pairs) go
## through Separation.displacements and Separation.displacements_bucketed; the sha256 of each
## result's to_byte_array() is compared with a pinned hex string, and the bucketed pass must equal
## the pairwise one byte for byte. The pins were computed on the GDScript implementation and are
## never edited: the native version of the pass must reproduce them unchanged.

const BASE_SEED: int = 40415
const HIGH_RADIUS: float = 0.5
const LOW_RADIUS: float = 0.4
const CELL_SLACK: float = 0.001
const MODES: Array[String] = ["high", "low", "mixed"]
const SPREADS: Array[int] = [5, 20, 60]
const PINS: Dictionary = {
	"n0": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
	"n1": "af5570f5a1810b7af78caf4bc70a660f0df51e42baf91d4de5b2328de0e83dfc",
	"n2_s5_high": "d09c058f89efcf868267c6734b25380abd859fdf484a5728019a8c84ba06c162",
	"n2_s5_low": "374708fff7719dd5979ec875d56cd2286f6d3cf7ec317a3b25632aab28ec37bb",
	"n2_s5_mixed": "2408ea4aa0d6b340732c67dead57b435e0bf1c64615f6c82565c84c649694d85",
	"n2_s20_high": "2143f3c5e878586211040ad1f29b18602b0e993ef42308abf7cddacca5f5472c",
	"n2_s20_low": "f22be7856dc6fd22c28c882f36f3431df29830a4ed437a6a312e40458111a2d7",
	"n2_s20_mixed": "e59ac5dc299a86d81b63b766f34be739be3272cae02e6975a319ca89fb92babf",
	"n2_s60_high": "c6193e472b886ad0f9c5fb2dd822f55810b9c0b5cf17ad2d0db23214545476c9",
	"n2_s60_low": "998dd413476d0ee182a91fdac24f8a49a2697cc9d2778c26395c3e10c8a4469e",
	"n2_s60_mixed": "e7ca2c493d64a93f6e0731cada096f7f210a8a227d49b0e9672aa2f139fc6f8e",
	"n50_s5_high": "1b93b9aa5903ef4153a9ee85c5b6119959db20101e3cbc17c6b3883ad561e8d6",
	"n50_s5_low": "e1b4fdbb90d8405fc793d002bee5aef495ece910a9c5750fd7402b7f01c9164f",
	"n50_s5_mixed": "8c535c1819326c49da398cde6f83de7957e08b2b09b9ef01388b205af69647d7",
	"n50_s20_high": "0a128ec824557e9592f34b3d9471e2c92aedc59aae873c420f875121b7e2286e",
	"n50_s20_low": "26d165962ef4c7058b7b0d6864ad19b3eb16b60337c135955ad74e6fc037eca3",
	"n50_s20_mixed": "77102f90a814515024058b69d6ba30f9feb89aec206de8c0adb5a87563aabead",
	"n50_s60_high": "7a12e561363385e9dfeeab326368731c030ed4b374e7f5897ac819159d2884c5",
	"n50_s60_low": "fe9605f3c72bc63d97484108cd2e37bb86bccce428202a7d9afe02aaa56aaecb",
	"n50_s60_mixed": "7a12e561363385e9dfeeab326368731c030ed4b374e7f5897ac819159d2884c5",
	"n300_s5_high": "59aeadf76cb20af8ee768b92229d1fac345b9409f52a312bd76d619823e01176",
	"n300_s5_low": "b5494a5610b88cb6f0ee1a79a9384cb2dc006744ce9b320b41aa6369a8be1577",
	"n300_s5_mixed": "19aa01b810f119010848bf4ee457e7ba72f4b3a499b51a27a185fa2889235ace",
	"n300_s20_high": "f18ff1ac6f26861fd33db5510e58f26b5a18089a6c8ce7f00f00f8bd1abfb94c",
	"n300_s20_low": "66abc8faebfb89c589bbbf4a823896c0f64858ad2c9668617217dea1bb841f44",
	"n300_s20_mixed": "051c12af58cfd12c87dc0013b827bb5a713f2d0ed74544bd5dad6b61aaeece58",
	"n300_s60_high": "be8f6b3d2353f097796ff5249a7dbafbe35f5ac58446c8d3988f71d0914ef47f",
	"n300_s60_low": "67f2ae0cd5da8132d5975e85ea8fbb5ec336f4d8981e1933a74fdba5b3ddcef5",
	"n300_s60_mixed": "3f340cf3e8621be488ddd3332dd8c0aafb72ecfce8d3aa36d4d719217d001ebe",
	"n1000_s5_high": "8e54ec3088ef0f05609a6744f720d3f2479f2e0dc8f934b73d691f84a5f3fdda",
	"n1000_s5_low": "4225b54620f0d52bd976b68d64ae7b62ae5f79bfe1827128b537f2f69fa0481b",
	"n1000_s5_mixed": "be05167ac6782ed0eb8ef5ee4cf6d2bc070c15bcdf22a21f9f4b85d84d816200",
	"n1000_s20_high": "f9290c35a51bbf2ae99d931a20cb7a2d2113f4764ed66b319d995a3d0345ae8a",
	"n1000_s20_low": "73349d83f56af9c7a6093373d037c45d09afb42dc8837e945cfb671c5e129e3c",
	"n1000_s20_mixed": "f46d82ae9a50e10ebb9bfbaae1fcfae71451c7757eeec64c07017327ddec55e3",
	"n1000_s60_high": "52133a0cb4339aed7648d6a4641e2f4d9a4607fdd0db416729f0d5f4cf6439bc",
	"n1000_s60_low": "70ac30d94dd17a798612e58d55c46d2ee24a25bef0f4ec1e23e743ae7a5056e7",
	"n1000_s60_mixed": "de6d8489ed86e0f2853a5a64bb9a948e77a4f371e5408129618db366cd859065",
	"duplicates": "a76c8ee962ba86fc294dda423d4283dc3a18642f9a168e179b40933210866e38",
	"touching_pairs": "307c9a42a483d458c0b8eedff719e123a3eab24ec9ced807ea90c733d61db791",
	"touching_grid": "4cf9816ed1062189ff0c8d427fba5e912cc68fc9af76cf7f08fd255977de3b33",
	"inside_grid": "0aaf62915e57780545ad2a0af3053e10bbb32e31f6d5a466c54cc2a40abb1cfe",
}


## The radius of circle `index` in a radius `mode`: all 0.5, all 0.4, or alternating from 0.4.
static func radius_for(mode: String, index: int) -> float:
	if mode == "high":
		return HIGH_RADIUS
	if mode == "low":
		return LOW_RADIUS
	return LOW_RADIUS if index % 2 == 0 else HIGH_RADIUS


## `count` circles at seeded positions inside a square `spread` metres wide, ids ascending from 1.
## Two circles are always placed within 0.7 m of each other on each axis, so that they overlap.
static func crowd(count: int, spread: int, mode: String) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BASE_SEED + count * 31 + spread * 7 + MODES.find(mode)
	var half: float = float(spread) * 0.5
	var positions: PackedVector2Array = PackedVector2Array()
	var radii: PackedFloat64Array = PackedFloat64Array()
	var ids: PackedInt64Array = PackedInt64Array()
	for index: int in range(count):
		positions.append(Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half)))
		radii.append(radius_for(mode, index))
		ids.append(index + 1)
	if count == 2:
		positions[1] = (
			positions[0] + Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.7, 0.7))
		)
	return {"positions": positions, "radii": radii, "ids": ids}


## A crowd in which every third circle sits exactly on the one before it, so the zero-difference
## parity axis runs; ids step by 3 from 8 so both parities occur among the lower ids of a pair.
static func duplicates() -> Dictionary:
	var circles: Dictionary = crowd(300, 20, "mixed")
	var positions: PackedVector2Array = circles["positions"]
	var ids: PackedInt64Array = circles["ids"]
	for index: int in range(positions.size()):
		ids[index] = index * 3 + 8
		if index % 3 == 1:
			positions[index] = positions[index - 1]
	return circles


## A square grid of `side` by `side` circles `step` metres apart: with step 1.0 and radius 0.5
## every neighbouring pair touches exactly (a gap of exactly the radii sum pushes nothing).
static func grid(side: int, step: float, mode: String) -> Dictionary:
	var positions: PackedVector2Array = PackedVector2Array()
	var radii: PackedFloat64Array = PackedFloat64Array()
	var ids: PackedInt64Array = PackedInt64Array()
	for row: int in range(side):
		for column: int in range(side):
			var index: int = row * side + column
			positions.append(Vector2(float(column) * step, float(row) * step))
			radii.append(radius_for(mode, index))
			ids.append(index + 1)
	return {"positions": positions, "radii": radii, "ids": ids}


## Two circles that touch exactly (1.0 apart on x, radii 0.5 each) and two a hair inside that.
static func touching_pairs() -> Dictionary:
	var positions: PackedVector2Array = PackedVector2Array(
		[Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(10.0, 0.0), Vector2(10.0, 0.9999)]
	)
	var radii: PackedFloat64Array = PackedFloat64Array([0.5, 0.5, 0.5, 0.5])
	var ids: PackedInt64Array = PackedInt64Array([1, 2, 3, 4])
	return {"positions": positions, "radii": radii, "ids": ids}


## The bucketed cell edge the callers use: twice the largest radius plus the slack.
static func cell_of(circles: Dictionary) -> float:
	var radii: PackedFloat64Array = circles["radii"]
	var largest: float = 0.0
	for radius: float in radii:
		largest = maxf(largest, radius)
	return 2.0 * largest + CELL_SLACK


## The sha256 of the bytes of `pushes`, as lowercase hex.
static func digest_of(pushes: PackedVector2Array) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if not pushes.is_empty():
		context.update(pushes.to_byte_array())
	return context.finish().hex_encode()


## Both passes on `circles`: {pairwise, bucketed} as packed arrays.
static func run_both(circles: Dictionary) -> Dictionary:
	var positions: PackedVector2Array = circles["positions"]
	var radii: PackedFloat64Array = circles["radii"]
	var ids: PackedInt64Array = circles["ids"]
	return {
		"pairwise": Separation.displacements(positions, radii, ids),
		"bucketed": Separation.displacements_bucketed(positions, radii, ids, cell_of(circles)),
	}


## Every case as {key: circles}, in a fixed order (used by the pin tests and to print the pins).
static func all_cases() -> Dictionary:
	var cases: Dictionary = {}
	cases["n0"] = crowd(0, 5, "high")
	cases["n1"] = crowd(1, 5, "high")
	for count: int in [2, 50, 300, 1000]:
		for spread: int in SPREADS:
			for mode: String in MODES:
				cases[_key(count, spread, mode)] = crowd(count, spread, mode)
	cases["duplicates"] = duplicates()
	cases["touching_pairs"] = touching_pairs()
	cases["touching_grid"] = grid(12, 1.0, "high")
	cases["inside_grid"] = grid(12, 0.9, "mixed")
	return cases


static func _key(count: int, spread: int, mode: String) -> String:
	return "n%d_s%d_%s" % [count, spread, mode]


func _check(key: String, circles: Dictionary) -> void:
	var both: Dictionary = run_both(circles)
	var pairwise: PackedVector2Array = both["pairwise"]
	var bucketed: PackedVector2Array = both["bucketed"]
	var positions: PackedVector2Array = circles["positions"]
	assert_eq(pairwise.size(), positions.size(), "%s: one displacement per circle" % key)
	assert_eq(
		bucketed.to_byte_array(), pairwise.to_byte_array(), "%s: bucketed equals pairwise" % key
	)
	assert_eq(digest_of(pairwise), String(PINS.get(key, "no pin for " + key)), "%s: pinned" % key)


func _check_size(count: int) -> void:
	for spread: int in SPREADS:
		for mode: String in MODES:
			_check(_key(count, spread, mode), crowd(count, spread, mode))


func test_no_circles_and_one_circle_push_nothing() -> void:
	_check("n0", crowd(0, 5, "high"))
	_check("n1", crowd(1, 5, "high"))


func test_two_circles() -> void:
	_check_size(2)


func test_fifty_circles() -> void:
	_check_size(50)


func test_three_hundred_circles() -> void:
	_check_size(300)


func test_one_thousand_circles() -> void:
	_check_size(1000)


func test_exact_duplicates_use_the_parity_axis() -> void:
	_check("duplicates", duplicates())


func test_exactly_touching_pairs_push_nothing() -> void:
	var pushes: PackedVector2Array = run_both(touching_pairs())["pairwise"]
	assert_eq(pushes[0], Vector2.ZERO, "touching pair, first")
	assert_eq(pushes[1], Vector2.ZERO, "touching pair, second")
	assert_ne(pushes[2], Vector2.ZERO, "a pair a hair inside does push")
	_check("touching_pairs", touching_pairs())


func test_a_grid_of_exactly_touching_circles_pushes_nothing() -> void:
	var circles: Dictionary = grid(12, 1.0, "high")
	for push: Vector2 in run_both(circles)["pairwise"]:
		assert_eq(push, Vector2.ZERO, "no push in a touching grid")
	_check("touching_grid", circles)


func test_a_grid_a_little_inside_touching_pushes() -> void:
	_check("inside_grid", grid(12, 0.9, "mixed"))


func test_every_case_has_a_pin_and_every_pin_a_case() -> void:
	var cases: Dictionary = all_cases()
	assert_eq(PINS.size(), cases.size(), "one pin per case")
	for key: String in cases:
		assert_true(PINS.has(key), "%s has a pin" % key)
