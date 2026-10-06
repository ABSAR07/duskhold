---
phase: 02-night-defense-playtest-gate
plan: 15
subsystem: simulation
tags: [godot, castle-attack, night-sim, projectile-vfx, balance-report, gap-closure, g-02-1]
status: complete

requires:
  - phase: 02-night-defense-playtest-gate
    provides: 02-12 base dawn income (MapConfig fields and validate rules this plan builds on), 02-05 tower system (TowerSystem, PendingHits, SimClock.flight_ticks, ProjectileVfx), the owner UAT finding G-02-1 point 2 and its diagnosis in .planning/debug/playtest-economy-castle-speed-difficulty.md
provides:
  - CastleAttack (simulation/night/castle_attack.gd), stepped by NightSim after the towers and before the enemies; damage 2, reach 11 m, one shot per 1.5 s, arrows at 18 m/s on the shipped map; off (every field 0) everywhere else
  - MapConfig castle_attack_damage, castle_attack_range, castle_attack_interval, castle_projectile_speed with validate() rules (negative values; an attacking castle with no range or interval)
  - Gold castle arrows from the top of the keep in ProjectileVfx (CASTLE_LAUNCH_HEIGHT)
  - kills_castle per night in ReplayDriver.Tally and a Kills castle column in the balance report
affects: [02-16 difficulty re-measurement, phase-2-verification, playtest-gate]

requirements-completed: [KING-03, LOOP-03]

actuals:
  tokens: 9600
  tasks: 2
  commits: 4

plan_head_before: b634f053897c81b598192564ad369d07af02e3ec
plan_head_after: 8c0362783c0fe6593a27f175415700068bc79b21

tech-stack:
  added: []
  patterns:
    - "A new attacker mirrors TowerSystem: one ready tick, TargetQuery.nearest_enemy, SimClock.flight_ticks, a PendingHits entry with the attacker kind and id, one attack_fired event; it is armed only when every number it needs is above 0"
    - "Tooling learns a new attacker kind before the simulation uses it (presentation and tally first, then the switch-on)"

key-files:
  created:
    - simulation/night/castle_attack.gd
    - simulation/night/castle_attack.gd.uid
    - tests/unit/test_castle_attack.gd
    - tests/unit/test_castle_attack.gd.uid
    - tests/unit/test_map_validate_castle.gd
    - tests/unit/test_map_validate_castle.gd.uid
  modified:
    - simulation/defs/map_config.gd
    - simulation/night/night_sim.gd
    - data/maps/prototype_map.tres
    - presentation/vfx/projectile_vfx.gd
    - tools/replay/replay_driver.gd
    - tools/replay/balance_report.gd
    - tests/e2e/test_projectiles_visible.gd
    - tests/integration/test_balance_report.gd
    - tests/unit/test_building_damage.gd

key-decisions:
  - "The castle is a one-attacker system with attacker id 0 and PendingHits.KIND_CASTLE; EnemySystem is unchanged because NightSim._resolve_hits already passes the attacker kind, so a castle kill reaches enemy_died with killer_kind castle"
  - "Armed only when damage, range and interval are all above 0, so bad data can never make it fire every tick; validate() reports a negative number once (as negative) and a zero range or interval only for a castle that attacks"
  - "CASTLE_LAUNCH_HEIGHT is KEEP_SIZE.y + TURRET_HEIGHT (8 m): the arrow leaves the top of the keep with its turret, derived from BuildingViews so a model change points at it"
  - "The shipped-data castle contract test lives in test_map_validate_castle.gd, not test_prototype_map_data.gd, because that file already holds gdlint's 20 public methods (same move 02-12 made)"

duration: 32 min
completed: 2026-10-06
---

# Phase 2 Plan 15: Castle attack Summary

**The castle now shoots the nearest enemy within 11 m every 1.5 s for 2 damage (three hits kill a grunt, two a skirmisher, and it reaches a skirmisher at its 10.5 m stand-off), drawn as a gold arrow from the keep top and counted in a Kills castle column of the balance report (G-02-1 point 2).**

## Performance

- **Duration:** 32 min (2026-10-06T13:14:29Z to 2026-10-06T13:46Z, approximately)
- **Tasks:** 2 (both TDD)
- **Files:** 15 (9 modified, 6 created)
- **Tests:** 787 after Task 1, 810 after Task 2 (baseline 784); lint clean; smoke digest unchanged

## Accomplishments

