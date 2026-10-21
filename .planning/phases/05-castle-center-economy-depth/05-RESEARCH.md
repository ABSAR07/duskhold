# Phase 5: Castle Center & Economy Depth - Research

**Researched:** 2026-10-21
**Domain:** Godot 4.7.2 GDScript deterministic simulation: a pure stat-modifier stack, a tiered castle with a branching-choice card system, four economic income curves (declining, per-tier, ramping, threshold-activated), world-space choice cards with mouse and digit input, balance bots, golden-replay discipline
**Confidence:** HIGH on every in-repo fact (each was read this session or measured by a probe run this session); MEDIUM on the proposed numbers (costs, ability values, thresholds are starting points for the bots to fit, not measurements); LOW on the CC0 asset candidates (pack contents were not enumerable from the vendor pages)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried Forward (locked before this discussion - do not re-litigate)**
- Stack, the simulation / presentation / data split, `.tres` content referenced by id, the command/intent layer, the event bus, CC0-only assets with the attribution log (`01-CONTEXT.md`).
- One building type per fixed plot (Phase 1 D-02); every tunable number lives in `.tres` data, never in code (Phase 1 D-09); the free dawn rebuild that pays nothing that morning (LOOP-04, LOOP-05, Phase 2 D-14 crossed-coin marker).
- Ride-up-and-hold building and upgrading exactly as validated through the Phase 1 to 4 sign-offs (Phase 1 D-05 as amended, D-06 refund on early release, D-07 world-space spot label, D-08 denied bump). Keyboard and mouse only; the shipped pad code stays unsupported and untouched.
- The deterministic fixed-step simulation (`SimClock` 1/30 s, seeded RNG, integer ticks, event recorder, golden replays, bot playtests) and the rule that nothing under `simulation/` reads wall-clock time, the OS, the scene tree or the time scale (Phase 2 DR-1 to DR-10). Player commands enter the simulation as intents stamped on ticks. Presentation never writes the simulation.
- The prototype map is the permanent sandbox (Phase 1 D-04); its 14 existing plots, their positions and their balance data are not moved (Phase 3 D-03, Phase 4 D-06).
- Goldens mean "same outcomes, not digests" (Phase 4 D-14): a digest move is a stop rule that needs an owner checkpoint, never a silent re-pin. This phase's one regeneration is pre-approved below (D-08).
- The Phase 2 balance bar: the balanced bot wins 7 or 8 of seeds 1 to 10; the bots measure, only the owner judges fun; night counts move only if the bar breaks (Phase 4 D-15 pattern).
- The castle as it stands: 70 health in map data, its own arrow (2 damage every 1.5 s, 22 m reach, 27 m/s arrows, Phase 2 playtest-gate decision), 1 base gold at dawn, the king spawns beside it.
- The PLAT-01 native route (Phase 4): the enemy step, separation, wall solids, the flow field, the stuck tracker and the per-frame view fills run in the C++ GDExtension behind unchanged GDScript APIs, pinned byte-identical. New systems in this phase are GDScript; they may call the native facades but must not change the native step's inputs without a re-pin.

**Castle Center tiers and abilities**
- **D-01:** **The castle has four tiers and a run makes three ability picks.** The castle starts standing at tier I. Upgrades to II, III and IV are bought by riding up to the castle and holding the action key, like any plot. Each upgrade raises the castle's health with a gentler step than Thronefall's three-rung 1:3:7 ladder, and each offers one pick of four abilities (D-02). The health ladder and the costs are data on Thronefall's rising cost line, fitted by the planner and the bots; the first upgrade must be a real early trade-off, not a free day-1 buy. - **Reversibility:** costly - the ability set (twelve cards), the gate authoring (D-03), the castle's model per tier and every balance number measured afterwards assume four rungs.
- **D-02:** **Twelve abilities, authored by Claude in Thronefall's style.** Four per upgrade tier, each a run-wide passive that touches only systems that exist by Phase 5 (king, squads, towers, walls, buildings, the castle, dawn income) and is expressed as stat modifiers through the new stacking order (D-15), numbers in data. Candidates: Royal Training (+king health and damage), Commander (+unit health and damage), Masons (+building and wall health), Prosperity (+dawn income), Assassin's Training (slower but far harder king attacks), Engineers (+tower damage and range), Rallying Banner (units return faster at night), Magic Armor (part of the damage the king takes is reflected). The four cards of one tier must be distinct lines, and a card is offered once per run. The owner judges the set and its numbers at the UAT; a pick is permanent for the run (BLDG-05).
- **D-03:** **One gate: the top tier of every building needs the castle at tier II.** Tier I and II of any building are always buyable; the last tier of each building (House III, Tower II, Barracks III, Archery Range III, Wall III, Mill III, Harbor II, and so on) requires castle tier II. The requirement is authored per tier in data (default: none) so later maps can gate differently, and `MapConfig.validate()` reports an impossible requirement. A gated tier's label reads "Needs Castle II" and holding there gives the Phase 1 D-08 denied bump with a `castle_tier` rejection reason, nothing spent. The same requirement mechanism ("this tier or plot needs another spot at tier N or more") is what Field plots use (D-10).
- **D-04:** **Each castle tier also strengthens the castle itself.** Besides health and the ability pick, tiers II to IV raise the castle's arrow (damage, and the planner may touch reach or interval) and add base dawn income (about +1 gold per tier). Numbers in data; the bots check the bar.

**Choice cards**
- **D-05:** **Approach, pick, then hold to pay.** Riding up to the castle while an upgrade with a pending pick is affordable shows the four cards. The player highlights one with the number keys 1 to 4 or by pointing the mouse at it (hover highlights; a click highlights too and never buys), then holds the action key as usual; the hold only starts with a highlighted card. Nothing is spent until the last coin lands; releasing early or leaving range cancels for free, exactly as today's builds (Phase 1 D-06); the pick locks when the hold completes. The upgrade and its choice reach the simulation as one intent stamped on a tick (a `BuildIntent` carrying the choice id, or a sibling intent the planner names), so a recorded run replays identically and the bots can pick. While the cards are shown and the king stands in range by day, the digit keys mean "pick a card", not "recall a control group", the same modal rule Phase 3 applied to movement keys while a squad is selected.
- **D-06:** **A row of four cards above the castle in world space.** The cards hover over the plot the way the spot label does (Phase 1 D-07), the highlighted card raised and brighter; day only, in range only; the HUD centre stays clear (Phase 3 D-21). Nothing about the cards lives in the HUD.
- **D-07:** **Each card shows an icon, a name and a flavour line; the exact numbers appear when the card is highlighted** (an expanded line on the card, keyboard or mouse). The numbers are read from the same data the modifier stack applies, so what the card says can never drift from what the game does. Icons are CC0 and logged in `ASSETS.md`.

**New plots on the prototype map and the goldens**
- **D-08:** **The new plots join the prototype map and the goldens are regenerated once.** `smoke`, `army`, `full_idle` and `walls` are regenerated in one deliberate commit with a before/after outcome report beside it, the Phase 4 D-14 way: same outcomes expected per seed (win or loss, nights survived, kills within a stated band), because no existing plot moves and the bots merely see more plots. The owner approved this regeneration on 2026-10-21; no further checkpoint is needed for it, but any later digest move in the phase is still a stop rule. - **Reversibility:** costly - every balance number measured afterwards assumes the 22-plot map, and a second sandbox map was considered and rejected.
- **D-09:** **Eight new plots: 1 Gold Mine, 1 Mill with 3 Fields, 1 Fishing Harbor, 2 Shrines.** The map goes from 14 to 22 plots; the existing 14 stay where they are. Two Shrines so that their mutual buff can be seen. Positions are the planner's, within these rules: no plot on a road, inside a wall run's line or in an authored gap; Fields within a few metres of their Mill; Shrines where enemies pass so that they can wake; nothing that changes the routes or the flow field.
- **D-10:** **Field plots exist from the start but are locked until the nearby Mill stands.** They read "Needs a Mill" and the hold is refused with the denied bump until the Mill is at tier I or more. The lock is the D-03 requirement mechanism (the Field's tier I requires the Mill's spot at tier 1 or more). A built Field does not depend on the Mill afterwards: a destroyed Mill is rebuilt free at dawn like anything else and the Fields keep paying.
- **D-11:** **A visual-only pond at one map edge, with the Harbor on its shore.** The pond sits off the three roads; nothing walks on it and nothing is blocked by it, so the flow field, the wall routes, the enemy paths and the gate stress are untouched. Boats on the pond are presentation only.

**Income curves and destroyed-building rules**
- **D-12:** **Thronefall's curve shapes, fitted to our scale by the planner and the bots.** Each curve keeps its shape; the numbers live in data and are fitted to our economy (House pays 1/2/3 for 2/3/5 gold, 4 starting gold, 1 base income) so that the balanced bot stays at 7 or 8 wins of 10:
  - Gold Mine: one tier; pays a high amount at its first dawn and 1 less at each later dawn it pays, down to a floor of 1 gold, never 0 (Thronefall: 5 gold, 6 then -1 per night).
  - Mill: three tiers paying per tier (Thronefall: 3/4/6 gold, paying 1/2/6); it unlocks its Fields (D-10).
  - Field: one tier, flat 1 gold at dawn (Thronefall: 1 gold).
  - Fishing Harbor: two tiers; gains one boat at every dawn it survives, up to the tier's cap; every boat pays the tier's per-boat gold (Thronefall: 3 then 7 gold, cap 5 then 10, boat 1 then 2 gold).
  - Shrine: one tier; dormant until the total max health of enemies that die within its radius reaches a threshold (Thronefall: 3 gold, about 350 health, pays 2); once awake it stays awake for the run, shoots enemies in reach like a tower (a bolt on the pending-hit queue), pays its dawn income, and every other awake Shrine gets +20% attack damage, a percent-additive modifier through the stack (D-15).
- **D-13:** **The Mill pays for itself; Fields pay their flat gold regardless of the Mill's tier.** A Mill upgrade raises only the Mill's own payout and unlocks nothing new.
- **D-14:** **A destroyed economic building loses nothing it accumulated; it only skips that dawn.** As with Houses, a building rebuilt this dawn pays nothing that morning and makes no progress: the Harbor gains no boat, the Mine's decline does not advance, the Shrine keeps its kill count and stays awake (and shoots again once it stands). The Phase 2 crossed-coin marker applies to every rebuilt building.

**Stat-modifier order (META-08)**
- **D-15:** **One stacking order for every modifiable stat, built first and tested in isolation.** `final = (base + sum of flat bonuses) x (1 + sum of percent bonuses) x product of multipliers`, the research pattern (`ARCHITECTURE.md` Pattern 3, `PITFALLS.md` Pitfall 6); the order of pickup never matters, only the bucket. Castle abilities (D-02) and the Shrine buff (D-12) are its first users; building upgrades keep their per-tier values as the base the stack applies to. The stack is a pure, headless-testable module with single-modifier and combined-modifier tests, the order is written down in the repository (the planner names the document), integer stats use one documented rounding rule pinned by tests, and the debug overlay shows the computed values. The owner left the design of the stack to Claude; what is locked is that every bonus in this phase and in later phases goes through it.

