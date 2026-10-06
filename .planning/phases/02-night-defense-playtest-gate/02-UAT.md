---
status: complete
phase: 02-night-defense-playtest-gate
source: [02-VERIFICATION.md]
started: 2026-10-05T15:26:33Z
updated: 2026-10-06T10:25:22Z
---

## Current Test

[testing complete]

## Tests

### 1. Owner playtest gate (ROADMAP SC4, D-18): play one or two full 8-night runs on the exported build and either sign off or record the fixes that must land before Phase 3
expected: A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change
result: issue
reported: "(1) there needs to be some base gold gain at each wave. I made a tower the first wave and then had 0 gold for all waves after that. (2) castle should also have a simple attack, not too strong though. Maybe takes three shots to kill a grunt and two to kill the ranged units. (3) the speed up should be at least 1.5x faster too (4) i cant currently win lol make it just a bit easier"
severity: major

### 2. Results screen layout and the accidental-restart tap (WR-03, and the second review's WR-01, both now fixed in the code)
expected: Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel. Tapping or mashing Space or gamepad A as Victory/Defeat appears does not restart the run or quit: for the first 0.6 s of the screen both buttons ignore every press, and Play again works after that. A press that BEGINS inside the 0.6 s window and is released after it also does nothing (the code stamps when a press began, on button_down, and counts it only if it began after the window), and so does a key that was already held when the screen appeared. A fresh press that begins after the window works. Judge the feel: that 0.6 s neither lets a mash through nor feels sluggish before Play again responds, and that a held or straddling press does nothing
result: issue
reported: "stat rows have a gap between each other and between them and the buttons but the gap between the stat rows and the buttons is smaller than the gap within the stat rows. I think it should be equal. The rest is all good and passes (accidental-restart tap and press feel pass)."
severity: cosmetic

### 3. Enemy, health-bar, projectile and slash readability at night at the default camera
expected: Red grunts and violet skirmishers are told apart and read against the dark ground; hurt-only bars on enemies, king, castle and buildings are legible; arrows (now 15 cm x 1 m) are visible; the king's slash is visible
result: pass

### 4. Ghost king and knockout countdown
expected: On a knockout the king becomes a cyan ghost that cannot be steered, 'Knocked out - back in N s' reads clearly, and the king reappears at the castle on time; respawn times (6, 10, 14, 15 s) feel like a cost but not a punishment
result: pass

### 5. Rubble and collapse
expected: A destroyed House or tower collapses over about 0.9 s into rubble that is readable against the dark ground and on the pale plot disc
result: pass

### 6. Spawn telegraph markers and the night preview line
expected: By day each spawn point that will send enemies shows a red disc with its count (44 px on 1280x720) or an edge arrow when off screen, and 'Night N: X enemies from Y directions' sits under the start-night prompt; the player can plan from them
result: pass

### 7. Crossed-out coin over rebuilt Houses at dawn
expected: Each rebuilt House shows a crossed-out gold coin (26 px, on a red roof) and the player understands it pays nothing this dawn; it fades when the day starts
result: pass

### 8. Debug overlay path lines (F3) during a night
expected: Enemy-to-target and road lines are visible enough at game camera distance (currently 1-pixel hairlines); Wave, King and Paths sections read correctly
result: pass

### 9. Loss beat and results screen in a real defeat and a real victory
expected: On defeat the castle collapses for about 1.2 s, then the Defeat screen; on victory the screen appears at once; Play again starts a fresh run from day 1 and Quit closes the game; the screen works with keyboard, gamepad and mouse (all three act only after the 0.6 s grace)
result: pass

### 10. Hand-steered king, ride cost and gamepad feel at night; night 3 fairness
expected: The king handles well when steered by hand; riding between plots costs a meaningful amount of day; night 3 (king alone against two roads) feels fair to a first-time player; gamepad play at night works
result: pass

### 11. The 13 assumptions on the owner's behalf
expected: Owner confirms or changes each; in particular full dawn repair (1), no last dawn payout after night 8 (2), 6/10/14/15 s respawn (10), the 4-gold opening (13). Also the Play again behaviour recorded in 02-07 (a new random seed, so a replayed run is not the same run) is flagged in the summary but is not one of the 13
result: pass

## Summary

total: 11
passed: 9
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps
- gap_id: G-02-1
  truth: "A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change"
  status: failed
  reason: "User reported: (1) there needs to be some base gold gain at each wave. I made a tower the first wave and then had 0 gold for all waves after that. (2) castle should also have a simple attack, not too strong though. Maybe takes three shots to kill a grunt and two to kill the ranged units. (3) the speed up should be at least 1.5x faster too (4) i cant currently win lol make it just a bit easier"
  severity: major
  test: 1
  artifacts: []
  missing: []
- gap_id: G-02-2
  truth: "Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel. Tapping or mashing Space or gamepad A as Victory/Defeat appears does not restart the run or quit: for the first 0.6 s of the screen both buttons ignore every press, and Play again works after that. A press that BEGINS inside the 0.6 s window and is released after it also does nothing (the code stamps when a press began, on button_down, and counts it only if it began after the window), and so does a key that was already held when the screen appeared. A fresh press that begins after the window works. Judge the feel: that 0.6 s neither lets a mash through nor feels sluggish before Play again responds, and that a held or straddling press does nothing"
  status: failed
  reason: "User reported: stat rows have a gap between each other and between them and the buttons but the gap between the stat rows and the buttons is smaller than the gap within the stat rows. I think it should be equal. The rest is all good and passes (accidental-restart tap and press feel pass)."
  severity: cosmetic
  test: 2
  artifacts: []
  missing: []
