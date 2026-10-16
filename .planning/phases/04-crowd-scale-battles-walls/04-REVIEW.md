---
phase: 04-crowd-scale-battles-walls
reviewed: 2026-10-16T20:45:54Z
depth: standard
files_reviewed: 208
files_reviewed_list:
  - .github/workflows/ci.yml
  - data/buildings/wall.tres
  - data/maps/prototype_map.tres
  - data/tuning/nav_tuning.tres
  - input/selection_controller.gd
  - presentation/buildings/building_views.gd
  - presentation/crowd/crowd_batch.gd
  - presentation/crowd/crowd_batch.gd.uid
  - presentation/crowd/crowd_instance.gdshader
  - presentation/crowd/crowd_instance.gdshader.uid
  - presentation/crowd/mesh_baker.gd
  - presentation/crowd/mesh_baker.gd.uid
  - presentation/debug/enemy_path_gizmo.gd
  - presentation/debug/flow_field_gizmo.gd
  - presentation/debug/flow_field_gizmo.gd.uid
  - presentation/enemies/enemy_views.gd
  - presentation/king/king.gd
  - presentation/map/prototype_map.tscn
  - presentation/units/selection_rings.gd
  - presentation/units/unit_views.gd
  - presentation/vfx/death_puff.gdshader
  - presentation/vfx/death_puff.gdshader.uid
  - presentation/vfx/death_puff_batch.gd
  - presentation/vfx/death_puff_batch.gd.uid
  - presentation/vfx/health_bar_batch.gd
  - presentation/vfx/health_bar_batch.gd.uid
  - presentation/vfx/health_bar_batch.gdshader
  - presentation/vfx/health_bar_batch.gdshader.uid
  - presentation/vfx/projectile_vfx.gd
  - presentation/walls/wall_views.gd
  - presentation/walls/wall_views.gd.uid
  - simulation/buildings/building_system.gd
  - simulation/defs/build_spot_def.gd
  - simulation/defs/enemy_def.gd
  - simulation/defs/map_config.gd
  - simulation/defs/nav_tuning.gd
  - simulation/defs/nav_tuning.gd.uid
  - simulation/events/sim_events.gd
  - simulation/nav/flow_field.gd
  - simulation/nav/flow_field.gd.uid
  - simulation/nav/goal_field_cache.gd
  - simulation/nav/goal_field_cache.gd.uid
  - simulation/nav/nav_grid.gd
  - simulation/nav/nav_grid.gd.uid
  - simulation/nav/pathing.gd
  - simulation/nav/pathing.gd.uid
  - simulation/nav/stuck_tracker.gd
  - simulation/nav/stuck_tracker.gd.uid
  - simulation/nav/wall_decision.gd
  - simulation/nav/wall_decision.gd.uid
  - simulation/night/crowd_read_view.gd
  - simulation/night/crowd_read_view.gd.uid
  - simulation/night/enemy_index.gd
  - simulation/night/enemy_index.gd.uid
  - simulation/night/enemy_system.gd
  - simulation/night/night_sim.gd
  - simulation/night/pending_hits.gd
  - simulation/night/structure_index.gd
  - simulation/night/structure_index.gd.uid
  - simulation/night/target_query.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - simulation/squads/separation.gd
  - simulation/squads/squad_system.gd
  - simulation/squads/unit_system.gd
  - simulation/walls/wall_run_def.gd
  - simulation/walls/wall_run_def.gd.uid
  - simulation/walls/wall_solids.gd
  - simulation/walls/wall_solids.gd.uid
  - simulation/walls/wall_system.gd
  - simulation/walls/wall_system.gd.uid
  - simulation/walls/wall_validation.gd
  - simulation/walls/wall_validation.gd.uid
  - tests/e2e/test_enemy_views.gd
  - tests/e2e/test_enemy_views.gd.uid
  - tests/e2e/test_overlay_field.gd
  - tests/e2e/test_overlay_field.gd.uid
  - tests/e2e/test_projectiles_visible.gd
  - tests/e2e/test_results_screen.gd
  - tests/e2e/test_squad_tracer_scene.gd
  - tests/e2e/test_unit_views.gd
  - tests/e2e/test_upgrade_at_spot.gd
  - tests/e2e/test_wall_tracer_scene.gd
  - tests/e2e/test_wall_tracer_scene.gd.uid
  - tests/e2e/test_wall_views.gd
  - tests/e2e/test_wall_views.gd.uid
  - tests/fixtures/fixture_map_replay_walls.tres
  - tests/fixtures/fixture_map_walls.tres
  - tests/fixtures/fixture_map_walls_gap.tres
  - tests/golden/walls.json
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_report.gd
  - tests/integration/test_balance_report_walls.gd
  - tests/integration/test_balance_report_walls.gd.uid
  - tests/integration/test_gate_stress.gd
  - tests/integration/test_gate_stress.gd.uid
  - tests/integration/test_wall_behaviour.gd
  - tests/integration/test_wall_behaviour.gd.uid
  - tests/integration/test_wall_dawn.gd
  - tests/integration/test_wall_dawn.gd.uid
  - tests/integration/test_wall_determinism.gd
  - tests/integration/test_wall_determinism.gd.uid
  - tests/integration/test_wall_detour.gd
  - tests/integration/test_wall_detour.gd.uid
  - tests/integration/test_walls_replay_golden.gd
  - tests/integration/test_walls_replay_golden.gd.uid
  - tests/support/sim_signals.gd
  - tests/unit/test_crowd_batch.gd
  - tests/unit/test_crowd_batch.gd.uid
  - tests/unit/test_crowd_read_view.gd
  - tests/unit/test_crowd_read_view.gd.uid
  - tests/unit/test_death_puff_batch.gd
  - tests/unit/test_death_puff_batch.gd.uid
  - tests/unit/test_debug_overlay_crowd_sections.gd
  - tests/unit/test_debug_overlay_crowd_sections.gd.uid
  - tests/unit/test_debug_overlay_night_sections.gd
  - tests/unit/test_flow_field.gd
  - tests/unit/test_flow_field.gd.uid
  - tests/unit/test_frame_report.gd
  - tests/unit/test_frame_report.gd.uid
  - tests/unit/test_goal_field_cache.gd
  - tests/unit/test_goal_field_cache.gd.uid
  - tests/unit/test_health_bar_batch.gd
  - tests/unit/test_health_bar_batch.gd.uid
  - tests/unit/test_los_targets.gd
  - tests/unit/test_los_targets.gd.uid
  - tests/unit/test_map_nav_validation.gd
  - tests/unit/test_map_nav_validation.gd.uid
  - tests/unit/test_map_wall_validation.gd
  - tests/unit/test_map_wall_validation.gd.uid
  - tests/unit/test_mesh_baker.gd
  - tests/unit/test_mesh_baker.gd.uid
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_nav_grid.gd
  - tests/unit/test_nav_grid.gd.uid
  - tests/unit/test_nav_tuning_contract.gd
  - tests/unit/test_nav_tuning_contract.gd.uid
  - tests/unit/test_playtest_strategies.gd
  - tests/unit/test_projectile_vfx.gd
  - tests/unit/test_prototype_map_data.gd
  - tests/unit/test_prototype_map_walls.gd
  - tests/unit/test_prototype_map_walls.gd.uid
  - tests/unit/test_replay_cli_args.gd
  - tests/unit/test_separation_grid.gd
  - tests/unit/test_separation_grid.gd.uid
  - tests/unit/test_shot_list.gd
  - tests/unit/test_sim_rules_guard.gd
  - tests/unit/test_spatial_index.gd
  - tests/unit/test_spatial_index.gd.uid
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_stress_map_data.gd
  - tests/unit/test_stress_map_data.gd.uid
  - tests/unit/test_stress_tool_args.gd
  - tests/unit/test_stress_tool_args.gd.uid
  - tests/unit/test_stuck_tracker.gd
  - tests/unit/test_stuck_tracker.gd.uid
  - tests/unit/test_wall_blocking.gd
  - tests/unit/test_wall_blocking.gd.uid
  - tests/unit/test_wall_data_contract.gd
  - tests/unit/test_wall_data_contract.gd.uid
  - tests/unit/test_wall_decision.gd
  - tests/unit/test_wall_decision.gd.uid
  - tests/unit/test_wall_plot_isolation.gd
  - tests/unit/test_wall_plot_isolation.gd.uid
  - tests/unit/test_wall_solids.gd
  - tests/unit/test_wall_solids.gd.uid
  - tests/unit/test_wall_system.gd
  - tests/unit/test_wall_system.gd.uid
  - tools/gate_stress.sh
  - tools/playtest.sh
  - tools/replay.sh
  - tools/replay/balance_report.gd
  - tools/replay/playtest_bot.gd
  - tools/replay/playtest_strategies.gd
  - tools/replay/replay_driver.gd
  - tools/replay/replay_scenarios.gd
  - tools/replay/sim_recorder.gd
  - tools/screenshot.sh
  - tools/screenshot/shot_crowd_scenarios.gd
  - tools/screenshot/shot_crowd_scenarios.gd.uid
  - tools/screenshot/shot_runner.gd
  - tools/screenshot/shot_scenarios.gd
  - tools/stress.sh
  - tools/stress/data/stress_barracks.tres
  - tools/stress/data/stress_footman.tres
  - tools/stress/data/stress_grunt.tres
  - tools/stress/data/stress_tower.tres
  - tools/stress/data/stress_wall.tres
  - tools/stress/frame_report.gd
  - tools/stress/frame_report.gd.uid
  - tools/stress/frame_report_cli.gd
  - tools/stress/frame_report_cli.gd.uid
  - tools/stress/gate_stress.gd
  - tools/stress/gate_stress.gd.uid
  - tools/stress/gate_stress_cli.gd
  - tools/stress/gate_stress_cli.gd.uid
  - tools/stress/step_bench.gd
  - tools/stress/step_bench.gd.uid
  - tools/stress/stress_map.tres
  - tools/stress/stress_night.gd
  - tools/stress/stress_night.gd.uid
  - tools/stress/stress_night.tscn
  - ui/overlay/crowd_overlay_sections.gd
  - ui/overlay/crowd_overlay_sections.gd.uid
  - ui/overlay/debug_overlay.gd
  - ui/overlay/debug_overlay.tscn
  - ui/overlay/night_overlay_sections.gd
  - ui/world/spot_label_model.gd
