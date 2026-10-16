---
phase: "4"
slug: "crowd-scale-battles-walls"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-16"
validated: "2026-10-16"
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT 9.7.1 on Godot 4.7.2-stable (GDScript, headless), gdtoolkit 4.5.0 lint |
| **Config file** | `.gutconfig.json` (dirs `tests/unit`, `tests/integration`, `tests/e2e`; JUnit to `build/test-results/gut-junit.xml`) |
| **Quick run command** | `bash tools/test.sh -gselect=<test_script_substring>` (one selection per invocation) |
| **Full suite command** | `bash tools/test.sh` then `bash tools/lint.sh`; replays `bash tools/replay.sh --scenario=<smoke, army or walls> --twice --expect-file=tests/golden/<scenario>.json` and `--scenario=full_idle --twice` (unpinned); `bash tools/gate_stress.sh --twice`; real-window checks `bash tools/screenshot.sh` (37 shots) and `bash tools/stress.sh --runs=3 --duration=20` |
| **Estimated runtime** | quick run 20-90 s per script; full suite 617 s at wave 8 and about 10 min at the end of the phase (190 scripts, 1794 tests, 27554 asserts); lint 15 s; gate stress 40 s; screenshots about 8 min; stress night 3 runs about 2 min |

---

## Sampling Rate

