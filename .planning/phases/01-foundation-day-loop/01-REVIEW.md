---
phase: 01-foundation-day-loop
reviewed: 2026-09-30T10:04:59Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - tests/unit/test_debug_overlay_readonly.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay_model.gd
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-09-30T10:04:59Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the debug overlay (view, model, unit tests) and the dawn payout VFX. I traced the
payout flow through `_on_dawn_payout`, `_whole_amounts`, `_coins_for_amount`, `_coin_share`,
`_reset_for_new_payout` and `_launch_coin`, and cross-checked the HUD hand-off (`payout_started`
and `coin_landed` in `hud.gd`). I found no crash, data-loss or security defects.

- **Payout arithmetic.** Per-spot shares sum to the spot amount, and the coin budget and
  clamping hold. Malformed `per_spot` input is handled (non-finite floats, non-name keys, huge
  values). A superseded payout is guarded by `_generation`, and the HUD backstop releases any
  held-back gold at the end of dawn.
- **Model.** The provider-skip and warn-once logic is consistent, and each branch is covered by a
  test.

What remains is a silent-failure hazard in the overlay's registration API that Phase 2 is about
to use, plus a few maintainability and test-coverage points.

## Warnings

### WR-01: `DebugOverlay.register_section` silently drops registrations made before `bind_run`, and a second `bind_run` wipes all registered sections

**File:** `ui/overlay/debug_overlay.gd:17-26`
**Issue:** `register_section` is a no-op while `_model == null`, with no warning. The doc comment
says "Phase 2 and later add sections through this". Any caller that registers from its own
`_ready` or bind step before the overlay is bound (bind order across `run_bound` group members is
not guaranteed) loses its section, and nothing says so. This is the exact "silently never shows"
failure that `DebugOverlayModel._warn_once` exists to prevent one layer down.
`bind_run` also has no repeat-call guard, unlike `Hud.bind_run` and `DawnPayoutVfx.bind_run`
(`if _ctx != null: return`). A second call replaces `_model` with a fresh one, discarding every
registered provider without a warning.
**Fix:** Make registration independent of binding order, and guard the rebind:
```gdscript
var _pending: Array[Array] = []  # [title, provider, owner] registered before bind_run

func bind_run(ctx: RunContext, _map_root: MapRoot) -> void:
	if _model != null:
		return
	_model = DebugOverlayModel.new(ctx)
	for entry: Array in _pending:
		_model.register_section(entry[0], entry[1], entry[2])
	_pending.clear()

func register_section(title: String, provider: Callable, owner: Object = null) -> void:
	if _model == null:
		_pending.append([title, provider, owner])
		return
	_model.register_section(title, provider, owner)
```
At minimum, `push_warning` when `_model == null`.

### WR-02: Untested branches of the read-only model: `Timer` row and NIGHT/DAWN phases

**File:** `tests/unit/test_debug_overlay_readonly.gd:52-131` (covers `ui/overlay/debug_overlay_model.gd:132-145`)
**Issue:** The suite is named "read-only" and asserts that collecting does not mutate state. It
only ever collects in the DAY phase, so the NIGHT/DAWN branch of `_loop_rows` is never exercised.
That branch is the one that calls `run_manager.get_phase_time_remaining()` and appends the
`Timer` row. The `Day` and `Night` rows are also never asserted in the unit tests. The
200-collect no-mutation test likewise runs only in DAY, so a getter with a side effect in a
timed phase would not be caught. The e2e test only checks `Day: 1` and `Night: 0`.
**Fix:** Add a unit test that drives the run to NIGHT (and one to DAWN) and asserts three things.
The `Timer` row is present, it is absent in DAY, and repeated `collect` in that phase leaves the
timer, gold and phase unchanged. Assert `Day` and `Night` values after a phase change.

## Info

### IN-01: `_reset_for_new_payout` and `live_coin_count` treat every child as a coin

**File:** `ui/hud/dawn_payout_vfx.gd:255-256`, `ui/hud/dawn_payout_vfx.gd:78`
**Issue:** `queue_free()` is called on all children, and `live_coin_count` counts all non-queued
children. This works today because coins are the only children of `DawnPayoutVfx` (the scene
`PayoutTotal` label is a sibling under the HUD root). Any future child added to the node in the
scene, such as a pooled node, a debug marker or a trail effect, would be freed on the next
payout and counted as a coin.
**Fix:** Track coins explicitly, or put them in a dedicated container or group:
```gdscript
coin.add_to_group(&"payout_coin")
# then iterate get_children().filter(func(c: Node) -> bool: return c.is_in_group(&"payout_coin"))
```

### IN-02: `owner` parameter shadows `Node.owner` in `DebugOverlay.register_section`

**File:** `ui/overlay/debug_overlay.gd:24`
**Issue:** `DebugOverlay` extends `CanvasLayer` (a `Node`), which has an `owner` property. The
parameter shadows it. It is harmless at runtime, and I saw no shadow warning in the e2e test
output, but it is confusing to read and risks engine warnings if the warning level changes.
**Fix:** Rename the parameter to `lifetime_owner` or `watched`, in both `DebugOverlay` and
`DebugOverlayModel` for consistency.

### IN-03: `_registered.erase(entry)` removes by Dictionary content equality

**File:** `ui/overlay/debug_overlay_model.gd:70`
**Issue:** `Array.erase` finds the element by `==`, which compares Dictionary contents, including
a Callable and a WeakRef. It is correct here because titles are unique, but it depends on
content-equality semantics and does needless work compared with removing by identity or index.
**Fix:** Iterate by index over a reversed range and `remove_at(i)`, or key `_registered` by title
in a Dictionary so removal is `erase(title)`.

---

_Reviewed: 2026-09-30T10:04:59Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
