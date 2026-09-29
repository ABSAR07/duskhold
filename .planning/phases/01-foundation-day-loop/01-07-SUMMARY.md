---
phase: 01-foundation-day-loop
plan: 07
subsystem: presentation-assets
tags: [godot, cc0, kenney, quaternius, git-lfs, attribution, gltf, art-02]

requires:
  - phase: 01-foundation-day-loop
    provides: "01-05 BuildingViews._make_visual seam and CastleCenter landmark; 01-04 king Model pivot with facing logic; 01-01 vendored GUT and LFS routing"
provides:
  - "assets/attribution.json + ASSETS.md: test-enforced log of every third-party file (engine, GUT, four CC0 model sources) with archive SHA256 and retrieval date"
  - "BuildingViewEntry / BuildingViewCatalog seam with primitive fallback and view_source meta"
  - "Real CC0 models for the mounted king, House tiers I-III, tower tiers I-II and the castle center, in text wrapper scenes"
  - "tests/e2e/test_building_models.gd and tests/unit/test_attribution_log.gd"
affects: [phase-08-art-pass, phase-13-credits-screen, 01-10-export-and-push]

actuals:
  tokens: 13800
  tasks: 3
  commits: 3

tech-stack:
  added: ["Kenney Castle Kit 2.0 (CC0)", "Kenney Fantasy Town Kit 2.0 (CC0)", "Kenney Mini Characters 1.0 (CC0)", "Quaternius animated horse 2021 (CC0 via Poly Pizza)"]
  patterns:
    - "Third-party binaries live only under assets/third_party/<pack_id>/ (GLB/PNG via Git LFS, .import files committed) with the pack licence file beside them"
    - "Model wrapper scenes: Node3D root + scaled Model pivot instancing GLB pieces; catalog .tres maps (building_id, tier) to a wrapper scene"
    - "Tests that assert primitive shapes clear BuildingViews.catalog first; model tests read view_source meta"

key-files:
  created:
    - assets/third_party/kenney_castle_kit/
    - assets/third_party/kenney_fantasy_town_kit/
    - assets/third_party/kenney_mini_characters/
    - assets/third_party/quaternius_horse/
    - presentation/buildings/models/house_t1.tscn
    - presentation/buildings/models/house_t2.tscn
    - presentation/buildings/models/house_t3.tscn
    - presentation/buildings/models/tower_t1.tscn
    - presentation/buildings/models/tower_t2.tscn
    - presentation/buildings/models/castle_center.tscn
    - presentation/king/king_model.tscn
    - tests/e2e/test_building_models.gd
  modified:
    - assets/attribution.json
    - ASSETS.md
    - presentation/buildings/building_view_catalog.tres
    - presentation/king/king.tscn
    - tests/e2e/test_upgrade_at_spot.gd

key-decisions:
  - "Owner approved exactly Kenney packs 1-3 plus the animated horse 4b (verbatim reply recorded below); nothing else was downloaded"
  - "Horse recorded as CC0-1.0 with the Quaternius QAL v1.0 wording quoted next to the Poly Pizza CC0 statement so the provenance is auditable"
  - "Houses and the castle keep are composed from kit pieces in wrapper scenes because neither kit ships a complete house or keep model"
  - "Rider is Kenney character-male-b with a small gold crown primitive, since no crowned figure exists in the pack"
  - "Horse is left in its bind pose; gait animation is deferred to the Phase 8 art pass"

patterns-established:
  - "Attribution: one JSON entry per pack folder, sorted by id, mirrored row-for-row in ASSETS.md, enforced by test_attribution_log"
  - "Scale matching lives in the text wrapper scene's Model pivot (D-01); Phase 8 does full normalization"

requirements-completed: [ART-02]

