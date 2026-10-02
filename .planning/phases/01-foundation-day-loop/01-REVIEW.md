---
phase: 01-foundation-day-loop
reviewed: 2026-10-02T07:50:00Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - ASSETS.md
  - assets/attribution.json
  - assets/third_party/quaternius_horse/License.txt
  - data/tuning/loop_tuning.tres
  - presentation/camera/camera_rig.gd
  - presentation/king/king_model.tscn
  - presentation/vfx/coin_drip_vfx.gd
  - presentation/vfx/xray_silhouette.gd
  - presentation/vfx/xray_silhouette.gd.uid
  - project.godot
  - simulation/defs/loop_tuning.gd
  - tests/e2e/test_build_hold_timing.gd
  - tests/e2e/test_build_hold_timing.gd.uid
  - tests/e2e/test_camera_zoom.gd
  - tests/e2e/test_camera_zoom.gd.uid
  - tests/e2e/test_king_ride.gd
  - tests/e2e/test_king_xray.gd
  - tests/e2e/test_king_xray.gd.uid
  - tests/unit/test_input_map.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_loop_tuning_contract.gd.uid
  - tools/screenshot.sh
  - tools/screenshot/shot_scenarios.gd
  - ui/world/spot_label.gd
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-10-02T07:50:00Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed the pass-26 documentation fixes (horse licence records, ASSETS.md) and the three UAT gap-closure
plans (01-11 zoom and framing, 01-12 X-Ray silhouette, 01-13 drip interval).

No correctness or security defects in the shipped code. Checked specifically:

- **KING-02.** `look_at` is called only in `CameraRig.bind_run`. Zoom scales `offset` along its fixed direction, and `Input.get_axis(zoom_in, zoom_out)` has the right sign. Stick up gives -1 and moves the camera closer.
- **Input Map.** Both new actions have keyboard (physical keycodes), keypad and right-stick bindings, no mouse binding and no shared binding. The keycode values 61, 45, 4194437 and 4194435 are `KEY_EQUAL`, `KEY_MINUS`, `KEY_KP_ADD` and `KEY_KP_SUBTRACT`.
- **Presentation only.** Zoom touches no simulation state.
- **X-Ray.** It duplicates the active material and writes it as a surface override. The shared imported material is never mutated, and the test proves it.
- **Label scale.** The 16.9 m constant is correct arithmetic: sqrt(12.8^2 + 11^2 + 0.5^2) = 16.88.
- **Flight cap.** The 0.27 s cap equals 0.9 x 0.3 s, so coins still land before the next one leaves.
- **Screenshot.** The `king_behind_keep` capture shows the cyan silhouette through the keep roof.
- **Licence docs.** The repository, LFS and public-repo statements match `git remote` and `git lfs ls-files`.

The remaining findings are test-reliability and maintainability items. Two warnings, four info.

## Warnings

### WR-01: Hold-timing test measures physics-rate behaviour with wall-clock stamps and tight tolerances

**File:** `tests/e2e/test_build_hold_timing.gd:15-17, 22-24, 71-84`
**Issue:** `BuildHoldController` advances in `_process(delta)` with the real, variable frame delta, and
its `while _drip_timer >= interval` loop emits every overdue coin in the same frame. The test stamps each
`hold_progress` with `Time.get_ticks_usec()`. After any frame hitch longer than about 50 ms (CI
contention, GC, first-use allocation), two things can happen:

- Consecutive coins get nearly identical timestamps, so a gap of about 0 s fails `GAP_TOLERANCE_S`
  (0.05 s) in `test_coins_drip_one_per_interval`.
- The whole hold can complete more than `EARLY_TOLERANCE_S` (0.02 s) sooner than the wall-clock
  `cost x interval` in `test_house_one_hold_lasts_cost_times_the_drip_interval`.

The tolerances are a bit over one frame (16.7 ms), so the suite is correct only while no frame stalls.
It passes today (315/315), but it is a latent flake that will show up on a slow runner.

**Fix:** Make the assertions independent of frame hitches. For example:

- Record the accumulated `delta` instead of wall time. Connect to `get_tree().process_frame` and sum
  `get_process_delta_time()`, or stamp each coin with the engine process time.
- Assert the invariant directly: the Nth coin is never emitted before `N x interval` of accumulated
  frame time, and the total count equals the cost.
- Or widen `EARLY_TOLERANCE_S` and `GAP_TOLERANCE_S` to a fraction of `coin_drip_interval`
  (for example 0.5 x) and keep the `MIN_HOLD_S` contract in the unit test, which is deterministic.

