# Requirements: Duskhold (codename)

**Defined:** 2026-09-28
**Core Value:** The day/night build-then-defend loop must feel as tight and satisfying as Thronefall's — meaningful gold trade-offs by day, readable and tense defense by night — and be fun on a single map with zero meta-progression.

## v1 Requirements

Requirements for the initial release (5-map campaign). Each maps to exactly one roadmap phase.

### Core Loop

- [ ] **LOOP-01**: Player can take as long as they want during the day (no timer) and starts the night only through a deliberate hold-to-confirm input
- [ ] **LOOP-02**: During the day, player can see an icon at each spawn point showing how many enemies will arrive there that night
- [ ] **LOOP-03**: The night ends only when every enemy spawned that night is dead, after which dawn begins
- [ ] **LOOP-04**: At dawn, buildings destroyed during the night are rebuilt automatically at no cost
- [ ] **LOOP-05**: At dawn, each surviving economic building pays its gold income, while buildings rebuilt that morning pay nothing and are visibly marked as not paying
- [ ] **LOOP-06**: Player loses the run immediately when the castle center is destroyed
- [ ] **LOOP-07**: Player wins the map by surviving its final night, and the run ends on a results screen
- [ ] **LOOP-08**: After losing, player can retry from the start of the failed night's day or restart the map; using retry forfeits the no-restart score bonus

### King

- [ ] **KING-01**: Player can move the mounted king with WASD or the left stick, with a sprint modifier
- [ ] **KING-02**: The camera follows the king from a fixed isometric-style angle
- [ ] **KING-03**: The king automatically attacks enemies in range using the equipped weapon's passive attack
- [ ] **KING-04**: Player can trigger the equipped weapon's active ability, which then shows a visible cooldown
- [ ] **KING-05**: The king's health regenerates after a short period without taking damage
- [ ] **KING-06**: When the king's health reaches zero, the king is knocked out and respawns at the castle after a visible countdown; the run continues

### Building

- [ ] **BLDG-01**: Each map has fixed, pre-placed build spots, and buildings can only exist on those spots
- [ ] **BLDG-02**: When the king is near a build spot during the day, player sees what can be built there and its gold cost
- [ ] **BLDG-03**: Player can build on an empty spot by holding the action key near it, with a visible hold-progress indicator, if they can afford the cost
- [ ] **BLDG-04**: Player can upgrade an existing building the same way, seeing the next tier's cost and effect
- [ ] **BLDG-05**: When an upgrade tier offers branching options, player picks one of the offered choice cards (with keyboard or gamepad), and that choice is permanent for the run
- [ ] **BLDG-06**: Building and upgrading is only possible during the day
- [ ] **BLDG-07**: Buildings have health, take damage from enemies, and are visibly destroyed at zero health
- [ ] **BLDG-08**: Player can upgrade the castle center through its tiers for more health, picking one of four run-wide abilities or passives at each tier
- [ ] **BLDG-09**: The castle center's tier gates which higher building tiers can be purchased
- [ ] **BLDG-10**: Player can build walls and barricades that block enemy movement and upgrade linearly in health
- [ ] **BLDG-11**: Player can build towers that attack enemies, upgrading through a tier-2 choice of four specializations and a tier-3 choice of four further specializations, each with a distinct attack behavior
- [ ] **BLDG-12**: Player can build a Blacksmith and a Royal Forge and start timed research (spanning multiple days) that grants global buffs to the king, units, and buildings
- [ ] **BLDG-13**: Research progress pauses while its building is destroyed, and higher research-building tiers add research slots

### Economy

- [ ] **ECON-01**: Gold is the only currency, and the HUD always shows the player's current gold
- [ ] **ECON-02**: A House pays a flat income each dawn that increases with its upgrade tier
- [ ] **ECON-03**: A Gold Mine pays a high income that declines by a fixed amount each night
- [ ] **ECON-04**: A Mill pays income per tier and unlocks nearby Field build spots, each Field paying a flat income
- [ ] **ECON-05**: A Fishing Harbor gains a boat each night up to a cap (raised by upgrading), and each boat pays income
- [ ] **ECON-06**: A Shrine activates after enough enemies die near it; once active it attacks enemies and pays income, and each additional active Shrine strengthens the others
- [ ] **ECON-07**: Unspent gold carries over from day to day

