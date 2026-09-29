---
status: testing
phase: 01-foundation-day-loop
source: [01-VERIFICATION.md]
started: 2026-09-29T12:10:00Z
updated: 2026-09-29T16:19:31Z
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

### 6. Hold N (and gamepad Y) for 1.5 s, then watch night banner, lighting, dawn payout and return to Day as 'Night 2'
expected: Prompt fills, banner and night lighting show, dawn coins fly from each paying House to the gold counter, '+X gold' appears, day returns with carried-over gold (known: the dawn capture looks mostly night-coloured because the 1.0 s lighting ease outlasts the 0.6 s coin flight)
result: [pending]

### 7. Owner decision on the Quaternius horse licence (WR-06, skipped in review-fix)
expected: Owner confirms keeping the 2021 CC0 Poly Pizza copy despite the newer Quaternius Asset License, or replaces it before the itch.io release
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps
