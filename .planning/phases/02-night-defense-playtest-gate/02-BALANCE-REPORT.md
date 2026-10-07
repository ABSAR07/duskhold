# Phase 2 Balance Report (playtest gate evidence, D-18)

Round 1 was produced by plan 02-10 (round 2 below by plan 02-16, round 3 above it by plan 02-20, round 4 above that by plan 02-22) with `bash tools/playtest.sh --seeds=10` on the shipped prototype map. The tables
below are measured by scripted bots; they show what the data does under those bots and nothing more.
**They are not the owner's sign-off and not evidence that the loop is fun.** The gate decision stays
with the owner (D-18) and is recorded through `/gsd-verify-work`.

Reproduce: `bash tools/playtest.sh` (all five strategies, seeds 1 to 10, about 45 s) writes
`build/playtest/report.json` and `report.md`. Seeds 1 to 10 are the acceptance set; a 30-seed run of the
final data gave the same win rates for `balanced` and `houses_first` (100% each).

## Round 4 (gap closure G-02-18, 2026-10-07)

Written by plan 02-22 after plan 02-21 changed the king's walk. Nothing was re-measured with the bots, on purpose,
and this section says why nothing in the tables below could have moved. Same disclaimer as above: scripted bots and
Claude's reading of them are **not the owner's sign-off**; only the owner's round-4 replay and decision, recorded
through `/gsd-verify-work`, answer the round-3 gate (G-02-18, D-18). The Round 3 tables below are the current
balance. Where Round 4 and the older sections disagree (the walk speed, the sprint multiplier), Round 4 wins.

### What changed

The king's walk went from 5.0 to 7.5 m/s (1.5x) and his sprint stays at exactly 12 m/s, so the sprint multiplier
went from 2.4 to 1.6. Acceleration (60) and the night fast-forward (2x) are unchanged, and D-03's ride budget was
amended to match (edge to edge about 15 s at the walk and about 9 s at the sprint, the map not grown). This is plan
02-21 and it is two lines of `data/king/king.tres`; no other data file moved.

### Why no bot number moved

- Every building strategy (`balanced`, `greedy_economy`, `houses_first`, `towers_first`) moves its king only as the
  defender, and the defender's step is `walk_speed x sprint_multiplier` on every tick. 5.0 x 2.4 and 7.5 x 1.6 are
  both exactly 12.0 in doubles, so the per-tick step is bit-identical before and after.
- `no_build` never leaves the king spawn, so its king never moves at all.
- So the bots cannot see a walk change: they either sprint at exactly 12.0 m/s or stand still.

### Evidence

- The diagnosis (`.planning/debug/king-walk-speed-1-5x.md`) ran all five strategies on seeds 1 to 10 on this exact
  7.5 / 1.6 data and diffed the result against a baseline taken on the round-3 data: `report.md` and `report.json`
  were byte-identical (diff exit 0).
- In this plan, on the final tree, the full suite passes (831 tests in 95 scripts, lint clean) with `test_balance_acceptance` unchanged
  (balanced 7 or 8 of 10, seeds 3 and 9 lost on night 3 or later), the smoke replay equals its golden
  (`REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`)
  and `full_idle` prints the same line as round 3
  (`REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac`).
- No playtest was re-run in this plan, on purpose: a re-run could only reproduce the byte-identical report.

### The blind spot

The bots never walk at night, so no number here says what a walking king does. A human who rides without holding
sprint is now half again as mobile between sprints (2.3x a grunt's 3.2 m/s instead of 1.6x; 2.7x a skirmisher's
2.8 m/s instead of 1.8x). Because the top speed is unchanged, this can only make human play slightly easier, never
harder. Only the owner's replay can judge how much.

The Round 3 tables below are the current balance.

## Round 3 (gap closure G-02-13 to G-02-15, 2026-10-07)

