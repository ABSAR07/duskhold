---
status: partial
phase: 03-king-combat-troops
source: [03-VERIFICATION.md]
started: 2026-10-12T09:35:00Z
updated: 2026-10-14T06:36:09Z
---

## Current Test

number: 12
name: E6: longest toast inside x 384..896
expected: |
  Select a squad, ride to the edge of the ground and right-click off the map to raise the "Can't go there" toast. Accept a 526 px toast (x 377..903, one line, entirely below the clear centre), or have the copy shortened, or amend the UI-SPEC bound (03-12 D4; unmet-truth entry in .planning/WINDOWS.md).
awaiting: user response

## Tests

### 1. Guard and commit readability at night
requirement: UNIT-04
expected: Build a Barracks and an Archery Range, play a night and watch the squads. Footmen hold the ground in front of the plot, pick one grunt and stay on it, then walk back to the post; archers stay back and shoot. Units read as footmen and archers, guard rather than wander, commit to one target instead of flip-flopping and return to their formation after the fight (03-01 D8; test_squad_guard 14/14 pins the rules).
result: pass
note: "Self-verified 2026-10-13 with a scripted real-window run (scratch uat_probe.gd p1): both squads at post through nights 1 and 2, then holding on the west road for night 3. Feel of the read is left to the owner gate (test 15)."
evidence: "Nights 1-2 at post: footmen 19 and 31 engagements, 0 target switches while the target lived, 1 retarget after a kill, farthest 4.8 m from the post (guard 7 m); archers 16 engagements on night 2, fired at 5.5-8.5 m (range 8.5), never closer than 5.5 m; every unit back on its formation slot (0.00 m error) 5 s after each night. Night 3 on the road: 32 and 34 engagements, 0 flips, archers fired at 3.2-8.5 m, footmen at 0.8-1.7 m. Screenshots p1_fight_a..c show swords and bows apart at game-camera distance."

### 2. Barracks and Archery Range models and replacement pace
requirement: UNIT-07
expected: Build each military plot to tier 3 and look at the models; lose units at night and watch the 10 / 7 / 4 s trickle at the building, then the full restore at dawn. Each tier reads bigger than the last next to the House and Tower models, the trickle pace feels right for the gold spent, and dawn visibly makes every squad whole (03-02 D8).
result: pass
note: "Tier models and trickle measured in a real window (p2, p2b). The Archery Range tier 1 piece shares the House footprint and height (2.2 x 2.1 x 3.8 m) and is told apart by its cyan roof; both military buildings are kit-piece placeholders. Whether the pace feels right for the gold is the owner's call at test 15."
evidence: "Model bounds: Barracks 2.0x1.8x4.6 m (t1), 3.6x3.6x4.6 (t2), 3.6x3.6x6.4 (t3); Archery 2.2x2.1x3.8 (t1), 4.2x2.1x3.8 (t2), 4.2x2.1x5.8 (t3); House 2.2x2.1x3.8; Tower 2.0x1.8x6.1. First replacement countdown after a death: 9.97 s (tier 1), 6.97 s (tier 2), 3.97 s (tier 3). Dawn restored 8/8, 14/14 and 4/4 (squad_restored). Screenshots p2_*_t1..t3."

### 3. HUD in a real window at 1920x1080 and 16:10
requirement: UI-01
expected: Open the exported build at 1920x1080 and at a 16:10 resolution, play a day and a night, and compare with screenshots hud_day_squads_1080p, hud_night_squad_down_16x10 and hud_day_counter_long. The HUD scales uniformly, "Night N of 8" reads over the 3D scene, nothing overlaps and the middle of the screen stays clear (03-03 D6).
result: pass
evidence: "Real windows at 1920x1080 and 1600x1000 (p3): canvas scale 1.5 and 1.25 uniform, visible rect 1280x720 and 1280x800 (expand); 0 overlaps between drawing HUD controls and 0 controls in the clear centre by day and at night 7 (squad down, king 36/50); banner 'Night 7 of 8 - 9 enemies left' centred over the scene at both sizes. Screenshots p3_day_* and p3_night_*."

### 4. Slam and regeneration feel
requirement: KING-04, KING-05
expected: Press Q (pad X) amid enemies and by day; watch the ring, the sword icon fill and the ready flash; take a hit, stop being hit and watch health return. The 4 m / 4 damage / 9 s slam feels useful, the ring and flash read, and regeneration (1 s delay, 10 percent of max per second) feels Thronefall-like and not too generous. The floating bar over the king and the bottom-left widget agree after a heal (open review finding WR-01: today the floating bar does not follow regeneration).
result: issue
reported: "The floating bar over the king does not follow regeneration: after a heal the simulation read 49/50 and the HUD widget 49 / 50 (0.981), but the 3D bar still showed 0.960 (the last damaged value). It only updates on king_damaged, downed, respawned and the dawn payout, never on king_healed (review WR-01). Everything else measured: slam ring on Q, 269 ticks (9 s) cooldown, 2 hits on the 2 enemies within 4 m, the plate shakes on a cooling press, regeneration starts 36 ticks after the last hit (30 delay + 6) and adds 1 point every 6 ticks (5/s)."
severity: minor
evidence: "p4 probe lines: day_slam ticks_left=269 ring=true; night_slam hits=[2] enemies_within_4m_at_slam=[2]; regen first_gain_after_ticks=36, heals t2484:+1->49, t2490:+1->50; bars sim_ratio=0.980 floating_bar_ratio=0.960 widget_bar=0.981. Screenshots p4_day_slam, p4_night_slam, p4_regen_bars."

