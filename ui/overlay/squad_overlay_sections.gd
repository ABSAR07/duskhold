class_name SquadOverlaySections
extends RefCounted
## The debug overlay's Squads section (DEV-03 extension, plan 03-05): one row per squad in creation
## order with its alive / max, its stance (the verb it is carrying out when there is one, else its
## resting stance) and the whole seconds to its next replacement. Every row builder is a pure read
## of RunContext getters: collecting them emits no event and changes no tick count, gold or
## health (T-03-09). `register` hooks the section into a DebugOverlay after the night sections.

const SQUADS_TITLE := "Squads"
## Shown where a value does not apply: no squad yet, no replacement coming.
const NONE_TEXT := "—"
## Every squad row label starts with this, so the overlay's flattened rows never collide with the
## other sections (the 02-08 "Nights" precedent).
const ROW_PREFIX := "Squad "
## The row label when no squad exists yet.
const EMPTY_LABEL := "Squad"
## Shown for a squad whose building is rubble: its countdown is frozen, so no time is given.
const RUBBLE_TEXT := "rubble"
## Guards the ceiling of a seconds value that is a float sum of ticks.
const SECONDS_EPSILON: float = 0.000001


## Registers the Squads section with `overlay`; it lists after the sections registered before it.
static func register(overlay: DebugOverlay, ctx: RunContext, _map_root: MapRoot) -> void:
	overlay.register_section(
		SQUADS_TITLE, func() -> Array: return SquadOverlaySections.squad_rows(ctx)
	)


## One ["Squad <id>", "<alive>/<max>  <stance>  <seconds>"] row per squad in creation order; one
## ["Squad", dash] row when there is no squad.
static func squad_rows(ctx: RunContext) -> Array:
	var rows: Array = []
	var squads: SquadSystem = ctx.squads
	for squad_id: StringName in squads.squad_ids():
		var alive: int = squads.alive_count(squad_id)
		var max_alive: int = squads.max_count(squad_id)
		var verb: StringName = squads.executing_verb(squad_id)
		var stance: StringName = verb if verb != &"" else squads.resting_stance(squad_id)
		var value: String = (
			"%d/%d  %s  %s"
			% [alive, max_alive, stance, _next_text(ctx, squad_id, alive, max_alive)]
		)
		rows.append([ROW_PREFIX + String(squad_id), value])
	if rows.is_empty():
		rows.append([EMPTY_LABEL, NONE_TEXT])
	return rows


## The next replacement as whole seconds rounded up ("8 s"), the dash when none is coming, or the
## rubble word when the building fell.
static func _next_text(ctx: RunContext, squad_id: StringName, alive: int, max_alive: int) -> String:
	if alive >= max_alive:
		return NONE_TEXT
	if ctx.buildings.is_destroyed(squad_id):
		return RUBBLE_TEXT
	var seconds: float = ctx.squads.replacement_seconds_left(squad_id)
	if seconds <= 0.0:
		return NONE_TEXT
	return "%d s" % ceili(seconds - SECONDS_EPSILON)
