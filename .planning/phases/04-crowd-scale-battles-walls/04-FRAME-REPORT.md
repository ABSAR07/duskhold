# Phase 4 Frame Report: the stress night against the 8 ms budget (PLAT-01, D-10, D-12)

## After the view-layer port (plans 04-24 to 04-28), 2026-10-20T15:48Z

Measured 2026-10-20 by plan 04-28 on the same dev machine, with the method of plans 04-09 and 04-21 (both kept below as the before). **Verdict: the budget is MET.** The median run's p95 frame time is **5.37 ms against the unchanged 8.0 ms budget** (2.63 ms, 33 percent, under it; it was 10.95 ms, 1.37 times over, after the step port, and 37.04 ms, 4.6 times over, before any port), with the D-10 on-screen bar met in full (300 enemies, 50 units and 237 or more arrows in view at every sampled frame). Taking the three view layers' per-frame fill into C++ (arrows in plan 04-25, enemies and death puffs in 04-26, units in 04-27) bought a factor of 2.0 on the p95 and 1.7 on the median frame (p50 6.25 ms to 3.70 ms, about 142 fps to about 256 fps), and a factor of 6.9 on the p95 since 04-09. **PLAT-01 and ROADMAP success criterion 3 are closed by measurement on the dev machine (gap G-04-5).** Nothing was lowered or raised: no budget change (`FrameReport.BUDGET_P95_MS` is 8.0), no fewer enemies, no skipped steps, no draw-cap or fidelity change, the stress map, the load numbers and the stress tools untouched.

```
FRAME_REPORT_OK runs=3 median_run=2 p95_ms=5.37 budget_ms=8.0 within=true enemies=300 units=50 arrows=237
```

