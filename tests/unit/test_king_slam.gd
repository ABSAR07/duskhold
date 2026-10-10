extends GutTest
## KING-04, D-17, D-19: the weapon's active ability on KingState + EnemySystem + PendingHits +
## CommandProcessor, plus the day, dawn and run-over edges through a RunContext on the shipped
## map. The slam numbers (radius 4, damage 4, cooldown 9 s) are set on the test's own weapon, so
## nothing here depends on a later retune of sword.tres; the shipped data is pinned elsewhere.

const GRUNT_PATH := "res://data/enemies/grunt.tres"
const MAP_PATH := "res://data/maps/prototype_map.tres"
const TUNING_PATH := "res://data/tuning/loop_tuning.tres"
const KING_PATH := "res://data/king/king.tres"
const RADIUS: float = 4.0
const DAMAGE: int = 4
const COOLDOWN_S: float = 9.0
const SPAWN := Vector2.ZERO
## Outside every reach in these tests, so the passive attack never fires and only the slam acts.
const NO_PASSIVE_RANGE: float = 0.1
const TOUGH_HEALTH: int = 100000

var _grunt: EnemyDef
var _events: SimEvents
var _enemies: EnemySystem
var _hits: PendingHits
var _king: KingState
var _commands: CommandProcessor
var _weapon: WeaponDef
var _ctx: RunContext


func before_each() -> void:
	_grunt = load(GRUNT_PATH)
	_build(_slam_weapon())


func _slam_weapon() -> WeaponDef:
	var weapon: WeaponDef = WeaponDef.new()
	weapon.id = &"test_sword"
	weapon.attack_range = NO_PASSIVE_RANGE
	weapon.slam_radius = RADIUS
	weapon.slam_damage = DAMAGE
	weapon.slam_cooldown_seconds = COOLDOWN_S
	return weapon


## A king with `weapon` on his own events, and a real command gate (a RunContext supplies the
## economy, buildings and run manager the gate needs) that is told about this king.
func _build(weapon: WeaponDef) -> void:
	_weapon = weapon
	_ctx = RunContext.new(load(MAP_PATH), load(TUNING_PATH), 1)
	var def: KingDef = (load(KING_PATH) as KingDef).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.weapon = weapon
	_events = _ctx.events
	_enemies = EnemySystem.new(_events)
	_hits = PendingHits.new()
	_king = KingState.new(def, SPAWN, _events)
	_king.begin_night()
	_commands = CommandProcessor.new(
		_ctx.economy, _ctx.buildings, _ctx.run_manager, _events, _king, _ctx.squads
	)


## Loses the run: the castle falls during a night, the only way the defeat is legal.
func _end_run() -> void:
	assert_true(_ctx.run_manager.start_night(), "the night starts")
	assert_true(_ctx.run_manager.end_run_in_defeat(), "and the castle falls")


func _tough_grunt() -> EnemyDef:
	var def: EnemyDef = _grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	def.max_health = TOUGH_HEALTH
	return def


func _press() -> StringName:
	return _commands.submit(ActivateAbilityIntent.new())


## Targets of the hits the king queued for `tick`, in resolve order.
func _slam_targets(tick: int) -> Array[int]:
	var targets: Array[int] = []
	for hit: PendingHits.Hit in _hits.take_due(tick):
		assert_eq(hit.attacker_kind, PendingHits.KIND_KING, "the king is the attacker")
		assert_eq(hit.target_kind, PendingHits.KIND_ENEMY, "and only enemies are struck")
		assert_eq(hit.amount, DAMAGE, "for the slam damage")
		targets.append(hit.target_id)
	return targets


func test_an_accepted_slam_strikes_every_enemy_within_the_radius_inclusive_in_id_order() -> void:
	var edge: int = _enemies.spawn(_tough_grunt(), Vector2(RADIUS, 0.0))
	var just_out: int = _enemies.spawn(_tough_grunt(), Vector2(RADIUS + 0.01, 0.0))
	var behind: int = _enemies.spawn(_tough_grunt(), Vector2(-3.0, 0.0))
	var close: int = _enemies.spawn(_tough_grunt(), Vector2(0.0, 1.0))
	assert_eq(_press(), CommandProcessor.OK, "the press is accepted")
	assert_eq(_hits.size(), 0, "nothing lands until the next step")
	_king.step(0, _enemies, _hits)
	var expected: Array[int] = [edge, behind, close]
	assert_eq(_slam_targets(0), expected, "exactly the radius is in, 0.01 m beyond is out")
	assert_false(expected.has(just_out), "the enemy just outside is spared")


