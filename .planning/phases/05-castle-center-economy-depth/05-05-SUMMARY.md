---
phase: 05-castle-center-economy-depth
plan: 05
subsystem: simulation
tags: [godot, gdscript, build-gate, requirements, castle-tier, spot-label, playtest-bot, validation, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "validate_build(spot_id, choice_id) with CHOICE_REQUIRED and BAD_CHOICE, the castle plot and its four tiers (05-02); ChoiceValidation and CastleValidation as the validation helper shape, SpotLabelModel castle effect line and picks (05-03)"
provides:
  - "BuildingTierDef.requires_castle_tier (default 0 = none) and BuildSpotDef.requires_spot / requires_spot_tier (default none / 1): the one requirement mechanism D-03 and D-10 share"
  - "BuildRequirements (static, pure; rejection and castle_tier) called by CommandProcessor.validate_build right after MAX_TIER; reasons CommandProcessor.CASTLE_TIER and NEEDS_SPOT announce command_rejected, spend nothing and give the existing denied bump"
  - "Locked label lines 'Needs Castle II' (Roman numeral of the required tier) and 'Needs a House' (the required building's display name) with cost 0 and affordable true (no price, no red coins); the title still names the locked tier and the effect line stays"
  - "BuildRequirementValidation, appended to MapConfig.validate(): castle tier below 0 or above the castle's top tier, a castle tier gating itself, requires_spot naming the plot itself or a missing spot, a required tier outside 1..that building's top tier, requirement cycles (once)"
  - "PlaytestBot defer-on-locked: castle_tier and needs_spot entries go to a pending list retried first on every think, in deferral order; CANNOT_AFFORD still waits in place"
  - "tests/fixtures/fixture_map_gate.tres (inline tower copy whose tier II needs castle 2, a house_b plot needing house_a), so shipped data stays ungated"
affects: [05-06 and later plots (Field lock 'Needs a Mill' reuses requires_spot), 05-07 Mill and Field, 05-09 Harbor, 05-11 shipped top-tier gating with castle-aware bots and the balance re-pin, 05-12 verification]

actuals:
  tokens: 10800
  tasks: 2
  commits: 3
plan_head_before: b6e88c3eb2fd4cedb3669c2c6986fc92473bd8f5
plan_head_after: dc191f859af0ca76fffa284c88baf7f731b4768f

tech-stack:
  added: []
  patterns:
    - "A requirement is data on the tier (castle) or the plot (other plot), checked by one static pure helper that reads only existing public BuildingSystem getters, so BuildingSystem (at the 20-method cap) gains nothing"
    - "Check order puts requirements before affordability: a locked tier the player cannot afford reads as locked, not as dear"
    - "The label asks the same gate the hold uses (validate_build) for its locked line, so label and denied bump cannot disagree"
    - "Bots defer a locked entry to a pending list retried each think instead of waiting on it, so a gate never stalls a build order"

key-files:
  created:
    - simulation/commands/build_requirements.gd
    - simulation/defs/build_requirement_validation.gd
    - tests/fixtures/fixture_map_gate.tres
    - tests/unit/test_build_requirements.gd
    - tests/unit/test_spot_label_locked.gd
    - tests/unit/test_build_requirement_validation.gd
    - tests/unit/test_bot_defers_locked.gd
    - tests/e2e/test_castle_gate.gd
  modified:
    - simulation/defs/building_tier_def.gd
    - simulation/defs/build_spot_def.gd
    - simulation/commands/command_processor.gd
    - simulation/defs/map_config.gd
    - ui/world/spot_label_model.gd
    - tools/replay/playtest_bot.gd

key-decisions:
  - "Requirement checks sit between MAX_TIER and CANNOT_AFFORD (plan order, not RESEARCH Pattern 3's earlier draft): a gated tier with too little gold is CASTLE_TIER, MAX_TIER still wins at the top, and the check is skipped when CommandProcessor has no map"
  - "Castle requirements apply only on a map that has a castle plot (BuildRequirements checks the plot, not the tier), so every fixture and replay map without one is unaffected and the three goldens cannot move"
  - "requires_spot applies when the plot is unbuilt (tier 0) only, so a built plot never relocks and a destroyed required building does not relock it (D-10)"
  - "Shipped data is untouched: no tier or plot in data/ carries a requirement, so no shipped strategy defers; gating the top tiers waits for plan 05-11 with the castle-aware bots and the balance re-pin"
  - "The locked label keeps the effect line and hides only the price: a player sees what the locked tier would give while the status line says why it is closed"
  - "BuildRequirementValidation also reports a tier of the castle's own building that needs the castle at its own tier or higher (the castle would have to be bought before itself), beyond the plan's list, because it is the one self-deadlock the castle plot allows"

patterns-established:
  - "Locked status lines share the Status Label3D with the coin row: cost 0 hides the coins and the status line shows (05-07 Field and 05-09 reuse the exact strings)"

requirements-completed: [BLDG-09]

coverage:
  - id: D1
    description: "A tier can need the castle at tier N and a plot's first build can need another plot at tier N, authored as data per tier or per plot"
    requirement: "BLDG-09"
    verification:
      - kind: unit
        ref: "tests/unit/test_build_requirements.gd (15 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "validate_build order NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CASTLE_TIER / NEEDS_SPOT, CANNOT_AFFORD; a refusal announces command_rejected and spends nothing; exact castle tier unlocks, one below refuses, 0 never refuses, MAX_TIER wins"
    requirement: "BLDG-09"
    verification:
      - kind: unit
        ref: "tests/unit/test_build_requirements.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "Locked label reads 'Needs Castle II' / 'Needs a House' with no price and no red coins; the price returns when the requirement is met"
    requirement: "BLDG-09"
    verification:
      - kind: unit
        ref: "tests/unit/test_spot_label_locked.gd (7 tests)"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_castle_gate.gd (3 tests, real scene on a gated deep copy of the prototype map)"
        status: pass
    human_judgment: true
    rationale: "Whether the status line reads clearly at the label's position in the real window is a look-and-feel judgment; the e2e proves the text, the empty coin row, the denied hold and the shake on the headless renderer only"
  - id: D4
    description: "MapConfig.validate() reports impossible requirements (range, missing spot, self, cycle)"
    requirement: "BLDG-09"
    verification:
      - kind: unit
        ref: "tests/unit/test_build_requirement_validation.gd (15 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "A bot defers a locked entry, keeps buying later ones and retries the deferred ones on every think"
    requirement: "BLDG-09"
    verification:
      - kind: unit
        ref: "tests/unit/test_bot_defers_locked.gd (8 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "smoke, army and walls replay byte-identical and full_idle keeps digest 4385f569...: no shipped tier is gated"
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke|army|walls --twice --expect-file=...; --scenario=full_idle --twice"
        status: pass
    human_judgment: false

duration: 56 min
completed: 2026-10-21
status: complete
---

# Phase 5 Plan 5: Requirement Gate Summary

**One data-driven requirement mechanism: a building tier can need the castle at tier N and a plot's first build can need another plot at tier N, refused at the build gate with castle_tier / needs_spot, read on the label as "Needs Castle II" / "Needs a House", validated in MapConfig, and stepped around by the bots, while the shipped data stays ungated so every pin and replay is exact.**

## Performance

- **Duration:** 56 min
- **Started:** 2026-10-21T15:41:08Z
- **Completed:** 2026-10-21T16:36:41Z (last code commit; SUMMARY follows)
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files modified:** 20 (8 created source/test files plus 4 .uid files and the fixture, 6 modified sources)

## Accomplishments

- **Tracer (Task 1):** BuildingTierDef.requires_castle_tier, BuildSpotDef.requires_spot / requires_spot_tier, the static BuildRequirements helper and the two rejection reasons. On a deep copy of the prototype map with Tower II gated, the real scene shows "Needs Castle II" with an empty coin row, the action key emits hold_denied(tower_1, castle_tier), the label shakes, gold is unchanged, and after castle II is bought through the cards the price returns and a full hold buys Tower II.
- **Validation and bots (Task 2):** BuildRequirementValidation reports every requirement that can never be met, appended to MapConfig.validate() after plan 05-03's helpers. PlaytestBot defers castle_tier and needs_spot entries to a pending list retried first on every think, in deferral order; the shipped strategies never defer because no shipped datum carries a requirement.
- Nothing balance-relevant moved: no pin was edited, and the three goldens and the full_idle digest are exact.

## Task Commits

1. **Task 1: requirement gate (tracer)** - `2d56716` (feat)
2. **Task 2 RED: failing validation and bot defer tests** - `5b3106c` (test) - test_bot_defers_locked 3 of 8 failing (a locked entry stalls the order: house_a / house_b not bought past the locked Tower II, deferred entries never retried); test_build_requirement_validation failed to load (BuildRequirementValidation undeclared, a parse error that GUT reports as a failed script)
3. **Task 2 GREEN: validation helper and bot defer rule** - `dc191f8` (feat)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md and ROADMAP.md follows.

_TDD note: no REFACTOR commit, the GREEN code needed no cleanup._

## Files Created/Modified

- `simulation/commands/build_requirements.gd` - static pure requirement check: castle_tier and rejection
- `simulation/defs/build_requirement_validation.gd` - problems(map) for impossible requirements
- `simulation/defs/building_tier_def.gd`, `build_spot_def.gd` - the requirement fields
- `simulation/commands/command_processor.gd` - CASTLE_TIER, NEEDS_SPOT, the check right after MAX_TIER, the check-order doc line
- `simulation/defs/map_config.gd` - appends BuildRequirementValidation.problems after the castle helpers
- `ui/world/spot_label_model.gd` - locked status lines through validate_build (private `_locked_line`)
- `tools/replay/playtest_bot.gd` - pending list and `_retry_pending`
- `tests/fixtures/fixture_map_gate.tres` - castle plot, gated inline tower, house_a, house_b needing house_a
- `tests/unit/test_build_requirements.gd`, `test_spot_label_locked.gd`, `test_build_requirement_validation.gd`, `test_bot_defers_locked.gd`, `tests/e2e/test_castle_gate.gd` - the new tests

## Decisions Made

See key-decisions above. The one reading beyond the plan: the validation helper also reports a castle tier that requires the castle at its own tier or higher.

## Deviations from Plan

None - plan executed exactly as written. (The self-gating castle check is an addition inside the validation helper's own scope, recorded under decisions, not a deviation from a stated truth.)

## Verification

- Full suite, three runs this plan, all exit 0: after Task 1 249 scripts / 2356 tests / 57250 asserts; after Task 2, run 1 251 scripts / 2379 tests / 57339 asserts and run 2 251 scripts / 2379 tests / 57310 asserts (the assert count differs by 29 between two identical runs: the e2e tests poll with wait loops, so the number of polling asserts varies with machine timing; test and script counts are identical and every test passes). Delta from the 246 / 2331 / 57148 baseline: +5 scripts, +48 tests (15 + 7 + 3 + 15 + 8).
- JUnit names present: test_build_requirements, test_spot_label_locked, test_castle_gate, test_build_choice, test_upgrade_at_spot, test_build_requirement_validation, test_bot_defers_locked, test_playtest_strategies, test_balance_acceptance (the last passes with no pin edited).
- Replays (each `--twice`): smoke `2599c7c2...` 703 ticks, army `f7a967ed...` 1353, walls `bfb05fc7...` 1961 (all matched their golden files); full_idle outcome=won ticks=6911 digest `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`, identical to the RESEARCH E3 baseline.
- `bash tools/gate_stress.sh --twice`: GATE_OK enemies=300 crossed=300 stuck=0.
- `bash tools/lint.sh`: clean (414 files).
- Acceptance criteria re-checked: field and constant strings present in the named files, `data/buildings/tower.tres` not among the committed files (git show --stat), full_idle digest unchanged.

## Known Stubs

None. No file created or modified carries a placeholder or empty data source.

## Issues Encountered

- Two small iterations on my own tests only (a label test that built the tower in the wrong context, and long comment lines flagged by gdlint); no source bug found by the suite.
- The assert total of the full suite varies by a few dozen between identical runs (timing-dependent polling in e2e tests); pre-existing, not caused by this plan.

## Threat Flags

None. The only new surface is data fields read by the existing build gate; T-05-11 and T-05-12 are mitigated and pinned by test_build_requirement_validation and test_build_requirements (gold unchanged, command_rejected announced).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The mechanism is complete for plan 05-07's Field lock ("Needs a Mill" via requires_spot / requires_spot_tier on the Field plots) and for Mill III / Harbor II arriving gated with their buildings.
- Plan 05-11 gates the shipped top tiers (House III, Tower II, Barracks III, Archery Range III, Wall III) together with the castle-aware bot orders and the balance re-pin. Until then no shipped strategy defers; the bot's CHOICE_REQUIRED path is untouched (05-11 gives the bots their picks), so a bot that reaches a tier with cards still waits there.
- BLDG-09 is recorded in `requirements-completed` as this plan's declared requirement but is NOT ticked in REQUIREMENTS.md: plans 05-11 and 05-12 still declare it (shared-ID gate), and the shipped gating lands in 05-11.

## Self-Check: PASSED

- Created files exist: build_requirements.gd, build_requirement_validation.gd, fixture_map_gate.tres, the five test scripts (verified with `[ -f ]`).
- Commits found: 2d56716, 5b3106c, dc191f8.
- All acceptance criteria of both tasks re-run and passing.
