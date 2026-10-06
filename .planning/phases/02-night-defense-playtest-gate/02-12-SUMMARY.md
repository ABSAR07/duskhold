---
phase: 02-night-defense-playtest-gate
plan: 12
subsystem: economy
tags: [godot, gdscript, dawn-payout, base-income, map-config, vfx, gap-closure, g-02-1]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: RunManager dawn payout and BuildingSystem.dawn_income_by_spot (02-02), DawnPayoutVfx coin flight (02-01), the owner playtest diagnosis G-02-1 (02-UAT.md)
provides:
  - MapConfig.base_dawn_income (script default 0, shipped prototype map 1) and the reserved MapConfig.CASTLE_PAYOUT_KEY with their validate() rules
  - A dawn payout that adds the base income under the castle key after every building entry, even with no House standing
  - A castle coin origin in DawnPayoutVfx so the base income's coin flies from the castle to the gold counter
  - Every test that pinned "Houses are the only income" updated on purpose, read from the map data
affects: [phase-2-verification, playtest-gate, 02-13, 02-14, 02-15, 02-16, balance]

actuals:
  tokens: 5500
  tasks: 2
  commits: 4

plan_head_before: df50de2f13639258a88b1f6112548e865aa5e344
plan_head_after: cce9d16bd46a4c2f276b06b457aedd85ff97e66a

tech-stack:
  added: []
  patterns:
    - "A non-building gold source is listed in dawn_payout per_spot under a reserved StringName key, so the total always equals the sum of per_spot and the VFX can attribute it"
    - "Tests read the base income from the map (E2eSupport.waveless_prototype_map().base_dawn_income), never as a literal"

key-files:
  created:
    - tests/unit/test_map_validate_income.gd
    - tests/unit/test_map_validate_income.gd.uid
    - tests/e2e/test_dawn_payout_castle.gd
    - tests/e2e/test_dawn_payout_castle.gd.uid
  modified:
    - simulation/defs/map_config.gd
    - simulation/run/run_manager.gd
    - simulation/run/run_context.gd
    - data/maps/prototype_map.tres
    - ui/hud/dawn_payout_vfx.gd
    - tests/unit/test_dawn_income.gd
    - tests/unit/test_building_damage.gd
    - tests/unit/test_dawn_rebuild.gd
    - tests/e2e/test_dawn_payout.gd
    - tests/e2e/test_start_night_hold.gd
    - tests/integration/test_loop_gold_carryover.gd

key-decisions:
  - "The base income is paid every dawn on the shipped map (1 gold) under the castle key, listed last; towers still pay nothing (D-10), starting gold stays 4, no cost or House income changed"
  - "RunManager stores maxi(base_dawn_income, 0); a negative data value is reported by validate() and pays nothing at runtime"
  - "CASTLE_ANCHOR is 4.5 m (the top of the 5 m keep): at 8.5 m, above the turret, the default camera projects the coin above the top edge of the screen"
  - "A dawn that pays nothing is now only reachable with the base switched off, so test_a_dawn_that_pays_nothing_shows_no_coins_and_no_total zeroes the base on purpose (its subject is the no-coin path); the real dawn with the base has its own test"

patterns-established:
  - "New dawn payout sources go through dawn_payout per_spot with a reserved key that validate() keeps spots from using"

requirements-completed: [LOOP-04, LOOP-05]

coverage:
  - id: D1
    description: "Every dawn pays the map's base income under the castle key, after the building entries, even with no House; the shipped map pays 1 and a base of 0 pays exactly as before"
    requirement: LOOP-04
    verification:
      - kind: unit
        ref: "tests/unit/test_dawn_income.gd#test_a_dawn_with_no_houses_pays_only_the_base_income_and_the_day_still_returns"
        status: pass
      - kind: unit
        ref: "tests/unit/test_dawn_income.gd#test_a_dawn_with_the_base_switched_off_and_no_houses_pays_nothing"
        status: pass
      - kind: unit
        ref: "tests/unit/test_dawn_income.gd#test_houses_pay_their_current_tier_income_at_dawn"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (digest 2599c7c2 unchanged)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A House rebuilt this dawn still pays nothing while the castle's base income is paid; towers are never listed"
    requirement: LOOP-05
    verification:
      - kind: unit
        ref: "tests/unit/test_dawn_income.gd#test_a_house_rebuilt_this_dawn_pays_nothing_but_the_castle_still_pays_its_base"
        status: pass
      - kind: unit
        ref: "tests/unit/test_dawn_income.gd#test_a_tower_pays_nothing_and_is_not_listed"
        status: pass
    human_judgment: false
  - id: D3
    description: "MapConfig.validate() reports a negative base_dawn_income and a spot using the reserved castle id; the shipped map and the replay fixture report nothing"
    verification:
      - kind: unit
        ref: "tests/unit/test_map_validate_income.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "At dawn the base income's coin starts above the castle on screen, lands on the gold counter, and the HUD settles on the ledger"
    requirement: LOOP-04
    verification:
      - kind: e2e
        ref: "tests/e2e/test_dawn_payout_castle.gd#test_the_base_income_coin_flies_from_the_castle"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_dawn_payout_castle.gd#test_a_real_dawn_with_nothing_built_pays_the_base_income_coin"
        status: pass
    human_judgment: false
  - id: D5
    description: "The coin leaving the castle reads well on the real game camera (the anchor sits near the top of the keep, so the pop rises toward the top edge of a 720p screen)"
    verification: []
    human_judgment: true
    rationale: "Where a coin starts relative to the keep model is a visual judgment; the tests only prove the projection and the landing"

