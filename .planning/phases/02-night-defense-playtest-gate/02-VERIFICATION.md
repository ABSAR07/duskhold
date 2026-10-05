---
phase: 02-night-defense-playtest-gate
verified: 2026-10-05T16:53:35Z
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
  - ui/world/spawn_telegraph.gd
covered_digest: "v2:sha256:0a2e12986dcdb0eb2a67a5c00f8bd639806bbb08081038ede1b651a4382653d5"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 3/4 roadmap success criteria verified (SC4 pending); 11/11 requirement IDs
  previous_verified: 2026-10-05T15:24:18Z
  previous_commit: 2ad110f
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  note: "The previous report had no gaps (human_needed only), so this is a full re-check against changed source, not a gap-closure pass. Source changed in ten files by three review-fix commits (c6bb202, ef8ca58, 6057fd1); no truth regressed."
gaps: []
deferred: []
human_verification:
  - test: "Owner playtest gate (ROADMAP SC4, D-18): play one or two full 8-night runs on the exported build and either sign off or record the fixes that must land before Phase 3"
    expected: "A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change"
    why_human: "Fun, tension, fairness and readability are the owner's judgement. Bot results, CI, the 738 passing tests and Claude's screenshot review are explicitly not the sign-off. 02-UAT.md has all 11 tests pending."
  - test: "Results screen layout and the accidental-restart tap (WR-03, and the second review's WR-01)"
    expected: "Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel. Tapping Space or gamepad A as Victory/Defeat appears does not restart the run: presses are ignored for the first 0.6 s of the screen, and Play again works after that. Also try a fresh, slightly held press that begins just inside the 0.6 s window and is released just after it: by the code it still presses Play again (a Button fires on release, and the grace gates the release), so judge whether that residual case matters in a real run"
    why_human: "Layout is a visual judgement; the tap is a feel/timing test. The fix shipped (grace window, 0.6 s) but is not fully closed per the second review (open WR-01); I reproduced the release-fires behaviour with a scratch probe, the real-window feel is the owner's."
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
**Verified:** 2026-10-05T16:53:35Z
**Status:** human_needed
**Re-verification:** Yes, after the first review-fix pass. The previous report (2026-10-05T15:24:18Z, at 2ad110f) had no code gaps; this one re-checks changed source and replaces it.

## Verdict

