---
phase: 05-castle-center-economy-depth
plan: 15
subsystem: test-fixtures
tags: [x100-rescale, fixtures, tres, wall-tests, gap-closure, G-05-2, godot]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "Plans 05-13 and 05-14: all 19 shipped data files at the x100 health and damage scale; full_idle cec3eb71"
provides:
  - "The seven non-golden fixture maps (castle, gate, one_night, shrine, squads, walls, walls_gap) at the x100 scale of the shipped defs they load"
  - "test_wall_decision, test_wall_dawn and test_wall_detour applying their own amounts at the x100 scale with every expected tick count unchanged"
affects: [05-16, 05-17, 05-18, 05-19, 05-20, 05-24]

actuals:
  tokens: 3600
  tasks: 2
  commits: 2

plan_head_before: 8a22c10787039dc9f76bb4a9489d36da43cd45a9
plan_head_after: d4f26fb0712fc4d1799e5742dad504a3bb4ffcf5

tech-stack:
  added: []
  patterns:
    - "Exact-x100 check on fixtures: rebuild each .tres from git show ce3fcea:<file> with only six field names multiplied (awk), diff against the working file; now run over the seven non-golden fixtures"

key-files:
  created: []
  modified:
    - tests/fixtures/fixture_map_castle.tres
    - tests/fixtures/fixture_map_gate.tres
    - tests/fixtures/fixture_map_one_night.tres
    - tests/fixtures/fixture_map_shrine.tres
    - tests/fixtures/fixture_map_squads.tres
    - tests/fixtures/fixture_map_walls.tres
    - tests/fixtures/fixture_map_walls_gap.tres
    - tests/unit/test_wall_decision.gd
    - tests/integration/test_wall_dawn.gd
    - tests/integration/test_wall_detour.gd

key-decisions:
  - "Followed the owner's locked G-05-2 decision: fixture health and damage numbers x100 so they match the shipped defs they load; the four golden fixtures and their king and tuning copies untouched (D-08)"
  - "test_wall_decision keeps every expected tick count: its grunt is the shipped grunt, so GRUNT_PER_300 and the health paired with it both moved x100 (ratio unchanged)"

patterns-established:
  - "A test pairing the shipped grunt with its own amounts moves with the data: scale both sides, keep the expected ticks"

requirements-completed: [BLDG-08, META-08]

coverage:
  - id: D1
    description: "Castle, gate, one-night, Shrine and squads fixtures at x100, every other line byte-identical to ce3fcea; the Shrine, castle-tier, squad-lifecycle, night-loop and requirement-validation suites pass on them"
    requirement: "BLDG-08"
    verification:
      - kind: other
        ref: "exact-x100 awk rebuild from git show ce3fcea:<file> over the five fixtures (empty diff each)"
        status: pass
      - kind: unit
        ref: "bash tools/test.sh -gselect=test_shrine (75 of 75), test_castle_tiers (16), test_squad_lifecycle (4), test_night_loop (7), test_build_requirement_validation (15)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Wall ring and wall gap fixtures at x100 and the three wall tests on their own amounts at x100; tick counts, assertions and test counts unchanged"
    requirement: "BLDG-08"
    verification:
      - kind: other
        ref: "exact-x100 awk rebuild over all seven fixtures; acceptance greps on the three wall tests; test count 12 at ce3fcea and now"
        status: pass
      - kind: unit
        ref: "bash tools/test.sh -gselect=test_wall_decision (12), test_wall_dawn (5), test_wall_detour (12), test_wall_determinism (3), test_wall_behaviour (8), test_flow_field (9)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The four goldens replay byte-identical and full_idle stays at cec3eb71; golden inputs unchanged since ce3fcea"
    verification:
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke|army|walls|economy --twice --expect-file=tests/golden/<s>.json; --scenario=full_idle --twice; git diff --quiet ce3fcea over the golden inputs"
        status: pass
    human_judgment: false

duration: 10 min
completed: 2026-10-25
status: complete
---

# Phase 05 Plan 15: Fixtures and wall tests at the x100 scale Summary

**The seven non-golden fixture maps and the three wall tests that pair the shipped grunt with amounts of their own moved to the owner's x100 scale, so every suite on them keeps its fractions and every expected wall tick count, while the four goldens replay byte-identical and full_idle stays at cec3eb71.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-25T12:19:50Z
- **Completed:** 2026-10-25T12:28:44Z (code), SUMMARY follows
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Task 1 (tracer): castle, gate, one_night, shrine and squads fixtures at x100 and the five suites that run on them green on the first run.
- Task 2: walls and walls_gap fixtures at x100; test_wall_decision, test_wall_dawn and test_wall_detour scaled with every expected tick count, assertion and test count as at ce3fcea.
- No shipped data changed here, so full_idle is still cec3eb71 and the four frozen goldens (D-08) replayed unchanged.

