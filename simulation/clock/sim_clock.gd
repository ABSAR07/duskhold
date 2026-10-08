class_name SimClock
extends RefCounted
## The simulation's only clock. `RunContext.step()` advances the run by exactly STEP seconds; real
## time reaches it only through `RunContext.advance()` (DR-2). Inside a night every timer is an
## integer tick count converted once from data seconds with `ticks` (DR-3).

## Seconds per simulation step (30 Hz). A determinism contract, not a feel number: changing it
## regenerates every golden replay digest, so test_sim_clock.gd pins it.
const STEP: float = 1.0 / 30.0
## Longest real frame the accumulator accepts. A window drag, alt-tab or debugger stall delivers
## one huge frame delta; clamping it keeps the catch-up bounded (7 steps at most).
const MAX_ADVANCE_SECONDS: float = 0.25
## Slack when comparing the accumulator with STEP, so sixty 1/60 s frames make exactly 30 steps.
const ACCUMULATOR_EPSILON: float = 1e-9
## Slack inside `ticks` so a duration that is a whole number of steps (0.8 s) does not round up.
const TICK_ROUNDING_SLACK: float = 0.0001
## The longest timer `ticks` and `flight_ticks` return (about 10,000 hours): a huge or infinite
## duration saturates here instead of overflowing. Far above any shipped timer.
const MAX_TICKS: int = 1 << 30


## Whole simulation ticks a duration lasts: 0 for zero, negative or NaN, else at least 1 and at
## most MAX_TICKS (a longer or infinite duration saturates, review WR-01: an unchecked ceili
## overflowed and the one-tick floor then turned 1e30 s into a timer that fires every tick).
static func ticks(duration: float) -> int:
	if not duration > 0.0:
		return 0
	return _whole_ticks(duration / STEP)


## Whole simulation ticks a projectile flies over `distance` metres at `speed` metres per second:
## 0 for a speed of zero or less or NaN (a melee hit lands at once), 0 for a NaN distance, else at
## least 1 and at most MAX_TICKS. The same slack as `ticks`, so a flight that is a whole number of
## steps does not round up.
static func flight_ticks(distance: float, speed: float) -> int:
	if not speed > 0.0:
		return 0
	return _whole_ticks(distance / speed / STEP)


## `steps` rounded up to whole ticks: 0 for NaN, else clamped to [1, MAX_TICKS].
static func _whole_ticks(steps: float) -> int:
	if is_nan(steps):
		return 0
	return clampi(ceili(minf(steps, float(MAX_TICKS)) - TICK_ROUNDING_SLACK), 1, MAX_TICKS)


## Seconds a whole number of ticks lasts.
static func seconds(tick_count: int) -> float:
	return float(tick_count) * STEP
