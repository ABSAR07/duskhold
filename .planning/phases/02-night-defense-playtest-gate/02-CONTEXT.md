# Phase 2: Night Defense & Playtest Gate - Context

**Gathered:** 2026-10-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 turns Phase 1's enemy-free placeholder night into a real one on the prototype map. During the day the player sees how many enemies will arrive at each spawn point (LOOP-02) and starts the night with the existing hold-to-confirm input (LOOP-01). At night, enemies spawn in hand-authored waves, damage and destroy buildings (BLDG-07), and are fought by the king's passive auto-attack (KING-03) and by the basic towers. A knocked-out king respawns at the castle after a visible countdown (KING-06). The night ends only when every enemy is dead (LOOP-03). At dawn, destroyed buildings return for free (LOOP-04), surviving Houses pay income and rebuilt ones visibly pay nothing (LOOP-05). The run ends on a results screen: a loss when the castle center falls (LOOP-06) or a win after the final night (LOOP-07).

A seeded scripted night replays with identical results from the command line and in CI (DEV-05), headless GUT tests cover waves, combat and loop transitions, and the debug overlay gains live enemy counts, wave state and enemy paths. The phase ends in the first human playtest gate.

**Not in this phase:**
- troops, unit hotkeys, the weapon's active ability, king health regeneration, device-switching prompts and the full HUD (Phase 3)
- data-oriented scale-up to hundreds of units (Phase 4)
- castle center upgrades, branching upgrade cards, other economic buildings (Phase 5)
- the wider enemy roster, tower specializations and walls (Phase 6)
- the art cohesion pass and SFX (Phase 8)
- scoring, retrying a failed night, and saves (Phase 9)
- main menu and settings (Phase 13)

</domain>

<decisions>
## Implementation Decisions

### Carried Forward (locked before this discussion — do not re-litigate)
- Stack, controls, architecture split (simulation / presentation / data), `.tres` content, command/intent layer and CC0-only assets, as recorded in `01-CONTEXT.md`.
- The start-night hold-to-confirm input already exists (Phase 1 D-11). `RunManager` is the only writer of the loop phase; Phase 2 replaces `_night_should_end` and `_apply_dawn_payout` instead of rebuilding the loop (plan 01-09).
- The prototype map stays the permanent sandbox: 5 House plots, 3 tower plots, the castle center in the middle (Phase 1 D-03, D-04). One building type per spot (D-02). Tiers stay linear (D-10).
- The starting economy is tight (D-09). Enemies drop no gold.
- Every tunable number lives in `.tres` data, never in code (Phase 1 D-09 pattern, `loop_tuning.tres`).

### King Knockout & Respawn
- **D-01:** **The respawn countdown grows with each knockout in the same night, up to a cap of 15 s.** It starts at about 6 s and adds about 4 s per further knockout that night, then stays at the cap. The count resets at dawn.
- **D-02:** **The start value, the step and the 15 s cap are tuning data.** The owner expects to adjust the cap later and may tie it to difficulty settings in a later phase, so nothing about it may be hard-coded.
- **D-03:** **A knockout costs only the time away.** No gold penalty, and the king returns at full health.
- **D-04:** **The king is sturdy but mortal.** He can fight a small group alone, but a full wave knocks him out if he stands in it, so towers and positioning stay meaningful.
- **D-05:** **Health returns only at dawn (full heal) or through a respawn.** There is no regeneration during a night in Phase 2; Phase 3's regeneration rule (KING-05) is added on top later.
- **D-06:** The king respawns **at the castle** after a **visible countdown** (KING-06). The run never ends because of the king.

### Enemies & Night Shape
- **D-07:** **A full run on the prototype map is 8 nights.** Surviving night 8 wins.
- **D-08:** **Two enemy types: a basic melee grunt and a ranged attacker.** The ranged type is introduced a few nights in. The wider roster waits for Phase 6.
- **D-09:** **Spawn points start at 1 and grow to 3.** Night 1 comes from one side; later nights add a second and then a third direction, so the telegraph icons matter and the king cannot be everywhere.
- **D-10:** **A first run is winnable with good choices.** Greedy or careless play should lose around the middle nights. Wave compositions are hand-authored per night and per spawn point, in data, so they can be retuned after the playtest.

### Building Damage & Towers
- **D-11:** **Enemies attack the nearest thing in their path.** They march toward the castle center and attack whatever is close on the way: the king, a tower or a House. Outer buildings act as a buffer, and the king can pull enemies off them.
- **D-12:** **A destroyed building becomes rubble on its plot** with a short collapse effect, and stays that way until dawn. Before that, damage shows as a health bar that appears only once the building has been hurt.
- **D-13:** **Towers shoot the nearest enemy in range with a visible projectile.** Tier II shoots faster or harder. Smarter targeting is left for tower specializations in Phase 6.
- **D-14:** **A rebuilt House shows a crossed-out coin above it at dawn** while the surviving Houses send coins to the gold counter. The icon fades when the day starts.

