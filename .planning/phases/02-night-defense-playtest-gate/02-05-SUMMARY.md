---
phase: 02-night-defense-playtest-gate
plan: 05
subsystem: simulation
tags: [godot, gdscript, towers, ranged-enemy, projectiles, vfx, king-03, bldg-07, gut]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: PendingHits (decide-then-resolve queue), TargetQuery.nearest_enemy, building health and standing_spot_ids, BuildingTierDef attack_interval and projectile_speed, EnemyDef.projectile_speed, HealthBar3D, attack_fired with a flight_ticks argument (plans 02-01 to 02-04)
provides:
  - SimClock.flight_ticks, the whole-tick flight time of a projectile (0 for a melee hit)
  - TowerSystem: every standing tower shoots the nearest enemy in range on a per-spot cooldown, hits land flight_ticks later on the enemy's id
  - A second enemy type, the Skirmisher (ranged.tres), that stops at its attack_range and shoots on the same targeting rules, joining the prototype nights from night 4 with per-night totals unchanged
  - ProjectileVfx (arrows for tower and skirmisher shots, a slash for the king's passive strike) and richer EnemyViews (per-type colour and silhouette, hurt-only bar, hit flash, death puff)
affects: [02-06, 02-07, 02-09, 02-10, 02-11]

actuals:
  tokens: 19500
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Every attack goes through the pending-hit queue with an arrival tick of tick + SimClock.flight_ticks(distance, speed); melee is the same path with a speed of 0 and an arrival of this tick"
    - "A cosmetic projectile follows its target's current position over exactly the simulation's flight time and finishes at the last known position when the target is gone; the simulation already decided the hit by id"
    - "Presentation nodes expose read-only test hooks (live_count, slash_count, puff_count) and cap their own node growth"
    - "Each enemy puppet owns its material so a hit flash never lights up the rest of its type"

key-files:
  created:
    - simulation/night/tower_system.gd
    - data/enemies/ranged.tres
    - presentation/vfx/projectile_vfx.gd
    - tests/unit/test_tower_combat.gd
    - tests/unit/test_ranged_enemy.gd
    - tests/unit/test_projectile_vfx.gd
    - tests/e2e/test_projectiles_visible.gd
  modified:
    - simulation/clock/sim_clock.gd
    - simulation/night/night_sim.gd
    - simulation/night/enemy_system.gd
    - data/maps/prototype_map.tres
    - presentation/enemies/enemy_views.gd
    - presentation/map/prototype_map.tscn
    - tests/unit/test_night_data_contract.gd
    - tests/unit/test_sim_clock.gd

key-decisions:
  - "A ranged shot's flight is measured from the shooter to the target's centre, the tower's from the plot centre to the enemy, both through SimClock.flight_ticks, so the event's flight_ticks and the hit's arrival tick can never disagree"
  - "Towers keep one ready-tick per spot in a Dictionary and are stepped in standing_spot_ids order (MapConfig order); a tower with no target keeps its cooldown, so an enemy entering range is shot on that tick, as the king already behaves"
  - "Each ranged group starts 1.5 s after its road's grunts, so the first skirmisher arrives behind the first wave of grunts rather than with it"
  - "Puppets own their materials (the shared per-type cache was dropped) so the hit flash is per enemy"
  - "Projectiles and slashes are drawn only for towers, skirmishers and the king; a melee enemy strike (flight 0) has no visual in this plan"

patterns-established:
  - "TDD tasks commit a RED test commit with only the shells needed to fail on assertions, then a GREEN feat commit (continued)"
  - "Night data contract pins structure and the per-night totals, not the unit mix inside a night"

requirements-completed: [KING-03, BLDG-07]

coverage:
  - id: D1
    description: "A standing tower shoots the nearest enemy within its tier's attack_range (ties to the lower id, exactly at range yes, 0.01 m beyond no) at tick 0 and then every attack_interval; the hit lands flight_ticks later and drops if the target is already dead; an empty plot, a House and a fallen tower never shoot"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_tower_combat.gd"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tier II deals more damage per tick than tier I with the shipped data, uses its own flight and interval, and a tower kill is credited to killer kind building"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_tower_combat.gd#test_a_tier_two_tower_shoots_harder_and_faster_than_tier_one"
        status: pass
      - kind: unit
        ref: "tests/unit/test_tower_combat.gd#test_an_enemy_killed_by_a_tower_is_credited_to_a_building"
        status: pass
    human_judgment: false
  - id: D3
    description: "SimClock.flight_ticks(14, 14) is 30, a short hop is 1, a speed of 0 or less is 0, and a flight that is a whole number of steps does not round up"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_sim_clock.gd"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Skirmisher stops at attack_range plus the target's radius, shoots every attack_interval, its hit lands flight_ticks after the shot on a House, the castle or the king, and a hit on a House destroyed in the meantime drops; a grunt still strikes at once"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_ranged_enemy.gd"
        status: pass
    human_judgment: false
  - id: D5
    description: "The map lists exactly the grunt and the ranged type; no ranged group appears before night 3, the first ranged night is 4 and it stays; per-night totals stay 5, 8, 11, 14, 18, 22, 27, 33"
    requirement: BLDG-07
    verification:
      - kind: unit
        ref: "tests/unit/test_night_data_contract.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "In the real scene a tower shot shows a projectile at the moment it fires that is freed within flight_seconds plus 0.2 s, a skirmisher shot is a violet arrow, a flood of 200 shots never passes the 128 cap and all free themselves, and the king's passive strike shows a slash that is gone within 0.3 s"
    requirement: KING-03
    verification:
      - kind: e2e
        ref: "tests/e2e/test_projectiles_visible.gd"
        status: pass
      - kind: unit
        ref: "tests/unit/test_projectile_vfx.gd"
        status: pass
    human_judgment: false
  - id: D7
    description: "A grunt and a skirmisher puppet differ in colour and silhouette, an enemy's bar is hidden until it is hit and then fills to hp over max, a hit flashes the body and it settles, and a dying enemy leaves a puff that frees itself"
    requirement: KING-03
    verification:
      - kind: e2e
        ref: "tests/e2e/test_projectiles_visible.gd"
        status: pass
    human_judgment: false
  - id: D8
    description: "Whether the arrows, the slash, the flash and the puff read clearly and feel good on screen, and whether skirmishers make positioning matter"
    requirement: KING-03
    verification: []
    human_judgment: true
    rationale: "Readability and feel are visual judgements; the tests prove the nodes exist, move and free themselves, not how they look. The screenshot tool needs a real renderer; the owner judges it at the playtest gate and plan 02-10 retunes the skirmisher numbers."

duration: 38min
completed: 2026-10-05
status: complete
plan_head_before: 288d45b07309d9c7d23a6580e1cf412cef841d7a
plan_head_after: 98753b38fc395b41daf7200779ddad5b03e19e37
commits: 4
---

# Phase 2 Plan 05: Towers, Skirmishers and Visible Attacks Summary

**Towers now shoot the nearest enemy on a fixed cadence with travel-time hits, a ranged Skirmisher joins the nights from night 4 on the same deterministic hit queue, and every attack (arrows, the king's slash, hit flashes, hurt bars, death puffs) is drawn on screen.**

## Performance

- **Duration:** 38 min
- **Started:** about 2026-10-05T09:30:00Z
- **Completed:** 2026-10-05T10:07:24Z
- **Tasks:** 2 (4 commits: RED and GREEN for each)
- **Files modified:** 21 (including `.gd.uid` files)

## Accomplishments

- **SimClock.flight_ticks(distance, speed):** `maxi(ceili(distance / speed / STEP - 0.0001), 1)`, 0 for a speed of zero or less; the same slack as `ticks`, pinned in `test_sim_clock.gd`.
- **TowerSystem:** for each standing spot in MapConfig order whose current tier has `attack_damage > 0`, it keeps a ready-tick per spot, picks `TargetQuery.nearest_enemy(plot XZ, tier.attack_range)`, enqueues a `KIND_BUILDING` hit arriving `tick + flight_ticks(distance, projectile_speed)`, emits `attack_fired(&"building", spot_index, &"enemy", id, flight)` and sets the cooldown to `tick + ticks(attack_interval)`. No target leaves the cooldown alone. A fallen tower is not in `standing_spot_ids`, so it stops at once; a hit whose target already died drops in `EnemySystem.damage`. `NightSim` builds it, calls `begin_night()` and steps it between the king and the enemies (DR-8).
- **Ranged enemies:** `EnemySystem._advance_and_strike` now enqueues the hit at `tick + flight_ticks(distance to target centre, def.projectile_speed)` and emits that flight in `attack_fired`; for a melee def the speed is 0, so nothing changes. The existing stop distance (target radius plus attack_range) already keeps a ranged enemy out of melee. `data/enemies/ranged.tres` is the Skirmisher (4 hp, speed 2.8, range 7, damage 2 every 1.6 s, arrow speed 14).
- **Nights:** nights 4 to 8 of `prototype_map.tres` split into grunt and ranged groups exactly as the plan lists, each ranged group starting 1.5 s after its road's grunts; per-night totals are still 5, 8, 11, 14, 18, 22, 27, 33. `test_night_data_contract.gd` pins D-08: exactly two types, none before night 3, first on night 4, totals unchanged.
- **ProjectileVfx** (node in `prototype_map.tscn`, group `run_bound`): on `attack_fired` with a flight it spawns an emissive arrow (yellow for towers, violet for skirmishers) at the attacker, moves it to the target's current position over `flight_seconds(flight_ticks)` with a parabolic `arc_height`, then frees it; capped at `MAX_PROJECTILES` (128). A flight of 0 from the king shows a flat slash pointing at his target that shrinks away in 0.15 s. Hooks `live_count()` and `slash_count()`.
- **EnemyViews:** the Skirmisher is violet, taller (2.0 m) and narrower than the grunt; each puppet has a hurt-only `HealthBar3D` fed by `enemy_damaged`, a per-puppet emission flash and a one-shot `CPUParticles3D` puff on death that frees itself after 0.6 s (capped at 64).

## Task Commits

1. **Task 1 RED:** failing tests for tower fire, ranged attackers and the D-08 contract - `2e05827` (test)
2. **Task 1 GREEN:** towers fire at the nearest enemy, skirmishers join from night 4 - `b35d90c` (feat)
3. **Task 2 RED:** failing tests for projectiles, the slash, hurt bars and puffs - `192d81f` (test)
4. **Task 2 GREEN:** projectiles, slash, enemy bar, flash and puff - `98753b3` (feat)

**Plan metadata:** recorded in the final docs commit.

## Verification

- Full suite after Task 1: 71 scripts, 598 tests, 0 failures (baseline 568 in 69 scripts); after Task 2: 73 scripts, 611 tests, 0 failures. `bash tools/lint.sh` clean.
- `test_tower_combat`, `test_ranged_enemy`, `test_night_data_contract`, `test_determinism`, `test_prototype_nights`, `test_king_combat`, `test_projectile_vfx`, `test_projectiles_visible` and `test_night_tracer_scene` are all present and passing in the JUnit XML.
- RED runs failed on assertions for the planned behavior: tower tests 12 of 16 (the 4 that passed in RED are negative guards such as an empty plot not shooting), ranged tests 3 of 7, contract 3 of 11, flight_ticks 1 of 9, projectile helpers 3 of 6, e2e 7 of 7.
- Mutation probe: setting the tower cooldown to `tick` instead of `tick + ticks(attack_interval)` made `test_tower_combat` fail on the cadence, the cooldown and the begin-night tests; the code was restored with `git checkout`.
- Acceptance strings checked: `class_name TowerSystem` and `flight_ticks(` in tower_system.gd, `static func flight_ticks(` in sim_clock.gd, `id = &"ranged"` and `projectile_speed = 14.0` in ranged.tres, the ranged.tres reference in prototype_map.tres, `D-08` in the contract test, `class_name ProjectileVfx`, `const MAX_PROJECTILES` and `attack_fired.connect` in projectile_vfx.gd, `ProjectileVfx` in the scene, `HealthBar3D` and `enemy_damaged.connect` in enemy_views.gd.

## Deviations from Plan

### Auto-fixed Issues

None: no bug or blocker surfaced in existing code.

### Interface details that differ from the plan's sketch (no behavior change)

- **Test-only fix for a StringName sort.** The D-08 "exactly two types" test first sorted an `Array[StringName]`, which orders by internal pointer, not text; it now sorts `String`s. Test-side only, found by the first GREEN run.
- **Extra constants and hooks.** `ProjectileVfx` exposes `ARC_PER_METRE`, `MAX_ARC_HEIGHT`, `SKIRMISHER_COLOR`, `MAX_SLASHES` and `slash_count()` beyond the interface list (the tests pin the arc through the constants); `EnemyViews` exposes `SKIRMISHER_COLOR`, `PUFF_SECONDS` and `puff_count()`. All read-only.
- **Shared per-type material cache removed.** `EnemyViews._materials` is gone: each puppet builds its own material so a flash is per enemy. Nothing else read it.
- **Ranged hit distance.** The flight of a ranged shot is measured to the target's centre (the plan says only "distance"); the stop distance puts a ranged enemy at attack_range plus the target's radius from that centre.
- **Tests placed as the plan says.** The Skirmisher cases live in a new `test_ranged_enemy.gd` and the tower cases in `test_tower_combat.gd`, so neither `test_enemy_targeting.gd` nor `BuildingSystem` crossed gdlint's 20-public-method limit.

---

**Total deviations:** 0 auto-fixed; 5 interface details noted above.
**Impact on plan:** none; every behavior-list case holds.

## Issues Encountered

- The working tree stores CRLF (gdformat rewrites it) while the index is LF; the first scripted edit of `test_night_data_contract.gd` silently missed its anchor because of that, so the constants were added in a second pass. Later scripted edits normalise line endings explicitly.
- `-gselect` takes one pattern, so partial runs were done one script at a time with a small helper in the scratchpad.

## Known Stubs

None. The RED-phase shells (`TowerSystem`, `ProjectileVfx`, the `flight_ticks` body, the `puff_count` stub) were replaced by the GREEN commits.

## Threat Flags

None. T-02-10 (node growth) is mitigated as planned: `MAX_PROJECTILES` 128 (asserted by the flood test), `MAX_VIEWS` 256 and a 64-puff cap, and every arrow, slash and puff frees itself. T-02-11 (provenance): primitives only (boxes, capsules, spheres, particles); no third-party model, texture or sound was added. T-02-SC: no packages installed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Plan 02-06** (rebuild at dawn) can rely on `TowerSystem` reading `standing_spot_ids`: a rebuilt tower is shooting again from the next night's tick 0 because `begin_night` clears every cooldown. `BuildingSystem` is unchanged by this plan and still has 18 public methods.
- **Plan 02-09 / 02-10** (balance report, retune): kills carry `killer_kind` `building` for tower kills and `king` for the king's, so the report can count kills by source. The Skirmisher numbers (4 hp, damage 2 per 1.6 s from 7 m, 14 m/s arrows) and the tower numbers are first guesses for 02-10 to retune.
- Not run: the screenshot tool (it needs a real renderer and has no shot of arrows or slashes), so how the attacks look is verified by state, not by eye; the owner judges it at the playtest gate.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*

## Self-Check: PASSED

- Created files verified present: tower_system.gd, ranged.tres, projectile_vfx.gd, test_tower_combat.gd, test_ranged_enemy.gd, test_projectile_vfx.gd, test_projectiles_visible.gd.
- Commits `2e05827`, `b35d90c`, `192d81f`, `98753b3` exist; `git rev-list --count 288d45b..HEAD` is 4.
- Full suite: 73 scripts, 611 tests, all passing; lint clean.