findings:
  critical: 0
  warning: 7
  info: 6
  total: 13
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-10-16T20:45:54Z
**Depth:** standard
**Files Reviewed:** 208 (68 `.uid` files confirmed as resource ids with no logic and not analysed)
**Status:** issues_found

## Summary

The Phase 4 simulation core (NavGrid, FlowField with Dial buckets, GoalFieldCache, WallDecision, StuckTracker, WallSystem, WallSolids, EnemyIndex, StructureIndex, bucketed Separation, EnemySystem wall rules) was read line by line and the neighbour order, bucket ring, rescan cadence and ordering invariants hold up. I traced the Dial ring (15 slots against a longest step of 14), the neighbour and side tables of the 8-way flow field, the float-order equivalence of `Separation.displacements_bucketed` against the O(n^2) pass, the wall dawn restore order in `RunManager._enter_dawn`, and the integer tick arithmetic in `WallDecision` (all inside int32 because `MAX_TICKS` is 2^30). No determinism breach was found: no transcendental call, no Dictionary iterated for an outcome (every Dictionary walk is followed by a sort or only erases), no unstable sort on ties. The CI workflow still has `permissions: contents: read`, SHA-pinned `uses:` and no secrets. The tools' argument allowlists and `ReplayCli.safe_dir` use match the expected shape. Every test function in scope contains at least one assertion.

