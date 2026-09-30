---
status: testing
phase: 01-foundation-day-loop
source: [01-VERIFICATION.md]
started: 2026-09-29T12:10:00Z
updated: 2026-09-30T12:43:12Z
---

## Current Test

number: 1
name: Ride the king with keyboard and with a gamepad (walk, sprint, diagonal, stop) and watch the follow camera
expected: |
  Acceleration, turning and camera trail feel responsive and readable; sprint is clearly faster; camera never rotates
awaiting: user response

## Tests

### 1. Ride the king with keyboard and with a gamepad (walk, sprint, diagonal, stop) and watch the follow camera
expected: Acceleration, turning and camera trail feel responsive and readable; sprint is clearly faster; camera never rotates
result: [pending]

### 2. Ride around the whole prototype map and look at the spot markers, plot colours and castle landmark
expected: Map is readable; the 8 spots are distinguishable; edge-to-edge ride feels like 20-30 s
result: [pending]

### 3. Ride up to a House and a tower plot and read the world-space spot label; hold, release early, hold to completion, try with too little gold
expected: Label is legible (the 'House I' title reportedly overlaps its effect line in the spot_label screenshot); coins drip and refund visibly; red cost plus shake when unaffordable
result: [pending]

### 4. Look at the king (horse plus rider) and the House / tower / castle models in the running game
expected: Models read as a mounted king and as buildings (rider currently in T-pose on an unanimated horse, horse small; cosmetic, Phase 8 art pass)
result: [pending]

### 5. Press F3 (and gamepad Back) in a real window
expected: Overlay appears with FPS, units, enemies, phase, day, night, gold, buildings and is readable
result: [pending]

### 6. Hold N (and gamepad Y) for 1.5 s, then watch night banner, lighting, dawn payout and return to Day as 'Night 2'. Watch specifically: the gold counter must stay lagged while coins fly, tick up as each coin lands, and be exactly the ledger gold once dawn ends (never stuck low, never ahead of the coins)
expected: Prompt fills, banner and night lighting show, dawn coins fly from each paying House to the gold counter, '+X gold' appears, day returns with carried-over gold
result: [pending]

### 7. Owner decision on the Quaternius horse licence (review WR-06, skipped in review-fix)
expected: Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release
result: [pending]

### 8. Check the start-night prompt on a non-QWERTY keyboard layout (Dvorak or AZERTY): hold the bound physical key's position and read the on-screen prompt
expected: The prompt names the key by the label printed on that keycap on the player's layout (the default N key on QWERTY reads 'Hold N / (Y) to start Night 1'), not by its US-QWERTY position
result: [pending]

### 9. Owner decision on CI trigger semantics for DEV-02, then push the branch and confirm CI is green on the final HEAD
expected: Owner either accepts 'main, master, gsd/** and PRs' as satisfying 'on every push' (record an override) or widens the trigger; after pushing, lint, test, export and screenshots jobs are green on the new HEAD (last green run is 981e4c8, the current origin tip; the local branch is 239 commits ahead)
result: [pending]

## Summary

total: 9
passed: 0
issues: 0
pending: 9
skipped: 0
blocked: 0

## Gaps
