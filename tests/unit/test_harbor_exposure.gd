extends GutTest
## UAT G-05-7 (ECON-05, owner 2026-10-25, plan 05-22): "move the harbor into a much more exposed
## position that have enemy threat but not complete tower coverage so it is a bit awkward to
## defend". This file pins that exposure from the shipped data, so a later edit of an aggro range,
## a tower range, a card or the plot cannot silently cover the Harbor (a tower or the keep reaches
## it) or hide it again (no road passes within a skirmisher's notice).
## Every number is read from the shipped files: the prototype map (plots, spawns, castle), the
## Fishing Harbor (body radius), the tower and castle_center tiers (reach), the grunt and the
## skirmisher (aggro range), and the Engineers and Arrow Storm cards, applied through a StatStack's
## float_value exactly as the game resolves a reach. An enemy takes a building whose edge is within
## its aggro range, so the notice distance is the aggro range plus the building's body radius,
## centre to centre. The wall-run and gap rules stay in test_prototype_map_economy and the pond
## and footprint rules in test_pond_layout.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const HARBOR_PATH := "res://data/buildings/fishing_harbor.tres"
const CASTLE_PATH := "res://data/buildings/castle_center.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const SKIRMISHER_PATH := "res://data/enemies/ranged.tres"
const ENGINEERS_PATH := "res://data/abilities/engineers.tres"
const ARROW_STORM_PATH := "res://data/abilities/arrow_storm.tres"
const HARBOR: StringName = &"harbor_1"
const TOWER_DAMAGE: StringName = &"tower.damage"
const TOWER_RANGE: StringName = &"tower.range"
const ARROW_RANGE: StringName = &"castle.arrow_range"
## A point a few metres from tower_1 and from the keep, for the negative controls.
const NEAR_M: float = 5.0


func _map() -> MapConfig:
	return load(MAP_PATH)


