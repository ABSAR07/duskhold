---
phase: 04-crowd-scale-battles-walls
plan: 01
subsystem: rendering
tags: [godot, multimesh, gdscript, shader, crowd, presentation, tdd]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: EnemySystem read accessors, SimEvents enemy_spawned/enemy_damaged/enemy_died, golden replays
  - phase: 03-king-combat-troops
    provides: smoke, army and full_idle replay scenarios and the screenshot tooling
provides:
  - CrowdBatch, a MultiMesh batch with a CPU mirror (flags before instance_count, begin/add/commit)
  - crowd_instance.gdshader (flash from INSTANCE_CUSTOM.x, tint from COLOR), reused by plan 04-02 arrows
  - EnemyViews drawn as one batch per archetype, MAX_VIEWS 512 in total, no node per enemy
  - HealthBarBatch (hurt-only billboard bars) and DeathPuffBatch (ring of 128 puffs)
  - ShotRunner waits one processed frame so batched views are uploaded before a capture
affects: [04-02 unit and arrow batches, 04-03 hot-path pass, 04-09 stress and frame report, 08 art pass]

actuals:
  tokens: 22000
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "MultiMesh batch with a CPU mirror: tests read the mirror, never the MultiMesh (headless renderer returns zeros)"
    - "Instance colours stay on for batches whose shader reads COLOR: Compatibility reads a missing vertex colour as black"
    - "Per-id presentation state comes from events only (spawned, damaged, died); the drawn set is a sorted mirror searched with a binary search"
    - "Flash measured against the clock sampled at the start of the latest frame, so a hit between frames reads exactly 1.0"

key-files:
  created:
    - presentation/crowd/crowd_batch.gd
    - presentation/crowd/crowd_instance.gdshader
    - presentation/vfx/health_bar_batch.gd
    - presentation/vfx/health_bar_batch.gdshader
    - presentation/vfx/death_puff_batch.gd
    - presentation/vfx/death_puff.gdshader
    - tests/unit/test_crowd_batch.gd
    - tests/unit/test_health_bar_batch.gd
    - tests/unit/test_death_puff_batch.gd
    - tests/e2e/test_enemy_views.gd
  modified:
    - presentation/enemies/enemy_views.gd
    - tests/e2e/test_projectiles_visible.gd
    - tests/e2e/test_results_screen.gd
    - tools/screenshot/shot_runner.gd

key-decisions:
  - "Enemy batches keep instance colours on and pass white: the Compatibility renderer reads a missing vertex colour as black, so a colourless batch drew every body black through the tint"
  - "ShotRunner waits one processed frame before the capture: batches upload in _process, so a scenario that stepped the simulation by hand left the captured frame without enemies"
  - "flash_of and bar_ratio_of read per-id event state against the drawn mirror instead of the committed buffer, so a hit between frames reads 1.0 and 0.0 exactly"
  - "DeathPuffBatch.spawn takes an optional colour (default white) so puffs keep the enemy colour the particles had; the plan interface had origin and time only"

patterns-established:
  - "CrowdBatch is the one place a MultiMesh is built: flags, mesh, instance_count, visible_instance_count in that order"
  - "A view's test hooks (has_view, puppet_position, flash_of, bar_ratio_of, puff_count) read CPU state, never the GPU buffer"

requirements-completed: [PLAT-01]

duration: 54min
completed: 2026-10-16
status: complete
commits: 3
plan_head_before: 75183fe1d63073a720a6dcddf8f9c3eb337b74a4
plan_head_after: 6af352bcfb4d79d3ac55d7d911c481c1a5abcd5a

