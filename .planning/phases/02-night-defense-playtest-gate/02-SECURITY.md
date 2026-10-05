---
phase: "2"
slug: "night-defense-playtest-gate"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-05"
---

# Phase 2 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Built from the `<threat_model>` blocks of plans 02-01 to 02-11 and the SUMMARY threat flags (all eleven report "None" beyond the planned surface; one of those claims is incomplete, see Unregistered Flags). Verified by `gsd-security-auditor` on 2026-10-05 at commit 7499e21. Paths are relative to the repository root.

---

## Trust Boundaries

Phase 2 adds no network, account or save-file surface. The boundaries it touches:

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Command line → replay and playtest CLIs | `tools/replay.sh` and `tools/playtest.sh` pass arguments to Godot scripts that write files | Scenario names, seeds, output and golden paths (integrity of the working tree) |
| Authored `.tres` data → simulation | Night, enemy, building-health and respawn data are first-party but hand-edited | Game data (integrity, and run length) |
| Presentation and debug tooling → simulation | Puppets, the King node, the overlay sections and the path gizmo must only read | Read-only game state |
| Wall clock and engine globals → simulation | Any nondeterministic source would break seeded replays | Determinism of the event digest |
| Working tree → git index → public GitHub | Two pushes in this phase; the repo ABSAR07/duskhold is public | Source, history, author identities |
| GitHub Actions runner → public artifacts | CI uploads test results, replay logs and screenshots | Generated files from a job with a read-only token and no secrets |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-02-01 | Tampering | `simulation/` determinism | medium | mitigate | `tests/unit/test_sim_rules_guard.gd:18-40` bans global RNG, `Time.`, `OS.`, `get_tree(`, NavigationServer, PhysicsServer and `Engine.get_` under `res://simulation`, and transcendental calls in clock, night, king and castle; each pattern is proven against a sample (`:90-96`) and the scan must read more than 20 files (`:79`). RNG pinned by `test_sim_rng.gd:6-35`; step and clamp by `test_sim_clock.gd:21-24`. Auditor grep of `simulation/`: 0 hits. | closed |
| T-02-02 | Denial of Service | ReplayDriver loop | low | mitigate | `tools/replay/replay_driver.gd:39` loops at most `max_ticks`, else outcome `timeout`; `simulation/run/run_context.gd:67` clamps each frame to 0.25 s. Pinned by `test_determinism.gd:58-63`, `test_sim_clock.gd:63-71`. | closed |
| T-02-03 | Tampering | shared `.tres` resources | low | mitigate | No assignment to def, map or tuning fields under `simulation/`; tools that vary data use `duplicate_deep(DEEP_DUPLICATE_ALL)` (`tools/screenshot/shot_scenarios.gd:98`). Pinned by `test_shot_list.gd:63-65`, `test_prototype_nights.gd:80`. | closed |
| T-02-04 | Denial of Service | MapConfig nights and groups | medium | mitigate | `simulation/defs/map_config.gd:7` (300 per night), `:220-233` (non-positive count, negative delay or interval, empty night, over-cap total); `validate()` runs in `run_context.gd:31`. Since review-fix pass 1 the cap is enforced at runtime too: `simulation/night/wave_schedule.gd:65-77` gives a group at an unknown spawn point or with an unknown enemy nothing and spends one 300-enemy budget across the night's groups in group order; the spawn preview uses the same budget. Pinned by `test_map_validate_nights.gd:79-151` and the four budget tests in `test_wave_schedule.gd`. | closed |
| T-02-05 | Tampering | Phase 1 tests weakened by the migration | low | mitigate | Commit `f37ce9a`: in the migrated Phase 1 suites the only changed lines swap `load(PROTOTYPE_MAP)` for `E2eSupport.waveless_prototype_map()`; no `assert` line was removed. | closed |
| T-02-06 | Tampering | King node writing simulation state | low | mitigate | `simulation/king/king_state.gd:40-43` ignores `report_position` while down; `presentation/king/king.gd:61` ignores input while down or after the run ends; the node only connects signals and calls getters. Pinned by `test_king_respawn.gd:122`, `tests/e2e/test_king_knockout.gd:94`. | closed |
| T-02-07 | Denial of Service | respawn tuning data | low | mitigate | `simulation/defs/loop_tuning.gd:64-69` clamps start, step and cap to at least 0 and the result to the cap. Pinned by `test_king_respawn.gd:69-84`. | closed |
| T-02-08 | Tampering | building health data | low | mitigate | `map_config.gd:86` reports `max_health <= 0`, and since review-fix pass 1 `:186-197` reports a tier with a negative attack range or projectile speed or a non-positive attack interval; `simulation/buildings/building_system.gd:179-188` ignores hits on a destroyed building, clamps, and destroys exactly once. Pinned by `test_building_damage.gd:75,205,223,234` and `test_map_validate_enemies.gd`. | closed |
| T-02-09 | Repudiation | asset provenance for rubble | low | mitigate | `git diff 2512000..HEAD` touches nothing in `assets/` or the attribution log and adds no model, image, audio or font; the rubble is primitives. `test_attribution_log.gd` unchanged. | closed |
| T-02-10 | Denial of Service | ProjectileVfx and EnemyViews node growth | low | mitigate | `presentation/vfx/projectile_vfx.gd:12,115` (128 cap); `presentation/enemies/enemy_views.gd:11,80` (256 views), `:13,124` (64 puffs); every visual frees itself. Pinned by `test_projectiles_visible.gd:105-115,121,202`. | closed |
| T-02-11 | Repudiation | asset provenance | low | mitigate | Same evidence as T-02-09; the 02-05 and 02-11 visuals are primitives only. | closed |
| T-02-12 | Tampering | dawn payout and rebuild | low | mitigate | `building_system.gd:194-204` (`rebuild_destroyed`) has no Economy reference; `:82` skips rebuilt spots in dawn income; `_apply_dawn_payout` is called once from `_enter_dawn` (`run_manager.gd:167-198`). Pinned by `test_dawn_rebuild.gd:134,177,324,368`. | closed |
| T-02-13 | Denial of Service | Play again / Quit in tests | low | mitigate | `ui/results/results_screen.gd:99-106` only emits signals, and since review-fix pass 1 only once the input grace window is over (`:61-62`, `:85-86`); `presentation/map/map_root.gd:35-59` wires reload and quit only when `handle_results_actions` is true; `test_results_screen.gd:108-116` sets it per scene (false everywhere except the one test that only inspects the connections and presses nothing) and `shot_runner.gd:119` sets it false. See observation 5. | closed |
| T-02-14 | Tampering | terminal phase transitions | low | mitigate | `_phase =` appears only at `run_manager.gd:203`; tick and step are no-ops once the run is over (`run_manager.gd:130-132`, `run_context.gd:53`); `end_run_in_defeat` is legal only at night. Pinned by `test_run_manager.gd:188-204`, `test_run_outcomes.gd:220,236,245`. | closed |
| T-02-15 | Tampering | overlay providers and path gizmo | low | mitigate | `ui/overlay/night_overlay_sections.gd:39-97` and `presentation/debug/enemy_path_gizmo.gd:56-133` call only getters. Pinned by `test_debug_overlay_night_sections.gd:206-230` (100 collections change no state and emit no signal). | closed |
| T-02-16 | Information Disclosure | overlay and gizmo in release builds | low | accept | See AR-01. | closed |
| T-02-17 | Information Disclosure | git push in plan 02-09 | high | mitigate | `tools/prepush_check.sh` (tracked and all-refs paths, credential patterns, blobs over 5 MB, identities) passed when the auditor ran it after the fact over all refs: 766 tracked files, 548 commits, 1 identity. Pushed range `2512000..0b66929`: text files only, no forbidden path, 0 credential-pattern hits. One exact push allow rule exists. That the check ran before the push is reported by the 02-09 executor, not independently observed. | closed |
| T-02-18 | Tampering | `--out`, `--expect-file`, `--write-golden` paths | medium | mitigate | `tools/replay/replay_cli.gd:87-99` rejects any `..` segment and any absolute path outside `res://`; `safe_dir` (`:70-74`) requires `res://build` or below; `_safe_json` (`:78-83`) requires `.json` under `res://tests/golden/`; usage errors exit 64 before anything runs. Pinned by `test_replay_cli_args.gd:28-101`. Auditor ran 7 bad-argument cases through `tools/replay.sh`: all exit 64, nothing written. | closed |
| T-02-19 | Denial of Service | replay CLI hang or silent script error | medium | mitigate | Scenario tick bounds in `replay_scenarios.gd`; `tools/replay.sh:45-67` wraps the run in `timeout` (300 s), requires the `REPLAY_OK` sentinel and greps for script errors; the CLI fails on a `timeout` outcome (`replay_cli.gd:173-179`). See observation 6. | closed |
| T-02-20 | Elevation of Privilege | CI workflow edit (02-09) | low | mitigate | The diff adds only the replay step and `build/replay/` to an upload; `ci.yml:17-18` stays `contents: read`; all 17 `uses:` lines are pinned to 40-hex SHAs; no `pull_request_target`; no secrets. | closed |
| T-02-21 | Denial of Service | playtest matrix size and run length | medium | mitigate | `tools/playtest/playtest_cli.gd:55-77` (strategy allowlist, seeds 1 to 50); `tools/replay/balance_report.gd:59-60` bounds a run at 40000 ticks; `tools/playtest.sh:45-67` wraps in `timeout` (1800 s) with a sentinel and error grep. Pinned by `test_balance_report.gd:258-268`, `test_every_night_ends.gd:35`. | closed |
| T-02-22 | Tampering | playtest `--out` path | medium | mitigate | `playtest_cli.gd:44` reuses `ReplayCli.safe_dir` against `res://build` and exits 64 otherwise. Pinned by `test_balance_report.gd:271-278`. Read and test-pinned; the auditor did not execute this CLI with bad arguments. | closed |
| T-02-23 | Repudiation | balance claims at the gate | low | mitigate | `02-BALANCE-REPORT.md` holds the acceptance checks, the before and after tables, the data changes and what the bots cannot tell; `02-PLAYTEST-GATE.md` keeps the owner's sign-off separate, through `/gsd-verify-work`. The sign-off itself is still open. | closed |
| T-02-24 | Information Disclosure | git push in plan 02-11 | high | mitigate | As T-02-17. Pushed range `0b66929..dd5428c`; CI run 37325147907 on `dd5428c` succeeded on lint, test, export and screenshots. | closed |
| T-02-25 | Information Disclosure | `duskhold-screenshots` artifact | low | accept | See AR-02. | closed |
| T-02-26 | Elevation of Privilege | CI workflow edit (02-11) | low | mitigate | `git show dd5428c` changes one line, the screenshots job `timeout-minutes` 20 to 30; permissions, secrets and pins as T-02-20. | closed |
| T-02-SC (all 11 plans) | Tampering | package installs | low | accept | See AR-03. | closed |

