# Duskhold (codename)

## What This Is

A faithful, from-scratch recreation of Thronefall's gameplay as a Windows PC game: a minimalist, low-poly 3D strategy game that blends tower defense, light city-building, and action. By day the player — a king on horseback — rides to fixed build spots and holds the action key to spend gold on economy, defenses, and military; by night they fight alongside their troops against escalating enemy waves. Survive every night to win the map; lose if the castle center falls. Controls follow Thronefall (movement + one action key + a few hotkeys, keyboard or gamepad). Built as a portfolio/learning project, distributed as a downloadable Windows build on itch.io, using an original name and CC0 assets (no Thronefall IP).

## Core Value

The day/night build-then-defend loop must feel as tight and satisfying as Thronefall's: meaningful gold trade-offs by day, readable and tense defense by night. On a single map with zero meta-progression, it must already be fun to play.

## Requirements

### Validated

(None yet — ship to validate)

### Active

Full, testable list with REQ-IDs: `.planning/REQUIREMENTS.md`. Summary:

**Core loop**
- [ ] Day/night cycle: build phase → deliberately triggered night → wave defense → dawn payout
- [ ] Castle center is the loss condition; surviving the final night of a map is the win condition
- [ ] Destroyed buildings are restored free at dawn (no income that morning)
- [ ] Next night's enemy counts per spawn point are telegraphed during the day
- [ ] Retry a failed night at a score penalty

**King (player avatar)**
- [ ] Mounted king moves with WASD / left stick and fights directly (weapon passive auto-attack + active ability)
- [ ] King can be knocked out and respawns after a delay (does not end the run)
- [ ] King is the only builder: ride to a build spot and hold the action key to build/upgrade (Thronefall style)

**Economy & building**
- [ ] Single currency (gold); economic buildings (House, Gold Mine, Mill + Fields, Fishing Harbor, Shrine) pay at dawn with distinct income curves
- [ ] Fixed, pre-placed build spots per map
- [ ] Full-depth branching upgrades (pick 1-of-N per tier) for Castle Center, Towers, and military buildings
- [ ] Walls/barricades and multiple tower specializations
- [ ] Blacksmith and Royal Forge multi-day research with global buffs

**Military**
- [ ] Barracks, Archery Range, Hero's Quarter with 4 unit/hero choices each
- [ ] Units fight autonomously; hotkeys for hold position and rally/follow

**Enemies & waves**
- [ ] Varied enemy roster (melee, ranged, fast, tank, flying, siege, anti-king, exploder) that counters single-strategy defenses
- [ ] Hand-authored, escalating waves per night per map; unique enemies per map; boss nights on maps 3–5

**Campaign & meta-progression**
- [ ] 5 handcrafted maps with distinct layouts, gimmicks, and unique content
- [ ] Player level (XP from map runs) unlocking weapons, perks, perk slots, and heroes
- [ ] 5 king weapons, 30+ perks (up to 5 equipped), 10+ stacking mutators
- [ ] Thronefall-style scoring, per-map high scores, soft retry penalty

**Presentation & platform**
- [ ] Minimal HUD; menus (main, map select, loadout, pause, settings, results)
- [ ] Settings: key/button rebinding, display, audio volume, graphics quality
- [ ] Keyboard and gamepad play; mouse for menus only
- [ ] Stylized low-poly 3D using normalized CC0 asset packs; readable at night
- [ ] SFX for core feedback
- [ ] Versioned save of campaign progress
- [ ] Windows build on itch.io; 60 fps on modest hardware with hundreds of units

### Out of Scope

- Thronefall's name, art, maps, UI, or other assets — IP; original codename + CC0 assets only
- Click-to-build / remote building — dropped in favor of Thronefall's ride-up-and-hold building (keeps travel time as a cost and the camera on the king)
- Mouse unit commands and mouse-aimed king attacks — mouse is for menus only; faithful to Thronefall's controls
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

**Development context:**
- Portfolio/learning project; Claude writes most of the code, so the project favors text-editable scenes/data and headless/CLI test runs
- Engine chosen by research: Godot 4.7.2-stable + GDScript (see `.planning/research/STACK.md`)
- Asset sources: CC0 low-poly medieval packs (Kenney, KayKit, Quaternius) plus CC0 SFX
- Research highlights: simulation/presentation split for headless testing, data-driven content (.tres), data-oriented units (MultiMesh), stat-modifier stacking order and save versioning designed up front, human playtest gates (see `.planning/research/SUMMARY.md`)

## Constraints

- **Tech stack**: Godot 4.7.2-stable, GDScript (standard build), GUT 9.7.1 tests, gdtoolkit lint/format — text-based scenes/resources and headless CLI for AI-driven development
- **Assets**: CC0 (or equally permissive) only — clean licensing for a public portfolio; attribution log maintained
- **IP**: No Thronefall trademarks, names, or assets; the mechanics are recreated, the content is original
- **Platform**: Windows PC; keyboard and gamepad gameplay, mouse for menus
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
| Thronefall-style controls: ride up + hold action key to build; hotkeys for units; keyboard + gamepad; mouse for menus only | Research flagged click-to-build as the #1 design risk (removes travel cost and king-centric camera); owner chose to stay true to Thronefall | — Pending |
| Player level (XP from map runs) instead of separate per-map levels | Matches Thronefall's actual progression model | — Pending |
| Low-poly 3D, CC0 asset packs | Matches Thronefall's look; zero cost; fast cohesive visuals | — Pending |
| SFX only in v1 | Core feedback matters most; music can be added later | — Pending |
| Godot 4.7.2-stable + GDScript | Text-based scenes/resources + headless CLI best suit AI-agent-driven development; MIT license; verified latest stable (2026-08-18) | — Pending |
| Codename "Duskhold" | Placeholder; must not reuse Thronefall branding | — Pending |

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
*Last updated: 2026-09-28 after requirements scoping*
