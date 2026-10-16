class_name FrameReport
extends RefCounted
## The frame-time report of the stress night (PLAT-01, D-12, RESEARCH Pattern 11). Pure static
## functions: percentiles on a sorted copy (nearest rank), a summary of one captured run, the
## median run of several by p95, and the markdown of the result. StressNight captures the runs,
## tools/stress/frame_report_cli.gd reads them and calls these. tools/ is excluded from the export.
##
## A run is the dictionary StressNight writes to run_<n>.json: {header, frame_ms, step_ms,
## render_cpu_ms, render_gpu_ms, draw_calls, objects, primitives, sample_enemies, sample_units,
## sample_arrows}. The first seven are one value per frame of the measured window; the last three
## one value per sampled frame.

## D-12's documented PLAT-01 budget: the median run's p95 frame time, in milliseconds, at 1080p and
## 1.0x speed on the dev machine (2x headroom on 16.7 ms, the 60 fps frame). This is the pass
## threshold of a tools-only, export-excluded measurement tool, not a gameplay tunable, so it is
## exempt from the every-number-in-data rule (04-09 Flagged Assumptions, the precedent is
## test_balance_acceptance.gd pinning the Phase 2 bar in test code). Moving it changes D-12, which
## is the owner's call, never a tuning step. FrameReportCli's bounded --budget-ms defaults to it
## and the report prints the budget it used.
const BUDGET_P95_MS: float = 8.0
## The share of frames the "worst frames" mean covers.
const WORST_SHARE: float = 0.01
## The D-10 bar the on-screen minimums are read against.
const BAR_ENEMIES: int = 300
const BAR_UNITS: int = 50
const BAR_ARROWS: int = 200
## Float slack so p * n that is an integer in decimal does not round up a rank.
const RANK_EPSILON: float = 1e-9


