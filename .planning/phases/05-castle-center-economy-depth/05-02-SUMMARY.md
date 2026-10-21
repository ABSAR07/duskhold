---
phase: 05-castle-center-economy-depth
plan: 02
subsystem: simulation
tags: [godot, gdscript, castle, choice-cards, build-gate, stat-stack, world-space-ui, determinism, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "StatStack (add_source, has_source, int_value), CastleState getters and its trailing stat_stack parameter, RunContext.stat_stack (plan 05-01)"
provides:
  - "ChoiceDef, BuildingTierDef.choices and BuildSpotDef.is_castle: any building tier may carry cards, the castle plot is marked in data"
  - "data/buildings/castle_center.tres (four tiers, tier II offers four cards) and the four tier-II ability resources in data/abilities/"
  - "castle_plot appended as spot 15 of the prototype map: stands at tier I silently, never a target, payer, rebuild or plot disc; CastleState owns its health"
  - "CastleState.has_tiers(), tier(), plot_id(); health, arrow and base income from the tier data at tiers II to IV, the map's own fields at tier I and on maps without a castle plot"
  - "BuildIntent.choice_id, CommandProcessor.CHOICE_REQUIRED and BAD_CHOICE (after CANNOT_AFFORD), validate_build(spot, choice_id = &\"\")"
  - "SimEvents.choice_picked(spot_id, tier, choice_id) in SimSignals.ALL and SimRecorder.HANDLED; ChoiceLedger arming each pick through the StatStack, RunContext.choices"
  - "CardPicker (keys 1 to 4, no pre-highlight), CardRow (world-space row of four cards), CardRowModel, MapRoot.get_cards(); BuildHoldController carries the highlighted card on the one BuildIntent"
  - "Digit hand-over: keys 1 to 4 pick cards while the cards show, control groups otherwise; 5 to 9 and 0 never handed over"
  - "tests/unit/test_nav_layout_pin.gd and test_prototype_map_economy.gd: the nav grid and the plot counts pinned in one place each"
affects: [05-03 twelve cards and castle label, 05-04 mouse, numbers on highlight, icons and castle look, 05-05 requirement gate, 05-06 to 05-09 new plots, 05-11 balance fit, phase-06 tower specialisations, phase-07 unit choices]

actuals:
  tokens: 31000
  tasks: 2
  commits: 3
plan_head_before: e8f57d0df47988676fe9bb445a93cd3dfc43b73a
plan_head_after: a44121ff5d709c5cf81cc677ebdd175bede4a0cf

tech-stack:
  added: []
  patterns:
    - "A branching purchase is one BuildIntent carrying choice_id; CommandProcessor validates it, spends, raises the tier, then emits choice_picked; ChoiceLedger (a sibling listener, like WallSystem) arms the card under its own id through the StatStack"
    - "A plot whose kind is data (is_castle, like wall_run): BuildingSystem keeps one private _is_plain(spot) predicate and every guard that is about the castle tests is_castle, so no wall-plot path changed"
    - "The castle instance is a tier carrier only (health_of and max_health_of read 0, a documented sentinel): CastleState is the single owner of the castle's health"
    - "CardPicker is presentation state that refreshes itself from the hold's focus, building, phase and gold signals; the cards show exactly when validate_build(focused) answers CHOICE_REQUIRED"
    - "Modal digit rule: CommandKeyController keeps reading every digit for its edge state and skips only the group call for keys 1 to 4 while CardPicker.is_showing()"

key-files:
  created:
    - simulation/defs/choice_def.gd
    - simulation/buildings/choice_ledger.gd
    - input/card_picker.gd
    - ui/world/card_row.gd
    - ui/world/card_row_model.gd
    - data/buildings/castle_center.tres
    - data/abilities/royal_training.tres
    - data/abilities/commander.tres
    - data/abilities/masons.tres
    - data/abilities/prosperity.tres
    - tests/fixtures/fixture_map_castle.tres
    - tests/unit/test_build_choice.gd
    - tests/unit/test_castle_tiers.gd
    - tests/unit/test_castle_data_contract.gd
    - tests/unit/test_card_row_model.gd
    - tests/unit/test_nav_layout_pin.gd
    - tests/unit/test_prototype_map_economy.gd
    - tests/e2e/test_card_row.gd
    - tests/e2e/test_card_digit_handover.gd
  modified:
    - simulation/defs/building_tier_def.gd
    - simulation/defs/build_spot_def.gd
    - simulation/defs/map_config.gd
    - simulation/buildings/building_system.gd
    - simulation/castle/castle_state.gd
    - simulation/commands/build_intent.gd
    - simulation/commands/command_processor.gd
    - simulation/events/sim_events.gd
    - simulation/run/run_context.gd
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - data/maps/prototype_map.tres
    - input/build_hold_controller.gd
    - input/command_key_controller.gd
    - presentation/map/map_root.gd
    - presentation/map/prototype_map.tscn
    - presentation/buildings/building_views.gd
    - ui/overlay/debug_overlay_model.gd

key-decisions:
  - "The castle plot's id is castle_plot (castle is the payout key) at (0, 0, 4.2): 0.7 m outside the castle radius, inside the ring wall, 2.8 m from the king spawn so the label does not pop at spawn; it is appended after the fourteen Phase 4 plots, so no PendingHits building index moves"
  - "Tier I of castle_center carries only a never-charged cost; its health, arrow and base income stay the map's own fields (70, 2 / 22 m / 1.5 s / 27 m/s, 1), so no number has two homes and a map copy that edits them keeps working"
  - "validate_build order is NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD, CHOICE_REQUIRED, BAD_CHOICE: a player without the gold sees the price, not a pick prompt; a card is offered once per run because only its own tier lists it"
  - "No card is pre-highlighted (research A7): a hold with no highlight is refused with choice_required and the existing denied bump"
  - "Ctrl plus a digit 1 to 4 also picks a card while the cards show (the hand-over skips the whole group call, so no group is stored by accident)"
  - "The card row is 2.4 by 3.2 m per card at 7.6 m above the plot (the plan said about 1.7 by 2.3 m and 5.0): the first real-window look showed the names wrapping mid word and the cards covering the spot label; sizes are for plan 05-04 and the owner to judge"

patterns-established:
  - "Every existing test that walked all spots as plain plots now skips or specially handles is_castle (the castle stands from the start and has no disc), so later plots can follow the same rule"
  - "Pin tests for map shape live in one script each: test_prototype_map_economy (counts) and test_nav_layout_pin (grid); later plans raise the counts there"

requirements-completed: []

coverage:
  - id: D1
    description: "Riding up to the castle by day with tier II affordable shows four cards above it; keys 1 to 4 highlight one (raised, brighter); the hold starts only with a highlight; the highlighted card at hold start is bought; castle II with the ability armed, in the real scene"
    requirement: BLDG-08
    verification:
      - kind: e2e
        ref: "tests/e2e/test_card_row.gd (12 tests, real prototype scene)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A tier with cards cannot be bought without one: CHOICE_REQUIRED, BAD_CHOICE after CANNOT_AFFORD, nothing spent on a rejection, building_built then choice_picked, the card armed once and never offered again"
    requirement: BLDG-05
    verification:
      - kind: unit
        ref: "tests/unit/test_build_choice.gd (18 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The castle is a plot at tier I that CastleState reads: map numbers at tier I, tier data at II to IV, never a target, payer, rebuild or damage target in BuildingSystem; maps without a castle plot keep the map numbers"
    requirement: BLDG-08
    verification:
      - kind: unit
        ref: "tests/unit/test_castle_tiers.gd (16 tests) and tests/unit/test_castle_data_contract.gd (8 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Card row content: four cards in the authored order, one highlighted, none for a plain plot or the top tier, digit n addresses card n"
    requirement: UI-02
    verification:
      - kind: unit
        ref: "tests/unit/test_card_row_model.gd (11 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "While the cards show, digits 1 to 4 pick cards and recall no group; otherwise they recall groups; 5 to 9 and 0 always do"
    requirement: UI-02
    verification:
      - kind: e2e
        ref: "tests/e2e/test_card_digit_handover.gd (6 tests, 2 red before the change)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The nav grid (origin (-82, -82), 82 by 67) and the plot counts (15 spots, one castle plot, 14 buildable) are pinned; smoke, army and walls goldens and the full_idle digest are byte-identical"
    verification:
      - kind: unit
        ref: "tests/unit/test_nav_layout_pin.gd (6) and tests/unit/test_prototype_map_economy.gd (8)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh smoke, army, walls with --expect-file and full_idle --twice"
        status: pass
    human_judgment: false
  - id: D7
    description: "How the card row reads at the shipped camera: legibility, size, the raised and brighter highlight, the icon slot left empty until plan 05-04"
    verification: []
    human_judgment: true
    rationale: "Pixels are not asserted (the headless renderer); one real-window look was taken by the executor and the sizes were tuned from it, but whether the cards read well is a feel judgment for the end-of-phase check"

duration: 75min
completed: 2026-10-21
status: complete
---

# Phase 5 Plan 02: Castle Tracer Summary

**Ride up to the castle by day, press 1 to 4 to raise one of four cards above it, hold, and the castle rises to tier II with that ability armed through the stat stack for the rest of the run, recorded in the replay, with all four replay digests unchanged**

## Performance

- **Duration:** 75 min
- **Started:** 2026-10-21T11:28:35Z
- **Completed:** 2026-10-21T12:44Z
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd hand-over and pins)
- **Files modified:** 57 changed (19 created and 18 modified source, test and data files, plus 20 other files: `.gd.uid` files and tests updated for the castle plot)
- **Commits:** 3 task commits (feat tracer, test RED, feat GREEN)

