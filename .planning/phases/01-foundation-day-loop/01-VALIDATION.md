---
phase: "1"
slug: "foundation-day-loop"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-29"
validated: "2026-09-29"
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `01-RESEARCH.md` § Validation Architecture, then audited against the executed plans on 2026-09-29 (after the code-review fixes).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT (Godot Unit Test) 9.7.1 on Godot 4.7.2-stable (standard build), run headless |
| **Config file** | `.gutconfig.json` (dirs `tests/unit`, `tests/integration`, `tests/e2e`; JUnit XML to `build/test-results/gut-junit.xml`) |
| **Quick run command** | `bash tools/test.sh -gdir=res://tests/unit` |
| **Full suite command** | `bash tools/test.sh` (headless import pass, then GUT over all three dirs; fails on any first-party parse/load error) |
| **Single file** | `bash tools/test.sh -gselect=<test_file>.gd` |
| **Lint** | `bash tools/lint.sh` (gdtoolkit 4.5.0: `gdformat --check` + `gdlint`) |
| **Measured runtime** | Quick: ~12 s wall (16 scripts, 132 tests). Full: ~85 s wall (31 scripts, 218 tests) |

The `tools/*.sh` wrappers need Git Bash on Windows; they resolve the pinned binary under `.tools/godot/4.7.2-stable/` (D-14).

Screenshots (DEV-04) use a different mode: a real rendering driver (a normal window locally, `xvfb-run` with the Compatibility renderer in CI). `tools/screenshot/shot_runner.tscn` refuses to run under `--headless` (exit 2) because that mode produces blank images without an error.

---

## Sampling Rate

- **After every task commit:** Run the quick run command (unit tests, ~12 s)
- **After every plan wave:** Run the full suite command plus `bash tools/lint.sh`
- **Before `/gsd-verify-work`:** Full suite green, lint clean, and the six DEV-04 screenshots captured and non-blank
- **Max feedback latency:** 60 seconds per commit (quick run ~12 s). The full suite (~85 s) runs per wave, not per commit.

---

## Per-Task Verification Map

