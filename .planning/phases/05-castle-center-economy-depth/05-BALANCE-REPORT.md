# Phase 5 Balance Report (plan 05-11: the castle gate ships, the bots play the new day, D-08 outcome report)

Measured 2026-10-22 (UTC) by plan 05-11 with `bash tools/playtest.sh --seeds=10` on the shipped prototype map
(`PLAYTEST_OK runs=100`: ten strategies by seeds 1 to 10, about seven minutes). As in Phases 2 to 4, these tables
are scripted bots measuring the data. They build without riding to the plots and react perfectly, so they are not
the owner's sign-off and say nothing about feel (Phase 2 D-18). The owner judges the feel of the castle, the cards,
the gate and the new buildings at the Phase 5 gate (`/gsd-verify-work 5`).

## Gap round G-05-2 and G-05-7 (plans 05-13 to 05-24)

Measured 2026-10-25 (UTC) by plan 05-23 on the final data of plans 05-13 to 05-22 with `bash tools/playtest.sh --seeds=10`
(`PLAYTEST_OK runs=100`). This is the owner's UAT round of 2026-10-22 to 2026-10-25: the x100 health and damage rescale (gap
G-05-2, the owner's hard requirement), the three recut cards (G-05-2), and the Fishing Harbor moved to an exposed spot beside the
west road (gap G-05-7). Everything below this section (`## Outcome` onward) is plan 05-11's report and stays as history. As in
every earlier report these are scripted bots measuring the data, not the owner's sign-off and not a statement about feel
(Phase 2 D-18).

### Outcome

**The Phase 2 bar holds on the final data, on the first sweep, without lowering it and without touching a bot order.**
`balanced` wins 8 of seeds 1 to 10 (bar 7 or 8), losing seed 3 on night 7 and seed 9 on night 3, exactly as before the round.
`army_balanced` wins 8 of 10 (bar 7 or 8), losing seed 1 on night 7 and seed 9 on night 6, exactly as before, with a squad value
ratio of 0.882 (bar 0.8; it was 0.888). The balanced bot still buys its first castle upgrade on day 6 at the earliest. What the
round did change, and the bar absorbed: the balanced bot now earns 26.4 gold a run (30.0 before) and loses 10.6 buildings a run
(8.6 before), because the Harbor now stands where skirmishers can reach it.

**No bot order was changed to pass the bar.** The one lever the plan kept in reserve (harbor_1's place in the balanced order,
fifth, and in the army_balanced order, seventh) was not pulled, and no night count, economy number, castle number, health,
damage or card number moved to pass it. `BALANCED_MIN_WINS` 7, `BALANCED_MAX_WINS` 8, `ARMY_BALANCED_MIN_WINS` 7,
`ARMY_BALANCED_MAX_WINS` 8 and `SQUAD_VALUE_BAR` 0.8 are unchanged, and so is every other pin in `test_balance_acceptance`.

| Strategy | Wins | Lost (seed: night) | Nights survived (mean) | Gold earned (mean) | Buildings lost (mean) | Castle tier (mean) | First upgrade (earliest day) | Squad value ratio |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| balanced | 8 of 10 | 3: 7, 9: 3 | 7.2 | 26.4 (was 30.0) | 10.6 (was 8.6) | 1.80 | 6 | n/a |
| army_balanced | 8 of 10 | 1: 7, 9: 6 | 7.5 | 14.8 (was 15.0) | 18.5 (was 18.0) | 1.00 | none | 0.882 (was 0.888) |
| balanced_no_castle | 3 of 10 | 2: 8, 4: 8, 5: 8, 6: 7, 8: 8, 9: 3, 10: 7 | 6.6 | 20.4 | 15.0 | 1.00 | none | n/a |
| balanced_no_walls | 4 of 10 | 1: 8, 3: 8, 4: 8, 6: 7, 9: 3, 10: 7 | 6.7 | 22.1 | 16.2 | 1.00 | none | n/a |
| army_balanced_no_castle | 8 of 10 | 1: 7, 9: 6 | 7.5 | 14.8 | 18.0 | 1.00 | none | 0.888 |
| army_balanced_no_walls | 8 of 10 | 1: 7, 9: 6 | 7.5 | 15.0 | 17.6 | 1.00 | none | 0.909 (was 0.915) |
| houses_first | 4 of 10 | 3: 8, 4: 8, 6: 7, 8: 8, 9: 3, 10: 7 | 6.7 | 21.1 | 14.8 | 1.00 | none | n/a |
| greedy_economy | 0 of 10 | loss nights 3 to 5 | 2.9 | 9.2 | 5.0 | 1.00 | none | n/a |
| towers_first | 0 of 10 | seven seeds on night 7, seed 8 on night 8 | 6.1 | 6.1 | 5.9 | 1.00 | none | n/a |
| no_build | 0 of 10 | night 2 on every seed | 1.0 | 1.0 | 0.0 | 1.00 | none | n/a |

