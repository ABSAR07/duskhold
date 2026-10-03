---
phase: 01-foundation-day-loop
reviewed: 2026-10-03T10:37:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - presentation/vfx/coin_drip_vfx.gd
  - tests/e2e/e2e_support.gd
  - tests/e2e/test_coin_drip_burst.gd
  - tests/e2e/test_hold_pacing_sandbox.gd
  - tests/unit/test_coin_drip_flight.gd
  - tests/unit/test_e2e_support_tuning.gd
  - tools/sandbox/hold_pacing_sandbox.gd
findings:
  critical: 0
  warning: 0
  info: 4
  total: 4
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-10-03T10:37:00Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Reviewed the whole of each listed file with the changes since 326ca0c in focus: the hidden-while-waiting coin change (IN-02), the stepped-hold test helpers, the capped-base `flat_drip_tuning` (WR-01), the derived ceiling and break-even tests, and the sandbox's plot-count gold.

Cross-checked against `simulation/defs/loop_tuning.gd` and `input/build_hold_controller.gd`. Traced the group/frame logic, the stagger and window maths, the airborne-bound arithmetic at the floor (3 coins), and the hidden-coin show/free path. None of it produced a correctness bug, security issue or data-loss risk. Ran `tools/lint.sh` (clean) and the four suites: `test_coin_drip_flight` 10/10, `test_e2e_support_tuning` 5/5, `test_hold_pacing_sandbox` 3/3, `test_coin_drip_burst` 8/8. No Godot process was left running and no repository file other than this report was touched.

The shipped pacing (0.25 s first interval, 2 steady coins, 0.9 decay, 0.05 s floor, no cap) is an owner decision and is not treated as a defect.

The remaining items are minor: one misleading doc claim, one stale-position visual nit, one test assertion that cannot catch the regression it names, and one silent failure path in the sandbox.

## Info

### IN-01: Class doc says the BuildIntent is sent when the last coin lands, but it is sent when the last coin is paid (launched)

**File:** `presentation/vfx/coin_drip_vfx.gd:11`
**Issue:** The header says "the simulation only ever sees the single BuildIntent sent when the last coin lands". In `BuildHoldController._advance_hold` (`build_hold_controller.gd:107-111`), the last coin's `hold_progress` is emitted and `_finish_hold` submits the intent in that same frame. The VFX spawns that coin in the `hold_progress` handler, so the building completes while the last coin has just left the king. It then flies for up to `flight_seconds_for(coin_interval(cost + 1))`, about 0.12-0.225 s at the shipped tuning. Behaviour is fine and probably intended; the comment misdescribes the order, which will mislead anyone who tunes the flight or adds a landing SFX.
**Fix:** Reword to "...sent in the frame the last coin is paid, while that coin is still leaving the king" (or similar), or delay the build visuals until the final coin lands if that was the intent.

### IN-02: Delayed coins fly to or from positions captured at event time

**File:** `presentation/vfx/coin_drip_vfx.gd:134-147`
**Issue:** The launch position (`_king.global_position + KING_ANCHOR`) and, for a refund, the destination `home` are computed once when the signal fires. A coin delayed by up to BURST_WINDOW_SECONDS (0.3 s) then appears at, or flies to, where the king was up to 0.3 s earlier. A refund fires on release or when leaving range, which is exactly when the king rides away, so the refund coins aim at a stale spot. With the new hidden-while-waiting behaviour the stale launch point is no longer visible as a stack, but the target drift remains. Cosmetic only.
**Fix:** If it ever reads badly, tween toward the king live, for example `tween_method` that lerps from `from` to `_king.global_position + KING_ANCHOR` each step, or compute `home` inside the delayed callback.

### IN-03: Sandbox test compares the context's tuning to the cached shipped resource, so it cannot detect an in-place mutation

**File:** `tests/e2e/test_hold_pacing_sandbox.gd:78-87`
**Issue:** `map_root.get_context().tuning` and `load(SHIPPED_TUNING_PATH)` normally resolve to the same cached `LoopTuning` instance. `assert_eq(tuning.coin_drip_interval, shipped.coin_drip_interval)` and the min-interval and cap checks therefore only fail if the sandbox swaps in a different tuning object. They stay green if the sandbox mutates the shared resource in place, which is the leak the file's header says it guards against. Only `plain_sum_s` (computed from the same object) is equally self-referential.
**Fix:** Pin against the owner's literal numbers (0.25, 0.05, 0.0 cap, as `test_coin_drip_flight` does for the ceiling), or compare against a fresh `ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)` copy.

### IN-04: Sandbox fails silently in the window when the map has no or a mis-tiered House

**File:** `tools/sandbox/hold_pacing_sandbox.gd:23-25`
**Issue:** When `_sandbox_map()` returns null (after `push_error`), `_ready` returns without starting a map. Run from the editor or a real window the owner sees an empty scene with only a console error. `get_map_root()` then returns null; the tests do guard it. Low impact (dev tool, excluded from export), but the failure is easy to miss. The plot-counting loop is also written twice (`house_plot_count` here and `_expected_gold` in the test); that is acceptable for an independent check but worth remembering when the map's House data changes.
**Fix:** `push_error` is probably enough for a dev tool; optionally `get_tree().quit(1)` in a headless run so a broken sandbox is not mistaken for a working one.

---

_Reviewed: 2026-10-03T10:37:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
