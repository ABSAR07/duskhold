---
status: diagnosed
phase: 05-castle-center-economy-depth
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-05-SUMMARY.md, 05-06-SUMMARY.md, 05-07-SUMMARY.md, 05-08-SUMMARY.md, 05-09-SUMMARY.md, 05-10-SUMMARY.md, 05-11-SUMMARY.md, 05-12-SUMMARY.md, 05-VERIFICATION.md, 05-PLAYTEST-GATE.md]
started: 2026-10-22T10:24:21Z
updated: 2026-10-24T20:03:16Z
---

## Current Test

[testing complete]

## Tests

### 1. The cards read clearly in world space and picking by key and by mouse feels right (UI-02, BLDG-05)
requirement: UI-02, BLDG-05
test: Play a run on build/windows/Duskhold.exe (instructions in 05-PLAYTEST-GATE.md, 'How to play'). Ride to the castle by day with 6 or more gold; four cards stand above the keep. Highlight each with keys 1 to 4, then with the mouse (hover, then click), and hold the action key to buy
expected: Icon, name and flavour read from the riding camera; the pointed-at card rises and shows its yellow effect line; a click highlights and never buys; the hold buys the highlighted card and the pick is locked for the run; digits 1 to 4 pick cards while they show and recall control groups again after you ride away
why_human: Legibility from the real camera and the feel of picking are perceptual. The mechanics are pinned (test_card_row 12/12, test_card_mouse 12/12, test_card_digit_handover 6/6 in the full run) and I read castle_cards.png, but whether the row reads well is the owner's call
result: pass
note: "Verified by Claude 2026-10-22 in a real window (scratch probe uat5_probe.gd on the shipped map, 1280x720, Forward+): with the king beside the castle plot and 60 gold the four tier II cards show with no card pre-highlighted; keys 1 to 4 highlight cards 1 to 4, each raised with its numbers line (+25% king health, +1 king damage / +25% unit health, +25% unit damage / +30% building health, +30% wall health / +1 castle gold at dawn); pointing the mouse at card 3 highlights it; a left click on card 4 highlights it (Prosperity) with gold 60, tier I and no command touched; the hold then bought castle II with Prosperity in 1.3 s, gold 60 to 54, choice_picked (castle_plot, 2, prosperity), the source armed in the stack and the label reading Castle III with 'Prosperity' as the locked pick; riding away hides the row and key 2 then highlights nothing; back at the plot the tier III row (Headsman's Edge, Engineers, War Horns, Warded Mail) shows with no highlight. Legibility from the riding camera read in the captures p1_cards_shown.png, p1_crop_click4.png and p1_bought.png: icon, name and flavour line read at 1280x720, the raised card is clearly lit and its yellow effect line reads; the known point stands: the 'Night 1 of 8' banner sits over the top of cards 2 and 3 and the keep's spire crosses card 2's and card 3's text. Feel of picking is the owner's to confirm in play; nothing measurable failed."