- Task 1: ProjectileVfx draws an arrow for the castle as an attacker (TOWER_COLOR gold mesh, launched from the castle position raised by CASTLE_LAUNCH_HEIGHT, capped by MAX_PROJECTILES like every arrow); ReplayDriver.Tally counts `PendingHits.KIND_CASTLE` kills in `kills_castle` of the open night; BalanceReport shows a Kills castle column after Kills towers, and king + tower + castle kills equal the night's `enemy_died` lines.
- Task 2: `CastleAttack` copies TowerSystem.step with the castle as the one attacker; NightSim builds it from the map and castle it holds, calls `begin_night()` with the other systems and steps it right after the towers and before the enemies (class doc order: spawn, king, towers, castle, enemies, hits, dead). MapConfig gets the four fields (default 0 = off) and `_validate_castle_attack()` (no new public method). The shipped prototype map sets 2, 11.0, 1.5, 18.0; nothing else on it changed.
- Behaviour pinned by 14 hand-built and NightSim tests (tick-0 shot and flight, 45-tick cadence, no cooldown spent without a target, exact 11.0 m in and 11.01 m out, id and distance ordering, 3 and 2 hit kills with killer kind castle, destroyed or unarmed castle silent, begin_night reset, step order building then castle then enemy) and 9 validate and shipped-contract tests.

## Task Commits

1. **Task 1 RED:** `2bebb32` - test(02-15): add failing tests for castle arrows and castle kills in the balance report
2. **Task 1 GREEN:** `c295f2f` - feat(02-15): draw castle arrows from the keep and count castle kills in the balance report
3. **Task 2 RED:** `55c6657` - test(02-15): add failing tests for the castle attack
4. **Task 2 GREEN:** `8c03627` - feat(02-15): the castle shoots the nearest enemy in reach, three shots per grunt and two per skirmisher

## TDD Gate Compliance

- Task 1 RED: the castle arrow test failed on `[0] expected to equal [1]: one projectile for one castle shot`; the balance tests failed on `night has kills_castle`, the missing `Kills castle` column and the pipe counts (4 failing tests, 14 passing). Genuine assertion failures, no parse errors (the test derives the keep top from `BuildingViews` instead of naming the not-yet-existing constant).
- Task 2 RED: the RED commit carries a behaviour-free `CastleAttack` skeleton (is_armed false, step does nothing) and the four MapConfig fields so the new tests fail on assertions rather than on a parse error for an unknown class or property: 11 of 14 castle-attack tests and 7 of 9 validate tests failed on the planned assertions (for example `ARRAY([]) != ARRAY([[&"castle", 0, &"enemy", 1, 10]])`, `a negative damage reports exactly one error: []`, `the shipped castle attacks`).
- GREEN: both tasks pass the full suite. REFACTOR: none needed.

## Mutation probes

- Task 1: dropping `KIND_CASTLE` from `_draws_arrows` in projectile_vfx.gd made `test_a_castle_shot_flies_as_a_gold_arrow_from_the_keep` fail (`[0] expected to equal [1]: one projectile for one castle shot`), 7 of 8 passing. Restored (3 `KIND_CASTLE` mentions again), all pass.
- Task 2 probe A: removing `or _castle.is_destroyed()` from `CastleAttack.step` made `test_a_destroyed_castle_fires_nothing` fail (`[2] expected to equal [0]: a fallen castle does not shoot`), 13 of 14 passing. Restored.
- Task 2 probe B: moving `_castle_attack.step` after `_enemies.step` in `NightSim.step` made the order test fail (`[building, enemy, castle] != [building, castle, enemy]`), 13 of 14 passing. Restored (diff against the pre-probe copy empty).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Shipped castle contract test moved out of test_prototype_map_data.gd**
- **Found during:** Task 2 (RED)
- **Issue:** `test_prototype_map_data.gd` already holds gdlint's 20 public methods, so adding `test_the_castle_kills_a_grunt_in_three_shots_and_a_skirmisher_in_two_and_reaches_a_skirmisher` there would break `max-public-methods` (the same situation 02-12 met).
- **Fix:** The test lives in the new `tests/unit/test_map_validate_castle.gd` as `test_the_castle_kills_a_grunt_in_three_shots_and_a_skirmisher_in_two_and_reaches_one`, with all the planned assertions (ceil(6 / 2) is 3, ceil(4 / 2) is 2, range at least castle_radius + skirmisher attack_range + 0.25, interval 1.5, speed above 0, grunt max_health stays 6). `test_prototype_map_data.gd` is untouched, so its frontmatter entry in the plan is not modified.
- **Files modified:** tests/unit/test_map_validate_castle.gd
- **Commit:** 55c6657

**2. [Rule 3 - Blocking] NightSim ordering test builds NightSim directly**
- **Found during:** Task 2 (RED)
- **Issue:** The plan suggested a RunContext over a fixture copy; a hand-built NightSim over a `MapConfig.new()` with one tower spot gives the same coverage (tower, castle and a skirmisher that all act on night tick 0) with less setup and no fixture dependency.
- **Fix:** `test_a_tower_and_the_castle_fire_before_any_enemy_in_that_order_through_night_sim` builds the map, BuildingSystem, KingState and CastleState by hand and steps `NightSim.step(0)`.
- **Files modified:** tests/unit/test_castle_attack.gd
- **Commit:** 55c6657

