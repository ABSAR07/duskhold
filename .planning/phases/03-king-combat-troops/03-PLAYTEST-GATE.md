# Phase 3 Playtest Gate: King Combat & Troops (owner packet)

You are the gate (D-08 feel half, Phase 2 D-18, ROADMAP success criteria 1 to 5). Claude has checked everything it can observe and lists it below. It cannot tell you whether the army feels good to command, whether the slam and the regeneration suit the game, or whether the HUD stays readable in a real fight on your hardware. Spend two or three full runs on that, on both devices, then sign off or name the fixes. **Nothing here counts as your sign-off**; your decision, recorded through `/gsd-verify-work`, closes the phase.

## How to play

- **Exported build:** `build/windows/Duskhold.exe`, freshly exported on 2026-10-12 (UTC) from commit `c418b6c`, the state the latest CI run checked. It launched and quit cleanly in the headless check `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` (exit 0 in about 3 s). It replaces the Phase 2 export.
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
| Queue an order behind the current ones | hold Shift while giving it (up to 9 orders per squad) |
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
| Queue an order behind the current ones | hold the right trigger (RT) when you confirm |
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
6. **Do the retuned nights feel tense with squads?** Nights 1 to 4 are unchanged (5, 12, 21, 21 enemies); nights 5 to 8 are now 25, 31, 39 and 39. Is the army worth its gold against a tower, or do you feel nothing is gained (see the first balance finding below)?

## What Claude already checked

**Automated checks** (final state, commit `c418b6c`; this plan changed no game data and no simulation code, only the screenshot tooling, one CI timeout and the size of the queued-order numbers):