- The balanced bot spends, mean per run: towers 13.2, economy 11.1, castle 4.8, shrine 0.0, military 0.0 (plan 05-11: 14.6, 13.7,
  4.8, 0.0, 0.0). The 3.6 gold the exposed Harbor no longer pays comes out of the economy and tower spend, not out of wins. The
  bot buys castle II in 8 of 10 seeds (day 6 in six of them, day 7 in one, day 8 in one), always with Masons, and the two lost
  seeds are the two that never reach it.
- `army_balanced` still never buys the castle (it earns about 15 gold and the castle costs 6 after the Barracks and Range have
  taken the first 8), so no card pick of the army bot is exercised.
- Every twin and every older bot has the same wins and the same lost seeds as plan 05-11's table, which is the statement that
  the rescale and the Harbor's new place changed the margins and not the shape.

### full_idle before and after

`bash tools/replay.sh --scenario=full_idle --twice` (seed 1, the shipped map and tuning, bot `balanced`). It has no golden file by
design; every row below is a recorded measurement, never a pin, and each pair of runs agreed.

| Point | Outcome | Ticks | Digest |
|---|---|---:|---|
| Before the round (plan 05-11 final data) | won | 7000 | `afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14` |
| After the x100 rescale (plan 05-14; unchanged by the card recut of plan 05-21) | won | 7000 | `cec3eb7182baddc2d2215916f624759510c911bfec64ed249c4ef375189b40e9` |
| After the Harbor's move (plan 05-22, Task 1) | won | 6993 | `6fd6121e0822bda3605d91ef2539e28c0649072c97df96d694be6d9346f3b019` |
| After the Harbor's health step (plan 05-22, Task 2) | won | 6993 | `c68254cda9eb986d0dcb40a3ac83d29d23f24444ed525fcfc025c9d2c656c441` |
| Final (this plan, on the committed data; nothing in the data moved in this plan) | won | 6993 | `c68254cda9eb986d0dcb40a3ac83d29d23f24444ed525fcfc025c9d2c656c441` |

Why each step moved it: the run digest folds in the hit amounts and the health values, so a rescale that makes every one of them
100 times larger changes the digest even though the fight is the same fight (same winner, same 7000 ticks; the bots' hits-to-kill
are unchanged). In this run the balanced bot picks Masons at castle II and never reaches tier III, so none of the three cards
recut in plan 05-21 is ever picked and the recut left the digest alone. The Harbor's move (a new plot position changes where the
king rides and what gets struck) shortened the run by 7 ticks and moved the digest, and the health step moved it once more at
the same length.

### Goldens (D-08)

None of the four goldens was regenerated or re-pinned, and none moved at any step of the round (they run on frozen fixture maps
with inline copies of every def, so neither the rescale nor the new Harbor position can reach them). Replayed here on the final
data, `--twice` against the checked-in files, all `REPLAY_OK`:

| Scenario | Outcome | Ticks | Digest |
|---|---|---:|---|
| smoke | won | 703 | `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (2599c7c2) |
| army | won | 1353 | `f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (f7a967ed) |
| walls | won | 1961 | `bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (bfb05fc7) |
| economy | won | 1842 | `f4b98093c0bfaaf7123d74c50fbc454024b6b5debf3137a88fb7210d14551a97` (f4b98093) |

`git diff --quiet ce3fcea` over `tests/golden` and the seven replay fixtures (the smoke, army, walls and economy maps, the smoke
and army kings, the smoke tuning) is clean, so no golden input changed either.

Gate stress (`bash tools/gate_stress.sh --twice`, the tools-only stress map, re-run here on the final data, both runs identical):
`GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0`. The crossing
statistics are exactly those of before the round. Its digest moved from `e448ffdb` to
`eb319f092e059b341cd186ce3c75306e1703a46913310d2f5b563119143efaa8` (plan 05-16), because the digest records raw health and the
stress data is scaled with the rest; it is pinned nowhere.

### The rescale (G-05-2)

The owner's hard requirement of 2026-10-25, in his words: "nah this is a hard requirement from my side so this MUST be done"
(on making every damage and health number 100 times larger, so that percentages and rounding to the nearest unit work as they
are written). What was done:

- Every health and damage number is 100 times larger in the 19 shipped data files (king, sword and its slam, footman, archer,
  grunt, skirmisher, tower, Shrine and its wake threshold, castle center tiers II to IV, the map's castle health and arrow, the
  walls, Houses, Barracks, Archery Range, Field, Gold Mine, Mill, Fishing Harbor, and Royal Training's flat king damage), in the
  seven non-golden fixtures (castle, gate, one_night, shrine, squads, walls, walls_gap) and in the tools-only stress data. Gold
  was not rescaled: costs, incomes, refunds and every other gold number are as they were.
- The per-attacker rounding carry planned first is dropped: `StatStack` keeps its one half-up rounding (D-15), and at the new
  scale that rounding no longer swallows a card's percentage (the table under `### The cards (G-05-2)`).
