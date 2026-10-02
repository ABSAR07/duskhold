---
phase: 01-foundation-day-loop
plan: 14
subsystem: build-hold-input
tags: [godot, gdscript, tuning, hold-to-build, gap-closure, gut, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: BuildHoldController, LoopTuning, CommandProcessor.validate_build, E2eSupport (plans 01-04 to 01-13)
provides:
  - "Accelerating, capped hold-to-build pace: 0.25 s first coins, x0.9 per coin, 0.08 s floor, 3.0 s cap with the rest paid in the cap frame"
  - "LoopTuning.coin_interval / coin_due_seconds / build_hold_seconds pure helpers, the one source of hold length for tests, tools and the coin VFX"
  - "BuildHoldController hold clock (get_hold_elapsed) so timing tests need no wall-clock time"
  - "E2eSupport.map_with_tier_cost: isolated deep-copied map with one tier repriced"
  - "D-05 amendment in 01-CONTEXT.md recording the owner's UAT G-01-58 decision"
affects: [01-15 coin stream visuals, 01-16 test decoupling and SECURITY/VALIDATION docs, Phase 2 playtest tuning]

actuals:
  tokens: 15000
  tasks: 3
  commits: 5

plan_head_before: dafaa85ed7f9eaca71c144023000cdbd9c41cc02
plan_head_after: eb54967ecdda2f23eaea1ccea2d369ae858ae93d

tech-stack:
  added: []
  patterns:
    - "Pure schedule helpers on a Resource (due time per coin) drive a controller; a cap is just a clamped due time, so no special fast-forward branch"
    - "Real-scene timing measured on the node's own accumulated frame delta, never wall-clock"
    - "DEEP_DUPLICATE_ALL to isolate a test's data edit from cached external resources"

key-files:
  created:
    - tests/e2e/test_build_hold_cap.gd
    - tests/e2e/test_build_hold_cap.gd.uid
    - tests/unit/test_loop_tuning_curve.gd
    - tests/unit/test_loop_tuning_curve.gd.uid
  modified:
    - simulation/defs/loop_tuning.gd
    - data/tuning/loop_tuning.tres
    - input/build_hold_controller.gd
    - tests/e2e/e2e_support.gd
    - tests/e2e/test_build_hold_timing.gd
    - tests/unit/test_loop_tuning_contract.gd
    - tests/e2e/test_walking_skeleton.gd
    - tests/e2e/test_upgrade_at_spot.gd
    - tests/e2e/test_debug_overlay_toggle.gd
    - tests/integration/test_build_hold_refund.gd
    - .planning/phases/01-foundation-day-loop/01-CONTEXT.md

key-decisions:
  - "Cap fast-forward is implicit: every coin due at or past the cap has due time == cap, so the cap frame pays them all and sends one BuildIntent; no affordability branch (D-06 forbids a partially-paid state, and a hold only starts with the full cost)"
  - "coin_drip_interval keeps its name (now the first and steady interval, 0.25 s) so existing overrides still compile"
  - "All curve numbers live in data (D-09); helpers sanitise bad values (T-01-23) so a hold can never be instant or endless"

patterns-established:
  - "Hold-length expectations in tests come from LoopTuning.build_hold_seconds(cost), never cost x interval"
  - "Repricing a shipped tier in a test goes through E2eSupport.map_with_tier_cost"

requirements-completed: [BLDG-03, BLDG-04]

coverage:
  - id: D1
    description: "Holding the action key pays coins on the accelerating curve (0.25 s first coins, x0.9 per coin, floor 0.08 s); House I 0.5 s, Tower I 0.9275 s"
    requirement: "BLDG-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_loop_tuning_curve.gd#test_hold_seconds_match_the_owner_table"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_hold_timing.gd#test_each_tower_coin_is_paid_at_its_due_time"
        status: pass
    human_judgment: true
    rationale: "Whether the accelerating pace feels right is a feel judgement; plan 01-15 adds the real-window feel check and the Phase 2 playtest retunes the numbers"
  - id: D2
    description: "No hold lasts longer than 3 s: at the cap every remaining coin is paid in that frame, one BuildIntent, one full-cost debit"
    requirement: "BLDG-04"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_build_hold_cap.gd#test_the_pricey_hold_builds_with_one_progress_per_coin_and_one_debit"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_hold_cap.gd#test_every_coin_due_at_the_cap_is_paid_in_the_same_frame"
        status: pass
    human_judgment: false
  - id: D3
    description: "Release or range exit at any moment before the cap, including just before it, refunds every dripped coin and builds nothing (D-06)"
    requirement: "BLDG-04"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_build_hold_cap.gd#test_releasing_just_before_the_cap_refunds_everything"
        status: pass
    human_judgment: false
  - id: D4
    description: "Shipped tuning data held to D-05's range, the 0.5 s minimum hold, the 3 s cap, script/data parity and monotonic holds"
    verification:
      - kind: unit
        ref: "tests/unit/test_loop_tuning_contract.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "Hold timing tests measure the hold's own clock, so a frame hitch cannot make them flake (review WR-01)"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_build_hold_timing.gd#test_the_hold_clock_equals_the_summed_frame_deltas"
        status: pass
    human_judgment: false
  - id: D6
    description: "D-05 records the owner's UAT G-01-58 amendment in 01-CONTEXT.md"
    verification:
      - kind: other
        ref: "grep -q G-01-58 .planning/phases/01-foundation-day-loop/01-CONTEXT.md"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-10-02
status: complete
---

# Phase 1 Plan 14: Accelerating, Capped Build Hold Summary

**Hold-to-build now pays its first coins 0.25 s apart, speeds up (x0.9 per coin, 0.08 s floor), and never lasts more than 3 s: at the cap every remaining coin is paid in that frame and the build completes with one full-cost debit, driven by pure `LoopTuning` due-time helpers.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-10-02T12:20:25Z
- **Completed:** 2026-10-02T12:33:46Z
- **Tasks:** 3 (Task 1 tracer, TDD; Task 2 and Task 3 TDD-flagged characterization/test work)
- **Files modified:** 15 (4 created, 11 modified, excluding this SUMMARY)

## Accomplishments

- Closed the simulation path of G-01-58: `BuildHoldController._advance_hold` pays each coin once its hold clock reaches `LoopTuning.coin_due_seconds(n)`; coins due at or past the cap share the cap's due time, so the cap frame pays all of them and sends one `BuildIntent` with no special branch. D-06 (release/range/day check runs first, full refund) and D-09 (numbers in data) are unchanged.
- Curve in data and behind three sanitised pure helpers (`coin_interval`, `coin_due_seconds`, `build_hold_seconds`); the `.tres` and script defaults agree (contract test).
- Real-scene proof on a 30-coin House I tier (isolated map copy): 30 ordered `hold_progress`, one `hold_completed`, one `gold_changed` of -30, last coins paid together at the cap, and a release 0.3 s before the cap refunds in full with the tier unbuilt.
- Review WR-01 closed by Task 3 (hold-clock stamps).
- D-05 amended in `01-CONTEXT.md`; D-06 text untouched.

## Owner Decision vs Design Defaults

Binding (owner, UAT G-01-58, amends D-05): first coin 0.25 s, later coins accelerate, a whole hold never exceeds 3 s, remaining coins paid at once at 3 s. No affordability branch was built: a hold only starts when `validate_build` passes the full-cost check, gold is debited once at completion, and a failed completion submit already emits `hold_cancelled` with a full refund.

Non-binding defaults, all shipped unchanged (none needed changing):

| Field | Shipped | Why |
|-------|---------|-----|
| `coin_drip_interval` (first and steady interval) | 0.25 s | Owner value, inside D-05's 0.15-0.3 s range |
| `coin_drip_steady_coins` | 2 | Keeps House I at exactly 0.5 s (UAT G-01-4 minimum) |
| `coin_drip_decay` | 0.90 | Each later coin takes 90% of the previous interval |
| `coin_drip_min_interval` | 0.08 s | Floor, reached at coin 13 |
| `max_build_hold_seconds` | 3.0 s | Owner value |

## Measured Hold-Clock Completion Times (real scene)

Last-coin stamp on `hold.get_hold_elapsed()` (frame-delta clock), shipped map and tuning:

| Hold | Measured (hold clock) | Expected |
|------|-----------------------|----------|
| House I (2 coins) | 0.501 s and 0.500 s (two runs) | 0.5 s |
| Tower I (4 coins) | 0.932 s and 0.934 s (two runs) | 0.9275 s |
| 30-coin cap hold (24 drip, 6 fast-forwarded) | 3.0005 s, 3.0004 s, 3.0054 s (three runs) | 3.0 s |

Every overshoot is within the one process frame the plan allows (asserted as `<= due + frame delta + 0.0001`).

## Task Commits

1. **Task 1 (tracer): 30-coin hold completes at the 3 s cap in the real scene**
   - RED: `3c60001` (test) - `test_build_hold_cap.gd` fails: 15 of 30 coins paid at 3.75 s, tier never built, no `gold_changed`
   - GREEN: `0d7dbd0` (feat) - controller pays coins at due times; tracer `<verify>` re-run end to end and passed before expansion
2. **Task 2: Pin the curve math and data contract, record D-05 amendment**
   - `1f687e1` (test) - `test_loop_tuning_curve.gd` (14 tests) and the rewritten `test_loop_tuning_contract.gd` (6 tests)
   - `053b212` (docs) - D-05 amendment and the Claude's Discretion note
3. **Task 3: Hitch-proof timing on the hold clock, hold waits on `build_hold_seconds`**
   - `eb54967` (test)

**Plan metadata:** committed separately (docs: complete plan).

## Files Created/Modified

- `simulation/defs/loop_tuning.gd` - curve fields, range constants, `coin_interval` / `coin_due_seconds` / `build_hold_seconds`
- `data/tuning/loop_tuning.tres` - shipped curve (0.25 s, 2 steady, 0.9, 0.08 s, 3.0 s cap)
- `input/build_hold_controller.gd` - hold clock, due-time coin payment, removed the interval timer and minimum-interval constant
- `tests/e2e/e2e_support.gd` - `map_with_tier_cost` (deep copy, isolated from cached `house.tres`)
- `tests/e2e/test_build_hold_cap.gd` (+ `.uid`) - cap, fast-forward, single debit, refund just before the cap, no leak into cached resource
- `tests/unit/test_loop_tuning_curve.gd` (+ `.uid`) - pure curve math and sanitising
- `tests/unit/test_loop_tuning_contract.gd` - rewritten shipped-data contract (coin-flight assertion removed; plan 01-15 re-creates it)
- `tests/e2e/test_build_hold_timing.gd` - hold-clock timing, no wall-clock source
- `tests/e2e/test_walking_skeleton.gd`, `test_upgrade_at_spot.gd`, `test_debug_overlay_toggle.gd`, `tests/integration/test_build_hold_refund.gd` - hold waits via `build_hold_seconds`
- `.planning/phases/01-foundation-day-loop/01-CONTEXT.md` - D-05 amendment

## Decisions Made

- The cap fast-forward needs no branch because the schedule helper clamps due times to the cap; this also means a release on the cap frame still refunds (the release check runs before coin payment).
- Kept the field name `coin_drip_interval` for compatibility with existing overrides in `test_coin_drip.gd`, `test_spot_label.gd`, `test_start_night_hold.gd` and `test_build_hold_refund.gd` (plan 01-16 owns decoupling them).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] RED commit carries the prerequisite helpers and data**
- **Found during:** Task 1, step 4
- **Issue:** The plan's steps 1-3 (data, helpers, `map_with_tier_cost`) have no commit of their own, and the RED test cannot even load without them.
- **Fix:** Committed them in the single RED `test(01-14)` commit together with the clock-only controller change. The drip loop stayed linear, so the cap tests failed on the intended assertions (tier not built, 15 of 30 coins, no debit, last stamp 3.75 s above the cap).
- **Commit:** `3c60001`

