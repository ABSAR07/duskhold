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
| T-03-04 | Tampering | MapConfig unit and squad fields | medium | mitigate | `MapConfig._validate_squads()` reports non-finite, non-positive and unresolved values so a corrupted file cannot arm a squad silently; each rule pinned by `tests/unit/test_map_validate_squads.gd` Reopened 2026-10-12 by code review CR-01: the validation only reports, `RunContext._init` carries on after `push_error`, and `SquadSystem._fill` / `restore_for_dawn` loop `while living < cap`, so a unit with `max_health <= 0` spawns without bound. Fix owed by the review-fix pass (clamp in `UnitSystem.spawn`, loop over missing seats). Closed by review-fix pass 1 on 2026-10-13 (commit 56b2828), grep-verified 2026-10-14: `SquadSystem._fill` and `restore_for_dawn` loop once per missing seat (`for _seat: int in range(maxi(squad.cap - _living_count(squad), 0))`, `simulation/squads/squad_system.gd:148,462`) and `UnitSystem.spawn` / `heal_to_full` floor the stored health at 1 (`simulation/squads/unit_system.gd:29,126`); `tests/unit/test_squad_bad_unit_health.gd` builds a Barracks over a footman with `max_health` 0 and -5 and expects exactly one spawn per seat (the suite hung on the unfixed code, so the RED run is the hang itself). | closed |
| T-03-05 | Denial of Service | Trickle countdown and squad allocation | medium | mitigate | `squad_respawn_seconds` and `attack_interval` bounded to [SimClock.STEP, 3600], `squad_size` to 1..MAX_UNITS_PER_SQUAD in `_validate_squads()`; `SimClock.ticks` saturates at MAX_TICKS (Phase 2 fix); pinned by `test_map_validate_squads.gd` and `test_squad_respawn.gd` Reopened 2026-10-12 with CR-01: the per-squad cap is not enforced on the consumer side of the spawn loop (Phase 2 `WaveSchedule._allowances` has such a cap; the squad path does not). Closed by review-fix pass 1 on 2026-10-13 (commit 56b2828), grep-verified 2026-10-14: the consumer-side bound now exists, `_fill` and `restore_for_dawn` raise at most `cap - living` units per pass (never more than `squad.cap`, itself bounded to 1..MAX_UNITS_PER_SQUAD by `_validate_squads()`), so a bad definition cannot allocate without bound; pinned by `test_squad_bad_unit_health.gd` and `test_squad_respawn.gd` (14/14). | closed |
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
| T-03-22 | Tampering | CommandKeyController._give -> CommandProcessor (03-13) | low | mitigate | The queued flag is a plain bool inside the existing `SquadOrderIntent`; `CommandProcessor` still returns `QUEUE_CLOSED` for a verb behind a terminal order (`simulation/commands/command_processor.gd:136`) and `SquadOrder.MAX_QUEUE` stays 9 (`simulation/squads/squad_order.gd:33`); nothing under `simulation/` or `project.godot` changed in the plan's commits; `test_squad_queue` and the new `test_command_keys` Shift cases pass in the full suite | closed |
| T-03-23 | Tampering | King._on_king_healed (03-14) | low | mitigate | The handler only forwards the event's hp and max_hp to `HealthBar3D.set_health`, which clamps the ratio and guards `max_hp <= 0` (`presentation/vfx/health_bar_3d.gd:52-53`); no KingState writer is called, `simulation/` is untouched, `test_king_knockout` pins the behaviour | closed |
| T-03-24 | Denial of Service | StartNightPlate (03-15) | low | mitigate | `mouse_filter = 2` (IGNORE) on StartNightPlate, StartNightRows, StartNightPrompt and the glyph (`ui/hud/hud.tscn:74,80,86,101`); pinned by `test_the_plate_is_the_dominant_panel_colour_and_ignores_the_mouse`; the box-selection and right-click suites pass in the full suite | closed |
| T-03-25 | Tampering | ReplayDriver.Tally (03-16) | low | mitigate | The tally only connects to `SimEvents.building_built` and reads defs; `tests/golden/smoke.json` and `army.json` are byte-identical since 9e01f23 and both replay `REPLAY_OK` twice; `test_balance_value_metric` pins the bookkeeping | closed |
| T-03-26 | Denial of Service | playtest runs (03-16) | low | mitigate | No CLI file changed since 9e01f23 (`tools/replay/playtest_cli.gd`, `replay_cli.gd`, `tools/playtest.sh`); runs stay bounded by `BalanceReport.MAX_TICKS` 40000, the seed cap and `PLAYTEST_TIMEOUT_S` (default 1800 s, `tools/playtest.sh:30`); output confined by `ReplayCli.safe_dir` (`tools/replay/replay_cli.gd:70`) | closed |
| T-03-27 | Tampering | Shipped data edits (03-17) | medium | mitigate | Only two values moved (`data/buildings/tower.tres` attack_interval 0.8 to 0.9, `data/maps/prototype_map.tres` night 8 north count 10 to 11), each pinned old to new in `test_military_data_contract.gd` (Round 2 pins) and `test_night_data_contract.gd`; `test_every_night_stays_under_the_per_night_enemy_cap_and_the_map_validates` keeps `MapConfig.validate()` clean; no unit health changed, so the CR-01 loop is unreachable from this retune | closed |
| T-03-28 | Denial of Service | balance search runs (03-17) | low | mitigate | 29 measured candidates (under the 30 cap), five per helper call in private project copies, each run bounded by `BalanceReport.MAX_TICKS`, the seed cap and `PLAYTEST_TIMEOUT_S`; no new CLI argument (no diff on the CLI files) | closed |
| T-03-29 | Tampering | Round 2 tables in 03-BALANCE-REPORT.md and 03-PLAYTEST-GATE.md (03-18) | low | mitigate | The After Round 2 tables come from a fresh `bash tools/playtest.sh --seeds=10` on the committed data (`PLAYTEST_OK runs=60`) and equal 03-17-SUMMARY.md on every figure; each task commit (ad31e2b, bea054d) lists only its own `.planning` file | closed |
| T-03-30 | Denial of Service | playtest and screenshot runs (03-18) | low | mitigate | No new CLI argument; the playtest run is bounded as in T-03-26 and `bash tools/screenshot.sh` ran the unchanged 33-shot list (Saved 33 of 33) | closed |
| T-03-31 | Tampering | KingWidget knocked-out rule, Hud.enemy_count_text and the contrast probe (03-19) | low | accept | Both HUD paths read KingState and the night counts and never write the simulation (the replay goldens passed inside the plan's full suite); `enemy_count_text` formats an int into a constant pattern; the probe rejects a `..` segment and non-PNG paths, exits 64 on usage errors, writes only `build/contrast/` (`tools/screenshot/contrast_probe.gd:14-20`), and `tools/*` is excluded from the export (`export_presets.cfg:11`); since review-fix pass 1 (commit 2e863c8) the guard and the measurement are pinned by `tests/unit/test_contrast_probe.gd` (fifteen rejected paths, WCAG ratios); AR-03-04 | closed |
| T-03-SC | Tampering | package installs (one row per plan, 03-01 to 03-19) | low | accept | No npm, pip or cargo installs anywhere in the phase (RESEARCH Package Legitimacy Audit: none); the only third-party items are the two hash-checked CC0 asset packs above (AR-03-03) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Unregistered Flags

None. All twelve SUMMARY `## Threat Flags` sections read "None" (the seven gap-closure SUMMARYs 03-13 to 03-19 also read "None" and describe only the planned surface: T-03-22 to T-03-31 above) and describe only the planned surface. Two deviations touched trust-adjacent code and are covered by existing rows: 03-07's `MAX_GROUND_HALF_EXTENT` bound (T-03-12) and 03-12's CI timeout change (T-03-20).

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-03-01 | T-03-14 | Marker and box-select work is bounded by the Phase 3 unit count and hard caps; the data-oriented scale-up is Phase 4's goal (ROADMAP) | Planner (03-08 threat model), confirmed by the orchestrator at verification | 2026-10-12 |
| AR-03-02 | T-03-21 | The project has no code-signing budget (PROJECT.md constraint); the owner's playtest build is launched locally; SmartScreen/AV behaviour is tracked under Phase 13 in STATE.md Blockers | Planner (03-12 threat model), owner constraint | 2026-10-12 |
| AR-03-03 | T-03-SC | No package manager installs in the phase; the only third-party inputs are CC0 asset packs verified by sha256 before extraction | Planner (every plan's threat model) | 2026-10-12 |
| AR-03-04 | T-03-31 | The knocked-out widget rule and the singular copy are read-only views of the simulation; the contrast probe is a tools/ script excluded from the export that reads one screenshot and writes under build/ | Planner (03-19 threat model), confirmed by the orchestrator at the 2026-10-13 L1 audit | 2026-10-13 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-12 | 22 (T-03-01 to T-03-21 plus the per-plan T-03-SC row) | 22 | 0 | execute-phase orchestrator (ASVS L1 grep verification, short-circuit rule; commit 80badde) |
| 2026-10-12 (after code review) | 22 | 20 | 2 (T-03-04, T-03-05: medium, below the high block threshold; CR-01 in 03-REVIEW.md) | execute-phase orchestrator, from gsd-verifier and gsd-code-reviewer findings |
| 2026-10-13 (UAT round-1 gap closure) | 32 (T-03-01 to T-03-31 plus the per-plan T-03-SC row) | 30 | 2 (T-03-04, T-03-05: medium, below the high block threshold; CR-01 still open in 03-REVIEW.md) | execute-phase orchestrator (ASVS L1 grep verification of T-03-22 to T-03-31, short-circuit rule; HEAD e47ac01) |
| 2026-10-14 (after review-fix pass 1) | 32 (T-03-01 to T-03-31 plus the per-plan T-03-SC row) | 32 | 0 | execute-phase orchestrator (ASVS L1 grep re-verification of T-03-04 and T-03-05 against commit 56b2828 and of the fix pass's new surface, short-circuit rule; HEAD ca8086a) |
| 2026-10-15 (after review-fix pass 2) | 32 (T-03-01 to T-03-31 plus the per-plan T-03-SC row) | 32 | 0 | execute-phase orchestrator (ASVS L1 grep re-verification of the pass-2 surface: two test files and a debug-only precondition assert, short-circuit rule; HEAD 7f5cb65) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed (T-03-04 and T-03-05, reopened by CR-01 on 2026-10-12, were closed by review-fix pass 1 on 2026-10-13 (grep-verified 2026-10-14); no open threat remains at any severity)
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-12

## Security Audit 2026-10-13
| Metric | Count |
|--------|-------|
| Threats found | 10 (T-03-22 to T-03-31, plan-time registers of 03-13 to 03-19) |
| Closed | 10 (9 mitigated and grep-verified at L1, 1 accepted as AR-03-04) |
| Open | 0 new; T-03-04 and T-03-05 stay open below the high threshold pending the CR-01 review fix |

Short-circuit rule applied: `threats_open: 0`, every gap plan carried a plan-time `<threat_model>`, ASVS level 1. Evidence is the grep lines cited in each register row at HEAD e47ac01; no auditor was spawned.

## Security Audit 2026-10-14 (after review-fix pass 1)
| Metric | Count |
|--------|-------|
| Threats found | 0 new (the 13 fix commits 56b2828 to e01971e add no trust boundary: no network, file-format, account or save surface) |
| Closed | 2 (T-03-04 and T-03-05, both medium, reopened by code review CR-01 on 2026-10-12, closed by the CR-01 fix) |
| Open | 0 |

New surface reviewed at L1 (grep): WR-02 makes `tools/screenshot.sh` write `build/screenshot-<shot>.log` (under `build/`, export-excluded and a forbidden path in `tools/prepush_check.sh`) and read it with the same error filter as `tools/replay.sh`; ci.yml uploads those logs with the screenshots artifact. WR-03 and IN-06 add two toast strings and a static `Toast.refusal_text` (UI reads of the gate's return value, no simulation write; the mixed-selection rule is recorded in the UI-SPEC Copywriting Contract). IN-02's `MapConfig.ground_limit_cm` is now the single ground-bounds rule for the command gate and the ground picker, which strengthens T-03-12 (the toast can no longer disagree with the gate). IN-03's `Separation.displacements` is a pure static routine over packed arrays; both replay goldens are byte-identical. `bash tools/prepush_check.sh` PASSED before the push (no forbidden path, no credential-shaped string, no blob over 5 MB) and CI run 38473757849 is green. Short-circuit rule applied: `threats_open: 0`, plan-time registers, ASVS level 1; no auditor was spawned.

## Security Audit 2026-10-15 (after review-fix pass 2)
| Metric | Count |
|--------|-------|
| Threats found | 0 new (the two fix commits db5e138 and 2471438 touch two test scripts and add a debug-only `assert` to `Separation.displacements`; no trust boundary, input, file, network or save surface changes) |
| Closed | 0 |
| Open | 0 |

New surface reviewed at L1 (grep): IN-10 changes only `tests/unit/test_contrast_probe.gd` (the "outside the project" case is now the project's parent folder, absolute on Windows and on the Linux runner, with an assertion that it localizes outside `res://`), which strengthens the T-03-31 path-guard evidence without touching `tools/screenshot/contrast_probe.gd`. IN-11 changes `tests/unit/test_separation.gd` (inline `UnitDef` / `EnemyDef` radii instead of `load("res://data/...")`, the private `_separate` seam kept and commented) and adds to `simulation/squads/separation.gd` a parallel-array precondition `assert` that Godot strips from release exports (the header note is the durable statement); both callers build the arrays in lockstep, both replay goldens are byte-identical (smoke 703 ticks, army 1353 ticks) and the shipped data is untouched. `bash tools/prepush_check.sh` PASSED before the push (no forbidden path, no credential-shaped string, no blob over 5 MB) and CI run 38774381177 on 7f5cb65 is green. Short-circuit rule applied: `threats_open: 0`, plan-time registers, ASVS level 1; no auditor was spawned.
