# Phase 5: Castle Center & Economy Depth - Context

**Gathered:** 2026-10-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 5 gives the day real depth. The castle center becomes an upgradeable building: four tiers, bought by riding up to it and holding like any plot, each upgrade raising its health and offering one pick of four run-wide abilities, so a run makes three picks (BLDG-08). The pick is made through the project's first branching-choice system: choice cards with an icon, a name and a short description, chosen with the keyboard or the mouse and locked for the rest of the run (BLDG-05, UI-02). The castle's tier gates the top tier of every other building (BLDG-09). Four new economic buildings join the prototype map, each with its own income curve: a Gold Mine that pays a lot and then less every dawn, a Mill that unlocks nearby Field plots that each pay a flat amount, a Fishing Harbor that gains a paying boat every dawn up to a cap that its upgrade raises, and a Shrine that wakes after enough enemies die near it, then shoots, pays and strengthens other awake Shrines (ECON-03 to ECON-06). Every bonus in the game, from castle abilities to building upgrades, combines through one fixed, documented stat-modifier order with automated single-modifier and combined-modifier tests (META-08).

The card system and the modifier stack are built once here and reused: Phase 6's tower specializations and Phase 7's unit choices are later users of the cards; Phase 10's perks and mutators and Phase 12's research are later users of the stack. The prototype map grows from 14 to 22 plots and the replay goldens are regenerated once, deliberately, for the new plots. The balance bots learn to buy the castle tiers and the new buildings, the bar stays the Phase 2 bar, and the phase ends in the owner's feel check through `/gsd-verify-work`, as before.

**Not in this phase:**
- tower specializations and the wider enemy roster (Phase 6); unit choices and the Hero's Quarter (Phase 7) — they reuse the card system, which must therefore be generic from the start
- perks, mutators and the loadout screen (Phase 10); research buildings (Phase 12) — they reuse the modifier stack
- the art cohesion pass and SFX (Phase 8); the new buildings use CC0 placeholders logged in `ASSETS.md`
- scoring, retry, saves (Phase 9); menus and settings (Phase 13)
- any gamepad work (owner decision 2026-10-16: keyboard and mouse only)

</domain>

<decisions>
## Implementation Decisions

### Carried Forward (locked before this discussion — do not re-litigate)
- Stack, the simulation / presentation / data split, `.tres` content referenced by id, the command/intent layer, the event bus, CC0-only assets with the attribution log (`01-CONTEXT.md`).
- One building type per fixed plot (Phase 1 D-02); every tunable number lives in `.tres` data, never in code (Phase 1 D-09); the free dawn rebuild that pays nothing that morning (LOOP-04, LOOP-05, Phase 2 D-14 crossed-coin marker).
- Ride-up-and-hold building and upgrading exactly as validated through the Phase 1 to 4 sign-offs (Phase 1 D-05 as amended, D-06 refund on early release, D-07 world-space spot label, D-08 denied bump). Keyboard and mouse only; the shipped pad code stays unsupported and untouched.
- The deterministic fixed-step simulation (`SimClock` 1/30 s, seeded RNG, integer ticks, event recorder, golden replays, bot playtests) and the rule that nothing under `simulation/` reads wall-clock time, the OS, the scene tree or the time scale (Phase 2 DR-1 to DR-10). Player commands enter the simulation as intents stamped on ticks. Presentation never writes the simulation.
- The prototype map is the permanent sandbox (Phase 1 D-04); its 14 existing plots, their positions and their balance data are not moved (Phase 3 D-03, Phase 4 D-06).
- Goldens mean "same outcomes, not digests" (Phase 4 D-14): a digest move is a stop rule that needs an owner checkpoint, never a silent re-pin. This phase's one regeneration is pre-approved below (D-08).
- The Phase 2 balance bar: the balanced bot wins 7 or 8 of seeds 1 to 10; the bots measure, only the owner judges fun; night counts move only if the bar breaks (Phase 4 D-15 pattern).
- The castle as it stands: 70 health in map data, its own arrow (2 damage every 1.5 s, 22 m reach, 27 m/s arrows, Phase 2 playtest-gate decision), 1 base gold at dawn, the king spawns beside it.
- The PLAT-01 native route (Phase 4): the enemy step, separation, wall solids, the flow field, the stuck tracker and the per-frame view fills run in the C++ GDExtension behind unchanged GDScript APIs, pinned byte-identical. New systems in this phase are GDScript; they may call the native facades but must not change the native step's inputs without a re-pin.

