---
phase: 02-night-defense-playtest-gate
plan: 01
subsystem: simulation
tags: [godot, gdscript, determinism, fixed-step, seeded-rng, night-loop, replay, gut]

requires:
  - phase: 01-foundation-day-loop
    provides: RunManager phase owner, RunContext composition root, SimEvents bus, CommandProcessor intents, BuildingSystem, MapRoot and bind_run presentation pattern
provides:
  - SimClock (30 Hz step contract, integer tick conversion) and SimRng (splitmix stream seeds) with contract tests
  - DR-5 source-scan guard against nondeterministic engine calls in simulation/
  - Night data schema (EnemyDef, SpawnPointDef, SpawnGroupDef, NightDef, MapConfig night fields, KingDef combat fields) and grunt/king data
  - WaveSchedule, PendingHits, EnemySystem, KingState, NightSim in the fixed DR-8 order
  - RunContext.step/advance/alpha, RunManager night hook (LOOP-03), MapRoot fixed-step feed with fixed_run_seed
  - EnemyViews interpolated puppets
  - SimRecorder digest, PlaytestBot, ReplayDriver with the in-process double-run determinism proof
affects: [02-02, 02-03, 02-04, 02-05, 02-06, 02-07, 02-08, 02-09, 02-10, 02-11, phase-04-flow-field]

actuals:
  tokens: 22300
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Decide-then-resolve: attackers enqueue PendingHits, due hits resolve together in (arrival tick, seq) order"
    - "Id-based storage-agnostic enemy API (ids never reused) as the Phase 4 flow-field/MultiMesh seam"
    - "Integer ticks inside the night; data seconds converted once with SimClock.ticks"
    - "Integer-only event log digest (positions quantized roundi(x * 100.0)) for replay equality"
    - "Waveless-map fallback keeps the Phase 1 timed night so every Phase 1 suite stays green"

key-files:
  created:
    - simulation/clock/sim_clock.gd
    - simulation/clock/sim_rng.gd
    - simulation/defs/enemy_def.gd
    - simulation/defs/spawn_point_def.gd
    - simulation/defs/spawn_group_def.gd
    - simulation/defs/night_def.gd
    - simulation/night/wave_schedule.gd
    - simulation/night/pending_hits.gd
    - simulation/night/enemy_system.gd
    - simulation/night/night_sim.gd
    - simulation/king/king_state.gd
    - presentation/enemies/enemy_views.gd
    - data/enemies/grunt.tres
    - tests/fixtures/fixture_map_one_night.tres
    - tools/replay/sim_recorder.gd
    - tools/replay/playtest_bot.gd
    - tools/replay/replay_driver.gd
    - tests/unit/test_sim_rules_guard.gd
    - tests/unit/test_sim_clock.gd
    - tests/unit/test_sim_rng.gd
    - tests/unit/test_king_combat.gd
    - tests/integration/test_night_loop.gd
    - tests/integration/test_determinism.gd
    - tests/e2e/test_night_tracer_scene.gd
  modified:
    - simulation/defs/map_config.gd
    - simulation/defs/king_def.gd
    - data/king/king.tres
    - simulation/events/sim_events.gd
    - simulation/run/run_manager.gd
    - simulation/run/run_context.gd
    - presentation/map/map_root.gd
    - presentation/map/prototype_map.tscn
    - tests/support/sim_signals.gd
    - tests/e2e/test_walking_skeleton.gd

key-decisions:
  - "SimClock.STEP is a const 1/30 s pinned by test_sim_clock.gd, not a LoopTuning field (changing it regenerates every golden digest)"
  - "Night timers are integer ticks relative to the night start; NightSim keeps its own night tick and RunContext passes the run tick"
  - "Clearing a night is is_cleared() = schedule finished AND no enemy alive; waveless maps keep the Phase 1 placeholder timer"
  - "Recorder lines are '<tick> <event> <args>' for every line including the final state, so one line grammar covers the whole digest"

patterns-established:
  - "Every new SimEvents signal is added to SimSignals.ALL and to SimRecorder.HANDLED in the same task"
  - "Tests vary data only on duplicate_deep(DEEP_DUPLICATE_ALL) copies of the fixture"
  - "Presentation puppets read previous/current simulation positions and RunContext.alpha(); they never write simulation state"

requirements-completed: [DEV-05, LOOP-03, KING-03]