coverage:
  - id: D1
    description: "Every third-party file is logged with source, licence, author, retrieval date and SHA256; the log is test-enforced (CC0-1.0/MIT only, full coverage, sorted, no nested paths)"
    requirement: "ART-02"
    verification:
      - kind: unit
        ref: "tests/unit/test_attribution_log.gd (all tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "House tiers I-III, tower tiers I-II and the castle center render CC0 model wrapper scenes; taller/bigger per tier; primitive fallback still works"
    requirement: "ART-02"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_building_models.gd (all tests)"
        status: pass
      - kind: unit
        ref: "tests/unit/test_building_view_catalog.gd (all tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The king renders as a crowned rider on a horse that turns to face its riding direction, roughly 2.5 m tall and smaller than a House"
    verification:
      - kind: e2e
        ref: "tests/e2e/test_building_models.gd#test_king_model_pivot_holds_the_composed_king_model"
        status: pass
      - kind: e2e
        ref: "tests/e2e/test_king_ride.gd#test_model_turns_to_face_the_ride_direction_and_the_body_does_not"
        status: pass
    human_judgment: true
    rationale: "Whether the composed rider/horse and the kit-composed buildings look right and are scale-matched in the running game is a visual judgment; the plan's Task 3 human-check covers it"
  - id: D4
    description: "Every committed GLB and PNG under assets/third_party/ is an LFS object and no reference-game name appears in game content"
    verification:
      - kind: other
        ref: "Task 3 automated verify chain (git lfs ls-files cross-check and git grep)"
        status: pass
    human_judgment: false

duration: "~35 min this continuation (Task 1 ran earlier, plus the Task 2 approval wait)"
completed: 2026-09-29
status: complete
plan_head_before: cfa1b39e5685065206bd36fbfa95c05cbfd59f71
plan_head_after: 90d1b6c00b99aae595f109c8d53ec890be3bf590
---

# Phase 1 Plan 07: CC0 Models and Attribution Log Summary

**A test-enforced attribution log (engine, GUT and four CC0 sources with archive SHA256) plus real Kenney and Quaternius models for the crowned mounted king, three House tiers, two tower tiers and the castle keep, wired through a catalog seam with a primitive fallback.**

## Performance

- **Duration:** ~35 min for Tasks 2-3 in this continuation (Task 1 ran in an earlier session, plus the owner-approval wait)
- **Completed:** 2026-09-29T10:27Z
- **Tasks:** 3 (Task 1 TDD, Task 2 checkpoint, Task 3 auto)
- **Files:** 90 changed in the plan-owned commits (mostly GLB/PNG/.import under assets/third_party/)

## Accomplishments

- Attribution log: `assets/attribution.json` (schema_version 1, six entries sorted by id) and `ASSETS.md` in the same order, guarded by `test_attribution_log`.
- Catalog seam: `BuildingViews.catalog` picks a wrapper scene by (building_id, tier), else a primitive; `view_source` meta records which.
- Four owner-approved CC0 downloads imported as small subsets in Git LFS (19 binaries, about 1.6 MB), with `.import` files and each pack's licence notice.
- King is a Kenney rider with a gold crown primitive on the Quaternius horse under the existing `Model` pivot; facing logic untouched.
- Rendered each wrapper scene and the real prototype map headlessly-with-window to check scale: king about 2.6 m tall, T1 House 3.1 m, T3 House 6.2 m, towers 5.4 m and 7.8 m, keep about 10 m with flag.

## Owner approval (Task 2), verbatim

> Kenney 1–3 + animated horse 4b

Meaning: download only Kenney Castle Kit 2.0, Kenney Fantasy Town Kit 2.0, Kenney Mini Characters and the Quaternius animated horse (2021) via Poly Pizza (4b, not 4a). Each size matched the approved figure exactly and no request redirected (`curl --fail`, `redirects=0`).

## Survey and download table

| Pack | Exact files kept | Direct URL | Bytes | Archive SHA256 | Retrieved | Licence page and wording |
|---|---|---|---|---|---|---|
| Kenney Castle Kit 2.0 | `tower-square-base`, `tower-square-mid`, `tower-square-mid-windows`, `tower-square-top-roof`, `tower-square-top-roof-high`, `wall`, `flag` (.glb) + `Textures/colormap.png` + `License.txt` | https://kenney.nl/media/pages/assets/castle-kit/a395102d20-1711543616/kenney_castle-kit.zip | 2,232,589 | `921f3f73927bb23106cae34bc21d5ab4b033a9fc120475e96f714a406e3169df` | 2026-09-29 | https://kenney.nl/assets/castle-kit; License.txt: "License: (Creative Commons Zero, CC0)" |
| Kenney Fantasy Town Kit 2.0 | `wall`, `wall-door`, `wall-window-small`, `wall-window-shutters`, `roof-gable`, `roof-high-gable`, `chimney` (.glb) + `Textures/colormap.png` + `License.txt` | https://kenney.nl/media/pages/assets/fantasy-town-kit/efe948d309-1754222374/kenney_fantasy-town-kit_2.0.zip | 3,854,691 | `1a7530c09f4d2fa2cdee259876f089334f8b1f27fa86a0c4f54ef86cdd8676ef` | 2026-09-29 | https://kenney.nl/assets/fantasy-town-kit; License.txt: "License: (Creative Commons Zero, CC0)" |
| Kenney Mini Characters 1.0 | `character-male-b` (.glb) + `Textures/colormap.png` + `License.txt` | https://kenney.nl/media/pages/assets/mini-characters/bfc7e272b4-1774770718/kenney_mini-characters.zip | 2,403,059 | `9e1d48e6d7b8479ebbe84df71eb5bd8e1b3f0da546dea641890dccc8a02d0999` | 2026-09-29 | https://kenney.nl/assets/mini-characters; License.txt: "License: (Creative Commons Zero, CC0)" |
| Quaternius Horse, animated (2021), 4b | `horse_animated.glb` + `License.txt` (project-written provenance note) | https://static.poly.pizza/d37dbc87-ca61-4b2c-a2da-d2f0c4240bef.glb (page https://poly.pizza/m/qvTrSG9pZF) | 1,108,124 | `fae7a7ec91e0d6a33554efb896fac9c4e8c632644183bcb8cc962f673d3ce609` (of the GLB; no archive) | 2026-09-29 | see below |

