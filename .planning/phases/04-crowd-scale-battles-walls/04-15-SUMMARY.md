---
phase: 04-crowd-scale-battles-walls
plan: 15
subsystem: native-port
tags: [gdextension, cpp, godot-cpp, separation, determinism, step-bench, math-contract, gut]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-14 native scaffold (build script, pin, NativeSim, probe rule (i)) and plan 04-22 stale-library guards
provides:
  - "Separation.displacements and Separation.displacements_bucketed run in C++ (native/src/native_separation.cpp) behind their unchanged GDScript static API; both EnemySystem._separate and UnitSystem.separate use them; the GDScript bodies are deleted"
  - "tests/unit/test_separation_pins.gd: 42 seeded cases pinned by sha256 on the GDScript before any native code existed, never edited since"
  - "tools/stress/step_bench.gd --map=stress and --warmup=<0..900> (the PLAT-01 stress-night shape for headless step measurements)"
  - "native/src/gd_math.h: bit-exact mirrors of the GDScript utilities, Vector2 methods and SimClock tick conversions, opening with the operation table later plans must follow"
  - "NativeSim.probe_vector / probe_double / probe_int with the OP_* op codes bound on the class, and tests/unit/test_native_math_contract.gd (20,000 seeded inputs per operation, 19 tests)"
affects: [04-16, 04-17, 04-18, 04-19, 04-20, 04-21, 04-23]

actuals:
  tokens: 24820
  tasks: 2
  commits: 6

plan_head_before: 283bc74f41995b8122ceda25fab9445c28a800b5
plan_head_after: 6352c5a075163ffab64795f5ea364be22d85c817

tech-stack:
  added: []
  patterns:
    - "Port under pins: a GUT test pins the GDScript output digests, the native code must reproduce them unchanged, the GDScript body is then deleted (one implementation ships)"
    - "Bucketed grid as a sorted (key, index) vector with binary search; the key arithmetic wraps in unsigned arithmetic exactly like GDScript int64, partners are sorted ascending"
    - "Math contract: probe methods and op codes bound on NativeSim, the test reads the codes from the class by name; every godot-cpp out-of-line Vector2 method has a _CPP twin op so the table records proven equality"
    - "Medians of five for timings, interleaved A/B on the same machine state as corroboration"

key-files:
  created:
    - native/src/gd_math.h
    - native/src/native_separation.h
    - native/src/native_separation.cpp
    - tests/unit/test_separation_pins.gd
    - tests/unit/test_step_bench_args.gd
    - tests/unit/test_native_separation.gd
    - tests/unit/test_native_math_contract.gd
  modified:
    - native/src/native_sim.h
    - native/src/native_sim.cpp
    - simulation/squads/separation.gd
    - tools/stress/step_bench.gd

key-decisions:
  - "The push-apart pass crosses the GDScript/C++ boundary as whole packed arrays (positions, radii, ids in, displacements out): at 300 circles the native call costs 214 us against 3246 us in GDScript, so marshalling is negligible and the boundary pays"
  - "gd_math.h: the port calls the inline mirrors (compiled with this target's flags) for every out-of-line Vector2 method; godot-cpp's own methods and operators were also proven equal by the contract test, so both are allowed and the table says which"
  - "Op codes are enumerators of NativeSim bound as class constants: one table in native_sim.h, read by name from the test; probe_int takes five arrays (x, y doubles; m, n, k ints) because the plan left its parameter types open and clampi needs three ints"
  - "Vector2 contract inputs stay finite and NaN free: the engine warns (which GUT counts as a failure) when asked to normalize a non-finite vector, and which NaN payload survives two NaN operands is a compiler choice; NaN and infinity are covered among the double scalars"
  - "No change to any simulation number, digest or golden: smoke 2599c7c2, army f7a967ed, walls bfb05fc7, full_idle 4385f569, gate e448ffdb all hold"

requirements-completed: [PLAT-01]

