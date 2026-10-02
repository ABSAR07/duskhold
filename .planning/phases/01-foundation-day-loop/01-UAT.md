---
status: complete
phase: 01-foundation-day-loop
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md, 01-04-SUMMARY.md, 01-05-SUMMARY.md, 01-06-SUMMARY.md, 01-07-SUMMARY.md, 01-08-SUMMARY.md, 01-09-SUMMARY.md, 01-10-SUMMARY.md, 01-VERIFICATION.md]
started: 2026-10-01T09:10:51Z
updated: 2026-10-02T10:55:41Z
---

## Current Test

[testing complete]

## Tests

### 1. Boot into the prototype map and ride the king
expected: The game boots straight into the prototype map. The king rides with WASD / arrow keys / left stick (Shift or RB to sprint) and a fixed follow camera keeps him in view.
result: pass

### 2. Acceleration and turning feel
expected: The king speeds up smoothly instead of jumping to full speed, and horse and rider turn to face the riding direction; the acceleration and turn rate feel right with keyboard and with a gamepad.
result: pass

### 3. Follow camera framing
expected: The camera keeps one fixed angle (the player cannot rotate it), trails slightly behind the king and catches up, and keeps the king readable near the centre of the screen.
result: issue
reported: "mostly good, but when the king goes behind a building like behind the castle, his silhouette is not visible. The king disappears behind stuff basically. Is that intentional? / I think we should move the camera a bit further away. Also should have buttons that zoom out or zoom in, to a certain extent"
severity: major

### 4. Map, plots and building growth
expected: Riding the whole map: 5 tan House plots near the castle, 3 slate-blue tower plots further out and a castle keep at the centre; a House grows to tier II on a second hold (gold falls by 2, then 3); the far towers are about 10-15 s from the castle; the map is readable.
result: issue
reported: "pass. But the building count up time is too short. needs tweaking to make it a biiiit longer"
severity: minor

### 5. King and building models
expected: The king reads as a crowned rider on a horse (about 2.5 m tall, smaller than a House) that turns to face the way it rides, and the House, tower and castle models look right and match in scale. Known: the rider is in a T-pose on an unanimated horse until the Phase 8 art pass.
result: pass

### 6. Spot label legibility
expected: Near a spot by day, a label floats above only the nearest spot with the next tier name, its effect and coin icons for the cost that fill as coins land; it turns red when unaffordable, says Max tier at the top tier and shakes on a denied press. It is legible and well placed from the gameplay camera.
result: pass

### 7. Coin drip and refund
expected: Holding the action key at a spot sends coins one at a time from the king into the spot while the HUD gold counts down; releasing early flies them back and restores the full amount. The drip reads as a satisfying one-at-a-time stream.
result: pass

### 8. F3 debug overlay in a real window
expected: F3 (or gamepad Back) shows the overlay in the top-right corner with FPS, phase, day, night, gold, buildings, units and enemies; it is legible, does not clash with the gold label, and a second press hides it.
result: pass
verified_by: "Claude scripted real-window run 2026-10-02 at owner's request: F3 shows the top-right panel with FPS 144, Phase, Day, Night, Gold, Buildings, Units, Enemies; Gold/Buildings rows updated after two Space-hold builds; Timer row by night and dawn; second F3 hides; gamepad Back shows and hides; panel clear of the gold label"

### 9. Night and dawn in a real window
expected: Holding N (or gamepad Y) fills the bar at the bottom over about 1.5 s; the night starts with cool blue light under the 'Night 1 — no enemies yet' banner, then an orange dawn, then the day returns with the prompt reading 'Hold N / (Y) to start Night 2'.
result: pass
verified_by: "Claude scripted real-window run 2026-10-02: N hold filled the bar (0.50 at 0.75 s) and started Night 1 at ~1.5 s; blue night under 'Night 1 — no enemies yet'; settled dawn reads orange; day returned with 'Hold N / (Y) to start Night 2'. Note: the payout plays in the first ~0.7 s of dawn while the light is still easing from night"