- The screen shows the numbers as they are (a king with 5000 health reads `5000 / 5000`, and Royal Training's `6250 / 6250`); the
  king widget's label was widened from 96 px to 128 px so the row stays on one line (plan 05-20).
- Every native-parity pin held unedited: the native enemy step reads whatever health the data carries, so no native input changed.
- With the rescale in and before the Harbor moved, every balance pin held except the grunt's own (`GRUNT_MAX_HEALTH` 6 to 600,
  plan 05-14), and the planner's scratch copy measured the bots at the pre-round numbers (balanced 8 of 10, 30.0 gold, 8.6
  buildings lost; army_balanced 8 of 10, ratio 0.88).

### The cards (G-05-2)

Owner decision of 2026-10-24 (UAT G-05-2): "all alternatives at an upgrade level are mostly viable options ... not overly weak
even in a case where its not an ideal option". Two things changed: the rescale (above), and three card recuts in data only
(plan 05-21).

The recut, old and new:

| Card | Value | Old | New | Reason |
|---|---|---|---|---|
| Prosperity (tier II) | castle gold at dawn | +1 | +2 | flat gold is worth its value times the paying dawns left |
| Golden Age (tier IV) | castle gold at dawn (its +25% shrine damage stays) | +2 | +4 | tier IV comes about one paying dawn after tier II's day-6 pick, so +4 pays about what Prosperity's +2 pays at its tier |
| Headsman's Edge (tier III) | king attack interval (its x2 king damage stays) | x1.5 | x1.25 | the old card was a third slower for no extra kill on skirmishers or after Royal Training; the worst case is now a fifth slower |

What every card says now against what it said before the round (the numbers line the castle card shows):

| Card | Numbers line before | Numbers line after |
|---|---|---|
| Royal Training | +25% king health, +1 king damage | +25% king health, +100 king damage |
| Commander | +25% unit health, +25% unit damage | +25% unit health, +25% unit damage |
| Masons | +30% building health, +30% wall health | +30% building health, +30% wall health |
| Prosperity | +1 castle gold at dawn | +2 castle gold at dawn |
| Headsman's Edge | x2 king damage, x1.5 king attack interval | x2 king damage, x1.25 king attack interval |
| Engineers | +25% tower damage, +15% tower range | +25% tower damage, +15% tower range |
| War Horns | x0.6 unit return time | x0.6 unit return time |
| Warded Mail | x0.75 damage the king takes | x0.75 damage the king takes |
| Iron Discipline | x1.5 unit damage, x1.3 unit health | x1.5 unit damage, x1.3 unit health |
| Arrow Storm | +100% castle arrow damage, +25% castle arrow range | +100% castle arrow damage, +25% castle arrow range |
| Master Builders | x1.5 building health, x1.5 wall health | x1.5 building health, x1.5 wall health |
| Golden Age | +2 castle gold at dawn, +25% shrine damage | +4 castle gold at dawn, +25% shrine damage |

