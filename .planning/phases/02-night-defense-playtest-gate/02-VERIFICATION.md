---
phase: 02-night-defense-playtest-gate
verified: 2026-10-05T15:24:18Z
status: human_needed
score: 3/4 roadmap success criteria verified (SC4, the owner playtest gate, has not happened); 11/11 requirement IDs have implementation evidence
covered_files:
  - .planning/phases/02-night-defense-playtest-gate/02-01-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-01-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-02-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-02-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-03-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-03-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-04-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-04-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-05-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-05-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-06-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-06-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-07-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-07-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-08-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-08-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-09-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-09-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-10-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-10-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-11-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-11-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md
  - .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
  - data/enemies/grunt.tres
  - data/king/king.tres
  - data/maps/prototype_map.tres
  - data/tuning/loop_tuning.tres
  - presentation/king/king.gd
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - project.godot
  - simulation/buildings/building_system.gd
  - simulation/king/king_state.gd
  - simulation/night/enemy_system.gd
  - simulation/night/night_sim.gd
  - simulation/night/wave_schedule.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - tests/golden/smoke.json
  - ui/hud/dawn_no_income_marker.gd
  - ui/hud/hud.gd
  - ui/overlay/night_overlay_sections.gd
  - ui/results/results_screen.gd
  - ui/world/spawn_telegraph.gd
covered_digest: "v2:sha256:768a52454ee84f0fb837cb168e6b44cd7c19b6beb7b218b71f86cacf2653e4d6"
behavior_unverified: 0
overrides_applied: 0
re_verification: false
gaps: []
deferred: []
human_verification:
  - test: "Owner playtest gate (ROADMAP SC4, D-18): play one or two full 8-night runs on the exported build and either sign off or record the fixes that must land before Phase 3"
    expected: "A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change"
    why_human: "Fun, tension, fairness and readability are the owner's judgement. Bot results and Claude's screenshot review are explicitly not the sign-off. No 02-UAT.md exists."
  - test: "Results screen layout and the accidental-restart tap (WR-03)"
    expected: "Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel; tapping Space or gamepad A as Victory/Defeat appears does not restart the run before the stats can be read"
    why_human: "Layout is a visual judgement; the tap is a feel/timing test. The code review finding is still open (see Warnings)."
  - test: "Enemy, health-bar, projectile and slash readability at night at the default camera"
    expected: "Red grunts and violet skirmishers are told apart and read against the dark ground; hurt-only bars on enemies, king, castle and buildings are legible; arrows (now 15 cm x 1 m) are visible; the king's slash is visible"
    why_human: "Summaries 02-03, 02-04, 02-05 and 02-08 record these as verified by state only. Claude's screenshot review is not the owner's judgement."
  - test: "Ghost king and knockout countdown"
    expected: "On a knockout the king becomes a cyan ghost that cannot be steered, 'Knocked out - back in N s' reads clearly, and the king reappears at the castle on time; respawn times (6, 10, 14, 15 s) feel like a cost but not a punishment"
    why_human: "Visual and feel; plan 02-03 verified by state only. Also the gamepad feel while down."
  - test: "Rubble and collapse"
    expected: "A destroyed House or tower collapses over about 0.9 s into rubble that is readable against the dark ground and on the pale plot disc"
    why_human: "Plan 02-04 verified by state only; the rubble is dark on dark."
  - test: "Spawn telegraph markers and the night preview line"
    expected: "By day each spawn point that will send enemies shows a red disc with its count (44 px on 1280x720) or an edge arrow when off screen, and 'Night N: X enemies from Y directions' sits under the start-night prompt; the player can plan from them"
    why_human: "Look and size were verified by placement/state and by Claude's screenshot only (02-08)."
  - test: "Crossed-out coin over rebuilt Houses at dawn"
    expected: "Each rebuilt House shows a crossed-out gold coin (26 px, on a red roof) and the player understands it pays nothing this dawn; it fades when the day starts"
    why_human: "Small and low-contrast per the packet; 02-06 verified by state and count only."
  - test: "Debug overlay path lines (F3) during a night"
    expected: "Enemy-to-target and road lines are visible enough at game camera distance (currently 1-pixel hairlines); Wave, King and Paths sections read correctly"
    why_human: "The packet records the lines as faint; whether that matters is the owner's call."
  - test: "Loss beat and results screen in a real defeat and a real victory"
    expected: "On defeat the castle collapses for about 1.2 s, then the Defeat screen; on victory the screen appears at once; Play again starts a fresh run from day 1 and Quit closes the game; the screen works with keyboard, gamepad and mouse"
    why_human: "Assumption 9 and the collapse look were untested by eye (02-07)."
  - test: "Hand-steered king, ride cost and gamepad feel at night; night 3 fairness"
    expected: "The king handles well when steered by hand; riding between plots costs a meaningful amount of day; night 3 (king alone against two roads) feels fair to a first-time player; gamepad play at night works"
    why_human: "Packet 'What nobody has checked'. The bots build without riding and react perfectly."
  - test: "The 13 assumptions on the owner's behalf"
    expected: "Owner confirms or changes each; in particular full dawn repair (1), no last dawn payout after night 8 (2), 6/10/14/15 s respawn (10), the 4-gold opening (13). Also the Play again behaviour recorded in 02-07 (a new random seed, so a replayed run is not the same run) is flagged in the summary but is not one of the 13"
    why_human: "Product decisions made for the owner."
