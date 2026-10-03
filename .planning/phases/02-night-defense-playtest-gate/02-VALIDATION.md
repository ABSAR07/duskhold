---
phase: "2"
slug: "night-defense-playtest-gate"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Estimated runtime** | quick ~16 s today (223 unit tests; grows with the new pure-simulation tests), full suite ~2–3 minutes |

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
| TBD | TBD | TBD | LOOP-01 | — | N/A | unit + e2e | `-gselect=test_run_manager.gd`, `-gselect=test_start_night_hold.gd` | ✅ (extend) | ⬜ pending |
| TBD | TBD | TBD | LOOP-02 | — | N/A | unit + e2e | `-gselect=test_wave_schedule.gd`, `-gselect=test_spawn_telegraph.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LOOP-03 | TBD (unbounded night) | A night always ends: every shipped night clears inside a tick budget | integration | `-gselect=test_night_loop.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LOOP-04 | — | N/A | unit | `-gselect=test_dawn_rebuild.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LOOP-05 | — | N/A | unit + e2e | `-gselect=test_dawn_rebuild.gd`, `-gselect=test_dawn_rebuilt_marker.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LOOP-06 | — | Loss is decided in the same step the castle falls; it beats a same-tick win | integration | `-gselect=test_run_outcomes.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LOOP-07 | — | N/A | integration | `-gselect=test_run_outcomes.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | KING-03 | — | N/A | unit | `-gselect=test_king_combat.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | KING-06 | — | N/A | unit | `-gselect=test_king_respawn.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BLDG-07 | — | N/A | unit + e2e | `-gselect=test_building_damage.gd`, `-gselect=test_building_rubble.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DEV-05 | TBD (CLI arguments and output path) | `--scenario` comes from a fixed list, `--seed` must be an integer, `--out` stays under `build/`; runs are bounded by `max_ticks` and `timeout` | integration + script | `-gselect=test_determinism.gd`, `-gselect=test_sim_rules_guard.gd`, `-gselect=test_sim_rng.gd`, `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | D-07 to D-10 (night data contract) | TBD (data caps) | `MapConfig.validate()` reports non-positive counts, negative delays, empty nights and over-cap enemy counts | unit | `-gselect=test_night_data_contract.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DEV-03 extension (overlay: enemy counts, wave state, paths) | T-01-15 (carried) | Overlay sections read state and never change it | unit | `-gselect=test_debug_overlay_night_sections.gd` | ❌ W0 | ⬜ pending |

Each `-gselect=` entry runs as `bash tools/test.sh -gselect=<file>`. Threat refs marked TBD are placeholders until the plans' `<threat_model>` blocks assign `T-02-NN` IDs.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/unit/test_sim_rules_guard.gd`, `test_sim_rng.gd`, `test_sim_clock.gd` — the determinism rules, in place before any combat code
- [ ] `tests/unit/test_night_data_contract.gd`, `test_wave_schedule.gd`
- [ ] `tests/unit/test_enemy_targeting.gd`, `test_tower_combat.gd`, `test_king_combat.gd`, `test_king_respawn.gd`, `test_building_damage.gd`, `test_dawn_rebuild.gd`
- [ ] `tests/integration/test_night_loop.gd`, `test_run_outcomes.gd`, `test_determinism.gd`, and `tests/golden/`
- [ ] `E2eSupport.waveless_prototype_map()` helper, and the Phase 1 placeholder-night tests moved onto it (file list in `02-RESEARCH.md`, Pitfall 2)
- [ ] `tests/support/sim_signals.gd` updated with every new `SimEvents` signal
- [ ] `tools/replay/*`, `tools/replay.sh`, `tools/playtest.sh`, and the replay step in `.github/workflows/ci.yml`

No framework install is needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tension, readability and gold trade-offs over full runs | Success criterion 4 (playtest gate), D-18 | A feel judgment that belongs to the owner | After the balance table and screenshots exist, the owner plays one or two full runs and either signs off or names the fixes. Recorded through `/gsd-verify-work`. |
| Night readability: enemies, health bars, projectiles, rubble and telegraph markers in the dark | LOOP-02, BLDG-07, KING-06 | Needs someone to look at the images | `bash tools/screenshot.sh` captures the new shots (spawn telegraph, night combat, building destroyed, dawn rebuilt, king-down countdown, results victory, results defeat, overlay paths). Claude reviews each for content first (D-18); the owner confirms during the one or two runs. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
