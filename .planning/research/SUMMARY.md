# Project Research Summary

**Project:** Duskhold (codename) — faithful recreation of Thronefall's gameplay
**Domain:** Minimalist low-poly 3D day/night tower-defense / light city-builder / action strategy (Windows PC)
**Researched:** 2026-09-28
**Confidence:** MEDIUM-HIGH

## Executive Summary

Duskhold is a faithful Windows PC recreation of Thronefall's core gameplay loop: alternating day (build/economy) and night (defense/combat) phases on handcrafted maps, with a mounted king who fights directly alongside troops. The game succeeds or fails on a narrow but achievable band of economic tension — gold is always scarce enough to force real trade-offs between economy/defense/military spending, but not so tight that a single mistake is unrecoverable.

**Recommended approach:** Build the core loop (single map, zero meta-progression) to a playable, human-tested state first, validating that the loop is genuinely fun before layering weapons/perks/mutators/maps on top. The single highest architectural requirement is a clean simulation/presentation split: the game logic must run headlessly (no rendering dependency) so an AI coding agent can verify correctness via automated tests rather than visual inspection. **Godot 4.7.2-stable (GDScript, GUT 9.7.1)** is the decisive engine choice: its plain-text `.tscn`/`.tres` format, first-class `--headless` CLI support, and documented strong LLM compatibility directly enable AI-driven development while remaining fully capable for GTX 970-class hardware targeting hundreds of simultaneous units.

**Key risks and mitigations:**
1. **Loop balance collapse** (trivial or punishing) — data-driven economic numbers, explicit scarcity targets (<20% gold surplus at night start), human playtest gate at core-loop completion.
2. **Click-to-build feels disconnected** — reintroduce a build-range cost from the king's position, king-centric camera, validated at playtest.
3. **AI-agent blindness to feel regressions** — debug overlay + automated screenshot tooling from day one, mandatory human-playtest checkpoints per phase.
4. **Night readability collapse** — silhouette-based design discipline, automated screenshot review, capped VFX.
5. **Stat modifier stacking bugs** — unified aggregation system designed before the first perk is added.

## Key Findings

### Recommended Stack

**Godot 4.7.2-stable** with **GDScript** (standard, non-.NET build) wins decisively on three fronts (full comparison vs Unity 6, Unreal 5, Bevy, and a web stack in STACK.md):

1. **Text-based, agent-editable formats end-to-end** — `.tscn` scenes, `.tres` resources, `.gd` scripts and `project.godot` are plain text and safely hand-editable by an AI agent. Unity's YAML is GUID-riddled and fragile; Unreal's `.uasset` files are binary.
2. **Headless CLI is a first-class workflow** — `godot --headless` runs the game, executes tests (GUT), and exports release builds with no editor GUI.
3. **2026 LLM evidence** — current reports favor Claude's GDScript output quality and cite Godot's text-first architecture as the easiest for AI agents.

**Core technologies:**
- Godot 4.7.2-stable (MIT, zero cost): engine — text formats, headless CLI, Windows export
- GDScript: primary language — zero build step, best agent fit; move only a proven hot system to C#/GDExtension if profiling demands
- GUT 9.7.1: headless-runnable unit/integration tests (9.7.0 added Godot 4.7 compatibility)
- gdtoolkit 4.5.0: `gdformat`/`gdlint` gate for consistent, statically typed agent-written code
- MultiMeshInstance3D + NavigationServer3D (built-in): GPU-instanced rendering of hundreds of units; navmesh + selective avoidance, flow fields if profiling demands
- Git LFS, `.gitattributes` (LF for text formats), GitHub Actions headless test/export, itch.io `butler`

### Expected Features