### Unregistered Flags

- **`gut-results` artifact now carries replay output (plan 02-09).** `ci.yml:78-86` uploads `build/replay/` into the public `gut-results` artifact: the replay and import logs, the per-scenario summary JSON (which includes the OS name) and the event lines. That artifact has no `retention-days`, so GitHub's 90-day default applies (the run 37325147907 copy expires 2027-01-03). The 02-09 summary says no new surface was added, and the plan's register has no Information Disclosure row for this. The content is the public repository's own deterministic game data from a job with no secrets, so it is not blocking. Open choice for the owner: accept it alongside AR-02, or set `retention-days: 7` on that upload.
- **Three changes outside the plans' declared files were checked and weaken nothing:** the `ui_accept` / `ui_left` / `ui_right` bindings in `project.godot` (02-07; key and pad events only, pinned by `test_input_map.gd:181-198`), the screenshots job timeout (02-11; still bounded, and each shot by `RUN_TIMEOUT_S=120`), and the `_safe_dir` to `safe_dir` rename (02-10; both CLIs' tests pin the rule).
- **`results_input_grace_seconds` has no upper bound (review-fix pass 1).** `ui/results/results_screen.gd:85` clamps the new tuning value at 0 from below only. A very large value in a mistyped or tampered `loop_tuning.tres` would leave Play again and Quit ignoring every press; the window can still be closed. `test_loop_tuning_contract.gd` pins the shipped value between 0.3 and 1.0 s. Same class as T-02-07 and low severity, so not blocking; passed to the code review as a fact.

