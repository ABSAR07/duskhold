# Feature Research

**Domain:** Minimalist low-poly 3D day/night strategy — tower defense + light city-builder + action, Thronefall recreation
**Researched:** 2026-09-28
**Confidence:** MEDIUM-HIGH (numeric stats mostly from the community-maintained Thronefall wiki and Steam guides, cross-checked against Wikipedia, Steam store page, dev interview, and multiple reviews; a few exact figures — precise hotkeys, Falchion weapon, deep mid/late-map content — are LOW confidence single-source or incomplete)

> **⚠ Controls decision update (2026-09-28, made after this research was written):** The project no longer deviates from Thronefall's controls. The mouse is used **for menus only**. Building and upgrading follow Thronefall: the king rides to a fixed build spot and the player **holds the action key** (click-to-build was dropped). Units are commanded with **hotkeys** (hold position; follow the king — all units or one unit type), not mouse selection. Gameplay input is **keyboard + gamepad**. Statements below that described a keyboard+mouse ("KB+M") deviation have been updated inline; see PROJECT.md → Key Decisions and REQUIREMENTS.md (BLDG-02/03/04, UNIT-05/06, INPT-01..03).

## Sources

- Steam store page: https://store.steampowered.com/app/2239150/Thronefall/
- Wikipedia: https://en.wikipedia.org/wiki/Thronefall
- Community wiki (data-rich, fan-maintained, actively updated): https://throne-fall.github.io/ — pages fetched: about/king, about/overview, about/leveling, about/score, game-content/{buildings,units,enemies,weapons,mutators,maps}/index and individual pages for House, Castle Center, Tower, Wall, Barracks, Archery Range, Hero's Quarter, Gold Mine, Fishing Harbour, Shrine, Blacksmith, Field, Mill, Bow & Dagger, Spear, Sword, Lightning Staff, Shadow Codex
- Steam Community guides: "How to git gud at thronefall" (3109796946), "ALL DESCRIPTIONS" (3042795640), building/economy guides
- Steam Community discussions: night-start hotkey, unit-hold-position commands, repair/rebuild rules, king respawn behavior
- Dev interview / design philosophy: Game Developer, "Mastering minimalism and layering complexity with strategy game Thronefall" (Jonas Tyroller & Paul Schnepf, Grizzly Games)
- Reviews: TheGamer "8 Things We Wish We Knew Before Playing Thronefall", TheSixthAxis, GameLuster, BigBossBattle, various run-length/difficulty commentary
- Comparable games (brief scan): Kingdom Two Crowns (Wikipedia, Pocket Tactics review), Bad North, Kingdom Rush, Rogue Tower — general genre framing only, not deep mechanical research

---

## Concrete Thronefall Mechanics (Reference Documentation)

This section documents what Thronefall *actually does*, mechanically, before categorizing what to build. REQ-ID category tags shown in brackets.

### Day/Night Loop [LOOP]

