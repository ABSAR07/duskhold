# Phase 4 Balance Report (plan 04-10: the bots buy walls, D-14 and D-15)

Measured 2026-10-16 (UTC) by plan 04-10 with `bash tools/playtest.sh --seeds=10` on the shipped prototype map
(`PLAYTEST_OK runs=80`: eight strategies by seeds 1 to 10, about five minutes). As in Phases 2 and 3, these
tables are scripted bots measuring the data. They build without riding to the plots and react perfectly,
so they are not the owner's sign-off and say nothing about feel (Phase 2 D-18). The owner judges the feel of
the walls at the Phase 4 gate (`/gsd-verify-work 4`).

## Outcome

**The Phase 2 bar holds with walls: `balanced` wins 8 of seeds 1 to 10 and `army_balanced` 8 of 10, as before.**
Nothing in `data/` moved: no night group count, no wall cost, no tower, squad, castle, king or economy number.
Only the bots changed (their build orders, plus two new names for the Phase 3 orders).

Which branch of D-15 applied, in the order it was reached:

1. The plan's first order (each road run right after that road's first tower, the ring after the last
   first-tier House, one upgrade of each road run after that road's tower upgrade) **broke the bar**:
   `balanced` won **4 of 10** and `army_balanced` **2 of 10**. That is the "6 or fewer" branch of D-15.
2. D-15's first lever for that branch is the bot's order: the wall entries moved later (a measuring choice,
   not a game rule). Every candidate is in the search log below. The shipped orders win 8 of 10 for both bots
   and lose exactly the seeds the Phase 3 orders lose (balanced 3 and 9, army 1 and 9).
3. D-15's second lever, wall costs within D-03, was **not needed and not pulled**. It was measured as a
   sensitivity only (search log, Round I); even the cheapest costs D-03 allows (1 / 3 / 5) left the
   first order at 5 of 10 for `balanced`, so the order was the lever that works.
4. D-15's "9 or 10 wins" branch (raise night counts) never came up, and lowering night counts is not one of
   D-15's levers.

The honest limit of this result is stated under "What the numbers say, and what they cannot": at the shipped
wall prices the bots can only afford walls in the last days before the final nights, so the with-walls rows
measure a game in which walls are bought late and are never broken.

## Nights play the same (success criterion 4)

ROADMAP success criterion 4 read per D-14 as the same outcomes. Two checks, both before any bot learned to buy a wall.

**Check 1: the Phase 3 orders on the Phase 4 code, against the Phase 3 code.** On commit `e3b8a74` (the walls
golden; the simulation and every strategy exactly as the earlier Phase 4 plans left them, the strategies still
the Phase 3 orders), `bash tools/playtest.sh --seeds=10` (60 runs, six strategies) wrote `report.json` and `report.md`.
The same command on a clean export of the Phase 3 tree (commit `75183fe`, the parent of the first Phase 4 code change
`c86d389`, so Phase 3 as signed off with its review fixes) wrote the same two files. The two `report.json`
files are **byte-identical** (md5 `001778e71f38ecd0424f65e0ef9977f8` for both) and so are the two `report.md`
files: every run's outcome, nights survived, gold, buildings lost, knockouts, per-night enemies, every kill
column, military, tower and economy gold, in all 60 runs. That is stronger than "within a stated band": the
straight-line fallback of 04-04 and 04-06 leaks nowhere on the shipped map before a wall is bought.

The per-seed rows, equal to 03-BALANCE-REPORT.md Round 2 ("After Round 2") on every figure it prints:

| Strategy | Per seed (seed: outcome, nights survived, kills over the run) |
|---|---|
| balanced | 1 won 8 194, 2 won 8 194, **3 lost 7 182**, 4 won 8 194, 5 won 8 194, 6 won 8 194, 7 won 8 194, 8 won 8 194, **9 lost 2 33**, 10 won 8 194 |
| army_balanced | **1 lost 6 151**, 2 to 8 won 8 194 (seeds 2, 3, 4, 5, 6, 7, 8), **9 lost 5 109**, 10 won 8 194 |
| towers_first | seeds 1 to 7, 9 and 10 lost with 6 nights survived (kills 139 to 150), seed 8 lost with 7 (kills 183); 0 of 10 won |
| houses_first | seeds 1, 2, 5 and 7 won; 3, 4 and 8 lost on night 8, 6 and 10 on night 7, 9 on night 3; 4 of 10 won |

Round 2's own text (balanced lost seed 3 on night 8 and seed 9 on night 3; army lost seed 1 on night 7 and seed 9
on night 6; towers_first 0 of 10; houses_first 4 of 10) is the same list.

**Check 2: the final matrix.** After the bots learned to buy walls, the four strategies that never buy a wall
(no_build, greedy_economy, houses_first, towers_first) and the two no-walls twins (`balanced_no_walls`,
`army_balanced_no_walls`, which are the Phase 3 orders under new names) were compared run by run with the Phase 3
run of the same strategy and seed: **60 of 60 runs equal** in every field (the new `walls_broken` column is the only
addition). The smoke and army goldens are untouched by this plan and by the whole phase (see "Goldens decision").

