---
phase: 04-crowd-scale-battles-walls
plan: 07
subsystem: wall-ai
tags: [godot, gdscript, walls, pathing, wall-decision, integer-arithmetic, hysteresis, stuck-detection, determinism, tracer, tdd]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: Pathing.castle_cost_at / is_sealed / march_step, FlowField.cost_at, the castle_blocked mark and cached castle_blocker, the NavTuning data and its contract test, the gap and ring fixtures (04-06); KIND_WALL target, WallSystem health and version (04-04)
provides:
  - WallDecision, the integer break-or-detour arithmetic and the per-segment published time to destruction on a staggered cadence
  - Enemies that break a wall exactly when ttd + straight walk < detour (or sealed), keep it until the detour wins by more than the hysteresis, and never retake a segment they gave up
  - StuckTracker, read-only stuck flags with a queue-tolerant progress watermark, updated by NightSim after the enemy phase
  - Pathing.decision(), stuck(), detour_ticks(), straight_ticks(), castle_distance_cm()
  - Six NavTuning numbers (wall_decision_seconds, wall_notice_range, wall_neighbour_span, wall_hysteresis_seconds, stuck_seconds, stuck_progress_m) in data and validated
affects: [04-08 overlay and gate stress (reads stuck_ids and longest_streak_ticks, ttd_of), 04-10 bot walls and the walls golden]

actuals:
  tokens: 16100
  tasks: 2
  commits: 3

plan_head_before: 87ab0b3fc43d40786516ac74deebe0c21e7b366f
plan_head_after: 11d7110aee45a1a6096f9731b4448a734773823f

tech-stack:
  added: []
  patterns:
    - "Integer decision path: damage per 10 s, ticks and centimetres, round up with (a + b - 1) / b, SimClock.MAX_TICKS for never, strict < in should_break, seconds to ticks once"
    - "Staggered cadence for a shared published value: due segments are walked as a stride from posmod(-tick, cadence), so a pass touches about 1/15 of the segments and a due segment with nobody near resets to never"
    - "A route read from a position stepped off the blocking wall (Pathing._probe_of) instead of the raw cell cost, so a sealed enemy pressed into the wall does not read the open neighbour across it"
    - "A read-only tracker owned by Pathing, fed by NightSim, with its own dictionary of entries and no event, in the shape of the 04-06 caches"

key-files:
  created:
    - simulation/nav/wall_decision.gd
    - simulation/nav/stuck_tracker.gd
    - tests/unit/test_wall_decision.gd
    - tests/unit/test_stuck_tracker.gd
    - tests/integration/test_wall_behaviour.gd
  modified:
    - simulation/defs/nav_tuning.gd
    - data/tuning/nav_tuning.tres
    - simulation/walls/wall_validation.gd
    - simulation/nav/pathing.gd
    - simulation/night/enemy_system.gd
    - simulation/night/night_sim.gd
    - tests/unit/test_nav_tuning_contract.gd
    - tests/unit/test_map_nav_validation.gd

key-decisions:
  - "A blocked marcher takes a segment from min(wall_notice_range, leash_range) metres of its face (10 m for the grunt), not aggro_range (6 m): the plan says an enemy within the notice range attacks the segment, and a take beyond the leash would be invalid the next tick"
  - "An enemy that gives a segment up for the detour never takes that same segment again while a way round exists: the crowd near it thins as the others walk through, so ttd dithers around the break-even and the 15-tick dead band alone let one grunt flip four times (wall_given_up on the Record)"
  - "A due segment with no crowd near is published as never (MAX_TICKS), so a stale small time to destruction from a crowd that left cannot make a lone enemy break a strong wall"
  - "Detour and sealed tests read the castle field at a probe off the blocking wall: FlowField.cost_at on a blocked cell reads the cheapest open neighbour, which for a sealed ring is across the wall"
  - "Stuck progress is the castle field cost where it reaches the cell (needed improvement roundi(0.5 * 10 / 2) = 3), else centimetres to the castle (50); a unit change restarts the watermark. Queued enemies in a field can be flagged between cell crossings (plan Flagged Assumption, RESEARCH F5)"

