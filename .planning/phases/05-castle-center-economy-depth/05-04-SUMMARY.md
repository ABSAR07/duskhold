---
phase: 05-castle-center-economy-depth
plan: 04
subsystem: ui
tags: [godot, gdscript, choice-cards, mouse-picking, world-space-ui, svg-icons, castle-keep, screenshots, gut]

requires:
  - phase: 05-castle-center-economy-depth
    provides: "CardPicker, CardRow, CardRowModel, castle_plot and the four-card rows (plan 05-02); ChoiceDef.effect_line(), the twelve cards, the castle label Picks line (plan 05-03)"
provides:
  - "Mouse on the cards: CardRowModel.hit_test, CardRow.card_rects (Camera3D.unproject_position per corner), CardPicker._input (hover and left click highlight, a press is consumed only when it lands on a card, a click never buys)"
  - "The numbers line (ChoiceDef.effect_line()) printed on the highlighted card only, by key or by mouse (CardRow.numbers_text); CardRowModel cards() entries gain effect_line and key_hint"
  - "Twelve first-party CC0 SVG card icons under assets/first_party/card_icons/ set on every ChoiceDef, a First-party assets section in ASSETS.md, CardRow.icon_of, and the Kenney keyboard_1 to keyboard_4 key tile on each card"
  - "castle_center_t2, t3 and t4 keep scenes composed from the seven Castle Kit GLBs, catalog entries, BuildingViews._swap_castle_keep (the keep grows on the castle plot's building_built, the bar follows)"
  - "ShotEconomyScenarios (castle_cards, castle_tier_four), ALL_SHOTS and tools/screenshot.sh at 39 shots in four blocks"
affects: [05-05 requirement gate, 05-06 to 05-09 new plots (append Phase 5 shots to ShotEconomyScenarios), 05-11 balance fit, 05-12 playtest packet (research A10), phase-08 art pass (icons and keeps may be replaced)]

actuals:
  tokens: 26800
  tasks: 2
  commits: 3
plan_head_before: 617c4861d0beb88ae7e8f112d2fbb1c8848fdddf
plan_head_after: 989238204517088c39fbca3b855c87b5a912fc39

tech-stack:
  added: []
  patterns:
    - "Mouse picking on world-space UI is rectangles only: each card's four corners through Camera3D.unproject_position into a bounding Rect2, CardRowModel.hit_test on the list (inclusive edges, lower index wins); no collider, no physics, no SubViewport"
    - "A picker that must beat the selection layer takes the press in _input and calls set_input_as_handled() only when the press lands on its own target (and its matching release), so a press anywhere else still reaches _unhandled_input"
    - "A keep swap moves the existing hurt-only HealthBar3D to the new model (remove_child, add_child, reset height_offset and position.y) instead of rebuilding it, so castle_damaged and castle_destroyed keep their one connection"
    - "First-party art lives in assets/first_party/ and is logged in prose bullets in ASSETS.md (no table row, so the third-party log parser is untouched)"

key-files:
  created:
    - assets/first_party/card_icons/ (twelve .svg and their .import files)
    - presentation/buildings/models/castle_center_t2.tscn
    - presentation/buildings/models/castle_center_t3.tscn
    - presentation/buildings/models/castle_center_t4.tscn
    - tools/screenshot/shot_economy_scenarios.gd
    - tests/e2e/test_card_mouse.gd
    - tests/e2e/test_castle_views.gd
    - tests/unit/test_card_icons.gd
  modified:
    - input/card_picker.gd
    - ui/world/card_row.gd
    - ui/world/card_row_model.gd
    - presentation/buildings/building_views.gd
    - presentation/buildings/building_view_catalog.tres
    - data/abilities/ (all twelve .tres: icon field)
    - ASSETS.md
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot.sh
    - tests/unit/test_card_row_model.gd
    - tests/unit/test_shot_list.gd
    - tests/unit/test_castle_data_contract.gd