### Win, Loss & Playtest Gate
- **D-15:** **The results screen shows the outcome plus a few run stats:** Victory or Defeat, nights survived out of 8, gold earned, buildings lost and king knockouts. There is no score yet (Phase 9).
- **D-16:** **From the results screen the player can restart or quit.** "Play again" restarts the map from day 1; "Quit" closes the game. There is no main menu until Phase 13, and no retry of a single failed night until Phase 9.
- **D-17:** **Losing has a short beat.** The castle collapses, the action freezes for about a second so the player sees what happened, then the Defeat screen appears. The loss itself is decided the instant the castle center falls (LOOP-06).
- **D-18:** **The playtest gate is mostly delegated to Claude.** Claude runs scripted, seeded playthroughs, reports balance numbers (for example nights survived under different build orders, gold over time, knockouts, buildings lost) and checks readability from screenshots. The owner plays only one or two runs for feel and then gives the sign-off or names the fixes. The sign-off stays the owner's decision and is recorded through `/gsd-verify-work`.
  - Note for planning: ROADMAP success criterion 4 says the owner plays "several full runs". The owner chose a lighter version on 2026-10-03. Plan the scripted playthrough tooling and the balance report as real deliverables, and keep the owner's part to one or two runs.

### Claude's Discretion
- The look of the spawn-point telegraph icons and how enemy counts are shown on them.
- Exact health, damage, range, speed and attack-rate numbers for the king, towers, buildings and both enemy types, as long as they are data and meet D-04 and D-10.
- The exact countdown values of D-01 other than the 15 s cap.
- How the king's passive auto-attack looks and how far it reaches.
- How enemies path around buildings and each other, and what they do when blocked.
- Night lighting and how the action stays readable in the dark.
- The exact length and look of the loss beat (D-17), and the layout of the results screen.
- The seeded-RNG and fixed-step rules that make a night deterministic (DEV-05). Settle them before combat code is written.
- Which CC0 models stand in for the two enemies, the arrow and the rubble.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` — "Phase 2: Night Defense & Playtest Gate": goal and the four success criteria
- `.planning/REQUIREMENTS.md` — LOOP-01 to LOOP-07, KING-03, KING-06, BLDG-07, DEV-05
- `.planning/PROJECT.md` — core value, constraints, key decisions

### Prior decisions
- `.planning/phases/01-foundation-day-loop/01-CONTEXT.md` — Phase 1 decisions D-01 to D-16 (map, hold-to-build, start-night input, placeholder night and dawn payout)
- `.planning/STATE.md` — accumulated decisions and the Phase 2 concerns (determinism before combat code; king respawn rules, settled here)

### Research
- `.planning/research/ARCHITECTURE.md` — simulation/presentation split, state machine, command layer, event bus, KingController responsibilities
- `.planning/research/FEATURES.md` — Thronefall's night, dawn, rebuild and king knockout behaviour
- `.planning/research/PITFALLS.md` — known risks (determinism, readability, performance)
- `.planning/research/SUMMARY.md` — research summary and confidence notes

No external specs or ADRs exist beyond these.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `simulation/run/run_manager.gd`: the loop state machine (DAY, NIGHT_TRANSITION, NIGHT, DAWN). `_night_should_end` and `_apply_dawn_payout` are the two designated extension points.
- `input/start_night_hold_controller.gd` and `simulation/commands/start_night_intent.gd`: the start-night hold, already deliberate and tested.
- `simulation/buildings/building_system.gd` and `building_instance.gd`: building tiers per spot; health and destruction attach here.
- `simulation/defs/` (`map_config.gd`, `building_tier_def.gd`, `king_def.gd`, `loop_tuning.gd`) with `data/` `.tres` files: where wave, enemy, health and respawn data belong.
- `ui/hud/dawn_payout_vfx.gd`: the dawn coin payout, the place for the "no income" mark.
- `ui/overlay/debug_overlay.gd` with `register_section`: add enemy counts, wave state and paths as new sections.
- `presentation/vfx/coin_drip_vfx.gd`: precedent for pooled, capped, staggered visual effects.
- `tools/sandbox/hold_pacing_sandbox.gd`: precedent for a tuning sandbox that reprices data on a deep copy and never ships.
- `tools/screenshot/` and `tools/test.sh`: scripted screenshots and headless GUT for readability checks and seeded replays.

### Established Patterns
- Rejected operations return values instead of calling `push_error` (GUT counts engine errors as failures).
- Display-only effects lag the simulation; the simulation never waits for visuals.
- Tests step controllers with fixed deltas instead of wall-clock time.
- Every number is data; contract tests pin shipped values to the decisions.

### Integration Points
- `RunManager` phase transitions drive spawning (night start), the end-of-night check and the dawn rebuild and payout.
- `CommandProcessor` re-validates intents; building stays day-only (`not_day`).
- `RunContext` already exposes unit and enemy counts (0 in Phase 1) to the overlay.
- `data/maps/prototype_map.tres` gains spawn points and per-night wave data.

</code_context>

<specifics>
## Specific Ideas

- The owner on the respawn countdown: "grows each time until a max 15 seconds. but this max should be adjustable later. might even change using difficulty settings later".
- The game should stay faithful to Thronefall where the sources document it; where they do not (respawn numbers), the decisions above apply.
- The owner prefers Claude to check what can be measured with scripted real-window runs and to be asked only for feel judgments and decisions.

</specifics>

<deferred>
## Deferred Ideas

- Difficulty settings that change the respawn cap (and possibly other tuning) — a later phase; Phase 2 only keeps the values in data.
- Retrying a failed night — Phase 9 (RETRY), not brought forward.
- King health regeneration — Phase 3 (KING-05), not brought forward.
- A small minimap (from Phase 1 UAT) — still in the Phase 1 UAT follow-ups, not part of Phase 2.
- Drip coins hidden inside already-built models on upgrades (seen in Phase 1 UAT) — not logged as a task yet; could ride along with any VFX work here if the planner finds it cheap.

</deferred>

---

*Phase: 2-Night Defense & Playtest Gate*
*Context gathered: 2026-10-03*