No BLOCKER was found. The 7 warnings are a gap-width validation that does not guarantee what its comment promises, a tangency epsilon in the wall line test, an out-of-grid enemy being treated as walled off, a missing wall-tier health check, two shell-script defects, and a balance acceptance that proves little about walls. The 6 info items are hot-path allocations with concrete fixes (not general advice) and small duplication or cap mismatches. The PLAT-01 budget miss itself is not reported, as instructed.

## Warnings

### WR-01: MIN_GAP_METRES (3 m) does not keep a gap routable on the 2 m grid; the documented guarantee is wrong

**File:** `simulation/walls/wall_validation.gd:9` (also `simulation/defs/nav_tuning.gd:9-10`, `tests/unit/test_map_wall_validation.gd:95-98`)
**Issue:** `NavTuning.cell_size`'s comment says "authored gaps are at least 3 m wide (MIN_GAP_METRES) so 2 m cells keep every gap open", and `WallValidation` accepts a gap of exactly 3.0 m (the test at `test_map_wall_validation.gd:95` pins that acceptance). `NavGrid._mark_near` blocks every cell whose centre is within `half_thickness + inflate` of an intact segment (0.4 + 0.5 = 0.9 m on the shipped data), and a blocked reach is a disc around each segment end. A 3 m gap therefore leaves only 3 - 2 x 0.9 = 1.2 m of open centre line, which is narrower than the 2 m cell pitch, so depending on the alignment of the run to the grid no cell centre may fall inside it and the field would treat the gap as sealed (the `_mark_crossed` pass can only close more). `cell_size` is also allowed up to 8 m (`MAX_CELL_SIZE`), which no gap of the allowed width can survive. The shipped 4 m gaps (open width 2.2 m >= 2 m) happen to be safe, so this is a latent data trap, not a current failure. An enemy that is "sealed" because of it will break the wall even when a gap exists, silently changing the break-or-detour outcome.
**Fix:** Derive the minimum from the grid instead of a constant, and add a routability test on the validator:
```gdscript
# in WallValidation._gaps_ok: replace the MIN_GAP_METRES test with
var tuning: NavTuning = NavGrid.tuning_of(map)
var need: float = tuning.cell_size + 2.0 * (run.half_thickness + NavGrid.largest_radius_of(map))
if high - low < need:
	out.append("%s gap %d is %s m wide, under the %s m the nav grid needs" % [label, index + 1, high - low, need])
```
(`_largest_radius` is already a static on `NavGrid`; expose it.) Also correct the `cell_size` comment, and add a case to `test_map_wall_validation.gd` that builds a 3 m and a 3.8 m gap and asserts `FlowField.is_reached` from the far side.

