# Phase 4 Frame Report: the stress night against the 8 ms budget (PLAT-01, D-10, D-12)

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
