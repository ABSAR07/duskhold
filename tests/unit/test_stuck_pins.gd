extends GutTest
## PLAT-01 (plan 04-20, exact_port_rules 7): the stuck tracker's flags and streaks pinned on the
## GDScript tracker that shipped before NativeStuck existed. Two whole runs go through the
## read-only on_tick hooks of plans 04-23: the walls replay scenario (1961 ticks) and the 300-enemy
## gate stress. After every step the hook feeds the tick, the stuck ids, the stuck count, the
## longest streak and the streak of every living enemy (in ascending id) of the run's
## StuckTracker into one HashingContext per run; the sha256 of each run is compared with a pinned
## hex string. The pins were computed on the GDScript tracker and are never edited: the native
## tracker must reproduce them unchanged. The hooks only read, so the golden digests do not move
## (test_enemy_trace and the replay wrappers prove it).

const WALLS_SEED: int = 1
const GATE_SEED: int = 1
const PINS: Dictionary = {
	"walls": "e7b44adde1ee0803106913ce6d54c7b68c08044b105ecd9aa5d843429553d14c",
	"gate": "849437d5923b0215dcee4492a96480b1b34b52381660cf8fc999cf17571ea668",
}


## A read-only on_tick observer: hashes what the tracker says after each step.
class Watcher:
	extends RefCounted

	var ticks: int = 0
	var flagged_ticks: int = 0
	var highest_streak: int = 0
	var _context: HashingContext = HashingContext.new()

	func _init() -> void:
		_context.start(HashingContext.HASH_SHA256)

	## Called by the driver with the RunContext right after every step.
	func record(ctx: RunContext) -> void:
		var tracker: StuckTracker = ctx.night.get_pathing().stuck()
		var enemies: EnemySystem = ctx.night.get_enemies()
		var numbers: PackedInt64Array = PackedInt64Array(
			[ctx.tick_count, tracker.stuck_count(), tracker.longest_streak_ticks()]
		)
		numbers.append_array(tracker.stuck_ids())
		for id: int in enemies.ids():
			if enemies.is_alive(id):
				var streak: int = tracker.streak_of(id)
				numbers.append(id)
				numbers.append(streak)
				highest_streak = maxi(highest_streak, streak)
		_context.update(numbers.to_byte_array())
		ticks += 1
		if tracker.stuck_count() > 0:
			flagged_ticks += 1

	func digest() -> String:
		return _context.finish().hex_encode()


## {digest, ticks, flagged_ticks, highest_streak} of the walls replay.
static func walls_run() -> Dictionary:
	var watcher: Watcher = Watcher.new()
	ReplayScenarios.run(&"walls", WALLS_SEED, Callable(watcher, "record"))
	return summary_of(watcher)


## {digest, ticks, flagged_ticks, highest_streak} of the gate stress.
static func gate_run() -> Dictionary:
	var watcher: Watcher = Watcher.new()
	var map: MapConfig = load(GateStress.STRESS_MAP) as MapConfig
	GateStress.run(map, GATE_SEED, GateStress.DEFAULT_MAX_SECONDS, Callable(watcher, "record"))
	return summary_of(watcher)


static func summary_of(watcher: Watcher) -> Dictionary:
	return {
		"digest": watcher.digest(),
		"ticks": watcher.ticks,
		"flagged_ticks": watcher.flagged_ticks,
		"highest_streak": watcher.highest_streak,
	}


func test_the_walls_replay_is_watched_as_pinned() -> void:
	var run: Dictionary = walls_run()
	assert_eq(run["digest"], PINS.get("walls", ""), "the walls run's flags and streaks")


func test_the_gate_stress_is_watched_as_pinned() -> void:
	var run: Dictionary = gate_run()
	assert_eq(run["digest"], PINS.get("gate", ""), "the gate run's flags and streaks")


func test_the_pins_are_present_and_differ() -> void:
	assert_eq(PINS.size(), 2, "one pin per run")
	assert_ne(PINS.get("walls", "a"), PINS.get("gate", "b"), "the two runs read differently")


func test_the_runs_exercise_streaks_and_the_gate_flags_enemies_for_a_while() -> void:
	var walls: Dictionary = walls_run()
	assert_eq(walls["ticks"], 1961, "the walls run is 1961 ticks")
	assert_gt(int(walls["highest_streak"]), 0, "some walls enemy waited")
	assert_gt(int(walls["flagged_ticks"]), 0, "and the walls run flagged some enemy")
	var gate: Dictionary = gate_run()
	assert_eq(gate["ticks"], 658, "the gate run is 658 ticks")
	assert_gt(int(gate["highest_streak"]), 90, "a gate enemy waited past the 3 s threshold")
	assert_gt(int(gate["flagged_ticks"]), 0, "and was flagged")