coverage:
  - id: D1
    description: "Separation.displacements and displacements_bucketed run in C++ behind the unchanged GDScript API, byte-identical to the pins computed on the GDScript, with all replay and gate digests unchanged"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_separation_pins.gd (10 tests), tests/unit/test_native_separation.gd (6 tests), tests/unit/test_separation_grid.gd, tests/unit/test_separation.gd"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh smoke/army/walls --twice --expect-file, full_idle --twice, bash tools/gate_stress.sh --twice (digests below)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The native gain is measured and clears both machine-checked bars: stress-shape step median down 10.62 ms over five runs each (bar 2.0 ms) and the native pass 15.2x faster on the 300-circle stress crowd (bar 5x)"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "build/bench/before.txt, after.txt (10 STEP_BENCH lines each), micro.txt (1 SEPARATION_MICRO line), the awk comparison in the task verify block"
        status: pass
    human_judgment: false
  - id: D3
    description: "step_bench --map=stress and --warmup with the allowlist and the rebuilds refusal"
    verification:
      - kind: unit
        ref: "tests/unit/test_step_bench_args.gd (8 tests), tests/unit/test_stress_tool_args.gd (20 tests, unchanged)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every Vector2 operation and GDScript utility the port uses is bit-equal in C++ and in the engine on 20,000 seeded inputs, with the operation table at the top of gd_math.h"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_native_math_contract.gd (19 tests); mutation probes (reciprocal normalize, tick slack 0.0002 and 0.00005) fail it; tests/unit/test_native_rules_guard.gd and test_sim_clock.gd pass"
        status: pass
    human_judgment: false
  - id: D5
    description: "The 8.0 ms p95 frame budget is not met yet (stress shape step mean about 29 ms after this plan); this plan is the tracer, the rest of the step crosses in 04-16 to 04-21 and 04-23"
    requirement: PLAT-01
    verification: []
    human_judgment: true
    rationale: "PLAT-01 closes only when the whole step runs natively and the stress night is re-measured against 8.0 ms (04-VERIFICATION.md gap, G-04-5); this plan delivers the boundary proof"

duration: 88min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 15: Native Push-Apart Tracer Summary

**Separation.displacements and displacements_bucketed now run in C++ behind their unchanged GDScript API, byte-identical to 42 sha256 pins computed on the GDScript before any native code existed, with every replay and gate digest unchanged, a stress-shape step median 10.62 ms lower (interleaved A/B about 4 ms) and a native pass 15.2x faster; gd_math.h plus a 20,000-input contract test prove the rest of the port's math bit-equal to the engine.**

## Performance

- **Duration:** about 88 min (started about 2026-10-19T12:08:00Z, finished 2026-10-19T13:36Z; the full suite is about 20 min of it)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files modified:** 15 (11 created, 4 modified; counting the .uid files of the four new tests: 4 more)
- **Tracer feedback gate:** Task 1's verify is automated-only under `end-of-phase`; re-run end to end after the deletion commit and passed ("Tracer verified end-to-end, expanding").

## Accomplishments

- **Pins first.** `tests/unit/test_separation_pins.gd` builds 42 seeded cases (sizes 0, 1, 2, 50, 300 and 1000; spreads 5, 20 and 60 m; radii 0.5, 0.4 and mixed; exact duplicates that run the parity axis; exactly touching pairs and grids) and pins the sha256 of each pairwise result; the bucketed pass must equal it byte for byte. Committed green on the GDScript in `0efb1dc`, 36 minutes of work before the first native commit, and not touched since.
- **Stress shape.** `step_bench --map=stress --warmup=<n>` builds the diagnosis probe's shape (stress map, groups of enemies/4, king 100000 hp parked at (0, 14), every plot built) and prints `STEP_BENCH map=stress ...`; the prototype line format is unchanged; `--rebuilds` with the stress map is a usage error.
- **Native port.** `native/src/native_separation.cpp` follows the GDScript line by line (exact_port_rules 1 to 5, 10): single-precision Vector2, double scalars, narrowing at each operator, one shared `pair_push` for both passes, the grid as a sorted `(key, index)` vector whose int64 key arithmetic wraps like GDScript's, partners sorted ascending. It reproduced all 42 pins on the first run. Size mismatches give an all-zero array of `positions.size()`.
- **Switch and deletion.** `Separation` keeps its two static functions, documentation and asserts and calls `NativeSim.separation_displacements(_bucketed)`; the partner-sum loop, the cell key and the key constants are gone.
- **Math contract.** `gd_math.h` mirrors maxf/minf/clampf/absf/sqrt/floori/ceili/roundi/posmod/maxi/mini/clampi, length/length_squared/distance/dot/cross/normalized/move_toward/lerp and SimClock.ticks/flight_ticks (STEP as the double 1/30, slack 0.0001, MAX_TICKS clamp), opening with the operation table. `NativeSim.probe_vector/probe_double/probe_int` and the OP_* class constants feed `test_native_math_contract` (19 tests, 20,000 inputs per operation: signed zeros, exact halves, ulp neighbours of integers, multiples of STEP and tick-slack boundaries, huge and tiny magnitudes, infinities and NaN among the scalars). godot-cpp's own operators and out-of-line methods turned out bit-equal to the engine too (the `_CPP` twin ops).

