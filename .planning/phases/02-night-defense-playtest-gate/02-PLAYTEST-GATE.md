# Phase 2 Playtest Gate: Night Defense (owner packet)

You are the gate (D-18, ROADMAP success criterion 4). Claude has checked everything it can observe and lists it below. It cannot tell you whether the loop is fun. Spend one or two full runs on that, then sign off or name the fixes. Nothing here counts as your sign-off.

## Round 4 (after your playtest of 2026-10-07, round 3)

In round 3 you passed the castle's 22 m reach and 27 m/s arrows, the fast-forward toggle, the full-wall difficulty and assumptions 12 to 15, and asked for one change: the king's normal speed 1.5x, with the sprint kept at its current magnitude, which you clarified as walk 7.5 m/s, sprint 12 m/s, fast-forward still 2x. It is in this build. The bots' numbers and Claude's screenshot review below are evidence only; **they are not your sign-off**. Your round-4 decision, recorded through `/gsd-verify-work`, answers the round-3 gate (G-02-18, ROADMAP success criterion 4, D-18).

### How to play round 4

- **Exported build:** `build/windows/Duskhold.exe`, freshly exported on 2026-10-07 (UTC) from the final round-4 state; it launched and quit cleanly in a headless check (`--headless --quit-after 120`, exit 0 in about 3 s). It replaces the round-3 export.
- **From the editor binary, in PowerShell** (PowerShell's `bash` is WSL, so the Git Bash wrappers are not your entry point):

  ```powershell
  & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path .
  ```

### What changed

| Your fix (round 3) | What changed | Plan |
|---|---|---|
| The king's normal speed 1.5x, sprint kept at the same magnitude (G-02-18) | The walk is **7.5 m/s instead of 5**. The sprint is **exactly 12 m/s, unchanged**; its multiplier is now **1.6** (was 2.4), which is the source game's walk-to-sprint ratio again. Acceleration is 60, unchanged, so the king stops **0.47 m** after you let go at a walk (was 0.21 m) and **1.2 m** after a full sprint (unchanged), both well inside the 2.5 m build radius. The night fast-forward is still 2x. The map is the same size: D-03's ride budget was amended instead (edge to edge about 15 s at the walk and about 9 s at the sprint) | 02-21 |

Ride times at the walk, before and after (the sprint is 12 m/s in both):

| Ride | Distance | Walk before (5 m/s) | Walk after (7.5 m/s) |
|---|---:|---:|---:|
| King spawn to the inner Houses | 9.2 m | 1.84 s | 1.23 s |
| King spawn to houses 3 and 4 | 26.2 m | 5.23 s | 3.49 s |
| King spawn to house 5 | 31 m | 6.2 s | 4.13 s |
| King spawn to tower_1 or tower_2 | 56.5 m | 11.3 s | 7.54 s |
| King spawn to tower_3 | 62 m | 12.4 s | 8.27 s |
| Farthest pair, tower_1 to tower_2 | 110 m | 22.0 s | 14.67 s (9.17 s at the sprint) |

- Sprinting now adds 4.5 m/s instead of 7, so holding Shift matters less: it saves 37.5% of a ride instead of 58%.
- At night the walking king is 2.3x as fast as a grunt (3.2 m/s); it was 1.6x. (Against a skirmisher's 2.8 m/s it is 2.7x, was 1.8x.)

### Controls (round 4)

| Action | Keyboard | Gamepad |
|---|---|---|
| Ride (walk 7.5 m/s, was 5) | WASD or arrow keys | left stick |
| Sprint (12 m/s, unchanged) | Shift | right shoulder |
| Fast-forward (press to switch on, press again to switch off; **night only**, 2x; off again when the night ends) | F | left trigger |
| Build or upgrade (ride to a plot, hold) | E or Space | A |
| Start the night (hold, by day) | N | Y |
| Debug overlay (shows the run seed, wave state, enemy path lines) | F3 | Back |
| Camera zoom | = and - (also keypad) | right stick up and down |

### What Claude checked in round 4

**Automated checks** (plan 02-22, on the final round-4 state; plan 02-21 changed two lines of `data/king/king.tres` and this plan changed no game data or code):

- Test suite: 831 tests in 95 scripts, all passing; lint and format clean (`bash tools/test.sh`, `bash tools/lint.sh`).
- Seeded replays, identical to round 3: smoke `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden unchanged); `full_idle` run twice `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac`.
- Windows build: `bash tools/export.sh` exported `build/windows/Duskhold.exe` and `build/windows/Duskhold.exe --headless --quit-after 120` exits 0 in about 3 s. CI has not been run on this branch state (nothing was pushed).
- **No bot number moved, and none was re-measured.** The building bots sprint on every tick at exactly 12.0 m/s (5.0 x 2.4 and 7.5 x 1.6 are both exactly 12.0), and the `no_build` bot never moves, so the bots cannot see a walk change. The diagnosis ran all five strategies on seeds 1 to 10 on this exact data and its report was byte-identical to the round-3 baseline. The Round 3 balance table (`02-BALANCE-REPORT.md`, with a short Round 4 note above it) stands.
- **Screenshots** (all 15 scripted shots re-run in a real window on the round-4 data, "Saved 15 of 15"; the shot-list guard passes; no scenario had to change). Three of them walk the bot king to a hold point at the new walk pace:

| Shot | What it shows | Result |
|---|---|---|
| `night_combat` | Night 5 of 8, 19 enemies left: red grunts and violet skirmishers at the lower left, a pink arrow in flight, the king beside the tower, Gold 0 | Pass; looks the same as the round-3 frame |
| `king_down_countdown` | Night 7 of 8, 1 enemy left: the king as a cyan ghost capsule, "Knocked out - back in 6 s", a violet skirmisher, a cluster of yellow arrow streaks from the tower at the top right | Pass; the same as round 3 apart from one tower arrow a few pixels along its path |
| `overlay_paths` | Debug overlay open on night 1 (2 enemies left): the stats panel, a white enemy path line running to the castle, one grunt at the left, the king at the castle front with an arrow beside him | Pass; the grunt and arrow sit slightly differently from round 3 and the panel's FPS reads 110 instead of 15, which is frame timing in a real window, not a changed state |

**What nobody has checked:** how the 7.5 m/s walk and the smaller sprint step feel in your hands, and whether the king still stops where you mean him to on a plot, from a walk and from a sprint.

### Assumptions (round 4; 12 is restated, 13 to 15 stand as in round 3)

12. The bots build without riding to plots, sprint at 12 m/s at night on every tick and never walk, and the castle shoots for them too, so the faster walk cannot move a single bot number. The measurement rule and the target (the balanced bot wins 7 or 8 of 10 seeds) are the ones you confirmed, and the measured result is the Round 3 one: balanced 8 of 10 (seeds 3 and 9 lost on night 3), 36 of 50.

### Your decision (round 4)

Play one or two full runs on the new build, then tell Claude in the `/gsd-verify-work` session:

- **Sign off:** the 7.5 m/s walk feels right with the sprint still at 12 m/s, and everything you passed in round 3 still holds. Phase 2 closes and Phase 3 can begin.
- **Fixes first:** name what is still needed (for example: the walk still too slow or too fast, the king stopping short of or past a plot, the sprint feeling too small a step now), and any of assumptions 12 to 15 you want changed.

The decision is recorded through `/gsd-verify-work`. No meta-progression work starts before it.

---

Round 3, Round 2 and Round 1 below are kept as they were; where they disagree with Round 4 (the walk speed, the ride and sprint rows of the controls table, assumption 12's wording, the export date), Round 4 wins.

## Round 3 (after your playtest of 2026-10-07)

In round 2 you asked for three fixes and passed everything else (base gold, results spacing, sprint and braking, the 2x pace and its label, fast-forward by night only). All three fixes are in this build: the castle reaches farther and its arrows fly faster, fast-forward is now a toggle, and the game is harder through the night counts (the full wall you chose). The bots' numbers and Claude's screenshot review below are evidence only; **they are not your sign-off**. You decide again (D-18, ROADMAP success criterion 4), and only your decision, recorded through `/gsd-verify-work`, closes the round-2 gate (G-02-12).

### How to play round 3

- **Exported build:** `build/windows/Duskhold.exe`, freshly exported on 2026-10-07 (UTC) from the final round-3 state; it launched and quit cleanly in a headless check (`--headless --quit-after 120`, exit 0 in about 1 s). It replaces the round-2 export.
- **From the editor binary, in PowerShell** (PowerShell's `bash` is WSL, so the Git Bash wrappers are not your entry point):

  ```powershell
  & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path .
  ```

### What changed for each of your fixes

| Your fix (round 2) | What changed | Plan |
|---|---|---|
| Castle attack farther and faster (G-02-13) | The castle now reaches **22 m instead of 11**, and its arrows fly at **27 m/s instead of 18**. Its damage is unchanged: 2 every 1.5 s, so **3 hits per grunt and 2 per skirmisher**. It now covers the two inner House plots, so a lone grunt dies before it reaches the wall and a lone skirmisher before it shoots. It fires only when an enemy gets within 22 m: on the new night counts the balanced bot's castle kills about 4 of the 12 enemies of night 2 and about 2 of the 21 of night 3 (seeds 1 to 10), but a defence that stops every enemy farther out, as the balanced bot's did under the round-2 counts, still never makes it fire | 02-17 |
| Fast-forward as a toggle (G-02-14) | During a night, press **F** (or pull the **left trigger**) once and the game runs at 2x and stays there after you let go, with the "Fast-forward 2x" label showing; press it again and it returns to normal speed and the label disappears. Each press counts once however long you hold it, and a trigger that hovers around halfway counts once until you let it go nearly all the way. It switches itself off the moment the night ends (dawn, victory or defeat), so every night starts at normal speed and the loss beat and results screen run in real seconds. Pressing the key by day, at dawn or on the results screen does nothing, and a key you are still holding when the night begins does not switch it on (you need a fresh press) | 02-18 |
| Harder: "a little harder, the balanced bot should lose 2 to 3 times out of 10" (G-02-15) | Night 2 now comes from two roads, and nights 3 to 5 are heavier: night 2 W8 becomes W8 E4, night 3 W6 E5 becomes W11 E10, night 4 W7 E4 [E3] becomes W11 E7 [E3], night 5 W7 E7 [W2 E2] becomes W9 E8 [W2 E2] (grunts per road, skirmishers in brackets). Night totals go from 5, 8, 11, 14, 18, 22, 27, 33 to **5, 12, 21, 21, 21, 22, 27, 33**; nights 1 and 6 to 8 are unchanged. Measured: the balanced bot wins **8 of 10** (seeds 1 to 10), against your target of 7 or 8, and loses seeds 3 and 9, both on night 3. On seeds 1 to 50 it wins 36 of 50 (72%). The difficulty sits in one place, the night-3 wall explained below | 02-19 |

### Controls (round 3)

| Action | Keyboard | Gamepad |
|---|---|---|
| Ride | WASD or arrow keys | left stick |
| Sprint (12 m/s) | Shift | right shoulder |
| Fast-forward (press to switch on, press again to switch off; **night only**, 2x; off again when the night ends) | F | left trigger |
| Build or upgrade (ride to a plot, hold) | E or Space | A |
| Start the night (hold, by day) | N | Y |
| Debug overlay (shows the run seed, wave state, enemy path lines) | F3 | Back |
| Camera zoom | = and - (also keypad) | right stick up and down |

### What Claude checked in round 3

**Automated checks** (plan 02-20, on the final round-3 state; this plan changed no game data or code):

- Test suite: 829 tests in 95 scripts, all passing; lint and format clean (`bash tools/test.sh`, `bash tools/lint.sh`).
- Seeded replays: smoke `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden unchanged); `full_idle` run twice `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac` (was 4007 ticks in round 2: the heavier nights take the bot longer).
- Windows build: `bash tools/export.sh` exported `build/windows/Duskhold.exe` and `build/windows/Duskhold.exe --headless --quit-after 120` exits 0 in about 1 s. CI has not been run on this branch state (nothing was pushed).
- 50-seed balanced line (`bash tools/playtest.sh --strategies=balanced --seeds=50`): **36 of 50 won (72%)**; all 14 losses are on night 3.

**Balance round 3, from scripted bots** (`02-BALANCE-REPORT.md` Round 3, seeds 1 to 10, shipped data; reproduce with `bash tools/playtest.sh`; rounds 2 and 1 are kept beside it in the report). The bots build instantly without riding, react perfectly and start every night at once, so this measures the data, not a player.

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.4 / 2 / 3 | 3 | 7.3 | 4.0 | 1.4 |
| houses_first | 80% | 6.8 / 2 / 8 | 3 | 24.5 | 2.9 | 0.4 |
| towers_first | 100% | 8.0 / 8 / 8 | - | 7.0 | 2.0 | 2.8 |
| balanced | 80% | 6.8 / 2 / 8 | 3 | 22.3 | 2.7 | 0.4 |

Reading: the balanced and House-first openings win 8 of 10 and lose the same two seeds (3 and 9) on night 3; the tower-first opening wins every run with the castle untouched until night 8; pure House greed (greedy_economy) now dies on night 3 or 4 on every seed; doing nothing dies on night 2 (the castle kills all five night-1 grunts for it). A person plays worse than these bots, so a human will be markedly worse than every row above.

**Screenshot review** (Claude opened these seven of the 15 scripted shots on the round-3 data, real window, Forward+; all 15 were saved and the shot-list guard passes; no scenario had to change):

| Shot | What it shows | Result |
|---|---|---|
| `spawn_telegraph` | Day, Tower II standing, Gold 26; one red marker with a "5" at the screen's lower left over the west road, "Hold N / (Y) to start Night 1" and "Night 1: 5 enemies from 1 direction" | Pass; it is night 1, which has one road, so one marker is right; the two-marker look of night 2 on is not in a still frame and is for you to see in play |
| `night_combat` | Night 5 of 8, 19 enemies left: red grunts and violet skirmishers by the west side of the tower, a pink skirmisher arrow in flight, the king beside the tower, Gold 0 | Pass; no gold castle arrow in frame (the castle is off screen, nothing is within 22 m of it in this shot) |
| `building_destroyed` | Night 3 of 8, 8 enemies left: a fallen House as dark slabs on its pale disc with grunts crowding the king, health bars on the king and a grunt, the castle at the top left, "+14 gold" | Pass |
| `king_down_countdown` | Night 7 of 8, 1 enemy left: the king as a cyan ghost capsule, "Knocked out - back in 6 s" in cyan, a violet skirmisher, a cluster of yellow arrow streaks from a tower at the top right | Pass; the arrow cluster is the shot's fast-forward launching them in one frame (a shot artifact, as in round 1) |
| `dawn_payout` | Dawn, Gold 23: gold coins in flight around the castle and the two House plots (two at the castle front and top, one over each House side), two Houses with teal roofs | Pass; a still frame cannot say which coin is the castle's base coin, so judge that in play |
| `results_victory` | "Victory", Nights survived 1 of 1 (the shot keeps one night), four stat rows, then Play again (outlined) and Quit, the gaps even | Pass |
| `results_defeat` | "Defeat", Nights survived 0 of 8, the same even spacing, grunts crowding the dark castle behind the panel | Pass |

**What nobody has checked:** whether it is fun, whether the 22 m castle with 27 m/s arrows reads and feels right in a real fight, whether the toggle feels right on your keyboard and gamepad (the trigger edges were tested with synthetic input, never a physical trigger), and whether the game is now "a little harder" or a wall that is too abrupt.

### The night-3 wall, plainly

The extra difficulty is **one wall on night 3 that only a House opening can hit**:

- **House opening (houses first, or a mix with no tower on night 2):** night 2 now comes from two roads. If it costs you 2 of your 3 Houses, dawn 2 pays only **3 gold**, because a House rebuilt that dawn pays nothing, and that is below the **4-gold** first tower. Night 3 then brings **21 grunts from two roads with no tower to help**, heavier than the 11 grunts of the round-1 night 3 you could not beat. That is how the balanced bot loses seeds 3 and 9. If night 2 costs only 1 House (or none), the tower stands and the same night 3 is won at full castle health.
- **Tower opening:** stays safe and is now **the strictly safer start**: the tower-first bot wins every run with the castle at full health until night 8.
- **Steepness:** the win rate is steep in the counts: one grunt more or less per road on night 3 moves it 10 to 20 points, so only your replay can say whether this is "a little harder" for a human.
- **If it feels too hard or too abrupt:** two measured alternatives exist, neither applied. `k7pS4m` (night 2 east 7; night 3 W10 E9; night 4 W10 E6; night 5 W8) gives balanced 7 of 10 and 76% of 50, a gentler night 3 but closer wins (night 3 ends on 2 to 34 castle hp); `k4pS6m` (night 3 W12 E11 and more) gives 7 of 10 and 66% of 50 and is harsher (greedy dies on night 3 every time).

### Assumptions (round 3; these replace 12 to 14 of round 2, 15 stands)

12. The bots build without riding to plots and sprint at 12 m/s, and the castle shoots for them too. You confirmed this as the measurement rule in round 2, and the target is now **the balanced bot wins 7 or 8 of 10 seeds** (greedy economy at most 2 of 10 with its losses on nights 3 to 6; night 3 and the castle health change only through the night counts you chose). Measured: balanced 8 of 10 (seeds 3 and 9 lost on night 3), 36 of 50; greedy 0 of 10 (median loss night 3); no_build loses night 2; tower-first 10 of 10.
13. **The castle attacks for 2 damage every 1.5 s at 22 m with 27 m/s arrows.** The difficulty was raised with the night counts only (the full wall you chose). Castle damage 2 and health 70, every building cost, the House incomes, the base income of 1 per dawn, the starting gold of 4 and the grunt's 6 hp are unchanged. Combat numbers are as in round 1 (king 50 hp, 5 damage per 0.7 s; Houses 12 / 18 / 24 hp; tower I 50 hp, 3 damage per 0.8 s, range 9; tower II 70 hp, 6 damage per 0.7 s, range 10.5).
14. **Fast-forward is a toggle**, night only, at 2x: press F or the left trigger once to switch it on, press again to switch it off, and it switches itself off when the night ends (dawn, victory or defeat), so every night starts at real time. It is off by day, at dawn, during the defeat beat and on the results screen, and a key held from day into the night does not switch it on. It also works while the king is knocked out. It stays on if the game window loses focus (the old hold stopped when you alt-tabbed); press again to switch it off. Both bindings can be rebound in the Input Map.
15. The base income is shown as a gold coin flying from the castle to the gold counter at dawn, not as a text line, and it is paid on every dawn including the first. (Unchanged from round 2.)

### Your decision (round 3)

Play one or two full runs on the new build, then tell Claude in the `/gsd-verify-work` session:

- **Sign off:** the castle's 22 m reach and 27 m/s arrows feel right, the fast-forward toggle works the way you want on keyboard and gamepad, and the game is "a little harder" in a way you accept, knowing night 3 is a wall for a House opening that lost two Houses on night 2. Phase 2 closes and Phase 3 can begin.
- **Fixes first:** name what is still needed (for example: the castle reach or arrow speed still off, the toggle still wrong somewhere, night 3 too abrupt or still too easy, one of the alternatives `k7pS4m` or `k4pS6m` preferred), and any of assumptions 12 to 15 you want changed.

The decision is recorded through `/gsd-verify-work`. No meta-progression work starts before it.

---

Round 2 and Round 1 below are kept as they were; where they disagree with Round 3 (castle numbers, the fast-forward control, the night counts, the balance tables, assumptions 12 to 14, the export date), Round 3 wins.

## Round 2 (after your playtest of 2026-10-06)

You played round 1 and named four points plus the results-screen spacing (`02-UAT.md`, G-02-1 and G-02-2). All five are fixed on the new build. The bots' numbers and Claude's screenshot review below are evidence only; **they are not your sign-off**. You decide again (D-18, ROADMAP success criterion 4).

### How to play round 2

- **Exported build:** `build/windows/Duskhold.exe`, freshly exported on 2026-10-06 after all five fixes (it launched and quit cleanly in a headless check, exit 0 in 1.7 s). The round-1 export of 2026-10-05 is gone; this one replaces it.
- **From the editor binary, in PowerShell:** the same command as in round 1 below.

### What changed for each of your points

| Your point (round 1) | What changed | Plan |
|---|---|---|
| (1) "some base gold gain at each wave; I made a tower the first wave and then had 0 gold" | Every dawn now pays **1 base gold from the castle** (a coin flies from the castle to the gold counter). Houses still pay their own income; towers still pay nothing. A tower-first opening now earns gold every run (bots: 7.0 gold on average, was 0.0) and wins 10 of 10 (was 0 of 10) | 02-12 |
| (2) "castle should have a simple attack, not too strong; three shots to kill a grunt, two for the ranged units" | The castle shoots the nearest enemy within **11 m** for **2 damage every 1.5 s** with a gold arrow from the keep: **3 shots per grunt, 2 per skirmisher**; a skirmisher is reached at its 10.5 m stand-off. It is counted in a new Kills castle column of the balance report. Honest limit: a well-played defence never lets an enemy within 11 m of the castle, so for the balanced bot the castle kills nothing; it helps weak, idle or knocked-out play (the idle bot's castle kills 3.8 of the 5 night-1 grunts and it still loses) | 02-15 |
| (3) "the speed up should be at least 1.5x faster" | The sprint is **12 m/s instead of 8** (1.5x, with higher acceleration so the king still stops on a plot). New **fast-forward**: hold **F** or the **left trigger** at night to run the game at **2x**. **Night only**: day, dawn, the defeat beat and the results screen run at real time. That is a decision made for you (see assumption 14); say if you want it by day too | 02-13 |
| (4) "i cant currently win lol make it just a bit easier" | Measured after the three fixes above, on seeds 1 to 10: the balanced bot wins 10 of 10 and **loses no run, so under your rule no wave or castle number was touched** (night 3 east stays 5 grunts, castle health stays 70, grunt health stays 6). The base gold alone does the easing for the bots: balanced earns 28 gold a run (was 18), loses no building and is never knocked out; the tower-first opening that never won now always wins. A human plays worse than a bot, so whether this is "a bit easier" or already too easy is your call | this plan |
| Results-screen spacing (G-02-2) | The results buttons sit **11 px lower** (an 11 px margin above the button row), so the gap from the last stat row to the buttons equals the gap between stat rows | 02-14 |

### Controls (round 2)

| Action | Keyboard | Gamepad |
|---|---|---|
| Ride | WASD or arrow keys | left stick |
| Sprint (now 12 m/s, was 8) | Shift | right shoulder |
| Fast-forward (hold, **night only**, 2x) | F | left trigger |
| Build or upgrade (ride to a plot, hold) | E or Space | A |
| Start the night (hold, by day) | N | Y |
| Debug overlay (shows the run seed, wave state, enemy path lines) | F3 | Back |
| Camera zoom | = and - (also keypad) | right stick up and down |

### What Claude checked in round 2

**Automated checks** (after plan 02-16 task 1, commit `07414dd`; no game data changed in this plan):

- Test suite: 817 tests in 94 scripts, all passing; lint and format clean (`bash tools/test.sh`, `bash tools/lint.sh`). New `tests/integration/test_balance_acceptance.gd` pins the seeded shape (seeds 1 to 3: balanced wins all, greedy_economy loses on nights 3 to 6, no_build survives at most 2 nights, towers_first earns gold and wins at least 2, grunt stays 6 hp); with the base income and the castle attack removed it fails on the two tower-first checks.
- Seeded replays: smoke `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden unchanged); `full_idle` run twice `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=4007 digest=27fa2a8071969a4c9350e751cda7bb775984bcf7f3db48fad341567f8944a435` (was 6244 ticks in round 1: the base income lets the bot win sooner).
- Windows build: `bash tools/export.sh` exported `build/windows/Duskhold.exe` and `build/windows/Duskhold.exe --headless --quit-after 120` exits 0 in 1.7 s. CI has not been run on this branch state (nothing was pushed).

**Balance round 2, from scripted bots** (`02-BALANCE-REPORT.md`, seeds 1 to 10, shipped data; reproduce with `bash tools/playtest.sh`; round 1 is kept beside it in the report). The bots build instantly without riding, react perfectly and start every night at once, so this measures the data, not a player.

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 0.3 / 0 / 1 | 1 | 0.3 | 0.0 | 0.0 |
| greedy_economy | 0% | 4.0 / 4 / 4 | 5 | 15.0 | 6.0 | 1.7 |
| houses_first | 100% | 8.0 / 8 / 8 | - | 31.0 | 0.9 | 0.0 |
| towers_first | 100% | 8.0 / 8 / 8 | - | 7.0 | 1.9 | 1.9 |
| balanced | 100% | 8.0 / 8 / 8 | - | 28.0 | 0.0 | 0.0 |

Reading: a balanced build and a tower-first build both win every run now; pure House greed still loses (night 5, castle at 0 hp); doing nothing still loses on night 1 or 2. In round 1 the winning rows lost about 5 buildings and the king was knocked out 1.4 times a run; in round 2 balanced loses none and is never knocked out, so the bots' nights are calmer than your round-1 nights were.

**Screenshot review** (Claude opened these five of the 15 scripted shots on the new data, real window, Forward+; all 15 were saved and the shot-list guard passes):

| Shot | What it shows | Result |
|---|---|---|
| `results_victory` | "Victory", four stat rows, then Play again (outlined) and Quit; the gap from the last row to the buttons looks the same as the gaps between rows | Pass; spacing is for you to confirm |
| `results_defeat` | "Defeat", Nights survived 0 of 8, the same even spacing, collapsed castle behind the panel | Pass |
| `night_combat` | Night 5 of 8, 16 enemies left: red grunts and violet skirmishers by the west tower, an arrow in flight, the king by the castle | Pass; no gold castle arrow in frame, as expected (nothing comes within 11 m of the castle under the shot's bot) |
| `building_destroyed` | Night 3, 4 enemies left: a fallen House as dark slabs on its pale disc, grunts with health bars, the king's bar, a "+14 gold" line | Pass |
| `dawn_payout` | Dawn, Gold 23: four gold coins mid-flight around the castle and the House plots | Pass; a still frame cannot show which coin is the castle's base coin, so judge that in play |

**What nobody has checked:** whether it is fun, whether 1 base gold per dawn fixes the tower-first trap without making gold meaningless, whether the castle attack reads well in a real fight (it rarely fires for a good defence), whether 12 m/s and 2x feel fast enough in your hands, and whether the run is now "a bit easier" rather than too easy.

### Assumptions (round 2; these replace 12 and 13 below and add 14 and 15)

12. The bots build without riding to plots and now sprint at 12 m/s, and the castle shoots for them too; the balance targets are the same (balanced wins at least 8 of 10 seeds, greedy economy at most 2 with its losses on nights 3 to 6), plus your rule that night 3 and the castle health change only if the balanced bot loses a run. Measured: balanced 10 of 10, greedy 0 of 10 (median loss night 5), no_build loses by night 2, tower-first 10 of 10.
13. Costs, House incomes and the starting gold of 4 are unchanged from Phase 1; a **base income of 1 gold per dawn** and the **castle attack** were added at your request, and no night-3 or castle-health change was made (balanced lost no run). Combat numbers are as in round 1 (king 50 hp, 5 damage per 0.7 s; castle 70 hp; Houses 12 / 18 / 24 hp; tower I 50 hp, 3 damage per 0.8 s, range 9; tower II 70 hp, 6 damage per 0.7 s, range 10.5; grunt 6 hp, never 5 because the king would one-shot it).
14. Fast-forward acts only at night, at 2x, with F or the left trigger held. It is off by day (no timer to wait for; the sprint is for riding), at dawn (two seconds of payout coins), during the defeat beat and on the results screen. It drops to real time the moment the night ends, and a key held across dawn resumes it when the next night starts. It also works while the king is knocked out. Both bindings can be rebound in the Input Map.
15. The base income is shown as a gold coin flying from the castle to the gold counter at dawn, not as a text line, and it is paid on every dawn including the first.

### Your decision (round 2)

Play one or two full runs on the new build, then tell Claude in the `/gsd-verify-work` session:

- **Sign off:** the base gold fixes the tower-first trap without making gold meaningless, the castle attack is simple and not too strong, the 12 m/s sprint and the night fast-forward are fast enough, the game is a bit easier but still tense, and the results spacing looks even. Phase 2 closes and Phase 3 can begin.
- **Fixes first:** name what is still needed (for example: base gold too much or too little, fast-forward by day too or faster than 2x, castle attack too strong or too weak, night 3 or the whole run still too hard or now too easy, spacing still off), and any of assumptions 12 to 15 you want changed.

The decision is recorded through `/gsd-verify-work`. No meta-progression work starts before it.

---

Round 1 below is the original packet, kept as it was. Where it disagrees with Round 2 above (the controls table, assumptions 12 and 13, the balance table, the export date), Round 2 wins.

## How to play

- **Exported build:** `build/windows/Duskhold.exe` (exported from the final phase state on 2026-10-05; it launched and quit cleanly in a headless check).
- **From the editor binary, in PowerShell** (PowerShell's `bash` is WSL, so the Git Bash wrappers are not your entry point):

  ```powershell
  & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path .
  ```

- **Controls** (keyboard or gamepad):

  | Action | Keyboard | Gamepad |
  |---|---|---|
  | Ride | WASD or arrow keys | left stick |
  | Sprint | Shift | right shoulder |
  | Build or upgrade (ride to a plot, hold) | E or Space | A |
  | Start the night (hold, by day) | N | Y |
  | Debug overlay (shows the run seed, wave state, enemy path lines) | F3 | Back |
  | Camera zoom | = and - (also keypad) | right stick up and down |

- **A run:** 8 nights on the one prototype map. By day, ride to plots and hold the action key to spend gold; start the night yourself when ready (the spawn markers and the "Night N: X enemies from Y directions" line tell you what is coming). By night the king fights alongside the towers; at dawn what fell is rebuilt, what stands is repaired and the Houses pay. Win by clearing night 8; lose when the castle falls. The results screen offers Play again and Quit.

## What to judge

Play one or two full runs. Judge three things only:

1. **Do gold choices by day feel like real trade-offs?** You start with 4 gold; a House costs 2 and pays 1 each dawn, a Tower costs 4 and pays nothing.
2. **Do nights feel tense?** Night 3 is the first danger (the king alone against two roads before a tower is affordable); from night 4 the towers carry the fight.
3. **Can you read what is happening at night?** Spawn markers by day, enemies (red grunts, taller violet skirmishers), health bars, arrows, rubble, the knocked-out countdown, the results text.

Then either sign off or list the tuning and feel fixes that must land before Phase 3. Also say if any of the 13 assumptions below should change.

## What Claude already checked

**Automated checks, on the code as pushed in `dd5428c`:**

- Test suite: 719 tests in 85 scripts, all passing; lint and format clean (`bash tools/test.sh`, `bash tools/lint.sh`).
- Seeded replays: `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` prints REPLAY_OK (won, 703 ticks, digest `2599c7c2...`); `--scenario=full_idle --twice` prints REPLAY_OK (won, 6244 ticks, digest `a25aa7fd...`).
- CI: run https://github.com/ABSAR07/duskhold/actions/runs/37325147907 on `dd5428c` is green on all four jobs (lint, test with the replay checks, export, screenshots). Artifacts: `gut-results`, `duskhold-windows`, `duskhold-screenshots` (15 PNGs).
- Windows build: `bash tools/export.sh` exports `build/windows/Duskhold.exe`; `build/windows/Duskhold.exe --headless --quit-after 120` exits 0 in 7.6 s.

**Balance, from scripted bots** (`02-BALANCE-REPORT.md`, seeds 1 to 10, shipped data; reproduce with `bash tools/playtest.sh`). The bots build instantly without riding, react perfectly and start every night at once, so this measures the data, not a player.

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 0.0 / 0 / 0 | 1 | 0.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 3.5 / 3 / 4 | 4 | 8.5 | 5.0 | 2.1 |
| houses_first | 100% | 8.0 / 8 / 8 | - | 18.0 | 4.6 | 1.4 |
| towers_first | 0% | 5.1 / 5 / 6 | 6 | 0.0 | 0.0 | 1.9 |
| balanced | 100% | 8.0 / 8 / 8 | - | 18.0 | 4.8 | 1.4 |

Reading: a balanced build wins, pure House greed loses around night 4, building only towers starves (no income) and dies on night 6, doing nothing loses on night 1. The whole run pays about 18 gold in dawn income, so after the third House there are few real trade-offs; this is the Phase 1 economy, left alone. Nights 6 and 7 look easy once all three towers stand; night 8 is the long one.

**Screenshot review** (Claude opened every new image, locally with the Forward+ renderer and again from the CI artifact, which is flatter and lighter but the same content; one presentation fix was applied, see the end of this section):

| Shot | What it shows | Result |
|---|---|---|
| `spawn_telegraph` | Day, one Tower standing; a red disc with a "5" over the west road's spawn point; the prompt "Hold N / (Y) to start Night 1" and "Night 1: 5 enemies from 1 direction" | Pass; the disc is small (44 px on a 1280x720 frame) but legible |
| `night_combat` | Night 5 near the west tower: red grunts and taller violet skirmishers stand out from the ground and from each other, with shadows; a violet skirmisher arrow in flight; "Night 5 of 8 - 16 enemies left" | Pass; no enemy health bar in this frame because the bars show only on hurt enemies (they show in `building_destroyed`) |
| `building_destroyed` | Night 3: a fallen House as dark slabs on its pale plot disc, the castle at the top left, grunts with health bars, the king's bar, "+13 gold" | Pass; the rubble is dark against the dark night ground and is carried by the pale disc under it |
| `dawn_rebuilt` | Dawn: two rebuilt Houses standing again, each with a gold coin crossed out in red | Pass; the coin is small (26 px) and sits on the red roof |
| `king_down_countdown` | Night 7: the king as a cyan ghost capsule, "Knocked out - back in 6 s" in cyan under the night line, a violet skirmisher, yellow tower arrows | Pass; the arrows are a cluster of streaks because the shot's fast-forward launched them in one frame (a shot artifact, not game behaviour) |
| `results_victory` | "Victory", Nights survived 1 of 1, Gold earned, Buildings lost, King knockouts, Play again (focused, outlined) and Quit | Pass, with the layout issue below |
| `results_defeat` | "Defeat", Nights survived 0 of 8, the collapsed castle and grunts behind the panel | Pass, with the layout issue below |
| `overlay_paths` | F3 overlay on the right (Perf, Loop, Agents, Wave, King, Paths) with the king, a tower, a grunt and the path lines | Pass, with the line issue below |

**Open readability points (not fixed; they sit outside the files this plan could touch, and each is your call):**

- Results screen: the stat rows sit right on top of the buttons with almost no gap, and the Quit button is barely distinguishable from the panel (low contrast, no border); only Play again, which has focus, shows an outline. The text itself is legible.
- Debug overlay path lines are 1-pixel hairlines (white-grey) and are faint at game camera distance. The overlay panel text is readable.
- The "crossed-out coin" marks at dawn are small (26 px); the spawn markers are 44 px.
- The overlay's FPS row read 18 to 24 in these shots only because each shot's fast-forward makes one very long frame; it is not a frame-rate measurement. Performance with hundreds of units is Phase 4's job.

**Presentation fix applied:** projectile arrows were 7 cm thick and nearly invisible at game camera distance (a skirmisher arrow showed as a 2-pixel sliver); they are now 15 cm by 1 m, using the same colours and emission. Nothing else was changed and no asset was added.

**What nobody has checked:** whether it is fun, how the king handles when steered by hand, how the ride between plots costs you in day time, whether night 3 feels fair to a player who has never seen the waves, and gamepad feel at night.

## Assumptions made for you

1. Damaged buildings and the castle are fully repaired at dawn (survivors, castle and king), and what fell is rebuilt for free; the rebuilt buildings pay no income that dawn.
2. After night 8 the run goes straight to Victory with no last dawn payout (gold earned counts dawn payouts only).
3. A king still knocked out when a night is cleared returns at dawn with full health.
4. The simulation runs at a fixed 30 steps per second (changing it regenerates every golden digest) and the ground is 180 m.
5. Enemies, arrows, rubble and the ghost king are simple shapes, with no new asset packs until Phase 8.
6. The cross-platform replay result from 02-09: Linux produced the same digest as Windows, so there is one shared golden file and no per-platform key.
7. Your own runs are not recorded for replay, but the seed shown in the overlay (F3) identifies a run.
8. Enemies switch to the king whenever he enters their reach, which is how he pulls them off buildings; otherwise they keep their target.
9. Victory shows at once and Defeat after a 1.2 s beat while the castle collapses.
10. The respawn countdown is 6, 10, 14 then 15 s, with the cap in data.
11. The skirmisher (ranged) arrives from night 4.
12. The bots build without riding to plots; the balance targets were: balanced wins at least 8 of 10 seeds, greedy economy at most 2 with its losses on nights 3 to 6 (median loss night 4).
13. Costs, incomes and the starting gold of 4 are unchanged from Phase 1; only combat and wave numbers were tuned (king 50 hp, 5 damage per 0.7 s; castle 70 hp; Houses 12 / 18 / 24 hp; tower I 50 hp, 3 damage per 0.8 s, range 9; tower II 70 hp, 6 damage per 0.7 s, range 10.5). The full before and after list is in `02-BALANCE-REPORT.md`.

## Your decision

Choose one and tell Claude in the `/gsd-verify-work` session:

- **Sign off:** gold trade-offs feel meaningful, nights feel tense and readable. Phase 2 closes and Phase 3 can begin.
- **Fixes first:** list the tuning and feel fixes that must land before Phase 3 (for example: night 3 too harsh or too soft, nights 6 and 7 too calm, the 4-gold opening, results screen layout, line or marker sizes), and any of the 13 assumptions you want changed.

The decision is recorded through `/gsd-verify-work`. No meta-progression work starts before it.
