---
phase: 04-crowd-scale-battles-walls
plan: 18
subsystem: native-port
tags: [gdextension, cpp, godot-cpp, flow-field, nav-grid, castle-routing, determinism, step-bench, gut]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-17 NativeWalls mirror (closest_point for the probe, the intact count); plan 04-15 gd_math.h operation table and the pins-first port style; plan 04-22 stale-library guard; plan 04-16 CI that builds the native library from source
provides:
  - "NativeGrid (native/src/native_field.*): the nav grid's layout and blocked and owner masks in C++, refreshed by NavGrid at the end of every rebuild, with cell_of, is_blocked, is_border, owner_of and is_ready"
  - "NativeField: the cost field's reads (cost_at, is_reached and the lazily cached, bilinearly blended direction_at) in C++ over the LIVE grid mirror; FlowField.build keeps Dial in GDScript and hands its costs over"
  - "NativeRoute: Pathing's castle routing (is_sealed with its probe off a blocking wall, castle_cost_at, castle_distance_cm, detour_ticks, straight_ticks, march_step) in C++ behind Pathing's unchanged 20 public methods"
  - "tests/unit/test_field_route_pins.gd: 36 sha256 pins (4 worlds x intact, broken, stale x castle, goals, route) computed on the GDScript before any native field code, never edited since"
  - "tests/unit/test_native_field.gd: bad-input answers, grid-mirror agreement cell for cell, route fallbacks (T-04-47, T-04-48)"
  - "Plain C++ members for plan 04-19's native enemy step: every bound method of the three classes is also an ordinary const member (no Godot arrays), and NativeRoute reads the grid, field and wall mirrors by Ref"
affects: [04-19, 04-20, 04-21, 04-23]

actuals:
  tokens: 18660
  tasks: 2
  commits: 3

plan_head_before: a5e502a8638465c7122e651d675c1fd314144e33
plan_head_after: 8551a087270946555dbda091d03dfae999cf49d3

tech-stack:
  added: []
  patterns:
    - "Live mirror pattern again: NavGrid pushes layout once and both masks after each rebuild; the native field reads the mirror at read time, so a stale field sees the new mask exactly as the GDScript saw NavGrid's"
    - "Lazy per-cell direction cache with a generation stamp, filled by const readers (mutable members), stored as float exactly as the PackedFloat32Array it replaced"
    - "A pin state that deliberately breaks the field/grid invariant (grid rebuilt, field not) so the pins hold the laziness, not just the answers"
    - "Plain C++ members beside the bound ones (the bound method is the member) so the native enemy step calls the route without crossing the GDScript boundary"

key-files:
  created:
    - native/src/native_field.h
    - native/src/native_field.cpp
    - tests/unit/test_field_route_pins.gd
    - tests/unit/test_native_field.gd
  modified:
    - native/src/register_types.cpp
    - simulation/nav/nav_grid.gd
    - simulation/nav/flow_field.gd
    - simulation/nav/pathing.gd

key-decisions:
  - "The lazy direction cache is reproduced, not replaced: a cell's direction is computed from the live grid mask the first time it is asked in a generation and kept until the next set_costs; a mutation that recomputes on every read fails all 12 stale pins"
  - "FlowField.build's Dial stays GDScript (owner accepted the wall-break rebuild hitch, UAT test 10); the native field receives the finished cost array and a reference to the grid mirror"
  - "Algorithm constants of the direction maths (WALL_PENALTY, MIN_DIRECTION_LENGTH, the unit offsets) moved into native_field.cpp and were deleted from flow_field.gd: one implementation, no duplicated numbers"
  - "NativeRoute is private to Pathing (a member, set up in _init and pointed at the castle field in refresh()); Pathing stays at its 20 public methods; NavGrid is at 18 and FlowField at 9 with native()"
  - "WR-03 (an enemy outside the grid reads unreached, so counts as sealed) now lives in NativeRoute::is_sealed, ported unchanged on purpose"

patterns-established:
  - "Pins first and never edited: d333f5b precedes the first commit that creates native_field.cpp (0f5a85b)"
  - "Interleaved A/B on the same machine state beside the before/after files, because the laptop drifts (04-15, 04-17)"

requirements-completed: []

