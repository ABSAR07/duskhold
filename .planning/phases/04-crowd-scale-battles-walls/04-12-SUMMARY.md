---
phase: 04-crowd-scale-battles-walls
plan: 12
subsystem: simulation
tags: [godot, gdscript, enemy-ai, walls, target-choice, determinism, gap-closure]
gap_closure: true
gap_ids: [G-04-7]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: "plans 04-06 and 04-07: the line-of-sight gates and the break-or-detour rule this plan amends; 04-10: the balance pins and the with-walls sweep it re-measures"
provides:
  - "EnemyDef.drops_blocked_targets (default false): the per-type opt-out of the new rule for the Phase 6 roster"
  - "A default melee enemy breaks the segment in front of a king, unit or building target behind a wall, keeps it until it breaks and resumes the target"
  - "StructureIndex.nearest_through_walls: nearest unit or building ignoring walls, castle excluded"
  - "Record.behind_kind / behind_id and the private EnemySystem._breaks_to_targets and _release_held_wall"
  - "Three new test scripts and a migrated test_los_targets; dated amendments in four planning documents"
affects: [04-14 to 04-23 (the GDExtension port ports the enemy step as left here), phase-06 enemy roster]

actuals:
  tokens: 13700
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Held-for-target wall: the target a segment stands in front of lives on the record (behind_kind/behind_id), is swapped in to reuse _target_valid and _goal_of for the release test, and is put back when the segment breaks"
    - "Radius-0 centre-line test for the default melee rule (a body that only grazes a gap edge is clear); ranged and flagged records keep def.radius"

key-files:
  created:
    - tests/unit/test_enemy_wall_flags_contract.gd
    - tests/integration/test_wall_break_to_target.gd
    - tests/unit/test_melee_breaks_to_target.gd
  modified:
    - simulation/defs/enemy_def.gd
    - simulation/night/enemy_system.gd
    - simulation/night/structure_index.gd
    - tests/unit/test_los_targets.gd
    - .planning/phases/04-crowd-scale-battles-walls/04-BALANCE-REPORT.md
    - .planning/phases/04-crowd-scale-battles-walls/04-PLAYTEST-GATE.md
    - .planning/phases/04-crowd-scale-battles-walls/04-RESEARCH.md
    - .planning/phases/04-crowd-scale-battles-walls/04-07-PLAN.md

key-decisions:
  - "The release test swaps the behind target into target_kind/target_id and calls the existing _target_valid and _goal_of instead of refactoring them to take a kind and an id; no existing call changed, EnemySystem stays at 18 public methods and 795 lines"
  - "StructureIndex._scan gained a skip_castle argument rather than a second scan, so nearest_through_walls shares the shipped candidate order and test; nearest and nearest_visible pass false"
  - "A jostled held grunt may move to the segment its centre line now crosses on a rescan (release, then retake); what is pinned is that it is never left without a wall while its segment and its target stand"

patterns-established:
  - "Every new wall branch of the night step sits behind _walls_are_solid(), so scenarios with no intact segment (smoke, army) cannot reach it"

requirements-completed: [ENMY-04]

duration: 52min
completed: 2026-10-19
status: complete
plan_head_before: 820a2e178c50abbf98baa455b35c7367633df8d8
plan_head_after: d9b6dc03b4c48a0318e047fc290a1cf774ca8d9d
commits: 3

