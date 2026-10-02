---
phase: 01-foundation-day-loop
verified: 2026-10-02T07:48:00Z
status: human_needed
score: 5/5 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/01-foundation-day-loop/01-01-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-01-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-02-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-02-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-03-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-03-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-04-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-04-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-05-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-05-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-06-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-06-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-07-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-07-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-08-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-08-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-09-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-09-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-10-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-10-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-11-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-11-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-12-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-12-SUMMARY.md"
  - ".planning/phases/01-foundation-day-loop/01-13-PLAN.md"
  - ".planning/phases/01-foundation-day-loop/01-13-SUMMARY.md"
  - "ASSETS.md"
  - "assets/attribution.json"
  - "assets/third_party/quaternius_horse/License.txt"
  - "data/tuning/loop_tuning.tres"
  - "export_presets.cfg"
  - "input/build_hold_controller.gd"
  - "input/start_night_hold_controller.gd"
  - "presentation/buildings/building_views.gd"
  - "presentation/camera/camera_rig.gd"
  - "presentation/king/king_model.tscn"
  - "presentation/map/map_root.gd"
  - "presentation/vfx/coin_drip_vfx.gd"
  - "presentation/vfx/xray_silhouette.gd"
  - "project.godot"
  - "simulation/buildings/building_system.gd"
  - "simulation/commands/command_processor.gd"
  - "simulation/defs/loop_tuning.gd"
  - "simulation/defs/map_config.gd"
  - "simulation/run/run_manager.gd"
  - "tests/e2e/test_build_hold_timing.gd"
  - "tests/e2e/test_camera_zoom.gd"
  - "tests/e2e/test_debug_overlay_toggle.gd"
  - "tests/e2e/test_king_ride.gd"
  - "tests/e2e/test_king_xray.gd"
  - "tests/unit/test_debug_overlay_registration.gd"
  - "tests/unit/test_input_map.gd"
  - "tests/unit/test_loop_tuning_contract.gd"
  - "tools/lint.sh"
  - "tools/screenshot.sh"
  - "tools/screenshot/shot_scenarios.gd"
  - "tools/test.sh"
  - "ui/hud/dawn_payout_vfx.gd"
  - "ui/hud/hud.gd"
  - "ui/overlay/debug_overlay.gd"
  - "ui/overlay/debug_overlay.tscn"
  - "ui/overlay/debug_overlay_model.gd"
  - "ui/world/spot_label.gd"
covered_digest: "v2:sha256:1bc07bbe717d6e4e73262a8bbdd85f9c64162c31d11de69a19bd633ae89b8f23"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 5/5
  gaps_closed:
    - "G-01-3 (UAT test 3, major): king hidden behind buildings, camera too close, no zoom (plans 01-11 and 01-12)"
    - "G-01-4 (UAT test 4, minor): build hold too short (plan 01-13)"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Debug overlay shows wave state and enemy/pathing information (DEV-03 full text)"
    addressed_in: "Phase 2"
    evidence: "ROADMAP Phase 1 SC5: 'wave state and enemy paths join it once nights have enemies in Phase 2'; Phase 2 SC3 requires 'the debug overlay shows live enemy counts, wave state, and enemy paths'"
