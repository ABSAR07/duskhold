---
status: diagnosed
trigger: "UAT G-01-58: this is better. However, I think we should start with 0.25s per coin, and accelerate (since there will be buildings at some point that require e.g. 15 coins or even more). And set a max time limit too so for example set 3 seconds as the maximum time it takes, even if only half the coins are filled, just fast forward to full coin usage if that is possible given the current coins."
created: 2026-10-02T11:00:00Z
updated: 2026-10-02T11:35:00Z
goal: find_root_cause_only
---

## Current Focus

bug_class: Bohrbug (deterministic design gap: a constant-interval model, reproduced exactly by a timed probe). Not a defect; a design change requested by the owner on working behaviour.
hypothesis: CONFIRMED. Hold pacing is a single constant interval per coin (duration = cost x coin_drip_interval, 0.3 s) with no acceleration and no total cap; the controller loop, the coin VFX flight, the tuning contract, the timing e2e test, four derived test waits and the screenshot scenario all assume a constant interval
test: done (code read of every consumer, headless probe of the real scene, curve arithmetic, duplicate() isolation probe)
expecting: n/a
next_action: Return ROOT CAUSE FOUND to the orchestrator; the change goes to plan-phase --gaps

known_pattern_candidate: none (knowledge-base.md does not exist; related prior session build-hold-too-short.md, G-01-4)

reasoning_checkpoint:
  hypothesis: "Long builds will drag and no hold accelerates or caps because BuildHoldController._advance_hold pays one coin per constant coin_drip_interval (0.3 s) until cost is reached, so duration = cost x 0.3 s with no upper bound"
  confirming_evidence:
    - "build_hold_controller.gd:95-102: interval is one per-frame constant, one coin per interval, finish at coins_paid >= cost; no elapsed-hold clock, no index-dependent interval, no cap"
    - "Probe on the real scene: 2/3/5/4/30-coin holds completed at 0.614/0.911/1.511/1.217/9.014 s = cost x 0.3 s"
    - "loop_tuning.gd:5-7 has a single pacing field; coin_drip_vfx.gd:57-58 derives flight from that constant"
  falsification_test: "Any code path that shortens later coins or ends a hold before cost x interval (none found by grep or probe), or a measured 30-coin hold well under 9 s"
  fix_rationale: "Replacing the constant with a pure per-coin schedule (0.25 s start, geometric decay to a floor, min(T(cost), 3 s) cap with the remainder paid at the cap) changes exactly the quantity the owner asked to change, at the one site that computes it, and leaves D-06's all-or-nothing debit and refund untouched"
  blind_spots: "Owner's subjective feel of the proposed decay/floor is unverified (needs a windowed UAT re-check). The overlapping coin stream after coin 8 has not been seen in a window. No building in the game costs more than 6 yet, so the cap and fast-forward are exercised only by synthetic tests until Phase 5+ content"
  candidate_causes:
    - "code: constant-interval loop in BuildHoldController with no cap (confirmed)"
    - "data: a single coin_drip_interval field cannot express a curve or a cap (confirmed, contributing)"
    - "config/decision: D-05 locks 'steady rate', so the linear model was built as specified (confirmed, contributing)"
    - "environment: frame-rate dependent timing (eliminated by probe)"
  and_gate: "yes: the linear behaviour needs D-05's steady-rate decision AND a one-field data model AND a constant-interval loop; the fix must touch all three (amend D-05, add tuning fields, change the loop) plus the VFX and tests that assume a constant gap"

## Symptoms

expected: Hold at House I/II/III and tower plots; at 0.3 s per coin the hold feels deliberate without dragging; the coin stream reads as one coin at a time (UAT test 58)
actual: "this is better. However, I think we should start with 0.25s per coin, and accelerate (since there will be buildings at some point that require e.g. 15 coins or even more). And set a max time limit too so for example set 3 seconds as the maximum time it takes, even if only half the coins are filled, just fast forward to full coin usage if that is possible given the current coins."
errors: none
reproduction: UAT test 58 - run the game windowed, hold the action key at House/tower plots
started: UAT re-check after gap-closure plan 01-13 (coin_drip_interval 0.2 -> 0.3, MAX_FLIGHT_SECONDS 0.18 -> 0.27)

