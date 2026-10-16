# Phase 4: Crowd-Scale Battles & Walls - Research

**Researched:** 2026-10-16
**Domain:** Godot 4.7.2 GDScript crowd simulation: MultiMesh batching, deterministic integer flow fields, destructible wall segments, stress measurement
**Confidence:** HIGH on measured facts (every number below was produced by a probe run this session); MEDIUM on the projected end state (the optimisations are prototyped in pieces, not yet end to end)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried forward (locked before this discussion, do not re-litigate)**
- Stack, the simulation / presentation / data split, `.tres` content referenced by id, the command/intent layer, the event bus, CC0-only assets with the attribution log (`01-CONTEXT.md`).
- One building type per fixed plot (Phase 1 D-02), linear tiers (D-10), every tunable number in `.tres` data, never in code. The free dawn rebuild of destroyed buildings (LOOP-04).
- The deterministic fixed-step simulation (`SimClock` 1/30 s, seeded RNG, integer event recorder, golden replays, bot playtests) and the rule that nothing under `simulation/` reads wall-clock time, the OS, the scene tree or the time scale (Phase 2 DR-1 to DR-10). Presentation never writes the simulation.
- The prototype map is the permanent sandbox (Phase 1 D-04); its ten existing plots, their positions and their balance data are not moved (Phase 3 D-03).
- Enemies commit to a target with staggered rescans; squads use the same discipline; the push-apart pass is `Separation.displacements`, shared by both systems (Phase 2 D-11, Phase 3 03-01).
- Ride-up-and-hold building, the squad command layer, the HUD and the king's numbers as signed off in Phase 3. Keyboard and mouse only; the shipped pad code stays unsupported and untouched.
- The Phase 2 balance bar: the balanced bot wins 7 or 8 of seeds 1 to 10; the bots measure, only the owner judges fun.

**Walls: plots, tiers and blocking**
- **D-01:** **One plot buys a whole wall run.** A wall plot carries a pre-drawn line of wall segments with authored gaps; holding the action key at the plot builds every segment of the run at once, and an upgrade raises every segment. The gaps are authored in map data and never move; the player's choice is which runs to buy and when to upgrade them, not where the gates are. - **Reversibility:** costly - the wall data schema (a run of segments per plot), the flow-field obstacle set and every map authored from here on assume runs with authored gaps; switching to per-segment plots would need a new plot kind and a data migration per map.
- **D-02:** **A run is made of segments, each with its own health.** Enemies attack one segment and break a hole in it while the rest of the run stands. The run's tier sets each segment's max health; `BuildingSystem` keeps one instance per plot and the wall data adds per-segment health inside it (or a sibling system the planner names).
- **D-03:** **The barricade is tier I of the Wall.** One building type, `wall`, with **three linear tiers**: tier I barricade (cheap, low health, wooden look), tier II stone wall, tier III reinforced wall. Only health rises per tier; the run's shape and its gaps never change. Costs are data on Thronefall's scale (research: barricade cheap, wall roughly 3 to 7 gold) and may move in the bot measurement (D-15).
- **D-04:** **A wall run blocks everyone on the ground**: enemies, squads and the king. Only the authored gaps let anyone through, so gate placement matters for the king's own routes. The flow field (and the king's movement) treat intact segments as solid.
- **D-05:** **A broken segment is a hole open to everyone until dawn.** It passes enemies, squads and the king like an authored gap; the field rebuilds when a segment falls or is rebuilt. Dawn rebuilds broken segments free, as LOOP-04 does for buildings (walls pay nothing, so the rebuilt marker is moot). Rubble at a hole is visual only and never blocks.
- **D-06:** **Four wall plots on the prototype map: three outer road runs and one inner ring.** One run across each of the west, east and north roads between the towers (55 m) and the spawn points (66 m), each with an authored gap on the road, plus a ring run around the castle with gaps toward the three roads. The ten existing plots stay where they are. - **Reversibility:** costly - the prototype map is the permanent sandbox; adding plots regenerates the goldens (D-14) and every balance number measured afterwards assumes these four runs.

**Enemy behaviour at walls**
- **D-07:** **Enemies are smart about walls: break through or go around, whichever is faster.** For a wall segment that has enemies aggroed onto it, the simulation computes a *time to destruction*: the segment's current health divided by the combined damage per second of every enemy aggroed onto that segment and the segments near it. It compares that with the *detour time*: how long the enemy would take to reach its target through the nearest open gap. If breaking through is faster the enemies attack the segment; otherwise they walk around. A sealed target (no open path at all) has an infinite detour, so sealed enemies always attack.
- **D-08:** **The wall decision is computed per segment on a coarse cadence, not per enemy per tick.** Only segments with aggroed enemies are evaluated, about every 0.5 s of simulation time (whole ticks from data, staggered the way rescans are), and the resulting time to destruction is published as one signal that every nearby enemy reads. The evaluation is deterministic and integer-tick scheduled like every other sim rule.
- **D-09:** **A stuck enemy is one that has made no progress toward its goal for N seconds while not attacking anything.** N is data (about 3 s). The headless gate stress test (200+ enemies through one gap) fails on any enemy still stuck at its end; the debug overlay flags stuck enemies in a distinct colour, beside the flow-field directions.

**Scale: rendering and the stress bar**
- **D-10:** **The stress night must hold 300 enemies, 50 units and 200 projectiles on screen at once** at 60 fps on GTX 970-class hardware. The per-night cap of 300 stands for shipped maps; the stress scene is allowed what it needs.
- **D-11:** **The stress scene is a tools-only stress map** under `tools/` (export-excluded, like the hold-pacing sandbox): one long wall with a single gate and one huge night. The prototype map, its goldens and its balance data are untouched by the stress work except for the wall plots of D-06.
- **D-12:** **Frame time is measured in a scripted real-window run and committed as a report.** The owner's dev machine has a modern discrete GPU well above a GTX 970, so the documented budget on it is a frame time held under about 8 ms at 1080p (2x headroom on 16.7 ms) with the scaling assumption written down. The tools script runs the stress night for a fixed duration, captures per-frame times and writes a report (p50, p95, worst 1 percent) that is committed as the documented budget. CI runs only the headless gate stress test; no frame-time check runs in CI.

**Goldens, order of work and balance**
- **D-13:** **The rendering switch lands first, with every golden byte-identical across it.** The MultiMesh view layer is its own step; `smoke`, `army` and `full_idle` must keep their digests through it, proving presentation never touched the simulation. Only then does pathing land.
- **D-14:** **The pathing change regenerates the goldens once, deliberately, with a before/after outcome report.** Success criterion 4 ("nights play the same") is read as the same outcomes (win or loss, nights survived, kills within a stated band per seed), not the same digests. The regeneration is one commit with the report beside it and the reason recorded.
- **D-15:** **The bots learn to buy walls; night counts move only if the bar breaks.** The balanced and army bots buy the wall runs as part of their build orders; the balance report shows wins over seeds 1 to 10 with and without walls. If the balanced bot still wins 7 or 8 of 10, nothing moves. If walls push it to 9 or 10 of 10, raise the counts the Phase 3 way (group counts only, no locked value). The owner judges feel at the UAT.

