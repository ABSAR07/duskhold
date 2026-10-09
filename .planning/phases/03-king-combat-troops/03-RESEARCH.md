# Phase 3: King Combat & Troops - Research

**Researched:** 2026-10-09 (17:07 UTC at start)
**Domain:** Friendly squads, an RTS-style command layer (keyboard, mouse and gamepad), the king's slam and regeneration, and the in-run HUD with device glyphs, all on top of the Phase 2 deterministic fixed-step simulation (Godot 4.7.2 GDScript)
**Confidence:** HIGH on how the existing code must change and on the engine input facts (code read and engine probes run this session). MEDIUM on every balance number, key choice and pad layout (flagged ASSUMED; the bots and the owner settle them).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried Forward (locked before this discussion — do not re-litigate)**
- Stack, the simulation / presentation / data split, `.tres` content referenced by id, the command/intent layer, the event bus, CC0-only assets with the attribution log, as recorded in `01-CONTEXT.md`.
- One building type per fixed plot (Phase 1 D-02), linear tiers (D-10), the tight starting economy (D-09), no gold from kills. Every tunable number lives in `.tres` data, never in code.
- Ride-up-and-hold building and upgrading, exactly as validated in the Phase 1 and Phase 2 sign-offs. The reversal of the mouse decision (D-11 below) touches unit commands only; building never uses the mouse and there are no mouse-aimed king attacks.
- The deterministic fixed-step simulation (`SimClock` 1/30 s, seeded RNG, integer event recorder, golden replays, bot playtests) and the rule that nothing under `simulation/` reads wall-clock time, the OS or the time scale (Phase 2 DR-1 to DR-10). Player commands enter the simulation as intents stamped on ticks, like `BuildIntent` and `StartNightIntent` today, so a recorded run replays identically.
- The king's shipped numbers (50 hp, passive 5 damage every 0.7 s at 3 m, walk 7.5 m/s, sprint 12 m/s) and the knockout and respawn rules (Phase 2 D-01 to D-06: countdown 6 s + 4 s per knockout, capped at 15 s, no cost beyond the time, full health on respawn). Phase 2 D-05 ("health returns only at dawn or through a respawn") is superseded by D-20 below, as Phase 2 anticipated.
- Enemies attack the nearest thing in their path, commit to a target with staggered rescans, and are pushed apart when they overlap (Phase 2 D-11 and the `EnemySystem` pattern). Squads reuse the same targeting discipline.
- Hurt-only health bars, the results screen, the fast-forward toggle and the castle attack from the Phase 2 gate stay as they are.

**Squads & Military Buildings**
- **D-01:** Two new building types: the Barracks produces the melee squad, the Archery Range the ranged squad. Each has three linear tiers and the squad cap grows 4 → 8 → 14. The owner's rule for the top tier: tier 3's increase from tier 2 is proportionally smaller than tier 1 to tier 2 (+75 % against +100 %) but larger in magnitude (+6 units against +4), so the last upgrade is still clearly the strongest.
- **D-02:** Costs follow Thronefall's doubling line, 4 → 8 → 16 gold. The first squad is a real day-1 trade-off against two Houses. The exact numbers are data and may move in the bot retune (D-08).
- **D-03:** The two military plots are added to the prototype map, one per building, near the castle and inside the tower ring. The eight existing plots and their balance data are not touched. The map has ten plots afterwards. — Reversibility: costly — the prototype map is the permanent test and replay sandbox (Phase 1 D-04); changing its plots regenerates the golden replays and shifts every balance number measured on it.
- **D-04:** A squad without orders guards its post. Units idle at their building, engage enemies that come inside a short guard radius, commit to their target the way enemies do (Pitfall 5), and walk back to the post once nothing is near. By day they stand at the post. Hold, rally, move and patrol (D-09) change where "the post" is for the rest of the run (D-14).
- **D-05:** Dead units trickle back during the night at one unit per 10 s at tier 1, 7 s at tier 2 and 4 s at tier 3, spawning at the building; at dawn every squad is instantly back to full (UNIT-07). A squad that is following or holding away from its post gets its replacements at the building, and they walk to the squad.
- **D-06:** The classic pair. Melee units are the sturdier ones and stand in the enemy's path, a buffer in front of buildings; archers are fragile, outrange the melee grunt and fire visible arrows like the towers do. Counters and special roles wait for Phase 6 (UNIT-08).
- **D-07:** A single unit is weak: about a fifth of the king's health and damage. A full tier-1 squad roughly matches the king, so the king stays the hero and squads are the wall.
- **D-08:** The night counts are retuned in this phase with the balance bots. With squads in play the authored counts rise until the balanced bot still wins 7 or 8 of 10 seeds (the Phase 2 bar). The bots measure; the owner judges feel in the UAT, as in Phase 2 D-18.

