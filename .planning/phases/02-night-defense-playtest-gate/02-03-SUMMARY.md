---
phase: 02-night-defense-playtest-gate
plan: 03
subsystem: simulation
tags: [godot, gdscript, enemy-targeting, castle-damage, king-knockout, respawn, health-bar, hud, gut]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: EnemySystem, KingState, NightSim, PendingHits, SimRecorder, shipped eight-night map and waveless helpers (plans 02-01 and 02-02)
provides:
  - CastleState (integer health, castle_damaged per hit, castle_destroyed exactly once, repair)
  - TargetQuery.nearest_enemy as the single nearest-target seam
  - D-11 targeting in EnemySystem (committed targets, per-id staggered rescans, leash, king pull) with target_of() and id-ordered crowd separation
  - Mortal king: health, knockout, 6/10/14/15/15 s capped countdown from loop_tuning.tres, respawn at king_spawn, dawn heal (KING-06, D-01 to D-06)
  - HealthBar3D (hurt-only billboard bar) on the king and the castle, ghost king, HUD RespawnLabel
affects: [02-04, 02-05, 02-06, 02-07, 02-08, 02-09, 02-10, 02-11]

actuals:
  tokens: 15600
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Target priority in one function (_choose_target): keep king inside leash, king inside aggro, keep valid, castle inside aggro, none; evaluated when the target is invalid or on the (tick + id) % rescan_ticks tick"
    - "Crowd separation: one position snapshot per tick, ascending-id pair loop, displacements applied together"
    - "Knockout countdown is whole ticks decremented in KingState.step; remaining seconds = ticks * STEP so ceili never reads 0 while down"
    - "Optional trailing constructor arguments (tuning, castle, king) so earlier hand-built tests keep compiling"
    - "Presentation nodes (King, HealthBar3D) read run events and never write simulation state"

key-files:
  created:
    - simulation/castle/castle_state.gd
    - simulation/night/target_query.gd
    - presentation/vfx/health_bar_3d.gd
    - tests/unit/test_enemy_targeting.gd
    - tests/unit/test_king_respawn.gd
    - tests/unit/test_health_bar_3d.gd
    - tests/e2e/test_king_knockout.gd
  modified:
    - simulation/night/enemy_system.gd
    - simulation/night/night_sim.gd
    - simulation/king/king_state.gd
    - simulation/run/run_context.gd
    - simulation/run/run_manager.gd
    - simulation/events/sim_events.gd
    - simulation/defs/loop_tuning.gd
    - data/tuning/loop_tuning.tres
    - tests/support/sim_signals.gd
    - tools/replay/sim_recorder.gd
    - tests/unit/test_loop_tuning_contract.gd
    - presentation/king/king.gd
    - presentation/king/king.tscn
    - presentation/map/prototype_map.tscn
    - presentation/buildings/building_views.gd
    - ui/hud/hud.gd
    - ui/hud/hud.tscn

key-decisions:
  - "castle_damaged and king_damaged report the hit points actually lost (a clamped overkill reports less than the swing), so event amounts sum to damage dealt"
  - "A destroyed castle makes the whole enemy field stand still; the loss itself lands in plan 02-07"
  - "A king inside aggro_range wins any rescan; a king target is kept until he is down or beyond leash_range (D-11)"
  - "The respawn countdown outlasting the night is legal: dawn restores him at king_spawn and fires king_respawned once"
  - "The King health bar refreshes on dawn_payout (emitted right after the dawn heal) because phase_changed fires before the heal"

patterns-established:
  - "New SimEvents signals go into SimSignals.ALL and SimRecorder (handler plus HANDLED) in the same task (continued)"
  - "TDD tasks commit a RED test commit carrying only the stubs needed to fail on assertions, then a GREEN feat commit"

requirements-completed: [KING-06]

