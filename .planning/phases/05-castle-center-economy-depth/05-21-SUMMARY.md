---
phase: 05-castle-center-economy-depth
plan: 21
subsystem: economy-cards
tags: [godot, gdscript, gut, castle-cards, stat-stack, g-05-2, recurrence-guard]

requires:
  - phase: 05-castle-center-economy-depth
    provides: plans 05-13 to 05-20, the x100 health and damage rescale finished in data, fixtures, tools, tests and HUD (full_idle at cec3eb71)
provides:
  - Prosperity +2 castle gold at dawn (was +1)
  - Golden Age +4 castle gold at dawn beside its unchanged +25% shrine damage (was +2)
  - Headsman's Edge x2 king damage at a x1.25 attack interval (was x1.5), flavour reworded
  - tests/unit/test_card_resolution.gd, the G-05-2 recurrence guard (8 tests) built from the shipped files
  - the per-card before and after table and the blows-to-kill table below, for plan 05-23's report
affects: [05-22, 05-23, 05-24]

actuals:
  tokens: 22000
  tasks: 2
  commits: 2

plan_head_before: b1c99cd48c90450a229c1991e10523b328b09661
plan_head_after: 6852027aa600c404b3a50f18b6b8adb9c76e723b

tech-stack:
  added: []
  patterns:
    - "Recurrence guard: bases read from the shipped .tres files, one fresh StatStack per card, exact value from the documented formula, a half-to-one-and-a-half band, a negative control"

key-files:
  created:
    - tests/unit/test_card_resolution.gd
    - tests/unit/test_card_resolution.gd.uid
  modified:
    - data/abilities/prosperity.tres
    - data/abilities/golden_age.tres
    - data/abilities/headsmans_edge.tres
    - tests/unit/test_ability_data.gd
    - tests/unit/test_castle_label.gd

key-decisions:
  - "Prosperity +1 to +2, Golden Age income +2 to +4, Headsman's Edge interval x1.5 to x1.25: the three cards the x100 rescale cannot help (flat gold, and a slower blow against one-hit kills) are recut in data only (D-02); StatStack untouched (D-15)"
  - "The guard's band is 0.5 to 1.5 times the written effect, plus a half-unit half-up rounding check, so a card that rounds to nothing or doubles fails"
  - "The guard pins every integer health and damage base between 100 and StatStack.MAX_ABS_BASE; castle.base_income (gold, not rescaled) is exempt"

requirements-completed: [BLDG-08, META-08]

coverage:
  - id: D1
    description: "Prosperity pays +2 castle gold at dawn, pinned in test_ability_data and read from data in the castle label test"
    requirement: BLDG-08
    verification:
      - kind: unit
        ref: "tests/unit/test_ability_data.gd#test_tier_two_cards_carry_the_pinned_numbers"
        status: pass
      - kind: unit
        ref: "tests/unit/test_castle_label.gd#test_a_gold_source_and_a_health_source_show_in_the_label_too"
        status: pass
    human_judgment: false
  - id: D2
    description: "Golden Age +4 gold beside +25% shrine damage; Headsman's Edge x2 damage at x1.25 interval with the label line 'x2 king damage, x1.25 king attack interval'"
    requirement: BLDG-08
    verification:
      - kind: unit
        ref: "tests/unit/test_ability_data.gd#test_headsmans_edge_slows_the_blow_by_a_quarter"
        status: pass
      - kind: unit
        ref: "tests/unit/test_castle_label.gd#test_headsmans_edge_reads_two_multipliers"
        status: pass
    human_judgment: false
  - id: D3
    description: "Recurrence guard over every card modifier at every shipped base, the Shrine synergy, the 100 to MAX_ABS_BASE scale bound and a negative control"
    requirement: META-08
    verification:
      - kind: unit
        ref: "tests/unit/test_card_resolution.gd (8 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Whether the recut cards (Prosperity +2, Golden Age +4, Headsman's Edge x1.25) are each a viable pick at their tier"
    verification: []
    human_judgment: true
    rationale: "No bot reaches castle tier III or IV and the numbers are Claude's draft under D-02; the owner judges them in plan 05-24's re-judge"