coverage:
  - id: D1
    description: "A default melee enemy whose tower, unit or king is behind an intact wall breaks the segment its centre line crosses and then resumes the target (G-04-7 closed)"
    requirement: ENMY-04
    verification:
      - kind: integration
        ref: "tests/integration/test_wall_break_to_target.gd#test_a_grunt_breaks_the_wall_in_front_of_a_tower_then_damages_the_tower"
        status: pass
      - kind: unit
        ref: "tests/unit/test_melee_breaks_to_target.gd (king, unit and held-target cases 1 to 3)"
        status: pass
    human_judgment: true
    rationale: "Whether chewing through a wall toward a target feels right in play is the owner's feel check; the UAT test 13 re-test is the owner's"
  - id: D2
    description: "The three sub-rules (visible first, gap mouth, castle never behind a wall) and the release rules (death, leash, cleared line, no give-up flip) are pinned"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_melee_breaks_to_target.gd#cases 4 to 10"
        status: pass
    human_judgment: false
  - id: D3
    description: "EnemyDef.drops_blocked_targets defaults to false, no shipped or fixture resource sets it, and a flagged grunt keeps every old 04-06 assertion"
    requirement: ENMY-04
    verification:
      - kind: unit
        ref: "tests/unit/test_enemy_wall_flags_contract.gd; tests/unit/test_los_targets.gd (flagged copies)"
        status: pass
    human_judgment: false
  - id: D4
    description: "smoke 2599c7c2, army f7a967ed, walls bfb05fc7, full_idle 4385f569 and the gate digest e448ffdb are byte-identical; test_balance_acceptance holds"
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke|army|walls --twice --expect-file; --scenario=full_idle --twice; bash tools/gate_stress.sh --twice; bash tools/test.sh -gselect=test_balance_acceptance"
        status: pass
    human_judgment: false
---

# Phase 4 Plan 12: Melee enemies break through walls to their target Summary

**A default melee enemy now breaks the wall segment in front of a king, unit or building it has chosen or holds, remembers the target through the break and resumes it; EnemyDef.drops_blocked_targets keeps the old castle-first rule for the Phase 6 roster, and no replay, gate or balance pin moved.**

## Performance

- **Duration:** 52 min
- **Started:** 2026-10-19T08:15:05Z
- **Completed:** 2026-10-19T09:07Z
- **Tasks:** 3 (Task 1 tracer, Task 2, Task 3)
- **Files modified:** 14 (4 simulation and test sources changed, 3 test scripts added with their .uid files, 4 planning documents amended)

## Accomplishments

- G-04-7 closed (owner rule change of 2026-10-19, UAT test 13). In the diagnosis repro shape (run at x = 102, tower behind it, shipped grunt in front) the grunt takes the segment its centre line crosses on its first step, breaks it, gets the tower back the step after the break and damages it; it is never without a target and never marches on the castle.
- The three sub-rules the plan settled are one test each: a target in sight still wins over a nearer one behind a wall; a body that only grazes a gap's edge walks through the gap and damages no segment over 300 steps; the castle is never a target behind a wall and the sealed ring is still attacked by the 04-07 castle rule with behind_kind never set.
- The release rules are pinned: the segment is let go when the unit behind it dies, when the king leaves the leash, and on a rescan tick when the centre line no longer crosses it (the target comes back); a crowd of 12 holding weak segments for a tower never flips to a detour and its holders count into the segment's crowd (D-08).
- Ranged enemies and flagged enemies keep every 04-06 gate unchanged: test_los_targets runs its drop assertions on a `drops_blocked_targets = true` copy of the grunt, word for word, and the "nearer unit behind loses to a farther one in sight" test stays on the default grunt.
- Every pin held: smoke, army, walls and full_idle digests byte-identical, GATE_OK digest e448ffdb, test_balance_acceptance 15/15 with constants unedited. The bot re-measure moved one run of 20 (balanced seed 2, night 8, exactly the run the diagnosis predicted), with outcome and nights survived unchanged.

## Task Commits

1. **Task 1: Tracer, a grunt chooses a tower behind a wall, breaks the segment, then attacks the tower** - `56d68ad` (feat)
2. **Task 2: The king, units and held targets break through too; sub-rules and releases pinned; old assertions moved onto a flagged grunt** - `489ebd3` (feat)
3. **Task 3: Re-measure the bots and amend the docs that state the old rule** - `d9b6dc0` (docs)

**Plan metadata:** the docs(04-12) close-out commit that carries this SUMMARY, STATE.md and ROADMAP.md.

_TDD note: tdd="true" on Tasks 1 and 2 with one commit per task as the plan and execute-plan.md specify, so there is no separate test(04-12) RED commit. RED was observed and is recorded below._

## RED evidence (Tasks 1 and 2)