coverage:
  - id: D1
    description: "The flow-field reads (cost_at, is_reached, direction_at with its lazy per-cell cache) run in C++ from a grid mirror NavGrid refreshes on every rebuild, byte-identical to 36 pins computed on the GDScript, with all replay and gate digests unchanged"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_field_route_pins.gd (9 tests), tests/unit/test_native_field.gd (13 tests), test_flow_field.gd, test_nav_grid.gd, test_goal_field_cache.gd"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh smoke/army/walls --twice --expect-file, full_idle --twice, bash tools/gate_stress.sh --twice (digests below), full suite 204 scripts / 1909 tests"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pathing's castle routing runs in C++ through one NativeRoute behind the unchanged 20-method API, and the replaced GDScript bodies (probe helper, PROBE_STEPS, FlowField's direction arrays and helpers) are deleted"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "route pins in tests/unit/test_field_route_pins.gd; mutation probe PROBE_STEPS 3 to 2 fails 6 route pins; grep: no _probe_of or PROBE_STEPS in pathing.gd, no _compute_direction in flow_field.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "The stress-shape and prototype step medians are measured before and after (five runs each) and an interleaved A/B corroborates the direction"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "ten bench lines, the A/B pairs and both medians in this SUMMARY"
        status: pass
    human_judgment: false
  - id: D4
    description: "The 8.0 ms p95 frame budget is not met yet (stress shape step mean still about 23 to 26 ms); the enemy step itself crosses in 04-19 to 04-21 and 04-23"
    requirement: PLAT-01
    verification: []
    human_judgment: true
    rationale: "PLAT-01 closes only when the whole step runs natively and the stress night is re-measured against 8.0 ms (04-VERIFICATION.md gap G-04-5); plan 04-21 judges the frame budget"

duration: 61min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 18: Native Flow-Field Reads and Castle Routing Summary

**The flow-field reads (cost_at, is_reached and the lazily cached bilinear direction_at) now run in C++ over a grid mirror that NavGrid refreshes on every rebuild, and Pathing's castle routing (is_sealed with its wall probe, castle_cost_at, castle_distance_cm, detour_ticks, straight_ticks, march_step) runs through one NativeRoute behind its unchanged 20-method API, byte-identical to 36 sha256 pins computed on the GDScript first, with all five replay digests and the 300-enemy gate unchanged and the replaced GDScript deleted.**

## Performance

- **Duration:** about 61 min (2026-10-19T15:40:36Z to about 16:42Z; the full suite is 14 min of it, the bench series and A/B about 15 min)
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files:** 10 in the production commits (4 created plus 2 .uid files, 4 modified)
- **Tracer feedback gate:** Task 1's verify is automated-only under `end-of-phase`; the whole chain passed end to end (pins, field, grid, cache and detour suites, rules guard, four replays, gate, lint) and Task 2's chain re-ran everything plus the full suite after the expansion: "Tracer verified end-to-end, expanding".

## Accomplishments

