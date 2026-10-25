# Phase 5 Playtest Gate: Castle Center & Economy Depth (owner packet)

You are the gate (the feel half of D-02 and D-12, ROADMAP success criteria 1 to 4 of Phase 5). Claude has checked everything it can observe and lists it below. It cannot tell you whether the castle's cards read well and are worth a pick, whether the twelve abilities are distinct and worth their numbers, whether the castle gate makes the castle a real choice, or whether the four new buildings (Gold Mine, Mill with Fields, Fishing Harbor, Shrines) make the day's gold decisions deeper and still fun. Play two or three full runs, then sign off or name the fixes that must land before Phase 6. Nothing was changed in the game in the last plan; everything below describes the build as it ships.

## Gap round (G-05-2 and G-05-7): what changed and what to re-judge

Written 2026-10-25 (UTC). This section is the newest and comes first. Everything below it (How to play, What to judge, What Claude already checked and the rest) is the packet from before your round of play and stays as history: where it quotes an old number, a plot position or the old build, this section wins.

### What changed

You asked for two things after playing the build, and this round does them.

- **Every health and damage number is now 100 times bigger, as you required.** The king has 5000 health, a footman hits for 100 and a Tower for 300, and the screen shows those numbers exactly as they are. Gold did not change at all: costs, incomes and refunds are as they were. The reason you wanted it is now true: a percent card adds exactly what it says. Commander's soldiers hit 125 instead of 100, Warded Mail turns every 200 blow into 150, Iron Discipline is an honest x1.5 (100 becomes 150), Royal Training adds +100 king damage and +25% king health (5000 becomes 6250), and Masons add 30% where before the rounding gave 33%.
- **Three cards were recut.** Prosperity pays 2 gold a dawn instead of 1. Golden Age pays 4 gold a dawn plus its Shrine bonus instead of 2. Headsman's Edge still hits twice as hard but is now only a quarter slower between blows instead of half as slow.
- **The Fishing Harbor moved to an exposed spot.** It now stands on a smaller pond beside the west road, between the first tower and the Gold Mine. Skirmishers walking that road notice it and come for it, and no tower or castle arrow reaches it, so it is awkward to defend (your wish). Its health is lower: 1400 (2000 once upgraded) instead of 1800 (2400). Its price, its boats and the gold each boat pays are as before, and it still needs Castle II for its second tier.
- **The king's health number beside his bar is wider now** and sits a little further right, so "6250 / 6250" stays on one line.

Nothing else moved: the castle ladder (6, 10 and 16 gold), the other nine cards, the Mine, the Mill and Fields, the Shrines and the night counts are as they were.

### What the bots measured

The scripted bots play the new numbers and say nothing about feel; you are the judge of that.

- **The bar your earlier rounds set still holds, without lowering it.** The main bot wins 8 of 10 games, and the army bot wins 8 of 10 with its soldiers killing nearly as much per gold as towers do (a ratio of 0.88 against a bar of 0.8). The main bot still buys its first castle upgrade on day 6 at the earliest. No bot's build order was changed to make this pass.
- **The Harbor is now at risk.** The main bot built it in 9 of 10 games, enemies attacked it in 7 of those 9, and it was destroyed 18 times across the ten games. The bots never ride out to defend it, so this is the worst case: a king who defends it will lose it less. The price shows in the bot's income: it earns about 26 gold a run instead of 30 and loses about 11 buildings a run instead of 9, with the same two lost games as before.
- **Prosperity trails Masons.** With only the second-tier card swapped, the main bot won 8 of 10 with Masons and 6 of 10 with Prosperity, even when Prosperity was tried at 3 gold a dawn. More on this under the card choices below.
- **The old checks are unchanged.** The four recorded test runs replay byte for byte, 300 enemies still cross the wall gate with none stuck, and the full test suite passes (281 test files, 2668 tests).

### How to play

- **The fresh build is `build/windows/Duskhold.exe`**, exported on 2026-10-25 (UTC) from the finished round. `Duskhold.pck` and `libduskhold_sim.windows.x86_64.dll` sit beside it, and a headless launch (`timeout 90 build/windows/Duskhold.exe --headless --quit-after 120`) started and quit cleanly in about 8 seconds. It replaces the 2026-10-22 export.
- The controls, the editor-binary alternative and the plot list under "How to play" further down are unchanged, except for the Harbor: it is no longer at (0, 20.5) behind the castle but beside the west road, with its pond (see What changed).
- Keyboard and mouse only, as before.

## How to play

