# Pitfalls Research

**Domain:** Thronefall-like minimalist low-poly 3D tower-defense/city-builder/action hybrid, built primarily by an AI coding agent, for Windows/itch.io
**Researched:** 2026-09-28
**Confidence:** MEDIUM-HIGH (engine-agnostic RTS/TD technical pitfalls and distribution issues are HIGH confidence, well-documented; Thronefall-specific design claims are MEDIUM — inferred from developer interviews/postmortems, not the source code; AI-agent-driven gamedev pitfalls are LOW-MEDIUM — this is an emerging practice with thin published literature, reasoned from first principles and adjacent reports)

## Critical Pitfalls

### Pitfall 1: The Loop Becomes Either Trivial or Punishing — Trade-off Tension Erodes

**What goes wrong:**
Clones of tight economy/defense loops routinely end up in one of two failure states: (a) the "correct" strategy is obvious every game (e.g., always max economy first, defense is an afterthought, or vice versa) so there's no real decision-making, or (b) the game becomes a spreadsheet-optimization puzzle where one wrong build order is unrecoverable and the player feels punished rather than challenged. Thronefall's actual design secret (per developer interviews) is that gold is *always* scarce enough that economy vs. defense vs. military is a genuine trade-off every single day, and mistakes are recoverable but costly — not run-ending.

**Why it happens:**
Without the original's carefully tuned numbers, a recreation built from "the loop looks like this" (build phase → gold → night) rather than "these are the exact scarcity ratios" will drift toward whichever extreme is easiest to implement/tune first. It's also drastically easier to accidentally make gold *too plentiful* (buildings feel free, no tension) than to hit the narrow band where every purchase hurts. An LLM agent tuning numbers by reasoning ("a house should probably give ~10 gold") rather than by data from actual play will systematically miss this narrow band because it has no feedback signal.

**How to avoid:**
- Build a single fully-tunable reference map early and treat gold-income/gold-cost ratios as a first-class tunable data table (resource/JSON files), not hardcoded magic numbers in scene logic.
- Establish an explicit tuning philosophy up front: e.g. "at optimal play, the player should have <20% gold surplus at the start of each night" — a measurable target the agent can validate against a scripted simulation, not just "eyeball it."
- Require a human playtest checkpoint at the end of the core-loop-slice phase specifically to validate trade-off tension — this cannot be verified by the agent alone (see Pitfall 8).

**Warning signs:**
- Simulated/scripted playtests always converge on the same build order regardless of varied starting conditions.
- Gold surplus at night-start trends toward always-full or always-empty across difficulty levels.
- Losing a night for reasons other than "made a bad economic trade-off" (e.g., pure random bad luck, or unavoidable damage) becomes common.

**Phase to address:** Core loop slice (single map, zero meta-progression) — this is explicitly called out in PROJECT.md as the phase that must already be fun. Revisit at meta-progression phase since perks/mutators change the gold math.

---

### Pitfall 2: Remote Click-to-Build Erodes King Presence, Camera Framing, and the Travel-Time Cost

