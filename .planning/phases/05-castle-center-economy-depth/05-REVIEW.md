---
phase: 05-castle-center-economy-depth
reviewed: 2026-10-25T23:41:54Z
depth: standard
files_reviewed: 93
files_reviewed_list:
  - .claude/CLAUDE.md
  - data/abilities/golden_age.tres
  - data/abilities/headsmans_edge.tres
  - data/abilities/prosperity.tres
  - data/abilities/royal_training.tres
  - data/buildings/archery_range.tres
  - data/buildings/barracks.tres
  - data/buildings/castle_center.tres
  - data/buildings/field.tres
  - data/buildings/fishing_harbor.tres
  - data/buildings/gold_mine.tres
  - data/buildings/house.tres
  - data/buildings/mill.tres
  - data/buildings/shrine.tres
  - data/buildings/tower.tres
  - data/buildings/wall.tres
  - data/enemies/grunt.tres
  - data/enemies/ranged.tres
  - data/king/king.tres
  - data/king/sword.tres
  - data/maps/prototype_map.tres
  - data/units/archer.tres
  - data/units/footman.tres
  - project.godot
  - tests/e2e/test_harbor_scene.gd
  - tests/e2e/test_king_knockout.gd
  - tests/e2e/test_king_ride.gd
  - tests/e2e/test_king_widget.gd
  - tests/e2e/test_order_markers.gd
  - tests/e2e/test_squad_strip.gd
  - tests/fixtures/fixture_map_castle.tres
  - tests/fixtures/fixture_map_gate.tres
  - tests/fixtures/fixture_map_one_night.tres
  - tests/fixtures/fixture_map_shrine.tres
  - tests/fixtures/fixture_map_squads.tres
  - tests/fixtures/fixture_map_walls.tres
  - tests/fixtures/fixture_map_walls_gap.tres
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_wall_dawn.gd
  - tests/integration/test_wall_detour.gd
  - tests/unit/test_ability_data.gd
  - tests/unit/test_build_requirements.gd
  - tests/unit/test_card_resolution.gd
  - tests/unit/test_card_resolution.gd.uid
  - tests/unit/test_castle_attack.gd
  - tests/unit/test_castle_data_contract.gd
  - tests/unit/test_castle_label.gd
  - tests/unit/test_dawn_rebuild.gd
  - tests/unit/test_debug_overlay_crowd_sections.gd
  - tests/unit/test_debug_overlay_squad_section.gd
  - tests/unit/test_economy_data_contract.gd
  - tests/unit/test_economy_overlay_sections.gd
  - tests/unit/test_enemy_targeting.gd
  - tests/unit/test_field_route_pins.gd
  - tests/unit/test_glyph_resolver.gd
  - tests/unit/test_harbor_exposure.gd
  - tests/unit/test_harbor_exposure.gd.uid
  - tests/unit/test_input_capabilities.gd
  - tests/unit/test_input_map.gd
  - tests/unit/test_map_validate_castle.gd
  - tests/unit/test_melee_breaks_to_target.gd
  - tests/unit/test_military_data_contract.gd
  - tests/unit/test_nav_grid.gd
  - tests/unit/test_pond_layout.gd
  - tests/unit/test_prototype_map_economy.gd
  - tests/unit/test_run_stats.gd
  - tests/unit/test_shot_list.gd
  - tests/unit/test_spot_label_model.gd
  - tests/unit/test_squad_archers.gd
  - tests/unit/test_squad_respawn.gd
  - tests/unit/test_stress_map_data.gd
  - tests/unit/test_structure_decision_pins.gd
  - tests/unit/test_unit_fill_pins.gd
  - tests/unit/test_wall_data_contract.gd
  - tests/unit/test_wall_decision.gd
  - tests/unit/test_wall_geometry_pins.gd
  - tests/unit/test_wall_solids.gd
  - tests/unit/test_weapon_def.gd
  - tools/screenshot/shot_army_scenarios.gd
  - tools/screenshot/shot_crowd_scenarios.gd
  - tools/screenshot/shot_economy_scenarios.gd
  - tools/stress/data/stress_barracks.tres
  - tools/stress/data/stress_footman.tres
  - tools/stress/data/stress_grunt.tres
  - tools/stress/data/stress_tower.tres
  - tools/stress/data/stress_wall.tres
  - tools/stress/step_attribution.gd
  - tools/stress/step_bench.gd
  - tools/stress/stress_map.tres
  - tools/stress/stress_night.gd
  - ui/hud/king_widget.gd
  - ui/overlay/economy_overlay_sections.gd
  - ui/world/spot_label_model.gd