**Must have (table stakes):**
- Day/night cycle with player-triggered night start; night ends when all enemies are dead; telegraphed spawn points with per-point enemy counts; dawn auto-rebuild (rebuilt buildings earn no income that morning)
- Castle center destroyed = loss; surviving the final night = win
- King: mounted, one equipped weapon with passive auto-attack + active ability on cooldown; knocked out and respawns (not a game over)
- Single gold currency; fixed pre-placed build spots; escalating per-tier costs
- Branching "choose 1-of-N" upgrades — one shared system across Castle Center, towers, barracks, archery range, hero quarters
- Military buildings produce squads; autonomous combat + hold/rally commands
- Enemy roster (melee/ranged/fast/flying/tanky/siege) that counters single-strategy defenses
- 3–5 handcrafted maps; per-map scoring with soft retry penalty (lose the 1.1× no-restart bonus)
- Meta-progression: per-map XP/levels, 2–3 weapons, 12+ perks (limited loadout), 4–6 mutators

**Should have (v1 differentiators):**
- Varied income curves (flat House, declining Mine, ramping Harbor, threshold Shrine) — makes the economy a puzzle, not a spreadsheet
- Per-map unique enemies/buildings; a boss night on at least one map
- Weapon playstyle variety (ranged, melee, crowd control)
- Build-placement feedback/juice

**Defer (v1.x / v2+):**
- Research buildings (Blacksmith / Royal Forge) — **safest scope cut; nothing else depends on them**
- Expanded weapon/perk/mutator rosters toward full-game counts
- Music (SFX-only in v1)

**Scoring formula (portable from Thronefall):** (Base score [survival + building preservation + time bonus, capped ~600] + Gold×10 + mutator bonus) × no-restart bonus (1.1×). Stabilize and playtest the formula before tuning mutator multipliers on top of it.

### Architecture Approach

The load-bearing decision is a hard **simulation / presentation / data** split. Simulation (run state machine, economy, buildings, combat, health, stats, scoring, meta) has zero dependency on rendering nodes, so it can be instantiated and ticked in headless GUT tests; presentation only reacts to EventBus signals and reads state; all content lives in read-only `.tres` Resource definitions. Player input becomes plain-data intents (BuildIntent, RallyIntent, SelectUnitsIntent) so tests can drive the game without a mouse, camera, or viewport.

**Major components:**
1. RunManager / FSM — explicit Boot→Menu→Loadout→Run→Results, nested Day↔Night↔Dawn; gated transitions
2. Economy — gold ledger, dawn income from surviving buildings, varied income curves
3. BuildSpot / BuildingSystem — fixed spots, shared branching-upgrade pattern, destruction and dawn restoration
4. King + Weapon — WASD movement, passive auto-attack, active ability on cooldown, knockout/respawn
5. UnitManager / EnemyManager — data-oriented pools (not one physics node per unit), MultiMesh rendering, flow-field or throttled pathfinding, spatial hashing
6. CombatResolver — unified damage/projectile resolution with commitment-window targeting (no retarget thrash)
7. StatModifier system — `(base + Σflat) × (1 + Σpercent) × Πmultiplicative`, fixed order, designed before the first perk
8. Spawner / WaveDefs — hand-authored waves per night per map, spawn telegraphing
9. Scoring + Meta-progression + SaveGame — schema-version field from the first save, forward-only migrations
10. EventBus — one-to-many notifications (gold_changed, building_destroyed, night_started…) for UI, SFX, scoring; direct calls on hot paths
11. UI/HUD + SFX layers — pure consumers of events/state

### Critical Pitfalls

1. **Loop trivial or punishing** — the narrow gold-scarcity band is Thronefall's design secret. Data-drive all numbers, set explicit tuning targets, and require a human playtest pass before meta-progression.
2. **Click-to-build erodes king presence** — remote clicking removes the embodied "ride to the spot" cost axis. Limit build range to a radius around the king, keep the camera king-centric, consider restricting building at night; validate at playtest.
3. **Night readability collapse** — visual soup under hundreds of units and dark lighting. Art/lighting rules (silhouettes, color-coded threat tiers, capped VFX) plus automated screenshot review.
4. **Unit jamming at chokepoints / target thrash** — naive per-agent navmesh at walls/gates causes gridlock. Staggered path requests, flow fields for dense same-goal groups, commitment-window targeting, headless stress tests (200+ units through one gate).
5. **Stat-modifier stacking and save-corruption bugs** — silent wrong numbers and broken saves compound over phases. Fixed aggregation order with unit tests per perk and combined cases; schema-versioned saves with fixture regression tests.