duration: 30min
completed: 2026-10-25
status: complete
---

# Phase 5 Plan 21: Card recuts and the G-05-2 recurrence guard Summary

**Prosperity +2, Golden Age income +4 and Headsman's Edge x1.25 recut in three .tres files, and a new 8-test guard (test_card_resolution) that runs every card against every shipped base from the shipped data, with a Shrine-synergy case, a 100-to-MAX_ABS_BASE scale bound and a negative control.**

## Performance

- **Duration:** about 30 min
- **Started:** 2026-10-25T19:20:28Z
- **Completed:** 2026-10-25T19:50Z (SUMMARY write)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files modified:** 7 (3 data, 3 tests modified or created, 1 .uid)

## Accomplishments

- **The three recuts, old to new, with the owner's reason** (UAT G-05-2, owner 2026-10-24: "all alternatives at an upgrade level are mostly viable options ... not overly weak even in a case where its not an ideal option"; Prosperity is too weak):

| Card | File value | Old | New | Reason |
|---|---|---|---|---|
| Prosperity | castle.base_income FLAT | +1 | +2 | flat gold is worth its value times the paying dawns left; the debug session measured +2 matching Masons on wins and gold while +1 trailed (plan 05-23 re-measures) |
| Golden Age | castle.base_income FLAT (its +25% shrine.damage stays) | +2 | +4 | tier IV comes about one paying dawn after tier II's day-6 pick, so +4 pays about what Prosperity's +2 pays at its tier |
| Headsman's Edge | king.attack_interval MULTIPLIER (x2 king.attack_damage stays first) | 150 (x1.5) | 125 (x1.25) | the old card was a third slower for no extra kill on skirmishers and after Royal Training; the worst case is now a fifth slower, the best case (grunt without Royal Training, 1000 against 600) is one blow instead of two at 1.25 times the interval; flavour is now "Heavier cuts that land only a little slower." |

- **The guard, tests/unit/test_card_resolution.gd (8 tests, built from the shipped files, no literal base):**
  1. test_every_stat_a_card_names_has_a_shipped_base_list
  2. test_every_registered_stat_has_bases_of_its_own_kind (all 18 registered stats have a base list; int stats hold ints, float stats floats)
  3. test_every_integer_modifier_moves_its_stat_in_the_written_direction_at_every_base
  4. test_every_integer_modifier_lands_within_half_to_one_and_a_half_of_its_text (band plus rounded once, half up)
  5. test_every_float_modifier_lands_exactly_and_moves_its_stat (float_value, 1e-6)
  6. test_golden_age_on_top_of_the_shrine_synergy_adds_a_quarter_of_the_base (synergy_percent read from shrine.tres, one other awake Shrine, two Shrine plots asserted on the shipped map)
  7. test_every_integer_health_and_damage_base_lies_between_100_and_the_stack_bound (StatStack.MAX_ABS_BASE; gold exempt; largest shipped base is castle tier IV's 20000)
  8. test_the_band_rejects_a_quarter_on_a_base_of_one_and_accepts_it_on_one_hundred (negative control: +25% on 1 rounds to no change and fails, on 100 passes, a doubled effect fails)
- Bases collected from the prototype map's buildings list and castle fields, data/king (king and sword), the map's units and enemies, and castle_center.tres tiers II to IV; one fresh StatStack per card.
- The guard passed on its first run on the rescaled data, as the plan expected; test 8 is what proves it bites at the old scale.
- Task 1 trace: Prosperity's +2 from `prosperity.tres` through the CARDS pin and the castle label (which now reads the card's value from data) to the guard's cases.

## Task Commits

