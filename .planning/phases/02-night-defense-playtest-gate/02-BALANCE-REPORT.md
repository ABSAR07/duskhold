# Phase 2 Balance Report (playtest gate evidence, D-18)

Produced by plan 02-10 with `bash tools/playtest.sh --seeds=10` on the shipped prototype map. The tables
below are measured by scripted bots; they show what the data does under those bots and nothing more.
**They are not the owner's sign-off and not evidence that the loop is fun.** The gate decision stays
with the owner (D-18) and is recorded through `/gsd-verify-work`.

Reproduce: `bash tools/playtest.sh` (all five strategies, seeds 1 to 10, about 45 s) writes
`build/playtest/report.json` and `report.md`. Seeds 1 to 10 are the acceptance set; a 30-seed run of the
final data gave the same win rates for `balanced` and `houses_first` (100% each).

## Acceptance checks (measured on the final data, seeds 1 to 10)

| Check | Required (D-10, D-04) | Measured | Result |
|---|---|---|---|
| `balanced` win rate | at least 0.8 | 1.0 (10 of 10 won) | pass |
| `greedy_economy` win rate | at most 0.2 | 0.0 (0 of 10 won) | pass |
| `greedy_economy` median loss night | 3 to 6 | 4 | pass |
| `no_build` loses by night 3 | max nights survived at most 2 | 0 survived; lost night 1 on every seed | pass |
| King alone vs a group of 3 grunts | kills all, no knockout | 3 of 3 killed, 0 knockouts, castle untouched (`test_king_sturdiness`) | pass |
| King in the shipped night-4 wave | knocked out at least once | knocked out, down when the loop stopped (`test_king_sturdiness`) | pass |
| Every started night ends | DAWN, WON or LOST within 300 s, no timeout, seeds 1 to 10 | all nights ended, none near the budget (`test_every_night_ends`) | pass |
| Smoke golden | digest unchanged | `2599c7c2...` still matches (`bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`) | pass |
| `full_idle` replay | two runs agree | REPLAY_OK, won in 6244 ticks, digest `a25aa7fd...` | pass |

The acceptance thresholds are Claude's reading of D-10 ("winnable with good choices", "greedy or careless
play should lose around the middle nights"); they are listed here so the owner can overrule them.

## Final balance table

### Summary

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 0.0 / 0 / 0 | 1 | 0.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 3.5 / 3 / 4 | 4 | 8.5 | 5.0 | 2.1 |
| houses_first | 100% | 8.0 / 8 / 8 | - | 18.0 | 4.6 | 1.4 |
| towers_first | 0% | 5.1 / 5 / 6 | 6 | 0.0 | 0.0 | 1.9 |
| balanced | 100% | 8.0 / 8 / 8 | - | 18.0 | 4.8 | 1.4 |

### Per night: no_build

| Night | Runs | Enemies | Kills king | Kills towers | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 1.1 | 0.0 | 0.0 | 0.0 | 0.0 | 31.9 | 4.0 |

### Per night: greedy_economy

| Night | Runs | Enemies | Kills king | Kills towers | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 70.0 | 12.7 | 2.0 |
| 2 | 10 | 8.0 | 8.0 | 0.0 | 0.0 | 0.0 | 70.0 | 13.9 | 3.0 |
| 3 | 10 | 11.0 | 11.0 | 0.0 | 2.0 | 0.6 | 49.6 | 37.8 | 3.0 |
| 4 | 10 | 14.0 | 10.9 | 0.0 | 2.0 | 1.0 | 4.4 | 39.1 | 2.5 |
| 5 | 5 | 18.0 | 7.0 | 0.0 | 2.0 | 1.0 | 0.0 | 33.4 | 1.0 |

### Per night: houses_first

| Night | Runs | Enemies | Kills king | Kills towers | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 70.0 | 12.7 | 2.0 |
| 2 | 10 | 8.0 | 8.0 | 0.0 | 0.0 | 0.0 | 70.0 | 13.9 | 3.0 |
| 3 | 10 | 11.0 | 11.0 | 0.0 | 2.0 | 0.6 | 49.6 | 37.8 | 4.0 |
| 4 | 10 | 14.0 | 7.0 | 7.0 | 0.0 | 0.0 | 70.0 | 17.0 | 3.0 |
| 5 | 10 | 18.0 | 9.0 | 9.0 | 0.0 | 0.8 | 70.0 | 24.9 | 6.0 |
| 6 | 10 | 22.0 | 7.0 | 15.0 | 0.0 | 0.0 | 70.0 | 20.3 | 5.0 |
| 7 | 10 | 27.0 | 2.1 | 24.9 | 0.0 | 0.0 | 70.0 | 17.2 | 4.0 |
| 8 | 10 | 33.0 | 8.3 | 24.7 | 2.6 | 0.0 | 70.0 | 38.0 | 1.0 |

