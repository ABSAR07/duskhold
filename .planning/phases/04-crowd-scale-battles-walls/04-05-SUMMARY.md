---
phase: 04-crowd-scale-battles-walls
plan: 05
subsystem: walls
tags: [godot, gdscript, walls, prototype-map, validation, castle-kit, multimesh, screenshots, tdd, tracer]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: WallRunDef, BuildSpotDef.wall_run, data/buildings/wall.tres, WallSystem, WallSolids and the placeholder WallViews (04-04); CrowdBatch (04-01); MeshBaker (04-02); HealthBarBatch (04-01)
  - phase: 03-king-combat-troops
    provides: the ten prototype plots, the shot runner and ShotArmyScenarios shape, the ride band test
provides:
  - four wall plots on the prototype map (wall_west, wall_east, wall_north, wall_ring) after archery_1, three road runs placed by the 5.0 m clearance rule and a 16-sided ring, 52 segments in all
  - WallValidation (MIN_GAP_METRES 3.0, MAX_SEGMENTS_PER_MAP 1000) appended to MapConfig.validate()
  - the hold label for a wall plot ("Wall I", "12 segments, 30 health each") and a timber-tan wall plot marker
  - WallViews tier looks (palisade, Castle Kit stone wall, wall with tower-base pillars), a 0.4 s collapse, rubble in RubbleView's slab pattern, hurt-only bars, the dawn rise, and the hooks tier_look_of, bar_count and pillar_count
  - ShotCrowdScenarios and the shots walls_day and walls_night_breach (35 shots in all)
affects: [04-06 flow field on the shipped runs, 04-07 break-or-detour rule, 04-10 bot walls and the walls golden, 04-11 phase gate]

actuals:
  tokens: 16800
  tasks: 2
  commits: 3

plan_head_before: 70e49e74b2ce64d569fe155eadf158206e13fd45
plan_head_after: ff29cf27aae9fa3152bab3ea5ad5ab61485b4217

tech-stack:
  added: []
  patterns:
    - "A static validation class beside MapConfig (WallValidation.errors) keeps map_config.gd small: one readable string per problem, non-finite numbers reported once and their range checks skipped"
    - "A look per tier is one CrowdBatch per piece mesh with the mesh's own materials (material_override null), tiled along every segment from a basis built from the direction vector"
    - "Presentation-time animation in a batch view: per-segment sink and rise timers advanced in _process, a redraw only on a version change, a hit or while a timer runs"
    - "Tracer first (plots, validation, label, data tests), then RED (tests plus hook stubs) and GREEN for the looks"

key-files:
  created:
    - simulation/walls/wall_validation.gd
    - tests/unit/test_prototype_map_walls.gd
    - tests/unit/test_map_wall_validation.gd
    - tests/unit/test_wall_data_contract.gd
    - tests/e2e/test_wall_views.gd
    - tools/screenshot/shot_crowd_scenarios.gd
  modified:
    - data/maps/prototype_map.tres
    - simulation/defs/map_config.gd
    - ui/world/spot_label_model.gd
    - presentation/walls/wall_views.gd
    - presentation/buildings/building_views.gd
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot.sh
    - tests/unit/test_military_data_contract.gd
    - tests/unit/test_prototype_map_data.gd
    - tests/unit/test_spot_label_model.gd
    - tests/unit/test_shot_list.gd
    - tests/e2e/test_upgrade_at_spot.gd
    - tests/e2e/test_wall_tracer_scene.gd

key-decisions:
  - "The plan's run literals were kept: the re-derivation script agreed with every plot, endpoint, ring vertex and gap offset to within 0.01 m (limit 0.02 m)"
  - "WallValidation counts a run's segments itself instead of calling WallRunDef.expand(), which returns nothing past 200 pieces and so cannot say how many there were; a run with unusable data adds 0 to the map total, so one bad run reports once"
  - "A wall effect line lives in SpotLabelModel.describe (the run's segment count with the tier's health) and, at max tier, still names the health; BuildingTierDef.effect_line() keeps its fallback untouched"
  - "piece_count() keeps meaning standing segments (a sinking one still counts) and rubble_count() broken segments whose collapse has played, so the 04-04 hooks keep their meaning; pillar_count() and bar_count() are new mirror hooks"
  - "Tier II and III draw the Castle Kit wall with the model's own materials (batch material override null), because the shared crowd shader would drop the colormap texture; the palisade is built from primitives with a brown StandardMaterial3D"
  - "A rising piece (purchase or dawn restore) grows from RISE_START_SCALE over BuildingViews.RISE_SECONDS, the same beat as a rebuilt building"

