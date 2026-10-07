---
phase: 02-night-defense-playtest-gate
plan: 22
subsystem: playtest-gate-closeout
tags: [godot, documentation, screenshots, export, gap-closure, g-02-18, playtest-gate]
status: complete

requires:
  - phase: 02-night-defense-playtest-gate
    provides: 02-21 king walk 7.5 m/s, sprint exactly 12 m/s (multiplier 1.6), D-03 amendment; 02-20 round-3 documents and baselines
provides:
  - "02-BALANCE-REPORT.md opens with a Round 4 note: the walk change moved no bot number, why (the bots sprint at exactly 12.0 m/s or never move), the evidence, the human blind spot"
  - "STATE.md's 01-05 ride-time line and 02-13 sprint line each say what superseded them"
  - "All 15 scripted screenshots re-run in a real window on the round-4 data (Saved 15 of 15), the three hold-point shots read"
  - "A fresh, launch-checked Windows export on the 7.5 / 1.6 king"
  - "02-PLAYTEST-GATE.md opens with the Round 4 owner packet and the round-4 decision prompt"
affects: [owner-playtest-gate, verify-work, phase-02-verification]

requirements-completed: [LOOP-07, DEV-05]

actuals:
  tokens: 2600
  tasks: 2
  commits: 2

plan_head_before: d6d39cf203e235786e769d3861faf985408f7557
plan_head_after: d9004d96f7838e97a90241c6c7138ad62cb0a1dd

tech-stack:
  added: []
  patterns:
    - "A new Round section is spliced above the kept rounds with a script that asserts the old text is byte-identical afterwards (the 02-20 pattern); numstat then shows 0 deleted lines (packet) or exactly the 1 intro line (report)"

key-files:
  created: []
  modified:
    - .planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md
    - .planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md
    - .planning/STATE.md

key-decisions:
  - "No bot re-measurement (bash tools/playtest.sh not run): the bots sprint on every tick at exactly 12.0 m/s before and after, or never move, and the diagnosis's 10-seed report was byte-identical; the suite's test_balance_acceptance and the unchanged full_idle digest are this plan's own evidence"
  - "Round 4 wins over older sections where they disagree (walk speed, sprint multiplier, ride and sprint control rows, assumption 12 wording, export date); Round 3's tables remain the current balance"

coverage:
  - id: D1
    description: "Round 4 note in the balance report (nothing moved, why, evidence, blind spot) and the two STATE.md lines marked superseded"
    requirement: "DEV-05"
    verification:
      - kind: integration
        ref: "bash tools/test.sh (831 tests in 95 scripts, test_balance_acceptance 8 of 8)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=full_idle --twice (ticks=5140, digest unchanged from round 3)"
        status: pass
    human_judgment: false
  - id: D2
    description: "15 screenshots re-run on the round-4 data in a real window; three hold-point shots read"
    requirement: "DEV-05"
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh (Saved 15 of 15, no blank frame) and bash tools/test.sh -gselect=test_shot_list.gd (5 of 5)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Fresh Windows export launches"
    requirement: "DEV-05"
    verification:
      - kind: other
        ref: "bash tools/export.sh; timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 (exit 0, 3 s)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Round 4 owner packet and decision prompt; whether the 7.5 m/s walk feels right and the round-3 gate (G-02-18) is answered"
    requirement: "LOOP-07"
    verification: []
    human_judgment: true
    rationale: "The playtest gate (D-18, ROADMAP success criterion 4) is the owner's judgment of movement feel and fun; bots and screenshot review are evidence only and only the owner's round-4 replay through /gsd-verify-work answers it"

duration: 20 min
completed: 2026-10-07
---

# Phase 02 Plan 22: Round 4 Gate Close-Out Summary

**Round 4 note in the balance report (the 7.5 m/s walk moved no bot number, with the byte-identical diagnosis, 831 passing tests and the unchanged full_idle digest as evidence), 15 screenshots re-run, a launch-checked fresh export, and the Round 4 owner packet reopening the playtest gate for G-02-18.**

## Performance

- **Duration:** about 20 min
- **Started:** 2026-10-07T10:56:45Z
- **Completed:** 2026-10-07T11:20Z (approximate; the final metadata commit follows)
- **Tasks:** 2
- **Files modified:** 3 (plus this SUMMARY and the plan-state files)

## Accomplishments

- `02-BALANCE-REPORT.md`: `## Round 4 (gap closure G-02-18, 2026-10-07)` sits above Round 3 with what changed (walk 5.0 to 7.5 m/s, sprint exactly 12 m/s, multiplier 2.4 to 1.6, acceleration 60 and the 2x fast-forward unchanged, D-03 amended), `### Why no bot number moved` (the building strategies move only at walk_speed x sprint_multiplier, exactly 12.0 in doubles both ways; `no_build` never moves), the evidence, the blind spot (the bots never walk at night; a human is 2.3x a grunt instead of 1.6x, which can only make play slightly easier) and the line that the Round 3 tables are the current balance and Round 4 wins where they disagree. Intro line 3 extended; numstat shows 45 added and exactly 1 deleted line (the intro); Rounds 3, 2 and 1 byte-identical (the splice script asserted it).
- `STATE.md`: exactly two lines changed (numstat 2 added, 2 deleted): the 01-05 ride-time line now ends "; superseded 2026-10-07 by 02-21: walk 7.5 m/s, the 110 m pair takes 14.7 s, D-03 amended, ride band 12-18 s" and the 02-13 sprint line ends " (02-21, 2026-10-07: walk 7.5 m/s and multiplier 1.6, the sprint still exactly 12 m/s)".
- `02-PLAYTEST-GATE.md`: `## Round 4 (after your playtest of 2026-10-07, round 3)` above Round 3 with the opening paragraph and the not-your-sign-off disclaimer, how to play (export date 2026-10-07 UTC, launch check, the PowerShell command), the change table with walk and sprint numbers and stops (0.47 m walk, 1.2 m sprint, inside the 2.5 m build radius), a ride-time table before and after, the controls table (Ride walk 7.5 m/s was 5, Sprint 12 m/s unchanged), what Claude checked, assumption 12 restated (13 to 15 stand), the round-4 decision prompt and the closing "Round 4 wins" line. numstat: 80 added, 0 deleted.