### Per night: towers_first

| Night | Runs | Enemies | Kills king | Kills towers | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 0.7 | 4.3 | 0.0 | 0.0 | 70.0 | 8.6 | 0.0 |
| 2 | 10 | 8.0 | 6.2 | 1.8 | 0.0 | 0.0 | 70.0 | 12.2 | 0.0 |
| 3 | 10 | 11.0 | 5.5 | 5.5 | 0.0 | 0.0 | 70.0 | 20.4 | 0.0 |
| 4 | 10 | 14.0 | 7.0 | 7.0 | 0.0 | 0.0 | 70.0 | 15.9 | 0.0 |
| 5 | 10 | 18.0 | 9.0 | 9.0 | 0.0 | 0.8 | 70.0 | 24.6 | 0.0 |
| 6 | 10 | 22.0 | 7.2 | 8.0 | 0.0 | 1.0 | 0.2 | 36.1 | 0.0 |
| 7 | 1 | 27.0 | 6.0 | 9.0 | 0.0 | 1.0 | 0.0 | 33.2 | 0.0 |

### Per night: balanced

| Night | Runs | Enemies | Kills king | Kills towers | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 70.0 | 12.7 | 2.0 |
| 2 | 10 | 8.0 | 8.0 | 0.0 | 0.0 | 0.0 | 70.0 | 13.9 | 3.0 |
| 3 | 10 | 11.0 | 11.0 | 0.0 | 2.0 | 0.6 | 49.6 | 37.8 | 4.0 |
| 4 | 10 | 14.0 | 7.0 | 7.0 | 0.0 | 0.0 | 70.0 | 17.0 | 3.0 |
| 5 | 10 | 18.0 | 9.0 | 9.0 | 0.0 | 0.8 | 70.0 | 24.9 | 6.0 |
| 6 | 10 | 22.0 | 7.0 | 15.0 | 0.0 | 0.0 | 70.0 | 20.3 | 5.0 |
| 7 | 10 | 27.0 | 2.1 | 24.9 | 0.0 | 0.0 | 70.0 | 17.2 | 4.0 |
| 8 | 10 | 33.0 | 8.3 | 24.7 | 2.8 | 0.0 | 69.8 | 38.0 | 4.0 |

## Before the tuning pass

The same matrix on the data as plan 02-02 to 02-07 left it (king 30 hp, castle 40 hp, tower I 20 hp). With
the strategies as they stood then (`balanced` opening with a tower, so no income) no run survived past night 4, and no strategy won a single run:

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 0.0 / 0 / 0 | 1 | 0.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.0 / 2 / 2 | 3 | 5.0 | 2.0 | 2.0 |
| houses_first | 0% | 2.0 / 2 / 2 | 3 | 5.0 | 2.0 | 2.0 |
| towers_first | 0% | 2.6 / 2 / 4 | 3 | 0.0 | 1.7 | 2.6 |
| balanced | 0% | 2.6 / 2 / 4 | 3 | 0.0 | 1.7 | 2.6 |

(The `balanced` and `houses_first` rows above came from build orders that were later corrected: `balanced`
originally opened with a tower, which spends the 4 starting gold and leaves a run with no income at all.
The corrected orders are in `tools/replay/playtest_strategies.gd`; the before and after comparison that
matters is that the king and towers could not hold nights 3 to 4 on the old numbers, for any order.)

## What changed (data only)

Only combat numbers moved. Costs, dawn incomes, starting gold, the 15 s respawn cap, the respawn start and
step (6 s and 4 s), the 8 nights, the spawn-point progression and every wave group (counts, delays,
intervals: totals stay 5, 8, 11, 14, 18, 22, 27, 33) and both enemy types are as they were.