**3. [Rule 1 - Bug (test setup)] The full_idle digest did not change**
- **Found during:** Task 2 step 7
- **Issue:** The plan expected the full_idle digest and ticks to change. They did not: `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435`, identical to the post-02-13 value. The log has 407 `attack_fired` lines and none from the castle: the balanced bot's defence kills every enemy before one comes within 11 m of the castle centre, so the castle never fires and the run is unchanged.
- **Fix:** None needed, and none made. Confirmed the castle works on the shipped data with `bash tools/playtest.sh --strategies=no_build,balanced --seeds=3 --out=build/pt02_15`: no_build night 1 shows Kills castle 3.0 (and still loses night 1 in all 3 seeds), balanced wins 3/3 with Kills castle 0.0 on every night. The two full_idle runs in the double run agree, and no golden file changed.
- **Files modified:** none
- **Commit:** n/a

**4. [Plan step 6a] One shipped-copy test switched the castle attack off**
- **Found during:** Task 2 full-suite run
- **Test:** `tests/unit/test_building_damage.gd`, `_swarm_a_house` (used by `test_two_strikes_on_one_tick_destroy_the_house_once`): it spawns grunts in a ring around House A within the castle's 11 m reach, and the castle shot one of them before it struck (`attack_fired` count 9 instead of 8).
- **Fix:** The deep copy sets castle_attack_damage, range, interval and projectile speed to 0 with the comment "The subject is the swarm on the House, so the castle must not shoot one of the grunts (02-15)." Subject unrelated to the castle, so kind (a) of the plan; no design-contract test needed switching (test_king_sturdiness, test_every_night_ends, test_prototype_nights, test_night_data_contract and the balance report checks all passed unchanged).
- **Files modified:** tests/unit/test_building_damage.gd
- **Commit:** 8c03627

**Total deviations:** 4 (2 Rule 3, 1 Rule 1 note, 1 planned test switch-off). **Impact:** none on scope; the shipped balance is untouched apart from the new castle attack.

## Replays

- Smoke: `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` against `tests/golden/smoke.json`, unchanged.
- Full idle (both runs agree): `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435` (unchanged from 02-13, see deviation 3).

## Tests that switched the castle attack off

Only `tests/unit/test_building_damage.gd` (`_swarm_a_house`), reason in deviation 4.

## Issues Encountered

None open. For 02-16: the balanced bot never lets an enemy within the castle's reach, so the castle attack does not move the balanced results at all; it only helps weak or idle play (no_build now kills 3 of the 5 night-1 enemies with the castle but still loses night 1).

## Known Stubs

None.

## Threat Flags

None. T-02-33 (data to simulation) is mitigated by the validate rules and the armed check; T-02-34 by the destroyed check, the NightSim-only step, begin_night and the determinism guard scanning the new file (test_sim_rules_guard passes).

## Verification

- `bash tools/test.sh`: 810 tests, 810 passing (baseline 784 plus 3 in Task 1 and 23 in Task 2); test_castle_attack, test_map_validate_castle, test_projectiles_visible, test_balance_report, test_projectile_vfx, test_prototype_map_data, test_sim_rules_guard and test_determinism are all in the JUnit XML.
- `bash tools/lint.sh`: clean (162 first-party files plus the new ones).
- Acceptance: `CASTLE_LAUNCH_HEIGHT` and `PendingHits.KIND_CASTLE` in projectile_vfx.gd, `kills_castle` in replay_driver.gd, `Kills castle` in balance_report.gd, `class_name CastleAttack`, `PendingHits.KIND_CASTLE` and `TargetQuery.nearest_enemy` in castle_attack.gd, `CastleAttack.new(` and `_castle_attack.step(` in night_sim.gd, the four castle values in prototype_map.tres, and `max_health = 6` still in grunt.tres.
- Prohibitions held: no change to grunt or skirmisher health, tower numbers, castle_max_health or any night composition; tests/golden/smoke.json and tests/fixtures untouched.

## Next Phase Readiness

Ready for 02-16 (re-measure difficulty with base income, sprint and the castle attack in place).

## Self-Check: PASSED

- Created files exist: castle_attack.gd (+uid), test_castle_attack.gd (+uid), test_map_validate_castle.gd (+uid) all appear in `git diff --stat` of the plan range.
- Commits exist: 2bebb32, c295f2f, 55c6657, 8c03627 (`git log b634f05..HEAD`, count 4 matching `plan_head_before` and `commits: 4`).
