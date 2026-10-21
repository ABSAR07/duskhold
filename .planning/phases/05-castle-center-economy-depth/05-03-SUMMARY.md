---
phase: 05-castle-center-economy-depth
plan: 03
subsystem: simulation
tags: [godot, gdscript, castle, choice-cards, stat-stack, validation, world-space-ui, contract-test, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "ChoiceDef, castle_center.tres with tier II cards, castle_plot, ChoiceLedger.picks_of/find_choice, CardPicker/CardRow, CastleState.tier() (plan 05-02); StatStack, StatModifierDef.effect_text(), StatIds labels (plan 05-01)"
provides:
  - "Eight more ability cards in data/abilities/ (Headsman's Edge, Engineers, War Horns, Warded Mail for tier III; Iron Discipline, Arrow Storm, Master Builders, Golden Age for tier IV): castle_center.tres now offers four cards at each of its three upgrades"
  - "ChoiceDef.effect_line(): the card's numbers line generated from its modifiers (effect_text joined with ', ')"
  - "SpotLabelModel.describe()['picks'] and a private _castle_effect: the castle label reads 'Health N · Arrow N · N gold at dawn' through the stat stack and lists the picked cards in pick order; SpotLabel gains a Picks Label3D"
  - "ChoiceValidation and CastleValidation (static problems(map) -> Array[String]) called from MapConfig.validate(): bad card and castle data is reported instead of armed"
  - "test_ability_data pins the twelve cards (ids, stat, bucket, value); test_castle_label, test_castle_three_picks and test_choice_validation"
affects: [05-04 icons, mouse path and castle look, 05-05 requirement gate, 05-06 to 05-09 new plots, 05-11 balance fit and bot roles, phase-06 tower specialisations, phase-07 unit choices]

actuals:
  tokens: 36000
  tasks: 2
  commits: 3
plan_head_before: 17242a1aae8e849e9e6c305bebe0648126ec758d
plan_head_after: 9bdc5fc2897ac81cb018fef85d626e26f5da690a

tech-stack:
  added: []
  patterns:
    - "A card's player-facing numbers line is never authored: ChoiceDef.effect_line() joins each modifier's effect_text(), and test_ability_data pins that equality for all twelve cards"
    - "Castle label numbers are read through ctx.stat_stack, so a picked card that changes health, arrow damage or gold at dawn shows in the next tier's preview"
    - "Validation helpers follow WallValidation: static, pure, one readable string per problem, called from MapConfig.validate(); a helper never repeats a check MapConfig already owns (second castle plot, castle plus wall plot, unknown building id, bad castle radius)"
    - "SpotLabel refreshes on choice_picked as well as building_built, because the pick is announced after the purchase's building_built"

key-files:
  created:
    - data/abilities/headsmans_edge.tres
    - data/abilities/engineers.tres
    - data/abilities/war_horns.tres
    - data/abilities/warded_mail.tres
    - data/abilities/iron_discipline.tres
    - data/abilities/arrow_storm.tres
    - data/abilities/master_builders.tres
    - data/abilities/golden_age.tres
    - simulation/defs/choice_validation.gd
    - simulation/defs/castle_validation.gd
    - tests/unit/test_castle_label.gd
    - tests/unit/test_ability_data.gd
    - tests/unit/test_choice_validation.gd
    - tests/e2e/test_castle_three_picks.gd
  modified:
    - data/buildings/castle_center.tres
    - simulation/defs/choice_def.gd
    - simulation/defs/map_config.gd
    - ui/world/spot_label_model.gd
    - ui/world/spot_label.gd
    - ui/world/spot_label.tscn
    - tests/unit/test_castle_data_contract.gd
    - tests/unit/test_castle_tiers.gd
    - tests/unit/test_build_choice.gd
    - tests/unit/test_card_row_model.gd
    - tests/e2e/test_card_row.gd

key-decisions:
  - "The twelve-card set keeps the plan's table exactly (research Ability Draft numbers); flavour lines are original, all ASCII, at most 70 characters; names at most 24"
  - "Castle label effect is one line 'Health %d · Arrow %d · %d gold at dawn' with the next tier's numbers through castle.max_health, castle.arrow_damage and castle.base_income; at tier IV the effect is empty and the status reads Max tier"
  - "The Picks line is generic (SpotLabelModel._picks_line reads picks_of for any plot), empty for a plot with no picks, so Phase 6 tower specialisations can reuse it without a change"
  - "ChoiceValidation also reports a card with no name and a card with no modifiers (a blank card face and a card that arms nothing), beyond the plan's list; CastleValidation does not repeat the second-castle-plot check that 05-02 put in MapConfig.validate()"
  - "CastleValidation measures the plot against castle_radius + 3.0 m only when the radius is a positive finite number; a bad radius stays MapConfig's own single report"

patterns-established:
  - "When a data change gives a plain tier cards (tiers III and IV of the castle), every existing test that bought that tier without a card is updated in the same commit"

requirements-completed: []

coverage:
  - id: D1
    description: "Eight new ability cards so castle tiers III and IV each offer four; every card's numbers pinned (stat, bucket, value) and its names within 24/70 characters, none named after a Thronefall perk"
    requirement: BLDG-08
    verification:
      - kind: unit
        ref: "tests/unit/test_ability_data.gd (15 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "ChoiceDef.effect_line() generated from the modifiers: royal_training reads '+25% king health, +1 king damage', headsmans_edge reads 'x2 king damage, x1.5 king attack interval'"
    requirement: UI-02
    verification:
      - kind: unit
        ref: "tests/unit/test_castle_label.gd#test_royal_training_reads_plus_25_percent_health_and_plus_1_damage"
        status: pass
      - kind: unit
        ref: "tests/unit/test_ability_data.gd#test_every_numbers_line_is_the_modifiers_text_joined_in_order"
        status: pass
    human_judgment: false
  - id: D3
    description: "The castle label names the next tier and its effective health, arrow and gold through the stat stack, lists the picked cards in pick order, and reads Max tier with all three picks at tier IV"
    requirement: UI-02
    verification:
      - kind: unit
        ref: "tests/unit/test_castle_label.gd (12 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "In the real prototype scene, keys 1, 2 and 4 with a full hold buy castle tiers II, III and IV with Royal Training, Engineers and Golden Age: three choice_picked digest lines in order, the rows refreshing with no highlight, the Picks node reading 'Royal Training · Engineers · Golden Age', no cards at the top"
    requirement: BLDG-08
    verification:
      - kind: e2e
        ref: "tests/e2e/test_castle_three_picks.gd (3 tests, real scene)"
        status: pass
    human_judgment: false
  - id: D5
    description: "MapConfig.validate() reports bad card and castle data (duplicate id once naming both places, null or empty-id choice, bad modifier, over-long name or flavour, wrong card count on a castle tier, short castle building, tier I with cards, far castle plot) and the shipped map validates clean"
    requirement: BLDG-05
    verification:
      - kind: unit
        ref: "tests/unit/test_choice_validation.gd (20 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "smoke, army and walls goldens and the full_idle digest are byte-identical"
    verification:
      - kind: other
        ref: "bash tools/replay.sh smoke, army, walls with --expect-file and full_idle, each --twice"
        status: pass
    human_judgment: false
  - id: D7
    description: "Whether the twelve cards, their numbers and their flavour lines read well and feel balanced, and whether the Picks line sits well under the coins at the shipped camera"
    verification: []
    human_judgment: true
    rationale: "The set is Claude's draft under D-02 and the label layout is world-space text; no test asserts feel or legibility, so the owner judges both at the end-of-phase check"

duration: 57min
completed: 2026-10-21
status: complete
---

# Phase 5 Plan 03: Castle Ladder Complete Summary

**The castle now offers one pick of four at each of its three upgrades (twelve generated-text ability cards in data), its label shows the next tier's effective health, arrow and gold through the stat stack plus the cards already picked, and MapConfig.validate() reports bad card and castle data, with all four replay digests unchanged**

## Performance

- **Duration:** 57 min
- **Started:** 2026-10-21T13:00:15Z
- **Completed:** 2026-10-21T13:57Z
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files:** 25 changed (14 created, 11 modified), plus 4 `.gd.uid` files
- **Commits:** 3 task commits (feat tracer, test RED, feat GREEN)

## Accomplishments

- Eight cards (`data/abilities/*.tres`, same text form as plan 05-02) and `castle_center.tres` tiers III and IV choices: tier III Headsman's Edge, Engineers, War Horns, Warded Mail; tier IV Iron Discipline, Arrow Storm, Master Builders, Golden Age. Numbers copied from the plan table; the three renames (Assassin's Training, Rallying Banner, Magic Armor) are in place.
- `ChoiceDef.effect_line()` (modifiers' `effect_text()` joined with ", "): "+25% king health, +1 king damage", "x2 king damage, x1.5 king attack interval".
- Castle label: `SpotLabelModel._castle_effect` reads `castle.max_health`, `castle.arrow_damage` and `castle.base_income` through `ctx.stat_stack` ("Health 100 · Arrow 3 · 2 gold at dawn" for tier II as shipped); `describe()["picks"]` joins the picked cards' display names with " · "; `SpotLabel` has a `Picks` Label3D under the coins, hidden when empty, refreshed on `choice_picked` (the pick is announced after the purchase's `building_built`).
- `ChoiceValidation` and `CastleValidation` (static, pure, `Array[String]`) wired into `MapConfig.validate()`; `test_ability_data` pins the twelve cards.
- Tracer proof: in the real prototype scene the king buys tier II (key 1), tier III (key 2) and tier IV (key 4) by key and hold; three `choice_picked` digest lines `castle_plot 2 royal_training`, `castle_plot 3 engineers`, `castle_plot 4 golden_age`, the Picks node reads "Royal Training · Engineers · Golden Age".

