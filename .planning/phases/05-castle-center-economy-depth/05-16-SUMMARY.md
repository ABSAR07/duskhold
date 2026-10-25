---
phase: 05-castle-center-economy-depth
plan: 16
subsystem: stress-tools
tags: [x100-rescale, stress-map, gate-stress, plat-01-pins, tres, gap-closure, G-05-2, godot]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "Plan 05-15: the non-golden fixtures and wall tests at the x100 scale"
provides:
  - "The tools-only stress map (five data files and stress_map.tres) at the x100 health and damage scale, every stress ratio unchanged"
  - "The stress tools' king (10000000) and the bench's castle (1000000000) scaled with them"
  - "test_stress_map_data pinned at HUGE_HEALTH 10000000 and the stress tower's 100"
affects: [05-17, 05-18, 05-19, 05-20, 05-24]

actuals:
  tokens: 1500
  tasks: 2
  commits: 2

plan_head_before: 017f125eb2ebc154fdaf957e47d57312a9c408da
plan_head_after: 2f706f3ec1a85a354029ca892d11a348366ad4a6

tech-stack:
  added: []
  patterns:
    - "Exact-x100 awk rebuild from git show ce3fcea:<file> diffed against the working file, now over the six stress data files"

key-files:
  created: []
  modified:
    - tools/stress/data/stress_barracks.tres
    - tools/stress/data/stress_footman.tres
    - tools/stress/data/stress_grunt.tres
    - tools/stress/data/stress_tower.tres
    - tools/stress/data/stress_wall.tres
    - tools/stress/stress_map.tres
    - tools/stress/step_attribution.gd
    - tools/stress/step_bench.gd
    - tools/stress/stress_night.gd
    - tests/unit/test_stress_map_data.gd

key-decisions:
  - "Followed the owner's locked G-05-2 decision: the stress grunt strikes for the shipped 200 and the footman for 100; every huge pool x100; the stress castle stays unarmed"
  - "The gate stress digest (raw health) moved e448ffdb -> eb319f09 and is recorded only; no test or CI step pins it"

requirements-completed: [BLDG-08, META-08]

coverage:
  - id: D1
    description: "Six stress data files exactly their ce3fcea text with max_health and attack_damage (castle_max_health in stress_map.tres) x100; castle_attack_damage stays 0"
    requirement: "BLDG-08"
    verification:
      - kind: other
        ref: "exact-x100 awk rebuild from git show ce3fcea:<file> over the six files (empty diff each, ok=1)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Gate stress keeps every crossing statistic of the pre-round line"
    requirement: "META-08"
    verification:
      - kind: other
        ref: "bash tools/gate_stress.sh --twice -> GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Stress pin re-pinned and the PLAT-01 enemy and arrow fill pins pass unedited on the scaled stress night"
    requirement: "META-08"
    verification:
      - kind: unit
        ref: "bash tools/test.sh -gselect=test_enemy_fill_pins (5 of 5), test_projectile_fill_pins (4 of 4), test_stress (36 of 36: test_stress_map_data 16, test_stress_tool_args 20)"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-10-25
status: complete
---

# Phase 5 Plan 16: Stress Map and Tools at the x100 Scale Summary

