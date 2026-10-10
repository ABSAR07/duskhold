---
phase: 03-king-combat-troops
plan: 10
subsystem: ui
tags: [godot, gdscript, input-prompts, kenney, glyphs, device-detection, command-hints, hud]

requires:
  - phase: 03-king-combat-troops
    provides: "03-09 pad layout (LB layer, Start group mode, R3, RT queue, B cancel), PadChords, the Toast prompt slot with the armed lines; 03-07 and 03-08 armed-command lines and toasts that share the slot above the squad strip; 03-06 SelectionModel, Toast and the F/H/R/Tab/F2 verbs; 03-04 KingWidget plate and the ability action; 03-03 HudRoot and the protected-centre contract"
provides:
  - "assets/third_party/kenney_input_prompts: Kenney Input Prompts 1.5 (CC0, zip sha256 ac2fcf59... checked before extraction), the licence file, 53 keyboard and mouse tiles and 21 Xbox tiles, logged in assets/attribution.json and ASSETS.md"
  - "GlyphResolver: an action and a device to the first binding's Kenney tile, or a text keycap when the pack has none, or '(unbound)'; keys named by the layout label so Dvorak and AZERTY stay right"
  - "PromptGlyph: a fixed 24 or 32 px tile on a #14141A plate or a #3A3F4B keycap, re-rendered by one device_changed signal, and noticing a runtime rebind itself"
  - "DeviceModel and LastDeviceTracker: pure device rule with an injected clock (axis 0.5, 8 px of motion in 0.25 s, one switch per 0.25 s) and the node that emits device_changed, hides the cursor on the pad and falls back to the keyboard when the pad leaves; MapRoot.get_device_tracker()"
  - "Start-night prompt 'Hold [glyph] to start Night N', a 24 px glyph on the slam badge, and CommandHints (Follow, Hold, Rally, Move, Attack, Patrol, Queue with glyphs, LB + D-pad chords on the pad) in the toast slot, yielding to a toast or an armed line through Toast.is_occupied"
affects: [03-11, 03-12, phase-13-controls-menu]

actuals:
  tokens: 25650
  tasks: 2
  commits: 4

plan_head_before: 4dd84fcb4ffa48fc0c731f5b7e8609fa8ac96d23
plan_head_after: 000488fd939845efb572615398fae72218fd1280
commits: 4

tech-stack:
  added: []
  patterns:
    - "One device_changed signal re-renders every prompt in the same call; each PromptGlyph also compares its own binding signature once a frame while on screen, so a runtime rebind needs no owner code"
    - "The tracker is the last child of the map, so it is the first to see each event (input goes to later nodes first) and a controller that handles an event cannot hide it from the tracker; it never marks anything handled"
    - "A text keycap is a child of a PromptGlyph only while a keycap is shown, so a tile glyph holds no Label (the HUD label-size and king-widget footprint tests keep their counts and extents)"
    - "A prompt state that headless Godot cannot store (Input.mouse_mode) is exposed as the state the node asked for (cursor_hidden) and the real mode is read in a real-window probe"

key-files:
  created:
    - assets/third_party/kenney_input_prompts/License.txt
    - assets/third_party/kenney_input_prompts/keyboard_mouse/ (53 tiles)
    - assets/third_party/kenney_input_prompts/xbox/ (21 tiles)
    - ui/hud/glyph_resolver.gd
    - ui/hud/prompt_glyph.gd
    - ui/hud/command_hints.gd
    - input/device_model.gd
    - input/last_device_tracker.gd
    - tests/unit/test_glyph_resolver.gd
    - tests/unit/test_prompt_glyph.gd
    - tests/unit/test_device_model.gd
    - tests/e2e/test_prompt_switch.gd
    - tests/e2e/test_command_hints.gd
  modified:
    - assets/attribution.json
    - ASSETS.md
    - ui/hud/hud.gd
    - ui/hud/hud.tscn
    - ui/hud/king_widget.gd
    - ui/hud/toast.gd
    - presentation/map/map_root.gd
    - presentation/map/prototype_map.tscn
    - tests/e2e/test_start_night_hold.gd

key-decisions:
  - "Sticks use the text tiles xbox_ls and xbox_rs (the plan's right-stick candidates xbox_stick_r and xbox_rs were viewed on a #14141A plate at 24 px: the pictorial stick reads as a blur of rings, the RS text stays legible); R3 uses xbox_stick_r_press; both directions of a stick axis share the stick tile, and keycap_text still tells Axis 0- from Axis 0+"
  - "A shown glyph wider than its tile (a long key name, the unbound keycap) is anchored on the bottom-right corner of the slam plate and may extend 12 px left of it, so it stays on screen; it then overlaps the icon, which is acceptable for a rebind edge case"
  - "The hint row fades in over 0.15 s but hides at once (whether a toast takes the slot, the selection empties or the squads go), so it never overlaps a toast that fades in over 0.1 s"
  - "Hud no longer builds a text hint: START_NIGHT_PROMPT, UNBOUND_HINT, _hint and _start_night_hint were removed and the gamepad and trigger names moved to GlyphResolver; Hud keeps physical_label_resolver and hands it to the start-night glyph through a lambda, so a resolver replaced after the HUD is up still counts"
  - "Non-Xbox pads show Xbox glyphs until Phase 13 (as planned); the controls menu is the place to key tiles off the pad family"

