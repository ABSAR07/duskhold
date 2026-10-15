# Phase 4: Crowd-Scale Battles & Walls - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-16
**Phase:** 04-crowd-scale-battles-walls
**Areas discussed:** Wall plots & what they block, Enemy behaviour at walls, Stress bar & your machine, Goldens & balance after pathing

---

## Wall plots & what they block

### How should walls exist on the map?

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed wall-segment plots | Short segment plots in lines; the player picks segments and leaves the gaps (keeps D-02 per segment) | |
| One plot buys a whole wall run | A single plot is a pre-drawn wall line with authored gates | ✓ |
| Wall plots plus authored gate plots | Segment plots plus gate plots open to the king and squads only | |

**User's choice:** One plot buys a whole wall run

### What is a barricade?

| Option | Description | Selected |
|--------|-------------|----------|
| Cheap short run that plugs a gap | A separate cheaper building on its own plots across authored gaps | |
| Same building, first tier | Wall tier I is the barricade; higher tiers the stone wall | ✓ |
| No separate barricade | Ship walls only | |

**User's choice:** Same building, first tier

### Who does a wall run block?

| Option | Description | Selected |
|--------|-------------|----------|
| Everyone on the ground | Enemies, squads and the king; only authored gaps pass | ✓ |
| Enemies only | Squads and the king walk through | |
| Enemies and squads, king passes | The mounted king crosses walls | |

**User's choice:** Everyone on the ground

### How many tiers and what changes?

| Option | Description | Selected |
|--------|-------------|----------|
| 3 tiers: barricade, wall, strong wall | Health only rises; shape and gaps fixed | ✓ |
| 2 tiers: barricade, wall | Thronefall's own count | |
| 3 tiers, top tier narrows the gaps | Tier III also shrinks each gap | |

**User's choice:** 3 tiers, health only
**Notes:** Follow-up round declined ("Next area"); prototype-map placement was settled in the last area.

---

## Enemy behaviour at walls

### When an enemy's route is blocked by a wall run, what does it do?

| Option | Description | Selected |
|--------|-------------|----------|
| Go around through a gap; attack only when sealed | Thronefall's rule | |
| Detour limit, then break through | Data threshold in metres | |
| Always attack what is in the way | Walls as health sponges | |
| Other (free text) | Smart compare of time-to-destruction against detour time | ✓ |

**User's choice:** Free text: enemies compute the time to bring the segment down with every enemy aggroed to nearby segments and the segment's current health, compare it with the detour time, and attack only if breaking is faster. Computed per segment with aggroed enemies about every half second and published as a "time to destruction" signal for nearby enemies.
**Notes:** Clarification asked in plain text (run as one body or segments?). Owner: "A run is made of segments, each with its own health."

### When a segment breaks, what does the hole do?

| Option | Description | Selected |
|--------|-------------|----------|
| Open to everyone until dawn | Passable like an authored gap; free dawn rebuild; rubble visual only | ✓ |
| Open to enemies only | Rubble still blocks squads and the king | |
| Rebuildable by day for gold | No free dawn rebuild for walls | |

**User's choice:** Open to everyone until dawn

### What counts as a stuck enemy?

| Option | Description | Selected |
|--------|-------------|----------|
| No progress toward its goal for N seconds | Data window (~3 s) while not attacking; overlay flags in a distinct colour | ✓ |
| Never reached the castle by a time budget | Per-route travel budget | |
| Both | Either condition | |

**User's choice:** No progress for N seconds

---

## Stress bar & your machine

### Dev machine hardware?

| Option | Description | Selected |
|--------|-------------|----------|
| A modern discrete GPU, well above a GTX 970 | Tighter budget (~8 ms) with the scaling assumption documented | ✓ |
| Roughly GTX 970 class or an older laptop | Measure directly | |
| Integrated graphics only | Weaker than target | |

**User's choice:** Modern discrete GPU

### Stress counts on screen at once?

| Option | Description | Selected |
|--------|-------------|----------|
| 300 enemies, 50 units, 200 projectiles | Matches the per-night cap of 300 with margin | ✓ |
| 500 enemies, 100 units, 300 projectiles | Headroom for boss nights | |
| 200 enemies, 40 units, 100 projectiles | The minimum hundreds | |

**User's choice:** 300 / 50 / 200

### Where does the stress scene live?

| Option | Description | Selected |
|--------|-------------|----------|
| Tools-only stress map | Export-excluded map under tools/ with one long gate | ✓ |
| Prototype map with raised caps | Couples the stress test to balance data | |

**User's choice:** Tools-only stress map

### How is frame time measured and recorded?

| Option | Description | Selected |
|--------|-------------|----------|
| Scripted real-window run, CI-free, report file | 1080p run, per-frame capture, committed p50/p95/worst-1% report; CI runs only the headless gate test | ✓ |
| Also a headless sim-only budget in CI | Plus a tick-budget check in CI | |

**User's choice:** Scripted real-window run with a report file
**Notes:** Follow-up round on visuals at scale declined; left to Claude's discretion with screenshots.

---

## Goldens & balance after pathing

### How to handle golden digests changing with new pathing?

| Option | Description | Selected |
|--------|-------------|----------|
| Regenerate once, deliberately, with a before/after report | Criterion 4 read as same outcomes, not same digests | ✓ |
| Keep old goldens by keeping straight-line pathing on wall-free maps | Two movement codepaths | |
| Digest-identical is the bar | Would block the phase | |

**User's choice:** Regenerate once with a report

### How strictly to prove the render swap is sim-neutral?

| Option | Description | Selected |
|--------|-------------|----------|
| Land rendering before pathing; goldens byte-identical across it | Own step, digests unchanged | ✓ |
| One combined regeneration | Loses the proof | |

**User's choice:** Rendering first, goldens identical

### Retune night counts with walls?

| Option | Description | Selected |
|--------|-------------|----------|
| Teach the bots walls, measure, retune only if the bar breaks | 7 or 8 of 10 stays; raise counts only if walls push the bot to 9 or 10 | ✓ |
| No retune; leave Phase 3 balance | Bots learn walls only for tests | |
| Always retune with walls in play | Re-pin with walls bought | |

**User's choice:** Teach the bots, retune only if the bar breaks

### Where do the wall plots go on the prototype map?

| Option | Description | Selected |
|--------|-------------|----------|
| One run per spawn road, outside the tower ring | Three plots | |
| One inner ring run around the castle | One plot | |
| Two tiers of runs: outer road walls and an inner ring | Four plots | ✓ |

**User's choice:** Outer road walls plus an inner ring (four wall plots)

---

## Claude's Discretion

- The pathing technique (flow field per goal is the research recommendation), grid resolution, field rebuild on segment changes, and where the king's wall test lives.
- The definition of "aggroed to a segment", the near-segment set, and the exact DPS and detour arithmetic, kept deterministic.
- The MultiMesh design per archetype, per-instance hit flash, health bars, rings, markers and puffs at scale, and the fate of the 256-view cap.
- Run geometry, segment length, gap width, the wall's look (Kenney Castle Kit first), the hold label text and the collapse effect.
- Wall costs and health per tier, the stuck window N, the 0.5 s cadence, all as data.
- The stress map's shape, extra gate-test metrics, overlay readouts, how the bots decide to buy walls, and the order of plans.

## Deferred Ideas

- Flying and siege enemy behaviour at walls (Phase 6); a gap-narrowing tier and paid wall rebuilds (rejected); a headless sim-step budget in CI (later); the night readability pass under crowds (Phase 8).
