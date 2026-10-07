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
> Built from the `<threat_model>` blocks of plans 02-01 to 02-16 and the SUMMARY threat flags (all sixteen report "None" beyond the planned surface; one of those claims is incomplete, see Unregistered Flags). Verified by `gsd-security-auditor` on 2026-10-05 at commit 7499e21. Paths are relative to the repository root.

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
| T-02-04 | Denial of Service | MapConfig nights and groups | medium | mitigate | `simulation/defs/map_config.gd:7` (300 per night), `:220-233` (non-positive count, negative delay or interval, empty night, over-cap total); `validate()` runs in `run_context.gd:31`. At runtime `simulation/night/wave_schedule.gd:60-74` (`_allowances`) gives a null group, a group at an unknown spawn point or one with an unknown enemy nothing and spends one 300-enemy budget across the night's groups in group order; since review-fix pass 2 the schedule and the spawn preview apply exactly that rule, and the budget is the only cap. Pinned by `test_map_validate_nights.gd:79-151` and the six budget and preview tests in `test_wave_schedule.gd` (15 tests). | closed |
| T-02-05 | Tampering | Phase 1 tests weakened by the migration | low | mitigate | Commit `f37ce9a`: in the migrated Phase 1 suites the only changed lines swap `load(PROTOTYPE_MAP)` for `E2eSupport.waveless_prototype_map()`; no `assert` line was removed. | closed |
| T-02-06 | Tampering | King node writing simulation state | low | mitigate | `simulation/king/king_state.gd:40-43` ignores `report_position` while down; `presentation/king/king.gd:61` ignores input while down or after the run ends; the node only connects signals and calls getters. Pinned by `test_king_respawn.gd:122`, `tests/e2e/test_king_knockout.gd:94`. | closed |
| T-02-07 | Denial of Service | respawn tuning data | low | mitigate | `simulation/defs/loop_tuning.gd:64-69` clamps start, step and cap to at least 0 and the result to the cap. Pinned by `test_king_respawn.gd:69-84`. | closed |
| T-02-08 | Tampering | building health data | low | mitigate | `map_config.gd:86` reports `max_health <= 0`, and since review-fix pass 1 `:186-197` reports a tier with a negative attack range or projectile speed or a non-positive attack interval; `simulation/buildings/building_system.gd:179-188` ignores hits on a destroyed building, clamps, and destroys exactly once. Pinned by `test_building_damage.gd:75,205,223,234` and `test_map_validate_enemies.gd`. | closed |
| T-02-09 | Repudiation | asset provenance for rubble | low | mitigate | `git diff 2512000..HEAD` touches nothing in `assets/` or the attribution log and adds no model, image, audio or font; the rubble is primitives. `test_attribution_log.gd` unchanged. | closed |
| T-02-10 | Denial of Service | ProjectileVfx and EnemyViews node growth | low | mitigate | `presentation/vfx/projectile_vfx.gd:12,115` (128 cap); `presentation/enemies/enemy_views.gd:11,80` (256 views), `:13,124` (64 puffs); every visual frees itself. Pinned by `test_projectiles_visible.gd:105-115,121,202`. | closed |
| T-02-11 | Repudiation | asset provenance | low | mitigate | Same evidence as T-02-09; the 02-05 and 02-11 visuals are primitives only. | closed |
| T-02-12 | Tampering | dawn payout and rebuild | low | mitigate | `building_system.gd:194-204` (`rebuild_destroyed`) has no Economy reference; `:82` skips rebuilt spots in dawn income; `_apply_dawn_payout` is called once from `_enter_dawn` (`run_manager.gd:167-198`). Pinned by `test_dawn_rebuild.gd:134,177,324,368`. | closed |
| T-02-13 | Denial of Service | Play again / Quit in tests | low | mitigate | `ui/results/results_screen.gd:119-126` only emits signals, and since review-fix pass 2 only when `_press_counts()` (`:115-116`) holds: the grace window is over (`:71-72`) and the press began after it (`button_down` stamp, `:110-111`); the window is `results_input_grace_seconds` clamped to `MAX_GRACE_S` = 3 s (`:30`, `:95-97`). `presentation/map/map_root.gd:35-59` wires reload and quit only when `handle_results_actions` is true; `test_results_screen.gd:116` sets it per scene (false everywhere except the one test that only inspects the connections and presses nothing) and `shot_runner.gd:119` sets it false. See observation 5. | closed |
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
| T-02-27 | Tampering | `MapConfig.base_dawn_income` (02-12) | low | mitigate | `simulation/defs/map_config.gd:78-79` reports a negative value; `simulation/run/run_manager.gd:48` clamps it to 0 at runtime (`maxi`), and `DawnPayoutVfx` still clamps every per-spot amount to `MAX_AMOUNT`. Pinned by `test_map_validate_income.gd` (8) and `test_dawn_income.gd` (12); 6 of the latter fail with the castle entry switched off (orchestrator probe). | closed |
| T-02-28 | Spoofing | dawn payout `per_spot` castle key (02-12) | low | mitigate | `map_config.gd:11` reserves `CASTLE_PAYOUT_KEY`; `:120` reports a spot whose id is that key, so a House entry can never shadow or merge with the base income; `run_manager.gd:198-199` lists the base last under the key. Pinned by `test_map_validate_income.gd`. | closed |
| T-02-29 | Denial of Service | `LoopTuning.fast_forward_scale` (02-13) | medium | mitigate | `input/fast_forward_controller.gd:35-42` (`scale_for`) returns 1.0 outside NIGHT or when fast-forward is not switched on (a toggle since 02-18), treats NaN and infinities as 1.0, and clamps to `[1.0, LoopTuning.FAST_FORWARD_MAX_SCALE]` (4.0, `loop_tuning.gd:19`); `run_context.gd:69` still clamps every frame to `SimClock.MAX_ADVANCE_SECONDS` (0.25 s), so a fast-forwarded frame runs at most 7 steps. Pinned by `test_fast_forward_rules.gd` (14) and `test_loop_tuning_contract.gd`. | closed |
| T-02-30 | Tampering | `Engine.time_scale` (global engine state) (02-13) | medium | mitigate | One writer: `test_fast_forward_rules.gd:13` scans the project for `Engine.time_scale =` and allows only `fast_forward_controller.gd`; the controller drops to 1.0 inside the `phase_changed` handler that leaves NIGHT (`:77-86`) and restores 1.0 in `_exit_tree` (`:66-72`); the tests reset it in before/after each. 11 of 19 fast-forward tests fail with the scale forced to real time (orchestrator probe). | closed |
| T-02-31 | Tampering | determinism of seeded nights under fast-forward (02-13) | medium | mitigate | `grep -rn time_scale simulation/` is empty (auditor grep, and the same scan in `test_fast_forward_rules.gd`); doubled frame deltas give the same ticks and digest (`test_doubled_frame_deltas_run_the_same_steps_and_the_same_digest`); the smoke golden digest `2599c7c2...` is unchanged and the full run agrees across `--twice`. | closed |
| T-02-32 | Denial of Service | results panel layout (02-14) | low | accept | See AR-04. | closed |
| T-02-33 | Denial of Service | `MapConfig` castle attack data (02-15) | medium | mitigate | `map_config.gd:169-181` reports negative damage, range, interval or projectile speed and an attacking castle (`damage > 0`) with range 0 or interval 0; at runtime `simulation/night/castle_attack.gd:32-37` (`is_armed`) requires damage, range and interval all above 0, so bad data can never make the castle fire every tick, and `step` keeps a `_ready_at` cooldown (`:48`, `:66`). Pinned by `test_map_validate_castle.gd` (9) and `test_castle_attack.gd` (14); 11 of the latter fail with the castle never armed (orchestrator probe). | closed |
| T-02-34 | Tampering | castle firing outside its rules (02-15) | low | mitigate | `castle_attack.gd:48` returns while the castle is destroyed or before `_ready_at`; the only `step` call is `night_sim.gd:80`, after the towers and before the enemies, and `begin_night` (`:64`) resets it, so nothing fires by day, at dawn or after the run ends; `castle_attack.gd` sits under `simulation/night/`, inside `test_sim_rules_guard.gd`'s scan roots. Pinned by `test_castle_attack.gd` (destroyed castle, order, cooldown and boundary tests). | closed |
| T-02-35 | Repudiation | `02-BALANCE-REPORT.md` and `02-PLAYTEST-GATE.md` round 2 (02-16) | low | mitigate | Both files keep the disclaimer that the bot numbers are not the owner's sign-off (2 matches each); the round-2 packet ends in `Your decision (round 2)` and the decision is recorded only through `/gsd-verify-work` (D-18). The sign-off itself is still open. | closed |
| T-02-36 | Tampering | `data/maps/prototype_map.tres` tuning (02-16) | low | mitigate | The owner's two levers were never applied (the balanced bot won 10 of 10), so 02-16 changed no data file (`git diff 25c2f02..a483ff6 -- data/` is empty); `test_balance_acceptance.gd:89-91` pins grunt `max_health` 6 and the other six tests pin the shape of every strategy on seeds 1 to 3. | closed |
| T-02-SC (all 16 plans) | Tampering | package installs | low | accept | See AR-03. | closed |

