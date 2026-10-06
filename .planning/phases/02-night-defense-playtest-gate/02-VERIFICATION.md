---
phase: 02-night-defense-playtest-gate
verified: 2026-10-06T05:54:21Z
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
  - data/enemies/ranged.tres
  - data/king/king.tres
  - data/maps/prototype_map.tres
  - data/tuning/loop_tuning.tres
  - presentation/king/king.gd
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - project.godot
  - simulation/buildings/building_system.gd
  - simulation/defs/loop_tuning.gd
  - simulation/defs/map_config.gd
  - simulation/king/king_state.gd
  - simulation/night/enemy_system.gd
  - simulation/night/night_sim.gd
  - simulation/night/wave_schedule.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - tests/e2e/test_results_screen.gd
  - tests/golden/smoke.json
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_map_validate_enemies.gd
  - tests/unit/test_wave_schedule.gd
  - ui/hud/dawn_no_income_marker.gd
  - ui/hud/hud.gd
  - ui/overlay/night_overlay_sections.gd
  - ui/results/results_screen.gd
  - ui/results/results_screen.tscn
  - ui/world/spawn_telegraph.gd
covered_digest: "v2:sha256:1748afe568d034501ab59404101ee701df8308464f69b96b3e9e1c617f4c6f4c"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 3/4 roadmap success criteria verified (SC4 pending); 11/11 requirement IDs
  previous_verified: 2026-10-05T16:53:35Z
  previous_commit: 4dfb729
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  note: "The previous report had no gaps (human_needed only), so this is a full re-check against changed source, not a gap-closure pass. Source changed in five files by three review-fix commits (21b8abb, 260ec31, 81c300e); no truth regressed. The previous report's human item 2 described a residual (a press begun inside the grace window and released after it still pressed Play again); that residual is closed in the code and item 2 is rewritten."
gaps: []
deferred: []
human_verification:
  - test: "Owner playtest gate (ROADMAP SC4, D-18): play one or two full 8-night runs on the exported build and either sign off or record the fixes that must land before Phase 3"
    expected: "A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change"
    why_human: "Fun, tension, fairness and readability are the owner's judgement. Bot results, CI, the 745 passing tests and Claude's screenshot review are explicitly not the sign-off. 02-UAT.md has all 11 tests pending."
  - test: "Results screen layout and the accidental-restart tap (WR-03, and the second review's WR-01, both now fixed in the code)"
    expected: "Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel. Tapping or mashing Space or gamepad A as Victory/Defeat appears does not restart the run or quit: for the first 0.6 s of the screen both buttons ignore every press, and Play again works after that. A press that BEGINS inside the 0.6 s window and is released after it also does nothing (the code stamps when a press began, on button_down, and counts it only if it began after the window), and so does a key that was already held when the screen appeared. A fresh press that begins after the window works. Judge the feel: that 0.6 s neither lets a mash through nor feels sluggish before Play again responds, and that a held or straddling press does nothing"
    why_human: "Layout is a visual judgement and the tap is a feel/timing test. The code and its tests now cover the straddling case (I read the gate in ui/results/results_screen.gd), but whether 0.6 s is the right length in a real run only a player can say."
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
    expected: "On defeat the castle collapses for about 1.2 s, then the Defeat screen; on victory the screen appears at once; Play again starts a fresh run from day 1 and Quit closes the game; the screen works with keyboard, gamepad and mouse (all three act only after the 0.6 s grace)"
    why_human: "Assumption 9 and the collapse look were untested by eye (02-07). The grace window means presses in the first 0.6 s do nothing, which only a real run shows to feel right or sluggish."
  - test: "Hand-steered king, ride cost and gamepad feel at night; night 3 fairness"
    expected: "The king handles well when steered by hand; riding between plots costs a meaningful amount of day; night 3 (king alone against two roads) feels fair to a first-time player; gamepad play at night works"
    why_human: "Packet 'What nobody has checked'. The bots build without riding and react perfectly."
  - test: "The 13 assumptions on the owner's behalf"
    expected: "Owner confirms or changes each; in particular full dawn repair (1), no last dawn payout after night 8 (2), 6/10/14/15 s respawn (10), the 4-gold opening (13). Also the Play again behaviour recorded in 02-07 (a new random seed, so a replayed run is not the same run) is flagged in the summary but is not one of the 13"
    why_human: "Product decisions made for the owner."
