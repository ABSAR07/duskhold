# Phase 3: King Combat & Troops - Context

**Gathered:** 2026-10-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 gives the king an army and the player full control over it. Two new military buildings on the prototype map, a Barracks (melee squad) and an Archery Range (ranged squad), produce squads that fight on their own near their post, committing to targets instead of flip-flopping (UNIT-04), trickle back during the night and are fully restored at dawn (UNIT-07). The player commands whole squads through an RTS-style command layer: follow the king, hold, rally to the king, move, attack-move and patrol, with box selection and numbered control groups on keyboard and mouse and squad cycling with a right-stick cursor on the gamepad (UNIT-05, UNIT-06 and the new UNIT-09, UNIT-10). The king's sword gains its active ability, a slam around him on a visible cooldown (KING-04), and his health regenerates after a short time without taking damage (KING-05). Every in-run action works on keyboard and mouse and on gamepad, switching at any moment with glyph prompts that follow the active device (INPT-01, INPT-02). The in-run HUD is complete: gold, night N of total, king health, ability cooldown and unit group status, with the centre of the screen kept clear (UI-01).

The night counts signed off in Phase 2 are retuned with the balance bots once squads exist, and the phase ends in the owner's feel check through `/gsd-verify-work`, as before.

**Not in this phase:**
- hundreds of units, batched simulation and rendering, walls and barricades, flow-field pathing (Phase 4)
- Castle Center upgrades, branching upgrade cards, other economic buildings (Phase 5)
- the wider enemy roster, unit counters and special roles (UNIT-08), tower specializations, the Hero's Quarter (Phase 6 onwards)
- further weapons, the loadout screen, perks and mutators (meta phases)
- the art cohesion pass and SFX (Phase 8)
- scoring, retrying a failed night, saves (Phase 9)
- menus, settings and the rebinding UI (Phase 13)

</domain>

<decisions>
## Implementation Decisions

### Carried Forward (locked before this discussion — do not re-litigate)
- Stack, the simulation / presentation / data split, `.tres` content referenced by id, the command/intent layer, the event bus, CC0-only assets with the attribution log, as recorded in `01-CONTEXT.md`.
- One building type per fixed plot (Phase 1 D-02), linear tiers (D-10), the tight starting economy (D-09), no gold from kills. Every tunable number lives in `.tres` data, never in code.
- Ride-up-and-hold building and upgrading, exactly as validated in the Phase 1 and Phase 2 sign-offs. The reversal of the mouse decision (D-11 below) touches unit commands only; building never uses the mouse and there are no mouse-aimed king attacks.
- The deterministic fixed-step simulation (`SimClock` 1/30 s, seeded RNG, integer event recorder, golden replays, bot playtests) and the rule that nothing under `simulation/` reads wall-clock time, the OS or the time scale (Phase 2 DR-1 to DR-10). Player commands enter the simulation as intents stamped on ticks, like `BuildIntent` and `StartNightIntent` today, so a recorded run replays identically.
- The king's shipped numbers (50 hp, passive 5 damage every 0.7 s at 3 m, walk 7.5 m/s, sprint 12 m/s) and the knockout and respawn rules (Phase 2 D-01 to D-06: countdown 6 s + 4 s per knockout, capped at 15 s, no cost beyond the time, full health on respawn). Phase 2 D-05 ("health returns only at dawn or through a respawn") is superseded by D-20 below, as Phase 2 anticipated.
- Enemies attack the nearest thing in their path, commit to a target with staggered rescans, and are pushed apart when they overlap (Phase 2 D-11 and the `EnemySystem` pattern). Squads reuse the same targeting discipline.
- Hurt-only health bars, the results screen, the fast-forward toggle and the castle attack from the Phase 2 gate stay as they are.