---

# Phase 2: Night Defense & Playtest Gate Verification Report

**Phase Goal:** The prototype map plays the full day -> night -> dawn loop. The player sees each night coming and starts it deliberately, defends with the king and basic towers, rebuilds and collects income at dawn, and wins or loses on a results screen. Seeded nights replay deterministically, and the owner confirms the loop is fun before anything is built on top of it.
**Verified:** 2026-10-05T15:24:18Z
**Status:** human_needed
**Re-verification:** No, initial verification

## Verdict

The engineering part of the goal is achieved and was checked against the code, not the summaries: the loop plays, nights are seeded and replay to identical digests, and every requirement has implementation and test evidence. The last clause of the goal, "the owner confirms the loop is fun before anything is built on top of it", is not achieved yet and cannot be by an agent. ROADMAP success criterion 4 is a human gate that has not happened (no 02-UAT.md, no recorded decision). The phase therefore must not be marked complete, and Phase 3 must not start, until the owner decides. There are no FAILED truths and no blockers in the code; three code-review warnings are open and one of them (WR-03) bears on the owner's playtest.

## What I ran and read

Ran in my own process (none of this is taken from a summary):

| Check | Command | Result |
|---|---|---|
| Full suite | `bash tools/test.sh` | 85 scripts, 719 tests, 719 passing, 8527 asserts, 253.6 s, exit 0 |
| Lint and format | `bash tools/lint.sh` | "155 files would be left unchanged", "no problems found" |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK ... outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (matches `tests/golden/smoke.json`) |
| Full-run replay | `bash tools/replay.sh --scenario=full_idle --twice` | `REPLAY_OK ... outcome=won ticks=6244 digest=a25aa7fd...` (matches the packet) |
| CI | `gh run view 37325147907` | lint, test, export, screenshots all succeeded on `dd5428c` |
| Source drift | `git diff dd5428c HEAD --name-only` outside `.planning/` | empty: no source change since the pushed, CI-green commit |
| Debt markers | grep `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER` over simulation, presentation, ui, tools, tests, data | none (the `placeholder_night_seconds` hits are a field name) |
| Forbidden APIs in `simulation/` | grep for global random, Time, OS, get_tree, servers, transcendental math | none; `pow` only in `loop_tuning.gd` coin pacing (not in the digest path), `sqrt` in `EnemySystem._separate` (exactly rounded) |
| Processes | `tasklist` after the runs | no Godot process left; `git status` shows only the pre-existing `.planning/config.json` change |

Read in full: `run_manager.gd`, `run_context.gd`, `night_sim.gd`, `enemy_system.gd`, `king_state.gd`, `building_system.gd`, `results_screen.gd`, `hud.gd`, `map_root.gd`, `loop_tuning.tres`, `king.tres`, `grunt.tres`, `02-REVIEW.md`, `02-REVIEW-DISPOSITION.md`, `02-PLAYTEST-GATE.md`. Read in part: `wave_schedule.gd` (preview_counts and take_due), `king.gd` (signal wiring), `dawn_no_income_marker.gd`, `spawn_telegraph.gd` and `prototype_map.tres` (grep of wiring, spawn points and counts), `project.godot` input section, `prototype_map.tscn` node list. Viewed screenshots `results_defeat.png` and `night_combat.png`; both match the packet's description, including the results layout issue (stat rows touching the buttons, Quit nearly invisible).

