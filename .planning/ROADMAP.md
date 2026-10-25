# Roadmap: Duskhold

## Overview

Duskhold goes from an empty Godot 4.7.2 project to a released 5-map Windows campaign. The first two phases prove the day/night build-then-defend loop on one prototype map with no meta-progression. Phase 1 sets up the project and the agent-verification tooling (headless tests, lint, CI with a Windows export, screenshots, debug overlay, asset log) alongside a playable day phase: riding the king, building, upgrading, and earning gold. Phase 2 adds nights, dawn, win/loss, and seeded replays, and it ends in a human playtest gate. Next, the king and his troops fight together, and the unit/enemy simulation is scaled to Thronefall-size battles before content breadth is added. Day-phase depth comes next (castle center, branching upgrades, income curves), then enemy variety and tower specializations as counter pairs, then army variety. After that the game gets its cohesive art and sound. Then it becomes a campaign: scoring, retry, and versioned saves on maps 1–2, followed by the meta-progression loadout (second playtest gate) and the maps 3–5 finale with boss nights. Research buildings are isolated as the designated scope cut, and the project closes with settings, menus, and the itch.io release.

**Controls (changed 2026-09-28):** every phase uses Thronefall's original scheme. The king moves with WASD / left stick; building and upgrading happen by riding to a build spot and holding the action key; units take hotkey commands (hold; follow the king); gameplay works on keyboard and gamepad. **The mouse is used only in menus.** The earlier keyboard + mouse plan (click-to-build, mouse unit commands) was dropped and must not reappear in phase plans. On 2026-10-09 the owner brought the mouse back for squad selection, control groups and the ground points of move, attack-move and patrol (Phase 3, 03-CONTEXT.md D-11 and D-25), with building still ride-up-and-hold and king attacks automatic, matching PROJECT.md. Amended 2026-10-16: a gamepad is no longer required; later phases are keyboard and mouse only, the shipped pad paths are unsupported.

Sequencing rules this roadmap honors:
- The verification tooling and the day phase (Phase 1) are testable on their own before nights are layered on top (Phase 2). Phase 1's enemy-free day-to-day transition is the same loop that Phase 2 fills with real nights, not a throwaway.
- The core loop is proven and playtested (Phase 2 gate) before any meta-progression work. Meta-progression ends with its own playtest gate (Phase 10).
- Data-oriented unit/enemy scale-up (Phase 4) lands before content breadth (Phases 5–7), so no unit or enemy type has to be rebuilt for performance later.
- The stat-modifier aggregation order (META-08) lands with the first buffs (castle abilities, Phase 5). Save schema versioning (META-09) lands with the first save (Phase 9). Later phases extend both instead of retrofitting them.
- Enemy and building variety ship as counter pairs: flyers come with anti-air towers (Phase 6), and unit counters come right after the roster (Phase 7).
- The scoring formula stabilizes (Phase 9) before mutators are tuned on top of it (Phase 10).
- Map and wave authoring gets two visible phases: maps 1–2 (Phase 9) and maps 3–5 plus bosses (Phase 11).
- Research buildings (Phase 12) are the safest cut. No other phase depends on them.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & Day Loop** - Godot project with headless test/lint/CI/screenshot/debug tooling, plus a playable day of riding, building, upgrading, and earning gold on the prototype map (completed 2026-10-03)
- [x] **Phase 2: Night Defense & Playtest Gate** - Telegraphed nights, combat, king knockout, dawn rebuild and income, win/loss, and seeded replays; ends in a human playtest gate (completed 2026-10-08)
- [x] **Phase 3: King Combat & Troops** - Barracks and Archery Range squads with hold/follow hotkeys, king active ability, full HUD, keyboard + gamepad (completed 2026-10-15)
- [x] **Phase 4: Crowd-Scale Battles & Walls** - Walls and barricades, jam-free pathing, and hundreds of units/enemies/projectiles at 60 fps (completed 2026-10-21)
- [ ] **Phase 5: Castle Center & Economy Depth** - Branching choice-card upgrades, castle tiers with run-wide abilities, stat-modifier order, four new income curves
- [ ] **Phase 6: Enemy Roster & Tower Specializations** - Eight enemy roles (incl. flyers and siege) paired with 4+4 tower specializations that answer them
- [ ] **Phase 7: Army Variety & Heroes** - Four melee and four ranged unit choices, four heroes, and unit counter roles
- [ ] **Phase 8: Art, Readability & Sound** - Normalized CC0 low-poly look, readable nights, visual feedback, and mixed SFX
- [ ] **Phase 9: Campaign Opening & Scoring** - Tutorial map 1 and map 2 with authored waves, sequential unlocks, scoring, retry, and versioned saves
- [ ] **Phase 10: Loadout & Meta-Progression** - 5 weapons, 30+ perks, 10+ mutators, player level and unlocks, full menu flow; ends in a human playtest gate
- [ ] **Phase 11: Campaign Finale & Boss Nights** - Maps 3–5 with unique content, boss nights, and a tuned 5-map difficulty curve
- [ ] **Phase 12: Research Buildings** - Blacksmith and Royal Forge multi-day research with global buffs (designated scope cut)
- [ ] **Phase 13: Settings & Release** - Settings and rebinding, credits, any-device menus, clean-machine Windows build, itch.io launch

## Phase Details

### Phase 1: Foundation & Day Loop

**Goal**: A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: KING-01, KING-02, BLDG-01, BLDG-02, BLDG-03, BLDG-04, BLDG-06, ECON-01, ECON-02, ECON-07, ART-02, DEV-01, DEV-02, DEV-03, DEV-04
**Success Criteria** (what must be TRUE):
  1. During the day, the player rides the mounted king (WASD / left stick, with sprint) under a following isometric-style camera. Near each fixed build spot, the player sees what can be built there and its gold cost.
  2. Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier's cost and effect. This only works when affordable, only on build spots, and never at night.
  3. Gold is the only currency and is always on the HUD. Ending the day through a placeholder transition (the night has no enemies until Phase 2) leads to dawn, where each House pays income that grows with its tier and unspent gold carries over to the next day.
  4. From the command line, and in CI on every push:
     - lint and headless GUT tests cover the economy, building rules, and day-to-day transitions
     - scripted scenes export screenshots
     - CI produces a Windows export
  5. A key toggles a debug overlay showing FPS, unit/enemy counts, and the current loop state (wave state and enemy paths join it once nights have enemies in Phase 2). Every third-party asset used so far is recorded in the repository's license/attribution log.

