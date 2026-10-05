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
## Reasons a `lifetime_owner` is refused at registration (see owner_problem). OWNER_FREED_REASON
## is also the wording for a section dropped once its owner is freed later.
const OWNER_FREED_REASON := "its owner was freed"
const OWNER_NOT_OBJECT_REASON := "its owner is not an Object"
## Why a title that names a default section is refused at registration (see title_problem).
const DEFAULT_TITLE_REASON := "the title is a default section"
## The words that complete "debug overlay section '<title>' skipped: ..." for each Skip code. Every
## code except NONE needs a message.
const SKIP_MESSAGES: Dictionary = {
	Skip.OWNER_FREED: OWNER_FREED_REASON,
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
##
## The overlay itself holds `lifetime_owner` only through a WeakRef, but the stored `provider`
## Callable is a strong reference to everything a lambda captured. So this works for an owner that
## is freed explicitly (a Node: free() or queue_free()). A RefCounted owner that the provider
## captures is kept alive by that capture: it is never freed, and the section is never dropped. To
## have a RefCounted owner end the section, capture a weakref() of it in the provider instead.
##
## `lifetime_owner` must be alive when this is called: an owner that is already freed is refused
## with a warning, like a default title, and so is a value that is not an Object at all. It is a
## Variant, not an Object, because passing a freed
## instance to an Object parameter raises a script error in the caller's frame, before this body
## could guard.
func register_section(title: String, provider: Callable, lifetime_owner: Variant = null) -> void:
	var problem: String = title_problem(title)
	if problem == "":
		problem = owner_problem(lifetime_owner)
	if problem != "":
		warn_not_registered(title, problem)
		return
	# Assigning to an existing title keeps its position; a new title goes last.
	_registered[title] = {"provider": provider, "owner": owner_ref(lifetime_owner)}
	# The one-shot warning belongs to the provider, so a replacement may warn afresh.
	_warned.erase(title)


## Why a section title cannot be used, or "" when it can: only a title that names a default section
## is refused. The overlay view checks a pre-bind registration with this too, so both paths refuse
## the same mistake at the same moment, in the same words.
static func title_problem(title: String) -> String:
	return DEFAULT_TITLE_REASON if title in DEFAULT_TITLES else ""


## Why a `lifetime_owner` cannot be used, or "" when it can (no owner at all is fine). The overlay
## view checks a pre-bind registration with this too, so both paths refuse an owner for the same
## reasons in the same words. typeof, not `!= null`: a freed instance compares equal to null, so it
## must be told apart from "no owner" here, and a non-Object (an int, a String) is a caller mistake
## that must not be reported as a freed owner.
static func owner_problem(lifetime_owner: Variant) -> String:
	if typeof(lifetime_owner) == TYPE_NIL:
		return ""
	if typeof(lifetime_owner) != TYPE_OBJECT:
		return OWNER_NOT_OBJECT_REASON
	if not is_instance_valid(lifetime_owner):
		return OWNER_FREED_REASON
	return ""


## A WeakRef to a usable `lifetime_owner` (see owner_problem), so the overlay's own reference to a
## RefCounted owner never keeps it alive; null when there is no owner. The provider Callable is
## separate: whatever it captures stays alive (see register_section).
static func owner_ref(lifetime_owner: Variant) -> WeakRef:
	return weakref(lifetime_owner) if typeof(lifetime_owner) == TYPE_OBJECT else null


## The one warning for a refused registration, so every refusal reads the same. `reason` completes
## "debug overlay section '<title>' not registered: ...".
static func warn_not_registered(title: String, reason: String) -> void:
	push_warning("debug overlay section '%s' not registered: %s" % [title, reason])


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
	var owner_weak: WeakRef = entry["owner"]
	if owner_weak != null and owner_weak.get_ref() == null:
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


## Keeps only rows shaped like [label, value] (exactly two entries, as strings; a longer row is a
## provider mistake and is dropped, not truncated), so a malformed provider row is dropped
## here rather than raising a script error in the overlay on every refresh. collect reports the
## number dropped, so a provider that returns malformed rows is not mistaken for an empty one.
func _clean_rows(rows: Array) -> Array:
	var clean: Array = []
	for row: Variant in rows:
		if row is Array and (row as Array).size() == 2:
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
	# NIGHT_TRANSITION has no clock of its own (it passes straight through to NIGHT), and a real
	# night ends when its wave is cleared, not on a clock, so only the timed night and dawn show one.
	var timed_night: bool = phase == RunManager.RunPhase.NIGHT and _ctx.run_manager.is_timed_night()
	if timed_night or phase == RunManager.RunPhase.DAWN:
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