coverage:
  - id: D1
    description: "Every live enemy is drawn as one instance of its archetype batch (grunt red, skirmisher violet taller and narrower, any other type the fallback colour) at the interpolated position; EnemyViews holds only batches"
    requirement: PLAT-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd#test_every_live_enemy_is_one_batch_instance_that_follows_the_simulation"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd#test_enemy_views_holds_only_its_batches_and_never_a_node_per_enemy"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd#test_each_archetype_has_its_own_colour_and_silhouette"
        status: pass
    human_judgment: false
  - id: D2
    description: "A hit flashes the instance, a hurt enemy shows a hurt-only bar filled to hp / max_health, a death leaves a puff that fades within 0.6 s, all from batches"
    requirement: PLAT-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd#test_a_hit_flashes_the_instance_and_settles"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd#test_a_hurt_enemy_shows_a_bar_filled_to_its_health_and_a_full_one_shows_none"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd#test_a_dying_enemy_leaves_a_puff_that_fades_within_its_lifetime"
        status: pass
    human_judgment: false
  - id: D3
    description: "Overflow and empty edges: past MAX_VIEWS 512 enemies are not drawn while the simulation keeps them; with no enemy every batch commits visible_instance_count 0"
    requirement: PLAT-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd#test_more_enemies_than_the_cap_are_simulated_but_not_drawn"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_enemy_views.gd#test_with_no_enemy_alive_every_batch_commits_nothing"
        status: pass
      - kind: unit
        ref: "tests/unit/test_crowd_batch.gd#test_a_full_batch_refuses_one_more_instance"
        status: pass
    human_judgment: false
  - id: D4
    description: "Presentation never touched the simulation: smoke and army goldens byte-identical, full_idle replays twice to f417c7f5... at 6941 ticks"
    requirement: PLAT-01
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json (REPLAY_OK digest 2599c7c2...)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json (REPLAY_OK digest f7a967ed...)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=full_idle --twice (REPLAY_OK digest f417c7f5... ticks=6941)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The night shots that show enemies read correctly in a real window in Forward+ and, for night_combat and building_destroyed, in the Compatibility renderer"
    requirement: PLAT-01
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh night_combat building_destroyed king_down_countdown overlay_paths results_defeat (exit 0)"
        status: pass
      - kind: automated_ui
        ref: "DUSKHOLD_SCREENSHOT_COMPAT=1 bash tools/screenshot.sh night_combat building_destroyed (exit 0)"
        status: pass
    human_judgment: true
    rationale: "The agent read every PNG, but whether the placeholder capsules, bars and puffs look right is the owner's call at the Phase 4 UAT"
---

# Phase 4 Plan 01: Crowd-Scale Battles - Enemy Batches Summary

**Enemies, their hurt-only health bars and their death puffs drawn through MultiMesh batches (one per archetype plus a bar batch and a 128-puff ring) with the smoke, army and full_idle replays byte-identical.**

## Performance