**What goes wrong:**
This project's deliberate deviation — mouse click-to-build from anywhere, instead of Thronefall's "ride the king to the spot and hold a button" — removes several things the original mechanic does simultaneously: (1) travel time is itself a resource cost (you can't build and be everywhere at once, especially at night), (2) it keeps the camera naturally anchored on the king as the single locus of attention, and (3) it makes "king presence" during building feel embodied rather than administrative. A naive remote-click implementation turns building into a menu-driven UI action disconnected from the avatar, which risks: the game feeling like a top-down management sim with a decorative avatar; the camera either staying fixed on the king (making distant build spots hard to see/click) or free-roaming (losing the "king as camera anchor" identity); and trivializing positioning decisions since there's no cost to building anywhere on the map at any time, including mid-fight.

**Why it happens:**
Click-to-build is the obvious, easy-to-implement interaction for mouse-driven UI, and it's tempting to treat it as a pure UX improvement without noticing it silently removes a core resource-cost axis (king travel time/positioning) that the original design relied on for both pacing and camera behavior.

**How to avoid:**
- Reintroduce a *cost* for remote building that approximates travel time: e.g., a build range limit from the king's current position (forces repositioning to build across the map), and/or a short cast/channel delay after clicking that can be interrupted if the king takes damage (keeps risk during night building).
- Keep the camera king-centric (follow-cam) rather than a free RTS camera; if players need to click distant spots, consider click-to-queue + auto-walk-to-build, or a soft camera pull toward the clicked spot that still frames the king, rather than decoupling the camera from the avatar entirely.
- During nights specifically, consider disabling or heavily restricting remote building so the "king fights directly" identity isn't undercut by pause-and-administrate play; Thronefall's building is primarily a daytime action for a reason.
- Treat this as a design hypothesis to validate at the core-loop-slice human playtest, not an assumption — this is the single highest-risk deliberate deviation in the project and deserves explicit before/after comparison against the reference game's feel.

**Warning signs:**
- Playtesters describe the game as feeling like "a management screen with a guy walking around" rather than "playing as the king."
- No meaningful decision is lost by being able to build anywhere instantly — i.e., removing a hypothetical range/cost limit doesn't change any playtester's strategy.
- Camera work becomes fiddly/disorienting because it's torn between following the king and framing distant build spots.

**Phase to address:** Core loop slice — this must be nailed before building further systems on top of it, since it affects camera architecture, input handling, and UI throughout the whole project.

---

### Pitfall 3: Night Readability Collapse Under Visual Clutter

**What goes wrong:**
With "hundreds of units," low-poly meshes, particle effects, and a night/dark lighting setting simultaneously, it's very easy to end up with a screen where the player cannot tell what's attacking the castle, which enemies are dangerous, or where the king is. Thronefall's night combat stays readable specifically because of strong silhouette-driven enemy design, minimal on-screen text, and deliberate color/contrast choices (enemies pop against the dark environment). Clones commonly lose this by treating "make it look cool at night" and "keep it readable" as separate, sequential concerns instead of the same constraint.

**Why it happens:**
Readability is a cross-cutting concern (lighting, enemy silhouette/color design, VFX budget, camera height/angle, HUD minimalism) that's easy to defer as "polish" and hard to retrofit — by the time dozens of enemy types and VFX exist, fixing systemic readability requires touching everything. An agent that cannot see the rendered result (see Pitfall 8) is especially prone to this because "looks readable" is fundamentally a visual judgment call it cannot make from code alone.

**How to avoid:**
- Establish a night-time art/lighting bible before building enemy variety: fixed low ambient light + warm rim-light or outline shader on units/enemies so silhouettes read against dark terrain, and a hard cap on simultaneous particle/VFX instances.
- Give every enemy type a distinct, exaggerated silhouette and a color-coded threat tier (not just distinct textures) so identification doesn't depend on close inspection.
- Automated screenshot capture at fixed test scenarios (e.g., "20 mixed enemies attacking a wall at night") reviewed by a human at each phase checkpoint — this is the most direct mitigation for an agent that can't judge visual readability itself.
- Cap concurrent enemy/projectile draw complexity independent of gameplay unit caps if needed (e.g., LOD or simplified shading beyond N enemies) so readability doesn't degrade as waves scale up in later maps.

**Warning signs:**
- Screenshot review shows overlapping/indistinguishable enemy silhouettes in mid-to-late wave scenarios.
- Health bars/UI indicators are the only way to tell enemies apart at a glance.
- The king's position on screen becomes ambiguous among a crowd of allied units (same low-poly style, similar size).

**Phase to address:** Units & combat phase (when enemy roster and night visuals are built), verified continuously via automated screenshots through content/meta-progression phases as enemy variety grows.

---

### Pitfall 4: Unit Jamming at Walls, Gates, and Chokepoints

**What goes wrong:**
With hundreds of friendly and enemy units pathing around player-built walls/barricades and through narrow gaps, naive pathfinding (recompute-every-frame A*/navmesh queries, or pure steering-only avoidance) reliably produces gridlock: units bunch up at chokepoints, oscillate trying to path around each other and the walls, or get stuck pushing into geometry indefinitely. In a wall-and-gate-centric defense game like this one, chokepoints are the *entire point* of the defense layer — if units jam there instead of funneling through convincingly, the core tower-defense fantasy breaks.

**Why it happens:**
Individual-agent pathfinding (each unit re-querying a NavigationAgent independently every frame) scales badly and doesn't account for crowd dynamics; pure flocking/steering avoidance handles crowd behavior between units but is bad at respecting hard obstacles like walls, producing units stuck vibrating against a wall segment. Godot's default per-agent NavigationAgent request pattern is known to bottleneck and lag with large agent counts if requests aren't throttled/staggered.

**How to avoid:**
- Stagger/throttle navigation path requests across frames rather than recomputing every agent every frame (e.g., re-path every N frames or on a rolling schedule, not synchronously).
- Use Godot's built-in NavigationServer avoidance (RVO) for local avoidance combined with navmesh pathfinding for global routing, rather than hand-rolled flocking — the RVO/navmesh combination is specifically built to handle static obstacles + dynamic agents together.
- For very dense same-destination crowds (a wave attacking one wall segment), consider a flow-field approach for the shared approach vectors instead of per-unit A*, which scales far better with unit count and inherently avoids the "everyone recomputes the same path independently" cost.
- Widen chokepoints/gate geometry generously beyond the visual wall gap so multiple agent radii fit through simultaneously without collision resolution fighting the nav mesh edge.
- Build a stress-test scene early (200+ units funneling through a single gate) as an automated/headless test with pass/fail on "average time-to-destination" and "stuck agent count," not just a visual check — this is testable without the agent watching the game render.

**Warning signs:**
- Units visibly vibrate or bounce in place near walls/gates in playtest footage or automated stress-test logs.
- Frame time spikes correlate with wave size crossing certain thresholds (a scaling problem, not an occasional glitch).
- Increasing wall length/gate count makes performance *worse* rather than the expected "more spread out, should be fine."

**Phase to address:** Units & combat phase (introduce navigation architecture before enemy roster grows); stress-tested again at content/map-building phase since handcrafted maps will have unique chokepoint geometry per map.

---

### Pitfall 5: Target-Selection Thrash — Units Flip-Flop and Lose Effective DPS

**What goes wrong:**
A naive "attack nearest enemy, re-evaluate every frame" targeting rule causes units (both player troops and enemies) to switch targets constantly as relative distances change slightly frame to frame, especially in crowded melee scrums. This looks visually erratic (units spin/reorient constantly) and functionally wastes DPS, since attacks with wind-up or projectile travel time get cancelled/retargeted before landing.

**Why it happens:**
"Nearest enemy" re-evaluated every frame is the simplest targeting rule to write and looks correct in isolated testing with 1-2 units, but breaks down at the unit density this game targets (hundreds of units) where many candidates are near-equidistant and jitter across the "nearest" threshold constantly.

**How to avoid:**
- Commit to a target for a minimum duration (a "commitment window," e.g. 1-2 seconds or until the target dies/leaves range/leaves line of sight) rather than re-evaluating every frame; only force a retarget for explicit reasons (target died, target out of range).
- Use a seeded tie-break for near-equidistant candidates instead of pure distance comparison, so results are stable and deterministic — this also helps automated/headless testing reproduce specific combat scenarios.
- Separate "threat scanning" (cheap, can run every frame) from "commit to attack" (expensive re-evaluation, throttled) so responsiveness to new threats doesn't require constant full re-evaluation of the current target.

**Warning signs:**
- Units' attack animations restart/cancel repeatedly without landing hits in dense fights.
- DPS-per-unit measured in a controlled stress test is significantly lower than the theoretical value (attack rate × damage) once unit density passes a threshold.
- Visual "jitter" — units rotating rapidly back and forth — visible in automated screenshot/video capture of crowd combat.

**Phase to address:** Units & combat phase, verified via headless combat-simulation tests (deterministic seed, fixed unit counts, assert on total damage dealt over N seconds) rather than relying on visual inspection alone.

---

### Pitfall 6: Stat Modifier Stacking Bugs Across Perks × Mutators × Upgrades

**What goes wrong:**
With building upgrade choices, unlockable perks (limited loadout), and mutators all potentially modifying the same underlying stats (damage, gold income, attack speed, HP), the order and method of combining these modifiers produces silently wrong numbers if not designed deliberately. Known failure patterns from other games: multiple percentage bonuses that should stack additively instead get applied multiplicatively in sequence (or vice versa) depending on the order perks were "picked up"/applied in code, producing results that differ from what the UI displays or what the player would reasonably calculate by hand (a well-documented real example: Fallout 4's Sandman/Ninja/Cloak perk stacking order bug).

**Why it happens:**
It's very easy to implement each new perk/mutator as "multiply this stat by X" applied directly and sequentially as systems are added one at a time, without a unified modifier-aggregation architecture. This works fine with 2-3 modifiers and silently produces wrong (usually overpowered, sometimes underpowered) results once the perk/mutator count in PROJECT.md's scope (multiple perks per run × mutators × per-building upgrade choices) combines in ways never individually tested.

**How to avoid:**
- Design a single stat-modifier aggregation system up front (before the first perk is implemented) with explicit "buckets": all additive percentage modifiers to a given stat sum together, then multiplicative/multiplier-class modifiers apply on top, in a fixed, documented order — never order-of-application-dependent (order of *pickup*, not order of *bucket*, must not matter).
- Write it as a small, isolated, pure-function module (stat name + list of modifiers → final value) that can be headlessly unit-tested with known input/output pairs, independent of the rest of the game — ideal for an agent to verify correctness without needing to observe gameplay.
- When adding each new perk/mutator, add a corresponding unit test asserting its effect on a baseline stat, and a combined test with 2-3 other modifiers active simultaneously to catch bucket-classification mistakes early.
- Surface the final computed value in a debug overlay (see Pitfall 8) so discrepancies between "intended" and "actual" are visible during manual playtests too.

**Warning signs:**
- A perk/mutator combination produces a stat value that doesn't match manual calculation from the displayed percentages.
- Enabling multiple economy-boosting perks produces runaway gold income disproportionate to any single perk's stated effect (or the reverse — diminishing returns nobody intended).
- Bug reports (from self-playtesting) of specific perk/mutator *combinations* behaving oddly, rather than any perk in isolation.

**Phase to address:** Meta-progression phase (when perks/mutators/upgrades are introduced) — but the *architecture* for stat aggregation should be designed and tested before the first upgrade-choice or perk is added, ideally scaffolded during the units & combat or economy phase when the base stat system is first built.

---

### Pitfall 7: Save Data Corruption / Versioning Failures Across Maps and Meta-Progression

**What goes wrong:**
Campaign progress (map unlocks, per-map XP/levels, weapon/perk unlocks, high scores) must persist between sessions per PROJECT.md. As the save schema evolves during development (new fields for new perks, mutators, maps added over time), old save files loaded against new code either crash, silently drop data (lost unlocks), or worse, silently corrupt other fields. This is especially likely here because the agent itself will be iterating on the save schema repeatedly across many phases (adding weapons, perks, mutators, maps) — every phase is a potential schema-breaking change.

**Why it happens:**
It's tempting to serialize the exact in-memory game-state structure directly (e.g., dump a dictionary/resource as-is) without a version field or migration path, because it's the fastest way to get persistence working. This works until the very next field is added or renamed, at which point old saves either fail to load or load with wrong/missing values that aren't obviously wrong (e.g., a new stat defaults to 0 instead of an intended value, silently weakening the player's unlocked loadout).

**How to avoid:**
- Include an explicit integer schema-version field in the save file from the very first implementation, even before any format changes are anticipated.
- Write forward-only migration functions (old format → next format) that are pure and independently testable; never deserialize old data directly against the current struct/resource definition.
- Write to a temp file and atomically rename/replace on save (never overwrite in place) to avoid half-written corrupt saves from crashes or forced quits during a save operation.
- Maintain a small fixture library of "save file from phase N" test files and run automated load tests against the current code on every phase transition — this is critical given how often the schema will change (new maps, weapons, perks, mutators added over many phases) and the agent has no way to manually notice a subtly broken save by eye.
- Keep unlock/progress data structurally separate from transient run state (current map attempt, current gold) so a corrupted/incompatible in-run state can't cascade into destroying permanent unlocks.

**Warning signs:**
- Any manual test of "load an older save with the current build" isn't part of the regular testing routine (this is the single most common way save bugs ship silently).
- Save file format has no version field, or the version field exists but no migration code path has ever been exercised.
- New fields default to falsy/zero values without an explicit "what should an old save get for this new field" decision.

**Phase to address:** Introduce save/load system with versioning as soon as any persistent state exists (likely economy/building phase for basic progress, definitely by meta-progression phase); add regression fixture tests at every subsequent phase that touches the save schema, through to release.

---

### Pitfall 8: AI-Agent Blindness — Invisible Feel Regressions and Silently Broken Scenes

**What goes wrong:**
The agent building this game cannot see the rendered game, cannot play it, and cannot judge "does this feel good" — a category of bug/regression (camera feels wrong, hit feedback feels weak, a scene's visual layout is broken, an enemy mesh is facing the wrong way, UI elements overlap) is fundamentally invisible to code review and passes all logical/unit tests while being obviously broken or unfun to a human. Left unchecked, many phases' worth of work can compound "looks/feels fine in the code" issues that only surface at the next human playtest, by which point the root cause may be buried under later changes.

**Why it happens:**
Standard AI-agent development loops (write code → run automated tests → assume correctness) have no feedback channel for aesthetic/experiential quality, which is most of what makes a Thronefall-like game good or bad. Logical correctness (a building costs the right amount of gold) and experiential correctness (the loop *feels* tight) are different axes, and only the former is verifiable without a human or a rendering-aware tool in the loop.

**How to avoid:**
- Build a debug overlay early (on-screen stat readouts: gold/sec, current wave composition, active modifiers, frame time, unit counts) so both automated screenshot review and human playtests can quickly verify systemic state without guesswork.
- Use automated screenshot/video capture at fixed checkpoints (e.g., "start of night 3, default loadout") as part of the phase-completion routine — captured artifacts the human can review quickly are far cheaper than a full playtest and catch gross breakage (missing meshes, broken UI, wrong camera) that an agent cannot self-detect.
- Schedule a genuine human playtest checkpoint at the end of every phase that touches feel (core loop, combat, camera/controls, difficulty tuning, meta-progression) — not just at major milestones — and treat "does this feel like Thronefall" as a phase-completion criterion equal in weight to "does this pass tests."
- Write headless simulation tests for systemic correctness (economy balance, combat DPS, pathfinding stress tests, save/load) so the agent can self-verify everything that *can* be verified without rendering, reserving human playtests for the things that can't.
- Use deterministic seeds for any randomized systems (wave composition randomization if any, mutator rolls) so a reported "feels off" bug from a human playtest can be reproduced exactly by the agent afterward.

**Warning signs:**
- A phase is marked complete based solely on automated tests passing, with no screenshot or human review step.
- Playtest feedback repeatedly surfaces the same category of issue (camera, feedback/juice, readability) late, after multiple phases have built on top of the affected system.
- The agent cannot answer "what does this look like right now" without asking a human to check.

**Phase to address:** Cross-cutting — establish debug overlay, screenshot capture tooling, and the human-playtest-checkpoint cadence as infrastructure during the core loop slice phase (first thing built, before content scales up), and enforce the checkpoint at every subsequent phase.

---

### Pitfall 9: Editor-Only Workflows and Opaque Binary Assets Block Agent Iteration

**What goes wrong:**
Game engines default to workflows that assume a human sitting at the editor GUI: dragging nodes in a scene tree, tweaking values in an inspector panel, visually placing meshes, and saving binary or hybrid scene formats. An agent working via files and shell cannot do any of this directly — if the project's scenes, level layouts, or tuning data live only in a GUI-edited binary format, the agent is reduced to blind guessing or cannot make changes at all without a human relaying every edit.

**Why it happens:**
Default engine project setups don't optimize for text-editable, diffable, agent-writable files; it's the path of least resistance to just use the editor's default save formats and hand-place values in the inspector, especially for a solo/portfolio project where "just use the editor" is the normal habit from tutorials.

**How to avoid:**
- Prefer the engine's text-based resource/scene formats where available (e.g., Godot's `.tscn`/`.tres` are plain text, human- and agent-readable/diffable, unlike a binary `.scn`/`.res`) and confirm this is the default export setting, not an opt-in the agent must remember every time.
- Externalize all tunable game data (build costs, unit stats, wave compositions, perk effects) into plain data files (JSON/Resource `.tres`/similar) rather than hardcoded inspector values or embedded in scene-tree node properties, so the agent can read and modify balance data directly without touching scene structure.
- For anything that genuinely requires visual/spatial placement (build-spot positions on a handcrafted map, enemy spawn points), define a text-based authoring format (e.g., a coordinate list in a data file) that both the agent and a human-in-the-editor can produce/edit, rather than requiring GUI-only placement.
- Verify early (during stack/engine research, before committing) that the chosen engine's CLI/headless mode can import, build, and run scenes non-interactively — if any critical asset pipeline step requires the GUI with no CLI equivalent, that's a hard blocker for agent-driven iteration on that content type.

**Warning signs:**
- Any required project setup step says "open the editor and click X" with no scripted/CLI equivalent.
- Balance tuning changes require locating and editing a value nested inside a scene file rather than a dedicated data file.
- The agent produces a diff that is unreadable (binary blob change) for what should be a simple numeric tweak.

**Phase to address:** Engine/stack decision and project scaffolding (before core loop slice) — this is foundational; retrofitting text-based data-driven workflows after content already exists in ad hoc inspector values is expensive.

---

### Pitfall 10: Scope Creep — Full Meta-Progression Built Before the Core Loop Is Proven Fun

**What goes wrong:**
PROJECT.md commits v1 to full meta-progression (weapons, perks, mutators + scoring, per-map XP) across 3-5 handcrafted maps. If work on perks/weapons/mutators/scoring starts before the single-map, zero-meta-progression core loop is validated as fun (explicitly named as the Core Value in PROJECT.md), the project risks building an elaborate progression system on top of a loop that isn't actually satisfying yet — requiring expensive rework of every dependent system if the core loop needs fundamental changes later (e.g., changing how gold scarcity works, which cascades into every perk that touches gold).

**Why it happens:**
Meta-progression systems (unlock trees, scoring, perk lists) are individually well-specified and "easy" to build in the sense that they don't require subjective feel-tuning — they're attractive work for an agent because progress is legible (X perks implemented, Y mutators implemented) even when the more important, harder-to-verify core loop isn't actually done. This creates a false sense of progress.

**How to avoid:**
- Sequence the roadmap so the core loop slice (single map, no meta-progression, per PROJECT.md's own Core Value framing) is a gated phase with an explicit human-playtest pass/fail checkpoint before any meta-progression work begins.
- Treat the "3-5 handcrafted maps" content requirement as a content-pipeline risk distinct from the "full meta-progression" systems requirement — sequence map-building and meta-progression so systems (weapon/perk/mutator effects) are built generically enough to apply to new maps without per-map special-casing, avoiding a linear cost increase per map.
- Explicitly budget and track "content pipeline" time (how long does one handcrafted map with waves, build spots, and balancing take once systems exist) after the first map, to catch a bottleneck early rather than discovering at map 4 that each map takes far longer than planned.

**Warning signs:**
- Meta-progression systems (perks, mutators, weapons) are being implemented while the single reference map still doesn't have a "this is fun" human sign-off.
- The second or third handcrafted map takes as long or longer than the first, despite systems already existing (signals systems aren't generic/reusable enough).
- Roadmap phases are organized by system category (all perks, then all mutators, then all maps) rather than by validated increments of player-facing value.

**Phase to address:** Roadmap/phase sequencing itself — core loop slice must precede and gate meta-progression phases; content pipeline efficiency should be assessed after the first handcrafted map, before committing to the full 3-5 map content plan.

---

### Pitfall 11: CC0 Asset Pack Visual Inconsistency (Scale, Style, Palette Mismatch)

**What goes wrong:**
Mixing CC0 low-poly packs from different sources (Kenney, KayKit, Quaternius, etc.) without normalization produces a visually incoherent "asset flip" look: differing polygon densities (Kenney packs run very low-poly with flat colors; Quaternius models can run several times higher poly with different texturing conventions), inconsistent real-world scale (a Kenney building and a Quaternius character may not be proportioned to stand together believably), and clashing color palettes (some packs use flat vertex colors, others use texture atlases with their own palette). This directly undermines the "cohesive color palette" and "stylized low-poly" requirements in PROJECT.md.

**Why it happens:**
CC0 packs are attractive precisely because they're free and cover different needs (one pack for buildings, another for characters, another for props), but each pack was authored independently with its own scale reference, poly budget, and shading approach — there's no inherent guarantee of interoperability just because all pieces are CC0-licensed.

**How to avoid:**
- Establish a single canonical scale reference (e.g., "1 unit = 1 meter, king character is X units tall") before importing any pack, and normalize every imported model's scale to match on import, not ad hoc per-instance in scenes.
- Pick a primary pack for the majority of visible assets (likely whichever covers buildings + characters + terrain most completely) and use other packs only to fill genuine gaps, minimizing the number of distinct art styles visible at once.
- Apply a unified shading approach across all imported meshes regardless of source (e.g., a single custom flat-shaded/toon material/shader forcing a consistent look) rather than relying on each pack's native materials — this is a strong mitigation because it makes style consistency a rendering-pipeline decision rather than a per-asset curation problem.
- Constrain the color palette actively (a small defined palette applied via material/shader tinting) rather than trusting source packs to already share a palette.

**Warning signs:**
- Side-by-side screenshot comparison shows visibly different poly density/shading style between adjacent objects (e.g., a smooth-shaded tree next to a flat-shaded building).
- Characters and buildings look mismatched in scale when placed together in a test scene.
- Import settings vary ad hoc per-asset instead of following a documented, consistent pipeline.

**Phase to address:** Presentation/art pipeline setup (early, ideally alongside or just after core loop slice, before content scales across multiple maps and many enemy/building types) — establishing the normalization pipeline late means re-touching every already-placed asset.

---

### Pitfall 12: IP/Legal Risk From Naming, Store Page Similarity, and Literal Copying

**What goes wrong:**
"Faithful recreation" carries real risk of drifting from "recreating the mechanics" (which is generally legally safe — game mechanics/rules are not copyrightable) into "copying protectable expression" (specific UI layouts, exact map designs, distinctive names, marketing copy, or visual presentation that's "confusingly similar" to Thronefall's branding). PROJECT.md already correctly scopes this out (original codename, CC0 assets, no Thronefall trademarks/assets), but the risk resurfaces at execution time: store page copy that name-drops "Thronefall" for discoverability, a UI layout that's a pixel-for-pixel recreation rather than an original interpretation, or map layouts copied so literally they read as tracing rather than inspiration.

**Why it happens:**
"Faithful recreation" as a design goal creates natural pressure to reference the source directly during development (screenshots, exact numbers, exact layouts) and that reference material can leak into final assets/copy if not deliberately filtered — especially on a store page, where "if you liked Thronefall, you'll like this" is the single most tempting (and riskiest) marketing sentence to write.

**How to avoid:**
- Treat Thronefall as a design *reference* for mechanics/rules only; UI layout, specific wording, exact map geometry, and iconography should be original interpretations, not traced copies — the "why the loop works" analysis (Pitfall 1) is the kind of reference that's safe; screenshotting Thronefall's exact HUD and rebuilding it pixel-for-pixel is not.
- Do not use "Thronefall" (or confusingly similar variants) anywhere in the project name, store page title/copy, or marketing materials; a factual, restrained comparison ("inspired by minimalist tower-defense/strategy games" rather than naming the specific title) is lower risk than direct namedropping, though even indirect comparison should be reviewed before publishing since this is a portfolio project representing the author's judgment.
- Design handcrafted maps as original layouts inspired by the *category* of challenge Thronefall's maps present (e.g., "a coastal map with a harbor economy angle") rather than recreating specific named Thronefall maps tile-for-tile.
- Keep a running note of any point during development where source material (screenshots, wiki data, video) was consulted directly for a specific numeric value or layout, so it's possible to review before release whether anything crossed from "inspiration" into "copy."

**Warning signs:**
- Store page draft copy includes the word "Thronefall" or a deliberately similar constructed name.
- A UI mockup or map layout, compared side-by-side with reference screenshots, is difficult to distinguish at a glance.
- Marketing materials lean on "like [Thronefall] but..." framing rather than describing the game on its own terms.

**Phase to address:** Ongoing discipline through content/presentation phases; explicit final review at the release/distribution phase before the store page goes live.

---

### Pitfall 13: Windows Unsigned-Exe SmartScreen and Antivirus False Positives on itch.io

**What goes wrong:**
Exported Windows executables from engines with a packed-payload structure (a common pattern: engine binary + appended/bundled data blob) frequently trigger Windows SmartScreen "unrecognized app" warnings and, more seriously, false-positive antivirus/Defender detections, because the executable's structure superficially resembles patterns used by malware packers. This is a well-documented, currently active issue for at least one likely-candidate engine (Godot), not a hypothetical risk. For a portfolio project distributed as an unsigned itch.io download, this directly harms the first impression: a scary OS-level warning before the player has even opened the game.

**Why it happens:**
Code-signing certificates cost money and require an established publisher identity, neither of which fits a zero-budget portfolio project; without a signature, there's no chain of trust to override heuristic detection, and the specific way many engines package the exported binary (compressed/appended data) pattern-matches known packer signatures used by real malware.

**How to avoid:**
- Budget for this from the start rather than being surprised at release: plan the itch.io page/description to proactively explain the SmartScreen warning and reassure players it's a known false positive for this export method (with a link to the engine's own documentation on the issue, if available), rather than reacting to it after launch.
- Follow the specific engine's documented guidance for minimizing false-positive triggers at export time if such guidance exists (e.g., export flags, avoiding certain compression settings) — verify this during the engine/stack research and export/packaging setup, not discovered for the first time at release.
- Consider a free/low-cost self-signed certificate as a partial mitigation (does not eliminate SmartScreen warnings for a new unknown publisher, but is better than nothing and costs nothing beyond setup time) if budget-zero options are explored; otherwise accept and clearly communicate the limitation given the zero-budget constraint.
- Test the actual exported build on a clean Windows machine (or VM) with default Defender settings before release, not just on the development machine (which likely has exclusions/history that suppress the warning).

**Warning signs:**
- The exported build has never been tested on a machine without prior Defender/SmartScreen history for that file.
- itch.io page copy doesn't mention or prepare players for a possible warning.
- No investigation has been done into the specific chosen engine's known false-positive patterns before the release phase.

**Phase to address:** Export/packaging setup (verify early, don't wait for release) and release/distribution phase (test on a clean machine, prepare store page messaging).

---

### Pitfall 14: Tuning Without Data and Without Play — Difficulty Curve Guesswork

**What goes wrong:**
Difficulty curves (wave escalation across nights, per-map difficulty progression across 3-5 maps, mutator-driven difficulty scaling) are traditionally tuned through iterative human play and feel, adjusted by "that night felt too easy/too hard." An agent that cannot play the game has no direct feedback loop for this and risks either reasoning abstractly about numbers ("wave 5 should have roughly 1.5x the enemies of wave 4") without any grounding in whether that's actually survivable/tense, or never revisiting initial guesses because nothing forces reconsideration.

**Why it happens:**
Difficulty tuning is inherently experiential and probabilistic (depends on player skill, build choices, RNG if any) — it resists being fully captured by a deterministic headless test the same way, say, save-file correctness does, so it's the category of work most likely to be under-verified in an agent-driven workflow unless deliberately compensated for.

**How to avoid:**
- Build a headless "simulated playthrough" harness that runs the game logic (not rendering) with a scripted/AI-controlled king and simple troop-commanding heuristics against each night's wave data, logging outcomes (won/lost, gold remaining, damage taken) across many runs and difficulty settings — this gives the agent a *proxy* signal for difficulty even without human play, useful for catching gross outliers (a wave that always wipes the player, or never threatens them) before human playtesting.
- Explicitly reserve human playtesting specifically for difficulty *feel* validation (not just correctness) at defined checkpoints — every new map and every meaningful wave-escalation change should get a human pass, since this is the category of pitfall most resistant to automated verification.
- Data-drive all wave composition and scaling numbers (not hardcoded per-map logic) so difficulty tuning is a data-editing task the agent can iterate on quickly based on playtest feedback, rather than a code-refactoring task.
- Track a simple per-map/per-night difficulty target (expected survivability at "average" skill, informed by playtest results) as living documentation, so tuning changes have a reference point rather than being re-guessed from scratch each time.

**Warning signs:**
- Wave/difficulty numbers have never been validated against any simulated or human playthrough, only reasoned about in the abstract.
- Difficulty escalation across nights/maps follows a suspiciously uniform mathematical formula (e.g., flat +10% per night) applied without any playtest-driven adjustment.
- Playtest feedback about difficulty repeatedly contradicts the agent's assumptions, suggesting the simulated-playthrough proxy (if any) isn't correlating with real player experience.

**Phase to address:** Units & combat / enemies & waves phase (build the simulation harness alongside first wave content), with human-playtest-driven difficulty passes at every subsequent phase that adds maps or escalates content.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Hardcoding wave/build-cost numbers directly in scene/node logic instead of data files | Faster to get first content working | Blocks agent-driven tuning iteration, breaks Pitfall 9/14 mitigations | Never beyond earliest prototype spike |
| Applying perk/mutator effects as direct sequential stat multiplications without a modifier-aggregation system | Fast to add each individual perk | Compounds into Pitfall 6 stacking bugs as perk count grows | Only acceptable with 1-2 perks total; must be refactored before meta-progression phase |
| Skipping save-schema versioning until "the format is stable" | Saves initial setup time | Every subsequent schema change risks silent corruption/data loss (Pitfall 7) | Never — add version field on the very first save implementation |
| Using per-unit synchronous navmesh queries every frame instead of staggered/throttled requests | Simplest to implement, works fine at low unit counts | Gridlock and frame drops once unit counts scale to "hundreds" (Pitfall 4) | Acceptable only for early combat prototyping with <20 units |
| Relying on default engine editor binary scene format instead of confirming text-based export | No setup friction | Blocks agent diffing/editing (Pitfall 9) | Never for this project's agent-driven workflow |
| Testing only on the development machine, never a clean Windows install | Convenient | Misses SmartScreen/AV false-positive issues until release (Pitfall 13) | Acceptable until the export/packaging phase, must be tested before release |
| Deferring the debug overlay / screenshot tooling until "something looks wrong" | Avoids upfront tooling work | Every prior phase accumulates unverifiable feel regressions (Pitfall 8) | Never — build minimal version during core loop slice |

## Integration Gotchas

Not a networked/service-integrated game, but analogous "external system" integration points apply:

| Integration Point | Common Mistake | Correct Approach |
|--------------------|-----------------|-------------------|
| itch.io / butler upload pipeline | Manually zipping and uploading builds ad hoc, inconsistent between test and release builds | Script the export + package + butler-push pipeline so release builds are reproducible and match what was tested |
| CC0 asset pack import | Importing packs with default/inconsistent import settings per-asset (varying scale, shading, collision generation) | Define and document a standard import preset applied consistently across all imported packs (see Pitfall 11) |
| License/attribution tracking | Assuming "CC0" without verifying each specific pack's actual license (some "free" packs are CC-BY or custom-licensed, not CC0) | Maintain a simple manifest (source, license, URL) for every imported asset pack at time of import, verified against the pack's actual license page, not just its marketing description |
| Godot (or chosen engine) headless/CLI test runner in CI or local automation | Assuming editor-based manual test runs are equivalent to what a headless run will do (audio/display driver differences) | Explicitly test the headless invocation (`--headless` or engine equivalent) locally before relying on it for automated regression tests |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| Individual MeshInstance3D per unit/prop instead of instancing | Draw call count rises linearly with on-screen object count; frame time degrades with more units/props on screen | Use engine mesh-instancing (e.g., Godot MultiMeshInstance3D) for repeated meshes (units, projectiles, trees/props) so many instances share one draw call | Noticeable once simultaneous on-screen units + props exceeds roughly a few hundred draw calls; matches this project's "hundreds of units" target directly |
| Per-frame synchronous navmesh path requests for every agent | Frame time spikes scale with unit count; agents visibly stutter/lag in movement updates during large waves | Stagger/throttle path requests across frames; combine with RVO/flow-field approaches for dense same-destination groups (Pitfall 4) | Reported to bottleneck starting in the low hundreds of concurrent agents in Godot's default NavigationAgent pattern |
| RigidBody/physics-simulated projectiles for high-volume ranged combat | Physics step time grows with projectile count; unpredictable collision resolution at high volume | Use simple raycasts or kinematic/manually-integrated movement for projectiles instead of full physics bodies, reserving physics simulation for cases that need it | Breaks down once simultaneous projectile count reaches the hundreds during large multi-archer waves |
| Per-frame allocation (e.g., creating new arrays/objects in `_process`/update loops for target lists, pathing results) | Periodic frame-time hitches correlated with garbage collection, especially in GC-managed scripting layers | Reuse pre-allocated buffers/pools for hot-path per-frame logic (target-candidate lists, temporary path arrays) instead of allocating fresh each frame | Becomes visible as stutter once enough units run this logic every frame simultaneously — exact threshold depends on engine/scripting language, worth profiling once combat systems exist |
| Full re-evaluation of every enemy's target every frame (see Pitfall 5) treated purely as a gameplay bug | Also a hidden performance cost — repeated distance-comparison sweeps across large unit counts every frame | Fix via the same commitment-window approach as Pitfall 5; this is both a feel bug and a performance trap simultaneously | Compounds badly once both unit count and enemy count are in the hundreds simultaneously (a full night wave) |

## Security Mistakes

Low relevance for a single-player, offline, non-commercial portfolio game, but a few domain-adjacent points:

| Mistake | Risk | Prevention |
|---------|------|------------|
| Trusting save-file contents as unmodifiable | Trivial for anyone to hand-edit local save files to unlock everything/inflate scores | Low actual risk for a single-player portfolio project — not worth engineering effort to prevent; explicitly decide this is acceptable rather than leaving it unconsidered, since it could otherwise be mistaken for a "bug" late in development |
| Misattributing a non-CC0 asset as CC0 due to sloppy sourcing | Public portfolio project distributing content under an incorrect license claim — a credibility/legal issue, not a technical security one | Verify each pack's actual license at the source (not from memory or a marketplace listing) and keep a manifest (see Integration Gotchas) |
| Shipping debug overlay/cheat tools (built per Pitfall 8) enabled in the release build | Undermines the intended scoring/difficulty experience for anyone who finds a leftover debug hotkey | Gate all debug/dev tooling behind a build flag stripped from release exports; verify by testing the actual release build, not just the dev build |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|--------------|-------------------|
| Remote click-to-build with no visual indication of build range/cost from king's position | Player builds impulsively without understanding the positioning trade-off (Pitfall 2), loop feels flat | Show a clear range indicator/cost-scaling cue tied to king distance, and disallow or visibly penalize out-of-range builds |
| Unit selection/command UI that doesn't clearly show what's selected or what "hold position" vs "move" does | Player loses track of army state mid-fight, frustration during chaotic night combat | Persistent, minimal selection indicator (per Thronefall's own minimalist HUD philosophy) and clear, immediate visual feedback on command issued |
| No pre-night summary of incoming wave direction/composition strength | Player can't make an informed final build decision before committing to start the night | Telegraph wave direction/rough strength during the day (already an Active requirement in PROJECT.md) — treat this as a hard requirement, not nice-to-have, since it's core to the trade-off tension in Pitfall 1 |
| Upgrade choice UI that doesn't clearly show the trade-off between branching options | Player picks upgrades semi-randomly rather than making a meaningful strategic choice, undermining Pitfall 1's core tension | Side-by-side comparison of branching upgrade effects at the point of choice, consistent formatting across all building types |
| Retry-with-penalty flow (retrying a night costs score) not clearly communicated before the player commits to retry | Player feels punished by a hidden rule rather than making an informed trade-off | Show the exact penalty before confirming a retry, consistent with the minimalist-but-transparent design philosophy |

## "Looks Done But Isn't" Checklist

- [ ] **Wave spawning:** Often missing telegraphing/direction indicators during the day — verify the player can see incoming spawn direction before the night starts, not just that enemies spawn correctly.
- [ ] **Perk/mutator system:** Often missing combined-effect testing — verify with automated tests that stacking 2-3 modifiers simultaneously produces the mathematically expected result (Pitfall 6), not just that each perk works alone.
- [ ] **Save/load system:** Often missing corruption/version-mismatch handling — verify by attempting to load a save file from an earlier schema version against current code, not just a freshly-saved file.
- [ ] **Build-spot UI:** Often missing affordability/range feedback — verify build spots visually communicate whether they're affordable and (per Pitfall 2) in range before the player clicks, not just reject the click silently after the fact.
- [ ] **Night end condition:** Often missing edge-case handling for an enemy stuck in geometry (behind a wall gap, wedged in a corner) that never dies and soft-locks the night — verify with a stress test that all enemies are always reachable/killable, not just that "night ends when enemy count reaches zero" logic is correct in the common case.
- [ ] **Difficulty scaling across maps:** Often missing validation beyond the first map — verify each of the 3-5 maps has actually been difficulty-tuned via playtest or simulation (Pitfall 14), not just copy-pasted scaling formulas from map 1.
- [ ] **Windows export build:** Often missing a clean-machine test — verify the actual distributed .exe runs and installs cleanly on a machine without the development environment's Defender exclusions (Pitfall 13).
- [ ] **Asset license manifest:** Often missing entirely until release crunch — verify every imported asset pack has a recorded, source-verified license before the project is made public, not assembled retroactively.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|----------------|------------------|
| Loop trivial/punishing (Pitfall 1) | MEDIUM | Since numbers are data-driven (per prevention strategy), retune the gold-income/cost data tables directly; re-run simulated playthroughs and a human playtest pass to confirm before moving on |
| Remote-build feel loss (Pitfall 2) | MEDIUM-HIGH | If discovered late, retrofitting range/cost limits and camera behavior touches input handling and UI broadly; cheaper the earlier it's caught — this is why it's flagged for the core-loop-slice checkpoint specifically |
| Unit jamming (Pitfall 4) | MEDIUM | Isolate to a reproducible stress-test scene, swap the specific avoidance/pathing strategy (e.g., add flow-field for the worst chokepoints) without needing to touch unrelated combat/AI code, since navigation should be decoupled from combat logic |
| Stat stacking bugs (Pitfall 6) | LOW (if aggregation architecture exists) / HIGH (if not) | With a proper modifier-aggregation system, fixing a bucket-classification mistake is a small localized change; without one, may require refactoring every perk/mutator's implementation — strong argument for building the architecture correctly the first time |
| Save corruption (Pitfall 7) | HIGH for affected players, LOW-MEDIUM for the codebase if versioning existed | With version fields already in place, write a new migration function; without them, may require accepting data loss for existing saves and communicating this clearly — much worse for any player who has invested campaign progress |
| CC0 asset inconsistency (Pitfall 11) | MEDIUM-HIGH | A unified shading/material pipeline applied retroactively can salvage inconsistent source assets without re-sourcing them; full re-sourcing of mismatched packs is expensive and should be a last resort |
| IP/legal drift (Pitfall 12) | LOW-MEDIUM if caught before release, HIGH after | Rename/rebrand and revise copy before any public listing is trivial; addressing it after a store page or build is public (e.g., following a complaint) is reputationally costly for a portfolio project |
| SmartScreen/AV warnings (Pitfall 13) | LOW | Cannot be fully eliminated without a paid certificate; recovery is proactive communication on the store page plus following the engine's known mitigation guidance, not a code fix |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| 1. Loop trivial/punishing | Core loop slice | Simulated playthrough harness + human playtest sign-off before any further phase begins |
| 2. Remote-build feel loss | Core loop slice | Explicit before/after comparison against reference game feel at human playtest checkpoint |
| 3. Night readability collapse | Units & combat (enemy/night visuals) | Automated screenshot review at fixed combat scenarios, repeated through content phases |
| 4. Unit jamming at chokepoints | Units & combat (navigation architecture) | Headless stress test: 200+ units through a single gate, pass/fail on stuck-agent count and frame time |
| 5. Target-selection thrash | Units & combat | Headless combat simulation asserting measured DPS matches theoretical DPS within tolerance |
| 6. Stat modifier stacking bugs | Base stat system (before first perk/upgrade), enforced at meta-progression phase | Unit tests per perk/mutator plus combined-modifier test cases |
| 7. Save data corruption/versioning | First persistent state (economy/building phase), enforced through meta-progression and release | Automated load tests against a fixture library of old-schema save files, run every phase that touches the schema |
| 8. AI-agent blindness (feel regressions) | Core loop slice (tooling), enforced every phase | Debug overlay + automated screenshots + mandatory human playtest checkpoint per phase |
| 9. Editor-only workflows / opaque assets | Engine/stack decision, project scaffolding | Confirm text-based scene/resource formats and headless CLI capability before content work begins |
| 10. Scope creep (meta-progression before core loop) | Roadmap sequencing itself | Core loop slice has an explicit pass/fail gate before meta-progression phases are scheduled |
| 11. CC0 asset inconsistency | Presentation/art pipeline setup | Side-by-side screenshot check of assets from different packs sharing a scene, before content scales across maps |
| 12. IP/legal risk | Ongoing; final check at release | Manual review of store page copy, UI, and map designs against reference material before publishing |
| 13. Windows SmartScreen/AV warnings | Export/packaging setup, release/distribution | Clean-machine test of the actual release build; store page messaging prepared in advance |
| 14. Difficulty tuning guesswork | Units & combat / enemies & waves (build simulation harness) | Human playtest difficulty pass at every phase adding maps or wave escalation |

## Sources

- [Deep dive: how Thronefall went 'minimal' to hit 300k sales](https://newsletter.gamediscover.co/p/deep-dive-how-thronefall-went-minimal)
- [Mastering minimalism and layering complexity with strategy game Thronefall — Game Developer](https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
- [Thronefall — A Take on Minimalism & Trimming the Fat from Strategy](https://donatvatoci1.medium.com/thronefall-a-take-on-minimalism-trimming-the-fat-from-strategy-b76b2413a10c)
- [Thronefall's Paul Schnepf: "I Want to Take the Headache Out of Strategy Games" — I.N.T](https://int-magazine.com/interview/paul-schnepf-of-thronefall/)
- [Building a best-selling game with a tiny team — with Jonas Tyroller (Pragmatic Engineer)](https://newsletter.pragmaticengineer.com/p/thronefall)
- [Steam Community — Idea for more freedom of building placement (Thronefall discussion)](https://steamcommunity.com/app/2239150/discussions/0/4293691221503857538/)
- [Optimizing Tower Defense for Focus and Thinking — Defender's Quest (Fortress of Doors)](https://www.fortressofdoors.com/optimizing-tower-defense-for-focus-and-thinking-defenders-quest/)
- [How to handle large amounts of NavigationAgents / pathfinding? — Godot Forums](https://godotforums.org/d/31934-how-to-handle-large-amounts-of-navigationagents-pathfinding)
- [3D Pathfinding in Godot 4: Complete Setup — Vav Labs](https://vav-labs.com/blog/3d-pathfinding-in-godot/)
- [Using flocking to avoid non-circular obstacles in an RTS setting — GameDev.net](https://gamedev.net/forums/topic/646981-using-flocking-to-avoid-non-circular-obstacles-in-an-rts-setting/5089397/)
- [Group Pathfinding & Movement in RTS Style Games — Game Developer](https://www.gamedeveloper.com/programming/group-pathfinding-movement-in-rts-style-games)
- [target selection strategies — GameDev.net](https://www.gamedev.net/forums/topic/682498-target-selection-strategies/)
- [Give AI sticky multi-player target selection — GitHub issue](https://github.com/AustinOrphan/tanks/issues/359)
- [Understanding Batching in Godot 4 — Godot Forum](https://forum.godotengine.org/t/understanding-batching-in-godot-4/65635)
- [Godot 4 CharacterBody3D vs MultiMesh: Scaling Hundreds of Units Without Killing Performance](https://www.slashskill.com/godot-4-characterbody3d-vs-multimesh-scaling-hundreds-of-units-without-killing-performance/)
- [MultiMesh — Godot Docs 4.3](https://rokojori.com/en/labs/godot/docs/4.3/multimesh-class)
- [Versioned Indie Save System: Migrations, Tests, Atomic Writes](https://arcadeonstudios.co.uk/blog/a-practical-save-system-for-indie-games-versioned-portable-testable)
- [How to Test Game Saves for Corruption and Version Incompatibility — Bugnet Blog](https://bugnet.io/blog/how-to-test-game-saves-for-corruption)
- [Calculating Bonuses — Warframe Wiki (additive vs. multiplicative stacking, Fallout 4 perk-order example)](https://warframe.fandom.com/wiki/Calculating_Bonuses)
- [How to (Comfortably) Deal with Modifiable Stats in RPGs — RefresherTowel Games](https://refreshertowelgames.wordpress.com/2024/02/17/how-to-comfortably-deal-with-modifiable-stats/)
- [Tips: Avoid false positives with anti-viruses and Godot Engine 4 exports — itch.io](https://itch.io/t/3990804/tips-avoid-false-positives-with-anti-viruses-and-godot-engine-4-exports)
- [Fix: Godot Export Windows Defender Flags Binary as Virus — Bugnet Blog](https://bugnet.io/blog/fix-godot-export-windows-defender-flags-binary-virus)
- [Windows Defender warning on 4.5 STABLE release — godotengine/godot GitHub Issue #110612](https://github.com/godotengine/godot/issues/110612)
- [Problem with the game being a false positive for Defender — itch.io](https://itch.io/blog/731874/problem-with-the-game-being-a-false-positive-for-defender)
- [A Practical Guide to Protecting Your Indie Game — Corsearch](https://corsearch.com/content-library/blog/a-practical-guide-to-protecting-your-indie-game/)
- [Analysis: Clone Games & Fan Games — Legal Issues — Game Developer](https://www.gamedeveloper.com/game-platforms/analysis-clone-games-fan-games----legal-issues)
- [Kenney vs Quaternius: Best Free CC0 Game Assets (2026)](https://3dxdev.com/kenney-vs-quaternius-the-best-free-cc0-game-assets/)
- [GUT / gdUnit4 headless testing for Godot 4 — CI-tested GUT (Medium)](https://medium.com/@kpicaza/ci-tested-gut-for-godot-4-fast-green-and-reliable-c56f16cde73d)
- [gdUnit4 — GitHub](https://github.com/godot-gdunit-labs/gdUnit4)
- [PlayGodot — headless test automation with screenshot/visual regression](https://github.com/Randroids-Dojo/PlayGodot)
- [Agentic test processes, LLM benchmarks, and other notes on agentic coding (Dan Luu)](https://danluu.com/ai-coding/)
- [AI Agents in Game Development: Real Production Lessons — Luden.io](https://blog.luden.io/ai-agents-in-game-development-real-production-lessons-failed-experiments-and-workshop-101-7d71e64685fa)
- [Scope Creep in Indie Games: How to Avoid Development Hell — Wayline](https://www.wayline.io/blog/scope-creep-indie-games-avoiding-development-hell)

---
*Pitfalls research for: Thronefall-like minimalist low-poly 3D strategy/tower-defense/city-builder/action game (Duskhold), AI-agent-driven development, Windows/itch.io*
*Researched: 2026-09-28*
