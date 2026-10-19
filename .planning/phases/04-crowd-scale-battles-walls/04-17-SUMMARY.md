---
phase: 04-crowd-scale-battles-walls
plan: 17
subsystem: native-port
tags: [gdextension, cpp, godot-cpp, walls, wall-solids, determinism, step-bench, gut]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-15 gd_math.h operation table and the pins-first port style; plan 04-16 CI that builds the native library on Linux and Windows
provides:
  - "NativeWalls (native/src/native_walls.*): the wall segment mirror, the 4 m bucket grid, segments_near, first_blocking, push_out and closest_point in C++, plus plain C++ members for the native enemy step of plan 04-19"
  - "WallSystem keeps the mirror in step on every health write (on_building_built, damage_segment, restore_all) and exposes native(); WallSolids' three statics and WallSystem.segments_near keep their GDScript API and delegate"
  - "tests/unit/test_wall_geometry_pins.gd: 60 sha256 pins (4 worlds x 3 health patterns x 5 query kinds, 2,000 seeded queries each) computed on the GDScript before any native wall code, never edited since"
  - "tests/unit/test_native_walls.gd: bad-input answers and mirror step-keeping (T-04-45, T-04-46)"
affects: [04-18, 04-19, 04-20, 04-21, 04-23]

actuals:
  tokens: 14200
  tasks: 2
  commits: 3

plan_head_before: 91387a08162dc49c67b79fb2a603a3ab6b3ac902
plan_head_after: 6d662f57fac464c0a32a228e3ce2d0a727ad85ef

tech-stack:
  added: []
  patterns:
    - "Mirror pattern: a native copy of WallSystem's segments, written through set_health from the three GDScript health writers; the pins break segments through damage_segment, so a missed write fails a pin"
    - "Bucket grid as an ordered std::map keyed exactly like WallSystem._key (int64 arithmetic wrapped in unsigned), per-cell lists ascending, query walks the same cells and sorts and de-duplicates only when more than one cell was visited"
    - "Plain C++ members (near_segments, blocking_segment, pushed_position, closest_on_segment) beside the bound ones so a native caller never crosses the GDScript boundary"

key-files:
  created:
    - native/src/native_walls.h
    - native/src/native_walls.cpp
    - tests/unit/test_wall_geometry_pins.gd
    - tests/unit/test_native_walls.gd
  modified:
    - native/src/register_types.cpp
    - simulation/walls/wall_system.gd
    - simulation/walls/wall_solids.gd

key-decisions:
  - "Candidate sets are the GDScript's own: the native grid uses WallSystem._bucket's inflated box, floori on doubles, KEY_OFFSET and KEY_STRIDE and the same ascending list, because push_out's answer depends on exactly which segments it visits"
  - "WR-02 (strict line test without a tangency epsilon) and IN-02 (bucket walk grows with the square of the reach) are ported unchanged on purpose; the tangent case is pinned as the GDScript behaved"
  - "A query whose cell range exceeds 4M cells (one the GDScript would never finish) is cut to the occupied cell range; every range the GDScript could finish is walked exactly as it did, NaN positions included"
  - "Health is mirrored per write (set_health) rather than synced as an array: three call sites, each a single boundary crossing"

patterns-established:
  - "Pins first and never edited: af9beaa precedes every commit that touches native_walls.cpp (23019a6)"
  - "A/B on the same machine state beside the before/after files, because the laptop drifts several ms between runs taken 30 minutes apart"

requirements-completed: [PLAT-01]

