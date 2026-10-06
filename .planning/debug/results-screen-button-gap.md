---
status: diagnosed
trigger: "UAT Test 2 (results screen layout) of Phase 2: the owner reports the vertical gap between the stat rows and the buttons is smaller than the gap between the stat rows themselves."
created: 2026-10-06T10:48:04Z
updated: 2026-10-06T10:56:00Z
---

## Current Focus

hypothesis: CONFIRMED. The Column VBoxContainer puts the same 12 px of layout separation between every child rect, but each 26 px stat Label rect holds about 9 px of empty font leading above its capitals (Open Sans SemiBold ascent 28 px vs cap height about 18.6 px), while the Buttons row has nothing above its face (the Button StyleBoxFlat fills the rect) and the focused Play again focus outline even expands 2 px above the rect. Perceived gap between stat rows = 28 px (baseline to next cap top); last stat row to Play again = 17 px (19 px to the Quit rect).
test: done (rect dump, pixel scan of an isolated render and of the real results_victory screenshot, in-memory variants adding 11 px above the Buttons)
expecting: n/a
next_action: none (diagnose-only); hand back ROOT CAUSE FOUND to the caller
bug_class: Bohrbug (deterministic layout, identical on every render)
reasoning_checkpoint:
  hypothesis: "The row-to-button gap reads smaller because VBoxContainer separation (12) is measured between control rects, and a Label rect includes about 9 px of invisible leading above the glyphs (ascent 28 minus cap height about 18.6 at 26 px) that the Button face does not, plus the focused button focus StyleBox expands 2 px upward."
  confirming_evidence:
    - "Rect dump: every Column gap is exactly 12 px (Knockouts 428..464, Buttons 476..524); labels are 36 px = ascent 28 + descent 8, Label normal stylebox margins 0; Button normal StyleBoxFlat expand_margin_top 0; focus StyleBoxFlat expand_margin_top 2, border 2."
    - "Pixel scan (Forward+, 1280x720): cap tops at rect top + 9 (293, 341, 389, 437), baselines at rect top + 28; baseline to next cap top = 28 px for every stat pair; last baseline 456 to Play again outline 474 = 17 px; identical rows in the real game screenshot (results_victory)."
    - "In-memory variant adding 11 px above Buttons (MarginContainer margin_top 11, or Buttons min height 59 + buttons SHRINK_END): baseline to outline 28 px and descender to outline 23 px, both exactly equal to the stat-row gaps; side-by-side render shows even spacing."
  falsification_test: "If label rects carried no leading above their glyphs (cap top at rect top), or if the button face started inside its rect, the measured gaps would not be 28 vs 17 px and adding 11 px above the buttons would not equalise both ink metrics. Measured: it does."
  fix_rationale: "Equalising needs the visible top of the button row to sit as far below the last baseline as each capital row does (28 px). Only the button row lacks the label leading, so the fix adds exactly that missing space (9 px leading + 2 px focus expand = 11 px) above the Buttons row only, leaving the stat rows untouched."
  blind_spots: "Measured at 1280x720 with no stretch mode; a future stretch/content scale or a different UI font would change the 9 px leading, so a fixed 11 px pad would then be slightly off. Defeat variant not measured separately (same scene and nodes). Unfocused Quit face is about 1/255 from the panel in both renders, so the owner perception rests on the Play again focus outline."
  candidate_causes:
    - "code/scene: Column separation applied rect to rect while Label rects include font leading above the capitals (CONFIRMED)"
    - "config/theme: a custom theme or overrides giving buttons/labels different margins (ELIMINATED: no theme, Label stylebox margins 0, Button face fills its rect)"
    - "environment: DPI or stretch scaling distorting spacing (ELIMINATED: viewport 1280x720, no stretch mode, rects are integers and match the render)"
  and_gate: "Yes, two contributors add up: (1) about 9 px of font leading above label capitals that buttons lack (the root, affects both buttons) and (2) the focus StyleBox expand_margin_top 2 on the focused Play again (only the focused button). (1) alone already leaves the gap 9 px short."
tdd_checkpoint: (n/a, diagnose-only)

## Symptoms

