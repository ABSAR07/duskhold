---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T14:39:48Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 1
skipped: 1
status: partial
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T14:39:48Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 1
- Skipped: 1

**Verification environment:** all gates ran in the main checkout (no worktree was created, as in the previous
pass: the orchestrator's probe-and-restore workflow and the gitignored Godot import cache need the real tree).
Final full run `bash tools/test.sh`: 289/289 passing in 36 scripts (unchanged count; the fix is a test constant).
`bash tools/lint.sh`: clean. `.planning/config.json` was left uncommitted, and `.github/workflows/ci.yml`,
`ui/hud/dawn_payout_vfx.gd` and the start-night prompt were not touched.

## Fixed Issues

### IN-02: The e2e refresh assertions have a tight real-time window

**Files modified:** `tests/e2e/test_debug_overlay_toggle.gd`
**Commit:** 625a89d
**Applied fix:** `REFRESH_WINDOW_S` changed from 0.5 to 1.0 (one constant, used by all three refresh waits and
their failure messages). The 0.25 s cadence is still asserted deterministically by the unit tests, so nothing
that the window proved is lost.
**Probe (the widened window still discriminates):** with the fix in place, replaced `_advance_refresh(real_delta)`
with `_advance_refresh(0.0)` in `ui/overlay/debug_overlay.gd`, so the tick never refreshes. Three e2e tests failed
("the Buildings row shows 1 within 1.0 s", "the overlay refreshes within 1.0 s while paused", "the overlay
refreshes within 1.0 s of real time"). Source restored from a backup copy and confirmed unchanged by `git diff`.
This is a test-reliability change with no source behaviour change, so there is no "fails on unfixed code" probe.

## Skipped Issues

### IN-01: Toggle reads `Input` directly, so it fires for input a UI has already consumed

**File:** `ui/overlay/debug_overlay.gd:114`
**Reason:** skipped: the reviewer rates it harmless today and its own fix says to act "when a rebind or menu UI
arrives". No such UI exists in Phase 1, so nothing can consume F3 or Back before the overlay sees it. Polling
`Input` also matches `build_hold_controller.gd` and `start_night_hold_controller.gd`; moving only the overlay to
`_unhandled_input` would make one controller inconsistent, and the right design (a shared suppress flag or
consistent event-based handling, chosen against the real rebind/pause UI) cannot be picked without that UI. The
change would also rewrite every overlay e2e test that drives the toggle with `Input.action_press` (which
dispatches no `InputEvent`) to `Input.parse_input_event`, for no observable benefit yet. Revisit when the Phase 2+
pause or rebind screen lands.
**Original issue:** `Input.is_action_just_pressed(TOGGLE_ACTION)` ignores GUI focus and `set_input_as_handled()`.
The gamepad binding is Back, which menus and rebind screens commonly use, so once such a UI exists a press there
would toggle the overlay as well.

---

_Fixed: 2026-09-30T14:39:48Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
