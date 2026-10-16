# Phase 4 Playtest Gate: Crowd-Scale Battles & Walls (owner packet)

You are the gate (the feel half of D-15, ROADMAP success criteria 1 to 4 of Phase 4). Claude has checked everything it can observe and lists it below. It cannot tell you whether walls feel worth their gold, whether the gates funnel the crowd the way you want, whether enemies that break a wall or walk to the gap look smart, or whether a big battle feels good to watch. Spend two or three full runs buying walls, and watch the stress night once, then sign off or name the fixes that must land before Phase 5.

**Read this first: the performance goal is NOT met.** PLAT-01 and ROADMAP success criterion 3 ("hundreds of units, enemies, and projectiles at 60 fps") are recorded as **not met** (details under "What Claude already checked"). Plan 04-09 halted at its own stop rule with a median-run p95 frame time of **37.04 ms against the 8.0 ms budget**, about **43 fps** at the median with **300 enemies** on screen, and the shipped nights top out at about **40 enemies** (a step of about 3.6 ms in the bench). You chose to run this gate on the missed budget (decision of 2026-10-16), so the packet below asks for the feel judgement and for your route on performance, which is the open decision it needs from you.

## How to play

- **Exported build:** `build/windows/Duskhold.exe`, freshly exported on 2026-10-16 (UTC) from commit `a8c57ab`, the state the latest CI run checked (https://github.com/ABSAR07/duskhold/actions/runs/38959046206). It launched and quit cleanly in `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` (exit 0 in about 3 s). It replaces the Phase 3 export.
- **From the editor binary, in PowerShell** (PowerShell's `bash` is WSL, so the Git Bash wrappers are not your entry point):

  ```powershell
  & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path .
  ```

- **A run:** the same 8 nights on the one prototype map. New this phase: four **wall plots** (Wall: barricade, stone, reinforced; 2, 4 and 6 gold per tier, bought for the whole run of segments at once). Ride up and hold the action key like any plot. A run has 12 segments at the west, east and north plots and 16 on the ring round the castle, each segment 3 m long with its own health (30, 60 and 90 per tier). Segments block the enemies' straight line; each run has a gap (4 m on the roads, three 4 m gaps on the ring), and enemies either walk to a gap or break a segment, deciding by how long each would take. A broken segment sinks to rubble that blocks nothing and rises again at dawn.
- **Where the four wall plots are:**
  - West plot: (-58.3, 21.2), just inside the west road's gap, the run being 36 m long from (-54, 38.8) to (-66.3, 5.0).
  - East plot: (58.3, 21.2), the mirror of it on the east road.
  - North plot: (0, -58.5), just inside the north road's gap, the run lying along z = -60.5 from x -18 to 18.
  - Ring plot: (0, -6.5), inside the ring (9 m radius round the castle) near its north gap, clear of where the king starts a day. The ring has gaps at its north, west-south-west and east-south-east; stand at the plot and the label names the run ("12 segments, 30 health each" and so on).
  Hold the action key at the plot (the plot sits just inside its run's gap, on the castle side). The king cannot walk through a standing segment (he is pushed out of it); he rides through the gaps or round the ends.
- **The stress night** (a tools scene, only from the editor binary, not in the exported build because `tools/` is excluded). It shows the largest battle: 300 enemies, 50 footmen, 20 towers and the gate wall:

  ```powershell
  & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path . res://tools/stress/stress_night.tscn -- --duration=30
  ```

  It runs in a real window (never headless), measures for 30 s after a 10 s warm-up and quits by itself. The camera is high so the whole field is in view and the crowd looks small; towers shoot slow arrows so many are in flight. Judge smoothness by eye. Its frame numbers are in 04-FRAME-REPORT.md; this run is for how it feels, not for a new measurement.

### Controls, keyboard and mouse (read from the Input Map as shipped)

Keyboard and mouse only (owner decision 2026-10-16: the pad bindings from Phases 1 to 3 stay in the project unsupported; nothing in this phase asks you to judge a gamepad).

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
| Attack-move | A, then left click on the ground (with nothing selected the key is the king's move-left) |
| Patrol | hold P, right click each point, let go of P (up to 7 points) |
| Queue an order behind the current ones | hold Shift while giving it |
| Cancel a waiting point command, then clear the selection | Escape |
| Store the selection as a control group / recall it | Ctrl + 1 to 9 or 0 / the digit 1 to 9 or 0 |
| Camera zoom | = and - (also the keypad) |
| Debug overlay | F3 (new rows this phase: Walls and Field, plus Crowd frame time and the drawn counts) |

## What to judge

Play **two or three full runs buying walls** and watch the stress night once. The questions only you can answer:

1. **Are barricades and walls worth their gold, and do they read by tier?** A barricade costs 2 (the same as a first-tier House), stone 4, reinforced 6. The tier looks are a primitive palisade, the Castle Kit stone wall, and stone with tower-base pillars. Can you tell the tiers apart from the riding camera, and does a hurt segment's health bar read?
2. **Do the gates funnel enemies into the towers?** With a wall across a road, do the crowd bunch at the gap in front of the towers' range, or do they spread and chew through the wall?
3. **Does an enemy that breaks a weak wall versus walking to the gap look smart and readable?** The rule is by time: a crowd at a weak segment breaks it, a strong wall sends them round. Does the choice look intentional, and does a breach read (the segment sinks, rubble blocks nothing, dawn rebuilds it)?
4. **Do squads and the king get round walls without fuss?** The army bot loses seeds even with free walls (assumption 22); the suspected cause is squads following the king round the walls. Does your squad hold up, and do you ever get stuck?
5. **Does the stress night feel smooth, and does the crowd read?** It will not reach 60 fps on a measured basis (see below); is the crowd legible, are the arrows and the towers readable, and where does the frame time hurt you on your machine?
6. **Do the nights still feel tense with walls available?** No night count, wall cost or other data moved in this phase (the bots' measured nights are the same as Phase 3's), so this is the same eight nights with the walls on top. Do walls make the nights too easy, or are they bought too late to matter (the bots only afford them in the last days)?

## What Claude already checked

Everything below was run in one local pass by plan 04-11 on 2026-10-16/17 (UTC) and then on CI.

**Performance, stated plainly: PLAT-01 and ROADMAP success criterion 3 are NOT met.**

- Quoted exactly from 04-FRAME-REPORT.md (plan 04-09, halted): "**Verdict: the budget is NOT met.** The median run's p95 frame time is 37.04 ms against the 8.0 ms budget (4.6 times over), with the D-10 on-screen bar met in full (300 enemies, 50 units and 239 or more arrows in view at every sampled frame). The simulation step, not the renderer, is what misses."
- The median run (run 1 of three, p95 36.58, 37.04, 38.89 ms): 856 frames (about **43 fps**), frame time p50 20.92 ms, p95 **37.04 ms**, p99 50.00 ms, maximum 74.82 ms; step (`ctx.advance`) mean 14.34, p50 18.14, p95 25.43 ms; render CPU median 0.70 ms, render GPU median 4.46 ms, 230 draw calls. On screen at every sampled frame: 300 enemies, 50 units, at least 239 arrows (bar 300 / 50 / 200). The renderer is healthy; the simulation step (18 to 25 ms on a step frame) is what costs.
- Hardware: NVIDIA GeForce RTX 3060 Laptop GPU, Intel Core i5-10500H, Windows 11, Godot 4.7.2 Forward+, 1920x1080 requested, vsync off, 1.0x speed. **No GTX 970 was available and none was measured.** The projection (RESEARCH A1: GPU about 3 to 4 times slower, the GDScript step about 1.3 to 1.6 times slower) puts the median at about 30 to 37 fps and the p95 at 48 to 59 ms on a GTX 970-class machine: the projection is far over 16.7 ms, and the CPU-bound step makes the miss larger on older hardware, not smaller. The budget would need a step of about 5 to 6 ms; the measured step median is 18 ms.
- Where the step goes (profile in the frame report): enemies 15.6 ms of 22.2 ms (target choice 7.5, push-apart 3.7, move and strike 2.4); the wall logic added 8 to 10 ms once 300 enemies queue at a gate (the same night without the gate wall is 14.2 ms). Lever (a), packed storage inside EnemySystem, was **not pulled**: the measurement bounded its gain at about 1 ms of the 22 ms step, so the stop rule applied. The budget was not raised and fidelity was not lowered.
- The shipped nights are small: at most 40 enemies a night, a step of about 3.6 ms in `step_bench` (two runs of this plan: 3.56 and 3.69 ms mean at `--enemies=40`; an earlier read was 3.2 ms). Nothing the player can reach today stresses the frame; PLAT-01 is about the largest battle the game must support.
- **Wall-break rebuild hitch** (04-FRAME-REPORT.md "Wall-break rebuild"): a synchronous rebuild of the navigation grid and the castle field when a wall segment falls costs **11.74 ms mean and 13.22 ms maximum** over 16 timed rebuilds on the shipped map's 5,494 cells. The break-frame estimate (median-run p50 frame 20.92 ms plus the 13.22 ms maximum) is 34.14 ms, above 16.7 ms, so a wall break drops a frame. The plan's rule names count-based time slicing of the rebuild as the response; it changes how many ticks enemies take to see a breach, which is a rule change, so it is not made and is an open point for you below.

**Tests and replays (local, plan 04-11 Task 1):**

- `bash tools/test.sh`: 190 scripts, 1794 tests, 1794 passing, 27553 asserts, exit 0 (765 s). Lint: 334 files unchanged, no problems.
- The four replays, each run twice in one process: smoke `2599c7c2...` (703 ticks), army `f7a967ed...` (1353 ticks), walls `bfb05fc7...` (1961 ticks), the last two against their goldens in `tests/golden/`; full_idle (no golden, by design) `4385f569...` (6911 ticks), two runs agreeing.
- The gate stress, twice: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0`. 300 enemies cross an 80 m wall through its 4 m gate before 60 s and none is stuck at the end: no gridlock.
- **CI run for HEAD `a8c57ab`: https://github.com/ABSAR07/duskhold/actions/runs/38959046206**, success on all four jobs (lint, test, export, screenshots), first push, no fix cycle. Its log carries `REPLAY_OK` for smoke, army, walls and full_idle with the same digests as the local run, and the same `GATE_OK` line; the screenshots artifact holds the 37 PNGs.

**Balance with walls** (04-BALANCE-REPORT.md, `bash tools/playtest.sh --seeds=10`, 80 runs, scripted bots; they say nothing about feel):

| Strategy | Win rate (10 seeds) | Nights survived (mean / min / max) | Median loss night | Gold earned (mean) |
|---|---:|---:|---:|---:|
| balanced (with walls) | 80% | 7.3 / 2 / 8 | 3 | 21.9 |
| balanced_no_walls (the Phase 3 order) | 80% | 7.3 / 2 / 8 | 3 | 22.2 |
| army_balanced (with walls) | 80% | 7.5 / 5 / 8 | 6 | 14.8 |
| army_balanced_no_walls (the Phase 3 order) | 80% | 7.5 / 5 / 8 | 6 | 15.0 |

- The Phase 2 bar holds with walls: `balanced` and `army_balanced` win 8 of 10 and lose the same seeds as before (balanced 3 and 9, army 1 and 9). Nothing in `data/` moved in 04-10: no night count, wall cost or other number. D-15's branch that applied: the plan's first wall order broke the bar (balanced 4 of 10, army 2 of 10), the bot's order was the lever (the wall entries moved later), and D-15's second lever (wall costs) was measured as a sensitivity and not pulled. It took 133 measurements of ten seeds.
- Success criterion 4 read as D-14: the Phase 3 orders on the Phase 4 code give a byte-identical `report.json` (md5 `001778e71f38ecd0424f65e0ef9977f8`) to the Phase 3 tree over 60 runs.
- **Honest limit:** the bots earn only about 15 to 22 gold a run, so the shipped orders buy walls only in the last days before the final nights: **21 tier I walls over 20 runs, 0 segments broken in the whole sweep**. The with-walls rows show that buying walls late changes no outcome; they say nothing about what mid-game walls are worth, and the walls golden (not the bot sweep) is where the break-or-detour rule is pinned. The army bot still loses 4 seeds even with free walls (assumption 22). The squad value ratio is 0.915 on the Phase 3 twin (bar 0.8) and 0.888 with walls.

**Screenshots, 37 of 37** captured in a real window (RTX 3060 Laptop, Forward+) with no blank image, no clear-centre failure and no script error, and the same 37 on CI (Mesa software GL, flatter and lighter, as expected). Claude opened the four Phase 4 shots and every shot that shows enemies or units:

- `walls_day`: two palisade segments either side of the gap, the king at the plot with the label "Wall II / 12 segments, 60 health each" readable; the shadow is long and dark, the segments thin from this camera.
- `walls_night_breach`: night 1 with a broken segment sunk to dark rubble at the foot of the south half, two grunts at the king; the wall reads but is low contrast against the dark night ground.
- `overlay_field_gate`: the F3 overlay and the field arrows (white-blue, a lot of them, all pointing at the gate gap) with 300 purple enemies bunched at the south of the gate; the arrows read; the overlay panel covers the right part of the wall (its place by design).
- `crowd_stress_night`: 300 purple enemies funnelled through the 4 m gate under 20 towers with yellow arrows in the air and two squads of 25; the crowd reads as a mass and the gate reads as a gap; individual enemies are small from this high camera.
- `night_combat`, `building_destroyed`, `king_down_countdown`, `results_defeat`, `hud_night_squad_down`, `hud_day_squads`, `cmd_box_select`, `cmd_move_ping`, `cmd_patrol`, `cmd_slam`: enemies, puffs, arrows, rings, order lines and the HUD read as in Phases 2 and 3; `king_down_countdown` shows the stone-tier wall clearly (pink and grey blocks); no regression from the instanced views.
- `overlay_paths`: the overlay panel shows the state from before the shot's fast-forward (Day, gold 30, 0 enemies) next to a night banner and a grunt; that is the overlay's 0.25 s refresh clock against a scripted fast-forward, a property of the shot and not of the game.
- **No presentation fix was needed, so no code changed in plan 04-11.** Open readability points, none touching data or the budget: wall segments are thin and the tier I and II palisade look similar from the riding camera; wall shadows are long; the night ground is dark and low-contrast for the palisade; 300 enemies are small from the stress camera. Night readability under hundreds of units is Phase 8's pass (UI-05); recorded there, not reworked here.

## Assumptions made for you

Nothing here was confirmed with you. Change any of it at the decision below.

1. **View caps (04-01, 04-02):** at most 512 enemies, 256 units, 512 arrows and 128 death puffs are drawn at once. They are presentation caps only; the simulation is never capped. A day with more than that would silently draw fewer than are alive.
2. **Enemy look:** enemies stay low-poly capsules (144 triangles) in the shipped colours until the Phase 8 art pass; the hit flash decays over real seconds.
3. **Unit meshes (04-02):** units are drawn from the static bind pose of their model (no animation until Phase 8), baked once per unit type; arrows keep retargeting the moving victim every frame.
4. **Packed read accessors only (04-03):** EnemySystem keeps its dictionary-of-records storage and exposes `read_view()`. Converting storage to packed arrays (lever (a)) was **not done** (04-09 halted; measured gain about 1 ms of 22 ms). Grid cell sizes (12 m for structures, 8 m for enemies) are code constants, not data, since they change cost and never an answer.
5. **Wall numbers (04-04, unchanged by 04-10):** cost 2 / 4 / 6 gold and health 30 / 60 / 90 per segment for tiers I, II, III; segment length up to 3 m; half thickness 0.4 m. 04-10 measured the cheapest D-03 prices (1 / 3 / 5) and left them unused.
6. **Run geometry, gaps and plots (04-05):** outer runs 36 m long with one 4 m gap each (west and east at 64 m, north at 60.5 m from the castle, by a 5 m clearance rule), a ring of 9 m radius with three 4 m gaps; 12 + 12 + 12 + 16 = 52 segments; minimum authored gap 3 m. The king holds a wall plot just inside its gap and the ring plot sits at (0, 0, -6.5).
7. **Tier looks (04-05):** a primitive palisade (barricade), the Castle Kit wall (stone), the wall plus tower-base pillars (reinforced). The label keeps "Wall I/II/III" as its title and puts the run in the effect line.
8. **Targets behind walls are dropped (04-06, RESEARCH Open Question 3):** a king, unit, building or castle target needs a clear line for a melee attacker; a ranged attacker may shoot over a wall at what is within its range. A blocked target is dropped and the enemy marches on the castle. If you would rather melee enemies break a wall to reach a tower, that is a rule change.
9. **Pathing tunables (04-06):** 2 m navigation cells, a 10 m bounds margin, 8 cached goal fields, a 4 m goal quantum, one build per tick and a 0.5 s refresh.
10. **The wall-break rebuild hitch (04-06, measured by 04-09):** a wall break rebuilds the grid and castle field synchronously, 11.74 ms mean, 13.22 ms maximum; the break frame is estimated at 34.14 ms and drops a frame. It was accepted for now; the verdict names count-based time slicing, which is an open point under "Your decision".
11. **D-07 definitions (04-07):** "aggroed to a segment" is an enemy marching on the castle whose straight line that segment blocks within a **12 m** notice range of it, or an enemy attacking it; "near" segments are those of the same run within **2** segments; the break-or-detour decision is re-run per segment every **0.5 s** (15 ticks, staggered); a 15-tick hysteresis stops flip-flops; the detour cost is the castle field's cost to the castle.
12. **D-09's numbers (04-07):** an enemy is flagged stuck after **3 s** without **0.5 m** of progress in the castle-field cost. Healthy queued enemies can be flagged for a while in a surge (up to about 13 s in measurement), which is why the gate passes on "everyone crosses and none is flagged at the end".
13. **The give-up rule (04-07 deviation, new):** an enemy that gives up on a segment never takes that same segment again while a way round exists (`Record.wall_given_up`), added after a hysteresis of 15 ticks alone still let one grunt flip between a wall and none four times. A sealed enemy still breaks in.
14. **The gate pass rule and the stress wall (04-08):** every one of 300 enemies must cross before 60 s of simulation (measured 14 to 22 s) and none may be flagged stuck at the end. The finish margin (2.0 m), the sink margin (4.0 m) and the 60 s limit are code constants of a tools-only harness, not gameplay data; changing one changes what the gate proves. The stress wall has 100000 health per segment, so the gate measures going round, not breaking through (breaking is proved by `test_wall_behaviour`).
15. **The 8 ms p95 budget and the GTX 970 scaling (04-09):** the budget is the median run's p95 at or under 8.0 ms at 1080p, 1.0x speed, vsync off on this machine, as D-12's equivalent of 60 fps on a GTX 970-class machine; the 3 to 4 times GPU and 1.3 to 1.6 times CPU scaling is an assumption (no GTX 970 measured). p99, the worst-1-percent mean and the maximum are reported, not gated.
16. **Lever (a)'s outcome (04-09):** it did not run. The stop rule applied, plan 04-09 is `halted`, and the simulation code is exactly 04-08's. The 8.0 ms budget, D-12 and every performance lever are untouched; the route is yours (below).
17. **Stress arrows and units (04-09):** the stress night uses slow tools-only towers (arrow speed **5 m/s**, shot every 0.15 s, range 30 m, damage 1; real hits through `PendingHits`). The plan's first arrow speed of 8 m/s left only 186 arrows in view in a 5 s trial, under the 200 bar, so only the tools-only speed was lowered. Stress grunts, footmen, towers and barracks carry 100000 health so the crowd stays full-sized; their speed, size and attacks are the shipped ones. The stress camera sits at 119.5 m so the whole 88 m by 80 m play area is in frame, which draws the crowd smaller than in play and trims fragment cost a little.
18. **D-14 reading (orchestrator decision, 04-04, 04-06, 04-10):** "regenerate the goldens once" was read as **same outcomes, not digests**: the pathing keeps the exact straight-line step wherever no intact wall exists, so the smoke and army digests were **never regenerated and never moved**; there is a **new walls golden** and one deliberate regeneration commit (`94fff12`: the bots' orders, the balance pins, full_idle's digest) with the before and after report beside it. You may ask for the literal reading (every digest regenerated).
19. **full_idle stays unpinned (04-10):** it has no golden, as since Phase 1, so CI cannot detect a later change of its absolute digest, only that two in-process runs agree. It moved in the regeneration commit from `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` (6941 ticks) to `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (6911 ticks) because the balanced bot's order changed; 04-BALANCE-REPORT.md records both.
20. **The bots' wall placement and the value bar (04-10):** where the bots buy walls (each road run after the first tower upgrade, the ring after the last first-tier House, the road upgrades late) is a measuring choice, not a game rule; the squad value bar (0.8) stays pinned on the no-walls twin and the with-walls ratio (0.888) is only reported. The walls fixture's night 2 stragglers arrive every 3.0 s rather than the sketched 1.5 s, because at 1.5 s one of eight walked round and five broke through; at 3.0 s all eight take the gap.
21. **The player-steered king is not routed (04-04, 04-06):** the player steers through the gaps and is pushed out of a standing segment by the same pure rule the bots use; only the bot king is routed. The gap in the test fixture is off the straight castle line (12 to 16 m along a 20 m run) on purpose, so every enemy has to detour.
22. **Squads round walls (04-10):** the army bot still loses 4 seeds with free walls; the suspected cause is squads following the king, who walks round the walls through the gaps, slowing the formation. It was not isolated by a separate run.
23. **Edge cases resolved by assumption (04-01, 04-04, 04-06):** drawing is capped but simulating never is, and an empty field commits empty batches; one break event per segment, overkill reports the points lost, targets that vanish are dropped silently, and the dawn restore is idempotent; a sealed enemy breaks in, one rebuild per changed step, and maps without walls are untouched.
24. **The stress night is a tools scene (04-11):** it is offered from the editor binary and is not in the exported build.
25. **Night readability under hundreds of units is not reworked here:** observed and recorded for Phase 8 (UI-05).

## Your decision

Sign off, or list what must land before Phase 5, through `/gsd-verify-work 4`.

**Decisions only you can make:**

1. **Performance route (PLAT-01 is NOT met).** The three options from 04-FRAME-REPORT.md:
   1. A **GDExtension (C++)** for the enemy and wall step, the STACK.md escape hatch; the only option that plausibly gives the 3.5 to 4 times the budget needs without changing rules.
   2. A **documented higher budget** for the stress night, with the number you choose (the measure is 37 ms p95 at the full 300-enemy load; the shipped nights top out at 40 enemies, but PLAT-01 is about the largest battle).
   3. A **targeted optimisation plan** for the wall logic and target choice (the 8 to 10 ms walls add, 7.5 ms of target choice, 3.7 ms of push-apart), including slicing enemy rescans or wall decisions across ticks. Slicing changes behaviour and needs its own golden decisions.
   You said you would decide the route after the gate from a profiling-driven gap plan; this is that open point.
2. **The wall-break rebuild hitch:** keep it accepted (11.7 ms mean, 13.2 ms max, one dropped frame on a break), or have count-based time slicing of the rebuild planned (a rule change: enemies take more ticks to see a breach).
3. **D-14:** confirm the "same outcomes, not digests" reading (assumption 18), or ask for the literal one (every digest regenerated, a new commit).
4. **Walls worth their gold:** the bots only afford walls in the last days; if mid-game walls matter, say whether a barricade should cost 1 (D-03 allows it), whether prices or the economy should move, and whether squads getting round walls (assumption 22) needs work.

**Also:** say whether any listed assumption should change, and list the feel and tuning fixes (readability of the walls, the tier looks, the gates, the squads) that must land before Phase 5. Anything you list becomes a gap plan through `/gsd-verify-work 4`.