### 5. Squad slot look at 1280x720
requirement: UI-01
expected: Compare the bottom-centre squad strip with 03-UI-SPEC.md in play: icon weight, alive / max, stance glyph at 20 px, replacement fill and the dawn border flash. Slots read at a glance and the post, hold, follow, patrol and attack-move glyphs are tellable apart at slot size (03-UI-REVIEW notes post, hold and patrol look alike at that size; 03-05 D7).
result: pass
note: "Measured against 03-UI-SPEC (p5): slot 136x72 at (500,544), icon 32 px, alive label '4 / 4', stance glyph 20x20, replacement fill 120x4 at the slot bottom; all five stance shapes drawn (square_on_base, chevrons, square_with_bar, double_arrow, spike_arrow) and distinct in the 3x crops; zero-alive slot shows '0 / 4' in red with the icon dimmed and the fill at 0.87; the dawn border flash fired once on restore. At 1x the post, hold and patrol glyphs are small (UI-REVIEW note); the owner can override at test 15."
evidence: "Crops p5_crop_post/follow/hold/patrol/attack_move/zero_alive/dawn."

### 6. Selection, follow, hold and rally feel
requirement: UNIT-05, UNIT-06, UNIT-09
expected: Click a squad, double-click a unit (every squad of that type), Tab, F2; press F, H and R; watch the rings and the slot highlight; end a night and check a held or following squad keeps its stance the next day. Selection and the three verbs respond at once and read clearly; hold-at-centroid and rally-ignores-enemies match what you meant; stances persist across dawn (03-06 D9; test_squad_stance_persistence 3/3).
result: pass
evidence: "Real input events (p6): click on a footman selected barracks_1 (4 rings, slot highlighted), hover over an archer drew 4 hover rings, double-click selected the archery squad, Tab cycled barracks -> archery, F2 selected both (8 rings); F set follow on both and the footmen stood 0.12 m from the king after 4 s; H froze the anchor exactly at the centroid (0.00 m); R walked the squad to the king (0.00 m after 5 s) and held; hold and follow survived night 1 into day 2; Escape cleared the selection and the rings. Screenshots p6_both_selected, p6_following."

### 7. Right-click move, attack-move on A, and the king standing still while a squad is selected
requirement: UNIT-10, INPT-01
expected: Select a squad and hold A: the king must not move; then left-click ground to attack-move. Press Escape once to cancel an armed command and again to clear the selection. With nothing selected hold A and the king rides left. Right-click ground to move. The D-15 amendment you decided at the 03-07 checkpoint (keep A, movement goes to the selection, the king is the implicit selection, Escape clears) feels right in play, and the pings and the armed line read (03-07 D8; test_selection_steering and test_king_selection_steering pin the rule).
result: pass
evidence: "p7, real key and mouse events: with barracks_1 selected, A held 1 s moved the king 0.000 m and armed attack-move with the line 'Click a point to attack-move'; the left click issued attack_move to (-9,5) with 1 ping; Escape disarmed, a second Escape cleared the selection; with nothing selected A rode the king 6.97 m left in 1 s (7.5 m/s minus acceleration); the left stick with a selection moved him 0.000 m; right click with the archery squad selected pinged a move. Screenshots p7_armed, p7_attack_move."

### 8. Patrol, Shift queue, drag box and control groups
requirement: UNIT-09, UNIT-10
expected: Hold P and right-click points, release P; Shift-queue several moves then a hold; drag a box over both squads; Ctrl+1 to store and 1 to recall; build a new squad while a group exists. The patrol line, numbered queue discs (nine orders kept, six drawn), hover rings, drag box, recall flash and slot badges read well. Decide whether a newly built squad should auto-join a group (today it joins none, assumption 9) (03-08 D7).
result: issue
reported: "Shift does not queue the keyboard verbs: with three moves queued (discs 1 and 2 drawn), Shift+H cleared the queue and held the squad at once at its current centroid, so the D-09 gesture 'move here, then hold' cannot be given from the keyboard (CommandKeyController._give always submits queued=false; the simulation accepts a queued hold intent and keeps it behind the walk). Everything else passed: P + two right clicks drew the dashed patrol line with 2 discs and a 3-point path, the drag box selected both squads, Ctrl+1 stored the group (badge 1, 'Group 1 saved'), 1 recalled it with a ring flash, 2 said 'Group 2 is empty', and a squad built afterwards joined no group (kept as the default)."
severity: major
evidence: "p8/p8b: after_3_shift_moves orders=[move,move,move] discs=2; after_shift_H orders=[] stance=hold anchor=centroid; intent_queued_hold result=ok orders=[move, hold]; recall ring_flash 0->1; new_squad group_of_archery=-1. Screenshots p8_patrol, p8b_three_queued, p8_groups."

