extends GutTest
## ENMY-04, ROADMAP success criterion 2 (D-09, D-11): 300 grunt-sized enemies at one 4 m gate in an
## 80 m wall. Every one crosses before T_max, no living enemy is still flagged stuck at the end, and
## the strong wall takes no hit. This is the CI gate; tools/gate_stress.sh runs the same harness and
## rule from the command line, twice.

const RESULT_KEYS: Array[String] = [
	"enemies",
	"crossed",
	"stuck_at_end",
	"max_cross_s",
	"median_cross_s",
	"longest_flag_s",
	"wall_hits",
	"ticks",
	"digest",
	"passed",
]
const EXPECTED_ENEMIES: int = 300
const NO_GATE_FIXTURE := "res://tests/fixtures/fixture_map_walls_gap.tres"

var _result: Dictionary = {}


func before_all() -> void:
	_result = GateStress.run(load(GateStress.STRESS_MAP) as MapConfig, 1, 60.0)


func test_the_result_carries_every_key() -> void:
	for key: String in RESULT_KEYS:
		assert_true(_result.has(key), "result has %s" % key)


func test_all_three_hundred_enemies_cross_and_none_is_stuck() -> void:
	assert_eq(_result["enemies"], EXPECTED_ENEMIES, "300 enemies")
	assert_eq(_result["crossed"], EXPECTED_ENEMIES, "every one crossed")
	assert_eq(_result["stuck_at_end"], 0, "no living enemy flagged at the end")
	assert_true(_result["passed"], "the gate passes")


func test_the_surge_drains_well_before_the_time_limit() -> void:
	assert_lt(_result["max_cross_s"], 60.0, "the last crossing is before T_max")
	assert_gt(_result["max_cross_s"], 0.0, "and it took some time")
	assert_lte(_result["median_cross_s"], _result["max_cross_s"], "the median is not above the max")


func test_the_strong_wall_takes_no_hit() -> void:
	assert_eq(_result["wall_hits"], 0, "they went round through the gate (D-07)")


func test_the_result_has_a_digest_of_the_run() -> void:
	var digest: String = _result["digest"]
	assert_eq(digest.length(), 64, "a sha256 hex digest")
	assert_true(digest.is_valid_hex_number(), "in hex")


func test_the_pass_rule_has_a_stuck_clause_of_its_own() -> void:
	assert_false(GateStress.passes(300, 300, 1, false), "everyone crossed, one still flagged")
	assert_true(GateStress.passes(300, 300, 0, false), "everyone crossed, none flagged")


func test_the_pass_rule_needs_every_crossing_and_an_unspent_clock() -> void:
	assert_false(GateStress.passes(300, 299, 0, false), "one did not cross")
	assert_false(GateStress.passes(300, 300, 0, true), "the time limit was hit")
	assert_false(GateStress.passes(0, 0, 0, false), "an empty night proves nothing")


func test_a_map_without_the_gate_reports_why_it_did_not_run() -> void:
	var result: Dictionary = GateStress.run(load(NO_GATE_FIXTURE) as MapConfig, 1, 10.0)
	assert_eq(result["reason"], "no_gate_wall", "named")
	assert_false(result["passed"], "and not a pass")
	assert_eq(result["crossed"], 0, "nobody crossed")


func test_a_time_limit_too_short_to_drain_fails_the_gate() -> void:
	var result: Dictionary = GateStress.run(load(GateStress.STRESS_MAP) as MapConfig, 1, 5.0)
	assert_true(result["hit_limit"], "five seconds is not enough for 300")
	assert_false(result["passed"], "so it is not a pass")
	assert_lt(result["crossed"], EXPECTED_ENEMIES, "not everyone crossed")


func test_the_same_seed_gives_the_same_run() -> void:
	var again: Dictionary = GateStress.run(load(GateStress.STRESS_MAP) as MapConfig, 1, 60.0)
	assert_eq(again["digest"], _result["digest"], "the event digest repeats")
	assert_eq(again["ticks"], _result["ticks"], "and so does the length")