**Unit Commands (squad control layer)**
- **D-09:** Commands are given to whole squads, never to single units. The verbs: follow the king; hold (freeze where they stand, fight inside the guard radius of that spot, return to it after a fight); rally to the king (walk to where the king stands now and hold there); move (walk to a ground point ignoring enemies on the way, then resume the autonomous stance of D-04 at that spot, without holding unless hold is pressed or queued); attack-move (walk to a ground point, engaging anything met on the way); patrol (walk a path back and forth, engage what comes close, resume the path when it is dead). Return-to-post is the stance a squad has before any order. Shift queues commands, so "move here, then hold" is one gesture.
- **D-10:** Custom control groups, Age of Empires style. On keyboard and mouse, left click selects a squad, dragging a box selects every squad it touches, Ctrl adds to the selection, Ctrl + 0 to 9 stores the current selection as a group and the bare number recalls it, Tab cycles through the squads. On the gamepad the player cycles through the squads and assigns them to a group with a modifier; there is no pointer-style selection on the pad. Select-all and select-one-type remain available as built-in selections, so UNIT-06 ("all units or one unit type") holds inside the richer scheme. The whole system ships in this phase with the two squads the map has.
- **D-11:** The mouse returns to runs for unit commands. This reverses the 2026-09-28 decision "mouse for menus only" (PROJECT.md, REQUIREMENTS.md INPT-03, the dropped "mouse unit commands" row). The owner: "mouse use is kind of a necessity now i realize in hindsight." The mouse selects squads, stores groups, and supplies the ground point of move, attack-move and patrol. Building stays hold-only and the king's attacks stay automatic. — Reversibility: costly — it changes a project-level constraint, the Out of Scope table, INPT-01 and INPT-03, and every later menu, prompt and rebinding decision assumes a pointer exists during a run.
- **D-12:** Gamepad parity through cycling and a cursor. The command verbs sit on the D-pad (the owner's choice) with the remaining verbs on chords the planner picks; holding a command button that needs a ground point shows a right-stick ground cursor, released to confirm. Switching device mid-run keeps the current selection and groups.
- **D-13:** The camera stays locked on the king while the mouse is in use. Mouse points and box selections are projected onto the visible ground; anything off-screen needs the king to ride closer. The Phase 1 follow camera is unchanged.
- **D-14:** Stances persist across dawn. A held, patrolling or following squad stays that way day after day until the player changes it; dawn restores numbers only. Replacements (D-05) join the squad wherever it is.
- **D-15:** Keyboard defaults are the classic RTS letters: F follow, H hold, R rally, A attack-move, P patrol, Tab cycle the selection, Ctrl + click add to the selection, Ctrl + 0..9 store a group, 0..9 recall it, right click move. Fast-forward moves off F to a key the planner picks. Everything stays in the Input Map with both device bindings, rebindable in Phase 13.
- **D-16:** A selected squad shows a coloured ground ring under each of its units and a highlighted slot in the HUD group status, with the stored control-group number on the slot.

**King Weapon, Active Ability & Regeneration**
- **D-17:** The king starts with a sword: the shipped melee passive stays exactly as signed off, and the active ability is a slam, a circular strike around the king that hits every enemy within a few metres. It needs no aiming and reads the same on both devices.
- **D-18:** Weapons are data from now on. A `WeaponDef` resource holds the passive numbers (range, damage, interval) and the active's (radius, damage, cooldown); the king reads its equipped weapon from it. One weapon ships; the roster and the loadout screen come in the meta phases.
- **D-19:** The slam's cooldown is about 9 s and the ability can be used at any time, by day too (it simply hits nothing), so the timing can be learned. The HUD shows a radial fill and a ready flash (D-22).
- **D-20:** Health regenerates Thronefall-style: about 1 s after the last hit taken, 10 % of max health per second until full, by day and by night. Both values are data. Knockout and respawn (Phase 2 D-01 to D-06) are unchanged; a respawn still returns full health.

**HUD & Device Prompts**
- **D-21:** Corners, centre kept clear. Gold top-left (as today), "Night N of 8" top-centre by day (the night banner keeps its place at night), king health and the ability bottom-left, unit group slots bottom-centre, the start-night prompt where it is. Nothing sits in the middle of the play area.
- **D-22:** King health is a horizontal bar with the number ("38 / 50") beside a sword icon that fills clockwise as the cooldown runs and flashes when ready. Matches the hurt-only bars in the world.
- **D-23:** One group slot per squad: unit icon, "alive / max", a small stance glyph (post, follow, hold, patrol, attack-move), the stored control-group number, a highlight when selected, and a thin fill that shows a replacement on its way.
- **D-24:** Prompts use button and key glyphs from a CC0 prompt pack (Kenney Input Prompts, recorded in the attribution log) instead of the text names. Any press or stick movement on the other device switches every prompt at once; mouse input counts as keyboard. This supersedes the Phase 1 "Known limitation" of Xbox-only text labels for the actions that get glyphs.

**Scope Amendment (owner decision 2026-10-09)**
- **D-25:** Phase 3 scope extends beyond the written UNIT-05 and UNIT-06. Control groups, move, rally, attack-move, patrol, Shift-queued commands and mouse selection all ship in this phase. The owner confirmed the amendment of ROADMAP success criterion 2 and REQUIREMENTS.md (UNIT-05 and UNIT-06 reworded, new UNIT-09 and UNIT-10, INPT-01 and INPT-03 reworded) alongside this context, so verification checks for them.

### Claude's Discretion
- The guard radius, how a squad spreads around its post, its walking formation and the separation rule between friendly units; how squads path around buildings and each other (the straight-line step with push-apart that enemies use is enough until Phase 4's flow field).
- Unit health, damage, range, speed, arrow speed and squad walking speed, within D-06, D-07 and D-08; whether units fight by day if an enemy somehow remains.
- How a patrol path is set with the mouse (for example right-click endpoints while P is held) and on the pad, and how it is drawn.
- Which keys and chords on the pad carry rally, attack-move, patrol, select-all and select-one-type; the new fast-forward key; how groups are assigned by cycling on the pad; the cycling order.
- The slam's radius, damage, animation and sound hook; whether it knocks enemies back.
- How device switching is detected (last `InputEvent` class) and debounced, and the glyph mapping for keyboard keys and Xbox-style pad buttons; non-Xbox pad glyphs can wait.
- HUD sizes, fonts and colours, within D-21 to D-24, verified with night screenshots.
- Which CC0 models stand in for the two unit types (the Kenney Mini Characters pack already in the repo is the first choice) and the arrow, logged in `ASSETS.md`.
- How the balance bots use the command layer (at least follow and hold) and how the determinism harness records mouse points (quantise them to the simulation's integer grid or record the intent, never raw mouse events).
- The order of work. A suggested shape: squads and military buildings first on the fixed step, then the command layer with keyboard and mouse, then gamepad parity and prompts, then the HUD, then the retune and the gate.

### Deferred Ideas (OUT OF SCOPE)
- Unit counters and special roles (UNIT-08), the Hero's Quarter and the 1-of-4 unit choice per military building — Phase 6 and the content phases.
- More weapons, the loadout screen, perks and mutators — the meta phases; `WeaponDef` (D-18) is the groundwork.
- Walls, flow-field pathing, the 200-unit stress test and the MultiMesh switch — Phase 4.
- Glyphs for non-Xbox gamepads and the rebinding UI — Phase 13.
- Camera edge-scroll or drag while commanding — rejected for now (D-13); revisit only if the owner finds the locked camera limiting in the UAT.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KING-04 | Equipped weapon's active ability with a visible cooldown | `WeaponDef` slam fields; `ActivateAbilityIntent` -> `KingState` countdown counter in ticks, resolved through `PendingHits`; works by day (Pattern 5); HUD radial widget reads `ability_cooldown_ratio()` |
| KING-05 | King health regenerates after a short period without damage | `KingDef.regen_delay_seconds` / `regen_fraction_per_second`, per-step counters decremented on every phase (Pattern 5), `king_healed` event; opt-in default 0 keeps the smoke golden |
| UNIT-04 | Units fight autonomously near their post, committing to targets | `SquadSystem` guard radius + committed target reusing `EnemySystem.is_rescan_tick` and `TargetQuery`; enemies gain `KIND_UNIT` targets (Pattern 2, 3) |
| UNIT-05 | Order selected squads to hold position; held squad fights near the spot and returns | Order state machine, hold anchor = squad centroid at the apply tick (Pattern 4) |
| UNIT-06 | Follow the king for all squads, one unit type, or the selection | Follow is a squad order; "all" and "one type" are selections built by `SelectionModel` (select-all, double-click same type) |
| UNIT-07 | Killed units trickle back at night, everything restored at dawn | Per-squad replacement countdown (10/7/4 s per tier, data on `BuildingTierDef`), `restore_for_dawn()` called from `RunManager._enter_dawn` |
| UNIT-09 | Select squads (click, box, Ctrl, pad cycling), store/recall groups, ground ring + HUD slot | `SelectionModel` (pure, outside `simulation/`), `SelectionMath`, ground pick via `Plane.intersects_ray`, MultiMesh rings |
| UNIT-10 | Move, rally, attack-move, patrol, Shift queue, mouse or right-stick cursor, stances persist across dawn | `SquadOrderIntent` with `Vector2i` centimetre points, `GroundCursor` model for the pad, stance state outlives `begin_night`/dawn |
| INPT-01 | Whole game on keyboard and mouse | New Input Map actions, mouse events handled in `_unhandled_input`, scripted via `Input.parse_input_event` |
| INPT-02 | Whole game on a gamepad, switching at any time, prompts follow the device | `LastDeviceTracker` (pure model + node), glyph resolver, one `device_changed` signal |
| UI-01 | HUD: gold, night N of total, king health, ability cooldown, unit group status | 03-UI-SPEC.md layout; Kenney Input Prompts pack facts below |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Extracted from `./.claude/CLAUDE.md` (read this session). Treat as locked.

- **Stack:** Godot 4.7.2-stable, GDScript (standard build), GUT 9.7.1, gdtoolkit `gdformat`/`gdlint`; static typing everywhere, and the project turns an untyped declaration into a compile error [VERIFIED: project.godot:19 `gdscript/warnings/untyped_declaration=2`].
- **Text-first, headless-first:** scenes and resources are text `.tscn`/`.tres`; everything the agent verifies runs from `godot --headless` or a scripted real-window run.
- **Assets:** CC0 only, attribution log (`ASSETS.md` + `assets/attribution.json`) maintained; no Thronefall names, art or assets.
- **Platform/input:** Windows PC; keyboard and gamepad gameplay. The "mouse for menus only" line in CLAUDE.md is superseded for unit commands by D-11 (owner decision 2026-10-09, REQUIREMENTS.md amended). Building never uses the mouse.
- **Performance:** GTX 970 class, 60 fps; Phase 3 has tens of units, but unit data must stay in a manager so Phase 4's MultiMesh switch does not change the simulation.
- **Workflow:** file-changing work goes through a GSD command; the researcher writes only RESEARCH.md. No project skills exist.
- **Lint caps that bite:** `max-line-length: 100`, `max-public-methods: 20` (this is the "20 test functions per script" cap), `max-returns: 6`, `function-arguments-number: 10` [VERIFIED: .gdlintrc:34,41-43].

## Summary

Phase 3 is the first phase that adds a second team to the deterministic night. The pattern is already proven by `EnemySystem`: a manager of `RefCounted` records addressed by ids that only grow, `Vector2` XZ positions, ascending-id iteration, decide-then-resolve through `PendingHits`, committed targets with staggered rescans. A `SquadSystem` (units grouped in one squad per military building) follows that pattern one-for-one, and enemies learn to target units exactly the way they already target buildings (a new `KIND_UNIT`). The two things that are genuinely new for the simulation are that squads and the king's timers must advance **every phase** (today only `NightSim.step` runs, and only in NIGHT), and that player commands carry **ground points**, which enter the simulation only as `Vector2i` centimetres inside a `SquadOrderIntent`, never as raw mouse events.

The input work is mostly Godot behaviour that was probed this session on 4.7.2 and is now certain: `Input.action_press` produces no `InputEvent` (so event-driven handlers never see scripted presses, while polling handlers do); `Input.parse_input_event` drives `_unhandled_input` and also updates action state; a bare-digit action also matches Ctrl+digit unless `exact_match` is passed, so the store/recall design uses one modifier action plus ten digit actions; a STOP `Panel` consumes a click before `_unhandled_input` while PASS containers and IGNORE controls let it through; and with the UI-SPEC's required `canvas_items` stretch, mouse positions, `get_visible_rect()`, `Camera3D.unproject_position` and `project_ray_*` all share the 1280x720 base space, so ray picks and HUD overlays agree at 1920x1080 and 16:10. One trap comes with that same stretch change: in the 64 px headless test window `get_visible_rect()` becomes 1280x1280, so tests written around a tiny viewport must be re-checked right after the project setting lands.

The Kenney Input Prompts v1.5 pack was downloaded and inspected: it is CC0, zip sha256 `ac2fcf59...`, and its "Default" tiles are **white glyphs on transparent backgrounds**, so every glyph needs a dark plate on the lit 3D scene (the UI-SPEC's "filled" wording does not hold for the Default folder; coloured badges exist only for the `xbox_button_color_*` tiles). The smoke golden can be preserved byte-for-byte by making every new rule opt-in by data default (regeneration 0, no military spots), and a new `army` replay scenario with its own golden carries the new rules.

**Primary recommendation:** Build in this order: (1) data schema + `MapConfig.validate()` + `WeaponDef` migration with the smoke golden unchanged, (2) `SquadSystem` on the fixed step with enemy targeting of units and the day-phase step, (3) intents, `SelectionModel` and the mouse/keyboard controllers, (4) pad cursor, `LastDeviceTracker` and glyphs, (5) HUD widgets, (6) bots + retune + `army` golden, (7) screenshot scenarios and the owner gate.

## Architectural Responsibility Map

This is a single-process desktop game; the "tiers" are the project's own layers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Unit and squad state, orders, guard/commit targeting, replacement timers, dawn restore | Simulation (`simulation/squads/`) | — | Must be bit-reproducible; owns ids and positions |
| Enemies targeting units, unit hits | Simulation (`EnemySystem`, `PendingHits`, `NightSim._resolve_hits`) | — | Same decide-then-resolve queue as every other attack |
| King slam, cooldown, regeneration | Simulation (`KingState`) | Data (`WeaponDef`, `KingDef`) | Rules are sim; numbers are data |
| Ground point picking (ray vs ground plane), drag-box maths | Input / presentation (`input/`) | — | Needs the `Camera3D`; produces `Vector2i` cm for the intent and nothing else |
| Selection, control groups, cycling order | Input (`SelectionModel`, pure `RefCounted`) | HUD (reads it) | UI state; never affects results, intents carry explicit squad ids |
| Command intents (follow, hold, rally, move, attack-move, patrol, ability) | Simulation (`CommandProcessor`) | Input (builds them) | Single validated mutation gate, rejections returned as values |
| Device detection and prompt glyphs | Input (`LastDeviceTracker`) + UI (`GlyphResolver`) | Assets (Kenney tiles) | Pure model with an injected clock, thin node on top |
| Unit puppets, arrows, selection rings, pings, patrol lines | Presentation (`presentation/units/`, `presentation/vfx/`) | — | Read sim, interpolate by `ctx.alpha()` |
| HUD (king widget, squad strip, hints, toast, day counter) | UI (`ui/hud/`) | — | Polls sim getters, listens to events |
| Replay, bots, balance report | Tooling (`tools/replay/`) | Simulation | Headless; excluded from the export |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine (standard) | 4.7.2-stable | Engine, headless CLI | Pinned; every probe in this document printed `VERSION 4.7.2-stable (official)` [VERIFIED: probe this session] |
| GDScript, static typing | 4.7 built-in | All new code | Project constraint |
| GUT | 9.7.1 | Unit/integration/e2e tests | Existing; config in `.gutconfig.json` (dirs unit, integration, e2e; JUnit to `build/test-results/gut-junit.xml`) [VERIFIED: .gutconfig.json] |
| gdtoolkit | 4.5.0 | `gdformat`/`gdlint` | Pinned in `tools/requirements-lint.txt`; run through `bash tools/lint.sh` |

### Supporting (engine built-ins; no addons)
| Facility | Purpose | When to Use |
|----------|---------|-------------|
| `Camera3D.project_ray_origin` / `project_ray_normal` + `Plane.intersects_ray` | Mouse and pad-cursor ground point | `Plane(Vector3.UP, 0.0).intersects_ray(origin, dir)` returns a `Variant`, `null` on a miss [CITED: docs.godotengine.org/en/stable/classes/class_plane.html] |
| `Camera3D.unproject_position` | Box select and click select against projected unit points; ring/marker placement | Same coordinate space as the rays (probe below) |
| `MultiMeshInstance3D` / `MultiMesh` | Ground rings under selected units (one draw call, matches Phase 4) | Set `transform_format` and `use_colors` **before** `instance_count`; `use_colors` "Can only be set when instance_count is 0 or less" [CITED: docs.godotengine.org/en/stable/classes/class_multimesh.html] |
| `Input.parse_input_event` | Scripted mouse/pad events in tests and real-window runs | "Feeds an InputEvent to the game ... Also generates Node._input() calls" [CITED: docs.godotengine.org/en/stable/classes/class_input.html] |
| `InputEventMouseButton.double_click` | Double-click selects every squad of the same unit type | Serialised field `"double_click":false` is part of the event [VERIFIED: var_to_str probe] |
| `TextureProgressBar` (`FILL_CLOCKWISE`), `ProgressBar`, `TextureRect`, `PanelContainer` | HUD per 03-UI-SPEC.md | As specified there |

### Assets (not packages)
| Asset | Version | Purpose | Notes |
|-------|---------|---------|-------|
| Kenney Input Prompts | 1.5 (License.txt says 1.5A, creation date 11-07-2026) | Key, mouse and Xbox glyph tiles | CC0; see "Kenney Input Prompts facts" |
| Kenney Mini Characters 1.0 (already in repo) | 1.0 | Footman and archer puppets | Only `character-male-b` is kept today; the zip holds `character-male-a..f` and `character-female-a..f` GLBs with animations |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One `SquadOrderIntent` class with a verb constant | One intent class per verb (`HoldPositionIntent`, `FollowKingIntent` as ARCHITECTURE.md names them) | Per-verb classes make `CommandProcessor.submit` a long `if` chain that hits `max-returns: 6`; one class + `match` on the verb keeps it flat. Either works; pick one and keep `submit` dispatching through a table |
| 20 actions (`group_store_N`, `group_recall_N`) | 10 digit actions + one `selection_modifier` action (Ctrl) | 20 actions trip the exact-match trap (below) and double the rebinding surface in Phase 13 |
| Group state in the simulation | Group state in `SelectionModel` (presentation/input) | Groups never change results; intents carry explicit squad ids, so replays are unaffected |
| Sim-owned selection | Not needed | Selection is UI state |

**Installation:** none. No package is installed. The Kenney pack is downloaded with `curl --fail` (no redirects), exactly as the earlier Kenney packs were.

**Version verification:** Engine and GUT versions confirmed by running them (probes). Kenney pack: page https://kenney.nl/assets/input-prompts lists version 1.5, licence "Creative Commons CC0", tile size 64 x 64, download `https://kenney.nl/media/pages/assets/input-prompts/8de120163f-1783763952/kenney_input-prompts_1.5.zip` [CITED: kenney.nl/assets/input-prompts]; downloaded this session: HTTP 200, 0 redirects, 5,070,075 bytes, sha256 `ac2fcf599080b0f3ba2d174c9474db6df1a0e96ff0662580e2da79a122ab78a1` [VERIFIED: curl + sha256sum this session].

## Package Legitimacy Audit

No npm, PyPI or crates packages are installed in this phase (engine built-ins and the existing GUT addon only), so the `package-legitimacy` gate has nothing to check. The one new third-party item is a CC0 asset pack, audited below under the project's own asset rules.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | — |

| Asset | Source | Licence evidence | Hash | Disposition |
|-------|--------|------------------|------|-------------|
| Kenney Input Prompts 1.5 | kenney.nl/assets/input-prompts (author's own page) | Page: "Creative Commons CC0"; the zip's own `License.txt` reads "License: (Creative Commons Zero, CC0)" [VERIFIED: extracted this session] | `ac2fcf599080b0f3ba2d174c9474db6df1a0e96ff0662580e2da79a122ab78a1` | Approved; the owner approved Kenney Input Prompts in the UI-SPEC (Registry Safety row). Keep only the tiles the resolver needs, plus `License.txt`. Do **not** copy the `.url` files |
| Kenney Mini Characters 1.0 (more GLBs) | already logged entry `kenney-mini-characters` | Existing entry | Re-downloaded this session: sha256 `9e1d48e6d7b8479ebbe84df71eb5bd8e1b3f0da546dea641890dccc8a02d0999`, 2,403,059 bytes, identical to the logged value [VERIFIED] | Approved. Adding GLBs only extends the entry's `notes` ("Kept files") and ASSETS.md composition note; no new entry |

**Packages removed due to SLOP verdict:** none
**Packages flagged SUS:** none

## Architecture Patterns

### System Architecture Diagram

```
 REAL GAME (frame loop)                                  HEADLESS / CI / BOTS
 ----------------------                                  --------------------
 mouse / keys / pad events                               PlaytestBot.think(ctx)  (+ new army commands)
   |                                                       |  SquadOrderIntent / ActivateAbilityIntent /
   v                                                       |  BuildIntent / StartNightIntent, king position
 LastDeviceTracker (_input)  -> device_changed -> all prompts
   |
   +-> SelectionController (_unhandled_input: click, box, Ctrl, double-click, right-click)
   +-> CommandKeyController (polls Input actions: follow, hold, rally, point verbs, groups, cycle)
   +-> PadCursorController (right stick -> screen cursor -> ground ray)
   |        ground pick: Camera3D.project_ray_* + Plane(UP,0).intersects_ray  -> Vector2 metres
   |        quantise: Vector2i centimetres      (the ONLY form a point takes in the sim)
   v                                                       |
 SelectionModel (selection, 10 groups; pure)               |
   |  explicit squad ids                                   |
   v                                                       v
 CommandProcessor.submit(intent)  ------------- the single validated mutation gate -------------
   |  accepted -> SquadSystem.apply_order / KingState.try_activate_ability ;  rejected -> reason value
   v
 RunContext.step()   (fixed 1/30 s, every phase)
   0. king.tick_timers()            regen delay/accumulator, ability cooldown   (DAY, NIGHT, DAWN)
   1. NIGHT:  NightSim.step         spawn -> king (passive, slam resolve) -> SQUADS -> towers -> castle
                                    -> enemies (may target units) -> resolve hits (unit hits too)
                                    -> remove dead enemies, remove dead units
      else :  NightSim.step_day     squads move/guard/top-up, slam resolve (hits nothing)
   2. RunManager.tick               NIGHT->DAWN: rebuild, repair, heal king, squads.restore_for_dawn, payout
   3. tick_count += 1
   |
 SimEvents (new signals) --> views (UnitViews, arrows, rings, pings), HUD, SimRecorder digest, RunStats
```

Primary trace (a move order): right-click -> `SelectionController` builds `SquadOrderIntent(squad_ids, MOVE, [Vector2i cm], queued=Shift)` -> `CommandProcessor` validates (squads exist, point inside the ground extent, queue below the cap) -> `SquadSystem` appends/replaces the squad's order queue and emits `squad_ordered` -> each step the squad's units walk to their formation slots around the target, then the squad's post becomes that point (D-09, D-14).

### Recommended Project Structure
```
simulation/
  squads/
    unit_system.gd        # unit records, ids that only grow, positions, damage, separation (id-based API)
    squad.gd              # Squad record: spot_id, stance, order queue, anchor, replacement countdown
    squad_order.gd        # Order record + verb constants
    squad_orders.gd       # pure functions that advance an order / pick the next one
    squad_formation.gd    # pure slot offsets (grid, no sin/cos)
    squad_system.gd       # orchestrator: sync with buildings, step, intents, dawn restore
  commands/
    squad_order_intent.gd, activate_ability_intent.gd      (new)
    command_processor.gd  (change: dispatch table, new reasons)
  defs/
    unit_def.gd, weapon_def.gd                             (new)
    building_def.gd (+unit_id), building_tier_def.gd (+squad_size, squad_respawn_seconds)
    king_def.gd (+weapon, regen_*), map_config.gd (+units, ground_half_extent, validate)
  king/king_state.gd      (change: slam, cooldown, regeneration)
  night/enemy_system.gd, night_sim.gd, pending_hits.gd (change: KIND_UNIT)
input/
  selection_model.gd, selection_math.gd, ground_pick.gd, ground_cursor.gd   (pure, unit-testable)
  last_device_tracker.gd (+ pure DeviceModel), selection_controller.gd, command_key_controller.gd,
  pad_cursor_controller.gd, ability_controller.gd
presentation/units/unit_views.gd, selection_rings.gd, order_markers.gd, slam_vfx.gd
ui/hud/ hud_root.gd, king_widget.gd, squad_strip.gd, squad_slot.gd, command_hints.gd, toast.gd,
        day_counter.gd, glyph_resolver.gd, prompt_glyph.gd, stance_glyph.gd
data/units/footman.tres, archer.tres; data/buildings/barracks.tres, archery_range.tres;
data/king/sword.tres; assets/third_party/kenney_input_prompts/
tools/replay/ (playtest_bot.gd, playtest_strategies.gd, replay_scenarios.gd + army scenario), tests/golden/army.json
```

### Pattern 1: Squad data layout that Phase 4 will not have to change
**What:** `UnitSystem` mirrors `EnemySystem` (read this session): `_records: Dictionary` id -> `Record`, `_order: Array[int]` ascending, `_next_id` only grows, `position`/`previous` `Vector2`, an id-based read API (`ids()`, `position_of(id)`, `previous_position_of(id)`, `health_of(id)`, `def_of(id)`, `squad_of(id)`, `is_alive(id)`). A squad is **not** an id-counter object: it is keyed by the military building's spot id (`barracks_1`), which is stable for the whole run, one per military plot, created the first time the building exists and never deleted (a fallen building keeps its squad; the dawn rebuild restores it). This resolves the UI-SPEC's unresolved "control groups after a squad is lost or added" row (Open Question 2).
**Sync with buildings by polling, not by event:** at the start of `SquadSystem.step`, for each military spot in MapConfig order compare `buildings.current_tier(spot)` with the squad's recorded tier; a new tier creates the squad or raises its cap. Pull-based sync is deterministic, needs no listener inside the simulation (events stay one-way, DR-11) and also covers dawn rebuilds.
**Slots:** each unit takes the lowest free formation slot index at spawn, so a death leaves a hole that the replacement fills; units never re-rank when a neighbour dies (no jitter).
**Phase 4:** swap `Record` storage for packed arrays and `_order.erase` for swap-remove behind the same id API; combat rules and tests stay.

### Pattern 2: Enemies target units like they target buildings
`EnemySystem._choose_target` priority today (read this session): keep a king target inside leash; the king when up and inside aggro; keep any other valid target; else the structure with the nearest edge inside aggro (buildings in spot order, castle last, strictly smaller edge needed). Add `PendingHits.KIND_UNIT := &"unit"` and, in `_pick_nearest_structure`, scan living units (ascending id) **before** the buildings so equal edge distances go to the unit (this is what makes melee units the buffer, D-06). `_target_valid` gets a unit branch (alive and edge within `leash_range`), `_advance_and_strike` a unit goal (centre = unit position, radius = `UnitDef.radius`). `EnemySystem.step` takes a trailing optional `units: UnitSystem = null`, so every existing call site and test stays valid. `NightSim._resolve_hits` gets `KIND_UNIT -> _squads.damage_unit(id, amount)`; a hit on a dead unit drops silently (the established rule).
Sites that switch on a kind and must learn `KIND_UNIT` [VERIFIED: grep this session]: `presentation/debug/enemy_path_gizmo.gd:121,131`, `presentation/vfx/projectile_vfx.gd:144-145,183,188,209,213`, `simulation/night/enemy_system.gd:209,215,235,240,275`, `simulation/night/night_sim.gd:145,149`, `tools/replay/replay_driver.gd:139,141` (kills by unit), `ui/overlay/night_overlay_sections.gd:86,88`.

### Pattern 3: Guard, commit, leash (UNIT-04)
Per unit: `target_id` (enemy id) and `cooldown_ready_tick`. A unit with no target looks for one on its staggered tick only: `EnemySystem.is_rescan_tick(tick, unit_id, rescan_ticks)` (a static, reusable function: `rescan_ticks > 0 and (tick + id) % rescan_ticks == 0`). Acquire with `TargetQuery.nearest_enemy(enemies, anchor, guard_radius)` (strictly nearer replaces, lower id wins ties). **Commit:** keep the target until it is dead or farther than `leash_range` from the squad's anchor (or from the unit, for attack-move and patrol); never swap to a nearer enemy mid-fight. When nothing is valid the unit returns to its formation slot. A melee unit walks to `target radius + attack_range`; an archer stops at `attack_range` and fires a `PendingHits` arrow with `SimClock.flight_ticks(distance, projectile_speed)`, the same path the towers use (`tower_system.gd`, read this session). `attack_fired(KIND_UNIT, unit_id, KIND_ENEMY, enemy_id, flight)` drives `ProjectileVfx`.

### Pattern 4: The order state machine (D-09, D-14)
A squad has an `orders` queue (cap 9 per the UI-SPEC) and a **resting stance** used when the queue is empty: `POST` (anchor, guard), `FOLLOW` (anchor = king position, re-evaluated each step), `HOLD` (anchor frozen), `PATROL` (path ping-pong). One-shot verbs `MOVE`, `ATTACK_MOVE` consume themselves on arrival and leave the resting stance `POST` at the arrival point. Terminal verbs (`HOLD`, `FOLLOW`, `PATROL`) set the resting stance and end the queue. `RALLY` expands at apply time into `[MOVE king_position_snapshot, HOLD]`. A non-queued command clears the queue first; a queued one appends (a tenth replaces the last, matching the UI-SPEC's overflow row). `begin_night` and `restore_for_dawn` must **not** touch stance, queue or anchor (D-14); replacements spawn at the building and walk to their slots. The HUD stance glyph reads two getters: `resting_stance(squad)` and `executing_verb(squad)`.
Decisions the code must pin with tests (ASSUMED until the owner confirms in the UAT): units do not attack while a `MOVE` is executing; `HOLD` freezes the anchor at the squad centroid at the apply tick (units shuffle to slots around it); a queued order after a terminal verb is dropped at queue time.

### Pattern 5: Phases other than NIGHT must step the army and the king
Today `RunContext.step` calls `night.step(tick_count)` only while `get_phase() == NIGHT` (run_context.gd:59-66, read this session), so nothing day-time ever advances. Phase 3 needs, on **every** step of every phase except a finished run:
1. `king.tick_timers()` (new): decrements the ability cooldown counter, advances the regeneration delay counter and the heal accumulator. These are countdown counters in ticks decremented once per step, exactly like `_respawn_ticks_left`, so no tick base is needed (the night tick resets every night, the run tick does not). Regeneration never runs while he is down.
2. The army and a pending slam: a `NightSim.step_day(tick)` (or an equivalent hook the planner names) runs `squads.step(...)` and the slam resolver against an **empty** enemy set, then resolves hits. Squad movement, formation settling, top-up and the slam by day all go through the same code as at night.
Order inside the night step (extends DR-8): spawn, king (passive attack, slam resolve), **squads (id order)**, towers (spot order), castle, enemies (id order), resolve hits, remove dead enemies, remove dead units. Units decide on the positions at the start of their own sub-step.
`ActivateAbilityIntent` applies between steps: validate (king up, cooldown 0, run not over), set the cooldown counter and arm `_slam_pending`; the next step's king slot enqueues one `PendingHits` entry per enemy in `slam_radius` (ascending id, centre-to-centre `<= radius`, arrival tick = now, attacker kind `KIND_KING`) and emits `king_ability_used(hit_count)`. By day there are no enemies, so it hits nothing and still fires the event (the HUD flash and VFX).
Regeneration uses a float accumulator, which DR-7 allows (`+ - * /` only): `progress += float(max_health) * regen_fraction_per_second * SimClock.STEP`, then heal one point per whole unit of progress and emit `king_healed(amount, hp, max_hp)` only when the integer hp changed. Defaults of 0 make both rules opt-in so fixtures and the smoke golden are untouched (Pitfall 1).

### Pattern 6: Mouse points never enter the simulation raw
Ground pick (presentation): `camera.project_ray_origin(p)`, `camera.project_ray_normal(p)`, `Plane(Vector3.UP, 0.0).intersects_ray(...)`; a `null` result or a point outside `MapConfig.ground_half_extent` means "Can't go there". The controller converts to `Vector2i(roundi(x * 100.0), roundi(z * 100.0))` (centimetres, the same quantisation `SimRecorder.POSITION_SCALE = 100.0` uses) and builds the intent. The simulation converts back with `Vector2(cm) / 100.0`, one IEEE division, deterministic. Rally, hold and follow take no point from the player at all: the simulation reads the king position or the squad centroid itself at the apply tick. A new `squad_ordered(squad_id, verb, queued, x_cm, y_cm)` event puts every accepted order into the digest.
Pad cursor: keep the cursor in **screen space**, move it by the right stick, clamp it to the viewport inset by `SpawnTelegraph.EDGE_MARGIN_PX` (48 px), start it at `camera.unproject_position(king ground point)`, and ray-pick on release. Clamping in screen space gives "clamped to the visible ground" for free. The camera looks down at about 55 degrees (offset 0, 20.8, 14.3, fov 40) [VERIFIED: camera_rig.gd offset; prototype_map.tscn `fov = 40.0`], so every ray inside the viewport hits the ground at any zoom (a probe with the same rig hit the ground at the screen centre and at 2 px from the top of a 64 px viewport) and the pad never produces an invalid point.

### Pattern 7: Device tracking and prompts
`LastDeviceTracker` is a pure `DeviceModel` (RefCounted) with `feed(event: InputEvent, now_s: float) -> bool` plus a thin `Node` that calls it from `_input` with `Time.get_ticks_msec() / 1000.0` and emits `device_changed(kind)`. Rules are the UI-SPEC's (key press, any mouse button, mouse motion 8 px within 0.25 s -> keyboard; pad button or `abs(axis_value) >= 0.5` -> pad; one switch per 0.25 s; start on keyboard; `Input.joy_connection_changed` falling back to keyboard). `Input.parse_input_event` of an `InputEventJoypadMotion` with `axis_value = 0.8` reaches a Node's `_unhandled_input` [VERIFIED: probe], so scripted tests can drive the tracker with real events. `Input.mouse_mode = Input.MOUSE_MODE_HIDDEN` while the pad is active is presentation-only. `time` use in `input/` is fine: the DR-5 scan covers only `simulation/`.

### Anti-Patterns to Avoid
- **Raw mouse positions, `InputEvent`s or `Camera3D` anything inside `simulation/`.** Points enter as `Vector2i` cm inside an intent only.
- **Selection or control groups inside the simulation.** They are UI state; intents carry ids.
- **`Input.is_action_just_pressed` for digits without thinking about modifiers.** A bare-digit action also fires on Ctrl+digit (probe); use the modifier action to branch, or pass `exact_match`.
- **Copying `EnemyViews`' `blend = alpha if NIGHT else 1.0`.** Enemies do not move by day, units do; unit puppets must interpolate by `ctx.alpha()` in every phase or they snap at 30 Hz by day.
- **A unit-count-dependent `for` over `get_nodes_in_group`** or per-unit physics bodies (DR-1, DR-6).
- **`push_error` for a rejected command.** Return a reason value and emit `command_rejected` (established pattern; GUT counts engine errors as failures).
- **Assigning `Engine.time_scale` anywhere new.** `FastForwardController` is the only writer and a source scan enforces it (read in tests/unit/test_fast_forward_rules.gd).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mouse to ground point | Manual matrix maths | `Camera3D.project_ray_origin/normal` + `Plane.intersects_ray` | Round-trips to within 1e-6 m at three window sizes [VERIFIED: probe] |
| Box-select hit test | A custom rasteriser | `Rect2.has_point` over `Camera3D.unproject_position` of each unit | Pure and unit-testable with injected screen points |
| Staggered rescans | A second scheme | `EnemySystem.is_rescan_tick(tick, id, rescan_ticks)` | Same distribution, already pinned by tests |
| Nearest enemy | A new scan | `TargetQuery.nearest_enemy(enemies, pos, reach)` | Phase 4's spatial hash replaces the one seam |
| Arrow flight and damage | Spatial projectiles | `PendingHits` + `SimClock.flight_ticks` + `ProjectileVfx` | Deterministic, drops cleanly when the target is gone |
| Seeded randomness | `randf()` | `SimRng` streams (and none is needed: formation and orders use no randomness) | DR-4/DR-5 |
| Hold-to-build / start-night input | New handling | Existing `BuildHoldController` / `StartNightHoldController` | Unchanged by this phase |
| Ground ring rendering | One `MeshInstance3D` per unit | One `MultiMeshInstance3D` with per-instance colour | Matches Phase 4 and the UI-SPEC |
| Glyph art | Drawing key caps | Kenney Input Prompts tiles + a code-drawn text keycap fallback | The UI-SPEC already specifies the fallback |
| Platform-correct key labels | A key-name table | The existing `Hud._key_text` / `physical_label_resolver` logic (Dvorak/AZERTY safe); move it into the glyph resolver, keep the tests | Already handles headless |

**Key insight:** every hard part of this phase already has a seam from Phase 2 (ids, pending hits, rescans, intents, recorder, golden, bots). The risk is not missing machinery but forgetting to thread the new kind and the new phase-step through every place that switches on a kind or on the phase.

## Runtime State Inventory

Not applicable: this is a greenfield-feature phase, not a rename or migration. (Data growth is covered under Pitfalls: the prototype map, the golden replays and the balance pins.)

## Common Pitfalls

### Pitfall 1: The smoke golden moves when it should not
**What goes wrong:** the `smoke` golden digest `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` [VERIFIED: tests/golden/smoke.json and `bash tools/replay.sh --scenario=smoke --expect-file=tests/golden/smoke.json` printed `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c2...` this session] contains six `king_damaged` lines [VERIFIED: grep -c on build/replay/smoke.log]. Any always-on regeneration changes the later hp values and therefore the digest.
**Why it happens:** Phase 3 adds a rule (regeneration) that touches a king who is hurt in the fixture.
**How to avoid:** make both new king rules opt-in by data default (`regen_fraction_per_second = 0.0`, a `WeaponDef` slam with `cooldown = 0` treated as "no ability") and move the king's passive numbers into `WeaponDef` with **identical** values in `fixture_king_replay_smoke.tres` (which today carries `attack_range = 3.0`, `attack_damage = 3`, `attack_interval = 0.8` [VERIFIED: tests/fixtures/fixture_king_replay_smoke.tres:13-15]). The shipped `king.tres` then sets the real values. The unchanged digest becomes the regression proof that Phase 3 did not alter Phase 2 rules. Add a second scenario `army` (fixture map with a Barracks and an Archery Range, scripted commands and a slam) with its own golden in `tests/golden/army.json`. `full_idle` has no golden and moves with the retune.
**Warning signs:** `test_replay_golden` red after the first king-def task.

### Pitfall 2: Moving the weapon fields breaks tests that read `KingDef.attack_*`
**What goes wrong:** `KingDef` declares `attack_range`, `attack_damage`, `attack_interval` [VERIFIED: simulation/defs/king_def.gd:25,27,29] and `KingState` reads them (king_state.gd:125,129,132). `tests/unit/test_king_combat.gd` reads `_def.attack_range` at lines 45, 51, 73 and `_def.attack_damage` at 96. D-18 moves them to `WeaponDef`.
**How to avoid:** `KingDef` gains `@export var weapon: WeaponDef`; remove the three fields in the same task that migrates `king.tres`, the smoke fixture, `king_state.gd` and `test_king_combat.gd`. `KingState` falls back to a default `WeaponDef` when `weapon` is null so test-built `KingDef.new()` instances keep working.

### Pitfall 3: Every new `SimEvents` signal has three more places to update
The drift guard `test_the_watched_signals_are_every_signal_the_simulation_declares` compares `SimEvents` with `SimSignals.ALL` [VERIFIED: tests/support/sim_signals.gd]; the recorder has its own `HANDLED` list, one `connect` per signal and one handler [VERIFIED: tools/replay/sim_recorder.gd], and `test_determinism.gd` fails when one is missing. Add each new signal (suggested: `unit_spawned`, `unit_damaged`, `unit_died`, `squad_ordered`, `squad_restored`, `king_healed`, `king_ability_used`) to all three in the same task, and give the recorder only ints, ids and names (`Vector2` is already quantised by `_token`).

### Pitfall 4: `test_input_map.gd` encodes the old controls
It pins `&"fast_forward": [KEY_F]` (line 32), "no gameplay action has a mouse binding" (`test_no_project_action_has_a_mouse_binding`, line 173) and "no two gameplay actions share a key, button or stick direction". All three must be amended deliberately: fast-forward to its new key, mouse bindings allowed only on the named selection/command actions (D-11), and an explicit allow-list for the intentional shared bindings (Shift for `sprint` and the queue modifier; the same D-pad button on a bare action and its LB-chord twin if the layout uses chords). `GAMEPLAY_ACTIONS` grows so INPT-01/02 are enforced for every new action.

### Pitfall 5: A bare-digit action also matches Ctrl+digit
Probe on 4.7.2: for a Ctrl+1 event, an action bound to bare `1` reports `is_action_pressed(..., false, false) = true` and `exact = false`; the Ctrl+1 action reports `true` both ways; after `Input.parse_input_event` of Ctrl+1, `Input.is_action_pressed(recall)` is `true` loose and `false` with `exact_match = true` [VERIFIED: probe this session]. The docs agree: "If exact_match is false, it ignores additional input modifiers for InputEventKey and InputEventMouseButton events" [CITED: docs.godotengine.org/en/stable/classes/class_input.html]. A design with 10 `group_N` digit actions plus one `selection_modifier` (Ctrl) action, branching on `Input.is_action_pressed(&"selection_modifier")` at the moment of the digit press, avoids the trap entirely and halves the rebinding surface.

### Pitfall 6: `Input.action_press` is invisible to event handlers
`Input.action_press(&"g_recall")` set `is_action_pressed` to true and delivered **zero** events to a node's `_unhandled_input` [VERIFIED: probe: `listener events=0`]. Existing controllers poll (`BuildHoldController` reads `Input.is_action_pressed` and keeps its own `_was_pressed` edge, read this session), so scripted real-window runs work for them. Rule for this phase: **verbs and digits are polled** (`is_action_just_pressed`, plus the `pressed and not _was_pressed` fallback the hold controller uses); **mouse and pad-cursor input are events** and tests drive them with `Input.parse_input_event`.

### Pitfall 7: The required stretch setting changes `get_visible_rect()` in tests
03-UI-SPEC.md requires `display/window/stretch/mode="canvas_items"` and `aspect="expand"`. Probe with exactly those settings and the 1280x720 base: window 1280x720 -> visible rect 1280x720; window 1920x1080 -> 1280x720; window 1600x1000 -> 1280x800; the **default 64x64 headless test window -> 1280x1280** [VERIFIED: probes this session]. Code that assumed a tiny viewport behaves differently: `SpawnTelegraph.edge_margin` (its unit test uses a literal 64x64 `Rect2` and is unaffected), `dawn_payout_vfx.gd:332` (`viewport.get_visible_rect().size * 0.5`), `dawn_no_income_marker.gd`, `spot_label.gd` and the e2e tests `test_dawn_payout*.gd`, `test_king_ride.gd`, `test_camera_zoom.gd`. Land the project setting in its own early task and run the suite before anything else builds on it.

### Pitfall 8: Mouse clicks swallowed by HUD controls
Probed defaults on 4.7.2: `Panel` = STOP (0), `MarginContainer` = PASS (1), `Label` = IGNORE (2); a click on the STOP panel never reached `_unhandled_input`, clicks on the PASS container and on empty space did [VERIFIED: probe this session]. So selection and box-drag belong in `_unhandled_input` (HUD buttons then naturally block them, as the UI-SPEC wants for slots), and every full-rect HUD overlay must be IGNORE: the existing ones already are (`hud.tscn` sets `mouse_filter = 2` on SpawnTelegraph, StartNightBox, PhaseBannerBox, RespawnBox, FastForwardLabel, PayoutTotal, DawnNoIncomeMarker, DawnPayoutVfx; the top-left `Margin` MarginContainer is PASS and 40 px wide). New `HudRoot`, `SquadStrip` (non-slot parts), `CommandHints` and the toast must be IGNORE; only `SquadSlot` is STOP. Add one e2e test that a left click on empty ground with the real HUD instanced reaches the selection controller.

### Pitfall 9: MultiMesh property order
`use_colors` and `transform_format` must be set while `instance_count` is 0, then `instance_count` is assigned [CITED: docs.godotengine.org/en/stable/classes/class_multimesh.html]. Setting them afterwards silently does nothing and every ring renders in one colour.

### Pitfall 10: Positions that look right but break determinism
The new directory `simulation/squads/` is not covered by `test_sim_rules_guard.gd`'s math scan: `MATH_ROOTS` lists only clock, night, king and castle [VERIFIED: tests/unit/test_sim_rules_guard.gd:9-14]. Add `res://simulation/squads` to it in the first squads task. The whole simulation tree is already scanned for global RNG, `Time`, `OS`, `get_tree(`, `Engine.get_` and friends, so the squad code is covered by that half already. Practical consequence: **no `sin`, `cos`, `atan2`, `pow`, `lerp_angle` in squad code**; formation is an axis-aligned grid (`columns = ceili(sqrt(cap))`), headings are not simulated.

### Pitfall 11: Adding the two plots shifts hit ids and test counts
Building hits address a spot by its **index** in `BuildingSystem.spot_ids()` (`PendingHits` doc: "For KIND_BUILDING the id is the spot's index"). Append the two new `BuildSpotDef`s at the **end** of `MapConfig.spots` so the eight existing indices, payout order and nearest-spot tie-breaks never change. `tests/unit/test_prototype_map_data.gd:58` asserts `map.spots.size()` equals `HOUSE_SPOT_COUNT + TOWER_SPOT_COUNT` ("8 fixed spots (D-03)") and must be amended; `building_view_catalog.tres` has no entry for the new buildings (BuildingViews falls back to primitives, so nothing crashes, but the markers need colours); `SpotLabel` shows `BuildingTierDef.effect_line()` which has branches for income and attack only and needs a squad branch ("Squad of 4").

### Pitfall 12: The balance acceptance test measures the old balance
`tests/integration/test_balance_acceptance.gd` pins `BALANCED_LOST_SEEDS = [3, 9]`, `BALANCED_FIRST_LOSS_NIGHT = 3` and greedy/no_build/towers_first shapes on the shipped data [VERIFIED: file read]. Raising night counts (D-08) invalidates them. Keep the existing five strategies as the "no army" control (they now lose earlier, which is itself a D-10 signal), add an army-building balanced strategy, and re-pin: army-balanced wins 7 or 8 of 10 on seeds 1 to 10; `test_night_data_contract.gd` (`NIGHT_TOTALS`, `ROUND_THREE_COUNTS`) is updated with the new counts and a comment that records the retune. `before_all` of that test already runs a whole strategy matrix inside GUT, so the suite wall time will grow; measure it.

### Pitfall 13: Real-window verification needs the right driver
Headless GUT has a 64 px window and a dummy renderer. Selection rings, the HUD layout and glyph legibility can only be judged in a real window through the screenshot runner (`tools/screenshot.sh`, never headless; the runner exits 2 there). The shot list lives in two places that must change together: `tools/screenshot.sh` `ALL_SHOTS` and `tools/screenshot/shot_scenarios.gd` `ALL_SHOTS` [VERIFIED: both read this session].

### Pitfall 14: The "A" key conflict is real, not cosmetic
D-15 binds attack-move to **A**, but `move_left` is bound to physical key 65 (A) and 4194319 (Left arrow) [VERIFIED: project.godot move_left block]. The king polls the movement actions every physics frame (`King._physics_process` uses `Input.get_vector`, read this session), so pressing A to arm attack-move also rides the king left; `set_input_as_handled()` does not stop polling. See Open Question 1 for the decision this needs.

## Code Examples

### Ground pick and quantise (presentation only)
```gdscript
# Source: Camera3D / Plane docs; round trip verified by probe on 4.7.2 (hit within 1e-6 m).
static func ground_point(camera: Camera3D, screen: Vector2) -> Variant:
	var origin: Vector3 = camera.project_ray_origin(screen)
	var direction: Vector3 = camera.project_ray_normal(screen)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)  # Vector3 or null


static func to_centimetres(ground: Vector3) -> Vector2i:
	return Vector2i(roundi(ground.x * 100.0), roundi(ground.z * 100.0))
```

### Modifier-aware digit handling (polled, scriptable with `Input.action_press`)
```gdscript
# group_0..group_9 are bare-digit actions; selection_modifier is Ctrl (and a pad chord).
# A loose match is fine here because the branch is decided by the modifier action itself.
func _poll_groups() -> void:
	for index: int in range(GROUP_ACTIONS.size()):
		if not Input.is_action_just_pressed(GROUP_ACTIONS[index]):
			continue
		if Input.is_action_pressed(&"selection_modifier"):
			_selection.store_group(index)
		else:
			_selection.recall_group(index)
```

### Input Map text for the new bindings (var_to_str output of 4.7.2, `device` set to -1 as the file already does)
```
# Right mouse button (Move):
Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":2,"canceled":false,"pressed":true,"double_click":false,"script":null)
# Ctrl + 1 as a key chord (only if a chord action is wanted; modifier bits are fields on the key event):
Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":true,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":49,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
# Right trigger as a button-like axis:
Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"axis":5,"axis_value":1.0,"script":null)
```
Engine constants (printed by the probe): `KEY_CTRL=4194326`, `KEY_SHIFT=4194325`, `KEY_TAB=4194306`, `KEY_ALT=4194328`, `KEY_0=48`, `KEY_9=57`, `KEY_H=72`, `KEY_R=82`, `KEY_P=80`, `KEY_Q=81`, `KEY_C=67`, `KEY_T=84`, `KEY_G=71`, `KEY_X=88`, `KEY_ESCAPE=4194305`; joypad buttons A0 B1 X2 Y3 Back4 Start6 L3=7 R3=8 LB9 RB10 D-pad up/down/left/right 11/12/13/14; axes LX0 LY1 RX2 RY3 LT4 RT5 [VERIFIED: probe this session]. Always compare against `KEY_*`/`JOY_*` constants in tests, never integer literals (the existing input test's rule).

### Scripted pointer input in a test (works headless and in a real window)
```gdscript
# Source: probe this session. The event position is in the stretched 2D space.
func _click(position: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT, ctrl: bool = false) -> void:
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = button
	down.pressed = true
	down.ctrl_pressed = ctrl
	down.position = position
	Input.parse_input_event(down)
```

### Pure box select (no camera needed in the test)
```gdscript
# points_by_squad: Dictionary StringName -> PackedVector2Array of screen points (one per unit).
static func squads_in_rect(points_by_squad: Dictionary, rect: Rect2) -> Array[StringName]:
	var hit: Array[StringName] = []
	for squad_id: StringName in points_by_squad:
		for point: Vector2 in points_by_squad[squad_id]:
			if rect.has_point(point):
				hit.append(squad_id)
				break
	return hit  # insertion order = squad creation order, deterministic
```

## Kenney Input Prompts facts (D-24)

Downloaded to a scratch directory and inspected this session (zip held outside the repo; it is untrusted data).

- **Layout:** top-level folders per device (`Keyboard & Mouse`, `Xbox Series`, `PlayStation Series`, `Nintendo Switch`, ..., `Flairs`, `Generic`), each with `Default` (64 px PNG), `Double` (128 px PNG), `Vector` (SVG) and `Fonts`. `Keyboard & Mouse/Default` holds 257 files, `Xbox Series/Default` 99 [VERIFIED: zip listing]. There is no separate Xbox 360 folder; `Xbox Series` covers Xbox 360/One/Series buttons.
- **Licence:** `License.txt` "License: (Creative Commons Zero, CC0) ... Support by crediting 'Kenney' ... (this is not a requirement)"; header "Input Prompts (1.5A)", "Creation date: 11-07-2026" [VERIFIED: extracted this session].
- **Tile colour:** the `Default` tiles are **white on transparent** (palette PNGs: `xbox_button_a.png` = 1646 opaque pixels, all `(255,255,255)`; `xbox_rs.png` and `xbox_stick_r.png` white; `mouse_right.png` white with a red `(231,50,70)` button area). The only coloured badges are `xbox_button_color_a/b/x/y.png` (A is `(125,183,0)`). `*_outline` variants are white outlines. Consequence: a white tile on mid-green daytime grass has no contrast; every glyph must sit on a dark plate (`#14141A` at alpha 0.78, radius 4, matching the HUD panels), or use the `*_color_*` badges for A/B/X/Y. The UI-SPEC's "carries a 6 px outline" cannot apply to a texture, so the plate is the contract. Reading the UI-SPEC's "default filled style" as the `Default` folder is correct; "filled" does not mean coloured.
- **Tile names needed (all in `Default/`), as extracted:** keyboard `keyboard_<a-z>.png`, `keyboard_0.png`..`keyboard_9.png`, `keyboard_space.png`, `keyboard_shift.png`, `keyboard_ctrl.png`, `keyboard_tab.png`, `keyboard_escape.png`, `keyboard_enter.png`, `keyboard_arrow_up/down/left/right.png`, `keyboard_f3.png`, `keyboard_equals.png`, `keyboard_minus.png`, `keyboard_numpad_plus.png`; mouse `mouse_left.png`, `mouse_right.png`, `mouse_scroll.png`; Xbox `xbox_button_a/b/x/y.png` (and `_color_` twins), `xbox_lb.png`, `xbox_rb.png`, `xbox_lt.png`, `xbox_rt.png`, `xbox_dpad_up/down/left/right.png`, `xbox_button_back.png`, `xbox_button_start.png`, `xbox_stick_r.png`, `xbox_rs.png`, `xbox_stick_r_press.png`. Which of `xbox_stick_r` / `xbox_rs` reads best as "right stick" was not judged visually (both are white-on-transparent) [ASSUMED: view both in the first glyph task]. There is no keypad-minus tile, so `KEY_KP_SUBTRACT` falls to the text keycap fallback.
- **Resolver mapping:** key events by `physical_keycode` through the existing layout-label logic (`Hud._key_text` / `physical_label_resolver`), mouse by `button_index` (1 left, 2 right), `InputEventJoypadButton.button_index` and trigger axes 4/5 by the constants above, D-pad by buttons 11 to 14. Everything else falls back to the text keycap.
- **Where it goes:** `assets/third_party/kenney_input_prompts/{keyboard_mouse,xbox}/` plus `License.txt`; attribution entry `id: "kenney-input-prompts"` sorts **between** `kenney-fantasy-town-kit` and `kenney-mini-characters` in both `assets/attribution.json` and the `ASSETS.md` table (test_attribution_log enforces order, one owning entry per file including `.import` files, and rows in the same order). PNG files are Git LFS (`.gitattributes`: `*.png filter=lfs`), `.import` files are text.

## Unit model facts

The Mini Characters zip lists `Models/GLB format/character-male-a..f.glb` and `character-female-a..f.glb` (about 245 to 273 KB each). `character-male-a.glb` carries an `AnimationPlayer`-ready animation list: `static, idle, walk, sprint, jump, fall, crouch, sit, drive, die, pick-up, emote-yes, emote-no, holding-right, holding-left, holding-both, holding-right-shoot, holding-left-shoot, holding-both-shoot, attack-melee-right, attack-melee-left, attack-kick-right, attack-kick-left, interact-right, interact-left, ...` and two meshes (`body-mesh`, `head-mesh`) [VERIFIED: GLB JSON parsed this session; the other eleven characters were not parsed, ASSUMED to share the rig]. The pack has no weapon props (only `aid-*` accessibility items), so a sword and bow are small code-built primitives attached to a hand node; unit teams are told apart by choosing different characters, since the characters share one colormap texture and cannot be tinted without a material override. Animated GLB puppets are one node tree each (fine for tens of units); Phase 4 decides what to do at hundreds.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mouse for menus only, keyboard hotkeys for units | Mouse selects squads and supplies ground points; pad uses cycling and a right-stick cursor | 2026-10-09 (D-11) | Input tests, REQUIREMENTS wording, prompts all change |
| King combat numbers on `KingDef` | `WeaponDef` equipped on the king | D-18 | Fixture and test migration (Pitfall 2) |
| Only the night steps | Every phase steps the army and king timers | This phase | New day hook (Pattern 5) |
| Text pad labels (`PAD_BUTTON_NAMES`, `AXIS_NAMES`) | Glyph tiles with a text fallback | D-24 | `hud.gd` constants become the fallback |

**Deprecated/outdated:** the `Hud` "Known Phase-1 limitation" of Xbox-only text labels for glyphed actions.

## Assumptions Log

> Claims tagged `[ASSUMED]` below need user confirmation or a measurement before becoming locked.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Starter unit numbers: Footman hp 10, damage 1, interval 0.6 s, speed 4.0, radius 0.45, attack range 1.2, guard 7 m, leash 12 m; Archer hp 6, damage 1, interval 0.9 s, speed 3.8, radius 0.4, range 8.5, arrow 16 m/s, guard 10 m, leash 14 m. Basis: D-07 "a fifth" of 50 hp and 5 damage, and a 4-footman squad at 4 / 0.6 = 6.7 dps against the king's 5 / 0.7 = 7.1 dps. Integer damage means damage 1 is the only value near a fifth of 5, so squad strength is tuned through interval, hp and squad size | Pattern 3, Standard Stack | Wrong feel; the bots and the owner retune; all data |
| A2 | Plot positions: Barracks `(-16, 0, -2)`, Archery Range `(16, 0, -2)`, ids `barracks_1` / `archery_1`, building ids `barracks` / `archery_range`, unit ids `footman` / `archer`. Criteria that matter: inside the 55 m tower ring, at least 5 m from every plot and the castle edge (interaction radius 2.5 m), appended after the existing eight | Pitfall 11 | Squads too far from the roads; data only |
| A3 | New keys: ability `Q` / pad `X`; fast-forward `T`; follow F, hold H, rally R, patrol P, cycle Tab, store/recall Ctrl + 0..9 / 0..9 per D-15; attack-move conflicts with `move_left` (Open Question 1); select-all and select-one-type keys unchosen (suggest double-click for "same type" and a dedicated key for "all") | Pitfall 14 | Owner dislikes a key; Input Map data plus prompts follow automatically |
| A4 | New seats created by a build or an upgrade fill instantly by day; the 10/7/4 s trickle applies in the night only (D-05) | Pattern 4 | UI-SPEC text implies a visible fill after an upgrade; a momentary or no fill |
| A5 | Units do not attack while a `MOVE` executes; `HOLD` anchors at the centroid at the apply tick; an order queued after a terminal verb is dropped | Pattern 4 | Behaviour differs from the owner's mental model of "ignoring enemies" |
| A6 | Slam: radius 4.0 m, damage 4, cooldown 9 s; no knockback; hits by centre-to-centre distance | Pattern 5 | Too strong or weak; data only |
| A7 | Dawn keeps its full king heal (`restore_for_dawn`) next to regeneration; D-20 only supersedes "no regeneration during a night" | Pattern 5 | A different intent, one line in `RunManager._enter_dawn` |
| A8 | `MapConfig.ground_half_extent` (new data, 90 m for the 180 m ground) defines "outside the map" for command points | Pattern 6 | Points off the ground plane accepted; trivial |
| A9 | The stretch-mode coordinate agreement measured in the headless dummy window also holds in a real window | Pitfall 7 | Pick offset at other resolutions; verify in the first real-window run with a round-trip scenario |
| A10 | Mini Characters GLBs other than `character-male-a` share its animation list | Unit model facts | A different character lacks `attack-melee-right`; check when picking |
| A11 | Suggested pad layout: X slam; D-pad up follow, down hold, left rally, right cycle next; LB held + D-pad for the point verbs and cycle previous; RT held = queue; Start held = group assign (D-pad left/right steps the slot); B cancels a cursor aim | Open Question 3 | Any of it can move; D-12 only fixes "verbs on the D-pad" |
| A12 | Control-group semantics: groups hold squad ids; squads are never deleted (a fallen building keeps its squad), so groups never drop members; a newly built squad joins no group; recalling an empty group shows "Group N is empty" | Open Question 2 | Resolves the UI-SPEC's unresolved row; owner may want auto-join |
| A13 | Timing: the unit suite stays about one minute and the full suite grows from about 270 s (Phase 2 figure) by the cost of the new bot matrix | Validation Architecture | Slower feedback; measure in the first bot task |
| A14 | Both military buildings get max health around 40 / 60 / 80 by tier (tower 50/70, castle 70) | Standard Stack | Buildings die too fast or too slowly; data |

## Open Questions

1. **The `A` key (attack-move) collides with `move_left`.**
   - What we know: D-15 is locked ("A attack-move"); `move_left` is physical A and Left arrow; the king is driven by polling; the hint strip reads the Input Map so any final key is shown correctly.
   - What's unclear: whether the owner accepts the king drifting left on every A press, or prefers a different attack-move key.
   - Recommendation: ship the action with a **data default that is not WASD** (suggest `C`, "charge") and put a one-line `checkpoint:human-verify` in the plan so the owner confirms; or keep `A` verbatim and accept the drift (a 0.1 s tap moves the king about half a metre at walk speed with acceleration 60 m/s^2). Do not suppress `move_left` while squads are selected: selection is permanent, so that would remove A-steering for the whole run.
   - Resolution: (RESOLVED) plan 03-07 Task 1 is a blocking `checkpoint:decision` (keep-a recommended because D-15 is locked, use-c or another key as the alternatives); 03-07 Task 3 binds the chosen key and the test_input_map allow-list follows it.
2. **Control groups after a squad is lost or added (UI-SPEC unresolved row).**
   - Recommendation: as A12. It is a pure `SelectionModel` property, covered by unit tests, and needs no simulation support.
   - Resolution: (RESOLVED) plan 03-08 Task 3 adopts A12: groups hold squad ids, keep members at 0 alive, a new squad joins no group, and recalling an empty group keeps the selection.
3. **Pad layout beyond the D-pad verbs (D-12 leaves it to the planner).**
   - Free pad bindings today [VERIFIED: project.godot]: B, X, LB, RT (axis 5), Start, L3, R3, D-pad up/down (11, 12); D-pad left/right (13, 14) are `ui_left`/`ui_right` menu bindings (harmless in a run because no HUD control takes focus, but the results screen uses them); right stick Y (axis 3) is zoom, right stick X (axis 2) is free. Taken: A (build/`ui_accept`), Y (start night), RB (sprint), LT axis 4 (fast-forward), Back (debug).
   - Recommendation: A11. Chords on a pad are a code-level modifier (`Input.is_action_pressed(&"command_layer")`), never an Input Map modifier, so twin actions bound to the same D-pad button need an explicit exception in the "no two actions share a binding" test. While the ground cursor is active, suppress zoom (a flag on `CameraRig`).
   - Resolution: (RESOLVED) plan 03-09 adopts A11: D-pad verbs, the LB command layer, R3 and LB + R3 selection, Start group mode, RT queue and B cancel (Task 1), and the right-stick ground cursor with zoom suppressed through `CameraRig.set_zoom_suppressed` (Task 2).
4. **Where `NightSim.step_day` lives.** Pattern 5 states the constraint (same slot order, empty enemy set); naming and file split are the planner's.
   - Resolution: (RESOLVED) plan 03-01 Task 1 adds `NightSim.step_day(tick)` in `simulation/night/night_sim.gd`, called by `RunContext.step()` in every phase except NIGHT and a finished run.
5. **Do the owner's own runs get recorded for replay?** Phase 2 said no. Because intents are already integer-only, a `CommandProcessor` intent log (`[tick, intent fields]`) is a cheap optional add that makes a played run replayable; not required.
   - Resolution: (RESOLVED) left out of Phase 3 as optional; owner runs stay unrecorded, as in Phase 2, and no plan adds an intent log.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot console binary | everything | yes | 4.7.2-stable official (probe) | none needed |
| `bash tools/test.sh` / `replay.sh` / `playtest.sh` / `screenshot.sh` / `lint.sh` | validation | yes (Git Bash) | `replay.sh --scenario=smoke` ran in about 40 s including import | PowerShell's `bash` is WSL and cannot see the Windows binary; use Git Bash |
| gdtoolkit (`gdformat`, `gdlint`) | lint gate | via `.tools/venv` (not on PATH) | 4.5.0 pinned | `bash tools/lint.sh` resolves it; `gdlint` is not on the shell PATH, so run through the wrapper |
| Python 3 | probes, `tools/bootstrap.py` | yes | 3.14.5 (`python -I`) | none needed; Pillow is not installed (PNG inspected with a stdlib reader) |
| curl, sha256sum, git, git-lfs | asset download, LFS | yes | git 2.46, git-lfs 3.5.1 | none needed |
| Real renderer / GPU window | screenshot scenarios, glyph and ring checks | yes on the owner's machine (Phase 2 used it) | Forward+ | `DUSKHOLD_SCREENSHOT_COMPAT=1` for CI |
| Gamepad hardware | pad parity check | not verified | — | Scripted pad events via `Input.parse_input_event`; the cursor feel is an owner check |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT 9.7.1 on Godot 4.7.2-stable, headless (64 px window; with the new stretch setting `get_visible_rect()` is 1280x1280 there, Pitfall 7) |
| Config file | `.gutconfig.json` (unit, integration, e2e dirs, `include_subdirs`, prefix `test_`, JUnit `res://build/test-results/gut-junit.xml`) [VERIFIED: file read] |
| Quick run command | `bash tools/test.sh -gdir=res://tests/unit` (about 16 s of test time at Phase 2's 223 tests; a few times that now; plus the import pass) |
| Single file | `bash tools/test.sh -gselect=test_<name>.gd` |
| Full suite command | `bash tools/test.sh && bash tools/lint.sh` (about 4 to 6 minutes; Phase 2 closed at 831 tests in 95 scripts) |
| Replay / determinism | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` and the new `--scenario=army --twice --expect-file=tests/golden/army.json` |
| Balance report | `bash tools/playtest.sh [--strategies=...] [--seeds=1..10]` (local) |
| Screenshots | `bash tools/screenshot.sh [shot...]` (real renderer, never headless) |

Rules carried over: a partial run overwrites the JUnit XML, so grep it only after a full run; a script runtime error inside Godot still exits 0, so the replay and playtest wrappers count as passing only with their sentinel line and a clean log; each test script stays at or below 20 test functions and 100-character lines with static typing.

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| KING-04 | Slam: cooldown in ticks from data, hits every enemy within radius in id order, works by day, rejected while down or cooling, kills attributed to the king | unit | `-gselect=test_king_slam.gd` | Wave 0 |
| KING-04 | Weapon data: `WeaponDef` shipped values pinned (50 hp king, 5 dmg / 0.7 s / 3 m passive, ~9 s cooldown) | unit | `-gselect=test_weapon_def.gd` | Wave 0 |
| KING-04 | HUD ability widget: fill ratio, ready flash once, denied shake, hidden knocked-out state | e2e | `-gselect=test_king_widget.gd` | Wave 0 |
| KING-05 | Regen starts 1 s after the last hit, 10 % of max per second, stops at full, none while down, restarts on a new hit, runs by day and by night | unit | `-gselect=test_king_regen.gd` | Wave 0 |
| UNIT-04 | Units guard a post, commit to a target until dead or beyond the leash, return to the slot, archers fire arrows through `PendingHits`; enemies target units and units absorb hits | unit | `-gselect=test_squad_guard.gd`, `-gselect=test_enemy_targets_units.gd` | Wave 0 |
| UNIT-05 | Hold anchors at the centroid, fights inside the guard radius, returns after a fight | unit | `-gselect=test_squad_orders.gd` | Wave 0 |
| UNIT-06 | Follow for the selection, for all (select-all) and for one type (same-type selection) | unit | `-gselect=test_squad_follow.gd`, `-gselect=test_selection_model.gd` | Wave 0 |
| UNIT-07 | Replacement every 10/7/4 s at night per tier, none by day, spawns at the building, dawn restore full numbers and hp, none while the building is rubble | unit | `-gselect=test_squad_respawn.gd` | Wave 0 |
| UNIT-09 | Click and box selection maths, Ctrl add, double-click type select, store/recall groups (0 = group 10), cycling order, groups keep squads that hit zero alive; ring count equals unit count | unit + e2e | `-gselect=test_selection_math.gd`, `-gselect=test_selection_model.gd`, `-gselect=test_selection_rings.gd` | Wave 0 |
| UNIT-10 | Move, attack-move, patrol (ping-pong, resume after a fight), rally expansion, Shift queue and the 9-order cap, stances survive `begin_night` and dawn, points quantised to cm and bounds-checked, rejections returned as values | unit + integration | `-gselect=test_squad_order_intent.gd`, `-gselect=test_squad_patrol.gd`, `-gselect=test_squad_stance_persistence.gd` | Wave 0 |
| UNIT-10 | Ground pick: `unproject_position` -> ray -> plane round trip, `null` off the ground, cm quantisation | unit | `-gselect=test_ground_pick.gd` | Wave 0 |
| INPT-01 | Every in-run action has a keyboard binding; mouse bindings only on the named actions; scripted mouse and key commands reach the simulation in the real scene (HUD present, STOP slot blocks, empty ground passes) | unit + e2e | `-gselect=test_input_map.gd`, `-gselect=test_mouse_commands.gd`, `-gselect=test_command_keys.gd` | exists (extend) + Wave 0 |
| INPT-02 | Every in-run action has a pad binding; pad cursor model (clamp, speed, start on king, release confirms, cancel); zoom suppressed while the cursor is active; `DeviceModel` thresholds and debounce; one `device_changed` re-renders every prompt; glyph resolver mapping and fallback | unit + e2e | `-gselect=test_ground_cursor.gd`, `-gselect=test_device_model.gd`, `-gselect=test_glyph_resolver.gd`, `-gselect=test_prompt_switch.gd` | Wave 0 |
| UI-01 | HUD contract: layout offsets, the four font sizes, `#8CEBFF`, copy constants, nothing inside x 384..896 / y 96..500 apart from the exempt nodes; squad strip states; day counter | unit + e2e + screenshot | `-gselect=test_hud_contract.gd`, `-gselect=test_squad_strip.gd`, `bash tools/screenshot.sh` (7 UI-SPEC scenarios) | Wave 0 |
| DEV-05 (kept) | Smoke golden unchanged; `army` golden; double run identical; new signals recorded; squads directory in the math scan | integration + script | `-gselect=test_replay_golden.gd`, `-gselect=test_determinism.gd`, `-gselect=test_sim_rules_guard.gd`, `bash tools/replay.sh ...` | exists (extend) |
| D-01..D-03 | Data contract: squad caps 4/8/14, respawn 10/7/4 s, costs 4/8/16, two plots appended after the eight, existing eight unchanged | unit | `-gselect=test_military_data_contract.gd`, `-gselect=test_prototype_map_data.gd` | Wave 0 + extend |
| D-08 | Army-balanced bot wins 7 or 8 of 10 seeds; no-army controls lose earlier; night data pins updated | integration | `-gselect=test_balance_acceptance.gd`, `-gselect=test_night_data_contract.gd` | exists (re-pin) |
| Data hygiene | `MapConfig.validate()` rejects bad unit/squad/weapon data (non-finite, non-positive, unknown ids, oversized squads, `ground_half_extent <= 0`) | unit | `-gselect=test_map_validate_squads.gd` | Wave 0 |
| Assets | Attribution log covers the Input Prompts files, sorted, one owner each | unit | `-gselect=test_attribution_log.gd` | exists |

### Sampling Rate
- **Per task commit:** `bash tools/test.sh -gdir=res://tests/unit` plus the task's own `-gselect=` file; `bash tools/lint.sh` when GDScript changed.
- **Per wave merge:** full `bash tools/test.sh` + `bash tools/lint.sh` + `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` (must stay green and unchanged until the deliberate army golden exists).
- **Phase gate:** full suite green, lint clean, smoke golden unchanged, `army` golden matches and double-runs, balance report regenerated and the army-balanced bot at 7 or 8 of 10, the seven UI-SPEC screenshot scenarios captured and non-blank at 1280x720 plus one 1920x1080 and one 16:10, a scripted real-window run that drives box select, right-click move, a patrol and the slam through `Input.parse_input_event`/`action_press` with screenshots, then `/gsd-verify-work` for the owner's feel check.

### Wave 0 Gaps
- [ ] `tests/unit/test_weapon_def.gd`, `test_king_slam.gd`, `test_king_regen.gd` - KING-04/05
- [ ] `tests/unit/test_military_data_contract.gd`, `test_map_validate_squads.gd` - D-01 to D-03, data hygiene
- [ ] `tests/unit/test_squad_guard.gd`, `test_squad_orders.gd`, `test_squad_patrol.gd`, `test_squad_follow.gd`, `test_squad_respawn.gd`, `test_squad_order_intent.gd`, `test_squad_stance_persistence.gd`, `test_enemy_targets_units.gd`
- [ ] `tests/unit/test_selection_model.gd`, `test_selection_math.gd`, `test_ground_pick.gd`, `test_ground_cursor.gd`, `test_device_model.gd`, `test_glyph_resolver.gd`
- [ ] `tests/e2e/test_mouse_commands.gd`, `test_command_keys.gd`, `test_prompt_switch.gd`, `test_king_widget.gd`, `test_squad_strip.gd`, `test_selection_rings.gd`, `test_hud_contract.gd` (watch the 20-per-script cap; split by topic)
- [ ] `tests/golden/army.json` + `army` scenario in `tools/replay/replay_scenarios.gd` + fixtures `tests/fixtures/fixture_map_army.tres` (frozen standalone copy, like the smoke fixtures)
- [ ] Amend: `tests/support/sim_signals.gd`, `tools/replay/sim_recorder.gd`, `tests/unit/test_input_map.gd`, `test_king_combat.gd`, `test_king_respawn.gd` (`test_there_is_no_regeneration_during_a_night` at line 197), `test_prototype_map_data.gd`, `test_balance_acceptance.gd`, `test_night_data_contract.gd`, `test_sim_rules_guard.gd` (`MATH_ROOTS`), `E2eSupport` (a helper that builds a map with military plots and a command-issuing driver)
- [ ] `tools/screenshot.sh` and `tools/screenshot/shot_scenarios.gd` shot list (two places), plus the seven UI-SPEC scenarios
- [ ] Framework install: none.

Manual-only (justified): the owner's feel judgments in `/gsd-verify-work`: squad behaviour readability (commit versus thrash at night), formation look, how the right-stick cursor feels, mouse selection feel, glyph legibility at night, HUD clutter, whether the slam cooldown and regeneration suit the game, and the balance bar. Everything measurable (positions, ticks, hp, counts, layout rectangles, event order, digests, screenshots) is checked by the agent first (self-verify rule).

## Security Domain

`security_enforcement` is on (ASVS level 1, block on high). This is a local single-player game with no network, accounts or persistence yet.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | no accounts |
| V3 Session Management | no | none |
| V4 Access Control | no | none |
| V5 Input Validation | yes | `CommandProcessor` validates every intent: squad ids exist, verb allow-listed, points inside `ground_half_extent` and finite, path length and queue length capped, rejections returned as reason values; `MapConfig.validate()` bounds all new data (unit counts, squad cap guard, non-finite floats); replay CLI keeps its scenario-name allowlist (add `army`, never a path argument) |
| V6 Cryptography | no | `String.sha256_text()` for digests only (integrity, not secrecy); asset zip hashes recorded |
| V10/V12 Files and resources | yes | No new file I/O at runtime; the downloaded Kenney zip is untrusted data: extracted to a scratch directory, only listed PNGs plus `License.txt` copied, `.url` files excluded, hash recorded |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Resource exhaustion through huge squads, queues or patrol paths | Denial of service | Squad size, order-queue (9) and patrol point caps validated in data and in the intent; `MAX_ENEMIES_PER_NIGHT`-style guard constant for units |
| NaN or infinite floats in new data (speed, radius, cooldown) making units never arrive or fire every tick | Tampering / DoS | `validate()` reports non-finite and non-positive values like the existing enemy checks (`_validate_enemy` pattern); `SimClock.ticks` already saturates |
| Non-deterministic command timing from frame order | Repudiation (replay integrity) | Intents carry only ints; `squad_ordered` is in the digest; the double-run test proves it |
| Supply chain: tampered asset download | Tampering | `curl --fail`, no redirects, sha256 compared with the recorded value before extraction; CC0 licence text kept with the files |
| Script runtime error exits 0 in CLI runs | Spoofing of a pass | Existing sentinel-line rule in `replay.sh`/`playtest.sh` |

## Sources

### Primary (HIGH confidence)
- Repository files read this session: `03-CONTEXT.md`, `03-UI-SPEC.md`, `02-RESEARCH.md`, `.claude/CLAUDE.md`, `project.godot`, `simulation/night/*` (night_sim, enemy_system, target_query, pending_hits, tower_system), `simulation/king/king_state.gd`, `simulation/run/*`, `simulation/commands/*`, `simulation/buildings/building_system.gd`, `simulation/defs/*`, `simulation/events/sim_events.gd`, `simulation/clock/sim_clock.gd`, `data/**`, `input/*`, `ui/hud/hud.gd` + `hud.tscn`, `presentation/{map,king,camera,enemies,vfx,buildings}`, `tools/replay/*`, `tools/*.sh`, `tests/support/*`, `tests/unit/test_input_map.gd`, `test_sim_rules_guard.gd`, `tests/integration/test_balance_acceptance.gd`, `.gdlintrc`, `.gutconfig.json`, `.gitattributes`, `ASSETS.md`, `assets/attribution.json`.
- Engine probes run on the pinned 4.7.2-stable console binary with scratch projects outside the repository (scratchpad `probe_proj` to `probe5_proj`): action matching with modifiers, `action_press` vs `parse_input_event`, mouse and joypad events through `_unhandled_input`, camera ray round trip, stretch-mode coordinate spaces at three window sizes, default `mouse_filter` values and STOP/PASS behaviour, `var_to_str` of input events, key/joy constants.
- `bash tools/replay.sh --scenario=smoke --expect-file=tests/golden/smoke.json` run this session (REPLAY_OK, digest matches).
- https://kenney.nl/assets/input-prompts and the downloaded `kenney_input-prompts_1.5.zip` (listing, `License.txt`, tile palette analysis); the re-downloaded `kenney_mini-characters.zip` (hash identical to the log; GLB animation list parsed).
- https://docs.godotengine.org/en/stable/classes/class_input.html, `class_inputevent.html`, `class_camera3d.html`, `class_plane.html`, `class_multimesh.html` (quoted where used).

### Secondary (MEDIUM confidence)
- Kenney's own knowledge base and itch listing surfaced by web search (PNG and SVG, default 64 px and double 128 px): consistent with the zip contents inspected directly.

### Tertiary (LOW confidence)
- None used for a decision; unknowns are in the Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - engine built-ins plus the existing toolchain; asset pack inspected directly.
- Architecture: HIGH - every integration point read in code; the two genuinely new mechanisms (day-phase step, unit target kind) follow existing patterns.
- Input behaviour: HIGH - probed on the pinned engine; real-window stretch behaviour is the one ASSUMED item (A9).
- Pitfalls: HIGH for the repo-specific ones (verified against files), MEDIUM for balance-related ones.
- Numbers (units, slam, plots, keys, pad layout): MEDIUM/LOW by design; all data, retuned by the bots and the owner.

**Research date:** 2026-10-09
**Valid until:** 2026-11-08 (30 days; the engine pin and the Kenney zip hash are the only fast-moving parts)
