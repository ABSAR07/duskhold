---
phase: 04-crowd-scale-battles-walls
plan: 28
subsystem: performance
tags: [frame-report, stress-night, plat-01, view-ablation, export, playtest-gate, gap-closure]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plans 04-24 to 04-27 (the committed instruments, the baseline before any port, and the arrow, enemy, puff and unit view fills in C++, pushed once and green on CI run 39445109146); plan 04-21's report section and plan 04-09's method
provides:
  - "04-FRAME-REPORT.md: a dated '## After the view-layer port (plans 04-24 to 04-28)' section above the kept native-port and 04-09 sections: verdict MET, median-run p95 5.37 ms against the unchanged 8.0 ms, with FRAME_REPORT_OK and VIEW_ABLATION_OK quoted verbatim"
  - "The residual attributed by the committed probe: all three view loops off now saves 0.22 ms of a 3.78 ms mean frame (3.80 ms before the round)"
  - "A fresh launch-checked export (build/windows/Duskhold.exe plus its DLL), three re-captured screenshots, and a dated update at the top of 04-PLAYTEST-GATE.md for UAT tests 5, 6 and 13 with the native build step"
affects: [04-verification, 04-uat, requirements, phase-13]

actuals:
  tokens: 7160
  tasks: 2
  commits: 2

plan_head_before: 9282d64d92b97063471646cf302a238eb6eae57e
plan_head_after: 059ae7502da254d9faaff290054400cb6f2fd35a

tech-stack:
  added: []
  patterns:
    - "Same instrument before and after: the committed view ablation (plan 04-24) rerun with identical arguments beside its baseline, so the residual is attributed by a probe and not a scratch script"
    - "Headless numbers first, one command at a time, then the real-window runs on a quiet machine (no other Godot process), then the rebuild probe"

key-files:
  created: []
  modified:
    - .planning/phases/04-crowd-scale-battles-walls/04-FRAME-REPORT.md
    - .planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md

key-decisions:
  - "The verdict is met (FRAME_REPORT_OK within=true): G-04-5 and ROADMAP success criterion 3 are closed by measurement and PLAT-01 is marked complete; the stop rule did not apply"
  - "With-step frames are taken as a step of 0.5 ms or more in ctx.advance (the other frames call it without a tick and spend under 0.2 ms), because the histogram has a clean gap there: 603 of 5119 frames in the published run"
  - "The report states what the window run shows about the step (4.5 ms on a step frame against 2.5 ms headless, a session drift not a code change) rather than hiding it"

patterns-established:
  - "A round's closing measurement quotes every upstream plan's own before and after and its own baseline, so the reader can follow one number from the instrument to the verdict"

requirements-completed: [PLAT-01]

