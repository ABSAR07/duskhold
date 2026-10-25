---
phase: 05-castle-center-economy-depth
plan: 17
subsystem: contract-tests
tags: [x100-rescale, contract-tests, labels, gap-closure, G-05-2, gut, godot]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "Plans 05-13 and 05-14: the shipped data at the x100 health and damage scale; 05-16: stress map and tools"
provides:
  - "Ten contract and label test scripts that pin every shipped health and damage number at its x100 value, each with the gap round G-05-2 header note"
  - "Phase 3 D-07 honoured at the x100 ratio (footman 100 a blow)"
  - "Labels read the scaled numbers as they are (no hidden division): 'Health 10000 · Arrow 300 · 2 gold at dawn', '+25% king health, +100 king damage', '12 segments, 3000 health each', 'asleep 3000 of 10000'"
affects: [05-18, 05-19, 05-20, 05-22, 05-24]

actuals:
  tokens: 2800
  tasks: 2
  commits: 2

plan_head_before: 1f6bae5c6dcf7444c558e194f96e6b9c5ce16588
plan_head_after: 11b59dfb7d221bc55ad57b9c52b227861dca7fb6

tech-stack:
  added: []
  patterns:
    - "Exact-string, line-ending-preserving edits of pinned literals, with a wrapped gap-round header paragraph appended to each file's leading ## block"

key-files:
  created: []
  modified:
    - tests/unit/test_weapon_def.gd
    - tests/unit/test_military_data_contract.gd
    - tests/unit/test_castle_data_contract.gd
    - tests/unit/test_map_validate_castle.gd
    - tests/unit/test_castle_label.gd
    - tests/unit/test_wall_data_contract.gd
    - tests/unit/test_economy_data_contract.gd
    - tests/unit/test_ability_data.gd
    - tests/unit/test_spot_label_model.gd
    - tests/unit/test_economy_overlay_sections.gd

key-decisions:
  - "Labels show the scaled numbers as they are (Flagged Assumption of the plan; the owner may reverse it at the next UAT)"
  - "The test-local weapon in test_weapon_def._armed_weapon (slam_damage 4, a bad-slam builder not a shipped pin) stays, as in the planner's reference diff"

requirements-completed: [BLDG-08, META-08]

coverage:
  - id: D1
    description: "Sword, footman, tower, castle, grunt and castle-label pins moved to the x100 scale"
    requirement: "BLDG-08"
    verification:
      - kind: unit
        ref: "tests/unit/test_weapon_def.gd, test_military_data_contract.gd, test_castle_data_contract.gd, test_map_validate_castle.gd, test_castle_label.gd (five -gselect runs, all pass)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Wall, economy buildings, Shrine, Royal Training card, wall spot labels and Economy overlay pins moved to the x100 scale"
    requirement: "META-08"
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_data_contract.gd, test_economy_data_contract.gd, test_ability_data.gd, test_spot_label_model.gd, test_economy_overlay_sections.gd (five -gselect runs, all pass)"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-10-25
status: complete
---

# Phase 5 Plan 17: Contract and Label Pins at the x100 Scale Summary

**Ten contract and label test scripts re-pinned to the x100 health and damage scale (sword 500, footman 100, castle 10000 to 20000, Wall 3000 to 9000, Shrine 10000 wake threshold), labels showing the scaled numbers as they are, every test count unchanged.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-25T13:14:02Z
- **Completed:** 2026-10-25T13:21:30Z
- **Tasks:** 2
- **Files modified:** 10 (tests only)

## Accomplishments

- Task 1 (tracer): the fighters' and the castle's pins and the castle label the player reads now say what the scaled data holds.
- Task 2: the wall, economy, card, spot-label and overlay pins follow, ending at the Economy overlay's "asleep 3000 of 10000".
- Every file carries the "Gap round G-05-2" header note (wrapped over `##` lines of at most 100 characters); no assertion removed or weakened; no data, simulation, UI, tool, fixture or golden file touched.

## Pins changed (old -> new), per file

Task 1:
- `test_weapon_def.gd`: passive damage 5 -> 500 (value and message); slam damage 4 -> 400 (value and message); header "(3 m, 5 damage, ...) and slam (4 m, 4 damage, ...)" -> 500 and 400.
- `test_military_data_contract.gd`: FOOTMAN_DAMAGE 1 -> 100; comment "passive 5" -> "passive 500"; message "strikes for 1" -> 100; Tower I damage 3 -> 300, Tower I health 50 -> 5000, Tower II damage 6 -> 600 (values and messages). KING_HEALTH_PER_FOOTMAN 5 unchanged (a ratio).
- `test_castle_data_contract.gd`: HEALTH [100, 140, 200] -> [10000, 14000, 20000]; ARROW_DAMAGE [3, 4, 5] -> [300, 400, 500]; header numbers updated (the map's 70 -> 7000, the map's arrow 200 named).
- `test_map_validate_castle.gd`: GRUNT_HEALTH 6 -> 600; message -> "a grunt stays at 600 hp (500 would let the king's 500 one-shot it)". GRUNT_SHOTS 3 and SKIRMISHER_SHOTS 2 unchanged.
- `test_castle_label.gd`: tier II line "Health 100 · Arrow 3 · 2 gold at dawn" -> "Health 10000 · Arrow 300 · 2 gold at dawn"; Royal Training line "+1 king damage" -> "+100 king damage".

