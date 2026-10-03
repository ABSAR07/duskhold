# Phase 2: Night Defense & Playtest Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-03
**Phase:** 2-Night Defense & Playtest Gate
**Areas discussed:** King knockout and respawn, Enemies and night shape, Building damage and towers, Win, loss and playtest gate

Each area's four questions were asked together in one turn.

---

## King knockout and respawn

| Question | Options | Selected |
|----------|---------|----------|
| Countdown length | Grows each time (about 6 s, +4 s per knockout, reset at dawn); Fixed short (about 5 s); Fixed long (about 12 s) | Free text (see below) |
| Penalty besides time | Nothing else; Returns weakened; Gold penalty | Nothing else ✓ |
| King toughness | Sturdy but mortal; Fragile; Tanky | Sturdy but mortal ✓ |
| Healing during a night | Full heal at dawn only; Add regeneration now; Heal near the castle | Full heal at dawn only ✓ |

**User's choice (countdown):** "grows each time until a max 15 seconds. but this max should be adjustable later. might even change using difficulty settings later"
**Notes:** Recorded as a growing countdown with a 15 s cap, all three values in tuning data. Difficulty settings are deferred.

---

## Enemies and night shape

| Question | Options | Selected |
|----------|---------|----------|
| Run length | 5 nights (recommended); 3 nights; 8 nights | 8 nights ✓ |
| Enemy types | Melee plus ranged; Melee only; Melee, ranged and a fast one | Melee plus ranged ✓ |
| Spawn points | Start with 1, grow to 3; 2 fixed; 4 from the start | Start with 1, grow to 3 ✓ |
| First-run difficulty | Winnable with good choices; Easy; Punishing | Winnable with good choices ✓ |

**Notes:** The owner chose the longer 8-night run over the recommended 5.

---

## Building damage and towers

| Question | Options | Selected |
|----------|---------|----------|
| Enemy targeting | Nearest thing in their path; Straight for the castle; King first | Nearest thing in their path ✓ |
| Destroyed look | Rubble on the plot; Building vanishes; Darkened and smoking | Rubble on the plot ✓ |
| Tower targeting | Nearest enemy, visible arrows; Closest to the castle; You decide | Nearest enemy, visible arrows ✓ |
| No-income mark | Crossed-out coin above it; Grey tint for the morning; Text label | Crossed-out coin above it ✓ |

---

## Win, loss and playtest gate

| Question | Options | Selected |
|----------|---------|----------|
| Results screen | Outcome plus a few run stats; Outcome only; Detailed per-night table | Outcome plus a few run stats ✓ |
| After a run | Restart or quit; Restart only; Also retry the failed night | Restart or quit ✓ |
| Loss moment | Short beat, then results; Instant results; You decide | Short beat, then results ✓ |
| Playtest sign-off | Through /gsd-verify-work (recommended); Free-form notes file; Delegate most of it | Delegate most of it ✓ |

**Notes:** The owner chose to delegate most of the playtest: Claude runs scripted seeded playthroughs and reports balance numbers; the owner plays one or two runs for feel. This is lighter than ROADMAP success criterion 4 ("several full runs"); CONTEXT.md D-18 records it for the planner.

---

## Claude's Discretion

Telegraph icon look; exact health, damage, range and speed numbers; countdown values other than the cap; the king's auto-attack look and reach; enemy pathing; night lighting; the loss beat and results layout; determinism rules; placeholder models. The owner declined to explore further gray areas ("I'm ready for context").

## Deferred Ideas

Difficulty settings for the respawn cap; retrying a failed night (Phase 9); king health regeneration (Phase 3); a small minimap; drip coins hidden inside built models on upgrades.