## Measured results

All numbers are from this laptop, headless, one run at a time, GDScript simulation (`bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- ...`).

**build/bench/before.txt** (taken before any native code existed; stress shape, then prototype shape):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=40.70 p95_ms=73.91 max_ms=185.13
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=37.30 p95_ms=57.53 max_ms=191.55
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=39.37 p95_ms=65.70 max_ms=128.91
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=38.16 p95_ms=60.14 max_ms=125.62
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=39.49 p95_ms=66.08 max_ms=116.45
STEP_BENCH enemies=300 steps=30 mean_ms=35.23 p95_ms=47.70 max_ms=53.77
STEP_BENCH enemies=300 steps=30 mean_ms=35.01 p95_ms=44.87 max_ms=48.98
STEP_BENCH enemies=300 steps=30 mean_ms=35.72 p95_ms=48.33 max_ms=50.72
STEP_BENCH enemies=300 steps=30 mean_ms=37.20 p95_ms=54.39 max_ms=84.01
STEP_BENCH enemies=300 steps=30 mean_ms=34.64 p95_ms=43.98 max_ms=49.79
```

**build/bench/after.txt** (after the delegation commit's code, same flags):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=28.75 p95_ms=51.57 max_ms=113.96
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=29.24 p95_ms=47.59 max_ms=151.85
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=30.12 p95_ms=44.84 max_ms=192.77
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=26.98 p95_ms=42.35 max_ms=87.22
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=28.46 p95_ms=45.60 max_ms=152.28
STEP_BENCH enemies=300 steps=30 mean_ms=27.27 p95_ms=33.49 max_ms=75.82
STEP_BENCH enemies=300 steps=30 mean_ms=29.02 p95_ms=50.95 max_ms=57.54
STEP_BENCH enemies=300 steps=30 mean_ms=26.57 p95_ms=39.83 max_ms=68.88
STEP_BENCH enemies=300 steps=30 mean_ms=24.07 p95_ms=30.22 max_ms=37.15
STEP_BENCH enemies=300 steps=30 mean_ms=23.91 p95_ms=30.19 max_ms=30.81
```

**build/bench/micro.txt** (300 circles of the stress crowd at warm-up 300, 248 of them pushed, 200 repetitions each, outputs byte-equal):

```
SEPARATION_MICRO gdscript_us=3245.82 native_us=214.24
```

| Measure | Before / GDScript | After / native | Gain | Bar | Result |
|---------|------------------|----------------|------|-----|--------|
| Stress-shape step mean, median of 5 | 39.37 ms | 28.75 ms | 10.62 ms | at least 2.0 ms | pass |
| Prototype-shape step mean, median of 5 (informational) | 35.23 ms | 26.57 ms | 8.66 ms | none | n/a |
| displacements_bucketed on the 300-circle crowd | 3245.82 us | 214.24 us | 15.2x | at least 5x | pass |

**Reading the step gain honestly.** The before and after files were taken about 25 minutes apart and the machine was slower during the "before" runs (the plan warns that one load varies 22.7 to 31.8 ms on this laptop; the earlier diagnosis saw about 27 ms for this shape), so the 10.62 ms difference includes drift on top of the real gain. To separate the two I ran an interleaved A/B on the same machine state (original `separation.gd` swapped in and out of the working tree, stress shape, three pairs, file restored and verified with `cmp`):

```
gdscript 33.68 / native 30.27   (gain 3.41 ms)
gdscript 30.72 / native 28.94   (gain 1.78 ms)
gdscript 33.23 / native 28.06   (gain 5.17 ms)
```

