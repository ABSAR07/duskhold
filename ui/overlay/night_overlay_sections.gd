class_name NightOverlaySections
extends RefCounted
## The debug overlay's night sections (DEV-03 extension, ROADMAP success criterion 3): Wave (how far
## the night is), King (his health and knockouts) and Paths (what each enemy is heading for). Every
## row builder is a pure read of RunContext getters: collecting them emits no event and changes no
## tick count, gold or health (T-02-15). `register` hooks them into a DebugOverlay after the
## default sections, and adds the 3D path gizmo under the map.

const WAVE_TITLE := "Wave"
const KING_TITLE := "King"
const PATHS_TITLE := "Paths"
## Shown where a value does not apply: nothing left to spawn, no respawn countdown.
const NONE_TEXT := "—"


## Registers the three sections with `overlay` (they list after the defaults and after anything
## registered before the overlay was bound) and, when `map_root` is given, adds one EnemyPathGizmo
## under it that follows the overlay's visibility.
static func register(overlay: DebugOverlay, ctx: RunContext, map_root: MapRoot) -> void:
	overlay.register_section(
		WAVE_TITLE, func() -> Array: return NightOverlaySections.wave_rows(ctx)
	)
	overlay.register_section(
		KING_TITLE, func() -> Array: return NightOverlaySections.king_rows(ctx)
	)
	overlay.register_section(
		PATHS_TITLE, func() -> Array: return NightOverlaySections.path_rows(ctx)
	)
	if map_root == null:
		return
	var gizmo: EnemyPathGizmo = EnemyPathGizmo.new()
	gizmo.name = "EnemyPathGizmo"
	gizmo.bind(ctx, overlay)
	map_root.add_child(gizmo)


## Night n of the total, enemies spawned of the night's total, enemies alive, seconds to the next
## spawn, whether the night is cleared, and the run seed.
static func wave_rows(ctx: RunContext) -> Array:
	var night: NightSim = ctx.night
	var night_number: int = ctx.run_manager.get_night_number()
	var night_text: String = "%d of %d" % [night_number, ctx.map.nights.size()]
	if ctx.run_manager.is_timed_night() and night_number > 0:
		night_text = "%d (timed)" % night_number
	var ticks_to_next: int = night.ticks_until_next_spawn()
	var next_text: String = NONE_TEXT
	if ticks_to_next >= 0:
		next_text = "%.1f s" % (float(ticks_to_next) * SimClock.STEP)
	return [
		["Nights", night_text],
		["Spawned", "%d of %d" % [night.spawned_count(), night.total_count()]],
		["Alive", str(ctx.get_enemy_count())],
		["Next spawn", next_text],
		["Cleared", "yes" if night.is_cleared() else "no"],
		["Seed", str(ctx.run_seed)],
	]


## His health, whether he is up, the respawn countdown, and the knockouts this night / this run.
static func king_rows(ctx: RunContext) -> Array:
	var king: KingState = ctx.king
	var respawn_text: String = NONE_TEXT
	if king.is_down():
		respawn_text = "%.1f s" % king.respawn_seconds_remaining()
	return [
		["HP", "%d / %d" % [king.get_health(), king.get_max_health()]],
		["State", "Down" if king.is_down() else "Up"],
		["Respawn", respawn_text],
		["Knockouts", "%d / %d" % [king.knockouts_this_night(), king.knockouts_total()]],
	]


## How many living enemies head for the king, the castle or a building, and how many are still
## marching with no target. The four counts add up to the alive count.
static func path_rows(ctx: RunContext) -> Array:
	var enemies: EnemySystem = ctx.night.get_enemies()
	var to_king: int = 0
	var to_castle: int = 0
	var to_building: int = 0
	var marching: int = 0
	for id: int in enemies.ids():
		var target: Dictionary = enemies.target_of(id)
		var kind: StringName = target.get("kind", &"")
		if kind == PendingHits.KIND_KING:
			to_king += 1
		elif kind == PendingHits.KIND_CASTLE:
			to_castle += 1
		elif kind == PendingHits.KIND_BUILDING:
			to_building += 1
		else:
			marching += 1
	return [
		["To king", str(to_king)],
		["To castle", str(to_castle)],
		["To building", str(to_building)],
		["Marching", str(marching)],
	]
