# Phase 4: Crowd-Scale Battles & Walls - Context

**Gathered:** 2026-10-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 makes nights scale to Thronefall-size battles and gives the player walls. Hundreds of enemies, units and projectiles run on the fixed-step simulation and are drawn through batched (MultiMesh) rendering at 60 fps on GTX 970-class hardware (PLAT-01). A new Wall building, bought as a whole pre-drawn run of segments on a wall plot, blocks everyone on the ground and upgrades linearly in health (BLDG-10). Enemies path to their targets around walls through the gaps, or break through a segment when the smart break-or-detour rule says that is faster, and never jam indefinitely at a gate (ENMY-04); the flow field and stuck enemies are visible in the debug overlay. A headless stress test sends 200+ enemies through a single gate with zero permanently stuck agents, and a scripted real-window stress night with 300 enemies, 50 units and 200 projectiles on screen is measured and reported against a documented frame-time budget. The nights of Phases 1 to 3 keep their outcomes across the switch, every existing headless test still passes, and the goldens are regenerated once, deliberately, for the new pathing.

The prototype map gains four wall plots (three road runs and an inner ring). The balance bots learn to buy walls and the night counts move only if the Phase 2 bar breaks. The phase ends in the owner's feel check through `/gsd-verify-work`, as before.

**Not in this phase:**
- the wider enemy roster, flying enemies that ignore walls, siege enemies that target buildings first, tower specializations (Phase 6); this phase only leaves the passability hooks they need
- Castle Center upgrades, branching upgrade cards, other economic buildings (Phase 5)
- unit counters, the Hero's Quarter, the 1-of-4 unit choices (Phases 6 and 7)
- the art cohesion pass, SFX and the night readability pass (Phase 8); wall models here are placeholders or Kenney Castle Kit pieces
- scoring, retry, saves (Phase 9); menus and settings (Phase 13)
- any gamepad work (owner decision 2026-10-16: keyboard and mouse only)

</domain>

<decisions>
## Implementation Decisions

### Carried Forward (locked before this discussion — do not re-litigate)
- Stack, the simulation / presentation / data split, `.tres` content referenced by id, the command/intent layer, the event bus, CC0-only assets with the attribution log (`01-CONTEXT.md`).
- One building type per fixed plot (Phase 1 D-02), linear tiers (D-10), every tunable number in `.tres` data, never in code. The free dawn rebuild of destroyed buildings (LOOP-04).
- The deterministic fixed-step simulation (`SimClock` 1/30 s, seeded RNG, integer event recorder, golden replays, bot playtests) and the rule that nothing under `simulation/` reads wall-clock time, the OS, the scene tree or the time scale (Phase 2 DR-1 to DR-10). Presentation never writes the simulation.
- The prototype map is the permanent sandbox (Phase 1 D-04); its ten existing plots, their positions and their balance data are not moved (Phase 3 D-03).
- Enemies commit to a target with staggered rescans; squads use the same discipline; the push-apart pass is `Separation.displacements`, shared by both systems (Phase 2 D-11, Phase 3 03-01).
- Ride-up-and-hold building, the squad command layer, the HUD and the king's numbers as signed off in Phase 3. Keyboard and mouse only; the shipped pad code stays unsupported and untouched.
- The Phase 2 balance bar: the balanced bot wins 7 or 8 of seeds 1 to 10; the bots measure, only the owner judges fun.

### Walls: plots, tiers and blocking
- **D-01:** **One plot buys a whole wall run.** A wall plot carries a pre-drawn line of wall segments with authored gaps; holding the action key at the plot builds every segment of the run at once, and an upgrade raises every segment. The gaps are authored in map data and never move; the player's choice is which runs to buy and when to upgrade them, not where the gates are. — **Reversibility:** costly — the wall data schema (a run of segments per plot), the flow-field obstacle set and every map authored from here on assume runs with authored gaps; switching to per-segment plots would need a new plot kind and a data migration per map.
- **D-02:** **A run is made of segments, each with its own health.** Enemies attack one segment and break a hole in it while the rest of the run stands. The run's tier sets each segment's max health; `BuildingSystem` keeps one instance per plot and the wall data adds per-segment health inside it (or a sibling system the planner names).
- **D-03:** **The barricade is tier I of the Wall.** One building type, `wall`, with **three linear tiers**: tier I barricade (cheap, low health, wooden look), tier II stone wall, tier III reinforced wall. Only health rises per tier; the run's shape and its gaps never change. Costs are data on Thronefall's scale (research: barricade cheap, wall roughly 3 to 7 gold) and may move in the bot measurement (D-15).
- **D-04:** **A wall run blocks everyone on the ground**: enemies, squads and the king. Only the authored gaps let anyone through, so gate placement matters for the king's own routes. The flow field (and the king's movement) treat intact segments as solid.
- **D-05:** **A broken segment is a hole open to everyone until dawn.** It passes enemies, squads and the king like an authored gap; the field rebuilds when a segment falls or is rebuilt. Dawn rebuilds broken segments free, as LOOP-04 does for buildings (walls pay nothing, so the rebuilt marker is moot). Rubble at a hole is visual only and never blocks.
- **D-06:** **Four wall plots on the prototype map: three outer road runs and one inner ring.** One run across each of the west, east and north roads between the towers (55 m) and the spawn points (66 m), each with an authored gap on the road, plus a ring run around the castle with gaps toward the three roads. The ten existing plots stay where they are. — **Reversibility:** costly — the prototype map is the permanent sandbox; adding plots regenerates the goldens (D-14) and every balance number measured afterwards assumes these four runs.

