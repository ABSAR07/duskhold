---
phase: 02-night-defense-playtest-gate
reviewed: 2026-10-06T05:39:42Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - simulation/night/wave_schedule.gd
  - tests/e2e/test_results_screen.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_wave_schedule.gd
  - ui/results/results_screen.gd
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-10-06T05:39:42Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Third review of Phase 2, covering the five files changed since the second review (review-fix pass 2).
All five were read in full, plus `tools/test.sh`, `tests/e2e/e2e_support.gd` (wait_until),
`simulation/defs/map_config.gd` (find_enemy, find_spawn_point, night_def), `SimClock.ticks` and
`RunContext.advance`. Nothing was run and no source was modified; the orchestrator's measurements
(745 tests green, six mutation probes caught) were taken as given.

The second review's six fixes are sound in the code. The results screen and the wave schedule have no
defect I can show. The one real problem is in the new tests: the `pending()` escape hatch added for
WR-02 also swallows the exact regression those tests exist to catch, and `tools/test.sh` does not
fail on a pending test.

What I checked and found correct:

- **Press-start gate (`results_screen.gd`).** The engine's `BaseButton` emits `button_down` for
  keyboard and gamepad `ui_accept` as well as the mouse (non-echo press), which the passing
  key and gamepad straddle tests confirm empirically. A press begun inside the window and released
  after it is rejected because `_down_ms < _accept_from_ms`. A key held from before the screen
  appears sends no press event to the button, and its release does nothing because no press attempt
  began. A `pressed` with no `button_down` since the window opened is rejected: `_down_ms` starts at
  -1 and `_accept_from_ms` is never negative, so `-1 >= 0` is false. A grace of exactly 0 gives
  `_accept_from_ms == now`, so the first press (same millisecond or later) counts. The cap cannot lock
  the player out for more than 3 s, and a negative value clamps to 0. Nothing in the gate depends on
  focus, so focus changes cannot lock it. After the window all three devices work as before.
- **Shared `_down_ms` across the two buttons.** The only way I can construct to exploit it is a key
  press on Play again begun inside the window and still held, then a mouse press on Quit after the
  window, then the key released. That needs two devices at once and the focus change on the mouse
  press should already cancel the first button's press attempt. I did not report it; a per-button
  stamp would close it if the owner wants zero residual.
- **Wave schedule.** `_allowances` is the single rule for both the schedule and `preview_counts`:
  null group, unknown spawn point and unknown enemy each give 0 and spend no budget; the budget is
  spent in group order and `mini(maxi(count, 0), budget)` never goes negative. The constructor's
  `<= 0` skip and the preview's `> 0` filter agree. The sort key `(tick, group_index, index)` is
  total. The file uses no `Time`, `OS`, global random or scene tree, so it stays deterministic.
  `MAX_GROUP_COUNT` is gone and has no remaining users in the repo.
- **Contract test.** The `"\nresults_input_grace_seconds = "` check now fails if the line is removed
  from `loop_tuning.tres`; the shipped value of 0.6 sits inside the 0.3 to 1.0 pin.
- **Wave-schedule tests.** The unknown-enemy test fails on the pre-fix preview (it would list a
  full-budget ghost group at WEST and starve EAST) and passes now, for the right reason.
- **Bounded waits.** Every wait in the new tests is `E2eSupport.wait_until` (bounded by real time) or
  a fixed number of frames; a stalled runner cannot hang the suite.

## Warnings

### WR-01: A grace that is never applied turns every grace test pending, and a pending test does not fail the run

**File:** `tests/e2e/test_results_screen.gd:373-375`, `:405-407`, `:424-427` (also `:492-504`)
**Issue:** The three grace tests and the four straddle tests treat `results.accepts_input() == true`
after the taps as "the runner stalled past the window" and end with `pending()`. But
`accepts_input()` is also true immediately if the grace is simply not applied: `grace_ms` computed as
0, the clamp swapped, `_accept_from_ms` set to the past, or the tuning field read from the wrong
object. In that case all seven tests go pending, and nothing else asserts the window exists:

- `test_a_huge_grace_value_is_capped_so_the_buttons_still_work` (`:492`) only waits for
  `accepts_input()` to become true, which is true at once with no grace at all.
- `test_shipped_results_input_grace_is_set_in_the_data_file_and_short` only reads the data file.
- A repo grep shows `accepts_input` and `_accept_from_ms` are used by no other test.

`tools/test.sh` exits non-zero only if Godot/GUT exits non-zero, the JUnit XML is missing, or a
parse error appears. GUT counts pending tests as neither passed nor failed and exits 0 on them, so CI
stays green. The result is that the WR-03 behaviour (mashing the build key at the end of a run
restarts the game) can regress with a green suite. The orchestrator's six mutation probes did not
include "grace not applied", so this was not seen. The press-start stamp probes are caught only
because they do not depend on the window.

**Fix:** Decide "the window exists" from a fact that cannot be confused with a stall, taken the moment
the screen shows, and keep `pending()` only for the genuine stall. With a 3 s window a stall before
this check is not credible, so assert it hard:

```gdscript
# in _defeat_scene() and _victory_scene(), right after the wait for is_showing():
assert_false(results.accepts_input(), "the grace window is open when the screen appears")
```

Do the same in the two tests that build their own scene (`:359-363`, `:492-497` for the cap test:
there assert it is false after show, then keep the wait for true). Then a regression that applies no
grace fails these asserts instead of silently going pending. If a stall between show and assert is
still a concern, compare against a timestamp taken at show time instead of relying on the later
`accepts_input()` read.

## Info

### IN-05: Some end-to-end tests budget real seconds against a clamped simulation clock

**File:** `tests/e2e/test_results_screen.gd:17-18`, `:163`, `:267`, `:397`
**Issue:** `DEFEAT_TIMEOUT_S = 4.0` and `VICTORY_TIMEOUT_S = 20.0` are real-time budgets for events that
happen in simulation time, and `RunContext.advance` clamps each frame to
`SimClock.MAX_ADVANCE_SECONDS` (0.25 s). Real and simulated time agree only while the runner
holds at least 4 frames per second; below that the simulation runs slower than the wall clock and
the siege (castle falls) or the night (Victory) can miss its budget on a loaded CI VM, failing with
"the castle falls" or "the night is cleared" rather than a real defect. The loss-beat and grace waits
are real time on both sides and are not affected. No flake has been seen in the measured runs, so
the risk is latent.
**Fix:** Wait on simulation progress with a generous real-time backstop (for example, a tick-count
based predicate with the current timeout kept only as a deadlock guard), or raise the two timeouts
by a safety factor and state the minimum frame rate they assume.

---

_Reviewed: 2026-10-06T05:39:42Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
