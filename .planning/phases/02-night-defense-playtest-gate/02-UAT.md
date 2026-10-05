---
status: testing
phase: 02-night-defense-playtest-gate
source: [02-VERIFICATION.md]
started: 2026-10-05T15:26:33Z
updated: 2026-10-05T16:55:31Z
---

## Current Test

number: 1
name: Owner playtest gate (ROADMAP SC4, D-18): play one or two full 8-night runs on the exported build and either sign off or record the fixes that must land before Phase 3
expected: |
  A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change
awaiting: user response

## Tests

### 1. Owner playtest gate (ROADMAP SC4, D-18): play one or two full 8-night runs on the exported build and either sign off or record the fixes that must land before Phase 3
expected: A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change
result: [pending]

### 2. Results screen layout and the accidental-restart tap (WR-03, and the second review's WR-01)
expected: Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel. Tapping Space or gamepad A as Victory/Defeat appears does not restart the run: presses are ignored for the first 0.6 s of the screen, and Play again works after that. Also try a fresh, slightly held press that begins just inside the 0.6 s window and is released just after it: by the code it still presses Play again (a Button fires on release, and the grace gates the release), so judge whether that residual case matters in a real run
result: [pending]

### 3. Enemy, health-bar, projectile and slash readability at night at the default camera
expected: Red grunts and violet skirmishers are told apart and read against the dark ground; hurt-only bars on enemies, king, castle and buildings are legible; arrows (now 15 cm x 1 m) are visible; the king's slash is visible
result: [pending]

### 4. Ghost king and knockout countdown
expected: On a knockout the king becomes a cyan ghost that cannot be steered, 'Knocked out - back in N s' reads clearly, and the king reappears at the castle on time; respawn times (6, 10, 14, 15 s) feel like a cost but not a punishment
result: [pending]

### 5. Rubble and collapse
expected: A destroyed House or tower collapses over about 0.9 s into rubble that is readable against the dark ground and on the pale plot disc
result: [pending]

### 6. Spawn telegraph markers and the night preview line
expected: By day each spawn point that will send enemies shows a red disc with its count (44 px on 1280x720) or an edge arrow when off screen, and 'Night N: X enemies from Y directions' sits under the start-night prompt; the player can plan from them
result: [pending]

### 7. Crossed-out coin over rebuilt Houses at dawn
expected: Each rebuilt House shows a crossed-out gold coin (26 px, on a red roof) and the player understands it pays nothing this dawn; it fades when the day starts
result: [pending]

### 8. Debug overlay path lines (F3) during a night
expected: Enemy-to-target and road lines are visible enough at game camera distance (currently 1-pixel hairlines); Wave, King and Paths sections read correctly
result: [pending]

### 9. Loss beat and results screen in a real defeat and a real victory
expected: On defeat the castle collapses for about 1.2 s, then the Defeat screen; on victory the screen appears at once; Play again starts a fresh run from day 1 and Quit closes the game; the screen works with keyboard, gamepad and mouse (all three act only after the 0.6 s grace)
result: [pending]

### 10. Hand-steered king, ride cost and gamepad feel at night; night 3 fairness
expected: The king handles well when steered by hand; riding between plots costs a meaningful amount of day; night 3 (king alone against two roads) feels fair to a first-time player; gamepad play at night works
result: [pending]

### 11. The 13 assumptions on the owner's behalf
expected: Owner confirms or changes each; in particular full dawn repair (1), no last dawn payout after night 8 (2), 6/10/14/15 s respawn (10), the 4-gold opening (13). Also the Play again behaviour recorded in 02-07 (a new random seed, so a replayed run is not the same run) is flagged in the summary but is not one of the 13
result: [pending]

## Summary

total: 11
passed: 0
issues: 0
pending: 11
skipped: 0
blocked: 0

## Gaps
