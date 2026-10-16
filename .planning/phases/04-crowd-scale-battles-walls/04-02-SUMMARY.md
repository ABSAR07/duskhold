---
phase: 04-crowd-scale-battles-walls
plan: 02
subsystem: rendering
tags: [godot, multimesh, gdscript, shader, crowd, presentation, mesh-baking, tdd, ci]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: CrowdBatch, HealthBarBatch, crowd_instance.gdshader and the ShotRunner one-frame wait (plan 04-01)
  - phase: 03-king-combat-troops
    provides: UnitViews puppets, SelectionRings, SelectionController, the 33 shipped screenshots
provides:
  - MeshBaker (bake a model scene's skinned or static meshes into one ArrayMesh; append_primitive), reused by plan 04-05 for the wall model
  - UnitViews drawn as one CrowdBatch per unit type with baked Kenney meshes (capsule fallback headless), a shared hurt-only bar batch, MAX_VIEWS 256 in total
  - ProjectileVfx arrows as instances of one 512-slot ring batch, arrow_transform pose helper, per-instance sRGB colour
  - has_view / puppet_position / mesh_source_of / bar_ratio_of hooks replacing UnitViews.get_view
  - Evidence that the instance shaders and baked meshes render on CI's Mesa software renderer (RESEARCH A2): green CI run for HEAD, 33 screenshots
affects: [04-03 hot-path pass, 04-05 wall model (MeshBaker), 04-09 stress scene and frame report, 08 art pass and night readability]

actuals:
  tokens: 15500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Skinned Kenney characters are baked once per type with bake_mesh_from_current_skeleton_pose and drawn through a MultiMesh with the surface materials kept (no material override)"
    - "A batch whose instance colours carry authored sRGB colours converts them to linear in the shader (instance colour arrives linear)"
    - "Ring of flights in parallel packed arrays; per frame the live slots are written to a CrowdBatch in slot order and uploaded once; an idle frame after an idle frame uploads nothing"
    - "MeshBaker skips the skinned bake on the headless display server instead of calling it, so tests see no engine error and fall back to the capsule"

key-files:
  created:
    - presentation/crowd/mesh_baker.gd
    - tests/unit/test_mesh_baker.gd
  modified:
    - presentation/units/unit_views.gd
    - presentation/units/selection_rings.gd
    - input/selection_controller.gd
    - presentation/vfx/projectile_vfx.gd
    - presentation/crowd/crowd_instance.gdshader
    - tests/e2e/test_unit_views.gd
    - tests/e2e/test_squad_tracer_scene.gd
    - tests/e2e/test_projectiles_visible.gd
    - tests/unit/test_projectile_vfx.gd

key-decisions:
  - "MeshBaker returns null without calling the skinned bake on the headless display server: the call logs an engine error there, which GUT counts as a test failure, and the dummy renderer returns no pose anyway"
  - "Unit batches use no material override and no instance colours: the baked surfaces keep the Kenney materials, which read no vertex colour, so Compatibility draws them correctly (checked locally and on CI)"
  - "crowd_instance.gdshader converts the instance tint from sRGB to linear: arrows passed their authored sRGB colours and drew washed out; enemies pass white so nothing else moved"
  - "ProjectileVfx gains arrow_launch_at(index) beyond the plan interface, so the castle-shot test can still prove the keep-top launch point now that no node carries a position"
  - "Task 3's verify compares the latest CI run to HEAD: that holds at 3c8f69e, the pushed commit; the SUMMARY and state commits that follow stay local, as the plan allows one push only"

patterns-established:
  - "A unit or arrow view's hooks read the batch mirror (has_view, puppet_position, arrow_count, arrow_color_at), never the MultiMesh"
  - "Ids drawn this frame are kept ascending in a mirror and found with a binary search"

requirements-completed: [PLAT-01]

duration: 60min
completed: 2026-10-16
status: complete
commits: 3
plan_head_before: b09ef6d5c85ed08dbc8e87e7ad6cf21f4f5b8dab
plan_head_after: 3c8f69e7f6c2e00bee6270f5a5b8cac07422b57d

coverage:
  - id: D1
    description: "Every living friendly unit is one instance of its type's batch, interpolated by RunContext.alpha(); UnitViews holds only batches; headless the types wear the capsule, in a real window the baked character-male-a and character-female-a with sword or bow merged in"
    requirement: PLAT-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_unit_views.gd#test_every_living_unit_is_one_batch_instance_and_no_node_stands_per_unit"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_unit_views.gd#test_each_type_has_its_own_batch_and_headless_wears_the_capsule"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_unit_views.gd#test_a_drawn_unit_stays_within_a_step_of_the_simulation"
        status: pass
      - kind: unit
        ref: "tests/unit/test_mesh_baker.gd (7 tests)"
        status: pass
      - kind: automated_ui
        ref: "bash tools/screenshot.sh hud_day_squads (real window, Forward+ and Compatibility, baked models with sword and bow)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A hurt unit shows a hurt-only bar filled to hp / max health from the shared bar batch and the dawn restore hides it; selection, box-select, control groups, order markers and mouse commands work unchanged on has_view and puppet_position"
    requirement: PLAT-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_unit_views.gd#test_a_hurt_unit_shows_a_bar_filled_to_its_health_until_the_dawn_restore"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_squad_selection.gd, test_box_select.gd, test_control_group_keys.gd, test_order_markers.gd (unchanged, in the 1469-test full run)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Arrows from towers, the castle, skirmishers and archers fly as instances of one 512-slot ring batch with the same flight time, arc and colours, retargeting the victim each frame; slashes stay nodes capped at 8; a shot with 512 in the air is not drawn"
    requirement: PLAT-01
    verification:
      - kind: unit
        ref: "tests/unit/test_projectile_vfx.gd#test_the_projectile_cap_is_512"
        status: pass
      - kind: unit
        ref: "tests/unit/test_projectile_vfx.gd#test_an_arrow_starts_at_the_origin_and_lands_on_the_target"
        status: pass
      - kind: unit
        ref: "tests/unit/test_projectile_vfx.gd#test_the_arrow_basis_is_orthonormal_along_the_flight_direction"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_projectiles_visible.gd#test_a_flood_of_shots_never_passes_the_cap_and_all_of_them_drain"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_projectiles_visible.gd (tower, skirmisher, castle, king slash)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Presentation never touched the simulation: smoke and army goldens byte-identical, full_idle replays twice to f417c7f5... at 6941 ticks"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (digest 2599c7c2...)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json (digest f7a967ed...)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=full_idle --twice (digest f417c7f5..., ticks 6941)"
        status: pass
    human_judgment: false
  - id: D5
    description: "All 33 shipped screenshots capture non-blank locally in a real window (Forward+), and CI run 38848480353 for HEAD 3c8f69e succeeds on lint, test, export and screenshots with 33 PNGs from the Mesa software renderer (RESEARCH A2 settled)"
    requirement: PLAT-01
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh (33 saved, exit 0); gh run 38848480353 conclusion success, headSha 3c8f69e; gh run download -n duskhold-screenshots holds 33 PNGs"
        status: pass
    human_judgment: false
  - id: D6
    description: "The baked friendly units and the arrows look right to the owner (model fidelity, arrow readability under clutter)"
    requirement: PLAT-01
    verification: []
    human_judgment: true
    rationale: "The agent read every unit and arrow PNG and found no difference from the puppet era, but whether the look is acceptable is the owner's call at the Phase 4 UAT"
---

# Phase 4 Plan 02: Crowd-Scale Battles - Unit and Arrow Batches Summary

**Friendly units drawn as one MultiMesh batch per unit type from Kenney models baked once into a single mesh (capsule fallback headless), every arrow flown from a 512-slot ring batch, and the selection layer moved onto has_view, with the goldens untouched and the Mesa software renderer on CI proven by a green run and 33 screenshots.**

## Performance

- **Duration:** about 60 min
- **Started:** 2026-10-16T03:12:00Z (approximate: the prior plan's state record is 03:09:47Z; no start timestamp was captured)
- **Completed:** 2026-10-16T04:12:00Z
- **Tasks:** 3 (Task 1 tracer, Task 2 TDD, Task 3 screenshots and CI)
- **Files modified:** 13 paths in the three code commits (2 new scripts, their 2 `.uid` files, 9 changed)

## Accomplishments

- `MeshBaker.bake` walks a model tree in child order, moves every mesh to its place under the root, scales it and appends the surfaces (materials kept) to one ArrayMesh; a skinned part goes through `bake_mesh_from_current_skeleton_pose()`, and the whole bake is null when that cannot run. `append_primitive` adds the sword box, the bow cylinder and the capsule fallback the same way.
- `UnitViews` is now two unit batches (footman, archer), one bar batch and no node per unit. In a real window the footman batch draws the baked `character-male-a` mesh with the sword merged in and the archer batch `character-female-a` with the bow; headless both are capsules (`mesh_source_of` reads `&"baked"` or `&"capsule"`). `MAX_VIEWS` stays 256 across both types, so `SelectionRings.MAX_RINGS` keeps its meaning. `get_view` is gone; the rings and the selection controller test `has_view`.
- `ProjectileVfx` holds 512 flight slots in parallel arrays and writes the live ones into one arrow batch per frame (`add_transform`, one commit). `arrow_transform(origin, target, t)` gives the pose along the arc (z along the path including the arc slope, y upright for a level shot). Retargeting the living victim every frame is kept (RESEARCH Open Question 5). Slashes remain nodes, capped at 8.
- All three replays are byte-identical across the switch (D-13), and CI confirmed the batches on Mesa: lint, test, export and screenshots all succeeded on the first push of this plan.

## Task Commits

1. **Task 1: Tracer, units from one batch per type with baked models and hurt bars, selection on has_view** - `4a925a9` (feat)
2. **Task 2 RED: failing tests for arrows from one ring batch** - `5ed3725` (test; amended once to apply gdformat to the new test file)
3. **Task 2 GREEN: arrows as instances of a 512-slot ring batch** - `3c8f69e` (feat)
4. **Task 3: screenshots and CI check** - no code of its own (nothing needed fixing); pushed `3c8f69e`, CI run https://github.com/ABSAR07/duskhold/actions/runs/38848480353 succeeded

**Plan metadata:** the SUMMARY commit and the STATE/ROADMAP commit follow this file (docs, not pushed). No REFACTOR commit.

## TDD Gate Compliance

Task 2 (`tdd="true"`) followed RED, GREEN:

- **RED** `5ed3725`: `test(04-02)` adds the new test_projectile_vfx tests (cap 512, arrow pose) and rewrites test_projectiles_visible against `arrow_count`, `arrow_color_at` and `arrow_launch_at`, with minimal stubs in ProjectileVfx so the tests fail on assertions. Runs: `bash tools/test.sh -gselect=test_projectile_vfx` 6 of 10 passed, 4 failed (cap 128 vs 512, arrow at origin, arc height, climb and dive); `bash tools/test.sh -gselect=test_projectiles_visible` 1 of 5 passed, 4 failed on assertions (`arrow_count` 0 against 1, colour white against gold, the 128 cap). The persisted record (the GUT JUnit XML as output, target `test_a_flood_of_shots_never_passes_the_cap_and_all_of_them_drain`) verified `RED_EVIDENCE_OK` (reason `target_test_failed`) through `gsd-tools check tdd-red-evidence`.
- **GREEN** `3c8f69e`: the real ring batch; 10 of 10 and 5 of 5 pass, then the whole suite.
- **REFACTOR:** none needed. Task 1 is the tracer (no `tdd` attribute, no RED commit).

Tracer gate: Task 1's `<verify>` is automated only and `human_verify_mode` is `end-of-phase`, so the tracer re-ran end to end (full suite 1465 tests, smoke and army replays, lint) and expansion continued.

## Files Created/Modified

- `presentation/crowd/mesh_baker.gd` - bake and append_primitive
- `presentation/units/unit_views.gd` - rewritten on batches; hooks `view_count`, `has_view`, `puppet_position`, `mesh_source_of`, `bar_ratio_of`, `bar_count`
- `presentation/units/selection_rings.gd`, `input/selection_controller.gd` - `has_view` instead of `get_view`
- `presentation/vfx/projectile_vfx.gd` - ring of 512 flights, `arrow_transform`, `arrow_count`, `arrow_color_at`, `arrow_launch_at`
- `presentation/crowd/crowd_instance.gdshader` - sRGB to linear tint
- `tests/unit/test_mesh_baker.gd` (7), `tests/e2e/test_unit_views.gd` (5), `tests/e2e/test_projectiles_visible.gd` (5), `tests/unit/test_projectile_vfx.gd` (10), `tests/e2e/test_squad_tracer_scene.gd` (one assertion)

## Decisions Made

See the frontmatter. In short: no skinned bake call on the headless display server; no material override or instance colour on the unit batches; sRGB tint conversion in the shared shader; one extra test hook (`arrow_launch_at`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Arrows drew washed out through the instance tint**
- **Found during:** Task 2 (night_combat screenshot after the GREEN code passed its tests)
- **Issue:** the batch's instance colours reach the shader as written, in linear space, while the arrow colours (gold, violet, pale blue) are authored as sRGB like the StandardMaterial3D colours they replaced. The violet skirmisher arrow came out pale pink next to its 04-01 reference shot.
- **Fix:** `crowd_instance.gdshader` converts `COLOR.rgb` from sRGB to linear in `vertex()`. Enemies pass white, which converts to white, so no enemy changed.
- **Files modified:** `presentation/crowd/crowd_instance.gdshader` (a 04-01 file, not in this plan's file list)
- **Verification:** `night_combat` re-captured in Forward+ and Compatibility, arrow matches the earlier violet; the full suite and all three replays passed after
- **Committed in:** `3c8f69e`

**2. [Rule 3 - Blocking] The skinned bake logs an engine error headless, which GUT counts as a failure**
- **Found during:** Task 1 (test_mesh_baker)
- **Issue:** calling `bake_mesh_from_current_skeleton_pose()` with no skeleton or renderer prints an engine error; GUT fails the test on any unexpected engine error, so the null fallback could not be tested, and every e2e scene that binds UnitViews would have hit it.
- **Fix:** `MeshBaker` returns null for a skinned part on the headless display server without calling the bake (the headless result was null anyway, RESEARCH F7); the test builds the skinned part from an ArrayMesh.
- **Files modified:** `presentation/crowd/mesh_baker.gd`, `tests/unit/test_mesh_baker.gd`
- **Verification:** 7 of 7 pass, test_unit_views passes with `mesh_source_of` = capsule
- **Committed in:** `4a925a9`

**3. [Rule 2 - Missing test hook] `arrow_launch_at(index)`**
- **Found during:** Task 2 (RED)
- **Issue:** the castle-shot test asserted the arrow's start position through the arrow node; with no node left, the only position in the mirror is the frame's moved arrow, not its launch point.
- **Fix:** the vfx keeps the launch point of each drawn arrow for a read-only hook.
- **Files modified:** `presentation/vfx/projectile_vfx.gd`, `tests/e2e/test_projectiles_visible.gd`
- **Committed in:** `5ed3725` (stub), `3c8f69e`

---

**Total deviations:** 3 auto-fixed (1 bug, 1 blocking, 1 missing hook)
**Impact on plan:** all three needed for correctness or verifiability; no scope creep. No fix cycle was needed in Task 3 (CI passed on the first push).

## Issues Encountered

- `gsd-tools query git.base-branch --is-protected` treats `gsd/phase-01-foundation-day-loop` as the protected default branch (the owner made it the GitHub default, STATE decision [01-01]); as in 04-01 the orchestrator dispatched this sequential run on that branch, HEAD never drifted and no ref was rewritten.
- The Bash tool refused two commands that mixed several heredocs and apostrophes (a shell parse error before anything ran); files were written with the Write tool instead. Nothing was left half-written.
- The first RED commit was amended once (gdformat reformatted one line of the new test file) before any push.
- Every CI screenshot log carries 33 lines of ALSA and `ERR_CANT_OPEN` noise (no audio device on the runner); it is not a script error and the shots are fine.

## Test and Replay Results

- Full suite after Task 1: 158 scripts, 1465 tests, 16890 asserts, 523 s, exit 0. After Task 2: **158 scripts, 1469 tests, 17376 asserts, 516 s, exit 0** (dispatch baseline 157 scripts, 1456 tests, 16846 asserts).
- `bash tools/lint.sh`: clean (gdformat + gdlint over 278 files).
- smoke: `REPLAY_OK ... ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden match); army: `ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (golden match); full_idle: `ticks=6941 digest=f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` twice. No golden was regenerated.
- CI: run 38848480353, https://github.com/ABSAR07/duskhold/actions/runs/38848480353, headSha `3c8f69e7f6c2e00bee6270f5a5b8cac07422b57d`, conclusion success, jobs lint, test, export and screenshots all success; `gh run download -n duskhold-screenshots` holds 33 PNGs (`ALL_SHOTS` has 33). The Task 3 verify line (latest run on the branch is for HEAD, success, 33 PNGs) printed `VERIFY_OK` at `3c8f69e`; the docs commits after it are not pushed.

## Screenshot Review

Local, Forward+ (real window, RTX 3060 Laptop, Vulkan 1.4), all 33 saved and non-blank (smallest 54 KB). Read one by one:

- `hud_day_squads`: four footmen in baked male-a models with sword left of the castle, four archers in female-a models with bow right, selection rings under the selected squad, as before the switch (compared with the Phase 3 capture).
- `hud_night_squad_down`: night 7, no footman left, three archers at the right edge, castle bars, violet skirmisher arrows and a cyan ghost king; arrows read as before.
- `cmd_box_select`: both squads ringed in cyan; `cmd_move_ping`: footmen ringed, a ping ring on the ground; `cmd_patrol`: footmen on the way, dashed patrol line; `cmd_queue_ten`: numbered waypoint path, footmen ringed; `hud_drag_box`: selection box over the castle, units unringed; `hud_pad_cursor`: cursor ring, footmen ringed; `hud_ability_ready`, `hud_keycap_backspace`, `hud_long_toast`, `hud_day_counter_long`: units as before or none in frame.
- `cmd_slam`: footmen and the king around a red grunt, yellow tower arrows in flight; `night_combat`: red grunt, two violet skirmishers, a violet arrow, pale-red puffs, yellow slam bar; `building_destroyed`: grunts around the king with two hurt-only bars; `overlay_paths`: grunt, puffs, debug panel and path line intact; `king_down_countdown`, `hud_king_down`, `hud_king_120`: cyan ghost king among puffs, gold arrow stack at the tower; `hud_rubble_squad` and `hud_night_squad_down_16x10`: rubble plots, one violet pair of arrows; `hud_day_squads_1080p`: same as 720p, baked models sharp at 1080p; `spawn_telegraph`, `night_banner`, `dawn_rebuilt`, `results_victory`, `results_defeat`: unchanged presentation, no unit or arrow regression. `day_overview`, `spot_label`, `build_in_progress`, `dawn_payout`, `overlay_on` and `king_behind_keep` have no unit or arrow in frame and were captured non-blank without being opened one by one.
- Compatibility (OpenGL 3, local NVIDIA driver): `hud_day_squads` shows the baked models with correct colours (no black bodies), `night_combat` shows violet and gold arrows.

CI, Mesa llvmpipe Compatibility (downloaded from run 38848480353, read: `hud_day_squads`, `night_combat`, `building_destroyed`, `cmd_box_select`, `cmd_slam`, `hud_night_squad_down`, `overlay_paths`): the baked footmen and archers show their models with rings, the grunt and skirmisher capsules and gold, violet and yellow arrows draw in the right colours, the hurt-only bars show; the images are flatter and lighter than the Forward+ ones as expected. RESEARCH A2 is settled: the custom shaders and baked meshes run on Mesa software GL.

## Known Stubs

None. The RED stubs from `5ed3725` were replaced in `3c8f69e`.

## Threat Flags

None. No new network endpoint, file access or trust boundary. T-04-03 (the fixed ring of 512, shots past it not drawn, slashes capped at 8) is covered by the flood test; T-04-04 held: `ci.yml` was not edited, `tools/prepush_check.sh` passed before the push and the push used the gh credential helper command only.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Enemies, units and arrows all render from batches; the goldens are untouched, so the hot-path pass (04-03) can start. `MeshBaker` is ready for the wall model of plan 04-05.
- The headless skinned-bake skip means a unit test run never shows the baked mesh; the real-window shots are its only check (the owner judges the look at the UAT).

## Self-Check: PASSED

- Files: the two new scripts and their `.uid` files, the seven changed source and test files and the shader exist on disk (checked with `[ -f ]`).
- Commits: `4a925a9`, `5ed3725`, `3c8f69e` found in `git log`; `git log --grep=04-02` lists them.
- Acceptance criteria re-run: `mesh_baker.gd` contains `class_name MeshBaker` and `bake_mesh_from_current_skeleton_pose`; `unit_views.gd` contains `CrowdBatch`, `HealthBarBatch`, `func has_view(`, `func mesh_source_of(` and no `func get_view(`; the rings and the controller contain `has_view(`; `projectile_vfx.gd` contains `const MAX_PROJECTILES: int = 512`, `static func arrow_transform(`, `add_transform(` and `MAX_SLASHES` with slashes still built as MeshInstance3D; `test_projectile_vfx.gd` pins 512; the JUnit XML lists test_mesh_baker, test_unit_views, test_squad_tracer_scene, test_squad_selection, test_box_select, test_control_group_keys, test_order_markers, test_projectile_vfx and test_projectiles_visible; 33 local PNGs and 33 CI PNGs.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
