# Walking Skeleton — Duskhold

**Phase:** 1
**Generated:** 2026-09-29

## Capability Proven End-to-End

The game boots into the prototype map. The player rides the king to a House plot and holds the action key. Coins drip into the plot, and the House is built through the validated command path (`BuildIntent` → `CommandProcessor` → `Economy` + `BuildingSystem` → `SimEvents` → building view + HUD gold). The same path is proven by a headless GUT end-to-end test. CI publishes a Windows export artifact on every push.

Translation of the web-app skeleton checklist for a game:

| Web skeleton item | Duskhold equivalent |
|---|---|
| Routing | `project.godot` `run/main_scene` boots `res://presentation/map/prototype_map.tscn` |
| One real DB read | `MapConfig` / `BuildingDef` `.tres` resources loaded from `res://data/` |
| One real DB write | A completed hold mutates `Economy.gold` and creates a `BuildingInstance` via `CommandProcessor.submit(BuildIntent)` |
| One real UI interaction | Keyboard/gamepad `action_build` hold at a spot → building appears, HUD gold drops |
| Dev deployment | `bash tools/test.sh` (headless GUT) locally + GitHub Actions `export` job artifact `duskhold-windows` |

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Engine / language | Godot 4.7.2-stable (standard build), GDScript with static typing enforced by `debug/gdscript/warnings/untyped_declaration=2` (error) | Locked stack. The engine setting makes an untyped declaration a compile error, so typing is enforced by the engine itself, not only by lint. |
| Toolchain pinning | `tools/bootstrap.py` (Python 3) downloads Godot, export templates, GUT and gdtoolkit. It verifies SHA512 against the official `SHA512-SUMS.txt` and the committed pin `tools/godot_sha512sums.txt`. Godot is installed under git-ignored `.tools/godot/<version>/` with a `_sc_` self-contained marker, so editor data and templates live in `editor_data/` next to the binary. | D-14/D-15. One version pin (`tools/godot_version.txt`) is shared by local and CI. Nothing is written to the user's AppData. Downloads need an explicit `--yes`. |
| Script wrappers | `tools/godot.sh`, `tools/test.sh`, `tools/lint.sh`, `tools/export.sh`, `tools/screenshot.sh`: bash, targeting Git Bash on Windows and bash on Linux CI. All paths are quoted (the repo path contains a space). Paths passed to Godot are converted with `cygpath -m` on Windows. | One command surface for the agent, the owner and CI. On Windows the `_console.exe` build is used so output and exit codes reach the terminal. |
| Data layer | Content definitions are `Resource` scripts in `simulation/defs/` (`BuildingDef`, `BuildingTierDef`, `BuildSpotDef`, `MapConfig`, `LoopTuning`, `KingDef`). Instances are `.tres` files under `data/`. A spot names its single building type by `building_id` (D-02); `MapConfig.buildings` holds the map's building set. | Locked architecture Pattern 2. Text `.tres` files are diffable and agent-editable. All tunable numbers live in data (D-09). |
| Simulation | Plain `RefCounted` classes with no scene-tree or rendering dependency: `Economy`, `BuildingSystem`, `BuildingInstance`, `RunManager` (sole owner of `RunPhase`), `CommandProcessor`, composed by `RunContext`. Time advances only through `RunManager.tick(delta)`. | Locked Anti-Pattern 1/4 guidance. Tests construct `RunContext` directly with no scene tree. The explicit tick is the groundwork for Phase 2 determinism (DEV-05). |
| Event bus | A per-run `SimEvents` (`RefCounted` with typed signals) owned by `RunContext`, not a global autoload | Satisfies the locked "event bus for cross-cutting notifications" while keeping each headless test's bus isolated. Presentation subscribes through `bind_run`. |
| Command/intent layer | `BuildIntent`, `StartNightIntent` → `CommandProcessor.submit(intent) -> StringName` (`&"ok"` or a rejection reason). The same checks are exposed read-only as `validate_build(spot_id)`. | Locked Pattern 7. Validation lives in one place and runs again when the intent is applied (Pitfall 4). |
| Input | All gameplay actions are in the `project.godot` Input Map with keyboard and gamepad events. Hold logic lives in input-layer nodes (`BuildHoldController`, `StartNightHoldController`) that keep only ephemeral hold state. The mouse is never bound for gameplay. | Locked controls scheme. D-06: no partial payment state ever reaches the simulation. |
| Presentation composition | `MapRoot` (root of `prototype_map.tscn`) builds the `RunContext` from exported `.tres` references. It then calls `bind_run(ctx, map_root)` on every node in group `run_bound`, and drives `RunManager.tick` from `_process`. | Later plans add nodes to the scene and the group without editing `map_root.gd`, so there are fewer file conflicts between plans. |
| Tests | GUT 9.7.1, vendored at `addons/gut/`. `tests/unit/` and `tests/integration/` hold simulation tests (no scene tree); `tests/e2e/` holds headless scene tests driven by `Input.action_press`. Fixtures live in `tests/fixtures/`. JUnit XML goes to `build/test-results/gut-junit.xml`. | DEV-01. The e2e tests drive the real scene through the real input path without a GPU. |
| Screenshots | `tools/screenshot/shot_runner.tscn` runs scripted scenarios through the real input path, then checks that each PNG is not blank before saving it. It never runs under `--headless`. CI uses `xvfb-run` with `--rendering-method gl_compatibility --rendering-driver opengl3`. | DEV-04. Research Pitfall 1: `--headless` produces blank images without erroring. |
| CI / deployment | GitHub Actions on `ubuntu-latest` with jobs `lint`, `test`, `export` (needs lint+test) and `screenshots`. Settings: `permissions: contents: read`, LFS objects cached, the Godot install cached by version+checksum hash. The Windows export preset has `application/modify_resources=false`, so no Wine or rcedit is needed. Artifacts are `duskhold-windows` and `duskhold-screenshots`. | D-13/D-15/D-16. The public repo `ABSAR07/<approved-name>` is created only after a blocking human decision. |
| Directory layout | `data/`, `simulation/{defs,economy,buildings,run,commands,events}/`, `input/`, `presentation/{map,king,camera,buildings,vfx,environment}/`, `ui/{hud,world,overlay}/`, `tests/{unit,integration,e2e,fixtures}/`, `tools/`, `assets/third_party/<pack>/`, `addons/gut/`. Generated output goes to `build/` and `screenshots/`, which are git-ignored except for a tracked `.gdignore`. | Follows ARCHITECTURE.md's recommended structure. The `.gdignore` keeps generated files out of Godot's import scan. |
| Naming | snake_case file names, PascalCase `class_name`, typed signals. Newer GDScript syntax that gdtoolkit 4.5.0 may not parse (`@abstract`, variadic parameters) is not used. | Follows the Godot style guide and avoids case-sensitivity problems on the Linux CI runner. |
| Asset licensing | CC0 or MIT only. Every third-party file is covered by an entry in `assets/attribution.json` (machine-readable, reused by the Phase 13 credits screen) and in `ASSETS.md` (human-readable). A GUT test enforces this coverage. | ART-02, PITFALLS Integration Gotchas. |