patterns-established:
  - "WallDecision reads nothing but WallSystem and NavTuning; the field lives in Pathing (detour_ticks) so the decision never sees it"
  - "Anything read by the overlay and the gate test (stuck_ids, longest_streak_ticks, ttd_of, evaluated_count) is a getter on a RefCounted that emits nothing"

requirements-completed: [ENMY-04]

coverage:
  - id: D1
    description: "The integer arithmetic: damage_per_300(2, 30) is 20, ttd_ticks rounds up (450, 465) and is MAX_TICKS for a zero sum, walk_ticks(2000, 320) is 188, should_break is strict and always true for no detour, keep_breaking lets go only when the detour wins by more than the hysteresis, the two rules leave a dead band, 1,000,000 health against 1000 attackers is exact and saturates at MAX_TICKS"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_decision.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "Per-segment publication: five grunts aggroed onto segment s publish ttd 90 for a 30 hp segment across s-2 to s+2 of its run only, not the next run, evaluated only on (tick + s) % 15 == 0 and held in between, back to never when the crowd left"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_wall_decision.gd"
        status: pass
    human_judgment: false
  - id: D3
    description: "On an 80 m wall a crowd of 12 grunts breaks a tier I segment where it stands (10 of 12 cross within 1.2 m of z 0), a lone grunt at tier III crosses inside the gap (z 36 to 40) with no wall_damaged, a lone grunt attacks a weak wall when the gap is far, the sealed ring is still broken into, and no grunt switches between a wall target and none more than twice over seeds 1 to 3"
    requirement: ENMY-04
    verification:
      - kind: integration
        ref: "tests/integration/test_wall_behaviour.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "The six NavTuning numbers hold their shipped values, a fresh NavTuning reads like the data, and WallValidation reports a notice range of 0 or over 50, a negative or oversized span, a cadence or hysteresis outside one tick to 10 s (including NaN and INF), stuck seconds outside 0.5 to 60 and progress of 0 or over 10 m"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_nav_tuning_contract.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_map_nav_validation.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "StuckTracker: a held enemy with no target is flagged after exactly 90 updates and not at 89; one gaining 0.5 m every 2.5 s never; a targeted one resets; the dead are dropped; clear() empties everything; the longest streak is kept; field-cost progress counts a cell; update() emits none of SimSignals.ALL and changes no enemy position, health, previous position or target on a real night; a new night starts clean"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_stuck_tracker.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "Smoke, army and full_idle replay twice with unchanged digests: no intact segment exists on their maps, so the decision never runs, and the tracker emits and changes nothing"
    requirement: ENMY-04
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
  - id: D7
    description: "Whether enemies that weigh a wall against the walk round it read as smart to the player (a crowd chewing through a weak wall in front of it, a lone raider walking round a strong one)"
    verification: []
    human_judgment: true
    rationale: "The arithmetic and the behaviour contract are tested; whether the choice looks and feels right in play is the owner's call at the phase UAT"

duration: 50 min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 07: Smart Walls and the Stuck Tracker Summary