Taken from a summary or report without re-checking: the balance table (`02-BALANCE-REPORT.md`, I did not run `tools/playtest.sh`); the Windows export launching (I did not run `tools/export.sh` or the exe, only confirmed CI's export job passed); the Linux/Windows digest equality (CI's replay step passed on Linux against the same golden); the other 13 screenshots; 02-VALIDATION.md and 02-SECURITY.md (read only as existing, not re-audited); the individual test bodies behind each plan's edge-case truths (covered by the suite passing, not read one by one).

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | No day timer; per-spawn-point counts shown; hold-to-confirm start; enemies damage and visibly destroy buildings; king auto-attacks; knocked-out king respawns at the castle after a visible countdown | VERIFIED in code and tests; visual quality for the owner | `RunManager` leaves DAY only in `start_night()`, and `get_phase_time_remaining` returns 0 for DAY and for an authored night; `test_no_day_timer.gd` passes. `SpawnTelegraph` binds to `phase_changed`/`day_started`, `Hud._refresh_preview` uses `WaveSchedule.preview_counts` and prints "Night N: X enemies from Y directions". `NightSim._resolve_hits` routes building hits to `BuildingSystem.damage_building` (emits `building_destroyed` once, drops hits on fallen buildings); `BuildingViews` swaps to `RubbleView`. `KingState.step` attacks the nearest enemy in range every `attack_interval` ticks. `KingState.take_damage` knocks out at 0, countdown `SimClock.ticks(respawn_seconds(n))` with 6/10/14/15 from `loop_tuning.tres`, `_respawn()` returns him to the spawn at full health; `Hud._refresh_respawn` shows "Knocked out - back in N s" (rounded up); `King` switches to the ghost on `king_downed`. |
| 2 | Night ends only when every enemy is dead; dawn rebuilds destroyed buildings free, surviving Houses pay tier income, rebuilt ones visibly marked as paying nothing; results screen on loss (instant when the castle falls) or win after the final night | VERIFIED in code and tests | `RunManager._night_should_end` returns `NightSim.is_cleared()` (schedule finished and zero enemies) on authored maps. `_enter_dawn` calls `rebuild_destroyed()` (no gold), `repair_standing()`, castle and king restore, then `_apply_dawn_payout()`; `dawn_income_by_spot` skips `destroyed` and `rebuilt_this_dawn`. `DawnNoIncomeMarker` binds `buildings_rebuilt` and fades on `day_started`. `RunContext.step` calls `end_run_in_defeat()` in the same step the castle is destroyed, before `tick`, so loss beats a same-step win; `_end_night` goes straight to WON on the last authored night (8, count from `prototype_map.tres` and `get_total_nights`). `ResultsScreen` shows Victory at once, Defeat after `loss_beat_seconds` (1.2 s), with the five stats. Ordering and edge cases are pinned by `test_run_outcomes.gd`, `test_dawn_rebuild.gd`, `test_building_damage.gd`; all in the 719 passing. |
| 3 | Seeded scripted night replays identically from the command line and in CI; GUT covers waves, combat and loop transitions; during nights the debug overlay shows live enemy counts, wave state and enemy paths | VERIFIED | Both replay scenarios printed `REPLAY_OK` twice-in-process with identical digests, and smoke matches the checked-in golden; CI ran the same on Linux. `SimRng` splitmix streams are the only randomness in `simulation/` (grep clean); `test_sim_rules_guard.gd`, `test_determinism.gd`, `test_replay_golden.gd` pass. `DebugOverlay` calls `NightOverlaySections.register(...)` (`debug_overlay.gd:57`), which adds the Wave, King and Paths sections and the `EnemyPathGizmo`. |
| 4 | Human playtest gate: owner plays several full runs and signs off or records fixes; no meta-progression scheduled until then | NOT ACHIEVED, awaiting the owner | `02-PLAYTEST-GATE.md` is the packet; no owner decision exists anywhere, no `02-UAT.md`. Plan 02-11's own truth for this is marked `verification: backstop`, so it cannot be satisfied by tests. |