### WR-02: A circle resting exactly on a wall is reported as blocked by the wall behind it (no tangency epsilon in `first_blocking`)

**File:** `simulation/walls/wall_solids.gd:64`
**Issue:** `WallSolids.push_out` places a circle at `nearest + offset / sqrt(squared) * reach` in float32 `Vector2` arithmetic, i.e. exactly `half_thickness + radius` from the centre line to within one ulp. `first_blocking` then uses the strict test `_segments_distance(...) >= half_thickness + radius` to decide that a line is clear. A body that was just pushed out and now walks directly away can be measured at `reach - 1 ulp` (about 6e-8 at 0.9 m, larger at map coordinates of 50 m) and be reported as blocked by the very wall it is leaning on. Consumers: `EnemySystem._target_walls_in_the_way` (`_take_wall` then switches a target that is behind the wall to the wall), `_can_see`/`StructureIndex._seen` (an adjacent unit on the same side counts as "not seen"), `TargetQuery.nearest_enemy_clear`, `SquadSystem._walk_toward` (flow field used instead of the straight step) and the bot king. The unit test for clearance (`test_wall_blocking.gd:83`, `EPSILON = 0.001`) tolerates the same ulp error on the push-out side, but nothing covers the tangent case on the line-test side.
**Fix:** Give the test the same slack the push-out tests already assume:
```gdscript
const TANGENT_EPSILON: float = 0.001  # metres; a circle resting on a wall is not blocked by it
...
if _segments_distance(from, to, start, end) >= walls.half_thickness_of(segment) + radius - TANGENT_EPSILON:
	continue
```
Add a unit test that pushes a circle out of a segment, then asserts `first_blocking(pushed, pushed + away, radius) == -1` for several offsets and rotations. Replay goldens (smoke, army, walls) must be re-checked because this changes decisions.

### WR-03: An enemy outside the nav grid counts as walled off from the castle