advisory:
  - finding: "Gap-plan code and everything after 7ae173b is not pushed, so CI has not yet run the new tests or the seventh screenshot"
    category: other
    reason: "origin/gsd/phase-01-foundation-day-loop is at 7ae173b (green run 36835551706, four jobs). HEAD fe3dc81 is 24 commits ahead. `git diff 7ae173b HEAD -- .github` is empty, so the workflow is unchanged, but the 315-test suite and `Saved 7 of 7 screenshots` have only run locally. Not a must-have failure; a push will confirm."
    evidence_status: "git ls-remote, git rev-list --count 7ae173b..HEAD = 24, gh run list, git diff --stat on .github"
  - finding: "Open review findings WR-01 and WR-02 (01-REVIEW.md, ledger open: 6): test robustness of the new tests"
    category: other
    reason: "WR-01: test_build_hold_timing measures a _process-driven hold with wall-clock stamps and tight tolerances, so it could flake on a slow CI runner. WR-02: test_buildings_never_get_the_xray_pass discards the build results and could pass without checking any house. Both passed in this pass's full run; neither makes a truth false. They are OPEN, not addressed. 01-REVIEW-FIX.md belongs to the previous review."
    evidence_status: "01-REVIEW.md lines 66-112 and 01-REVIEW-DISPOSITION.md ledger (open: 6) read; test run 315/315"
  - finding: "Open review findings IN-01 to IN-04: CameraRig zoom exports not validated; MAX_FLIGHT_SECONDS is a redundant second source of truth; king_behind_keep never asserts the king is occluded; horse License.txt dates a 2026-10-01 statement under a 2026-09-29 heading"
    category: other
    reason: "Info-level, OPEN. The occlusion in the scripted shot was checked by me visually (cyan silhouette over the keep roof) but the scenario itself does not assert it."
    evidence_status: "01-REVIEW.md read; king_behind_keep.png viewed"
  - finding: "Horse licence risk is owner-accepted; the unmodified horse GLB is public in the repo (Git LFS) and ships in the export"
    category: other
    reason: "The earlier WR-01 wording defect is fixed in f84de3b: ASSETS.md lines 65-66 and License.txt lines 27-28 now say the unmodified GLB is in the public repo and the build, and that the owner accepts the risk (2026-10-01). `git check-attr filter` = lfs; export_presets.cfg exclude_filter is only 'tests/*, addons/gut/*, tools/*'. A licence verdict is a legal judgment I cannot make; the owner accepted it, so it is not a human item."
    evidence_status: "git log 3fa5e48..HEAD on ASSETS.md/assets, grep of the three records, git ls-files, git check-attr"
  - finding: "Phase is Mode: mvp but its goal is not in 'As a..., I want to..., so that...' form"
    category: other
    reason: "MVP narrowing could not be applied; verified as standard goal-backward against the roadmap contract."
    evidence_status: "ROADMAP.md Phase 1 goal text"
human_verification:
  - test: "Ride the king around the map at the new default camera distance, then hold the zoom keys (- and =, or keypad - and +, or right stick down and up) through the whole range"
    expected: "At spawn the castle and first ring of House plots frame comfortably around a king who is still readable at about 25 m; the zoom range (0.7x to 1.5x, 0.6 units/s) feels right and the king is neither too small zoomed out nor too close zoomed in"
    why_human: "Framing and zoom feel are the owner's judgment (UAT test 3 was a feel complaint). Scripted runs already prove: default is exactly 1.3x the UAT offset on the same angle, clamps at 0.7x and 1.5x, angle never changes, real key and stick events move it, deadzone, simulation untouched, spot labels keep their size (test_camera_zoom 11 tests, test_king_ride 10 tests, test_input_map 12 tests)"
  - test: "Ride behind the castle keep (and a House) and look at the king in a real window, by day and by night"
    expected: "The hidden part of the king shows as a flat light-cyan silhouette over the building, reads as 'the king is here', and is not distracting or ugly (the rider/horse silhouette looks thin and stalk-like from above in the king_behind_keep capture)"
    why_human: "Whether the silhouette look is acceptable is aesthetic. Already covered: stencil X-Ray set on every king surface, shared materials untouched, buildings do not get the pass, king in the open unchanged (test_king_xray 5 tests), and the king_behind_keep screenshot, viewed by me, shows the cyan silhouette through the keep roof"
  - test: "Hold the action key at a House plot (House I, then II and III) and at a tower plot, and release early once"
    expected: "At 0.3 s per coin the hold (House I about 0.6 s, tower I about 1.2 s) feels 'a bit longer' and deliberate without dragging; the coin stream still reads as one coin at a time"
    why_human: "Hold feel is the owner's judgment (UAT test 4). Already covered: tuning data and script default are 0.3, flight cap 0.27 s, House I hold lasts cost x interval in the real scene, every shipped hold is at least 0.5 s, early release refunds everything (test_loop_tuning_contract 4 tests, test_build_hold_timing 3 tests)"