### WR-02: `test_buildings_never_get_the_xray_pass` can pass without checking any house

**File:** `tests/e2e/test_king_xray.gd:88-108`
**Issue:** The three `ctx.commands.submit(BuildIntent.new(spot_id))` results are discarded, and the
only guards are "CastleCenter exists" and `checked > 0`. The castle alone satisfies both. If the
submits are rejected (gold, phase, a changed spot id) and no house view exists, the test passes
without ever checking a house, so it cannot catch an X-Ray pass leaking onto the building models it
exists to protect. The header comment ("buildings must not show through each other") overstates what
is asserted.

**Fix:** Assert each submit returned `CommandProcessor.OK` and that the views node has a child per
built spot before iterating:
```gdscript
for spot_id: StringName in HOUSE_SPOTS:
	assert_eq(ctx.commands.submit(BuildIntent.new(spot_id)), CommandProcessor.OK, str(spot_id))
await wait_process_frames(1)
for spot_id: StringName in HOUSE_SPOTS:
	assert_not_null(views.get_node_or_null(String(spot_id)), "%s has a view" % spot_id)
```
(Use the real view-node naming the views use.)

## Info

### IN-01: `CameraRig` zoom exports are not validated

**File:** `presentation/camera/camera_rig.gd:15-19, 29, 47`
**Issue:** `zoom_min`, `zoom_max` and `zoom_speed` are plain `@export`s. A tuning mistake of
`zoom_min <= 0` puts the rig on or inside the king, and `look_at` with a zero-length direction errors.
`zoom_min > zoom_max` makes `clampf` ill-defined. Both are only reachable by editing the scene, so
this is low risk.
**Fix:** In `bind_run`, `assert(zoom_min > 0.0 and zoom_min <= zoom_max)` or use
`@export_range(0.1, 1.0)` and `@export_range(1.0, 3.0)`.

### IN-02: `MAX_FLIGHT_SECONDS` is now a redundant second source of truth

**File:** `presentation/vfx/coin_drip_vfx.gd:13-18, 58`
**Issue:** At the shipped 0.3 s interval, `0.9 x interval` equals `MAX_FLIGHT_SECONDS` (0.27), and 0.3 s
is also the top of D-05's range (enforced by `test_loop_tuning_contract`). The cap can therefore never
bind for any legal interval. It is a magic number that must be hand-edited whenever the interval is
re-tuned, which is exactly what plan 01-13 had to do. The contract test guards it, but only after the
fact.
**Fix:** Drop the cap and use `interval * FLIGHT_FRACTION_OF_INTERVAL`. If a hard cap is wanted, derive
it from the D-05 maximum rather than a separate literal.

### IN-03: `king_behind_keep` scenario never verifies the king is actually occluded

**File:** `tools/screenshot/shot_scenarios.gd:8-10, 126-136`
**Issue:** `BEHIND_KEEP_OFFSET = (0, 0, -5)` encodes the keep's footprint and the camera angle in a
literal, and the comment records a "1.4 m past the far wall" figure that is not read from the map. The
scenario returns true whenever the XRay node exists and `get_applied_count() > 0`. If the keep model,
camera offset or zoom default changes, the shot silently stops showing the occluded case while still
exiting 0. The current capture is correct.
**Fix:** Derive the position from the keep's footprint, or check occlusion (for example a
`PhysicsRayQuery` from `camera.global_position` to the king that hits a building collider). Fail the
shot if no occluder is hit.

### IN-04: Horse `License.txt` puts a 2026-10-01 statement under a 2026-09-29 heading and records a guess

**File:** `assets/third_party/quaternius_horse/License.txt:21-28, 36-39`
**Issue:**
- The new sentence "The owner also accepts this risk (2026-10-01)" sits inside the "Licence evidence
  (checked 2026-09-29)" section. The file's dated structure is now inconsistent.
- The re-check note asserts that the colon "may have" come from a web-to-markdown fetch and that
  "neither quote has been altered". Both are unverifiable statements in an evidentiary licence record.
  They are harmless, since both quotes name CC0, but they read as speculation.

**Fix:** Move the owner-acceptance sentence under the "Decision (2026-10-01)" heading, where it is
already stated. Reduce the note to the verifiable fact: "the quote differs by a colon; both name CC0".

---

_Reviewed: 2026-10-02T07:50:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
