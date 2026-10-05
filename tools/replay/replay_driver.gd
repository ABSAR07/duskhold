class_name ReplayDriver
extends RefCounted
## RED stub: replaced by the real driver in the GREEN commit.


static func run(
	_map: MapConfig,
	_tuning: LoopTuning,
	_run_seed: int,
	_bot: PlaytestBot,
	_max_ticks: int,
	_stop_after_dawns: int = 0,
	_king_def: KingDef = null
) -> Dictionary:
	return {
		"outcome": &"",
		"ticks": 0,
		"digest": "",
		"line_count": 0,
		"nights_started": 0,
		"lines": PackedStringArray(),
	}
