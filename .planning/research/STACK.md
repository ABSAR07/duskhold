# Stack Research

**Domain:** Stylized low-poly 3D strategy / tower-defense / light city-builder ("Thronefall-like"), Windows PC, itch.io distribution, AI-agent (Claude)-driven development
**Researched:** 2026-09-28
**Confidence:** HIGH (engine choice, licensing, CLI/CI workflow); MEDIUM (exact perf ceiling for "hundreds of units," some addon version pins)

## Engine Decision

**Recommendation: Godot 4.7 (pin 4.7.2-stable, released 2026-08-18), scripted primarily in GDScript, using the standard (non-.NET) build.**

> **Orchestrator version correction (2026-09-28):** The researcher originally pinned Godot 4.5.1. Verification against the official Godot release blog (https://godotengine.org/blog/release/) shows newer stable releases: 4.6 (2026-01-26), 4.6.1–4.6.3, 4.7 (2026-06-18), 4.7.1 (2026-07-14), **4.7.2 (2026-08-18, latest stable)**; 4.8 is in dev snapshots only. All version pins below have been updated to the 4.7 line. The engine *choice* and its rationale are unchanged.

This is a decisive, single-engine recommendation. Comparison and rationale below.

### Comparison Table

| Criterion | **Godot 4.7** | Unity 6 (6000.3 LTS) | Unreal Engine 5.6/5.8 | Bevy 0.17 (Rust) | Web (Three.js/Babylon.js + TS) |
|---|---|---|---|---|---|
| **Text-based, diff-friendly scenes/resources** | Yes — `.tscn`/`.tres` are plain text by default, human- and LLM-editable, clean git diffs | No — scenes/prefabs are YAML-ish but large, fragile, editor-serialized; meta noise pollutes diffs | No — `.uasset`/`.umap` are binary blobs; unreadable/unmergeable by an agent | Yes (all Rust source, no opaque scene format) but no scene format at all — everything is code, which is diff-friendly but has no visual editor fallback for a human to sanity-check | Yes (all source/JSON) but no engine-native scene format; must hand-roll one |
| **Headless CLI: run, test, export without GUI** | Yes — `godot --headless` runs the game/tests/exports from a shell; this is a first-class, documented workflow | Partial — `-batchmode -nographics` exists but Unity's CLI/build pipeline is heavier, licensing-gated, slower to boot, historically flaky in CI | Partial — `UnrealEditor-Cmd` / `RunUAT` exist but are heavyweight (multi-GB toolchain, long cook times), not built for fast agent iteration loops | Yes — it's a Rust binary; `cargo run`/`cargo test` are natively headless-capable | Yes — Node-based dev servers and headless browser test runners (Playwright) exist but must be assembled, not built-in |
| **LLM/agent familiarity with language & APIs** | HIGH for GDScript specifically: reports from 2026 confirm modern LLMs (Claude Opus/Sonnet family) write clean, idiomatic Godot 4 GDScript, and Godot's text-first architecture is repeatedly cited as the easiest engine for AI agents to reason about (scenes/scripts/configs all readable text) | HIGH raw C# training-data volume, but scene/prefab GUID-linking and heavy inspector-driven workflows are hard for a non-GUI agent to manipulate correctly | MEDIUM for C++/Blueprints in general, but Blueprints are visual-only (unusable by a text-only agent) and the binary asset format blocks agent editing entirely | MEDIUM — Bevy has a small but growing corpus, ECS patterns are less universally documented, and the API churns significantly between 0.x versions (0.17 released Oct 2025), risking stale-training-data mismatches | MEDIUM — huge general JS/TS corpus, but no standardized "game project" convention, so the agent must invent architecture rather than follow one |
| **Stylized low-poly 3D + isometric-ish camera, day/night lighting/post** | Yes — built-in WorldEnvironment, DirectionalLight3D, glow/SSAO/tonemap, easy orthogonal/isometric camera setup; well-suited to low-poly stylized look | Yes — URP handles this well too, but is heavier to configure and iterate on without the editor GUI | Yes, and best-in-class visuals, but Lumen/Nanite are overkill and *expensive* for a low-poly stylized game and for a GTX 970-class target | Possible but immature — Bevy's PBR/lighting pipeline is functional but far less polished for stylized non-photorealistic look development, more manual shader work needed | Possible (Three.js has toon shading, post-processing) but requires assembling a rendering pipeline from scratch |
| **Perf on modest hardware (GTX 970 / 4GB RAM), hundreds of units** | Yes — Forward+ / Mobile renderer, MultiMesh GPU instancing, and Godot ships and runs well on this class of hardware; huge body of "hundreds of instances" optimization guidance | Yes, mature (Thronefall itself shipped this way), GPU instancing via `Graphics.DrawMeshInstanced`/DOTS available, but far heavier baseline engine/editor footprint | Yes for the runtime, but authoring/iterating a lightweight game in UE on a GTX-970-class dev box is itself painful (editor alone wants much more VRAM) | Yes technically (Rust performance headroom is excellent) but rendering/instancing ergonomics are less turnkey and require more custom code to match Godot's MultiMesh out-of-the-box | Constrained by browser GPU/WebGL2/WebGPU variability; achievable but not the target platform (Windows native exe) anyway |
| **Windows export + itch.io (butler)** | Yes — one-click/CLI export to a self-contained Windows folder; butler pushes folders directly, documented itch.io workflow | Yes, standard and well-trodden (Thronefall precedent) | Yes but export/cook artifacts are huge (GBs) for a small game, slower iteration | Yes — `cargo build --release --target x86_64-pc-windows-msvc` produces a native exe; butler push works fine | N/A — not a native Windows download; would require Electron/Tauri wrapper, added complexity for no benefit |
| **Zero-cost licensing, no royalties/seats** | Yes — MIT license, fully free, no revenue thresholds, no seat fees, no attribution splash required | Yes for Personal tier below revenue threshold (free, no runtime fee as of the 2024 policy reversal), but tier/eligibility rules exist and could apply if the project ever monetizes | Yes below $1M lifetime revenue (5% royalty above, 3.5% if EGS day-and-date) — irrelevant financially for a free portfolio project but adds legal/tracking overhead and EULA complexity for zero benefit | Yes — MIT/Apache-2.0 dual license, fully free | Yes — all recommended libraries (Three.js, Babylon.js) are MIT-licensed |
| **Keyboard+mouse: WASD avatar, mouse-pick build spots, box-select/command units, UI** | Yes — `Input` map, `Camera3D.project_ray_*`/physics picking, `Control` UI nodes, and multiple free RTS-selection addons/tutorials exist | Yes, equally capable (Thronefall proves it), but building UI without the Editor GUI is significantly more friction for an agent | Yes, capable, but UMG/Slate UI workflows lean heavily on the visual editor | Possible via `bevy_picking`/ray casting and `bevy_ui`, but RTS-style box-select/group-command is DIY — fewer existing references to draw on | Yes technically (raycasting via Three.js), but again, no native "game UI" convention — everything hand-built |
| **Automated testing framework, headless-in-CI** | Yes — **GUT** (GDScript-native) and **gdUnit4** (GDScript + C#) both run headlessly via CLI/GitHub Actions; mature, actively maintained (GUT 9.7.x adds Godot 4.7 compatibility; gdUnit4 v6.x documents 4.5/4.6 support, 4.7 support not yet confirmed in its release notes) | Yes — Unity Test Framework (UTF), runs headless via `-runTests -batchmode`, but slower CI boot and license-check friction in CI runners | Limited — Unreal's Automation/Functional Testing framework exists but is heavyweight and poorly suited to fast headless CI for a small team | Yes — native `cargo test`, extremely fast and CI-friendly, but no game-specific test helpers (must write your own scene/fixture harness) | Yes (Vitest/Jest + Playwright) but again hand-assembled, not a first-party game-test framework |
| **CC0 asset import (Kenney/KayKit/Quaternius, glTF/GLB/FBX/OBJ)** | Yes — native glTF2 importer is Godot's primary/recommended 3D pipeline; FBX import greatly improved in 4.3+ via built-in ufbx importer; OBJ supported; Kenney ships GLB directly (best case), Quaternius/KayKit FBX or GLB both work | Yes, mature FBX/glTF import (Thronefall-precedent packs import fine) | Yes, robust FBX/glTF pipeline, arguably the most forgiving of messy source files | Partial — glTF loading exists (`bevy_gltf`) but is less forgiving of non-standard exports; FBX not natively supported (must pre-convert) | Yes — glTF loaders are mature (GLTFLoader in Three.js, SceneLoader in Babylon.js); FBX needs pre-conversion |
| **Save/persistence for meta-progression** | Yes — `FileAccess` + JSON, or `ConfigFile`, or custom `Resource` serialization to `user://`; simple, text-debuggable, well documented | Yes — `PlayerPrefs` (simple/limited) or JSON to `Application.persistentDataPath`; equally viable | Yes — SaveGame objects via `UGameplayStatics`; more ceremony, C++/Blueprint-oriented | Yes — `serde` + `ron`/JSON to a data dir; very clean in Rust, but no built-in convention, DIY | Yes — `localStorage`/IndexedDB, but this is the browser sandbox model, not applicable to a native Windows build target |

### Why Godot wins decisively

1. **It is the only engine whose primary project format is plain text end-to-end.** `.tscn` scenes, `.tres` resources, `project.godot`, and `.gd` scripts are all readable/writable/diffable by an agent with a text editor and a shell — no GUI clicking required at any point in the authoring loop. Unity's YAML scenes are technically text but are large, GUID-riddled, and easily corrupted by non-Editor hand edits; Unreal's binary `.uasset`/`.umap` files are opaque to a coding agent entirely.
2. **Godot has a first-class, documented `--headless` mode** for running the game, running automated tests (GUT/gdUnit4), and exporting release builds, all from the CLI — exactly the workflow Claude needs. Unity and Unreal both have headless/batch modes, but they are heavier, slower to boot, and (for Unity) license-check-gated even for the free tier in CI.
3. **2026 evidence explicitly favors GDScript + Claude.** Community write-ups from mid-2026 report that Claude's Opus/Sonnet family produces clean, idiomatic Godot 4 GDScript and that Godot's text-first architecture makes it the easiest engine for AI coding agents to reason about — this is the single most decision-relevant, current data point for this project.
4. **MIT license, zero cost, no thresholds, no attribution splash** — simplest possible licensing story for a free portfolio project; Unity/Unreal's revenue-threshold royalty clauses are irrelevant at $0 revenue but add unnecessary legal surface area for no benefit.
5. **MultiMesh + NavigationServer3D/RVO avoidance comfortably cover "hundreds of units + projectiles"** on GTX 970-class hardware, matching Thronefall's actual production scale (Thronefall itself never needed thousands of simultaneous agents).
6. **CC0 low-poly packs (Kenney, KayKit, Quaternius) import cleanly** via Godot's native glTF2 pipeline (Kenney ships GLB directly) and the greatly improved built-in FBX importer (ufbx, since 4.3) for the packs that ship FBX.

### Why the others lost

- **Unity 6**: The best "proven" choice (Thronefall's own engine) and technically fully capable, but its binary-ish serialized scenes/prefabs and Editor-centric prefab/inspector workflow are meaningfully harder for a no-GUI coding agent to manipulate reliably than Godot's plain-text scenes. Licensing is free for this use case, but adds tier/eligibility tracking overhead irrelevant to a $0-revenue project.
- **Unreal Engine 5**: Best-in-class visual fidelity and battle-tested performance, but Nanite/Lumen and the general engine weight are overkill (and counterproductive) for a low-poly, GTX-970-target game; binary `.uasset` assets are unreadable/unwritable by an agent; Blueprints are visual-only and unusable by a text-only coding agent; heaviest install/build footprint of any candidate.
- **Bevy 0.17 (Rust)**: Technically excellent performance and fully text/code-based (which is diff-friendly), but it is pre-1.0, its API still churns meaningfully between minor versions (raising stale-training-data risk for an LLM), it has no built-in scene editor or GUI at all (harder for the human owner to sanity-check the agent's work), and its rendering/UI/RTS-selection ergonomics require substantially more from-scratch work than Godot provides out of the box. Best reserved for teams prioritizing raw performance/control over development speed.
- **Web stack (Three.js/Babylon.js + TypeScript)**: Huge LLM familiarity with JS/TS, and technically capable of the visuals, but the project's actual target is a native Windows itch.io download, not a browser game — shipping via a web stack would mean wrapping in Electron/Tauri for no upside, plus hand-building everything (scene format, ECS, editor, test harness) that Godot already provides.

### GDScript vs C# within Godot

**Recommendation: GDScript for all gameplay code.**

- GDScript keeps the entire project in one language with zero build-step friction — no .NET SDK, no MSBuild step blocking headless CI, no separate C# export template downloads. This matters directly for the "Claude runs everything from a shell" requirement: `godot --headless` runs `.gd` scripts immediately, while C# requires a compiled assembly step first.
- 2026 community evidence specifically flags Claude's GDScript output quality as strong; C# in Godot draws on Unity-flavored training data that doesn't always map cleanly onto Godot's C# API surface (different node/signal idioms), which can introduce subtle agent errors.
- Godot's dynamic typing is a known footgun for large codebases; mitigate by mandating **static typing everywhere** (`var x: int`, typed function signatures) — this gives most of C#'s error-catching benefit while staying in one language and one toolchain. Enforce with `gdlint` (see Development Tools).
- Performance: GDScript is not as fast as C#, but for hundreds of instanced units driven by MultiMesh + simple state machines (not physics-heavy simulation), it is not expected to be the bottleneck. If profiling later reveals a hot path (e.g., pathfinding-heavy AI tick for many agents), that specific system can be moved to a GDExtension (C++) — but do not reach for C# preemptively.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Godot Engine | **4.7.2-stable** (standard/non-.NET build) | Game engine | Latest stable maintenance release as of Sept 2026 (4.7 shipped 2026-06-18 with rendering/HDR improvements; 4.7.2 shipped 2026-08-18 fixing stability bugs; 4.6 focused on QoL + performance); text-based scenes, headless CLI, MIT license — see comparison above |
| GDScript | Godot 4.7's built-in version | Primary scripting language | Zero build step, best-documented 2026 LLM/agent fit, one toolchain for editor+CLI+CI |
| Forward+ renderer (Godot default, desktop) | Ships with 4.7 | Rendering backend | Best quality/perf balance for desktop; switch a given scene's environment to a simplified glow/SSAO setup to keep GTX-970 headroom. (Godot's separate "Mobile" renderer is a fallback only if perf profiling demands it — unlikely needed for this art style/scale) |

### Supporting Libraries / Addons

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **GUT** (Godot Unit Test) | **9.7.1** (9.7.0 added Godot 4.7 compatibility; 9.6.x targets 4.6, 9.5.x targets 4.5 — pin to the release matching your exact editor version) | GDScript-native unit/integration testing, headless-runnable | Primary test framework; write tests under `res://tests/`, run via `godot --headless -s addons/gut/gut_cmdln.gd` in CI |
| **gdUnit4** | v6.2.x (documents Godot 4.5/4.6 support; verify 4.7 compatibility before adopting) | Alternative/supplementary test framework with richer assertions, scene testing, mocking, JUnit XML export | Consider if you want JUnit-format CI reports or C# interop later; not required alongside GUT — pick one primary framework (default: GUT, for simplicity) |
| MultiMesh / MultiMeshInstance3D (built-in, no addon) | Godot 4.7 core | GPU-instanced rendering of hundreds of units/projectiles in one draw call | Any visual group where many identical/near-identical meshes are on screen (troops, arrows, enemy waves) — do not spawn hundreds of individual `MeshInstance3D`/`CharacterBody3D` nodes for visuals |
| NavigationServer3D + NavigationAgent3D (built-in) | Godot 4.7 core | Navmesh pathfinding + RVO local avoidance | Unit movement to rally points/targets; enable avoidance only on agents that need it (documented perf cost at scale) — consider a lightweight custom flow-field for large simultaneous waves if RVO avoidance cost becomes a bottleneck at full unit counts (validate via profiling, don't pre-optimize) |
| gdtoolkit (`gdformat`, `gdlint`) | 4.5.0 (PyPI, released 2025-10-09 — still the latest; the `4.*` line targets all Godot 4.x. May lag brand-new 4.6/4.7 GDScript syntax — if the parser rejects valid code, exclude that file rather than rewriting working code) | GDScript formatter + linter | Run in pre-commit/CI to enforce static typing and consistent style across agent-written code |
| godot-ci (abarichello/godot-ci) or gdunit4-action / godot-export (firebelley) | latest tagged | GitHub Actions building blocks for headless export and/or test execution | Use as a starting Dockerfile/workflow reference for the CI pipeline (see below) rather than hand-rolling export template downloads |
| butler | latest (itch.io official) | CLI push of the exported Windows build folder to itch.io | `butler push build/windows <user>/<game>:windows` — push the raw folder, not an installer, per itch.io's own guidance |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Git + Git LFS | Version control; LFS for binary assets | Use Git LFS for `*.glb`, `*.fbx`, `*.png`, `*.wav`, `*.ogg`, `*.import` cache is regenerated locally (do not LFS-track `.godot/` — it's git-ignored entirely). LFS avoids repo bloat from CC0 asset packs and keeps clone times reasonable for a portfolio repo others may browse |
| `.gitignore` (Godot template) | Exclude editor/build cruft | Ignore `.godot/`, `.import/` (pre-4.3 layout), `export.cfg` (if it contains local paths), `*.translation` build artifacts; **do** commit `.godot/editor/` is not needed, `export_presets.cfg` **should** be committed (defines Windows export target) |
| `.gitattributes` | Normalize line endings + mark binary/LFS paths | Force LF for `.gd`/`.tscn`/`.tres`/`.cfg` text files (prevents CRLF diff noise cross-platform); route asset extensions to LFS filters |
| GitHub Actions | CI: headless test run + headless export on push/PR | Job 1: pull Godot 4.7.2 headless binary (via chickensoft-games/setup-godot or barichello/godot-ci Docker image) → run GUT via `--headless -s addons/gut/gut_cmdln.gd -gexit` → fail build on red tests. Job 2 (on tag/release): `--headless --export-release "Windows Desktop" build/windows/game.exe`, then optionally `butler push` if `BUTLER_API_KEY` secret is set |
| gdtoolkit (`gdformat`/`gdlint`) pre-commit hook | Format/lint gate | Run as a pre-commit hook and again in CI so agent-authored code stays statically typed and consistently styled |
| Godot's built-in Project Settings > Autoload/Input Map (edited as text via `project.godot`) | Input remapping, singletons | Since `project.godot` is plain text (INI-like), Claude can add/edit input actions (WASD, mouse-click) and autoload singletons directly without opening the editor |

## Installation

```bash
# 1. Download Godot 4.7.2-stable (standard build, not .NET) for Windows, plus matching export templates
#    https://godotengine.org/download/archive/4.7.2-stable/  (or https://github.com/godotengine/godot/releases)
#    Place godot.exe on PATH or reference by full path in scripts/CI.

# 2. Add GUT as a project addon (clone/download into addons/gut, matching your Godot version)
#    https://github.com/bitwes/Gut  -> place under res://addons/gut/
#    Enable it: Project > Project Settings > Plugins > Gut

# 3. Install gdtoolkit (formatter/linter) for local + CI use
pip install gdtoolkit==4.5.0

# 4. Install butler (itch.io CLI) for local pushes / CI release job
#    https://itch.io/docs/butler/installing.html
#    (download the zip for your platform; no package manager needed)

# 5. Git LFS (once per machine, then once per repo)
git lfs install
git lfs track "*.glb" "*.fbx" "*.png" "*.wav" "*.ogg"
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| Godot 4.7, GDScript | Unity 6 (C#), Unity Test Framework | If the project later needs console/mobile ports, a huge third-party asset-store ecosystem, or the team specifically wants Thronefall-identical production precedent over agent-workflow fit |
| Godot 4.7, GDScript | Unreal Engine 5.8 | If visual fidelity (Lumen/Nanite-grade lighting) becomes a priority over low-poly stylization, or the target hardware bar is raised well above GTX 970 |
| Godot 4.7, GDScript | Bevy 0.17 (Rust) | If the owner is a Rust developer prioritizing raw performance/control and is comfortable building UI/RTS-selection/scene-editing tooling from scratch, and is willing to accept less mature AI-agent tooling |
| Godot 4.7, GDScript | Godot 4.7, C# (.NET build) | If a specific hot system profiles as GDScript-bound and needs near-native speed; move only that system to C#/GDExtension rather than switching the whole project |
| MultiMesh + NavigationAgent3D/RVO | Custom flow-field pathfinding (GDExtension or GDScript) | If profiling at target unit counts (hundreds simultaneously) shows RVO avoidance cost is the bottleneck — flow fields amortize cost across many agents sharing one goal, common in Thronefall-like wave-defense games |
| GUT | gdUnit4 | If you want C# test support alongside GDScript, JUnit XML CI reports, or richer built-in mocking — otherwise GUT's simplicity is preferable for an all-GDScript project |
| JSON/ConfigFile save via `FileAccess` | A dedicated save-plugin addon (e.g. "Godot Save Manager" type addons) | If meta-progression grows complex enough (many unlock trees, versioned save migrations) to justify a schema/versioning layer — not needed for v1's scope (unlocks, XP, high scores) |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| Unreal Engine Blueprints as primary logic | Visual-only, unusable by a no-GUI coding agent; also binary-serialized in `.umap`/`.uasset` | Godot GDScript in plain-text `.tscn`/`.gd` files |
| Unity prefabs/scenes as the primary hand-edit surface for an agent | YAML-ish but large, GUID-linked, easy to corrupt via manual text edits outside the Editor; agent cannot reliably "see" what a prefab looks like without opening the GUI | Godot's `.tscn` scenes, which are small, readable, and safe to hand-edit |
| Bevy for this specific project (despite technical merits) | Pre-1.0 API churn (0.16→0.17 in ~6 months) risks LLM training-data mismatches; no built-in scene format/editor means more scaffolding work before any gameplay exists | Godot 4.7, which ships an editor, scene format, and test framework out of the box |
| Individual `CharacterBody3D`/`MeshInstance3D` per unit for hundreds of units | Physics + per-node overhead does not scale to "hundreds of units + projectiles" at 60 fps on GTX-970-class hardware | `MultiMeshInstance3D` for rendering + lightweight custom movement/state (avoid per-unit physics bodies where visual-only or simple kinematic movement suffices) |
| FBX files imported as-is from Quaternius/KayKit without checking Godot 4.3+ ufbx importer behavior | Pre-4.3 FBX import had known skeleton/animation issues | Prefer GLB where the pack offers it (Kenney does); for FBX-only packs, rely on Godot 4.7's built-in ufbx importer (much improved) or pre-convert to glTF via Blender/`gltf-transform` if issues arise |
| Committing `.godot/` cache directory to git | Regenerated locally, large, machine-specific, causes noisy diffs/merge conflicts | Add to `.gitignore`; only commit `project.godot`, `export_presets.cfg`, source scenes/scripts/resources |
| Unity/Unreal "free tier is free forever" as a legal assumption without re-checking | Terms have changed before (Unity's 2023 runtime-fee controversy) and could change again | Godot's MIT license has no revenue-threshold clause to monitor at all — one less thing to re-verify later |

## Stack Patterns by Variant

**If a specific system (e.g., pathfinding tick for hundreds of agents) profiles as a genuine GDScript bottleneck:**
- Move only that system to a GDExtension written in C++ (or Rust via `gdext`), keeping GDScript as the project's primary language
- Because this avoids a full-project language migration while still getting near-native speed exactly where needed

**If the project later adds a second platform (Steam, Linux, etc., beyond v1's Windows-only scope):**
- Godot's export presets already support this with no engine change — add an export preset, no re-architecture needed
- Because Godot's export pipeline is platform-preset-based, not a per-platform rewrite

**If GUT's assertion/mocking features prove too limited as test coverage grows:**
- Add gdUnit4 alongside it for specific suites (both can coexist), or migrate fully
- Because gdUnit4 offers richer scene-testing and mocking utilities at the cost of slightly more setup

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| Godot 4.7.2-stable | GUT 9.7.1 | GUT 9.7.0 introduced Godot 4.7 compatibility (breaking change to double return-type handling); 9.6.x targets 4.6 — do not mix |
| Godot 4.7.2-stable | gdUnit4 v6.2.x | Release notes confirm 4.5/4.6 support only — verify 4.7 before relying on it (GUT is the primary framework anyway) |
| Godot 4.7.2-stable | gdtoolkit 4.5.0 | Latest gdtoolkit; `4.*` line covers Godot 4.x, but may lag newest syntax additions |
| Godot 4.7.2-stable | glTF2 importer (built-in) | No version pin needed; ships with the engine |
| Godot 4.7.2-stable | ufbx-based FBX importer (built-in, since 4.3) | No version pin needed; ships with the engine — confirm no regressions before committing to FBX-heavy packs, prefer GLB where available |
| butler (itch.io) | Any exported Windows build folder | No version coupling to Godot; butler pushes a folder/zip regardless of what produced it |

## Sources

- https://godotengine.org/blog/release/ — official release blog: 4.6 (2026-01-26), 4.6.3 (2026-05-20), 4.7 (2026-06-18), 4.7.1 (2026-07-14), 4.7.2 (2026-08-18, latest stable as of 2026-09-28) (HIGH — verified by orchestrator)
- https://github.com/bitwes/Gut/releases — GUT 9.7.0 "Godot 4.7 compatibility", 9.7.1 bugfix (HIGH — verified by orchestrator)
- https://github.com/godot-gdunit-labs/gdUnit4/releases — gdUnit4 v6.x release notes (4.5+/4.6 support) (HIGH — verified by orchestrator)
- https://unity.com/releases/unity-6/support — Unity 6.3 LTS current as of Sept 18, 2026; Unity 6.0 LTS supported through Oct 2026 (HIGH)
- https://unity.com/products/pricing-updates — Unity Personal free, no runtime fee for projects made with Unity 6 or earlier, subject to Tier Eligibility (HIGH)
- Unreal Engine royalty terms (roadtovr.com, seeles.ai, tech-insider.org 2026 coverage) — free below $1M lifetime revenue, 5% above (3.5% with EGS day-and-date) (MEDIUM — multiple consistent secondary sources, not fetched directly from unrealengine.com EULA text)
- https://bevy.org/news/bevy-0-17/ — Bevy 0.17 released ~Oct 2025, confirms active but fast-churning API (HIGH)
- https://github.com/godot-gdunit-labs/gdUnit4 and gdUnit4 CI workflow discussion — headless CI support (HIGH)
- https://gut.readthedocs.io/ — GUT version-to-Godot-version mapping (HIGH)
- Godot docs — "Optimization using MultiMeshes" (docs.godotengine.org) — MultiMesh GPU instancing guidance for hundreds/thousands of instances (HIGH)
- Godot docs — "Using NavigationAgents" (docs.godotengine.org, stable + latest) — RVO avoidance behavior and performance cost note (HIGH)
- https://godotengine.org/article/introducing-the-improved-ufbx-importer-in-godot-4-3/ — FBX import overhaul since 4.3 (HIGH)
- Kenney knowledge base (kenney.nl) — Kenney ships GLB by default; Quaternius/KayKit often need FBX→GLB conversion (MEDIUM)
- https://itch.io/docs/butler/pushing.html and itch.io Windows builds docs — push the raw build folder, not an installer (HIGH)
- Summer Engine / Ziva 2026 blog coverage on GDScript vs C# and Claude's Godot 4 code quality (MEDIUM — third-party blog commentary, directionally consistent across multiple 2026 sources, not an official Godot/Anthropic statement)
- https://pypi.org/project/gdtoolkit/ — gdtoolkit 4.5.0 (2025-10-09) is still the latest release; `gdtoolkit==4.*` for Godot 4 projects (HIGH — verified by orchestrator)
- https://github.com/abarichello/godot-ci, https://github.com/chickensoft-games/setup-godot, https://github.com/firebelley/godot-export — GitHub Actions building blocks for headless export/test in CI (MEDIUM — active repos, exact latest tags not individually verified)

---
*Stack research for: Thronefall-like game (Duskhold), engine/toolchain selection*
*Researched: 2026-09-28*
