---
phase: 03-king-combat-troops
plan: 18
subsystem: testing
tags: [godot, balance, balance-report, playtest-gate, screenshots, documentation, gap-closure]
gap_closure: true
gap_ids: [G-03-11]

requires:
  - phase: 03-king-combat-troops
    provides: "03-17 outcome (a), search log, moved values and full_idle digests; 03-16 squad_value_ratio, targets and baseline; the fixes of 03-13, 03-14, 03-15 and 03-19 the gate packet lists"
provides:
  - "03-BALANCE-REPORT.md Round 2: Outcome, What changed, Search log (29 candidates and the levers ruled out), After Round 2 (six-strategy, squad value, per-night and per-seed tables re-measured on the committed data), What the numbers say and cannot, Determinism and goldens"
  - "03-PLAYTEST-GATE.md for test 15: question 6 with the new night totals, the Round 2 balance tables (03-11 numbers kept below, marked superseded), assumption 14 restated, 'Fixed since UAT round 1' with six gap ids"
  - "All 33 real-window screenshots re-captured on the retuned data, passing their blank and clear-centre checks"
affects: [phase-03-verification, 03-UAT-retest]

actuals:
  tokens: 5300
  tasks: 2
  commits: 2

plan_head_before: 2b43d849d8d150c6215b759a6193b7a97177a702
plan_head_after: bea054d0c0c4f894b9fb76c5bf872c58f10564d0
commits: 2

tech-stack:
  added: []
  patterns:
    - "A publish plan re-measures before it copies: the report tables come from a fresh deterministic run on the committed data and are checked against the retune plan's SUMMARY"

key-files:
  created: []
  modified:
    - .planning/phases/03-king-combat-troops/03-BALANCE-REPORT.md
    - .planning/phases/03-king-combat-troops/03-PLAYTEST-GATE.md

key-decisions:
  - "Round 2 is published as outcome (a) with the owner's 0.8 bar (D-26); the 03-11 Round 1 text stays below it and a line at the top of Round 2 says the After Round 2 tables supersede it"
  - "The gate packet states that the exported Windows build (from c418b6c) predates the fixes and the retune, and points the owner at the editor binary or a re-export, rather than leaving the stale export line to mislead"

patterns-established: []

requirements-completed: [UNIT-04, UNIT-07, KING-04, KING-05]

coverage:
  - id: D1
    description: "The balance report publishes Round 2: outcome (a) with the 0.8 bar, the moved values, the search log, the after-retune tables and the golden and full_idle digest facts"
    requirement: "UNIT-07"
    verification:
      - kind: other
        ref: "bash tools/playtest.sh --seeds=10 (PLAYTEST_OK runs=60: balanced 8, army_balanced 8, squad_value_ratio 0.915, equal to 03-17-SUMMARY.md); grep of the five Round 2 headings and 'byte-identical' in 03-BALANCE-REPORT.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "The gate packet shows the new night totals in question 6, the Round 2 results, assumption 14 restated and the six fixed gaps one line each"
    requirement: "UNIT-04"
    verification:
      - kind: other
        ref: "grep of 'Fixed since UAT round 1', G-03-11, G-03-8, G-03-14b, G-03-4, G-03-13 and G-03-14 in 03-PLAYTEST-GATE.md"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 33 real-window shots pass on the retuned data and the two night shots still show their states"
    requirement: "KING-04"
    verification:
      - kind: other
        ref: "bash tools/screenshot.sh (Saved 33 of 33 screenshots, exit 0); hud_night_squad_down.png and night_combat.png opened and read"
        status: pass
    human_judgment: false
  - id: D4
    description: "Whether the retuned nights feel tense with squads and whether a 0.9 s first tower still feels like a rewarding opening"
    requirement: "KING-05"
    verification: []
    human_judgment: true
    rationale: "The bots measure the data, not feel (D-08, Phase 2 D-18); the owner judges at the gate (test 15)."

duration: 13 min
completed: 2026-10-13
status: complete
---

# Phase 3 Plan 18: Round 2 published and the gate packet brought up to date Summary

**Round 2 of the balance retune is published in the balance report (outcome (a), two moved numbers, the 29-candidate search log, tables re-measured on the committed data: balanced 8 of 10, army_balanced 8 of 10, squad ratio 0.915, night 8 at 40 against 39), the owner's gate packet carries the same numbers and every fix since UAT round 1, and all 33 shots pass on the retuned data.**

G-03-11 is closed by plans 03-16, 03-17 and 03-18 together; the owner's feel check is still to come at the gate (test 15).

## Performance

- **Duration:** 13 min
- **Started:** 2026-10-13T19:13:32Z
- **Completed:** 2026-10-13T19:26:39Z (last task commit; this file follows)
- **Tasks:** 2
- **Files modified:** 2 (both under `.planning/`)

## Accomplishments