### Squads & Military Buildings
- **D-01:** **Two new building types: the Barracks produces the melee squad, the Archery Range the ranged squad.** Each has **three linear tiers** and the squad cap grows **4 → 8 → 14**. The owner's rule for the top tier: tier 3's increase from tier 2 is proportionally smaller than tier 1 to tier 2 (+75 % against +100 %) but larger in magnitude (+6 units against +4), so the last upgrade is still clearly the strongest.
- **D-02:** **Costs follow Thronefall's doubling line, 4 → 8 → 16 gold.** The first squad is a real day-1 trade-off against two Houses. The exact numbers are data and may move in the bot retune (D-08).
- **D-03:** **The two military plots are added to the prototype map, one per building, near the castle and inside the tower ring.** The eight existing plots and their balance data are not touched. The map has ten plots afterwards. — **Reversibility:** costly — the prototype map is the permanent test and replay sandbox (Phase 1 D-04); changing its plots regenerates the golden replays and shifts every balance number measured on it.
- **D-04:** **A squad without orders guards its post.** Units idle at their building, engage enemies that come inside a short guard radius, commit to their target the way enemies do (Pitfall 5), and walk back to the post once nothing is near. By day they stand at the post. Hold, rally, move and patrol (D-09) change where "the post" is for the rest of the run (D-14).
- **D-05:** **Dead units trickle back during the night at one unit per 10 s at tier 1, 7 s at tier 2 and 4 s at tier 3**, spawning at the building; **at dawn every squad is instantly back to full** (UNIT-07). A squad that is following or holding away from its post gets its replacements at the building, and they walk to the squad.
- **D-06:** **The classic pair.** Melee units are the sturdier ones and stand in the enemy's path, a buffer in front of buildings; archers are fragile, outrange the melee grunt and fire visible arrows like the towers do. Counters and special roles wait for Phase 6 (UNIT-08).
- **D-07:** **A single unit is weak: about a fifth of the king's health and damage.** A full tier-1 squad roughly matches the king, so the king stays the hero and squads are the wall.
- **D-08:** **The night counts are retuned in this phase with the balance bots.** With squads in play the authored counts rise until the balanced bot still wins 7 or 8 of 10 seeds (the Phase 2 bar). The bots measure; the owner judges feel in the UAT, as in Phase 2 D-18.