findings:
  critical: 0
  warning: 3
  info: 9
  total: 12
status: issues_found
---

# Phase 5: Code Review Report (gap-closure round 1)

**Reviewed:** 2026-10-26
**Depth:** standard
**Files Reviewed:** 93
**Status:** issues_found

## Summary

This round rescaled every health and damage number x100 in shipped data, fixtures, the stress map and three stress tools, re-pinned the tests, recut three cards, moved the Harbor and its pond, widened the king widget label, and stripped the pad bindings from the king's move and sprint actions (quick task 261023-aos). I read the diff of each file against 06aa63d and checked the 13 surviving candidates against the source.

The data rescale itself holds up. The diff of `data/` shows a consistent x100 on health and damage, gold untouched, and the one place that sits near an integer limit (wall segment health in a PackedInt32Array) peaks at 9000 in shipped data and 10000000 in the stress wall, both far below int32. I found no critical defects. The quick task's `project.godot` change removes exactly the five intended pad events (four move axes, one sprint button). The defects are all of one family: a number rescaled in one place and left behind in another.

- WR-06 to WR-08: one test that silently stopped testing, one bench constant that has no effect, and one shot-tool gap that lets a pad cancel the zoom.
- IN-10 to IN-18: stale names, comments and docs after the rescale and the pad removal.

All 13 candidates were confirmed against the source. Three were merged: the two step_bench candidates (one finding, WR-06), and the stale doc comments in `simulation/night/castle_attack.gd`, `building_def.gd` and `choice_def.gd` (IN-18). The CLAUDE.md candidate is reported at the line the file has on disk, 91. None was dropped. The six refuted candidates were not independently re-confirmed and are not reported.

Carried count: 14 findings from the previous review (listed below). The frontmatter counts new findings only.

## Carried from the previous review (still open, outside this round's changes)

None of the fourteen was fixed, and this round touched none of their code.

- WR-01: A refused `add_source` is ignored after the gold is spent and the pick is recorded
- WR-02: Castle tiers II to IV are not validated, so a bad row silently disarms the keep; the CastleAttack header still claims otherwise
- WR-03: `StatModifierDef.problems()` accepts a bucket that is not one of the three
- WR-04: The "no income" coin is drawn over a rebuilt Shrine that has not woken and pays nothing anyway
- WR-05: IncomeState's per-death handler allocates and rescans every plot for each enemy death
- IN-01: `CastleAttack._map` is a dead field after 05-02
- IN-02: A digit key above the card count clears the highlight instead of being ignored
- IN-03: `StatStack` allocates an empty Dictionary on every read, and `CastleAttack` reads the stack several times per tick
- IN-04: The card picker and the requirement check do avoidable work every frame near a plot
- IN-05: `dawn_income` set on a BOATS tier is silently never paid and not reported
- IN-06: The castle-raising helper exists twice, fails silently, and the shot version writes the economy directly
- IN-07: `PondView.bind_run` dereferences spot entries without a null check
- IN-08: A wall-clock loop in an e2e test makes the shake assertion machine-dependent
- IN-09: The transcendental guard does not scan the Phase 5 simulation folders that make decisions

Note on WR-02 and IN-18: IN-18 is separate from carried WR-02. The CastleAttack header is also stale after the rescale (its shipped numbers), which WR-02's fix should cover in the same edit.

## Warnings

### WR-06: step_bench's `CASTLE_HEALTH` never reaches the castle on the prototype shape: the castle plot is built to tier II, whose 10000 replaces it

