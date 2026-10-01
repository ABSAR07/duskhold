---
status: diagnosed
trigger: "UAT G-01-4: pass. But the building count up time is too short. needs tweaking to make it a biiiit longer"
created: 2026-10-02T00:00:00Z
updated: 2026-10-02T00:20:00Z
goal: find_root_cause_only
---

## Current Focus

bug_class: Bohrbug (deterministic; a tuning value, reproduced exactly by a timed probe)
hypothesis: CONFIRMED. Build hold duration = cost x coin_drip_interval (0.2 s) with no floor, so the common builds finish in 0.4-0.6 s
test: done (code read + headless timing probe)
expecting: n/a
next_action: Return ROOT CAUSE FOUND to the orchestrator; the fix goes to plan-phase --gaps

reasoning_checkpoint:
  hypothesis: "Cheap builds feel instant because duration is cost x 0.2 s, with no minimum, and the most common costs are 2-3 coins"
  confirming_evidence:
    - "build_hold_controller.gd:95-102: interval = coin_drip_interval; a coin per interval; completion at coins_paid >= cost; timer starts at 0"
    - "Probe: House I completed at 0.410 s, House II 0.607 s, Tower I 0.803 s (model 0.4/0.6/0.8)"
  falsification_test: "A measured House I hold materially longer than 0.4 s, or any other code path delaying completion. Neither was observed."
  fix_rationale: "Raising the per-coin interval (data) or adding a duration floor (code) directly lengthens the measured hold the owner felt"
  blind_spots: "Owner's subjective target is unknown ('a biiiit'). The real-window feel at 144 fps was not re-measured, but the timer is delta-accumulated so it is frame-rate independent."
  candidate_causes:
    - "data: coin_drip_interval = 0.2 at the fast end of D-05's 0.15-0.3 range"
    - "code: linear-only duration model with no minimum total hold"
    - "environment: frame-rate dependent timer (eliminated)"
  and_gate: "yes: small interval AND small early costs AND no floor jointly produce sub-0.5 s holds; any one lever fixes it, and the data lever is the minimal one"

known_pattern_candidate: none (knowledge-base.md does not exist yet; MemPalace not used)

## Symptoms

expected: Holding the action key at a plot builds/upgrades over a hold that takes a deliberate, slightly longer moment (UAT test 4)
actual: "pass. But the building count up time is too short. needs tweaking to make it a biiiit longer"
errors: none
reproduction: UAT test 4 - hold Space at a House plot with 4 gold; House I costs 2 and completes almost at once
started: discovered during UAT 2026-10-02 (always this way since 01-06)

## Eliminated

- hypothesis: The hold completes faster than its model because of a timing bug (timer not reset between holds, double-counted delta, frame-rate dependence)
  evidence: _reset_hold zeroes _drip_timer (build_hold_controller.gd:133-137); the timer accumulates real delta; the probe measured coin spacing of 0.200 s and completion within about 10 ms of cost x 0.2 for all five tiers
  timestamp: 2026-10-02T00:15:00Z

- hypothesis: The HUD or spot-label count-up runs on its own faster clock
  evidence: ui/hud/hud.gd:86-98 and ui/world/spot_label.gd:144-156 only mirror coins_paid from hold_progress; neither reads coin_drip_interval nor animates independently
  timestamp: 2026-10-02T00:08:00Z

## Evidence

- timestamp: 2026-10-02T00:05:00Z
  checked: input/build_hold_controller.gd:91-102 (_advance_hold), :77-86 (_try_start_hold)
  found: _drip_timer starts at 0.0 on hold start; each frame adds delta; while _drip_timer >= interval a coin is paid (hold_progress); completion when _coins_paid >= _cost. interval = maxf(tuning.coin_drip_interval, 0.001). First coin lands at t = 1 x interval (not t = 0). No minimum total duration, no per-building or per-tier duration, no curve.
  implication: hold duration = cost x coin_drip_interval exactly (plus frame quantization). Duration is purely linear in cost.

