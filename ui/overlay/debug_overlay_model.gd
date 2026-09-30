class_name DebugOverlayModel
extends RefCounted
## Read-only view model of the debug overlay (DEV-03). It is a pure function of RunContext
## getters plus registered section providers, and holds no gameplay state of its own, so it can
## never become a second source of truth (RESEARCH Pitfall 5). Phase 2 adds wave state and enemy
## paths by calling register_section instead of restructuring this class.
##
## collect() returns Array of {title: String, rows: Array of [label: String, value: String]}.

var _ctx: RunContext
var _registered: Array[Dictionary] = []
## Titles already warned about, so a skipped provider is reported once, not on every refresh.
var _warned: Dictionary = {}


func _init(ctx: RunContext) -> void:
	_ctx = ctx


## Appends a section after the defaults; registering a title that is already registered replaces
## that section's provider in place, so a section never shows twice. `provider` takes no arguments
## and returns rows as an Array of [String, String]. It must only read simulation state.
func register_section(title: String, provider: Callable) -> void:
	for entry: Dictionary in _registered:
		if entry["title"] == title:
			entry["provider"] = provider
			return
	_registered.append({"title": title, "provider": provider})


func collect(fps: float) -> Array:
	var sections: Array = [
		_section("Perf", [["FPS", str(roundi(fps))]]),
		_section("Loop", _loop_rows()),
		_section("Agents", _agent_rows()),
	]
	for entry: Dictionary in _registered:
		var provider: Callable = entry["provider"]
		# A freed owner leaves an invalid Callable, and a provider that needs an argument cannot be
		# called with none; skip either instead of raising a script error on every refresh.
		var skip_reason: String = _skip_reason(provider)
		if not skip_reason.is_empty():
			_warn_once(entry["title"], skip_reason)
			continue
		var rows: Variant = provider.call()
		if rows is Array:
			sections.append(_section(entry["title"], _clean_rows(rows)))
		else:
			_warn_once(
				entry["title"], "it returned %s, not an Array of rows" % type_string(typeof(rows))
			)
	return sections


## Why a provider cannot be called with no arguments, or "" when it can. Parameters with default
## values count as arguments here, so a provider must declare none at all.
func _skip_reason(provider: Callable) -> String:
	if not provider.is_valid():
		return "its callable is no longer valid"
	if provider.get_argument_count() > 0:
		return "it declares parameters (default values count); a provider takes none"
	return ""


## A section that silently never shows is hard to notice, so name it once.
func _warn_once(title: String, reason: String) -> void:
	if _warned.has(title):
		return
	_warned[title] = true
	push_warning("debug overlay section '%s' skipped: %s" % [title, reason])


## Keeps only rows shaped like [label, value] (as strings), so a malformed provider row is dropped
## here rather than raising a script error in the overlay on every refresh.
func _clean_rows(rows: Array) -> Array:
	var clean: Array = []
	for row: Variant in rows:
		if row is Array and (row as Array).size() >= 2:
			clean.append([str(row[0]), str(row[1])])
	return clean


func _section(title: String, rows: Array) -> Dictionary:
	return {"title": title, "rows": rows}


func _loop_rows() -> Array:
	var phase: RunManager.RunPhase = _ctx.run_manager.get_phase()
	var phase_name: String = str(RunManager.RunPhase.find_key(phase))
	var rows: Array = [
		["Phase", phase_name],
		["Day", str(_ctx.run_manager.get_day_number())],
		["Night", str(_ctx.run_manager.get_night_number())],
		["Gold", str(_ctx.economy.get_gold())],
		["Buildings", str(_count_buildings())],
	]
	# NIGHT_TRANSITION has no clock of its own (it passes straight through to NIGHT), so no Timer row.
	if phase == RunManager.RunPhase.NIGHT or phase == RunManager.RunPhase.DAWN:
		rows.append(["Timer", "%.1f" % _ctx.run_manager.get_phase_time_remaining()])
	return rows


func _agent_rows() -> Array:
	return [
		["Units", str(_ctx.get_unit_count())],
		["Enemies", str(_ctx.get_enemy_count())],
	]


func _count_buildings() -> int:
	var count: int = 0
	for spot_id: StringName in _ctx.buildings.spot_ids():
		if _ctx.buildings.get_instance(spot_id) != null:
			count += 1
	return count