Produced by plan 02-20 with `bash tools/playtest.sh` (all five strategies, seeds 1 to 10, about 1 minute) and
`bash tools/playtest.sh --strategies=balanced --seeds=50 --out=build/playtest_round3_seeds50` (the balanced bot on
seeds 1 to 50) on the shipped prototype map, after the three round-2 fixes landed (plans 02-17, 02-18, 02-19).
Same disclaimer: these are scripted-bot measurements and Claude's own reading of them,
**not the owner's sign-off**; only the owner's round-3 replay and decision, recorded through `/gsd-verify-work`,
close G-02-12 (D-18). Where this section and the Round 2 or Round 1 sections below disagree, Round 3 wins; they
stay as the record of what the owner played in those rounds.

### What changed since round 2

| Change | Plan | Effect on the bots |
|---|---|---|
| Castle reach 22 m (was 11) and arrow speed 27 m/s (was 18); damage 2, interval 1.5 s and castle health 70 unchanged (G-02-13) | 02-17 | It now covers both inner House plots and the centres of houses 3 and 4 (no tower's circle). A lone grunt dies before it reaches the wall and a lone skirmisher before it shoots. Under the old counts the balanced bot never let an enemy within reach, so the castle fired 0 shots and every replay was unchanged; under the new night counts it does fight: `balanced` castle kills 4.1 of 12 on night 2 and 1.7 of 21 on night 3, and `no_build` now lets the castle kill all 5 grunts of night 1 (it ends the night with 24.2 castle hp) before losing night 2 |
| Night fast-forward is a toggle (F or the left trigger: press once for 2x, press again for real time, off again when the night ends) instead of a hold (G-02-14) | 02-18 | None. Fast-forward only scales the engine time outside the simulation, replays and the bots never involve the controller, so no digest and no table moved |
| The full wall: night 2 opens the east road, nights 3 to 5 grow (G-02-15) | 02-19 | `balanced` 8 of 10 (round 2: 10 of 10), `houses_first` 8 of 10, `greedy_economy` 0 of 10 and now loses on nights 3 and 4, `no_build` loses night 2, `towers_first` 10 of 10 |

What did not change: grunt health 6, every building cost, the House incomes, the base income of 1, the starting
gold of 4, castle damage 2 and castle health 70, nights 1 and 6 to 8, and every skirmisher group. Nothing but the
night counts of nights 2 to 5 (and the castle's two numbers above) moved the difficulty.

### Night counts, before and after (grunts per road, skirmishers in brackets)

| Night | Round 2 (before) | Round 3 (after) | Total before | Total after |
|---:|---|---|---:|---:|
| 1 | W5 | W5 (unchanged) | 5 | 5 |
| 2 | W8 | W8 E4 | 8 | 12 |
| 3 | W6 E5 | W11 E10 | 11 | 21 |
| 4 | W7 E4 [E3] | W11 E7 [E3] | 14 | 21 |
| 5 | W7 E7 [W2 E2] | W9 E8 [W2 E2] | 18 | 21 |
| 6 | W6 E5 N7 [W2 E2] | unchanged | 22 | 22 |
| 7 | W7 E7 N7 [W2 E2 N2] | unchanged | 27 | 27 |
| 8 | W8 E8 N8 [W3 E3 N3] | unchanged | 33 | 33 |

Totals per night, before: 5, 8, 11, 14, 18, 22, 27, 33. After: 5, 12, 21, 21, 21, 22, 27, 33. Night 2 now comes
from two roads (the new east group starts 2.0 s in, one grunt every 1.5 s, like the other east groups), so the
telegraph shows two markers from night 2 on. `test_night_data_contract` pins every changed count.

### Acceptance checks (measured on the final data, seeds 1 to 10)

| Check | Required (D-10, D-04, owner 2026-10-07) | Measured | Result |
|---|---|---|---|
| `balanced` wins | 7 or 8 of seeds 1 to 10 (the owner's round-2 target; D-10 minimum was 0.8) | 8 of 10 won (win rate 0.8); lost seeds 3 and 9 | pass |
| `balanced` loses on night 3 or later | never earlier | both losses on night 3 (2 nights survived), none on night 1 or 2 | pass |
| `greedy_economy` win rate | at most 0.2 | 0.0 (0 of 10 won) | pass |
| `greedy_economy` median loss night | 3 to 6 | 3 (night 3 on six seeds, night 4 on four) | pass |
| `no_build` loses by night 3 | max nights survived at most 2 | max 1 survived: every seed lost night 2 | pass |
| `towers_first` gold earned | above 0.0 | mean 7.0, 7 in every run | pass |
| `towers_first` result | winnable (owner's tower opening) | 10 of 10 won | pass |
| King alone vs a group of 3 grunts | kills all, no knockout | passes (`test_king_sturdiness`) | pass |
| King in the shipped night-4 wave | knocked out at least once | passes (`test_king_sturdiness`) | pass |
| Every started night ends | DAWN, WON or LOST within 300 s, no timeout, seeds 1 to 10 | passes (`test_every_night_ends`) | pass |
| Grunt health | stays 6 | 6 (`test_balance_acceptance`) | pass |
| Smoke golden | digest unchanged | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` | pass |
| `full_idle` replay | two runs agree | `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac` | pass |

The seeded shape (balanced 7 or 8 of seeds 1 to 10, losing exactly seeds 3 and 9 on night 3 or later; seeds 1 to 3
for the other strategies) is pinned by `tests/integration/test_balance_acceptance.gd`. The full suite is 829
tests in 95 scripts, all passing, and lint is clean. The numbers match what the diagnosis
(`.planning/debug/difficulty-balanced-7-of-10.md`) measured for this exact edit (balanced 8 of 10 losing seeds 3
and 9 on night 3; greedy 0 of 10 on nights 3 and 4 with median 3; no_build night 2; towers_first 10 of 10 with 7.0
gold; houses_first 8 of 10; 36 of 50 on seeds 1 to 50), so there is nothing to flag.

### The 50-seed balanced line (the project's own CLI)

`bash tools/playtest.sh --strategies=balanced --seeds=50`: **balanced wins 36 of 50 (72%)** on seeds 1 to 50
(nights survived 6.3 mean, 2 to 8; median loss night 3). All 14 losses are on night 3 (seeds 3, 9, 14, 15, 16,
19, 26, 28, 31, 33, 35, 38, 39, 42), which is exactly the figure the diagnosis got from its in-memory harness.
A 72% win rate on 50 seeds is "loses 2 to 3 times in 10" at the upper end of the owner's ask; the 8 of 10 on
seeds 1 to 10 is the acceptance set, and seeds 1 to 10 happen to be slightly kinder than seeds 11 to 50.

### The night-3 wall, plainly

The extra difficulty is **one wall on night 3 that only a House opening can hit**, and it works as an AND gate:

- Night 2 now comes from two roads. When the king (alone, with no tower yet) lets it cost a House opening 2 of
  its 3 Houses, dawn 2 pays only 3 gold, because a House rebuilt that dawn pays nothing: that is below the 4-gold
  first tower, so night 3 is met with no tower at all.
- Night 3 then brings 21 grunts from two roads, heavier than the 11 of the round-1 night 3 the owner could not
  beat. The king and the 22 m castle cannot hold it, and the castle falls on night 3.
- With 1 House lost (or none) on night 2, dawn 2 pays 4 gold or more, the first tower stands and night 3 is won
  at full castle health. Measured on seeds 1 to 50: 28 of 28 such runs won with the castle at 70 hp after night
  3; of the 22 runs that lost 2 Houses on night 2, 14 lost on night 3 and 8 won (the castle ended night 3 on
  4, 30, 38, 14, 32, 4, 16 and 34 hp).
- A **tower opening stays safe and is now the strictly safer start**: `towers_first` wins 10 of 10 (and 50 of 50
  in the diagnosis) with the castle at 70 hp until night 8. `houses_first` loses the same two seeds as
  `balanced` (3 and 9), and `greedy_economy` dies on night 3 or 4 on every seed.
- The castle's 22 m reach is what fights the wall when enemies get close: `balanced` castle kills 4.1 of 12 on
  night 2 and 1.7 of 21 on night 3.
- The win rate is steep in the counts: one grunt more or less per road on night 3 moves it 10 to 20 points (the
  diagnosis's measured alternatives: `k7pS4m`, night 2 east 7, night 3 W10 E9, night 4 W10 E6, night 5 W8, gives
  balanced 7 of 10 and 76% of 50 with wins that end night 3 on 2 to 34 castle hp; `k4pS6m`, night 3 W12 E11 and
  more, gives 7 of 10 and 66% of 50 with greedy dying on night 3 every time; neither is applied). Whether this
  is "a little harder" or a wall that is too abrupt for a human is for the owner's replay to say; the bot has
  a perfect king and builds instantly, so a person will be markedly worse than every row below.

### Round 3 summary (seeds 1 to 10)

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.4 / 2 / 3 | 3 | 7.3 | 4.0 | 1.4 |
| houses_first | 80% | 6.8 / 2 / 8 | 3 | 24.5 | 2.9 | 0.4 |
| towers_first | 100% | 8.0 / 8 / 8 | - | 7.0 | 2.0 | 2.8 |
| balanced | 80% | 6.8 / 2 / 8 | 3 | 22.3 | 2.7 | 0.4 |

### Round 3 per night: balanced

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 11.1 | 3.0 |
| 2 | 10 | 12.0 | 7.9 | 0.0 | 4.1 | 1.2 | 0.0 | 70.0 | 31.4 | 3.8 |
| 3 | 10 | 21.0 | 10.4 | 7.6 | 1.7 | 0.6 | 0.3 | 49.4 | 28.8 | 4.0 |
| 4 | 8 | 21.0 | 2.3 | 18.8 | 0.0 | 0.3 | 0.1 | 70.0 | 20.3 | 4.3 |
| 5 | 8 | 21.0 | 1.4 | 19.6 | 0.0 | 0.0 | 0.0 | 70.0 | 18.7 | 4.3 |
| 6 | 8 | 22.0 | 0.5 | 21.5 | 0.0 | 0.0 | 0.0 | 70.0 | 14.7 | 7.8 |
| 7 | 8 | 27.0 | 2.6 | 24.4 | 0.0 | 0.0 | 0.0 | 70.0 | 17.1 | 5.6 |
| 8 | 8 | 33.0 | 7.1 | 25.9 | 0.0 | 0.9 | 0.0 | 70.0 | 23.3 | 3.9 |

### Round 3 per night: greedy_economy

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 11.1 | 3.0 |
| 2 | 10 | 12.0 | 7.9 | 0.0 | 4.1 | 1.2 | 0.0 | 70.0 | 31.4 | 3.8 |
| 3 | 10 | 21.0 | 11.7 | 0.0 | 5.7 | 2.0 | 1.0 | 3.4 | 41.9 | 1.9 |
| 4 | 4 | 21.0 | 10.0 | 0.0 | 4.3 | 2.0 | 1.0 | 0.0 | 38.4 | 1.3 |

### Round 3 per night: towers_first

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 2.1 | 2.9 | 0.0 | 0.0 | 0.0 | 70.0 | 8.0 | 1.0 |
| 2 | 10 | 12.0 | 4.4 | 7.6 | 0.0 | 0.0 | 0.0 | 70.0 | 15.5 | 2.0 |
| 3 | 10 | 21.0 | 10.0 | 11.0 | 0.0 | 0.0 | 0.0 | 70.0 | 22.9 | 3.0 |
| 4 | 10 | 21.0 | 10.0 | 11.0 | 0.0 | 0.0 | 1.0 | 70.0 | 26.7 | 4.0 |
| 5 | 10 | 21.0 | 1.3 | 19.7 | 0.0 | 0.1 | 0.0 | 70.0 | 19.2 | 1.0 |
| 6 | 10 | 22.0 | 7.0 | 15.0 | 0.0 | 0.0 | 0.0 | 70.0 | 18.9 | 2.0 |
| 7 | 10 | 27.0 | 9.0 | 18.0 | 0.0 | 0.0 | 0.8 | 70.0 | 26.0 | 3.0 |
| 8 | 10 | 33.0 | 14.1 | 16.1 | 2.8 | 1.9 | 1.0 | 56.4 | 39.2 | 3.0 |

(The per-night tables of the other two strategies are in `build/playtest/report.md` after
`bash tools/playtest.sh`.)

## Round 2 (gap closure G-02-1, 2026-10-06)

Produced by plan 02-16 with `bash tools/playtest.sh` (all five strategies, seeds 1 to 10, about 45 s) after the
three gap fixes landed on the shipped prototype map. Same disclaimer: these are scripted-bot measurements,
**not the owner's sign-off**; the owner's replay and decision close G-02-1 (D-18).

### What changed since round 1

| Change | Plan | Effect on the bots |
|---|---|---|
| Base income: the castle pays 1 gold every dawn (`base_dawn_income = 1`), towers still pay nothing | 02-12 | Every strategy has income, including the tower-first opening that earned 0.0 in round 1 |
| Castle attack: 2 damage every 1.5 s up to 11 m, arrows at 18 m/s (`castle_attack_*` on the map) | 02-15 | None for `balanced` (no enemy ever comes within 11 m of the castle under it, 0 castle kills); it only helps weak or idle play (`no_build` castle kills 3.8 of 5 enemies on night 1 and still loses) |
| Sprint 12 m/s (was 8), acceleration 60; night fast-forward (hold F or left trigger, night only) | 02-13 | The bots' king sprints at 12 m/s; fast-forward only scales the engine time (never inside the simulation), so every replay and digest is unchanged |
| Results-screen button spacing | 02-14 | None (UI only) |
| Wave data and castle health | this plan | **No wave change: `balanced` lost no run on seeds 1 to 10.** Night 3 east stays 5 grunts, `castle_max_health` stays 70, grunt `max_health` stays 6 |

Costs, House incomes, the starting gold of 4 and every night other than the ones listed are untouched, as the
owner required (G-02-1 point 4: "a bit easier", only the night-3 count and the castle health allowed, and only
if the balanced bot still lost).

### Acceptance checks (measured on the shipped data, seeds 1 to 10)

| Check | Required (D-10, D-04, owner 2026-10-06) | Measured | Result |
|---|---|---|---|
| `balanced` win rate | at least 0.8 (D-10) and no lost run (owner's rule for touching night 3) | 1.0 (10 of 10 won) | pass |
| `greedy_economy` win rate | at most 0.2 | 0.0 (0 of 10 won) | pass |
| `greedy_economy` median loss night | 3 to 6 | 5 (every run lost on night 5) | pass |
| `no_build` loses by night 3 | max nights survived at most 2 | max 1 survived: lost night 1 on 7 seeds, night 2 on 3 seeds | pass |
| `towers_first` gold earned | above 0.0 (round 1: 0.0) | mean 7.0, above 0 in every run | pass |
| `towers_first` result | winnable (owner's tower opening) | 10 of 10 won | pass |
| King alone vs a group of 3 grunts | kills all, no knockout | passes (`test_king_sturdiness`) | pass |
| King in the shipped night-4 wave | knocked out at least once | passes (`test_king_sturdiness`) | pass |
| Every started night ends | DAWN, WON or LOST within 300 s, no timeout, seeds 1 to 10 | passes (`test_every_night_ends`) | pass |
| Grunt health | stays 6 | 6 (`test_balance_acceptance`) | pass |
| Smoke golden | digest unchanged | `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` | pass |
| `full_idle` replay | two runs agree | `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435` | pass |

The seeded shape (seeds 1 to 3) is pinned by `tests/integration/test_balance_acceptance.gd`. On the data
before the three fixes the two `towers_first` assertions fail (mutation probe: `base_dawn_income = 0` and
`castle_attack_damage = 0` turn the gold-earned and the wins-at-least-2 tests red).

### Reading the numbers (what a bot cannot tell you)

- The base gold moved the economy a lot for the bots: `balanced` earns 28 gold a run (round 1: 18), loses no
  building and is never knocked out. `towers_first` goes from 0 of 10 wins to 10 of 10. Whether that is "a bit
  easier" or "too easy" is for the owner to judge on a replay: the bots build instantly, never ride to the
  plots and never mis-step, so a human will be markedly worse than every row below (the round-1 caveats in
  "What the bots cannot tell you" still apply).
- `greedy_economy` still falls (night 5, castle at 0 hp), so skipping defence still loses, and `no_build`
  still falls on night 1 or 2: the castle attack plus the idle king kill about 4 of the 5 night-1 grunts (3.8 by the castle, 0.3 by the king) but not all.
- The castle attack is invisible to `balanced` (0 castle kills in every night of its table); it is a safety
  net for weak play and for a king who is knocked out. If the owner finds nights too easy, the levers are
  the night counts and the castle's damage, not the grunt's health.

### Round 2 summary (seeds 1 to 10)

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 0.3 / 0 / 1 | 1 | 0.3 | 0.0 | 0.0 |
| greedy_economy | 0% | 4.0 / 4 / 4 | 5 | 15.0 | 6.0 | 1.7 |
| houses_first | 100% | 8.0 / 8 / 8 | - | 31.0 | 0.9 | 0.0 |
| towers_first | 100% | 8.0 / 8 / 8 | - | 7.0 | 1.9 | 1.9 |
| balanced | 100% | 8.0 / 8 / 8 | - | 28.0 | 0.0 | 0.0 |

### Round 2 per night: balanced

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 11.1 | 3.0 |
| 2 | 10 | 8.0 | 8.0 | 0.0 | 0.0 | 0.0 | 0.0 | 70.0 | 13.5 | 5.0 |
| 3 | 10 | 11.0 | 5.7 | 5.3 | 0.0 | 0.0 | 0.0 | 70.0 | 17.4 | 5.0 |
| 4 | 10 | 14.0 | 0.2 | 13.8 | 0.0 | 0.0 | 0.0 | 70.0 | 13.7 | 5.0 |
| 5 | 10 | 18.0 | 1.1 | 16.9 | 0.0 | 0.0 | 0.0 | 70.0 | 17.1 | 5.0 |
| 6 | 10 | 22.0 | 0.3 | 21.7 | 0.0 | 0.0 | 0.0 | 70.0 | 14.7 | 9.0 |
| 7 | 10 | 27.0 | 2.9 | 24.1 | 0.0 | 0.0 | 0.0 | 70.0 | 17.1 | 6.0 |
| 8 | 10 | 33.0 | 6.6 | 26.4 | 0.0 | 0.0 | 0.0 | 70.0 | 16.2 | 0.0 |

### Round 2 per night: towers_first

| Night | Runs | Enemies | Kills king | Kills towers | Kills castle | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 2.1 | 2.9 | 0.0 | 0.0 | 0.0 | 70.0 | 8.0 | 1.0 |
| 2 | 10 | 8.0 | 6.6 | 1.4 | 0.0 | 0.0 | 0.0 | 70.0 | 12.2 | 2.0 |
| 3 | 10 | 11.0 | 5.5 | 5.5 | 0.0 | 0.0 | 0.0 | 70.0 | 17.4 | 3.0 |
| 4 | 10 | 14.0 | 7.0 | 7.0 | 0.0 | 0.0 | 0.0 | 70.0 | 15.2 | 4.0 |
| 5 | 10 | 18.0 | 0.8 | 17.2 | 0.0 | 0.0 | 0.0 | 70.0 | 17.0 | 1.0 |
| 6 | 10 | 22.0 | 7.0 | 15.0 | 0.0 | 0.0 | 0.0 | 70.0 | 18.8 | 2.0 |
| 7 | 10 | 27.0 | 9.0 | 18.0 | 0.0 | 0.0 | 0.8 | 70.0 | 26.0 | 3.0 |
| 8 | 10 | 33.0 | 15.0 | 16.1 | 1.9 | 1.9 | 1.1 | 52.0 | 40.5 | 3.0 |

(The per-night tables of the other three strategies are in `build/playtest/report.md` after
`bash tools/playtest.sh`; the `Kills castle` column is new in round 2.)

## Round 1 (plan 02-10)

The round-1 text and tables below are unchanged from plan 02-10 except that their headings sit one level deeper.
They were measured on the data before the gap closure (no base income, no castle attack, sprint 8 m/s) and
have no `Kills castle` column.

### Acceptance checks (measured on the final data, seeds 1 to 10)

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

### Final balance table

#### Summary

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 0.0 / 0 / 0 | 1 | 0.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 3.5 / 3 / 4 | 4 | 8.5 | 5.0 | 2.1 |
| houses_first | 100% | 8.0 / 8 / 8 | - | 18.0 | 4.6 | 1.4 |
| towers_first | 0% | 5.1 / 5 / 6 | 6 | 0.0 | 0.0 | 1.9 |
| balanced | 100% | 8.0 / 8 / 8 | - | 18.0 | 4.8 | 1.4 |

#### Per night: no_build

| Night | Runs | Enemies | Kills king | Kills towers | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 1.1 | 0.0 | 0.0 | 0.0 | 0.0 | 31.9 | 4.0 |

#### Per night: greedy_economy

| Night | Runs | Enemies | Kills king | Kills towers | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 5.0 | 0.0 | 0.0 | 0.0 | 70.0 | 12.7 | 2.0 |
| 2 | 10 | 8.0 | 8.0 | 0.0 | 0.0 | 0.0 | 70.0 | 13.9 | 3.0 |
| 3 | 10 | 11.0 | 11.0 | 0.0 | 2.0 | 0.6 | 49.6 | 37.8 | 3.0 |
| 4 | 10 | 14.0 | 10.9 | 0.0 | 2.0 | 1.0 | 4.4 | 39.1 | 2.5 |
| 5 | 5 | 18.0 | 7.0 | 0.0 | 2.0 | 1.0 | 0.0 | 33.4 | 1.0 |

#### Per night: houses_first

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

#### Per night: towers_first

| Night | Runs | Enemies | Kills king | Kills towers | Buildings lost | Knockouts | Castle hp at end | Night seconds | Gold at dawn |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 5.0 | 0.7 | 4.3 | 0.0 | 0.0 | 70.0 | 8.6 | 0.0 |
| 2 | 10 | 8.0 | 6.2 | 1.8 | 0.0 | 0.0 | 70.0 | 12.2 | 0.0 |
| 3 | 10 | 11.0 | 5.5 | 5.5 | 0.0 | 0.0 | 70.0 | 20.4 | 0.0 |
| 4 | 10 | 14.0 | 7.0 | 7.0 | 0.0 | 0.0 | 70.0 | 15.9 | 0.0 |
| 5 | 10 | 18.0 | 9.0 | 9.0 | 0.0 | 0.8 | 70.0 | 24.6 | 0.0 |
| 6 | 10 | 22.0 | 7.2 | 8.0 | 0.0 | 1.0 | 0.2 | 36.1 | 0.0 |
| 7 | 1 | 27.0 | 6.0 | 9.0 | 0.0 | 1.0 | 0.0 | 33.2 | 0.0 |

#### Per night: balanced

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

### Before the tuning pass

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

### What changed (data only)

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

### What the shape of the numbers says

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

### What the bots cannot tell you

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

### Open points for the owner at the gate

- Does the first day feel like a real choice with only 4 gold (two Houses, or one tower that earns nothing)?
- Is night 3 (the king alone against two roads) the right first scare, and does losing 2 Houses there feel fair?
- Are nights 6 and 7 too calm once the three towers stand?
- Dawn repair is full (RESEARCH Open Question 1, resolved in plan 02-06 as full repair); confirm or ask for a
  different rule.
