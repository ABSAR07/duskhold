class_name DebugOverlayModel
extends RefCounted
## Read-only view model of the debug overlay (DEV-03). It is a pure function of RunContext
## getters plus registered section providers, and holds no gameplay state of its own, so it can
## never become a second source of truth (RESEARCH Pitfall 5). Phase 2 adds wave state and enemy
## paths by calling register_section instead of restructuring this class.
##
## collect() returns Array of {title: String, rows: Array of [label: String, value: String]}.

## Why a provider cannot be called (see _skip_code). Control flow branches on these codes, never on
## the message text, so rewording a message cannot change what is dropped.
enum Skip { NONE, OWNER_FREED, CALLABLE_INVALID, DECLARES_PARAMETERS }

## Titles of the sections collect() always builds itself; registered sections cannot reuse them.
const DEFAULT_TITLES: Array[String] = ["Perf", "Loop", "Agents"]
## The words that complete "debug overlay section '<title>' skipped: ..." for each Skip code. Every
## code except NONE needs a message.
const SKIP_MESSAGES: Dictionary = {
	Skip.OWNER_FREED: "its owner was freed",
	Skip.CALLABLE_INVALID: "its callable is no longer valid",
	Skip.DECLARES_PARAMETERS:
	"it declares parameters (default values count); a provider takes none",
}
## The Skip codes that never recover, so the section is dropped once named. Any code left out is
## transient: the provider is checked again on the next refresh.
const GONE_FOR_GOOD: Array[Skip] = [Skip.OWNER_FREED, Skip.CALLABLE_INVALID]

var _ctx: RunContext
## Registered sections by title: {title: {provider: Callable, owner: WeakRef or null}}. A Dictionary
## keeps insertion order, so sections show in registration order, and removing one is erase(title).
var _registered: Dictionary = {}
## The kind of problem last warned about for each title ({title: kind String}), so a skipped
## provider is reported once per problem, not on every refresh. A different problem warns afresh.
var _warned: Dictionary = {}


func _init(ctx: RunContext) -> void:
	_ctx = ctx


## Appends a section after the defaults; registering a title that is already registered replaces
## that section's provider in place, so a section never shows twice. A title that names a default
## section ("Perf", "Loop", "Agents") is refused with a warning for the same reason. `provider`
## takes no arguments and returns rows as an Array of [String, String]. It must only read
## simulation state.
##
## Callable.is_valid() only notices a freed `self` or method target, not an object that a lambda
## captured. A provider that reads an object which can be freed before the overlay (a wave manager,
## a node) must pass it as `lifetime_owner`: the section is skipped and dropped once that owner is
## freed. Without an owner the provider may only capture objects that live as long as the run
## (RunContext and what it holds), or check is_instance_valid itself.
func register_section(title: String, provider: Callable, lifetime_owner: Object = null) -> void:
	if title in DEFAULT_TITLES:
		push_warning(
			"debug overlay section '%s' not registered: the title is a default section" % title
		)
		return
	# A WeakRef, so the overlay never keeps a RefCounted owner alive; null when there is no owner.
	var owner_ref: WeakRef = weakref(lifetime_owner) if lifetime_owner != null else null
	# Assigning to an existing title keeps its position; a new title goes last.
	_registered[title] = {"provider": provider, "owner": owner_ref}
	# The one-shot warning belongs to the provider, so a replacement may warn afresh.
	_warned.erase(title)


func collect(fps: float) -> Array:
	var sections: Array = [
		_section("Perf", [["FPS", str(roundi(fps))]]),
		_section("Loop", _loop_rows()),
		_section("Agents", _agent_rows()),
	]
	# keys() is a copy: an entry that is gone for good is dropped from _registered below.
	for title: String in _registered.keys():
		var entry: Dictionary = _registered[title]
		var provider: Callable = entry["provider"]
		# A freed owner or an invalid Callable cannot be called, and a provider that needs an
		# argument cannot be called with none; skip any of them instead of raising a script error
		# on every refresh.
		var skip: Skip = _skip_code(entry)
		if skip != Skip.NONE:
			_warn_once(title, "skip %d" % skip, "skipped: %s" % SKIP_MESSAGES[skip])
			if skip in GONE_FOR_GOOD:
				# A freed owner or an invalid Callable never recovers (register_section is the way to
				# replace it), so it is named once and then forgotten, not re-checked each refresh.
				_registered.erase(title)
				_warned.erase(title)
			continue
		var rows: Variant = provider.call()
		if rows is Array:
			var clean: Array = _clean_rows(rows)
			var dropped: int = (rows as Array).size() - clean.size()
			if dropped > 0:
				# Keyed without the count, so a changing number of bad rows is still one problem.
				_warn_once(
					title,
					"malformed rows",
					"dropped %d malformed row(s); rows are [label, value]" % dropped
				)
			else:
				# A provider that works again may fail again later, and that failure is news.
				_warned.erase(title)
			sections.append(_section(title, clean))
		else:
			var returned: String = type_string(typeof(rows))
			_warn_once(
				title,
				"returned %s" % returned,
				"skipped: it returned %s, not an Array of rows" % returned
			)
	return sections


## Why an entry's provider cannot be called with no arguments, or Skip.NONE when it can. Parameters
## with default values count as arguments here, so a provider must declare none at all.
func _skip_code(entry: Dictionary) -> Skip:
	var owner_ref: WeakRef = entry["owner"]
	if owner_ref != null and owner_ref.get_ref() == null:
		return Skip.OWNER_FREED
	var provider: Callable = entry["provider"]
	if not provider.is_valid():
		return Skip.CALLABLE_INVALID
	if provider.get_argument_count() > 0:
		return Skip.DECLARES_PARAMETERS
	return Skip.NONE


## A section that silently never shows, or shows without some of its rows, is hard to notice, so
## name each problem once per failure streak. `kind` identifies the problem (a stable key, without
## counts), so a streak that changes from one problem to another names the new one too. The warning
## re-arms when the provider returns only well-formed rows again (see collect). `problem` completes
## "debug overlay section '<title>' ...".
func _warn_once(title: String, kind: String, problem: String) -> void:
	if _warned.get(title, "") == kind:
		return
	_warned[title] = kind
	push_warning("debug overlay section '%s' %s" % [title, problem])


## Keeps only rows shaped like [label, value] (as strings), so a malformed provider row is dropped
## here rather than raising a script error in the overlay on every refresh. collect reports the
## number dropped, so a provider that returns malformed rows is not mistaken for an empty one.
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
		if _ctx.buildings.current_tier(spot_id) > 0:
			count += 1
	return count