### 9. Gamepad on a physical pad
requirement: INPT-02
expected: Play one full night on a real pad: ride, sprint (RB), build (A), start night (Y), slam (X), D-pad verbs, LB layer for move / attack-move / patrol with the right-stick cursor (900 px/s), R3 select all, LB+R3 select type, Start group mode, RT to queue, B to cancel, D-pad right to cycle. Every in-run action is reachable on the pad with nothing needing a pointer; cursor speed, button feel, trigger edges and the chord layout feel right. Every pad event in every test and screenshot was synthetic; the pad layout was chosen by Claude, not by you (03-09 D6, assumption 8).
result: blocked
blocked_by: physical-device
reason: "No gamepad is connected to this machine (Input.get_connected_joypads() is empty), so a physical pad cannot be driven from here; the synthetic pad path passed in p10 and in the 03-09 tests."

### 10. Prompts follow the device; glyph legibility at 24 px
requirement: INPT-02, UI-01
expected: Switch between keyboard-and-mouse and the pad mid-run several times, in a day and in a fight, and read the start-night line, the slam badge and the hint row. Every prompt flips at once on any press or stick move of the other device (mouse counts as keyboard); 24 px tiles are readable (the D-pad tile is a cross with one arm lit, the Shift and Q tiles are small); Xbox tiles are acceptable on a non-Xbox pad until Phase 13 (03-10 D7; test_device_model and test_prompt_switch pin the switching).
result: pass
note: "Device switching measured in a real window (p10); the 24 px tiles were judged from the 4x crops and the 03-12 pad shot: letter keycaps (F, H, R, A, P, N) and the Xbox Y and X circles read at 1x, the Shift tile's word is too small to read at 1x but the tile shape is distinct, and the D-pad cross tiles were not captured here (03-10 D7 note stands). Xbox tiles on a non-Xbox pad stay deferred to Phase 13."
evidence: "p10: 12 PromptGlyph nodes; a pad press flipped the tracker and all 12 glyphs within the same frame, mouse motion flipped them back; 8 of 8 alternating switches landed within one frame; the start-night hold kept filling across a switch (0.40 -> 0.60). Crops p10_crop_hints_keyboard, p10_crop_widget_*, p10_crop_prompt_*; screenshots/hud_pad_cursor.png."

### 11. Balance feel with an army
requirement: UNIT-04
expected: Play three nights with an army, including nights 5 to 8 (now 25 / 31 / 39 / 39 enemies), and read 03-BALANCE-REPORT.md. Say which balance finding to accept: squads are not stronger than towers per gold under the bots; the balanced bot loses 1 of 10, not the 2 or 3 asked for in G-02-15; night 8 equals night 7. Nights should feel tense with squads (03-11 D7, D-08, Phase 2 D-18).
result: issue
reported: "Owner decision at UAT (2026-10-13), before the gate runs: retune further now toward all four goals at once: the balanced (tower-heavy) bot should lose 2-3 of 10 (G-02-15, today 1 of 10); squads should be worth their gold against towers (today the army bot falls faster than the balanced bot as nights grow); night 8 should rise above night 7 (today 39 = 39); and the army bot should also lose 2-3 of 10 (today 8 of 10 wins). The report shows night counts alone cannot reach these, so the pass may move squad or tower values, costs or regeneration, keeping nights 1-4 (the Phase 2 wall) untouched."
severity: major
evidence: "03-BALANCE-REPORT.md: army_balanced 8 of 10 after the retune, balanced 9 of 10, towers_first 2 of 3 pinned seeds, nights 5-8 at 25/31/39/39; the probe runs (p1, p2b) confirm the shipped unit data in play."

### 12. E6: longest toast inside x 384..896
requirement: UI-01
expected: Select a squad, ride to the edge of the ground and right-click off the map to raise the "Can't go there" toast. Accept a 526 px toast (x 377..903, one line, entirely below the clear centre), or have the copy shortened, or amend the UI-SPEC bound (03-12 D4; unmet-truth entry in .planning/WINDOWS.md).
result: [pending]