## Eliminated

- hypothesis: The hold is slower or faster than its model because of a timing bug (frame-rate dependence, timer not reset, double-counted delta)
  evidence: probe measured House I 0.614 / II 0.911 / III 1.511 / Tower I 1.217 / 30-coin 9.014 s, i.e. cost x 0.3 s within about 15 ms; _reset_hold zeroes the timer (build_hold_controller.gd:133-137)
  timestamp: 2026-10-02T11:20:00Z

- hypothesis: The HUD or spot label paces the count-up on its own clock and would also need a curve
  evidence: hud.gd:86-98 and spot_label.gd:156-167 only mirror coins_paid from hold_progress; neither reads the tuning or animates independently
  timestamp: 2026-10-02T11:09:00Z

- hypothesis: The fast-forward could be unaffordable in the current game, so it needs a partial-payment or "stop at what is affordable" branch
  evidence: a hold only starts when validate_build passes the full-cost CANNOT_AFFORD check (command_processor.gd:38, build_hold_controller.gd:78-81, D-06); the only runtime gold writers are the hold's own completion submit and the DAWN payout (run_manager.gd:117), which cannot run during a day hold; submit re-validates and a rejection already routes to hold_cancelled (full refund)
  timestamp: 2026-10-02T11:08:00Z

## Evidence

- timestamp: 2026-10-02T11:02:00Z
  checked: Knowledge base (Phase 0)
  found: .planning/debug/knowledge-base.md does not exist; MemPalace not used. Closest prior session is .planning/debug/build-hold-too-short.md (G-01-4, diagnosed, fixed by 01-13), which mapped the linear model and its consumers at 0.2 s.
  implication: no known-pattern shortcut; reuse the G-01-4 consumer map but re-verify it at the post-01-13 state.

- timestamp: 2026-10-02T11:05:00Z
  checked: input/build_hold_controller.gd (full, 137 lines)
  found: |
    The ONLY cadence site is _advance_hold (:91-102). :95 interval = maxf(_ctx.tuning.coin_drip_interval, MIN_DRIP_INTERVAL) is recomputed every frame but is the same value for every coin; :96 _drip_timer += delta; :97-100 while _drip_timer >= interval and _coins_paid < _cost: subtract interval, pay one coin, emit hold_progress; :101-102 finish when _coins_paid >= _cost. _try_start_hold (:77-86) zeroes _coins_paid and _drip_timer and fixes _cost at start. No notion of elapsed hold time, coin index-dependent interval, or total cap exists. _finish_hold (:114-122) submits ONE BuildIntent; a CommandProcessor rejection there is reported as hold_cancelled(spot, coins) (refund path).
  implication: hold duration = cost x coin_drip_interval exactly (0.3 s now). Acceleration and a cap both need code here; data alone cannot express them.

- timestamp: 2026-10-02T11:06:00Z
  checked: presentation/vfx/coin_drip_vfx.gd:13-18, 57-58, 81-91; simulation/defs/loop_tuning.gd:5-7; data/tuning/loop_tuning.tres:7
  found: |
    VFX flight = minf(MAX_FLIGHT_SECONDS 0.27, coin_drip_interval x FLIGHT_FRACTION_OF_INTERVAL 0.9) (:57-58). It reads the CONSTANT interval, not the gap to the next coin, and spawns one coin per hold_progress with delay 0 (:81-83). Refund coins are staggered by REFUND_STAGGER_SECONDS 0.04 (:87-91). LoopTuning has one pacing field, coin_drip_interval = 0.3 (script default and .tres), documented as "Top of D-05's 0.15-0.3 s range".
  implication: with a shrinking interval the flight (0.27 s) would outlast later gaps, so several coins would be airborne at once (the stream stops reading one-at-a-time). A fast-forward burst of N hold_progress signals in one frame would spawn N coins at the same point with the same tween, overlapping into what looks like one coin. The VFX needs a per-coin flight time (from the actual gap) and a stagger for bursts.

