---
phase: 04-crowd-scale-battles-walls
reviewed: 2026-10-20T16:16:53Z
depth: standard
files_reviewed: 50
files_reviewed_list:
  - .github/workflows/ci.yml
  - native/src/gd_math.h
  - native/src/native_arrows.cpp
  - native/src/native_arrows.h
  - native/src/native_enemy_views.cpp
  - native/src/native_enemy_views.h
  - native/src/native_mirror.h
  - native/src/native_puffs.cpp
  - native/src/native_puffs.h
  - native/src/native_sim.cpp
  - native/src/native_sim.h
  - native/src/native_unit_views.cpp
  - native/src/native_unit_views.h
  - native/src/register_types.cpp
  - presentation/crowd/crowd_batch.gd
  - presentation/enemies/enemy_views.gd
  - presentation/units/unit_views.gd
  - presentation/vfx/death_puff_batch.gd
  - presentation/vfx/projectile_vfx.gd
  - simulation/squads/unit_read_view.gd
  - simulation/squads/unit_read_view.gd.uid
  - simulation/squads/unit_system.gd
  - tests/unit/test_crowd_batch.gd
  - tests/unit/test_enemy_fill_pins.gd
  - tests/unit/test_enemy_fill_pins.gd.uid
  - tests/unit/test_native_arrows.gd
  - tests/unit/test_native_arrows.gd.uid
  - tests/unit/test_native_enemy_views.gd
  - tests/unit/test_native_enemy_views.gd.uid
  - tests/unit/test_native_unit_views.gd
  - tests/unit/test_native_unit_views.gd.uid
  - tests/unit/test_native_view_math_contract.gd
  - tests/unit/test_native_view_math_contract.gd.uid
  - tests/unit/test_projectile_fill_pins.gd
  - tests/unit/test_projectile_fill_pins.gd.uid
  - tests/unit/test_unit_fill_pins.gd
  - tests/unit/test_unit_fill_pins.gd.uid
  - tests/unit/test_unit_read_view.gd
  - tests/unit/test_unit_read_view.gd.uid
  - tests/unit/test_view_ablation.gd
  - tests/unit/test_view_ablation.gd.uid
  - tests/unit/test_view_fill_bench_args.gd
  - tests/unit/test_view_fill_bench_args.gd.uid
  - tools/_common.sh
  - tools/native_build.sh
  - tools/native_stamp_probe.sh
  - tools/stress/view_ablation.gd
  - tools/stress/view_ablation.gd.uid
  - tools/stress/view_fill_bench.gd
  - tools/stress/view_fill_bench.gd.uid
findings:
  critical: 0
  warning: 13
  info: 20
  total: 33
status: issues_found
---

# Phase 4: Code Review Report (gap round 2, plans 04-24 to 04-28)

**Reviewed:** 2026-10-20T16:16:53Z
**Depth:** standard
**Files Reviewed:** 50 (37 source files read; the 13 `.gd.uid` siblings are Godot resource ids with no logic)
**Status:** issues_found

## Summary

This round did three things: it bound the native stamp to the library bytes (04-24), moved the four per-frame view fills (arrows, enemies, units, puffs) into C++ behind pinned GDScript facades (04-25 to 04-27), and measured the result (04-28, no code). I read every changed `native/src` file in full (`native_arrows`, `native_enemy_views`, `native_unit_views`, `native_puffs`, `native_mirror.h`, the `gd_math.h` and `native_sim` diffs, `register_types.cpp`), the five rewritten GDScript facades and `CrowdBatch`, `UnitSystem.read_view`, the stamp helpers and probe, the two stress tools, and the new tests (the three `*_fill_pins` files and `test_native_arrows`, `test_unit_read_view`, `test_view_ablation`, `test_view_fill_bench_args` in whole or in their driver parts). I compared each native fill with the GDScript it replaced (`git show 6434327:presentation/...`) for narrowing, visit order, cap and capacity handling, the flash/forget order, the hurt-only bar rule and the target-follow rule, and I compared the Vector3 rows of `gd_math.h` with the copies in `.tools/godot-cpp/include/godot_cpp/variant/vector3.hpp` (`length`, `length_squared`, `cross`, `lerp`, `normalize` including the non-finite fallback): all agree. The three pin files each have exactly one commit (`b7f29f6`, `e3a5b4a`, `5c78be5`), which is the "never edited" claim. No new `std::max/min/clamp` on floats, FMA, time, randomness or engine singleton exists in the new native files, bounds are checked at every entry (layout, sizes, slots, indices, batch numbers), the binary searches run over ids that the read views guarantee ascending, and CI still has `permissions: contents: read`, SHA-pinned `uses:` and no secrets (the diff is two comment lines).

