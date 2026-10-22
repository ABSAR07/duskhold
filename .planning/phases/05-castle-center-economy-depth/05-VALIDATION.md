---
phase: "05"
slug: "castle-center-economy-depth"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-21"
validated: "2026-10-22"
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT 9.7.1 on Godot 4.7.2-stable (GDScript, headless), gdtoolkit 4.5.0 lint |
| **Config file** | `.gutconfig.json` (dirs `tests/unit`, `tests/integration`, `tests/e2e`; JUnit to `build/test-results/gut-junit.xml`) |
| **Quick run command** | `bash tools/test.sh -gselect=<test_script_substring>` (one selection per invocation) |
| **Full suite command** | `bash tools/test.sh` then `bash tools/lint.sh`; replays `bash tools/replay.sh --scenario=<smoke, army, walls or economy> --twice --expect-file=tests/golden/<scenario>.json` and `--scenario=full_idle --twice` (unpinned by design, digest recorded in 05-BALANCE-REPORT.md); `bash tools/gate_stress.sh --twice`; real-window checks `bash tools/screenshot.sh` (44 shots); `bash tools/playtest.sh --seeds=10` for the balance bar |
| **Estimated runtime** | quick run 20-90 s per script; full suite about 15 min at the end of the phase (279 scripts, 2653 tests, 60629 asserts, all passing, lint clean on 446 files: the orchestrator's wave-11 post-merge gate of 2026-10-22T09:37:47Z on commit 6679a32; plan 05-12's own run on 82928bd gave 60264 asserts and the wave-10 gate 60608 with the same 2653 tests, so the assert count varies by a few hundred between runs of the same code (per-frame assertions in e2e tests) and the script and test counts are the stable figures); lint 20 s; each replay under a minute; gate stress under two minutes; the 44 shots 20 to 30 minutes on a quiet machine; the ten-seed sweep about 6 minutes |

---

## Sampling Rate

