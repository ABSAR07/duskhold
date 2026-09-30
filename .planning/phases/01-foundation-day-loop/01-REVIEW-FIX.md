---
phase: 01-foundation-day-loop
fixed_at: 2026-09-30T07:08:00Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 10
fixed: 10
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-09-30T07:08:00Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 10 (fix_scope: all)
- Fixed: 10
- Skipped: 0

**Verification:** run in the main checkout (no worktree; `workflow.use_worktrees` opt-out per the orchestrator), branch `gsd/phase-01-foundation-day-loop`. Final state: `bash tools/test.sh` 227/227 passing (was 218 at the start of this pass), `bash tools/lint.sh` clean (gdformat and gdlint). `.github/workflows/ci.yml` was not touched.

**Mutation probes (a strengthened test must fail against the bug it guards):**
- WR-05 CR-01 stagger test: changed the launch delay in `ui/hud/dawn_payout_vfx.gd` to `float(launches.size()) * STAGGER_SECONDS` (the equivalent of the old `float(index) * STAGGER_SECONDS`). `bash tools/test.sh -gselect=test_dawn_payout.gd` went to 14/15 with two failures: "[0.88] expected to equal [0.4] +/- [0.0001]: the last coin's launch delay" and "[1.48] expected to be <= than [1.001]: the last coin is scheduled to land before the dawn window ends". Restored by reversing the edit with `sed` (a `git checkout` would have discarded the uncommitted accessor added for the test), then confirmed 15/15 green before committing.
- WR-05 cancelled-hold test: changed `_economy.grant(total)` to `grant(total * 2)` in `simulation/run/run_manager.gd`. `-gselect=test_start_night_hold.gd` went to 11/12: "[20] expected to equal [19]: only dawn income moved gold". Restored with `git checkout -- simulation/run/run_manager.gd`. Before the fix this mutation passed, because the expectation reduced to `gold == gold_before`.
- WR-03 cap test: passed `total` instead of `carried_gold` to `_coins_for_amount`. `test_dawn_payout.gd` went to 14/15 (the new cap test failed). Restored before committing.
- WR-01, WR-02, WR-04 and IN-05 tests were not mutation-probed. Each asserts a value the previous code could not produce (a named trigger or Ctrl+N hint, a `payout_started` signal, a null return from `apply_next_tier`, a single overlay section per title).

## Fixed Issues

### WR-01: Start-night hint reports "(unbound)" for bindings that work

**Files modified:** `ui/hud/hud.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** e83e5e0
**Applied fix:** `_start_night_hint` now names mouse-button events (`as_text()`) and joypad trigger events (`(LT)` and `(RT)`, `(Axis N)` otherwise), and key events go through a new `_key_text` helper that uses `as_text_physical_keycode()`, falling back to the keycode and then the key label, so modifiers show ("Ctrl+N"). A key event that names no key is skipped instead of adding an empty entry. The default text "Hold N / (Y) to start Night 1" is unchanged. Two new tests cover a trigger, a mouse button, a Ctrl+N chord and a blank key event.

### WR-02: HUD readout lag is derived independently of the VFX, so it holds only by an unenforced invariant

**Files modified:** `ui/hud/hud.gd`, `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`, `tests/e2e/test_map_binding.gd`
**Commit:** e6a0651
**Applied fix:** `DawnPayoutVfx` now plans every coin first and emits a new `payout_started(carried_total)` once per `dawn_payout`, before any coin launches. It emits 0 when nothing flies. The HUD no longer listens to `dawn_payout`; it sets `_payout_pending` from `payout_started`, so the held-back gold is always the gold the VFX will land. As a backstop, the HUD clears `_payout_pending` when the phase leaves DAWN. New tests cover the announced amount (a negative spot amount carries no coin) and the release at the end of dawn. The re-bind test now also checks `payout_started` gains no extra connection. Status: fixed, requires human verification (a logic change to when the readout releases; the tests are deterministic but a look at the dawn payout in the running game is worthwhile).

### WR-03: The coin cap and the "fits the dawn window" guarantee are not actually enforced

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`
**Commit:** 0a8e428
**Applied fix:** `_coins_for_amount` now scales by `carried_gold` (the sum of the positive `per_spot` amounts), not the claimed `total`. `MAX_COINS` is documented as a soft cap (each paying spot still sends at least one coin, so more than 12 paying spots send one coin per spot), the `launch_stagger` doc says a dawn no longer than `TRIP_SECONDS` cannot be met, and `bind_run` calls `push_warning` when `dawn_seconds <= TRIP_SECONDS`. The choice was to document the cap as soft rather than merge spots into shared coins, which would break per-spot attribution of coins. New tests: the cap holds when `total` disagrees with the parts, and the bind-time warning fires.