**The tools-only stress map, its three tools and test_stress_map_data follow the owner's x100 rescale (stress grunt 200 a blow, every huge pool 10000000), so the gate stress crosses 300 of 300 with the exact pre-round statistics and the unedited PLAT-01 fill pins still pass.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-25T12:50:08Z
- **Completed:** 2026-10-25T12:55:30Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Six stress data files at x100 (old to new): stress_grunt max_health 100000 to 10000000, attack_damage 2 to 200; stress_footman max_health 100000 to 10000000, attack_damage 1 to 100; stress_tower attack_damage 1 to 100, max_health 100000 to 10000000; stress_barracks max_health 100000 to 10000000; stress_wall max_health 100000 to 10000000; stress_map castle_max_health 100000 to 10000000 (castle_attack_damage 0 stays 0). Exact-x100 check against ce3fcea: ok=1, no NOT_EXACT_X100 line for any of the six files.
- Gate stress, before the round (05-VERIFICATION.md): `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdb...`
- Gate stress, after Task 1 (`bash tools/gate_stress.sh --twice`, exit 0, both runs identical): `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=eb319f092e059b341cd186ce3c75306e1703a46913310d2f5b563119143efaa8`. Only the digest moved (it records raw health); recorded, pinned nowhere.
- Tool constants: KING_HEALTH 100000 to 10000000 in step_attribution.gd, step_bench.gd and stress_night.gd; step_bench.gd CASTLE_HEALTH 10000000 to 1000000000; the header lines naming the king's health updated (step_attribution.gd line 5, step_bench.gd lines 12 and 193).
- test_stress_map_data: HUGE_HEALTH 10000000, the stress tower's `attack_damage` 100 ("real hits of 100 through PendingHits"), a three-line `Gap round G-05-2` header; still 16 tests as at ce3fcea.
- PLAT-01 pins: `git diff ce3fcea --stat -- tests/unit/test_enemy_fill_pins.gd tests/unit/test_projectile_fill_pins.gd` is empty (and `git diff --quiet ce3fcea` over all six pin files passed). test_enemy_fill_pins 5 of 5 passing (30 asserts), test_projectile_fill_pins 4 of 4 (17 asserts), `-gselect=test_stress` 36 of 36 (324 asserts); both stress scripts and both pin scripts appear in the JUnit XML of their own runs.
- Four goldens byte-identical, `--twice`:
  - `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
  - `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`
  - `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58`
  - `REPLAY_OK scenario=economy seed=1 outcome=won ticks=1842 digest=f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97`
- `bash tools/lint.sh` exits 0 (446 files unchanged, no problems found).

## Task Commits

1. **Task 1 (tracer): stress map health and damage at x100, gate stress 300 of 300** - `8b23ca5` (chore)
2. **Task 2: stress pin and stress tools' king and castle at x100, fill pins hold unedited** - `2f706f3` (test)

**Plan metadata:** docs commit follows (SUMMARY, STATE, ROADMAP, REQUIREMENTS).

## Files Created/Modified

- `tools/stress/data/stress_{barracks,footman,grunt,tower,wall}.tres` - health and damage x100
- `tools/stress/stress_map.tres` - castle_max_health 10000000, castle unarmed
- `tools/stress/step_attribution.gd`, `step_bench.gd`, `stress_night.gd` - king (and bench castle) pools scaled, header lines updated
- `tests/unit/test_stress_map_data.gd` - HUGE_HEALTH, tower damage and gap-round header

## Decisions Made

None beyond the owner's locked G-05-2 decision; followed the plan as specified.

## Deviations from Plan

None - plan executed exactly as written. Cross-check against the planner's reference diff (05-16.diff): every data and constant hunk is identical; the diff carries no header sentence or doc-line edits, which the plan adds and this plan did (the plan wins).

## Issues Encountered

None. No Godot process was alive before the gate stress or the suites; no wrapper exited 3 (native library current). The edits used sed on exact lines (working files are LF), verified by the exact-x100 check and `git diff`.

## Known Stubs

None.

## Threat Flags

None. No new surface; T-05-31 (overflow) mitigated: 10000000 and 1000000000 are inside int64, and wall segment health 10000000 is under the PackedInt32Array ceiling; the gate stress and fill pins ran. T-05-32 mitigated: the six pin files are identical to ce3fcea.

## Next Phase Readiness

Plan 05-17 onward can proceed. The crowd-stress screenshot's king (tools/screenshot/shot_crowd_scenarios.gd) is plan 05-20's. The suite remains red by design in groups owned by plans 05-17 to 05-20; the full suite is plan 05-24's.

## Self-Check: PASSED

- Commits 8b23ca5 and 2f706f3 exist; all ten files modified as listed; acceptance criteria of both tasks re-checked (constants by grep, fill pins and stress suites passing, goldens unmoved, lint clean).

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*
