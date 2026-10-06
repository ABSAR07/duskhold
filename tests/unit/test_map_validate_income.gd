extends GutTest
## G-02-1: MapConfig.validate() reports a bad base dawn income and a spot that squats on the
## reserved castle payout key (T-02-27, T-02-28). Every case edits a deep copy and calls validate()
## directly, never through RunContext, whose push_error would fail the test. The shipped map and
## the frozen replay fixture report nothing.

const SMOKE_FIXTURE := "res://tests/fixtures/fixture_map_replay_smoke.tres"


func _map() -> MapConfig:
	return E2eSupport.shipped_prototype_map()


## Asserts validate() reports exactly one error and that it contains `needle`.
func _assert_one_error(map: MapConfig, needle: String, label: String) -> void:
	var errors: PackedStringArray = map.validate()
	assert_eq(errors.size(), 1, "%s reports exactly one error: %s" % [label, errors])
	if errors.size() == 1:
		assert_string_contains(errors[0], needle, "%s names the item" % label)


func test_the_script_default_base_income_is_off() -> void:
	assert_eq(MapConfig.new().base_dawn_income, 0, "a map that says nothing pays no base income")


func test_the_castle_payout_key_is_the_castle_string_name() -> void:
	assert_eq(MapConfig.CASTLE_PAYOUT_KEY, &"castle", "the reserved per_spot key")


func test_the_shipped_map_reports_no_error() -> void:
	assert_eq(_map().validate(), PackedStringArray(), "the shipped map is clean")


func test_the_replay_smoke_fixture_reports_no_error() -> void:
	var fixture: MapConfig = load(SMOKE_FIXTURE)
	var copy: MapConfig = fixture.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	assert_eq(copy.validate(), PackedStringArray(), "the frozen fixture is clean")
	assert_eq(copy.base_dawn_income, 0, "and it keeps the base income off")


func test_a_negative_base_dawn_income_is_reported() -> void:
	var map: MapConfig = _map()
	map.base_dawn_income = -1
	_assert_one_error(map, "base_dawn_income", "a negative base income")


func test_a_zero_base_dawn_income_is_clean() -> void:
	var map: MapConfig = _map()
	map.base_dawn_income = 0
	assert_eq(map.validate(), PackedStringArray(), "0 switches the base income off")


func test_a_spot_with_the_reserved_castle_id_is_reported() -> void:
	var map: MapConfig = _map()
	map.spots[0].id = MapConfig.CASTLE_PAYOUT_KEY
	_assert_one_error(map, "reserved", "a spot named castle")


## Lives here, not in test_prototype_map_data.gd, which already holds gdlint's 20 public methods.
func test_the_shipped_map_pays_a_base_income_of_one_gold_every_dawn() -> void:
	assert_eq(_map().base_dawn_income, 1, "owner decision 2026-10-06, G-02-1")
	assert_eq(_map().starting_gold, 4, "the starting gold stays 4")
