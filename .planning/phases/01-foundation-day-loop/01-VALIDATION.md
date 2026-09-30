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
| **Measured runtime** | Quick: ~14 s wall (20 scripts, 172 tests). Full: ~96 s wall (36 scripts, 276 tests) |

The `tools/*.sh` wrappers need Git Bash on Windows; they resolve the pinned binary under `.tools/godot/4.7.2-stable/` (D-14).

Screenshots (DEV-04) use a different mode: a real rendering driver (a normal window locally, `xvfb-run` with the Compatibility renderer in CI). `tools/screenshot/shot_runner.tscn` refuses to run under `--headless` (exit 2) because that mode produces blank images without an error.

---

## Sampling Rate

- **After every task commit:** Run the quick run command (unit tests, ~14 s)
- **After every plan wave:** Run the full suite command plus `bash tools/lint.sh`
- **Before `/gsd-verify-work`:** Full suite green, lint clean, and the six DEV-04 screenshots captured and non-blank
- **Max feedback latency:** 60 seconds per commit (quick run ~14 s). The full suite (~96 s) runs per wave, not per commit.

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
| WR-03 fix (pass 2) | review | — | DEV-03 | T-01-15 | A provider returning a non-Array is skipped, not a crash | unit | `test_debug_overlay_providers.gd` | ✅ | ✅ green |
| WR-01 fix (pass 3) | review | — | ECON-01, ECON-02 | — | A payout naming an unknown spot still lands its coin and settles the HUD | e2e | `test_dawn_payout.gd` (`test_a_payout_naming_an_unknown_spot_still_lands_its_coin_and_settles_the_hud`) | ✅ | ✅ green |
| WR-02 fix (pass 3) | review | — | BLDG-01, ECON-02 | T-01-10 | Duplicate spot id listed once (first definition wins); unknown building id skipped in dawn income | unit | `test_building_system_data_errors.gd` (2 tests) | ✅ | ✅ green |
| WR-03 / IN-03 fix (pass 3) | review | — | DEV-03 | T-01-15 | Malformed provider rows dropped; the read-only test watches every simulation signal | unit | `test_debug_overlay_providers.gd` (malformed rows), `test_debug_overlay_readonly.gd` (every simulation signal watched) | ✅ | ✅ green |
| IN-01 fix (pass 3) | review | — | ECON-01 | — | Binding the HUD twice connects nothing twice | e2e | `test_map_binding.gd` (`test_binding_the_hud_again_connects_nothing_twice`) | ✅ | ✅ green |
| IN-02 fix (pass 3) | review | — | BLDG-06 (start-night input) | — | The start-night prompt names the live bindings and follows a runtime rebind | e2e | `test_start_night_hold.gd` (2 tests) | ✅ | ✅ green |
| IN-04 fix (pass 3) | review | — | ECON-02 | — | `launch_stagger` falls back to the default before `bind_run`; payout timing tests poll instead of racing | e2e | `test_dawn_payout.gd` (`test_launch_stagger_before_the_run_is_bound_falls_back_to_the_default`) | ✅ | ✅ green |
| WR-01 fix (pass 4) | review | — | ECON-01, ECON-02 | — | Binding the HUD and the payout VFX again connects nothing twice (fails on "already connected" with the guard removed) | e2e | `test_map_binding.gd` (`test_binding_the_hud_and_payout_view_again_connects_nothing_twice`) | ✅ | ✅ green |
| WR-02 / IN-02 / IN-03 fix (pass 4) | review | — | BLDG-06 (start-night input) | — | The prompt follows a runtime rebind on its own; start-night test null-guarded, timings tied to tuning | e2e | `test_start_night_hold.gd` | ✅ | ✅ green |
| WR-03 fix (pass 4) | review | — | ECON-02, ECON-07 | — | Payout and dawn hand-back tests assert game state, not wall-clock time | e2e | `test_dawn_payout.gd` | ✅ | ✅ green |
| WR-04 / IN-04 fix (pass 4) | review | — | BLDG-01 | T-01-10 | A duplicate building id keeps the first definition, like spots; duplicate-spot test asserts identity | unit | `test_building_system_data_errors.gd` (`test_a_duplicate_building_id_keeps_the_first_definition`) | ✅ | ✅ green |
| WR-05 fix (pass 4) | review | — | BLDG-01 | — | Changing the returned spot ids does not change the system | unit | `test_build_spot.gd` (`test_changing_the_returned_spot_ids_does_not_change_the_system`) | ✅ | ✅ green |
| IN-01 fix (pass 4) | review | — | DEV-03 | T-01-15 | A provider that needs an argument is skipped instead of crashing; phase name via `find_key` | unit | `test_debug_overlay_providers.gd` (`test_a_provider_that_needs_an_argument_is_skipped_instead_of_crashing`) | ✅ | ✅ green |
| WR-05 fix (pass 5) | review | — | ECON-02 | — | The CR-01 guard is discriminating again: the last coin's scheduled launch delay equals (n-1)·launch_stagger(n) and lands inside the dawn window (fails 14/15 with the old `STAGGER_SECONDS` spacing; orchestrator-probed) | e2e | `test_dawn_payout.gd` (`test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window`) | ✅ | ✅ green |
| WR-02 / WR-03 fix (pass 5) | review | — | ECON-01, ECON-02 | — | The VFX announces the gold its coins carry and the HUD lags by exactly that, releasing at dawn end; coin cap follows the gold that flies; a too-short dawn warns | e2e | `test_dawn_payout.gd` (4 tests) | ✅ | ✅ green |
| WR-01 fix (pass 5) | review | — | BLDG-06 (start-night input) | — | The prompt names trigger/mouse bindings, keeps key modifiers, skips an event that names no key | e2e | `test_start_night_hold.gd` (2 tests) | ✅ | ✅ green |
| WR-04 fix (pass 5) | review | — | BLDG-01, BLDG-04 | T-01-10 | Empty-id spots skipped and never focusable; `apply_next_tier` refuses unknown buildings and never passes the last tier | unit | `test_building_system_data_errors.gd` (3 tests) | ✅ | ✅ green |
| IN-05 fix (pass 5) | review | — | DEV-03 | T-01-15 | Registering a title twice replaces the section instead of duplicating it | unit | `test_debug_overlay_providers.gd` | ✅ | ✅ green |
| WR-01 / IN-01 / IN-02 fix (pass 6) | review | — | BLDG-06 (start-night input) | — | The prompt names a key by its layout label (fake-layout seam; real layouts need a human check), follows an in-place rebind, and shows a stick axis's direction | e2e | `test_start_night_hold.gd` (2 tests + extended assertions) | ✅ | ✅ green |
| WR-02 fix (pass 6) | review | — | DEV-03 | T-01-15 | A skipped overlay provider is warned about once per title | unit | `test_debug_overlay_providers.gd` (`test_a_skipped_provider_is_warned_about_once_however_often_the_overlay_refreshes`) | ✅ | ✅ green |
| WR-03 fix (pass 6) | review | — | BLDG-01 | T-01-10 | A building with an empty id is skipped and never matches an unset building id | unit | `test_building_system_data_errors.gd` | ✅ | ✅ green |
| IN-03 / IN-05 fix (pass 6) | review | — | ECON-02 | — | A crowded payout tightens the stagger to exactly fill the dawn window (asserted against tuning, not itself); a coin whose plot is behind the camera starts mid-screen | e2e | `test_dawn_payout.gd` (2 tests; the stagger test was renamed in pass 10 for the landing margin) | ✅ | ✅ green |
| IN-04 fix (pass 6) | review | — | ECON-01 | — | The double-bind test covers all 11 HUD connections and asserts each is bound first | e2e | `test_map_binding.gd` | ✅ | ✅ green |
| WR-01 / WR-02 fix (pass 7) | review | — | DEV-03 | T-01-15 | A non-Array provider return warns once; replacing a warned provider lets the new one warn again | unit | `test_debug_overlay_providers.gd` (`test_replacing_a_warned_provider_lets_the_new_one_warn_again` + extended non-Array test) | ✅ | ✅ green |
| WR-03 / IN-03 fix (pass 7) | review | — | ECON-01, ECON-02, BLDG-06 | — | In-flight-coin and early-release tests drive the run manager by hand with no wall-clock race; the dawn-end release is tested through a real night→dawn→day | e2e | `test_dawn_payout.gd`, `test_start_night_hold.gd` | ✅ | ✅ green |
| IN-01 fix (pass 7) | review | — | BLDG-01, BLDG-04 | T-01-04 | Readers get a `BuildingInstance` snapshot; changing it does not change the building | unit | `test_build_spot.gd` (`test_a_reader_changing_the_instance_it_was_given_does_not_change_the_building`) | ✅ | ✅ green |
| IN-02 fix (pass 7) | review | — | ECON-02 | — | A float or non-number payout amount does not abort the payout | e2e | `test_dawn_payout.gd` (superseded in pass 8 by `test_a_malformed_payout_entry_does_not_abort_the_payout`) | ✅ | ✅ green |
| WR-01 fix (pass 8) | review | — | ECON-02 | — | A malformed payout entry (bad spot key, non-number or non-finite amount) is dropped with a warning and does not abort the payout | e2e | `test_dawn_payout.gd` (`test_a_malformed_payout_entry_does_not_abort_the_payout`) | ✅ | ✅ green |
| WR-02 fix (pass 8) | review | — | ECON-01, ECON-02 | — | The "+X gold" label, the coins and the HUD readout all use the gold that flies; no coin, no total | e2e | `test_dawn_payout.gd` (2 renamed tests + coin-cap expectation) | ✅ | ✅ green |
| IN-01 fix (pass 8) | review | — | ECON-02 | — | A new payout stops the pending launches of the one it supersedes | e2e | `test_dawn_payout.gd` (`test_a_new_payout_stops_the_pending_launches_of_the_one_it_supersedes`) | ✅ | ✅ green |
| IN-02 / IN-03 fix (pass 8) | review | — | DEV-03 | T-01-15 | Buildings counted by tier (no snapshot allocation); a section titled like a default one is refused | unit | `test_debug_overlay_providers.gd` (`test_registering_a_default_section_title_is_refused_instead_of_showing_it_twice`) | ✅ | ✅ green |
| WR-01 / WR-02 / IN-01 fix (pass 9) | review | — | ECON-02 | — | Absurdly large amounts are clamped so the coin cap holds; fired launch tweens are no longer reported as waiting; a coinless payout does not report the previous total | e2e | `test_dawn_payout_hardening.gd` (3 tests, new file) | ✅ | ✅ green |
| WR-03 / IN-02 fix (pass 9) | review | — | ECON-02 | — | Camera test null-guarded; test hooks documented, `start_point` public | e2e | `test_dawn_payout.gd` | ✅ | ✅ green |
| IN-03 fix (pass 9) | review | — | DEV-03 | T-01-15 | A provider whose Callable became invalid (its object was freed) is dropped after its one warning | unit | `test_debug_overlay_providers.gd` (`test_a_provider_with_an_invalid_callable_is_dropped_after_its_one_warning`, renamed in pass 14) | ✅ | ✅ green |
| WR-01 fix (pass 10) | review | — | ECON-02 | — | A tightened stagger keeps a `DAWN_MARGIN_SECONDS` (0.15 s) landing margin before dawn ends; the default tuning keeps the full stagger | e2e | `test_dawn_payout.gd` (`test_a_crowded_payout_tightens_the_stagger_to_fill_the_dawn_window_less_its_margin` + a margin assertion in the CR-01 guard) | ✅ | ✅ green |
| IN-01 fix (pass 10) | review | — | ECON-02 | — | `start_point` before `bind_run` falls back to mid-screen instead of dereferencing a null run | e2e | `test_dawn_payout_hardening.gd` (`test_start_point_before_the_run_is_bound_falls_back_to_mid_screen`) | ✅ | ✅ green |
| IN-02 / IN-03 fix (pass 10) | review | — | DEV-03 | T-01-15 | The provider warning re-arms once the provider returns rows again; the freed-owner and needs-an-argument tests assert their warnings | unit | `test_debug_overlay_providers.gd` (`test_a_flapping_provider_warns_again_after_it_recovers` + 2 tests extended) | ✅ | ✅ green |
| WR-01 fix (pass 11) | review | — | DEV-03 | T-01-15 | A provider can name the object its lambda captured as `owner`; once that owner is freed the section is warned about once and dropped, while live captures keep showing | unit | `test_debug_overlay_providers.gd` (`test_a_lambda_that_captured_a_freed_object_is_skipped_when_it_names_that_owner`, `test_a_lambda_that_captured_a_live_object_keeps_showing_with_or_without_an_owner`) | ✅ | ✅ green |
| IN-01 / IN-02 fix (pass 11) | review | — | ECON-02, DEV-03 | T-01-15 | Payout test hooks grouped and documented (no behaviour change); the overlay read-only test builds its context from duplicated resources | e2e + unit | `test_dawn_payout.gd`, `test_debug_overlay_readonly.gd` (context now built by `tests/support/overlay_test_support.gd`, still from duplicated resources) | ✅ | ✅ green |
| WR-01 / IN-02 fix (pass 12) | review | — | DEV-03 | T-01-15 | Sections registered before `bind_run` are held and replayed in order (a pending one whose owner died is left out with a warning); a repeat `bind_run` keeps them; the owner parameter is `lifetime_owner`, not `owner` | unit | `test_debug_overlay_registration.gd` (5 tests, new file) | ✅ | ✅ green |
| WR-02 fix (pass 12) | review | — | DEV-03, BLDG-06 | T-01-15 | The overlay's Loop section shows the Timer row by night and dawn only, follows the clock, counts days and nights, and 200 collects by night and by dawn change no state and emit no events | unit | `test_debug_overlay_timed_phases.gd` (7 tests, new file) | ✅ | ✅ green |
| IN-01 / IN-03 fix (pass 12) | review | — | ECON-02, DEV-03 | — | The payout view counts and frees only its coins (group `payout_coin`); overlay sections keyed by title keep replace-in-place order | e2e + unit | `test_dawn_payout_hardening.gd` (`test_a_child_that_is_not_a_coin_is_neither_counted_nor_freed_by_a_payout`), `test_debug_overlay_providers.gd` | ✅ | ✅ green |
| WR-01 / IN-01 fix (pass 13) | review | — | DEV-03 | T-01-15 | A provider whose rows are dropped as malformed is warned about once per failure streak (re-armed only by a fully well-formed answer); the permanent-failure check is derived from the skip reason | unit | `test_debug_overlay_providers.gd` (malformed-rows test extended) | ✅ | ✅ green |
| WR-02 fix (pass 13) | review | — | ECON-01, ECON-02 | — | A payout claiming no gold but listing per-spot amounts warns and shows nothing; a payout of only negative amounts shows nothing and leaves the HUD on the ledger | e2e | `test_dawn_payout_hardening.gd` (`test_a_payout_claiming_no_gold_but_listing_amounts_is_reported_and_shows_nothing`, `test_a_payout_of_only_negative_amounts_shows_nothing_and_leaves_the_hud_on_the_ledger`) | ✅ | ✅ green |
| IN-02 / IN-03 fix (pass 13) | review | — | DEV-03 | T-01-15 | The night/dawn read-only check also snapshots every spot's tier and the unit/enemy counts; registration tests show the overlay through the real toggle action and wait frames, not wall-clock time | unit | `test_debug_overlay_timed_phases.gd`, `test_debug_overlay_registration.gd` | ✅ | ✅ green |
| WR-01 fix (pass 14) | review | — | DEV-03 | T-01-15 | Every read-only overlay suite watches one shared `SimSignals.ALL` list, and the drift guard checks that list against `SimEvents`, so no suite silently under-watches a new signal | unit | `test_debug_overlay_readonly.gd` (drift guard), `test_debug_overlay_timed_phases.gd`; shared list `tests/support/sim_signals.gd` | ✅ | ✅ green |
| IN-01 / IN-03 fix (pass 14) | review | — | DEV-03 | T-01-15 | Overlay skip handling branches on `Skip` codes (messages in one table, `GONE_FOR_GOOD` names the permanent ones), not message text; the invalid-callable test is named for what it pins | unit | `test_debug_overlay_providers.gd` | ✅ | ✅ green |
| IN-02 / IN-04 fix (pass 14) | review | — | ECON-02 | — | The clamp test pins the exact plan (`MAX_COINS` coins split evenly between the two spots) and the shown total; dead night-length setup removed | e2e | `test_dawn_payout_hardening.gd` | ✅ | ✅ green |
| WR-01 / WR-02 fix (pass 15) | review | — | DEV-03 | T-01-15 | A provider whose problem changes within one failure streak is named again (a changing count of malformed rows is not a new problem); every `Skip` code except NONE has a message | unit | `test_debug_overlay_providers.gd` (`test_a_provider_whose_problem_changes_within_one_streak_is_named_again`, `test_the_count_of_malformed_rows_changing_is_not_a_new_problem`, `test_every_skip_code_except_none_has_a_message`) | ✅ | ✅ green |
| IN-04 fix (pass 15) | review | — | DEV-03 | T-01-15 | A section registered with an already-freed `lifetime_owner` is refused with a warning (model and overlay, before and after `bind_run`) instead of a script error at the call site | unit | `test_debug_overlay_providers.gd` (`test_a_section_whose_owner_was_already_freed_is_refused_with_a_warning`), `test_debug_overlay_registration.gd` (`test_a_section_registered_with_an_already_freed_owner_is_refused_before_and_after_bind_run`) | ✅ | ✅ green |
| IN-01 / IN-02 / IN-03 fix (pass 15) | review | — | DEV-03, ECON-02 | T-01-15 | Overlay suites share setup, lookup and the 200-collect read-only assertion (`tests/support/overlay_test_support.gd`); 12 provider tests moved unchanged into their own suite; a payout-test comment corrected | unit + e2e | `test_debug_overlay_readonly.gd`, `test_debug_overlay_providers.gd`, `test_debug_overlay_timed_phases.gd`, `test_dawn_payout_hardening.gd` | ✅ | ✅ green |
| IN-01 fix (pass 16) | review | — | DEV-03 | — | `DebugOverlay.get_text()` before the overlay is in the tree returns "" instead of a null-instance script error | unit | `test_debug_overlay_registration.gd` (`test_get_text_before_the_overlay_is_in_the_tree_is_empty_instead_of_a_script_error`) | ✅ | ✅ green |
| IN-02 / IN-03 fix (pass 16) | review | — | DEV-03 | T-01-15 | One shared owner check (`DebugOverlayModel.owner_problem`) for the model, the view's pre-bind path and the bind replay; a non-Object owner is refused as "not an Object", not as freed; the registration suite builds its context from `OverlayTestSupport.new_map()`/`new_tuning()` | unit | `test_debug_overlay_providers.gd` (`test_a_section_whose_owner_is_not_an_object_is_refused_as_such_not_as_freed`), `test_debug_overlay_registration.gd` (`test_an_owner_that_is_not_an_object_is_refused_before_and_after_bind_run_as_such`) | ✅ | ✅ green |
| WR-01 fix (pass 17) | review | — | DEV-03 | — | `OverlayTestSupport.new_map()` deep-copies building definitions and tiers (`duplicate_deep(DEEP_DUPLICATE_ALL)`), so no overlay test can leak an edit into the cached map or a later copy | unit | `test_overlay_test_support.gd` (4 tests, new file) | ✅ | ✅ green |
| IN-01 / IN-02 fix (pass 17) | review | — | DEV-03 | T-01-15 | A default section title is refused at once before `bind_run` too (never buffered); a repeat `bind_run` with a different `RunContext` warns and the overlay keeps reading the first run | unit | `test_debug_overlay_registration.gd` (`test_a_default_title_is_refused_at_once_before_bind_run_and_never_buffered`, `test_a_default_title_is_refused_the_same_way_after_bind_run`, `test_a_repeat_bind_run_with_another_context_warns_and_keeps_reading_the_first_run`) | ✅ | ✅ green |
| WR-01 fix (pass 18) | review | — | DEV-03 | T-01-15 | `DebugOverlay.bind_run` with no `RunContext` warns and stays unbound, so a later valid bind still works (no script error on every refresh) | unit | `test_debug_overlay_registration.gd` (`test_bind_run_with_no_context_warns_and_leaves_the_overlay_free_to_bind_properly`) | ✅ | ✅ green |
| IN-01 / IN-02 / IN-03 fix (pass 18) | review | — | DEV-03 | T-01-15 | Overlay rows must be exactly [label, value]: a longer row is dropped and counted in the malformed-row warning, not truncated; the shared helper asserts the map has a spot before indexing it and deep-copies tuning like the map; the map-copy test can no longer pass on an empty map | unit | `test_debug_overlay_providers.gd` (malformed-rows test updated), `test_overlay_test_support.gd` | ✅ | ✅ green |

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
| DEV-03 | `test_debug_overlay_readonly`, `test_debug_overlay_providers`, `test_debug_overlay_timed_phases`, `test_debug_overlay_registration`, `test_debug_overlay_toggle` (FPS, phase, gold, buildings, units, enemies; wave-state and pathing rows are Phase 2 scope per ROADMAP SC5) | COVERED (Phase 1 scope) |
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
| Start-night key label on a non-QWERTY layout | BLDG-06 (start-night input) | Headless Godot cannot switch keyboard layouts; only a fake-layout seam is tested | On a Dvorak or AZERTY desktop, confirm the start-night prompt names the key printed on the keycap |
| Licence judgment for logged assets | ART-02 | The test proves every file is logged under an allow-listed licence, not that a self-declared licence is right | Owner decision on the Quaternius horse licence (review finding WR-06) before the itch.io release |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (owner gates excepted by design)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s (per-commit quick run ~14 s)
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

