---
phase: 02-night-defense-playtest-gate
verified: 2026-10-07T00:53:09Z
status: human_needed
score: 3/4 roadmap success criteria verified (SC4, the owner playtest gate, awaits the owner's round-3 replay); 11/11 requirement IDs have implementation evidence; 4/4 round-3 gap-closure plans (02-17 to 02-20) verified in code, with one plan-truth edge overclaim (fifth review WR-01) recorded as a warning
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
  - .planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md
  - .planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md
  - .planning/phases/02-night-defense-playtest-gate/02-REVIEW.md
  - data/enemies/grunt.tres
  - data/enemies/ranged.tres
  - data/king/king.tres
  - data/maps/prototype_map.tres
  - data/tuning/loop_tuning.tres
  - input/fast_forward_controller.gd
  - presentation/map/map_root.gd
  - presentation/map/prototype_map.tscn
  - presentation/vfx/projectile_vfx.gd
  - project.godot
  - simulation/buildings/building_system.gd
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
  - tests/e2e/test_results_layout.gd
  - tests/golden/smoke.json
  - tests/integration/test_balance_acceptance.gd
  - tests/unit/test_castle_attack.gd
  - tests/unit/test_fast_forward_rules.gd
  - tests/unit/test_fast_forward_toggle.gd
  - tests/unit/test_fast_forward_toggle.gd.uid
  - tests/unit/test_input_map.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_map_validate_castle.gd
  - tests/unit/test_night_data_contract.gd
  - tools/replay/balance_report.gd
  - tools/replay/replay_driver.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/results/results_screen.gd
  - ui/results/results_screen.tscn
covered_digest: "v2:sha256:5a03d4aa2af75a4df77b8876e1c3bf43e6a2ba0490c9f700213ef85641c3ce29"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 3/4 roadmap success criteria verified (SC4, the owner playtest gate, awaits the owner's round-2 replay); 11/11 requirement IDs have implementation evidence; 5/5 gap-closure plans (02-12 to 02-16) verified in code
  previous_verified: 2026-10-06T14:40:04Z
  previous_commit: a483ff6
  gaps_closed:
    - "G-02-13: castle reach 11 m -> 22 m and arrow speed 18 -> 27 m/s (plan 02-17); fourth review WR-02 closed for INF, NaN and sub-step intervals, fourth review IN-01 closed (sim_events.gd doc names CASTLE_PAYOUT_KEY)"
    - "G-02-14: fast-forward is a latched night-only toggle with a trigger re-arm guard (plan 02-18); fourth review WR-01 closed (add_child_autofree in the controller tests)"
    - "G-02-15: the owner's full wall, night 2 east group of 4 and nights 3 to 5 at W11 E10, W11 E7, W9 E8 (plan 02-19)"
    - "G-02-12 documentation side: Round 3 report and packet, 15 screenshots, launch-checked export (plan 02-20); the owner's decision is NOT closed"
  gaps_remaining: []
  regressions: []
  note: "The previous report had no code gaps (human_needed only). Round 2 of the owner's UAT produced G-02-13, G-02-14, G-02-15 and the gate decision G-02-12 (fixes first); plans 02-17 to 02-20 changed 16 non-planning files since a483ff6 (557 insertions, 145 deletions). I re-read every changed source and data file at HEAD ec0d6ca and ran the changed test files, both replays and the balance command myself. Round 3 has not happened, so SC4 stays a human gate. No source file has changed since 2bdcbd4 (only .planning documents)."
gaps: []
deferred: []
warnings:
  - id: "WR-01 (fifth review)"
    where: "simulation/clock/sim_clock.gd ticks(), simulation/defs/map_config.gd _validate_castle_attack, simulation/night/castle_attack.gd is_armed"
    issue: "Reproduced in my own process on 4.7.2: SimClock.ticks(1e30) is 1 (the ceili overflow is swallowed by the maxi floor), and on the shipped map with castle_attack_interval set to 1e30, validate() returns []. So a huge finite interval still validates, arms the castle and fires it every tick. Plan 02-17's fourth truth ('even a map that was never validated cannot make the castle fire every tick') and the class doc claim are true for INF, NaN, zero, negative and sub-step values and false for an enormous finite one. The shipped data (22 m, 1.5 s, 27 m/s) validates clean and is correct, so the goal is not affected."
    decision_requested: "Fix in the review-fix pass that follows this run (saturate SimClock.ticks, add an upper bound to validate() and is_armed(), two tests), or accept and reword the comment and T-02-33. I did not treat it as a gap because no shipped or owner-authored value triggers it and no roadmap criterion depends on it; it is the same class as fourth-review WR-02, which the previous report also weighed as a warning. A literal reader could call that one plan truth failed, which is why it is listed here and not absorbed."
  - id: "WR-02 (fifth review)"
    where: "tests/unit/test_fast_forward_rules.gd line 20 WRITE_PATTERN"
    issue: "Confirmed by reading: the pattern is Engine\\.time_scale\\s*=[^=], so a second writer written as '*=', '+=' or Engine.set(...) would pass the single-writer scan the controller doc advertises. Test robustness only; the controller is today the only writer and nothing under simulation/ mentions the time scale."
    decision_requested: "Fix (widen the pattern, add three self-check samples) or accept."
behavior_unverified_items: []
human_verification:
  - test: "Owner round-3 playtest gate (ROADMAP SC4, D-18, G-02-12): replay one or two full runs on the fresh build/windows/Duskhold.exe (exported 2026-10-07 in plan 02-20) or the editor binary, then either sign off or name the fixes that must land first, covering the three round-2 fixes (castle 22 m and 27 m/s, the fast-forward toggle, the full-wall night counts)"
    expected: "A recorded decision through /gsd-verify-work. Sign-off means: the castle's reach and arrows feel right, the toggle works the way the owner wants, and the game is 'a little harder' in a way the owner accepts. Otherwise a list of fixes (for example the alternatives k7pS4m or k4pS6m named in 02-PLAYTEST-GATE.md) and any of assumptions 12 to 15 to change"
    why_human: "Fun, tension and fairness are the owner's judgement and ROADMAP success criterion 4 is explicitly a human gate. Bot results, CI, the 829 passing tests and Claude's screenshot review are not the sign-off. 02-UAT.md holds rounds 1 and 2 and no round-3 decision exists"
  - test: "G-02-13 as seen on the real camera: the castle at 22 m reach and 27 m/s arrows"
    expected: "At night a gold arrow leaves the keep at an enemy up to 22 m away and flies visibly fast (an edge shot lands in 25 ticks, under the 45-tick interval, so one arrow is in the air at a time); three hits kill a grunt and two a skirmisher. The owner says whether this reads as simple and not too strong now that it covers the two inner House plots and the centres of houses 3 and 4"
    why_human: "Reach and arrow speed were set at the owner's request and the numbers are pinned by tests, but whether 22 m and 27 m/s feel right, and whether the castle is still 'not too strong', is a feel judgement. The balanced bot rarely lets an enemy within range, so the castle seldom appears in a bot run or in the screenshots"
  - test: "G-02-14: the fast-forward toggle on a real keyboard and a real gamepad trigger"
    expected: "At night one press of F (or one left-trigger pull) switches to 2x and it stays on after release with the 'Fast-forward 2x' label; the next press switches it off. A long hold, a quick tap and a trigger hovering near halfway each toggle once. It resets by itself at dawn, victory and defeat, so each night starts at real time, and presses by day or on the results screen do nothing"
    why_human: "The 02-18 SUMMARY states the trigger path was exercised with synthetic InputEventJoypadMotion events only; a physical trigger's analogue noise and the Windows focus behaviour have not been exercised by automation. Key feel and label legibility are also the owner's. Round 2 already covered the hold version, which this replaces"
  - test: "G-02-15: difficulty after the full wall, in the owner's hands"
    expected: "The owner decides whether the game is 'a little harder' rather than too hard, knowing the measured shape: the balanced bot wins 8 of 10 seeds (36 of 50 on seeds 1 to 50), every loss is a night-3 wall for a House opening that lost two Houses on night 2 (3 gold at dawn 2, below the 4-gold tower, then 21 grunts with no tower), and a tower opening is the strictly safer start"
    why_human: "A human plays worse than a bot, and the packet states plainly that this wall is heavier than the round-1 night 3 the owner could not beat. Whether that is the harder game the owner asked for, or too abrupt, cannot be measured"
  - test: "Assumptions 12 to 15 of the round-3 packet, on the owner's behalf"
    expected: "The owner confirms or changes: 12 (bot measurement rule restated with the 7-or-8 target), 13 and 14 (rewritten in round 3 for the castle numbers and the toggle), 15 (base income shown as a coin from the castle, still standing)"
    why_human: "Product decisions made for the owner"
---

# Phase 2: Night Defense & Playtest Gate Verification Report

**Phase Goal:** The prototype map plays the full day -> night -> dawn loop. The player sees each night coming and starts it deliberately, defends with the king and basic towers, rebuilds and collects income at dawn, and wins or loses on a results screen. Seeded nights replay deterministically, and the owner confirms the loop is fun before anything is built on top of it.
**Verified:** 2026-10-07T00:53:09Z
**Status:** human_needed
**Re-verification:** Yes, after gap-closure plans 02-17 to 02-20 (commits de2be23..2bdcbd4). The previous report (2026-10-06T14:40:04Z, commit a483ff6) is replaced.

## Verdict

The engineering part of the goal is achieved and the four round-3 plans did what they claimed, with one edge exception. I read each changed source and data file at HEAD and ran the changed test files, both replays and the balance command in my own process. There are no FAILED roadmap truths and no code blockers. The last clause of the goal, "the owner confirms the loop is fun before anything is built on top of it", is still not achieved and an agent cannot achieve it. ROADMAP success criterion 4 is a human gate: the owner played rounds 1 and 2 (round 2: 11 pass, 6 issues, all diagnosed), the three round-2 code gaps are closed, and the owner's round-3 replay has not happened. G-02-12 (the owner's "fixes first" decision) closes only when the owner replays and decides through /gsd-verify-work. The phase must not be marked complete, and Phase 3 and meta-progression must not start, until then.

One finding is worth the owner's and the orchestrator's attention. Plan 02-17 closed the fourth review's WR-02 for INF, NaN and sub-step intervals (I checked the code and its tests) and rewrote the comments to say that neither bad nor unvalidated data can make the castle fire every tick. The fifth review's WR-01 says that is still false for a huge finite interval, and I reproduced it: `SimClock.ticks(1e30)` returns 1 and a map with `castle_attack_interval = 1e30` validates clean and arms the castle. That makes one plan truth (02-17, fourth truth) false at the extreme edge. I weighed it as a warning, the same way the previous report weighed the fourth review's WR-02, because the shipped map is valid, no owner-authored value triggers it and no roadmap criterion depends on it. A review-fix pass is expected next.

One process note carried over: ROADMAP marks Phase 2 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form, so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD ec0d6ca (git status clean before and after; no source modified, no process killed, nothing pushed or committed):

| Check | Command | Result |
|---|---|---|
| Castle data and validation | `bash tools/test.sh -gselect=test_map_validate_castle.gd` and `test_castle_attack.gd` | 13/13 and 14/14 |
| Fast-forward toggle | `-gselect=test_fast_forward_rules.gd`, `test_fast_forward_toggle.gd`, e2e `test_fast_forward.gd` | 15/15, 5/5, 5/5 |
| Night data and balance pins | `-gselect=test_night_data_contract.gd`, `test_balance_acceptance.gd` | 12/12, 8/8 |
| Input map and tuning contract | `-gselect=test_input_map.gd`, `test_loop_tuning_contract.gd` | 14/14, 12/12 |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden unchanged) |
| Full-run replay | `bash tools/replay.sh --scenario=full_idle --twice` | `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac` (matches the figure on record) |
| Balance | `bash tools/playtest.sh` (43 s) | `PLAYTEST_OK runs=50` |
| Shipped data probe | scratch script in the session scratchpad, Godot 4.7.2 headless | shipped `validate()` is `[]`; castle range 22.0, speed 27.0; night totals `[5, 12, 21, 21, 21, 22, 27, 33]` |
| Edge probe (WR-01) | same script | `SimClock.ticks(1e30)=1`, `ticks(INF)=1`, `flight_ticks(10, NAN)=1`; `validate()` returns `[]` after setting `castle_attack_interval = 1e30` |

