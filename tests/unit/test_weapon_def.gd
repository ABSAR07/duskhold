extends GutTest
## D-17, D-18, D-19: the king's weapon is data. The shipped sword carries the signed-off passive
## (3 m, 5 damage, 0.7 s) and slam (4 m, 4 damage, 9 s), the king points at it, a WeaponDef made
## with no data behaves like the old KingDef defaults, and bad slam numbers are never armed
## (T-03-08).

const SWORD_PATH := "res://data/king/sword.tres"
const KING_PATH := "res://data/king/king.tres"
const SMOKE_KING_PATH := "res://tests/fixtures/fixture_king_replay_smoke.tres"
const MAX_COOLDOWN_S: float = 3600.0


func _armed_weapon() -> WeaponDef:
	var weapon: WeaponDef = WeaponDef.new()
	weapon.slam_radius = 4.0
	weapon.slam_damage = 4
	weapon.slam_cooldown_seconds = 9.0
	return weapon


func test_the_shipped_sword_has_the_signed_off_passive() -> void:
	var sword: WeaponDef = load(SWORD_PATH) as WeaponDef
	assert_not_null(sword, "data/king/sword.tres loads as a WeaponDef")
	if sword == null:
		return
	assert_eq(sword.id, &"sword", "id")
	assert_eq(sword.display_name, "Sword", "name")
	assert_eq(sword.attack_range, 3.0, "passive reach is 3 m")
	assert_eq(sword.attack_damage, 5, "passive damage is 5")
	assert_eq(sword.attack_interval, 0.7, "passive interval is 0.7 s")


func test_the_shipped_sword_has_the_signed_off_slam() -> void:
	var sword: WeaponDef = load(SWORD_PATH) as WeaponDef
	assert_not_null(sword, "data/king/sword.tres loads as a WeaponDef")
	if sword == null:
		return
	assert_eq(sword.slam_radius, 4.0, "slam radius is 4 m")
	assert_eq(sword.slam_damage, 4, "slam damage is 4")
	assert_eq(sword.slam_cooldown_seconds, 9.0, "slam cooldown is 9 s")
	assert_true(sword.is_slam_armed(), "the shipped slam is armed")


func test_the_shipped_king_carries_the_sword() -> void:
	var king: KingDef = load(KING_PATH) as KingDef
	assert_not_null(king.weapon, "king.tres has a weapon")
	if king.weapon == null:
		return
	assert_eq(king.weapon.resource_path, SWORD_PATH, "and it is sword.tres")


func test_a_weapon_made_with_no_data_matches_the_old_king_defaults() -> void:
	var weapon: WeaponDef = WeaponDef.new()
	assert_eq(weapon.attack_range, 3.0, "range")
	assert_eq(weapon.attack_damage, 3, "damage")
	assert_eq(weapon.attack_interval, 0.8, "interval")
	assert_false(weapon.is_slam_armed(), "no slam")


func test_a_king_def_with_no_weapon_falls_back_to_the_defaults() -> void:
	var def: KingDef = KingDef.new()
	assert_null(def.weapon, "a fresh KingDef has no weapon")
	var king: KingState = KingState.new(def, Vector2.ZERO, SimEvents.new())
	var weapon: WeaponDef = king.get_weapon()
	assert_not_null(weapon, "the king still has a weapon")
	assert_eq(weapon.attack_range, 3.0, "range falls back")
	assert_eq(weapon.attack_damage, 3, "damage falls back")
	assert_eq(weapon.attack_interval, 0.8, "interval falls back")
	assert_false(king.has_ability(), "and has no ability")


func test_the_smoke_king_fixture_keeps_the_old_passive_and_no_slam() -> void:
	var king: KingDef = load(SMOKE_KING_PATH) as KingDef
	assert_not_null(king.weapon, "the fixture carries an inline weapon")
	if king.weapon == null:
		return
	assert_eq(king.weapon.attack_range, 3.0, "range")
	assert_eq(king.weapon.attack_damage, 3, "damage")
	assert_eq(king.weapon.attack_interval, 0.8, "interval")
	assert_false(king.weapon.is_slam_armed(), "no slam, so the smoke golden cannot move")


func test_a_complete_slam_is_armed() -> void:
	assert_true(_armed_weapon().is_slam_armed(), "radius, damage and cooldown set")


func test_a_slam_radius_that_is_not_finite_or_not_positive_is_not_armed() -> void:
	for bad: float in [NAN, INF, -INF, 0.0, -1.0]:
		var weapon: WeaponDef = _armed_weapon()
		weapon.slam_radius = bad
		assert_false(weapon.is_slam_armed(), "radius %s" % bad)


func test_a_slam_with_no_damage_is_not_armed() -> void:
	for bad: int in [0, -3]:
		var weapon: WeaponDef = _armed_weapon()
		weapon.slam_damage = bad
		assert_false(weapon.is_slam_armed(), "damage %d" % bad)


func test_a_slam_cooldown_outside_one_step_to_an_hour_is_not_armed() -> void:
	for bad: float in [NAN, INF, 0.0, -9.0, SimClock.STEP * 0.5, MAX_COOLDOWN_S + 1.0]:
		var weapon: WeaponDef = _armed_weapon()
		weapon.slam_cooldown_seconds = bad
		assert_false(weapon.is_slam_armed(), "cooldown %s" % bad)
	for good: float in [SimClock.STEP, MAX_COOLDOWN_S]:
		var weapon: WeaponDef = _armed_weapon()
		weapon.slam_cooldown_seconds = good
		assert_true(weapon.is_slam_armed(), "cooldown %s is on the boundary and allowed" % good)