- **Test suite:** 1373 tests in 148 scripts, all passing, 15364 asserts, exit 0 in 630 s (`bash tools/test.sh`); lint and format clean (`bash tools/lint.sh`).
- **Seeded replays:** smoke `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (golden unchanged); army `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4` (golden unchanged); both twice in one process, locally and in CI. CI also ran `full_idle` (shipped data, balanced bot): `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6199 digest=ab4d17d91e197347f66e24008fffbc3f7061b0b1ab27de312423212797650b7a` (it has no golden and moved with the night retune by design).
- **CI:** https://github.com/ABSAR07/duskhold/actions/runs/38219154906 on `c418b6c` succeeded on all four jobs: lint 25 s, test 6 min 31 s (with the smoke, army and full_idle replay checks), export 33 s, screenshots 2 min 25 s with **33 of 33 screenshots saved** (artifact `duskhold-screenshots`, kept 7 days). The first CI run of this plan (`38215930089`, on `549e53c`) failed its screenshots job on two of the new shots, `cmd_queue_ten` and `cmd_move_ping`, because a frame on the software renderer is long enough for a squad's first leg to end during ten clicks and for the half-second ping to expire; the scenes were made independent of frame time (`85990e9`, run `38217462543` green), and a third change made the slam ring show in the CI frame too (`c418b6c`). The screenshots job needed 2 to 3 minutes, so its 60-minute timeout is generous; it stays as the plan said.
- **Windows build:** `bash tools/export.sh` exported `build/windows/Duskhold.exe`; the launch check above exits 0 in about 3 s.

**Balance, from scripted bots** (`03-BALANCE-REPORT.md`, plan 03-11, seeds 1 to 10, shipped data; reproduce with `bash tools/playtest.sh --seeds=10`). The bots build instantly without riding, react perfectly and start every night at once, so this measures the data, not a player and not the feel of squads.

| Strategy | Win rate | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) | Buildings lost (mean) | Knockouts (mean) |
|---|---:|---:|---:|---:|---:|---:|
| no_build | 0% | 1.0 / 1 / 1 | 2 | 1.0 | 0.0 | 0.0 |
| greedy_economy | 0% | 2.9 / 2 / 4 | 4 | 9.2 | 5.0 | 1.8 |
| houses_first | 90% | 7.4 / 2 / 8 | 3 | 25.1 | 9.2 | 0.5 |
| towers_first | 30% | 7.2 / 6 / 8 | 8 | 6.9 | 6.0 | 3.8 |
| balanced | 90% | 7.4 / 2 / 8 | 3 | 24.0 | 5.8 | 0.5 |
| army_balanced | 80% | 7.5 / 5 / 8 | 6 | 15.3 | 16.4 | 1.1 |

Two findings the report leaves for you, plainly:

- **Squads are not stronger than towers per gold under these bots.** The army bot (footmen follow the king, archers hold, the king slams at three enemies) won 10 of 10 on the old night counts but falls faster than the tower-heavy balanced bot as the late nights grow, and it loses far more buildings (16.4 a run against 5.8). The units do real work (4 to 11 enemy kills per late night), but the balanced order puts that gold into towers, which kill more. A player who fights beside the squad, or posts the footmen where they shield a tower, may do better or worse than the bot.
- **The balanced bot still loses 1 of 10, not the 2 or 3 you asked for in Phase 2 (G-02-15).** Regeneration (plan 03-04) moved it from 2 losses to 1, and raising the early nights to cost it a run breaks the Phase 2 night-3 wall (a x1.5 raise lost every seed on night 3). Night 8 equals night 7 (39 each) because a larger last night ends the tower opening on every seed. The two goals cannot both be reached by night counts alone with these squads; you decide which bar the nights serve.

**Screenshot review** (Claude opened every new image: all 18 locally in a real window with the Forward+ renderer, and again from the CI artifact, which is flatter and paler because it is the Compatibility renderer under Mesa; the content is the same). Every `hud_` and `cmd_` shot also passes the runner's clear-centre check (no visible HUD control other than the banner, the knocked-out label, the drag box while dragging and world-anchored markers inside x 384..896, y 96..500 of the 1280x720 base space), or it would have failed:

| Shot | What it shows | Result |
|---|---|---|
| `hud_day_squads` | Day 1, Barracks and Range raised, the Barracks squad selected: both slots 4 / 4 with the selected one outlined, the hint row (7 items, 318 to 964 px wide) above them, rings under the four footmen, the king widget bottom-left, the start-night prompt below the slots | Pass; widgets stand apart, centre empty |
| `hud_night_squad_down` | Night 7 of 8, 9 enemies left: the Barracks slot reads a red 0 / 4 with its fill showing a replacement on the way, the Range 3 / 4, the king at 36 / 50, his cyan X-ray silhouette behind the keep, health bars over enemies and the keep | Pass; all text reads on the dark ground |
| `hud_drag_box` | A drag box (fill 16 %, border 2 px, cyan) from the top-left to the middle right across the keep, the slots unselected and no hint row | Pass; the box is the one thing allowed in the centre |
| `hud_pad_cursor` | Pad as last device: the start-night glyph is a Y tile, the slam badge shows an X tile, the cursor ring and its line run from the king toward the east, the hint row is replaced by "Aim with the right stick, release to confirm" at y 504 | Pass |
| `hud_king_down` | Night 7, knocked out: widget at alpha 0.4 with a red 0 / 50, "Knocked out - back in 6 s" in cyan under the banner, the squad slots unchanged | Pass |
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
- **Copy:** the night banner and the preview line print "1 enemies left" and "Night 12: 1 enemies from 1 direction" at a count of one (Phase 2 copy; the fix is a plural rule in `hud.gd`, outside this plan's files).
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
14. **The bots' army plan and the retuned nights:** the army bot's footmen follow the king and its archers hold, and it slams at three enemies in reach; the night totals are 5, 12, 21, 21, 25, 31, 39, 39 (only nights 5 to 8 moved), and no economy, squad or unit number was changed to get there.
15. **The mouse is back for squads only (D-11):** building stays hold-only, the mouse never aims the king and never moves the camera, and the camera stays locked on the king, so a point off screen needs him to ride closer (D-13).

## Your decision

Choose one and tell Claude in the `/gsd-verify-work` session:

- **Sign off:** squads guard and commit instead of thrashing, selection and commands feel right on both devices, the slam and the regeneration suit the game, the HUD reads at night with the centre clear, and the retuned nights are tense with an army. Say which of the two balance findings (squads not stronger than towers per gold; the balanced bot losing 1 of 10, not 2 or 3) you accept for now. Phase 3 closes and Phase 4 can begin.
- **Fixes first:** list the feel and tuning fixes that must land before Phase 4 (for example: a unit or squad number, the slam's radius, damage or cooldown, the regeneration pace, a pad button, the cursor speed, the toast width, the "1 enemies" copy, the control-group rule, which balance bar the nights serve), and any of assumptions 1 to 15 you want changed.

The decision is recorded through `/gsd-verify-work`. No Phase 4 work starts before it.
