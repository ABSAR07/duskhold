---
status: diagnosed
trigger: "UAT Phase 04, Test 5, gap G-04-5 (major), same root cause as 04-VERIFICATION.md's gap for ROADMAP success criterion 3 (PLAT-01): the stress night (300 enemies, 50 units, 239 arrows in view) runs at 43 fps median with a 37.04 ms p95 frame time against the 8.0 ms p95 budget (D-12). Owner route decided 2026-10-19: a GDExtension (C++) for the enemy and wall simulation step, profiling first; the 8.0 ms budget stands."
created: 2026-10-19T05:24:48Z
updated: 2026-10-19T05:57:31Z
goal: find_root_cause_only
---

## Current Focus

hypothesis: CONFIRMED - the step is GDScript call/branch overhead spread over per-enemy per-tick wall-aware target choice, push-apart, push-out and advance (EnemySystem.step 16-17 ms at 300) plus 7-7.5 ms of non-enemy GDScript that scans the enemy field (towers' nearest_enemy, squads, stuck tracker)
bug_class: Bohrbug (deterministic cost; the step is a pure function of the seed; run-to-run timing noise only)
test: replica + wrapper profile (digest-identical to ctx.step) at N 100/200/300 on the bench and stress shapes; post-window micro-measures; marshalling measure
expecting: (met) a function-level attribution with scaling
next_action: diagnosis returned to the orchestrator (goal find_root_cause_only); the G-04-5 gap plan writes the native boundary
rca:
  candidate_causes:
    - "code: per-enemy GDScript work every tick in EnemySystem (confirmed, 16-17 ms)"
    - "code: enemy-field scans outside EnemySystem - TargetQuery.nearest_enemy all-ids loop, StuckTracker target_of Dictionaries, squads (confirmed, 7-7.5 ms)"
    - "data/config: the stress settings (20 towers at 0.15 s and 30 m reach, 100000 hp everywhere) inflate the towers' query count (contributing, legitimate D-10 load, not to be changed)"
    - "environment: laptop timing noise (22.7-31.8 ms means for one load; p95/p50 ~2 inside enemies.step with no periodic component) - widens p95, not the cause"
  and_gate: "no - each of (1) EnemySystem.step and (2) the non-enemy remainder alone exceeds the ~5-6 ms step target, so both must be addressed (two sufficient causes, an OR, not an AND)"

## Symptoms

expected: The median stress run's p95 frame time at or under 8.0 ms at 1080p, 1.0x speed, vsync off on the dev machine (RTX 3060 Laptop, i5-10500H), as D-12's equivalent of 60 fps on a GTX 970-class machine, with 300 enemies, 50 units and 200+ arrows on screen.
actual: p95 37.04 ms (p50 20.92, p99 50.00, max 74.82), 856 frames (~43 fps). The simulation step (ctx.advance / NightSim.step) is the cost: mean 14.34 ms, p50 18.14, p95 25.43 ms; render CPU median 0.70 ms, render GPU 4.46 ms, 230 draw calls. 04-FRAME-REPORT.md profile (ticks 300-600): enemies 15.6 ms of a 22.2 ms step: _choose_target 7.5 ms, _separate 3.7 ms, move and strike 2.4 ms; the wall logic of 04-04 to 04-07 adds 8 to 10 ms once 300 enemies queue at the gate (14.2 ms without the gate wall). step_bench on the shipped map: 40 enemies 3.2-3.7 ms, 100 -> 9.1, 200 -> 17.2, 300 -> 20-23 ms (plan 04-03 measured 8.4-9.2 ms at 300 before walls). Lever (a), packed storage inside EnemySystem, bounded at about 1 ms and not pulled.
errors: None.
reproduction: `bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- --enemies=300 --steps=30` (headless); full stress night `bash tools/stress.sh --runs=3 --duration=20` (real window, not to be run here).
started: Plan 04-03 measured 8.4-9.2 ms at 300 enemies before walls; 04-04 to 04-07 added the wall logic; 04-09 measured and halted at its stop rule.

## Eliminated

## Evidence

- timestamp: 2026-10-19T05:24:48Z
  checked: .planning/debug/knowledge-base.md (Phase 0)
  found: no knowledge base file exists; no MemPalace configured for this run
  implication: no known-pattern candidate; proceed from evidence

- timestamp: 2026-10-19T05:41:45Z
  checked: read 04-FRAME-REPORT (all), 04-09-SUMMARY (halted), 04-03-SUMMARY (pre-wall bench 8.4-9.2 ms, lever list), 04-CONTEXT D-10..D-15, 04-RESEARCH F1-F6/A1/A6/A7, melee-targets-behind-walls.md (G-04-7 diagnosis); code: enemy_system.gd (710 lines, full), night_sim.gd, pathing.gd, wall_solids.gd, wall_decision.gd, wall_system.gd, structure_index.gd, enemy_index.gd, separation.gd, stuck_tracker.gd, flow_field.gd, target_query.gd, tower_system.gd, squad_system.gd step/_step_unit/_walk_toward, run_context.gd, step_bench.gd, sim_recorder.gd, test_sim_rules_guard.gd, .gdlintrc
  found: step order NightSim.step (night_sim.gd:83-101) spawn -> pathing.refresh -> king -> squads -> towers -> castle_attack -> enemies.step -> stuck.update -> resolve_hits -> remove_dead x2; EnemySystem.step (enemy_system.gd:149-178) previous copy -> StructureIndex.rebuild -> _publish_wall_times -> per enemy in id order {_choose_target, _advance_and_strike} -> _separate -> _push_out_of_walls. WallSolids.first_blocking (wall_solids.gd:52-70) queries WallSystem.segments_near(middle, half length + radius) (wall_system.gd:129-145), a Dictionary lookup per 4 m bucket cell over the whole line's bounding square, then sorts/uniques. Caps: .gdlintrc max-public-methods 20, max-file-lines 1000, function-arguments-number 10, max-returns 6 (gdlint, tools/lint.sh); test_sim_rules_guard enforces only DR-5 forbidden APIs over simulation/ and the transcendental ban (sin cos tan atan2 pow lerp_angle) over MATH_ROOTS clock/night/king/castle/squads/walls/nav - it scans .gd only.
  implication: the wall line test cost scales with the line length squared (bucket cells), not with the number of segments; a native port of the guard must add its own C++ scan

- timestamp: 2026-10-19T05:41:45Z
  checked: scratch probe scratchpad/exec/debug-g5/prof_step.gd (plain = ctx.step; coarse = replica of RunContext/NightSim/EnemySystem.step with clock reads per phase; fine = coarse + super-calling wrappers on EnemySystem private functions, Pathing public functions, WallSystem.segments_near, StructureIndex) on the step_bench shape, 300 grunts, steps 0-29
  found: digests identical in all three modes (760ed362... ticks=31), so the replica and wrappers step the same simulation. plain 19.79 ms mean (step_bench itself 21.50 the same minute). coarse: enemies.step 17.45 ms = _choose_target 9.43 (31 us/enemy) + _separate 3.59 + _push_out_of_walls 1.89 + _advance_and_strike 1.84 + _publish_wall_times 0.35 + StructureIndex.rebuild 0.11; stuck.update 1.42; squads 0.53 (8 units); castle_attack 0.47; king 0.32; towers 0.15. fine (34 ms, wrapper-inflated): first_blocking 24.3 calls/step, 14.7 of them the castle line on a rescan (_aim_at_walls) at ~270 us each; segments_near 332 calls/step visiting 5,437 bucket cells/step; push_out 300 calls/step (one per enemy) each a segments_near.
  implication: the cost is GDScript per-call overhead spread over target choice, line tests, push-out, push-apart and the stuck tracker, not one hotspot

- timestamp: 2026-10-19T05:50:35Z
  checked: run_all.sh - prof_step.gd in plain/coarse/fine at N = 100/200/300 for the bench shape (steps 0-29) and the stress-night shape (tools stress map, every plot built, king parked (0,14), night ticks 300-599, groups scaled to N/4); logs in scratchpad/exec/debug-g5/*.log
  found: |
    Every mode gives the same digest per (shape, N): bench 4d869fbc/d1f5ba76/760ed362, stress 75bec777/8852bf7d/06e60a5f.
    Plain mean ms (bench / stress): N100 7.34 / 9.75, N200 13.76 / 15.09, N300 21.74 / 27.43 (a re-run of stress 300 coarse: 22.74).
    Coarse stress, ms per step at N100 / N200 / N300 (re-run in brackets):
      enemies.step 4.98 / 10.40 / 17.04 (15.96)
        _choose_target 1.96 / 4.67 / 7.94 (7.20) = 19.6 / 23.3 / 26.5 us per enemy
        _separate 1.24 / 2.48 / 4.13 (3.72)   [superlinear: the gate queue is denser]
        _advance_and_strike 0.67 / 1.45 / 2.28 (2.14) = 6.7-7.6 us per enemy
        _push_out_of_walls 0.57 / 1.10 / 1.69 (1.77) = 5.6 us per enemy
        StructureIndex.rebuild 0.37 / 0.32 / 0.41 (0.51), _publish_wall_times 0.08 / 0.18 / 0.30, previous copy 0.03 / 0.06 / 0.08
      squads.step (50 units) 2.47 / 2.85 / 2.96 (2.70)
      towers.step (20 towers) 0.93 / 1.68 / 2.36 (2.13)
      stuck.update 0.45 / 0.91 / 1.45 (1.36) = 4.5-4.8 us per enemy
      resolve_hits 0.26 / 0.26 / 0.27, king.step 0.15 / 0.19 / 0.16, remove_dead x2 0.11 / 0.13 / 0.15
    Coarse bench (shipped map, 8 units, 3 towers) N100 / N200 / N300: enemies.step 6.24 / 12.31 / 19.09 (_choose_target 3.71 / 6.95 / 10.32 = 34-37 us per enemy; _separate 0.99 / 2.25 / 3.83; _push_out 0.59 / 1.29 / 2.10; _advance 0.64 / 1.30 / 2.04), stuck 0.50 / 1.03 / 1.53, squads 0.44 / 0.50 / 0.58, castle_attack 0.17 / 0.34 / 0.53, king 0.12 / 0.23 / 0.37, towers 0.11 / 0.12 / 0.17.
    Fine stress 300 (38.8 ms, wrapper-inflated ~1.6x; read for structure): _choose_target 16.1 = _target_walls_in_the_way 7.0 (of it _aim_at_walls no-rescan 3.5 at 148 calls/step -> _breaking_is_faster 98/step -> _wall_ticks -> detour_ticks + straight_ticks + ttd every tick for every aggroed enemy; _aim_at_walls rescan 2.0 at 10.6/step, castle-line first_blocking 145 us each) + _choose_base_target 6.3 (_pick_nearest_structure 3.0 at 159/step -> StructureIndex.nearest_visible 1.6; _target_valid 1.0 at 141/step) + own 2.8. push_out 300/step, each a segments_near (1,754 bucket cells/step). first_blocking 34.9 calls/step. living_within returned 1,651 ids/step.
    Post-window micro-measures at the final stress-300 crowd: TargetQuery.nearest_enemy at a tower's 30 m reach 451 us per query (living_within returns all 300 ids; the per-id is_alive + position_of loop is the cost; 20 towers firing every 5 ticks = 4 queries/step = 1.8 ms); UnitSystem.separate (50 units) 389 us; target_of 1.39 us/call (a fresh Dictionary); position_of 0.72 us/call; read_view refill 165 us; an empty GDScript call 0.20 us; Time.get_ticks_usec 0.066 us.
  implication: at the PLAT-01 load 7 to 7.5 ms of the 22-24 ms step is OUTSIDE EnemySystem.step (squads 2.7-3.0, towers 2.1-2.4, stuck 1.4, hits/king/cleanup 0.6). A native EnemySystem.step alone cannot reach a 5-6 ms step; the enemy-field queries (nearest_enemy for towers/squads/king/castle) and the stuck tracker must cross with it, and squads need at least their push-apart and push-out moved or optimised

- timestamp: 2026-10-19T05:50:35Z
  checked: float widths - scratch float_probe.gd on the pinned binary; `--dump-extension-api` of Godot_v4.7.2-stable_win64_console.exe into scratch/api
  found: Vector2(0.1,0).x == 0.1 is false (0x3fb99999a0000000 = float32 0.1); GDScript float is double; distance_to returns a float32 value widened to double; PackedFloat64Array keeps doubles, PackedFloat32Array rounds; SimClock.STEP = 0x3fa1111111111111 (double 1/30). extension_api.json header: version 4.7.2 stable official, "precision": "single", build_configuration float_32. The official Windows binary embeds "GCC: (GNU) 15.2.1" / MinGW-w64 strings, i.e. it is built with MinGW-GCC, not MSVC.
  implication: the step is mixed-width - Vector2 state and Vector2 methods in float32, GDScript scalars (radii, ranges, speeds, distances after the call returns, Separation radii, WallSolids sums, FlowField gains) in float64, narrowing to float32 wherever a scalar meets a Vector2 (Vector2 * / float, move_toward's delta, lerp's weight, PackedFloat32Array stores). A C++ port must reproduce those exact conversion points; godot-cpp built with precision=single gives the same Vector2 type

- timestamp: 2026-10-19T05:57:31Z
  checked: baseline contract on this machine - bash tools/replay.sh smoke/army/walls --twice --expect-file, full_idle --twice, bash tools/gate_stress.sh --twice
  found: REPLAY_OK smoke 2599c7c2... 703 ticks, army f7a967ed... 1353, walls bfb05fc7... 1961, full_idle 4385f569... 6911; GATE_OK enemies=300 crossed=300 stuck=0 median 14.93 s max 21.93 s longest_flag 3.37 s wall_hits=0 digest e448ffdb... (unchanged since 04-09)
  implication: the pins a native step must keep are all green today

- timestamp: 2026-10-19T05:57:31Z
  checked: per-tick series of the stress-300 coarse run (PROF_DUMP), grouped by tick mod 2/3/5/15; a marshalling micro-measure (300 records' step inputs gathered into packed arrays and the outputs scattered back)
  found: enemies.step p50 15.3 / p90 24.2 / p95 32.1 / p99 53.4 ms with no periodic component (the tail is noise on this laptop, every mode shows it); towers.step has a period-5 cadence (0.6 ms on 3 of 5 ticks, 4-6 ms on the other 2: the 0.15 s towers fire on shared ticks); gather+scatter of 300 records = 0.75 ms per tick
  implication: a native step that keeps GDScript-owned Records pays ~0.75 ms per tick of marshalling; a native-owned store pays none. The step's run-to-run noise (22.7-31.8 ms means for the same stress-300 load) means the gap plan must judge medians of several runs

- timestamp: 2026-10-19T05:57:31Z
  checked: toolchain on this machine (where/command -v, vswhere, directory listings, cl.exe banner, cmake/ninja --version), CI (.github/workflows/ci.yml), export_presets.cfg, .gitignore, .gitattributes, tools/prepush_check.sh, tools/lint.sh, tools/export.sh, tools/godot.sh/_common.sh; web: godot-cpp README (master = v10.x beta, api_version 4.3+, custom_api_file from --dump-extension-api; last engine-named tag godot-4.5-stable, no 4.7 tag found), MSVC /fp:contract (off by default under /fp:precise since VS2022 17.0), Godot 4.5 system requirements (x86_64 needs SSE4.2, no AVX/FMA)
  found: no C++ compiler on PATH; MSVC 19.51.36246 (VS Build Tools 2026 18.6.2, toolset 14.51.36231, vcvars64.bat) and MSVC toolset 14.44.35207 (VS 2022 Community) installed; Windows SDK 10.0.22621.0 and 10.0.26100.0; CMake 4.2.3-msvc3 and Ninja 1.13.2 bundled with the Build Tools; clang-format/clang-tidy (VS 2022 Llvm folder) but no clang-cl; no gcc/g++/clang++/MinGW; no SCons (Python 3.14.5 + pip 26.1.1); git-lfs present. CI: lint/test/export/screenshots all on ubuntu-latest; Godot via tools/bootstrap.py (checksum-pinned); test job runs tools/test.sh, the four replays and gate_stress on the Linux binary; export job exports the Windows preset from Linux. Preset: one "Windows Desktop" x86_64, export_filter all_resources, exclude "tests/*, addons/gut/*, tools/*". .gitignore ignores /build/*, .godot/, .tools/; prepush_check fails on build/ paths in history and on blobs > 5 MB not in LFS; .gitattributes routes no *.dll/*.so; lint.sh lints first-party .gd only and never addons/.
  implication: the plan can build locally with MSVC + CMake/Ninja (after vcvars64) without installing anything; SCons would be an install. CI needs a Linux .so for the test job and a Windows .dll at export time on a Linux runner (mingw cross-compile, a windows-latest job artifact, or a committed LFS binary); Windows (MSVC or MinGW) and Linux (GCC) builds must give identical goldens, as the engine's own MinGW and Linux builds do today

## Resolution

root_cause: |
  The simulation step at the PLAT-01 load (300 enemies, 50 units, 20 towers, a gated wall) costs 22-24 ms headless (20-22 ms on the shipped-map bench) because the whole night step runs as interpreted GDScript with per-call overhead on per-enemy, per-tick work; there is no single hotspot. Two independently sufficient parts, both above the ~5-6 ms step the 8 ms frame p95 needs:
  (1) EnemySystem.step (enemy_system.gd:149-178) 16-17 ms at 300 (5.0 / 10.4 / 17.0 ms at 100 / 200 / 300): _choose_target 7.2-7.9 ms (24-27 us per enemy per tick; target-less marchers re-query StructureIndex.nearest_visible every tick via _choose_base_target:284-286, aggroed enemies re-run _breaking_is_faster -> _wall_ticks -> detour_ticks/straight_ticks every tick via _aim_at_walls:350-356, plus ~11-15 castle-line WallSolids.first_blocking calls per tick on rescans at 145-270 us each because segments_near visits every 4 m bucket of the line's bounding square), _separate 3.7-4.1 ms (superlinear with crowd density), _advance_and_strike 2.1-2.3 ms, _push_out_of_walls 1.7 ms (one segments_near per enemy per tick), StructureIndex.rebuild + _publish_wall_times 0.6-0.8 ms. The walls (04-04..04-07) roughly doubled the per-enemy cost: 04-03's 300-enemy step was 8.4-9.2 ms.
  (2) Outside EnemySystem 7-7.5 ms: squads.step 2.7-3.0 ms (50 units; UnitSystem.separate alone 0.39-0.41 ms), towers.step 2.1-2.4 ms (TargetQuery.nearest_enemy at the stress tower's 30 m reach gets all 300 ids from EnemyIndex.within's fallback and calls is_alive + position_of per id: 425-451 us per query), stuck.update 1.4 ms (target_of allocates a Dictionary per enemy per tick), hits/king/cleanup 0.6 ms.
  Lever (a) (packed storage) is bounded because the cost is call and branch overhead, not field access (0.75 ms per tick is the whole gather+scatter of 300 records).
fix: (diagnose only; goal find_root_cause_only)
verification: replica/wrapper probes proven transparent by identical digests in plain, coarse and fine modes for every shape and size; baselines smoke/army/walls/full_idle/gate re-run green
files_changed: []