### Unregistered Flags

- **`gut-results` artifact now carries replay output (plan 02-09).** `ci.yml:78-86` uploads `build/replay/` into the public `gut-results` artifact: the replay and import logs, the per-scenario summary JSON (which includes the OS name) and the event lines. That artifact has no `retention-days`, so GitHub's 90-day default applies (the run 37325147907 copy expires 2027-01-03). The 02-09 summary says no new surface was added, and the plan's register has no Information Disclosure row for this. The content is the public repository's own deterministic game data from a job with no secrets, so it is not blocking. Open choice for the owner: accept it alongside AR-02, or set `retention-days: 7` on that upload.
- **Three changes outside the plans' declared files were checked and weaken nothing:** the `ui_accept` / `ui_left` / `ui_right` bindings in `project.godot` (02-07; key and pad events only, pinned by `test_input_map.gd:181-198`), the screenshots job timeout (02-11; still bounded, and each shot by `RUN_TIMEOUT_S=120`), and the `_safe_dir` to `safe_dir` rename (02-10; both CLIs' tests pin the rule).
- **`results_input_grace_seconds` has no upper bound (review-fix pass 1) — resolved in review-fix pass 2.** `ui/results/results_screen.gd:95` now clamps the value to `[0, MAX_GRACE_S]`, with `MAX_GRACE_S` = 3.0 at `:30` and the reason in its comment. `test_results_screen.gd` (`test_a_huge_grace_value_is_capped_so_the_buttons_still_work`) pins it with a 600 s data value, and `test_loop_tuning_contract.gd` still pins the shipped value between 0.3 and 1.0 s. Was the same class as T-02-07 and low severity; nothing to carry forward.