patterns-established:
  - "Plot kind is data: a wall plot is told by wall_run, in the marker colour test as in the data tests"
  - "A scene test that watches a collapse waits with E2eSupport.wait_until instead of a fixed frame count, because a collapse plays in presentation time"

requirements-completed: [BLDG-10]

coverage:
  - id: D1
    description: "The prototype map has four wall plots appended after archery_1 in order (west, east, north, ring); the outer runs make 12 segments each with one 4 m gap on the road line, the ring 16 with three 4 m gaps toward the roads; the ten earlier plots keep their ids and positions; the ride band holds"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_walls.gd#test_the_wall_plots_are_appended_after_archery_1_in_order"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_walls.gd#test_the_ten_earlier_plots_keep_their_ids_and_positions"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_walls.gd#test_each_road_run_gap_is_centred_on_its_road_line_at_its_distance"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_walls.gd#test_the_farthest_plot_pair_still_rides_inside_the_twelve_to_eighteen_second_band"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each road run keeps at least 5.0 m from its road's tower and spawn point on opposite sides of its line, more than the spawn scatter plus half thickness plus the largest enemy radius; the north run lies on z = -60.5; each ring gap faces its road within 5 degrees"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_prototype_map_walls.gd#test_each_road_run_keeps_the_clearance_from_its_tower_and_its_spawn"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_walls.gd#test_the_ring_has_a_gap_toward_each_road_within_five_degrees"
        status: pass
    human_judgment: false
  - id: D3
    description: "MapConfig.validate() reports bad wall data once per problem (non-finite or short polylines, segment length, thickness, gaps under 3 m, outside the path or overlapping, 200 per run, 1000 per map, wall plots on income, attack or squad buildings); the shipped map validates clean"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_map_wall_validation.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_prototype_map_walls.gd#test_the_shipped_map_validates_clean_with_the_wall_plots"
        status: pass
    human_judgment: false
  - id: D4
    description: "The wall data contract: three tiers, cost 2 / 4 / 6, health 30 / 60 / 90 in equal steps, no income, attack or squad"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_data_contract.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "The hold label at a wall plot reads the tier and the run (Wall I, 12 segments, 30 health each; Wall II, 60 health; max tier 90 health; the ring 16 segments)"
    requirement: BLDG-10
    verification:
      - kind: unit
        ref: "tests/unit/test_spot_label_model.gd#test_an_empty_wall_plot_names_the_tier_and_the_run"
        status: pass
      - kind: unit
        ref: "tests/unit/test_spot_label_model.gd#test_a_wall_at_max_tier_names_its_ninety_health"
        status: pass
    human_judgment: false
  - id: D6
    description: "Each tier has its own look, a broken segment sinks then is rubble that blocks nothing, a hurt segment shows a bar, and dawn raises the pieces back, asserted through the CPU mirror hooks in the real scene"
    requirement: BLDG-10
    verification:
      - kind: e2e
        ref: "tests/e2e/test_wall_views.gd#test_the_three_tiers_have_the_barricade_stone_and_reinforced_looks"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_wall_views.gd#test_a_broken_segment_sinks_then_becomes_rubble_that_blocks_nothing"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_wall_views.gd#test_a_hurt_segment_shows_a_bar_and_a_full_one_does_not"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_wall_views.gd#test_dawn_raises_the_broken_segment_and_clears_rubble_and_bars"
        status: pass
    human_judgment: false
  - id: D7
    description: "No replay moved: smoke, army and full_idle replay twice with unchanged digests with the four unbought wall plots on the shipped map"
    requirement: BLDG-10
    verification:
      - kind: integration
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=army --twice --expect-file=tests/golden/army.json"
        status: pass
      - kind: integration
        ref: "bash tools/replay.sh --scenario=full_idle --twice"
        status: pass
    human_judgment: false
  - id: D8
    description: "walls_day and walls_night_breach are captured non-blank in a real window, and the tier looks (palisade, Castle Kit stone wall, pillars), the collapse and the rubble read as walls to a person"
    requirement: BLDG-10
    verification:
      - kind: automated_ui
        ref: "bash tools/screenshot.sh walls_day walls_night_breach"
        status: pass
    human_judgment: true
    rationale: "Whether the placeholder-grade tier looks read well at game camera distance is the owner's call at the Phase 4 gate; the executor read both PNGs and three scratch captures of the stone, reinforced and ring looks, and the run in the real scene passes the automated checks"

duration: 44 min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 05: Wall Plots, Validation and Tier Looks Summary

