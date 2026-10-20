extends GutTest
## PLAT-01 (plan 04-27, review IN-07): UnitSystem.read_view() hands the unit batches packed arrays
## instead of a copy of the id list and three record look-ups per unit every frame. It must agree
## with the id API, change its version only when an id, a position or a def changes, list each def
## once, and read without emitting a SimEvents signal. UnitSystem also stays inside gdlint's cap of
## 20 public methods (squad_of, which nobody called, gave up its slot to read_view).

const FOOTMAN_PATH := "res://data/units/footman.tres"
const ARCHER_PATH := "res://data/units/archer.tres"
const SYSTEM_PATH := "res://simulation/squads/unit_system.gd"
const PUBLIC_METHOD_CAP: int = 20
const SPAWN_COUNT: int = 9

var _footman: UnitDef
var _archer: UnitDef
var _events: SimEvents
var _units: UnitSystem


func before_each() -> void:
	_footman = load(FOOTMAN_PATH)
	_archer = load(ARCHER_PATH)
	_events = SimEvents.new()
	_units = UnitSystem.new(_events)


func _spawn_army() -> void:
	for index: int in range(SPAWN_COUNT):
		var def: UnitDef = _footman if index % 3 != 0 else _archer
		_units.spawn(def, &"barracks_1", index, Vector2(float(index) * 1.5, 2.0 + float(index % 2)))


func _assert_matches_the_id_api() -> void:
	var view: UnitReadView = _units.read_view()
	var ids: Array[int] = _units.ids()
	assert_eq(view.ids.size(), ids.size(), "one slot per unit")
	assert_eq(view.previous.size(), ids.size(), "a previous position per unit")
	assert_eq(view.current.size(), ids.size(), "a current position per unit")
	assert_eq(view.def_slots.size(), ids.size(), "a def slot per unit")
	for index: int in range(mini(ids.size(), view.ids.size())):
		var unit_id: int = ids[index]
		assert_eq(view.ids[index], unit_id, "ascending ids, slot %d" % index)
		assert_eq(view.previous[index], _units.previous_position_of(unit_id), "previous")
		assert_eq(view.current[index], _units.position_of(unit_id), "current")
		assert_eq(
			view.defs[view.def_slots[index]], _units.def_of(unit_id), "def of unit %d" % unit_id
		)


func test_an_empty_army_reads_empty_arrays() -> void:
	var view: UnitReadView = _units.read_view()
	assert_eq(view.ids.size(), 0, "no ids")
	assert_eq(view.previous.size(), 0, "no previous positions")
	assert_eq(view.current.size(), 0, "no current positions")
	assert_eq(view.def_slots.size(), 0, "no def slots")
	assert_eq(view.defs.size(), 0, "no defs")


func test_the_view_agrees_with_the_id_api_after_spawning() -> void:
	_spawn_army()
	_assert_matches_the_id_api()


func test_each_def_is_listed_once_in_first_seen_order() -> void:
	_spawn_army()
	var view: UnitReadView = _units.read_view()
	assert_eq(view.defs.size(), 2, "two unit types")
	assert_eq(view.defs[0], _archer, "unit 1 is an archer, so it comes first")
	assert_eq(view.defs[1], _footman, "then the footman")
	assert_eq(view.def_slots[0], 0, "the first unit is an archer")
	assert_eq(view.def_slots[1], 1, "the second is a footman")


func test_the_view_agrees_after_a_step_moved_the_army_separate_and_remove_dead() -> void:
	_spawn_army()
	_units.begin_step()
	for unit_id: int in _units.ids():
		_units.set_position_of(unit_id, _units.position_of(unit_id) + Vector2(0.5, -0.25))
	_assert_matches_the_id_api()
	var view: UnitReadView = _units.read_view()
	assert_ne(view.previous[0], view.current[0], "the first unit really moved")
	_units.separate()
	_assert_matches_the_id_api()
	_units.damage(_units.ids()[2], 1000, &"test")
	_units.remove_dead()
	_assert_matches_the_id_api()
	assert_eq(_units.read_view().ids.size(), SPAWN_COUNT - 1, "the dead unit left the view")


func test_a_second_read_with_no_change_returns_the_same_object_and_version() -> void:
	_spawn_army()
	var first: UnitReadView = _units.read_view()
	var version: int = first.version
	var second: UnitReadView = _units.read_view()
	assert_same(second, first, "the same object every time")
	assert_eq(second.version, version, "nothing changed, nothing rebuilt")
	_units.damage(_units.ids()[0], 1, &"test")
	_units.heal_to_full(_units.ids()[0])
	assert_eq(_units.read_view().version, version, "health is not part of the view")


func test_spawn_begin_step_move_separate_and_remove_dead_each_bump_the_version() -> void:
	var seen: int = _units.read_view().version
	_units.spawn(_footman, &"barracks_1", 0, Vector2(1.0, 1.0))
	_units.spawn(_footman, &"barracks_1", 1, Vector2(1.1, 1.0))
	var after_spawn: int = _units.read_view().version
	assert_ne(after_spawn, seen, "spawn bumps it")
	_units.begin_step()
	var after_begin: int = _units.read_view().version
	assert_ne(after_begin, after_spawn, "begin_step bumps it")
	_units.set_position_of(_units.ids()[0], Vector2(5.0, 5.0))
	var after_move: int = _units.read_view().version
	assert_ne(after_move, after_begin, "a move bumps it")
	_units.separate()
	var after_separate: int = _units.read_view().version
	assert_ne(after_separate, after_move, "separate bumps it")
	_units.damage(_units.ids()[0], 1000, &"test")
	_units.remove_dead()
	var after_removal: int = _units.read_view().version
	assert_ne(after_removal, after_separate, "remove_dead bumps it")
	assert_eq(_units.read_view().ids.size(), 1, "one unit is left")


func test_a_dead_unit_stays_in_the_view_until_it_is_removed() -> void:
	_spawn_army()
	var victim: int = _units.ids()[3]
	_units.damage(victim, 1000, &"test")
	assert_true(victim in _units.read_view().ids, "ids() still lists it, so the view does")
	_units.remove_dead()
	assert_false(victim in _units.read_view().ids, "removal takes it out")
	_assert_matches_the_id_api()


func test_reading_the_view_emits_no_signal() -> void:
	_spawn_army()
	_units.begin_step()
	watch_signals(_events)
	_units.read_view()
	_units.read_view()
	for signal_name: String in SimSignals.ALL:
		assert_signal_not_emitted(_events, signal_name, "%s stays quiet" % signal_name)


func test_unit_system_stays_inside_the_public_method_cap() -> void:
	var file: FileAccess = FileAccess.open(SYSTEM_PATH, FileAccess.READ)
	assert_not_null(file, "unit_system.gd opens")
	if file == null:
		return
	var matcher: RegEx = RegEx.new()
	matcher.compile("^(static )?func [a-z]")
	var public_methods: int = 0
	for line: String in file.get_as_text().split("\n"):
		if matcher.search(line) != null:
			public_methods += 1
	assert_lte(public_methods, PUBLIC_METHOD_CAP, "at most 20 public functions")
	assert_false(_units.has_method("squad_of"), "squad_of gave up its slot")
