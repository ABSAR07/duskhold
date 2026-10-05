# Phase 2 Playtest Gate: Night Defense (owner packet)

You are the gate (D-18, ROADMAP success criterion 4). Claude has checked everything it can observe and lists it below. It cannot tell you whether the loop is fun. Spend one or two full runs on that, then sign off or name the fixes. Nothing here counts as your sign-off.

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
