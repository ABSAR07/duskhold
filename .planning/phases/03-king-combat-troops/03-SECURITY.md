---
phase: "3"
slug: "king-combat-troops"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-12"
---

# Phase 3 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Built from the `<threat_model>` blocks of plans 03-01 to 03-12 and the SUMMARY threat flags (all twelve report "None" beyond the planned surface). Verified at ASVS level 1 (grep depth) by the execute-phase orchestrator on 2026-10-12 at commit 80badde; with `threats_open: 0` and a plan-time register at level 1, the workflow's short-circuit rule applied and no auditor subagent was spawned. Paths are relative to the repository root.

---

## Trust Boundaries

Phase 3 adds no network, account or save-file surface. The boundaries it touches:

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Third-party asset packs → repository | Two CC0 zips (Kenney Mini Characters in 03-01, Kenney Input Prompts in 03-10) fetched by the executors | Archive bytes (integrity: sha256 and size checked against the logged values before extraction; only named files copied; archives never committed) |
| Authored `.tres` data → simulation | Unit, military-building, weapon, king and night data are first-party but hand-edited | Game data (integrity and run length: validated by `MapConfig._validate_squads`, `WeaponDef.is_slam_armed`, regeneration guards) |
| Player input (keyboard, mouse, pad) → command gate → simulation | Squad orders, point orders, control groups, the slam and the pad cursor all enter through `CommandProcessor` intents | Squad ids, verbs, integer-centimetre points (bounded by the gate's reasons; the simulation never reads `Input`) |
| Presentation and debug tooling → simulation | Strip, slots, overlay sections, rings, markers, prompts and the device tracker must only read | Read-only game state |
| Command line → replay and playtest CLIs | `tools/replay.sh` and `tools/playtest.sh` select scenarios and strategies by allow-listed name | Scenario and strategy names, seeds (no path arguments) |
| Working tree → git index → public GitHub → CI runner | Three pushes in this phase; the repo ABSAR07/duskhold is public; CI runs with a read-only token and no secrets | Source, history, generated artifacts |
| Exported Windows build → owner's machine | Unsigned local export for the playtest gate | Executable (no code-signing budget; Phase 13 concern) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-03-01 | Denial of Service | SquadSystem spawn path | medium | mitigate | `MAX_UNITS_PER_SQUAD` guard constant caps spawns per squad regardless of data (`simulation/squads/squad_system.gd`); `_validate_squads()` rejects an oversized `squad_size` (03-02); pinned by `tests/unit/test_squad_guard.gd` and `tests/unit/test_map_validate_squads.gd` | closed |
| T-03-02 | Tampering | simulation/squads determinism | medium | mitigate | `res://simulation/squads` is in the no-RNG/clock/OS source scan of `tests/unit/test_sim_rules_guard.gd`; `tests/integration/test_squad_determinism.gd` proves two in-process runs give identical digests and seeds 1 and 2 differ; smoke golden byte-identical through the phase | closed |
| T-03-03 | Tampering | Mini Characters zip download | medium | mitigate | Hash `9e1d48e6...` compared with the logged value before extraction in scratch; only `character-male-a.glb` and `character-female-a.glb` copied (LFS); logged in `assets/attribution.json` and `ASSETS.md`; archive never committed (03-01 SUMMARY) | closed |
| T-03-04 | Tampering | MapConfig unit and squad fields | medium | mitigate | `MapConfig._validate_squads()` reports non-finite, non-positive and unresolved values so a corrupted file cannot arm a squad silently; each rule pinned by `tests/unit/test_map_validate_squads.gd` | closed |
| T-03-05 | Denial of Service | Trickle countdown and squad allocation | medium | mitigate | `squad_respawn_seconds` and `attack_interval` bounded to [SimClock.STEP, 3600], `squad_size` to 1..MAX_UNITS_PER_SQUAD in `_validate_squads()`; `SimClock.ticks` saturates at MAX_TICKS (Phase 2 fix); pinned by `test_map_validate_squads.gd` and `test_squad_respawn.gd` | closed |
| T-03-06 | Denial of Service | HudRoot and new full-rect controls | low | mitigate | HudRoot, DayCounter, KingWidget, SquadStrip, Toast, CommandHints and DragBox are `mouse_filter` IGNORE or sized away from the play area; `tests/e2e/test_hud_contract.gd` pins the filter and the protected centre; `ShotRunner.protected_violations` re-checks every HUD screenshot (03-12) | closed |
| T-03-07 | Tampering | ActivateAbilityIntent | low | mitigate | `CommandProcessor` returns RUN_OVER, NO_ABILITY, KING_DOWN or ABILITY_COOLING before any state changes; spammed presses change nothing; each reason pinned by `tests/unit/test_king_slam.gd` | closed |
| T-03-08 | Denial of Service | WeaponDef slam and KingDef regeneration numbers | medium | mitigate | `WeaponDef.is_slam_armed()` refuses non-finite, non-positive, sub-step or over-an-hour values; `KingState` treats a non-finite or negative regeneration fraction as off (`is_finite` guard); pinned by `test_weapon_def.gd` and `test_king_regen.gd` | closed |
| T-03-09 | Tampering | SquadStrip, SquadSlot, Squads overlay section | low | mitigate | Widgets call read getters only; `tests/unit/test_debug_overlay_squad_section.gd` watches every `SimSignals.ALL` signal plus tick, gold and squad state across 100 reads; the Phase 2 read-only drift guard covers new signals | closed |
| T-03-10 | Tampering | SquadOrderIntent handling | medium | mitigate | The gate rejects empty lists, unknown squad ids and verbs outside `SquadOrders.is_supported` as returned reasons before any state changes; pinned by `tests/unit/test_squad_order_intent.gd` | closed |
| T-03-11 | Repudiation | Player orders in replays | low | mitigate | Every accepted order emits `squad_ordered` with its resolved points; the signal is in `SimSignals.ALL` and `SimRecorder.HANDLED`, so a run's digest captures each command; the army golden (`tests/golden/army.json`) records them | closed |
| T-03-12 | Denial of Service | Order queue and patrol paths | medium | mitigate | `MAX_QUEUE` 9 and `MAX_PATROL_POINTS` 8 in `simulation/squads/squad_orders.gd`; `BAD_POINT`, `TOO_MANY_POINTS` and `QUEUE_CLOSED` reasons in `simulation/commands/command_processor.gd:19-21,136,162`; points are integer centimetres bounded by `ground_half_extent`, itself bounded by `MAX_GROUND_HALF_EXTENT` (03-07 deviation); pinned by `test_squad_queue.gd`, `test_squad_patrol.gd`, `test_squad_point_validation.gd` | closed |
| T-03-13 | Tampering | simulation/ determinism boundary | medium | mitigate | `tests/unit/test_sim_rules_guard.gd` fails on `Input.`, `InputEvent`, `Camera3D`, `Viewport` or `DisplayServer` under `res://simulation`; orchestrator grep of `simulation/` for those names: 0 hits; points cross only as `Vector2i` in `SquadOrderIntent` | closed |
| T-03-14 | Denial of Service | Box select and marker drawing | low | accept | Work is bounded by the living unit count (two squads of at most 14 units in Phase 3); `MAX_DISCS_SHOWN` 6 and `MAX_PINGS` 16 in `presentation/units/order_markers.gd`; `SquadPlanView` rebuilds only on change; Phase 4 revisits scale (AR-03-01) | closed |
| T-03-15 | Tampering | Pad cursor points | low | mitigate | `GroundCursor.clamp_to()` keeps the cursor `SpawnTelegraph.EDGE_MARGIN_PX` (48 px) inside the visible rect; `PadCursorController` passes the point through `GroundPick.to_centimetres` and `GroundPick.in_bounds` (`input/pad_cursor_controller.gd:125-126`) and the gate's BAD_POINT check; pinned by `test_ground_cursor.gd` and `test_pad_cursor.gd` | closed |
| T-03-16 | Tampering | Kenney Input Prompts download | medium | mitigate | Size and sha256 `ac2fcf59...` checked before extraction with `python -I` into an empty scratch directory; only the licence and the 74 named PNGs copied, no `.url` files (orchestrator check: none under `assets/third_party/kenney_input_prompts`); hash recorded in `assets/attribution.json`; `tests/unit/test_attribution_log.gd` pins the entry | closed |
| T-03-17 | Denial of Service | LastDeviceTracker switching | low | mitigate | One switch per 0.25 s, axis threshold 0.5 above the 0.2 deadzone, 8 px motion threshold in `input/device_model.gd`; each boundary pinned by `tests/unit/test_device_model.gd` (mutation probe on the threshold failed the test, 03-10 SUMMARY) | closed |
| T-03-18 | Tampering | replay CLI scenario selection | low | mitigate | `army` joined `ReplayScenarios.NAMES`; `tools/replay/replay_cli.gd:107` rejects any name outside the list with usage exit 64; no path argument added; pinned by `tests/unit/test_replay_cli_args.gd` and the plan's verify command | closed |
| T-03-19 | Denial of Service | army scenario and balance runs | low | mitigate | Every run is bounded by `ARMY_MAX_TICKS` (8000) or `BalanceReport.MAX_TICKS`; the playtest seed cap of 50 is unchanged; pinned by `test_army_replay_golden.gd` and `test_balance_report.gd` | closed |
| T-03-20 | Elevation of Privilege | .github/workflows/ci.yml | low | mitigate | Only the screenshots job timeout and the army replay step changed; `permissions: contents: read` (line 17-18), no `secrets.` reference, every `uses:` pinned to a full commit SHA with a version comment; `tools/prepush_check.sh` passed before each of the three pushes; CI run 38219154906 green | closed |
| T-03-21 | Spoofing | Exported Windows build | low | accept | Unsigned local build for the owner's playtest (no code-signing budget, project constraint); `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exits 0 in 3 s (03-12 SUMMARY); SmartScreen behaviour is a Phase 13 concern (AR-03-02) | closed |
| T-03-SC | Tampering | package installs (one row per plan, 03-01 to 03-12) | low | accept | No npm, pip or cargo installs anywhere in the phase (RESEARCH Package Legitimacy Audit: none); the only third-party items are the two hash-checked CC0 asset packs above (AR-03-03) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Unregistered Flags

None. All twelve SUMMARY `## Threat Flags` sections read "None" and describe only the planned surface. Two deviations touched trust-adjacent code and are covered by existing rows: 03-07's `MAX_GROUND_HALF_EXTENT` bound (T-03-12) and 03-12's CI timeout change (T-03-20).

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-03-01 | T-03-14 | Marker and box-select work is bounded by the Phase 3 unit count and hard caps; the data-oriented scale-up is Phase 4's goal (ROADMAP) | Planner (03-08 threat model), confirmed by the orchestrator at verification | 2026-10-12 |
| AR-03-02 | T-03-21 | The project has no code-signing budget (PROJECT.md constraint); the owner's playtest build is launched locally; SmartScreen/AV behaviour is tracked under Phase 13 in STATE.md Blockers | Planner (03-12 threat model), owner constraint | 2026-10-12 |
| AR-03-03 | T-03-SC | No package manager installs in the phase; the only third-party inputs are CC0 asset packs verified by sha256 before extraction | Planner (every plan's threat model) | 2026-10-12 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-12 | 22 (T-03-01 to T-03-21 plus the per-plan T-03-SC row) | 22 | 0 | execute-phase orchestrator (ASVS L1 grep verification, short-circuit rule; commit 80badde) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-12