The three claimed fixes hold (sections below): CR-01 is fixed for the failure it named, IN-07 and IN-08 are fixed. What remains is around the fix rather than in the port: the new stamp still records the sources as of install time, not as of build time, so a source edit during a build still yields a library with a valid-looking stamp (WR-12); the seven-case probe that proves the guard is run by nothing, and it has no stale-sources case (WR-13); and six small items in the new C++ and tools (IN-17 to IN-22). No new critical finding. The 25 findings that were not claimed fixed are carried below; the facts of WR-08, WR-09, IN-03, IN-06, IN-11, IN-12, IN-15 and the line numbers of WR-10 moved with this round and are updated in place.

Limits of this review: I did not run Godot, the suite, the native build or a shell script (read-only, as instructed). I read `test_native_view_math_contract.gd` from the top to its helpers (lines 1 to 120) and `test_native_enemy_views.gd`, `test_native_unit_views.gd`, `test_unit_fill_pins.gd` and `test_projectile_fill_pins.gd` for assertion presence, structure and the driver code, not every assertion; the plan files and `04-RESEARCH.md` were consulted for the `exact_port_rules` and DR rules (the 04-26 plan text for the rules, the research file for DR-1 to DR-10) and the SUMMARY deviation sections, not read end to end. The performance numbers in the SUMMARYs are taken as recorded.

### Fix CR-01 verified: the stamp now binds the library bytes (fixed, with the residuals WR-12 and WR-13)

The failure CR-01 named, a copy that fails because Godot holds the DLL open leaving a valid-looking stamp, can no longer happen:

- `tools/_common.sh:102-120` (`duskhold_native_install`): the old stamp is removed first (`:108`), the copy is checked by exit status and by `cmp -s` (`:109`), and the new stamp is written to a temp file and moved into place only after that (`:113-118`); on any failure it prints `NATIVE_BUILD_FAIL` and returns 1 with no stamp.
- `tools/native_build.sh:294` ends the build with `duskhold_native_install ... || exit 1`, before `NATIVE_BUILD_OK` (`:296`). The API-file copy that CR-01 also named is now checked (`:106`, `fail_toolchain`).
- `tools/_common.sh:86-95` (`duskhold_native_stamp_for`) prints two lines, the source stamp and the library's sha256, and returns 1 for a missing file; `:126-140` (`duskhold_require_native`) recomputes both from the installed file and compares the whole stamp file (CR stripped) with them, so a missing library, a missing stamp, a one-line (old-format) stamp, a changed library and a swapped library of the same size all return 3. Writer and checker share the one function, so they cannot drift.
- `tools/native_stamp_probe.sh` exercises these seven cases against a temp directory.

Residuals, none of which reopen the named failure: the source half of the stamp is taken at install time (WR-12), the probe is not run by anything (WR-13), and `_common.sh` now contains raw control characters (IN-17).

### Fix IN-07 verified: the per-frame view loops run in C++ (fixed)

- `ProjectileVfx._process` (`presentation/vfx/projectile_vfx.gd:142-156`) is one native `fill` plus a `commit_buffer`; the 512-slot GDScript loop, the per-arrow `StringName` if-chain, the two bound calls per enemy target and the three `lerp`s and normalisations are gone. Enemy targets come from the read view by binary search (`native_arrows.cpp:166-176`); only friendly-unit arrows are resolved in GDScript (`:147-153`).
- `EnemyViews._process` (`presentation/enemies/enemy_views.gd:136-151`) is one `fill` over `read_view()` and five `commit_buffer` calls; the per-enemy `_kind_of`/`_hit_ms`/`_hp_of`/`_max_hp_of` Dictionary reads, `_flash_amount` calls and `CrowdBatch.add` calls are now `NativeEnemyViews::fill` (`native_enemy_views.cpp:186-260`) over a sorted record vector.
- `UnitViews._process` (`presentation/units/unit_views.gd:134-146`) reads `UnitSystem.read_view()` (`simulation/squads/unit_system.gd:50-76`), which replaces the per-frame `ids()` duplicate and the three record look-ups per unit with packed arrays refilled only when `_changes` moved; `NativeUnitViews::fill` does the rest.
- The ports are line by line: same visit order, same narrowing (`lerp` weight to `real_t`, bar height computed in double and narrowed once), same cap-before-capacity order, flash forgotten before the capacity test, hurt-only rule copied with its source named. The SHA-256 pins over the whole batch mirrors (stale tail included) were computed on the GDScript and each pin file has a single commit.

