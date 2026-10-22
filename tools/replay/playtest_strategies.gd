class_name PlaytestStrategies
extends RefCounted
## The named bot strategies of the balance report (D-18). Each is a PlaytestBot configured with a
## build order for the shipped prototype map (five House plots house_1..house_5, three tower plots
## tower_1..tower_3, the barracks_1 and archery_1 plots and the four wall plots wall_west,
## wall_east, wall_north and wall_ring) and a king mode. A repeated spot id is an upgrade. The bots
## build without riding to the plots and the defending king reacts perfectly, so the report treats
## their results as a measure of the data, not of a player. tools/ is excluded from the export.
##   no_build        - builds nothing and keeps the king at the castle: must lose early.
##   greedy_economy  - Houses and House upgrades only: richer each dawn, but nothing to hold the
##                     roads, so it must lose around the middle nights (D-10).
##   houses_first    - three Houses, then the towers, then upgrades, then the last Houses.
##   towers_first    - the towers first, then Houses, then upgrades.
##   balanced        - the order for the day of Phase 5 (plan 05-11): alternates tower and House as
##                     before, buys the Fishing Harbor right after the first tower, the castle
##                     (castle_plot, three upgrades with one deterministic card pick each) right
##                     after the second, then Tower II, the Gold Mine, the Mill with its Fields, the
##                     four wall runs and the two Shrines. A locked entry (a top tier before castle
##                     II, a Field before the Mill) is deferred by the bot, never waited for
##                     (Pitfall 1). full_idle plays this bot.
##   army_balanced   - the army order for the same day: the Barracks within the first three
##                     entries, the Range within the first six, then the Harbor, the Mine, the
##                     castle with its picks and the rest of the Phase 4 army order (walls, the
##                     Mill and its Fields, the Shrines). The king slams when at least three
##                     enemies are within the slam's radius (plan 03-11, D-08); at every night
##                     start the footmen follow the king and the archers hold their post.
##   balanced_no_castle, army_balanced_no_castle
##                   - the Phase 4 orders of balanced and army_balanced, unchanged (plan 05-11
##                     renamed them): the four wall runs, no castle and none of the new buildings.
##                     With the castle gate on the shipped map these bots never buy a top tier, so
##                     they measure what the gate costs a bot that ignores the castle.
##   balanced_no_walls, army_balanced_no_walls
##                   - the Phase 3 orders of balanced and army_balanced, unchanged: the same builds,
##                     king, squad and slam settings and no wall. They measured what the walls
##                     change (plan 04-10, D-15) and now also keep the gate's cost on the Phase 3
##                     orders visible.

const NAMES: Array[StringName] = [
	&"no_build",
	&"greedy_economy",
	&"houses_first",
	&"towers_first",
	&"balanced",
	&"army_balanced",
	&"balanced_no_castle",
	&"army_balanced_no_castle",
	&"balanced_no_walls",
	&"army_balanced_no_walls",
]
## The king slams when this many enemies stand inside the slam's radius.
const _ARMY_SLAM_MIN_ENEMIES: int = 3

const _GREEDY_ECONOMY: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
]
const _HOUSES_FIRST: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"house_3",
	&"tower_1",
	&"tower_2",
	&"tower_3",
	&"house_1",
	&"house_2",
	&"house_3",
	&"tower_1",
	&"tower_2",
	&"tower_3",
	&"house_4",
	&"house_5",
	&"house_4",
	&"house_5",
]
const _TOWERS_FIRST: Array[StringName] = [
	&"tower_1",
	&"tower_2",
	&"tower_3",
	&"house_1",
	&"house_2",
	&"house_3",
	&"tower_1",
	&"tower_2",
	&"tower_3",
	&"house_4",
	&"house_5",
	&"house_1",
	&"house_2",
	&"house_3",
]
## The Phase 3 order of the balanced bot (plan 04-10 kept it as balanced_no_walls).
const _BALANCED_NO_WALLS: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"house_3",
	&"tower_1",
	&"tower_2",
	&"tower_3",
	&"tower_1",
	&"house_4",
	&"tower_2",
	&"house_5",
	&"tower_3",
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
]
## The Phase 3 order of the army bot (plan 04-10 kept it as army_balanced_no_walls).
const _ARMY_BALANCED_NO_WALLS: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"barracks_1",
	&"house_3",
	&"tower_1",
	&"archery_1",
	&"tower_2",
	&"house_4",
	&"tower_3",
	&"barracks_1",
	&"archery_1",
	&"house_5",
	&"tower_1",
	&"tower_2",
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
	&"barracks_1",
	&"archery_1",
	&"tower_3",
]