---

# Phase 2: Night Defense & Playtest Gate Verification Report

**Phase Goal:** The prototype map plays the full day -> night -> dawn loop. The player sees each night coming and starts it deliberately, defends with the king and basic towers, rebuilds and collects income at dawn, and wins or loses on a results screen. Seeded nights replay deterministically, and the owner confirms the loop is fun before anything is built on top of it.
**Verified:** 2026-10-06T05:54:21Z
**Status:** human_needed
**Re-verification:** Yes, after the second review-fix pass. The previous report (2026-10-05T16:53:35Z, commit 4dfb729) had no code gaps; this one re-checks the changed source at HEAD 00cf14b and replaces it.

## Verdict

The engineering part of the goal is achieved and was re-checked against the code at HEAD, not against the summaries. The last clause, "the owner confirms the loop is fun before anything is built on top of it", is not achieved and cannot be by an agent: ROADMAP success criterion 4 is a human gate, `02-UAT.md` holds 11 tests all `[pending]` (status testing), and no owner decision exists in any file. The phase must not be marked complete, and Phase 3 and any meta-progression work must not start, until the owner decides. There are no FAILED truths and no code blockers. One warning from the third review (WR-01, a test that cannot fail on a missing grace window) and one info item are open; neither is a must-have, and I do not describe either as fixed.

One process note. ROADMAP.md marks Phase 2 `Mode: mvp`, but its goal is not in the "As a ..., I want ..., so that ..." form (`user-story.validate` returns `false`). The earlier reports and this one therefore verified the goal with the standard goal-backward method, not the MVP user-flow table. If the orchestrator wants the MVP form, the goal needs rewording first (`/gsd mvp-phase 2`).

## What changed since the previous verification

`git diff 4dfb729..HEAD -- . ':!.planning/'` is exactly five files, from three fix commits. I read all five diffs and the full text of `ui/results/results_screen.gd`. Everything after 81c300e is `.planning/` only.

| Commit | Change | Effect on this verification |
|---|---|---|
| 21b8abb | `WaveSchedule._allowances(map, night)` lost its `needs_enemy` flag: a group with a null entry, an unknown spawn point or an unknown enemy gets 0 and spends no budget, for both the schedule and `preview_counts`. The dead `MAX_GROUP_COUNT` constant is gone. Two new tests (`test_the_preview_skips_an_unknown_enemy_group_like_the_schedule`, `test_the_night_budget_is_the_only_cap_constant`) | The telegraph and the night now agree on which groups are skipped, so the SC1 preview cannot promise enemies the night will not send. Replay digests unchanged. Closes the second review's IN-01 and IN-02. |
| 260ec31 | `test_shipped_results_input_grace_is_set_in_the_data_file_and_short` also reads the text of `loop_tuning.tres` and requires the line `results_input_grace_seconds = ` | The grace is pinned in the data file, not only in the script default (the file does contain it, at line 17). Closes IN-03. |
| 81c300e | `ResultsScreen`: both buttons stamp `_down_ms` on `button_down`; a `pressed` counts only if `accepts_input()` is true and `_down_ms >= _accept_from_ms`. The grace is `clampf(results_input_grace_seconds, 0, MAX_GRACE_S = 3.0)`. The grace tests use their own 3 s window and end `pending()` if the runner stalled past it. Seven new or rewritten tests | Closes the previous report's open residual (a press begun inside the window and released after it pressed Play again), the cap (IN-04) and the tests' timing flake (WR-02). Introduces the third review's open WR-01 (below). |