- Task 1: ran `bash tools/playtest.sh --seeds=10` on the committed data (`PLAYTEST_OK runs=60`, 3 min 37 s) and published Round 2 in `03-BALANCE-REPORT.md` under the 03-16 baseline: `### Outcome`, `### What changed`, `### Search log`, `### After Round 2`, `### What the numbers say, and what they cannot` and `### Determinism and goldens`. The outcome names (a) and the owner's 0.8 bar and notes that (b) would have been a successful path; the golden section carries G-03-11's wording (byte-identical, frozen fixtures) with both golden digests and full_idle's digest and ticks before (`ab4d17d9...`, 6199) and after (`f417c7f5...`, 6941).
- Task 2: rewrote the gate packet for test 15: question 6 (nights 5 to 8 are 25, 31, 39 and 40; the first tower fires every 0.9 s), the Round 2 goal table and six-strategy table with the 03-11 numbers kept below and marked superseded, assumption 14 restated, the sign-off and fixes-first bullets no longer asking about the two 03-11 findings or the "1 enemies" copy, and a `## Fixed since UAT round 1` list: G-03-8 (03-13), G-03-4 (03-14), G-03-14b (03-15), G-03-13 and G-03-14 (03-19), G-03-11 (03-16, 03-17, 03-18), one line each.
- Re-captured the whole shot set with `bash tools/screenshot.sh`: `Saved 33 of 33 screenshots`, exit 0, every blank and clear-centre check passed.

## What the two night shots show (opened and read after the re-capture)

- `hud_night_squad_down.png`: Night 7 of 8, 9 enemies left; the Barracks slot reads a red 0 / 4 (selected, outlined) and the Archery Range 3 / 4; the king is hurt at 36 / 50 with his cyan X-ray silhouette over the keep; health bars over the enemies and the keep, the hint row above the slots. It is still a squad at 0 alive with the king hurt.
- `night_combat.png`: Night 5 of 8, 23 enemies left, the king beside a tower at 50 / 50 with red and purple enemies and pink shots closing in on his left. It is still a night fight.

## Task Commits

1. **Task 1: Round 2 in the balance report** - `ad31e2b` (docs)
2. **Task 2: the gate packet with Round 2 and the fixes since UAT round 1** - `bea054d` (docs)

**Plan metadata:** the `docs(03-18): complete ...` commit that carries this file, STATE.md, ROADMAP.md and REQUIREMENTS.md.

## Verification Results

- Fresh run on the committed data against 03-17-SUMMARY.md: balanced 8 wins (lost seeds 3 and 9), army_balanced 8 wins (lost seeds 1 and 9), squad_value_ratio 0.915190 (4.30556 / 4.70455, the same 4.31 and 4.70), towers_first 0, houses_first 4, night totals 25 31 39 40, per-night army_balanced table equal to the SUMMARY's final matrix. No mismatch, so no deviation.
- Task 1 verify chain: `PLAYTEST_OK` in `build/playtest/playtest.log`, the five Round 2 headings and `byte-identical` present, `git diff --quiet HEAD -- data simulation tools tests` clean. `git show --stat ad31e2b` lists only `03-BALANCE-REPORT.md`.
- Task 2 verify chain: "Fixed since UAT round 1" and the gap ids G-03-11, G-03-8, G-03-14b (plus G-03-4, G-03-13, G-03-14) present; `bash tools/screenshot.sh` exit 0 with 33 of 33; both named shots exist and are non-empty; no file under `data/`, `simulation/`, `tools/` or `tests/` changed. `git show --stat bea054d` lists only `03-PLAYTEST-GATE.md`.
- The full GUT suite and lint were not re-run: this plan changes no code, data, test or golden (the suite's totals in the documents are 03-17's own run: 150 scripts, 1397 tests, 621.8 s, lint clean on 265 files, stated as such).

## Decisions Made

- Round 2 sits above the Round 1 text, which stays and is declared superseded by a sentence in Round 2's opening paragraph (the 02-20 precedent the report already cites) instead of being deleted.
- Added a "Since then" line to the packet's automated checks and a stale-export warning to "How to play": the exported `build/windows/Duskhold.exe` and the CI lines in the packet describe commit `c418b6c`, before the fixes and the retune, and the owner would otherwise play an export without them. The export itself was not redone (out of this plan's scope).

## Deviations from Plan

None - plan executed exactly as written.

Notes that are not deviations: the plan's `<verify>` for Task 1 reruns the playtest, so it ran twice in effect (once to measure, and its result is the one cited); the two small packet additions above (the "Since then" paragraph and the stale-export line) go beyond the plan's listed edits but change no number and keep to the packet's purpose.

**Total deviations:** 0 auto-fixed.

## Issues Encountered

None.

## Known Stubs

None. This plan edits two documents; no placeholder value flows to any output.

## Threat Flags

None. No code, endpoint, file access or trust boundary changed. T-03-29 holds: the After Round 2 tables come from a fresh deterministic run checked against 03-17-SUMMARY.md, and each task's commit lists only its own `.planning` file. T-03-30 holds: no new CLI argument, `playtest.sh --seeds=10` and the unchanged 33-shot `screenshot.sh`. T-03-SC: no package installed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 03's plans are all executed; the phase-level verification, the code-review loop and the owner's gate (UAT test 15, recorded through `/gsd-verify-work`) are what remain. Test 9 and test 12 are decided after the owner plays the fixed build (D-28).
- For the owner at the gate: the exported Windows build predates the fixes and the retune; run the editor binary or re-export (`bash tools/export.sh`) before playing.

## Self-Check: PASSED

- Modified files exist: `03-BALANCE-REPORT.md`, `03-PLAYTEST-GATE.md`.
- Commits exist: `ad31e2b`, `bea054d` (`git log --oneline --grep="03-18"`).
- Acceptance criteria re-run: five Round 2 headings and `byte-identical` found; the six gap ids found in the packet; 33 of 33 shots; both named shots non-empty; the code-diff guard clean.

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-13*