| File | Value | Before | After | Reason |
|---|---|---|---|---|
| `data/king/king.tres` | `max_health` | 30 | 50 | D-04: sturdy enough to hold nights 1 to 3 alone; he was knocked out on night 2 against 8 grunts |
| `data/king/king.tres` | `attack_damage` | 3 | 5 | A king alone must carry nights 1 to 3 (no tower affordable before day 4), but not beyond night 4 |
| `data/king/king.tres` | `attack_interval` | 0.8 | 0.7 | Same: about 7 damage per second |
| `data/maps/prototype_map.tres` | `castle_max_health` | 40 | 70 | The old castle fell on night 3 in every run; a leak through night 3 now costs hp, not the run |
| `data/buildings/house.tres` | tier I / II / III `max_health` | 8 / 12 / 16 | 12 / 18 / 24 | Houses are the income; losing them to a few strikes made greedy and balanced collapse together |
| `data/buildings/tower.tres` | tier I `attack_range` | 8.0 | 9.0 | Reaches skirmishers (range 7) before they reach the plot |
| `data/buildings/tower.tres` | tier I `attack_damage` | 2 | 3 | Towers killed about 2 enemies a night on the old numbers; a tower is the thing greedy play skips (D-10) |
| `data/buildings/tower.tres` | tier I `max_health` | 20 | 50 | Three grunts killed a tower in about 3 s; 45 hp gave a 90% win rate over 30 seeds, 48 or more gave 100% |
| `data/buildings/tower.tres` | tier I `attack_interval` | 1.0 | 0.8 | Same reason as the damage |
| `data/buildings/tower.tres` | tier II `attack_range` | 10.0 | 10.5 | Tier II stays ahead of tier I (D-13) |
| `data/buildings/tower.tres` | tier II `attack_damage` | 4 | 6 | Tier II stays clearly stronger than tier I (D-13) |
| `data/buildings/tower.tres` | tier II `max_health` | 30 | 70 | Tier II stays sturdier than tier I |
| `data/buildings/tower.tres` | tier II `attack_interval` | 0.8 | 0.7 | Tier II stays faster than tier I |

Tools changed alongside (not data): the bot's telegraph preference only reorders the first build of each
tower plot (moving upgrades ahead of an unbuilt plot starved the north road and lost night 7), and the
`full_idle` replay scenario now plays the `balanced` bot, because an idle king loses on night 1 (plan 02-09
asked for this). The smoke golden does not read `data/`, so it did not move.

No existing test pinned a number that this pass changed: the full suite stayed green without edits to any
older test (714 tests in 84 scripts).

## What the shape of the numbers says

- **Night 3 is the first danger.** The king alone faces 11 grunts from two roads before any tower can be
  afforded (the first tower comes on day 4 under the `balanced`, `houses_first` and `greedy_economy` orders, which open with Houses). Under the House-opening strategies the castle falls to about 50 of 70 hp on average, with 0.6 knockouts per run and 2 Houses lost. This is where `greedy_economy`
  starts to break: it never builds a tower, loses on night 4 (castle 4 hp) or night 5 and never survives
  night 5.
- **From night 4 the towers take over.** They land 50 to 92% of the kills, the castle stays within 0.2 hp of full from night 4 on for `balanced`, and the king is knocked out about 0.8 times on night 5 only.
- **Nights 6 and 7 are easy once all three towers stand; night 8 is the long one** (38 s on average, about
  3 buildings lost). If the owner finds the middle of the run too calm, the knobs are the three-road nights
  6 and 7 (wave data) and the tier I tower, not the king.
- **The economy decides the choices.** All seven dawns pay about 18 gold in total, so a run affords roughly three Houses, three towers and one or two more buildings. `towers_first` shows the trap: its 4 starting gold goes
  into one tower, Houses are never affordable, income stays at 0 and it dies on night 6. That economy is the
  owner's Phase 1 tuning and was left alone; it is flagged because it leaves few real trade-offs after the
  third House.
- **`balanced` and `houses_first` play the same opening** (three Houses, then the three towers) and only
  differ after about 18 gold, which a run barely reaches, so their rows are close.
- **`no_build` is a sanity check, not a gauge.** An idle king at the castle front cannot reach grunts that stop at the castle's west edge (about 7 m from him), so the castle falls on night 1.

## What the bots cannot tell you

These bots are tools for measuring the data, not stand-ins for a player:

- They **build instantly without riding to the plots.** A real player spends day time riding to a plot and
  holding the action key; the bots pay nothing for that.
- They **react perfectly.** The defending king sprints to the enemy nearest the castle on the very tick it
  appears, never mis-steps and never retreats; the king in a real run is steered by hand.
- They **start every night at once**, so they never trade day time for anything and never use the telegraph
  to prepare beyond reordering tower plots.
- **Seeds only move spawn scatter** (3 m around each spawn point), so a win rate over 10 seeds is nearly a
  deterministic yes or no per strategy, not a probability of a human winning.
- They **cannot judge tension, readability or fun**: whether night 3 feels fair, whether the telegraph icons
  are noticed, whether the king's knockouts feel like a cost or an annoyance, whether 7 to 11 grunts on screen
  are readable. That is the owner's call at the gate (D-18).
- They have **no memory of a first run**: a player who has never seen the waves will be worse than these bots
  on night 3 and on the choice of the first purchase.

## Open points for the owner at the gate

- Does the first day feel like a real choice with only 4 gold (two Houses, or one tower that earns nothing)?
- Is night 3 (the king alone against two roads) the right first scare, and does losing 2 Houses there feel fair?
- Are nights 6 and 7 too calm once the three towers stand?
- Dawn repair is full (RESEARCH Open Question 1, resolved in plan 02-06 as full repair); confirm or ask for a
  different rule.