The words did not change for nine cards, the results did: before the rescale the integer rounding swallowed or distorted a
percentage on a small base. The same cards on the same base, before (the round's base commit, health and damage divided by 100)
and after (the shipped data), printed through the real `StatStack` (plan 05-21; its SUMMARY holds the table for every shipped
base, about ninety rows):

| Card | Stat, base | Before (result, change) | After (result, change) |
|---|---|---|---|
| Royal Training | king damage, sword | 5 -> 6 (+20%) | 500 -> 600 (+20%) |
| Commander | unit damage, footman | 1 -> 1 (+0%) | 100 -> 125 (+25%) |
| Commander | unit health, footman | 10 -> 13 (+30%) | 1000 -> 1250 (+25%) |
| Masons | building health, house 1 | 12 -> 16 (+33%) | 1200 -> 1560 (+30%) |
| Prosperity | castle income, tier II | 2 -> 3 (+50%) | 2 -> 4 (+100%) |
| Headsman's Edge | king attack interval, sword | 0.700 -> 1.050 (+50%) | 0.700 -> 0.875 (+25%) |
| Engineers | tower damage, tower I | 3 -> 4 (+33%) | 300 -> 375 (+25%) |
| War Horns | squad respawn, Barracks I | 10.0 -> 6.0 s (-40%) | 10.0 -> 6.0 s (-40%) |
| Warded Mail | damage the king takes, grunt blow | 2 -> 2 (+0%) | 200 -> 150 (-25%) |
| Iron Discipline | unit damage, footman | 1 -> 2 (+100%) | 100 -> 150 (+50%) |
| Arrow Storm | castle arrow damage, tier IV | 5 -> 10 (+100%) | 500 -> 1000 (+100%) |
| Master Builders | building health, tower I | 50 -> 75 (+50%) | 5000 -> 7500 (+50%) |
| Golden Age | castle income, tier IV | 4 -> 6 (+50%) | 4 -> 8 (+100%) |
| Golden Age | shrine damage, Shrine | 3 -> 4 (+33%) | 300 -> 375 (+25%) |

Blows to kill, before the round (grunt 6, skirmisher 4) and now (grunt 600, skirmisher 400); a card is read in blows, because a
percentage changes a kill only when it crosses a whole enemy:

| Attacker (card) | Before: damage, blows to a grunt / skirmisher | After: damage, blows to a grunt / skirmisher |
|---|---|---|
| king, no card | 5, 2 / 1; interval 0.700 s | 500, 2 / 1; interval 0.700 s |
| Royal Training | 6, 1 / 1; interval 0.700 s | 600, 1 / 1; interval 0.700 s |
| Headsman's Edge | 10, 1 / 1; interval 1.050 s | 1000, 1 / 1; interval 0.875 s |
| Royal Training + Headsman's Edge | 12, 1 / 1; interval 1.050 s | 1200, 1 / 1; interval 0.875 s |
| footman, no card | 1, 6 / 4 | 100, 6 / 4 |
| Commander (footman) | 1, 6 / 4 | 125, 5 / 4 |
| Iron Discipline (footman) | 2, 3 / 2 | 150, 4 / 3 |
| Commander + Iron Discipline (footman) | 2, 3 / 2 | 188, 4 / 3 |
| tower I, no card | 3, 2 / 2 | 300, 2 / 2 |
| Engineers (tower I) | 4, 2 / 1 | 375, 2 / 2 |
| tower II, no card | 6, 1 / 1 | 600, 1 / 1 |
| Engineers (tower II) | 8, 1 / 1 | 750, 1 / 1 |
| castle IV arrow, no card | 5, 2 / 1 | 500, 2 / 1 |
| Arrow Storm (castle IV) | 10, 1 / 1 | 1000, 1 / 1 |
| Shrine, no synergy | 3, 2 / 2 | 300, 2 / 2 |
| Shrine + synergy (1 other awake) | 4, 2 / 1 | 360, 2 / 2 |
| Golden Age on a lone Shrine | 4, 2 / 1 | 375, 2 / 2 |
| Golden Age + synergy | 4, 2 / 1 | 435, 2 / 1 |

In one sentence: a percent of damage changes a kill only when it crosses a whole enemy, so Engineers' honest +25% (375) changes no
Tower I kill (the old rounding turned 3 into 4, which one-shot a 4-health skirmisher; that was a rounding accident, not the
card), while Commander's honest +25% (125) takes a grunt in 5 blows instead of 6. A later way to make the steps finer is to raise
enemy health relative to damage; that is an owner feel item, not done here.

#### Tier II cards on the final data

The balanced bot played seeds 1 to 10 six times with only its tier II pick swapped (the later picks Engineers and Golden Age as
shipped, which a tower bot never reaches), in a scratch copy of the debug session's `tier2_probe.gd` (read-only; the value of
Prosperity is set in memory and nothing is saved). The `masons` row is the shipped bot and equals the sweep's `balanced` row
exactly (8 of 10, 26.4, 10.6), the cross-check that the probe plays the shipped game.