## What I ran and read

Ran in my own process, at HEAD 00cf14b with no source modified:

| Check | Command | Result |
|---|---|---|
| Full suite | `bash tools/test.sh` | 86 scripts, 745 tests, 745 passing, 8613 asserts, 247.5 s, exit 0; `gut-junit.xml` shows `skipped="0"` on all 86 suites and the run summary lists no pending or risky test (the grep hits for "pending" are test names such as "pending section") |
| Lint and format | `bash tools/lint.sh` | "156 files would be left unchanged", "Success: no problems found" |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (matches the golden, unchanged since the previous report) |
| Full-run replay | `bash tools/replay.sh --scenario=full_idle --twice` | `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6244 digest=a25aa7fd20e3cba842165f4c9579660b0ce3dd4b30628dd17facf812f97c5b07` (unchanged) |
| Roadmap and requirements | `user-story.validate` on the goal; reading ROADMAP Phase 2 and REQUIREMENTS.md | goal is not a user story (see the process note); 11 IDs found |
| Processes and tree | `tasklist`, `git status --short` | no Godot process left; the only modification is the pre-existing `.planning/config.json` |

I did not re-run the scratch probe from the previous report (a Button fires `pressed` on release); the code no longer depends on it, and the fix is judged from the source below. I started no command that hung and killed no process.

Read in full this time: the five diffs, `ui/results/results_screen.gd`, `ui/results/results_screen.tscn` (grep for action mode, toggle and shortcut: none set, so the buttons use the default release-fires action), `tests/e2e/test_results_screen.gd` lines 230-560, `02-REVIEW.md` (third review), `02-REVIEW-DISPOSITION.md`, `02-UAT.md`, `.planning/STATE.md` Blockers/Concerns, ROADMAP Phase 2, the requirement rows, and the `requirements:` frontmatter of all 11 plans. Re-read at HEAD for the symbols that carry the goal: `simulation/run/run_manager.gd` (`start_night`, `tick`, `_night_should_end`, `_end_night`, `_enter_dawn`, `end_run_in_defeat`), `simulation/run/run_context.gd` (`step`), `BuildingSystem.rebuild_destroyed` and `dawn_income_by_spot`, `KingState` knockout and respawn, and the `NightOverlaySections.register` wiring. Files not changed since the previous report were not re-read line by line; the earlier reading stands.

Taken from a report without re-checking: the balance table (`02-BALANCE-REPORT.md`; I did not run `tools/playtest.sh`); the Windows export launching (I did not run the exe, and it predates pass 2); CI run 37325147907 green on `dd5428c` and Linux/Windows digest equality (CI has not run on either fix pass; I did not push); the screenshots (not re-viewed); the orchestrator's mutation probes (six of seven caught, recorded in 02-VALIDATION.md; I did not repeat them); 02-VALIDATION.md's re-audit and 02-SECURITY.md's re-audit (26 of 26 threats closed). The third review's claim that the press-start gate cannot be bypassed I checked in the code myself (next section).

## Goal Achievement

### The press-start gate, read from the code

`ResultsScreen` (the only changed production file):

- `_ready` connects `pressed` and `button_down` on both buttons. `_on_button_down` stores `Time.get_ticks_msec()` in `_down_ms`, which starts at -1.
- `_show_results` sets `_showing`, then `_accept_from_ms = now + roundi(clampf(grace, 0, 3.0) * 1000)`, and shows the screen with focus on Play again.
- `_press_counts()` is `accepts_input() and _down_ms >= _accept_from_ms`; both `pressed` handlers emit only through it.

Consequences, each traced in the code: a press that begins inside the window and is released after it has `_down_ms < _accept_from_ms` and does nothing; a key already held when the screen appears sends no press to the button, so no `button_down` stamp exists and `-1 >= _accept_from_ms` is false; a bare `pressed` with no `button_down` is rejected for the same reason; a grace of 0 gives `_accept_from_ms == now`, so the first press counts; a typo such as 60 clamps to 3.0 s and a negative value clamps to 0, so the player can never be locked out for more than 3 s; nothing depends on focus. After the window, keyboard, gamepad and mouse all work as before.