### Plan must_haves (spot-verified; the rest rest on the green suite)

| Plan | Truth checked against code | Status |
|---|---|---|
| 02-01 | Fixed 30 Hz step through `RunContext.advance` with clamp; night ends only on `is_cleared()`; DR-8 order spawn, king, towers, enemies, resolve, remove in `NightSim.step`; timed-night fallback kept for waveless maps; digest stable | VERIFIED |
| 02-01 prohibition | No gold for kills or other night events: `Economy.grant` is called only from `_apply_dawn_payout` in the files read; no kill bounty path found | VERIFIED (judgment tier, my reading; not a formal audit) |
| 02-03 | Enemy target priority (king in aggro, leash, structures by edge distance, castle last); castle and king integer health; knockout idempotent (`take_damage` returns while `_down`); respawn reset per night (`begin_night`); dawn restores the king and emits `king_respawned` once | VERIFIED |
| 02-04 | Integer building health, destroyed buildings stop being targets, pay nothing, hits dropped, `building_destroyed` once; `damage_building` clamps at 0 | VERIFIED |
| 02-05 | Towers shoot in `NightSim.step` between king and enemies; ranged enemy via `projectile_speed` flight ticks; killer kind recorded | VERIFIED (code path read in `enemy_system.gd` and `night_sim.gd`; `tower_system.gd` not read, covered by passing `test_tower_combat`) |
| 02-06 | Free rebuild at the tier it had, once per dawn, in MapConfig order; rebuilt building pays 0 that dawn and income the next; marks cleared at `start_night` | VERIFIED. Deviation: the plan named a `was_rebuilt_this_dawn` method on `BuildingSystem`; it was not added (lint method cap). The behaviour lives in `BuildingInstance.rebuilt_this_dawn` read by `dawn_income_by_spot`, so the truth holds and the deviation is cosmetic. |
| 02-07 | WON/LOST terminal (`tick` and `step` return when `is_run_over()`), loss beats win, no last dawn payout, results screen with Play again and Quit, focus on Play again, mouse only on the screen's buttons | VERIFIED |
| 02-08 | `StartNightIntent` only way out of DAY; telegraph, preview line, banner "Night N of T - K enemies left", overlay sections read-only | VERIFIED |
| 02-09 | Replay CLI, wrapper, golden, CI step | VERIFIED (ran both replays; CI green) |
| 02-10 | Bot strategies, balance report, tuning only on combat/wave data (costs and starting gold unchanged) | PARTLY CHECKED: tuning values in `king.tres`, `grunt.tres`, `loop_tuning.tres` match the packet's assumption 13; the win-rate table is taken from `02-BALANCE-REPORT.md`; `test_balance_report.gd` and `test_playtest_strategies.gd` pass |
| 02-11 | 15 screenshots, shot-list drift guard, packet with 13 assumptions, CI green, local export | VERIFIED for the drift guard (test passes), CI (green) and the packet (read); export launch not re-run. The owner-decision truth is `backstop` and stays open (SC4). |
| 02-02 | Eight authored nights, three spawn points, grunt-only nights 1-3 and ranged from night 4 (prototype_map.tres groups) | VERIFIED by the data read and `test_night_data_contract.gd` passing |

Prohibitions: every `must_haves.prohibitions` item in the plans is judgment-tier and was marked resolved by the executors. My independent reading supports: no day timer (RunManager has no day clock), no meta reward on the results screen (`ResultsScreen` shows only outcome and the five stats), mouse bound to no gameplay action (the results screen is the only mouse consumer I found; `project.godot` has no mouse binding for gameplay actions in the section I read), no gold on knockout (`take_damage` touches no economy), no charge for the dawn rebuild (`rebuild_destroyed` takes no economy). These remain NON-AUTHORITATIVE judgments, not formal proof; the asset and secret-publication prohibitions (02-04, 02-05, 02-09, 02-11) I did not audit and rely on 02-SECURITY.md (26 of 26 threats closed) as stated.

### Requirements Coverage

All 11 IDs in the phase's ROADMAP line appear in at least one plan's `requirements:` frontmatter, and plan 02-11 lists all 11. No REQUIREMENTS.md ID mapped to Phase 2 is orphaned. LOOP-08 is mapped to Phase 9 and correctly pending.

