class_name ShotEconomyScenarios
extends RefCounted
## The Phase 5 scenes of `tools/screenshot.sh` (plan 05-04). Scaffold only in the failing-test
## commit: the shot list is empty until the scenes land.

const ECONOMY_SHOTS: Array[StringName] = []
## The gold the Phase 5 shots start with: enough for all three castle upgrades.
const SHOT_GOLD: int = 60


## True for the Phase 5 shots.
static func handles(shot_name: StringName) -> bool:
	return ECONOMY_SHOTS.has(shot_name)
