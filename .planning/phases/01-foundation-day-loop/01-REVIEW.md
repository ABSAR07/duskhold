---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T14:10:24Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - tests/e2e/test_debug_overlay_toggle.gd
  - tests/unit/test_debug_overlay_registration.gd
  - tests/unit/test_overlay_test_support.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay.tscn
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T14:10:24Z
**Depth:** standard
**Files Reviewed:** 5

## Summary

I reviewed the debug overlay view (`debug_overlay.gd`, `.tscn`) and its three test suites. I also read `DebugOverlayModel`, `OverlayTestSupport`, `hud.tscn`, `map_root.gd` and the `toggle_debug_overlay` entry in `project.godot`, to check the cross-file contracts.

The overlay logic itself holds up:
- bind_run is idempotent and refuses a null context before it sets any state.
- Pending sections replay in order, and a section replaced before bind keeps its place.
- A section whose owner was freed before bind is dropped with a warning.
- The pre-bind checks (`title_problem`, `owner_problem`) match the model's own, so a mistake is refused at the same moment on both paths.
- F3 (physical keycode 4194334) and gamepad Back (button 4) are bound correctly.
- The scene's `load_steps` and `process_mode = 3` (ALWAYS) are correct.

I found no crashes, security problems or data-loss risks. The remaining findings are one test that asserts a property rather than the behaviour its comment claims, one gap in the refresh-rate coverage, and a few robustness notes.

## Warnings

### WR-01: The pause test checks the flag, not the behaviour it claims to protect

**File:** `tests/e2e/test_debug_overlay_toggle.gd:92-105`
**Issue:** The test comment says "the F3 toggle and the refresh must still run" while the tree is paused. The test only asserts `process_mode == PROCESS_MODE_ALWAYS` and `can_process()`. Both are derived from the same `process_mode` property, so the second assertion adds almost nothing. Nothing checks that `_process` actually toggles or refreshes during a pause. A later change could break this and the test would stay green. Examples are moving the toggle to `_physics_process`, or gating `_process` on a paused-aware check. The test also writes `get_tree().paused` directly and restores it inline, so an error between the two writes would leave the tree paused for every following test in the run.
**Fix:** Pause the tree, press the toggle through the real input path, assert the overlay became visible, and restore the pause state in `after_each` (or with a `finally`-style guard). For example:
```gdscript
func after_each() -> void:
	get_tree().paused = false
	E2eSupport.release_all_actions()

func test_overlay_toggles_while_the_tree_is_paused() -> void:
	# ...spawn map, get overlay...
	get_tree().paused = true
	await _press_toggle()
	assert_true(overlay.is_overlay_visible(), "F3 still toggles while the tree is paused")
```
`_press_toggle` uses `wait_process_frames`, which keeps ticking under GUT while paused, so it can be reused.

### WR-02: The "refreshes about 4 times/s" contract has no upper-bound or cadence test

**File:** `tests/e2e/test_debug_overlay_toggle.gd:86-89` and `tests/unit/test_debug_overlay_registration.gd:146`
**Issue:** The file header claims the overlay "refreshes about 4 times/s" (DEV-03). The only checks are that the Buildings row updates within 0.5 s, and a `wait_seconds(REFRESH_INTERVAL_S * 2.0)` sleep in the unit suite. A regression that refreshes every frame, or one that never accumulates `_since_refresh` correctly, would pass every test. The wall-clock sleep-and-hope pattern also depends on frame pacing on a loaded CI machine. It is safe at 2x the interval, but the margin exists only because of the constant.
**Fix:** Add a unit test with a counting provider and drive `_process(delta)` directly with synthetic deltas. Assert that 10 calls of `delta = 0.1` yield 4 provider calls (this needs the overlay visible, which `_process` alone cannot do, so set `overlay.visible = true` first). That tests the cadence deterministically with no real-time waits. For example:
```gdscript
var calls: Array[int] = [0]
overlay.register_section("Count", func() -> Array: calls[0] += 1; return [["n", str(calls[0])]])
overlay.bind_run(_context(), null)
overlay.visible = true
for i in 10: overlay._process(0.1)
assert_between(calls[0], 3, 5)
```

## Info

### IN-01: The toggle is read by polling `Input`, so it also fires for input a UI has consumed

**File:** `ui/overlay/debug_overlay.gd:101`
**Issue:** `Input.is_action_just_pressed(TOGGLE_ACTION)` in `_process` ignores whether a focused Control or a pause menu consumed the event. Runtime rebinding is a stated requirement. If the player rebinds another action to F3, or presses F3 in a rebind capture screen, the overlay toggles too. The overlay is read-only, so this is cosmetic. Handling the action in `_unhandled_input` (with `set_input_as_handled`) would honour UI consumption, but it would need the `process_mode` ALWAYS setting kept. This is a design note, not a defect.
**Fix:** Optional. Move the toggle to `_unhandled_input(event)` using `event.is_action_pressed(TOGGLE_ACTION)`, and keep `_process` for the refresh only.

### IN-02: `_refresh` advances on scaled delta, so a paused or slowed simulation freezes the overlay

**File:** `ui/overlay/debug_overlay.gd:100-108`
**Issue:** `_process` delta is scaled by `Engine.time_scale`. If a later phase adds a fast-forward or slow-mo debug control, `time_scale = 0` would stop the overlay from refreshing (F3 still works). The FPS row would then look frozen. There is no current caller, so the risk is latent.
**Fix:** Optional. Accumulate `delta / maxf(Engine.time_scale, 0.001)`, or use `Time.get_ticks_msec()` for the refresh clock.

### IN-03: Pending sections are held forever if the overlay is never bound

**File:** `ui/overlay/debug_overlay.gd:20, 75-86`
**Issue:** `_pending` keeps each provider Callable (a strong reference to everything the lambda captured) until `bind_run` runs. The comment explains the WeakRef for the owner, but the provider capture still keeps a captured RefCounted alive for the overlay's lifetime if the bind never happens. This only matters if `MapRoot` fails to bind the overlay, which would already be a visible fault. The docs in `register_section` mention the caveat for the model; the same sentence applies here.
**Fix:** No code change needed. Optionally note in the `_pending` doc comment that unbound entries keep their captures alive.

---

_Reviewed: 2026-09-30T14:10:24Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
