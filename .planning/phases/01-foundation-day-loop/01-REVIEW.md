---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T14:32:14Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - tests/e2e/test_debug_overlay_toggle.gd
  - tests/unit/test_debug_overlay_registration.gd
  - ui/overlay/debug_overlay.gd
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T14:32:14Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed `ui/overlay/debug_overlay.gd` with its two test files. I also read `debug_overlay_model.gd`, `debug_overlay.tscn`, `hud.tscn`, `project.godot` and `tests/e2e/e2e_support.gd` to check the call paths.

No bugs or security problems were found. The points I checked:

- **Bind logic:** `bind_run` refuses a null context before `_model` is set, so a later valid bind still works. A repeat bind is idempotent, and a repeat with a different context warns.
- **Pending sections:** the pending list mirrors the model's replace-in-place rule. It holds owners only through a `WeakRef`, so a replaced entry never warns about its old owner. The pre-bind checks (`title_problem`, `owner_problem`) match the model's, so the two paths agree.
- **Timing and process mode:** the refresh clock uses real time (`Time.get_ticks_usec`), so `Engine.time_scale` cannot slow or freeze it. The scene sets `process_mode = 3` (ALWAYS), so the overlay keeps running while the tree is paused.
- **Bindings:** the F3 and gamepad Back bindings in `project.godot` (keycode 4194334, joypad button 4) are covered by `tests/unit/test_input_map.gd`.
- **Input polling:** `Input.is_action_just_pressed` is read from `_process`, which is correct for a per-frame check. The toggle frame skips `_advance_refresh` but calls `_refresh` itself when the overlay becomes visible.
- **Tests:** each e2e test that changes global state (pause, `time_scale`, held actions) restores it in `after_each`. The unit tests drive `_advance_refresh` synchronously with no awaits in between, so real `_process` ticks cannot disturb the call counts they assert.

The previous review's skipped "toggle polls `Input`" note is judged below on its merits (IN-01).

## Info

### IN-01: Toggle reads `Input` directly, so it fires for input a UI has already consumed

**File:** `ui/overlay/debug_overlay.gd:114`
**Issue:** `Input.is_action_just_pressed(TOGGLE_ACTION)` ignores GUI focus and `set_input_as_handled()`. The gamepad binding is Back (`JOY_BUTTON_BACK`), a button that menus and rebind screens commonly use. Once a rebind UI or pause menu exists and the player presses Back or F3 there, the overlay toggles as well. The same applies to a rebind screen capturing F3. The overlay also ships in release builds (accepted threat T-01-15). It is harmless today, since no UI exists that consumes those inputs, and it matches the other controllers (`build_hold_controller.gd` and `start_night_hold_controller.gd` also poll `Input`). It becomes a real defect the moment a Phase 2+ screen binds F3 or Back.
**Fix:** When a rebind or menu UI arrives, either move the toggle to `_unhandled_input(event)` with `event.is_action_pressed(TOGGLE_ACTION)` and `get_viewport().set_input_as_handled()`, or have the UI set a suppress flag while it captures input. For example:
```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION, false, true):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()
```
Then `_process` only advances the refresh clock. The e2e tests would need to send real `InputEventAction`s instead of using `Input.action_press`.

### IN-02: The e2e refresh assertions have a tight real-time window

**File:** `tests/e2e/test_debug_overlay_toggle.gd:7`, `:88-91`, `:114-117`, `:139-142`
**Issue:** `REFRESH_WINDOW_S` is 0.5 s against a 0.25 s refresh interval. `wait_until` measures wall-clock milliseconds, so a frame hitch of 250 ms or more (a cold shader compile, or a loaded CI runner) can time the wait out even though the overlay is correct. The `test_shown_overlay_refreshes_the_buildings_row_after_a_build` case is the most exposed, because it runs the whole ride-and-hold build path first. This is a test-reliability risk only.
**Fix:** Give the window headroom without weakening what it proves: `REFRESH_WINDOW_S = 1.0` still shows "refreshes about 4 times a second" through the unit cadence tests, which already assert the 0.25 s interval deterministically.

---

_Reviewed: 2026-09-30T14:32:14Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
