---
phase: "03"
slug: "king-combat-troops"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-09"
---

# Phase 03 - UI Design Contract (King Combat & Troops)

> Visual and interaction contract for the in-run HUD, squad selection feedback, command prompts and device
> glyphs. Written in Godot terms for the 1280x720 base viewport. Locked inputs: 03-CONTEXT.md D-09..D-16,
> D-21..D-24. Everything marked **(researcher's choice)** was decided here without an owner answer and may be
> overridden. Every number is a presentation constant, never read by `simulation/`.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Godot 4.7.2 `Control` nodes + `StyleBoxFlat`; no web framework, no shadcn) |
| Preset | not applicable |
| Component library | Godot built-ins: `Label`, `HBoxContainer`, `PanelContainer`, `TextureProgressBar`, `ProgressBar`, `TextureRect`, `ColorRect`, `Control._draw` |
| Icon library | Kenney Input Prompts (CC0) for key/button glyphs; unit and sword icons per "Assets" below; stance glyphs are drawn in code |
| Font | Godot's built-in default font, unchanged (the project has no Theme and no custom font; reuse it). Bold = a `FontVariation` of the default font with `variation_embolden = 0.5`. |
| Theme | New `ui/theme/hud_theme.tres` (default font, outline colour/size, `Label` font colour) applied to one new `HudRoot` Control. Existing HUD nodes keep their `theme_override_*` values untouched, except the three font sizes re-mapped in Typography. |
| Base viewport | 1280x720. `project.godot` currently has **no** `display/window/stretch/*` keys, so nothing scales: add `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"` so the anchored layout below holds at 1920x1080 and 16:10 (required change; tests must keep passing in the 64 px headless window). |

Reused existing values (do not re-pick): gold label size 28 (`hud.tscn` GoldLabel), start-night prompt 22, night
preview 18, banner 36, respawn colour `Color(0.55,0.92,1)` = #8CEBFF, fast-forward colour `Color(1,0.88,0.45)` = #FFE073
with outline 8, unaffordable red `Color(1,0.25,0.25)` = #FF4040 (`spot_label.gd`), world health bar background
`Color(0.08,0.08,0.1,0.8)` = #14141A and fill `Color(0.85,0.2,0.18)` = #D9332E (`health_bar_3d.gd`), margins 16 left / 12 top.

---

## Spacing Scale

All new HUD gaps and sizes come from the standard set below (4, 8, 16, 24, 32, 48, 64). The few values outside it are strokes, radii, outlines or shipped Phase 1 scene values and are named under Exceptions after the table; nothing else is allowed.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4 | Glyph-to-word gap, replacement-fill height, border-to-content on a selected slot |
| sm | 8 | Slot padding, gap between slots, icon-to-bar gap, hint-to-strip gap |
| md | 16 | Screen-edge margin (matches GoldLabel `margin_left` 16), hint item gap |
| lg | 24 | Hint-strip and ability-badge glyph size, replaced-toast row gap |
| xl | 32 | Inline prompt glyph size, hint row height |
| 2xl | 48 | Min touch/click target for a slot row (slot is 72 tall) |
| 3xl | 64 | Reserved |

The standard set is used unchanged; no token is added. The DayCounter sits at `offset_top` 16 (md), 4 px below the
existing GoldLabel top edge, which is close enough to read as one baseline (both are 28 px labels; the 4 px step is
invisible at the top edge). The GoldLabel's own 12 px top margin is a shipped Phase 1 scene value, not a token of this
phase, and stays untouched.

Exceptions (named, not tokens): the existing GoldLabel top margin 12 (`hud.tscn` Margin, Phase 1, untouched); 2 px
strokes (idle slot border, drag-box border, bar border) and the 1 px ring outline, which are strokes; corner radius 6 on
the squad slot plate (between the 4 of the badge and the 8 of the ability plate, so the three plate sizes read as
nested); text `outline_size` 6 on every HUD label and 12 on the queued-order `Label3D` digits (double the base because
the 3D text is smaller on screen; the spawn telegraph already uses 6, fast-forward keeps its 8); the ±3 px denied shake,
which is motion, not spacing; the StartNightFill bar height 14 (`hud.tscn`, Phase 1, untouched). Fixed widget sizes: ability icon 56x56, health bar 192x24, slot 136x72.

---

## Typography

Exactly four sizes (36, 28, 22, 18), two weights (Regular 400, Bold 600). Every HUD text role maps to one of them. `hud.tscn` today also holds three off-scale labels: RespawnLabel 30, FastForwardLabel 26 and PayoutTotal 24. **The executor changes the scene, not the spec:** RespawnLabel 30 to 28, FastForwardLabel 26 to 22, PayoutTotal 24 to 22 (`theme_override_font_sizes/font_size` only; positions, colours and rects are untouched, and each rect is at least 32 px tall, so it still fits). The fast-forward label is 244 px wide, which holds "Fast-forward 2x" at 22.

| Role | Size | Weight | Line Height | Used for |
|------|------|--------|-------------|----------|
| Display | 36 | Regular 400 | 1.2 | Night banner (existing, unchanged) |
| Heading | 28 | Regular 400 | 1.2 | GoldLabel (existing), the new day counter "Night 3 of 8", RespawnLabel "Knocked out - back in 6 s" (30 to 28) |
| Body | 22 | **Bold 600 (embolden 0.5)** for numerals, Regular for words | 1.2 | "38 / 50", slot "4 / 4", start-night prompt, toast, FastForwardLabel (26 to 22), PayoutTotal (24 to 22) |
| Label | 18 | Bold for the group digit, Regular otherwise | 1.2 | Hint-strip verbs, control-group badge, queue order numbers, Label3D numbers, ability caption "Slam" |

Rules: every new HUD `Label` sets `font_outline_color` #000000 and `outline_size` 6 (the spawn-telegraph count uses 6;
fast-forward keeps its 8). GoldLabel gains the same outline in this phase (it has none today and is the one
unoutlined HUD text; night legibility, Pitfall 3). Single-line labels only; `line_spacing` 0. No text smaller than 18.

---

## Color

HUD palette (60/30/10 applied to HUD pixels, not the 3D scene).

| Role | Value | Usage |
|------|-------|-------|
| Dominant 60% | #14141A at alpha 0.78 | Every panel behind HUD content: slot background, bar track, ability icon plate, start-night plate (G-03-14b) |
| Secondary 30% | #FFFFFF text; #C8CCD4 secondary text; #3A3F4B idle borders; #7A808C disabled | Numbers, verbs, idle slot border, empty-state dimming |
| Accent 10% | #8CEBFF | Reserved list below |
| Danger | #D9332E (fill) / #FF4040 (text) | Health bar fill; a squad at 0 alive and the king's "0 / 50" |
| Highlight | #FFE073 | Patrol path only (reuses the fast-forward yellow) |
| Attack | #FF7A59 | Attack-move ping and path only (new, warm so it separates from cyan) |