The three Kenney zips were deleted from `.tools/downloads/` after extraction, as was the horse download (its copy lives in the repo).

### Horse licence evidence

- Poly Pizza page states "Public Domain (CC0)" and links creativecommons.org/publicdomain/zero/1.0/ (orchestrator re-checked 2026-09-29).
- The 2021 pack page https://quaternius.com/packs/ultimateanimatedanimals.html states "License CC0".
- Caveat: https://quaternius.com/license.html now shows the "Quaternius Asset License (QAL) v1.0", last updated 8/28/2026. It forbids redistributing "the Assets themselves ... as a standalone asset" and says "the version in effect at the time you obtained the Assets governs your use of them".
- Decision: recorded as `CC0-1.0` (obtained under CC0 and used inside a game, not redistributed standalone). The same evidence is in the horse's `attribution.json` notes, `ASSETS.md`, and `assets/third_party/quaternius_horse/License.txt`.

## Task Commits

1. **Task 1 (RED): failing attribution tests** - `303d3ca` (test)
2. **Task 1 (GREEN): attribution log and building view catalog seam** - `a367181` (feat)
3. **Task 2: owner approval checkpoint** - no commit (reply recorded above)
4. **Task 3: import approved CC0 models, wire buildings and king, log every file** - `90d1b6c` (feat)

**Plan metadata:** the docs commit that adds this SUMMARY and the state files.

`commits: 3` counts only the `(01-07)` task commits. `git rev-list` from the ledger base also covers the plan 01-06 commits (3e5677c..cc277af) that landed on this branch during the checkpoint wait, so the raw range is larger; those commits are not part of this plan.

## Files Created/Modified

- `assets/third_party/{kenney_castle_kit,kenney_fantasy_town_kit,kenney_mini_characters,quaternius_horse}/` - chosen GLBs, colormaps, `.import` files, licence notices (19 LFS binaries)
- `presentation/buildings/models/{house_t1,house_t2,house_t3,tower_t1,tower_t2,castle_center}.tscn` - wrapper scenes (Node3D root, scaled `Model` pivot)
- `presentation/buildings/building_view_catalog.tres` - five tier entries plus the castle scene
- `presentation/king/king_model.tscn` - horse (0.42 scale) + rider (1.6 scale) + gold crown; `presentation/king/king.tscn` now instances it under `Model`
- `assets/attribution.json`, `ASSETS.md` - four new entries/rows, checksum and licence-caveat sections
- `tests/e2e/test_building_models.gd` - wiring, growth, scale and king-model tests (6 tests)
- `tests/e2e/test_upgrade_at_spot.gd` - primitive-shape test now clears the catalog first

## Decisions Made