**File:** `simulation/nav/pathing.gd:90-93` (via `simulation/nav/flow_field.gd:429-444`)
**Issue:** `is_sealed` returns true when `FlowField.is_reached(_probe_of(pos))` is false, and `cost_at` returns `INF_COST` for any position outside the grid (`cell_of` returns -1). The grid covers the map content plus `bounds_margin` (10 m), not the 180 m ground, so an enemy that chases the king (or is knocked) more than 10 m beyond the outermost spawn scatter or wall end is, after it drops its target, "sealed": `_aim_at_walls` sets `castle_blocked = false`, it marches straight at the wall and `_breaking_is_faster` sees `detour_ticks == MAX_TICKS` and attacks the wall even though a gap exists. `FlowField.direction_at` is also zero there, so `march_step` falls back to the straight line. The same conflation means StuckTracker switches to centimetre progress for such enemies.
**Fix:** Distinguish "outside the grid" from "walled off": in `is_sealed`, return false when `_grid.cell_of(probe) < 0` (let the straight step carry the enemy back toward the grid), and add a test with an enemy 30 m outside `bounds_margin` and a gap in the wall that expects `castle_blocked == true` once it re-enters the grid.

### WR-04: `WallValidation` never checks that a wall plot's tiers have health

**File:** `simulation/walls/wall_validation.gd:153-176`
**Issue:** `_building_errors` rejects a wall plot whose building pays income, attacks or fields a squad, but not one whose tiers have `max_health <= 0` or an empty `tiers` array. `WallSystem.on_building_built` then writes `_max_health = 0`, so the segment never counts as built (`was_built` stays false, `_state_of` reports UNBUILT), the player pays gold and sees a plot marker that never turns into a wall, and `WallViews.tier_look_of` stays empty. The shipped `data/buildings/wall.tres` is correct and pinned by `test_wall_data_contract`, so this only bites authored or fixture maps (the project validates data "so bad authored geometry is reported instead of arming a wall").
**Fix:** In `_building_errors`, after the existing loop condition, add `if tier.max_health <= 0: out.append("wall plot '%s' uses building '%s' whose tier %d has no health" % [...])` and an `if building_def.tiers.is_empty()` error, with a case in `test_map_wall_validation.gd`.

### WR-05: `tools/stress.sh` accepts `--duration=08` and then dies in bash arithmetic; `STRESS_EXTRA_TIMEOUT_S` is evaluated as arithmetic

**File:** `tools/stress.sh:27-33` and `tools/stress.sh:50`
**Issue:** The allowlist (`''|*[!0-9]*` rejected, then `-lt 5`/`-gt 120`) lets `--duration=08` or `--duration=09` through because `[ ... -lt ... ]` parses decimal. Line 50 then runs `$((WARMUP + DURATION + ${STRESS_EXTRA_TIMEOUT_S:-120}))`, in which `08` is an invalid octal literal; I reproduced `value too great for base (error token is "08")`, so the script aborts with a bash error instead of the documented exit 64. Separately, the environment value is expanded inside `$(( ))`; setting `STRESS_EXTRA_TIMEOUT_S='a[$(cmd)]'` runs `cmd` (reproduced). The environment is the invoking user's own, so this is not a privilege boundary, but it breaks the "bounded integers" shape the tools are expected to have, and the other wrappers (`GATE_TIMEOUT_S`, `PLAYTEST_TIMEOUT_S`, `REPLAY_TIMEOUT_S`) pass theirs to `timeout` unevaluated.
**Fix:** Normalise and validate before use:
```bash
DURATION=$((10#${DURATION}))   # after the digit check, strip leading zeros safely
EXTRA="${STRESS_EXTRA_TIMEOUT_S:-120}"
case "${EXTRA}" in ''|*[!0-9]*) echo "usage: STRESS_EXTRA_TIMEOUT_S must be whole seconds" >&2; exit 64 ;; esac
TIMEOUT_S=$((WARMUP + DURATION + 10#${EXTRA}))
```
Also apply the same `10#` normalisation to the value forwarded as `--duration=` so Godot receives a canonical integer (and bound its length, since `[ "$x" -lt 5 ]` on a 30-digit string errors).