key-decisions:
  - "A mouse highlight is sticky: pointing at a card highlights it and moving the pointer off every card leaves the highlight where it was, so the player can click or point at a card and then hold the action key with the mouse anywhere (D-05)"
  - "The card rectangle follows the card as drawn, raised or not (card_rects projects the card's own global transform); the sticky highlight means the raise cannot make the highlight flicker at a card edge"
  - "Cards are 3.4 by 3.2 m (were 2.4 by 3.2): the first real-window look of the numbers line showed it overlapping the three-line flavour of a narrow card; wider cards give the text 320 px so flavour takes at most three lines and numbers two"
  - "The key digit is the Kenney Input Prompts tile (GlyphResolver.KEYBOARD_DIR keyboard_N.png) in the card's top left corner, replacing the plain digit Label3D of plan 05-02; a digit with no tile file draws nothing"
  - "The icon sprite gets render_priority 2 above the dark slot quad: without it transparency sorting drew the slot over the icon and the icons looked dim in the first screenshot"
  - "The tier IV keep is 15 m tall (four storeys plus roof); at the shipped camera its roof tip and flag are cropped by the top of the screen (see the shot review), accepted as the growth reads at a glance; castle_tier_four stands the king beside and slightly behind the plot to show more of it"
  - "castle_tier_four and castle_cards run with 60 gold (ShotEconomyScenarios.SHOT_GOLD), not the shared 30: the three upgrades cost 32; test_shot_list expects the economy value for them"

patterns-established:
  - "Later Phase 5 shot plans append their shot names to ShotScenarios.ALL_SHOTS, tools/screenshot.sh and ShotEconomyScenarios.ECONOMY_SHOTS, and raise the counts in test_shot_list (39 now)"

requirements-completed: [UI-02, BLDG-05, BLDG-08]

coverage:
  - id: D1
    description: "Pointing the mouse at a world-space card highlights it and prints its numbers line; a left click on a card highlights it, is consumed (no drag box, the squad stays selected), never buys or spends and emits no command_rejected; a click away from the cards still clears the selection; digit keys move the highlight after a click; the hold buys the clicked card"
    requirement: BLDG-05
    verification:
      - kind: e2e
        ref: "tests/e2e/test_card_mouse.gd (13 tests, real scene in a 1280x720 SubViewport)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CardRowModel.hit_test (shared edge and overlap resolve to the lower index, -1 outside or for no rectangles) and the card entries' effect_line and key_hint"
    requirement: UI-02
    verification:
      - kind: unit
        ref: "tests/unit/test_card_row_model.gd (17 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every one of the twelve cards has its own first-party SVG icon named after its id, CardRow draws the icon and the Kenney key tile of its key, a card with no icon draws an empty slot and stays valid, ASSETS.md logs the icons as CC0-1.0 in prose"
    requirement: UI-02
    verification:
      - kind: unit
        ref: "tests/unit/test_card_icons.gd (10 tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_attribution_log.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "The keep swaps to the catalog scene of each castle tier (II, III, IV), grows taller each time, keeps one CastleCenter node on the same spot, keeps its hurt-only bar bound and the collapse path working, and the castle plot still has no plot disc"
    requirement: BLDG-08
    verification:
      - kind: e2e
        ref: "tests/e2e/test_castle_views.gd (8 tests, real scene)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The shot list is 39 distinct shots in four blocks (Phase 1 15, Phase 3 18, Phase 4 4, Phase 5 2), the wrapper and the scenarios agree, each Phase 5 shot works on a deep copy of the shipped map"
    verification:
      - kind: unit
        ref: "tests/unit/test_shot_list.gd (17 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "smoke, army and walls replay byte-identical to their goldens and full_idle replays twice to digest 4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf (nothing in this plan touches the simulation)"
    verification:
      - kind: other
        ref: "bash tools/replay.sh smoke, army, walls with --expect-file and full_idle, each --twice, after both tasks"
        status: pass
    human_judgment: false
  - id: D7
    description: "How the cards read at the shipped camera (size, the HUD banner overlapping the top of the raised card, icon art, key tile) and how the keep looks at each tier (the tier IV roof tip is cropped at the default zoom); research assumption A10 (cards re-appearing each time the king passes with enough gold)"
    verification: []
    human_judgment: true
    rationale: "Legibility and look are judgments no test asserts; two real-window shots were reviewed by the executor (lines below) but the owner judges the art and the feel at the end-of-phase check"