## With and without walls

Summary of all eight strategies, seeds 1 to 10 (the Phase 3 table plus the new rows; `balanced` and `army_balanced`
now buy the wall runs, the `_no_walls` rows are their Phase 3 orders):

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.9 / 2 / 4 | 4 | 9.2 | 5.0 | 1.8 |
| houses_first | 40% | 6.7 / 2 / 8 | 7 | 21.1 | 14.7 | 1.1 |
| towers_first | 0% | 6.1 / 6 / 7 | 7 | 6.1 | 5.9 | 2.6 |
| balanced | 80% | 7.3 / 2 / 8 | 3 | 21.9 | 10.9 | 0.6 |
| army_balanced | 80% | 7.5 / 5 / 8 | 6 | 14.8 | 18.0 | 1.2 |
| balanced_no_walls | 80% | 7.3 / 2 / 8 | 3 | 22.2 | 10.4 | 0.6 |
| army_balanced_no_walls | 80% | 7.5 / 5 / 8 | 6 | 15.0 | 17.6 | 1.3 |

Wins with and without walls: **balanced 8 and 8, army_balanced 8 and 8.** Seeds lost: balanced 3 (night 8) and 9
(night 3) in both; army_balanced 1 (night 7) and 9 (night 6) in both.

What the bots actually bought (`building_built` lines of the wall plots, by the shipped orders; "after night N"
means in the day that follows night N):

| Bot | Wall tiers bought over seeds 1 to 10 | Walls broken |
|---|---|---:|
| balanced | 15: seeds 2, 5 west after night 6 then east and north after night 7; seeds 1, 4, 7, 10 west (seed 7: after night 6) and east; seed 6 west only; seeds 3, 8 and 9 none | 0 |
| army_balanced | 6: seed 4 west and east after night 6 and north after night 7; seed 2 west and east; seed 3 west; seeds 1, 5 to 10 none | 0 |