- **Pins first.** `tests/unit/test_field_route_pins.gd` builds four worlds (the prototype map with all four wall runs at tier I, the stress map's gate wall, the sealed 32-segment ring, the gap fixture) and puts each through three states: all segments intact; a seeded handful of segments broken through `damage_segment` with the grid and fields rebuilt; and a *stale* state (the lazy direction cache primed on half the points, more segments broken, the grid rebuilt but the fields not, then every point read). In each state 2,000 seeded points (uniform in and around the grid, inside wall bands, on the border ring, exactly on cell edges and centres, and up to 300 m outside) are read through `FlowField.cost_at`, `is_reached` and `direction_at` of the castle field and of three goal fields from a `GoalFieldCache`, through `Pathing.walk_step`, and through `Pathing.is_sealed`, `castle_cost_at`, `castle_distance_cm`, `detour_ticks` and `straight_ticks` (speeds 300 and 320 cm/s) and `march_step` (reaches 0.0, 0.107, 1.0). 36 pins (4 x 3 x 3: castle, goals, route), plus coverage tests that prove the points hit open, blocked, border and outside cells, that fields reach and miss, that the ring seals and unseals, and that the stale cache keeps asked cells and reads the live mask for new ones. Digests were identical on two GDScript runs; committed green on the GDScript in `d333f5b`, before `native_field.cpp` existed, and not touched since.
- **Native grid mirror and field reads.** `NativeGrid` holds armed, origin, cell, width, height and both masks; `NativeField` holds the costs, a reference to the live grid mirror, and the lazy per-cell direction cache with its generation stamp (a direction is computed from the grid's mask the first time a cell is asked in a generation, kept until the next `set_costs`, and stored as `float` exactly as the `PackedFloat32Array` stored it). `FlowField.build` still runs Dial in GDScript and hands `_cost` and `grid.native()` over; `cost_at`, `is_reached` and `direction_at` delegate; `_dir_x`, `_dir_y`, `_stamp`, `_generation`, `_unit_x`, `_unit_y`, the three private direction helpers and the constants only they used are deleted. `NavGrid` creates its mirror in `_init`, sets the layout when armed and refreshes both masks at the end of every `rebuild`.
- **Mutation probe on the laziness.** Replacing the stamp test with "always recompute" fails all 12 stale pins (every world, castle/goals/route), so the pins really hold the cache semantics.
- **Native castle routing.** `NativeRoute` references the grid mirror, the castle field, the wall mirror (04-17), the castle position and the tuning's cell size, and answers the six routing calls plus `probe_of` and `has_intact_walls` line by line from `Pathing`. `Pathing` creates one in `_init`, points it at the castle field when `refresh()` first builds it, and its routing methods delegate; `_probe_of` and `PROBE_STEPS` are deleted. Pathing still has exactly 20 public methods. A probe mutation (PROBE_STEPS 3 to 2) fails 6 route pins (prototype and ring, all three states).
- **One implementation.** The GDScript bodies are gone; no runtime fallback.

## Measured results

All numbers are from this laptop, headless, one run at a time, GDScript enemy step otherwise (`bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- ...`; stress shape `--map=stress --enemies=300 --warmup=300 --steps=300`, prototype shape `--enemies=300 --steps=30`).

**Before** (taken at `d333f5b`, the pins commit, all GDScript; stress shape first, then prototype):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=22.30 p95_ms=39.65 max_ms=95.62
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=24.61 p95_ms=52.61 max_ms=82.54
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=23.89 p95_ms=43.35 max_ms=74.45
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=23.04 p95_ms=37.09 max_ms=150.10
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=29.50 p95_ms=62.64 max_ms=142.80
STEP_BENCH enemies=300 steps=30 mean_ms=15.89 p95_ms=21.91 max_ms=22.83
STEP_BENCH enemies=300 steps=30 mean_ms=25.99 p95_ms=41.81 max_ms=122.31
STEP_BENCH enemies=300 steps=30 mean_ms=15.97 p95_ms=19.44 max_ms=19.48
STEP_BENCH enemies=300 steps=30 mean_ms=28.03 p95_ms=42.45 max_ms=42.75
STEP_BENCH enemies=300 steps=30 mean_ms=23.93 p95_ms=52.28 max_ms=55.16
```

**After** (at the Task 2 code, about 25 minutes later, same flags):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=25.42 p95_ms=48.30 max_ms=197.46
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=22.78 p95_ms=40.30 max_ms=117.13
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=24.13 p95_ms=41.46 max_ms=122.39
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=22.05 p95_ms=41.24 max_ms=91.84
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=21.41 p95_ms=40.89 max_ms=111.24
STEP_BENCH enemies=300 steps=30 mean_ms=33.92 p95_ms=85.88 max_ms=99.64
STEP_BENCH enemies=300 steps=30 mean_ms=15.55 p95_ms=26.59 max_ms=36.20
STEP_BENCH enemies=300 steps=30 mean_ms=22.80 p95_ms=33.62 max_ms=33.95
STEP_BENCH enemies=300 steps=30 mean_ms=37.63 p95_ms=54.38 max_ms=58.59
STEP_BENCH enemies=300 steps=30 mean_ms=13.98 p95_ms=18.15 max_ms=19.84
```

| Shape | Median before | Median after | Difference |
|-------|--------------|-------------|------------|
| Stress, step mean, median of 5 | 23.89 ms | 22.78 ms | -1.11 ms |
| Prototype, step mean, median of 5 | 23.93 ms | 22.80 ms | -1.13 ms |

**Reading the figures honestly.** There is no gain bar in the plan, and the plan 04-17 lesson applies again: the prototype series is bimodal (about 15 ms or about 25 to 38 ms from run to run, in both the before and the after file), so its median says little, and the laptop drifts over the 25 minutes between the two files. So I ran an interleaved A/B on the same machine state: the GDScript `flow_field.gd`, `nav_grid.gd` and `pathing.gd` of `d333f5b` swapped in and out of the working tree against the Task 2 files (the native library is the same in both arms; the old GDScript simply never calls it), the working files restored and checked with `cmp`:

```
stress  gdscript 28.89 / native 25.54   (gain 3.35 ms)
stress  gdscript 26.62 / native 25.37   (gain 1.25 ms)
stress  gdscript 24.71 / native 25.65   (gain -0.94 ms)
stress  gdscript 26.44 / native 24.51   (gain 1.93 ms)
```

Stress: median of the four gains +1.59 ms (mean +1.40 ms; column medians 26.53 against 25.46). Prototype, nine pairs (three in the first A/B, six more afterwards; the second run's lines were `28.16/14.47`, `19.95/15.89`, `19.73/35.56`, `14.82/30.29`, `21.30/18.53`, `20.52/19.12`, the first three `18.77/16.07`, `18.96/31.82`, `15.19/27.50`): gdscript median 19.73 ms, native median 19.12 ms, with the native arm hitting the same 28 to 36 ms outliers as before and after files do. The prototype direction is inside the noise; I do not claim it. The stress figure I trust: the field reads and the castle routing take about 1 to 3 ms off the stress-shape step, consistent with the diagnosis (the enemy step makes a handful of boundary-light field calls per enemy per tick; the rest of the step, about 22 to 25 ms, is still GDScript). The stress-shape step is far from the 5 to 6 ms the 8.0 ms frame budget needs; the enemy step itself crosses in 04-19 and the budget is judged in 04-21.

## Task Commits

1. **Task 1 (tracer), pins on the GDScript:** `d333f5b` (test)
2. **Task 1, the grid mirror and native field reads, FlowField delegating, GDScript direction cache deleted, native-input tests:** `0f5a85b` (feat)
3. **Task 2, NativeRoute, Pathing delegating, `_probe_of` and `PROBE_STEPS` deleted, route tests:** `8551a08` (refactor)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified

- `native/src/native_field.h`, `native/src/native_field.cpp` - NativeGrid, NativeField, NativeRoute
- `native/src/register_types.cpp` - registers the three classes
- `simulation/nav/nav_grid.gd` - owns the mirror, sets the layout in `_init`, refreshes the masks at the end of `rebuild`, `native()` (18 public methods)
- `simulation/nav/flow_field.gd` - hands its costs over, reads delegate, direction code and arrays deleted, `native()` (9 public methods)
- `simulation/nav/pathing.gd` - one private NativeRoute, six routing methods delegate, `_probe_of` and `PROBE_STEPS` deleted (still 20 public methods)
- `tests/unit/test_field_route_pins.gd`, `tests/unit/test_native_field.gd` (with their .uid files)

## Decisions Made

See `key-decisions` above. In addition: `NativeRoute.set_world` takes the tuning's `cell_size` explicitly rather than reading the grid's, because `NavGrid._cell` keeps its default 2.0 while unarmed and `detour_ticks` multiplies the tuning value (the two agree whenever a field exists, which is the only case that reaches the product); `walk_ticks` and the centimetre arithmetic use wrapping unsigned operations so a pathological coordinate cannot be signed-overflow undefined behaviour in C++ where GDScript wraps; unused `NavGrid` accessors stay GDScript (`centre_of`, `cell_of` and friends are still called by `rebuild`, `_goal_cells` and tests) rather than adding boundary crossings for nothing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] A direct test of the native entry points**
- **Found during:** Task 1 (exact_port_rules 10 and threats T-04-47 and T-04-48 require index, size and finiteness checks and a mirror that never drifts, but the facades pass only well-formed values and the pins cover only good input)
- **Issue:** nothing exercised `NativeGrid`, `NativeField` or `NativeRoute` directly for an unarmed grid, wrong-sized masks, cost arrays shorter than the grid, non-finite positions, a route with nothing set, zero or negative speeds, or grid-mirror agreement after rebuilds (including breaks).
- **Fix:** added `tests/unit/test_native_field.gd` (13 tests, 77 asserts at Task 1, extended in Task 2 with the route cases).
- **Files modified:** tests/unit/test_native_field.gd (new, not in the plan's files_modified)
- **Committed in:** `0f5a85b` and `8551a08`

### Plan conformance notes (not deviations)

- The plan's Task 2 step 1 asks for the baseline "before switching"; I took it at `d333f5b`, the pins commit, which also precedes Task 1's `FlowField` switch, so the before/after pair spans the whole plan.
- The plan's executor rule about option C (committing the rebuilt DLL) does not apply: the owner chose option A at plan 04-16, nothing binary is committed and CI builds both libraries from source.
- A gdlint/gdformat-compatible `NavGrid.native()`, `FlowField.native()` pair, as the plan allowed; NavGrid is at 18 public methods, FlowField at 9, Pathing at 20.

**Total deviations:** 1 auto-fixed (1 missing critical). **Impact:** none on scope or numbers.

## Issues Encountered

- Bash heredocs of several hundred lines would not parse in this shell session, so the larger new files were created with the Write tool instead; no effect on the result.
- The prototype shape of `step_bench` is bimodal (about 15 ms or 25 to 38 ms between runs) in every series, which is why its medians are reported but not relied on.
- The local build is MSVC only. The C++ is written warning-free for GCC (`-Wall -Wextra -Werror`, no unused parameters, no signed/unsigned comparisons) but was not compiled with GCC here; the Linux CI job compiles it on the next push, and that is where a float difference would show if there were one.

## Notes for the later `/gsd-code-review 4 --fix` pass

- **WR-03** (an enemy outside the grid counts as sealed, because `cell_of` is -1, the castle field reads it unreached and `is_sealed` answers true while walls stand) now lives in `NativeRoute::is_sealed` (native/src/native_field.cpp), ported unchanged on purpose: fixing it moves a digest and needs its own owner golden decision. It is pinned as the GDScript behaved (the pins include 300 m outside points; the ring world's sealed count includes them).
- `NativeField::direction_at` reproduces the GDScript's NaN behaviour for a NaN or infinite position (the blend of zero directions with a NaN weight is a NaN vector, as the engine's `lerp` gave); `cost_at` and `is_reached` answer INF_COST and false for them (tested). Not changed.

## Known Stubs

None.

## Threat Flags

None. The new surface is pure arithmetic on arrays and values GDScript passes in (no I/O, no engine singletons). T-04-47 is mitigated by the pins, the exact lazy-cache semantics, the four replays and the gate digest; T-04-48 by the native bounds checks (cell indices, mask sizes, cost array length, null references) tested in `test_native_field.gd`, and by NavGrid arming only below MAX_NAV_CELLS so the mirror never exceeds 40,000 cells.

## Verification results

- Task 1 verify chain (as written in the plan, minus the build step which the chain script ran first): `NATIVE_BUILD_OK`, test_field_route_pins 9/9 (102 asserts, listed in the JUnit XML), test_flow_field 9/9, test_nav_grid 12/12, test_goal_field_cache 7/7, test_wall_detour 12/12, test_native_rules_guard 10/10, test_native_field 9/9 at that point; four replays; gate; lint. `CHAIN_OK`.
- Task 2 verify chain (`CHAIN_OK`): `NATIVE_BUILD_OK`, full suite `bash tools/test.sh`: 204 scripts, 1909 tests, 31262 asserts, all passing (baseline 202 / 1887 / about 30900; +2 scripts and +22 tests are the two new test files, 9 + 13), named suites present in the JUnit XML, lint clean (348 files).
- Digests after Task 2: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks, against tests/golden), army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353), walls `bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (1961), full_idle `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (6911), `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`. All unchanged.
- Acceptance: `git log` shows the pins file in one commit (`d333f5b`) older than the first commit that creates `native_field.cpp` (`0f5a85b`) and unchanged since; `nav_grid.gd` and `flow_field.gd` each have `func native(`; `pathing.gd` has 20 public methods and its six routing methods call `_route`; ten before and ten after bench lines plus the A/B pairs and the WR-03 note above.

## Next Phase Readiness

Ready for 04-19. The native enemy step can call `NativeRoute::march_step`, `is_sealed`, `detour_ticks`, `straight_ticks`, `castle_cost_at` and `probe_of` directly, and `NativeField::cost_at`, `is_reached`, `direction_at` for goal fields (take the `FlowField.native()` object and keep a `Ref`). PLAT-01 stays open until the whole step crosses and 04-VERIFICATION.md's success criterion 3 is re-measured by 04-21.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-19*

## Self-Check: PASSED

- Created files exist: native/src/native_field.h, native/src/native_field.cpp, tests/unit/test_field_route_pins.gd, tests/unit/test_native_field.gd (all tracked).
- Commits found in git log: d333f5b, 0f5a85b, 8551a08; `git rev-list --count a5e502a..HEAD` = 3 before this SUMMARY's own commit.
- Re-run after the last code change: the Task 2 verify chain including the full suite, the A/B (working files restored and `cmp`-checked), lint.