GUT rows run as `bash tools/test.sh -gselect=<file>`. Threat refs are the plans' `<threat_model>` IDs.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-T1 | 01-01 | 1 | DEV-01 | T-01-02, T-01-03 | No download without owner consent; tool caches and local settings git-ignored | script (one-time, pre-install) | `python tools/bootstrap.py --dry-run` + `git check-ignore` asserts (01-01 Task 1 verify) | ✅ | ✅ green (at execution; asserts a pre-install state, so not re-runnable) |
| 01-01-T3 | 01-01 | 1 | DEV-01 | T-01-01 | Godot and export templates SHA512-verified before install | unit + lint | `test_toolchain_smoke.gd` + `bash tools/lint.sh` | ✅ | ✅ green |
| 01-02-T1 | 01-02 | 2 | KING-01, BLDG-01, BLDG-03, ECON-01 | T-01-04 | Build applied only after CommandProcessor re-validation | e2e | `test_walking_skeleton.gd` | ✅ | ✅ green |
| 01-02-T2 | 01-02 | 2 | BLDG-03, ECON-01, DEV-01 | T-01-04 | Gold never goes negative; refused spends change nothing | integration + unit (no scene tree) | `test_build_flow.gd`, `test_economy_gold.gd` | ✅ | ✅ green |
| 01-03-T1 | 01-03 | 3 | DEV-02 | T-01-06, T-01-07 | Pre-push gate blocks credentials and tool caches; CI token is read-only | script | `bash tools/export.sh` + `build/windows/Duskhold.exe --headless --quit-after 120` + `ci.yml` jobs/permissions assert + `bash tools/prepush_check.sh` | ✅ | ✅ green (re-run 2026-09-29) |
| 01-03-T3 | 01-03 | 3 | DEV-02 | T-01-17 | Only approved content pushed | CI | `gh run list --workflow ci.yml` conclusion + `duskhold-windows` artifact | ✅ | ✅ green (last CI run on `981e4c8`; the review-fix commits are not pushed yet) |
| 01-04-T1 | 01-04 | 3 | KING-01 | T-01-09 | Input Map contract fixed by test | unit | `test_input_map.gd`, `test_king_movement_config.gd` | ✅ | ✅ green |
| 01-04-T2 | 01-04 | 3 | KING-01, KING-02 | — | N/A | e2e | `test_king_ride.gd` | ✅ | ✅ green |
| 01-05-T1 | 01-05 | 3 | BLDG-01, BLDG-02 | T-01-10 | `MapConfig.validate()` reports bad map data | unit | `test_prototype_map_data.gd`, `test_build_spot.gd`, `test_build_spot_affordability.gd` | ✅ | ✅ green |
| 01-05-T2 | 01-05 | 3 | BLDG-04 | T-01-04 | Upgrade applied only after re-validation; max tier rejected | integration + e2e | `test_upgrade_flow.gd`, `test_upgrade_at_spot.gd` | ✅ | ✅ green |
| 01-06-T1 | 01-06 | 4 | BLDG-03 | T-01-05, T-01-11 | No partial payment persists; refund on release, leaving range or night | integration + e2e | `test_build_hold_refund.gd`, `test_build_denied.gd` | ✅ | ✅ green |
| 01-06-T2 | 01-06 | 4 | BLDG-02, BLDG-04 | — | N/A | unit + e2e | `test_spot_label_model.gd`, `test_spot_label.gd` | ✅ | ✅ green |
| 01-06-T3 | 01-06 | 4 | BLDG-03, ECON-01 | — | HUD shows gold minus coins in flight, restores on refund | e2e | `test_coin_drip.gd` | ✅ | ✅ green |
| 01-07-T1 | 01-07 | 4 | ART-02 | T-01-12 | Only allow-listed licences; every third-party file logged exactly once | unit | `test_attribution_log.gd`, `test_building_view_catalog.gd` | ✅ | ✅ green |
| 01-07-T3 | 01-07 | 4 | ART-02 | T-01-12, T-01-13 | Imported models logged with archive SHA256 | unit + e2e | `test_attribution_log.gd`, `test_building_models.gd` | ✅ | ✅ green |
| 01-08-T1 | 01-08 | 4 | DEV-03 | T-01-15 | Overlay reads state, never mutates it (200-collect snapshot) | unit | `test_debug_overlay_readonly.gd` | ✅ | ✅ green |
| 01-08-T2 | 01-08 | 4 | DEV-03 | T-01-15 | — | e2e | `test_debug_overlay_toggle.gd` | ✅ | ✅ green |
| 01-09-T1 | 01-09 | 5 | BLDG-06 | T-01-14 | Build/upgrade rejected outside DAY, checked when applied; RunManager is the only phase writer | unit | `test_run_manager.gd`, `test_build_phase_guard.gd` | ✅ | ✅ green |
| 01-09-T2 | 01-09 | 5 | ECON-02, ECON-07 | T-01-14 | Dawn income exact per tier; gold carries over exactly | unit + integration | `test_dawn_income.gd`, `test_loop_gold_carryover.gd` | ✅ | ✅ green |
| 01-09-T3 | 01-09 | 5 | BLDG-06, ECON-01 | — | Start-night needs a fresh deliberate hold | e2e | `test_start_night_hold.gd` | ✅ | ✅ green |
| 01-10-T1 | 01-10 | 6 | ECON-01, ECON-02 | — | Payout VFX is display-only; HUD settles exactly on ledger gold | e2e | `test_dawn_payout.gd` | ✅ | ✅ green |
| 01-10-T2 | 01-10 | 6 | DEV-04 | — | Never captures under `--headless` (exit 2); blank frames fail | screenshot + unit | `bash tools/screenshot.sh` (6 PNGs) + headless guard exit 2 + `test_shot_blank_check.gd` | ✅ | ✅ green (re-run 2026-09-29) |
| 01-10-T3 | 01-10 | 6 | DEV-02, DEV-04 | T-01-16 | Screenshot artifact holds game images only | CI | `ci.yml` `screenshots` job needs `test` + CI run conclusion + artifacts | ✅ | ✅ green (last CI run on `981e4c8`) |
| WR-01 fix | review | — | BLDG-01, ECON-01 | — | One map's binding never reaches another map's views or HUD | e2e | `test_map_binding.gd` | ✅ | ✅ green |
| CR-01 fix (pass 2) | review | — | ECON-02 | — | Every dawn coin lands inside a short dawn window on a real payout | e2e | `test_dawn_payout.gd` (`test_a_real_payout_lands_every_coin_inside_a_short_dawn_window`) | ✅ | ✅ green |
| WR-01 fix (pass 2) | review | — | BLDG-01 | T-01-10 | Empty building ids reported; null map entries skipped instead of crashing | unit | `test_prototype_map_data.gd` (2 tests) | ✅ | ✅ green |
| WR-02 fix (pass 2) | review | — | ECON-01 | — | A payout with no coin to fly never leaves the HUD gold short | e2e | `test_dawn_payout.gd` (`test_a_payout_with_no_coin_to_fly_does_not_leave_the_hud_short`) | ✅ | ✅ green |
| WR-03 fix (pass 2) | review | — | DEV-03 | T-01-15 | A provider returning a non-Array is skipped, not a crash | unit | `test_debug_overlay_readonly.gd` | ✅ | ✅ green |
| WR-01 fix (pass 3) | review | — | ECON-01, ECON-02 | — | A payout naming an unknown spot still lands its coin and settles the HUD | e2e | `test_dawn_payout.gd` (`test_a_payout_naming_an_unknown_spot_still_lands_its_coin_and_settles_the_hud`) | ✅ | ✅ green |
| WR-02 fix (pass 3) | review | — | BLDG-01, ECON-02 | T-01-10 | Duplicate spot id listed once (first definition wins); unknown building id skipped in dawn income | unit | `test_building_system_data_errors.gd` (2 tests) | ✅ | ✅ green |
| WR-03 / IN-03 fix (pass 3) | review | — | DEV-03 | T-01-15 | Malformed provider rows dropped; the read-only test watches every simulation signal | unit | `test_debug_overlay_readonly.gd` (2 tests) | ✅ | ✅ green |
| IN-01 fix (pass 3) | review | — | ECON-01 | — | Binding the HUD twice connects nothing twice | e2e | `test_map_binding.gd` (`test_binding_the_hud_again_connects_nothing_twice`) | ✅ | ✅ green |
| IN-02 fix (pass 3) | review | — | BLDG-06 (start-night input) | — | The start-night prompt names the live bindings and follows a runtime rebind | e2e | `test_start_night_hold.gd` (2 tests) | ✅ | ✅ green |
| IN-04 fix (pass 3) | review | — | ECON-02 | — | `launch_stagger` falls back to the default before `bind_run`; payout timing tests poll instead of racing | e2e | `test_dawn_payout.gd` (`test_launch_stagger_before_the_run_is_bound_falls_back_to_the_default`) | ✅ | ✅ green |
| WR-01 fix (pass 4) | review | — | ECON-01, ECON-02 | — | Binding the HUD and the payout VFX again connects nothing twice (fails on "already connected" with the guard removed) | e2e | `test_map_binding.gd` (`test_binding_the_hud_and_payout_view_again_connects_nothing_twice`) | ✅ | ✅ green |
| WR-02 / IN-02 / IN-03 fix (pass 4) | review | — | BLDG-06 (start-night input) | — | The prompt follows a runtime rebind on its own; start-night test null-guarded, timings tied to tuning | e2e | `test_start_night_hold.gd` | ✅ | ✅ green |
| WR-03 fix (pass 4) | review | — | ECON-02, ECON-07 | — | Payout and dawn hand-back tests assert game state, not wall-clock time | e2e | `test_dawn_payout.gd` | ✅ | ✅ green |
| WR-04 / IN-04 fix (pass 4) | review | — | BLDG-01 | T-01-10 | A duplicate building id keeps the first definition, like spots; duplicate-spot test asserts identity | unit | `test_building_system_data_errors.gd` (`test_a_duplicate_building_id_keeps_the_first_definition`) | ✅ | ✅ green |
| WR-05 fix (pass 4) | review | — | BLDG-01 | — | Changing the returned spot ids does not change the system | unit | `test_build_spot.gd` (`test_changing_the_returned_spot_ids_does_not_change_the_system`) | ✅ | ✅ green |
| IN-01 fix (pass 4) | review | — | DEV-03 | T-01-15 | A provider that needs an argument is skipped instead of crashing; phase name via `find_key` | unit | `test_debug_overlay_readonly.gd` (`test_a_provider_that_needs_an_argument_is_skipped_instead_of_crashing`) | ✅ | ✅ green |