### Enemy behaviour at walls
- **D-07:** **Enemies are smart about walls: break through or go around, whichever is faster.** For a wall segment that has enemies aggroed onto it, the simulation computes a *time to destruction*: the segment's current health divided by the combined damage per second of every enemy aggroed onto that segment and the segments near it. It compares that with the *detour time*: how long the enemy would take to reach its target through the nearest open gap. If breaking through is faster the enemies attack the segment; otherwise they walk around. A sealed target (no open path at all) has an infinite detour, so sealed enemies always attack.
- **D-08:** **The wall decision is computed per segment on a coarse cadence, not per enemy per tick.** Only segments with aggroed enemies are evaluated, about every 0.5 s of simulation time (whole ticks from data, staggered the way rescans are), and the resulting time to destruction is published as one signal that every nearby enemy reads. The evaluation is deterministic and integer-tick scheduled like every other sim rule.
- **D-09:** **A stuck enemy is one that has made no progress toward its goal for N seconds while not attacking anything.** N is data (about 3 s). The headless gate stress test (200+ enemies through one gap) fails on any enemy still stuck at its end; the debug overlay flags stuck enemies in a distinct colour, beside the flow-field directions.

### Scale: rendering and the stress bar
- **D-10:** **The stress night must hold 300 enemies, 50 units and 200 projectiles on screen at once** at 60 fps on GTX 970-class hardware. The per-night cap of 300 stands for shipped maps; the stress scene is allowed what it needs.
- **D-11:** **The stress scene is a tools-only stress map** under `tools/` (export-excluded, like the hold-pacing sandbox): one long wall with a single gate and one huge night. The prototype map, its goldens and its balance data are untouched by the stress work except for the wall plots of D-06.
- **D-12:** **Frame time is measured in a scripted real-window run and committed as a report.** The owner's dev machine has a modern discrete GPU well above a GTX 970, so the documented budget on it is a frame time held under about 8 ms at 1080p (2x headroom on 16.7 ms) with the scaling assumption written down. The tools script runs the stress night for a fixed duration, captures per-frame times and writes a report (p50, p95, worst 1 percent) that is committed as the documented budget. CI runs only the headless gate stress test; no frame-time check runs in CI.

### Goldens, order of work and balance
- **D-13:** **The rendering switch lands first, with every golden byte-identical across it.** The MultiMesh view layer is its own step; `smoke`, `army` and `full_idle` must keep their digests through it, proving presentation never touched the simulation. Only then does pathing land.
- **D-14:** **The pathing change regenerates the goldens once, deliberately, with a before/after outcome report.** Success criterion 4 ("nights play the same") is read as the same outcomes (win or loss, nights survived, kills within a stated band per seed), not the same digests. The regeneration is one commit with the report beside it and the reason recorded.
- **D-15:** **The bots learn to buy walls; night counts move only if the bar breaks.** The balanced and army bots buy the wall runs as part of their build orders; the balance report shows wins over seeds 1 to 10 with and without walls. If the balanced bot still wins 7 or 8 of 10, nothing moves. If walls push it to 9 or 10 of 10, raise the counts the Phase 3 way (group counts only, no locked value). The owner judges feel at the UAT.

