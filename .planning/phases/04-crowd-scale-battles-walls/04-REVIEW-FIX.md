---
phase: 04-crowd-scale-battles-walls
fixed_at: 2026-10-21T05:30:31Z
review_path: .planning/phases/04-crowd-scale-battles-walls/04-REVIEW.md
iteration: 1
findings_in_scope: 33
fixed: 27
skipped: 6
status: partial
---

# Phase 04: Code Review Fix Report

**Fixed at:** 2026-10-21T05:30:31Z
**Source review:** .planning/phases/04-crowd-scale-battles-walls/04-REVIEW.md (reviewed 2026-10-20T16:16:53Z; 36 findings, of which CR-01, IN-07 and IN-08 were already verified fixed)
**Iteration:** 1 (three sequential fixer batches on the main checkout: A = WR-01 to WR-13 and IN-17, B = IN-06, IN-13, IN-14, IN-16, IN-18 to IN-22, C = IN-01 to IN-05, IN-09 to IN-12, IN-15)

**Summary:**
- Findings in scope: 33
- Fixed: 27
- Skipped: 6

## Fixed Issues

_Batch A_

### WR-12: The stamp records the sources as of install time, so an edit during the build still yields a library with a valid-looking stamp

**Files modified:** `tools/_common.sh`, `tools/native_build.sh`
**Commit:** 10f12a0
**Applied fix:** `native_build.sh` takes `SOURCES_AT_START="$(duskhold_native_stamp)"` right before configure and passes it as a fourth argument to `duskhold_native_install`. The install removes the old stamp, then refuses (`NATIVE_BUILD_FAIL: native sources changed during the build; rebuild`, return 1, no stamp) when the current source stamp differs, and writes the start stamp as line 1 when it is given. `duskhold_native_stamp_for` takes the source stamp as an optional second argument (default: evaluated now, so the checker `duskhold_require_native` is unchanged). Probe cases for it were added under WR-13.
**Status:** fixed

### WR-13: `tools/native_stamp_probe.sh`, the only proof of the fail-closed stamp guard, is run by nothing and has no stale-sources case

**Files modified:** `tools/native_stamp_probe.sh`, `tools/prepush_check.sh`, `.github/workflows/ci.yml`
**Commit:** 3c5303f
**Applied fix:** The probe grew from 7 to 10 cases (`NATIVE_STAMP_PROBE_OK cases=10`). The three new ones run against a miniature root (a copy of the pin file, `native/CMakeLists.txt` and `native/src` under the temp directory, `DUSKHOLD_ROOT` pointed at it after sourcing `_common.sh`): `changed_sources` (a source edited after the install makes the guard return 3), `install_refuses_moved_sources` (the WR-12 refusal, no stamp left, guard 3) and `install_with_start_stamp` (matching start stamp installs and is line 1 of the stamp). `ci.yml` gets a `native stamp guard` step (`bash tools/native_stamp_probe.sh`) in the `lint` job, and `tools/prepush_check.sh` gets a `Native stamp guard` section that fails the check when the probe fails. `permissions: contents: read` and the SHA pins are untouched; the YAML parses (PyYAML).
**Status:** fixed: requires human verification (the CI step cannot run here; the probe and the prepush section were run locally and pass)

### IN-17: `tools/_common.sh` contains a raw carriage return and raw newlines inside quoted strings

**Files modified:** `tools/_common.sh`, `tools/native_build.sh`, `tools/lint.sh`
**Commit:** 68bc2c0
**Applied fix:** The `printf` format in `duskhold_native_stamp_for` was already rewritten to `'%s\n%s\n'` under WR-12. This commit restores `tr -d '\r'` in `duskhold_require_native`, joins the `||` with a normal backslash continuation, and does the same for the collapsed `cp -f ... || fail_toolchain` spacing in `native_build.sh`. `tools/lint.sh` gained the reviewer's guard in a form that works in Git Bash: for every `tools/*.sh` it counts carriage returns with `tr -cd '\r' | wc -c` and sets the lint status to failure on any (the suggested `grep -nP '\r'` does not work in this environment: grep -P rejects the locale, and `$(printf '\r')` loses the CR in Git Bash command substitution). Proven with a planted file (lint reported it) and with the real tree (clean).
**Status:** fixed

### WR-09: `test_native_rules_guard.gd` does not scan for the rule `gd_math.h` says it enforces (no `std::max/min/clamp` on floats)