coverage:
  - id: D1
    description: "The wall solid test (first_blocking, push_out, closest_point, segments_near) runs in C++ for every caller behind the unchanged GDScript API, byte-identical to the 60 pins computed on the GDScript, with every replay and the gate digest unchanged"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_geometry_pins.gd (7 tests), tests/unit/test_native_walls.gd (7 tests), tests/unit/test_wall_solids.gd, test_wall_blocking.gd, test_wall_system.gd"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh smoke/army/walls --twice --expect-file, full_idle --twice, bash tools/gate_stress.sh --twice (digests below), full suite 202 scripts / 1887 tests"
        status: pass
    human_judgment: false
  - id: D2
    description: "One implementation ships: WallSolids' geometry helpers and WallSystem's bucket dictionary, helpers and constants are deleted"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "grep: no _segments_distance or _pushed_from in wall_solids.gd, no _buckets in wall_system.gd; test_native_rules_guard passes"
        status: pass
    human_judgment: false
  - id: D3
    description: "The stress-shape step median is measured before and after (five runs each) and an interleaved A/B corroborates the direction"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "ten before and ten after STEP_BENCH lines and the A/B pairs in this SUMMARY"
        status: pass
    human_judgment: false
  - id: D4
    description: "The 8.0 ms p95 frame budget is not met yet (stress shape step mean still about 29 ms); the rest of the step crosses in 04-18 to 04-21 and 04-23"
    requirement: PLAT-01
    verification: []
    human_judgment: true
    rationale: "PLAT-01 closes only when the whole step runs natively and the stress night is re-measured against 8.0 ms (04-VERIFICATION.md gap G-04-5); plan 04-21 judges the frame budget"

duration: 54min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 17: Native Wall Solid Test Summary

**The wall solid test (segments_near, first_blocking, push_out, closest_point) now runs in C++ on a segment mirror that WallSystem keeps in step with every health change, byte-identical to 60 sha256 pins computed on the GDScript first, with all five replay digests and the 300-enemy gate unchanged, the GDScript bodies and the bucket dictionary deleted, and an interleaved A/B showing the stress-shape step about 4 to 5 ms lower.**

## Performance

- **Duration:** about 54 min (started about 2026-10-19T14:40Z, finished 2026-10-19T15:36Z; the full suite is 15 min of it)
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files modified:** 9 in the production commits (4 created plus 2 .uid files, 3 modified)
- **Tracer feedback gate:** Task 1's verify is automated-only under `end-of-phase`; the whole chain passed end to end (pins, wall suites, rules guard, four replays, gate, lint) and Task 2's chain re-ran everything after the expansion: "Tracer verified end-to-end, expanding".

## Accomplishments

