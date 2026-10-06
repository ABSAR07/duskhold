---
phase: 02-night-defense-playtest-gate
verified: 2026-10-06T14:40:04Z
status: human_needed
score: 3/4 roadmap success criteria verified (SC4, the owner playtest gate, awaits the owner's round-2 replay); 11/11 requirement IDs have implementation evidence; 5/5 gap-closure plans (02-12 to 02-16) verified in code
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
  - tests/unit/test_map_validate_castle.gd
  - tools/replay/balance_report.gd
  - tools/replay/replay_driver.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/results/results_screen.gd
  - ui/results/results_screen.tscn
covered_digest: "v2:sha256:2c1a70161d15e2d24184e71b074cffba5068560d170adc92fdc7641e89a5477b"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 3/4 roadmap success criteria verified (SC4 pending); 11/11 requirement IDs
  previous_verified: 2026-10-06T05:54:21Z
  previous_commit: 00cf14b
  gaps_closed:
    - "G-02-1 point 1: no base gold gain at each wave (plan 02-12, base dawn income from the castle)"
    - "G-02-1 point 2: the castle has no attack (plan 02-15)"
    - "G-02-1 point 3: speed-up at least 1.5x (plan 02-13: 12 m/s sprint and night-only hold-to-fast-forward)"
    - "G-02-1 point 4 evidence: balance re-measured under the owner's rule (plan 02-16); the owner's replay decision is NOT closed"
    - "G-02-2: gap above the results buttons (plan 02-14, 11 px margin)"
  gaps_remaining: []
  regressions: []
  note: "The previous report had no code gaps (human_needed only). The owner played round 1 and reported G-02-1 (major) and G-02-2 (cosmetic); five gap-closure plans changed 50 files since 00cf14b. Every source file the plans changed was re-read at HEAD a483ff6. Round 2 has not happened, so SC4 stays a human gate."
gaps: []
deferred: []
warnings:
  - id: "WR-02 (fourth review)"
    where: "simulation/defs/map_config.gd _validate_castle_attack and simulation/night/castle_attack.gd is_armed"
    issue: "Plan 02-15's edge truth ('bad data can never make it fire every tick') and the closed threat T-02-33 overclaim. Reproduced in my own process on 4.7.2: with damage 1, range INF and interval INF, validate() returns [] and SimClock.ticks(INF) is 1; castle_attack_interval 0.001 also validates clean and ticks() floors at 1. Zero, negative and missing values ARE rejected or leave the castle off. The shipped data (11 m, 1.5 s, 18 m/s) is correct, so the goal is not affected."
    decision_requested: "Fix in the next review-fix pass (finite and at-least-one-step checks, three tests), or accept and reword the comments and T-02-33. I did not treat it as a gap because no shipped or owner-authored value triggers it and no roadmap criterion depends on it."
  - id: "WR-01 (fourth review)"
    where: "tests/unit/test_fast_forward_rules.gd lines 42-47"
    issue: "_controller_on uses add_child with no autofree (confirmed by reading it), so a stale controller from an earlier test can mask a deleted phase_changed handler in test_a_night_that_starts_while_the_key_is_already_down_runs_fast. The real-scene e2e file tests/e2e/test_fast_forward.gd (5 tests, passing) is not affected."
    decision_requested: "Fix (add_child_autofree plus one partial-mutation check) or accept. Test robustness only."
behavior_unverified_items: []
human_verification:
  - test: "Owner round-2 playtest gate (ROADMAP SC4, D-18): replay one or two runs on the fresh build/windows/Duskhold.exe (exported in 02-16) and either sign off or name further fixes, covering the four G-02-1 points and the G-02-2 spacing"
    expected: "A recorded decision through /gsd-verify-work. Sign-off means: base gold fixes the tower-first trap without making gold meaningless, the castle attack is simple and not too strong, the 12 m/s sprint and the night fast-forward are fast enough, the game is a bit easier but still tense, and the results spacing looks even. Otherwise a list of fixes and any of assumptions 12 to 15 to change"
    why_human: "Fun, tension, fairness and readability are the owner's judgement. Bot results, CI, the 817 passing tests and Claude's screenshot review are explicitly not the sign-off. 02-UAT.md records round 1 (9 pass, 2 issues) and no round-2 decision exists."
  - test: "G-02-1 points 1 and 2, as seen on the real camera: the castle's base-income coin and the castle's arrows"
    expected: "At dawn one coin starts from the top of the castle keep (CASTLE_ANCHOR, 4.5 m above the castle centre) and flies to the gold counter, and the player reads it as the castle paying 1 gold. At night, when an enemy comes within 11 m of the castle, a gold arrow leaves the top of the keep (CASTLE_LAUNCH_HEIGHT); three hits kill a grunt and two a skirmisher. Judge whether the castle attack reads as simple and not too strong"
    why_human: "The executors flagged the coin start point and the arrow look as human_judgment. A still screenshot cannot show which coin is the castle's, and the balanced bot never lets an enemy within 11 m, so castle arrows rarely appear in a bot run or in the screenshots (02-PLAYTEST-GATE.md says so)."
  - test: "G-02-1 point 3: how the 12 m/s sprint, 60 m/s^2 braking and the night 2x fast-forward feel in the owner's hands"
    expected: "The king still stops on a plot when the sprint key is released (full-sprint stop 1.2 m, inside the 2.5 m build radius) and is not uncontrollable at 12 m/s. Holding F or the left trigger at night runs the game at 2x and the 'Fast-forward 2x' label (top right, 26 px, gold) is legible. The game returns to real time at dawn, in the 1.2 s defeat beat and on the results screen. The owner says whether night-only is acceptable or wants it by day too or faster than 2x (assumption 14)"
    why_human: "Feel, speed and label legibility. The code and tests prove the numbers and the night-only rule, not that 'at least 1.5x faster' feels right. Round-1 test 10 (hand-steered king handling) passed at 8 m/s; the sprint changed, so that judgement is partly reopened here."
  - test: "G-02-1 point 4: difficulty for a human after the three fixes"
    expected: "The owner decides whether the run is now 'a bit easier' rather than too easy, and whether night 3 and the castle still feel fair. The bots now win 10 of 10 (balanced and tower-first); the balanced bot loses no building and is never knocked out, which is easier than 'a bit easier'. If the owner finds it too easy, the levers named in 02-BALANCE-REPORT.md are the night counts and the castle's damage, never grunt health"
    why_human: "Plan 02-16 applied none of the owner's levers because the balanced bot lost no run, by the owner's own rule. A human plays worse than a bot, and whether the result is fun cannot be measured by bots."
  - test: "G-02-2: results screen spacing on a real Victory and Defeat"
    expected: "The visible gap from the last stat row to the Play again and Quit buttons looks equal to the gap between stat rows (11 px margin above the button row). Quit is still distinguishable. Play again, Quit and the 0.6 s accidental-restart grace behave as the owner passed them in round 1"
    why_human: "Spacing is a visual judgement. test_results_layout.gd pins the 11 px constant and the rect arithmetic, not the optical gap (fourth review IN-02)."
  - test: "Assumptions 12 to 15 of the round-2 packet, on the owner's behalf"
    expected: "The owner confirms or changes: 12 (bot measurement rule), 13 (base income of 1 gold per dawn paid on every dawn including the first, the castle attack numbers, no night-3 or castle-health change), 14 (fast-forward night only, 2x, F or left trigger), 15 (base income shown as a coin from the castle, not a text line)"
    why_human: "Product decisions made for the owner."
---

# Phase 2: Night Defense & Playtest Gate Verification Report

**Phase Goal:** The prototype map plays the full day -> night -> dawn loop. The player sees each night coming and starts it deliberately, defends with the king and basic towers, rebuilds and collects income at dawn, and wins or loses on a results screen. Seeded nights replay deterministically, and the owner confirms the loop is fun before anything is built on top of it.
**Verified:** 2026-10-06T14:40:04Z
**Status:** human_needed
**Re-verification:** Yes, after gap-closure plans 02-12 to 02-16 (commits b6c47d5..a483ff6). The previous report (2026-10-06T05:54:21Z, HEAD 00cf14b) is replaced.

## Verdict

The engineering part of the goal is achieved and the five gap-closure plans did what they claimed. I read each changed source file at HEAD and ran the new test files and the replay and balance commands myself. There are no FAILED truths and no code blockers. The last clause of the goal, "the owner confirms the loop is fun before anything is built on top of it", is still not achieved and an agent cannot achieve it. ROADMAP success criterion 4 is a human gate: the owner played round 1 (9 pass, 2 issues), the issues were fixed, and the owner's round-2 replay on the fresh export has not happened. The phase must not be marked complete, and Phase 3 and meta-progression must not start, until the owner decides through /gsd-verify-work.

Two fourth-review warnings are open and I reproduced one of them (WR-02): the castle-attack validation does not give the "can never fire every tick" guarantee that plan 02-15 and the closed threat T-02-33 claim. I weighed it and did not call it a gap, for the reason in "Open code-review findings". Both warnings are in the frontmatter with a decision requested.

One process note carried over: ROADMAP marks Phase 2 `Mode: mvp`, but the goal is not in "As a ..., I want ..., so that ..." form, so I verified with the standard goal-backward method and wrote no MVP user-flow table.

## What I ran and read

Run in my own process at HEAD a483ff6 (git status clean before and after the runs; no source modified, no process killed, nothing hung):

| Check | Command | Result |
|---|---|---|
| New unit tests | `bash tools/test.sh -gselect=<file>` per file | test_dawn_income 12/12, test_map_validate_income 8/8, test_castle_attack 14/14, test_map_validate_castle 9/9, test_fast_forward_rules 14/14, test_king_movement_config 7/7 |
| New e2e and integration tests | same, per file | test_fast_forward 5/5, test_dawn_payout_castle 2/2, test_results_layout 4/4, test_projectiles_visible 8/8, test_balance_acceptance 7/7 |
| Smoke replay vs golden | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` | `REPLAY_OK ... ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden unchanged) |
| Full-run replay | `bash tools/replay.sh --scenario=full_idle --twice` | `REPLAY_OK ... outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435` (matches the orchestrator's figure) |
| Balance | `bash tools/playtest.sh` (38 s) | `PLAYTEST_OK runs=50` |
| Castle-attack validation probe | scratch script in the session scratchpad, Godot 4.7.2 | `SimClock.ticks(INF)=1`, `ticks(0.001)=1`, `ticks(NAN)=1`; `validate()` returns `[]` for damage 1 with range INF and interval INF, and for interval 0.001 |

I did not re-run the full 817-test suite, as instructed. Note for the orchestrator: `build/test-results/gut-junit.xml` on disk was overwritten by a mutation probe (one suite, test_dawn_income, 11 of 12 failing) and then by my single-file runs, so it is not evidence of the full suite. The 817/817 figure rests on the orchestrator's earlier run and I did not reproduce it; my own evidence is the 11 new test files above plus the replays and the playtest. No source changed after commit 07414dd (2026-10-06T19:03+05:00, local clock), and the export file is dated 19:05 local, after it.

Taken from reports without re-checking: CI (nothing was pushed in this run; 64 commits remain local, and the only green CI run predates every fix pass), Linux/Windows digest equality, the screenshot images, the Windows exe launching (I did not run the exe), the contents of 02-VALIDATION.md and 02-SECURITY.md, and the orchestrator's and executors' mutation probes (13 recorded, all caught; I repeated none).

## What the gap-closure plans changed, read from the code

`git diff 00cf14b..HEAD -- . ':!.planning/'` covers 50 files. Plan by plan against the gaps:

| Gap and plan | What the code does at HEAD | Status |
|---|---|---|
| G-02-1 point 1, 02-12: base gold each wave | `MapConfig.base_dawn_income` (script default 0, `prototype_map.tres:346` = 1; validate() rejects negatives and a spot id equal to the reserved `CASTLE_PAYOUT_KEY`). `RunContext` passes it to the new last argument of `RunManager` (clamped at 0). `_apply_dawn_payout` takes `dawn_income_by_spot()` (a fresh dictionary; towers and rebuilt or destroyed Houses excluded), adds `per_spot[CASTLE_PAYOUT_KEY] = base` after the building entries, sums the total from the dictionary and grants it, so the total equals the sum of per_spot even with no House standing. `DawnPayoutVfx.spot_screen_point` projects the castle key above the castle (`CASTLE_ANCHOR` 4.5 m) so the coin flies from the castle. Smoke golden unchanged (the base defaults to 0 in fixtures) | VERIFIED |
| G-02-1 point 3a, 02-13: faster sprint | `king.tres`: `sprint_multiplier = 2.4` (5.0 x 2.4 = 12 m/s), `acceleration = 60.0`; `king_def.gd` defaults match; test_king_movement_config 7/7 | VERIFIED |
| G-02-1 point 3b, 02-13: night-only fast-forward | `fast_forward` action in `project.godot` (physical key F, joypad axis 4 = left trigger; no mouse). `FastForwardController` is a node in `prototype_map.tscn` (group run_bound, so `MapRoot` calls `bind_run`). `scale_for` returns 1.0 unless the phase is NIGHT and the key is held, else `fast_forward_scale` (2.0 in `loop_tuning.tres`) clamped to 1.0..4.0, with NaN and INF as 1.0. The `phase_changed` handler re-applies inside the simulation step, so dawn, victory and defeat drop to 1.0 synchronously; `_exit_tree` restores 1.0. A repository grep for `time_scale` finds the controller as the only writer (debug_overlay.gd only mentions it in a comment) and nothing under simulation/ reads it. The HUD finds the `FastForward` node and shows `Fast-forward %sx` from its `changed` signal. e2e test_fast_forward 5/5 | VERIFIED in code and tests; feel and label legibility are the owner's |
| G-02-1 point 2, 02-15: castle attack | `CastleAttack` (RefCounted, integer ticks, no randomness) is created in `NightSim._init`, reset in `begin_night`, and stepped in `step` between towers and enemies. It targets `TargetQuery.nearest_enemy` within `castle_attack_range`, enqueues a `PendingHits.KIND_CASTLE` hit with `flight_ticks`, emits `attack_fired`, keeps a `_ready_at` cooldown, and does nothing when destroyed or unarmed. Shipped data: damage 2, range 11.0, interval 1.5, speed 18.0 (3 shots kill a 6 hp grunt, 2 kill a 4 hp skirmisher). `ProjectileVfx` draws castle arrows from `CASTLE_LAUNCH_HEIGHT`; the replay driver and balance report count castle kills. Smoke golden unchanged (attack fields default 0). test_castle_attack 14/14, test_projectiles_visible 8/8 | VERIFIED; the "never fires every tick" edge truth is overclaimed for INF and sub-step data (WR-02) |
| G-02-2, 02-14: results button gap | `results_screen.tscn` wraps `Buttons` in `ButtonsMargin` (margin_top 11); the script reaches the buttons by unique name so nothing else moved; stat rows untouched. test_results_layout 4/4 | VERIFIED in code; the optical gap is the owner's judgement |
| G-02-1 point 4, 02-16: re-measure and packet | `tools/playtest.sh` prints `PLAYTEST_OK runs=50`. The Round 2 table in 02-BALANCE-REPORT.md (balanced 100%, greedy_economy 0% with median loss night 5, no_build 0% by night 1, towers_first 100% with 7.0 gold earned, was 0.0) meets the plan's targets. No night-3 count, castle health, grunt health, cost, income or starting-gold change was made: grunt `max_health = 6`, `starting_gold = 4` and `castle_max_health = 70` at HEAD; the `data/` diff is only king.tres, prototype_map.tres and loop_tuning.tres; `tests/golden` and `tests/fixtures` are untouched. 02-PLAYTEST-GATE.md has a Round 2 section with the change table, controls, balance table, assumptions 12 to 15 and the decision prompt | Evidence VERIFIED; the owner decision is open (SC4) |

## Goal Achievement

### ROADMAP success criteria (the contract)

| # | Success criterion | Status | Evidence |
|---|---|---|---|
| 1 | No day timer; per-spawn-point counts; hold-to-confirm start; enemies destroy buildings; king auto-attacks; knocked-out king respawns after a visible countdown | VERIFIED in code and tests; the owner passed the visuals in round 1 | Unchanged by 02-12 to 02-16 except that the king moves faster. The owner passed tests 3 to 8 and 10 of 02-UAT.md. `RunManager.tick` still has no DAY timer case. |
| 2 | Night ends only when every enemy is dead; dawn rebuilds free, surviving Houses pay, rebuilt ones marked; results screen on loss or win | VERIFIED in code and tests | `_enter_dawn` rebuilds, repairs, then `_apply_dawn_payout()`. The base income is added without touching the House rules: rebuilt Houses still pay nothing while the castle's base income is still paid (test_dawn_income 12/12, including the LOOP-05 edge). The results screen differs only by the 11 px margin. |
| 3 | Seeded night replays identically from the command line and in CI; GUT covers waves, combat, loop transitions; overlay shows live counts, wave state, paths | VERIFIED locally; CI on the fix commits still pending | Both replays print `REPLAY_OK` twice with the expected digests and smoke equals the golden. Fast-forward only changes how many fixed steps run per real second and nothing under simulation/ reads the time scale, so determinism holds. No CI run covers any fix commit (nothing pushed). |
| 4 | Human playtest gate: owner plays several full runs and signs off or records fixes; no meta-progression until then | NOT ACHIEVED, awaiting the owner's round-2 replay | Round 1 produced G-02-1 and G-02-2 (02-UAT.md, status diagnosed); plans 02-12 to 02-16 address them; the round-2 packet exists in 02-PLAYTEST-GATE.md. No round-2 owner decision exists in any file. Plan 02-16's own truth for this is `verification: backstop`, which tests cannot satisfy. |

### Plan must_haves (02-12 to 02-16)

| Plan | Truth | Status |
|---|---|---|
| 02-12 | Every dawn grants `base_dawn_income` (1) on top of Houses, even with no House; towers pay nothing; the total equals the sum of per_spot with the castle key last; the coin flies from the castle; base 0 pays as before and the smoke golden is unchanged; validate() rules; a rebuilt House pays nothing while the base is paid | VERIFIED (code read; test_dawn_income, test_map_validate_income, test_dawn_payout_castle; smoke replay) |
| 02-13 | Sprint 12 m/s with acceleration 60; hold fast_forward at night runs at `fast_forward_scale` 2.0 through Engine.time_scale; night only, dropping to 1.0 inside the step that leaves the night; same results under doubled deltas; HUD label; single writer that restores on exit tree; scale clamped, NaN and INF as 1.0 | VERIFIED (code read; test_fast_forward_rules 14/14, test_fast_forward 5/5, test_king_movement_config 7/7; repository grep for the single writer) |
| 02-14 | 11 px above the button row, stat rows untouched, buttons still reachable by name | VERIFIED (scene diff, test_results_layout 4/4); the optical result is the owner's |
| 02-15 | The castle shoots the nearest enemy within 11 m for 2 every 1.5 s, three shots per grunt and two per skirmisher; reaches a skirmisher at 10.5 m; silent when destroyed, by day, at dawn and after the run; fixed step order; visible gold arrow from the keep; Kills castle column; defaults 0 leave the golden unchanged; boundary at exactly the range; armed only with damage, range and interval above 0 | VERIFIED, except the last phrase of the "malformed data" edge, "so bad data can never make it fire every tick": true for zero, negative and missing values, FALSE for a non-finite or sub-step interval (WR-02). Weighed below as a warning with a decision requested. |
| 02-16 | PLAYTEST_OK and a Round 2 section; night 3 and castle health change only if balanced lost a run (it did not); acceptance test pins the shape; 15 screenshots still reach their states; fresh export and a Round 2 packet; owner decision (backstop) | Evidence truths VERIFIED (playtest run, acceptance test 7/7, packet and report read). The screenshots and the exe launch are taken from the report (the export file exists and postdates the last source change). Owner decision: OPEN (SC4). |

Prohibitions (all judgment-tier, marked resolved by executors; my reading is non-authoritative): no tower income, costs, starting gold, grunt health, night composition or castle health changed (checked in the data diff); `tests/golden/smoke.json` and `tests/fixtures` untouched (checked by diff); nothing under simulation/ reads or writes the time scale (checked by grep); `fast_forward` has no mouse binding (checked in project.godot); no push (64 commits remain local); the bots' numbers and screenshots are not presented as the owner's sign-off (the packet says so twice). None is absorbed into a pass: they stay judgment-tier and are confirmed only by the owner's play.

### Requirements Coverage

All 11 IDs appear in at least one plan's `requirements:` frontmatter (02-01: DEV-05, LOOP-03, KING-03; 02-02: LOOP-03, LOOP-07; 02-03: KING-06; 02-04: BLDG-07; 02-05: KING-03, BLDG-07; 02-06: LOOP-04, LOOP-05; 02-07: LOOP-06, LOOP-07; 02-08: LOOP-01, LOOP-02, DEV-05; 02-09: DEV-05; 02-10: DEV-05, LOOP-07; 02-11: all 11; 02-12: LOOP-04, LOOP-05; 02-13: LOOP-03, KING-03; 02-14: LOOP-06, LOOP-07; 02-15: KING-03, LOOP-03; 02-16: LOOP-05, LOOP-07, DEV-05). REQUIREMENTS.md maps exactly these 11 to Phase 2 and ticks all as Complete; none is orphaned and none is missing from a plan. The tick reflects implementation, not the playtest gate (ROADMAP still shows Phase 2 unchecked).

| Requirement | Status | Evidence |
|---|---|---|
| LOOP-01 | SATISFIED | Start is still the only exit from DAY. Fast-forward is night-only, so it adds no day timer or skip. |
| LOOP-02 | SATISFIED in code; passed by the owner in round 1 | Spawn telegraph and preview unchanged |
| LOOP-03 | SATISFIED | A night still ends only on a cleared field; the castle attack only kills enemies and adds no other way to end a night |
| LOOP-04 | SATISFIED | Free rebuild unchanged; test_dawn_rebuild updated for the base income |
| LOOP-05 | SATISFIED | `dawn_income_by_spot` still skips rebuilt Houses; the base income is a separate castle entry |
| LOOP-06 | SATISFIED | Castle-falls-loses unchanged; results screen gap added |
| LOOP-07 | SATISFIED | Win on the last night unchanged |
| KING-03 | SATISFIED | King auto-attack unchanged; faster sprint |
| KING-06 | SATISFIED | Knockout and respawn unchanged; the controller comments and e2e file state fast-forward also works while the king is down |
| BLDG-07 | SATISFIED | Unchanged |
| DEV-05 | SATISFIED | Both replays and the smoke golden pass at HEAD; determinism guards untouched |

### Data-Flow Trace (Level 4)

FLOWING: `base_dawn_income` (prototype_map.tres) -> `RunContext` -> `RunManager._apply_dawn_payout` -> `Economy.grant` and the `dawn_payout` signal -> `DawnPayoutVfx` castle coin and the HUD gold; `fast_forward_scale` (loop_tuning.tres) -> `FastForwardController.scale_for` -> `Engine.time_scale` and `changed` -> HUD label; `castle_attack_*` (prototype_map.tres) -> `CastleAttack.step` -> `PendingHits` -> enemy damage and `attack_fired` -> `ProjectileVfx` arrow; king `sprint_multiplier` and `acceleration` (king.tres) -> `KingDef` -> king movement. No hardcoded literal stands in for any of these paths.

### Anti-Patterns Found

None blocking. A grep for `TBD`, `FIXME`, `XXX`, `TODO`, `HACK` and `PLACEHOLDER` across every `.gd`, `.tscn`, `.tres` file and `project.godot` changed since 00cf14b found no matches. No stubs or hardcoded empty data flow to the UI.

## Open code-review findings (fourth review, 2026-10-06T14:31:33Z: 0 critical, 2 warnings, 2 info; ALL OPEN, none fixed)

| ID | Verdict | Weighing |
|---|---|---|
| WR-02 | WARNING, hardening gap, not a roadmap or goal failure; decision requested | I reproduced it (probe above). It makes plan 02-15's edge truth and T-02-33's closed status overclaim: INF or a 0.001 s interval passes `validate()`, arms the castle and fires it every tick; a NaN range or interval passes `validate()` and silently leaves the castle off. I did not make it a gap because it needs authored map data outside the shipped values, the shipped map is correct, every zero, negative and missing case the plan's tests describe is guarded and passes, and no ROADMAP criterion depends on it. A reader who applies the plan text literally could call that truth failed, which is why it is a decision item and not silently absorbed. The reviewer's fix is small (finite checks, a one-step minimum, `is_finite()` in `is_armed`, three tests), or reword the comments and T-02-33 |
| WR-01 | WARNING, test robustness, not a must-have | Confirmed in `tests/unit/test_fast_forward_rules.gd`: `_controller_on` uses `add_child` with no autofree and `after_each` does not free controllers, so an earlier test's night-state controller can hold `Engine.time_scale` at 2.0 while a later test asserts it. A deleted `phase_changed` handler could therefore slip past that one unit test. The scene-level `tests/e2e/test_fast_forward.gd` (5 tests) and the whole-feature-off probe (11 of 19 failures, per the orchestrator) still guard the feature |
| IN-01 | INFO | `sim_events.gd:16` still says per_spot maps spot ids only; it can now also carry the castle key (read in the file) |
| IN-02 | INFO | `test_results_layout.gd` pins the 11 px constant, not the optical gap; its own comment says so |

Still open from the third review: its WR-01 (the grace tests in `tests/e2e/test_results_screen.gd` can all end `pending()` with the grace never applied; I confirmed `pending(` at lines 374, 406 and 426) and IN-05. Also open in the ledger: IN-06. The previous verifier judged these not must-haves and I agree: the code is correct today, the screen's behaviour passed the owner's round-1 test, and none is a roadmap criterion. I do not describe any of them as fixed.

## Flagged assumptions and deviations

The packet's assumptions 12 and 13 are rewritten and 14 and 15 are new (fast-forward night only at 2x; the base income shown as a coin from the castle and paid on every dawn including the first). Assumptions 1 to 11 are unchanged and were passed by the owner in round 1. Plan 02-16 made no data change because the balanced bot won 10 of 10, so the owner's two levers (night-3 east grunts 5 to 4, then castle health 70 to 80) were not applied. The bots now find the game easier than "a bit easier" (balanced loses no building and is never knocked out, and the castle kills nothing for it); the packet says so and leaves the call to the owner.

## Human Verification Required

The structured list is in the frontmatter (6 items); the orchestrator extends 02-UAT.md from it. Tests 3 to 11 of the round-1 UAT passed and are not repeated, except where the gap plans changed what they show: the sprint change touches round-1 test 10, and the results layout change is item 5 here (round-1 test 2). The owner replays one or two runs on the fresh `build/windows/Duskhold.exe` (or the editor binary) and records sign-off or fixes through `/gsd-verify-work`.

## Gaps Summary

No code gaps and no blockers. The phase is `human_needed` because success criterion 4 has not happened: the owner has not yet replayed the fixed build and decided. Before or alongside the owner's play: decide on WR-02 (fix, or accept and correct the T-02-33 wording) and WR-01, triage IN-01, IN-02, IN-05 and IN-06 as `fixed`, `skipped` or `deferred`, and push so CI runs on the fix commits, because the only green CI run predates them all. Do not treat the 817 green tests, the replay digests, the balance table or the screenshot review as the sign-off.

---

_Verified: 2026-10-06T14:40:04Z_
_Verifier: Claude (gsd-verifier)_