expected: Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel. (Everything else in the test passed: the accidental-restart tap and press feel.)
actual: stat rows have a gap between each other and between them and the buttons but the gap between the stat rows and the buttons is smaller than the gap within the stat rows. I think it should be equal. The rest is all good and passes (accidental-restart tap and press feel pass).
errors: None reported
reproduction: Test 2 in UAT (.planning/phases/02-night-defense-playtest-gate/02-UAT.md); gap id G-02-2
started: Discovered during UAT (2026-10-06)

## Eliminated

- hypothesis: The Button StyleBox content margins make the visible button face start inside its control rect, so 12 px looks smaller above a button
  evidence: Default-theme Button normal StyleBoxFlat has expand_margin_top 0 and draw_center true; the face is drawn over the whole rect (content margins 4/4 only inset the text). Pixel scan shows the focused outline at rect top - 2 (474 vs rect 476), i.e. the visible edge is OUTSIDE the rect, not inside. The direction is the opposite: the label side carries hidden space, the button side carries none.
  timestamp: 2026-10-06T10:50:30Z

- hypothesis: A theme resource, spacer node or extra margin container changes the spacing above the Buttons
  evidence: No project theme (project.godot has no gui/theme/custom), no Theme resource anywhere, no theme property on any node; Column holds only the five labels and Buttons; rect dump shows exactly 12 px between every pair.
  timestamp: 2026-10-06T10:49:30Z

- hypothesis: DPI or stretch scaling distorts the separation
  evidence: Root viewport 1280x720, project has no stretch mode; rect coordinates are whole pixels and match the rendered ink rows.
  timestamp: 2026-10-06T10:51:00Z

## Evidence

- timestamp: 2026-10-06T10:48:04Z
  checked: Knowledge base (.planning/debug/knowledge-base.md)
  found: File does not exist; no MemPalace available. No known-pattern candidate.
  implication: Investigate from scratch.

- timestamp: 2026-10-06T10:48:04Z
  checked: ui/results/results_screen.tscn (all 101 lines) and git history of that file
  found: Column VBoxContainer (line 37) has theme_override_constants/separation = 12 (line 39). Children in order OutcomeLabel (56 px font, line 41), NightsLabel, GoldLabel, BuildingsLostLabel, KnockoutsLabel (26 px font, lines 48-74), then Buttons HBoxContainer (line 76; separation 24 at line 78 is horizontal only). Buttons have custom_minimum_size (180, 48) (lines 83, 94) and font_size 24. No spacer node, no margin container around Buttons, no theme on any node, no size_flags overrides. File unchanged since creation in 8e32ea4.
  implication: Every pair of Column children gets exactly the same 12 px of layout separation; the visible difference must come from how much empty space each child carries inside its own rect.

- timestamp: 2026-10-06T10:48:04Z
  checked: ui/results/results_screen.gd (all 126 lines)
  found: Script only sets label text, visibility and focus; no layout code, no size or margin changes at runtime.
  implication: Layout is purely the scene plus the theme.

- timestamp: 2026-10-06T10:49:30Z
  checked: Theme in use (project.godot, every .tscn/.tres under ui/)
  found: project.godot sets no gui/theme/custom; no Theme resource exists; no node in results_screen.tscn has a theme property. The screen uses the Godot 4.7.2 built-in default theme plus the per-node overrides listed above.
  implication: Font = default Open Sans SemiBold; Label normal stylebox and Button styleboxes are the engine defaults.

- timestamp: 2026-10-06T10:50:30Z
  checked: Scratch SceneTree script (scratchpad/measure_results.gd) that loads ui/results/results_screen.tscn alone at 1280x720, fills realistic text, shows it, focuses Play again and prints rects and metrics (headless and windowed, Forward+ on RTX 3060)
  found: Every Column gap is exactly 12 px in layout (Outcome 195..272, Nights 284..320, Gold 332..368, BuildingsLost 380..416, Knockouts 428..464, Buttons 476..524). Each 26 px stat Label is 36 px tall = font ascent 28 + descent 8 (Open Sans SemiBold); Label normal stylebox margins 0; line_spacing 3 is not added for a single line. Buttons are 48 px (custom_minimum_size); normal StyleBoxFlat bg (0.1,0.1,0.1,0.6), expand_margin_top 0, so the face starts at the rect top. Focus StyleBoxFlat has border 2 and expand_margin_top 2, so the focused Play again outline is drawn 2 px ABOVE its rect (row 474).
  implication: The asymmetry is on the label side: a stat label rect carries about 9 px of empty font leading above its capitals that the button has no counterpart for, and the focus outline removes a further 2 px.

