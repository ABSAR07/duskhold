---
status: testing
phase: 04-crowd-scale-battles-walls
source: [04-01-SUMMARY.md, 04-02-SUMMARY.md, 04-03-SUMMARY.md, 04-04-SUMMARY.md, 04-05-SUMMARY.md, 04-06-SUMMARY.md, 04-07-SUMMARY.md, 04-08-SUMMARY.md, 04-09-SUMMARY.md, 04-10-SUMMARY.md, 04-11-SUMMARY.md, 04-VERIFICATION.md, 04-PLAYTEST-GATE.md]
started: 2026-10-16T21:07:26Z
updated: 2026-10-16T21:07:26Z
---

## Current Test

number: 1
name: Walls worth their gold, readable by tier, and the barricade price (assumptions 5, 7, 20; decision 4)
expected: |
  Tiers I, II and III are tell-apart-able from the riding camera (primitive palisade, Castle Kit stone wall, stone with tower-base pillars), a damaged segment's bar reads, and a wall is worth 2, 4 or 6 gold against a House or a tower; or the owner names the price or look fix that must land before Phase 5
awaiting: user response

## Tests

### 1. Walls worth their gold, readable by tier, and the barricade price (assumptions 5, 7, 20; decision 4)
requirement: BLDG-10
test: Play two or three full runs buying walls (Space or E held at the west, east, north and ring plots; barricade 2, stone 4, reinforced 6 gold). From the riding camera compare the three tiers and a hurt segment's bar. Say whether a barricade should cost 1 (D-03 allows it), whether prices or the economy should move, and whether the late-only bot purchase means mid-game walls matter. See 04-PLAYTEST-GATE.md 'What to judge' 1 and 'Your decision' 4
expected: Tiers I, II and III are tell-apart-able from the riding camera (primitive palisade, Castle Kit stone wall, stone with tower-base pillars), a damaged segment's bar reads, and a wall is worth 2, 4 or 6 gold against a House or a tower; or the owner names the price or look fix that must land before Phase 5
why_human: Worth and readability are by-eye and economic judgements. The code pins cost 2 / 4 / 6 and health 30 / 60 / 90 (data/buildings/wall.tres; test_wall_data_contract 7/7 re-run by me), but the screenshots show the segments thin and tier I and II alike, and the bots (about 15 to 22 gold a run) buy walls only in the last days
result: [pending]

### 2. Gates funnel enemies into the towers
requirement: BLDG-10, ENMY-04
test: With a wall across a road and a tower behind it, watch whether the crowd bunches at the 4 m gap inside the tower's range or spreads and chews through (04-PLAYTEST-GATE.md 'What to judge' 2; the stress night shows 300 funnelling through one gate under 20 towers)
expected: The crowd bunches at the gap in front of the towers, which is the roadmap's 'funnel enemies into chokepoints'
why_human: Code and tests prove 300 of 300 cross a 4 m gate and that the walls replay detours and breaks (GATE_OK, test_wall_detour 12/12, test_wall_behaviour 8/8); whether that reads as a satisfying funnel into the defence is a feel judgement
result: [pending]

### 3. Break-or-go-around looks smart, and a breach reads
requirement: ENMY-04
test: Watch a crowd meet a weak wall and a lone enemy meet a strong wall; watch a segment break, sink to rubble and rise again at dawn (04-PLAYTEST-GATE.md 'What to judge' 3; assumptions 8, 11, 12)
expected: A crowd at a weak segment breaks it and walks on, a strong wall sends enemies round, the choice looks intentional, and the breach (sink, rubble blocking nothing, free dawn rebuild) is readable
why_human: The rule is pinned (test_wall_decision 12/12, test_wall_behaviour 8/8 re-run by me); whether it looks intentional rather than twitchy, and whether the dark low-contrast rubble reads at night (walls_night_breach), is by eye
result: [pending]

### 4. Squads and the king get round walls without fuss
requirement: ENMY-04, BLDG-10
test: Take an army through the gaps of a built run, ride the king through them, try to get stuck against a segment (04-PLAYTEST-GATE.md 'What to judge' 4, assumption 22). The army bot still loses 4 seeds with free walls; the suspected cause, squads following the king round the walls, is not isolated
expected: Squads route through the gaps on the goal-keyed flow field and the king is pushed out of standing segments without sticking; the army holds up, or the owner names the squad fix
why_human: Squads and the bot king route through gaps by tests (the squad path is covered in test_wall_detour and test_wall_system), but feel and the unexplained army-bot loss are judgements; the player-steered king is pushed out, not routed (assumption 21)
result: [pending]

