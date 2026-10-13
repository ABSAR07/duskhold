# Phase 3 Balance Report (D-08 retune for squads, plans 03-11 and 03-16)

## Round 2 (G-03-11)

Round 2 opens on 2026-10-13 (UTC), plan 03-16. Where this section and the Round 1 text below it disagree, Round 2 wins
(the 02-20 precedent). Plan 03-16 only measures: it changed no shipped data, no simulation code, no bot and no golden.
Plan 03-17 retunes against the targets below and plan 03-18 publishes the result; G-03-11 closes only when 03-17 and
03-18 are done.
Plans 03-17 and 03-18 have run: the sections from `### Outcome` down hold the result, and the Round 1 tables below
them are superseded by the `### After Round 2` tables. As in Round 1, the tables are measured by scripted bots; they are not the owner's sign-off and say
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

### Outcome

Plan 03-17 ended in **outcome (a): all four targets are met inside the allowed levers.** No locked value moved (D-01 squad
sizes, D-05 replacements, D-07 footman, the king's numbers, starting gold, income), so there was no hand-back to the owner
and no D-26 amendment. Outcome (b), the owner choosing at a hand-back, was not needed; it would have been a successful path
of the plan, not a failure.

The squad-value bar used is **0.8, the owner's bar** (D-26, confirmed by the owner on 2026-10-13; no override exists in
`03-CONTEXT.md`). It is not a planner's guess any more: it is what the owner asked for.

Two numbers moved: tower tier 1 fires every 0.9 s (was 0.8 s) and night 8's north road holds 11 grunts (was 10). Measured
on the committed data by `bash tools/playtest.sh --seeds=10` (`PLAYTEST_OK runs=60`, run again for this report and equal to
03-17's final matrix on every figure below):

| # | Goal | Bar | Before (baseline) | After Round 2 | Met |
|---:|---|---|---|---|---|
| 1 | The balanced bot loses 2 to 3 of 10 | 7 or 8 wins | 9 wins (seed 9 lost) | **8 wins** (seed 3 lost on night 8, seed 9 on night 3) | yes |
| 2 | The army bot loses 2 to 3 of 10 | 7 or 8 wins | 8 wins | **8 wins** (seed 1 lost on night 7, seed 9 on night 6) | yes |
| 3 | Night 8 is larger than night 7 | strictly above | 39 and 39 | **40 and 39** | yes |
| 4 | Squads are worth their gold against towers | squad_value_ratio at least 0.8 | 0.681 (4.04 / 5.93) | **0.915** (4.31 unit kills per military gold / 4.70 tower kills per tower gold) | yes |

Two findings for the owner come with it. The tower route lost its wins: **towers_first wins 0 of 10** (it was 3 of 10) and
**houses_first wins 4 of 10** (it was 9 of 10). See "What the numbers say" below.

G-03-11 is closed by plans 03-16 (the metric and the baseline), 03-17 (the retune) and 03-18 (this report); whether the new
balance feels right is still the owner's call at the gate (test 15).

### What changed

| File | Value | Old | New | Allowed by |
|---|---|---:|---:|---|
| `data/buildings/tower.tres` | tier 1 `attack_interval` | 0.8 | 0.9 | "tower tier values" on the may-move list (owner decision 2026-10-13, D-27) |
| `data/maps/prototype_map.tres` | night 8 north road grunts (`Resource_group_n8_north` `count`) | 10 | 11 | "group counts of nights 5 to 8" on the may-move list (D-27); night 8 total 39 to 40 |

Nothing else under `data/` moved. Nights 1 to 4 (5, 12, 21, 21), squad sizes 4 / 8 / 14, replacements 10 / 7 / 4 s, the
footman, the archer, the king and every enemy are as before. The night totals are now 5, 12, 21, 21, 25, 31, 39, 40. Tier 1
is a 30 Hz quantised lever: 0.8 s is 24 ticks, 0.9 s is 27 ticks.

### Search log

Copied from 03-17's SUMMARY. 29 candidates (c01 to c29) of the 30 allowed were measured, each in a private copy of the
project so the repository's data was never edited during the search, plus the baseline row, which matches the 03-16
baseline exactly. Columns: wins of balanced, army_balanced and towers_first over seeds 1 to 10 (towers_first's wins on its
pinned seeds 1 to 3 in brackets), army_balanced's squad_value_ratio (unit kills per military gold / tower kills per tower
gold), and the night 5 to 8 totals. "T1" is tower tier 1, "T2" tier 2.