One residual the reviewer saw and chose not to report, and I agree it is not worth a finding: `_down_ms` is shared by both buttons, so a key press on Play again begun inside the window and still held, followed by a mouse press on Quit after the window, followed by the key release, could press Play again. That needs two devices at once. A per-button stamp would close it if the owner wants zero residual.

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | No day timer; per-spawn-point counts shown; hold-to-confirm start; enemies damage and visibly destroy buildings; king auto-attacks; knocked-out king respawns at the castle after a visible countdown | VERIFIED in code and tests; visual quality for the owner | `RunManager.tick` has no DAY case: the day ends only through `start_night()`, which returns false unless the phase is DAY. Start input is wired through `StartNightHoldController` and `Hud`, with `test_no_day_timer.gd` and `test_start_night_hold.gd` in the passing 745. Preview counts and telegraph go through `WaveSchedule._allowances` (now the same rule as the schedule). `BuildingSystem.damage_building` and `KingState` knockout and respawn are present, with `test_king_knockout.gd`. |
| 2 | Night ends only when every enemy is dead; dawn rebuilds destroyed buildings free, surviving Houses pay tier income, rebuilt ones visibly marked; results screen on loss (the instant the castle falls) or win after the final night | VERIFIED in code and tests | `_night_should_end` is `NightSim.is_cleared()` on authored maps; `_enter_dawn` calls `rebuild_destroyed()`, repairs, then `_apply_dawn_payout()`, and `dawn_income_by_spot` skips destroyed and `rebuilt_this_dawn` buildings. `RunContext.step` calls `end_run_in_defeat()` the step the castle falls, before the loop clock ticks (loss beats win). `_end_night` wins on the last authored night. `ResultsScreen` shows Victory at once and Defeat after `loss_beat_seconds`, with five stats and the hardened buttons above. |
| 3 | Seeded scripted night replays identically from the command line and in CI; GUT covers waves, combat, loop transitions; overlay shows live enemy counts, wave state and paths | VERIFIED locally; CI re-run on the fixes still pending | Both replays printed `REPLAY_OK` twice with unchanged digests and smoke equals the golden. 745 tests pass. `DebugOverlay` registers the night sections via `NightOverlaySections.register`. CI evidence is for `dd5428c` only; no CI run has covered the six fix commits. |
| 4 | Human playtest gate: owner plays several full runs and signs off or records fixes; no meta-progression until then | NOT ACHIEVED, awaiting the owner | `02-UAT.md`: 11 tests, all `[pending]`, status testing. No owner decision exists. Plan 02-11's own truth for this is `verification: backstop`, so it cannot be satisfied by tests. Bot results, CI and screenshot review are not the sign-off. |

### Plan must_haves

The plan-level truths were spot-verified in the first report; the files they rest on are unchanged except as listed above. For the changed files:

| Plan | Truth | Status |
|---|---|---|
| 02-01 / 02-02 | Night data sane and bounded; nights end; schedule deterministic in (tick, group, index) order | VERIFIED. `_allowances` is pure and in group order; `wave_schedule.gd` uses no `Time`, `OS`, global random or scene tree (also enforced by `test_sim_rules_guard.gd`, passing); digests unchanged. |
| 02-07 | Results screen with Play again and Quit, focus on Play again, loss beat, mouse only on the screen's buttons | VERIFIED. Buttons are never disabled, focus unchanged, all three devices work once the press-start gate passes. |
| 02-06, 02-03, 02-04, 02-05, 02-08, 02-09, 02-10, 02-11 | as in the previous report | Files unchanged; suite and replays pass. 02-11's owner-decision truth stays open (SC4). |

