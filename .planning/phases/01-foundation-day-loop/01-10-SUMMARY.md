---
phase: 01-foundation-day-loop
plan: 10
subsystem: hud-vfx-and-ci
tags: [godot, gdscript, gut, dawn-payout, hud, screenshots, xvfb, github-actions, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "01-03 CI workflow, prepush_check.sh, published repo and the push credential quirk; 01-06 HUD gold readout with pending-coin display; 01-07 building models; 01-09 dawn_payout event (total, per_spot in MapConfig order), start-night hold, night banner, lighting moods"
provides:
  - "DawnPayoutVfx: one gold coin per gold each paying House pays flies from above its plot to the HUD gold counter, then a '+X gold' total shows for 2 s; nothing shows for a 0 dawn"
  - "HUD readout that lags the ledger by the coins still flying (Hud._payout_pending) and settles exactly on Economy gold"
  - "tools/screenshot.sh + ShotRunner + ShotScenarios: six scripted scenes (day_overview, spot_label, build_in_progress, night_banner, dawn_payout, overlay_on) captured through input actions and intents, refusing --headless (exit 2) and rejecting blank frames (exit 1)"
  - "CI screenshots job (needs test) under xvfb with the Compatibility renderer, uploading the duskhold-screenshots artifact next to duskhold-windows"
  - "Phase 1 published: CI green on origin with lint, test, export and screenshots"
affects: [phase-01-verify-work, phase-02-nights-waves, phase-08-audio-visual-polish]

actuals:
  tokens: 21500
  tasks: 3
  commits: 5
plan_head_before: abbfdfc322393f4f31b7b0d635cbb80834877708
plan_head_after: 72d9f18b8c563394d5ce9993e3aa689ba05a528c

tech-stack:
  added: []
  patterns:
    - "Payout VFX is display only: the Economy is credited when dawn begins and the HUD subtracts the gold whose coins are still in the air"
    - "Screenshot tooling never runs under --headless; the only headless call in screenshot.sh is the --import warm-up"
    - "Scripted scenes call ctx.commands intents and Input.action_press, never simulation setters"
    - "A capture is rejected when a 64x36 downsample has luminance variance < 0.0005 or fewer than 8 colours (4 bits per channel)"

key-files:
  created:
    - ui/hud/dawn_payout_vfx.gd
    - tests/e2e/test_dawn_payout.gd
    - tests/unit/test_shot_blank_check.gd
    - tools/screenshot/shot_runner.tscn
    - tools/screenshot/shot_runner.gd
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot.sh
  modified:
    - ui/hud/hud.tscn
    - ui/hud/hud.gd
    - .github/workflows/ci.yml

key-decisions:
  - "Coins are launched from a per-coin delay tween (0.08 s apart) so live_coin_count and get_spawned_count reflect coins actually in the air; a generation counter makes a newer payout discard a stale one"
  - "The HUD payout total is a separate Label (%PayoutTotal) placed under the gold counter rather than a sibling inside the Margin container, so %GoldLabel keeps its node path"
  - "The tests use a tuning duplicate with a 0.5 s night (dawn_seconds and everything else come from loop_tuning.tres) to keep the e2e file near 9 s"
  - "CI screenshots use upload-artifact@v7 and checkout@v7 to match the other jobs (the plan said v4)"

patterns-established:
  - "RED commit carries a signature-only stub plus the scene nodes, so typed tests fail on assertions rather than on missing nodes"
  - "Hud.bind_run can run twice on one HUD when a second map joins the tree (call_group hits every run_bound node); connections to objects that outlive a run need an is_connected guard"

requirements-completed: [DEV-04, DEV-02, ECON-02]

coverage:
  - id: D1
    description: "At dawn each paying House sends one coin per gold to the gold counter, the counter lags the ledger while they fly and settles exactly on it, and a '+X gold' total (derived from house.tres) appears and fades"
    requirement: "ECON-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_dawn_payout.gd (5 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A dawn that pays 0 spawns no coins and shows no '+0 gold'"
    requirement: "ECON-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_dawn_payout.gd#test_a_dawn_that_pays_nothing_shows_no_coins_and_no_total"
        status: pass
    human_judgment: false
  - id: D3
    description: "bash tools/screenshot.sh saves six non-empty PNGs locally and in CI; the runner exits 2 under --headless and rejects blank images"
    requirement: "DEV-04"
    verification:
      - kind: e2e
        ref: "rm -f screenshots/*.png && bash tools/screenshot.sh (6 PNGs) and tools/godot.sh --headless ... shot_runner.tscn exits 2"
        status: pass
      - kind: unit
        ref: "tests/unit/test_shot_blank_check.gd (4 tests)"
        status: pass
      - kind: e2e
        ref: "gh run 36561004973 screenshots job success, duskhold-screenshots artifact with 6 PNGs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every push runs lint, test, export and screenshots in CI and the phase is green on origin"
    requirement: "DEV-02"
    verification:
      - kind: e2e
        ref: "gh run 36561004973 on gsd/phase-01-foundation-day-loop @ 72d9f18: lint, test, export, screenshots all success; artifacts duskhold-windows, duskhold-screenshots, gut-results"
        status: pass
    human_judgment: false
  - id: D5
    description: "The dawn payout and the six scenes read correctly to a player: coin size and timing, the '+X gold' total placement, the orange dawn light"
    verification: []
    human_judgment: true
    rationale: "Tests assert coin counts, timing windows, HUD text and visibility, not how the flight, colours and layout look. The dawn capture shows the mood only half-blended (see Issues Encountered)."

duration: 19min
completed: 2026-09-29
status: complete
---

# Phase 1 Plan 10: Dawn Payout, Screenshots and Green CI Summary

**At dawn a coin per gold flies from each paying House to the HUD counter (which ticks up as they land) before a "+X gold" total, six scripted scenes are captured to PNG through the real input path locally and under xvfb in CI, and the whole phase is green on origin with a downloadable Windows build and the screenshot set.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-09-29T11:05:01Z
- **Completed:** 2026-09-29T11:24Z
- **Tasks:** 3 (Task 1 TDD with RED and GREEN commits; Tasks 2 and 3 auto)
- **Files:** 10 first-party files (7 created, 3 modified), plus `.gd.uid` files

## Accomplishments

- `DawnPayoutVfx` spawns coins per `dawn_payout(total, per_spot)`: one per gold, in MapConfig order, 0.08 s apart, from `unproject_position(plot + 2.5 up)`, a small pop then a 0.6 s trip to the `%GoldLabel` centre, `coin_landed` on each arrival, then `%PayoutTotal` "+X gold" for 2 s. A 0 total does nothing.
- `Hud` displays `gold - pending hold coins - _payout_pending`, so the counter ticks up as coins land and ends exactly on Economy gold. The Economy itself is credited at the start of dawn, unchanged.
- `tools/screenshot.sh` runs `ShotRunner` (windowed, real renderer) for `day_overview`, `spot_label`, `build_in_progress`, `night_banner`, `dawn_payout` and `overlay_on`. Scenes are driven by BuildIntent/StartNightIntent and `action_build` / `toggle_debug_overlay` presses. `--headless` exits 2; a blank or near-uniform frame exits 1 and is never saved.
- CI job `screenshots` (needs `test`) installs xvfb and Mesa, runs the same wrapper with `DUSKHOLD_SCREENSHOT_COMPAT=1` (Compatibility renderer, OpenGL 3) and uploads `duskhold-screenshots` (7 days, `if-no-files-found: error`).
- First push of the plan went green with no fix cycles: run 36561004973.

## Task Commits

1. **Task 1: Visible dawn payout** - RED `22ac829` (test), GREEN `06eed6d` (feat), follow-up `a00d977` (fix: round coins)
2. **Task 2: Scripted screenshot capture** - `a0cd33d` (feat)
3. **Task 3: Screenshots CI job, push, green run** - `72d9f18` (feat)

**Plan metadata:** committed separately as `docs(01-10)` after this file.

## Publication and CI Record

- **Pushed:** `gsd/phase-01-foundation-day-loop` only, using the one-off gh credential helper from 01-03. `master`, tags and every other ref were not pushed. `bash tools/prepush_check.sh` passed first (59 commits, one author identity, clean credential scan).
- **CI run:** https://github.com/ABSAR07/duskhold/actions/runs/36561004973 (head `72d9f18`). Jobs: lint, test, export, screenshots, all success.
- **Artifacts:** `duskhold-windows`, `duskhold-screenshots` (6 PNGs), `gut-results`.

## Screenshots (each PNG opened with the Read tool)

Local (Windows, RTX 3060, Forward+):

- `day_overview`: castle with blue towers at the top, king on horseback in the middle, a House on each side of the screen (the left one at tier II, larger), "Gold: 23" and the "Hold N / (Y) to start Night 1" prompt with an empty fill bar.
- `spot_label`: king beside an empty sandy plot with a floating "House I / +1 gold at dawn" label and two dark (unpaid) cost coins; "Gold: 30". The title and effect lines overlap slightly.
- `build_in_progress`: king beside a blue tower plot, label "Tower I / Range 8.0 - Damage 2" with two of four cost coins filled gold, a coin just leaving the king; "Gold: 28".
- `night_banner`: the same scene in a dark cool blue with "Night 1 — no enemies yet" under the top edge and no start-night prompt; "Gold: 26".
- `dawn_payout`: three small gold coins in the air between the two Houses and the top-left counter, the HUD reads "Gold: 23" while the ledger holds 26; the light is a cool grey-green, only partly blended toward dawn.
- `overlay_on`: day scene with two empty plots and the debug panel at top right (FPS 26, Phase DAY, Day 1, Night 0, Gold 30, Buildings 0, Units 0, Enemies 0).

CI (Ubuntu, Mesa llvmpipe, Compatibility renderer; flatter and brighter than local, as expected):

- `day_overview`: same layout as local, brighter, saturated teal roofs, "Gold: 23".
- `spot_label`: same empty House plot and "House I" label, "Gold: 30".
- `build_in_progress`: Tower I label with two of four coins filled, "Gold: 28".
- `night_banner`: blue night mood with the banner text, "Gold: 26".
- `dawn_payout`: two coins visible mid-air (the software renderer runs slower, so the third had moved off frame or landed), "Gold: 23", darker dawn grade.
- `overlay_on`: debug panel showing FPS 6 (software rendering, first frames), Phase DAY, Gold 30.

## Files Created/Modified

- `ui/hud/dawn_payout_vfx.gd` - coin flights, per-spot counts, "+X gold" total
- `ui/hud/hud.tscn`, `ui/hud/hud.gd` - `DawnPayoutVfx` (run_bound), `%PayoutTotal`, `_payout_pending`
- `tests/e2e/test_dawn_payout.gd` - 5 tests on the real scene
- `tools/screenshot/shot_runner.tscn|gd`, `shot_scenarios.gd`, `tools/screenshot.sh` - capture tooling
- `tests/unit/test_shot_blank_check.gd` - 4 tests for the blank-image check
- `.github/workflows/ci.yml` - `screenshots` job

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `coin_landed` connected twice when a second map joins the tree**
- **Found during:** Task 1 (first full-suite run: `test_an_unaffordable_cost_is_red_and_an_affordable_one_is_not` failed with "Signal 'coin_landed' is already connected")
- **Issue:** `MapRoot._ready` calls `call_group(&"run_bound", &"bind_run", ...)`, which reaches every run_bound node in the tree. A test that spawns two maps re-binds the first HUD, and the new `coin_landed` connection goes to an object that outlives the run.
- **Fix:** `is_connected` guard in `Hud.bind_run`.
- **Files modified:** `ui/hud/hud.gd`
- **Commit:** 06eed6d

**2. [Rule 1 - Bug] Coins rendered as gold squares**
- **Found during:** Task 2 (reading `dawn_payout.png`)
- **Issue:** The two-stop radial gradient fills the whole square texture, so the corners were opaque.
- **Fix:** Three stops ending in a transparent rim so the texture reads as a disc.
- **Files modified:** `ui/hud/dawn_payout_vfx.gd`
- **Commit:** a00d977

**3. [Rule 2 - Missing critical] Unit test for the blank-image check**
- **Found during:** Task 2
- **Issue:** The plan's "fails on a blank image" guarantee had no test; a regression would silently save blank PNGs.
- **Fix:** `tests/unit/test_shot_blank_check.gd` (black, flat grey, one-pixel noise rejected; a varied image accepted).
- **Commit:** a0cd33d

**4. [Rule 3 - Blocking] Timing and wording adjustments**
- The plan's test wants `%PayoutTotal` visible 3.0 s after DAWN starts, but the total is shown 2.0 s after the last coin lands (about 0.76 s to 2.76 s) and dawn is 2.0 s long. The test waits for the total to appear, checks its text, then waits for the HUD to settle and for the total to hide.
- `get_spawned_count` counts coins actually launched (staggered), so the per-spot test waits 0.5 s rather than 2 frames.
- `dawn_payout` waits 0.45 s after DAWN begins (plan: 0.35 s) and upgrades house_2 once so three coins are in flight; `spot_label` and `build_in_progress` wait 1.2 s for the smoothed camera to settle before the shot.
- Workflow actions are `@v7` to match the existing jobs (the plan said `upload-artifact@v4`).

---

**Total deviations:** 4 (2 Rule 1 bugs, 1 Rule 2, 1 Rule 3 group of timing and wording adjustments)
**Impact on plan:** No scope change. All acceptance criteria hold.

## TDD Gate Compliance

Task 1 has a `test(01-10)` RED commit (`22ac829`) before its `feat(01-10)` GREEN commit (`06eed6d`). RED ran with a signature-only `DawnPayoutVfx` stub and the HUD nodes present: 4 of 5 tests failed on the planned assertions (no coins, HUD not lagging, wrong total text and total 0, per-spot counts 0) with no parse or load errors. `test_a_dawn_that_pays_nothing_shows_no_coins_and_no_total` passed in RED because the stub already produced "nothing"; it is kept as a regression guard for the empty dawn. `gsd_run check tdd-red-evidence` was not run (no record file persisted); the RED output was checked by hand. No refactor commit.

## Issues Encountered

- The dawn lighting mood eases over 1.0 s while a coin's trip is 0.6 s, so no capture has both coins in flight and the full orange dawn. The `dawn_payout` shot at 0.45 s shows the light still mostly night-coloured. Left as is (mood behaviour is asserted in 01-09's tests); flagged for the human check at verify-work.
- Cosmetic, out of scope: in `spot_label` the "House I" title overlaps the effect line below it.
- Overlay FPS reads 26 locally and 6 in CI at capture time (first seconds of a fresh process, software rendering in CI); not a performance measurement.
- A long multi-file shell heredoc was rejected by the shell tool; the files were written with the Write tool instead.
- Working copies of `hud.gd` and `dawn_payout_vfx.gd` are CRLF on disk; git normalises to LF on commit.
- Informational CI annotation: `ubuntu-latest` migrates to Ubuntu 26 from 2026-10-19; the screenshots job apt package names (`libglx-mesa0`) should be re-checked then, or the runner pinned to `ubuntu-24.04`.

