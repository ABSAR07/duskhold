---
phase: 03-king-combat-troops
reviewed: 2026-10-13T19:48:42Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - data/buildings/tower.tres
  - data/maps/prototype_map.tres
  - input/command_key_controller.gd
  - presentation/king/king.gd
  - tests/e2e/test_command_keys.gd
  - tests/e2e/test_king_knockout.gd
  - tests/e2e/test_king_widget.gd
  - tests/e2e/test_pad_commands.gd
  - tests/e2e/test_spawn_telegraph.gd
  - tests/e2e/test_start_night_plate.gd
  - tests/e2e/test_start_night_plate.gd.uid
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_report.gd
  - tests/integration/test_balance_value_metric.gd
  - tests/integration/test_balance_value_metric.gd.uid
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_night_data_contract.gd
  - tools/contrast_probe.sh
  - tools/replay/balance_report.gd
  - tools/replay/replay_driver.gd
  - tools/screenshot/contrast_probe.gd
  - tools/screenshot/contrast_probe.gd.uid
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/hud/king_widget.gd
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 3: Code Review Report (incremental, UAT round-1 gap closure, plans 03-13 to 03-19)

**Reviewed:** 2026-10-13T19:48:42Z
**Depth:** standard
**Files Reviewed:** 25 (the files changed since review commit 86e60eb)
**Status:** issues_found

## Summary