**2. [Rule 1 - Bug] Out-of-bounds index in the RED test**
- **Found during:** Task 1 RED run
- **Issue:** `test_every_coin_due_at_the_cap_is_paid_in_the_same_frame` indexed a stamp array that was shorter than 30 when the build failed, raising a script error instead of a clean assertion failure.
- **Fix:** Assert the coin count first and return early; same guard for the empty case in the completion test (and the same pattern in the timing tests).
- **Commit:** `3c60001`

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug in own new test). **Impact:** none on scope or behavior.

### TDD Gate Compliance

RED (`test(01-14)` `3c60001`) precedes GREEN (`feat(01-14)` `0d7dbd0`). The RED run failed on the planned assertions, not on a load error. No refactor commit was needed. Tasks 2 and 3 are characterization/test-only work on already-implemented behavior.

## Issues Encountered

None. Full suite 338/338 green at the end (was 315 before this plan; 337 after Task 2); `bash tools/lint.sh` clean. No Godot process left running.

## Known Stubs

None.

## Threat Flags

None. T-01-23 (curve-field tampering) and T-01-24 (cap fast-forward) are mitigated as planned: helper sanitising is covered by `test_loop_tuning_curve.gd`, the single `BuildIntent` / one debit / refund-before-cap by `test_build_hold_cap.gd`.

## Next Phase Readiness

Ready for 01-15 (coin stream visuals): `CoinDripVfx` still reads `coin_drip_interval` for its flight time and is not yet aware of acceleration or the fast-forward; it should use `LoopTuning.coin_interval` / `coin_due_seconds` and re-create the stream contract in `tests/unit/test_coin_drip_flight.gd`. 01-16 still owns the slow-drip overrides (`_tuning_with_interval`) and the SECURITY/VALIDATION refresh (T-01-22 text, new T-01-23/T-01-24 rows).

## Self-Check: PASSED

- Created files exist: `tests/e2e/test_build_hold_cap.gd`, its `.uid`, `tests/unit/test_loop_tuning_curve.gd`, its `.uid` (verified in `git diff --stat`).
- Commits present: `3c60001`, `0d7dbd0`, `1f687e1`, `053b212`, `eb54967`; `git rev-list --count dafaa85..HEAD` = 5.
- Acceptance greps passed (helpers, `coin_due_seconds(_coins_paid + 1)`, `DEEP_DUPLICATE_ALL`, `build_hold_seconds(` in all four waits, no `get_ticks` in the timing test, 14 `func test_` in the curve test).
- `.planning/config.json` never staged.