## Task Commits

1. **Task 1: Round 4 balance note and the two STATE.md lines** - `8bb0def` (docs)
2. **Task 2: Round 4 owner packet** - `d9004d9` (docs)

**Plan metadata:** the docs(02-22) commit that carries this SUMMARY, STATE.md, ROADMAP.md and REQUIREMENTS.md.

## Verification results (final tree, no code changed by this plan)

- `bash tools/test.sh`: exit 0, **831 tests in 95 scripts**, all passing (Asserts 8931, 374 s). `test_balance_acceptance.gd` is in gut-junit.xml with 8 of 8 passing; `test_king_movement_config` is present.
- `bash tools/lint.sh`: `167 files would be left unchanged`, `Success: no problems found`.
- Smoke replay equals the golden: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
- full_idle, run twice, identical to round 3: `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac`
- **No playtest was re-run in this plan** (`bash tools/playtest.sh` was not run), on purpose: the building bots sprint on every tick at exactly 12.0 m/s before and after (5.0 x 2.4 and 7.5 x 1.6 are both exactly 12.0 in doubles) and `no_build` never moves, so a re-run could only reproduce the diagnosis's 5-strategy x 10-seed report, which was byte-identical to the round-3 baseline.
- `bash tools/screenshot.sh` in a real window: exit 0, **"Saved 15 of 15 screenshots"**, 15 PNGs on disk, none blank. `bash tools/test.sh -gselect=test_shot_list.gd`: 5 of 5. **No change to `tools/screenshot/shot_scenarios.gd`** was needed: every shot reached its state.
- Export: `bash tools/export.sh` exit 0 (`Export OK`, `build/windows/Duskhold.exe`, 109 MB); `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exit 0 in 3 s. Export date 2026-10-07T11:10Z.

## Screenshot lines (the three walking shots, compared with the round-3 frames kept in build/screenshots_round3/, never committed)

- `night_combat`: Night 5 of 8, 19 enemies left, grunts and skirmishers at the lower left, a pink arrow in flight, the king beside the tower, Gold 0. Pass; the frame looks the same as round 3 (the bytes differ, the picture does not).
- `king_down_countdown`: Night 7 of 8, 1 enemy left, the cyan ghost king with "Knocked out - back in 6 s", a violet skirmisher and the tower's arrow cluster. Pass; the same as round 3 apart from one tower arrow a few pixels along its path.
- `overlay_paths`: Night 1 of 8 with the debug overlay and the white path line, one grunt at the left, the king at the castle front. Pass; the grunt and an arrow sit slightly differently and the FPS readout is 110 instead of 15, which is real-window frame timing, not a changed state.

Eleven of the 15 PNGs differ byte-wise from round 3 and four are identical (day_overview, king_behind_keep, results_defeat, spawn_telegraph); there are no image goldens and the differences read as frame timing.

## Decisions Made

- No bot re-measurement; the claim "nothing moved" rests on the diagnosis's byte-identical report, the passing `test_balance_acceptance`, the smoke golden and the unchanged full_idle digest, and the report names the blind spot instead of implying the bots tested the walk.
- Round 4 supersedes the older sections wherever they disagree; Round 3's balance tables stay as the current ones.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. One shell chain stopped early because `git check-ignore` on the bare directory names returned 1; the screenshots were then copied and re-run in a second call, with the round-3 PNGs already safe in build/screenshots_round3/.

## Known Stubs

None.

## Threat Flags

None. T-02-47 (disclaimer kept in both Round 4 sections, owner decision only through /gsd-verify-work, earlier rounds byte-identical by deleted-line counts) and T-02-48 (the nothing-moved claim cites its evidence and states the blind spot) are mitigated as planned.

## Next Phase Readiness

The round-4 gate is open: the owner replays one or two runs on the fresh export and either signs off or names further fixes, recorded through /gsd-verify-work (the plan's human-check, harvested by the phase verifier). Nothing here is the owner's sign-off.

## Self-Check: PASSED

- Files exist: 02-BALANCE-REPORT.md and 02-PLAYTEST-GATE.md carry `## Round 4`, `Why no bot number moved`, `Your decision (round 4)`, `walk 7.5 m/s, was 5`, `Sprint (12 m/s, unchanged)`, `0.47 m`; STATE.md carries `14.7 s` and `02-21, 2026-10-07: walk 7.5 m/s`; `build/windows/Duskhold.exe` and 15 PNGs in screenshots/ exist.
- Commits 8bb0def and d9004d9 exist on gsd/phase-01-foundation-day-loop; `git rev-list --count d6d39cf..HEAD` was 2 at SUMMARY write.