## The balanced order with the four wall runs (plan 04-10, D-15). The first attempt, each road run
## right after that road's first tower, cost the bot 6 of its 10 seeds (4 wins): the bots earn about
## 22 gold in a whole run, a barricade costs a House, and every wall bought early delays a tower.
## So, as D-15 allows, the entries moved later (a measuring choice, searched in 04-BALANCE-REPORT):
## the three road runs right after the first tower upgrade, the ring after the last first-tier
## House (house_5), and one upgrade of each road run after the last tower upgrade. Every other
## entry keeps its relative order. The entries past what the bot can pay for are never reached.
const _BALANCED: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"house_3",
	&"tower_1",
	&"tower_2",
	&"tower_3",
	&"tower_1",
	&"wall_west",
	&"wall_east",
	&"wall_north",
	&"house_4",
	&"tower_2",
	&"house_5",
	&"wall_ring",
	&"tower_3",
	&"wall_west",
	&"wall_east",
	&"wall_north",
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
]
## The army order with the same four wall runs, moved later for the same reason: the army bot earns
## about 15 gold a run, so the three road runs sit right after the first Archery Range (earlier,
## one barricade before it cost 6 of 10 seeds), the ring after house_5 and the upgrades at the end.
const _ARMY_BALANCED: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"barracks_1",
	&"house_3",
	&"tower_1",
	&"archery_1",
	&"wall_west",
	&"wall_east",
	&"wall_north",
	&"tower_2",
	&"house_4",
	&"tower_3",
	&"barracks_1",
	&"archery_1",
	&"house_5",
	&"wall_ring",
	&"tower_1",
	&"tower_2",
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
	&"barracks_1",
	&"archery_1",
	&"tower_3",
	&"wall_west",
	&"wall_east",
	&"wall_north",
]
## The balanced order for the day of Phase 5 (plan 05-11, see the search log in
## 05-BALANCE-REPORT.md). The Phase 4 entries keep their relative order. The Harbor follows the
## first tower (a Harbor pays a gold a boat from its first dawn, the best price per gold on the
## map), the castle follows the second tower and comes before Tower II, the one top tier this order
## buys (it needs castle II), and the Mine, the Mill with its Fields, the road walls, the Shrines
## and the castle's later tiers follow. The entries past what the bot can pay for are never
## reached.
const _BALANCED_CASTLE: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"house_3",
	&"tower_1",
	&"harbor_1",
	&"tower_2",
	&"castle_plot",
	&"tower_3",
	&"tower_1",
	&"gold_mine_1",
	&"wall_west",
	&"wall_east",
	&"wall_north",
	&"mill_1",
	&"field_1",
	&"field_2",
	&"house_4",
	&"tower_2",
	&"house_5",
	&"wall_ring",
	&"tower_3",
	&"field_3",
	&"shrine_west",
	&"castle_plot",
	&"wall_west",
	&"wall_east",
	&"wall_north",
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
	&"shrine_east",
	&"castle_plot",
]
## The army order for the day of Phase 5 (plan 05-11): the Barracks within
## the first three non-wall entries and the Range within the first six, as before.
const _ARMY_CASTLE: Array[StringName] = [
	&"house_1",
	&"house_2",
	&"barracks_1",
	&"house_3",
	&"tower_1",
	&"archery_1",
	&"harbor_1",
	&"gold_mine_1",
	&"castle_plot",
	&"wall_west",
	&"wall_east",
	&"wall_north",
	&"tower_2",
	&"house_4",
	&"tower_3",
	&"barracks_1",
	&"archery_1",
	&"mill_1",
	&"field_1",
	&"field_2",
	&"house_5",
	&"wall_ring",
	&"tower_1",
	&"tower_2",
	&"field_3",
	&"shrine_west",
	&"castle_plot",
	&"house_1",
	&"house_2",
	&"house_3",
	&"house_4",
	&"house_5",
	&"barracks_1",
	&"archery_1",
	&"tower_3",
	&"shrine_east",
	&"castle_plot",
	&"wall_west",
	&"wall_east",
	&"wall_north",
]
## The cards each castle-aware bot takes, one per castle tier (tiers II, III, IV), in pick order.
## balanced leans on buildings, towers and gold; army_balanced on the king and the squads.
const _BALANCED_CASTLE_PICKS: Array[StringName] = [&"masons", &"engineers", &"golden_age"]
const _ARMY_CASTLE_PICKS: Array[StringName] = [&"commander", &"war_horns", &"iron_discipline"]


## A fresh bot for `name`, or null when the name is not in NAMES.
static func make(name: StringName) -> PlaytestBot:
	if not NAMES.has(name):
		return null
	var bot: PlaytestBot = PlaytestBot.new()
	bot.king_mode = PlaytestBot.KING_DEFEND_NEAREST_THREAT
	if name == &"no_build":
		bot.king_mode = PlaytestBot.KING_IDLE_AT_CASTLE
	elif name == &"greedy_economy":
		bot.build_order = _GREEDY_ECONOMY.duplicate()
	elif name == &"houses_first":
		bot.build_order = _HOUSES_FIRST.duplicate()
	elif name == &"towers_first":
		bot.build_order = _TOWERS_FIRST.duplicate()
	elif _is_army(name):
		bot.build_order = _army_order(name).duplicate()
		if name == &"army_balanced":
			bot.card_picks = _ARMY_CASTLE_PICKS.duplicate()
		bot.prefer_telegraphed_towers = true
		bot.night_orders = [
			{"squads": [&"barracks_1"], "verb": &"follow"},
			{"squads": [&"archery_1"], "verb": &"hold"},
		]
		bot.slam_min_enemies = _ARMY_SLAM_MIN_ENEMIES
	else:
		bot.build_order = _balanced_order(name).duplicate()
		if name == &"balanced":
			bot.card_picks = _BALANCED_CASTLE_PICKS.duplicate()
		bot.prefer_telegraphed_towers = true
	return bot


static func _is_army(name: StringName) -> bool:
	return (
		name == &"army_balanced"
		or name == &"army_balanced_no_castle"
		or name == &"army_balanced_no_walls"
	)


static func _army_order(name: StringName) -> Array[StringName]:
	if name == &"army_balanced":
		return _ARMY_CASTLE
	return _ARMY_BALANCED if name == &"army_balanced_no_castle" else _ARMY_BALANCED_NO_WALLS


static func _balanced_order(name: StringName) -> Array[StringName]:
	if name == &"balanced":
		return _BALANCED_CASTLE
	return _BALANCED if name == &"balanced_no_castle" else _BALANCED_NO_WALLS