coverage:
  - id: D1
    description: "The stress night (300 enemies, 50 units, 237 or more arrows in view, 1080p requested, 1.0x, vsync off, three 20 s runs after a 10 s warm-up) is measured on the native step and the native view fills against the unchanged 8.0 ms median-run p95, and the verdict is committed verbatim"
    requirement: PLAT-01
    verification:
      - kind: integration
        ref: "bash tools/stress.sh --runs=3 --duration=20 -> FRAME_REPORT_OK runs=3 median_run=2 p95_ms=5.37 budget_ms=8.0 within=true enemies=300 units=50 arrows=237 (runs 5.00 / 5.37 / 5.56 ms); grep -qF of the line in 04-FRAME-REPORT.md; BUDGET_P95_MS: float = 8.0 in tools/stress/frame_report.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "The measured code is the proven code: the four replays and the gate digest are unchanged, the attribution probe and the step and view benches ran"
    verification:
      - kind: integration
        ref: "REPLAY_OK smoke 2599c7c2 / army f7a967ed / walls bfb05fc7 (--twice --expect-file) and full_idle 4385f569 (--twice); GATE_OK enemies=300 crossed=300 stuck=0 digest=e448ffdb (--twice); STEP_ATTRIBUTION_OK runs=3 enemies=300 warmup=300 steps=300"
        status: pass
    human_judgment: false
  - id: D3
    description: "The residual frame cost is attributed by the committed view ablation, quoted beside its 04-24 baseline and 04-21's scratch numbers"
    verification:
      - kind: other
        ref: "bash tools/godot.sh --path . --resolution 1920x1080 -s res://tools/stress/view_ablation.gd -- --duration=60 --warmup=10 --run=9 --out=build/stress/ablation -> 12 ABLATION_SLICE, 4 ABLATION_SAVED (all_off 0.22 ms), VIEW_ABLATION_OK trials=2 slice_s=5; quoted in the report"
        status: pass
    human_judgment: false
  - id: D4
    description: "The owner has a fresh, launch-checked export, three re-captured screenshots and a dated update in the gate packet naming UAT tests 5, 6 and 13, the native build step and the measured verdict"
    verification:
      - kind: integration
        ref: "bash tools/export.sh (Export OK, DLL beside the exe); timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 -> exit 0 in about 4 s; bash tools/screenshot.sh crowd_stress_night walls_night_breach overlay_field_gate -> 3 of 3, each non-empty; grep of the update heading, native_build.sh and the FRAME_REPORT_OK line in 04-PLAYTEST-GATE.md"
        status: pass
    human_judgment: false
  - id: D5
    description: "The stress night, the overlay below the night banner and melee enemies breaking through to their targets feel right to the owner (UAT tests 5, 6 and 13)"
    verification: []
    human_judgment: true
    rationale: "Smoothness, legibility and the look of a breakthrough are perceptual; the measurement says smooth on the dev machine, the owner's eye decides, harvested at /gsd-verify-work 4"

duration: 14min
completed: 2026-10-20
status: complete
---

# Phase 4 Plan 28: The stress night after the view-layer port Summary

**The stress night now meets the unchanged 8.0 ms budget: the median-run p95 is 5.37 ms (runs 5.00 / 5.37 / 5.56 ms, 300 enemies, 50 units and 237 or more arrows on screen), down from 10.95 ms after the step port and 37.04 ms before any port, so G-04-5 and ROADMAP success criterion 3 are closed by measurement and PLAT-01 is complete; the committed view ablation shows the three view loops, 3.80 ms of the frame before the round, now cost 0.22 ms.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-20T15:37:31Z
- **Completed:** 2026-10-20T15:52Z
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files modified:** 2 (both planning documents; no code changed)

## Accomplishments

- **The measured code was the proven code.** `bash tools/native_build.sh` printed `NATIVE_BUILD_OK` (HEAD `9282d64`, game code of `e0ecde0`); smoke (703 ticks, 2599c7c2), army (1353, f7a967ed) and walls (1961, bfb05fc7) each `--twice` against `tests/golden/`, full_idle (6911, 4385f569) `--twice`, and `GATE_OK enemies=300 crossed=300 stuck=0 ... digest=e448ffdb...` `--twice`, all exit 0 and unchanged.
- **The verdict, from the real window** (RTX 3060 Laptop, i5-10500H, 1920x1080 requested, vsync off, nothing else running, no Godot process before any real-window run):

  ```
  FRAME_REPORT_OK runs=3 median_run=2 p95_ms=5.37 budget_ms=8.0 within=true enemies=300 units=50 arrows=237
  ```

  Median run: 5119 frames (about 256 fps), p50 3.70 ms, p95 5.37 ms, p99 6.60 ms, mean 3.86 ms, step mean 0.55 ms, render CPU 0.64 ms, GPU 0.77 ms, 230 draw calls. Against 04-21 (p50 6.25, p95 10.95, mean 6.99 ms) and 04-09 (p50 20.92, p95 37.04 ms). Every run has one frame over 16.7 ms and 16 to 23 over 8 ms; the worst run is 2.44 ms under the budget.