## Stack Touched in Phase 1

- [ ] Project scaffold: `project.godot`, the pinned toolchain, GUT, gdtoolkit lint, and the export preset (plans 01-01, 01-03)
- [ ] Routing: the main scene boots the prototype map (plan 01-02)
- [ ] Data: `.tres` reads (map, buildings, tuning) and a write through the command path (plan 01-02)
- [ ] UI: the hold-to-build interaction updates the building view and the HUD gold (plan 01-02)
- [ ] Deployment: headless GUT locally and in CI, plus the CI Windows export artifact (plans 01-02, 01-03)

## Out of Scope (Deferred to Later Slices)

- Enemies, combat, building health/destruction, king HP/respawn, spawn telegraphing, win/loss, the results screen, seeded replays (Phase 2)
- The top-level Boot → Menu → Run → Results state machine. Phase 1 boots straight into the run. The in-run `RunPhase` state machine is built now, and Phase 2 adds the results state.
- Branching upgrade cards, castle tiers, and other economic buildings (Phase 5)
- Unit squads, hotkeys, device-specific prompts (Phase 3); rebinding UI (Phase 13)
- The art normalization pass and SFX (Phase 8). Phase 1 leaves the denied cue silent and exposes the `hold_denied` signal as the hook.
- Save files and persistence (Phase 9)

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without changing its architectural decisions:

- Phase 2: real nights fill the existing `RunPhase.NIGHT` (the timer condition is replaced by "all enemies dead"), buildings gain health, the dawn rebuild runs, win/loss and results are added, and seeded replays run through `RunManager.tick` and `CommandProcessor.submit`
- Phase 3: King combat, Barracks/Archery Range squads, unit hotkeys added to the same Input Map, full HUD
- Phase 4: Data-oriented crowd simulation (MultiMesh, flow fields), walls, and the 60 fps stress test
- Phase 5: Castle center tiers, branching upgrade cards on `BuildingDef`, the stat-modifier order, and four new income curves
- Phase 6: The enemy roster and tower specializations
- Phase 7: Unit and hero variety with counter roles
- Phase 8: The cohesive art pass, readability, and SFX (connected to the existing event and hook signals)
- Phase 9: Campaign maps 1–2 (new `MapConfig`s with `is_sandbox=false`), scoring, retry, and versioned saves
- Phase 10: Loadout and meta-progression
- Phase 11: Maps 3–5 and boss nights
- Phase 12: Research buildings
- Phase 13: Settings, rebinding, credits (read from `assets/attribution.json`), and the itch.io release
