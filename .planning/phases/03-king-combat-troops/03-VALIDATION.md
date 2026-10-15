---
phase: "3"
slug: "king-combat-troops"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-09"
validated: "2026-10-13"
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT 9.7.1 on Godot 4.7.2-stable (GDScript, headless), gdtoolkit 4.5.0 lint |
| **Config file** | `.gutconfig.json` (dirs `tests/unit`, `tests/integration`, `tests/e2e`; JUnit to `build/test-results/gut-junit.xml`) |
| **Quick run command** | `bash tools/test.sh -gselect=<test_script_substring>` (one selection per invocation) |
| **Full suite command** | `bash tools/test.sh` then `bash tools/lint.sh`; replays `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` and `--scenario=army --twice --expect-file=tests/golden/army.json` |
| **Estimated runtime** | quick run 20-90 s per script; full suite 511 s after review-fix pass 2 (153 scripts, 1427 tests, 15886 asserts); lint 15 s |

---

## Sampling Rate

- **After every task commit:** Run `bash tools/test.sh -gselect=<the task's test scripts>` (executors did this for every RED and GREEN step; every tdd="true" task has a RED commit confirmed by `check tdd-red-evidence`)
- **After every plan wave:** Run `bash tools/test.sh` and `bash tools/lint.sh` (the orchestrator's post-merge gate ran after each of the 10 waves; every run green: 888, 929, 990, 1024, 1094, 1175, 1250, 1306, 1358, 1373 tests)
- **Before `/gsd-verify-work`:** Full suite must be green (last run 2026-10-12T08:19Z at HEAD b7db3d5: 1373/1373, lint clean, both goldens byte-identical, CI run 38219154906 green on lint, test, export and screenshots)
- **Max feedback latency:** 90 s for a single script, 11 min for the whole suite (the project's accepted latency since Phase 1; no 3-second runner exists for a Godot project)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | UNIT-04 | T-03-01 / T-03-02 / T-03-03 | MAX_UNITS_PER_SQUAD caps spawns; simulation/squads joins the no-Input source scan | tracer (unit + integration + e2e) | `bash tools/test.sh -gselect=test_squad_guard`, `-gselect=test_enemy_targets_units`, `-gselect=test_squad_determinism`, `-gselect=test_squad_tracer_scene` | ✅ | ✅ green |
| 3-01-02 | 01 | 1 | UNIT-04 | T-03-03 | Mini Characters zip hash checked before extraction; only two GLBs kept and logged | unit + e2e | `-gselect=test_squad_archers`, `-gselect=test_unit_views`, `-gselect=test_prototype_map_data` | ✅ | ✅ green |
| 3-02-01 | 02 | 2 | UNIT-07, UNIT-04 | T-03-04 | Respawn countdown runs only below the cap with a standing building | unit + integration | `-gselect=test_squad_respawn`, `-gselect=test_squad_lifecycle` | ✅ | ✅ green |
| 3-02-02 | 02 | 2 | UNIT-07, UNIT-04 | T-03-04 / T-03-05 | MapConfig reports every bad unit or squad number instead of arming it | unit + e2e | `-gselect=test_map_validate_squads`, `-gselect=test_military_data_contract`, `-gselect=test_spot_label_model`, `-gselect=test_building_models` | ✅ | ✅ green |
| 3-03-01 | 03 | 1 | UI-01 | T-03-06 | Stretch change landed alone with the full suite green before anything built on it | e2e | `-gselect=test_stretch_coordinates` then full suite | ✅ | ✅ green |
| 3-03-02 | 03 | 1 | UI-01 | T-03-06 | HudRoot and DayCounter are mouse_filter IGNORE (clear centre, no input capture) | e2e | `-gselect=test_hud_contract` | ✅ | ✅ green |
| 3-04-01 | 04 | 3 | KING-04 | T-03-07 | Slam goes through CommandProcessor with RUN_OVER / NO_ABILITY / KING_DOWN / ABILITY_COOLING reasons; hits enemies only | unit + e2e | `-gselect=test_weapon_def`, `-gselect=test_king_slam`, `-gselect=test_ability_input`, `-gselect=test_input_map` | ✅ | ✅ green |
| 3-04-02 | 04 | 3 | KING-05 | T-03-08 | A zero, negative or non-finite regen fraction switches regeneration off; never runs while down | unit + integration | `-gselect=test_king_regen`, `-gselect=test_king_respawn`, `-gselect=test_balance_acceptance` | ✅ | ✅ green |
| 3-04-03 | 04 | 3 | UI-01, KING-04 | T-03-06 | Widget stays inside x 16..376, y 624..704, outside the protected centre | e2e | `-gselect=test_king_widget`, `-gselect=test_hud_contract` | ✅ | ✅ green |
| 3-05-01 | 05 | 4 | UI-01, UNIT-07 | T-03-09 | Strip is read-only presentation; scales past six slots, never captures input | unit + e2e | `-gselect=test_squad_strip`, `-gselect=test_stance_glyph` | ✅ | ✅ green |
| 3-05-02 | 05 | 4 | UI-01 | T-03-09 | Overlay Squads section is read-only | unit | `-gselect=test_debug_overlay_squad_section`, `-gselect=test_debug_overlay_night_sections` | ✅ | ✅ green |
| 3-06-01 | 06 | 5 | UNIT-05, UNIT-06 | T-03-10 / T-03-11 | Order gate rejects empty lists, unknown ids and verbs outside the allow-list; every accepted order emits squad_ordered into the recorder | unit | `-gselect=test_squad_orders`, `-gselect=test_squad_order_intent`, `-gselect=test_squad_stance_persistence` | ✅ | ✅ green |
| 3-06-02 | 06 | 5 | UNIT-09 | T-03-10 | Selection lives in the input layer; the simulation never reads Input | unit + e2e | `-gselect=test_selection_model`, `-gselect=test_selection_math`, `-gselect=test_squad_selection` | ✅ | ✅ green |
| 3-06-03 | 06 | 5 | UNIT-05, UNIT-06, INPT-01 | T-03-10 | Command keys only act on a non-empty selection; a press with none shows a toast | e2e + unit | `-gselect=test_command_keys`, `-gselect=test_input_map` | ✅ | ✅ green |
| 3-07-01 | 07 | 6 | UNIT-10, INPT-01 | — | Owner decision (keep A; movement goes to the selection), recorded in 03-CONTEXT D-15 and the SUMMARY | checkpoint:decision | N/A (decision task; its outcome is pinned by 3-07-03's tests) | n/a | ✅ resolved by owner 2026-10-10 |
| 3-07-02 | 07 | 6 | UNIT-10 | T-03-12 / T-03-13 | MAX_QUEUE 9, MAX_PATROL_POINTS, BAD_POINT / TOO_MANY_POINTS / QUEUE_CLOSED gate reasons, ground_half_extent bounds; source scan forbids Input, InputEvent, Camera3D, Viewport, DisplayServer under simulation/ | unit | `-gselect=test_squad_point_orders`, `-gselect=test_squad_patrol`, `-gselect=test_squad_queue`, `-gselect=test_squad_point_validation`, `-gselect=test_sim_rules_guard`, `-gselect=test_map_validate_squads` | ✅ | ✅ green |
| 3-07-03 | 07 | 6 | UNIT-10, INPT-01 | T-03-13 | Ground picks clamp to the visible ground; the king takes no movement input while a squad is selected | unit + e2e | `-gselect=test_ground_pick`, `-gselect=test_mouse_commands`, `-gselect=test_king_selection_steering`, `-gselect=test_selection_steering`, `-gselect=test_input_map` | ✅ | ✅ green |
| 3-08-01 | 08 | 7 | UNIT-10 | T-03-14 | At most 6 queued discs drawn (MAX_DISCS_SHOWN), presentation only | e2e | `-gselect=test_order_markers` | ✅ | ✅ green |
| 3-08-02 | 08 | 7 | UNIT-09 | T-03-14 | A drag released off the ground is dropped; an empty box clears | unit + e2e | `-gselect=test_selection_math`, `-gselect=test_box_select` | ✅ | ✅ green |
| 3-08-03 | 08 | 7 | UNIT-09, INPT-01 | T-03-14 | Groups hold squad ids only; recalling an empty group keeps the selection | unit + e2e | `-gselect=test_control_groups`, `-gselect=test_control_group_keys`, `-gselect=test_input_map_groups` | ✅ | ✅ green |
| 3-09-01 | 09 | 8 | INPT-02, UNIT-09 | T-03-15 | Pad chords resolve deterministically; a capability table pins a path for every in-run action on both devices | unit + e2e | `-gselect=test_pad_chords`, `-gselect=test_input_capabilities`, `-gselect=test_pad_commands`, `-gselect=test_select_one_type` | ✅ | ✅ green |
| 3-09-02 | 09 | 8 | INPT-02, UNIT-10 | T-03-15 | Cursor clamped 48 px inside the visible rect; points go through GroundPick.to_centimetres / in_bounds | unit + e2e | `-gselect=test_ground_cursor`, `-gselect=test_pad_cursor`, `-gselect=test_camera_zoom` | ✅ | ✅ green |
| 3-10-01 | 10 | 9 | INPT-02, UI-01 | T-03-16 | Kenney Input Prompts zip hash-checked before extraction into an empty scratch directory; only used tiles kept and logged | unit | `-gselect=test_glyph_resolver`, `-gselect=test_prompt_glyph`, `-gselect=test_attribution_log` | ✅ | ✅ green |
| 3-10-02 | 10 | 9 | INPT-02, UI-01, KING-04 | T-03-17 | One device switch per 0.25 s with an axis threshold above the deadzone | unit + e2e | `-gselect=test_device_model`, `-gselect=test_prompt_switch`, `-gselect=test_command_hints`, `-gselect=test_start_night_hold`, `-gselect=test_king_widget` | ✅ | ✅ green |
| 3-11-01 | 11 | 7 | UNIT-04, UNIT-07, UNIT-10, KING-04 | T-03-18 | Army scenario runs on frozen fixtures that reference nothing under data/; bot orders go through intents only (source scan for random calls) | integration + unit | `-gselect=test_army_replay_golden`, `-gselect=test_replay_golden`, `-gselect=test_replay_cli_args`, `-gselect=test_balance_report`; `bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json` | ✅ | ✅ green |
| 3-11-02 | 11 | 7 | UNIT-04, UNIT-07 | T-03-19 | Night totals never decrease; per-night cap respected by MapConfig validation | unit + integration | `-gselect=test_playtest_strategies`, `-gselect=test_night_data_contract`, `-gselect=test_balance_acceptance`, `-gselect=test_military_data_contract` | ✅ | ✅ green |
| 3-12-01 | 12 | 10 | UI-01 | T-03-20 | ShotRunner.protected_violations fails any hud_/cmd_ shot with a HUD control inside x 384..896, y 96..500 | unit + real-window run | `-gselect=test_shot_protected_centre`, `-gselect=test_shot_list`; `bash tools/screenshot.sh` (33 of 33 saved) | ✅ | ✅ green |
| 3-12-02 | 12 | 10 | all phase IDs | T-03-20 | CI permissions unchanged (contents: read); only the screenshots timeout changed | CI | `gh run view 38219154906` (lint, test, export, screenshots all success; REPLAY_OK smoke, army, full_idle; 33 screenshots) | ✅ | ✅ green |
| 3-12-03 | 12 | 10 | all phase IDs | T-03-21 | Unsigned local build for the owner's playtest (accepted, no code-signing budget) | launch check | `bash tools/export.sh && timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` (exit 0 in 3 s) | ✅ | ✅ green |
| 3-13-01 | 13 | 1 (gap) | UNIT-10, UNIT-05, INPT-01 | T-03-22 | The queue flag is a plain bool inside the existing intent; CommandProcessor re-validates every intent (QUEUE_CLOSED, RUN_OVER, unknown squads) | tracer e2e (TDD RED then GREEN) | `bash tools/test.sh -gselect=test_command_keys` (3 Shift-queue cases) | ✅ | ✅ green |
| 3-13-02 | 13 | 1 (gap) | INPT-02, UNIT-10 | T-03-22 | Same gate for the pad RT path; real-window probe lines recorded in the SUMMARY | e2e + real-window probe | `bash tools/test.sh -gselect=test_pad_commands`, `bash tools/test.sh` (1377/1377) | ✅ | ✅ green |
| 3-14-01 | 14 | 1 (gap) | KING-05, UI-01 | T-03-23 | The handler only passes the event's hp and max_hp to HealthBar3D.set_health; no KingState writer is called | tracer e2e (TDD RED then GREEN) | `bash tools/test.sh -gselect=test_king_knockout` (bar follows each heal, hides at full) | ✅ | ✅ green |
| 3-14-02 | 14 | 1 (gap) | KING-05, UI-01 | T-03-23 | Read-only real-window measurement: sim, floating bar and widget agree at every heal | real-window probe + full suite | `bash tools/godot.sh --path . -s <probe>` (10 heals, 0.820 to 1.000 all equal), `bash tools/test.sh` (1378/1378) | ✅ | ✅ green |
| 3-15-01 | 15 | 1 (gap) | UI-01 | T-03-24 | StartNightPlate and its rows are mouse_filter IGNORE, pinned by the plate contract test; the prompt copy is unchanged | tracer e2e (TDD RED then GREEN) + shots | `bash tools/test.sh -gselect=test_start_night_plate` (6 tests), `bash tools/screenshot.sh hud_day_squads hud_day_squads_1080p` (clear-centre check), `bash tools/test.sh` (1384/1384) | ✅ | ✅ green |
| 3-16-01 | 16 | 1 (gap) | UNIT-04, UNIT-07 | T-03-25 | Tally only connects to SimEvents and reads defs; the smoke and army goldens replay unchanged | tracer integration (TDD RED then GREEN) | `bash tools/test.sh -gselect=test_balance_value_metric` (5 tests), `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`, `... --scenario=army ...` | ✅ | ✅ green |
| 3-16-02 | 16 | 1 (gap) | UNIT-04, UNIT-07 | T-03-26 | No new CLI argument; runs stay bounded by BalanceReport.MAX_TICKS, the 50-seed cap and PLAYTEST_TIMEOUT_S | bot measurement | `bash tools/playtest.sh --seeds=10` (PLAYTEST_OK runs=60; squad_value_ratio 0.68 baseline), `bash tools/test.sh` (1389/1389) | ✅ | ✅ green |
| 3-19-01 | 19 | 2 (gap) | UI-01 | T-03-31 | KingWidget reads KingState only; the count and caption keep alpha 1.0 on an opaque outline | tracer e2e (TDD RED then GREEN) + committed contrast probe | `bash tools/test.sh -gselect=test_king_widget` (4.5:1 fill over outline), `bash tools/contrast_probe.sh --image=screenshots/hud_king_down.png --rect=280,648,96,56 --min=4.5` (CONTRAST_OK ratio=5.88; 1.62 unfixed) | ✅ | ✅ green |
| 3-19-02 | 19 | 2 (gap) | UI-01 | T-03-31 | Hud.enemy_count_text is a pure formatter of the night counts | e2e (TDD RED then GREEN) + shots | `bash tools/test.sh -gselect=test_spawn_telegraph` (singular at one), `bash tools/screenshot.sh` (33 of 33), `bash tools/test.sh` (1392/1392) | ✅ | ✅ green |
| 3-17-01 | 17 | 3 (gap) | UNIT-04, UNIT-07, KING-04, KING-05 | T-03-27 | The four owner goals are contract tests that failed RED on the pre-retune data | integration + unit (TDD RED) | `bash tools/test.sh -gselect=test_balance_acceptance`, `bash tools/test.sh -gselect=test_night_data_contract` | ✅ | ✅ green |
| 3-17-02 | 17 | 3 (gap) | UNIT-04, UNIT-07, KING-04, KING-05 | T-03-27 / T-03-28 | Only two values moved (tower I interval 0.9 s, night 8 north grunts 11), each pinned old to new; 29 candidates, each measured in a private project copy; MapConfig.validate() clean; goldens byte-identical | bot measurement + contracts + replays | `bash tools/playtest.sh --seeds=10` (balanced 8, army_balanced 8, ratio 0.915, night 8 at 40), `bash tools/replay.sh --scenario=full_idle --twice` (digest recorded before and after), `bash tools/test.sh` (1397/1397) | ✅ | ✅ green |
| 3-18-01 | 18 | 4 (gap) | UNIT-04, UNIT-07, KING-04, KING-05 | T-03-29 / T-03-30 | Round 2 tables come from a fresh deterministic run on the committed data, checked against 03-17-SUMMARY.md | bot re-measurement + document grep | `bash tools/playtest.sh --seeds=10` (every figure equal to 03-17), grep of the five Round 2 headings | ✅ | ✅ green |
| 3-18-02 | 18 | 4 (gap) | all phase IDs | T-03-30 | screenshot.sh runs the existing bounded shot list; no data, code or test changed | shots + document check | `bash tools/screenshot.sh` (Saved 33 of 33, blank and clear-centre checks), hud_night_squad_down.png and night_combat.png read | ✅ | ✅ green |
| CR-01 fix (pass 1) | review | fix | UNIT-04 | T-03-04 / T-03-05 | `SquadSystem._fill` and `restore_for_dawn` loop once per missing seat and `UnitSystem.spawn` / `heal_to_full` floor stored health at 1, so a born-dead unit can no longer loop the spawn | unit (TDD RED: the suite hung on the unfixed code) | `bash tools/test.sh -gselect=test_squad_bad_unit_health` (3 tests), `-gselect=test_map_validate_squads` (14), `-gselect=test_squad_respawn` (14), both replay goldens | ✅ | ✅ green |
| WR-02 fix (pass 1) | review | fix | UI-01 | T-03-20 / T-03-30 | `tools/screenshot.sh` tees each shot to `build/screenshot-<shot>.log` and fails on `SCRIPT ERROR`, `Parse Error` or `Failed to load script` (the replay and playtest filter); ci.yml uploads the logs | shell check + one real shot | `bash -n tools/screenshot.sh`, one `bash tools/screenshot.sh day_overview` run (exit 0, log written, no error line), synthetic error-line filter check by the orchestrator | ✅ | ✅ green |
| WR-03 fix (pass 1) | review | fix | UNIT-10, INPT-01, INPT-02, UI-01 | T-03-22 | A refused queued order shows `Toast.QUEUE_CLOSED` on the Shift+F/H/R, Shift right-click and pad RT paths; the gate refuses only when every ordered squad is closed and `SquadSystem.apply_order` skips the closed ones | unit + e2e (TDD RED) | `-gselect=test_squad_queue` (17), `-gselect=test_command_keys` (17), `-gselect=test_mouse_commands` (16), `-gselect=test_pad_cursor` (10), `-gselect=test_pad_commands` (18), both replay goldens | ✅ | ✅ green |
| WR-04 fix (pass 1) | review | test | UI-01 | T-03-31 | The contrast probe's path guard (fifteen rejected paths) and measurement (WCAG ratios, red-on-outline at or above 4.5, red-on-grey below) are pinned | unit | `-gselect=test_contrast_probe` (10) | ✅ | ✅ green |
| IN-01 fix (pass 1) | review | cleanup | UNIT-10 | - | The dead patrol-leg budget assignment is removed; behaviour byte-identical (goldens) | existing suites | `-gselect=test_squad_patrol` (9), `-gselect=test_squad_queue` (17), both replay goldens | ✅ | ✅ green |
| IN-02 fix (pass 1) | review | fix | UNIT-10, INPT-01 | T-03-12 | One `MapConfig.ground_limit_cm` rule for the command gate and the ground picker, so the toast cannot disagree with the gate | unit (new case) | `-gselect=test_ground_pick` (9), `-gselect=test_squad_point_validation` (11), the five `test_map_validate_*` scripts (70), both replay goldens | ✅ | ✅ green |
| IN-03 fix (pass 1) | review | refactor | UNIT-04 | T-03-01 | `Separation.displacements` is one pure static routine shared by units and enemies; the end positions of both systems on a 12-unit cluster are pinned and identical before and after | unit (characterization, TDD RED) | `-gselect=test_separation` (7), `-gselect=test_enemy_targeting` (15), `-gselect=test_squad_guard` (14), both replay goldens | ✅ | ✅ green |
| IN-04 fix (pass 1) | review | docs | UNIT-04 | - | Doc comments only ("Test hook") on `anchor_of` and `squad_of`; no method added | lint | `bash tools/lint.sh` | ✅ | ✅ green |
| IN-05 fix (pass 1) | review | cleanup | UNIT-07 | - | Three unused `ext_resource` entries removed and `load_steps` lowered in the barracks and archery range scenes | scene test | `-gselect=test_building_models` (8) | ✅ | ✅ green |
| IN-06 fix (pass 1) | review | fix | UNIT-10, UI-01 | T-03-22 | The eighth patrol click shows `Toast.PATROL_FULL` and adds no point | e2e (TDD RED) | `-gselect=test_mouse_commands` (16) | ✅ | ✅ green |
| IN-07 fix (pass 1) | review | fix | UNIT-04, UNIT-07 | T-03-25 | `BalanceReport._mean` reads the run keys tolerantly, so `to_markdown` accepts every report `summary` accepts | integration (new case) | `-gselect=test_balance_value_metric` (6), `-gselect=test_balance_report` (19) | ✅ | ✅ green |
| IN-08 fix (pass 1) | review | refactor | UNIT-10, INPT-01, INPT-02 | T-03-22 | One `SelectionController.QUEUE_ACTION` read by the three order controllers, pinned against the Input Map | e2e (new case) | `-gselect=test_command_keys` (17), `-gselect=test_pad_cursor` (10), `-gselect=test_pad_commands` (18) | ✅ | ✅ green |
| IN-09 fix (pass 1) | review | test | UI-01 | T-03-24 | The start-night plate test reads `KingWidget.PLATE_COLOR`, so the two plates cannot drift apart silently | e2e | `-gselect=test_start_night_plate` (6), `-gselect=test_king_widget` (15) | ✅ | ✅ green |
| IN-10 fix (pass 2) | review | test | UI-01 | T-03-31 | The contrast probe's "outside the project" case is the project's parent folder (absolute and outside on Windows and on the Linux runner) and the test asserts it localizes outside `res://`, so the case cannot regress to an inside path silently | unit (TDD RED: 9/10 against the old expression) | `bash tools/test.sh -gselect=test_contrast_probe` (10 tests, 68 asserts) | ✅ | ✅ green |
| IN-11 fix (pass 2) | review | test | UNIT-04 | T-03-01 | `test_separation` builds its unit and enemy definitions inline (radii 0.45 / 0.4 / 0.5 / 0.45 as test constants) so a shipped-data retune cannot fail the pinned positions, keeps the private `_separate` seam with a comment, and `Separation.displacements` asserts its parallel-array precondition in debug builds (header note is the durable statement) | unit (characterization; decoupling probe) | `-gselect=test_separation` (7, 40 asserts), `-gselect=test_enemy_targeting` (15), `-gselect=test_squad_guard` (14), `-gselect=test_squad_orders` (13), `-gselect=test_squad_respawn` (14), `-gselect=test_ranged_enemy` (7), `-gselect=test_sim_rules_guard` (4), both replay goldens | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Requirement coverage: KING-04 (3-04-01, 3-04-03, 3-10-02, 3-11-01), KING-05 (3-04-02), UNIT-04 (3-01-01, 3-01-02, 3-02-01, 3-11-01, 3-11-02), UNIT-05 and UNIT-06 (3-06-01, 3-06-03), UNIT-07 (3-02-01, 3-02-02, 3-05-01, 3-11-02), UNIT-09 (3-06-02, 3-08-02, 3-08-03, 3-09-01), UNIT-10 (3-07-02, 3-07-03, 3-08-01, 3-09-02, 3-11-01), INPT-01 (3-06-03, 3-07-03, 3-08-03), INPT-02 (3-09-01, 3-09-02, 3-10-01, 3-10-02), UI-01 (3-03-01, 3-03-02, 3-04-03, 3-05-01, 3-05-02, 3-10-01, 3-10-02, 3-12-01). Every requirement is COVERED: the named scripts exist, target the behaviour, and ran green in the final full suite. UAT round-1 gap closure (2026-10-13) adds 3-13-01 to 3-18-02: UNIT-10 and UNIT-05 (3-13-01, 3-13-02), KING-05 (3-14-01, 3-14-02, 3-17-01, 3-17-02), UI-01 (3-14-01, 3-15-01, 3-19-01, 3-19-02), UNIT-04 and UNIT-07 (3-16-01, 3-16-02, 3-17-01, 3-17-02, 3-18-01), KING-04 (3-17-01, 3-17-02, 3-18-01), INPT-01 and INPT-02 (3-13-01, 3-13-02); every gap task has an automated command and the final full suite at HEAD dcf3ed1 is 150 scripts, 1397/1397 tests, lint clean. Review-fix pass 1 (2026-10-13, the 13 findings CR-01, WR-02 to WR-04 and IN-01 to IN-09, commits 56b2828 to e01971e) adds the thirteen `fix (pass 1)` rows: every behaviour-changing fix has a suite that fails with the fix switched off (probes below), the three cleanups (IN-01, IN-04, IN-05) change no behaviour (goldens byte-identical, lint clean), and the full suite at HEAD ca8086a is 153 scripts, 1427/1427 tests, lint clean (269 files). Review-fix pass 2 (2026-10-15, IN-10 and IN-11, commits db5e138 and 2471438) adds the two `fix (pass 2)` rows: test-only changes plus a debug-only precondition assert, no behaviour change (goldens byte-identical, shipped data untouched), and the full suite at HEAD 7f5cb65 is 153 scripts, 1427/1427 tests, 15886 asserts, lint clean (269 files).

Mutation probes recorded by the executors (behaviour switched off, the matching test failed, code restored): 03-07 steering rule disabled (4 of 7 steering e2e tests failed), 03-08 off-ground drag drop disabled, 03-09 `CameraRig.set_zoom_suppressed` made a no-op, 03-10 stick threshold `>=` changed to `>`.

Mutation probes run by the orchestrator at the 2026-10-13 re-audit (each fix switched off entirely, the named suite run, the file restored from a backup): 03-13 queue flag forced false (3 of 14 test_command_keys failed), 03-14 king_healed listener removed (1 of 5 test_king_knockout failed), 03-15 plate hidden by day (1 of 6 test_start_night_plate failed), 03-16 squad_value_ratio zeroed (1 of 5 test_balance_value_metric failed), 03-19 knocked-out label dimmed with the rest (2 of 15 test_king_widget failed), 03-19 singular copy removed (2 of 22 test_spawn_telegraph failed); 03-17's retune is covered by its own recorded RED run on the pre-retune data (three of the four goal tests failed on assertions).

Mutation probes run by the orchestrator at the 2026-10-14 re-audit after review-fix pass 1 (each fix switched off entirely, the named suite run, the file restored from a backup): CR-01 health clamp removed (3 of 3 test_squad_bad_unit_health failed, out-of-bounds on the empty living list) and the fill loop made to over-spawn by one (3 of 3 failed), WR-03 refusal toast returned empty (1 of 17 test_command_keys failed) and the gate reverted to any-closed (1 of 17 test_squad_queue failed), IN-02 ground limit uncapped (1 of 9 test_ground_pick failed), IN-03 separation push zeroed (5 of 7 test_separation failed), IN-06 patrol-full toast removed (1 of 16 test_mouse_commands failed), IN-07 strict mean restored (1 of 6 test_balance_value_metric failed with four invalid-access script errors), IN-08 queue action constant renamed (10 of 17 test_command_keys failed), IN-09 widget plate alpha retuned (1 of 6 test_start_night_plate failed), WR-04 probe fill key raised to 0.95 (3 of 10 test_contrast_probe failed); the WR-02 shell filter fired on a synthetic SCRIPT ERROR line and ignored an addons/gut line. IN-01, IN-04 and IN-05 change no behaviour (goldens byte-identical, lint clean) and were not probed.

Mutation probes run by the orchestrator at the 2026-10-15 re-audit after review-fix pass 2 (each change switched off or the data it decoupled retuned, the named suite run, the file restored from a backup): P1 IN-10 with the outside path reverted to the old inside-the-project expression: test_contrast_probe 9/10, 1 failing (the new localize-outside assertion, 67/68 asserts). P2 IN-11 decoupling with the shipped footman radius retuned 0.45 to 0.9 in data/units/footman.tres: test_separation 7/7 unchanged (before the fix the case loaded footman.tres and would have failed on the pinned positions). P3 with the shared routine pushing nothing (push = 0.0): test_separation 2/7, 5 failing on the pinned positions (the inline-def characterization still guards the routine). P4 with the new precondition assert removed: test_separation 7/7, no suite reacts by design (a debug-only guard over a precondition both callers already satisfy, documented in the header). Every file was restored from its backup and the tree was clean at the end (log: scratchpad/logs/mutate_fix2.log).

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No Wave 0 stubs were needed: GUT, the test directories, the replay goldens and the screenshot runner were in place from Phases 1 and 2, and every plan added its own scripts.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guard and commit readability at night; the puppet look (03-01 D8) | UNIT-04 | Visual judgement | Play a night with a Barracks and an Archery Range; watch units hold their post, commit to one grunt, and read as footmen and archers |
| Composed Barracks and Archery Range tier models (03-02) | UNIT-07 | Headless Godot cannot render; only scene use and tier growth are asserted | Build each plot to tier 3 and look at the models |
| 1920x1080 and 16:10 HUD layouts (03-03) | UI-01 | Captured by CI screenshots; the look is a judgement | Open `hud_day_squads_1080p.png` and `hud_night_squad_down_16x10.png` from the CI artifact |
| Slam ring and ready-flash feel (03-04) | KING-04 | Animation feel | Press Q near enemies; watch the ring and the icon flash when the cooldown ends |
| Squad slot look (03-05 D7) | UI-01 | Visual judgement | Compare the strip against the UI-SPEC at 1280x720 |
| Selection, follow, hold and rally feel (03-06 D9) | UNIT-05, UNIT-06, UNIT-09 | Feel | Select a squad, press F, H, R; judge the response |
| Attack-move on A with movement routed to the selection (03-07, owner decision) | UNIT-10, INPT-01 | Owner confirms the routing rule in play | Select a squad, hold A: the king must not move; press Escape, hold A: he rides left |
| Control-group auto-join question (03-08) | UNIT-09 | Owner preference | Build a new squad while a group exists; decide whether it should join |
| Pad layout, single-point pad patrol, cursor speed 900 px/s (03-09) | INPT-02 | Every pad event in tests was synthetic; no physical pad was available | Play one night on a real pad using LB layer, Start group mode, R3, RT and the right-stick cursor |
| Prompt tile legibility at 24 px; Xbox tiles on non-Xbox pads (03-10) | INPT-02, UI-01 | Visual judgement on a real monitor and pad | Switch between keyboard and pad mid-run and read the prompts |
| Balance feel: squads versus towers per gold; the balanced bot's 1-of-10 loss rate (03-11) | UNIT-04 | The bots measure the data; the owner judges difficulty | Read 03-BALANCE-REPORT.md and play three nights with an army |
| E6 longest toast inside x 384..896 (03-12) | UI-01 | The line is 526 px wide at x 377..903, 7 px past the literal band on each side, one line below the centre; left human_needed and logged as an unmet-truth in .planning/WINDOWS.md | Trigger "Can't go there. Click a point on the visible ground." and judge whether it intrudes on the play area |
| Balance feel after Round 2: the 0.9 s first tower as an opening, nights 5 to 8 at 25 / 31 / 39 / 40 with an army (03-17, 03-18) | UNIT-04, UNIT-07 | The bots measure the data (balanced 8 of 10, army 8 of 10, squad value 0.915); the owner judges feel at the gate | Play two or three full runs with an army on both devices (UAT test 15) and compare against `03-PLAYTEST-GATE.md` |
| Bottom-centre hierarchy with the plate, the opaque knocked-out count and the singular copy as seen in play (03-15, 03-19) | UI-01 | Measured in tests and the contrast probe; whether the prompt leads and the count reads by eye is a judgement | Re-check UAT tests 13 and 14 on the fixed build |
| Refused-queue and patrol-full toasts as seen in play (review-fix pass 1: WR-03, IN-06) | UNIT-10, UI-01 | Copy, timing and the refusal paths are pinned by tests; whether the line reads at the moment of refusal is a judgement | Select a squad, queue a hold (Shift+H) then Shift+F: read "Nothing can be queued after Hold, Follow or Patrol"; arm patrol and right-click eight points: the eighth shows "A patrol takes up to 7 points" |

All of these are owner items in `03-PLAYTEST-GATE.md`; `/gsd-verify-work 3` walks them.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (46 of 47 tasks after the gap round; 3-07-01 is an owner decision task whose outcome 3-07-03's tests pin)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none)
- [x] No watch-mode flags (GUT runs with `-gexit`)
- [x] Feedback latency within the project's accepted bound (single script under 90 s; full suite 11 min)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-12 (validate-phase audit, state A); re-approved 2026-10-13 after the UAT round-1 gap closure (state A re-audit); re-approved 2026-10-14 after review-fix pass 1 (state A re-audit); re-approved 2026-10-15 after review-fix pass 2 (state A re-audit)

## Validation Audit 2026-10-12
| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit basis: 12 PLAN and 12 SUMMARY files, the per-plan test scripts listed in each SUMMARY's `key-files`, the ten post-merge gate runs, the final full suite at HEAD b7db3d5 (148 scripts, 1373/1373, 15367 asserts), lint clean, smoke and army goldens byte-identical, CI run 38219154906 green. No auditor spawn was needed.

## Validation Audit 2026-10-13
| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit basis (UAT round-1 gap closure, plans 03-13 to 03-19): 7 PLAN and 7 SUMMARY files, 13 tasks each with an automated command (12 test or replay commands, 1 bounded screenshot run), every TDD task with a RED commit before its GREEN commit, the four post-merge gate runs (1389, 1392, 1397 and the empty-diff wave 4), the final full suite at HEAD dcf3ed1 (150 scripts, 1397/1397), lint clean (265 files), smoke and army goldens byte-identical, the full_idle digest recorded before and after the retune, 33 of 33 real-window shots. Mutation probes above: every gap fix is caught by its own suite when switched off. No auditor spawn was needed.

## Validation Audit 2026-10-14 (after review-fix pass 1)
| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit basis (review-fix pass 1, 2026-10-13: the 13 open findings of 03-REVIEW-DISPOSITION.md fixed in 13 commits, 56b2828 to e01971e, one per finding, each with a scoped suite run recorded in 03-REVIEW-FIX.md): three new test scripts (test_squad_bad_unit_health, test_contrast_probe, test_separation) and new cases in five existing scripts, TDD RED recorded for every finding that asked for a test, the orchestrator's full suite at HEAD ca8086a (153 scripts, 1427/1427, 15885 asserts, 535 s), lint clean (269 files), smoke and army goldens byte-identical (703 and 1353 ticks), CI run 38473757849 green. Mutation probes above: every behaviour-changing fix is caught by its own suite when switched off; the shell filter of WR-02 fires on a synthetic error line and ignores addons/gut noise. No auditor spawn was needed.

## Validation Audit 2026-10-15 (after review-fix pass 2)
| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit basis (review-fix pass 2, 2026-10-15: the two open info findings of the fourth review, IN-10 and IN-11, fixed in commits db5e138 and 2471438, one per finding, each with a scoped suite run recorded in 03-REVIEW-FIX.md; ledger 0 of 16 open): no new test script, two test scripts changed and one debug-only precondition assert added, TDD RED recorded for IN-10, the orchestrator's full suite at HEAD 7f5cb65 (153 scripts, 1427/1427, 15886 asserts), lint clean (269 files), smoke and army goldens byte-identical (703 and 1353 ticks), CI run 38774381177 green. Mutation probes above: the IN-10 assertion catches the old inside-the-project path, the IN-11 characterization no longer reacts to a shipped radius retune and still fails when the routine stops pushing; the precondition assert is a documented debug-only guard that no suite exercises by design (a mismatched-length call is a script error, not a behaviour). No auditor spawn was needed.
