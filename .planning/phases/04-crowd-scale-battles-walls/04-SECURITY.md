---
phase: "4"
slug: "crowd-scale-battles-walls"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-16"
---

# Phase 4 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Built from the `<threat_model>` blocks of plans 04-01 to 04-11 and the SUMMARY threat flags (all eleven report "None" beyond the planned surface). Verified at ASVS level 1 (grep depth) by the execute-phase orchestrator on 2026-10-16 at commit 235f7e1; with `threats_open: 0` and a plan-time register at level 1, the workflow's short-circuit rule applied and no auditor subagent was spawned. Paths are relative to the repository root.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Simulation -> presentation | Views read enemy, unit and arrow positions, ids and events every frame into MultiMesh batches; a write back would break replay identity | Positions, ids, attack and death events (read-only) |
| Simulation queries -> replay identity | A spatial query that answers differently from the shipped scan changes every later outcome | Nearest-structure and nearest-enemy answers, push-apart displacements |
| Map data (.tres) -> MapConfig.validate and the wall simulation | Untrusted geometry, tier data and run polylines drive allocations and per-tick loops | Wall runs, lengths, gaps, costs, tiers |
| Map data -> nav grid allocation | Content bounds and cell size size the grid and every flow field | Grid extents, cell counts |
| Data (health, damage, tunables) -> integer decision arithmetic | Large or malformed numbers could overflow or divide by zero in WallDecision | Health, damage per 10 s, ticks |
| CLI arguments -> stress tools (step bench, gate harness, stress night, frame report) | Untrusted strings size runs and choose output folders | Integers, output directories under res://build |
| Golden files -> CI verdicts | A regenerated golden can hide a regression | smoke, army, walls digests; full_idle unpinned by design |
| Local repo -> GitHub and CI runners | Pushed code runs in CI with the workflow's permissions | Source, workflow YAML, artifacts |
| Project -> Windows export | Tools, tests and the GUT addon must not ship | Export filter |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-04-01 | Denial of Service | CrowdBatch and EnemyViews instance writes | low | mitigate | `MAX_VIEWS: int = 512` and `_drawn_ids.resize(MAX_VIEWS)` in `presentation/enemies/enemy_views.gd`; `DeathPuffBatch.MAX_PUFFS` 128; `add()` past capacity returns false (04-01 SUMMARY); pinned by `tests/unit/test_crowd_batch.gd` | closed |
| T-04-02 | Tampering | presentation/ reading the simulation | medium | mitigate | Views use read accessors and SimEvents only; `tests/unit/test_sim_rules_guard.gd` scans `MATH_ROOTS`; smoke `2599c7c2` and army `f7a967ed` byte-identical for the whole phase, walls `bfb05fc7` new, full_idle moved only in the one D-14 commit `94fff12` | closed |
| T-04-03 | Denial of Service | ProjectileVfx arrow ring | low | mitigate | `MAX_PROJECTILES: int = 512` and `MAX_SLASHES: int = 8` in `presentation/vfx/projectile_vfx.gd`; the flood test in `tests/unit/test_projectile_vfx.gd` holds the cap | closed |
| T-04-04 | Elevation of Privilege | push to origin and CI (04-02) | low | mitigate | `.github/workflows/ci.yml:17-18` `permissions: contents: read`; every `uses:` pinned to a 40-hex SHA (18 lines, 0 unpinned); no `secrets.` reference; `tools/prepush_check.sh` ran before the 04-02 push; CI run 38848480353 green | closed |
| T-04-05 | Tampering | StructureIndex, EnemyIndex, displacements_bucketed | medium | mitigate | `tests/unit/test_spatial_index.gd` keeps the shipped `_pick_nearest_structure` verbatim as the reference and compares on seeded worlds with ties; `test_separation_grid.gd` likewise; the three replays stayed byte-identical through 04-03 | closed |
| T-04-06 | Denial of Service | grid allocation | low | mitigate | `simulation/night/enemy_index.gd:19` `var _cells: Dictionary = {}`, cleared and keyed only for occupied cells (`if not _cells.has(key)`); `structure_index.gd` the same shape | closed |
| T-04-07 | Tampering | tools/stress/step_bench.gd arguments | low | mitigate | Usage header: bounded integer flags only, `STEP_BENCH_USAGE` and exit 64 on anything else, no path argument; `export_presets.cfg` `exclude_filter` carries `tools/*`; pinned by `tests/unit/test_stress_tool_args.gd` | closed |
| T-04-08 | Denial of Service | WallRunDef.expand | medium | mitigate | `simulation/walls/wall_run_def.gd:9` `MAX_SEGMENTS_PER_RUN: int = 200`; non-finite or non-positive input expands to nothing; `WallValidation.errors` names the cases (04-05); pinned by `tests/unit/test_wall_system.gd` and `test_map_wall_validation.gd` | closed |
| T-04-09 | Tampering | simulation/walls and simulation/nav determinism | medium | mitigate | `tests/unit/test_sim_rules_guard.gd:15-16` lists `res://simulation/walls` and `res://simulation/nav` in `MATH_ROOTS`; integer-centimetre geometry; `test_wall_determinism` double run; the recorder writes integers and names | closed |
| T-04-10 | Denial of Service | push-out and blocking tests per tick | low | mitigate | Static bucket grid in `simulation/walls/wall_solids.gd` and `wall_system.gd` (bucket edge is a performance parameter, never data); with no intact segment the pass is skipped; pinned by `tests/unit/test_wall_blocking.gd` | closed |
| T-04-11 | Tampering | WallValidation.errors | medium | mitigate | `simulation/walls/wall_validation.gd:42` `static func errors(map: MapConfig) -> PackedStringArray` reports non-finite numbers, short polylines, bad lengths and thicknesses, gaps under 3 m, more than 200 segments per run or 1000 per map, wall plots on non-wall buildings; `tests/unit/test_map_wall_validation.gd` covers each case | closed |
| T-04-12 | Repudiation | wall model provenance | low | mitigate | Only logged Castle Kit files and code-built primitives; `tests/unit/test_attribution_log.gd` runs in the suite and fails on an unowned file | closed |
| T-04-13 | Denial of Service | NavGrid allocation | medium | mitigate | `simulation/nav/nav_grid.gd:23` `MAX_NAV_CELLS: int = 40000`; bounds come from content plus a margin; above the cap nothing is allocated and the map runs on straight steps; `validate()` names the count; pinned by `tests/unit/test_nav_grid.gd` | closed |
| T-04-14 | Denial of Service | field rebuild storms | low | mitigate | `simulation/nav/pathing.gd` rebuilds in `refresh()` at most once per step on a `_field_version` change; `tests/integration/test_wall_detour.gd` pins one rebuild for two breaks in a tick; 04-09 measured the rebuild at 11.74 ms mean | closed |
| T-04-15 | Denial of Service | GoalFieldCache | low | mitigate | `simulation/defs/nav_tuning.gd` `field_cache_size` (8, validated 1 to 32) and `field_builds_per_tick` (1, validated 1 to 4); past the budget the straight step is used; pinned by `tests/unit/test_goal_field_cache.gd` and `test_nav_tuning_contract.gd` | closed |
| T-04-16 | Tampering | simulation/nav determinism | medium | mitigate | `test_sim_rules_guard.gd` scans NavigationServer, Engine, OS, Time and transcendentals (`cos`, `sin`, ...) over `MATH_ROOTS` including `simulation/nav`; integer costs; the cache keeps insertion order; replays byte-identical | closed |
| T-04-17 | Tampering | WallDecision arithmetic | medium | mitigate | `simulation/nav/wall_decision.gd` fills with `SimClock.MAX_TICKS`, returns it for a zero sum or non-positive speed (line 61) and clamps before comparison; `tests/unit/test_wall_decision.gd:173-174` pins `ttd_ticks(1000000, 1000 attackers) == 15000` exactly in 64-bit integers | closed |
| T-04-18 | Denial of Service | per-tick decision pass | low | mitigate | One pass over enemies with a wall aggro per tick on the `(tick + segment) % decision_ticks` cadence, touching only due segments within `wall_neighbour_span` (`nav_tuning.gd:33`, default 2, validated at most 10) | closed |
| T-04-19 | Repudiation | StuckTracker | low | mitigate | `simulation/nav/stuck_tracker.gd` emits no SimEvents signal and writes no record field; `tests/unit/test_stuck_tracker.gd` and `test_debug_overlay_readonly.gd` guard it; goldens unchanged through 04-07 | closed |
| T-04-20 | Tampering | tools/stress/gate_stress_cli.gd arguments | medium | mitigate | Four allowlisted flags, `--max-seconds=<10..300>`, `--out` through `ReplayCli.safe_dir`, `EXIT_USAGE: int = 64`, no map or data path; pinned by `tests/unit/test_stress_tool_args.gd` | closed |
| T-04-21 | Denial of Service | the CI gate step | low | mitigate | The run stops at `SimClock.ticks(max_seconds)` (default 60 s of simulation); `tools/gate_stress.sh:28` `TIMEOUT_S="${GATE_TIMEOUT_S:-600}"` bounds the process; CI step `Gate stress (ENMY-04)` ran in run 38959046206 | closed |
| T-04-22 | Information Disclosure | stress tools in the export | low | mitigate | `export_presets.cfg:11` `exclude_filter="tests/*, addons/gut/*, tools/*"`; the overlay sections ship like the existing debug overlay (T-01-15 accepted) | closed |
| T-04-23 | Elevation of Privilege | .github/workflows/ci.yml (04-08) | low | mitigate | Only the `Gate stress (ENMY-04)` step (line 83) and `build/stress/` artifact path (line 93) added; `permissions: contents: read` kept; every `uses:` still SHA-pinned; YAML parsed before commit | closed |
| T-04-24 | Tampering | StressNight, FrameReportCli and StepBench arguments | medium | mitigate | Bounded integers (`--rebuilds=<0..64>`), folders through `ReplayCli.safe_dir`, exit 64 on usage errors, exit 2 headless by design (`tools/stress/stress_night.gd:16`); `tools/*` export-excluded; pinned by `tests/unit/test_stress_tool_args.gd` (20 tests) | closed |
| T-04-25 | Repudiation | 04-FRAME-REPORT.md | low | mitigate | Three runs, median by p95, vsync off, 1.0x, GPU, driver, Godot version, renderer and actual window size recorded; the report's p95 37.04 ms equals the tool's `FRAME_REPORT_OK ... p95_ms=37.04` line (`frame_report_cli.gd:5`); the verdict is honest: NOT met | closed |
| T-04-26 | Tampering | tests/golden and the balance pins | medium | mitigate | `tests/golden/walls.json` is new on a frozen fixture; smoke and army byte-identical; the single regeneration is commit `94fff12` whose message names D-14 and D-15, with 04-BALANCE-REPORT.md giving before and after (full_idle `f417c7f5...` 6941 ticks to `4385f569...` 6911 ticks) | closed |
| T-04-27 | Elevation of Privilege | .github/workflows/ci.yml (04-10) | low | mitigate | One line added to the existing replay step (`ci.yml:79` `--scenario=walls --twice --expect-file=tests/golden/walls.json`); permissions, secrets and pins unchanged | closed |
| T-04-28 | Elevation of Privilege | push and .github/workflows/ci.yml (04-11) | low | mitigate | `tools/prepush_check.sh` passed before the one push `3c8f69e..a8c57ab` with the gh credential-helper command; `ci.yml` untouched in 04-11; CI run 38959046206 green on lint, test, export and screenshots | closed |
| T-04-29 | Information Disclosure | the Windows export | low | mitigate | `export_presets.cfg:11` excludes `tests/*, addons/gut/*, tools/*`; the launch check `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exited 0 on the exported build (109,268,480 bytes) | closed |
| T-04-SC | Tampering | package installs (every plan) | low | accept | No npm, pip or cargo installs and no new downloaded asset in any of the eleven plans; the unit meshes and wall pieces come from already-logged Kenney and Castle Kit files or code-built primitives; the YAML checks use the already-installed tools venv (AR-04-01) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Unregistered Flags

None. Every SUMMARY's `## Threat Flags` section reports "None" beyond the planned surface. Two execution facts touch the register without opening a threat: the 04-09 stop-rule halt (PLAT-01 not met) is a performance outcome recorded in 04-FRAME-REPORT.md and 04-PLAYTEST-GATE.md, not a security gap; and the 04-07 give-up memory (`Record.wall_given_up`) is a simulation rule flagged for the owner, covered by T-04-19's read-only guard and the unchanged goldens.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-04-01 | T-04-SC | No package manager installs in the phase; no new asset was downloaded (unit meshes from the already-logged Kenney GLBs, wall pieces from the logged Castle Kit and code-built primitives); the YAML parse uses the existing tools venv | Planner (every plan's threat model), confirmed by the orchestrator at verification | 2026-10-16 |
| AR-04-02 | T-04-22 | The Walls, Field and Crowd debug overlay sections ship in the export like the existing F3 overlay (T-01-15 accepted in Phase 1); they are read-only views of the simulation and show no data a player could not infer | Planner (04-08 threat model), confirmed by the orchestrator at verification | 2026-10-16 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-16 | 30 (T-04-01 to T-04-29 plus the per-plan T-04-SC row) | 30 | 0 | execute-phase orchestrator (ASVS L1 grep verification, short-circuit rule; HEAD 235f7e1; CI run 38959046206 green on a8c57ab) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-16 (secure-phase, state B, ASVS L1 short-circuit; no auditor spawn needed)
