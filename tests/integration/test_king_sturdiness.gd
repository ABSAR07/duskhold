extends GutTest
## D-04: the king is sturdy but mortal. On deep copies of the shipped data with no buildings, a king
## holding his ground beats one small group of grunts without being knocked out, and standing at
## the spawn point of the shipped night 4's largest road, with every night-4 group sent there, he is
## knocked out at least once. Every number comes from the shipped data (king.tres, grunt.tres and
## the prototype map), so a retune that breaks either half of D-04 fails here.

const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
## D-04's "small group": a group of three grunts.
const SMALL_GROUP: int = 3
const FLOOD_NIGHT: int = 4
## How far in front of the spawn point (toward the castle) the king holds against the small group.
const HOLD_DISTANCE_M: float = 5.0
const FIRST_ROAD: StringName = &"west"

var _deaths: int = 0


func _on_enemy_died(_id: int, _def_id: StringName, _pos: Vector2, _killer: StringName) -> void:
	_deaths += 1


func _xz(position: Vector3) -> Vector2:
	return Vector2(position.x, position.z)


## The shipped map copy with exactly one night made of `groups`.
func _one_night_map(groups: Array[SpawnGroupDef]) -> MapConfig:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var night: NightDef = NightDef.new()
	night.groups = groups
	var nights: Array[NightDef] = [night]
	map.nights = nights
	return map


## A bot that builds nothing and keeps the king at `point`.
func _holding_bot(point: Vector2) -> PlaytestBot:
	var bot: PlaytestBot = PlaytestBot.new()
	bot.king_mode = PlaytestBot.KING_HOLD_POINT
	bot.hold_point = point
	return bot


## Steps until the run is over, `stop_on_knockout` and the king went down, or the tick budget ends.
func _play(ctx: RunContext, bot: PlaytestBot, stop_on_knockout: bool) -> void:
	ctx.events.enemy_died.connect(_on_enemy_died)
	ctx.king.report_position(bot.hold_point)
	for _tick: int in range(SimClock.ticks(300.0)):
		bot.think(ctx)
		ctx.step()
		if ctx.run_manager.is_run_over():
			return
		if stop_on_knockout and ctx.stats.king_knockouts() > 0:
			return


func before_each() -> void:
	_deaths = 0


func test_the_king_alone_beats_a_small_group_of_grunts_without_being_knocked_out() -> void:
	var template: SpawnGroupDef = E2eSupport.shipped_prototype_map().night_def(1).groups[0]
	var group: SpawnGroupDef = template.duplicate(true)
	group.spawn_point_id = FIRST_ROAD
	group.count = SMALL_GROUP
	var groups: Array[SpawnGroupDef] = [group]
	var map: MapConfig = _one_night_map(groups)
	var spawn: Vector2 = _xz(map.find_spawn_point(FIRST_ROAD).position)
	var castle: Vector2 = _xz(map.castle_position)
	var hold: Vector2 = spawn + (castle - spawn).normalized() * HOLD_DISTANCE_M
	var ctx: RunContext = RunContext.new(map, load(TUNING_PATH), 1)
	_play(ctx, _holding_bot(hold), false)
	assert_eq(ctx.stats.outcome(), &"victory", "the night was cleared")
	assert_eq(_deaths, SMALL_GROUP, "all three grunts died")
	assert_eq(ctx.stats.king_knockouts(), 0, "and the king was never knocked out")
	assert_gt(ctx.king.get_health(), 0, "he is still standing")
	assert_eq(ctx.castle.get_health(), ctx.castle.get_max_health(), "the castle was not touched")


## The spawn point that brings the most enemies on `night_number`, the earlier one on a tie.
func _largest_road(map: MapConfig, night_number: int) -> StringName:
	var counts: Dictionary = WaveSchedule.preview_counts(map, night_number)
	var best: StringName = &""
	var best_count: int = 0
	for road: StringName in counts.keys():
		if int(counts[road]) > best_count:
			best_count = int(counts[road])
			best = road
	return best


func test_standing_in_the_shipped_night_four_wave_knocks_the_king_out() -> void:
	var map: MapConfig = E2eSupport.shipped_prototype_map()
	var road: StringName = _largest_road(map, FLOOD_NIGHT)
	assert_ne(road, &"", "night 4 has a largest road")
	var groups: Array[SpawnGroupDef] = []
	for group: SpawnGroupDef in map.night_def(FLOOD_NIGHT).groups:
		var redirected: SpawnGroupDef = group.duplicate(true)
		redirected.spawn_point_id = road
		groups.append(redirected)
	var flood_map: MapConfig = _one_night_map(groups)
	var spawn: Vector2 = _xz(flood_map.find_spawn_point(road).position)
	var ctx: RunContext = RunContext.new(flood_map, load(TUNING_PATH), 1)
	_play(ctx, _holding_bot(spawn), true)
	assert_gte(ctx.stats.king_knockouts(), 1, "a full wave knocks him out if he stands in it")
	assert_true(ctx.king.is_down(), "and he is down when the loop stops")
