# Phase 3 Playtest Gate: King Combat & Troops (owner packet)

You are the gate (D-08 feel half, Phase 2 D-18, ROADMAP success criteria 1 to 5). Claude has checked everything it can observe and lists it below. It cannot tell you whether the army feels good to command, whether the slam and the regeneration suit the game, or whether the HUD stays readable in a real fight on your hardware. Spend two or three full runs on that, on both devices, then sign off or name the fixes. **Nothing here counts as your sign-off**; your decision, recorded through `/gsd-verify-work`, closes the phase.

## How to play

- **Exported build:** `build/windows/Duskhold.exe`, freshly exported on 2026-10-12 (UTC) from commit `c418b6c`, the state the latest CI run checked. It launched and quit cleanly in the headless check `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` (exit 0 in about 3 s). It replaces the Phase 2 export. **That export predates the fixes since UAT round 1 and the Round 2 retune below**, so it does not hold them; to play the current build, run the editor binary below, or re-export first (`bash tools/export.sh` from Git Bash).
- **From the editor binary, in PowerShell** (PowerShell's `bash` is WSL, so the Git Bash wrappers are not your entry point):

  ```powershell
  & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path .
  ```

- **A run:** the same 8 nights on the one prototype map. New this phase: a **Barracks** plot west of the keep and an **Archery Range** plot east of it. You build and upgrade them like any plot (ride up, hold the action key); they cost 4, 8 and 16 gold and field a squad of 4, 8 and 14 footmen or archers. A squad stands 3.5 m in front of its plot and guards it until you command it. At night the dead come back one at a time at the building (every 10, 7 and 4 s by tier); at dawn every squad is whole again. You command **whole squads**, never single units. The king also has a sword **slam** and **regenerates** (1 s after the last hit, 10 % of his health per second).
- **Selecting a squad takes the movement keys away from the king** (your decision at the 03-07 checkpoint): while any squad is selected the WASD keys and the left stick give the king nothing, and with nothing selected he steers as before. Escape cancels a point command that is waiting and, pressed again with nothing armed, clears the selection and gives you the king back.

### Controls, keyboard and mouse (read from the Input Map as shipped)

| Action | Keyboard and mouse |
|---|---|
| Ride (walk 7.5 m/s) | WASD or the arrow keys |
| Sprint (12 m/s) | Shift |
| Build or upgrade (ride to a plot, hold) | Space or E |
| Start the night (hold, by day) | N |
| Slam (the sword's active ability, any time, 9 s cooldown) | Q |
| Fast-forward (night only, 2x, press to switch on and off) | T |
| Select a squad | left click on one of its units, or its slot at the bottom of the screen |
| Select several squads | drag a box on the ground; Ctrl + click adds or removes one |
| Select every squad of one unit type | double-click a unit |
| Cycle the selection to the next squad | Tab |
| Select every squad | F2 |
| Follow the king / hold / rally to the king | F / H / R |
| Move | right click on the ground |
| Attack-move (walk there and fight on the way) | A, then left click on the ground (the key is also the king's move-left, so with nothing selected it does nothing) |
| Patrol | hold P, right click each point, let go of P (up to 7 points) |
| Queue an order behind the current ones | hold Shift while giving it, including F, H and R (sprinting with Shift while pressing one of them now queues it instead of replacing the queue; up to 9 orders per squad) |
| Cancel a waiting point command, then clear the selection | Escape |
| Store the selection as a control group | Ctrl + 1 to 9 or 0 |
| Recall a control group | the digit 1 to 9 or 0 |
| Camera zoom | = and - (also the keypad) |
| Debug overlay | F3 |

### Controls, gamepad

| Action | Gamepad |
|---|---|
| Ride | left stick |
| Sprint | right shoulder (RB) |
| Build or upgrade (hold) | A |
| Start the night (hold) | Y |
| Slam | X |
| Fast-forward (night only) | left trigger (LT) |
| Follow / hold / rally | D-pad up / down / left |
| Cycle to the next squad | D-pad right |
| Select every squad | right stick press (R3) |
| Select every squad of one unit type (the type of the squad cycled last) | LB + R3 |
| Move / attack-move / patrol | hold LB and press D-pad up / right / down: a ring appears on the ground, steer it with the right stick, let go of the D-pad button to confirm (a pad patrol takes one point) |
| Queue an order behind the current ones | hold the right trigger (RT) when you confirm, or when you press a D-pad verb |
| Cancel the cursor, then clear the selection | B |
| Control groups | hold Start; D-pad left and right step the number 1 to 9 and 0 on the selected squad's badge, D-pad up recalls it; let go of Start to store |
| Camera zoom | right stick up and down (suppressed while the cursor is out) |
| Debug overlay | Back |

Every prompt on screen (the start-night line, the slam badge, the hint row above the squad slots) follows the device you touched last; any press or stick move on the other device switches all of them at once, and mouse input counts as keyboard.

## What to judge

Play two or three full runs with an army, on keyboard and mouse and on a gamepad, and switch device mid-run at least once. Judge:

1. **Do squads guard and commit instead of thrashing?** Do footmen hold the ground in front of a plot, pick a target and stay on it, and walk back to their post afterwards? Do archers stay behind and shoot? Is the guard-or-follow behaviour readable at night, with units small and plain-coloured?
2. **Does the formation look right?** Four, eight and fourteen units around a post, while following the king, after a move, and on patrol.
3. **Do selection and commands feel right?** Mouse: clicking a squad, the drag box, right-click moves, the attack-move key, patrol and Shift queueing, control groups. Gamepad: the right-stick ground cursor (it moves at 900 px/s across the screen at full stick), the LB layer, the Start group mode, the D-pad verbs. Does the king stopping while a squad is selected help or annoy?
4. **Do the slam and the regeneration suit the game?** The slam hits everything within 4 m for 4 damage with a 9 s cooldown and no knockback; regeneration starts 1 s after the last hit at 10 % of 50 health per second, by day and by night.
5. **Does the HUD read at night and keep the centre clear?** Gold top-left, the day counter top-centre, the king's health and slam badge bottom-left, the squad slots and the hint row bottom-centre. Can you read the slots, the glyphs (24 px tiles on the hint row) and the toasts in the middle of a fight?
6. **Do the retuned nights feel tense with squads?** Nights 1 to 4 are unchanged (5, 12, 21, 21 enemies); nights 5 to 8 are now 25, 31, 39 and **40**, so the last night is at last one enemy larger than the night before (Round 2 raised night 8's north road from 10 to 11 grunts). The first tower tier also fires every **0.9 s instead of 0.8 s**. Is the army worth its gold against a tower now (the bots measure 0.92 of a tower's kills per gold, against 0.68 before), and does the slower first tower still feel like a rewarding opening (the pure tower route no longer wins under the bots)?

## Fixed since UAT round 1

Your first UAT pass found these gaps; each is fixed and covered by tests, and you should find them gone in play. One line each:

- **G-03-8 (plan 03-13):** the follow, hold and rally keys now queue behind the squad's walks when Shift is held (right trigger on the pad), in line with D-09; sprinting with Shift while pressing F, H or R used to replace the queue and now appends to it, and a plain press still clears the queue and acts at once.
- **G-03-4 (plan 03-14):** the floating health bar over the king now follows every regeneration point, climbing with the bottom-left widget and hiding again at full health (it used to stay frozen at its last hit).
- **G-03-14b (plan 03-15):** the start-night prompt and its fill bar sit on a dark plate between the squad slots and the bottom of the screen, so the bottom-centre hierarchy reads and the prompt is the focal point by day.
- **G-03-13 (plan 03-19):** a knocked-out king's "0 / 50" and the "Slam" caption stay fully opaque on their dark outline (measured at 5.88:1 contrast, was 1.62:1) while the bar, plate, sword and slam glyph dim.
- **G-03-14 (plan 03-19):** one enemy now reads "1 enemy" on the night banner and the day preview; "N enemies" everywhere else. The "1 enemies" copy is no longer an open point.
- **G-03-11 (plans 03-16, 03-17 and 03-18):** the balance retune you asked for on 2026-10-13: squad value is now measured (03-16), two numbers moved so all four goals are met under the bots (03-17: the first tower tier fires every 0.9 s, night 8's north road holds 11 grunts), and the results are published in `03-BALANCE-REPORT.md` (03-18). Your feel check is still to come at this gate.

## What Claude already checked

**Automated checks** (the first block is the state at commit `c418b6c`, the end of plan 03-12; the fixes since UAT round 1 and the Round 2 retune landed after it, so its CI run, export and replay lines below describe that commit, and the "Since then" lines say what has been re-checked on the current data):

- **Since then (current data, plans 03-13 to 03-19):** the full suite is **1397 tests in 150 scripts, all passing**, exit 0 in 621.8 s (`bash tools/test.sh`, plan 03-17's run); lint and format clean on 265 files; the smoke and army goldens replay unchanged (digests below); `full_idle` moved by design to `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` (6941 ticks, was `ab4d17d9...` at 6199) and replays to one digest twice in one process; `bash tools/playtest.sh --seeds=10` prints `PLAYTEST_OK runs=60`; all 33 real-window screenshots were re-captured on the retuned data (details in the screenshot review below).
- **Test suite at `c418b6c`:** 1373 tests in 148 scripts, all passing, 15364 asserts, exit 0 in 630 s (`bash tools/test.sh`); lint and format clean (`bash tools/lint.sh`).
- **Seeded replays:** smoke `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden unchanged); army `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (golden unchanged); both twice in one process, locally and in CI. CI also ran `full_idle` (shipped data, balanced bot): `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6199 digest=ab4d17d91e197347f66e24008fffbc3f7061b0b1ab27de312423212797650b7a` (it has no golden and moved with the night retune by design).
- **CI:** https://github.com/ABSAR07/duskhold/actions/runs/38219154906 on `c418b6c` succeeded on all four jobs: lint 25 s, test 6 min 31 s (with the smoke, army and full_idle replay checks), export 33 s, screenshots 2 min 25 s with **33 of 33 screenshots saved** (artifact `duskhold-screenshots`, kept 7 days). The first CI run of this plan (`38215930089`, on `549e53c`) failed its screenshots job on two of the new shots, `cmd_queue_ten` and `cmd_move_ping`, because a frame on the software renderer is long enough for a squad's first leg to end during ten clicks and for the half-second ping to expire; the scenes were made independent of frame time (`85990e9`, run `38217462543` green), and a third change made the slam ring show in the CI frame too (`c418b6c`). The screenshots job needed 2 to 3 minutes, so its 60-minute timeout is generous; it stays as the plan said.
- **Windows build:** `bash tools/export.sh` exported `build/windows/Duskhold.exe`; the launch check above exits 0 in about 3 s.

**Balance, Round 2, from scripted bots** (`03-BALANCE-REPORT.md` section "Round 2 (G-03-11)", plans 03-16, 03-17 and 03-18, seeds 1 to 10, shipped data; reproduce with `bash tools/playtest.sh --seeds=10`, which prints `PLAYTEST_OK runs=60`). The bots build instantly without riding, react perfectly and start every night at once, so this measures the data, not a player and not the feel of squads. You asked on 2026-10-13 for a retune toward all four goals at once; two numbers moved to reach them: **tower tier 1 now fires every 0.9 s (was 0.8 s)** and **night 8's north road holds 11 grunts (was 10)**. Squad sizes, replacement times, the footman, the king, nights 1 to 4 and every enemy are as before.

| Your goal | Bar | Before | Now |
|---|---|---|---|
| The balanced bot loses 2 to 3 of 10 | 7 or 8 wins | 9 wins | **8 wins** (seeds 3 and 9 lost) |
| The army bot loses 2 to 3 of 10 | 7 or 8 wins | 8 wins | **8 wins** (seeds 1 and 9 lost) |
| Night 8 is larger than night 7 | strictly above | 39 and 39 | **40 and 39** |
| Squads are worth their gold against towers | kills per gold, squads over towers, at least 0.8 (your bar, D-26) | 0.68 | **0.92** (4.31 enemy kills per squad gold, 4.70 per tower gold) |

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.9 / 2 / 4 | 4 | 9.2 | 5.0 | 1.8 |
| houses_first | 40% | 6.7 / 2 / 8 | 7 | 21.1 | 14.7 | 1.1 |
| towers_first | 0% | 6.1 / 6 / 7 | 7 | 6.1 | 5.9 | 2.6 |
| balanced | 80% | 7.3 / 2 / 8 | 3 | 22.2 | 10.4 | 0.6 |
| army_balanced | 80% | 7.5 / 5 / 8 | 6 | 15.0 | 17.6 | 1.3 |

Two findings the report leaves for you, plainly:

- **The pure tower opening no longer wins under the bots.** To lower the balanced bot to 8 wins and lift the squads' worth, the first tower had to get slower, and every route that leans on first-tier towers paid: towers_first went from 3 wins of 10 to **0** (it falls on night 7 on nine seeds, night 8 on one) and houses_first from 9 to **4**. The search tried 29 candidates (squad speed and cost, tier 2, tier 1 cost, range, health, arrow speed, king regeneration, night counts) and none that met your four goals kept the tower route winning. Whether a 0.9 s first tower still feels like a good opening is yours to judge; keeping its wins would cost one of the four goals.
- **The ratio understates a squad that holds a line.** Footmen that stand in front of a tower get no kill credit for the kills they make possible, and only the army bot buys squads, so 0.92 compares its squads with its own small tower spend (about 4 gold a run). The army bot also loses a lot of buildings (17.6 a run; the balanced bot 10.4); it has no notion of defending its plots, and a player who fights beside the squad or posts the footmen where they shield a tower may do better or worse.

The earlier Phase 3 numbers (plan 03-11, before Round 2), kept for reference and **superseded by the tables above**:

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.9 / 2 / 4 | 4 | 9.2 | 5.0 | 1.8 |
| houses_first | 90% | 7.4 / 2 / 8 | 3 | 25.1 | 9.2 | 0.5 |
| towers_first | 30% | 7.2 / 6 / 8 | 8 | 6.9 | 6.0 | 3.8 |
| balanced | 90% | 7.4 / 2 / 8 | 3 | 24.0 | 5.8 | 0.5 |
| army_balanced | 80% | 7.5 / 5 / 8 | 6 | 15.3 | 16.4 | 1.1 |

Its two findings were that squads were not stronger than towers per gold (ratio 0.68) and that the balanced bot lost 1 of 10 with night 8 equal to night 7 (39 each); Round 2 answers both.

**Screenshot review** (Claude opened every new image: all 18 locally in a real window with the Forward+ renderer, and again from the CI artifact, which is flatter and paler because it is the Compatibility renderer under Mesa; the content is the same). Every `hud_` and `cmd_` shot also passes the runner's clear-centre check (no visible HUD control other than the banner, the knocked-out label, the drag box while dragging and world-anchored markers inside x 384..896, y 96..500 of the 1280x720 base space), or it would have failed:

**Re-check on the Round 2 data (plan 03-18):** the night shots fast-forward the shipped data with the bots, so all 33 shots were captured again after the retune with `bash tools/screenshot.sh` (real window, Forward+): `Saved 33 of 33 screenshots`, every blank check and every clear-centre check passed, exit 0. Claude opened `hud_night_squad_down.png` and `night_combat.png` again: the first still shows Night 7 of 8 with 9 enemies left, the Barracks slot a red 0 / 4 and the Range 3 / 4, the king hurt at 36 / 50 with his cyan silhouette behind the keep; the second still shows a night fight (Night 5 of 8, 23 enemies left, the king beside a tower with red and purple enemies and pink shots closing in on his left). The rows below describe the original captures; the two changes since (the start-night plate and the knocked-out count) are noted in their rows.

| Shot | What it shows | Result |
|---|---|---|
| `hud_day_squads` | Day 1, Barracks and Range raised, the Barracks squad selected: both slots 4 / 4 with the selected one outlined, the hint row (7 items, 318 to 964 px wide) above them, rings under the four footmen, the king widget bottom-left, the start-night prompt on its dark plate below the slots (plan 03-15, G-03-14b) | Pass; widgets stand apart, centre empty |
| `hud_night_squad_down` | Night 7 of 8, 9 enemies left: the Barracks slot reads a red 0 / 4 with its fill showing a replacement on the way, the Range 3 / 4, the king at 36 / 50, his cyan X-ray silhouette behind the keep, health bars over enemies and the keep | Pass; all text reads on the dark ground |
| `hud_drag_box` | A drag box (fill 16 %, border 2 px, cyan) from the top-left to the middle right across the keep, the slots unselected and no hint row | Pass; the box is the one thing allowed in the centre |
| `hud_pad_cursor` | Pad as last device: the start-night glyph is a Y tile, the slam badge shows an X tile, the cursor ring and its line run from the king toward the east, the hint row is replaced by "Aim with the right stick, release to confirm" at y 504 | Pass |
| `hud_king_down` | Night 7, knocked out: the bar, plate, sword and slam glyph dimmed to alpha 0.4 while the red "0 / 50" and the "Slam" caption stay opaque on their outline (plan 03-19, G-03-13), "Knocked out - back in 6 s" in cyan under the banner, the squad slots unchanged | Pass |
| `hud_ability_ready` | Day, the slam used and recharged: the badge plate and its caption are tinted cyan on the ready flash, the border is cyan | Pass; the 0.25 s flash is a still frame here, judge it in play |
| `hud_long_toast` | A squad selected, the king at the edge of the ground, a right click off the map: "Can't go there. Click a point on the visible ground." on one line at y 504..536 above the slots, the dark void right of the ground edge | Pass for one line and below the centre; **measured 526 px wide, x 377..903**, see the backstop table |
| `hud_day_squads_1080p` | The same scene in a 1920x1080 window (1920x1050 on this laptop, whose title bar leaves no room for 1080 rows; exactly 1920x1080 on CI): the HUD scales uniformly, nothing overlaps | Pass |
| `hud_night_squad_down_16x10` | The night-7 scene at 1600x1000 (16:10) with the surviving Range squad selected: the hint row (398 to 1205 px) clears the king widget and the slots, the banner stays centred | Pass |
| `hud_day_counter_long` | A map of twelve one-grunt nights run to the eve of the last: "Night 12 of 12" on one centred line at the top, "Hold N to start Night 12" below | Pass |
| `hud_king_120` | A king of 120 health at 90 / 120 on night 7: the bar and the label keep their places, the label simply grows to the right | Pass |
| `hud_keycap_backspace` | Follow rebound to Backspace: the first hint item is a keycap plate reading "Backspace", wider than the other tiles, not clipped, the row still centred | Pass |
| `cmd_queue_ten` | Ten Shift-queued moves on the Barracks squad: nine orders kept (checked by the scene), six numbered discs drawn, 1 to 6, joined by a line | Pass after one fix (see below) |
| `hud_rubble_squad` | Night 5, the Barracks destroyed: its slot keeps its place, selected, a dimmed icon and a red 0 / 4, a dark rubble pile on its plot, the Range 4 / 4 | Pass; the scene also checks that the fill is stopped (0.223 and 0.223, half a second apart) |
| `cmd_box_select` | After a real drag over both squads: both slots outlined, rings under all eight units, the hint row shown, the box gone | Pass |
| `cmd_move_ping` | A right click with the Barracks squad selected: a small cyan ping ring on the ground near the click, the footmen starting to walk | Pass; the ping is small (0.3 m growing to 0.8 m) |
| `cmd_patrol` | A two-point patrol: a dashed beige line from the squad to a gold end disc, the slot's stance glyph now the double arrow | Pass; thin, see the open points |
| `cmd_slam` | Night 2, the king amid his footmen and a grunt: the white slam ring about 2.5 m out and fading, tower arrows, the strip with a follow glyph on the Barracks slot | Pass |

**Backstop rows** (the seven UI-SPEC rows lifted into plan 03-12), one by one:

| Row | Shot | Result |
|---|---|---|
| E1 long-text: "Night 12 of 12" stays on one centred line | `hud_day_counter_long` | Confirmed |
| E2 long-text: a 120 health king, the label grows right without reflowing the row | `hud_king_120` | Confirmed (the bar starts at the same x as at 50 / 50; the label starts at x 280 and the row does not move) |
| E3 partial: a squad whose Barracks is rubble keeps its slot with "0 / N" dimmed and the fill stopped | `hud_rubble_squad` | Confirmed (image and the stopped-fill check) |
| E5 overflow: all 7 hint items fit without touching the king widget or the slots | `hud_day_squads` (1280x720) and `hud_night_squad_down_16x10` | Confirmed; the row measures about 646 px, not the 610 the spec estimated, and still clears both |
| E6 long-text: the longest toast on one line inside x 384..896 | `hud_long_toast` | **human_needed**: one line, entirely below y 500 so it never enters the clear centre, but it is **526 px wide and spans x 377..903**, 7 px past the literal x band on each side (plan 03-06 had already measured 526 px against the spec's 460 estimate). Your call whether that is fine |
| E7 long-text: a long key name widens the keycap without clipping | `hud_keycap_backspace` | Confirmed |
| E9 overflow: the queue is capped at 9 orders and disc numbers stay one digit | `cmd_queue_ten` | Confirmed (nine kept, six discs, digits 1 to 6) |

**RESEARCH A9** (the stretch-mode coordinate agreement also holds in a real window): confirmed by a one-off probe that is not part of the repository. In a real window at 1280x720, 1920x1050 and 1600x1000, a left click at the window position of an archer puppet's projected point selected the archery squad each time (the canvas-to-window transform scales by 1, 1.459 and 1.25).

**Readability fixes made:** the numbers on queued-order discs were drawn about 9 px high on a 1280x720 frame and hard to read on the cyan disc; the label is now 1.6x larger (pixel size 0.02 to 0.032) and sits 0.3 m higher (0.15 to 0.45 m) (`presentation/units/squad_plan_view.gd`, presentation only). Nothing else was changed.

**Open readability points (not changed; each is your call):**

- **The longest toast is 526 px wide**, 7 px past the x 384..896 band on each side (above), because the Godot default font measures wider than the spec's estimate.
- **A "+2 gold" payout line stays under the gold counter** through the day after a dawn and through the following night (seen in four new shots). It is the Phase 1 dawn-payout label; nothing in this phase changed it.
- **The patrol line** is a 12 cm dashed beige line at 80 % alpha, thin on the green ground at the game camera distance; legible, but faint.
- **The king widget's slam badge** and the hint-row glyphs are small by design (56 px and 24 px); Claude could read them in every shot, but 24 px tiles are an eyesight question.

**What nobody has checked:** how any of it feels in your hands. In particular: every gamepad event Claude sent was synthetic (never a physical pad), so button feel, the trigger edges and the 900 px/s cursor speed are untested on hardware; the pointer shots run at 1280x720 only (the probe above is the only larger-window click); the squads' look in motion (puppets are static bind-pose models, animation is Phase 8, and the two military buildings are kit-piece placeholders); whether guard and commit read as "intelligent" or as thrashing; and whether the Xbox tiles are fine on a non-Xbox pad (deferred to Phase 13).

## Assumptions made for you

1. **Unit numbers (A1):** Footman 10 health, 1 damage every 0.6 s, speed 4.0, reach 1.2 m, guard 7 m, leash 12 m; Archer 6 health, 1 damage every 0.9 s, speed 3.8, range 8.5 m, arrows at 16 m/s, guard 10 m, leash 14 m. A single unit is about a fifth of the king; integer damage makes 1 the only value near a fifth of 5, so strength is tuned through interval, health and squad size. Costs 4 / 8 / 16 gold, squads of 4 / 8 / 14, replacements every 10 / 7 / 4 s.
2. **Plot positions (A2):** Barracks at (-16, 0, -2) west of the keep, Archery Range at (16, 0, -2) east; inside the tower ring and apart from every other plot. Squads wait 3.5 m in front of their plot.
3. **New seats fill at once by day; only night losses trickle (A4):** a build or an upgrade by day fills every new seat immediately, and the 10 / 7 / 4 s replacement timer runs only at night.
4. **Units ignore enemies during a move or a rally, and an order queued after hold, follow or patrol is refused (A5):** a move is a walk that ignores the fight; hold, follow and patrol act at once, so nothing can queue behind them. Attack-move fights on the way, and a fight does not end an attack-move or a patrol leg.
5. **Slam 4 m, 4 damage, 9 s cooldown, no knockback (A6);** it hits by centre distance and can be used by day (it hits nothing).
6. **The dawn still heals the king fully (A7)** next to regeneration, which only replaced "no regeneration during a night". Regeneration: 1 s after the last hit, 10 % of maximum health per second, both numbers in data.
7. **A 90 m map extent for command points (A8):** a point beyond 90 m from the centre, or on no ground under the cursor, gives no order and the "Can't go there" toast; points are quantised to whole centimetres.
8. **The pad layout (A11):** the D-pad carries the verbs, LB is the layer for move, attack-move and patrol with the right-stick cursor, R3 and LB + R3 select all and one type, Start is the group mode, RT queues, B cancels. A pad patrol takes one point (multi-point patrol is a mouse gesture). The cursor starts on the king and moves at 900 px/s at full stick. This was chosen by Claude, not by you; D-12 only fixed "verbs on the D-pad".
9. **Control groups hold squad ids and never drop a member at 0 alive; a newly built squad joins no group; recalling an empty group keeps the selection and shows "Group N is empty" (A12).** There is no auto-join; say if you want one.
10. **Military building health 40 / 60 / 80 by tier (A14),** against the towers' 50 / 70 and the castle's 70. A fallen Barracks or Range leaves rubble and its squad cannot be replaced until dawn restores it.
11. **The planner's key choices, all in the Input Map and rebindable in Phase 13:** Q for the slam (pad X), T for fast-forward (it moved off F), F2 for select all (pad R3), double-click for "every squad of this type" (pad LB + R3), Tab to cycle. **Attack-move stays on A**, your choice at the 03-07 checkpoint, shared with the king's move-left. **Shift is both sprint and queue:** a queue only counts when Shift is held at the moment the order lands.
12. **Selecting a squad stops the king (your 03-07 rule):** WASD and the left stick go to nobody while a squad is selected; Escape (pad B) with nothing armed clears the selection; clicking empty ground also clears it. Device switches keep the selection and the groups.
13. **A squad's stance persists across dawn (D-14):** a held, following or patrolling squad stays so day after day until you change it; dawn restores numbers only.
14. **The bots' army plan and the Round 2 numbers:** the army bot's footmen follow the king and its archers hold, and it slams at three enemies in reach, with no riding and perfect reactions. The night totals are 5, 12, 21, 21, 25, 31, 39, 40 (only nights 5 to 8 ever moved: Round 1 set 25, 31, 39, 39; Round 2 added one grunt to night 8's north road), and Round 2 moved exactly two numbers: tower tier 1 attack interval 0.8 s to 0.9 s and that one grunt. No economy, squad, unit, king or enemy number changed. The squad-value bar is your 0.8 (D-26), measured as unit kills per military gold over tower kills per tower gold for the army bot; it reads 0.915. The pure tower opening and the houses-first opening no longer win under the bots (0 and 4 of 10); that is a result of the slower first tower, not an accident.
15. **The mouse is back for squads only (D-11):** building stays hold-only, the mouse never aims the king and never moves the camera, and the camera stays locked on the king, so a point off screen needs him to ride closer (D-13).

## Your decision

Choose one and tell Claude in the `/gsd-verify-work` session:

- **Sign off:** squads guard and commit instead of thrashing, selection and commands feel right on both devices, the slam and the regeneration suit the game, the HUD reads at night with the centre clear, and the retuned nights are tense with an army. Say whether you accept the Round 2 balance as it stands, in particular that the pure tower opening no longer wins under the bots (towers_first 0 of 10, houses_first 4 of 10). Phase 3 closes and Phase 4 can begin.
- **Fixes first:** list the feel and tuning fixes that must land before Phase 4 (for example: a unit or squad number, the slam's radius, damage or cooldown, the regeneration pace, a pad button, the cursor speed, the toast width, the control-group rule, the first tower's firing interval or which of the four balance goals gives way if the tower opening should win again), and any of assumptions 1 to 15 you want changed.

The decision is recorded through `/gsd-verify-work`. No Phase 4 work starts before it.
