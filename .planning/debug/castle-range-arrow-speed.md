---
status: diagnosed
trigger: "UAT Test 13 of Phase 2 (round 2, gap G-02-13): the owner played the fresh build with the new castle attack (2 damage every 1.5 s, reach 11 m, arrows at 18 m/s, added by plan 02-15) and asked for a tuning change: castle range should be double what it is now, and arrow speed should be 1.5x faster."
created: 2026-10-06T20:20:14Z
updated: 2026-10-06T20:37:21Z
---

## Current Focus

hypothesis: CONFIRMED. Not a defect but an owner tuning decision on shipped data. The castle's reach and arrow speed are two values in data/maps/prototype_map.tres (:357 castle_attack_range = 11.0, :359 castle_projectile_speed = 18.0), read live by CastleAttack.step every night tick; nothing in code, VFX, fixtures or the golden hard-codes them. Setting 22.0 and 27.0 needs no code change, keeps all 817 tests and the smoke golden green, leaves the balanced bot exactly unchanged (the castle never fires for it even at 22 m) and makes only weak play easier (no_build now survives night 1, greedy_economy falls one night later).
test: done (code read, flight-tick arithmetic, temporary 22.0 / 27.0 edit with the instructed 3-strategy x 5-seed playtest, a 5-strategy x 10-seed playtest, the full GUT suite, full_idle and smoke replays; data restored with git checkout, tree clean except this file)
expecting: n/a
next_action: none (diagnose-only); hand back ROOT CAUSE FOUND to the caller
bug_class: Bohrbug (deterministic shipped data value; the request is a tuning change - every run reproduces the 11 m / 18 m/s numbers the owner judged)
reasoning_checkpoint:
  hypothesis: "The castle attack the owner judged in round 2 uses castle_attack_range 11.0 and castle_projectile_speed 18.0 from prototype_map.tres:357/:359 (identical at the exported commit a483ff6); CastleAttack.step reads both from MapConfig each tick (castle_attack.gd:51, :54-56) and ProjectileVfx times the arrow from the event's flight_ticks, so changing those two values to 22.0 and 27.0 is the whole mechanical change."
  confirming_evidence:
    - "grep: castle_attack_range / castle_projectile_speed are set only in prototype_map.tres; MapConfig defaults are 0.0 (map_config.gd:45, :47); no fixture under tests/fixtures sets any castle_attack_* field."
    - "Temporary 22.0 / 27.0 edit: no_build castle kills on night 1 rose from 3.4 to 5.0 of 5 (seeds 1-5) and the castle ended night 1 at 23.6 hp instead of 0, proving the data edit alone drives the behaviour."
    - "Temporary edit: bash tools/test.sh 817/817 passing; smoke replay digest 2599c7c2... unchanged; full_idle digest 27fa2a80... unchanged with 0 castle attack_fired lines (closest enemy death 41.2 m from the castle)."
  falsification_test: "If a code path cached or hard-coded 11 m / 18 m/s, the 22 m run would show the same no_build castle kills (3.4) as the baseline; if a test pinned the shipped numbers, the suite would go red. Neither happened."
  fix_rationale: "The owner's request is a data value, so the fix is the data value (22.0, 27.0) plus the tests and docs that describe the castle's numbers; no mechanism change is needed. Optional: pin the new values in the shipped-data contract test and close WR-02 in the same plan since it touches the same fields."
  blind_spots: "Bots never ride to plots and defend far out (balanced kills every enemy more than 41 m from the castle), so they cannot show what a human sees: the owner fights nearer the castle, where 22 m covers four of five House plots. The G-02-15 'harder' lever was not applied here; any lever that makes balanced lose must push enemies inside 22 m, where the stronger castle will soften it. Range and speed effects were not separated (only the combined 22/27 edit was measured)."
  candidate_causes:
    - "data: castle_attack_range 11.0 and castle_projectile_speed 18.0 in prototype_map.tres are the values the owner wants changed (CONFIRMED)"
    - "code: a hard-coded reach or speed in CastleAttack, TargetQuery or ProjectileVfx that a data edit would not move (ELIMINATED)"
    - "config/test: contract tests pinning 11.0 / 18.0 on the shipped map, so a data edit breaks the suite (ELIMINATED: 817/817 pass)"
    - "environment: the exported build carried different numbers from the tree (ELIMINATED: a483ff6 has 11.0 / 18.0 and no data/simulation/presentation change since)"
  and_gate: "No. One data value per request (range, speed); nothing else must change for the owner's numbers to take effect."
tdd_checkpoint: (n/a, diagnose-only)

## Symptoms

