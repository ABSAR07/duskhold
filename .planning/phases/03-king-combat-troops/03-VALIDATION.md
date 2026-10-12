---
phase: "3"
slug: "king-combat-troops"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-09"
validated: "2026-10-12"
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
| **Estimated runtime** | quick run 20-90 s per script; full suite 630 s at the end of the phase (148 scripts, 1373 tests, 15367 asserts); lint 15 s |

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

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Requirement coverage: KING-04 (3-04-01, 3-04-03, 3-10-02, 3-11-01), KING-05 (3-04-02), UNIT-04 (3-01-01, 3-01-02, 3-02-01, 3-11-01, 3-11-02), UNIT-05 and UNIT-06 (3-06-01, 3-06-03), UNIT-07 (3-02-01, 3-02-02, 3-05-01, 3-11-02), UNIT-09 (3-06-02, 3-08-02, 3-08-03, 3-09-01), UNIT-10 (3-07-02, 3-07-03, 3-08-01, 3-09-02, 3-11-01), INPT-01 (3-06-03, 3-07-03, 3-08-03), INPT-02 (3-09-01, 3-09-02, 3-10-01, 3-10-02), UI-01 (3-03-01, 3-03-02, 3-04-03, 3-05-01, 3-05-02, 3-10-01, 3-10-02, 3-12-01). Every requirement is COVERED: the named scripts exist, target the behaviour, and ran green in the final full suite.

Mutation probes recorded by the executors (behaviour switched off, the matching test failed, code restored): 03-07 steering rule disabled (4 of 7 steering e2e tests failed), 03-08 off-ground drag drop disabled, 03-09 `CameraRig.set_zoom_suppressed` made a no-op, 03-10 stick threshold `>=` changed to `>`.

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

All of these are owner items in `03-PLAYTEST-GATE.md`; `/gsd-verify-work 3` walks them.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (33 of 34 tasks; 3-07-01 is an owner decision task whose outcome 3-07-03's tests pin)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none)
- [x] No watch-mode flags (GUT runs with `-gexit`)
- [x] Feedback latency within the project's accepted bound (single script under 90 s; full suite 11 min)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-12 (validate-phase audit, state A)

## Validation Audit 2026-10-12
| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit basis: 12 PLAN and 12 SUMMARY files, the per-plan test scripts listed in each SUMMARY's `key-files`, the ten post-merge gate runs, the final full suite at HEAD b7db3d5 (148 scripts, 1373/1373, 15367 asserts), lint clean, smoke and army goldens byte-identical, CI run 38219154906 green. No auditor spawn was needed.