**Files modified:** `tests/unit/test_native_rules_guard.gd`, `native/src/native_enemy_views.cpp`
**Commit:** 5f225b1
**Applied fix:** A `FORBIDDEN_CODE` rule `(?<![A-Za-z0-9_:.>])(std::)?(max|min|clamp|fmax|fmin)\s*[(<]` with the sample `double m = std::max(a, b);` (the existing self-proof test covers it). The lookbehind differs from the review's `BEGIN` prefix on purpose: with `BEGIN` alone the rule flagged `std::numeric_limits<int32_t>::min()` and `::max()` in `native_structures.cpp:258-259`. `native_enemy_views.cpp:202` now uses `gd::mini` (identical `MIN` on `int64_t`). Native rebuilt.
**Status:** fixed (gates: lint, native build, `-gselect=test_native` 132/132, `_pins` 58/58, `replay_golden` 27/27)

### WR-10: `native_build.sh` verifies the godot-cpp commit but not that the checkout is unmodified

**Files modified:** `tools/native_build.sh`, `.github/workflows/ci.yml`
**Commit:** 6de15ba
**Applied fix:** After the HEAD check, `git -C .tools/godot-cpp status --porcelain --untracked-files=no` must be empty or the build stops with `fail_toolchain "godot-cpp has local modifications; run: git -C .tools/godot-cpp checkout --force <pin>"`. Proven: a line appended to a tracked file of the checkout made the build exit 3 with that message; after `checkout --force` the build passed. Both native CI jobs get a `Discard drift in the cached godot-cpp checkout` step before the build (`git checkout --force --detach <pin>` when the cached checkout exists). YAML parses; `permissions` and SHA pins unchanged.
**Status:** fixed: requires human verification (the CI step cannot run here)

### WR-11: `separation_displacements_bucketed` does unbounded work for a small caller-chosen `cell`, from a bound static method

**Files modified:** `native/src/native_separation.cpp`, `tests/unit/test_native_separation.gd`
**Commit:** 3b6195d
**Applied fix:** `largest` and `span` are now computed before the result array is written to, and when `span >= count`, `2*span+1 >= count` or `(2*span+1)^2 >= count` (wrapping helpers, so a huge span cannot overflow into a false negative) the function returns `separation_displacements(...)` instead. The existing cell-never-changes-an-answer test gained `0.0` and `0.001` as cells (before the fix `0.001` would have cost millions of lookups per circle). Native rebuilt.
**Status:** fixed (gates: lint, native build, `-gselect=separation` 30/30, `test_native` 132/132, `_pins` 58/58, `replay_golden` 27/27)

### WR-05: `tools/stress.sh` accepts `--duration=08` and then dies in bash arithmetic; `STRESS_EXTRA_TIMEOUT_S` is evaluated as arithmetic

**Files modified:** `tools/stress.sh`
**Commit:** f5d1073
**Applied fix:** After the digit check the duration is length-bounded (4 digits, exit 64) and read as `$((10#...))`; `STRESS_EXTRA_TIMEOUT_S` is validated with the same digits-only `case` (exit 64), length-bounded, and used as `10#${EXTRA_TIMEOUT_S}`. Proven without running a stress night: `STRESS_EXTRA_TIMEOUT_S='a[$(echo pwn >&2)]'` exits 64 and prints no `pwn`; `12345` exits 64; `--duration=500`, `--duration=4` and a 17-digit duration exit 64; `$((10#08 + 10#09))` is 17.
**Status:** fixed

### WR-04: `WallValidation` never checks that a wall plot's tiers have health

**Files modified:** `simulation/walls/wall_validation.gd`, `tests/unit/test_map_wall_building_health.gd` (new), `tests/unit/test_map_wall_building_health.gd.uid` (new)
**Commit:** 5226bbb
**Applied fix:** `_building_errors` now reports a wall plot whose building has no tiers ("which has no tiers") or a tier with `max_health <= 0` ("whose tier N has no health"), before the existing income/attack/squad check. `test_map_wall_validation.gd` already holds 20 tests (the gdlint cap), so the three new tests are a new script: the shipped ladder is clean, an empty ladder is reported, and `max_health` 0 and -5 are reported.
**Status:** fixed (gates: lint, `-gselect=wall` 167/167 at that point, new script 3/3, `replay_golden` 27/27)

### WR-01: MIN_GAP_METRES (3 m) does not keep a gap routable on the 2 m grid; the documented guarantee is wrong