---

# Phase 1: Foundation & Day Loop Verification Report

**Phase Goal:** A Godot 4.7.2 project where, on the prototype map, the player rides the king by day and spends scarce gold on Houses and a basic tower, earning income from one day to the next. From the first commit, the agent can lint, test, screenshot, and export the game headlessly on every push.
**Verified:** 2026-10-02T07:48:00Z
**Status:** human_needed (every automated check passes and no must-have fails; what remains is owner feel and look judgment of the three UAT-gap fixes)
**Re-verification:** Yes, after UAT gap closure. The previous report (2026-10-01T08:08:30Z) was stale because covered files changed. Every verdict below was regenerated from the current tree at HEAD fe3dc81; none was copied.

## Change audit since the previous report

- UAT (`01-UAT.md`, status `diagnosed`, 55 tests: 52 pass, 1 skipped, 2 issues). The two issues are G-01-3 (camera) and G-01-4 (hold length). Plans 01-11, 01-12 and 01-13 carry `gap_closure: true` and the matching `gap_ids`; all three have SUMMARYs. The skipped test is the non-QWERTY key label: the owner chose to skip it on 2026-10-02 with a stated reason, so it is no longer an open human item (the fake-layout resolver seam is unit-tested).
- `git diff --stat 7ae173b HEAD -- . ':!.planning'` touches 21 files: camera rig, spot label, X-Ray script and king model, coin drip VFX, loop tuning (data and script), `project.godot` (two actions), screenshot scenario and wrapper, and the new and extended tests. `.github`, `assets`, `ASSETS.md` and `export_presets.cfg` are unchanged since 7ae173b.
- Review-fix pass 26 (f84de3b, 49fb595, 70f4030) edited horse-licence and checksum documentation only.
- The only working-tree modification is `.planning/config.json`.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | During the day the player rides the mounted king (WASD / stick, sprint) under a following isometric-style camera; near each fixed spot sees what can be built and its gold cost | VERIFIED (feel: human) | `presentation/camera/camera_rig.gd` read: `offset = (0, 20.8, 14.3)` = exactly 1.3x the UAT (0, 16, 11) on the same angle; `look_at` is called only in `bind_run`; `_physics_process` reads `Input.get_axis(zoom_in, zoom_out)`, clamps `_zoom` to [0.7, 1.5] and lerps the rig toward king + `get_effective_offset()`. `project.godot` defines `zoom_in` (= , keypad +, right stick up) and `zoom_out` (- , keypad -, right stick down), keyboard and `InputEventJoypadMotion` axis 3 only, no mouse. `ui/world/spot_label.gd` scales labels by camera distance over `LEGIBLE_CAMERA_DISTANCE` 16.9 (never below 1.0) so the approved on-screen size holds. King, camera-zoom, input-map and label tests pass in the 315/315 run. `king_behind_keep.png` and `day_overview.png` (both viewed) show the king, castle, HUD `Gold: 23` and plots at the new framing. |
| 2 | Holding the action key near a spot, with a visible progress indicator, builds a House or basic tower, or upgrades it after showing the next tier cost and effect; only when affordable, only on build spots, never at night | VERIFIED | Unchanged code path from the prior pass (`command_processor.gd` `validate_build` checks NOT_DAY, UNKNOWN_SPOT, MAX_TIER, CANNOT_AFFORD; `try_spend` before `apply_next_tier`). `input/build_hold_controller.gd` line 95 drips one coin per `maxf(coin_drip_interval, MIN_DRIP_INTERVAL)`; `data/tuning/loop_tuning.tres` and the `simulation/defs/loop_tuning.gd` default both read 0.3; `coin_drip_vfx.gd` caps flight at `MAX_FLIGHT_SECONDS = 0.27` (0.9 x 0.3). Build, upgrade, affordability, range, NOT_DAY, refund, hold-timing and tuning-contract tests pass (test_build_hold_timing 3, test_loop_tuning_contract 4). |
| 3 | Gold is the only currency and always on the HUD; ending the day through the placeholder transition leads to dawn where each House pays tier-scaled income and unspent gold carries over | VERIFIED | `run_manager` dawn payout, HUD lag and carryover unchanged since the prior verification and covered by the dawn income, payout VFX, HUD lag release, carryover and start-night hold tests in the full run. `dawn_payout.png` regenerated locally (7 of 7). UAT tests 9 and 10 (scripted real-window run, 2026-10-02) show two House I paying 2 coins and the HUD counting 0 -> 1 -> 2 as coins landed. |
| 4 | From the command line and in CI on every push: lint plus headless GUT cover economy, building rules, transitions; scripted scenes export screenshots; CI produces a Windows export | VERIFIED (new code not yet CI-run, see Advisory) | Local: `bash tools/lint.sh` exit 0 (77 files unchanged, no problems); `bash tools/test.sh` run once, exit 0, 40 scripts, 315/315, 2095 asserts, 117 s; `bash tools/screenshot.sh` exit 0, `Saved 7 of 7 screenshots` (day_overview, spot_label, build_in_progress, night_banner, dawn_payout, overlay_on, king_behind_keep). CI: `ci.yml` unchanged since 7ae173b; trigger is push (any branch or tag), pull_request, workflow_dispatch; run 36835551706 on 7ae173b is success in all four jobs. That run predates the gap-plan code, so CI has not run the 315 tests or the seventh shot. `tools/screenshot.sh` and `ALL_SHOTS` in `shot_scenarios.gd` both list seven shots, and `ci.yml` runs `bash tools/screenshot.sh` with no hard-coded count. |
| 5 | A key toggles a debug overlay with FPS, unit/enemy counts and loop state; every third-party asset is in the attribution log | VERIFIED | Overlay files, toggle, cadence and registration tests unchanged and passing; `overlay_on.png` regenerated; UAT test 8 verified in a real window. `assets/attribution.json` and `ASSETS.md` list the engine, GUT, three Kenney packs and the Quaternius horse; `test_attribution_log` passes. No new third-party asset was added by the gap plans. Wave state and enemy paths are deferred to Phase 2 by the roadmap's own wording. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