What is left is small and listed as IN-21 (one `PackedInt32Array` allocation per frame in `UnitViews`, one per frame in `ProjectileVfx`, and the copy-on-write copy of each written mirror).

### Fix IN-08 verified: idle batches stop uploading and the puff scans are native (fixed)

- `CrowdBatch.commit()` (`presentation/crowd/crowd_batch.gd:113-119`) returns early when `_count == 0 and multimesh.visible_instance_count == 0`; the first empty frame after a drawn one still uploads and sets the count to 0 (tested by `test_an_idle_batch_uploads_no_buffer_until_something_is_drawn`).
- The native fills take a mirror for writing only when they write its first instance (`native_enemy_views.cpp:234-236`, `:251-253`; `native_unit_views.cpp:229-231`, `:247-249`; `native_puffs.cpp:84-86`), so an idle frame does not detach the shared mirror either. `NativeArrows::fill` takes `ptrw()` unconditionally (`native_arrows.cpp:156`), but `ProjectileVfx._process` returns before calling it while nothing flies or is drawn (`projectile_vfx.gd:145-146`).
- `DeathPuffBatch` (`presentation/vfx/death_puff_batch.gd:46-59`) hands `spawn` and `refresh` to `NativePuffs`; the per-death 128-slot count (`native_puffs.cpp:47-60`, `:94-103`) is now native, about 128 divisions per death. The per-frame `refresh()` with no puff standing remains but is a native scan that does not copy the mirror.
- The argument-order defect the 04-26 SUMMARY records (`commit_buffer(mirror(), refresh())` evaluating the stale array) is fixed at `death_puff_batch.gd:58-59` with a comment, and `EnemyViews` calls `fill` before it takes the mirrors (`enemy_views.gd:144-147`).

## Critical Issues

None. The one critical finding of the previous review (CR-01) is verified fixed above.

## Warnings

### WR-12: The stamp records the sources as of install time, so an edit during the build still yields a library with a valid-looking stamp

**File:** `tools/_common.sh:102-120` (source stamp taken at `:114` through `:94`), `tools/native_build.sh:181-294` (configure at `:181`, build at `:266`, install at `:294`)
**Issue:** CR-01's contract is "the stamp binds what the library was built from". The library half is now the installed bytes, but the source half is `duskhold_native_stamp` evaluated inside `duskhold_native_install`, after configure (`:181`) and build (`:266`) have finished. A first build compiles every godot-cpp binding (the header says 10 to 30 minutes), an incremental one takes a minute or more, and this project is edited by agents and by hand while builds run. If anything under `native/src`, `native/CMakeLists.txt` or `tools/godot_cpp_pin.txt` changes after CMake read it and before line 294, the library is compiled from the old sources and stamped with the hash of the new ones. `duskhold_require_native` then recomputes the same current hash and accepts it, so goldens, the gate and `tools/export.sh` run against code that is not in `native/src`. This is the stale-library state CR-01 was about, reached by a race instead of a failed copy.
**Fix:** Take the source stamp before configuring and refuse to install when it moved:
```bash
# native_build.sh, right after the platform case (before step 3)
SOURCES_AT_START="$(duskhold_native_stamp)"
# step 7
duskhold_native_install "${BUILD_DIR}/out/${LIB_NAME}" "${OUT_DIR}" "${PLATFORM}" \
  "${SOURCES_AT_START}" || exit 1
```
```bash
# _common.sh: duskhold_native_install takes an optional 4th argument, the stamp taken at the start
local sources_at_start="${4:-}"
if [ -n "${sources_at_start}" ] && [ "$(duskhold_native_stamp)" != "${sources_at_start}" ]; then
  echo "NATIVE_BUILD_FAIL: native sources changed during the build; rebuild" >&2
  return 1
fi
```
(placed after `rm -f "${stamp}"`), and write `${sources_at_start}` as line 1 when it is given (let `duskhold_native_stamp_for` take it as an optional second argument). Add a probe case for it (see WR-13).

### WR-13: `tools/native_stamp_probe.sh`, the only proof of the fail-closed stamp guard, is run by nothing and has no stale-sources case

