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
##   balanced        - alternates tower and House, towers on the roads the coming night uses first,
##                     then upgrades. Since plan 04-10 (D-15) it also buys the four wall runs: the
##                     road runs right after the first tower upgrade, the ring after the last
##                     first-tier House and one upgrade of each road run after the last tower
##                     upgrade. Every other entry keeps its relative order.
##   army_balanced   - the balanced order with the Barracks (barracks_1) and the Archery Range
##                     (archery_1) and their upgrades woven in: the Barracks within the first three
##                     entries, the Range within the first six. At every night start the footmen
##                     follow the king and the archers hold their post; the king slams when at
##                     least three enemies are within the slam's radius (plan 03-11, D-08). It buys
##                     the same four wall runs since plan 04-10, the road runs right after the
##                     first Archery Range (the Range stays within the first six non-wall entries).
##   balanced_no_walls, army_balanced_no_walls
##                   - the Phase 3 orders of balanced and army_balanced, unchanged: the same builds,
##                     king, squad and slam settings and no wall. They keep the Phase 3 results
##                     and measure what the walls change (plan 04-10, D-15).

const NAMES: Array[StringName] = [
	&"no_build",
	&"greedy_economy",
	&"houses_first",
	&"towers_first",
	&"balanced",
	&"army_balanced",
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
	elif name == &"army_balanced" or name == &"army_balanced_no_walls":
		var army_walls: bool = name == &"army_balanced"
		bot.build_order = (_ARMY_BALANCED if army_walls else _ARMY_BALANCED_NO_WALLS).duplicate()
		bot.prefer_telegraphed_towers = true
		bot.night_orders = [
			{"squads": [&"barracks_1"], "verb": &"follow"},
			{"squads": [&"archery_1"], "verb": &"hold"},
		]
		bot.slam_min_enemies = _ARMY_SLAM_MIN_ENEMIES
	else:
		var balanced_walls: bool = name == &"balanced"
		bot.build_order = (_BALANCED if balanced_walls else _BALANCED_NO_WALLS).duplicate()
		bot.prefer_telegraphed_towers = true
	return bot
