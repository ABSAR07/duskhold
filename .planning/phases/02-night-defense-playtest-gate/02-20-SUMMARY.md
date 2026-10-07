---
phase: 02-night-defense-playtest-gate
plan: 20
subsystem: playtest-gate-documentation
tags: [godot, balance, playtest-gate, gap-closure, g-02-12, g-02-13, g-02-14, g-02-15, documentation]
status: complete

requires:
  - phase: 02-night-defense-playtest-gate
    provides: 02-17 castle 22 m / 27 m/s, 02-18 fast-forward toggle, 02-19 the owner's full-wall night counts, 02-16 round-2 report and packet
provides:
  - "02-BALANCE-REPORT.md Round 3 section above rounds 2 and 1 (what changed, night counts before and after, acceptance checks, the 50-seed line, the night-3 wall in plain words, summary and per-night tables)"
  - "02-PLAYTEST-GATE.md Round 3 owner packet above Round 2 (per-fix table, controls with the toggle row, checks, balance table copied verbatim, assumptions 12 to 15, night-3 wall, round-3 decision prompt)"
  - "A fresh launch-checked Windows export and 15 screenshots on the round-3 data"
  - "02-SECURITY.md T-02-29 wording no longer describes a hold"
affects: [phase-2-verification, owner-playtest-gate, verify-work]

requirements-completed: [LOOP-07, DEV-05]

actuals:
  tokens: 7500
  tasks: 2
  commits: 2

plan_head_before: 339676a7af826df0d420c80270b297007db73873
plan_head_after: f01dd00b74107436e0555280fccfd6b6305e6c11

tech-stack:
  added: []
  patterns:
    - "A new Round section is spliced above the kept earlier rounds by a script that asserts the old text is byte-identical (only one intro sentence and the new lines change)"
    - "The packet's balance table is extracted from the report's round-3 summary by script and checked as a substring, so the two cannot drift"

key-files:
  created: []
  modified:
    - .planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md
    - .planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md
    - .planning/phases/02-night-defense-playtest-gate/02-SECURITY.md

key-decisions:
  - "Round 3 says it wins where Round 2 and Round 1 disagree; both older sections stay byte-identical as the record"
  - "No scripted shot needed a change: all 15 reach their state on the round-3 data, so tools/shot_scenarios.gd is untouched"
  - "The castle bullet in the packet is stated from the measured numbers (castle kills about 4 of 12 on night 2 for the balanced bot) rather than the plan's 'never fires for a perfect defence', which is only true for the round-2 counts; the perfect-defence caveat is kept as a qualifier"

coverage:
  - id: D1
    description: "Round 3 section in 02-BALANCE-REPORT.md above rounds 2 and 1, with the night-3 wall and the 50-seed line"
    requirement: "LOOP-07"
    verification:
      - kind: other
        ref: "grep -q '## Round 3', '## Round 2', '## Round 1', 'night-3 wall', 'Kills castle', '5, 12, 21, 21, 21, 22, 27, 33' in 02-BALANCE-REPORT.md"
        status: pass
      - kind: other
        ref: "bash tools/playtest.sh (PLAYTEST_OK runs=50) and bash tools/playtest.sh --strategies=balanced --seeds=50 --out=build/playtest_round3_seeds50 (PLAYTEST_OK runs=50)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Round 3 owner packet in 02-PLAYTEST-GATE.md with the toggle row, assumptions 12 to 15, the night-3 wall and the decision prompt; fresh export launches"
    requirement: "DEV-05"
    verification:
      - kind: other
        ref: "grep -q 'Your decision (round 3)', 'night-3 wall', '22 m', '27 m/s' in 02-PLAYTEST-GATE.md; packet summary table is a substring of the report's Round 3 summary"
        status: pass
      - kind: other
        ref: "bash tools/export.sh then timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 (exit 0 in about 1 s)"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 15 scripted screenshots reach their states on the round-3 data (seven read by Claude)"
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh (Saved 15 of 15) and bash tools/test.sh -gselect=test_shot_list.gd (5 of 5)"
        status: pass
    human_judgment: false
  - id: D4
    description: "T-02-29 row of 02-SECURITY.md says 'switched on' instead of 'held'"
    verification:
      - kind: other
        ref: "grep -q 'switched on' 02-SECURITY.md; git diff shows exactly one changed row"
        status: pass
    human_judgment: false
  - id: D5
    description: "The owner's round-3 replay and decision: castle reach and arrow speed feel, the toggle on keyboard and gamepad, and whether the night-3 wall is 'a little harder' (closes G-02-12, D-18)"
    verification: []
    human_judgment: true
    rationale: "Bot numbers and Claude's screenshot review are evidence only; difficulty and input feel are the owner's judgment and only their /gsd-verify-work decision closes the gate"

duration: 13 min
completed: 2026-10-07
---