### WR-04: BuildingSystem hardening is inconsistent: empty-id spots are kept and `apply_next_tier` is unguarded

**Files modified:** `simulation/buildings/building_system.gd`, `tests/unit/test_building_system_data_errors.gd`
**Commit:** c85432a
**Applied fix:** `_init` skips spots with `id == &""`, so `get_spot(&"")` is null and `validate_build(&"")` returns `UNKNOWN_SPOT` on such a map. `apply_next_tier` returns null, mutating nothing and emitting nothing, when `next_tier_def(spot_id)` is null (unknown building or already at max tier). The old test that drove `apply_next_tier` into an unknown building and relied on a phantom instance was replaced by one asserting the refusal; new tests cover the empty-id spot and the max-tier guard.

### WR-05: Two e2e tests claim more than they assert

**Files modified:** `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`, `tests/e2e/test_start_night_hold.gd`
**Commit:** d03968c
**Applied fix:** `DawnPayoutVfx` gained a read-only `get_launch_delays()` accessor that records the delay of every scheduled coin. The short-dawn test (now `test_a_real_payout_schedules_its_last_coin_to_land_inside_a_short_dawn_window`) asserts 12 scheduled coins, that the last coin's delay equals `(n-1) * launch_stagger(n)`, and that delay plus `TRIP_SECONDS` is at most `dawn_seconds`. It uses no wall-clock timing and fails against the stagger bug (see the probe above). In `test_a_build_hold_is_cancelled_when_the_night_starts` a House is now built on `house_2` first and the test asserts its dawn income is greater than 0, so "only dawn income moved gold" can catch a payout bug (see the probe above).

### IN-01: Orphaned comment above the house constants

**Files modified:** `tests/e2e/test_dawn_payout.gd`
**Commit:** d03968c (removed in the same edit as WR-05; no separate commit)
**Applied fix:** Deleted the stale "Real-time allowance on top of the dawn window" comment, since the constant it described no longer exists.

### IN-02: PAD_BUTTON_NAMES is Xbox-only

**Files modified:** `ui/hud/hud.gd`
**Commit:** e8ee695
**Applied fix:** Documented the Xbox-style labels as a known Phase-1 limitation in the comment on `PAD_BUTTON_NAMES` (with `Input.get_joy_name` as the later route). No behaviour change, as the review recommended.

### IN-03: `_coin_share` does integer division through floats

**Files modified:** `ui/hud/dawn_payout_vfx.gd`
**Commit:** 8fb6201
**Applied fix:** `var base: int = (amount - remainder) / coin_count` with `@warning_ignore("integer_division")`. The existing payout tests (including the 120 + 83 split that must settle exactly on the ledger) pass unchanged.

### IN-04: Default-binding test depends on suite order

**Files modified:** `tests/e2e/test_start_night_hold.gd`
**Commit:** 669b131
**Applied fix:** `test_the_prompt_names_the_default_start_night_bindings` now sets `start_night` to the `project.godot` defaults (physical N, joypad button Y) before spawning the map. The file's `after_each` already restores the bindings.

### IN-05: Debug overlay accepts duplicate titles and cannot detect impure providers

**Files modified:** `ui/overlay/debug_overlay_model.gd`, `tests/unit/test_debug_overlay_readonly.gd`
**Commit:** 17c661d
**Applied fix:** `register_section` replaces the provider of an already-registered title in place, so a section never shows twice and keeps its position. The doc says so. The purity contract stays a documented convention (the review offered "or note" for that half); the 200-collect test still covers the default sections. A new test covers replacement and ordering.

---

_Fixed: 2026-09-30T07:08:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