Owner gates with no automated verify by design: 01-01-T2 (toolchain download approval), 01-03-T2 (public repo name), 01-07-T2 (CC0 model download approval). No run of three consecutive tasks lacks automated verification.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement Coverage

| Requirement | Automated evidence | Status |
|-------------|--------------------|--------|
| KING-01 | `test_input_map`, `test_king_movement_config`, `test_king_ride`, `test_walking_skeleton` | COVERED |
| KING-02 | `test_king_ride` (detached rig, rotation never changes, settles at offset, trails a jump) | COVERED |
| BLDG-01 | `test_build_spot`, `test_prototype_map_data`, `test_map_binding` | COVERED |
| BLDG-02 | `test_build_spot_affordability`, `test_spot_label_model`, `test_spot_label` | COVERED |
| BLDG-03 | `test_build_flow`, `test_build_hold_refund`, `test_build_denied`, `test_coin_drip`, `test_walking_skeleton` | COVERED |
| BLDG-04 | `test_upgrade_flow`, `test_upgrade_at_spot`, `test_spot_label_model` | COVERED |
| BLDG-06 | `test_build_phase_guard`, `test_run_manager` | COVERED |
| ECON-01 | `test_economy_gold`, HUD `GoldLabel` asserts in `test_coin_drip` and `test_dawn_payout` | COVERED |
| ECON-02 | `test_dawn_income`, `test_dawn_payout` | COVERED |
| ECON-07 | `test_loop_gold_carryover` | COVERED |
| ART-02 | `test_attribution_log` (every third-party file covered by exactly one entry, allow-listed licences, ASSETS.md in sync) | COVERED |
| DEV-01 | Whole suite runs headless from the command line (`tools/test.sh`); `test_build_flow` runs without a scene tree; `test_toolchain_smoke` | COVERED |
| DEV-02 | `ci.yml` lint/test/export/screenshots jobs on push; export + launch + pre-push checks re-run locally | COVERED |
| DEV-03 | `test_debug_overlay_readonly`, `test_debug_overlay_toggle` (FPS, phase, gold, buildings, units, enemies; wave-state and pathing rows are Phase 2 scope per ROADMAP SC5) | COVERED (Phase 1 scope) |
| DEV-04 | `tools/screenshot.sh` six scenes, `test_shot_blank_check`, headless guard, CI `screenshots` job | COVERED |

