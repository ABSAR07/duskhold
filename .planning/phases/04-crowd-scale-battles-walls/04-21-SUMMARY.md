---
phase: 04-crowd-scale-battles-walls
plan: 21
subsystem: performance-measurement
tags: [plat-01, frame-budget, stress-night, step-attribution, view-layer, stop-rule, halted]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plans 04-15 to 04-20, 04-22 and 04-23 (the native port of the whole simulation step, CI run 39310876191 green), 04-09 (the method, the 8.0 ms budget and the before numbers), 04-13 (the overlay fix the owner re-judges)
provides:
  - "04-FRAME-REPORT.md: a dated '## After the native port' section above the kept 04-09 measurement: median-run p95 10.95 ms against the unchanged 8.0 ms budget, NOT met, with all runs, counts, the committed attribution probe's VARIANT and PHASE lines, per-plan bench medians, the wall-break rebuild line and the RESEARCH A1 projection"
  - "A real-window ablation of the three view _process loops showing the remaining miss is the presentation layer (about 3.5 ms of the mean frame), not the step: with the three off the whole night's p95 is 4.55 ms"
affects: [04-VERIFICATION gap G-04-5, ROADMAP success criterion 3, PLAT-01, the next gap plan the owner chooses]

actuals:
  tokens: 4200
  tasks: 1
  commits: 1

plan_head_before: a32e65f7bb3e6822d5922002a516cbf10dbb39e4
plan_head_after: 9f896662ab673d289e7347bbc4bbef382948411a

tech-stack:
  added: []
  patterns:
    - "Same-instrument re-measurement: the 04-09 method, hardware, budget and stress tools unchanged, so the before and after tables are directly comparable"
    - "Split the frame time by whether a frame ran a step (step_ms above 0.1 in run_<n>.json) before blaming the step: here both halves read p50 6.25 ms"
    - "Per-node set_process(false) ablation from a SceneTree wrapper script, in a real window, to attribute main-thread script time that the headless probe cannot see"

key-files:
  created: []
  modified:
    - .planning/phases/04-crowd-scale-battles-walls/04-FRAME-REPORT.md

key-decisions:
  - "Stop rule applied: within=false, so the NOT met verdict is committed with the numbers, nothing is lowered or raised, and the plan ends halted; Task 2 (export, screenshots, gate-packet update) was not run"
  - "The next candidate named first is the view layers' per-frame loops (ProjectileVfx, EnemyViews, UnitViews), not the squad per-unit port the plan's rule names when squads lead the step attribution, because the real-window numbers show the step is no longer what sets the p95; the squad port stays second"
  - "PLAT-01 stays Pending in REQUIREMENTS.md and requirements-completed is empty"

requirements-completed: []

coverage:
  - id: D1
    description: "The stress night is re-measured in a real window on the native step with the 04-09 method against the unchanged 8.0 ms budget, the measured code first proven by the four replays and the gate, and the result committed as a dated section of 04-FRAME-REPORT.md (honest miss: p95 10.95 ms, NOT met)"
    requirement: PLAT-01
    verification:
      - kind: integration
        ref: "bash tools/stress.sh --runs=3 --duration=20 -> FRAME_REPORT_OK runs=3 median_run=2 p95_ms=10.95 budget_ms=8.0 within=false enemies=300 units=50 arrows=239; four replays and bash tools/gate_stress.sh --twice unchanged; tools/stress/frame_report.gd still BUDGET_P95_MS: float = 8.0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The ROADMAP success criterion 3 gap (G-04-5, PLAT-01: 60 fps, 8.0 ms p95 on the dev machine at the largest battle) is closed"
    requirement: PLAT-01
    verification:
      - kind: integration
        ref: "FRAME_REPORT_OK ... within=false"
        status: fail
    human_judgment: true
    rationale: "The budget is missed (10.95 ms against 8.0 ms); the owner chooses the next route on the numbers, and the stress-night feel (UAT test 5) is theirs to judge"
  - id: D3
    description: "The owner's fresh launch-checked export, three re-captured screenshots and the dated re-check list at the top of 04-PLAYTEST-GATE.md"
    verification: []
    human_judgment: true
    rationale: "Task 2 was not run: the plan's stop rule ends the plan after the committed NOT met report; the export and the packet update are cheap to run once the owner has chosen a route"

duration: 11min
completed: 2026-10-19
status: halted
---

# Phase 4 Plan 21: The Stress Night on the Native Step, Re-Measured Summary

**The native port took the real-window stress night from a median-run p95 of 37.04 ms (43 fps) to 10.95 ms (about 142 fps) with the full 300 / 50 / 239 crowd on screen, but the unchanged 8.0 ms budget is still NOT met, and a real-window ablation shows the remaining 3.5 ms of mean frame time is the three view layers' per-frame GDScript loops (arrows first), not the 2.3 ms simulation step; plan halted by its stop rule with nothing lowered.**

## Performance