1. **Task 1 (tracer): Prosperity +2, pins, label read from data, the guard's first five tests** - `7aff759` (feat)
2. **Task 2 (tdd): Golden Age +4, Headsman's Edge x1.25, pins, label line, guard completed with tests 6 to 8** - `6852027` (feat)

**Plan metadata:** the docs(05-21) SUMMARY commit that follows.

### TDD record for Task 2 (RED then GREEN, one commit as the plan asks for one commit per task)

- **RED** (re-pins and the three new guard cases written first, data still old): `test_ability_data` 12/15 passing, failing: `test_headsmans_edge_slows_the_blow_by_a_quarter` ([1.2] expected [1.0]), `headsmans_edge modifier 1 value` ([150] expected [125]), `golden_age modifier 0 value` ([2] expected [4]); `test_castle_label` 11/12 passing, failing `test_headsmans_edge_reads_two_multipliers` ("x1.5 ..." expected "x1.25 ..."). The guard's three new cases passed against the old data (as the plan states: the recut moves no number the guard bands, and the negative control proves the band at the old scale rather than at the old cards). One real bug in my own test was caught in this run (an unescaped `%` in an assert message) and fixed before GREEN.
- **GREEN** (data recut): `test_ability_data` 15/15, `test_castle_label` 12/12, `test_card_resolution` 8/8; full verify below.

## Verification (every result from my own runs, logs under build/exec05-21_*.log)

Task 2 final verify (the Task 1 verify was identical except the castle_tiers and build_choice suites; both exited 0):

| Suite filter | Scripts | Tests | Passing | Asserts |
|---|---|---|---|---|
| test_card | 6 | 66 | 66 | 1014 |
| test_ability_data | 1 | 15 | 15 | 280 |
| test_castle_label | 1 | 12 | 12 | 33 |
| test_stat | 6 | 68 | 68 | 537 |
| test_choice_validation | 1 | 20 | 20 | 65 |
| (extra) test_castle | 7 | 64 | 64 | 335 |
| (extra) test_shrine | 8 | 75 | 75 | 788 |
| (extra) test_playtest_strategies | 2 | 27 | 27 | 451 |
| (extra) test_build_choice | 1 | 18 | 18 | 59 |
| (extra) test_card_row | 2 | 29 | 29 | 155 |

Task 1 verify also ran test_card (63 tests passing then), test_castle_tiers 16/16, test_choice_validation 20/20, test_build_choice 18/18.

Replays (identical after Task 1 and after Task 2):