The 15 tier I walls the balanced bot bought cost 2 gold each, 3.0 gold a run on average; the army bot's 6 cost 1.2 a run. The
walls displace other economy buys in the runs that reach them (the economy-role spend above the twin's is 1.6 gold a run for
balanced and 1.0 for army, less than the walls' price), so the with-walls rows differ from their twins in what they built, not only
in the walls.

Per-seed tables (outcome, nights survived, the night a lost run ended on, enemies killed over the run, wall
segments broken, gold spent on the economy role, which includes the walls):

**balanced_no_walls**

| Seed | Outcome | Nights survived | Lost on night | Kills | Walls broken | Economy gold spent |
|---:|---|---:|---:|---:|---:|---:|
| 1 | won | 8 | - | 194 | 0 | 8 |
| 2 | won | 8 | - | 194 | 0 | 8 |
| 3 | lost | 7 | 8 | 182 | 0 | 6 |
| 4 | won | 8 | - | 194 | 0 | 8 |
| 5 | won | 8 | - | 194 | 0 | 8 |
| 6 | won | 8 | - | 194 | 0 | 8 |
| 7 | won | 8 | - | 194 | 0 | 8 |
| 8 | won | 8 | - | 194 | 0 | 6 |
| 9 | lost | 2 | 3 | 33 | 0 | 6 |
| 10 | won | 8 | - | 194 | 0 | 8 |

**balanced (with walls)**

| Seed | Outcome | Nights survived | Lost on night | Kills | Walls broken | Economy gold spent |
|---:|---|---:|---:|---:|---:|---:|
| 1 | won | 8 | - | 194 | 0 | 10 |
| 2 | won | 8 | - | 194 | 0 | 12 |
| 3 | lost | 7 | 8 | 182 | 0 | 6 |
| 4 | won | 8 | - | 194 | 0 | 10 |
| 5 | won | 8 | - | 194 | 0 | 12 |
| 6 | won | 8 | - | 194 | 0 | 8 |
| 7 | won | 8 | - | 194 | 0 | 10 |
| 8 | won | 8 | - | 194 | 0 | 6 |
| 9 | lost | 2 | 3 | 33 | 0 | 6 |
| 10 | won | 8 | - | 194 | 0 | 10 |

**army_balanced_no_walls**

| Seed | Outcome | Nights survived | Lost on night | Kills | Walls broken | Economy gold spent |
|---:|---|---:|---:|---:|---:|---:|
| 1 | lost | 6 | 7 | 151 | 0 | 6 |
| 2 | won | 8 | - | 194 | 0 | 6 |
| 3 | won | 8 | - | 194 | 0 | 6 |
| 4 | won | 8 | - | 194 | 0 | 8 |
| 5 | won | 8 | - | 194 | 0 | 6 |
| 6 | won | 8 | - | 194 | 0 | 6 |
| 7 | won | 8 | - | 194 | 0 | 6 |
| 8 | won | 8 | - | 194 | 0 | 6 |
| 9 | lost | 5 | 6 | 109 | 0 | 6 |
| 10 | won | 8 | - | 194 | 0 | 6 |

**army_balanced (with walls)**

| Seed | Outcome | Nights survived | Lost on night | Kills | Walls broken | Economy gold spent |
|---:|---|---:|---:|---:|---:|---:|
| 1 | lost | 6 | 7 | 151 | 0 | 6 |
| 2 | won | 8 | - | 194 | 0 | 10 |
| 3 | won | 8 | - | 194 | 0 | 8 |
| 4 | won | 8 | - | 194 | 0 | 12 |
| 5 | won | 8 | - | 194 | 0 | 6 |
| 6 | won | 8 | - | 194 | 0 | 6 |
| 7 | won | 8 | - | 194 | 0 | 6 |
| 8 | won | 8 | - | 194 | 0 | 6 |
| 9 | lost | 5 | 6 | 109 | 0 | 6 |
| 10 | won | 8 | - | 194 | 0 | 6 |

Per night, with the new `Walls broken` column (the number of `wall_segment_broken` events in the night, a
read-only tally that does not move any digest):

**Per night: balanced (with walls)**

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Kills units | Buildings lost | Units lost | Walls broken | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 11.1 | 3.0 |
| 2 | 10 | 12.0 | 7.9 | 0.0 | 4.1 | 0.0 | 1.2 | 0.0 | 0.0 | 0.0 | 70.0 | 31.4 | 3.8 |
| 3 | 10 | 21.0 | 11.1 | 7.7 | 1.7 | 0.0 | 0.6 | 0.0 | 0.0 | 0.3 | 54.6 | 29.8 | 4.2 |
| 4 | 9 | 21.0 | 4.9 | 16.1 | 0.0 | 0.0 | 0.8 | 0.0 | 0.0 | 0.2 | 70.0 | 24.9 | 4.3 |
| 5 | 9 | 25.0 | 7.0 | 16.0 | 2.0 | 0.0 | 2.6 | 0.0 | 0.0 | 0.0 | 69.3 | 36.8 | 3.6 |
| 6 | 9 | 31.0 | 6.8 | 23.6 | 0.7 | 0.0 | 2.2 | 0.0 | 0.0 | 0.0 | 70.0 | 34.5 | 6.4 |
| 7 | 9 | 39.0 | 10.0 | 27.9 | 1.1 | 0.0 | 2.3 | 0.0 | 0.0 | 0.0 | 66.0 | 34.4 | 4.4 |
| 8 | 9 | 40.0 | 9.8 | 27.3 | 1.6 | 0.0 | 2.2 | 0.0 | 0.0 | 0.1 | 62.2 | 35.8 | 1.1 |

**Per night: balanced_no_walls**

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Kills units | Buildings lost | Units lost | Walls broken | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 11.1 | 3.0 |
| 2 | 10 | 12.0 | 7.9 | 0.0 | 4.1 | 0.0 | 1.2 | 0.0 | 0.0 | 0.0 | 70.0 | 31.4 | 3.8 |
| 3 | 10 | 21.0 | 11.1 | 7.7 | 1.7 | 0.0 | 0.6 | 0.0 | 0.0 | 0.3 | 54.6 | 29.8 | 4.2 |
| 4 | 9 | 21.0 | 4.9 | 16.1 | 0.0 | 0.0 | 0.8 | 0.0 | 0.0 | 0.2 | 70.0 | 24.9 | 4.3 |
| 5 | 9 | 25.0 | 7.0 | 16.0 | 2.0 | 0.0 | 2.6 | 0.0 | 0.0 | 0.0 | 69.3 | 36.8 | 3.6 |
| 6 | 9 | 31.0 | 6.8 | 23.6 | 0.7 | 0.0 | 2.2 | 0.0 | 0.0 | 0.0 | 70.0 | 34.5 | 6.4 |
| 7 | 9 | 39.0 | 10.1 | 27.8 | 1.1 | 0.0 | 2.3 | 0.0 | 0.0 | 0.0 | 66.0 | 34.3 | 4.8 |
| 8 | 9 | 40.0 | 9.8 | 28.0 | 0.9 | 0.0 | 1.7 | 0.0 | 0.0 | 0.1 | 62.2 | 31.4 | 2.6 |

**Per night: army_balanced (with walls)**

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Kills units | Buildings lost | Units lost | Walls broken | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 10.3 | 3.0 |
| 2 | 10 | 12.0 | 8.5 | 0.0 | 3.5 | 0.0 | 0.9 | 0.0 | 0.0 | 0.0 | 70.0 | 30.5 | 5.1 |
| 3 | 10 | 21.0 | 14.6 | 0.0 | 4.6 | 1.8 | 2.3 | 0.0 | 0.0 | 0.0 | 70.0 | 38.4 | 1.9 |
| 4 | 10 | 21.0 | 13.9 | 0.0 | 4.6 | 2.5 | 2.5 | 0.5 | 0.0 | 0.0 | 69.2 | 37.3 | 2.5 |
| 5 | 10 | 25.0 | 14.8 | 1.5 | 4.2 | 4.5 | 2.6 | 0.3 | 0.0 | 0.4 | 65.6 | 39.4 | 3.9 |
| 6 | 10 | 31.0 | 14.3 | 6.5 | 4.3 | 5.3 | 2.6 | 0.3 | 0.0 | 0.1 | 62.4 | 37.9 | 2.7 |
| 7 | 9 | 39.0 | 16.4 | 6.3 | 6.2 | 9.7 | 4.2 | 2.4 | 0.0 | 0.8 | 34.9 | 43.4 | 3.6 |
| 8 | 8 | 40.0 | 15.9 | 6.4 | 4.5 | 13.3 | 4.1 | 0.5 | 0.0 | 0.0 | 70.0 | 39.8 | 0.5 |

**Per night: army_balanced_no_walls**

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Kills units | Buildings lost | Units lost | Walls broken | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 10.3 | 3.0 |
| 2 | 10 | 12.0 | 8.5 | 0.0 | 3.5 | 0.0 | 0.9 | 0.0 | 0.0 | 0.0 | 70.0 | 30.5 | 5.1 |
| 3 | 10 | 21.0 | 14.6 | 0.0 | 4.6 | 1.8 | 2.3 | 0.0 | 0.0 | 0.0 | 70.0 | 38.4 | 1.9 |
| 4 | 10 | 21.0 | 13.9 | 0.0 | 4.6 | 2.5 | 2.5 | 0.5 | 0.0 | 0.0 | 69.2 | 37.3 | 2.5 |
| 5 | 10 | 25.0 | 14.8 | 1.5 | 4.2 | 4.5 | 2.6 | 0.3 | 0.0 | 0.4 | 65.6 | 39.4 | 3.9 |
| 6 | 10 | 31.0 | 14.3 | 6.5 | 4.3 | 5.3 | 2.6 | 0.3 | 0.0 | 0.1 | 62.4 | 37.9 | 2.7 |
| 7 | 9 | 39.0 | 17.7 | 7.1 | 5.3 | 8.6 | 3.7 | 2.4 | 0.0 | 0.8 | 34.9 | 43.8 | 4.0 |
| 8 | 8 | 40.0 | 15.8 | 7.9 | 4.9 | 11.5 | 4.3 | 0.4 | 0.0 | 0.1 | 70.0 | 40.8 | 1.0 |

The with-walls rows differ from their twins only in nights 7 and 8, where the walls were bought: a few kills
move between the king, the towers and the castle, and the walls broken are 0 in every night of every seed.

## What changed

Data: **nothing**. `data/maps/prototype_map.tres` (night group counts, still 5, 12, 21, 21, 25, 31, 39, 40) and
`data/buildings/wall.tres` (cost 2 / 4 / 6, health 30 / 60 / 90) are as the earlier plans left them, so
`test_night_data_contract` and `test_wall_data_contract` did not change.

Tools (the measuring side only):

| File | Change |
|---|---|
| `tools/replay/playtest_strategies.gd` | `NAMES` gains `balanced_no_walls` and `army_balanced_no_walls` (the Phase 3 orders, same king, squad and slam settings); `_BALANCED` and `_ARMY_BALANCED` carry the four wall runs, placed as below |
| `tools/replay/replay_driver.gd`, `tools/replay/balance_report.gd` | per-night `walls_broken` from `wall_segment_broken`; `Walls broken` column in the night tables |
| `tests/integration/test_balance_acceptance.gd` | Phase 3 pins on the twins; with-walls pins on `balanced` and `army_balanced` (below) |

The shipped wall placement (old order unchanged except for the added entries):

- `balanced`: `house_1, house_2, house_3, tower_1, tower_2, tower_3, tower_1, [wall_west, wall_east, wall_north], house_4,
  tower_2, house_5, [wall_ring], tower_3, [wall_west, wall_east, wall_north again, the upgrades], house_1 ... house_5` (the
  bracketed entries are the additions). The road runs come right after the first tower upgrade, the ring after the last
  first-tier House (`house_5`), and the road upgrades after the last tower upgrade.
- `army_balanced`: `house_1, house_2, barracks_1, house_3, tower_1, archery_1, [wall_west, wall_east, wall_north], tower_2,
  house_4, tower_3, barracks_1, archery_1, house_5, [wall_ring], tower_1, tower_2, house_1 ... house_5, barracks_1, archery_1,
  tower_3, [wall_west, wall_east, wall_north, the upgrades]`. The Archery Range is still within the first six non-wall entries.

## Search log

Every candidate measured, with seeds 1 to 10 on the shipped data. The candidates were run with a scratch runner that
swaps only the build order (or the wall costs, in a copy of the map) and runs the same `ReplayDriver` as the playtest; it
reproduces the sweep's rows exactly (the no-walls order gives 8, lost 3 and 9, and the plan's first order gives 4, as the
playtest printed). "Lost" is (seed, the night it was lost on). "Tiers/run" is the wall tiers bought per run on average and
"after night" the mean number of nights started when they were bought (7 means in the day before night 8); a first batch did
not record them (n/m). `t1` `t2` `t3` are the three towers, `u` an upgrade entry, `h` a House, `w e n r` the four wall plots.
The Phase 3 orders are `h1 h2 h3 t1 t2 t3 t1u h4 t2u h5 t3u h1u h2u h3u h4u h5u` (balanced) and
`h1 h2 b1 h3 t1 a1 t2 h4 t3 b1u a1u h5 t1u t2u h1u h2u h3u h4u h5u b1u a1u t3u` (army; `b1` the Barracks, `a1` the Range).
133 measurements of ten seeds were made, 123 of them distinct configurations (the repeats are the re-runs that added the tier
counts and a few identical orders reached twice; they gave the same results each time).

