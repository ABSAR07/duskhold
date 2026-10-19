---
status: diagnosed
trigger: "UAT Phase 04, Test 6, gap G-04-6 (cosmetic): at 1280x720 the F3 debug overlay's right column runs over the HUD's night banner (\"Night N of 8 — 300 enemies left\") and hides its last word."
created: 2026-10-19T05:13:59Z
updated: 2026-10-19T05:21:45Z
---

## Current Focus

hypothesis: CONFIRMED. The overlay Panel is right-anchored and grows left by its content width with no cap; plan 04-08's second column (220 px + 16 px separation) widened it from about 185 px to 421 px on the stress night, so its left edge (x 847) passes the centred banner's right edge (x 909). Both sit in the top band (panel y 12..609, banner y 45..95), and the overlay's CanvasLayer (layer 100) draws over the HUD (layer 1).
test: done (real-window probe at 1280x720, 1920x1080 requested, and the shipped-map overlay_paths night)
expecting: n/a
next_action: return ROOT CAUSE FOUND (goal find_root_cause_only); no fix applied
bug_class: Bohrbug (deterministic layout)
reasoning_checkpoint:
  hypothesis: "The night banner's last word is hidden because DebugOverlay/Panel (anchor 1.0, offset_right -12, grow_horizontal BEGIN, offset_top 12, no width cap) grows left to x = 1268 - (left column + 16 + right column); with the 04-08 two-column split that is 1268 - 421 = 847 on the stress night, left of the banner's right edge 640 + 538/2 = 909, and the panel shares the banner's rows (y 12..609 vs 45..95)."
  confirming_evidence:
    - "Probe at 1280x720 on overlay_field_gate: banner rect (371,45) 538x50 end x 909; panel rect (847,12) 421x597; intersection (847,45) 62x50."
    - "Left column 185 px, right column 220 px, separation 16, panel stylebox margins 0: 185+16+220 = 421 exactly the panel width."
    - "git log -p ui/overlay/debug_overlay.tscn: the Panel anchors and offsets are unchanged since 86f04dc (01-08); 034a050 (04-08) only added Columns and OverlayTextRight."
  falsification_test: "If the panel were placed by something other than its content width (a fixed rect or a cap), the probe would show a panel width independent of the rows; it does not (369 px on the shipped night vs 421 px on the stress night, same scene)."
  fix_rationale: "Not applied (diagnose only). Moving the panel's top below the banner band removes the shared rows whatever the column widths, which addresses the cause (a content-sized panel in the banner's band) rather than one text length."
  blind_spots: "Real 1920x1080 could not be opened on this display (OS clamped the window to 1920x1050); 1080p numbers are derived from the stretch settings. The Linux CI fallback for SystemFont Consolas has different glyph widths, so any x-based guard would measure differently in CI."
  candidate_causes:
    - "code/scene: Panel anchoring and growth in ui/overlay/debug_overlay.tscn (confirmed)"
    - "config: project.godot stretch canvas_items + aspect expand keeps the logical canvas 1280 wide at every 16:9/16:10/4:3 size, so a bigger window does not help (contributing, not a cause)"
    - "data: banner text length (3-digit counts on the stress map) widens the banner to 538 px (contributing; the shipped map collides from two-digit counts)"
  and_gate: "yes: it needs (a) the panel in the banner's vertical band AND (b) panel width + half the banner width + 12 > half the logical width. (a) is fixed by the scene since Phase 1; (b) became true in 04-08. Removing either condition removes the overlap; the cheapest robust one to remove is (a)."

## Symptoms

expected: The field and paths are readable, the overlay panel does not hide what matters, and the sections answer "where are they going and who is stuck" (ROADMAP criterion 2). The HUD night banner stays fully readable with the overlay open at the project's supported window sizes (screenshots run at 1280x720; frame report at 1920x1080).
actual: In screenshots/overlay_field_gate.png (1280x720, tools/screenshot.sh) the night banner "300 enemies left" runs under the two-column overlay panel's right column and its last word is hidden. Overlay got its two-column layout in plan 04-08; banner from ui/hud/hud.gd (~line 209).
errors: None.
reproduction: bash tools/screenshot.sh -> overlay_field_gate.png; or run game at 1280x720, press F3 at night.
started: Since plan 04-08 widened the overlay to two columns.

