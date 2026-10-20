extends SceneTree
## The real-window view ablation (PLAT-01, plan 04-24): the committed, rerunnable version of plan
## 04-21's scratch probe (04-FRAME-REPORT.md, "The remaining miss: the view layers, not the step").
## It runs the unchanged stress night (tools/stress/stress_night.tscn, with the arguments
## tools/stress.sh passes) in a real window and, once the warm-up is over, switches the `_process`
## of EnemyViews, UnitViews and ProjectileVfx off and on in 5 s slices, in the order
##   all_on, enemy_views_off, unit_views_off, projectile_vfx_off, all_off, all_on_again
## (one trial is 30 s). With a view's `_process` off its batch simply stops updating, so this
## attributes cost and proposes no change; the simulation, the data and the stress night itself are
## untouched. all_on_again is the drift check against the first all_on slice.
##
## Never headless (it exits 2 there, like StressNight), never CI, local only; close other heavy
## programs first and run nothing else meanwhile (RESEARCH Pitfall 13). tools/ is excluded from the
## export.
##
## Launch (two 30 s trials after a 10 s warm-up, about 70 s):
##   bash tools/godot.sh --path . --resolution 1920x1080 -s res://tools/stress/view_ablation.gd -- \
##       --duration=60 --warmup=10 --run=9 --out=build/stress/ablation
## Arguments are StressNight's (--duration, --warmup, --run, --out), because the stress night reads
## the same command line; --duration must also be a whole number of trials (30..120, a multiple of
## 30), else VIEW_ABLATION_USAGE and exit 64.
##
## A frame's delta is the cost of the frame before it, so each delta is recorded under the slice
## that was switched on while that frame ran, and the next slice is applied after it. Output,
## printed and written to <out>/ablation.txt:
##   ABLATION_SLICE trial=<t> slice=<name> frames=<n> p50_ms=<x.xx> p95_ms=<x.xx> mean_ms=<x.xx>
##   ABLATION_SAVED slice=<name> mean_ms=<x.xx>   (the four off slices: the median over trials of
##       that trial's all_on mean minus the slice's mean)
##   VIEW_ABLATION_OK trials=<n> slice_s=5
## StressNight still quits at the end of its own measured window and writes run_<n>.json in the same
## directory; that is expected. Exit codes: 0 written, 1 the output or a view node failed, 2 no real
## renderer, 64 usage.

const Attribution := preload("res://tools/stress/step_attribution.gd")

const EXIT_FAILED: int = 1
const EXIT_NO_RENDERER: int = 2
const EXIT_USAGE: int = 64
const NIGHT_SCENE := "res://tools/stress/stress_night.tscn"
const OUT_FILE := "ablation.txt"
const SLICE_S: float = 5.0
const SLICE_NAMES: Array[String] = [
	"all_on",
	"enemy_views_off",
	"unit_views_off",
	"projectile_vfx_off",
	"all_off",
	"all_on_again",
]
const SLICES_PER_TRIAL: int = 6
const TRIAL_S: int = 30
const MAX_DURATION_S: int = 120
const SLICE_ALL_ON := "all_on"
## The off slices ABLATION_SAVED reports.
const SAVED_SLICES: Array[String] = [
	"enemy_views_off", "unit_views_off", "projectile_vfx_off", "all_off"
]
const MS_PER_S: float = 1000.0
const ENEMY_VIEWS_NODE := "EnemyViews"
const UNIT_VIEWS_NODE := "UnitViews"
const PROJECTILE_VFX_NODE := "ProjectileVfx"

var _args: Dictionary = {}
var _night: Node
var _enemy_views: Node
var _unit_views: Node
var _projectiles: Node
var _elapsed_s: float = 0.0
var _measured_s: float = 0.0
var _started: bool = false
var _finished: bool = false
## The global slice number being recorded (trial * SLICES_PER_TRIAL + index), -1 before the first.
var _current: int = -1
var _frames_ms: PackedFloat64Array = PackedFloat64Array()
var _lines: Array[String] = []
## Per slice name, the slice mean of every trial in order.
var _means_of: Dictionary = {}


## "" when `parsed` (a StressNight.parse_args result) is usable, else a one-line reason. The
## duration must be a whole number of 30 s trials, 30 to 120.
static func check_duration(parsed: Dictionary) -> String:
	var error: String = parsed["error"]
	if not error.is_empty():
		return error
	var duration: int = parsed["duration"]
	if duration < TRIAL_S or duration > MAX_DURATION_S or duration % TRIAL_S != 0:
		return (
			"--duration must be a multiple of %d between %d and %d, got %d"
			% [TRIAL_S, TRIAL_S, MAX_DURATION_S, duration]
		)
	return ""


## The slice of the measured time `measured_s`: {trial (from 1), index (0..5 in the trial), name}.
static func slice_at(measured_s: float) -> Dictionary:
	var number: int = maxi(floori(measured_s / SLICE_S), 0)
	var index: int = number % SLICES_PER_TRIAL
	@warning_ignore("integer_division")
	var trial: int = number / SLICES_PER_TRIAL + 1
	return {"trial": trial, "index": index, "name": SLICE_NAMES[index]}


## Which views run in slice `slice_name`: [enemy views, unit views, projectiles]. An unknown name
## leaves all three on.
static func views_on(slice_name: String) -> Array[bool]:
	match slice_name:
		"enemy_views_off":
			return [false, true, true]
		"unit_views_off":
			return [true, false, true]
		"projectile_vfx_off":
			return [true, true, false]
		"all_off":
			return [false, false, false]
	return [true, true, true]


