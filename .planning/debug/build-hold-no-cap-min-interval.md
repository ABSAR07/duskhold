---
status: diagnosed
trigger: "UAT G-01-59 (test 59): yeah so i think dont keep 3 seconds as a hard limit, instead I think just keep 0.05s as the minimum time it takes for the coin to load after acceleration"
created: 2026-10-02T18:36:23Z
updated: 2026-10-02T18:53:30Z
goal: find_root_cause_only
---

## Current Focus

bug_class: Bohrbug-shaped design change (deterministic; the shipped data encodes a 3 s cap and a 0.08 s floor the owner now rejects). Not a defect.
hypothesis: CONFIRMED. The cap and the floor are shipped DATA (max_build_hold_seconds 3.0 and coin_drip_min_interval 0.08 in simulation/defs/loop_tuning.gd:27,30 and data/tuning/loop_tuning.tres:10-11); "no cap" is already expressible as max_build_hold_seconds <= 0. Setting cap 0 / floor 0.05 alone produces the owner's behaviour and breaks exactly 11 cap/floor-encoding tests in 5 suites; the rest is doc/record drift.
test: done (code read, curve + frame-quantization probe on the real helpers, model-height probe, differential full GUT run with the owner data in memory vs control)
expecting: n/a
next_action: Return ROOT CAUSE FOUND to the orchestrator; the change goes to plan-phase --gaps

known_pattern_candidate: none (knowledge-base.md absent); direct predecessor .planning/debug/build-hold-pacing-curve.md (G-01-58)

reasoning_checkpoint:
  hypothesis: "Every hold of 25+ coins ends in a 3 s rush and the post-acceleration stream never goes faster than 0.08 s per coin because the shipped LoopTuning data sets max_build_hold_seconds = 3.0 (coin_due_seconds clamps every due time to it) and coin_drip_min_interval = 0.08 (coin_interval's floor); both are what plans 01-14..01-16 shipped for the owner's G-01-58 request, which the owner has now revised"
  confirming_evidence:
    - "loop_tuning.gd:27,30 and loop_tuning.tres:10-11 hold 0.08 and 3.0; coin_due_seconds :62-67 clamps to the cap, coin_interval :51-52 applies the floor"
    - "Probe on the real helpers: shipped 30/50-coin holds = 3.000 s with 6/26 coins rushed; owner data 30 -> 2.937 s, 50 -> 3.937 s with every coin dripped; costs 2-12 identical"
    - "Differential GUT: control 358/358; owner data in memory 347/358, the 11 failures all in test_loop_tuning_contract, test_build_hold_cap, test_coin_drip_burst, test_hold_pacing_sandbox, test_e2e_support_tuning"
  falsification_test: "A runtime path that reads the cap or floor outside LoopTuning's helpers (none by grep), or a non-cap test failing under the owner data (none in the differential run), would show code changes are needed beyond data, tests and docs"
  fix_rationale: "Changing the two shipped values (script defaults + .tres) changes exactly the quantities the owner named, at their single source (D-09); the tests and records that pin the old values must follow so the suite pins the new decision instead of the old one"
  blind_spots: "Owner's reading of '0.05 s minimum time for the coin to load' is taken as the interval floor (the only pacing knob); if the owner meant the VISIBLE flight time, MIN_FLIGHT_SECONDS 0.12 would also have to change - the re-check should confirm. Feel of up to 3 coins airborne at the floor and of the 30 Hz 33/67 ms cadence is unobserved in a window. No hold-length upper bound remains (100 coins = 6.4 s); owner accepts this implicitly but has not seen a 50+ coin hold uncapped"
  candidate_causes:
    - "data: max_build_hold_seconds 3.0 and coin_drip_min_interval 0.08 in loop_tuning.tres + script defaults (confirmed, primary)"
    - "decision/config: D-05 as amended for G-01-58 locks a 3 s cap and a 0.08 s floor, and the tests, SECURITY and VALIDATION records pin that decision (confirmed, contributing)"
    - "code: controller or VFX hard-wired to the cap (eliminated: neither reads it; no-cap branch already exists)"
    - "environment: frame-rate dependent timing (eliminated: hold clock is accumulated delta; quantized model overshoots by at most one frame)"
  and_gate: "yes, for the change rather than the behaviour: the shipped behaviour comes from the data alone, but the owner's change cannot land green without also amending the decision record (D-05) and the 11 tests/5 suites that pin the old values; the fix must touch data + script defaults + tests + records together"

