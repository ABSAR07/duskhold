# Roadmap: Duskhold

## Overview

Duskhold goes from an empty Godot 4.7.2 project to a released 5-map Windows campaign. The first two phases prove the day/night build-then-defend loop on one prototype map with no meta-progression. Phase 1 sets up the project and the agent-verification tooling (headless tests, lint, CI with a Windows export, screenshots, debug overlay, asset log) alongside a playable day phase: riding the king, building, upgrading, and earning gold. Phase 2 adds nights, dawn, win/loss, and seeded replays, and it ends in a human playtest gate. Next, the king and his troops fight together, and the unit/enemy simulation is scaled to Thronefall-size battles before content breadth is added. Day-phase depth comes next (castle center, branching upgrades, income curves), then enemy variety and tower specializations as counter pairs, then army variety. After that the game gets its cohesive art and sound. Then it becomes a campaign: scoring, retry, and versioned saves on maps 1–2, followed by the meta-progression loadout (second playtest gate) and the maps 3–5 finale with boss nights. Research buildings are isolated as the designated scope cut, and the project closes with settings, menus, and the itch.io release.

**Controls (changed 2026-09-28):** every phase uses Thronefall's original scheme. The king moves with WASD / left stick; building and upgrading happen by riding to a build spot and holding the action key; units take hotkey commands (hold; follow the king); gameplay works on keyboard and gamepad. **The mouse is used only in menus.** The earlier keyboard + mouse plan (click-to-build, mouse unit commands) was dropped and must not reappear in phase plans.

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

- [ ] **Phase 1: Foundation & Day Loop** - Godot project with headless test/lint/CI/screenshot/debug tooling, plus a playable day of riding, building, upgrading, and earning gold on the prototype map
- [ ] **Phase 2: Night Defense & Playtest Gate** - Telegraphed nights, combat, king knockout, dawn rebuild and income, win/loss, and seeded replays; ends in a human playtest gate
- [ ] **Phase 3: King Combat & Troops** - Barracks and Archery Range squads with hold/follow hotkeys, king active ability, full HUD, keyboard + gamepad
- [ ] **Phase 4: Crowd-Scale Battles & Walls** - Walls and barricades, jam-free pathing, and hundreds of units/enemies/projectiles at 60 fps
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

**Plans**: 9/10 plans executed
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
- [ ] 01-10: Visible dawn payout, six scripted screenshots (local and CI), final push with green CI

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

**Plans**: TBD
**UI hint**: yes

### Phase 3: King Combat & Troops

**Goal**: The king leads an army. The player builds a Barracks and an Archery Range whose squads fight on their own, commands them with hotkeys, and fires the weapon's active ability. All of it is fully playable on keyboard or gamepad with a complete in-run HUD.
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: KING-04, KING-05, UNIT-04, UNIT-05, UNIT-06, UNIT-07, INPT-01, INPT-02, UI-01
**Success Criteria** (what must be TRUE):
  1. The player can build a Barracks (default melee squad) and an Archery Range (default ranged squad). Their units stay near their post and fight nearby enemies on their own, committing to targets instead of constantly switching. Units killed at night trickle back from their building, and every unit is fully restored at dawn.
  2. The player can press a hotkey to make units hold their current position, or to follow the king (all units or only one unit type).
  3. The player can trigger the king's weapon active ability and see its cooldown on the HUD. The king's health regenerates after a short time without taking damage.
  4. Every in-run action (move, sprint, hold-to-build/upgrade, active ability, unit commands, start night) works on keyboard and on gamepad. The player can switch devices at any moment, and on-screen prompts update to match the active device.
  5. The HUD shows gold, current night out of total, king health, ability cooldown, and unit group status without cluttering the play area.

**Plans**: TBD
**UI hint**: yes

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

**Plans**: TBD

### Phase 5: Castle Center & Economy Depth

**Goal**: Day decisions gain real depth. The castle center grows through tiers with run-defining ability picks that gate higher building tiers, and four new economic buildings each pay out on a different income curve. All bonuses stack in one tested order.
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08, UI-02
**Success Criteria** (what must be TRUE):
  1. At a branching upgrade tier, the player picks one of the offered choice cards (icon, name, short description) with keyboard or gamepad. The choice stays locked for the rest of the run.
  2. The player can upgrade the castle center through its tiers for more health, choosing one of four run-wide abilities or passives at each tier. Higher building tiers stay locked until the castle reaches the required tier.
  3. The player can build four new economic buildings:
     - a Gold Mine, whose high income drops each night
     - a Mill, which opens nearby Field spots that each pay a flat income
     - a Fishing Harbor, which gains a paying boat each night up to an upgradeable cap
     - a Shrine, which activates after enough nearby enemy deaths, then attacks, pays, and strengthens other active Shrines
  4. Bonuses from building upgrades and castle abilities combine in one fixed, documented order. Automated tests verify single-modifier and combined-modifier cases.

**Plans**: TBD
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
  1. The settings menu offers key/button rebinding, resolution, window mode, vsync, master and SFX volume, and graphics quality presets. Changes persist between sessions.
  2. Every menu can be navigated with mouse, keyboard, or gamepad, with the focused element always visible.
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
| 1. Foundation & Day Loop | 9/10 | In Progress|  |
| 2. Night Defense & Playtest Gate | 0/TBD | Not started | - |
| 3. King Combat & Troops | 0/TBD | Not started | - |
| 4. Crowd-Scale Battles & Walls | 0/TBD | Not started | - |
| 5. Castle Center & Economy Depth | 0/TBD | Not started | - |
| 6. Enemy Roster & Tower Specializations | 0/TBD | Not started | - |
| 7. Army Variety & Heroes | 0/TBD | Not started | - |
| 8. Art, Readability & Sound | 0/TBD | Not started | - |
| 9. Campaign Opening & Scoring | 0/TBD | Not started | - |
| 10. Loadout & Meta-Progression | 0/TBD | Not started | - |
| 11. Campaign Finale & Boss Nights | 0/TBD | Not started | - |
| 12. Research Buildings | 0/TBD | Not started | - |
| 13. Settings & Release | 0/TBD | Not started | - |
