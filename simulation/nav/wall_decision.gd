class_name WallDecision
extends RefCounted
## Break through or go round (ENMY-04, D-07 and D-08, RESEARCH Pattern 9), in integers only. The
## time to destruction of a wall segment is its health divided by the damage of every enemy aggroed
## onto it or onto a segment of the same run within wall_neighbour_span, and it is worked out per
## segment on a coarse, staggered cadence ((tick + segment) % cadence == 0) and published as one
## value that every nearby enemy reads. An enemy compares that time plus its straight walk to the
## castle with its detour through the castle field and attacks the segment exactly when breaking is
## faster (should_break), keeping it until the detour wins by more than the hysteresis
## (keep_breaking). All the arithmetic is on ticks and centimetres, rounded up, with
## SimClock.MAX_TICKS standing for never; seconds become ticks once, here, from NavTuning (DR-3).
## Pure RefCounted code under simulation/: no clock, scene tree or floats in the decision (DR-1
## to DR-10).

var _walls: WallSystem
var _cadence: int = 1
var _span: int = 0
var _hysteresis: int = 0
var _notice: float = 0.0
## Published time to destruction per segment; SimClock.MAX_TICKS until a crowd was seen at it.
var _ttd: PackedInt32Array = PackedInt32Array()
## Summed damage per 10 s of the attackers counted for each due segment this tick.
var _sums: PackedInt64Array = PackedInt64Array()
## The first and last segment of the run each segment belongs to.
var _run_first: PackedInt32Array = PackedInt32Array()
var _run_last: PackedInt32Array = PackedInt32Array()
var _tick: int = 0
var _evaluated: int = 0


func _init(walls: WallSystem, tuning: NavTuning) -> void:
	_walls = walls
	_cadence = maxi(SimClock.ticks(tuning.wall_decision_seconds), 1)
	_span = maxi(tuning.wall_neighbour_span, 0)
	_hysteresis = SimClock.ticks(tuning.wall_hysteresis_seconds)
	_notice = tuning.wall_notice_range
	var count: int = walls.segment_count() if walls != null else 0
	_ttd.resize(count)
	_ttd.fill(SimClock.MAX_TICKS)
	_sums.resize(count)
	_run_first.resize(count)
	_run_last.resize(count)
	for segment: int in range(count):
		var run: PackedInt32Array = walls.segments_of(walls.spot_of(segment))
		_run_first[segment] = run[0] if not run.is_empty() else segment
		_run_last[segment] = run[run.size() - 1] if not run.is_empty() else segment


## Damage per 10 seconds (300 ticks) of an attacker: attack_damage * 300 / interval, integer
## division, an interval below 1 tick counting as 1.
@warning_ignore("integer_division")
static func damage_per_300(attack_damage: int, interval_ticks: int) -> int:
	return attack_damage * 300 / maxi(interval_ticks, 1)


## Ticks to bring `health` down with `sum_per_300` damage per 10 s, rounded up; SimClock.MAX_TICKS
## when nothing deals damage (a sum of 0 or less) or the answer would not fit.
@warning_ignore("integer_division")
static func ttd_ticks(health: int, sum_per_300: int) -> int:
	if sum_per_300 <= 0:
		return SimClock.MAX_TICKS
	return mini((maxi(health, 0) * 300 + sum_per_300 - 1) / sum_per_300, SimClock.MAX_TICKS)


## Ticks to walk `distance_cm` at `speed_cm_per_s`, rounded up; SimClock.MAX_TICKS for a speed of 0
## or less.
@warning_ignore("integer_division")
static func walk_ticks(distance_cm: int, speed_cm_per_s: int) -> int:
	if speed_cm_per_s <= 0:
		return SimClock.MAX_TICKS
	return mini(
		(maxi(distance_cm, 0) * 30 + speed_cm_per_s - 1) / speed_cm_per_s, SimClock.MAX_TICKS
	)


## True when breaking through is strictly faster than the detour (or there is no detour at all).
static func should_break(ttd: int, straight_ticks: int, detour_ticks: int) -> bool:
	if detour_ticks >= SimClock.MAX_TICKS:
		return true
	return mini(ttd + straight_ticks, SimClock.MAX_TICKS) < detour_ticks


## True while an enemy already attacking a segment should go on: until the detour beats breaking
## by more than `hysteresis_ticks`. Never false for a detour that does not exist.
static func keep_breaking(
	ttd: int, straight_ticks: int, detour_ticks: int, hysteresis_ticks: int
) -> bool:
	if detour_ticks >= SimClock.MAX_TICKS:
		return true
	return not (detour_ticks + hysteresis_ticks < mini(ttd + straight_ticks, SimClock.MAX_TICKS))


## Starts the pass of `tick`: forgets the sums of the segments due on it.
func begin_tick(tick: int) -> void:
	_tick = tick
	_evaluated = 0
	for segment: int in range(_first_due(), _sums.size(), _cadence):
		_sums[segment] = 0


## Counts an attacker dealing `per_300` damage per 10 s, aggroed onto `segment`: it adds to that
## segment and to every segment of the same run within the neighbour span that is due this tick.
func add_attacker(segment: int, per_300: int) -> void:
	if segment < 0 or segment >= _sums.size() or per_300 <= 0:
		return
	var low: int = maxi(segment - _span, _run_first[segment])
	var high: int = mini(segment + _span, _run_last[segment])
	for near: int in range(low, high + 1):
		if (_tick + near) % _cadence == 0:
			_sums[near] += per_300


## Ends the pass: publishes the time to destruction of every due segment from its current health,
## and MAX_TICKS for a due segment nobody is aggroed near.
func end_tick() -> void:
	for segment: int in range(_first_due(), _sums.size(), _cadence):
		if _sums[segment] > 0:
			_ttd[segment] = ttd_ticks(_walls.health_of(segment), _sums[segment])
			_evaluated += 1
		else:
			_ttd[segment] = SimClock.MAX_TICKS


## The published time to destruction of `segment` in ticks; MAX_TICKS when unknown.
func ttd_of(segment: int) -> int:
	if segment < 0 or segment >= _ttd.size():
		return SimClock.MAX_TICKS
	return _ttd[segment]


## How many segments the last pass evaluated (due and with a crowd near).
func evaluated_count() -> int:
	return _evaluated


## Ticks of slack an attacker keeps a segment for (wall_hysteresis_seconds).
func hysteresis_ticks() -> int:
	return _hysteresis


## Metres from a segment's face within which a blocked enemy counts as aggroed onto it.
func notice_range() -> float:
	return _notice


## The first segment index due on the current tick: the smallest s with (tick + s) % cadence == 0.
func _first_due() -> int:
	return posmod(-_tick, _cadence)
