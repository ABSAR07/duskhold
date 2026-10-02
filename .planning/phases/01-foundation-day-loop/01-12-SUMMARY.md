---
phase: 01-foundation-day-loop
plan: 12
subsystem: presentation-vfx
tags: [godot, gdscript, gut, xray, stencil, king, screenshot, gap-closure, tdd]

requires:
  - phase: 01-foundation-day-loop
    provides: "01-11 camera framing (default offset 0,20.8,14.3 plus zoom), which the king_behind_keep screenshot shows; 01-10 screenshot tooling (ShotScenarios, shot_runner); 01-07 king model (horse and rider GLB instances plus crown)"
provides:
  - "XRaySilhouette: reusable presentation node that gives every BaseMaterial3D surface under its parent an X-Ray stencil copy, so the model shows through whatever hides it as a flat unlit silhouette"
  - "King shows as a light-cyan silhouette wherever a building hides him, by day and night, in Forward+ and Compatibility; unchanged in the open"
  - "Seventh scripted screenshot king_behind_keep, which fails (exit 1) when the king has no silhouette set up"
affects: [phase-02-playtest, phase-03-unit-hotkeys, phase-06-units-and-enemies]

actuals:
  tokens: 14000
  tasks: 2
  commits: 3
plan_head_before: 32049e0191a1d0ec6a3227443cbf860758688e84
plan_head_after: 9d2c0244e34092a31b1e833cba1328c5d220780a

tech-stack:
  added: []
  patterns:
    - "Occlusion reveal through the engine's stencil X-Ray preset (stencil_mode = STENCIL_MODE_XRAY) on duplicated per-instance surface override materials; mesh-owned imported materials are never written"
    - "A model opts in by carrying an XRay child node (last child, so its subtree exists in _ready); other units can reuse it"
    - "RED commit carries a signature-only interface stub so typed tests fail on assertions, not on a parse error (same approach as 01-11)"

key-files:
  created:
    - presentation/vfx/xray_silhouette.gd
    - presentation/vfx/xray_silhouette.gd.uid
    - tests/e2e/test_king_xray.gd
    - tests/e2e/test_king_xray.gd.uid
  modified:
    - presentation/king/king_model.tscn
    - tools/screenshot/shot_scenarios.gd
    - tools/screenshot.sh

key-decisions:
  - "Keep every design default from the plan unchanged (stencil X-Ray preset, stencil_color light cyan 0.4/0.9/1.0, king only, new king_behind_keep shot); none needed adjusting"
  - "RED commit carries a stub xray_silhouette.gd so the typed test script loads and fails on assertions"

patterns-established:
  - "XRaySilhouette.apply_xray(root, color) is static and testable on a plain fixture (StandardMaterial3D surface covered, ShaderMaterial surface skipped, original untouched)"

requirements-completed: [KING-02, DEV-04]

coverage:
  - id: D1
    description: "Every surface of the king's model carries the stencil X-Ray pass in the silhouette colour, with the shipped colour pinned and the applied count equal to the surface count"
    requirement: "KING-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_xray.gd#test_every_king_surface_has_the_xray_pass_in_the_silhouette_colour"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_xray.gd#test_the_xray_node_counts_every_surface_it_covered"
        status: pass
    human_judgment: false
  - id: D2
    description: "The shared imported materials stay untouched, buildings (the keep and Houses) never gain X-Ray, and apply_xray on a fixture covers only BaseMaterial3D surfaces with a copy"
    requirement: "KING-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_xray.gd#test_imported_materials_shared_with_other_instances_are_not_mutated"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_xray.gd#test_buildings_never_get_the_xray_pass"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_xray.gd#test_apply_xray_covers_standard_materials_only_and_copies_them"
        status: pass
    human_judgment: false
  - id: D3
    description: "The hidden king reads as a clear light-cyan silhouette on the keep by day and by night in both renderers, with no tint in the open"
    requirement: "KING-02"
    verification:
      - kind: command
        ref: "scratch rendered probe (windowed 1280x720): hidden 1268 px, open 0 px in Forward+ and Compatibility; night hidden 1270 px"
        status: pass
    human_judgment: true
    rationale: "Pixel counts prove the silhouette exists and is not tinting the open king; whether the colour and shape feel right is the owner's call at the end-of-phase playtest (the plan's human-check)"
  - id: D4
    description: "bash tools/screenshot.sh captures seven scenes including king_behind_keep, locally in both renderers, and the scenario fails if the king has no silhouette set up"
    requirement: "DEV-04"
    verification:
      - kind: command
        ref: "bash tools/screenshot.sh (7 of 7 saved), DUSKHOLD_SCREENSHOT_COMPAT=1 bash tools/screenshot.sh king_behind_keep (saved)"
        status: pass
    human_judgment: false

duration: ~16min
completed: 2026-10-02
status: complete
---