## Numbers changed (old to new)

| File | Field | Old | New |
|------|-------|-----|-----|
| fixture_map_castle.tres | castle_max_health / castle_attack_damage | 70 / 2 | 7000 / 200 |
| fixture_map_gate.tres | inline tower tier 1 attack_damage / max_health | 3 / 50 | 300 / 5000 |
| fixture_map_gate.tres | inline tower tier 2 attack_damage / max_health | 6 / 70 | 600 / 7000 |
| fixture_map_gate.tres | castle_max_health / castle_attack_damage | 70 / 2 | 7000 / 200 |
| fixture_map_one_night.tres | castle_max_health | 40 | 4000 |
| fixture_map_shrine.tres | inline Shrine attack_damage / max_health / wake_threshold_hp | 3 / 30 / 100 | 300 / 3000 / 10000 |
| fixture_map_shrine.tres | castle_max_health / castle_attack_damage | 200 / 2 | 20000 / 200 |
| fixture_map_squads.tres | castle_max_health | 40 | 4000 |
| fixture_map_walls.tres | castle_max_health / castle_attack_damage | 200 / 2 | 20000 / 200 |
| fixture_map_walls_gap.tres | castle_max_health / castle_attack_damage | 200 / 2 | 20000 / 200 |

Wall-test literals changed:

| File | Literal | Old | New |
|------|---------|-----|-----|
| test_wall_decision.gd | GRUNT_PER_300 | 20 | 2000 |
| test_wall_decision.gd | grunt case of damage_per_300 | (2, 30) "2 per second" | (200, 30) "200 per second" |
| test_wall_decision.gd | ttd_ticks health literals paired with GRUNT_PER_300 | 30 / 31 | 3000 / 3100 (450 and 465 unchanged) |
| test_wall_decision.gd | damage_segment(MIDDLE, ...) | 10 | 1000 (due again: 300 unchanged) |
| test_wall_decision.gd | ttd_ticks first million case | 1000000 | 100000000 (15000 unchanged); the 1000000/1 and 1 << 40 cases stay |
| test_wall_decision.gd | messages | "30 hp at 20 per 10 s" and the like | "3000 hp at 2000 per 10 s" and the like (5 grunts "3000 hp at 10000", 2 grunts "at 4000", 1000 grunts "at 2000000") |
| test_wall_decision.gd | header | none | "Gap round G-05-2 (owner decision 2026-10-25) ..." sentence |
| test_wall_dawn.gd | damage_segment(5, ...), (2, ...) / (6, ...) | 1000 / 4 | 100000 / 400 |
| test_wall_detour.gd | damage_segment(1, ...), (2, ...) | 1000 | 100000 |

No cost, income, range, position, spawn, night or group count moved in any fixture.

## Verification results

