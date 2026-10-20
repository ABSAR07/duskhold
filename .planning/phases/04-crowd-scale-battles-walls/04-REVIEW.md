---
phase: 04-crowd-scale-battles-walls
reviewed: 2026-10-20T06:25:30Z
depth: standard
files_reviewed: 86
files_reviewed_list:
  - .github/workflows/ci.yml
  - .gitignore
  - ASSETS.md
  - addons/duskhold_sim/duskhold_sim.gdextension
  - assets/attribution.json
  - export_presets.cfg
  - native/.gdignore
  - native/CMakeLists.txt
  - native/src/enemy_step.cpp
  - native/src/gd_math.h
  - native/src/native_enemies.cpp
  - native/src/native_enemies.h
  - native/src/native_field.cpp
  - native/src/native_field.h
  - native/src/native_separation.cpp
  - native/src/native_separation.h
  - native/src/native_sim.cpp
  - native/src/native_sim.h
  - native/src/native_structures.cpp
  - native/src/native_structures.h
  - native/src/native_stuck.cpp
  - native/src/native_stuck.h
  - native/src/native_wall_decision.cpp
  - native/src/native_wall_decision.h
  - native/src/native_walls.cpp
  - native/src/native_walls.h
  - native/src/register_types.cpp
  - native/src/register_types.h
  - presentation/map/map_root.gd
  - simulation/defs/enemy_def.gd
  - simulation/nav/flow_field.gd
  - simulation/nav/nav_grid.gd
  - simulation/nav/pathing.gd
  - simulation/nav/stuck_tracker.gd
  - simulation/nav/wall_decision.gd
  - simulation/night/crowd_read_view.gd
  - simulation/night/enemy_index.gd
  - simulation/night/enemy_system.gd
  - simulation/night/structure_index.gd
  - simulation/night/target_query.gd
  - simulation/squads/separation.gd
  - simulation/walls/wall_solids.gd
  - simulation/walls/wall_system.gd
  - tests/e2e/test_overlay_banner_layout.gd
  - tests/fixtures/trace/enemy_step_refs.txt
  - tests/integration/test_wall_break_to_target.gd
  - tests/unit/test_enemy_store_native.gd
  - tests/unit/test_enemy_trace.gd
  - tests/unit/test_enemy_wall_flags_contract.gd
  - tests/unit/test_field_route_pins.gd
  - tests/unit/test_los_targets.gd
  - tests/unit/test_melee_breaks_to_target.gd
  - tests/unit/test_native_extension.gd
  - tests/unit/test_native_field.gd
  - tests/unit/test_native_math_contract.gd
  - tests/unit/test_native_rules_guard.gd
  - tests/unit/test_native_separation.gd
  - tests/unit/test_native_structures.gd
  - tests/unit/test_native_walls.gd
  - tests/unit/test_separation.gd
  - tests/unit/test_separation_pins.gd
  - tests/unit/test_step_attribution.gd
  - tests/unit/test_step_bench_args.gd
  - tests/unit/test_structure_decision_pins.gd
  - tests/unit/test_stuck_pins.gd
  - tests/unit/test_stuck_tracker.gd
  - tests/unit/test_target_query_pins.gd
  - tests/unit/test_wall_geometry_pins.gd
  - tools/_common.sh
  - tools/export.sh
  - tools/gate_stress.sh
  - tools/godot_cpp_pin.txt
  - tools/native_build.sh
  - tools/playtest.sh
  - tools/replay.sh
  - tools/replay/replay_driver.gd
  - tools/replay/replay_scenarios.gd
  - tools/screenshot.sh
  - tools/screenshot/shot_scenarios.gd
  - tools/stress.sh
  - tools/stress/enemy_trace.gd
  - tools/stress/gate_stress.gd
  - tools/stress/step_attribution.gd
  - tools/stress/step_bench.gd
  - tools/test.sh
  - ui/overlay/debug_overlay.tscn
findings:
  critical: 1
  warning: 11
  info: 16
  total: 28
status: issues_found
---

# Phase 4: Code Review Report (gap-closure plans 04-12 to 04-23)

**Reviewed:** 2026-10-20T06:25:30Z
**Depth:** standard
**Files Reviewed:** 86 (`enemy_index.gd` reviewed as a deletion; the `.gdignore`, pin, fixture and `.tscn` files carry no logic beyond what is noted)
**Status:** issues_found

## Summary

This review covers the native C++17 GDExtension port (enemy store and step, wall solid test, flow-field reads, castle routing, structure index, wall decision, push-apart, nearest-enemy query, stuck tracker), the GDScript facades in front of it, the build, CI and guard tooling, the new stress/trace tools and the tests. The five replay goldens and the per-tick traces prove behaviour is unchanged, so this review looked for what they cannot see.