- **Task 1, on the 820a2e1 code.** test_wall_break_to_target failed on the plan's assertions: `DICTIONARY({  }) != DICTIONARY({ "kind": &"wall", "id": 7 })` (the tower was dropped, the grunt target was empty and it marched on the castle) and "never without a target" on every step. test_enemy_wall_flags_contract failed only on the missing field (`[<null>] expected to equal [false]`; the flag is read with `get()` so the RED is an assertion, not a parse error). The unbuilt-run test and the file-scan tests passed, as they should.
- **Task 2, on the Task 1 code.** test_melee_breaks_to_target ran 10 tests, 5 failing: case 1 (the king did not pull the grunt through his wall: target empty), case 2 (a held king who walks behind the wall was dropped on a rescan), cases 8 and 9 (nothing was held for the king, so there was no release to test) and case 10 (a jostled crowd member lost its target when the rescan in-sight test dropped the held tower). Cases 3 to 7 already passed because Task 1 had built the unit and building pick, the gap-mouth radius and the death release. The plan expected cases 1, 2 and 7 to 9 red; case 7 was already green after Task 1, and case 10 turned red instead of 7.
- **GREEN:** after the king-pull and held-target sight changes all 10 tests pass; the full suite is green.

## Files Created/Modified

- `simulation/defs/enemy_def.gd` - `drops_blocked_targets` (default false) beside `ignores_walls`, documented as the Phase 6 hook.
- `simulation/night/enemy_system.gd` - `Record.behind_kind/behind_id`; private `_breaks_to_targets` and `_release_held_wall`; the radius-0 line test and the held-for-target take in `_target_walls_in_the_way`; the king pull and the rescan sight test skip the line for a default melee enemy (the castle keeps a radius-0 test); `_pick_nearest_structure` asks `nearest_visible` (radius 0) then `nearest_through_walls`; doc blocks rewritten to state the rule per kind of enemy.
- `simulation/night/structure_index.gd` - `nearest_through_walls(pos, aggro_range)` and a `skip_castle` argument on `_scan`.
- `tests/unit/test_enemy_wall_flags_contract.gd` (5 tests), `tests/integration/test_wall_break_to_target.gd` (2), `tests/unit/test_melee_breaks_to_target.gd` (10) - new.
- `tests/unit/test_los_targets.gd` - the king-behind-the-wall and held-target-dropped tests run on a flagged copy of the grunt and are renamed accordingly.
- The four planning documents carry dated amendments naming UAT test 13, G-04-7 and plan 04-12.

## Results

- **Full suite (own run, `bash tools/test.sh`):** 193 scripts, 1811 tests, 30150 asserts, all passing, exit 0 (baseline 190, 1794, 27554: +3 scripts, +17 tests = 5 + 2 + 10). Lint clean (337 files).
- **Replays:** smoke `2599c7c250f4...` 703 ticks, army `f7a967edc680...` 1353, walls `bfb05fc7e4c7...` 1961, each REPLAY_OK against its golden, and full_idle `4385f569c3e0...` 6911 twice. `GATE_OK enemies=300 crossed=300 stuck=0 ... wall_hits=0 digest=e448ffdbd4d1...`. All verified after the Task 1 final code and again after Task 2.
- **enemy_system.gd:** 710 to 795 lines, still 16 public methods by count (cap 20) and under 1000 lines; two new private helpers. StructureIndex gained one public method.
- **Bot re-measure** (`balanced,army_balanced`, seeds 1 to 10, before and after, compared by a `python -I` script): 19 of 20 runs identical; army_balanced fully identical. Balanced seed 2 changed in night 8 only: buildings lost 9 to 8, tower kills 123 to 125, night 8 kills by king 9 to 10, by towers 28 to 30, by castle 3 to 0, buildings lost 3 to 2, night length 40.7 to 34.4 s; outcome (won), nights survived (8), kills (194) and walls broken (0) unchanged. Summary rows refreshed in 04-BALANCE-REPORT.md (balanced buildings lost 10.9 to 10.8; tower kills 107.50 to 107.70 and per tower gold 6.89 to 6.90; the night 8 row of the balanced with-walls table). test_balance_acceptance 15/15, constants unedited.

## Decisions Made