## Validation Audit 2026-09-30 (re-audit after review-fix pass 5)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the fifth review-fix pass (9 fix commits, `e83e5e0`..`17c661d`). 15/15 requirements are still COVERED.

- **Weak guard restored.** Pass 4 had left the CR-01 guard test vacuous: with the bug reverted, all 11 payout tests passed. It now fails 14/15 against the old `STAGGER_SECONDS` spacing, as orchestrator-probed.
- **Tests:** net +9 (see the rows above). Two tests were replaced by stronger ones.

Evidence:
- Full suite 227/227 (31 scripts); lint clean.
- Unit quick run 135/135 (~11 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 6)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the sixth review-fix pass (8 fix commits, `723080f`..`1c3e320`). 15/15 requirements are still COVERED.

- **Tests:** net +5. Every change carries a mutation probe in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator; it still fails with the old spacing.
- **Manual-only addition:** the start-night key label on a non-QWERTY layout, because a headless run cannot switch layouts.

Evidence:
- Full suite 232/232 (31 scripts); lint clean.
- Unit quick run 137/137 (~11 s).
- `tools/screenshot.sh`: 6/6 non-blank captures. The real-window prompt still reads "Hold N / (Y) to start Night 1".
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 7)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the seventh review-fix pass (6 fix commits, `b789dde`..`d4ef4f5`). 15/15 requirements are still COVERED.