### WR-06: Balance acceptance for the wall bots passes whether or not walls were ever bought or mattered

**File:** `tests/integration/test_balance_acceptance.gd:223-241` (with `tools/replay/playtest_strategies.gd:140-205`)
**Issue:** The walls bots (`balanced`, `army_balanced`) were reordered until they lost exactly the same seeds as their no-walls twins, and the entries were moved "later" because buying walls early cost 6 of 10 seeds. The only evidence that the walls were part of the runs is `assert_gt(extra, 0, ...)` summed over ten seeds, i.e. a single wall tier bought in one seed satisfies it. A change that made walls irrelevant (or broke their purchase in nine of ten seeds) would still pass the D-14 "same outcomes" check, so the acceptance does not prove that walls are neutral to balance, only that a rarely reached order is. The comment in `playtest_strategies.gd:200-203` acknowledges that entries "past what the bot can pay for are never reached".
**Fix:** Pin how many seeds actually bought each run and what the walls changed: assert per seed `walls_bought >= 1` for a minimum count (for example at least 6 of 10 seeds buy `wall_west`), and add the `walls_broken` mean from the per-night table as a lower bound for at least one night so a regression to "walls never engaged" fails.

### WR-07: `test_wall_tracer_scene` bounds a night by wall-clock time

**File:** `tests/e2e/test_wall_tracer_scene.gd:56-62`
**Issue:** The loop waits for DAWN with `Time.get_ticks_msec() - started < 90 s` while the simulation advances by real frame deltas (`RunContext.advance`, clamped by `MAX_ADVANCE_SECONDS`). On a slow or contended CI runner (the lint/test/export matrix shares the host) a clamped frame rate stretches the night past 90 s and the test fails with "dawn within the timeout" although nothing is wrong; on a very fast machine the 1-frame sampling for `saw_inside` can also miss a short pass-through. Time-based bounds are a flakiness source the rest of the suite avoids by stepping `ctx.step()`.
**Fix:** Drive the night with `ctx.advance`/`ctx.step()` in a bounded tick loop (for example `for _i in range(NIGHT_TICK_BOUND)`), check `_any_enemy_inside` after every step, and keep the frame waits only for the view assertions.

## Info

### IN-01: Hot-path allocations in the enemy phase, with the concrete fixes

**File:** `simulation/night/enemy_system.gd:219-232`, `simulation/night/enemy_system.gd:658-678`; `simulation/nav/stuck_tracker.gd:94`; `simulation/squads/separation.gd:107-113`; `simulation/walls/wall_system.gd:129-145`
**Issue:** Given the recorded 18-25 ms step, these are the named wins:
- `EnemySystem.remove_dead` calls `_order.erase(id)` once per dead enemy (O(n) shift each), so a slam that kills 100 of 300 costs about 100 x 300 moves. Rebuild `_order` in one filtering pass (`var kept: Array[int] = []; for id in _order: if _records[id].health > 0: kept.append(id)`) and erase the records of the dead ids only.
- `StuckTracker._observe` calls `enemies.target_of(id)`, which allocates a Dictionary per enemy per tick (300 x 30 per second) only to test `.is_empty()`. Add `EnemySystem.has_target(id) -> bool` and use it; the same applies to `NightOverlaySections.path_rows` and `EnemyPathGizmo`.
- `Separation._partner_sum` builds and `sort()`s a fresh `partners` Array per enemy (300 allocations and sorts per tick). Because the cells already hold ascending indices, merge the nine pre-sorted buckets with a nine-way pointer walk (or sort each bucket once at build) instead of `append_array` + `sort`.
- `EnemySystem._separate` rebuilds four arrays (`alive`, `positions`, `radii`, `ids`) and `ids()` duplicates `_order` each tick; keep the packed arrays as members and refill them in place.
- With walls standing, `WallSolids.push_out` calls `WallSystem.segments_near`, which allocates a PackedInt32Array plus a `_sorted_unique` copy for every enemy every tick even when no segment is within 4 m; an early return on an empty `_buckets.get(key)` for the single-cell case (the common one) avoids both.
**Fix:** As listed per bullet; none changes a decision, but each needs the three replay goldens re-run to prove it.

