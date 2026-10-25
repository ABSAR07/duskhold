---
phase: 05-castle-center-economy-depth
plan: 24
subsystem: gap-round-closing-pass-and-owner-section
tags: [godot, export, replays, gate-stress, playtest-gate, owner-checkpoint, g-05-2, g-05-7, d-08]

requires:
  - phase: 05-castle-center-economy-depth
    provides: plans 05-13 to 05-23 (the x100 rescale, the card recuts, the exposed Harbor, the measured bar and the gap-round section of 05-BALANCE-REPORT.md)
provides:
  - the round's one closing local pass, green on the final data (full suite, four goldens, full_idle, gate stress)
  - a fresh launch-checked Windows export for the owner (build/windows/Duskhold.exe, not committed)
  - the owner section at the top of 05-PLAYTEST-GATE.md (what changed, what the bots measured, how to play, what to re-judge, the cards the bots cannot judge, other choices)
affects: [phase-05-verification, phase-05-uat-extension]

actuals:
  tokens: 9000
  tasks: 2
  commits: 2

plan_head_before: de92f9144b97ad161de8ead5275dd5c97f415d0f
plan_head_after: a6d5834e105ebc6f3b081911a2b8fd02d367931c

tech-stack:
  added: []
  patterns:
    - "The owner's section sits above the older packet in the same file and says that it wins where the history quotes an old number"

key-files:
  created: []
  modified:
    - .planning/phases/05-castle-center-economy-depth/05-PLAYTEST-GATE.md

key-decisions:
  - "Prosperity recommendation (planner's, the owner decides): keep +2 and judge it in play, because +3 closed the gold gap (26.6 against 26.4) and none of the wins gap (6 of 10 either way); if it still feels weak, give it a second effect rather than a bigger gold number"
  - "Golden Age +4, Headsman's Edge x1.25 and Engineers as drafted are recommended keeps; the other six cards recommended as drafted; display divided by 100, Harbor spot, Harbor health and enemy health each recommended to stay as they are or wait for the Phase 6 roster"
  - "The new section is placed after the file's title and its intro paragraph and before '## How to play', so that the section the plan's verify extracts ends at that heading and does not swallow the intro"

requirements-completed: [BLDG-08, ECON-05, META-08]

coverage:
  - id: D1
    description: "The closing local pass is green once on the round's final data: full suite 281 scripts / 2668 tests, four goldens byte-identical, full_idle at the report's digest, gate stress 300/300/0 with the pre-round statistics, export launch-checked"
    requirement: META-08
    verification:
      - kind: integration
        ref: "bash tools/test.sh (build/exec05-24_suite.log, EXIT=0, 2668 of 2668); bash tools/replay.sh x5 (build/exec05-24_replays.log); bash tools/gate_stress.sh --twice (build/exec05-24_gate.log); bash tools/export.sh and timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 (rc 0, 8 s)"
        status: pass
    human_judgment: false
  - id: D2
    description: "05-PLAYTEST-GATE.md opens with the dated gap-round section: What changed, What the bots measured, How to play, What to re-judge, The cards the bots cannot judge (nine rows plus Prosperity) and Other choices you can ask for, with a recommendation for every decision"
    requirement: BLDG-08
    verification:
      - kind: other
        ref: "the plan's Task 1 and Task 2 verify greps and awk extraction (VERIFY_OK); a scan of the section for digests, plan ids and gap ids found none"
        status: pass
    human_judgment: false
  - id: D3
    description: "Whether each card is a viable pick (nine cards by arithmetic only, Prosperity trailing Masons), whether the exposed Harbor feels awkward but fair, and whether the day is deeper and fun"
    requirement: ECON-05
    verification: []
    human_judgment: true
    rationale: "No bot reaches castle tiers III and IV or fields soldiers; the owner re-judges UAT tests 2, 5 and 7 on the fresh build and decides the card choices at /gsd-verify-work 5"

duration: 30min
completed: 2026-10-25
status: complete
---

# Phase 5 Plan 24: The gap round's closing pass and the owner's section Summary