| Tier II pick | Wins | Lost seeds | Gold earned (mean) | Buildings lost (mean) | Same pick on the old map (debug session, before the Harbor moved) |
|---|---:|---|---:|---:|---|
| Masons (shipped) | 8 of 10 | 3, 9 | 26.4 | 10.6 | 8 of 10, 30.0, 8.6 |
| Royal Training | 8 of 10 | 3, 9 | 23.2 | 15.4 | 8 of 10, 28.6, 11.7 |
| Commander (a null card: the balanced bot fields no squads) | 4 of 10 | 3, 5, 6, 8, 9, 10 | 21.9 | 16.0 | 7 of 10, 27.3, 12.8 |
| Prosperity +1 (the old value, in memory only) | 5 of 10 | 3, 6, 8, 9, 10 | 23.3 | 14.9 | 7 of 10, 28.8, 12.3 |
| Prosperity +2 (shipped) | 6 of 10 | 3, 6, 8, 9 | 25.4 | 14.2 | 8 of 10, 31.7, 11.0 |
| Prosperity +3 (in memory only) | 6 of 10 | 3, 6, 8, 9 | 26.6 | 14.2 | 8 of 10, 33.1, 11.0 |

**Prosperity verdict.** The rule set before the measurement: `+2` passes if its mean gold earned is at least Masons' and its wins
are at least Masons' minus one. On the final data `+2` earns 25.4 gold against Masons' 26.4 (short by 1.0) and wins 6 against
Masons' 8 (two short, one allowed): it fails both halves. `+3` was then measured the same way (in the same probe run, so on
identical seeds and code): 26.6 gold, which meets the gold half (at least 26.4), but 6 wins, which still misses the win half (at
least 7). Neither value passes, so **Prosperity ships at its landed +2** and both measurements are an owner feel item.

Reading it plainly: on this map the tower bot's best tier II card is Masons by a clear margin. Every other card loses 14 to 16
buildings a run against Masons' 10.6, and Masons wins seeds 6 and 8, which Prosperity (at +1, +2 and +3) loses. The likeliest
cause is the Harbor's new place (on the old map Prosperity +2 matched Masons on wins, 8 of 10, and beat it on gold, 31.7 against
30.0): +30% building health keeps the struck Harbor and its neighbours standing, and an income card cannot buy that back for a
bot that has spent its gold by day 7 in any case. This is a reading, not a measurement. Prosperity's +3 does close the gold gap
(26.6 against 26.4), so what it costs the player is roughly "Masons' gold, without Masons' health". Commander's 4 of 10 is not a
verdict on Commander: the balanced bot fields no squads, so the card does nothing for it, and the row only measures what going
without Masons costs (Royal Training, whose king damage and health do help this bot, also loses the buildings but keeps 8 of 10).

### Viability basis per card

The three tier II cards the balanced bot can use are measured (the table above); the other nine cards (Commander, which the
balanced bot's order never picks and the army bot never reaches because it never buys the castle, and the eight tier III and IV
cards, which no bot reaches) are judged by the owner in play on an analytic basis, with no measurement, because no bot reaches
those tiers or fields soldiers. Plan 05-24 turns each of those nine rows into a decision for the owner. Costs of the castle
tiers: II 6, III 10, IV 16 gold; numbers are as the card shows them at the x100 scale.