I read every `native/src` file in full and compared `enemy_step.cpp` and `native_stuck.cpp` against the pre-port GDScript (`git show 2483384:simulation/night/enemy_system.gd`, `git show 5f6cd94:simulation/nav/stuck_tracker.gd`): the target-choice, held-wall, aim-at-walls, advance-and-strike and stuck-observe logic is a faithful port, the visit order is ascending id/index everywhere, and no `std::max/min/clamp`, FMA, transcendental call or unordered container exists in `native/src`. Bounds: every `Packed*Array` access in the bound methods is guarded by a size check, every bound vector index goes through `valid()`, `slot_of()`, `find_unit()` or a range test, and the `ptrw()` calls are on local arrays only. Lifetime: the native objects hold `Ref<>` (no raw pointer outlives a call; `Stepper` holds raw pointers only for the duration of `walk_pass`/`separate_pass`), there is no `Ref` cycle, and every `D_METHOD` name count matches its C++ signature. CI keeps `permissions: contents: read`, SHA-pinned `uses:` and no secrets; the tool CLIs keep their argument allowlists and `ReplayCli.safe_dir`.

What is wrong is mostly around the port rather than in it: one build-script defect that defeats the project's fail-closed stale-library guarantee (CR-01), a user-facing missing-library guard that cannot run (WR-08), a determinism guard that does not scan for a rule it is documented to enforce (WR-09), an unverified godot-cpp worktree (WR-10), and an unbounded loop reachable from a bound method (WR-11). The 13 findings of the 2026-10-16 review are carried below with their current locations: none is fixed, WR-02 and WR-03 were deliberately ported unchanged, IN-01 is largely moot, IN-05 got worse. Limits of this review: I did not run Godot, the suite or the native build; I read the pin/golden test files (`test_*_pins.gd`, `test_native_field/structures/separation.gd`, `test_los_targets.gd`, `test_melee_breaks_to_target.gd`, `test_stuck_tracker.gd`) only for assertion presence and shape (every `test_` function reaches an assertion), not line by line.

## Critical Issues

### CR-01: A failed library copy leaves a valid-looking stamp, so a stale native library passes every guard and can be exported

**File:** `tools/native_build.sh:290-292` (also `tools/native_build.sh:105`, `tools/_common.sh:84-95`)
**Issue:** The script has no `set -e` and checks no copy. Line 290 `cp -f "${BUILD_DIR}/out/${LIB_NAME}" "${OUT_DIR}/${LIB_NAME}"` is unchecked, and line 292 then writes the stamp of the CURRENT sources and line 294 prints `NATIVE_BUILD_OK`. On Windows, `cp` over a DLL that a running Godot process has loaded fails (sharing violation), which is exactly the situation of rebuilding while an editor, a test run or a replay is open. The old DLL stays, the stamp now says "current", and `duskhold_require_native` (`_common.sh:89-91`) compares only the stamp text to the source hash, never the library to the stamp. Every wrapper (`test.sh`, `replay.sh`, `gate_stress.sh`, `playtest.sh`, `stress.sh`, `screenshot.sh`) and `export.sh` then trust a library built from older sources: goldens and the gate can pass or fail against code that is not in `native/src`, and `bash tools/export.sh` on a dev machine can package that DLL into the itch.io build. This is the fail-closed contract of `_common.sh:40-44` broken in the one case that matters (a loaded library). Line 105 (`cp -f` of the dumped API files) has the same unchecked shape.
**Fix:** Invalidate the stamp before touching the library, verify the copy, and bind the stamp to the library bytes:
```bash
rm -f "${OUT_DIR}/${PLATFORM}.stamp"
if ! cp -f "${BUILD_DIR}/out/${LIB_NAME}" "${OUT_DIR}/${LIB_NAME}" \
  || ! cmp -s "${BUILD_DIR}/out/${LIB_NAME}" "${OUT_DIR}/${LIB_NAME}"; then
  echo "NATIVE_BUILD_FAIL: cannot install ${LIB_NAME} (a Godot process may hold it open)" >&2
  exit 1
fi
{ duskhold_native_stamp; sha256sum "${OUT_DIR}/${LIB_NAME}" | cut -d' ' -f1; } >"${OUT_DIR}/${PLATFORM}.stamp"
```
and have `duskhold_require_native` recompute both lines (source stamp and library sha256) so a library swapped or left behind is refused too.

## Warnings

### WR-08: The "no native library, no game" guard in `MapRoot._ready` cannot run in the case it guards

**File:** `presentation/map/map_root.gd:26-31` (and `:49-52`)
**Issue:** The check `ClassDB.class_exists(&"NativeSim")` is a string lookup, but the script that holds it depends, through `RunContext`, on classes that now declare typed members of native classes (`nav_grid.gd:47` `var _native: NativeGrid = NativeGrid.new()`, `wall_system.gd:34`, `flow_field.gd:26`, `enemy_system.gd:39`, `pathing.gd:32`, ...). With the library missing or refused (wrong architecture, antivirus quarantine, deleted DLL next to the exe), those scripts fail to compile ("Identifier NativeGrid not declared"), the dependent scripts then fail to resolve, and `map_root.gd` is not attached before `_ready` can print the friendly message and quit. The player sees a grey window or a script-error log, not "NativeSim missing". Where `_ready` does run, `_process` (line 49) is still called in the same frame because `quit()` is deferred, and dereferences `_ctx`, which is null (`_ctx.king.report_position`, line 51). I could not run Godot here: verify by launching with the DLL renamed.
**Fix:** Do the check in a script that references no native-dependent class, and make it the entry point:
```gdscript
# res://boot.gd (the project's main scene root; no class_name references)
extends Node
func _ready() -> void:
	if not ClassDB.class_exists(&"NativeSim"):
		OS.alert("The native simulation library did not load.\nReinstall the game.", "Duskhold")
		get_tree().quit(1)
		return
	get_tree().change_scene_to_file("res://presentation/map/prototype_map.tscn")
```
and add `set_process(false)` before the early `return` in `MapRoot._ready`.