# Phase 1 Plan 12: King X-Ray silhouette (G-01-3 part 1) Summary

**The king now renders as a flat, unlit light-cyan silhouette through any building that hides him (engine stencil X-Ray on per-instance material copies), by day and night in Forward+ and Compatibility, with no tint in the open and a seventh `king_behind_keep` screenshot that fails if the setup is missing.**

## Performance

- **Duration:** about 16 min
- **Started:** 2026-10-02T07:12Z (approx), **Completed:** 2026-10-02T07:29Z
- **Tasks:** 2 (task 1 TDD tracer: RED then GREEN; task 2 auto)
- **Files modified:** 7 (4 created, 3 modified)

## Accomplishments

- `XRaySilhouette` (`presentation/vfx/xray_silhouette.gd`): in `_ready` it walks every `MeshInstance3D` under its parent (`find_children("*", "MeshInstance3D", true, false)`, so meshes inside the instanced horse and rider GLBs count), takes each surface's active material, and if it is a `BaseMaterial3D` assigns a shallow `duplicate()` with `stencil_mode = STENCIL_MODE_XRAY` and `stencil_color` through `set_surface_override_material`. Other material types are skipped. The mesh-owned imported materials are never written (T-01-20).
- `king_model.tscn` gets an `XRay` node as the last child of `KingModel` with `stencil_color = Color(0.4, 0.9, 1, 1)`; Horse, Rider and Crown are unchanged.
- `tests/e2e/test_king_xray.gd`: five proofs on the real prototype map and a plain fixture (every king surface has X-Ray in the right colour, applied count equals the surface count and exceeds 3, source materials still `STENCIL_MODE_DISABLED`, no building mesh including `CastleCenter` gains X-Ray after three Houses are built, fixture covers only the StandardMaterial3D surface).
- `king_behind_keep` shot: places the king at `castle_position + (0, 0, -5)`, waits the 1.2 s camera settle, and returns false (exit 1) unless the king's `XRay` node reports `get_applied_count() > 0`. `tools/screenshot.sh` lists it and says "all seven". CI needs no change (its screenshots job runs every shot and uploads `screenshots/*.png`).

### Rendered pixel counts (scratch probe, windowed 1280x720, pixels within 0.1 per channel of the stencil colour 102/230/255)

| Case | Renderer | Count | Threshold | Result |
|------|----------|-------|-----------|--------|
| King behind the keep, day (5 m past the castle centre) | Forward+ | 1268 | at least 300 | pass |
| King in the open at spawn, day | Forward+ | 0 | at most 20 | pass |
| King behind the keep, day | Compatibility | 1268 | at least 300 | pass |
| King in the open at spawn, day | Compatibility | 0 | at most 20 | pass |
| King behind the keep, night (real `StartNightIntent`, mood `night`, plus 1.3 s) | Forward+ | 1270 | at least 300 | pass |

The colour did not shift in either renderer, so the measured threshold colour is the specified one. Images opened:
- Forward+ day, hidden: a narrow cyan figure sits on the keep's central roof where the king is hidden; his visible parts above the roof (crown, upper body, the blue collar) are normally shaded.
- Forward+ day, in the open: the king looks exactly as in earlier screenshots, no cyan anywhere.
- Compatibility day, hidden and open: same result with the brighter Compatibility look.
- Forward+ night, hidden: the dark-blue night scene with a bright cyan silhouette clearly readable against the dimmed keep (unlit pass, as predicted).
- The `king_behind_keep.png` produced by `tools/screenshot.sh` in both renderers matches those frames (Gold 30 HUD, silhouette on the keep).

CI renders screenshots with Mesa llvmpipe, which was not verified here: open the `duskhold-screenshots` artifact of the next CI run and confirm the silhouette appears in `king_behind_keep.png` there too.

## Task Commits

1. **Task 1 (tracer): the king shows as a silhouette through buildings**
   - RED: `d9f3ed8` (test): five tests, 3 failing on assertions (no XRay node, applied count, fixture not covered), 2 passing guards (imported materials untouched, buildings clean)
   - GREEN: `790b0af` (feat): `XRaySilhouette` and the `XRay` node on the king model
2. **Task 2: king_behind_keep screenshot and night readability** - `9d2c024` (feat)

**Plan metadata:** recorded in the docs commit that carries this file.

## Tracer gate

Task 1's `<verify>` (full suite, test_king_xray and test_building_models present in the JUnit XML, lint) was re-run end to end after the GREEN change and passed (315 tests, 0 failures) before task 2 started. Final suite after task 2: 315/315, 0 failures; lint clean.

## Design Defaults (from the plan; none changed)