func test_the_slam_reports_how_many_it_struck() -> void:
	_enemies.spawn(_tough_grunt(), Vector2(1.0, 0.0))
	_enemies.spawn(_tough_grunt(), Vector2(0.0, -2.0))
	_enemies.spawn(_tough_grunt(), Vector2(30.0, 0.0))
	watch_signals(_events)
	_press()
	_king.step(0, _enemies, _hits)
	assert_signal_emit_count(_events, "king_ability_used", 1, "once")
	assert_signal_emitted_with_parameters(_events, "king_ability_used", [2])


func test_the_slam_resolves_only_on_the_step_after_the_press_and_only_once() -> void:
	_enemies.spawn(_tough_grunt(), Vector2(1.0, 0.0))
	watch_signals(_events)
	_press()
	_king.step(0, _enemies, _hits)
	_king.step(1, _enemies, _hits)
	_king.step(2, _enemies, _hits)
	assert_signal_emit_count(_events, "king_ability_used", 1, "one press is one slam")
	assert_eq(_hits.size(), 1, "one hit for the one enemy")


func test_an_enemy_the_slam_kills_reports_the_king_as_its_killer() -> void:
	var weak: EnemyDef = _grunt.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	weak.max_health = DAMAGE
	var id: int = _enemies.spawn(weak, Vector2(2.0, 0.0))
	watch_signals(_events)
	_press()
	_king.step(0, _enemies, _hits)
	for hit: PendingHits.Hit in _hits.take_due(0):
		_enemies.damage(hit.target_id, hit.amount, hit.attacker_kind)
	_enemies.remove_dead()
	assert_signal_emitted_with_parameters(
		_events, "enemy_died", [id, &"grunt", Vector2(2.0, 0.0), PendingHits.KIND_KING]
	)


func test_the_slam_announces_no_passive_attack() -> void:
	_enemies.spawn(_tough_grunt(), Vector2(1.0, 0.0))
	watch_signals(_events)
	_press()
	_king.step(0, _enemies, _hits)
	assert_signal_not_emitted(_events, "attack_fired")


func test_the_slam_leaves_squads_buildings_and_the_castle_alone() -> void:
	_ctx.economy.grant(100)
	assert_eq(_ctx.commands.submit(BuildIntent.new(&"barracks_1")), CommandProcessor.OK, "built")
	_ctx.step()
	var units: UnitSystem = _ctx.squads.get_units()
	var living: int = units.count()
	assert_gt(living, 0, "the squad stands")
	var healths: Array[int] = []
	for id: int in units.ids():
		healths.append(units.health_of(id))
	var castle_health: int = _ctx.castle.get_health()
	var king: KingState = KingState.new(
		_king.get_def(), _ctx.castle.get_position(), _ctx.events, _ctx.tuning
	)
	var commands: CommandProcessor = CommandProcessor.new(
		_ctx.economy, _ctx.buildings, _ctx.run_manager, _ctx.events, king, _ctx.squads
	)
	var all_hits: PendingHits = PendingHits.new()
	var enemies: EnemySystem = EnemySystem.new(_ctx.events)
	enemies.spawn(_tough_grunt(), _ctx.castle.get_position() + Vector2(1.0, 0.0))
	assert_eq(commands.submit(ActivateAbilityIntent.new()), CommandProcessor.OK, "accepted")
	king.step(0, enemies, all_hits)
	for hit: PendingHits.Hit in all_hits.take_due(0):
		assert_eq(hit.target_kind, PendingHits.KIND_ENEMY, "only enemies are targets")
	assert_eq(units.count(), living, "no unit was lost")
	var after: Array[int] = []
	for id: int in units.ids():
		after.append(units.health_of(id))
	assert_eq(after, healths, "and no unit lost health")
	assert_eq(_ctx.castle.get_health(), castle_health, "the castle is untouched")


func test_a_second_press_during_the_cooldown_is_refused_and_changes_nothing() -> void:
	_press()
	var before: int = _king.ability_ticks_left()
	watch_signals(_events)
	assert_eq(_press(), CommandProcessor.ABILITY_COOLING, "refused")
	assert_eq(_king.ability_ticks_left(), before, "the cooldown is not restarted")
	assert_signal_emitted_with_parameters(
		_events, "command_rejected", [&"ability", &"", CommandProcessor.ABILITY_COOLING]
	)
	_king.step(0, _enemies, _hits)
	assert_signal_emit_count(_events, "king_ability_used", 1, "and no second slam")


func test_the_cooldown_runs_whole_ticks_then_accepts_the_slam_again() -> void:
	assert_eq(_king.ability_ticks_left(), 0, "ready before the first press")
	_press()
	var total: int = SimClock.ticks(COOLDOWN_S)
	assert_eq(_king.ability_ticks_left(), total, "the cooldown starts at SimClock.ticks(9.0)")
	assert_eq(total, 270, "9 s is 270 ticks at 30 Hz")
	for _i: int in range(total - 1):
		_king.tick_timers()
	assert_eq(_king.ability_ticks_left(), 1, "one tick left")
	assert_eq(_press(), CommandProcessor.ABILITY_COOLING, "still cooling")
	_king.tick_timers()
	assert_eq(_king.ability_ticks_left(), 0, "ready after exactly that many ticks")
	_king.tick_timers()
	assert_eq(_king.ability_ticks_left(), 0, "and it never goes below 0")
	assert_eq(_press(), CommandProcessor.OK, "accepted again")


