---
phase: 05-castle-center-economy-depth
plan: 19
subsystem: tests
tags: [x100-rescale, felling-blows, gap-closure, G-05-2, gut, godot]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "Plan 05-18: PLAT-01 pin inputs and combat tests at the x100 scale"
provides:
  - "Seven test scripts whose own felling blows fell the shipped House, Tower, Barracks, wall segment and footman at the x100 scale, with every assertion and test count unchanged"
affects: [05-20, 05-24]

actuals:
  tokens: 3000
  tasks: 2
  commits: 2

plan_head_before: a898cdba5361f775afff52e2c463f3fb1ec75b8d
plan_head_after: e03752a2dc7b08ac0e552be63c8f8f67d164ee00

tech-stack:
  added: []
  patterns:
    - "A felling blow is sized to the shipped health it must exceed (100000 over the 1200 to 5000 buildings and 3000 segment, 99900 to leave one 1000-health footman standing)"

key-files:
  created: []
  modified:
    - tests/unit/test_build_requirements.gd
    - tests/unit/test_dawn_rebuild.gd
    - tests/unit/test_run_stats.gd
    - tests/unit/test_nav_grid.gd
    - tests/unit/test_squad_respawn.gd
    - tests/unit/test_debug_overlay_squad_section.gd
    - tests/e2e/test_order_markers.gd

key-decisions:
  - "Hurts that still hurt and kill amounts that still kill were left alone (dawn-rebuild hurts at 177, 180, 182, 312, 413; test_squad_respawn's unit KILL_DAMAGE 1000 and its Barracks stage helper), per the plan's Flagged Assumption"

requirements-completed: [BLDG-08, META-08]

coverage:
  - id: D1
    description: "The day, dawn, run-stats and nav tests fell a shipped House, Tower and wall segment with 100000"
    requirement: "BLDG-08"
    verification:
      - kind: unit
        ref: "bash tools/test.sh -gselect=test_build_requirements 15/15; test_dawn_rebuild 15/15; test_run_stats 10/10; test_nav_grid 12/12"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Barracks and squad tests fell a shipped Barracks (100000) and footmen (100000, 99900) at the x100 scale"
    requirement: "META-08"
    verification:
      - kind: unit
        ref: "bash tools/test.sh -gselect=test_squad_respawn 14/14; test_debug_overlay_squad_section 10/10; test_order_markers (e2e, headless) 10/10"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-10-25
status: complete
---

# Phase 5 Plan 19: Felling blows at the x100 scale Summary

**Seven test scripts now fell the shipped House, Tower, Barracks, wall segment and footman with blows 100 times larger (100000, and 99900 for the footman), so each checks what it checked before the rescale; no assertion, hurt or test count changed.**

## Performance

- **Duration:** about 10 min
- **Completed:** 2026-10-25T18:24Z
- **Tasks:** 2
- **Files modified:** 7 (tests only)

## Accomplishments

- Tracer (Task 1): the four day, dawn, run-stats and nav blows moved; all four suites pass (logs build/exec05-19_<script>.log), so the tracer gate passed and Task 2 followed.
- Task 2: the Barracks and squad blows moved; the e2e order-marker script passes headless on the first run (no other Godot process alive).
- No non-test file changed: `git diff --quiet HEAD -- data simulation native presentation ui tools tests/fixtures tests/golden` was clean before each commit.

## Task Commits

1. **Task 1 (tracer): day, dawn, run-stats and nav falls** - `a19407e` (test)
2. **Task 2: Barracks and squad falls** - `e03752a` (test)

## Blows Changed (old to new)

| File:line | Old | New |
|---|---|---|
| tests/unit/test_build_requirements.gd:139 (HOUSE_A) | `damage_building(HOUSE_A, 1000)` | `100000` |
| tests/unit/test_dawn_rebuild.gd:412 (HOUSE_B) | `damage_building(HOUSE_B, 1000)` | `100000` (hurts at 177, 180, 182, 312 and the 2 at 413 untouched) |
| tests/unit/test_run_stats.gd:144 (tower_1) | `damage_building(&"tower_1", 1000)` | `100000` |
| tests/unit/test_nav_grid.gd:176 (segment 2) | `damage_segment(2, 1000)` | `100000` |
| tests/unit/test_squad_respawn.gd:157 (BARRACKS) | `damage_building(BARRACKS, 1000)` | `100000` (unit KILL_DAMAGE 1000 stays) |
| tests/unit/test_debug_overlay_squad_section.gd:14 | `const KILL_DAMAGE: int = 1000` | `100000` |
| tests/e2e/test_order_markers.gd:37 | `const KILL_DAMAGE: int = 999` | `99900` |

Line numbers are the pre-edit lines; each file also gained a two-line `##` header note (after the file's doc comment, under 100 characters), shifting later lines by two.

## Test Counts (ce3fcea vs now)

test_build_requirements 15/15, test_dawn_rebuild 15/15, test_run_stats 10/10, test_nav_grid 12/12, test_squad_respawn 14/14, test_debug_overlay_squad_section 10/10, test_order_markers 10/10.

## Suite Results

Each run was one `-gselect` and each name was confirmed in build/test-results/gut-junit.xml right after:

- test_build_requirements: 15/15 passing, 50 asserts
- test_dawn_rebuild: 15/15, 149 asserts
- test_run_stats: 10/10, 71 asserts
- test_nav_grid: 12/12, 168 asserts
- test_squad_respawn: 14/14, 648 asserts
- test_debug_overlay_squad_section: 10/10, 78 asserts
- test_order_markers: 10/10, 156 asserts (run alone, headless)
- `bash tools/lint.sh`: "446 files would be left unchanged", "Success: no problems found" (after each task)

## Decisions Made

None beyond the plan; the felling blows follow the interfaces block.

## Deviations from Plan

None - plan executed exactly as written. The planner's reference diff (05-19.diff) agrees with the plan on every blow and line; the only difference is the plan's added header notes.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None (tests only; T-05-36 mitigated: only felling blows and header notes changed, every assertion and expected value stays, counts equal ce3fcea).

## Next Phase Readiness

Ready for plan 05-20 (HUD tests and shot list). The eight scripts the Flagged Assumption names as still killing at exactly 1000 were not touched and not run; the full suite remains plan 05-24's.

## Self-Check: PASSED

- All seven modified test files exist; commits `a19407e` and `e03752a` found in `git log`; acceptance strings present (`damage_building(HOUSE_A, 100000)`, `damage_building(HOUSE_B, 100000)`, `damage_building(&"tower_1", 100000)`, `damage_segment(2, 100000)`, `damage_building(BARRACKS, 100000)`, `const KILL_DAMAGE: int = 100000`, `const KILL_DAMAGE: int = 99900`).

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*