- timestamp: 2026-10-02T11:08:00Z
  checked: simulation/commands/command_processor.gd:30-68, simulation/economy/economy.gd:23-36, grep of try_spend/grant/BuildIntent.new in runtime code
  found: |
    validate_build (:30-40) checks NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD(full cost). _try_start_hold only starts a hold when validate_build == OK, so a hold can never start with gold < full cost (D-06 "Starting the hold requires the full cost"). Gold is debited exactly once, at completion, by _submit_build -> Economy.try_spend(full cost) (:62); nothing is debited per coin. Runtime writers of gold: try_spend only via CommandProcessor._submit_build, whose only runtime caller is BuildHoldController._finish_hold (:117); grant only via RunManager._apply_dawn_payout (run_manager.gd:117), which runs at DAWN when is_build_allowed() is false and any hold has already been cancelled. Only one hold can be active at a time.
  implication: in the current game gold cannot change during a hold, so "fast forward if current gold covers the remainder" is ALWAYS true. The remainder of the HUD-displayed gold is never the constraint either: the HUD shows gold - coins_paid, and remaining coins = cost - coins_paid <= that. If a future phase ever lets gold drop mid-hold, the existing completion gate already handles it: submit returns CANNOT_AFFORD and the controller emits hold_cancelled (full refund, D-06 all-or-nothing). No new affordability branch is needed; partial "stop at what is affordable" would contradict D-06 (no partially-paid state).

- timestamp: 2026-10-02T11:09:00Z
  checked: ui/hud/hud.gd:60-62, 86-98, 213; ui/world/spot_label.gd:49-52, 156-167; ui/world/spot_label_model.gd:37-39
  found: HUD sets _pending = coins_paid on each hold_progress and 0 on cancel/complete; spot label fills coin icons from coins_paid (clamped to cost). Neither reads coin_drip_interval or animates on its own clock.
  implication: both are cadence-agnostic and already handle a multi-coin jump correctly (a fast-forward that emits hold_progress for each remaining coin, or one with coins_paid = cost, just fills the rest). No change needed there.