func test_the_cooldown_ratio_runs_from_zero_just_after_use_to_one_when_ready() -> void:
	assert_eq(_king.ability_cooldown_ratio(), 1.0, "ready")
	_press()
	assert_eq(_king.ability_cooldown_ratio(), 0.0, "0 right after use")
	var total: int = SimClock.ticks(COOLDOWN_S)
	for _i: int in range(total / 2):
		_king.tick_timers()
	assert_almost_eq(_king.ability_cooldown_ratio(), 0.5, 0.01, "half way")
	for _i: int in range(total - total / 2):
		_king.tick_timers()
	assert_eq(_king.ability_cooldown_ratio(), 1.0, "1 when ready")


func test_a_king_without_a_slam_has_no_ability_and_the_ratio_reads_ready() -> void:
	var plain: WeaponDef = WeaponDef.new()
	_build(plain)
	assert_false(_king.has_ability(), "no slam")
	assert_eq(_king.ability_cooldown_ratio(), 1.0, "reads ready")
	watch_signals(_events)
	assert_eq(_press(), CommandProcessor.NO_ABILITY, "refused")
	assert_signal_emitted_with_parameters(
		_events, "command_rejected", [&"ability", &"", CommandProcessor.NO_ABILITY]
	)


func test_a_knocked_out_king_cannot_slam() -> void:
	_king.take_damage(_king.get_max_health())
	assert_true(_king.is_down(), "down")
	watch_signals(_events)
	assert_eq(_press(), CommandProcessor.KING_DOWN, "refused")
	assert_eq(_king.ability_ticks_left(), 0, "no cooldown started")
	assert_signal_emitted_with_parameters(
		_events, "command_rejected", [&"ability", &"", CommandProcessor.KING_DOWN]
	)


func test_a_slam_pressed_just_before_a_knockout_is_dropped() -> void:
	_enemies.spawn(_tough_grunt(), Vector2(1.0, 0.0))
	_press()
	_king.take_damage(_king.get_max_health())
	watch_signals(_events)
	_king.step(0, _enemies, _hits)
	assert_eq(_hits.size(), 0, "a downed king strikes nothing")
	assert_signal_not_emitted(_events, "king_ability_used")


func test_after_the_run_ends_the_slam_is_refused() -> void:
	_end_run()
	assert_true(_ctx.run_manager.is_run_over(), "the run is over")
	watch_signals(_events)
	assert_eq(_press(), CommandProcessor.RUN_OVER, "refused")
	assert_signal_emitted_with_parameters(
		_events, "command_rejected", [&"ability", &"", CommandProcessor.RUN_OVER]
	)


func test_the_run_over_reason_beats_a_missing_ability() -> void:
	_build(WeaponDef.new())
	_end_run()
	assert_eq(_press(), CommandProcessor.RUN_OVER, "the run state is checked first")


func test_by_day_the_slam_is_accepted_and_hits_nothing() -> void:
	var ctx: RunContext = RunContext.new(load(MAP_PATH), load(TUNING_PATH), 1)
	assert_eq(ctx.run_manager.get_phase(), RunManager.RunPhase.DAY, "it is day")
	assert_true(ctx.king.has_ability(), "the shipped king has the slam")
	watch_signals(ctx.events)
	assert_eq(ctx.commands.submit(ActivateAbilityIntent.new()), CommandProcessor.OK, "accepted")
	ctx.step()
	assert_signal_emit_count(ctx.events, "king_ability_used", 1, "the slam happened")
	assert_signal_emitted_with_parameters(ctx.events, "king_ability_used", [0])
	assert_signal_not_emitted(ctx.events, "enemy_damaged")
	assert_gt(ctx.king.ability_ticks_left(), 0, "and the cooldown runs by day")


func test_the_cooldown_keeps_running_through_the_day_steps_of_a_run() -> void:
	var ctx: RunContext = RunContext.new(load(MAP_PATH), load(TUNING_PATH), 1)
	ctx.commands.submit(ActivateAbilityIntent.new())
	var total: int = SimClock.ticks(ctx.king.get_weapon().slam_cooldown_seconds)
	for _i: int in range(total):
		ctx.step()
	assert_eq(ctx.king.ability_ticks_left(), 0, "ready after the cooldown's worth of steps")
	assert_eq(ctx.commands.submit(ActivateAbilityIntent.new()), CommandProcessor.OK, "again")