Task 2:
- `test_wall_data_contract.gd`: HEALTHS [30, 60, 90] -> [3000, 6000, 9000]; header "30 / 60 / 90 (a linear +30)" -> "3000 / 6000 / 9000 (a linear +3000)".
- `test_economy_data_contract.gd`: MAX_HEALTH 20 -> 2000 (message "2000 health"); MILL_HEALTHS [15, 20, 25] -> [1500, 2000, 2500]; FIELD_HEALTH 8 -> 800; HARBOR_HEALTHS [18, 24] -> [1800, 2400]; SHRINE_DAMAGE 3 -> 300; SHRINE_HEALTH 30 -> 3000; SHRINE_WAKE_THRESHOLD 100 -> 10000; header "health 20" -> 2000.
- `test_ability_data.gd`: Royal Training row FLAT 1 -> 100; KING_BASE_DAMAGE 3 -> 300; KING_DAMAGE_AFTER_BOTH 8 -> 800.
- `test_spot_label_model.gd`: wall lines "12 segments, 30 / 60 / 90 health each" -> 3000 / 6000 / 9000, "16 segments, 30 health each" -> 3000; max-tier message "and 90 health" -> "and 9000 health".
- `test_economy_overlay_sections.gd`: SHRINE_THRESHOLD 100 -> 10000; message "shrine_west: asleep 30 of 100" -> "asleep 3000 of 10000".

## Tests renamed

- `test_royal_training_reads_plus_25_percent_health_and_plus_1_damage` -> `..._plus_100_damage` (test_castle_label)
- `test_health_per_segment_is_thirty_sixty_and_ninety` -> `test_health_per_segment_is_three_six_and_nine_thousand` (test_wall_data_contract)
- `test_royal_training_then_headsmans_edge_makes_king_damage_8_in_either_order` -> `..._800_in_either_order` (test_ability_data)
- `test_a_wall_at_max_tier_names_its_ninety_health` -> `test_a_wall_at_max_tier_names_its_nine_thousand_health` (test_spot_label_model)

## Test counts (func test_ at ce3fcea, before this plan, after)

test_weapon_def 10/10/10; test_military_data_contract 7/7/7; test_castle_data_contract 8/8/8; test_map_validate_castle 14/14/14; test_castle_label 12/12/12; test_wall_data_contract 7/7/7; test_economy_data_contract 20/20/20; test_ability_data 15/15/15; test_spot_label_model 15/15/15; test_economy_overlay_sections 18/18/18.

## Verification results (each in its own foreground run, name confirmed in gut-junit.xml)

- test_weapon_def: 10 tests, 10 passing, 44 asserts
- test_military_data_contract: 7/7, 86 asserts
- test_castle_data_contract: 8/8, 56 asserts
- test_map_validate_castle: 14/14, 68 asserts
- test_castle_label: 12/12, 33 asserts
- test_wall_data_contract: 7/7
- test_economy_data_contract: 20/20
- test_ability_data: 15/15
- test_spot_label_model: 15/15
- test_economy_overlay_sections: 18/18
- `git diff --quiet HEAD -- data simulation native presentation ui tools tests/fixtures tests/golden` clean after each task; `bash tools/lint.sh` exit 0 after each task ("446 files would be left unchanged", gdlint "no problems found"); the "Gap round G-05-2" grep passes in all ten files.
- Replays, golden digests and the full suite were not in scope (plan 05-24 and the orchestrator's gate).

## Task Commits

1. **Task 1 (tracer): the fighters' and the castle's pins** - `0124b47` (test)
2. **Task 2: the wall, economy, card, spot-label and overlay pins** - `11b59df` (test)

**Plan metadata:** the docs commit that carries this summary, STATE.md and ROADMAP.md.

## Decisions Made

- Labels show the scaled numbers as they are, as the plan's Flagged Assumption says; the owner can reverse this at the next UAT.
- `test_weapon_def._armed_weapon` keeps its test-local slam damage 4: it builds a fresh WeaponDef to test the arming rule, it names no shipped number (the planner's reference diff leaves it too).

## Deviations from Plan

None - plan executed exactly as written. The planner's reference diff and the plan agree on every number; the plan additionally renames the four tests, updates messages and headers (which the diff leaves as they were), and adds the header note. The test_economy_data_contract header's "health 20" is also updated.

Two minor in-flight corrections, not deviations: a first edit pass produced a header line over 100 characters in test_castle_data_contract and test_wall_data_contract and a message line of 102 characters in test_map_validate_castle; each was rewrapped before the run and commit.

## Issues Encountered

None. One helper-script pattern for the economy header spanned a line break and was corrected before any edit to that file was written.

## Known Stubs

None.

## Threat Flags

None (tests only; T-05-33 mitigated: every re-pinned script carries the header note, test counts unchanged).

## Next Phase Readiness

Ready for plan 05-18. Plan 05-22 (the Harbor move) edits test_economy_data_contract next and lowers the Harbor's health; plan 05-21 recuts the Prosperity, Golden Age and Headsman's Edge cards in test_ability_data.

## Self-Check: PASSED

- All ten modified test files exist and carry the header note (grep passes).
- Commits `0124b47` and `11b59df` found in `git log`.
- All acceptance criteria re-checked: FOOTMAN_DAMAGE 100 and "passive 500"; [10000, 14000, 20000] and [300, 400, 500]; castle label strings and renamed test; [3000, 6000, 9000]; HARBOR_HEALTHS [1800, 2400] and SHRINE_WAKE_THRESHOLD 10000; FLAT 100, KING_BASE_DAMAGE 300, KING_DAMAGE_AFTER_BOTH 800; "12 segments, 3000 health each"; SHRINE_THRESHOLD 10000; test counts equal to ce3fcea.