### 13. Knocked-out king widget legibility
requirement: UI-01
expected: Get the king knocked out at night and read the bottom-left widget and the "Knocked out" countdown label (screenshot hud_king_down). The red "0 / 50" is readable (KNOCKED_OUT_ALPHA 0.4 gives about 1.6:1 contrast per 03-UI-REVIEW.md priority fix 1); otherwise raise the alpha or keep the label opaque.
result: issue
reported: "The knocked-out king's '0 / 50' is illegible: at KNOCKED_OUT_ALPHA 0.4 the red digits measure 1.09:1 against the plate in the real-window capture (text luminance 0.077 vs background 0.067), far below any readable contrast; the 'Knocked out - back in 6 s' label measures 5.3:1 and reads fine."
severity: cosmetic
evidence: "p13: widget_alpha=0.40, health_label contrast_p90=1.09, respawn_label contrast_p90=5.32. Crops p13_crop_widget_down, p13_crop_respawn."

### 14. Bottom-centre hierarchy, plural copy and the lingering payout line
requirement: UI-01
expected: On a day with a squad selected look at the bottom-centre stack (hint row, slots, start-night prompt, fill bar, preview); at one enemy left read the banner; after a dawn look for the "+2 gold" line. The start-night prompt still reads as the day focal point beside a cyan selected slot; the banner should say "1 enemy", not "1 enemies left"; the payout line should expire at the next day start. Decide whether any of these block Phase 4 (03-UI-REVIEW fix 3; PLAYTEST-GATE open readability points; the plural and payout lines are Phase 1 and 2 copy).
result: issue
reported: "Plural copy: the banner prints 'Night 1 of 8 - 1 enemies left' and the preview 'Night 1: 1 enemies from 1 direction' at a count of one (NIGHT_BANNER and NIGHT_PREVIEW_ONE in hud.gd have no singular form). The payout line is fine in real time: '+1 gold' was still shown as the day began and hidden within 1 s (2 s hold from the dawn arrival); the lines lingering into the night in the 03-12 shots were a fast-forward artefact. Whether the cyan selected slot may outrank the start-night prompt (UI-REVIEW fix 3) is the owner's call."
severity: cosmetic
evidence: "p14: banner_one_left text='Night 1 of 8 - 1 enemies left'; preview_one_enemy text='Night 1: 1 enemies from 1 direction'; payout label_visible_at_day_start=true, day+1s visible=false; fast_forwarded_dawn+1.2s visible=true, +3.2s false. Crop p14_crop_bottom_centre."

### 15. Owner Phase 3 gate: two or three full runs on both devices, then sign off or name fixes
requirement: UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, KING-04, KING-05, INPT-01, INPT-02, UI-01
expected: Launch build/windows/Duskhold.exe (exported 2026-10-12 from c418b6c, launch-checked) or the editor binary, play two or three full 8-night runs with an army, once on keyboard and mouse and once on a gamepad, switching device at least once per run, following 03-PLAYTEST-GATE.md. Record a decision through /gsd-verify-work: sign off (squads guard and commit, selection and commands feel right on both devices, slam and regeneration suit the game, the HUD reads at night with the centre clear, the retuned nights are tense) or list fixes and any of assumptions 1 to 15 to change. No Phase 4 work starts before it.
result: [pending]

### 16. G-03-4 re-check: the floating bar over the king and the bottom-left widget agree after a heal
expected: Take a hit or two at night (or from an enemy by day), stop being hit, and watch the small bar floating over the king and the health bar bottom-left while the king regenerates; look at the moment he is whole again Expected: Both climb together, one point at a time, to the same number; the floating bar disappears once he is at full health (it used to freeze at the last damaged value while the widget climbed; fixed by plan 03-14, 10 heals measured equal in a real window) (Why human: The tests and the scripted real-window probe show the numbers agree; whether the two readouts read as one in motion, over the real scene, is a by-eye judgement (UAT test 4 re-check); requirement KING-05, UI-01)
result: [pending]