Exact-x100 check (the plan's awk rebuild from `git show ce3fcea:<file>`, carriage returns stripped, six field names multiplied by 100) printed no `NOT_EXACT_X100` for any of the seven fixtures (castle, gate, one_night, shrine, squads after Task 1; all seven after Task 2). The diff of my edits matches the planner's 05-15.diff on every fixture line; on the tests it matches too, except that the diff leaves assertion messages as they were and this plan updates them (the plan won).

Golden inputs: `git diff --quiet ce3fcea -- tests/golden fixture_map_replay_smoke/_army/_walls/_economy fixture_king_replay_smoke/_army fixture_tuning_replay_smoke` exits 0 (GOLDEN_INPUTS_IDENTICAL, after both tasks). They were never opened.

Suites (each its own invocation, runs logged under the scratch dir, suite present in the JUnit XML each time):

- `-gselect=test_shrine`: 8 scripts, 75 tests, 75 passing, 788 asserts, exit 0
- `-gselect=test_castle_tiers`: 16 of 16, 72 asserts, exit 0
- `-gselect=test_squad_lifecycle`: 4 of 4, 35 asserts, exit 0
- `-gselect=test_night_loop`: 7 of 7, 473 asserts, exit 0
- `-gselect=test_build_requirement_validation`: 15 of 15, 43 asserts, exit 0
- `-gselect=test_wall_decision`: 12 of 12, 171 asserts, exit 0
- `-gselect=test_wall_dawn`: 5 of 5, 53 asserts, exit 0
- `-gselect=test_wall_detour`: 12 of 12, 94 asserts, exit 0
- `-gselect=test_wall_determinism`: 3 of 3, 10 asserts, exit 0
- `-gselect=test_wall_behaviour`: 8 of 8, 412 asserts, exit 0
- `-gselect=test_flow_field`: 9 of 9, 57 asserts, exit 0

Replays (all `--twice`, exit 0):

- smoke: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
- army: `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`
- walls: `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58`
- economy: `REPLAY_OK scenario=economy seed=1 outcome=won ticks=1842 digest=f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97`
- full_idle: `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=7000 digest=cec3eb7182baddc2d2215916f624759510c911bfec64ed249c4ef375189b40e9` (unchanged from plan 05-14, as expected: no shipped data changed)

The four goldens read 2599c7c2, f7a967ed, bfb05fc7 and f4b98093 (D-08 stop rule not triggered). `bash tools/lint.sh`: 446 files unchanged, no problems. Acceptance greps (GRUNT_PER_300: int = 2000, damage_per_300(200, 30), ttd_ticks(3000, GRUNT_PER_300), 450, ttd_ticks(100000000, sum), 15000, "Gap round G-05-2", damage_segment(6, 400) with no damage_segment(5, 1000), damage_segment(1, 100000), castle 20000 / 200 in both wall fixtures) all hold; test_wall_decision has 12 tests, as at ce3fcea.

## Task Commits

1. **Task 1: castle, gate, one-night, Shrine and squads fixtures at x100 (tracer)** - `f76ae00` (test)
2. **Task 2: wall fixtures and wall tests at the x100 scale** - `d4f26fb` (test)

**Plan metadata:** recorded in the docs(05-15) commit that follows this summary.

## Files Created/Modified

- `tests/fixtures/fixture_map_castle.tres`, `fixture_map_gate.tres`, `fixture_map_one_night.tres`, `fixture_map_shrine.tres`, `fixture_map_squads.tres` - health and damage lines x100 (Task 1)
- `tests/fixtures/fixture_map_walls.tres`, `fixture_map_walls_gap.tres` - castle health and damage x100 (Task 2)
- `tests/unit/test_wall_decision.gd` - GRUNT_PER_300 2000, health and damage literals x100, messages, header sentence
- `tests/integration/test_wall_dawn.gd`, `test_wall_detour.gd` - break and hurt amounts x100, one header sentence each

## Decisions Made

None beyond following the plan and the owner's locked G-05-2 decision.

## Deviations from Plan

None - plan executed exactly as written.

Note (not a deviation, a plan-verify defect): Task 2's automated verify runs `bash tools/test.sh -gselect=test_wall_d` and expects exit 0, but that substring also matches `tests/unit/test_wall_data_contract.gd`, which is outside this plan's file list and belongs to plan 05-17 (it pins the wall tiers at 30 / 60 / 90 and is in the planner's list of 70 failures, summary.txt line 282). The combined run therefore printed 5 scripts, 39 tests, 38 passing, 1 failing (test_health_per_segment_is_thirty_sixty_and_ninety: 3000 / 6000 / 9000 against 30 / 60 / 90) and exited 1. I did not touch that test. The four suites the plan means to prove (test_wall_decision, test_wall_dawn, test_wall_detour, test_wall_determinism) each ran alone and passed, listed above; the rest of the verify chain after that step (test_wall_behaviour, test_flow_field, the replays, lint) was run step by step and passed.

## Issues Encountered

The `test_wall_d` filter over-match described above; it clears when plan 05-17 re-pins test_wall_data_contract.

## Known Stubs

None (fixture data and test literals only).

## Threat Flags

None (no new surface). T-05-29 is mitigated by the golden-input identity check against ce3fcea and the four goldens replaying against their files; T-05-30 by changing only literal amounts and messages, with the expected tick counts and the test count (12) as at ce3fcea.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 05-16 and the later fix plans. The fixtures are at the shipped scale; the remaining planner failures (the wall data contract in 05-17 and the other contract, combat and HUD pins) are outside this plan. full_idle stays at cec3eb71 until plan 05-22 moves it by design.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*

## Self-Check: PASSED

All ten modified files exist with the x100 numbers; commits f76ae00 and d4f26fb exist on gsd/phase-01-foundation-day-loop; plan commit count measured 2 from the ledger (8a22c10 to d4f26fb).