Prohibitions: all judgment-tier, marked resolved by executors. Non-authoritative reading, unchanged: no day timer, no meta reward on the results screen (outcome plus five stats only), no gold for kills or knockouts, no charge for the dawn rebuild, mouse bound to no gameplay action. The grace and press-start gate add no gold or reward path. None is silently absorbed into a pass: they stay judgment-tier and are confirmed in play only by the owner's playtest.

### Requirements Coverage

All 11 IDs appear in at least one plan's `requirements:` frontmatter (02-01: DEV-05, LOOP-03, KING-03; 02-02: LOOP-03, LOOP-07; 02-03: KING-06; 02-04: BLDG-07; 02-05: KING-03, BLDG-07; 02-06: LOOP-04, LOOP-05; 02-07: LOOP-06, LOOP-07; 02-08: LOOP-01, LOOP-02, DEV-05; 02-09: DEV-05; 02-10: DEV-05, LOOP-07; 02-11: all 11). REQUIREMENTS.md maps exactly these 11 to Phase 2; none is orphaned and none is missing from a plan. REQUIREMENTS.md already ticks all 11 as Complete; that reflects implementation, not the playtest gate, and ROADMAP still shows Phase 2 unchecked.

| Requirement | Status | Evidence |
|---|---|---|
| LOOP-01 | SATISFIED | `RunManager.start_night` is the only exit from DAY; no timer case in `tick`; `test_no_day_timer.gd`, `test_start_night_hold.gd` |
| LOOP-02 | SATISFIED in code; look needs owner | `SpawnTelegraph`, `WaveSchedule.preview_counts` (same rule as the schedule), Hud preview line; `test_spawn_telegraph.gd` |
| LOOP-03 | SATISFIED | `NightSim.is_cleared`, `_night_should_end`; `validate()` rejects enemy data that could never end a night |
| LOOP-04 | SATISFIED | `rebuild_destroyed` in `_enter_dawn`; `test_dawn_rebuild.gd` |
| LOOP-05 | SATISFIED in code; marker size for owner | `dawn_income_by_spot` skips `rebuilt_this_dawn`; `DawnNoIncomeMarker` |
| LOOP-06 | SATISFIED | `RunContext.step` calls `end_run_in_defeat()` the same step; `test_run_outcomes.gd` |
| LOOP-07 | SATISFIED | `_end_night` goes to WON on the last night; `ResultsScreen` |
| KING-03 | SATISFIED | `KingState.step` nearest-enemy attack |
| KING-06 | SATISFIED in code; visuals for owner | `KingState` knockout counters and respawn ticks; `Hud._refresh_respawn`; ghost king |
| BLDG-07 | SATISFIED in code; rubble readability for owner | `BuildingSystem.damage_building`, `RubbleView` |
| DEV-05 | SATISFIED | Replays, golden, determinism and rules-guard tests pass at HEAD |

### Data-Flow Trace (Level 4)

Unchanged and FLOWING: Hud banner and preview from `NightSim`/`MapConfig.nights` (preview now through the shared `_allowances`); respawn label from `KingState`; `ResultsScreen` stats from `RunStats` fed by `SimEvents`; `SpawnTelegraph` from `preview_counts`; overlay from the live simulation. `results_input_grace_seconds` flows from `loop_tuning.tres` (0.6, line 17) through `_ctx.tuning` into `_accept_from_ms`; real data, and the contract test now reads the data file text.

### Anti-Patterns Found