### Castle Center tiers and abilities
- **D-01:** **The castle has four tiers and a run makes three ability picks.** The castle starts standing at tier I. Upgrades to II, III and IV are bought by riding up to the castle and holding the action key, like any plot. Each upgrade raises the castle's health with a gentler step than Thronefall's three-rung 1:3:7 ladder, and each offers one pick of four abilities (D-02). The health ladder and the costs are data on Thronefall's rising cost line, fitted by the planner and the bots; the first upgrade must be a real early trade-off, not a free day-1 buy. — **Reversibility:** costly — the ability set (twelve cards), the gate authoring (D-03), the castle's model per tier and every balance number measured afterwards assume four rungs.
- **D-02:** **Twelve abilities, authored by Claude in Thronefall's style.** Four per upgrade tier, each a run-wide passive that touches only systems that exist by Phase 5 (king, squads, towers, walls, buildings, the castle, dawn income) and is expressed as stat modifiers through the new stacking order (D-15), numbers in data. Candidates: Royal Training (+king health and damage), Commander (+unit health and damage), Masons (+building and wall health), Prosperity (+dawn income), Assassin's Training (slower but far harder king attacks), Engineers (+tower damage and range), Rallying Banner (units return faster at night), Magic Armor (part of the damage the king takes is reflected). The four cards of one tier must be distinct lines, and a card is offered once per run. The owner judges the set and its numbers at the UAT; a pick is permanent for the run (BLDG-05).
- **D-03:** **One gate: the top tier of every building needs the castle at tier II.** Tier I and II of any building are always buyable; the last tier of each building (House III, Tower II, Barracks III, Archery Range III, Wall III, Mill III, Harbor II, and so on) requires castle tier II. The requirement is authored per tier in data (default: none) so later maps can gate differently, and `MapConfig.validate()` reports an impossible requirement. A gated tier's label reads "Needs Castle II" and holding there gives the Phase 1 D-08 denied bump with a `castle_tier` rejection reason, nothing spent. The same requirement mechanism ("this tier or plot needs another spot at tier N or more") is what Field plots use (D-10).
- **D-04:** **Each castle tier also strengthens the castle itself.** Besides health and the ability pick, tiers II to IV raise the castle's arrow (damage, and the planner may touch reach or interval) and add base dawn income (about +1 gold per tier). Numbers in data; the bots check the bar.

### Choice cards
- **D-05:** **Approach, pick, then hold to pay.** Riding up to the castle while an upgrade with a pending pick is affordable shows the four cards. The player highlights one with the number keys 1 to 4 or by pointing the mouse at it (hover highlights; a click highlights too and never buys), then holds the action key as usual; the hold only starts with a highlighted card. Nothing is spent until the last coin lands; releasing early or leaving range cancels for free, exactly as today's builds (Phase 1 D-06); the pick locks when the hold completes. The upgrade and its choice reach the simulation as one intent stamped on a tick (a `BuildIntent` carrying the choice id, or a sibling intent the planner names), so a recorded run replays identically and the bots can pick. While the cards are shown and the king stands in range by day, the digit keys mean "pick a card", not "recall a control group", the same modal rule Phase 3 applied to movement keys while a squad is selected.
- **D-06:** **A row of four cards above the castle in world space.** The cards hover over the plot the way the spot label does (Phase 1 D-07), the highlighted card raised and brighter; day only, in range only; the HUD centre stays clear (Phase 3 D-21). Nothing about the cards lives in the HUD.
- **D-07:** **Each card shows an icon, a name and a flavour line; the exact numbers appear when the card is highlighted** (an expanded line on the card, keyboard or mouse). The numbers are read from the same data the modifier stack applies, so what the card says can never drift from what the game does. Icons are CC0 and logged in `ASSETS.md`.