| Row | Values changed (old to new) | bal | army | tf | ratio | Nights 5-8 |
|---|---|---:|---:|---:|---:|---|
| baseline | none (committed data) | 9 | 8 | 3 (2) | 0.681 (4.04/5.93) | 25 31 39 39 |
| c01 | footman attack_interval 0.6 to 0.5 | 9 | 9 | 3 (2) | 0.648 | 25 31 39 39 |
| c02 | footman attack_interval 0.6 to 0.5; archer attack_interval 0.9 to 0.75 | 9 | 9 | 3 (2) | 0.658 | 25 31 39 39 |
| c03 | Barracks and Archery Range tier 1 cost 4 to 3 | 9 | 10 | 3 (2) | 0.633 | 25 31 39 39 |
| c04 | archer attack_range 8.5 to 10.0 | 9 | 8 | 3 (2) | 0.679 | 25 31 39 39 |
| c05 | tower T1 cost 4 to 5 | 8 | 2 | 1 (1) | 0.978 | 25 31 39 39 |
| c06 | tower T2 cost 6 to 8 | 9 | 8 | 3 (2) | 0.681 | 25 31 39 39 |
| c07 | tower T2 attack_damage 6 to 5 | 9 | 8 | 3 (2) | 0.681 | 25 31 39 39 |
| c08 | tower T1 attack_interval 0.8 to 1.0 | 4 | 6 | 0 (0) | 1.202 | 25 31 39 39 |
| c09 | tower T1 cost 4 to 5; T2 cost 6 to 7 | 8 | 2 | 1 (1) | 0.978 | 25 31 39 39 |
| c10 | tower T1 attack_interval 0.8 to 0.9 | 8 | 8 | 0 (0) | 0.895 (4.21/4.70) | 25 31 39 39 |
| c11 | tower T1 attack_interval 0.8 to 0.85 | 9 | 8 | 0 (0) | 0.792 | 25 31 39 39 |
| c12 | tower T1 attack_interval 0.8 to 0.95 | 6 | 4 | 0 (0) | 1.183 | 25 31 39 39 |
| c13 | tower T1 attack_range 9.0 to 8.0 | 9 | 8 | 3 (1) | 0.668 | 25 31 39 39 |
| c14 | tower T1 max_health 50 to 40 | 9 | 7 | 0 (0) | 0.882 | 25 31 39 39 |
| **c15** | **tower T1 attack_interval 0.8 to 0.9; night 8 north grunts 10 to 11 (shipped)** | **8** | **8** | **0 (0)** | **0.915 (4.31/4.70)** | **25 31 39 40** |
| c16 | c10 and night 8 grunts 10 to 11 on west, east and north | 8 | 8 | 0 (0) | 0.954 | 25 31 39 42 |
| c17 | c10 and night 8 north ranged 3 to 4 | 8 | 8 | 0 (0) | 0.905 | 25 31 39 40 |
| c18 | c10 and tower T1 attack_range 9.0 to 10.0 | 9 | 7 | 0 (0) | 0.876 | 25 31 39 39 |
| c19 | c10 and night 7 north grunts 10 to 9 | 8 | 9 | 0 (0) | 0.868 | 25 31 38 39 |
| c20 | king regen_delay_seconds 1.0 to 1.5 | 9 | 8 | 3 (2) | 0.700 | 25 31 39 39 |
| c21 | king regen_fraction_per_second 0.1 to 0.07 | 9 | 9 | 2 (1) | 0.669 | 25 31 39 39 |
| c22 | king regen_delay_seconds 1.0 to 2.0 | 9 | 8 | 2 (1) | 0.693 | 25 31 39 39 |
| c23 | tower T1 attack_interval 0.8 to 0.85; T1 max_health 50 to 60 | 9 | 9 | 3 (2) | 0.607 | 25 31 39 39 |
| c24 | tower T1 attack_interval 0.8 to 0.9; T1 max_health 50 to 60 | 9 | 8 | 0 (0) | 0.697 | 25 31 39 39 |
| c25 | c15 and tower T1 projectile_speed 18 to 24 | 8 | 6 | 0 (0) | 1.013 | 25 31 39 40 |
| c26 | tower T1 attack_interval 0.8 to 0.88; night 8 north grunts 10 to 11 | 8 | 8 | 0 (0) | 0.915 | 25 31 39 40 |
| c27 | tower T1 attack_interval 0.8 to 0.9; T1 cost 4 to 3; night 8 north grunts 10 to 11 | 10 | 8 | 3 (0) | 0.710 | 25 31 39 40 |
| c28 | tower T1 attack_interval 0.8 to 1.0; T1 cost 4 to 3; night 8 north grunts 10 to 11 | 10 | 7 | 0 (0) | 0.838 | 25 31 39 40 |
| c29 | tower T1 attack_interval 0.8 to 0.9; T1 attack_range 9.0 to 9.5; night 8 north grunts 10 to 11 | 8 | 6 | 0 (0) | 0.984 | 25 31 39 40 |