**File:** `tools/stress/step_bench.gd:61` (also 179-185)
**Issue:** `_build` writes `map.castle_max_health = CASTLE_HEALTH` (line 179) and then calls `apply_next_tier` on every spot (lines 184-185). `spot_ids()` includes the shipped `castle_plot` (`data/maps/prototype_map.tres:147-150`, `is_castle = true`), which `BuildingSystem` stands at tier I, so the call raises it to tier II. `CastleState._on_building_built` (`simulation/castle/castle_state.gd:177-182`) then sets `_max_health = _stat_max_health()`, and `_base_max_health()` (lines 162-167) reads the tier II row's `max_health = 10000` (`data/buildings/castle_center.tres:29`), not the map value. The bench castle therefore has 10000 health, 50 grunt blows of 200. The comment above the constant ("The castle must outlive the timed steps whatever the machine does") is false.

This round raised the constant from 10000000 to 1000000000 without noticing that it does nothing; the cause predates the round. `--warmup` is allowed up to 900 and `--steps` up to 600, so 1500 ticks (50 s) can be requested. Grunts arrive in about 19 s, and the castle falls soon after. `RunContext.step()` then returns at once (`simulation/run/run_context.gd:74-75`) and the remaining timed samples read about 0 ms, so `mean_ms` and `p95_ms` come out too low. Tier II also arms the castle's arrows (300 damage), so the bench load differs from the "every plot built at tier 1" shape its header describes. The default run (30 steps, no warm-up) does not get that far, and `--map=stress` is unaffected because that map has no castle plot.
**Fix:** In `_build`, skip the castle plot so it stays at tier I and keeps the map's value:
```gdscript
for spot_id: StringName in ctx.buildings.spot_ids():
	if ctx.buildings.get_spot(spot_id).is_castle:
		continue
	ctx.buildings.apply_next_tier(spot_id)
```
Alternatively, set the castle's health after the build loop. Correct the header's "every plot built at tier 1" either way.

### WR-07: The "building fell" integration test no longer fells the Barracks after the x100 rescale (file missed by the re-pin)

**File:** `tests/integration/test_squad_lifecycle.gd:12, 174-179`
**Issue:** `test_an_emptied_squad_whose_building_fell_is_rebuilt_and_restored_at_dawn` fells the Barracks with `KILL_DAMAGE`, still 1000 (line 12). The fixture loads the shipped `data/buildings/barracks.tres` (via `fixture_map_squads.tres`), whose tier I `max_health` is now 4000 (it was 40 at 06aa63d), so the blow takes it to 3000 and it is not destroyed. Nothing between line 174 and line 179 asserts that the building fell. As a result:

- `assert_false(is_destroyed(BARRACKS), "dawn rebuilt the barracks")` passes because the Barracks was never destroyed.
- `_stood_at_restore` is true because it never fell.
- "the squad is full again" can come from the night replacement trickle of a standing Barracks, not from the dawn rebuild and restore.

The rebuild-then-restore path the test is named for is no longer exercised, and the suite stays green. The unit kills at lines 72 and 84 still work, because the footman has 1000 health. The file is not in the round's scope list, which is the reason it was missed. In-scope siblings were re-pinned for the same call (`test_squad_respawn.gd` went to 100000).
**Fix:** Fell the Barracks with its own health and assert it:
```gdscript
_ctx.buildings.damage_building(BARRACKS, _ctx.buildings.max_health_of(BARRACKS))
assert_true(_ctx.buildings.is_destroyed(BARRACKS), "the barracks fell")
```
Keep `KILL_DAMAGE` for the unit blows only.

### WR-08: `castle_tier_four` and `crowd_stress_night` press `zoom_out` without `_drop_pad_zoom_events`, so a connected pad still cancels their zoom