### IN-02: `segments_near` cost grows with the square of the query reach in `first_blocking`

**File:** `simulation/walls/wall_solids.gd:52-69`, `simulation/walls/wall_system.gd:129-145`
**Issue:** `first_blocking` queries `segments_near(middle, distance / 2 + radius)`, so the Dictionary lookups per call scale with `(distance / 8 + 1)^2` (a 120 m line from spawn to castle is about 240 bucket lookups plus the sort). The notice-range and rescan cadence keep the call count near 20 per tick for marchers, but `StructureIndex._seen`, `TargetQuery.nearest_enemy_clear` and `_can_see` add one per candidate.
**Fix:** Walk the bucket cells along the line (a DDA over the 4 m grid) instead of the bounding box, or early-out with `intact_count() == 0` per run before the query; measure with `tools/stress/step_bench.gd` before and after.

### IN-03: `UnitViews.MAX_VIEWS` (256) is smaller than the simulation can field

**File:** `presentation/units/unit_views.gd:15`
**Issue:** `SquadSystem.MAX_UNITS_PER_SQUAD` is 50 and a map may carry several military plots, so a valid army can exceed 256 units; the surplus is simulated but never drawn (the cap is documented but unvalidated). The same asymmetry does not exist for enemies (512 draw cap against `MAX_ENEMIES_PER_NIGHT` 300).
**Fix:** Size the cap from the map (`sum of tier squad_size over military spots`, bounded) or have `MapConfig.validate` reject a map whose maximum army exceeds the draw cap.

### IN-04: The nav grid ignores the king's radius

**File:** `simulation/nav/nav_grid.gd:282-292`
**Issue:** `_largest_radius` takes the largest of `map.enemies` and `map.units` (0.5 here), but `Pathing.walk_step` also steers the bot king, whose `body_radius` is 0.6 (`data/king/king.tres:13`). The grid is therefore inflated for a smaller agent than one of its users; the bot king hugs walls by up to 0.1 m more than the field assumes and is pushed by `push_out`. No failure today (gap widths are well above), but the comment "the largest ground agent radius on the map" is not true.
**Fix:** Pass the king's body radius into `Pathing`/`NavGrid` (or document that the king is excluded and why), and include it in the WR-01 minimum-gap formula.

### IN-05: Key-packing code is copied into six classes

**File:** `simulation/nav/nav_grid.gd:30-31,275-278`, `simulation/nav/goal_field_cache.gd:256-257,275-278`, `simulation/walls/wall_system.gd:20-21,250-251`, `simulation/squads/separation.gd:16-17,142-143`, `simulation/night/structure_index.gd:168-169,272-273`, `simulation/night/enemy_index.gd:288-289,334-335`; also `SEPARATION_CELL_SLACK` in `enemy_system.gd:12` and `unit_system.gd:10`
**Issue:** `KEY_OFFSET = 1 << 19`, `KEY_STRIDE = 1 << 20` and `(x + OFFSET) * STRIDE + (y + OFFSET)` appear verbatim in six classes (and the slack constant twice). A future change to the range (the 2^19 cell limit is 4 km at an 8 m cell but only 2 km at 4 m) must be made in six places, and `NavGrid._key_of` and `GoalFieldCache.key_of` differ only in how they quantise.
**Fix:** One `CellKey` static helper in `simulation/` (`static func of(cell_x: int, cell_y: int) -> int`) and one shared constant for the separation slack, called from all sites.

### IN-06: `frame_report_cli._write` can leave a file handle open on a partial failure

**File:** `tools/stress/frame_report_cli.gd:155-162`
**Issue:** Both files are opened before the null check; if `report.md` cannot be opened, `report.json` was opened for write and is returned from the function unclosed (it is truncated and only released when the FileAccess is freed). Low impact (local tool), but `_finish` in `stress_night.gd:344-349` has the same open/store/close without checking `store_string`.
**Fix:** Open, write and close one file at a time, and treat a failed open or write as `cannot_write_output`.

---

_Reviewed: 2026-10-16T20:45:54Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
