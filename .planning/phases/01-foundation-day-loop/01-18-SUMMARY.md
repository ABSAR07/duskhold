---
phase: 01-foundation-day-loop
plan: 18
subsystem: gameplay-tuning
tags: [godot, gdscript, hold-to-build, coin-drip, uat-gap, docs, security, validation]
gap_closure: true
gap_ids: [G-01-59]

requires:
  - phase: 01-foundation-day-loop
    provides: "Plan 01-17: uncapped hold curve with a 0.05 s floor, long-hold and burst suites, sandbox"
provides:
  - "Controller and coin VFX doc comments that describe the uncapped, due-time drip with no seconds in comments (review IN-01 closed)"
  - "Real-window measurements of the uncapped sandbox hold and the normal map, recorded next to the expected values"
  - "The owner's G-01-59 re-check queued as an end-of-phase human check"
  - "01-SECURITY.md and 01-VALIDATION.md describing the hold as built (T-01-27, AR-06, per-task rows for 01-17 and 01-18)"
affects: [phase-1-verification, 01-UAT, code-review, secure-phase, validate-phase]

actuals:
  tokens: 7100
  tasks: 2
  commits: 2

plan_head_before: 50bb99269b6b340710c6e85f7a315be066769607
plan_head_after: 0c08d9903343e9328e40ee415e3c6ac9c27a7e0f

tech-stack:
  added: []
  patterns:
    - "Doc comments name fields and decisions; numbers live only in the tuning data (D-09)"
    - "Real-window self-check before the owner is asked: scripted Input.action_press, hold-clock stamps, per-frame live-coin sampling, screenshots outside timing runs"

key-files:
  created: []
  modified:
    - input/build_hold_controller.gd
    - presentation/vfx/coin_drip_vfx.gd
    - .planning/phases/01-foundation-day-loop/01-SECURITY.md
    - .planning/phases/01-foundation-day-loop/01-VALIDATION.md

key-decisions:
  - "Comment-only edits to the two scripts (no code line, constant or identifier changed), verified from the commit diff"
  - "T-01-24 and T-01-25 rescoped from a cap fast-forward/rush to any frame that pays several coins (long frame, hitch, refund, or a cap if one is ever set)"
  - "T-01-27 (uncapped coin_due_seconds sum, O(coins paid) per frame) accepted as AR-06, revisit if a later phase prices tiers in the hundreds"

patterns-established:
  - "Comment gate: no comment line in the hold scripts may state a number of seconds"

requirements-completed: [BLDG-03, BLDG-04]

coverage:
  - id: D1
    description: "Controller and coin VFX doc comments describe the uncapped, due-time drip and state no seconds; the docs(01-18) commit changes only comment lines"
    requirement: BLDG-03
    verification:
      - kind: other
        ref: "bash tools/test.sh (363/363) plus the Task 1 comment gate and git show diff check (0 non-comment changed lines)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Real-window sandbox check: 15/30/50 coins complete at 2.178/2.942/3.938 s, one coin per frame, at most 3 coins in the air, a late release at 3.5 s refunds every paid coin and builds nothing, House I 0.506 s and Tower I 0.931 s on the normal map"
    requirement: BLDG-03
    verification:
      - kind: other
        ref: "scratch probe probe18.gd run with the pinned console exe in a real window (forward_plus, about 144 fps)"
        status: pass
    human_judgment: false
  - id: D3
    description: "01-SECURITY.md and 01-VALIDATION.md describe the uncapped hold as built (T-01-22 to T-01-25 refreshed, T-01-27, AR-06, 32 register rows, five new per-task rows, supersession notes)"
    requirement: BLDG-04
    verification:
      - kind: other
        ref: "Task 2 grep checks of the plan verify block"
        status: pass
    human_judgment: false
  - id: D4
    description: "How the uncapped 0.05 s-floor stream feels and reads to the owner, and whether '0.05 s' meant the pace between coins or the flight"
    verification: []
    human_judgment: true
    rationale: "Feel and readability of the coin stream is a judgment no test asserts; the owner re-check is queued as the human-check below"

duration: 7min
completed: 2026-10-02
status: complete
---

# Phase 1 Plan 18: Uncapped hold docs, real-window check and records (G-01-59) Summary

