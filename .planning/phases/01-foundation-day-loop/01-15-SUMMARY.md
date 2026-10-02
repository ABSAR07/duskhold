---
phase: 01-foundation-day-loop
plan: 15
subsystem: coin-vfx-and-tools
tags: [godot, gdscript, vfx, coin-stream, sandbox, screenshot, gap-closure, gut, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "LoopTuning.coin_interval / coin_due_seconds / build_hold_seconds, BuildHoldController hold clock, E2eSupport.map_with_tier_cost (plan 01-14)"
provides:
  - "CoinDripVfx coin stream that follows the accelerating hold: per-coin flight of 90% of the gap to the next coin, 0.12 s floor, ceiling derived from LoopTuning.COIN_DRIP_INTERVAL_MAX_S"
  - "Staggered, capped coin rush for the 3 s cap fast-forward (and any same-frame group): launches inside 0.3 s, at most 12 coins drawn"
  - "CoinDripVfx.flight_seconds_for / launch_stagger static helpers and get_last_burst_delays test hook"
  - "build_in_progress screenshot timed from the curve helpers"
  - "tools/sandbox/hold_pacing_sandbox: real-window sandbox with House tiers of 15, 30 and 50 coins"
affects: [01-16 test decoupling and SECURITY/VALIDATION refresh, verify-work UAT re-check of G-01-58, Phase 2 playtest tuning]

actuals:
  tokens: 21000
  tasks: 2
  commits: 3

plan_head_before: bde91c90d1c4acaba0e6dde4fb6dc0b301a64b31
plan_head_after: 5f9a31956978834d45d578b85e1ec5fc1902e931

tech-stack:
  added: []
  patterns:
    - "Same-frame signal group detected with Engine.get_process_frames(): the first emission of a frame opens a group, later ones extend it"
    - "A visual cap and stagger window per group bound node count however many signals arrive (T-01-25)"
    - "Visual ceilings derived from the data-side bound instead of a second hand-edited literal"
    - "Tool scenes deep-copy shipped data before repricing it, and live under tools/ so the export excludes them"

key-files:
  created:
    - tests/unit/test_coin_drip_flight.gd
    - tests/unit/test_coin_drip_flight.gd.uid
    - tests/e2e/test_coin_drip_burst.gd
    - tests/e2e/test_coin_drip_burst.gd.uid
    - tools/sandbox/hold_pacing_sandbox.gd
    - tools/sandbox/hold_pacing_sandbox.gd.uid
    - tools/sandbox/hold_pacing_sandbox.tscn
    - tests/e2e/test_hold_pacing_sandbox.gd
    - tests/e2e/test_hold_pacing_sandbox.gd.uid
  modified:
    - presentation/vfx/coin_drip_vfx.gd
    - tools/screenshot/shot_scenarios.gd

key-decisions:
  - "Same-frame group stagger is sized from the coins that can still arrive this frame (cost - coins_paid + 1, capped at 12), so a normal drip is a group of one at delay 0 and the cap rush spreads inside 0.3 s"
  - "Delayed rush coins are spawned at once at the king with a tween delay, like the existing refund coins; hiding them until launch was not needed"
  - "All Design Defaults from the plan shipped unchanged"

patterns-established:
  - "Coin flight comes from LoopTuning.coin_interval(coins_paid + 1), never from a VFX-side interval"
  - "A shot scenario that needs a hold at a given coin count derives its wait from coin_due_seconds / coin_interval"

requirements-completed: [BLDG-03, BLDG-04, DEV-04]

coverage:
  - id: D1
    description: "Each dripped coin flies for 90% of the gap to the next one (never below 0.12 s, never above the derived ceiling), so every shipped build still streams one coin at a time while later coins speed up"
    requirement: "BLDG-03"
    verification:
      - kind: unit
        ref: "tests/unit/test_coin_drip_flight.gd#test_every_shipped_coin_lands_before_the_next_one_leaves"
        status: pass
      - kind: unit
        ref: "tests/unit/test_coin_drip_flight.gd#test_the_first_coin_leaves_no_visible_gap"
        status: pass
    human_judgment: true
    rationale: "Whether the stream reads as one coin at a time and the acceleration feels right is a feel judgement; the end-of-phase human check asks the owner"
  - id: D2
    description: "The 3 s cap's fast-forward leaves staggered inside 0.3 s and at most 12 coins are drawn however large the remainder; all are freed"
    requirement: "BLDG-04"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_coin_drip_burst.gd#test_the_cap_rush_is_staggered_inside_the_burst_window"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_coin_drip_burst.gd#test_a_huge_rush_draws_only_the_visual_cap"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_coin_drip_burst.gd#test_every_burst_coin_is_freed_after_the_window_and_the_flight"
        status: pass
    human_judgment: true
    rationale: "Whether the rush reads as many coins in a real window is a visual feel call; scripted captures were taken (see measurements) but the owner judges"
  - id: D3
    description: "A normal drip still launches immediately and the refund flies the dripped coins back staggered with the same visual cap"
    requirement: "BLDG-04"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_coin_drip_burst.gd#test_a_normal_drip_launches_immediately"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_coin_drip.gd#test_early_release_flies_the_coins_back_and_restores_the_hud"
        status: pass
    human_judgment: false
  - id: D4
    description: "The coin flight ceiling is derived from LoopTuning.COIN_DRIP_INTERVAL_MAX_S (review IN-02 closed)"
    verification:
      - kind: unit
        ref: "tests/unit/test_coin_drip_flight.gd#test_the_ceiling_is_derived_from_the_d05_bound"
        status: pass
    human_judgment: false
  - id: D5
    description: "build_in_progress screenshot is timed from the curve and still shows a tower hold with two coins paid and the second mid-flight"
    requirement: "DEV-04"
    verification:
      - kind: other
        ref: "bash tools/screenshot.sh build_in_progress (Gold 28, two of four label coins filled, a coin near the king)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The owner can launch a hold-pacing sandbox with House tiers of 15, 30 and 50 coins and feel the acceleration and the 3 s fast-forward"
    requirement: "DEV-04"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_hold_pacing_sandbox.gd"
        status: pass
    human_judgment: true
    rationale: "The pace, acceleration and 3 s rush are feel judgments; the human check below is the owner's UAT re-check of G-01-58"

duration: 15min
completed: 2026-10-02
status: complete
---

# Phase 1 Plan 15: Coin Stream Follows the Accelerating Hold Summary

**The build coin stream now flies each coin for 90% of the gap to the next one (0.12 s floor, ceiling derived from D-05's bound), the 3 s cap's fast-forward shows as a staggered rush capped at 12 coins, and a real-window sandbox with 15/30/50-coin House tiers lets the owner feel it.**

## Performance

- **Duration:** 15 min
- **Completed:** 2026-10-02
- **Tasks:** 2 (Task 1 tracer with TDD, Task 2 auto)
- **Files:** 11 (9 created, 2 modified, excluding this SUMMARY)

## Accomplishments

- `CoinDripVfx` takes each coin's flight from `LoopTuning.coin_interval(coins_paid + 1)` via the pure `flight_seconds_for`, so the stream speeds up with the hold and every shipped build (costs up to 6) still lands each coin before the next leaves.
- Coins paid in one process frame form one group: staggered by `launch_stagger` (at most 0.04 s apart, whole group inside 0.3 s) and drawn up to `MAX_BURST_COINS` (12). The cap's fast-forward therefore reads as a quick rush of coins instead of one blurred coin, and a 36-coin rush draws exactly 12 (T-01-25). The refund uses the same stagger and cap.
- The flight ceiling is `FLIGHT_FRACTION_OF_INTERVAL x LoopTuning.COIN_DRIP_INTERVAL_MAX_S`, so there is no standalone flight number any more.
- `build_in_progress` waits `coin_due_seconds(2) + 0.5 x coin_interval(3)` and needs a live hold; the screenshot shows Gold 28, two of the label's four coins filled and a coin by the king.
- `tools/sandbox/hold_pacing_sandbox.tscn` starts the prototype map with House tiers of 15, 30 and 50 coins on a deep copy and 105 starting gold; the shipped `house.tres` is untouched and `tools/*` is excluded from the export.

Review IN-02 closed by Task 1 (flight ceiling derived from LoopTuning.COIN_DRIP_INTERVAL_MAX_S)

## Design Defaults (all shipped unchanged)

| Choice | Default | Changed? |
|--------|---------|----------|
| Flight per coin | `clampf(0.9 x gap to the next coin, 0.12, ceiling)` | No |
| Flight ceiling | 0.9 x `LoopTuning.COIN_DRIP_INTERVAL_MAX_S` (0.27 s) | No (constant expression compiled, no `max_flight_seconds()` fallback needed) |
| Same-frame stagger | `launch_stagger(n) = clampf(0.3 / (n - 1), 0, 0.04)` | No |
| Visual cap per group | 12 coins | No |
| Sandbox House costs | 15 / 30 / 50, gold 105 | No |

## Scripted Real-Window Self-Check (Task 2 step 5)

Scratch script (kept in the session scratchpad, not committed) loaded the sandbox scene in a real 1280x720 window (Vulkan, Forward+, RTX 3060 Laptop), teleported the king beside house_1 (1.0 m east, 2.0 m south so the model does not hide the coins), and held `action_build` for each tier in turn.

| Tier | Cost | Hold-clock completion | Wall clock | Coins paid in the completion frame |
|------|------|----------------------|------------|-----------------------------------|
| House I | 15 | 2.210 s (2.209 s in the first run) | 2.21 s | 1 (pure drip) |
| House II | 30 | 3.002 s (3.0018 s in the first run) | 3.01 s | 6 (rush) |
| House III | 50 | 3.000 s (3.0035 s in the first run) | 3.00 s | 26 (rush) |

Expected about 2.205 / 3.0 / 3.0 s; the 15-coin hold is 2.21 s on the hold clock, within a frame of the curve's 2.205 s. Gold went 100 to 5 (15 + 30 + 50 debited once each).

Burst delays recorded by `get_last_burst_delays()`:

- 30-coin hold: `[0.0, 0.04, 0.08, 0.12, 0.16, 0.20]` (6 coins, 0.04 s apart).
- 50-coin hold: 12 delays from 0.0 to 0.3 s in 0.0273 s steps (26 coins due, 12 drawn).

Captures (viewport PNGs of the 30-coin hold):

- About 2.85 s into the hold (`tier2_pre_cap`): a single drip coin at the top of the plot, label coin row about three quarters filled.
- Frame of completion (`tier2_post_cap_f0`): no coins visible yet. The six rushed coins are spawned stacked at the king's anchor and the king model hides them until each one's turn.
- Two frames later (`tier2_post_cap_f2`): the rush is under way, with separate coins visible at different points along the king-to-plot line above the new House III, others still stacked at the king. 6 live coins right after completion, 5 a few frames later, 0 after the window plus flight.
- At the king's original 0.5 m offset the House model occludes the coins, so the angled camera hides part of the stream there. That is a camera and model-size effect, not a stream problem, and is why the offset was changed for the capture.

Note: the PNGs show several coins in staggered flight rather than one, but whether the rush reads well is left to the owner's feel check.

## Task Commits

1. **Task 1 (tracer): coins follow the accelerating gaps, cap rush staggered and capped**
   - RED: `0fc1ba7` (test) - `test_coin_drip_flight.gd` and `test_coin_drip_burst.gd` fail to load: `CoinDripVfx` has none of the new members (parse error, accepted as red by the plan)
   - GREEN: `fd80b83` (feat) - tracer `<verify>` re-run end to end (351/351 tests, JUnit entries present, lint clean) and passed before expansion
2. **Task 2: curve-timed screenshot, hold-pacing sandbox, scripted real-window check**
   - `5f9a319` (feat) - 354/354 tests, lint clean, screenshot saved

**Plan metadata:** committed separately (docs: complete plan).

## Files Created/Modified

- `presentation/vfx/coin_drip_vfx.gd` - per-coin flight, same-frame groups, visual cap, derived ceiling, `get_last_burst_delays`
- `tests/unit/test_coin_drip_flight.gd` (+ `.uid`) - flight and stagger math, one coin at a time on shipped costs, derived ceiling
- `tests/e2e/test_coin_drip_burst.gd` (+ `.uid`) - real-scene staggered, capped, freed cap rush; normal drip at delay 0
- `tools/screenshot/shot_scenarios.gd` - `SHOT_COINS_PAID`, `MID_GAP_FRACTION`, curve-timed wait
- `tools/sandbox/hold_pacing_sandbox.gd` (+ `.uid`, `.tscn`) - the sandbox
- `tests/e2e/test_hold_pacing_sandbox.gd` (+ `.uid`) - sandbox smoke test

## Decisions Made

- The group stagger uses the coins that can still arrive this frame, so no timer or frame hitch special case is needed: any same-frame pair is staggered like the cap rush.
- Rush coins spawn at once with a tween delay (the refund's existing pattern); no hide-until-launch step.
- The sandbox repeats the five-line deep-copy repricing instead of calling `E2eSupport`, because tools code must not depend on `tests/`.

## Deviations from Plan

None - plan executed exactly as written. (`MAX_FLIGHT_SECONDS` as a cross-class constant expression compiled, so the `max_flight_seconds()` fallback was not needed. The 36-coin case in T-01-25 is covered by the 60-coin test, which pays 36 rushed coins and draws 12.)

### TDD Gate Compliance

RED (`test(01-15)` `0fc1ba7`) precedes GREEN (`feat(01-15)` `fd80b83`). The RED run was a parse error on the missing `CoinDripVfx` members, which the plan explicitly allows to count as red. No refactor commit was needed. Task 2 is auto, with its tests added alongside the sandbox.

## Issues Encountered

None. Full suite 354/354 green (was 338 after plan 01-14); `bash tools/lint.sh` clean. No Godot process left running.

## Known Stubs

None.

## Threat Flags

None. T-01-25 (unbounded coin nodes) is mitigated by `MAX_BURST_COINS` and `BURST_WINDOW_SECONDS` and covered by `test_coin_drip_burst.gd`. T-01-26 (sandbox repricing shipped data) is mitigated by the `DEEP_DUPLICATE_ALL` copy and covered by `test_hold_pacing_sandbox.gd`; `tools/*` stays in the export `exclude_filter`.

## Human Check (end of phase, for the owner; verbatim from the plan)

End of phase, for the owner (UAT re-check of G-01-58). (1) Normal game: from Git Bash in the repo root run `bash tools/godot.sh --path .` (or press F5 in the editor). Hold Space or gamepad A at a House plot for House I, II and III, and at a tower plot. Expected: the first coin leaves after 0.25 s and the coins then come visibly faster. House I takes about 0.5 s, House III about 1.1 s and a tower about 0.9 s, and the stream still reads as one coin at a time. (2) Sandbox: run `bash tools/godot.sh --path . res://tools/sandbox/hold_pacing_sandbox.tscn`. House plots cost 15, 30 and 50 coins per tier, and you start with enough gold for all three. Hold at one House plot three times. Expected: the 15-coin build takes about 2.2 s with a clearly accelerating stream. The 30-coin build stops at 3.0 s with its last 6 coins rushing in at once, and the 50-coin build also stops at 3.0 s with about half its coins rushed in. Releasing just before 3 s flies the coins back and builds nothing. Judge whether the 0.25 s start, the acceleration and the 3 s rush feel right. (The label's coin-icon row is very wide at these synthetic costs. The label layout for expensive buildings belongs to the later phase that adds them and is not part of this check.)

## Next Phase Readiness

Ready for 01-16: it still owns the slow-drip test overrides (`_tuning_with_interval`, the `coin_drip_interval` overrides in `test_coin_drip.gd`, `test_spot_label.gd`, `test_start_night_hold.gd`) and the SECURITY/VALIDATION refresh (T-01-22 text, new T-01-23 to T-01-26 rows). The owner's feel check of the pace and rush is queued for the verifier.

## Self-Check: PASSED

- Created files exist on disk: the two test files and `.uid`s, the sandbox script, `.uid` and scene, the sandbox test and `.uid`.
- Commits present: `0fc1ba7`, `fd80b83`, `5f9a319`; `git rev-list --count bde91c9..HEAD` = 3.
- Acceptance greps passed (`LoopTuning.COIN_DRIP_INTERVAL_MAX_S`, `func flight_seconds_for(`, `func launch_stagger(`, `MAX_BURST_COINS`, `get_process_frames`, `func get_last_burst_delays(`, `SHOT_COINS_PAID`, `coin_due_seconds`, `DEEP_DUPLICATE_ALL`, `SANDBOX_HOUSE_COSTS`); JUnit XML lists test_coin_drip_flight, test_coin_drip_burst, test_coin_drip and test_hold_pacing_sandbox; `git log` shows `test(01-15)` before `feat(01-15)`.
- `.planning/config.json` never staged.
