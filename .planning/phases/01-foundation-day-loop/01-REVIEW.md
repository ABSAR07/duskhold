---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T11:30:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - tests/e2e/test_dawn_payout_hardening.gd
  - tests/support/sim_signals.gd
  - tests/support/sim_signals.gd.uid
  - tests/unit/test_debug_overlay_readonly.gd
  - tests/unit/test_debug_overlay_timed_phases.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T11:30:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the Skip-enum refactor of `DebugOverlayModel`, the new shared `SimSignals` list with its drift guard, and the two overlay test suites plus the dawn-payout hardening e2e suite. I cross-checked the payout tests against `ui/hud/dawn_payout_vfx.gd` (clamping, warning texts, coin budget and stagger arithmetic, tween validity) and found the assertions consistent with the implementation. The `SimSignals.ALL` list matches SimEvents' own signals, and the `.uid` file is well-formed. No crashes, security issues or wrong-behaviour bugs were found. The remaining findings are robustness and test-completeness gaps: one warning-suppression hole in the model and one unenforced invariant behind the new `SKIP_MESSAGES` table.

## Warnings

### WR-01: `_warn_once` swallows a different, later problem within the same streak

**File:** `ui/overlay/debug_overlay_model.gd:72-101`
**Issue:** `_warned` is keyed by title only, and it is cleared only when the provider returns an all-well-formed Array (line 95) or is replaced or dropped. A provider that first returns malformed rows (warning "dropped N malformed row(s)") and then starts returning Nil or a String keeps the `_warned[title]` flag set. The new, different failure ("returned Nil, not an Array") is never reported, and the section silently disappears. The docstring on `_warn_once` promises "name it once per failure streak", but the flag treats two distinct problems as one streak. The tests only cover streaks of a single problem kind (`test_a_flapping_provider_warns_again_after_it_recovers`, `test_a_provider_with_malformed_rows_...`).
**Fix:** Key the one-shot on the problem as well as the title, so a changed problem warns again:
```gdscript
func _warn_once(title: String, problem: String) -> void:
	if _warned.get(title, "") == problem:
		return
	_warned[title] = problem
	push_warning("debug overlay section '%s' %s" % [title, problem])
```
The `_warned.erase(title)` calls stay as they are. The dropped-rows message embeds the count, so use a count-free key for it, or store a separate `kind` string. Add a test for malformed-then-Nil.

### WR-02: Nothing enforces that every `Skip` code has a `SKIP_MESSAGES` entry

**File:** `ui/overlay/debug_overlay_model.gd:12-23, 80`
**Issue:** The comment says "Every code except NONE needs a message", but this is unenforced. Adding a new `Skip` value without a `SKIP_MESSAGES` entry makes `SKIP_MESSAGES[skip]` at line 80 fail with an invalid-key error inside `collect()`, which runs on every overlay refresh. That is the failure mode the refactor set out to prevent (comments at lines 75-77 describe avoiding a script error on every refresh). The drift-guard pattern used for `SimSignals` is not applied here.
**Fix:** Add a unit test alongside the model tests:
```gdscript
func test_every_skip_code_except_none_has_a_message() -> void:
	for code_name: String in DebugOverlayModel.Skip.keys():
		var code: int = DebugOverlayModel.Skip[code_name]
		if code == DebugOverlayModel.Skip.NONE:
			continue
		assert_true(DebugOverlayModel.SKIP_MESSAGES.has(code), "%s has a message" % code_name)
```
Alternatively, make the call site defensive with `SKIP_MESSAGES.get(skip, "it cannot be called")`.

## Info

### IN-01: Test-helper duplication across the two overlay suites

**File:** `tests/unit/test_debug_overlay_timed_phases.gd:17-48` (and `tests/unit/test_debug_overlay_readonly.gd:10-33`)
**Issue:** `_context_with_one_house` and `_prototype_with_one_house` are the same setup, `_loop` and `_section` are variants of one lookup, and `_row` and `_row_value` are variants of another. `COLLECT_REPEATS` and the 200-collect read-only assertion body are also duplicated. This commit already extracted `SimSignals` into `tests/support`, so the natural next step is a shared `OverlayTestSupport` helper. Fixes to one copy will otherwise drift from the other.
**Fix:** Move the setup and lookup helpers into a `tests/support/` class (no `test_` prefix, so GUT does not collect it) and call them from both suites.

### IN-02: `test_debug_overlay_readonly.gd` sits exactly at the 20 public-method cap

**File:** `tests/unit/test_debug_overlay_readonly.gd:43-327`
**Issue:** The file declares 20 `test_*` methods. The sibling e2e file's header notes that gdlint's public-method cap of 20 forced a split, so the next test added here will fail lint. Its content also now spans two concerns: read-only behaviour (DEV-03) and provider-registration robustness (about 12 tests).
**Fix:** Split the provider-registration and robustness tests (from `test_a_freed_section_provider_is_skipped...` onward) into `test_debug_overlay_providers.gd`.

### IN-03: Misleading comment in the negative-amounts payout test

**File:** `tests/e2e/test_dawn_payout_hardening.gd:157`
**Issue:** The comment "The Economy was credited the claimed 5" is not what the test does. It emits the `dawn_payout` signal directly and never credits the Economy, so the ledger stays at `RICH_GOLD`. The final assertion (`_hud_gold_settled`) therefore compares the HUD against an un-credited ledger. The same holds for the clamped test at line 83, where a synthetic 2,000,000 payout is announced without a matching credit. The tests still verify what they claim (the HUD readout is not left held back), but the comment misdescribes the setup.
**Fix:** Reword to "The payout claims 5 gold, but no per-spot amount can carry a coin (the ledger is not credited in this synthetic emit)."

### IN-04: `register_section` raises a script error if the `lifetime_owner` is already freed

**File:** `ui/overlay/debug_overlay_model.gd:51`
**Issue:** Verified with a headless probe on Godot 4.7.2: passing a previously freed instance to an `Object`-typed parameter raises "Invalid type in function ... (previously freed)" at the call site, before the function body runs. A caller that registers a section with an owner that has already been freed therefore errors instead of getting the graceful skip that the rest of the API provides. The failure is in the caller's frame, so the body cannot guard it.
**Fix:** Document that `lifetime_owner` must be alive at registration, or take it as `Variant` and check `is_instance_valid` before `weakref`.

---

_Reviewed: 2026-09-30T11:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