## Task Commits

1. **Task 1: Tracer, eight cards, effect_line, castle label, three picks in the real scene** - `17fc02e` (feat)
2. **Task 2 RED: failing validation tests and the twelve-card contract** - `cefac2a` (test)
3. **Task 2 GREEN: validate() reports bad card and castle data** - `9bdc5fc` (feat)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Verification (measured)

- Baseline at dispatch (HEAD 17242a1): 239 scripts / 2241 tests / 56384 asserts, lint clean.
- Task 1 full suite (before the fix below): 241 scripts / 2256 tests, 1 failing (`test_castle_tiers`: it bought tiers III and IV without a card, now refused with `choice_required`); fixed, script alone 16 of 16.
- Task 2 full suite, first run: 243 scripts / 2291 tests, 1 failing (`test_map_validate_enemies#test_a_castle_with_no_radius_is_reported` saw a second error from the new distance check); fixed in CastleValidation (see Deviations). **Final full suite after the fix: 243 scripts / 2291 tests / 56622 asserts, all passing, exit 0 (baseline 239 / 2241 / 56384: +4 scripts, +50 tests).**
- New scripts and tests: test_castle_label 12, test_castle_three_picks 3, test_choice_validation 20, test_ability_data 15. JUnit XML lists all four plus test_prototype_map_economy, test_prototype_map_data, test_card_row.gd, test_build_choice and test_spot_label.
- Replays, each with `--twice`, identical lines after Task 1 and again after Task 2:
  - `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden)
  - `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (golden)
  - `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (golden)
  - `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`
- `bash tools/lint.sh`: clean (403 files). Public method counts: ChoiceValidation 1, CastleValidation 1, SpotLabelModel 1 (+2 private), ChoiceDef 1; MapConfig 554 lines (cap 1000); `test_choice_validation` has exactly 20 tests and no `before_each` (at the cap).

## TDD record (Task 2)

- RED (`cefac2a`): `test_choice_validation` 3 of 20 passed at once and 17 failed on the planned assertion ("exactly one error, got []" for the duplicate id on two tiers and on one tier, the triple duplicate, the id shared with another building, a null choice, an empty id, no name, no modifiers, an unregistered stat, an out-of-range value, the 25-character name, the 71-character flavour, three cards, five cards, a one-tier castle, tier I with cards and a far plot). The three that passed at once pin behaviour that already held and must keep holding (the castle fixture, the shipped prototype map and a one-point-castle copy validate clean). The two helper files existed in the working tree but were not wired into `validate()` and not committed, so the run measured the missing behaviour.
- `test_ability_data` 15 of 15 passed at once, because it pins the Task 1 data (as `test_nav_layout_pin` did in plan 05-02): it is a contract pin, not new behaviour.
- GREEN (`9bdc5fc`): `test_choice_validation` 20 of 20 after the two `validate()` lines; full suite green after the radius fix.
- This plan is `type: execute`, so no `tdd-red-evidence` record was filed; the failing run above is the evidence.

## Decisions Made

- See `key-decisions` in the frontmatter. The cards, numbers and flavour are Claude's draft under D-02; the owner judges them at the end-of-phase check (flagged assumptions A2 to A4 stand unchanged).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing tests assumed castle tiers III and IV are plain upgrades**
- **Found during:** Task 1 (first full-suite run) and while reading the tests before editing
- **Issue:** with cards on tiers III and IV, a purchase without a card is refused (`choice_required`). `test_castle_tiers#test_tiers_three_and_four_raise_the_numbers_again` bought both tiers with no card (the one failure of the run); `test_build_choice` asserted tier III has no cards and that tier III is a plain purchase; `test_card_row_model` asserted tiers III and IV show no row; `test_castle_data_contract` asserted tiers III and IV carry no choices; `test_card_row` (e2e) asserted that after tier II the cards are gone.
- **Fix:** each test now states the new fact: tiers III and IV offer four cards, a pick adds to the earlier ones and never replaces them, the tier III row appears right after tier II with nothing highlighted. `test_castle_tiers` buys tier III with Headsman's Edge and tier IV with Iron Discipline (neither touches a castle stat, so the tier numbers it asserts are unchanged).
- **Files modified:** tests/unit/test_castle_tiers.gd, tests/unit/test_build_choice.gd, tests/unit/test_card_row_model.gd, tests/unit/test_castle_data_contract.gd, tests/e2e/test_card_row.gd
- **Verification:** each script run alone, then the full suite
- **Committed in:** 17fc02e