- **Pins first.** `tests/unit/test_wall_geometry_pins.gd` builds four worlds (the prototype map with its four wall runs at tier I, the stress map's gate wall, the sealed 32-segment ring, the gap fixture), each in three health patterns applied through `damage_segment` (all intact, every third segment broken, the first run broken), and pins the sha256 of the packed results of 2,000 seeded `segments_near` queries (reaches 0 to 60 m, cell-border multiples, six bad reaches), 2,000 `first_blocking` lines (radii 0.0, 0.4, 0.5, 0.6, plus 40 far-to-castle lines and every spawn point to the castle), 2,000 `push_out` points (near, inside and exactly on segments), `closest_point` of every index from -1 to count+1 against 40 points each, and the WR-02 tangent case (every segment midpoint pushed out to its reach and line-tested along and against the wall, plus 2,000 seeded push-then-walk-away lines). 60 pins; two sanity tests prove the queries block, push and miss. Committed green on the GDScript in `af9beaa`, before `native_walls.cpp` existed, and not touched since.
- **Native mirror.** `NativeWalls` holds starts, ends, half thickness, health and the intact count, and builds the 4 m bucket grid exactly as `WallSystem._bucket` did. `segments_near`, `first_blocking`, `push_out` and `closest_point` follow the GDScript line by line under exact_port_rules 1 to 6 and 10 (real_t Vector2 values, double scalars, narrowing at each operator, gd_math.h mirrors only, no unordered container, no FMA). Bad input answers what the GDScript answered: -1, the zero vector, an empty array, an ignored health write; mismatched `setup` arrays give an empty mirror.
- **Mirror kept in step.** `WallSystem` creates the mirror after the runs are added, calls `set_health` in `on_building_built`, `damage_segment` and `restore_all`, and gains `native()` (16 public methods). A mutation probe (dropping the `set_health` in `damage_segment`) fails 4 of the 7 pin tests.
- **One implementation.** `WallSolids` keeps its four public statics and docs and delegates to the mirror; `_pushed_from`, `_closest_on`, `_point_distance`, `_segments_distance`, `MAX_PASSES` and `REACH_MARGIN` are gone, as are `WallSystem._buckets`, `_bucket`, `_key`, `_sorted_unique`, `BUCKET_CELL`, `KEY_OFFSET` and `KEY_STRIDE`.
- **Extra cross-check (scratch, not committed).** Before wiring the GDScript, a scratch script compared the native class with the GDScript on 360,000 seeded points across all 12 world/pattern cases (`segments_near`, `first_blocking`, `push_out`, `closest_point`, with bad indices and bad reaches): zero mismatches.

## Measured results

All numbers are from this laptop, headless, one run at a time, GDScript simulation otherwise (`bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- ...`; stress shape `--map=stress --enemies=300 --warmup=300 --steps=300`, prototype shape `--enemies=300 --steps=30`).

**Before** (taken at `af9beaa`, the pins commit, with the GDScript wall solid test and no native wall code; stress shape first, then prototype):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=27.73 p95_ms=51.51 max_ms=153.81
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=25.55 p95_ms=39.20 max_ms=128.49
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=26.24 p95_ms=42.74 max_ms=96.66
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=26.86 p95_ms=48.97 max_ms=226.33
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=31.60 p95_ms=68.86 max_ms=119.24
STEP_BENCH enemies=300 steps=30 mean_ms=21.93 p95_ms=27.74 max_ms=30.38
STEP_BENCH enemies=300 steps=30 mean_ms=45.01 p95_ms=108.96 max_ms=211.24
STEP_BENCH enemies=300 steps=30 mean_ms=24.57 p95_ms=28.32 max_ms=28.79
STEP_BENCH enemies=300 steps=30 mean_ms=52.77 p95_ms=124.23 max_ms=153.79
STEP_BENCH enemies=300 steps=30 mean_ms=25.78 p95_ms=38.72 max_ms=49.13
```

**After** (at the Task 2 code, same flags, taken about 50 minutes later):

```
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=29.75 p95_ms=44.17 max_ms=212.86
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=37.26 p95_ms=85.25 max_ms=251.09
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=28.89 p95_ms=55.67 max_ms=147.98
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=28.97 p95_ms=51.19 max_ms=163.29
STEP_BENCH map=stress enemies=300 warmup=300 steps=300 mean_ms=38.02 p95_ms=82.34 max_ms=242.95
STEP_BENCH enemies=300 steps=30 mean_ms=61.00 p95_ms=124.43 max_ms=124.61
STEP_BENCH enemies=300 steps=30 mean_ms=22.36 p95_ms=31.39 max_ms=33.19
STEP_BENCH enemies=300 steps=30 mean_ms=23.19 p95_ms=32.50 max_ms=32.61
STEP_BENCH enemies=300 steps=30 mean_ms=22.27 p95_ms=31.37 max_ms=32.87
STEP_BENCH enemies=300 steps=30 mean_ms=20.47 p95_ms=28.43 max_ms=30.17
```

| Shape | Median before | Median after | Difference |
|-------|--------------|-------------|------------|
| Stress, step mean, median of 5 | 26.86 ms | 29.75 ms | +2.89 ms (worse in the two files; see below) |
| Prototype, step mean, median of 5 | 25.78 ms | 22.36 ms | -3.42 ms |

**Reading the stress-shape figure honestly.** The plan has no gain bar, but the two stress files read the wrong way round (26.86 before, 29.75 after) while the prototype shape reads the right way. Both files carry outliers (45.01 and 52.77 before, 61.00 and 37 to 38 after) and the laptop drifts by several ms over the roughly 50 minutes between them (the same effect 04-15 recorded). So I ran an interleaved A/B on the same machine state: the GDScript `wall_solids.gd` and `wall_system.gd` from `af9beaa` swapped in and out of the working tree against the Task 2 files (stress shape, four pairs, the Task 2 files restored and verified byte for byte with `cmp`):

```
gdscript 31.55 / native 28.40   (gain 3.15 ms)
gdscript 33.39 / native 30.67   (gain 2.72 ms)
gdscript 34.16 / native 28.95   (gain 5.21 ms)
gdscript 34.76 / native 27.65   (gain 7.11 ms)
```

Median 33.78 against 28.68, a gain of 5.10 ms (mean gain 4.55 ms; every pair positive). That is the figure I trust: the native wall solid test takes about 3 to 7 ms off the stress-shape step, consistent with the diagnosis (`first_blocking` at 145 to 272 us a call, `push_out`'s one `segments_near` per enemy per tick). The before/after files on their own say nothing reliable about the direction at this noise level. The stress-shape step is still about 28 to 29 ms against the 5 to 6 ms the 8.0 ms frame budget needs, as expected: the enemy step itself crosses in 04-19 and the frame budget is judged in 04-21.

## Task Commits

1. **Task 1 (tracer), pins on the GDScript:** `af9beaa` (test)
2. **Task 1, the native mirror, WallSystem keeping it in step, first_blocking switched, native-input tests:** `23019a6` (feat)
3. **Task 2, push_out, closest_point and segments_near switched, GDScript bodies and the bucket dictionary deleted:** `6d662f5` (refactor)

**Plan metadata:** the docs commits that carry this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified

- `native/src/native_walls.h`, `native/src/native_walls.cpp` - NativeWalls: mirror, bucket grid, the four queries, plain C++ members
- `native/src/register_types.cpp` - `GDREGISTER_CLASS(NativeWalls)`
- `simulation/walls/wall_system.gd` - owns the mirror, mirrors every health write, `native()`, `segments_near` delegates; bucket code deleted
- `simulation/walls/wall_solids.gd` - three statics delegating; geometry helpers and constants deleted
- `tests/unit/test_wall_geometry_pins.gd`, `tests/unit/test_native_walls.gd` (with their .uid files)

## Decisions Made

See `key-decisions` above. In addition: the bucket map is an ordered `std::map` (the rules guard forbids unordered containers and the plan allows any ordered or key-addressed lookup), and the query keeps a mutable scratch buffer so a native caller allocates nothing per call (single-threaded, documented in the header).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] A direct test of the native entry points**
- **Found during:** Task 1 (rule 10 and threats T-04-45 and T-04-46 require index, size and finiteness checks and a mirror that never drifts, but the facade passes only well-formed values and the pins cover only good input)
- **Issue:** nothing exercised `NativeWalls` directly for bad indices, non-finite reaches and radii, mismatched `setup` arrays or the mirror's intact count after a purchase, a break, a non-breaking hit, a tier purchase over a hole and the dawn restore.
- **Fix:** added `tests/unit/test_native_walls.gd` (7 tests, 38 asserts).
- **Files modified:** tests/unit/test_native_walls.gd (new, not in the plan's files_modified)
- **Committed in:** `23019a6`

### Plan conformance notes (not deviations)

- The plan's Task 2 step 1 asks for the baseline "before switching"; I took it before any native wall code at all (`af9beaa`), which also covers Task 1's `first_blocking` switch, so the before/after pair spans the whole plan.
- The plan's executor rule about option C (committing the DLL) does not apply: the owner chose option A at plan 04-16, nothing binary is committed and CI builds the library from source.
- One piece of C++ goes beyond a literal port: a query whose cell range holds more than 4M cells is cut to the occupied cell range. The GDScript would never have finished such a query, and every range it could finish (NaN and infinite positions included, which resolve to one hardware-converted cell) is walked exactly as before.

**Total deviations:** 1 auto-fixed (1 missing critical). **Impact:** none on scope or numbers.

## Issues Encountered

- The before/after bench files drifted against each other (see Measured results); resolved with the interleaved A/B, both reported.
- A first lint pass inside the Task 1 verify chain raced with the new native test file being written and flagged its formatting; `lint --fix` formatted it and the next lint was clean (the chain's other steps all passed).
- The local build is MSVC only. The C++ is written warning-free for GCC (`-Wall -Wextra -Werror`, no unused parameters, no signed/unsigned comparisons) but was not compiled with GCC here; the Linux CI job compiles it on the next push, and that is where a float difference would show if there were one.

## Notes for the later `/gsd-code-review 4 --fix` pass

- **WR-02** (the strict line test `>=` without a tangency epsilon) and **IN-02** (the bucket walk grows with the square of the reach) now live in `native/src/native_walls.cpp` (`segments_distance`, `NativeWalls::blocking_segment`, `NativeWalls::near_segments`), ported unchanged on purpose: fixing either moves a digest and needs its own owner golden decision. The WR-02 tangent case is pinned as the GDScript behaved today (`*_tangent` pins).
- **IN-01** (`push_out`'s allocations) is gone with the GDScript: the native `push_out` allocates nothing per call.
- The `*_near` and `*_closest` pins are independent of health by construction (`segments_near` returns standing or not, `closest_point` is geometry); the `blocking`, `push` and `tangent` pins differ per pattern.

## Known Stubs

None.

## Threat Flags

None. The new surface is pure geometry on arrays and values that GDScript passes in (no I/O, no engine singletons). T-04-44 is mitigated by the pins, the exact candidate sets, the four replays and the gate digest; T-04-45 by the three `set_health` call sites and the mutation probe; T-04-46 by the native checks tested in `test_native_walls.gd`.

## Verification results

- Task 1 verify chain (as written in the plan): every step passed (pins 7/7, test_wall_solids 15/15, test_wall_blocking 3/3, test_wall_system 17/17, test_native_rules_guard 10/10, replays, gate); the final lint step flagged only the then-unformatted new test, fixed by `lint --fix` and re-run clean.
- Task 2 verify chain (as written, `CHAIN_EXIT=0`): `NATIVE_BUILD_OK`, full suite `bash tools/test.sh`: 202 scripts, 1887 tests, 30908 asserts, all passing (baseline 200 / 1873 / about 30950; +2 scripts and +14 tests are the two new test files, 7 + 7), named suites present in the JUnit XML, lint clean (346 files).
- Digests after Task 2: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks, against tests/golden), army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353), walls `bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (1961), full_idle `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (6911), `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`. All unchanged.
- Acceptance: `git log` shows the pins file in one commit (`af9beaa`) older than the first commit touching `native_walls.cpp` (`23019a6`) and unchanged since; `wall_solids.gd` has neither `_segments_distance` nor `_pushed_from`; `wall_system.gd` has neither `_buckets` nor any bucket helper, and has `func native(` with `set_health` in its three writers; ten before and ten after bench lines above.

## Next Phase Readiness

Ready for 04-18 and 04-19. The native enemy step can call the mirror without the GDScript boundary through `NativeWalls::near_segments`, `blocking_segment`, `pushed_position` and `closest_on_segment` (take the `WallSystem.native()` object and keep a reference to it). PLAT-01 stays open until the whole step crosses and 04-VERIFICATION.md's success criterion 3 is re-measured by 04-21.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-19*

## Self-Check: PASSED

- Created files exist: native/src/native_walls.h, native/src/native_walls.cpp, tests/unit/test_wall_geometry_pins.gd, tests/unit/test_native_walls.gd (all tracked).
- Commits found in git log: af9beaa, 23019a6, 6d662f5; `git rev-list --count 91387a0..HEAD` = 3 before this SUMMARY's own commit.
- Re-run after the last code change: the Task 2 verify chain, the A/B (files restored byte for byte), lint.
