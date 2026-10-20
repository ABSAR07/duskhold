---
status: testing
phase: 04-crowd-scale-battles-walls
source: [04-01-SUMMARY.md, 04-02-SUMMARY.md, 04-03-SUMMARY.md, 04-04-SUMMARY.md, 04-05-SUMMARY.md, 04-06-SUMMARY.md, 04-07-SUMMARY.md, 04-08-SUMMARY.md, 04-09-SUMMARY.md, 04-10-SUMMARY.md, 04-11-SUMMARY.md, 04-VERIFICATION.md, 04-PLAYTEST-GATE.md]
started: 2026-10-16T21:07:26Z
updated: 2026-10-20T16:44:46Z
---

## Current Test

number: 14
name: The stress night feels smooth and the crowd reads, now on the native step (UAT test 5)
expected: |
  After bash tools/native_build.sh in Git Bash, run the stress night from the editor binary in PowerShell: & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path . res://tools/stress/stress_night.tscn -- --duration=30 (04-28 human-check 2; the step AND the arrows, enemies, bars, puffs and units are native now) Expected: 300 enemies, 50 footmen, 20 towers and the arrows are legible as a crowd and the frame time feels smooth, or the owner says where it still hurts. Claude measured about 256 fps at the median and a 5.37 ms p95 against the 8.0 ms budget (it was 142 fps and 10.95 ms before the view port) (Why human: Smoothness and crowd legibility are perceptual; the measurement is committed and is the closed gap, how it feels on the owner's machine is the owner's call)
awaiting: user response

## Tests

### 1. Walls worth their gold, readable by tier, and the barricade price (assumptions 5, 7, 20; decision 4)
requirement: BLDG-10
test: Play two or three full runs buying walls (Space or E held at the west, east, north and ring plots; barricade 2, stone 4, reinforced 6 gold). From the riding camera compare the three tiers and a hurt segment's bar. Say whether a barricade should cost 1 (D-03 allows it), whether prices or the economy should move, and whether the late-only bot purchase means mid-game walls matter. See 04-PLAYTEST-GATE.md 'What to judge' 1 and 'Your decision' 4
expected: Tiers I, II and III are tell-apart-able from the riding camera (primitive palisade, Castle Kit stone wall, stone with tower-base pillars), a damaged segment's bar reads, and a wall is worth 2, 4 or 6 gold against a House or a tower; or the owner names the price or look fix that must land before Phase 5
why_human: Worth and readability are by-eye and economic judgements. The code pins cost 2 / 4 / 6 and health 30 / 60 / 90 (data/buildings/wall.tres; test_wall_data_contract 7/7 re-run by me), but the screenshots show the segments thin and tier I and II alike, and the bots (about 15 to 22 gold a run) buy walls only in the last days
result: pass
note: "Verified by Claude 2026-10-16 from real-window captures (build/gate_shots/tier_west.png, tier_east.png, tier_north.png, hurt_bar.png): tier I is a thin brown palisade, tier II a pale uniform stone-block wall, tier III stone blocks with pillar blocks and the 'Max tier' label; all three tell apart from the riding camera. A segment hurt to 10 of 30 shows its red bar (small but readable). Worth: data only, the bots win 8 of 10 with and without walls and buy them only late; the barricade price (packet decision 4) stays the owner's call and is left at 2 / 4 / 6."

### 2. Gates funnel enemies into the towers
requirement: BLDG-10, ENMY-04
test: With a wall across a road and a tower behind it, watch whether the crowd bunches at the 4 m gap inside the tower's range or spreads and chews through (04-PLAYTEST-GATE.md 'What to judge' 2; the stress night shows 300 funnelling through one gate under 20 towers)
expected: The crowd bunches at the gap in front of the towers, which is the roadmap's 'funnel enemies into chokepoints'
why_human: Code and tests prove 300 of 300 cross a 4 m gate and that the walls replay detours and breaks (GATE_OK, test_wall_detour 12/12, test_wall_behaviour 8/8); whether that reads as a satisfying funnel into the defence is a feel judgement
result: pass
note: "Verified by Claude from screenshots/crowd_stress_night.png: 300 grunts pour through the 4 m gate in the gate wall between the two tower rows and mass round the king while both rows fire; GATE_OK 300/300 crossed, 0 stuck, twice locally and in CI run 38959046206."

