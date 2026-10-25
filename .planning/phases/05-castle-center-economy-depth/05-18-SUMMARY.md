---
phase: 05-castle-center-economy-depth
plan: 18
subsystem: tests
tags: [x100-rescale, plat-01-pins, combat-tests, gap-closure, G-05-2, gut, godot]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "Plans 05-13 to 05-17: the shipped data, fixtures, stress map and contract pins at the x100 health and damage scale"
provides:
  - "All nine PLAT-01 *_pins scripts green at the x100 scale with no PINS table, 64-hex digest, frame count or 'most' count edited (their four inputs moved, or are frozen at the Phase 4 numbers)"
  - "Five combat and crowd-overlay tests whose own amounts keep their meaning at the x100 scale"
affects: [05-19, 05-20, 05-24]

actuals:
  tokens: 4000
  tasks: 2
  commits: 2

plan_head_before: 12f9263c994eae69482df08aa0b57a9b6065fc2b
plan_head_after: 0b680fa50375038a031f247db9ee55ab9de54e90

tech-stack:
  added: []
  patterns:
    - "Frozen-input helper: a pinned-world builder deep-copies the shipped map and sets the one scaled number back to the value the pins were computed on, instead of re-pinning"

key-files:
  created: []
  modified:
    - tests/unit/test_unit_fill_pins.gd
    - tests/unit/test_field_route_pins.gd
    - tests/unit/test_wall_geometry_pins.gd
    - tests/unit/test_structure_decision_pins.gd
    - tests/unit/test_wall_solids.gd
    - tests/unit/test_castle_attack.gd
    - tests/unit/test_enemy_targeting.gd
    - tests/unit/test_squad_archers.gd
    - tests/unit/test_melee_breaks_to_target.gd
    - tests/unit/test_debug_overlay_crowd_sections.gd

key-decisions:
  - "The wall-decision pins keep the Phase 4 wall health (PHASE_FOUR_WALL_HEALTH [30, 60, 90]) on a duplicate_deep copy of the map; re-pinning on 3000/6000/9000 would pin the native twin against itself (plan's Flagged Assumption)"
  - "test_enemy_targeting names the shipped-scale castle as const CASTLE_HEALTH 4000 on its own fresh MapConfig; the def default of 40 is untouched (D-08)"

requirements-completed: [BLDG-08, META-08]

coverage:
  - id: D1
    description: "The nine PLAT-01 pin scripts pass unedited at the x100 scale (unit-fill hurt run 100 / 9900, route and wall-geometry BREAK_DAMAGE 100000000, wall decision worlds frozen at 30 / 60 / 90)"
    requirement: "BLDG-08"
    verification:
      - kind: unit
        ref: "bash tools/test.sh -gselect=_pins (9 scripts, 58 tests, 58 passing, 719 asserts)"
        status: pass
      - kind: other
        ref: "git diff ce3fcea over the nine pin scripts, grep for added or removed 64-hex / \"most_ / \"frames lines: no match"
        status: pass
    human_judgment: false
  - id: D2
    description: "test_wall_solids, test_castle_attack, test_enemy_targeting, test_squad_archers, test_melee_breaks_to_target and test_debug_overlay_crowd_sections check what they checked before at the x100 scale; native parity suites still pass"
    requirement: "META-08"
    verification:
      - kind: unit
        ref: "-gselect runs: test_wall_solids 15/15, test_native 135/135 (12 scripts), test_castle_attack 14/14, test_enemy_targeting 15/15, test_squad_archers 6/6, test_melee_breaks_to_target 10/10, test_debug_overlay_crowd_sections 12/12"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-10-25
status: complete
---

# Phase 5 Plan 18: PLAT-01 pin inputs and combat test amounts at the x100 scale Summary

**All nine native-parity pin scripts pass byte-unedited at the x100 scale (four inputs scaled or frozen at the Phase 4 wall health), and five combat and crowd-overlay tests carry their own amounts at the new scale.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-25T13:38:54Z
- **Completed:** 2026-10-25T13:46:26Z
- **Tasks:** 2
- **Files modified:** 10 (tests only)

## Accomplishments

- Tracer (Task 1): the four pin inputs and the wall-solid test moved; `-gselect=_pins` ran 9 scripts, 58 tests, 58 passing, 719 asserts (log build/exec05-18_pins.log). No pin failed, so no stop rule fired.
- Task 2: the five combat tests re-amounted; every suite passes with its test count unchanged; lint clean.
- No non-test file changed (`git diff --quiet HEAD -- data simulation native presentation ui tools tests/fixtures tests/golden` clean before each commit).

## Task Commits

1. **Task 1: Tracer, four PLAT-01 pin inputs and the wall-solid test** - `7d8dc5f` (test)
2. **Task 2: castle, targeting, archer, melee-break and crowd-overlay tests** - `0b680fa` (test)

**Plan metadata:** committed separately (docs: complete plan)

## Amounts Changed (old to new)