- The release rule is written against the existing helpers: it swaps the behind target into the record's target fields, asks `_target_valid` and `_goal_of`, and swaps the wall back if nothing releases. The plan suggested refactoring those helpers to take a kind and an id "where that avoids duplicating"; this avoids duplication with no change to any existing call, which matters because the GDExtension plans 04-14 to 04-23 port this step.
- `StructureIndex._scan` takes a `skip_castle` argument (false for `nearest` and `nearest_visible`) so `nearest_through_walls` shares the shipped candidate order and test.
- `_release_held_wall` runs whenever `behind_kind` is set, not only while walls are solid, so the target survives the last intact segment falling.

## Deviations from Plan

### Adjusted by the executor

**1. [Rule 1 - test geometry] The tracer and the unit worlds run their line at z = 101, not z = 100**
- **Found during:** Task 1 (test design)
- **Issue:** the plan's repro puts the line at z = 100, which is exactly the joint of segments 6 and 7 (z 80 to 120 in 14 pieces). After segment 6 breaks, segment 7's end point still lies on the centre line, so the grunt would have to break a second segment and "the step after the break its target is the tower" could not be asserted.
- **Fix:** grunt, tower, unit and king positions in the new tests use z = 101 (middle of segment 7). The tower stays at x = 105 and the run at x = 102, so the shape is the diagnosis repro.
- **Files modified:** tests/integration/test_wall_break_to_target.gd, tests/unit/test_melee_breaks_to_target.gd
- **Committed in:** 56d68ad, 489ebd3

**2. [Rule 1 - plan wording vs release rule] Case 10 asserts "never left without a wall" instead of "target never changes"**
- **Found during:** Task 2 (case 10)
- **Issue:** the plan's behaviour line says a held grunt's target never changes until the segment breaks, but the plan's own release rule lets a held grunt hand over to the segment its centre line now crosses on a rescan, and 12 jostling grunts do move across segment joints. The first probe showed no flip to a detour; the "failures" were a jostled grunt changing segment id and, later, the tower legitimately falling (every holder is released, as T-04-31 requires).
- **Fix:** the test tracks each grunt's latest held segment and asserts its target kind is a wall on every step until that segment breaks or the tower falls, and that the crowd count (D-08) shrinks the segment's time to destruction below the lone-attacker 450 ticks. The no-give-up-flip intent is fully covered.
- **Files modified:** tests/unit/test_melee_breaks_to_target.gd
- **Committed in:** 489ebd3

**Total deviations:** 2 (both test-design adjustments, Rule 1). **Impact on plan:** none on the simulation code or any pin.

## Issues Encountered

- `bash tools/lint.sh --fix` (gdformat) rewrites files with CRLF endings on this machine; an `sed -i 's/\r$//'` over a whole directory also flipped about 48 untouched files to CRLF-only "modified". They had empty content diffs; I restored them with `git checkout --` after confirming `git diff --numstat` showed no real change in any of them, and normalised line endings only on the files this plan owns afterwards.
- One crowd probe (scratch only) confirmed that a fallen tower, not a flip, ended the first failing case 10 run.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path, file access or schema at a trust boundary. T-04-30 (digest drift), T-04-31 (a held segment never released, now pinned by the death, leash, break and cleared-line tests) and T-04-32 (the flag set by data, now guarded by test_enemy_wall_flags_contract) are mitigated as planned.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The enemy step the GDExtension plans (04-14 to 04-23) will port is now final for this gap: the held-for-target memory (`behind_kind`, `behind_id`), `_breaks_to_targets`, `_release_held_wall`, the radius-0 line tests and `StructureIndex.nearest_through_walls` are the new behaviour to port; the tests above are its parity target.
- The owner re-test of UAT test 13 (a grunt chewing a wall toward a tower, the king pulling enemies through his wall, gap mouths still walkable) is a feel check for the next gate; the wall-break rebuild hitch (UAT test 10) is untouched by design.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-19*

## Self-Check: PASSED

- Files created exist: tests/unit/test_enemy_wall_flags_contract.gd, tests/integration/test_wall_break_to_target.gd, tests/unit/test_melee_breaks_to_target.gd (and their .uid files).
- Commits exist: 56d68ad, 489ebd3, d9b6dc0.
- All task acceptance criteria re-run: `drops_blocked_targets` field, `nearest_through_walls`, `behind_kind`, `_release_held_wall` present; the three new suites and the wall suites are in the JUnit XML; replays, gate and balance pins hold; enemy_system.gd 795 lines.