**Files modified:** `simulation/walls/wall_validation.gd`, `simulation/nav/nav_grid.gd`, `simulation/defs/nav_tuning.gd`, `tests/unit/test_map_wall_validation.gd`, `tests/unit/test_wall_gap_routable.gd` (new), `tests/unit/test_wall_gap_routable.gd.uid` (new)
**Commit:** 4b1a096
**Applied fix:** The minimum gap is now `max(MIN_GAP_METRES, cell_size + 2 * (half_thickness + largest agent radius))` (3.8 m on the shipped data; the shipped 4 m gaps still pass). `NavGrid._largest_radius` became the public static `largest_radius_of` (the nav grid itself is unchanged, so IN-04's rule not to move the grid radius holds); `WallValidation` computes the grid part once per map (`_grid_gap`) and passes it through `_run_errors` and `_gaps_ok`; a half thickness outside its valid range adds nothing (that case already reports its own error). The `cell_size` comment in `nav_tuning.gd` is corrected. `test_a_gap_exactly_three_metres_wide_is_accepted` (a test of the old rule, not a golden or digest) was replaced by one test that rejects 3.0 and 3.7 m and accepts 3.9 m, keeping the script at 20 tests. The new script sweeps the ring fixture over a 9 x 9 grid of quarter-metre alignments (ring shifted in y, gap moved along the north edge): a 3.85 m gap is accepted by validation and the castle stays reachable from outside at all 81 alignments, and the 3.0 m gap at shift 0 / start 8.25 really seals the ring (found by sweeping: 18 of 81 alignments seal at 3.0 m, 8 at 3.4 m, none at 3.8 m) and is refused by validation. This confirmed the finding empirically (the first attempt, with a finite wall whose ends can be walked around, proved nothing and was replaced).
**Status:** fixed: requires human verification (a validation-rule change; pinned by the new tests, no golden moved: `-gselect=wall` 167/167, `nav` 31/31, `_pins` 58/58, `replay_golden` 27/27, `prototype_map` 36/36)

### WR-06: Balance acceptance for the wall bots passes whether or not walls were ever bought or mattered

**Files modified:** `tests/integration/test_balance_acceptance.gd`
**Commit:** 828bdf0
**Applied fix:** The sum-over-seeds assertion became a per-seed count: for each seed, the economy gold of the walls bot minus that of its no-walls twin must be positive (a wall tier counts as economy gold) in at least `BALANCED_WALL_SEEDS_MIN = 6` seeds of the balanced bot and `ARMY_BALANCED_WALL_SEEDS_MIN = 3` of the army bot. Both floors are the measured counts on seeds 1 to 10 (balanced extras `[2,4,0,2,4,0,2,0,0,2]`, army `[0,4,2,4,0,0,0,0,0,0]`). The run entries do not record which spot was bought, so the gold difference is the per-seed signal; recording spots would change the report tooling. The second half of the suggested fix (a night whose mean `walls_broken` is above zero) was NOT applied: the measurement shows `walls_broken` is 0 in every night of every seed of both bots with walls, so that assertion would fail; a comment in the test records it. `-gselect=test_balance_acceptance` 15/15.
**Status:** fixed in part (per-seed floor applied; the walls-broken assertion is impossible on current data)

### WR-07: `test_wall_tracer_scene` bounds a night by wall-clock time

**Files modified:** `tests/e2e/test_wall_tracer_scene.gd`
**Commit:** d4394b5
**Applied fix:** `_spawn_wall_map` turns the root's `_process` off; the night loop now calls `ctx.step()` in a loop bounded by `SimClock.ticks(180 s)` of simulated time (`NIGHT_LIMIT_SIM_SECONDS`, replacing the 90 s wall-clock `NIGHT_TIMEOUT_S` and `Time.get_ticks_msec`), samples `_any_enemy_inside` after every step, and reports the idle king's position once before the loop (what `_process` did each frame). The frame waits remain only for the rubble view assertions. Passed three times in a row; 2/2.
**Status:** fixed

### WR-08: The "no native library, no game" guard in `MapRoot._ready` cannot run in the case it guards

**Files modified:** `presentation/map/map_root.gd`
**Commit:** 41a7a7c
**Applied fix (in part):** In the failing branch `MapRoot._ready` now also calls `OS.alert("The native simulation library did not load.\nReinstall the game.", "Duskhold")` and `set_process(false)` before the deferred `quit(1)`. Verified by launching Godot headless with the DLL renamed: before the change the log showed the NativeSim message followed by `Invalid access to property or key 'king' on a base object of type 'Nil'` from `_process`; after it the second error is gone (the alert is a no-op headless). The review's suggested boot scene (a new main scene, `res://boot.gd`) was not applied: it changes `application/run/main_scene`, which `tests/e2e/test_walking_skeleton.gd::test_main_scene_is_prototype_map` pins ("project boots straight into the prototype map", a pinned expectation under the owner's stop rule), and the headless launch showed `map_root.gd`'s `_ready` does run when the library is missing, so the grey-window case was not reproduced. `test_walking_skeleton` 4/4 and `test_king_ride` 10/10 pass.
**Status:** fixed in part: requires human verification (the boot-scene half is open for the owner; a windowed launch without the DLL is the check)
_Batch B_

### IN-18: `layout_from` accepts a custom-data offset that overlaps the colour, against its own comment