- **Tests:** +3 new. Two e2e tests no longer race wall-clock time.
- **Mutation probes:** every change carries one in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator; it fails 16/17 with the old spacing.

Evidence:
- Full suite 235/235 (31 scripts); lint clean.
- Unit quick run 139/139 (~11 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 8)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the eighth review-fix pass (5 fix commits, `60d4881`..`30d0dd4`). 15/15 requirements are still COVERED.

- **Tests:** +2 new. Three payout tests were renamed or rewritten for the "carried gold" label semantics.
- **Mutation probes:** every change carries one in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator; it fails 17/18 with the old spacing.

Evidence:
- Full suite 237/237 (31 scripts); lint clean.
- Unit quick run 140/140 (~11 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 9)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the ninth review-fix pass (6 fix commits, `7cd97d9`..`1a0bb93`). 15/15 requirements are still COVERED.

- **Tests:** +4 new, three of them in `tests/e2e/test_dawn_payout_hardening.gd`, split out because `test_dawn_payout.gd` is at gdlint's 20-method cap.
- **Mutation probes:** every change carries one in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator; it fails 17/18 with the old spacing.

Evidence:
- Full suite 241/241 (32 scripts); lint clean.
- Unit quick run 141/141 (~12 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 10)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the tenth review-fix pass (4 fix commits, `f1806f5`..`c3905c7`). 15/15 requirements are still COVERED.