- `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
- `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`
- `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58`
- `REPLAY_OK scenario=economy seed=1 outcome=won ticks=1842 digest=f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97`
- `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=7000 digest=cec3eb7182baddc2d2215916f624759510c911bfec64ed249c4ef375189b40e9` (unchanged: no bot picks the three cards, none reaches tier IV)

`bash tools/lint.sh`: gdformat (one `--fix` pass on the new guard, 447 files unchanged afterwards) and gdlint "Success: no problems found". `git diff --quiet HEAD -- tests/fixtures tests/golden` clean. The full suite is plan 05-24's, once (the orchestrator's gate after this plan expects 280 scripts).

Acceptance criteria re-run: prosperity value 2; golden_age 4 and 25; headsmans_edge 200 and 125; test_ability_data holds `Gap round G-05-2` and `test_headsmans_edge_slows_the_blow_by_a_quarter`; test_card_resolution reads castle_center through the map, calls `int_value(` and `float_value(`, references `StatStack.MAX_ABS_BASE`, holds the negative control, 8 tests, no line over 100 characters.

## Per-card before and after (printed by a scratch copy of the debug session's card_probe.gd, through the real StatStack)

"Before" is the ce3fcea state: health and damage bases divided by 100, gold and floats as they were, and the ce3fcea card numbers (only Royal Training's flat king damage +1, Prosperity +1, Golden Age income +2 and Headsman's Edge interval x1.5 differ from the shipped files). "After" is the shipped files now. Only the three cards of this plan changed in this plan; Royal Training's +1 to +100 was plan 05-14's rescale.

### Numbers line before and after

| Card | Numbers line before | Numbers line after |
|---|---|---|
| royal_training | +25% king health, +1 king damage | +25% king health, +100 king damage |
| commander | +25% unit health, +25% unit damage | +25% unit health, +25% unit damage |
| masons | +30% building health, +30% wall health | +30% building health, +30% wall health |
| prosperity | +1 castle gold at dawn | +2 castle gold at dawn |
| headsmans_edge | x2 king damage, x1.5 king attack interval | x2 king damage, x1.25 king attack interval |
| engineers | +25% tower damage, +15% tower range | +25% tower damage, +15% tower range |
| war_horns | x0.6 unit return time | x0.6 unit return time |
| warded_mail | x0.75 damage the king takes | x0.75 damage the king takes |
| iron_discipline | x1.5 unit damage, x1.3 unit health | x1.5 unit damage, x1.3 unit health |
| arrow_storm | +100% castle arrow damage, +25% castle arrow range | +100% castle arrow damage, +25% castle arrow range |
| master_builders | x1.5 building health, x1.5 wall health | x1.5 building health, x1.5 wall health |
| golden_age | +2 castle gold at dawn, +25% shrine damage | +4 castle gold at dawn, +25% shrine damage |

### Every card x every shipped base (base -> result (change))

| Card | Stat | Base | Before (ce3fcea scale and numbers) | After (shipped now) |
|---|---|---|---|---|
| royal_training | king.max_health | king | 50 -> 63 (+26%) | 5000 -> 6250 (+25%) |
| royal_training | king.attack_damage | sword | 5 -> 6 (+20%) | 500 -> 600 (+20%) |
| commander | unit.max_health | footman | 10 -> 13 (+30%) | 1000 -> 1250 (+25%) |
| commander | unit.max_health | archer | 6 -> 8 (+33%) | 600 -> 750 (+25%) |
| commander | unit.attack_damage | footman | 1 -> 1 (+0%) | 100 -> 125 (+25%) |
| commander | unit.attack_damage | archer | 1 -> 1 (+0%) | 100 -> 125 (+25%) |
| masons | building.max_health | house 1 | 12 -> 16 (+33%) | 1200 -> 1560 (+30%) |
| masons | building.max_health | house 2 | 18 -> 23 (+28%) | 1800 -> 2340 (+30%) |
| masons | building.max_health | house 3 | 24 -> 31 (+29%) | 2400 -> 3120 (+30%) |
| masons | building.max_health | tower 1 | 50 -> 65 (+30%) | 5000 -> 6500 (+30%) |
| masons | building.max_health | tower 2 | 70 -> 91 (+30%) | 7000 -> 9100 (+30%) |
| masons | building.max_health | barracks 1 | 40 -> 52 (+30%) | 4000 -> 5200 (+30%) |
| masons | building.max_health | barracks 2 | 60 -> 78 (+30%) | 6000 -> 7800 (+30%) |
| masons | building.max_health | barracks 3 | 80 -> 104 (+30%) | 8000 -> 10400 (+30%) |
| masons | building.max_health | archery_range 1 | 40 -> 52 (+30%) | 4000 -> 5200 (+30%) |
| masons | building.max_health | archery_range 2 | 60 -> 78 (+30%) | 6000 -> 7800 (+30%) |
| masons | building.max_health | archery_range 3 | 80 -> 104 (+30%) | 8000 -> 10400 (+30%) |
| masons | building.max_health | gold_mine 1 | 20 -> 26 (+30%) | 2000 -> 2600 (+30%) |
| masons | building.max_health | mill 1 | 15 -> 20 (+33%) | 1500 -> 1950 (+30%) |
| masons | building.max_health | mill 2 | 20 -> 26 (+30%) | 2000 -> 2600 (+30%) |
| masons | building.max_health | mill 3 | 25 -> 33 (+32%) | 2500 -> 3250 (+30%) |
| masons | building.max_health | field 1 | 8 -> 10 (+25%) | 800 -> 1040 (+30%) |
| masons | building.max_health | fishing_harbor 1 | 18 -> 23 (+28%) | 1800 -> 2340 (+30%) |
| masons | building.max_health | fishing_harbor 2 | 24 -> 31 (+29%) | 2400 -> 3120 (+30%) |
| masons | building.max_health | shrine 1 | 30 -> 39 (+30%) | 3000 -> 3900 (+30%) |
| masons | wall.max_health | wall 1 | 30 -> 39 (+30%) | 3000 -> 3900 (+30%) |
| masons | wall.max_health | wall 2 | 60 -> 78 (+30%) | 6000 -> 7800 (+30%) |
| masons | wall.max_health | wall 3 | 90 -> 117 (+30%) | 9000 -> 11700 (+30%) |
| prosperity | castle.base_income | castle 1 | 1 -> 2 (+100%) | 1 -> 3 (+200%) |
| prosperity | castle.base_income | castle 2 | 2 -> 3 (+50%) | 2 -> 4 (+100%) |
| prosperity | castle.base_income | castle 3 | 3 -> 4 (+33%) | 3 -> 5 (+67%) |
| prosperity | castle.base_income | castle 4 | 4 -> 5 (+25%) | 4 -> 6 (+50%) |
| headsmans_edge | king.attack_damage | sword | 5 -> 10 (+100%) | 500 -> 1000 (+100%) |
| headsmans_edge | king.attack_interval | sword | 0.700 -> 1.050 (+50%) | 0.700 -> 0.875 (+25%) |
| engineers | tower.damage | tower 1 | 3 -> 4 (+33%) | 300 -> 375 (+25%) |
| engineers | tower.damage | tower 2 | 6 -> 8 (+33%) | 600 -> 750 (+25%) |
| engineers | tower.range | tower 1 | 9.000 -> 10.350 (+15%) | 9.000 -> 10.350 (+15%) |
| engineers | tower.range | tower 2 | 10.500 -> 12.075 (+15%) | 10.500 -> 12.075 (+15%) |
| war_horns | squad.respawn_seconds | barracks 1 | 10.000 -> 6.000 (-40%) | 10.000 -> 6.000 (-40%) |
| war_horns | squad.respawn_seconds | barracks 2 | 7.000 -> 4.200 (-40%) | 7.000 -> 4.200 (-40%) |
| war_horns | squad.respawn_seconds | barracks 3 | 4.000 -> 2.400 (-40%) | 4.000 -> 2.400 (-40%) |
| war_horns | squad.respawn_seconds | archery_range 1 | 10.000 -> 6.000 (-40%) | 10.000 -> 6.000 (-40%) |
| war_horns | squad.respawn_seconds | archery_range 2 | 7.000 -> 4.200 (-40%) | 7.000 -> 4.200 (-40%) |
| war_horns | squad.respawn_seconds | archery_range 3 | 4.000 -> 2.400 (-40%) | 4.000 -> 2.400 (-40%) |
| warded_mail | king.damage_taken | grunt blow | 2 -> 2 (+0%) | 200 -> 150 (-25%) |
| warded_mail | king.damage_taken | ranged blow | 2 -> 2 (+0%) | 200 -> 150 (-25%) |
| iron_discipline | unit.attack_damage | footman | 1 -> 2 (+100%) | 100 -> 150 (+50%) |
| iron_discipline | unit.attack_damage | archer | 1 -> 2 (+100%) | 100 -> 150 (+50%) |
| iron_discipline | unit.max_health | footman | 10 -> 13 (+30%) | 1000 -> 1300 (+30%) |
| iron_discipline | unit.max_health | archer | 6 -> 8 (+33%) | 600 -> 780 (+30%) |
| arrow_storm | castle.arrow_damage | castle 1 | 2 -> 4 (+100%) | 200 -> 400 (+100%) |
| arrow_storm | castle.arrow_damage | castle 2 | 3 -> 6 (+100%) | 300 -> 600 (+100%) |
| arrow_storm | castle.arrow_damage | castle 3 | 4 -> 8 (+100%) | 400 -> 800 (+100%) |
| arrow_storm | castle.arrow_damage | castle 4 | 5 -> 10 (+100%) | 500 -> 1000 (+100%) |
| arrow_storm | castle.arrow_range | castle 1 | 22.000 -> 27.500 (+25%) | 22.000 -> 27.500 (+25%) |
| arrow_storm | castle.arrow_range | castle 2 | 22.000 -> 27.500 (+25%) | 22.000 -> 27.500 (+25%) |
| arrow_storm | castle.arrow_range | castle 3 | 22.000 -> 27.500 (+25%) | 22.000 -> 27.500 (+25%) |
| arrow_storm | castle.arrow_range | castle 4 | 22.000 -> 27.500 (+25%) | 22.000 -> 27.500 (+25%) |
| master_builders | building.max_health | house 1 | 12 -> 18 (+50%) | 1200 -> 1800 (+50%) |
| master_builders | building.max_health | house 2 | 18 -> 27 (+50%) | 1800 -> 2700 (+50%) |
| master_builders | building.max_health | house 3 | 24 -> 36 (+50%) | 2400 -> 3600 (+50%) |
| master_builders | building.max_health | tower 1 | 50 -> 75 (+50%) | 5000 -> 7500 (+50%) |
| master_builders | building.max_health | tower 2 | 70 -> 105 (+50%) | 7000 -> 10500 (+50%) |
| master_builders | building.max_health | barracks 1 | 40 -> 60 (+50%) | 4000 -> 6000 (+50%) |
| master_builders | building.max_health | barracks 2 | 60 -> 90 (+50%) | 6000 -> 9000 (+50%) |
| master_builders | building.max_health | barracks 3 | 80 -> 120 (+50%) | 8000 -> 12000 (+50%) |
| master_builders | building.max_health | archery_range 1 | 40 -> 60 (+50%) | 4000 -> 6000 (+50%) |
| master_builders | building.max_health | archery_range 2 | 60 -> 90 (+50%) | 6000 -> 9000 (+50%) |
| master_builders | building.max_health | archery_range 3 | 80 -> 120 (+50%) | 8000 -> 12000 (+50%) |
| master_builders | building.max_health | gold_mine 1 | 20 -> 30 (+50%) | 2000 -> 3000 (+50%) |
| master_builders | building.max_health | mill 1 | 15 -> 23 (+53%) | 1500 -> 2250 (+50%) |
| master_builders | building.max_health | mill 2 | 20 -> 30 (+50%) | 2000 -> 3000 (+50%) |
| master_builders | building.max_health | mill 3 | 25 -> 38 (+52%) | 2500 -> 3750 (+50%) |
| master_builders | building.max_health | field 1 | 8 -> 12 (+50%) | 800 -> 1200 (+50%) |
| master_builders | building.max_health | fishing_harbor 1 | 18 -> 27 (+50%) | 1800 -> 2700 (+50%) |
| master_builders | building.max_health | fishing_harbor 2 | 24 -> 36 (+50%) | 2400 -> 3600 (+50%) |
| master_builders | building.max_health | shrine 1 | 30 -> 45 (+50%) | 3000 -> 4500 (+50%) |
| master_builders | wall.max_health | wall 1 | 30 -> 45 (+50%) | 3000 -> 4500 (+50%) |
| master_builders | wall.max_health | wall 2 | 60 -> 90 (+50%) | 6000 -> 9000 (+50%) |
| master_builders | wall.max_health | wall 3 | 90 -> 135 (+50%) | 9000 -> 13500 (+50%) |
| golden_age | castle.base_income | castle 1 | 1 -> 3 (+200%) | 1 -> 5 (+400%) |
| golden_age | castle.base_income | castle 2 | 2 -> 4 (+100%) | 2 -> 6 (+200%) |
| golden_age | castle.base_income | castle 3 | 3 -> 5 (+67%) | 3 -> 7 (+133%) |
| golden_age | castle.base_income | castle 4 | 4 -> 6 (+50%) | 4 -> 8 (+100%) |
| golden_age | shrine.damage | shrine 1 | 3 -> 4 (+33%) | 300 -> 375 (+25%) |

Reading the table: before the rescale the integer rounding swallowed or distorted small bases (Commander's +25% unit damage on a base of 1 gave +0%, Warded Mail's x0.75 on 2 gave +0%, Iron Discipline's x1.5 on 1 gave +100%, Engineers' +25% on 3 gave +33%); after it every percent and multiplier lands as written at every shipped base. The three recut cards read in the table as: Prosperity 2 -> 4 gold at tier II and 3 -> 5 at tier III (was 2 -> 3 and 3 -> 4), Golden Age 4 -> 8 gold at tier IV (was 4 -> 6) with its shrine damage 300 -> 375, and Headsman's Edge interval 0.700 -> 0.875 (was 1.050). The tier I rows of the income cards are for completeness; the card is only offered from tier II.

## Blows to kill (grunt 600, skirmisher 400; before 6 and 4)

| Attacker (card) | Before: base -> damage, blows to kill a grunt (6) / skirmisher (4) | After: base -> damage, blows to kill a grunt (600) / skirmisher (400) |
|---|---|---|
| king, no card | 5 -> 5 dmg, grunt 2, skirm 1; interval 0.700 s, grunt in 1.40 s, skirm in 0.70 s | 500 -> 500 dmg, grunt 2, skirm 1; interval 0.700 s, grunt in 1.40 s, skirm in 0.70 s |
| royal_training | 5 -> 6 dmg, grunt 1, skirm 1; interval 0.700 s, grunt in 0.70 s, skirm in 0.70 s | 500 -> 600 dmg, grunt 1, skirm 1; interval 0.700 s, grunt in 0.70 s, skirm in 0.70 s |
| headsmans_edge | 5 -> 10 dmg, grunt 1, skirm 1; interval 1.050 s, grunt in 1.05 s, skirm in 1.05 s | 500 -> 1000 dmg, grunt 1, skirm 1; interval 0.875 s, grunt in 0.88 s, skirm in 0.88 s |
| royal_training+headsmans_edge | 5 -> 12 dmg, grunt 1, skirm 1; interval 1.050 s, grunt in 1.05 s, skirm in 1.05 s | 500 -> 1200 dmg, grunt 1, skirm 1; interval 0.875 s, grunt in 0.88 s, skirm in 0.88 s |
| footman, no card | 1 -> 1 dmg, grunt 6, skirm 4 | 100 -> 100 dmg, grunt 6, skirm 4 |
| commander (footman) | 1 -> 1 dmg, grunt 6, skirm 4 | 100 -> 125 dmg, grunt 5, skirm 4 |
| iron_discipline (footman) | 1 -> 2 dmg, grunt 3, skirm 2 | 100 -> 150 dmg, grunt 4, skirm 3 |
| commander+iron_discipline (footman) | 1 -> 2 dmg, grunt 3, skirm 2 | 100 -> 188 dmg, grunt 4, skirm 3 |
| tower I, no card | 3 -> 3 dmg, grunt 2, skirm 2 | 300 -> 300 dmg, grunt 2, skirm 2 |
| engineers (tower I) | 3 -> 4 dmg, grunt 2, skirm 1 | 300 -> 375 dmg, grunt 2, skirm 2 |
| tower II, no card | 6 -> 6 dmg, grunt 1, skirm 1 | 600 -> 600 dmg, grunt 1, skirm 1 |
| engineers (tower II) | 6 -> 8 dmg, grunt 1, skirm 1 | 600 -> 750 dmg, grunt 1, skirm 1 |
| castle IV arrow, no card | 5 -> 5 dmg, grunt 2, skirm 1 | 500 -> 500 dmg, grunt 2, skirm 1 |
| arrow_storm (castle IV) | 5 -> 10 dmg, grunt 1, skirm 1 | 500 -> 1000 dmg, grunt 1, skirm 1 |
| shrine, no synergy | 3 -> 3 dmg, grunt 2, skirm 2 | 300 -> 300 dmg, grunt 2, skirm 2 |
| shrine + synergy (1 other awake) | 3 -> 4 dmg, grunt 2, skirm 1 | 300 -> 360 dmg, grunt 2, skirm 2 |
| golden_age on a lone shrine | 3 -> 4 dmg, grunt 2, skirm 1 | 300 -> 375 dmg, grunt 2, skirm 2 |
| golden_age + synergy | 3 -> 4 dmg, grunt 2, skirm 1 | 300 -> 435 dmg, grunt 2, skirm 1 |

For the owner's re-judge (plan 05-24): a percent of damage changes a kill only when it crosses a whole enemy. Commander's 125 kills a 600 grunt in 5 blows instead of 6 but a 400 skirmisher still in 4. Engineers' honest +25% (375) changes no Tower I kill at all (the old rounding made 3 into 4, which one-shot 4-health skirmishers). The Shrine synergy alone (360) no longer one-shots a skirmisher, synergy plus Golden Age (435) does. Iron Discipline's honest x1.5 (150) is a smaller step than the old rounded +100% (1 -> 2). Headsman's Edge on a bare sword (1000) kills a grunt in one blow every 0.875 s instead of two blows (1.40 s); with Royal Training first the grunt already dies in one 0.70 s blow, so on that build Headsman's Edge buys no extra kill and costs a 0.875 s blow (the worst case named in the pin). The owner may later raise enemy health relative to damage to make the steps finer.

## Deviations from Plan

None - plan executed exactly as written.

Notes that are not deviations: Task 2 is a single commit (the plan and the project instructions ask for one commit per task), so the RED and GREEN runs are recorded above rather than as separate test/feat commits; the planner's `diff` for this plan was not consulted (the plan is the contract and it was unambiguous).

**Total deviations:** 0.

## Issues Encountered

- My first run of the negative-control test raised an "unsupported format character" engine error because an assert message held a bare `%` before a `%` format operator (`"+25% on 1 (%d) fails" % x`). Fixed by escaping (`%%`); re-run 8/8. Not in plan files outside the new test.
- `test_ability_data.gd` and `test_castle_label.gd` show a harmless "CRLF will be replaced by LF" warning on add (working-copy line endings; commits are LF).

## Known Stubs

None.

## Threat Flags

None. T-05-38 and T-05-39 are mitigated: every card is pinned with its old and new value and reason in the test_ability_data header, and the guard builds its bases from the shipped files, bands every card, bounds every integer health and damage base to 100..MAX_ABS_BASE and carries a negative control.

## Next Phase Readiness

Plan 05-22 (the Harbor move) is next and moves full_idle by design; plan 05-23 copies the two tables above into the report and re-measures Prosperity; plan 05-24's owner re-judge puts each recut card to the owner with the alternatives (Golden Age +3 or the old +2; Headsman's Edge at the old x1.5, or without the slowdown, rejected as an always-take). No blockers.

## Self-Check: PASSED

Found on disk: tests/unit/test_card_resolution.gd and its .uid, the three card files, this SUMMARY. Commits 7aff759 and 6852027 found in git log. Acceptance criteria of both tasks re-run: all pass.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-25*