duration: 78min
completed: 2026-10-21
status: complete
---

# Phase 5 Plan 04: Cards for the Mouse and the Eye Summary

**Hover or click a card above the castle to highlight it (a click is consumed by the card, never buys and never touches the squad selection), the highlighted card prints its exact generated numbers, every card shows its own first-party SVG icon and Kenney key tile, and the keep grows through three new scenes as the castle tiers rise, with all four replay digests unchanged**

## Performance

- **Duration:** about 78 min (the start time was not recorded; estimated from the 14:14Z dispatch gate)
- **Completed:** 2026-10-21T15:40Z
- **Tasks:** 2 (Task 1 tracer, Task 2 tdd)
- **Files:** 58 changed in the three task commits (12 SVG icons and 12 `.import` files, 12 ability resources, 3 keep scenes, 8 tests and tools, 11 source and doc files)
- **Commits:** 3 task commits (feat tracer, test RED, feat GREEN)

## Accomplishments

- Mouse (Task 1): `CardRowModel.hit_test` (edges inclusive, lower index wins), `CardRow.card_rects(camera)` (the bounding box of each card's four corners through `Camera3D.unproject_position`; a card behind the camera is parked off screen), `CardPicker._input` (motion highlights and is never consumed; a left press on a card highlights, is consumed with `set_input_as_handled()` and so is its release; any other press reaches `SelectionController`). Nothing else changed: `BuildHoldController` still reads the highlight at hold start, so only the hold buys.
- Numbers (D-07): cards() entries carry `effect_line` and `key_hint`; `CardRow` prints the numbers Label3D on the highlighted card only (`numbers_text(index)`), the same by key or mouse.
- Icons and key tiles (Task 2): twelve flat vector SVGs (crown and sword, banner, trowel and brick, coin stack, axe, gear and arrow, horn, mail shirt, shield and spear, arrow volley, tower and hammer, sun over coins) at 128 by 128 in two or three colours, set on every `ChoiceDef`, logged in a new `## First-party assets` section of `ASSETS.md` (prose, CC0-1.0); `CardRow.icon_of` and a `KeyTile` Sprite3D with the logged Kenney `keyboard_N.png` on each card.
- Keep per tier: `castle_center_t2` (a second keep storey and a flag on each corner turret), `t3` (raised corner turrets and a second row of wall between them), `t4` (the high roof on a third storey); all composed from the seven Castle Kit GLBs already in the repository. `BuildingViews._swap_castle_keep` replaces the keep on the castle plot's `building_built`, moves the hurt-only bar to the new model and raises it above the taller keep.
- Shots: `ShotEconomyScenarios` with `castle_cards` and `castle_tier_four`; `ALL_SHOTS` and `tools/screenshot.sh` at 39.

## Task Commits

1. **Task 1: Tracer, mouse hover and click highlight, numbers on the highlighted card** - `4ae6c46` (feat)
2. **Task 2 RED: failing icon, keep and shot-list tests** - `585f29a` (test)
3. **Task 2 GREEN: icons, key tiles, keep per tier, two shots** - `9892382` (feat)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Verification (measured)

- Baseline at dispatch (HEAD 617c486): 243 scripts / 2291 tests / 56767 asserts, lint clean (403 files).
- After Task 1: **244 scripts / 2310 tests / 56946 asserts, all passing, exit 0** (+1 script test_card_mouse with 13 tests, +6 tests in test_card_row_model). JUnit lists test_card_mouse, test_card_row_model, test_card_row.gd, test_box_select and test_squad_selection. Tracer verified end to end, expanding.
- After Task 2, first run: 246 scripts / 2331 tests / 57122 asserts, 1 failing (`test_castle_data_contract#test_every_card_is_valid_data` still pinned `icon == null`, see Deviations); fixed. **Final run: 246 scripts / 2331 tests / 57148 asserts, all passing, exit 0.** JUnit lists test_card_icons, test_castle_views, test_shot_list, test_attribution_log and test_building_view_catalog. +2 scripts, +21 tests in Task 2 (10 + 8 + 3).
- Replays after Task 1 and again after Task 2, identical, each with `--twice`:
  - `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden)
  - `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (golden)
  - `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (golden)
  - `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`
- `bash tools/lint.sh`: clean (407 files). Public method counts: CardRow 7, CardPicker 7, BuildingViews 5 (cap 20).
- Mutation probe (Task 1): removing `set_input_as_handled()` from the card press made 2 of the 13 mouse tests fail (the squad selection cleared and the drag box appeared), then the file was restored.
- Acceptance greps: twelve SVGs, every ability resource names `res://assets/first_party/card_icons/`, `ASSETS.md` has `## First-party assets` and `CC0-1.0`, the catalog names the three keep scenes, `tools/screenshot.sh` lists both shots, `EXPECTED_SHOT_COUNT: int = 39`.
- Real-window shots: `bash tools/screenshot.sh castle_cards castle_tier_four` exit 0, both PNGs saved (1280 by 720, Forward+, RTX 3060 laptop), no script error in either log.

### Shot review (each PNG opened with the Read tool)

- **castle_cards:** four cards side by side above the keep, each with its coloured icon, a white key tile 1 to 4 in its top left corner, its name and one or two flavour lines; card 2 (Commander) is raised and brighter and prints the gold numbers line "+25% unit health, +25% unit damage" under its flavour without overlapping it; the label "Castle II / Health 100 · Arrow 3 · 2 gold at dawn" reads below the cards. One blemish: the top of the raised card sits under the HUD "Night 1 of 8" banner, which draws over it.
- **castle_tier_four:** the tier IV keep is clearly not the tier I keep: a four-storey tower with its high roof, four raised corner turrets each with a flag, and a second row of wall between them; the label reads "Castle IV / Max tier / Royal Training · Engineers · Golden Age"; the king stands beside the label, clear of it. The very top (roof tip and flag) is cropped by the top of the screen at the camera's farthest zoom.

## TDD record (Task 2)

- RED (`585f29a`): `test_card_icons` 6 of 10 failed on the planned assertions (no icon on any of the twelve cards, no icon file under `assets/first_party/card_icons/`, no key tile node, `icon_of` null, no First-party assets section in ASSETS.md); the other 4 (twelve cards exist, null icon draws an empty slot and no error, an out-of-range index answers null, a null-icon card validates) pin behaviour that already held. `test_castle_views` 3 of 8 failed (no catalog scene for castle tiers 2 to 4, the keep stays the tier I scene after each purchase, the keep never gets taller); the other five pin behaviour that already held (bar bound and shown when hurt, no plot disc, rubble on collapse). `test_shot_list` 4 of 17 failed (37 instead of 39 shots in the wrapper and in ALL_SHOTS twice, the two economy shots not listed, the four-block test reading past the 37-shot list). To keep RED on assertions and not on parse errors, the RED commit carried two scaffolds: `CardRow.icon_of` returning null and `ShotEconomyScenarios` with an empty shot list.
- GREEN (`9892382`): all three scripts pass (10, 8 and 17), full suite green after the contract-test fix.
- This plan is `type: execute`, so no `tdd-red-evidence` record was filed; the failing runs above are the evidence.

## Decisions Made

- See `key-decisions` in the frontmatter. The mouse highlight is sticky; cards are wider so the numbers fit; the keep is tall at tier IV and cropped at the default camera.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The contract test still pinned the empty icon slot**
- **Found during:** Task 2 (first full-suite run: `test_castle_data_contract#test_every_card_is_valid_data`, 12 failed asserts)
- **Issue:** plan 05-02 pinned `assert_null(card.icon, "no icon yet (plan 05-04)")` for the tier II cards; this plan sets the icons.
- **Fix:** the assert now reads `assert_not_null(card.icon, ...)` (`test_card_icons` pins the exact path of each icon).
- **Files modified:** tests/unit/test_castle_data_contract.gd
- **Verification:** script alone 8 of 8, then the full suite
- **Committed in:** 9892382

**2. [Rule 3 - Blocking] The shared shot-gold test expected 30 for every shot**
- **Found during:** Task 2 (`test_shot_list#test_every_shot_has_a_map_copy_with_the_shot_gold`)
- **Issue:** the three castle upgrades cost 6 + 10 + 16 = 32, so `castle_tier_four` cannot run on the shared 30 gold; the Phase 5 shots start with 60 (`ShotEconomyScenarios.SHOT_GOLD`).
- **Fix:** the test expects `SHOT_GOLD` for the economy shots and the shared value for all others (test_shot_list is in the plan's file list).
- **Files modified:** tests/unit/test_shot_list.gd
- **Committed in:** 9892382

**3. Layout and shot values differ from the plan's wording (not rule-bound)**
- Cards grew from 2.4 to 3.4 m wide, fonts and heights changed (name 32, flavour 22, numbers 24, icon slot at 1.05 m, key tile 0.5 m in the top left corner), and the plain digit Label3D of plan 05-02 was replaced by the Kenney key tile. The first real-window look overlapped the numbers line with a three-line flavour; the final look is the shot review above.
- `castle_tier_four` zooms out and stands the king at (2.3, 0, -0.9) from the plot (a first try at (1.0, 0, -2.2) put his silhouette over the label); the roof tip is still cropped at the camera's farthest zoom.
- Two RED-commit scaffolds (see the TDD record).

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking) plus layout values and scaffolds by design. **Impact on plan:** none on scope or interfaces; every listed interface and acceptance criterion holds.

## Issues Encountered

- `gdformat` rewrites some files with CRLF in the working tree (`shot_economy_scenarios.gd`, `test_shot_list.gd`); scripted edits normalised line endings first, and git normalises on commit (the warnings are harmless).
- A heredoc-fed Python edit once lost tab indentation (the environment note about heredocs); the edit was redone with a script file and with Edit calls.

## Known Stubs

None. The icon-slot stub of plan 05-02 (ledger id 9 in `.planning/WINDOWS.md`, `ChoiceDef.icon` null) is resolved by this plan and marked fixed.

## Threat Flags

None. T-05-09 is mitigated as planned: a press is consumed only when `hit_test` finds a card, the picker writes only its own highlight, and `test_card_mouse` asserts gold, tier, selection and `command_rejected` after a click. T-05-10: the icons are first-party CC0-1.0 SVGs logged in ASSETS.md, the keep scenes compose only the already-logged Kenney Castle Kit GLBs, `test_attribution_log` stays green, and nothing was downloaded. No new network, file or auth surface.

## Next Phase Readiness

- Plan 05-05 (requirement gate) touches none of these files. Later Phase 5 plans append shots to `ShotEconomyScenarios` and raise the counts in `test_shot_list` (39 now).
- For the 05-12 playtest packet: research A10 (the cards re-appear each time the king passes the castle with enough gold), the HUD "Night 1 of 8" banner overlapping the top of the raised card, and the tier IV roof tip being cropped at the default camera.
- The Phase 8 art pass may replace the icons and the keeps; nothing depends on their look.

## Self-Check: PASSED

All created files exist on disk (twelve SVGs and their `.import` files, the three keep scenes, `shot_economy_scenarios.gd`, `test_card_mouse.gd`, `test_castle_views.gd`, `test_card_icons.gd`), commits 4ae6c46, 585f29a and 9892382 exist, `static func hit_test(`, `"effect_line"` and `"key_hint"` are in card_row_model.gd, `func card_rects(` and `unproject_position` in card_row.gd, `func _input(` and `set_input_as_handled()` in card_picker.gd, `class_name ShotEconomyScenarios` with `ECONOMY_SHOTS`, and both task verify chains were run (full suite, four replays, lint, both screenshots).

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-21*