**Round A: the plan's first order (step 2), as swept by `bash tools/playtest.sh --seeds=10`**

| # | Candidate | Bot | Wins | Lost | Tiers/run | After night |
|---|---|---|---:|---|---:|---:|
| A1 | each road run right after its first tower, ring after `h5`, each road upgrade after that road's tower upgrade | balanced | 4 | (3,7) (4,8) (5,8) (8,7) (9,3) (10,7) | 2.5 | 4.5 |
| A2 | the same entries in the army order | army_balanced | 2 | (1,7) (3,7) (5,8) (6,8) (7,8) (8,8) (9,6) (10,8) | 0.9 | 5.8 |

**Round B: balanced, structured placements (batch 1, then the ones that bought walls re-run with the tier counts)**

| # | Candidate | Wins | Lost | Tiers/run | After night |
|---|---|---:|---|---:|---:|
| B0 | the Phase 3 order, no wall (sanity: equals the sweep) | 8 | (3,8) (9,3) | 0 | - |
| B1 | `w e n r` after `t3u`, the House upgrades, then `w e n` (the road upgrades) at the end | 8 | (3,8) (9,3) | n/m | n/m |
| B2 | `w e n r` (tier I only) after `t3u`, then the House upgrades | 8 | (3,8) (9,3) | 0.0 | - |
| B3 | the House upgrades, then `w e n r` (tier I only) at the end | 8 | (3,8) (9,3) | 0.0 | - |
| B4 | the House upgrades, then `w e n r w e n` at the end | 8 | (3,8) (9,3) | n/m | n/m |
| B5 | `w` after `t1u`, `e` after `t2u`, `n r` after `t3u` | 8 | (3,8) (9,3) | 0.7 | 6.6 |
| B6 | `r` alone, at the end | 8 | (3,8) (9,3) | n/m | n/m |
| B7 | `r` alone, after `h5` (before `t3u`) | 8 | (3,8) (9,3) | 0.0 | - |
| B8 | `w` and its upgrade only, in A1's places | 7 | (3,7) (6,7) (9,3) | n/m | n/m |
| B9 | `e` and its upgrade only, in A1's places | 8 | (3,8) (9,3) | n/m | n/m |
| B10 | `n` and its upgrade only, in A1's places | 7 | (8,8) (9,3) (10,7) | n/m | n/m |
| B11 | A1 without the ring | 4 | (3,7) (4,8) (5,8) (8,7) (9,3) (10,7) | 2.5 | 4.5 |
| B12 | A1 without the road upgrades | 4 | (3,7) (4,8) (5,8) (8,7) (9,3) (10,7) | 2.5 | 4.5 |

