---
phase: 01-foundation-day-loop
plan: 13
subsystem: tuning-and-build-hold
tags: [godot, gdscript, gut, tuning, coin-drip, build-hold, gap-closure, tdd]
status: complete

requires:
  - phase: 01-foundation-day-loop
    provides: "01-05/01-06 BuildHoldController per-coin drip (cost x coin_drip_interval, no floor), CoinDripVfx coin flight, LoopTuning data (D-05, D-09)"
provides:
  - "Shipped drip rate 0.3 s per coin (top of D-05's 0.15-0.3 s range): House I 0.6 s, House II 0.9 s, House III 1.5 s, Tower I 1.2 s, Tower II 1.8 s"
  - "CoinDripVfx.MAX_FLIGHT_SECONDS 0.27 so each coin still flies for 90% of the interval (unbroken one-at-a-time stream)"
  - "tests/unit/test_loop_tuning_contract.gd: D-05 range, script default parity, 0.5 s minimum hold, unbroken stream"
  - "tests/e2e/test_build_hold_timing.gd: real-scene timing proof of a House I hold with the shipped map and tuning"
affects: [phase-02-playtest-tuning]

actuals:
  tokens: 5000
  tasks: 2
  commits: 3
plan_head_before: 9096f7c967dfa543c748b69e46393935f332fe63
plan_head_after: 32a2f2ce57287051f0951b8b40fedddd181f295e

tech-stack:
  added: []
  patterns:
    - "Hold pace is pure data (loop_tuning.tres); a data-contract unit test bounds it instead of a code-level floor"
    - "Real-scene timing tests derive expected durations from ctx.tuning and ctx.buildings, never literals"

key-files:
  created:
    - tests/unit/test_loop_tuning_contract.gd
    - tests/unit/test_loop_tuning_contract.gd.uid
    - tests/e2e/test_build_hold_timing.gd
    - tests/e2e/test_build_hold_timing.gd.uid
  modified:
    - data/tuning/loop_tuning.tres
    - simulation/defs/loop_tuning.gd
    - presentation/vfx/coin_drip_vfx.gd

key-decisions:
  - "coin_drip_interval 0.2 -> 0.3 s: 1.5x longer, the top of D-05's documented range; fix is data, not code (D-09)"
  - "Coin flight cap 0.18 -> 0.27 s keeps the 90% flight share so no gap appears between coins"
  - "No minimum-hold floor in BuildHoldController: it would equalise House I, House II and Tower I and break D-05's pricier-takes-longer rule"

patterns-established:
  - "Contract tests derive the shortest hold from the cheapest tier cost over the shipped map, so a later cost or pace change cannot silently shorten holds"

requirements-completed: [BLDG-03, BLDG-04]

coverage:
  - id: D1
    description: "Holding the action key drips one coin per 0.3 s; shipped interval is within D-05's range and a fresh LoopTuning matches it"
    requirement: "BLDG-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_loop_tuning_contract.gd#test_shipped_drip_interval_is_within_the_d05_range"
        status: pass
      - kind: unit
        ref: "tests/unit/test_loop_tuning_contract.gd#test_script_default_matches_the_shipped_interval"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every shipped build or upgrade hold lasts at least 0.5 s (cheapest tier x interval = 0.6 s)"
    requirement: "BLDG-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_loop_tuning_contract.gd#test_shortest_shipped_hold_is_at_least_the_minimum"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_hold_timing.gd#test_house_one_hold_is_at_least_the_minimum"
        status: pass
    human_judgment: false
  - id: D3
    description: "A real-scene House I hold lasts cost x interval and drips one coin per interval"
    requirement: "BLDG-03"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_build_hold_timing.gd#test_house_one_hold_lasts_cost_times_the_drip_interval"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_hold_timing.gd#test_coins_drip_one_per_interval"
        status: pass
    human_judgment: false
  - id: D4
    description: "Coins still stream one at a time with no visible gap at the slower pace"
    requirement: "BLDG-04"
    verification:
      - kind: unit
        ref: "tests/unit/test_loop_tuning_contract.gd#test_coin_flight_keeps_the_stream_unbroken_at_the_shipped_interval"
        status: pass
      - kind: command
        ref: "bash tools/screenshot.sh build_in_progress (2 of 4 coins paid, coin mid-flight)"
        status: pass
    human_judgment: true
    rationale: "Whether 0.6 s House / 1.2 s tower feels 'a biiit longer' yet still snappy is a feel judgment; the plan's end-of-phase human check covers it"
---

# Phase 1 Plan 13: Slower Build Hold (G-01-4) Summary