## The ABLATION_SAVED value: the median over trials of (a trial's all_on mean minus the same trial's
## slice mean), milliseconds. 0.0 when the two lists are empty or differ in length.
static func saved_of(all_on_means: PackedFloat64Array, slice_means: PackedFloat64Array) -> float:
	if all_on_means.is_empty() or all_on_means.size() != slice_means.size():
		return 0.0
	var gains: PackedFloat64Array = PackedFloat64Array()
	for trial: int in range(all_on_means.size()):
		gains.append(all_on_means[trial] - slice_means[trial])
	return Attribution.median_of(gains)


func _initialize() -> void:
	_args = StressNight.parse_args(OS.get_cmdline_user_args())
	var error: String = check_duration(_args)
	if not error.is_empty():
		printerr("VIEW_ABLATION_USAGE %s" % error)
		printerr(
			(
				(
					"usage: [--duration=<%d..%d, a multiple of %d>] [--warmup=<0..60>] [--run=<1..9>]"
					+ " [--out=build/<dir>]"
				)
				% [TRIAL_S, MAX_DURATION_S, TRIAL_S]
			)
		)
		quit(EXIT_USAGE)
		return
	if DisplayServer.get_name() == "headless":
		printerr("the view ablation needs a real renderer; never run it under --headless")
		quit(EXIT_NO_RENDERER)
		return
	for slice_name: String in SLICE_NAMES:
		_means_of[slice_name] = PackedFloat64Array()
	_night = (load(NIGHT_SCENE) as PackedScene).instantiate()
	root.add_child(_night)


func _process(delta: float) -> bool:
	if _finished or _night == null:
		return false
	_elapsed_s += delta
	if not _started:
		if _elapsed_s >= float(_args["warmup"]):
			_start_measuring()
		return false
	_frames_ms.append(delta * MS_PER_S)
	_measured_s += delta
	if _measured_s >= float(_args["duration"]):
		_finished = true
		_flush_slice()
		_finish()
		return false
	var slice: Dictionary = slice_at(_measured_s)
	var number: int = (int(slice["trial"]) - 1) * SLICES_PER_TRIAL + int(slice["index"])
	if number != _current:
		_flush_slice()
		_enter_slice(number, String(slice["name"]))
	return false


## Finds the three view nodes and applies the first slice; ends the run when a node is missing.
func _start_measuring() -> void:
	_enemy_views = _night.find_child(ENEMY_VIEWS_NODE, true, false)
	_unit_views = _night.find_child(UNIT_VIEWS_NODE, true, false)
	_projectiles = _night.find_child(PROJECTILE_VFX_NODE, true, false)
	if _enemy_views == null or _unit_views == null or _projectiles == null:
		printerr("VIEW_ABLATION_FAILED reason=view_nodes_not_found")
		_finished = true
		quit(EXIT_FAILED)
		return
	_started = true
	_enter_slice(0, SLICE_NAMES[0])


func _enter_slice(number: int, slice_name: String) -> void:
	_current = number
	_apply(views_on(slice_name))


func _apply(plan: Array[bool]) -> void:
	_enemy_views.set_process(plan[0])
	_unit_views.set_process(plan[1])
	_projectiles.set_process(plan[2])


## Appends the ABLATION_SLICE line of the slice just ended and remembers its mean.
func _flush_slice() -> void:
	if _current < 0 or _frames_ms.is_empty():
		return
	@warning_ignore("integer_division")
	var trial: int = _current / SLICES_PER_TRIAL + 1
	var slice_name: String = SLICE_NAMES[_current % SLICES_PER_TRIAL]
	var mean_ms: float = FrameReport.mean(_frames_ms)
	var means: PackedFloat64Array = _means_of[slice_name]
	means.append(mean_ms)
	_means_of[slice_name] = means
	(
		_lines
		. append(
			(
				"ABLATION_SLICE trial=%d slice=%s frames=%d p50_ms=%.2f p95_ms=%.2f mean_ms=%.2f"
				% [
					trial,
					slice_name,
					_frames_ms.size(),
					FrameReport.percentile(_frames_ms, 0.5),
					FrameReport.percentile(_frames_ms, 0.95),
					mean_ms,
				]
			)
		)
	)
	_frames_ms = PackedFloat64Array()


## Appends the ABLATION_SAVED and VIEW_ABLATION_OK lines, prints and writes every line, and
## switches the three views back on.
func _finish() -> void:
	_apply([true, true, true])
	var all_on: PackedFloat64Array = _means_of[SLICE_ALL_ON]
	for slice_name: String in SAVED_SLICES:
		var saved: float = saved_of(all_on, _means_of[slice_name])
		_lines.append("ABLATION_SAVED slice=%s mean_ms=%.2f" % [slice_name, saved])
	@warning_ignore("integer_division")
	var trials: int = int(_args["duration"]) / TRIAL_S
	_lines.append("VIEW_ABLATION_OK trials=%d slice_s=%d" % [trials, int(SLICE_S)])
	for line: String in _lines:
		print(line)
	var out: String = _args["out"]
	var made: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var file: FileAccess = FileAccess.open("%s/%s" % [out, OUT_FILE], FileAccess.WRITE)
	if made != OK or file == null:
		printerr("VIEW_ABLATION_FAILED reason=cannot_write_output out=%s" % out)
		quit(EXIT_FAILED)
		return
	for line: String in _lines:
		file.store_line(line)
	file.close()