**Plans**: 18/18 plans complete
**UI hint**: yes

Plans:
**Wave 1**
- [x] 01-01: Repo hygiene and pinned toolchain — consent-gated, checksum-verified bootstrap for Godot 4.7.2 + export templates, GUT 9.7.1, gdtoolkit, test/lint wrappers

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 01-02: Walking skeleton — ride the king to a House plot and hold to build it, end to end, with headless command-path tests

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 01-03: Command-line Windows export, pre-push leak check, CI (lint/test/export), repo-name decision, first push and green CI
- [x] 01-04: King riding feel (acceleration, facing) and the fixed-angle follow camera
- [x] 01-05: Full 8-spot prototype map, the basic tower, tight starting economy, upgrades and max tier

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 01-06: Floating spot label, coin drip, refund on release, denied shake
- [x] 01-07: Attribution log with coverage test; approved CC0 king, House, tower and castle models
- [x] 01-08: Read-only toggleable debug overlay

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 01-09: Day → night → dawn loop, hold-to-start-night, night banner and lighting, dawn income, gold carryover

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 01-10: Visible dawn payout, six scripted screenshots (local and CI), final push with green CI

**Gap closure (UAT 2026-10-02)** *(wave 1: 01-11, 01-13; wave 2: 01-12, after 01-11)*
- [x] 01-11: Camera 1.3x further out on the same fixed angle, clamped keyboard/gamepad zoom, spot labels that keep their size (G-01-3)
- [x] 01-12: King shows as a light-cyan silhouette behind buildings, plus a king_behind_keep screenshot (G-01-3)
- [x] 01-13: Slower coin drip (0.3 s per coin) for more deliberate build holds (G-01-4)

**Gap closure (UAT re-check 2026-10-02)** *(wave 1: 01-14; wave 2: 01-15, after 01-14; wave 3: 01-16, after 01-14 and 01-15)*
- [x] 01-14: Accelerating build hold (0.25 s first coin, faster after, 3 s cap that pays the remaining coins at once), curve helpers in data, hitch-proof timing tests, D-05 amended (G-01-58)
- [x] 01-15: Coin stream follows the curve and shows the cap rush, curve-timed build screenshot, real-window hold-pacing sandbox and owner feel check (G-01-58)
- [x] 01-16: Slow-drip tests on one flat-pace helper; security and validation records updated (G-01-58)

**Gap closure (UAT re-check 2026-10-02, second round)** *(wave 1: 01-17; wave 2: 01-18, after 01-17)*
- [x] 01-17: No build hold cap and a 0.05 s per-coin floor in data (cap kept as an off switch), every coin drips; stepped long-hold, burst, curve and no-cap contract tests; D-05 amended (G-01-59)
- [x] 01-18: Controller and coin VFX comments follow the uncapped hold, real-window sandbox self-check and the owner's re-check; security and validation records updated (G-01-59)

### Phase 2: Night Defense & Playtest Gate

**Goal**: The prototype map plays the full day → night → dawn loop. The player sees each night coming and starts it deliberately, defends with the king and basic towers, rebuilds and collects income at dawn, and wins or loses on a results screen. Seeded nights replay deterministically, and the owner confirms the loop is fun before anything is built on top of it.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: LOOP-01, LOOP-02, LOOP-03, LOOP-04, LOOP-05, LOOP-06, LOOP-07, KING-03, KING-06, BLDG-07, DEV-05
**Success Criteria** (what must be TRUE):
  1. There is no day timer. The player sees per-spawn-point enemy counts for the coming night and starts it with a hold-to-confirm input. Enemies then damage and visibly destroy buildings while the king auto-attacks enemies in range with the weapon's passive attack. A knocked-out king respawns at the castle after a visible countdown, and the run continues.
  2. The night ends only when every enemy is dead. At dawn, destroyed buildings return for free, surviving Houses pay tier-based income, and rebuilt buildings are visibly marked as paying nothing. The run ends on a results screen: a loss the instant the castle center falls, or a win after the final night.
  3. From the command line and in CI, a seeded scripted night replays with identical results, and headless GUT tests cover waves, combat, and loop transitions (day → night → dawn, loss, win). During nights, the debug overlay shows live enemy counts, wave state, and enemy paths.
  4. Human playtest gate: the owner plays the prototype map through several full runs and either signs off that gold trade-offs feel meaningful and nights feel tense and readable, or records the tuning/feel fixes that must land before later phases begin. No meta-progression work is scheduled until this sign-off.

**Plans**: 22/22 plans complete (02-12 to 02-16 closed the 2026-10-06 UAT gaps G-02-1 and G-02-2; 02-17 to 02-20 closed the 2026-10-07 round-2 UAT gaps G-02-13 to G-02-15 and reopened the gate for G-02-12; 02-21 and 02-22 close the 2026-10-07 round-3 UAT gap G-02-18 and reopen the gate for the round-4 replay)
**UI hint**: yes

Plans:
**Wave 1**
- [x] 02-01: Tracer — one seeded night end to end on the fixed 30 Hz step behind the determinism guards; event recorder, scripted bot and in-process replay digest

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 02-02: Eight real nights on the prototype map, every Phase 1 suite moved onto a waveless copy, night data validation and contract pins

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 02-03: Enemies target the king and the castle; king knockout and respawn countdown (6/10/14/15 s); hurt-only health bars and the ghost king

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 02-04: Buildings take damage and fall to rubble until dawn
- [x] 02-08: Spawn telegraph markers, night preview and banner, untimed-day regression; Wave/King/Paths overlay sections and the enemy-path gizmo