## Eliminated

- hypothesis: "A larger window (1920x1080) gives the panel room, so only 720p is affected"
  evidence: "project.godot uses stretch canvas_items with base 1280x720 and aspect expand; the probe at a 1920 wide window ran in a 1316x720 logical canvas (window clamped to 1920x1050) and still overlapped by 44 px; an exact 16:9 window is logically 1280x720, identical to 720p (62 px)."
  timestamp: 2026-10-19T05:19:30Z

- hypothesis: "The right column's own text is what covers the banner"
  evidence: "Probe: OverlayTextRight is laid out at y 122..499 (vertically centred in the 597 px HBox row), below the banner's y 45..95. What covers the word 'left' is the panel's background and the left column's first rows (Perf / FPS / Loop), pushed left by the right column's 236 px (220 + 16 separation)."
  timestamp: 2026-10-19T05:19:30Z

- hypothesis: "Only the tools-only stress map collides"
  evidence: "Probe on overlay_paths (shipped map, night 1 of 8, '2 enemies left'): banner end x 888, panel start x 890 after a refresh, 2 px clear. Any two-digit count ('Night N of 8 — 45 enemies left', 518 px, end x 899) overlaps by about 9 px, more once 'Fastest breach: 12.3 s' or 'Next spawn: 12.5 s' rows lengthen."
  timestamp: 2026-10-19T05:20:30Z

## Evidence

- timestamp: 2026-10-19T05:15:00Z
  checked: ui/overlay/debug_overlay.tscn (Panel node, lines 14-23) and git log -p of it
  found: Panel is a PanelContainer, anchors_preset 1 (top-right), anchor_left = anchor_right = 1.0, offset_left -240, offset_top 12, offset_right -12, offset_bottom 52, grow_horizontal = 0 (GROW_DIRECTION_BEGIN, grows left), no custom_minimum_size and no max width. Unchanged since 86f04dc (01-08); 034a050 (04-08) only added Panel/Columns (HBoxContainer, separation 16) holding OverlayText and OverlayTextRight (Consolas 16 px). DebugOverlay CanvasLayer layer = 100.
  implication: the panel's left edge is 1268 - (left column width + 16 + right column width); a second column moves it far left.

- timestamp: 2026-10-19T05:15:30Z
  checked: ui/overlay/debug_overlay.gd _refresh (lines 144-168)
  found: whole sections fill the left column until it holds ceil(total/2) lines, the rest go right; both columns are plain Labels, width = longest line.
  implication: panel width is content-dependent (longest row in each column), widest on a busy night.

- timestamp: 2026-10-19T05:16:00Z
  checked: ui/hud/hud.tscn PhaseBannerBox (lines 131-145) and hud.gd _refresh_banner (lines 209-228)
  found: PhaseBannerBox is a CenterContainer, anchors_preset 10 (top-wide), anchor_right 1.0, offset_top 40, offset_bottom 100; PhaseBanner Label font 36 (Open Sans SemiBold, the default theme font; it is outside HudRoot), text "Night %d of %d — %s left". Centred on x 640, width follows the text.
  implication: banner right edge = 640 + text_width / 2.

- timestamp: 2026-10-19T05:16:30Z
  checked: screenshots/overlay_field_gate.png and screenshots/overlay_paths.png (both 1280x720)
  found: field_gate: banner spans about x 371..908, panel about x 847..1268, y 12..608; "left" is under the panel. overlay_paths: banner ends about x 888, panel starts about x 899 (stale overlay text, see below).
  implication: the collision depends on both texts; normal nights sit within a few px of it.

- timestamp: 2026-10-19T05:16:45Z
  checked: project.godot [display]
  found: viewport 1280x720, stretch mode canvas_items, aspect expand.
  implication: at 1920x1080 (and any 16:9, 16:10 or 4:3 window) the logical canvas is 1280 wide, so the overlap is the same in logical px.

