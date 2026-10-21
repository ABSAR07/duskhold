class_name GoalFieldCache
extends RefCounted
## A small cache of flow fields toward goals other than the castle (ENMY-04, RESEARCH Pattern 8):
## the points, slots and targets a squad or the bot king walks to behind a wall. Goals that fall in
## one goal_quantum square share a field; a request past the build budget gets no field and the
## caller takes the straight step for that tick (T-04-15).
##
## Bounded and deterministic: at most field_cache_size entries, the oldest inserted evicted first,
## at most field_builds_per_tick builds (new or refreshed) per tick, a field older than
## field_refresh_seconds rebuilt on its next request, and every field dropped when the grid is
## rebuilt. The entries sit in an insertion-order Array and are searched in that order; no
## Dictionary is iterated. Pure RefCounted code under simulation/ (DR-1 to DR-10).

var _grid: NavGrid
var _tuning: NavTuning
var _entries: Array[Entry] = []
## The tick the build counter belongs to, and the builds spent in it.
var _budget_tick: int = -1
var _builds: int = 0
var _refresh_ticks: int = 0


func _init(grid: NavGrid, tuning: NavTuning) -> void:
	_grid = grid
	_tuning = tuning
	_refresh_ticks = SimClock.ticks(tuning.field_refresh_seconds)


## The key of the goal-quantum square holding `goal`: goals with one key share a field.
static func key_of(goal: Vector2, quantum: float) -> int:
	return CellKey.pack(floori(goal.x / quantum), floori(goal.y / quantum))


## How many fields the cache holds.
func size() -> int:
	return _entries.size()


## The field toward `goal` (a target of radius `goal_radius`) at `tick`, or null when the grid is
## not built or this tick's build budget is spent and no usable field is cached. A field built for
## an older goal in the same quantum square is served as is until it is refreshed.
func field_for(goal: Vector2, goal_radius: float, tick: int) -> FlowField:
	if not _grid.is_ready():
		return null
	if tick != _budget_tick:
		_budget_tick = tick
		_builds = 0
	var key: int = key_of(goal, _tuning.goal_quantum)
	var entry: Entry = _find(key)
	if entry != null and _is_usable(entry, tick):
		return entry.field
	if _builds >= maxi(_tuning.field_builds_per_tick, 1):
		if entry != null and entry.grid_version == _grid.version():
			return entry.field
		return null
	_builds += 1
	if entry == null:
		entry = _insert(key)
	entry.field.build(_grid, goal, goal_radius, _tuning.goal_margin)
	entry.built_tick = tick
	entry.grid_version = _grid.version()
	return entry.field


## True while the entry was built for the grid as it is and is younger than the refresh time.
func _is_usable(entry: Entry, tick: int) -> bool:
	if entry.grid_version != _grid.version():
		return false
	var age: int = tick - entry.built_tick
	return age >= 0 and age <= _refresh_ticks


func _find(key: int) -> Entry:
	for entry: Entry in _entries:
		if entry.key == key:
			return entry
	return null


## Adds an entry for `key`, evicting the oldest inserted one when the cache is full.
func _insert(key: int) -> Entry:
	var capacity: int = maxi(_tuning.field_cache_size, 1)
	while _entries.size() >= capacity:
		_entries.remove_at(0)
	var entry: Entry = Entry.new()
	entry.key = key
	entry.field = FlowField.new()
	_entries.append(entry)
	return entry


## One cached field.
class Entry:
	extends RefCounted
	var key: int = 0
	var field: FlowField
	var built_tick: int = 0
	var grid_version: int = -1