Median 33.23 against 28.94 is 4.29 ms (mean gain 3.45 ms). That agrees with the diagnosis (3.7 to 4.1 ms of `_separate` plus 0.39 ms of `UnitSystem.separate`, less the array building the callers still do in GDScript), and one pair of three is under 2.0 ms, which is the laptop noise the plan's medians-of-five rule exists for. The plan's machine-checked bar is met on its own terms; the true per-step gain is about 3.5 to 4.3 ms, which is what 04-19 (the enemy-side array building) builds on. The stress-shape step mean after this plan is still about 29 ms against the 5 to 6 ms the 8.0 ms frame budget needs, as expected for a tracer.

## Task Commits

1. **Task 1 (tracer), pins on the GDScript:** `0efb1dc` (test)
2. **Task 1, stress shape and warm-up in step_bench:** `9aec0df` (feat)
3. **Task 1, the push-apart pass in C++ (gd_math.h, native_separation, NativeSim methods, native pin test):** `1306b6e` (feat)
4. **Task 1, Separation delegates, GDScript bodies deleted:** `783d673` (refactor)
5. **Task 2 RED, the failing contract test (probes missing, 18 of 19 tests failed on the missing op constants and probe methods):** `1b9016e` (test)
6. **Task 2 GREEN, probes, mirrors and the operation table:** `6352c5a` (feat)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified

- `native/src/gd_math.h` - mirrors and the operation table
- `native/src/native_separation.h`, `native/src/native_separation.cpp` - the push-apart pass
- `native/src/native_sim.h`, `native/src/native_sim.cpp` - bound static methods, op codes and probes
- `simulation/squads/separation.gd` - the stable GDScript API delegating to NativeSim
- `tools/stress/step_bench.gd` - `--map`, `--warmup`
- `tests/unit/test_separation_pins.gd`, `test_native_separation.gd`, `test_step_bench_args.gd`, `test_native_math_contract.gd` (with their .uid files)

## Decisions Made

See `key-decisions` above. In addition: the plan's "bucket map may be any ordered structure" was met with a sorted `(key, index)` vector and binary search (no unordered containers); the int64 key arithmetic is done in unsigned arithmetic so a pathological coordinate aliases keys exactly as GDScript's wrapping `int` did.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] HashingContext.update rejects an empty input**
- **Found during:** Task 1 (pins test, computing the pins)
- **Issue:** `digest_of` called `HashingContext.update` on the zero bytes of the empty case (`n0`), which the engine logs as an error (GUT counts engine errors as failures).
- **Fix:** skip `update` for an empty array; the digest of nothing is the standard sha256 of the empty string (`e3b0c442...`).
- **Files modified:** tests/unit/test_separation_pins.gd
- **Verification:** all 10 pin tests pass; fixed before the pins commit.
- **Committed in:** `0efb1dc`

**2. [Rule 2 - Missing Critical] A direct test of the native entry points, including T-04-39**
- **Found during:** Task 1 (rule 10 and threat T-04-39 require size checks, but the facade keeps GDScript asserts that debug builds stop on before the native code sees a bad size)
- **Issue:** nothing exercised `NativeSim.separation_displacements*` directly, so the all-zero answer for mismatched sizes (the T-04-39 mitigation) and the native pass against the pins were unproven outside the facade.
- **Fix:** added `tests/unit/test_native_separation.gd` (6 tests): every pin reproduced by both native functions, any cell size gives the pairwise answer, mismatched or oversized arrays give all-zero results, empty and single-circle inputs.
- **Files modified:** tests/unit/test_native_separation.gd (new, not in the plan's files_modified)
- **Committed in:** `1306b6e`

**3. [Rule 1 - Bug] Contract-test data generated NaN by accident, and missed the tick-slack boundary**
- **Found during:** Task 2 (GREEN run, then mutation probe)
- **Issue:** stepping `0.0` one ulp below produced a NaN bit pattern in the Vector2 inputs, and the engine's normalize then logged a non-finite warning; separately, a mutation of the rounding slack (0.0001 to 0.0002) was not caught because no input sat on the boundary.
- **Fix:** integer neighbours are stepped from non-zero integers only; Vector2 components are clamped to a finite float32 range (NaN and infinities stay among the double scalars); every seventh scalar pair becomes a duration, or a distance and power-of-two speed, whose step fraction sits near 0.0001. Mutation probes now fail the test: reciprocal multiply in `normalized`, slack 0.0002, slack 0.00005.
- **Files modified:** tests/unit/test_native_math_contract.gd
- **Committed in:** `6352c5a` (test edits are part of GREEN; the RED commit `1b9016e` is the test as first written)

### Plan conformance notes (not deviations)

- `probe_int` takes five arrays (`x`, `y` doubles; `m`, `n`, `k` ints): the plan named `probe_int(op, x, y)` without types, and the listed operations need doubles in (floori, ceili, roundi, ticks, flight_ticks) and three ints (clampi).
- The operation table in `gd_math.h` was drafted in Task 1 and finished in Task 2 with the proving op codes; `native_sim.h` carries the one documented op-code table the test reads by name.
- RED for Task 2 reached through `ClassDB.class_call_static` and `class_has_integer_constant` (no parse dependency on symbols that did not exist yet), so the failure is on the planned assertions rather than a parse error.
- `gsd check tdd-red-evidence` was not run: this plan is `type: execute` with one `tdd="true"` task, not `type: tdd`. RED evidence: command `bash tools/test.sh -gselect=test_native_math_contract`, exit 1, 18 of 19 tests failing on "NativeSim has no op constant ..." and missing probe methods, the 19th (input-coverage sanity test, needs no native class) passing.

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical). **Impact on plan:** none on scope or numbers.

