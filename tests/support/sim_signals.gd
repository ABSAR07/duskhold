class_name SimSignals
extends RefCounted
## The single list of every signal SimEvents declares, shared by the tests that assert a read-only
## operation emits none of them. Not collected by GUT (no test_ prefix). The drift guard
## (test_the_watched_signals_are_every_signal_the_simulation_declares in
## test_debug_overlay_readonly.gd) fails when SimEvents gains a signal that is missing here, so
## every suite that reads ALL stays in step with the simulation.

const ALL: Array[String] = [
	"gold_changed",
	"building_built",
	"command_rejected",
	"phase_changed",
	"night_started",
	"dawn_payout",
	"day_started",
	"enemy_spawned",
	"enemy_damaged",
	"enemy_died",
	"attack_fired",
	"castle_damaged",
	"castle_destroyed",
	"building_damaged",
	"building_destroyed",
	"king_damaged",
	"king_downed",
	"king_respawned",
]