patterns-established:
  - "RED with inert skeletons committed beside failing tests, then GREEN, for both tasks (the pack, attribution, scene nodes and constants are configuration and land with the RED commit)"
  - "A mutation probe on the stick threshold (>= made > in DeviceModel) failed 'test_a_stick_at_half_travel_switches_and_just_under_does_not', then the real code was restored"

requirements-completed: [INPT-02, UI-01, KING-04]

coverage:
  - id: D1
    description: "The prompt tiles are Kenney Input Prompts 1.5 (CC0), downloaded without redirects, size and sha256 checked before extraction, only the resolver's tiles and the licence kept (no .url files), logged in attribution.json and ASSETS.md between kenney-fantasy-town-kit and kenney-mini-characters"
    requirement: INPT-02
    verification:
      - kind: unit
        ref: "tests/unit/test_attribution_log.gd (17 tests, every file under assets/third_party/kenney_input_prompts belongs to the kenney-input-prompts entry, order in both files)"
        status: pass
    human_judgment: false
  - id: D2
    description: "GlyphResolver maps every action's first binding on the keyboard or the pad to an existing tile (keys by layout label, mouse by button, pad buttons, D-pad, triggers, sticks), falls back to a text keycap for a chord or a key without a tile, and reads '(unbound)' when the device has no binding; PromptGlyph draws it at a fixed 24 or 32 px and widens a keycap for a long key name"
    requirement: INPT-02
    verification:
      - kind: unit
        ref: "tests/unit/test_glyph_resolver.gd (13 tests), tests/unit/test_prompt_glyph.gd (8 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "DeviceModel boundaries: a stick at abs 0.5 switches and 0.49 does not, 8 px of motion inside 0.25 s switches and 7 px or 8 px spread over a longer time does not, a mouse button counts as keyboard, a second switch inside 0.25 s is ignored and one at 0.25 s applies, a pad disconnect falls back"
    requirement: INPT-02
    verification:
      - kind: unit
        ref: "tests/unit/test_device_model.gd (12 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "One device_changed switches the start-night glyph, the slam badge and every hint glyph in the same call, mouse input counts as keyboard, a quarter-second debounce holds, the cursor is hidden while the pad is active and a disconnect of the pad in use falls back to the keyboard; a switch during the start-night hold swaps the glyph and leaves the fill and timer alone"
    requirement: INPT-02
    verification:
      - kind: e2e
        ref: "tests/e2e/test_prompt_switch.gd (7 tests), tests/e2e/test_start_night_hold.gd#test_a_device_switch_during_the_hold_swaps_the_glyph_and_leaves_the_hold_alone"
        status: pass
    human_judgment: false
  - id: D5
    description: "The start-night prompt reads 'Hold [glyph] to start Night N' with a 32 px glyph and follows rebinds, layout labels, triggers, sticks and mouse buttons; the slam badge carries a 24 px glyph of the ability action"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_start_night_hold.gd (16 tests), tests/e2e/test_king_widget.gd (14 tests, footprint and label counts unchanged), tests/e2e/test_prompt_switch.gd"
        status: pass
    human_judgment: false
  - id: D6
    description: "While a squad is selected the strip lists Follow, Hold, Rally, Move, Attack, Patrol, Queue left to right with their glyphs (pad point verbs as LB + D-pad pairs joined by '+') in y 504..536, 8 px above the squad strip and below the protected centre; with no squad or no selection it is hidden and shows no placeholder; a toast or an armed line takes the slot and the strip returns when it ends; a second toast replaces the first in the same slot"
    requirement: KING-04
    verification:
      - kind: e2e
        ref: "tests/e2e/test_command_hints.gd (10 tests, layout measured in a 1280x720 SubViewport)"
        status: pass
    human_judgment: false
  - id: D7
    description: "How the tiles read at 24 px (the D-pad tiles are a cross with one arm lit, the Shift and Q-key tiles are small), whether the glyph-and-word rows feel balanced, and how the glyphs look on a real non-Xbox pad"
    verification: []
    human_judgment: true
    rationale: "Legibility and taste are the owner's; no real pad was available, so the glyph switch was driven with scripted joypad events in a real window (Forward+, RTX 3060): the captures show the hint row at x 317..964 on the keyboard and x 252..1028 on the pad at 1280x720 and 1280x800, Input.mouse_mode 1 (hidden) on the pad and 0 on the keyboard, the toast replacing the row, and a Backspace and an unbound badge widening without clipping"