---

## Wave 0 Requirements

- [x] `addons/gut/` — GUT 9.7.1 installed and enabled
- [x] `.gutconfig.json` — shared config for local and CI runs
- [x] `tests/unit/`, `tests/integration/`, `tests/fixtures/` — directory scaffolding (plus `tests/e2e/`)
- [x] `tests/fixtures/` — minimal `MapConfig` test resources (`fixture_map_empty`, `fixture_map_one_tier`, `fixture_map_poor`, `fixture_map_tie`)
- [x] `tools/screenshot/` — the screenshot capture scripts, with a non-blank image check
- [x] gdtoolkit 4.5.0 installed (`gdlint`, `gdformat`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Riding feel: walk/sprint speed, turning, camera follow | KING-01, KING-02 | Movement feel can't be unit-tested (speeds, ratio, deadzone and fixed rotation are) | Play the prototype map with keyboard and gamepad; ride edge to edge (~20–30 s at walk speed per D-03); confirm the camera never rotates |
| Floating spot label, coin drip, denied shake | BLDG-02, BLDG-03, D-07, D-08 | Visual and feel checks | Ride to each spot type; hold to build with enough gold and without; release early to confirm the refund |
| Dawn payout animation and banners | ECON-02, D-12 | Visual check | End the day with the start-night hold; confirm the night banner, then the coins flying to the HUD and the "+X gold" total |
| Screenshot contents | DEV-04 | Needs someone to look at the images | Open the six captured PNGs (day overview, spot label, build in progress, night banner, dawn payout, overlay on) and confirm each shows its scene |
| Licence judgment for logged assets | ART-02 | The test proves every file is logged under an allow-listed licence, not that a self-declared licence is right | Owner decision on the Quaternius horse licence (review finding WR-06) before the itch.io release |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (owner gates excepted by design)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s (per-commit quick run ~12 s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-29

---

## Validation Audit 2026-09-29

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audited after the code-review fixes: 15/15 requirements COVERED. Evidence from this audit's runs: full suite 201/201 passing (30 scripts, 1393 asserts), unit quick run 122/122, lint clean, Windows export plus a headless launch of the exported exe, pre-push check passed, six screenshots captured and non-blank, headless screenshot guard exits 2, `ci.yml` job/permission structure asserted. No auditor spawn was needed because no gaps were found.

## Validation Audit 2026-09-29 (re-audit after review-fix pass 2)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the second review-fix pass (10 fix commits, `83b1c10`..`a8b919e`). 15/15 requirements are still COVERED. The pass added 5 tests, for ECON-02, BLDG-01, ECON-01 and DEV-03 (rows above). Evidence:
- Full suite 206/206 on the post-fix code.
- Unit quick run 125/125 (~13 s).
- `tools/screenshot.sh`, changed by WR-04: 6/6 non-blank captures, with its import log now kept at `build/screenshot-import.log`.
- Headless guard exits 2.
- `ci.yml`, changed by IN-04: job/needs/permissions structure asserted; no `pull_request_target`; no secrets referenced.

## Validation Audit 2026-09-29 (re-audit after review-fix pass 3)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the third review-fix pass (7 fix commits, `ecea4ff`..`9cae015`). 15/15 requirements are still COVERED. The pass added 9 tests (rows above), including the new `tests/unit/test_building_system_data_errors.gd`. Evidence:
- Full suite 215/215 (31 scripts) on the post-fix code; lint clean.
- Unit quick run 129/129 (~12 s).
- `tools/screenshot.sh`: 6/6 non-blank captures. `day_overview` still reads "Hold N / (Y) to start Night 1" now that the hint is built from the InputMap.
- Headless guard exits 2.
- `ci.yml` unchanged in this pass.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 4)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the fourth review-fix pass (8 fix commits, `2d8dd35`..`2fe6dc1`). 15/15 requirements are still COVERED. The pass added 3 tests and extended the rebind test to cover the payout VFX (rows above). Evidence:
- Full suite 218/218 (31 scripts) on the post-fix code; lint clean.
- Unit quick run 132/132 (~12 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.