coverage:
  - id: D1
    description: "Fixed 30 Hz step and seeded RNG streams run behind pinned contract tests and a DR-5 forbidden-API source scan"
    requirement: DEV-05
    verification:
      - kind: unit
        ref: "tests/unit/test_sim_clock.gd, tests/unit/test_sim_rng.gd, tests/unit/test_sim_rules_guard.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "A seeded night spawns grunts, marches them to the castle edge, lets the king's passive attack kill them, and enters DAWN only when every group has spawned and none is alive"
    requirement: LOOP-03
    verification:
      - kind: integration
        ref: "tests/integration/test_night_loop.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "King passive attack: inclusive range boundary, lower-id tie-break, no cooldown consumed when idle, integer-tick cadence, same-tick resolution"
    requirement: KING-03
    verification:
      - kind: unit
        ref: "tests/unit/test_king_combat.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "Enemy puppets follow the simulation in the real scene (one per live enemy, none after dawn)"
    requirement: LOOP-03
    verification:
      - kind: e2e
        ref: "tests/e2e/test_night_tracer_scene.gd#test_puppets_follow_the_enemies_through_the_night_to_dawn"
        status: pass
    human_judgment: false
  - id: D5
    description: "Same map, seed and scripted bot replay to an identical integer-only digest; different seeds differ; every SimEvents signal has a recorder handler"
    requirement: DEV-05
    verification:
      - kind: integration
        ref: "tests/integration/test_determinism.gd"
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-10-05
status: complete
plan_head_before: aea94b0ecdda8670027b998342d27f806f50aed7
plan_head_after: 42362dff15f1b7acbdfa8865b8e9b7e4eca1f678
commits: 3
---

# Phase 2 Plan 01: Seeded Night Tracer and Replay Digest Summary

**A pure, integer-tick, 30 Hz night simulation (seeded splitmix spawn streams, decide-then-resolve hits, id-based enemies) guarded by a forbidden-API source scan, proven end to end in the real scene and replayed to an identical sha256 event digest.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-10-05T06:31:27Z
- **Completed:** 2026-10-05T06:50:46Z
- **Tasks:** 2 (3 commits: tracer, TDD RED, TDD GREEN)
- **Files modified:** 56 (including `.gd.uid` files)

## Accomplishments

- The determinism rules (DR-2 to DR-5) landed before any combat code: `SimClock.STEP` and `SimRng` are pinned by contract tests, and `test_sim_rules_guard.gd` scans `simulation/` for global RNG, `Time`, `OS`, scene tree, navigation/physics and transcendental calls, proving it read more than 20 files and that every pattern matches its own sample.
- A seeded night runs end to end: `WaveSchedule` expands the NightDef into integer ticks, `NightSim` spawns with scatter from `SimRng.make(seed, night, STREAM_SPAWN)`, grunts march to the castle edge, `KingState` attacks the nearest in-range enemy through `PendingHits`, and RunManager enters DAWN on `is_cleared()` (LOOP-03, KING-03). Maps with no authored nights keep the Phase 1 timed night, so all 401 Phase 1 and earlier tests stay green.
- `RunContext.step()` is the only clock; `advance(real_delta)` is a clamped accumulator (sixty 1/60 s frames and an uneven split of one second both run exactly 30 steps). `MapRoot` pushes the king position and calls `advance`, with `fixed_run_seed` for tests and replays.
- DEV-05 core proof: `SimRecorder` (integer-only lines, positions quantized with `roundi(x * 100.0)`, sha256 digest), `PlaytestBot` (intents and `report_position` only) and `ReplayDriver` (bounded by `max_ticks`) give identical digests for the same seed in one process and different digests for seeds 1 and 2; a drift test fails if a SimEvents signal has no handler.

## Task Commits

1. **Task 1: Tracer, one seeded night end to end on the fixed step** - `c37088d` (feat)
2. **Task 2 RED: failing determinism tests (with minimal stubs)** - `2158bb8` (test)
3. **Task 2 GREEN: recorder, bot and replay driver** - `42362df` (feat)

**Plan metadata:** recorded in the final docs commit (docs: complete plan).

Tracer gate: `Tracer verified end-to-end — expanding`. The task's `<verify>` (`bash tools/test.sh`, the six suites present in the JUnit XML, `bash tools/lint.sh`) was re-run green before Task 2 started.

## Files Created/Modified

See `key-files` above. Notable: `simulation/night/night_sim.gd` (fixed DR-8 step order), `simulation/clock/sim_rng.gd` (splitmix seed mixing with signed constants), `tools/replay/sim_recorder.gd` (canonical digest), `tests/fixtures/fixture_map_one_night.tres` (two-night fixture the later plans build on).

## Decisions Made