- **After every task commit:** Run `bash tools/test.sh -gselect=<the task's scripts>` and, for anything under simulation/ or data/, the smoke, army, walls and economy replays (and full_idle against the report's digest)
- **After every plan wave:** Run `bash tools/test.sh` and `bash tools/lint.sh` (the orchestrator's post-merge gate, logged to build/test-results/postmerge_test_stdout.log; eleven waves, all green)
- **Before `/gsd-verify-work`:** Full suite must be green (it is: 279 scripts, 2653 tests, 60629 asserts, all passing, lint clean on 446 files: the orchestrator's wave-11 post-merge gate of 2026-10-22T09:37:47Z on commit 6679a32; plan 05-12's own run on 82928bd gave 60264 asserts and the wave-10 gate 60608 with the same 2653 tests, so the assert count varies by a few hundred between runs of the same code (per-frame assertions in e2e tests) and the script and test counts are the stable figures; CI run 39751537305 green on 570ff8d)
- **Max feedback latency:** 90 s for a single script; the full suite is accepted at about 15 minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 5-01-01 | 01 | 1 | META-08 | T-05-01 / T-05-02 | StatStack.add_source validates every modifier (registered id, FLAT within 100000, PERCENT -90..1000, MULTIPLIER 10..400, at most four) and applies nothing on failure; `simulation/stats` joins MATH_ROOTS; every stat reads identity while the stack is empty | tracer (unit + integration + replays) | `bash tools/test.sh -gselect=test_stat_stack`, `-gselect=test_stat_contract`, `-gselect=test_stat_tracer`, `-gselect=test_sim_rules_guard`; smoke, army and walls replays | ✅ | ✅ green |
| 5-01-02 | 01 | 1 | META-08 | T-05-03 | Overlay and unit_views call read methods only (`modified_stats`, `sums_of`, `int_value`); a raised maximum lifts current health by the gain, never beyond | unit + integration | `-gselect=test_stat_combined`, `-gselect=test_stat_consumers`, `-gselect=test_stat_refresh`, `-gselect=test_dawn_income`, `-gselect=test_castle_attack`, `-gselect=test_balance_acceptance` | ✅ | ✅ green |
| 5-02-01 | 02 | 2 | BLDG-08, BLDG-05, UI-02 | T-05-04 / T-05-05 / T-05-06 | `validate_build` answers BAD_CHOICE for an id outside the next tier's list and CHOICE_REQUIRED for none, before any spend; the pick is armed through StatStack.add_source; `choice_picked` is in the replay digest | tracer (unit + e2e + replays) | `-gselect=test_build_choice`, `-gselect=test_castle_tiers`, `-gselect=test_card_row_model`, `-gselect=test_card_row.gd`, `-gselect=test_upgrade_at_spot`, `-gselect=test_determinism`; the replays | ✅ | ✅ green |
| 5-02-02 | 02 | 2 | BLDG-08, BLDG-05, UI-02 | T-05-04 | Digits 1 to 4 pick a card only while the row shows and fall back to control groups otherwise; the castle plot is appended after the Phase 4 plots so no stored index moves | e2e + unit | `-gselect=test_card_digit_handover`, `-gselect=test_control_group_keys`, `-gselect=test_nav_layout_pin`, `-gselect=test_prototype_map_economy` | ✅ | ✅ green |
| 5-03-01 | 03 | 3 | BLDG-08, BLDG-05, UI-02 | T-05-08 | Card names are capped at 24 and flavour at 70 code points by `validate()`; Label3D wraps at a fixed width; the castle label lists the picks in order | tracer (unit + e2e + replays) | `-gselect=test_castle_label`, `-gselect=test_castle_three_picks`, `-gselect=test_card_row.gd`, `-gselect=test_build_choice`, `-gselect=test_spot_label` | ✅ | ✅ green |
| 5-03-02 | 03 | 3 | BLDG-08, BLDG-05, UI-02 | T-05-07 | ChoiceValidation and CastleValidation report duplicate ids, empty choices, bad modifiers, wrong choice counts, a second castle plot and a tier I with choices at construction; nothing bad is armed; the twelve cards are pinned | unit | `-gselect=test_choice_validation`, `-gselect=test_ability_data`, `-gselect=test_prototype_map_economy`, `-gselect=test_prototype_map_data` | ✅ | ✅ green |
| 5-04-01 | 04 | 4 | UI-02, BLDG-05, BLDG-08 | T-05-09 | CardPicker consumes a press only when `hit_test` finds a card and writes only its own highlight; the hold's BuildIntent through CommandProcessor stays the only purchase path (gold, tier and selection unchanged after a click) | tracer (e2e + unit + replays) | `-gselect=test_card_mouse`, `-gselect=test_card_row_model`, `-gselect=test_card_row.gd`, `-gselect=test_box_select`, `-gselect=test_squad_selection` | ✅ | ✅ green |
| 5-04-02 | 04 | 4 | UI-02, BLDG-05, BLDG-08 | T-05-10 | Twelve first-party SVG icons logged CC0-1.0 in ASSETS.md with the logged Kenney key tiles; keep scenes compose only logged Castle Kit GLBs; `test_attribution_log` stays green | unit + e2e + real window | `-gselect=test_card_icons`, `-gselect=test_castle_views`, `-gselect=test_shot_list`, `-gselect=test_attribution_log`, `-gselect=test_building_view_catalog`; `bash tools/screenshot.sh castle_cards castle_tier_four` | ✅ | ✅ green |
| 5-05-01 | 05 | 4 | BLDG-09 | T-05-12 | `validate_build` refuses a locked tier with `castle_tier` or `needs_spot` before any spend; `command_rejected` announces it; the label reads "Needs Castle II" | tracer (unit + e2e + replays) | `-gselect=test_build_requirements`, `-gselect=test_spot_label_locked`, `-gselect=test_castle_gate`, `-gselect=test_build_choice`, `-gselect=test_upgrade_at_spot` | ✅ | ✅ green |
| 5-05-02 | 05 | 4 | BLDG-09 | T-05-11 | BuildRequirementValidation reports a cycle, a missing spot, a self-requirement and an impossible tier at construction; a locked entry never stalls a bot (defer-on-locked) | unit + integration | `-gselect=test_build_requirement_validation`, `-gselect=test_bot_defers_locked`, `-gselect=test_playtest_strategies`, `-gselect=test_balance_acceptance` | ✅ | ✅ green |
| 5-06-01 | 06 | 5 | ECON-03 | T-05-14 | FLAT curves are paid only by BuildingSystem and every other curve only by IncomeState; one `dawn_payout` per dawn whose total equals the sum; the full_idle digest guards the order | tracer (unit + integration + e2e + replays) | `-gselect=test_gold_mine.gd`, `-gselect=test_dawn_payout_economy`, `-gselect=test_gold_mine_scene`, `-gselect=test_prototype_map_economy`, `-gselect=test_nav_layout_pin`, `-gselect=test_dawn_income`, `-gselect=test_sim_rules_guard` | ✅ | ✅ green |
| 5-06-02 | 06 | 5 | ECON-03 | T-05-13 | EconomyValidation reports out-of-range or misplaced curve fields (MAX_CURVE_VALUE 1000); the payout counter never grows; the Economy overlay section is read-only | unit + e2e | `-gselect=test_rebuilt_economy_marker`, `-gselect=test_economy_validation`, `-gselect=test_economy_data_contract`, `-gselect=test_economy_overlay_sections`, `-gselect=test_debug_overlay_readonly` | ✅ | ✅ green |
| 5-07-01 | 07 | 6 | ECON-04 | T-05-15 | `validate_build` refuses NEEDS_SPOT (a Field without its Mill) before any spend, gold unchanged and `command_rejected` announced; Mill and Field pay through the one dawn payout | tracer (unit + e2e + integration + replays) | `-gselect=test_mill_fields.gd`, `-gselect=test_mill_fields_scene`, `-gselect=test_prototype_map_economy`, `-gselect=test_nav_layout_pin`, `-gselect=test_build_requirements`, `-gselect=test_dawn_payout_economy` | ✅ | ✅ green |
| 5-07-02 | 07 | 6 | ECON-04 | T-05-15 | Built Fields stay independent of their Mill (a fallen Mill relocks nothing); the Mill and Field numbers are pinned by the contract test; the lock reads in a shot | integration + unit + real window | `-gselect=test_field_independence`, `-gselect=test_economy_data_contract`, `-gselect=test_shot_list`; `bash tools/screenshot.sh field_locked` | ✅ | ✅ green |
| 5-08-01 | 08 | 7 | ECON-05 | T-05-16 | One boat per dawn the Harbor still stands, up to the tier's cap; `harbor_boats_changed` is in the replay digest; every boat pays at dawn | tracer (unit + e2e + integration + replays) | `-gselect=test_fishing_harbor`, `-gselect=test_harbor_scene`, `-gselect=test_prototype_map_economy`, `-gselect=test_nav_layout_pin`, `-gselect=test_determinism`, `-gselect=test_dawn_payout_economy` | ✅ | ✅ green |
| 5-08-02 | 08 | 7 | ECON-05 | T-05-16 | EconomyValidation bounds `boat_cap` to 1..20, `boat_income` to 1..1000 and the pond radius to 30 m with finite numbers, and keeps plots, spawns and roads off the pond; the pond never enters NavGrid | unit + real window | `-gselect=test_economy_validation`, `-gselect=test_pond_layout`, `-gselect=test_economy_data_contract`, `-gselect=test_economy_overlay_sections`, `-gselect=test_shot_list`; `bash tools/screenshot.sh harbor_pond` | ✅ | ✅ green |
| 5-09-01 | 09 | 8 | ECON-06 | T-05-17 | A dormant Shrine never fires; it wakes when kill credit within `wake_radius` reaches `wake_threshold_hp` (one squared-distance test per Shrine per death) and then joins the tower loop; `shrine_woke` is in the digest | tracer (unit + integration + e2e + replays) | `-gselect=test_shrine.gd`, `-gselect=test_shrine_night`, `-gselect=test_shrine_scene`, `-gselect=test_prototype_map_economy`, `-gselect=test_tower_combat`, `-gselect=test_determinism`, `-gselect=test_stat_tracer` | ✅ | ✅ green |
| 5-09-02 | 09 | 8 | ECON-06 | T-05-17 / T-05-18 | The `shrine_synergy` source id is replaced on every change, never appended, under StatStack's percent-sum bound; EconomyValidation bounds `wake_radius` (0, 40], `wake_threshold_hp` 1..100000 and `synergy_percent` 0..100 and requires attack numbers and known stat ids on AWAKENED tiers | unit + integration + real window | `-gselect=test_shrine_synergy`, `-gselect=test_shrine_destroyed`, `-gselect=test_economy_validation`, `-gselect=test_shrine_validation`, `-gselect=test_shot_list`; `bash tools/screenshot.sh shrine_awake_night` | ✅ | ✅ green |
| 5-10-01 | 10 | 9 | BLDG-05, BLDG-08, ECON-03, ECON-04, ECON-05, ECON-06 | T-05-19 / T-05-20 | `tests/golden/economy.json` is written once on a frozen fixture map; ReplayCli accepts only the names in ReplayScenarios.NAMES; ci.yml keeps `permissions: contents: read` with two replay lines added | tracer (integration + CI) | `-gselect=test_economy_replay_golden`, `-gselect=test_bot_card_picks`, `-gselect=test_replay_cli_args`; `bash tools/replay.sh --scenario=economy --twice --expect-file=tests/golden/economy.json` | ✅ | ✅ green |
| 5-10-02 | 10 | 9 | BLDG-05, BLDG-08, ECON-03, ECON-04, ECON-05, ECON-06 | T-05-19 | One night that destroys all four new building types costs none of them anything but that morning's pay (D-14); the rebuilt marker shows | integration + e2e + replays | `-gselect=test_economy_destroyed`, `-gselect=test_rebuilt_economy_marker`; the economy, smoke and full_idle replays | ✅ | ✅ green |
| 5-11-01 | 11 | 10 | BLDG-09, BLDG-08, ECON-03, ECON-04, ECON-05, ECON-06 | T-05-22 | Playtest outputs stay under build/ through the `--out` allowlist; the castle-aware bots pick cards by script and the report shows tiers, picks and spend | tracer (sweep + unit + integration) | `bash tools/playtest.sh --strategies=balanced_castle,army_castle --seeds=10`, `-gselect=test_playtest_strategies`, `-gselect=test_balance_report_castle`, `-gselect=test_balance_report.gd`, `-gselect=test_balance_acceptance` | ✅ | ✅ green |
| 5-11-02 | 11 | 10 | BLDG-09, BLDG-08, ECON-03, ECON-04, ECON-05, ECON-06 | T-05-21 | Pins, data and 05-BALANCE-REPORT.md land in one commit; the full_idle after digest in the report is the one the run prints and the before digest is kept; the Phase 2 bar is not lowered; the castle gate ships on five top tiers | integration + sweep | `bash tools/playtest.sh --seeds=10`, `-gselect=test_balance_acceptance`, `-gselect=test_gate_data_contract`, `-gselect=test_castle_gate`, `-gselect=test_upgrade_flow`, `-gselect=test_ability_data` | ✅ | ✅ green |
| 5-11-03 | 11 | 10 | BLDG-09, BLDG-08, ECON-03, ECON-04, ECON-05, ECON-06 | T-05-22 | Two shots on the shipped map (the gate on a Tower, the whole economy in one frame); the shot list is pinned | real window + unit | `-gselect=test_shot_list`; `bash tools/screenshot.sh castle_gate_locked economy_day` | ✅ | ✅ green |
| 5-12-01 | 12 | 11 | BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08, UI-02 | T-05-24 | The whole verify line in one sitting on the committed tree; only the four presentation files may change, and none did | tracer (suite + five replays + gate stress + 44 shots + lint) | `bash tools/test.sh`; `bash tools/replay.sh --scenario=<smoke, army, walls or economy> --twice --expect-file=tests/golden/<scenario>.json` and `--scenario=full_idle --twice`; `bash tools/gate_stress.sh --twice`; `bash tools/screenshot.sh`; `bash tools/lint.sh` | ✅ | ✅ green |
| 5-12-02 | 12 | 11 | BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08, UI-02 | T-05-23 | `tools/prepush_check.sh` before the one push with the gh credential-helper command; ci.yml changed by one comment line only, `permissions: contents: read` and every pinned `uses:` SHA kept | CI | CI run 39751537305 green on 570ff8d (lint, test, native-linux, native-windows, export, screenshots; REPLAY_OK for the five scenarios, GATE_OK, 44 PNGs in the artifact) | ✅ | ✅ green |
| 5-12-03 | 12 | 11 | BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08, UI-02 | T-05-24 | The export demands the stamped native DLL beside the exe; the headless launch check runs the exported build; the packet lists every assumption | e2e (export) + human-check | `bash tools/export.sh`; `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` | ✅ | ✅ green (owner feel check pending, /gsd-verify-work 5) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Every plan's Task 1 is a tracer with an automated verify on the committed tree; no stubs or Wave 0 installs were needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The cards read from the riding camera and picking by key and by mouse feels right; the re-appearing row (research A10, no dismiss) helps rather than annoys (D-02 feel half) | BLDG-05, UI-02 | Feel and readability; the e2e tests prove the pick path, not whether it reads | Play two or three runs climbing the castle (05-PLAYTEST-GATE.md "What to judge" 1); decide at `/gsd-verify-work 5` |
| The twelve abilities are distinct and worth a pick; none is always or never taken; Prosperity's +1 is not too weak | BLDG-08 | Balance judgement; the bots pick by script and say nothing about which card is best (05-11) | Take different cards across runs; name the cards to rename, rebalance or replace |
| "Needs Castle II" reads as a trade-off, not a wall (D-03) | BLDG-09 | Feel; the bots only show the no-castle order falls from 8 to 3 wins | Run a Phase 4 style game and read the locked labels; decide whether to soften the gate |
| Each new building reads and is worth its gold: the Mine's falling payout, the Fields' lock, the boats arriving, the Shrines waking (D-12 feel half) | ECON-03, ECON-04, ECON-05, ECON-06 | Feel; measured facts for the owner: the Harbor dominates income, the Mine, Mill and Fields pay about a House, the Shrine wakes in a minority of seeds and almost never fires | Build every new building in a run; decide the economy mix and whether the Shrine needs a nearer plot or a different wake rule |
| The day's decisions feel deeper and the game is still fun (core value) | BLDG-08, ECON-03 to ECON-06 | Only the owner can judge | Two or three full runs, then sign off or list the fixes that must land before Phase 6 |
| Presentation points left for the owner: the HUD banner over a raised card, the tier IV keep's roof cropped at default zoom, the small buildings in the wide economy shot (05-12 shot review) | UI-02 | Readability calls; no code changed in 05-12 | Open `castle_cards.png`, `castle_tier_four.png`, `economy_day.png` from `screenshots/` or the CI artifact; decide now or defer to Phase 8 |
| Castle tiers III and IV are out of bot reach (costs 10 and 16 against about 30 gold a run) and the army build cannot afford the castle | BLDG-08 | Whether the later tiers should be mid-run decisions is a tuning decision, not a test | Decide the ladder's reach at the gate; a retune is data plus one contract test each |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (26 of 26 tasks; 05-12 Task 3 also carries the owner's `<human-check>`)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none)
- [x] No watch-mode flags (GUT runs with `-gexit`)
- [x] Feedback latency within the project's accepted bound (single script under 90 s; full suite about 15 min)
- [x] `nyquist_compliant: true` set in frontmatter (every task's automated check is green; the manual-only rows are the owner's feel and tuning decisions, which no test can settle)

