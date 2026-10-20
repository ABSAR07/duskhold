---
phase: 04-crowd-scale-battles-walls
plan: 27
subsystem: presentation
tags: [gdextension, native, cpp, view-port, units, read-view, multimesh, pins-first, ci, gap-closure]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plans 04-25 and 04-26 (CrowdBatch.mirror()/layout()/commit_buffer(), native_mirror.h write_origin, the NativeEnemyViews class shape and the pin harness); plan 04-24 view_fill_bench.gd; plans 04-19/04-20 the change-counted packed read (CrowdReadView) that UnitReadView copies; plan 04-15 gd_math.h
provides:
  - "tests/unit/test_unit_fill_pins.gd: the unit bodies and hurt-only bars pinned on the GDScript fill (stress night, hurt stress night, army replay), one commit, never edited"
  - "UnitReadView (simulation/squads/unit_read_view.gd) and UnitSystem.read_view(): ids ascending, previous and current positions, def slots, the distinct defs, a version refilled only when an id, a position or a def changed; squad_of removed, UnitSystem stays at 20 public methods"
  - "NativeUnitViews (native/src/native_unit_views.h/.cpp): per-unit hit-point records and the whole per-frame fill of unit bodies and hurt-only bars in C++"
  - "UnitViews delegating to it; the GDScript loop, the two hit-point dictionaries, the drawn-id search and the drawn mirrors deleted"
  - "tests/unit/test_native_unit_views.gd: 14 entry tests"
  - "The whole round (plans 04-24 to 04-27) pushed once and green on CI for HEAD e0ecde0 on every job, goldens on both native libraries, the CI export downloaded and launched"
affects: [04-28]

actuals:
  tokens: 15222
  tasks: 2
  commits: 4

plan_head_before: b2cd906a7dcb9048624e3f3ff6dc3981e4d2ccbf
plan_head_after: e0ecde0ad7e7e90107107c52975011c12e490292

tech-stack:
  added: []
  patterns:
    - "A change-counted packed read of a GDScript record store (UnitReadView), refilled by the owner only after a writer ran, read once per frame by the native fill"
    - "Pins first (computed on the GDScript, one commit, never edited), then the native fill must reproduce them unchanged on its first run"
    - "Native per-unit state (max hp, hp) in an id-ordered record vector fed by the unchanged GDScript event handlers; the native fill takes a mirror for writing only when it writes the first instance"

key-files:
  created:
    - simulation/squads/unit_read_view.gd
    - native/src/native_unit_views.h
    - native/src/native_unit_views.cpp
    - tests/unit/test_unit_fill_pins.gd
    - tests/unit/test_unit_read_view.gd
    - tests/unit/test_native_unit_views.gd
  modified:
    - simulation/squads/unit_system.gd
    - native/src/register_types.cpp
    - presentation/units/unit_views.gd

key-decisions:
  - "One implementation shipped: UnitViews keeps its node, baked models, capsule fallback, constants (MAX_VIEWS 256), event handlers and every public hook; every per-unit GDScript body is gone; no runtime fallback"
  - "UnitSystem's read view is refilled in GDScript, only after a writer ran (spawn, remove_dead, begin_step, set_position_of, separate bump _changes); health writers do not, because the view carries no health"
  - "squad_of (no caller anywhere, checked by git grep before deleting) gave up its slot to read_view(), so UnitSystem stays at the gdlint cap of 20 public methods with no new file"
  - "A third pin run (the stress night with the army hit, restored and one unit killed) because the plain stress night hurts nobody (0 bars): only the hurt run pins the bar batch under varying blends"
  - "The two bench sets are read as the plan reads them: the median is the third sorted mean_us of five"

patterns-established:
  - "Bench: five before and five after runs one at a time, medians by sorting mean_us, both medians and the ratio quoted with the ten lines"

requirements-completed: []