- **Duration:** 11 min (2026-10-19T19:45:19Z to about 19:56Z; the four replays, the gate, the attribution probe, eleven bench runs, the three 20 s real-window runs, two 40 s ablation trials)
- **Tasks:** 1 of 2 executed (Task 1 tracer); Task 2 not run by the stop rule
- **Files modified:** 1 (04-FRAME-REPORT.md); 1 plan commit
- **Tracer feedback gate:** Task 1's verify is automated-only under `end-of-phase`; every automated link passed except `within=true`, which the acceptance criteria exempt under the stop rule (`within=false` with the NOT met verdict committed), so the plan stops before expansion rather than expanding.

## Accomplishments

- **Measured code proven first.** `bash tools/native_build.sh` (NATIVE_BUILD_OK), then `smoke` 2599c7c2 (703 ticks), `army` f7a967ed (1353), `walls` bfb05fc7 (1961), `full_idle` 4385f569 (6911), each `--twice`, and `GATE_OK enemies=300 crossed=300 stuck=0 ... digest=e448ffdb...`: all unchanged against the owner's D-14 pins.
- **Attribution rerun before the real-window runs**, with the committed probe exactly as the plan gave: `PHASE total ms=2.33`, `towers 0.49`, `squads 1.34`, `enemies 0.48`, `rest 0.02`, `STEP_ATTRIBUTION_OK runs=3 enemies=300 warmup=300 steps=300` (04-09's profile read 22.2 ms total). Five stress-shape bench lines 2.47, 2.37, 2.49, 2.38, 2.52 ms (median 2.47) and five prototype lines 0.91, 1.17, 0.95, 0.97, 0.96 ms (median 0.96); `--rebuilds=16` read `mean_ms=10.00 max_ms=11.74`.
- **The real-window stress night, three 20 s runs** (`bash tools/stress.sh --runs=3 --duration=20`, 1920x1080 requested, vsync off, 1.0x): p95 10.88, 10.95 and 11.11 ms (2.1 percent spread), p50 6.25 ms, 2838 frames in the median run, render CPU 0.45 ms, GPU 1.21 ms, 230 draw calls, minimum on-screen 300 enemies, 50 units, 239 arrows. The line, verbatim: `FRAME_REPORT_OK runs=3 median_run=2 p95_ms=10.95 budget_ms=8.0 within=false enemies=300 units=50 arrows=239`.
- **The finding that changes the next step.** In the run data a frame that ran a simulation step (21 percent of frames, step 3.39 ms mean) has the same frame time as one that did not (p50 6.25 ms both; p95 11.11 and 10.61 ms). A scratch real-window probe that switched the `_process` of `ProjectileVfx`, `EnemyViews` and `UnitViews` off and on in 5 s slices (two trials) read: all on p95 11.32 and 10.43 ms; arrows off about 2.0 ms less mean frame; enemy views off about 1.1 ms less; unit views off about 0.5 ms less; all three off **p95 4.55 ms in both trials**, under the budget with the step and the renderer included. The step port is done; the budget is now a presentation cost.
- **Report.** 04-FRAME-REPORT.md opens with `## After the native port (plans 04-12 to 04-23), 2026-10-19T19:54Z`: verdict first with the line above, before/after table, all runs, counts, the attribution table (04-09 profile, 04-20 probe, this run), per-plan bench medians (04-15 39.37 to 28.75 ms ... 04-19 17.88 to 4.58, 04-20 4.58 to 2.18, now 2.47), the view-layer finding, the wall-break rebuild (break-frame estimate 6.25 + 11.74 = 17.99 ms, the hitch the owner accepted for now), the RESEARCH A1 projection (p50 8.1 to 10.0 ms, p95 14.2 to 17.5 ms on a GTX 970-class machine, a projection) and the next candidates. The 04-09 measurement is intact below under `## Before the native port: the plan 04-09 measurement`.

## Next candidates and the proposal for the owner

The plan's rule says to propose the squad per-unit port when squads are the largest remaining phase. They are, headless (1.34 ms of 2.33 ms). But the real-window numbers say that port alone cannot close the gap: frames without a step already sit at a 10.6 ms p95, and the squad port can take at most about 1.3 ms off the 21 percent of frames that step. The recommendation, in order:

1. **A gap plan for the view layers' per-frame loops** (`ProjectileVfx._process` about 2.0 ms of mean frame, `EnemyViews._process` about 1.1 ms, `UnitViews._process` about 0.5 ms): port the multimesh fills to C++ over the already packed read view, and animate arrows from origin, target and launch time on the GPU or in a native batch. No rule changes and no digest can move (the views only read); the drawn result is checked by screenshot against the current ones. With the loops off the p95 is 4.55 ms.
2. **The squad per-unit port** second (orders, slot walks, goal-field walks; 1.34 ms headless).
3. Towers (0.49 ms) and the enemy step with the stuck tracker (0.48 ms) are not worth a port at this size.

No plan was written; the owner decides the route on these numbers.

## Task Commits

1. **Task 1 (tracer): the report** - `9f89666` (docs) - `04-FRAME-REPORT.md`
2. **Task 2: not run** (stop rule; see Deviations)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md. PLAT-01 stays Pending in REQUIREMENTS.md.

## Files Created/Modified

- `.planning/phases/04-crowd-scale-battles-walls/04-FRAME-REPORT.md` - the new dated section above the kept 04-09 measurement
- `.planning/phases/04-crowd-scale-battles-walls/04-21-SUMMARY.md` - this file
- Evidence outside git: build/stress/{run_1,run_2,run_3,report}.json, report.md, stress.log; build/bench/attribution.txt and final.txt; the scratch ablation probe (`view_ablation.gd`, in the executor's scratch directory, never committed, like the 04-09 profile)

## Decisions Made

- The stop rule is the plan's documented honest outcome: committed the NOT met report, changed nothing else (no budget, load or fidelity change; `BUDGET_P95_MS: float = 8.0` verified), halted.
- Named the view layers as the first next candidate ahead of the squad port the plan's rule would suggest, on the strength of the step-frame / non-step-frame split and the ablation; the squad port stays as the second candidate. This is a recommendation, not a plan.
- Left PLAT-01 Pending and `requirements-completed` empty; no `requirements.mark-complete`.

## Deviations from Plan

**1. [Stop rule, plan step 5] Task 2 was not executed.**
- **Found during:** Task 1, after FRAME_REPORT_OK read `within=false`.
- **Issue:** The plan's step 5 says to commit the report "and end the plan here with the SUMMARY status halted". The export, the three screenshots and the 04-PLAYTEST-GATE.md update (Task 2) therefore did not run.
- **Reason:** A fresh export and a re-check list written now would describe a build the owner is about to be asked to change (the next gap plan), and the stop rule says to end the plan; Task 2 is cheap (about 5 minutes: `bash tools/export.sh`, the launch check, `bash tools/screenshot.sh crowd_stress_night walls_night_breach overlay_field_gate`, the dated section) and can be run as soon as the owner has chosen a route, or at once if they want it before deciding.
- **04-PLAYTEST-GATE.md** therefore still carries the 37.04 ms numbers at its top; the current figures are in 04-FRAME-REPORT.md.

**2. [Extra evidence, no rule] A scratch real-window ablation probe was run beyond the plan's list.**
- **Why:** the step/non-step split of the run data contradicted the plan's expectation that the step is the remaining cost; the owner needs to know that before choosing the squad port. It uses `Node.set_process(false)` on three view nodes of a StressNight instance from a `SceneTree` script, writes nothing but stdout, touches no committed file, and is described in the report. Two trials are reported.

**Total deviations:** 1 stop-rule outcome (Task 2 not run), 1 extra measurement. **Impact:** none on code, digests or the budget; PLAT-01 stays open with sharper numbers than the plan asked for.

## Authentication Gates

None.

## Issues Encountered

- The first draft of the scratch probe failed to parse (`_set` overrides the engine's `Object._set`; an untyped `for` iterator under warnings-as-errors); renamed and typed before any run. No other problems: no hung processes, nothing else was running during the real-window runs.
- The ablation's `Performance.TIME_PROCESS` column read implausibly (10 to 20 ms against 3.6 to 7.5 ms frames) and was discarded; only frame deltas are reported.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. No file, network, input or scene surface was added; T-04-56 (the budget and its evidence) is mitigated: `BUDGET_P95_MS` checked unchanged at 8.0, the measured code proven by the four replays and the gate, the 04-09 numbers kept as the before, and the miss reported rather than hidden. T-04-57 (the export) does not apply because no export was made.

## Next Phase Readiness

Phase 4 is not ready to close: ROADMAP success criterion 3 (PLAT-01) is unmet by 2.95 ms of p95 on the dev machine, and Task 2's owner re-check list is outstanding. The orchestrator should take the numbers to the owner and ask for the route: a view-layer gap plan (recommended), the squad port, or a decision on the budget. The measured gap is small enough (p95 10.95 ms; 4.55 ms with the view loops off) that one targeted plan should be able to close it.

## Self-Check: PASSED

- `04-FRAME-REPORT.md` exists and contains `## After the native port` and the verbatim FRAME_REPORT_OK line (`grep -F` of the stress.log line, carriage returns stripped: found); `tools/stress/frame_report.gd` still has `BUDGET_P95_MS: float = 8.0`; `build/stress/stress.log` has the line with `budget_ms=8.0`; `build/bench/attribution.txt` contains `STEP_ATTRIBUTION_OK runs=3`, `PHASE enemies`, `PHASE squads` and `PHASE total`, and was written before the stress runs.
- Commit `9f89666` exists (`git rev-list --count a32e65f..9f89666` is 1); it adds only 04-FRAME-REPORT.md (170 insertions, no deletions).
- PLAT-01 is still `Pending` in REQUIREMENTS.md; the four replays and the gate digests are as pinned.