## Known Stubs

None.

## Threat Flags

None. T-01-17 mitigated as planned: `bash tools/prepush_check.sh` passed before the push. T-01-16 and T-01-SC accepted as planned: the artifact holds only the game's own frames, and the apt install is on the ephemeral runner with a read-only token and no secrets.

## User Setup Required

None.

## Next Phase Readiness

- Phase 1 is complete and green on origin. Ready for `/gsd-verify-work 1`: the human checks are the feel of the dawn payout (coin size, timing, "+X gold" placement, half-blended dawn light), the six PNGs, and the earlier 01-09 D7 check.
- Phase 2 fills the same loop; `dawn_payout(total, per_spot)` stays the hook the payout VFX listens to, so a dawn rebuild or "rebuilt pays nothing" only changes what `_apply_dawn_payout` emits.
- Pushing needs the one-off gh credential helper from 01-03. GitHub's default branch is still the phase branch; the owner can switch it to `master` after merging.

## Self-Check: PASSED

- Files: `ui/hud/dawn_payout_vfx.gd`, `tests/e2e/test_dawn_payout.gd`, `tests/unit/test_shot_blank_check.gd`, `tools/screenshot.sh`, `tools/screenshot/shot_runner.tscn`, `shot_runner.gd`, `shot_scenarios.gd` all exist.
- Commits: `22ac829`, `06eed6d`, `a00d977`, `a0cd33d`, `72d9f18` in `git log`; `git rev-list --count abbfdfc..HEAD` reports 5.
- Acceptance criteria re-run: every grep passes; `bash tools/test.sh` 190/190 with test_dawn_payout and test_shot_blank_check in the JUnit XML; `bash tools/lint.sh` clean; `bash tools/screenshot.sh` saves 6 non-empty PNGs and `--headless` exits 2; CI run 36561004973 green with both artifacts and 6 PNGs downloaded.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*