- timestamp: 2026-10-02T00:06:00Z
  checked: data/tuning/loop_tuning.tres:7, simulation/defs/loop_tuning.gd:5-6, data/buildings/house.tres (cost 2/3/5), data/buildings/tower.tres (cost 4/6), data/maps/prototype_map.tres:62 (starting_gold 4)
  found: coin_drip_interval = 0.2 (script default also 0.2). start_night_hold_seconds = 1.5. Durations: House I 0.4 s, House II 0.6 s, House III 1.0 s, Tower I 0.8 s, Tower II 1.2 s. Every build/upgrade in the game is shorter than the 1.5 s start-night hold; the opening House I is 27% of it.
  implication: the cheapest and most frequent actions (House I/II) are the ones that feel "almost instant", matching the owner's report.

- timestamp: 2026-10-02T00:08:00Z
  checked: every reader of coin_drip_interval (grep outside .planning)
  found: |
    Runtime: input/build_hold_controller.gd:95 (cadence); presentation/vfx/coin_drip_vfx.gd:56 (flight = min(0.18, interval*0.9); at 0.2 -> 0.18 s, so a longer interval does NOT lengthen the flight, it adds a gap between coins).
    Signal-driven only (no direct read): ui/hud/hud.gd:86-98 (_pending = coins_paid), ui/world/spot_label.gd:144-156 (coin icon fill = coins_paid). They follow whatever cadence the controller emits.
    Tools: tools/screenshot/shot_scenarios.gd:15,75 (HOLD_INTERVALS = 2.5; build_in_progress waits 2.5 x coin_drip_interval at tower_1 (cost 4) and requires get_coins_paid() > 0).
    Tests deriving from the live value: tests/e2e/test_walking_skeleton.gd:33, tests/e2e/test_upgrade_at_spot.gd:22-23 (cost x interval + 0.5), tests/e2e/test_debug_overlay_toggle.gd:124, tests/integration/test_build_hold_refund.gd:125.
    Tests overriding the value (independent of the .tres): test_build_hold_refund.gd SLOW_DRIP_S 1.0, test_coin_drip.gd SLOW_DRIP_S 0.8 and a hard-coded 0.2 at :130, test_spot_label.gd SLOW_DRIP_S 1.0, test_start_night_hold.gd:252 SLOW_DRIP_S 1.0.
    Tests using the live value with a FIXED timeout (implicit upper bound): test_build_hold_refund.gd:116 (first coin within WAIT_SLACK_S 3.0) and :185-187 (House I complete within 3.0 s => 2 x interval < ~3.0).
  implication: no test pins 0.2 as an asserted value; changing the .tres is safe for derived tests. Upper bounds: per-coin interval < ~1.4 s for test_build_hold_refund, and the screenshot assumes effective per-coin cadence == coin_drip_interval.

- timestamp: 2026-10-02T00:10:00Z
  checked: 01-CONTEXT.md D-05 (lines 66-69), D-09 (83-84), Claude's Discretion (125); 01-RESEARCH.md:454; 01-06-PLAN.md:237,301
  found: D-05 "steady rate (1 coin = 1 gold), so pricier builds take a little longer ... Costs use Thronefall-scale small integers so holds stay short". D-09: drip rate lives in .tres and is tuned at the Phase 2 playtest gate. Discretion: "roughly 0.15-0.3 s per coin is the starting point". Research picked 0.2 s/coin. D-06 is refund, D-07 is the label coin-icon fill (both cadence-agnostic). No decision mandates a minimum total hold duration.
  implication: 0.2 s was a deliberately chosen first-pass value at the fast end of a placeholder range, explicitly expected to be retuned. This is a tuning gap, not a code defect.

- timestamp: 2026-10-02T00:15:00Z
  checked: Scratch probe (outside the repo, scratchpad/measure_hold.gd) run headless with the pinned console Godot against the real prototype_map.tscn, starting_gold 50, pressing action_build via Input.action_press and timestamping hold_progress/hold_completed
  found: |
    coin_drip_interval=0.2 start_night_hold_seconds=1.5
    House I  (2): coins at 0.187/0.394 s, COMPLETED 0.410 s
    House II (3): coins at 0.197/0.397/0.597 s, COMPLETED 0.607 s
    House III(5): COMPLETED 1.007 s
    Tower I  (4): COMPLETED 0.803 s
    Tower II (6): COMPLETED 1.211 s
    Process exited 0; no Godot process left running.
  implication: measured durations equal cost x 0.2 s within about one frame. The model is confirmed end to end; there is no hidden speed-up bug.

