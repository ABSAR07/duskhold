# Phase 2 Playtest Gate: Night Defense (owner packet)

You are the gate (D-18, ROADMAP success criterion 4). Claude has checked everything it can observe and lists it below. It cannot tell you whether the loop is fun. Spend one or two full runs on that, then sign off or name the fixes. Nothing here counts as your sign-off.

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
