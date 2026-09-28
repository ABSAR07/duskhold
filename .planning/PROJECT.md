# Duskhold (codename)

## What This Is

A faithful, from-scratch recreation of Thronefall's gameplay as a Windows PC game: a minimalist, low-poly 3D strategy game that blends tower defense, light city-building, and action. By day the player — a king on horseback — spends gold on fixed build spots (economy, defenses, military); by night they fight alongside their troops against escalating enemy waves. Survive every night to win the map; lose if the castle center falls. Built as a portfolio/learning project, distributed as a downloadable Windows build on itch.io, using an original name and CC0 assets (no Thronefall IP).

## Core Value

The day/night build-then-defend loop must feel as tight and satisfying as Thronefall's: meaningful gold trade-offs by day, readable and tense defense by night. On a single map with zero meta-progression, it must already be fun to play.

## Requirements

### Validated

(None yet — ship to validate)

### Active

**Core loop**
- [ ] Day/night cycle: build phase → player-triggered night → wave defense → dawn payout
- [ ] Castle center is the loss condition; surviving the final night of a map is the win condition
- [ ] Destroyed buildings are restored at dawn
- [ ] Next night's enemy spawn directions are telegraphed during the day

**King (player avatar)**
- [ ] Mounted king moves with WASD and fights directly during nights (weapon-driven attacks)
- [ ] King can be knocked out and returns after a delay (does not end the run)

**Economy & building**
- [ ] Single currency (gold); economic buildings (houses, fields/farms, mines, harbors) pay gold at dawn only if they survived the night
- [ ] Buildings occupy fixed, pre-placed build spots per map (Thronefall's design)
- [ ] Mouse click on a build spot to build/upgrade; costs shown clearly
- [ ] Buildings have branching upgrade choices (pick one of N options per upgrade tier)
- [ ] Castle center can be upgraded with ability choices
- [ ] Defensive structures: walls/barricades and multiple tower types

**Military**
- [ ] Military buildings (e.g. barracks, archery range) produce troop squads (melee, ranged, and specialist types)
- [ ] Mouse commands for unit groups: select, rally/move, hold position; troops also fight autonomously

**Enemies & waves**
- [ ] Varied enemy roster (melee, ranged, fast, flying, tanky, siege) that counters single-strategy defenses
- [ ] Hand-authored waves per night per map, escalating in difficulty

**Campaign & meta-progression**
- [ ] Small campaign: 3–5 handcrafted maps with distinct layouts and challenges
- [ ] Per-map XP / levels that unlock weapons and perks
- [ ] Unlockable king weapons, each with a passive attack and an active ability
- [ ] Unlockable perks; limited perk loadout chosen before each run
- [ ] Optional mutators that raise difficulty in exchange for score/XP multipliers
- [ ] Per-map scoring and high scores; retrying a night is allowed with a score penalty

**Presentation & platform**
- [ ] Minimal HUD: gold, day/night counter, costs, upgrade choices, unit selection
- [ ] Menus: main menu, map select, pre-run loadout (weapon/perks/mutators), pause, settings, results screen
- [ ] Stylized low-poly 3D look using CC0 asset packs, with a cohesive color palette
- [ ] SFX for core feedback (combat hits, building, coins, UI, night start/dawn)
- [ ] Campaign progress (unlocks, XP, high scores) persists between sessions
- [ ] Exported Windows build, playable from an itch.io download

### Out of Scope

- Thronefall's name, art, maps, UI, or other assets — IP; original codename + CC0 assets only
- Gamepad support — keyboard + mouse chosen for v1; revisit later
- Mouse-aimed king attacks — mouse is for building, unit commands, and UI only
- Music — SFX only in v1; music deferred to a later milestone
- Multiplayer / co-op — Thronefall is single-player; large added complexity
- Mac / Linux / Switch / mobile / web builds — Windows itch.io build only for v1
- Steam integration (achievements, cloud saves, leaderboards) — not a commercial release
- Custom-modeled art — CC0 packs cover v1
- Localization — English only
- Full 10-map parity / DLC-scale content — v1 is a small campaign
- Procedural/random maps — Thronefall's maps are handcrafted; faithful recreation

## Context

**Reference game — Thronefall** (Grizzly Games, 2-person team, Unity; early access Aug 2023, 1.0 Oct 2024; ~1M copies in year one; ~95% positive on Steam; $6.49):
- Minimalist strategy / tower defense / light city-builder with an action layer; the king rides a small horse through a small stylized world
- Day: spend gold on fixed build spots — economy (houses, fields, mines, harbors), defense (walls, barricades, towers, shrines), military (barracks, archery range, hero quarters); castle center upgrades twice with ability choices; research buildings (blacksmith, royal forge) exist in the full game
- Night: waves attack; the king fights directly; the night ends when all enemies are dead
- Dawn: destroyed buildings return; surviving economic buildings pay gold
- Units: knights, berserkers, crossbowmen, fire archers, golems, mages; enemies include barrel knights, flying mages, ogres, slimes, wasps, catapults
- Meta: 10 maps, 9 weapons (passive + active ability), 50+ perks (up to 5 per run), mutators with score/XP multipliers, per-map levels; retrying a day costs score
- Original controls: move + one main action key (hold to build, press to attack) + unit hotkeys; controller-first design
- Design philosophy: built for time-constrained players; fixed build spots let features be added without breaking earlier levels

**Deliberate deviations from Thronefall:**
- Keyboard + mouse: WASD moves the king; the mouse clicks build spots/upgrades, commands unit groups, and drives menus (Thronefall uses ride-up-and-hold plus hotkeys)
- SFX only (no music) in v1

**Development context:**
- Portfolio/learning project; Claude writes most of the code, so the engine should favor text-editable scenes/data and headless/CLI test runs
- Asset sources: CC0 low-poly medieval packs (e.g. Kenney, KayKit, Quaternius) plus CC0 SFX
- Engine not yet chosen — to be decided by stack research

## Constraints

- **Tech stack**: Engine TBD by research. Must support stylized low-poly 3D, Windows export, many simultaneous units at 60 fps; strongly prefer text-based scene/resource files and a headless/CLI workflow for AI-driven development and automated tests
- **Assets**: CC0 (or equally permissive) only — clean licensing for a public portfolio
- **IP**: No Thronefall trademarks, names, or assets; the mechanics are recreated, the content is original
- **Platform**: Windows PC; keyboard + mouse input
- **Budget**: Zero-cost tools and assets
- **Performance**: Modest hardware (Thronefall's minimum spec is roughly a GTX 970 with 4 GB RAM); stay smooth with hundreds of units and projectiles on screen

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Faithful recreation of Thronefall's loop | Goal is to nail what makes Thronefall good, not invent a new game | — Pending |
| Portfolio/learning purpose, itch.io Windows build | Not a commercial release; keeps scope on gameplay quality over storefront features | — Pending |
| v1 = small campaign (3–5 maps) with full meta-progression (weapons, perks, mutators/score, map XP) | Shows the full system depth without 10-map content cost | — Pending |
| Low-poly 3D, CC0 asset packs | Matches Thronefall's look; zero cost; fast cohesive visuals | — Pending |
| Keyboard + mouse (click-to-build, mouse unit commands) | Player preference; diverges from Thronefall's single-key controller-first scheme | — Pending |
| SFX only in v1 | Core feedback matters most; music can be added later | — Pending |
| Engine chosen by research | Needs a comparison weighted toward AI-driven, text-based workflows | — Pending |
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
*Last updated: 2026-09-28 after initialization*
