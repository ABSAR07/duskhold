---
phase: 01-foundation-day-loop
plan: 17
subsystem: gameplay-tuning
tags: [godot, gdscript, gut, hold-to-build, tuning, coin-drip, uat-gap]
gap_closure: true
gap_ids: [G-01-59]

requires:
  - phase: 01-foundation-day-loop
    provides: "Plans 01-14 to 01-16: accelerating coin drip, 3 s cap, coin VFX groups, hold pacing sandbox"
provides:
  - "Shipped hold curve with no cap and a 0.05 s coin floor (UAT G-01-59, D-05 amended again)"
  - "E2eSupport.stand_at_spot, begin_stepped_hold, step_hold: deterministic stepping of the hold controller"
  - "Long-hold and burst suites that step the controller by fixed deltas"
  - "Contract that pins no cap, the 0.05 s floor and in-range fields"
affects: [01-18, phase-2-playtest-tuning, 01-SECURITY, 01-VALIDATION]

actuals:
  tokens: 15058
  tasks: 3
  commits: 6

plan_head_before: dcdb6c9f337a9d209ad3dce367c52ec32e6f5baa
plan_head_after: a8eaba047b90869db52e55fa7eb69905c72c5e20

tech-stack:
  added: []
  patterns:
    - "Deterministic hold testing: set_process(false) on the controller, then call _process(fixed delta) once per awaited engine frame"
    - "Tuning contract pins owner decisions on purpose (no cap, floor value) next to in-range asserts"

key-files:
  created:
    - tests/e2e/test_build_hold_long.gd
  modified:
    - data/tuning/loop_tuning.tres
    - simulation/defs/loop_tuning.gd
    - tests/e2e/e2e_support.gd
    - tests/unit/test_loop_tuning_contract.gd
    - tests/unit/test_loop_tuning_curve.gd
    - tests/e2e/test_coin_drip_burst.gd
    - tests/unit/test_coin_drip_flight.gd
    - tests/e2e/test_hold_pacing_sandbox.gd
    - tests/unit/test_e2e_support_tuning.gd
    - tools/sandbox/hold_pacing_sandbox.gd
    - .planning/phases/01-foundation-day-loop/01-CONTEXT.md
  deleted:
    - tests/e2e/test_build_hold_cap.gd (git mv to test_build_hold_long.gd, uid travelled)

key-decisions:
  - "Cap field kept as a dormant data switch, shipped off (max_build_hold_seconds 0.0): two data values change, no runtime logic changes, D-09 keeps it a data-only knob"
  - "CoinDripVfx.MIN_FLIGHT_SECONDS stays 0.12 s: a 0.045 s flight would be a flicker; the cost is up to 3 coins in the air at the 0.05 s floor, which the owner re-check judges"
  - "Contract pins no cap on purpose, reversing review WR-02's premise, and adds WR-02's in-range asserts"

patterns-established:
  - "Stepped hold clock: every timing assertion is independent of frame length and wall-clock time"
  - "Coin-group assertions run right after the step returns, before any engine time can free a coin"

requirements-completed: [BLDG-03, BLDG-04]

coverage:
  - id: D1
    description: "With the shipped tuning a hold has no time limit: every coin of a 30-coin tier drips at its own due time, never two in one step, completing when the last coin lands (about 2.94 s) with one BuildIntent and one full-cost debit"
    requirement: BLDG-03
    verification:
      - kind: e2e
        ref: "tests/e2e/test_build_hold_long.gd#test_every_coin_drips_at_its_own_due_time_and_never_two_in_one_step"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_hold_long.gd#test_the_hold_lasts_the_uncapped_sum_of_its_intervals"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_hold_long.gd#test_the_pricey_hold_builds_with_one_progress_per_coin_and_one_debit"
        status: pass
    human_judgment: false
  - id: D2
    description: "After the acceleration a coin never comes faster than every 0.05 s (floor reached at coin 18, each extra coin adds 0.05 s); normal-game holds unchanged (House I 0.5 s, House II 0.725 s, House III 1.11 s, Tower I 0.93 s, Tower II 1.27 s)"
    requirement: BLDG-03
    verification:
      - kind: unit
        ref: "tests/unit/test_loop_tuning_curve.gd#test_hold_seconds_match_the_owner_table"
        status: pass
      - kind: unit
        ref: "tests/unit/test_loop_tuning_curve.gd#test_each_coin_past_the_floor_adds_exactly_the_floor"
        status: pass
      - kind: unit
        ref: "tests/unit/test_loop_tuning_contract.gd#test_shipped_floor_is_the_owners_and_is_reached_and_never_undercut"
        status: pass
    human_judgment: false
  - id: D3
    description: "Releasing the key before the last coin refunds every dripped coin and builds nothing (D-06 unchanged); a single long frame pays all due coins and completes with one debit"
    requirement: BLDG-04
    verification:
      - kind: e2e
        ref: "tests/e2e/test_build_hold_long.gd#test_releasing_before_the_last_coin_refunds_everything"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_hold_long.gd#test_one_long_frame_pays_every_due_coin_and_completes_with_one_debit"
        status: pass
    human_judgment: false
  - id: D4
    description: "Coin VFX staggers a long-frame group, draws at most 12 coins for groups and refunds, frees them; at most 3 drip coins in the air on the shipped curve"
    requirement: BLDG-03
    verification:
      - kind: e2e
        ref: "tests/e2e/test_coin_drip_burst.gd (5 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_coin_drip_flight.gd#test_at_most_the_derived_number_of_drip_coins_are_airborne_at_once"
        status: pass
    human_judgment: false
  - id: D5
    description: "How the uncapped 0.05 s-floor stream reads to the owner (up to 3 coins airborne at the floor; '0.05 s' read as the pace between coins, not the visible flight)"
    verification: []
    human_judgment: true
    rationale: "Feel and readability of the coin stream is a judgment no test asserts; plan 01-18 queues the owner re-check"

