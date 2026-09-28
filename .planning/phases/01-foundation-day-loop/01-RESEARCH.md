# Phase 1: Foundation & Day Loop - Research

**Researched:** 2026-09-29
**Domain:** Godot 4.7.2 project scaffolding, headless CI/testing/export tooling, and a data-driven day-phase build/economy loop
**Confidence:** MEDIUM (stack/version facts largely CITED/VERIFIED against official sources; Godot-implementation-detail code patterns are mostly community-corroborated, tagged accordingly; game-feel numbers are explicitly Claude's-discretion per CONTEXT.md and stay ASSUMED until playtested)

## Summary

Phase 1 is two things bolted together on purpose: a from-scratch Godot 4.7.2 project that can be linted, tested, screenshotted, and exported entirely from the command line on every push, and a first vertical slice of the day-phase loop (king movement, fixed build spots, hold-to-build Houses/tower, dawn income, a placeholder night). Nothing here is exploratory — `.planning/research/STACK.md` and `.planning/research/ARCHITECTURE.md` already locked the stack and the architecture; this document fills the *implementation* gap between those macro decisions and an executable plan: exact CLI invocations, exact CI gotchas, exact file formats.

The single biggest risk this research surfaces that isn't yet documented elsewhere: **`--headless` and "produces a screenshot" are in tension.** Godot's `--headless` flag disables the rendering device outright (confirmed via multiple `godotengine/godot` GitHub issues) — it is correct and fast for GUT tests (which never touch a viewport), but a screenshot-capture script needs a *real* rendering driver (`--rendering-driver opengl3`) running under a virtual display (`Xvfb`), which is a different CLI invocation, a different (much slower) CI step, and on Ubuntu runners requires Mesa's software rasterizer (`llvmpipe`) since there's no GPU. Conflating these two modes — trying to screenshot under `--headless`, or running all GUT tests under Xvfb "just in case" — is the most likely early CI failure. A second, separate cross-compilation gotcha: exporting a Windows build *from a Linux CI runner* needs `rcedit` (via Wine) to embed the `.exe` icon/metadata unless the export preset's "Modify Resources" option is turned off — turning it off is the pragmatic Phase 1 choice (no custom icon exists yet anyway) and avoids installing Wine in CI entirely.

**Primary recommendation:** Scaffold the Godot project and its three CI jobs (lint, headless GUT tests, Windows export via `--headless` + templates) before writing any gameplay code, using `chickensoft-games/setup-godot@v2` with `use-dotnet: false` (standard build) for the lint/test job and either the same action with `include-templates: true` plus Wine-free export settings, or `lihop/setup-godot`'s auto-Xserver mode, for the screenshot job — then build the day loop in the dependency order ARCHITECTURE.md's "Suggested Build Order" already lays out (state machine skeleton → data layer → one trivial map + Economy → king controller → hold-to-build intent flow), gated by three explicit `checkpoint:human-verify` tasks (repo creation/push, Godot binary download, export template download) per CONTEXT.md D-13/D-14/D-15.

## Execution Checkpoints Required (Safety — do not skip in planning)

Per this phase's `01-CONTEXT.md` (D-13/D-14/D-15) and the safety constraints for this research run, the following actions are **outward-facing or download-heavy and must not run unattended**. The planner MUST insert a `checkpoint:human-verify` task immediately before each:

| Checkpoint | Action gated | Why |
|---|---|---|
| 1 | `gh repo create` and the first `git push` to a public GitHub repo under `ABSAR07` | D-13: one-way — once history is public it can be cloned/forked/cached; ask for the exact repo name first |
| 2 | Downloading the Godot 4.7.2-stable editor binary | D-14: ~large binary download; user must approve before the setup script fetches it, even though it will be checksum-verified |
| 3 | Downloading the 4.7.2 export templates (~1 GB) | D-15: explicitly called out as a large download the user must approve separately from the editor binary |

No other Phase 1 action (writing GDScript, `.tscn`/`.tres` files, CI YAML, running `godot --headless` locally once installed) needs a checkpoint — those are ordinary file edits/local runs within the existing GSD workflow.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KING-01 | Move the mounted king with WASD/left stick, sprint modifier | `CharacterBody3D` + `Input.get_vector` pattern (Code Examples); default bindings proposal (Architecture Patterns) |
| KING-02 | Camera follows king from a fixed isometric-style angle, no rotation | Orthogonal `Camera3D` rig pattern (Code Examples); confirmed as Claude's Discretion in CONTEXT.md |
| BLDG-01 | Fixed, pre-placed build spots; buildings only exist on those spots | `MapConfig`/`BuildSpot` data pattern from ARCHITECTURE.md Pattern 2, extended with `allowed_building_id` per D-02 |
| BLDG-02 | King near a spot sees what can be built and its cost | `Area3D` proximity + world-space floating label pattern (Code Examples, D-07) |
| BLDG-03 | Hold action key on empty affordable spot builds, with progress indicator | Hold-to-build intent flow (Architecture Patterns, D-05/D-06) |
| BLDG-04 | Hold action key on existing building upgrades, showing next tier cost/effect | Same intent flow, `BuildingInstance.tier` + `UpgradeTier` data (D-10) |
| BLDG-06 | Building/upgrading only possible during the day | `RunPhase` guard in `CommandProcessor` (ARCHITECTURE.md Pattern 1 + Pattern 7) |
| ECON-01 | Gold is the only currency, always on HUD | `Economy` simulation service (ARCHITECTURE.md `simulation/economy/`) |
| ECON-02 | House pays flat income each dawn, increasing with tier | Dawn transition flow (ARCHITECTURE.md, already documented) + `.tres` `HouseDef.income_per_tier` |
| ECON-07 | Unspent gold carries over day to day | `Economy.gold` persists across `RunPhase` transitions; no reset logic — verified by omission (no dawn/day-start code path zeroes gold in the documented flow) |
| ART-02 | Every third-party asset recorded in a license/attribution log | Kenney CC0 pack findings (Standard Stack); attribution log format proposal (Code Examples) |
| DEV-01 | Headless GUT tests cover economy/building/loop-transition simulation | GUT 9.7.1 CLI invocation (Standard Stack, Code Examples) |
| DEV-02 | CI runs lint + tests on every push, can produce a Windows export | GitHub Actions patterns (Architecture Patterns, Common Pitfalls) |
| DEV-03 | Toggleable debug overlay: FPS, unit/enemy counts, loop state | Overlay content/extensibility proposal (Architecture Patterns) |
| DEV-04 | Automated screenshot capture of scripted scenes | Xvfb + `--rendering-driver opengl3` pattern (Common Pitfalls #1, Code Examples) |
</phase_requirements>

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried forward (do not re-litigate):**
- Godot 4.7.2-stable, standard (non-.NET) build; GDScript with static typing everywhere; GUT 9.7.1; gdtoolkit 4.5.0 (`gdformat`/`gdlint`); GitHub Actions for CI.
- Controls: keyboard + gamepad for all gameplay, mouse only in menus; WASD/left stick moves the king with a sprint modifier; build/upgrade only by riding up and holding the action key (no click-to-build, no remote building); every gameplay action lives in the Input Map with both keyboard and gamepad bindings.
- Architecture (per `.planning/research/ARCHITECTURE.md`): hard split between simulation, presentation, and data so economy/building rules/loop transitions run in headless tests without a scene tree; content definitions are `.tres` Resources referenced by id; explicit top-level state machine with day/night sub-states; an event bus for cross-cutting notifications; a command/intent layer (`BuildIntent`, `StartNightIntent`) between input and simulation.
- Economy basics: gold is the only currency; build spots are fixed; there is no day timer; enemies drop no gold — income comes only from buildings at dawn.
- Assets: CC0 (or equally permissive) only; every third-party asset is logged; no Thronefall names or assets.

**D-01 — Prototype look:** grey placeholder shapes plus a small set of CC0 models. The mounted king, House, basic tower, and castle center use real CC0 models; everything else (ground, spot markers, props) uses primitives. Each CC0 model recorded in the attribution log. Only rough scale matching needed now.

**D-02 — One building type per spot:** each build spot has exactly one building type fixed in map data (House plot or tower plot), as in Thronefall. The action key only builds/upgrades whatever that spot allows. No building picker. Reversibility: costly (spot schema, interaction flow, world label, every later map assume one type per spot).

**D-03 — Small prototype map:** castle center plus ~8 build spots (~5 House plots, ~3 tower plots). Edge-to-edge ride time ~20–30s at normal speed. Castle center is landmark/start point only in Phase 1 — no health/loss logic/upgrades yet.

**D-04 — Permanent test/sandbox map:** unit/integration tests, scripted screenshot scenes, and (from Phase 2) seeded replays run against it. Never ships as a campaign level. Campaign maps designed fresh in Phase 9.

**D-05 — Coins drip in one by one:** while the action key is held near an affordable spot, coins fly from the king into the spot at a steady rate (1 coin = 1 gold); pricier builds take longer. Build/upgrade completes when the last coin lands. Costs use Thronefall-scale small integers (single digits early) so holds stay short.

**D-06 — Refund and reset on early release:** starting the hold requires the full cost. Letting go early, or leaving interaction range, refunds every dripped coin and resets the spot. No partially-paid state ever stored. Build/upgrade is all-or-nothing.

**D-07 — Spot info floats above the spot in world space,** not a HUD panel. Shows building name/tier, cost as coin icons that fill while paying, and a one-line effect (e.g. "House II: +2 gold at dawn"). Appears only for the nearest in-range spot, only during the day.

**D-08 — Unaffordable spots:** cost always shown in red when unaffordable. Holding the action key there plays a short shake and a "denied" cue, no coins move. Sound is a hook: wire a placeholder CC0 sound (logged) or leave silent until Phase 8 SFX pass.

**D-09 — Tight starting economy:** starting gold covers ~2 Houses **or** 1 tower, forcing a trade-off in the first minute. All numbers (starting gold, costs, income per tier, tower stats, drip rate) live in `.tres` data, tuned at the Phase 2 playtest gate.

**D-10 — Linear-only tiers in Phase 1:** House has 3 tiers (build + 2 upgrades), income rises each tier (deliberate deviation from Thronefall's 2-tier House). Basic tower has 2 tiers (build + 1 upgrade); does nothing in Phase 1 (no enemies) but its label still shows the tier's stats as the effect. Branching upgrade cards (BLDG-05) are Phase 5.

**D-11 — Real hold-to-confirm "start night" input built now:** dedicated action, separate from the build/action key, bound on keyboard and gamepad. Works anywhere during the day, shows a filling on-screen prompt. Phase 2 reuses it unchanged (LOOP-01), only adding enemies behind it.

**D-12 — Placeholder night, then visible dawn payout:** lighting shifts to a night mood for a few seconds under a "Night N — no enemies yet" banner. At dawn, coins pop out of each House and fly to the HUD gold counter, then a "+X gold" total appears. Establishes the Day→Night→Dawn→Day loop state machine and day/night lighting states Phase 2 fills rather than replaces. No final night, no win/loss in Phase 1; days repeat until the player quits.

**D-13 — Public GitHub repo under `ABSAR07`, added as `origin`; CI runs on every push.** Creating the repo and first push are outward-facing — executor must get explicit user confirmation (including repo name) before `gh repo create`/pushing. One-way/irreversible once public.

**D-14 — Setup script fetches a pinned Godot:** downloads official Godot 4.7.2-stable standard win64 release, verifies against official checksums, stores it in a git-ignored project folder (e.g. `.tools/godot/`). Every local script (test/lint/screenshot/export) and CI use exactly this version; CI (Linux runner) pins the same version. Ask before first download.

**D-15 — Windows export works locally and in CI from the start:** setup script also downloads matching 4.7.2 export templates (~1 GB) so a local Windows `.exe` export works immediately — ask before downloading. CI produces a Windows export on every push as a downloadable workflow artifact.

**D-16 — Git LFS from the first commit:** `.gitattributes` routes binary asset types (`*.glb`, `*.fbx`, `*.png`, `*.wav`, `*.ogg`) to LFS, forces LF line endings for text files (`.gd`, `.tscn`, `.tres`, `.cfg`, `.godot`). CI checkouts enable LFS. Keep assets lean given GitHub's free LFS quota. `.godot/` fully git-ignored.

### Claude's Discretion
- **Camera:** angle, perspective vs orthographic, FOV/size, follow smoothing. Must be a fixed isometric-style angle that follows the king (KING-02); player can't rotate it.
- **King movement:** walk/sprint speeds (Thronefall reference ratio ~1.6×, no stamina), turning feel, acceleration.
- **Build interaction details:** interaction radius and nearest-spot-wins logic; whether the king can keep moving while holding (leaving range still cancels/refunds per D-06); coin drip rate (~0.15–0.3s/coin starting point); max-tier behavior ("Max tier" label, holding does nothing).
- **Numbers:** exact starting gold, costs, House income per tier, tower stats, payout animation timing, within D-09/D-10. Thronefall reference: House 2 gold, paying 1 then 2 gold/night; tower 3→5→15.
- **Default bindings:** default keys/buttons for move, sprint, action (hold), start night (hold), debug overlay toggle. No conflict between build-hold and start-night-hold. Rebinding UI is Phase 13.
- **Debug overlay (DEV-03):** contents/layout; must show FPS, unit/enemy counts (zero for now), current loop state; must be extensible for Phase 2's wave state/enemy paths.
- **Screenshot scenes (DEV-04):** which scripted scenes get captured; at minimum a day overview, the label near a spot, a build in progress, the dawn payout, the overlay on.
- **Attribution log:** format/location (e.g. human-readable `ASSETS.md`/credits file, optionally a machine-readable manifest Phase 13's credits screen can reuse).
- **Which CC0 pack(s)** provide the four models. Prefer GLB sources (e.g. Kenney), stay visually consistent.
- **Tooling details:** project folder layout (follow ARCHITECTURE.md's structure); GUT test organization; CI workflow structure/action choices (e.g. `chickensoft-games/setup-godot` or a pinned download step); whether to add a local pre-commit lint hook.
- **Simulation tick:** a fixed-step simulation tick and seeded RNG service may be set up now so Phase 2's determinism work (DEV-05) doesn't retrofit them — optional groundwork, not a Phase 1 deliverable.

### Deferred Ideas (OUT OF SCOPE)
None. The discussion stayed within the phase scope.
</user_constraints>

## Architectural Responsibility Map

Adapted from ARCHITECTURE.md's project tiers (this is a desktop game, not a client/server web app — "tier" here means the project's own `simulation / presentation / input / ui / data / tooling` split, which the planner should use instead of a web-service tier vocabulary).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| King movement + sprint | Presentation (`CharacterBody3D` node) | Input (device → movement vector) | No HP/combat exists yet in Phase 1, so there's nothing headless-testable about movement itself; it's a controller, not simulation state. Input translates raw device state to a movement vector; presentation applies it via `move_and_slide`. |
| Camera follow | Presentation (`camera/` rig) | — | Pure visual concern, no simulation dependency. |
| Build-spot proximity + affordance display | Input (`Area3D` proximity → nearest spot id) | Presentation (world-space floating label, D-07) | Proximity detection is an input-adjacent device/world query; the label rendering is presentation reading that result plus simulation's cost/affordability data. |
| Hold-to-build progress + coin drip | Input (hold timer, drip tick) → Simulation (validates + mutates on completion) | Presentation (coin VFX) | The *timer and refund-on-release* logic can stay in the input/intent layer since no gold moves until the last coin lands (D-05/D-06); the actual gold deduction and `BuildingInstance` creation is simulation, invoked once via `BuildIntent`. |
| Economy (gold, income, carryover) | Simulation (`simulation/economy/`) | — | Pure data logic per ECON-01/02/07; must be headless-testable per DEV-01. |
| Building/upgrade rules (BLDG-01..04, BLDG-06) | Simulation (`simulation/buildings/`) | Data (`BuildingDef`/`UpgradeTier` `.tres`) | Validation (afford? day-only? correct spot type?) lives once in `CommandProcessor`, not duplicated in UI and mutation code (ARCHITECTURE.md Pattern 7). |
| Day/Night/Dawn loop state machine | Simulation (`RunManager`, `simulation/run/`) | Presentation (lighting mood, banner text) | This *is* the architecture's Pattern 1; only `RunManager` may change phase. |
| Debug overlay (DEV-03) | Presentation/UI | Simulation (read-only state source) | Overlay reads `RunManager.phase`, `Economy.gold`, unit/enemy counts — never mutates. |
| Screenshot capture tooling (DEV-04) | Tooling (`tools/` script, CLI-invoked) | Presentation (the scene it renders) | Not part of runtime gameplay code; a separate headful-but-automated script per Common Pitfalls #1. |
| CI: lint, test, export (DEV-01/02) | Tooling/CI (`.github/workflows/`) | — | Cross-cutting infrastructure, not a gameplay tier. |
| Attribution log (ART-02) | Data/Docs (repo root, e.g. `ASSETS.md`) | — | Not code — a tracked repo artifact. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.7.2-stable (standard, non-.NET) | Game engine | Locked in STACK.md/CLAUDE.md; confirmed current — release assets for `4.7.2-stable` verified present on `godotengine/godot-builds` [VERIFIED: github.com/godotengine/godot-builds releases API, fetched 2026-09-29] |
| GDScript | ships with 4.7.2 | Primary scripting language | Zero build step, static typing enforced project-wide per CLAUDE.md |
| GUT (Godot Unit Test) | 9.7.1 | Headless GDScript test framework | Tag `v9.7.1` confirmed on `bitwes/Gut`, target branch `godot_4_7`, published 2026-07-10 [VERIFIED: github.com/bitwes/Gut releases API, fetched 2026-09-29] |
| gdtoolkit (`gdformat`, `gdlint`) | 4.5.0 | GDScript formatter/linter | Confirmed latest and installable via `pip index versions gdtoolkit` → `4.5.0` is newest [VERIFIED: pip index versions gdtoolkit, run this session] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `chickensoft-games/setup-godot` GitHub Action | `@v2` | Installs pinned Godot + (optionally) export templates in CI, with caching | Lint/test CI job; set `use-dotnet: false` for the standard build, `include-templates: true` only on the export job [CITED: github.com/chickensoft-games/setup-godot action.yml] |
| `lihop/setup-godot` GitHub Action | latest tagged | Alternative that auto-starts an Xserver and exports `DISPLAY` on Linux runners | Screenshot-capture CI job, as a lower-friction alternative to hand-rolling `xvfb-run` [CITED: github.com/lihop/setup-godot README] |
| Kenney "Mini Characters" pack | latest (kenney.nl) | CC0 low-poly character source for the king model | D-01's "real CC0 model for the king" — GLB, CC0 1.0, no attribution required [CITED: kenney.nl, corroborated by community pack listings] |
| Kenney "Castle Kit" pack | latest (kenney.nl) | CC0 low-poly medieval/castle modular kit for House, tower, castle center | D-01's House/tower/castle-center models; explicitly built for GLB/Godot workflows per Kenney's own pack description [CITED: kenney.nl / poly.pizza mirror listing] |
| Git LFS | 3.5.1 (already installed locally) | Binary asset storage | D-16; confirmed installed this session [VERIFIED: `git lfs version`, run this session] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `chickensoft-games/setup-godot` | `abarichello/godot-ci` Docker image | Pre-baked image with export templates and headless deps already installed; less caching flexibility per-run, more opaque version pinning — fine as a fallback if the action proves flaky |
| Hand-rolled `xvfb-run` screenshot job | `lihop/setup-godot`'s auto-Xserver mode | Less CI boilerplate, but one more third-party action dependency; hand-rolled `xvfb-run` is more transparent/debuggable and has zero extra action dependency |
| gdtoolkit's default `.gdlintrc` | A hand-authored `.gdlintrc` enforcing project-specific naming | Default catches nothing project-specific (e.g. `simulation/` files importing `Node3D`); a custom rule set is more valuable once the sim/presentation split exists to enforce, likely not worth it in Phase 1's first plan |

**Installation:** (subject to the Execution Checkpoints above — do not run unattended)
```bash
# 1. Godot 4.7.2-stable standard win64 build (D-14) — ASK FIRST (Checkpoint 2)
#    https://godotengine.org/download/archive/4.7.2-stable/
#    -> resolves to https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=win64.exe.zip&platform=windows.64
#    Verify against SHA512-SUMS.txt from the godotengine/godot-builds 4.7.2-stable release.
#    Store at .tools/godot/ (git-ignored).

# 2. Export templates (D-15) — ASK FIRST (Checkpoint 3), ~1 GB
#    Godot_v4.7.2-stable_export_templates.tpz from the same release.

# 3. GUT 9.7.1 addon
#    git clone --branch v9.7.1 https://github.com/bitwes/Gut.git  # or download zip
#    -> copy the `addons/gut` folder into res://addons/gut/
#    Enable: Project > Project Settings > Plugins > Gut

# 4. gdtoolkit (local + CI)
pip install "gdtoolkit==4.5.0"

# 5. Git LFS (already installed locally per this session's check)
git lfs install
git lfs track "*.glb" "*.fbx" "*.png" "*.wav" "*.ogg"
```

**Version verification performed this session:**
- `pip index versions gdtoolkit` → `4.5.0` is latest [VERIFIED]
- `git lfs version` → `3.5.1` installed [VERIFIED]
- GitHub releases API for `godotengine/godot-builds` tag `4.7.2-stable` → assets include `SHA512-SUMS.txt`, `Godot_v4.7.2-stable_win64.exe.zip`, `Godot_v4.7.2-stable_export_templates.tpz` [VERIFIED]
- GitHub releases API for `bitwes/Gut` → tag `v9.7.1`, target branch `godot_4_7`, published 2026-07-10 [VERIFIED]
- `godot`, `python`, `git`, `gh` on PATH checked this session (see Environment Availability)

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| gdtoolkit | PyPI | 4.5.0 published 2025-10-09 (per registry) | unknown (PyPI API returned null) | github.com/Scony/godot-gdscript-toolkit | SUS | Approved — the `SUS` verdict is driven solely by `unknown-downloads` (a PyPI API gap, not a signal about the package itself); the repo is long-established and independently corroborated by CLAUDE.md/STACK.md's own verified sources. Planner should still add a lightweight `checkpoint:human-verify` before the first `pip install` per protocol. |
| GUT (bitwes/Gut) | Not a package registry — installed via GitHub release/clone | v9.7.1, godot_4_7 branch | N/A (not registry-distributed) | github.com/bitwes/Gut | Not applicable to the registry-based legitimacy check | Approved — verified directly against the GitHub releases API this session (tag + target branch + publish date match STACK.md's compatibility table). |
| Godot engine binary | Not a package registry — official downloads.godotengine.org / GitHub releases | 4.7.2-stable | N/A | github.com/godotengine/godot(-builds) | Not applicable | Approved — verify via SHA512-SUMS.txt checksum at download time (D-14), not a registry legitimacy check. |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** gdtoolkit — see disposition above (false-positive-shaped, but the protocol's checkpoint still applies).

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────┐
                    │  Keyboard / Gamepad device   │
                    └───────────────┬──────────────┘
                                    ▼
                    ┌─────────────────────────────┐
                    │  input/ : device → movement   │
                    │  vector, Area3D proximity,    │
                    │  hold-timer → BuildIntent /   │
                    │  StartNightIntent             │
                    └───────────────┬──────────────┘
                                    ▼
                    ┌─────────────────────────────┐
                    │  CommandProcessor (validates: │
                    │  DAY phase? spot valid? gold   │
                    │  sufficient?)                  │
                    └───────────────┬──────────────┘
                          valid     │    invalid
                    ┌───────────────┴──────┐   └──► denied shake/cue (D-08), no state change
                    ▼                       
        ┌───────────────────────┐  ┌─────────────────────┐
        │ simulation/economy/   │  │ simulation/buildings/│
        │ Economy.deduct/       │◄─┤ BuildingSystem       │
        │ apply_dawn_income     │  │ (create/upgrade from │
        └───────────┬───────────┘  │  BuildingDef .tres)  │
                    │              └──────────┬───────────┘
                    ▼                         ▼
              ┌─────────────────────────────────┐
              │      EventBus (autoload)          │
              │ gold_changed, building_built,      │
              │ night_started, dawn_payout, ...    │
              └───────────────┬────────────────────┘
                              ▼
        ┌──────────────────────────────────────────┐
        │ presentation/ (mesh spawn/update, coin VFX)│
        │ ui/ (HUD gold, floating spot label, overlay)│
        │ audio/ (build sfx, denied cue)              │
        └──────────────────────────────────────────┘

  RunManager (simulation/run/) owns RunPhase: DAY ↔ NIGHT_TRANSITION ↔
  NIGHT (placeholder, no enemies) ↔ DAWN ↔ DAY — only it may change phase;
  everything above reacts to phase_changed via EventBus.
```

### Recommended Project Structure
Per ARCHITECTURE.md §"Recommended Project Structure" (already the locked reference — reproduced here trimmed to what Phase 1 actually creates):
```
project/
├── data/
│   ├── buildings/          # house.tres, tower.tres (BuildingDef + UpgradeTier[])
│   └── maps/                # prototype_map.tres (MapConfig: build spots, castle center)
├── simulation/
│   ├── run/                 # RunManager (RunPhase state machine)
│   ├── economy/              # Economy (gold, dawn income)
│   ├── buildings/            # BuildSpot, BuildingInstance, BuildingSystem
│   └── events/                # EventBus signal definitions
├── presentation/
│   ├── scenes/                # prototype_map.tscn, king.tscn, house.tscn, tower.tscn
│   └── camera/                  # CameraRig (follow + fixed isometric angle)
├── ui/
│   ├── hud/                     # gold counter, start-night hold prompt
│   └── overlay/                  # debug overlay (DEV-03)
├── input/                          # raw device → BuildIntent/StartNightIntent
├── autoload/                        # EventBus.gd, RunManager.gd (or RunManager as autoload)
├── tests/
│   ├── unit/                        # economy, building-rule tests
│   ├── integration/                  # day→night→dawn loop tests
│   └── fixtures/                      # test MapConfig/BuildingDef resources
├── tools/
│   └── screenshot/                    # headful screenshot-capture script(s)
├── addons/gut/                          # GUT 9.7.1
├── ASSETS.md                              # attribution log (ART-02)
├── export_presets.cfg
├── .gitattributes                          # LFS routing + LF enforcement (D-16)
└── .gitignore                                # .godot/, .tools/ (D-14 storage)
```

### Pattern 1: Headless GUT invocation (test job)
**What:** Run GUT entirely under `--headless` — no Xvfb, no rendering driver — since `simulation/` tests never touch a viewport.
**When to use:** Every CI push and local pre-commit test run (DEV-01/DEV-02).
**Example:**
```bash
# Source: synthesized from gut.readthedocs.io Command-Line docs + Godot command-line docs [CITED]
# One-time warm-up so resources/imports are registered (avoids flaky first-run failures):
godot --headless --path . --import --quit

# Actual test run, CI-friendly exit code (0 pass / 1 fail):
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit,res://tests/integration -gexit
```
`.gutconfig.json` (checked into repo root or `res://`) can hold the same settings so both local and CI runs share one source of truth:
```json
{
  "dirs": ["res://tests/unit/", "res://tests/integration/"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "should_exit": true,
  "log_level": 1
}
```
[CITED: gut.readthedocs.io/en/latest/Command-Line.html]

### Pattern 2: Screenshot capture requires a *different* CLI mode than tests
**What:** `--headless` disables the rendering device; a screenshot script must instead run under a virtual display with a real rendering driver.
**When to use:** DEV-04's scripted-scene screenshot capture, both locally (if no GPU/display is convenient) and in CI.
**Example:**
```bash
# Source: synthesized from Godot GitHub issues (#98247 et al.) + community CI write-ups [CITED]
# Local (Linux CI) — Mesa software rasterizer, no GPU required:
xvfb-run --auto-servernum godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 res://tools/screenshot/day_overview.tscn --quit-after 60
```
The screenshot scene itself calls, after at least one rendered frame:
```gdscript
# Source: synthesized from multiple community sources on get_viewport().get_texture() [CITED]
await RenderingServer.frame_post_draw
var img := get_viewport().get_texture().get_image()
img.save_png("res://screenshots/day_overview.png")
```
**Anti-pattern to avoid:** running the same script under `--headless` "for consistency with the test job" — it will silently save a black/empty image rather than failing loudly, because the rendering device never existed. This is the most likely first-week CI surprise here; verify visually the first time.

### Pattern 3: Windows export from a Linux CI runner without Wine
**What:** Disable the export preset's "Modify Resources" (icon/exe-metadata embedding) option so the export doesn't need `rcedit` via Wine.
**When to use:** DEV-02's "CI produces a Windows export" — Phase 1 has no custom icon yet anyway (D-01 uses placeholder/CC0 models, no branding), so there's nothing to embed.
**Example:**
```bash
# Source: synthesized from Godot forum/GitHub issue discussion on rcedit+Wine requirement [CITED]
godot --headless --path . --export-release "Windows Desktop" build/windows/game.exe
```
In `export_presets.cfg`, ensure the Windows preset has `application/modify_resources=false` (or equivalent — the exact key name should be confirmed against the actual 4.7.2 editor-generated file once the project exists, since exact preset option names are version-sensitive and the file doesn't exist yet in this greenfield repo). Revisit once a custom icon is designed (later phase).

### Pattern 4: Input Map — text-editable, dual-bound actions
**What:** `project.godot`'s `[input]` section is plain text; every gameplay action needs both an `InputEventKey` and an `InputEventJoypadButton`/axis entry (per the locked controls decision).
**Example (conceptual, to be generated by the editor or hand-authored):**
```ini
[input]
move_forward={
"events": [Object(InputEventKey,"physical_keycode":87), Object(InputEventJoypadMotion,"axis":1,"axis_value":-1.0)]
}
sprint={
"events": [Object(InputEventKey,"physical_keycode":4194326), Object(InputEventJoypadButton,"button_index":10)]
}
action_build={
"events": [Object(InputEventKey,"physical_keycode":69), Object(InputEventJoypadButton,"button_index":2)]
}
action_start_night={
"events": [Object(InputEventKey,"physical_keycode":78), Object(InputEventJoypadButton,"button_index":3)]
}
debug_toggle_overlay={
"events": [Object(InputEventKey,"physical_keycode":16777251)]
}
```
[CITED: docs.godotengine.org InputMap/InputEvent docs — exact keycode integers above are illustrative, not verified against a live `project.godot`; the planner should generate these via the editor's Input Map UI or Godot's own keycode constants rather than hand-typing integers]. **Discretion note:** `action_build` and `action_start_night` must never share a physical key/button (D-11's explicit "no conflict" requirement) — recommend distinct face buttons on gamepad (e.g. build = West/X, start-night = North/Y) and distinct keys on keyboard (e.g. `E` for build, `N` for start-night).

### Anti-Patterns to Avoid
- **Coupling king movement/build-spot logic to `_process`/`_physics_process` implicitly:** even in Phase 1 before real determinism work (DEV-05, Phase 2), keep `Economy`/`BuildingSystem` mutations behind explicit method calls (`build(spot_id)`, `apply_dawn_income()`) invoked from the intent layer — never have UI code reach into simulation state directly (ARCHITECTURE.md Anti-Pattern 1/4, already locked).
- **Storing partial build progress as building state:** D-06 is explicit — no partially-paid state is ever stored on a spot. Model the hold as ephemeral input-layer state (a coin counter that either completes into one `BuildIntent` or is discarded on release/range-exit), not as a simulation-layer field.
- **Testing under `--headless` and expecting a real screenshot**, or running GUT under Xvfb "for safety" (Pattern 2 above) — wastes CI minutes and can mask real headless-test regressions behind rendering flakiness.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GDScript test runner + CI exit codes | A custom `SceneTree`-based test harness | GUT 9.7.1's `gut_cmdln.gd` | Already handles exit codes, fixtures, doubles, and directory discovery; reinventing this for Phase 1 alone would duplicate work Phase 2+ also needs |
| GDScript style/lint enforcement | Custom regex-based style checker | gdtoolkit's `gdformat`/`gdlint` | Purpose-built for GDScript syntax, actively maintained, already in the locked stack |
| Screenshot capture off-screen rendering | A custom render-to-texture pipeline | `get_viewport().get_texture().get_image().save_png()` + Xvfb | Built into Godot; the only non-trivial part is the CI display/driver setup, not the capture API itself |
| Windows export packaging | Hand-zipping the exported folder | `godot --headless --export-release` + `actions/upload-artifact` | Godot's export pipeline already produces a self-contained folder; no packaging step needed for a CI artifact (butler/itch.io push is out of scope for Phase 1) |
| Stat/cost data for buildings | Hardcoded GDScript constants for costs/income/tiers | `.tres` `BuildingDef`/`UpgradeTier` Resources | Locked architecture decision (Pattern 2) — D-09's tuning-at-playtest-gate requirement specifically depends on these being data, not code |

**Key insight:** everything in Phase 1's tooling layer (test runner, linter, screenshot capture, export) has an existing, actively-maintained, already-locked-in solution — the actual engineering risk in this phase is entirely in *wiring them together correctly in CI* (the headless-vs-rendered distinction, the Wine/rcedit dependency), not in building any of them from scratch.

## Common Pitfalls

### Pitfall 1: `--headless` silently produces black/empty screenshots
**What goes wrong:** A screenshot-capture script written and tested locally (with a real display) works, then fails silently in CI because the CI job reuses the test job's `--headless` invocation, producing a black or all-transparent PNG instead of erroring.
**Why it happens:** `--headless` sets the display driver to `headless`, which disables the rendering device outright — `get_viewport().get_texture()` still returns *something*, but with no rendering having occurred, not an error.
**How to avoid:** Use two distinct CI steps/jobs — one `--headless` for GUT tests, one `xvfb-run ... --rendering-driver opengl3` (no `--headless`) for screenshots — and add an automated check that a saved PNG isn't uniformly black/empty (even a cheap pixel-variance check) as a CI assertion, not just "the file exists."
**Warning signs:** Screenshot files exist and are non-zero bytes but are visually blank when actually opened; CI "succeeds" but a human reviewing the artifact sees nothing.

### Pitfall 2: Windows export from Linux CI needs Wine+rcedit unless disabled
**What goes wrong:** The export step fails or silently produces an `.exe` with no icon/metadata because `rcedit` (needed to embed Windows resources) is Windows-only and isn't installed in the CI image.
**Why it happens:** Godot's Windows export "Modify Resources" option assumes `rcedit` is reachable (natively on Windows, via Wine elsewhere); a Linux runner has neither by default.
**How to avoid:** For Phase 1 (no custom icon exists yet), disable "Modify Resources" in the Windows export preset so the export path never invokes `rcedit`. Revisit only when a real icon/branding pass happens (later phase), at which point either install Wine+rcedit in CI or move the export job to a `windows-latest` runner.
**Warning signs:** Export step logs mention `rcedit` or icon embedding failures; the exported `.exe` has a generic/missing icon (expected in Phase 1, but confirm it's *because* the option is off, not because export silently failed a step).

### Pitfall 3: GUT/Godot version mismatch breaks double-generation
**What goes wrong:** GUT versions below 9.7.0 target Godot 4.6 and have a documented breaking change around double return-type handling against 4.7 — running an older GUT against 4.7.2 can produce parsing errors in generated test doubles.
**Why it happens:** GUT's internals generate GDScript "doubles" (mocks) by introspecting the engine's class API, which changes between minor Godot versions.
**How to avoid:** Pin exactly GUT `v9.7.1` (target branch `godot_4_7`, confirmed this session) — never let a dependency-update pass silently bump GUT without checking its target Godot branch first.
**Warning signs:** Cryptic "unresolved return" or "invalid class in class list" errors from GUT specifically during double generation, not from project code itself.

### Pitfall 4: Build/upgrade hold accepted mid-transition or at night
**What goes wrong:** Without an explicit phase guard, the hold-to-build interaction could complete a build during `NIGHT_TRANSITION` or `DAWN` (e.g. if the player starts holding right as the day ends), violating BLDG-06.
**Why it happens:** Input-layer hold timers are naturally decoupled from simulation phase unless explicitly checked both at hold-start *and* hold-completion (phase could change mid-hold in a later phase with a shorter day, though not possible in Phase 1's no-timer day — still worth guarding now since Phase 2 adds the real night).
**How to avoid:** `CommandProcessor` validates `phase == RunPhase.DAY` both when the hold *starts* (to show the correct affordance) and when the `BuildIntent` is *applied* (the actual mutation gate) — never trust the input layer's own phase snapshot from hold-start.
**Warning signs:** A build completes with a `+X gold at dawn` label that doesn't match the current phase in the debug overlay; a GUT test that starts a hold, force-transitions phase mid-hold, and asserts the build is rejected would catch this directly.

### Pitfall 5: Debug overlay coupling to simulation internals defeats headless testability
**What goes wrong:** DEV-03's debug overlay directly reads/mutates simulation objects (`RunManager.phase = X` for debug purposes, or the overlay itself holding gameplay state), quietly reintroducing a dependency from presentation back into simulation.
**Why it happens:** Debug tooling is often written fast/sloppy since "it's just for humans," making the read-only boundary the first thing to erode.
**How to avoid:** The overlay only subscribes to `EventBus` signals and read-only getters (`RunManager.phase`, `Economy.gold`) — per ARCHITECTURE.md's own explicit warning, treat it as presentation-layer, never a second source of truth or a debug-mutation surface (Pitfall 8 in `.planning/research/PITFALLS.md` already flags this project-wide).
**Warning signs:** A `RunManager` setter callable from anywhere other than `RunManager` itself; the overlay's code imports from `simulation/` rather than only listening to `autoload/EventBus.gd`.

## Code Examples

### Fixed isometric-style follow camera
```gdscript
# Source: synthesized from Godot 4 community camera-follow patterns [CITED — no single canonical
# official doc for this exact pattern; corroborated across multiple independent community sources]
class_name CameraRig
extends Node3D

@export var target: Node3D
@export var follow_speed: float = 6.0
@export var offset: Vector3 = Vector3(0, 14, 10)

func _physics_process(delta: float) -> void:
    if target == null:
        return
    var desired: Vector3 = target.global_position + offset
    global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
    # Fixed angle — rotation is set once at scene setup, never touched here (KING-02: no rotation).
```

### King movement with sprint (input → CharacterBody3D)
```gdscript
# Source: synthesized from Godot 4 official "Moving the player with code" pattern + Input.get_vector
# [CITED: docs.godotengine.org/en/stable/getting_started/first_3d_game/03.player_movement_code.html]
class_name King
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_multiplier: float = 1.6  # Thronefall reference ratio per CONTEXT.md discretion note

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var speed := walk_speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    move_and_slide()
```

### Hold-to-build coin drip (input-layer, ephemeral state — D-05/D-06)
```gdscript
# Source: original synthesis from D-05/D-06/D-07/D-08 requirements + ARCHITECTURE.md Pattern 7
# [ASSUMED structure — not verified against any external reference, this is project-specific design]
class_name BuildHoldController
extends Node

var _active_spot_id: StringName = &""
var _coins_dripped: int = 0
var _total_cost: int = 0
var _drip_timer: float = 0.0
const DRIP_INTERVAL := 0.2  # seconds/coin, within CONTEXT.md's 0.15-0.3s discretion range

func _process(delta: float) -> void:
    if _active_spot_id == &"":
        return
    if not Input.is_action_pressed("action_build") or not _king_in_range(_active_spot_id):
        _cancel_and_refund()
        return
    _drip_timer += delta
    if _drip_timer >= DRIP_INTERVAL:
        _drip_timer = 0.0
        _coins_dripped += 1
        if _coins_dripped >= _total_cost:
            _complete_build()

func _complete_build() -> void:
    var intent := BuildIntent.new(_active_spot_id)
    CommandProcessor.submit(intent)  # single mutation point — simulation validates again here
    _reset_hold_state()

func _cancel_and_refund() -> void:
    # No simulation-layer gold was ever deducted (D-06) — this just clears input-layer UI state.
    _reset_hold_state()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| GUT targeting Godot 4.6 (9.6.x line) | GUT 9.7.0+ targeting 4.7 (breaking double-return-type change) | 2026-07-10 (v9.7.1 release date, confirmed this session) | Must pin ≥9.7.0, never mix with the 4.6-targeted 9.6.x line per STACK.md's version compatibility table |
| Godot 4.0–4.2 FBX import (known skeleton/animation issues) | ufbx-based importer since 4.3 | Godot 4.3 | Not directly relevant if the chosen Kenney packs ship GLB (preferred per D-01/STACK.md); only matters if a gap-filling pack is FBX-only |

**Deprecated/outdated:** none identified specific to Phase 1's scope beyond the above.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact `project.godot` `[input]` keycode integers shown in the Input Map code example | Architecture Patterns / Pattern 4 | Low — illustrative only; the planner should generate real entries via the Godot editor's Input Map UI or `InputEventKey` constants, not copy these integers verbatim |
| A2 | The exported preset's exact key name for disabling icon/resource embedding (e.g. `application/modify_resources`) | Architecture Patterns / Pattern 3 | Medium — if the key name differs in the actual 4.7.2-generated `export_presets.cfg`, the planner needs to confirm it once the file exists (it doesn't yet — greenfield repo) rather than hand-typing a guessed key |
| A3 | Camera-follow and hold-to-build GDScript examples are original syntheses, not fetched from a single authoritative source | Code Examples | Low — these are illustrative starting points for the planner/executor, not verified-working code; GUT tests and manual screenshot review will catch correctness issues |
| A4 | Kenney's "Mini Characters" and "Castle Kit" are the best-fit packs for king/House/tower/castle | Standard Stack | Low-Medium — CONTEXT.md explicitly leaves pack choice to Claude's discretion; if these packs don't visually fit together (Pitfall 11 in PITFALLS.md), the executor should re-survey Kenney's catalog before committing, not treat this as locked |
| A5 | Proposed default keybindings (E=build, N=start-night, gamepad West=build, North=start-night) | Architecture Patterns / Pattern 4 | Low — explicitly Claude's discretion per CONTEXT.md; only hard constraint is no overlap between build-hold and start-night-hold, which this proposal satisfies |

**If this table is empty:** N/A — see entries above.

## Open Questions

1. **Exact GUT scene-testing needs for `CharacterBody3D`-based king movement**
   - What we know: Pure economy/building-rule logic is cleanly headless-testable (ARCHITECTURE.md's testability strategy, already locked).
   - What's unclear: Whether KING-01/02 need any automated test coverage at all in Phase 1, or whether they're screenshot/manual-only (per Pitfall 8 in PITFALLS.md, movement "feel" is inherently not unit-testable) — GUT does support scene-based testing (loading a `.tscn` and ticking `_physics_process`), so a minimal "king moves N units in T seconds at expected speed" integration test is possible but may be low-value for a controller with no combat yet.
   - Recommendation: Planner should scope KING-01/02 verification as screenshot + manual playtest primarily, with at most a thin unit test asserting the walk/sprint speed *constants* on the king's config (not actual scene-tree movement).

2. **Whether `chickensoft-games/setup-godot`'s caching interacts correctly with a pinned-download setup script (D-14)**
   - What we know: D-14 wants a project-owned setup script (not necessarily the GitHub Action) so local dev and CI use "exactly this version," stored in `.tools/godot/`.
   - What's unclear: Whether CI should use the setup-godot Action (simpler, but a second source of truth for the Godot version separate from the local setup script) or invoke the same local setup script inside CI (single source of truth, more CI script to maintain).
   - Recommendation: Prefer having CI invoke the *same* setup script D-14 creates for local use (single source of truth for the version pin + checksum), using the GitHub Action only as a fallback/alternative if that proves awkward in CI's environment.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot 4.7.2-stable editor | All gameplay/CI work | ✗ | — | D-14 setup script (checkpoint-gated download) — hard blocker until approved and run |
| Python (for gdtoolkit) | Lint/format (DEV-02) | ✓ | 3.14.5 | — |
| Git | Version control | ✓ | 2.46.0.windows.1 | — |
| Git LFS | D-16 binary asset storage | ✓ | 3.5.1 | — |
| GitHub CLI (`gh`) | D-13 repo creation | ✓ | 2.49.0, logged in as `ABSAR07` | — |
| GUT 9.7.1 addon | DEV-01 headless tests | ✗ | — | Download from `bitwes/Gut` tag `v9.7.1` (not a checkpoint — small text/GDScript files, not a large binary) |
| gdtoolkit 4.5.0 | DEV-02 lint | ✗ (installable) | latest confirmed via `pip index versions` | `pip install "gdtoolkit==4.5.0"` — not a checkpoint, small pure-Python package |
| Windows export templates (4.7.2) | DEV-02 Windows export, local `.exe` testing | ✗ | — | D-15 setup script (checkpoint-gated download, ~1 GB) — hard blocker until approved |
| Xvfb / Mesa llvmpipe (CI runner) | DEV-04 screenshot capture in CI | Not checked locally (this is a CI-runner concern, not local dev) — `ubuntu-latest` GitHub runners ship Mesa by default per community sources | — | If missing, `apt-get install -y xvfb libgl1-mesa-dev` in the CI job |

**Missing dependencies with no fallback:**
- Godot editor binary and export templates — both are explicit, user-approved downloads (Checkpoints 2 and 3). No other path exists; every other tool in this phase depends transitively on Godot being installed.

**Missing dependencies with fallback:**
- GUT and gdtoolkit — both are small, non-checkpoint-worthy installs the executor can perform directly once Godot itself is approved and present.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT (Godot Unit Test) 9.7.1 |
| Config file | none yet — Wave 0 must create `.gutconfig.json` at the project root |
| Quick run command | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit` |
| Full suite command | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit,res://tests/integration -gexit` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BLDG-01 | Build spot only allows its fixed building type | unit | `godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_build_spot.gd -gexit` | ❌ Wave 0 |
| BLDG-02 | Spot exposes correct cost/affordability given current gold | unit | `... test_build_spot_affordability.gd ...` | ❌ Wave 0 |
| BLDG-03 | `BuildIntent` on empty affordable spot creates a `BuildingInstance`, deducts gold | integration | `... test_build_flow.gd ...` | ❌ Wave 0 |
| BLDG-04 | `BuildIntent` on existing building upgrades tier, shows next cost/effect | integration | `... test_upgrade_flow.gd ...` | ❌ Wave 0 |
| BLDG-06 | Build/upgrade rejected outside `RunPhase.DAY` | unit | `... test_build_phase_guard.gd ...` | ❌ Wave 0 |
| ECON-01 | Gold never goes negative; HUD-facing getter returns current gold | unit | `... test_economy_gold.gd ...` | ❌ Wave 0 |
| ECON-02 | Dawn income scales with House tier per `.tres` data | unit | `... test_dawn_income.gd ...` | ❌ Wave 0 |
| ECON-07 | Gold persists unchanged across a Day→Night→Dawn→Day cycle beyond dawn income | integration | `... test_loop_gold_carryover.gd ...` | ❌ Wave 0 |
| D-06 (refund) | Releasing hold early or leaving range refunds all dripped coins, no partial state persists | integration | `... test_build_hold_refund.gd ...` | ❌ Wave 0 |
| KING-01/02 | Walk/sprint speed constants; camera never rotates | unit (constants only) + manual/screenshot | `... test_king_movement_config.gd ...` (constants) + screenshot review | ❌ Wave 0 |
| DEV-03 | Debug overlay reflects `RunManager.phase`/`Economy.gold` without mutating them | unit (read-only contract) | `... test_debug_overlay_readonly.gd ...` | ❌ Wave 0 |
| DEV-04 | Screenshot capture produces non-blank PNGs for the 5 scripted scenes | manual-only (CI produces artifacts; a human/agent reviews the PNGs) | `xvfb-run godot --path . --rendering-driver opengl3 ...` (see Pattern 2) | ❌ Wave 0 (script itself) |
| ART-02 | Every CC0 asset in use is present in the attribution log | manual-only | N/A — reviewed at phase verification, not automatable | ❌ Wave 0 (log file) |

### Sampling Rate
- **Per task commit:** quick run command (unit dir only) for the module just touched.
- **Per wave merge:** full suite command (unit + integration).
- **Phase gate:** full suite green, plus a human/agent screenshot review of the 5 DEV-04 scenes, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `addons/gut/` — GUT 9.7.1 installed and enabled
- [ ] `.gutconfig.json` — shared config for local + CI runs
- [ ] `tests/unit/`, `tests/integration/`, `tests/fixtures/` — directory scaffolding
- [ ] `tests/fixtures/` — a minimal `MapConfig`/`BuildingDef` test fixture (small prototype-map-shaped data, per D-04's own note that the real prototype map doubles as the test map)
- [ ] `tools/screenshot/` — the screenshot-capture script(s) themselves (DEV-04 has no existing infrastructure to build on — greenfield)

## Security Domain

> `security_enforcement` is enabled with `security_asvs_level: 1` per `.planning/config.json`. This is a single-player, offline, non-networked Windows desktop game with no accounts and (in Phase 1) no save file — most ASVS categories are structurally not applicable, documented explicitly below rather than silently skipped.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | No accounts/login exist or are planned for this offline single-player game |
| V3 Session Management | No | No sessions — a single local process, no network |
| V4 Access Control | No | No multi-user/permission boundary exists |
| V5 Input Validation | Yes (narrow) | `CommandProcessor` must validate every `BuildIntent`/`StartNightIntent` server-side-equivalent (i.e., simulation-side, not just UI-side) — phase guard, spot-type guard, affordability guard — exactly as ARCHITECTURE.md Pattern 7 already mandates. This is the one genuine "don't trust the input layer" boundary in Phase 1, even though the "attacker" is just a local player, because a UI-only check would let a bug (not malice) desync gold/building state. |
| V6 Cryptography | No | No secrets, no save file, no network traffic exist in Phase 1 to protect |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|-----------------------|
| UI-layer-only affordability/phase checks (bug, not malicious-actor risk) | Tampering (of in-memory game state via a logic bug) | Validate in `CommandProcessor`/simulation on every `BuildIntent`, never trust the input layer's own snapshot (see Pitfall 4 above) |
| Debug overlay accidentally shipped enabled with mutation hooks | Elevation of Privilege (local, trivial — a leftover debug hotkey) | Per `.planning/research/PITFALLS.md` Security Mistakes table (already documented project-wide): gate debug tooling behind a build flag, verify the actual behavior in a release export, not just the dev build — not a Phase 1 blocker since there's no release build yet, but the overlay should be built read-only from day one (Pitfall 5 above) so this is free later |

## Sources

### Primary (HIGH confidence)
- api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable — confirmed release assets (`SHA512-SUMS.txt`, `win64.exe.zip`, `export_templates.tpz`), fetched directly this session
- api.github.com/repos/bitwes/Gut/releases — confirmed `v9.7.1` tag, `godot_4_7` target branch, publish date, fetched directly this session
- `pip index versions gdtoolkit` — run directly this session, confirms `4.5.0` latest
- `git lfs version` / `gh --version` / `python --version` — run directly this session

### Secondary (MEDIUM confidence)
- gut.readthedocs.io/en/latest/Command-Line.html — GUT CLI flags and `.gutconfig.json` format
- docs.godotengine.org (command line tutorial, input tutorial, first-3D-game movement tutorial) — `--headless`/`--export-release` semantics, `InputMap`/`InputEvent` structure, `CharacterBody3D` movement pattern
- github.com/chickensoft-games/setup-godot (README + action.yml) — Action inputs, `use-dotnet`/`include-templates` semantics
- github.com/lihop/setup-godot — auto-Xserver alternative for screenshot CI
- kenney.nl pack listings (via web search, corroborated by poly.pizza mirror) — CC0 1.0, GLB, no-attribution-required pack characteristics
- deepwiki.com/Scony/godot-gdscript-toolkit — gdtoolkit config file format (`.gdlintrc`/`gdformatrc`, YAML, no `pyproject.toml` support)
- Multiple `godotengine/godot` GitHub issues (e.g. #98247, #86941, #5790 proposal) — corroborate that `--headless` disables the rendering device, motivating the Xvfb/rendering-driver split for screenshots
- godot-gdunit-labs/gdUnit4Net discussion #350 — corroborates Xvfb-based rendering in CI is real-but-slow, motivating keeping it to a separate, narrowly-scoped screenshot job

### Tertiary (LOW confidence)
- Community blog/forum posts on isometric `Camera3D` rig angles and follow-smoothing lerp patterns — no single canonical official doc, code example in this file is an original synthesis to be validated by the executor via screenshot review
- Community posts on `Area3D`/`get_overlapping_bodies()` proximity patterns — standard Godot idiom, not independently verified against a specific official doc page this session

## Metadata

**Confidence breakdown:**
- Standard stack (versions, checksums, GUT/gdtoolkit facts): HIGH — directly verified via GitHub API and local tool checks this session
- CI/tooling patterns (headless-vs-rendered split, Wine/rcedit gotcha): MEDIUM — multiple corroborating community + GitHub-issue sources, no single official "how to CI this" doc from Godot itself
- Gameplay code patterns (camera rig, king movement, hold-to-build controller): LOW-MEDIUM — mostly original synthesis against the locked architecture and CONTEXT.md decisions, not verified-working code; expect iteration during execution
- Security domain: HIGH confidence in the *scoping* (most ASVS categories genuinely don't apply to an offline single-player game with no save file yet) — this is a straightforward, low-risk assessment, not a deep audit

**Research date:** 2026-09-29
**Valid until:** ~30 days for version pins (Godot/GUT/gdtoolkit move slowly); ~7 days for anything CI-action-behavior-specific (chickensoft-games/setup-godot, lihop/setup-godot) since third-party Action internals can change without a version bump in this doc's citation
