# Phase 3 Balance Report (D-08 retune for squads, plans 03-11 and 03-16)

## Round 2 (G-03-11)

Round 2 opens on 2026-10-13 (UTC), plan 03-16. Where this section and the Round 1 text below it disagree, Round 2 wins
(the 02-20 precedent). Plan 03-16 only measures: it changed no shipped data, no simulation code, no bot and no golden.
Plan 03-17 retunes against the targets below and plan 03-18 publishes the result; G-03-11 closes only when 03-17 and
03-18 are done. As in Round 1, the tables are measured by scripted bots; they are not the owner's sign-off and say
nothing about feel (D-08, Phase 2 D-18).

### The owner's decision and the four goals

Owner decision of 2026-10-13, quoted from `03-UAT.md` (test 11, gap G-03-11): "retune further now toward all four goals
at once". The four goals, as the UAT states the truth they serve: the balanced bot loses 2 to 3 of 10, squads are worth
their gold against towers, night 8 is larger than night 7, and the army bot loses 2 to 3 of 10. The pass may move squad
or tower values, costs or regeneration; nights 1 to 4 stay untouched.

### Targets (seeds 1 to 10, `bash tools/playtest.sh --seeds=10`)

| # | Goal | Target | How it is measured |
|---:|---|---|---|
| 1 | The balanced bot loses 2 to 3 of 10 | balanced wins 7 or 8 of seeds 1 to 10 (G-02-15) | `summaries.balanced.win_rate` times 10 |
| 2 | The army bot loses 2 to 3 of 10 | army_balanced wins 7 or 8 of seeds 1 to 10 | `summaries.army_balanced.win_rate` times 10 |
| 3 | Night 8 is larger than night 7 | the night 8 enemy total is strictly above the night 7 total | per-night `enemies`, any run that reached night 8 |
| 4 | Squads are worth their gold against towers | army_balanced's squad_value_ratio is at least 0.8 (provisional owner bar) | unit kills per military gold divided by tower kills per tower gold, both summed over seeds 1 to 10 (`summaries.army_balanced.squad_value_ratio`) |

Beside target 4: 0.8 is the planner's measurable reading of "squads worth their gold against towers" ("within reach" of
the towers, at least four fifths of their kills per gold). The owner confirmed it as D-26 in `03-CONTEXT.md` on
2026-10-13, so plan 03-17 reads 0.8 from there; a later owner override is recorded as an amendment of D-26 and replaces
this line. The bots measure, the owner judges feel (D-08, Phase 2 D-18). What the ratio cannot show: footmen that stand
in front of a tower get no kill credit for the tower kills they make possible, so it understates a squad that holds a
line, and only army_balanced buys squads, so the ratio compares its squads with its own (small) tower spend.

### What plan 03-17 may move

- Unit attack interval, attack range, guard and leash range and move speed; the archer's arrow speed and health (staying
  below the footman's).
- The Barracks and Archery Range tier costs (D-02 says they may move in the bot retune) and building health.
- Tower tier values.
- The king's regeneration numbers (owner decision, D-20 data).
- The slam's radius and damage, and a cooldown of about 9 s (D-19, CONTEXT discretion).
- The group counts of nights 5 to 8.

### What stays