### 17. G-03-8 re-check: Shift-queued hold (and RT on the pad)
expected: Select a squad, Shift + right-click three points, then press Shift + H; repeat with Shift + F and Shift + R; press plain H after a queued walk; on a pad hold RT and press D-pad down Expected: The squad walks all three points and then holds at the last one (move here, then hold); plain H still stops it at once and holds where it stands; Shift + F and Shift + R queue the follow and the rally the same way; Shift while sprinting now queues a verb, which should not surprise. A hold pressed behind a queue that already ends in a hold, follow or patrol is silently refused (open finding WR-03) (Why human: Real keys and a real window were driven by the executor (03-13 probe lines: orders move, move, move, hold, held at the third point), but the gesture's feel, the hint row's 'Queue' wording and the silent refusal behind a terminal order are the owner's to judge (UAT test 8 re-check); requirement UNIT-10, INPT-01, INPT-02)
result: [pending]

### 18. G-03-11 re-check: Round 2 balance feel (0.9 s first tower, nights 5 to 8 at 25 / 31 / 39 / 40)
expected: Play three nights with an army, including nights 5 to 8, and read the Round 2 section of 03-BALANCE-REPORT.md; open with a tower on day 1 and see whether a first tower that fires every 0.9 s (was 0.8 s) still feels like a good opening Expected: Nights feel tense with squads; the owner accepts or rejects the reported trade: the balanced bot wins 8 of 10 and the army bot 8 of 10 (goals met), squads score 0.915 against the 0.8 bar mostly because towers got weaker, towers_first wins 0 of 10 and houses_first 4 of 10, the army bot loses 17.6 buildings a run, night 8 is now 40 against 39 (Why human: The bots build instantly and react perfectly and cannot judge tension or whether an opening feels rewarding; the report states the numbers measure the data only (D-08, Phase 2 D-18, UAT test 11 re-check); requirement UNIT-04, UNIT-07)
result: [pending]

### 19. G-03-13 re-check: the knocked-out king's '0 / 50'
expected: Get the king knocked out at night and read the bottom-left widget (count, the dimmed bar and sword plate, the Slam caption) and the 'Knocked out, back in N s' label Expected: The red 0 / 50 and the Slam caption are crisp and readable, the bar and sword plate are visibly dimmed; the knocked-out state still reads as knocked out (measured 5.88:1 on the real capture, was 1.62:1; I viewed hud_king_down.png and the count is legible) (Why human: A contrast number and one capture approximate legibility; the owner's eyes on a real monitor and a real night decide (UAT test 13 re-check). Note the probe's own guard and measurement rule have no unit test (WR-04); requirement UI-01)
result: [pending]

### 20. G-03-14 re-check: singular copy at a count of one (and the payout line)
expected: Leave exactly one enemy at night and read the banner; on a day whose night has one enemy read the preview; after a dawn watch the '+N gold' line under the gold counter Expected: 'Night N of 8 - 1 enemy left' and 'Night N: 1 enemy from 1 direction' (and plural for any other count); the payout line goes away by the time the day is under way and does not sit under the gold counter at night (UI-REVIEW saw it in fast-forwarded night captures; UAT p14 saw it expire within 1 s in real time) (Why human: The copy is test-pinned and I viewed the banner shot; whether the payout line behaves in real play, and whether it matters, is the owner's call (UAT test 14 re-check); requirement UI-01)
result: [pending]

### 21. G-03-14b re-check: the plated start-night prompt leads the day's bottom centre
expected: On a day with a squad selected (cyan slot border) look at the bottom-centre stack: hint row, squad slots, the plated 'Hold N to start Night N' prompt with its fill bar, and the preview line below it Expected: The start-night prompt reads as the day's focal point beside the selected slot (it now has a #14141A plate at y 624..690 below the strip, preview unplated below it); the five-layer column does not feel cluttered. UI-REVIEW still sees the cyan 4 px border as the most saturated element in the column and scores Visuals 3/4 (Why human: Hierarchy and clutter are a visual judgement; the geometry is test-pinned (test_start_night_plate 6/6) and the clear-centre check passes on 33 of 33 shots, but whether the prompt leads is the owner's (UAT test 14 re-check, UI-REVIEW fix 3); requirement UI-01)
result: [pending]

### 22. E6: longest toast inside x 384..896
expected: Select a squad, ride to the edge of the ground and right-click off the map to raise the Can't go there toast; then select a squad, press Shift + H, and press Shift + F (or Shift + right-click) to raise the Nothing can be queued after Hold, Follow or Patrol toast Expected: The owner accepts the two one-line toasts (Can't go there: 526 px, x 377..903; Nothing can be queued: 540 px, x about 370..910, both entirely below the clear centre at y 504..536), or has the copy shortened, or amends the UI-SPEC bound to the real longest line. The 540 px figure is new in this report: the fix pass added the toast and no record or test measured it (Why human: A 7 to 14 px per side miss of a literal band that never touches the protected rectangle is a spec-versus-taste call (03-12 D4, .planning/WINDOWS.md, D-28: decided after the owner plays the fixed build; UAT test 22 pending); requirement UI-01)
result: [pending]

### 23. Gamepad on a physical pad
expected: Play one full night on a real pad: ride, sprint (RB), build (A), start night (Y), slam (X), D-pad verbs, hold RT for the queue (new: RT + D-pad now queues the verb), LB layer for move / attack-move / patrol with the right-stick cursor (900 px/s), R3 select all, LB+R3 select type, Start group mode, B to cancel, D-pad right to cycle Expected: Every in-run action is reachable on the pad with nothing needing a pointer; cursor speed, button feel, trigger edges and the chord layout feel right (Why human: No gamepad is connected to this machine, so every pad event in every test, probe and screenshot was synthetic; the pad layout was chosen by Claude, not the owner (UAT test 9 blocked on physical-device; 03-09 D6, assumption 8); requirement INPT-02)
result: [pending]