### WR-09: `test_native_rules_guard.gd` does not scan for the rule `gd_math.h` says it enforces (no `std::max/min/clamp` on floats)

**File:** `tests/unit/test_native_rules_guard.gd:18-91` (claim at `native/src/gd_math.h:49-51`)
**Issue:** `gd_math.h` states "Rules: no std::max, std::min or std::clamp on floats (signed zero and NaN differ from the engine's comparison) ... (tests/unit/test_native_rules_guard.gd scans this file)". `FORBIDDEN_CODE` has patterns for trigonometry, pow/log, `fma`, intrinsics, randomness, time, threads, unordered containers, pragmas and engine singletons, but none for `std::max`, `std::min`, `std::clamp`, `fmax`, `fmin`. Nothing in `native/src` uses them today (I grepped), so the code is right and the guard is not: a future edit that writes `std::max(a, b)` on doubles changes the NaN and signed-zero answer relative to `gd::maxf` and no test fails, unless a golden happens to exercise it.
**Fix:** Add a rule with its own offending sample (the test at line 172 then proves it matches):
```gdscript
[
	"std min, max or clamp (use gd::minf, gd::maxf, gd::clampf)",
	BEGIN + "(std::)?(max|min|clamp|fmax|fmin)\\s*[(<]",
	"double m = std::max(a, b);",
],
```
`maxf(`, `maxi(` and `gd::clampf(` do not match because a letter follows the name. That closes the documented gap.

### WR-10: `native_build.sh` verifies the godot-cpp commit but not that the checkout is unmodified

**File:** `tools/native_build.sh:72-85` (CI: `.github/workflows/ci.yml:71-75`, `:121-125`)
**Issue:** The pin (`tools/godot_cpp_pin.txt`) is enforced by `git rev-parse HEAD == PIN`. That proves the commit, not the files: an edited or partially restored tracked file under `.tools/godot-cpp` (a local experiment, a half-applied checkout, or a restored Actions cache entry, both CI jobs cache that whole directory by pin hash) keeps `HEAD` equal to the pin and is compiled into the shipped DLL. The stamp covers `native/` and the pin file only, so nothing records that godot-cpp itself was altered. `ASSETS.md` and `attribution.json` promise the DLL contains godot-cpp "at commit 2bb1acf".
**Fix:** After the HEAD check add a tracked-file cleanliness check, and make CI discard any drift:
```bash
if [ -n "$(git -C "${GODOT_CPP_DIR}" status --porcelain --untracked-files=no)" ]; then
  fail_toolchain "godot-cpp has local modifications; run: git -C .tools/godot-cpp checkout --force ${PIN}"
fi
```

### WR-11: `separation_displacements_bucketed` does unbounded work for a small caller-chosen `cell`, from a bound static method

**File:** `native/src/native_separation.cpp:126` and `:143-189` (bound at `native/src/native_sim.cpp`, `NativeSim.separation_displacements_bucketed`)
**Issue:** `edge = maxf(cell, 0.001)` and `span = maxi(ceili(2.0 * largest / edge), 1)`; each circle then visits `(2*span+1)^2` cells with a binary search each. With `cell = 0.001` and a normal 0.5 m radius, `span` is 1000 and a circle costs about 4 million lookups, so 300 circles is over a billion searches on the main thread (minutes). The only in-tree caller passes `2 * largest + 0.001` (`enemy_step.cpp:130`, `unit_system.gd:187`), so today it is fine, but the header (`native_separation.h:20-23`) and `native_sim.cpp` expose it to any GDScript with the "bad input answers a default" contract of exact_port_rules 10, and the doc says `cell` "decides how many cells are visited, never an answer". A block larger than the circle count is never cheaper than the pairwise pass.
**Fix:** Fall back to the pairwise routine (bit-identical by the documented contract) when the block exceeds the number of circles:
```cpp
const int64_t side = wrap_add(wrap_mul(2, span), 1);
if (wrap_mul(side, side) >= count) {
	return separation_displacements(positions, radii, ids);
}
```
(`separation_displacements` already allocates its own result; return before `result`/`ptrw()` is taken, or reuse `result`.) Add a case with `cell = 0.001` to `test_native_separation.gd`.

## Info

### IN-07: The view layers still do per-enemy, per-frame script work that the next gap plan can remove