### Observations (non-blocking)

1. T-02-17 / T-02-24: running the pre-push check is a procedure, not an enforced hook (`.git/hooks/pre-push` only runs `git lfs pre-push`). No secret scanner such as gitleaks is installed; the pushed ranges hold no binaries.
2. T-02-01: the transcendental scan covers clock, night, king and castle. `pow` at `simulation/defs/loop_tuning.gd:77` (the Phase 1 coin-drip curve) is outside those roots; its callers are input, VFX and screenshot code, none on the replay or digest path.
3. T-02-04: since review-fix pass 1 the night budget is enforced at runtime and pinned by tests. The skip of a group with an unknown spawn point or enemy id still has no dedicated test. The rules that pass added to `validate()` (an enemy that can never attack, and the others) are reported at run start like every `validate()` error; they do not stop a run, so such an enemy is caught by the data tests on shipped data, not refused at runtime.
4. T-02-10: `MAX_VIEWS` and `MAX_PUFFS` are in the code but only `MAX_PROJECTILES` is asserted by a test.
5. T-02-13: only `test_results_screen.gd` and the screenshot runner set `handle_results_actions` false. Ten other e2e suites load the map with the default true, but none injects an input event that matches `ui_accept`, so no button can be pressed there. Since review-fix pass 1 a press in the first 0.6 s after the screen appears is ignored as well.
6. T-02-19 / T-02-21: the `--import` warm-up in `replay.sh` and `playtest.sh` runs without `timeout`. CI bounds it with the job timeout; a local run could hang at that step.
7. T-02-15: the read-only test covers the three overlay row builders, not `EnemyPathGizmo.refresh()`, which is getter-only by code reading.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-02-16 | Carried from T-01-15 (Phase 1 AR-01). The F3 / gamepad-Back debug overlay, now with Wave, King and Paths sections, and the EnemyPathGizmo ship read-only in every build: `export_presets.cfg` excludes only `tests/*`, `addons/gut/*` and `tools/*`, and there is no debug-build gate. Every night row builder and the gizmo call only RunContext getters. Residual risk: a player of this offline single-player game can see a little more than the HUD shows (run seed, next-spawn countdown, target counts, enemy-to-target lines) but cannot change state, and nothing leaves the machine. Revisit gating before the Phase 13 release. | Plan 02-08 threat model (carried T-01-15) | 2026-10-05 |
| AR-02 | T-02-25 | Carried from T-01-16 (Phase 1 AR-02). The public `duskhold-screenshots` CI artifact holds 15 scripted PNG frames of the game's own primitive and CC0 content and the Godot import log for the public repo's files. The job has a read-only token and no secrets; retention is 7 days. The overlay frame shows the fixed screenshot seed 1, which is not a secret. Residual risk: anyone can download frames that reveal nothing beyond the public repository, for 7 days. | Plan 02-11 threat model | 2026-10-05 |
| AR-03 | T-02-SC (02-01 to 02-11) | These plans install no packages: `git diff 2512000..HEAD` changes nothing under `addons/`, `tools/requirements-lint.txt` or `tools/bootstrap.py`. The toolchain was pinned and owner-approved in 01-01. | Plan threat models | 2026-10-05 |