### 24. Owner Phase 3 gate: two or three full runs on both devices, then sign off or name fixes
expected: Re-export first (`bash tools/export.sh`; build/windows/Duskhold.exe dates from c418b6c and holds none of the 03-13 to 03-19 fixes or the retune) or launch the editor binary; play two or three full 8-night runs with an army, once on keyboard and mouse and once on a gamepad, switching device at least once per run, following 03-PLAYTEST-GATE.md Expected: A recorded decision through /gsd-verify-work: sign off (squads guard and commit, selection and commands feel right on both devices, slam and regeneration suit the game, the HUD reads at night with the centre clear, the Round 2 nights are tense) or a list of fixes and any of assumptions 1 to 15 to change. No Phase 4 work starts before it (Why human: The feel clauses of the success criteria (fun, tension, readability, commands that feel right) and the delegated playtest gate (D-08, Phase 2 D-18) are the owner decision; bots, CI, 1397 green tests, probes and screenshot reviews are not the sign-off (UAT test 15); requirement UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, KING-04, KING-05, INPT-01, INPT-02, UI-01)
result: [pending]

### 25. Refused-queue and patrol-full toasts, and the mixed-selection rule (review-fix pass 1: WR-03, IN-06)
expected: Select a squad, Shift + right-click a point, press Shift + H, then press Shift + F (or Shift + right-click again): read the toast. Arm patrol (P) and right-click eight points: read the toast on the eighth. Select two squads, give both a move, queue a hold on only one of them, then Shift + right-click a point: watch which squads take it Expected: 'Nothing can be queued after Hold, Follow or Patrol' shows once when every selected squad already ends in a hold, follow or patrol (1.5 s, one line, in the hint-strip slot) and reads at the moment you needed it; 'A patrol takes up to 7 points' shows on the eighth patrol click and adds no point; in a mixed selection the open squad queues the new order and the closed squad is skipped with no toast, which should read as sensible rather than as a missed command (width of both lines is decided in item 7) (Why human: Copy, timing and the refusal paths are pinned by tests (test_squad_queue 17/17, test_command_keys 17/17, test_mouse_commands 16/16, test_pad_cursor 10/10 re-run by me) and the 03-VALIDATION manual-only table lists this check; whether the line reads in the moment, whether the silent skip of a closed squad in a mixed selection is the right call, and whether the 540 px line is acceptable are judgements (new UAT test 25); requirement UNIT-10, INPT-01, INPT-02, UI-01)
result: [pending]


## Summary

total: 25
passed: 7
issues: 5
pending: 12
skipped: 0
blocked: 1

## Gaps

Round 1 (2026-10-13, self-verified by the orchestrator with scripted real-window probes; root causes written from the probe evidence and the code, no debugger spawned). The 10 open code-review findings of 03-REVIEW.md stay open in 03-REVIEW-DISPOSITION.md; G-03-4 is the same defect as WR-01.

- gap_id: G-03-4
  truth: "The floating bar over the king and the bottom-left widget agree after a heal"
  status: failed
  reason: "User reported: the 3D bar over the king still showed 0.960 (the last damaged value) while the simulation and the HUD widget read 49/50 after regeneration; the bar only refreshes on damage, knockout, respawn and the dawn payout"
  severity: minor
  test: 4
  root_cause: "presentation/king/king.gd binds king_damaged, king_downed, king_respawned and dawn_payout but never king_healed, so _on_king_damaged is the only path that calls _health_bar.set_health during a night and every regeneration point is missed until the next hit (review WR-01). KingWidget polls the KingState every frame and is correct."
  artifacts:
    - "presentation/king/king.gd: bind_run connects four events, no king_healed handler"
    - "simulation/events/sim_events.gd: king_healed(amount, hp, max_hp) is emitted by KingState._regenerate"
    - "tests/integration/test_king_ride.gd or test_king_sturdiness.gd: no test drives a heal through the King node"
  missing:
    - "A king_healed handler in king.gd that calls _health_bar.set_health(hp, max_hp) (hidden again at full health by the D-12 rule)"
    - "A scene test that damages then heals the king and asserts the HealthBar3D fill ratio equals hp / max_hp after the heal"