### Gap-plan must-haves (plans 01-11, 01-12, 01-13)

| Must-have | Status | Evidence |
|-----------|--------|----------|
| Default camera 1.3x farther on the same angle | VERIFIED | 20.8/16 = 14.3/11 = 1.3 in `camera_rig.gd`; `test_king_ride` follow tests use `get_effective_offset()`; `test_camera_zoom` asserts the default framing |
| Clamped keyboard and gamepad zoom, no mouse, angle fixed, bindings shared with no other action | VERIFIED | `project.godot` zoom bindings read; `test_input_map` (12 tests) and `test_camera_zoom` (11 tests) pass, including real key and stick events and deadzone |
| Spot labels keep approved on-screen size at default and fully zoomed out | VERIFIED | `spot_label.gd` `_process` scale; label-size test in `test_camera_zoom` |
| Zoom is presentation only | VERIFIED | `camera_rig.gd` never references the simulation or command layer; simulation-untouched test passes |
| Hidden part of the king drawn as an unlit cyan silhouette; king unchanged in the open; only the king, shared materials untouched | VERIFIED (look: human) | `xray_silhouette.gd` duplicates each BaseMaterial3D surface, sets `STENCIL_MODE_XRAY` and `stencil_color`, applies via `set_surface_override_material`; `king_model.tscn` has the `XRay` child as last node; `test_king_xray` (5 tests) pass; `king_behind_keep.png` viewed |
| Seventh screenshot `king_behind_keep` captured locally and in CI, fails if the silhouette is not set up | VERIFIED locally; CI not yet run | scenario returns false when `get_applied_count() <= 0`; local 7 of 7 saved. See Advisory (IN-03: it does not assert occlusion) |
| Coin drip 0.3 s; House I 0.6 s, tower I 1.2 s; flight 0.27 s; proportional, refund on early release; every hold >= 0.5 s | VERIFIED | tuning data and default 0.3, cap 0.27; `test_loop_tuning_contract` and `test_build_hold_timing` pass |

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Overlay wave state and pathing info (full REQUIREMENTS DEV-03 wording) | Phase 2 | Phase 2 SC3: "the debug overlay shows live enemy counts, wave state, and enemy paths" |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `presentation/camera/camera_rig.gd` | Fixed-angle follow rig, clamped zoom, 1.3x default | VERIFIED | Substantive, instanced by the map, bound via `bind_run`, driven by real input actions |
| `project.godot` | `zoom_in` / `zoom_out` actions | VERIFIED | Keyboard + stick only |
| `ui/world/spot_label.gd` | Distance compensation | VERIFIED | Uses `get_viewport().get_camera_3d()` |
| `presentation/vfx/xray_silhouette.gd` (+ `.uid`) | Stencil X-Ray on every king surface | VERIFIED | Wired through `king_model.tscn` `XRay` node |
| `presentation/king/king_model.tscn` | XRay node | VERIFIED | Last child, `stencil_color` set |
| `presentation/vfx/coin_drip_vfx.gd`, `data/tuning/loop_tuning.tres`, `simulation/defs/loop_tuning.gd` | 0.3 s drip, 0.27 s flight cap | VERIFIED | Values read |
| `tools/screenshot/shot_scenarios.gd`, `tools/screenshot.sh` | Seven-shot list | VERIFIED | 7 of 7 saved |
| New tests (`test_camera_zoom`, `test_king_xray`, `test_build_hold_timing`, `test_loop_tuning_contract`) and `.uid` files | Real-scene proofs | VERIFIED | Present, tracked, 11 + 5 + 3 + 4 tests pass |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `camera_rig.gd` | `project.godot` | `Input.get_axis(&"zoom_in", &"zoom_out")` | WIRED | Actions exist; real-event test moves the camera |
| `test_king_ride.gd` | `camera_rig.gd` | `get_effective_offset()` | WIRED | |
| `spot_label.gd` | active Camera3D | `get_camera_3d()` distance scale | WIRED | |
| `king_model.tscn` | `xray_silhouette.gd` | `XRay` child script | WIRED | |
| `xray_silhouette.gd` | king MeshInstance3D surfaces | `set_surface_override_material` | WIRED | |
| `shot_scenarios.gd` | `xray_silhouette.gd` | `get_applied_count()` | WIRED | |
| `build_hold_controller.gd` | `loop_tuning.tres` | `coin_drip_interval` | WIRED | |
| `coin_drip_vfx.gd` | `loop_tuning.tres` | `_flight_seconds()` | WIRED | |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Camera rig | `_zoom` | `Input.get_axis` each physics tick | Yes | FLOWING |
| Spot label scale | camera distance | live `Camera3D` position | Yes | FLOWING |
| X-Ray silhouette | surface materials | king's imported GLB meshes at runtime | Yes (`get_applied_count() > 0`) | FLOWING |
| Coin drip | `coin_drip_interval` | `loop_tuning.tres` via `ctx.tuning` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Lint | `bash tools/lint.sh` | exit 0, 77 files unchanged, no problems | PASS |
| Full suite (run once) | `bash tools/test.sh` | exit 0, 40 scripts, 315/315, 2095 asserts | PASS |
| Gap-plan test scripts | JUnit `gut-junit.xml` | zoom 11, xray 5, hold timing 3, tuning contract 4, input map 12, king ride 10, 0 failures | PASS |
| Seven scripted screenshots | `bash tools/screenshot.sh` | exit 0, `Saved 7 of 7 screenshots` | PASS |
| Silhouette visible | Read `screenshots/king_behind_keep.png` | cyan king silhouette over the keep roof | PASS |