**Upstream halts: none.** All four view ports of this round shipped natively and none halted: the arrows (plan 04-25, bench 2280.07 us to 74.44 us, 30.6 times), the enemy bodies, flashes and hurt-only bars and the death-puff ring (plan 04-26, 758.89 us to 73.12 us, 10.4 times, and 140.05 us to 4.63 us, 30.2 times), and the unit bodies and bars (plan 04-27, 273.88 us to 30.16 us, 9.1 times); the SUMMARYs of 04-24 to 04-27 all read `status: complete`, so the measurement below covers every per-frame view loop of the night as native code (no view kept its GDScript). The whole round went out in one push and CI run 39445109146 (https://github.com/ABSAR07/duskhold/actions/runs/39445109146, head `e0ecde0`) was green on every job (lint, test, native-linux, native-windows, screenshots, export) with the four replays and the gate on both the GCC and the MSVC library.

### What was proven first

The measured code is the proven code (`HEAD 9282d64`, which holds the code of `e0ecde0`; the commits after it change only `.planning/`; native library rebuilt and stamp-checked by `bash tools/native_build.sh`, which printed `NATIVE_BUILD_OK platform=windows lib=libduskhold_sim.windows.x86_64.dll godot_cpp=2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec api=4.7.2`): the four replays and the gate, each twice, all unchanged against the owner's D-14 reading.

```
REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f
REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4
REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58
REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf
GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a
```

(The three golden scenarios ran with `--twice --expect-file=tests/golden/<name>.json`, full_idle with `--twice`; all exit 0.)

### Method and hardware

Identical to the sections below: `bash tools/stress.sh --runs=3 --duration=20` (10 s warm-up, 20 s measured, three runs, the median-p95 run published), real window, requested 1920x1080 (actual window 1920x1050, viewport 1316x720), vsync off, `Engine.max_fps = 0`, speed 1.0x, the camera at y 119.5, NVIDIA GeForce RTX 3060 Laptop GPU (Vulkan 1.4.341), Intel Core i5-10500H, Windows 11 Home, Godot 4.7.2-stable (official), Forward+. The stress map, the load numbers (300 grunts, 50 footmen, 20 towers, the gate wall, arrow speed 5 m/s) and the stress tools are exactly those of plan 04-09; nothing in `tools/stress/` changed (the two instruments plan 04-24 added are new files, not edits). The headless numbers were taken first, one command at a time, then the three stress runs, then the ablation, then the rebuild probe; no other Godot process was running (checked with `tasklist` before each real-window run) and nothing else ran on the machine.

### Result (median of 3 runs)

The published run is run 2 (the median by p95: 5.00, 5.37, 5.56).

| Measure | After the view port | After the step port (04-21) | Before (04-09) |
|---------|--------------------:|----------------------------:|---------------:|
| Frames measured | 5119 (about 256 fps) | 2838 (about 142 fps) | 856 (about 43 fps) |
| Frame time p50 | 3.70 ms | 6.25 ms | 20.92 ms |
| Frame time p95 | **5.37 ms** | **10.95 ms** | **37.04 ms** |
| Frame time p99 | 6.60 ms | 13.33 ms | 50.00 ms |
| Worst 1 percent mean | 8.76 ms | 14.11 ms | 55.42 ms |
| Frame time max | 46.71 ms | 16.88 ms | 74.82 ms |
| Frame time mean | 3.86 ms | 6.99 ms | 23.33 ms |
| Step (ctx.advance) mean / p50 / p95 / max, all frames | 0.55 / 0.02 / 4.39 / 36.37 ms | 0.73 / 0.01 / 3.62 / 24.10 ms | 14.34 / 18.14 / 25.43 / 56.35 ms |
| Render CPU, median | 0.64 ms | 0.45 ms | 0.70 ms |
| Render GPU, median | 0.77 ms | 1.21 ms | 4.46 ms |
| Draw calls / objects / primitives, median | 230 / 328 / 719,000 | 230 / 328 / 718,998 | 230 / 328 / 718,962 |

p95 5.37 ms against the 8.0 ms budget: **within**.

The maximum of the published run is one frame (46.71 ms, frame 850, a frame that also ran a 4.69 ms step); every run has exactly one frame over 16.7 ms (run 1 18.44 ms, run 2 46.71 ms, run 3 23.70 ms) and 16 to 23 frames over 8 ms (0.3 to 0.45 percent of the frames), so the tail is a handful of single-frame spikes, not a trend. The p99 is 6.60 ms. The render CPU median reads 0.64 ms here against 0.45 ms in 04-21; it was not investigated (the machine's session drift is the likely part), and it is small beside the 3.70 ms median frame.

### All runs

| Run | Frames | p50 ms | p95 ms | p99 ms | max ms | Published |
|-----|-------:|-------:|-------:|-------:|-------:|-----------|
| 1 | 5432 | 3.46 | 5.00 | 6.06 | 18.44 |  |
| 2 | 5119 | 3.70 | 5.37 | 6.60 | 46.71 | yes |
| 3 | 5084 | 3.70 | 5.56 | 6.67 | 23.70 |  |

The three runs agree to within 11 percent on p95 (5.00 to 5.56 ms) and the worst of them is 2.44 ms under the budget, so the pass is not a lucky run. (04-21's runs were 10.88 / 10.95 / 11.11 ms.) The frame times are quantised by the host timer (3.33, 3.70, 4.17 ms and so on), which is why the percentiles sit on those values.

### On-screen counts

| Kind | Minimum (gated) | Median | Bar (D-10) |
|------|----------------:|-------:|-----------:|
| Enemies | 300 | 300 | 300 |
| Units | 50 | 50 | 50 |
| Arrows | 237 | 257 | 200 |

Counted on every 30th frame of the measured window (170 samples in the median run); the minimum arrows of all three runs were 237 (04-21: 239). All 300 grunts had spawned before the measured window began (`spawned_at_start` 300). The crowd, the arrows and the framing are what they were; only how fast the frame is made changed.

### With-step and without-step frames

In the median run 603 of 5119 frames (12 percent; the tick is 30 Hz and the frame rate is now about 256 fps, so a step lands on one frame in about eight) ran a simulation step, taken as a step of 0.5 ms or more (the other 4516 frames spend under 0.2 ms calling `ctx.advance` without a tick). On those frames the step took 4.53 ms on average (p50 4.09, p95 6.80, max 36.37 ms; 04-21 read 3.39 ms on average in the window against 2.33 ms headless, so the window run costs the step more than the dummy-renderer probe, and this session reads about 1 ms higher still, which is the laptop's session drift and not a code change: the headless probe below is within 0.15 ms of 04-21's):

| Frames | p50 frame ms | p95 frame ms |
|--------|-------------:|-------------:|
| With a step (603) | 3.70 | 5.56 |
| Without a step (4516) | 3.70 | 5.31 |

(Runs 1 and 3: step frames 601 and 601, p50 3.33 and 3.70, p95 5.16 and 5.56; frames without a step 4831 and 4483, p50 3.58 and 3.70, p95 5.00 and 5.56.) In 04-21 a frame cost the same with or without the step and the p95 was set by something every frame paid, the three view loops; now, in the published run, a step frame costs 0.25 ms more at the p95 than a plain frame (runs 1 and 3: 0.16 and 0.00 ms more), which is the step showing through at most, and the all-frames p95 (5.37 ms) sits between the two. Nothing every frame pays dominates any more.

### Where the step goes (the committed attribution probe, run before the real-window runs)

`bash tools/godot.sh --headless --path . -s res://tools/stress/step_attribution.gd -- --runs=3 --out=build/bench/attribution.txt` (headless, dummy renderer, ablation deltas by the variant method of the 04-09 report, so the phases need not add up) wrote build/bench/attribution.txt:

```
VARIANT full mean_ms=2.47
VARIANT no_towers mean_ms=1.83
VARIANT no_squads mean_ms=1.00
VARIANT enemies_only mean_ms=0.46
PHASE total ms=2.47
PHASE towers ms=0.63
PHASE squads ms=1.47
PHASE enemies ms=0.46
PHASE rest ms=-0.09
STEP_ATTRIBUTION_OK runs=3 enemies=300 warmup=300 steps=300
```

| Phase | 04-09 profile (GDScript) | 04-21 probe | This run |
|-------|-------------------------:|------------:|---------:|
| Total step | 22.2 ms | 2.33 ms | **2.47 ms** |
| Enemies | 15.6 ms | 0.48 ms | **0.46 ms** |
| Squads (50 units: orders, slot walks, goal-field walks) | 2.7 ms | 1.34 ms | **1.47 ms** |
| Towers (20 towers, 300 targets) | 2.1 ms | 0.49 ms | **0.63 ms** |
| Rest | 1.8 ms | 0.02 ms | **-0.09 ms** |

The step was not touched by this round (plans 04-24 to 04-27 changed the view layer, the stamp and the tools), so the step reads as before within the laptop's drift of 0.1 to 0.15 ms per phase; the squads are still its largest piece (1.47 ms of 2.47 ms). The five stress-shape `step_bench` lines read 2.55, 2.51, 4.10, 2.25 and 2.33 ms (median **2.51 ms**; p95 2.63 to 7.63 ms, max 3.57 to 31.35 ms, the 4.10 ms run carrying a 31 ms single-frame spike) and the five prototype lines 1.19, 0.97, 1.58, 0.98 and 0.99 ms (median **0.99 ms**), appended to build/bench/final.txt; 04-21 read 2.47 ms and 0.96 ms. The step side did not move, which is the point: the improvement below comes from the view layers alone.

### Bench medians per port plan (the step)

| Plan (what moved to C++) | Stress step, before | Stress step, after | Prototype step, before | Prototype step, after |
|--------------------------|--------------------:|-------------------:|-----------------------:|----------------------:|
| 04-09 baseline (GDScript, profile / bench) | 22.2 ms | | 20.1 to 22.9 ms | |
| 04-15 push-apart and the gd_math table | 39.37 ms | 28.75 ms | 35.23 ms | 26.57 ms |
| 04-17 wall solid test | 26.86 ms | 29.75 ms (A/B gain 5.10 ms) | 25.78 ms | 22.36 ms |
| 04-18 flow-field reads and castle routing | 23.89 ms | 22.78 ms | 23.93 ms | 22.80 ms |
| 04-23 structure index and wall decision | 22.78 ms | 17.88 ms | 22.80 ms | 11.35 ms |
| 04-19 the enemy store and step | 17.88 ms | 4.58 ms | 11.35 ms | 2.07 ms |
| 04-20 nearest-enemy query and stuck tracker | 4.58 ms | 2.18 ms | 2.07 ms | 1.08 ms |
| 04-21 re-measurement | | 2.47 ms | | 0.96 ms |
| **Now (this plan, HEAD 9282d64, no step change since)** | | **2.51 ms** | | **0.99 ms** |

### The view fills: bench medians per view plan

`view_fill_bench.gd` (headless, dummy renderer, script and buffer cost only, 1440 warm-up and 720 timed frames at 1/144 s) is the per-view check each port plan used; "now" is the median of three runs per view of this plan (`build/bench/view_final.txt`), the other columns are as the SUMMARYs of 04-24 to 04-27 recorded them (their own medians of three or five runs). Medians in microseconds per frame:

| View (plan) | 04-24 baseline (before any port) | The plan's own before | The plan's own after | Ratio (plan before / after) | Now (this plan) | Now against the 04-24 baseline |
|-------------|---------------------------------:|----------------------:|---------------------:|----------------------------:|----------------:|-------------------------------:|
| Arrows (04-25) | 2736.99 | 2280.07 | 74.44 | 30.6 | **57.44** | 47.6 times lower |
| Enemies (04-26) | 611.33 | 758.89 | 73.12 (38.13 on the final build) | 10.4 (19.9) | **38.97** | 15.7 times lower |
| Units (04-27) | 177.25 | 273.88 | 30.16 | 9.1 | **25.23** | 7.0 times lower |
| Puffs (04-26) | 105.79 | 140.05 | 4.63 | 30.2 | **6.36** | 16.6 times lower |
| **Sum of the four views** | **3631.36 (3.63 ms)** | | | | **128.00 (0.13 ms)** | **28.4 times lower** |

The nine "now" lines (three runs per view, sorted by mean_us, the middle one is the median):

```
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=57.44 p95_us=91.00 max_us=171.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=58.73 p95_us=89.00 max_us=176.00 drawn_max=507
VIEW_FILL_BENCH view=arrows warmup=1440 frames=720 mean_us=53.59 p95_us=88.00 max_us=197.00 drawn_max=507
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=38.88 p95_us=62.00 max_us=163.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=40.49 p95_us=69.00 max_us=169.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=38.97 p95_us=63.00 max_us=106.00 drawn_max=300
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=23.92 p95_us=77.00 max_us=153.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=25.23 p95_us=79.00 max_us=137.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=26.29 p95_us=87.00 max_us=141.00 drawn_max=50
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=6.36 p95_us=7.00 max_us=25.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=11.27 p95_us=14.00 max_us=121.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=5.25 p95_us=6.00 max_us=20.00 drawn_max=87
```

(The arrows bench fills about 507 of the 512 slots, a ceiling for the real window's roughly 250 arrows; the puffs bench's three lines were taken in the order shown and the median is the 6.36 us line.) The sum fell from 3.63 ms to 0.13 ms of script and buffer work per frame, and the real-window ablation below shows the same thing from the other side.

### The residual, attributed by the committed probe (view ablation)

`bash tools/godot.sh --path . --resolution 1920x1080 -s res://tools/stress/view_ablation.gd -- --duration=60 --warmup=10 --run=9 --out=build/stress/ablation` (the committed probe of plan 04-24, real window, nothing else running, two trials of six 5 s slices after the 10 s warm-up) wrote build/stress/ablation/ablation.txt, whole:

```
ABLATION_SLICE trial=1 slice=all_on frames=1323 p50_ms=3.70 p95_ms=5.00 mean_ms=3.78
ABLATION_SLICE trial=1 slice=enemy_views_off frames=1356 p50_ms=3.33 p95_ms=5.56 mean_ms=3.69
ABLATION_SLICE trial=1 slice=unit_views_off frames=1349 p50_ms=3.33 p95_ms=5.56 mean_ms=3.71
ABLATION_SLICE trial=1 slice=projectile_vfx_off frames=1327 p50_ms=3.38 p95_ms=5.56 mean_ms=3.77
ABLATION_SLICE trial=1 slice=all_off frames=1414 p50_ms=3.33 p95_ms=5.03 mean_ms=3.54
ABLATION_SLICE trial=1 slice=all_on_again frames=1323 p50_ms=3.70 p95_ms=5.56 mean_ms=3.78
ABLATION_SLICE trial=2 slice=all_on frames=1335 p50_ms=3.33 p95_ms=5.56 mean_ms=3.75
ABLATION_SLICE trial=2 slice=enemy_views_off frames=1363 p50_ms=3.33 p95_ms=5.56 mean_ms=3.67
ABLATION_SLICE trial=2 slice=unit_views_off frames=1322 p50_ms=3.70 p95_ms=6.06 mean_ms=3.78
ABLATION_SLICE trial=2 slice=projectile_vfx_off frames=1404 p50_ms=3.33 p95_ms=5.00 mean_ms=3.56
ABLATION_SLICE trial=2 slice=all_off frames=1408 p50_ms=3.33 p95_ms=5.56 mean_ms=3.55
ABLATION_SLICE trial=2 slice=all_on_again frames=1305 p50_ms=3.70 p95_ms=5.56 mean_ms=3.83
ABLATION_SAVED slice=enemy_views_off mean_ms=0.09
ABLATION_SAVED slice=unit_views_off mean_ms=0.02
ABLATION_SAVED slice=projectile_vfx_off mean_ms=0.10
ABLATION_SAVED slice=all_off mean_ms=0.22
VIEW_ABLATION_OK trials=2 slice_s=5
```

The same probe's baseline from before any port (04-24, unchanged views) and 04-21's scratch trials beside this run, mean frame ms and p95 per slice (trial 1 [trial 2]):

| Slice (5 s each) | Now: mean / p95 | 04-24 baseline: mean / p95 | 04-21 scratch: mean / p95 |
|------------------|----------------:|---------------------------:|--------------------------:|
| All three views on | 3.78 [3.75] / 5.00 [5.56] | 7.59 [6.77] / 12.39 [9.09] | 7.14 [6.98] / 11.32 [10.43] |
| EnemyViews off | 3.69 [3.67] / 5.56 [5.56] | 5.94 [5.79] / 9.09 [8.33] | 6.09 [5.88] / 8.33 [8.33] |
| UnitViews off | 3.71 [3.78] / 5.56 [6.06] | 6.57 [6.95] / 10.94 [10.74] | 6.51 [6.63] / 10.42 [10.00] |
| ProjectileVfx off | 3.77 [3.56] / 5.56 [5.00] | 4.77 [5.33] / 7.58 [8.33] | 5.00 [5.15] / 7.41 [6.67] |
| All three off | 3.54 [3.55] / 5.03 [5.56] | 3.39 [3.38] / 4.17 [4.52] | 3.60 [3.59] / 4.55 [4.55] |
| All three on again (drift check) | 3.78 [3.83] / 5.56 [5.56] | 7.58 [7.86] / 11.11 [12.96] | 7.53 [7.53] / 12.50 [11.67] |

| Mean frame ms saved vs all on (ABLATION_SAVED) | Now | 04-24 baseline | 04-21 scratch (trial 1 [trial 2]) |
|------------------------------------------------|----:|---------------:|---------------------------------:|
| EnemyViews off | 0.09 | 1.32 | 1.05 [1.10] |
| UnitViews off | 0.02 | 0.42 | 0.63 [0.35] |
| ProjectileVfx off | 0.10 | 2.13 | 2.14 [1.83] |
| All three off | **0.22** | **3.80** | 3.54 [3.39] |

Reading: before the round the three view loops were 3.4 to 3.8 ms of a 7.1 to 7.6 ms mean frame, almost exactly the gap between the all-on and all-off slices; now switching them off saves 0.22 ms of a 3.78 ms mean frame (well inside the 0.4 ms drift the earlier sections state for this probe), and the all-on slices sit at the all-off slices' level: the views are no longer a cost worth attributing. What is left is the floor the all-off slices always had: a mean frame of about 3.5 ms (04-24: 3.4 ms), made of the step (0.55 ms mean, 4.5 ms on the one frame in eight that runs it), the renderer (render CPU 0.64 ms, GPU 0.77 ms, 230 draw calls) and the engine. That floor is why the full-night p95 is 5.37 ms and not lower: the p95 is set by the step frames and the timer quantisation, not by any view. The probe's embedded stress run (`STRESS_RUN run=9 frames=16229 p50_ms=3.33 p95_ms=5.56 p99_ms=6.25 max_ms=13.80 enemies_min=300 units_min=50 arrows_min=240`) is not a budget measurement (the views were switched off for a share of it); the budget is judged by the three runs above.

### Wall-break rebuild (UAT test 10: the hitch the owner accepted for now)

`bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- --enemies=300 --steps=30 --rebuilds=16` after the stress runs and the ablation, nothing else running:

```
STEP_BENCH enemies=300 steps=30 mean_ms=1.01 p95_ms=1.18 max_ms=1.53
STEP_BENCH_REBUILD cells=5494 rebuilds=16 mean_ms=11.61 max_ms=13.48
```

| Measure | Now | After the step port (04-21) | Before (04-09) |
|---------|----:|----------------------------:|---------------:|
| Mean per rebuild | 11.61 ms | 10.00 ms | 11.74 ms |
| Maximum per rebuild | 13.48 ms | 11.74 ms | 13.22 ms |
| Break-frame estimate (median-run p50 frame plus the maximum rebuild) | 3.70 + 13.48 = 17.18 ms | 6.25 + 11.74 = 17.99 ms | 34.14 ms |

A wall break still drops about one frame at 60 fps (17.18 ms against 16.7 ms, by 0.5 ms; the rebuild itself is unchanged by this round and reads within the session's drift of earlier readings). **The owner accepted the hitch for now (UAT test 10, 2026-10-19: "pass for now, revisit later")**: it is reported here and not fixed; count-based time slicing of the rebuild stays the named alternative, a rule change that is not made. The stress night never breaks a wall (its walls carry 100000 health), so the hitch cannot show in the percentiles above.

### Budget and the GTX 970 projection (RESEARCH A1, a projection, not a measurement)

The budget is the same as before: a median-run p95 of at most 8.0 ms at 1080p, 1.0x speed, vsync off on the dev machine (D-12's documented 2x headroom on the 16.7 ms frame). **No GTX 970 was available and none was measured** (UAT test 12 is blocked by hardware). Applying RESEARCH A1 (the GPU portion 3 to 4 times slower than this RTX 3060 Laptop, the host's script work 1.3 to 1.6 times slower than this i5-10500H) to the median run:

- GPU median 0.77 ms becomes about 2.3 to 3.1 ms, far inside a frame (it was 13 to 18 ms in the 04-09 projection and 3.6 to 4.8 ms in 04-21's).
- The CPU-bound frame p50 of 3.70 ms becomes about 4.8 to 5.9 ms (about 170 to 210 fps at the median), and the p95 of 5.37 ms about 7.0 to 8.6 ms: at or under the 8.6 ms end, about half of the 16.7 ms (60 fps) line, so about 2x headroom, which is what the 8.0 ms dev-machine budget exists to guarantee. The 04-21 projection was 14.2 to 17.5 ms at the p95 (borderline) and the 04-09 projection 48 to 59 ms (3 to 4 times over).
- So the view-layer port moved the old-hardware projection from borderline at the p95 to comfortably inside the 60 fps line. It stays a projection: the same stress night on real GTX 970 hardware is the only measurement that could confirm it, and PLAT-01 is re-verified on real campaign battles in Phase 13 whatever this reads.

### Verdict and the open decision

- **PLAT-01 on the dev machine is MET:** median-run p95 5.37 ms against 8.0 ms (6.9 times better than the 37.04 ms before; 2.0 times better than 04-21's 10.95 ms; 2.63 ms, 33 percent, under the budget); p50 3.70 ms (about 256 fps); the D-10 crowd (300 / 50 / 200) is on screen at every sampled frame. G-04-5 and ROADMAP success criterion 3 are closed by measurement; PLAT-01 is marked complete in REQUIREMENTS.md.
- **Not done, by design:** the budget was not raised and fidelity was not lowered (no fewer enemies, no skipped or lengthened steps, nothing drawn fewer than alive, the stress map and tools unchanged). The squad per-unit port and a higher budget, rejected by the owner on 2026-10-20 on the numbers, were not needed.
- **What the owner re-judges:** the stress night by eye (UAT test 5), the overlay below the night banner (test 6) and melee enemies breaking through to their targets (test 13); see the update at the top of 04-PLAYTEST-GATE.md. The look of the crowd, the arrows and the army was compared before and after each port by the executors and again after this plan (SUMMARY review lines); the owner's own eye is the harvested human check.
- **Open, not blocking:** the GTX 970 transfer is a projection (test 12, blocked by hardware); the wall-break rebuild hitch is accepted for now (test 10, revisit later); on a step frame the step is 4.5 ms in the window (2.5 ms headless), the largest remaining per-frame cost and still smaller than a frame.

## After the native port (plans 04-12 to 04-23), 2026-10-19T19:54Z

Measured 2026-10-19 by plan 04-21 on the same dev machine, with the method of plan 04-09 (the measurement kept below as the before). **Verdict: the budget is still NOT met.** The median run's p95 frame time is **10.95 ms against the unchanged 8.0 ms budget** (1.37 times over; it was 37.04 ms, 4.6 times over), with the D-10 on-screen bar met in full (300 enemies, 50 units and 239 or more arrows in view at every sampled frame). The port bought a factor of 3.4 on the p95 and on the median frame (p50 20.92 ms to 6.25 ms, about 43 fps to about 142 fps), but the remaining miss is **not the simulation step any more**: the step is 2.3 ms headless and frames that run a step are no slower than frames that do not. What is left is the per-frame GDScript of the three view layers (arrows, enemies, units), measured below. Nothing was lowered or raised: no budget change (`FrameReport.BUDGET_P95_MS` is 8.0), no fewer enemies, no skipped steps. The stop rule of the plan applies; the decision on the next candidates is the owner's.

```
FRAME_REPORT_OK runs=3 median_run=2 p95_ms=10.95 budget_ms=8.0 within=false enemies=300 units=50 arrows=239
```

### What was proven first

The measured code is the proven code (`HEAD a32e65f`, native library rebuilt and stamp-checked by `bash tools/native_build.sh`, which printed `NATIVE_BUILD_OK`): the four replays and the gate, each twice, all unchanged against the owner's D-14 reading.

```
REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f
REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4
REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58
REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf
GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a
```

The port itself went green on CI in run 39310876191 (https://github.com/ABSAR07/duskhold/actions/runs/39310876191, head `b5a6f57`, every job, Linux and Windows) at plan 04-20; this plan changes no code, so that run covers the measured code.

### Method and hardware

Identical to the before below: `bash tools/stress.sh --runs=3 --duration=20` (10 s warm-up, 20 s measured, three runs, the median-p95 run published), real window, requested 1920x1080 (actual window 1920x1050, viewport 1316x720), vsync off, `Engine.max_fps = 0`, speed 1.0x, the camera at y 119.5, NVIDIA GeForce RTX 3060 Laptop GPU (Vulkan 1.4.341), Intel Core i5-10500H, Windows 11 Home, Godot 4.7.2-stable (official), Forward+. The stress map, the load numbers (300 grunts, 50 footmen, 20 towers, the gate wall, arrow speed 5 m/s) and the stress tools are exactly those of plan 04-09; nothing in `tools/stress/` changed. The machine was quiet: nothing else ran during the three runs.

### Result (median of 3 runs)

The published run is run 2 (the median by p95: 10.88, 10.95, 11.11).

| Measure | After the port | Before (04-09) |
|---------|---------------:|---------------:|
| Frames measured | 2838 (about 142 fps) | 856 (about 43 fps) |
| Frame time p50 | 6.25 ms | 20.92 ms |
| Frame time p95 | **10.95 ms** | **37.04 ms** |
| Frame time p99 | 13.33 ms | 50.00 ms |
| Worst 1 percent mean | 14.11 ms | 55.42 ms |
| Frame time max | 16.88 ms | 74.82 ms |
| Frame time mean | 6.99 ms | 23.33 ms |
| Step (ctx.advance) mean / p50 / p95 / max, all frames | 0.73 / 0.01 / 3.62 / 24.10 ms | 14.34 / 18.14 / 25.43 / 56.35 ms |
| Render CPU, median | 0.45 ms | 0.70 ms |
| Render GPU, median | 1.21 ms | 4.46 ms |
| Draw calls / objects / primitives, median | 230 / 328 / 718,998 | 230 / 328 / 718,962 |

p95 10.95 ms against the 8.0 ms budget: **over**.

### All runs

| Run | Frames | p50 ms | p95 ms | p99 ms | max ms | Published |
|-----|-------:|-------:|-------:|-------:|-------:|-----------|
| 1 | 2860 | 6.25 | 10.88 | 11.67 | 24.91 |  |
| 2 | 2838 | 6.25 | 10.95 | 13.33 | 16.88 | yes |
| 3 | 2816 | 6.52 | 11.11 | 13.15 | 56.69 |  |

The three runs agree to within 2.1 percent on p95 (10.88 to 11.11 ms), so the miss is not noise. The frame times are quantised by the host timer (6.25, 6.67, 7.58, 8.33 ms and so on), which is why the percentiles sit on those values.

### On-screen counts

| Kind | Minimum (gated) | Median | Bar (D-10) |
|------|----------------:|-------:|-----------:|
| Enemies | 300 | 300 | 300 |
| Units | 50 | 50 | 50 |
| Arrows | 239 | 254 | 200 |

Counted on every 30th frame of the measured window (94 samples in the median run); the minimum arrows of all three runs were 239. All 300 grunts had spawned before the measured window began (`spawned_at_start` 300).

### Where the step goes now (the committed attribution probe, run before the real-window runs)

The probe of plan 04-20 was rerun exactly as `bash tools/godot.sh --headless --path . -s res://tools/stress/step_attribution.gd -- --runs=3 --out=build/bench/attribution.txt`, which wrote build/bench/attribution.txt (headless, dummy renderer, ablation deltas by the variant method of the 04-09 report, so the phases need not add up):

```
VARIANT full mean_ms=2.33
VARIANT no_towers mean_ms=1.84
VARIANT no_squads mean_ms=0.99
VARIANT enemies_only mean_ms=0.48
PHASE total ms=2.33
PHASE towers ms=0.49
PHASE squads ms=1.34
PHASE enemies ms=0.48
PHASE rest ms=0.02
STEP_ATTRIBUTION_OK runs=3 enemies=300 warmup=300 steps=300
```

| Phase | 04-09 profile (GDScript) | Plan 04-20 probe | This run |
|-------|-------------------------:|-----------------:|---------:|
| Total step | 22.2 ms | 2.42 ms | **2.33 ms** |
| Enemies (the stuck tracker and hit resolution are inside this floor) | 15.6 ms | 0.58 ms | **0.48 ms** |
| Squads (50 units: orders, slot walks, goal-field walks) | 2.7 ms | 1.41 ms | **1.34 ms** |
| Towers (20 towers, 300 targets) | 2.1 ms | 0.45 ms | **0.49 ms** |
| Rest | 1.8 ms (stuck tracker 1.4, king, hits, removal 0.4) | -0.02 ms | **0.02 ms** |

Every residual cost the diagnosis named is now a number: the squads are the largest piece of the step (1.34 ms, 58 percent of 2.33 ms), then the towers (0.49 ms) and the enemy step with its stuck tracker (0.48 ms); the step as a whole is 2.33 ms where 04-09 measured 22.2 ms (9.5 times lower), and well under the 5 to 6 ms the diagnosis said the budget needs.

### Bench medians per port plan

Stress-shape and prototype `step_bench` means, medians of five runs, as each plan's SUMMARY recorded them (the laptop drifts between sessions, and each pair is a plan's own before and after, so the figures are an upper bound on what a single plan did; the per-plan SUMMARYs hold the interleaved A/B corroboration):

| Plan (what moved to C++) | Stress step, before | Stress step, after | Prototype step, before | Prototype step, after |
|--------------------------|--------------------:|-------------------:|-----------------------:|----------------------:|
| 04-09 baseline (GDScript, profile / bench) | 22.2 ms | | 20.1 to 22.9 ms | |
| 04-15 push-apart and the gd_math table | 39.37 ms | 28.75 ms | 35.23 ms | 26.57 ms |
| 04-17 wall solid test | 26.86 ms | 29.75 ms (A/B gain 5.10 ms) | 25.78 ms | 22.36 ms |
| 04-18 flow-field reads and castle routing | 23.89 ms | 22.78 ms | 23.93 ms | 22.80 ms |
| 04-23 structure index and wall decision | 22.78 ms | 17.88 ms | 22.80 ms | 11.35 ms |
| 04-19 the enemy store and step | 17.88 ms | 4.58 ms | 11.35 ms | 2.07 ms |
| 04-20 nearest-enemy query and stuck tracker | 4.58 ms | 2.18 ms | 2.07 ms | 1.08 ms |
| **Now (this plan, HEAD a32e65f)** | | **2.47 ms** | | **0.96 ms** |

The five stress-shape lines of this plan read 2.47, 2.37, 2.49, 2.38 and 2.52 ms (p95 3.36 to 3.90 ms, max 5.52 to 9.02 ms), the five prototype lines 0.91, 1.17, 0.95, 0.97 and 0.96 ms (appended to build/bench/final.txt). The 0.3 ms difference from plan 04-20's 2.18 ms is the laptop's session drift; both are in the same band.

### The remaining miss: the view layers, not the step

The real-window run shows that the step is not what sets the frame time any more. In the median run 600 of 2838 frames (21 percent) ran a simulation step (the tick is 30 Hz); on those frames the step took 3.39 ms on average (p50 3.04, p95 5.16, max 24.10 ms, against 2.33 ms headless; the window run is not expected to match the dummy-renderer figure), yet:

| Frames | p50 frame ms | p95 frame ms |
|--------|-------------:|-------------:|
| With a step (600) | 6.25 | 11.11 |
| Without a step (2238) | 6.25 | 10.61 |

(The same split in runs 1 and 3: step frames p50 6.25 and 6.67, p95 11.11 and 10.89; frames without a step p50 6.25 and 6.48, p95 10.68 and 11.11.) A frame costs about the same with or without the 3.4 ms step, so the p95 is set by something every frame pays. The renderer is again healthy (render CPU 0.45 ms, GPU 1.21 ms, 230 draw calls); the rest is the main thread's per-frame script work: `EnemyViews._process` (a GDScript loop over the 300-enemy read view, one `CrowdBatch.add` each), `UnitViews._process` (50 units), and `ProjectileVfx._process` (about 250 arrows in flight, each with a target-position lookup and an arrow transform every frame).

To put numbers on it, a scratch probe (never committed, like the 04-09 profile) launched the stress night in the real window and, after the 10 s warm-up, switched the `_process` of those three view nodes off and on in 5 s slices, taking the frame-time percentiles of each slice. It changes nothing in the simulation or in what is built; with a view's `_process` off its multimesh simply stops updating, so this is an attribution, not a proposed change. Two trials (the second in brackets):

| Slice (5 s each) | Frames | p50 ms | p95 ms | Mean ms | Mean saved vs all on |
|------------------|-------:|-------:|-------:|--------:|---------------------:|
| All three views on | 700 [716] | 6.52 [6.67] | 11.32 [10.43] | 7.14 [6.98] | |
| EnemyViews off | 821 [850] | 5.56 [5.56] | 8.33 [8.33] | 6.09 [5.88] | 1.05 [1.10] |
| UnitViews off | 769 [754] | 6.06 [6.06] | 10.42 [10.00] | 6.51 [6.63] | 0.63 [0.35] |
| ProjectileVfx off | 1000 [971] | 4.76 [5.00] | 7.41 [6.67] | 5.00 [5.15] | 2.14 [1.83] |
| All three off | 1390 [1395] | 3.70 [3.53] | **4.55 [4.55]** | 3.60 [3.59] | 3.54 [3.39] |
| All three on again (drift check) | 665 [664] | 6.94 [6.94] | 12.50 [11.67] | 7.53 [7.53] | |

With the three view loops off, the p95 of the whole night (the step, the renderer and the engine included) is **4.55 ms, under the 8.0 ms budget**, in both trials. The arrows are the largest piece (about 2.0 ms of the mean frame), the enemy views next (about 1.1 ms), the unit views last (about 0.5 ms); the all-on slices before and after drift by about 0.4 ms of mean and 1.2 ms of p95, so each saving is good to about that much. This is the finding the next plan must act on: the step port is done (2.33 ms), and the budget is now a presentation cost.

### Wall-break rebuild (UAT test 10: the hitch the owner accepted for now)

`bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- --enemies=300 --steps=30 --rebuilds=16` after the stress runs, nothing else running:

```
STEP_BENCH enemies=300 steps=30 mean_ms=0.82 p95_ms=0.89 max_ms=0.99
STEP_BENCH_REBUILD cells=5494 rebuilds=16 mean_ms=10.00 max_ms=11.74
```

| Measure | After the port | Before (04-09) |
|---------|---------------:|---------------:|
| Mean per rebuild | 10.00 ms | 11.74 ms |
| Maximum per rebuild | 11.74 ms | 13.22 ms |
| Break-frame estimate (median-run p50 frame plus the maximum rebuild) | 6.25 + 11.74 = 17.99 ms | 34.14 ms |

A wall break still drops about one frame (17.99 ms against 16.7 ms), now by a margin of 1.3 ms rather than 17 ms. **The owner accepted the hitch for now (UAT test 10, 2026-10-19: "pass for now, revisit later")**: it is reported here and not fixed; count-based time slicing of the rebuild stays the named alternative, a rule change that is not made. The stress night never breaks a wall (its walls carry 100000 health), so the hitch cannot show in the percentiles above.

### Budget and the GTX 970 projection (RESEARCH A1, a projection, not a measurement)

The budget is the same as before: a median-run p95 of at most 8.0 ms at 1080p, 1.0x speed, vsync off on the dev machine (D-12's documented 2x headroom on the 16.7 ms frame). **No GTX 970 was available and none was measured** (UAT test 12 is blocked by hardware). Applying RESEARCH A1 (the GPU portion 3 to 4 times slower than this RTX 3060 Laptop, the host's script work 1.3 to 1.6 times slower than this i5-10500H) to the median run:

- GPU median 1.21 ms becomes about 3.6 to 4.8 ms, well inside a frame; it no longer approaches the 16.7 ms line (it was 13 to 18 ms in the 04-09 projection).
- The CPU-bound frame p50 of 6.25 ms becomes about 8.1 to 10.0 ms (about 100 to 123 fps at the median), and the p95 of 10.95 ms about 14.2 to 17.5 ms: right at the 16.7 ms (60 fps) line at the pessimistic end. The 04-09 projection was 48 to 59 ms at the p95, 3 to 4 times over that line.
- So the port moved the old-hardware projection from far over 60 fps to borderline at the p95, and the median frame to above 100 fps, but the 8.0 ms dev-machine budget, which exists to give the old machine that headroom, is not met.

### Verdict and the open decision

- **PLAT-01 on the dev machine is NOT met:** median-run p95 10.95 ms against 8.0 ms (3.4 times better than the 37.04 ms before; 1.37 times over the budget); p50 6.25 ms (about 142 fps); the D-10 crowd (300 / 50 / 200) is on screen at every sampled frame. PLAT-01 stays Pending in REQUIREMENTS.md and ROADMAP success criterion 3 stays open.
- **Not done, by design:** the budget was not raised and fidelity was not lowered (no fewer enemies, no skipped or lengthened steps, nothing drawn fewer than alive, the stress map and tools unchanged).
- **Next candidates, from the numbers (the owner decides; no plan is written now):**
  1. **The view layers' per-frame loops**, which the real-window ablation shows hold the gap: `ProjectileVfx._process` (about 2.0 ms of the mean frame; arrow flight moved into C++ batching, or animated on the GPU from an origin, a target and a launch time so a frame writes nothing per arrow), `EnemyViews._process` (about 1.1 ms; the read view is already packed, so the fill of the multimesh buffers is the loop to port) and `UnitViews._process` (about 0.5 ms). Together they are 3.4 to 3.5 ms of the mean frame and the whole difference between a 4.55 ms and a 10.95 ms p95. No rule and no view changes; the same pins-first, byte-identical-digest approach applies to anything that reads the simulation, and the drawn result can be compared by screenshot.
  2. **The squad per-unit port** (orders, slot walks, goal-field walks), which 04-20's flagged assumption and the plan's rule name when squads are the largest remaining step phase (they are: 1.34 ms of 2.33 ms). It is a smaller prize than it looks in the real window: it can take at most about 1.3 ms off the 21 percent of frames that run a step, and frames without a step already sit at a p95 of 10.6 ms, so it cannot reach 8.0 ms alone. It would be worth doing after the first candidate, not instead of it.
  3. The towers (0.49 ms) and the enemy step with the stuck tracker (0.48 ms) are small; porting them gains less than the run-to-run drift.

## Before the native port: the plan 04-09 measurement (2026-10-16), kept as written

Measured 2026-10-16 by plan 04-09 on the owner's dev machine. **Verdict: the budget is NOT met.** The median run's p95 frame time is 37.04 ms against the 8.0 ms budget (4.6 times over), with the D-10 on-screen bar met in full (300 enemies, 50 units and 239 or more arrows in view at every sampled frame). The simulation step, not the renderer, is what misses. The plan's first lever (packed storage inside EnemySystem) was not pulled because the measurements below bound its gain at about 1 ms of a 22 ms step; the plan's stop rule applies and the decision is the owner's (see "Verdict and the open decision").

## Method

- **Scene:** `tools/stress/stress_night.tscn` (tools-only, export-excluded, never in CI, never headless). It instances the prototype map scene on `tools/stress/stress_map.tres` with run seed 1 and builds every plot through `ctx.buildings.apply_next_tier`: the 80 m gate wall (4 m gate at x -2 to 2 on z 30), 20 stress towers in two rows (z 12 and z 20, x -27 to 27 every 6 m) and two stress barracks at (-12, 0, 6) and (12, 0, 6) that field 25 stress footmen each. It steps once by day so the squads fill, starts night 1 (300 stress grunts from four spawn points beyond the wall, all spawned by about 8.5 s of simulation) and parks the king at (0, 0, 14).
- **Load numbers:** the stress grunt, footman, tower and barracks carry 100000 health so the crowd stays at full size for the whole window; their speed, size and attacks are the shipped ones. The stress tower shoots every 0.15 s, 30 m range, damage 1, **arrow speed 5 m/s** (real hits through `PendingHits`, RESEARCH Open Question 7). The plan's first value was 8 m/s; with it the minimum arrows in view fell to 186 inside a 5 s trial, below the 200 bar, so only the tools-only arrow speed was changed (the 300 / 50 / 200 bar did not move).
- **Measurement:** real window, vsync off (`DisplayServer.VSYNC_DISABLED`), `Engine.max_fps = 0`, speed 1.0x (nothing writes the time scale), 10 s warm-up then 20 s measured, three runs (`bash tools/stress.sh --runs=3 --duration=20`), the run with the median p95 published. StressNight turns the map root's own `_process` off and feeds the real frame delta to `ctx.advance` itself so the step can be timed.
- **Camera:** the active camera sits straight above the centre of the play area at **y = 119.5 m**, fov 40 (vertical), looking down with world -z as screen up, so the box x -44 to 44, y 0 to 3, z -16 to 64 is inside the frustum; its eight corners are tested with `Camera3D.is_position_in_frustum` before the warm-up (`STRESS_FRAMING_FAILED` would quit 1; it did not fire). The box holds the 80 m wall with 4 m to spare, the spawn scatter out to z 59, the towers, the barracks and the crowd round the castle. The sun's shadow distance is raised to 400 m so the shadow pass still reaches a camera this high. The crowd is drawn smaller than in play, which trims fragment cost a little.
- **Columns:** *frame* is the delta Godot reports between two `_process` calls, less the time the previous frame spent counting what is on screen; *step* is the time of `ctx.advance(delta)` that frame (0 when no simulation step ran, the sum when several did); *render CPU* and *render GPU* are `RenderingServer.viewport_get_measured_render_time_cpu` and `_gpu`; draw calls, objects and primitives are the `Performance` monitors. Every 30th frame the enemies, units and arrows drawn at their drawn positions are counted inside the camera frustum; the gated number is the minimum over those samples.
- **Budget it was judged against:** the median run's p95 at or under 8.0 ms (`FrameReport.BUDGET_P95_MS`, D-12) and the minimum counts at or over 300 / 50 / 200. p99, the worst-1 percent mean and the maximum are reported, not gated.

## Hardware and build

| Item | Value |
|------|-------|
| GPU | NVIDIA GeForce RTX 3060 Laptop GPU (vendor NVIDIA), Vulkan 1.4.341; Windows driver 32.0.16.1088 (a second adapter, Intel UHD Graphics, was not the one rendering) |
| CPU | Intel Core i5-10500H @ 2.50 GHz (6 cores) |
| OS | Windows 11 Home |
| Godot | 4.7.2-stable (official), `Godot_v4.7.2-stable_win64_console.exe` |
| Renderer | Forward+ (Vulkan) |
| Window | requested 1920x1080 (`--resolution 1920x1080`); actual window 1920x1050; the viewport is 1316x720 in canvas-items stretch units (same 1.83 aspect) |
| vsync / fps cap / speed | off / none (0) / 1.0x |
| Commit measured | simulation and stress code of `2d1248a` (plan 04-09 Task 1); nothing under `simulation/` changed since 04-08 |

## Result (median of 3 runs)

The published run is run 1 (the median by p95: 36.58, 37.04, 38.89).

| Measure | Value |
|---------|------:|
| Frames measured | 856 (about 43 fps) |
| Frame time p50 | 20.92 ms |
| Frame time p95 | **37.04 ms** |
| Frame time p99 | 50.00 ms |
| Worst 1 percent mean | 55.42 ms |
| Frame time max | 74.82 ms |
| Frame time mean | 23.33 ms |
| Step (ctx.advance) mean / p50 / p95 / max | 14.34 / 18.14 / 25.43 / 56.35 ms |
| Render CPU, median | 0.70 ms |
| Render GPU, median | 4.46 ms |
| Draw calls, median | 230 |
| Objects, median | 328 |
| Primitives, median | 718,962 |

p95 37.04 ms against the 8.0 ms budget: **over**.

## All runs

| Run | p50 ms | p95 ms | p99 ms | max ms | Published |
|-----|-------:|-------:|-------:|-------:|-----------|
| 1 | 20.92 | 37.04 | 50.00 | 74.82 | yes |
| 2 | 18.06 | 38.89 | 50.00 | 62.61 |  |
| 3 | 19.44 | 36.58 | 44.77 | 65.60 |  |

The three runs agree to within 6 percent on p95, so the miss is not noise. (Run 2's GPU median was 3.10 ms against 4.46 and 4.24 ms in runs 1 and 3; its frame times are no better, which says the GPU is not what sets them.)

## On-screen counts

| Kind | Minimum (gated) | Median | Bar (D-10) |
|------|----------------:|-------:|-----------:|
| Enemies | 300 | 300 | 300 |
| Units | 50 | 50 | 50 |
| Arrows | 239 | 249 | 200 |

Counted on every 30th frame of the measured window (28 samples in the median run); the other two runs' minimum arrows were 238 and 238. All 300 grunts had spawned before the measured window began (`spawned_at_start` 300 in every run).

## Budget and the GTX 970 assumption

- **Budget:** a median-run p95 of at most 8.0 ms at 1080p, 1.0x speed, vsync off on the dev machine. It is D-12's documented equivalent of 60 fps on a GTX 970-class machine: 8.0 ms is 2x headroom on the 16.7 ms frame, because the dev GPU is well above a GTX 970 (RESEARCH Open Question 2, decided in plan 04-09).
- **Scaling assumption (RESEARCH A1):** a GTX 970 renders the GPU portion about 3 to 4 times slower than this RTX 3060 Laptop, and its era's host CPU runs the GDScript step about 1.3 to 1.6 times slower than this i5-10500H. **No GTX 970 was available and none was measured.**
- **Projection from the median run:** GPU median 4.46 ms becomes 13 to 18 ms; the CPU-bound frame p50 of 20.92 ms (of which the step is the bulk) becomes 27 to 33 ms, so about 30 to 37 fps at the median, and the p95 of 37.04 ms becomes 48 to 59 ms. The projection is far over 16.7 ms: even a GPU-only reading of the 8 ms budget would not transfer, and the CPU-bound step makes the miss larger on older hardware, not smaller.
- **What would have to be true:** a p95 of 8.0 ms with the GPU at 4.5 ms asks the step frames (every second to fourth frame, depending on the frame rate) to cost about 7 ms in total, i.e. a step of about 5 to 6 ms. The measured step median is 18 ms.

## What dominates the frame

**The simulation step.** On a step frame the step is 18 to 25 ms and the render CPU is 0.7 ms; the GPU runs 3 to 4.5 ms in parallel, well inside the frame. Frames with a step run (about two thirds of all frames) are the slow ones. The renderer is healthy: 230 draw calls and 328 objects for 300 enemies, 50 units and 200+ arrows, render CPU 0.7 ms.

Where the step goes (a headless profile of the same stress night on this machine: the stress map's night with every plot built, the king parked at (0, 0, 14), `NightSim.step` run phase by phase with `Time.get_ticks_usec` around each, averaged over ticks 300 to 600, i.e. 10 to 20 s into the night, 300 enemies and 50 units alive; a scratch probe, not committed):

| Phase | ms per step |
|-------|------------:|
| Enemies (`EnemySystem.step`) | 15.6 |
| of which target choice (`_choose_target`) | 7.5 |
| of which push-apart (`_separate`) | 3.7 |
| of which move and strike (`_advance_and_strike`) | 2.4 |
| of which index rebuild, previous-position copy and rest | 2.1 |
| Squads (50 units) | 2.7 |
| Towers (20 towers, 300 targets) | 2.1 |
| Stuck tracker | 1.4 |
| King, hits, remove dead | 0.4 |
| **Total** | **22.2** |

Walls are the largest single added cost. The same night with the pieces taken away (same method):

| Variant | Step ms |
|---------|--------:|
| Everything (the stress night as measured) | 22.2 |
| No towers | 20.5 |
| No barracks (no units) | 20.1 |
| King parked far away | 26.5 |
| Gate wall, no towers, no barracks, king far | 21.2 |
| **No gate wall**, towers, barracks and king as measured | 14.2 |
| No gate wall, no towers, no barracks, king far (the plan 04-03 shape) | 9.3 |

So 300 marchers alone cost 9 ms (the 04-03 bench: 8.4 to 9.2 ms), the towers, squads and a crowd that fights cost 5 ms more, and the wall logic of plans 04-04 to 04-07 (line tests, the castle flow field march, the visible-structure query, wall decisions, push-out, the stuck tracker) costs another 8 to 10 ms once 300 enemies queue at a gate. `bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- --enemies=300 --steps=30` on the shipped prototype map, which has four wall runs, now reads 20.1 to 22.9 ms mean per step, where plan 04-03 recorded 8.4 to 9.2 ms before walls existed.

## Lever (a): packed storage inside EnemySystem (not pulled)

The plan names packed struct-of-arrays storage behind EnemySystem's unchanged reads as the first and only lever, to be kept byte-identical against the three replays. It was **not implemented**, on this evidence:

- A micro-benchmark on this machine (300 records, 13 field reads and writes per iteration, Godot 4.7.2 headless): Record objects 0.60 us per enemy-iteration, packed arrays 0.17 us, i.e. about 33 ns saved per field access.
- A step iteration of one enemy costs about 70 us at 300 enemies (22 ms over 300), and the per-enemy code touches on the order of 100 record fields per tick, so a storage change saves about 3 us of those 70 us: roughly 1 ms of the 22 ms step (5 percent). The time is in function calls and branching (target validity, wall line tests, flow-field march, structure queries), which a data layout does not remove.
- The budget needs the step at about 5 to 6 ms, a 3.5 to 4 times reduction. A 5 percent gain cannot close that, and the change touches a 710-line class under three golden replays, so spending it would only have delayed this report.

If the owner wants the lever pulled anyway, it can still be done as its own plan; the numbers above are what it would have to move.

## Wall-break rebuild

Plan 04-06 accepted a synchronous grid and castle-field rebuild on a wall break as a one-step hitch (RESEARCH F4 and A4: about 7 to 18 ms). It is measured here, not assumed. `bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- --enemies=300 --steps=30 --rebuilds=16`, run after the three stress runs with nothing else heavy running, breaks the first 16 intact segments of the shipped prototype map's four standing wall runs one at a time and times `Pathing.refresh()` for each (every rebuild raised `field_version()` by exactly one):

```
STEP_BENCH enemies=300 steps=30 mean_ms=21.19 p95_ms=24.07 max_ms=24.96
STEP_BENCH_REBUILD cells=5494 rebuilds=16 mean_ms=11.74 max_ms=13.22
```

| Measure | Value |
|---------|------:|
| Nav grid cells (shipped map) | 5,494 |
| Rebuilds timed | 16 |
| Mean per rebuild | 11.74 ms |
| Maximum per rebuild | 13.22 ms |
| Break-frame estimate (median-run p50 frame 20.92 ms + maximum rebuild 13.22 ms) | 34.14 ms |
| Same estimate with the rebuild scaled by RESEARCH A1's CPU factor 1.6 (rebuild alone) | 21.15 ms |

**Verdict by the plan's rule** (a break-frame estimate at or under 16.7 ms on the dev machine keeps the hitch accepted): 34.14 ms is above 16.7 ms, so a wall break does cost a dropped frame, and the named response is **count-based time slicing of the rebuild** (a fixed relaxation count per tick, the old field kept in use until the new one completes; RESEARCH Pattern 7's rebuild trigger, deterministic because it is count-based). Note that the rebuild alone, 11.7 ms on average, is already about 70 percent of a 16.7 ms frame, and an earlier trial of the same probe read 10.8 ms mean and 11.8 ms maximum, so about 11 to 13 ms is the figure. Time slicing changes how many ticks enemies take to see a breach, which is a rule change, so this plan does not make it: it is an **open point for the owner**, carried into 04-PLAYTEST-GATE.md by plan 04-11. The stress night itself never breaks a wall (its walls carry 100000 health), so the hitch cannot show in the frame percentiles above.

## Verdict and the open decision

- **PLAT-01 on the dev machine is not met:** median-run p95 37.04 ms against 8.0 ms; p50 20.92 ms (about 43 fps); the D-10 crowd is on screen as required. The cause is the simulation step (18 to 25 ms on a step frame) at the full stress load, not rendering.
- **Not done, by design:** the budget was not raised and fidelity was not lowered (no fewer enemies, no skipped or lengthened steps, nothing drawn fewer than alive). Lever (a) was not pulled (see above).
- **Options for the owner** (the plan's stop rule names the first two; the third is what the profile suggests):
  1. A GDExtension (C++) for the enemy and wall step, STACK.md's escape hatch. It is the only option that plausibly gives the 3.5 to 4 times the budget needs without changing rules.
  2. Accept a documented higher budget for the stress night, with the number the owner chooses (the current measure is 37 ms p95 at the full stress load; the shipped nights top out at 40 enemies so far, but PLAT-01 is about the largest battle).
  3. A targeted optimisation plan for the wall logic and target choice (the 8 to 10 ms the walls add, 7.5 ms of target choice, 3.7 ms of push-apart), including slicing enemy rescans or wall decisions across ticks. Slicing changes behaviour and would need its own golden decisions.
- Plans 04-10 and 04-11 depend on this plan; this plan is recorded as halted, not complete.