None blocking. I did not grep the five changed files for debt markers this round beyond reading their diffs and the screen in full; the diffs contain no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK` or placeholder text, no stubs and no hardcoded empty data flowing to the UI.

## Open code-review findings (third review, 2026-10-06T05:39:42Z: 0 critical, 1 warning, 1 info; BOTH OPEN)

| ID | Verdict | Weighing |
|---|---|---|
| WR-01 | WARNING, test robustness, not a must-have | Confirmed by reading `tests/e2e/test_results_screen.gd`. The three grace tests and four straddle tests end with `pending()` when `results.accepts_input()` is already true after the taps. That is also the state when the grace is never applied (grace 0, clamp swapped, wrong field). Nothing else asserts that the window exists: the cap test only waits for `accepts_input()` to become true, and `accepts_input` and `_accept_from_ms` appear in no other test. `tools/test.sh` exits 0 on pending tests, and this run reported none. The orchestrator's mutation probe (grace forced to 0: seven tests pending, run passes) agrees. So the accidental-restart defect (the first review's WR-03) could return with CI green. The code today is correct, so SC2 is not affected; the press-start stamp itself is guarded (a regression that drops the `_down_ms` check fails the straddle tests while the window is applied). The reviewer's fix is an `assert_false(results.accepts_input())` right after `is_showing()` in the two scene helpers and the two tests that build their own scene. Escalated to the next review-fix pass. |
| IN-05 | INFO | Some e2e tests budget real seconds (`DEFEAT_TIMEOUT_S`, `VICTORY_TIMEOUT_S`) against a simulation clock clamped to 0.25 s per frame, so a loaded CI VM under 4 fps could miss them. No flake seen. |

Also open and recorded elsewhere: IN-06 (screenshot job worst case equals its timeout, in the disposition ledger) and three first-review info findings that lost their ledger rows (an arrow in flight when the last enemy dies is dropped though drawn landing; `BuildingViews.bind_run` and `DayNightLighting.bind_run` lack a repeat-bind guard; `replay.sh` and `playtest.sh` do not fail on `push_error` output), recorded in `.planning/STATE.md`. The second review's WR-01, WR-02 and IN-01 to IN-04 are recorded fixed in `02-REVIEW-FIX.md`, and I confirmed the code for each: the press-start gate, the stall-tolerant tests (with the WR-01 caveat above), the shared skip rule, the dead constant, the data-file text check and the 3 s cap. None of the open items is a FAILED must-have, so none produces `gaps_found`.

## Flagged assumptions and deviations

Unchanged from the previous report. The 13 assumptions in the playtest packet cover the items the summaries flagged, with one minor addition kept in human item 11 (Play again starts a new random seed, so a replayed run is not the same run). The 02-06 deviation (`was_rebuilt_this_dawn` not added; behaviour lives in `BuildingInstance.rebuilt_this_dawn`) is cosmetic. The optional per-night tick ceiling the first review suggested was not added; the hang is prevented at the data gate instead.

## Human Verification Required

The structured list is in the frontmatter and has the same 11 items, in the same order, as `02-UAT.md`. Items 1 and 3 to 11 are unchanged in wording. Item 2 is rewritten: the previous text asked the owner to judge a held press that "by the code still presses Play again"; the code now ignores a press begun inside the window and released after it, so the item states that and asks the owner to judge the feel (that 0.6 s neither lets a mash through nor feels sluggish, and that a held or straddling press does nothing). Item 9's clause "all three act only after the 0.6 s grace" still holds. No new item was needed. The owner must play one or two full runs on the rebuilt `build/windows/Duskhold.exe` (the local build predates pass 2; the orchestrator rebuilds it) or the editor binary, and record sign-off or fixes through `/gsd-verify-work`.

## Gaps Summary

No code gaps and no blockers. The phase is `human_needed` because success criterion 4 (the owner playtest gate) has not happened, by design: it blocks Phase 3 and any meta-progression work until the owner decides. Before or alongside the owner's play: fix or consciously accept the third review's WR-01 (a few assert lines in the e2e helpers), triage IN-05, IN-06 and the three dropped first-review infos as `fixed`, `skipped` or `deferred`, and push so CI runs on the six fix commits, because the only green CI run predates all of them. Do not treat the 745 green tests, the unchanged replay digests, the earlier CI run, the balance table or the screenshot review as the sign-off.

---

_Verified: 2026-10-06T05:54:21Z_
_Verifier: Claude (gsd-verifier)_