**Approval:** validated 2026-10-22 (validate-phase audit, state A): 26 of 26 task checks green, no gap, no auditor spawn needed

## Validation Audit 2026-10-22
| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit basis: 12 PLAN and 12 SUMMARY files (all `status: complete`), the per-plan test scripts listed in each SUMMARY's `key-files`, the eleven post-merge gate runs (asserts 55813 at wave 1 to 60608 at wave 10), the final full suite (279 scripts, 2653 tests, 60629 asserts, all passing, lint clean on 446 files: the orchestrator's wave-11 post-merge gate of 2026-10-22T09:37:47Z on commit 6679a32; plan 05-12's own run on 82928bd gave 60264 asserts and the wave-10 gate 60608 with the same 2653 tests, so the assert count varies by a few hundred between runs of the same code (per-frame assertions in e2e tests) and the script and test counts are the stable figures), the five replays byte-identical to their recorded digests (smoke 2599c7c2, army f7a967ed, walls bfb05fc7, economy f4b98093; full_idle afc11cd0 at 7000 ticks as 05-BALANCE-REPORT.md records), `GATE_OK enemies=300 crossed=300 stuck=0`, 44 real-window screenshots, CI run 39751537305 green on every job for 570ff8d. Every requirement of the phase is exercised by at least one green automated check (COVERED); no PARTIAL or MISSING entry, so no auditor was spawned. The one post-merge fix of the phase (commit f39b578 after wave 10: three tests and one shot outside plan 05-11's edit list met the new castle gate) was re-run in the wave-10 gate. One known flake class (an e2e hover or box-select test on a busy machine) is recorded in the orchestrator's flake ledger and passes alone.
