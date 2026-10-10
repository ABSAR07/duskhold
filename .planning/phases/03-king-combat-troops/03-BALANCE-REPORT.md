# Phase 3 Balance Report (D-08 retune for squads, plan 03-11)

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