# Phase 2 Plan 20: Round-3 balance report and playtest packet Summary

**Round 3 is measured and on record (balanced 8 of 10 on seeds 1 to 10, 36 of 50 on seeds 1 to 50, every loss a night-3 wall for a House opening that lost two Houses on night 2), 15 screenshots and a launch-checked export are done, and the owner has a Round 3 packet that states the wall plainly and asks for the round-3 decision.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-10-07T00:13:12Z
- **Completed:** 2026-10-07T00:27Z (SUMMARY write; the docs commit follows)
- **Tasks:** 2
- **Files modified:** 3 (all planning documents; no code or data touched)

## Accomplishments

- `02-BALANCE-REPORT.md` opens with a Round 3 section: what changed, night counts before and after (totals 5, 8, 11, 14, 18, 22, 27, 33 to 5, 12, 21, 21, 21, 22, 27, 33), 13 acceptance checks (all pass), the 50-seed line, the night-3 wall, and the summary and three per-night tables with the Kills castle column. Diff: 146 added lines and one changed intro sentence ("round 3 above it by plan 02-20"); Round 2 and Round 1 are byte-identical.
- `02-PLAYTEST-GATE.md` opens with a Round 3 packet (97 added lines, none removed): opening paragraph, how to play (export date 2026-10-07 UTC, PowerShell command), per-fix table, controls with the toggle row, checks, screenshot table, the night-3 wall, assumptions 12 to 15, decision prompt and the "Round 3 wins" line. The packet's balance table is the report's Round 3 summary table verbatim (checked by script).
- `02-SECURITY.md` row T-02-29: "or when not held" became "or when fast-forward is not switched on (a toggle since 02-18)"; nothing else changed.

## Round-3 numbers (measured in this plan, final tree)

- Suite: 829 tests in 95 scripts, all passing (270 s); `test_balance_acceptance` (8 tests), `test_night_data_contract` (12), `test_every_night_ends` and `test_king_sturdiness` present in the JUnit file. Lint: 167 files unchanged, no problems.
- Smoke: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (equals tests/golden/smoke.json).
- Final full_idle (`--twice`): `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac`.
- Seeds 1 to 10, five strategies (`PLAYTEST_OK runs=50`):

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold (mean) | Buildings lost | Knockouts |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.4 / 2 / 3 | 3 | 7.3 | 4.0 | 1.4 |
| houses_first | 80% | 6.8 / 2 / 8 | 3 | 24.5 | 2.9 | 0.4 |
| towers_first | 100% | 8.0 / 8 / 8 | - | 7.0 | 2.0 | 2.8 |
| balanced | 80% | 6.8 / 2 / 8 | 3 | 22.3 | 2.7 | 0.4 |

- **50-seed balanced line (project CLI, `PLAYTEST_OK runs=50`): 36 of 50 won (72%)**; nights survived 6.3 mean (2 to 8), median loss night 3; the 14 losses (seeds 3, 9, 14, 15, 16, 19, 26, 28, 31, 33, 35, 38, 39, 42) are all on night 3.
- Wall mechanism, from report.json on the 50 seeds: 28 runs lost 0 or 1 House on night 2 and all 28 won with the castle at 70 hp after night 3; 22 runs lost 2 Houses on night 2, 14 of them lost on night 3 and 8 won (castle hp after night 3: 4, 30, 38, 14, 32, 4, 16, 34).
- Greedy loses night 3 on six seeds (1, 2, 3, 5, 6, 9) and night 4 on four (4, 7, 8, 10); balanced and houses_first lose the same seeds 3 and 9.

**Difference from the diagnosis: none.** Every figure the diagnosis measured for this exact edit (balanced 8 of 10 losing seeds 3 and 9 on night 3, 36 of 50; greedy 0 of 10 on nights 3 and 4 with median 3; no_build night 2; towers_first 10 of 10 with 7.0 gold; houses_first 8 of 10) reproduced exactly, so nothing is flagged.

## Screenshots (15 of 15 saved in a real window, Forward+; shot-list guard 5 of 5)

`bash tools/screenshot.sh` printed "Saved 15 of 15 screenshots". No scenario had to change, so `tools/screenshot/shot_scenarios.gd` is untouched. One line per shot Claude read:

