class_name SimEvents
extends RefCounted
## Per-run event bus. Owned by RunContext (not a global), so each headless test has its own.
## Presentation subscribes through bind_run; the simulation never listens to presentation.

## Emitted after every successful gold change. `delta` is signed.
signal gold_changed(new_amount: int, delta: int)
## `new_tier` 1 means constructed, greater than 1 means upgraded.
signal building_built(spot_id: StringName, building_id: StringName, new_tier: int)
## A command was refused; `reason` is one of the CommandProcessor reason constants.
signal command_rejected(command: StringName, spot_id: StringName, reason: StringName)
## Values are RunManager.RunPhase integers.
signal phase_changed(old_phase: int, new_phase: int)