| Tier | Card | Numbers as the card shows them | Basis |
|---|---|---|---|
| II | Royal Training | +25% king health, +100 king damage | measured: 8 of 10, 23.2 gold, 15.4 buildings lost (Masons 8 of 10, 26.4, 10.6); a king card: +100 lets the king fell a 600 grunt in one blow instead of two, and +25% health is 5000 to 6250 |
| II | Commander | +25% unit health, +25% unit damage | owner-judged, no measurement: lands exactly (125 a blow, so a grunt in 5 blows instead of 6 and a skirmisher still in 4; footman 1250 and archer 750 health); the balanced bot fields no squads (a null card for it) and army_balanced never buys the castle |
| II | Masons | +30% building health, +30% wall health | measured: 8 of 10, 26.4 gold, 10.6 buildings lost, the strongest tier II card for the tower bot (see the tier II comparison) |
| II | Prosperity | +2 castle gold at dawn | measured: 6 of 10, 25.4 gold, 14.2 buildings lost; +3 measured 6 of 10, 26.6 gold; neither passes the rule, so +2 ships (see the verdict above) |
| III | Headsman's Edge | x2 king damage, x1.25 king attack interval | owner-judged, no measurement: 1000 a blow at a 0.875 s interval, so against one-hit kills a fifth slower and against a grunt without Royal Training 1.6 times the kill rate (one blow every 0.875 s instead of two in 1.40 s); with Royal Training the grunt already dies in one blow, so the card then buys no extra kill |
| III | Engineers | +25% tower damage, +15% tower range | owner-judged, no measurement: +25% lands exactly (375 and 750) but changes no kill against the shipped roster (Tower I still needs 2 blows on a grunt and 2 on a skirmisher, Tower II kills in 1 already), so what it adds is the +15% range (9.0 to 10.35 m, 10.5 to 12.075 m) |
| III | War Horns | x0.6 unit return time | owner-judged, no measurement: unchanged by the rescale (respawn x0.6, a float: 10 to 6 s, 7 to 4.2 s, 4 to 2.4 s), so it is only as good as the squads it speeds up |
| III | Warded Mail | x0.75 damage the king takes | owner-judged, no measurement: every 200 blow becomes 150, so the king falls on the 34th grunt blow instead of the 25th; before the rescale it did nothing (2 stayed 2) |
| IV | Iron Discipline | x1.5 unit damage, x1.3 unit health | owner-judged, no measurement: an honest x1.5 (100 to 150, a grunt in 4 blows instead of 6; it was x2 by rounding) and x1.3 health (1000 to 1300, 600 to 780) |
| IV | Arrow Storm | +100% castle arrow damage, +25% castle arrow range | owner-judged, no measurement: doubles the arrow exactly (castle IV 500 to 1000, a grunt in 1 arrow instead of 2), range 22 to 27.5 m |
| IV | Master Builders | x1.5 building health, x1.5 wall health | owner-judged, no measurement: x1.5 exactly (house 1 1200 to 1800, tower I 5000 to 7500, wall III 9000 to 13500), the shape of Masons at +50% instead of +30% |
| IV | Golden Age | +4 castle gold at dawn, +25% shrine damage | owner-judged, no measurement: +4 dawn gold (was +2), about what Prosperity's +2 pays at tier II because tier IV comes about one paying dawn after the day-6 tier II pick; +25% shrine damage (300 to 375, and 435 with the synergy, which one-shots a 400 skirmisher) |

Tiers III and IV are unreachable by the bots at the 6 / 10 / 16 castle ladder (a balanced run earns about 26 gold), so the eight
tier III and IV rows cannot be measured without changing the ladder or the bot.

### The Harbor (G-05-7)

The owner's report (UAT test 7): the Fishing Harbor was risk-free, because no enemy ever noticed it. The debug session found why
(a plot 19 to 20 m from every road, behind the castle, inside the castle arrow's reach, held there by a test rule) and measured
candidate places. Plan 05-22 built the recommended proposal A:

| Value | Before | After the rescale (plan 05-14) | Now (plan 05-22) |
|---|---|---|---|
| harbor_1 position | (0, 0, 20.5), south of the castle | same | (-39.93, 0, 25.48), beside the west road |
| pond centre and radius | (0, 30), radius 8 | same | (-37.71, 31.59), radius 4.5 |
| Harbor health, tier I / II | 18 / 24 | 1800 / 2400 | 1400 / 2000 |
| distance from the west road | 19.3 m | same | 10.30 m (harbor_1 alone has its own 9.0 to 10.5 m road band) |

The pond was pushed 1.5 m farther out along the road's normal than the debug session's proposal (centre (-38.22, 30.18)), so the
dock stands 6.5 m from the water's middle, 2.0 m from its edge, on dry land. The pond is visual only, so the debug session's bot
numbers at that spot still hold. Cost, boat caps, boat gold and the castle gate are untouched.

Exposure, measured by plan 05-22 with a scratch copy of the debug session's `probe4.gd` on the committed data (seeds 1 to 10; no
bot order moved in this plan, so the table stands and was not re-run); "built" counts seeds in which harbor_1 stood at least
once, "struck" seeds with at least one hit on it:

| Bot | Wins | Lost seeds | Built in seeds | Struck in seeds | Destroyed in seeds | Destructions | Boat gold (mean) | Gold earned (mean) |
|---|---|---|---|---|---|---|---|---|
| balanced | 8 of 10 | 3, 9 | 1 to 8 and 10 (9 seeds; seed 9 lost on night 2 before building it) | 1, 3, 4, 5, 6, 7, 8 (7 of the 9 built) | 3, 4, 5, 6, 7, 8 (6 seeds) | 18 | 3.5 | 26.4 |
| army_balanced | 8 of 10 | 1, 9 | 2, 3, 4 (the army bot rarely buys it) | 2, 3, 4 (all 3 built) | 2, 3, 4 | 5 | 0.0 | 14.8 |