### Claude's Discretion
- The pathing technique behind D-07 (a flow field per goal on a grid built from the map's obstacles is the research recommendation; `NavigationServer3D` may bake the walkable grid but per-agent avoidance nodes are not used), the grid resolution, how the field is rebuilt when a segment falls or returns, and how the king's movement respects walls (the king is presentation-driven today; the planner decides where the solid test lives).
- How "aggroed to a segment" is defined, which segments count as near, and the exact DPS and detour arithmetic of D-07, kept integer-tick and deterministic.
- The MultiMesh design: one MultiMesh per archetype (grunt, skirmisher, footman, archer, arrow), per-instance custom data for the hit flash, how hurt-only health bars, selection rings, order markers and death puffs behave at hundreds of instances, and what the 256-view cap becomes. Verified with night screenshots.
- Segment length, run geometry and gap width on the prototype map within D-06, the wall's look (Kenney Castle Kit pieces are the first choice, logged in `ASSETS.md`), how the hold label names a run ("Wall II: 12 segments, 80 health each" or similar), and how a broken segment collapses.
- Wall costs and health per tier within D-03, the N of D-09, the 0.5 s cadence of D-08, all as data.
- The stress map's shape, the gate test's pass metrics beyond zero stuck (for example median time to reach the castle), and the overlay's frame-time and field readouts.
- How the bots decide when to buy walls, and the order of plans. Suggested shape: MultiMesh views first (D-13), then the wall building and map plots on straight-line pathing, then the flow field and the smart rule with the gate test, then the stress map and report, then the bot measurement and the gate.

### Deferred Ideas (OUT OF SCOPE)
- Flying enemies that ignore walls and siege enemies that target buildings first (ENMY-02, ENMY-03) - Phase 6; this phase keeps a per-enemy passability hook open for them.
- A tier that narrows the gaps (rejected option) - not planned; could be a later map gimmick.
- Rebuilding walls for gold by day (rejected option) - not planned; LOOP-04's free rebuild stands.
- A headless sim-step budget check in CI (declined for now) - could be added in Phase 13 if GDScript step cost regresses.
- The night readability pass under hundreds of units - Phase 8 (UI-05), with the screenshots this phase produces as its input.

**Not in this phase (CONTEXT `<domain>`):** the wider enemy roster, flying/siege enemies, tower specializations (Phase 6; only passability hooks); Castle Center upgrades, branching cards, other economy buildings (Phase 5); unit counters, Hero's Quarter, 1-of-4 unit choices (Phases 6 and 7); art cohesion, SFX, night readability pass (Phase 8; wall models are placeholders or Kenney Castle Kit pieces); scoring, retry, saves (Phase 9); menus and settings (Phase 13); any gamepad work (owner decision 2026-10-16).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BLDG-10 | Player can build walls and barricades that block enemy movement and upgrade linearly in health | `WallRunDef` + `WallSystem` sibling of `BuildingSystem` (which sits at the 20-public-method cap); tier health reuses `BuildingTierDef.max_health`; segment hit kind `KIND_WALL`; push-out collision for enemies, squads, king and bots; dawn restore in `_enter_dawn`; hold label from tier data (Architecture Patterns 4, 5, 6) |
| ENMY-04 | Enemies path toward their targets around or through defenses without jamming indefinitely | Integer Dial flow field on a 2 m grid with LOS shortcut, castle field plus small goal-keyed cache, integer break-or-detour rule, queue-tolerant stuck tracker, headless gate test (prototype: 200 enemies through 2.0 to 6.0 m gates all cross in 14 to 21 s) (Patterns 7 to 10, Empirical Findings F4 to F6) |
| PLAT-01 | The game holds 60 fps on GTX 970-class hardware during the largest battles | Two measured bottlenecks: the sim step (50 ms at 300 marching enemies) and node-per-entity views (about 1,100 draw calls). Exact-preserving sim hot-path pass, MultiMesh batches, packed read API, tools stress scene and frame-time report (Patterns 1 to 3, Empirical Findings F1 to F3, F7) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Directives from `.claude/CLAUDE.md` that bind every plan of this phase:
- **Stack:** Godot 4.7.2-stable standard build, GDScript with **static typing everywhere** (`untyped_declaration=2` is a compile error), GUT 9.7.1, gdtoolkit (`gdformat`, `gdlint`). Text-based scenes and resources only; headless CLI is the verification path.
- **Rendering at scale:** "do not spawn hundreds of individual `MeshInstance3D`/`CharacterBody3D` nodes for visuals"; use `MultiMeshInstance3D`. Avoid per-unit physics bodies. No per-agent RVO (`NavigationAgent3D`) at crowd scale.
- **Assets:** CC0 or equally permissive only, attribution log (`ASSETS.md`, `assets/attribution.json`) maintained; no Thronefall names or assets.
- **Platform and input:** Windows PC, **keyboard and mouse only**; the shipped pad code stays unsupported and untouched (owner decision 2026-10-16). No pad parity, prompts or tests in this phase.
- **Performance:** modest hardware (roughly GTX 970 / 4 GB RAM), 60 fps with hundreds of units and projectiles on screen.
- **Zero cost:** no paid tools or code signing.
- **Repo hygiene:** `.gitattributes` forces LF on `.gd/.tscn/.tres/.cfg`; binaries go through Git LFS; never commit `.godot/`.
- **gdlint caps (`.gdlintrc`):** `max-public-methods: 20`, `max-file-lines: 1000`, `max-line-length: 100`, `function-arguments-number: 10`, `max-returns: 6`; 20 tests per script (project convention).
- **GSD enforcement:** file-changing work starts through a GSD command (`/gsd-execute-phase` for this phase's plans).
- **Determinism (Phase 2 DR-1 to DR-12, project law):** nothing under `simulation/` reads wall-clock time, the OS, the scene tree, `Input`, the time scale, `NavigationServer` or `PhysicsServer`; integer ticks; seeded RNG only; ids only grow; iteration in id order; new `SimEvents` signals need `SimSignals.ALL` and `SimRecorder.HANDLED` entries in the same task.

## Summary

Phase 4 has two independent performance walls and one pathing risk, and the measurements below reorder the work CONTEXT suggested.

**The binding constraint is the GDScript simulation step, not rendering.** With 300 grunts marching from the three spawn points, one `RunContext.step()` costs **50 ms on average over the first 30 steps (p95 80 ms)** on this machine, against a 33.3 ms step period. The cause is not the push-apart pass (5.6 ms) but `EnemySystem._pick_nearest_structure`, which every enemy without a target runs **every tick** (140 us each, 42 ms per step at 300 enemies). A uniform grid over units, buildings and the castle returned **identical answers on 300 random positions (0 mismatches, 29 hits) in 1.1 ms instead of 40 ms**, so this fix is exact-preserving and provable with the existing byte-identical goldens. Rendering is the second wall: today's puppets cost 866 to 1,144 draw calls and 1,082 to 1,404 scene objects at 256 enemy puppets plus 28 units; one MultiMesh per archetype brings that to 118 to 141 draw calls and 207 to 264 objects and halves render-thread CPU. On the dev GPU the GPU time is about 1.7 ms either way, so the 8 ms frame budget is sim-bound until the hot paths are fixed.

**Pathing:** an integer cost field built with Dial's bucket algorithm over a 2 m grid costs about 7 ms (6,400 cells) and is rebuilt only when a wall segment is built, breaks or is restored. A prototype using the real `Separation.displacements`, a bilinear direction sample, a line-of-sight shortcut and a push-out against wall segments moved **200 enemies through a single gate of every width from 2.0 m to 6.0 m with no permanent jam (last enemy across at 13.9 to 20.7 s)**, but crowds queue for up to about 13 s, so D-09's "no progress for 3 s" flag will fire on healthy queued enemies; the pass criterion must be "everyone crosses before T_max", with the flag kept as the overlay diagnostic.

**A design choice that protects the goldens:** keep the straight-line step (the exact current `move_toward` expression) whenever no intact wall segment exists. The `smoke` and `army` goldens run on frozen fixture maps with no wall plots, and `full_idle` has no golden, so the pathing step then moves **no existing digest**, and D-14's "regenerate once" becomes "add one new `walls` golden plus the before/after outcome report" (see Open Question 1; the literal D-14 reading is also supported).

**Primary recommendation:** order the plans (1) MultiMesh view layer, goldens byte-identical (D-13); (2) a new exact-preserving sim hot-path pass (structure grid, enemy grid for `TargetQuery` and separation, packed read API), goldens byte-identical; (3) wall data, `WallSystem`, collision and views on straight-line pathing; (4) flow field, smart rule, stuck tracker, overlay, gate test; (5) tools stress map and the committed frame-time report; (6) bots, balance measurement, goldens decision and the gate. Use only Godot built-ins; there are no packages to install.

## Architectural Responsibility Map

This is a single-process offline game, so the tiers are the project's own layers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Wall segments, health, break and restore, solid test | Simulation (`simulation/walls/`) | Data (`.tres`) | Walls change who can move where and who dies; they must be deterministic and headless (D-04, D-05) |
| Flow field, LOS, break-or-detour, stuck tracking | Simulation (`simulation/nav/`) | - | Movement outcomes feed the goldens; integer tick arithmetic (D-07 to D-09) |
| Spatial indexes (structures, enemies), separation grid | Simulation | - | Pure performance rewrites of existing queries, exact-preserving |
| King solidity at walls | Presentation (`King` calls the sim's pure push-out) | Simulation (bots call the same function) | The king is presentation-driven (DR-10); one shared pure function keeps bots and player identical |
| MultiMesh batches (enemies, units, arrows, bars, puffs) | Presentation | - | Display only; reads the sim, never writes it; owns a CPU mirror for tests |
| Wall views, rubble | Presentation | - | Visual only; rubble never blocks (D-05) |
| Debug field, wall decision, stuck flags | Presentation (`EnemyPathGizmo`, `DebugOverlay`) | Simulation (read-only getters) | Existing read-only overlay pattern |
| Stress scene, frame-time report, gate test CLI | Tools (`tools/`, export-excluded) | Simulation | D-11, D-12; CI runs only the headless gate test |
| Wall plot geometry, gap widths, costs, N, cadence | Data (`MapConfig`, `WallRunDef`, `wall.tres`) | - | Every tunable is data (carried-forward rule) |

## Empirical Findings (probes run this session)

All probes ran on this machine against `Godot_v4.7.2-stable_win64_console.exe` (`Godot Engine v4.7.2.stable.official.ed1daf0bf`), scripts under the session scratchpad `.../scratchpad/research/` (no tracked file touched, no `--import` passed). Hardware: **Windows 11, NVIDIA GeForce RTX 3060 Laptop GPU (Vulkan 1.4, Forward+), Intel Core i5-10500H (6 cores)**. This is a modern discrete GPU well above a GTX 970, so every real-window number is a dev-machine number, not a GTX 970 number. [VERIFIED: probe]

### F1. Simulation step cost (headless, `bench_*.gd`)

| Scenario | Result |
|----------|--------|
| `NightSim.step`, N enemies spread 30 to 55 m from the castle (`bench_sim.gd`) | n=100: 2.52 ms, n=200: 5.93 ms, n=300: 9.47 ms per step |
| Where it goes at 300 enemies near the castle (`bench_parts.gd`, `bench_split.gd`) | `_separate` 5.2 to 5.6 ms of 9.8 to 12.5 ms; `TowerSystem.step` 1.1 ms; `ids()` copy 0.001 ms |
| **300 enemies marching from the three spawn points, 10 buildings and 25 units standing (`bench_march.gd`)** | first 30 steps mean **50.1 ms**, p50 39.8, p95 79.8, max 104.0. n=200: 37.8 ms; n=100: 24.4 ms; n=50: 15.8 ms (first 30 steps) |
| One `_pick_nearest_structure` for a far, target-less enemy (`bench_pick.gd`) | **140.6 us**, times 300 = **42.2 ms per step**; `units.ids()` 0.58 us, `standing_spot_ids()` 7.5 us |
| Same query through a structure grid, 300 random positions (`bench_grid_pick.gd`) | shipped scan 40.2 ms; grid build 0.20 ms + queries 0.87 ms; **targets found 29, mismatches vs shipped 0** |
| `Separation.displacements` vs a bucketed equivalent that accumulates each element's partners in ascending index order (`bench_sep.gd`) | **bit-identical output in all four configurations** (100 and 300 circles, spread 60 m and 12 m); my unoptimised emulation: 0.6 vs 1.1 ms (100 spread), 2.3 vs 9.8 ms (300 spread), 7.7 vs 14.1 ms (300 clumped). The O(n^2) pass alone is 4.6 to 9.8 ms at 300 |

Why it matters: `EnemySystem._choose_target` falls through to `_pick_nearest_structure` whenever the enemy has no valid target, i.e. every tick for every marching enemy (see `enemy_system.gd` lines 180 to 205). At Phase 3 scale (40 enemies) this was invisible; at 300 it is the cliff. [VERIFIED: simulation/night/enemy_system.gd:180-205 read this session]

### F2. Rendering and frame time (real window 1920x1080 request, observed client 1920x1050, vsync off, shadows on, `stress_frames.gd`)

300 enemies held near the castle, castle immortal, timed night stretched so the night never ends, 2 runs each. Enemy puppets are capped at `MAX_VIEWS: int = 256` so 44 enemies have no puppet. The MultiMesh mode is a naive prototype (default `CapsuleMesh`, id-API fill), not the target design.

| Mode | frame p50 / p95 / p99 / worst-1% mean (ms) | render CPU p50 | render GPU p50 | draw calls | objects | primitives |
|------|--------------------------------------------|----------------|----------------|-----------:|--------:|-----------:|
| Puppets (shipped code), run 1 | 9.09 / 11.11 / 13.57 / 18.06 | 1.15 ms | 1.68 ms | 913 | 1,110 | 2.79 M |
| Puppets, run 2 (machine noisier) | 10.61 / 30.22 / 42.32 / 53.79 | 1.52 ms | 2.18 ms | 866 | 1,082 | 2.63 M |
| MultiMesh prototype, run 1 | 7.58 / 10.42 / 13.49 / 17.68 | 0.53 ms | 1.79 ms | 118 | 207 | 5.22 M |
| MultiMesh prototype, run 2 | 7.41 / 9.99 / 11.52 / 14.58 | 0.51 ms | 1.74 ms | 118 | 207 | 5.22 M |

- The real-window `ctx.advance` cost per step in these runs was **8.2 to 10.9 ms p50 (p95 10.4 to 23.6 ms)**, the same order as the headless F1 numbers, and it is the largest single frame cost. The id-API MultiMesh fill added 1.1 to 1.3 ms p50 per frame.
- Primitives went **up** because the placeholder `CapsuleMesh` defaults are heavy: `default CapsuleMesh tris: 3456`, versus `CapsuleMesh radial 8 rings 2 tris: 144`. A MultiMesh does not reduce triangles; low-poly archetype meshes do.
- Run-to-run noise is real (puppets run 2). The report must take 3 runs and publish the median run. [VERIFIED: probe]

### F3. Filling MultiMesh buffers from the sim (`bench_fill.gd`, 300 enemies, headless)

| Method | Cost per frame |
|--------|---------------:|
| Today's id API (`ids()` + `previous_position_of` + `position_of` + `def_of`), lerp, 6 float writes | 1,074 us |
| Same API, 4 custom floats (prev, cur) | 511 us |
| **Struct-of-arrays (`PackedVector2Array` prev/cur), 4 custom floats** | **51 us** |
| 200 arrows lerp + arc + 6-float write on the CPU | 148 us |
| `mm.buffer = buf` call overhead (dummy server) | 2 us |

So a packed read accessor on `EnemySystem` and `UnitSystem` is worth about 20x on the fill. [VERIFIED: probe]

### F4. Flow field build cost (`bench_field.gd`, `proto_field.gd`)

| Grid | Algorithm | Time |
|------|-----------|-----:|
| 160x160 at 1 m (25,600 cells) | FIFO label-correcting, 8-neighbour, 10/14 costs (`proto_field.gd`) | 177 to 416 ms |
| 160x160 at 1 m | uniform BFS / Dial 10/14 / direction pass for every cell | 30 / 49 / 60 ms |
| 107x107 at 1.5 m | BFS / Dial / direction pass | 20 / 18 / 17 ms |
| **80x80 at 2 m (6,400 cells)** | BFS / **Dial 10/14** / direction pass | 5.9 / **7.2** / 10.6 ms |
| 320x320 at 0.5 m | BFS / Dial / direction | 108 / 134 / 153 ms |

Rasterising the blocked mask took 0.2 to 0.3 ms. A first Dial attempt that appended to `PackedInt32Array`s stored inside an `Array` produced a field of one cell: **`(buckets[d] as PackedInt32Array).append(x)` appends to a copy**; use flat parallel arrays or an `Array` of `Array`s. [VERIFIED: probe]

### F5. Gate stress prototype (`proto_field.gd`, headless, real `Separation.displacements`)

Setup: wall along z=0, one centred gate, 200 grunt-sized circles (radius 0.5, 3.2 m/s) scattered 8 to 30 m from it, goal the castle at (0,-30) radius 3.5, 1 m cells, blocked mask inflated by wall half-thickness 0.4 + agent radius 0.5, straight line when the segment to the goal is clear else the bilinear-sampled field, push-out against the wall segments after separation, arrivals removed (a sink).

| Gate width | All 200 across the wall by | Run ends (all arrived) | Longest no-progress streak before crossing |
|-----------:|---------------------------:|-----------------------:|-------------------------------------------:|
| 2.0 m | 20.7 s | 34.7 s | 3.9 s |
| 2.5 m | 18.8 s | 26.4 s | 12.8 s |
| 3.0 m | 16.5 s | 24.2 s | 11.0 s |
| 4.0 m | 15.3 s | 22.9 s | 9.6 s |
| 6.0 m | 13.9 s | 21.6 s | 8.3 s |

With the arrivals left in place as permanent obstacles (first prototype run), 118 of 200 stayed queued around the castle forever: that is a property of the test sink, not a jam at the gate, and it shows the real castle ring holds only about 29 melee enemies abreast. **Zero enemies stayed on the near side of the gate in any run.** 2 m gates pass because the inflated corridor still leaves one open cell column; authored gaps should still be at least 3 m. [VERIFIED: probe]

A separate probe confirmed that **centre-distance rasterisation of a thin 45 degree wall does not leak at 1, 2 or 3 m cells provided diagonal moves are forbidden when either orthogonal neighbour is blocked** (`leak_test.gd`: all six combinations `path leaks through the wall = false`). [VERIFIED: probe]

### F6. MultiMesh API surface on 4.7.2 (`api_multimesh.gd`, `mm_shader_test.gd`, `headless_mm.gd`, `ps.gd`)

- `MultiMesh` properties: `transform_format, use_colors, use_custom_data, custom_aabb, instance_count, visible_instance_count, mesh, buffer, transform_array, transform_2d_array, color_array, custom_data_array, physics_interpolation_quality`; methods include `set_buffer`, `set_buffer_interpolated`, `set_instance_custom_data`, `set_instance_color`, `reset_instance(s)_physics_interpolation`. `RenderingServer` has `multimesh_set_buffer`, `multimesh_set_visible_instances`, `multimesh_allocate_data`. `enum TransformFormat: ["TRANSFORM_2D", "TRANSFORM_3D"]`. [VERIFIED: probe]
- Setting `transform_format` with `instance_count` already above 0 prints `Instance count must be 0 to change the transform format.` [VERIFIED: probe]. Docs: `use_colors` and `use_custom_data` "Can only be set when instance_count is 0 or less" and `instance_count` "clears and (re)sizes the buffers" [CITED: docs.godotengine.org/en/stable/classes/class_multimesh.html].
- **Buffer layout** (undocumented, read back in a real window): per instance `[12 floats transform: xx xy xz ox, yx yy yz oy, zx zy zz oz][4 floats colour if use_colors][4 floats custom data if use_custom_data]`. A 3D + colour + custom MultiMesh of 8 instances reported a 160-float buffer (stride 20); readback gave transform origin `(0.0, 0.8, 2.0)`, custom `(1.0, 0.0, 0.0, 0.0)`, colour `(0.3, 0.3, 1.0, 1.0)` for the values written at those offsets. [VERIFIED: probe]
- `visible_instance_count` default `-1`; "Changing this does not change the sizes of the buffers" [CITED: class_multimesh.html]; probe: set 2 of 4 reads back 2. `custom_aabb`: "Setting this manually prevents costly runtime AABB recalculations" [CITED: class_multimesh.html]. The `buffer` getter "is copied" [CITED: class_multimesh.html]: never read it per frame.
- **Headless dummy renderer keeps no readback**: after `set_instance_transform(1, origin (5,6,7))` and `set_instance_custom_data`, `get_instance_transform(1).origin` printed `(0.0, 0.0, 0.0)`, `get_instance_custom_data(1)` `(0.0, 0.0, 0.0, 1.0)` and `buffer.size()` 0; after `mm.buffer = buf` the getter size was 64 but `get_instance_transform(0).origin.x` was still 0.0. Tests must read a CPU-side mirror, never the MultiMesh. [VERIFIED: probe]
- A spatial shader reads `INSTANCE_CUSTOM` and `COLOR` in `vertex()` into varyings; the flash (custom.x = 1.0 gave a white body), the instance colour (blue times red gave purple) and a **billboard health-bar quad whose fill is `UV.x <= ratio` from custom data** (ratios 1.0, 0.5, 0.1 drew as 100 %, 50 %, 10 % fills) all rendered correctly in Forward+ **and in `--rendering-method gl_compatibility --rendering-driver opengl3`**, the renderer CI uses for screenshots (colours differ slightly between the two, brighter in Forward+). CI's Mesa software GL was not run. [VERIFIED: probe for both local renderers; ASSUMED for Mesa]
- Project settings: `physics/common/physics_interpolation = false`, `physics/common/physics_ticks_per_second = 60`, `display/window/vsync/vsync_mode = 1`, `rendering/renderer/rendering_method = forward_plus`; `MultiMesh.physics_interpolation_quality` defaults to 0 (FAST). The engine's physics-interpolation path (`set_buffer_interpolated`) interpolates by the engine physics fraction, not by `RunContext.alpha()`; **leave it off and interpolate in the batch from the sim's previous and current positions**. [VERIFIED: probe; CITED: class_multimesh.html for "can be used with physics interpolation"]
- `ImmediateMesh` (the field gizmo) in a real window: 12,800 vertices rebuilt in 3.0 ms, 25,600 in 5.7 ms, 51,200 in 13.1 ms, 102,400 in 20.6 ms (p50); no vertex limit error up to 102,400. [VERIFIED: probe]
- `NavigationServer3D.bake_from_source_geometry_data` works headless (12 polygons in 31 ms for a ground plane with two obstruction outlines) but yields **polygons, not a grid**, and DR-5 bans `NavigationServer` under `simulation/`. Not used. [VERIFIED: probe]

### F7. Assets (`model_probe.gd`, `bake_view.gd`, `wall_probe.gd`)

- `character-male-a.glb` is a `Skeleton3D` with two skinned `MeshInstance3D`s (`body-mesh` 450 tris, `head-mesh` 273 tris); `character-female-a.glb` 578 + 298. `MeshInstance3D.bake_mesh_from_current_skeleton_pose()` run in a real window after the node entered the tree produced one ArrayMesh per part; merging them with `add_surface_from_arrays` (keeping each surface material) and drawing the result through a MultiMesh looked identical to the original puppet (screenshot compared). **Headless it returns null** (`baked surfaces=-1`), so the unit batch needs a capsule fallback in tests. [VERIFIED: probe]
- Kenney Castle Kit `wall.glb` (already imported and logged): two meshes, AABB 1.0 x 1.31 x 1.0 m, 178 + 32 tris. [VERIFIED: probe]

## Standard Stack

### Core (Godot 4.7.2 built-ins; nothing is installed)

| Facility | Version | Purpose | Why standard |
|----------|---------|---------|--------------|
| `MultiMesh` + `MultiMeshInstance3D` | 4.7.2 core | One instanced draw per archetype (grunt, skirmisher, footman, archer, arrow, bar, puff) | STACK.md and ARCHITECTURE.md Pattern 5; measured 8x fewer draw calls (F2) |
| `PackedFloat32Array` buffer + `multimesh.buffer = buf` | 4.7.2 | Whole-buffer upload per frame, `visible_instance_count` for the live count | 2 us call overhead, no per-instance RS calls (F3) |
| Spatial `Shader` with `INSTANCE_CUSTOM` / `COLOR` | 4.7.2 | Hit flash, hurt-only bar fill, billboard bars | Verified in Forward+ and Compatibility (F6) |
| `ImmediateMesh` | 4.7.2 | Flow-field and stuck gizmo (existing `EnemyPathGizmo` pattern) | Verified cost (F6) |
| `PackedInt32Array` / `PackedVector2Array` / `PackedByteArray` | 4.7.2 | Struct-of-arrays sim storage, nav grid, indexes | 20x cheaper reads than id-API calls (F3) |
| `RenderingServer.viewport_set_measure_render_time` + `viewport_get_measured_render_time_cpu/gpu` | 4.7.2 | CPU and GPU render split in the frame-time report | Used in `stress_frames.gd` |
| `Performance` monitors (`RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `RENDER_TOTAL_PRIMITIVES_IN_FRAME`, `RENDER_TOTAL_OBJECTS_IN_FRAME`) | 4.7.2 | Draw-call / object counts in the report | Used in `stress_frames.gd` |
| GUT | 9.7.1 (`addons/gut/plugin.cfg` line 6: `version="9.7.1"`) | Unit, integration and e2e tests | Project standard |
| gdtoolkit (`gdformat`, `gdlint`) | `.tools/venv/Scripts/gdlint.exe` present | Lint and format gate | Project standard |

### Supporting

| Facility | Purpose | When to use |
|----------|---------|-------------|
| `MeshInstance3D.bake_mesh_from_current_skeleton_pose()` | Turn the skinned Kenney character into a MultiMesh-ready ArrayMesh | Unit batch, once at bind in a real renderer; capsule fallback when it returns null |
| `Image.save_png` / `FileAccess` + `JSON.stringify` | Screenshots and the frame-time report | Tools only |
| `CapsuleMesh` with `radial_segments = 8`, `rings = 2` (144 tris) | Low-poly placeholder archetype meshes | Enemy placeholders until the Phase 8 art pass |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Own integer grid from wall data | `NavigationServer3D` bake | Polygon output, needs scene geometry, banned in `simulation/` by DR-5, 31 ms bake; rejected |
| Flow field per goal | Castle field + LOS shortcut + small goal-keyed cache (recommended) | Per-goal fields for hundreds of moving goals would rebuild constantly; the cache covers the few blocked-LOS cases |
| 1 m cells | 2 m cells (recommended) | 1 m rebuild is about 110 ms (F4); 2 m is 7 to 18 ms; needs authored gaps of at least 3 to 4 m |
| CPU lerp from packed arrays | Shader lerp from prev/cur custom data (`TIME`-free, alpha as a global uniform) | Saves 50 us of fill; costs a shader and a global parameter; not needed |
| GDScript sim with hot-path fixes | GDExtension / C# for the step | STACK.md escape hatch; only if the profile after Plan 2 still misses budget |
| Engine physics interpolation of MultiMesh | Own alpha from `RunContext.alpha()` | Engine fraction is tied to the 60 Hz physics tick, the sim is 30 Hz |

**Installation:** none. No external packages (`npm`, `pip` and `cargo` are not involved).

**Version verification:** engine 4.7.2-stable printed by every probe (`engine 4.7.2-stable (official)`); GUT 9.7.1 read from `addons/gut/plugin.cfg:6`.

## Package Legitimacy Audit

No external packages are recommended for this phase; every facility above is an engine built-in or already committed (`addons/gut`, the Kenney Castle Kit wall). No registry lookups were needed.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | - | - | - | - | - | - |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 day:  hold at a wall plot --> CommandProcessor.validate_build/BuildIntent --> BuildingSystem.apply_next_tier (tier I..III)
                                                     |  building_built(spot, building_id, tier)
                                                     v
                         WallSystem.on_tier(spot, tier): segments built/raised to tier max_health, version += 1
                                                     |
                                      NavGrid.rebuild (blocked mask from intact segments) + castle FlowField rebuild (Dial, ~7 ms)

 night step (NightSim.step, fixed order):
   spawn --> king --> squads --> towers --> castle attack --> [indexes: EnemyGrid, StructureGrid rebuilt once]
        --> wall decision pass (every wall_decision_ticks: one O(n) pass -> ttd per segment)
        --> EnemySystem.step:
              per enemy: choose target (staggered rescan; structure grid query; LOS-gated)
                      --> blocker = NavGrid.line_blocked(pos, goal)  (cached on the record at rescan)
                      --> if blocker >= 0: attack it iff ttd + straight_ticks < detour_ticks  (or sealed) else follow field
                      --> step = Pathing.step(pos, goal, reach, goal_key)   [no intact wall: the exact old move_toward]
                      --> strike through PendingHits (KIND_WALL for segments)
              then Separation (grid) --> WallSolids.push_out(pos, radius) --> StuckTracker (read-only)
        --> resolve hits (WallSystem.damage_segment -> wall_damaged / wall_segment_broken -> version += 1 -> field rebuild)
        --> remove dead
   dawn (RunManager._enter_dawn): WallSystem.restore_all() BEFORE buildings_rebuilt and the payout; field rebuild

 presentation (reads only):  RunContext.alpha() + EnemySystem packed prev/cur
        --> CrowdBatch per archetype (CPU mirror + PackedFloat32Array) --> MultiMesh.buffer, visible_instance_count
        --> HealthBarBatch (hurt only), ProjectileBatch (ring of 512), PuffBatch (ring of 128)
        --> WallViews (segment pieces, rubble) ; King calls WallSolids.push_out after move_and_slide
        --> EnemyPathGizmo / DebugOverlay: field arrows (cached per field version), stuck flags, wall ttd, frame readout

 tools:  tools/stress/stress_night.gd (real window, report)   tools/stress/gate_stress.gd (headless CLI, CI)
```

### Recommended Project Structure

```
simulation/
├── walls/
│   ├── wall_run_def.gd        # Resource: polyline, segment_length, gaps (data)
│   ├── wall_system.gd         # segments, health, version, break/restore, hit target kind (<= 20 public methods)
│   └── wall_solids.gd         # static pure push-out / closest-point / clip-move; king, bots, enemies, squads
├── nav/
│   ├── nav_grid.gd            # blocked mask + segment-owner mask + integer line_blocked (Bresenham)
│   ├── flow_field.gd          # Dial build, lazy per-cell direction, bilinear sample, cost_at
│   ├── pathing.gd             # facade used by EnemySystem and SquadSystem; castle field + goal cache; straight fallback
│   ├── wall_decision.gd       # D-07/D-08 integer ttd pass and detour compare
│   └── stuck_tracker.gd       # D-09, read-only (no events)
├── night/
│   ├── enemy_index.gd         # enemy uniform grid shared by TargetQuery and separation
│   └── structure_index.gd     # unit/building/castle grid for _pick_nearest_structure (exact-preserving)
└── squads/separation.gd       # gains a grid variant with the same accumulation order
presentation/
├── crowd/crowd_batch.gd       # generic MultiMesh batch: capacity, CPU mirror, begin/add/commit
├── enemies/enemy_views.gd     # rewritten on CrowdBatch (hooks kept: view_count, puff_count)
├── units/unit_views.gd        # rewritten on CrowdBatch + baked unit meshes
├── vfx/projectile_vfx.gd      # arrows through a ring batch; slashes stay nodes (<= 8)
├── vfx/health_bar_batch.gd, death_puff_batch.gd
├── walls/wall_views.gd        # run pieces, collapse, rubble
└── debug/flow_field_gizmo.gd  # or extend enemy_path_gizmo.gd
data/buildings/wall.tres, data/maps/prototype_map.tres (4 wall plots)
tools/stress/                  # stress_night.gd/.tscn, stress_map.tres, gate_stress.gd, frame_report.gd
tests/golden/walls.json        # new golden if Open Question 1 is accepted as recommended
```

### Pattern 1: Make the sim step cheap first, and prove it with the goldens (exact-preserving)

**What:** four changes that return bit-identical results, so `bash tools/replay.sh --scenario=<x> --twice --expect-file=tests/golden/<x>.json` is the proof:
1. `StructureIndex`: a uniform grid (cell 12 m in the prototype; at least aggro range) of living units, standing buildings and the castle, rebuilt once per night step after the squads and towers moved. `_pick_nearest_structure` gathers candidates from the 3x3 cells, sorts them into the original order (units by ascending id, buildings in spot order, castle last) and applies the same `edge <= aggro_range and edge < best_edge` test with the same expressions (`distance_to(...) - radius`). Measured: 0 mismatches over 300 positions, 1.1 ms vs 40 ms (F1).
2. `EnemyIndex` + `TargetQuery.nearest_enemy`: same grid idea for the tower and squad "nearest enemy" scans (tie rule: lower id wins).
3. `Separation` grid variant: per element accumulate partner contributions in ascending partner index (the order the O(n^2) loops produce), which is bit-identical (F1).
4. Cache `SimClock.ticks(def.retarget_interval_seconds)` per def, stop calling `units.ids()` / `standing_spot_ids()` per enemy per tick, and expose packed read accessors.

**When to use:** immediately after the MultiMesh plan, before any behaviour change. **Why first:** it makes every later plan's goldens meaningful and the stress numbers honest.

**Example (sketch; `StructureIndex` candidate order is the contract):**
```gdscript
# Source: bench_grid_pick.gd (session probe); same expressions as EnemySystem._pick_nearest_structure
func pick(pos: Vector2, aggro: float) -> Vector2i:  # (kind, id) or (-1, 0)
	var cell_x: int = floori(pos.x / CELL)
	var cell_y: int = floori(pos.y / CELL)
	var candidates: Array = []
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			var bucket: Variant = _grid.get(_key(cell_x + dx, cell_y + dy))
			if bucket != null:
				candidates.append_array(bucket)
	candidates.sort()  # insertion index == original scan order, so ascending index is the contract
	var best: float = INF
	var found: Vector2i = Vector2i(-1, 0)
	for index: int in candidates:
		var edge: float = pos.distance_to(_pos[index]) - _rad[index]
		if edge <= aggro and edge < best:
			best = edge
			found = Vector2i(_kind[index], _tid[index])
	return found
```
Insert units first (id order), then buildings (spot order), then the castle, so insertion index equals the shipped scan order. A radius of influence larger than one cell needs a wider neighbourhood; choose `CELL >= max(aggro_range) + max(radius)` or query ring 2.

### Pattern 2: One CrowdBatch per archetype, CPU mirror, compact every frame

**What:** a presentation helper that owns `MultiMesh` (set `transform_format`, `use_colors`, `use_custom_data` **before** `instance_count`), a `PackedFloat32Array` of `capacity * stride`, and a live count. Each frame: iterate sim ids ascending, write dead-free instances sequentially (no slot bookkeeping), assign the buffer, set `visible_instance_count`. Set `custom_aabb` once to the map bounds. Stride is 16 (transform + custom) or 20 (plus colour), per the verified layout (F6). Write the identity basis once; per frame only origin and custom data change.

**Hooks for tests:** `count()`, `position_of(index)`, `custom_of(index)` read the **CPU mirror**, because the headless dummy renderer returns nothing from the MultiMesh (F6). Keep `EnemyViews.view_count()` and `puff_count()`, `UnitViews.view_count()` and `ProjectileVfx.live_count()` as thin readers of the mirrors so existing assertions on counts survive; tests that reached into puppet nodes (`get_view(id).get_node("HealthBar")`, `material.emission_energy_multiplier`) must be rewritten against the mirrors. About 107 references across 25 test files use these hooks; budget that in the plan (see Pitfall 3).

**Capacity:** `MAX_VIEWS = 256` becomes a per-archetype capacity of 512 (the stress night's 300 enemies of one type fit); when a spawn would exceed capacity the instance is not drawn, the same degrade as today. `SelectionRings.MAX_RINGS = UnitViews.MAX_VIEWS` (selection_rings.gd line 11) is tied to the unit cap; keep them in step.

**Archetype meshes:** enemies use `CapsuleMesh` with `radial_segments = 8`, `rings = 2` (144 tris) in the existing grunt red and skirmisher violet (skirmisher taller and narrower as in `EnemyViews`). Friendly units bake the Kenney body and head surfaces (723 / 876 tris) into one ArrayMesh once, in a real renderer, with a capsule fallback when `bake_mesh_from_current_skeleton_pose()` returns null (headless).

### Pattern 3: Hit flash, hurt-only bars, arrows and puffs without nodes

- **Flash:** custom data `x` carries the flash amount (`1.0` at the hit, decayed in real seconds over the existing `FLASH_SECONDS = 0.15`), read in `vertex()` into a varying and added to `EMISSION` (verified, F6). Keep a `Dictionary` id -> hit time only for recently hit enemies and erase it after 0.15 s.
- **Bars:** one billboard `QuadMesh` MultiMesh whose shader draws fill versus background from `UV.x <= ratio` (verified). Instances exist only for enemies with `0 < hp < max` (`HealthBar3D.should_show` rule), compacted per frame.
- **Arrows:** a ring of 512 instances (D-10 asks 200; natural concurrent arrows top out near 90 to 130, see Pitfall 11). Each flight keeps origin, last target, elapsed and duration in packed arrays; per frame the same lerp and `arc_height` as today (`ProjectileVfx.arc_height`, `ARC_PER_METRE = 0.12`, `MAX_ARC_HEIGHT = 2.5`), 148 us for 200 (F3). Orientation needs a basis from the heading; write 9 more floats per arrow. Colour per instance (`use_colors`, tower gold, skirmisher violet, unit pale blue) through one emissive shader, `cast_shadow = OFF`. Slashes stay nodes (cap `MAX_SLASHES = 8`). Raise `MAX_PROJECTILES` (128) to the ring capacity.
- **Puffs:** replace per-death `CPUParticles3D` + `create_timer` (`MAX_PUFFS = 64`) with a ring of 128 batch instances whose scale and alpha are driven in the shader from a spawn time in custom data.

### Pattern 4: Wall data schema (D-01, D-02, D-03)

`BuildSpotDef` today has `id`, `position`, `building_id` (build_spot_def.gd lines 5 to 9). Add one nullable export `wall_run: WallRunDef`; a non-null run marks a wall plot, so the plot kind is data, not an id convention.

```gdscript
# simulation/walls/wall_run_def.gd  (proposal)
class_name WallRunDef
extends Resource
## An authored line of wall. The simulation expands it into segments once, deterministically.
@export var points: PackedVector2Array = PackedVector2Array()   # polyline vertices, metres, XZ
@export var segment_length: float = 3.0                          # metres per segment along the path
@export var gaps: Array[Vector2] = []                            # (from_m, to_m) along the path with no wall
@export var half_thickness: float = 0.4                          # metres; solid core radius
```
Expansion rule: walk the polyline, cut `segment_length` pieces, drop any piece whose midpoint lies in a gap range, quantise endpoints with `roundi(x * 100.0)` into integer centimetres kept in `PackedInt32Array`s. A wall tier reuses `BuildingTierDef.max_health` as the **per-segment max health** (`wall.tres`: three tiers, cost and `max_health` only; `effect_line()` gains a wall branch, for example "80 health per segment"), so the label "Wall II: 12 segments, 80 health each" is computed from the run and the tier. `BuildingDef.body_radius` is unused for walls.

**Authoring guidance for the prototype map (D-06):** each outer run is perpendicular to its road at about 60 m from the castle (west run through (-60, 22), east (60, 22), north (0, -60)), 30 to 40 m long, with one authored gap of **4 m** centred on the road line; the plot position (where the king holds) sits just inside the gap. The spawn scatter is 3 m (`spawn_point_def.gd`), the spawns are about 6 m beyond the wall line, towers 5 m inside it. The ring run (radius about 8 to 9 m, castle radius 3.5) has three gaps of 4 m toward the roads. Minimum authored gap: **3 m** (a `validate()` error below it).

### Pattern 5: `WallSystem` is a sibling of `BuildingSystem`

`BuildingSystem` has exactly 20 public functions (counted this session; the cap is `max-public-methods: 20`), `UnitSystem` 20, `SquadSystem` 19, `EnemySystem` 16, `NightSim` 15. Wall logic goes in a new file:
- `WallSystem(map, buildings, events)`: `on_tier(spot_id, tier)` (called from the `building_built` path in `RunContext` composition, or by `CommandProcessor`), `segments()`/`segment_count()`, `is_intact(index)`, `health_of(index)`, `damage_segment(index, amount)`, `restore_all()`, `version()`, `intact_segments_near(...)`.
- Segment indices are global, ascending, never reused (the same rule as enemy ids); a segment hit names its target by index like a building hit names a spot index.
- Pitfall: a wall plot is an ordinary standing building to the rest of the code. Filter it out of `EnemySystem._pick_nearest_structure` (`standing_spot_ids()` includes it), `dawn_income_by_spot`, `BuildingViews` (it would draw a stand-in at the plot centre) and the tower/squad systems. `damage_building` must never be called for a wall plot; segments take their own hits.
- New hit kind `PendingHits.KIND_WALL := &"wall"` with `_resolve_hits` branch calling `WallSystem.damage_segment`. New signals `wall_damaged(spot_id, segment, amount, hp, max_hp)`, `wall_segment_broken(spot_id, segment)`, `walls_restored(spot_ids)`; each needs `SimSignals.ALL`, `SimRecorder.HANDLED`, an `attach` connection and an `_on_*` handler **in the same task**.
- Dawn: call `WallSystem.restore_all()` inside `RunManager._enter_dawn` right after `_buildings.repair_standing()` and before `_events.buildings_rebuilt.emit(rebuilt)` (the shipped order is rebuild, repair, castle, king, squads, `buildings_rebuilt`, payout). Intact but damaged segments heal to full, as `repair_standing` does for buildings. `RunManager._init` already takes 9 parameters (cap 10), so reach `WallSystem` through `NightSim` (add `restore_walls()`), not a tenth parameter.

### Pattern 6: Solidity for everyone, one pure function

`WallSolids.push_out(pos, radius) -> Vector2` (static, pure): for each intact segment within reach (use the nav grid's segment-owner mask for the candidate set), if the distance from `pos` to the segment is below `half_thickness + radius` move `pos` out along the normal. Apply it (a) after `Separation` for enemies and units, in that order: **move, separate, push-out**, so a crowd cannot shove an enemy through a wall; (b) in `King._physics_process` after `move_and_slide()` (the king has a capsule collision shape but there are no static bodies in the world, so a `StaticBody3D` per segment is the alternative; the pure function is preferred because it is the same rule bots use); (c) in `PlaytestBot._move_king`, which today does `here.move_toward(goal, pace)` straight through anything. Segments 3 m long at 0.4 half-thickness and a 0.107 m step (3.2 m/s at 30 Hz) cannot be tunnelled. No transcendental functions are needed.

### Pattern 7: Nav grid and flow field (D-04, D-05, ENMY-04)

- **Grid:** cell size from `MapConfig` (default 2.0 m), bounds from the union of wall runs, spawn points, spots and castle plus a margin (not `ground_half_extent`, which may be 10,000 m: `MAX_GROUND_HALF_EXTENT: float = 10000.0`, map_config.gd line 16), and a hard cap on the cell count that `MapConfig.validate()` enforces (Security Domain). The prototype's bounds (about 172 x 130 m) are 5.6k cells at 2 m.
- **Blocked mask:** a cell is blocked when its centre is within `half_thickness + inflate` of an intact segment, `inflate` the largest enemy radius (0.5). A second `PackedInt32Array` stores the owning segment index so a blocked cell names its segment. Forbid a diagonal step when either orthogonal neighbour is blocked (no leaks, F5 probe).
- **Field:** Dial buckets with integer costs 10 (orthogonal) and 14 (diagonal), implemented over flat parallel arrays (entry cell, entry next, bucket heads), each cell finalised once (7 ms at 2 m, F4). Goal cells are the cells within `goal_radius + 0.8 m` of the target. Unreached cells keep `INF_COST`.
- **Directions:** compute lazily per cell with a validity stamp (the full pass costs 10.6 ms at 2 m, F4): `dir = normalized(sum over 8 neighbours of unit_offset * (cost_here - cost_neighbour))`, blocked and unreached neighbours substitute `cost_here + 25`; sample bilinearly over the four surrounding cell centres and normalise. Only `+ - * /` and `sqrt` (DR-7).
- **Rebuild trigger:** `WallSystem.version()` changes (built, raised, broken, restored). By day with no enemies rebuild synchronously (a one-tick 7 ms hitch on the frame the hold completes). At night a break triggers one synchronous rebuild of the castle field; a second break within the same tick is coalesced (rebuild once per tick). If profiling shows hitches, time-slice by a fixed relaxation count per tick (count-based, so still deterministic) and keep the old field until the new one completes.
- **Straight fallback (golden safety):** `Pathing.step()` returns exactly `pos.move_toward(goal, maxf(max_distance, 0.0)) - pos` (today's `desired_step` body) when the grid has no intact segment, or when `line_blocked(pos, goal)` is false. Maps without wall plots (the `smoke` and `army` fixtures) therefore never touch the field.

### Pattern 8: Which goals get a field (the multi-goal problem)

A field per goal does not scale to moving goals (the king, hundreds of units), so:
- **Castle field:** permanent, rebuilt on wall change. Enemies without a target march on it.
- **Target kinds king, unit, building:** a target is valid only while `NavGrid.line_blocked(pos, goal)` is clear (the enemy's `aggro_range` is 6 m and `leash_range` 10 m, so these targets are always close). A blocked target is dropped at the next rescan and the enemy returns to the castle field. This is a behaviour change from "path to its target" (D-07 wording) that keeps one field; flagged as Open Question 3.
- **Squads:** walk goals are the formation slot, the anchor and order points. Use a small goal-keyed cache (capacity 8, key = goal cell quantised to 4 m, eviction in insertion order) built lazily on the first blocked-LOS query, at most one build per tick, stale up to `field_refresh_ticks` (about 15). A following squad shares one field keyed by the king's cell. When the cache is full or the per-tick build is spent, the unit falls back to the straight step for that tick. Melee unit targets also require clear LOS; archers (`projectile_speed > 0`) do not, as their shots arc over the wall.

### Pattern 9: Break or detour, in integers (D-07, D-08)

All quantities are integers computed from data converted once at construction.
- Per enemy def: `speed_cm_per_s = roundi(move_speed * 100.0)`, `interval_ticks = SimClock.ticks(attack_interval)`, `dmg_per_300 = attack_damage * 300 / interval_ticks` (integer division; damage per 10 s).
- **Aggro to a segment:** at its staggered rescan an enemy that has a goal and `line_blocked` returns segment `s` records `wall_seg = s` (else -1) and the tick.
- **Decision pass:** every `wall_decision_ticks` (data, `SimClock.ticks(0.5)` = 15, staggered by `segment % cadence`, or one O(n) pass over all enemies; at 300 enemies it is a 300-iteration loop, about 0.1 ms) accumulate `sum_dps300[s]` over enemies whose `wall_seg` lies in the segment's neighbourhood (same run, index within `wall_neighbour_span`, data, default 2) and who are within `wall_notice_range` of it, then `ttd_ticks[s] = (health * 300 + sum_dps300 - 1) / sum_dps300`, or a saturating `MAX_TICKS` when `sum_dps300 == 0`. Published as a `PackedInt32Array`.
- **Detour:** `cost_at(cell)` from the castle field (10 per metre-cell) -> `detour_cm = cost * cell_cm / 10` -> `detour_ticks = ceil(detour_cm * 30 / speed_cm_per_s)`; `straight_ticks` the same from `roundi(distance * 100)`. Unreached (`INF_COST`) means sealed: always attack.
- **Rule:** attack segment `s` when `ttd_ticks[s] + straight_ticks < detour_ticks` (strict) or sealed; otherwise follow the field. Once a segment is the committed target keep it until the segment is gone or `detour_ticks + wall_hysteresis_ticks < ttd + straight` (hysteresis, data, default 15), so crowds do not flip-flop at every rescan.
- **Attacking a segment:** `KIND_WALL` joins `_target_valid` (intact and inside leash) and `_advance_and_strike` (goal = closest point on the segment, `goal_radius = half_thickness`, same stop-distance rule). `EnemyPathGizmo._target_position` and `_target_color`, `ProjectileVfx._target_position` / `_attacker_position` and the overlay must learn the new kind or they silently fall back to the castle position (Pitfall 9).

### Pattern 10: Stuck detection that tolerates queues (D-09)

Prototype result (F5): healthy enemies in a 200-enemy surge wait up to about 13 s in the queue. Define two things:
- **Flag (overlay diagnostic):** an enemy is flagged when, on its staggered rescan ticks, its field cost at its cell has not dropped below its best-so-far (watermark) by at least 3 for `stuck_ticks` (data, `SimClock.ticks(3.0)` = 90) while it has no attack target. Integer only, read-only, **emits no events**: an event would move the goldens (a new recorded line) and the flag would also fire for enemies idling at a destroyed castle.
- **Pass criterion (gate test):** every enemy crosses the finish line before `T_max` (recommended 60 s of sim time; measured 13.9 to 20.7 s) **and** none is still flagged at the end. Report median and maximum time to cross and the longest flag streak as information, as F5's table does.

### Pattern 11: Frame-time report (D-12)

`tools/stress/stress_night.gd` (real window, never headless, like `ShotRunner`): set `DisplayServer.window_set_vsync_mode(DISABLED)` and `Engine.max_fps = 0`, load the stress map, run a fixed 20 s of night at 1.0x speed, record per-frame `delta` and `viewport_get_measured_render_time_cpu/gpu`, step cost around `ctx.advance`, `Performance` draw-call and object counts, three runs, publish the median run's p50, p95, p99, worst-1% mean and max. Header: Godot version, GPU and driver string (`RenderingServer.get_video_adapter_name()`), the actual window size (this machine gave 1920x1050 client area for `--resolution 1920x1080`), renderer, enemies/units/arrows on screen. Night fast-forward doubles the per-frame sim cost; report 1.0x and say so. Launch: `bash tools/godot.sh --path . --resolution 1920x1080 res://tools/stress/stress_night.tscn -- --duration=20 --out=...`.

### Anti-Patterns to Avoid
- **Node per entity for views:** 913 draw calls and 1,110 objects at 256 puppets (F2).
- **Reading MultiMesh state back in tests:** the dummy renderer returns zeros (F6); mirror on the CPU.
- **`(array_in_array[i] as PackedXArray).append(...)`:** appends to a copy (hit twice in probes); use flat arrays or `Array`.
- **Events for diagnostics:** a stuck or field event changes digests; keep diagnostics as getters.
- **Per-agent `NavigationAgent3D`, `NavigationServer3D` in `simulation/`, `Geometry2D` allocations in the hot path:** banned (DR-5, DR-9, STACK.md) or slow.
- **A field per goal for moving goals;** use LOS shortcut plus the castle field plus a small cache.
- **Raising caps or disabling gdlint rules** to fit wall code into `BuildingSystem`; new file instead.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Drawing hundreds of identical meshes | Node per entity, `CPUParticles3D` per death | `MultiMesh` batches with a shader for flash, bars, puffs | 8x fewer draw calls (F2); layout verified (F6) |
| Deterministic ordering of float accumulation | A new push-apart algorithm | A bucketed variant of `Separation.displacements` that keeps ascending partner order | Bit-identical to the shipped pass (F1); the goldens depend on it |
| Cross-platform float sin/cos in the sim | `sin`, `cos`, `atan2`, `pow` | `+ - * /`, `sqrt`, integer cell maths | DR-5 / DR-7; libm results are platform-dependent [ASSUMED per DR-5] |
| Walkable grid from scene geometry | `NavigationServer3D` bake in the sim | Rasterise authored `WallRunDef` data into `PackedByteArray` | DR-5 bans the server; bake yields polygons (F6) |
| Frame-time statistics | Eyeballing the FPS counter | The report script with `viewport_get_measured_render_time_*` and sorted percentiles | Reproducible, committed (D-12) |

**Key insight:** the genuinely hard parts (an exact-preserving spatial index, an integer field, queue-tolerant stuck logic) have no engine equivalent that is both deterministic and usable under `simulation/`, so they are hand-written, but every piece is small, pure and gated by the existing goldens or a headless test.

## Runtime State Inventory

Not a rename, refactor-by-string or migration phase; omitted. (The MultiMesh switch replaces view code only; there is no stored or registered runtime state carrying an old name. Existing saves do not exist yet (Phase 9).)

## Common Pitfalls

### Pitfall 1: The step-time cliff at crowd scale
**What goes wrong:** 300 marching enemies cost 50 ms per step (F1); the game would run in slow motion because `RunContext.advance` clamps each frame to `MAX_ADVANCE_SECONDS: float = 0.25`. [VERIFIED: sim_clock.gd:12]
**Why it happens:** target-less enemies re-run an all-structures scan every tick.
**How to avoid:** Pattern 1, in its own plan, goldens byte-identical.
**Warning signs:** `bench_march.gd`-style probe above 10 ms at 300; frame spikes proportional to enemy count.

### Pitfall 2: MultiMesh property order and the headless dummy renderer
**What goes wrong:** `transform_format` / `use_colors` / `use_custom_data` set after `instance_count` print `Instance count must be 0 ...` or do nothing; tests that read the MultiMesh back see zeros.
**How to avoid:** set flags, then `mesh`, then `instance_count`, then `visible_instance_count`; assert on the CPU mirror. Never read the `buffer` getter per frame (it copies).

### Pitfall 3: View tests assert puppet internals
**What goes wrong:** about 107 references in 25 test files use `get_view`, `view_count`, `puff_count`, `live_count`, `puppet_position`; several assert material emission or `HealthBar` nodes (`test_projectiles_visible.gd`, `test_unit_views.gd`, `test_night_tracer_scene.gd`, `test_results_screen.gd`). Criterion 4 says existing tests still pass: the *simulation and loop* tests must be untouched; the view tests are rewritten to assert the mirrors and are called out as such in the plan.
**How to avoid:** keep the count hooks; keep `get_view(id)` only if a thin proxy is cheap, else migrate the callers (`selection_rings.gd` line 131 calls `_views.get_view`).

### Pitfall 4: Skinned Kenney models in a MultiMesh
**What goes wrong:** the glb meshes are skinned; without a skeleton they render in bind space and bake returns null headless.
**How to avoid:** `bake_mesh_from_current_skeleton_pose()` once after the node is in the tree in a real renderer, merge surfaces, capsule fallback when null (F7).

### Pitfall 5: A wall plot behaves like a normal building
**What goes wrong:** enemies target the run's centre as a building, the plot pays income logic, `BuildingViews` draws a stand-in, `damage_building` hits a run.
**How to avoid:** filter on `BuildSpotDef.wall_run != null` in every iteration over `standing_spot_ids()` (grep `standing_spot_ids` and `spot_ids` callers).

### Pitfall 6: `BuildingSystem` and friends are at the lint cap
**What goes wrong:** adding methods fails `gdlint` (`max-public-methods: 20`): `BuildingSystem` 20, `UnitSystem` 20, `SquadSystem` 19.
**How to avoid:** new files for wall, nav, index logic; EnemySystem has 4 spare public methods, so packed accessors go on a small `EnemyReadView`-style helper or replace `ids()`-style methods rather than add many.

### Pitfall 7: Existing data tests pin the plot list
**What goes wrong:** `tests/unit/test_military_data_contract.gd` line 22 `const SPOT_COUNT: int = 10` and line 104 `assert_eq(map.spots.size(), SPOT_COUNT, "ten plots (D-03)")`; `tests/unit/test_prototype_map_data.gd` lines 84 to 88 assert that **every spot appended after the Phase 1 plots fields a unit** (`assert_ne(building.unit_id, &"", "%s fields a unit" ...)`), which a wall plot fails. `test_ride_across_the_map_takes_twelve_to_eighteen_seconds` (lines 101 to 115, `MIN_RIDE_S: float = 12.0`, `MAX_RIDE_S: float = 18.0`, king `walk_speed = 7.5`) bounds the farthest pair at 90 to 135 m: west and east wall plots 120 m apart pass (16 s), but keep wall plots within 135 m of every other plot.
**How to avoid:** append the four wall plots last (spot indices of existing plots, and therefore hit ids, do not move) and update those tests deliberately.

### Pitfall 8: Three more places per new signal
**What goes wrong:** a new `SimEvents` signal without `SimSignals.ALL` (tests/support/sim_signals.gd), `SimRecorder.HANDLED` and the recorder handler fails `test_determinism.gd` and the drift guard. [VERIFIED: sim_recorder.gd header and sim_signals.gd read this session]
**How to avoid:** one task adds signal, three registrations and the handler.

### Pitfall 9: A new target kind is silently mis-drawn
**What goes wrong:** `EnemyPathGizmo._target_position` and `_target_color`, `ProjectileVfx._target_position` / `_attacker_position` and the debug overlay default unknown kinds to the castle.
**How to avoid:** grep `KIND_BUILDING` across `presentation/` and `ui/` and add `KIND_WALL` beside each.

### Pitfall 10: The goldens move for the wrong reason
**What goes wrong:** the recorder logs positions only inside events (`enemy_spawned`, `enemy_died`) quantised to 1 cm, so any float-order change in movement shifts `enemy_died` lines; a stuck or field event adds lines.
**How to avoid:** straight-line fallback with the identical expression; diagnostics as getters; exact-preserving index code proven by `--twice --expect-file`.

### Pitfall 11: 200 simultaneous arrows are not natural
**What goes wrong:** skirmishers fly 7 m at 14 m/s (0.5 s) every 1.6 s, so even 300 shooters keep about 94 arrows aloft; the tower and archers add far less. The D-10 bar cannot be reached by play.
**How to avoid:** the stress map declares a tools-only slow-arrow `stress_tower` def (for example `projectile_speed` 8, interval 0.15 s, range 30; 20 of them hold about 200 in flight) so real hits and real `PendingHits` load apply, or the harness emits synthetic `attack_fired` events. Pick one and state it in the report.

### Pitfall 12: Field rebuild trigger storms
**What goes wrong:** several segments breaking in one tick rebuild the field repeatedly; rebuilds sized by `ground_half_extent` allocate without bound.
**How to avoid:** rebuild at most once per tick from `WallSystem.version()`; grid bounds from content, capped and validated.

### Pitfall 13: Real-window measurement noise
**What goes wrong:** two puppet runs differed (p95 11.1 vs 30.2 ms); vsync on clamps deltas to 16.7 ms; the window client area is smaller than requested.
**How to avoid:** vsync off, 3 runs, median run published, actual size and driver recorded, other heavy processes closed.

### Pitfall 14: Bots and squads walk through walls
**What goes wrong:** `PlaytestBot._move_king` uses `move_toward`; `SquadFormation` slots can lie inside or behind a run.
**How to avoid:** `WallSolids.push_out` in the bot; slots resolved by `Pathing` (cache) with a straight fallback; accept a documented jitter for a slot inside a wall.

## Code Examples

### MultiMesh batch construction (verified layout)
```gdscript
# Source: mm_shader_test.gd / headless_mm.gd (session probes, 4.7.2); flags BEFORE instance_count
var mm: MultiMesh = MultiMesh.new()
mm.transform_format = MultiMesh.TRANSFORM_3D
mm.use_colors = true            # optional; stride 20 with custom data
mm.use_custom_data = true       # x = flash or ratio
mm.mesh = mesh
mm.instance_count = 512         # capacity
mm.visible_instance_count = 0
mm.custom_aabb = AABB(Vector3(-100.0, -1.0, -100.0), Vector3(200.0, 8.0, 200.0))

# per instance: [12 transform][4 colour][4 custom]
func put(buf: PackedFloat32Array, i: int, x: float, y: float, z: float, flash: float) -> void:
	var o: int = i * 16                 # 20 when use_colors
	buf[o + 3] = x                       # identity basis written once at allocation
	buf[o + 7] = y
	buf[o + 11] = z
	buf[o + 12] = flash                  # custom.x
# per frame: mm.buffer = buf ; mm.visible_instance_count = live
```

### Flash and billboard-bar shaders (rendered correctly, Forward+ and Compatibility)
```glsl
// Source: mm_shader_test.gd (session probe)
shader_type spatial;
varying float flash;
varying vec3 inst_color;
void vertex() { flash = INSTANCE_CUSTOM.x; inst_color = COLOR.rgb; }
void fragment() { ALBEDO = base_color * inst_color; EMISSION = vec3(1.0) * flash; }
```
```glsl
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;
varying float ratio;
void vertex() {
	ratio = INSTANCE_CUSTOM.x;
	mat4 mv = VIEW_MATRIX * MODEL_MATRIX;
	mv[0] = vec4(1.0, 0.0, 0.0, mv[0][3]);
	mv[1] = vec4(0.0, 1.0, 0.0, mv[1][3]);
	mv[2] = vec4(0.0, 0.0, 1.0, mv[2][3]);
	mv[0][0] = length(MODEL_MATRIX[0].xyz);
	mv[1][1] = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = mv;
}
void fragment() { ALBEDO = UV.x <= ratio ? vec3(0.85, 0.2, 0.18) : vec3(0.08, 0.08, 0.1); }
```

### Dial's algorithm over flat arrays (integer, deterministic)
```gdscript
# Source: bench_field.gd (session probe); padded grid (n+2)^2 with a blocked border, no corner cutting
func dial(blocked: PackedByteArray, goals: PackedInt32Array, width: int, max_d: int) -> PackedInt32Array:
	var cost: PackedInt32Array = PackedInt32Array()
	cost.resize(blocked.size())
	cost.fill(INF_COST)
	var offs: PackedInt32Array = PackedInt32Array([1, -1, width, -width, width + 1, width - 1, -width + 1, -width - 1])
	var steps: PackedInt32Array = PackedInt32Array([10, 10, 10, 10, 14, 14, 14, 14])
	var side_a: PackedInt32Array = PackedInt32Array([1, -1, 1, -1])
	var side_b: PackedInt32Array = PackedInt32Array([width, width, -width, -width])
	var head: PackedInt32Array = PackedInt32Array()      # bucket -> first entry or -1
	head.resize(max_d + 16)
	head.fill(-1)
	var e_cell: PackedInt32Array = PackedInt32Array()    # entry -> cell
	var e_next: PackedInt32Array = PackedInt32Array()    # entry -> next entry in bucket
	e_cell.resize(blocked.size() * 3)
	e_next.resize(blocked.size() * 3)
	var count: int = 0
	for goal: int in goals:
		cost[goal] = 0
		e_cell[count] = goal
		e_next[count] = head[0]
		head[0] = count
		count += 1
	var d: int = 0
	while d <= max_d:
		var e: int = head[d]
		if e == -1:
			d += 1
			continue
		head[d] = e_next[e]
		var cur: int = e_cell[e]
		if cost[cur] != d:
			continue                                     # stale entry
		for k: int in 8:
			var ni: int = cur + offs[k]
			if blocked[ni] == 1:
				continue
			# no corner cutting: a diagonal move needs both orthogonal neighbours open
			if k >= 4 and (blocked[cur + side_a[k - 4]] == 1 or blocked[cur + side_b[k - 4]] == 1):
				continue
			var nd: int = d + steps[k]
			if nd < cost[ni]:
				cost[ni] = nd
				e_cell[count] = ni
				e_next[count] = head[nd]
				head[nd] = count
				count += 1
	return cost
```
Note: the corner-cut rule is the one the no-leak probe (`leak_test.gd`) used; the probe's flood fill forbade the diagonal when either orthogonal neighbour was blocked. The Dial timings in F4 were measured without this extra check, so expect a few percent more.

### Wall decision arithmetic
```gdscript
# Source: design for this phase; integers only
static func ttd_ticks(health: int, sum_dps300: int) -> int:
	if sum_dps300 <= 0:
		return SimClock.MAX_TICKS
	return (health * 300 + sum_dps300 - 1) / sum_dps300    # ceiling of health / (dps300 / 300 per tick)

static func should_break(ttd: int, straight_ticks: int, detour_ticks: int) -> bool:
	return detour_ticks == SimClock.MAX_TICKS or ttd + straight_ticks < detour_ticks
```

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| One `Node3D` + capsule + `HealthBar3D` (two quads, four materials) per enemy | One MultiMesh per archetype, shader flash and bars | 913 to 1,144 draw calls to 118 to 141 |
| `NavigationAgent3D` RVO per agent | Integer flow field + local separation | Deterministic, O(1) per agent (ARCHITECTURE Pattern 6; DR-9) |
| Engine physics interpolation | Own `RunContext.alpha()` interpolation in the batch | Sim is 30 Hz, physics 60 Hz; `physics_interpolation = false` |
| `get_instance_transform` readback in tests | CPU mirror in the batch | Dummy renderer returns zeros (F6) |

**Deprecated/outdated:** `Skeleton`-less rendering of a skinned mesh in a MultiMesh without baking; the `desired_step` static straight line as the only steering seam (it stays as the fallback body).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A GTX 970 renders the GPU portion about 3 to 4 times slower than this RTX 3060 Laptop, and its host CPU runs the GDScript sim about 1.3 to 1.6 times slower than this i5-10500H | Pattern 11, Open Question 2 | The "about 8 ms on the dev machine" budget may not translate to 16.7 ms on a real GTX 970; the report states the assumption, the owner may own a GTX 970-class machine to confirm later |
| A2 | The custom shaders also render in CI's Mesa software GL (`gl_compatibility` under `xvfb`) | Empirical F6, Pitfall list | A CI screenshot job could fail on software GL; local Compatibility run succeeded, CI not run |
| A3 | 2 m cells and 3 to 4 m authored gaps are adequate for gate feel and for the debug overlay to read | Pattern 4, 7 | Gaps may need to be wider or cells 1.5 m (rebuild 18 ms) |
| A4 | A 7 to 18 ms synchronous field rebuild on a wall break or a hold completion is an acceptable one-frame hitch | Pattern 7 | Visible stutter when a segment falls mid-night; mitigation is count-based time slicing |
| A5 | Requiring clear LOS for king, unit and building targets (dropping blocked targets) matches what the owner means by "path to its target" | Pattern 8, Open Question 3 | Enemies might ignore a unit just behind a wall they would have chased around it |
| A6 | After Plan 2 a 300-enemy step reaches about 4 to 6 ms (the three measured fixes sum to roughly -50 ms, -4 ms and -1 ms from 50 ms) | Summary, Pattern 1 | If it stays above about 8 ms the budget is missed and packed storage or GDExtension is needed |
| A7 | libm transcendentals and compiler FMA are platform-dependent (carried from DR-5, DR-7) | Don't Hand-Roll | Over-restriction costs nothing; under-restriction would break goldens |
| A8 | Wall cost and health numbers (barricade cheap, tiers about 3 to 7 gold) match Thronefall's scale | Pattern 4 | Rebalanced in the bot measurement (D-15) |
| A9 | `physics/common/physics_interpolation` should stay false | F6 | None found; verified default false |

## Open Questions (RESOLVED)

1. **D-14 literally or with a straight-line fallback?**
   - What we know: the `smoke` and `army` goldens use frozen fixtures (`tests/fixtures/fixture_map_replay_*.tres`) with no wall plots; `full_idle` has no golden. A pathing step that returns the old straight-line expression when no intact wall exists changes none of their digests, and none of the `test_balance_acceptance.gd` pins (lost seeds `[3, 9]`, first loss night 3, and so on).
   - What's unclear: whether the owner wants D-14's "regenerate once" to mean "the digests must all change" or "outcomes are reported before and after".
   - Recommendation: keep the fallback; add a fourth golden `walls` (fixture map with a wall plot, bot buys it, enemies break and go around), record the before/after report as D-14 asks, and document in the report that smoke and army are unchanged by design. If the planner prefers the literal reading, drive every step through the field and regenerate smoke, army and the balance pins in one commit.
   - **RESOLVED (plan 04-10):** the fallback is kept. Wherever no intact segment exists the step runs the exact Phase 3 expressions, so the smoke and army goldens stay byte-identical (plans 04-04 and 04-06 pin this). Plan 04-10 adds the fourth golden `walls`, makes the one deliberate regeneration commit (balance pins, bot orders, full_idle's recorded digest, any data change) and writes the before/after outcome report in 04-BALANCE-REPORT.md. The owner confirms the "same outcomes, not digests" reading of D-14 at the Phase 4 gate (04-11 / `/gsd-verify-work`).
2. **What does "held under about 8 ms" gate?** Recommend p95 of the 20 s run at 1080p 1.0x speed is at most 8 ms, worst-1% mean and max are reported not gated. With the sim step at 4 to 6 ms landing on every second frame plus about 3 ms of render, the margin is thin (A6).
   - **RESOLVED (plan 04-09):** the gate is the median run's p95 (three 20 s runs after a 10 s warm-up, median by p95) at or under 8.0 ms at 1080p, 1.0x speed and vsync off; p99, the worst-1 percent mean and the maximum are reported, not gated; committed in 04-FRAME-REPORT.md with the GTX 970 scaling assumption (A1).
3. **LOS-gated targets (Pattern 8).** Confirm that enemies drop king/unit/building targets they cannot see past a wall and return to the castle field.
   - **RESOLVED (plan 04-06):** taken as recommended. While any segment is intact, a melee enemy chooses or keeps a king, unit, building or castle target only with a clear line (a ranged enemy also while the target is within its attack_range); a blocked target is dropped and the enemy marches the castle field. Melee units need a clear line to take an enemy, archers do not. The owner judges it at the UAT.
4. **Where the king holds a wall plot.** The plot position is the interaction point; recommend just inside the gate so the ride ends at a spot the king can reach without crossing the run.
   - **RESOLVED (plan 04-05):** each road run's plot sits on its road 2 m inside the gap (castle side); the ring's plot sits inside the ring near its north gap at (0, 0, -6.5), clear of the king spawn at (0, 0, 7).
5. **Arrow target tracking.** Current arrows retarget the moving victim every frame (`last_target`); a ring of packed arrows can keep that (0.15 ms per 200), so keep it unless profiling objects.
   - **RESOLVED (plan 04-02):** kept. Arrows drawn from the packed batch refresh `last_target` from the living victim every frame.
6. **Is packed (struct-of-arrays) storage inside `EnemySystem` in scope?** Pattern 3 of ARCHITECTURE allows it behind the id API. Recommend adding packed read accessors first (an additive, golden-safe change) and converting storage only if the post-Plan-2 profile misses the budget.
   - **RESOLVED (plan 04-03):** packed read accessors only (`EnemySystem.read_view()`); EnemySystem keeps its Dictionary-of-records storage. Converting the storage to struct-of-arrays is lever (a) in plan 04-09, used only if the frame-time budget is missed, with the three replays byte-identical.
7. **Stress arrows:** a tools-only `stress_tower` def (real hits) or synthetic events (Pitfall 11).
   - **RESOLVED (plan 04-09):** real hits. Tools-only slow-arrow stress towers (projectile_speed 8, attack_interval 0.15 s, attack_range 30) put their arrows through PendingHits; no synthetic events.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot editor, console build | everything | yes | 4.7.2-stable (`.tools/godot/4.7.2-stable/Godot_v4.7.2-stable_win64_console.exe`) | none needed |
| Real renderer window (non-headless) | frame-time report, screenshots, shader checks | yes | Vulkan 1.4 Forward+ on RTX 3060 Laptop (driver 610.88 per `nvidia-smi`); Compatibility OpenGL 3 also ran | `--rendering-method gl_compatibility` |
| GTX 970-class machine | D-10 literal | no | - | D-12 documented dev-machine budget with the A1 scaling assumption |
| gdtoolkit (`gdformat`, `gdlint`) | lint gate | yes | `.tools/venv/Scripts/*.exe` | - |
| GUT | tests | yes | 9.7.1 | - |
| bash (Git Bash) wrappers | `tools/*.sh` | yes | Git Bash (PowerShell `bash` is WSL and cannot see the Windows Godot) | - |
| CI (GitHub Actions, Ubuntu, xvfb + Mesa) | replays, screenshots | yes (existing `ci.yml`) | - | - |

**Missing dependencies with no fallback:** none. **Missing with fallback:** the GTX 970 (documented equivalence).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | GUT 9.7.1 on Godot 4.7.2 |
| Config file | `.gutconfig.json` (dirs `tests/unit`, `tests/integration`, `tests/e2e`, prefix `test_`) |
| Quick run command | `bash tools/test.sh -gselect=<script substring>` (single script) |
| Full suite command | `bash tools/test.sh` (about 9 minutes) |
| Replay commands | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` (also `army`, and `full_idle --twice`) |
| Lint | `bash tools/lint.sh` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BLDG-10 | Wall run builds all segments on one hold, tiers raise health linearly (cost and `max_health`), segments block enemies, squads, king (`push_out`) | unit + integration | `bash tools/test.sh -gselect=test_wall_system` / `test_wall_solids` | no, Wave 0 |
| BLDG-10 | A broken segment is a hole until dawn; dawn restores before the payout; `walls_restored` once | integration | `bash tools/test.sh -gselect=test_wall_dawn` | no, Wave 0 |
| BLDG-10 | Wall plot is never targeted as a building, pays no income, draws no stand-in | unit | `bash tools/test.sh -gselect=test_wall_plot_isolation` | no, Wave 0 |
| BLDG-10 | `MapConfig.validate()` rejects bad wall data (non-finite, too many segments, gap under 3 m, grid over cap) | unit | `bash tools/test.sh -gselect=test_map_wall_validation` | no, Wave 0 |
| ENMY-04 | Dial field costs and directions on a fixture grid; no leaks through a diagonal wall; `INF` for sealed cells | unit | `bash tools/test.sh -gselect=test_flow_field` | no, Wave 0 |
| ENMY-04 | Integer break-or-detour rule (`ttd`, `detour`, sealed always attacks, hysteresis) | unit | `bash tools/test.sh -gselect=test_wall_decision` | no, Wave 0 |
| ENMY-04 | Stuck tracker flags a stalled enemy, not a creeping queue; emits no events | unit | `bash tools/test.sh -gselect=test_stuck_tracker` | no, Wave 0 |
| ENMY-04 | 200+ enemies through one gate: all cross before T_max, none flagged at the end, two runs agree | integration (headless CLI) | `bash tools/gate_stress.sh --enemies=200 --twice` (new wrapper) | no, Wave 0 |
| ENMY-04 | Smart rule end to end: a weak wall is broken, a strong wall is bypassed through the gap | integration | `bash tools/test.sh -gselect=test_wall_behaviour` | no, Wave 0 |
| ENMY-04 / determinism | New `walls` golden and `--twice` agreement; smoke and army unchanged | replay | `bash tools/replay.sh --scenario=walls --twice --expect-file=tests/golden/walls.json` | no, Wave 0 |
| PLAT-01 | Structure grid and enemy grid return the same answers as the shipped scans on random positions; bucketed separation equals `Separation.displacements` | unit | `bash tools/test.sh -gselect=test_spatial_index` | no, Wave 0 |
| PLAT-01 | Existing goldens byte-identical across the MultiMesh switch and the sim hot-path pass | replay | the three `replay.sh` commands above | yes |
| PLAT-01 | Batches expose counts and mirrors; capacity degrade; flags set before `instance_count` | unit + e2e | `bash tools/test.sh -gselect=test_crowd_batch` / `test_enemy_views` | no, Wave 0 |
| PLAT-01 | 60 fps on GTX 970-class: committed report at 1080p, 300 enemies, 50 units, 200 arrows | manual-only (real window; D-12 forbids CI) | `bash tools/godot.sh --path . --resolution 1920x1080 res://tools/stress/stress_night.tscn -- --duration=20` | no, Wave 0 |
| Phase | Night screenshots under hundreds of units | screenshot (CI + local) | `bash tools/screenshot.sh <shot>` | partly |

### Sampling Rate
- **Per task commit:** `bash tools/test.sh -gselect=<touched suite>` plus `bash tools/lint.sh`.
- **Per wave merge:** the three golden replays with `--twice`, the touched integration suites, and for the sim hot-path wave the `bench_march`-style step-cost probe printed into the plan summary.
- **Phase gate:** full `bash tools/test.sh`, three replays, the gate stress CLI, `bash tools/screenshot.sh` for the new night shots, and the committed frame-time report, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `tests/unit/test_wall_system.gd`, `test_wall_solids.gd`, `test_wall_plot_isolation.gd`, `test_map_wall_validation.gd` - BLDG-10
- [ ] `tests/unit/test_flow_field.gd`, `test_wall_decision.gd`, `test_stuck_tracker.gd`, `test_spatial_index.gd` - ENMY-04, PLAT-01
- [ ] `tests/integration/test_wall_dawn.gd`, `test_wall_behaviour.gd`, `test_gate_stress.gd` - BLDG-10, ENMY-04
- [ ] `tests/unit/test_crowd_batch.gd`, rewritten `tests/e2e/test_unit_views.gd`, `test_projectiles_visible.gd`, `test_night_tracer_scene.gd` against the mirrors - PLAT-01
- [ ] `tools/gate_stress.sh` + `tools/stress/gate_stress.gd` (CLI with an allowlist like `replay_cli.gd`), `tools/stress/stress_night.gd/.tscn`, `tools/stress/stress_map.tres`
- [ ] `tests/golden/walls.json` and `tests/fixtures/fixture_map_replay_walls.tres` (if Open Question 1 is accepted)
- [ ] Update `tests/unit/test_military_data_contract.gd` (`SPOT_COUNT`) and `test_prototype_map_data.gd` (appended-spot assertion) for the four wall plots
- [ ] Add the new signals to `tests/support/sim_signals.gd` and `tools/replay/sim_recorder.gd`
- [ ] Framework install: none (GUT 9.7.1 present)

## Security Domain

`security_enforcement` is enabled (ASVS level 1, block on high). This is an offline single-player game: no authentication, sessions, network or cryptography in this phase. The relevant surface is untrusted data files and tool arguments, plus resource exhaustion.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | none (no accounts) |
| V3 Session Management | no | none |
| V4 Access Control | no | none |
| V5 Input Validation | yes | `MapConfig.validate()` extended for wall data (finite numbers, segment count and gap caps, minimum gap width, grid cell cap); allowlisted CLI arguments for the new tools like `replay_cli.gd` (`safe_dir` under `build/`, integer parsing) |
| V6 Cryptography | no | none |
| V12 Files and resources | yes | report and screenshot outputs only under `res://build` (reuse `ReplayCli.safe_dir`); no path taken from data |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| A map file with a huge `ground_half_extent` (up to 10,000) or far-flung spawn points drives an unbounded nav-grid allocation (400 M cells at 1 m) | Denial of service | Derive grid bounds from content, cap cells (for example 40,000), report in `validate()`, and refuse to arm the field (straight fallback) on a bad map, like castle numbers (T-02-04 precedent) |
| Wall data with NaN, INF, negative or zero lengths, thousands of segments | Tampering / DoS | `validate()` rejects and caps segment count per run and per map; expansion uses `is_finite` guards and integer centimetres |
| Field rebuild storms from many simultaneous breaks | DoS | One rebuild per tick from `version()`; count-based time slicing if needed |
| CLI arguments of the stress tool selecting arbitrary paths | Tampering | Allowlist and `safe_dir` under `res://build`, no `..` segments |
| Stress or overlay code shipping in the export | Information disclosure (minor) | Stay under `tools/` (export `exclude_filter="tests/*, addons/gut/*, tools/*"`, export_presets.cfg line 11); the debug overlay already ships (T-01-15 accepted) |

## Sources

### Primary (HIGH confidence)
- Session probes on Godot 4.7.2-stable (scripts in the session scratchpad `research/`): `bench_sim.gd`, `bench_parts.gd`, `bench_split.gd`, `bench_loop.gd`, `bench_march.gd`, `bench_pick.gd`, `bench_grid_pick.gd`, `bench_sep.gd`, `bench_fill.gd`, `bench_field.gd`, `proto_field.gd`, `leak_test.gd`, `stress_frames.gd`, `api_multimesh.gd`, `mm_shader_test.gd`, `headless_mm.gd`, `ps.gd`, `immediate_test.gd`, `nav_probe.gd`, `model_probe.gd`, `bake_view.gd`, `wall_probe.gd`
- Repository files read this session: `simulation/night/enemy_system.gd`, `night_sim.gd`, `pending_hits.gd`, `target_query.gd`, `simulation/squads/separation.gd`, `squad_system.gd`, `unit_system.gd`, `simulation/buildings/building_system.gd`, `building_instance.gd`, `simulation/defs/*`, `simulation/run/run_manager.gd`, `run_context.gd`, `simulation/clock/sim_clock.gd`, `presentation/enemies/enemy_views.gd`, `units/unit_views.gd`, `vfx/projectile_vfx.gd`, `vfx/health_bar_3d.gd`, `debug/enemy_path_gizmo.gd`, `king/king.gd`, `tools/replay/*`, `tools/screenshot/shot_runner.gd`, `tools/sandbox/hold_pacing_sandbox.gd`, `.gdlintrc`, `.github/workflows/ci.yml`, `export_presets.cfg`, `data/maps/prototype_map.tres`, tests named in Pitfall 7
- `.planning/phases/04-crowd-scale-battles-walls/04-CONTEXT.md`, `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/02-night-defense-playtest-gate/02-RESEARCH.md` (DR-1 to DR-12), `.planning/research/ARCHITECTURE.md` (Patterns 3, 5, 6), `.planning/research/PITFALLS.md` (Pitfall 4)
- docs.godotengine.org/en/stable/classes/class_multimesh.html - `buffer`, `custom_aabb`, `visible_instance_count`, `instance_count`, `use_colors`, `use_custom_data`, `set_buffer_interpolated` (fetched this session)

### Secondary (MEDIUM confidence)
- ARCHITECTURE.md citations of Red Blob Games "Flow Field Pathfinding for Tower Defense" and the jdxdev flow-field write-up (not re-fetched this session; the prototype in F5 is the independent check)

### Tertiary (LOW confidence)
- GTX 970 versus RTX 3060 Laptop scaling factors (A1): general hardware knowledge, not measured

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - engine built-ins, API surface and layout verified by probes and the class docs.
- Architecture: HIGH for the measured hot paths, the MultiMesh design and the field build; MEDIUM for the multi-goal and break-or-detour design (prototyped in isolation, not integrated).
- Pitfalls: HIGH - most were hit during the probes or read from the code and tests.
- Frame-budget projection: MEDIUM - pieces measured, end state not built (A6); GTX 970 scaling LOW (A1).

**Research date:** 2026-10-16
**Valid until:** about 2026-11-15 (engine pinned at 4.7.2; re-run `bench_march.gd`-style probes if `EnemySystem`, `SquadSystem` or `Separation` change before planning ends)