## Accomplishments

- Data: `ChoiceDef`, `BuildingTierDef.choices` and `BuildSpotDef.is_castle`; `castle_center.tres` with four tiers (costs 6 / 10 / 16, health 100 / 140 / 200, arrow damage 3 / 4 / 5, dawn income 2 / 3 / 4; tier I only a never-charged cost) and the tier-II cards Royal Training, Commander, Masons and Prosperity as `data/abilities/*.tres` (every flavour line at most 70 characters, icons empty).
- The castle plot: `castle_plot` appended as spot 15 at (0, 0, 4.2). `BuildingSystem` stands it at tier I with no event; `standing_spot_ids` and `dawn_income_by_spot` skip it through one private `_is_plain`, `health_of` and `max_health_of` read 0 for it, hits on it are dropped silently, it is never destroyed or rebuilt. `BuildingViews` draws no disc or model for it (the keep stays the landmark). `CastleState` reads its tier: map fields at tier I, tier data at II to IV, whole health on every upgrade.
- The gate: `BuildIntent.choice_id`; `validate_build(spot, choice_id)` answers NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD, CHOICE_REQUIRED, BAD_CHOICE; a rejection is announced on `command_rejected` and spends nothing; a purchase emits `building_built` then `choice_picked(spot, tier, choice)`, which `ChoiceLedger` turns into `stat_stack.add_source(choice_id, card.modifiers)` once. `choice_picked` is in `SimSignals.ALL`, `SimRecorder.HANDLED` and the recorder (one digest line, right after the `building_built` line).
- Presentation: `CardPicker` shows the cards exactly when the command gate would say CHOICE_REQUIRED for the focused spot (day, in range, affordable), keys 1 to 4 highlight, nothing is pre-highlighted, the highlight resets on hide, spot change, tier change and night, and is frozen while a hold runs. `CardRow` draws four unshaded quads (empty icon slot, name, wrapped flavour, key digit) above the castle, facing the camera, scaled by `SpotLabel`'s distance rule, the highlighted card raised and brighter. `BuildHoldController` reads the highlight at hold start and the card rides the one `BuildIntent`.
- Digit hand-over (Task 2): `CommandKeyController` keeps reading every digit and skips only the group call for keys 1 to 4 while the cards show (Ctrl plus a digit included); 5 to 9 and 0 are never handed over.
- Pins: the nav grid of the shipped map (origin (-82, -82), 82 by 67, 2 m cells, every plot inside) and the plot counts (15 spots, one castle plot at index 14, 14 buildable plots) are each pinned in one script.