**Enemies now weigh breaking a wall against walking round it in integers (the whole crowd's damage against the detour through the castle field, judged per segment on a staggered 0.5 s cadence with hysteresis and a give-up memory), and a read-only StuckTracker flags enemies that make no progress while tolerating queues; smoke, army and full_idle replay byte-identical**

## Performance

- **Duration:** about 50 min
- **Started:** 2026-10-16T08:26Z (estimated from file times; no start stamp was captured)
- **Completed:** 2026-10-16T09:20Z
- **Tasks:** 2 (Task 1 the tracer; Task 2 as RED then GREEN)
- **Files modified:** 18 in the plan range (5 created sources and tests, 8 modified, 5 new `.uid` files)

## Accomplishments

- WallDecision (ENMY-04, D-07, D-08): `damage_per_300`, `ttd_ticks`, `walk_ticks`, `should_break` and `keep_breaking` are static integer functions with the exact rounding the plan lists; the instance publishes one time to destruction per segment. Segments are due on `(tick + segment) % 15` and are walked as a stride from `posmod(-tick, cadence)`, an attacker adds to its own segment and to the segments of the same run within the span that are due, and a due segment with nobody near goes back to MAX_TICKS.
- Enemy behaviour: a target-less marcher blocked by a segment within 12 m of its face records `wall_seg`; each step counts every aggroed enemy once in ascending id; on any tick it takes the segment when `ttd + straight < detour` (or when sealed), keeps it on its rescan ticks until the detour beats `ttd + straight` by more than 15 ticks, and never retakes a segment it gave up. On an 80 m wall a crowd of 12 grunts breaks a tier I segment at z of about 0 (10 of 12 cross within 1.2 m of it); a lone grunt at tier III walks to the gap at z 36 to 40 and hits no wall; the sealed ring is still broken into; nobody flips more than twice.
- StuckTracker (D-09): per-enemy watermark and streak, field-cost progress where the field reaches the cell and centimetres otherwise, a target resets, flagged at exactly 90 updates; `stuck_ids()`, `streak_of()`, `longest_streak_ticks()` for plan 04-08. It runs on every map from NightSim and changes nothing.
- NavTuning gained the six numbers (data and validation); `Pathing` gained `decision()`, `stuck()`, `detour_ticks()`, `straight_ticks()` and `castle_distance_cm()` (20 public methods, at the lint cap).

## Task Commits

1. **Task 1: Tracer, the break-or-go-around rule end to end** - `22f11b6` (feat)
2. **Task 2 RED: failing tests for the read-only stuck tracker** - `454eddb` (test)
3. **Task 2 GREEN: flag enemies that make no progress, read-only and queue tolerant** - `11d7110` (feat)

**Plan metadata:** committed after this file (docs: complete plan). No refactor commit was needed.

## Files Created/Modified

- `simulation/nav/wall_decision.gd` - the integer arithmetic and the per-segment publication (12 public)
- `simulation/nav/stuck_tracker.gd` - the read-only stall flags (8 public)
- `simulation/nav/pathing.gd` - owns both, `detour_ticks`, `straight_ticks`, `castle_distance_cm`, the wall probe behind `is_sealed` and the detour
- `simulation/night/enemy_system.gd` - Record `per_300`, `speed_cm`, `wall_seg`, `wall_given_up`; the decision pass, the take/keep/give-up logic (18 public, unchanged)
- `simulation/night/night_sim.gd` - tracker update after the enemy phase, clear per night
- `simulation/defs/nav_tuning.gd`, `data/tuning/nav_tuning.tres`, `simulation/walls/wall_validation.gd` - the six numbers and their ranges
- Tests: `test_wall_decision` (12), `test_wall_behaviour` (8), `test_stuck_tracker` (11), `test_nav_tuning_contract` (4 to 5), `test_map_nav_validation` (9 to 14)

## Decisions Made

See `key-decisions` above. Readings the plan leaves open, none a deviation:

- "Aggroed to a segment" counts the segment in the way of the enemy's line to the castle within the notice range, as the plan's Flagged Assumption says; a segment is evaluated when it is due and any enemy aggroed within the span of it counts, whether or not one is aggroed onto the segment itself.
- The take decision runs every tick for an aggroed marcher (sealed enemies took the wall every tick in 04-06); the release decision runs on the enemy's rescan tick.
- The long walls in the behaviour test are the gap fixture deep-copied with `duplicate_deep` and a lengthened run (the plan's -40 to 40 with the gap at 76 to 80 m), and the night is 12 grunts on one tick. No tower is built, so the crowd reaches the wall.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] A sealed enemy pressed into the wall was read as having a short route**
- **Found during:** Task 1 (test_wall_detour's ring case failed: wall_damaged but no wall_segment_broken)
- **Issue:** `FlowField.cost_at` on a blocked cell reads the cheapest open neighbour, which for a sealed ring is the open cell across the wall. Once the grunts were pressed against the ring, `detour_ticks` was a few dozen ticks, `keep_breaking` was false and they let go of the wall they had just started on.
- **Fix:** `Pathing._probe_of` steps a position in a blocked cell away from the segment that blocks it, a cell at a time (at most 3), onto its own side; `detour_ticks` and `is_sealed` read the field there (the step length is added to the detour). An open position reads where it stands.
- **Files modified:** `simulation/nav/pathing.gd`
- **Verification:** test_wall_detour 12 of 12 (the ring case), test_wall_behaviour's ring case, and the full suite.
- **Committed in:** `22f11b6`

**2. [Rule 2 - Missing critical] A hysteresis of 15 ticks alone did not stop a flip-flop**
- **Found during:** Task 1 (test_wall_behaviour: seed 1, grunt 12 switched wall, none, wall, none)
- **Issue:** When a neighbour segment broke and most of the crowd walked through the hole, the number of enemies counted near the remaining segment fell and rose again, so ttd moved by more than the dead band (68 then 30 ticks against a detour of 244) and the grunt gave a segment up and took it again 13 ticks later. The plan's must-have is that a crowd does not flip.
- **Fix:** `Record.wall_given_up`; an enemy that lets a segment go does not take that same segment again while a way round exists (a sealed enemy still does).
- **Files modified:** `simulation/night/enemy_system.gd`
- **Verification:** test_wall_behaviour's flip test over seeds 1 to 3 (it failed at 4 switches before the change).
- **Committed in:** `22f11b6`

**3. [Rule 3 - Blocking] The stuck tracker needs the straight distance in centimetres**
- **Found during:** Task 2
- **Issue:** The interface lists no way to read the straight distance to the castle in centimetres from `Pathing`, and StuckTracker is given the tuning and a cell size only.
- **Fix:** `Pathing.castle_distance_cm(pos)`; `straight_ticks` now calls it. Pathing is at 20 public methods, the lint cap.
- **Files modified:** `simulation/nav/pathing.gd`
- **Committed in:** `454eddb`

**4. [Test adaptation, not a code change] A lone grunt at tier I dies to the castle before it breaks the wall**
- **Found during:** Task 1 (test_wall_behaviour)
- **Issue:** The castle fires at 22 m and the wall is 20 m from it; a 6 hp grunt dies in about 4.5 s, the wall needs 15 s of one grunt. The decision does choose to attack (the point of the test); it cannot finish.
- **Fix:** The test asserts that the lone grunt attacks the weak wall (a `wall_damaged`) and not that it crosses.
- **Files modified:** `tests/integration/test_wall_behaviour.gd`

---

**Total deviations:** 4 (1 bug, 1 missing critical, 1 blocking, 1 test adaptation)
**Impact on plan:** The first two are behaviour the plan's own tests (the sealed ring and "does not flip-flop") would have caught; the third is one accessor. No scope creep.

## Issues Encountered

- GutTest already has a `_pass` method, so the decision-pass helper in test_wall_decision is `_decide`.
- The first stuck-field test assumed a move along the wall lowers the field cost; the cost at (-25, 0) and (-25, 4) is the same 114. The test now moves the enemy 4 m toward the wall.
- Several files had CRLF endings; `gdformat` normalises them, so diffs stay LF.
- The assert total varies between full runs (25440 after Task 1, 26510 after Task 2), e2e tests loop on frame conditions; the test count only grows.

## Verification (final state, HEAD 11d7110)

- `bash tools/test.sh`: 183 scripts, 1705 tests, 26510 asserts, exit 0 (baseline at dispatch 180 scripts, 1668 tests; +3 scripts, +37 tests). After Task 1 alone: 182 scripts, 1694 tests, 25440 asserts. `test_wall_decision`, `test_wall_behaviour`, `test_stuck_tracker`, `test_nav_tuning_contract`, `test_map_nav_validation`, `test_wall_detour`, `test_wall_determinism`, `test_wall_tracer_scene` and `test_debug_overlay_readonly` are in the JUnit XML.
- `bash tools/replay.sh`: smoke `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks), army `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks) REPLAY_OK against their goldens, full_idle `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` (6941 ticks) twice; run after Task 1 and again after Task 2; no golden touched.
- `bash tools/lint.sh`: clean (320 files). Public methods: Pathing 20, EnemySystem 18 (unchanged), WallDecision 12, StuckTracker 8.
- Tracer gate: the Task 1 verify (full suite, JUnit names, the three replays, lint) was run end to end on the tree that was committed; "Tracer verified end-to-end, expanding".

## TDD Gate Compliance

Task 2 (`tdd="true"`): RED `454eddb`, GREEN `11d7110`; no refactor commit. RED evidence was built from the JUnit XML of `bash tools/test.sh -gselect=test_stuck_tracker` (exit 1) and verified with `gsd-tools check tdd-red-evidence`: `RED_EVIDENCE_OK`, target test `test_an_enemy_held_in_place_is_flagged_after_exactly_ninety_updates` failing on its assertion (8 of 11 failed, 3 pass by design: the unknown id, the creeping enemy and the targeted enemy are never flagged by a stub either). The RED commit carries a stub StuckTracker and the real `Pathing.stuck()` and `castle_distance_cm` so the tests parse and fail on assertions. GREEN made all 11 pass and the full suite stayed green.

## Known Stubs

None. The RED-commit stub was replaced in GREEN.

## Threat Flags

None. No new network, auth or file surface. T-04-17 (64-bit arithmetic, MAX_TICKS for a zero sum, an unreached detour or a non-positive speed, sums clamped before comparison, tunables validated, the 1,000,000 health and 1000 attacker case pinned), T-04-18 (one pass over the aggroed enemies and a stride over the due segments, the span validated at most 10) and T-04-19 (the tracker emits nothing and writes nothing, pinned by test; goldens unchanged) are mitigated as planned.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 04-08 reads `Pathing.stuck()` (`stuck_ids()`, `streak_of()`, `longest_streak_ticks()`, `stuck_count()`) and `Pathing.decision()` (`ttd_of()`, `evaluated_count()`) for the overlay and the gate stress; none of them emits or writes.
- A queue in a field can flag healthy enemies between cell crossings (a cell is 2 m, the needed improvement 3 cost units), as the plan's Flagged Assumption says; the gate passes on "everyone crosses before T_max and none is flagged at the end".
- ENMY-04 stays open in REQUIREMENTS.md until plan 04-08 (which also declares it) finishes.
- Open for the verifier (D7): the owner judges at the UAT whether the wall choices look smart in play. The one new rule beyond the plan, that an enemy never retakes a segment it gave up, is in `key-decisions` for the owner to veto.

## Self-Check: PASSED

- Created files exist: wall_decision.gd, stuck_tracker.gd, test_wall_decision.gd, test_stuck_tracker.gd, test_wall_behaviour.gd, each with its `.uid`.
- Commits `22f11b6`, `454eddb` and `11d7110` are in `git log`; `git rev-list --count 87ab0b3..HEAD` was 3 before this file.
- Acceptance criteria re-run: `class_name WallDecision`, `static func ttd_ticks(`, `static func should_break(`, `static func keep_breaking(`; `should_break(` and `add_attacker(` in enemy_system.gd; `wall_decision_seconds = 0.5` and `wall_neighbour_span = 2` in nav_tuning.tres; `class_name StuckTracker`, `func update(`, `func longest_streak_ticks(`; `stuck().update(` and `stuck().clear()` in night_sim.gd; the three replays with unchanged digests.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