- gap_id: G-03-8
  truth: "Shift-queue several moves then a hold: the hold runs after the queued walks (D-09: 'move here, then hold' is one gesture)"
  status: failed
  reason: "User reported: with three moves queued, Shift+H cleared the queue and held the squad at once at its current centroid; the hold is never queued from the keyboard"
  severity: major
  test: 8
  root_cause: "input/command_key_controller.gd _give(verb) submits SquadOrderIntent.new(ids, verb) with the queued flag left false and never reads the command_queue action, while SelectionController passes Input.is_action_pressed(command_queue) for right-click moves and patrol commits. SquadSystem.apply_order already accepts a queued hold (probe: a queued hold intent after a move returned ok and the queue read [move, hold]), so only the key path is missing."
  artifacts:
    - "input/command_key_controller.gd: _give(verb) (queued flag absent); the F, H and R verbs and the pad D-pad verbs all go through it"
    - "input/selection_controller.gd: right-click move and patrol commit pass Input.is_action_pressed(&\"command_queue\")"
    - "simulation/squads/squad_system.gd apply_order: a queued terminal verb waits behind the walks; QUEUE_CLOSED after a terminal verb"
    - "tests/integration/test_command_keys.gd (or test_control_group_keys.gd): no case holds command_queue while pressing a verb"
  missing:
    - "_give(verb) submits SquadOrderIntent.new(ids, verb, [], Input.is_action_pressed(&\"command_queue\")) so Shift+F / Shift+H / Shift+R append to the queue; the pad RT (command_queue) gets the same behaviour for free"
    - "A test: three queued moves then command_queue + squad_hold leaves orders_of == [move, move, move, hold] and the squad keeps walking; without Shift the hold still clears the queue"
    - "The hint row's 'Queue' item already names Shift; no copy change needed"

- gap_id: G-03-13
  truth: "The red '0 / 50' on the knocked-out king widget is readable"
  status: failed
  reason: "User reported: at KNOCKED_OUT_ALPHA 0.4 the digits measure 1.09:1 against the plate in a real-window capture (illegible); the respawn countdown label measures 5.3:1 and is fine"
  severity: cosmetic
  test: 13
  root_cause: "ui/hud/king_widget.gd _apply_knocked_out sets modulate.a = KNOCKED_OUT_ALPHA (0.4) on the whole widget, so the #FF4040 HealthLabel is dimmed together with the bar and the icon and lands at about the plate's own luminance (UI-REVIEW priority fix 1)."
  artifacts:
    - "ui/hud/king_widget.gd: KNOCKED_OUT_ALPHA = 0.4; _apply_knocked_out dims the whole widget"
    - "03-UI-SPEC.md King widget table: the caption 'shares the widget alpha (0.4 when knocked out)'"
    - "tests/integration/test_king_widget.gd: asserts the 0.4 modulate"
  missing:
    - "Keep HealthLabel (and the Slam caption) at alpha 1.0 while knocked out and dim only the bar and the icon plate, or raise the alpha to at least 0.7 with the label on the opaque plate (UI-REVIEW fix 1); update the UI-SPEC row and test_king_widget accordingly"
    - "A contrast check in the test: the label's effective colour over the plate must stay at or above 4.5:1"

- gap_id: G-03-14
  truth: "The night banner and the preview line use singular copy at a count of one ('1 enemy left', '1 enemy from 1 direction')"
  status: failed
  reason: "User reported: the banner prints 'Night 1 of 8 - 1 enemies left' and the day preview 'Night 1: 1 enemies from 1 direction' at a count of one"
  severity: cosmetic
  test: 14
  root_cause: "ui/hud/hud.gd formats NIGHT_BANNER, NIGHT_PREVIEW and NIGHT_PREVIEW_ONE with a fixed 'enemies' word and no plural rule (Phase 1 and 2 copy); the direction count already has a singular form (NIGHT_PREVIEW_ONE)."
  artifacts:
    - "ui/hud/hud.gd: NIGHT_BANNER, NIGHT_PREVIEW, NIGHT_PREVIEW_ONE, _refresh_banner, the preview refresh"
    - "tests/integration/test_walking_skeleton.gd or the HUD tests asserting the banner text"
  missing:
    - "A small plural helper (1 -> 'enemy', else 'enemies') used by both the banner and the preview"
    - "Tests pinning 'Night N of 8 - 1 enemy left' and 'Night N: 1 enemy from 1 direction'"

