---
status: testing
phase: 05-castle-center-economy-depth
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-05-SUMMARY.md, 05-06-SUMMARY.md, 05-07-SUMMARY.md, 05-08-SUMMARY.md, 05-09-SUMMARY.md, 05-10-SUMMARY.md, 05-11-SUMMARY.md, 05-12-SUMMARY.md, 05-VERIFICATION.md, 05-PLAYTEST-GATE.md]
started: 2026-10-22T10:24:21Z
updated: 2026-10-22T10:24:21Z
---

## Current Test

number: 1
name: The cards read clearly in world space and picking by key and by mouse feels right (UI-02, BLDG-05)
expected: |
  Icon, name and flavour read from the riding camera; the pointed-at card rises and shows its yellow effect line; a click highlights and never buys; the hold buys the highlighted card and the pick is locked for the run; digits 1 to 4 pick cards while they show and recall control groups again after you ride away
awaiting: user response

## Tests

### 1. The cards read clearly in world space and picking by key and by mouse feels right (UI-02, BLDG-05)
requirement: UI-02, BLDG-05
test: Play a run on build/windows/Duskhold.exe (instructions in 05-PLAYTEST-GATE.md, 'How to play'). Ride to the castle by day with 6 or more gold; four cards stand above the keep. Highlight each with keys 1 to 4, then with the mouse (hover, then click), and hold the action key to buy
expected: Icon, name and flavour read from the riding camera; the pointed-at card rises and shows its yellow effect line; a click highlights and never buys; the hold buys the highlighted card and the pick is locked for the run; digits 1 to 4 pick cards while they show and recall control groups again after you ride away
why_human: Legibility from the real camera and the feel of picking are perceptual. The mechanics are pinned (test_card_row 12/12, test_card_mouse 12/12, test_card_digit_handover 6/6 in the full run) and I read castle_cards.png, but whether the row reads well is the owner's call
result: [pending]