**The round is green once on its final data (281 scripts / 2668 tests, the four goldens byte-identical, full_idle at the report's digest, the gate stress at its pre-round statistics, a fresh export that launches and quits in 8 s), and 05-PLAYTEST-GATE.md now opens with the owner's dated section: what changed, what the bots measured, how to play, tests 2, 5 and 7 to re-judge, an explicit choice with a recommendation for each of the nine cards the bots cannot judge plus Prosperity, and the other choices he can ask for.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-10-25T21:45Z (the commit ledger was written at 21:46:43Z)
- **Completed:** 2026-10-25T22:15Z
- **Tasks:** 2 (Task 1 tracer, Task 2 auto)
- **Files modified:** 1 (05-PLAYTEST-GATE.md)

## Accomplishments

- Task 1 (tracer): the full suite once, the five replays, the gate stress, the export and its launch check, then the opening of the owner section (What changed, What the bots measured, How to play). The tracer's verify is automated-only, so it auto-continued to Task 2.
- Task 2: What to re-judge (tests 2, 5, 7 and the whole-blows sentence), The cards the bots cannot judge (the two opening sentences, one row for each of Commander and the eight tier III and IV cards with tier, numbers, basis, choices and recommendation, then a Prosperity paragraph), Other choices you can ask for (four, display divided by 100 first).

## Closing pass (own runs, logs under build/, nothing committed from build/)

**Full suite** (`bash tools/test.sh`, build/exec05-24_suite.log, 918 s, EXIT=0, "All tests passed"):

| Scripts | Tests | Passing | Failing | Asserts |
|---:|---:|---:|---:|---:|
| 281 | 2668 | 2668 | 0 | 61295 |

The script and test counts equal the orchestrator's gate after plan 05-23 (281 / 2668). The assert count printed 61295 where that gate recorded 61304; no test failed, skipped or went pending, and the difference of nine asserts is not explained by anything this plan changed (it changed no code). The JUnit XML carries test_card_resolution, test_harbor_exposure, test_king_widget, test_structure_decision_pins, test_balance_acceptance and test_pond_layout. Lint after each task: "448 files would be left unchanged", "Success: no problems found". No flake, no rerun.

**The five replays** (each `--twice`, rc 0, build/exec05-24_replays.log; the four goldens against `tests/golden/*.json`):

```
REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f
REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4
REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58
REPLAY_OK scenario=economy seed=1 outcome=won ticks=1842 digest=f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97
REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6993 digest=c68254cda9eb986d0dcb40a3ac83d29d23f24444ed525fcfc025c9d2c656c441
```

None of the four goldens moved (no D-08 stop rule); full_idle's digest is the one 05-BALANCE-REPORT.md records as final. `git diff --quiet ce3fcea` over tests/golden and the seven replay fixtures is clean.

**Gate stress** (`bash tools/gate_stress.sh --twice`, rc 0, both runs identical, build/exec05-24_gate.log):

```
GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=eb319f092e059b341cd186ce3c75306e1703a46913310d2f5b563119143efaa8
```

The statistics are the pre-round ones; the digest is the one recorded after the rescale of the stress data.

**Export and launch check:** `bash tools/export.sh` rc 0, last lines `[ DONE ] savepack` and `Export OK: .../build/windows/Duskhold.exe`; build/windows holds Duskhold.exe (109268480 bytes), Duskhold.pck (1648256) and libduskhold_sim.windows.x86_64.dll (670720). `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` printed the Godot banner, exited rc 0 in 8 s.

## Task Commits

1. **Task 1 (tracer): the owner section opened after the closing pass** - `22e3e0b` (docs)
2. **Task 2: the re-judge list, the card decisions and the other choices** - `a6d5834` (docs)

**Plan metadata:** the docs(05-24) commit that carries this file.

## The owner section, in brief (what the file now says)

- What changed: every health and damage number x100 (king 5000, footman 100, Tower 300, shown as they are, gold unchanged); Commander 125, Warded Mail 200 to 150, Iron Discipline an honest x1.5, Royal Training +100 and +25%; Prosperity +2, Golden Age +4 plus its Shrine bonus, Headsman's Edge x2 at x1.25; the Harbor on a smaller pond beside the west road between the first tower and the Gold Mine at 1400 / 2000 instead of 1800 / 2400; the king's health label wider.
- What the bots measured: balanced 8 of 10 and army_balanced 8 of 10 (ratio 0.88, bar 0.8), no bot order changed; Harbor built in 9 of 10 balanced games, attacked in 7 of those 9, destroyed 18 times; balanced gold 26.4 (was 30.0), buildings lost 10.6 (was 8.6); Prosperity trails Masons (8 of 10 against 6 of 10, 6 of 10 even at +3).
- The decisions: Commander, War Horns, Warded Mail, Iron Discipline, Arrow Storm and Master Builders as drafted (recommended); Headsman's Edge keep x1.25 (recommended) or x1.5 or no slowdown (not recommended); Engineers as drafted (recommended) or +34%; Golden Age +4 (recommended) or +3 or +2; Prosperity keep +2 (recommended, with +3, a different effect or lower Masons as the alternatives); display divided by 100, other Harbor spots and health, more enemy health: each with a recommendation, none taken for the owner.
- The sentences the plan required are in: "100 times", "divided by 100", the whole-blows sentence, and the opening sentence that the eight tier III and IV cards were set by arithmetic with no measurement.

## Deviations from Plan

None - plan executed exactly as written. The full suite had no failure, so the stale-literal rule of Task 1 step 1 was not needed and no test file was edited; no data number, simulation file, balance pin, golden input or .tres changed.

Notes that are not deviations: (a) the new section sits after the file's title and its one intro paragraph and before `## How to play`, because the plan's Task 2 verify extracts the section up to the next `## ` heading and an intro paragraph left below the new section would have become part of it; the intro paragraph (which says nothing was changed in the last plan) is old packet text and the new section's first paragraph says the older packet is history where it quotes old numbers. (b) The planner's Prosperity pick is not in the plan; the environment brief asked for one labelled as a recommendation, and it says plainly that the owner decides. (c) Royal Training's card line and a Tower's "Damage 300" label were not seen on screen by plan 05-20, so the section describes them only as what the cards and labels now say. (d) `git.base-branch --is-protected` treats the working branch as the project's base branch, as in plan 05-23; the commits were made on it by the orchestrator's sequential-executor instruction.

## Issues Encountered

- A stray `python - <<'E'` probe of mine hung the first results read (python waited on stdin) and was moved to a background task by the harness; the log was read again with sed and the results are the ones above. It touched no file.

## Known Stubs

None.

## Threat Flags

None. T-05-44 mitigated (the export ran from the pinned native sources, the DLL sits beside the exe and the headless launch check exited 0 in 8 s). T-05-45 mitigated (the nine cards, Golden Age's +4 and +3, Headsman's Edge's x1.25 and x1.5, a recommendation each, the no-measurement statement and the display choice are all in the section; the plan's verify prints VERIFY_OK).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The round is complete locally and the branch is not pushed (the orchestrator pushes after this plan; no `gh` was run). Next are the phase close-out gates (code review, verifier, UAT extension) and then `/gsd-verify-work 5`, where the owner plays the fresh build and answers tests 2, 5 and 7 and the card choices. Things for the verifier: the screenshots of plan 05-20 did not show Royal Training's card line or a tower's "Damage 300" label (capture them at verification); UAT test 10's packet quotes the older 0.888 ratio and the pre-round export, which the new section supersedes (0.882, the 2026-10-25 export).

## Self-Check: PASSED

- Files: 05-PLAYTEST-GATE.md holds the new section with all six subsections; build/windows/Duskhold.exe, Duskhold.pck and the DLL exist; no build/ file is committed (git status clean after each commit).
- Commits: 22e3e0b and a6d5834 are on the branch (`git log --grep="05-24"`).
- Acceptance criteria re-run: the dated section with "100 times", What the bots measured and How to play; the export exists and exits in 8 s; the Deviations section is present; Task 2's verify prints VERIFY_OK; the digest/plan-id scan of the section finds nothing; lint clean.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*