### Military Units

- [ ] **UNIT-01**: When building a Barracks, player picks one of four melee unit types; the Barracks produces a squad over time up to a cap that grows with its tier
- [ ] **UNIT-02**: When building an Archery Range, player picks one of four ranged unit types, produced the same way
- [ ] **UNIT-03**: When building a Hero's Quarter, player picks one of four heroes; the single hero grows stronger with each tier and revives after a long timer when killed
- [ ] **UNIT-04**: Units fight autonomously near their post, committing to targets rather than constantly switching
- [ ] **UNIT-05**: Player can order units to hold their current position with a hotkey
- [ ] **UNIT-06**: Player can order units to follow the king with a hotkey, for all units or for a selected unit type
- [ ] **UNIT-07**: Units killed during the night slowly respawn at their building, and all units are fully restored at dawn
- [ ] **UNIT-08**: Unit types have distinct roles and counters (e.g. anti-air, anti-siege, anti-armor, healing)

### Enemies & Waves

- [ ] **ENMY-01**: The shared enemy roster covers melee, ranged, fast, tank, flying, siege, anti-king, and exploder roles
- [ ] **ENMY-02**: Siege enemies target buildings first, and anti-king enemies target the king first
- [ ] **ENMY-03**: Flying enemies ignore walls and can only be hit by attackers that can reach air targets
- [ ] **ENMY-04**: Enemies path toward their targets around or through defenses without jamming indefinitely at walls or chokepoints
- [ ] **ENMY-05**: Each night of each map uses a hand-authored wave composition per spawn point that escalates in count, variety, and spawn directions
- [ ] **ENMY-06**: Each map after the first introduces at least one enemy type unique to that map
- [ ] **ENMY-07**: Maps 3, 4, and 5 each end with a boss night featuring a unique boss enemy

### Campaign & Maps

- [ ] **MAP-01**: The campaign has 5 hand-crafted maps, each with its own layout, build spots, spawn points, night count, and starting gold
- [ ] **MAP-02**: Map 1 teaches the core loop through in-game prompts (moving, building, starting the night, fighting, dawn income)
- [ ] **MAP-03**: Each map adds at least one distinguishing element: a unique building, terrain gimmick, or unique mechanic
- [ ] **MAP-04**: Maps unlock sequentially when the previous map is won
- [ ] **MAP-05**: Difficulty rises from map to map, and each map is winnable with the loadout available at that point in the campaign

### Meta-Progression & Scoring

- [ ] **META-01**: Player picks one unlocked king weapon before each run; there are 5 weapons, each with a distinct passive attack and active ability
- [ ] **META-02**: Player picks up to their unlocked number of perk slots (maximum 5) from a pool of 30+ perks spanning economy, military, defense, towers, king, and utility
- [ ] **META-03**: Player can enable any of 10+ mutators before a run; each raises difficulty and grants a score/XP multiplier, and multiple mutators stack multiplicatively
- [ ] **META-04**: Run score is computed from survival, buildings protected, time bonus, unspent gold, mutator bonus, and the no-restart bonus, and the results screen shows the breakdown
- [ ] **META-05**: Each completed run awards XP based on its score toward a persistent player level
- [ ] **META-06**: Leveling up unlocks weapons, perks, perk slots, and heroes on a front-loaded curve that unlocks all v1 content within the campaign
- [ ] **META-07**: Map select shows each map's lock state and best score
- [ ] **META-08**: Stat bonuses from perks, mutators, upgrades, castle abilities, and research combine in a fixed, documented order that automated tests verify
- [ ] **META-09**: Campaign progress (level, XP, unlocks, best scores) and settings persist between sessions, and saves carry a schema version so older saves migrate after updates

### Input

- [ ] **INPT-01**: Player can play the game entirely on keyboard: move, sprint, action (hold to build or upgrade), active ability, unit commands, and start night
- [ ] **INPT-02**: Player can play the game entirely on a gamepad with equivalent bindings, switching between keyboard and gamepad at any time with on-screen prompts matching the active device
- [ ] **INPT-03**: Player can navigate every menu with mouse, keyboard, or gamepad

