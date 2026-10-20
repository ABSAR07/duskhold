---
phase: 04-crowd-scale-battles-walls
plan: 26
subsystem: presentation
tags: [gdextension, native, cpp, view-port, enemies, puffs, multimesh, pins-first, clock-seam, gap-closure]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-25 CrowdBatch.mirror()/layout()/commit_buffer(), native_mirror.h, the NativeArrows class shape and the pin harness; plan 04-24 view_fill_bench.gd and the stamp guard; plans 04-19/04-20 the packed enemy read view; plan 04-15 gd_math.h
provides:
  - "EnemyViews.set_clock(): the millisecond-clock seam (default Time.get_ticks_msec) that lets the flash and the puffs be pinned deterministically"
  - "tests/unit/test_enemy_fill_pins.gd: the three archetype batches, the bars and the puffs pinned on the GDScript fill (stress night, walls replay, army replay, puff flood), one commit, never edited"
  - "NativeEnemyViews (native/src/native_enemy_views.h/.cpp): per-enemy state and the whole per-frame fill of bodies, flashes and hurt-only bars in C++; native_mirror.h write_origin"
  - "EnemyViews delegating to it, the GDScript loop, the four per-enemy dictionaries, the flash helper and the drawn-id search deleted"
  - "NativePuffs (native/src/native_puffs.h/.cpp): the 128-slot death-puff ring and both scans in C++; DeathPuffBatch delegating, the GDScript ring deleted"
  - "CrowdBatch.commit() skips the upload when nothing is held and nothing is shown (review IN-08)"
  - "tests/unit/test_native_enemy_views.gd: 18 entry tests for both native classes"
affects: [04-27, 04-28]

actuals:
  tokens: 17300
  tasks: 2
  commits: 5

plan_head_before: ed8c5c3914d8174ead7aefd4630121667d916fa8
plan_head_after: 4b1022c571e5c539aea9a0a9300630af2c9c28ab

tech-stack:
  added: []
  patterns:
    - "Clock seam: a Callable defaulting to the engine clock, replaced only by the pin test, so a time-dependent fill is pinned byte for byte"
    - "Pins first (computed on the GDScript, one commit, never edited), then the native fill must reproduce them unchanged; the GDScript is deleted in the switch commit after the gain is read"
    - "A native fill writes its own copy of the batch mirror and takes it for writing only when its first instance is written; GDScript hands it back with commit_buffer after the fill call (never in the same argument list)"
    - "The per-enemy dictionaries become one id-ordered record vector in C++, fed by the unchanged GDScript event handlers"

key-files:
  created:
    - native/src/native_enemy_views.h
    - native/src/native_enemy_views.cpp
    - native/src/native_puffs.h
    - native/src/native_puffs.cpp
    - tests/unit/test_enemy_fill_pins.gd
    - tests/unit/test_native_enemy_views.gd
  modified:
    - native/src/native_mirror.h
    - native/src/register_types.cpp
    - presentation/enemies/enemy_views.gd
    - presentation/vfx/death_puff_batch.gd
    - presentation/crowd/crowd_batch.gd
    - tests/unit/test_crowd_batch.gd

key-decisions:
  - "The one-implementation rule held for both views: EnemyViews and DeathPuffBatch keep their nodes, constants, handlers and public hooks, and every per-enemy and per-puff GDScript body is gone; no runtime fallback"
  - "Pins carry a fourth run, a puff flood (900 frames, 150-death burst past the ring's cap), because the stress night kills nobody in 2400 frames (0 puffs) and the walls and army replays never exceed 3 puffs, so only the flood pins the ring's fill, refusal, expiry and wrap"
  - "A native fill must run before its mirror is handed back: GDScript evaluates arguments left to right, so commit_buffer(native.mirror(), native.refresh(...)) captured the pre-write array"
  - "NativeEnemyViews and NativePuffs take a mirror for writing (the copy-on-write detach) only when they write the first instance, so idle frames neither upload nor copy (review IN-08)"
  - "The 128-ring and the 512 caps, the flash window, the hurt-only rule, every constant and every public hook stay as they were (D-13); only HealthBar3D.should_show was copied into C++, with its source named"