The Harbor is struck in 7 of the 9 balanced seeds in which it is built and destroyed 18 times over ten runs; skirmishers notice it
(10.5 m centre to centre) and grunts do not (7.5 m), and no tower or keep arrow reaches it even through Engineers and Arrow Storm
(`test_harbor_exposure`). The bots never ride out to defend it, so this is the worst case. The sweep's 26.4 gold and 10.6
buildings lost (same two lost seeds) are the price of that exposure.

Alternatives rejected (debug session, bot probes on seeds 1 to 10, measured at the pre-rescale scale, so the health pair there is
14 / 20; the ratios carry over):

| Alternative | Place | Result | Why not |
|---|---|---|---|
| B: west road, north side | Harbor (-45.09, 5.43), pond (-47.92, -2.37) radius 8 | 8 of 10, 26.8 gold, 3.3 boat gold, same lost seeds 3 and 9 | the Harbor lands on the pond's south shore with its dock facing away from the water (`BuildSpotDef` has no facing) |
| C: north road | Harbor (-8, -40), pond (-18.6, -38.6) radius 8 | at 18 / 24 health 7 of 10 (lost seeds 3, 8 and 9, which breaks the pinned lost seeds), 29.3 gold, 6.4 boat gold, destroyed 5 times; at 14 / 20 health 8 of 10 (lost 3 and 9), 5.5 boat gold, destroyed 8 times | it is struck only from night 6 (when the north spawns open), so for most of the run it is as safe as before; it stays available to the owner as the measured alternative (the north-road Harbor at 1400 / 2000) |

### Numbers changed

Every value this round changed, old to new (gold and the percent and multiplier cards other than the three recuts did not move):

