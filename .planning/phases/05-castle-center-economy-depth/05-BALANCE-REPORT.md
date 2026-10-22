# Phase 5 Balance Report (plan 05-11: the castle gate ships, the bots play the new day, D-08 outcome report)

Measured 2026-10-22 (UTC) by plan 05-11 with `bash tools/playtest.sh --seeds=10` on the shipped prototype map
(`PLAYTEST_OK runs=100`: ten strategies by seeds 1 to 10, about seven minutes). As in Phases 2 to 4, these tables
are scripted bots measuring the data. They build without riding to the plots and react perfectly, so they are not
the owner's sign-off and say nothing about feel (Phase 2 D-18). The owner judges the feel of the castle, the cards,
the gate and the new buildings at the Phase 5 gate (`/gsd-verify-work 5`).

## Outcome

**The Phase 2 bar holds on the shipped 23-spot map with the castle gate in the data: `balanced` wins 8 of seeds 1 to
10, `army_balanced` wins 8 of 10 with a squad value ratio of 0.888 (bar 0.8), and the balanced bot's first castle
upgrade is bought on day 6 at the earliest (D-01: never before day 2).** No number moved except the gate itself:
`requires_castle_tier = 2` on the last tier of House, Tower, Barracks, Archery Range and Wall (D-03). The order lever
of the Phase 4 D-15 ladder was enough, so no castle tier, card, new-building or night number was fitted
(`## Numbers fitted`).

Which branch of the ladder applied, in the order it was reached:

1. The first castle-aware orders (round 1, no gate yet) put the castle behind the Harbor and the Mine: `balanced`
   won 6 of 10 and the castle was bought on day 8 in the best seed. That is below the bar, and the bot's own order was
   the cause (an unaffordable castle entry blocks every later entry). Lever (a), the bots' orders and picks, was
   pulled.
2. With the gate in the data, about forty scratch candidates of lever (a) (search log) showed the shape of the problem: the
   Phase 4 order alone falls to 3 of 10 (it cannot upgrade a tower without castle II), the castle bought right after
   the first tower gives 9 of 10 (above the bar), and the Harbor placed right after the first tower with the castle
   after the second gives 8 of 10 with the castle on day 6 and exactly the Phase 4 losses (seeds 3 and 9).
3. Round 2 measured that order as the shipped one: the goal was met, so levers (b) castle tiers, (c) new-building
   numbers, (d) cards and (e) night counts were not pulled. The Shrine and the Harbor were measured as sensitivities
   only (`## Search log`, batch G).

## Goldens decision (D-08)

`smoke`, `army` and `walls` were never regenerated: they run on frozen fixture maps that carry inline copies of
every def (research P1), so neither the new plots nor the gate can reach them, and none of their digests moved
through any step of this plan (checked after the gate lines, after the rename and with the final data):
smoke `2599c7c2` (703 ticks), army `f7a967ed` (1353), walls `bfb05fc7` (1961). `economy` (`f4b98093`, 1842 ticks,
plan 05-10) is the one new golden, on its own frozen fixture; it did not move either. `full_idle` has no golden file
by design (it plays the shipped data), so its before and after is reported in the next section. No golden was
re-pinned and no stop rule fired.

## full_idle before and after

`bash tools/replay.sh --scenario=full_idle --twice` (seed 1, the shipped map and tuning, bot `balanced`):

| | Outcome | Ticks | Digest |
|---|---|---:|---|
| Before (plan 05-10 and RESEARCH E3) | won | 6911 | `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` |
| After (this plan, final data) | won | 7000 | `afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14` |

Why it moved (research P2 predicted it): the gate sits in the shipped data and the `balanced` bot is now the
castle-aware order. The run still wins, 89 ticks (about 3 s) longer. The log now shows what the new day looks like
at seed 1: the Harbor bought on day 3 and gaining a boat at each of the next three dawns, castle II bought with
the Masons card on day 5 (tick 4258), Tower II after it, the Gold Mine bought on day 7 and six buildings lost
over the run. The same bot played the Phase 4 order before, with no castle and no new building.

## Balanced bot (bar 7 or 8 of 10)

Round 2, seeds 1 to 10, shipped data:

| Strategy | Wins | Lost (seed: night) | Nights survived (mean) | Gold earned (mean) | Buildings lost (mean) | Castle tier (mean) | First upgrade (earliest day) | Squad value ratio |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| balanced | 8 of 10 | 3: 7, 9: 3 | 7.2 | 30.0 | 8.6 | 1.80 | 6 | n/a |
| army_balanced | 8 of 10 | 1: 7, 9: 6 | 7.5 | 15.0 | 18.0 | 1.00 | none | 0.888 |