**2. [Rule 2 - Missing critical] SpotLabel refresh on choice_picked**
- **Found during:** Task 1 (design: `choice_picked` is emitted after the purchase's `building_built`, which is the only event the label refreshed on)
- **Issue:** the Picks line would have lagged one purchase behind.
- **Fix:** `SpotLabel` connects `choice_picked` to a refresh; `test_castle_three_picks` reads the Picks node after every purchase.
- **Files modified:** ui/world/spot_label.gd
- **Committed in:** 17fc02e

**3. [Rule 1 - Bug] CastleValidation double-reported a bad castle radius**
- **Found during:** Task 2 (full suite: `test_map_validate_enemies#test_a_castle_with_no_radius_is_reported` expects exactly one error)
- **Issue:** a map with `castle_radius` 0 already gets MapConfig's own "castle_radius is 0.0"; the new plot-distance check measured against `0 + 3.0 m` and added a second, misleading error.
- **Fix:** the distance check runs only when the radius is a positive finite number.
- **Files modified:** simulation/defs/castle_validation.gd
- **Verification:** `-gselect=test_map_validate` 70 of 70, then the full suite
- **Committed in:** 9bdc5fc

**4. Two checks beyond the plan's list (Rule 2) and one omission by design**
- ChoiceValidation also reports a card with no name and a card with no modifiers (a blank card face, a card that arms nothing); both are pinned in `test_choice_validation`.
- CastleValidation omits the plan's "at most one castle spot" and "its building exists" checks: plan 05-02 already put the first in `MapConfig.validate()` (pinned in `test_castle_tiers`) and MapConfig already reports a spot naming an unknown building, so repeating them would double-report (the orchestrator's note and the 05-02 SUMMARY say to extend, not re-report).

