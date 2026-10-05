class_name WaveSchedule
extends RefCounted
## One night's spawn list, expanded from its NightDef into integer night ticks (DR-3). The order is
## total: (tick, group index, index within the group), so spawns due on the same tick always happen
## in the same order and the unstable sort cannot reorder them (DR-6).

## Upper bound on one group's count: a group may fill a whole night but no more, so the group cap
## and the night cap (MapConfig.MAX_ENEMIES_PER_NIGHT, threat T-02-04) are one number and cannot
## disagree.
const MAX_GROUP_COUNT: int = MapConfig.MAX_ENEMIES_PER_NIGHT

var _entries: Array[Entry] = []
var _cursor: int = 0


func _init(map: MapConfig, night_number: int) -> void:
	var night: NightDef = map.night_def(night_number)
	if night == null:
		return
	var allowances: Array[int] = _allowances(map, night, true)
	for group_index: int in range(night.groups.size()):
		var group: SpawnGroupDef = night.groups[group_index]
		if allowances[group_index] <= 0:
			continue
		var first_tick: int = SimClock.ticks(group.start_delay_seconds)
		var gap: int = SimClock.ticks(group.interval_seconds)
		for index: int in range(allowances[group_index]):
			var entry: Entry = Entry.new()
			entry.tick = first_tick + index * gap
			entry.group_index = group_index
			entry.index = index
			entry.spawn_point_id = group.spawn_point_id
			entry.enemy_id = group.enemy_id
			_entries.append(entry)
	_entries.sort_custom(_before)


## spawn_point_id -> enemies that night brings from it, in MapConfig spawn-point order, entries
## above 0 only. Empty for a night number outside 1..nights.size(). Pure.
static func preview_counts(map: MapConfig, night_number: int) -> Dictionary:
	var counts: Dictionary = {}
	var night: NightDef = map.night_def(night_number)
	if night == null:
		return counts
	var allowances: Array[int] = _allowances(map, night, false)
	for spawn_point: SpawnPointDef in map.spawn_points:
		if spawn_point == null:
			continue
		var total: int = 0
		for group_index: int in range(night.groups.size()):
			var group: SpawnGroupDef = night.groups[group_index]
			if group != null and group.spawn_point_id == spawn_point.id:
				total += allowances[group_index]
		if total > 0:
			counts[spawn_point.id] = total
	return counts


## How many enemies each group of the night may spawn, by group index. A group the night cannot play
## (empty, or at an unknown spawn point, or with an unknown enemy when `needs_enemy`) gets 0 and
## takes nothing from the budget. The groups share one night budget,
## MapConfig.MAX_ENEMIES_PER_NIGHT, in group order, so a bad or hostile data file cannot spawn more
## than a night may hold. Both the schedule and the preview use this, so the telegraph and the
## night agree. Pure.
static func _allowances(map: MapConfig, night: NightDef, needs_enemy: bool) -> Array[int]:
	var allowances: Array[int] = []
	var budget: int = MapConfig.MAX_ENEMIES_PER_NIGHT
	for group: SpawnGroupDef in night.groups:
		var playable: bool = group != null and map.find_spawn_point(group.spawn_point_id) != null
		if playable and needs_enemy:
			playable = map.find_enemy(group.enemy_id) != null
		var allowed: int = 0
		if playable:
			allowed = mini(mini(maxi(group.count, 0), MAX_GROUP_COUNT), budget)
		budget -= allowed
		allowances.append(allowed)
	return allowances


## Removes and returns every entry due at `night_tick` or earlier, in order, as Entry objects.
func take_due(night_tick: int) -> Array:
	var due: Array = []
	while _cursor < _entries.size() and _entries[_cursor].tick <= night_tick:
		due.append(_entries[_cursor])
		_cursor += 1
	return due


func total_count() -> int:
	return _entries.size()


func spawned_count() -> int:
	return _cursor


## True once every entry has been handed out.
func is_finished() -> bool:
	return _cursor >= _entries.size()


## Ticks until the next spawn is due (0 when due now); -1 once the schedule is finished.
func ticks_until_next(night_tick: int) -> int:
	if is_finished():
		return -1
	return maxi(_entries[_cursor].tick - night_tick, 0)


func _before(a: Entry, b: Entry) -> bool:
	if a.tick != b.tick:
		return a.tick < b.tick
	if a.group_index != b.group_index:
		return a.group_index < b.group_index
	return a.index < b.index


## One scheduled spawn.
class Entry:
	extends RefCounted
	var tick: int = 0
	var group_index: int = 0
	var index: int = 0
	var spawn_point_id: StringName = &""
	var enemy_id: StringName = &""