- **Exported build:** `build/windows/Duskhold.exe`, exported on 2026-10-22 (UTC) by `bash tools/export.sh` from the tree at commit `570ff8d` (the game code is that of plan 05-11 and the orchestrator's wave-10 fix; every later commit is planning files only). That is the code CI run 39751537305 checked. `libduskhold_sim.windows.x86_64.dll` and `Duskhold.pck` sit beside the exe, and `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` launched and quit cleanly (exit 0 in about 8 s). It replaces the Phase 4 export.
- **From the editor binary, in PowerShell** (PowerShell's `bash` is WSL, so the Git Bash wrappers are not your entry point):

  ```powershell
  & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path .
  ```

  If you changed anything under `native/` or checked the project out fresh, run `bash tools/native_build.sh` once in Git Bash first (it prints `NATIVE_BUILD_OK`). The exported build needs nothing.
- **A run:** the same eight nights on the one prototype map, now with 22 buildable plots plus the castle (23 spots). New this phase:
  - **The castle plot** at (0, 4.2), just south of the keep, which you hold-buy like any plot. It starts at tier I and has three upgrades (II, III, IV). At each upgrade the four cards of that tier appear in a row above the keep; you pick one card and buy the tier, and the card's bonus lasts the whole run. Each upgrade also raises the castle's health, arrow damage and the gold it pays at dawn.
  - **The castle gate:** the last tier of House, Tower, Barracks, Archery Range and Wall (and Mill III and Fishing Harbor II) refuses to be bought until the castle is at tier II. The plot's label then reads "Needs Castle II".
  - **The Gold Mine** at (-30, 30): pays 3 gold at the first dawn, then 2, then 1, and stays at 1.
  - **The Mill** at (30, 28) with **three Fields** at (25.5, 30.5), (30, 33) and (34.5, 30.5): a Field cannot be bought until the Mill stands ("Needs a Mill").
  - **The Fishing Harbor** at (0, 20.5) on the north shore of a pond centred at (0, 30) with radius 8: it gains one boat at each dawn it still stands, up to a cap, and every boat pays gold at dawn. The pond is for looks; nothing collides with it.
  - **Two Shrines** at (-46, 30) and (46, 30): a Shrine sleeps until enemies have died close to it, then wakes and fires bolts at enemies in its reach for the rest of the night.
- **Debug overlay (F3):** it now has a Stats section (every bonus the cards have stacked, per stat) and an Economy section (what each income building pays next dawn, the Harbor's boats, whether a Shrine is awake).

### Controls, keyboard and mouse (read from the Input Map as shipped)

Keyboard and mouse only (owner decision 2026-10-16: the pad bindings from Phases 1 to 3 stay in the project unsupported; nothing here asks you to judge a gamepad).

| Action | Keyboard and mouse |
|---|---|
| Ride (walk 7.5 m/s) | WASD or the arrow keys |
| Sprint (12 m/s) | Shift |
| Build or upgrade (ride to a plot, hold) | Space or E |
| **Pick a castle card** | **keys 1 to 4, or point at a card / left click it, then hold Space or E to buy** |
| Start the night (hold, by day) | N |
| Slam (any time, 9 s cooldown) | Q |
| Fast-forward (night only, press to switch on and off) | T |
| Select a squad / several / every squad of a type | left click a unit or its slot; drag a box; Ctrl + click; double-click a unit |
| Select every squad / cycle to the next | F2 / Tab |
| Follow the king / hold / rally to the king | F / H / R |
| Move / attack-move / patrol | right click on the ground / A then left click / hold P and right click points |
| Queue an order behind the current ones | hold Shift while giving it |
| Cancel, then clear the selection | Escape |
| Store / recall a control group | Ctrl + 1 to 9 or 0 / the digit 1 to 9 or 0 (while the castle cards show, the digits 1 to 4 pick a card instead) |
| Camera zoom | = and - (also the keypad) |
| Debug overlay | F3 |

A click on a card never buys anything: it only highlights the card. The hold on the action key is the only way to buy, and the card highlighted when the hold starts is the card you get. With no card highlighted the hold is refused with the usual denied bump.

## What to judge

Play **two or three full runs, climbing the castle with picks and building the new economy**. The questions only you can answer:

1. **Do the cards read, and does picking feel right?** Four cards stand in a row above the keep (icon, name, a flavour line, a key tile 1 to 4; the pointed-at card rises and shows its effect line in yellow). Can you read them from the riding camera? Does picking by key and by mouse feel natural? Do the cards showing again every time you ride past the castle with enough gold (nothing dismisses them) help you or annoy you?
2. **Are the twelve abilities worth a pick and distinct?** Tier II: Royal Training, Commander, Masons, Prosperity. Tier III: Headsman's Edge, Engineers, War Horns, Warded Mail. Tier IV: Iron Discipline, Arrow Storm, Master Builders, Golden Age. Is there a card you would never take, or one you always take? Is Prosperity (+1 gold at dawn) too weak beside the others? Do you feel the effect when you take one?
3. **Does the castle gate make the castle a real choice?** The last tier of every defense building needs Castle II (6 gold). A run that skips the castle cannot upgrade a tower. Does "Needs Castle II" read as a trade-off to make, or as a wall in your way?
4. **Does each new building read, and is it worth its gold?** The Mine's falling payout (3, 2, 1), the Fields' lock behind the Mill, the Harbor's boats arriving one per dawn, the Shrines waking. Can you tell what each one pays before you buy it (the label shows the next payout)? Does any one of them feel pointless or too strong?
5. **Do the day's decisions feel deeper, and is it still fun?** The core value: meaningful gold trade-offs by day, tense defense by night. The bots only measure; only you can say whether the day is richer or merely busier.

## What Claude already checked

Everything below was run by plan 05-12 on 2026-10-22 (UTC): the local pass first, then CI.

**Tests, replays and the gate stress (local, one sitting, commit `82928bd`):**

- `bash tools/test.sh`: 279 scripts, 2653 tests, 2653 passing, 60264 asserts, exit 0 (876 s). No failure, no flake. Lint: 446 files unchanged, no problems.
- The five replays, each run twice in one process, all agreeing: smoke `2599c7c2` (703 ticks), army `f7a967ed` (1353), walls `bfb05fc7` (1961) and economy `f4b98093` (1842) against their golden files in `tests/golden/`, byte-identical to what plans 05-10 and 05-11 recorded; `full_idle` (no golden file by design, it plays the shipped data) won at 7000 ticks with digest `afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14`, the digest 05-BALANCE-REPORT.md records after the castle gate. No golden digest moved, so the D-08 stop rule did not fire.
- The gate stress, twice: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0`: 300 enemies cross the 80 m wall through its 4 m gate and none is stuck.
- All 44 screenshots were captured in a real window (RTX 3060 Laptop, Forward+, 1280x720) with no script error in any shot's log and no blank image; 44 PNGs on disk, one per shot in `ALL_SHOTS`.

**CI: run 39751537305, https://github.com/ABSAR07/duskhold/actions/runs/39751537305, for commit `570ff8d`, first push, no fix cycle: success on all six jobs** (lint, native-linux (GCC), native-windows (MSVC), test, screenshots, export). Its log carries `REPLAY_OK` for smoke, army, walls, economy and full_idle (on the Linux test job and again on the Windows library, with the same digests as the local run, so the economy golden and the native push-apart agree under GCC and MSVC) and `GATE_OK enemies=300 crossed=300 stuck=0` on both; the screenshots artifact holds the same 44 PNGs. The workflow still has `permissions: contents: read`, no secrets and every pinned `uses:` SHA; the only change in this plan is one comment line.

**The eleven shots Claude opened with its own eyes, local and (for the seven new ones) the CI copies (CI uses the Compatibility renderer, so its images are flatter and lighter; the same content is on them):**

- `day_overview`: the keep (castle tier I) fills the top of the frame with its blue roofs, two teal-roofed Houses either side of the king, two dark-red tower discs top left and top right; "Gold: 23", the night banner and "Hold N to start Night 1" all read.
- `spot_label`: the king on a House plot, "House I / +1 gold at dawn" over the plot, readable against the grass.
- `build_in_progress`: "Tower I / Range 9.0 · Damage 3" with the coin dots filling above the king as the hold runs; reads.
- `dawn_payout`: coins fly from the Houses toward the gold counter at dawn (Gold: 23, the dark dawn tint), the keep above them; reads.
- `castle_cards`: the four tier II cards in a row over the keep, each with a first-party icon, a key tile 1 to 4 in its corner and a flavour line; the card the mouse points at (Commander) is raised, lit and shows its effect line "+25% unit health, +25% unit damage" in yellow; the plot label "Castle II / Health 100 · Arrow 3 · 2 gold at dawn" sits under it with six grey cost dots. The one thing that reads badly: the HUD banner "Night 1 of 8" overlaps the top of the raised card and the first card (open point 1).
- `castle_tier_four`: the tier IV keep is a tall stack of towers and flagpoles; the label reads "Castle IV / Max tier / Royal Training · Engineers · Golden Age"; the roof tip and flag are cropped by the top of the screen at the default zoom (open point 2); the king's health reads 63 / 63 after Royal Training.
- `field_locked`: the king on the first of three Field plots round the Mill with "Field I / +1 gold at dawn / Needs a Mill" over it; the label tells the lock plainly.
- `harbor_pond`: a flat blue pond with three boats (cream deck and sail on a brown hull) at different angles, the dock of dark boards reaching from the teal-roofed hut into the water, "+4 gold" in the corner after the dawn payout; the water and the boats read; the king stands on the pond (it is visual only).
- `shrine_awake_night`: the awake Shrine on its violet plot disc, a pale-violet orb above its obelisk and a bolt in flight toward the crowd on the road, gold tower arrows beside it, banner "Night 1 of 2 — 19 enemies left"; the glow and the bolt read; the banner sits over the arrows at the top of the frame.
- `castle_gate_locked`: a built Tower I with the king beside it, label "Tower II / Range 10.5 · Damage 6 / Needs Castle II"; the gate reads as a plain requirement.
- `economy_day`: a wide day view with the keep at the top, the pond with two boats and the Harbor, the Gold Mine and a Shrine on the left, the Mill with two Fields on the right, the king in the middle; the whole new economy is in one frame (camera zoom 3.4 for this capture only). The buildings are small at that distance: the Mine's coins and the Mill's blades are hard to make out (open point 3).
- **No presentation fix was needed, so no game code changed in plan 05-12.**

**The Windows build:** exported and launch-checked as described under "How to play".

**Balance (05-BALANCE-REPORT.md, plan 05-11, `bash tools/playtest.sh --seeds=10`, 100 runs; scripted bots that say nothing about feel):**

| Strategy | Wins (10 seeds) | Lost (seed: night) | Nights survived (mean) | Gold earned (mean) | Castle tier (mean) | Squad value ratio |
|---|---:|---|---:|---:|---:|---:|
| balanced (castle-aware order) | 8 of 10 | 3: 7, 9: 3 | 7.2 | 30.0 | 1.80 | n/a |
| balanced_no_castle (the Phase 4 order) | 3 of 10 | 2: 8, 4: 8, 5: 8, 6: 7, 8: 8, 9: 3, 10: 7 | 6.6 | 20.4 | 1.00 | n/a |
| army_balanced | 8 of 10 | 1: 7, 9: 6 | 7.5 | 15.0 | 1.00 | 0.888 |
| greedy_economy | 0 of 10 | loss nights 3 to 5 | 2.9 | 9.2 | 1.00 | n/a |
| no_build | 0 of 10 | night 2 on every seed | 1.0 | 1.0 | 1.00 | n/a |

- **The Phase 2 bar holds** on the shipped 23-spot map with the gate in the data: `balanced` wins 8 of seeds 1 to 10 (bar 7 or 8), `army_balanced` wins 8 of 10 with a squad value ratio of 0.888 (bar 0.8), and the balanced bot's first castle upgrade is on day 6 at the earliest (D-01: never before day 2). The bot's own order was the lever that met the bar; **no castle tier, card, new-building or night number was fitted**, so every number in the data is the plan's starting number.
- **D-08 outcome:** smoke, army and walls were never regenerated and none of their digests moved (they run on frozen fixture maps that carry their own copies of every def); economy is the one new golden (`f4b98093`, 1842 ticks); `full_idle` moved from `4385f569…` (won, 6911 ticks, before the phase) to `afc11cd0…` (won, 7000 ticks, after the gate and the castle-aware order). No golden was re-pinned.
- **What the gate does:** a Phase 4 style game (towers, Houses, walls, no castle) cannot upgrade a tower, so the same bot falls from 8 wins to 3. The Fishing Harbor is the strongest new income (the balanced bot earns 30 gold a run, up from 20, almost all from boats); the Mine, Mill and Fields pay about what a House does and are bought last; the Shrine wakes in a minority of seeds and almost never fires.

## Open points (feel calls Claude saw and did not change)

None of these touches data, rules or tests, and each is yours to rule on at the decision below.

1. **The HUD night banner overlaps a raised card** (plan 05-04, still in `castle_cards`): the text "Night 1 of 8" sits over the top of the card the mouse points at. It is legible but untidy; a fix is a presentation offset on the card row.
2. **The tier IV keep's roof tip and flag are cropped at the default zoom** (plan 05-04): 15 m tall, four storeys. Zooming out shows it whole.
3. **The new buildings are small in a wide shot** (`economy_day`): they read when you ride up to them; from the far camera the Mine and the Mill are hard to tell apart.
4. **The Shrine does almost nothing in bot play:** it sits 12.5 m from the road with a 9 m reach and fired about never in the sweep; a longer reach and a lower wake threshold did not change that. Whether a visible, working Shrine needs its plot nearer the road, or a different wake rule, is a decision.
5. **The Fishing Harbor dominates income:** the Mine, the Mill and the Fields pay no better than a House. The shapes are fixed by D-12 but the numbers (the Harbor's cost and cap, the Mine's first payout) are free.
6. **Castle tiers III and IV are out of bot reach** (costs 10 and 16 against about 30 gold a run) and the army build cannot afford the castle at all. If you want the later tiers to be real mid-run decisions, their costs or the income are the levers.
7. **Cards re-appear on every pass** with enough gold, with no dismiss (research A10).

## Assumptions made for you

Nothing here was confirmed with you. Change any of it at the decision below.

1. **The castle ladder as finally measured (05-02, 05-11):** the castle has four tiers; the three upgrades cost 6 / 10 / 16 gold, raise health to 100 / 140 / 200 and arrow damage to 3 / 4 / 5 (arrow range 22 m, shot every 1.5 s), and pay 2 / 3 / 4 gold at dawn (tier I: 1). 05-11 left every one of these numbers as drafted because the bar was met without moving them.
2. **The twelve cards and their numbers are Claude's draft (05-03, D-02):** tier II Royal Training (king health +25%, king damage +1), Commander (unit health +25%, unit damage +25%), Masons (building and wall health +30%), Prosperity (+1 gold at dawn); tier III Headsman's Edge (king damage x2, attack interval x1.5), Engineers (tower damage +25%, tower range +15%), War Horns (squad respawn time x0.6), Warded Mail (damage the king takes x0.75); tier IV Iron Discipline (unit damage x1.5, unit health x1.3), Arrow Storm (castle arrow damage +100%, range +25%), Master Builders (building and wall health x1.5), Golden Age (+2 gold at dawn, Shrine damage +25%).
3. **Three names are original replacements for the IP rule (05-03):** Headsman's Edge, War Horns and Warded Mail replace the drafts "Assassin's Training", "Rallying Banner" and "Magic Armor". The nine kept names (Royal Training, Commander, Masons, Prosperity, Engineers, Iron Discipline, Arrow Storm, Master Builders, Golden Age) are generic words with no recorded check against Thronefall's own perk list.
4. **Warded Mail lowers the damage the king takes by a quarter** (05-03, research A3); it does not reflect damage, which CONTEXT defers as a rule change.
5. **Prosperity and Golden Age add flat gold to the castle's base income** (05-03, research A4), not a percentage of all income, so the dawn payout keeps one rounding home; Prosperity's +1 is modest next to the other tier II cards.
6. **No card is pre-highlighted** (05-02, research A7): a hold with no highlighted card is refused with the denied bump. Picking by key or by pointing is the only way; a pre-highlight of card 1 is a one-line change.
7. **The cards show every time you ride past the castle with enough gold, and nothing dismisses them** (05-04, research A10); the cards appear only when the next tier is affordable, so a player short of gold sees the price and no cards (05-02: the cannot-afford answer comes before the choose-a-card answer).
8. **Card icons and key tiles (05-04):** twelve first-party flat vector SVG icons (logged in ASSETS.md as CC0-1.0) and the logged Kenney keyboard key tiles on each card; the Phase 8 art pass may replace them.
9. **The keep looks per tier (05-04):** tiers II to IV are composed from the seven Castle Kit models already in the repository, growing taller each tier; the picks are listed in pick order in the castle's label.
10. **The plot positions and the castle plot (05-02, 05-06 to 05-09):** the castle plot at (0, 4.2), Mine (-30, 30), Mill (30, 28) with its three Fields, Harbor (0, 20.5), Shrines (-46, 30) and (46, 30); the castle plot is appended after the fourteen Phase 4 plots (so no stored building index moves) and counts as infrastructure: "22 buildable plots, 23 spots".
11. **The castle gate on every top tier (05-05, 05-11):** House III, Tower II, Barracks III, Archery Range III and Wall III need Castle II (D-03), as do Mill III and Harbor II from their own plans; the castle's own tiers carry no gate, and a map without a castle plot has no gate at all (every fixture and golden map stays as it was). The locked label reads "Needs a <building>" for a missing building (always "a", D-10's "Needs a Mill") and "Needs Castle II" for the gate.
12. **The Gold Mine as finally measured (05-06):** cost 4, health 20, pays 3 gold at the first dawn then 2 then 1 and stays at 1; its label shows "Next dawn: N gold" on a built Mine so the decline is readable.
13. **The Mill and Fields as finally measured (05-07):** Mill costs 3 / 4 / 6 and pays 1 / 2 / 3 (tier III needs Castle II); a Field costs 2 and pays 1, three Fields round the Mill; a Field is locked while the Mill is not standing, and the free dawn rebuild keeps the Mill's tier, so a Mill that fell in the night does not relock its built Fields by day either.
14. **The Fishing Harbor as finally measured (05-08):** costs 3 / 6 (tier II needs Castle II), boat cap 3 / 5, 1 gold per boat on both tiers, one boat added at each dawn the Harbor stands. The pond is `MapConfig.pond_center` (0, 30) and `pond_radius` 8, drawn with no collision and never part of navigation; D-11's "one map edge" is read as the south edge of the built-up area; the boats are code-built primitives, not a downloaded model.
15. **The Shrine as finally measured (05-09, 05-11):** cost 3, pays 1 gold at dawn, 30 health, fires 3 damage bolts at enemies within 9 m every 1.1 s once awake; it wakes when enemies have died within 18 m of it totalling 100 max health.
16. **Shrine credit comes from any killer (05-09, research A8):** a death near the Shrine counts toward its wake whoever killed the enemy, the Shrine itself included once awake.
17. **The stat stack's limits and rounding rule (05-01):** per stat, flat bonuses stay within plus or minus 100000, percent within -90 to +1000, multipliers within 10 to 400 with at most four multipliers; the order of pickups never matters; rounding happens once at the end, ties half up; a modifier outside the limits is refused whole. The stack is global per stat id (a per-tower stat waits for Phase 6).
18. **Units already alive when a health card is picked are raised by the gain at once** (05-01), not left at the old maximum until dawn.
19. **Declining and flat payouts (05-06):** a declining building's `dawn_income` is its first payout, and only flat curves are paid by the plain per-building payout; the curve, not a zero, decides who pays.
20. **The overlay (05-01, 05-06, 05-08, 05-09):** F3 shows a Stats section from plan 05-01 and one read-only Economy section from plan 05-06, which the Harbor and Shrine rows join.
21. **The bots measure the data and are not a sign-off (05-11):** the balanced order buys house, house, house, tower, Harbor, tower, castle (with Masons), tower, then Tower II, the Mine, the walls, the Mill with its Fields, the Shrines and the later castle tiers; the Phase 4 orders were renamed `balanced_no_castle` and `army_balanced_no_castle`. Which card a bot picks says nothing about which card is best.
22. **The D-08 reading (05-10, 05-11, research P1):** three goldens unchanged, economy new, full_idle's before and after reported in the balance report; a golden digest moving would have been a stop rule for you, and none moved.
23. **Internal limits that are not game rules (05-02, 05-09):** NightSim is at the lint cap of ten arguments with the income parameter (a later phase folds two into one holder first); plan 05-10's second task was test-only by design, so a rule gap it found would have stopped for a gap plan, and it found none.

## Your decision

Sign off, or list what must land before Phase 6, through `/gsd-verify-work 5`.

**Decisions only you can make:**

1. **The twelve abilities:** keep the set as drafted, or name the cards to rename, rebalance or replace (the numbers are data plus one contract test each).
2. **The castle gate:** keep "Needs Castle II" on every top tier, or soften it (fewer gated tiers, or a lower gate), if it reads as a wall rather than a choice.
3. **The economy mix:** whether the Harbor should be weaker, or the Mine, Mill and Fields stronger, so the order of attractiveness changes; and whether the Shrine needs a nearer plot, a longer reach or a different wake rule to matter.
4. **How far the castle ladder should reach:** keep tiers III and IV as late-game goals, or lower their costs (or raise the income) so they happen mid-run; and whether the army build should be able to afford the castle.
5. **The card row:** whether the cards re-appearing on every pass needs a dismiss, whether the first card should be pre-highlighted, and whether the banner overlap and the cropped tier IV roof need a presentation pass now or wait for Phase 8.

**Also:** say whether any numbered assumption should change, and list the feel and tuning fixes that must land before Phase 6. Anything you list becomes a gap plan through `/gsd-verify-work 5`.