### Probe Execution

Step 7c: SKIPPED. No phase plan declares a `probe-*.sh`, and `scripts/*/tests/probe-*.sh` does not exist; the verification entry points are `tools/lint.sh`, `tools/test.sh` and `tools/screenshot.sh`, run above.

### Requirements Coverage

All 15 phase IDs appear in REQUIREMENTS.md as Phase 1 / Complete and in at least one plan's `requirements:` field. No orphaned Phase 1 requirement.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| KING-01 | 01-02, 01-04 | Move the mounted king with WASD / left stick, sprint | SATISFIED | input map, king ride tests |
| KING-02 | 01-04, 01-11, 01-12 | Camera follows the king from a fixed isometric-style angle | SATISFIED | rig fixed `look_at`, zoom only along the offset direction, X-Ray keeps the king visible; feel is a human item |
| BLDG-01 | 01-02, 01-05 | Fixed build spots; buildings only on spots | SATISFIED | validate_build UNKNOWN_SPOT tests |
| BLDG-02 | 01-05, 01-06 | Near a spot by day, see what can be built and its cost | SATISFIED | spot label and its scale compensation |
| BLDG-03 | 01-02, 01-06, 01-13 | Build by holding the action key, with visible progress, if affordable | SATISFIED | hold controller at 0.3 s per coin; timing tests |
| BLDG-04 | 01-05, 01-13 | Upgrade the same way, showing next tier cost and effect | SATISFIED | tier tests, label model |
| BLDG-06 | 01-09 | Build and upgrade only by day | SATISFIED | NOT_DAY validation |
| ECON-01 | 01-02, 01-09 | Gold is the only currency; HUD shows it | SATISFIED | HUD, economy tests |
| ECON-02 | 01-09, 01-10 | House pays flat income each dawn that rises with tier | SATISFIED | dawn income tests |
| ECON-07 | 01-09 | Unspent gold carries over | SATISFIED | carryover tests |
| ART-02 | 01-07 | Third-party assets in an attribution log | SATISFIED | `ASSETS.md`, `attribution.json`, `test_attribution_log` |
| DEV-01 | 01-01, 01-02 | Headless simulation and GUT tests from the CLI | SATISFIED | 315/315 headless |
| DEV-02 | 01-01, 01-03, 01-10 | CI lint and tests on every push, Windows export | SATISFIED | run 36835551706 green; trigger read; new code not yet pushed (Advisory) |
| DEV-03 | 01-08 | Toggleable debug overlay | SATISFIED (wave state and pathing deferred to Phase 2) | overlay tests, `overlay_on.png`, UAT test 8 |
| DEV-04 | 01-10, 01-12 | Automated screenshot capture of scripted scenes | SATISFIED | 7 of 7 locally |