duration: 10min
completed: 2026-10-02
status: complete
---

# Phase 1 Plan 17: Uncapped hold with a 0.05 s coin floor (G-01-59) Summary

**The shipped build-hold curve loses its 3 s cap and drops the coin floor from 0.08 s to 0.05 s (two data values, no runtime logic change), with the long-hold and burst suites now stepping the hold controller deterministically and the data contract pinning the owner's decision.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-02T20:18:12Z
- **Completed:** 2026-10-02T20:28:28Z (SUMMARY and state updates follow)
- **Tasks:** 3 (Task 1 a tracer, TDD)
- **Files modified:** 14 (13 changed or created, 1 renamed with its uid)

## Accomplishments

- With the shipped tuning every coin of a 30-coin hold drips at its own due time. Stepped by a fixed 1/64 s per frame, the last coin lands at 188 steps = 2.9375 s, next to the expected 2.9367 s (the test asserts the stamp lies between the sum and the sum plus one step). One BuildIntent, one `gold_changed(10, -30)`.
- A single long frame (hold length plus one step) pays all 30 coins in one frame, completes with one debit and builds tier I. Releasing after 29 coins refunds all 29 (D-06 unchanged).
- The cap survives only as a tested, dormant data switch (`max_build_hold_seconds = 0.0`); the cap-clamp math is still covered by the curve suite on an explicit 3.0 s fixture.
- Every test that pinned the old 3 s cap or 0.08 s floor now pins the owner's curve; D-05 in `01-CONTEXT.md` records the UAT G-01-59 amendment.
- Final full-suite run: 46 scripts, 363 tests, 363 passing, 3101 asserts (`bash tools/test.sh`, exit 0); `bash tools/lint.sh` clean.

## Cap-field decision and defaults

Kept as planned (Option A): `max_build_hold_seconds` stays on `LoopTuning`, shipped and defaulted to 0.0 ("0 or less means no cap"). It is the smaller change, no locked decision argues for deletion (D-09 keeps numbers in data so Phase 2 can turn it back on), and the contract now pins "no cap" on purpose. Defaults table values were used exactly as planned; no value was changed:

| Field / constant | Value |
|---|---|
| `coin_drip_interval` | 0.25 s (unchanged) |
| `coin_drip_steady_coins` | 2 (unchanged) |
| `coin_drip_decay` | 0.9 (unchanged) |
| `coin_drip_min_interval` | 0.05 s (was 0.08) |
| `max_build_hold_seconds` | 0.0 = no cap (was 3.0) |
| `CoinDripVfx.MIN_FLIGHT_SECONDS`, `MAX_BURST_COINS`, `BURST_WINDOW_SECONDS` | unchanged |

## Task Commits

1. **Task 1 (tracer): every coin of a 30-coin hold at its own due time**
   - RED: `e200e8a` test(01-17): add failing uncapped long build hold test. Run failed on assertions (3 of 6 tests: strictly rising stamps, uncapped sum 3.4055 s vs 3.0 s, release after 29 coins), not on a load error.
   - GREEN: `c040517` feat(01-17): no build hold cap and a 0.05 s coin floor (UAT G-01-59)
2. **Task 2: pin the curve and contract, D-05 amendment**
   - `52d286a` test(01-17): pin the uncapped hold curve and its no-cap data contract
   - `b6dedd9` docs(01-17): amend D-05 with the owner's uncapped hold and 0.05 s floor