## Task Commits

1. **Task 1: Tracer, castle plot, build gate, ledger, card row** - `f3ec749` (feat)
2. **Task 2 RED: failing digit hand-over test and the pins** - `5121104` (test)
3. **Task 2 GREEN: digit keys 1 to 4 go to the cards while they show** - `a44121f` (feat)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Verification (measured)

- Baseline before the first edit (orchestrator's wave-1 gate on e8f57d0): 231 scripts / 2156 tests / 55813 asserts, lint clean.
- Replays after Task 1 and again after Task 2 (identical lines both times):
  - `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c2...` (expect-file golden)
  - `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967ed...` (golden)
  - `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7...` (golden)
  - `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`
  Each with `--twice`; the castle plot, its tier I data and the new nodes changed nothing in play.
- Full suite: first run after the tracer 236 scripts / 2221 tests, 8 failing (all existing tests that walked every spot as a plain plot, fixed, see Deviations); second run 236 scripts / 2221 tests / 56074 asserts, all passing, exit 0. After Task 2: **239 scripts / 2241 tests / 56376 asserts, all passing, exit 0** (baseline 231 / 2156 / 55813: +8 scripts, +85 tests; the assert total is timing dependent in some e2e scripts, as plan 05-01 noted).
- New scripts and tests: test_build_choice 18, test_castle_tiers 16, test_castle_data_contract 8, test_card_row_model 11, test_card_row (e2e) 12, test_card_digit_handover (e2e) 6, test_nav_layout_pin 6, test_prototype_map_economy 8.
- `bash tools/lint.sh`: clean (397 files). `grep -c '^func [a-z]'`: BuildingSystem 20 (at the cap, no public method added), CastleState 15 (cap 20).
- One real-window run (scratch script, 1280 x 720, Forward+): the king beside the castle plot with gold shows the four cards above the keep and the spot label "Castle II" below them; key 2 raises and brightens card 2. The first look wrapped "Commander" mid word and let the cards cover the label, which set the final sizes (see Decisions).

## TDD record (Task 2)

- RED (`5121104`): `test_card_digit_handover` failed 2 of 6 on the planned behaviour (`a digit key recalls a group while the cards show`: "Expected ... to NOT emit signal [group_recalled]: and recalled no group", "the selection is still empty"; and Ctrl plus 3 "stores nothing in group 3"). The other four (group 5 recalls, key 0 recalls, the digit recalls after leaving range, the digit recalls while the castle is unaffordable) passed at once because they pin behaviour that already held and must keep holding. `test_nav_layout_pin` (6) and `test_prototype_map_economy` (8) passed at once: they pin facts Task 1 already built (the castle plot inside the grid, 15 spots), which the plan asks for as pins, not as new behaviour.
- GREEN (`a44121f`): handover 6 of 6, `test_control_group_keys` 9 of 9, full suite green.
- This plan is `type: execute`, so no `tdd-red-evidence` record was filed; the failing run is the evidence above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing tests assumed every spot is a plain plot**
- **Found during:** Task 1 (first full-suite run: 8 failures in 5 scripts)
- **Issue:** `test_build_spot` built every spot without a card and expected no instance on any spot at the start; `test_build_flow` counted every instance; `test_prototype_map_data` expected the later spots to field units; `test_upgrade_at_spot` expected a disc on every spot and four marker kinds; `test_loop_tuning_contract` took the castle's never-charged tier I cost (1 coin, 0.25 s) as the cheapest purchase.
- **Fix:** each test now treats the castle plot as what it is: `test_build_spot` buys it with its first card and skips it in the empty-start check, the counts and loops skip `is_castle`, `test_upgrade_at_spot` asserts the castle plot has no disc, and the cheapest-tier helper leaves out a standing castle's tier I.
- **Files modified:** tests/unit/test_build_spot.gd, tests/integration/test_build_flow.gd, tests/unit/test_prototype_map_data.gd, tests/e2e/test_upgrade_at_spot.gd, tests/unit/test_loop_tuning_contract.gd
- **Verification:** each script run alone, then the full suite (236 / 2221 all passing)
- **Committed in:** f3ec749

**2. [Rule 2 - Missing critical] `MapConfig.validate()` and the overlay for the castle plot**
- **Found during:** Task 1
- **Issue:** two castle plots (or a castle plot that is also a wall plot) would be armed silently; the F3 overlay's building count would have started counting the standing castle plot as a built building.
- **Fix:** `validate()` reports more than one castle plot and a castle plot that carries a wall run (pinned in `test_castle_tiers`); `DebugOverlayModel._count_buildings` skips `is_castle`.
- **Files modified:** simulation/defs/map_config.gd, ui/overlay/debug_overlay_model.gd, tests/unit/test_castle_tiers.gd
- **Committed in:** f3ec749

**3. [Rule 2 - Missing critical] Stat refresh must not clamp the castle instance**
- **Found during:** Task 1 (design: `BuildingSystem._on_stats_changed` walked every non-wall instance)
- **Issue:** with the castle instance's maximum at the 0 sentinel, a Masons pick would have clamped its health to `[1, 0]`.
- **Fix:** the refresh uses `_is_plain` and skips the castle plot; pinned by `test_after_a_purchase_the_instance_still_reads_zero_while_the_castle_reads_the_tier` (buys Masons).
- **Files modified:** simulation/buildings/building_system.gd
- **Committed in:** f3ec749

**4. [Rule 2 - Missing critical] Contract test for the shipped castle numbers**
- **Found during:** Task 1 (project rule: every tunable number is `.tres` data pinned by a contract test)
- **Fix:** added `tests/unit/test_castle_data_contract.gd` (8 tests: four tiers, costs, health, arrow, income, the arrow's reach, interval and speed equal to the map's, tier I carrying no number, the four cards, valid modifiers, the shipped map validating clean). Plan 05-11 re-pins it deliberately.
- **Committed in:** f3ec749

**5. Card row size and height differ from the plan's "about" numbers**
- The plan said about 1.7 by 2.3 m per card and a row 5.0 m above the plot. The first real-window look wrapped names mid word and the cards covered the spot label, so the shipped values are 2.4 by 3.2 m per card, 0.3 m gaps, a row 7.6 m above the plot, text wrapped at 220 px. These are layout constants in `card_row.gd`, not a behaviour change; the look is judged by the owner at the end of the phase.

---

**Total deviations:** 4 auto-fixed (1 blocking, 3 missing critical) plus 1 layout value change. **Impact on plan:** none on scope or interfaces; every listed interface and acceptance criterion is as written.

## Observations for the orchestrator

- **Protected-branch assertion:** `gsd_run query git.base-branch --is-protected` answers `true` for `gsd/phase-01-foundation-day-loop`, because the GitHub default branch is this phase branch (STATE decision 01-03). The branch is where HEAD was at spawn and where every plan of the project has committed (the 01-01 owner decision records it), so I did not halt and did not set `git.allow_default_branch_commits`; the three task commits are on it. If the orchestrator wants the override recorded in `.planning/config.json` it is a one-line change that I left to the owner.
- Some tracked files carry CRLF in the working tree (`map_config.gd`, `map_root.gd`, `command_key_controller.gd`, `sim_recorder.gd`, `build_hold_controller.gd`, `debug_overlay_model.gd`): my edits kept each file's own line endings; git normalises them on commit.

## Issues Encountered

- The shell heredoc lost a quote once while writing a Python edit script; the scripts were written with the Write tool afterwards (as the environment notes advise).
- `ui/world/spot_label_model.gd` and `BuildingTierDef.effect_line()` still print base tier numbers (plan 05-01's note): the castle label shows "+2 gold at dawn" for tier II from the tier data, which is the base value (no source touches it yet except Prosperity's +1). Plan 05-03 owns the castle label and should read the stack.

## Known Stubs

- `ChoiceDef.icon` is null on all four cards, so each card draws an empty dark icon slot (`ui/world/card_row.gd`, `data/abilities/*.tres`). Intentional per the plan; plan 05-04 adds the twelve icons. Recorded in `.planning/WINDOWS.md`.

## Threat Flags

None. `choice_id` enters through `BuildIntent` only, is validated before anything is spent (T-05-04), is armed through `StatStack.add_source` which refuses out-of-range modifiers (T-05-05), and `choice_picked` is in the replay digest (T-05-06). No new network, file or auth surface.

## Next Phase Readiness

- Plan 05-03 can add the tier III and IV cards (`choices` on tiers 3 and 4 of `castle_center.tres`), rename the candidates that echo Thronefall's perk names, and read castle numbers through `ctx.stat_stack` on the castle label. `CardRowModel.cards`, `CardPicker` and `ChoiceLedger` are generic: nothing in them names the castle.
- `test_prototype_map_economy` is the single place the plot counts are raised (22 buildable plots and 23 spots at the end of the phase); `test_nav_layout_pin` must stay unchanged unless a plan says otherwise.
- `BuildingSystem` is still at 20 public methods; the castle plot logic is private helpers only. `CommandProcessor._init` still has 7 parameters.
- `tools/replay/replay_driver.gd` `Tally._role_of` would class a bought castle as `towers` (its tiers attack); no bot buys the castle yet, plan 05-11 must give it a role when the bots do.

## Self-Check: PASSED

All created files exist on disk, commits f3ec749, 5121104 and a44121f exist, `class_name ChoiceDef`, `var choices: Array[ChoiceDef]`, `var is_castle: bool = false`, `const CHOICE_REQUIRED`, `const BAD_CHOICE`, `choice_picked.emit(`, `var choice_id: StringName`, `"choice_picked"` in both sim_signals.gd and sim_recorder.gd, the `CardPicker` and `CardRow` scene nodes, `func get_cards(` and `is_showing()` in command_key_controller.gd are all present, `grep -c '^func [a-z]'` prints 20 for building_system.gd, and both tasks' verify chains were run (full suite, four replays, lint).

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-21*