**Files modified:** `native/src/native_mirror.h`, `tests/unit/test_native_arrows.gd`, `tests/unit/test_native_enemy_views.gd`, `tests/unit/test_native_unit_views.gd`
**Commit:** ff75d31
**Applied fix:** the custom offset must now be at or past the end of the colour (`color_offset + 4`, or 12 when the batch has no colour) as well as inside the stride. Each of the three set_mirror refusal tests got a `[capacity, stride, 12, 12]` case (the enemy and unit ones derive it from the batch's own layout). Native rebuilt; `test_native`, `_pins` and `replay_golden` green.

### IN-19: `configure` takes non-positive or NaN time constants, which make the flash and the puff age NaN

**Files modified:** `native/src/native_enemy_views.cpp`, `native/src/native_puffs.cpp`, `tests/unit/test_native_enemy_views.gd`
**Commit:** 5392b54
**Applied fix:** both `configure` functions now leave the object unconfigured when the flash or puff seconds are `!(x > 0.0)` or not finite (`<cmath>` added). The test script got the 0.0, negative, NaN and INF cases for the flash (a fill draws nothing) and for the puff ring (a spawn stands nowhere). Native rebuilt; goldens and pins unchanged.

### IN-22: `NativeUnitViews` keeps the per-fill write pointers in a member

**Files modified:** `native/src/native_unit_views.cpp`, `native/src/native_unit_views.h`
**Commit:** d9b2c83
**Applied fix:** the `buffers_` member is gone; `fill` holds a local `std::vector<float *>` that is created after the readiness check. One small vector allocation per drawn frame is the price, as in the enemy and puff fills' use of locals. Native rebuilt; `test_native`, `_pins`, `replay_golden` green (the pins prove the mirrors are byte-identical).

### IN-20: Numeric codes are declared twice (C++ enum and GDScript constants) with no test that they agree

**Files modified:** `presentation/vfx/projectile_vfx.gd`, `presentation/enemies/enemy_views.gd`
**Commit:** c36c811
**Applied fix:** `ProjectileVfx.TARGET_*` and `EnemyViews.BAR_BATCH` are now defined from `NativeArrows.TARGET_*` and `NativeEnemyViews.BATCH_BARS`, so the two sides cannot drift. GDScript accepts the bound constants in a `const` initialiser (the scripts load and the projectile, enemy-view and pin tests pass).

### IN-21: Small per-frame allocations and one avoidable mirror copy remain in the view layer

**Files modified:** `native/src/native_arrows.cpp`, `native/src/native_arrows.h`, `presentation/units/unit_views.gd`, `presentation/vfx/projectile_vfx.gd`, `tests/unit/test_native_arrows.gd`
**Commit:** 49da34d
**Applied fix:** (1) `UnitViews` keeps `batch_of_def` in a member and rebuilds it only when the read view object, its `version` or the number of ready batches changed (`_batches_of`); the array handed to `fill` has the same contents as before. (2) New `NativeArrows.unit_flights()` (a counter kept in `launch` and `fill`, reset in `configure`); `ProjectileVfx._process` skips the `slots_targeting` scan and its allocation while it is 0. Tests: `unit_flights` is asserted in the unit-flight test and in the landing test. Pins and replay goldens unchanged.
**Not done:** the third bullet (ping-pong buffers so the batch never holds the array the native class writes next). The review says "if the copy ever matters", the measured p95 is within budget, and it changes the ownership model of every fill; left as is.

### IN-16: `test_living_within_lists_every_living_enemy_in_reach_ascending` asserts the opposite of the documented contract and passes by call order

**Files modified:** `tests/unit/test_enemy_store_native.gd`
**Commit:** 4b772b7
**Applied fix:** the second option only. The assertion `ids[4] not in found` is replaced by `not _enemies.is_alive(ids[4])`; the expectation loop already filters by `is_alive`, so a dead enemy that is still indexed no longer matters and the test no longer depends on call order. Native code untouched.

### IN-14: `step_bench.gd --map=stress` runs and reports a different enemy count than it was given

**Files modified:** `tools/stress/step_bench.gd`, `tests/unit/test_step_bench_args.gd`
**Commit:** 8c8b3cf
**Applied fix:** with `--map=stress`, `parse_args` now refuses an `--enemies` total that is not a multiple of 4 (one-line reason, either argument order), as `step_attribution.gd` does; the usage comment says so. New test `test_the_stress_map_needs_an_enemy_total_that_its_four_groups_share`.
**Not done:** the second half of the fix (moving the stress shape builder, duplicated between `step_bench.gd` and `step_attribution.gd`, to one shared function). It is a refactor of two measurement tools with no behaviour defect; the input mismatch the finding names is closed.

### IN-06: `frame_report_cli._write` can leave a file handle open on a partial failure

**Files modified:** `tools/stress/frame_report_cli.gd`, `tools/stress/stress_night.gd`, `tools/stress/view_ablation.gd`
**Commit:** f2faed7
**Applied fix:** `frame_report_cli._write` opens, writes and closes one file at a time through a new `_write_file`, and a failed open or store gives `cannot_write_output`; `stress_night._finish` and `view_ablation._finish` check the store result (view_ablation no longer opens the file before testing the folder result, so no handle is left open on a failure). Checked by running the report tool for real on a synthetic run (`FRAME_REPORT_OK`, both report files written) and on a missing folder (`FRAME_REPORT_FAILED`); the arg tests of the three tools pass.
**Not done:** the same unchecked-write shape in `enemy_trace.gd:166` and `step_attribution.gd:298`, which the finding lists as "earlier" and which were not in the cited fix; left for a later pass.

### IN-13: The `export` job downloads native artifacts by pattern, not by exact name

**Files modified:** `.github/workflows/ci.yml`
**Commit:** 57c867b
**Status:** fixed: requires human verification (CI cannot run here)
**Applied fix:** the single `pattern: native-*` / `merge-multiple` download is now two `download-artifact` steps with `name: native-linux` and `name: native-windows`, both into `addons/duskhold_sim/bin`. Both names match the upload steps (lines 92 and 149). The invariants hold: `permissions: contents: read`, every `uses:` is a 40-character SHA, no secrets; the YAML parses (PyYAML). Only a CI run proves that two single-artifact downloads into one folder keep both libraries and both stamps, as the merged download did.
_Batch C_

### IN-09: Native helpers copied across files: `wrap_add`/`wrap_mul` six times, `cell_key` four times, `walk_ticks` twice

**Files modified:** `native/src/gd_math.h`, `native/src/native_field.cpp`, `native/src/native_field.h`, `native/src/native_stuck.h`, `native/src/native_wall_decision.cpp`, `native/src/native_wall_decision.h`
**Commit:** e603545
**Applied fix:** `gd::wrap_add`, `gd::wrap_mul` and `gd::wrap_neg` now live once in `gd_math.h` (bodies unchanged). `native_field.cpp` and `native_wall_decision.cpp` lost their private copies; `NativeRoute::detour_ticks` and `straight_ticks` call `NativeWallDecision::walk_ticks` instead of a second copy of the tick rule. `gd::FIELD_INF_COST` and `gd::FIELD_STEP_ORTHOGONAL` are defined once and `NativeField::INF_COST`, `NativeStuck::STEP_ORTHOGONAL` and the `native_field.cpp` constant alias them; `NativeWallDecision::MAX_TICKS` aliases `gd::SIM_MAX_TICKS`. The wrap helpers of the four key files were removed in the IN-05 commit (they share those files with the key packing). Bit-identical: `-gselect=test_native`, `_pins` and `replay_golden` green.

### IN-05: Key-packing code is copied into six classes (now also into five C++ files)

**Files modified:** `native/src/cell_key.h` (new), `native/src/native_walls.cpp`, `native/src/native_structures.cpp`, `native/src/native_structures.h`, `native/src/native_enemies.cpp`, `native/src/native_enemies.h`, `native/src/native_separation.cpp`, `simulation/nav/cell_key.gd` (new), `simulation/nav/cell_key.gd.uid` (new), `simulation/nav/nav_grid.gd`, `simulation/nav/goal_field_cache.gd`, `tests/unit/test_cell_key.gd` (new), `tests/unit/test_cell_key.gd.uid` (new)
**Commit:** 92f7dbf
**Applied fix:** One `gd::cell_key` (with `CELL_KEY_OFFSET` and `CELL_KEY_STRIDE`) in the new header `native/src/cell_key.h`, used by the walls, structures, enemies and separation sources (their private `KEY_OFFSET`/`KEY_STRIDE`/`cell_key`/`grid_key` and wrap copies, and the `GRID_KEY_*` and structures `KEY_*` class constants, are gone). One `CellKey.pack` in `simulation/nav/cell_key.gd` replaces the copies in `NavGrid._key_of` and `GoalFieldCache.key_of`; three new tests pin its arithmetic. Same arithmetic, so keys are unchanged: native tests (135), pins (58), replay goldens (27), nav grid, goal field cache and sim rules guard green. The review's fix wording put `cell_key` in `gd_math.h`; it is a separate header here, as IN-05 itself proposed.

### IN-15: Float-to-integer casts and boundary values cross into C++ unchecked

**Files modified:** `native/src/gd_math.h`, `native/src/native_field.cpp`, `native/src/native_field.h`, `native/src/native_structures.cpp`, `tests/unit/test_native_cast_saturation.gd` (new), `tests/unit/test_native_cast_saturation.gd.uid` (new), `tests/unit/test_native_field.gd`
**Commit:** 8ad7d2f
**Applied fix:** `gd::floori`, `ceili` and `roundi` answer `INT64_MIN` for a NaN and for any value outside [-2^63, 2^63) instead of relying on undefined behaviour. Deviation from the review's suggested snippet: the suggestion saturated positive overflow to `INT64_MAX`, but the engine on x86-64 answers `INT64_MIN` for it, and the byte-equality contract with the engine matters more, so the mirrors answer what the engine does. `NativeGrid::set_layout` now leaves the grid unarmed for a cell that is zero, negative, NaN or infinite and for a layout whose `width * height` would exceed a 32-bit count (so `set_masks` cannot overflow). New test script `test_native_cast_saturation.gd` compares the probes with the engine at NaN, infinities, +-1e19, +-2^63 and the in-range edge values; `test_native_field.gd` gained the layout refusal cases. The 64-bit to 32-bit id narrowing (second bullet) is only documented at `NativeStructures::rebuild`: `scan` answers a `Vector3i` with 32-bit components, so it cannot be kept 64-bit without changing the bound API, and ids would need 2^31 spawns to differ. Status: fixed, with that one bullet documented rather than changed.

### IN-01: Hot-path allocations in the enemy phase, with the concrete fixes

**Files modified:** `native/src/native_separation.cpp`, `native/src/native_separation.h`, `native/src/enemy_step.cpp`
**Commit:** 670e31d
**Applied fix:** `duskhold::separation_displacements_raw` and `separation_displacements_bucketed_raw` (plain pointers plus a caller-owned `SeparationScratch`) hold the algorithm; the two packed-array entry points that `NativeSim` binds are thin wrappers that check sizes first. `Stepper::separate()` fills `std::vector` members and calls the raw core, so it builds no Godot packed arrays and makes no per-element `push_back` extension call. Only the first remaining item of the finding is addressed; `EnemySystem.target_of` (Dictionary per call for the overlay) is untouched. Native tests, pins, goldens and the separation tests green.

### IN-10: Public GDScript facade methods that only tests call, which also force the private-member access `pathing._route`

**Files modified:** `simulation/nav/pathing.gd`, `simulation/nav/wall_decision.gd`, `simulation/night/enemy_system.gd`, `simulation/walls/wall_system.gd`, `tests/integration/test_wall_detour.gd`, `tests/unit/test_field_route_pins.gd`, `tests/unit/test_native_field.gd`, `tests/unit/test_stuck_tracker.gd`
**Commit:** 0164c90
**Applied fix:** The six `Pathing` delegates (`is_sealed`, `castle_cost_at`, `castle_distance_cm`, `detour_ticks`, `straight_ticks`, `march_step`) are deleted and `Pathing.route() -> NativeRoute` added (the class goes from 20 to 15 public methods); `EnemySystem._hand_over_world` uses `pathing.route()` instead of the private `pathing._route`, and the 20-method-cap comment is gone. Test callers use `pathing.route().<method>`. The four `WallDecision` static rules stay in place (moving them would edit more pin files) with the class comment corrected to say they are the oracle of their native twins and that only `damage_per_300` is called by the game; `EnemySystem.living_within` and `WallSystem.segments_near` are marked test-only in their doc comments (the review allowed either). Note for the reviewer: `tests/unit/test_field_route_pins.gd` is a pin file; only eight call expressions changed (`pathing.x(` to `pathing.route().x(`), no digest or expectation was touched and the pin test passes. The header comment of that file still names the old Pathing methods.

### IN-04: The nav grid ignores the king's radius

**Files modified:** `simulation/nav/nav_grid.gd`, `simulation/walls/wall_validation.gd`
**Commit:** abdcc85
**Applied fix:** Comment-only, as ordered. `NavGrid`'s class comment and `largest_radius_of` now say the inflate is the largest enemy or unit radius and that the king (0.6 m, `data/king/king.tres`) is deliberately left out, and why (a larger inflate moves the wall goldens); `WallValidation._grid_gap` carries a matching note. The grid's largest radius is unchanged and WR-01's gap formula keeps using `NavGrid.largest_radius_of`.

## Skipped Issues

_Batch A_

### WR-02: A circle resting exactly on a wall is reported as blocked by the wall behind it (no tangency epsilon in `first_blocking`)

**File:** `native/src/native_walls.cpp:290`
**Reason:** skipped: re-pin required (moves a golden/pin, owner stop rule D-14). The Fix names a re-pin of the three wall goldens, the wall pin digests and `enemy_step_refs.txt`; not attempted.
**Original issue:** `blocking_segment` clears a line only when the distance is `>= half + radius` with no tangency slack, so a body just pushed out of a wall can be blocked by the wall it leans on.

### WR-03: An enemy outside the nav grid counts as walled off from the castle

**File:** `native/src/native_field.cpp:384-389`
**Reason:** skipped: re-pin required (moves a golden/pin, owner stop rule D-14). The Fix says "Re-pin as for WR-02"; not attempted.
**Original issue:** `NativeRoute::is_sealed` is true for any position outside the grid (cost INF), so an enemy more than 10 m past the outermost content that drops its target attacks the wall although a gap exists.
_Batch B_: none skipped.

_Batch C_

### IN-02: `segments_near` cost grows with the square of the query reach in `first_blocking`

**File:** `native/src/native_walls.cpp:210-300`
**Reason:** skipped: a DDA walk along the line changes the candidate set (from the bounding box of the swept circle to the cells the line touches); it can only be called digest-safe by an argument about how segments are registered into the 4 m buckets, which I cannot prove identical here. The `intact_ == 0` early return the review also names already exists in `blocking_segment`. Left as is; measure with `tools/stress/step_bench.gd --map=stress` before any attempt.
**Original issue:** The bounding box of a long query is hundreds of cells per call plus a sort and unique.

### IN-03: `UnitViews.MAX_VIEWS` (256) is smaller than the simulation can field

**File:** `presentation/units/unit_views.gd:20`
**Reason:** skipped: out of scope by owner decision at UAT test 13; recorded without edits.
**Original issue:** A valid army can exceed 256 units and the surplus is simulated but not drawn.

### IN-11: Test-only probe code ships in the production library

**File:** `native/src/native_sim.cpp`, `native/src/register_types.cpp`
**Reason:** skipped: needs a second, probe-less build next to the test build, and I cannot verify the CI half here. In CI the Linux library is both the test library and the one the export job loads, and the Windows library is both replay-tested and exported; only the Windows job could drop the probes without an extra build. Locally, `tools/export.sh` ships whatever library `tools/native_build.sh` last installed (the test build with probes), so a clean exported DLL needs a rebuild before every export and a rebuild back for the tests, and the stamp does not record which surface a library has. A CI-only change would leave the owner's local export unchanged and could not be run here. Follow-up: a `DUSKHOLD_NATIVE_PROBES` CMake option with a `--release-surface` flag on `tools/native_build.sh`, used by the Windows CI job and by `tools/export.sh`, plus a stamp that records the surface.
**Original issue:** About 400 lines of contract-test scaffolding are bound into the DLL that goes to itch.io.

### IN-12: No sanitizer or static-analysis pass over the new C++

**File:** `.github/workflows/ci.yml`, `native/CMakeLists.txt`
**Reason:** skipped: needs a Linux sanitizer run to verify; follow-up. An ASan and UBSan Godot process under `LD_PRELOAD` cannot be run or checked on this machine, and a blind job would add an unverified red check to the pipeline.
**Original issue:** CI builds only an optimised library; memory safety on inputs the goldens do not exercise is not checked.

## Verification

_Batch A_

All gates ran in the main checkout (no worktree, no temp branch, `workflow.use_worktrees` treated as false, branch `gsd/phase-01-foundation-day-loop`), against the `.tools/` Godot 4.7.2 and the MSVC native library built there. Nothing under `.planning/` was written or committed by this batch.

- WR-12 / WR-13 / IN-17: `bash -n` on every shell file touched, `bash tools/native_stamp_probe.sh` (7 cases before, `NATIVE_STAMP_PROBE_OK cases=10` after), `bash tools/native_build.sh` (NATIVE_BUILD_OK, incremental), `bash tools/test.sh -gselect=test_native_rules_guard` (10/10), `bash tools/lint.sh` (now also checks shell files for raw CR), CI YAML parsed with PyYAML (`permissions: {contents: read}`, all `uses:` pinned to 40-character SHAs, no secrets), `bash tools/prepush_check.sh` section run.
- WR-09: lint, native build, `-gselect=test_native` 132/132, `_pins` 58/58, `replay_golden` 27/27.
- WR-10: native build negative and positive cases as described, `test_native_rules_guard` 10/10, YAML parse.
- WR-11: lint, native build, `-gselect=separation` 30/30, `test_native` 132/132, `_pins` 58/58, `replay_golden` 27/27.
- WR-05: the argument cases listed under the finding (no stress night was run).
- WR-04, WR-01: lint, `-gselect=wall`, `nav`, `prototype_map`, the new scripts, `_pins`, `replay_golden`.
- WR-06: `-gselect=test_balance_acceptance` 15/15 (77 s). WR-07: `test_wall_tracer_scene` 2/2 three times. WR-08: DLL-rename launch, `test_walking_skeleton`, `test_king_ride`.
- Goldens, pins, digests and `enemy_step_refs.txt` were not edited; none moved (replay goldens 27/27 and pins 58/58 green after every native or simulation change).
- Final full suite after the last commit (`bash tools/test.sh`, main checkout, 620.9 s): Scripts 223, Tests 2081, Passing Tests 2081, Failing Tests 0, Pending 0 (the line is not printed), Asserts 55185. `bash tools/lint.sh`: 371 files unchanged, "Success: no problems found". The suite grew from 2076 tests in 221 scripts by 5 tests in 2 new scripts (3 in `test_map_wall_building_health`, 2 in `test_wall_gap_routable`); the one flaky test (`test_order_markers`) passed in this run.
- Working tree clean after the last commit; every commit carries the `Co-Authored-By: Claude Sonnet 5.5` trailer.

---

_Fixed: 2026-10-21T04:01:34Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
_Batch B_

All gates ran in the main checkout (no worktree, `wt="."`), not in an isolated worktree, so the numbers are reproducible from the tree as committed.

Per finding:
- IN-18, IN-19, IN-22, IN-21 (native): `bash tools/native_build.sh` (NATIVE_BUILD_OK each time), then `-gselect=test_native` (132 tests, 132 passing), `-gselect=_pins` (58/58) and `-gselect=replay_golden` (27/27), plus `bash tools/lint.sh`. IN-21 also ran `-gselect=unit_views` (19/19) and `-gselect=projectile` (19/19).
- IN-20: lint, `-gselect=projectile` (19/19), `-gselect=enemy_views` (30/30), `-gselect=_pins` (58/58), `-gselect=crowd` (32/32).
- IN-16: lint, `-gselect=enemy_store` (14/14).
- IN-14: lint, `-gselect=step_bench` (9/9), `-gselect=stress_tool` (20/20).
- IN-06: lint, `-gselect=view_ablation`, `-gselect=stress_tool`, `-gselect=stress_night`, a real run of `frame_report_cli.gd` on a synthetic run folder and on a missing folder.
- IN-13: YAML parse and the permissions, SHA-pin and secrets checks; no run possible.
- No golden, pin or digest moved at any step (smoke, army, walls and the SHA-256 pins stayed green and unedited).

Final, after the last commit: full suite `bash tools/test.sh`: Scripts 223, Tests 2082, Passing Tests 2082, Failing 0, Pending 0, Asserts 55224, Time 552.6 s (2081 before this batch, plus one new test in test_step_bench_args). `bash tools/lint.sh`: "371 files would be left unchanged", gdlint "Success: no problems found". `git status` is clean.

Note on line endings: the working-copy .gd test files in this checkout carry CRLF while the index is LF (`eol=lf`); the edits kept each file's existing endings, and git normalises them on commit.

---

_Fixed: 2026-10-21T04:52:07Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
_Batch C_

All gates ran in the main checkout (no worktree), on branch gsd/phase-01-foundation-day-loop; no push.

- IN-09 and IN-05 (shared tree, built once): `bash tools/native_build.sh` (NATIVE_BUILD_OK), then `-gselect=test_native` (132 passing), `-gselect=_pins` (58), `-gselect=replay_golden` (27). For IN-05's GDScript half: `bash tools/lint.sh --fix`, then `-gselect=cell_key` (3), `goal_field` (7), `nav_grid` (12), `sim_rules_guard` (4), `replay_golden` (27). IN-09 was committed before the four key files, which still carried their private helpers, so its commit compiles on its own.
- IN-15: lint, rebuild, `test_native` (135), `_pins` (58), `replay_golden` (27).
- IN-01: rebuild, `test_native` (135), `_pins` (58), `replay_golden` (27), `separation` (30).
- IN-10: `lint.sh --fix`, `_pins` (58), `native_field` (13), `stuck_tracker` (11), `wall_detour` (12), `replay_golden` (27), `wall_decision` (12), `spatial_index` (12), `wall_system` (17), `enemy_store` (14).
- IN-04: lint, `nav_grid` (12), `wall_validation` (20).
- No golden, pin digest, `enemy_step_refs.txt` or gate digest moved or was edited.
- Final run after the last commit: `bash tools/test.sh` (full suite): Scripts 225, Tests 2088, Passing Tests 2088, Failing 0, Pending 0, Asserts 55329 (2082 before plus 3 in `test_cell_key.gd` and 3 in `test_native_cast_saturation.gd`). `bash tools/lint.sh`: 374 files unchanged, "Success: no problems found". No uncommitted changes remain.

Commits are listed oldest first: e603545 (IN-09), 92f7dbf (IN-05), 8ad7d2f (IN-15), 670e31d (IN-01), 0164c90 (IN-10), abdcc85 (IN-04). Fix status flagged for human check: IN-15 (the INT64_MIN choice for positive overflow follows the engine on x86-64, not the review's snippet), IN-10 (edits eight call sites inside a pin test file).

---

_Fixed: 2026-10-21T05:28:40Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

---

_Fixed: 2026-10-21T05:30:31Z_
_Fixer: Claude (gsd-code-fixer, three batches)_
_Iteration: 1_