### 5. The stress night feels smooth and the crowd reads
requirement: PLAT-01
test: Run the stress night in the editor binary (& .\.tools\godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe --path . res://tools/stress/stress_night.tscn -- --duration=30) and watch 300 enemies, 50 footmen, 20 towers and the arrows (04-PLAYTEST-GATE.md 'What to judge' 5)
expected: On the owner's machine the crowd, arrows and towers are legible and the frame time is tolerable, or the owner says where it hurts; Claude measured about 43 fps at the median and a 37.04 ms p95
why_human: Smoothness and crowd legibility are perceptual; the measurement is in 04-FRAME-REPORT.md and is the failed gap, but how bad it feels on the real machine is the owner's call
result: [pending]

### 6. The drawn field and the two-column overlay read well
requirement: ENMY-04
test: Press F3 at night (stress night or a prototype night with walls): look at the flow-field arrows, blocked-cell crosses, enemy paths, magenta stuck enemies, and the Walls, Field and Crowd sections (screenshots overlay_field_gate, overlay_paths)
expected: The field and paths are readable, the panel does not hide what matters, and the sections answer 'where are they going and who is stuck'; this is the 'paths are visible in the debug overlay' clause of criterion 2
why_human: The wiring and numbers are tested (test_debug_overlay_crowd_sections 12/12 re-run by me; FlowFieldGizmo and EnemyPathGizmo added by CrowdOverlaySections and NightOverlaySections), legibility of arrows and layout is by eye (the overlay panel covers the right part of the wall by design)
result: [pending]

### 7. Nights still feel tense with walls available
requirement: BLDG-10, PLAT-01
test: Play the eight nights with walls on top (04-PLAYTEST-GATE.md 'What to judge' 6): no night count, cost or other data moved in Phase 4
expected: Walls do not make the nights trivially easy and are not bought too late to matter, or the owner says which number should move
why_human: The bots measure data only: balanced and army_balanced win 8 of 10 with and without walls and the Phase 3 per-seed rows reproduce byte-identically (md5 001778e71f38ecd0424f65e0ef9977f8), but tension is a feel judgement and the bots buy walls late
result: [pending]

### 8. D-14 reading: same outcomes, not digests
requirement: BLDG-10, ENMY-04
test: Read 04-PLAYTEST-GATE.md assumption 18 and 04-BALANCE-REPORT.md; confirm the reading or ask for the literal one (every digest regenerated in one new commit)
expected: The owner confirms that smoke (2599c7c2, 703 ticks) and army (f7a967ed, 1353 ticks) never moved, the new walls golden bfb05fc7 (1961 ticks) pins the wall rules, and full_idle (unpinned) moved once in 94fff12 from f417c7f5 (6941 ticks) to 4385f569 (6911 ticks); or asks for the literal regeneration
why_human: It is the owner's reading of their own D-14 and a decision to confirm; verified fact: I re-ran all four replays and they match
result: [pending]

### 9. The give-up rule of plan 04-07
requirement: ENMY-04
test: Watch crowds at a long weak wall near the break-even (assumption 13): an enemy that gives up on a segment should not return to it while a way round exists
expected: No grunt flips between a wall and the gap, and sealed enemies still break in; or the owner wants the rule changed
why_human: A rule the plan did not specify (it was added after a 15-tick hysteresis alone still let one grunt flip four times) and no test pins it directly; see behavior_unverified_items
result: [pending]

### 10. The wall-break rebuild hitch: keep it accepted or slice it
requirement: ENMY-04, PLAT-01
test: Break a wall in play (or read 04-FRAME-REPORT.md 'Wall-break rebuild') and notice whether the break drops a frame: 11.74 ms mean and 13.22 ms maximum per synchronous grid and castle-field rebuild on 5,494 cells, a 34.14 ms break-frame estimate against 16.7 ms
expected: The owner keeps the hitch accepted, or asks for count-based time slicing of the rebuild (a rule change: enemies take more ticks to see a breach) to be planned
why_human: The measurement is committed; whether one dropped frame at a break matters in play, and whether to change a rule to remove it, is the owner's decision (04-PLAYTEST-GATE.md 'Your decision' 2)
result: [pending]

### 11. The PLAT-01 performance route
requirement: PLAT-01
test: Choose, from 04-FRAME-REPORT.md 'Verdict and the open decision' and 04-PLAYTEST-GATE.md 'Your decision' 1: (1) a GDExtension (C++) for the enemy and wall step, (2) a documented higher budget with a number the owner chooses, or (3) a targeted GDScript optimisation plan for the wall logic, target choice and push-apart, including slicing
expected: A recorded route that becomes the profiling-driven gap plan for the gap above (the owner's decision of 2026-10-16 deferred this choice to /gsd-verify-work 4)
why_human: A project decision with cost and rule trade-offs, explicitly reserved to the owner
result: [pending]

### 12. GTX 970 transfer of the dev-machine budget (insufficient_spec, backstop tier)
requirement: PLAT-01
test: If a GTX 970-class machine is ever available, run bash tools/stress.sh --runs=3 --duration=20 on it; otherwise accept the written projection
expected: The budget transfers to at most 16.7 ms per frame under RESEARCH A1 (GPU about 3 to 4 times slower, GDScript step about 1.3 to 1.6 times slower); the committed projection is the opposite: 30 to 37 fps at the median and a 48 to 59 ms p95, because the step is CPU-bound
why_human: Plan 04-09 truth 5 is a backstop-tier truth: no GTX 970 exists here, presence and wiring never qualify, and no wired held-out test can stand in for hardware; I abstain (insufficient_spec). It is moot while the dev-machine budget itself is missed
result: [pending]

### 13. The 25 assumptions made for the owner, and the Phase 5 fix list
requirement: BLDG-10, ENMY-04, PLAT-01
test: Read the 25 assumptions in 04-PLAYTEST-GATE.md (view caps, enemy look, baked unit meshes, wall numbers and geometry, targets behind walls dropped, pathing tunables, D-07 and D-09 numbers, stress-night settings, the bots' wall placement, edge cases); change any; list the readability, tier-look, gate and squad fixes that must land before Phase 5
expected: Each assumption confirmed or changed; anything listed becomes a gap plan through /gsd-verify-work 4. Note review IN-03: UnitViews.MAX_VIEWS is 256, below the 50-per-squad times several squads the simulation can field; assumption 1 states the cap
why_human: Nothing in the packet was confirmed with the owner
result: [pending]

## Summary

total: 13
passed: 0
issues: 0
pending: 13
skipped: 0
blocked: 0

## Gaps