---

**Total deviations:** 3 auto-fixed (1 blocking, 1 missing critical, 1 bug) plus two additions and one omission by design. **Impact on plan:** none on scope or interfaces; every listed interface and acceptance criterion holds.

## Issues Encountered

- Several tracked files carry CRLF in the working tree (`test_build_choice.gd`, `test_castle_tiers.gd`, `map_config.gd` and the files `gdformat` rewrites); the edits preserved each file's own line endings and git normalises on commit (the warnings are harmless).
- Godot 4.7's `Resource.duplicate(true)` leaves external sub-resources shared, so the synthetic maps in `test_choice_validation` use `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` (the `e2e_support` precedent); otherwise a test editing a card would have changed the cached `castle_center.tres` for every later test.

## Known Stubs

None new. `ChoiceDef.icon` is still null on all twelve cards (the empty icon slot), intentional per the plan and already recorded in `.planning/WINDOWS.md` by plan 05-02; plan 05-04 adds the twelve icons.

## Threat Flags

None. T-05-07 (card and castle data tampering) is mitigated by `ChoiceValidation` and `CastleValidation` plus the existing RunContext push of `validate()` errors; T-05-08 (card text) by the 24 and 70 character limits. No new network, file or auth surface.

## Next Phase Readiness

- Plan 05-04 can add the twelve icons and the mouse path to the cards; `CardRow` and `CardRowModel` are generic and show whichever tier's four cards come next. The Picks line sits at 0.9 m below the label origin (under the coins); its look at the shipped camera is for the owner to judge.
- Plan 05-05 (requirement gate) can read `ctx.choices` and the castle tier as before; nothing here changed `CommandProcessor` or `BuildingSystem`.
- Plan 05-11 (balance fit) re-pins `test_ability_data` and `test_castle_data_contract` together if it retunes a card or a tier number. No bot picks cards yet; `Tally._role_of` still classes a bought castle as `towers` (05-02 note).
- Reminder from 05-01/05-02 stands: the Prosperity +1 gold is a modest tier-II card (flagged for the owner).

## Self-Check: PASSED

All 14 created files exist on disk, commits 17fc02e, cefac2a and 9bdc5fc exist, `data/buildings/castle_center.tres` names all twelve ability files, `func effect_line(` is in choice_def.gd, `"picks"` and `picks_of(` are in spot_label_model.gd, `ui/world/spot_label.tscn` has a `Picks` node, `class_name ChoiceValidation` with `MAX_NAME_LENGTH: int = 24` and `MAX_FLAVOUR_LENGTH: int = 70` and `class_name CastleValidation` exist, `ChoiceValidation.problems(` and `CastleValidation.problems(` are in map_config.gd, test_ability_data lists the twelve ids in tier order, and both tasks' verify chains were run (full suite, four replays, lint).

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-21*