### 10. Dawn payout
expected: At dawn, coins fly from each paying House to the gold counter, which ticks up as each lands and ends exactly on the new total; then a '+X gold' total appears and fades. Coin size and timing, the total's placement and the dawn light read well, and the six screenshots in screenshots/ show their scenes.
result: pass
verified_by: "Claude scripted real-window run 2026-10-02: two House I paid 2 coins; HUD gold counted 0 -> 1 -> 2 as coins landed while the ledger was already 2; '+2 gold' shown under the gold label then day kept 2 gold"

### 11. Start-night key label on a non-QWERTY layout
expected: On a Dvorak or AZERTY layout, the start-night prompt names the key by the label printed on that keycap (on QWERTY the default reads 'Hold N / (Y) to start Night 1'), not by its US-QWERTY position.
result: skipped
reason: "Owner chose to skip on 2026-10-02: no non-QWERTY layout at hand; the fake-layout resolver seam is unit-tested"

### 12. Simulation and test suite run headless
expected: The whole simulation is built and exercised without a scene tree, and the full suite runs headless: bash tools/test.sh (Git Bash) passes 290/290, and the CI test job is green on 7ae173b.
result: pass
verified_by: "Full suite 290/290 (36 scripts) locally at 7ae173b on 2026-10-01 and in CI run 36835551706 (test job green); test_build_flow builds RunContext without a scene tree"

### 13. CI runs on every push
expected: Every push to any branch or tag (plus pull requests and manual runs) runs lint, test, export and screenshots in GitHub Actions, and the latest push, 7ae173b (run 36835551706), is green in all four jobs. This trigger satisfies DEV-02 for you.
result: pass
verified_by: "ci.yml triggers on every push (any branch or tag) plus pull_request and workflow_dispatch; push run 36835551706 on 7ae173b green in lint, test, export and screenshots; trigger decision delegated by the owner on 2026-10-01"

### 14. Public repo under the approved name
expected: The repository is public as ABSAR07/duskhold, the name you approved, with only the gsd/phase-01-foundation-day-loop branch pushed and no tags.
result: pass
verified_by: "gh repo view: ABSAR07/duskhold PUBLIC; git ls-remote: only refs/heads/gsd/phase-01-foundation-day-loop, no tags (2026-10-01); name approved by the owner at the 01-03 checkpoint"

### 15. Horse licence decision
expected: You keep the Quaternius horse as CC0 and accept the residual licence risk, including that the unmodified GLB is public in the repo and ships in the build; ASSETS.md, its License.txt and attribution.json record this.
result: pass
verified_by: "Owner answered in chat on 2026-10-01: keep the horse and accept the residual licence risk, including the unmodified GLB being public in the repo and shipping in the build; recorded in ASSETS.md, License.txt and attribution.json"

### 16. tools/bootstrap.py refuses to download without --yes (exit 2) and prints the dry-run table; nothing was downloaded before owner approval
expected: tools/bootstrap.py refuses to download without --yes (exit 2) and prints the dry-run table; nothing was downloaded before owner approval
result: pass
source: automated
coverage_id: 01-01/D1

### 17. Godot 4.7.2-stable installed self-contained with Windows export templates, both archives checksum-verified against official SHA512-SUMS.txt
expected: Godot 4.7.2-stable installed self-contained with Windows export templates, both archives checksum-verified against official SHA512-SUMS.txt
result: pass
source: automated
coverage_id: 01-01/D2

### 18. Headless GUT 9.7.1 run through tools/test.sh with JUnit XML output; toolchain smoke test passes 2/2
expected: Headless GUT 9.7.1 run through tools/test.sh with JUnit XML output; toolchain smoke test passes 2/2
result: pass
source: automated
coverage_id: 01-01/D3

### 19. tools/lint.sh runs gdformat --check and gdlint on first-party GDScript only and exits 0
expected: tools/lint.sh runs gdformat --check and gdlint on first-party GDScript only and exits 0
result: pass
source: automated
coverage_id: 01-01/D4