**Round C: balanced, one `w` tier I inserted before entry p of the 16-entry Phase 3 order**

| p | 3 | 4 | 5 | 6 | 7 | 8 | 9 to 16 |
|---|---:|---:|---:|---:|---:|---:|---:|
| wins | 2 | 7 | 7 | 7 | 8 | 8 | 8 |
| lost | (2,3) (3,4) (4,3) (5,3) (6,3) (8,6) (9,3) (10,7) | (3,7) (6,7) (9,3) | (3,8) (6,7) (9,3) | (3,8) (6,7) (9,3) | (3,8) (9,3) | (3,8) (9,3) | (3,8) (9,3) |
| tiers/run | 1.0 | 0.9 | 0.9 | 0.9 | 0.7 | 0.6 | 0.0 |
| after night | 2.0 | 3.2 | 4.2 | 5.2 | 6.6 | 7.0 | - |

One barricade ahead of the third entry costs the balanced bot six wins; from the fourth entry on a single one costs at most one seed.

**Round D: balanced, greedy second and third steps from `w` at p = 4 (order `h1 h2 h3 t1 w t2 t3 t1u h4 t2u h5 t3u ...`)**

| Step | Inserted before entry | Wins | Lost | Tiers/run | After night |
|---|---|---:|---|---:|---:|
| `e` | 5 | 6 | (3,6) (8,7) (9,3) (10,7) | 1.8 | 3.2 |
| `e` | 6 | 6 | (3,7) (8,7) (9,3) (10,7) | 1.8 | 3.8 |
| `e` | 7 | 7 | (3,7) (9,3) (10,7) | 1.7 | 4.3 |
| `e` | 8 | 7 | (3,7) (6,7) (9,3) | 1.4 | 4.6 |
| `e` | 9 | 7 | (3,7) (6,7) (9,3) | 1.3 | 4.4 |
| `e` | 10 to 17 | 7 | (3,7) (6,7) (9,3) | 0.9 | 3.2 |
| `n` (after `e` at 7) | 7 | 3 | (3,7) (4,8) (5,8) (6,7) (8,8) (9,3) (10,7) | 2.4 | 4.8 |
| `n` | 8 | 4 | (3,7) (4,8) (5,8) (6,7) (9,3) (10,7) | 2.4 | 4.8 |
| `n` | 9 to 18 | 7 | (3,7) (9,3) (10,7) | 1.7 | 4.3 |