### New plots on the prototype map and the goldens
- **D-08:** **The new plots join the prototype map and the goldens are regenerated once.** `smoke`, `army`, `full_idle` and `walls` are regenerated in one deliberate commit with a before/after outcome report beside it, the Phase 4 D-14 way: same outcomes expected per seed (win or loss, nights survived, kills within a stated band), because no existing plot moves and the bots merely see more plots. The owner approved this regeneration on 2026-10-21; no further checkpoint is needed for it, but any later digest move in the phase is still a stop rule. — **Reversibility:** costly — every balance number measured afterwards assumes the 22-plot map, and a second sandbox map was considered and rejected.
- **D-09:** **Eight new plots: 1 Gold Mine, 1 Mill with 3 Fields, 1 Fishing Harbor, 2 Shrines.** The map goes from 14 to 22 plots; the existing 14 stay where they are. Two Shrines so that their mutual buff can be seen. Positions are the planner's, within these rules: no plot on a road, inside a wall run's line or in an authored gap; Fields within a few metres of their Mill; Shrines where enemies pass so that they can wake; nothing that changes the routes or the flow field.
- **D-10:** **Field plots exist from the start but are locked until the nearby Mill stands.** They read "Needs a Mill" and the hold is refused with the denied bump until the Mill is at tier I or more. The lock is the D-03 requirement mechanism (the Field's tier I requires the Mill's spot at tier 1 or more). A built Field does not depend on the Mill afterwards: a destroyed Mill is rebuilt free at dawn like anything else and the Fields keep paying.
- **D-11:** **A visual-only pond at one map edge, with the Harbor on its shore.** The pond sits off the three roads; nothing walks on it and nothing is blocked by it, so the flow field, the wall routes, the enemy paths and the gate stress are untouched. Boats on the pond are presentation only.

### Income curves and destroyed-building rules
- **D-12:** **Thronefall's curve shapes, fitted to our scale by the planner and the bots.** Each curve keeps its shape; the numbers live in data and are fitted to our economy (House pays 1/2/3 for 2/3/5 gold, 4 starting gold, 1 base income) so that the balanced bot stays at 7 or 8 wins of 10:
  - Gold Mine: one tier; pays a high amount at its first dawn and 1 less at each later dawn it pays, down to a floor of 1 gold, never 0 (Thronefall: 5 gold, 6 then −1 per night).
  - Mill: three tiers paying per tier (Thronefall: 3/4/6 gold, paying 1/2/6); it unlocks its Fields (D-10).
  - Field: one tier, flat 1 gold at dawn (Thronefall: 1 gold).
  - Fishing Harbor: two tiers; gains one boat at every dawn it survives, up to the tier's cap; every boat pays the tier's per-boat gold (Thronefall: 3 then 7 gold, cap 5 then 10, boat 1 then 2 gold).
  - Shrine: one tier; dormant until the total max health of enemies that die within its radius reaches a threshold (Thronefall: 3 gold, about 350 health, pays 2); once awake it stays awake for the run, shoots enemies in reach like a tower (a bolt on the pending-hit queue), pays its dawn income, and every other awake Shrine gets +20% attack damage, a percent-additive modifier through the stack (D-15).
- **D-13:** **The Mill pays for itself; Fields pay their flat gold regardless of the Mill's tier.** A Mill upgrade raises only the Mill's own payout and unlocks nothing new.
- **D-14:** **A destroyed economic building loses nothing it accumulated; it only skips that dawn.** As with Houses, a building rebuilt this dawn pays nothing that morning and makes no progress: the Harbor gains no boat, the Mine's decline does not advance, the Shrine keeps its kill count and stays awake (and shoots again once it stands). The Phase 2 crossed-coin marker applies to every rebuilt building.

### Stat-modifier order (META-08)
- **D-15:** **One stacking order for every modifiable stat, built first and tested in isolation.** `final = (base + sum of flat bonuses) × (1 + sum of percent bonuses) × product of multipliers`, the research pattern (`ARCHITECTURE.md` Pattern 3, `PITFALLS.md` Pitfall 6); the order of pickup never matters, only the bucket. Castle abilities (D-02) and the Shrine buff (D-12) are its first users; building upgrades keep their per-tier values as the base the stack applies to. The stack is a pure, headless-testable module with single-modifier and combined-modifier tests, the order is written down in the repository (the planner names the document), integer stats use one documented rounding rule pinned by tests, and the debug overlay shows the computed values. The owner left the design of the stack to Claude; what is locked is that every bonus in this phase and in later phases goes through it.