### Observations (non-blocking)

1. T-02-17 / T-02-24: running the pre-push check is a procedure, not an enforced hook (`.git/hooks/pre-push` only runs `git lfs pre-push`). No secret scanner such as gitleaks is installed; the pushed ranges hold no binaries.
2. T-02-01: the transcendental scan covers clock, night, king and castle. `pow` at `simulation/defs/loop_tuning.gd:77` (the Phase 1 coin-drip curve) is outside those roots; its callers are input, VFX and screenshot code, none on the replay or digest path.
3. T-02-04: the night budget is enforced at runtime and pinned by tests. Since review-fix pass 2 the unknown-enemy skip has a dedicated preview-versus-schedule test (`test_wave_schedule.gd:191-206`); the unknown-spawn-point skip is still covered only through `validate()` (`test_map_validate_nights.gd:95-98`). The rules review-fix pass 1 added to `validate()` (an enemy that can never attack, and the others) are reported at run start like every `validate()` error; they do not stop a run, so such an enemy is caught by the data tests on shipped data, not refused at runtime.
4. T-02-10: `MAX_VIEWS` and `MAX_PUFFS` are in the code but only `MAX_PROJECTILES` is asserted by a test.
5. T-02-13: only `test_results_screen.gd` and the screenshot runner set `handle_results_actions` false. Ten other e2e suites load the map with the default true, but none injects an input event that matches `ui_accept`, so no button can be pressed there. Since review-fix pass 1 a press in the grace window after the screen appears is ignored; since pass 2 the press must also have begun after the window (a Button fires on release), and the window is capped at 3 s.
6. T-02-19 / T-02-21: the `--import` warm-up in `replay.sh` and `playtest.sh` runs without `timeout`. CI bounds it with the job timeout; a local run could hang at that step.
7. T-02-15: the read-only test covers the three overlay row builders, not `EnemyPathGizmo.refresh()`, which is getter-only by code reading.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-02-16 | Carried from T-01-15 (Phase 1 AR-01). The F3 / gamepad-Back debug overlay, now with Wave, King and Paths sections, and the EnemyPathGizmo ship read-only in every build: `export_presets.cfg` excludes only `tests/*`, `addons/gut/*` and `tools/*`, and there is no debug-build gate. Every night row builder and the gizmo call only RunContext getters. Residual risk: a player of this offline single-player game can see a little more than the HUD shows (run seed, next-spawn countdown, target counts, enemy-to-target lines) but cannot change state, and nothing leaves the machine. Revisit gating before the Phase 13 release. | Plan 02-08 threat model (carried T-01-15) | 2026-10-05 |
| AR-02 | T-02-25 | Carried from T-01-16 (Phase 1 AR-02). The public `duskhold-screenshots` CI artifact holds 15 scripted PNG frames of the game's own primitive and CC0 content and the Godot import log for the public repo's files. The job has a read-only token and no secrets; retention is 7 days. The overlay frame shows the fixed screenshot seed 1, which is not a secret. Residual risk: anyone can download frames that reveal nothing beyond the public repository, for 7 days. | Plan 02-11 threat model | 2026-10-05 |
| AR-03 | T-02-SC (02-01 to 02-16) | These plans install no packages: `git diff 2512000..HEAD` changes nothing under `addons/`, `tools/requirements-lint.txt` or `tools/bootstrap.py` (re-checked for `df50de2..a483ff6`, the gap-closure range, on 2026-10-06). The toolchain was pinned and owner-approved in 01-01. | Plan threat models | 2026-10-05, extended 2026-10-06 |
| AR-04 | T-02-32 | The results panel grows by 11 px only (`ButtonsMargin`, `margin_top = 11`) and stays centred inside 1280x720; `test_results_layout.gd` pins the stat-row and button gaps and `test_results_screen.gd` (14) still presses both buttons by keyboard, gamepad and mouse after the grace. Residual risk: none beyond a layout that could only misplace two buttons on a screen the owner looks at. | Plan 02-14 threat model | 2026-10-06 |