**Round E: balanced, structured placements of all four runs**

| # | Candidate | Wins | Lost | Tiers/run | After night |
|---|---|---:|---|---:|---:|
| E1 | `w e n` after `t3`, upgrades `w e n` after `t3u`, `r` after `h5` | 4 | (4,8) (5,8) (6,7) (8,8) (9,3) (10,7) | 2.6 | 5.7 |
| E2 | `w e n` after `t3`, `r` after `t3u` (no upgrades) | 4 | (4,8) (5,8) (6,7) (8,8) (9,3) (10,7) | 2.6 | 5.7 |
| E3 | `w e` after `t3`, `n` after `t1u`, `r` after `t3u` | 7 | (4,8) (9,3) (10,7) | 1.8 | 5.4 |
| E4 | `w` after `t1`, `e` after `t3`, `n r` after `t3u`, upgrades at the end | 7 | (3,7) (9,3) (10,7) | 1.7 | 4.3 |
| E5 | `w` after `t1`, `e` after `t1u`, `n r` after `t3u`, upgrades at the end | 7 | (3,7) (6,7) (9,3) | 1.4 | 4.6 |
| E6 | `w` after `t1`, `w` again after `t1u`, `e` after `t2u`, `n r` after `t3u`, `e n` at the end | 7 | (3,7) (6,7) (9,3) | 1.3 | 4.4 |
| E7 | `w` after `t2`, `e` after `t2u`, `n r` after `t3u`, upgrades at the end | 7 | (3,8) (6,7) (9,3) | 0.9 | 4.2 |
| E8 | `w e n` after `t1u`, `r` after `h5`, no upgrades | 8 | (3,8) (9,3) | 1.5 | 6.8 |
| E9 | `w e n` after `h4` (after `t1u`), `r` after `h5` | 8 | (3,8) (9,3) | 1.0 | 7.0 |
| E10 | `w` after `t1u`, `e` after `h4`, `n` after `t2u`, `r` after `h5` | 8 | (3,8) (9,3) | 0.9 | 6.7 |
| E11 | `w` after `t3`, `e` after `t1u`, `n` after `h4`, `r` after `h5` | 7 | (3,8) (6,7) (9,3) | 1.3 | 5.8 |
| E12 | `w e n` after `t1u`, `r` after `t2u` (before `h5`), no upgrades | 8 | (3,8) (9,3) | 1.5 | 6.8 |
| E13 | **E8 plus the three road upgrades after `t3u`: the shipped `balanced` order** | **8** | **(3,8) (9,3)** | **1.5** | **6.8** |

Picked E13: of the candidates that lose exactly the seeds the Phase 3 order loses, it buys walls earliest and most
(E9, E10 buy fewer; E8 and E12 buy the same tiers and have no upgrades). E3 to E7 and E11 buy a little earlier but lose a seed
the Phase 3 order wins, so they change an outcome (D-14 reads the criterion as the same outcomes).

**Round F: army_balanced, `w e n` inserted before entry p of the 22-entry Phase 3 order**

| p | 4 | 5 | 6 (right after the first Range) | 7 | 8 | 9 to 22 |
|---|---:|---:|---:|---:|---:|---:|
| wins | 0 | 3 | 8 | 8 | 8 | 8 |
| lost | all ten, nights 6 and 7 | (1,7) (2,8) (4,7) (6,8) (7,8) (9,6) (10,8) | (1,7) (9,6) | (1,7) (9,6) | (1,7) (9,6) | (1,7) (9,6) |
| tiers/run | 2.3 | 2.0 | 0.6 | 0.2 | 0.1 | 0.0 |
| squad value ratio | n/m | 1.261 | 0.888 | 0.909 | 0.915 | 0.915 |

**Round G: army_balanced, one `w` tier I inserted before entry p**

| p | 4 | 5 | 6 | 7 | 8 | 9 to 22 |
|---|---:|---:|---:|---:|---:|---:|
| wins | 2 | 2 | 8 | 8 | 8 | 8 |
| lost | (1,6) (3,6) (5,6) (6,6) (7,6) (8,6) (9,6) (10,6) | (1,7) (3,7) (5,8) (6,8) (7,8) (8,8) (9,6) (10,8) | (1,7) (9,6) | (1,7) (9,6) | (1,7) (9,6) | (1,7) (9,6) |
| tiers/run | 1.0 | 0.9 | 0.3 | 0.1 | 0.1 | 0.0 |