c15, c16, c17 and c26 meet all four goals (c10 misses the night goal, c19 the army band). c15 was chosen because it moves
the fewest values: two numbers, one tower interval and one night count. c26 equals c15 because 0.88 s rounds to the same 27
ticks. Per seed in c15 and in the shipped data: balanced lost seeds 3 and 9, army_balanced lost seeds 1 and 9.

Levers tried and ruled out, and why:

- **Squad speed and cost (c01, c02, c03, c04):** faster footman or archer shots and a cheaper tier 1 keep the army alive
  (army wins 9 and 10) and the ratio goes down, because a surviving army buys every tier and the higher tiers earn fewer
  kills per gold. The archer's longer reach changed nothing measurable. Squad buffs cannot reach 0.8 while the army has to
  stay at 7 or 8 wins.
- **Tower tier 2 (c06, c07):** cost and damage changes gave a result identical to the baseline on every column. Tier 2
  does not influence any bot result, so it is not a lever.
- **Tower tier 1 cost (c05, c09, c27, c28):** cost 5 collapses the army to 2 of 10 wins; cost 3 hands the balanced bot 10
  of 10.
- **Tower tier 1 interval:** steep and quantised to 30 Hz steps. 0.85 s is not enough (c11: balanced still 9), 0.95 s and
  1.0 s are too much (c08, c12: balanced 4 and 6, army 6 and 4). 0.9 s is the window.
- **Tower tier 1 range, health, arrow speed (c13, c14, c18, c23, c24, c25, c29):** range 8 and health 60 do nothing for the
  goals; health 40, range 9.5 and 10 and arrow speed 24 either move the army out of its 7 to 8 band or leave the balanced
  bot at 9.
- **King regeneration (c20, c21, c22):** the balanced bot stays at 9 wins and the ratio stays near 0.7, as plan 03-04 had
  shown. Regeneration does not move the goals.
- **Night counts alone (c16, c17, c19):** only the night 8 goal needs them. One grunt is the smallest change that makes
  night 8 larger than night 7; +3 grunts (c16) or a fourth ranged enemy (c17) also meet the goals; lowering night 7 (c19)
  made the army win 9.
- **Locked values:** none was needed. Squad sizes, replacement times, the footman and the king were never touched, and no
  owner unlock was requested.

