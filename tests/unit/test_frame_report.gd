extends GutTest
## PLAT-01 / D-12: the frame-time report arithmetic. Percentiles are nearest rank on a sorted copy,
## the published run is the one with the median p95, and the markdown carries the sections the
## committed report is built from. Pure functions, no window and no process.

const ONE_TO_HUNDRED_COUNT: int = 100


func _one_to_hundred() -> PackedFloat64Array:
	var values: PackedFloat64Array = PackedFloat64Array()
	for value: int in range(1, ONE_TO_HUNDRED_COUNT + 1):
		values.append(float(value))
	return values


func _run(run_number: int, frames: Array, arrows: Array) -> Dictionary:
	return {
		"header": {"run": run_number, "gpu": "Test GPU", "window_size": [1920, 1050]},
		"frame_ms": frames,
		"step_ms": [1.0, 2.0, 3.0, 4.0],
		"render_cpu_ms": [0.5, 0.5, 0.7, 0.9],
		"render_gpu_ms": [2.0, 2.0, 3.0, 4.0],
		"draw_calls": [100, 110, 120, 130],
		"objects": [200, 210, 220, 230],
		"primitives": [1000, 1100, 1200, 1300],
		"sample_enemies": [300, 310, 305],
		"sample_units": [50, 52, 51],
		"sample_arrows": arrows,
	}


func test_percentile_takes_the_nearest_rank() -> void:
	var values: PackedFloat64Array = _one_to_hundred()
	assert_eq(FrameReport.percentile(values, 0.5), 50.0, "the median of 1 to 100 is 50")
	assert_eq(FrameReport.percentile(values, 0.95), 95.0, "the 95th")
	assert_eq(FrameReport.percentile(values, 0.99), 99.0, "the 99th")
	assert_eq(FrameReport.percentile(values, 1.0), 100.0, "the top")
	assert_eq(FrameReport.percentile(values, 0.0), 1.0, "the bottom")


func test_percentile_of_a_single_value_is_that_value() -> void:
	assert_eq(FrameReport.percentile(PackedFloat64Array([7.5]), 0.95), 7.5, "one value")
	assert_eq(FrameReport.percentile(PackedFloat64Array(), 0.95), 0.0, "none reads 0")


func test_percentile_sorts_a_copy_and_leaves_the_input_alone() -> void:
	var values: PackedFloat64Array = PackedFloat64Array([5.0, 1.0, 3.0])
	assert_eq(FrameReport.percentile(values, 0.5), 3.0, "the median of three")
	assert_eq(values, PackedFloat64Array([5.0, 1.0, 3.0]), "the caller's order is kept")


func test_worst_share_mean_averages_the_largest_values() -> void:
	var values: PackedFloat64Array = _one_to_hundred()
	assert_eq(FrameReport.worst_share_mean(values, 0.01), 100.0, "1 percent of 100 is one value")
	assert_eq(FrameReport.worst_share_mean(values, 0.05), 98.0, "5 percent is 96 to 100")
	assert_eq(FrameReport.worst_share_mean(PackedFloat64Array([4.0]), 0.01), 4.0, "at least one")
	assert_eq(FrameReport.worst_share_mean(PackedFloat64Array(), 0.01), 0.0, "none reads 0")


func test_summarise_gives_the_percentiles_the_counts_and_the_header() -> void:
	var run: Dictionary = _run(2, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0], [210, 205])
	var summary: Dictionary = FrameReport.summarise(run)
	assert_eq(summary["run"], 2, "the run number comes from the header")
	assert_eq(summary["count"], 10, "ten frames")
	assert_eq(summary["p50"], 5.0, "p50")
	assert_eq(summary["p95"], 10.0, "p95 by nearest rank")
	assert_eq(summary["max"], 10.0, "max")
	assert_eq(summary["mean"], 5.5, "mean")
	assert_eq(summary["step_mean"], 2.5, "step mean")
	assert_eq(summary["render_gpu_p50"], 2.0, "render GPU median")
	assert_eq(summary["enemies_min"], 300, "minimum enemies over the samples")
	assert_eq(summary["units_min"], 50, "minimum units")
	assert_eq(summary["arrows_min"], 205, "minimum arrows")
	assert_eq(summary["samples"], 3, "samples counted from the enemy column")
	assert_eq(summary["header"]["gpu"], "Test GPU", "the hardware fields travel with it")