**Four wall runs (three road runs placed by a 5.0 m clearance rule and a 16-sided ring, 52 segments) the king can ride to and buy on the shipped map, validated by WallValidation, labelled "12 segments, 30 health each", and drawn per tier as a palisade, a Castle Kit stone wall and the same wall with tower-base pillars, with a 0.4 s collapse into rubble, hurt-only bars and a dawn rise; no replay digest moved**

## Performance

- **Duration:** 44 min (the first timestamp was taken at 2026-10-16T06:18:34Z, after the plan and context were read)
- **Started:** 2026-10-16T06:18:34Z
- **Completed:** 2026-10-16T07:03Z
- **Tasks:** 2 (Task 1 the tracer, Task 2 as RED, GREEN)
- **Files modified:** 25 in the plan range (6 sources, 6 new tests and tools, 7 edited tests, data, shot list files and 5 new `.uid` files)

## Accomplishments

- Plots and data (D-06): `data/maps/prototype_map.tres` lists `wall.tres` in `buildings` and appends `wall_west`, `wall_east`, `wall_north` and `wall_ring` after `archery_1` with inline `WallRunDef`s (3.0 m segments, 0.4 m half thickness); 12 + 12 + 12 + 16 = 52 segments. The ten earlier plots are untouched; the farthest plot pair (west to east, 116.5 m) rides in 15.5 s inside the 12 to 18 s band.
- Validation (T-04-11): `WallValidation.errors(map)` is appended to `MapConfig.validate()` and reports non-finite or short polylines, a segment length outside 0.5 to 20 m, a half thickness outside 0 to 2 m, a gap under 3 m, a gap outside the path or overlapping another, more than 200 segments in a run, more than 1000 on the map, and a wall plot whose building pays income, attacks or fields a squad. The shipped map validates clean.
- Label: a wall plot reads its tier and its run, `Wall I` with `12 segments, 30 health each`, `Wall II` with 60, and at max tier still names 90; the ring reads 16 segments; the marker is a timber tan, the fourth kind in the colour test.
- Looks (D-03, D-05): `WallViews` builds a palisade (four posts and two rails per metre from `MeshBaker.append_primitive`), bakes the Castle Kit `wall.glb` and `tower-square-base.glb` once, tiles every segment with `ceili(length / 1.0)` pieces that fill it exactly, and draws pillars at both ends of every reinforced segment. A broken segment sinks 1.2 m over 0.4 s, then lies as rubble in RubbleView's slab pattern; a hurt standing segment shows a `HealthBarBatch` bar 1.6 m up; a purchase or the dawn restore raises pieces over `BuildingViews.RISE_SECONDS`.
- Screenshots: `walls_day` and `walls_night_breach` through the new `ShotCrowdScenarios`; 35 shots in both lists.
- Replays: smoke `2599c7c2...` (703 ticks), army `f7a967ed...` (1353 ticks) and full_idle `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` (6941 ticks) are byte-identical to before; the four unbought wall plots are invisible to everything.

## Task Commits

1. **Task 1: Tracer, four wall runs with validated data and a run label** - `53b7cc1` (feat)
2. **Task 2 RED: failing tests for the tier looks, collapse, bars and the two wall shots** - `8645e4b` (test)
3. **Task 2 GREEN: tier looks from the Castle Kit with collapse, rubble and hurt bars, and two screenshots** - `ff29cf2` (feat)

**Plan metadata:** committed after this file (docs: complete plan). No refactor commit was needed.

## Geometry re-derivation (scratch script, from the shipped data)

The script (Python, trigonometry allowed there only) read the shipped towers (-55,20), (55,20), (0,-55), spawns (-66,24), (66,24), (0,-66) with scatter 3.0 and the castle at the origin:

| Run | Tower dist | Spawn dist | Run at | Clear of tower | Clear of spawn | Script endpoints | Plan literals |
|---|---|---|---|---|---|---|---|
| west | 58.523 m | 70.228 m | 64.0 m | 5.477 m | 6.228 m | (-53.995, 38.788) to (-66.298, 4.955) | (-54.00, 38.79) to (-66.30, 4.96) |
| east | 58.523 m | 70.228 m | 64.0 m | 5.477 m | 6.228 m | (53.995, 38.788) to (66.298, 4.955) | (54.00, 38.79) to (66.30, 4.96) |
| north | 55.0 m | 66.0 m | 60.5 m | 5.5 m | 5.5 m | (-18, -60.5) to (18, -60.5) | same |