- `spawn_telegraph`: day, Tower II standing, Gold 26, one red marker "5" over the west road, "Hold N / (Y) to start Night 1" and "Night 1: 5 enemies from 1 direction". Pass. It is night 1 (one road), so a single marker is correct; no shot shows the night-2 two-marker look (open observation, not a defect, the scenario is meant to be night 1).
- `night_combat`: Night 5 of 8, 19 enemies left, red grunts and violet skirmishers west of the tower, a pink skirmisher arrow in flight, the king beside the tower, Gold 0. Pass. No gold castle arrow in frame (castle off screen).
- `building_destroyed`: Night 3 of 8, 8 enemies left, a fallen House as dark slabs on its pale disc, grunts crowding the king, health bars on the king and a grunt, castle top left, "+14 gold". Pass.
- `king_down_countdown`: Night 7 of 8, 1 enemy left, the king as a cyan ghost, "Knocked out - back in 6 s", a violet skirmisher, yellow arrow streaks from a tower top right. Pass. The cluster is the shot's fast-forward launching arrows in one frame (round-1 note); castle and tower arrows share the same gold colour, so a castle arrow cannot be told apart in a still.
- `dawn_payout`: Dawn, Gold 23, gold coins in flight (two at the castle front and top, one over each House plot), two teal-roofed Houses. Pass; which coin is the castle's base coin is for play to judge.
- `results_victory`: "Victory", Nights survived 1 of 1 (the shot keeps one night), four stat rows evenly spaced, Play again (outlined) and Quit. Pass.
- `results_defeat`: "Defeat", Nights survived 0 of 8, the same even spacing, grunts crowding the dark castle behind the panel. Pass.

## Export check

`bash tools/export.sh` printed "Export OK: .../build/windows/Duskhold.exe" (Duskhold.exe 109 MB with Duskhold.pck); `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exited 0 in about 1 s. Export date in the packet: 2026-10-07 (UTC). Neither build/ nor screenshots/ is committed.

## Task Commits

1. **Task 1: Round 3 in the balance report** - `f56e07f` (docs)
2. **Task 2: Round 3 packet and the T-02-29 wording** - `f01dd00` (docs)

**Plan metadata:** the docs(02-20) commit that follows this summary.

## Decisions Made

- Round 3 sits above the kept Round 2 and Round 1 sections and says it wins where they disagree (castle numbers, fast-forward control, night counts, balance tables, assumptions 12 to 14, export date).
- The castle row in the packet reports what the castle now does on the new counts (about 4 of the 12 enemies of night 2 for balanced) and keeps "a defence that stops everything farther out never makes it fire" as a qualifier, because the plan's blanket "never fires for a perfect defence" no longer holds once the night-3 wall brings enemies close (T-02-44: state the measured effect).
- The packet's assumption 14 says the toggle stays on after the window loses focus (the old hold stopped on alt-tab), taken from the 02-18 SUMMARY.

## Deviations from Plan

None - plan executed exactly as written. (One wording choice, the castle row above, is recorded under Decisions Made; the bash heredoc used to build the report script failed once on shell quoting and the same script was written with the Write tool instead, no effect on the output.)

## Issues Encountered

None.

## Human check for the owner (G-02-12, ROADMAP success criterion 4, D-18)

Harvested by the phase verifier at the end of the phase (human_verify_mode=end-of-phase); nothing was waited on. Read the Round 3 section of `02-PLAYTEST-GATE.md`, then play one or two full runs on `build/windows/Duskhold.exe` (or the PowerShell command in the packet). Judge: does the castle's 22 m reach with 27 m/s arrows feel right; does fast-forward work as a toggle (press on, press again off, off again at dawn) on keyboard and gamepad; is the game "a little harder", knowing night 3 is a wall for a House opening that lost two Houses on night 2. Sign off or name the fixes still needed; the answer is recorded through `/gsd-verify-work`. Nothing in this plan, the bots' numbers or the screenshot review is the owner's sign-off.

## Known Stubs

None.

## Threat Flags

None. T-02-43 (repudiation) and T-02-44 (the wall described honestly) are mitigated: both documents keep the not-the-owner's-sign-off disclaimer, the packet's balance table is checked against the report, and every number is from this plan's own runs with the (empty) differences from the diagnosis stated.

## Next Phase Readiness

- The round-3 gate is open. Phase 2 closes only through the owner's `/gsd-verify-work` decision; the phase verifier collects the human check above.
- `02-SECURITY.md` T-02-29 line references (`fast_forward_controller.gd:35-42`, `loop_tuning.gd:19`) were deliberately left for the secure-phase gate, as the plan said.

## Self-Check: PASSED

- Files modified carry the changes: `## Round 3` above `## Round 2` in both documents, `Your decision (round 3)`, `night-3 wall`, `22 m`, `27 m/s`, `switched on` in 02-SECURITY.md; Round 2 and Round 1 removed-line count is 0 in the packet and 1 (the intro sentence) in the report.
- Commits `f56e07f` and `f01dd00` exist on gsd/phase-01-foundation-day-loop (`git rev-list --count 339676a..HEAD` = 2 before this summary).
- Plan-level checks re-run: suite 829/829, lint clean, smoke and full_idle replays, both playtest runs PLAYTEST_OK, 15 PNGs, shot-list guard 5/5, export and launch exit 0.
- `git diff 339676a..HEAD -- data simulation input presentation ui tests tools` is empty; nothing pushed.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-07*