coverage:
  - id: D1
    description: "Enemies commit to a target by D-11 priority, rescan on staggered ticks, keep the king inside the leash and drop him when he is down"
    requirement: KING-06
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_targeting.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "Grunts strike the castle once per attack_interval; castle hp clamps at 0 and castle_destroyed fires exactly once; a destroyed castle stops the field"
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_targeting.gd#test_the_castle_hp_clamps_at_zero_and_is_destroyed_exactly_once"
        status: pass
    human_judgment: false
  - id: D3
    description: "Ten grunts spawned on one point spread to at least 0.9 of their combined radii in one second, identically on two runs"
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_targeting.gd#test_ten_grunts_on_one_point_spread_out_while_marching"
        status: pass
    human_judgment: false
  - id: D4
    description: "King knockout and respawn: 1 hp stays up, exactly 0 knocks out, overkill clamps, countdown 6/10/14/15/15 s in whole ticks, no damage or attacks while down, reset per night, no regeneration, no gold cost, dawn restore, king_respawned once"
    requirement: KING-06
    verification:
      - kind: unit
        ref: "tests/unit/test_king_respawn.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "Respawn start, step and cap are exported tuning data and the shipped cap is pinned at 15 s"
    requirement: KING-06
    verification:
      - kind: unit
        ref: "tests/unit/test_loop_tuning_contract.gd#test_shipped_respawn_cap_is_fifteen_seconds"
        status: pass
    human_judgment: false
  - id: D6
    description: "In the real scene a knocked-out king shows a ghost, the HUD countdown, cannot move, and reappears at king_spawn; king and castle bars show only once hurt"
    requirement: KING-06
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_knockout.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_health_bar_3d.gd"
        status: pass
    human_judgment: false
  - id: D7
    description: "Whether the ghost capsule, the health bars and the countdown read clearly on screen"
    requirement: KING-06
    verification: []
    human_judgment: true
    rationale: "Readability is a visual judgement; the tests prove state, not looks. The screenshot tool needs a real renderer and was not run here."

duration: 43min
completed: 2026-10-05
status: complete
plan_head_before: 569a5d701652df2030c5153d1bf4b34e6ae75273
plan_head_after: 05bc97a5c3d706ea72f9a6e809f5e4f18490330a
commits: 6
---

# Phase 2 Plan 03: Enemies Fight Back, the King Is Mortal Summary

**D-11 enemy targeting with committed targets and id-ordered separation, castle damage, and a king who is knocked out and returns at the castle after a data-driven 6, 10, 14, 15, 15 s countdown, with hurt-only health bars, a ghost king and a HUD countdown.**

## Performance

- **Duration:** 43 min
- **Started:** 2026-10-05T07:26:45Z
- **Completed:** 2026-10-05T08:12:00Z
- **Tasks:** 3 (6 commits: RED and GREEN for each)
- **Files modified:** 31 (including `.gd.uid` files)

## Accomplishments

- `CastleState` owns integer health from `MapConfig.castle_max_health`; `castle_damaged` reports points actually lost, `castle_destroyed` fires exactly once, a hit on a destroyed castle drops. RunContext builds it and hands it to NightSim, which resolves `castle` hits into it.
- `EnemySystem` now fights. Each enemy keeps a `target_kind`/`target_id` (exposed read-only through `target_of`), rescans only when the target is invalid or on `(tick + id) % rescan_ticks`, walks to `target radius + attack_range`, and strikes through `PendingHits` once per `attack_interval`. Priority: keep a king target inside the leash; the king when up and inside aggro range (this is how he pulls enemies off the castle); keep a valid target; the castle inside aggro range plus its radius; otherwise keep marching. After all enemies moved, `_separate()` pushes overlapping enemies apart from one snapshot in id order.
- `TargetQuery.nearest_enemy` is the one nearest-target seam (Phase 4 spatial hash); `KingState` calls it and `test_king_combat` is unchanged and green.
- `KingState` is mortal: integer health, `take_damage` (clamped, ignored while down), knockout counters, a whole-tick countdown of `SimClock.ticks(LoopTuning.respawn_seconds(n))`, respawn at the spawn with full health, `restore_for_dawn()` called by `RunManager._enter_dawn` before the payout. No regeneration, no gold cost, the run never ends (D-03, D-05, D-06). `LoopTuning` gained `respawn_start_seconds` 6, `respawn_step_seconds` 4, `respawn_cap_seconds` 15 in `loop_tuning.tres` and a sanitised `respawn_seconds` helper; the contract test pins the 15 s cap.
- Presentation: `HealthBar3D` (billboard, unshaded, no depth test, shown only while `0 < hp < max`) on the king and castle; `King.bind_run` hides the model, shows a translucent cyan ghost and ignores movement while down, and teleports to `king_spawn` on respawn; `Hud` shows `RESPAWN_TEXT` with `ceili(remaining)`.
- Five new SimEvents signals (`castle_damaged`, `castle_destroyed`, `king_damaged`, `king_downed`, `king_respawned`) are in `SimSignals.ALL` and `SimRecorder` with handlers.

## Task Commits

1. **Task 1 RED:** failing tests for targeting, castle damage, separation - `8532fa5` (test)
2. **Task 1 GREEN:** castle, TargetQuery, targeting and separation - `229a381` (feat)
3. **Task 2 RED:** failing tests for knockout, respawn and king targeting - `3f289f0` (test)
4. **Task 2 GREEN:** mortal king, tuning data, dawn heal - `b6bd8dd` (feat)
5. **Task 3 RED:** failing tests for the bar, ghost and countdown - `2ec31aa` (test)
6. **Task 3 GREEN:** health bars, ghost king, HUD countdown - `05bc97a` (feat)