### 3. Break-or-go-around looks smart, and a breach reads
requirement: ENMY-04
test: Watch a crowd meet a weak wall and a lone enemy meet a strong wall; watch a segment break, sink to rubble and rise again at dawn (04-PLAYTEST-GATE.md 'What to judge' 3; assumptions 8, 11, 12)
expected: A crowd at a weak segment breaks it and walks on, a strong wall sends enemies round, the choice looks intentional, and the breach (sink, rubble blocking nothing, free dawn rebuild) is readable
why_human: The rule is pinned (test_wall_decision 12/12, test_wall_behaviour 8/8 re-run by me); whether it looks intentional rather than twitchy, and whether the dark low-contrast rubble reads at night (walls_night_breach), is by eye
result: pass
note: "Verified by Claude: in build/gate_shots/night_0.png to night_3.png night 1's five grunts walk to the west run's gap and through it (no segment attacked, 12 of 12 intact), the sensible choice for a small group with a gap 2 m away; screenshots/walls_night_breach.png shows a broken segment as sunk rubble with grunts coming through; the crowd-breaks / lone-detours / sealed-breaks rule is pinned by test_wall_behaviour 8/8 and the walls golden (bfb05fc7, 1961 ticks). A crowd breaking a wall was not filmed in motion, only forced for the breach shot."

### 4. Squads and the king get round walls without fuss
requirement: ENMY-04, BLDG-10
test: Take an army through the gaps of a built run, ride the king through them, try to get stuck against a segment (04-PLAYTEST-GATE.md 'What to judge' 4, assumption 22). The army bot still loses 4 seeds with free walls; the suspected cause, squads following the king round the walls, is not isolated
expected: Squads route through the gaps on the goal-keyed flow field and the king is pushed out of standing segments without sticking; the army holds up, or the owner names the squad fix
why_human: Squads and the bot king route through gaps by tests (the squad path is covered in test_wall_detour and test_wall_system), but feel and the unexplained army-bot loss are judgements; the player-steered king is pushed out, not routed (assumption 21)
result: pass
note: "Verified by Claude: the barracks squad ordered to (-70, 16) behind the west run walked from (-22, 2) through the gap at about (-58, 20) to the target in 8 frames (build/gate_shots/detour_0.png to detour_7.png) with 0 unit ticks inside a wall, and the bot king reached the same point through walk_step; test_wall_detour 12/12."