duration: 66min
completed: 2026-10-10
status: complete
---

# Phase 3 Plan 10: Device Prompts and Command Hints Summary

**Kenney Input Prompts tiles (CC0, hash-checked, logged) behind one GlyphResolver with a text keycap fallback, a DeviceModel and LastDeviceTracker that switch every prompt in the same call when the player touches the pad or the keyboard, a glyph start-night prompt and slam badge, and a CommandHints strip that lists the seven squad verbs with their keys or buttons in the toast slot**

## Performance

- **Duration:** 66 min
- **Started:** 2026-10-10T19:11:00Z (approximate; the first command ran about 19:13Z)
- **Completed:** 2026-10-10T20:17:48Z (code at 20:1x); SUMMARY and tracking follow
- **Tasks:** 2 (both TDD, RED then GREEN each)
- **Files modified:** 178 per `git diff --name-only 4dd84fc HEAD` (74 of them are the PNG tiles and their .import files)

## Accomplishments

- **Glyph pack (Task 1):** the zip was fetched with `curl --fail` and no redirects (5,070,075 bytes, sha256 `ac2fcf59...ab78a1`, both checked before extraction), extracted with `python -I` into a scratch directory outside the repository, and only the licence file, 53 keyboard and mouse tiles (a-z, 0-9, space, shift, ctrl, tab, escape, enter, the arrows, F2, F3, equals, minus, numpad plus, mouse left and right) and 21 Xbox tiles (A/B/X/Y and their colour twins, LB, RB, LT, RT, the four D-pad tiles, Back, Start, the two stick text tiles, the right-stick press) were copied. No `.url` file is kept; PNGs go through Git LFS. The `kenney-input-prompts` entry sorts between `kenney-fantasy-town-kit` and `kenney-mini-characters` in attribution.json and ASSETS.md, and ASSETS.md gains an archive-checksum note.
- **Resolver and glyph (Task 1):** `GlyphResolver.first_event` finds the first binding on the keyboard (a key or mouse button) or the pad (a button or axis); `tile_path` maps it to a tile and returns "" for a chord, a key the pack does not draw, a middle mouse button or a left stick press; `keycap_text` gives the key with its modifiers, a button or trigger by name, or "(unbound)". The layout-safe key naming and the pad names moved here from `Hud`. `PromptGlyph` draws the tile on a #14141A plate at alpha 0.78 or the keycap (radius 4, #3A3F4B, 2 px #C8CCD4 border, Label 18) at 24 or 32 px, and notices a runtime rebind within a frame.
- **Device tracking (Task 2):** `DeviceModel` is a pure rule on an injected clock; `LastDeviceTracker` feeds it from `_input`, emits `device_changed`, hides the mouse on the pad, restores it on the keyboard and when it leaves the tree, and falls back to the keyboard when the pad in use disconnects. It is the last child of the map so it sees each event first, and it never handles an event.
- **Prompts (Task 2):** the start-night prompt is an HBox "Hold", a 32 px glyph, "to start Night N"; the slam badge carries a 24 px glyph at the bottom-right of the plate; `CommandHints` shows the seven verbs with 24 px glyphs and 18 px words in the toast slot (offset -216..-184, so y 504..536 at 720), separation 16. On the pad Move, Attack and Patrol show LB, a "+" and the D-pad tile. It shows while the selection is non-empty and the toast is not occupied, fading in over 0.15 s, and hides at once otherwise; `Toast.is_occupied()` is a toast in progress or an armed line.
- **Self-verification:** a real-window probe (Forward+, RTX 3060, scratch script outside the repo) captured the hint row, the start-night glyph and the badge on both devices at 1280x720 and 1280x800, the toast replacing the row, and the Backspace and unbound badges; `Input.mouse_mode` read 1 (hidden) on the pad and 0 on the keyboard. A mutation probe (`>=` made `>` on the stick threshold) failed the half-travel test, then the real code was restored.
- Suite: 142 scripts / 1306 tests at baseline to 147 scripts / 1358 tests, all passing (15223 asserts, exit 0); lint clean; smoke digest `2599c7c2...` and army digest `f7a967ed...` byte-identical (`REPLAY_OK`, `--twice`).

## Task Commits

