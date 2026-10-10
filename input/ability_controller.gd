class_name AbilityController
extends Node
## Polled input for the weapon's active ability (D-17).

## Emitted when a press was refused; `reason` is the CommandProcessor reason value.
signal denied(reason: StringName)

const ACTION: StringName = &"ability"


func bind_run(_ctx: RunContext, _map_root: MapRoot) -> void:
	pass