duration: 22min
completed: 2026-10-06
status: complete
---

# Phase 02 Plan 12: Base dawn income from the castle Summary

**A map-data base income (`MapConfig.base_dawn_income`, 1 on the prototype map) is paid every dawn under a reserved `castle` payout key, so a tower-first opening no longer ends at 0 gold, and its coin flies from the castle to the gold counter.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-10-06T11:43:46Z
- **Completed:** 2026-10-06T12:05:42Z
- **Tasks:** 2 (both TDD: RED then GREEN)
- **Files modified:** 15 (4 created)

## Accomplishments

- `MapConfig` gains `base_dawn_income` (default 0, shipped 1) and `CASTLE_PAYOUT_KEY = &"castle"`; `validate()` reports a negative income and any spot whose id is the reserved key.
- `RunManager._apply_dawn_payout` adds the base under the castle key after the building entries, then sums and grants as before, so `dawn_payout`'s total always equals its per_spot sum. `RunContext` passes the map's value; a `RunManager` built without the argument pays no base.
- `DawnPayoutVfx.spot_screen_point` projects the castle (plus `CASTLE_ANCHOR`) for the castle key, with the same behind-camera and no-camera fallbacks; every other key is unchanged.
- The smoke golden digest `2599c7c2...` is unchanged and no fixture, golden or building data file was touched.

## Task Commits

1. **Task 1 RED** - `b6c47d5` test(02-12): add failing tests for the base dawn income
2. **Task 1 GREEN** - `d63125c` feat(02-12): pay a base income from the castle at every dawn
3. **Task 2 RED** - `05f8bd8` test(02-12): add failing tests for the castle coin at dawn
4. **Task 2 GREEN** - `cce9d16` feat(02-12): fly the base income's coin from the castle at dawn

## TDD Gate Compliance

RED then GREEN for both tasks. RED evidence: Task 1's RED run failed 9 tests on their assertions (payout dictionaries lacking the castle entry, the shipped map's base 0, validate() returning no error); every other unit test passed. Task 2's RED run failed `test_the_base_income_coin_flies_from_the_castle` on its assertion (start point mid-screen, expected the castle projection). In both RED commits the bare `base_dawn_income` / `CASTLE_PAYOUT_KEY` and `CASTLE_ANCHOR` declarations are included with no behavior, only so the new tests parse (a typed access to a missing member is a parse error, which would not be a valid RED).

## Mutation probes

- **Task 1:** replaced the `per_spot[MapConfig.CASTLE_PAYOUT_KEY] = _base_dawn_income` line in `RunManager._apply_dawn_payout` with `pass`; `test_dawn_income.gd` then failed 6 of its 12 tests. Restored.
- **Task 2:** made `spot_screen_point` skip the castle branch (`if false and spot_id == ...`); `test_the_base_income_coin_flies_from_the_castle` failed (1 of 2 in `test_dawn_payout_castle.gd`). Restored.

## Tests updated for the base income (all on purpose, base read from the map, none deleted)

