class_name CrowdOverlaySections
extends RefCounted
## The debug overlay's crowd-scale sections (ENMY-04, D-09, ROADMAP success criterion 2, plan
## 04-08): Walls (built runs, intact and broken segments, how many segments the break-or-detour rule
## weighed, the shortest time to breach), Field (the castle field's version and reach, how many
## enemies are flagged stuck and the longest streak) and Crowd (the frame time and how many enemies,
## units and arrows are drawn). Every row builder is a pure read of getters: collecting them emits
## no event, builds no goal field and changes no tick count, gold or health (T-04-19). `register`
## hooks them into a DebugOverlay after the squad section and adds the 3D flow-field gizmo under the
## map. Every row label is new, because the overlay flattens all sections into one table.

const WALLS_TITLE := "Walls"
const FIELD_TITLE := "Field"
const CROWD_TITLE := "Crowd"
## Shown where a value does not apply: no crowd at a wall, no scene to read the drawn counts from.
const NONE_TEXT := "—"
const ENEMY_VIEWS_NODE := "EnemyViews"
const UNIT_VIEWS_NODE := "UnitViews"
const PROJECTILE_VFX_NODE := "ProjectileVfx"
const MILLIS_PER_SECOND: float = 1000.0


## Registers the three sections with `overlay` (they list after the sections registered before them)
## and, when `map_root` is given, adds one FlowFieldGizmo under it that follows the overlay.
static func register(overlay: DebugOverlay, ctx: RunContext, map_root: MapRoot) -> void:
	overlay.register_section(
		WALLS_TITLE, func() -> Array: return CrowdOverlaySections.wall_rows(ctx)
	)
	overlay.register_section(
		FIELD_TITLE, func() -> Array: return CrowdOverlaySections.field_rows(ctx)
	)
	overlay.register_section(
		CROWD_TITLE, func() -> Array: return CrowdOverlaySections.crowd_rows(ctx, map_root)
	)
	if map_root == null:
		return
	var gizmo: FlowFieldGizmo = FlowFieldGizmo.new()
	gizmo.name = "FlowFieldGizmo"
	gizmo.bind(ctx, overlay)
	map_root.add_child(gizmo)


## Wall runs bought, segments standing and fallen in them, the segments the last decision pass
## weighed, and the shortest time to destruction any standing segment shows (the dash when no crowd
## is weighing a wall).
static func wall_rows(ctx: RunContext) -> Array:
	var walls: WallSystem = ctx.walls
	var decision: WallDecision = ctx.night.get_pathing().decision()
	var runs: int = 0
	var intact: int = 0
	var broken: int = 0
	var fastest: int = SimClock.MAX_TICKS
	for spot: BuildSpotDef in ctx.map.spots:
		if spot == null or spot.wall_run == null:
			continue
		var built: bool = false
		for segment: int in walls.segments_of(spot.id):
			if walls.max_health_of(segment) <= 0:
				continue
			built = true
			if walls.is_intact(segment):
				intact += 1
				fastest = mini(fastest, decision.ttd_of(segment))
			else:
				broken += 1
		runs += 1 if built else 0
	var breach_text: String = NONE_TEXT
	if fastest < SimClock.MAX_TICKS:
		breach_text = "%.1f s" % (float(fastest) * SimClock.STEP)
	return [
		["Runs built", str(runs)],
		["Segments intact", str(intact)],
		["Segments broken", str(broken)],
		["Walls evaluated", str(decision.evaluated_count())],
		["Fastest breach", breach_text],
	]


## The castle field's rebuild count, the grid's cells and the cells the field reaches (0 until a
## wall has stood), and the stuck tracker's flagged count and longest streak.
static func field_rows(ctx: RunContext) -> Array:
	var pathing: Pathing = ctx.night.get_pathing()
	var grid: NavGrid = pathing.grid()
	var field: FlowField = pathing.castle_field()
	var cells: int = grid.width() * grid.height() if grid.is_ready() else 0
	var reached: int = field.reached_count() if field != null else 0
	var stuck: StuckTracker = pathing.stuck()
	return [
		["Field version", str(pathing.field_version())],
		["Grid cells", str(cells)],
		["Reached cells", str(reached)],
		["Stuck now", str(stuck.stuck_count())],
		["Longest stuck", "%.1f s" % (float(stuck.longest_streak_ticks()) * SimClock.STEP)],
	]


## The engine's last process time in milliseconds, and how many enemies, friendly units and arrows
## the views drew (the dash for a count whose view is not in the scene, such as a bare overlay).
static func crowd_rows(_ctx: RunContext, map_root: MapRoot) -> Array:
	var frame_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * MILLIS_PER_SECOND
	var enemies: EnemyViews = _view_of(map_root, ENEMY_VIEWS_NODE) as EnemyViews
	var units: UnitViews = _view_of(map_root, UNIT_VIEWS_NODE) as UnitViews
	var arrows: ProjectileVfx = _view_of(map_root, PROJECTILE_VFX_NODE) as ProjectileVfx
	return [
		["Frame ms", "%.1f" % frame_ms],
		["Drawn enemies", str(enemies.view_count()) if enemies != null else NONE_TEXT],
		["Drawn units", str(units.view_count()) if units != null else NONE_TEXT],
		["Arrows in flight", str(arrows.live_count()) if arrows != null else NONE_TEXT],
	]


static func _view_of(map_root: MapRoot, node_name: String) -> Node:
	return map_root.get_node_or_null(node_name) if map_root != null else null