### 2. The twelve abilities are distinct and worth a pick (BLDG-08)
requirement: BLDG-08
test: Over two or three runs take different cards at tiers II, III and IV (Royal Training, Commander, Masons, Prosperity; Headsman's Edge, Engineers, War Horns, Warded Mail; Iron Discipline, Arrow Storm, Master Builders, Golden Age) and read the Stats section of the F3 overlay
expected: Each card's effect is felt and no card is one you would never take or always take; or the owner names cards to rename, rebalance or replace (the numbers are data plus one contract test each)
why_human: Backstop-tier truth (05-12, D-02: the owner judges the set at the UAT). The data, the numbers line generated from the modifiers, the stack and the pick-order invariance are tested (test_ability_data 15/15, test_stat_combined, test_build_choice in the full run); whether a card is worth its pick is design taste
result: [pending]

### 3. The castle gate reads as a trade-off, not a wall (BLDG-09)
requirement: BLDG-09
test: Ride to a Tower, House, Barracks, Archery Range or Wall plot at its second-to-last tier before the castle is at tier II, read 'Needs Castle II', hold, then buy castle II (6 gold) and return
expected: The label reads as a choice to make (castle first or more defences first), the hold gives the denied bump and spends nothing, and the tier unlocks the moment castle II stands; or the owner softens the gate (fewer gated tiers or a lower gate)
why_human: The gate is pinned (test_build_requirements 15/15, test_gate_data_contract, test_castle_gate e2e; seven shipped top tiers carry requires_castle_tier = 2, read by me in data/buildings) and the bots lose the castle-less build (balanced_no_castle 3 of 10); whether it feels like a trade-off or an obstacle is the owner's judgement
result: [pending]

### 4. Each new building reads and is worth its gold (ECON-03, ECON-04, ECON-05, ECON-06)
requirement: ECON-03, ECON-04, ECON-05, ECON-06
test: In a run build the Gold Mine at (-30, 30), the Mill at (30, 28) and one Field, the Fishing Harbor on the pond's shore at (0, 20.5) and a Shrine at (-46, 30) or (46, 30); read each label before buying and watch the dawn payouts across several days (F3 Economy section shows the next payout)
expected: The Mine's falling payout (3, 2, 1, 1), the Fields' 'Needs a Mill' lock, the Harbor's boat per dawn up to its cap and the Shrine's wake are readable before purchase and each building feels worth its price; none feels pointless or too strong
why_human: The payout curves, the lock, the boats and the wake rule are pinned by unit, integration and e2e tests and the economy golden (all green in my full run), but worth and readability are judgements; the bots only measure
result: [pending]

### 5. The day's decisions feel deeper and the game is still fun (core value)
requirement: BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06
test: Play two or three full runs climbing the castle with picks and building the new economy (05-PLAYTEST-GATE.md, 'What to judge' 5)
expected: The day offers richer gold trade-offs (castle versus defences versus income) without being merely busier, and the night defence stays tense
why_human: Backstop-tier truth (05-12): fun and depth cannot be measured. The bots measured: balanced (castle-aware) wins 8 of 10, army_balanced 8 of 10 (value ratio 0.888 against the 0.8 bar), balanced_no_castle 3 of 10, greedy_economy 0 and no_build 0 (05-BALANCE-REPORT.md, not re-run by me)
result: [pending]

### 6. Three presentation points: night banner over a raised card, cropped tier IV roof, small buildings in economy_day
requirement: UI-02, BLDG-08
test: Open castle_cards.png, castle_tier_four.png and economy_day.png (screenshots/ or the CI artifacts) and look in the exported build: the 'Night 1 of 8' banner over the raised card, the tier IV keep's roof tip and flag at the default zoom, the Mine and the Mill from the far camera
expected: Rule on each: fix now (a presentation offset on the card row, a camera or model tweak, larger models) or wait for Phase 8 (Art, Readability and Sound)
why_human: Pure look. I read castle_cards.png (the banner text sits over the top of the raised card, legible but untidy) and economy_day.png (the Mine and the Mill are small at the far camera), matching the packet's open points 1 and 3; the owner decides
result: [pending]

### 7. The economy mix and the Shrine's wake rule (ECON-03, ECON-05, ECON-06)
requirement: ECON-03, ECON-05, ECON-06
test: Compare what the Harbor, the Mine, the Mill and the Fields pay across a run, and watch whether a Shrine wakes and fires in play (packet 'Open points' 4 and 5)
expected: The owner decides whether the Harbor should be weaker or the Mine, Mill and Fields stronger, and whether the Shrine needs a nearer plot, a longer reach, a lower threshold or a different wake rule. The bot sweep: the Shrine wakes in a minority of seeds and almost never fires; the Harbor dominates income
why_human: A balance call the bots flagged and the plans deliberately did not change (D-12 fixes the shapes, the numbers are free). The Shrine's rules are proven on fixtures and in the economy golden (test_shrine_night, test_shrine_destroyed, test_shrine_synergy); how often it matters on the shipped map is the owner's decision
result: [pending]

### 8. How far the castle ladder should reach (BLDG-08)
requirement: BLDG-08
test: Note how often a run affords castle III (10 gold) and IV (16 gold) and whether the army build can afford the castle at all (packet 'Open points' 6)
expected: Keep tiers III and IV as late-game goals, or lower their costs or raise income so they happen mid-run; and whether the army build should be able to afford the castle
why_human: Costs and income are data and the bots cannot reach tiers III and IV (about 30 gold a run) or afford the castle on the army build; whether that reads as a goal or a dead end is a feel call
result: [pending]

### 9. The card row's dismiss and pre-highlight (UI-02)
requirement: UI-02
test: Ride past the castle repeatedly with enough gold; try buying with no highlight (denied bump) and then with a highlight
expected: Rule whether cards re-appearing on every pass needs a dismiss, and whether the first card should be pre-highlighted (research A7 and A10 chose neither: no highlight means the hold is refused with choice_required and the denied bump)
why_human: A UX call: both behaviours are pinned (test_card_row, test_castle_gate) and neither was chosen by the owner yet
result: [pending]

### 10. The exported build and the owner's packet hand-off
requirement: UI-02, BLDG-08, ECON-03, ECON-06
test: Launch build/windows/Duskhold.exe (Duskhold.pck and libduskhold_sim.windows.x86_64.dll beside it, dated 2026-10-22) on the owner's machine and open 05-PLAYTEST-GATE.md (23 assumptions, 7 open points, 5 decisions)
expected: The build launches and plays a full run, and the packet's numbers (balanced 8 of 10, army 8 of 10, ratio 0.888, goldens, 44 shots) match 05-BALANCE-REPORT.md and 05-12-SUMMARY.md; the owner signs off or lists what must land before Phase 6 through /gsd-verify-work 5
why_human: A hand-off: the export files exist (listed by me, dated 2026-10-22 13:57 local) and the executor and orchestrator launch-checked it, but the launch on the owner's machine is the check and I did not launch it
result: [pending]

## Summary

total: 10
passed: 0
issues: 0
pending: 10
skipped: 0
blocked: 0

## Gaps
