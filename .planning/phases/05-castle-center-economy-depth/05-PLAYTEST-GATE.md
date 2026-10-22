# Phase 5 Playtest Gate: Castle Center & Economy Depth (owner packet)

<!-- gsd:write-continue -->

## What Claude already checked

Everything in this section was run in one local sitting by plan 05-12 on 2026-10-22 (UTC), on commit `82928bd` (the tree plans 05-01 to 05-11 and the orchestrator's wave-10 fix left). CI and the build are added below by the later tasks of the plan.

**Tests, replays and the gate stress (local, one sitting):**

- `bash tools/test.sh`: 279 scripts, 2653 tests, 2653 passing, 60264 asserts, exit 0 (876 s). No failure, no flake.
- The five replays, each run twice in one process, all agreeing: smoke `2599c7c2` (703 ticks), army `f7a967ed` (1353), walls `bfb05fc7` (1961) and economy `f4b98093` (1842) against their golden files in `tests/golden/`, byte-identical to the values plans 05-10 and 05-11 recorded; `full_idle` (no golden file by design, it plays the shipped data) won at 7000 ticks with digest `afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14`, the digest 05-BALANCE-REPORT.md records after the castle gate. No golden digest moved, so the D-08 stop rule did not fire.
- The gate stress, twice: `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0`: 300 enemies cross the 80 m wall through its 4 m gate and none is stuck.
- All 44 screenshots were captured in a real window (RTX 3060 Laptop, Forward+, 1280x720) with no script error in any shot's log and no blank image; 44 PNGs on disk, one per shot in `ALL_SHOTS`.

**The eleven shots Claude opened with its own eyes (one line each; no code changed in this plan, so none of these was re-captured):**

- `day_overview`: the keep (castle tier I) fills the top of the frame with its blue roofs, two teal-roofed Houses either side of the king, two dark-red tower discs top left and top right; "Gold: 23", the night banner and "Hold N to start Night 1" all read.
- `spot_label`: the king on a House plot, "House I / +1 gold at dawn" over the plot, readable against the grass.
- `build_in_progress`: "Tower I / Range 9.0 · Damage 3" with the coin dots filling above the king as the hold runs; reads.
- `dawn_payout`: coins fly from the Houses toward the gold counter at dawn (Gold: 23, the dark dawn tint), the keep above them; reads.
- `castle_cards`: the four tier II cards in a row over the keep (Royal Training, Commander, Masons, Prosperity), each with a first-party icon, a key tile 1 to 4 in its corner and a flavour line; the card the mouse points at (Commander) is raised, lit and shows its effect line "+25% unit health, +25% unit damage" in yellow; the plot label "Castle II / Health 100 · Arrow 3 · 2 gold at dawn" sits under it with six grey cost dots. The one thing that reads badly: the HUD night banner "Night 1 of 8" overlaps the top of the raised card and the first card (the known open point from plan 05-04, listed below).
- `castle_tier_four`: the tier IV keep is a tall stack of towers and flagpoles; the label reads "Castle IV / Max tier / Royal Training · Engineers · Golden Age"; the roof tip and flag are cropped by the top of the screen at the default zoom (known, from plan 05-04), the king's health reads 63 / 63 after Royal Training.
- `field_locked`: the king on the first of three Field plots round the Mill with "Field I / +1 gold at dawn / Needs a Mill" over it; the label tells the lock plainly.
- `harbor_pond`: a flat blue pond with three boats (cream deck and sail on a brown hull) at different angles, the dock of dark boards reaching from the teal-roofed hut into the water, "+4 gold" in the corner after the dawn payout; the water and the boats read, the king stands on the pond (it is visual only and has no collision).
- `shrine_awake_night`: the awake Shrine on its violet plot disc, a pale-violet orb above its obelisk and a bolt in flight toward the crowd on the road, gold tower arrows beside it, banner "Night 1 of 2 — 19 enemies left"; the glow and the bolt read; the banner sits over the arrows at the top of the frame.
- `castle_gate_locked`: a built Tower I with the king beside it, label "Tower II / Range 10.5 · Damage 6 / Needs Castle II"; the gate reads as a plain requirement.
- `economy_day`: a wide day view with the keep at the top, the pond with two boats and the Harbor, the Gold Mine and a Shrine on the left, the Mill with two Fields on the right, the king in the middle; the new economy is all visible in one frame (zoom 3.4 for this capture only). The buildings are small at that distance: the Mine's coins and the Mill's blades are hard to make out.
- **No presentation fix was needed, so no code changed in plan 05-12:** the open readability points are listed under "Open points" below, each one a feel call and none touching data, rules or tests.

<!-- gsd:write-continue -->
