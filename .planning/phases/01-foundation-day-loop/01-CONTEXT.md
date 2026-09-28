# Phase 1: Foundation & Day Loop - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 delivers a Godot 4.7.2 project with a small, permanent prototype map. During the day, the player rides the mounted king (KING-01/02) and holds the action key at fixed build spots to build or upgrade Houses and a basic tower (BLDG-01..04, BLDG-06), spending gold as the only currency (ECON-01). Houses pay tier-based income at dawn (ECON-02), and unspent gold carries over (ECON-07). The day ends through the real hold-to-confirm "start night" input and a placeholder night with no enemies, followed by dawn.

From the first commit, lint, headless GUT tests, scripted screenshot capture and a Windows export run from the command line and in GitHub Actions on every push (DEV-01, DEV-02, DEV-04). A toggleable debug overlay (DEV-03) and a license/attribution log (ART-02) exist.

**Not in this phase:**
- enemies, combat, building health/destruction, king HP/respawn, spawn telegraphing, win/loss, results screen, seeded replays (all Phase 2)
- branching upgrade cards (Phase 5)
- other economic buildings (Phase 5)
- the art cohesion pass and SFX (Phase 8)
- the rebinding UI (Phase 13)

</domain>

<decisions>
## Implementation Decisions

### Carried Forward (locked before this discussion — do not re-litigate)
- **Stack:**
  - Godot 4.7.2-stable, standard (non-.NET) build
  - GDScript with static typing everywhere
  - GUT 9.7.1 for tests
  - gdtoolkit 4.5.0 (`gdformat`/`gdlint`)
  - GitHub Actions for CI