| Choice | Default | Why |
|--------|---------|-----|
| Occlusion technique | Godot's built-in stencil X-Ray preset on duplicated copies of the king's surface materials | Verified again here in Forward+ and Compatibility with no false tint in the open (0 px) |
| `stencil_color` | `Color(0.4, 0.9, 1.0, 1.0)`, light cyan, opaque | The generated pass is unshaded, so night did not dim it (1270 px at night vs 1268 by day) |
| Which models | The king only | Test-enforced: no building mesh gains X-Ray |
| Screenshot | New `king_behind_keep` shot (seven in total) | Permanent visual record, locally and as a CI artifact |

## Files Created/Modified

- `presentation/vfx/xray_silhouette.gd` (+ `.gd.uid`) - the reusable silhouette node.
- `presentation/king/king_model.tscn` - ext_resource, `load_steps` 5 to 6, `XRay` node.
- `tests/e2e/test_king_xray.gd` (+ `.gd.uid`) - five proofs.
- `tools/screenshot/shot_scenarios.gd` - `KING_BEHIND_KEEP`, `BEHIND_KEEP_OFFSET`, `_king_behind_keep`.
- `tools/screenshot.sh` - seventh shot in the list, header comment and "all seven".

## Decisions Made

None beyond the plan's defaults. The one execution-level choice: the RED commit includes a signature-only `xray_silhouette.gd` stub so the typed tests load and fail on assertions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] RED commit needs an interface stub**
- **Found during:** Task 1 RED
- **Issue:** `test_king_xray.gd` is statically typed against `XRaySilhouette`; with no class the whole script fails to parse, which would be an INVALID_RED (a parse error rather than an assertion on the behavior).
- **Fix:** the RED commit also contains `xray_silhouette.gd` with the final signatures returning 0; the tests then failed on assertions (3 of 5), as in plan 01-11.
- **Files modified:** `presentation/vfx/xray_silhouette.gd`
- **Commit:** `d9f3ed8`

**2. [Rule 1 - Bug] Missing `match` arm in the first screenshot edit**
- **Found during:** Task 2 captures
- **Issue:** my scripted edit added the shot constant, `ALL_SHOTS` entry and scenario function but the `match` arm silently did not apply, so `king_behind_keep` was reported "unknown shot" (the shot runner exited 1).
- **Fix:** added the `KING_BEHIND_KEEP` arm to `ShotScenarios.run`; all three captures then succeeded.
- **Files modified:** `tools/screenshot/shot_scenarios.gd`
- **Commit:** `9d2c024` (fixed before the commit; never committed broken)

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug in my own edit). **Impact:** none on scope or behavior.

### TDD notes

Task 1's RED: 3 of 5 tests failed on assertions (missing XRay node twice, fixture surface not covered). The two that passed in RED (source materials untouched, no X-Ray on buildings) are negative guards that hold trivially before the feature exists and keep protecting after it.

## Issues Encountered

- The night self-check first captured without finding the lighting node (probe looked for a node named `DayNightLighting`; the node is called `Lighting`). Re-run with the right node: mood reached `night`, 1270 px.
- The shot's 1268 px silhouette is a narrow figure because the 10.1 m keep roof hides most of the king while his upper body and crown stay visible above it; this is the intended X-Ray result.

## Known Stubs

None.

## Threat Flags

None. T-01-20 (tampering with shared GLB materials) is mitigated and test-enforced; T-01-21 (extra render pass) is accepted and goes to the Phase 4 stress test.

## Next Phase Readiness

G-01-3 part 1 is closed; with 01-11 all three parts of G-01-3 are done. End-of-phase human check (from the plan): ride the king behind the castle keep, a tier-III House and a tier-II tower by day and after starting a night; the hidden part shows as a light-cyan silhouette and nothing is tinted in the open. Also open the CI `duskhold-screenshots` artifact to confirm the silhouette under llvmpipe. No Godot process left running; nothing pushed.

## Self-Check: PASSED

- Files found: `presentation/vfx/xray_silhouette.gd`, `presentation/vfx/xray_silhouette.gd.uid`, `tests/e2e/test_king_xray.gd`, `tests/e2e/test_king_xray.gd.uid`, `presentation/king/king_model.tscn`, `tools/screenshot/shot_scenarios.gd`, `tools/screenshot.sh`.
- Commits found: `d9f3ed8`, `790b0af`, `9d2c024`.
- Acceptance gates re-run: `class_name XRaySilhouette`, `STENCIL_MODE_XRAY`, `set_surface_override_material`, `duplicate()` and `find_children("*", "MeshInstance3D", true, false)` present; `king_model.tscn` contains `xray_silhouette.gd`, `name="XRay"` and `stencil_color = Color(0.4, 0.9, 1, 1)`; `shot_scenarios.gd` contains `KING_BEHIND_KEEP`, `BEHIND_KEEP_OFFSET`, `get_applied_count`; `screenshot.sh` has `king_behind_keep` and "all seven"; full suite 315/315 with test_king_xray, test_building_models and test_shot_blank_check in the XML; lint clean; 7 of 7 PNGs saved (Forward+) and the Compatibility run of `king_behind_keep` saved.
