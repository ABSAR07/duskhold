---
phase: 01-foundation-day-loop
plan: 16
subsystem: test-support-and-phase-records
tags: [godot, gdscript, gut, test-fixtures, gap-closure, security, validation, tdd]
status: complete

requires:
  - phase: 01-foundation-day-loop
    provides: "LoopTuning curve fields and helpers, E2eSupport.map_with_tier_cost (plan 01-14); coin VFX rework and sandbox (plan 01-15)"
provides:
  - "E2eSupport.flat_drip_tuning(seconds_per_coin): a copy of the shipped tuning with a flat pace and no cap, for tests that slow the drip"
  - "test_e2e_support_tuning.gd: pins the helper as flat, uncapped, otherwise shipped, and isolated from the cached tuning"
  - "Four slow-drip suites (refund, coin drip, spot label, start-night hold) independent of the shipped acceleration and cap"
  - "01-SECURITY.md rows T-01-23 to T-01-26 and a refreshed T-01-22; 01-VALIDATION.md rows for 01-14 to 01-16 and new BLDG-03 / BLDG-04 evidence"
affects: [verify-work UAT re-check of G-01-58, secure-phase and validate-phase re-runs, code-review of the gap-closure chain]

tech-stack:
  added: []
  patterns:
    - "Tests that watch a hold in progress build their tuning with E2eSupport.flat_drip_tuning; only tests that measure the shipped curve use the shipped tuning"
    - "A test helper that copies a shipped resource is itself unit-tested for isolation from the cached copy"

key-files:
  created:
    - tests/unit/test_e2e_support_tuning.gd
    - tests/unit/test_e2e_support_tuning.gd.uid
  modified:
    - tests/e2e/e2e_support.gd
    - tests/integration/test_build_hold_refund.gd
    - tests/e2e/test_coin_drip.gd
    - tests/e2e/test_spot_label.gd
    - tests/e2e/test_start_night_hold.gd
    - .planning/phases/01-foundation-day-loop/01-SECURITY.md
    - .planning/phases/01-foundation-day-loop/01-VALIDATION.md

key-decisions:
  - "The helper disables the curve with coin_drip_decay 1.0 and max_build_hold_seconds 0.0 instead of adding a second tuning resource, so it keeps reading the shipped file for every other field"
  - "The two Security Audit Trail and threats_open sections were left alone: the next /gsd-secure-phase run re-audits and appends its own row"

requirements-completed: [BLDG-03, DEV-01]

actuals:
  tokens: 6700
  tasks: 3
  commits: 4

plan_head_before: 88e9d4c83e0d83f5ae72393ce229d746c5b3ca5d
plan_head_after: 488908f3308c6ee34678f7fc52ac4c96465f8de1

coverage:
  - id: D1
    description: "Slow-drip fixtures get a flat, uncapped pace from one helper, so retuning the shipped acceleration or cap cannot change what those tests observe"
    requirement: "BLDG-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_e2e_support_tuning.gd"
        status: pass
      - kind: e2e
        ref: "tests/integration/test_build_hold_refund.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "test_coin_drip, test_spot_label and test_start_night_hold use the helper; test_coin_drip has no bare pace literal"
    requirement: "DEV-01"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_coin_drip.gd"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_spot_label.gd"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_start_night_hold.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "01-SECURITY.md and 01-VALIDATION.md describe the accelerating, capped hold as built"
    verification:
      - kind: other
        ref: "grep checks of the 01-16 Task 3 verify (T-01-23 to T-01-26, 01-01 to 01-16, 01-14-T1, 01-15-T2, 01-16-T3, superseded by 01-14, test_build_hold_cap)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-02
---

# Phase 1 Plan 16: Flat-Pace Fixtures and Records Summary

**One tested `E2eSupport.flat_drip_tuning` helper now gives every slow-drip test a flat, uncapped pace, so the shipped 0.9 decay and 3 s cap cannot silently change what four suites observe, and the security register and validation map record the accelerating capped hold.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-10-02
- **Tasks:** 3 (Task 1 tracer with TDD, Tasks 2 and 3 auto)
- **Files:** 9 (2 created, 7 modified, excluding this SUMMARY)

## Accomplishments