- **Duration:** 54 min
- **Started:** 2026-10-16T02:13:00Z (approximate: the orchestrator's begin-phase commit is 02:13:44Z)
- **Completed:** 2026-10-16T03:09:00Z
- **Tasks:** 2 (Task 1 tracer, Task 2 TDD)
- **Files modified:** 14 source and test files, 10 new plus 4 changed (24 paths with the generated `.uid` files)

## Accomplishments

- `CrowdBatch` builds one MultiMesh with the flags set before `instance_count` and a `PackedFloat32Array` mirror; a frame is `begin`, `add`, `commit`, and the readers (`origin_of`, `basis_of`, `custom_of`, `color_of`) serve the tests because the headless renderer reads a MultiMesh back as zeros.
- `EnemyViews` no longer owns a node per enemy: three 144-triangle capsule batches (grunt, skirmisher, fallback), one bar batch and one puff ring. `MAX_VIEWS` is 512 enemies drawn in total; past it the simulation keeps stepping and the view stops drawing. `get_view` and the flash tweens are gone.
- Hit flash, hurt-only bars and death puffs are per-instance data (custom x) read by three small shaders; the puff cap rose from 64 to 128 and one particle node plus one timer per death disappeared.
- All three replays are byte-identical across the switch (D-13).

## Task Commits

1. **Task 1: Tracer, enemies as one MultiMesh instance per archetype** - `c86d389` (feat)
2. **Task 2 RED: failing tests for bars and puffs** - `e51a6dd` (test)
3. **Task 2 GREEN: hurt-only bars and death puffs from batches** - `6af352b` (feat)

**Plan metadata:** the SUMMARY commit and the STATE/ROADMAP commit follow this file (docs). No REFACTOR commit: nothing to clean up.

## TDD Gate Compliance

Task 2 (`tdd="true"`) followed RED, GREEN:

- **RED** `e51a6dd`: `test(04-01)` adds test_health_bar_batch, test_death_puff_batch and four new test_enemy_views tests, with minimal API stubs (HealthBarBatch, DeathPuffBatch, EnemyViews bar hooks) so the tests fail on assertions rather than parse errors. Run: `bash tools/test.sh -gselect=test_enemy_views` exit 1, 12 tests, 5 failing, among them the target `test_a_hurt_enemy_shows_a_bar_filled_to_its_health_and_a_full_one_shows_none` (expected 0.667, actual -1.0). The persisted record verified `RED_EVIDENCE_OK` (reason `target_test_failed`) through `gsd-tools check tdd-red-evidence`. test_health_bar_batch failed 4 of 5 and test_death_puff_batch 5 of 5 on assertions as well.
- **GREEN** `6af352b`: the real batches replace the stubs; all 12 test_enemy_views, 5 test_health_bar_batch and 5 test_death_puff_batch tests pass.
- **REFACTOR:** none needed. Task 1 is the tracer (`type="tracer"`, no `tdd` attribute) and has no RED commit.

Tracer gate: Task 1's `<verify>` is automated only and `human_verify_mode` is `end-of-phase`, so the tracer re-ran end to end (full suite 1443 tests, three replays, lint) and expansion continued.

## Files Created/Modified

- `presentation/crowd/crowd_batch.gd` - MultiMesh batch with CPU mirror, begin/add/add_transform/commit, readers
- `presentation/crowd/crowd_instance.gdshader` - flash from INSTANCE_CUSTOM.x and tint from COLOR
- `presentation/enemies/enemy_views.gd` - rewritten on batches; hooks `view_count`, `has_view`, `puppet_position`, `flash_of`, `archetype_color_of`, `bar_count`, `bar_ratio_of`, `puff_count`
- `presentation/vfx/health_bar_batch.gd` and `.gdshader` - hurt-only billboard bars
- `presentation/vfx/death_puff_batch.gd` and `death_puff.gdshader` - ring of 128 puffs aged by the real clock
- `tests/unit/test_crowd_batch.gd` (9 tests), `test_health_bar_batch.gd` (5), `test_death_puff_batch.gd` (5), `tests/e2e/test_enemy_views.gd` (12, at most 20 per script)
- `tests/e2e/test_projectiles_visible.gd` - the enemy colour, flash and puff tests moved out (arrow and slash tests stay for plan 04-02); `tests/e2e/test_results_screen.gd` - `_puppet_positions` reads `puppet_position`
- `tools/screenshot/shot_runner.gd` - one processed frame before the capture

## Screenshot Review

Forward+ (real window, RTX 3060 Laptop, Vulkan 1.4), every PNG read:

- `night_combat`: non-blank; one red grunt and two violet skirmishers (taller and narrower) on the field, a violet arrow in flight and a cluster of pale-red death puffs; no bar because no enemy in frame is hurt.
- `building_destroyed`: non-blank; a cluster of red grunts around the king with two small hurt-only bars (red fill, dark remainder) over the two hurt grunts and none over the others.
- `king_down_countdown`: non-blank; one violet skirmisher, a cyan ghost king surrounded by translucent red and violet puffs fading out, tower and slash marks right; no bars.
- `overlay_paths`: non-blank; a red grunt and three small pale-red puffs left of the tower, debug overlay panel and path line intact.
- `results_defeat`: non-blank; grunts dimmed behind the defeat card with one small bar over a hurt grunt on the left.

Compatibility (OpenGL 3, CI's renderer), after the colour fix below:

- `night_combat`: non-blank; grunt dark red, skirmishers violet, red puffs, arrow, same layout as Forward+ with Compatibility's darker, less emissive colours (RESEARCH F6).
- `building_destroyed`: non-blank; dark-red grunts and the two hurt-only bars, as in Forward+.

## Decisions Made

- Enemy batches keep instance colours on and pass white; see deviation 1.
- `ShotRunner` waits one processed frame before the capture; see deviation 2.
- `flash_of` and `bar_ratio_of` are computed from per-id event state against the drawn mirror (not from the committed buffer), so tests read exactly 1.0 right after a hit and -1.0 for an enemy with no bar, whatever the frame timing.
- `DeathPuffBatch.spawn(origin, now_s, color = WHITE)` has one optional colour parameter beyond the plan interface so puffs keep the enemy colour.
- The puff sphere is 0.35 m (data constant `PUFF_RADIUS`) growing to 0.7 m: with the plan's 6 sides and 3 rings and a 1.0 + age scale, the particle spheres' 0.1 m would be invisible.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Compatibility rendered every enemy body black**
- **Found during:** Task 2 (Compatibility screenshot run)
- **Issue:** Task 1 built the enemy batches without instance colours (`with_colors` false, stride 16) to save memory. The shader multiplies albedo by `COLOR`, and with no instance colour and no vertex colour the Compatibility renderer reads COLOR as black, so grunts and skirmishers drew black. Forward+ was unaffected, so Task 1's tests and Forward+ shots passed.
- **Fix:** `setup(..., true)`: instance colours on, every enemy passes white (the plan's wording, "enemies pass white"). A test now pins `use_colors` on the enemy batches.
- **Files modified:** `presentation/enemies/enemy_views.gd`, `tests/e2e/test_enemy_views.gd`
- **Verification:** Compatibility `night_combat` and `building_destroyed` captured with red and violet bodies
- **Committed in:** `6af352b`

**2. [Rule 3 - Blocking] Night screenshots captured no enemies**
- **Found during:** Task 1 follow-up screenshot run, fixed in Task 2
- **Issue:** The shot scenarios fast-forward the simulation by hand inside one frame and capture at once. The old puppets were nodes added the instant an enemy spawned, so they were in that frame's draw; a batch uploads in `_process`, so `night_combat` showed an empty field (`view_count` 0 against 6 live enemies at capture).
- **Fix:** `ShotRunner._capture` awaits one `process_frame` before `frame_post_draw`, so the views are uploaded before the image is taken.
- **Files modified:** `tools/screenshot/shot_runner.gd` (not in the plan's file list)
- **Verification:** all five Forward+ shots and both Compatibility shots show the enemies
- **Committed in:** `6af352b`

**3. [Rule 2 - Missing test coverage] Extra test script for the puff ring**
- **Found during:** Task 2 (RED)
- **Issue:** the plan named test_health_bar_batch and test_enemy_views only; DeathPuffBatch's ring logic (lifetime, cap, slot reuse) is unit-testable with an injected clock.
- **Fix:** added `tests/unit/test_death_puff_batch.gd` (5 tests, no real-time waits).
- **Committed in:** `e51a6dd`

---

**Total deviations:** 3 auto-fixed (1 bug, 1 blocking, 1 missing coverage)
**Impact on plan:** all three needed for correctness or verifiability; no scope creep. The plan's own sequencing leaves the commit between Task 1 and Task 2 (`c86d389`) without bars (the old puppets' bars went with the puppets) and with the old particle puffs, as Task 2 was meant to replace them.

## Issues Encountered

- The `gsd-tools query git.base-branch --is-protected` check reports `gsd/phase-01-foundation-day-loop` as the protected default branch, because the owner made it the GitHub default (STATE decision [01-01], owner decision after the Phase 1 protected-branch halt; every earlier Phase 1 to 3 commit and the orchestrator's own phase-4 commits are on it). The orchestrator dispatched this sequential run on that branch and HEAD never drifted, so the commits stayed here; no ref was rewritten.
- My first versions of the killed-enemy tests relied on the simulation's `remove_dead()` firing within two frames (`EnemySystem.damage` does not emit `enemy_died`); that was flaky at high frame rates and was fixed before the GREEN commit by calling `remove_dead()` in the test.

## Test and Replay Results

- `bash tools/test.sh`: 157 scripts, 1456 tests, 16847 asserts, 514 s, exit 0 (dispatch baseline 153 scripts, about 1428 tests; four new scripts, the moved tests net out in test_enemy_views).
- `bash tools/lint.sh`: clean (gdformat + gdlint over 276 files).
- smoke: `REPLAY_OK ... ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden match); army: `ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (golden match); full_idle: `ticks=6941 digest=f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` twice. No golden was regenerated.

## Known Stubs

None. The RED stubs from `e51a6dd` were replaced in `6af352b`; no placeholder text or empty UI data remains in the files of this plan.

## Threat Flags

None. No new network endpoint, file access or trust boundary: the views read the simulation and event bus only, and T-04-01 (fixed capacities: MAX_VIEWS 512, puffs 128, `add()` past capacity returns false) and T-04-02 (replay identity) are the mitigations the tests and replays above exercise.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `CrowdBatch` and `crowd_instance.gdshader` are ready for plan 04-02 (unit batch, arrow ring with per-instance colours; keep colours on for any batch that reads COLOR).
- The enemy rendering switch is in and the goldens are untouched, so the hot-path pass (04-03) can start. Per RESEARCH F1 the binding cost at 300 enemies is the simulation step, not these views.
- RESEARCH A2 (the custom shaders in CI's Mesa software GL) is still checked by plan 04-02 Task 3 through the CI screenshots job; the Compatibility run here used the local NVIDIA OpenGL driver.

## Self-Check: PASSED

- Files: all ten created files and the four modified files exist on disk (checked with `[ -f ]`).
- Commits: `c86d389`, `e51a6dd`, `6af352b` found in `git log`; `git log --grep=04-01` lists them.
- Acceptance criteria re-run: CrowdBatch declares `setup(`, `commit(`, `origin_of(` and `use_custom_data` is assigned before `instance_count`; the crowd shader contains INSTANCE_CUSTOM and EMISSION; `MAX_VIEWS: int = 512`, `CrowdBatch`, `has_view(`, no `get_view(`; `HealthBarBatch` uses `should_show`; `DeathPuffBatch.MAX_PUFFS: int = 128`; `bar_ratio_of(` present and no particle node is built per death; the JUnit XML lists test_crowd_batch, test_health_bar_batch, test_enemy_views, test_results_screen, test_night_tracer_scene and test_projectiles_visible; `screenshots/night_combat.png` and `screenshots/building_destroyed.png` exist.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
