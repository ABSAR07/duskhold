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


## Whole simulation ticks a duration lasts: 0 for zero or negative, else at least 1.
static func ticks(duration: float) -> int:
	if duration <= 0.0:
		return 0
	return maxi(ceili(duration / STEP - TICK_ROUNDING_SLACK), 1)


## RED-phase shell for the projectile flight time; the GREEN commit fills it in.
static func flight_ticks(_distance: float, _speed: float) -> int:
	return 0


## Seconds a whole number of ticks lasts.
static func seconds(tick_count: int) -> float:
	return float(tick_count) * STEP