patterns-established:
  - "Bench: five before and five after runs one at a time, medians by sorting mean_us, both medians and the ratio quoted with the ten lines"

requirements-completed: []

coverage:
  - id: D1
    description: "EnemyViews reads its millisecond clock through set_clock (frame sample, hit time, puff birth, puff refresh); default unchanged"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd (12 tests, green on the seam commit 4d31a82 and on every later tree)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The enemy bodies, flashes, hurt-only bars and death puffs are pinned on the GDScript fill before any native enemy-view code: stress night (2400 frames, 300 enemies, 135 bars), walls (3922 frames, 12 enemies, 2 puffs), army (2706 frames, 17 enemies, 3 puffs), puff flood (900 frames, 128 puffs)"
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_fill_pins.gd (5 tests; one commit b7f29f6, green twice on the GDScript, green unchanged on NativeEnemyViews and again on NativePuffs)"
        status: pass
    human_judgment: false
  - id: D3
    description: "NativeEnemyViews fills the archetype batches, flashes and bars in one native call per frame, byte for byte as the GDScript, at 10.4x (758.89 us to 73.12 us median; 19.9x on the final lazy-buffer build, 38.13 us)"
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_fill_pins.gd; tests/e2e/test_enemy_views.gd; tests/unit/test_native_enemy_views.gd"
        status: pass
      - kind: other
        ref: "build/bench/enemies_before.txt and enemies_after.txt: medians 758.89 -> 73.12, ratio 10.38 (bar 3.0), drawn_max 300 on all ten lines"
        status: pass
    human_judgment: false
  - id: D4
    description: "NativePuffs runs the 128-slot ring and both scans natively, byte for byte as the GDScript, at 30.2x (140.05 us to 4.63 us median)"
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_fill_pins.gd (walls, army and flood hash the puff batch); tests/unit/test_death_puff_batch.gd; tests/unit/test_native_enemy_views.gd (6 puff tests)"
        status: pass
      - kind: other
        ref: "build/bench/puffs_before.txt and puffs_after.txt: medians 140.05 -> 4.63, ratio 30.25 (bar 3.0), drawn_max 87 on all ten lines"
        status: pass
    human_judgment: false
  - id: D5
    description: "An idle CrowdBatch uploads no buffer (nothing held and nothing shown), the first empty frame after a drawn one still shows 0, and the CPU mirror is unchanged on an idle frame"
    verification:
      - kind: unit
        ref: "tests/unit/test_crowd_batch.gd (test_an_idle_batch_uploads_no_buffer_until_something_is_drawn, and the existing empty-frame test)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Nothing the round is measured against moved: four replays and the gate digest"
    verification:
      - kind: integration
        ref: "REPLAY_OK smoke 2599c7c2 (703) / army f7a967ed (1353) / walls bfb05fc7 (1961) against tests/golden, full_idle 4385f569 (6911) twice; GATE_OK enemies=300 crossed=300 stuck=0 digest=e448ffdb; full suite 218 scripts, 2049 tests, 2049 passing"
        status: pass
    human_judgment: false
  - id: D7
    description: "The crowd looks as it did after the port (crowd_stress_night and walls_night_breach compared before and after)"
    verification: []
    human_judgment: true
    rationale: "A visual comparison of real-window captures; headless Godot reads MultiMeshes back as zeros (RESEARCH F3), so the executor's by-eye review lines below stand in for the harvested human-check at the end of the phase"

duration: 51min
completed: 2026-10-20
status: complete
---

# Phase 4 Plan 26: Enemies and puffs in C++ (the second view port) Summary