---

## Security Audit Trail

| Date | Auditor | Scope | Result |
|------|---------|-------|--------|
| 2026-10-05 | gsd-security-auditor (via `/gsd-secure-phase 2`, dispatched from `/gsd-execute-phase 2`) | All 26 planned threats plus T-02-SC, at commit 7499e21, ASVS level 1 | SECURED: 26 of 26 closed (24 mitigated and found in code, 2 accepted), 1 unregistered flag recorded |
| 2026-10-05 | Orchestrator (via `/gsd-secure-phase 2`, dispatched from `/gsd-execute-phase 2`), re-audit after review-fix pass 1 | The mitigations whose cited files changed in `c6bb202`, `ef8ca58` and `6057fd1` (T-02-01, T-02-04, T-02-07, T-02-08, T-02-13) and the pre-push check (T-02-17, T-02-24), at grep depth | 26 of 26 still closed; evidence refreshed; 1 unregistered flag added |

What the auditor ran: `bash tools/prepush_check.sh` (passed), seven bad-argument cases through `bash tools/replay.sh` (all exit 64), git range and blob checks on both pushed ranges, and `gh` checks of CI run 37325147907, its artifacts and the repo's visibility. What it read rather than ran: every cited file and line. What it did not verify itself: that the pre-push check ran before each push (executor-reported), that the cited GUT tests pass (it did not run the suite; the orchestrator's full run at 7499e21 was 719 tests, 0 failures, and CI was green on dd5428c), and the playtest CLI's rejection behaviour (read and test-pinned only).

## Security Audit 2026-10-05

| Metric | Count |
|--------|-------|
| Threats found | 26 |
| Closed | 26 |
| Open | 0 |

## Security Audit 2026-10-05 (re-audit after review-fix pass 1)

| Metric | Count |
|--------|-------|
| Threats found | 26 |
| Closed | 26 |
| Open | 0 |

Re-checked at grep depth (ASVS level 1) the mitigations touched by the 3 fix commits (`c6bb202`, `ef8ca58`, `6057fd1`). The other 19 threats cite files that did not change and were not re-checked.
- **T-02-04:** strengthened. The 300-enemy night limit is now a runtime budget in `WaveSchedule._allowances` (shared by the schedule and the spawn preview) instead of a `validate()` message only, and the per-group cap is the same number. `validate()` gained the enemy rules of the WR-01 fix; like the rest of `validate()` they are reported, not enforced.
- **T-02-08:** strengthened. `validate()` also reports a tower tier's bad combat numbers. The damage clamp and destroy-once logic are unchanged.
- **T-02-07:** unchanged; the respawn clamp moved to `loop_tuning.gd:64-69`. The new `results_input_grace_seconds` field is clamped at 0 from below and has no upper bound (see Unregistered Flags).
- **T-02-13:** the results screen still only emits signals, now gated by the grace window. `handle_results_actions` is false in every test scene that presses a button and in the screenshot runner.
- **T-02-01:** no `Time`, `OS`, global random or scene-tree call under `simulation/` (grep clean; `test_sim_rules_guard.gd` green in the full run). The new real-time read is in `ui/results/results_screen.gd`, after the run has ended and outside the digest path. Both replay digests are unchanged.
- **T-02-17 / T-02-24:** `tools/prepush_check.sh` PASSED over all refs, including the 14 unpushed commits. Nothing was pushed in this pass.
- **Tests:** full suite 738/738 (86 scripts), lint clean, at source `6057fd1`.