### 2. The twelve abilities are distinct and worth a pick (BLDG-08)
requirement: BLDG-08
test: Over two or three runs take different cards at tiers II, III and IV (Royal Training, Commander, Masons, Prosperity; Headsman's Edge, Engineers, War Horns, Warded Mail; Iron Discipline, Arrow Storm, Master Builders, Golden Age) and read the Stats section of the F3 overlay
expected: Each card's effect is felt and no card is one you would never take or always take; or the owner names cards to rename, rebalance or replace (the numbers are data plus one contract test each)
why_human: Backstop-tier truth (05-12, D-02: the owner judges the set at the UAT). The data, the numbers line generated from the modifiers, the stack and the pick-order invariance are tested (test_ability_data 15/15, test_stat_combined, test_build_choice in the full run); whether a card is worth its pick is design taste
result: issue
reported: "Owner (2026-10-24), two points. (a) On Commander's +25% unit damage rounding back to 1 at the shipped unit numbers: 'perhaps we need to scale all damage and health numbers up by a factor of 100. then percentages and rounding to nearest unit will work more as intended i think'. (b) On Prosperity's +1 gold a dawn: 'seems weak. we want to make sure that all alternatives at an upgrade level are mostly viable options, stronger in particular cases but not overly weak even in a case where its not an ideal option'. Claude's context for the gap planner: the twelve cards are distinct and each lands in the stack (verified); the defect is tuning resolution and balance, not the pick mechanism. A x100 scale of every health and damage integer (units, enemies, king, towers, buildings, walls, castle arrows, Shrine bolts, slam) touches every .tres and contract pin, the HUD and label numbers (50/50 would read 5000/5000 unless the display divides), the balance pins and the full_idle digest; the four fixture goldens carry their own def copies and would stay unless the fixtures are rescaled too (D-08 stop rule). Lower-blast alternatives the planner should weigh: scale only unit and enemy health and damage by 10, or make the small-base cards flat (+1 unit damage) where a percent cannot resolve."
severity: major

### 3. The castle gate reads as a trade-off, not a wall (BLDG-09)
requirement: BLDG-09
test: Ride to a Tower, House, Barracks, Archery Range or Wall plot at its second-to-last tier before the castle is at tier II, read 'Needs Castle II', hold, then buy castle II (6 gold) and return
expected: The label reads as a choice to make (castle first or more defences first), the hold gives the denied bump and spends nothing, and the tier unlocks the moment castle II stands; or the owner softens the gate (fewer gated tiers or a lower gate)
why_human: The gate is pinned (test_build_requirements 15/15, test_gate_data_contract, test_castle_gate e2e; seven shipped top tiers carry requires_castle_tier = 2, read by me in data/buildings) and the bots lose the castle-less build (balanced_no_castle 3 of 10); whether it feels like a trade-off or an obstacle is the owner's judgement
result: pass
note: "Verified by Claude 2026-10-22 in a real window (uat5_probe.gd, shipped map, 56 gold after Tower I): beside the built Tower I the label reads 'Tower II / Range 10.5 · Damage 6 / Needs Castle II' with no coin row (p3_locked.png); holding the action key fires hold_denied(tower_1, castle_tier), starts no hold, shakes the label 0.15 m and spends nothing (gold 56, tier I); buying castle II at the plot with key 1 (gold 50) then returning shows the label with the price back (6 coins, status empty) and a full hold buys Tower II for 6 gold (gold 44, tier II; p3_unlocked_bought.png). The seven gated top tiers (House III, Tower II, Barracks III, Archery Range III, Wall III, Mill III, Harbor II) are pinned by test_gate_data_contract, and the bots show the cost of skipping the castle (balanced_no_castle 3 of 10 against 8 of 10). Whether the gate reads as a trade-off or a wall, and whether to soften it, is the owner's call at the end (decision 2 of the packet)."

### 4. Each new building reads and is worth its gold (ECON-03, ECON-04, ECON-05, ECON-06)
requirement: ECON-03, ECON-04, ECON-05, ECON-06
test: In a run build the Gold Mine at (-30, 30), the Mill at (30, 28) and one Field, the Fishing Harbor on the pond's shore at (0, 20.5) and a Shrine at (-46, 30) or (46, 30); read each label before buying and watch the dawn payouts across several days (F3 Economy section shows the next payout)
expected: The Mine's falling payout (3, 2, 1, 1), the Fields' 'Needs a Mill' lock, the Harbor's boat per dawn up to its cap and the Shrine's wake are readable before purchase and each building feels worth its price; none feels pointless or too strong
why_human: The payout curves, the lock, the boats and the wake rule are pinned by unit, integration and e2e tests and the economy golden (all green in my full run), but worth and readability are judgements; the bots only measure
result: pass
note: "Verified by Claude 2026-10-22 in a real window (uat5_probe.gd, shipped map with no nights so dawns come from the timed night, 60 gold): before purchase the labels read 'Gold Mine I / Pays 3 gold, then 1 less each dawn, never below 1' (4 coins), 'Mill I / +1 gold at dawn' (3), 'Field I / +1 gold at dawn / Needs a Mill' (no coins), 'Fishing Harbor I / +1 boat each dawn, up to 3, 1 gold each' (3), 'Shrine I / Wakes after 100 enemy health falls within 18 m, then shoots and pays 1' (3); all five read at 1280x720 (p4_before_*.png). A hold on the Field before the Mill is refused with needs_spot and spends nothing; after the Mill the Field costs 2. The Mine was bought with a real hold (60 to 56). Four dawns with Mine, Mill, Field, Harbor and Shrine built paid +7 each: Mine 3, 2, 1, 1 (next-dawn preview 2, 1, 1, 1), Mill 1, Field 1, Harbor 1, 2, 3, 3 (one boat per dawn to the cap of 3), castle 1, Shrine 0 (asleep, no enemies). After the dawns the labels read 'Gold Mine I / Next dawn: 1 gold / Max tier' with the coin pile model, 'Fishing Harbor II / +1 boat each dawn, up to 5, 1 gold each / Needs Castle II' with boats on the pond, 'Shrine I / Asleep: 0 of 100 enemy health / Max tier', 'Mill II / +2 gold at dawn' (p4_after_*.png). Payback from the shipped numbers: House I 2 dawns, Field 2, Mine 2 (then 1 a dawn), Harbor 2 (then 3 a dawn), Mill 3, Shrine 3 plus its bolts once awake. Whether each feels worth its gold and whether the Harbor is too strong is the owner's call at the end (packet decision 3)."

### 5. The day's decisions feel deeper and the game is still fun (core value)
requirement: BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06
test: Play two or three full runs climbing the castle with picks and building the new economy (05-PLAYTEST-GATE.md, 'What to judge' 5)
expected: The day offers richer gold trade-offs (castle versus defences versus income) without being merely busier, and the night defence stays tense
why_human: Backstop-tier truth (05-12): fun and depth cannot be measured. The bots measured: balanced (castle-aware) wins 8 of 10, army_balanced 8 of 10 (value ratio 0.888 against the 0.8 bar), balanced_no_castle 3 of 10, greedy_economy 0 and no_build 0 (05-BALANCE-REPORT.md, not re-run by me)
result: skipped
reason: "Deferred follow-up: defer (owner 2026-10-24: judge the day's depth and the fun after the test 2 ability fixes and the economy decisions land; play two or three full runs on the exported build then)"

### 6. Three presentation points: night banner over a raised card, cropped tier IV roof, small buildings in economy_day
requirement: UI-02, BLDG-08
test: Open castle_cards.png, castle_tier_four.png and economy_day.png (screenshots/ or the CI artifacts) and look in the exported build: the 'Night 1 of 8' banner over the raised card, the tier IV keep's roof tip and flag at the default zoom, the Mine and the Mill from the far camera
expected: Rule on each: fix now (a presentation offset on the card row, a camera or model tweak, larger models) or wait for Phase 8 (Art, Readability and Sound)
why_human: Pure look. I read castle_cards.png (the banner text sits over the top of the raised card, legible but untidy) and economy_day.png (the Mine and the Mill are small at the far camera), matching the packet's open points 1 and 3; the owner decides
result: pass
note: "Owner 2026-10-24: 'pass for now, revisit in phase 8'. All three points (the night banner over a raised card, the cropped tier IV roof at default zoom, the small buildings in the wide economy view) wait for Phase 8 (Art, Readability and Sound); nothing changes now."

### 7. The economy mix and the Shrine's wake rule (ECON-03, ECON-05, ECON-06)
requirement: ECON-03, ECON-05, ECON-06
test: Compare what the Harbor, the Mine, the Mill and the Fields pay across a run, and watch whether a Shrine wakes and fires in play (packet 'Open points' 4 and 5)
expected: The owner decides whether the Harbor should be weaker or the Mine, Mill and Fields stronger, and whether the Shrine needs a nearer plot, a longer reach, a lower threshold or a different wake rule. The bot sweep: the Shrine wakes in a minority of seeds and almost never fires; the Harbor dominates income
why_human: A balance call the bots flagged and the plans deliberately did not change (D-12 fixes the shapes, the numbers are free). The Shrine's rules are proven on fixtures and in the economy golden (test_shrine_night, test_shrine_destroyed, test_shrine_synergy); how often it matters on the shipped map is the owner's decision
result: issue
reported: "Owner (2026-10-25): 'pass as is, but I think move the harbor into a much more exposed position that have enemy threat but not complete tower coverage so it is a bit awkward to defend or something. perhaps reduce its hp a bit too.' The Harbor's numbers (cost 3, cap 3 then 5, 1 gold a boat), the Mine, Mill, Fields and the Shrine's plots and wake rule stay as shipped. Claude's context for the gap planner: the Harbor plot sits at (0, 20.5) on the north shore of the visual-only pond centred at (0, 30) radius 8, south of the castle and away from the three spawn roads (west, east, north), so no enemy path passes it; moving it to an exposed spot means moving the pond with it (D-11, the pond must stay clear of plots, spawns, roads and the nav grid: EconomyValidation and test_pond_layout pin that), choosing a place a road passes within the enemies' aggro but outside full tower cover, and lowering harbor max_health (18 at tier I, 24 at tier II) by a step; the shipped prototype_map.tres and fishing_harbor.tres change, so the full_idle digest moves (owner-sanctioned by this decision, record before and after in the balance report) while the four fixture goldens stay; re-check the balance bar after the move."
severity: major

### 8. How far the castle ladder should reach (BLDG-08)
requirement: BLDG-08
test: Note how often a run affords castle III (10 gold) and IV (16 gold) and whether the army build can afford the castle at all (packet 'Open points' 6)
expected: Keep tiers III and IV as late-game goals, or lower their costs or raise income so they happen mid-run; and whether the army build should be able to afford the castle
why_human: Costs and income are data and the bots cannot reach tiers III and IV (about 30 gold a run) or afford the castle on the army build; whether that reads as a goal or a dead end is a feel call
result: pass
note: "Owner 2026-10-25: pass. The castle ladder stays at 6 / 10 / 16 with tiers III and IV as late-game goals; revisit after the test 2 ability fix and the test 7 Harbor move have settled and a few real runs have been played."

### 9. The card row's dismiss and pre-highlight (UI-02)
requirement: UI-02
test: Ride past the castle repeatedly with enough gold; try buying with no highlight (denied bump) and then with a highlight
expected: Rule whether cards re-appearing on every pass needs a dismiss, and whether the first card should be pre-highlighted (research A7 and A10 chose neither: no highlight means the hold is refused with choice_required and the denied bump)
why_human: A UX call: both behaviours are pinned (test_card_row, test_castle_gate) and neither was chosen by the owner yet
result: pass
note: "Owner 2026-10-25: pass. No dismiss and no pre-highlighted card: the row shows only while the upgrade is available and in reach, and a hold with no pick stays refused."

### 10. The exported build and the owner's packet hand-off
requirement: UI-02, BLDG-08, ECON-03, ECON-06
test: Launch build/windows/Duskhold.exe (Duskhold.pck and libduskhold_sim.windows.x86_64.dll beside it, dated 2026-10-22) on the owner's machine and open 05-PLAYTEST-GATE.md (23 assumptions, 7 open points, 5 decisions)
expected: The build launches and plays a full run, and the packet's numbers (balanced 8 of 10, army 8 of 10, ratio 0.888, goldens, 44 shots) match 05-BALANCE-REPORT.md and 05-12-SUMMARY.md; the owner signs off or lists what must land before Phase 6 through /gsd-verify-work 5
why_human: A hand-off: the export files exist (listed by me, dated 2026-10-22 13:57 local) and the executor and orchestrator launch-checked it, but the launch on the owner's machine is the check and I did not launch it
result: pass
note: "Verified by Claude 2026-10-22: build/windows/Duskhold.exe (109,268,480 bytes, with Duskhold.pck and libduskhold_sim.windows.x86_64.dll beside it, all dated 2026-10-22 13:57 local) launched in a real window on this machine (Vulkan 1.4, Forward+, RTX 3060 Laptop GPU) and quit cleanly after 600 frames, exit 0 in 11 s; the executor's headless launch check also exited 0. The packet's numbers match the reports: balanced and army 8 of 10 and the 0.888 ratio in 05-BALANCE-REPORT.md, the full_idle digests afc11cd0 (after) and 4385f569 (before) in the report, the economy golden f4b98093, CI run 39751537305 and the 44 shots in 05-12-SUMMARY.md. The full run on this build is what tests 1 to 5 ask the owner to play."

## Summary

total: 10
passed: 7
issues: 2
pending: 0
skipped: 1
blocked: 0

## Gaps
- gap_id: G-05-2
  truth: "Each card's effect is felt and no card is one you would never take or always take; or the owner names cards to rename, rebalance or replace (the numbers are data plus one contract test each)"
  status: failed
  reason: "User reported: Owner (2026-10-24), two points. (a) On Commander's +25% unit damage rounding back to 1 at the shipped unit numbers: 'perhaps we need to scale all damage and health numbers up by a factor of 100. then percentages and rounding to nearest unit will work more as intended i think'. (b) On Prosperity's +1 gold a dawn: 'seems weak. we want to make sure that all alternatives at an upgrade level are mostly viable options, stronger in particular cases but not overly weak even in a case where its not an ideal option'. Claude's context for the gap planner: the twelve cards are distinct and each lands in the stack (verified); the defect is tuning resolution and balance, not the pick mechanism. A x100 scale of every health and damage integer (units, enemies, king, towers, buildings, walls, castle arrows, Shrine bolts, slam) touches every .tres and contract pin, the HUD and label numbers (50/50 would read 5000/5000 unless the display divides), the balance pins and the full_idle digest; the four fixture goldens carry their own def copies and would stay unless the fixtures are rescaled too (D-08 stop rule). Lower-blast alternatives the planner should weigh: scale only unit and enemy health and damage by 10, or make the small-base cards flat (+1 unit damage) where a percent cannot resolve."
  severity: major
  test: 2
  root_cause: "Three causes add up (debug session, scratch probe on the real StatStack and shipped data): (a) several cards apply a percent or multiplier to a per-hit whole number whose shipped base is 1, 2 or 3, so the change rounds away or overshoots: Commander's +25% unit damage on footman and archer damage 1 gives 1 (no change); Warded Mail's x0.75 on every enemy hit of 2 gives 2 (the whole card does nothing in every run); Golden Age's +25% shrine damage on 3 gives 4, the same as the Shrine's own synergy, so it adds nothing once two Shrines are awake; Iron Discipline's x1.5 on damage 1 gives 2 (+100%, more than written); Engineers' +25% on Tower I damage 3 gives 4 (+33%). (b) Enemies die in 1 to 6 hits (grunt 6 hp, skirmisher 4 hp), so a damage percent only shows when it changes the hits to kill; a uniform x100 rescale keeps every one of those thresholds where it is. (c) Prosperity (+1 castle gold a dawn) and Golden Age (+2) pay a flat amount at each dawn left after the pick, and the castle tiers arrive late (castle II on day 6 at the earliest for the bot, seven paying dawns in a run), so Prosperity pays about 2 gold for a 6-gold tier; the shipped balanced bot with Prosperity instead of Masons wins 7 of 10 (Masons 8) with 28.8 gold earned (Masons 30.0); +2 matches Masons on gold. StatStack itself works as documented (one exact fraction, rounded half up once): the fault is in the data bases and the flat income design, not the formula. Why not caught: test_ability_data pins only each card's stat, bucket and value; test_stat_stack and test_stat_combined use synthetic bases (3, 6, 10); the bots only ever pick Masons."
  artifacts:
    - path: "data/abilities/commander.tres"
      issue: "+25% unit.attack_damage on a base of 1 rounds to no change"
    - path: "data/abilities/warded_mail.tres"
      issue: "x0.75 king.damage_taken on every 2-damage enemy hit rounds to 2: the card does nothing"
    - path: "data/abilities/golden_age.tres"
      issue: "+25% shrine.damage on 3 is masked by the Shrine synergy; +2 castle gold at tier IV has 0 or 1 paying dawn"
    - path: "data/abilities/iron_discipline.tres"
      issue: "x1.5 unit.attack_damage on 1 gives 2, double what the card says"
    - path: "data/abilities/prosperity.tres"
      issue: "+1 castle gold a dawn is worth about 2 gold by the time castle II is bought; weakest tier II card by wins, gold and buildings lost"
    - path: "data/abilities/engineers.tres"
      issue: "+25% tower damage on 3 gives 4 (+33%); only the range half changes a kill"
    - path: "data/abilities/headsmans_edge.tres"
      issue: "x2 damage at x1.5 interval is a loss against skirmishers and after Royal Training (kill thresholds)"
    - path: "data/units/footman.tres"
      issue: "attack_damage 1 (Phase 3 D-07) is the base every unit damage percent rounds against"
    - path: "data/units/archer.tres"
      issue: "attack_damage 1, same"
    - path: "data/enemies/grunt.tres"
      issue: "damage 2 and health 6 set the kill thresholds every damage card is measured against"
    - path: "data/enemies/ranged.tres"
      issue: "damage 2 and health 4, same"
    - path: "tests/unit/test_ability_data.gd"
      issue: "pins stat, bucket and value only; no test that a card moves its stat at every shipped base it touches"
    - path: "simulation/stats/stat_stack.gd"
      issue: "correct to its contract (one half-up rounding); a per-attacker fractional carry would be the systemic alternative"
  missing:
    - "A choice of resolution fix, from the debug session's three sized alternatives: (ii) recut the dead or dishonest cards in data only (Commander +1 unit damage or a bigger health half; Warded Mail x0.5 or -1 damage taken; Golden Age +1 shrine damage; Iron Discipline text made honest), smallest blast, no golden moves; (iii) a per-attacker fractional carry inside StatStack so percents land on 1-damage hits with data unchanged (new rounding sentence in STAT_MODIFIERS.md, test_stat_contract), no golden moves, Iron Discipline becomes an honest x1.5; or the owner's x100 (or x10) rescale of every health and damage number (about 20 data files, 5 stress files, 7 fixtures, 10 display sites, about 15 contract tests, all balance pins; full_idle moves, the four fixture goldens stay) which fixes the percents but not the hits-to-kill thresholds"
    - "Prosperity made viable: +2 castle gold a dawn (matches Masons on gold in the bot sweep) or a percent-of-all-income stat (new income stat in code; roughly +2 a dawn at 6 to 8 gold dawns); rework Golden Age's income half the same way"
    - "A recurrence-guard contract test: every card modifier must move its stat at every shipped base it touches, within a band of its written effect"
    - "Re-measure the Phase 2 bar (bash tools/playtest.sh --seeds=10) after the retune; record any full_idle move in 05-BALANCE-REPORT.md (D-08)"
  debug_session: .planning/debug/card-percent-rounding-and-prosperity.md
- gap_id: G-05-7
  truth: "The owner decides whether the Harbor should be weaker or the Mine, Mill and Fields stronger, and whether the Shrine needs a nearer plot, a longer reach, a lower threshold or a different wake rule. The bot sweep: the Shrine wakes in a minority of seeds and almost never fires; the Harbor dominates income"
  status: failed
  reason: "User reported: Owner (2026-10-25): 'pass as is, but I think move the harbor into a much more exposed position that have enemy threat but not complete tower coverage so it is a bit awkward to defend or something. perhaps reduce its hp a bit too.' The Harbor's numbers (cost 3, cap 3 then 5, 1 gold a boat), the Mine, Mill, Fields and the Shrine's plots and wake rule stay as shipped. Claude's context for the gap planner: the Harbor plot sits at (0, 20.5) on the north shore of the visual-only pond centred at (0, 30) radius 8, south of the castle and away from the three spawn roads (west, east, north), so no enemy path passes it; moving it to an exposed spot means moving the pond with it (D-11, the pond must stay clear of plots, spawns, roads and the nav grid: EconomyValidation and test_pond_layout pin that), choosing a place a road passes within the enemies' aggro but outside full tower cover, and lowering harbor max_health (18 at tier I, 24 at tier II) by a step; the shipped prototype_map.tres and fishing_harbor.tres change, so the full_idle digest moves (owner-sanctioned by this decision, record before and after in the balance report) while the four fixture goldens stay; re-check the balance bar after the move."
  severity: major
  test: 7
  root_cause: "The Harbor is risk-free because of where it was placed and a test that keeps it there; nothing in the targeting code skips it (debug session, bot probes on seeds 1 to 10). (1) Data: harbor_1 sits at (0, 20.5) with its pond at (0, 30) radius 8, south of the castle where no road runs: 19.3 m from the west and east roads, 20.5 m from the north road, inside the castle arrow's 22 m reach. Enemies walk straight lines from their spawns at (-66, 24), (66, 24) and (0, -66) to the castle and only take a building whose edge is within their aggro (grunt 6 m, skirmisher 9 m; with the Harbor's 1.5 m body radius that is 7.5 m and 10.5 m centre to centre), so no enemy ever notices it: in 10 balanced-bot runs it was built in 9, earned 7.2 gold a run, took 0 hits. (2) A test rule: test_every_phase_five_plot_is_twelve_metres_from_every_road in tests/unit/test_prototype_map_economy.gd (MIN_ROAD_CLEARANCE_M 12, from RESEARCH E5 and D-09/D-11) covers harbor_1, so moving the plot alone fails the test and relaxing the test alone moves nothing. Measured candidates: a Harbor 9.5 to 10.3 m off a road is noticed by skirmishers only and keeps every balance pin; at 7.5 m grunts take it too and the balanced bot drops to 6 or 7 of 10. Proposal A (recommended): west road, south side, between tower_1 and the Mine, Harbor (-39.93, 25.48) with the pond at (-38.22, 30.18) radius 4.5 (shrunk from 8 to clear the Mine and the west Shrine; 15.3 m from the road against 14.5 needed), north-shore rule kept, no tower reaches it (tower_1 16.0 m away, the castle 47.4 m), an awake west Shrine 7.6 m away covers it partly: balanced 8 of 10 (same lost seeds 3 and 9), 26.4 gold (was 30.0), the Harbor earns 3.5 and is destroyed 18 times in 10 runs. B: west road north side (-45.09, 5.43), pond (-47.92, -2.37) r 8, 8 of 10, but the Harbor lands on the pond's south shore (dock faces away; BuildSpotDef has no facing). C: north road (-8, -40), pond (-18.6, -38.6) r 8, threat only from night 6; 7 of 10 at 18/24 health (breaks BALANCED_LOST_SEEDS), 8 of 10 at 14/20. Health: 18/24 today (House 12/18/24, Mill 15/20/25); 14/20 or 15/20 is 'a bit less'; pinned only by HARBOR_HEALTHS in test_economy_data_contract.gd; at A the health makes no difference (skirmishers finish it either way)."
  artifacts:
    - path: "data/maps/prototype_map.tres"
      issue: "harbor_1 position (0, 20.5) and pond_center (0, 30) / pond_radius 8 keep the Harbor 19 m from every road, outside every enemy's notice"
    - path: "data/buildings/fishing_harbor.tres"
      issue: "max_health 18 / 24 is the lever for 'a bit less' (14/20 or 15/20)"
    - path: "tests/unit/test_prototype_map_economy.gd"
      issue: "MIN_ROAD_CLEARANCE_M 12 applies to harbor_1 (test_every_phase_five_plot_is_twelve_metres_from_every_road) and HARBOR_AT pins (0, 20.5)"
    - path: "tests/unit/test_economy_data_contract.gd"
      issue: "pins the plot position, POND_CENTER, POND_RADIUS and HARBOR_HEALTHS"
    - path: "tests/unit/test_pond_layout.gd"
      issue: "MIN_ROAD_CENTRE_M hard-coded to 18 (radius 8 + 10): compute it from the radius; the north-shore check holds for A and C, not B"
    - path: "tests/e2e/test_harbor_scene.gd"
      issue: "POND_CENTER and POND_RADIUS pins"
    - path: "tools/screenshot/shot_economy_scenarios.gd"
      issue: "POND_STAND_OFFSET and DAY_STAND aim the harbor_pond and economy_day shots at the old position"
    - path: ".planning/phases/05-castle-center-economy-depth/05-BALANCE-REPORT.md"
      issue: "full_idle (afc11cd0, 7000 ticks) moves with the map change; record before and after (D-08)"
  missing:
    - "Move harbor_1 and its pond to proposal A (Harbor (-39.93, 25.48), pond (-38.22, 30.18) radius 4.5) unless the owner prefers B or C; keep the pond clearance rules and the north-shore rule"
    - "Give harbor_1 its own road band (9 to 10.5 m) in test_prototype_map_economy.gd instead of the 12 m rule, with the reason written in the test"
    - "Lower the Harbor's health a step (14/20 or 15/20) and re-pin HARBOR_HEALTHS"
    - "Update the position, pond and shot pins; compute test_pond_layout's road-distance constant from the radius; re-aim and re-capture harbor_pond and economy_day in a real window and review them"
    - "Re-run bash tools/playtest.sh --seeds=10, keep the Phase 2 bar (balanced 7 or 8 of 10, army 8 of 10, ratio at least 0.8) without lowering it, re-pin test_balance_acceptance with a header naming this gap round, and record full_idle before and after in 05-BALANCE-REPORT.md; the four fixture goldens must not move"
  debug_session: .planning/debug/harbor-exposed-placement.md

## Deferred Follow-Ups

- test: 5
  idea: "defer (owner 2026-10-24: judge the day's depth and the fun after the test 2 ability fixes and the economy decisions land; play two or three full runs on the exported build then)"
  deferred_at: 2026-10-24