### Anti-Patterns Found

TBD/FIXME/XXX grep on the gap-plan source and test files: no matches. No stubs: the camera rig, X-Ray script, coin drip and tuning are all substantive and wired. Open review findings WR-01, WR-02, IN-01 to IN-04 are test-robustness and doc items (see Advisory); none is a blocker.

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `tests/e2e/test_build_hold_timing.gd` | - | wall-clock stamps with tight tolerances (review WR-01, OPEN) | Warning | possible CI flake; passed locally |
| `tests/e2e/test_king_xray.gd` | - | discarded build results (review WR-02, OPEN) | Warning | the test could pass vacuously; the silhouette itself is proven by the other tests and the screenshot |

### Human Verification Required

Only the owner's feel and look judgments strictly need a human (the frontmatter lists them in full):

1. **Camera framing and zoom range** at the new 1.3x default and the 0.7x to 1.5x range.
2. **Look of the king silhouette** through the keep and Houses, by day and night.
3. **Feel of the 0.3 s per-coin build hold.**

Everything else is covered by scripted evidence (tests, real-window UAT runs and screenshots). The non-QWERTY label check was skipped by the owner on 2026-10-02 and the horse licence and CI trigger decisions were accepted by the owner, so none of them is raised again.

### Gaps Summary

No gaps. Both UAT issues are closed in code, by named tests and by the screenshot. The remaining risk is that the gap-plan code has not been pushed, so CI has not yet exercised the 315 tests or the seventh screenshot.

---

_Verified: 2026-10-02T07:48:00Z_
_Verifier: Claude (gsd-verifier)_