### Claude's Discretion
- The exact twelve abilities, their numbers and which four sit at which tier (within D-02), and how a locked pick is shown afterwards (for example the castle's label reading "Castle II — Royal Training" and the chosen cards listed on the castle's label).
- The castle's health, cost, arrow and base-income ladder across the four tiers (D-01, D-04), its model or look per tier (Kenney Castle Kit pieces first, logged), and whether the castle's current tier is readable on the map.
- Card size, icon art, the highlight look, whether the first card is pre-highlighted, how a hold with no highlighted card is refused, and how the digit keys hand over between cards and control groups (D-05).
- Plot positions, which edge holds the pond, the pond and boat visuals, and the CC0 models for the five new building types, within D-09 and D-11.
- Economy numbers within D-12; the Shrine's wake radius, threshold, reach, damage and bolt look; how the kill count is tracked (the `enemy_died` event carries the position and the def id, whose max health is the credit).
- The modifier stack's design (D-15): the bucket API, the rounding rule, where the order is documented, what the overlay shows.
- How the bots buy the castle tiers and the new buildings (and which cards they pick, deterministically), how the goldens are regenerated and reported (D-08), and the order of plans. Suggested shape: the stat stack first (pure, tested, documented), then the castle tiers with the gate and the cards on the castle, then the four economic buildings with their plots and the pond, the golden regeneration with its report, then the bot build orders, the balance measurement and the gate.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` — "Phase 5: Castle Center & Economy Depth": goal, mode `mvp`, the four success criteria; "Phase 6: Enemy Roster & Tower Specializations" and "Phase 7: Army Variety & Heroes" for the later users of the card system; "Phase 10" and "Phase 12" for the later users of the modifier stack
- `.planning/REQUIREMENTS.md` — BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08, UI-02; LOOP-04 and LOOP-05 (the free rebuild that pays nothing, D-14); ECON-02 (House income, the base the new curves sit beside); the 2026-10-16 gamepad amendment under `### Input`
- `.planning/PROJECT.md` — core value, constraints, Key Decisions (determinism row, goldens row, gamepad row, PLAT-01 native route)