- timestamp: 2026-10-02T11:12:00Z
  checked: every reader of coin_drip_interval / MAX_FLIGHT_SECONDS / HOLD_INTERVALS outside .planning (grep)
  found: |
    Runtime: input/build_hold_controller.gd:95; presentation/vfx/coin_drip_vfx.gd:58.
    Tool: tools/screenshot/shot_scenarios.gd:18,87 (build_in_progress at tower_1, cost 4: waits HOLD_INTERVALS 2.5 x coin_drip_interval and returns get_coins_paid() > 0; implicitly also needs the hold NOT yet complete).
    Tests asserting the LINEAR model (will fail under any curve): tests/e2e/test_build_hold_timing.gd:51,63,74 (timeout and expected = cost x interval, EARLY_TOLERANCE 0.02 s; every gap == interval +-0.05 s); tests/unit/test_loop_tuning_contract.gd:50 (shortest hold = cheapest cost x interval >= MIN_HOLD_S 0.5), :58-67 (MAX_FLIGHT >= 0.9 x interval and < interval).
    Tests deriving a hold wait from cost x interval + slack (still pass under a decaying curve because the curve is never slower than linear, but semantically wrong): test_walking_skeleton.gd:33, test_upgrade_at_spot.gd:23, test_debug_overlay_toggle.gd:124, test_build_hold_refund.gd:125.
    Tests overriding coin_drip_interval to a slow value (inherit the shipped curve's other parameters via duplicate(true)): test_build_hold_refund.gd:10,30 (1.0), test_coin_drip.gd:11,29 (0.8, plus a literal 0.2 at :130), test_spot_label.gd:15,34 (1.0), test_start_night_hold.gd:10,252 (1.0).
    Fixed-timeout tests: test_build_hold_refund.gd:116 and :185-187 (WAIT_SLACK_S 3.0 for a live-tuning House I).
  implication: two tests and one contract encode the constant-interval assumption explicitly and must be rewritten against the new curve; the four cost x interval waits should switch to a shared duration helper; the slow-override tests need the curve to keep early coins slow (or the overrides must also neutralise decay/cap).

- timestamp: 2026-10-02T11:15:00Z
  checked: 01-CONTEXT.md D-05 (:66-69), D-06 (:70-73), D-09 (:83-84), Claude's Discretion (:125); 01-DISCUSSION-LOG.md:54; REQUIREMENTS.md BLDG-03 (:34), DEV-05 (:134); 01-SECURITY.md T-01-05 (:45), T-01-22 (:66)
  found: |
    D-05 locks "a steady rate (1 coin = 1 gold), so pricier builds take a little longer" and "completes when the last coin lands". D-06 locks "Starting the hold requires the full cost", full refund on early release, and "no partially-paid state ... all-or-nothing". D-09 says the drip rate lives in .tres data. Discretion: "roughly 0.15-0.3 s per coin is the starting point". T-01-22 records the 0.15-0.3 s bound and the 0.5 s minimum shortest hold as the mitigation for coin_drip_interval tampering. BLDG-03 only needs a visible hold-progress indicator. DEV-05 (seeded deterministic simulation) is Phase 2; the simulation clock today is MapRoot._process -> run_manager.tick (map_root.gd:28-29), and grep finds no Time.*/rand* in input/, simulation/, presentation/ (only the debug overlay FPS counter).
  implication: an accelerating drip with a total cap contradicts D-05's literal "steady rate" (needs an owner-sourced D-05 amendment recorded from this UAT), but keeps "pricier builds take a little longer" (monotone, up to the cap) and "completes when the last coin lands" (the fast-forward lands the rest). D-06 is untouched: the start gate and the all-or-nothing refund stay. 0.25 s is inside the documented 0.15-0.3 range. Determinism is preserved if the curve is a pure function of (tuning, coin index) driven by accumulated frame delta, as today; the simulation still sees exactly one BuildIntent per completed hold.

- timestamp: 2026-10-02T11:20:00Z
  checked: Scratch probe (scratchpad/measure_pacing.gd, outside the repo) run headless with the pinned console Godot against the real prototype_map.tscn, starting_gold 200, tower tier II cost set to 30 in memory, pressing action_build and stamping hold_progress / tier change
  found: |
    coin_drip_interval=0.300 flight=0.270
    House I  cost=2  COMPLETED 0.614 s (coins at 0.304 .. 0.607)
    House II cost=3  COMPLETED 0.911 s
    House III cost=5 COMPLETED 1.511 s
    Tower I  cost=4  COMPLETED 1.217 s
    Tower II cost=30 COMPLETED 9.014 s (30 coins, first 0.293, last 8.998)
    VFX live coin count at every spawn = 1 (one coin airborne at a time). Gold 200 -> 156 (= 200 - 44), debited once per completed hold. Process exited 0.
  implication: the shipped pacing is exactly linear (cost x 0.3 s) end to end; a 15-coin build would take 4.5 s and a 30-coin build 9 s, the "drag" the owner anticipates. Nothing shortens long holds today.

- timestamp: 2026-10-02T11:24:00Z
  checked: 01-REVIEW.md WR-01 (:66-90) and IN-02 (:124-132), 01-REVIEW-DISPOSITION.md (both "open"); ui/hud/dawn_payout_vfx.gd:23-28, 99-108 (launch_stagger / MAX_COINS)
  found: Open review warning WR-01 says test_build_hold_timing.gd stamps coins with wall-clock time and tight tolerances (EARLY 0.02 s, GAP 0.05 s), a latent flake on a frame hitch, and suggests asserting on accumulated delta. Open info IN-02 says MAX_FLIGHT_SECONDS is a redundant hand-edited second source of truth for the flight. DawnPayoutVfx already has a window-bounded stagger (launch_stagger = clamp(window / (n-1), 0, STAGGER_SECONDS)) and a MAX_COINS visual cap.
  implication: the gap-closure plan rewrites exactly the files these two open findings name, so it should close WR-01 and IN-02 in the same change; the fast-forward burst in CoinDripVfx can reuse the DawnPayoutVfx stagger pattern.

- timestamp: 2026-10-02T11:27:00Z
  checked: Scratch probe (scratchpad/dup_probe.gd): MapConfig.duplicate(true), then edit a tower tier cost, then read the cached res://data/buildings/tower.tres; repeat with duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
  found: "duplicate(true): cached tower tier II cost after edit = 30" (the edit leaked into the cached external resource). "duplicate_deep(ALL): cached tower tier I cost after edit = 4" (isolated).
  implication: a new e2e test for the 3 s cap that raises a tier cost in place (the pattern the existing tests use for starting_gold and spot positions) would mutate the shared tower.tres for every later test in the GUT process. It must use duplicate_deep(Resource.DEEP_DUPLICATE_ALL) or a fixture building .tres under tests/fixtures/.

- timestamp: 2026-10-02T11:30:00Z
  checked: Curve candidates computed in scratchpad/curve.py and curve2.py (pure arithmetic of the proposed model)
  found: |
    Recommended: first_interval 0.25, steady_coins 2, decay 0.90, min_interval 0.08, max_hold 3.0.
    interval_k = 0.25 for k <= 2, else max(0.08, 0.25 x 0.90^(k-2)); T(n) = sum of interval_1..n; hold(cost) = min(T(cost), 3.0).
    cost:  2     3     4     5     6     10    15    30                 (50)
    hold:  0.500 0.725 0.927 1.110 1.274 1.781 2.205 3.000 (24 paid, 6 fast-forwarded; natural 3.41)  (3.000: 24 paid, 26 fast-forwarded)
    linear 0.30 today: 0.60 0.90 1.20 1.50 1.80 3.00 4.50 9.00
    Variant without the steady pair (decay from coin 2, d 0.90): House I 0.475 s, which breaks the existing 0.5 s MIN_HOLD contract (G-01-4, T-01-22).
    Steeper variant (d 0.85): 0.500 0.713 0.893 1.047 1.177 1.543 1.943 3.000 (only 2 fast-forwarded at 30).
    VFX with flight_k = clamp(0.9 x interval_(k+1), 0.12, 0.27): every coin of costs 2-7 lands before the next leaves (one at a time); from coin 8 on, gaps fall under 0.133 s and the stream overlaps (at most 2 airborne at the 0.08 s floor).
  implication: the recommended curve satisfies all three owner points, keeps House I at exactly 0.5 s (existing contract), keeps every Phase 1 build one-coin-at-a-time, and makes the cap bite at about 25+ coins, where at 50 coins about half the coins are fast-forwarded, matching the owner's "even if only half the coins are filled".

## Resolution

root_cause: |
  Design gap, not a defect. Build-hold pacing is a single constant interval per coin, so hold time grows linearly with cost and has no upper bound:
  (1) code: BuildHoldController._advance_hold (input/build_hold_controller.gd:91-102) reads one per-frame constant interval = coin_drip_interval (:95), pays one coin each time _drip_timer passes it (:97-100) and finishes only at coins_paid >= cost (:101-102). There is no elapsed-hold clock, no coin-index-dependent interval and no cap. The while loop also reuses that one interval for every coin paid in a frame, so it cannot express a varying interval as written.
  (2) data: LoopTuning has one pacing field, coin_drip_interval = 0.3 (simulation/defs/loop_tuning.gd:5-7, data/tuning/loop_tuning.tres:7), which cannot express a start rate, decay, floor or cap.
  (3) decision: D-05 (01-CONTEXT.md:66-69) locks "a steady rate", so the linear model was built as specified.
  Measured on the real scene: 2/3/5/4-coin holds take 0.61/0.91/1.51/1.22 s, and a 30-coin tier takes 9.01 s (a 15-coin build would take 4.5 s). Downstream, the coin VFX flight (presentation/vfx/coin_drip_vfx.gd:13-17, 57-58), the tuning contract (tests/unit/test_loop_tuning_contract.gd:47-67), the timing e2e test (tests/e2e/test_build_hold_timing.gd:51-77), four cost x interval test waits and the screenshot wait (tools/screenshot/shot_scenarios.gd:18,87) all assume that constant interval.
  The affordability condition in the owner's request is always met today: a hold cannot start without the full cost (D-06; command_processor.gd:30-40), gold is debited once at completion, and no runtime path changes gold during a day hold.
suggested_fix_direction: |
  CURVE (satisfies all three owner points). For coin k (1-based):
    interval_k = first_interval                                          for k <= steady_coins
               = max(min_interval, first_interval x decay^(k - steady_coins))  otherwise
    T(n) = interval_1 + ... + interval_n;  coin n is due at min(T(n), max_hold_seconds)
    hold(cost) = min(T(cost), max_hold_seconds)
  Recommended values: first_interval 0.25, steady_coins 2, decay 0.90, min_interval 0.08, max_hold_seconds 3.0.
    cost   2     3     4     5     6     10    15    30
    hold   0.500 0.725 0.927 1.110 1.274 1.781 2.205 3.000 (24 coins drip, the last 6 are fast-forwarded at 3.0 s)
    today  0.60  0.90  1.20  1.50  1.80  3.00  4.50  9.00
  At 50 coins: 3.0 s, 24 dripped and 26 fast-forwarded (about half, as in the owner's example). The two steady coins keep House I at exactly 0.5 s (the existing G-01-4 / T-01-22 minimum) and keep the opening of every hold one coin at a time. Without them (decay from coin 2), House I is 0.475 s and breaks that contract. A steeper decay of 0.85 gives 0.500/0.713/0.893/1.047/1.177/1.543/1.943/3.0.

  DATA vs CODE. Data (LoopTuning script defaults + loop_tuning.tres, D-09): coin_drip_interval (keep the name as "the first and steady interval" = 0.25 so the 4 slow-override tests still compile; renaming is optional churn), coin_drip_steady_coins 2, coin_drip_decay 0.90, coin_drip_min_interval 0.08, max_build_hold_seconds 3.0. Add pure helpers on LoopTuning (the same pattern as BuildingDef.tier_def/max_tier): coin_interval(k), coin_due_seconds(n) and build_hold_seconds(cost). Code: the controller loop, the VFX flight and stagger constants.

  CONTROLLER (input/build_hold_controller.gd). Replace _drip_timer with an accumulated _hold_elapsed (+= delta; no Time.*, so it stays deterministic for a given delta sequence). Then:
    while _coins_paid < _cost and _hold_elapsed >= tuning.coin_due_seconds(_coins_paid + 1): pay one coin and emit hold_progress
  Because the due time is clamped to the cap, fast-forward needs no separate branch: every coin with T(n) >= cap becomes due at the cap, so all of them pay in one frame and _finish_hold submits the single BuildIntent. Keep the release/range/day check ahead of the drip (:92), so a release on the cap frame still refunds, and keep _reset_hold zeroing the new clock. Keep a positive-value guard (like MIN_DRIP_INTERVAL); max_build_hold_seconds <= 0 can mean "no cap".
  Affordability: no new check is needed. If a future phase ever lets gold fall mid-hold, the completion submit already returns CANNOT_AFFORD and the controller emits hold_cancelled with a full refund. Do NOT add a partial "stop at what is affordable" path: D-06 forbids a partially paid state.

  VFX (presentation/vfx/coin_drip_vfx.gd). Derive each coin's flight from the actual next gap: flight = clamp(0.9 x tuning.coin_interval(coins_paid + 1), MIN_FLIGHT about 0.12, MAX_FLIGHT about 0.27). Then costs 2-7 stay strictly one coin at a time (as now), and from about coin 8 the stream speeds up and overlaps slightly (at most 2 coins in the air at the 0.08 s floor). This also closes open review IN-02 (the redundant hand-edited MAX_FLIGHT literal). For coins emitted in the same frame (fast-forward or a frame hitch), stagger the launches with a window-bounded stagger like DawnPayoutVfx.launch_stagger (ui/hud/dawn_payout_vfx.gd:99-108). The VFX knows cost and coins_paid from the signal, so it can size the stagger to the remaining coins, and it can cap the number of visual coins (like MAX_COINS). Without this, a burst spawns N coins at the same point on identical tweens and reads as one coin. HUD and spot label need no change: they mirror coins_paid.

  TESTS AND TOOLS.
    - tests/unit/test_loop_tuning_contract.gd: keep the first interval inside 0.15-0.3; compare script defaults with the .tres for every new field; compute the shortest hold with build_hold_seconds(cheapest) >= 0.5. Add: intervals are non-increasing and >= the floor, hold is non-decreasing in cost and <= the cap, hold == cap whenever T(cost) > cap, and the first gap keeps one coin at a time. This replaces the MAX_FLIGHT contract at :58-67.
    - tests/e2e/test_build_hold_timing.gd: derive the expectations from build_hold_seconds and coin_due_seconds instead of cost x interval and equal gaps. Measure accumulated process delta, which closes open review WR-01 (wall-clock stamps with tight tolerances). Add an expensive synthetic tier (for example 30 coins) that must complete at about 3.0 s with exactly cost hold_progress emissions and one cost-sized debit, plus a release just before the cap that refunds everything. Build that map with duplicate_deep(Resource.DEEP_DUPLICATE_ALL) or a tests/fixtures building .tres. Plain duplicate(true) leaks the tier edit into the cached tower.tres (probe-verified).
    - Replace cost x coin_drip_interval with tuning.build_hold_seconds(cost) + slack in test_walking_skeleton.gd:33, test_upgrade_at_spot.gd:23, test_debug_overlay_toggle.gd:124 and test_build_hold_refund.gd:125. These still pass under the curve because it is never slower than linear, but they describe the old model.
    - The slow-override tests (test_build_hold_refund.gd:10/30, test_coin_drip.gd:11/29 plus the literal 0.2 at :130, test_spot_label.gd:15/34, test_start_night_hold.gd:10/252) inherit decay and cap through duplicate(true). They still pass with steady_coins 2: test_coin_drip's third coin lands at 2.32 s, after its 1.6 + 0.4 s check, and the cap is never reached. A shared helper that sets a flat slow pace (decay 1.0, no cap) would make them independent of the shipped curve.
    - tools/screenshot/shot_scenarios.gd:18,87: wait a fraction of build_hold_seconds(cost) (or until 2 coins are paid) instead of 2.5 x coin_drip_interval. The current formula still catches 2 of 4 coins at 0.625 s, but its meaning no longer holds.
  DOCS: record the owner's UAT G-01-58 decision as an amendment of D-05 ("steady rate" becomes "starts at 0.25 s per coin, accelerates, capped at 3 s with the rest paid at once") in 01-CONTEXT.md, and update the T-01-22 mitigation text (01-SECURITY.md:66), the 01-VALIDATION rows and the doc comments in loop_tuning.gd and coin_drip_vfx.gd. Re-check in a window (UAT): the feel of the decay and floor, and the overlapping stream on a synthetic 15/30-coin tier.
fix: (diagnose only, not applied)
verification: (not applicable, diagnose only)
files_changed: []