Also: agent blindness (build debug overlays, deterministic seeds, screenshot capture early); CC0 pack style/scale mismatch (normalize scale/palette/shading as an explicit setup step, keep an attribution/license log); IP (no "Thronefall" in the name or store page, original maps/UI); Windows SmartScreen/AV false positives on unsigned Godot exports (clean-VM testing, store-page messaging); scope creep (full meta in v1 before the core loop is proven).

## Implications for Roadmap

Suggested phase structure (the roadmapper should adapt it to the project's "fine" granularity setting — 8–12 phases):

### Phase 1: Core Loop Slice (Vertical Slice) — GATE: human playtest
**Rationale:** Validates the single-map, zero-meta loop is fun before anything else is built; also proves the whole agent workflow (headless run/test/export).
**Delivers:** Godot 4.7.2 project scaffolding (GUT, gdtoolkit, LFS, .gitattributes, CI), state machine, one simple map, basic economy + a few buildings, king with placeholder weapon, one enemy type + spawn scheduler, win/lose, debug overlay + automated screenshot tooling.
**Addresses:** LOOP table stakes, core ECON/BLDG.
**Avoids:** Pitfalls 1, 2, 8, 9, 10 (loop balance, click-to-build feel, agent blindness, scope creep).

### Phase 2: King Combat & Unit Production
**Rationale:** Combat is the second-most-essential system and unlocks meaningful nights.
**Delivers:** Weapon system (passive + active), data-oriented UnitManager with MultiMesh rendering, barracks/archery range, mouse unit commands (select/rally/hold), CombatResolver, stat-system foundation.
**Uses:** MultiMeshInstance3D, NavigationServer3D (or flow field).
**Implements:** UnitManager, CombatResolver, StatModifier foundation.

### Phase 3: Economy & Buildings
**Rationale:** Economy variety creates loop tension; the shared branching-upgrade system unlocks building variety cheaply.
**Delivers:** Varied income curves, full economic/defensive building set, Castle Center upgrades, pick-1-of-N upgrade system and UI, BuildingDef resources.

### Phase 4: Enemy Variety & Wave System
**Rationale:** Enemy and building variety are mutually dependent (an anti-air tower branch is meaningless without flyers).
**Delivers:** Enemy roster (melee/ranged/flying/siege/tank/fast), EnemyDef/WaveDef data, spawn telegraphing UI, readability validation via screenshots, chokepoint stress tests.

### Phase 5: Meta-Progression — GATE: human playtest
**Rationale:** Systems layered on a validated foundation; scoring must stabilize before mutator tuning.
**Delivers:** 2–3 weapons, 12+ perks with loadout, 4–6 mutators, scoring formula, per-map XP/levels, versioned SaveGame, loadout and results screens.

### Phase 6: Map Content & Difficulty Tuning
**Rationale:** Content authoring leverages proven systems; map/wave authoring is real content work and needs its own allocation.
**Delivers:** 3–5 handcrafted maps (tutorial → capstone) with per-map waves, unique enemies/buildings, boss night; tuning via simulated playthroughs + human playtests.

### Phase 7: Polish & Distribution
**Rationale:** Presentation and release after systems/content are validated.
**Delivers:** Minimal HUD, menus/settings, SFX, juice (hit feedback, camera smoothing), Windows export tested on a clean VM, itch.io butler pipeline and store page with SmartScreen guidance, final IP copy review.

### Phase Ordering Rationale

- The core loop is proven before any meta work (the biggest scope-creep and feel risk).
- Data-oriented unit scale-up (MultiMesh + flow fields/throttled pathing) lands right after the vertical slice and **before** content breadth, so dozens of unit/enemy types aren't rebuilt for a later performance refactor.
- The stat-modifier system and save versioning are designed before the first perk / first save, not retrofitted.
- Enemy variety and building variety ship together; research buildings are the first thing cut if a phase overruns.
- UI/SFX can progress in parallel once the EventBus contract is stable.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** unit scale on target hardware — validate MultiMesh + navigation/avoidance empirically; Godot's avoidance behavior has changed across 4.x releases, so re-verify against 4.7.
- **Phase 4:** night readability and enemy-count scaling at chokepoints.
- **Phase 5:** perk/mutator balance feel (tests validate math; humans validate feel).
- **Phase 6:** content pipeline efficiency and per-map balance across loadout variants.
- **Phase 7:** SmartScreen/AV behavior of the actual export.

Phases with standard patterns (research optional):
- **Phase 1 scaffolding** (Godot project setup, GUT, CI) — well documented.
- **Phase 3** (economy/building data model) — standard data-driven patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Godot 4.7.2-stable verified against the official release blog; GUT 9.7.1 and gdtoolkit 4.5.0 verified against their release pages; headless CLI confirmed in official docs |
| Features | MEDIUM-HIGH | Mechanic structures cross-corroborated (Wikipedia, Steam, community wiki, guides, dev interview); exact numbers mostly from a community wiki; king respawn timer/location unconfirmed |
| Architecture | MEDIUM-HIGH | Industry-standard patterns; Godot specifics checked against docs; the ~50-node CharacterBody3D ceiling is a community figure to validate empirically |
| Pitfalls | MEDIUM-HIGH | Engine-agnostic RTS/TD and Windows distribution pitfalls HIGH; Thronefall-specific design claims MEDIUM; AI-agent workflow pitfalls LOW-MEDIUM (emerging practice) |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Core-loop feel with click-to-build:** only a Phase 1 playtest can confirm it; be ready to adjust build range/camera rules.
- **Unit scale threshold:** Phase 2 stress tests decide whether flow fields are needed.
- **Difficulty tuning:** simulated playthroughs catch gross imbalance; humans validate feel (Phase 1, 5, 6 gates).
- **King respawn rules:** not documented in sources — a design decision, not a research question.
- **gdUnit4 Godot 4.7 support:** unconfirmed; GUT is primary, so non-blocking.
- **CI action tags** (setup-godot, godot-ci, godot-export): verify latest tags when CI is implemented.
- **SmartScreen specifics:** only known after Phase 7 clean-machine export testing.

## Sources

### Primary (HIGH confidence)
- https://godotengine.org/blog/release/ — Godot stable release history; 4.7.2 (2026-08-18) is latest stable
- https://github.com/bitwes/Gut/releases — GUT 9.7.x Godot 4.7 compatibility
- https://pypi.org/project/gdtoolkit/ — gdtoolkit 4.5.0 latest
- Godot docs (docs.godotengine.org) — headless/command-line export, MultiMesh optimization, NavigationAgents/avoidance, Resources
- https://store.steampowered.com/app/2239150/Thronefall/ and https://en.wikipedia.org/wiki/Thronefall — game description, features, development history, sales
- https://itch.io/docs/butler/ — pushing Windows build folders

### Secondary (MEDIUM confidence)
- Thronefall community wiki, Steam community guides, TheGamer, Digitsguide, Kotaku and review coverage — mechanics, numbers, perks/mutators, scoring formula
- Red Blob Games (flow fields) and RTS practitioner write-ups — crowd pathfinding patterns
- Godot GitHub issues/proposals — avoidance performance, SmartScreen false positives on exported executables
- 2026 blog coverage on GDScript vs C# and Claude's Godot 4 code quality

### Tertiary (LOW confidence)
- AI-agent-driven game development workflow reports — sparse literature; mitigations partly reasoned from first principles
- Exact Thronefall hotkeys, king respawn timer, late-content weapons — incomplete in sources

Detailed findings and full citations: [STACK.md](STACK.md), [FEATURES.md](FEATURES.md), [ARCHITECTURE.md](ARCHITECTURE.md), [PITFALLS.md](PITFALLS.md).

---
*Research completed: 2026-09-28*
*Ready for roadmap: yes*