### After Round 2

Measured on the committed data with `bash tools/playtest.sh --seeds=10` (`PLAYTEST_OK runs=60`), seeds 1 to 10, shipped
prototype map. The bots build instantly without riding, so these are measurements of the data, not of play.

Six-strategy table:

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.9 / 2 / 4 | 4 | 9.2 | 5.0 | 1.8 |
| houses_first | 40% | 6.7 / 2 / 8 | 7 | 21.1 | 14.7 | 1.1 |
| towers_first | 0% | 6.1 / 6 / 7 | 7 | 6.1 | 5.9 | 2.6 |
| balanced | 80% | 7.3 / 2 / 8 | 3 | 22.2 | 10.4 | 0.6 |
| army_balanced | 80% | 7.5 / 5 / 8 | 6 | 15.0 | 17.6 | 1.3 |

Before Round 2 (the baseline above): houses_first 90%, towers_first 30%, balanced 90%, army_balanced 80%; the other two
rows are unchanged.

Squad value per gold (means per run; the per-gold columns and the ratio divide sums over the ten seeds):

| Strategy | Military gold (mean) | Unit kills (mean) | Unit kills per military gold | Tower gold (mean) | Tower kills (mean) | Tower kills per tower gold | Squad value ratio |
|---|---:|---:|---:|---:|---:|---:|---:|
| no_build | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| greedy_economy | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| houses_first | 0.00 | 0.00 | 0.00 | 10.80 | 90.60 | 8.39 | 0.00 |
| towers_first | 0.00 | 0.00 | 0.00 | 8.00 | 77.40 | 9.68 | 0.00 |
| balanced | 0.00 | 0.00 | 0.00 | 16.20 | 108.00 | 6.67 | 0.00 |
| army_balanced | 7.20 | 31.00 | 4.31 | 4.40 | 20.70 | 4.70 | 0.92 |

The ratio is 0.915 before rounding (4.3056 / 4.7045); the 0.92 in the table is that value to two decimals. Only
army_balanced buys squads, so only its ratio is meaningful.

Per night, army_balanced (averaged over the runs that started each night; nights 7 and 8 have 9 and 8 runs because seeds 9
and 1 had already lost):

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Kills units | Buildings lost | Units lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 10.3 | 3.0 |
| 2 | 10 | 12.0 | 8.5 | 0.0 | 3.5 | 0.0 | 0.9 | 0.0 | 0.0 | 70.0 | 30.5 | 5.1 |
| 3 | 10 | 21.0 | 14.6 | 0.0 | 4.6 | 1.8 | 2.3 | 0.0 | 0.0 | 70.0 | 38.4 | 1.9 |
| 4 | 10 | 21.0 | 13.9 | 0.0 | 4.6 | 2.5 | 2.5 | 0.5 | 0.0 | 69.2 | 37.3 | 2.5 |
| 5 | 10 | 25.0 | 14.8 | 1.5 | 4.2 | 4.5 | 2.6 | 0.3 | 0.4 | 65.6 | 39.4 | 3.9 |
| 6 | 10 | 31.0 | 14.3 | 6.5 | 4.3 | 5.3 | 2.6 | 0.3 | 0.1 | 62.4 | 37.9 | 2.7 |
| 7 | 9 | 39.0 | 17.7 | 7.1 | 5.3 | 8.6 | 3.7 | 2.4 | 0.8 | 34.9 | 43.8 | 4.0 |
| 8 | 8 | 40.0 | 15.8 | 7.9 | 4.9 | 11.5 | 4.3 | 0.4 | 0.1 | 70.0 | 40.8 | 1.0 |

Per-seed results (`won` or `lost`; the number is nights survived):

- **balanced:** seeds 1, 2, 4, 5, 6, 7, 8 and 10 won; seed 3 lost (survived 7, lost on night 8); seed 9 lost (survived 2,
  lost on night 3).
