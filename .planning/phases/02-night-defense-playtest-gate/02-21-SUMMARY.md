---
phase: 02-night-defense-playtest-gate
plan: 21
subsystem: king-movement-tuning
tags: [godot, gdscript, king, movement, tuning, gap-closure, g-02-18, d-03, tdd]
status: complete

requires:
  - phase: 02-night-defense-playtest-gate
    provides: 02-13 sprint change (12 m/s, acceleration 60), 02-20 round-3 close-out baselines (829 tests, smoke golden, full_idle digest)
provides:
  - "The shipped king walks at 7.5 m/s (1.5x the 5 m/s of round 3) and still sprints at exactly 12.0 m/s: walk_speed 7.5, sprint_multiplier 1.6, acceleration unchanged at 60"
  - "D-03 in 01-CONTEXT.md carries a dated 2026-10-07 amendment (the original 20-30 s line kept and marked superseded); the ride-time contract test pins 12 to 18 s"
  - "Tests pin walk 7.5, multiplier 1.6, a sprint of exactly 12.0 and the KingDef script defaults"
  - "KingDef script defaults and doc comments on the owner's numbers"
affects: [02-22 round-4 screenshots and export, owner-playtest-gate, verify-work]

requirements-completed: [KING-01, DEV-05]

actuals:
  tokens: 2250
  tasks: 2
  commits: 5

plan_head_before: 43e367d1185f7032660926dfe209458bf514a86a
plan_head_after: 87fbcb75622ce498f6af03e65f8210a240fe917c

tech-stack:
  added: []
  patterns:
    - "A tuning decision that supersedes a locked design decision amends it with a dated sub-bullet and marks the old line superseded (D-05 precedent), and the contract test is renamed to carry the new band"
    - "7.5 x 1.6 and 5.0 x 2.4 both round to exactly 12.0 in doubles, so an exact assert_eq on the sprint is valid and bites on a wrong multiplier or wrong walk"

key-files:
  created: []
  modified:
    - .planning/phases/01-foundation-day-loop/01-CONTEXT.md
    - data/king/king.tres
    - simulation/defs/king_def.gd
    - tests/unit/test_king_movement_config.gd
    - tests/unit/test_prototype_map_data.gd

key-decisions:
  - "Walk 5.0 -> 7.5 m/s and sprint_multiplier 2.4 -> 1.6 keeps the sprint at exactly 12 m/s; acceleration stays 60 (owner decision 2026-10-07, G-02-18)"
  - "The map is not grown to keep the old ride budget; D-03 is amended instead (edge to edge 14.67 s at walk, 9.17 s at sprint)"
  - "The frozen smoke fixture king (walk 5.0, multiplier 1.6) and tests/golden/smoke.json are untouched"

coverage:
  - id: D1
    description: "Shipped king walks at 7.5 m/s and sprints at exactly 12.0 m/s (walk_speed 7.5, sprint_multiplier 1.6, acceleration 60)"
    requirement: "KING-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_king_movement_config.gd#test_walk_speed_is_seven_and_a_half_metres_per_second"
        status: pass
      - kind: unit
        ref: "tests/unit/test_king_movement_config.gd#test_the_sprint_stays_exactly_twelve_metres_per_second"
        status: pass
      - kind: unit
        ref: "tests/unit/test_king_movement_config.gd#test_a_king_letting_go_at_full_sprint_stops_inside_the_build_radius"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-03 dated amendment and the 12 to 18 s ride-time contract test"
    requirement: "DEV-05"
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_data.gd#test_ride_across_the_map_takes_twelve_to_eighteen_seconds"
        status: pass
    human_judgment: false
  - id: D3
    description: "KingDef script defaults equal the shipped king, with doc comments on the owner's numbers"
    requirement: "KING-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_king_movement_config.gd#test_the_script_defaults_are_the_shipped_movement"
        status: pass
    human_judgment: false
  - id: D4
    description: "Whether a 7.5 m/s walk with the unchanged 12 m/s sprint feels right to ride"
    verification: []
    human_judgment: true
    rationale: "Movement feel is the owner's judgment at the round-4 gate (02-22); no test asserts it"

duration: 25 min
completed: 2026-10-07
---

# Phase 02 Plan 21: King Walk 1.5x Summary

**The king walks at 7.5 m/s and still sprints at exactly 12 m/s (walk_speed 7.5, sprint_multiplier 1.6), D-03 is amended with the owner's decision, and tests lock all three numbers with the smoke golden and full_idle digest unchanged.**

## Performance

- **Duration:** about 25 min (start time not captured at dispatch; estimated from the commit times)
- **Completed:** 2026-10-07T10:44Z (last production commit)
- **Tasks:** 2 (each RED commit then GREEN commit, plus the D-03 docs commit)
- **Files modified:** 5

## Accomplishments

- `data/king/king.tres`: exactly two lines changed (`walk_speed` 5.0 to 7.5, `sprint_multiplier` 2.4 to 1.6). `King.move_speed(def, true)` is exactly 12.0 before and after.
- D-03 amended on 2026-10-07 the way D-05 was: the original "20-30 s" line is kept (en dash intact) and marked superseded; riding edge to edge is now about 15 s at walk (14.67 s) and about 9 s at sprint (9.17 s); the map is not grown. `test_ride_across_the_map_takes_twelve_to_eighteen_seconds` pins 12 to 18 s (renamed, the file stays at 20 tests).
- `test_king_movement_config.gd` now pins walk 7.5, multiplier 1.6 and an exact 12.0 sprint, keeps the 1.5 x 8 m/s floor, the stopping-distance test and the acceleration-60 pin, and gained a script-defaults pin (9 tests).
- `KingDef` defaults (7.5, 1.6, 60.0) and doc comments now state the owner's decision (G-02-18), the exactly-12 sprint and both stopping distances (1.2 m at sprint, 0.47 m at walk).