| Requirement | Plans | Description | Status | Evidence |
|---|---|---|---|---|
| LOOP-01 | 02-08, 02-11 | No day timer; deliberate hold-to-confirm night start | SATISFIED | `RunManager.start_night` is the only exit from DAY; `test_no_day_timer.gd` (10 simulated minutes of DAY) and `test_start_night_hold.gd` pass |
| LOOP-02 | 02-08, 02-11 | Icon at each spawn point showing enemy count | SATISFIED in code; look needs owner | `SpawnTelegraph`, `WaveSchedule.preview_counts`, Hud preview line; `test_spawn_telegraph.gd` passes |
| LOOP-03 | 02-01, 02-02, 02-11 | Night ends only when every spawned enemy is dead | SATISFIED | `NightSim.is_cleared`, `RunManager._night_should_end` |
| LOOP-04 | 02-06, 02-11 | Destroyed buildings rebuilt free at dawn | SATISFIED | `BuildingSystem.rebuild_destroyed`, `RunManager._enter_dawn` |
| LOOP-05 | 02-06, 02-11 | Survivors pay income; rebuilt pay nothing and are marked | SATISFIED in code; marker size for owner | `dawn_income_by_spot`, `DawnNoIncomeMarker` |
| LOOP-06 | 02-07, 02-11 | Loss the instant the castle falls | SATISFIED | `RunContext.step` calls `end_run_in_defeat` before `tick` |
| LOOP-07 | 02-01/02-02 (via 02-07), 02-11 | Win after the final night, results screen | SATISFIED | `RunManager._end_night` to WON, `ResultsScreen` |
| KING-03 | 02-01, 02-05, 02-11 | King auto-attacks enemies in range | SATISFIED | `KingState.step` with `TargetQuery.nearest_enemy` |
| KING-06 | 02-03, 02-11 | Knockout, visible countdown, respawn at the castle, run continues | SATISFIED in code; visuals for owner | `KingState`, `Hud._refresh_respawn`, `King` ghost |
| BLDG-07 | 02-04, 02-05, 02-11 | Buildings have health, take damage, visibly destroyed | SATISFIED in code; rubble readability for owner | `BuildingSystem.damage_building`, `RubbleView` |
| DEV-05 | 02-01, 02-08, 02-09, 02-10, 02-11 | Seeded deterministic simulation, scripted full-night playthrough tests | SATISFIED | Replays, golden, determinism and rules-guard tests |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|---|---|---|---|---|
| `Hud` banner and preview | `remaining_count`, `preview_counts` | `NightSim` schedule and `MapConfig.nights` from `prototype_map.tres` | Yes | FLOWING |
| `Hud` respawn label | `respawn_seconds_remaining` | `KingState` ticks from `loop_tuning.tres` | Yes | FLOWING |
| `ResultsScreen` stats | `RunStats` | Fed by `SimEvents` (`dawn_payout`, `building_destroyed`, `king_downed`, `run_ended`) | Yes | FLOWING |
| `SpawnTelegraph` | `preview_counts` | Same map data | Yes | FLOWING |
| Debug overlay Wave/King/Paths | `NightSim`, `KingState`, `EnemySystem.target_of` | Live simulation | Yes | FLOWING |

### Anti-Patterns Found

None blocking. No debt markers, no stubs, no hardcoded empty data flowing to the UI.

## Open code-review findings (all nine open; none addressed)

`02-REVIEW-DISPOSITION.md` records all nine as `open`. No fix pass has run, and I do not describe any as addressed. Weighed against the goal:

| ID | Verdict | Weighing |
|---|---|---|
| WR-03 | WARNING that touches SC2 and the playtest | Confirmed in `project.godot`: `action_build` is Space, E and gamepad A; `ui_accept` is Enter, Keypad Enter, Space and gamepad A. `ResultsScreen._show_results` calls `grab_focus()` on "Play again" with no grace window, and Victory shows in the same step the last enemy dies. A fresh tap of Space or A at that moment presses "Play again" and reloads the scene, losing the stats; E users are not affected. The results screen still appears, so SC2's wording ("the run ends on a results screen") holds, but a player can lose it before reading it, in the owner's very first full run. I rate it WARNING, not BLOCKER: it is an input-timing hazard, not a missing feature, and it is cheap to fix (input grace window). It should be fixed or consciously accepted before the owner plays, and the owner should be told. |
| WR-01 | WARNING, latent | `MapConfig.validate()` does not reject an enemy with `aggro_range < attack_range`, which would leave a real (clockless) night unable to end. Shipped data is safe (grunt 6.0 > 1.2, ranged 9.0 > 7.0, covered by `test_every_night_ends`). Affects future data only, but Phase 3+ will author more enemies. |
| WR-02 | WARNING, latent | The 300-per-night cap is advisory; `WaveSchedule` caps a group at 500, so oversized data is not stopped at runtime. Shipped nights are far below it. Matters for hostile or sloppy data, not for the Phase 2 goal. |
| IN-01 to IN-06 | INFO | Telegraph/schedule mismatch only on bad data; an arrow in flight at night end is dropped (an unstated rule); two `bind_run` calls lack the repeat-bind guard (MapRoot binds once); the replay wrappers ignore `push_error`; some e2e tests budget real seconds; screenshot job timeout equals worst case. None affects a must-have. |

None of the nine is a FAILED must-have, so none produces `gaps_found`. The orchestrator should still triage them (`fixed`, `skipped` or `deferred`) rather than leave all nine at `open`, and WR-03 deserves a decision before the owner's playtest.

## Flagged assumptions: packet versus summaries

The packet's 13 numbered assumptions cover the items the summaries flagged, with two partial mismatches:

- 02-06 flagged full repair at dawn: packet item 1. Match.
- 02-07 flagged the final night ending straight on Victory with no last payout, and the Victory screen having no beat: packet items 2 and 9. Match.
- 02-07 also flagged that Play again reloads the scene with a new random seed (D-16), and that the collapse look and results layout are untested by eye. The new-seed behaviour is not one of the 13 (item 7 is about seeds in the overlay, not about Play again); the layout is covered by the packet's "open readability points". Minor gap: add Play again's new-seed behaviour to the list.
- Summaries 02-03, 02-04, 02-05, 02-08 flagged no numbered assumptions, only visual-by-state items; those are harvested into the human_verification list above. Packet items 3, 4, 5, 8, 10, 11, 12, 13 come from plan decisions and the balance work (02-03, 02-05, 02-09, 02-10), not from a "Flagged Assumptions" heading, so I could not match them to a summary line one by one.

## Deviations checked

| Deviation | Result |
|---|---|
| `was_rebuilt_this_dawn` not added to BuildingSystem (02-06) | Behaviour present via `BuildingInstance.rebuilt_this_dawn`; LOOP-05 truths verified; no must-have fails |
| `full_idle` plays the balanced bot (02-10) | Ran it: won, 6244 ticks, two identical digests. It is now a balanced full run, not an idle one; the scenario name is misleading but the plan's truth (two complete runs, matching digests) holds |
| Building-targeting tests in `test_building_targeting.gd` (02-04) | File exists and passes within the 719; cosmetic path deviation |
| `project.godot` gained `ui_accept`, `ui_left`, `ui_right` (02-07) | Confirmed. This is the source of WR-03 (shared Space and gamepad A with `action_build`) |

## Human Verification Required

The structured list is in the frontmatter. In short, the owner must (1) play one or two full runs on `build/windows/Duskhold.exe` or the editor binary and record sign-off or fixes through `/gsd-verify-work`; (2) judge the visual items that executors verified by state only (health bars, ghost king, rubble, spawn markers, projectiles, crossed-out coin, results layout, overlay path lines); (3) try the end-of-run tap hazard; (4) confirm or change the 13 assumptions and the Play again new-seed behaviour. The readability points the 02-11 executor already recorded outside its files (results layout, hairline path lines, 26 px crossed-out coin) are the first things to look at.

## Gaps Summary

No code gaps. The phase is `human_needed` because success criterion 4 (the owner playtest gate) has not happened, and that is by design: it blocks Phase 3 and any meta-progression work until the owner decides. Recommended before the owner plays: decide WR-03 (a fix is a few lines in `ResultsScreen` plus an e2e assertion), and record a disposition for the other eight findings. Do not treat the 719 green tests, the replay digests, CI, the balance table or the screenshot review as the sign-off.

---

_Verified: 2026-10-05T15:24:18Z_
_Verifier: Claude (gsd-verifier)_
