---
phase: 05-castle-center-economy-depth
plan: 13
subsystem: balance-data
tags: [x100-rescale, shipped-data, tres, gap-closure, G-05-2, godot]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "Round-1 shipped data at ce3fcea (the round's base commit) and the owner's 2026-10-25 x100 decision on UAT G-05-2"
provides:
  - "Ten shipped data files at the x100 health and damage scale: king, sword, footman, archer, grunt, skirmisher, tower, Shrine, castle center and the prototype map's tier-I castle"
affects: [05-14, 05-15, 05-16, 05-17, 05-18, 05-19, 05-20, 05-21, 05-22, 05-23, 05-24]

actuals:
  tokens: 330
  tasks: 2
  commits: 2

plan_head_before: 0c22b3c4674eb65cd5fa2b003a6514d17e065a8b
plan_head_after: 4749f2b9e973b350585d3285dbeef62e95e1d2e5

tech-stack:
  added: []
  patterns:
    - "Exact-x100 check: rebuild each .tres from git show ce3fcea:<file> with only six field names multiplied (awk), diff against the working file"

key-files:
  created: []
  modified:
    - data/king/king.tres
    - data/king/sword.tres
    - data/units/footman.tres
    - data/units/archer.tres
    - data/enemies/grunt.tres
    - data/enemies/ranged.tres
    - data/buildings/tower.tres
    - data/buildings/shrine.tres
    - data/buildings/castle_center.tres
    - data/maps/prototype_map.tres

key-decisions:
  - "Followed the owner's locked G-05-2 decision: every health and damage number x100, gold untouched, StatStack and its one half-up rounding untouched (D-15); no .gd file and no script @export default moved (D-08)"
  - "Task 1 tracer verify (exact-x100, map test, smoke and army goldens) ran green in automated mode, so the plan auto-continued into Task 2 with no human stop"

patterns-established:
  - "Half-flipped data window: the shipped game is consistent only after plan 05-14 completes the flip; nothing is pushed, exported or run through full_idle in between"

requirements-completed: [BLDG-08, META-08]

coverage:
  - id: D1
    description: "Sword, footman, archer, grunt and skirmisher carry every health and damage number at 100 times its ce3fcea value, every other line byte-identical"
    requirement: "BLDG-08"
    verification:
      - kind: other
        ref: "exact-x100 awk rebuild from git show ce3fcea:<file> diffed against the working file (empty diff for all five files)"
        status: pass
      - kind: unit
        ref: "bash tools/test.sh -gselect=test_prototype_map_data (20 of 20)"
        status: pass
    human_judgment: false
  - id: D2
    description: "King, towers, Shrine, castle tiers II to IV and the map's tier-I castle at the x100 scale, regen fraction, synergy percent, costs, incomes and pond untouched"
    requirement: "META-08"
    verification:
      - kind: other
        ref: "exact-x100 awk rebuild over all ten files (empty diff for each); git diff ce3fcea shows 26 changed lines, all in the six field names"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke|army|walls|economy --twice --expect-file=tests/golden/<s>.json (REPLAY_OK, digests unchanged)"
        status: pass
    human_judgment: false

duration: 5 min
completed: 2026-10-25
status: complete
---

# Phase 05 Plan 13: x100 flip of the first ten shipped data files Summary

**The king, sword, both soldiers, both enemies, towers, Shrine and castle moved to the owner's x100 health and damage scale in ten .tres files (26 changed lines, nothing else touched), with the shipped map still validating and all four frozen goldens replaying byte-identical.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-25T09:49:31Z
- **Completed:** 2026-10-25T09:54:49Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Task 1 (tracer): sword, footman, archer, grunt and skirmisher at x100, loaded through the shipped map (test_prototype_map_data).
- Task 2: king, tower tiers I and II, Shrine, castle tiers II to IV and the map's tier-I castle at x100.
- The data is half-flipped by design: fighters, towers, Shrine and castle are at x100 while buildings (House, Barracks, Archery, Wall, the economy buildings) and Royal Training are still at the old scale. The shipped game is consistent only after plan 05-14 flips the other nine files. Nothing is pushed or exported, and full_idle was not run (plan 05-14 is its first run and records it).

## Numbers changed (old to new)

| File | Field | Old | New |
|------|-------|-----|-----|
| data/king/king.tres | max_health | 50 | 5000 (regen_fraction_per_second 0.1 stays) |
| data/king/sword.tres | attack_damage | 5 | 500 |
| data/king/sword.tres | slam_damage | 4 | 400 |
| data/units/footman.tres | max_health | 10 | 1000 |
| data/units/footman.tres | attack_damage | 1 | 100 |
| data/units/archer.tres | max_health | 6 | 600 |
| data/units/archer.tres | attack_damage | 1 | 100 |
| data/enemies/grunt.tres | max_health | 6 | 600 |
| data/enemies/grunt.tres | attack_damage | 2 | 200 |
| data/enemies/ranged.tres (Skirmisher) | max_health | 4 | 400 |
| data/enemies/ranged.tres (Skirmisher) | attack_damage | 2 | 200 |
| data/buildings/tower.tres tier 1 | attack_damage / max_health | 3 / 50 | 300 / 5000 |
| data/buildings/tower.tres tier 2 | attack_damage / max_health | 6 / 70 | 600 / 7000 |
| data/buildings/shrine.tres | attack_damage / max_health | 3 / 30 | 300 / 3000 |
| data/buildings/shrine.tres | wake_threshold_hp | 100 | 10000 (synergy_percent 20 stays) |
| data/buildings/castle_center.tres tier 2 | attack_damage / max_health | 3 / 100 | 300 / 10000 |
| data/buildings/castle_center.tres tier 3 | attack_damage / max_health | 4 / 140 | 400 / 14000 |
| data/buildings/castle_center.tres tier 4 | attack_damage / max_health | 5 / 200 | 500 / 20000 |
| data/maps/prototype_map.tres | castle_max_health | 70 | 7000 |
| data/maps/prototype_map.tres | castle_attack_damage | 2 | 200 |