- `STEP` is a const pinned by a contract test rather than tuning data (RESEARCH open question 4, decided here as the plan flagged).
- The night keeps its own tick counter (tick minus the run tick of its first step), so cooldowns, spawn schedule and hit arrival are all night-relative integers.
- `EnemySystem.clear()` keeps the id counter growing, so ids are never reused even across nights.
- Clearing needs the schedule to be finished AND no enemy alive, so an early death with a late spawn pending cannot end the night.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Phase 1 stalled-frame test referenced the removed `MapRoot.MAX_SIM_STEP`**
- **Found during:** Task 1 (MapRoot fixed-step wiring)
- **Issue:** The plan removes the old clamp constant; `tests/e2e/test_walking_skeleton.gd` read it and compared a 0.25 s advance exactly. With a 30 Hz step the clamped quarter second becomes 7 or 8 whole steps (0.2333 or 0.2667 s, depending on the accumulator remainder).
- **Fix:** The assertion now compares against `SimClock.MAX_ADVANCE_SECONDS` with a tolerance of one `SimClock.STEP`, with a comment explaining why. Intent (one stall advances at most the clamp, night does not end) is unchanged.
- **Files modified:** `tests/e2e/test_walking_skeleton.gd`
- **Verification:** full suite green.
- **Committed in:** `c37088d`

**2. [Rule 1 - Spec conflict] Recorder final-state line format**
- **Found during:** Task 2
- **Issue:** The action text writes `final <tick_count> ...` but the behavior list requires every recorded line to match `^-?[0-9]+ [a-z_]+( [^ ]+)*$` (tick first).
- **Fix:** The final line is `<tick> final <phase> <gold> <enemy_count> <day> <night>`, so one grammar covers the whole digest. Empty ids are written as `-` and an empty per-spot dictionary writes no token, so no line carries an empty token.
- **Files modified:** `tools/replay/sim_recorder.gd`
- **Committed in:** `42362df`

**3. [Rule 2 - Missing critical] Night data validation in `MapConfig.validate()`**
- **Found during:** Task 1
- **Issue:** New arrays (enemies, spawn points, nights) had no data-error reporting, unlike the existing fields (T-01-10 pattern); unknown ids or empty nights would loop or crash silently.
- **Fix:** `validate()` now reports unknown or duplicate ids, non-positive hp or counts, negative delays, a night that spawns nothing, and `castle_max_health <= 0`; `WaveSchedule` skips groups with unknown ids at runtime and caps one group at `MAX_GROUP_COUNT` (500) as a resource-exhaustion guard.
- **Files modified:** `simulation/defs/map_config.gd`, `simulation/night/wave_schedule.gd`
- **Committed in:** `c37088d`

### Interface details that differ from the plan's sketch (no behavior change)

- `RunContext._init` names its third parameter `seed_value` (a parameter named `run_seed` would shadow the `run_seed` field); positional callers are unaffected.
- `EnemySystem._init(events)` takes the event bus so `spawn` and `remove_dead` can emit; `EnemySystem.died_count()` and `KingState.get_def()` were added (used by `remaining_count()` and the bot).
- The TDD RED commit carries minimal recorder/bot/driver stubs so the target tests fail on assertions (all 8 failed on planned behavior) rather than on parse errors; the GREEN commit replaces them.

---

**Total deviations:** 3 auto-fixed (1 Rule 3, 1 Rule 1, 1 Rule 2)
**Impact on plan:** All necessary for correctness; no scope creep.

## Issues Encountered

None. The RED run hit one out-of-bounds script error in the last test (indexing an empty log); the test was tightened to assert the log is non-empty first, then RED was committed.

## Known Stubs

None. The RED-phase stubs were replaced in the GREEN commit; grunts waiting at the castle edge (no castle damage yet) is the plan's stated scope and arrives in plans 02-03 to 02-05, not a stub.

## Threat Flags

None. No network, auth, file-access or trust-boundary surface was added beyond the plan's threat model (T-02-01 to T-02-03 mitigated by the source scan, pinned contract tests, `max_ticks` bound, the 0.25 s frame clamp and deep-copied test data).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02-02 can author the prototype map's nights and migrate the Phase 1 timed-night tests onto a waveless map helper; the waveless fallback already keeps them green.
- Later combat plans extend `NightSim.step` behind the same id-based API; any new SimEvents signal needs `SimSignals.ALL` and `SimRecorder` (handler plus `HANDLED`) in the same task.
- `RunManager.get_phase_time_remaining()` still reports the Phase 1 placeholder countdown for NIGHT on authored-night maps; the HUD and overlay copy move to real wave state in a later plan.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*

## Self-Check: PASSED

- Created files verified present (sim_clock, sim_rng, night_sim, enemy_views, sim_recorder, replay_driver, fixture map, seven test suites).
- Commits `c37088d`, `2158bb8`, `42362df` exist; `git rev-list --count aea94b0..HEAD` is 3.
- Full suite: 53 scripts, 409 tests, all passing; `bash tools/lint.sh` clean; all seven required testsuite names present in the JUnit XML.