### Unit Commands (squad control layer)
- **D-09:** **Commands are given to whole squads, never to single units.** The verbs: **follow** the king; **hold** (freeze where they stand, fight inside the guard radius of that spot, return to it after a fight); **rally to the king** (walk to where the king stands now and hold there); **move** (walk to a ground point ignoring enemies on the way, then resume the autonomous stance of D-04 at that spot, without holding unless hold is pressed or queued); **attack-move** (walk to a ground point, engaging anything met on the way); **patrol** (walk a path back and forth, engage what comes close, resume the path when it is dead). Return-to-post is the stance a squad has before any order. **Shift queues commands**, so "move here, then hold" is one gesture.
- **D-10:** **Custom control groups, Age of Empires style.** On keyboard and mouse, left click selects a squad, dragging a box selects every squad it touches, Ctrl adds to the selection, **Ctrl + 0 to 9 stores the current selection as a group and the bare number recalls it**, Tab cycles through the squads. On the gamepad the player cycles through the squads and assigns them to a group with a modifier; there is no pointer-style selection on the pad. Select-all and select-one-type remain available as built-in selections, so UNIT-06 ("all units or one unit type") holds inside the richer scheme. The whole system ships in this phase with the two squads the map has.
- **D-11:** **The mouse returns to runs for unit commands.** This reverses the 2026-09-28 decision "mouse for menus only" (PROJECT.md, REQUIREMENTS.md INPT-03, the dropped "mouse unit commands" row). The owner: "mouse use is kind of a necessity now i realize in hindsight." The mouse selects squads, stores groups, and supplies the ground point of move, attack-move and patrol. Building stays hold-only and the king's attacks stay automatic. — **Reversibility:** costly — it changes a project-level constraint, the Out of Scope table, INPT-01 and INPT-03, and every later menu, prompt and rebinding decision assumes a pointer exists during a run.
- **D-12:** **Gamepad parity through cycling and a cursor.** The command verbs sit on the D-pad (the owner's choice) with the remaining verbs on chords the planner picks; holding a command button that needs a ground point shows a **right-stick ground cursor**, released to confirm. Switching device mid-run keeps the current selection and groups.
- **D-13:** **The camera stays locked on the king while the mouse is in use.** Mouse points and box selections are projected onto the visible ground; anything off-screen needs the king to ride closer. The Phase 1 follow camera is unchanged.
- **D-14:** **Stances persist across dawn.** A held, patrolling or following squad stays that way day after day until the player changes it; dawn restores numbers only. Replacements (D-05) join the squad wherever it is.
- **D-15:** **Keyboard defaults are the classic RTS letters:** F follow, H hold, R rally, A attack-move, P patrol, Tab cycle the selection, Ctrl + click add to the selection, Ctrl + 0..9 store a group, 0..9 recall it, right click move. Fast-forward moves off F to a key the planner picks. Everything stays in the Input Map with both device bindings, rebindable in Phase 13.
  - Amended 2026-10-10 at the 03-07 checkpoint: keep A; while a squad is selected all movement input goes to the selection and the king does not move; the king is the implicit selection when nothing is selected; Escape clears the selection.
- **D-16:** **A selected squad shows a coloured ground ring under each of its units and a highlighted slot in the HUD group status**, with the stored control-group number on the slot.

### King Weapon, Active Ability & Regeneration
- **D-17:** **The king starts with a sword:** the shipped melee passive stays exactly as signed off, and the active ability is a **slam, a circular strike around the king that hits every enemy within a few metres.** It needs no aiming and reads the same on both devices.
- **D-18:** **Weapons are data from now on.** A `WeaponDef` resource holds the passive numbers (range, damage, interval) and the active's (radius, damage, cooldown); the king reads its equipped weapon from it. One weapon ships; the roster and the loadout screen come in the meta phases.
- **D-19:** **The slam's cooldown is about 9 s and the ability can be used at any time**, by day too (it simply hits nothing), so the timing can be learned. The HUD shows a radial fill and a ready flash (D-22).
- **D-20:** **Health regenerates Thronefall-style: about 1 s after the last hit taken, 10 % of max health per second until full**, by day and by night. Both values are data. Knockout and respawn (Phase 2 D-01 to D-06) are unchanged; a respawn still returns full health.

### HUD & Device Prompts
- **D-21:** **Corners, centre kept clear.** Gold top-left (as today), "Night N of 8" top-centre by day (the night banner keeps its place at night), king health and the ability bottom-left, unit group slots bottom-centre, the start-night prompt where it is. Nothing sits in the middle of the play area.
- **D-22:** **King health is a horizontal bar with the number ("38 / 50") beside a sword icon that fills clockwise as the cooldown runs and flashes when ready.** Matches the hurt-only bars in the world.
- **D-23:** **One group slot per squad:** unit icon, "alive / max", a small stance glyph (post, follow, hold, patrol, attack-move), the stored control-group number, a highlight when selected, and a thin fill that shows a replacement on its way.
- **D-24:** **Prompts use button and key glyphs** from a CC0 prompt pack (Kenney Input Prompts, recorded in the attribution log) instead of the text names. **Any press or stick movement on the other device switches every prompt at once; mouse input counts as keyboard.** This supersedes the Phase 1 "Known limitation" of Xbox-only text labels for the actions that get glyphs.

### Scope Amendment (owner decision 2026-10-09)
- **D-25:** **Phase 3 scope extends beyond the written UNIT-05 and UNIT-06.** Control groups, move, rally, attack-move, patrol, Shift-queued commands and mouse selection all ship in this phase. The owner confirmed the amendment of ROADMAP success criterion 2 and REQUIREMENTS.md (UNIT-05 and UNIT-06 reworded, new UNIT-09 and UNIT-10, INPT-01 and INPT-03 reworded) alongside this context, so verification checks for them.

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` — "Phase 3: King Combat & Troops": goal, mode `mvp`, the five success criteria (criterion 2 amended per D-25); "Phase 4: Crowd-Scale Battles & Walls" for what Phase 3 must not pre-empt (batched units, walls, flow fields)
- `.planning/REQUIREMENTS.md` — KING-04, KING-05, UNIT-04 to UNIT-07, UNIT-09, UNIT-10, INPT-01, INPT-02, UI-01; the amended "Controls scheme" note under `### Input`; the Out of Scope table (mouse unit commands row amended)
- `.planning/PROJECT.md` — core value, constraints (platform constraint amended per D-11), Key Decisions (the controls row and the Phase 2 tuning row)

### Prior decisions
- `.planning/phases/01-foundation-day-loop/01-CONTEXT.md` — D-02 one type per plot, D-03 map size as amended, D-04 the sandbox map, D-09 and D-10 economy and tiers, D-11 the start-night hold, the camera and default-binding discretion
- `.planning/phases/02-night-defense-playtest-gate/02-CONTEXT.md` — D-01 to D-06 knockout and respawn, D-11 to D-13 enemy and tower behaviour, D-18 the delegated playtest gate
- `.planning/phases/02-night-defense-playtest-gate/02-RESEARCH.md` — the determinism rules DR-1 to DR-10 and the fixed-step architecture every new system must obey
- `.planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md` and `02-PLAYTEST-GATE.md` — the Phase 2 bar (balanced bot 7 or 8 of 10) and the owner's feel decisions
- `.planning/STATE.md` — accumulated decisions; the review-ledger note

### Research
- `.planning/research/FEATURES.md` §"The King" (weapons, regen), §"Units" (production, respawn, commands), §"UI/UX" (HUD, controller-first origin)
- `.planning/research/ARCHITECTURE.md` — Pattern 5 (data-oriented units; Phase 4 does the MultiMesh switch, Phase 3 must keep unit data in the manager so that switch does not change the simulation), Pattern 7 (intents: `HoldPositionIntent`, `FollowKingIntent`, `ActivateAbilityIntent`), the Unit/Squad and Input layer rows
- `.planning/research/PITFALLS.md` — Pitfall 3 (night readability), Pitfall 4 (jamming; the stress test is Phase 4), Pitfall 5 (target-selection thrash, the committed-target rule)

### Assets
- `ASSETS.md` and `assets/attribution.json` — the attribution log format every new CC0 asset (unit models, the prompt glyph pack) must follow

No external specs or ADRs exist beyond these.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `simulation/night/enemy_system.gd` and `target_query.gd`: committed targets with staggered rescans, the straight-line step and the push-apart pass; the model for a friendly `UnitSystem` or `SquadSystem` (ids that only grow, Vector2 XZ positions, iteration in id order).
- `simulation/night/night_sim.gd`: the fixed night step order (spawn, king, towers, castle, enemies, hits, dead). Squads get their own slot in it; the day loop needs a step too, since commands and regeneration work by day (D-14, D-19, D-20).
- `simulation/night/pending_hits.gd` and `castle_attack.gd` / `tower_system.gd`: projectile flight ticks and the hit queue the archers reuse; `SimClock.flight_ticks` for arrow timing.
- `simulation/king/king_state.gd`: the king's health and passive attack; the natural home of regeneration and the ability cooldown. `KingDef` keeps movement; the combat numbers move to `WeaponDef` (D-18).
- `simulation/defs/enemy_def.gd` and `building_tier_def.gd`: the field shape for a `UnitDef` (health, speed, radius, ranges, intervals, projectile speed) and for squad cap and respawn interval per tier.
- `simulation/commands/command_processor.gd` with `build_intent.gd` and `start_night_intent.gd`: the intent pattern every command verb follows; rejected intents return values, never `push_error`.
- `input/build_hold_controller.gd`, `start_night_hold_controller.gd`, `fast_forward_controller.gd`: controller precedent (fixed-delta stepping in tests, `Input.action_press` in scripted runs, the Engine.time_scale single-writer scan).
- `ui/hud/hud.gd` and `hud.tscn`: gold, start-night prompt with device-named hints, night banner, respawn countdown, fast-forward label, dawn payout; `PAD_BUTTON_NAMES` / `AXIS_NAMES` are the text labels D-24 replaces with glyphs.
- `presentation/vfx/health_bar_3d.gd`, `projectile_vfx.gd`, `xray_silhouette.gd`: hurt-only bars, arrows and the ghost silhouette, reusable for units.
- `presentation/enemies/enemy_views.gd`: puppets interpolated from previous to current positions; the shape unit views follow.
- `tools/replay/` (`playtest_bot.gd`, `playtest_strategies.gd`, `balance_report.gd`, `replay_cli.gd`): the bots and the report the D-08 retune runs through; `tools/screenshot/` for HUD and night readability checks.
- `assets/third_party/kenney_mini_characters/`: the rider model pack, first choice for unit models.

### Established Patterns
- Simulation code is `RefCounted`, positions are `Vector2` on XZ, time is integer ticks, randomness only through the seeded night stream; presentation never writes the sim.
- Every number is data; contract tests pin shipped values to the decisions; `MapConfig.validate()` reports bad data instead of letting it arm anything.
- Each test script stays under the gdlint cap of 20 test functions; lines are at most 100 characters; static typing everywhere.
- Scripted real-window runs (`tools/godot.sh` with `Input.action_press`) and screenshots are how the agent checks what it cannot see; the owner is asked only for feel.
- The replay goldens (`tests/golden/smoke.json`, `full_idle`) must either hold or be regenerated deliberately with the reason recorded.

### Integration Points
- `data/maps/prototype_map.tres`: two new `BuildSpotDef` entries (D-03) and the retuned night counts (D-08); `MapConfig.validate()` grows the squad fields.
- `data/buildings/`: `barracks.tres`, `archery_range.tres` with per-tier squad cap and respawn interval; `data/units/`: the two `UnitDef` files; `data/king/`: the `WeaponDef` for the sword.
- `project.godot` Input Map: the new actions with keyboard, mouse and gamepad events (D-15, D-12); `fast_forward` rebinds off F.
- `RunManager` and `RunContext`: day and night stepping of squads, regeneration and the ability; `RunContext` already exposes unit counts (0 today) to the overlay.
- `ui/hud/`: the king widget, group slots and glyph prompts; `ui/overlay/debug_overlay.gd` gets a squads section.
- `tests/support/sim_signals.gd`: every new `SimEvents` signal must be listed or the drift guard fails.

</code_context>

<specifics>
## Specific Ideas

- The owner on squad caps: "make it 4 -> 8 -> 14 over 3 tiers. Tier 3's increase from Tier 2 should be proportionally smaller than t1 to t2, but still substantially stronger magnitude wise as compared with tier 2."
- On commands: "Need a full Age of Empires type command structure, with custom control groups being possible. commands to be given and followed by entire squads at once though, not separately for each unit."
- On patrol: the squad "patrols a movement path back and forth and attacks as if attack move is used so if enemies come close, the squad engages them, but as soon as the enemies are done with, the squad gets back to patrolling the movement path."
- On selection: "Ctrl + select a squad or mouse select should be able to capture multiple squads, and then assigning a control group for them should be easy through Ctrl + any number 0 through 9. For the controller, I should be able to cycle the squads and assign them to a control group as I deem fit since mouse-like selection is probably not ideal for the controller."
- On the mouse: "yes reverse the decision, mouse use is kind of a necessity now i realize in hindsight."
- On right click: "Move but doesn't 'hold' there unless i then press the hold key (or queue it with shift)."
- On scope: "build it all now."
- The owner prefers Claude to check what can be measured with scripted real-window runs and the bots, and to be asked only for feel judgments and decisions.

</specifics>

<deferred>
## Deferred Ideas

- Unit counters and special roles (UNIT-08), the Hero's Quarter and the 1-of-4 unit choice per military building — Phase 6 and the content phases.
- More weapons, the loadout screen, perks and mutators — the meta phases; `WeaponDef` (D-18) is the groundwork.
- Walls, flow-field pathing, the 200-unit stress test and the MultiMesh switch — Phase 4.
- Glyphs for non-Xbox gamepads and the rebinding UI — Phase 13.
- Camera edge-scroll or drag while commanding — rejected for now (D-13); revisit only if the owner finds the locked camera limiting in the UAT.

</deferred>

---

*Phase: 03-king-combat-troops*
*Context gathered: 2026-10-09*