### Claude's Discretion
- The exact twelve abilities, their numbers and which four sit at which tier (within D-02), and how a locked pick is shown afterwards (for example the castle's label reading "Castle II - Royal Training" and the chosen cards listed on the castle's label).
- The castle's health, cost, arrow and base-income ladder across the four tiers (D-01, D-04), its model or look per tier (Kenney Castle Kit pieces first, logged), and whether the castle's current tier is readable on the map.
- Card size, icon art, the highlight look, whether the first card is pre-highlighted, how a hold with no highlighted card is refused, and how the digit keys hand over between cards and control groups (D-05).
- Plot positions, which edge holds the pond, the pond and boat visuals, and the CC0 models for the five new building types, within D-09 and D-11.
- Economy numbers within D-12; the Shrine's wake radius, threshold, reach, damage and bolt look; how the kill count is tracked (the `enemy_died` event carries the position and the def id, whose max health is the credit).
- The modifier stack's design (D-15): the bucket API, the rounding rule, where the order is documented, what the overlay shows.
- How the bots buy the castle tiers and the new buildings (and which cards they pick, deterministically), how the goldens are regenerated and reported (D-08), and the order of plans. Suggested shape: the stat stack first (pure, tested, documented), then the castle tiers with the gate and the cards on the castle, then the four economic buildings with their plots and the pond, the golden regeneration with its report, then the bot build orders, the balance measurement and the gate.

### Deferred Ideas (OUT OF SCOPE)
- Tower specializations (BLDG-11, Phase 6) and the per-building unit and hero choices (UNIT-01 to UNIT-03, Phase 7) - later users of the card system; this phase keeps the card data and the intent generic (any building tier may carry a choice list), with the castle as the only user.
- Perks and mutators (Phase 10) and research buffs (Phase 12) - later users of the modifier stack; this phase ships the stack with the castle abilities and the Shrine buff as its users.
- Rule-changing abilities (reflect damage as a rule, a free House upgrade at dawn, a second castle arrow) - offered as an option and not chosen; the twelve abilities are stat passives. Magic Armor stays in the candidate list only as far as it can be expressed through the stack and the existing king hit handling.
- Destruction that costs accumulated progress (boats lost, Shrines going dormant) - rejected for this phase; could return as a map gimmick or a mutator.
- A second sandbox map for new buildings - rejected; the prototype map stays the one sandbox.
- A lake that blocks movement - rejected for this phase; water as an obstacle could be a later map's gimmick (Phase 11).
- A UI design contract (`/gsd-ui-phase 5`) for the card look - optional; the plan-phase UI gate does not block, the owner may run it before planning.