- **The headless numbers** (committed attribution probe `STEP_ATTRIBUTION_OK runs=3`: total 2.47, towers 0.63, squads 1.47, enemies 0.46 ms, within drift of 04-21's 2.33; `step_bench` medians 2.51 ms stress shape and 0.99 ms prototype; `view_fill_bench` medians in microseconds: arrows 57.44, enemies 38.97, units 25.23, puffs 6.36, sum 128 against 3631 before any port, 28.4 times lower).
- **The residual attributed by the committed probe.** `view_ablation.gd` rerun with 04-24's arguments: `ABLATION_SAVED` enemy views 0.09, unit views 0.02, projectile VFX 0.10, all off 0.22 ms (04-24 baseline: 1.32, 0.42, 2.13, 3.80 ms; 04-21 scratch: 1.1, 0.5, 2.0, 3.5 ms), and `VIEW_ABLATION_OK trials=2 slice_s=5`. What is left is a floor of about 3.5 ms mean (step, renderer, engine) that the all-off slices always had.
- **Upstream halts: none.** The SUMMARYs of 04-24, 04-25, 04-26 and 04-27 all read `status: complete`; every view fill (arrows, enemies, puffs, units) ran natively in the measurement, and the report says so.
- **Task 2, in full:** `bash tools/export.sh` (Export OK, 34 s, DLL and pck beside the exe), `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exit 0 in about 4 s, three real-window screenshots, and the dated update at the top of 04-PLAYTEST-GATE.md.

## Task Commits

1. **Task 1 (tracer): the stress night after the view-layer port, measured and reported** - `a482e3f` (docs; `04-FRAME-REPORT.md` only; first committed as `3cef4fb`, amended once before anything else touched it to correct the section's timestamp from 15:50Z to the real 15:48Z)
2. **Task 2: export, launch check, screenshots and the owner's re-check update** - `059ae75` (docs; `04-PLAYTEST-GATE.md` only)

**Plan metadata:** the docs commit that carries this file. `plan_head_before` 9282d64, `plan_head_after` 059ae75; `git rev-list --count 9282d64..059ae75` is 2.

## Screenshot review (real-window captures re-taken in Task 2, opened with the Read tool)

- **crowd_stress_night:** the 300-enemy purple crowd funnelling to the gate, pink flashed grunts and red hurt-only bars at its edge, the two rows of towers with their yellow arrows, the blue unit rows at the top edge, the two 25 / 25 squad cards, the king, the Slam slot, the king's bar (99896 / 100000) and the "Night 1 of 1 - 300 enemies left" banner all read as in the earlier plans' captures; nothing missing, doubled, recoloured or mis-sized.
- **walls_night_breach:** the king with his health bar, the two red grunts, the blue footprint, the wall segments (one sunk to rubble) and the HUD are as before; four enemies left, no arrow or puff on screen, so the small-crowd case draws as before.
- **overlay_field_gate:** the F3 panel sits below the night banner, and the banner "Night 1 of 1 - 300 enemies left" reads in full (the UAT test 6 complaint, fixed by plan 04-13); the field arrows, the orange wall crosses and the Perf, Loop, Agents, Wave, King, Paths, Squads, Walls, Field and Crowd rows all read.

I judge the three to look as before the ports; the owner's eye on tests 5, 6 and 13 is the harvested human check.

## Files Created/Modified

- `.planning/phases/04-crowd-scale-battles-walls/04-FRAME-REPORT.md` - the new dated section above the kept native-port and 04-09 sections (verdict first, 229 lines added, nothing removed)
- `.planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md` - the dated update at the top (36 lines added, nothing removed)

## Decisions Made

See `key-decisions` in the frontmatter. In short: the verdict is met so PLAT-01 closes; the step-frame threshold of 0.5 ms comes from the histogram; the in-window step cost (4.5 ms on a step frame) is stated, not hidden.

## Deviations from Plan

None - plan executed exactly as written. (Not deviations: the plan's `<verify>` chain was run as separate commands with their outputs kept under `build/` instead of one `&&` chain, because the real-window runs need the machine quiet and a single chain would not have let me read each result before the next; every check in the chain was run and passed. The Task 1 commit was amended once, before Task 2 and before anything else referenced it, to correct a timestamp I had written ahead of the clock.)

## Issues Encountered

- **The in-window step is slower than the headless one by more than in 04-21.** On the 603 frames of the published run that ran a step the step took 4.53 ms on average (p50 4.09, p95 6.80, max 36.37 ms) against 2.5 ms headless (04-21 read 3.39 ms in the window against 2.33 headless). The headless probe is within 0.15 ms of 04-21, so this is the laptop's session drift or the window run's higher frame rate, not a code change; it is reported in the frame report and does not change the verdict (the p95 is 2.63 ms under the budget in the published run and 2.44 ms under in the worst run). It means the step is now the largest per-frame cost left, which only matters if the owner wants more headroom than 2x on the old-hardware projection.
- **Single-frame spikes remain**: one frame over 16.7 ms per run (18.44, 46.71, 23.70 ms), 0.3 to 0.45 percent of frames over 8 ms. They are above the p99 (6.60 ms) and outside the budget's definition; the report lists them.
- No full test suite, lint or CI run belongs to this plan (only `.planning/` files changed); the code was proven by 04-27's local suite (221 scripts, 2076 of 2076) and CI run 39445109146.

## Known Stubs

None.

## Threat Flags

None. Only two planning documents changed; no endpoint, auth path, file access pattern or schema was added. T-04-73 is mitigated as the plan states (BUDGET_P95_MS checked unchanged at 8.0, the code proven by the four replays and the gate, the earlier sections kept, both verdict lines quoted verbatim, nothing lowered); T-04-74: `export_presets.cfg` was not touched and the exported build launched and quit by itself.

## User Setup Required

None - no external service configuration required. (For the owner, before playing from the editor binary: `bash tools/native_build.sh` in Git Bash; the packet update says so.)

## Next Phase Readiness

PLAT-01's measurement gap is closed: G-04-5 and ROADMAP success criterion 3 hold on the dev machine, and the GTX 970 transfer stays a RESEARCH A1 projection (UAT test 12, blocked by hardware; Phase 13 re-verifies on real campaign battles). Ready for the owner's re-check at `/gsd-verify-work 4` (UAT tests 5, 6 and 13, the packet update at the top of 04-PLAYTEST-GATE.md) and the phase verifier's re-run of the gaps in 04-VERIFICATION.md. Open, not blocking: the wall-break rebuild hitch (test 10, accepted for now, 17.18 ms break-frame estimate).

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-20*

## Self-Check: PASSED

- Files exist: 04-FRAME-REPORT.md and 04-PLAYTEST-GATE.md carry the new sections (`grep -n "^## After the view-layer port"` and `"^## Update after the gap plans 04-12 to 04-28"` hit lines 3 and 3); build/windows/Duskhold.exe, Duskhold.pck, libduskhold_sim.windows.x86_64.dll and the three screenshots exist and are non-empty.
- Commits exist: a482e3f and 059ae75 on `gsd/phase-01-foundation-day-loop`; `git rev-list --count 9282d64..059ae75` = 2; neither commit deletes a file.
- Acceptance re-run: the FRAME_REPORT_OK line (`budget_ms=8.0 within=true`) and the VIEW_ABLATION_OK line are in the report verbatim (`grep -qF`), `BUDGET_P95_MS: float = 8.0` in tools/stress/frame_report.gd, attribution file has the total and squads PHASE lines, the report names every upstream halt (none), and the packet update has the heading, `native_build.sh` and the verbatim FRAME_REPORT_OK line.
