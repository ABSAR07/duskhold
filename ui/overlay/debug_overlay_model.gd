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


func _init(ctx: RunContext) -> void:
	_ctx = ctx


## Appends a section after the defaults. `provider` takes no arguments and returns rows as an
## Array of [String, String]. It must only read simulation state.
func register_section(title: String, provider: Callable) -> void:
	_registered.append({"title": title, "provider": provider})


func collect(fps: float) -> Array:
	var sections: Array = [
		_section("Perf", [["FPS", str(roundi(fps))]]),
		_section("Loop", _loop_rows()),
		_section("Agents", _agent_rows()),
	]
	for entry: Dictionary in _registered:
		var provider: Callable = entry["provider"]
		sections.append(_section(entry["title"], provider.call()))
	return sections


func _section(title: String, rows: Array) -> Dictionary:
	return {"title": title, "rows": rows}


func _loop_rows() -> Array:
	var phase_name: String = RunManager.RunPhase.keys()[_ctx.run_manager.get_phase()]
	return [
		["Phase", phase_name],
		["Gold", str(_ctx.economy.get_gold())],
		["Buildings", str(_count_buildings())],
	]


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
