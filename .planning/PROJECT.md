# Duskhold (codename)

## What This Is

A faithful, from-scratch recreation of Thronefall's gameplay as a Windows PC game: a minimalist, low-poly 3D strategy game that blends tower defense, light city-building, and action. By day the player — a king on horseback — rides to fixed build spots and holds the action key to spend gold on economy, defenses, and military; by night they fight alongside their troops against escalating enemy waves. Survive every night to win the map; lose if the castle center falls. Controls follow Thronefall (movement + one action key + a few hotkeys, keyboard or gamepad). Built as a portfolio/learning project, distributed as a downloadable Windows build on itch.io, using an original name and CC0 assets (no Thronefall IP).

## Core Value

The day/night build-then-defend loop must feel as tight and satisfying as Thronefall's: meaningful gold trade-offs by day, readable and tense defense by night. On a single map with zero meta-progression, it must already be fun to play.

## Requirements

### Validated

- ✓ King is the only builder: ride to a build spot and hold the action key to build or upgrade (accelerating coin drip, refund on early release) — Phase 1
- ✓ Fixed, pre-placed build spots per map (prototype sandbox map) — Phase 1
- ✓ Mounted king movement with WASD / left stick and sprint, fixed follow camera with zoom — Phase 1 (combat follows in Phase 2)
- ✓ Gold as the single currency, with House income paid at dawn and unspent gold carried over — Phase 1 (other economic buildings follow later)
- ✓ Deliberately triggered night and dawn payout loop, with an enemy-free placeholder night — Phase 1 (wave defense follows in Phase 2)
- ✓ Agent-verification tooling: headless GUT suite, lint, CI with Windows export and screenshots, debug overlay, CC0 asset log — Phase 1
- ✓ Full day → night → dawn loop: telegraphed per-spawn-point enemy counts, hold-to-confirm night start, escalating waves, dawn rebuild of destroyed buildings (marked as paying nothing that morning) and House income, loss the instant the castle falls, win after the final night on a results screen — Phase 2
- ✓ King passive auto-attack, knockout and respawn at the castle after a visible countdown; castle attack and base dawn income added at the owner's playtest gate — Phase 2 (active ability follows in Phase 3)
- ✓ Seeded deterministic simulation with an event recorder, golden replays, bot playtests and a CI replay step; the owner signed off the core loop after four playtest rounds (2026-10-08) — Phase 2
- ✓ Barracks and Archery Range squads that guard their post, commit to targets, trickle back from their building at night and are restored at dawn; RTS-style selection (click, drag box, Ctrl, strip slot, pad cycling), numbered control groups, and hold / follow / rally / move / attack-move / patrol orders with Shift (pad RT) queuing — Phase 3 (Hero's Quarter and the per-building unit choices follow later)
- ✓ The king's weapon active ability (sword slam on Q / pad X, 9 s cooldown shown on the HUD) and health regeneration after 1 s without damage — Phase 3
- ✓ Every in-run action on keyboard and mouse or on gamepad (D-pad verbs with an LB layer, right-stick ground cursor), prompts that follow the active device, and the in-run HUD (gold, night counter, king widget, squad strip, command hints) with a clear centre; the owner signed off on keyboard and mouse and a DualShock 4 (2026-10-15) — Phase 3

### Active

Full, testable list with REQ-IDs: `.planning/REQUIREMENTS.md`. Summary:

**Core loop**
- [ ] Retry a failed night at a score penalty

**Economy & building**
- [ ] Single currency (gold); economic buildings (House, Gold Mine, Mill + Fields, Fishing Harbor, Shrine) pay at dawn with distinct income curves
- [ ] Full-depth branching upgrades (pick 1-of-N per tier) for Castle Center, Towers, and military buildings
- [ ] Walls/barricades and multiple tower specializations
- [ ] Blacksmith and Royal Forge multi-day research with global buffs

**Military**
- [ ] Hero's Quarter, and the 4 unit/hero choices per military building (the default Barracks and Archery Range squads shipped in Phase 3)

**Enemies & waves**
- [ ] Varied enemy roster (melee, ranged, fast, tank, flying, siege, anti-king, exploder) that counters single-strategy defenses
- [ ] Hand-authored, escalating waves per night per map; unique enemies per map; boss nights on maps 3–5

**Campaign & meta-progression**
- [ ] 5 handcrafted maps with distinct layouts, gimmicks, and unique content
- [ ] Player level (XP from map runs) unlocking weapons, perks, perk slots, and heroes
- [ ] 5 king weapons, 30+ perks (up to 5 equipped), 10+ stacking mutators
- [ ] Thronefall-style scoring, per-map high scores, soft retry penalty

**Presentation & platform**
- [ ] Menus (main, map select, loadout, pause, settings, results), reachable on keyboard and mouse or gamepad like the in-run HUD shipped in Phase 3
- [ ] Settings: key/button rebinding, display, audio volume, graphics quality
- [ ] Stylized low-poly 3D using normalized CC0 asset packs; readable at night
- [ ] SFX for core feedback
- [ ] Versioned save of campaign progress
- [ ] Windows build on itch.io; 60 fps on modest hardware with hundreds of units

### Out of Scope

- Thronefall's name, art, maps, UI, or other assets — IP; original codename + CC0 assets only
- Click-to-build / remote building — dropped in favor of Thronefall's ride-up-and-hold building (keeps travel time as a cost and the camera on the king)
- Mouse-aimed king attacks and mouse building — attacks stay automatic and building stays ride-up-and-hold; mouse unit commands returned on 2026-10-09 (see Context)
- Music — SFX only in v1; music deferred to a later milestone
- Multiplayer / co-op — Thronefall is single-player; large added complexity
- Mac / Linux / Switch / mobile / web builds — Windows itch.io build only for v1
- Steam integration (achievements, cloud saves, leaderboards) — not a commercial release
- Custom-modeled art — CC0 packs cover v1
- Localization — English only
- Full 10-map parity — v1 is a 5-map campaign
- Procedural/random maps or waves — Thronefall's maps and waves are handcrafted
- Per-kill gold bounties, multiple currencies, free building placement, permadeath — contradict Thronefall's design

## Context

**Reference game — Thronefall** (Grizzly Games, 2-person team, Unity; early access Aug 2023, 1.0 Oct 2024; ~1M copies in year one; ~95% positive on Steam; $6.49):
- Minimalist strategy / tower defense / light city-builder with an action layer; the king rides a small horse through a small stylized world
- Day: ride to fixed build spots and hold the action key to spend gold — economy (houses, fields, mines, harbors), defense (walls, barricades, towers, shrines), military (barracks, archery range, hero quarters); castle center upgrades with ability choices; research buildings (blacksmith, royal forge)
- Night: waves attack from telegraphed spawn points; the king fights directly; the night ends when all enemies are dead
- Dawn: destroyed buildings return free but earn nothing that morning; surviving economic buildings pay gold
- Units: knights, berserkers, crossbowmen, fire archers, golems, mages; enemies include barrel knights, flying mages, ogres, slimes, wasps, catapults
- Meta: 10 maps, weapons (passive + active ability), 50+ perks (up to 5 per run), mutators with stacking score/XP multipliers, player level unlocks; retrying costs the no-restart score bonus
- Controls: move + one main action key (hold to build, press to attack) + unit hotkeys; controller-first design
- Design philosophy: built for time-constrained players; fixed build spots let features be added without breaking earlier levels

**Deliberate deviations from Thronefall:** SFX only (no music) in v1; original names, maps, and CC0 art.

**Controls change (2026-09-28):** The project was first scoped with keyboard + mouse controls (mouse click on build spots to build/upgrade, mouse unit commands). During requirements scoping, research flagged click-to-build as the #1 design risk, and the owner switched to Thronefall's original scheme: WASD / left stick moves the king, riding to a build spot and holding the action key builds or upgrades, hotkeys command units (hold position; follow the king — all or one unit type), gameplay works on keyboard and gamepad, and **the mouse is used only in menus**. Research documents written before the change carry an inline "Controls decision update" note.

**Controls change (2026-10-09):** While discussing Phase 3 the owner brought the mouse back for unit commands: "mouse use is kind of a necessity now i realize in hindsight." Squads are selected by click, drag box and Ctrl, stored as numbered control groups, and ordered to move, rally, attack-move or patrol with mouse-supplied ground points, Age of Empires style; the gamepad reaches the same commands by cycling squads and a right-stick cursor. Building stays ride-up-and-hold, the king's attacks stay automatic, and the follow camera stays locked on the king. Recorded in `.planning/phases/03-king-combat-troops/03-CONTEXT.md` (D-09 to D-16, D-25) and REQUIREMENTS.md (UNIT-09, UNIT-10, INPT-01, INPT-03).

**Development context:**
- Portfolio/learning project; Claude writes most of the code, so the project favors text-editable scenes/data and headless/CLI test runs
- Engine chosen by research: Godot 4.7.2-stable + GDScript (see `.planning/research/STACK.md`)
- Asset sources: CC0 low-poly medieval packs (Kenney, KayKit, Quaternius) plus CC0 SFX
- Research highlights: simulation/presentation split for headless testing, data-driven content (.tres), data-oriented units (MultiMesh), stat-modifier stacking order and save versioning designed up front, human playtest gates (see `.planning/research/SUMMARY.md`)

## Constraints

- **Tech stack**: Godot 4.7.2-stable, GDScript (standard build), GUT 9.7.1 tests, gdtoolkit lint/format — text-based scenes/resources and headless CLI for AI-driven development
- **Assets**: CC0 (or equally permissive) only — clean licensing for a public portfolio; attribution log maintained
- **IP**: No Thronefall trademarks, names, or assets; the mechanics are recreated, the content is original
- **Platform**: Windows PC; keyboard and mouse, or gamepad, for all gameplay (Thronefall-style: ride up and hold the action key to build; RTS-style squad selection, control groups and orders with the mouse or a pad cursor); click-to-build stays dropped, mouse unit commands returned 2026-10-09
- **Budget**: Zero-cost tools and assets (no code-signing certificate)
- **Performance**: Modest hardware (roughly GTX 970 / 4 GB RAM); 60 fps with hundreds of units and projectiles on screen

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Faithful recreation of Thronefall's loop | Goal is to nail what makes Thronefall good, not invent a new game | — Pending |
| Portfolio/learning purpose, itch.io Windows build | Not a commercial release; keeps scope on gameplay quality over storefront features | — Pending |
| v1 = 5-map campaign with large meta content (5 weapons, 30+ perks, 10+ mutators) and full-depth upgrade trees | Owner wants full system depth and breadth in v1 | — Pending |
| All optional buildings in v1, including Blacksmith/Royal Forge | Owner choice; research flags research buildings as the safest cut if scope pressure hits | — Pending |
| Boss nights on maps 3, 4 and 5 | Owner choice; research warns about boss difficulty cliffs — tune carefully | — Pending |
| Thronefall-style controls: ride up + hold action key to build; hotkeys for units; keyboard + gamepad; mouse for menus only | Research flagged click-to-build as the #1 design risk (removes travel cost and king-centric camera); owner chose to stay true to Thronefall | ✓ Good — build hold validated in Phase 1 UAT; the mouse-for-menus-only half was reversed for unit commands on 2026-10-09 (next row) |
| Mouse returns for squad commands (selection, control groups, move / rally / attack-move / patrol points), Age of Empires style; gamepad parity by squad cycling and a right-stick cursor; building and king attacks unchanged | Owner decision at the Phase 3 discussion ("mouse use is kind of a necessity now i realize in hindsight"); hotkeys alone could not express custom control groups and point orders | ✓ Good — Phase 3 shipped it; the owner signed off on keyboard and mouse and on a DualShock 4 (UAT 25 of 25, 2026-10-15) |
| Player level (XP from map runs) instead of separate per-map levels | Matches Thronefall's actual progression model | — Pending |
| Low-poly 3D, CC0 asset packs | Matches Thronefall's look; zero cost; fast cohesive visuals | — Pending |
| SFX only in v1 | Core feedback matters most; music can be added later | — Pending |
| Godot 4.7.2-stable + GDScript | Text-based scenes/resources + headless CLI best suit AI-agent-driven development; MIT license; verified latest stable (2026-08-18) | ✓ Good — Phase 1 shipped on it (363 headless tests, CI export) |
| Codename "Duskhold" | Placeholder; must not reuse Thronefall branding | — Pending |
| Build hold pacing: first coin after 0.25 s, accelerating (decay 0.9) to one coin every 0.05 s, no time cap, all-or-nothing refund | Owner feel checks in Phase 1 UAT (tests 58 to 60); expensive buildings must not drag, and nothing is fast-forwarded | ✓ Good — Phase 1 |
| Playtest-gate tuning after four owner rounds: base income 1 gold per dawn, castle attack (2 damage every 1.5 s, 22 m reach, 27 m/s arrows), walk 7.5 m/s with a 12 m/s sprint, night-only 2x fast-forward toggle, full-wall night counts (balanced bot wins 7 or 8 of 10 seeds) | Owner feel decisions recorded through /gsd-verify-work rounds 1 to 4; the balance bots measure, only the owner judges fun | ✓ Good — owner signed off the core loop 2026-10-08 |
| Deterministic fixed-step simulation (SimClock 1/30 s, seeded RNG, integer event recorder, golden replays) under simulation/, with a presentation layer that never writes the sim | Seeded replays and bot playtests are the agent's own playtest (DEV-05); nothing under simulation/ may read time, OS or the time scale | ✓ Good — the smoke golden held across 22 plans and Linux matched the Windows digest |
| While a squad is selected all movement input (keys and stick) steers the selection and the king stands; attack-move stays on A; Escape with nothing armed clears the selection | Owner decision at the 03-07 checkpoint (2026-10-10, amending D-11 and D-15) | ✓ Good — passed UAT rounds 1 and 3 |
| Round 2 balance: tower tier 1 attack interval 0.9 s and night 8 north count 11, with a 0.8 squad-value bar (D-26 to D-28); the balanced and army bots win 8 of 10 seeds and night 8 (40) rises above night 7 (39) | Owner asked for all four balance goals at once; the retune moved the fewest values of 29 candidates and no locked value | ✓ Good — the owner passed the fixed build (UAT test 18, 2026-10-14) |
| Gamepad layout: D-pad verbs with an LB layer for move / attack-move / patrol on a 900 px/s right-stick cursor, R3 select all, LB+R3 select type, Start group mode, RT queue, B cancel; Xbox glyph tiles for every pad | RESEARCH A11; chosen by Claude pending a real pad | ✓ Good — passed on a DualShock 4 (UAT test 23, 2026-10-15) |
| Long refusal toasts (526 and 540 px at Body 22) accepted below the clear centre; UI-SPEC toast bound amended (D-29) | Owner decision at UAT test 22 (2026-10-14): readable copy beats the estimated width | ✓ Good — WINDOWS.md entry 4 waived |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-10-15 after Phase 3*