- **Structure:** alternating Day (build) and Night (defend) phases, repeated for a fixed number of nights per map (varies by map — e.g. Nordfels has 6 waves/nights; later maps run longer). No mid-map save; a "run" is one full attempt at a map's full night count. HIGH confidence (Wikipedia, wiki, guides agree).
- **Night start is player-triggered, not timer-based:** there is a dedicated key/button the player presses when ready; the day phase has no countdown. Steam discussions confirm players can "accidentally start the night" by mis-pressing the key, and a "change hotkey to start the night" request exists — confirming it is a discrete bound action, not automatic. MEDIUM confidence (community discussion, not an official manual, but consistent).
- **Night end condition:** night ends only when **all spawned enemies for that night are dead** — not a fixed timer. HIGH confidence (wiki + guide, multiple corroborating sources). A faster kill within ~5s of the final spawn earns a "Time Bonus" component of score (see Meta/Scoring); enemies surviving beyond ~90s total reduce that bonus.
- **Spawn telegraphing:** during the day, small red icons appear at each map-defined spawn point showing **how many enemies** (and by extension roughly what type/wave) will arrive there that night. This is a hard readability requirement — the player commits build/defense decisions based on legible, per-spawn-point enemy counts, not surprise. HIGH confidence (guide + review corroboration).
- **Mono-spawn vs multi-spawn:** most nights on a map spawn from a subset of that map's spawn points; final/climax nights typically spawn from *all* directions simultaneously (except on maps explicitly designed as "mono-spawn" the whole way through). MEDIUM confidence.
- **Dawn payout rule:** at dawn, **destroyed buildings are automatically and freely rebuilt** — no gold cost, no manual action — but **any economic building that was destroyed does not produce income the very morning it rebuilds** (effectively a 1-day income penalty per loss, on top of the interruption to compounding growth). A red "X" icon over a building during the day signals "this building was destroyed and is not paying out." HIGH confidence (Steam discussion + wiki cross-checked, consistent story across sources).
- **Win/loss condition:** losing = the Castle Center (the player's single core building) is destroyed → immediate run failure. Winning a map = surviving that map's final night. HIGH confidence.
- **Retry:** the player can retry an individual night/day after failing or mid-run; doing so removes a scoring bonus (see Meta) rather than blocking retry outright — i.e., retry is always allowed, but it costs score/XP, not a hard permadeath. HIGH confidence (score page + reviews).

### The King [KING]

- **Movement:** mounted (rides a horse), WASD-equivalent movement with a run/sprint modifier (documented walk speed 14 vs sprint 23 in wiki units — relative ratio ~1.64x, exact numbers engine-specific and not directly portable). HIGH confidence for the *existence* of walk/sprint, MEDIUM for exact numbers.
- **Health:** finite HP pool (wiki cites 50 base) with passive regeneration after a short delay following the last hit (wiki: ~10%/sec regen, ~1s delay). MEDIUM confidence on exact numbers (community datamined values), HIGH on the existence of delayed regen.
- **Attack triggering:** the king has **exactly one equipped weapon at a time**, chosen before the run starts (from unlocked weapons). The weapon defines a **passive auto-attack** (fires automatically at nearby enemies while in combat range, no manual aiming input in the original controller-first scheme) plus **one active ability on a cooldown**, manually triggered by the player. This is the single most important KING mechanic to preserve. HIGH confidence (wiki weapon pages, Steam store, TheGamer review all agree on passive+active structure).
- **Weapons (5 documented in the community wiki, base + early-access content; a 6th "Falchion" exists but is under-documented, likely later/DLC-tier content):**
  | Weapon | Unlock | Passive | Active Ability |
  |---|---|---|---|
  | Bow & Dagger | starting weapon | ranged, medium damage, long range (~30 units), ~1/sec | melee dagger stab, high damage, cooldown *shrinks* the lower the target's HP (targets weak/fleeing enemies), ~0.75–6s cooldown |
  | Spear | ~level 4 | melee, low damage but fast (~3/sec), bonus damage + slow vs fast enemies | brief frenzy: much faster attacks + king self-heals per second; duration doubles if king is low HP; ~13s cooldown |
  | Sword | ~level 13 | melee, moderate single-target, bonus vs bosses | AoE circular slam around the king, ~9s cooldown |
  | Lightning Staff | later unlock | ranged, low per-hit but **hits multiple enemies**, bonus vs flying/boss | delayed AoE lightning strike (~3s fuse) at a large radius, bonus vs flying/boss, ~9s cooldown |
  | Shadow Codex | later unlock | ranged, applies a stacking "curse" debuff to multiple enemies, bonus vs boss | detonates all active curses for burst AoE damage, ~10s cooldown |

  Each weapon is a distinct **playstyle**, not a stat upgrade — some favor crowd control, some single-target burst, some sustain. This variety is a core replayability driver. HIGH confidence for structure, MEDIUM for exact numbers.
- **Death/respawn:** when the king's HP hits zero, the king does **not end the run** — the king enters a temporary "ghost"/downed state and **respawns after a timer** at (or near) the castle, matching the PROJECT.md requirement. Ranged and flying enemies specifically prioritize targeting the king, making king death a real tactical risk during heavy nights, but never an instant loss (only the Castle Center falling is a loss). MEDIUM confidence (Steam discussion corroborated, exact respawn timer/location not found in sources — flag as an open question for design, default to "short timer, respawns at castle").
- **King as sole builder:** only the king can construct/upgrade buildings (by proximity/interaction — "ride up and hold" — which this project keeps exactly; *updated: the earlier plan to build by mouse click on a build spot was dropped*). HIGH confidence (wiki: "the only character... with the ability to construct buildings").

### Economy [ECON]

- **Single currency:** gold. No secondary resources (no wood/stone/food as separate currencies) — this simplicity is core to the "minimalism" design philosophy documented in the dev interview. HIGH confidence.
- **Income sources (all pay out at dawn, only if the building survived the night):**
  | Building | Cost (T1→T2→T3) | Income pattern |
  |---|---|---|
  | House | 2 → 2 gold | flat 1 gold/night (T1) → 2 gold/night (T2); simplest, most reliable income |
  | Gold Mine | 5 gold, no further tiers found | **declining** yield: 6 gold first night, −1 per subsequent night (diminishing resource, encourages *early* investment) |
  | Mill (unlocks Fields) | 3 → 4 → 6 gold | Mill itself pays 1 → 2 → 6 gold/night; **also unlocks build slots for Field buildings nearby** |
  | Field | 1 gold, built only once a Mill exists nearby | flat 1 gold/night per field; cheap, stacks under a Mill |
  | Fishing Harbour | 3 → 7 gold | does **not** pay flat gold — accumulates "boats" (1 new boat/night, cap 5 base/10 upgraded), each boat worth 1 gold/night (2 after upgrade); i.e. income *ramps up* over several nights, a deliberately different economic curve from Houses (instant) or Mines (declining) |
  | Shrine | 3 gold | not a pure economy building — a **defense/economy hybrid**: dormant until 350 cumulative HP of nearby enemy kills "activates" it, after which it both auto-attacks enemies AND pays 2 gold/night; multiple activated shrines buff each other's attack (+20% per additional shrine) |

  The variety of income *curves* (flat/instant, declining, ramping, threshold-activated) is a deliberate economic-puzzle layer, not just "buy more houses." MEDIUM-HIGH confidence (numbers from community wiki, curve *shapes* corroborated by multiple guide sources).
- **Upgrade cost pattern:** costs increase per tier (commonly ~roughly-doubling or a bit more per tier, e.g. Barracks 4→8→16, Hero's Quarter 5→9→18, Tower 3→5→15, Castle Center 3→7→20), and the Castle Center's own upgrade level often gates which higher building tiers are even purchasable. HIGH confidence on "cost escalates per tier," MEDIUM on universality of ~2x pattern.
- **No interest/tax/loan mechanic in the base economy** — but a "Loan" **perk** exists (meta-progression unlock, not base mechanic) implying an opt-in interest-like mechanic is a *perk*, not core economy. This matters: interest/compounding-gold mechanics belong in the perk system, not the baseline econ loop.
- **Enemies do not directly drop gold on death** in the documented sources — gold comes from surviving buildings at dawn, not per-kill bounties. This is an important distinction from many tower-defense games (see Anti-Features).

### Buildings [BLDG]

Full category breakdown, with **build-spot system**: every building can only be placed on a **fixed, pre-designed spot** baked into the map — there is no free placement. This is a deliberate, load-bearing design decision (see Architecture note below).

**Economy:** House, Field (requires adjacent/associated Mill), Mill, Gold Mine, Fishing Harbour, Shrine (hybrid).

**Defense:** Wall (linear 2-tier HP upgrade only, no branching — 240→640 HP, cost ~3-5→5-7 or a flat 15/20 buy-up-front option per some sources), Barricade (cheap temporary chokepoint variant of wall), Tower (3-tier: T1 base → T2 choose 1-of-4 specialization [Castle/Sniper/Armoured/Bunker Tower] → T3 choose 1-of-4 further specialization [Archer's/Ballistic/Fire/Healing Spire]), Shrine.

**Military:** Barracks (produces melee squads; on construction choose 1-of-4 unit type: Knights/Spearmen/Flails/Berserks; upgrades scale squad size 4→8→12 and reduce spawn interval 10s→6s→6s), Archery Range (ranged squads; choose 1-of-4: Longbow Archers/Crossbowmen/Hunters/Fire Archers), Hero's Quarter (single powerful hero unit; choose 1-of-4: Golem/Support Mage/Firewing/Lizzard Rider; upgrades scale hero HP and a damage multiplier 1x→2x→4x).

**Castle/Research:** Castle Center (the loss-condition building; 3 tiers, 100→300→700 HP; **each upgrade is a choose-1-of-4 ability/passive pick** — e.g. Royal Training [+HP/damage], Builder's Guild [auto-upgrades houses], Magic Armor [reflect damage], Assassin's Training [slower but much stronger king attacks], Commander [unit buffs], Castle-Up [cheaper nightly wall/tower costs] — this is the single most important build-order decision each run). Blacksmith and Royal Forge (multi-day timed research buildings; each tier grants more simultaneous research slots (1→2→3) and a choice of buffs like +20% melee/ranged damage or +30% melee/ranged resistance, applied globally to king+units+buildings, taking 2-3 in-game days to complete — meaning research must be started early enough to matter before the map ends).

**Branching-choice pattern is the throughline:** almost every building beyond tier 1 asks the player to pick 1-of-N permanent specializations rather than a single linear power increase. This creates build diversity per run and is core to replay variety. HIGH confidence (consistent across Tower, Castle Center, Barracks, Archery Range, Hero's Quarter, Blacksmith).

### Units [UNIT]

- **Production:** military buildings (Barracks/Archery Range/Hero's Quarter) spawn units automatically over time once built, up to a squad cap that increases with the building's upgrade tier (regular units: cap scales in +4 increments per tier; hero units: stay as a single unit that gets stronger instead of more numerous).
- **Respawn:** killed units slowly regenerate at their source building **during the night** (a trickle, not instant) and are **fully restored instantly at dawn**. This means losing units in a fight is a real but recoverable cost, and morning is a full reset.
- **Commands:** units default to autonomous combat AI near their spawn/position, but the player can command them to **hold position** or **follow/move**, via a dedicated hold-position hotkey and per-unit-type selection hotkeys in the original controller-first scheme (documented: hold key ~"R"/Square/Y toggles hold at current position until re-commanded, killed, or battle ends; a "select one unit type" hotkey ~"F"/Circle/B exists; players have long requested more granular hotkeys, e.g. direct "select all of unit type 1/2/3/4," suggesting the original command UX is a known friction point). MEDIUM confidence on exact keys (community-sourced; *updated: this project now uses the same hotkey-driven command scheme on keyboard + gamepad, with rebindable keys — no mouse unit commands — so the exact defaults are a design choice to make, informed by the "more granular hotkeys" requests above*), HIGH confidence on the *behavior*: default autonomous + explicit hold + explicit rally/move.
- **Specialization/counters:** unit types counter specific enemy categories (e.g. Hunters strong vs "monster" enemies but weak to ranged; Fire Archers bonus vs siege; Crossbowmen armored vs ranged damage; Support Mage heals + blocks magic projectiles in an AoE). Hero units are stronger, individually meaningful, slower to replace (documented ~60s hero revive timer vs the fast trickle-respawn of regular squads).

### Enemies [ENEMY]

Roster is broad and role-differentiated, confirmed via the wiki's enemy index (26 enemy pages) and cross-referenced with reviews:

- **Basic ground:** Peasant (very weak filler), Swordsman (standard melee), Archer (standard ranged).
- **Tanks:** Ogre (basic high-HP melee tank), Spiky Slime (bigger/tougher slime variant).
- **Fast/skirmish:** Racer, Slime (small/fast melee).
- **Siege (target buildings, not the king):** Barrel Knight (wooden melee siege unit), Ram (heavy battering unit), Catapult (ranged siege, arcs damage onto structures), Quicksling (advanced high-damage siege).
- **Anti-player specialists:** Hunterling, Monster Rider — explicitly target the king rather than buildings, punishing a king who over-commits to melee brawling without support.
- **Suicide/area-denial:** Exploder — dies on contact with a building and detonates, area damage.
- **Flying:** Wasp (basic flier), Flying Mage (ranged AoE flier) — flying enemies are the counter to ground-only defenses (towers/melee units that can't hit air), forcing anti-air investment (see Anti-Air Telescope perk, Fire Archers/Golem/Lizzard Rider splash or anti-air value).
- **Armored/elite variants:** Elite Crossbow Man, Pikes (anti-cavalry — slows and bonus-damages the mounted king specifically), Mole Archer/Mole Knight (map-specific burrowing variants).
- **Bosses (map-specific, later/climax nights):** Fury (large flying boss focused on destroying defenses), Shadow In The Water (Frostsee map boss), Strange Statue (Sturmklamm map boss — 4 simultaneous statues on the final night). Bosses are tied to specific maps' final nights, not a generic "every map has a boss" rule — early/tutorial maps have no boss.
- **Wave composition pattern:** waves escalate within a map (more enemies, more types, more simultaneous spawn points), telegraphed per spawn point (see LOOP). Later maps introduce their own 2-4 new unique enemy types on top of the shared roster, keeping each map mechanically fresh without discarding earlier learning.

### Meta-Progression [META]

- **Player/account-level XP and leveling** (separate from any per-run score, though score feeds it): formula documented as `[base score + gold×10] × 1.2^(mutator count)`-style scaling (exact formula MEDIUM confidence — sourced from wiki leveling page, roughly matches the score-page formula below). Leveling is the **unlock gate** for weapons, perk slots, and hero units — e.g. (illustrative unlock cadence found in sources): level 1 = starting weapon already owned; level 4 = 2nd weapon; level 8 = 2nd perk slot; level 13/15 = 3rd weapon; level 24 = 3rd perk slot; level 28 = 4th weapon; further levels unlock additional hero units. Level cap in the full game is very high (~59), with trophy-only rewards after all content unlocks — **not directly portable to a 3–5 map v1**, but the *pattern* (early levels front-load core unlocks fast, then long tail of diminishing unlocks) is exactly right to imitate at a compressed scale.
- **Perks:** a large pool (documented ~34-70+ across sources depending on version/date) of permanent, unlockable modifiers the player **selects up to 5 of before starting a run** (a loadout, not always-on) — spanning economy (Royal Mint, Sustainable Mining, Treasure Hunter, Loan), military (Melee/Ranged Damage, Warrior Training, Elite Warriors), defense (Heavy Armor, Castle Fortifications, Fortified Houses), magic/towers (Arcane Towers, Elite Towers, Anti-Air Telescope), and special/utility (Ring of Resurrection, Commander Mode, Healing Spirits, Glass Cannon [likely a risk/reward trade-off perk]). Perks are unlocked once (via leveling) and then reusable across all future runs/maps.
- **Mutators:** opt-in difficulty modifiers chosen before a run, each granting a **score/XP multiplier** if the run is won. Documented examples: Tiger God (+75% enemy damage, ×1.2 score/XP), Turtle God (+75% enemy HP, ×1.4 score/XP — highest single multiplier found), Destruction God (buildings heal only 25%/morning + destroyed buildings take an extra day to repair, ×1.2), plus Death/Elite/Falcon/Growth/Snake/Wasp/Range/Phoenix "God" mutators and structural bans like No Towers/No Units/No Walls Pact. Multiple mutators **stack multiplicatively** (documented max ×4.529 with all 7 "god" mutators active). This is the primary score-chasing/replayability layer for players who've already beaten a map.
- **Scoring formula:** `(Base Score + Gold Score + Mutator Bonus) × No-Restart Bonus`, where Base Score is capped ~600/night from three components — Night Survived (flat, e.g. +100), Realm Protected (up to +250, scaled by % of buildings kept alive), Time Bonus (up to +250, front-loaded for fast final-wave clears, decaying if stragglers survive past ~90s); Gold Score = unspent gold × 10 at run end; Mutator Bonus = multiplicative stack of active mutators' bonus %; No-Restart Bonus = +10% if the player never used the retry function during that run, +0% (×1.0) if they did. **Retry penalty is soft** (lose a 10% multiplier + implicitly lower "no mistakes" bragging rights) not a hard gate or content loss — retrying is always allowed.
- **Maps differ structurally, not just cosmetically:** each map after the tutorial (Neuland) adds its own terrain gimmicks (mountains, rivers, deserts with vantage ramps, snow/lakes, coastal grassland, mountain corridors with rain, multi-node bridge networks), its own 1-4 unique buildings and 2-4 unique enemies not found elsewhere, different starting gold, different spawn-point counts/layout (mono- vs multi-directional), and — on the harder maps — a unique boss night. Difficulty and mechanical novelty both increase map-over-map. This "each map teaches/adds something new, on top of a stable shared core" structure is exactly the model a 3-5 map v1 should imitate at a smaller scale.

### UI/UX [UI]

- **Minimal, always-visible HUD**: gold count, day/night phase indicator, per-spawn-point enemy-count icons (day only), build/upgrade cost tooltips on hover/select, branching-choice cards presented as clear icon+text options at upgrade time, unit-group selection indicators.
- **Readability via silhouette + limited palette**: the developers explicitly designed buildings/units/enemies to be identifiable by outline/shape and a constrained color language rather than fine detail, "so players can tell what's happening at a glance" even with dozens of units/projectiles on screen. This is a HIGH-value, LOW-complexity-to-adopt principle given this project's own low-poly CC0-asset constraint.
- **Build/upgrade prompts**: "ride up and hold" (proximity + hold-button) — this project keeps this exactly: a prompt with the option and cost appears when the king is near a spot, and holding the action key (keyboard or gamepad) fills a progress indicator. *(Updated: the earlier plan to replace this with mouse click-to-build was dropped.)*
- **Menus**: main menu, map/level select, pre-run loadout screen (weapon + perks + mutators chosen before entering a map), pause, settings, post-run results/score screen. HIGH confidence these all exist in some form (store page screenshots, reviews, wiki's leveling/score pages imply a dedicated results screen).
- **Difficulty curve**: reviews are consistent that early nights/maps ramp smoothly and are approachable, but call out at least one severe difficulty spike (a late-game/final boss described by one reviewer as jumping from "reasonably tough" to "untouchable, one-shots everything") — a cautionary note: escalation should be tuned carefully and tested, not just linearly scaled up, especially for a boss/climax night.
- **Run length**: a full first-time campaign clear is commonly cited around 4-5 hours in the full 10-map game; individual maps are "bite-sized," designed to be replayed with different perks/mutators/weapons rather than being long single sits. This validates a 3-5 map v1 as a legitimately complete, right-sized experience rather than "an incomplete slice."
- **Controller-first origin**: the original game is explicitly designed around a single main-action button (hold=build, press=attack) plus movement plus hotkeys, aimed at "time-constrained players" wanting depth without heavy APM. This project follows the same scheme on keyboard and gamepad (move + one action key + hotkeys), with the mouse used only in menus. *(Updated: an earlier keyboard+mouse deviation — click-to-build/upgrade and mouse unit commands — was dropped in favor of Thronefall's original controls.)*

---

## Feature Landscape

### Table Stakes (Users Expect These — "must have or it doesn't feel like Thronefall")

| Feature | Why Expected | Complexity | Notes |
|---|---|---|---|
| [LOOP] Day/night cycle with player-triggered night start | This *is* the game's structural spine; genre fans expect deliberate, no-timer-pressure build phases | MEDIUM | Needs an explicit "start night" UI action per PROJECT.md; night ends only when all enemies are dead, not a clock |
| [LOOP] Dawn auto-rebuild, no-income-on-rebuild-morning | Defines the core day-to-day risk calculus ("losing a building costs a day of income, not the building itself") | LOW-MEDIUM | Simple state machine per building: alive/destroyed-this-night/rebuilt-no-income-today/earning |
| [LOOP] Per-spawn-point enemy-count telegraphing | Removes "unfair surprise," lets players make informed build/defense trade-offs — central to the game's promise of being readable strategy, not reflex panic | MEDIUM | Needs per-spawn UI icon + data-driven wave definitions visible ahead of time |
| [LOOP] Castle-falls-loses / survive-final-night-wins | Clear, legible win/loss condition | LOW | Single HP pool + game-state check |
| [KING] Mounted king who fights directly (passive auto-attack + 1 active ability per weapon) | The king-as-combatant hybrid (city-builder + action) is Thronefall's signature; a passive-only or non-combatant king breaks the core value prop | MEDIUM-HIGH | Passive auto-attack needs target-acquisition/range logic; active ability needs cooldown UI + input binding |
| [KING] King can be downed and respawns after a delay, not a hard game-over | Matches PROJECT.md explicitly; keeps night-time tension without punishing king aggression too harshly | LOW-MEDIUM | Timer + ghost/invulnerable state + respawn-at-castle logic |
| [ECON] Single currency (gold) | Core minimalism; multiple resources would fight the design philosophy and add UI/complexity for no value | LOW | — |
| [ECON] Fixed, pre-placed build spots (no free placement) | Documented as THE key design lever that let Thronefall's devs layer content without breaking earlier levels; also directly requested in PROJECT.md | MEDIUM | Requires hand-authoring spot positions per map — feeds level design, not just code |
| [ECON] Income only pays out for buildings that survived the night, at dawn | Defines the tension of the build phase — every building is a target with a cost of loss | LOW | Tied to dawn-payout loop above |
| [ECON] Escalating per-tier upgrade costs | Standard, expected economic pacing; keeps late-game upgrades meaningful gold sinks | LOW | Data-driven per building definition |
| [BLDG] Building categories: economy / defense / military / castle | Structures the whole build-phase decision space; players expect these four "buckets" | MEDIUM | Directly named in PROJECT.md |
| [BLDG] Branching upgrade choices (choose 1-of-N at a tier) | The signature "build variety without complexity" mechanic — every Thronefall guide/review calls this out as central | MEDIUM-HIGH | Needs upgrade-choice UI (cards), and per-building-type branching data; this is a core system, not a building instance |
| [BLDG] Castle Center upgrades with its own ability choices | Explicitly named in PROJECT.md; the single most build-defining decision per run | MEDIUM | Ties castle HP scaling + a global ability/passive unlock together |
| [BLDG] Walls/barricades (defense chokepoints) | Baseline tower-defense expectation; also explicitly in PROJECT.md | LOW | Linear HP upgrade only — simplest building type, good first implementation target |
| [BLDG] Towers (multiple types/specializations) | Baseline TD expectation, and Thronefall's branching-tower pattern (T2 4 options, T3 4 options) is a strong differentiator worth preserving even at v1 | MEDIUM-HIGH | Can start with fewer than 8 total specializations for v1 and still hit "branching towers exist" |
| [UNIT] Military buildings produce squads (melee + ranged at minimum) | Explicitly in PROJECT.md; baseline for any TD/city-builder hybrid | MEDIUM-HIGH | Squad spawn/cap/trickle-respawn-then-dawn-reset logic |
| [UNIT] Units default to autonomous combat, can be told to hold or move/rally | Removes micromanagement burden while still giving tactical control — a genre expectation reinforced by Thronefall specifically | MEDIUM-HIGH | Needs a simple command layer: default AI state + override states |
| [ENEMY] Enemy roster with clear roles that counter single-strategy defenses (melee, ranged, flying, siege, at minimum) | Prevents "one tower type solves everything"; central to why the branching-building system matters at all | MEDIUM-HIGH | v1 needs enough enemy variety (flying + siege + melee + ranged minimum) to justify the building variety being built |
| [ENEMY] Hand-authored, escalating waves per night per map | Explicitly in PROJECT.md (anti-feature: no procedural maps/waves) | MEDIUM | Data-driven wave definitions per map per night |
| [META] Per-map scoring, high scores, soft retry penalty | Explicitly in PROJECT.md; gives replay value even on a small campaign | MEDIUM | Score formula composition (survival + building preservation + gold remaining + no-restart bonus) is well documented and portable |
| [META] Small number of unlockable king weapons, each with passive+active | Explicitly in PROJECT.md; this is where "weapon variety" as a meta-progression axis comes from | MEDIUM-HIGH | v1 can ship with fewer than Thronefall's 5-6 weapons (e.g. 3) and still deliver the "distinct playstyle per weapon" promise |
| [META] Perks, limited loadout selected pre-run | Explicitly in PROJECT.md | MEDIUM | v1 needs enough perks (a dozen-ish) across econ/military/defense/king categories to make loadout choice meaningful, at fewer than Thronefall's 50+ |
| [META] Mutators with score/XP multipliers | Explicitly in PROJECT.md | LOW-MEDIUM | Simpler than perks to implement — mostly numeric modifiers + a multiplier applied at score time |
| [UI] Minimal always-visible HUD (gold, phase, costs, spawn counts, unit selection) | Baseline usability; also central to Thronefall's minimalist-but-readable identity | MEDIUM | — |
| [UI] Silhouette/color-based readability for buildings/units/enemies | Directly enables the low-poly CC0 art pipeline to still read clearly at a glance in combat | MEDIUM | Art-direction constraint as much as a UI one — affects CC0 asset selection/coloring, not just HUD |
| [UI] Pre-run loadout screen (weapon + perks + mutators) | Explicitly implied by PROJECT.md's meta-progression requirements | MEDIUM | Needs its own menu flow distinct from in-run HUD |
| [UI] Results/score screen after each run | Needed to close the scoring/meta loop | LOW-MEDIUM | — |

### Differentiators (What Elevates It — flagged v1 vs later)

These aren't "missing = broken," but they're what separates a *good* Thronefall-like from a generic, forgettable tower-defense clone. Grouped by whether the compressed 3-5 map v1 scope should include them now.

| Feature | Value Proposition | Complexity | v1 or Later? |
|---|---|---|---|
| Building-specific economic income *curves* (flat/House, declining/Mine, ramping/Harbor, threshold-activated/Shrine) rather than one uniform "gold per building" | Turns economy into a genuine puzzle (when to invest, not just how much) instead of a flat number-go-up; this is one of Thronefall's most-praised subtleties in guides | MEDIUM | **v1** — cheap to add once the base income system exists, and it's core to why Thronefall's economy feels good rather than rote |
| Mill-gates-Fields dependency (must build the unlocking structure before its sub-buildings become available) | Adds a light tech-tree feel to a single map without needing a full research tree | LOW-MEDIUM | **v1** — small addition, reinforces build-spot design language |
| Boss/elite nights on select maps (not every map) | Gives the small campaign a clear "this map is the hard/special one" beat, and a memorable capstone | MEDIUM-HIGH | **v1**, but only on 1 of the 3-5 maps — a single well-tuned boss night is worth more than several mediocre ones; watch the documented "difficulty cliff" pitfall (see PITFALLS research) |
| Per-map unique enemy(ies) and unique building(s), layered on a shared core roster | Keeps each of the (few) maps feeling distinct despite a small map count — directly compensates for "only 3-5 maps" by making each one memorably different rather than a reskin | MEDIUM | **v1** — actually *more* important at small map counts, since each map needs to justify its own existence |
| Research buildings (Blacksmith/Royal Forge) with multi-day timed global buffs | Adds a "plan ahead, don't just react" layer distinct from instant-build economy/defense; rewards players who think several nights ahead | MEDIUM | **Later (v1.x)** — genuinely optional; a 3-5 map, single-digit-night-per-map campaign may not have enough runway for multi-day research payoff to matter, and it's the most cut-able building category without breaking the core loop |
| Large weapon roster (5-6+) with deep specialization (crowd-control vs burst vs sustain vs curse-stacking) | Long-tail replay variety | MEDIUM-HIGH | **Partial v1** — ship 2-3 mechanically distinct weapons (e.g. one ranged/single-target, one melee/AoE, one CC/curse-style) covering the *range* of playstyles; defer filling out the full roster |
| Deep perk pool (50+) | Long-tail replay variety, "I unlocked something new" dopamine over many hours | HIGH | **Later** — v1 needs enough perks to make a 5-slot loadout meaningful (dozen-plus, spanning categories), not Thronefall's full late-game breadth |
| High mutator count with multiplicative stacking up to ~4.5x score | Long-tail score-chasing for players who've mastered a map | LOW-MEDIUM | **Partial v1** — a handful of mutators (4-6) with a simple multiplicative stack captures the mechanic; more can be added post-v1 cheaply since each is largely a numeric modifier |
| Long unlock tail (level cap ~59, trophies-only late levels) | Retention hook for a live/ongoing commercial game | HIGH | **Not v1** — explicitly wrong shape for a small, complete portfolio campaign; v1's level curve should be short and front-loaded (most/all content unlocked within the 3-5 map campaign itself), not a treadmill |
| Dev-philosophy "small execution polish" (juicy build-placement animation/feedback, "feel like you can exercise great power with a simple button press") | This is explicitly named by the devs as *the* differentiator for a 2-person team without content budget — cheap animation/juice punches above its weight | LOW-MEDIUM | **v1** — extremely high value-per-effort; directly achievable regardless of map count, and arguably more important than an extra map or weapon would be |
| ~~Mouse-driven build/command UX~~ — **DROPPED (controls decision 2026-09-28): the project uses Thronefall's ride-up-and-hold building and hotkey unit commands on keyboard + gamepad; mouse is for menus only. Row kept for history.** | Not from Thronefall itself, but a legitimate differentiator for this recreation: mouse click-to-build/upgrade and mouse-driven unit-group commands can be *more* precise and discoverable than Thronefall's proximity+hold+hotkey scheme, especially for players without controller-first instincts | MEDIUM | ~~**v1**~~ **Dropped** — the owner chose to copy Thronefall's control feel (ride-up-and-hold building, hotkey unit commands, keyboard + gamepad); build prompts and unit commands follow the original design |

### Anti-Features (Commonly Tempting, Deliberately Avoid for v1)

| Feature | Why Tempting | Why Problematic Here | Alternative |
|---|---|---|---|
| Free/flexible building placement | Feels more "creative," common in city-builders | Directly contradicts Thronefall's core, dev-validated insight that *fixed* spots are what let hand-authored level design and tech-tree curation work; also explicitly in PROJECT.md as intentional | Fixed, hand-placed build spots per map, authored alongside wave design |
| Multiple resource currencies (wood/stone/food) | "More strategic depth," common in RTS/city-builders | Fights the single-currency minimalism that makes Thronefall's economy legible at a glance; adds UI and balancing surface for little payoff at v1 scale | Single gold currency; use branching upgrade choices for depth instead of more currencies |
| Per-kill gold bounties | Common TD trope, feels rewarding in the moment | Not how Thronefall's economy works (income is building-survival-based, at dawn); would shift the core tension from "protect your economy" to "grind kills," changing the game's identity | Keep gold tied to building survival at dawn only |
| Full permadeath / no-retry roguelike structure (Kingdom Two Crowns-style) | Raises stakes, common in the broader genre-adjacent space | Thronefall's actual model is retry-always-allowed-with-a-soft-score-penalty — permadeath would be a harder, different game and risks frustrating a portfolio demo audience | Soft retry penalty via the no-restart score/XP multiplier only |
| Mouse-aimed king attacks (twin-stick-shooter style) | Feels more "actiony," natural mouse affordance | Explicitly out of scope in PROJECT.md; changes the king from "auto-attack + timed ability" (strategy-layer combat) to "aim skill" (action-layer combat), a genuinely different core value proposition | Passive auto-attack (nearest/priority target) + manually-triggered active ability, matching Thronefall; mouse reserved for menus only (updated from "building/commands/UI") |
| Full 50+ perk pool / 9+ weapon roster / 10-map parity at v1 | "More content = more faithful" | Explicitly out of scope in PROJECT.md; the full-game numbers exist because Thronefall is a shipped commercial product with a year+ of live content — copying the volume without the runway just under-polishes everything | Curated subset (a few weapons covering distinct playstyles, a dozen-plus perks, a handful of mutators) that demonstrates full system *depth* on a *small* footprint |
| Procedural/random map or wave generation | Reduces authoring burden, adds "infinite replayability" | Explicitly out of scope in PROJECT.md; Thronefall's spawn-telegraphing and hand-tuned difficulty curve depend on hand-authored waves — procedural generation would also fight the fixed-build-spot design | Hand-author 3-5 maps' worth of build spots and per-night wave compositions |
| Steam integration (achievements/cloud saves/leaderboards) | "Feels more complete/professional" | Explicitly out of scope; not a commercial release, adds third-party dependency and scope for zero player-facing value in a single downloadable build | Local save file for progress/unlocks/high scores |
| Music/soundtrack in v1 | Adds atmosphere, expected in most games | Explicitly deferred in PROJECT.md; SFX carries core feedback (hits, building, coins, UI, night-start/dawn) and is a much smaller asset/mixing surface for a first milestone | Strong SFX-only pass; add music in a later milestone |
| Multiplayer/co-op | Kingdom Two Crowns and some genre-adjacent games support it, "more replayability" | Explicitly out of scope; Thronefall itself is single-player, and co-op multiplies netcode/sync/UI complexity for a portfolio project with zero requirement for it | Single-player only |
| Research buildings with deep multi-tier timed trees | "More systems = more depth" | Given the small per-map night count in a 3-5 map v1, multi-day research timers may not have enough in-run runway to pay off, risking a system that's technically present but never meaningfully used | Defer Blacksmith/Royal Forge to v1.x, or ship a heavily simplified single-tier version only if time allows |

## Feature Dependencies

```
[LOOP] Fixed build spots per map
    └──requires──> Map authoring (spot positions, per-night wave data) — feeds level design work, not just engine code

[LOOP] Dawn payout / no-income-on-rebuild-morning
    └──requires──> [LOOP] Auto-rebuild-at-dawn state machine per building
    └──requires──> [ECON] Building income defined per building type/tier

[BLDG] Branching upgrade choices (choose 1-of-N)
    └──requires──> Upgrade-choice UI (cards/selection) — shared system, not per-building
    └──enables──> [BLDG] Castle Center ability choices
    └──enables──> [BLDG] Tower specializations
    └──enables──> [UNIT] Barracks/Archery Range/Hero's Quarter unit-type choice

[UNIT] Squad production & command
    └──requires──> [BLDG] Military buildings built and upgraded
    └──requires──> Default autonomous-AI behavior + hold/rally override command layer

[ENEMY] Wave composition variety (flying/siege/melee/ranged)
    └──requires──> [BLDG] Building variety (towers vs anti-air vs melee-favoring walls) to have something to counter
    └──enables──> [BLDG] Branching building choices actually mattering (a build choice with no enemy to counter is a false choice)

[KING] Weapon passive+active combat
    └──requires──> Target-acquisition/range/damage-type system (shared with towers/units — same underlying combat resolution)
    └──enables──> [META] Weapon unlocks as a meta-progression axis

[META] Per-map XP/leveling
    └──requires──> [META] Scoring formula (score feeds XP)
    └──enables──> [META] Weapon unlocks
    └──enables──> [META] Perk-slot count increases
    └──enables──> [META] Perk pool unlocks

[META] Mutators
    └──requires──> [META] Scoring formula (multiplier applies to score/XP)
    └──conflicts with──> nothing structurally, but tuning mutator multipliers requires the base scoring formula to be stable first

[UI] Spawn-point telegraphing
    └──requires──> [ENEMY] Wave data defined and readable ahead of night start (data must exist before UI can display it)

[UI] Pre-run loadout screen
    └──requires──> [META] Weapons, perks, and mutators all existing as unlockable/selectable data
```

### Dependency Notes

- **Fixed build spots require map authoring, not just a building system:** this is the one dependency most likely to be underestimated — every map needs its build-spot layout and per-night wave data hand-placed before building/wave *code* can be meaningfully tested end-to-end. Plan map content authoring as its own tracked work, not a byproduct of building the systems.
- **Branching upgrade choices are a shared system, not four separate features:** implement the "pick 1 of N at a tier" UI/data pattern once, then apply it to Castle Center, Tower, Barracks, Archery Range, and Hero's Quarter. Building it once and reusing it four times is both more faithful to how Thronefall is structured and far cheaper than building four bespoke upgrade UIs.
- **Enemy variety and building variety are mutually dependent, not sequential:** a branching tower choice (e.g. anti-air specialization) is meaningless without flying enemies to justify it, and flying enemies are frustrating without an anti-air option existing. These two research findings should land in the same phase/milestone of the roadmap, not be split across early vs late phases.
- **Scoring formula must exist before mutators are tuned:** mutators apply a multiplier to score/XP — get the base formula (survival + building preservation + time bonus + gold remaining + no-restart bonus) stable and playtested before layering multiplier balance on top, or multiplier tuning will have to be redone.
- **Research buildings (Blacksmith/Royal Forge) are the cleanest cut point if scope pressure hits:** nothing else in the dependency graph requires them — economy, defense, military, king combat, and meta-progression all function completely without research buildings. This makes them the safest deferral if v1 time runs short.

## MVP Definition

### Launch With (v1) — matches PROJECT.md's Active requirements

- [ ] Day/night loop: player-triggered night, telegraphed spawns, dawn payout with rebuild-no-income rule, castle-loss/final-night-win conditions — the non-negotiable spine
- [ ] King: WASD movement, one equipped weapon (passive auto-attack + active ability), down/respawn-after-delay
- [ ] Economy: single gold currency, fixed build spots, at least 3 distinct economic income curves (flat/House, declining/Mine, threshold or ramping/Harbor-or-Shrine)
- [ ] Buildings: walls, towers (with at least one tier of branching specialization), Castle Center (with branching ability choices at each of its upgrade tiers), Barracks, Archery Range — economy + defense + military + castle categories all represented
- [ ] Units: at least 2 producible unit types (1 melee, 1 ranged) with autonomous AI + hold + rally commands
- [ ] Enemies: roster covering melee, ranged, flying, and siege roles at minimum, so building/unit variety is meaningfully tested
- [ ] 3-5 hand-authored maps, each with at least one distinguishing element (unique enemy, unique building, or a boss night on at least one map)
- [ ] Meta-progression: per-map XP/levels; 2-3 unlockable weapons; a dozen-plus perks with a 5-slot pre-run loadout; 4-6 mutators with multiplicative score/XP bonus; scoring formula with soft retry penalty
- [ ] UI: minimal HUD, spawn telegraphing, branching-choice cards, pre-run loadout screen, results screen, Thronefall-style ride-up-and-hold building and hotkey unit commands on keyboard + gamepad, mouse for menus only (updated: replaces the earlier mouse-driven build/command plan)
- [ ] SFX for core feedback only; no music (explicit v1 deviation, not a cut corner)

### Add After Validation (v1.x)

- [ ] Blacksmith/Royal Forge research buildings with multi-day timed global buffs — add once base loop is validated and there's confidence the per-map night count gives research enough runway to matter
- [ ] Expand weapon roster beyond initial 2-3 (fill out remaining playstyles: pure ranged, pure melee-AoE, curse/DoT-style)
- [ ] Expand perk pool beyond initial dozen-plus toward Thronefall's broader category coverage
- [ ] Additional tower/building specialization branches beyond the minimum one-tier-of-branching shipped at v1
- [ ] Music (explicitly deferred per PROJECT.md)

### Future Consideration (v2+)

- [ ] Full 10-map-scale campaign content (explicitly out of scope for v1 per PROJECT.md)
- [ ] Gamepad support (explicitly deferred per PROJECT.md)
- [ ] Deep, long-tail meta-progression (level cap in the dozens+, trophy-only late unlocks) — wrong shape for a small complete campaign; only relevant if the project ever grows toward a live/ongoing release model

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---|---|---|---|
| Day/night loop core (trigger, telegraphing, dawn payout, win/loss) | HIGH | MEDIUM | P1 |
| King combat (passive+active weapon, down/respawn) | HIGH | MEDIUM-HIGH | P1 |
| Fixed build spots + branching upgrade choice system | HIGH | MEDIUM-HIGH | P1 |
| Economy with varied income curves | HIGH | MEDIUM | P1 |
| Core building set (wall, tower, castle center, barracks, archery range) | HIGH | HIGH | P1 |
| Unit production + command (autonomous/hold/rally) | HIGH | MEDIUM-HIGH | P1 |
| Enemy roster (melee/ranged/flying/siege minimum) | HIGH | MEDIUM-HIGH | P1 |
| 3-5 hand-authored maps with per-map distinctiveness | HIGH | HIGH | P1 |
| Scoring formula + soft retry penalty | MEDIUM-HIGH | LOW-MEDIUM | P1 |
| Weapons (2-3), perks (dozen-plus), mutators (4-6), per-map XP | HIGH | HIGH | P1 (reduced scope from full game) |
| Minimal HUD + spawn telegraphing UI + loadout/results screens | HIGH | MEDIUM | P1 |
| Boss/elite night on at least one map | MEDIUM-HIGH | MEDIUM-HIGH | P1 (single map only) |
| Build-placement "juice"/feedback polish | MEDIUM | LOW | P2 (cheap, high value-per-effort — do early if time allows) |
| Research buildings (Blacksmith/Royal Forge) | MEDIUM | MEDIUM | P2/P3 (safest cut point) |
| Expanded weapon/perk/mutator rosters beyond v1 minimums | MEDIUM | HIGH | P3 |
| Full 10-map content parity | LOW (for this project's goals) | VERY HIGH | P3 / out of scope |
| Gamepad support | LOW (for this project's goals) | MEDIUM | P3 / out of scope |
| Music | MEDIUM | MEDIUM | P3 (explicitly deferred) |

**Priority key:** P1 = must have for v1 launch; P2 = should have, add when possible within v1 or immediately after; P3 = future consideration.

## Competitor Feature Analysis

Brief scan for genre table-stakes framing (not deep mechanical research — Thronefall itself is the primary reference).

| Feature | Thronefall | Kingdom Two Crowns | Bad North | Kingdom Rush | Our Approach |
|---|---|---|---|---|---|
| Build placement | Fixed, pre-designed spots per map | Free placement along a 2D lane/path | Free placement on small island terrain | Fixed tower slots along a lane | Fixed spots (matches Thronefall; explicit project requirement) |
| Player avatar in combat | Mounted king, direct combat + build | Mounted monarch, no direct combat (recruits/commands only) | No direct player avatar (top-down squad command only) | No player avatar (pure tower placement) | Mounted king, direct combat (matches Thronefall — this is the genre-differentiating hybrid) |
| Session/run structure | Level-based, retry-with-soft-penalty, discrete maps | Procedurally-continuous islands, run persists forward even through "death" | Islands lost permanently if failed (roguelite permadeath per island) | Level-based, replayable, no permadeath | Level-based, retry-with-soft-penalty (matches Thronefall, explicitly not Kingdom Two Crowns/Bad North's permadeath models) |
| Meta-progression | Player level → weapon/perk/hero unlocks; perk loadout; mutators for score | Persistent gold/gear carried between islands; "greed" risk-reward | Persistent commander unlocks across the campaign | Hero unlocks, tower upgrade trees, stars per level | Player/map-XP → weapon/perk unlocks; perk loadout; mutators for score (matches Thronefall model) |
| Art direction | Low-poly 3D, minimalist, silhouette-readable | 2D pixel/side-scroller | Low-poly 3D, minimalist (closest visual cousin) | 2D hand-painted, lane-based | Low-poly 3D CC0 assets, silhouette-readable (matches Thronefall and Bad North's minimalist-readability approach) |
| Currency model | Single currency (gold) | Single currency (gold/coins) | No persistent currency (squad-based, not economy-based) | Single currency (gold) per level | Single currency (gold) — genre-standard, matches Thronefall |

**Takeaway:** the genre broadly agrees on single-currency economies and level-based (not fully open-world) structure. Thronefall's two real differentiators versus its closest neighbors are (1) fixed build spots enabling curated per-level tech trees, and (2) a directly-controlled, weapon-driven king turning the game into a hybrid strategy/action title rather than pure top-down command (Bad North, Kingdom Rush) or a management sim with a non-combatant avatar (Kingdom Two Crowns). Both are already core, non-negotiable requirements in PROJECT.md — this research confirms they are the right things to protect as table stakes.

---
*Feature research for: Thronefall-like day/night strategy game (Windows PC recreation)*
*Researched: 2026-09-28*