- timestamp: 2026-10-02T00:17:00Z
  checked: tests/unit for any assertion on coin_drip_interval; presentation/vfx/coin_drip_vfx.gd:13-15
  found: No unit test pins 0.2. The VFX flight is capped at MAX_FLIGHT_SECONDS 0.18, so raising the interval leaves flight at 0.18 s and adds a visible gap between coins (0.12 s at 0.3 s/coin). test_coin_drip FLIGHT_SETTLE_S = 0.4 tolerates a flight cap up to roughly 0.35 s.
  implication: a data change is not blocked by tests; the VFX cap should be considered alongside so the stream stays continuous (UAT test 7 passed the stream feel at a 90% flight duty cycle).

- timestamp: 2026-10-02T00:18:00Z
  checked: web search for a Thronefall per-coin build drip reference
  found: no reliable figure. Reference castle upgrades cost 7 and 20 coins (steamcommunity guide 3016836199), so the long tail of a linear model grows later (20 coins = 4 s at 0.2, 6 s at 0.3).
  implication: the per-coin value is an internal tuning choice; long-tail behaviour (cap or acceleration) is a later-phase concern, not this gap.

## Resolution

root_cause: |
  Tuning, not a code defect. BuildHoldController (input/build_hold_controller.gd:91-102) makes hold duration exactly cost x coin_drip_interval, and data/tuning/loop_tuning.tres:7 sets coin_drip_interval = 0.2 s, the fast end of D-05's 0.15-0.3 s placeholder range (D-09 defers tuning to the Phase 2 playtest gate). With Thronefall-scale costs (House 2/3/5, Tower 4/6), the most common actions finish in 0.4 s (House I) and 0.6 s (House II), only 27-40% of the 1.5 s start-night hold, which is the game's existing "deliberate" reference. Every build/upgrade is shorter than that reference. Contributing conditions (AND): small per-coin interval (data) x small early costs (data/design) x a purely linear model with no floor (code). Changing any one lengthens cheap builds.
suggested_fix_direction: |
  Preferred (data only, D-05-compliant): set coin_drip_interval 0.2 -> 0.3 in data/tuning/loop_tuning.tres (and the script default in simulation/defs/loop_tuning.gd:6 for consistency). Gives House I 0.6, II 0.9, III 1.5, Tower I 1.2, Tower II 1.8 s. Sensible band 0.25-0.35. Optionally raise CoinDripVfx.MAX_FLIGHT_SECONDS 0.18 -> ~0.27 so coins still fly for about 90% of each interval. No test or screenshot change is needed; derived tests scale, and the fixed 3.0 s waits in test_build_hold_refund.gd allow up to about 1.4 s per coin.
  Alternative (code + data): a minimum total hold, effective_interval = max(coin_drip_interval, min_build_hold_seconds / cost). This lengthens only cheap builds, but it breaks D-05's "steady rate, pricier takes longer" at the low end (House I/II/Tower I collapse to the same duration). It also requires a shared duration helper for the tests that compute cost x interval + 0.5 (walking_skeleton, upgrade_at_spot, debug_overlay_toggle, build_hold_refund:125), whose slack would otherwise shrink to about 0.1 s, plus a fix to shot_scenarios.gd:75 (it waits 2.5 x coin_drip_interval and needs at least one coin; it breaks if min/4 > 0.5 s at tower_1).
  Long tail (later phase): castle upgrades of 7 and 20 coins scale linearly (20 coins = 6 s at 0.3); a max-total cap or accelerating drip belongs to the Phase 2 playtest gate or Phase 5, not this gap.
fix: (diagnose only, not applied)
verification: (not applicable, diagnose only)
files_changed: []