---

## Security Audit Trail

| Date | Auditor | Scope | Result |
|------|---------|-------|--------|
| 2026-10-05 | gsd-security-auditor (via `/gsd-secure-phase 2`, dispatched from `/gsd-execute-phase 2`) | All 26 planned threats plus T-02-SC, at commit 7499e21, ASVS level 1 | SECURED: 26 of 26 closed (24 mitigated and found in code, 2 accepted), 1 unregistered flag recorded |
| 2026-10-05 | Orchestrator (via `/gsd-secure-phase 2`, dispatched from `/gsd-execute-phase 2`), re-audit after review-fix pass 1 | The mitigations whose cited files changed in `c6bb202`, `ef8ca58` and `6057fd1` (T-02-01, T-02-04, T-02-07, T-02-08, T-02-13) and the pre-push check (T-02-17, T-02-24), at grep depth | 26 of 26 still closed; evidence refreshed; 1 unregistered flag added |
| 2026-10-06 | Orchestrator (via `/gsd-secure-phase 2`, dispatched from `/gsd-execute-phase 2`), re-audit after review-fix pass 2 | The mitigations whose cited files changed in `21b8abb`, `260ec31` and `81c300e` (T-02-01, T-02-04, T-02-13) and the pre-push check (T-02-17, T-02-24), at grep depth | 26 of 26 still closed; evidence refreshed; the pass-1 unregistered flag resolved |
| 2026-10-06 | Orchestrator (via `/gsd-secure-phase 2`, dispatched from `/gsd-execute-phase 2 --gaps-only`), after the gap-closure plans 02-12 to 02-16 | The ten new planned threats T-02-27 to T-02-36 plus T-02-SC for the five plans, the touched mitigations T-02-01, T-02-12 and T-02-13, and the pre-push check (T-02-17, T-02-24), at grep depth (ASVS level 1), commits `b6c47d5..a483ff6` | 36 of 36 closed (33 mitigated and found in code, 3 accepted); 1 accepted risk added (AR-04) |

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

## Security Audit 2026-10-06 (re-audit after review-fix pass 2)

| Metric | Count |
|--------|-------|
| Threats found | 26 |
| Closed | 26 |
| Open | 0 |