- **army_balanced:** seeds 2 to 8 and 10 won; seed 1 lost (survived 6, lost on night 7); seed 9 lost (survived 5, lost on
  night 6).
- **towers_first:** every seed lost: seeds 1 to 7, 9 and 10 on night 7 (survived 6), seed 8 on night 8 (survived 7).
- houses_first (for completeness): seeds 1, 2, 5 and 7 won; seeds 3, 4 and 8 lost on night 8, seeds 6 and 10 on night 7,
  seed 9 on night 3.

Each target against its bar:

| # | Target | Bar | Measured | Result |
|---:|---|---|---|---|
| 1 | balanced wins | 7 or 8 of 10 | 8 | met |
| 2 | army_balanced wins | 7 or 8 of 10 | 8 | met |
| 3 | night 8 against night 7 | 40 above 39 | 40 and 39 | met |
| 4 | squad_value_ratio | at least 0.8 (D-26, the owner's bar) | 0.915 | met |

### What the numbers say, and what they cannot

- **The tower opening paid for the balance.** The slower tier 1 tower is what lowers the balanced bot to 8 wins and lifts
  the army bot's ratio, and it does so for every route that leans on tier 1 towers. **towers_first now wins no seed (0 of
  10, it was 3 of 10)**: it falls on night 7 on nine seeds and on night 8 on seed 8. Its pinned test moved from "wins at
  least two of three" to "survives at least six nights on every pinned seed", as the plan allowed when the data cannot keep
  a win. 29 candidates were searched and none that met the four goals left the pure tower opening a win: every tower-shot
  nerf that moved the balanced bot also took towers_first to 0, and the candidates that kept its wins (c13, c20, c27)
  left the balanced bot at 9 or 10. **houses_first fell from 9 wins to 4 of 10** for the same reason (balanced lost one
  seed as intended, houses_first lost five). If the owner wants the tower opening to win again, it costs one of the four
  goals.
- The bots build without riding to plots and react perfectly, so a win count here is a measurement of the data, not a
  prediction of how often a person wins.
- **Footmen that shield a tower get no kill credit.** The ratio counts the kills a unit makes, not the kills it makes
  possible, so a squad that holds a line in front of a tower is understated; and only army_balanced buys squads, so the
  ratio compares its squads with its own small tower spend (4.40 gold of towers a run).
- The army bot's footmen follow the king and its archers hold; it loses 17.6 buildings a run (the balanced bot 10.4, up
  from 5.8 before Round 2). Plots it leaves uncovered are the likely cause, not isolated by a
  separate run.
- The bots measure the data; the owner judges feel at the gate (D-08, Phase 2 D-18). In particular whether a tier 1 tower
  firing every 0.9 s still feels rewarding as an opening, and whether a fight beside the squad is worth the gold.

### Determinism and goldens

In G-03-11's words: the smoke and army goldens stay byte-identical (they replay frozen fixture copies per the 03-11
design), and the full_idle digest before and after is recorded here. Copied from 03-17's SUMMARY.

- Smoke golden: `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (703 ticks) replays to
  `tests/golden/smoke.json`, byte-identical (`git diff --quiet HEAD -- tests/golden/smoke.json tests/golden/army.json`
  exits 0).
- Army golden: `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (1353 ticks) replays to
  `tests/golden/army.json`, byte-identical.
- **full_idle** (shipped data, balanced bot, no golden):
  - before the first Round 2 data edit: digest `ab4d17d91e197347f66e24008fffbc3f7061b0b1ab27de312423212797650b7a`, **6199
    ticks**, won.
  - after the retune: digest `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064`, **6941 ticks**, won; two
    runs in one process agree (`REPLAY_OK scenario=full_idle`). It moves by design, because the shipped tower data changed.
- The full GUT suite after the retune: 150 scripts, 1397 tests, all passing, 621.8 s (03-17's run; before it 1392 tests).
  Lint clean on 265 files.

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