- Wrapper scenes carry scale on a `Model` child pivot so the root stays an identity Node3D (`_instance_model` casts the root to Node3D and positions it).
- Scale choices: House 2.0x (T1 2.2 m footprint, T2/T3 4.2 x 2.2 m), tower 1.8x, keep 2.4x, horse 0.42x, rider 1.6x. Full normalization is Phase 8.
- Horse GLB faces +Z like the rider, matching the king's `atan2(vx, vz)` facing, so no extra rotation was needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Regression] 01-05 primitive-shape test broke against real models**
- **Found during:** Task 3 (planned by the Task 1 executor's notes)
- **Issue:** `test_tower_view_is_a_cylinder_and_house_view_a_box_that_grows_with_tier` asserts CylinderMesh/BoxMesh views; the default catalog now supplies models.
- **Fix:** Renamed to `test_primitive_fallback_tower_is_a_cylinder_and_house_a_box_that_grows_with_tier` and set `views.catalog = null` first, so it still covers the fallback while `test_building_models` covers models. The assertions were not weakened.
- **Files modified:** tests/e2e/test_upgrade_at_spot.gd
- **Committed in:** 90d1b6c

**2. [Rule 3 - Blocking] Neither Kenney kit ships a complete house or keep**
- **Found during:** Task 3 (archive inspection)
- **Issue:** The Fantasy Town Kit is modular wall/roof pieces and the Castle Kit has towers and walls but no keep, so "one GLB per wrapper" was not possible.
- **Fix:** Wrapper scenes compose kit pieces: Houses from four or six wall panels (door, windows) plus gable roofs, tier III with a second storey, high roof and chimney; towers from stacked base/mid/roof pieces; the keep as a central tower with four corner turrets and four wall segments around a 1x1 courtyard, with a flag. The kept-file list is therefore 7 + 7 + 1 + 1 GLBs rather than the minimum.
- **Files modified:** presentation/buildings/models/*.tscn, assets/third_party/
- **Committed in:** 90d1b6c

**3. [Rule 2 - Missing critical] No crowned figure in Mini Characters**
- **Found during:** Task 3
- **Issue:** The plan asked to prefer a crowned or royal rider; none exists.
- **Fix:** Used `character-male-b` and added a small gold `CylinderMesh` crown (project-made primitive) under the Rider node; recorded in ASSETS.md and the entry notes so it is not mistaken for CC0 content.
- **Files modified:** presentation/king/king_model.tscn, ASSETS.md, assets/attribution.json
- **Committed in:** 90d1b6c

**4. [Additive, Task 1] Extra unplanned test** `tests/unit/test_building_view_catalog.gd` (catalog lookups and the fallback) was added during Task 1 (`a367181`); not required by the plan.

---

**Total deviations:** 3 auto-fixed (1 regression fix, 1 blocking, 1 missing-critical) plus 1 additive test from Task 1
**Impact on plan:** All necessary for the models to exist and for the suite to stay honest. No scope creep beyond the crown primitive.

## Issues Encountered

- Kenney `License.txt` files arrived with CRLF; git normalizes them to LF under `.gitattributes` (a warning at `git add`, no action needed).
- Nothing else. Sizes matched the approved list exactly, no redirects, no failed downloads, no package-manager installs.

## Known Stubs

None. The horse is deliberately un-animated (bind pose) and the crown is a primitive; both are recorded as decisions, and full art normalization and animation belong to Phase 8.

## Threat Flags

None. The only new surface is third-party binary assets; T-01-12, T-01-13 and T-01-SC are mitigated as planned (licences verified on the source pages, hashes logged, owner-approved URLs, `curl --fail`, only chosen files extracted, name-grep clean).

## User Setup Required

None - no external service configuration required.

## Pending human check

Task 3's `<human-check>` (run the game and eyeball the king, Houses, towers and keep) is left to the phase verifier under `end-of-phase` mode. Executor-side, each wrapper scene and the real prototype map (all buildings built, king near the castle) were rendered to PNG and inspected for scale and orientation.

## Verification

- `bash tools/test.sh`: 136/136 passing (130 before, plus 6 in `test_building_models`), 20 scripts; JUnit contains `test_attribution_log` and `test_building_models`.
- `bash tools/lint.sh`: no problems, 46 files.
- Task 3 verify chain: LFS cross-check of every tracked GLB/PNG under `assets/third_party/`, and the reference-game name grep over game content: pass.
- Acceptance: four CC0-1.0 entries with 64-hex SHA256, sorted by id; every third-party folder has `License.txt`; catalog references all six wrapper scenes; `king.tscn` references `king_model.tscn`.

## Next Phase Readiness

- 01-08 onward can rely on `BuildingViews.catalog`; any new building or tier just needs a wrapper scene and a catalog entry, plus an attribution entry if it brings new third-party files.
- 01-10 owns the next push: the repo is public and the LFS objects (about 1.6 MB) go up then.
- Phase 8 owns scale normalization, horse animation and a proper crown.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*

## Self-Check: PASSED

All created files exist on disk; task commits 303d3ca, a367181 and 90d1b6c are in git history; the plan-level verification chain and 136/136 tests pass.