- **After every task commit:** Run `bash tools/test.sh -gselect=<the task's scripts>` and, for anything under simulation/, the smoke, army and walls replays
- **After every plan wave:** Run `bash tools/test.sh` and `bash tools/lint.sh` (the orchestrator's post-merge gate, logged to build/test-results/postmerge_test_stdout.log)
- **Before `/gsd-verify-work`:** Full suite must be green (it is: 190 scripts, 1794 tests, 27554 asserts at a8c57ab; CI run 38959046206 green)
- **Max feedback latency:** 90 s for a single script; the full suite is accepted at about 10 minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | PLAT-01 | T-04-01 / T-04-02 | CrowdBatch caps instance writes at MAX_VIEWS 512 (DeathPuffBatch 128); views use read accessors only, the three replays stay byte-identical | tracer (unit + integration) | `bash tools/test.sh -gselect=test_crowd_batch`, `-gselect=test_enemy_views`, `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | ✅ | ✅ green |
| 4-01-02 | 01 | 1 | PLAT-01 | T-04-01 | Hurt-only bars and death puffs come from batches, no per-enemy nodes | unit (TDD) | `-gselect=test_health_bar_batch`, `-gselect=test_enemy_views` | ✅ | ✅ green |
| 4-02-01 | 02 | 2 | PLAT-01 | T-04-03 | MeshBaker bakes once per unit type; a unit past the batch cap is not drawn | tracer (unit + e2e) | `-gselect=test_mesh_baker`, `-gselect=test_unit_views` | ✅ | ✅ green |
| 4-02-02 | 02 | 2 | PLAT-01 | T-04-03 | A fixed 512-slot arrow ring allocated once; a shot past the cap is not drawn | unit (TDD) | `-gselect=test_projectile_vfx`, `-gselect=test_projectiles_visible` | ✅ | ✅ green |
| 4-02-03 | 02 | 2 | PLAT-01 | T-04-04 | ci.yml unchanged (`permissions: contents: read`, pinned SHAs); push with the credential-helper command only | e2e (real window + CI) | `bash tools/screenshot.sh` (33 shots then), CI run 38848480353 green on 3c8f69e | ✅ | ✅ green |
| 4-03-01 | 03 | 3 | PLAT-01 | T-04-05 / T-04-07 | StructureIndex equals the reference scan on seeded worlds with ties; step_bench allowlists two bounded flags (exit 64 otherwise) | tracer (unit + bench) | `-gselect=test_spatial_index`, `-gselect=test_stress_tool_args`, `bash tools/godot.sh --headless --path . -s res://tools/stress/step_bench.gd -- --enemies=300 --steps=30` | ✅ | ✅ green |
| 4-03-02 | 03 | 3 | PLAT-01 | T-04-05 / T-04-06 | EnemyIndex and the bucketed push-apart equal the reference copies; grids key only occupied cells | unit (TDD) | `-gselect=test_separation_grid`, `-gselect=test_crowd_read_view`, `-gselect=test_spatial_index` | ✅ | ✅ green |
| 4-04-01 | 04 | 4 | BLDG-10 | T-04-08 / T-04-09 | WallRunDef.expand rejects non-finite input and caps runs at 200 segments; walls and nav join the no-transcendental source scan | tracer (unit + integration) | `-gselect=test_wall_system`, `-gselect=test_wall_solids`, `-gselect=test_sim_rules_guard` | ✅ | ✅ green |
| 4-04-02 | 04 | 4 | BLDG-10 | T-04-10 | A static 4 m segment bucket grid bounds blocking candidates per query; dawn rebuilds every broken segment | unit + integration (TDD) | `-gselect=test_wall_blocking`, `-gselect=test_wall_dawn` | ✅ | ✅ green |
| 4-05-01 | 05 | 5 | BLDG-10 | T-04-11 | WallValidation reports non-finite numbers, short polylines, bad lengths and gaps under 3 m instead of arming them | tracer (unit) | `-gselect=test_prototype_map_walls`, `-gselect=test_map_wall_validation`, `-gselect=test_prototype_map_data` | ✅ | ✅ green |
| 4-05-02 | 05 | 5 | BLDG-10 | T-04-12 | Only already-logged Castle Kit files and primitives; test_attribution_log runs | unit + e2e (TDD) | `-gselect=test_wall_views`, `-gselect=test_shot_list`, `-gselect=test_attribution_log`, `bash tools/screenshot.sh walls_day` | ✅ | ✅ green |
| 4-06-01 | 06 | 6 | ENMY-04 | T-04-13 / T-04-14 / T-04-16 | NavGrid bounds come from map content plus a margin under MAX_NAV_CELLS; refresh() rebuilds at most once per step; nav joins the determinism scan | tracer (unit + integration) | `-gselect=test_nav_grid`, `-gselect=test_flow_field`, `-gselect=test_nav_tuning_contract`, `-gselect=test_wall_detour` | ✅ | ✅ green |
| 4-06-02 | 06 | 6 | ENMY-04 | T-04-15 / T-04-16 | GoalFieldCache bounds memory and builds per tick (1 to 32); LOS-gated targets drop what a wall hides | unit + integration (TDD) | `-gselect=test_goal_field_cache`, `-gselect=test_los_targets`, `-gselect=test_map_wall_validation` | ✅ | ✅ green |
| 4-07-01 | 07 | 7 | ENMY-04 | T-04-17 / T-04-18 | WallDecision uses 64-bit ints with MAX_TICKS clamps; one O(n) pass per tick over due segments | tracer (unit + integration) | `-gselect=test_wall_decision`, `-gselect=test_wall_behaviour`, `-gselect=test_nav_tuning_contract` | ✅ | ✅ green |
| 4-07-02 | 07 | 7 | ENMY-04 | T-04-19 | StuckTracker is read-only by construction and test (no SimEvents signal, no record writes); goldens unchanged | unit (TDD) | `-gselect=test_stuck_tracker`, `-gselect=test_debug_overlay_readonly`, the three replays | ✅ | ✅ green |
| 4-08-01 | 08 | 8 | ENMY-04 | T-04-20 / T-04-21 / T-04-23 | gate_stress_cli allowlists four flags with bounded --max-seconds; the CI step stops at 60 s of simulation; ci.yml keeps `contents: read` | tracer (integration + CI) | `-gselect=test_gate_stress`, `-gselect=test_stress_map_data`, `bash tools/gate_stress.sh --twice` | ✅ | ✅ green |
| 4-08-02 | 08 | 8 | ENMY-04 | T-04-22 | Stress tools live under tools/ (export-excluded); overlay sections read only | unit + e2e (TDD) | `-gselect=test_debug_overlay_crowd_sections`, `-gselect=test_overlay_field`, `bash tools/screenshot.sh overlay_field_gate` | ✅ | ✅ green |
| 4-09-01 | 09 | 9 | PLAT-01 | T-04-24 | StressNight, FrameReportCli and StepBench allowlist bounded integers and folders; usage errors exit 64 | tracer (unit + real window) | `-gselect=test_frame_report`, `-gselect=test_stress_tool_args`, `bash tools/stress.sh --runs=1` | ✅ | ✅ green |
| 4-09-02 | 09 | 9 | PLAT-01 | T-04-25 | Three runs, median by p95, vsync off, hardware and renderer recorded; the report's p95 equals the tool's line | e2e (real window) + unit | `bash tools/stress.sh --runs=3 --duration=20` (pass rule `FRAME_REPORT_OK ... within=true`), `-gselect=test_shot_list` | ✅ | ❌ red (within=false: p95 37.04 ms vs 8.0 ms; owner decision, see Manual-Only) |
| 4-10-01 | 10 | 10 | BLDG-10, ENMY-04 | T-04-26 / T-04-27 | The walls golden is a new file on a frozen fixture; smoke and army stay byte-identical; one replay line added to CI | tracer (integration + CI) | `-gselect=test_walls_replay_golden`, `-gselect=test_replay_cli_args`, `bash tools/replay.sh --scenario=walls --twice --expect-file=tests/golden/walls.json` | ✅ | ✅ green |
| 4-10-02 | 10 | 10 | BLDG-10, ENMY-04 | T-04-26 | Balance pins re-measured on 80 seeded runs; no night count or wall cost moved | integration + sweep | `bash tools/playtest.sh --seeds=10`, `-gselect=test_balance_acceptance`, `-gselect=test_balance_report`, `-gselect=test_playtest_strategies` | ✅ | ✅ green |
| 4-11-01 | 11 | 11 | BLDG-10, ENMY-04, PLAT-01 | T-04-29 | The export excludes tests/, addons/gut/ and tools/ | tracer (suite + replays + e2e) | `bash tools/test.sh`, the four replays, `bash tools/gate_stress.sh --twice`, `bash tools/screenshot.sh`, `bash tools/lint.sh` | ✅ | ✅ green |
| 4-11-02 | 11 | 11 | BLDG-10, ENMY-04, PLAT-01 | T-04-28 | prepush_check.sh before the push; the credential-helper push command only; at most the screenshots timeout may change in ci.yml | CI | `bash tools/prepush_check.sh`; CI run 38959046206 green on a8c57ab (lint, test, export, screenshots) | ✅ | ✅ green |
| 4-11-03 | 11 | 11 | BLDG-10, ENMY-04, PLAT-01 | T-04-29 | Launch check of the export; the packet quotes the committed reports | e2e (export) + human-check | `bash tools/export.sh`; `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` | ✅ | ✅ green (owner feel check pending, /gsd-verify-work 4) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Every plan's Task 1 is a tracer with an automated verify on the committed tree; no stubs or Wave 0 installs were needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The frame budget verdict (04-09): PLAT-01 is NOT met on the dev machine, median-run p95 37.04 ms against 8.0 ms with 300 enemies, 50 units and 239 arrows in view; the automated check exists and runs (`bash tools/stress.sh --runs=3 --duration=20` prints `FRAME_REPORT_OK ... within=false`) but no test can turn it green | PLAT-01 | The gap is in the simulation step (18 to 25 ms), not in test coverage; the plan's stop rule hands the route to the owner (GDExtension, a documented higher budget, or an optimisation plan), recorded in 04-FRAME-REPORT.md and 04-PLAYTEST-GATE.md; the owner decided 2026-10-16 to run the gate on the missed budget | Decide the route at `/gsd-verify-work 4`; re-run `bash tools/stress.sh --runs=3 --duration=20` after the chosen change and read `within=true` |
| Wall-break rebuild hitch (04-06 accepted, 04-09 measured 11.74 ms mean, 13.22 ms max) | PLAT-01 | Whether a dropped frame on a wall break is acceptable, or count-based time slicing (a rule change) is wanted, is the owner's call | Break a wall in play and watch for the hitch; decide in the packet |
| Walls and barricades worth their gold and readable by tier; gates funnel enemies into towers (D-15 feel half) | BLDG-10 | Feel and visual judgement; the bots buy walls only late (15 to 22 gold a run) | Play two or three full runs buying walls (04-PLAYTEST-GATE.md "What to judge") |
| Break-or-go-around looks smart; squads and the king get round walls cleanly | ENMY-04 | Feel; the army bot still loses 4 seeds with free walls (suspected: squads following the king round walls) | Watch a night with a long wall and a gap; select a squad and send it through |
| The stress night feels smooth and the crowd reads; the drawn flow field, stuck posts and two-column overlay read well (coverage item D7, 04-08) | PLAT-01, ENMY-04 | Visual judgement in a real window | Run `tools/stress/stress_night.tscn` from the editor binary; toggle the F3 overlay |
| Thin palisade with tier I and II alike from the riding camera, long wall shadows, dark night ground, small enemies from the stress camera (04-11 screenshot review) | BLDG-10 | Readability points left for Phase 8 (UI-05) | Open `walls_day.png`, `walls_night_breach.png`, `crowd_stress_night.png` from the CI artifact |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (24 of 24 tasks; 04-11 Task 3 also carries the owner's `<human-check>`)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none)
- [x] No watch-mode flags (GUT runs with `-gexit`)
- [x] Feedback latency within the project's accepted bound (single script under 90 s; full suite about 10 min)
- [ ] `nyquist_compliant: true` set in frontmatter (left `false`: 4-09-02's automated check is red by the plan's own rule, PLAT-01 is not met, and the resolution is an owner decision, not a test)

**Approval:** validated 2026-10-16 (validate-phase audit, state A) as PARTIAL: 23 of 24 task checks green, 1 red by design pending the owner's PLAT-01 route

## Validation Audit 2026-10-16
| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 0 |
| Escalated | 1 |

Audit basis: 11 PLAN and 11 SUMMARY files (04-09 `status: halted`), the per-plan test scripts listed in each SUMMARY's `key-files`, the ten post-merge gate runs (157/1456 tests at wave 1 to 190/1794 at wave 10), the final full suite at a8c57ab (190 scripts, 1794 tests, 27554 asserts, lint clean on 334 files), the four replays byte-identical to their digests, `GATE_OK enemies=300 crossed=300 stuck=0`, 37 real-window screenshots, CI run 38959046206 green. The one gap is 4-09-02 (PLAT-01, PARTIAL: the automated check exists and fails for a measured reason); it is escalated to the owner as a decision, not to the auditor, because no test change can resolve it and the auditor never modifies implementation files. No auditor spawn was needed.