- `balanced` wins 8 of 10 (`BALANCED_MIN_WINS` 7 and `BALANCED_MAX_WINS` 8 are unchanged). It loses seed 3 on night 7
  (night 8 before) and seed 9 on night 3 (unchanged): the same two seeds the Phase 4 order lost. It buys castle II in
  8 of 10 seeds (day 6 in seven of them, day 8 in one, never in the two lost early seeds), always with Masons.
- Spend by role, mean per run: towers 14.6, economy 13.7, castle 4.8, shrine 0.0, military 0.0. Gold earned rises
  from 20 to 30 per run, almost all of it from the Fishing Harbor (three boats paying 1 gold each from the third
  dawn).
- `army_balanced` wins 8 of 10 and loses seeds 1 (night 7) and 9 (night 6), as before. Its squad value ratio is 0.888
  (unit kills per military gold 4.61, tower kills per tower gold 5.19), above the 0.8 bar. It never buys the castle:
  Barracks and Range take the first 8 gold and the run earns about 15, so the castle (6) is never affordable before
  the gold is spent. Its picks (Commander, War Horns, Iron Discipline) are in the order but never reached. This is
  a finding about the squad build, not a retune.
- The first castle upgrade costs 6 gold, above the 4 starting gold plus the 1 base income of the first dawn
  (`test_gate_data_contract` pins it), and in play it is bought on day 6 at the earliest.

## What the castle and the gate change

The four bots against their twins, round 2 (the twins keep the Phase 3 and Phase 4 orders; all ten strategies share
the 23-spot map and the gate):

| Strategy | Wins | Lost (seed: night) | Nights survived (mean) | Gold earned (mean) | Castle tier (mean) | Squad value ratio |
|---|---:|---|---:|---:|---:|---:|
| balanced | 8 of 10 | 3: 7, 9: 3 | 7.2 | 30.0 | 1.80 | n/a |
| balanced_no_castle (Phase 4 order) | 3 of 10 | 2: 8, 4: 8, 5: 8, 6: 7, 8: 8, 9: 3, 10: 7 | 6.6 | 20.4 | 1.00 | n/a |
| balanced_no_walls (Phase 3 order) | 4 of 10 | 1: 8, 3: 8, 4: 8, 6: 7, 9: 3, 10: 7 | 6.7 | 22.1 | 1.00 | n/a |
| army_balanced | 8 of 10 | 1: 7, 9: 6 | 7.5 | 15.0 | 1.00 | 0.888 |
| army_balanced_no_castle (Phase 4 order) | 8 of 10 | 1: 7, 9: 6 | 7.5 | 14.8 | 1.00 | 0.888 |
| army_balanced_no_walls (Phase 3 order) | 8 of 10 | 1: 7, 9: 6 | 7.5 | 15.0 | 1.00 | 0.915 |
| houses_first | 4 of 10 | 3: 8, 4: 8, 6: 7, 8: 8, 9: 3, 10: 7 | 6.7 | 21.1 | 1.00 | n/a |
| greedy_economy | 0 of 10 | loss nights 3 to 5 | 2.9 | 9.2 | 1.00 | n/a |
| towers_first | 0 of 10 | seven seeds on night 7, seed 8 on night 8 | 6.1 | 6.1 | 1.00 | n/a |
| no_build | 0 of 10 | night 2 on every seed | 1.0 | 1.0 | 1.00 | n/a |

What this shows:

- **The gate is what costs the tower build.** The Phase 4 balanced order bought Tower II as its seventh entry; with
  the gate it can never buy it, so it falls from 8 wins to 3 (seven seeds lost, none before night 3), and the Phase 3
  order from 8 to 4. A bot that wants Tower II has to pay for castle II (6 gold) first: that trade is the point of
  D-03, and `balanced` makes it and keeps the Phase 4 result (8 of 10, the same two lost seeds).
- **Army bots do not feel the gate.** Their orders reach Tower II (and every other top tier) only after the gold is
  gone, so the three army rows are identical in wins and lost seeds; the tiny gold difference (14.8 and 15.0) is the
  Harbor and Mine entries, bought in some seeds.