func test_summarise_of_an_empty_run_is_all_zero() -> void:
	var summary: Dictionary = FrameReport.summarise({})
	assert_eq(summary["count"], 0, "no frames")
	assert_eq(summary["p95"], 0.0, "no p95")
	assert_eq(summary["enemies_min"], 0, "no counts")


func test_median_run_picks_the_middle_p95_of_three() -> void:
	var summaries: Array = [{"run": 1, "p95": 7.0}, {"run": 2, "p95": 9.0}, {"run": 3, "p95": 8.0}]
	assert_eq(FrameReport.median_run(summaries)["run"], 3, "the 8.0 run is the median")
	assert_eq(summaries[0]["run"], 1, "the caller's list is not reordered")
	assert_eq(
		FrameReport.median_run([{"run": 4, "p95": 5.0}])["run"], 4, "one run is its own median"
	)
	assert_eq(FrameReport.median_run([]), {}, "none gives an empty dictionary")


func test_median_run_of_an_even_count_takes_the_lower_middle() -> void:
	var summaries: Array = [{"run": 1, "p95": 4.0}, {"run": 2, "p95": 2.0}]
	assert_eq(FrameReport.median_run(summaries)["run"], 2, "a run that really happened")


func test_the_budget_is_the_documented_eight_milliseconds() -> void:
	assert_eq(FrameReport.BUDGET_P95_MS, 8.0, "D-12: 2x headroom on 16.7 ms")


func test_meets_budget_needs_the_p95_and_the_whole_on_screen_bar() -> void:
	var good: Dictionary = {
		"p95": 8.0, "samples": 5, "enemies_min": 300, "units_min": 50, "arrows_min": 200
	}
	assert_true(FrameReport.meets_budget(good, 8.0), "exactly on the budget and the bar passes")
	var slow: Dictionary = good.duplicate()
	slow["p95"] = 8.01
	assert_false(FrameReport.meets_budget(slow, 8.0), "a p95 over the budget fails")
	for field: String in ["enemies_min", "units_min", "arrows_min"]:
		var short: Dictionary = good.duplicate()
		short[field] = int(short[field]) - 1
		assert_false(FrameReport.meets_budget(short, 8.0), "%s one short fails" % field)
	var unsampled: Dictionary = good.duplicate()
	unsampled["samples"] = 0
	assert_false(FrameReport.meets_budget(unsampled, 8.0), "no samples is no proof")


func test_markdown_carries_the_sections_of_the_committed_report() -> void:
	var summaries: Array = [
		FrameReport.summarise(_run(1, [6.0, 7.0, 8.0], [210])),
		FrameReport.summarise(_run(2, [7.0, 8.0, 9.0], [220])),
		FrameReport.summarise(_run(3, [5.0, 6.0, 7.0], [230])),
	]
	var report: Dictionary = {
		"median": FrameReport.median_run(summaries), "runs": summaries, "budget_ms": 8.0
	}
	var text: String = FrameReport.markdown(report)
	for heading: String in [
		"## Method",
		"## Hardware and build",
		"## Result (median of 3 runs)",
		"## All runs",
		"## On-screen counts",
	]:
		assert_true(text.contains(heading), "has %s" % heading)
	assert_true(text.contains("8.0 ms"), "the Method names the budget it was judged against")
	assert_true(text.contains("Test GPU"), "and the hardware")
	assert_true(text.contains("1920x1050"), "and the actual window size")