Ratios held: footman 100 against sword 500 (Phase 3 D-07) and footman 1000 against king 5000 (D-06); a footman's 100 against a grunt's 600 is still six blows. Largest base is castle tier IV's 20000, inside StatStack.MAX_ABS_BASE (100000).

## Verification results

Exact-x100 check (the plan's awk rebuild of each file from `git show ce3fcea:<file>` with only the six field names multiplied, diffed against the working file with carriage returns ignored): empty diff, printed as EXACT_X100, for all ten files (data/king/king.tres, sword.tres, data/units/footman.tres, archer.tres, data/enemies/grunt.tres, ranged.tres, data/buildings/tower.tres, shrine.tres, castle_center.tres, data/maps/prototype_map.tres). `git diff ce3fcea -- data` shows 10 files, 26 insertions and 26 deletions. `git diff --quiet ce3fcea -- simulation native presentation ui tools tests` exits 0 (no script, tool, test or golden input changed).

`bash tools/test.sh -gselect=test_prototype_map_data`: 1 script, 20 tests, 20 passing, 113 asserts, exit 0 (run after Task 1 and again after Task 2; suite present in build/test-results/gut-junit.xml).

REPLAY_OK lines observed after Task 2 (all `--twice --expect-file`, exit 0; smoke and army also observed after Task 1):

- smoke: seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f
- army: seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4
- walls: seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58
- economy: seed=1 outcome=won ticks=1842 digest=f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97

The four goldens read 2599c7c2, f7a967ed, bfb05fc7 and f4b98093, unchanged (D-08 stop rule not triggered). `bash tools/lint.sh` exit 0 (446 files unchanged, no problems). The full suite was not run (red by design until plan 05-20; it is plan 05-24's).

Acceptance criteria re-checked by grep after Task 2: king 5000 with regen 0.1; tower 300/5000 and 600/7000; shrine 300, 3000, 10000 and synergy_percent 20; castle 10000/14000/20000 and 300/400/500; map 7000 and 200, with pond_center, pond_radius and the Harbor spot lines unchanged.

## Task Commits

1. **Task 1: sword, soldiers and enemies at x100 (tracer)** - `443a282` (feat)
2. **Task 2: king, towers, Shrine and castle at x100** - `4749f2b` (feat)

**Plan metadata:** recorded in the docs(05-13) commit that follows this summary.

## Files Created/Modified

- `data/king/king.tres`, `data/king/sword.tres` - king health, sword blow and slam at x100
- `data/units/footman.tres`, `data/units/archer.tres` - soldier health and blow at x100
- `data/enemies/grunt.tres`, `data/enemies/ranged.tres` - enemy health and blow at x100
- `data/buildings/tower.tres`, `data/buildings/shrine.tres`, `data/buildings/castle_center.tres` - tower, Shrine and castle tier numbers at x100, Shrine wake threshold 10000
- `data/maps/prototype_map.tres` - tier-I castle health and arrow at x100

## Decisions Made

None beyond following the plan and the owner's locked G-05-2 decision.

## Deviations from Plan

None - plan executed exactly as written.

Note (not a deviation): the planner's 05-13.diff and this plan agree. The sorted set of changed lines in `git diff ce3fcea -- data` is identical to the 52 changed lines of the planner's patch, so there is no disagreement to record. Flagged Assumptions relied on: the half-flipped window between plans 05-13 and 05-14 (no run of the scaled game in between), and gold not rescaled (no gold number touched).

## Issues Encountered

None.

## Known Stubs

None (data-only plan).

## Threat Flags

None (no new surface). T-05-25 (half-flipped data) is mitigated by the back-to-back chain: nothing pushed or exported, full_idle not run. T-05-26 (a mis-typed product or missed field) is mitigated by the exact-x100 check, which printed an empty diff for all ten files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 05-14 (flip the other nine shipped data files: buildings, walls and Royal Training, then the first replay of the scaled game). The shipped data is inconsistent until then; do not play the bots or full_idle before 05-14 finishes.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*

## Self-Check: PASSED

All ten files exist and carry the x100 numbers; commits 443a282 and 4749f2b exist on gsd/phase-01-foundation-day-loop; plan commit count measured 2 from the ledger (0c22b3c to 4749f2b).
