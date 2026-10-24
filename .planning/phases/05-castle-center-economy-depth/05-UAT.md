---
status: complete
phase: 05-castle-center-economy-depth
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-05-SUMMARY.md, 05-06-SUMMARY.md, 05-07-SUMMARY.md, 05-08-SUMMARY.md, 05-09-SUMMARY.md, 05-10-SUMMARY.md, 05-11-SUMMARY.md, 05-12-SUMMARY.md, 05-VERIFICATION.md, 05-PLAYTEST-GATE.md]
started: 2026-10-22T10:24:21Z
updated: 2026-10-24T19:13:36Z
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
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis
- gap_id: G-05-7
  truth: "The owner decides whether the Harbor should be weaker or the Mine, Mill and Fields stronger, and whether the Shrine needs a nearer plot, a longer reach, a lower threshold or a different wake rule. The bot sweep: the Shrine wakes in a minority of seeds and almost never fires; the Harbor dominates income"
  status: failed
  reason: "User reported: Owner (2026-10-25): 'pass as is, but I think move the harbor into a much more exposed position that have enemy threat but not complete tower coverage so it is a bit awkward to defend or something. perhaps reduce its hp a bit too.' The Harbor's numbers (cost 3, cap 3 then 5, 1 gold a boat), the Mine, Mill, Fields and the Shrine's plots and wake rule stay as shipped. Claude's context for the gap planner: the Harbor plot sits at (0, 20.5) on the north shore of the visual-only pond centred at (0, 30) radius 8, south of the castle and away from the three spawn roads (west, east, north), so no enemy path passes it; moving it to an exposed spot means moving the pond with it (D-11, the pond must stay clear of plots, spawns, roads and the nav grid: EconomyValidation and test_pond_layout pin that), choosing a place a road passes within the enemies' aggro but outside full tower cover, and lowering harbor max_health (18 at tier I, 24 at tier II) by a step; the shipped prototype_map.tres and fishing_harbor.tres change, so the full_idle digest moves (owner-sanctioned by this decision, record before and after in the balance report) while the four fixture goldens stay; re-check the balance bar after the move."
  severity: major
  test: 7
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis

## Deferred Follow-Ups

- test: 5
  idea: "defer (owner 2026-10-24: judge the day's depth and the fun after the test 2 ability fixes and the economy decisions land; play two or three full runs on the exported build then)"
  deferred_at: 2026-10-24