expected: At night, when an enemy comes within castle_attack_range of the castle, a gold arrow leaves the top of the keep at castle_projectile_speed; three hits kill a grunt and two a skirmisher; the attack reads as simple and not too strong.
actual: castle range should be double what it is now, and arrow speed should be 1.5x faster
errors: None reported
reproduction: Test 13 in .planning/phases/02-night-defense-playtest-gate/02-UAT.md (owner play on build/windows/Duskhold.exe exported 2026-10-06 from commit a483ff6); gap id G-02-13
started: Discovered during round-2 UAT on 2026-10-06/07; the castle attack landed in plan 02-15 the same day

## Eliminated

- hypothesis: The 11 m reach or the 18 m/s speed is hard-coded somewhere in code (CastleAttack, TargetQuery, ProjectileVfx), so editing the map data would not change the game
  evidence: CastleAttack.step passes _map.castle_attack_range to TargetQuery.nearest_enemy and _map.castle_projectile_speed to SimClock.flight_ticks on every call (castle_attack.gd:51, :54-56); ProjectileVfx takes the flight from the attack_fired event (projectile_vfx.gd:129); with the temporary 22.0 / 27.0 edit, no_build night-1 castle kills moved 3.4 -> 5.0 of 5 (seeds 1-5).
  timestamp: 2026-10-06T20:37:21Z

- hypothesis: Tests pin the shipped 11.0 / 18.0, so the tuning would turn the suite red
  evidence: Full bash tools/test.sh on the temporary edit - 817 tests, 817 passing, exit 0. The shipped-data contract test only asserts range >= castle_radius + skirmisher range + 0.25 (= 10.75 m) and speed > 0 (test_map_validate_castle.gd:110-116); test_castle_attack.gd uses its own hand-built MapConfig with literal 11.0 / 18.0 and never reads the shipped map.
  timestamp: 2026-10-06T20:37:21Z