Plots 2 m inside each gap: (-58.267, 21.188), (58.267, 21.188), (0, -58.5); ring plot (0, -6.5). Ring: 16 vertices of radius 9 m at 90 + 22.5k degrees rounded to centimetres, path length 56.158 m, road crossings at 10.929 m (west), 28.079 m (north, the vertex (0, -9)) and 45.230 m (east), so the gaps are 8.929 to 12.929, 26.079 to 30.079 and 43.230 to 47.230. Every literal of the plan agrees to within 0.01 m (limit 0.02 m), so the plan's values were written unchanged. The 5.0 m rule and the 3.9 m scatter bound hold for all three runs, and the ring plot is 13.5 m from the king spawn (0, 7), well outside the 2.5 m interaction radius.

## Screenshot reviews

- `screenshots/walls_day.png` (1280x720, Forward+): the king stands in the west gap on the tan plot disc with the label "Wall II / 12 segments, 60 health each" and four coin dots above him; the tier I palisade is two brown runs on either side of the gap, throwing long shadows. It reads as a fence with an opening, thin from the steep camera. Not blank (checked by ShotRunner).
- `screenshots/walls_night_breach.png` (1280x720, Forward+): night 1 ("4 enemies left"), dark scene; the broken segment beside the gap lies as grey rubble slabs next to the standing palisade, so the opening is clearly wider than the authored gap; one grunt stands beside the king inside the gap and one waits outside, and the king's hurt bar shows 46 / 50.
- Scratch captures (not committed): the east run (stone wall, crenellated, bricks along the line), the north run (reinforced: a tower-base pillar at every 3 m) and the ring (a stone arc around the keep) all read as intended; no orientation correction was needed for the Castle Kit pieces.

## Files Created/Modified

- `data/maps/prototype_map.tres` - the four wall plots and their runs; `wall.tres` registered
- `simulation/walls/wall_validation.gd` - the wall data checks (1 public function)
- `simulation/defs/map_config.gd` - appends `WallValidation.errors(self)` (542 lines)
- `ui/world/spot_label_model.gd` - the wall effect line
- `presentation/walls/wall_views.gd` - looks, collapse, rubble, bars, rise (7 public methods, 406 lines)
- `presentation/buildings/building_views.gd` - `WALL_MARKER_COLOR` set to the plan's tan
- `tools/screenshot/shot_crowd_scenarios.gd`, `shot_scenarios.gd`, `tools/screenshot.sh` - the two shots (35 in all; shot_scenarios.gd 635 lines)
- `tests/unit/test_prototype_map_walls.gd` (16), `test_map_wall_validation.gd` (20), `test_wall_data_contract.gd` (7), `tests/e2e/test_wall_views.gd` (6)
- `tests/unit/test_military_data_contract.gd`, `test_prototype_map_data.gd`, `test_spot_label_model.gd` (15), `test_shot_list.gd` (11), `tests/e2e/test_upgrade_at_spot.gd`, `test_wall_tracer_scene.gd` - updated deliberately

## Decisions Made

See `key-decisions` above. Readings the plan leaves open, none a deviation:

- The plan's `WALL_MARKER_COLOR := Color(0.7, 0.55, 0.35)` replaced the stone grey 04-04 had already put in `building_views.gd` (the constant existed; no test pinned its value).
- test_wall_views breaks segments with `ctx.walls.damage_segment` and restores with `restore_all()` directly instead of running a night: the behaviour under test is the view, and a night would let other segments break and move the counts.
- The shot `walls_night_breach` takes the segment next to the road gap from the two middle segments of the west run (the gap is authored in the middle) and breaks the one nearer to the first grunt within 6 m of a standing segment, as the plan describes.

## TDD Gate Compliance

Task 2 (`tdd="true"`): RED `8645e4b`, GREEN `ff29cf2`; no refactor commit. RED evidence was built from the JUnit XML of `bash tools/test.sh -gselect=test_wall_views` (exit 1) and verified with `gsd-tools check tdd-red-evidence`: `RED_EVIDENCE_OK`, target test `test_the_three_tiers_have_the_barricade_stone_and_reinforced_looks` failing on its assertions (5 of 6 failed, the empty-scene test passes by design). The RED commit also carries three stubs so the new tests parse and fail on assertions instead of on a parse error: `WallViews.tier_look_of`, `bar_count` and `pillar_count` returning nothing, and a `ShotCrowdScenarios` that lists no shot; test_shot_list failed on its count and list assertions. GREEN made both suites pass first time (6 of 6 and 11 of 11).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The 04-04 tracer scene test expected rubble two frames after a break**
- **Found during:** Task 2 (GREEN)
- **Issue:** `tests/e2e/test_wall_tracer_scene.gd` asserted rubble and a missing piece two process frames after `wall_segment_broken`; the 0.4 s collapse that D-05 asks for makes the piece sink first, so the assertion failed (1 of 2 tests).
- **Fix:** The test waits with `E2eSupport.wait_until` (3 s bound) for `rubble_count() >= 1` before asserting; no assertion was weakened.
- **Files modified:** tests/e2e/test_wall_tracer_scene.gd
- **Verification:** both tests of the script pass; full suite exit 0.
- **Committed in:** ff29cf2