## Task Commits

1. **Task 1: walk 7.5, sprint 12, D-03 follows**
   - `912b253` docs: D-03 amendment
   - `08eb979` test (RED): walk, multiplier, 12.0 sprint, ride band
   - `6dca6c3` feat (GREEN): the two data lines
2. **Task 2: KingDef defaults and docs**
   - `53d339e` test (RED): script defaults pin
   - `87fbcb7` feat (GREEN): defaults and doc comments

**Plan metadata:** the docs(02-21) commit that carries this SUMMARY, STATE.md and ROADMAP.md.

## RED evidence

Task 1, on the shipped data (5.0 / 2.4) before the data change, exactly the three predicted failures:

- `test_walk_speed_is_seven_and_a_half_metres_per_second`: `[5.0] expected to equal [7.5]`
- `test_sprint_is_at_least_one_and_a_half_times_the_original_sprint`: `[2.4] expected to equal [1.6]` (multiplier assertion; the 1.5 x 8 floor passed)
- `test_ride_across_the_map_takes_twelve_to_eighteen_seconds`: `[22.0] expected to be between [12.0] and [18.0]`
- `test_the_sprint_stays_exactly_twelve_metres_per_second` passed on both sides by design (5.0 x 2.4 is also exactly 12.0).

Task 2, before the script default change: `test_the_script_defaults_are_the_shipped_movement` failed on walk (`[5.0]` vs `[7.5]`) and multiplier (`[2.4]` vs `[1.6]`); acceleration already matched.

## Mutation probes (each restored, `git diff -- data/king/king.tres` again showed only the two intended lines)

- **(a) multiplier 2.4 with walk 7.5 (an 18 m/s sprint):** 3 failures: the multiplier assertion (`[2.4]` vs `[1.6]`), `test_the_sprint_stays_exactly_twelve_metres_per_second` (`[18.0]` vs `[12.0]`) and `test_a_king_letting_go_at_full_sprint_stops_inside_the_build_radius` (`[2.7]` not under `[2.5]`).
- **(b) walk 5.0 with multiplier 1.6 (an 8 m/s sprint):** the movement suite failed the walk pin (`[5.0]` vs `[7.5]`), the 1.5 x 8 floor (`[8.0]` not at least `[12.0]`) and the 12.0 pin (`[8.0]` vs `[12.0]`); the map suite failed the ride band (`[22.0]` outside 12 to 18).
- **(c) KingDef script default `sprint_multiplier` back to 2.4:** `test_the_script_defaults_are_the_shipped_movement` failed (`[2.4]` vs `[1.6]`); restored to 1.6 and the movement suite is 9 of 9.

## Two-line data diff

```
-walk_speed = 5.0
-sprint_multiplier = 2.4
+walk_speed = 7.5
+sprint_multiplier = 1.6
```

## Verification results (final tree, 87fbcb7)

- `bash tools/test.sh`: exit 0, 831 tests in 95 scripts, all passing (829 plus the 12.0 pin and the defaults pin). test_king_movement_config, test_prototype_map_data, test_king_ride, test_balance_acceptance, test_sim_rules_guard and test_fast_forward are all present in gut-junit.xml.
- Task 1's four suites run one by one: movement 8 of 8, map 20 of 20, king_ride 10 of 10, playtest_strategies 14 of 14.
- `bash tools/lint.sh`: no problems (167 files unchanged).
- Smoke replay matches `tests/golden/smoke.json` (`--twice --expect-file`, exit 0): `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
- full_idle, unchanged: `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac`
- `git diff --stat 43e367d..HEAD` touches only the five files in files_modified; nothing under tests/golden, tests/fixtures, data/maps, data/tuning, data/buildings or data/enemies changed; no file was deleted.

No bot re-measurement was run: the diagnosis measured that the bots only ever sprint (exactly 12.0 m/s before and after, as 5.0 x 2.4 and 7.5 x 1.6 are both exactly 12.0 in doubles) or never move, and the 10-seed report was byte-identical on this exact edit. The unchanged full_idle digest and the passing test_balance_acceptance are this plan's own check of that.

## Decisions Made

- The sprint stays exactly 12 m/s, so the multiplier moves 2.4 to 1.6 when the walk moves 5.0 to 7.5 (owner decision, clarified once).
- D-03 is amended, not the map grown (moving spots would move every balance number).

## Deviations from Plan

None - plan executed exactly as written. (Minor wording: the ride-band assert message was shortened to "ride time in s (D-03 as amended 2026-10-07)" to stay under the 100-character lint limit; the plan allowed the amendment note in the message.)

## Issues Encountered

None. A first sed for the D-03 italic note did not match because `.` in a C-locale sed matches one byte and the en dash is three; it was fixed with `.*` and the diff then showed only the one line changed and one sub-bullet added.

## Known Stubs

None.

## Threat Flags

None. T-02-45 and T-02-46 are mitigated as planned (movement pins plus the unchanged golden and digest; dated amendment with the original line kept).

## Next Phase Readiness

Ready for 02-22: re-run the screenshots and export the build on the 7.5 / 1.6 king for the owner's round-4 replay.

## Self-Check: PASSED

- All five modified files exist and carry the intended content (`walk_speed = 7.5`, `sprint_multiplier = 1.6`, `acceleration = 60.0`, `Amended 2026-10-07`, `20–30 s at normal speed` kept, `walk_speed: float = 7.5`, `G-02-18`, `0.47 m`).
- Commits 912b253, 08eb979, 6dca6c3, 53d339e and 87fbcb7 exist on gsd/phase-01-foundation-day-loop; `git rev-list --count 43e367d..HEAD` was 5 at SUMMARY write.