Re-checked at grep depth (ASVS level 1) the mitigations touched by the 3 fix commits (`21b8abb`, `260ec31`, `81c300e`), which closed all six findings of the second code review. The other 23 threats cite files that did not change and were not re-checked.
- **T-02-04:** strengthened. `WaveSchedule._allowances` applies one rule for the schedule and the spawn preview (a null group, an unknown spawn point or an unknown enemy gets 0 and spends no budget), and the night budget is the only cap (the dead `MAX_GROUP_COUNT` is gone). A hostile data file still cannot spawn more than 300 a night, and can no longer make the telegraph promise enemies the night will not bring.
- **T-02-13:** strengthened. The results buttons act only on a press that began after the grace window and was released after it, and the window is capped at 3 s, so a tampered or mistyped `loop_tuning.tres` cannot leave the buttons dead. The pass-1 unregistered flag is resolved.
- **T-02-01:** grep of `simulation/` clean (the only `randf_range` is on the seeded `_spawn_rng` instance at `night_sim.gd:129-130`, which the guard allows); the three `Time.get_ticks_msec()` reads are all in `ui/results/results_screen.gd` (`:72`, `:97`, `:111`), after the run has ended and outside the digest path. Both replay digests are unchanged.
- **T-02-17 / T-02-24:** `tools/prepush_check.sh` PASSED over all refs (568 commits, one author and committer identity), including the 24 unpushed commits. Nothing was pushed in this pass.
- **Tests:** full suite 745/745 (86 scripts), lint clean, at source `81c300e`.

## Security Audit 2026-10-06 (after the gap-closure plans 02-12 to 02-16)

| Metric | Count |
|--------|-------|
| Threats found | 36 |
| Closed | 36 |
| Open | 0 |

The five gap-closure plans for the owner's round-1 UAT (G-02-1, G-02-2) each carried a plan-time `<threat_model>`; their ten threats T-02-27 to T-02-36 were added to the register and verified at grep depth (ASVS level 1) against the code at `a483ff6`, and all five SUMMARYs flag nothing beyond the planned surface. Short-circuit rule applied: `threats_open: 0`, register authored at plan time, ASVS level 1, so no auditor subagent was spawned.
- **New surface, data to engine (T-02-29, T-02-30, T-02-31):** fast-forward is the first thing in the project that writes a global engine setting. The guard is in three layers: `scale_for` clamps the tuning value to `[1.0, 4.0]` and treats non-finite values as real time; one source file is allowed to assign `Engine.time_scale` and a test scans the project for any other; and `simulation/` never reads the time scale, so a fast-forwarded night runs more fixed steps per real second and nothing else (doubled deltas give the same digest; the smoke golden is unchanged). The orchestrator's whole-feature-off probe failed 11 of 19 fast-forward tests.
- **New surface, data to simulation (T-02-27, T-02-28, T-02-33, T-02-34):** both new map fields default to 0 (off) in the script, so the frozen fixtures and the golden are untouched; `validate()` reports negative values, the reserved castle id and an attacking castle with no range or interval; at runtime the base income is clamped at 0 from below and the castle is armed only with damage, range and interval all positive, keeps a cooldown, and fires only from `NightSim.step` between the towers and the enemies. Two whole-feature-off probes failed 11 of 14 and 6 of 12 tests.
- **Touched mitigations re-checked:** T-02-01 (`test_sim_rules_guard.gd` green in the 817-test run; `castle_attack.gd` lies inside its scan roots; grep of `simulation/` for `Time.`, `OS.`, `time_scale` and global random is clean), T-02-12 (`_apply_dawn_payout` is still called once from `_enter_dawn` and now appends the castle entry after the building entries), T-02-13 (the results screen script is unchanged; the buttons moved under `ButtonsMargin` by `parent=` path only, and the 14 results-screen tests still press them after the grace).
- **T-02-17 / T-02-24:** `tools/prepush_check.sh` PASSED over all refs (608 commits, one author and committer identity, 24 tracked UI files among the scanned paths), including the 64 unpushed commits on `gsd/phase-01-foundation-day-loop`. Nothing was pushed in this run; the executor of 02-16 was told not to push, and the 02-16 plan forbids it.
- **Unregistered flags:** none new. The `gut-results` retention note from the first audit still stands as an open owner choice; `ci.yml` did not change in this run.
- **Tests:** full suite 817/817 (94 scripts), lint clean, at source `a483ff6`; smoke replay matches the golden; `bash tools/playtest.sh` prints `PLAYTEST_OK runs=50`.