**Wave 5** *(blocked on 02-04)*
- [x] 02-05: Towers and skirmishers shoot visible projectiles; the king's slash; enemy hit flashes and health bars

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 02-06: Free dawn rebuild, full repair, no income from rebuilt buildings and the crossed-out coin

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 02-07: Loss the instant the castle falls, victory after night 8, run stats, the loss beat and the results screen

**Wave 8** *(blocked on 02-07 and 02-08)*
- [x] 02-09: Replay CLI and wrapper, frozen smoke golden, CI replay step, push and the cross-platform golden

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 02-10: Playtest strategies and balance report; D-10/D-04 tuning pass; 02-BALANCE-REPORT.md

**Wave 10** *(blocked on Wave 9 completion)*
- [x] 02-11: Fifteen scripted screenshots with a readability review, final green CI, a launch-checked export and the owner's playtest gate packet

**Gap closure** *(UAT 2026-10-06: G-02-1 playtest fixes, G-02-2 results-screen spacing)*

**Gap wave 1**
- [x] 02-12: Base dawn income of 1 gold from the castle, its coin flying from the castle at dawn
- [x] 02-13: Sprint 12 m/s and a night-only hold-to-fast-forward (F / left trigger, 2x) with its HUD label (a toggle from 02-18)
- [x] 02-14: Results screen: 11 px above the buttons so the spacing is even

**Gap wave 2** *(blocked on 02-12)*
- [x] 02-15: The castle shoots (2 damage, 11 m, every 1.5 s) with visible arrows; castle kills in the balance report (22 m and 27 m/s arrows from 02-17)

**Gap wave 3** *(blocked on 02-12 to 02-15)*
- [x] 02-16: Balance re-measure under the owner's rule, acceptance test, regenerated report, fresh export and the round-2 playtest packet

