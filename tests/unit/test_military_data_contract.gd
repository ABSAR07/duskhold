extends GutTest
## The shipped military numbers, pinned on purpose (D-01, D-02, D-03, D-05, D-06, D-07): costs
## 4/8/16, squad sizes 4/8/14 with a smaller but larger-in-magnitude last step, respawn 10/7/4 s,
## the footman at a fifth of the king's health, and the two military plots last on the map, inside
## the tower ring and clear of everything. Plan 03-11 would re-pin a number here deliberately if its
## night retune had to move one; it did not (the nights alone reached the bar), so every number was
## unchanged then. Round 2 (G-03-11, plan 03-17) moved exactly one number outside the nights, the
## first tower tier's shot interval, pinned by its own test below; every other number here is
## unchanged, and any change that breaks this test is a regression.
## Gap round G-05-2 (owner UAT decision 2026-10-25, plans 05-13 to 05-24): every health and damage
## number is 100 times larger, the owner's hard requirement, so percentages and rounding to the
## nearest unit work as written; the numbers below moved x100 and nothing else did; here: the
## footman's 100 (D-07 at the same ratio), Tower I 300 and 5000, Tower II 600.

const MAP_PATH := "res://data/maps/prototype_map.tres"
const TOWER_PATH := "res://data/buildings/tower.tres"
const KING_PATH := "res://data/king/king.tres"
const BARRACKS_PATH := "res://data/buildings/barracks.tres"
const ARCHERY_PATH := "res://data/buildings/archery_range.tres"
const FOOTMAN_PATH := "res://data/units/footman.tres"
const ARCHER_PATH := "res://data/units/archer.tres"
const GRUNT_PATH := "res://data/enemies/grunt.tres"
const COSTS: Array[int] = [4, 8, 16]
const SQUAD_SIZES: Array[int] = [4, 8, 14]
const RESPAWN_SECONDS: Array[float] = [10.0, 7.0, 4.0]
## Ten Phase 1 to 3 plots and, since plan 04-05 (D-06), the four wall plots appended after them.
## Plan 05-02 appends the castle plot after those fourteen; the total is pinned in
## test_prototype_map_economy, so this contract pins only the first fourteen.
const WALL_PLOT_COUNT: int = 4
const PHASE_FOUR_SPOT_COUNT: int = 14
const BARRACKS_SPOT: int = 8
const ARCHERY_SPOT: int = 9
const MIN_CLEARANCE_M: float = 5.0
## The footman is a fifth of the king (D-06); its blow is the integer nearest a fifth of the king's
## passive 500 (D-07), written as a literal so the weapon migration of plan 03-04 does not touch it.
const FOOTMAN_DAMAGE: int = 100
const KING_HEALTH_PER_FOOTMAN: int = 5
## Round 2 (G-03-11, plan 03-17): every number the retune moved outside the nights, old to new. The
## first tower tier fired every 0.8 s and now fires every 0.9 s (the owner's goals: the balanced bot
## loses 2 or 3 of 10 and squads are worth their gold against towers). The second tier (0.7 s), the
## tier costs, damage, range, health and arrow speeds, every unit number and the king's numbers did
## not move.
const ROUND_TWO_TOWER_TIER_ONE_INTERVAL_S: float = 0.9  # was 0.8
const TOWER_TIER_TWO_INTERVAL_S: float = 0.7


func _map() -> MapConfig:
	return load(MAP_PATH)


func _ground(position: Vector3) -> Vector2:
	return Vector2(position.x, position.z)


func _costs_of(building_def: BuildingDef) -> Array[int]:
	var costs: Array[int] = []
	for tier: BuildingTierDef in building_def.tiers:
		costs.append(tier.cost)
	return costs


func _sizes_of(building_def: BuildingDef) -> Array[int]:
	var sizes: Array[int] = []
	for tier: BuildingTierDef in building_def.tiers:
		sizes.append(tier.squad_size)
	return sizes


func _respawns_of(building_def: BuildingDef) -> Array[float]:
	var seconds: Array[float] = []
	for tier: BuildingTierDef in building_def.tiers:
		seconds.append(tier.squad_respawn_seconds)
	return seconds


func test_both_military_buildings_cost_four_eight_and_sixteen() -> void:
	assert_eq(_costs_of(load(BARRACKS_PATH)), COSTS, "Barracks costs (D-02)")
	assert_eq(_costs_of(load(ARCHERY_PATH)), COSTS, "Archery Range costs (D-02)")


func test_squad_sizes_are_four_eight_and_fourteen_with_a_bigger_last_step() -> void:
	for path: String in [BARRACKS_PATH, ARCHERY_PATH]:
		var sizes: Array[int] = _sizes_of(load(path))
		assert_eq(sizes, SQUAD_SIZES, "%s squad sizes (D-01)" % path)
		var first_step: int = sizes[1] - sizes[0]
		var last_step: int = sizes[2] - sizes[1]
		assert_lt(
			float(last_step) / float(sizes[1]), float(first_step) / float(sizes[0]), "smaller"
		)
		assert_gt(last_step, first_step, "yet larger in magnitude")