- hypothesis: The frozen fixtures or tests/golden/smoke.json would move with the castle numbers
  evidence: No tests/fixtures/*.tres sets any castle_attack_* field (default 0 = castle off); smoke replay on the temporary edit REPLAY_OK digest 2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f, equal to tests/golden/smoke.json.
  timestamp: 2026-10-06T20:37:21Z

- hypothesis: The exported build the owner played (a483ff6) carried numbers different from the tree
  evidence: git show a483ff6:data/maps/prototype_map.tres has castle_attack_range 11.0 and castle_projectile_speed 18.0; git log a483ff6..HEAD touches nothing under data/, simulation/ or presentation/.
  timestamp: 2026-10-06T20:37:21Z

## Evidence

- timestamp: 2026-10-06T20:20:14Z
  checked: Knowledge base (.planning/debug/knowledge-base.md) and resolved sessions
  found: Neither exists; no MemPalace available. Related unresolved-dir session .planning/debug/playtest-economy-castle-speed-difficulty.md (G-02-1 diagnosis) chose "range about 11 m to reach a skirmisher firing at the castle".
  implication: No known-pattern candidate; the 11 m number was derived as castle_radius 3.5 + skirmisher range 7 + margin.

- timestamp: 2026-10-06T20:22:47Z
  checked: data/maps/prototype_map.tres (all 359 lines) and simulation/defs/map_config.gd:36-47, 131-185
  found: The four castle numbers live only in prototype_map.tres:356-359 (castle_attack_damage 2, castle_attack_range 11.0, castle_attack_interval 1.5, castle_projectile_speed 18.0); MapConfig declares them at map_config.gd:44-47 with script default 0 / 0.0 (off). castle_radius 3.5 (:355), castle_position (0,0,0) (:348), king_spawn (0,0,7). _validate_castle_attack (map_config.gd:167-185) only checks < 0 and "damage > 0 with range or interval == 0"; no upper bound, no is_finite check, no interval >= SimClock.STEP check (the open WR-02 of the fourth review). grep: no other .tres/.gd/.json file in data/, tests/fixtures/ or tests/golden/ sets any castle_attack_* field, so every frozen fixture keeps the default 0 (castle off).
  implication: The tuning is a two-number data edit in one file; validate() accepts 22.0 and 27.0 unchanged (no rule depends on the value beyond > 0).

- timestamp: 2026-10-06T20:22:47Z
  checked: simulation/night/castle_attack.gd (66 lines), simulation/night/target_query.gd, simulation/clock/sim_clock.gd
  found: CastleAttack.step reads _map.castle_attack_range and _map.castle_projectile_speed live each tick (no cached copy): TargetQuery.nearest_enemy(enemies, castle centre, range) is centre-to-centre, inclusive (d2 <= range^2); flight = SimClock.flight_ticks(distance, speed) = max(ceil(d / v / STEP - 0.0001), 1), STEP 1/30 s; cooldown = SimClock.ticks(1.5) = 45 ticks; the castle tracks no pending damage (it may overkill like the towers). Flight ticks (computed with the same formula) - today 11 m @ 18 m/s = 19 ticks (0.633 s); 6 m @ 18 = 10. Requested 22 m @ 27 m/s = 25 ticks (0.833 s); 11 m @ 27 = 13 ticks (0.433 s); 6 m @ 27 = 7 ticks. Either way the flight stays shorter than the 45-tick interval, so at most one castle arrow is ever in the air.
  implication: No code change is needed for the new numbers; the attack's rate (2 dmg per 1.5 s = 1.33 dps) is unchanged, only the window in which it acts before contact and the arrow's time in the air change.

- timestamp: 2026-10-06T20:22:47Z
  checked: presentation/vfx/projectile_vfx.gd (240 lines), presentation/buildings/building_views.gd:18-20
  found: Castle arrows launch at the castle centre raised by CASTLE_LAUNCH_HEIGHT = KEEP_SIZE.y 5.0 + TURRET_HEIGHT 3.0 = 8 m (:30, :188-190) and fly for exactly SimClock.seconds(flight_ticks) taken from the attack_fired event (:129), so the visual follows any speed change with no code edit. arc_height peak = min(3D distance * 0.12, 2.5) (:52-56): at 11 m the 3D launch-to-chest distance is sqrt(11^2 + 6.8^2) = 12.9 m (peak 1.55 m); at 22 m it is 23.0 m, so the peak hits the MAX_ARC_HEIGHT 2.5 m cap (uncapped would be 2.76 m). MAX_PROJECTILES 128 is not approached (one castle arrow at a time).
  implication: The VFX needs no change; at long range the arc is clamped a little flatter, which is cosmetic only.

- timestamp: 2026-10-06T20:22:47Z
  checked: Positions on the shipped map (prototype_map.tres:15-82) against the castle centre (0,0), plus enemy and tower data (grunt.tres, ranged.tres, tower.tres)
  found: Distances from the castle centre - king_spawn 7.0 m; house_1 (-9,9) and house_2 (9,9) 12.73 m; house_3 (-18,-12) and house_4 (18,-12) 21.63 m; house_5 (0,-24) 24.0 m; tower_1/tower_2 (+-55,20) 58.52 m; tower_3 (0,-55) 55.0 m; spawn west/east (+-66,24) 70.23 m; spawn north (0,-66) 66.0 m. Skirmisher stand-off at the castle = castle_radius 3.5 + attack_range 7.0 = 10.5 m (today's 11 m covers it by 0.5 m; 22 m covers it with 11.5 m to spare, 2.1x). Grunt stop = 3.5 + 1.2 = 4.7 m. Tower reach is 9.0 (tier I) / 10.5 (tier II), so the inner edge of tower cover is 55 - 10.5 = 44.5 m from the castle: the 22 m castle circle never overlaps a tower circle (gap 22.5 m) and is far from every spawn (44+ m short). At 22 m the castle covers both inner Houses (12.7 m) completely and the centres of houses 3 and 4 (21.63 m, 0.37 m inside the edge), but not house_5 (24 m). Today's 11 m covers no House plot centre at all.
  implication: Doubling the range turns the castle from a "last 6 m before the wall" defence into an inner-ring defence over four of the five House plots; it also makes the castle the longest-reach attacker in the game (2.1x tier II tower reach) and its arrow the fastest (27 m/s vs tower 18/20, skirmisher 14).

- timestamp: 2026-10-06T20:37:21Z
  checked: Tests and tools that reference the castle numbers (grep for castle_attack_*, 11.0, 18.0, "11 m", "18 m/s" across tests/, tools/, simulation/, presentation/, ui/)
  found: (1) tests/unit/test_map_validate_castle.gd:92-116 is the only shipped-data castle contract - asserts damage > 0, 3 shots per grunt / 2 per skirmisher, range >= 3.5 + 7.0 + 0.25 = 10.75, interval == 1.5, speed > 0; it does not pin 11.0 or 18.0 (22.0 / 27.0 pass it). (2) tests/unit/test_castle_attack.gd is hand-built on MapConfig.new() with its own literals REACH 11.0, JUST_BEYOND_REACH 11.01, PROJECTILE_SPEED 18.0, "6 m @ 18 m/s = 10 ticks" (:15-19, :95-97, :140-150); it never reads the shipped map, so it stays green, but its header (:7) calls those literals "the castle's own numbers", which goes stale. (3) tests/unit/test_building_damage.gd:198-201 already switches the castle off on its shipped copy. (4) tests/integration/test_balance_acceptance.gd pins outcomes (balanced wins seeds 1-3, greedy loses on night 3-6, no_build survives <= 2 nights, towers_first wins >= 2/3), not castle numbers. (5) tests/unit/test_prototype_map_data.gd has no castle_attack assertion. No UI, overlay or screenshot scenario reads the castle attack fields. Comments and docs that quote 11 m / 18 m/s: simulation/night/castle_attack.gd:7-10 (reach 11 m, "castle_radius plus a skirmisher's attack_range plus a little"), simulation/defs/map_config.gd:40-43 ("a simple, slow shot"), 02-PLAYTEST-GATE.md:19 and :62, 02-BALANCE-REPORT.md:23, ROADMAP.md:154, STATE.md:172.
  implication: No test has to move for the suite to stay green; a planner who wants the owner's decision locked must ADD an assertion (e.g. range 22.0 and speed 27.0 in test_map_validate_castle.gd) and should refresh test_castle_attack.gd's literals or header plus the doc comments.

- timestamp: 2026-10-06T20:37:21Z
  checked: Baseline playtest on the shipped 11 m / 18 m/s data - bash tools/playtest.sh --strategies=balanced,no_build,greedy_economy --seeds=5 --out=build/pt_diag13_base (PLAYTEST_OK runs=15)
  found: balanced 5/5 won, 0.0 castle kills every night, 0 buildings lost, 0 knockouts, castle 70 hp every night. no_build 0/5, lost night 1 on all 5 seeds, night 1 castle kills 3.4 / king 0.2 of 5, castle 0 hp. greedy_economy 0/5, lost night 5 on all 5 seeds (nights survived 4), castle kills 2.2 / 2.6 / 2.0 on nights 3 / 4 / 5, gold earned 15.0, buildings lost 6.0. Matches the round-2 report (02-BALANCE-REPORT.md) for balanced and greedy.
  implication: Apples-to-apples baseline for the 22 m measurement.

- timestamp: 2026-10-06T20:37:21Z
  checked: TEMPORARY edit of prototype_map.tres to castle_attack_range 22.0 / castle_projectile_speed 27.0 (sed on lines 357 and 359), then the instructed run bash tools/playtest.sh --strategies=balanced,no_build,greedy_economy --seeds=5 --out=build/pt_diag13 (PLAYTEST_OK runs=15)
  found: balanced 5/5 won, every per-night number identical to the baseline (0.0 castle kills on all 8 nights). no_build 0/5 but now SURVIVES night 1 on all 5 seeds (castle kills 5.0 of 5, castle 23.6 hp at the end of night 1) and loses night 2 (castle kills 4.0, king 1.4 of 8). greedy_economy 0/5, now loses night 6 on 4 seeds and night 5 on 1 (median loss night 6, was 5); castle kills per night 3.0 / 3.2 / 3.8 / 2.5 on nights 3 / 4 / 5 / 6 (was 2.2 / 2.6 / 2.0 on 3 / 4 / 5); castle hp at the end of night 5 23.6 (was 0); gold earned 19.6 (was 15.0).
  implication: Doubling the reach roughly adds one pre-contact kill per wave front and turns the night-1 castle-alone loss into a win; the balanced bot is untouched.

- timestamp: 2026-10-06T20:37:21Z
  checked: Same temporary edit, all five strategies on seeds 1-10 (bash tools/playtest.sh --seeds=10 --out=build/pt_diag13_full, PLAYTEST_OK runs=50) against the round-2 tables in 02-BALANCE-REPORT.md
  found: balanced 10/10 (round 2: 10/10), per-night table identical to round 2 to the decimal, 0.0 castle kills, 0 buildings lost, 0 knockouts. houses_first 10/10 (10/10), 0 castle kills, 0.9 buildings lost (0.9). towers_first 10/10 (10/10); only night 8 moves - castle kills 2.5 (1.9), king kills 14.4 (15.0), castle hp at end 56.4 (52.0), knockouts 1.8 (1.9) mean per run. greedy_economy 0/10 (0/10), nights survived 4.9 / 4 / 5 (4.0 / 4 / 4), median loss night 6 (5; seed 1 loses night 5, seeds 2-10 night 6), gold earned 19.8 (15.0), buildings lost 8.4 (6.0, more nights played). no_build 0/10 (0/10), nights survived 1.0 / 1 / 1 (0.3 / 0 / 1), median loss night 2 (1), night-1 castle kills 5.0 of 5 (3.8).
  implication: The range doubling does not make the balanced bot one bit easier (it still wins 10/10, castle never involved), so it does not work against G-02-15's 7-8 of 10 target directly; it makes weak and idle play about one night more forgiving. It also puts greedy_economy at night 6, the top edge of the D-10 band pinned by test_balance_acceptance (GREEDY_LAST_LOSS_NIGHT 6): any further easing would push it out of band, while the G-02-15 harder lever should pull it back.

- timestamp: 2026-10-06T20:37:21Z
  checked: Same temporary edit - bash tools/replay.sh --scenario=full_idle --twice --out=build/replay_diag13 and --scenario=smoke --twice --expect-file=tests/golden/smoke.json; enemy_died positions in build/replay_diag13/full_idle.log
  found: full_idle REPLAY_OK outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435 - identical to round 2; 407 attack_fired lines (188 building, 161 enemy, 58 king), none from the castle. The closest enemy death to the castle centre is 41.2 m (balanced seed 1). smoke REPLAY_OK digest 2599c7c2... matches the golden.
  implication: Under the balanced bot no enemy ever comes within about 41 m of the castle, so a 22 m castle fires zero shots; full_idle and smoke both stay as they are, no golden change.

- timestamp: 2026-10-06T20:37:21Z
  checked: Full GUT suite on the same temporary edit (bash tools/test.sh, 5 min 13 s, log in the session scratchpad gut_22m.log)
  found: Scripts 94, Tests 817, Passing 817, Asserts 8871, exit 0; the only warnings and ERROR lines are the expected outputs of validate/overlay tests (duplicate spot id, malformed overlay rows), the same as on the shipped data.
  implication: The tuning needs no test edit to stay green.

- timestamp: 2026-10-06T20:37:21Z
  checked: Mechanics of the attack at both ranges (SimClock.flight_ticks / ticks with the shipped formula; grunt move_speed 3.2, attack_range 1.2; skirmisher move_speed 2.8, attack_range 7.0, projectile 14 m/s)
  found: Throughput is unchanged at 2 damage per 45 ticks (1.33 dps, one grunt per 4.5 s, one skirmisher per 3.0 s); only the pre-contact window grows. A lone grunt crosses from reach to its castle stop (4.7 m) in 6.3 / 3.2 = 1.97 s at 11 m (2 hits land before it strikes, the third after) and in 17.3 / 3.2 = 5.4 s at 22 m (all 3 hits land, it dies near 11 m out without striking). A skirmisher walks from reach to its 10.5 m stand-off in 0.18 s at 11 m (it shoots the castle almost at once) and in 11.5 / 2.8 = 4.1 s at 22 m (2 hits kill it before it fires). Flight at the reach edge: 19 ticks (0.63 s) today, 25 ticks (0.83 s) at 22 m / 27 m/s, 37 ticks (1.23 s) if the range doubled without the speed bump. At most one castle arrow is in the air at a time (flight < 45-tick interval) at every distance.
  implication: The owner's two numbers fit together: the 1.5x speed keeps the long-range flight under a second; the attack stays "simple" (same damage, same rate) but now neutralises lone grunts and skirmishers before contact, and covers four of five House plots.

## Resolution

root_cause: "Not a code defect: an owner tuning decision on shipped data. The castle's reach and arrow speed are data/maps/prototype_map.tres:357 castle_attack_range = 11.0 and :359 castle_projectile_speed = 18.0 (the same values at the exported commit a483ff6), read live by CastleAttack.step (simulation/night/castle_attack.gd:51 TargetQuery.nearest_enemy(..., castle_attack_range), :54-56 SimClock.flight_ticks(distance, castle_projectile_speed)); MapConfig declares both with default 0.0 (simulation/defs/map_config.gd:45, :47) and ProjectileVfx times the arrow from the event's flight_ticks, so the owner's 'double the range, 1.5x arrow speed' is exactly 22.0 and 27.0 in those two lines. At 11 m the castle only acts in the last 6.3 m before a grunt reaches its wall and 0.5 m beyond a skirmisher's 10.5 m stand-off, and covers no House plot, so in a human run it barely joins the fight."
fix: "(not applied - diagnose-only) Set castle_attack_range = 22.0 and castle_projectile_speed = 27.0 in prototype_map.tres; no code change is needed (verified: 817/817 tests, smoke and full_idle digests unchanged on the temporary edit)."
verification: "Diagnosis verified by code read, flight-tick arithmetic, a temporary 22.0 / 27.0 edit measured with the instructed 3 x 5 playtest, a 5 x 10 playtest, the full GUT suite and the full_idle and smoke replays; data restored with git checkout -- data/maps/prototype_map.tres, git status --short shows only this debug file."
files_changed: []