## Symptoms

expected: (UAT 59) first coin after 0.25 s then faster; House I ~0.5 s, House III ~1.1 s, tower ~0.9 s; sandbox 15-coin ~2.2 s, 30 and 50-coin stop at the 3.0 s cap with remaining coins rushed in
actual: owner verbatim (DATA): "yeah so i think dont keep 3 seconds as a hard limit, instead I think just keep 0.05s as the minimum time it takes for the coin to load after acceleration"
errors: none
reproduction: UAT test 59 in .planning/phases/01-foundation-day-loop/01-UAT.md (normal game + res://tools/sandbox/hold_pacing_sandbox.tscn)
started: discovered 2026-10-02 right after gap closure plans 01-14..01-16 shipped the accelerating hold with a 3 s cap
orchestrator_measurement: real window, Forward+, 144 Hz - first coin 0.25 s; House I/II/III 0.50/0.73/1.11 s; Tower I/II 0.93/1.28 s; sandbox 15 = 2.21 s, 30 = 3.01 s (24 dripped + 6 rushed), 50 = 3.01 s (24 + 26 rushed); release at 2.90 s refunded 23 coins; rush coins invisible in stills (launch inside king, fly 0.12 s to spot + 3.0 m, inside a built House roof 3.14 m)

## Eliminated

- hypothesis: Removing the cap needs new controller or VFX code (a no-cap branch, or a different payment loop)
  evidence: loop_tuning.gd:62 already treats max_build_hold_seconds <= 0 as no cap; the controller (build_hold_controller.gd:102-111) and the VFX (coin_drip_vfx.gd:114-140) never read the cap; E2eSupport.flat_drip_tuning (e2e_support.gd:44) and test_loop_tuning_curve.gd:88-97 already run uncapped holds; the differential GUT run with cap 0 / floor 0.05 in memory left every runtime, visual and flow test green (347/358, failures only in cap-encoding suites)
  timestamp: 2026-10-02T18:50:30Z

- hypothesis: test_build_hold_timing.gd encodes the 3 s cap (30-coin at about 3.0 s, release just before the cap)
  evidence: test_build_hold_timing.gd only times House I and Tower I against build_hold_seconds / coin_due_seconds and passed unchanged under the owner data; the 30-coin cap, same-frame fast-forward and release-before-cap tests are in tests/e2e/test_build_hold_cap.gd
  timestamp: 2026-10-02T18:50:30Z

- hypothesis: Without the cap the same-frame burst stagger and MAX_BURST_COINS (T-01-25) become dead code
  evidence: the refund path (coin_drip_vfx.gd:133-140) still flies up to cost coins back (a late release on a 50-coin hold refunds ~49, drawn as 12), and the frame-quantized probe shows pairs of coins in one frame at 15 fps (3 such frames at cost 30, 8 at cost 50) and on any frame hitch longer than 0.05 s
  timestamp: 2026-10-02T18:50:30Z

- hypothesis: A 0.05 s floor conflicts with D-05's documented 0.15-0.3 s range or with the 0.5 s minimum hold
  evidence: COIN_DRIP_INTERVAL_MIN_S/MAX_S bound only the first interval (test_loop_tuning_contract.gd:42-49); coin_interval clamps the floor to [MIN_INTERVAL_S 0.001, first] (loop_tuning.gd:51), so 0.05 is used as-is; the floor only applies from coin 18, and House I stays 0.500 s (probe)
  timestamp: 2026-10-02T18:50:30Z

- hypothesis: The build_in_progress screenshot scenario depends on the cap or floor
  evidence: tools/screenshot/shot_scenarios.gd:86-97 waits coin_due_seconds(2) + 0.5 x coin_interval(3) at tower_1 (cost 4) = 0.6125 s, identical under both curves (intervals identical through coin 12)
  timestamp: 2026-10-02T18:50:30Z

## Evidence

- timestamp: 2026-10-02T18:37:00Z
  checked: Knowledge base (Phase 0)
  found: .planning/debug/knowledge-base.md does not exist (MemPalace not used; logged fallback). The direct predecessor is .planning/debug/build-hold-pacing-curve.md (G-01-58, diagnosed), which designed the current curve (0.25 s, 2 steady, x0.9, 0.08 s floor, 3.0 s cap) and its consumer map.
  implication: no known-pattern shortcut; reuse the G-01-58 consumer map but re-verify it against what 01-14..01-16 actually built.

- timestamp: 2026-10-02T18:38:00Z
  checked: simulation/defs/loop_tuning.gd (76 lines) and data/tuning/loop_tuning.tres (15 lines)
  found: |
    Floor and cap are data. loop_tuning.gd:27 `coin_drip_min_interval: float = 0.08`, :30 `max_build_hold_seconds: float = 3.0` (doc :28-29 "0 or less means no cap"); .tres:10 `coin_drip_min_interval = 0.08`, :11 `max_build_hold_seconds = 3.0`.
    coin_interval (:45-52) clamps the floor to [MIN_INTERVAL_S 0.001, first], so 0.05 is accepted as-is.
    coin_due_seconds (:59-68): `capped = max_build_hold_seconds > 0.0`; running sum of coin_interval(1..n); early return of the cap once total >= cap. With cap <= 0 the loop runs all n coins (O(n) per call). Doc :55-58 says "a call costs at most about cap / floor iterations instead of the coin count" - this bound only holds when capped.
    Header doc :5-8 and field docs :18-30 describe the 3 s cap and the rush.
  implication: the owner's change is expressible in data alone (max_build_hold_seconds = 0.0, coin_drip_min_interval = 0.05): no runtime code change is needed for the behaviour. The no-cap branch already exists and is exercised by flat_drip_tuning (01-16) and test_loop_tuning_curve.gd:88-97. Script defaults must change with the .tres (contract test_script_defaults_match_the_shipped_pacing_data).

- timestamp: 2026-10-02T18:39:00Z
  checked: input/build_hold_controller.gd (146 lines)
  found: |
    _advance_hold (:102-111): release/range/day check first (:103-105), `_hold_elapsed += delta` (:106), then `while _coins_paid < _cost and _hold_elapsed >= tuning.coin_due_seconds(_coins_paid + 1)` pays coins (:107-109), finish at coins_paid >= cost (:110-111). No reference to max_build_hold_seconds or the floor; the cap only enters through coin_due_seconds. Doc :3-5 and :96-101 describe the 3 s cap and cap-frame fast-forward.
  implication: removing the cap needs no controller code change. Per-frame cost with no cap: the while condition calls coin_due_seconds(k) at least once per frame, each O(k) coin_interval calls (one pow each), so per-frame work is O(coins_paid) and the hold total is O(cost x frames). Only the doc comments go stale.

- timestamp: 2026-10-02T18:39:30Z
  checked: presentation/vfx/coin_drip_vfx.gd (140 lines)
  found: |
    flight_seconds_for(gap) = clampf(0.9 x gap, MIN_FLIGHT_SECONDS 0.12, MAX_FLIGHT_SECONDS 0.27) (:43-44); per-coin flight from tuning.coin_interval(coins_paid + 1) (:128). Same-frame group stagger (:114-125) via Engine.get_process_frames(); group stagger = launch_stagger(mini(cost - coins_paid + 1, MAX_BURST_COINS 12)); BURST_WINDOW_SECONDS 0.3, STAGGER_SECONDS 0.04 (:25-30). Refund path (:133-140) uses the same stagger and visual cap. Doc :3-9 describes "the 3 s cap pays the remaining coins in one frame". VFX never reads max_build_hold_seconds or the floor directly.
  implication: the VFX needs no code change for the owner's request. The burst/stagger and MAX_BURST_COINS still matter without the cap: they serve the refund (up to cost coins flying back) and any same-frame group from a frame hitch or a frame longer than the 0.05 s floor (below 20 fps every frame can carry 2+ coins). Only the "cap rush" wording goes stale.

- timestamp: 2026-10-02T18:40:00Z
  checked: 01-14/01-15/01-16 SUMMARY files; 01-SECURITY.md T-01-22..T-01-26 (:66-70, :599-611); 01-VALIDATION.md (:155-164, :178-179); 01-CONTEXT.md D-05 (:66-70) and Discretion (:126)
  found: |
    01-14 shipped the helpers, the clock-based controller, test_build_hold_cap.gd (6 tests), test_loop_tuning_curve.gd (14), rewrote test_loop_tuning_contract.gd (6). 01-15 shipped per-coin flight, same-frame burst stagger, test_coin_drip_flight.gd (9), test_coin_drip_burst.gd (4), the sandbox and its test (3). 01-16 shipped E2eSupport.flat_drip_tuning (decay 1.0, cap 0.0) and test_e2e_support_tuning.gd (4) plus the SECURITY/VALIDATION refresh.
    SECURITY: T-01-22 (:66) "requires a cap of at most 3 s"; T-01-23 (:67) lists max_build_hold_seconds and "the 3 s cap ... no instant or endless hold" (endlessness is actually prevented by MIN_INTERVAL_S + finite cost, not by the cap); T-01-24 (:68) is about the cap fast-forward (evidence test_build_hold_cap.gd); T-01-25 (:69) burst cap (cap rush, refund); :599-611 audit narrative "3 s-capped build hold", "0.25 s, 2, 0.9, 0.08 s and 3.0 s", "requires a cap of at most 3 s".
    VALIDATION: rows 01-14-T1 (:157, "completes at the 3 s cap"), 01-14-T2 (:158, "a cap of at most 3 s"), 01-15-T1 (:160 "the cap rush is staggered"), 01-16-T1 (:162 "flat, uncapped"), BLDG-04 coverage (:179 "ends at the 3 s cap").
    CONTEXT: D-05 amendment (:70) "never lasts longer than 3 s ... never under 0.08 s, capped at 3.0 s ... 30-coin tier 3.0 s with its last 6 coins fast-forwarded"; Discretion (:126) "a hold is capped at 3 s".
  implication: every planning record that describes the hold encodes both the 3 s cap and the 0.08 s floor; all need a G-01-59 amendment. T-01-24 loses its subject (no fast-forward) unless the cap mode is kept as an optional data feature.

- timestamp: 2026-10-02T18:44:00Z
  checked: Scratch probe diag59/curve_probe.gd run headless with the pinned console Godot (exit 0). Uses the REAL LoopTuning.coin_interval / coin_due_seconds / build_hold_seconds and CoinDripVfx.flight_seconds_for / launch_stagger on a duplicate of the shipped tuning, SHIPPED (floor 0.08, cap 3.0) vs OWNER (floor 0.05, cap 0).
  found: |
    Floor reached at coin 13 (shipped) vs coin 18 (owner). Intervals identical through coin 12 (0.25, 0.25, 0.225, 0.2025, 0.1823, 0.1640, 0.1476, 0.1329, 0.1196, 0.1076, 0.0969, 0.0872); owner then 0.0785, 0.0706, 0.0635, 0.0572, 0.0515, 0.05...
    Hold seconds   cost: 2     3     4      5      6      10     12     13     15     18     20     25     30     40     50     75     100
      shipped           0.500 0.725 0.9275 1.1098 1.2738 1.7814 1.9655 2.0455 2.2055 2.4455 2.6055 3.000  3.000  3.000  3.000  3.000  3.000   (rushed at cap: 25->1, 30->6, 40->16, 50->26, 100->76)
      owner             0.500 0.725 0.9275 1.1098 1.2738 1.7814 1.9655 2.0439 2.1781 2.3367 2.4367 2.6867 2.9367 3.4367 3.9367 5.1867 6.4367 (nothing rushed)
    Every shipped Phase 1 cost (2..6) is identical; the change only shows from 13 coins up. Beyond coin 17 each extra coin adds exactly 0.05 s: hold(n) = 2.4367 + 0.05 x (n - 20) for n >= 18.
    Coins in the air (VFX rule clamp(0.9 x gap, 0.12, 0.27)): costs 2-7 one at a time (unchanged); first overlap at coin 8 (gap 0.1196 < 0.12, unchanged); at most 2 airborne up to cost ~17, at most 3 airborne from coin ~18 (0.12 s flights launched every 0.05 s). Shipped floor 0.08 gave at most 2.
    Frame-quantized controller model (owner curve): 60 Hz -> every floor coin exactly 3 frames apart, max 1 coin per frame; 144 Hz -> 7 or 8 frames (0.0486/0.0556 s); 30 Hz -> alternating 1 and 2 frames (0.033/0.067 s, uneven cadence); 20 Hz -> 1 coin every frame; 15 Hz -> some frames carry 2 coins (0: 3 gaps at cost 30, 8 at cost 50), handled by the same-frame stagger. Completion overshoots the curve by at most one frame (cost 30: 2.9375 s at 144 Hz, 2.95 s at 60 Hz; cost 50: 3.9375 / 3.95 s).
    Shipped cap frame: cost 50 pays 26 coins in one frame, cost 30 pays 6 (matches orchestrator's 24+26 / 24+6).
    Call cost of coin_due_seconds: capped 17-26 us per call for n = 50 / 1000 / 20000 (early return at the cap); uncapped 31 us (n 50), 756 us (n 1000), 10.7 ms (n 20000). Controller worst single frame: shipped cost 50 cap frame 650 coin_interval calls; owner cost 50 at most 99 (141 at 15 fps).
  implication: |
    The owner's literal request is fully satisfied by data alone: no cap means no rush (every coin drips, so the invisible-rush observation disappears), floor 0.05 shortens only holds of 13+ coins. Concrete numbers for the re-check: sandbox 15 -> 2.18 s, 30 -> 2.94 s (all 30 dripped, about the old cap), 50 -> 3.94 s. Normal-game holds are unchanged (0.50 / 0.73 / 1.11 / 0.93 / 1.27 s).
    Guarantees lost with the cap: (a) a hard upper bound on hold length (now ~0.05 s per coin past 17, 100 coins = 6.4 s); (b) coin_due_seconds' per-call bound (its doc at loop_tuning.gd:55-58 becomes false: per call O(cost), per hold O(cost x frames)); harmless at realistic costs (<= ~100 coins, < 0.1 ms/frame), only a self-inflicted frame-time cost with tampered data of thousands of coins (which also needs that much starting gold to start the hold). The cap's own worst case was the cap frame (O(rushed coins x cap/floor) in ONE frame), so removing it does not worsen the pathological case.
    0.05 s is 3 frames at 60 Hz; at 30 Hz the cadence alternates 33/67 ms; below 20 Hz pairs share a frame and the existing same-frame stagger (MAX_BURST_COINS, launch_stagger) keeps them distinct, so the burst logic must stay even without the cap.

- timestamp: 2026-10-02T18:47:00Z
  checked: 01-REVIEW.md (reviewed 2026-10-02T13:15:07Z, the 01-14..01-16 chain) and 01-REVIEW-DISPOSITION.md
  found: |
    Open findings on exactly the files this change touches: WR-01 (test_build_hold_cap release-before-cap and test_coin_drip_burst assume short frames; MAX_DRIPS_IN_AIR 2 "rests on the 0.08 s floor"), WR-02 ("A cap of zero silently removes the hold cap ... reintroduces gap G-01-58"; suggests in-range contract asserts for decay, steady coins and floor, and @export_range hints), IN-01 (doc comments hard-code "0.25 s", "3 s", "0.08 s" in build_hold_controller.gd:4-5, coin_drip_vfx.gd:3-6, loop_tuning.gd:5-8), IN-02 (tautological ceiling test), IN-03 (delayed burst/refund coins sit visible and stacked at the king/spot before launch - the same mechanism the orchestrator saw as "rush coins hidden inside the king"), IN-04 (duplicated scaffolding in the cap/burst tests and sandbox literals). All six are disposition "open".
  implication: WR-02's premise is reversed by the owner: cap 0 is now the INTENDED shipped value, so the contract must pin "no cap" deliberately (or the field is removed) instead of treating 0 as an accident; WR-02's in-range asserts (0 < decay < 1, steady >= 1, 0 < floor <= first) still apply and would now pin the 0.05 floor. The gap plan rewrites the files named by WR-01/IN-01/IN-04, so it can close them in passing; IN-03 still matters for refunds and low-fps pairs even after the rush is gone.

- timestamp: 2026-10-02T18:48:00Z
  checked: Scratch probe diag59/model_height_probe.gd (merged AABB tops of the building models) vs CoinDripVfx SPOT_ANCHOR (0, 3.0, 0) and KING_ANCHOR (0, 1.5, 0)
  found: house_t1 top 3.14 m, house_t2 3.14 m, house_t3 6.60 m, tower_t1 5.40 m, tower_t2 7.83 m. Every coin lands at spot + 3.0 m and launches at king + 1.5 m (inside the ~2.6 m king model).
  implication: on EVERY upgrade hold (House I->II, II->III, Tower I->II, normal game included) the coin's landing point is inside the already-built model; the visible part of each 0.12-0.27 s flight is only its middle. This is pre-existing (01-06/01-15 anchors), independent of the cap and the floor, and not part of the owner's request; with the 0.05 s floor more coins per second vanish into the roof on 13+ coin upgrades. Optional, separate visual follow-up (e.g. land above the current model's top); not a root cause of G-01-59.

- timestamp: 2026-10-02T18:50:00Z
  checked: |
    Differential GUT run (pinned console Godot, headless, full .gutconfig.json suite, JUnit to the scratchpad):
    (a) WITH scratch pre-run hook diag59/owner_tuning_hook.gd, which sets the CACHED shipped LoopTuning to coin_drip_min_interval 0.05 and max_build_hold_seconds 0.0 in memory (script defaults untouched, nothing written to disk; hook printed "DIAG59 hook: cached shipped tuning now floor 0.050 cap 0.00");
    (b) control WITHOUT the hook.
  found: |
    (b) control: 46 scripts, 358/358 passing, exit 0.
    (a) owner data: 46 scripts, 347/358 passing, 11 failing, all in five cap/floor-encoding suites:
      tests/unit/test_loop_tuning_contract.gd (3): test_script_defaults_match_the_shipped_pacing_data (floor 0.08 vs 0.05 :58, cap 3.0 vs 0.0 :61 - the script defaults must change with the .tres); test_shipped_cap_is_set_and_at_most_the_owner_maximum (:90 cap > 0, :92 huge tier == cap; build_hold_seconds(1000) = 51.44 s); test_every_shipped_hold_is_capped_and_never_shorter_than_a_cheaper_one (:104 hold <= cap for every shipped cost).
      tests/e2e/test_build_hold_cap.gd (4 of 6): test_the_pricey_hold_builds_with_one_progress_per_coin_and_one_debit (waits only cap + 1.0 s = 1.0 s, 4 of 30 coins paid), test_the_hold_completes_at_the_cap, test_every_coin_due_at_the_cap_is_paid_in_the_same_frame, test_releasing_just_before_the_cap_refunds_everything (cap - 0.3 = -0.3 s, released at 0 coins). test_no_coin_is_paid_before_its_due_time passed only vacuously (timed out at 1 s), test_repricing_... is cap-agnostic.
      tests/e2e/test_coin_drip_burst.gd (2 of 4): test_the_cap_rush_is_staggered_inside_the_burst_window (1 delay, expected 12), test_a_huge_rush_draws_only_the_visual_cap (1, expected 12). test_every_burst_coin_is_freed_... passed vacuously (hold timed out at 1 s and refunded); test_a_normal_drip_launches_immediately is cap-agnostic.
      tests/e2e/test_hold_pacing_sandbox.gd (1 of 3): test_the_sandbox_uses_the_shipped_tuning_so_the_big_tiers_hit_the_cap (50-coin hold 3.937 s vs cap 0.0).
      tests/unit/test_e2e_support_tuning.gd (1 of 4): test_the_helper_hands_out_a_copy_and_leaves_the_shipped_tuning_alone (:51 "the shipped hold is still capped").
    Everything else passed under the owner data, including test_build_hold_timing.gd (4), test_loop_tuning_curve.gd (14, uses explicit values), test_coin_drip_flight.gd (9, shipped costs <= 6), test_coin_drip.gd, test_build_hold_refund.gd, test_walking_skeleton.gd, test_upgrade_at_spot.gd, test_debug_overlay_toggle.gd, test_spot_label.gd, test_start_night_hold.gd.
    The hook run's Godot process segfaulted at exit (139) AFTER writing results; the control exited 0, so the crash is the scratch hook's Engine.set_meta(Resource) reference surviving engine teardown, not the project.
  implication: confirmed by experiment - the owner's change is a pure data change at runtime; exactly 11 tests in 5 suites encode the 3 s cap or the 0.08 s floor and must be rewritten; no runtime, visual or other test depends on the cap. test_build_hold_timing.gd does NOT encode the cap (the 30-coin "about 3.0 s" and "release just before the cap" tests live in test_build_hold_cap.gd).

## Resolution

root_cause: |
  Design change on working behaviour, not a defect. The 3 s hard limit and the 0.08 s per-coin floor the owner rejects are two shipped DATA values, pinned by D-05 (as amended for G-01-58) and by the tests and records written for it:
  (1) data: max_build_hold_seconds = 3.0 and coin_drip_min_interval = 0.08 in both the LoopTuning script defaults (simulation/defs/loop_tuning.gd:27,30) and data/tuning/loop_tuning.tres:10-11. LoopTuning.coin_due_seconds (:59-68) clamps every coin's due time to the cap, so from coin 25 on every remaining coin is paid in the cap frame (30 coins: 24 dripped + 6 rushed at 3.0 s; 50 coins: 24 + 26). coin_interval (:45-52) never goes below the floor, reached at coin 13.
  (2) decision and pins: D-05's G-01-58 amendment (01-CONTEXT.md:70, :126), and 11 tests in 5 suites (test_loop_tuning_contract x3, test_build_hold_cap x4, test_coin_drip_burst x2, test_hold_pacing_sandbox x1, test_e2e_support_tuning x1), plus SECURITY T-01-22..T-01-25, VALIDATION, the sandbox text and several doc comments, all encode "capped at 3 s" and/or "0.08 s".
  "No cap" is already expressible in data: max_build_hold_seconds <= 0 disables it (loop_tuning.gd:62), and the controller and the coin VFX never read the cap or the floor directly. With cap 0 and floor 0.05 the normal game is unchanged (costs 2..6 = 0.500/0.725/0.928/1.110/1.274 s); a 15-coin hold takes 2.18 s, 30 coins 2.94 s and 50 coins 3.94 s with every coin dripped; after coin 17 each coin adds 0.05 s; at most 3 coins are in the air (0.12 s minimum flight vs 0.05 s gaps; 2 today).
suggested_fix_direction: |
  Non-binding.
  DATA (the behaviour change): set coin_drip_min_interval 0.05 and max_build_hold_seconds 0.0 in BOTH loop_tuning.tres and the LoopTuning script defaults. Option A, smallest: keep the field and its "<= 0 means no cap" switch dormant (flat_drip_tuning and test_loop_tuning_curve already use it). Option B: delete the cap field and the capped branch in coin_due_seconds. That also removes e2e_support.gd:44, the cap tests in test_loop_tuning_curve.gd:79-97 and test_build_hold_cap.gd, and T-01-24's subject. Under A, the contract must pin "no cap" deliberately, which reverses the premise of review WR-02.
  CODE: no runtime change is required. Fix stale docs: loop_tuning.gd:5-8, :18-30 and :55-58 (the "cap / floor iterations" bound no longer holds: per call is now O(cost), 0.03 ms at 50 coins, 0.76 ms at 1000); build_hold_controller.gd:3-5 and :96-101; coin_drip_vfx.gd:3-9 and :112-113. This is a chance to close review IN-01 by writing "the tuned floor" instead of numbers. Optional: make due times O(1) per frame by caching the next due time in the controller or with a closed form. Not needed at realistic costs.
  KEEP the burst stagger and MAX_BURST_COINS. Refunds and frames longer than 0.05 s (below 20 fps, or a hitch) still produce same-frame groups.
  TESTS:
    - test_loop_tuning_contract.gd: update the header and OWNER_MAX_HOLD_S. Replace test_shipped_cap_is_set_and_at_most_the_owner_maximum and the cap half of test_every_shipped_hold_is_capped_... with no-cap and floor pins (shipped cap <= 0 or the field absent; floor == 0.05, or 0 < floor <= first; holds non-decreasing; WR-02's range asserts). The script-default parity test passes once the defaults change.
    - test_build_hold_cap.gd: rework into an uncapped long-hold suite. Example: a 30-coin tier drips all 30 coins, each at its due time within a frame, finishing about 2.94 s with one debit; a release just before completion refunds everything. Waits come from build_hold_seconds(cost) + slack, never max_build_hold_seconds. Fixing WR-01 there means stepping the controller deterministically or guarding against long frames. Alternatively keep cap-mode coverage with an explicit capped fixture (Option A only).
    - test_coin_drip_burst.gd: the two cap-rush tests become a same-frame group test (refund burst, or a forced long frame) plus a long-drip airborne bound of 3 (derive it as ceil(MIN_FLIGHT_SECONDS / floor)). MAX_DRIPS_IN_AIR 2 and its "0.08 s floor" comment are stale. Waits must not use max_build_hold_seconds.
    - test_hold_pacing_sandbox.gd: test_the_sandbox_uses_the_shipped_tuning_so_the_big_tiers_hit_the_cap becomes "the 50-coin tier is uncapped (3.94 s) and drips every coin".
    - test_e2e_support_tuning.gd:43-51: the "shipped hold is still capped" assertion inverts or goes. flat_drip_tuning's doc (e2e_support.gd:34-38) mentions the shipped cap.
    - test_loop_tuning_curve.gd still passes because it uses explicit values. Optionally retarget FLOOR_S, CAP_S and the owner table to the new curve (2.1781 at 15, 2.9367 at 30, 3.9367 at 50) so it documents the shipped decision.
    - Headers of test_coin_drip_flight.gd:2-5 and test_coin_drip_burst.gd:1-6 mention "the 3 s cap".
  TOOLS: hold_pacing_sandbox.gd:3-6 doc and the :30-38 print text ("stop at %s s ... rushed in at once" would print "0.0 s") must describe the uncapped stream. The 15/30/50 costs still exercise the floor (from coin 18). shot_scenarios.gd needs no change.
  RECORDS: amend D-05 again for UAT G-01-59 (01-CONTEXT.md:70 and Discretion :126): no hold cap, floor 0.05 s, every coin drips, 15/30/50 coins = 2.18/2.94/3.94 s, +0.05 s per coin past 17. Refresh 01-SECURITY.md T-01-22 (:66 "cap of at most 3 s"), T-01-23 (:67 "no instant or endless hold": endlessness is prevented by positive intervals and finite cost, not the cap), T-01-24 (:68, retire or rescope), T-01-25 (:69 "cap rush" becomes refund and low-fps groups) and :599-611. Refresh 01-VALIDATION.md rows :157-162 and BLDG-04 :179. 01-VERIFICATION.md (:60, :86, :115-117, :151-157, :172-177, :245-246) is regenerated by re-verification.
  UAT RE-CHECK WORDING: normal game unchanged (House I 0.5 s, III 1.1 s, tower 0.9 s, one coin at a time). Sandbox: the 15-coin build takes about 2.2 s, the 30-coin build about 2.9 s with every coin dripped, and the 50-coin build about 3.9 s. There is no rush, and up to 3 coins are in the air at the fastest. Releasing late on the 50-coin tier refunds all coins (12 drawn) and builds nothing. Also ask whether "0.05 s" meant the pace, as built, or the visible flight time.
  SEPARATE, NOT IN SCOPE: every upgrade's coins land inside the already-built model (target spot + 3.0 m vs House I/II roof 3.14 m and Tower I 5.40 m). Review IN-03 (delayed burst and refund coins sit visible and stacked before launch) is still open.
fix: (diagnose only; not applied)
verification: (diagnose only)
files_changed: []