**File:** `tools/native_stamp_probe.sh:1-101` (callers: none in `.github/workflows/ci.yml`, `tools/test.sh`, `tools/prepush_check.sh` or any test; a repository search finds only the script's own header)
**Issue:** The CR-01 fix is a security gate (a stale library must make every wrapper exit 3), and its regression test is a script someone must remember to run by hand. A later edit to `_common.sh` (for example the raw-character cleanup in IN-17, or a "simplified" `duskhold_require_native`) can reopen CR-01 with every golden and unit test still green. The probe also lacks the most common staleness path: its seven cases vary the library and the stamp but never the sources (it uses the real `native/src`, whose hash it cannot change), so "sources changed after install" is untested.
**Fix:** Run it where it costs nothing: it needs no Godot and no build, only `sha256sum` over the sources. Add `- name: native stamp guard` / `run: bash tools/native_stamp_probe.sh` to the `lint` job in `.github/workflows/ci.yml` and a line to `tools/prepush_check.sh`. For the missing case, let the probe build a miniature root: copy `tools/godot_cpp_pin.txt`, `native/CMakeLists.txt` and `native/src` into the temp directory, set `DUSKHOLD_ROOT` to it after sourcing `_common.sh` (`duskhold_native_stamp` does `cd "${DUSKHOLD_ROOT}"` at call time), install, append a line to one copied source file and expect `guard_code` 3; with WR-12 fixed, also expect the install itself to refuse when the sources change between the start stamp and the install.

## Info

### IN-17: `tools/_common.sh` contains a raw carriage return and raw newlines inside quoted strings

**File:** `tools/_common.sh:92-94` and `:135`
**Issue:** The 04-24 edit replaced escape sequences with the control characters themselves: the `printf` format at `:92-94` is `'%s<LF>%s<LF>'` spread over three physical lines, and the stamp comparison at `:135` is `tr -d '<CR>'` (a literal 0x0D between the quotes; the previous version had `'\r\n'`), with a run of spaces where a continuation was collapsed. It works today, but a lone CR survives `* text=auto eol=lf` normalisation only by luck: an editor, a formatter or `git add --renormalize` that strips it turns line 135 into `tr -d ''`, which deletes nothing, and a stamp with a CR then no longer matches (fail-closed, but every wrapper exits 3 for no visible reason). `tools/native_build.sh:106` has the same collapsed-continuation spacing.
**Fix:** Restore the escapes: `printf '%s\n%s\n' "$(duskhold_native_stamp)" "${lib_sha}"` and `[ "$(tr -d '\r' <"${stamp_file}")" != "${expected}" ]`, with the `||` joined normally; let a lint step run `grep -nP '\r' tools/*.sh` and fail on a match.

### IN-18: `layout_from` accepts a custom-data offset that overlaps the colour, against its own comment

**File:** `native/src/native_mirror.h:32-35` (comment) and `:55-63` (checks)
**Issue:** The comment promises that "the transform, the colour (when there is one) and the custom data each fit inside the stride behind the previous one". The code checks `color_offset >= 12` and `custom_offset >= 12` and both `<= stride - 4`, but never `custom_offset >= color_offset + 4`. A layout `[capacity, 20, 12, 12]` is accepted, and `write_transform`/`write_origin` then write the custom data over the colour on every instance. It cannot leave the mirror, so rule 10's "never an out-of-bounds read" holds; but the refusal tests (`tests/unit/test_native_arrows.gd:44-64`, and the matching ones in the enemy and unit tests) do not cover it, and the contract is stated more strongly than it is enforced. `CrowdBatch.layout()` is the only producer and is consistent, so this is a hardening gap.
**Fix:** `const int64_t earliest = candidate.color_offset == -1 ? TRANSFORM_FLOATS : candidate.color_offset + COLOR_FLOATS;` and `if (candidate.custom_offset < earliest || candidate.custom_offset > candidate.stride - CUSTOM_FLOATS) return false;`, plus a `[capacity, 20, 12, 12]` case in the three `set_mirror` refusal tests.

### IN-19: `configure` takes non-positive or NaN time constants, which make the flash and the puff age NaN

**File:** `native/src/native_enemy_views.cpp:49-72` (division at `:166`) and `native/src/native_puffs.cpp:19-34` (divisions at `:77` and `:97`)
**Issue:** The headers promise that every value crossing from GDScript is checked, and both configures validate the capacity but store `flash_seconds` and `puff_seconds` as given. With 0 (or NaN), the flash is `1.0 - elapsed_s / 0.0`, which is NaN at the hit instant, passes `amount <= 0.0` as false and is written into the custom colour; the puff age is NaN, so the puff is drawn (`age < 0.0 || age >= 1.0` is false) but not counted by `active_count()` (`age >= 0.0` is false), so the cap test undercounts and a full ring is overwritten. Today the callers pass the constants 0.15 and 0.6, so nothing is wrong at runtime; it is the same "bad input answers a default" gap rule 10 closes for sizes.
**Fix:** In both `configure` functions leave the object unconfigured when `!(seconds > 0.0) || !std::isfinite(seconds)` (clear the ring or `configured_` first, as the capacity check does), and add a `configure(…, 0.0, …)` case to `test_native_enemy_views.gd` (both classes are covered there).

### IN-20: Numeric codes are declared twice (C++ enum and GDScript constants) with no test that they agree

**File:** `presentation/vfx/projectile_vfx.gd:55-58` against `native/src/native_arrows.h:59-64`; `presentation/enemies/enemy_views.gd:46` (`BAR_BATCH = 3`) against `native/src/native_enemy_views.h:57-60` (`BATCH_BARS = 3`)
**Issue:** `ProjectileVfx.TARGET_FIXED/ENEMY/UNIT/KING` repeat `NativeArrows::TARGET_*`, and `EnemyViews.BAR_BATCH` repeats `NativeEnemyViews::BATCH_BARS`, although both C++ values are bound to GDScript (`BIND_CONSTANT`) and the tests already read them through the class (`NativeArrows.TARGET_FIXED`). A change on one side silently reroutes arrows (a unit target treated as an enemy) or sends the bars to an archetype mirror; the pins would catch it only on paths they drive (the stress night has enemy and king targets, the replays few unit shots).
**Fix:** Define the GDScript constants from the native ones (`const TARGET_ENEMY: int = NativeArrows.TARGET_ENEMY`, `const BAR_BATCH: int = NativeEnemyViews.BATCH_BARS`), or add a two-line test asserting equality.

### IN-21: Small per-frame allocations and one avoidable mirror copy remain in the view layer

**File:** `presentation/units/unit_views.gd:139-143`, `presentation/vfx/projectile_vfx.gd:147`, `presentation/crowd/crowd_batch.gd:143`
**Issue:** Three leftovers of the hot paths, none of which threatens the measured p95 (5.37 ms, owner-recorded):
- `UnitViews._process` allocates a `PackedInt32Array` and loops `view.defs` every frame to build `batch_of_def`, which only changes when `_batch_index_of` or `view.defs` changes.
- `ProjectileVfx._process` calls `_native.slots_targeting(TARGET_UNIT)` every frame, allocating a `PackedInt32Array` even when no friendly archer arrow is in the air.
- `CrowdBatch.commit_buffer` keeps the array it was handed as `_mirror` (`:143`), so the native class and the batch share it, and the next frame's first `ptrw()` detaches (copies) it: about 41 KB per drawn enemy archetype batch, 33 KB for bars and 41 KB for arrows each frame, plus the upload copy.
**Fix:** Cache `batch_of_def` and rebuild it only when `view.version` or `_batches.size()` changes; add `NativeArrows.unit_flights() -> int` (a counter kept in `launch`/`fill`) and skip the loop when it is 0; if the copy ever matters, let the native class keep two buffers and ping-pong them so it never writes the one the batch holds.

### IN-22: `NativeUnitViews` keeps the per-fill write pointers in a member

**File:** `native/src/native_unit_views.h:141` (`buffers_`), `native/src/native_unit_views.cpp:188-191`, `:229-232`
**Issue:** `buffers_` stores raw `float *` from `ptrw()` as a member although they are only used inside `fill`. After `fill` returns, GDScript takes `mirror(i)` and hands it to `commit_buffer`, and a later `set_mirror`/`configure` replaces or frees the arrays, so the pointers dangle between calls. They are reset to `nullptr` at the top of every `fill` and never read elsewhere, so there is no bug today, but it is the lifetime hazard class of IN-12 and a trap for the next edit (the enemy and puff fills correctly use locals).
**Fix:** Make it a local `std::vector<float *> buffers(counts_.size(), nullptr)` (or a small fixed array) inside `fill` and delete the member.

## Carried findings (not re-reviewed)

The thirteen findings WR-01 to WR-07 and IN-01 to IN-06 (2026-10-16 review) and the findings WR-08 to WR-11, IN-09 to IN-16 (second review, 2026-10-20T06:25:30Z) are carried with their ids and titles unchanged. The files they cite are untouched by this round except where a note says so; I did not re-review them. IN-03 stays out of scope by owner decision at UAT test 13. Notes marked "Round 2" record what this round changed in the facts.

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

### WR-08: The "no native library, no game" guard in `MapRoot._ready` cannot run in the case it guards

**File:** `presentation/map/map_root.gd:26-31` (and `:49-52`)
**Status (round 2):** open and slightly wider. `map_root.gd` is unchanged, but the view layer added four more scripts that declare typed native members and therefore fail to compile when the library is missing: `presentation/vfx/projectile_vfx.gd:64` (`NativeArrows`), `presentation/enemies/enemy_views.gd:56` (`NativeEnemyViews`), `presentation/vfx/death_puff_batch.gd:21` (`NativePuffs`), `presentation/units/unit_views.gd:64` (`NativeUnitViews`), on top of the simulation scripts named below.
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

**File:** `tests/unit/test_native_rules_guard.gd:18-91` (claim at `native/src/gd_math.h:67-69`)
**Status (round 2):** open. The claim moved from `:49-51` to `:67-69` (the Vector3 table was added above it). One integer `std::min` now exists in the native sources, `native/src/native_enemy_views.cpp:202` (`std::min(static_cast<int64_t>(lifts_.size()), static_cast<int64_t>(BATCH_BARS))`): it is on `int64_t`, so the rule's concern (signed zero and NaN) does not apply, but the pattern proposed below would flag it, so the fix needs the line rewritten or an allowance.
**Issue:** `gd_math.h` states "Rules: no std::max, std::min or std::clamp on floats (signed zero and NaN differ from the engine's comparison) ... (tests/unit/test_native_rules_guard.gd scans this file)". `FORBIDDEN_CODE` has patterns for trigonometry, pow/log, `fma`, intrinsics, randomness, time, threads, unordered containers, pragmas and engine singletons, but none for `std::max`, `std::min`, `std::clamp`, `fmax`, `fmin`. No float use exists in `native/src` today (I grepped), so the code is right and the guard is not: a future edit that writes `std::max(a, b)` on doubles changes the NaN and signed-zero answer relative to `gd::maxf` and no test fails, unless a golden happens to exercise it.
**Fix:** Add a rule with its own offending sample (the test at line 172 then proves it matches):
```gdscript
[
	"std min, max or clamp (use gd::minf, gd::maxf, gd::clampf)",
	BEGIN + "(std::)?(max|min|clamp|fmax|fmin)\\s*[(<]",
	"double m = std::max(a, b);",
],
```
`maxf(`, `maxi(` and `gd::clampf(` do not match because a letter follows the name. That closes the documented gap; also change `native_enemy_views.cpp:202` to `gd::mini` (or a plain conditional) so the new rule passes.

### WR-10: `native_build.sh` verifies the godot-cpp commit but not that the checkout is unmodified

**File:** `tools/native_build.sh:73-86` (CI: `.github/workflows/ci.yml:71-75`, `:121-125`)
**Status (round 2):** open; the script gained one header line in 04-24, so the cited lines moved by +1.
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

### IN-01: Hot-path allocations in the enemy phase, with the concrete fixes

**File:** `native/src/enemy_step.cpp:110-136`, `native/src/native_enemies.cpp:219-226`, `simulation/night/enemy_system.gd:108-112` (was `enemy_system.gd`, `stuck_tracker.gd:94`, `separation.gd`, `wall_system.gd`)
**Status (2026-10-20):** largely moot. Moot: the `_order.erase` per dead enemy (now one `std::vector::erase` of a small struct, `NativeEnemies::remove`), the per-enemy `target_of` Dictionary in the stuck tracker (it reads `view.targeted`), the per-enemy `partners` Array and `sort()` (a reused `std::vector` in `separation_displacements_bucketed`), and the `segments_near` PackedInt32Array allocations (`near_segments` fills a reused scratch). Remaining: `Stepper::separate()` builds a `std::vector<EnemyRec *>`, then fills three Godot packed arrays with a per-element `push_back` (one extension-interface call each) only to hand them to a C++ function that immediately reads them back; `EnemySystem.target_of` still builds a PackedInt64Array plus a Dictionary per call for the overlay and the path gizmo.
**Fix:** Give `duskhold::separation_displacements_bucketed` a raw-pointer core (`const Vector2 *`, `const double *`, `const int64_t *`, count) that `Stepper::separate()` calls on `std::vector` scratch members; keep the packed-array entry point as a thin wrapper for `NativeSim`.

### IN-02: `segments_near` cost grows with the square of the query reach in `first_blocking`

**File:** `native/src/native_walls.cpp:210-255` (and `:274-300` `blocking_segment`; was `wall_solids.gd:52-69`, `wall_system.gd:129-145`)
**Status (2026-10-20):** open, ported unchanged on purpose (`native_walls.h:30-32`). It is cheaper now (a `std::map` lookup per cell and no Dictionary), but the bounding box of a 120 m line is still about 240 cells per call plus a `std::sort` and `std::unique`.
**Fix:** Walk only the cells along the line (a DDA over the 4 m grid), or return early on `intact_ == 0` per run; measure with `tools/stress/step_bench.gd --map=stress`. Only a change that keeps the candidate set identical is digest-safe.

### IN-03: `UnitViews.MAX_VIEWS` (256) is smaller than the simulation can field

**File:** `presentation/units/unit_views.gd:20`
**Status (round 2):** open, unchanged, and out of scope by owner decision at UAT test 13. The constant moved from line 15 to line 20 and now also sizes `NativeUnitViews.configure` and the bar batch; the cap behaviour (surplus simulated, not drawn) is unchanged and `test_native_unit_views.gd` pins it at 300 units in a 256 cap.
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
**Status (round 2):** open. The new tools repeat the unchecked-write shape: `enemy_trace.gd:166-167` and `step_attribution.gd:298-301` (earlier), and now `tools/stress/view_ablation.gd:247-256`, which opens the output file at `:249` before testing `made != OK or file == null` at `:250` (a returned failure leaves an opened handle) and ignores the result of every `store_line` at `:255`.
**Issue:** Both files are opened before the null check; if the second open fails the first stays open and truncated. No tool checks that a store succeeded.
**Fix:** Open, write and close one file at a time and treat a failed open or store as `cannot_write_output`.

### IN-09: Native helpers copied across files: `wrap_add`/`wrap_mul` six times, `cell_key` four times, `walk_ticks` twice

**File:** `native/src/native_walls.cpp:30-39`, `native_structures.cpp:19-23`, `native_enemies.cpp:18-31`, `native_separation.cpp:28-37`, `native_field.cpp:38-48`, `native_wall_decision.cpp:14-18` and `:168` (`NativeWallDecision::walk_ticks` against the anonymous `walk_ticks` in `native_field.cpp:48`); constants `NativeWallDecision::MAX_TICKS`, `gd::SIM_MAX_TICKS`, `NativeField::INF_COST`, `NativeStuck::STEP_ORTHOGONAL`, `native_field.cpp` `STEP_ORTHOGONAL`
**Issue:** The same wrapping-arithmetic helpers and the same tick rule exist in several files; a fix to one (for example a bound on `walk_ticks`) misses the others, and `walk_ticks` is the kind of function the exact-port contract makes expensive to drift. `gd_math.h` is the one header the table says the port calls.
**Fix:** Move `wrap_add`, `wrap_mul`, `wrap_neg` and `cell_key` into `gd_math.h` (namespace `gd`), call `NativeWallDecision::walk_ticks` from `native_field.cpp`, and define the step and infinity constants once.

### IN-10: Public GDScript facade methods that only tests call, which also force the private-member access `pathing._route`

**File:** `simulation/nav/pathing.gd:100-134` (`is_sealed`, `castle_cost_at`, `castle_distance_cm`, `detour_ticks`, `straight_ticks`, `march_step`); `simulation/night/enemy_system.gd:200-201` (`living_within`); `simulation/walls/wall_system.gd:134-135` (`segments_near`); `simulation/nav/wall_decision.gd:249-283` (`ttd_ticks`, `walk_ticks`, `should_break`, `keep_breaking`); consumer `simulation/night/enemy_system.gd:310` (`pathing._route`)
**Issue:** I grepped `simulation/`, `presentation/`, `ui/`, `input/` and `tools/`: none of these has a production caller, since the native step calls `NativeRoute`, `NativeEnemies.nearest_living` and `NativeWallDecision` directly. They are kept as test oracles (`probe_rules` and the pins compare against `WallDecision`'s statics), but the `wall_decision.gd:208-211` comment says the statics stay "for the GDScript callers that spawn an enemy or draw the overlay", and only `damage_per_300` is called (`enemy_system.gd:77`); the overlay calls none. Six dead `Pathing` methods hold the class at its 20-method cap, and that cap is the stated reason `EnemySystem._hand_over_world` reads the private `pathing._route` (`enemy_system.gd:300-302`). This is the "leftover duplicate body" the exact-port contract forbids, in a mild form.
**Fix:** Delete the six `Pathing` delegates and add `func route() -> NativeRoute`; tests call `pathing.route().detour_ticks(...)`. Move the four `WallDecision` static rules into the test support that uses them (or into `tests/support/`) and fix the comment; drop `EnemySystem.living_within` and `WallSystem.segments_near` or mark them test-only.

### IN-11: Test-only probe code ships in the production library

**File:** `native/src/native_sim.cpp` (`probe_vector`, `probe_double`, `probe_int`, `probe_rules`, and since round 2 `probe_vector3` at `:384` and `probe_double3` at `:433`, with all `OP_*` constants including the `*_CPP` variants that call godot-cpp's own methods and the new `OP_V3_*`/`OP_DBL3_*`); registered in `native/src/register_types.cpp`
**Status (round 2):** open and larger: 04-25 added about 100 lines of probe code and ten more bound constants to the same library, with the same justification (the Vector3 contract test needs them).
**Issue:** About 400 lines of contract-test scaffolding are bound into the DLL that goes to itch.io, widening the public surface of a library loaded into the game process for no runtime use.
**Fix:** Guard them with a `DUSKHOLD_NATIVE_PROBES` compile definition that `tools/native_build.sh` sets for local and test builds (and CI's test job library), and build the exported DLL without it; the contract tests already fail loudly when a probe is missing.

### IN-12: No sanitizer or static-analysis pass over the new C++

**File:** `.github/workflows/ci.yml:51-84`, `native/CMakeLists.txt:56-63`
**Status (round 2):** open; round 2 added about 2,000 lines of C++ with raw `ptrw()` pointers and pointer arithmetic over packed arrays (`native_mirror.h` writers, the four fills), which is exactly the class a sanitizer pass covers (see also IN-22).
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

**File:** `native/src/gd_math.h:127-141` (`floori` at `:129`, `ceili` at `:134`, `roundi` at `:140`; moved from `:108-122` by the Vector3 table); callers `native_walls.cpp:210-230` (`near_segments`), `native_enemies.cpp:233-251` and `:254-260`, `native_field.cpp:133-143` (`cell_of`); `native/src/native_structures.cpp:93` and `:189`; `native/src/native_field.cpp:99` (`set_masks`) and `:77-93` (`set_layout`)
**Status (round 2):** open. The new view classes narrow 64-bit ids to `int32_t` in `drawn_ids_` (`native_enemy_views.cpp:239`, `native_unit_views.cpp:235`) and arrow `target_ids_` (`native_arrows.cpp:127`), as the GDScript `PackedInt32Array`s they replace did, so `has_view` and the arrow target lookup for an id past 2^31 would answer for a different number; unreachable with ids that start at 1 and only grow, but it is the second bullet's pattern again. The new code adds no float-to-integer cast from engine data.
**Issue:** Three small things of the same family, none reachable by healthy data:
- `static_cast<int64_t>(std::floor(x))` is undefined behaviour in C++ for NaN, infinity and values beyond 2^63; the header comment says "the hardware converts it" like the engine, which holds on x86-64 only. `NativeStructures::scan` guards `gd::is_finite(pos)`, but the wall mirror, the enemy grid and `NativeGrid::cell_of` do not, so a NaN position gives platform-dependent cells instead of a defined answer.
- `rebuild` narrows 64-bit unit ids with `static_cast<int32_t>(id)` (`native_structures.cpp:93`) and `scan` returns the narrowed `ids_[index]` (`:189`), while `find_unit` compares the full 64-bit `unit_ids_`; an id past 2^31 would be found by `has_unit` but returned as a different number.
- `NativeGrid::set_masks` computes `width_ * height_` (`native_field.cpp:99`) from GDScript integers without an overflow check, and `set_layout` accepts a NaN, zero or negative `cell` (division by zero in `cell_of`) although its comment promises that a layout that cannot size a grid stays unarmed.
**Fix:** Make `gd::floori`/`ceili`/`roundi` saturating (`if (!(x > -9.2e18 && x < 9.2e18)) return x != x ? INT64_MIN : (x < 0 ? INT64_MIN : INT64_MAX);`, which equals the x86 result for NaN and the engine's for in-range values) and add the cases to `test_native_math_contract.gd`; keep ids 64-bit end to end; in `set_layout` require `cell > 0.0 && std::isfinite(cell)` and `width <= INT32_MAX / height`.

### IN-16: `test_living_within_lists_every_living_enemy_in_reach_ascending` asserts the opposite of the documented contract and passes by call order

**File:** `tests/unit/test_enemy_store_native.gd:185-195` (contract at `simulation/night/enemy_system.gd:196-199`, `native/src/native_enemies.cpp:199-207`)
**Issue:** `EnemySystem.living_within` documents that dead enemies not yet removed "may be listed", and `NativeEnemies::damage` leaves `grid_dirty_` unchanged, so an enemy killed after a grid build stays in it until the next dirtying. The test kills `ids[4]` after spawning and before the first query, so the lazy rebuild happens to exclude it, then asserts `assert_false(ids[4] in found, "a dead enemy is not indexed")`. One earlier query in the test would make it fail. Production is safe (`nearest_living` rechecks `health`), but the test pins a behaviour that the facade says it does not guarantee.
**Fix:** Either mark the grid dirty when `damage` brings health to 0 (`native_enemies.cpp:199-207`, one line) and say so in the facade comment, or change the assertion to `assert_true(not _enemies.is_alive(ids[4]))` and filter by `is_alive` in the expectation loop.

---

_Reviewed: 2026-10-20T16:16:53Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