**Not in this phase (CONTEXT `<domain>`):** tower specializations and the wider enemy roster (Phase 6); unit choices and the Hero's Quarter (Phase 7); perks, mutators and the loadout screen (Phase 10), research buildings (Phase 12); the art cohesion pass and SFX (Phase 8; the new buildings use CC0 placeholders logged in `ASSETS.md`); scoring, retry, saves (Phase 9); menus and settings (Phase 13); any gamepad work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BLDG-05 | When an upgrade tier offers branching options, the player picks one of the offered choice cards (keyboard or mouse); permanent for the run | `BuildingTierDef.choices: Array[ChoiceDef]` (generic), `BuildIntent.choice_id`, new rejection reasons `choice_required` / `bad_choice`, `choice_picked` event, `CardRowModel` + `CardRow` + `CardPicker` (Patterns 3, 4, 8) |
| BLDG-08 | Castle upgrades through its tiers for more health, one of four run-wide abilities per tier | Castle plot (`castle_center`) bought through `BuildingSystem`/`CommandProcessor`; `CastleState` applies the tier's health/arrow/income through the stat stack; twelve `ChoiceDef` resources (Patterns 1, 2, 3) |
| BLDG-09 | The castle tier gates higher building tiers | `BuildingTierDef.requires_castle_tier` + `castle_tier` rejection checked in `validate_build`; label status "Needs Castle II" (Pattern 3) |
| ECON-03 | Gold Mine: high income declining by a fixed amount each night | `IncomeState` dawn counter per Mine, floor 1, no progress on destroyed/rebuilt dawns (Pattern 5) |
| ECON-04 | Mill pays per tier and unlocks nearby Field spots, each paying flat income | Per-tier `dawn_income` already supported; `BuildSpotDef.requires_spot` for Fields (Patterns 3, 5) |
| ECON-05 | Fishing Harbor gains a boat each night up to a cap (raised by upgrade), each boat pays | `IncomeState` boat counter, tier cap and per-boat gold in tier data; `harbor_boats_changed` event for the boat views (Pattern 5) |
| ECON-06 | Shrine activates after enough nearby enemy deaths, then attacks, pays, and strengthens other active Shrines | `IncomeState` listens to `enemy_died`, awake flag, `TowerSystem` gate, `shrine.damage` stat with a +20% per other awake shrine percent source (Patterns 5, 6) |
| META-08 | Stat bonuses combine in a fixed, documented order verified by automated tests | `StatStack` pure module, one integer rounding rule, `docs/STAT_MODIFIERS.md`, single and combined test scripts (Pattern 1) |
| UI-02 | Upgrade choice cards show an icon, name and short description per option | World-space `CardRow` with generated numbers line from the same modifier data (Pattern 8) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Directives from `.claude/CLAUDE.md` (read this session) that bind every plan of this phase:
- **Stack:** Godot 4.7.2-stable standard build, GDScript with static typing everywhere, GUT 9.7.1, gdtoolkit (`gdformat`, `gdlint`), text-based `.tscn`/`.tres`, headless CLI as the verification path.
- **Assets:** CC0 (or equally permissive) only; attribution log maintained (`ASSETS.md` + `assets/attribution.json`); no Thronefall names or assets.
- **Platform and input:** Windows PC, keyboard and mouse only; the shipped pad code stays unsupported; no pad parity, prompts or tests (owner decision 2026-10-16).
- **Performance:** modest hardware (GTX 970 / 4 GB RAM class), 60 fps with hundreds of units; do not spawn per-entity nodes for crowds (the cards are four nodes, not a crowd).
- **Zero cost:** no paid tools, no code-signing.
- **gdlint caps (`.gdlintrc`):** `max-public-methods: 20`, `max-file-lines: 1000`, `max-line-length: 100`, `function-arguments-number: 10`, `max-returns: 6`; 20 tests per script (project convention). [VERIFIED: .gdlintrc:34,40,42]
- **Repo hygiene:** `.gitattributes` forces LF on `.gd/.tscn/.tres/.cfg`; binaries (`*.glb` and others) route through Git LFS; commit the `.gd.uid` files Godot writes for every new script.
- **Determinism law (Phase 2 DR-1 to DR-12):** nothing under `simulation/` reads wall-clock time, the OS, the scene tree, `Input`, the camera or the viewport; integer ticks; seeded RNG only; ids only grow; iteration in id or MapConfig order; only `+ - * /` and `sqrt` in the math directories. `tests/unit/test_sim_rules_guard.gd` enforces this by source scan; its `MATH_ROOTS` lists `clock`, `night`, `king`, `castle`, `squads`, `walls`, `nav` - the new directories (`simulation/stats`, `simulation/economy`) must be added to that list in the same task. [VERIFIED: tests/unit/test_sim_rules_guard.gd:9-18]
- **GSD enforcement:** file-changing work starts through a GSD command (`/gsd-execute-phase` for this phase's plans).

## Summary

Phase 5 is mostly composition, not invention: almost every mechanism it needs already exists in the repository and only has to be generalised. `BuildingTierDef` already carries `cost`, `dawn_income`, `attack_range`, `attack_damage`, `max_health`, `attack_interval` and `projectile_speed`, which is exactly what a castle tier needs; the Mill and Field already fit the existing flat `dawn_income` path; `TowerSystem` already steps every standing attacking building in spot order, which is already the Shrine's attack slot; `WallSystem` already shows how a sibling system listens to `building_built`; `DawnNoIncomeMarker` and `DawnPayoutVfx` already handle any spot id. The genuinely new pieces are four: the pure `StatStack`, the requirement/choice fields and rejection reasons on the build gate, one economy-state sibling (Mine decline, Harbor boats, Shrine kills), and the world-space card row with its mouse/digit input. The research below pins each of them to concrete files, line numbers and measured facts.

Eight findings change how the plans should be written (details under "Premise Corrections"): (1) the replay goldens `smoke`, `army` and `walls` run on frozen fixture maps and `full_idle` is not pinned anywhere, so adding eight plots to `data/maps/prototype_map.tres` cannot move any of the three checked-in digests and there is no `full_idle` digest pin in CI to replace - D-08's "regeneration" is expected to be a verified no-op for the three plus a before/after outcome report for `full_idle`, and the golden coverage of the new events should come from one new fixture-based `economy` scenario, the way Phase 4 added `walls`; (2) the castle gate (D-03) changes the shipped bots' behaviour by construction (the balanced order buys Tower II at its seventh entry), so "the bots merely see more plots" is not what will happen and the balance work is a real measurement task; (3) `NavGrid` sizes its grid from every plot position, so a new plot north of z = 40 or beyond the wall ends changes the flow-field cell layout; (4) a Shrine tier with `attack_damage` above 0 is picked up by `TowerSystem` as a tower and would shoot while dormant unless gated; (5) the castle plot's id cannot be `castle`; (6) the spot list becomes 23 entries (22 plots plus the castle plot); (7) presentation reads `def.max_health` directly for unit health bars, which would drift from the simulation when a unit-health ability applies; (8) `RunManager` (9 parameters), `NightSim` (8) and `CommandProcessor` (7) are at or near the 10-argument lint cap, and `BuildingSystem`, `UnitSystem` and `KingState` are at the 20-public-method cap.

**Primary recommendation:** Build in this order: (1) `simulation/stats/` (`StatStack`, `StatModifierDef`, `StatIds`) with `docs/STAT_MODIFIERS.md` and the single/combined test scripts; (2) wire every consumer through the stack with identity modifiers and prove `smoke`/`army`/`walls` and `full_idle` byte-identical (full_idle baseline recorded below); (3) requirement/choice fields, `BuildIntent.choice_id`, the castle plot and `CastleState` tiers, `validate_build` reasons; (4) the card row and input; (5) `IncomeState` and the four economic buildings; (6) the eight plots, pond and models; (7) bots, measurement, the new `economy` golden and the `full_idle` before/after report; (8) shots, assets log, gate. Use only Godot built-ins; there are no packages to install.

## Premise Corrections (read before planning)

| # | What the context says | What the repository shows | Consequence for the plans |
|---|----------------------|---------------------------|---------------------------|
| P1 | D-08 and `<code_context>`: "`smoke`, `army`, `full_idle` and `walls` are regenerated"; "the regenerated goldens replace the pinned `full_idle` digest in the replay step" | `tools/replay/replay_scenarios.gd` loads `smoke`, `army` and `walls` from frozen fixtures (`tests/fixtures/fixture_map_replay_*.tres`), and `full_idle` has no golden file. CI runs `bash tools/replay.sh --scenario=full_idle --twice` with no `--expect-file` (`.github/workflows/ci.yml:160` and `:218`). `tests/golden/` holds `smoke.json`, `army.json`, `walls.json` only. [VERIFIED: tools/replay/replay_scenarios.gd:27 `const NAMES: Array[StringName] = [&"smoke", &"full_idle", &"army", &"walls"]`; ci.yml:160 `bash tools/replay.sh --scenario=full_idle --twice`] | Adding plots to the prototype map cannot move the three goldens. They move only if simulation rules change. Plan: keep the three byte-identical through every change (that is the regression guard, the D-13 pattern); if one moves it is a stop rule exactly as D-08 says. The "regeneration" deliverable becomes (a) a recorded `full_idle` before/after (baseline below) and (b) one new fixture-based `economy` golden covering the new events. No CI line carries a `full_idle` digest to replace. |
| P2 | D-08: "same outcomes expected per seed ... because no existing plot moves and the bots merely see more plots" | D-03 gates the top tier of every building behind castle tier II. The shipped balanced order contains `tower_1` twice (Tower II is the last tier of a two-tier building) at its fourth and seventh entries and House/Tower/Barracks/Archery upgrades later. [VERIFIED: tools/replay/playtest_strategies.gd `_BALANCED` list; data/buildings/tower.tres has two tiers] | With the gate in data the existing orders cannot buy Tower II until castle II stands. The `full_idle` outcome will move for a reason other than extra plots. The balance work (Pattern 9) must treat the castle purchase and the gate as the main change, keep the Phase 4 order as a "no castle" twin for comparison, and expect a retune of costs or bot order. |
| P3 | D-11 / D-09: "nothing that changes ... the flow field" | `NavGrid._content_bounds` includes every `map.spots` position and every wall run point; the grid layout is derived from it. Measured: shipped map grid origin `(-82.0, -82.0)`, width 82, height 67; an extra plot at z = 36 leaves it unchanged, at z = 50 height becomes 72. [VERIFIED: probe this session; simulation/nav/nav_grid.gd:311-358] | Keep every new plot inside the current content box (|x| <= 66.3, -66 <= z <= 38.79) and pin the grid's `origin()`, `width()`, `height()` in a test. The pond is not a plot and does not enter the bounds. |
| P4 | D-12: "shoots enemies in reach like a tower" | `TowerSystem.step` loops `standing_spot_ids()` and shoots whenever the current tier has `attack_damage > 0`. [VERIFIED: simulation/night/tower_system.gd:28-31] | A Shrine tier with attack numbers would fire from tick 0 of the first night. The Shrine must be gated on its awake flag inside that loop. No separate "Shrine slot" is needed in `NightSim`; the existing towers slot (spot order, between squads and the castle arrow) is the slot. |
| P5 | Castle as a plot | `MapConfig.CASTLE_PAYOUT_KEY` is `&"castle"` and `validate()` rejects any spot with that id. [VERIFIED: simulation/defs/map_config.gd:22 and the `spot.id == CASTLE_PAYOUT_KEY` check] | The castle plot needs another id (for example `castle_plot`). |
| P6 | "22 plots" | The castle plot is one more `BuildSpotDef` (a plot the king holds at). | `map.spots.size()` becomes 23 if the castle plot lives in `spots`; "22" counts the buildable plots other than the castle. Tests that pin 14 (`test_military_data_contract` `SPOT_COUNT`, `test_prototype_map_walls` "fourteen plots") must change; `test_prototype_map_data.gd` is at the 20-test cap, so new assertions go in a new script. |
| P7 | "Read their modifiable stats through the stack instead of raw def values" | `presentation/units/unit_views.gd` calls `_native.set_max_hp(unit_id, def.max_health ...)` at lines 95 and 174 and `king_widget`/`building_views` read the simulation's own getters. [VERIFIED: grep this session] | Unit health bars would show the old maximum after Commander. `UnitSystem` is at the public-method cap, so presentation must read the same stack (`stats.int_value(&"unit.max_health", def.max_health)`) rather than a new `UnitSystem` method. |
| P8 | Constructor wiring | `RunManager._init` has 9 parameters, `NightSim._init` 8, `CommandProcessor._init` 7; the lint cap is 10. `BuildingSystem` has 20 public methods, `KingState` 20, `UnitSystem` 20 (counted with `grep -c "^func [a-z]"`; `.gdlintrc` caps at 20). [VERIFIED: files read this session] | Add collaborators as optional trailing parameters only where room remains; fold `base_dawn_income` into `CastleState` to free a `RunManager` slot; add no public method to the three full classes (use private helpers, signals on `StatStack`, or sibling classes). |

## Architectural Responsibility Map

This is a single-process offline game, so the tiers are the project's own layers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stat buckets, rounding, stat registry | Simulation (`simulation/stats/`) | Data (`.tres` modifiers) | Pure, headless, feeds the digest; DR-7 math only |
| Castle tier, castle numbers, ability picks | Simulation (`BuildingSystem` tier + `CastleState` numbers + `StatStack` sources) | Data (`castle_center.tres`, `data/abilities/*.tres`) | Outcomes of a run must replay identically |
| Requirement checks (castle tier, Mill) and choice validation | Simulation (`CommandProcessor.validate_build`) | Data (tier/spot fields) | The single validated mutation gate |
| Dawn income of Mine, Harbor, Shrine | Simulation (`IncomeState`, called from `RunManager._apply_dawn_payout`) | Data | One `dawn_payout` event, MapConfig order |
| Shrine wake credit | Simulation (`IncomeState` reads `enemy_died`) | - | Kill positions and ids are simulation facts |
| Shrine attack | Simulation (`TowerSystem`, gated) | - | Existing towers slot, bolt on `PendingHits` |
| Card row visuals, highlight, hover | Presentation (`ui/world/`) | Input (`input/`) | Display and pointer only; writes nothing but one intent on hold completion |
| Card highlight state, digit hand-over | Input/presentation (`CardPicker`) | - | Ephemeral UI state, like hold state |
| Castle per-tier look, new building models, pond, boats | Presentation | Data (view catalog) | Display only; boats follow `harbor_boats_changed` |
| Debug overlay "Stats" section | UI overlay | Simulation (read-only getters) | Existing read-only section pattern |
| Bots, strategies, balance report, `economy` golden scenario | Tools (`tools/replay/`) | Simulation | Export-excluded measurement |
| Plot positions, pond circle, requirement graph validation | Data (`prototype_map.tres`) + `MapConfig.validate()` | Tests | Bad data is reported, never armed |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.7.2-stable (pinned; `Godot Engine v4.7.2.stable.official.ed1daf0bf`) | Everything | Locked by CLAUDE.md. [VERIFIED: probe banner this session] |
| GDScript | 4.7 built-in | All code | Locked by CLAUDE.md |
| GUT | 9.7.1 | Unit/integration/e2e tests via `bash tools/test.sh` | Locked by CLAUDE.md; `.gutconfig.json` dirs `tests/unit`, `tests/integration`, `tests/e2e`, prefix `test_` [VERIFIED: .gutconfig.json] |
| gdtoolkit | 4.5.0 (`.tools/venv/Scripts/gdlint.exe` present) | `bash tools/lint.sh` | Locked by CLAUDE.md |

### Supporting (all Godot built-ins, no install)
| Facility | Purpose | When to Use |
|----------|---------|-------------|
| `Resource` + `@export` typed arrays | `StatModifierDef`, `ChoiceDef`, income fields | Data authoring in `.tres` |
| `Label3D`, `Sprite3D`, `MeshInstance3D` + `QuadMesh`/`StandardMaterial3D` | World-space cards, boats, pond, placeholder models | Same technique as `ui/world/spot_label.gd` |
| `Camera3D.unproject_position` | Screen rectangles of world-space cards for mouse picking | Hover/click hit tests without colliders |
| `Tween` | Card raise/highlight, pond ripple | Presentation only |
| `PackedScene` composition of Kenney GLBs already in the repo | Placeholder models | Pattern used by `house_t1.tscn`, `castle_center.tscn` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Label3D/Sprite3D cards (D-06 as written) | Controls that follow a projected world point (the `DawnNoIncomeMarker` pattern) | Easier text wrapping and free hover/click, but D-06 says "Nothing about the cards lives in the HUD"; only switch with the owner's agreement |
| Castle plot inside `BuildingSystem` (recommended, tier only) | A separate `CastleTiers` system with its own intent | A separate system avoids touching `BuildingSystem` but duplicates focus, hold, label, cost, `building_built` and view plumbing and cannot reuse `BuildIntent` for the choice id |
| One `StatStack` with global stat ids (recommended) | Per-instance stat objects | Per-instance is needed only when Phase 6 specialises single towers; global ids are enough here and a scope suffix can be added later |

**Installation:** none. **Package versions:** no external packages are introduced.

## Package Legitimacy Audit

No external packages (npm, PyPI, crates) are installed by this phase, so the `package-legitimacy` gate has nothing to check. The only external content candidates are CC0 art packs (below); they are not packages and each needs the existing attribution-log discipline.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | - | - | - | - | - | - |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

Art candidates (all `[ASSUMED]`, none downloaded): Kenney Castle Kit and Fantasy Town Kit are already in the repo as seven GLBs each (only extracted pieces; the archives are not kept) [VERIFIED: assets/attribution.json entries `kenney-castle-kit`, `kenney-fantasy-town-kit` notes]. Kenney Game Icons (CC0, 2014, 105 files) [CITED: kenney.nl/assets/game-icons] is an interface/gamepad pack and the vendor page does not list sword/heart/coin icons; Kenney Pirate Kit (CC0, 70 files, v2.1 adds fortress walls) [CITED: kenney.nl/assets/pirate-kit] likely holds boats but its page does not list them. Any new download follows the Phase 1 procedure (`curl --fail`, size and SHA256 recorded, owner-approved size) and gets a `checkpoint:human-verify` task.

## Empirical Findings (probes and reads run this session)

All probes used `bash tools/godot.sh --headless --path . -s <scratch script>` against the pinned binary; scripts live in the session scratchpad; no tracked file was touched. [VERIFIED: probe]

- **E1 - integer stat math.** A single-rounding integer formula `round_half_up((base + flat) * (100 + pct) * m1 * m2 ... / (100 * 100^k))` returned: base 10, flat +2, pct +50 -> 18; base 10, pct +20 and +30 summed (+50) -> 15; base 3, +50% -> 5 (4.5 rounds up); base 6, +25% -> 8 (7.5 rounds up); base 10, flat +2, pct +50, one multiplier 200 -> 36; identity (no modifiers) base 70 -> 70, base 2 with two identity multipliers 100 -> 2; base 1 with multiplier 40 -> 0 (so a clamp to 1 for positive bases is needed). The 18 matches `ARCHITECTURE.md` Pattern 3's own example (`compute_stat(base=10, modifiers=[flat(+2), percent(+50%)]) == 18`).
- **E2 - nav grid.** Shipped map: 14 spots, `validate()` empty, `NavGrid` origin `(-82.0, -82.0)`, 82 x 67 cells of 2.0 m. Adding a plot at (0, 36) -> unchanged; at (0, 50) -> height 72.
- **E3 - full_idle baseline (record this before touching anything).** `bash tools/replay.sh --scenario=full_idle --twice` -> `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`, 16 s wall. The checked-in goldens are `smoke` 2599c7c2..., `army` f7a967ed..., `walls` bfb05fc7... [VERIFIED: tests/golden/*.json].
- **E4 - where enemies die (balanced bot, seed 1, 194 kills; killer split building 125, king 62, castle 7).** Total enemy max health credited by 10 m cell: (-60, 20) 386 hp, (0, -60) 210, (60, 20) 208 plus (50, 20) 70, then 56/34/34 near (-10..10, 10) and (40, 10..20). Cumulative hp credited per night inside a radius of 18 m around a candidate Shrine at (-46, 30): [30, 36, 102, 168, 222, 282, 306, 348] after nights 1..8; at (46, 30): [0, 0, 60, 114, 156, 202, 262, 328]. Enemy max health: grunt 6, skirmisher 4. So a Shrine threshold near 100 wakes such a Shrine around night 3, near 200 around night 5.
- **E5 - candidate plot geometry (checked numerically).** Castle plot (0, 5); Gold Mine (-30, 30); Mill (30, 28) with Fields (25.5, 30.5), (30, 33), (34.5, 30.5); Harbor (0, 20.5) on the north shore of a pond centred near (0, 30) of radius about 8; Shrines (-46, 30) and (46, 30). Distances: every non-shrine, non-castle plot at least 16.1 m from every spawn-to-castle road segment (grunt aggro 6 m, skirmisher 9 m); Shrines 12.5 m from the road and 10.5 m from the nearest wall run; Fields 5.0-5.1 m from the Mill; every plot inside the nav content box; nearest other plot at least 5.0 m. These are a starting layout the planner may move; the rules to test are in the Validation section.
- **E6 - cap arithmetic.** `BuildingSystem` 20 public methods, `KingState` 20, `UnitSystem` 20, `SquadSystem` 19, `WallSystem` 16, `EnemySystem` 17, `CastleState` 7, `TowerSystem` 2, `Economy` 4. Files: `map_config.gd` 545 lines, `command_processor.gd` 213, `squad_system.gd` 658 (cap 1000).

## Architecture Patterns

### System Architecture Diagram

```
 INPUT (day only)
   king rides to castle plot ---> BuildHoldController._update_focus (nearest_spot_in_range)
        |                                   |
        |            CardPicker (digits 1-4 via group_1..group_4, mouse hover/click)
        |               highlight state -> choice_id        CommandKeyController skips digits 1-4
        |                                   |               while cards show
        v                                   v
   hold completes --> BuildIntent(spot_id, choice_id) --> CommandProcessor.submit
                                                     |
                  validate_build(spot_id, choice_id):  NOT_DAY, UNKNOWN_SPOT, MAX_TIER,
                  CASTLE_TIER, NEEDS_SPOT, CHOICE_REQUIRED, BAD_CHOICE, CANNOT_AFFORD
                                                     |
                      try_spend --> BuildingSystem.apply_next_tier --> building_built
                                                     |
              +--------------------------------------+------------------------------+
              v                                      v                              v
     castle plot? CastleState.set_tier       choice_id? StatStack.add_source   events: choice_picked
     (health, arrow, income via stack)        (ChoiceDef.modifiers)             (recorded in digest)
              |                                      |
              +--------------- StatStack.changed ----+--> KingState, UnitSystem, BuildingSystem,
                                                         WallSystem, TowerSystem, CastleAttack,
                                                         RunManager payout re-read their stats

 DAWN (RunManager._enter_dawn)
   rebuild_destroyed -> repair -> walls restore -> king/squads restore
        -> _apply_dawn_payout:
             flat house/mill/field income  <- BuildingSystem.dawn_income_by_spot()
             mine / harbor / shrine income <- IncomeState.dawn_payouts()  (advances state, skips
                                              destroyed and rebuilt-this-dawn spots, D-14)
             castle base income            <- CastleState.base_income() (tier + stack), key "castle"
        -> ONE dawn_payout(total, per_spot) event, MapConfig order, castle last

 NIGHT (NightSim.step, fixed order, unchanged)
   spawn, pathing.refresh, king, squads, towers (+ awake shrines, same loop), castle arrow,
   enemies, stuck tracker, resolve hits, remove_dead --> enemy_died --> IncomeState credits
   shrines whose radius contains the death (enemy max_health from MapConfig.find_enemy)
```

### Recommended Project Structure
```
simulation/
├── stats/
│   ├── stat_stack.gd            # pure buckets, rounding, sources, changed signal
│   ├── stat_modifier_def.gd     # Resource: stat id, bucket, value
│   └── stat_ids.gd              # the registry of legal stat ids + kind (int/float) + labels
├── economy/
│   ├── economy.gd               # existing ledger
│   └── income_state.gd          # mine counter, harbor boats, shrine kills/awake, dawn payouts
├── defs/
│   ├── choice_def.gd            # Resource: id, name, flavour, icon, modifiers
│   ├── build_requirement_validation.gd  # MapConfig.validate() helper (like wall_validation.gd)
│   └── economy_validation.gd    # MapConfig.validate() helper for the new fields
data/
├── abilities/                   # twelve ChoiceDef .tres
└── buildings/                   # castle_center, gold_mine, mill, field, fishing_harbor, shrine
docs/
└── STAT_MODIFIERS.md            # the documented order (new folder)
ui/world/
├── card_row.gd (+ .tscn)        # Node3D view of the four cards
├── card_row_model.gd            # pure: card content, highlight, hit test on supplied rects
input/
└── card_picker.gd               # highlight state, digits, mouse; consumes clicks on cards
presentation/
├── environment/pond_view.gd     # visual-only pond from MapConfig pond fields
└── buildings/models/            # new model scenes
tests/unit|integration|e2e/      # see Validation Architecture
tools/replay/                    # bot strategy changes, economy scenario, report columns
```

### Pattern 1: StatStack (META-08, D-15)
**What:** One pure `RefCounted` holding, per stat id, three buckets contributed by named sources. Formula (D-15): `final = (base + sum(flat)) * (1 + sum(percent)) * product(multipliers)`.
**Design (recommended):**
- Values are integers in the `.tres`: `FLAT` in stat units; `PERCENT` in whole percent (+20 means +20%); `MULTIPLIER` in percent of identity (100 = x1.0, 150 = x1.5, 75 = x0.75).
- Integer stats: compute the exact rational once and round once: `numerator = max(base + flat, 0) * (100 + pct) * m1 * m2 ...`, `denominator = 100 * 100^k`, `result = (numerator * 2 + denominator) / (2 * denominator)` (round half up), then clamp: never below 1 when `base >= 1`, never below 0 otherwise. One rounding at the end makes the result independent of pickup order and of bucket-internal order (E1 vectors).
- Float stats (ranges, intervals, seconds): if the stat has no modifier return `base` untouched (bit-identical, so identity cannot move a golden); otherwise `(base + flat) * (1.0 + pct / 100.0) * prod(m / 100.0)` using only `+ - * /` (DR-7).
- Sources: `add_source(source_id, mods)` replaces any earlier list for that id (so the Shrine's synergy can be re-set as the awake count changes), `remove_source(source_id)`, and a `changed` signal for consumers.
- Registry: `StatIds` lists every legal stat id with its kind and a player-facing label; `MapConfig.validate()` reports an unknown stat id in any modifier (typo guard), a bucket value outside range, and a source with too many modifiers.
- Overflow guard (security): with int64 the product stays safe if `base + flat <= 100000`, `sum(percent)` in `[-90, 1000]`, each multiplier in `[10, 400]` and at most 4 multipliers per stat: `1e5 * 1100 * 400^4 = 2.8e18 < 9.2e18`. `validate()` and `add_source` enforce these.
**Where documented:** `docs/STAT_MODIFIERS.md` (new), the same formula in the `StatStack` class header, and a contract test that reads the doc file and asserts the formula line and the rounding sentence are present (cheap drift guard). Per-tier building values stay in `BuildingTierDef` and are the `base` argument.
**Stat registry proposal (consumer map in Pattern 2):** `king.max_health`, `king.attack_damage`, `king.slam_damage`, `king.attack_interval` (float), `king.damage_taken`, `unit.max_health`, `unit.attack_damage`, `squad.respawn_seconds` (float), `building.max_health`, `wall.max_health`, `tower.damage`, `tower.range` (float), `shrine.damage`, `castle.arrow_damage`, `castle.arrow_range` (float), `castle.base_income`.

### Pattern 2: Consumer touchpoints (identity first)
Read each stat through the stack at the point the simulation already reads the def value. With no modifiers every call returns the base, so all goldens must stay byte-identical (this is the first gate).

| Stat | Today reads (file, verified) | Change |
|------|------------------------------|--------|
| `king.max_health` | `KingState.get_max_health()` `maxi(_def.max_health, 1)` (king_state.gd:144-145); also `_health = maxi(def.max_health, 1)` in `_init` | read via stack; on `changed` raise current health by the delta (a pick happens by day, so the king is at full health) |
| `king.attack_damage` / `king.attack_interval` | `_passive_attack`: `_weapon.attack_damage`, `SimClock.ticks(_weapon.attack_interval)` (king_state.gd:256-263) | wrap both reads |
| `king.slam_damage` | `resolve_ability`: `_weapon.slam_damage` | wrap |
| `king.damage_taken` | `KingState.take_damage(amount)` | `amount = stats.int_value(&"king.damage_taken", amount)` before the health math; floor of 1 for positive hits |
| `unit.max_health` | `UnitSystem.spawn` `maxi(def.max_health, 1)` (unit_system.gd:36) and `heal_to_full` (unit_system.gd:156); presentation `unit_views.gd:95,174` | wrap in the three places; units alive at pick time keep their old health until the dawn restore |
| `unit.attack_damage` | `SquadSystem` hit enqueue `def.attack_damage` (squad_system.gd ~584) | wrap |
| `squad.respawn_seconds` | `squad.respawn_seconds = tier_def.squad_respawn_seconds` (squad_system.gd:319) | wrap (float) |
| `building.max_health` | `BuildingSystem._max_health_of` (building_system.gd:241-248) | wrap for non-wall, non-castle spots; on `changed` call the existing `repair_standing()` so bars match |
| `wall.max_health` | `WallSystem.on_building_built` sets `_max_health[segment] = tier_def.max_health` (wall_system.gd:61) | wrap there, and re-apply on `changed` (one new method on `WallSystem`, which has 16 public) |
| `tower.damage` / `tower.range` | `TowerSystem.step` `tier.attack_damage`, `tier.attack_range` (tower_system.gd:36,49) | wrap; Shrine uses `shrine.damage` through a per-building `attack_stat` field |
| `castle.arrow_damage` / `castle.arrow_range` | `CastleAttack` reads `_map.castle_attack_*` (castle_attack.gd:42-78) | read from `CastleState`'s current numbers through the stack |
| `castle.base_income` | `RunManager._base_dawn_income` (run_manager.gd:24,207-209) | read from `CastleState.base_income()` |

### Pattern 3: Requirements, choices and the build gate
**Data (all default to "none", so every existing `.tres` and fixture loads unchanged):**
- `BuildingTierDef.requires_castle_tier: int = 0` (D-03, per tier). `BuildSpotDef.requires_spot: StringName = &""` and `requires_spot_tier: int = 1` (D-10, per plot, applies to the plot's first build, so a built Field never depends on its Mill again).
- `BuildingTierDef.choices: Array[ChoiceDef] = []` (generic, any tier; empty means no branching).
- `ChoiceDef`: `id`, `display_name`, `flavour`, `icon: Texture2D`, `modifiers: Array[StatModifierDef]`. `effect_line()` is generated from `modifiers` and the `StatIds` labels ("+25% tower damage"), so the numbers on a card are the numbers applied (D-07).
**Gate:** extend `CommandProcessor.validate_build(spot_id, choice_id = &"")`; the default argument keeps every existing caller (`BuildHoldController`, bots, tests). New order, after the existing three and before affordability: `NOT_DAY`, `UNKNOWN_SPOT`, `MAX_TIER`, `CASTLE_TIER`, `NEEDS_SPOT`, `CHOICE_REQUIRED`, `BAD_CHOICE`, `CANNOT_AFFORD`. New constants `&"castle_tier"`, `&"needs_spot"`, `&"choice_required"`, `&"bad_choice"`. Existing order, verified: "Check order: NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD." [VERIFIED: simulation/commands/command_processor.gd:60]. The requirement checks use only existing public reads (`get_building_def_for_spot`, `current_tier`, `get_spot`), so `BuildingSystem` gets no new public method.
**Intent:** `BuildIntent._init(target_spot, choice: StringName = &"")` with a `choice_id` field. `_submit_build` passes it to the validator, spends, calls `apply_next_tier`, then if the tier had choices calls `StatStack.add_source(choice_id, choice.modifiers)` and emits `choice_picked(spot_id, tier, choice_id)`.
**Replay:** bots call `ctx.commands.submit(BuildIntent.new(spot, choice))` on the tick they think, exactly as they submit builds today; the choice reaches the digest through `choice_picked`. Add the signal to `SimEvents`, `tests/support/sim_signals.gd` `ALL`, `SimRecorder.HANDLED` and a handler plus connect in the same task (the recorder header and `test_determinism.gd` enforce this).
**Castle plot:** a `BuildSpotDef` appended last in `spots` with `building_id = &"castle_center"` and a data marker (recommended: `BuildSpotDef.kind` enum or a `is_castle` flag, "the plot's kind is data", like `wall_run`). `BuildingSystem` creates its tier-1 instance in `_init` without an event so the castle "starts standing". The three places that test `spot.wall_run == null` (standing_spot_ids line 151, `dawn_income_by_spot`, the rebuild path) become one private `_is_plain(spot)` that also excludes the castle plot, so enemies never target it and towers never treat it as a tower. [VERIFIED: building_system.gd:78-92,145-154]
**Castle numbers:** `CastleState` stops reading `map.castle_max_health` once and instead owns "current tier numbers" (max health, arrow damage/range/interval/speed, base income) refreshed by `set_tier`, with legacy fixtures (no castle def) keeping the `MapConfig.castle_*` fields so their digests cannot move. `validate()` requires tier I of `castle_center` to equal the legacy fields (70 health, 2 / 22 / 1.5 / 27, base income 1) so there is one source of truth. `CastleAttack.is_armed`/`step` read `CastleState`, not `MapConfig`.
**Why not a separate castle system:** it would re-implement focus, label, cost, hold, `building_built`, view swap and `BuildIntent` for the choice id; the cost of the plot-in-`BuildingSystem` route is one private helper and three predicate edits.

### Pattern 4: Choice cards - input and hand-over
- `CardPicker` (Node, run-bound, accessor `map_root.get_cards()` like `get_selection()`): shown when the focused spot is the castle plot (or any plot whose next tier has `choices`), by day, in range, and `validate_build(spot)` without a choice is not already blocked by a gate reason; pre-highlight none (recommended: the hold then refuses with `CHOICE_REQUIRED` and the existing denied bump, and the label status reads "Pick a card (1-4)").
- Digits: reuse the existing `group_1`..`group_4` actions [VERIFIED: project.godot group_1..group_4 bound to physical keycodes 49-52]; no `project.godot` change. `CommandKeyController._process` loops `GROUP_ACTIONS` and calls `_group_key`; it must still call `_pressed_now(action)` for 1-4 (to keep its edge state correct) but skip `_group_key` while `CardPicker.is_showing()`. Digits 5-9 and 0 keep their control-group meaning. [VERIFIED: input/command_key_controller.gd:124-126]
- Mouse: `CardPicker._input` handles motion (hover highlight, never consumes) and `InputEventMouseButton` left press over a card (highlight, `get_viewport().set_input_as_handled()`), so `SelectionController._unhandled_input` never starts a drag or deselects. A press elsewhere is untouched. A click never buys.
- Hold: `BuildHoldController._try_start_hold` calls `validate_build(_focused, picker.highlighted())`; denied reasons emit `hold_denied` as today; the choice is captured into `_active_choice` at hold start and `_finish_hold` submits `BuildIntent.new(spot_id, _active_choice)`, so moving the highlight mid-hold cannot change what is bought. Release or leaving range cancels for free (unchanged `_cancel_hold`).

### Pattern 5: IncomeState (Mine, Harbor, Shrine) and the dawn payout
`IncomeState` (new, `simulation/economy/`), constructed in `RunContext` from `(map, buildings, events, stats)`:
- State per spot id: Mine `paid_dawns` (int); Harbor `boats` (int); Shrine `kill_hp` (int) and `awake` (bool). It connects `events.enemy_died` in `_init` (same style as `WallSystem` connecting `building_built`): for each Shrine plot in MapConfig order, if the death position is within the tier's `wake_radius` (squared compare) add `map.find_enemy(def_id).max_health` to `kill_hp`; at or above `wake_threshold_hp` set `awake` once and emit `shrine_woke`. Credit continues to accrue while a Shrine is destroyed (D-14).
- `dawn_payouts()` returns `{spot_id: amount}` in `buildings.spot_ids()` order for the three special kinds and advances state: skip any spot that is destroyed or `rebuilt_this_dawn` (read from `get_instance`) with no progress (D-14). Mine pays `max(floor, start - paid_dawns)` then `paid_dawns += 1`. Harbor first `boats = min(boats + 1, cap)` (emit `harbor_boats_changed`) then pays `boats * per_boat`. Shrine pays `dawn_income` only if awake.
- Merge: `RunManager._apply_dawn_payout` builds `per_spot` by walking `_buildings.spot_ids()` and taking the amount from `dawn_income_by_spot()` or from `dawn_payouts()`, so MapConfig order and the single `dawn_payout` event are preserved; the castle entry stays last under `CASTLE_PAYOUT_KEY`. The three special buildings carry `dawn_income = 0` in their tier data so `BuildingSystem.dawn_income_by_spot()` returns nothing for them (no double pay); their numbers live in new tier fields (below).
- New `BuildingTierDef` fields (all default 0 / empty): `income_step` and `income_floor` (Mine), `boat_cap` and `boat_income` (Harbor), `wake_radius` and `wake_threshold_hp` (Shrine), `attack_stat` (`&"tower.damage"` default, `&"shrine.damage"` for the Shrine). A `BuildingDef.pays_income()` helper (any tier with `dawn_income > 0`, or any special field set) replaces the `tier_def.dawn_income > 0` tests in `DawnNoIncomeMarker._pays_income` (dawn_no_income_marker.gd:72-77) and the role test, so the crossed-coin marker (D-14) appears on a rebuilt Mine, Harbor and Shrine.
- Events (each in `SimEvents`, `SimSignals.ALL`, `SimRecorder.HANDLED` plus handler and connect): `choice_picked(spot_id, tier, choice_id)`, `shrine_woke(spot_id)`, `harbor_boats_changed(spot_id, boats)`. The payout itself is already in the digest through `dawn_payout`.

### Pattern 6: Shrine attack and synergy
- `TowerSystem.step` gets one gate: skip a spot whose building def is a Shrine and which is not awake (ask `IncomeState`, passed as an optional constructor parameter), and read damage with `stats.int_value(tier.attack_stat, tier.attack_damage)`. The bolt is the existing `PendingHits.enqueue(... KIND_BUILDING, spot_index ...)` plus `attack_fired`, so `ProjectileVfx` already draws it from the spot [VERIFIED: presentation/vfx/projectile_vfx.gd handles KIND_BUILDING at 192, 268, 309]. Kill credit lands in `kills_towers` in the reports; add a `shrine` spend role and (optional) `kills_shrines` column only if the report needs them.
- Synergy (D-12): when the awake count `n` changes, `StatStack.add_source(&"shrine_synergy", [PERCENT +20 * (n - 1) on shrine.damage])` (or remove it when `n <= 1`). Every awake Shrine reads the same stat, so each gets +20% per other awake Shrine (FEATURES.md: "+20% per additional shrine").
- Shrines are appended last in spot order, so they step after towers (spot order) and before the castle arrow; no change to the fixed night step order. The pending-hit sequence counter only advances when something enqueues, so fixtures without Shrines are unaffected.

### Pattern 7: Dawn, upgrade and refresh rules
- A pick or a castle tier happens by day. After applying it, `CommandProcessor` triggers the refresh through `StatStack.changed`: the king gains the max-health delta, `repair_standing()` and the wall max-health re-apply run so no bar shows "hurt" for a freshly raised maximum, and the castle heals to its new maximum. Units already alive keep their old health until the dawn restore (documented limitation).
- `CastleState.set_tier` sets health to the new maximum (the castle is at full health by day because `castle.repair()` runs at dawn).

### Pattern 8: Card row (world space)
- `CardRowModel` (pure, no Nodes): from `(ctx, spot_id, highlighted)` returns four card dicts `{id, name, flavour, effect_line, icon, highlighted}`; `hit_test(rects: Array[Rect2], point: Vector2) -> int`; digit-to-index mapping. Unit-testable without a scene.
- `CardRow` (Node3D, run-bound, same bind/refresh pattern as `SpotLabel`): per card a `MeshInstance3D` quad (unshaded `StandardMaterial3D`, `no_depth_test`, billboard), a `Sprite3D` icon, a `Label3D` name, a `Label3D` flavour line; the highlighted card is raised and brighter and shows the numbers line. Scale with camera distance using the same `LEGIBLE_CAMERA_DISTANCE = 16.9` rule as `SpotLabel` [VERIFIED: ui/world/spot_label.gd:14-17]. Anchor above the castle plot at `spot.position + (0, height, 0)` with the height tuned by screenshot.
- Picking: each frame `CardPicker` projects each card's four world corners with `Camera3D.unproject_position` into `Rect2`s and feeds them to `CardRowModel.hit_test`. No colliders, no physics, no SubViewport.
- The `SpotLabel` keeps showing the cost coins; while cards show, the label's title reads the castle tier being bought ("Castle II").
- `SpotLabelModel.describe` gains the locked states by asking `ctx.commands.validate_build(spot)`: `CASTLE_TIER` -> status "Needs Castle II" (Roman numeral from `BuildingDef.ROMAN_NUMERALS`), `NEEDS_SPOT` -> "Needs a Mill" (the required building's `display_name`), `CHOICE_REQUIRED` -> "Pick a card (1-4)". For a locked state report `cost` 0 so the coin row stays hidden and the status line shows (the `Status` Label3D shares the coins' position). [VERIFIED: ui/world/spot_label.tscn, spot_label_model.gd]

### Pattern 9: Bots, balance and the new golden
- `PlaytestBot._build` today: on `OK` submit; on `MAX_TIER`/`UNKNOWN_SPOT` skip; any other reason returns and waits [VERIFIED: tools/replay/playtest_bot.gd:127-139]. With the gate, a locked entry would block the whole order forever. Change: `CASTLE_TIER`/`NEEDS_SPOT` defer the entry (keep it in a pending list retried each think, continue with later entries); `CHOICE_REQUIRED` is impossible when the bot supplies the next id from a per-strategy ordered `card_picks` list.
- `_is_tower_plot` returns true for any plot whose tier I has `attack_damage > 0` (playtest_bot.gd:157); the castle and the Shrine would qualify and `_prioritise_telegraphed_towers` would reorder them among tower slots. Exclude by building id/kind. `Tally._role_of` (replay_driver.gd:199) likewise classes anything attacking as "towers": add `castle` and `shrine` roles.
- Strategy changes: add a `castle_plot` entry (repeated for II, III, IV) and the economic plots to the balanced/army orders; keep the Phase 4 orders as no-castle twins (`balanced_no_walls` precedent) so the report shows what the gate and the castle cost or give. Fit the castle cost and ability numbers so `balanced` stays at 7 or 8 wins of seeds 1..10 (pinned constants live in `tests/integration/test_balance_acceptance.gd`; `BALANCED_LOST_SEEDS` etc. will need re-pinning from the measurement, and the strategy list test pins 8 names).
- Starting numbers for the fit (all `[ASSUMED]`, chosen to the existing scale of House 2/3/5 paying 1/2/3, Tower 4/6, Barracks 4/8/16, 4 starting gold, base income 1): castle cost II 6, III 10, IV 16; castle health 70 / 100 / 140 / 200; castle arrow damage 2 / 3 / 4 / 5; base income 1 / 2 / 3 / 4. Gold Mine cost 4, first payout 3, step 1, floor 1. Mill cost 3 / 4 / 6 paying 1 / 2 / 3; Field cost 1 paying 1. Harbor cost 3 / 6, cap 3 / 5, boat gold 1 / 1. Shrine cost 3, threshold about 100 hp (E4), radius 18 m, reach 9 m, damage 3, interval 1.1 s, pays 1. The bots earn only about 22 gold in a whole run [VERIFIED: 04-BALANCE-REPORT.md, "Gold earned (mean)" 21.9 for balanced], so the Mine, Harbor and the castle ladder are large levers: expect several measurement rounds.
- The new `economy` scenario (fixture map and king, frozen like `smoke`): a map with the castle def, Mine, Mill with a Field, Harbor and a Shrine, a short scripted bot that buys castle II with a pick, builds each, lets a Shrine wake and a building fall once, and ends. Add to `ReplayScenarios.NAMES`, `max_ticks`, `run`, `tests/golden/economy.json`, the two CI replay lines (Linux `test` job and Windows `native-windows` job) and the `tools/replay.sh` usage comment.

### Anti-Patterns to Avoid
- **Applying a bonus outside the stack** (`damage *= 1.25` in a consumer): breaks order-independence and the overlay.
- **Rounding per bucket or per modifier:** reintroduces pickup-order dependence; round once.
- **Reading `def.max_health` / `tier.attack_damage` in presentation** for anything the stack can change (P7).
- **A gate that returns a new reason but leaves the bots waiting** (they stall; P2).
- **Putting the Shrine in a second attack loop:** it would shoot the same enemy as towers with a different cooldown map; reuse the tower loop with the awake gate.
- **Emitting `command_rejected` for the card state:** highlight changes are UI state, not commands.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| World-to-screen for card hit tests | Manual projection matrices | `Camera3D.unproject_position` per corner | Handles FOV, aspect and window size |
| Card text layout | Per-glyph sprites | `Label3D` (`autowrap_mode`, `width`, `font_size`, `outline_size`) | Same as `SpotLabel` |
| Icon image generation | A runtime image painter | CC0 PNGs logged in `ASSETS.md`, or first-party SVG/PNG files committed as assets | Reviewable, no per-run work |
| Rounding | Float `round()` on a chain of floats | The integer half-up formula (E1) | Exact, platform-independent (DR-7) |
| Event digest | A second logging path | New `SimEvents` signals + `SimRecorder` | The recorder is the one source for goldens |
| Replay of picks | A recorded input log | Bots calling `BuildIntent`, `choice_picked` in the digest | The project's replays are bot-driven, not input logs |
| Map data checks | Ad hoc asserts | `MapConfig.validate()` + a `*_validation.gd` helper (precedent `WallValidation`) | Bad data is reported, never armed (T-01-10) |

**Key insight:** every gap in this phase is a small extension of an existing seam (tier fields, build gate, tower loop, dawn payout, spot label, recorder). The risk is not missing machinery but drifting two copies of a number apart, so each number must have exactly one data home and each display must read it.

## Common Pitfalls

### Pitfall 1: A locked entry stalls every bot (and a test harness)
**What goes wrong:** `_build` returns on any reason other than OK/MAX_TIER/UNKNOWN_SPOT, so `castle_tier` blocks all later purchases and the balanced bot buys nothing after its first gated entry.
**Why:** the loop was written when the only blocking reason was affordability.
**Avoid:** defer-on-locked (Pattern 9); a test with a gated entry followed by an affordable one.
**Warning signs:** `full_idle` gold piling up unspent; balanced wins collapsing.

### Pitfall 2: Dormant Shrine shoots
**What goes wrong:** see P4. **Avoid:** awake gate in the tower loop plus a test that a dormant Shrine with an enemy in reach fires nothing and an awake one fires.

### Pitfall 3: New plot extends the nav grid
**What goes wrong:** P3: the flow-field cell layout shifts; `walls`-style behaviour on the prototype map changes silently. **Avoid:** pin `NavGrid.origin()/width()/height()` of the shipped map in a test and keep plots inside the content box.

### Pitfall 4: Double-paying or mis-ordering the dawn payout
**What goes wrong:** a special building with `dawn_income > 0` is paid by both `BuildingSystem` and `IncomeState`; or `per_spot` loses MapConfig order so `DawnPayoutVfx` flies coins in the wrong order and `test_dawn_payout*` break. **Avoid:** special tiers carry `dawn_income = 0`; the merge walks `spot_ids()`; keep the castle key last; assert `sum(per_spot) == total`.

### Pitfall 5: Rebuilt-this-dawn progress (D-14)
**What goes wrong:** the Harbor gains a boat, the Mine's counter advances or the Shrine pays on the morning it was rebuilt. **Avoid:** `IncomeState.dawn_payouts` runs after `rebuild_destroyed` and reads `rebuilt_this_dawn`; test each curve with a destroyed-then-rebuilt building across two dawns.

### Pitfall 6: Digit keys do two jobs
**What goes wrong:** pressing 2 picks card 2 and recalls control group 2, or Ctrl+2 stores a group by accident. **Avoid:** the hand-over gate in `CommandKeyController` (Pattern 4); an e2e test with squads selected, cards showing, digit pressed; and the same digit after leaving range recalls the group again.

### Pitfall 7: Mouse click on a card also starts a selection drag
**What goes wrong:** `SelectionController` takes the press in `_unhandled_input`. **Avoid:** `CardPicker` consumes in `_input` only when the press is on a card; a test that a click on a card leaves `SelectionModel` unchanged.

### Pitfall 8: Stat changes leave stale maxima
**What goes wrong:** health bars show hurt after Masons/Royal Training, unit bars use the old max (P7). **Avoid:** `changed` refresh (Pattern 7) and presentation reading the stack.

### Pitfall 9: Gate authoring mistakes
**What goes wrong:** `requires_castle_tier` set on a tier that is also bought on day 1, or a requirement above the castle's top tier, or a Field requiring a Mill spot that does not exist; the player can never buy it. **Avoid:** `validate()` checks (castle tier within `1..max`, `requires_spot` exists, is not the spot itself, requirement graph acyclic, required tier within that building's `max_tier`).

### Pitfall 10: Test-script and lint caps
**What goes wrong:** `test_prototype_map_data.gd` is at 20 tests; `test_balance_acceptance.gd` at 15; `map_config.gd` grows toward 1000 lines; `RunManager` is at 9 of 10 parameters. **Avoid:** new test scripts per concern, validation helpers in their own files, collaborator folding (P8).

### Pitfall 11: Native route untouched
The Phase 4 native step takes enemy defs and the flow field; this phase changes neither inputs. Do not route Shrine kills or modifiers through the native enemy step. A change to `EnemySystem.set_def` inputs would require a re-pin (carried-forward rule).

## Code Examples

### StatStack integer evaluation (design sketch; verified arithmetic in E1)
```gdscript
# Source: this research (E1 probe); formula from ARCHITECTURE.md Pattern 3 / D-15
func int_value(stat: StringName, base: int) -> int:
	var entry: Dictionary = _sums.get(stat, {})
	if entry.is_empty():
		return base                       # identity: byte-identical to the raw def value
	var numerator: int = maxi(base + int(entry["flat"]), 0) * (100 + int(entry["pct"]))
	var denominator: int = 100
	for mult: int in entry["mults"]:      # each 100 == x1.0
		numerator *= mult
		denominator *= 100
	var rounded: int = (numerator * 2 + denominator) / (2 * denominator)  # half up
	return maxi(rounded, 1) if base >= 1 else maxi(rounded, 0)
```
(Add `@warning_ignore("integer_division")` as the repository does elsewhere.)

### Extended validate_build order
```gdscript
# Source: simulation/commands/command_processor.gd:60-71 (current) extended per Pattern 3
func validate_build(spot_id: StringName, choice_id: StringName = &"") -> StringName:
	if not _run_manager.is_build_allowed():
		return NOT_DAY
	if _buildings.get_spot(spot_id) == null:
		return UNKNOWN_SPOT
	var cost: int = _buildings.next_action_cost(spot_id)
	if cost < 0:
		return MAX_TIER
	var gate: StringName = _requirement_rejection(spot_id)   # CASTLE_TIER / NEEDS_SPOT / OK
	if gate != OK:
		return gate
	var choice: StringName = _choice_rejection(spot_id, choice_id)  # CHOICE_REQUIRED / BAD_CHOICE
	if choice != OK:
		return choice
	if not _economy.can_afford(cost):
		return CANNOT_AFFORD
	return OK
```

### Hold controller change (capture the choice at start)
```gdscript
# Source: input/build_hold_controller.gd:80-146 (current) with the choice captured at hold start
func _try_start_hold() -> void:
	var choice: StringName = _cards.highlighted() if _cards != null else &""
	var reason: StringName = _ctx.commands.validate_build(_focused, choice)
	if reason != CommandProcessor.OK:
		hold_denied.emit(_focused, reason)
		return
	_active_choice = choice
	# ... unchanged: _active, _cost, _coins_paid, hold_started
func _finish_hold() -> void:
	var result: StringName = _ctx.commands.submit(BuildIntent.new(_active, _active_choice))
```

### Economy-state dawn merge
```gdscript
# Source: run_manager.gd:205-215 (current) extended per Pattern 5
func _apply_dawn_payout() -> void:
	var flat: Dictionary = _buildings.dawn_income_by_spot()
	var special: Dictionary = _income.dawn_payouts() if _income != null else {}
	var per_spot: Dictionary = {}
	for spot_id: StringName in _buildings.spot_ids():     # MapConfig order
		if special.has(spot_id):
			per_spot[spot_id] = special[spot_id]
		elif flat.has(spot_id):
			per_spot[spot_id] = flat[spot_id]
	var base: int = _castle.base_income() if _castle != null else _base_dawn_income
	if base > 0:
		per_spot[MapConfig.CASTLE_PAYOUT_KEY] = base
	# total, grant and the single dawn_payout emit: unchanged
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-perk `stat *= x` | Bucketed flat / percent / multiplier stack, single rounding | Standard roguelite practice [CITED: .planning/research/ARCHITECTURE.md Pattern 3] | Order-independent, testable |
| One giant economy table | Distinct curves per building (flat, declining, ramping, threshold) | Thronefall design [CITED: .planning/research/FEATURES.md lines 62-66] | Each needs its own small state, not a shared formula |

**Deprecated/outdated:** none relevant; the engine and test tooling are pinned.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The proposed costs, health ladder, arrow ladder, base-income ladder and Mine/Mill/Harbor/Shrine numbers are reasonable starting points | Pattern 9 | They will need several bot rounds; if the castle II cost is too low the "real early trade-off" in D-01 fails |
| A2 | The twelve-ability draft (Pattern 1 stat registry, ability list in the Ability Draft below) is acceptable to the owner | Ability Draft | Owner judges at UAT; cards may be rewritten (data only) |
| A3 | Magic Armor is implemented as `king.damage_taken` x 0.75 rather than reflect | Ability Draft | If the owner insists on reflect, a hit-resolution rule is needed (deferred idea) |
| A4 | Prosperity is a flat `castle.base_income` bonus rather than a percent of all income | Ability Draft | A percent over the total needs a rounding home (the castle key) and changes how the payout looks |
| A5 | Kenney Game Icons / Pirate Kit contain usable icons / boats | Package Legitimacy Audit | Icons or boats may need another CC0 source or first-party drawing; vendor pages did not list contents |
| A6 | The stack's overflow caps (|base+flat| <= 100000, pct in [-90,1000], mults in [10,400], <= 4 mults) are enough for every planned stat | Pattern 1 | A later perk may need wider ranges; widen with a recheck of the int64 bound |
| A7 | No pre-highlight of the first card is the better default | Pattern 4 | Owner may prefer a pre-highlighted first card; it is a one-line change |
| A8 | The Shrine's kill credit should include kills by any attacker, including the Shrine itself | Pattern 5 | Owner might want only non-Shrine kills; trivial to change |
| A9 | The castle plot should be appended last in `spots` so existing spot indices (used as `PendingHits` building ids) do not shift | Pattern 3 | If inserted earlier, spot indices shift and any digest containing a building hit moves |
| A10 | Cards appearing every time the king passes the castle with enough gold will not annoy the owner | Pattern 4 | Feel call for the UAT; a "dismiss" or cooldown may be wanted |

## Ability Draft (Claude's discretion, D-02; numbers are starting points)

Four cards per upgrade tier, each a bundle of `StatModifierDef`s; all three buckets are exercised so the combined tests are meaningful. Stat ids are from the registry in Pattern 1.

| Tier | Card | Modifiers |
|------|------|-----------|
| II | Royal Training | `king.max_health` PERCENT +25; `king.attack_damage` FLAT +1 |
| II | Commander | `unit.max_health` PERCENT +25; `unit.attack_damage` PERCENT +25 |
| II | Masons | `building.max_health` PERCENT +30; `wall.max_health` PERCENT +30 |
| II | Prosperity | `castle.base_income` FLAT +1 |
| III | Assassin's Training | `king.attack_damage` MULTIPLIER 200; `king.attack_interval` MULTIPLIER 150 |
| III | Engineers | `tower.damage` PERCENT +25; `tower.range` PERCENT +15 |
| III | Rallying Banner | `squad.respawn_seconds` MULTIPLIER 60 |
| III | Magic Armor | `king.damage_taken` MULTIPLIER 75 |
| IV | Iron Discipline | `unit.attack_damage` MULTIPLIER 150; `unit.max_health` MULTIPLIER 130 |
| IV | Arrow Storm | `castle.arrow_damage` PERCENT +100; `castle.arrow_range` PERCENT +25 |
| IV | Master Builders | `building.max_health` MULTIPLIER 150; `wall.max_health` MULTIPLIER 150 |
| IV | Golden Age | `castle.base_income` FLAT +2; `shrine.damage` PERCENT +25 |

Combined-case examples for the tests (computed with E1's formula): tower damage base 6 (Tower II) with Engineers (+25%) and the Shrine-style +20% on a different stat is independent; `king.attack_damage` base 3 with Royal Training (+1 flat) and Assassin's Training (x2.0): (3 + 1) * 100 * 200 / (100 * 100) = 8; the same picks in the other order give 8; `king.attack_interval` base 0.8 s with Assassin's x1.5: 1.2 s via the float path.

## Open Questions

1. **Does the owner want the castle plot counted in "22 plots"?**
   - What we know: eight new plots plus the existing 14 make 22; the castle is bought like a plot, so `spots` has 23 entries (P6).
   - What's unclear: whether any display or report should say 22 or 23.
   - Recommendation: treat the castle plot as infrastructure ("22 buildable plots, 23 spots"), pin both numbers in the tests, and mention it in the plan so nobody "fixes" the 23.
   - **RESOLVED (plan 05-02):** the castle plot is infrastructure: "22 buildable plots, 23 spots". Plan 05-02 appends `castle_plot` as spot 15 and creates `tests/unit/test_prototype_map_economy.gd` as the single place the counts are pinned; plans 05-06 to 05-09 raise them as they add plots, ending at 23 spots (22 buildable plus the castle) in plan 05-09.

2. **Where does the pond live in data?**
   - What we know: D-11 says visual only; `validate()` cannot check "off the roads" for a scene-only node.
   - What's unclear: whether the owner minds two new `MapConfig` fields.
   - Recommendation: `MapConfig.pond_center: Vector2` and `pond_radius: float` (0 = none); `MapRoot` or `PondView` draws it; `validate()` and a test prove it contains no plot, spawn point or road segment (point-to-segment distance from each spawn point to the castle at least `pond_radius + 10 m`).
   - **RESOLVED (plan 05-08):** `MapConfig.pond_center` (0, 30) and `pond_radius` 8.0 (0 = no pond), drawn by `PondView` with no collision and never entering NavGrid; `EconomyValidation` reports a pond that holds a plot or spawn point or lies within `pond_radius + 10 m` of a road segment, and `tests/unit/test_pond_layout.gd` pins the shipped layout.

3. **Card icons: download a pack or draw first-party?**
   - What we know: D-07 wants CC0 icons logged in `ASSETS.md`; no icon pack is in the repo; the vendor pages do not list icon names (A5).
   - What's unclear: whether a suitable CC0 pack exists with sword/shield/heart/coin/tower-style glyphs.
   - Recommendation: the plan gets one `checkpoint:human-verify` task to approve a specific CC0 pack download (record URL, size, SHA256 as Phase 1 did); fallback is first-party icons drawn as committed PNG/SVG files, which need no third-party log entry.
   - **RESOLVED (plan 05-04):** first-party icons, no download: twelve original SVG glyphs under `assets/first_party/card_icons/`, dedicated CC0-1.0 and logged in a new "First-party assets" section of `ASSETS.md` (icon art is Claude's discretion in CONTEXT, so no owner checkpoint is needed); the key hint on each card reuses the already-logged Kenney Input Prompts tiles `keyboard_1.png` to `keyboard_4.png`. The Phase 8 art pass may replace the icons.

4. **Does the castle's per-tier look need new models?**
   - What we know: the castle scene composes seven existing Kenney pieces; only seven GLBs of each pack are in the repo.
   - Recommendation: build tiers II to IV by adding pieces from the already-extracted set (more turrets, a second roof, flags) in `.tscn` wrappers, as the House tiers do; extract new GLBs only if a checkpoint approves a download.
   - **RESOLVED (plan 05-04):** `castle_center_t2.tscn`, `castle_center_t3.tscn` and `castle_center_t4.tscn` compose only the seven Castle Kit GLBs already in the repository (extra storeys, raised turrets, wall pieces, flags); catalog entries for `castle_center` tiers 2 to 4; BuildingViews swaps the keep on the castle plot's `building_built`. No download.

5. **Where does the overlay show the Shrine counts?**
   - Recommendation: one new `Economy` section (awake shrines, kill hp per shrine, Mine dawns, Harbor boats) and one `Stats` section (each stat with a non-identity result: base -> final) registered through `DebugOverlay.register_section` the way `NightOverlaySections.register` does; both read-only (a `test_debug_overlay_readonly` style test).
   - **RESOLVED (plans 05-01, 05-06, 05-08, 05-09):** `StatOverlaySections` (the Stats section, plan 05-01) and `EconomyOverlaySections` (the Economy section: castle tier and picks and Mine rows in plan 05-06, Harbor boats in plan 05-08, Shrine credit and awake state in plan 05-09), both registered in `DebugOverlay.bind_run` after the Squad sections and read-only.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot (pinned) | everything | yes | 4.7.2-stable (`.tools/godot/4.7.2-stable`) | - |
| Native library | all runs (the game refuses to start without it) | yes | `addons/duskhold_sim/bin/libduskhold_sim.windows.x86_64.dll` present; replay ran | rebuild with `bash tools/native_build.sh` |
| Git Bash + tools/*.sh | tests, replays, playtest, lint | yes | probes ran | - |
| gdtoolkit (gdlint, gdformat) | lint gate | yes | `.tools/venv/Scripts/gdlint.exe` | `python tools/bootstrap.py --lint-tools --yes` |
| Python | helper scripts | yes | 3.14.5 | - |
| Git LFS | new GLB/PNG assets | yes | 3.5.1 | - |
| Network to kenney.nl | optional asset downloads | reachable from the research tool (pages fetched) | - | first-party art |

Stray `~libduskhold_sim.windows.x86_64.dll~RF*.TMP` files sit in `addons/duskhold_sim/bin/` (editor temp files); they are not part of this phase.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT 9.7.1 on Godot 4.7.2 |
| Config file | `.gutconfig.json` (dirs `tests/unit`, `tests/integration`, `tests/e2e`, prefix `test_`) |
| Quick run command | `bash tools/test.sh -gselect=<script substring>` |
| Full suite command | `bash tools/test.sh` (about 9 minutes in Phase 4) |
| Replay commands | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` (also `army`, `walls`, `economy` once added; `full_idle --twice`) |
| Gate stress | `bash tools/gate_stress.sh --twice` (reads the tools-only stress map, never the prototype map) |
| Balance | `bash tools/playtest.sh --seeds=10` (about 5 minutes for 80 runs in Phase 4; more strategies add time) |
| Lint | `bash tools/lint.sh` |
| Screenshots | `bash tools/screenshot.sh <shot>` (real window; CI uses Mesa software rendering) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| META-08 | Each bucket alone (flat, percent, multiplier) gives the documented value; pickup order never matters; rounding half-up pinned; clamp to 1; overflow caps | unit | `bash tools/test.sh -gselect=test_stat_stack` | no, Wave 0 |
| META-08 | Combined cases (E1 vectors; ability pairs; Shrine synergy source replace/remove) | unit | `bash tools/test.sh -gselect=test_stat_combined` | no, Wave 0 |
| META-08 | `docs/STAT_MODIFIERS.md` states the formula and rounding rule; every modifier in `data/abilities/*.tres` uses a registered stat; sim-rule scan includes the new dirs | unit | `bash tools/test.sh -gselect=test_stat_contract` | no, Wave 0 |
| META-08 | Identity wiring: every consumer returns the raw value with no modifier; goldens and `full_idle` byte-identical | replay | three `replay.sh --expect-file` commands + `full_idle --twice` digest equals E3 | yes (replay), new compare step |
| BLDG-05 | `choices` on a tier; `choice_required`/`bad_choice`; the pick locks (modifiers applied once, not offered again); `choice_picked` recorded | unit | `bash tools/test.sh -gselect=test_build_choice` | no, Wave 0 |
| BLDG-08 | Castle starts at tier I, upgrades II-IV, health/arrow/base income per tier through `CastleState`; castle never targeted; never rebuilt | unit | `bash tools/test.sh -gselect=test_castle_tiers` | no, Wave 0 |
| BLDG-08 | Twelve ability resources: four per tier, distinct ids, numbers match the contract, `effect_line()` text is generated from modifiers | unit | `bash tools/test.sh -gselect=test_ability_data` | no, Wave 0 |
| BLDG-09 | `castle_tier` rejection order and nothing spent; ungated tiers unaffected; `validate()` reports impossible requirements | unit | `bash tools/test.sh -gselect=test_build_requirements` | no, Wave 0 |
| ECON-03 | Mine pays start, then 1 less per paid dawn to the floor; skipped dawns do not advance | unit | `bash tools/test.sh -gselect=test_gold_mine` | no, Wave 0 |
| ECON-04 | Mill pays per tier; Field locked until Mill tier >= 1 (`needs_spot`), flat 1, unaffected by a later Mill loss | unit | `bash tools/test.sh -gselect=test_mill_fields` | no, Wave 0 |
| ECON-05 | Harbor gains a boat per surviving dawn up to the cap; upgrade raises cap and per-boat gold; destroyed/rebuilt dawns gain nothing | unit | `bash tools/test.sh -gselect=test_fishing_harbor` | no, Wave 0 |
| ECON-06 | Shrine wake by credited max health in radius, stays awake, pays only when awake, dormant never fires, awake fires, synergy +20% per other awake Shrine | unit + integration | `bash tools/test.sh -gselect=test_shrine` | no, Wave 0 |
| ECON-03..06 | D-14 across all four: destroyed loses nothing accumulated, only skips; one `dawn_payout`, MapConfig order, castle key last; crossed-coin marker on rebuilt special buildings | integration | `bash tools/test.sh -gselect=test_economy_destroyed` and `test_dawn_payout_economy` | no, Wave 0 |
| UI-02 | `CardRowModel` content (icon, name, flavour, numbers on highlight), hit test on supplied rects, digit mapping | unit | `bash tools/test.sh -gselect=test_card_row_model` | no, Wave 0 |
| UI-02 / BLDG-05 | World-space card row appears day-only/in-range/affordable; hover and click highlight, never buy; digits 1-4 pick cards and do not recall groups; click does not change selection; hold refused without a highlight, completes with it | e2e | `bash tools/test.sh -gselect=test_card_row` and `test_card_input_handover` | no, Wave 0 |
| UI-02 | Locked status lines "Needs Castle II" / "Needs a Mill" / "Pick a card" | unit | `bash tools/test.sh -gselect=test_spot_label_locked` | no, Wave 0 |
| D-09..D-11 | Prototype map: 22 buildable plots plus castle plot (23 spots), existing 14 unmoved, nav grid origin/width/height unchanged, plots clear of roads/wall runs/gaps, Fields near Mill, Shrines in kill zones, pond clear, `validate()` empty | unit | `bash tools/test.sh -gselect=test_prototype_map_economy` and `test_nav_layout_pin` | no, Wave 0 |
| D-08 | Goldens: `smoke`, `army`, `walls` unchanged; new `economy` golden twice-agree | replay | `bash tools/replay.sh --scenario=economy --twice --expect-file=tests/golden/economy.json` | no, Wave 0 |
| Bar | `balanced` wins 7 or 8 of seeds 1..10; report with and without castle | integration (measurement) | `bash tools/playtest.sh --seeds=10` then `bash tools/test.sh -gselect=test_balance_acceptance` | yes (pins to update) |
| Feel | Cards readable, castle tiers legible, new buildings readable, economy feel | manual-only (owner, `/gsd-verify-work`) | scripted screenshots first, then owner session | n/a |

### Sampling Rate
- **Per task commit:** `bash tools/test.sh -gselect=<touched suite>` plus `bash tools/lint.sh`.
- **Per wave merge:** the three golden replays with `--twice`, `full_idle --twice` (digest compared to E3 until the first data change), the touched integration suites, and `bash tools/gate_stress.sh --twice` for any wave touching `simulation/`.
- **Phase gate:** full `bash tools/test.sh`, all golden replays including `economy`, gate stress, `bash tools/playtest.sh --seeds=10` with the report committed, the new shots via `bash tools/screenshot.sh`, then `/gsd-verify-work` (owner feel check).

### Wave 0 Gaps
- [ ] `tests/unit/test_stat_stack.gd`, `test_stat_combined.gd`, `test_stat_contract.gd` - META-08
- [ ] `tests/unit/test_build_choice.gd`, `test_build_requirements.gd`, `test_castle_tiers.gd`, `test_ability_data.gd` - BLDG-05, BLDG-08, BLDG-09
- [ ] `tests/unit/test_gold_mine.gd`, `test_mill_fields.gd`, `test_fishing_harbor.gd`, `test_shrine.gd`, `tests/integration/test_economy_destroyed.gd`, `test_dawn_payout_economy.gd` - ECON-03..06
- [ ] `tests/unit/test_card_row_model.gd`, `test_spot_label_locked.gd`, `tests/e2e/test_card_row.gd`, `test_card_input_handover.gd` - UI-02
- [ ] `tests/unit/test_prototype_map_economy.gd`, `test_nav_layout_pin.gd`
- [ ] Updates (not new): `test_military_data_contract.gd` (`SPOT_COUNT` 14), `test_prototype_map_walls.gd` ("fourteen plots"), `test_playtest_strategies.gd` (names list), `test_balance_acceptance.gd` (re-pinned seeds), `test_building_view_catalog.gd`, `test_sim_rules_guard.gd` (`MATH_ROOTS`), the debug-overlay registration/readonly tests
- [ ] `tests/support/sim_signals.gd` and `tools/replay/sim_recorder.gd`: add `choice_picked`, `shrine_woke`, `harbor_boats_changed` (handler, connect, HANDLED)
- [ ] `tests/fixtures/fixture_map_replay_economy.tres` (+ king, reuse smoke tuning) and `tests/golden/economy.json`; `ReplayScenarios` and CI lines
- [ ] `docs/STAT_MODIFIERS.md`
- [ ] Framework install: none (GUT 9.7.1 present)

Manual-only checks (owner or scripted screenshot): world-space card legibility and raise/brighten look at the shipped camera; castle tier looks; mouse feel of hover versus click; digit hand-over feel while a squad is selected; whether the cards re-appearing on every pass is acceptable (A10); the ability set and numbers (owner judges at UAT).

## Security Domain

`security_enforcement` is enabled (ASVS level 1, block on high). This is an offline single-player game: no authentication, sessions, network or cryptography. The relevant surface is untrusted data files (`.tres` maps and abilities), tool arguments and resource exhaustion.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | none (no accounts) |
| V3 Session Management | no | none |
| V4 Access Control | no | none |
| V5 Input Validation | yes | `MapConfig.validate()` extended: stat ids must be registered, bucket value ranges and per-stat modifier counts (overflow bound), requirement graph (existing spot, in-range tier, acyclic), choice lists non-empty only where intended and ids unique, `boat_cap`/`wake_threshold_hp`/radius finite and bounded, pond finite and positive; bad data is reported and never armed |
| V6 Cryptography | no | none |
| V12 Files and resources | yes | any new tool CLI (none planned) reuses `ReplayCli.safe_dir`/allowlists; report outputs only under `res://build`; no path taken from data |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------------|---------------------|
| A tampered ability file with huge percent or multiplier values overflows the integer stack | Tampering / DoS | Range caps enforced in `validate()` and `add_source` (A6), product bound documented |
| An unknown stat id in a modifier silently does nothing | Tampering | Registry check in `validate()` |
| A requirement cycle or missing spot makes a plot unbuyable | Tampering | `validate()` reports it |
| Huge `boat_cap` / `wake_threshold_hp` / radius values | DoS | Bounded and finite in `validate()` |
| A far-flung plot enlarges the nav grid allocation (T-04-13 precedent) | DoS | Grid cell cap already exists; plus the layout pin test |
| Choice id supplied by a bot or test that is not in the tier's list | Tampering | `BAD_CHOICE` rejection, nothing spent |

## Sources

### Primary (HIGH confidence)
- Repository files read this session: `.planning/phases/05-castle-center-economy-depth/05-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/phases/04-crowd-scale-battles-walls/04-RESEARCH.md` (shape and Validation precedent), `04-BALANCE-REPORT.md`, `.planning/research/FEATURES.md` (Economy/Buildings), `ARCHITECTURE.md` Pattern 3, `PITFALLS.md` Pitfall 6, `.claude/CLAUDE.md`, `.gdlintrc`, `.gutconfig.json`, `.github/workflows/ci.yml`, `project.godot` (input map), `data/maps/prototype_map.tres`, `data/buildings/*.tres`, `data/enemies/*.tres`, `data/tuning/*.tres`
- Simulation: `simulation/defs/{building_def,building_tier_def,build_spot_def,map_config,king_def,weapon_def,unit_def,nav_tuning}.gd`, `simulation/walls/{wall_run_def,wall_system,wall_validation}.gd`, `simulation/buildings/*`, `simulation/castle/castle_state.gd`, `simulation/commands/{command_processor,build_intent}.gd`, `simulation/events/sim_events.gd`, `simulation/run/{run_manager,run_context}.gd`, `simulation/night/{night_sim,tower_system,castle_attack,pending_hits,target_query,enemy_system}.gd`, `simulation/king/king_state.gd`, `simulation/squads/{unit_system,squad_system}.gd` (read ranges), `simulation/nav/nav_grid.gd`
- Presentation/UI/Input: `ui/world/{spot_label,spot_label_model}.gd`, `spot_label.tscn`, `input/{build_hold_controller,command_key_controller,selection_controller}.gd`, `ui/hud/{dawn_no_income_marker,toast}.gd`, `ui/overlay/{debug_overlay,night_overlay_sections}.gd`, `presentation/buildings/*`, `presentation/map/{map_root.gd,prototype_map.tscn}`, `presentation/king/king.gd` (grep)
- Tools/tests: `tools/replay/{replay_scenarios,replay_driver,replay_cli,sim_recorder,playtest_bot,playtest_strategies,balance_report}.gd`, `tools/{replay,playtest,test,lint,gate_stress}.sh`, `tests/golden/*.json`, `tests/support/sim_signals.gd`, `tests/unit/test_sim_rules_guard.gd`, test counts of the pinned scripts
- `assets/attribution.json`, `ASSETS.md`
- Probes (scratchpad): stat-math vectors, NavGrid layout with and without extra plots; replay `full_idle --twice`; kill-position analysis of `build/replay_p5research/full_idle.log`; plot-geometry check

### Secondary (MEDIUM confidence)
- kenney.nl asset pages (Game Icons, Pirate Kit, Fantasy Town Kit): license CC0 and file counts only; contents not listed

### Tertiary (LOW confidence)
- Candidate icon/boat availability in those packs (A5)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies; versions pinned and probed
- Architecture: HIGH for the integration points (read in source), MEDIUM for choices the planner may take differently (castle in `BuildingSystem` vs separate, Label3D vs Controls)
- Pitfalls: HIGH - each is traced to a line in the repository
- Numbers (costs, thresholds, ability values): MEDIUM/LOW - starting points that the bots must fit
- Assets: LOW - no pack contents confirmed

**Research date:** 2026-10-21
**Valid until:** 30 days for the code facts (the repository moves only through this project's own commits); re-run the baseline probe (E2, E3) at the start of execution because earlier plans in this phase will change the tree.