- timestamp: 2026-10-06T10:51:00Z
  checked: Pixel scan of the isolated render (scratchpad/results_alone.png, crop_panel.png) for rows holding any ink in the Column span
  found: Ink rows - Nights 293..317, Gold 341..359, BuildingsLost 389..413, Knockouts 437..461, buttons 474..525. Each row's capitals start 9 px below the rect top (293=284+9, 341=332+9, 389=380+9, 437=428+9); baselines sit at rect top + 28 (312, 360, 408, 456). Baseline to next cap top = 28 px for every stat pair (8 descent + 12 separation + 9 leading - 1). Last baseline (456) to Play again focus outline (474) = 17 px; to the Quit rect top (476) = 19 px. Ink to ink with descenders - stat-row gaps 23 to 29 px; Knockouts g descender (461) to Play again outline (474) = 12 px.
  implication: Quantitatively confirms the mechanism - perceived row gap 28 px vs row-to-button gap 17 to 19 px; the deficit is 9 px (cap-top leading) + 2 px (focus expand) for Play again, 9 px for Quit.

- timestamp: 2026-10-06T10:52:00Z
  checked: Real in-game screenshot via bash tools/screenshot.sh results_victory (git-ignored screenshots/results_victory.png, copied to scratchpad/results_victory_game.png); per-row max-brightness profile
  found: Same rows as the isolated render - Knockouts ink 437..461, Play again outline/face from 474, Quit text from 491. Quit face average (26,26,25) vs panel (27,28,25) - the unfocused Quit face is 1 to 2/255 from the panel, so the only visible button edge under the stat rows is the Play again 2 px focus outline.
  implication: The owner's gap to the buttons is the 17 px from the last baseline to the Play again outline (12 px from the g descender), against 28 px baseline to cap (23 px descender to cap) between stat rows. Same issue was already noted in 02-PLAYTEST-GATE.md:73 and 02-11-SUMMARY.md:151 (stat rows sit right on top of the buttons); the scene was never changed after that note.

- timestamp: 2026-10-06T10:53:00Z
  checked: In-memory variants on the instantiated scene (no file written) - (a) Buttons wrapped in a MarginContainer with margin_top 11; (b) Buttons custom_minimum_size.y 59 with both buttons size_flags_vertical SHRINK_END; (c) a zero-height spacer Control before Buttons
  found: (a) and (b) - Play again outline at 480, last baseline 451, so 28 px baseline to outline and 23 px ink gap, exactly equal to the stat rows (28 px baseline to cap, 23 px descender to cap). (c) - +12 px, 24 px ink gap, 1 px over. scratchpad/before_after.png shows even spacing with (a). Stat row rects unchanged (12 px apart); panel grows 11 px. Tests reach the buttons through unique names only (tests/e2e/test_results_screen.gd lines 291-365) and focus neighbours are sibling-relative (../QuitButton), so wrapping does not break them.
  implication: The smallest exact change is +11 px above the Buttons row only; a spacer costs an extra separation and lands 1 px over.

## Resolution

root_cause: "ui/results/results_screen.tscn:39 gives the Column VBoxContainer one 12 px separation between every child rect, but the stat Labels (lines 48-74, 26 px Open Sans SemiBold from the default theme) are 36 px rects = ascent 28 + descent 8, so each label's capitals start about 9 px below its rect top; the Buttons HBoxContainer (line 76) has no such leading because a Button StyleBoxFlat face fills its rect (content margins only inset the text), and the focused Play again focus StyleBox expands 2 px above the rect. Result - 28 px baseline to cap top between stat rows vs 17 px from the last baseline to the Play again outline (19 px to the Quit rect)."
fix: "(not applied - diagnose-only) Add 11 px above the Buttons row only - wrap Buttons in a MarginContainer with theme_override_constants/margin_top = 11, or set Buttons custom_minimum_size = Vector2(0, 59) and both buttons size_flags_vertical = 8 (SHRINK_END). Verified in memory to make both gap measures equal."
verification: "Diagnosis verified by rect dump, pixel scan of an isolated render and of the real results_victory screenshot, and in-memory variants; no source or scene file changed."
files_changed: []