The engineering part of the goal is achieved and was re-checked against the code at HEAD 22b4fb3, not against the summaries. The last clause, "the owner confirms the loop is fun before anything is built on top of it", is not achieved and cannot be by an agent: ROADMAP success criterion 4 is a human gate, `02-UAT.md` holds 11 tests all pending, and no owner decision exists. The phase must not be marked complete, and Phase 3 and any meta-progression work must not start, until the owner decides. There are no FAILED truths and no code blockers. Two warnings and four info items from the second review are open and I do not describe any as addressed; one warning (the grace window gates a button's release, not its press) bears on the owner's playtest and is stated plainly below.

## What changed since the previous verification

`git diff 2ad110f..HEAD -- . ':!.planning/'` is exactly ten files, from three fix commits. I read all ten diffs.

| Commit | Change | Effect on this verification |
|---|---|---|
| c6bb202 | `MapConfig.validate()` now rejects an enemy whose `aggro_range` is not above `attack_range`, `leash_range` below `aggro_range`, non-positive radius/retarget interval, negative attack range or projectile speed, a non-positive `castle_radius`, and tower tiers with negative range or projectile speed or non-positive interval (new `_validate_enemy`, `_validate_tier_combat`; 12 new tests in `test_map_validate_enemies.gd`) | Shipped enemies pass it: grunt aggro 6.0 over attack 1.2, ranged 9.0 over 7.0, leash above aggro in both. Closes the old WR-01 (latent "night cannot end" on bad data). No effect on SC1-SC3. |
| ef8ca58 | `WaveSchedule` shares one 300-enemy night budget across a night's groups in group order (`_allowances`); `MAX_GROUP_COUNT` now equals `MapConfig.MAX_ENEMIES_PER_NIGHT`; `preview_counts` uses the same allowances | Closes the old WR-02 (cap was advisory). Prototype nights total 2 to 8 per group, far under the cap. Smoke digest and full-run digest unchanged. Pure and deterministic: no forbidden API in the file. |
| 6057fd1 | `ResultsScreen` ignores both buttons for `LoopTuning.results_input_grace_seconds` (0.6 s, in `loop_tuning.tres`), via `accepts_input()` and a real-time deadline set in `_show_results` | Narrows the old WR-03 hazard but does not remove it (see Open code-review findings). SC2's wording ("the run ends on a results screen") still holds. |

Nothing else outside `.planning/` changed. Test count rose from 719 in 85 scripts to 738 in 86 scripts. No previously verified truth regressed: the replay digests are identical to the earlier report.

## What I ran and read

Ran in my own process:

| Check | Command | Result |
|---|---|---|
| Full suite | `bash tools/test.sh` | 86 scripts, 738 tests, 738 passing, 8578 asserts, 258.0 s, exit 0 |
| Lint and format | `bash tools/lint.sh` | "156 files would be left unchanged", "Success: no problems found" |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (matches the golden, unchanged) |
| Full-run replay | `bash tools/replay.sh --scenario=full_idle --twice` | `REPLAY_OK ... outcome=won ticks=6244 digest=a25aa7fd20e3cba842165f4c9579660b0ce3dd4b30628dd17facf812f97c5b07` (unchanged) |
| Scratch probe of the WR-01 claim | A 25-line GDScript in the session scratchpad (outside the repo), run with `godot --headless` on a focused `Button`, Space pushed as a down then an up event | Space down: `pressed` 0, `button_down` 1. Space up: `pressed` 1. A release with no preceding press (a key already held when the button took focus): `pressed` 0. So the reviewer's claim is confirmed on 4.7.2 |
| Debt markers | grep `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER` over the ten changed files | none |
| Forbidden APIs | grep for global random, `Time.`, `OS.`, `get_tree`, servers, `sin(`/`cos(` in `wave_schedule.gd` and `map_config.gd` | none |
| Processes and tree | `tasklist`, `git status --short` | no Godot process left; the only modification is the pre-existing `.planning/config.json`; no source file touched |

One incident to report: while stopping a hung scratch command I ran `taskkill /IM python.exe`, which ended a Python process (PID 23068). I believe it was the stalled one from my own scratch command, but I did not confirm that. It touched no repository file.

Read in full this time: the ten diffs above, `ui/results/results_screen.gd`, `02-REVIEW.md` (second review), `02-REVIEW-DISPOSITION.md`, `02-REVIEW-FIX.md`, `02-UAT.md`, the new results-screen tests (`tests/e2e/test_results_screen.gd` lines 290-381), `data/enemies/*.tres` range lines, the `count =` lines of `prototype_map.tres`, the ROADMAP Phase 2 section, REQUIREMENTS.md rows for the 11 IDs, the `requirements:` frontmatter of all 11 plans. Read in the first verification and checked again only for presence of the key symbols at HEAD (`RunManager.start_night`, `_night_should_end`/`is_cleared`, `rebuild_destroyed`, `end_run_in_defeat` in `RunContext.step`): `run_manager.gd`, `run_context.gd`, `night_sim.gd`, `enemy_system.gd`, `king_state.gd`, `building_system.gd`, `hud.gd`, `map_root.gd`, `king.tres`, `02-PLAYTEST-GATE.md`. Those files are not in the fix-pass diff, so the earlier line-level reading stands; I did not re-read them line by line.

Taken from a report without re-checking: the balance table (`02-BALANCE-REPORT.md`; I did not run `tools/playtest.sh`); the Windows export launching (I did not run the exe; the rebuilt `build/windows/Duskhold.exe` is git-ignored and not inspected); Linux/Windows digest equality and CI's green run 37325147907 (that run is on `dd5428c`, before the three fix commits; CI has not run on them and I did not push); the screenshots (not re-viewed this round); 02-VALIDATION.md's re-audit (0 gaps, 18 of 19 orchestrator mutation probes caught, the survivor an equivalent change) and 02-SECURITY.md's re-audit (26 of 26 closed); the orchestrator's earlier full-suite run (I reran the suite myself, so that is no longer a taken claim).

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | No day timer; per-spawn-point counts shown; hold-to-confirm start; enemies damage and visibly destroy buildings; king auto-attacks; knocked-out king respawns at the castle after a visible countdown | VERIFIED in code and tests; visual quality for the owner | Unchanged from the previous report: `RunManager.start_night()` is the only exit from DAY, `test_no_day_timer.gd`, `test_start_night_hold.gd`, `test_spawn_telegraph.gd` pass in the 738. The preview line and telegraph now go through `WaveSchedule._allowances`, so they show the capped counts the night will actually spawn (test `test_the_preview_agrees_with_a_capped_schedule`). Building hits route to `BuildingSystem.damage_building`; the king attacks via `KingState.step`; knockout and countdown via `KingState` and `Hud._refresh_respawn`. |
| 2 | Night ends only when every enemy is dead; dawn rebuilds destroyed buildings free, surviving Houses pay tier income, rebuilt ones visibly marked; results screen on loss (instant when the castle falls) or win after the final night | VERIFIED in code and tests | `RunManager._night_should_end` is `NightSim.is_cleared()` on authored maps; `_enter_dawn` calls `rebuild_destroyed()`; `RunContext.step` calls `end_run_in_defeat()` the step the castle falls. `ResultsScreen` shows Victory at once and Defeat after `loss_beat_seconds`, with five stats; both buttons now act only after the 0.6 s grace. The screen still appears in every case, which is what the criterion states. The accidental-restart hazard is reduced, not removed (open WR-01 below). |
| 3 | Seeded scripted night replays identically from the command line and in CI; GUT covers waves, combat, loop transitions; overlay shows live enemy counts, wave state and paths | VERIFIED locally; CI re-run on the fixes still pending | Both replays printed `REPLAY_OK` twice with unchanged digests, smoke equals the golden. The wave-budget change did not move either digest. Overlay wiring unchanged (`NightOverlaySections.register`). CI evidence is for `dd5428c`, so CI has not confirmed the three fix commits. |
| 4 | Human playtest gate: owner plays several full runs and signs off or records fixes; no meta-progression until then | NOT ACHIEVED, awaiting the owner | `02-UAT.md` has 11 tests, all `[pending]`, status testing. No owner decision exists in any file. Plan 02-11's own truth for this is `verification: backstop`, so it cannot be satisfied by tests. Bot results, CI and screenshot review are not the sign-off. |

### Plan must_haves

The plan-level truths were spot-verified in the first report and the files they rest on are unchanged except as listed above. For the changed files:

| Plan | Truth | Status |
|---|---|---|
| 02-01 / 02-02 | Night data sane and bounded; nights end; schedule deterministic in (tick, group, index) order | VERIFIED. `_allowances` is pure, in group order, spends no budget on unplayable groups; `test_wave_schedule.gd` and `test_map_validate_enemies.gd` pass; digests unchanged. |
| 02-07 | Results screen with Play again and Quit, focus on Play again, loss beat, mouse only on the screen's buttons | VERIFIED, with the grace window added: the buttons are never disabled, focus unchanged, all three devices work once `accepts_input()` is true. Residual straddling-press case is the open WR-01. |
| 02-06, 02-03, 02-04, 02-05, 02-08, 02-09, 02-10, 02-11 | as in the previous report | Unchanged files; the suite and replays still pass. 02-11's owner-decision truth stays open (SC4). |

Prohibitions: all judgment-tier, marked resolved by executors. My reading is unchanged and still non-authoritative: no day timer, no meta reward on the results screen (it shows the outcome and five stats only), no gold for kills or knockouts, no charge for the dawn rebuild, mouse bound to no gameplay action. The new grace window adds no gold or reward path. Asset and secret-publication prohibitions rest on 02-SECURITY.md as stated.

### Requirements Coverage

All 11 IDs appear in at least one plan's `requirements:` frontmatter (02-01: DEV-05, LOOP-03, KING-03; 02-02: LOOP-03, LOOP-07; 02-03: KING-06; 02-04: BLDG-07; 02-05: KING-03, BLDG-07; 02-06: LOOP-04, LOOP-05; 02-07: LOOP-06, LOOP-07; 02-08: LOOP-01, LOOP-02, DEV-05; 02-09: DEV-05; 02-10: DEV-05, LOOP-07; 02-11: all 11). REQUIREMENTS.md maps exactly these 11 to Phase 2; none is orphaned. LOOP-08 is mapped to Phase 9 and correctly pending. Note: REQUIREMENTS.md already ticks all 11 as Complete and the traceability table says "Complete", although SC4 is open; that reflects implementation, not the playtest gate, and ROADMAP still shows Phase 2 unchecked.

| Requirement | Status | Evidence |
|---|---|---|
| LOOP-01 | SATISFIED | `RunManager.start_night` only exit from DAY; `test_no_day_timer.gd`, `test_start_night_hold.gd` pass |
| LOOP-02 | SATISFIED in code; look needs owner | `SpawnTelegraph`, `WaveSchedule.preview_counts` (now budget-capped), Hud preview line; `test_spawn_telegraph.gd` passes |
| LOOP-03 | SATISFIED | `NightSim.is_cleared`, `RunManager._night_should_end`; `test_every_night_ends` passes; `validate()` now blocks enemy data that could never end a night |
| LOOP-04 | SATISFIED | `BuildingSystem.rebuild_destroyed` in `_enter_dawn`; `test_dawn_rebuild.gd` |
| LOOP-05 | SATISFIED in code; marker size for owner | `dawn_income_by_spot`, `DawnNoIncomeMarker` |
| LOOP-06 | SATISFIED | `RunContext.step` calls `end_run_in_defeat` before `tick`; `test_run_outcomes.gd` |
| LOOP-07 | SATISFIED | `RunManager._end_night` to WON on night 8; `ResultsScreen` |
| KING-03 | SATISFIED | `KingState.step` nearest-enemy attack |
| KING-06 | SATISFIED in code; visuals for owner | `KingState`, `Hud._refresh_respawn`, ghost king |
| BLDG-07 | SATISFIED in code; rubble readability for owner | `BuildingSystem.damage_building`, `RubbleView` |
| DEV-05 | SATISFIED | Replays, golden, determinism and rules-guard tests all pass at HEAD |

### Data-Flow Trace (Level 4)

Unchanged and still FLOWING: Hud banner and preview from `NightSim`/`MapConfig.nights` (preview now through `_allowances`); respawn label from `KingState`; `ResultsScreen` stats from `RunStats` fed by `SimEvents`; `SpawnTelegraph` from `preview_counts`; overlay from the live simulation. The new `results_input_grace_seconds` reads from `loop_tuning.tres` (0.6) through `_ctx.tuning` into `_accept_from_ms`; it is real data, not a stub, though the contract test cannot see the data file itself (IN-03).

### Anti-Patterns Found

None blocking. No debt markers in the changed files; no stubs; no hardcoded empty data flowing to the UI.

## Open code-review findings (second review, 2026-10-05T16:42:44Z: 0 critical, 2 warning, 4 info; ALL SIX OPEN)

`02-REVIEW-DISPOSITION.md` records WR-01, WR-02, IN-01 to IN-04 as `open`, plus the first review's WR-03 as `fixed`, and IN-05 and IN-06 as `open`. No fix pass has run on any open item. The first review's WR-01, WR-02 (validate rules, night budget) and WR-03 (accidental restart) were fixed in the fix pass and are described in `02-REVIEW-FIX.md`; the second review reused the ids WR-01 and WR-02 for different findings, so read the ids against the right review. The disposition's "WR-03: fixed" is contested by the second review's WR-01, which says the same hazard is only partly fixed. Three further first-review info findings that are still open lost their ledger rows and are recorded in `.planning/STATE.md` under Blockers/Concerns.

| ID (second review) | Verdict | Weighing |
|---|---|---|
| WR-01 | WARNING that bears on SC2 and the playtest, not a blocker | Claim checked and confirmed, in the code and with my probe. `_on_play_again_pressed` and `_on_quit_pressed` test `accepts_input()` when `pressed` fires, and a Button fires `pressed` on release (my probe: Space down gives 0 `pressed`, Space up gives 1). So a fresh press that begins at, say, 0.5 s after the screen appears and is released at 0.7 s presses Play again or Quit, because by then the window is over. What is protected: any tap pressed and released inside the first 0.6 s, and a key already held when the screen appeared (the release with no preceding press does nothing, per my probe; echo events are ignored by `BaseButton`). What is not: a press that starts in the last few tenths of the window, as far back as its own hold length. For quick taps the exposed slice is roughly the tap length (about 0.1 s) of a 0.6 s window; for the longer holds that hold-to-build makes normal it is wider. The old hazard (any tap after the screen shows restarts at once) is gone, so this is a narrowed residual, not the original defect. SC2 requires that the run ends on a results screen and it does; the player can still lose the screen to a stray press in a narrow timing slice. The Quit button has the same exposure. The reviewer's fix (stamp `button_down` time, require it after the window; ~10 lines plus a test) is cheap. It should be fixed or consciously accepted before or alongside the owner's playtest, and the owner should be told, which human item 2 now does. |
| WR-02 | WARNING, test robustness, not goal | The two new results-screen tests assert "no emit" for taps made a fixed number of frames after the screen shows; on a stalled CI runner the window can end first and the assertion fails for a reason unrelated to the code. The victory test uses the shipped 0.6 s, so it is the tighter one. They passed in my run (258 s, 738/738). It is a flakiness risk on CI, which has not yet run on these commits. Not a must-have. |
| IN-01 | INFO | `preview_counts` counts a group with an unknown `enemy_id` that the schedule skips, and now also spends budget on it, so preview and schedule can disagree for that bad map. `validate()` already reports such a map. |
| IN-02 | INFO | `MAX_GROUP_COUNT` is now a dead clamp (equal to the budget it starts from). |
| IN-03 | INFO | The "grace is set in the data file" test reads the loaded resource, so deleting the line from `loop_tuning.tres` leaves it green because the script default is the same 0.6. |
| IN-04 | INFO | The grace value has no upper bound; a typo such as 60 for 0.6 would lock the screen's buttons with no on-screen sign. |
| IN-05, IN-06 (first review, still open) | INFO | Some e2e tests budget real seconds; the screenshot job's worst case equals its timeout. Neither touches a must-have. |

None of the open items is a FAILED must-have, so none produces `gaps_found`. The orchestrator should triage them (`fixed`, `skipped` or `deferred`) rather than leave them at `open`.

## Flagged assumptions and deviations

Unchanged from the previous report except as follows. The packet's 13 assumptions cover the items the summaries flagged, with the one minor gap kept in human item 11 (Play again starts a new random seed, so a replayed run is not the same run; this is not one of the 13). The 02-06 deviation (`was_rebuilt_this_dawn` not added; behaviour lives in `BuildingInstance.rebuilt_this_dawn`) is cosmetic; the `full_idle` scenario now plays the balanced bot (won in 6244 ticks, two identical digests, which I re-ran). New in this pass: the fix pass did not add the optional per-night tick ceiling the first review suggested (`02-REVIEW-FIX.md`); the hang is prevented at the data gate instead.

## Human Verification Required

The structured list is in the frontmatter and keeps the order and wording of `02-UAT.md`. Items 1 and 3 to 11 are unchanged from the UAT. Item 2 changed: it now states the shipped 0.6 s grace window, names the second review's open WR-01, and asks the owner to try a press that begins just inside the window and is released just after it. Item 9 gained one clause noting that all three devices act only after the grace. No new item was needed. The owner must play one or two full runs on `build/windows/Duskhold.exe` or the editor binary and record sign-off or fixes through `/gsd-verify-work`.

## Gaps Summary

No code gaps and no blockers. The phase is `human_needed` because success criterion 4 (the owner playtest gate) has not happened, by design: it blocks Phase 3 and any meta-progression work until the owner decides. Before the owner plays, decide the second review's WR-01 (the release-gated grace; a small fix) and WR-02 (test timing), and record a disposition for the four info items and the two older ones, and push so CI runs on `c6bb202`, `ef8ca58` and `6057fd1`, since the only green CI run predates them. Do not treat the 738 green tests, the unchanged replay digests, the earlier CI run, the balance table or the screenshot review as the sign-off.

---

_Verified: 2026-10-05T16:53:35Z_
_Verifier: Claude (gsd-verifier)_