**Per-coin drip raised from 0.2 s to 0.3 s (House I 0.4 s -> 0.6 s) with the coin flight cap raised to 0.27 s so the one-at-a-time stream stays unbroken, guarded by a data contract and a real-scene timing test.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-02T07:05:19Z
- **Completed:** 2026-10-02T07:12:14Z
- **Tasks:** 2
- **Files:** 3 modified, 4 created (two scripts plus their .uid files)

## Accomplishments

- UAT G-01-4 closed by tuning: `coin_drip_interval` 0.3 in `data/tuning/loop_tuning.tres` and the `LoopTuning` script default.
- `CoinDripVfx.MAX_FLIGHT_SECONDS` 0.27 keeps the flight at 90% of the interval (FLIGHT_FRACTION_OF_INTERVAL unchanged).
- `BuildHoldController` is untouched: pacing stays linear (D-05) and the refund path (D-06) is unchanged.
- Measured with the shipped data in the real scene (scratch probe, headless): House I 0.614 s, House II 0.911 s, House III 1.509 s, Tower I 1.218 s, Tower II 1.824 s against the expected 0.60 / 0.90 / 1.50 / 1.20 / 1.80 s.
- `build_in_progress` screenshot at 0.75 s into the 1.2 s tower hold shows 2 of 4 label coins filled and a coin mid-flight.

## Design Defaults (as planned, none changed)

| Choice | Default | Why |
|--------|---------|-----|
| `coin_drip_interval` | 0.3 s per coin (was 0.2) | Top of D-05's 0.15-0.3 s starting range; 1.5x longer. Durations: House I 0.6 s, II 0.9 s, III 1.5 s, Tower I 1.2 s, II 1.8 s |
| Coin flight cap | `CoinDripVfx.MAX_FLIGHT_SECONDS` 0.27 s (was 0.18) | Keeps each coin in flight for 90% of the interval, the stream feel that passed UAT test 7 |
| Minimum-hold floor in code | Not added | It would make House I, House II and Tower I take the same time, breaking D-05's "pricier builds take a little longer" |

## Task Commits

1. **Task 1 RED:** `f9ba152` test(01-13): add failing loop tuning contract (0.5 s floor test failed: 2 x 0.2 = 0.4 s)
2. **Task 1 GREEN:** `25bff70` feat(01-13): slower coin drip for more deliberate build holds
3. **Task 2:** `32a2f2c` test(01-13): prove House I hold lasts cost x drip interval in the real scene

## TDD Gate Compliance

Task 1: RED (`f9ba152`, one target test failed on the intended assertion, 3 others passed as they should at 0.2 s) then GREEN (`25bff70`, 307/307). Task 2 is a characterization test for behavior the GREEN commit already delivers, so it was committed passing in one `test(...)` commit; no REFACTOR commits were needed.

## Verification

- `bash tools/test.sh`: 310/310 pass (303 before plus 4 contract tests plus 3 timing tests), about 118 s; `test_loop_tuning_contract`, `test_build_hold_timing`, `test_coin_drip` and `test_build_hold_refund` all in the JUnit XML.
- `bash tools/lint.sh`: clean (gdformat reflowed two lines in the new tests via `--fix`).
- `bash tools/screenshot.sh build_in_progress`: saved a 55 KB PNG showing a hold in progress.
- `git diff --quiet -- input/build_hold_controller.gd`: unchanged.
- Acceptance greps for `coin_drip_interval = 0.3`, `coin_drip_interval: float = 0.3` and `MAX_FLIGHT_SECONDS: float = 0.27`: all present.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0. **Impact:** none.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. T-01-22 mitigated: `test_loop_tuning_contract.gd` bounds the interval to D-05's range and enforces the 0.5 s floor.

## Human Check (end of phase, for the owner)

Hold Space (or gamepad A) at a House plot and at a tower plot. The build should take a noticeably more deliberate moment (House I about 0.6 s, a tower about 1.2 s) while still feeling snappy, with coins streaming one at a time without gaps.

## Next Phase Readiness

Ready for the remaining gap-closure plan (01-12) and phase verification. The 0.3 s value is still a placeholder to be tuned at the Phase 2 playtest (D-09).

## Self-Check: PASSED

- FOUND: tests/unit/test_loop_tuning_contract.gd, tests/unit/test_loop_tuning_contract.gd.uid, tests/e2e/test_build_hold_timing.gd, tests/e2e/test_build_hold_timing.gd.uid
- FOUND commits: f9ba152, 25bff70, 32a2f2c