- gap_id: G-03-14b
  truth: "On a day with a squad selected the start-night prompt still reads as the day focal point beside a cyan selected slot (UI-SPEC focal-point rule; UI-REVIEW priority fix 3)"
  status: failed
  reason: "Owner decision at UAT (2026-10-13): fix the bottom-centre hierarchy now with the gaps. In hud_day_squads and p14_crop_bottom_centre the selected slot's 4 px #8CEBFF border and tinted plate are the strongest element at y 544..614, directly above the unplated start-night prompt at y 624..650"
  severity: cosmetic
  test: 14
  root_cause: "The start-night prompt (StartNightBox: 'Hold [glyph] to start Night N', fill bar, NightPreview) draws text with an outline straight on the 3D scene while the selected SquadSlot draws a 4 px accent border on a plate (ui/hud/squad_slot.gd SELECTED_BORDER_COLOR, SELECTED_PLATE_COLOR), so the accent-coloured slot outranks the contract's primary day focal point."
  artifacts:
    - "ui/hud/hud.tscn: StartNightBox, StartNightPrompt, StartNightFill, NightPreview (Phase 1 nodes, no plate)"
    - "ui/hud/squad_slot.gd: selected state border 4 px #8CEBFF and plate tint"
    - "03-UI-SPEC.md Layout 'Focal points (hierarchy)' and UI-REVIEW Top 3 fix 3"
    - "tools/screenshot/shot_army_scenarios.gd hud_day_squads; tests/unit/test_shot_protected_centre.gd (the plate must stay below y 500)"
  missing:
    - "A #14141A at 0.78 plate (corner radius 8, 8 px inset, Spacing sm) behind the start-night prompt and its fill bar, keeping NightPreview at 18 px tertiary, positioned inside y 616..700 so it never enters the clear centre and does not touch the strip (8 px gap)"
    - "UI-SPEC Layout row for StartNightBox updated with the plate; hud_day_squads re-captured; a scene test that the plate rect lies below y 500 and clears the SquadStrip rect"

- gap_id: G-03-11
  truth: "Nights 5 to 8 are tense with an army and the balance serves the owner's four goals: the balanced bot loses 2-3 of 10, squads are worth their gold against towers, night 8 is larger than night 7, and the army bot loses 2-3 of 10"
  status: failed
  reason: "User reported: retune further now toward all four goals (owner decision 2026-10-13); the 03-11 retune reached the Phase 2 bar for the army bot only (8 of 10) and left the balanced bot at 9 of 10 and night 8 equal to night 7"
  severity: major
  test: 11
  root_cause: "Plan 03-11 was limited to authored night counts (data/maps/prototype_map.tres) and could not change costs, income, squad sizes, unit stats or timings; with those fixed, raising late nights hurts the army route before the tower route (towers do 18-30 of the late-night kills, the army bot loses 16.4 buildings per run against 5.8), the tower opening dies at about 40 enemies on night 8, and regeneration (03-04) already moved the balanced bot from 2 losses to 1. Reaching all four goals needs the squad and tower values (and possibly regeneration or the king's slam) to move together with the night curve."
  artifacts:
    - "data/maps/prototype_map.tres: nights 5-8 totals 25/31/39/39 (nights 1-4 are the Phase 2 wall and stay)"
    - "data/units/footman.tres, data/units/archer.tres, data/buildings/barracks.tres, data/buildings/archery_range.tres: unit stats, squad sizes, costs, respawn seconds"
    - "data/king/king.tres: regen_fraction_per_second 0.1; data/king/sword.tres: slam 4 m / 4 damage / 9 s"
    - "tools/replay/playtest_strategies.gd (balanced, army_balanced, towers_first), tools/replay/balance_report.gd, tools/replay.sh; tests/unit/test_military_data_contract.gd and test_night_data_contract.gd pin the data; goldens smoke 2599c7c2 and army f7a967ed depend on the data"
    - "03-BALANCE-REPORT.md: the six-strategy table over seeds 1-10 and the levers it rules out"
  missing:
    - "A retune pass that moves squad value (unit damage, health, interval, squad size or cost) and, if needed, tower or regeneration values together with nights 5-8, measured with the existing bots over seeds 1-10, until: balanced 7-8 of 10, army_balanced 7-8 of 10, night 8 total above night 7, and the army bot's kills per gold within reach of the towers'"
    - "Re-pinned data contract tests; the smoke and army goldens stay byte-identical (they replay frozen fixture copies per the 03-11 design) and the full_idle digest before and after is recorded; plus an updated 03-BALANCE-REPORT.md section 'Round 2' with the table and the reasons"
    - "The owner judges feel at the gate afterwards (test 15); nights 1-4 untouched"

Round 2 (2026-10-13, after the UAT round-1 gap closure 03-13 to 03-19 at HEAD e925538): tests 16 to 24 are the verifier's nine remaining owner judgements, one per item (re-checks of G-03-4, G-03-8, G-03-11, G-03-13, G-03-14 and G-03-14b; the E6 decision; the physical pad; the gate). Tests 12 and 15 of round 1 stay pending and are superseded in substance by tests 22 and 24. build/windows/Duskhold.exe was re-exported from this HEAD on 2026-10-13 for the gate. Resume with /gsd-verify-work 3.

Round 3 (2026-10-14, after review-fix pass 1 fixed the 13 open code-review findings at commits 56b2828 to e01971e; fourth review 0 critical, 0 warning, 2 info; third verification report): test 25 is the verifier's one new owner judgement (the two new toasts and the mixed-selection rule); test 22 now covers both the 526 px and the new 540 px toast; tests 16 to 21, 23 and 24 are unchanged. build/windows/Duskhold.exe was re-exported from commit ca8086a (the fix pass plus its docs) on 2026-10-13T21:51Z. Resume with /gsd-verify-work 3.