I did not re-run the full 829-test suite (about 5 minutes). The 829 tests in 95 scripts, 0 failures and lint-clean figures at 2bdcbd4 rest on the orchestrator's three wave gates (the last at 2026-10-07T00:28Z), and `git diff 2bdcbd4..HEAD` touches only `.planning`. My own evidence is the ten test files above (88 tests, all passing), both replays and the playtest. Note for the orchestrator: `build/test-results/gut-junit.xml` on disk now holds my last single-file run, not the full suite.

Taken from reports without re-checking: CI (nothing pushed, so no CI run covers any fix commit), Linux/Windows digest equality, the 15 screenshot images and Claude's one-line reads of them, the exe launching (I did not run it; the file `build/windows/Duskhold.exe` exists, dated 05:24 local on 2026-10-07, after the last source commit b89a40d at 04:58 local), the 02-VALIDATION.md and 02-SECURITY.md audits, and the orchestrator's seven whole-feature-off mutation probes (I repeated none).

## What the round-3 plans changed, read from the code

`git diff a483ff6..HEAD -- . ':!.planning/'` covers 16 files (data/maps/prototype_map.tres, input/fast_forward_controller.gd, simulation/defs/loop_tuning.gd, simulation/defs/map_config.gd, simulation/events/sim_events.gd, simulation/night/castle_attack.gd and ten test files). Plan by plan against the gaps:

| Gap and plan | What the code does at HEAD | Status |
|---|---|---|
| G-02-13, 02-17: castle 22 m and 27 m/s | `prototype_map.tres` lines 365 and 367: `castle_attack_range = 22.0`, `castle_projectile_speed = 27.0`; damage 2, interval 1.5 and castle health 70 unchanged (lines 362, 364, 366), grunt health untouched (diff has no enemy file). `MapConfig._validate_castle_attack` now routes range, interval and speed through `_castle_number_errors` (not finite, or negative, one error each) and rejects an attacking castle whose interval is below `SimClock.STEP`. `CastleAttack.is_armed` requires damage above 0, a finite range above 0 and a finite interval of at least one step. `sim_events.gd` documents the castle key in `per_spot`. Edge flight 22 m at 27 m/s is 25 ticks, under the 45-tick interval. Smoke golden and `full_idle` unchanged by the castle (balanced never lets an enemy within 22 m, per the plan's measurement) | VERIFIED, except the huge-finite-interval edge (WR-01 below) |
| G-02-14, 02-18: fast-forward toggle | `FastForwardController` latches `_switched_on` on a counted press edge read in `_process` (never per input event), counted only when `_rearmed` (re-armed once the action is up and its raw strength is below `REARM_STRENGTH` 0.25); toggles only when the phase is NIGHT; clears the latch and re-applies the scale in `_on_phase_changed` when the new phase is not NIGHT, inside the simulation step; `_exit_tree` restores 1.0. A key held from day into night has no edge so it does not switch on. `scale_for` clamps and treats NaN and INF as 1.0. `project.godot` binding unchanged (physical key 70 = F, joypad axis 4, deadzone 0.5). The node is still in `prototype_map.tscn` (line 72, group run_bound) and the HUD still finds it by name. `LoopTuning` change is a comment only. Fourth review WR-01 is closed: the controller tests use `add_child_autofree` and the plain `add_child(` grep in test_fast_forward_rules.gd finds nothing | VERIFIED in code and tests; physical gamepad trigger and feel are the owner's |
| G-02-15, 02-19: the owner's full wall | `prototype_map.tres`: new `Resource_group_n2_east` (east grunts, count 4, start 2.0, interval 1.5) added to night 2's groups; night 3 west 11 east 10; night 4 west 11 east 7; night 5 west 9 east 8; nights 1, 6, 7, 8 and all skirmisher groups untouched in the diff. My probe sums the nights to 5, 12, 21, 21, 21, 22, 27, 33, matching the plan and the contract test. `test_night_data_contract` 12/12 and `test_balance_acceptance` 8/8 (balanced wins 7 or 8 of seeds 1 to 10, losing only seeds 3 and 9 on night 3 or later) | VERIFIED |
| G-02-12 documentation, 02-20 | No code or data changed (the non-planning diff has no 02-20 file). `02-BALANCE-REPORT.md` and `02-PLAYTEST-GATE.md` carry Round 3 sections; the packet's decision prompt states the night-3 wall plainly and says the bots' numbers are not the sign-off. `bash tools/playtest.sh` prints `PLAYTEST_OK runs=50` in my process. 15 screenshots exist under `screenshots/`; the export exists | Evidence VERIFIED; the owner decision is open (SC4) |

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | No day timer; per-spawn-point counts; hold-to-confirm start; enemies destroy buildings; king auto-attacks; knocked-out king respawns after a visible countdown | VERIFIED in code and tests; the owner passed the visuals in round 1 | Unchanged by 02-17 to 02-20; the toggle only acts at night, so it adds no day timer or skip. Night 2 now has an east group, which the spawn telegraph reads from the night data (`test_night_data_contract` pins per-road counts). |
| 2 | Night ends only when every enemy is dead; dawn rebuilds free, surviving Houses pay, rebuilt ones marked; loss when the castle falls; win after the final night on a results screen | VERIFIED in code and tests | Round-3 changes touch no dawn, payout or results code. The castle's longer reach only kills enemies sooner and adds no other way to end a night. Both replays end `outcome=won`. |
| 3 | Seeded night replays identically from the CLI and in CI; GUT covers waves, combat, loop transitions; overlay shows live counts, wave state, paths | VERIFIED locally; CI on the fix commits still pending | Both replays print `REPLAY_OK` twice with the expected digests and smoke equals the golden. Fast-forward changes only how many fixed steps run per real second, and the controller test file scans that nothing under simulation/ mentions the time scale. No CI run covers any fix commit (nothing pushed). |
| 4 | Human playtest gate: owner plays several full runs and signs off or records fixes; no meta-progression until then | NOT ACHIEVED, awaiting the owner's round-3 replay | Round 2 produced G-02-13 to G-02-15 and the decision "fixes first" (G-02-12); plans 02-17 to 02-20 address them; the round-3 packet exists in 02-PLAYTEST-GATE.md. No round-3 owner decision exists in any file. Plan 02-20's own truth for this is `verification: backstop`, which tests cannot satisfy. |

### Plan must_haves (02-17 to 02-20)

| Plan | Truth | Status |
|---|---|---|
| 02-17 | Shipped reach 22.0 and speed 27.0, damage 2, interval 1.5, health 70 unchanged, three hits per grunt and two per skirmisher; edge arrow 25 ticks under the 45-tick interval | VERIFIED (data read, pins in test_map_validate_castle 13/13) |
| 02-17 | validate() reports non-finite range, interval or speed as one error each and an attacking castle with a sub-step interval; exactly one step, no-damage castle, shipped map and smoke fixture stay clean | VERIFIED (code read, tests pass) |
| 02-17 | `is_armed()` refuses non-finite and sub-step values, "so even a map that was never validated cannot make the castle fire every tick", and the doc says exactly that | PARTIAL: true for INF, NaN, zero, negative and sub-step values, false for an enormous finite interval (1e30 reproduced). Recorded as warning WR-01, not a gap. |
| 02-17 | Smoke matches the golden and full_idle is expected at the plan's figure | VERIFIED for the golden. The plan text names `ticks=4007 digest=27fa2a80...` for full_idle; that figure predates 02-19, and the correct post-02-19 figure is the 5140/bb9059c8 pair the plan 02-19 truth and my replay give. Plan 02-17's number was true when it ran, not at HEAD. |
| 02-17 | dawn_payout doc names CASTLE_PAYOUT_KEY | VERIFIED (sim_events.gd diff) |
| 02-18 | One press toggles on at the tuning scale, stays on after release, next press off; resets in the step that leaving NIGHT; presses outside night do nothing and arm nothing; held-into-night key does not switch it on; one press is one toggle for a long hold, a sub-frame tap, one trigger pull and a hovering trigger; HUD unchanged; tests own their controllers; the controller stays the only writer and determinism holds | VERIFIED in code and tests (15 + 5 + 5 passing, controller read line by line). Physical gamepad trigger exercised with synthetic events only, so routed to the owner. |
| 02-19 | Exact night counts, totals 5, 12, 21, 21, 21, 22, 27, 33, escalating roads, balanced 7 or 8 of seeds 1 to 10 losing only seeds 3 and 9 on night 3 or later, the rest of the seeded shape, smoke golden unchanged, full_idle at ticks=5140 digest bb9059c8... | VERIFIED (data read, probe, test_night_data_contract 12/12, test_balance_acceptance 8/8, both replays) |
| 02-20 | PLAYTEST_OK, Round 3 report and packet, screenshots, launch-checked export, T-02-29 wording, owner decision (backstop) | Evidence truths VERIFIED (playtest run and document read; screenshots, export launch and security wording taken from the reports and the file listing). Owner decision: OPEN (SC4). |

Prohibitions (all judgment-tier, marked resolved by the executors; my reading is non-authoritative and none is absorbed into a pass): 02-17 and 02-19 changed no castle damage, interval, health, grunt health, cost, income, base income or starting gold (checked in the data diff; the only `data/` file in the diff is prototype_map.tres and its changes are the two castle lines and the night groups); `tests/golden/smoke.json` and `tests/fixtures` are untouched (the diff lists none); nothing under simulation/ reads or writes the time scale (the controller test scans it, and the simulation diff holds only castle, map-config and doc changes); the `fast_forward` bindings and `fast_forward_scale` (2.0) are unchanged; no push (nothing is on the remote); 02-20 changed no code or data and kept the Round 2 and Round 1 sections; the packet does not present bot numbers as the sign-off. They stay judgment-tier and are confirmed only by the owner's play.

### Requirements Coverage

All 11 IDs appear in at least one plan's `requirements:` frontmatter. Round-3 plans: 02-17 KING-03, LOOP-03; 02-18 LOOP-03, DEV-05; 02-19 LOOP-02, LOOP-03, LOOP-07; 02-20 LOOP-07, DEV-05 (02-01 to 02-16 as in the previous report: 02-11 carries all 11). REQUIREMENTS.md maps exactly these 11 to Phase 2 and ticks all as Complete (lines 12 to 18, 25, 28, 38, 134); none is orphaned and none is missing from a plan. The tick reflects implementation, not the playtest gate (ROADMAP still shows Phase 2 unchecked).

| Requirement | Status | Evidence |
|---|---|---|
| LOOP-01 | SATISFIED | Start is still the only exit from DAY; fast-forward is night-only |
| LOOP-02 | SATISFIED in code; passed by the owner in round 1 | Night 2 gains an east road group; the telegraph reads from night data (contract test) |
| LOOP-03 | SATISFIED | A night ends only on a cleared field; the longer castle reach only kills enemies |
| LOOP-04 | SATISFIED | Free rebuild untouched in round 3 |
| LOOP-05 | SATISFIED | Dawn payout untouched in round 3 |
| LOOP-06 | SATISFIED | Castle-falls-loses untouched |
| LOOP-07 | SATISFIED | Win on the last night; both replays `outcome=won`; the shipped map still validates |
| KING-03 | SATISFIED | King auto-attack unchanged |
| KING-06 | SATISFIED | Knockout and respawn unchanged |
| BLDG-07 | SATISFIED | Unchanged |
| DEV-05 | SATISFIED | Smoke golden and `full_idle` pass at HEAD; the toggle is presentation only |

### Data-Flow Trace (Level 4)

FLOWING: `castle_attack_range` and `castle_projectile_speed` (prototype_map.tres) -> `CastleAttack.step` (`TargetQuery.nearest_enemy`, `SimClock.flight_ticks`) -> `PendingHits` -> enemy damage and `attack_fired` -> `ProjectileVfx`; `fast_forward_scale` (loop_tuning.tres) -> `FastForwardController.scale_for` -> `Engine.time_scale` and `changed` -> HUD label; the night groups (prototype_map.tres) -> `WaveSchedule` -> spawns and the telegraph. No hardcoded literal stands in for these paths.

### Anti-Patterns Found

None blocking. A grep for `TBD`, `FIXME`, `XXX`, `TODO`, `HACK` and `PLACEHOLDER` across every `.gd`, `.tres` and `.tscn` file changed since a483ff6 found no matches. No stubs or hardcoded empty data flow to the UI.

## Open code-review findings (fifth review, 2026-10-07T00:45:45Z, scoped to the round-3 plans: 0 critical, 2 warnings, 4 info; ALL OPEN, none fixed)

This is 02-REVIEW.md. It is not 02-REVIEW-FIX.md, which records an older fix pass. A review-fix pass is expected after this run.

| ID | Verdict | Weighing |
|---|---|---|
| WR-01 | WARNING, hardening gap, not a roadmap or goal failure; decision requested | Reproduced above. A huge finite interval (1e30) passes `validate()`, arms the castle and fires it every tick, because `SimClock.ticks` overflows `ceili` and the `maxi` floor returns 1. It makes plan 02-17's fourth truth and threat T-02-33's "closed" wording overclaim at the extreme edge. Not a gap: it needs authored data far outside the shipped values, the shipped map is correct, every case the plan's tests describe is guarded and passes, and no ROADMAP criterion depends on it. The reviewer's fix (saturate `ticks`, bound the interval in `validate()` and `is_armed()`, two tests) is small. |
| WR-02 | WARNING, test robustness, not a must-have | Confirmed: `WRITE_PATTERN` at test_fast_forward_rules.gd line 20 matches only a plain `=`, so `*=`, `+=` and `Engine.set` would slip past the single-writer scan. Today the controller is the only writer. The e2e file test_fast_forward.gd (5 tests) and the whole-feature-off probes still guard the feature. |
| IN-01 | INFO | `BALANCED_MIN_WINS = 7` is unreachable next to the exact-seed pin (the window can never fail low), and one night-totals test name still says "unchanged". Test hygiene. |
| IN-02 | INFO | `is_armed()` does not check `castle_projectile_speed` is finite; a NaN speed arms the castle and the arrow lands next tick (benign, contradicts the doc's "unvalidated data" wording). |
| IN-03 | INFO | `validate()` accepts a NaN `castle_radius` (and the enemy float fields share the hole). Same defect class as WR-01, outside the round-3 diff. |
| IN-04 | INFO | An orphaned "## Read through" line in the `fast_forward_scale` doc comment in loop_tuning.gd. |

Still open from earlier reviews and not described as fixed: the third review's WR-01 (the grace tests in `tests/e2e/test_results_screen.gd` can all end `pending()` with the grace never applied; I confirmed `pending(` at lines 374, 406 and 426) and its IN-05, plus IN-06 in the ledger. The fourth review's WR-01, WR-02 and IN-01 are closed by 02-17 and 02-18 (WR-02 only for INF, NaN and sub-step values; its finite-huge remainder is the fifth review's WR-01). None of the open items is a roadmap criterion and none changes the goal verdict.

## Flagged assumptions and deviations

The round-3 packet rewrites assumptions 13 and 14 for the castle numbers and the toggle, restates 12 with the owner's 7-or-8 target and keeps 15; assumptions 1 to 11 were passed by the owner in round 1. The extra difficulty is a night-3 wall for House openings: a House opening that loses two Houses on night 2 has 3 gold at dawn 2, below the 4-gold tower, and meets 21 grunts on night 3 with no tower, which the packet says is heavier than the round-1 night 3 the owner could not beat. The bots lose seeds 3 and 9 and win 8 of 10 (36 of 50 on seeds 1 to 50). The owner chose this exact edit; the alternatives `k7pS4m` and `k4pS6m` are named in the packet. Plan 02-17's full_idle figure (ticks 4007) is superseded by 02-19's (5140), which is the current truth.

## Human Verification Required

The structured list is in the frontmatter (5 items); the orchestrator extends 02-UAT.md from it. Round-1 tests 3 to 11 and round-2 tests 12 to 17 are not repeated. The owner replays one or two runs on the fresh `build/windows/Duskhold.exe` (or the editor binary) and records sign-off or fixes through `/gsd-verify-work`. The UAT gap rows for G-02-13, G-02-14 and G-02-15 still read `failed`; verify-work reconciles them once the owner confirms the fixes.

## Gaps Summary

No code gaps and no blockers. The phase is `human_needed` because success criterion 4 has not happened: the owner has not yet replayed the round-3 build and decided. Before or alongside the owner's play: run the review-fix pass for the fifth review (WR-01 and WR-02 first, then IN-01 to IN-04), triage the older open items, and push so CI runs on the fix commits, because the only green CI run predates them all. Do not treat the 829 green tests, the replay digests, the balance table or the screenshot review as the sign-off.

---

_Verified: 2026-10-07T00:53:09Z_
_Verifier: Claude (gsd-verifier)_