- **The older bots keep their shape.** Greedy economy still never wins and falls on nights 3 to 5; doing nothing
  falls on night 2; the tower opening survives 6 or 7 nights on every seed; Houses first wins 4 (it was not pinned).
- **The Fishing Harbor is the strongest new income** (20 to 30 gold per run when bought right after the first tower).
  Placed that early, with the castle after it, balanced stays at 8 of 10; bought as the third entry it costs the bot
  its first tower and loses seeds 2, 6 and 9 on nights 2 and 3.
- **How often the Shrine fires.** In the shipped balanced order the Shrines sit last and are never reached
  (shrine gold 0.0). Measured separately (batch G): bought right after Tower III, shrine_west woke in 1 seed of 10 and
  fired 0 times; with both Shrines bought early it woke in 5 seeds, fired once in total, and cost
  the bot three wins (5 of 10). A reach of 14 m and a wake threshold of 50 health changed the wins (still 8) and the
  shots (still 0): the Shrine plots lie 12.5 m from the roads and the road enemies die before they come for it. See
  `## Owner feel items`.

## Numbers fitted

**None.** The bar was met by lever (a) alone, so every ladder number kept its value.

| Lever | Value | Old | New |
|---|---|---|---|
| (b) castle tiers II to IV: cost, health, arrow, base income | `castle_center.tres` | 6 / 10 / 16, 100 / 140 / 200, 3 / 4 / 5, 2 / 3 / 4 | unchanged |
| (c) Gold Mine, Mill, Field, Harbor, Shrine numbers | `gold_mine.tres` to `shrine.tres` | as shipped by plans 05-06 to 05-09 | unchanged |
| (d) the twelve cards | `data/abilities/*.tres` | as drafted by plan 05-03 | unchanged |
| (e) night counts | `prototype_map.tres` | as shipped | unchanged |
| Gate (D-03, not a fit) | `requires_castle_tier` on House III, Tower II, Barracks III, Archery Range III, Wall III | 0 | 2 |

The five Phase 4 building files changed on that one line only (their costs, health and attack numbers are Phase 4
balance data, not levers). Mill III and Harbor II already carried the requirement. The castle's own tiers carry none.
What did change is the bots' orders and picks (lever a, `tools/replay/playtest_strategies.gd`): `balanced` is now
house_1, house_2, house_3, tower_1, harbor_1, tower_2, castle_plot (Masons), tower_3, tower_1 (II), gold_mine_1 and
then the walls, the Mill with its Fields, the Shrines and the later castle tiers (Engineers, Golden Age); the Phase 4
orders were renamed `balanced_no_castle` and `army_balanced_no_castle` and the round 1 names `balanced_castle` and
`army_castle` became `balanced` and `army_balanced`.

## Search log

Each line is ten seeds (1 to 10) on the code of its batch. "Round" means a full `bash tools/playtest.sh` run; the
"scratch" batches ran the same simulation through a throwaway probe script that overrides the order (and, in batch A
to D, the five gate lines) so that candidates could be compared without a seven-minute sweep each; every candidate
that mattered is listed. Two rounds were used of the eight the stop rule allows.

**Round 1 (Task 1, no gate in the data, `balanced_castle` and `army_castle` as first written).**
`balanced_castle` 6 of 10 (lost 3: night 8, 6: 7, 9: 3, 10: 7), mean castle tier 1.40, castle bought in four seeds on
day 8 with Masons, 23.1 gold earned; `army_castle` 8 of 10 (lost 1: 7, 9: 6), never bought the castle, 15.0 gold,
ratio 0.888. The castle entry waited, unaffordable, behind a Harbor and a Mine and blocked the order.

**Scratch batch A (gate on by override; Phase 4 orders and first castle placements).**
Phase 4 balanced order with the gate 3 of 10; Phase 4 army order with the gate 8 of 10; castle after the three towers,
Harbor and Mine after the walls 8 of 10 (lost 3: 8, 9: 3; castle day 7); castle after the first tower 9 of 10 (lost 9);
Mine first 7 of 10 (lost 2, 6, 9 on night 3); Harbor as third entry 7 of 10 (lost 2, 6, 9; 29 gold).

**Scratch batch B.** Harbor right after the first tower, castle after the third 9 of 10; after the second tower 8 of
10; Harbor as the third entry 7; Harbor and Mine both before the castle 7; Harbor after all three towers and before
the castle 6; castle before the Harbor 8. Army bot with the castle after the Range, after the Harbor, or after the
walls: 8 of 10 in every case, castle never bought.