- Nights 1 to 4 (5, 12, 21 and 21 enemies and their groups): the Phase 2 wall.
- Squad sizes 4 / 8 / 14 (D-01) and replacements every 10 / 7 / 4 s (D-05).
- The footman's 10 health and 1 damage, a fifth of the king (D-07).
- The king's 50 health, his passive 5 damage every 0.7 s at 3 m, and his speeds (carried forward).
- Starting gold, House income and base income.
- The castle numbers (owner decisions G-02-13).
- Every enemy number (the grunt's 6 hp is an owner decision).
- The bot strategies (`tools/replay/playtest_strategies.gd`, `playtest_bot.gd`).
- The pins of `tests/unit/test_military_data_contract.gd` for D-01, D-05 and D-07.

### Baseline (today's data)

Measured on the unchanged shipped data with `bash tools/playtest.sh --seeds=10` after plan 03-16's report columns landed:
six strategies by seeds 1 to 10, 60 runs, `PLAYTEST_OK runs=60`. The win columns match the Round 1 "after the retune"
table, as they must: the new columns only read events, so no digest moved (the smoke and army goldens replay to
`2599c7c2...` and `f7a967ed...`).

Six-strategy table:

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.9 / 2 / 4 | 4 | 9.2 | 5.0 | 1.8 |
| houses_first | 90% | 7.4 / 2 / 8 | 3 | 25.1 | 9.2 | 0.5 |
| towers_first | 30% | 7.2 / 6 / 8 | 8 | 6.9 | 6.0 | 3.8 |
| balanced | 90% | 7.4 / 2 / 8 | 3 | 24.0 | 5.8 | 0.5 |
| army_balanced | 80% | 7.5 / 5 / 8 | 6 | 15.3 | 16.4 | 1.1 |

Squad value table (new in plan 03-16; means are per run, the per-gold columns and the ratio divide sums over the ten
seeds):

| Strategy | Military gold (mean) | Unit kills (mean) | Unit kills per military gold | Tower gold (mean) | Tower kills (mean) | Tower kills per tower gold | Squad value ratio |
|---|---:|---:|---:|---:|---:|---:|---:|
| no_build | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| greedy_economy | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| houses_first | 0.00 | 0.00 | 0.00 | 13.20 | 116.10 | 8.80 | 0.00 |
| towers_first | 0.00 | 0.00 | 0.00 | 8.00 | 102.90 | 12.86 | 0.00 |
| balanced | 0.00 | 0.00 | 0.00 | 16.80 | 122.30 | 7.28 | 0.00 |
| army_balanced | 7.20 | 29.10 | 4.04 | 4.40 | 26.10 | 5.93 | 0.68 |

Only army_balanced buys squads, so only its ratio is meaningful (the others show 0.00 because of the zero guard). Its
squads kill 4.04 enemies per gold; its own towers kill 5.93 per gold; the ratio is 0.68. The tower-first bots get more
out of a tower gold (7.28 for balanced, 12.86 for towers_first) because every tower they buy stands where the enemies
come in, so measuring squads against the army bot's own small tower spend is the gentler comparison.

Per-seed outcomes (`w` won, `l` lost; the number is nights survived):

- balanced: seeds 1 to 8 and 10 won, seed 9 lost (survived 2, lost on night 3).
- army_balanced: seeds 2 to 8 and 10 won; seed 1 lost on night 7 (survived 6) and seed 9 lost on night 6 (survived 5).
- towers_first: seeds 1, 2 and 7 won; seeds 3, 4, 5, 6, 8 and 10 lost on night 8, seed 9 on night 7.

Night totals today: 5, 12, 21, 21, 25, 31, 39, 39.

How far today's data is from each target:

1. **Balanced bot loses 2 to 3 of 10:** 9 of 10 won, one win too many (needs 7 or 8 wins).
2. **Army bot loses 2 to 3 of 10:** 8 of 10 won, inside the bar already; the retune must keep it there while the other
   targets move.
3. **Night 8 larger than night 7:** 39 against 39, short by at least one enemy.
4. **Squad value:** squad_value_ratio 0.68 against 0.8, short by 0.12 (the army bot's squads need about 18 percent more
   kills per gold, or its towers about 15 percent fewer, to reach it).

How the run totals are counted: the gold of a build and of each upgrade is added once at the price of the tier bought, a
refused build adds nothing, and the free dawn rebuild adds nothing. Military is a building with a unit_id (Barracks,
Archery Range); towers are any other building with a tier that attacks; economy is the rest (the House). Unit kills
and tower kills are the sums of the nights' `kills_units` and `kills_towers`.

---

The Round 1 text of plan 03-11 follows unchanged.

Measured 2026-10-10 (UTC) by plan 03-11 with `bash tools/playtest.sh --seeds=10` on the shipped prototype map: six
strategies by seeds 1 to 10, 60 runs, about 105 s. The tables below are measured by scripted bots; they show what the
data does under those bots and nothing more. **They are not the owner's sign-off and not evidence that the squads feel
good.** The bots build without riding to the plots, react perfectly and cannot judge tension, readability or fun, so
the gate decision on feel stays with the owner (D-08, Phase 2 D-18) and is recorded through `/gsd-verify-work`.

Reproduce: `bash tools/playtest.sh --seeds=10` writes `build/playtest/report.json` and `report.md`. Seeds 1 to 10 are
the acceptance set (`tests/integration/test_balance_acceptance.gd`).

## What changed

Only the authored night counts in `data/maps/prototype_map.tres`. No cost, income, starting gold, squad size, unit stat
or timing moved (the plan's prohibition), so `tests/unit/test_military_data_contract.gd` needed no re-pin. Nights 1 to 4
are untouched: a x1.5 raise of nights 2 to 8 (night 3 from 21 to 32) made the balanced bot lose every seed on night 3,
and the Phase 2 shape of the early nights is the owner's wall.

| Night | Old total | New total | Groups that changed (old to new) |
|---:|---:|---:|---|
| 1 | 5 | 5 | none |
| 2 | 12 | 12 | none |
| 3 | 21 | 21 | none |
| 4 | 21 | 21 | none |
| 5 | 21 | 25 | west grunts 9 to 11, east grunts 8 to 10 |
| 6 | 22 | 31 | west grunts 6 to 8, east 5 to 7, north 7 to 10, west ranged 2 to 3, east ranged 2 to 3 |
| 7 | 27 | 39 | grunts 7 to 10 on each of the three roads, ranged 2 to 3 on each of the three roads |
| 8 | 33 | 39 | grunts 8 to 10 on each of the three roads (ranged stays 3 per road) |

Every night stays far under `MapConfig.MAX_ENEMIES_PER_NIGHT` (300), the totals never decrease, and
`MapConfig.validate()` is clean (pinned in `tests/unit/test_night_data_contract.gd`).

### Why these numbers

The first measurement on the unchanged data: `army_balanced` won 10 of 10 seeds, so the nights were too soft for an army.
The search then scaled the late nights and re-measured. The result is steep and quantised (group counts are small
integers): a uniform +30 % on nights 4 to 8 left `army_balanced` at 9 of 10, +40 % dropped it to 6 of 10, and +50 % on
nights 2 to 8 lost every seed on night 3 for the balanced bot. Two further constraints shaped the final curve:

- The night totals must not decrease (D-10), so night 8 cannot sit below night 7.
- The tower-opening bot (`towers_first`) falls on night 8 for every seed once that night reaches about 40 enemies, so
  night 8 stops at 39.

The accepted set (totals 5, 12, 21, 21, 25, 31, 39, 39) puts `army_balanced` at 8 of 10 (the Phase 2 bar of 7 or 8) and
keeps `towers_first` winning 2 of the 3 pinned seeds. Counts alone reached the bar, so no squad number was changed.

## Six-strategy table, seeds 1 to 10

After the retune (the current balance):

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.9 / 2 / 4 | 4 | 9.2 | 5.0 | 1.8 |
| houses_first | 90% | 7.4 / 2 / 8 | 3 | 25.1 | 9.2 | 0.5 |
| towers_first | 30% | 7.2 / 6 / 8 | 8 | 6.9 | 6.0 | 3.8 |
| balanced | 90% | 7.4 / 2 / 8 | 3 | 24.0 | 5.8 | 0.5 |
| army_balanced | 80% | 7.5 / 5 / 8 | 6 | 15.3 | 16.4 | 1.1 |

Before the retune (same code, original night counts):

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 3.1 / 2 / 5 | 4 | 10.0 | 5.6 | 2.0 |
| houses_first | 90% | 7.4 / 2 / 8 | 3 | 26.4 | 3.3 | 0.5 |
| towers_first | 100% | 8.0 / 8 / 8 | - | 7.0 | 2.0 | 2.6 |
| balanced | 90% | 7.4 / 2 / 8 | 3 | 24.1 | 2.9 | 0.5 |
| army_balanced | 100% | 8.0 / 8 / 8 | - | 17.5 | 11.2 | 0.2 |

Per-seed results after the retune (`w` won, `l` lost; the number is nights survived):

- balanced: seeds 1 to 8 and 10 won, seed 9 lost (survived 2, lost on night 3). Unchanged by the retune.
- army_balanced: seeds 2 to 8 and 10 won; seed 1 lost on night 7 (survived 6) and seed 9 lost on night 6 (survived 5).
- towers_first: seeds 1, 2 and 7 won; seeds 3, 4, 5, 6, 8 and 10 lost on night 8, seed 9 on night 7.
- greedy_economy: lost on nights 3 to 5 (it used to reach night 6).
- no_build: lost on night 2 every seed.

## Per night: army_balanced after the retune

Averaged over the runs that started each night (nights 7 and 8 have 9 and 8 runs because seeds 9 and 1 had already lost).

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Kills units | Buildings lost | Units lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 10.3 | 3.0 |
| 2 | 10 | 12.0 | 8.5 | 0.0 | 3.5 | 0.0 | 0.9 | 0.0 | 0.0 | 70.0 | 30.5 | 5.1 |
| 3 | 10 | 21.0 | 14.6 | 0.0 | 4.6 | 1.8 | 2.3 | 0.0 | 0.0 | 70.0 | 38.4 | 1.9 |
| 4 | 10 | 21.0 | 13.9 | 0.0 | 4.6 | 2.5 | 2.5 | 0.5 | 0.0 | 69.2 | 37.3 | 2.5 |
| 5 | 10 | 25.0 | 14.5 | 1.8 | 4.5 | 4.2 | 2.6 | 0.3 | 0.4 | 65.6 | 39.1 | 3.9 |
| 6 | 10 | 31.0 | 12.5 | 8.5 | 4.1 | 5.3 | 1.9 | 0.5 | 0.1 | 62.2 | 37.3 | 3.0 |
| 7 | 9 | 39.0 | 16.9 | 9.4 | 4.4 | 7.6 | 3.4 | 2.2 | 0.7 | 42.7 | 43.4 | 4.3 |
| 8 | 8 | 39.0 | 16.3 | 9.1 | 3.0 | 10.6 | 3.9 | 1.1 | 0.0 | 70.0 | 40.6 | 1.3 |

## What the numbers say, and what they cannot

- **Squads are not stronger than towers per gold under these bots.** Before the retune `army_balanced` won 10 of 10, but
  as the late nights grow it falls faster than the tower-heavy `balanced` bot (at +40 % on nights 4 to 8 `army_balanced`
  won 6 of 10 while `balanced` won 8). In the balanced bot's late nights towers do 18 to 30 of the 21 to 39 kills while
  the castle barely loses health; the army bot's castle loses health from night 5 on and it loses more buildings (16.4
  per run against 5.8). The squads do real work (units kill 4 to 11 enemies per late night) but the balanced order puts
  that gold into towers, and those kill more. This is a measurement of the data under bots that always follow with the footmen and hold the archers; a
  player who fights beside the squad, or posts the footmen where they shield a tower, may do better or worse. It is the
  first thing worth the owner's attention at the gate.
- **Buildings lost is high for the army bot** (16.4 per run, 5.8 for `balanced`). Its night orders send the footmen to
  follow the king and the bot has no notion of defending its own plots, so the likely cause is plots left uncovered;
  this was not isolated by a separate run. A real player can choose where the squads stand.
- **The balanced bot still loses 1 of 10, not the 2 or 3 the owner asked for (G-02-15).** Regeneration (plan 03-04)
  moved it from 2 losses to 1 and this retune does not move it again: the nights that were raised are late nights the
  tower-heavy order wins easily. Raising the early nights instead breaks the Phase 2 wall (see above). The two goals
  (balanced loses 2 or 3; the army bot loses 2 or 3) cannot both be reached by night counts alone with these squads; the
  owner decides which bar the nights serve.
- **Night 8 equals night 7 (39 each).** A larger last night ends the tower opening on every seed. If the owner wants a
  bigger finale, the squads or the towers have to give the tower opening more room first.
- The bots measure the data; the owner judges feel at the gate (D-08, Phase 2 D-18).

## Determinism and goldens

- Smoke golden digest unchanged: `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (frozen fixtures, no
  military plot).
- Army golden recorded by this plan: `tests/golden/army.json`, digest
  `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (seed 1, 1353 ticks, a win). It runs on its own
  frozen fixtures, so this retune did not move it.
- `full_idle` (shipped data, balanced bot) moved with the retune, by design and with no golden: old digest
  `91db5112b2041975d04ab464667528b33f5e04e8b486dad0a8687ce620f6efdc` (5140 ticks) to
  `ab4d17d91e197347f66e24008fffbc3f7061b0b1ab27de312423212797650b7a` (6199 ticks). Two runs in one process agree.

## Test suite cost

The full GUT suite took 351 s for 1243 tests after the replay task and 417 s for 1250 tests after the army balance matrix
(`test_balance_acceptance` now runs 10 more full army runs in `before_all`, and the late nights are bigger). RESEARCH A13
(the suite grows by the army matrix) holds: about 66 s more.