### Interface & Presentation

- [ ] **UI-01**: The in-run HUD shows gold, current night out of total, the king's health, the ability cooldown, and unit group status, without cluttering the view
- [ ] **UI-02**: Upgrade choice cards show an icon, name, and short description for each option
- [ ] **UI-03**: The game has a main menu, map select, pre-run loadout screen (weapon, perks, mutators, with a live score-multiplier preview), pause menu, and results screen (score breakdown, XP gained, new unlocks)
- [ ] **UI-04**: The settings menu offers key/button rebinding, display options (resolution, window mode, vsync), master and SFX volume, and graphics quality presets
- [ ] **UI-05**: Buildings, units, and enemies stay distinguishable at night through silhouettes and a consistent color language, with distinct day and night lighting moods
- [ ] **UI-06**: Building, upgrading, hits, destruction, and gold payouts have clear visual feedback
- [ ] **UI-07**: A credits screen lists all third-party assets and their licenses

### Art & Audio

- [ ] **ART-01**: The game has a cohesive low-poly look built from CC0 asset packs normalized to consistent scale, palette, and shading
- [ ] **ART-02**: Every third-party asset is recorded in a license/attribution log in the repository
- [ ] **AUD-01**: SFX play for king and unit attacks, hits, deaths, building and upgrading, gold payout, UI interactions, night start, and dawn
- [ ] **AUD-02**: SFX use CC0 sources and are mixed so that large battles stay readable

### Platform & Release

- [ ] **PLAT-01**: The game holds 60 fps on GTX 970-class hardware during the largest battles (hundreds of units and projectiles on screen)
- [ ] **PLAT-02**: A Windows build exports from the command line and runs on a clean Windows machine without extra installs
- [ ] **PLAT-03**: The game is published on itch.io with a store page that avoids Thronefall branding and explains the Windows SmartScreen warning

### Development & Verification

- [ ] **DEV-01**: Game simulation (economy, waves, combat, stats, scoring) runs headlessly, and automated GUT tests cover it from the command line
- [ ] **DEV-02**: CI runs lint and the test suite on every push, and can produce a Windows export
- [ ] **DEV-03**: A toggleable debug overlay shows FPS, unit/enemy counts, wave state, and pathing information
- [ ] **DEV-04**: Automated screenshot capture of scripted scenes allows visual verification without a human watching
- [ ] **DEV-05**: Seeded, deterministic simulation allows scripted playthrough tests of full nights and maps

## v2 Requirements

Deferred to a future release. Tracked but not in the current roadmap.

### Content & Presentation

- **V2-01**: Music soundtrack with day/night themes
- **V2-02**: Additional maps beyond 5, toward Thronefall's campaign length
- **V2-03**: Additional weapons, perks, mutators, and unit/hero options beyond the v1 counts
- **V2-04**: Localization beyond English

### Platform

- **V2-05**: Linux and macOS builds
- **V2-06**: Steam release with achievements, cloud saves, and leaderboards

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Click-to-build / remote building | Dropped for Thronefall's ride-up-and-hold building, which keeps travel time as a cost and the camera on the king |
| Mouse unit commands, mouse-aimed king attacks | Mouse is for menus only; faithful to Thronefall's controls |
| Free building placement | Fixed build spots are Thronefall's core, dev-validated design lever |
| Multiple currencies | Single-gold minimalism keeps the economy legible |
| Per-kill gold bounties | Income comes from buildings surviving the night; bounties would change the game's identity |
| Permadeath / no-retry runs | Thronefall allows retry with a soft score penalty |
| Procedural maps or waves | Hand-authored maps and waves drive telegraphing and difficulty tuning |
| Multiplayer / co-op | Thronefall is single-player; large complexity for no project need |
| Thronefall names, art, maps, or UI | IP; recreate mechanics with original content |
| Custom-modeled art | CC0 packs cover v1 |
| Web, mobile, and console builds | Windows itch.io build only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| (filled by roadmapper) | | |

**Coverage:**
- v1 requirements: 85 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 85 ⚠️

---
*Requirements defined: 2026-09-28*
*Last updated: 2026-09-28 after initial definition*