**File:** `tools/screenshot/shot_economy_scenarios.gd:157` and `tools/screenshot/shot_crowd_scenarios.gd:220`
**Issue:** Plan 05-23 found that with a pad connected, stick noise overrides a scripted `Input.action_press(&"zoom_out")`, and recorded the rule that a real-window shot that presses a zoom action must drop that action's pad bindings in memory first. The new `_drop_pad_zoom_events()` helper (shot_economy_scenarios.gd:190) is called only from `harbor_pond` (line 214) and `economy_day` (line 314). `_castle_tier_four` (lines 157-159, meant to fit the tall keep in frame) and `_crowd_stress_night` (shot_crowd_scenarios.gd:220-222) use the same press, wait, release sequence without it. Both zoom actions are bound to joypad axis 3 (`project.godot` zoom_in and zoom_out). Neither shot checks the camera zoom in its ready check, so with a pad connected both pass and save a picture at about the default zoom. The UI audit reads those pictures as evidence. Each shot runs in its own Godot process, so applying the helper everywhere is safe. The same mechanism could, less likely, affect `_queue_ten` in `shot_army_scenarios.gd` (it holds `command_queue`, bound to a trigger axis).
**Fix:** Move the helper to `ShotScenarios` (or call it once in `ShotRunner` before any scenario) and call it before every scripted zoom press. Optionally assert the rig's zoom has moved before the capture.

## Info

### IN-10: New header note calls 300 "the king's base"; the shipped king's base is 500

**File:** `tests/unit/test_ability_data.gd:13-14` (constants at 84-85)
**Issue:** The round's header line says "the king's 300 base and 800 with both cards", and the test is named `..._makes_king_damage_800_in_either_order`. The king's damage base is the weapon's `attack_damage` (`simulation/king/king_state.gd:280`), and `data/king/sword.tres:10` is `attack_damage = 500`. With both cards the shipped king deals (500 + 100) x 2 = 1200. `KING_BASE_DAMAGE` was always an arbitrary probe base, so the stack-order arithmetic is right, but the note says something false about the shipped king. The same header's Headsman's Edge paragraph uses the real 500, so the file contradicts itself.
**Fix:** Rename the constant to a probe base (for example `STACK_PROBE_BASE`) and reword the header and test name, or load `sword.tres` and pin 1200.

### IN-11: Test name says "a million health" but its thousand-attacker case now uses a hundred million

**File:** `tests/unit/test_wall_decision.gd:175-177`
**Issue:** The re-pin raised the thousand-attacker health from 1,000,000 to 100,000,000 so that 1000 x `GRUNT_PER_300` (2,000,000) still gives 15000 ticks. The name was not updated. A million health against that sum would give 150, which no line asserts, so the name matches neither the case it names nor the whole body.
**Fix:** Rename it (for example `test_a_hundred_million_health_against_a_thousand_attackers_stays_exact`).

### IN-12: Wall "break" before the grid rebuild no longer breaks the 3000-health segment (file missed by the re-pin)

**File:** `tests/unit/test_goal_field_cache.gd:83`
**Issue:** `_walls.damage_segment(1, 1000)` used to break the old 30-health segment. The shipped wall now has 3000 health (`data/buildings/wall.tres:9`), so the segment is left at 2000 and the rebuild re-rasterises the same wall. The assertions still pass because `NavGrid.rebuild` bumps `_version` unconditionally (`simulation/nav/nav_grid.gd:183`), so the test no longer checks invalidation after a real wall change. This is the same stale-blow pattern the round fixed in `test_nav_grid.gd` (1000 to 100000). The file is not in the scope list.
**Fix:** Use 100000 (or `_walls.max_health_of(1)`) so the segment really breaks before the rebuild.

### IN-13: `KILL_DAMAGE` 9900 kills nobody in the hurt run, so its "killed outright" path has never been pinned

