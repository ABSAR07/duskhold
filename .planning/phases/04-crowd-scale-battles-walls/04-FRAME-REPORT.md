# Phase 4 Frame Report: the stress night against the 8 ms budget (PLAT-01, D-10, D-12)

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