**Plan metadata:** recorded in the final docs commit.

## Verification

- Full suite after Task 3: 60 scripts, 486 tests, 0 failures (baseline 440 in 56 scripts); `bash tools/lint.sh` clean.
- `test_enemy_targeting`, `test_king_respawn`, `test_loop_tuning_contract`, `test_health_bar_3d`, `test_king_knockout`, `test_king_xray` and `test_determinism` are all present in the JUnit XML.
- Mutation probe: disabling the downed-king early return in `King._physics_process` made `test_king_knockout` fail on "x unchanged" (the king moved 2.2 m); the code was restored.

## Deviations from Plan

### Auto-fixed Issues

None needed beyond the interface choices below; no bug or blocker surfaced in existing code.

### Interface details that differ from the plan's sketch (no behavior change)

- **Optional constructor arguments.** `KingState._init` takes `tuning: LoopTuning = null` (falls back to a fresh `LoopTuning`), `NightSim._init` takes `castle: CastleState = null` (builds its own), `RunManager._init` takes `king: KingState = null`. The plan says the constructors "become" these; keeping the arguments optional leaves `test_king_combat` and `test_map_validate_nights` untouched and compiling, which the plan itself requires for `test_king_combat`.
- **`EnemySystem.step(tick, castle, king, hits)`** replaces `step(tick, castle_pos, castle_radius)`; `king` may be null so a hand-built castle-only test needs no king.
- **`EnemySystem.is_rescan_tick`** is a public static helper so the staggered-rescan rule is unit-testable on its own; the behaviour is also proven through the king pull (switch tick `rescan_ticks - id`).
- **`castle_damaged` / `king_damaged` amounts** are the points actually lost, not the swing size (the plan's interface comment only says "clamps at 0").
- **Dawn bar refresh.** `King` refreshes its bar on `dawn_payout`, not `phase_changed`: `RunManager` changes phase first and heals second, and `dawn_payout` is the first event after the heal. `restore_for_dawn` itself emits only `king_respawned` (when he was down).
- **Accessors for tests.** `King.get_health_bar()`, `King.is_ghost_shown()`, `BuildingViews.get_castle_health_bar()`, `HealthBar3D.get_fill_ratio()`, `CastleState` getters were added; they are read-only.
- **Task 3 RED process.** The presentation implementation was written before its tests; to keep the gate honest it was set aside (files restored from a scratchpad copy), the tests were committed against minimal stubs and failed on assertions (0 of 4 e2e, 0 of 9 unit), then the implementation was restored.

---

**Total deviations:** 0 auto-fixed; 6 interface details noted above.
**Impact on plan:** none; every behavior-list case holds.

## Issues Encountered

- A first `edit3.py` helper script was written but not executed, so the first Task 2 RED run did not include the king-targeting tests; noticed from the test count (10 instead of 15), fixed and re-run before the RED commit.
- gdformat rewrites files to CRLF in the working tree; all scripted edits normalise to LF on write so git sees no spurious diffs.

## Known Stubs

None. The RED-phase stubs were replaced by the GREEN commits.

## Threat Flags

None. T-02-06 (King node never writes simulation state; `report_position` ignored while down; `test_king_knockout` proves a downed king cannot be moved) and T-02-07 (`respawn_seconds` sanitised and never above the cap; `test_respawn_seconds_is_sanitised_so_bad_data_cannot_strand_the_king`) are mitigated as planned; no new network, auth or file surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02-04 can add standing buildings to the same `_choose_target` list (between "keep a valid target" and "the castle") and reuse `HealthBar3D` and `PendingHits.KIND_BUILDING`.
- Plan 02-07 owns what `castle_destroyed` does (the loss and results screen); the enemy field already stands still on a destroyed castle.
- Not run: the screenshot tool (it needs a real renderer), so the ghost capsule, bars and label are verified by state, not by eye; the owner judges readability at the playtest gate.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*

## Self-Check: PASSED

- Created files verified present: castle_state.gd, target_query.gd, health_bar_3d.gd, four new test suites.
- Commits `8532fa5`, `229a381`, `3f289f0`, `b6bd8dd`, `2ec31aa`, `05bc97a` exist; `git rev-list --count 569a5d7..HEAD` is 6.
- Acceptance strings checked: `class_name CastleState`, `castle_destroyed.emit`, `static func nearest_enemy(`, `func respawn_seconds(knockout_number: int) -> float`, `respawn_cap_seconds = 15.0`, `restore_for_dawn()` in run_manager.gd, `RespawnLabel` in hud.tscn, `back in %d s` in hud.gd, King in group `run_bound`.
- Full suite: 60 scripts, 486 tests, all passing; lint clean.