func _ground(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


func _spot(map: MapConfig, spot_id: StringName) -> BuildSpotDef:
	for spot: BuildSpotDef in map.spots:
		if spot.id == spot_id:
			return spot
	return null


func _def_of(map: MapConfig, building_id: StringName) -> BuildingDef:
	for def: BuildingDef in map.buildings:
		if def.id == building_id:
			return def
	return null


func _harbor_at() -> Vector2:
	return _ground(_spot(_map(), HARBOR).position)


func _road_distance(map: MapConfig, point: Vector2) -> float:
	var nearest: float = INF
	var castle: Vector2 = _ground(map.castle_position)
	for spawn: SpawnPointDef in map.spawn_points:
		var on_road: Vector2 = Geometry2D.get_closest_point_to_segment(
			point, _ground(spawn.position), castle
		)
		nearest = minf(nearest, point.distance_to(on_road))
	return nearest


## The distance from the road at which an enemy with this aggro range notices the Harbor.
func _notice_m(enemy_path: String) -> float:
	var enemy: EnemyDef = load(enemy_path)
	var harbor: BuildingDef = load(HARBOR_PATH)
	return enemy.aggro_range + harbor.body_radius


## One fresh stack carrying a card's modifiers.
func _stack_with(card_path: String) -> StatStack:
	var card: ChoiceDef = load(card_path)
	var stack: StatStack = StatStack.new()
	assert_true(stack.add_source(card.id, card.modifiers), "the %s card applies" % card.id)
	return stack


## True for a building that shoots through the tower stats (tower.damage and tower.range): some
## tier of it attacks. The Shrine names its own stats and the keep's arrow has its own test.
func _shoots_like_a_tower(def: BuildingDef) -> bool:
	if def == null or def.damage_stat != TOWER_DAMAGE or def.range_stat != TOWER_RANGE:
		return false
	for tier: BuildingTierDef in def.tiers:
		if tier.attack_damage > 0:
			return true
	return false


## The longest reach of one building: its largest tier range, read through the Engineers card
## (tower.range), so Tower II with Engineers is the longest a tower ever shoots.
func _longest_reach(def: BuildingDef) -> float:
	var stack: StatStack = _stack_with(ENGINEERS_PATH)
	var longest: float = 0.0
	for tier: BuildingTierDef in def.tiers:
		longest = maxf(longest, stack.float_value(def.range_stat, tier.attack_range))
	return longest


## The longest reach of the keep's arrow: the map's tier I range and every castle_center tier
## range, read through the Arrow Storm card (castle.arrow_range).
func _longest_arrow_reach(map: MapConfig) -> float:
	var stack: StatStack = _stack_with(ARROW_STORM_PATH)
	var longest: float = stack.float_value(ARROW_RANGE, map.castle_attack_range)
	var castle: BuildingDef = load(CASTLE_PATH)
	for tier: BuildingTierDef in castle.tiers:
		longest = maxf(longest, stack.float_value(ARROW_RANGE, tier.attack_range))
	return longest


## True when a plot whose building shoots like a tower is within that building's longest reach.
func _tower_covers(map: MapConfig, point: Vector2) -> bool:
	for spot: BuildSpotDef in map.spots:
		var def: BuildingDef = _def_of(map, spot.building_id)
		if (
			_shoots_like_a_tower(def)
			and _ground(spot.position).distance_to(point) <= _longest_reach(def)
		):
			return true
	return false


func _arrow_covers(map: MapConfig, point: Vector2) -> bool:
	return _ground(map.castle_position).distance_to(point) <= _longest_arrow_reach(map)


func test_a_skirmisher_notices_the_harbor_from_the_road_and_a_grunt_does_not() -> void:
	var map: MapConfig = _map()
	var apart: float = _road_distance(map, _harbor_at())
	var skirmisher: float = _notice_m(SKIRMISHER_PATH)
	var grunt: float = _notice_m(GRUNT_PATH)
	assert_lte(
		apart,
		skirmisher,
		"%.2f m from a road is inside a skirmisher's %.2f m" % [apart, skirmisher]
	)
	assert_gt(apart, grunt, "%.2f m from a road is outside a grunt's %.2f m" % [apart, grunt])


func test_no_tower_plot_reaches_the_harbor_even_at_tower_two_range_through_engineers() -> void:
	var map: MapConfig = _map()
	var towers: int = 0
	for spot: BuildSpotDef in map.spots:
		var def: BuildingDef = _def_of(map, spot.building_id)
		if not _shoots_like_a_tower(def):
			continue
		towers += 1
		var reach: float = _longest_reach(def)
		var apart: float = _ground(spot.position).distance_to(_harbor_at())
		assert_gt(apart, reach, "%s is %.2f m away, its reach is %.2f m" % [spot.id, apart, reach])
	assert_gt(towers, 0, "the map has towers to check")
	assert_false(_tower_covers(map, _harbor_at()), "so no tower covers the Harbor")


func test_the_castle_arrow_does_not_reach_the_harbor_even_through_arrow_storm() -> void:
	var map: MapConfig = _map()
	var reach: float = _longest_arrow_reach(map)
	var apart: float = _ground(map.castle_position).distance_to(_harbor_at())
	assert_gt(reach, map.castle_attack_range, "Arrow Storm lengthens the arrow")
	assert_gt(apart, reach, "the keep is %.2f m away, its longest reach %.2f m" % [apart, reach])
	assert_false(_arrow_covers(map, _harbor_at()), "so the keep's arrow does not cover it")


func test_the_exposure_checks_do_cover_a_point_beside_a_tower_or_the_keep() -> void:
	var map: MapConfig = _map()
	var tower: Vector2 = _ground(_spot(map, &"tower_1").position)
	assert_true(_tower_covers(map, tower + Vector2(NEAR_M, 0.0)), "a point 5 m from tower_1")
	var castle: Vector2 = _ground(map.castle_position)
	assert_true(_arrow_covers(map, castle + Vector2(0.0, NEAR_M)), "a point 5 m from the keep")