---

**Total deviations:** 1 auto-fixed (1 blocking). The plan names the data tests it updates and "any further suite that iterates every plot"; the full suite found none besides the three it names, test_upgrade_at_spot and this one.
**Impact on plan:** None on scope; the fix keeps the 04-04 test's intent under the new collapse timing.

## Issues Encountered

- A bash heredoc containing an apostrophe was refused by the tool shell again; the three larger test files were written with the Write tool.
- The first full-suite run started before the Task 2 RED files existed, so it ran the Task 1 state (172 scripts, 1596 tests); the Task 2 numbers come from a second full run.
- `tools/lint.sh` reformatted three new files on first run (gdformat); `--fix` was used and the files were committed formatted.

## Verification (final state, HEAD ff29cf2)

- `bash tools/test.sh`: 173 scripts, 1604 tests, 24679 asserts, exit 0 (baseline at dispatch 169 scripts, 1549 tests, 24218 asserts; +4 scripts, +55 tests). After Task 1 alone: 172 scripts, 1596 tests, 24603 asserts, exit 0. `test_prototype_map_walls`, `test_map_wall_validation`, `test_wall_data_contract`, `test_wall_views`, `test_spot_label_model`, `test_military_data_contract`, `test_prototype_map_data`, `test_upgrade_at_spot`, `test_shot_list` and `test_attribution_log` are in the JUnit XML.
- `bash tools/replay.sh`: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks), army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks) against their goldens, full_idle `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` (6941 ticks) twice; after Task 1 and again after Task 2; no golden touched.
- `bash tools/screenshot.sh walls_day walls_night_breach`: both saved, no script error in either log.
- `bash tools/lint.sh`: clean. Public functions: WallViews 7, WallValidation 1; no class near a cap.
- No new asset file: only `wall.glb` and `tower-square-base.glb` of the already logged Kenney Castle Kit are used, so ASSETS.md and attribution.json are unchanged and test_attribution_log passes.

## Known Stubs

None. The RED-commit stubs were replaced in GREEN. The tier looks are Castle Kit and primitive placeholders for the Phase 8 art pass, not unwired data.

## Threat Flags

None. No new network, auth or file surface; T-04-11 (bad wall data reported by WallValidation, covered case by case in test_map_wall_validation) and T-04-12 (only logged Castle Kit files and code-built primitives, test_attribution_log green) are mitigated as planned.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 04-06 and 04-07 can build the flow field and the break-or-detour rule on the shipped runs: all four plots exist, every gap is 4 m, and `WallValidation` already guards the 3 m minimum the field relies on (RESEARCH A3).
- Plan 04-10 owns the bots buying walls and the one golden regeneration; an unbought wall plot changes nothing, which is why full_idle did not move.
- BLDG-10 is declared by plans 04-04 and 04-05 (and possibly later ones); the shared-ID gate decides whether it reads Complete now.
- Open for the verifier (D8): one look at the tier looks and the collapse in a real window at game camera distance.

## Self-Check: PASSED

- Created files exist: wall_validation.gd, the four new test scripts, shot_crowd_scenarios.gd (each with its `.uid`), and both screenshots under `screenshots/`.
- Commits `53b7cc1`, `8645e4b` and `ff29cf2` are in `git log`; `git rev-list --count 70e49e7..HEAD` was 3 before this file.
- Acceptance criteria re-run: the four `SubResource("Resource_wall_*")` entries after `Resource_archery_1` and `ExtResource("18_wall")` in `buildings`; `class_name WallValidation`, `MIN_GAP_METRES: float = 3.0`, `MAX_SEGMENTS_PER_MAP: int = 1000`; `WallValidation.errors(self)` in map_config.gd; `segments, %d health each` in spot_label_model.gd; `SPOT_COUNT: int = 14`; `MIN_RUN_CLEARANCE` in test_prototype_map_walls.gd and wall_north on z = -60.5; `wall.glb`, `tower-square-base.glb`, `func tier_look_of(` and `HealthBarBatch` in wall_views.gd; `class_name ShotCrowdScenarios` with both shot names; both names in tools/screenshot.sh and shot_scenarios.gd; both PNGs exist.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