func test_replacements_come_every_ten_seven_and_four_seconds() -> void:
	assert_eq(_respawns_of(load(BARRACKS_PATH)), RESPAWN_SECONDS, "Barracks respawn (D-05)")
	assert_eq(_respawns_of(load(ARCHERY_PATH)), RESPAWN_SECONDS, "Archery Range respawn (D-05)")


func test_the_footman_is_a_fifth_of_the_king_and_the_archer_is_frailer_with_a_longer_reach(
) -> void:
	var king: KingDef = load(KING_PATH)
	var footman: UnitDef = load(FOOTMAN_PATH)
	var archer: UnitDef = load(ARCHER_PATH)
	var grunt: EnemyDef = load(GRUNT_PATH)
	assert_eq(footman.max_health * KING_HEALTH_PER_FOOTMAN, king.max_health, "five footmen (D-06)")
	assert_eq(footman.attack_damage, FOOTMAN_DAMAGE, "a footman strikes for 100 (D-07)")
	assert_gt(footman.max_health, archer.max_health, "the archer is frailer")
	assert_gt(archer.attack_range, grunt.attack_range, "the archer outreaches a grunt")


func test_the_prototype_map_has_the_barracks_and_archery_plots_before_the_wall_plots() -> void:
	var map: MapConfig = _map()
	# D-06 (plan 04-05): four wall plots follow the ten plots of D-03, so the first 14 are fixed.
	assert_gte(map.spots.size(), PHASE_FOUR_SPOT_COUNT, "ten plots (D-03), four wall plots (D-06)")
	for index: int in range(ARCHERY_SPOT + 1, PHASE_FOUR_SPOT_COUNT):
		assert_not_null(map.spots[index].wall_run, "plot %d is a wall plot, right after" % index)
	assert_eq(PHASE_FOUR_SPOT_COUNT - WALL_PLOT_COUNT, ARCHERY_SPOT + 1, "the wall plots follow")
	assert_true(map.spots[PHASE_FOUR_SPOT_COUNT].is_castle, "the castle plot is appended next")
	assert_eq(map.spots[BARRACKS_SPOT].id, &"barracks_1", "the Barracks plot is ninth")
	assert_eq(map.spots[BARRACKS_SPOT].building_id, &"barracks", "and takes a Barracks")
	assert_eq(map.spots[ARCHERY_SPOT].id, &"archery_1", "the Archery Range plot is tenth")
	assert_eq(map.spots[ARCHERY_SPOT].building_id, &"archery_range", "and takes a Range")


func test_the_military_plots_sit_inside_the_tower_ring_and_clear_of_everything() -> void:
	var map: MapConfig = _map()
	var castle: Vector2 = _ground(map.castle_position)
	for index: int in [BARRACKS_SPOT, ARCHERY_SPOT]:
		var spot: BuildSpotDef = map.spots[index]
		var here: Vector2 = _ground(spot.position)
		var edge_gap: float = here.distance_to(castle) - map.castle_radius
		assert_gt(edge_gap, MIN_CLEARANCE_M, "%s is clear of the castle edge" % spot.id)
		for other_index: int in range(map.spots.size()):
			if other_index == index:
				continue
			var other: BuildSpotDef = map.spots[other_index]
			var apart: float = here.distance_to(_ground(other.position))
			assert_gt(apart, MIN_CLEARANCE_M, "%s is clear of %s" % [spot.id, other.id])
			if other.building_id == &"tower":
				var tower_distance: float = _ground(other.position).distance_to(castle)
				assert_lt(
					here.distance_to(castle),
					tower_distance,
					"%s is inside %s" % [spot.id, other.id]
				)


func test_round_two_slowed_the_first_tower_tier_and_nothing_else_of_the_tower() -> void:
	var tiers: Array[BuildingTierDef] = (load(TOWER_PATH) as BuildingDef).tiers
	assert_eq(tiers.size(), 2, "the tower still has two tiers")
	if tiers.size() != 2:
		return
	assert_eq(
		tiers[0].attack_interval,
		ROUND_TWO_TOWER_TIER_ONE_INTERVAL_S,
		"Round 2: tier 1 fires every 0.9 s (was 0.8 s)"
	)
	assert_eq(tiers[0].cost, 4, "tier 1 still costs 4")
	assert_eq(tiers[0].attack_damage, 300, "tier 1 still strikes for 300")
	assert_eq(tiers[0].attack_range, 9.0, "tier 1 still reaches 9 m")
	assert_eq(tiers[0].max_health, 5000, "tier 1 still has 5000 health")
	assert_eq(tiers[1].attack_interval, TOWER_TIER_TWO_INTERVAL_S, "tier 2 still fires every 0.7 s")
	assert_eq(tiers[1].cost, 6, "tier 2 still costs 6")
	assert_eq(tiers[1].attack_damage, 600, "tier 2 still strikes for 600")