**Gap closure, round 2** *(UAT 2026-10-07: G-02-13 castle reach and arrow speed, G-02-14 fast-forward toggle, G-02-15 a little harder; G-02-12 is the owner's gate record, answered by the round-3 replay)*

**Round-2 gap wave 1**
- [x] 02-17: Castle reach 22 m and arrows 27 m/s (the owner's numbers, pinned); castle validation and arming refuse non-finite and sub-step values (review WR-02)
- [x] 02-18: Fast-forward becomes a night-only toggle (press on, press again off, off when the night ends; one trigger pull counts once); leaked test controllers fixed (review WR-01)

**Round-2 gap wave 2** *(blocked on 02-17)*
- [x] 02-19: The owner's full wall: night 2 opens the east road and nights 3 to 5 grow (totals 5, 12, 21, 21, 21, 22, 27, 33); balanced bot pinned at 7 or 8 of 10

**Round-2 gap wave 3** *(blocked on 02-17 to 02-19)*
- [x] 02-20: Round-3 balance report, 15 screenshots, fresh export and the round-3 owner packet (the night-3 wall said plainly)

**Gap closure, round 3** *(UAT 2026-10-07 round 3: G-02-18 the king walks 1.5x faster, 7.5 m/s, with the sprint kept at exactly 12 m/s; G-02-18 is also the round-3 gate record, answered by the round-4 replay)*

**Round-3 gap wave 1**
- [x] 02-21: The king walks at 7.5 m/s and still sprints at exactly 12 m/s (multiplier 1.6), all three pinned; D-03 amended (edge-to-edge ride about 15 s, the map not grown); KingDef defaults and docs

**Round-3 gap wave 2** *(blocked on 02-21)*
- [x] 02-22: Round-4 note in the balance report (no bot number moved, no re-measurement), 15 screenshots, fresh export and the round-4 owner packet

### Phase 3: King Combat & Troops

**Goal**: The king leads an army. The player builds a Barracks and an Archery Range whose squads fight on their own, commands them RTS-style with hotkeys, mouse selection and control groups, and fires the weapon's active ability. All of it is fully playable on keyboard and mouse or on gamepad with a complete in-run HUD.
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: KING-04, KING-05, UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, INPT-01, INPT-02, UI-01
**Success Criteria** (what must be TRUE):
  1. The player can build a Barracks (default melee squad) and an Archery Range (default ranged squad). Their units stay near their post and fight nearby enemies on their own, committing to targets instead of constantly switching. Units killed at night trickle back from their building, and every unit is fully restored at dawn.
  2. The player can select whole squads (click, drag box, Ctrl to add; cycling on gamepad), store and recall them as numbered control groups, and order the selection to hold its position, follow the king (all squads or one unit type), rally to the king, move, attack-move or patrol a path, with Shift queuing orders. Stances persist across dawn. (Amended 2026-10-09, owner decision; see 03-CONTEXT.md D-09 to D-16.)
  3. The player can trigger the king's weapon active ability and see its cooldown on the HUD. The king's health regenerates after a short time without taking damage.
  4. Every in-run action (move, sprint, hold-to-build/upgrade, active ability, unit selection and commands, start night) works on keyboard and mouse and on gamepad. The player can switch devices at any moment, and on-screen prompts update to match the active device.
  5. The HUD shows gold, current night out of total, king health, ability cooldown, and unit group status without cluttering the play area.

**Plans**: 19/19 plans complete (03-13 to 03-19 close the 2026-10-13 UAT round-1 gaps G-03-4, G-03-8, G-03-11, G-03-13, G-03-14 and G-03-14b; the owner gate, test 15, follows them)
**UI hint**: yes

Plans:
**Wave 1**
- [x] 03-01: Tracer — a Barracks squad end to end on the fixed step (guard, commit, enemies target units, puppets, double-run digest); archers, arrows and Mini Characters models
- [x] 03-03: HUD foundation — canvas_items stretch with every suite green; HudRoot, theme, four-size type scale, "Night N of T" counter and the clear-centre contract

**Wave 2** *(blocked on 03-01)*
- [x] 03-02: Squad life cycle — night trickle 10/7/4 s, full restore at dawn, posts by day; military data validated and pinned (4/8/14, 4/8/16), "Squad of N" labels and tier models

**Wave 3** *(blocked on 03-02 and 03-03)*
- [x] 03-04: The sword as WeaponDef, the slam on Q / pad X with a 9 s cooldown, regeneration after 1 s, and the bottom-left king widget

**Wave 4** *(blocked on 03-04)*
- [x] 03-05: Squad strip bottom-centre (icon, alive / max, stance glyph, replacement fill) and the Squads overlay section

**Wave 5** *(blocked on 03-05)*
- [x] 03-06: Follow, hold and rally on a selection — order gate and persistence, click / Ctrl / double-click / slot selection with rings, F H R Tab F2 keys, toast, fast-forward to T

**Wave 6** *(blocked on 03-06)*
- [x] 03-07: Attack-move key decision (owner checkpoint); move, attack-move, patrol and Shift queue on centimetre points; right-click and armed mouse commands with pings

**Wave 7** *(blocked on 03-07)*
- [x] 03-08: Patrol lines and queued discs, drag-box selection, Ctrl + digit control groups with slot badges
- [x] 03-11: Army replay golden in CI, army-building bots, and the D-08 night retune to 7 or 8 wins of 10

**Wave 8** *(blocked on 03-08)*
- [x] 03-09: Gamepad parity — D-pad verbs with an LB layer, Start group mode, right-stick ground cursor, capability table

**Wave 9** *(blocked on 03-09)*
- [x] 03-10: Device-following prompts — Kenney Input Prompts glyphs, device tracker, glyph start-night prompt and slam badge, command hint strip

**Wave 10** *(blocked on 03-10 and 03-11)*
- [x] 03-12: 18 real-window screenshots with the clear-centre check, green CI, a launch-checked export and the owner's gate packet

**Gap closure** *(UAT 2026-10-13 round 1: G-03-4 king bar and regeneration, G-03-8 Shift-queued verbs, G-03-13 knocked-out legibility, G-03-14 singular copy, G-03-14b start-night plate, G-03-11 balance round 2)*

**Gap wave 1**
- [x] 03-13: Shift (pad RT) queues F, H and R behind the walks, so "move here, then hold" is one gesture (G-03-8)
- [x] 03-14: The floating king bar follows regeneration and hides at full health (G-03-4, review WR-01)
- [x] 03-15: A plate behind the start-night prompt, below the squad strip and clear of the centre; UI-SPEC rows and re-captured day shots (G-03-14b)
- [x] 03-16: Kills per gold by building role in the balance report; Round 2 targets and today's baseline (G-03-11, part 1)

**Gap wave 2** *(blocked on 03-15)*
- [x] 03-19: An opaque knocked-out "0 / 50" and "1 enemy" copy; UI-SPEC rows, the full suite and all 33 shots re-checked with the plate (G-03-13, G-03-14)

**Gap wave 3** *(blocked on 03-13 to 03-16 and 03-19)*
- [x] 03-17: Round 2 retune: the owner's four balance goals as tests, a measured search of squad, tower, cost and regeneration values with nights 5 to 8 and re-pinned contracts, or an owner decision on the best three candidates if the allowed levers cannot reach all four (G-03-11, part 2)

**Gap wave 4** *(blocked on 03-17 and 03-19)*
- [x] 03-18: Round 2 published: outcome, what changed, search log, after-retune tables and goldens in the balance report; the updated gate packet and the 33 shots re-captured (G-03-11, part 3)

### Phase 4: Crowd-Scale Battles & Walls

**Goal**: Nights scale to Thronefall-size battles, with hundreds of units, enemies, and projectiles at 60 fps. Walls and barricades shape enemy paths without gridlock. This lands before any content breadth is added.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: BLDG-10, ENMY-04, PLAT-01
**Success Criteria** (what must be TRUE):
  1. The player can build walls and barricades that block enemy movement, upgrade them linearly in health, and use them to funnel enemies into chokepoints.
  2. Enemies path to their targets around walls or by breaking through them and never jam indefinitely. A headless stress test that sends 200+ enemies through a single gate finishes with zero permanently stuck agents, and the paths are visible in the debug overlay.
  3. A scripted stress night with hundreds of units, enemies, and projectiles on screen holds 60 fps on GTX 970-class hardware, or within a documented equivalent frame-time budget on the dev machine.
  4. Nights from Phases 1–3 play the same after the switch to batched simulation and rendering. All existing headless loop and combat tests still pass.

**Plans**: 28/28 plans complete (04-12 to 04-23 closed the 2026-10-19 UAT gaps G-04-5, G-04-6 and G-04-7; 04-24 to 04-28 are the second gap round for the 04-VERIFICATION.md gap for success criterion 3, PLAT-01, planned 2026-10-20)

Plans:
**Wave 1**
- [x] 04-01: Tracer — enemies drawn as one MultiMesh batch per type with hit flash, hurt-only bars and death puffs; smoke, army and full_idle byte-identical (D-13)

**Wave 2** *(blocked on 04-01)*
- [x] 04-02: Units and arrows from batches (baked Kenney meshes, 512-slot arrow ring), selection on the new hooks, 33 screenshots re-checked, green CI

**Wave 3** *(blocked on 04-02)*
- [x] 04-03: Exact-preserving crowd step — structure and enemy grids, bucketed Separation, packed read view; goldens byte-identical, step bench recorded

**Wave 4** *(blocked on 04-03)*
- [x] 04-04: Wall tracer — WallRunDef, WallSystem of segments, WallSolids, Pathing facade, KIND_WALL hits, free dawn restore, solidity for everyone, WallViews

**Wave 5** *(blocked on 04-04)*
- [x] 04-05: Four wall runs on the prototype map (three road runs and a ring, D-06), WallValidation, run label, plot tests 10 to 14, a look per tier, collapse and rubble

**Wave 6** *(blocked on 04-05)*
- [x] 04-06: Integer Dial flow field — everyone goes around walls through gaps and holes, sealed enemies break in, blocked targets dropped, goal-field cache

**Wave 7** *(blocked on 04-06)*
- [x] 04-07: Break-or-go-around rule per segment on a 0.5 s cadence with hysteresis (D-07, D-08); read-only stuck tracker (D-09)

**Wave 8** *(blocked on 04-07)*
- [x] 04-08: Tools-only stress map, headless 300-enemy gate test in GUT and CI, field / path / stuck display in the debug overlay

**Wave 9** *(blocked on 04-08)*
- [x] 04-09: Real-window stress night (300 enemies, 50 units, 200 arrows), three runs, median p95 at or under 8 ms, rebuild-hitch probe, committed 04-FRAME-REPORT.md

**Wave 10** *(blocked on 04-09)*
- [x] 04-10: Walls golden in CI, wall-buying bots with no-walls twins, balance with and without walls, the one regeneration commit and 04-BALANCE-REPORT.md (D-14, D-15)

**Wave 11** *(blocked on 04-09 and 04-10)*
- [x] 04-11: Gate — full local pass (suite, four goldens, gate stress, 37 screenshots), green CI, launch-checked export, 04-PLAYTEST-GATE.md and the owner feel check

**Gap closure** *(UAT 2026-10-19: G-04-7 melee enemies break through to targets behind walls, G-04-6 the overlay hides the night banner, G-04-5 PLAT-01 by the owner's GDExtension route with the 8 ms budget kept; also the 04-VERIFICATION.md gap for criterion 3)*

**Gap wave 1 (wave 12)** *(blocked on 04-11)*
- [x] 04-12: Melee enemies break the wall in front of a tower, unit or king behind it (visible targets first, centre-line test at gap mouths, the castle left to D-07); EnemyDef.drops_blocked_targets for the Phase 6 roster; goldens unchanged (G-04-7)
- [x] 04-13: The F3 overlay moves below the night banner box; a y-only 1280x720 layout test; the three overlay shots re-captured (G-04-6)

**Gap wave 2 (wave 13)** *(blocked on 04-12)*
- [x] 04-14: Native toolchain and scaffold — pinned godot-cpp, CMake build with MSVC (no install), NativeSim loads, the C++ determinism guard, godot-cpp attribution (G-04-5)

**Gap wave 3 (wave 14)** *(blocked on 04-14)*
- [x] 04-22: A missing or stale native library is a named error in every wrapper and at boot; the export carries the DLL and launches (G-04-5)

**Gap wave 4 (wave 15)** *(blocked on 04-22)*
- [x] 04-15: Tracer — Separation in C++, pinned on the GDScript first, goldens byte-identical, a machine-checked gain on the stress shape; the math contract against the engine (G-04-5)

**Gap wave 5 (wave 16)** *(blocked on 04-15)*
- [x] 04-16: The owner picks where the binaries come from (checkpoint), then CI builds or receives the library, replays the goldens on Linux and Windows and exports the DLL; one push watched green (G-04-5)

**Gap wave 6 (wave 17)** *(blocked on 04-16)*
- [x] 04-17: The wall solid test in C++ (first_blocking, push_out, closest_point, segments_near) for every caller, pinned first (G-04-5)

**Gap wave 7 (wave 18)** *(blocked on 04-17)*
- [x] 04-18: Flow-field reads and castle routing in C++ from a live grid mirror, pinned first (G-04-5)

**Gap wave 8 (wave 19)** *(blocked on 04-18)*
- [x] 04-23: The structure index and the wall decision state in C++, pinned first; the per-tick enemy trace tool with bounds taken from each scenario (G-04-5)

**Gap wave 9 (wave 20)** *(blocked on 04-23)*
- [x] 04-19: The enemy store and step in C++ behind EnemySystem's facade, identical tick by tick to committed reference trace digests on five scenarios (G-04-5)

**Gap wave 10 (wave 21)** *(blocked on 04-19)*
- [x] 04-20: Native nearest-enemy queries and stuck tracker, then the whole port green on CI on Linux and Windows (G-04-5)

**Gap wave 11 (wave 22)** *(blocked on 04-20)*
- [x] 04-21: The stress night re-measured against the unchanged 8.0 ms p95 into 04-FRAME-REPORT.md with the residual step attribution, a launch-checked export and the owner's re-check list (G-04-5, criterion 3)

**Gap closure, round 2** *(re-verification 2026-10-20: PLAT-01 still missed at a median-run p95 of 10.95 ms against the unchanged 8.0 ms, the step now 2.33 ms and the three per-frame view loops the remaining cost; owner route 2026-10-20: port the view fills to C++, pins-first and byte-identical, budget unchanged, then re-measure; review CR-01 folded in first)*

**Gap wave 12 (wave 23)** *(blocked on 04-21)*
- [x] 04-24: Review CR-01 first — the native stamp binds the library bytes and a failed copy leaves no stamp, with a hermetic probe; the committed per-view fill bench and the real-window view ablation, with the ablation baseline before any port (G-04-5)

**Gap wave 13 (wave 24)** *(blocked on 04-24)*
- [x] 04-25: Tracer — the arrows' per-frame flight in C++ (NativeArrows) behind ProjectileVfx's API, pinned on the GDScript fill first, the same pins and goldens, a measured gain, then the GDScript loop goes; the Vector3 math contract against the engine (G-04-5)

**Gap wave 14 (wave 25)** *(blocked on 04-25)*
- [x] 04-26: Enemy bodies, flashes and bars filled in C++ (NativeEnemyViews) over the packed read view behind a clock seam, pinned first; the death-puff ring native and idle batches no longer uploading (review IN-08) (G-04-5)

**Gap wave 15 (wave 26)** *(blocked on 04-26)*
- [x] 04-27: Unit bodies and bars filled in C++ (NativeUnitViews) from a packed UnitSystem read view, pinned first; the round's one push and CI green on both native jobs with a launched export (G-04-5)

**Gap wave 16 (wave 27)** *(blocked on 04-27)*
- [x] 04-28: The stress night re-measured against the unchanged 8.0 ms p95 with the committed view ablation into 04-FRAME-REPORT.md; the export, three re-captured screenshots and the owner's dated re-check list for UAT tests 5, 6 and 13, in every outcome (G-04-5, criterion 3)

### Phase 5: Castle Center & Economy Depth

**Goal**: Day decisions gain real depth. The castle center grows through tiers with run-defining ability picks that gate higher building tiers, and four new economic buildings each pay out on a different income curve. All bonuses stack in one tested order.
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08, UI-02
**Success Criteria** (what must be TRUE):
  1. At a branching upgrade tier, the player picks one of the offered choice cards (icon, name, short description) with keyboard or mouse. The choice stays locked for the rest of the run.
  2. The player can upgrade the castle center through its tiers for more health, choosing one of four run-wide abilities or passives at each tier. Higher building tiers stay locked until the castle reaches the required tier.
  3. The player can build four new economic buildings:
     - a Gold Mine, whose high income drops each night
     - a Mill, which opens nearby Field spots that each pay a flat income
     - a Fishing Harbor, which gains a paying boat each night up to an upgradeable cap
     - a Shrine, which activates after enough nearby enemy deaths, then attacks, pays, and strengthens other active Shrines
  4. Bonuses from building upgrades and castle abilities combine in one fixed, documented order. Automated tests verify single-modifier and combined-modifier cases.

**Plans**: 14/24 plans executed (planned 2026-10-21: 12 plans in 11 waves, one chain with 05-04 and 05-05 side by side; research P1 to P8 and the one approved golden step folded in; 05-13 to 05-24 close the UAT gaps G-05-2 and G-05-7: first planned 2026-10-24 as five plans around a per-attacker rounding carry, replanned 2026-10-25 as twelve plans in twelve waves after the owner's hard requirement to scale every health and damage number by 100)

Plans:

**Wave 1**
- [x] 05-01: Tracer — the StatStack (flat, percent, multiplier buckets, one half-up rounding) with docs/STAT_MODIFIERS.md and the single- and combined-modifier tests; every modifiable stat read through it with identity values, smoke, army, walls and full_idle byte-identical; Stats overlay (META-08, D-15)

**Wave 2** *(blocked on 05-01)*
- [x] 05-02: Castle tracer — the castle plot and its four tiers, BuildIntent choice_id, choice_picked and the ChoiceLedger, the world-space card row picked with keys 1 to 4 and the digit hand-over from control groups (BLDG-08, BLDG-05, UI-02, D-01, D-05, D-06)

**Wave 3** *(blocked on 05-02)*
- [x] 05-03: All twelve cards, the castle label showing the next tier's effect and the locked picks, castle and choice validation, the ability data contract (D-02, D-04, D-07)

**Wave 4** *(blocked on 05-03)*
- [x] 05-04: Mouse hover and click on the cards, exact numbers on highlight, first-party SVG icons with key tiles, the keep's look per tier, two screenshots (UI-02, D-05, D-07)
- [x] 05-05: The one requirement mechanism — a tier that needs the castle at tier N and a plot that needs another spot at tier N — refused at the build gate with "Needs Castle II" / "Needs a Mill" labels and the denied bump, validated in data, the bots' defer-on-locked rule (BLDG-09, D-03, D-10)

**Wave 5** *(blocked on 05-04 and 05-05)*
- [x] 05-06: Gold Mine and IncomeState — the declining payout merged into the one dawn payout, the crossed coin on a rebuilt building, curve validation, Economy overlay (ECON-03, D-12, D-14)

**Wave 6** *(blocked on 05-06)*
- [x] 05-07: Mill and its three Fields locked until the Mill stands, Mill III gated, the field_locked shot (ECON-04, D-10, D-13)

**Wave 7** *(blocked on 05-07)*
- [x] 05-08: Fishing Harbor — one boat per surviving dawn up to the tier's cap, harbor_boats_changed, the visual-only pond and its clearance validation (ECON-05, D-11)

**Wave 8** *(blocked on 05-08)*
- [x] 05-09: Shrines — wake by nearby kill credit, the awake gate in the tower loop, the mutual +20% through the stack, shrine_woke; the edge-probe ledger (ECON-06, D-12)

**Wave 9** *(blocked on 05-09)*
- [x] 05-10: The new economy replay golden on a frozen fixture with its CI lines, scripted bot card picks, the one-night D-14 test across all four buildings

**Wave 10** *(blocked on 05-10)*
- [x] 05-11: Castle-aware bots and no-castle twins, D-03's gate on the shipped top tiers, numbers fitted to the 7-8 of 10 bar with the fewest changes, the re-pin and 05-BALANCE-REPORT.md with the full_idle before/after (D-08), two shots

**Wave 11** *(blocked on 05-11)*
- [x] 05-12: Phase gate — the full local pass with all 44 shots, push and green CI, a launch-checked export and 05-PLAYTEST-GATE.md for the owner's feel check

**Gap closure** *(UAT 2026-10-24/25: G-05-2 percent cards that round away at the shipped numbers and income cards too weak for their tier, resolved by the owner's hard requirement of 2026-10-25 to scale every health and damage number by 100; G-05-7 the Fishing Harbor moved into harm's way with a little less health. One chain of twelve plans, one per wave, because executors share the main checkout and its test and replay outputs)*

**Gap wave 1** *(after 05-12)*
- [x] 05-13: The x100 rescale begins: the king, sword, soldiers, enemies, towers, Shrine and castle at 100 times their health and damage, each file checked line by line against the round's base; the data is consistent only after 05-14 (G-05-2)

**Gap wave 2** *(blocked on 05-13)*
- [x] 05-14: The rescale completes in the shipped data (walls, Houses, military and economy buildings, Royal Training's flat +100) and the bots play the scaled game to the unchanged bar (GRUNT_MAX_HEALTH 600); full_idle to its scaled digest (G-05-2)

**Gap wave 3** *(blocked on 05-14)*
- [ ] 05-15: The seven non-golden fixtures that load shipped defs move to the x100 scale, and the wall tests apply their own amounts at it; the four golden fixtures untouched (G-05-2)

**Gap wave 4** *(blocked on 05-15)*
- [ ] 05-16: The stress map and the stress tools' king and castle follow the scale; the gate stress keeps its crossing statistics and the PLAT-01 fill pins hold unedited (G-05-2)

**Gap wave 5** *(blocked on 05-16)*
- [ ] 05-17: Every contract and label test that names a shipped health or damage number is re-pinned x100 with the gap round in its header (D-07's footman blow as 100) (G-05-2)

**Gap wave 6** *(blocked on 05-17)*
- [ ] 05-18: The PLAT-01 pins stay byte-identical (their inputs scaled or frozen at the Phase 4 numbers) and the combat tests keep their intent at the new scale (G-05-2)

**Gap wave 7** *(blocked on 05-18)*
- [ ] 05-19: The tests that fell shipped buildings, segments and units with their own blows fell them again at the x100 scale (G-05-2)

**Gap wave 8** *(blocked on 05-19)*
- [ ] 05-20: The HUD shows the scaled numbers as they are, the king widget's label widened to 128 px, the HUD tests and shot scenarios at the new scale, ten real-window shots reviewed (G-05-2)

**Gap wave 9** *(blocked on 05-20)*
- [ ] 05-21: Prosperity +2, Golden Age's income +4, Headsman's Edge x1.25, and the card recurrence guard over every card and shipped base with the scale bound and a negative control, green on its first run (G-05-2)

**Gap wave 10** *(blocked on 05-21)*
- [ ] 05-22: The Fishing Harbor moves beside the west road (skirmishers notice it, no tower or castle arrow covers it) with its pond set 6.5 m off so the dock stays on land, its health 1800/2400 to 1400/2000, harbor_1's own road band and the pond and footprint rules pinned, exposure measured with the bots (G-05-7)

**Gap wave 11** *(blocked on 05-22)*
- [ ] 05-23: The bar re-measured and re-pinned, the gap-round section of 05-BALANCE-REPORT.md with full_idle before, after the rescale and at the end, the rescale, and a viability basis for every card; harbor_pond and economy_day re-captured (G-05-2, G-05-7)

**Gap wave 12** *(blocked on 05-23)*
- [ ] 05-24: The closing local pass (full suite, five replays, gate stress), a launch-checked export and the owner's re-check list with the display choice, the hits-to-kill point and a decision for each card the bots cannot judge (G-05-2, G-05-7)

**UI hint**: yes

### Phase 6: Enemy Roster & Tower Specializations

**Goal**: Nights demand varied defenses. A shared roster covering eight enemy roles punishes single-strategy builds, and towers branch into specializations that answer them, landing counter pairs together (e.g. anti-air options alongside flyers).
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: ENMY-01, ENMY-02, ENMY-03, BLDG-11
**Success Criteria** (what must be TRUE):
  1. Enemies covering all eight roles (melee, ranged, fast, tank, flying, siege, anti-king, exploder) appear in scripted nights, each with behavior that matches its role.
  2. Siege enemies go for buildings first, and anti-king enemies hunt the king first.
  3. Flying enemies cross over walls and can only be hit by attackers that can reach air targets.
  4. The player can upgrade towers through a tier-2 choice of four specializations and a tier-3 choice of four more. Each has a visibly distinct attack behavior, and at least one option can hit flyers.
  5. In seeded headless simulation, a mixed-role night overwhelms a single-strategy defense (e.g. walls plus one tower type) but is survivable with a varied defense.

**Plans**: TBD

### Phase 7: Army Variety & Heroes

**Goal**: Military choices matter. Each Barracks and Archery Range specializes into one of four unit types, a Hero's Quarter fields one of four heroes, and unit roles form clear counters to the enemy roster.
**Mode:** mvp
**Depends on**: Phase 6
**Requirements**: UNIT-01, UNIT-02, UNIT-03, UNIT-08
**Success Criteria** (what must be TRUE):
  1. When building a Barracks, the player picks one of four melee unit types. When building an Archery Range, the player picks one of four ranged types. Each building produces its squad over time, up to a cap that grows with tier.
  2. The player can build a Hero's Quarter and pick one of four heroes. The single hero grows stronger with each tier and revives after a long timer when killed.
  3. Unit types fill distinct counter roles (e.g. anti-air, anti-siege, anti-armor, healing). Seeded headless matchup tests show each counter outperforming a non-counter unit against its target enemy role.

**Plans**: TBD

### Phase 8: Art, Readability & Sound

**Goal**: Duskhold looks and sounds like one cohesive game: normalized CC0 low-poly art, nights that stay readable in big battles, satisfying visual feedback, and a mixed SFX layer for every core action. This happens before campaign maps are authored in the final asset kit.
**Mode:** mvp
**Depends on**: Phase 7
**Requirements**: ART-01, UI-05, UI-06, AUD-01, AUD-02
**Success Criteria** (what must be TRUE):
  1. Buildings, units, enemies, and terrain from different CC0 packs share consistent scale, palette, and shading. A side-by-side screenshot of mixed-pack assets in one scene shows no visible style clash.
  2. In automated night-battle screenshots, the king, each unit type, each enemy role, and each building are identifiable by silhouette and color language. Day and night have distinct lighting moods.
  3. Building, upgrading, hits, destruction, and dawn gold payouts each give clear visual feedback.
  4. CC0 SFX play for king and unit attacks, hits, deaths, building and upgrading, gold payout, UI interactions, night start, and dawn. The largest scripted battle stays readable by ear, with no clipping or wall of noise.

**Plans**: TBD
**UI hint**: yes

### Phase 9: Campaign Opening & Scoring

**Goal**: The game becomes a campaign. Map 1 teaches the loop, map 2 unlocks after winning it, and every run is scored with a visible breakdown. Failed nights can be retried at a score cost, and progress survives relaunching under a versioned save.
**Mode:** mvp
**Depends on**: Phase 8
**Requirements**: LOOP-08, ENMY-05, MAP-02, MAP-04, META-04, META-07, META-09
**Success Criteria** (what must be TRUE):
  1. A new player learns to move, build, start the night, fight, and collect dawn income on map 1 from in-game prompts alone.
  2. Maps 1 and 2 each play hand-authored nights whose per-spawn-point waves escalate in count, variety, and spawn directions. Map 2 has its own layout and distinguishing content.
  3. Winning map 1 unlocks map 2. Map select shows each map's lock state and best score.
  4. After a loss, the player can retry from the start of the failed night's day, which forfeits the no-restart bonus, or restart the map. The results screen breaks the score into survival, buildings protected, time bonus, unspent gold, mutator bonus, and no-restart bonus.
  5. Best scores and map unlocks persist across quitting and relaunching. The save file carries a schema version, and automated tests load older-version fixture saves and migrate them correctly.

**Plans**: TBD
**UI hint**: yes

### Phase 10: Loadout & Meta-Progression

**Goal**: Runs feed a persistent player level that unlocks a pre-run loadout of weapons, perks, and stacking mutators, and the owner confirms the meta layer feels rewarding before the campaign finale is authored.
**Mode:** mvp
**Depends on**: Phase 9
**Requirements**: META-01, META-02, META-03, META-05, META-06, UI-03
**Success Criteria** (what must be TRUE):
  1. The player goes from main menu to map select to the loadout screen and picks:
     - one unlocked weapon (5 total, each with a distinct passive attack and active ability)
     - perks up to their unlocked slot count (maximum 5), from 30+ spanning economy, military, defense, towers, king, and utility
     - any of 10+ mutators, with a live score-multiplier preview that stacks mutators multiplicatively
  2. Every completed run awards XP based on its score toward a persistent player level. The results screen shows the score breakdown, XP gained, and new unlocks. Level-ups unlock weapons, perks, perk slots, and heroes on a front-loaded curve that makes all v1 content reachable within the campaign.
  3. The player can pause any run and resume, restart, or quit to the menu. Level, XP, and unlocks persist across relaunch.
  4. Every perk and mutator effect has an automated test through the documented stat-modifier order, including combined-stack cases.
  5. Human playtest gate: the owner plays maps 1–2 with several weapon/perk/mutator loadouts and signs off that weapons and perks feel distinct, mutators feel worth their risk, and the unlock pace feels rewarding, before maps 3–5 are authored.

**Plans**: TBD
**UI hint**: yes

### Phase 11: Campaign Finale & Boss Nights

**Goal**: The full 5-map campaign is playable end to end. Each map feels distinct, maps 3–5 end with boss nights, and difficulty climbs from map to map while every map stays winnable with the loadout available at that point.
**Mode:** mvp
**Depends on**: Phase 10
**Requirements**: MAP-01, MAP-03, MAP-05, ENMY-06, ENMY-07
**Success Criteria** (what must be TRUE):
  1. The campaign has 5 hand-crafted maps, each with its own layout, build spots, spawn points, night count, and starting gold, playable in sequence from map 1 to map 5.
  2. Every map has at least one distinguishing element (a unique building, terrain gimmick, or unique mechanic). Every map after the first introduces at least one enemy type found nowhere else.
  3. Maps 3, 4, and 5 each end with a boss night featuring a unique boss enemy.
  4. Difficulty rises from map to map. Seeded simulated playthroughs and an owner playtest confirm that each map, including each boss night, is winnable with the weapons, perks, and heroes unlocked by that point, with no difficulty cliff.

**Plans**: TBD

### Phase 12: Research Buildings

**Goal**: Players can invest in multi-day research at a Blacksmith and a Royal Forge for global buffs. This is a self-contained optional depth layer: it is the designated scope cut and can be deferred without affecting any other phase.
**Mode:** mvp
**Depends on**: Phase 11 (technically needs only Phase 5's stat-modifier system; no phase depends on this one)
**Requirements**: BLDG-12, BLDG-13
**Success Criteria** (what must be TRUE):
  1. The player can build a Blacksmith and a Royal Forge, start timed research that spans multiple days, and watch its progress. Completed research grants global buffs to the king, units, or buildings.
  2. Research pauses while its building is destroyed and resumes after the dawn rebuild. Higher research-building tiers add research slots.
  3. Each research buff combines through the documented stat-modifier order with automated tests. Seeded campaign playthroughs confirm the maps stay challenging with research available.

**Plans**: TBD
**UI hint**: yes

### Phase 13: Settings & Release

**Goal**: A finished, shippable Windows game: full settings, credits, and menus that work with any device, published on itch.io as a build that runs on a clean machine.
**Mode:** mvp
**Depends on**: Phase 11 (and Phase 12 unless deferred)
**Requirements**: INPT-03, UI-04, UI-07, PLAT-02, PLAT-03
**Success Criteria** (what must be TRUE):
  1. The settings menu offers key rebinding, resolution, window mode, vsync, master and SFX volume, and graphics quality presets. Changes persist between sessions.
  2. Every menu can be navigated with mouse or keyboard, with the focused element always visible.
  3. A credits screen lists every third-party asset and its license, matching the repository's attribution log.
  4. A Windows build exported from the command line launches and plays the full campaign on a clean Windows machine with no extra installs, holding 60 fps in the largest campaign battles.
  5. The game is live on itch.io with a store page that uses only original branding (no Thronefall names or assets) and explains the Windows SmartScreen warning.

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Day Loop | 18/18 | Complete    | 2026-10-03 |
| 2. Night Defense & Playtest Gate | 22/22 | Complete    | 2026-10-08 |
| 3. King Combat & Troops | 19/19 | Complete    | 2026-10-15 |
| 4. Crowd-Scale Battles & Walls | 28/28 | Complete    | 2026-10-21 |
| 5. Castle Center & Economy Depth | 14/24 | In Progress|  |
| 6. Enemy Roster & Tower Specializations | 0/TBD | Not started | - |
| 7. Army Variety & Heroes | 0/TBD | Not started | - |
| 8. Art, Readability & Sound | 0/TBD | Not started | - |
| 9. Campaign Opening & Scoring | 0/TBD | Not started | - |
| 10. Loadout & Meta-Progression | 0/TBD | Not started | - |
| 11. Campaign Finale & Boss Nights | 0/TBD | Not started | - |
| 12. Research Buildings | 0/TBD | Not started | - |
| 13. Settings & Release | 0/TBD | Not started | - |

## Backlog

### Phase 999.1: Follow-up — Phase 01 deferred UAT follow-up: Test 4 (BACKLOG)

**Goal:** Resolve the UAT checkpoint deferred during Phase 01 verification
**Source phase:** 01
**Deferred at:** 2026-10-02 during /gsd-verify-work 01 session completion
**Follow-ups:**
- [ ] Test 4: yes, but a small minimap would be nice (deferred 2026-10-01)