### 5. The stress night feels smooth and the crowd reads
requirement: PLAT-01
test: Run the stress night in the editor binary (& .\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe --path . res://tools/stress/stress_night.tscn -- --duration=30) and watch 300 enemies, 50 footmen, 20 towers and the arrows (04-PLAYTEST-GATE.md 'What to judge' 5)
expected: On the owner's machine the crowd, arrows and towers are legible and the frame time is tolerable, or the owner says where it hurts; Claude measured about 43 fps at the median and a 37.04 ms p95
why_human: Smoothness and crowd legibility are perceptual; the measurement is in 04-FRAME-REPORT.md and is the failed gap, but how bad it feels on the real machine is the owner's call
result: issue
reported: "Claude, measured not felt: the stress night with 300 enemies, 50 units and 239 arrows in view runs at 43 fps median with a p95 frame time of 37.04 ms (04-FRAME-REPORT.md), so it is not smooth on the dev machine; the crowd itself reads as a crowd (screenshots/crowd_stress_night.png, one flat purple). Same root cause as the VERIFICATION.md gap for success criterion 3 (PLAT-01): one gap plan, not two."
severity: major

### 6. The drawn field and the two-column overlay read well
requirement: ENMY-04
test: Press F3 at night (stress night or a prototype night with walls): look at the flow-field arrows, blocked-cell crosses, enemy paths, magenta stuck enemies, and the Walls, Field and Crowd sections (screenshots overlay_field_gate, overlay_paths)
expected: The field and paths are readable, the panel does not hide what matters, and the sections answer 'where are they going and who is stuck'; this is the 'paths are visible in the debug overlay' clause of criterion 2
why_human: The wiring and numbers are tested (test_debug_overlay_crowd_sections 12/12 re-run by me; FlowFieldGizmo and EnemyPathGizmo added by CrowdOverlaySections and NightOverlaySections), legibility of arrows and layout is by eye (the overlay panel covers the right part of the wall by design)
result: issue
reported: "Claude, from screenshots/overlay_field_gate.png: the field arrows, the orange wall crosses, the queue at the gate and the Walls / Field / Crowd sections all read, but at 1280x720 the night banner '300 enemies left' runs under the overlay's right column and its last word is hidden."
severity: cosmetic

### 7. Nights still feel tense with walls available
requirement: BLDG-10, PLAT-01
test: Play the eight nights with walls on top (04-PLAYTEST-GATE.md 'What to judge' 6): no night count, cost or other data moved in Phase 4
expected: Walls do not make the nights trivially easy and are not bought too late to matter, or the owner says which number should move
why_human: The bots measure data only: balanced and army_balanced win 8 of 10 with and without walls and the Phase 3 per-seed rows reproduce byte-identically (md5 001778e71f38ecd0424f65e0ef9977f8), but tension is a feel judgement and the bots buy walls late
result: pass

### 8. D-14 reading: same outcomes, not digests
requirement: BLDG-10, ENMY-04
test: Read 04-PLAYTEST-GATE.md assumption 18 and 04-BALANCE-REPORT.md; confirm the reading or ask for the literal one (every digest regenerated in one new commit)
expected: The owner confirms that smoke (2599c7c2, 703 ticks) and army (f7a967ed, 1353 ticks) never moved, the new walls golden bfb05fc7 (1961 ticks) pins the wall rules, and full_idle (unpinned) moved once in 94fff12 from f417c7f5 (6941 ticks) to 4385f569 (6911 ticks); or asks for the literal regeneration
why_human: It is the owner's reading of their own D-14 and a decision to confirm; verified fact: I re-ran all four replays and they match
result: pass

### 9. The give-up rule of plan 04-07
requirement: ENMY-04
test: Watch crowds at a long weak wall near the break-even (assumption 13): an enemy that gives up on a segment should not return to it while a way round exists
expected: No grunt flips between a wall and the gap, and sealed enemies still break in; or the owner wants the rule changed
why_human: A rule the plan did not specify (it was added after a 15-tick hysteresis alone still let one grunt flip four times) and no test pins it directly; see behavior_unverified_items
result: pass

### 10. The wall-break rebuild hitch: keep it accepted or slice it
requirement: ENMY-04, PLAT-01
test: Break a wall in play (or read 04-FRAME-REPORT.md 'Wall-break rebuild') and notice whether the break drops a frame: 11.74 ms mean and 13.22 ms maximum per synchronous grid and castle-field rebuild on 5,494 cells, a 34.14 ms break-frame estimate against 16.7 ms
expected: The owner keeps the hitch accepted, or asks for count-based time slicing of the rebuild (a rule change: enemies take more ticks to see a breach) to be planned
why_human: The measurement is committed; whether one dropped frame at a break matters in play, and whether to change a rule to remove it, is the owner's decision (04-PLAYTEST-GATE.md 'Your decision' 2)
result: pass
note: \"Owner 2026-10-19: pass for now, revisit later (after the PLAT-01 route is chosen; count-based time slicing stays the named alternative)\"

### 11. The PLAT-01 performance route
requirement: PLAT-01
test: Choose, from 04-FRAME-REPORT.md 'Verdict and the open decision' and 04-PLAYTEST-GATE.md 'Your decision' 1: (1) a GDExtension (C++) for the enemy and wall step, (2) a documented higher budget with a number the owner chooses, or (3) a targeted GDScript optimisation plan for the wall logic, target choice and push-apart, including slicing
expected: A recorded route that becomes the profiling-driven gap plan for the gap above (the owner's decision of 2026-10-16 deferred this choice to /gsd-verify-work 4)
why_human: A project decision with cost and rule trade-offs, explicitly reserved to the owner
result: pass
note: \"Owner decision 2026-10-19: route (3), a GDExtension (C++) for the enemy and wall simulation step; the 8.0 ms p95 budget (D-12) stands. The gap plan for G-04-5 / VERIFICATION criterion 3 profiles the step first and moves the measured hot path (target choice, push-apart, wall checks) to native code behind the existing deterministic contract (goldens byte-identical, replays twice-equal); toolchain, CI and export changes are part of that plan.\"

### 12. GTX 970 transfer of the dev-machine budget (insufficient_spec, backstop tier)
requirement: PLAT-01
test: If a GTX 970-class machine is ever available, run bash tools/stress.sh --runs=3 --duration=20 on it; otherwise accept the written projection
expected: The budget transfers to at most 16.7 ms per frame under RESEARCH A1 (GPU about 3 to 4 times slower, GDScript step about 1.3 to 1.6 times slower); the committed projection is the opposite: 30 to 37 fps at the median and a 48 to 59 ms p95, because the step is CPU-bound
why_human: Plan 04-09 truth 5 is a backstop-tier truth: no GTX 970 exists here, presence and wiring never qualify, and no wired held-out test can stand in for hardware; I abstain (insufficient_spec). It is moot while the dev-machine budget itself is missed
result: blocked
blocked_by: physical-device
reason: "No GTX 970-class machine is available; the transfer stays the RESEARCH A1 scaling assumption (3 to 4x GPU, 1.3 to 1.6x CPU) recorded in 04-FRAME-REPORT.md."

### 13. The 25 assumptions made for the owner, and the Phase 5 fix list
requirement: BLDG-10, ENMY-04, PLAT-01
test: Read the 25 assumptions in 04-PLAYTEST-GATE.md (view caps, enemy look, baked unit meshes, wall numbers and geometry, targets behind walls dropped, pathing tunables, D-07 and D-09 numbers, stress-night settings, the bots' wall placement, edge cases); change any; list the readability, tier-look, gate and squad fixes that must land before Phase 5
expected: Each assumption confirmed or changed; anything listed becomes a gap plan through /gsd-verify-work 4. Note review IN-03: UnitViews.MAX_VIEWS is 256, below the 50-per-squad times several squads the simulation can field; assumption 1 states the cap
why_human: Nothing in the packet was confirmed with the owner
result: issue
reported: "Owner 2026-10-19: assumption 8 changes. A melee enemy whose target (a tower or other building, a unit, the king) is behind a wall must break through the wall to reach it, not drop the target and march on the castle; only some enemy types introduced in later phases go for the castle directly. Ranged enemies shooting over walls stays. All other 24 assumptions, the wall prices (2 / 4 / 6), the draw caps and the looks are signed off as they are; nothing else must land before Phase 5."
severity: major

### 14. The stress night feels smooth and the crowd reads, now on the native step (UAT test 5)
expected: After bash tools/native_build.sh in Git Bash, run the stress night from the editor binary in PowerShell: & ".\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe" --path . res://tools/stress/stress_night.tscn -- --duration=30 (04-28 human-check 2; the step AND the arrows, enemies, bars, puffs and units are native now) Expected: 300 enemies, 50 footmen, 20 towers and the arrows are legible as a crowd and the frame time feels smooth, or the owner says where it still hurts. Claude measured about 256 fps at the median and a 5.37 ms p95 against the 8.0 ms budget (it was 142 fps and 10.95 ms before the view port) (Why human: Smoothness and crowd legibility are perceptual; the measurement is committed and is the closed gap, how it feels on the owner's machine is the owner's call)
result: [pending]

### 15. The debug overlay sits below the night banner at 720p (UAT test 6, plan 04-13)
expected: Press F3 on a night (the stress night or a prototype night with walls) in a 1280x720-based window and read the night banner ('Night 8 of 8 - 300 enemies left'), the fast-forward label and the last overlay row; look at the re-captured shots overlay_on, overlay_paths and overlay_field_gate (re-taken by 04-28) and the CI Linux fallback-font overlay_field_gate.png Expected: The banner reads whole above the panel, nothing that matters is hidden, the last row is on screen, and overlay_paths shows a night. In a live window the panel's Phase, Enemies and Drawn rows follow the night (see the stale-panel note in warnings) (Why human: Layout adequacy and legibility are by eye; the y-only layout test (test_overlay_banner_layout 4/4 re-run by me, panel offset_top 104.0 in ui/overlay/debug_overlay.tscn line 19) pins the geometry but not the look)
result: [pending]

### 16. Melee enemies chew through a wall to reach a tower, unit or the king (UAT test 13, plan 04-12)
expected: Play a run on build/windows/Duskhold.exe with a wall bought in front of a tower (04-28 human-check 1) and watch a night: a grunt whose tower, unit or king is behind a standing wall should attack the segment in front of it until it breaks and then walk on to the target; ranged enemies still shoot over; a grunt in a gap mouth walks through Expected: The rule reads as the owner meant it on 2026-10-19 (melee breaks through to its target; only later enemy types go castle-first), or the owner names a change; the wall-break rebuild hitch stays accepted (UAT test 10, 11.61 ms mean per rebuild after this round) (Why human: The rule is pinned (test_wall_break_to_target, test_melee_breaks_to_target, test_los_targets, test_enemy_wall_flags_contract) and the four replays did not move, but whether it looks right in play is the owner's judgement)
result: [pending]

### 17. The owner's re-check packet and fresh export after the view-loop port
expected: Open the dated update at the top of 04-PLAYTEST-GATE.md ('Update after the gap plans 04-12 to 04-28 (2026-10-20T15:51Z)') and launch build/windows/Duskhold.exe (exported 2026-10-20 at HEAD a482e3f, with libduskhold_sim.windows.x86_64.dll and Duskhold.pck beside it; the executor's launch check exited 0 in about 4 s) Expected: The build launches and plays a full run, the packet names UAT tests 5, 6 and 13 and the native build step, and the numbers it quotes (p95 5.37 ms, 256 fps) match 04-FRAME-REPORT.md (Why human: It is a hand-off to the owner; the packet and the export exist (read and listed by me) but the owner's own launch on the owner's machine is the check, and the export launch itself was not re-run by me)
result: [pending]

### 18. GTX 970 transfer of the dev-machine budget (insufficient_spec, backstop tier; UAT test 12 blocked by hardware)
expected: If a GTX 970-class machine is ever available, run bash tools/stress.sh --runs=3 --duration=20 on it; otherwise accept the written projection Expected: The RESEARCH A1 projection recorded in 04-FRAME-REPORT.md after the view-layer port: p50 about 4.8 to 5.9 ms and p95 about 7.0 to 8.6 ms on a GTX 970-class machine (the pre-port projections were 14.2 to 17.5 ms and 48 to 59 ms at the p95); PLAT-01 is re-verified on real campaign battles in Phase 13 whatever this reads (Why human: A backstop-tier truth: no GTX 970 exists here, presence and wiring never qualify, and no wired held-out test can stand in for hardware; I abstain (insufficient_spec))
result: [pending]

### 19. The view-layer port draws the night as before (by-eye screenshot comparison)
expected: Compare the arrows, the enemy crowd with its hit flashes and hurt-only bars, the death puffs and the friendly units and their bars in a night on the exported build (or the crowd_stress_night and walls_night_breach captures) with what the owner saw at UAT tests 5 and 13; the coverage items with human_judgment true in the SUMMARYs of 04-25, 04-26 and 04-27 record the executors' own comparison Expected: Nothing is missing, doubled, recoloured, mis-sized or popping; the arrows arc from the tower to the target as before; flashes last 0.15 s; puffs fade over 0.6 s; bars show only on hurt enemies and units (Why human: The view fills are pinned byte-for-byte on the batch mirrors (test_projectile_fill_pins 4/4, test_enemy_fill_pins 5/5, test_unit_fill_pins 4/4, SHA-256 over the instance buffers, computed on the GDScript before any native code, never edited) and the goldens did not move, so any difference could only be in how the buffer is drawn, which only an eye can judge. I read crowd_stress_night.png and overlay_field_gate.png and saw the purple crowd, pink flashes, red hurt-only bars, yellow arrows and blue units as described)
result: [pending]

## Summary

total: 19
passed: 9
issues: 3
pending: 6
skipped: 0
blocked: 1

## Gaps

- gap_id: G-04-5
  truth: "On the owner's machine the crowd, arrows and towers are legible and the frame time is tolerable, or the owner says where it hurts; Claude measured about 43 fps at the median and a 37.04 ms p95"
  status: failed
  reason: "User reported: Claude, measured not felt: the stress night with 300 enemies, 50 units and 239 arrows in view runs at 43 fps median with a p95 frame time of 37.04 ms (04-FRAME-REPORT.md), so it is not smooth on the dev machine; the crowd itself reads as a crowd (screenshots/crowd_stress_night.png, one flat purple). Same root cause as the VERIFICATION.md gap for success criterion 3 (PLAT-01): one gap plan, not two."
  severity: major
  test: 5
  root_cause: "No single hotspot: the simulation step is GDScript call and branch overhead spread over per-enemy per-tick work. Headless at the PLAT-01 load the step is 22 to 24 ms (bench shape 20 to 22): EnemySystem.step 16 to 17 ms (_choose_target 7.9, of which _target_walls_in_the_way re-runs the detour-versus-break arithmetic for every wall-aggroed enemy every tick and WallSolids.first_blocking costs 145 to 272 us per call because segments_near walks every 4 m bucket of the line's bounding square; _separate 4.1 superlinear; _advance_and_strike 2.3; _push_out_of_walls 1.7) plus 7 to 7.5 ms outside it (squads 3.0, towers 2.4 with TargetQuery.nearest_enemy at 425 us per query since EnemyIndex.within falls back to all 300 ids, stuck tracker 1.5 with a Dictionary allocation per enemy per tick). Both parts exceed on their own the 5 to 6 ms step an 8 ms p95 frame allows; packed storage (lever a) is bounded at 0.75 ms"
  artifacts:
    - path: "simulation/night/enemy_system.gd"
      issue: "the whole enemy phase (:149-178, :253-258, :298-356, :380-385, :486-490, :602-678) is 16 to 17 ms of GDScript at 300 enemies; Dictionary-of-Record storage, 18 of 20 public methods, 710 of 1000 lines"
    - path: "simulation/walls/wall_solids.gd"
      issue: "first_blocking (:52-70) via WallSystem.segments_near (wall_system.gd:129-145) costs by the square of the line length"
    - path: "simulation/night/target_query.gd"
      issue: "nearest_enemy (:12-23) loops is_alive + position_of over all 300 ids at the stress reach; towers.step 4 to 6 ms on two ticks in five"
    - path: "simulation/night/stuck_tracker.gd"
      issue: "_observe (:94) allocates a Dictionary per enemy per tick through enemies.target_of"
    - path: "simulation/night/night_sim.gd"
      issue: "fixed phase order the native step must keep (enemies, squads, towers, hits, king, stuck, cleanup)"
  missing:
    - "Native (C++ GDExtension, godot-cpp pinned to a commit, precision=single) enemy store and step: boundary A of the diagnosis, the whole EnemySystem phase behind the existing 18-method facade plus native nearest-enemy / living_within queries and shared Separation / WallSolids helpers; SimEvents, PendingHits, NightSim order, squads' orders, towers' fire control and all GDScript API stay"
    - "Bit-exact contract: Vector2 float32 and GDScript-scalar double with the same narrowing points and operation order, ascending-id iteration, no FMA (/fp:precise, no /arch:AVX2; -ffp-contract=off on GCC), goldens smoke 2599c7c2 / army f7a967ed / walls bfb05fc7 and full_idle 4385f569 byte-identical, GATE_OK 300/300, a test_sim_rules_guard equivalent for the C++ sources"
    - "Toolchain: MSVC 19.51 (VS Build Tools 2026) with bundled CMake 4.2.3 and Ninja is the only local compiler (no gcc, clang or SCons); CI on ubuntu-latest needs a Linux .so for the test job and a Windows .dll at export time (cross-compile, a windows job artifact, or a committed binary under the LFS rules; prepush_check caps non-LFS blobs at 5 MB); layout res://addons/<name>/<name>.gdextension + bin/; .gitignore and export_presets exclude filters"
    - "A tracer that measures the native gain first (for example a native Separation.displacements_bucketed) before porting the wall logic; judge by medians of several runs (step means vary 22.7 to 31.8 ms on this laptop)"
    - "Land G-04-7's target-rule change before the port so the enemy step is ported once"
  debug_session: .planning/debug/stress-night-step-over-budget.md
  note: "Same root cause as 04-VERIFICATION.md's gap for ROADMAP success criterion 3 (PLAT-01); plan it once. Owner route 2026-10-19 (test 11): GDExtension (C++) for the enemy and wall step, profiling first"
- gap_id: G-04-6
  truth: "The field and paths are readable, the panel does not hide what matters, and the sections answer 'where are they going and who is stuck'; this is the 'paths are visible in the debug overlay' clause of criterion 2"
  status: failed
  reason: "User reported: Claude, from screenshots/overlay_field_gate.png: the field arrows, the orange wall crosses, the queue at the gate and the Walls / Field / Crowd sections all read, but at 1280x720 the night banner '300 enemies left' runs under the overlay's right column and its last word is hidden."
  severity: cosmetic
  test: 6
  root_cause: "The overlay panel (ui/overlay/debug_overlay.tscn :14-23) is anchored top-right at offset_top 12 with grow_horizontal 0 and no width cap; plan 04-08's second column (HBoxContainer separation 16, :25-28) widened it from about 185 to 225 px to 421 px, so its left edge at x 847 crosses the centred 36 px night banner (hud.tscn :131-145; 'Night 1 of 1 — 300 enemies left' has its right edge at x 909) by 62 px over 50 shared rows (panel y 12-609, banner y 45-95); the overlay CanvasLayer is layer 100 so it draws over the HUD. Because project.godot stretches canvas_items at a 1280x720 base with aspect expand, every 16:9 window has the same 62 px overlap; the shipped map overlaps by about 9 px with any two-digit count; FastForwardLabel (hud.tscn :164-181) has sat under the panel since Phase 1. No test or screenshot check pins the banner's horizontal extent or the panel rect"
  artifacts:
    - path: "ui/overlay/debug_overlay.tscn"
      issue: "Panel offset_top 12, grows left without a width cap; two columns since 04-08"
    - path: "ui/overlay/debug_overlay.gd"
      issue: "column split rule (:156-168) decides the widths"
    - path: "ui/hud/hud.tscn"
      issue: "PhaseBannerBox y 40-100 centred; FastForwardLabel at (1020, 60) under the panel"
    - path: "tests/e2e/test_hud_contract.gd"
      issue: "pins banner font sizes and y positions but no horizontal extent; DebugOverlay exempt"
  missing:
    - "Move the panel below the banner box (offset_top about 104, offset_bottom 144) and buy the lost headroom with a smaller line spacing or font so a full stress-night row set still ends above y 720; the player-facing banner stays at y 40-100, 36 px (03-UI-SPEC D-21)"
    - "A GUT e2e regression test in a 1280x720 SubViewport (test_hud_contract's _hud_in_base_viewport pattern): with 'Night 8 of 8 — 300 enemies left' and a full overlay, the panel top is at or below PhaseBannerBox's bottom, it does not intersect FastForwardLabel, and its bottom is at or above 720; assert on y only so the CI font substitution for Consolas does not matter"
    - "Re-capture the three overlay screenshots (overlay_on, overlay_paths, overlay_field_gate); optionally wait one 0.25 s overlay refresh before capturing overlay_paths"
  debug_session: .planning/debug/overlay-hides-night-banner-720p.md
- gap_id: G-04-7
  truth: "Each assumption confirmed or changed; anything listed becomes a gap plan through /gsd-verify-work 4. Note review IN-03: UnitViews.MAX_VIEWS is 256, below the 50-per-squad times several squads the simulation can field; assumption 1 states the cap"
  status: failed
  reason: "User reported: Owner 2026-10-19: assumption 8 changes. A melee enemy whose target (a tower or other building, a unit, the king) is behind a wall must break through the wall to reach it, not drop the target and march on the castle; only some enemy types introduced in later phases go for the castle directly. Ranged enemies shooting over walls stays. All other 24 assumptions, the wall prices (2 / 4 / 6), the draw caps and the looks are signed off as they are; nothing else must land before Phase 5."
  severity: major
  test: 13
  root_cause: "Not a defect: plan 04-06 built RESEARCH Open Question 3 as three line-of-sight gates in simulation/night/enemy_system.gd that only melee enemies fail (the king pull needs _can_see at :274-281; _pick_nearest_structure uses StructureIndex.nearest_visible at :498-517 whenever a wall stands; a held target failing _target_in_sight is dropped on its rescan at :266-269 and :450-476), after which the enemy falls through to _aim_at_walls (:333-356), the castle-line rule. Separately the 04-07 KIND_WALL bookkeeping (_take_wall :404-411, _keeps_breaking / _breaking_is_faster / _wall_ticks :363-385, wall_given_up :310 and :365) weighs breaking only against the castle detour and keeps no memory of a target behind the wall, so removing the gates alone would make a grunt take the wall, drop it at the next 15-tick rescan for the castle detour, and re-take it. Ranged enemies (def.projectile_speed > 0) shoot over walls through _shoots_over (:460-463) and that rule stays. A read-only probe replaying the goldens counted 0 melee triggers of the gates in the walls golden, full_idle, the fixtures and 9 of the 10 with-walls bot seeds; only balanced seed 2 (night 8, a grunt in the north gap mouth whose line to tower_3 and to the king grazes the gap-edge segment within 0.9 m) would change"
  artifacts:
    - path: "simulation/night/enemy_system.gd"
      issue: "drop gates at :266-269, :274-281, :450-476, :498-517; castle-only wall bookkeeping at :298-326 and :363-411; Record fields (:682-710) keep no memory of a target behind a wall"
    - path: "simulation/night/structure_index.gd"
      issue: "nearest_visible (:76-79) and _seen (:107-112) filter structures by line of sight"
    - path: "simulation/nav/wall_decision.gd"
      issue: "cadence 15 / span 2 / hysteresis 15 / notice 12 from data/tuning/nav_tuning.tres :14-17; add_attacker (:103) counts the crowd per segment"
    - path: "simulation/defs/enemy_def.gd"
      issue: "no per-type flag for castle-first behaviour beside ignores_walls (:30)"
    - path: "tests/unit/test_los_targets.gd"
      issue: ":82-89, :100-113 (and :133-139) assert the old drop rule"
  missing:
    - "Default melee (projectile_speed 0, flag unset): choose targets as in Phase 3 (nearest(), the king pull without _can_see, no rescan drop); on choosing or rescanning, take pathing.first_blocking(pos, goal, radius) as a KIND_WALL target held for that target (a Record memory of kind + id and a held-for-target marker), released only when the segment breaks (resume the target if still valid), the target becomes invalid (dead, fallen, beyond leash) or the line no longer crosses the segment; skip _keeps_breaking and wall_given_up for held-for-target walls; _publish_wall_times counts them into the crowd automatically"
    - "Keep ranged on today's gates; add an EnemyDef flag (castle_first / drops_blocked_targets, default false, no shipped .tres sets it, a contract test like test_stress_map_data.gd:103) that routes a type through the old 04-06 gates for the Phase 6 roster"
    - "Decide two sub-rules in the plan: whether visible targets still win over nearer blocked ones, and how a grunt standing in a gap mouth avoids chewing the gap-edge segment (test the line with the centre, radius 0, and let push_out slide it round the end, or detour to the target through a goal field)"
    - "Move test_los_targets to the new rule (old assertions onto a flagged def copy); keep smoke, army, walls and full_idle byte-identical (0 triggers measured; every wall branch is behind _walls_are_solid()); keep GATE_OK 300/300 with wall_hits 0 (the gate map has only the castle as a target); re-measure test_balance_acceptance (only balanced seed 2 can move); update the docs at enemy_system.gd :243-252 and :447-449, structure_index.gd :71-75, PLAYTEST-GATE assumption 8, RESEARCH OQ3/A5 and 04-07 flagged assumption 3"
  debug_session: .planning/debug/melee-targets-behind-walls.md
  note: "Rule change to 04-06's target rule (RESEARCH Open Question 3, packet assumption 8): melee enemies break the blocking wall to reach a blocked target; the walls golden and test_wall_behaviour pin the old rule and will move (a D-14 regeneration with its report)"

> Round 2 (2026-10-20T16:44:46Z, after gap round 2, plans 04-24 to 04-28): tests 14 to 19 are the six owner items of 04-VERIFICATION.md verified 2026-10-20T16:41:25Z (status human_needed, 0 gaps, 4 of 4 criteria, PLAT-01 met at median-run p95 5.37 ms against 8.0). Tests 5, 6 and 13 stay as round-1 history and are superseded in substance by 14, 15 and 16; the gap rows G-04-5, G-04-6 and G-04-7 are reconciled at /gsd-verify-work 4.