**EnemyViews' per-enemy fill (bodies, hit flashes, hurt-only bars) now runs as one NativeEnemyViews call per frame over the packed enemy read view, and the death-puff ring runs as NativePuffs, both byte for byte equal to the GDScript they replaced (pins computed on the GDScript behind a new clock seam, committed first): the enemies bench falls from a 758.89 us median to 73.12 us (10.4x, bar 3.0) and the puffs bench from 140.05 us to 4.63 us (30.2x, bar 3.0), idle batches no longer upload, and the four replays, the gate digest and the full suite (2049 of 2049) did not move.**

## Performance

- **Duration:** 51 min
- **Started:** 2026-10-20T13:13:26Z
- **Completed:** 2026-10-20T14:04Z (last task commit; SUMMARY follows)
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files modified:** 14 (6 created, 6 modified, plus 2 `.gd.uid`)

## Accomplishments

- **Clock seam first** (`4d31a82`, behaviour unchanged): `EnemyViews.set_clock(Callable)` with the engine clock as default; the frame sample, the hit time, the puff birth and the puff refresh all read through it; an invalid Callable is ignored. `test_enemy_views` green, lint clean.
- **Pins on the GDScript fill** (`b7f29f6`, the only commit that ever touches `test_enemy_fill_pins.gd`): four runs on a deterministic clock (starts at 100000 ms, moves by the rounded frame delta, six unequal frame deltas), one SHA-256 per run over the view, bar and puff counts and, after every frame, the count and the whole mirror (stale tail included) of Grunts, Skirmishers, Others, Bars and Puffs. Computed on the GDScript, green twice:

  | Run | Frames | Most enemies | Most bars | Most puffs | Digest |
  |-----|--------|--------------|-----------|------------|--------|
  | stress night (300 enemies) | 2400 | 300 (floor 300 met) | 135 | 0 | `e8183d664f3f784734e49c2612422f007b4558153fbf0af5ea5e2bdd0e0643dc` |
  | walls replay | 3922 | 12 | 2 | 2 | `fdeb2c226c927763599cdc1d7c215d3d22475bed9a431514ebc251e1c9b23e55` |
  | army replay | 2706 | 17 | 3 | 3 | `ad55a687330e8bc6f48f43fb94c2cd665b1665dbcf4f57f6013640bd6ccc3b67` |
  | puff flood | 900 | 0 | 0 | 128 | `8495d93e355e09d750ff7041d778e34c9d22571401cfaadf8f2adc557a8a43b9` |