### Prior decisions
- `.planning/phases/01-foundation-day-loop/01-CONTEXT.md` — D-02 one type per plot, D-04 the sandbox map, D-05 to D-08 the hold, refund, world-space label and denied bump the cards and the gate reuse, D-09 and D-10 economy and tiers
- `.planning/phases/02-night-defense-playtest-gate/02-CONTEXT.md` — D-13 tower behaviour (the Shrine's attack mirrors it), D-14 the crossed-coin marker, D-18 the delegated playtest gate
- `.planning/phases/02-night-defense-playtest-gate/02-RESEARCH.md` — determinism rules DR-1 to DR-10
- `.planning/phases/03-king-combat-troops/03-CONTEXT.md` — D-15 keyboard defaults and the digit keys as control groups (D-05 here takes them over while cards show), D-21 the clear HUD centre, D-26 to D-28 the balance bar and retune method
- `.planning/phases/04-crowd-scale-battles-walls/04-CONTEXT.md` — D-13 to D-15 goldens, the regeneration report and the bot measurement pattern; the Carried Forward list
- `.planning/phases/04-crowd-scale-battles-walls/04-BALANCE-REPORT.md` and `04-PLAYTEST-GATE.md` — the current counts, the bots' win rates and the owner's accepted assumptions
- `.planning/STATE.md` — accumulated decisions; the META-08 note (the modifier order lands here with the first buffs); the Phase 4 native-port decisions (04-14 to 04-27)

### Research
- `.planning/research/FEATURES.md` §"Economy" (the income table: Mine, Mill, Field, Harbour, Shrine numbers and curve shapes; the upgrade cost pattern and the castle gate), §"Buildings" (Castle Center: three tiers in Thronefall, choose-1-of-4 ability picks, the candidate abilities; the branching-choice throughline), §"UI/UX" (branching-choice cards as icon plus text), the feature table rows on income curves and the Mill-gates-Fields dependency, and the note that branching choices are one shared system
- `.planning/research/ARCHITECTURE.md` — Pattern 2 (data-driven definitions), Pattern 3 (additive-then-multiplicative stat modifier stack, D-15), Pattern 7 (intents), the UI/HUD layer row (upgrade choice cards)
- `.planning/research/PITFALLS.md` — Pitfall 6 (stat modifier stacking bugs; the bucket design and the test discipline D-15 follows), Pitfall 1 (trade-off tension), Pitfall 14 (tuning without data)

### Assets
- `ASSETS.md` and `assets/attribution.json` — the attribution log every new CC0 asset (five building models, the pond and boats, the card icons) must follow

No external specs or ADRs exist beyond these.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `simulation/defs/building_def.gd`, `building_tier_def.gd`, `build_spot_def.gd`: the building type, its linear tier ladder (`cost`, `dawn_income`, `max_health`, attack and squad fields, `effect_line()`) and the one-type-per-plot schema. The castle tiers, the per-tier requirement (D-03), the branching choice per tier (D-02) and the new income curves extend these.
- `simulation/buildings/building_system.gd` and `building_instance.gd`: the per-plot instance (tier, health, `destroyed`, `rebuilt_this_dawn`), `apply_next_tier`, `dawn_income_by_spot()` (pure, in MapConfig order, skips destroyed and rebuilt-this-dawn), `rebuild_destroyed`, `repair_standing`, `clear_rebuilt_marks`. `BuildingSystem` is at the gdlint public-method cap, so the Mine's decline counter, the Harbor's boats and the Shrine's kill count belong in a sibling economy-state system the planner names.
- `simulation/castle/castle_state.gd` and `simulation/night/castle_attack.gd`: the castle's health (from `MapConfig.castle_max_health`), `damage`, `repair`, and its arrow read from `MapConfig.castle_attack_*`. The castle is not a `BuildingSystem` plot today; D-01 makes it an upgradeable building (a castle spot in `BuildingSystem`, or `CastleState` reading its tier, the planner decides) and D-04 moves the arrow and base-income numbers per tier.
- `simulation/economy/economy.gd`: the gold ledger (`grant`, `try_spend`); `simulation/run/run_manager.gd` `_enter_dawn` and `_apply_dawn_payout` (`dawn_income_by_spot()` plus `base_dawn_income` under `MapConfig.CASTLE_PAYOUT_KEY`, one `dawn_payout(total, per_spot)` event); `ui/hud/dawn_payout_vfx.gd` and `dawn_no_income_marker.gd`: the coin flight and the crossed-coin marker (D-14).
- `simulation/commands/command_processor.gd` with `build_intent.gd`, `activate_ability_intent.gd`, `squad_order_intent.gd`: the single validated mutation gate; `validate_build` check order NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD gains the castle-tier and Field-lock requirement (D-03, D-10); rejections are returned reasons announced on `command_rejected`, never `push_error`. The choice id rides an intent (D-05).
- `input/build_hold_controller.gd`: the edge-triggered hold with the tuned coin curve and the free cancel; the card highlight (D-05) sits beside it, and the hold refuses to start without a highlighted card at a branching tier.
- `ui/world/spot_label.gd` and `spot_label_model.gd`: the world-space label (`describe()` returns title, cost, paid, effect, affordable, max_tier, status_line) the card row (D-06) extends with the "Needs Castle II" and "Needs a Mill" status lines (D-03, D-10).
- `simulation/night/night_sim.gd`: the fixed night step order (spawn, nav rebuild, king, squads, towers, castle, enemies, hits, dead); the Shrine's attack gets its slot beside the towers and the castle; `simulation/night/pending_hits.gd` carries its bolt; `simulation/night/tower_system.gd` is the attack precedent; `EnemySystem.nearest_living` (native-backed) answers the Shrine's target query.
- `simulation/events/sim_events.gd`: `dawn_payout`, `building_built`, `building_destroyed`, `buildings_rebuilt`, `enemy_died(enemy_id, def_id, pos, killer_kind)` (the Shrine's kill credit), `command_rejected`; every new signal must also be listed in `tests/support/sim_signals.gd` and `SimRecorder.HANDLED` in the same task.
- `simulation/defs/map_config.gd` `validate()`: reports bad data instead of arming it; grows the castle tiers, the requirement fields, the new building fields and the pond.
- `presentation/buildings/building_view_catalog.tres`, `building_views.gd`, `presentation/buildings/models/castle_center.tscn`: one model per building id, the castle's model; the five new types and the castle's per-tier look plug in here.
- `ui/overlay/debug_overlay.gd` `register_section`: the computed stat values (D-15), the Shrine counts and the castle tier join it.
- `tools/replay/` (`playtest_bot.gd`, `playtest_strategies.gd`, `balance_report.gd`, `replay_cli.gd`, `replay_scenarios.gd`) and `tests/golden/` (`smoke.json`, `army.json`, `walls.json`, the `full_idle` digest in CI): the bots, the report and the goldens of D-08.
- `assets/third_party/kenney_castle_kit`, `kenney_fantasy_town_kit`: logged CC0 packs, first choice for the new buildings and the castle's tiers.

### Established Patterns
- Simulation code is `RefCounted`, positions are `Vector2` on XZ, time is integer ticks, randomness only through the seeded night stream; ids only grow; iteration in id or MapConfig order.
- Every number is data; contract tests pin shipped values to the decisions; `MapConfig.validate()` reports bad data.
- Rejected operations return reason values and announce `command_rejected`; display-only effects lag the simulation and never gate it.
- gdlint caps: 20 public methods per class (`BuildingSystem`, `UnitSystem`, `KingState`, `EnemySystem` at or near it, so new writers go in new files), 1000 lines per file, 20 tests per script, 100-character lines, static typing everywhere.
- The native GDExtension (Phase 4) owns the enemy step, separation, wall solids, the field, the stuck tracker and the view fills behind unchanged GDScript APIs; GDScript code may call them, and a change to their inputs needs a pin first.
- The goldens hold or are regenerated deliberately with the reason and an outcome report recorded; CI replays smoke, army, full_idle and walls on GCC and MSVC.
- Scripted real-window runs and screenshots are how the agent checks what it cannot see; the owner is asked only for feel.

### Integration Points
- `data/maps/prototype_map.tres`: eight new `BuildSpotDef` entries (D-09), the Field requirements (D-10), the castle's tier data (D-01, D-04), the pond (D-11); `MapConfig.validate()` grows the checks. New `data/buildings/` files: `castle_center.tres` (four tiers with choices), `gold_mine.tres`, `mill.tres`, `field.tres`, `fishing_harbor.tres`, `shrine.tres`; a new `data/` folder for the twelve abilities as resources.
- `RunContext` (the composition root) wires the modifier stack, the castle tiers and the economy-state system; `RunManager` dawn: boats, mine decline and the Shrine's income join `_apply_dawn_payout` through `dawn_income_by_spot()` or a sibling, keeping one `dawn_payout` event.
- `KingState`, `UnitSystem`/`SquadSystem`, `TowerSystem`, `WallSystem`, `BuildingSystem` read their modifiable stats through the stack (D-15) instead of raw def values; `WeaponDef` and `UnitDef` values become bases.
- `presentation/map/map_root.gd` and the view catalog: the five new building views, the castle's tiers, the pond and the boats; `ui/world/`: the card row and the new status lines; `ui/hud/`: nothing new except the digit-key hand-over (D-05).
- `project.godot` Input Map: no new actions needed if the cards reuse `group_1` to `group_4` and `action_build`; a dedicated card action set is the planner's call.
- `.github/workflows/ci.yml`: the regenerated goldens (D-08) replace the pinned `full_idle` digest in the replay step.

</code_context>

<specifics>
## Specific Ideas

- The owner chose four castle tiers over three ("Four tiers, three picks") and wants each tier to strengthen the castle itself (arrow and base income), not only health and the ability.
- The owner delegated the ability set: Claude picks twelve Thronefall-style passives, judged at the UAT.
- Cards: approach, pick with 1 to 4 or the mouse, then the usual hold; a world-space row above the castle; flavour text on the card with the numbers on highlight.
- The goldens may be regenerated once for the new plots; the second-map alternative was rejected.
- Field plots are visible from day 1 and locked until the Mill stands, through the same mechanism as the castle gate.
- Nothing accumulated is ever lost to destruction; a rebuilt building only skips that dawn.
- The owner prefers Claude to check what can be measured with scripted real-window runs and the bots, and to be asked only for feel judgments and decisions.

</specifics>

<deferred>
## Deferred Ideas

- Tower specializations (BLDG-11, Phase 6) and the per-building unit and hero choices (UNIT-01 to UNIT-03, Phase 7) — later users of the card system; this phase keeps the card data and the intent generic (any building tier may carry a choice list), with the castle as the only user.
- Perks and mutators (Phase 10) and research buffs (Phase 12) — later users of the modifier stack; this phase ships the stack with the castle abilities and the Shrine buff as its users.
- Rule-changing abilities (reflect damage as a rule, a free House upgrade at dawn, a second castle arrow) — offered as an option and not chosen; the twelve abilities are stat passives. Magic Armor stays in the candidate list only as far as it can be expressed through the stack and the existing king hit handling.
- Destruction that costs accumulated progress (boats lost, Shrines going dormant) — rejected for this phase; could return as a map gimmick or a mutator.
- A second sandbox map for new buildings — rejected; the prototype map stays the one sandbox.
- A lake that blocks movement — rejected for this phase; water as an obstacle could be a later map's gimmick (Phase 11).
- A UI design contract (`/gsd-ui-phase 5`) for the card look — optional; the plan-phase UI gate does not block, the owner may run it before planning.

</deferred>

---

*Phase: 05-castle-center-economy-depth*
*Context gathered: 2026-10-21*