**The hold controller and coin VFX comments now describe the uncapped, due-time coin drip with no seconds in them, the sandbox was driven in a real window (15/30/50 coins at 2.178/2.942/3.938 s, one coin per frame, at most 3 coins airborne), and the security register and validation map record the hold as built, including the new T-01-27 and AR-06.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-02T20:31:49Z
- **Completed:** 2026-10-02T20:39:00Z (SUMMARY and state updates follow)
- **Tasks:** 2 (Task 1 a tracer)
- **Files modified:** 4

## Accomplishments

- `input/build_hold_controller.gd` class doc and `_advance_hold` doc now say each coin is paid at its own due time (`LoopTuning.coin_due_seconds`), that a frame long enough to pass several due times pays all of them, and that one BuildIntent goes out when the last coin is paid. `presentation/vfx/coin_drip_vfx.gd` class and `_on_hold_progress` docs say same-frame groups come from long frames, hitches and refunds (or a cap if the tuning ever sets one), and that at the floor the minimum flight makes a few coins overlap. No code line changed: all 0 non-comment lines in the `docs(01-18)` diff.
- Review IN-01 closed by plan 01-17 Task 1 and plan 01-18 Task 1 (no seconds in doc comments).
- Real-window self-check (below) matches every expectation, before the owner is asked.
- `01-SECURITY.md`: plan range 01-01 to 01-18; T-01-22 to T-01-25 refreshed; T-01-27 and AR-06 added; no-install row and AR-04 list 01-17 and 01-18; counting sentence recounted.
- `01-VALIDATION.md`: rows 01-17-T1..T3 and 01-18-T1..T2 with actual suites and counts, supersession notes on 01-14-T1, 01-14-T2, 01-15-T1, 01-15-T2, and `test_build_hold_long` as BLDG-03 and BLDG-04 evidence.
- Final full-suite run (after Task 1): 46 scripts, 363 tests, 363 passing, 3101 asserts (`bash tools/test.sh`, exit 0); `bash tools/lint.sh` clean. Task 2 changed only planning documents.
- Security register total after recount: 32 `T-01-` rows (18 T-01-SC listings across the plans, 14 merged into one row).

## Real-window self-check (Task 1 step 3)

Scripted with `Input.action_press`, a real window (renderer forward_plus, Windows display, about 144 fps, average frame 6.9 ms), the king stood at spot + (1.0, 0, 2.0). Timing runs took no screenshots; the PNGs came from a separate run on a fresh sandbox.

| Check | Expected | Measured |
|---|---|---|
| Sandbox 15 coins, last-coin hold clock | about 2.178 s | 2.178 s (run 1), 2.181 s (run 2) |
| Sandbox 30 coins | about 2.937 s | 2.942 s |
| Sandbox 50 coins (after the late release) | about 3.937 s | 3.938 s |
| Most coins paid in one frame | 1 | 1 on every hold |
| Most coins in the air during a hold | at most 3 | 2 (15-coin), 3 (30- and 50-coin) |
| Late release of the 50-coin tier at hold clock 3.493 s | refunds every paid coin, builds nothing | refunded 41 (all paid), gold 55 -> 55, tier 2 -> 2; 15 coins in the air right after (12 refund coins plus 3 drip coins still flying), 0 after 0.6 s |
| Same tier held again to completion | completes, one debit | 50 coins, hold clock 3.938 s, gold 55 -> 5, tier 2 -> 3 |
| Normal map House I (cost 2) | 0.5 s | 0.506 s, first coin 0.250 s |
| Normal map Tower I (cost 4) | 0.9275 s | 0.931 s |

Every completion lies within one frame (about 7 ms) of the curve. The first 15-coin hold of run 1 had a 26.5 ms hitch (first coin at 0.257 s), the only slow frame seen; the other holds had a worst frame of 6.9 to 7.2 ms.

Captures (read with the Read tool):