- **Tests:** +2 new, one in `test_dawn_payout_hardening.gd` and one in `test_debug_overlay_readonly.gd`. The crowded-stagger test was renamed for the landing margin, and two overlay tests now assert their warnings.
- **Landing margin:** the 0.15 s value is a tuning choice. At the default 2.0 s dawn the full 0.08 s stagger still holds for payouts of up to 16 coins, so no manual check was added.
- **Mutation probes:** every change carries one in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator; it fails 17/18 with the old spacing.

Evidence:
- Full suite 243/243 (32 scripts); lint clean.
- Unit quick run 142/142 (~12 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 11)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the eleventh review-fix pass (3 fix commits, `a273e88`..`f66045f`). 15/15 requirements are still COVERED.

- **Tests:** +2 new in `test_debug_overlay_readonly.gd`, which is now at gdlint's 20-method cap. They cover an owner-guarded lambda provider (freed owner: one warning, then dropped) and live captures with and without an owner.
- **No behaviour change:** IN-01 (the payout view's test hooks grouped and documented) and IN-02 (the overlay test builds its context from duplicated resources).
- **Mutation probes:** the WR-01 probe is recorded in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator, since `dawn_payout_vfx.gd` was touched; it fails 17/18 with the old spacing.

Evidence:
- Full suite 245/245 (32 scripts); lint clean.
- Unit quick run 144/144 (~12 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 12)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the twelfth review-fix pass (5 commits, `8ee2508`..`7e7a1f2`). 15/15 requirements are still COVERED.

- **Tests:** +13 new, in two new unit files split out because `test_debug_overlay_readonly.gd` is at gdlint's 20-method cap, plus one in `test_dawn_payout_hardening.gd`.
  - `test_debug_overlay_registration.gd` (5): registration before `bind_run`, order, repeat bind, dead pending owner, parameter name.
  - `test_debug_overlay_timed_phases.gd` (7): Timer row and day/night counters by day, night and dawn, plus the 200-collect read-only check by night and by dawn. This closes the DAY-only gap the review found in the DEV-03 read-only proof.
- **Mutation probes:** every behaviour change carries one in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator, since `dawn_payout_vfx.gd` was touched; it fails 17/18 with the old spacing.
- **Runtime:** re-measured. The quick run is now ~14 s and the full suite ~96 s, both within the sampling budget.

Evidence:
- Full suite 258/258 (34 scripts, ~96 s); lint clean.
- Unit quick run 156/156 (18 scripts, ~14 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 13)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the thirteenth review-fix pass (5 commits, `b223b55`..`6c38829`). 15/15 requirements are still COVERED.

- **Tests:** +2 new e2e payout tests in `test_dawn_payout_hardening.gd` (now 7 methods). Three existing tests were tightened:
  - The malformed-rows overlay test now asserts its one warning.
  - The night/dawn read-only check now also snapshots building tiers and unit/enemy counts.
  - The registration tests now go through the real toggle action and no longer race a wall-clock wait.
- **Mutation probes:** every behaviour change carries one in `01-REVIEW-FIX.md`. IN-01 is a behaviour-preserving refactor, guarded by the existing freed-owner, invalid-callable and argument-count tests.
- **CR-01 guard:** re-probed by the orchestrator, since `dawn_payout_vfx.gd` was touched; it fails 17/18 with the old spacing.

Evidence:
- Full suite 260/260 (34 scripts); lint clean.
- Unit quick run 156/156 (18 scripts, ~13 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 14)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the fourteenth review-fix pass (5 commits, `24f0e1e`..`3f3ee45`). 15/15 requirements are still COVERED.

- **Tests:** no new test methods.
  - The two read-only overlay suites now share `SimSignals.ALL` (`tests/support/sim_signals.gd`, not collected by GUT, linted with `tests/`) behind one drift guard.
  - The clamp test pins the exact coin plan and the shown total.
  - One overlay test was renamed; the pass-9 row above now uses the new name.
- **Mutation probes:** every change carries one in `01-REVIEW-FIX.md`. IN-02 (dead setup removed) and IN-03 (rename) need none.
- **CR-01 guard:** re-probed by the orchestrator; it fails 17/18 with the old spacing. `dawn_payout_vfx.gd` was not touched this pass.

Evidence:
- Full suite 260/260 (34 scripts); lint clean (69 files).
- Unit quick run 156/156 (18 scripts, ~12 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 15)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the fifteenth review-fix pass (6 commits, `639f5fd`..`4fac944`). 15/15 requirements are still COVERED.

- **Tests:** +5 new. 12 provider tests moved unchanged from `test_debug_overlay_readonly.gd` into the new `test_debug_overlay_providers.gd`; none was removed.
  - The map rows for those tests (passes 2 to 14) now point at the providers suite.
  - The read-only contract tests (01-08-T1, the drift guard) stay in `test_debug_overlay_readonly.gd`.
  - Shared setup and the 200-collect assertion now live in `tests/support/overlay_test_support.gd`, which is test-only and not collected by GUT. Plan 01-08's artifact check still passes (`verify.artifacts` 3/3).
- **Mutation probes:** every behaviour change carries one in `01-REVIEW-FIX.md`. IN-02 (a pure move) and IN-03 (a comment) need none.
- **CR-01 guard:** re-probed by the orchestrator; it fails 17/18 with the old spacing. `dawn_payout_vfx.gd` was not touched this pass.

Evidence:
- Full suite 265/265 (35 scripts, ~96 s); lint clean (71 files).
- Unit quick run 161/161 (19 scripts, ~13 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 16)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the sixteenth review-fix pass (3 commits, `187f47a`..`49f4ae9`), the first pass fixing an info-only review. 15/15 requirements are still COVERED.

- **Tests:** +3 new. One covers the `get_text()` readiness guard; two cover refusing a non-Object owner, in the model and before and after `bind_run`. IN-03 is a test-scaffolding refactor with no behaviour change.
- **Mutation probes:** every behaviour change carries one in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator; it fails 17/18 with the old spacing. `dawn_payout_vfx.gd` was not touched this pass.

Evidence:
- Full suite 268/268 (35 scripts); lint clean (71 files).
- Unit quick run 164/164 (19 scripts, ~14 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 17)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the seventeenth review-fix pass (3 commits, `457e334`..`8a440c0`). 15/15 requirements are still COVERED.

- **Tests:** +7 new.
  - 4 are in the new `test_overlay_test_support.gd`. They pin that the shared overlay test helper hands out fully private map and tuning copies.
  - 3 are in `test_debug_overlay_registration.gd`: a default title refused before and after bind, and a repeat bind with another run.
  - The existing second-bind test now rebinds the same run and asserts silence.
  - The 13 other suites that use `duplicate(true)` were left alone. None edits a building definition, so the review scoped the finding to the shared helper.
- **Mutation probes:** every change carries one in `01-REVIEW-FIX.md`.
- **CR-01 guard:** re-probed by the orchestrator; it fails 17/18 with the old spacing. `dawn_payout_vfx.gd` was not touched this pass.

Evidence:
- Full suite 275/275 (36 scripts); lint clean (72 files).
- Unit quick run 171/171 (20 scripts, ~14 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.

## Validation Audit 2026-09-30 (re-audit after review-fix pass 18)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audited after the eighteenth review-fix pass (4 commits, `546c3dc`..`c886c04`). 15/15 requirements are still COVERED.

- **Tests:** +1 new, the null-context `bind_run` test.
  - The malformed-rows provider test now expects an over-long row to be dropped rather than truncated. This is the one intended behaviour change in the overlay's row contract.
  - The map-copy helper test now asserts it has buildings and tiers to compare.
- **Mutation probes:** WR-01 and IN-03 each carry one in `01-REVIEW-FIX.md`.
  - IN-01's guard was probed against an empty map.
  - IN-02 needs none: `LoopTuning` holds only scalars, so the two copy methods behave the same today.
- **CR-01 guard:** re-probed by the orchestrator; it fails 17/18 with the old spacing. `dawn_payout_vfx.gd` was not touched this pass.

Evidence:
- Full suite 276/276 (36 scripts); lint clean (72 files).
- Unit quick run 172/172 (20 scripts, ~16 s).
- `tools/screenshot.sh`: 6/6 non-blank captures.
- Headless guard exits 2.
- `ci.yml` unchanged.