### 20. Repo hygiene keeps local tooling out of git (.claude/* except CLAUDE.md, .tools/, .godot/, build and screenshots output) with LFS routing for binary assets
expected: Repo hygiene keeps local tooling out of git (.claude/* except CLAUDE.md, .tools/, .godot/, build and screenshots output) with LFS routing for binary assets
result: pass
source: automated
coverage_id: 01-01/D5

### 21. Hold the action key on the House plot to build tier I through CommandProcessor; HUD gold drops by the tier I cost from house.tres
expected: Hold the action key on the House plot to build tier I through CommandProcessor; HUD gold drops by the tier I cost from house.tres
result: pass
source: automated
coverage_id: 01-02/D2

### 22. BuildIntent is re-validated on apply: unknown spot, unaffordable, max tier and not-day are rejected with a reason and change nothing; unknown intent rejected
expected: BuildIntent is re-validated on apply: unknown spot, unaffordable, max tier and not-day are rejected with a reason and change nothing; unknown intent rejected
result: pass
source: automated
coverage_id: 01-02/D3

### 23. Gold is the only currency, changes only via CommandProcessor/Economy, and never goes negative
expected: Gold is the only currency, changes only via CommandProcessor/Economy, and never goes negative
result: pass
source: automated
coverage_id: 01-02/D4

### 24. Windows export from the command line: bash tools/export.sh produces Duskhold.exe (109,268,480 B) and Duskhold.pck (50,204 B) with no rcedit/missing-template lines and no tests/GUT/tools packed; the release exe boots headless and exits 0
expected: Windows export from the command line: bash tools/export.sh produces Duskhold.exe (109,268,480 B) and Duskhold.pck (50,204 B) with no rcedit/missing-template lines and no tests/GUT/tools packed; the release exe boots headless and exits 0
result: pass
source: automated
coverage_id: 01-03/D1

### 25. CI workflow with independent lint and test jobs and an export job gated by needs [lint, test]; no path filters; permissions contents read; uploads duskhold-windows
expected: CI workflow with independent lint and test jobs and an export job gated by needs [lint, test]; no path filters; permissions contents read; uploads duskhold-windows
result: pass
source: automated
coverage_id: 01-03/D2

### 26. Pre-push safety check blocks tooling, generated output and credential-shaped strings across all history and lists author identities
expected: Pre-push safety check blocks tooling, generated output and credential-shaped strings across all history and lists author identities
result: pass
source: automated
coverage_id: 01-03/D3

### 27. King rides with WASD/arrows/left stick; walk 5.0 m/s, sprint about 1.6x, reaches the first build spot within the walk-time budget
expected: King rides with WASD/arrows/left stick; walk 5.0 m/s, sprint about 1.6x, reaches the first build spot within the walk-time budget
result: pass
source: automated
coverage_id: 01-04/D1

### 28. Diagonal input is not faster than cardinal; input below the 0.2 deadzone does not move the king
expected: Diagonal input is not faster than cardinal; input below the 0.2 deadzone does not move the king
result: pass
source: automated
coverage_id: 01-04/D2

### 29. Input Map contract: keyboard + gamepad per gameplay action matching the binding table, no mouse events, build and start_night share no key or button
expected: Input Map contract: keyboard + gamepad per gameplay action matching the binding table, no mouse events, build and start_night share no key or button
result: pass
source: automated
coverage_id: 01-04/D5

### 30. Prototype map is the 8-spot sandbox (5 House plots, 3 tower plots, castle at the middle, is_sandbox) and validates clean
expected: Prototype map is the 8-spot sandbox (5 House plots, 3 tower plots, castle at the middle, is_sandbox) and validates clean
result: pass
source: automated
coverage_id: 01-05/D1

### 31. Edge-to-edge ride takes 20 to 30 s at walk speed; starting gold buys two Houses or one tower but not both; tier data (House 3, tower 2) lives in .tres
expected: Edge-to-edge ride takes 20 to 30 s at walk speed; starting gold buys two Houses or one tower but not both; tier data (House 3, tower 2) lives in .tres
result: pass
source: automated
coverage_id: 01-05/D2

### 32. Spot rules: nearer spot wins, exact tie goes to the earlier spot, distance == radius is in range, empty map yields no focus, unknown or empty id is unknown_spot
expected: Spot rules: nearer spot wins, exact tie goes to the earlier spot, distance == radius is in range, empty map yields no focus, unknown or empty id is unknown_spot
result: pass
source: automated
coverage_id: 01-05/D3

### 33. Holding at a built House or tower upgrades it tier by tier with each tier's cost; max tier is rejected with max_tier and gold unchanged
expected: Holding at a built House or tower upgrades it tier by tier with each tier's cost; max tier is rejected with max_tier and gold unchanged
result: pass
source: automated
coverage_id: 01-05/D4

### 34. MapConfig.validate() rejects duplicate ids, dangling building ids, empty tier lists, non-positive costs, negative income and negative gold
expected: MapConfig.validate() rejects duplicate ids, dangling building ids, empty tier lists, non-positive costs, negative income and negative gold
result: pass
source: automated
coverage_id: 01-05/D5

### 35. Hold is all-or-nothing: early release or leaving range refunds every dripped coin with gold and buildings unchanged; a later hold starts from zero and pays the tier cost once
expected: Hold is all-or-nothing: early release or leaving range refunds every dripped coin with gold and buildings unchanged; a later hold starts from zero and pays the tier cost once
result: pass
source: automated
coverage_id: 01-06/D1

### 36. Focus is locked to the active spot while holding, a completed hold needs a fresh press, and a hold is refunded if building stops being allowed
expected: Focus is locked to the active spot while holding, a completed hold needs a fresh press, and a hold is refunded if building stops being allowed
result: pass
source: automated
coverage_id: 01-06/D2

### 37. Unaffordable, max-tier and night presses emit hold_denied exactly once per press, with no hold_started/hold_progress and no gold movement
expected: Unaffordable, max-tier and night presses emit hold_denied exactly once per press, with no hold_started/hold_progress and no gold movement
result: pass
source: automated
coverage_id: 01-06/D3

### 38. Label content (next-tier name, cost, effect, affordability, Max tier) is computed purely from RunContext data
expected: Label content (next-tier name, cost, effect, affordability, Max tier) is computed purely from RunContext data
result: pass
source: automated
coverage_id: 01-06/D4

### 39. Every third-party file is logged with source, licence, author, retrieval date and SHA256; the log is test-enforced (CC0-1.0/MIT only, full coverage, sorted, no nested paths)
expected: Every third-party file is logged with source, licence, author, retrieval date and SHA256; the log is test-enforced (CC0-1.0/MIT only, full coverage, sorted, no nested paths)
result: pass
source: automated
coverage_id: 01-07/D1

### 40. House tiers I-III, tower tiers I-II and the castle center render CC0 model wrapper scenes; taller/bigger per tier; primitive fallback still works
expected: House tiers I-III, tower tiers I-II and the castle center render CC0 model wrapper scenes; taller/bigger per tier; primitive fallback still works
result: pass
source: automated
coverage_id: 01-07/D2

### 41. Every committed GLB and PNG under assets/third_party/ is an LFS object and no reference-game name appears in game content
expected: Every committed GLB and PNG under assets/third_party/ is an LFS object and no reference-game name appears in game content
result: pass
source: automated
coverage_id: 01-07/D4

### 42. RunContext exposes unit and enemy counts (0 in Phase 1)
expected: RunContext exposes unit and enemy counts (0 in Phase 1)
result: pass
source: automated
coverage_id: 01-08/D1

### 43. Overlay model provides Perf/Loop/Agents sections with FPS, phase, gold, buildings, units, enemies and appends registered sections
expected: Overlay model provides Perf/Loop/Agents sections with FPS, phase, gold, buildings, units, enemies and appends registered sections
result: pass
source: automated
coverage_id: 01-08/D2

### 44. Reading the overlay 200 times never changes gold, phase or buildings and emits no simulation event
expected: Reading the overlay 200 times never changes gold, phase or buildings and emits no simulation event
result: pass
source: automated
coverage_id: 01-08/D3

### 45. Overlay is hidden by default, toggles on the toggle_debug_overlay action, lists the required fields and refreshes the Buildings row within 0.5 s of a build
expected: Overlay is hidden by default, toggles on the toggle_debug_overlay action, lists the required fields and refreshes the Buildings row within 0.5 s of a build
result: pass
source: automated
coverage_id: 01-08/D4

### 46. The day ends only through start_night; the loop runs DAY, NIGHT_TRANSITION, NIGHT (placeholder timer), DAWN, then the next DAY, one transition per tick, numbered days and nights
expected: The day ends only through start_night; the loop runs DAY, NIGHT_TRANSITION, NIGHT (placeholder timer), DAWN, then the next DAY, one transition per tick, numbered days and nights
result: pass
source: automated
coverage_id: 01-09/D1

### 47. validate_build and submit(BuildIntent) return not_day in NIGHT and DAWN with gold and buildings unchanged; a build hold in progress is cancelled when the night starts
expected: validate_build and submit(BuildIntent) return not_day in NIGHT and DAWN with gold and buildings unchanged; a build hold in progress is cancelled when the night starts
result: pass
source: automated
coverage_id: 01-09/D2

### 48. Dawn pays each House its current tier income once, in MapConfig order; upgraded, tier-equal, tower and empty cases behave as specified
expected: Dawn pays each House its current tier income once, in MapConfig order; upgraded, tier-equal, tower and empty cases behave as specified
result: pass
source: automated
coverage_id: 01-09/D3

### 49. Unspent gold carries over unchanged across three full cycles with exact expected totals derived from the .tres data; the payout is the only gold change over a night
expected: Unspent gold carries over unchanged across three full cycles with exact expected totals derived from the .tres data; the payout is the only gold change over a night
result: pass
source: automated
coverage_id: 01-09/D4

### 50. Gold is the only currency in the HUD and its label is always visible
expected: Gold is the only currency in the HUD and its label is always visible
result: pass
source: automated
coverage_id: 01-09/D5

### 51. Hold-to-confirm input: tap keeps the day and resets the fill, a full hold starts one night, input is ignored outside the day and after a held-through night, banner text and prompt visibility follow the phase
expected: Hold-to-confirm input: tap keeps the day and resets the fill, a full hold starts one night, input is ignored outside the day and after a held-through night, banner text and prompt visibility follow the phase
result: pass
source: automated
coverage_id: 01-09/D6

### 52. At dawn each paying House sends one coin per gold to the gold counter, the counter lags the ledger while they fly and settles exactly on it, and a '+X gold' total (derived from house.tres) appears and fades
expected: At dawn each paying House sends one coin per gold to the gold counter, the counter lags the ledger while they fly and settles exactly on it, and a '+X gold' total (derived from house.tres) appears and fades
result: pass
source: automated
coverage_id: 01-10/D1

### 53. A dawn that pays 0 spawns no coins and shows no '+0 gold'
expected: A dawn that pays 0 spawns no coins and shows no '+0 gold'
result: pass
source: automated
coverage_id: 01-10/D2

### 54. bash tools/screenshot.sh saves six non-empty PNGs locally and in CI; the runner exits 2 under --headless and rejects blank images
expected: bash tools/screenshot.sh saves six non-empty PNGs locally and in CI; the runner exits 2 under --headless and rejects blank images
result: pass
source: automated
coverage_id: 01-10/D3

### 55. Every push runs lint, test, export and screenshots in CI and the phase is green on origin
expected: Every push runs lint, test, export and screenshots in CI and the phase is green on origin
result: pass
source: automated
coverage_id: 01-10/D4

### 56. Re-check after gap closure: camera framing and zoom
expected: Ride the king around the map at the new default camera distance, then hold the zoom keys (- and =, or keypad - and +, or right stick down and up) through the whole range. Expected: At spawn the castle and first ring of House plots frame comfortably around a king who is still readable at about 25 m; the zoom range (0.7x to 1.5x, 0.6 units/s) feels right and the king is neither too small zoomed out nor too close zoomed in
result: pass

### 57. Re-check after gap closure: king silhouette behind buildings
expected: Ride behind the castle keep (and a House) and look at the king in a real window, by day and by night. Expected: The hidden part of the king shows as a flat light-cyan silhouette over the building, reads as 'the king is here', and is not distracting or ugly (the rider/horse silhouette looks thin and stalk-like from above in the king_behind_keep capture)
result: pass

### 58. Re-check after gap closure: build hold length
expected: Hold the action key at a House plot (House I, then II and III) and at a tower plot, and release early once. Expected: At 0.3 s per coin the hold (House I about 0.6 s, tower I about 1.2 s) feels 'a bit longer' and deliberate without dragging; the coin stream still reads as one coin at a time
result: issue
reported: "this is better. However, I think we should start with 0.25s per coin, and accelerate (since there will be buildings at some point that require e.g. 15 coins or even more). And set a max time limit too so for example set 3 seconds as the maximum time it takes, even if only half the coins are filled, just fast forward to full coin usage if that is possible given the current coins."
severity: minor

## Summary

total: 58
passed: 54
issues: 3
pending: 0
skipped: 1
blocked: 0

## Gaps

- gap_id: G-01-3
  truth: "The camera keeps one fixed angle (the player cannot rotate it), trails slightly behind the king and catches up, and keeps the king readable near the centre of the screen."
  status: resolved
  resolved_by: [01-11-PLAN.md, 01-12-PLAN.md]
  resolved_at: 2026-10-02
  reason: "User reported: mostly good, but when the king goes behind a building like behind the castle, his silhouette is not visible. The king disappears behind stuff basically. Is that intentional? / I think we should move the camera a bit further away. Also should have buttons that zoom out or zoom in, to a certain extent"
  severity: major
  test: 3
  root_cause: "Three causes. (1) Nothing lets the king show through geometry: the king model (presentation/king/king_model.tscn) uses plain opaque StandardMaterial3D surfaces with no x-ray, outline, overlay or fade, and buildings much taller than the king (castle keep 10.1 m vs king 2.6 m) fully cover him for several metres behind them at the fixed 55.5 degree pitch; moving the camera back does not fix this. (2) The camera offset is an untuned first-pass default: CameraRig.offset = Vector3(0, 16, 11) with fov 40 (camera_rig.gd:8, prototype_map.tscn:81-83), about 19.4 m from the king, framing only about 25 x 18 m of ground; plan 01-04 left it for playtest tuning and the in-window framing check was never done. (3) Zoom was deliberately excluded in plan 01-04 (\"no zoom, no orbit, no mouse\", camera_rig.gd:4); there is no zoom action, state or logic."
  artifacts:
    - path: "presentation/king/king_model.tscn"
      issue: "king surface materials are opaque StandardMaterial3D with no x-ray/silhouette when occluded"
    - path: "presentation/buildings/models/castle_center.tscn"
      issue: "tall opaque keep (10.1 m) fully hides the king behind it; no collision (buildings only), so the king can ride into it"
    - path: "presentation/camera/camera_rig.gd"
      issue: "offset (0,16,11) first-pass default; no zoom state or input; one-time look_at in bind_run"
    - path: "presentation/map/prototype_map.tscn"
      issue: "Camera3D fov 40 set only in the scene, not exported; no offset override"
    - path: "project.godot"
      issue: "no zoom_in / zoom_out actions in [input]"
    - path: "tests/unit/test_input_map.gd"
      issue: "binding-table contract new zoom actions must join (keyboard + gamepad, no mouse)"
    - path: "tests/e2e/test_king_ride.gd"
      issue: "follow tests read rig.offset live; zoom must keep them coherent"
    - path: "ui/world/spot_label.tscn"
      issue: "world-sized labels (pixel_size 0.01) shrink as the camera pulls back, capping zoom-out for legibility"
  missing:
    - "Show the king when he is behind geometry: Godot 4.7 BaseMaterial3D stencil X-Ray (stencil_mode + stencil_color) on the king surface materials works in Forward+ and Compatibility with no false tint in the open (debugger-verified)"
    - "Move the default camera further out along the same fixed angle (about 1.25-1.5x the current 19.4 m) and re-check spot-label legibility"
    - "Add clamped zoom in/out as new Input Map actions with keyboard and gamepad bindings (no mouse; candidates: -/= or PgUp/PgDn, right stick Y or D-pad up/down), moving only along the fixed offset direction so the angle never changes (KING-02); update test_input_map tables and keep test_king_ride follow tests passing"
    - "Optional: add a screenshot scenario with the king behind the castle keep; optionally give buildings collision so the king cannot ride inside them"
  debug_session: .planning/debug/camera-occlusion-zoom.md

- gap_id: G-01-4
  truth: "Holding the action key at a plot builds or upgrades it over a hold that feels deliberate (map, plots and tier growth otherwise passed)."
  status: resolved
  resolved_by: 01-13-PLAN.md
  resolved_at: 2026-10-02
  reason: "User reported: pass. But the building count up time is too short. needs tweaking to make it a biiiit longer (orchestrator note: coin_drip_interval is 0.2 s per coin in data/tuning/loop_tuning.tres, so House I completes in about 0.4 s)"
  severity: minor
  test: 4
  root_cause: "Tuning, not a code bug: hold time is exactly cost x coin_drip_interval with no minimum (input/build_hold_controller.gd:91-102), and coin_drip_interval = 0.2 s (data/tuning/loop_tuning.tres:7) is the fast end of D-05's 0.15-0.3 s placeholder range, so the common early builds finish in 0.4 s (House I) and 0.6 s (House II), well under the 1.5 s start-night hold that is the game's existing \"deliberate\" reference. Measured in the real game: completion times match cost x 0.2 to within a frame."
  artifacts:
    - path: "data/tuning/loop_tuning.tres"
      issue: "coin_drip_interval = 0.2 s per coin (main lever)"
    - path: "simulation/defs/loop_tuning.gd"
      issue: "matching script default 0.2"
    - path: "input/build_hold_controller.gd"
      issue: "straight per-coin model, no minimum hold"
    - path: "presentation/vfx/coin_drip_vfx.gd"
      issue: "coin flight capped at 0.18 s; a slower drip shows gaps between coins unless the cap is raised"
  missing:
    - "Raise coin_drip_interval to about 0.3 s (top of the D-05 range; House I 0.6 s, House III 1.5 s) in loop_tuning.tres and the script default"
    - "Optionally raise the coin flight cap (MAX_FLIGHT_SECONDS 0.18 -> about 0.27) so coins still fly for about 90% of each interval"
    - "Tests that compute waits from the live value scale automatically; check test_build_hold_refund 3.0 s timeouts and the screenshot HOLD_INTERVALS still hold"
  debug_session: .planning/debug/build-hold-too-short.md

- gap_id: G-01-58
  truth: "Hold the action key at a House plot (House I, then II and III) and at a tower plot, and release early once. Expected: At 0.3 s per coin the hold (House I about 0.6 s, tower I about 1.2 s) feels 'a bit longer' and deliberate without dragging; the coin stream still reads as one coin at a time"
  status: failed
  reason: "User reported: this is better. However, I think we should start with 0.25s per coin, and accelerate (since there will be buildings at some point that require e.g. 15 coins or even more). And set a max time limit too so for example set 3 seconds as the maximum time it takes, even if only half the coins are filled, just fast forward to full coin usage if that is possible given the current coins."
  severity: minor
  test: 58
  artifacts: []
  missing: []

## Deferred Follow-Ups

- test: 4
  idea: "yes, but a small minimap would be nice"
  deferred_at: 2026-10-01
