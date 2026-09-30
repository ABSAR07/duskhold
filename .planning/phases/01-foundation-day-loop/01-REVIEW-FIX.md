---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T14:24:10Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 4
skipped: 1
status: partial
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T14:24:10Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 4
- Skipped: 1

**Verification environment:** all gates ran in the main checkout (no worktree was created, because the
orchestrator's probe-and-restore workflow and the Godot import cache need the real tree). Final full run
`bash tools/test.sh`: 289/289 passing in 36 scripts (was 286/286; net +3 tests). `bash tools/lint.sh`: clean.
`.planning/config.json` was left uncommitted, and `.github/workflows/ci.yml`, the start-night prompt and
`ui/hud/dawn_payout_vfx.gd` were not touched (so the CR-01 guard needed no re-probe).

## Fixed Issues

### WR-01: The pause test checks the flag, not the behaviour it claims to protect

**Files modified:** `tests/e2e/test_debug_overlay_toggle.gd`
**Commit:** e91aa07
**Applied fix:** Replaced the flag-only test with `test_overlay_toggles_and_refreshes_while_the_tree_is_paused`.
It pauses the tree, presses F3 through `Input.action_press`, and asserts the overlay shows and fills. It then
builds a House through the command gate (no tree processing needed) and asserts the Buildings row refreshes to
1 within 0.5 s while still paused, and that a second F3 hides the overlay. `after_each` now sets
`get_tree().paused = false`, so a failure cannot leak a paused tree.
**Mutation probe:** added `if get_tree().paused: return` at the top of `DebugOverlay._process` (the kind of
change the old test would have passed). The new test failed ("Expected text and search strings to be
non-empty. You passed "" and "Buildings: 0""). Source restored from a backup copy.

### WR-02: The "refreshes about 4 times/s" contract has no upper-bound or cadence test

**Files modified:** `tests/unit/test_debug_overlay_registration.gd`
**Commit:** d07791d
**Applied fix:** Added two unit tests with a counting provider, driven with synthetic deltas and no real-time
waits. One checks no refresh before one interval, exactly one just after it, and that the timer restarts. The
other checks that a hidden overlay never refreshes and a shown one refreshes 7 to 9 times over 2 simulated
seconds at 60 fps (not one per frame). The freed-owner test's `wait_seconds(REFRESH_INTERVAL_S * 2.0)` sleep was
replaced by one synthetic interval. (Deviation from the suggested "10 calls of 0.1 give 4": discrete 0.1 steps
give 3 refreshes, so the tests use an unambiguous below/above-interval check and a tolerance band.) File is at
20 public methods, the gdlint cap. In this commit the tests drove `_process`; IN-02 later moved them to
`_advance_refresh`.
**Mutation probes:** (a) refreshing on every call (`if true:`) failed 4 assertions in the new tests; (b) never
accumulating the timer (`_since_refresh = 0.0`) failed the new cadence test and the freed-owner test. Source
restored from a backup copy each time.

### IN-02: `_refresh` advances on scaled delta, so a paused or slowed simulation freezes the overlay

**Files modified:** `ui/overlay/debug_overlay.gd`, `tests/e2e/test_debug_overlay_toggle.gd`, `tests/unit/test_debug_overlay_registration.gd`
**Commit:** bce38c1
**Applied fix:** The refresh clock now uses real elapsed time from `Time.get_ticks_usec()` (set in `_ready`,
updated every frame so showing the overlay after a long hidden spell cannot cause a burst), passed to a new
`_advance_refresh(seconds)`, which also holds the hidden-overlay guard. The reviewer's suggested
`delta / maxf(Engine.time_scale, 0.001)` was not used because at `time_scale = 0` delta is 0 and the quotient
stays 0, so it would not un-freeze the overlay. The unit cadence tests now call `_advance_refresh`. New e2e test
`test_overlay_keeps_refreshing_while_the_engine_time_scale_is_zero` sets `Engine.time_scale = 0.0` and asserts the
Buildings row still refreshes; `after_each` restores `Engine.time_scale = 1.0`.
**Mutation probe:** reverted `_advance_refresh(real_delta)` to `_advance_refresh(_delta)`; the new e2e test failed
("the overlay refreshes within 0.5 s of real time"). Source restored from a backup copy.

### IN-03: Pending sections are held forever if the overlay is never bound

**Files modified:** `ui/overlay/debug_overlay.gd`
**Commit:** e7a605d
**Applied fix:** Documentation only, as the review suggested. The `_pending` doc comment now says an entry's
provider Callable keeps its captures alive until `bind_run` runs, and for the overlay's lifetime if it is never
bound. No behaviour change, so no probe.

## Skipped Issues

### IN-01: The toggle is read by polling `Input`, so it also fires for input a UI has consumed

**File:** `ui/overlay/debug_overlay.gd:101`
**Reason:** skipped: optional design note that the reviewer itself calls "not a defect". Moving the toggle to
`_unhandled_input` means every overlay test that drives it with `Input.action_press` (which does not dispatch an
`InputEvent`) would need rewriting to `Input.parse_input_event`, across three suites, for a purely cosmetic
benefit in a read-only overlay. The situation it guards against (a rebind-capture screen, a UI consuming F3) does
not exist in Phase 1. Revisit when the runtime-rebinding UI lands.
**Original issue:** `Input.is_action_just_pressed(TOGGLE_ACTION)` in `_process` ignores whether a focused Control or
a pause menu consumed the event, so rebinding another action to F3 or pressing F3 in a rebind capture screen also
toggles the overlay.

---

_Fixed: 2026-09-30T14:24:10Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
