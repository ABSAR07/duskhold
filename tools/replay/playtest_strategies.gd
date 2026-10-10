class_name PlaytestStrategies
extends RefCounted
## The named bot strategies of the balance report (D-18). Each is a PlaytestBot configured with a
## build order for the shipped prototype map (five House plots house_1..house_5, three tower plots
## tower_1..tower_3) and a king mode. A repeated spot id is an upgrade. The bots build without
## riding to the plots and the defending king reacts perfectly, so the report treats their results
## as a measure of the data, not of a player. tools/ is excluded from the export.
##   no_build        - builds nothing and keeps the king at the castle: must lose early.
##   greedy_economy  - Houses and House upgrades only: richer each dawn, but nothing to hold the
##                     roads, so it must lose around the middle nights (D-10).
##   houses_first    - three Houses, then the towers, then upgrades, then the last Houses.
##   towers_first    - the towers first, then Houses, then upgrades.
##   balanced        - alternates tower and House, towers on the roads the coming night uses first,
##                     then upgrades.
##   army_balanced   - the balanced order with the Barracks (barracks_1) and the Archery Range
##                     (archery_1) and their upgrades woven in: the Barracks within the first three
##                     entries, the Range within the first six. At every night start the footmen
##                     follow the king and the archers hold their post; the king slams when at
##                     least three enemies are within the slam's radius (plan 03-11, D-08).

const NAMES: Array[StringName] = [
	&"no_build", &"greedy_economy", &"houses_first", &"towers_first", &"balanced", &"army_balanced"
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
const _BALANCED: Array[StringName] = [
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
const _ARMY_BALANCED: Array[StringName] = [
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
	elif name == &"army_balanced":
		bot.build_order = _ARMY_BALANCED.duplicate()
		bot.prefer_telegraphed_towers = true
		bot.night_orders = [
			{"squads": [&"barracks_1"], "verb": &"follow"},
			{"squads": [&"archery_1"], "verb": &"hold"},
		]
		bot.slam_min_enemies = _ARMY_SLAM_MIN_ENEMIES
	else:
		bot.build_order = _BALANCED.duplicate()
		bot.prefer_telegraphed_towers = true
	return bot