- **NativeEnemyViews** (`b27e082` native files, `d521b38` the switch): one id-ordered record per known enemy (kind, max hp, hit points, last hit) fed by the unchanged GDScript handlers, and `fill(frame_ms, blend, ids, previous, current)` that is the GDScript loop line by line (read-view order, the draw cap, `gd::lerp` at a real_t weight, the flash worked out before the add so a hit is forgotten even when the batch is full, double arithmetic for the flash, the bar height and the bar ratio narrowed once into the Color, the hurt-only rule copied from `HealthBar3D.should_show` with its source named). `native_mirror.h` gained `write_origin` (CrowdBatch.add's floats). The pins, `test_enemy_views`, `test_health_bar_batch`, `test_death_puff_batch`, `test_crowd_batch`, `test_projectile_fill_pins` and `test_native_rules_guard` all passed on the first native run, with no edit to any pin; the four replays and the gate held. The GDScript loop, the four dictionaries, the flash helper, the drawn-id search and the drawn mirrors were deleted in the same commit as the switch, after the gain was read.
- **NativePuffs** (`4b1022c`): the ring (slots, birth times as doubles, the standing scan, the per-frame write) in C++; `DeathPuffBatch` keeps `setup_puffs`, `spawn`, `refresh`, `active_count`, every constant and the age contract and delegates; the GDScript ring arrays and both scans are gone. The enemy pins (which hash the puff batch, the flood run ring-wrapping it) and `test_death_puff_batch` passed unchanged on the first run with the refresh ordering fixed (see Deviations).
- **Idle batches stop uploading** (review IN-08, `4b1022c`): `CrowdBatch.commit()` returns before the buffer assignment when `_count == 0` and `multimesh.visible_instance_count == 0`; the first empty frame after a drawn one still sets 0. The CPU mirror is unchanged on such a frame, so every pin held. The new test reads the headless server: `multimesh.buffer.size()` is 0 after setup and after an empty commit (RESEARCH F6 holds on the dummy server), then `capacity * stride` floats after one instance. NativeEnemyViews and NativePuffs also take their mirror for writing only when they write their first instance, so an idle frame neither uploads nor copies the shared mirror.
- **Native entry tests** (`4b1022c`): `tests/unit/test_native_enemy_views.gd`, 18 tests: mismatched read-view arrays draw nothing, damage on an unknown id is ignored, 600 known enemies draw exactly 512 and stop, a flash runs 1.0, 0.5, 0.0 and an expired hit stays forgotten, clear and forget, set_mirror refuses a wrong size or an unknown batch, a fill without all four mirrors or without configure draws nothing, unknown batches answer empty, unknown kinds are remembered and not drawn, the hurt-only rule at its edges (full health, zero, negative, no maximum), the neutral answers for an enemy that is not drawn, the blend, a full archetype batch skipping an enemy while a later one still draws, and for NativePuffs the capacity refusal, oldest-first order and ages, expiry at exactly the lifetime and slots coming back, 150 spawns held at 128, and an unconfigured ring or missing mirror doing nothing.

## Task Commits

1. **Task 1 (tracer): the enemy bodies, flashes and bars in C++**
   - `4d31a82` (refactor) EnemyViews reads its millisecond clock through a set_clock seam
   - `b7f29f6` (test) pin the enemy bodies, flashes, bars and puffs on the GDScript fill before any native enemy-view code
   - `b27e082` (feat) NativeEnemyViews fills the enemy bodies, flashes and hurt-only bars in C++ (not yet wired)
   - `d521b38` (feat) EnemyViews draws its crowd from one native fill per frame, the GDScript loop deleted
2. **Task 2: the puff ring in C++, idle batches stop uploading, native entry tests**
   - `4b1022c` (feat) the death-puff ring runs in C++ and idle batches stop uploading (review IN-08)

**Plan metadata:** the docs commit that carries this file. `plan_head_before` ed8c5c3, `plan_head_after` 4b1022c; `git rev-list --count ed8c5c3..4b1022c` is 5. The commit-order check holds: the clock-seam commit precedes the pin commit, `git log -- tests/unit/test_enemy_fill_pins.gd` is the single commit `b7f29f6`, and `native/src/native_enemy_views.cpp` was first added by the later, different commit `b27e082`.

## Bench: five runs before and five after, with 04-24's baseline beside them

Same arguments throughout (`view_fill_bench.gd`, default warm-up 1440 and 720 timed frames at 1/144 s, headless dummy renderer, script cost only), one run at a time, no other Godot process (`tasklist` checked before each set). The files are git-ignored (`build/bench/`), so this table is their only record. The before enemy set was noisy (612 to 993 us); the median is the third sorted value as the plan reads it.

Enemies before the switch (`build/bench/enemies_before.txt`):

```
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=612.21 p95_us=807.00 max_us=1177.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=956.13 p95_us=1863.00 max_us=4976.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=993.32 p95_us=2095.00 max_us=5291.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=758.89 p95_us=1265.00 max_us=4152.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=696.46 p95_us=975.00 max_us=4031.00 drawn_max=300
```

Enemies after the switch (`build/bench/enemies_after.txt`, the build of `d521b38`):

```
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=89.73 p95_us=150.00 max_us=239.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=72.09 p95_us=114.00 max_us=240.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=90.15 p95_us=153.00 max_us=1536.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=73.12 p95_us=114.00 max_us=214.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=72.38 p95_us=116.00 max_us=222.00 drawn_max=300
```

Enemies on the final build (`4b1022c`: lazy mirror take plus the idle commit skip; an extra set, not the one the bar is read from, `build/bench/enemies_after_final.txt`):

```
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=38.13 p95_us=57.00 max_us=113.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=36.38 p95_us=60.00 max_us=91.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=34.95 p95_us=51.00 max_us=78.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=39.21 p95_us=63.00 max_us=158.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=39.42 p95_us=61.00 max_us=121.00 drawn_max=300
```

Puffs before the switch (`build/bench/puffs_before.txt`):

```
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=166.97 p95_us=289.00 max_us=392.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=140.05 p95_us=211.00 max_us=2575.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=153.00 p95_us=266.00 max_us=554.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=87.52 p95_us=106.00 max_us=136.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=132.90 p95_us=208.00 max_us=277.00 drawn_max=87
```

Puffs after the switch (`build/bench/puffs_after.txt`):

```
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=4.63 p95_us=5.00 max_us=9.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=4.66 p95_us=5.00 max_us=19.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=5.22 p95_us=6.00 max_us=22.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=4.48 p95_us=5.00 max_us=26.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=4.38 p95_us=5.00 max_us=8.00 drawn_max=87
```

04-24's baseline lines (from `04-24-SUMMARY.md`, taken on the unchanged views, three runs each):

```
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=580.01 p95_us=744.00 max_us=2299.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=611.33 p95_us=786.00 max_us=1169.00 drawn_max=300
VIEW_FILL_BENCH view=enemies warmup=1440 frames=720 mean_us=635.83 p95_us=1009.00 max_us=6791.00 drawn_max=300
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=105.79 p95_us=125.00 max_us=166.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=97.76 p95_us=109.00 max_us=196.00 drawn_max=87
VIEW_FILL_BENCH view=puffs warmup=1440 frames=720 mean_us=205.16 p95_us=257.00 max_us=9193.00 drawn_max=87
```

| View | 04-24 baseline median (3 runs) | 04-26 before (5 runs) | 04-26 after (5 runs) | Ratio before/after (bar 3.0) |
|------|-------------------------------|----------------------|---------------------|-----------------------------|
| enemies | 611.33 | 758.89 | 73.12 | **10.38** |
| enemies, final build (extra) | | 758.89 | 38.13 | 19.90 |
| puffs | 105.79 | 140.05 | 4.63 | **30.25** |

One drawn_max across each set of ten lines (enemies 300, puffs 87). The stop rules did not trip. The enemies bench measures script and buffer work only (the dummy renderer draws nothing), so the real-window frame share (about 1.1 ms for the enemy views in 04-24's ablation) and the 8.0 ms p95 budget are judged by plan 04-28's stress runs, not by these ratios.

## Screenshot review (real-window captures; before the port in `build/shots_before_04-26/`, after in `build/shots_after_04-26/`)

Both pairs opened with the Read tool, before against after:

- **crowd_stress_night:** the 300-enemy crowd, the pink flashed grunts at its edge, the red hurt-only bars above the front enemies, the tower arrows, the squad cards, the HUD and the king read as before in the same places; the only differences are enemies a pixel or two apart (the two real-window captures are taken at slightly different wall-clock frames). Nothing missing, doubled, recoloured or mis-sized, and the bars sit over the same enemies.
- **walls_night_breach:** the two red grunts, the king with his health bar, the wall segments, the blue footprint and the HUD are identical to the eye; no puff or flash is on screen in either frame, so this scene confirms the small-crowd and empty-puff-ring case draws as before.

I judge the crowd to read as before. A human-check of the same pairs stays with the phase verifier (coverage D7). The puffs themselves were not on screen in either capture; they are pinned byte for byte by the flood, walls and army runs.

## Replays, gate and suite

Run on the switched tree (after Task 1 and again after Task 2); the Task 2 results:

- smoke: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
- army: `... ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`
- walls: `... ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (all three `--twice --expect-file=tests/golden/<name>.json`, exit 0)
- full_idle: `... ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (`--twice`)
- gate: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a` (`--twice`)
- **Full suite** (`bash tools/test.sh`, 594 s, exit 0): **218 scripts, 2049 tests, 2049 passing, 54229 asserts, all tests passed.** Baseline at dispatch 216 scripts, 2025 tests; this plan adds 24 tests in 2 new scripts (5 pins, 18 native entry tests) plus 1 in `test_crowd_batch`. Lint clean (365 files).

## Files Created/Modified

- `native/src/native_enemy_views.h`, `native/src/native_enemy_views.cpp` - NativeEnemyViews: records, fill, readers, the copied hurt-only rule
- `native/src/native_puffs.h`, `native/src/native_puffs.cpp` - NativePuffs: the ring, spawn, refresh, active_count
- `native/src/native_mirror.h` - `write_origin`
- `native/src/register_types.cpp` - `GDREGISTER_CLASS(NativeEnemyViews)`, `GDREGISTER_CLASS(NativePuffs)`
- `presentation/enemies/enemy_views.gd` - set_clock, `BAR_BATCH`, delegation to NativeEnemyViews; loop, dictionaries, flash helper, id search, drawn mirrors deleted
- `presentation/vfx/death_puff_batch.gd` - delegation to NativePuffs; ring arrays and scans deleted
- `presentation/crowd/crowd_batch.gd` - the idle-commit skip
- `tests/unit/test_enemy_fill_pins.gd` (+ `.gd.uid`) - the four pins, one commit
- `tests/unit/test_native_enemy_views.gd` (+ `.gd.uid`) - 18 entry tests
- `tests/unit/test_crowd_batch.gd` - the idle-upload test

## Decisions Made

See `key-decisions` in the frontmatter. In short: one implementation per view; a fourth pin (the puff flood) because the stress night produces no puffs; the native fill runs before its mirror is handed back; the native classes copy-on-write their mirrors only when they write.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The plan's `commit_buffer(_native.mirror(), _native.refresh(now_s))` hands back a stale mirror**
- **Found during:** Task 2 (first run of the pins and test_death_puff_batch after the puff switch: counts right, origins and ages zero)
- **Issue:** GDScript evaluates arguments left to right, so `_native.mirror()` returned a shared reference to the native array, and the `refresh()` that followed detached (copy-on-write) the native copy it wrote into; the batch received the pre-write array.
- **Fix:** `var written: int = _native.refresh(now_s)` first, then `commit_buffer(_native.mirror(), written)`, with a comment. EnemyViews already ran `fill` before taking the mirrors, so it was not affected.
- **Files modified:** presentation/vfx/death_puff_batch.gd
- **Verification:** the pins (all four runs) and test_death_puff_batch passed unchanged afterwards
- **Committed in:** 4b1022c (part of the Task 2 commit; the buggy form never reached a commit)

**2. [Rule 2 - Missing critical coverage] A fourth pin, the puff flood**
- **Found during:** Task 1 (computing the pins)
- **Issue:** the stress night kills nobody in 2400 frames (and nobody in 4800, tried) so it pins 0 puffs, and the walls and army replays stand at most 3 puffs; neither can reach the ring's cap, refusal, expiry or wrap, which Task 2 ports (T-04-67 asks that the puff batch be pinned before and after).
- **Fix:** a fourth run in `test_enemy_fill_pins.gd` (900 frames on the stress context, never advanced: a few deaths of unknown enemies every frame and one burst of 150, reaching 128 standing); it hashes the same five batches. It is part of the single pin commit; the stress run stays at 2400 frames (it reaches the 300 floor, so no lengthening was needed).
- **Files modified:** tests/unit/test_enemy_fill_pins.gd
- **Verification:** green twice on the GDScript, green unchanged on NativeEnemyViews and on NativePuffs
- **Committed in:** b7f29f6

**3. [Rule 2 - Missing critical functionality] Idle frames no longer copy the shared mirror**
- **Found during:** Task 2 (IN-08 asks idle batches to stop costing)
- **Issue:** a native fill's `ptrw()` detaches the mirror it shares with the batch, a copy of about 150 KB per idle frame for the enemy views and 10 KB for the puffs even though the upload is skipped.
- **Fix:** NativeEnemyViews and NativePuffs take a mirror for writing only when they write its first instance (native_enemy_views.cpp edited in the Task 2 commit although the plan lists it only for Task 1).
- **Verification:** pins, test_enemy_views, test_native_enemy_views green; the extra enemies bench set reads 38.13 us median.
- **Committed in:** 4b1022c

---

**Total deviations:** 3 auto-fixed (1 bug, 2 missing coverage or cost). **Impact on plan:** all within the plan's contract (pins first and unedited, one implementation, no fallback); the plan's literal argument order was wrong for GDScript and is fixed.

## Issues Encountered

- The first enemies before-set was noisy (612 to 993 us, nothing else of mine running); the median of the five is quoted as the plan reads it, and the ratio is far above 3.0 either way (even against the fastest before run, 612.21 vs 73.12 is 8.4x).
- Local compile is MSVC under /W4 /WX only (no gcc here); the C++ was written for GCC's -Wall -Wextra -Werror too (no sign-compare, unused or conversion constructs beyond what NativeArrows already uses), but CI's GCC build of these two new files is first proven by plan 04-27's push.

## Known Stubs

None.

## Threat Flags

None. NativeEnemyViews and NativePuffs are presentation-only: they read the packed enemy read view, take the clock and every hit time as arguments, write only their own state and the batch mirrors, and check every id, size, batch index and layout that crosses from GDScript (T-04-68, covered by `test_native_enemy_views`); T-04-67 is covered by the pins and the replay and gate digests; T-04-69 by the skip applying only when nothing was shown and nothing is held.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for plan 04-27 (the unit view fill, the round's one push): the shape is now proven twice (arrows in 04-25, enemies and puffs here): pins first behind a clock-free seam, `CrowdBatch.mirror()/layout()/commit_buffer()`, `native_mirror.h` (`write_origin` for batches placed with `add`), a native fill that runs before its mirror is handed back. Nothing is pushed; CI compiles the new C++ with GCC for the first time in 04-27. `requirements-completed` stays `[]`: PLAT-01 is decided by plan 04-28 only, which re-measures the full frame against the unchanged 8.0 ms p95 budget and names any halted part (none halted here).

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-20*

## Self-Check: PASSED

- Files exist: native/src/native_enemy_views.h/.cpp, native/src/native_puffs.h/.cpp, native/src/native_mirror.h, tests/unit/test_enemy_fill_pins.gd, tests/unit/test_native_enemy_views.gd, presentation/enemies/enemy_views.gd, presentation/vfx/death_puff_batch.gd, presentation/crowd/crowd_batch.gd.
- Commits exist: 4d31a82, b7f29f6, b27e082, d521b38, 4b1022c (`git rev-list --count ed8c5c3..4b1022c` = 5); the pin file has exactly one commit (b7f29f6), an ancestor of the commit that added native_enemy_views.cpp (b27e082).
- Acceptance criteria re-run: enemy_views.gd holds `_native.fill(`, `commit_buffer(`, `func set_clock(` and every public hook and `const MAX_VIEWS: int = 512`, and none of `func _flash_amount`, `func _find(`, `var _kind_of`, `var _hit_ms`; `var _born` is gone from death_puff_batch.gd; both classes registered; bench arithmetic recomputed from the files (10.38 and 30.25, one drawn_max per set); replays, gate and full suite as recorded above.