1. **Task 1 RED:** `f0da274` test(03-10): failing resolver tests, with the hash-checked CC0 prompt tiles
2. **Task 1 GREEN:** `3d2901e` feat(03-10): resolve any action on either device to a tile or a text keycap
3. **Task 2 RED:** `44608e0` test(03-10): failing tests for the device tracker, the prompt switch and the command hints
4. **Task 2 GREEN:** `000488f` feat(03-10): every prompt follows the device, and a command hint strip shows while squads are selected

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The mouse mode cannot be asserted headless**
- **Found during:** Task 2 (planning test_prompt_switch)
- **Issue:** the plan asks for `Input.mouse_mode` HIDDEN after a pad press, but the headless display server does not store the mode (it reads 0 after setting HIDDEN), so no headless test can see it.
- **Fix:** `LastDeviceTracker.cursor_hidden()` reports the state the tracker asked for and the e2e tests assert it; the real engine mode was read in a real-window probe (1 on the pad, 0 on the keyboard).
- **Files modified:** input/last_device_tracker.gd, tests/e2e/test_prompt_switch.gd
- **Commit:** 000488f

**2. [Rule 1 - Bug] A tile glyph still held an invisible keycap that the HUD tests counted**
- **Found during:** Task 2 (test_king_widget: bottom 706 > 704 and 3 labels where 2 were expected)
- **Issue:** the hidden keycap child of a PromptGlyph still has a size and a Label, so the king widget footprint grew 2 px and its label count rose by one.
- **Fix:** the keycap is a child only while a keycap is shown; it is freed on delete when it is not in the tree.
- **Files modified:** ui/hud/prompt_glyph.gd
- **Commit:** 000488f

**3. [Rule 1 - Bug] A long key name on the slam badge ran off the left of the screen**
- **Found during:** Task 2 (real-window capture with the ability bound to Backspace)
- **Issue:** anchoring the glyph's right edge to the plate pushed a 65 px keycap past x 0.
- **Fix:** the glyph may extend at most 12 px left of the plate (`GLYPH_MIN_X`); Backspace now reads in full, the unbound keycap overlaps the icon.
- **Files modified:** ui/hud/king_widget.gd
- **Commit:** 000488f

### Plan adaptations

- **PromptGlyph.bind_device lands in Task 2** (the plan lists the file under Task 1): it names `LastDeviceTracker`, which does not exist until Task 2, so Task 1 kept the glyph pure (render, rebind detection) and Task 2 added the subscription.
- **test_start_night_hold.gd was rewritten, not just adjusted:** the old assertions read one combined string ("Hold N / (Y) to start Night 1"). The prompt now shows one device's glyph, so the same facts are asserted per device: the key then the pad button on their own device, the layout label, the in-place edit, a trigger, a mouse button and a stick (each as a tile or keycap text), a chord and a blank event; stick directions share one tile, and `keycap_text` is asserted to still tell Axis 0- from Axis 0+. Two tests were added (the glyph-row structure and the mid-hold device switch), 14 to 16 tests.
- **tests/unit/test_prompt_glyph.gd** (8 tests) was added beside the plan's list for the tile, size, unbound, one-device, no-tile, Backspace, layout label and rebind behaviours of the glyph.
- **The tracker has a `time_source` Callable** (default `Time.get_ticks_msec`), so the e2e tests step the 0.25 s debounce by hand instead of waiting.
- **Remaining text:** `Hud` lost `START_NIGHT_PROMPT`, `UNBOUND_HINT`, `_hint` and `_start_night_hint` (no other file used them); the gamepad names moved to `GlyphResolver`.

**Total deviations:** 3 auto-fixed (1 Rule 3, 2 Rule 1), plus the adaptations above. **Impact:** none on the simulation (both goldens unchanged); the UI-SPEC rows are met.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. T-03-16 (download tampering) is mitigated as planned (no redirects, size and sha256 before extraction, `python -I`, named PNGs and the licence only, no `.url` files, hash in the attribution entry). T-03-17 (device flicker) is mitigated and each boundary is covered by test_device_model. The tracker is input-layer code that never marks an event handled.

## Open Items for the Owner (UAT)

- Whether the tiles read well at 24 px on a real monitor and a real pad (D-pad tiles are a cross with one arm lit; the Shift tile is small).
- Non-Xbox pads show Xbox tiles until Phase 13.
- Fast-forward keeps its text label, and the results screen buttons stay text (menus are Phase 13), as planned.

## Next Phase Readiness

03-11 and 03-12 can rely on `LastDeviceTracker`, `PromptGlyph` and `CommandHints` in the HUD; the pad layout of 03-09 is now shown on screen. Ready for 03-11.

## Self-Check: PASSED

- Files found: ui/hud/glyph_resolver.gd, ui/hud/prompt_glyph.gd, ui/hud/command_hints.gd, input/device_model.gd, input/last_device_tracker.gd, assets/third_party/kenney_input_prompts/License.txt, the five new test files.
- Commits found: f0da274, 3d2901e, 44608e0, 000488f.
- Full suite 147 scripts / 1358 tests passing, lint clean, both replay digests unchanged.