**File:** `tests/unit/test_unit_fill_pins.gd:6-7, 30-31, 35`
**Issue:** The doc says the frame-1000 hit kills a unit. The squads are stress footmen with `max_health = 10000000` (`tools/stress/data/stress_footman.tres:9`), so a 9900 hit plus a few 100-point hits leaves the unit near 9,989,000 and nobody dies. This predates the round (99 against 100000 at the pin's creation also killed nobody). The x100 kept the ratio exactly, which is correct for the frozen digest. The constant name and comments still claim coverage the pin does not have.
**Fix:** Change only names and comments, not the value (a real kill would move the frozen digest). Rename `KILL_DAMAGE` to something like `BIG_HIT_DAMAGE` and say bars drop out on restore, not on a death.

### IN-14: The old 376 px right edge survives in `hud.tscn` and in the contrast probe's documented label rect

**File:** `ui/hud/hud.tscn:253`, `tools/screenshot/contrast_probe.gd:22-26`, `tools/contrast_probe.sh:8,35`
**Issue:** `KingWidget` still has `offset_right = 376.0` (a 360 px rect), which matched the old minimum exactly. The new minimum is 392 (`LABEL_MIN_WIDTH` 128), and the row reaches x 408 only because an undersized Control grows along its default `grow_horizontal`. There is no runtime effect today (`test_king_widget` measures global rects against 408), but the scene no longer states the layout `king_widget.gd`'s header documents. The contrast probe still says the label rect is `280,648,96,56` and "LABEL_MIN_WIDTH is 96 (to x 376)"; the label now spans 280..408. The probe still works for the knocked-out "0 / 5000", so only the documented numbers are stale.
**Fix:** Set `offset_right = 408.0` in `hud.tscn`. Update the probe comment to 128 (to x 408), and either keep the 96 px default with a note or widen it to `280,648,128,56`.

### IN-15: CLAUDE.md still says the WASD and sprint actions each have keyboard and gamepad bindings

**File:** `.claude/CLAUDE.md:91`
**Issue:** Quick task 261023-aos updated the Platform constraint (line 16) but not the Development Tools row, which still lists "WASD, sprint, ... each with keyboard and gamepad bindings". Since 2026-10-23 that is false for WASD and sprint, and the file is the one agents read, so it tells a future agent to re-add the stick and RB bindings that caused the UAT drift. `test_input_map`'s `pad_events == 0` assertion would catch a re-add, but the instructions contradict each other.
**Fix:** Reword to "each with a keyboard binding and, except the move and sprint actions (keyboard only since 2026-10-23), a gamepad binding", or drop the gamepad clause.

### IN-16: `COMMAND_BUTTONS` comment still says B lets a pad player deselect and ride again

**File:** `tests/unit/test_input_map.gd:105`
**Issue:** The comment says B cancels a selection, "which also lets a pad player deselect and ride again". Since 2026-10-23 the four move actions have no stick events, so no pad player can ride. The commit that removed them rewrote the header (lines 2-6) and left this block.
**Fix:** Drop the "ride again" clause, or say the king has no pad movement and B only cancels the selection.

### IN-17: The class doc still says the Shrine reads "Asleep: 30 of 100 enemy health" while the same file's `_shrine_effect` doc says 3000 of 10000

**File:** `ui/world/spot_label_model.gd:19`
**Issue:** The round rewrote three doc examples in this file (lines 98, 106, 117) and missed the `describe()` doc at line 19. With the shipped `wake_threshold_hp = 10000` the label can never read "of 100". The file now contradicts itself about one string.
**Fix:** Change line 19 to "Asleep: 3000 of 10000 enemy health".

### IN-18: Doc comments in unchanged simulation files still give the pre-rescale numbers as "the shipped" ones

**File:** `simulation/night/castle_attack.gd:7-9`, `simulation/defs/building_def.gd:70`, `simulation/defs/choice_def.gd:24`
**Issue:** After the rescale, three comments contradict the data:

- The CastleAttack header says the shipped castle deals 2 every 1.5 s and that three hits kill a 6 hp grunt and two a 4 hp skirmisher. The shipped values are `castle_attack_damage = 200`, grunt 600, skirmisher 400.
- `BuildingDef.tier_effect_line` quotes "Wakes after 100 enemy health falls within 18 m". The game now prints 10000.
- `ChoiceDef.effect_line` quotes Royal Training as "+25% king health, +1 king damage", while `test_castle_label.gd:132` pins "+100 king damage".

This is separate from carried WR-02, which is about tier validation in the same CastleAttack header.
**Fix:** Update the examples to the x100 values (damage 200, grunt 600 hp, skirmisher 400 hp; "Wakes after 10000 ..."; "+100 king damage"), or reword them so they do not claim to be the shipped numbers.

---

_Reviewed: 2026-10-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