- timestamp: 2026-10-19T05:17:00Z
  checked: tools/screenshot/shot_runner.gd, tests/e2e/test_hud_contract.gd, grep of tests/
  found: DebugOverlay is in ShotRunner.EXEMPT_NODES (line 35) and is test_hud_contract's EXEMPT_SUBTREE (line 24); the protected-centre check only runs on hud_/cmd_ shots; no test asserts the overlay Panel rect, its font size or the PhaseBanner x extent; overlay tests read rows through DebugOverlay.get_text() (both columns joined). test_hud_contract pins PayoutTotal (16,52), FastForwardLabel y 60, RespawnBox y 100, the DayCounter band y 16..56 and the font-size set [36, 28, 22, 18].
  implication: no gate covers banner-vs-overlay overlap; a layout change to the overlay moves no existing test.

- timestamp: 2026-10-19T05:18:30Z
  checked: real-window probe scratchpad/exec/debug-g6/probe_overlay_banner.gd, overlay_field_gate at --resolution 1280x720 (log run720.log, image res://build/debug-g6/overlay_field_gate_720.png)
  found: window 1280x720, logical 1280x720, scale 1. Banner 'Night 1 of 1 — 300 enemies left' rect (371,45) 538x50, end (909,95); box (0,40) 1280x60. Panel (847,12) 421x597, end (1268,609). Left column (847,12) 185x597 (longest '  Spawned: 300 of 300'); right column (1048,122) 220x377 (longest '  Fastest breach: 649.4 s'); separation 16; panel stylebox margins 0. Intersection (847,45) 62x50. FastForwardLabel rect (1020,60) 244x36, wholly inside the panel when shown. Consolas 16 advance 9 px; line pitch about 19.9 px (30 left rows = 597 px).
  implication: confirms the mechanism with exact numbers: overlap = 538/2 + 421 + 12 - 640 = 62 px.

- timestamp: 2026-10-19T05:19:30Z
  checked: same probe at --resolution 1920x1080 (run1080.log, res://build/debug-g6/overlay_field_gate_1080.png)
  found: OS gave a 1920x1050 window; logical canvas 1316x720 (scale 1.459); banner end x 927, panel start x 883, intersection 44x50 logical px; picture shows 'left' under the Perf / FPS / Loop rows.
  implication: 1080p-class windows are affected; only a logical width above 2 x (269 + 421 + 12) = 1404 px (aspect about 1.95, ultrawide) would clear the stress night.

- timestamp: 2026-10-19T05:20:30Z
  checked: same probe on overlay_paths (shipped prototype map, night 1 of 8) at 1280x720 (runpaths.log)
  found: at capture: banner end 888, panel start 899 (overlay text stale: 'Phase: DAY' because the scenario fast-forwards the sim faster than the 0.25 s real-time refresh); after one refresh: panel 378 px, start 890, 2 px clear (longest rows '  Next spawn: 1.0 s', '  Longest stuck: 0.6 s'). Banner widths at 36 px: 'Night 8 of 8 — 45 enemies left' 518 (end 899), 'Night 1 of 8 — 5 enemies left' 497 (end 888.5), 'Night 8 of 8 — 1 enemy left' 468 (end 874).
  implication: the shipped map collides too from two-digit counts; the gap is general, not a stress-map artefact.

## Resolution

root_cause: "DebugOverlay/Panel (ui/overlay/debug_overlay.tscn lines 14-23) is anchored top-right at offset_top 12, offset_right -12, grow_horizontal BEGIN, with no width cap, so its left edge is 1268 - content width. Plan 04-08 (034a050) put the rows in two columns (Panel/Columns, separation 16), raising the content width from one column (about 185 to 225 px) to left + 16 + right (421 px on the stress night: 185 + 16 + 220), which moves the left edge to x 847, left of the centred night banner's right edge x 909 (ui/hud/hud.tscn PhaseBannerBox lines 131-145: top-wide CenterContainer y 40..100, 36 px label 538 px wide). The panel occupies y 12..609, so it shares the banner's rows (45..95), and the overlay CanvasLayer (layer 100) draws its background and its left column's first rows (Perf / FPS / Loop) over the word 'left' (62 x 50 logical px). Under canvas_items stretch with aspect expand the logical canvas is 1280 wide at 16:9, 16:10 and 4:3, so 1920x1080 is affected identically."
fix: ""
verification: ""
files_changed: []
