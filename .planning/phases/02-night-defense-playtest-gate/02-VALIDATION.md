---
phase: "2"
slug: "night-defense-playtest-gate"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: true) (#2117)
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-03"
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `02-RESEARCH.md` § Validation Architecture. Task IDs, plans and waves are filled in once the plans exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT (Godot Unit Test) 9.7.1 on Godot 4.7.2-stable (standard build), run headless |
| **Config file** | `.gutconfig.json` (exists: `res://tests/unit/`, `res://tests/integration/`, `res://tests/e2e/`, JUnit to `res://build/test-results/gut-junit.xml`) |
| **Quick run command** | `bash tools/test.sh -gdir=res://tests/unit` |
| **Full suite command** | `bash tools/test.sh && bash tools/lint.sh` |
| **Estimated runtime** | quick ~15 s of test time plus import (471 unit tests at the audit); full suite ~4.5 minutes (745 tests in 86 scripts after review-fix pass 2; about 240 s of GUT time) |

Other commands this phase adds or reuses:

| Purpose | Command |
|---------|---------|
| Single test file | `bash tools/test.sh -gselect=test_<name>.gd` |
| Seeded replay, double run against the golden (new, DEV-05) | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` |
| Balance report for the playtest gate (new, local only, not a CI gate) | `bash tools/playtest.sh` |
| Screenshots (real renderer) | `bash tools/screenshot.sh [shot]` |

The wrappers under `tools/` are Git Bash scripts and resolve the pinned Godot binary themselves. Two rules carried over from Phase 1:

- A partial run (`-gdir=`, `-gselect=`) overwrites `build/test-results/gut-junit.xml`. A verify command that greps the JUnit file for a test name must run the full `bash tools/test.sh` first.
- Screenshots never run under `--headless` (the runner exits 2 there); a headless capture would be blank.

A command-line script run with `-s` exits 0 even after a script runtime error (probed in the research). The replay and playtest wrappers therefore count as passing only when their sentinel line was printed, no `SCRIPT ERROR` appears in the output, and the run finished inside its `timeout`.

---

## Sampling Rate

- **After every task commit:** Run the quick run command, plus the task's own new test file with `-gselect=`
- **After every plan wave:** Run the full suite command; once `tools/replay.sh` exists, also `bash tools/replay.sh --scenario=smoke --twice`
- **Before `/gsd-verify-work`:** Full suite green, lint clean, replay double run green and matching the golden, the new screenshots captured and not blank, and the balance report generated
- **Max feedback latency:** 60 seconds (quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-08-T1 | 02-08 | 4 | LOOP-01 | — | N/A | unit + integration + e2e | `-gselect=test_run_manager.gd`, `-gselect=test_no_day_timer.gd`, `-gselect=test_start_night_hold.gd` | ✅ | ✅ green |
| 02-08-T1 | 02-08 | 4 | LOOP-02 | — | N/A | unit + e2e | `-gselect=test_wave_schedule.gd`, `-gselect=test_spawn_telegraph_place.gd`, `-gselect=test_spawn_telegraph.gd` | ✅ | ✅ green |
| 02-01-T1, 02-10-T2 | 02-01, 02-10 | 1, 9 | LOOP-03 | T-02-02, T-02-21 | A night always ends: every shipped night clears inside a tick budget | integration | `-gselect=test_night_loop.gd`, `-gselect=test_prototype_nights.gd`, `-gselect=test_every_night_ends.gd` | ✅ | ✅ green |
| 02-06-T1 | 02-06 | 6 | LOOP-04 | T-02-12 | Rebuild is free and happens once per dawn | unit | `-gselect=test_dawn_rebuild.gd` | ✅ | ✅ green |
| 02-06-T1, 02-06-T2 | 02-06 | 6 | LOOP-05 | T-02-12 | A rebuilt building pays nothing that dawn | unit + e2e | `-gselect=test_dawn_rebuild.gd`, `-gselect=test_dawn_rebuilt_marker.gd` | ✅ | ✅ green |
| 02-07-T1 | 02-07 | 7 | LOOP-06 | T-02-14 | Loss is decided in the same step the castle falls; it beats a same-tick win | integration + e2e | `-gselect=test_run_outcomes.gd`, `-gselect=test_results_screen.gd` | ✅ | ✅ green |
| 02-07-T1, 02-10-T2 | 02-07, 02-10 | 7, 9 | LOOP-07 | T-02-14 | Terminal phases never transition again | integration + unit | `-gselect=test_run_outcomes.gd`, `-gselect=test_run_stats.gd`, `-gselect=test_balance_report.gd` | ✅ | ✅ green |
| 02-01-T1, 02-05-T1, 02-05-T2 | 02-01, 02-05 | 1, 5 | KING-03 | T-02-10 | Projectile and puppet node counts are capped | unit + e2e | `-gselect=test_king_combat.gd`, `-gselect=test_tower_combat.gd`, `-gselect=test_projectile_vfx.gd`, `-gselect=test_projectiles_visible.gd` | ✅ | ✅ green |
| 02-03-T2, 02-03-T3, 02-10-T2 | 02-03, 02-10 | 3, 9 | KING-06 | T-02-06, T-02-07 | Respawn tuning is sanitised and capped; the King node never writes simulation state | unit + integration + e2e | `-gselect=test_king_respawn.gd`, `-gselect=test_king_sturdiness.gd`, `-gselect=test_king_knockout.gd` | ✅ | ✅ green |
| 02-04-T1, 02-04-T2 | 02-04 | 4 | BLDG-07 | T-02-08 | `MapConfig.validate()` reports a tier with non-positive health | unit + e2e | `-gselect=test_building_damage.gd`, `-gselect=test_building_targeting.gd`, `-gselect=test_building_rubble.gd` | ✅ | ✅ green |
| 02-01-T1, 02-01-T2, 02-09-T1, 02-09-T2 | 02-01, 02-09 | 1, 8 | DEV-05 | T-02-01, T-02-18, T-02-19 | `--scenario` comes from a fixed list, `--seed` must be an integer, `--out` stays under `build/`; runs are bounded by `max_ticks` and `timeout` | unit + integration + script + CI | `-gselect=test_determinism.gd`, `-gselect=test_sim_rules_guard.gd`, `-gselect=test_sim_rng.gd`, `-gselect=test_sim_clock.gd`, `-gselect=test_replay_cli_args.gd`, `-gselect=test_replay_golden.gd`, `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | ✅ | ✅ green |
| 02-02-T1, 02-02-T2, 02-05-T1 | 02-02, 02-05 | 2, 5 | D-07 to D-10 (night data contract) | T-02-04 | `MapConfig.validate()` reports non-positive counts, negative delays, empty nights and over-cap enemy counts | unit | `-gselect=test_night_data_contract.gd`, `-gselect=test_map_validate_nights.gd` | ✅ | ✅ green |
| 02-08-T2 | 02-08 | 4 | DEV-03 extension (overlay: enemy counts, wave state, paths) | T-02-15, T-02-16 | Overlay sections read state and never change it | unit + e2e | `-gselect=test_debug_overlay_night_sections.gd`, `-gselect=test_overlay_paths.gd` | ✅ | ✅ green |
| WR-01 fix (pass 1) | review | — | LOOP-03, D-07 to D-10 (night data contract) | T-02-04 | `MapConfig.validate()` reports an enemy that could never attack (aggro range not above attack range), one that gives up before it notices, a bodiless or never-rescanning enemy, negative ranges and projectile speeds, a castle with no radius, and a tower tier with a non-positive attack interval or negative range or projectile speed; shipped data reports nothing (each rule fails one test under an orchestrator mutation probe) | unit | `-gselect=test_map_validate_enemies.gd` (12 tests, new file) | ✅ | ✅ green |
| WR-02 fix (pass 1) | review | — | LOOP-03, D-07 to D-10 (night data contract) | T-02-04 | A night never spawns more than `MapConfig.MAX_ENEMIES_PER_NIGHT` (300): the groups share one budget in group order, and the spawn preview counts the same capped numbers (fails under three orchestrator mutation probes) | unit | `-gselect=test_wave_schedule.gd` (13 tests; four added by the fix) | ✅ | ✅ green |
| WR-03 fix (pass 1) | review | — | LOOP-06, LOOP-07 (results screen, D-16) | T-02-13 | For `results_input_grace_seconds` (0.6 s shipped) after the results screen appears, no press from any device presses Play again or Quit; afterwards keyboard, gamepad and mouse all work; the shipped value stays between 0.3 and 1.0 s (fails under five orchestrator mutation probes) | e2e + unit | `-gselect=test_results_screen.gd` (9 tests; two added), `-gselect=test_loop_tuning_contract.gd` (11 tests; one added) | ✅ | ✅ green |
| WR-01 fix (pass 2) | review | — | LOOP-06, LOOP-07 (results screen, D-16) | T-02-13 | A press on Play again or Quit counts only if it BEGAN after the grace window as well as being released after it: a press begun inside the window and released after it does nothing, a fresh press after it works, on keyboard, gamepad and mouse, on Defeat and Victory (fails under two orchestrator mutation probes) | e2e | `-gselect=test_results_screen.gd` (14 tests; four added) | ✅ | ✅ green |
| WR-02 fix (pass 2) | review | — | LOOP-06, LOOP-07 (results screen, D-16) | T-02-13 | Test hardening only: the grace tests use their own 3.0 s window instead of the shipped 0.6 s, judge "inside the window" after the taps, and report a stalled runner as `pending` instead of failing; no behaviour to mutate | e2e | `-gselect=test_results_screen.gd` | ✅ | ✅ green (no `pending` in the full run) |
| IN-01, IN-02 fix (pass 2) | review | — | LOOP-02, D-07 to D-10 (night data contract) | T-02-04 | The spawn preview skips exactly the groups the schedule skips (unknown enemy as well as unknown spawn point) and spends the night budget identically; the night budget is the only cap (fails under two orchestrator mutation probes) | unit | `-gselect=test_wave_schedule.gd` (15 tests; two added) | ✅ | ✅ green |
| IN-03 fix (pass 2) | review | — | LOOP-06, LOOP-07 (results screen, D-16) | T-02-13 | The shipped grace is written in `loop_tuning.tres` itself: deleting the line fails the contract test (the pass-1 mutation survivor, now caught) | unit | `-gselect=test_loop_tuning_contract.gd` (11 tests; one extended) | ✅ | ✅ green |
| IN-04 fix (pass 2) | review | — | LOOP-06, LOOP-07 (results screen, D-16) | T-02-13 | The grace is clamped to `ResultsScreen.MAX_GRACE_S` (3 s): with a 600 s data value the buttons accept presses once the cap is over (fails under one orchestrator mutation probe) | e2e | `-gselect=test_results_screen.gd` (one added) | ✅ | ✅ green |

Each `-gselect=` entry runs as `bash tools/test.sh -gselect=<file>`. Threat refs are the `T-02-NN` IDs from the plans' `<threat_model>` blocks. Task IDs read `<plan>-T<task number>`.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `tests/unit/test_sim_rules_guard.gd`, `test_sim_rng.gd`, `test_sim_clock.gd` — the determinism rules, in place before any combat code
- [x] `tests/unit/test_night_data_contract.gd`, `test_wave_schedule.gd`
- [x] `tests/unit/test_enemy_targeting.gd`, `test_tower_combat.gd`, `test_king_combat.gd`, `test_king_respawn.gd`, `test_building_damage.gd`, `test_dawn_rebuild.gd`
- [x] `tests/integration/test_night_loop.gd`, `test_run_outcomes.gd`, `test_determinism.gd`, and `tests/golden/`
- [x] `E2eSupport.waveless_prototype_map()` helper, and the Phase 1 placeholder-night tests moved onto it (file list in `02-RESEARCH.md`, Pitfall 2)
- [x] `tests/support/sim_signals.gd` updated with every new `SimEvents` signal
- [x] `tools/replay/*`, `tools/replay.sh`, `tools/playtest.sh`, and the replay step in `.github/workflows/ci.yml`

No framework install is needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tension, readability and gold trade-offs over full runs | Success criterion 4 (playtest gate), D-18 | A feel judgment that belongs to the owner | After the balance table and screenshots exist, the owner plays one or two full runs and either signs off or names the fixes. Recorded through `/gsd-verify-work`. |
| Night readability: enemies, health bars, projectiles, rubble and telegraph markers in the dark | LOOP-02, BLDG-07, KING-06 | Needs someone to look at the images | `bash tools/screenshot.sh` captures the new shots (spawn telegraph, night combat, building destroyed, dawn rebuilt, king-down countdown, results victory, results defeat, overlay paths). Claude reviews each for content first (D-18); the owner confirms during the one or two runs. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant` set in frontmatter (`false`: the two manual-only rows above belong to the owner's playtest gate and cannot be automated, so the phase reads PARTIAL by design)

**Approval:** validated 2026-10-05 (automated coverage; the two manual-only rows stay with the owner's playtest gate); re-validated 2026-10-05 and 2026-10-06 after review-fix passes 1 and 2

---

## Validation Audit 2026-10-05

Audit run by `/gsd-validate-phase 2` after all 11 plans executed, at commit 7499e21. Every requirement row was matched to its test files in the JUnit XML of a full `bash tools/test.sh` run (719 tests in 85 scripts, 0 failures) and lint was clean. The replay double run matched the golden digest locally and in CI run 37325147907.

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Notes:

- All 13 rows are COVERED. Every listed test file exists and is green; several rows gained files beyond the seeded ones (for example `test_no_day_timer.gd`, `test_every_night_ends.gd`, `test_building_targeting.gd`, `test_replay_golden.gd`).
- Ten of the eleven plans ran test-first (a RED commit before each GREEN commit). The executors of 02-03, 02-04, 02-05, 02-06 and 02-08 each reported a mutation probe that their tests caught; 02-07 reported none. This audit did not run its own mutation probes.
- The two Manual-Only rows are unchanged. The screenshot review was done by Claude in plan 02-11; the owner's playtest is still open and is recorded through `/gsd-verify-work`.

---

## Validation Audit 2026-10-05 (re-audit after review-fix pass 1)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the first review-fix pass (3 commits, `c6bb202`, `ef8ca58` and `6057fd1`), which closed the three warnings of the 2026-10-05 review. It touched `simulation/defs/map_config.gd`, `simulation/night/wave_schedule.gd`, `simulation/defs/loop_tuning.gd`, `data/tuning/loop_tuning.tres` and `ui/results/results_screen.gd`, added `tests/unit/test_map_validate_enemies.gd` and extended three test suites. All 13 rows of the per-task map are still COVERED, and three rows were added for the fixes.

- **Mutation probes (orchestrator):** 19 single-line mutations, each run against the fix's own test file and restored from a backup. 18 were caught; 1 survived and is an equivalent change, not a gap.
  - WR-01 (`test_map_validate_enemies.gd`): the aggro boundary (`<=` to `<`) and each of the nine other new rules switched off, one at a time (leash below aggro, enemy radius, negative enemy attack range, retarget interval, negative enemy projectile speed, castle radius, and the tower tier's attack range, attack interval and projectile speed). Each fails exactly one test.
  - WR-02 (`test_wave_schedule.gd`): with the budget never spent (`budget -= 0`) 2 tests fail; with the preview back to the uncapped per-group count 1 fails; with the schedule spawning one more than its allowance 5 fail.
  - WR-03 (`test_results_screen.gd`, `test_loop_tuning_contract.gd`): with `accepts_input()` ignoring the deadline 2 tests fail; with only the Quit handler ungated 1 fails; with only the Play again handler ungated 2 fail; with the shipped value set to 0 the contract test fails (1) and so does the victory test that uses the shipped window (1).
  - **Survivor:** deleting the `results_input_grace_seconds = 0.6` line from `loop_tuning.tres` leaves `test_loop_tuning_contract.gd` green. The script default is the same 0.6, so the loaded value and the game's behaviour do not change, and Godot itself drops a default-equal property when the resource is re-saved from the editor. The test is named "...is_set_in_the_data_file_and_short", but what it pins is that the field is a stored export and that the loaded shipped value is between 0.3 and 1.0 s. The older respawn-field test in the same file works the same way. Recorded as an observation for the code review, not as a coverage gap.
- **Tests:** +19, from 719 to 738 (86 scripts). `test_map_validate_enemies` is new with 12; `test_wave_schedule` 9 → 13; `test_results_screen` 7 → 9; `test_loop_tuning_contract` 10 → 11.
- **Replays:** the smoke replay still matches the golden digest (`2599c7c2...`) and the full run still wins in 6244 ticks (`a25aa7fd...`), so the two simulation-side fixes changed nothing on valid data.
- **Wall-clock note:** the two new results-screen tests wait on a real-time window (1 s in the defeat test, the shipped 0.6 s in the victory test) and tap inside it. Three consecutive runs of the suite gave identical assertion counts and times within 0.1 s. The total assertion count of the full suite differed by 4 between two runs at the same source (8580 and 8576); the difference is not in `test_results_screen` and was not located.
- **Manual:** unchanged. The owner still judges the end-of-run tap by feel in the playtest (UAT item 2).

Evidence:
- Full suite 738/738 (86 scripts, ~270 s GUT time) at `be5ff16` (source as at `6057fd1`); lint clean (156 files).
- Unit tests: 488, about 17 s of test time.

---

## Validation Audit 2026-10-06 (re-audit after review-fix pass 2)

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 0 |
| Escalated | 1 (to the review-fix loop: third review WR-01) |

Re-audited after the second review-fix pass (3 commits, `21b8abb`, `260ec31` and `81c300e`), which closed all six findings of the 2026-10-05 second review (2 warnings, 4 info). It touched `simulation/night/wave_schedule.gd`, `ui/results/results_screen.gd`, `tests/unit/test_wave_schedule.gd`, `tests/unit/test_loop_tuning_contract.gd` and `tests/e2e/test_results_screen.gd`; no data file changed. All 16 rows of the per-task map are still COVERED, and five rows were added for the fixes.

- **Mutation probes (orchestrator):** 7 single-line mutations, each run against the fix's own test file and restored from a backup. 6 were caught; 1 survived (see the addendum below).
  - WR-01 (`test_results_screen.gd`): with the press-start stamp ignored (the gate back to `accepts_input()` alone) the four straddling-press tests fail; with `button_down` never stamping 8 tests fail, because every press is then ignored.
  - IN-04 (`test_results_screen.gd`): with the clamp from below only (`maxf` instead of `clampf`) the 600 s grace test fails.
  - IN-01 (`test_wave_schedule.gd`): with the preview and the schedule no longer requiring a known enemy the unknown-enemy preview test fails.
  - IN-02 (`test_wave_schedule.gd`): with the dead `MAX_GROUP_COUNT` constant re-added its absence test fails.
  - IN-03 (`test_loop_tuning_contract.gd`): deleting the `results_input_grace_seconds = 0.6` line from `loop_tuning.tres` now fails the contract test. This was the one survivor of the pass-1 probes.
  - WR-02 is a test-only change and has no behaviour to mutate, but its `pending()` escape is what lets the seventh probe survive.
  - **Survivor (addendum, after the third review):** with the grace never applied (`grace_ms` forced to 0 in `_show_results`) `test_results_screen.gd` still passes: the seven grace and straddling-press tests end `pending` ("the runner stalled past the grace window") because `accepts_input()` is true at once, the capped-grace test passes with no grace at all, and `tools/test.sh` exits 0 on pending tests. So the accidental-restart bug (first review WR-03) could return with CI green. The third review reports this as its WR-01 with a fix (assert `accepts_input()` is false right after the screen shows, keep `pending()` only for a genuine stall); it is escalated to the review-fix loop rather than to a nyquist-auditor run, since the fix belongs to the test file the loop already owns.
- **Tests:** +7, from 738 to 745 (86 scripts). `test_results_screen` 9 → 14 (four straddling-press tests and the capped-grace test); `test_wave_schedule` 13 → 15; `test_loop_tuning_contract` stays at 11 with one test extended. No test ended `pending` in the full run.
- **Replays:** the smoke replay still matches the golden digest (`2599c7c2...`) and the full run still wins in 6244 ticks (`a25aa7fd...`), so the wave-schedule change altered nothing on valid data.
- **Wall-clock note:** the grace tests no longer depend on the shipped 0.6 s window. Each uses a 3.0 s window of its own (`TEST_GRACE_S`, equal to the cap so it is never clamped), judges "inside the window" after the taps, and calls `pending()` if the runner had already passed the window. `test_results_screen.gd` takes about 36 s of GUT time, most of it waiting out those windows.
- **Manual:** unchanged. The owner still judges the end-of-run tap by feel in the playtest (UAT item 2); the held-press case that item asked the owner to judge is now ignored by the code.

Evidence:
- Full suite 745/745 (86 scripts, about 240 s of GUT time) at `bcbb712` (source as at `81c300e`); lint clean.
- Unit tests: 490, about 13 s of test time.