**File:** `presentation/enemies/enemy_views.gd:141-161` and `:201-210`; `presentation/units/unit_views.gd:121-146`; `presentation/vfx/projectile_vfx.gd:159-181` and `:333-357`
**Issue:** Concrete costs, per frame:
- `EnemyViews._process`: for each of up to 300 enemies, `_kind_of.get`, then `_flash_amount()` (a call and a `_hit_ms.get`, even when `_hit_ms` is empty, which is the normal state), `CrowdBatch.add()` (a call plus `_write_data()`, a second call), `_hp_of.has()` and `_hp_of[]` (two lookups for one value), `_max_hp_of.get`. About ten script-level operations per enemy per frame for data that only changes on tick or on an event.
- `UnitViews._process`: `units.ids()` duplicates the `_order` Array every frame (`unit_system.gd:41-42`), then `def_of`, `previous_position_of` and `position_of` each do their own `_records.get(id) as Record` (three Dictionary lookups on the same record), plus `_batch_of.get` and `_hp_of.has`.
- `ProjectileVfx._process`: always loops all 512 slots (`range(MAX_PROJECTILES)`) although `_live` arrows are active; per live arrow `_target_position` runs a `StringName` if-chain and, for an enemy target, two bound calls (`is_alive`, `position_of`, each a binary search), and `arrow_transform` builds three path points with three `lerp`s and two normalisations.
**Fix:** In `EnemyViews`, early-out the flash with `if _hit_ms.is_empty()`, read `_hp_of` once (`var hp: int = _hp_of.get(id, -1)`), and expose the def index in the native read view (`view_defs`) so the kind is a packed-array read instead of a Dictionary; in `UnitViews`, add a `CrowdReadView`-style packed snapshot (ids, previous, current, def index) to `UnitSystem` refreshed on change; in `ProjectileVfx`, stop the slot loop once `seen == _live` and read enemy targets from `read_view()` (ids are ascending, so a binary search on the snapshot replaces two bound calls). These are the loops to port natively: write straight into the `CrowdBatch` mirror from C++.

### IN-08: `CrowdBatch.commit()` uploads the whole buffer every frame, even for an idle batch, and `DeathPuffBatch` scans all slots per death

**File:** `presentation/crowd/crowd_batch.gd:111-115`; `presentation/vfx/death_puff_batch.gd:46-54`, `:57-69`, `:72-80`; call site `presentation/enemies/enemy_views.gd:162-165`
**Issue:** `commit()` assigns `multimesh.buffer = _mirror` (capacity x stride floats: about 40 KB for each enemy archetype batch, 32 KB for the bar batch, 10 KB for puffs) every frame, including by day when `_count == 0` and nothing is drawn; `ProjectileVfx` already skips idle frames, the shared batch does not. `DeathPuffBatch.spawn()` calls `active_count()`, a 128-slot loop with a float division per slot, once per death: a slam that kills 100 enemies costs 12,800 iterations in one frame inside `remove_dead`. `refresh()` runs every frame of the run with no puff standing.
**Fix:** In `CrowdBatch.commit()` return early when `_count == 0 and multimesh.visible_instance_count == 0` (keep `visible_instance_count = 0` on the first idle frame); in `DeathPuffBatch` keep a `_standing` counter updated in `spawn`/`refresh` instead of re-counting, and skip `refresh()` when `_standing == 0` and the last frame drew nothing.

### IN-09: Native helpers copied across files: `wrap_add`/`wrap_mul` six times, `cell_key` four times, `walk_ticks` twice

**File:** `native/src/native_walls.cpp:30-39`, `native_structures.cpp:19-23`, `native_enemies.cpp:18-31`, `native_separation.cpp:28-37`, `native_field.cpp:38-48`, `native_wall_decision.cpp:14-18` and `:168` (`NativeWallDecision::walk_ticks` against the anonymous `walk_ticks` in `native_field.cpp:48`); constants `NativeWallDecision::MAX_TICKS`, `gd::SIM_MAX_TICKS`, `NativeField::INF_COST`, `NativeStuck::STEP_ORTHOGONAL`, `native_field.cpp` `STEP_ORTHOGONAL`
**Issue:** The same wrapping-arithmetic helpers and the same tick rule exist in several files; a fix to one (for example a bound on `walk_ticks`) misses the others, and `walk_ticks` is the kind of function the exact-port contract makes expensive to drift. `gd_math.h` is the one header the table says the port calls.
**Fix:** Move `wrap_add`, `wrap_mul`, `wrap_neg` and `cell_key` into `gd_math.h` (namespace `gd`), call `NativeWallDecision::walk_ticks` from `native_field.cpp`, and define the step and infinity constants once.

### IN-10: Public GDScript facade methods that only tests call, which also force the private-member access `pathing._route`

