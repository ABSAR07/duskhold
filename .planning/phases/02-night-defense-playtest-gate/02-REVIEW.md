---
phase: 02-night-defense-playtest-gate
reviewed: 2026-10-05T16:42:44Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - data/tuning/loop_tuning.tres
  - simulation/defs/loop_tuning.gd
  - simulation/defs/map_config.gd
  - simulation/night/wave_schedule.gd
  - tests/e2e/test_results_screen.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_map_validate_enemies.gd
  - tests/unit/test_wave_schedule.gd
  - ui/results/results_screen.gd
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 2: Code Review Report (re-review after fix pass 1)

**Reviewed:** 2026-10-05T16:42:44Z
**Depth:** standard
**Files Reviewed:** 9

## Summary

Read in full: wave_schedule.gd, results_screen.gd, map_config.gd, test_map_validate_enemies.gd, and the
diffs of loop_tuning.gd/.tres, test_results_screen.gd, test_loop_tuning_contract.gd and
test_wave_schedule.gd (plus the surrounding test helpers, enemy_system.gd stop/aggro code, SimClock and
EnemyDef). I ran one scratch Godot script (outside the repo) to check how a focused Button reacts to a
key press and release; no source was modified and no Godot process is left running.

WR-01 (validate rules) is correct: the aggro/attack rule matches enemy_system.gd (an enemy stops at
`radius + attack_range` from the centre, so its edge distance is exactly `attack_range`, and it only
targets an edge within `aggro_range`; strict `>` is right). WR-02 (night budget) is correct on valid data:
boundaries (count 0, negative, exactly 300, 300+1), group-order spending, and zero-allowance groups
(skipped, no entries, no budget taken) all behave; the simulation stays deterministic and pure.

WR-03 is NOT fully closed: the grace window gates the moment a button emits `pressed`, which for a Button
is the key/click RELEASE, not the press. A press that starts inside the window and is released after it
still restarts the run (WR-01 below). Both new results-screen tests also depend on real-time frame speed
(WR-02 below).

## Warnings

### WR-01: The input grace gates the release of a press, so a press started inside the window and held past it still restarts

**File:** `ui/results/results_screen.gd:99-106` (gate), `ui/results/results_screen.gd:85-86` (window)
**Issue:** `_on_play_again_pressed` / `_on_quit_pressed` check `accepts_input()` when `pressed` fires.
For a Button with the default action mode, `pressed` fires on release. I confirmed this with a scratch
script on 4.7.2 (focused Button: Space down gives 0 emissions, Space up gives 1). So a player who presses
the build key (or gamepad A, or the mouse button) at, say, 0.5 s after the screen appears and releases at
0.7 s gets `pressed` at 0.7 s, after `_accept_from_ms`, and Play again / Quit fires. This is exactly the
player WR-03 meant to protect, one still hammering or holding the action key as the run ends (hold-to-build
makes holds of a few tenths of a second normal). The window therefore shrinks the problem but does not
remove it for any press that straddles its end. The tests tap press+release inside the window, so they
cannot see this.
**Fix:** Gate on when the press began, not when it was released. Stamp the press time and require it to
be after the window:
```gdscript
var _down_ms: int = 0

func _ready() -> void:
	...
	_play_again_button.button_down.connect(_on_button_down)
	_quit_button.button_down.connect(_on_button_down)

func _on_button_down() -> void:
	_down_ms = Time.get_ticks_msec()

func _press_counts() -> bool:
	return accepts_input() and _down_ms >= _accept_from_ms
```
and use `_press_counts()` in the two `pressed` handlers. Add a test that presses inside the window,
waits for `accepts_input()`, releases, and asserts no signal. (Tests that emit `pressed` directly bypass
`button_down`; they would need `button_down.emit()` first, or keep `accepts_input()` for those.)

### WR-02: The new results-screen tests fail if the runner stalls longer than the grace window

