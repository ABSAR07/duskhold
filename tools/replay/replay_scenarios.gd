class_name ReplayScenarios
extends RefCounted
## Allowlisted replay scenarios (DEV-05). Stub for the RED commit; filled in by the GREEN commit.

const NAMES: Array[StringName] = [&"smoke", &"full_idle"]
const GOLDEN_DIR := "res://tests/golden"


static func has(_name: StringName) -> bool:
	return false


static func default_seed(_name: StringName) -> int:
	return 0


static func max_ticks(_name: StringName) -> int:
	return 0


static func run(_name: StringName, _run_seed: int) -> Dictionary:
	return {}


static func golden_digest(_path: String) -> String:
	return ""