| File or pin | Field | Old | New |
|---|---|---|---|
| king.tres | max_health | 50 | 5000 |
| sword.tres | attack_damage / slam_damage | 5 / 4 | 500 / 400 |
| footman.tres | max_health / attack_damage | 10 / 1 | 1000 / 100 |
| archer.tres | max_health / attack_damage | 6 / 1 | 600 / 100 |
| grunt.tres | max_health / attack_damage | 6 / 2 | 600 / 200 |
| ranged.tres (Skirmisher) | max_health / attack_damage | 4 / 2 | 400 / 200 |
| tower.tres tier I | attack_damage / max_health | 3 / 50 | 300 / 5000 |
| tower.tres tier II | attack_damage / max_health | 6 / 70 | 600 / 7000 |
| shrine.tres | attack_damage / max_health / wake_threshold_hp | 3 / 30 / 100 | 300 / 3000 / 10000 |
| castle_center.tres tier II | attack_damage / max_health | 3 / 100 | 300 / 10000 |
| castle_center.tres tier III | attack_damage / max_health | 4 / 140 | 400 / 14000 |
| castle_center.tres tier IV | attack_damage / max_health | 5 / 200 | 500 / 20000 |
| prototype_map.tres | castle_max_health / castle_attack_damage | 70 / 2 | 7000 / 200 |
| wall.tres | max_health (3 tiers) | 30 / 60 / 90 | 3000 / 6000 / 9000 |
| house.tres | max_health (3 tiers) | 12 / 18 / 24 | 1200 / 1800 / 2400 |
| barracks.tres and archery_range.tres | max_health (3 tiers) | 40 / 60 / 80 | 4000 / 6000 / 8000 |
| field.tres | max_health | 8 | 800 |
| gold_mine.tres | max_health | 20 | 2000 |
| mill.tres | max_health (3 tiers) | 15 / 20 / 25 | 1500 / 2000 / 2500 |
| fishing_harbor.tres | max_health (2 tiers) | 18 / 24 | 1400 / 2000 (1800 / 2400 after the rescale, then a step lower in plan 05-22) |
| royal_training.tres | king.attack_damage flat value | +1 | +100 |
| seven non-golden fixtures and the stress data | the same health and damage fields (castle 70 / 2 to 7000 / 200, the stress king 100000 to 10000000, the bench castle 10000000 to 1000000000) | x1 | x100 |
| king widget label | minimum width | 96 px | 128 px |
| prosperity.tres | castle.base_income flat value | +1 | +2 |
| golden_age.tres | castle.base_income flat value | +2 | +4 |
| headsmans_edge.tres | king.attack_interval multiplier | x1.5 | x1.25 |
| prototype_map.tres | harbor_1 position | (0, 0, 20.5) | (-39.93, 0, 25.48) |
| prototype_map.tres | pond centre and radius | (0, 30), 8 | (-37.71, 31.59), 4.5 |
| test_balance_acceptance | GRUNT_MAX_HEALTH | 6 | 600 (every other balance pin unchanged, as the test's header lists) |
| test_balance_acceptance | header | the plan 05-14 gap paragraph | plus the gap round G-05-2 and G-05-7 paragraph (this plan) |
| prosperity.tres (the conditional lever of plan 05-23) | castle.base_income flat value | +2 | not changed: neither +2 nor +3 passed the rule, so +2 stands |

### Search log

- **Round 1 (the only sweep): `bash tools/playtest.sh --seeds=10`**, committed data of plans 05-13 to 05-22, no bot order moved.
  `PLAYTEST_OK runs=100`. balanced 8 of 10 (lost 3: night 7, 9: night 3), 26.4 gold, 10.6 buildings lost, mean castle tier
  1.80, first upgrade day 6 at the earliest; army_balanced 8 of 10 (lost 1: 7, 9: 6), 14.8 gold, ratio 0.882 (unit kills per
  military gold 4.58, tower kills per tower gold 5.19). The bar held, so the lever (harbor_1's place in an order) was not pulled
  and rounds 2 and 3 were not needed.
- **Tier II probe (`tier2_probe.gd`, seeds 1 to 10, balanced order, one run, six variants):** masons 8 of 10 / 26.4 / 10.6;
  royal_training 8 / 23.2 / 15.4; commander 4 / 21.9 / 16.0; prosperity +1 5 / 23.3 / 14.9; prosperity +2 6 / 25.4 / 14.2;
  prosperity +3 6 / 26.6 / 14.2. The +2 and +3 variants were measured in the same run rather than the +3 after a data edit,
  because the probe sets the value in memory; the result is what a +3 file would measure.
- **Goldens and full_idle** (`--twice`): smoke, army, walls and economy unchanged; full_idle won in 6993 ticks, digest
  `c68254cd`. **Gate stress** (`--twice`): the plan 05-16 statistics, digest `eb319f09`.

### Owner feel items

The bots cannot judge any of these; they are for the owner's re-check (UAT tests 2, 5 and 7 are the ones to re-judge):

- **No bot order was changed to pass the bar.** The bar held on the first sweep with the Harbor fifth in the balanced order and
  seventh in the army order, so the Phase 2 bar is met by the game, not by a bot edit.
- **Prosperity is the weakest tier II card by measurement, at both +2 and +3.** On the final data the tower bot wins 8 of 10 with
  Masons (26.4 gold, 10.6 buildings lost), 6 of 10 with Prosperity +2 (25.4, 14.2) and 6 of 10 with Prosperity +3 (26.6, 14.2).
  +3 would match Masons on gold but not on wins. If "every card viable" should mean wins as well as gold, Prosperity needs to buy
  something other than gold (a different effect), or Masons' +30% needs to come down; both are the owner's call and neither was
  done, because the plan's rule leaves +2 in place.
- **The new card numbers**: Prosperity +2, Golden Age +4 (and +25% shrine damage), Headsman's Edge x2 damage at x1.25 interval
  (alternatives: Golden Age +3 or the old +2; Headsman's Edge at the old x1.5, or with no slowdown, which would make it an
  always-take).
- **Numbers shown as they are.** A king with 5000 health reads `5000 / 5000`. If the owner would rather read the old small
  numbers, dividing the displayed value by 100 is an alternative (the simulation would keep the large integers).
- **The hits-to-kill steps.** The percentages now land as written, but a percent only changes a kill when it crosses a whole
  enemy: Engineers' +25% changes no Tower I kill and Commander takes a grunt from 6 blows to 5. If the owner wants finer steps,
  raising enemy health relative to damage is the later lever (not done).
- **Whether the exposed Harbor feels awkward to defend.** It is struck in 7 of the 9 balanced seeds in which it is built and
  destroyed 18 times in ten runs, because the bots never ride out to save it; a human who defends it will lose less. Proposal C
  (the north-road Harbor at 1400 / 2000) is the measured alternative if this reads as too punishing.
- **The castle ladder still costs 6 / 10 / 16** against about 26 gold earned in a balanced run, so no bot reaches tier III; the
  eight tier III and IV cards above are owner-judged for that reason.
- **The wider king widget**: the label is 128 px (was 96) so `6250 / 6250` fits on one line; the row now spans x 16 to 408.
- **Tests 2, 5 and 7 of the UAT** (the twelve abilities, the day's depth and fun, the economy mix with the Harbor) are the ones
  the owner re-judges after this round; plan 05-24 hands over the build and the list.

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
