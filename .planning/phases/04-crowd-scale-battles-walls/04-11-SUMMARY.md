---
phase: 04-crowd-scale-battles-walls
plan: 11
subsystem: phase-gate
tags: [godot, gate, ci, export, playtest-packet, walls, stress, tracer]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: the walls, the crowd views, the stress night and gate stress (04-01 to 04-08), the frame report with PLAT-01 recorded not met (04-09, halted), the walls golden and the balance with walls (04-10)
provides:
  - One local end-to-end pass of the whole phase (suite, four goldens, gate stress, 37 screenshots in a real window) with Claude's review of 15 shots
  - A green CI run for HEAD a8c57ab on lint, test, export and screenshots, first push, with the walls golden, the gate stress and 37 screenshots
  - A launch-checked Windows export
  - 04-PLAYTEST-GATE.md, the owner's packet: PLAT-01 stated as NOT met, 25 numbered assumptions, the open decisions
affects: [/gsd-verify-work 4, the owner's performance route decision, Phase 5]

actuals:
  tokens: 6500
  tasks: 3
  commits: 1

plan_head_before: a8c57ab436696b0b1b0df48c0b614574efa568f6
plan_head_after: ff6df66d742a6e9d8f258830cc0a33fc97e5fdfc

tech-stack:
  added: []
  patterns:
    - "A gate plan that changes no code when its review finds nothing to fix: the evidence is the sentinel lines, the review lines and the packet"

key-files:
  created:
    - .planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md
  modified: []

key-decisions:
  - "No presentation fix was needed: the review of the 15 shots found no readability problem inside the four fix sites, so Task 1 made no commit; open readability points (thin palisade, long shadows, dark night ground, small enemies from the stress camera) go to the packet and Phase 8 (UI-05)"
  - "The packet states PLAT-01 and ROADMAP success criterion 3 as NOT met (median-run p95 37.04 ms vs 8.0 ms, about 43 fps at 300 enemies), lists the three owner options and the wall-break rebuild hitch (11.74 ms mean, 13.22 ms max, time slicing as the open point), and records that the owner chose to run the gate on the missed budget"
  - "PLAT-01 is not marked complete in REQUIREMENTS.md: requirements-completed lists BLDG-10 and ENMY-04 only"

patterns-established: []

requirements-completed: [BLDG-10, ENMY-04]

coverage:
  - id: D1
    description: "The whole phase checks out locally in one pass: suite, smoke, army, walls and full_idle replays, the gate stress and 37 non-blank screenshots"
    requirement: ENMY-04
    verification:
      - kind: e2e
        ref: "bash tools/test.sh (190 scripts, 1794 tests, all passing, exit 0)"
        status: pass
      - kind: e2e
        ref: "bash tools/replay.sh --scenario=<smoke|army|walls> --twice --expect-file=tests/golden/<name>.json and --scenario=full_idle --twice (REPLAY_OK x4)"
        status: pass
      - kind: e2e
        ref: "bash tools/gate_stress.sh --twice (GATE_OK enemies=300 crossed=300 stuck=0)"
        status: pass
      - kind: automated_ui
        ref: "bash tools/screenshot.sh (37 PNGs, exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CI is green for HEAD a8c57ab on lint, test, export and screenshots, with REPLAY_OK for smoke, army, walls and full_idle, the GATE_OK line and 37 screenshots"
    requirement: BLDG-10
    verification:
      - kind: e2e
        ref: "https://github.com/ABSAR07/duskhold/actions/runs/38959046206 (success)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A launch-checked Windows export and the owner's gate packet"
    requirement: PLAT-01
    verification:
      - kind: e2e
        ref: "bash tools/export.sh; timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 (exit 0 in about 3 s)"
        status: pass
    human_judgment: true
    rationale: "The owner's Phase 4 gate: whether walls are worth their gold and read by tier, whether the gates funnel enemies into the towers, whether break-or-detour looks smart, whether squads and the king get round walls, whether the stress night feels smooth. PLAT-01 is NOT met on the measured numbers; the performance route is the owner's decision."
  - id: D4
    description: "PLAT-01 (hundreds of units at 60 fps) is not met"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: ".planning/phases/04-crowd-scale-battles-walls/04-FRAME-REPORT.md (median-run p95 37.04 ms vs 8.0 ms)"
        status: fail
    human_judgment: true
    rationale: "Recorded as not met by plan 04-09 (halted); the owner chose to run the gate on the missed budget and will decide the route (GDExtension, a documented higher budget, or an optimisation plan)."

duration: 40 min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 11: The Phase 4 Gate Summary

**The whole phase passes one local pass and a first-push CI run with every job green (190 scripts, 1794 tests, four replay digests, GATE_OK 300 of 300 crossed, 37 screenshots), a launch-checked export exists, and the owner's packet states plainly that PLAT-01 is not met (p95 37.04 ms against 8.0 ms) and lists 25 assumptions and the open decisions**

## Performance

- **Duration:** 40 min
- **Started:** 2026-10-16T19:37:20Z
- **Completed:** 2026-10-16T20:17:10Z
- **Tasks:** 3 (Task 1 the tracer; Tasks 2 and 3 auto)
- **Files modified:** 1 created (the packet); no code changed

## Accomplishments

- Task 1 (tracer): the whole phase verified in one local pass, with the sentinel lines below; the 15 named screenshots reviewed in a real window; nothing needed fixing, so there is no Task 1 commit. Tracer verified end to end, expansion followed.
- Task 2: pushed `3c8f69e..a8c57ab` with the permitted command after `bash tools/prepush_check.sh` passed; CI run 38959046206 went green on the first push (no fix cycle, `ci.yml` untouched).
- Task 3: fresh export, launch check, and `04-PLAYTEST-GATE.md` (commit `ff6df66`).

### Sentinel lines (local, Task 1)

```
bash tools/test.sh:   Scripts 190, Tests 1794, Passing Tests 1794, Asserts 27553, Time 764.939s, exit 0
                      (the dispatch baseline read 27554 asserts; one assert fewer in a timing-dependent loop, every test passing)
bash tools/lint.sh:   334 files would be left unchanged / Success: no problems found (exit 0)
REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f
REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4
REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58
REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf
GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a
bash tools/screenshot.sh: exit 0 in 5 min 40 s, 37 PNGs (the 37 names of ALL_SHOTS), none under 2 kB
```

The full_idle digest is the post-04-10 one (`4385f569...`, 6911 ticks); the older `f417c7f5...` (6941 ticks) the plan text may still quote was superseded by the D-14 regeneration commit `94fff12`. smoke and army equal their goldens, walls equals `tests/golden/walls.json`.

### CI (Task 2)

- Run: https://github.com/ABSAR07/duskhold/actions/runs/38959046206, head `a8c57ab436696b0b1b0df48c0b614574efa568f6`, conclusion `success`; jobs lint (1 min), test (10 min), export (30 s) and screenshots (3.5 min) all `success`.
- Its log carries `REPLAY_OK` for smoke, army, walls and full_idle with the same four digests as the local pass, and `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0` with the same digest as the local run. The Task 2 `<automated>` verify returned VERIFY_OK (37 PNGs in `build/ci-screenshots`, `contents: read` still in ci.yml).
- The CI Phase 4 shots (Mesa software GL, Compatibility, flatter and lighter than the local Forward+ ones, as expected):
  - `walls_day`: the same scene as local with a lighter green ground; both palisade halves, the "Wall II / 12 segments, 60 health each" label, the king and the plot read.
  - `walls_night_breach`: the dark rubble at the foot of the south half, two red grunts and the king read; slightly flatter blue night.
  - `overlay_field_gate`: the field arrows, the overlay panel and the purple crowd at the gate read; the overlay's FPS and frame-ms rows read 11 and 1712 ms (software rendering of the 300-enemy scene), which is the CI renderer and not the budget.
  - `crowd_stress_night`: the 300 purple enemies, the towers with yellow arrows, two squads of 25 and the gate gap all read, as locally.

### Review of the 15 local shots (Task 1 step 2; Forward+ on the RTX 3060 Laptop)

- `walls_day`: day 1 at a wall plot, two thin brown palisade runs either side of the gap, long dark shadows, the king in the plot with "Wall II / 12 segments, 60 health each" readable above him, a red "5" spawn marker; the wall and gap read clearly, the segments are thin from this camera.
- `walls_night_breach`: night 1, 4 enemies left, a segment sunk to dark grey rubble at the foot of the south half, two red grunts near the king; the breach reads, the palisade is low contrast against the dark night ground (for the owner and Phase 8).
- `overlay_field_gate`: F3 overlay (Walls: runs built 1, segments intact 26, field version 1, Crowd 300 drawn) with white-blue field arrows all pointing to the gate gap and 300 purple enemies bunched south of the wall; the arrows and the gap read, the panel covers the right half of the wall (by design).
- `crowd_stress_night`: 300 enemies funnelled to the 4 m gate under 20 towers with yellow arrows in the air and two squads of 25 (blue) at the top; the crowd reads as a mass and the gate as a gap, individual enemies are small from the 119.5 m stress camera.
- `night_combat`: night 5, a red grunt, two violet skirmishers, pale-red puffs, a violet arrow, the yellow slam bar by the tower; clear.
- `building_destroyed`: night 3, grunts round the king (18 / 50), rubble plot, "+14 gold"; clear.
- `king_down_countdown`: night 7, "Knocked out, back in 6 s", cyan ghost king among puffs, gold arrow stack at the tower, stone-tier wall run (pink and grey blocks) reads very clearly; no overlap problem.
- `overlay_paths`: grunt, puffs, F3 panel and a path line intact; the panel shows the state from before the shot's fast-forward (Day, gold 30, 0 enemies) beside the night banner, because the overlay refreshes every 0.25 s (`REFRESH_INTERVAL_S`) and the capture follows the scripted fast-forward within frames; a property of the shot, not a game defect.
- `results_defeat`: dimmed field, "Defeat" panel with the four stat rows and Play again / Quit; unchanged.
- `hud_night_squad_down`: night 7, castle, a violet pair of arrows, an enemy skirmisher group at right, command-hint row, one squad slot red (0 / 4) and one archer slot 3 / 4; HUD and units read.
- `cmd_box_select`: day, two squads of 4 selected with cyan rings, the command hint row and both slots highlighted; clear.
- `cmd_move_ping`: a single cyan ring on the ground where the move was ordered, footmen slot selected; clear.
- `cmd_patrol`: a dashed line from the footmen to a yellow end dot, the patrol arrow glyph on the slot; clear.
- `cmd_slam`: night 2, the white slam ring round the king and footmen, yellow arrows, a red grunt with its hurt bar and puffs, the "slam" cooldown greyed; clear.
- `hud_day_squads`: day with the castle, both squads of 4 and the HUD; clear.
- Open readability points, all presentation and none touching data or the budget: thin palisade and similar tier I and II look from the riding camera, long wall shadows, a dark low-contrast night ground, small enemies from the stress camera. They are in the packet and left for Phase 8 (UI-05), not reworked.

### Export (Task 3)

`bash tools/export.sh` exit 0, `build/windows/Duskhold.exe` (109,268,480 bytes) and `Duskhold.pck` (1,469,600 bytes); `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exit 0 in 2.6 s. Nothing under `build/` or `screenshots/` is committed.

## Task Commits

1. **Task 1: Tracer, the whole phase verified locally** - no commit (nothing needed fixing; every automated check passed)
2. **Task 2: Push and green CI** - no commit (a push of existing commits; CI run 38959046206, no fix cycle, `ci.yml` untouched)
3. **Task 3: Export and the owner's packet** - `ff6df66` (docs)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## Files Created/Modified

- `.planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md` - the owner's gate packet (How to play, What to judge, What Claude already checked, 25 numbered Assumptions made for you, Your decision)

## Decisions Made

- The review found no presentation problem to fix in `enemy_views.gd`, `unit_views.gd`, `wall_views.gd` or `flow_field_gizmo.gd`, so none was touched.
- The packet states PLAT-01 as not met and quotes 04-FRAME-REPORT.md exactly; `requirements-completed` lists BLDG-10 and ENMY-04 only, and PLAT-01 stays open in REQUIREMENTS.md.
- The shipped-night step cost (about 40 enemies) was re-read as 3.56 and 3.69 ms with `step_bench --enemies=40` and put in the packet as about 3.6 ms; the 04-FRAME-REPORT.md numbers were not re-measured and the packet quotes them verbatim.

## Deviations from Plan

None - plan executed exactly as written. Two plan-text points that are not deviations: the plan's verify greps were satisfied by the post-04-10 full_idle digest (the older `f417c7f5...` digest is superseded), and the Task 2 verify's `headSha = HEAD` comparison was run at the pushed commit `a8c57ab` before the packet commit moved HEAD (the packet and this SUMMARY are on top of the checked commit, as Phases 2 and 3 were).

**Total deviations:** 0.
**Impact on plan:** none.

## Issues Encountered

- `bash tools/test.sh` read 27553 asserts against the dispatch baseline's 27554 (every test passing both times); not a failure.
- The first `gh run watch` call ran into my own 590 s shell timeout (exit 124) while CI was still running; it was resumed and returned success. No CI failure occurred.

## Known Stubs

None. No stub, skipped test or unrun verify was added by this plan (it adds no code).

## Threat Flags

None. No new endpoint, auth path or file access; `ci.yml` is unchanged (`permissions: contents: read`, no secrets, pinned SHAs intact) and the export excludes `tests/*, addons/gut/*, tools/*` (T-04-28 and T-04-29 mitigated as planned).

## User Setup Required

None - no external service configuration required. The owner's gate is the packet: `/gsd-verify-work 4`.

## Next Phase Readiness

- The owner plays two or three runs on the exported build and watches the stress night, then signs off or lists fixes through `/gsd-verify-work 4`.
- Open owner decisions the packet names: the performance route for PLAT-01 (GDExtension, a documented higher budget, or a profiling-driven optimisation plan), the wall-break rebuild hitch (time slicing), the D-14 reading, and whether walls are worth their gold.
- Blocker for calling the phase's success criterion 3 met: PLAT-01 (p95 37.04 ms against 8.0 ms, about 43 fps at 300 enemies) is NOT met; 04-09 is `halted`.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*

## Self-Check: PASSED

- `04-PLAYTEST-GATE.md` exists with its five sections and references to 04-FRAME-REPORT and 04-BALANCE-REPORT; `ff6df66` exists (`git log`); CI run 38959046206 concluded success for `a8c57ab`; 37 local and 37 CI screenshots present.
