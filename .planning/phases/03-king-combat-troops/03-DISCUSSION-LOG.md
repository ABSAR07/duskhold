# Phase 3: King Combat & Troops - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-09
**Phase:** 03-king-combat-troops
**Areas discussed:** Squads: size, post, respawn; Unit command hotkeys; Active ability and regen; HUD and device prompts

---

## Squads: size, post, respawn

| Option | Description | Selected |
|--------|-------------|----------|
| 4 → 8 → 12 over 3 tiers (Recommended) | Thronefall's numbers; matches the House's 3 linear tiers | |
| Smaller: 3 → 6 over 2 tiers | Like the tower's 2 tiers | |
| Other | 4 → 8 → 14 over 3 tiers; tier 3 proportionally smaller than tier 1 to 2 but larger in magnitude | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Add two new plots (Recommended) | One Barracks and one Archery Range plot near the castle, inside the tower ring; existing plots untouched | ✓ |
| Convert two existing plots | A House and a tower plot become military plots | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Guard the post (Recommended) | Idle at the building, engage inside a guard radius, commit to targets, return to post; stand at post by day | ✓ |
| Guard the castle | Gather at the castle center by default | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, retune with bots (Recommended) | Raise night counts until the balanced bot still wins 7 or 8 of 10 | ✓ |
| No, keep Phase 2 counts | Troops make nights easier until a later retune | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Thronefall pace (Recommended) | One unit every 10 s at tier 1, 6 s at tiers 2 and 3 | |
| Slow trickle | One unit every 20 s | |
| Other | 10 s at tier 1, 7 s at tier 2, 4 s at tier 3 | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Thronefall-like 4 → 8 → 16 (Recommended) | Roughly doubling per tier | ✓ |
| Cheaper early squad | 3 → 7 → 15 | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Classic pair (Recommended) | Sturdy melee buffer, fragile archers that outrange the grunt | ✓ |
| Equal footing | Only range differs | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Weak individually (Recommended) | About a fifth of the king; a tier-1 squad matches him | ✓ |
| Half a king each | A tier-1 squad outfights the king | |
| You decide | | |

**User's choice:** see the ticks above.
**Notes:** "Tier 3's increase from Tier 2 should be proportionally smaller than t1 to t2, but still substantially stronger magnitude wise as compared with tier 2."

---

## Unit command hotkeys

| Option | Description | Selected |
|--------|-------------|----------|
| Follow key + hold key + type selector (Recommended) | Three keys, mirrors Thronefall | |
| One key per unit type | Four keys, no cycling | |
| Other | A full Age of Empires type command structure with custom control groups; commands to whole squads | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Freeze where they stand (Recommended) | Hold at the current spot, guard radius there | ✓ |
| Send them back to the post | Hold means return to the building | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Every squad returns to its post at dawn (Recommended) | Dawn resets stances | |
| Stances persist across dawn | Stances stay until changed | ✓ |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| D-pad (Recommended) | Commands on the D-pad | ✓ |
| Face buttons | Y hold, X follow, B cycle | |
| You decide | | |

Follow-up (plain text), owner's answers:
- Verbs: rally to the king, attack-move and patrol in addition to follow and hold.
- Selection: Ctrl + select or mouse selection captures several squads; Ctrl + 0 to 9 assigns a control group; on the controller the squads are cycled and assigned.
- Scope: "build it all now".
- Reverse "mouse for menus only": "yes reverse the decision, mouse use is kind of a necessity now i realize in hindsight."
- Attack-move and patrol points come from the mouse, not from king-position marks.
- Amend ROADMAP success criterion 2 and REQUIREMENTS.md: "confirmed, make that ammendment".

| Option | Description | Selected |
|--------|-------------|----------|
| Right-stick cursor (Recommended) | Ground cursor on the right stick while a command button is held | ✓ |
| The king is the cursor | Ride there and press | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Stays locked on the king (Recommended) | Mouse points projected onto the visible ground | ✓ |
| Edge-scroll or drag to look around | Camera can leave the king | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Classic RTS letters (Recommended) | F follow, H hold, R rally, A attack-move, P patrol, Tab cycle, Ctrl+click add, Ctrl+0..9 store, 0..9 recall | ✓ |
| Number row for verbs | 1 to 5 verbs, F1..F10 groups | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Click and drag box (Recommended) | Left click selects, drag box selects several, Ctrl adds | ✓ |
| Click only, no box | One squad per click | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Ground ring plus HUD slot (Recommended) | Ring under each selected unit, highlighted slot with the group number | ✓ |
| HUD only | No world markers | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Move and hold there (Recommended) | Walk to the point, then hold | |
| Attack-move | Right click always attack-moves | |
| Other | Move, but no hold unless the hold key is pressed afterwards or queued with Shift | ✓ |

---

## Active ability and regen

| Option | Description | Selected |
|--------|-------------|----------|
| Sword: melee passive + slam (Recommended) | Shipped passive plus a circular slam, no aiming | ✓ |
| Bow and Dagger, Thronefall's starter | Ranged passive plus a dagger stab | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| WeaponDef resource now (Recommended) | Passive and active fields in a .tres | ✓ |
| Hard-code the one ability | Numbers in KingDef | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| About 9 s, any time (Recommended) | Usable by day too; radial fill and ready flash | ✓ |
| Short, about 4 s | Spammable, weaker | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Thronefall-like (Recommended) | 1 s after the last hit, 10 percent per second | ✓ |
| Slower and later | 3 s, 5 percent per second | |
| You decide | | |

---

## HUD and device prompts

| Option | Description | Selected |
|--------|-------------|----------|
| Corners, centre kept clear (Recommended) | Gold top-left, night top-centre, king bottom-left, groups bottom-centre | ✓ |
| One bottom bar | Single strip | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Health bar with number + radial icon (Recommended) | Bar with "38 / 50", sword icon fills clockwise | ✓ |
| Segmented hearts + countdown text | Ten segments, plain seconds | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Icon, count, stance, group number (Recommended) | Full slot with respawn fill | ✓ |
| Counts only | Icon and alive/max | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Icon glyphs, switch on last input (Recommended) | Kenney Input Prompts glyphs; any other-device input switches all prompts; mouse counts as keyboard | ✓ |
| Keep text names, switch them | Text prompts only | |
| You decide | | |

---

## Claude's Discretion

Guard radius and formation, unit numbers within the chosen shape, patrol path setting and drawing, the remaining pad chords and the new fast-forward key, the slam's radius and damage, device-switch detection and glyph mapping, HUD sizes and colours, unit models, how the bots use commands and how the harness records mouse points, the order of work.

## Deferred Ideas

Unit counters and the Hero's Quarter (Phase 6+), more weapons and the loadout screen (meta phases), walls and the MultiMesh switch (Phase 4), non-Xbox glyphs and rebinding (Phase 13), camera edge-scroll while commanding (rejected for now).