This round changed: the Shift / RT queue gesture for the F, H and R verbs (03-13, command_key_controller.gd); the king's in-world health bar following regeneration (03-14, king.gd); the knocked-out king widget dimming only its non-text parts (G-03-13, king_widget.gd); a plate behind the start-night prompt and singular/plural enemy copy (03-15, hud.gd, hud.tscn); the squad value metric (03-16, replay_driver.gd, balance_report.gd); the Round 2 data tuning (03-17, tower.tres, prototype_map.tres) with its pins; and a real-window contrast probe (03-19). I traced each change against the code it calls (SquadOrderIntent, CommandProcessor, SquadSystem.apply_order, KingState, HealthBar3D, BuildingSystem, the Tally event wiring, project.godot input actions) and found no incorrect behaviour and no security defect. The probe's path guard is sound: it rejects `..` segments, absolute paths outside the project and non-.png names, and the shell wrapper fails closed on a missing CONTRAST_OK line or script errors. One warning (the probe's pure functions have no automated test) and three info items follow.

### WR-01 from the previous review: re-verified, FIXED in code

The previous WR-01 said the king's in-world health bar never followed regeneration. `presentation/king/king.gd` now connects `ctx.events.king_healed` to `_on_king_healed` in `bind_run` (line 54). The handler (lines 101-103) calls `_health_bar.set_health(hp, max_hp)` with the event's own numbers. I checked the chain end to end:

- `KingState._regenerate()` emits `king_healed(gained, _health, max_hp)` only when the integer health changed, and skips while down or at full health, so the handler never fires for a downed king.
- `HealthBar3D.set_health` sets `visible = should_show(hp, max_hp)`, which is false at full health, so the bar hides again once the king is whole.
- The pre-existing refresh paths (damage, knockout, respawn, dawn payout) are untouched, and `bind_run` still guards against a repeat call, so the new connection cannot be made twice.
- The new test `test_after_regeneration_the_king_bar_follows_each_heal_and_hides_at_full` (test_king_knockout.gd) checks the bar ratio at the instant of every `king_healed` event, the widget label, and the hide at full health. It takes its wait times from the shipped king def.

WR-01 can be marked resolved in 03-REVIEW-DISPOSITION.md. No review-fix pass produced it; plan 03-14 did.

### Carried forward, still OPEN, not re-examined by this round

These nine touch files outside this scope. They keep their IDs and remain open in 03-REVIEW-DISPOSITION.md. The previous report's text is in git history (`git show 86e60eb:.planning/phases/03-king-combat-troops/03-REVIEW.md`).

- CR-01 (BLOCKER): a unit with `max_health <= 0` hangs the game in an unbounded spawn loop in `simulation/squads/squad_system.gd`; validation only reports it.
- WR-02: `tools/screenshot.sh` cannot see script errors.
- WR-03: a refused squad order is silent. Observation only, not a new finding: plan 03-13 gives players a new way to hit it. Shift+F, Shift+H or Shift+R behind a queue that ends in a hold, follow or patrol is refused by the command gate with `QUEUE_CLOSED`, and `_give` in `command_key_controller.gd` emits no feedback for it. The fix for WR-03 should cover this path too.
- IN-01: dead patrol-leg budget assignment.
- IN-02: duplicated ground-bounds rule.
- IN-03: duplicated `separate()` code.
- IN-04: test-only accessors.
- IN-05: unused ext_resource entries.
- IN-06: the eighth patrol click is dropped silently.

Recorded owner decisions (D-26 to D-28: the 0.8 squad-value bar, the Round 2 goals, A kept for attack-move) and the deliberate balance pins (BALANCED_LOST_SEEDS [3, 9]; the towers_first survival pin replacing its win pin) were not treated as findings.

## Warnings

### WR-04: The contrast probe's pure functions (path guard and measurement) have no automated test

**File:** `tools/screenshot/contrast_probe.gd:57-90, 141-215`
**Issue:** `parse_args` / `_safe_image` (the traversal and sandbox guard), `_parse_rect`, `measure`, `luminance` and `contrast_ratio` are all static and side-effect free, yet nothing under `tests/` exercises them (a repo-wide search finds the probe named only in test_king_widget.gd's comment and in the wrapper). The probe is the sole real-window evidence for the G-03-13 legibility claim, and its measurement rule is bespoke (a red key with a 0.15 threshold, the 90th percentile of fill luminance against the median of fill-adjacent pixels). A regression in the rule can turn it into a false pass that nobody notices, because the shipped wrapper is manual and not in CI. The guard is also a security-relevant function (it decides which file the script opens) whose rejection cases (`..`, a sibling prefix such as `res://screenshots_evil/x.png`, an absolute path outside the project, a non-.png name, a bare `res://screenshots/.png`) are only covered by reading the code.
**Fix:** Add `tests/unit/test_contrast_probe.gd`, loading the script with `load("res://tools/screenshot/contrast_probe.gd")` and calling the statics. Build small `Image` fixtures in memory: red text (#FF4040) on a black outline must measure at or above 4.5; the same text on a mid-grey surround must measure below 4.5; an image with no red pixels must return the "no fill pixels" error. Assert `parse_args` rejects each guard case above and accepts `--image=screenshots/a.png --rect=1,2,3,4`.

## Info

### IN-07: `to_markdown` indexes the new run keys strictly while `summary` reads them tolerantly

**File:** `tools/replay/balance_report.gd:104-107, 255-269, 310-316`
**Issue:** `summary` reads the new fields with `entry.get("military_gold_spent", 0)` (so a hand-built or older run entry works), but `_value_row` goes through `_mean(runs, key)`, which does `entry[key]` and raises an invalid-access error when a run lacks `military_gold_spent`, `unit_kills`, `tower_gold_spent` or `tower_kills`. A report that `summary` accepts can therefore make `to_markdown` fail. The shipped path always builds complete entries through `_run_entry`, and test_balance_report.gd's hand-built report calls only `summary`, so nothing breaks today.
**Fix:** Make `_mean` tolerant, `total += float(entry.get(key, 0))`, so both readers agree.

### IN-08: The queue action name is a literal in two controllers and a constant in a third

**File:** `input/command_key_controller.gd:56, 204` (constant `QUEUE_ACTION`) against `input/pad_cursor_controller.gd:103` and `input/selection_controller.gd:280` (literal `&"command_queue"`)
**Issue:** Plan 03-13 added a `QUEUE_ACTION` constant to the command key controller, but the two controllers that already read the same action keep the literal. A rename of the action in project.godot would need three edits, and a missed one fails silently (an unknown action name in `Input.is_action_pressed` only logs an error and returns false, so Shift stops queueing on that path).
**Fix:** Define the action name once (for example `const QUEUE_ACTION` on `SelectionController` or in a small shared input-actions script) and reference it from all three.

### IN-09: The panel colour #14141A at alpha 0.78 is written out in three places

**File:** `ui/hud/hud.tscn` (`StyleBoxFlat_start_night_plate`, `bg_color = Color(0.0784, 0.0784, 0.1019, 0.78)`), `ui/hud/king_widget.gd` (`PLATE_COLOR`), `tests/e2e/test_start_night_plate.gd:24` (`PLATE_COLOR`)
**Issue:** The start-night plate is meant to match the king widget's plate (UI-SPEC), and the test pins the literal rather than the widget's constant. Retuning one without the others silently drifts the HUD's two plates apart; the plate test would still pass because it compares against its own copy.
**Fix:** Have the plate test read `KingWidget.PLATE_COLOR` so the two plates stay in step, and note the dependency beside the sub_resource in hud.tscn.

---

_Reviewed: 2026-10-13T19:48:42Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