**File:** `simulation/nav/pathing.gd:100-134` (`is_sealed`, `castle_cost_at`, `castle_distance_cm`, `detour_ticks`, `straight_ticks`, `march_step`); `simulation/night/enemy_system.gd:200-201` (`living_within`); `simulation/walls/wall_system.gd:134-135` (`segments_near`); `simulation/nav/wall_decision.gd:249-283` (`ttd_ticks`, `walk_ticks`, `should_break`, `keep_breaking`); consumer `simulation/night/enemy_system.gd:310` (`pathing._route`)
**Issue:** I grepped `simulation/`, `presentation/`, `ui/`, `input/` and `tools/`: none of these has a production caller, since the native step calls `NativeRoute`, `NativeEnemies.nearest_living` and `NativeWallDecision` directly. They are kept as test oracles (`probe_rules` and the pins compare against `WallDecision`'s statics), but the `wall_decision.gd:208-211` comment says the statics stay "for the GDScript callers that spawn an enemy or draw the overlay", and only `damage_per_300` is called (`enemy_system.gd:77`); the overlay calls none. Six dead `Pathing` methods hold the class at its 20-method cap, and that cap is the stated reason `EnemySystem._hand_over_world` reads the private `pathing._route` (`enemy_system.gd:300-302`). This is the "leftover duplicate body" the exact-port contract forbids, in a mild form.
**Fix:** Delete the six `Pathing` delegates and add `func route() -> NativeRoute`; tests call `pathing.route().detour_ticks(...)`. Move the four `WallDecision` static rules into the test support that uses them (or into `tests/support/`) and fix the comment; drop `EnemySystem.living_within` and `WallSystem.segments_near` or mark them test-only.

### IN-11: Test-only probe code ships in the production library

**File:** `native/src/native_sim.cpp` (`probe_vector`, `probe_double`, `probe_int`, `probe_rules` and all `OP_*` constants, including the `*_CPP` variants that call godot-cpp's own methods); registered in `native/src/register_types.cpp`
**Issue:** About 300 lines of contract-test scaffolding are bound into the DLL that goes to itch.io, widening the public surface of a library loaded into the game process for no runtime use.
**Fix:** Guard them with a `DUSKHOLD_NATIVE_PROBES` compile definition that `tools/native_build.sh` sets for local and test builds (and CI's test job library), and build the exported DLL without it; the contract test already fails loudly when a probe is missing.

### IN-12: No sanitizer or static-analysis pass over the new C++

**File:** `.github/workflows/ci.yml:51-84`, `native/CMakeLists.txt:56-63`
**Issue:** The risks specific to this port (container indexing, `ptrw()` lifetime, signed overflow, float-to-int casts) are exactly what AddressSanitizer and UBSan find, yet CI builds only an optimised release library with `-Wall -Wextra -Werror`. The goldens prove behaviour on the inputs they exercise, not memory safety on the others.
**Fix:** Add a non-shipping `native-linux-asan` job (`-fsanitize=address,undefined -fno-sanitize-recover=undefined`, `LD_PRELOAD` of the ASan runtime for the Godot process) that runs `tools/test.sh` with the `test_native_*` and `*_pins` scripts, and a `-fsanitize=float-cast-overflow` run for IN-15.

### IN-13: The `export` job downloads native artifacts by pattern, not by exact name

**File:** `.github/workflows/ci.yml:246-251`
**Issue:** `pattern: native-*` with `merge-multiple: true` merges any artifact of this run whose name starts with `native-` into `addons/duskhold_sim/bin`. Today that is exactly `native-linux` and `native-windows` (the failure-only log artifact was renamed `windows-replay-logs` to avoid it, line 145), so nothing is wrong, but the rule is "same run, exact name" and the safeguard is a naming convention.
**Fix:** Two `download-artifact` steps with `name: native-linux` and `name: native-windows`, each into the same `path`.

### IN-14: `step_bench.gd --map=stress` runs and reports a different enemy count than it was given

**File:** `tools/stress/step_bench.gd:197-200` (`_build_stress`) and the `--enemies` handling in `parse_args`
**Issue:** `per_group = enemy_count / 4` is integer division: `--enemies=10` builds 8 enemies and prints `enemies=10`; `--enemies=1` to `3` builds none and times an empty night. `step_attribution.gd` rejects non-multiples of 4; `step_bench.gd` does not, so the two tools that must agree on the stress shape disagree on its input. The stress shape is also copy-pasted between `step_bench.gd:_build_stress` and `step_attribution.gd:build_context`.
**Fix:** Reject `--enemies` that is not a multiple of 4 when `--map=stress` (as `step_attribution.gd:_read_enemies` does), and move the shape builder to one shared static function.

### IN-15: Float-to-integer casts and boundary values cross into C++ unchecked

**File:** `native/src/gd_math.h:108-122` (`floori`, `ceili`, `roundi`); callers `native_walls.cpp:210-230` (`near_segments`), `native_enemies.cpp:233-251` and `:254-260`, `native_field.cpp:133-143` (`cell_of`); `native/src/native_structures.cpp:93` and `:189`; `native/src/native_field.cpp:99` (`set_masks`) and `:77-93` (`set_layout`)
**Issue:** Three small things of the same family, none reachable by healthy data:
- `static_cast<int64_t>(std::floor(x))` is undefined behaviour in C++ for NaN, infinity and values beyond 2^63; the header comment says "the hardware converts it" like the engine, which holds on x86-64 only. `NativeStructures::scan` guards `gd::is_finite(pos)`, but the wall mirror, the enemy grid and `NativeGrid::cell_of` do not, so a NaN position gives platform-dependent cells instead of a defined answer.
- `rebuild` narrows 64-bit unit ids with `static_cast<int32_t>(id)` (`native_structures.cpp:93`) and `scan` returns the narrowed `ids_[index]` (`:189`), while `find_unit` compares the full 64-bit `unit_ids_`; an id past 2^31 would be found by `has_unit` but returned as a different number.
- `NativeGrid::set_masks` computes `width_ * height_` (`native_field.cpp:99`) from GDScript integers without an overflow check, and `set_layout` accepts a NaN, zero or negative `cell` (division by zero in `cell_of`) although its comment promises that a layout that cannot size a grid stays unarmed.
**Fix:** Make `gd::floori`/`ceili`/`roundi` saturating (`if (!(x > -9.2e18 && x < 9.2e18)) return x != x ? INT64_MIN : (x < 0 ? INT64_MIN : INT64_MAX);`, which equals the x86 result for NaN and the engine's for in-range values) and add the cases to `test_native_math_contract.gd`; keep ids 64-bit end to end; in `set_layout` require `cell > 0.0 && std::isfinite(cell)` and `width <= INT32_MAX / height`.

### IN-16: `test_living_within_lists_every_living_enemy_in_reach_ascending` asserts the opposite of the documented contract and passes by call order

**File:** `tests/unit/test_enemy_store_native.gd:185-195` (contract at `simulation/night/enemy_system.gd:196-199`, `native/src/native_enemies.cpp:199-207`)
**Issue:** `EnemySystem.living_within` documents that dead enemies not yet removed "may be listed", and `NativeEnemies::damage` leaves `grid_dirty_` unchanged, so an enemy killed after a grid build stays in it until the next dirtying. The test kills `ids[4]` after spawning and before the first query, so the lazy rebuild happens to exclude it, then asserts `assert_false(ids[4] in found, "a dead enemy is not indexed")`. One earlier query in the test would make it fail. Production is safe (`nearest_living` rechecks `health`), but the test pins a behaviour that the facade says it does not guarantee.
**Fix:** Either mark the grid dirty when `damage` brings health to 0 (`native_enemies.cpp:199-207`, one line) and say so in the facade comment, or change the assertion to `assert_true(not _enemies.is_alive(ids[4]))` and filter by `is_alive` in the expectation loop.

## Carried from the 2026-10-16 review

The thirteen findings of the previous review (WR-01 to WR-07, IN-01 to IN-06), original IDs kept, File lines updated to where the code lives now. None is fixed. Status in brief: WR-02 and WR-03 were ported to C++ unchanged on purpose (digest-preserving) and are still defects; IN-01 is largely moot after the port; IN-02 was ported unchanged; IN-05 grew (the key packing now also lives in five C++ files); the rest are untouched by the gap plans.

**Warnings (carried)**

### WR-01: MIN_GAP_METRES (3 m) does not keep a gap routable on the 2 m grid; the documented guarantee is wrong

**File:** `simulation/walls/wall_validation.gd:9` and `:248` (also `simulation/defs/nav_tuning.gd:9-11`, `tests/unit/test_map_wall_validation.gd:95-98`)
**Status (2026-10-20):** open, untouched by the gap plans; the nav grid code is unchanged (`nav_grid.gd:53`, `_mark_near`).
**Issue:** `NavTuning.cell_size`'s comment says authored gaps are at least 3 m wide "so 2 m cells keep every gap open", and `WallValidation` accepts exactly 3.0 m. `NavGrid._mark_near` blocks every cell whose centre is within `half_thickness + inflate` (0.4 + 0.5 = 0.9 m on the shipped data) of an intact segment, so a 3 m gap leaves 3 - 2 x 0.9 = 1.2 m of open centre line, narrower than the 2 m cell pitch: depending on grid alignment no cell centre falls inside it and the field treats the gap as sealed (`_mark_crossed` can only close more). `cell_size` may be up to 8 m. The shipped 4 m gaps (2.2 m open) are safe, so this is a latent data trap. An enemy "sealed" by it breaks the wall although a gap exists.
**Fix:** Derive the minimum from the grid: `need = tuning.cell_size + 2.0 * (run.half_thickness + NavGrid.largest_radius_of(map))` in `WallValidation._gaps_ok` (expose `NavGrid._largest_radius`), correct the `cell_size` comment, and add a routability case (3 m and 3.8 m gaps, `FlowField.is_reached` from the far side) to `test_map_wall_validation.gd`.

### WR-02: A circle resting exactly on a wall is reported as blocked by the wall behind it (no tangency epsilon in `first_blocking`)

**File:** `native/src/native_walls.cpp:290` (`blocking_segment`; was `simulation/walls/wall_solids.gd:64`)
**Status (2026-10-20):** open, ported unchanged on purpose (`native_walls.h:30-32` says fixing it moves a digest). Not moot: the native test is still `segments_distance(...) >= half_[segment] + radius` with no slack.
**Issue:** `pushed_from` (`native_walls.cpp`, `nearest + offset / sqrt(squared) * reach`) places a circle at `half + radius` from the centre line to within one float ulp, and `blocking_segment` clears a line only when the distance is `>= half + radius`. A body just pushed out and now walking away can measure `reach - 1 ulp` and be blocked by the wall it leans on. Consumers: `enemy_step.cpp` `target_walls_in_the_way`/`can_see`, `NativeStructures::seen`, `NativeEnemies::nearest_living`, `SquadSystem._walk_toward`, the bot king.
**Fix:** `if (segments_distance(from, to, start, end) >= half_[segment] + radius - TANGENT_EPSILON)` with `TANGENT_EPSILON = 0.001` (a named constant in `native_walls.cpp`), a test that pushes a circle out and asserts `first_blocking(pushed, pushed + away, radius) == -1`, and a re-pin of the three wall goldens, the wall pin digests and `enemy_step_refs.txt`.

### WR-03: An enemy outside the nav grid counts as walled off from the castle

**File:** `native/src/native_field.cpp:384-389` (`NativeRoute::is_sealed`, via `NativeField::cost_at` at `:208-231`; was `simulation/nav/pathing.gd:90-93`)
**Status (2026-10-20):** open, ported unchanged on purpose (`native_field.h:125-127`).
**Issue:** `is_sealed` is true when `field_->is_reached(probe_of(pos))` is false, and `cost_at` returns `INF_COST` for any position whose `cell_of` is -1 (outside the grid, which covers the map content plus `bounds_margin` 10 m, not the 180 m ground). An enemy more than 10 m past the outermost spawn scatter or wall end that drops its target is "sealed": `aim_at_walls` sets `castle_blocked = false` and `breaking_is_faster` sees `detour_ticks == MAX_TICKS`, so it attacks the wall even though a gap exists; `march_step` falls back to the straight line; `NativeStuck::observe` switches to centimetre progress.
**Fix:** In `is_sealed`, return false when `grid_->cell_of(probe) < 0`; add a test with an enemy 30 m outside the grid and a gap in the wall that expects `castle_blocked == true` after it re-enters. Re-pin as for WR-02.

### WR-04: `WallValidation` never checks that a wall plot's tiers have health

**File:** `simulation/walls/wall_validation.gd:153-176`
**Status (2026-10-20):** open, unchanged.
**Issue:** `_building_errors` rejects a wall plot whose building pays income, attacks or fields a squad, but not tiers with `max_health <= 0` or an empty `tiers` array. `WallSystem.on_building_built` then keeps `_max_health = 0`, the segment never counts as built, the player pays and sees a marker that never becomes a wall. The shipped `wall.tres` is correct and pinned; this bites authored/fixture maps.
**Fix:** In `_building_errors` add `if tier.max_health <= 0:` and `if building_def.tiers.is_empty():` errors, with a case in `test_map_wall_validation.gd`.

### WR-05: `tools/stress.sh` accepts `--duration=08` and then dies in bash arithmetic; `STRESS_EXTRA_TIMEOUT_S` is evaluated as arithmetic

**File:** `tools/stress.sh:28-33` and `:53`
**Status (2026-10-20):** open; the gap plans only added `duskhold_require_native` and `duskhold_seed_extension_list` to this script.
**Issue:** The allowlist (digits only, then `-lt 5`/`-gt 120`) lets `--duration=08` or `09` through; `$((WARMUP + DURATION + ${STRESS_EXTRA_TIMEOUT_S:-120}))` then reads `08` as an invalid octal literal ("value too great for base") and aborts instead of exit 64. The environment value is expanded inside `$(( ))`, so `STRESS_EXTRA_TIMEOUT_S='a[$(cmd)]'` runs `cmd`. The other wrappers pass their timeout to `timeout` unevaluated.
**Fix:** `DURATION=$((10#${DURATION}))` after the digit check; validate `STRESS_EXTRA_TIMEOUT_S` with the same `''|*[!0-9]*` case (exit 64) and use `10#${EXTRA}`; bound the length of both before `[ -lt ]`.

### WR-06: Balance acceptance for the wall bots passes whether or not walls were ever bought or mattered

**File:** `tests/integration/test_balance_acceptance.gd:223-241` (with `tools/replay/playtest_strategies.gd:140-205`)
**Status (2026-10-20):** open, unchanged.
**Issue:** The walls bots were reordered until they lost exactly the seeds of their no-walls twins, and the only evidence walls were in the runs is `assert_gt(extra, 0, ...)` summed over ten seeds: one wall tier in one seed satisfies it, so a regression that made walls irrelevant in nine seeds still passes.
**Fix:** Assert per seed that `wall_west` was bought in at least a floor count (for example 6 of 10) and that the `walls_broken` mean of at least one night is above zero.

### WR-07: `test_wall_tracer_scene` bounds a night by wall-clock time

**File:** `tests/e2e/test_wall_tracer_scene.gd:56-62`
**Status (2026-10-20):** open, unchanged.
**Issue:** The loop waits for DAWN with `Time.get_ticks_msec() - started < 90 s` while the simulation advances by real frame deltas (clamped by `MAX_ADVANCE_SECONDS`); a slow CI runner stretches the night past 90 s and fails a correct build, a fast machine can miss a short pass-through between 1-frame samples.
**Fix:** Drive the night with `ctx.step()` in a bounded tick loop, sample `_any_enemy_inside` every step, keep frame waits only for the view assertions.

**Info (carried)**

### IN-01: Hot-path allocations in the enemy phase, with the concrete fixes

**File:** `native/src/enemy_step.cpp:110-136`, `native/src/native_enemies.cpp:219-226`, `simulation/night/enemy_system.gd:108-112` (was `enemy_system.gd`, `stuck_tracker.gd:94`, `separation.gd`, `wall_system.gd`)
**Status (2026-10-20):** largely moot. Moot: the `_order.erase` per dead enemy (now one `std::vector::erase` of a small struct, `NativeEnemies::remove`), the per-enemy `target_of` Dictionary in the stuck tracker (it reads `view.targeted`), the per-enemy `partners` Array and `sort()` (a reused `std::vector` in `separation_displacements_bucketed`), and the `segments_near` PackedInt32Array allocations (`near_segments` fills a reused scratch). Remaining: `Stepper::separate()` builds a `std::vector<EnemyRec *>`, then fills three Godot packed arrays with a per-element `push_back` (one extension-interface call each) only to hand them to a C++ function that immediately reads them back; `EnemySystem.target_of` still builds a PackedInt64Array plus a Dictionary per call for the overlay and the path gizmo.
**Fix:** Give `duskhold::separation_displacements_bucketed` a raw-pointer core (`const Vector2 *`, `const double *`, `const int64_t *`, count) that `Stepper::separate()` calls on `std::vector` scratch members; keep the packed-array entry point as a thin wrapper for `NativeSim`.

### IN-02: `segments_near` cost grows with the square of the query reach in `first_blocking`

**File:** `native/src/native_walls.cpp:210-255` (and `:274-300` `blocking_segment`; was `wall_solids.gd:52-69`, `wall_system.gd:129-145`)
**Status (2026-10-20):** open, ported unchanged on purpose (`native_walls.h:30-32`). It is cheaper now (a `std::map` lookup per cell and no Dictionary), but the bounding box of a 120 m line is still about 240 cells per call plus a `std::sort` and `std::unique`.
**Fix:** Walk only the cells along the line (a DDA over the 4 m grid), or return early on `intact_ == 0` per run; measure with `tools/stress/step_bench.gd --map=stress`. Only a change that keeps the candidate set identical is digest-safe.

### IN-03: `UnitViews.MAX_VIEWS` (256) is smaller than the simulation can field

**File:** `presentation/units/unit_views.gd:15`
**Status (2026-10-20):** open, unchanged.
**Issue:** `SquadSystem.MAX_UNITS_PER_SQUAD` is 50 and a map may carry several military plots, so a valid army can exceed 256 units and the surplus is simulated but never drawn.
**Fix:** Size the cap from the map (sum of tier `squad_size` over military spots, bounded) or have `MapConfig.validate` reject a larger army.

### IN-04: The nav grid ignores the king's radius

**File:** `simulation/nav/nav_grid.gd:53` and `:291-301`
**Status (2026-10-20):** open, unchanged.
**Issue:** `_largest_radius` takes the largest of `map.enemies` and `map.units` (0.5), but `Pathing.walk_step` also steers the bot king, whose `body_radius` is 0.6 (`data/king/king.tres:13`); the comment "the largest ground agent radius on the map" is untrue.
**Fix:** Pass the king's body radius into `NavGrid`/`Pathing` (or document the exclusion) and include it in the WR-01 minimum-gap formula.

### IN-05: Key-packing code is copied into six classes (now also into five C++ files)

**File:** GDScript: `simulation/nav/nav_grid.gd:30-31,286-288`, `simulation/nav/goal_field_cache.gd:14-15,34-36`. C++: `native/src/native_walls.cpp:30-39`, `native/src/native_structures.cpp:19-23,122,216-217` (+ `native_structures.h:105-106`), `native/src/native_enemies.cpp:18-31` (+ `native_enemies.h` `GRID_KEY_*`), `native/src/native_separation.cpp:28-37`; slack constant `simulation/squads/unit_system.gd:10` and `native/src/native_enemies.h` `SEPARATION_CELL_SLACK`
**Status (2026-10-20):** open and worse. The `wall_system.gd`, `separation.gd`, `structure_index.gd` and `enemy_index.gd` GDScript copies left with the port, but each moved into a C++ file as its own `KEY_OFFSET = 1 << 19`, `KEY_STRIDE = 1 << 20` and `(x + OFFSET) * STRIDE + (y + OFFSET)` (with its own `wrap_add`/`wrap_mul`), and two GDScript copies remain.
**Fix:** One `native/src/cell_key.h` (`inline int64_t cell_key(int64_t x, int64_t y)` plus `wrap_add`/`wrap_mul`) included by the four C++ users; one `CellKey` static helper in `simulation/` for the two GDScript users.

### IN-06: `frame_report_cli._write` can leave a file handle open on a partial failure

**File:** `tools/stress/frame_report_cli.gd:155-164` (and `tools/stress/stress_night.gd:344-349`)
**Status (2026-10-20):** open, unchanged. The new tools repeat the unchecked-write shape: `enemy_trace.gd:166-167` and `step_attribution.gd:298-301` ignore the result of `store_string`/`store_line`.
**Issue:** Both files are opened before the null check; if the second open fails the first stays open and truncated. No tool checks that a store succeeded.
**Fix:** Open, write and close one file at a time and treat a failed open or store as `cannot_write_output`.

---

_Reviewed: 2026-10-20T06:25:30Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