**Scratch batch C.** Army bot with the Harbor before the Range 2 of 10, before the third House 5, before the Barracks
3: the early game cannot spare the 3 gold. Army bot with the Harbor and Mine after the Range 8 of 10. Balanced with
castle between the second and third tower and Harbor second 7; Harbor and Mine before the castle 6; Harbor after the
second tower and Tower II second round 8.

**Scratch batch D.** The tail of the order (Mine, Mill, Fields, Shrine, walls) after the castle: five orders with
different tails all gave 8 of 10 and identical lost seeds, because the gold is spent by day 7. Mine placed before the
castle 6.

**Scratch batch E (gate in the data, so the sweep is the shipped code).** Twins: balanced_no_walls 4 of 10,
army_balanced_no_walls 8, Phase 4 balanced 3, Phase 4 army 8, greedy economy 0 (loss nights 3 to 5), towers first 0
(nights 7 and 8), houses first 4, no_build 0. Candidates: castle after the second tower with Harbor after Tower I
second round 8 of 10 (castle on day 6 in 8 seeds, 22.8 gold); the same with the Harbor after the first tower
**8 of 10, castle day 6 in 8 seeds, 30.0 gold, lost seeds 3 and 9** (shipped); castle after the third tower 8; Harbor
after the second tower 8.

**Round 2 (shipped).** Final data and orders: `balanced` 8 of 10 (lost 3: night 7, 9: night 3), mean castle tier 1.80,
earliest first upgrade day 6; `army_balanced` 8 of 10 (lost 1: 7, 9: 6), ratio 0.888. Goal met on the first round with
the gate in the data, so the ladder stopped at lever (a).

**Scratch batch G (sensitivities, not shipped).** Shrine placement: bought after Tower III 8 of 10, woke in 1 seed, 0
shots; after the castle 8; after Tower II (second round) 8; both Shrines before the castle 5 of 10 (woke in 5 seeds, 1
shot); shrine reach 14 m (from 9) 8 of 10, 0 shots; wake threshold 50 (from 100) 8 of 10, woke in 7 seeds, 0 shots.

## Owner feel items

The bots cannot judge any of these; they are for the Phase 5 gate (`/gsd-verify-work 5`):

- **The ability set and card numbers** (twelve cards, drafted by plan 05-03 from the research draft): the bot picks
  only Masons at tier II and never reaches tier III or IV, so no balance measurement exercises Engineers, Golden Age,
  War Horns or Iron Discipline. Their numbers are untouched starting points.
- **Cards re-appearing on every pass** (research A10): with enough gold the four cards show every time the king rides
  past the castle; whether that is welcome or needs a dismiss is a feel call.
- **How far the castle ladder reaches.** The ladder costs 6 / 10 / 16 against about 30 gold earned in a good eight-night
  run, so a bot reaches tier II around day 6 and never tier III. A human who skips walls and towers could climb
  further, but if the owner wants tiers III and IV to be real mid-run decisions their costs (or the income) are the
  levers; they were not touched because the bar was met.
- **The army build cannot afford the castle** (it earns about 15 gold in a run); only the tower-and-economy build uses
  the castle in this sweep. If the squad builds should also climb it, the Barracks and Range costs or the castle's
  first cost are the levers.
- **Economy mix.** The Fishing Harbor is far stronger than anything else the bots can buy (one boat more every dawn,
  1 gold each, cap 3), while the Mine (4 gold for 3, 2, then 1 a dawn), the Mill (3 for 1) and a Field (2 for 1) pay
  no better than a House and are bought last. The shapes are fixed by D-12 but the numbers (the Harbor's cost and cap,
  the Mine's first payout) are free if the owner wants a different order of attractiveness.
- **The Shrine does almost nothing in bot play.** It sits 12.5 m from the road with a 9 m reach, wakes in a minority of
  seeds and fires about never; a reach of 14 m and a lower threshold did not change that. If the owner wants a Shrine
  that visibly defends, the plots' distance to the road (a Phase 5 plot position) or its reach and wake rule need a
  decision; a plot move is outside this plan's levers.
- **What the gate does to a player who ignores the castle.** A Phase 4 style game (towers, Houses, walls, no castle)
  cannot upgrade a tower and wins about 3 of 10 against the bots' cadence; the trade-off is by design (D-03), but the
  owner should confirm it reads as a trade-off and not as a wall, especially the "Needs Castle II" label on a Tower.