- **Controls (Thronefall's original scheme):**
  - Keyboard + gamepad for all gameplay; the mouse is used only in menus.
  - WASD / left stick moves the king, with a sprint modifier.
  - Build or upgrade by riding up to a spot and holding the action key. There is no click-to-build and no remote building.
  - Every gameplay action lives in the Input Map with both keyboard and gamepad bindings.
- **Architecture** (per `.planning/research/ARCHITECTURE.md`):
  - A hard split between simulation, presentation and data, so the economy, building rules and loop transitions run in headless tests without a scene tree.
  - Content definitions are `.tres` Resources, referenced by id.
  - An explicit top-level state machine with day/night sub-states.
  - An event bus for cross-cutting notifications.
  - A command/intent layer (e.g. `BuildIntent`, `StartNightIntent`) sits between input and the simulation.
- **Economy basics:**
  - Gold is the only currency.
  - Build spots are fixed.
  - There is no day timer.
  - Enemies drop no gold; income comes only from buildings at dawn.
- **Assets:** CC0 (or equally permissive) only. Every third-party asset is logged. No Thronefall names or assets.

### Prototype Map & Look
- **D-01:** Phase 1 uses **grey placeholder shapes plus a small set of CC0 models**:
  - The mounted king, the House, the basic tower and the castle center use real CC0 models; everything else (ground, spot markers, props) uses primitives.
  - Each CC0 model is recorded in the attribution log (ART-02).
  - Only rough scale matching is needed now. The full cohesion/normalization pass is Phase 8 (ART-01).
- **D-02:** **Each build spot has exactly one building type, fixed in the map data** (a House plot or a tower plot), as in Thronefall. The action key only builds or upgrades whatever that spot allows. There is no building picker.
  - **Reversibility:** costly. The spot data schema, the interaction flow, the world label and every later map assume one type per spot. Switching to a picker would need new UI and input states, and a data migration for every map.
- **D-03:** The **prototype map is small**:
  - The castle center plus about 8 build spots: about 5 House plots and about 3 tower plots.
  - Riding from edge to edge takes about 20–30 s at normal speed.
  - In Phase 1 the castle center is only a landmark and the king's start point. It has no health, loss logic or upgrades yet (those come in Phase 2 and Phase 5).
- **D-04:** The **prototype map is a permanent test/sandbox map.**
  - Unit/integration tests, scripted screenshot scenes and (from Phase 2) seeded replays run against it.
  - It never ships as a campaign level. Campaign maps are designed fresh in Phase 9, so changing campaign content never breaks tests.

### Hold-to-Build Interaction
- **D-05:** **Coins drip in one by one.**
  - While the action key is held near an affordable spot, coins fly from the king into the spot at a steady rate (1 coin = 1 gold), so pricier builds take a little longer.
  - The build or upgrade completes when the last coin lands.
  - Costs use Thronefall-scale small integers (single digits early), so holds stay short.
- **D-06:** **Refund and reset on early release.**
  - Starting the hold requires the full cost.
  - Letting go early, or leaving the interaction range, refunds every coin already dripped and resets the spot.
  - No partially-paid state is ever stored on a spot. As far as the economy is concerned, a build or upgrade is all-or-nothing.
- **D-07:** **Spot info floats above the spot in world space**, not in a HUD panel.
  - It shows the building name/tier, the cost as coin icons that fill while paying, and a one-line effect (e.g. "House II: +2 gold at dawn").
  - It appears only for the nearest in-range spot, only during the day.
- **D-08:** **Unaffordable spots:**
  - The cost is always shown in red when the player can't afford it.
  - Holding the action key there plays a short shake and a "denied" cue, and no coins move.
  - The sound is a hook: wire a placeholder CC0 sound (logged) or leave it silent until the Phase 8 SFX pass.

### Economy & Day End
- **D-09:** **The starting economy is tight.** Starting gold covers about 2 Houses **or** 1 tower, so the first minute already forces a trade-off.
  - All numbers (starting gold, costs, income per tier, tower stats, drip rate) live in `.tres` data and get tuned at the Phase 2 playtest gate.
- **D-10:** **Upgrade tiers are linear only in Phase 1:**
  - The House has **3 tiers** (build + 2 upgrades), and its income rises each tier. This is a deliberate deviation from Thronefall's 2-tier House, to create more "upgrade vs build new" decisions.
  - The basic tower has **2 tiers** (build + 1 upgrade). It does nothing in Phase 1 because there are no enemies, but its label still shows the tier's stats as the effect (e.g. range/damage).
  - Pick-one-of-several upgrade cards (BLDG-05) are Phase 5.
- **D-11:** **The real hold-to-confirm "start night" input is built now:**
  - It is a dedicated action, separate from the build/action key, bound on both keyboard and gamepad.
  - It works anywhere during the day and shows a filling on-screen prompt, so it can't be triggered by accident.
  - Phase 2 reuses it unchanged (LOOP-01) and only adds enemies behind it.
- **D-12:** **Placeholder night, then a visible dawn payout:**
  - The lighting shifts to a night mood for a few seconds under a "Night N — no enemies yet" banner.
  - At dawn, coins pop out of each House and fly to the HUD gold counter, then a "+X gold" total appears.
  - This establishes the loop state machine (Day → Night → Dawn → Day) and the day/night lighting states that Phase 2 fills in rather than replaces.
  - The Phase 1 loop has no final night and no win/loss; days repeat until the player quits.

### Repo, CI & Godot Setup
- **D-13:** **A public GitHub repository under the user's account (`ABSAR07`)**, added as `origin`. CI runs on every push.
  - Creating the repo and the first push are outward-facing actions. The executor must get explicit user confirmation, including the repo name, at execution time before running `gh repo create` or pushing.
  - **Reversibility:** one-way. Once history is pushed publicly it can be cloned, forked or cached, and switching to private later does not un-publish it. Nothing secret may ever be committed.
- **D-14:** **A setup script fetches a pinned Godot:**
  - It downloads the official Godot 4.7.2-stable (standard, win64) release.
  - It verifies the download against the official checksums.
  - It stores Godot in a git-ignored project folder (e.g. `.tools/godot/`).
  - Every local script (test, lint, screenshot, export) and CI uses exactly this version.
  - CI (a Linux runner) pins the same version.
  - The user is asked before the first download.
- **D-15:** **Windows export works both locally and in CI from the start.**
  - The setup script also downloads the matching 4.7.2 export templates (about 1 GB), so a local Windows `.exe` export works right away. Ask before downloading.
  - CI produces a Windows export on every push as a downloadable workflow artifact.
- **D-16:** **Git LFS from the first commit:**
  - `.gitattributes` routes binary asset types (e.g. `*.glb`, `*.fbx`, `*.png`, `*.wav`, `*.ogg`) to LFS and forces LF line endings for text files (`.gd`, `.tscn`, `.tres`, `.cfg`, `.godot`).
  - CI checkouts enable LFS.
  - GitHub's free LFS quota is limited: keep assets lean and cache LFS objects in CI where practical.
  - `.godot/` is git-ignored entirely.

### Claude's Discretion
- **Camera:** angle, perspective vs orthographic, FOV/size, and follow smoothing. It must be a fixed isometric-style angle that follows the king (KING-02). The player can't rotate it.
- **King movement:** walk and sprint speeds. For reference, Thronefall's walk-to-sprint ratio is about 1.6×, and sprint has no stamina. Turning feel and acceleration are also open.
- **Build interaction details:**
  - The interaction radius, and picking the nearest spot when several are in range.
  - Whether the king can keep moving while holding. Leaving range must cancel and refund, per D-06.
  - The coin drip rate: roughly 0.15–0.3 s per coin is the starting point.
  - Max-tier behavior: the label shows "Max tier" and holding does nothing.
- **Numbers:** exact starting gold, costs, House income per tier, tower stats and the payout animation timing, within D-09/D-10. Thronefall's reference values: House 2 gold, paying 1 then 2 gold/night; tower 3 → 5 → 15 (see FEATURES.md).
- **Default bindings:** default keys and buttons for move, sprint, action (hold), start night (hold) and the debug overlay toggle. There must be no conflict between the build hold and the start-night hold. The rebinding UI is Phase 13.
- **Debug overlay (DEV-03):** its contents and layout. It shows FPS, unit/enemy counts (zero for now) and the current loop state, and must be extensible for Phase 2's wave state and enemy paths.
- **Screenshot scenes (DEV-04):** which scripted scenes get captured. At minimum: a day overview, the label near a spot, a build in progress, the dawn payout, and the overlay on.
- **Attribution log:** format and location (e.g. a human-readable `ASSETS.md`/credits file, optionally a machine-readable manifest that the Phase 13 credits screen can reuse).
- **Which CC0 pack(s)** provide the four models. Prefer GLB sources (e.g. Kenney) and stay consistent enough to read clearly.
- **Tooling details:**
  - the project folder layout (follow ARCHITECTURE.md's recommended structure)
  - GUT test organization
  - the CI workflow structure and action choices (e.g. `chickensoft-games/setup-godot` or a pinned download step)
  - whether to add a local pre-commit lint hook in addition to CI
- **Simulation tick:** a fixed-step simulation tick and a seeded RNG service may be set up now, so Phase 2's determinism work (DEV-05) doesn't have to retrofit them. This is optional groundwork, not a Phase 1 deliverable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 1: Foundation & Day Loop": the goal and the 5 success criteria (the acceptance bar).
- `.planning/ROADMAP.md` §"Phase 2: Night Defense & Playtest Gate": what Phase 2 builds on top of Phase 1. The loop state machine, start-night input, overlay and prototype map must extend cleanly.
- `.planning/REQUIREMENTS.md`:
  - KING-01, KING-02, BLDG-01..04, BLDG-06, ECON-01, ECON-02, ECON-07, ART-02 and DEV-01..04 are the Phase 1 requirements.
  - The "Controls scheme (changed 2026-09-28)" note under `### Input`.
  - The Out of Scope table.
- `.planning/PROJECT.md`: Constraints, the "Controls change (2026-09-28)" paragraph, Key Decisions and Out of Scope.
- `.planning/STATE.md`, Blockers/Concerns:
  - The suggested split of Phase 1 into several plans.
  - The Phase 2 determinism note (fix seeded-RNG and fixed-step rules before combat code).

### Engine, tooling & CI
- `.planning/research/STACK.md` covers:
  - version pins and the version-compatibility table (Godot 4.7.2 ↔ GUT 9.7.1 ↔ gdtoolkit 4.5.0)
  - the headless GUT command line
  - GitHub Actions building blocks (setup-godot, godot-ci, godot-export)
  - `.gitignore`/`.gitattributes`/LFS guidance
  - the Input Map-as-text approach

### Architecture
- `.planning/research/ARCHITECTURE.md`:
  - §"Recommended Project Structure": the folder layout.
  - §"Pattern 1": the explicit top-level state machine with day/night sub-states.
  - §"Pattern 2": data-driven definitions as Resources.
  - §"Pattern 4": event/signal bus usage rules.
  - §"Pattern 7": the command/intent layer (keyboard/gamepad → intents).
  - §"Day-phase build flow" and §"Dawn transition flow": the flows D-05/D-06/D-12 plug into.
  - §"Testability & Debuggability Without a Screen": the headless test and screenshot strategy.
  - §"Suggested Build Order".
  - §"Anti-Patterns": especially 1 (coupling sim to scene nodes) and 4 (booleans instead of a state machine).

### Thronefall reference mechanics
- `.planning/research/FEATURES.md` §"The King", §"Economy", §"Buildings", §"UI/UX": walk/sprint ratio, House/tower costs and income, the fixed build-spot rule, the ride-up-and-hold prompt and the single-currency philosophy.

### Risks to design against
- `.planning/research/PITFALLS.md`:
  - Pitfall 1: trade-off tension, which motivates D-09's tight economy.
  - Pitfall 8: agent blindness, which motivates screenshots and the overlay.
  - Pitfall 9: editor-only workflows and opaque binaries.
  - Pitfall 11: CC0 asset inconsistency.
  - Pitfall 12: IP risk.
  - Pitfall 14: tuning without data.
  - §"Integration Gotchas".
- `.planning/research/SUMMARY.md`: the synthesized research overview and risk list.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None. This is a greenfield project. The repo holds only `.planning/` (the GSD planning docs) and `.claude/` (the local GSD install plus `.claude/CLAUDE.md`). There is no Godot project, script or asset yet.

### Established Patterns
- None in code yet. Phase 1 *establishes* the patterns every later phase follows:
  - the sim/presentation/data split
  - `.tres` definitions
  - the loop state machine
  - the intent layer
  - the event bus
  - GUT test layout
  - the lint config
  - the CI workflow
  - the attribution-log format
- Choose them deliberately, because later phases extend rather than replace them.

### Environment Facts (verified 2026-09-29)
- The local git repo is on branch `master` with **no remote**. GSD `branching_strategy` is `none`, so commits go straight to `master`.
- The GitHub CLI (`gh`) is installed and logged in as `ABSAR07`.
- **Godot is not installed** (not on PATH). D-14/D-15 cover getting it.
- Python 3.14 (`python`, `py`) is available for gdtoolkit (`pip install "gdtoolkit==4.*"`).
- Git LFS 3.5.1 is installed.
- The shell is Windows 11 with PowerShell 5.1 and Git Bash. Local scripts must run on Windows; CI runs on Linux.

### Integration Points
- Phase 2 will extend, and must not have to rewrite:
  - the loop state machine's Night sub-state (real waves)
  - building entities (health/destruction; the free rebuild at dawn, where rebuilt buildings pay nothing)
  - the start-night input (D-11)
  - the debug overlay (wave state, enemy paths)
  - the prototype map (spawn points, castle center health)
  - determinism (the seeded RNG and fixed-step tick)
- Later phases add more building types to the same one-type-per-spot data (D-02) and more tiers/branching to the same upgrade data (D-10).

</code_context>

<specifics>
## Specific Ideas

- The coin drip should look like Thronefall's: coins visibly travel from the king into the spot while the key is held, and the coin icons in the floating label fill as each coin lands.
- Example label text: "House II: +2 gold at dawn".
- The placeholder night banner reads "Night N — no enemies yet".
- At dawn, coins fly from each paying House to the HUD gold counter, followed by a "+X gold" total, so it's clear which House paid what.
- A "no" bump (shake + denied cue) when holding at an unaffordable spot, so it never reads as the key not working.

</specifics>

<deferred>
## Deferred Ideas

None. The discussion stayed within the phase scope.

</deferred>

---

*Phase: 01-foundation-day-loop*
*Context gathered: 2026-09-29*