- `tests/unit/test_dawn_income.gd`: payout dictionaries, totals, key order and gold now include the castle; the "no Houses pays nothing" test became `test_a_dawn_with_no_houses_pays_only_the_base_income_and_the_day_still_returns`; added the base-off, no-argument RunManager and rebuilt-House tests
- `tests/unit/test_building_damage.gd`: `test_a_dawn_after_a_loss_pays_only_the_survivors`
- `tests/unit/test_dawn_rebuild.gd` (not listed in the plan): five payout and gold assertions on the waveless context (the one-night fixture keeps base 0 and is unchanged)
- `tests/integration/test_loop_gold_carryover.gd`: three dawn payouts, expected gold and the gold-delta test
- `tests/e2e/test_dawn_payout.gd`: `_expected_amounts`, `_coins_launched`, total and coin-count expectations include the castle coin; `test_a_dawn_that_pays_nothing_shows_no_coins_and_no_total` zeroes the base (see decisions)
- `tests/e2e/test_start_night_hold.gd` (not listed in the plan): `test_a_build_hold_is_cancelled_when_the_night_starts` adds the base to its expected dawn gold
- Left unchanged on purpose: `test_starting_gold_buys_two_houses_or_one_tower_but_not_both` and `test_tower_has_two_tiers_with_attack_data_and_no_income`

## Replay results

- `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (matches the golden)
- `bash tools/replay.sh --scenario=full_idle --twice`: `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=4178 digest=265423254dd3f12f7b9258c22822b25848de0c388e9919f4fffcc7e29a73b3a1` (was ticks 6244, digest a25aa7fd...; the change is expected because the balanced bot now earns the base income)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pin test moved out of test_prototype_map_data.gd**
- **Found during:** Task 1 (lint)
- **Issue:** `test_prototype_map_data.gd` already holds gdlint's 20 public methods, so the planned `test_the_shipped_map_pays_a_base_income_of_one_gold_every_dawn` failed `max-public-methods`.
- **Fix:** the test lives in `tests/unit/test_map_validate_income.gd` (and also pins starting gold 4); `test_prototype_map_data.gd` is untouched.
- **Commit:** b6c47d5

**2. [Rule 3 - Blocking] New castle coin tests live in a new e2e file**
- **Found during:** Task 2 (lint)
- **Issue:** `tests/e2e/test_dawn_payout.gd` is at the 20 public method cap (its own header says so), so the two new tests could not be added there.
- **Fix:** both are in `tests/e2e/test_dawn_payout_castle.gd` with the helpers they need. The acceptance grep for those two names in `test_dawn_payout.gd` therefore matches the new file instead.
- **Commit:** 05f8bd8

**3. [Rule 1 - Bug] Tests outside the plan's list broke on the new shipped data**
- **Found during:** Task 1 and Task 2 (unit and full suite)
- **Issue:** `test_dawn_rebuild.gd` (5 assertions, Task 1) and `test_start_night_hold.gd` (1 assertion, Task 2) expected House-only dawn gold.
- **Fix:** added the base read from the map, as the plan directs for such tests. Task 1 commit d63125c, Task 2 commit cce9d16.

**4. [Judgment] CASTLE_ANCHOR is 4.5, not above the turret**
- **Found during:** Task 2 RED
- **Issue:** the keep is 5 m tall with a 3 m turret; at 8.5 m the default camera projects the anchor above the top screen edge (y -9.9 of a 64 px viewport), at 4.5 m it is on screen (y 3.3). The plan's interface value of 4.5 is kept.

**Total deviations:** 3 auto-fixed (2 blocking, 1 bug), 1 judgment. **Impact:** none on behavior; the test files differ from the plan's file list.

## Known Stubs

None.

## Threat Flags

None. T-02-27 (negative base: validate() plus the runtime clamp) and T-02-28 (reserved castle key: validate()) are mitigated and tested.

## Self-Check: PASSED

- Created files exist: test_map_validate_income.gd, test_dawn_payout_castle.gd and their `.uid` sidecars (committed).
- Commits b6c47d5, d63125c, 05f8bd8, cce9d16 are on the branch.
- Acceptance greps hold: `base_dawn_income: int = 0` and `CASTLE_PAYOUT_KEY` in map_config.gd; `CASTLE_PAYOUT_KEY` and `base_dawn_income` in run_manager.gd; `map_config.base_dawn_income` in run_context.gd; `base_dawn_income = 1` and `starting_gold = 4` in prototype_map.tres; `CASTLE_ANCHOR` and `CASTLE_PAYOUT_KEY` in dawn_payout_vfx.gd.
- `git log b6c47d5^..HEAD -- data/buildings tests/fixtures tests/golden` prints nothing.
- `bash tools/test.sh`: 758 tests, 758 passing (baseline 745 plus 13 new); `bash tools/lint.sh`: clean; smoke golden matches; full_idle agrees across both runs.