A single barricade ahead of the first Archery Range costs the army bot six seeds: its economy is the tightest of the six.

**Round H: army_balanced, `w e n` or the shipped shape at the later placements** (all with `r` after `h5` and the upgrades at the end)

| # | Candidate | Wins | Lost | Tiers/run | After night | Ratio |
|---|---|---:|---|---:|---:|---:|
| H1 | **`w e n` right after the first Range (entry 6): the shipped `army_balanced` order** | **8** | **(1,7) (9,6)** | **0.6** | **6.5** | **0.888** |
| H2 | `w e` after the Range, `n` after `t3` | 8 | (1,7) (9,6) | 0.5 | 6.4 | 0.883 |
| H3 | `w e n` after `t2` | 8 | (1,7) (9,6) | 0.2 | 7.0 | 0.909 |
| H4 | `w e n` after `h4` | 8 | (1,7) (9,6) | 0.1 | 7.0 | 0.915 |
| H5 | `w e n` after `t3` | 8 | (1,7) (9,6) | 0.0 | - | 0.915 |
| H6 | `w e n` after the Barracks upgrade | 8 | (1,7) (9,6) | 0.0 | - | 0.915 |
| H7 | `w e n` after the Range upgrade | 8 | (1,7) (9,6) | 0.0 | - | 0.915 |
| H8 | `w e n` after `h5` | 8 | (1,7) (9,6) | 0.0 | - | 0.915 |

Picked H1, the earliest and largest purchase that loses the same two seeds; nothing earlier keeps the bar.