3. **Task 3: coin groups, airborne bound, sandbox, helper pins**
   - `6b8aade` test(01-17): coin groups, sandbox and helper pins follow the uncapped hold
   - `a8eaba0` chore(01-17): sandbox startup line describes the uncapped hold

**Plan metadata:** committed separately after this file (docs: complete plan).

## Files Created/Modified

- `data/tuning/loop_tuning.tres`, `simulation/defs/loop_tuning.gd`: shipped curve and script defaults; comments name fields and decisions, no hard-coded seconds
- `tests/e2e/e2e_support.gd`: `stand_at_spot`, `begin_stepped_hold`, `step_hold`, `NEAR_SPOT_OFFSET`, `FOCUS_TIMEOUT_S`; `flat_drip_tuning` doc re-worded
- `tests/e2e/test_build_hold_long.gd` (renamed from `test_build_hold_cap.gd`): six deterministic real-scene tests
- `tests/unit/test_loop_tuning_contract.gd` (8 tests), `tests/unit/test_loop_tuning_curve.gd` (15 tests): owner's G-01-59 curve, dormant cap, no-cap and floor pins, WR-02 in-range asserts
- `tests/e2e/test_coin_drip_burst.gd` (5 tests), `tests/unit/test_coin_drip_flight.gd` (10 tests), `tests/e2e/test_hold_pacing_sandbox.gd`, `tests/unit/test_e2e_support_tuning.gd`
- `tools/sandbox/hold_pacing_sandbox.gd`: startup line now reads "hold pacing sandbox: House plots cost [15, 30, 50] coins per tier; coins accelerate to one every 0.05 s and every coin drips, so full holds take 2.18 / 2.94 / 3.94 s" (verified headless)
- `.planning/phases/01-foundation-day-loop/01-CONTEXT.md`: D-05 amendment and the Discretion bullet

## Decisions Made

- Cap field kept as a dormant switch, shipped off (see above).
- `MIN_FLIGHT_SECONDS` left at 0.12 s on purpose; up to 3 coins fly at once at the floor, for the owner re-check to judge.
- The contract test pins no cap on purpose (reverses review WR-02's premise).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Discretion bullet wording in 01-CONTEXT.md**
- **Found during:** Task 2
- **Issue:** The plan quotes the old clause as ", later coins accelerate and a hold is capped at 3 s." but the file has "; later coins accelerate and a hold is capped at 3 s." (semicolon).
- **Fix:** Replaced the final clause with the plan's new text, keeping the file's semicolon.
- **Files modified:** `.planning/phases/01-foundation-day-loop/01-CONTEXT.md`
- **Committed in:** b6dedd9

**2. [Rule 3 - Blocking] RED commit staged only the rename**
- **Found during:** Task 1
- **Issue:** `git add` listed the already-renamed old path and failed, so the first commit held only the two renames.
- **Fix:** Staged the remaining files and amended the unpushed RED commit before continuing (hash e200e8a is the amended one).

**3. Test layout, within the plan's counts**
- Task 3 burst tests: the plan's `<behavior>` lists the 60-coin draw cap and its cleanup as separate cases; they are two of the five tests. Task 1's six tests merge the "STEP shorter than coin_interval(30)" check into the first test and the last-stamp and sum checks into one test.

---

**Total deviations:** 3 minor (2 Rule 3, 1 layout note). **Impact on plan:** none on behaviour or scope.

## TDD Gate Compliance

Task 1 (tracer) has its `test(01-17)` commit (`e200e8a`, RED on assertions) before its `feat(01-17)` commit (`c040517`). Tasks 2 and 3 are test and doc retargeting: their new tests passed at write time because Task 1 had already changed the shipped data, which is the plan's order (the old-pin tests were the known-red ones, now rewritten).

## Review findings

- Review WR-01 closed by Tasks 1 and 3 (stepped hold controller)
- Review WR-02 resolved: no cap pinned on purpose, in-range asserts added (optional @export_range hints not added)
- Review IN-04 closed by Tasks 1 and 3 (E2eSupport.stand_at_spot, derived sandbox gold)
- IN-01 is closed for loop_tuning.gd here and finished by plan 01-18; IN-02 and IN-03 stay open (out of this gap's scope)

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. T-01-27 (the uncapped `coin_due_seconds` sum, accepted) is recorded as AR-06 by plan 01-18.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 01-18: remaining doc comments (controller, VFX), a real-window sandbox check, the owner re-check queue, and the security and validation records. No runtime file (`input/build_hold_controller.gd`, `presentation/vfx/coin_drip_vfx.gd`) changed in this plan.

## Self-Check: PASSED

Created files and commits verified on disk and in git history (see the self-check run before the metadata commit).

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-10-02*
