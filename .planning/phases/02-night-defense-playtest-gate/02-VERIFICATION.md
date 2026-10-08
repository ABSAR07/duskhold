---
phase: 02-night-defense-playtest-gate
verified: 2026-10-07T11:44:47Z
status: passed
score: 3/4 roadmap success criteria verified (SC4, the owner playtest gate, awaits the owner's round-4 replay); 11/11 requirement IDs have implementation evidence; 2/2 round-4 gap-closure plans (02-21, 02-22) verified in code and documents
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
  - .planning/phases/02-night-defense-playtest-gate/02-12-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-12-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-13-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-13-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-14-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-14-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-15-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-15-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-16-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-16-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-17-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-17-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-18-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-18-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-19-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-19-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-20-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-20-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-21-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-21-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-22-PLAN.md
  - .planning/phases/02-night-defense-playtest-gate/02-22-SUMMARY.md
  - .planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md
  - .planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md
  - .planning/phases/02-night-defense-playtest-gate/02-REVIEW-DISPOSITION.md
  - .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
  - .planning/phases/02-night-defense-playtest-gate/02-SECURITY.md
  - .planning/phases/02-night-defense-playtest-gate/02-UAT.md
  - .planning/phases/02-night-defense-playtest-gate/02-VALIDATION.md
  - data/enemies/grunt.tres
  - data/enemies/ranged.tres
  - data/king/king.tres
  - data/maps/prototype_map.tres
  - data/tuning/loop_tuning.tres
  - input/fast_forward_controller.gd
  - presentation/king/king.gd
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/vfx/projectile_vfx.gd
  - project.godot
  - simulation/buildings/building_system.gd
  - simulation/clock/sim_clock.gd
  - simulation/defs/king_def.gd
  - simulation/defs/loop_tuning.gd
  - simulation/defs/map_config.gd
  - simulation/events/sim_events.gd
  - simulation/king/king_state.gd
  - simulation/night/castle_attack.gd
  - simulation/night/enemy_system.gd
  - simulation/night/night_sim.gd
  - simulation/night/wave_schedule.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - tests/e2e/test_fast_forward.gd
  - tests/e2e/test_king_ride.gd
  - tests/e2e/test_results_layout.gd
  - tests/golden/smoke.json
  - tests/integration/test_balance_acceptance.gd
  - tests/unit/test_castle_attack.gd
  - tests/unit/test_fast_forward_rules.gd
  - tests/unit/test_fast_forward_toggle.gd
  - tests/unit/test_input_map.gd
  - tests/unit/test_king_movement_config.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_map_validate_castle.gd
  - tests/unit/test_night_data_contract.gd
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_prototype_map_data.gd
  - tools/replay/balance_report.gd
  - tools/replay/playtest_bot.gd
  - tools/replay/replay_driver.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/results/results_screen.gd
  - ui/results/results_screen.tscn

covered_digest: "v2:sha256:a22e86cbf193a52a539fbe6bf79b658447e035028c00604fae9039a8f82a882d"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 3/4 roadmap success criteria verified (SC4, the owner playtest gate, awaits the owner's round-3 replay); 11/11 requirement IDs have implementation evidence; 4/4 round-3 gap-closure plans (02-17 to 02-20) verified in code
  previous_verified: 2026-10-07T00:53:09Z
  previous_commit: ec0d6ca
  gaps_closed:
    - "G-02-18, code and packet side: king walk 5.0 -> 7.5 m/s with the sprint kept at exactly 12.0 m/s (sprint_multiplier 2.4 -> 1.6), D-03 amended, KingDef defaults and docs aligned, pins in tests (plan 02-21); Round 4 balance note, STATE.md supersession marks, 15 screenshots, fresh export and Round 4 owner packet (plan 02-22). The owner's round-4 replay has NOT happened, so G-02-18 as a gate record stays open"
  gaps_remaining: []
  regressions: []
  note: "The previous report had no code gaps (human_needed only). Round 3 of the owner's UAT produced G-02-18 (test 18: walk 1.5x, sprint kept at the current magnitude, clarified once). Since ec0d6ca the non-planning diff is exactly four files (data/king/king.tres, simulation/defs/king_def.gd, tests/unit/test_king_movement_config.gd, tests/unit/test_prototype_map_data.gd; 59 insertions, 20 deletions), and git diff d6d39cf HEAD with .planning excluded is empty, so the 831/831 post-merge gate at d6d39cf covers the final source tree. I re-read the four files and every consumer of the two king fields, and ran six test files, both replays, lint, a map-distance probe and a launch check of the export myself."
gaps: []
deferred: []
warnings:
  - id: "WR-01 (fifth review, carried forward, still OPEN)"
    where: "simulation/clock/sim_clock.gd ticks(), simulation/defs/map_config.gd _validate_castle_attack, simulation/night/castle_attack.gd is_armed"
    issue: "A huge finite castle_attack_interval such as 1e30 overflows ceili in SimClock.ticks (the maxi floor returns 1), passes validate() and fires the castle every tick. I re-read ticks() (sim_clock.gd lines 20-23) and is_armed() (castle_attack.gd lines 38-45) at HEAD: both are unchanged since the previous report, which reproduced it in-process on 4.7.2; I did not re-run the reproduction. Plan 02-17's fourth truth (even a map that was never validated cannot make the castle fire every tick) is true for INF, NaN, zero, negative and sub-step values and false for an enormous finite one. The shipped data (22 m, 1.5 s, 27 m/s) validates clean and is correct."
    decision_requested: "Same as last round: fix in a review-fix pass (saturate SimClock.ticks, bound the interval in validate() and is_armed(), two tests) or accept and reword the comment and T-02-33. Not a gap: no shipped or owner-authored value triggers it and no roadmap criterion depends on it. It lost its ledger row to id reuse (STATE.md Blockers/Concerns) and is still open."
  - id: "WR-02 (fifth review, carried forward, still OPEN)"
    where: "tests/unit/test_fast_forward_rules.gd line 20 WRITE_PATTERN"
    issue: "Re-read at HEAD: the pattern is still Engine\\.time_scale\\s*=[^=], so a second writer written as '*=', '+=' or Engine.set(...) would pass the single-writer scan. Test robustness only; the controller is today the only writer."
    decision_requested: "Fix (widen the pattern, add three self-check samples) or accept."
behavior_unverified_items: []
human_verification:
  - test: "Owner round-4 playtest gate (ROADMAP SC4, D-18, G-02-12 and G-02-18): replay one or two full runs on the fresh build/windows/Duskhold.exe (exported 2026-10-07T11:10Z from the final source tree) or the editor binary, then either sign off or name the fixes that must land first"
    expected: "A recorded decision through /gsd-verify-work. Sign-off means the loop is fun: gold trade-offs by day feel meaningful and nights feel tense and readable, with the round-3 numbers (castle 22 m and 27 m/s, the fast-forward toggle, the full-wall nights) and the new 7.5 m/s walk all accepted. Otherwise a list of fixes and any of assumptions 12 to 15 to change"
    why_human: "Fun, tension and fairness are the owner's judgement and ROADMAP success criterion 4 is explicitly a human gate. Bot results, CI, the 831 passing tests and Claude's screenshot review are not the sign-off. No round-4 owner decision exists in any file"
  - test: "G-02-18 walk feel: ride the king at the new 7.5 m/s walk (WASD or left stick, no sprint) between the castle and the plots, and let go on a plot from a walk and from a full sprint"
    expected: "The walk reads as 1.5x faster than round 3 and as the owner meant it. The king stops where the owner means him to: 0.47 m after letting go at a walk (was 0.21 m) and 1.2 m after a full sprint (unchanged), both inside the 2.5 m build radius, so a hold starts without a nudge. The ride times (castle area to the inner Houses 1.2 s, to the towers 7.5 to 8.3 s, edge to edge about 15 s) feel right on a map that was not grown"
    why_human: "Movement feel and the stopping point under the owner's hands are not observable from code. The numbers are pinned by test_king_movement_config (9/9) and the ride-band test, but whether 7.5 m/s is the speed the owner pictured is a feel judgement"
  - test: "G-02-18 sprint versus walk: use Shift (or the right shoulder) on long rides and at night"
    expected: "The sprint is still the 12 m/s the owner asked to keep, and the owner accepts that it now adds only 4.5 m/s over the walk (it saves about 37.5% of a ride, was 58%). The owner confirms the reading of the round-3 note (adjust the speedup to stay at the current magnitude) as the sprint staying at 12 m/s, with the night fast-forward unchanged at 2x"
    why_human: "The owner's note was ambiguous and was clarified once; whether the smaller sprint step still feels like a speed-up, and whether the reading is the one they wanted, is the owner's call. The 12 m/s sprint target itself is the owner's from round 1 (UAT G-02-1)"
  - test: "Tension with a more mobile king: play full nights on the new walk, riding without sprint where natural"
    expected: "Nights stay tense and fair. The walking king is now 2.3x a grunt (3.2 m/s) and 2.7x a skirmisher (2.8 m/s), was 1.6x and 1.8x, so human play can only get slightly easier (the top speed is unchanged). The owner says whether the game is still 'a little harder' in the way accepted in round 3 (balanced bot 8 of 10, seeds 3 and 9 lost on night 3) or whether the walk made it too easy"
    why_human: "The bots never walk at night (they sprint at exactly 12.0 m/s on every tick or never move), so no measured number says what a walking human king does. 02-BALANCE-REPORT.md Round 4 states this blind spot. Difficulty feel is the owner's"
  - test: "Assumption 12 of the round-4 packet, on the owner's behalf (13 to 15 stand from round 3)"
    expected: "The owner confirms or changes assumption 12: the bots build without riding to plots, sprint at 12 m/s at night on every tick and never walk, and the castle shoots for them too, so the faster walk cannot move a bot number; the measurement rule and the 7-or-8-of-10 target are unchanged"
    why_human: "A product decision made on the owner's behalf; the packet restates it and the owner confirms it"
---

# Phase 2: Night Defense & Playtest Gate Verification Report

**Phase Goal:** The prototype map plays the full day -> night -> dawn loop. The player sees each night coming and starts it deliberately, defends with the king and basic towers, rebuilds and collects income at dawn, and wins or loses on a results screen. Seeded nights replay deterministically, and the owner confirms the loop is fun before anything is built on top of it.
**Verified:** 2026-10-07T11:44:47Z
**Status:** human_needed
**Re-verification:** Yes, after the round-4 gap-closure plans 02-21 and 02-22 (commits 912b253..6fbadc3). The previous report (2026-10-07T00:53:09Z, commit ec0d6ca) is replaced.

## Verdict

The engineering part of the goal is achieved and the two round-4 plans did what they claimed. I read each changed file at HEAD and ran the changed tests, both replays, lint and a launch check of the export in my own process. There are no FAILED roadmap truths and no code blockers. The last clause of the goal, "the owner confirms the loop is fun before anything is built on top of it", is still not achieved and an agent cannot achieve it. ROADMAP success criterion 4 is a human gate: the owner played rounds 1 to 3 (02-UAT.md: 22 tests, 15 passed, 7 issues, all diagnosed), every code gap the owner raised is closed, and the owner's round-4 replay has not happened. Nothing in this round is the owner's sign-off. The phase must not be marked complete, and Phase 3 and meta-progression must not start, until the owner replays and decides through /gsd-verify-work.

The round-4 change itself is small and exact. The owner's decision (G-02-18: walk 1.5x, sprint kept at its current magnitude, clarified once) is two data lines: walk_speed 7.5 and sprint_multiplier 1.6. I confirmed in my own process that 7.5 x 1.6 is exactly 12.0 in doubles, so the sprint did not move by even one bit, which is why the smoke golden, the full_idle digest and the balance acceptance test are unchanged. One precision note on the Round 4 documents' claim that bots "sprint or never move": that is exact for the five balance strategies (the four building strategies defend at the sprint pace, no_build idles at the king spawn and so never moves), but the bot's hold-point mode (used by the smoke scenario, some integration tests and three screenshot scenes) walks at walk_speed. The smoke scenario uses the frozen fixture king (walk 5.0, multiplier 1.6) and the integration tests passed in the 831/831 gate, so no number is affected; the claim is about the balance report, where it holds.

The fifth review's six findings and the sixth review's two info findings are all still open and none changes the verdict. The previous report weighed the fifth review's WR-01 as a warning (not a blocker); I kept that judgement because the code is unchanged (see the warnings in the frontmatter and the findings section below).

ROADMAP marks Phase 2 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form, so I verified with the standard goal-backward method and wrote no MVP user-flow table (unchanged from the previous report).

## What I ran and read

Run in my own process at HEAD 5fa444f (source tree identical to 6fbadc3; last source commit 87fbcb7, 2026-10-07T15:44+05:00). git status was clean before and after; no source modified, no process killed, nothing committed or pushed.

| Check | Command | Result |
|---|---|---|
| King movement pins | `bash tools/test.sh -gselect=test_king_movement_config.gd` | 9/9 passing |
| Ride-time band | `-gselect=test_prototype_map_data.gd` | 20/20 passing |
| Bot pacing | `-gselect=test_playtest_strategies.gd` | 14/14 passing |
| Balance acceptance | `-gselect=test_balance_acceptance.gd` | 8/8 passing (unchanged) |
| King ride (15% band, e2e) | `-gselect=test_king_ride.gd` | 10/10 passing (unchanged) |
| Night data contract | `-gselect=test_night_data_contract.gd` | 12/12 passing |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` |
| Full-run replay | `bash tools/replay.sh --scenario=full_idle --twice` | `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac` (identical to round 3) |
| Lint and format | `bash tools/lint.sh` | `167 files would be left unchanged`, `Success: no problems found` |
| Shipped data probe | scratch script in the session scratchpad, Godot 4.7.2 headless | farthest pair 110.0 m, ride 14.667 s at the walk, sprint 12.0 and `== 12.0` true, shipped map `validate()` is `[]`; spawn-to-spot distances 9.22, 26.17, 31.0, 56.52 and 62.0 m match the packet's ride table |
| Export launch | `build/windows/Duskhold.exe --headless --quit-after 120` | exit 0 in about 2.5 s |

I did not re-run the full 831-test suite (about 6 minutes). Its result rests on the orchestrator's wave-1 post-merge gate at d6d39cf (`build/test-results/postmerge_test_stdout.log`: Scripts 95, Tests 831, Passing 831, Asserts 8946, 348.7 s, lint clean). `git diff d6d39cf HEAD -- . ':!.planning/'` is empty, so that gate describes the final source tree. Note for the orchestrator: `build/test-results/gut-junit.xml` on disk now holds my last single-file run, not the full suite.

Taken from reports without re-checking: CI (121 commits are ahead of origin/gsd/phase-01-foundation-day-loop and nothing was pushed, so no CI run covers any fix commit since the last push), Linux and Windows digest equality, the 15 screenshot images and Claude's one-line reads of the three hold-point shots (I confirmed the 15 files exist, stamped 2026-10-07 16:07 to 16:09 +05, after the last source commit, and did not view them), the 02-VALIDATION.md and 02-SECURITY.md audits, the diagnosis's byte-identical 10-seed report (I did not re-run `bash tools/playtest.sh`, on purpose, because the bots cannot see the change and I confirmed the reason in the bot code), and the mutation probes recorded in the 02-21 SUMMARY (I repeated none).

## What the round-4 plans changed, read from the code

`git diff ec0d6ca HEAD -- . ':!.planning/'` covers four files. Plan by plan against the gap:

| Gap and plan | What the code does at HEAD | Status |
|---|---|---|
| G-02-18, 02-21: walk 7.5, sprint exactly 12 | `data/king/king.tres` lines 7 and 8: `walk_speed = 7.5`, `sprint_multiplier = 1.6`; line 9 `acceleration = 60.0` and every other king field (turn_speed 12, max_health 50, body_radius 0.6, attack range 3.0, damage 5, interval 0.7) unchanged in the diff. `King.move_speed` (presentation/king/king.gd lines 27-30) returns `walk_speed * sprint_multiplier` when sprinting, so the shipped sprint is `7.5 * 1.6 == 12.0` (true in my probe). Walk stop 7.5^2 / (2 x 60) = 0.47 m and full-sprint stop 1.2 m are both inside the 2.5 m build radius (the existing stopping-distance test passes unchanged) | VERIFIED |
| G-02-18, 02-21: KingDef defaults and docs | `simulation/defs/king_def.gd` defaults are now 7.5, 1.6 and 60.0 with doc comments that state the 7.5 m/s walk, the 1.6 multiplier and the exactly-12 m/s sprint; the combat defaults (max_health 30, attack 3 and 0.8) are untouched on purpose. `test_the_script_defaults_are_the_shipped_movement` ties walk, multiplier and acceleration to king.tres | VERIFIED |
| G-02-18, 02-21: pins | `tests/unit/test_king_movement_config.gd`: walk pin renamed and moved to 7.5, multiplier pin 1.6, new `test_the_sprint_stays_exactly_twelve_metres_per_second` (`assert_eq` on `King.move_speed(_def, true)` against 12.0), new defaults test; the 1.5 x 8 m/s floor and the stopping-distance test remain. 9/9 pass | VERIFIED |
| G-02-18, 02-21: ride band and D-03 | `tests/unit/test_prototype_map_data.gd`: MIN_RIDE_S 12.0, MAX_RIDE_S 18.0, test renamed (still 20 tests, 20/20 pass); the measured ride is 14.667 s, inside the band. `01-CONTEXT.md` D-03: the original "about 20-30 s" line is kept with an italic "Superseded by the 2026-10-07 amendment below" and a dated "Amended 2026-10-07 (owner decision, Phase 2 UAT round 3, G-02-18)" sub-bullet states 14.7 s walk, 9.2 s sprint, the map not grown, band 12 to 18 s. The diff of that file is one changed line and two added lines | VERIFIED |
| G-02-18, 02-21: no bot number moves | `tools/replay/playtest_bot.gd` `_move_king`: idle and hold-point modes pace at `walk_speed * STEP`; `KING_DEFEND_NEAREST_THREAT` paces at `walk_speed * sprint_multiplier * STEP` (lines 121 and 125). `tools/replay/playtest_strategies.gd` lines 96 and 98 set DEFEND for every strategy and IDLE_AT_CASTLE for no_build, whose king starts at `king_spawn` (the goal) and so never moves. With 7.5 x 1.6 == 5.0 x 2.4 == 12.0 the per-tick step is bit-identical, matching the unchanged full_idle digest, smoke golden (frozen fixture king at 5.0 and 1.6, `tests/fixtures/fixture_king_replay_smoke.tres` untouched), test_balance_acceptance 8/8 and test_playtest_strategies 14/14 | VERIFIED |
| G-02-18, 02-22: Round 4 note | `02-BALANCE-REPORT.md` opens with `## Round 4` above Round 3, 2 and 1 (45 insertions, 1 deletion: the intro line only): what changed, why no bot number moved, the evidence, the human blind spot, and that the Round 3 tables stand. The suite count (831 in 95 scripts) and the two replay lines it quotes match what I ran and the gate log | VERIFIED |
| G-02-18, 02-22: STATE.md | The two decision lines (01-05 ride time, 02-13 sprint) each gained a "superseded" or "(02-21, ...)" suffix naming the 7.5 / 1.6 change; the rest of the STATE.md diff is tracking fields, new 02-21 and 02-22 rows and a rewritten Blockers/Concerns history line | VERIFIED |
| G-02-18, 02-22: screenshots and export | 15 PNGs under screenshots/ (16:07 to 16:09 +05); `build/windows/Duskhold.exe` and `.pck` stamped 16:10 +05, after the last source commit at 15:44 +05, and the exe launches and exits 0 in my check. Whether the images read well was taken from the packet (the tool is real-window only, so I did not re-run it) | Evidence VERIFIED; image reads taken from the report |
| G-02-18, 02-22: owner packet | `02-PLAYTEST-GATE.md` opens with `## Round 4` above Round 3 (80 insertions, 0 deletions): the change and its numbers, the ride-time table (my probe reproduces 9.2, 26.2, 31.0, 56.5, 62.0 and 110 m, and 22.0 s to 14.67 s at the walk), the controls table with the walk and sprint rows, what Claude checked, assumption 12 restated, and "Your decision (round 4)". It says plainly that the bots' numbers and the screenshot review are not the sign-off, and its walk-versus-enemy ratios check out against the enemy data (7.5 / 3.2 = 2.3, 7.5 / 2.8 = 2.7) | VERIFIED |

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | No day timer; per-spawn-point counts; hold-to-confirm start; enemies destroy buildings; king auto-attacks; knocked-out king respawns after a visible countdown | VERIFIED in code and tests; the owner passed the visuals in round 1 | Round 4 changes two king movement numbers and nothing in the day, telegraph, combat, knockout or respawn code. The king's attack fields in king.tres are unchanged. |
| 2 | Night ends only when every enemy is dead; dawn rebuilds free, surviving Houses pay, rebuilt ones marked; loss when the castle falls; win after the final night on a results screen | VERIFIED in code and tests | No dawn, payout, loss or results code changed since the previous report. Both replays still end `outcome=won`. |
| 3 | Seeded night replays identically from the CLI and in CI; GUT covers waves, combat, loop transitions; overlay shows live counts, wave state, paths | VERIFIED locally; CI on the fix commits still pending | Both replays print `REPLAY_OK` twice with the expected digests and the smoke run equals the golden. The 831/831 gate covers the final source tree. Nothing was pushed, so no CI run covers the fix commits. |
| 4 | Human playtest gate: owner plays several full runs and signs off or records fixes; no meta-progression until then | NOT ACHIEVED, awaiting the owner's round-4 replay | Round 3 produced the one request G-02-18 and the owner passed everything else; plans 02-21 and 02-22 landed it and the Round 4 packet exists. No round-4 owner decision exists in any file. Plan 02-22's own truth for this is `verification: backstop`, which tests cannot satisfy. |

### Plan must_haves (02-21 and 02-22)

| Plan | Truth | Status |
|---|---|---|
| 02-21 | Shipped king walks 7.5, sprint multiplier 1.6, acceleration 60; `King.move_speed(def, true)` returns exactly 12.0 | VERIFIED (data read, probe prints true, pin test passes) |
| 02-21 | Sprint at least 1.5 x the original 8 m/s; full-sprint stop 1.2 m inside the 2.5 m build radius, walk stop 0.47 m | VERIFIED (floor test and stopping-distance test pass; arithmetic checked) |
| 02-21 | D-03 carries a dated 2026-10-07 amendment, original line kept and marked superseded, ride about 15 s (110 m in 14.67 s, 9 s at sprint), map not grown, ride test pins 12 to 18 s | VERIFIED (file diff read, test passes, probe 14.667 s) |
| 02-21 | KingDef defaults equal the shipped king (a test fails on drift) and the doc comments state the numbers | VERIFIED (defaults test, doc comments read). Sixth-review IN-02: the test omits turn_speed, which currently matches |
| 02-21 | Smoke matches golden; full_idle prints ticks=5140 digest bb9059c8... on both runs; balance acceptance, king ride and playtest strategies pass unchanged | VERIFIED (all run by me) |
| 02-22 | Round 4 section above Round 3 in the balance report, with the evidence and the blind spot, no re-measurement | VERIFIED (file read; I confirmed the reason in the bot code) |
| 02-22 | STATE.md's two old-walk lines say what superseded them and nothing else in STATE.md changes | VERIFIED for the two lines. The diff also holds the expected tracking updates and a Blockers/Concerns history rewrite (the ledger-id-reuse note), which is outside the plan's literal "nothing else" but is orchestrator bookkeeping and not a behaviour change |
| 02-22 | All 15 screenshots reach their states on the round-4 data in a real window; three hold-point shots read | Evidence VERIFIED (15 files, timestamps); the reads are Claude's own and taken from the report |
| 02-22 | Fresh export launches; packet has Round 4 above Round 3 with change, numbers, controls, checks, assumption 12 and the decision prompt | VERIFIED (export stamp and launch checked by me; packet read) |
| 02-22 | Owner replays and signs off or names fixes (backstop) | OPEN (SC4); routed to the owner in the frontmatter |

Prohibitions (all judgment-tier, marked resolved by the executors; my reading is non-authoritative and none is absorbed into a pass). 02-21: acceleration, turn_speed and every other king number, and every map, night, building, enemy and tuning file, are untouched (the non-planning diff since ec0d6ca is the four files above, king.tres changing two lines only); the map was not grown; `tests/golden/smoke.json` and `tests/fixtures` are untouched (the diff lists none); `test_king_ride.gd`'s 15% band, the stopping-distance test and the 1.5 x 8 floor are untouched or still present; the original D-03 line is kept; nothing is pushed (121 local commits ahead of origin). 02-22: no data, simulation, input, presentation or UI code changed (the plan's files_modified listed `tools/screenshot/shot_scenarios.gd`, but the diff shows it unchanged, consistent with the packet's "no scenario had to change"); Round 3, 2 and 1 sections kept (numstat 0 deletions in the packet, 1 intro-line deletion in the report); the packet does not present bot numbers or the screenshot review as the sign-off. They stay judgment-tier and are confirmed only by the owner's play.

### Requirements Coverage

All 11 phase IDs appear in at least one plan's `requirements:` frontmatter: 02-11 carries all 11 (as in the previous report), and the round-4 plans declare 02-21 KING-01 and DEV-05, 02-22 LOOP-07 and DEV-05. REQUIREMENTS.md maps exactly the 11 to Phase 2 (traceability rows at lines 176 to 182, 186, 189, 196, 260) and ticks all as Complete; none is orphaned and none is missing from a plan. KING-01 appears in plan 02-21 but is a Phase 1 requirement (traceability line 184, Complete); the plan touches its movement numbers, so it is a legitimate extra tag and not an orphan. The tick reflects implementation, not the playtest gate (ROADMAP still shows Phase 2 unchecked).

| Requirement | Status | Evidence |
|---|---|---|
| LOOP-01 | SATISFIED | Start is the only exit from DAY; no day timer; unchanged this round |
| LOOP-02 | SATISFIED in code; passed by the owner in round 1 | Telegraph reads the night data (contract test 12/12) |
| LOOP-03 | SATISFIED | A night ends only on a cleared field; unchanged |
| LOOP-04 | SATISFIED | Free rebuild unchanged |
| LOOP-05 | SATISFIED | Dawn payout unchanged |
| LOOP-06 | SATISFIED | Castle-falls-loses unchanged |
| LOOP-07 | SATISFIED | Win on the last night; both replays `outcome=won`; the shipped map still validates (probe `[]`) |
| KING-03 | SATISFIED | King auto-attack fields unchanged in king.tres |
| KING-06 | SATISFIED | Knockout and respawn unchanged |
| BLDG-07 | SATISFIED | Unchanged |
| DEV-05 | SATISFIED | Smoke golden and full_idle pass at HEAD; the movement change is presentation and bot pacing only |

### Data-Flow Trace (Level 4)

FLOWING: `walk_speed` and `sprint_multiplier` (data/king/king.tres) -> `King.move_speed` (presentation/king/king.gd), read live from the KingDef each physics frame -> the king's velocity; the same two fields -> `PlaytestBot._move_king` -> `ctx.king.report_position` (bot pacing) and `test_prototype_map_data` (ride-time band). Nothing under simulation/ reads either field, and no literal 5.0, 2.4 or 12 stands in for them in code (a grep of .gd, .tscn and .tres found only the king.tres lines, the script defaults, `King.move_speed`, the bot, tests, and the frozen smoke fixture on purpose). Earlier-round paths (castle numbers, toggle, night groups) were not touched this round and still flow as the previous report described.

### Anti-Patterns Found

None blocking. The four changed source and test files hold no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK` or `PLACEHOLDER` marker (a data file, a Resource script and two test files). No stubs or hardcoded empty data flow to the UI. Pre-existing hits for "2.4" and "22 s" elsewhere are unrelated constants (a castle model scale, particle speeds, an enemy march comment).

## Open code-review findings (all OPEN, none fixed, none a roadmap criterion)

Sixth review (02-REVIEW.md, 2026-10-07T11:26:46Z, scoped to 02-21's four files: 0 critical, 0 warnings, 2 info). 02-REVIEW-FIX.md belongs to the earlier second-review fix pass and is not evidence for any current finding.

| ID | Verdict | Weighing |
|---|---|---|
| IN-01 (sixth) | INFO | `test_sprint_is_at_least_one_and_a_half_times_the_original_sprint` still opens with a multiplier `assert_eq` that duplicates the exact-12 test; one retune would fail two tests. Confirmed by reading the diff. Test hygiene only. |
| IN-02 (sixth) | INFO | The defaults test covers walk, multiplier and acceleration but not `turn_speed` (currently equal at 12.0), and the "walking stop 0.47 m" doc claim has no test of its own (implied by the sprint-stop test). Confirmed by reading. Cosmetic. |

Fifth review (2026-10-07T00:45:45Z, scoped to the round-3 plans; all six STILL OPEN, no ledger rows after the id reuse). Code unchanged by round 4, so each is unchanged since the previous report: WR-01 and WR-02 are the frontmatter warnings (huge finite castle interval; single-writer scan blind to compound assignments); IN-01 `BALANCED_MIN_WINS = 7` unreachable next to the exact-seed pin; IN-02 `is_armed()` does not check the projectile speed is finite; IN-03 `validate()` accepts a NaN `castle_radius`; IN-04 an orphaned "## Read through" doc line in loop_tuning.gd. Older items still open as before: the first review's three info findings and the third and fourth reviews' IN-05 and IN-02 (see STATE.md Blockers/Concerns). The decision on WR-01 stands as in the previous report: a warning, not a gap, because the shipped map is valid and no owner-authored value or roadmap criterion depends on the extreme edge. A review-fix pass is still the natural next step for the code-side items and is independent of the owner's replay.

## Flagged assumptions and deviations

The Round 4 packet restates assumption 12 (the bots never walk at night, so the faster walk cannot move a bot number) and keeps 13 to 15 from round 3. The one product judgement behind round 4 is the owner's own clarified reading of "adjust the speedup to stay at the current magnitude" as the sprint staying at exactly 12 m/s with the night fast-forward unchanged at 2x. The consequence the owner should weigh is that the sprint now adds only 4.5 m/s over the walk (was 7) and that human play gets slightly easier, because the walking king is 2.3x a grunt instead of 1.6x. The balanced bot's 8 of 10 (36 of 50 on seeds 1 to 50) is unchanged by construction and says nothing about a human who walks.

## Human Verification Required

The structured list is in the frontmatter (5 items, one per thing the owner judges); the orchestrator extends 02-UAT.md from it as new tests 23 to 27. Rounds 1 to 3 (tests 1 to 22) are complete and are not repeated. The owner replays one or two full runs on the fresh `build/windows/Duskhold.exe` (or the editor binary) and records sign-off or fixes through `/gsd-verify-work`. The UAT gap row for G-02-18 still reads `failed`; verify-work reconciles it once the owner replays.

## Gaps Summary

No code gaps and no blockers. The phase is `human_needed` because success criterion 4 has not happened: the owner has not yet replayed the round-4 build and decided. In parallel, and independent of the owner: run the review-fix pass (the fifth review's WR-01 and WR-02 first, then its info items and the sixth review's IN-01 and IN-02), and push so CI runs on the 121 commits it has not seen. Do not treat the 831 green tests, the replay digests, the balance table, the screenshot review or this report as the sign-off.

---

_Verified: 2026-10-07T11:44:47Z
_Verifier: Claude (gsd-verifier)_