**File:** `tests/e2e/test_results_screen.gd:347-349` (defeat test), `tests/e2e/test_results_screen.gd:372-374` (victory test)
**Issue:** Both tests assert "no emit" for presses made a fixed number of frames after the screen shows,
which is only true while real elapsed time stays below the grace. The defeat test makes three taps (12
process frames) plus two direct emits inside TEST_GRACE_S = 1.0 s; the victory test makes one tap (4
frames) inside the shipped 0.6 s window, starting after `wait_until` and `watch_signals`. On a slow or
loaded CI runner (a GC pause, a 100 ms frame in the siege scene, a loaded shared VM) the window can end
before the tap, `accepts_input()` becomes true, the tap restarts, and the assertion
"no accept inside the window restarts" fails for a reason unrelated to the code under test. The victory
test is the tighter one because it uses the shipped 0.6 s, not a test value. Local runs being stable
within 0.1 s does not bound this on CI.
**Fix:** Give the victory test its own long window instead of the shipped value (build a tuning with
grace 3.0 and the victory map; keep the shipped-value check in the contract test), and size the defeat
window so the three taps cannot outlast it; or assert the "ignored" half by reading `accepts_input()`
immediately before each tap and skipping the assertion (via `pending`) if it is already true.

## Info

### IN-01: `preview_counts` counts groups that `WaveSchedule` skips

**File:** `simulation/night/wave_schedule.gd:45` (also the comment at 62-64)
**Issue:** Re-verified, and the fix made it a little worse. `preview_counts` calls `_allowances(map,
night, false)`, so a group with an unknown `enemy_id` is previewed while `_init` (needs_enemy true) skips
it. Since the budget is now shared, such a group also spends the night budget in the preview only: a
night with group 0 = unknown enemy x 300 and group 1 = valid grunt x 5 spawns 5 but previews 300 from
group 0's road and 0 from group 1's. The comment at lines 62-64 says the preview and the schedule "agree",
which is false for this case. The new test `test_the_preview_agrees_with_a_capped_schedule` only uses valid
groups. This needs a map that validate() already reports, so it is advisory.
**Fix:** Pass `true` in `preview_counts` (`map.find_enemy` is available there), drop the `needs_enemy`
parameter, and add a preview-vs-schedule test with an unknown-enemy group ahead of a valid one.

### IN-02: `MAX_GROUP_COUNT` is now a dead clamp

**File:** `simulation/night/wave_schedule.gd:10`, `:74`
**Issue:** `budget` starts at `MAX_ENEMIES_PER_NIGHT` and only falls, so `mini(count, MAX_GROUP_COUNT,
budget)` can never be decided by `MAX_GROUP_COUNT`. It is referenced nowhere else (grep). It adds a
second name for the same number without any effect.
**Fix:** Remove the constant and the inner `mini`, or keep it only if some other code is meant to use it.

### IN-03: The "shipped grace is set in the data file" test cannot see the data file

**File:** `tests/unit/test_loop_tuning_contract.gd:166-178`
**Issue:** The test is named for the data file but reads the loaded resource's property, and the script
default (`loop_tuning.gd:49`, 0.6) equals the data value, so deleting the line from `loop_tuning.tres`
leaves it green (orchestrator mutation survivor, confirmed by reading: nothing in the test distinguishes
a stored value from the default). The `PROPERTY_USAGE_STORAGE` loop checks the script, not the file.
**Fix:** Read the text of `res://data/tuning/loop_tuning.tres` (`FileAccess.get_file_as_string`) and
assert it contains `results_input_grace_seconds =`, or temporarily give the script default a different
value than the data in the test by comparing against a `LoopTuning.new()` and requiring they differ is not
needed; the text check is enough.

### IN-04: The grace value has no upper bound

**File:** `ui/results/results_screen.gd:85`
**Issue:** `maxf(..., 0.0)` clamps from below only. A large value in the data file (a typo such as 60
for 0.6) leaves both buttons ignoring all devices for that long with no on-screen sign; the player can
only close the window. `LoopTuning` has no validation for it and the contract test only checks the
shipped file.
**Fix:** `clampf(value, 0.0, MAX_GRACE_S)` with a small named cap (for example 3.0), or a test bound that
matches the cap.

---

_Reviewed: 2026-10-05T16:42:44Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