### Claude's Discretion
- The pathing technique behind D-07 (a flow field per goal on a grid built from the map's obstacles is the research recommendation; `NavigationServer3D` may bake the walkable grid but per-agent avoidance nodes are not used), the grid resolution, how the field is rebuilt when a segment falls or returns, and how the king's movement respects walls (the king is presentation-driven today; the planner decides where the solid test lives).
- How "aggroed to a segment" is defined, which segments count as near, and the exact DPS and detour arithmetic of D-07, kept integer-tick and deterministic.
- The MultiMesh design: one MultiMesh per archetype (grunt, skirmisher, footman, archer, arrow), per-instance custom data for the hit flash, how hurt-only health bars, selection rings, order markers and death puffs behave at hundreds of instances, and what the 256-view cap becomes. Verified with night screenshots.
- Segment length, run geometry and gap width on the prototype map within D-06, the wall's look (Kenney Castle Kit pieces are the first choice, logged in `ASSETS.md`), how the hold label names a run ("Wall II: 12 segments, 80 health each" or similar), and how a broken segment collapses.
- Wall costs and health per tier within D-03, the N of D-09, the 0.5 s cadence of D-08, all as data.
- The stress map's shape, the gate test's pass metrics beyond zero stuck (for example median time to reach the castle), and the overlay's frame-time and field readouts.
- How the bots decide when to buy walls, and the order of plans. Suggested shape: MultiMesh views first (D-13), then the wall building and map plots on straight-line pathing, then the flow field and the smart rule with the gate test, then the stress map and report, then the bot measurement and the gate.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` — "Phase 4: Crowd-Scale Battles & Walls": goal, mode `mvp`, the four success criteria (criterion 4 read per D-14); "Phase 6: Enemy Roster & Tower Specializations" for the flying and siege behaviour this phase must leave room for
- `.planning/REQUIREMENTS.md` — BLDG-10, ENMY-04, PLAT-01; ENMY-02 and ENMY-03 (later phases, passability hooks only); LOOP-04 (free dawn rebuild applies to wall segments); the 2026-10-16 gamepad amendment under `### Input`
- `.planning/PROJECT.md` — core value, the Performance constraint (GTX 970 / 4 GB, 60 fps with hundreds of units), Key Decisions (determinism row, gamepad row)

### Prior decisions
- `.planning/phases/01-foundation-day-loop/01-CONTEXT.md` — D-02 one type per plot, D-04 the sandbox map, D-09 and D-10 economy and tiers
- `.planning/phases/02-night-defense-playtest-gate/02-CONTEXT.md` — D-11 to D-13 enemy and tower behaviour, D-18 the delegated playtest gate
- `.planning/phases/02-night-defense-playtest-gate/02-RESEARCH.md` — determinism rules DR-1 to DR-10
- `.planning/phases/03-king-combat-troops/03-CONTEXT.md` — D-03 the military plots, D-04 to D-09 squad stances and orders (squads must obey walls, D-04 here), D-26 to D-28 the balance bar and the retune method
- `.planning/phases/03-king-combat-troops/03-BALANCE-REPORT.md` and `03-PLAYTEST-GATE.md` — the current counts, the bots' win rates and the owner's accepted assumptions
- `.planning/STATE.md` — accumulated decisions; the Phase 4 research flag (validate MultiMesh and flow fields empirically on Godot 4.7)

### Research
- `.planning/research/ARCHITECTURE.md` — Pattern 3 (storage swappable for packed arrays), Pattern 5 (data-oriented units, MultiMesh per archetype, manual overlap), Pattern 6 (flow field per goal; NavigationServer only to build the grid; no per-agent RVO at crowd scale)
- `.planning/research/PITFALLS.md` — Pitfall 4 (jamming at gates; the 200-unit headless stress test with stuck-count pass/fail), Pitfall 3 (night readability under clutter), Pitfall 5 (committed targets), Pitfall 8 (agent blindness)
- `.planning/research/FEATURES.md` §"Buildings" (Wall: linear health tiers; Barricade: the cheap variant) and the feature table row "[BLDG] Walls/barricades"
- `.planning/research/STACK.md` — MultiMesh and NavigationServer rows, the Forward+ renderer note and the GDExtension escape hatch for a profiled hot path

### Assets
- `ASSETS.md` and `assets/attribution.json` — the attribution log every new CC0 asset (wall pieces) must follow

No external specs or ADRs exist beyond these.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `simulation/night/enemy_system.gd`: `desired_step` is the one steering seam, already marked for the flow-field sample; `_advance_and_strike` walks and strikes, `_choose_target` and `_target_valid` hold the committed-target rule the wall target kind joins; `is_rescan_tick` is the staggering pattern D-08 reuses. `simulation/squads/squad_system.gd` calls the same `desired_step` (lines 548 and 601), so squads follow the field for free.
- `simulation/squads/separation.gd`: the shared push-apart pass; stays as the local separation beside the field.
- `simulation/buildings/building_system.gd` and `building_instance.gd`, `simulation/defs/building_def.gd`, `building_tier_def.gd`, `build_spot_def.gd`: the per-plot instance, tier ladder and plot schema the wall run extends (a run of segments per plot, per-segment health).
- `simulation/night/night_sim.gd`: the fixed step order (king, squads, towers, castle, enemies, hits, dead); the wall evaluation of D-08 gets its slot.
- `simulation/night/pending_hits.gd`: the hit queue; wall segments become a hit target kind.
- `presentation/enemies/enemy_views.gd` and `presentation/units/unit_views.gd`: the puppet views (one Node3D each, per-view materials for the flash, MAX_VIEWS 256) that the MultiMesh views replace; `presentation/vfx/projectile_vfx.gd` for arrows.
- `presentation/debug/enemy_path_gizmo.gd` and `ui/overlay/debug_overlay.gd`: the ImmediateMesh line gizmo and `register_section`, extended with field directions, wall decisions and stuck flags.
- `tools/replay/` (`playtest_bot.gd`, `playtest_strategies.gd`, `balance_report.gd`, `replay_cli.gd`) and `tests/golden/`: the bots, the report and the goldens of D-13 to D-15.
- `tools/sandbox/hold_pacing_sandbox.gd`: the precedent for a tools-only, export-excluded scene (D-11). `tools/screenshot/shot_runner.gd` and `tools/godot.sh`: scripted real-window runs for the frame-time report (D-12).
- `assets/third_party/`: Kenney Castle Kit (wall pieces) already logged.

### Established Patterns
- Simulation code is `RefCounted`, positions are `Vector2` on XZ, time is integer ticks, randomness only through the seeded night stream; ids only grow; iteration in id order.
- Every number is data; contract tests pin shipped values; `MapConfig.validate()` reports bad data instead of letting it arm anything.
- gdlint caps: 20 public methods per class (`UnitSystem`, `KingState` and `BuildingSystem` are at or near it, so new writers go in new files), 1000 lines per file, 20 tests per script, 100-character lines, static typing everywhere.
- The goldens hold or are regenerated deliberately with the reason recorded; CI replays smoke, army and full_idle.
- Scripted real-window runs and screenshots are how the agent checks what it cannot see; the owner is asked only for feel.

### Integration Points
- `data/maps/prototype_map.tres`: four `BuildSpotDef` entries for the wall plots with their run geometry (D-06); `MapConfig.validate()` grows wall checks. `data/buildings/wall.tres` with three tiers.
- `EnemySystem` target kinds, `PendingHits`, `SimEvents` (new wall signals must be added to `tests/support/sim_signals.gd` and `SimRecorder.HANDLED` in the same task).
- `RunManager` dawn: segment rebuild joins `_enter_dawn` before the payout.
- `presentation/map/map_root.gd` and `building_views.gd`: wall run views; the king (`presentation/king/king.gd`) must stop at solid segments.
- `ui/overlay/debug_overlay.gd`: field, wall decision and stuck sections; frame-time readout for the stress run.
- `.github/workflows/ci.yml` test job: the headless gate stress test joins the GUT run or the replay step.

</code_context>

<specifics>
## Specific Ideas

- The owner on walls: "I want the enemies to be 'smart'. The enemy calculates how long it would take to bring down the wall with all the enemies which are currently aggroed to wall segments near this enemy, and the wall segment's current health, and compares this to if going around would take longer or not. this would be a hefty calculation so maybe just do it every half second tick or something at the wall segment level for those wall segments which have aggroed enemies and use this 'time to destruction' as a signal for all nearby enemies."
- A run is bought whole but breaks segment by segment: "A run is made of segments, each with its own health."
- The barricade is the first tier of the same wall ladder, not a separate building.
- The owner prefers Claude to check what can be measured with scripted real-window runs and the bots, and to be asked only for feel judgments and decisions.

</specifics>

<deferred>
## Deferred Ideas

- Flying enemies that ignore walls and siege enemies that target buildings first (ENMY-02, ENMY-03) — Phase 6; this phase keeps a per-enemy passability hook open for them.
- A tier that narrows the gaps (rejected option) — not planned; could be a later map gimmick.
- Rebuilding walls for gold by day (rejected option) — not planned; LOOP-04's free rebuild stands.
- A headless sim-step budget check in CI (declined for now) — could be added in Phase 13 if GDScript step cost regresses.
- The night readability pass under hundreds of units — Phase 8 (UI-05), with the screenshots this phase produces as its input.

</deferred>

---

*Phase: 04-crowd-scale-battles-walls*
*Context gathered: 2026-10-16*