- `exec18/b_30coin_floor_2p6s.png` (30-coin hold at clock 2.611 s, 23 coins paid, 2 coins in the air): the label "House II" with a row of 23 filled and 7 dark coin icons, the king standing at the plot and two small yellow coins visible in flight between the king and the plot, so the stream at the floor reads as separate coins along the king-to-plot line.
- `exec18/c_50coin_after_late_release.png` (0.1 s after the release at clock 3.507 s, refund of 41, 12 coins in the air): the label "House III" with an all-dark 50-icon row (nothing paid any more), gold back to 55 and the coins flying back from the plot toward the king. The very wide icon row is the known label layout caveat at synthetic costs, noted in the human check.

No measurement contradicted an expectation, so nothing was tuned. Scratch files stay in the session scratchpad and were not committed. No Godot process of mine is still running.

## Owner re-check, queued (human-check, copied verbatim from the plan)

End of phase, for the owner (UAT re-check of G-01-59). (1) Normal game: from Git Bash in the repo root run `bash tools/godot.sh --path .` (or press F5 in the editor). Hold Space or gamepad A at a House plot for House I, II and III, and at a tower plot. Expected: unchanged since the last check. The first coin leaves after 0.25 s and the coins then come faster; House I takes about 0.5 s, House III about 1.1 s and a tower about 0.9 s, one coin at a time. (2) Sandbox: run `bash tools/godot.sh --path . res://tools/sandbox/hold_pacing_sandbox.tscn`. House plots cost 15, 30 and 50 coins per tier, and you start with enough gold for all three. Hold at one House plot three times; on the 50-coin tier, let go once at about 3.5 s, then hold it again. Expected: the 15-coin build takes about 2.2 s, the 30-coin build about 2.9 s and the 50-coin build about 3.9 s. There is no time limit any more: every coin drips in on its own and nothing is fast-forwarded. After the acceleration the coins come every 0.05 s, so up to 3 coins are in the air at once. Letting go early flies the coins back (at most 12 are drawn) and builds nothing. Judge whether the pace feels right, and say whether your "0.05 s" meant the gap between coins (as built) or how long each coin takes to fly (each flight still lasts at least 0.12 s so a coin stays visible). (The label's coin-icon row is very wide at these synthetic costs; the label layout for expensive buildings belongs to the later phase that adds them and is not part of this check.)

## Task Commits

1. **Task 1 (tracer): comments follow the uncapped hold, sandbox checked in a real window** - `aa4a872` (docs). The tracer verify ran green (full suite 363/363, lint clean, comment gate, diff check) before expansion.
2. **Task 2: security and validation records** - `0c08d99` (docs)

**Plan metadata:** committed separately after this file (docs: complete plan).

## Files Created/Modified

- `input/build_hold_controller.gd` - class and `_advance_hold` doc comments only
- `presentation/vfx/coin_drip_vfx.gd` - class and `_on_hold_progress` doc comments only
- `.planning/phases/01-foundation-day-loop/01-SECURITY.md` - refreshed T-01-22 to T-01-25, T-01-27, AR-06, plan range and counts
- `.planning/phases/01-foundation-day-loop/01-VALIDATION.md` - five per-task rows, supersession notes, BLDG-03/BLDG-04 evidence

## Decisions Made

- Comment-only changes in the scripts; the controller's drip condition `coin_due_seconds(_coins_paid + 1)` is untouched.
- T-01-24 and T-01-25 are rescoped to every frame that pays several coins rather than a cap event; the cap mode's arithmetic stays covered by `test_loop_tuning_curve.gd`.
- AR-06 accepts the O(coins paid) per-frame cost of the uncapped due-time sum (about 0.03 ms at 50 coins).

## Deviations from Plan

None - plan executed exactly as written. One note: the plan's per-commit trailer names Claude Opus 5.5; the commits carry this harness's trailer (Claude Sonnet 5.5) as the harness attribution instruction requires.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. No runtime surface changed; T-01-27 and AR-06 were registered by plan 01-17 and recorded here.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

G-01-59 is closed on the automated side. The phase is ready for verify-work (the queued human check above), then the next code-review, secure-phase and validate-phase runs, which start from accurate records. `.planning/config.json` carries a pre-existing uncommitted change that was not touched.

## Self-Check: PASSED

Verified: the four modified files exist, commits `aa4a872` and `0c08d99` are in git history, the Task 2 grep checks printed VERIFY_OK, and the `docs(01-18)` Task 1 diff has 0 non-comment changed lines.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-10-02*