| File | Change |
|---|---|
| test_unit_fill_pins.gd | `_hurt_run` per-hit damage 1 to 100; `KILL_DAMAGE` 99 to 9900 |
| test_field_route_pins.gd | `BREAK_DAMAGE` 1000000 to 100000000 |
| test_wall_geometry_pins.gd | `BREAK_DAMAGE` 1000000 to 100000000 |
| test_structure_decision_pins.gd | new `const PHASE_FOUR_WALL_HEALTH: Array[int] = [30, 60, 90]` (with `##` lines); `decision_bytes` builds `map` as `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` of the loaded map and sets each tier's `max_health` of the BuildingDef with id `&"wall"` from the const before BuildingSystem and WallSystem are built; `world_bytes` and all pins untouched |
| test_wall_solids.gd | `damage_segment(0, 1000)` and `(2, 1000)` to 100000 |
| test_castle_attack.gd | `DAMAGE` 2 to 200 (grunt dies on the third hit, skirmisher on the second; TOUGH_HEALTH 100000 stays) |
| test_enemy_targeting.gd | new `const CASTLE_HEALTH: int = 4000` set on the fresh MapConfig in `before_each`; `castle_max_health` 3 to 300 and 2 to 200; `_enemies.damage(far/near, 100, ...)` to 10000 |
| test_squad_archers.gd | `DUMMY_HEALTH` 500 to 50000 |
| test_melee_breaks_to_target.gd | `damage_segment(segment, 1000)` to 100000 |
| test_debug_overlay_crowd_sections.gd | `FIVE_GRUNTS_PER_300` 100 to 10000; expected "3.0 s" stays; message now "3000 hp against 10000 per 10 s is 90 ticks" |

Every file also gained the plan's `##` header note (the four pin scripts the extra "pins were not edited" sentence; wall-decision wording is shared by all four, as the plan's interfaces block gives it).

## Pin Results

All nine scripts passed in one run: test_enemy_fill_pins 5, test_field_route_pins 9, test_projectile_fill_pins 4, test_separation_pins 10, test_structure_decision_pins 8, test_stuck_pins 4, test_target_query_pins 7, test_unit_fill_pins 4, test_wall_geometry_pins 7. No PINS table, 64-hex digest, frame count or "most" count was edited: `git diff ce3fcea` over the nine scripts with the plan's grep (`^[-+][^-+].*([0-9a-f]{64}|"most_|"frames")`) returned no line. test_enemy_fill_pins, test_projectile_fill_pins, test_target_query_pins, test_separation_pins and test_stuck_pins carry no diff at all since ce3fcea.

## Test Counts (ce3fcea vs now)

test_unit_fill_pins 4/4, test_field_route_pins 9/9, test_wall_geometry_pins 7/7, test_structure_decision_pins 8/8, test_wall_solids 15/15, test_castle_attack 14/14, test_enemy_targeting 15/15, test_squad_archers 6/6, test_melee_breaks_to_target 10/10, test_debug_overlay_crowd_sections 12/12.

## Suite Results

- `-gselect=_pins`: 9 scripts, 58/58, exit 0
- `-gselect=test_wall_solids`: 15/15; `-gselect=test_native`: 12 scripts, 135/135 (test_native_structures present in the JUnit XML)
- `-gselect=test_castle_attack` 14/14; `test_enemy_targeting` 15/15; `test_squad_archers` 6/6; `test_melee_breaks_to_target` 10/10; `test_debug_overlay_crowd_sections` 12/12
- `bash tools/lint.sh`: "446 files would be left unchanged", "Success: no problems found" (after each task)
- Each name confirmed in build/test-results/gut-junit.xml right after its own run.

## Decisions Made

See key-decisions above. The frozen-input approach follows the plan's Flagged Assumption; the planner's reference diff set the tiers inline with a literal list, the plan names a const instead and the plan was followed.

## Deviations from Plan

None - plan executed exactly as written. Two notes that are not deviations:

- The planner's reference diff differs from the plan only in the frozen-world helper (inline `[30, 60, 90][index]` there, `PHASE_FOUR_WALL_HEALTH[index]` and a `source` local here) and in the plan's added header notes; every amount agrees.
- Plan frontmatter artifact `contains: castle_max_health = 4000` for test_enemy_targeting: the file holds `const CASTLE_HEALTH: int = 4000` (the acceptance criterion's string), set through `_map.castle_max_health = CASTLE_HEALTH`; the doc comment above the const reads `castle_max_health = 4000`.

## Issues Encountered

Three of the ten files (test_wall_geometry_pins, test_structure_decision_pins, test_melee_breaks_to_target) carry CRLF line endings in the working tree; the edit script detected the ending per file and preserved it (git warns that CRLF will be replaced by LF on touch, which matches eol=lf). A first run of the edit script aborted on the first CRLF file after two files had been edited; the script was fixed and re-run skipping the two done files (no file was edited twice).

## Known Stubs

None.

## Threat Flags

None (tests only; T-05-34 mitigated by the diff-grep over the nine pin scripts, T-05-35 by unchanged test counts and assertions).

## Next Phase Readiness

Ready for plan 05-19 (the next gap-wave group of kill amounts). The full suite stays plan 05-24's.

## Self-Check: PASSED

- All ten modified test files exist; commits `7d8dc5f` and `0b680fa` found in `git log`.
- Acceptance criteria re-checked: PHASE_FOUR_WALL_HEALTH and `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` in test_structure_decision_pins; BREAK_DAMAGE 100000000 in both route and geometry scripts; KILL_DAMAGE 9900; DAMAGE 200; DUMMY_HEALTH 50000; CASTLE_HEALTH 4000, 300 and 200; FIVE_GRUNTS_PER_300 10000 with "3.0 s"; test counts equal to ce3fcea.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*