## The `p` quantile (0..1) of `values` by nearest rank on a sorted copy; 0.0 for none.
static func percentile(values: PackedFloat64Array, p: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: PackedFloat64Array = values.duplicate()
	sorted.sort()
	var rank: int = clampi(ceili(p * float(sorted.size()) - RANK_EPSILON) - 1, 0, sorted.size() - 1)
	return sorted[rank]


## The mean of the worst (largest) `share` of `values`, at least one value; 0.0 for none.
static func worst_share_mean(values: PackedFloat64Array, share: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: PackedFloat64Array = values.duplicate()
	sorted.sort()
	var count: int = clampi(ceili(share * float(sorted.size()) - RANK_EPSILON), 1, sorted.size())
	var total: float = 0.0
	for index: int in range(sorted.size() - count, sorted.size()):
		total += sorted[index]
	return total / float(count)


## The mean of `values`; 0.0 for none.
static func mean(values: PackedFloat64Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / float(values.size())


## The largest of `values`; 0.0 for none.
static func maximum(values: PackedFloat64Array) -> float:
	var best: float = 0.0
	for index: int in range(values.size()):
		best = values[index] if index == 0 else maxf(best, values[index])
	return best


## The smallest of `values`; 0.0 for none.
static func minimum(values: PackedFloat64Array) -> float:
	var best: float = 0.0
	for index: int in range(values.size()):
		best = values[index] if index == 0 else minf(best, values[index])
	return best


## The numbers of one captured run: {run, count, p50, p95, p99, worst_1pct_mean, max, mean,
## step_mean, step_p50, step_p95, step_max, render_cpu_p50, render_gpu_p50, draw_calls_p50,
## objects_p50, primitives_p50, samples, enemies_min, enemies_median, units_min, units_median,
## arrows_min, arrows_median, header}. A run with no frames gives count 0 and zeros.
static func summarise(run: Dictionary) -> Dictionary:
	var frames: PackedFloat64Array = _column(run, "frame_ms")
	var steps: PackedFloat64Array = _column(run, "step_ms")
	var enemies: PackedFloat64Array = _column(run, "sample_enemies")
	var units: PackedFloat64Array = _column(run, "sample_units")
	var arrows: PackedFloat64Array = _column(run, "sample_arrows")
	var header: Dictionary = {}
	if run.get("header") is Dictionary:
		header = run["header"]
	return {
		"run": int(header.get("run", 0)),
		"count": frames.size(),
		"p50": percentile(frames, 0.5),
		"p95": percentile(frames, 0.95),
		"p99": percentile(frames, 0.99),
		"worst_1pct_mean": worst_share_mean(frames, WORST_SHARE),
		"max": maximum(frames),
		"mean": mean(frames),
		"step_mean": mean(steps),
		"step_p50": percentile(steps, 0.5),
		"step_p95": percentile(steps, 0.95),
		"step_max": maximum(steps),
		"render_cpu_p50": percentile(_column(run, "render_cpu_ms"), 0.5),
		"render_gpu_p50": percentile(_column(run, "render_gpu_ms"), 0.5),
		"draw_calls_p50": percentile(_column(run, "draw_calls"), 0.5),
		"objects_p50": percentile(_column(run, "objects"), 0.5),
		"primitives_p50": percentile(_column(run, "primitives"), 0.5),
		"samples": enemies.size(),
		"enemies_min": int(minimum(enemies)),
		"enemies_median": int(percentile(enemies, 0.5)),
		"units_min": int(minimum(units)),
		"units_median": int(percentile(units, 0.5)),
		"arrows_min": int(minimum(arrows)),
		"arrows_median": int(percentile(arrows, 0.5)),
		"header": header,
	}


## The summary with the median p95 of `summaries` (an Array of summarise() results). With an even
## count the lower middle run is taken, so the published run is always one that really happened.
## An empty list gives an empty dictionary.
static func median_run(summaries: Array) -> Dictionary:
	if summaries.is_empty():
		return {}
	var ordered: Array = summaries.duplicate()
	ordered.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return float(a["p95"]) < float(b["p95"])
	)
	return ordered[(ordered.size() - 1) >> 1]


## True when the median run meets the budget (p95 at or below `budget_ms`) and the D-10 on-screen
## bar (minimum counts at least 300 enemies, 50 units and 200 arrows).
static func meets_budget(median: Dictionary, budget_ms: float) -> bool:
	return float(median.get("p95", INF)) <= budget_ms and meets_bar(median)


## True when the minimum on-screen counts over the run's samples reach the D-10 bar.
static func meets_bar(median: Dictionary) -> bool:
	return (
		int(median.get("samples", 0)) > 0
		and int(median.get("enemies_min", 0)) >= BAR_ENEMIES
		and int(median.get("units_min", 0)) >= BAR_UNITS
		and int(median.get("arrows_min", 0)) >= BAR_ARROWS
	)


## The markdown of a report {median, runs, budget_ms}: the method line with the budget it was judged
## against, the hardware and build, the median run's result, every run's p95 and p50, and the
## on-screen counts against the D-10 bar.
static func markdown(report: Dictionary) -> String:
	var median: Dictionary = report.get("median", {})
	var runs: Array = report.get("runs", [])
	var budget: float = float(report.get("budget_ms", BUDGET_P95_MS))
	var header: Dictionary = {}
	if median.get("header") is Dictionary:
		header = median["header"]
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Stress night frame report")
	lines.append("")
	lines.append("## Method")
	lines.append("")
	lines.append(_method_line(header, runs.size(), budget))
	lines.append("")
	lines.append("## Hardware and build")
	lines.append("")
	lines.append_array(_hardware_lines(header))
	lines.append("")
	lines.append("## Result (median of %s)" % _runs_word(runs.size()))
	lines.append("")
	lines.append_array(_result_lines(median, budget))
	lines.append("")
	lines.append("## All runs")
	lines.append("")
	lines.append_array(_all_runs_lines(runs, median))
	lines.append("")
	lines.append("## On-screen counts")
	lines.append("")
	lines.append_array(_count_lines(median))
	lines.append("")
	return "\n".join(lines)


static func _runs_word(count: int) -> String:
	return "%d run%s" % [count, "" if count == 1 else "s"]


static func _method_line(header: Dictionary, run_count: int, budget_ms: float) -> String:
	return (
		(
			"The stress night in a real window, speed %sx, vsync %s, frame rate uncapped, %s s "
			+ "measured after a %s s warm-up, %s, the run with the median p95 published. Judged "
			+ "against a p95 of %.1f ms (D-12) and the D-10 bar of %d enemies, %d units and %d "
			+ "arrows on screen at every sampled frame."
		)
		% [
			header.get("speed", "?"),
			header.get("vsync", "?"),
			header.get("duration_s", "?"),
			header.get("warmup_s", "?"),
			_runs_word(run_count),
			budget_ms,
			BAR_ENEMIES,
			BAR_UNITS,
			BAR_ARROWS,
		]
	)


static func _hardware_lines(header: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var window: Array = header.get("window_size", [])
	var viewport: Array = header.get("viewport_size", [])
	var requested: Array = header.get("requested_size", [])
	lines.append(
		(
			"- GPU: %s (vendor %s, API %s)"
			% [header.get("gpu", "?"), header.get("gpu_vendor", "?"), header.get("gpu_api", "?")]
		)
	)
	lines.append("- CPU: %s" % header.get("cpu", "?"))
	lines.append("- Godot: %s" % header.get("godot", "?"))
	lines.append("- Renderer: %s (%s)" % [header.get("renderer", "?"), header.get("driver", "?")])
	lines.append(
		(
			"- Window requested: %s, window size: %s, viewport: %s"
			% [_size_text(requested), _size_text(window), _size_text(viewport)]
		)
	)
	lines.append(
		(
			"- vsync: %s, max fps: %s, speed: %sx"
			% [header.get("vsync", "?"), header.get("max_fps", "?"), header.get("speed", "?")]
		)
	)
	return lines


static func _result_lines(median: Dictionary, budget_ms: float) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if median.is_empty():
		lines.append("- no run")
		return lines
	var within: bool = float(median["p95"]) <= budget_ms
	lines.append("- Run published: %d, frames measured: %d" % [median["run"], median["count"]])
	(
		lines
		. append(
			(
				"- Frame time ms: p50 %.2f, p95 %.2f, p99 %.2f, worst 1 percent mean %.2f, max %.2f, mean %.2f"
				% [
					median["p50"],
					median["p95"],
					median["p99"],
					median["worst_1pct_mean"],
					median["max"],
					median["mean"]
				]
			)
		)
	)
	lines.append(
		(
			"- Step (ctx.advance) ms: mean %.2f, p50 %.2f, p95 %.2f, max %.2f"
			% [median["step_mean"], median["step_p50"], median["step_p95"], median["step_max"]]
		)
	)
	lines.append(
		(
			"- Render ms (median): CPU %.2f, GPU %.2f"
			% [median["render_cpu_p50"], median["render_gpu_p50"]]
		)
	)
	lines.append(
		(
			"- Per frame (median): %d draw calls, %d objects, %d primitives"
			% [median["draw_calls_p50"], median["objects_p50"], median["primitives_p50"]]
		)
	)
	lines.append(
		(
			"- p95 %.2f ms against the %.1f ms budget: %s"
			% [median["p95"], budget_ms, "within" if within else "OVER"]
		)
	)
	return lines


static func _all_runs_lines(runs: Array, median: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("| Run | p50 ms | p95 ms | p99 ms | max ms | Published |")
	lines.append("|-----|-------:|-------:|-------:|-------:|-----------|")
	for summary: Dictionary in runs:
		lines.append(
			(
				"| %d | %.2f | %.2f | %.2f | %.2f | %s |"
				% [
					summary["run"],
					summary["p50"],
					summary["p95"],
					summary["p99"],
					summary["max"],
					"yes" if int(summary["run"]) == int(median.get("run", -1)) else ""
				]
			)
		)
	return lines


static func _count_lines(median: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if median.is_empty():
		lines.append("- no run")
		return lines
	lines.append("| Kind | Minimum | Median | Bar |")
	lines.append("|------|--------:|-------:|----:|")
	lines.append(
		(
			"| Enemies | %d | %d | %d |"
			% [median["enemies_min"], median["enemies_median"], BAR_ENEMIES]
		)
	)
	lines.append(
		"| Units | %d | %d | %d |" % [median["units_min"], median["units_median"], BAR_UNITS]
	)
	lines.append(
		"| Arrows | %d | %d | %d |" % [median["arrows_min"], median["arrows_median"], BAR_ARROWS]
	)
	lines.append("")
	(
		lines
		. append(
			(
				"Counted inside the camera frustum on every 30th frame (%d samples); the minimum is gated."
				% median["samples"]
			)
		)
	)
	return lines


static func _size_text(size: Array) -> String:
	if size.size() < 2:
		return "?"
	return "%dx%d" % [int(size[0]), int(size[1])]


## The numbers under `key` of `run` as a PackedFloat64Array; empty when absent or not a list.
static func _column(run: Dictionary, key: String) -> PackedFloat64Array:
	var values: PackedFloat64Array = PackedFloat64Array()
	var raw: Variant = run.get(key)
	if raw is Array:
		for value: Variant in raw:
			values.append(float(value))
	return values