- `E2eSupport.flat_drip_tuning(seconds_per_coin)` loads the shipped tuning, takes a `duplicate(true)` copy and sets the first interval to the given pace, `coin_drip_decay` to 1.0 and `max_build_hold_seconds` to 0.0. `test_e2e_support_tuning.gd` (4 tests) shows every coin 1..40 takes the same interval, a ten-coin hold lasts ten paces, every other field equals the shipped `.tres`, and the cached shipped tuning keeps its decay below 1.0 and its positive cap.
- `test_build_hold_refund.gd`, `test_coin_drip.gd`, `test_spot_label.gd` and `test_start_night_hold.gd` build their slow fixtures with the helper. Their three private override functions and unused `TUNING` constants are gone, and no suite assigns the first interval directly any more.
- `test_coin_drip.gd`'s quick completion case uses a named `FAST_DRIP_S` (0.2 s) instead of a bare literal.
- `01-SECURITY.md`: T-01-22 now describes the 0.25 s first interval and the rewritten contract; T-01-23 to T-01-26 are added as closed with their evidence suites; 01-14 to 01-16 join the no-install row and AR-04; the counting sentence now reads sixteen T-01-SC listings, twelve merged, T-01-18 to T-01-26 added, 31 register rows (recounted: `grep -c "^| T-01-"` gives 31).
- `01-VALIDATION.md`: rows 01-14-T1..T3, 01-15-T1..T2 and 01-16-T1..T3 (WR-01 and IN-02 noted closed), the supersession note on 01-13-T1 and 01-13-T2, and `test_build_hold_cap`, `test_build_hold_timing`, `test_loop_tuning_curve`, `test_loop_tuning_contract`, `test_coin_drip_burst`, `test_coin_drip_flight` under BLDG-03 with `test_build_hold_timing` under BLDG-04.

## Task Commits

1. **Task 1 (tracer): flat-pace helper, unit test, refund suite adopts it**
   - RED: `8e19a02` (test) - `test_e2e_support_tuning.gd` fails to load: `flat_drip_tuning` does not exist on `E2eSupport` (parse error, as the plan expects)
   - GREEN: `d0c876f` (test) - helper added and refund suite switched; tracer `<verify>` re-run end to end (both suites in the JUnit XML, helper grep, lint) and passed before expansion
2. **Task 2: coin, label and night-start suites use the helper** - `b0a5a1e` (test); full suite 358/358, lint clean
3. **Task 3: security and validation records** - `488908f` (docs); only the two record files changed

**Plan metadata:** committed separately (docs: complete plan).

## Files Created/Modified

- `tests/e2e/e2e_support.gd` - `TUNING_PATH` and `flat_drip_tuning`
- `tests/unit/test_e2e_support_tuning.gd` (+ `.uid`) - helper contract
- `tests/integration/test_build_hold_refund.gd`, `tests/e2e/test_coin_drip.gd`, `tests/e2e/test_spot_label.gd`, `tests/e2e/test_start_night_hold.gd` - slow fixtures from the helper
- `.planning/phases/01-foundation-day-loop/01-SECURITY.md`, `01-VALIDATION.md` - records

## Decisions Made

- The helper uses the curve's own off switches (decay 1.0, cap 0) rather than a second tuning resource, so it cannot drift from the shipped file on the five unrelated fields.
- The Security Audit Trail, `threats_open` and the audit sections were not touched; the next `/gsd-secure-phase` run re-audits and appends its own row, as the plan says.

## Deviations from Plan

None - plan executed exactly as written. Two small notes, neither a deviation: Python is not installed on this machine, so the planned scripted edits were done with the Edit tool and one `sed` substitution; `bash tools/lint.sh --fix` reformatted the new test file once (gdformat line joins), which is why the GREEN commit carries the formatted version.

### TDD Gate Compliance

RED (`test(01-16)` `8e19a02`) precedes GREEN (`test(01-16)` `d0c876f`). The plan prescribes `test(01-16)` for the GREEN commit because the helper lives in test-support code; no `feat` commit exists by design. The RED run was a parse error on the missing static function, which the plan names as the expected failure. No refactor commit was needed.

## Issues Encountered

None. Full suite 358/358 green (354 after plan 01-15, plus the 4 new helper tests); `bash tools/lint.sh` clean. No Godot process left running.

## Known Stubs

None.

## Threat Flags

None. No runtime surface changed. The helper's isolation from the cached tuning is asserted by `test_e2e_support_tuning.gd`.

## Next Phase Readiness

G-01-58 is closed on the automated side. What remains for the phase: the owner's end-of-phase feel check of the pace and the cap rush (plan 01-15 Human Check), then code-review, secure-phase and validate-phase re-runs, which start from the refreshed records.

## Self-Check: PASSED

- Created files exist: `tests/unit/test_e2e_support_tuning.gd` and its `.uid`.
- Commits present: `8e19a02`, `d0c876f`, `b0a5a1e`, `488908f`; `git rev-list --count 88e9d4c..HEAD` = 4.
- Acceptance greps passed (`func flat_drip_tuning(`, `max_build_hold_seconds = 0.0`, no `_tuning_with_interval`, `flat_drip_tuning` in all four suites, `FAST_DRIP_S`, no `coin_drip_interval =` in the four suites, Task 3 greps); JUnit XML lists all three e2e suites; full suite 358/358; lint clean.
- `.planning/config.json` never staged.