Accent #8CEBFF reserved for (complete list, each with its reason):
1. Selected-squad ground ring, and its hover-preview (alpha 0.4) and group-recall flash: they are the same ring, so selection reads one way.
2. Selected slot border (4 px): the slot-side half of "selected" (D-16).
3. Drag-box fill and border: the one live selection gesture.
4. Ability "ready" flash and ready ring: the single animated accent on the night screen.
5. Ground cursor (pad) and move ping: where a move order will land or has landed.
6. Queued move-order discs and joining line (move orders only; attack-move and patrol keep #FF7A59 and #FFE073): the queue is a preview of the move ping, so it shares its colour.
7. Replacement-fill strip: a squad seat coming back.
8. Dawn-restore slot border flash (one-shot, 0.3 s): a transient confirmation that a squad refilled, never a resting state, so it does not make an unselected slot's border accent-coloured.
9. Pad group-assign badge pulse (only while the assign modifier is held): marks which badge the D-pad is editing.
10. The existing knocked-out label (RespawnLabel).
Never for generic text, the resting or hover border of any slot, or decoration. The slot Hover state therefore uses the
secondary #C8CCD4, not the accent. Contrast: white on #14141A over 15:1; #8CEBFF on
#14141A about 12:1; #FF4040 on #14141A about 5:1; every glyph sits on a dark panel or carries a 6 px outline, so
night lighting cannot dim it (HUD is on a CanvasLayer, unaffected by the WorldEnvironment). State is never colour-only:
selection = ring + thicker border + brighter plate; zero alive = red text + dimmed icon.

---

## Layout (1280x720; screen centre stays clear)

New nodes live under one `HudRoot` (`Control`, full-rect anchors preset 15, `mouse_filter` IGNORE, theme = hud_theme)
as a child of the existing `HUD` CanvasLayer. No new HUD node, toast, caption, hint strip, strip or widget is placed
inside the protected rectangle x 384..896, y 96..500. Everything new in the table below sits at y 504 or lower, or in a
top or side corner. The only things allowed inside the rectangle are the transient world markers, the user's own drag
box while dragging, and two shipped Phase 1 and 2 top-centre nodes that keep their place (D-21: "the night banner keeps
its place"): PhaseBanner (rect y 40..100, its 36 px text ends about y 85) and RespawnLabel (y 100..150, shown only while
the king is knocked out). Existing nodes keep their position.

| Widget | Anchor / offsets | Size | Notes |
|--------|------------------|------|-------|
| GoldLabel (existing) | top-left, margin 16/12 (shipped Phase 1 values, see Spacing exceptions) | font 28 | unchanged; PayoutTotal stays at (16,52) |
| DayCounter | `CenterContainer`, preset 10 (top-wide), offset_top 16 (md), offset_bottom 56 | label 28 | "Night %d of %d"; shown by day and dawn, hidden when the night banner shows; hidden on a map without authored nights |
| PhaseBanner (existing) | y 40..100 | 36 | unchanged |
| KingWidget | `HBoxContainer`, preset 2 (bottom-left), offset_left 16, offset_bottom -16, offset_top -72, separation 8 | 360x56 | [AbilityIcon 56x56][HealthBar 192x24, vertically centred][HealthLabel min 96] |
| SquadStrip | `HBoxContainer`, bottom-centre (anchor_left=right=0.5, top=bottom=1.0), grow both, offset_top -176, offset_bottom -104, separation 8 | slots 136x72 | Stays put by day and night; 8 px above StartNightBox (top at y 624) |
| CommandHints | `HBoxContainer`, same anchors, offset_top -216, offset_bottom -184, separation 16 | 32 tall | Only while at least one squad is selected |
| Toast | `Label`, same anchors as CommandHints, offset_top -216, offset_bottom -184 (y 504..536; at 460 px wide it spans x 410..870, entirely below y 500) | 22 | One line, centred. It uses the CommandHints slot: while a toast shows, the hint strip (or the armed-point line) is hidden, and it returns when the toast ends. Same mechanism as the armed-point line that already replaces the strip. |
| StartNightBox (existing) | bottom-centre, offset_top -96, offset_bottom -4 (y 624..716), separation 0 | prompt 22, preview 18 | top unchanged at y 624; content gains glyphs (D-24). **StartNightPlate** (G-03-14b, plan 03-15): a `PanelContainer` first in the box behind the prompt and the fill bar (inside a `StartNightRows` `VBoxContainer`, separation 4), #14141A at alpha 0.78, corner radius 8, 8 px inset on every side, top at y 624 (8 px below the SquadStrip), measured 400x66 at x 440..840, y 624..690 (never below y 700), `mouse_filter` IGNORE on the plate and its rows, hidden outside the day with the prompt. The NightPreview line (18) stays unplated directly under the plate, y 690..716 while shown. |
| DragBox | `Panel` under HudRoot, `mouse_filter` IGNORE | free | see Interaction |
| FastForwardLabel (existing) | top-right y 60..96 | font 22 (was 26; maps to Body, see Typography) | position unchanged; the executor edits the scene font size |

**Focal points (hierarchy).** *Day screen:* primary focal point is the start-night prompt, "Hold [glyph] to start Night %d" with its fill bar, bottom-centre (the only 22 bold line with a glyph and a bar, on the clear bottom-centre of the screen, on its own StartNightPlate, which is what keeps it above a cyan selected slot); secondary are GoldLabel (top-left) and the DayCounter (top-centre); the SquadStrip and hint strip are tertiary (18 px, no accent unless a squad is selected). *Night screen:* primary focal point is the KingWidget, bottom-left: the health bar (the only large red fill) and the sword ability ring, whose single #8CEBFF ready flash is the one animated accent; secondary are the night banner and RespawnLabel when shown, the SquadStrip is tertiary, and the start-night prompt is hidden. No HUD element competes with the 3D action in the cleared centre.

Up to 6 slots fit (6x136+5x8 = 856 px). More than 6 is not reachable in Phase 3; scale the strip with
`Control.scale` to a 720 px maximum if it ever happens.

---

## King widget (D-22)

| Part | Spec |
|------|------|
| AbilityIcon | 56x56 `Control`: plate `StyleBoxFlat` #14141A@0.78, radius 8, 2 px border #3A3F4B. Inside, a `TextureProgressBar` 48x48 (inset 4): `texture_under` the code-drawn sword (rendered once to an `ImageTexture` via a `SubViewport` or `_draw` on a child `Control`, no asset) modulated #5A5F6B, `texture_progress` the same texture #FFFFFF, `fill_mode` = FILL_CLOCKWISE (4), `radial_initial_angle` 0 (starts at 12 o'clock), value = elapsed/cooldown. |
| Ready state | Progress full: icon white, plate border #8CEBFF 2 px. One-shot flash on reaching ready: plate scale 1.0 to 1.2 to 1.0 over 0.25 s and modulate to #8CEBFF and back over 0.2 s. No repeating pulse. |
| On use | Fill snaps to 0, plate scales 1.0 to 0.9 to 1.0 over 0.12 s, border returns to #3A3F4B. Used by day too (D-19); it just hits nothing. |
| Pressed while cooling | Plate shakes +-3 px on x for 0.15 s (3 oscillations); no text, no sound hook beyond the Phase 8 SFX slot. |
| Ability caption (text fallback) | `Label` "Slam", Label 18 Regular, white, outline 6, centred, a child of the 56x56 plate positioned at offset (0,-24) size 56x24 (above the icon, outside the HBox, so KingWidget's row stays 56 tall; its footprint now reaches y 624..704 and x 16..72 for the caption, clear of SquadStrip and StartNightBox). Always visible, shares the widget alpha (0.4 when knocked out). The icon is therefore never icon-only, and it still reads if the glyph tile fails to load. |
| Ability glyph | 24x24 `TextureRect` at plate offset (32,32), bottom-right, showing the active-ability action's glyph for the last-used device (prompt rules below). |
| HealthBar | 192x24 `ProgressBar`, `show_percentage` false, `step` 0.001; background `StyleBoxFlat` #14141A@0.78 radius 4, 2 px border #000000; fill `StyleBoxFlat` #D9332E radius 4. Value tweens to the sim value over 0.15 s (regen climbs smoothly). |
| Damage taken | Border flashes #FFFFFF for 0.1 s on each hit. No shake. |
| HealthLabel | "%d / %d" (e.g. "38 / 50"), Body 22 bold, white, outline 6, left-aligned, 8 px after the bar, min width 96 so "50 / 50" and "5 / 50" do not shift the layout. |
| Knocked out (KING-06) | Bar value 0, HealthLabel "0 / 50" in #FF4040, whole widget `modulate` alpha 0.4, ability presses ignored. The existing RespawnLabel (centre-top, #8CEBFF, y 100..150) carries the countdown; the widget adds no timer. On respawn: widget returns to full alpha, bar jumps to full (no flash), cooldown shows whatever the sim holds. |
| Always visible | The widget never hides (it is the king's lifeline); it is not hurt-only like the world bars. The world `HealthBar3D` over the king is unchanged. |
| Slam in the world | Expanding flat ring at the king's feet: radius 0 to `WeaponDef` slam radius over 0.25 s, white #FFFFFF alpha 0.85 to 0, 0.15 m thick, unshaded, plus 4 radial dust billboards if the budget allows. Radius comes from data, never a literal. |

---

## Squad group slots (D-23)

One `PanelContainer` slot per existing squad, 136x72, in squad-creation order (order the buildings were built).
No squad exists yet: the strip is hidden and nothing replaces it (empty state; the spot labels already teach building).
A slot appears the tick its first unit spawns (fade in 0.15 s).

```
SquadSlot (PanelContainer 136x72, mouse_filter STOP, focus_mode NONE)
  Margin 8
    VBox (separation 4)
      TopRow HBox (separation 8, height 32): UnitIcon TextureRect 32x32 | AliveLabel (Body 22 bold "4 / 4")
      BottomRow HBox (height 20): StanceGlyph Control 20x20 | spacer | GroupBadge PanelContainer 20x20 (Label 18 bold)
  ReplacementFill ProgressBar: 4 px tall strip, offset 8 from left/right, bottom edge (y 64..68)
```

| State | Look |
|-------|------|
| Idle | Plate #14141A@0.78, radius 6, 2 px border #3A3F4B, icon white, text white |
| Selected | Border 4 px #8CEBFF, plate lightened to #1B2830@0.85 (same alpha, bluer), nothing else moves (border drawn inside the 8 px padding so the layout does not jump) |
| Hover (mouse) | Border 2 px #C8CCD4 (secondary text colour, not the accent), alpha 1.0; plate unchanged |
| 0 alive | Icon and glyph modulate #7A808C, AliveLabel "0 / 4" #FF4040, ReplacementFill visible if a replacement is coming; slot stays selectable and commandable |
| Full | ReplacementFill hidden |
| Replacement coming | Fill 0 to 1 over the tier's respawn interval (10 s / 7 s / 4 s), track #2A2D36@0.9, fill #8CEBFF alpha 0.6, resets to 0 per unit; shown only while alive < max |
| Dawn restore | One-shot: border flashes #8CEBFF 0.3 s and AliveLabel counts straight to full; no text |
| Cap raised by upgrade | AliveLabel max updates at once; the new empty seats show as a coming replacement |
| Unit icon | Melee squad: sword; ranged squad: bow. Both drawn in `_draw` (code, no asset): 32x32, white, 2 px line, 1 px dark stroke, the same two shapes the AbilityIcon uses at 48x48 |
| StanceGlyph | Drawn in `_draw`, 20x20, line width 2, colour #C8CCD4; the shapes are distinct without colour: **post** = small filled square on a base line, **follow** = two chevrons ">>", **hold** = square outline with a bar through it, **patrol** = double-headed horizontal arrow, **attack-move** = right arrow with a spike tip. Shows the stance after the current queue finishes; a squad executing a one-shot command (move, attack-move) shows the glyph of that command until it arrives, then returns to its resting stance. |
| GroupBadge | Shows the **lowest** stored control-group number the squad belongs to: digits 1 to 9 and 0 (key 0 is group 10). Hidden when the squad is in no group. Panel #000000@0.5 radius 4. |
| Click | Left click selects only this squad; Ctrl+click toggles it in the selection; same result as clicking its units. Slots do not take keyboard focus (so Space/Enter `ui_accept` never presses them). |

---

## Selection, commands and world feedback (D-09..D-16)

| Element | Spec |
|---------|------|
| Ground ring (D-16) | One flat ring under each unit of a selected squad, drawn as a `MultiMeshInstance3D` quad ring (one draw call; Phase 4's batching then needs no change). Outer diameter 1.1 m, thickness 0.1 m, y 0.03, unshaded, #8CEBFF alpha 0.95, with a second ring 0.06 m wider in #000000 alpha 0.5 underneath for contrast on light terrain. Follows the interpolated puppet. |
| Hover preview | Mouse over a squad's unit (nothing dragged): that squad's rings at alpha 0.4. |
| Group recall | Recalling a group flashes the rings once (alpha 1.0 for 0.15 s, scale 1.0 to 1.2 to 1.0). |
| Drag box | Starts after 8 px of movement from a press on the ground (not on the HUD). `Panel` with a `StyleBoxFlat`: fill #8CEBFF alpha 0.16, border 2 px #8CEBFF alpha 0.9, no radius. Releases select every squad with at least one unit inside the rectangle (screen-projected); with Ctrl held it adds. Escape or a right click mid-drag cancels. |
| Click select | Left click within 32 px of a unit selects its squad; clicking empty ground deselects all (researcher's choice). |
| Move (right click) | Ping at the ground point: ring expanding 0.3 m to 0.8 m over 0.5 s, alpha 0.9 to 0, #8CEBFF. |
| Attack-move | Same ping in #FF7A59, plus a 0.3 m crossed-blade mark (two bars) that stays 0.5 s. |
| Patrol path | Dashed ground line (0.12 m wide, 0.4 m dash, 0.3 m gap) in #FFE073 alpha 0.8 from the squad's start point through each waypoint, endpoints marked with 0.4 m discs. Drawn for selected patrolling squads; flashes for 1.5 s when set; not drawn for unselected squads (researcher's choice). |
| Queued orders | Shift-queued points show a 0.4 m disc with its order number (1, 2, 3; Label3D 18, outline 12) joined by a thin line, in the command's colour (cyan move, #FF7A59 attack-move, #FFE073 patrol), for selected squads only, up to 6 shown. |
| Rally / follow / hold | No ground marker. Rally pings at the king (cyan, as move). The stance shows on the slot glyph only. |
| Mouse cursor | Visible while the last device is keyboard or mouse; `CURSOR_CROSS` while a point command is armed and waiting for a click; `Input.mouse_mode` = HIDDEN while the pad is the last device, back to VISIBLE on mouse motion. |
| Gamepad cursor (D-12) | While a point-command button is held: a flat ground ring 1.2 m wide, #8CEBFF alpha 0.9 with the dark under-ring, plus a 0.12 m line from the king to it. Starts on the king, moves with the right stick at a data speed, clamped to the visible ground and 48 px inside the screen edge (`SpawnTelegraph.EDGE_MARGIN_PX`). Release confirms; cancelling uses the held command's opposite button (planner picks). The right stick is also zoom (`zoom_in`/`zoom_out` axis 3) today: **zoom is suppressed while the cursor is active.** |
| Patrol input (researcher's choice) | Mouse: hold the patrol key and right-click each point, release the key to commit; Shift appends. Pad: hold the patrol button, move the cursor, release to add that point; Shift-equivalent chord appends. The path starts where the squad stands when committed. |
| Pad group assign (researcher's choice) | While the assign modifier is held, the cycled squad's GroupBadge becomes editable: D-pad left/right steps 1..9,0 (wrapping), the badge border pulses #8CEBFF, release stores it and shows the "Group saved" toast. |
| Selection persists | Device switches keep the selection and groups (D-12). Dying squads stay selected at 0 alive. |

Two input conflicts the planner must settle, with the prompt contract unaffected (prompts are always read from the
Input Map): D-15's **A** (attack-move) is `move_left`'s physical key (65) today; **Shift** is the held sprint key
(physical 4194325, pad RB) and D-09 also uses Shift to queue. Recommendation: queue only counts when Shift is
held at the moment a command or click lands; the hint strip must show whatever keys end up bound.

---

## Command hints and device prompts (D-24, INPT-02)

**Device tracking.** A small `LastDeviceTracker` (input/, a Node) emits `device_changed(kind)` with kind = KEYBOARD
or PAD. Keyboard: `InputEventKey` pressed, any `InputEventMouseButton`, `InputEventMouseMotion` once 8 px have
accumulated within 0.25 s (a bumped mouse does not count). Pad: `InputEventJoypadButton` pressed or
`InputEventJoypadMotion` with abs(axis_value) >= 0.5 (the Input Map deadzone is 0.2; this beats stick drift). A
switch is applied at once but at most once per 0.25 s. Start on KEYBOARD (researcher's choice). Losing the active pad
falls back to KEYBOARD. Every prompt subscribes to the one signal, so all glyphs change in the same frame.

**Glyph rules.**
- Source: Kenney **Input Prompts** (CC0, v1.5, 64x64 PNG tiles; Keyboard & Mouse set and Xbox set, default filled style).
  Draw at 32x32 inline with Body text, 24x24 on the hint strip and ability badge, 20x20 never. Texture filter linear.
- A glyph resolver maps `InputEvent` to texture: key -> keyboard tile named for the key; mouse button -> mouse tile;
  pad button/axis -> Xbox tile (A/B/X/Y, LB/RB, LT/RT, D-pad directions, right stick). File names inside the pack
  must be taken from the extracted folder, not from this document. Keys use the layout label already resolved by
  `Hud._key_text` (Dvorak/AZERTY keep working).
- A binding with no tile (or an unbound action) renders as a text keycap: `PanelContainer` radius 4, #3A3F4B plate, 2 px
  border #C8CCD4, Label 18, so `"(unbound)"` still appears when nothing is bound.
- A prompt shows the **first binding of the active device only** (not "N / (Y)"). Modifier combinations show as two
  glyphs joined by a 4 px "+" label (Ctrl + 1).
- Text names (`PAD_BUTTON_NAMES`, `AXIS_NAMES`, "Pad %d") remain only as the keycap fallback.
- Non-Xbox pads show Xbox glyphs (deferred to Phase 13).

**Start-night prompt** (existing position): `HBoxContainer`: Label "Hold" | glyph 32x32 | Label "to start Night %d". The fill
bar below is unchanged. A device switch mid-hold swaps the glyph in place, does not reset the fill, and the hold keeps
counting while either device's input is down.

**Command hint strip** (new, selection non-empty). Items left to right, each = 24x24 glyph + 4 px + Label 18 word,
white with outline 6, no panel: **Follow, Hold, Rally, Move, Attack, Patrol**, then "Queue" with the Shift glyph. Move shows
the right-mouse glyph on keyboard/mouse and the cursor-confirm glyph on pad. Fades in 0.15 s on first selection, out 0.15
s on empty. While a point command is armed the strip is replaced by one line, e.g. "Click a point to attack-move"
(pad: "Aim with the right stick, release to confirm"), until it resolves or is cancelled.

**Ability and other persistent prompts**: ability glyph on the sword badge (above). Build hold keeps the spot-label text
unchanged (no key names there today). Fast-forward label stays text ("Fast-forward 2x"); the new key is the planner's.
Other glyph sites: results screen buttons are menus and stay text (Phase 13).

---

## Copywriting Contract

Tone: plain, short, sentence case, no exclamation marks, no trademarked names; strings live as `const` in `hud.gd` or
the new widget scripts, matching the existing style ("Hold %s to start Night %d", "Knocked out — back in %d s").

| Element | Copy |
|---------|------|
| Primary CTA (the phase's one in-run action) | "Hold [glyph] to start Night %d" (existing, now glyph-based: `START_NIGHT_PROMPT_PRE` "Hold", `START_NIGHT_PROMPT_POST` "to start Night %d") |
| Day counter | "Night %d of %d" (number = the next night) |
| King health | "%d / %d" |
| Squad count | "%d / %d" |
| Hint verbs | "Follow", "Hold", "Rally", "Move", "Attack", "Patrol", "Queue" |
| Armed-point prompts | "Click a point to attack-move" / "Click a point to patrol" / "Aim with the right stick, release to confirm" |
| Toast: group stored | "Group %d saved" |
| Toast: recall of an empty group | "Group %d is empty" |
| Empty state heading | **None, deliberately textless.** With no squads built the strip and the hint strip are hidden and no placeholder heading is shown (a "No squads" label would be noise on every map's first day). |
| Empty state body | **None, deliberately textless.** The existing spot labels (build name and price) on the Barracks and Archery Range spots are the guidance toward a first squad; the first slot fades in the tick its first unit spawns. |
| Ability caption | "Slam" (Label 18, always visible above the ability icon) |
| Error: command with nothing selected | Toast "Select a squad first" (1.5 s) |
| Error: point outside the map or off the visible ground | Toast "Can't go there. Click a point on the visible ground." (1.5 s, Body 22, about 460 px, one line), no order issued; the squad does not move. Pad cursor is clamped to visible ground, so this appears for mouse input only. |
| Error: ability pressed while cooling or down | None (shake only) |
| Knocked out | "Knocked out — back in %d s" (existing, unchanged) |
| Destructive confirmation | None in this phase: no command destroys anything and nothing asks for confirmation. |

Toast: Body 22, white, outline 6, no panel, shown in the hint-strip slot (y 504..536, below the protected centre) in place of the strip, fade in 0.1 s, hold 1.2 s (1.5 s for errors), fade out 0.3 s; a new toast replaces
the current one.

---

## UI Considerations

Probe run 2026-10-09 (ui-consideration-probe, 10 surfaces, kinds confirmed by the owner, resolutions taken from
this spec at the owner's direction): 47 applicable considerations — 29 resolved (explicit), 7 resolved
(backstop), 11 dismissed with a reason; plus 2 device-state truths and 1 unresolved row below. A backstop row lifts
into `must_haves.truths` as `{ statement, verification: backstop }` and needs explicit evidence (a scene test or a
screenshot scenario) at verify time, otherwise it routes to human review. Empty- and error-state copy lives in the
Copywriting Contract; rows here reference it rather than restate it.

| Category | Element | Status | Resolution / Reason |
|----------|---------|--------|---------------------|
| overflow | DayCounter (E1) | resolved (verification: explicit) | DayCounter is a full-width CenterContainer with one 28 px line; the longest shipped text "Night 8 of 8" fits with room to spare, nothing clips. |
| long-text | DayCounter (E1) | resolved (verification: backstop) | Two-digit night numbers ("Night 12 of 12") stay on one centred line; screenshot check on the longest authored map. |
| empty | KingWidget (E2) | resolved (verification: explicit) | The king always exists, so the widget is never empty; at 0 health it shows "0 / 50" in #FF4040 at alpha 0.4 with ability input ignored and the RespawnLabel countdown. |
| loading | KingWidget (E2) | dismissed | Health and cooldown come from the local simulation every frame; there is no in-flight state. |
| error | KingWidget (E2) | resolved (verification: explicit) | A press of the ability while knocked out or on cooldown does nothing and plays the ±3 px denied shake on the icon; no error text. |
| populated | KingWidget (E2) | resolved (verification: explicit) | Bar at the sim health with "38 / 50" beside the sword icon filling clockwise over the cooldown; ready flash once. |
| overflow | KingWidget (E2) | resolved (verification: explicit) | HealthLabel has min width 96 so "50 / 50" and "5 / 50" never shift the row; the widget is 192 + 8 + 96 + 8 + 56 px wide, inside x 16..376. |
| long-text | KingWidget (E2) | resolved (verification: backstop) | Health above 99 is not shipped in Phase 3 data; if a later tier reaches three digits the label grows right without reflow; screenshot check with max_health 120. |
| empty | SquadStrip (E3) | resolved (verification: explicit) | With no squads the SquadStrip and CommandHints are hidden; no placeholder text (Copywriting: empty state deliberately textless, spot labels guide). |
| loading | SquadStrip (E3) | dismissed | A squad slot appears the tick its building completes; the sim has no asynchronous state to wait for. |
| error | SquadStrip (E3) | dismissed | The strip mirrors sim state and has no data source that can fail. |
| populated | SquadStrip (E3) | resolved (verification: explicit) | One slot per squad, 136x72, 8 px gaps, centred at the bottom; two squads in Phase 3. |
| partial | SquadStrip (E3) | resolved (verification: backstop) | A squad whose building is rubble keeps its slot with "0 / N" dimmed and the replacement fill stopped until dawn restores it; scene test with a destroyed Barracks. |
| overflow | SquadStrip (E3) | resolved (verification: explicit) | Up to 6 slots fit in 856 px; more scale the strip down uniformly, never wrapping or entering the clear centre. |
| zero-one-many | SquadStrip (E3) | resolved (verification: explicit) | Zero: hidden. One: a single centred slot. Many: the strip grows both ways from the centre. |
| empty | Squad slot (E4) | resolved (verification: explicit) | At 0 alive the slot shows "0 / N" in #FF4040 with the icon dimmed and the replacement fill running; it stays selectable. |
| loading | Squad slot (E4) | resolved (verification: explicit) | A replacement on its way shows as the thin 4 px fill along the slot bottom, from 0 to full over the respawn interval. |
| error | Squad slot (E4) | dismissed | A slot has no failing operation; a destroyed building is the strip's partial state (E3). |
| populated | Squad slot (E4) | resolved (verification: explicit) | Unit icon, "alive / max", stance glyph, group badge, selection highlight as specified in the King widget and Squad slot tables. |
| overflow | Squad slot (E4) | resolved (verification: explicit) | The badge shows one character (lowest group, 0 = group 10); "14 / 14" at Body 22 fits the 136 px slot with 8 px padding. |
| long-text | Squad slot (E4) | resolved (verification: explicit) | Count text is digits only with a fixed-width layout; the longest shipped value is "14 / 14". |
| loading | CommandHints (E5) | dismissed | Glyph tiles are preloaded with the HUD scene; nothing streams in at runtime (a missing tile is E7's error state). |
| error | CommandHints (E5) | resolved (verification: explicit) | An unbound action renders the "(unbound)" text keycap in place of its tile; the strip never hides a verb silently. |
| overflow | CommandHints (E5) | resolved (verification: backstop) | All 7 items are about 610 px wide at 1280; screenshot check at 1280x720 and 16:10 against the king widget and the slots. |
| long-text | CommandHints (E5) | resolved (verification: explicit) | Verb labels are fixed single words (Follow, Hold, Rally, Move, Attack, Patrol, Queue); no wrapping. |
| overflow | Toast (E6) | resolved (verification: explicit) | One toast at a time, single line, in the hint-strip slot at y 504..536; a new toast replaces the current one. |
| long-text | Toast (E6) | resolved (verification: backstop) | The longest toast ("Can't go there. Click a point on the visible ground.") is about 460 px at Body 22; measured in verification scenario 7 so it never reaches x 384 or x 896. |
| empty | Prompt glyphs (E7) | resolved (verification: explicit) | An action with no binding on the active device renders the "(unbound)" keycap. |
| loading | Prompt glyphs (E7) | dismissed | Tiles are loaded with the scene from the local pack; no runtime fetch. |
| error | Prompt glyphs (E7) | resolved (verification: explicit) | A binding with no matching tile falls back to the text keycap (PanelContainer radius 4, #3A3F4B). |
| populated | Prompt glyphs (E7) | resolved (verification: explicit) | Every prompt shows the tile of its bound event on the active device. |
| partial | Prompt glyphs (E7) | resolved (verification: explicit) | A binding present on one device only shows that device's tile when active and the "(unbound)" keycap on the other. |
| overflow | Prompt glyphs (E7) | resolved (verification: explicit) | Tiles are fixed 24 or 32 px squares; they never scale with text. |
| long-text | Prompt glyphs (E7) | resolved (verification: backstop) | A long key name in the keycap fallback ("Backspace") widens the keycap; screenshot check with the longest bound key name. |
| loading | Drag box (E8) | dismissed | The drag box is immediate input feedback with no loading state. |
| error | Drag box (E8) | resolved (verification: explicit) | A drag that starts on a HUD control or ends off the ground selects nothing and the box simply disappears; no toast. |
| long-text | Drag box (E8) | dismissed | The drag box carries no text. |
| empty | World markers (E9) | resolved (verification: explicit) | With nothing selected no rings, pings, lines or discs are drawn. |
| loading | World markers (E9) | dismissed | Markers are drawn from local state the same frame. |
| error | World markers (E9) | resolved (verification: explicit) | An invalid ground point draws no ping; the "Can't go there" toast is the only feedback. |
| populated | World markers (E9) | resolved (verification: explicit) | A ring under each unit of each selected squad (MultiMesh), a ping at each clicked point, patrol lines and numbered queued discs in the verb colour. |
| partial | World markers (E9) | resolved (verification: explicit) | Units off-screen have no visible ring; the HUD slot stays highlighted (D-13). |
| overflow | World markers (E9) | resolved (verification: backstop) | The queue is capped at 9 orders per squad so disc numbers stay one digit; a tenth order replaces the last; scene test with 10 queued orders. |
| zero-one-many | World markers (E9) | resolved (verification: explicit) | Zero selected: nothing. One unit: one ring. Many: one ring per unit, all one colour per squad. |
| loading | Pad ground cursor (E10) | dismissed | The cursor appears the frame the command button is held. |
| error | Pad ground cursor (E10) | resolved (verification: explicit) | Releasing over invalid ground gives no order, hides the cursor and shows the "Can't go there" toast. |
| long-text | Pad ground cursor (E10) | dismissed | The cursor carries no text. |
| state | Device switch mid-hold | resolved (verification: explicit) | Glyphs swap in place; the fill and hold timer are untouched. |
| state | Any press on the other device | resolved (verification: explicit) | One `device_changed` signal re-renders every prompt in the same frame; mouse input counts as keyboard. |
| partial | Control groups after a squad is lost or added | ⚠ unresolved — planner must treat as assumption | Whether a stored group drops members that no longer exist (and how a new squad joins) is the planner's to decide; the HUD only shows what the sim reports. |

---

## Assets and Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none (not applicable, Godot) | not required |
| Kenney Input Prompts v1.5 (CC0) | `assets/third_party/kenney_input_prompts/`: only the keyboard, mouse and Xbox tiles the resolver needs, plus the pack's `License.txt` | **Required deliverable:** an entry in `assets/attribution.json` (id e.g. `kenney-input-prompts`, kept sorted, `license` CC0-1.0, `source_url` https://kenney.nl/assets/input-prompts, `retrieved`, zip `sha256`, `notes` listing kept files, `ships_in_build` true) and the same row in `ASSETS.md`, so `tests/unit/test_attribution_log.gd` passes (every file under `assets/third_party/` belongs to exactly one entry). Download with `curl --fail`, no redirects, as for the earlier Kenney packs. Not yet downloaded - no evidence recorded yet. |
| Sword and bow icons | None. Both icons are drawn in code (`Control._draw`: sword = blade line with a cross guard and pommel, bow = arc with a string and a nocked arrow), so no third-party source, no asset and no attribution entry are needed in this phase. | not required (no third-party block). A logged CC0 icon pack may replace the code-drawn shapes in the Phase 8 art pass, with its files, licence and sha256 recorded then. |
| Unit and arrow models | Kenney Mini Characters (already logged) per 03-CONTEXT | existing entry |

Code-drawn: stance glyphs, rings, ping, dashed lines, drag box (no assets).

---

## Verification hooks

For `tools/screenshot/shot_scenarios.gd`, 1280x720 plus one 1920x1080 and one 16:10: (1) day with two full squads and
one selected; (2) night with a squad at 0 alive and the king hurt at about 38 / 50; (3) drag box mid-drag; (4) pad as
the last device with the ground cursor out; (5) king knocked out; (6) ability just ready (flash frame); (7) the longest
toast ("Can't go there. Click a point on the visible ground.") showing over a selected squad. Pass when no HUD node
(toast, caption, hint strip, strip or widget) sits in x 384..896, y 96..500, apart from world markers, the drag box
while dragging, PhaseBanner and RespawnLabel (the exempt nodes named under Layout), and all text reads at night.
Tests: contract tests pin the layout offsets, the four font sizes (and assert no `HUD` label in `hud.tscn` or the new widgets uses a size outside 36/28/22/18), #8CEBFF, and the copy constants; a drift test checks
that every prompt re-renders on one `device_changed`.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS (FLAG accepted: shipped Phase 1 values named under Exceptions)
- [x] Dimension 6 Registry Safety: PASS (FLAG open until the Kenney Input Prompts pack is downloaded and its sha256 and attribution row recorded)
- [x] Dimension 7 Inventory Provenance: PASS (not applicable, `Tool: none`)

**Approval:** pending