## Issues Encountered

- A first `--map=stress` bench run was started while a GUT run was still going in the background; that sample (35.75 ms mean) was discarded and is in neither bench file. All recorded runs were taken one at a time.
- The before/after bench files drift with the laptop state (see the A/B above); the bars were still judged on the plan's rule (medians of five, awk comparison) and the interleaved pairs are reported beside them.
- A stray `~libduskhold_sim.windows.x86_64.dll~RF*.TMP` pair sits in `addons/duskhold_sim/bin/` from an earlier session; it is git-ignored and untouched.

## Known Stubs

None.

## Threat Flags

None. The new surface is pure math on arrays that GDScript passes in (no I/O, no engine singletons); T-04-38 is mitigated by the pins, the four replays, the gate digest and the 20,000-input contract test, and T-04-39 by the size checks tested in `test_native_separation.gd`.

## Verification results

- Task 1 verify chain (as written in the plan): exit 0, `median before=39.37 after=28.75`, `micro g=3245.82 n=214.24`, lint clean.
- Task 2 verify chain (as written): exit 0.
- Digests after both tasks (re-run after the last native build): smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks, against tests/golden), army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353), walls `bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (1961), full_idle `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (6911), `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`. All unchanged.
- Full suite (`bash tools/test.sh`): 200 scripts, 1873 tests, 30942 asserts, all passing, exit 0 (baseline 196 / 1830 / about 30300; the +4 scripts and +43 tests are the four new test files: 10 + 8 + 6 + 19). Lint: 344 files unchanged, no problems.
- Acceptance: `git log` shows test_separation_pins.gd in one commit (`0efb1dc`) older than the first commit touching native_separation.cpp (`1306b6e`); before.txt and after.txt hold ten STEP_BENCH lines each and micro.txt one SEPARATION_MICRO line; separation.gd keeps both `static func` lines and has no partner-sum loop.

## Next Phase Readiness

Ready for the rest of the port (04-16 first needs the owner's CI binary decision). Later plans port on `gd_math.h`: call only what its table allows, add a `_CPP`-style twin op only if they need godot-cpp's method, extend `probe_*` for any new operation, and rebuild with `bash tools/native_build.sh` after every C++ edit (the wrappers refuse a stale library). The step is still GDScript for everything but the push-apart pass: stress-shape step mean about 29 ms against the 8.0 ms frame budget, so PLAT-01 stays open until the whole step crosses and 04-VERIFICATION.md's success criterion 3 is re-measured.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-19*

## Self-Check: PASSED

- Created files exist: native/src/gd_math.h, native/src/native_separation.h, native/src/native_separation.cpp, tests/unit/test_separation_pins.gd, tests/unit/test_step_bench_args.gd, tests/unit/test_native_separation.gd, tests/unit/test_native_math_contract.gd (all tracked).
- Commits found in git log: 0efb1dc, 9aec0df, 1306b6e, 783d673, 1b9016e, 6352c5a; `git rev-list --count 283bc74..HEAD` = 6.
- Re-run after the last code change: both task verify chains, the four replays, the gate, the full suite and lint.