**Round I: wall costs (D-03's second lever), measured as a sensitivity and not applied. The plan's first order, other prices**

| # | Costs tier I / II / III | Bot | Wins | Lost | Tiers/run |
|---|---|---|---:|---|---:|
| I1 | 2 / 4 / 6 (shipped) | balanced | 4 | (3,7) (4,8) (5,8) (8,7) (9,3) (10,7) | 2.5 |
| I2 | 2 / 2 / 2 | balanced | 4 | (3,7) (4,8) (5,8) (8,7) (9,3) (10,7) | 2.5 |
| I3 | 1 / 4 / 6 | balanced | 5 | (3,8) (6,7) (8,8) (9,3) (10,7) | 2.7 |
| I4 | 1 / 3 / 5 (the cheapest D-03 allows) | balanced | 5 | (3,8) (6,7) (8,8) (9,3) (10,7) | 2.7 |
| I5 | 1 / 1 / 1 (outside D-03) | balanced | 5 | (3,8) (6,7) (8,8) (9,3) (10,7) | 3.0 |
| I6 | 0 / 0 / 0 (free, outside D-03) | balanced | 9 | (9,3) | 3.6 |
| I7 | 2 / 4 / 6 (shipped) | army_balanced | 2 | (1,7) (3,7) (5,8) (6,8) (7,8) (8,8) (9,6) (10,8) | 0.9 |
| I8 | 1 / 4 / 6 | army_balanced | 4 | (1,7) (3,7) (5,8) (6,8) (9,6) (10,8) | 0.9 |
| I9 | 1 / 3 / 5 | army_balanced | 4 | (1,7) (3,7) (5,8) (6,8) (9,6) (10,8) | 0.9 |
| I10 | 1 / 1 / 1 (outside D-03) | army_balanced | 4 | (1,7) (3,7) (5,8) (6,8) (9,6) (10,8) | 0.9 |
| I11 | 0 / 0 / 0 (free, outside D-03) | army_balanced | 6 | (1,7) (3,7) (9,6) (10,7) | 1.0 |

D-03's cheapest prices do not rescue the first order for either bot, so the cost lever alone could not have met the bar;
the order lever did, and no price moved.

Each distinct order or price set was run once over the ten seeds. The orders marked with a tier count were run a second time with the tier counts recorded and gave the same wins and lost seeds, and a few were reached twice from different batches (the all-walls-at-the-end order, the ring-only order and the cost rows I2, I4 and I6), with the same result each time.

## Squads with walls

`army_balanced` with the wall runs bought: unit kills per military gold 4.64, tower kills per tower gold 5.22, **squad
value ratio 0.888**. The Phase 3 order (`army_balanced_no_walls`): 4.31 and 4.70, **0.915**. Both are above the owner's
0.8 bar (D-26), which stays pinned on `army_balanced_no_walls`, where Phase 3 measured it. The plan's first order
gave 1.133 (the army bot, hardly able to afford towers beside its walls, kills more per tower gold). The with-walls ratio
is a number for the owner, not a pin, and not a retune; it did not fall below the bar.

| Strategy | Military gold (mean) | Unit kills (mean) | Unit kills per military gold | Tower gold (mean) | Tower kills (mean) | Tower kills per tower gold | Squad value ratio |
|---|---:|---:|---:|---:|---:|---:|---:|
| no_build | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| greedy_economy | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| houses_first | 0.00 | 0.00 | 0.00 | 10.80 | 90.60 | 8.39 | 0.00 |
| towers_first | 0.00 | 0.00 | 0.00 | 8.00 | 77.40 | 9.68 | 0.00 |
| balanced | 0.00 | 0.00 | 0.00 | 15.60 | 107.50 | 6.89 | 0.00 |
| army_balanced | 7.20 | 33.40 | 4.64 | 3.60 | 18.80 | 5.22 | 0.89 |
| balanced_no_walls | 0.00 | 0.00 | 0.00 | 16.20 | 108.00 | 6.67 | 0.00 |
| army_balanced_no_walls | 7.20 | 31.00 | 4.31 | 4.40 | 20.70 | 4.70 | 0.92 |

## Goldens decision

D-14's reading, taken from 04-RESEARCH.md Open Question 1 (RESOLVED) and recorded in 04-04, 04-06 and plan 04-10:
success criterion 4 is the **same outcomes**, not new digests, and "regenerate the goldens once" is met by **one
deliberate regeneration commit** (this plan's Task 2: the bots' new orders, the re-pinned balance tests, this report,
full_idle's before and after digests) plus a **new fourth golden**, walls. The owner can ask for the literal reading
(every digest regenerated) at the UAT.

- **smoke** `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks) and **army**
  `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks): **unchanged by design, byte-identical
  across the whole phase.** Their frozen fixtures have no wall plot, and with no intact segment the pathing runs the exact
  Phase 3 expressions (04-04 and 04-06), so no event line moves. `git diff 75183fe HEAD -- tests/golden/smoke.json
  tests/golden/army.json` is empty and `bash tools/replay.sh --scenario=smoke|army --twice --expect-file=...` replays to the
  same digests.
- **walls** (new, Task 1 of this plan, commit `e3b8a74`): `bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58`,
  1961 ticks, seed 1, on a frozen self-contained fixture (a 60 m run with one gap, a tower, a 12-grunt crowd on night 1 that
  breaks a segment and 8 stragglers on night 2 that all walk round through the gap, then dawn restores the wall). Written once with
  `--write-golden`, checked twice in CI beside smoke and army. It pins the wall rules (building, damage, breaking, going
  round, restoring), which the other two goldens cannot see.
- **full_idle** (the shipped data played by the `balanced` bot, which now buys walls): **before**
  `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` at **6941** ticks (won), the value it has had since the Phase 3 retune and
  that plans 04-03 to 04-09 left unchanged; **after** `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` at **6911** ticks (won); two runs in one process
  agree (`REPLAY_OK scenario=full_idle`). It moved because the bot's order changed, not the simulation. full_idle stays
  **intentionally unpinned**: no `tests/golden/full_idle.json` is added and CI keeps running it only with `--twice`, because it plays
  the shipped data and moves on every legitimate retune; rule drift is caught by the smoke, army and walls goldens on frozen
  fixtures. **This report is therefore the only record of its before and after digests.**

## What the numbers say, and what they cannot

- **Walls are expensive for these bots.** The balanced bot earns about 22 gold in a whole run and the army bot about 15; a
  barricade costs a House and the first three towers cost 12. Bought where D-15's first order put them, the walls
  displaced a tower or a squad building and cost the balanced bot six seeds and the army bot eight. Free walls would have
  helped the balanced bot (9 of 10, I6) and still hurt the army bot (6 of 10, I11), so the army result is not only the
  price. A likely cause (not isolated by a separate run) is that the squads follow the king and the king walks round the
  walls through the gaps, which slows the formation.
  The with-walls rows are therefore a game in which the walls are bought only in the last days before the final nights
  (21 tiers over 20 runs) and never broken (0 segments in all 80 runs of the sweep). They show that buying them late
  changes no outcome; they do not show what mid-game walls are worth, and the earlier balanced candidates (E3 to E7, E11)
  that buy them around night 4 or 5 already lose a seed or two.
- **Walls broken is zero everywhere.** Only tier I walls were ever bought, late, and the shipped nights are small (at most
  40 enemies a night), so a crowd hardly ever formed at a wall and the break-or-detour rule chose the gap (a reading of the
  zeros, not a measurement of the rule). The walls golden is
  the place where the break-or-detour rule is pinned; the bot sweep does not exercise it. The owner's feel check of a
  wall under pressure is the part no bot covers.
- The bots build without riding and the defending king reacts perfectly. Their win counts measure the data, not how
  often a person wins, and whether buying a barricade before a tower is fun is the owner's call at the gate.
- Questions for the owner that the numbers raise, none of which this plan decided: should a barricade cost 1 (D-03
  allows it; it did not rescue the first order), should wall prices or the economy change so that walls are worth buying
  before night 6, and does the army bot's slowdown around walls (free walls still lose it four seeds) matter in play.
- Performance is a separate matter (04-FRAME-REPORT.md): PLAT-01 is recorded as not met, and the owner's route for it
  is decided after the gate. The balance numbers above were measured on the unchanged simulation.