coverage:
  - id: D1
    description: "The unit bodies and hurt-only bars are pinned on the GDScript fill before any native unit-view code: stress night (2400 frames, 50 units, 0 bars), hurt stress night (2400 frames, 50 units, 50 bars), army replay (2706 frames, 8 units, 2 bars)"
    verification:
      - kind: unit
        ref: "tests/unit/test_unit_fill_pins.gd (4 tests; one commit e3a5b4a, green twice on the GDScript, green unchanged on NativeUnitViews on its first run and in the full suite and on CI's GCC build)"
        status: pass
    human_judgment: false
  - id: D2
    description: "UnitSystem.read_view() is a read-only, change-counted packed snapshot that agrees with the id API, lists each def once, emits no signal, and leaves UnitSystem at 20 public methods"
    verification:
      - kind: unit
        ref: "tests/unit/test_unit_read_view.gd (9 tests); tests/unit/test_sim_rules_guard.gd; test_squad_lifecycle, test_squad_guard, test_squad_orders"
        status: pass
    human_judgment: false
  - id: D3
    description: "NativeUnitViews fills the unit batches and bars in one native call per frame, byte for byte as the GDScript, at 9.1x (273.88 us to 30.16 us median, bar 2.0)"
    verification:
      - kind: unit
        ref: "tests/unit/test_unit_fill_pins.gd; tests/e2e/test_unit_views.gd; tests/unit/test_native_unit_views.gd (14 tests)"
        status: pass
      - kind: other
        ref: "build/bench/units_before.txt and units_after.txt: medians 273.88 -> 30.16, ratio 9.08, drawn_max 50 on all ten lines"
        status: pass
    human_judgment: false
  - id: D4
    description: "Nothing the round is measured against moved: four replays and the gate digest, locally and on CI (Linux GCC and Windows MSVC)"
    verification:
      - kind: integration
        ref: "REPLAY_OK smoke 2599c7c2 (703) / army f7a967ed (1353) / walls bfb05fc7 (1961) against tests/golden, full_idle 4385f569 (6911) twice; GATE_OK enemies=300 crossed=300 stuck=0 digest=e448ffdb; CI run 39445109146: two REPLAY_OK per scenario and two GATE_OK; full suite 221 scripts, 2076 tests, 2076 passing locally and on CI"
        status: pass
    human_judgment: false
  - id: D5
    description: "CI is green for HEAD on every job and the CI export launches"
    verification:
      - kind: integration
        ref: "gh run 39445109146 (headSha e0ecde0): lint, native-linux, native-windows, test, screenshots, export all success; build/ci-export/Duskhold.exe --headless --quit-after 120 exits 0 in about 3 s with libduskhold_sim.windows.x86_64.dll beside it"
        status: pass
    human_judgment: false
  - id: D6
    description: "The army looks as it did after the port (crowd_stress_night, hud_day_squads, hud_night_squad_down compared before and after; the three CI screenshots)"
    verification: []
    human_judgment: true
    rationale: "A visual comparison of real-window captures; headless Godot reads MultiMeshes back as zeros (RESEARCH F3), so the executor's by-eye review lines below stand in for the harvested human-check at the end of the phase"

duration: 63min
completed: 2026-10-20
status: complete
---

# Phase 4 Plan 27: Units in C++ (the third view port) and the round's push Summary

**UnitViews' per-unit fill (bodies and hurt-only bars) now runs as one NativeUnitViews call per frame over a new packed, change-counted UnitSystem.read_view(), byte for byte equal to the GDScript it replaced (pins computed on the GDScript first, committed alone): the units bench falls from a 273.88 us median to 30.16 us (9.1x, bar 2.0); the whole view-layer round (plans 04-24 to 04-27) went out in one push and CI run 39445109146 is green on every job for HEAD with the four replays and the gate on both the GCC and the MSVC library and the CI export launched here; nothing halted and no CI fix cycle was needed.**

## Performance

- **Duration:** 63 min
- **Started:** 2026-10-20T14:20:16Z
- **Completed:** 2026-10-20T15:23Z (last evidence step; SUMMARY follows)
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files modified:** 13 (6 created and 3 modified code or test files, plus 4 `.gd.uid`)

## Accomplishments

