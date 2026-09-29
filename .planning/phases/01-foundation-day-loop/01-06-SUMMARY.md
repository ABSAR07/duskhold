---
phase: 01-foundation-day-loop
plan: 06
subsystem: hold-to-build-feedback
status: complete
tags: [godot, gdscript, gut, hold-to-build, spot-label, coin-drip, hud, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "01-02 BuildHoldController, CommandProcessor, RunContext and E2eSupport; 01-04 detached CameraRig; 01-05 prototype map, tower and upgrade tiers"
provides:
  - "BuildHoldController hardened to D-05/D-06/D-08: focus locked to the active spot during a hold, cancel-with-refund on release, leaving range or the day ending, deny once per press edge, fresh press required after each completion"
  - "SpotLabelModel.describe(ctx, spot_id, coins_paid) -> Dictionary (title, cost, paid, effect, affordable, max_tier, status_line): pure label content"
  - "SpotLabel: world-space Label3D/Sprite3D label 3.2 m above the single focused spot, day only, coin icons fill as coins land, red when unaffordable, Max tier status, 0.3 s denied shake"
  - "CoinDripVfx: coin fly-in per drip and fly-back refund per cancelled coin, live_coin_count() for tests"
  - "Hud._pending: HUD shows Economy gold minus in-flight coins (display only)"
  - "E2eSupport.spawn_map and E2eSupport.wait_until shared test helpers"
affects: [01-08, 01-09, 01-10, phase-08-audio]

actuals:
  tokens: 14500
  tasks: 3
  commits: 6
plan_head_before: a36718131f6ba91631ac3611a17c04ebf6fc0765
plan_head_after: 17083eea5b511e7132478a2004c00735b7f9c656

tech-stack:
  added: []
  patterns:
    - "Presentation nodes join group run_bound and read the hold controller through map_root.get_build_hold() in bind_run"
    - "All UI/VFX state is derived from hold-controller signals plus SimEvents; the simulation is only ever touched by the one BuildIntent at completion"
    - "Scene tests slow the coin drip via a duplicated LoopTuning assigned to map_root.loop_tuning before add_child, so a test can act between coins deterministically"
    - "Removing a child before queue_free keeps get_child_count exact within the same frame"

key-files:
  created:
    - ui/world/spot_label_model.gd
    - ui/world/spot_label.gd
    - ui/world/spot_label.tscn
    - presentation/vfx/coin_drip_vfx.gd
    - tests/integration/test_build_hold_refund.gd
    - tests/e2e/test_build_denied.gd
    - tests/unit/test_spot_label_model.gd
    - tests/e2e/test_spot_label.gd
    - tests/e2e/test_coin_drip.gd
  modified:
    - input/build_hold_controller.gd
    - ui/hud/hud.gd
    - presentation/map/prototype_map.tscn
    - tests/e2e/e2e_support.gd

key-decisions:
  - "Hold start is edge-triggered (Input.is_action_just_pressed or a pressed-this-frame edge), so await-release after a completion needs no extra state and a denial fires once per press by construction"
  - "The day check (is_build_allowed) runs every frame ahead of any drip rather than inside the drip loop: the phase cannot change inside one frame's loop, so a coin never lands after building stops being allowed"
  - "SpotLabelModel.affordable is true when gold covers the cost OR coins_paid > 0 (a hold only starts when payable) and always true at max tier, so the red tint never shows on a running hold or a finished building"
  - "The single SpotLabel node is repositioned to the focused spot; the shake is a tweened _shake_x offset over a stored anchor so a re-focus mid-shake cannot leave the label displaced"
  - "Denied flash tweens Label3D.outline_modulate rather than modulate, so it never fights the red/normal cost tint"

patterns-established:
  - "Placeholder class in the RED commit (empty describe, 0-returning live_coin_count) so typed GDScript tests compile and fail on assertions, not parse errors"
  - "Forcing RunManager._phase in tests until plan 01-08 adds the real night transition"

requirements-completed: [BLDG-02, BLDG-03]

coverage:
  - id: D1
    description: "Hold is all-or-nothing: early release or leaving range refunds every dripped coin with gold and buildings unchanged; a later hold starts from zero and pays the tier cost once"
    requirement: "BLDG-03"
    verification:
      - kind: integration
        ref: "tests/integration/test_build_hold_refund.gd#test_early_release_refunds_every_dripped_coin_and_changes_nothing"
        status: pass
      - kind: integration
        ref: "tests/integration/test_build_hold_refund.gd#test_leaving_the_range_mid_hold_refunds_and_changes_nothing"
        status: pass
      - kind: integration
        ref: "tests/integration/test_build_hold_refund.gd#test_holding_again_after_a_cancel_pays_the_tier_cost_exactly_once"
        status: pass
    human_judgment: false
  - id: D2
    description: "Focus is locked to the active spot while holding, a completed hold needs a fresh press, and a hold is refunded if building stops being allowed"
    requirement: "BLDG-03"
    verification:
      - kind: integration
        ref: "tests/integration/test_build_hold_refund.gd#test_focus_stays_on_the_active_spot_while_holding"
        status: pass
      - kind: integration
        ref: "tests/integration/test_build_hold_refund.gd#test_keeping_the_key_held_after_a_completion_starts_no_new_hold"
        status: pass
      - kind: integration
        ref: "tests/integration/test_build_hold_refund.gd#test_a_hold_is_refunded_if_building_stops_being_allowed_mid_hold"
        status: pass
    human_judgment: false
  - id: D3
    description: "Unaffordable, max-tier and night presses emit hold_denied exactly once per press, with no hold_started/hold_progress and no gold movement"
    requirement: "BLDG-03"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_build_denied.gd#test_an_unaffordable_spot_is_denied_once_per_press_and_moves_no_coins"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_denied.gd#test_a_max_tier_building_is_denied_with_max_tier"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_build_denied.gd#test_pressing_at_night_is_denied_with_not_day"
        status: pass
    human_judgment: false
  - id: D4
    description: "Label content (next-tier name, cost, effect, affordability, Max tier) is computed purely from RunContext data"
    requirement: "BLDG-02"
    verification:
      - kind: unit
        ref: "tests/unit/test_spot_label_model.gd (9 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "A world-space label floats above only the nearest in-range spot by day, shows coin icons that fill as coins land, turns red when unaffordable, says Max tier, and shakes on a denied press"
    requirement: "BLDG-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_spot_label.gd (7 tests)"
        status: pass
    human_judgment: true
    rationale: "Automation proves the nodes, colours, positions and shake exist; whether the label is legible and well placed from the real gameplay camera at play distance is a visual judgement"
  - id: D6
    description: "Coins fly from the king into the spot per drip and fly back on refund; the HUD shows gold minus in-flight coins and restores the full amount on cancel"
    requirement: "BLDG-03"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_coin_drip.gd (4 tests)"
        status: pass
    human_judgment: true
    rationale: "Automation proves coin node counts and HUD text; whether the coin stream reads as a satisfying one-at-a-time drip (timing, size, glow) is a feel judgement"

duration: 14min
completed: 2026-09-29
---

# Phase 1 Plan 06: Hold-to-Build Feedback Summary

**Hold-to-build made readable and trustworthy: a hardened all-or-nothing hold controller (focus lock, refund on release/leave/night, deny once per press), a world-space spot label with coin-icon cost, red unaffordable tint and denied shake, and a coin-drip VFX with a HUD pending-gold display, all proven by 5 new test files (130/130 green).**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-29T09:57:05Z
- **Completed:** 2026-09-29T10:11:10Z
- **Tasks:** 3 (each RED then GREEN, no refactor commits needed)
- **Files modified:** 21 (13 source/scene/test files plus 8 `.gd.uid` files)

## Accomplishments

- The hold is all-or-nothing (D-06): cancelling by release, leaving the interaction radius or the day ending resets the drip and refunds every coin while Economy and buildings never change; a completed hold needs a fresh key press (BLDG-03).
- Denials (unaffordable, max tier, night) emit `hold_denied` exactly once per press with no coin movement, the silent SFX hook for Phase 8 (D-08).
- A single world-space `SpotLabel` shows the next tier name, the cost as coin icons that fill as each coin lands, and the effect line; red when unaffordable; "Max tier" at the top; hidden by night and when no spot is in range (BLDG-02, D-07).
- Coins fly one at a time from the king into the spot and fly back on refund (D-05/D-06 made visible); the HUD counts down `Economy gold - in-flight coins` and returns to the full amount on cancel.

## Task Commits

Each task followed RED then GREEN (RED evidence verified with `gsd_run check tdd-red-evidence` = `RED_EVIDENCE_OK` each time):

1. **Task 1: Harden hold semantics** - RED `3e5677c` (test), GREEN `5f4267a` (feat)
2. **Task 2: World-space spot label** - RED `ec5e7bf` (test), GREEN `bb1c3c5` (feat)
3. **Task 3: Coin-drip VFX and HUD pending gold** - RED `83f3ea6` (test), GREEN `17083ee` (feat)

**Plan metadata:** recorded in the `docs(01-06)` commit that follows this file.

## Files Created/Modified

- `input/build_hold_controller.gd` - focus locked during a hold, per-frame `is_build_allowed` and radius checks, edge-triggered start/deny
- `ui/world/spot_label_model.gd` - pure `describe()` label content
- `ui/world/spot_label.gd` / `spot_label.tscn` - world-space label with coin sprites (`GradientTexture2D` radial discs), red tint, Max tier, denied shake and flash
- `presentation/vfx/coin_drip_vfx.gd` - fly-in per drip, fly-back per refunded coin, `live_coin_count()`
- `ui/hud/hud.gd` - `_pending` coins subtracted from the displayed gold
- `presentation/map/prototype_map.tscn` - `SpotLabel` and `CoinDripVfx` nodes in group `run_bound`
- `tests/e2e/e2e_support.gd` - added `spawn_map()` and `wait_until()` shared helpers
- `tests/integration/test_build_hold_refund.gd` (6 tests), `tests/e2e/test_build_denied.gd` (3), `tests/unit/test_spot_label_model.gd` (9), `tests/e2e/test_spot_label.gd` (7), `tests/e2e/test_coin_drip.gd` (4)

## TDD Gate Compliance

Every task has a `test(01-06)` RED commit strictly before its `feat(01-06)` GREEN commit. No REFACTOR commits were needed. In Task 1, RED failed on the two behaviours the old controller lacked (focus lock, per-frame day check); the remaining Task 1 tests (leave-range refund, deny-once, await-release, max-tier deny) passed against the existing controller because 01-02 already had edge-triggered starts and cancel-on-focus-loss. They are kept as regression proof of the D-06/D-08 contract, and the GREEN commit changes controller behaviour only where the failing tests required. Tasks 2 and 3 used a placeholder class in the RED commit (empty `describe`, `live_coin_count` returning 0) so typed tests compile and fail on assertions rather than parse errors.

## Decisions Made

See `key-decisions` in the frontmatter. In short: edge-triggered starts, a per-frame (not per-loop-iteration) day check, `affordable` true on a running hold and at max tier, one repositioned label node with an anchored shake offset, and the denied flash on `outline_modulate`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Shared test helpers added to E2eSupport**
- **Found during:** Task 1 (writing the RED tests)
- **Issue:** Five scene tests each needed to instantiate the map with a swapped `MapConfig`/`LoopTuning` and poll a predicate; `tests/e2e/e2e_support.gd` is not in the plan's `files_modified`.
- **Fix:** Added `E2eSupport.spawn_map(test, map_config, tuning)` and `E2eSupport.wait_until(test, predicate, timeout_s)` rather than duplicating them in five files. Existing helpers are untouched.
- **Files modified:** `tests/e2e/e2e_support.gd`
- **Verification:** all 130 tests pass
- **Committed in:** 3e5677c

**2. [Minor plan interpretation] CoinDripVfx does not connect `hold_completed`**
- **Found during:** Task 3
- **Issue:** The plan says the VFX connects `hold_progress`, `hold_cancelled` and `hold_completed`, but completion needs no visual (the last coin already flew in on `hold_progress`), so a handler would be dead code.
- **Fix:** Connected only `hold_progress` and `hold_cancelled`. The HUD does connect `hold_completed` (it must reset `_pending`).
- **Files modified:** `presentation/vfx/coin_drip_vfx.gd`
- **Committed in:** 17083ee

---

**Total deviations:** 2 (1 blocking helper addition, 1 dead-code omission)
**Impact on plan:** No scope creep; both keep the codebase smaller and the tests less repetitive.

## Issues Encountered

- The `is_build_allowed` re-check and the night-hides-label/night-denies behaviours cannot be exercised through a real night transition until plan 01-08 lands. The tests force `RunManager._phase = NIGHT` (and emit `phase_changed` for the label test). When 01-08 adds `start_night`, these three tests can be switched to the real transition.
- The shared shell tool rejected two long heredocs; files were written with the Write tool instead. No effect on the result.

## Known Stubs

None. The RED-commit placeholders (`SpotLabelModel.describe` returning `{}`, `CoinDripVfx.live_coin_count` returning 0) were replaced with real implementations in the GREEN commits.

## Threat Flags

None. No new network endpoints, auth paths, file access or schema surface. T-01-11 (tampering with completion after leaving range, phase change or lost affordability) is mitigated as planned: focus lock plus per-frame radius and day checks, and `CommandProcessor.submit` re-validates at completion; the controller contains no `try_spend`, `apply_next_tier` or `grant(` (grep count 0).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 01-08 (night transition): the hold controller already cancels-with-refund when `is_build_allowed()` turns false, and the label already hides on `phase_changed`.
- Phase 8 audio can subscribe to `BuildHoldController.hold_denied` for the denied sound.
- Human check pending at phase verification (D5/D6 above): ride to each plot type in the real game and judge label legibility from the gameplay camera, and judge the coin stream's feel.

## Self-Check: PASSED

- Files: `ui/world/spot_label_model.gd`, `ui/world/spot_label.gd`, `ui/world/spot_label.tscn`, `presentation/vfx/coin_drip_vfx.gd`, `tests/integration/test_build_hold_refund.gd`, `tests/e2e/test_build_denied.gd`, `tests/unit/test_spot_label_model.gd`, `tests/e2e/test_spot_label.gd`, `tests/e2e/test_coin_drip.gd` all present.
- Commits: `3e5677c`, `5f4267a`, `ec5e7bf`, `bb1c3c5`, `83f3ea6`, `17083ee` all in `git log`; `git rev-list --count a36718131f..HEAD` (the plan ledger base) reports 6 commits.
- Acceptance criteria: `is_build_allowed` and `is_action_just_pressed` present in the controller; mutator grep count 0; `SpotLabelModel.describe` signature, `hold_denied`, `GradientTexture2D`, `SpotLabel` and `CoinDripVfx` scene entries, `live_coin_count`, `_pending` all present; `bash tools/test.sh` 130/130 with test_build_hold_refund, test_build_denied, test_spot_label_model, test_spot_label and test_coin_drip in the JUnit XML; `bash tools/lint.sh` clean.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*