- **Pins on the GDScript fill** (`e3a5b4a`, the only commit that ever touches `test_unit_fill_pins.gd`): three runs, one SHA-256 each over the view and bar counts and, after every frame, the count and whole mirror (stale tail included) of every `Units_<def id>` batch in map order and of `Bars`. Computed on the GDScript, green twice:

  | Run | Frames | Most units | Most bars | Digest |
  |-----|--------|------------|-----------|--------|
  | stress night (300 enemies, 50 footmen, varying blends) | 2400 | 50 (floor 50 met) | 0 | `1a7a6269efd0efd128f3853e34ec2186d523638d64922d754731694eac005220` |
  | hurt stress night (a hit every 6 frames, dawn restores at frames 700 and 1500, one unit killed at 1000) | 2400 | 50 | 50 | `f5d6b012ccf861f8c40d10d41c7d0feaeaf94b88c537709d98180692e339c8c4` |
  | army replay (Barracks and Archery squads) | 2706 | 8 | 2 | `5faf6ada627cc485769592cac440b580c7ce1c1bf041a2fd98a6f2086f2f52ce` |

- **UnitReadView and UnitSystem.read_view()** (`dde69ad`): `ids` (ascending), `previous`, `current`, `def_slots` (index into `defs`), `defs` (the distinct defs, first-seen order), `version`. UnitSystem gained `_changes` and `_view`; spawn, remove_dead (per removed unit), begin_step, set_position_of and separate bump the counter; `read_view()` returns the same object while the version matches and refills it from `_order` and the records otherwise. `squad_of` (no caller anywhere: `git grep -n "squad_of(" -- '*.gd'` listed only its definition, re-run before deleting) is gone, so UnitSystem stays at exactly 20 public functions. `test_unit_read_view` (9 tests), `test_sim_rules_guard`, `test_squad_lifecycle`, `test_squad_guard`, `test_squad_orders`, the pins, the four replays and the gate all held on this commit.
- **NativeUnitViews** (`c681c79` native files, `e0ecde0` the switch): an id-ordered record per known unit (max hp, hit points) fed by the unchanged GDScript handlers, and `fill(blend, ids, previous, current, def_slots, batch_of_def)` that is the GDScript loop line by line (read-view order, the draw cap, `gd::lerp` at a real_t weight, origin `Vector3(ground.x, 0, ground.y)`, `write_origin` with custom (0, 0, 0, 0) into the unit's type batch, the bar at `origin + Vector3(0, 1, 0) * real_t(bar_height)` with the ratio narrowed once into the Color, the hurt-only rule copied from `HealthBar3D.should_show` with its source named). A def slot with no batch (-1, out of range, or a type whose mesh is not ready) skips its unit, as a type with no batch did. The pins, `test_unit_views`, `test_squad_tracer_scene`, `test_selection_model`, `test_native_rules_guard`, `test_projectile_fill_pins` and `test_enemy_fill_pins` all passed on the first native run with no edit to any pin; the four replays and the gate held. The GDScript loop, `_hp_of`, `_max_hp_of`, `_find` and the drawn mirrors were deleted in the same commit as the switch, after the gain was read; the mirror of each type batch is handed to the native fill when the type's batch exists, and handed back with `commit_buffer` after the fill call.
- **Native entry tests** (`e0ecde0`): `tests/unit/test_native_unit_views.gd`, 14 tests: mismatched read-view arrays draw nothing, hit points before a maximum are ignored, 300 units in a 256-capacity batch draw 256 and stop at the cap (the oldest ids), a cap below the capacity stops there, a def slot with batch -1, past the table or past type_count is skipped, a type whose mesh is not ready skips its units, each unit lands in the batch of its def, the blend interpolates, the hurt-only rule at its edges (full health, zero, negative, no maximum), forget_hp and forget, set_mirror and set_bar_mirror refusals, a fill without the bar mirror or without configure, unknown batches answer empty, the neutral answers for a unit that is not drawn.
- **Task 2, the push** (no commit of its own): `bash tools/prepush_check.sh` passed, then exactly `git -c credential.helper= -c "credential.helper=!gh auth git-credential" push origin gsd/phase-01-foundation-day-loop` alone (`b5a6f57..e0ecde0`, carrying plans 04-24 to 04-27 and the earlier `.planning/` docs commits). Run **39445109146** (https://github.com/ABSAR07/duskhold/actions/runs/39445109146, headSha `e0ecde0`, equal to local HEAD) concluded success on the first attempt: **0 fix cycles**. `.github/workflows/ci.yml` was not touched (`permissions: contents: read` present, every `uses:` pinned to a 40-character SHA).

## Task Commits

1. **Task 1 (tracer): the unit bodies and bars in C++ from a packed UnitSystem read view**
   - `e3a5b4a` (test) pin the unit bodies and hurt-only bars on the GDScript fill before any native unit-view code
   - `dde69ad` (feat) UnitSystem.read_view() hands the unit batches a packed, change-counted read (review IN-07)
   - `c681c79` (feat) NativeUnitViews fills the unit bodies and hurt-only bars in C++ (not yet wired)
   - `e0ecde0` (feat) UnitViews draws its army from one native fill per frame, the GDScript loop deleted
2. **Task 2: push and CI** - no commit (a push and evidence only)

**Plan metadata:** the docs commit that carries this file. `plan_head_before` b2cd906, `plan_head_after` e0ecde0; `git rev-list --count b2cd906..e0ecde0` is 4. The commit-order check holds: `git log -- tests/unit/test_unit_fill_pins.gd` is the single commit `e3a5b4a`, older than `dde69ad` (which added `unit_read_view.gd`) and `c681c79` (which added `native_unit_views.cpp`).

## Bench: five runs before and five after, with 04-24's baseline beside them

Same arguments throughout (`view_fill_bench.gd --view=units`, default warm-up 1440 and 720 timed frames at 1/144 s, headless dummy renderer, script cost only; the read-view refill is inside the timed frame whenever the simulation stepped), one run at a time, no other Godot process of mine. The files are git-ignored (`build/bench/`), so this table is their only record. The before set was noisy (221 to 467 us); the median is the third sorted value as the plan reads it.

Units before the switch (`build/bench/units_before.txt`, HEAD `e3a5b4a` plus the native build):

```
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=225.02 p95_us=297.00 max_us=505.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=303.36 p95_us=390.00 max_us=48157.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=221.31 p95_us=274.00 max_us=458.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=273.88 p95_us=438.00 max_us=2938.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=467.39 p95_us=523.00 max_us=32254.00 drawn_max=50
```

Units after the switch (`build/bench/units_after.txt`, the build of `e0ecde0`):

```
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=31.68 p95_us=120.00 max_us=197.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=28.04 p95_us=90.00 max_us=167.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=24.51 p95_us=75.00 max_us=109.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=31.51 p95_us=109.00 max_us=210.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=30.16 p95_us=98.00 max_us=242.00 drawn_max=50
```

04-24's baseline lines (from `04-24-SUMMARY.md`, three runs on the unchanged view):

```
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=177.25 p95_us=206.00 max_us=265.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=161.04 p95_us=188.00 max_us=270.00 drawn_max=50
VIEW_FILL_BENCH view=units warmup=1440 frames=720 mean_us=187.48 p95_us=256.00 max_us=818.00 drawn_max=50
```

| View | 04-24 baseline median (3 runs) | 04-27 before median (5 runs) | 04-27 after median (5 runs) | Ratio before/after (bar 2.0) |
|------|-------------------------------|------------------------------|-----------------------------|------------------------------|
| units | 177.25 | 273.88 | 30.16 | **9.08** |

One drawn_max (50) across all ten lines. Against the fastest before run (221.31) the ratio is still 7.3. The stop rule did not trip. The bench measures script and buffer work only (the dummy renderer draws nothing), so the real-window share (about 0.5 ms of mean frame in 04-24's ablation) and the 8.0 ms p95 budget are judged by plan 04-28.

## Screenshot review (real-window captures; before the port in `build/shots_before_04-27/`, after in `build/shots_after_04-27/`)

All three pairs opened with the Read tool, before against after:

- **crowd_stress_night:** the 300-enemy crowd, the pink flashed grunts, the red hurt-only bars over the front enemies, the blue unit rows at the top edge, the towers' arrows, the squad cards, the HUD and the king are in the same places; the only differences are a few enemies a pixel or two apart (two real-window captures a few wall-clock frames apart). Nothing missing, doubled, recoloured or mis-sized.
- **hud_day_squads:** the four footmen with their selection rings on the left, the four archers on the right, the castle, the king, the squad cards (4 / 4 each) and the order-hotkey row are identical to the eye.
- **hud_night_squad_down:** the castle, the king with its bar, the red hurt-only bars over the castle's towers and the enemy, the squad cards (footmen 0 / 4, archers 3 / 4), the archers far right and the king's cyan ghost read as before; the only difference is two purple enemy arrows a few pixels apart (timing between captures).

CI screenshots (`build/ci-screenshots/screenshots/`, Compatibility renderer on a software GL stack, so slightly different shading, from the run for HEAD):

- **crowd_stress_night (CI):** the crowd, flashed grunts, bars, blue unit rows, arrows and cards all drawn; no missing batch.
- **overlay_field_gate (CI):** the debug overlay over the stress gate with "Drawn units: 0" (that scene fields no army), the flow arrows, the wall and the crowd below it; nothing unit-related is missing.
- **hud_night_squad_down (CI):** the same scene as the local capture (castle, king ghost, squad cards 0 / 4 and 3 / 4, hurt-only bars), drawn correctly.

I judge the army to read as before. A human-check of the same pairs stays with the phase verifier (coverage D6).

## Replays, gate, suite and CI

Local, on the switched tree (`e0ecde0`):

- smoke: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
- army: `... ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`
- walls: `... ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (all three `--twice --expect-file=tests/golden/<name>.json`)
- full_idle: `... ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (`--twice`)
- gate: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a` (`--twice`)
- **Full suite** (`bash tools/test.sh`, 602 s, exit 0): **221 scripts, 2076 tests, 2076 passing, 54978 asserts, all tests passed.** Baseline at dispatch 218 scripts, 2049 tests; this plan adds 27 tests in 3 new scripts (4 pins, 9 read-view tests, 14 native entry tests). Lint clean (369 files).

CI run 39445109146, every job success (job durations from the run): lint 36 s, native-linux 4 min 44 s, native-windows 9 min 36 s, test 8 min 8 s (Linux, GCC library, 221 scripts, 2076 of 2076 passing, so the three view pin files and the unit entry tests ran on the GCC build), screenshots 2 min 33 s, export 28 s; the run took about 15 min 30 s end to end. `build/ci-run.log` holds two REPLAY_OK lines for each of smoke, army, walls and full_idle (Windows job "Seeded replay determinism (Windows)" and Linux job "Seeded replay determinism", every digest identical to the local ones above) and two `GATE_OK enemies=300 crossed=300 stuck=0 ... digest=e448ffdb...` lines (Windows and Linux). `gh run download 39445109146 -n duskhold-windows -D build/ci-export` gave `Duskhold.exe`, `Duskhold.pck` and `libduskhold_sim.windows.x86_64.dll`; `timeout 90 build/ci-export/Duskhold.exe --headless --quit-after 120` launched and quit with exit 0 in about 3 s. The only runner annotation is GitHub's notice that the `ubuntu-latest` label migrates to Ubuntu 26 from 2026-10-19 (the runner for this run still built and passed everything).

## Files Created/Modified

- `native/src/native_unit_views.h`, `native/src/native_unit_views.cpp` - NativeUnitViews: records, fill, readers, the copied hurt-only rule
- `native/src/register_types.cpp` - `GDREGISTER_CLASS(NativeUnitViews)`
- `simulation/squads/unit_read_view.gd` (+ `.gd.uid`) - UnitReadView, the packed unit snapshot
- `simulation/squads/unit_system.gd` - `_changes`, `_view`, `read_view()`, change bumps in the five writers; `squad_of` removed
- `presentation/units/unit_views.gd` - delegation to NativeUnitViews; loop, dictionaries, id search, drawn mirrors deleted
- `tests/unit/test_unit_fill_pins.gd` (+ `.gd.uid`) - the three pins, one commit
- `tests/unit/test_unit_read_view.gd` (+ `.gd.uid`) - 9 tests
- `tests/unit/test_native_unit_views.gd` (+ `.gd.uid`) - 14 entry tests

## Decisions Made

See `key-decisions` in the frontmatter. In short: one implementation, no fallback; the read view refilled in GDScript only after a writer ran and not for health writes; `squad_of` gave up its slot; a third (hurt) pin run so the bar batch is pinned; the native fill takes each mirror for writing only when it writes the first instance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical coverage] A third pin run, the hurt stress night**
- **Found during:** Task 1 (computing the pins)
- **Issue:** the plan asks the pins to cover the bars on the stress shape and the army replay, but the stress night hurts none of the 50 footmen in 2400 frames (most_bars 0) and the army replay shows at most 2 bars; neither exercises the bar batch against many hurt units, restores, deaths and varying blends.
- **Fix:** a third run in `test_unit_fill_pins.gd`: the stress night with a hit every 6 frames, the dawn restore at frames 700 and 1500 and one unit killed at frame 1000 (all through public SquadSystem calls, no randomness), 50 bars at most; it hashes the same batches. It is part of the single pin commit.
- **Files modified:** tests/unit/test_unit_fill_pins.gd
- **Verification:** green twice on the GDScript, green unchanged on NativeUnitViews and on CI's GCC build
- **Committed in:** e3a5b4a

---

**Total deviations:** 1 auto-fixed (missing coverage). **Impact on plan:** within the plan's contract (pins first and unedited, one implementation, no fallback); the extra run only makes the bar pin stronger.

## Issues Encountered

- The first units before-set was noisy (221 to 467 us, two runs carried a 32 to 48 ms single-frame spike); the median of the five is quoted as the plan reads it, and the ratio is far above 2.0 either way.
- Local compile is MSVC under /W4 /WX only (no gcc here); the C++ was written for GCC's -Wall -Wextra -Werror too and CI's GCC build of `native_unit_views.cpp` passed on the first push (the native-linux job and the Linux test job are green).
- The machine has no usable Python (`python3` is the Microsoft Store shim); the pin and test edits were made with the Edit tool and sed instead.

## Known Stubs

None.

## Threat Flags

None. NativeUnitViews and UnitReadView are presentation-only reads: the read view is a copy refilled from the records and never written back (T-04-70, covered by the pins, `test_unit_read_view`, `test_sim_rules_guard`, the four replays, the gate digest and CI's Linux and Windows replays); every id, size, def slot and batch index that crosses from GDScript is checked in C++ (T-04-71, covered by `test_native_unit_views`, including 300 units into a 256 cap); the push followed prepush_check and the one credential-helper command, `gh` was used only in Task 2 and `ci.yml` is unchanged (T-04-72).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for plan 04-28 (the measurement): every per-frame view fill of the night now runs natively from a packed read (arrows 04-25, enemies and puffs 04-26, units here), none halted, and the whole round is on origin and green on both native libraries. `requirements-completed` stays `[]`: PLAT-01 is decided by plan 04-28 only, which re-measures the full frame against the unchanged 8.0 ms p95 budget.

## Self-Check: PASSED

Files created exist (`unit_read_view.gd`, `native_unit_views.h/.cpp`, the three test scripts and their `.gd.uid`); commits `e3a5b4a`, `dde69ad`, `c681c79` and `e0ecde0` are on the branch and on origin; the commit-order check (single pin commit older than the read-view and native commits), the 20-method cap (`grep -cE '^(static )?func [a-z]'` = 20), the deletion greps (`var _hp_of`, `func _find(`, `func squad_of` absent), `GDREGISTER_CLASS(NativeUnitViews)`, the bench ratio (9.08), the single drawn_max, the full suite (2076 of 2076), lint, the four replays, the gate, the CI run for HEAD (success on every job, two REPLAY_OK per scenario and two GATE_OK) and the export launch all pass.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-20*
