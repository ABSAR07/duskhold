# Phase 2: Night Defense & Playtest Gate - Research

**Researched:** 2026-10-03 (14:38 UTC at start; machine is UTC+5)
**Domain:** Deterministic fixed-step night simulation (waves, melee/ranged combat, building damage) on Godot 4.7.2 GDScript, plus the loop closure (dawn rebuild, win/loss), the presentation that makes it readable, and the headless replay/balance tooling that backs the playtest gate
**Confidence:** HIGH on the determinism rule set and on how the existing code must change (read this session, with engine probes). MEDIUM on balance numbers and on cross-platform golden stability (flagged ASSUMED; the harness exists to settle them).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried Forward (locked before this discussion — do not re-litigate)**
- Stack, controls, architecture split (simulation / presentation / data), `.tres` content, command/intent layer and CC0-only assets, as recorded in `01-CONTEXT.md`.
- The start-night hold-to-confirm input already exists (Phase 1 D-11). `RunManager` is the only writer of the loop phase; Phase 2 replaces `_night_should_end` and `_apply_dawn_payout` instead of rebuilding the loop (plan 01-09).
- The prototype map stays the permanent sandbox: 5 House plots, 3 tower plots, the castle center in the middle (Phase 1 D-03, D-04). One building type per spot (D-02). Tiers stay linear (D-10).
- The starting economy is tight (D-09). Enemies drop no gold.
- Every tunable number lives in `.tres` data, never in code (Phase 1 D-09 pattern, `loop_tuning.tres`).

**King Knockout & Respawn**
- **D-01:** The respawn countdown grows with each knockout in the same night, up to a cap of 15 s. It starts at about 6 s and adds about 4 s per further knockout that night, then stays at the cap. The count resets at dawn.
- **D-02:** The start value, the step and the 15 s cap are tuning data. The owner expects to adjust the cap later and may tie it to difficulty settings in a later phase, so nothing about it may be hard-coded.
- **D-03:** A knockout costs only the time away. No gold penalty, and the king returns at full health.
- **D-04:** The king is sturdy but mortal. He can fight a small group alone, but a full wave knocks him out if he stands in it, so towers and positioning stay meaningful.
- **D-05:** Health returns only at dawn (full heal) or through a respawn. There is no regeneration during a night in Phase 2; Phase 3's regeneration rule (KING-05) is added on top later.
- **D-06:** The king respawns at the castle after a visible countdown (KING-06). The run never ends because of the king.

**Enemies & Night Shape**
- **D-07:** A full run on the prototype map is 8 nights. Surviving night 8 wins.
- **D-08:** Two enemy types: a basic melee grunt and a ranged attacker. The ranged type is introduced a few nights in. The wider roster waits for Phase 6.
- **D-09:** Spawn points start at 1 and grow to 3. Night 1 comes from one side; later nights add a second and then a third direction, so the telegraph icons matter and the king cannot be everywhere.
- **D-10:** A first run is winnable with good choices. Greedy or careless play should lose around the middle nights. Wave compositions are hand-authored per night and per spawn point, in data, so they can be retuned after the playtest.

**Building Damage & Towers**
- **D-11:** Enemies attack the nearest thing in their path. They march toward the castle center and attack whatever is close on the way: the king, a tower or a House. Outer buildings act as a buffer, and the king can pull enemies off them.
- **D-12:** A destroyed building becomes rubble on its plot with a short collapse effect, and stays that way until dawn. Before that, damage shows as a health bar that appears only once the building has been hurt.
- **D-13:** Towers shoot the nearest enemy in range with a visible projectile. Tier II shoots faster or harder. Smarter targeting is left for tower specializations in Phase 6.
- **D-14:** A rebuilt House shows a crossed-out coin above it at dawn while the surviving Houses send coins to the gold counter. The icon fades when the day starts.

**Win, Loss & Playtest Gate**
- **D-15:** The results screen shows the outcome plus a few run stats: Victory or Defeat, nights survived out of 8, gold earned, buildings lost and king knockouts. There is no score yet (Phase 9).
- **D-16:** From the results screen the player can restart or quit. "Play again" restarts the map from day 1; "Quit" closes the game. There is no main menu until Phase 13, and no retry of a single failed night until Phase 9.
- **D-17:** Losing has a short beat. The castle collapses, the action freezes for about a second so the player sees what happened, then the Defeat screen appears. The loss itself is decided the instant the castle center falls (LOOP-06).
- **D-18:** The playtest gate is mostly delegated to Claude. Claude runs scripted, seeded playthroughs, reports balance numbers (for example nights survived under different build orders, gold over time, knockouts, buildings lost) and checks readability from screenshots. The owner plays only one or two runs for feel and then gives the sign-off or names the fixes. The sign-off stays the owner's decision and is recorded through `/gsd-verify-work`.
  - Note for planning: ROADMAP success criterion 4 says the owner plays "several full runs". The owner chose a lighter version on 2026-10-03. Plan the scripted playthrough tooling and the balance report as real deliverables, and keep the owner's part to one or two runs.

### Claude's Discretion
- The look of the spawn-point telegraph icons and how enemy counts are shown on them.
- Exact health, damage, range, speed and attack-rate numbers for the king, towers, buildings and both enemy types, as long as they are data and meet D-04 and D-10.
- The exact countdown values of D-01 other than the 15 s cap.
- How the king's passive auto-attack looks and how far it reaches.
- How enemies path around buildings and each other, and what they do when blocked.
- Night lighting and how the action stays readable in the dark.
- The exact length and look of the loss beat (D-17), and the layout of the results screen.
- The seeded-RNG and fixed-step rules that make a night deterministic (DEV-05). Settle them before combat code is written.
- Which CC0 models stand in for the two enemies, the arrow and the rubble.

### Deferred Ideas (OUT OF SCOPE)
- Difficulty settings that change the respawn cap (and possibly other tuning) — a later phase; Phase 2 only keeps the values in data.
- Retrying a failed night — Phase 9 (RETRY), not brought forward.
- King health regeneration — Phase 3 (KING-05), not brought forward.
- A small minimap (from Phase 1 UAT) — still in the Phase 1 UAT follow-ups, not part of Phase 2.
- Drip coins hidden inside already-built models on upgrades (seen in Phase 1 UAT) — not logged as a task yet; could ride along with any VFX work here if the planner finds it cheap.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOOP-01 | No day timer; night starts only by deliberate hold-to-confirm | Already true from Phase 1 (`StartNightHoldController`, `RunManager.start_night` is the only exit from DAY). Phase 2 adds a regression test that the day never advances on its own once nights have real waves, and keeps the hold prompt wording. See "RunManager integration". |
| LOOP-02 | Per-spawn-point enemy count icon during the day | Pure `WaveSchedule.preview_counts(night)` in the sim; presentation world icon plus **screen-edge clamped marker** (spawn points are about 66-70 m from the castle and the camera footprint is about 30 m wide, so a world-only icon is off-screen). See "Telegraph". |
| LOOP-03 | Night ends only when every enemy spawned that night is dead | `_night_should_end()` becomes `night.is_cleared()` = all spawn groups finished AND alive count 0; waveless-map fallback keeps Phase 1 tests valid. |
| LOOP-04 | Destroyed buildings rebuilt free at dawn | `BuildingSystem.rebuild_destroyed()` called from `RunManager._enter_dawn` before payout; same tier restored. |
| LOOP-05 | Surviving economic buildings pay; rebuilt ones pay nothing and are marked | `dawn_income_by_spot()` skips `rebuilt_this_dawn`; new `buildings_rebuilt` event drives the crossed-out coin (D-14). |
| LOOP-06 | Immediate loss when the castle center falls | `CastleState` hp; `castle_destroyed` handled inside RunManager -> new terminal `LOST` phase in the same step (loss beats win on a same-tick tie). |
| LOOP-07 | Win after the final night, results screen | Terminal `WON` phase when the last night is cleared (no dawn after the final night, see Open Question 2); `run_ended` event; `RunStats` feeds the results screen. |
| KING-03 | King auto-attacks enemies in range | `KingState` passive attack (range/damage/interval in `KingDef`), nearest enemy, id tie-break, resolved through the same pending-hit queue as every attack. |
| KING-06 | King knocked out, respawns at castle after visible countdown | `KingState` downed state; respawn seconds = `min(start + step*(n-1), cap)` from LoopTuning data (D-01/D-02); HUD countdown label plus ghosted king. |
| BLDG-07 | Buildings have health, take damage, visibly destroyed | `BuildingTierDef.max_health`, `BuildingInstance.health/destroyed`, `building_damaged/building_destroyed` events; hurt-only health bar, rubble plus collapse effect. |
| DEV-05 | Seeded deterministic simulation; scripted nights replay identically | The Determinism Rule Set below, `ReplayDriver` + CLI (`tools/replay.sh`) + GUT double-run tests + CI step. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Extracted from `./.claude/CLAUDE.md` (read this session). The planner must treat these like locked decisions.

- **Stack:** Godot 4.7.2-stable, GDScript (standard build, no C#), GUT 9.7.1 tests, gdtoolkit 4.5.0 `gdformat`/`gdlint`. Static typing everywhere; the project sets `gdscript/warnings/untyped_declaration=2` so an untyped variable or `for` iterator is a **compile error** [VERIFIED: project.godot:19 `gdscript/warnings/untyped_declaration=2`; probe: `"for" iterator variable "k" has no static type. (Warning treated as error.)`].
- **Text-first, headless-first:** text `.tscn`/`.tres`, everything verifiable from `godot --headless`; no editor GUI work.
- **Assets:** CC0 (or equally permissive) only, attribution log maintained (`ASSETS.md` + `assets/attribution.json`, enforced by `tests/unit/test_attribution_log.gd`). **No Thronefall names, art or assets.**
- **Platform/input:** Windows PC; keyboard + gamepad gameplay; **mouse for menus only** (so the results screen buttons must also be keyboard/gamepad focusable).
- **Budget:** zero-cost tools and assets.
- **Performance:** modest hardware (about GTX 970 / 4 GB), 60 fps; Phase 2 is only tens of enemies but the design must not block Phase 4's hundreds.
- **Workflow:** file-changing work goes through a GSD command (executors run under `/gsd-execute-phase`). Researcher writes only RESEARCH.md.
- No project skills exist (`.claude/skills/` etc. checked by CLAUDE.md: "No project skills found").

## Summary

Phase 2 is mostly one decision made early and kept: **the night is a pure, integer-tick, fixed-step simulation on `RefCounted` objects, driven by one `RunContext.step()`**, with no engine physics, navigation, Area3D, global RNG or wall-clock input anywhere in it. Everything the owner sees (enemy puppets, projectiles, health bars, rubble, telegraphs, countdowns) is presentation that reads sim state and listens to `SimEvents`. That single rule makes DEV-05 cheap (two runs of the same seed and script produce the same event log), makes the headless GUT coverage straightforward (the Phase 1 harness already constructs a `RunContext` with no scene tree), and leaves Phase 4 free to swap the storage to packed arrays and the steering to a flow field behind the same id-based API.

The existing code is a good base but has seven concrete gaps the plans must close: (1) `MapRoot._process` ticks the sim with a variable, clamped frame delta, so a fixed-step accumulator must replace it; (2) the sim has no king (the `King` node owns position/health-less movement in presentation), no castle health, no building health, no enemies; (3) `RunPhase` has no terminal states; (4) `SimEvents` has 7 signals and a drift-guard test that will fail until each new signal is added to `tests/support/sim_signals.gd`; (5) about a dozen Phase 1 tests and the HUD/screenshot tooling rely on the 4-second placeholder night; (6) the prototype map is 140 m square and spawn points need to sit about 66-70 m out collinear with the tower plots; (7) the debug overlay is text-only, so "enemy paths" needs a small 3D line gizmo. All of these are listed with file paths below.

For the two open STATE.md concerns: **determinism** is settled by 12 rules (DR-1..DR-12) below, each backed by an engine probe run this session where it could be (RNG sequence, dictionary order, unstable sort, float32 vectors, integer wrap, script-error exit code, 40-enemy tick cost); **pathing** is "straight-line march to the castle with proximity aggro, commit-to-target, and cheap id-ordered separation", with no NavigationServer and an `EnemyMover` seam that Phase 4 replaces with a flow-field sample. The playtest gate (D-18) is built on a `ReplayDriver` + scripted `PlaytestBot`s + a CLI that emits a per-night balance table.

**Primary recommendation:** Plan the determinism rules, `SimClock`/`SimRng`/integer-tick helpers, data schema and the migration of the Phase 1 placeholder-night tests as Wave 1 (before any combat system), write combat as ordered systems inside `NightSim.step()`, keep all presentation read-only over ids and events, and build the replay CLI and bots in parallel with the presentation work so the balance report exists before the owner plays.

## Architectural Responsibility Map

This is a single-process desktop game, so the "tiers" are the project's own layers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fixed-step clock, RNG streams, tick counter | Simulation (`simulation/`) | Presentation (`MapRoot` feeds real delta to `advance`) | Determinism requires the sim own time; presentation only supplies elapsed real seconds. |
| Wave schedule, spawning, telegraph counts | Simulation | Data (`MapConfig.nights`) | Hand-authored data; preview is a pure function of the schedule. |
| Enemy movement, aggro, targeting, melee/ranged attacks, pending hits | Simulation | — | Must be bit-reproducible; no physics/nav engine involvement. |
| Tower firing, king passive attack | Simulation | Presentation (cosmetic projectile/slash) | Damage is decided in the sim; projectiles are cosmetic and lag. |
| King position / movement | Presentation (`King` CharacterBody3D, real input) | Simulation (`KingState` receives position each step) | Phase 1 keeps the king in presentation; the sim consumes position as an input. Scripted nights push positions from a bot. |
| King hp, knockout, respawn countdown | Simulation | UI/HUD (countdown label), Presentation (ghost king, teleport on respawn) | Rules live in sim, shown by views. |
| Building / castle health, destruction, dawn rebuild, no-income flag | Simulation (`BuildingSystem`, `CastleState`) | Presentation (rubble, collapse, crossed-out coin) | State owner is `BuildingSystem`; the views react to events. |
| Phase transitions, win/loss | Simulation (`RunManager`, the only phase writer) | UI (results screen after the loss beat) | Existing rule enforced by a source-scan test. |
| Telegraph markers, health bars, enemy views, rubble | Presentation / UI | — | Display only; lag the sim. |
| Results screen, restart/quit | UI | Presentation (`MapRoot` handles restart) | Mouse allowed here (menus), must also work by keyboard/gamepad. |
| Debug overlay sections and enemy-path gizmo | UI overlay + Presentation gizmo | Simulation getters | Read-only, via `register_section` and sim getters. |
| Replay driver, bots, CLI, balance report | Tooling (`tools/replay/`, `tools/playtest/`) | Simulation | Headless; excluded from export by `exclude_filter="tests/*, addons/gut/*, tools/*"` [VERIFIED: export_presets.cfg:11]. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine (standard) | 4.7.2-stable | Engine; headless CLI | Pinned in `tools/godot_version.txt` (file read: `4.7.2-stable`); probe printed `VERSION 4.7.2-stable (official)` [VERIFIED: probe]. |
| GDScript (static typing) | 4.7 built-in | All sim + presentation code | Project constraint. |
| GUT | 9.7.1 | Headless unit/integration/e2e tests | Existing; baseline unit run: 24 scripts, 223 tests, all passing, 16 s wall [VERIFIED: `bash tools/test.sh -gdir=res://tests/unit` this session]. |
| gdtoolkit | 4.5.0 | `gdformat`/`gdlint` | Pinned in `tools/requirements-lint.txt`; `.gdlintrc` limits: `max-line-length: 100`, `max-public-methods: 20`, `max-returns: 6`, `function-arguments-number: 10`, `max-file-lines: 1000` [VERIFIED: .gdlintrc:41-43,25,40]. A `NightSim` that owns everything would breach 20 public methods; split into systems. |

### Supporting (all engine built-ins, no addons)
| Facility | Purpose | When to Use |
|----------|---------|-------------|
| `RandomNumberGenerator` (PCG32) | Per-stream seeded randomness | Spawn jitter/scatter only; one instance per (night, purpose). |
| `String.sha256_text()` / `HashingContext` | Replay digests | Digest of the canonical event log. `"abc".sha256_text()` printed `ba7816bf...15ad` [VERIFIED: probe]. |
| `JSON.stringify` / `FileAccess` | Replay/balance report files | Report output under `build/` (git-ignored). |
| `Camera3D.unproject_position`, `is_position_behind` | Screen-edge telegraph markers | Presentation only. |
| `Label3D`, `CPUParticles3D`, `Tween` | World labels, collapse dust, scale tweens | Presentation only; `CPUParticles3D` is safe under the headless dummy renderer. |
| `SceneTree` script (`extends SceneTree`, `-s`) | CLI runners | `tools/replay/replay_cli.gd`; verified to resolve project `class_name` types, receive `--` user args and propagate `quit(code)` [VERIFIED: probe2 exit=7, USERARGS printed]. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Straight-line march + aggro | `NavigationAgent3D` + RVO avoidance | Not deterministic-by-contract, tied to engine physics frames, needs a scene tree in tests, and does not scale to Phase 4 per project STACK notes. Rejected (see DR-9). |
| `CharacterBody3D` per enemy | Sim entities + puppet nodes | Per-node physics is the thing the project STACK says to avoid; blocks the Phase 4 scale-up. Rejected. |
| Hitscan damage at fire time + cosmetic arrow | Sim projectile entities with collision | Spatial projectile collision breaks determinism cheaply and scales badly. Use **pending hits** (target-id based, arrival tick). |
| 60 Hz sim step | 30 Hz sim step (recommended) | 60 Hz doubles Phase 4 cost for no gameplay gain; 30 Hz needs render interpolation of puppets (simple lerp of prev/curr). |

**Installation:** none. No new packages are installed in this phase.

**Version verification:** engine and GUT versions confirmed by running them this session (see above). No registry lookups apply.

## Package Legitimacy Audit

No external packages are installed in this phase (engine built-ins and the existing GUT 9.7.1 addon only), so the `package-legitimacy` gate has nothing to check.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | — |

**Packages removed due to SLOP verdict:** none
**Packages flagged SUS:** none

*Optional CC0 art (not a package): if the owner wants real enemy models instead of primitives, KayKit Character Pack: Skeletons (4 rigged skeletons, crossbows/arrows among 10+ accessories, glTF, CC0) is a candidate [CITED: github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0 via web search]. Phase 1 precedent (01-07) is that each new asset pack needs owner approval, an `ASSETS.md` row and an `assets/attribution.json` entry before it is committed. Recommendation: **primitives or recolored existing models in Phase 2; real art waits for Phase 8**, so no approval checkpoint is needed in this phase.*

## Architecture Patterns

### System Architecture Diagram

```
 REAL GAME                                         HEADLESS / CI
 ---------                                         -------------
 frame delta --> MapRoot._process                  ReplayDriver (tools/replay)
   (clamped MAX_SIM_STEP 0.25)                       |  scripted per-tick inputs:
        |                                            |  BuildIntent / StartNightIntent
        v                                            |  king position per tick (bot)
 RunContext.advance(real_delta)                      v
   accumulator: while acc >= STEP -----------> RunContext.step()   <-- the ONLY clock
        |                                            |
 King node (_physics_process, real input)            |
   position pushed once per step --------> KingState.report_position(pos)   (input boundary)
                                                     |
                                   RunContext.step():  fixed order, integer ticks
                                   1. NightSim.step()        (only while phase == NIGHT)
                                        1a WaveSpawner   -> spawn due groups (SimRng spawn stream)
                                        1b KingState     -> respawn timer, passive attack -> PendingHits
                                        1c Towers        -> nearest enemy in range -> PendingHits
                                        1d Enemies (id order) -> aggro/retarget, steer, separate, attack -> PendingHits
                                        1e PendingHits   -> resolve due hits (launch order): damage enemy / building / castle / king
                                        1f cleanup       -> remove dead (id order); castle_destroyed -> RunManager
                                   2. RunManager.tick(STEP)  -> _night_should_end(): night.is_cleared()
                                        NIGHT -> DAWN: rebuild_destroyed(), heal, payout (skip rebuilt)
                                        last night cleared -> WON ; castle_destroyed -> LOST (terminal)
                                   3. tick_count += 1
                                                     |
                                              SimEvents (synchronous signals)
                       +-----------------------------+----------------------------+
                       v                             v                            v
              Presentation views              SimRecorder (digest)          RunStats
       (EnemyViews, HealthBars, Rubble,      canonical int event log        (results screen:
        Projectile cosmetics, Telegraph,     -> sha256 -> golden/compare     nights, gold, lost,
        King ghost, DawnPayoutVfx, Hud,                                       knockouts)
        ResultsScreen, DebugOverlay+gizmo)
```

Primary use case trace: day -> player holds start-night -> `StartNightIntent` -> `RunManager.start_night` -> `NightSim.begin_night(n)` seeds the spawn RNG stream and loads the night's groups -> each `step()` spawns, moves, fights, resolves hits -> last enemy dies -> `RunManager` enters DAWN (rebuild, heal, payout) -> DAY, or `WON` after the last night, or `LOST` the instant the castle hits 0.

### Recommended Project Structure

New and changed files (existing paths verified this session; new paths are proposals).

```
simulation/
  clock/sim_clock.gd            # STEP constant source, accumulator, tick<->seconds helpers   (new)
  clock/sim_rng.gd              # stream_seed(), per-stream RandomNumberGenerator factory     (new)
  night/night_sim.gd            # orchestrates the fixed system order                         (new)
  night/wave_schedule.gd        # pure: preview_counts(night), due groups by tick             (new)
  night/enemy_system.gd         # arrays/ids, steer, aggro, separate, attack                  (new)
  night/tower_system.gd         # tower fire control                                          (new)
  night/pending_hits.gd         # delayed damage queue                                        (new)
  night/target_query.gd         # nearest(pos, radius, kinds) behind one function (Phase 4 seam) (new)
  king/king_state.gd            # hp, downed/respawn, knockouts, passive attack, position input (new)
  castle/castle_state.gd        # hp, destroyed                                               (new)
  run/run_stats.gd              # nights survived, gold earned, buildings lost, knockouts      (new)
  run/run_manager.gd            # + WON/LOST, night hooks, dawn rebuild                        (change)
  run/run_context.gd            # + night/king/castle/stats/seed, step(), advance()            (change)
  buildings/building_system.gd  # + damage/destroy/rebuild/repair, hp in snapshot             (change)
  buildings/building_instance.gd# + health, destroyed, rebuilt_this_dawn                      (change)
  defs/enemy_def.gd, spawn_point_def.gd, spawn_group_def.gd, night_def.gd                      (new)
  defs/map_config.gd            # + enemies, spawn_points, nights, castle_max_health, validate (change)
  defs/building_tier_def.gd     # + max_health, attack_interval, projectile_speed             (change)
  defs/king_def.gd              # + max_health, attack_range/damage/interval                   (change)
  defs/loop_tuning.gd           # + sim step, respawn start/step/cap, loss beat seconds        (change)
  events/sim_events.gd          # + night events (list below)                                  (change)
data/enemies/grunt.tres, ranged.tres   data/maps/prototype_map.tres (+ spawn points, 8 nights)
presentation/enemies/enemy_views.gd    # pooled puppets + interpolation, cosmetic projectiles
presentation/vfx/ (health_bar_3d.gd, rubble_view.gd, projectile_vfx.gd)
presentation/debug/enemy_path_gizmo.gd
ui/world/spawn_telegraph.gd            # world icon + screen-edge clamped marker
ui/results/results_screen.gd/.tscn     # outcome, stats, Play again / Quit
ui/overlay/night_overlay_sections.gd   # registers Wave / King / Paths rows through register_section
tools/replay/ (replay_driver.gd, sim_recorder.gd, playtest_bot.gd, replay_cli.gd), tools/replay.sh, tools/playtest.sh
tests/golden/*.json                     # expected digests per scenario
```

### Pattern 1: One fixed step, integer ticks inside the night

**What:** `RunContext.step()` is the only thing that advances the sim by exactly `STEP` seconds. Real time reaches it only through an accumulator. Inside `NightSim`, every timer (cooldowns, spawn schedule, respawn, pending-hit arrival) is an integer tick count.
**When to use:** always; headless tools call `step()` directly, the game calls `advance(real_delta)`.
**Example:**
```gdscript
# Source: design for this phase; accumulator shape follows the existing MapRoot clamp
# (map_root.gd:8 `const MAX_SIM_STEP: float = 0.25`, map_root.gd:29 `_ctx.run_manager.tick(minf(delta, MAX_SIM_STEP))`)
func advance(real_delta: float) -> int:
	_accumulator += minf(maxf(real_delta, 0.0), MAX_ADVANCE_SECONDS)
	var steps: int = 0
	while _accumulator >= SimClock.STEP:
		_accumulator -= SimClock.STEP
		step()
		steps += 1
	return steps   # presentation uses _accumulator / STEP as the interpolation alpha
```

### Pattern 2: Decide-then-resolve with pending hits

**What:** during a tick every attacker only *decides* (picks target, checks cooldown) and enqueues a `PendingHit{arrival_tick, seq, target_kind, target_id, amount}`; all hits due this tick resolve together afterwards in `(arrival_tick, seq)` order. Melee hits arrive in the same tick; ranged and tower hits arrive `ceil(distance / projectile_speed / STEP)` ticks later and apply to the **target id** (never a position), dropping silently if the target is already gone.
**Why:** trades are simultaneous and order-independent within a tick; there is no spatial projectile collision (cheap, deterministic, Phase 4 can render the arrows as a MultiMesh); presentation gets `attack_fired(..., flight_seconds)` to draw a cosmetic arrow.

### Pattern 3: Id-based, storage-agnostic API (Phase 4 seam)

**What:** callers address enemies by monotonically increasing integer ids that are never reused. `EnemySystem` exposes `ids()`, `position_of(id)`, `previous_position_of(id)`, `facing_of(id)`, `health_ratio(id)`, `def_of(id)`; no caller touches the storage. A `TargetQuery.nearest(pos, radius, filter)` function hides the linear scan; `EnemyMover.desired_step(enemy, goal)` hides the steering.
**Phase 4:** swap storage to packed arrays, `TargetQuery` to a spatial hash grid, `EnemyMover` to a flow-field sample, and views to a `MultiMeshInstance3D`, without touching combat rules or tests.

### Pattern 4: Waveless fallback keeps Phase 1 green

`RunManager._night_should_end()` becomes: if the map defines nights, `night.is_cleared()`; if `map.nights` is empty (test fixtures, `MapConfig.new()` built in tests), the Phase 1 placeholder timer applies. Then the ~12 Phase 1 test files and tools that tick `placeholder_night_seconds` keep working on a waveless copy of the prototype map; only the tests that load the shipped prototype map need to switch to a helper such as `E2eSupport.waveless_prototype_map()` (deep copy with `nights = []`, per the `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` precedent in `E2eSupport.map_with_tier_cost`).

### Anti-Patterns to Avoid
- **Engine physics/navigation in the sim** (`CharacterBody3D`, `Area3D`, `RayCast3D`, `NavigationAgent3D`): non-reproducible and node-bound.
- **Reading `delta` from `_process`/`_physics_process` inside sim code:** only `STEP`.
- **Global random** (`randi()`, `randf()`, `randf_range`, `Array.shuffle()`, `pick_random()`): shared global seed (docs: "this method uses a common, global random seed").
- **Sorting without a total order:** `sort`/`sort_custom` are not stable (docs; probe below).
- **Writing the loop phase outside `RunManager`:** an existing source-scan test fails it.
- **Calling `push_error` for a rejected operation:** GUT counts engine errors as failures; return a reason value (established pattern).
- **Presentation mutating sim state or sim waiting on visuals** (established pattern).

## Determinism Rule Set (settles STATE.md concern 1; fix these before any combat code)

Evidence column: `[VERIFIED: probe]` = run this session with `bash tools/godot.sh --headless -s <scratch script>` on 4.7.2-stable; `[CITED]` = official docs; `[ASSUMED]` = reasoned, not demonstrated.

| # | Rule | Why / evidence |
|---|------|----------------|
| DR-1 | The night sim is pure GDScript on `RefCounted` objects. It never touches a `Node`, `SceneTree`, physics server, navigation server, `Area3D`, `RayCast3D`, `Input`, `Time` or `OS`. The only inputs are the data resources, the run seed, intents (via `CommandProcessor`) and the king position pushed once per step. | Everything else depends on engine frame timing or hidden state. The Phase 1 harness already builds `RunContext` with no tree (`test_run_manager.gd` `_context()`), so this keeps it headless. |
| DR-2 | **One fixed step**, `SimClock.STEP = 1/30 s`, run by `RunContext.step()`. Real time enters only via `advance(real_delta)` (accumulator, clamped by the existing `MAX_SIM_STEP = 0.25`). Drive it from `MapRoot._process`, not `_physics_process`. Headless tools call `step()` N times. | `_physics_process` delta is constant but the engine may run up to `max_physics_steps_per_frame` per frame; probe printed `PHYS ticks 60 max steps 8` [VERIFIED: probe]. The accumulator gives the same step sequence however frames fall. 30 Hz halves Phase 4 cost; puppets interpolate prev->curr by `accumulator/STEP`. `STEP` is the one number that invalidates every golden, so pin it with a contract test and keep it out of casual tuning (a `LoopTuning` field is acceptable if the test pins the shipped value). |
| DR-3 | **Integer ticks inside NightSim.** Data stays in seconds; `SimClock.ticks(seconds)` converts once, with `maxi(ceili(seconds / STEP - 0.0001), 1)` for intervals. Cooldowns, spawn delays, respawn, pending-hit arrival are ints; `tick_count` is an int. | Integer comparison is exact on every platform; the digest and events can carry ticks. `RunManager`'s existing float `_phase_elapsed` for DAWN/placeholder timers stays as is (it is deterministic on one binary and carries no combat state). |
| DR-4 | **RNG:** only `RandomNumberGenerator` instances, explicitly seeded; one instance per (night, purpose) with `seed = SimRng.stream_seed(run_seed, night_number, stream_id)`. Never `seed + n`. Draw only at spawn time, in spawn order (position scatter, small speed variation, attack-cooldown offset). The presentation uses its own RNG; the sim RNG is never exposed. | Docs: PCG32 is "an implementation detail and should not be depended upon", and "The RNG does not have an avalanche effect, and can output similar random streams given similar seeds" [CITED: docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html]. Observed: seed 12345 -> `[1321476956, 17539747, 3348728241, 2863338820, 85463406]`, `state=5288669666918256702` [VERIFIED: probe]. Pin the first three values in a contract test so an engine change that alters the algorithm fails loudly. A splitmix64 mixer (snippet below) runs correctly in GDScript because `int` wraps on overflow (`9223372036854775807 + 1 -> -9223372036854775808` [VERIFIED: probe]). |
| DR-5 | **Forbidden in `simulation/`:** `randi(`, `randf(`, `randi_range(`, `randf_range(` on the global, `randomize(`, `.shuffle(`, `.pick_random(`, `Time.`, `OS.`, `get_tree(`, `NavigationServer`, `PhysicsServer`, `Engine.get_`, and (in the night/king/castle dirs) `sin(`, `cos(`, `tan(`, `atan2(`, `pow(`, `lerp_angle(`. A source-scan GUT test enforces it (same technique as the existing `test_only_the_run_manager_assigns_the_loop_phase`). | Global RNG: docs for `shuffle()`/`pick_random()` state they use "a common, global random seed" [CITED: docs.godotengine.org/en/stable/classes/class_array.html]; probe `GLOBAL randi 3595591889` is auto-seeded per process. Transcendentals are libm-dependent across compilers/platforms [ASSUMED]. `LoopTuning.coin_interval` uses `pow` but is outside the scanned dirs. |
| DR-6 | **Iteration order:** arrays in ascending id (enemies) or `MapConfig` order (spots); never iterate a `Node` group or child list; never mutate a collection while iterating it (collect, then apply); dictionaries only where insertion order is acceptable. Any sort must end with an id comparison. | Dictionary order is insertion order, including erase-then-reinsert going last (`DICT [5,3,9,1]`, `DICT2 [a, c, b]`) [VERIFIED: probe]. `sort_custom` is **not stable**: 40 items keyed `i % 3` came back as `[39,36,33,30,...,12,0,9,3,6,37,1,...]` [VERIFIED: probe]; docs: "The sorting algorithm used is not stable" [CITED: docs.godotengine.org/en/stable/classes/class_array.html]. |
| DR-7 | **Numerics:** hp/damage/ticks are `int`; compare squared distances; use only `+ - * /` and `sqrt` (`Vector2.length()`, `normalized()`, `move_toward` are fine). Positions are `Vector2` on the XZ plane; no `Vector3` in the sim. | GDScript `float` is 64-bit but `Vector2/3` components are 32-bit: `Vector2(0.1, 0.2).x == 0.1` is `false`, prints `0.10000000149012`; `0.1 + 0.2 == 0.30000000000000004` is `true` for scalars [VERIFIED: probe]. IEEE basic ops and `sqrt` are exactly specified; transcendental libm calls and compiler FMA contraction (a risk on ARM, not baseline x86-64) are not [ASSUMED]. |
| DR-8 | **Per-step order is fixed and documented** (diagram above): spawn, king, towers, enemies (id order), resolve pending hits, cleanup, then `RunManager.tick`. Attackers decide on the positions at the start of their own sub-step; separation uses a snapshot of enemy positions taken once per tick. A unit that dies while resolving hits still dealt the hits it launched this tick. Castle loss is checked at hit resolution, before the night-end check, so **loss beats win/dawn on a same-tick tie**. | Removes the order ambiguity that causes "same seed, different result" bugs; the tie rule is required by LOOP-06 ("the instant the castle center falls"). |
| DR-9 | **Not safe to depend on for replays:** `CharacterBody3D`/physics (Godot Jolt "is not able to make such guarantees" [CITED: github.com/godot-jolt/godot-jolt]); `NavigationServer3D`/`NavigationAgent3D` avoidance (its `velocity_computed` is emitted "every update" from the engine's physics-frame navigation update and the docs state no determinism guarantee [CITED: docs.godotengine.org/en/stable/classes/class_navigationagent3d.html]; whether it is reproducible across runs/threads is not demonstrated here [ASSUMED]); `_process` delta; `hash()` as a golden (Variant hash is an engine detail, `hash([1,2,3])` printed `3860078832`); scene-tree group order. **Safe on one pinned engine build:** `RandomNumberGenerator` with explicit seed, insertion-ordered `Dictionary`, `Array` order, `String.sha256_text()`. | Navigation is also unusable here because it needs a baked mesh and tree, and Phase 4 re-decides pathing anyway. |
| DR-10 | **Input boundary:** the only external inputs to a night are (a) intents through `CommandProcessor` and (b) `KingState.report_position(Vector2)` and sprint flag, applied at the **start** of each `step()`. A scripted run feeds both per tick; the real game feeds the `King` node's position. | Makes "scripted night" well-defined and keeps the Phase 1 king (CharacterBody3D in presentation, teleported by e2e tests via `global_position`) untouched. |
| DR-11 | **Events:** `SimEvents` signals are synchronous; listeners must be read-only. `SimRecorder` is connected first, in `RunContext._init`, so the recorded order equals emission order. | Phase 1 pattern ("the simulation never listens to presentation", `sim_events.gd` header). |
| DR-12 | **Shared mutable resources:** the sim never writes to a loaded `.tres`; tests and tools that vary data use `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` copies. | `E2eSupport.map_with_tier_cost` documents that a shallow `duplicate(true)` shared `house.tres` and leaked edits across tests (debugger-verified there). |

**Cross-platform caveat (honest scope of DEV-05):** replays are guaranteed identical for the **same engine binary**: same-process double runs, and cross-process runs on the same machine (probe2 produced the identical digest `43b7375e...` in two separate processes). Windows-vs-Linux identity of float results is plausible (same baseline x86-64 SSE2 math) but is **not established**, so the golden digest is computed from integers only (ticks, ids, hp, quantized positions `roundi(x * 100.0)`), and the CI step compares against a checked-in golden **and** runs the double-run self-check. If the first Linux CI run disagrees with the Windows-generated golden, fall back to per-platform golden files and keep the double-run gate as the hard determinism proof [ASSUMED risk, mitigation defined].

### Seed mixing (verified to run on 4.7.2)
```gdscript
# Source: probe4.gd run this session (outputs: mix(1) = -7995527694508729151, mix(2) = -7541218347953203506)
const GOLDEN: int = -7046029254386353131   # 0x9E3779B97F4A7C15 as signed int64
const M1: int = -4658895280553007687       # 0xBF58476D1CE4E5B9
const M2: int = -7723592293110705685       # 0x94D049BB133111EB

static func mix(x: int) -> int:
	var z: int = x + GOLDEN
	z = (z ^ ((z >> 30) & 0x3FFFFFFFF)) * M1   # & mask = logical shift (GDScript has no >>>)
	z = (z ^ ((z >> 27) & 0x1FFFFFFFFF)) * M2
	return z ^ ((z >> 31) & 0x1FFFFFFFF)

static func stream_seed(run_seed: int, night: int, stream: int) -> int:
	return mix(mix(mix(run_seed) + night) + stream)
```
Note: a literal `0x9E3779B97F4A7C15` is a parse error ("Cannot represent ... as a 64-bit signed integer", probe), hence the signed constants.

## Enemy pathing and targeting (settles STATE.md concern 2)

**Recommendation: straight-line march with proximity aggro, committed targets, and id-ordered separation. No NavigationServer, no per-enemy physics.**

- **March:** each enemy steers directly toward the castle position. Phase 2 has no walls or obstacles (walls are BLDG-10 / ENMY-04 in Phase 4), so a straight line is the correct path, never gets "blocked", and cannot softlock.
- **D-11 "attack the nearest thing in their path":** an enemy acquires the nearest valid target within `aggro_range` (data on `EnemyDef`): the king (if up), a standing building, or the castle; ties by lower id/spot order. It stops at `target.radius + attack_range` and attacks. A target is **kept until invalid** (dead, destroyed, downed king, or farther than a leash) with a data-driven re-scan every N ticks staggered by `id % N` and a hysteresis margin, which avoids the target-thrash pitfall documented in `.planning/research/PITFALLS.md` (Pitfall 5: "Commit to a target for a minimum duration").
- **Making towers "in the path" by authoring, not by pathfinding:** the three tower plots are at (-55,0,20), (55,0,20) and (0,0,-55) [VERIFIED: data/maps/prototype_map.tres:42-56 `position = Vector3(-55, 0, 20)`, `Vector3(55, 0, 20)`, `Vector3(0, 0, -55)`] and the castle at the origin. Put the three spawn points on the extension of the castle->tower ray, about 1.2x out: roughly (-66,0,24), (66,0,24), (0,0,-66). Each straight march then passes over its tower plot and, on the north route, house_5 at (0,0,-24). The W/E routes pass house_1/house_2 (about 5.7 m off the line) so an `aggro_range` near 6 m pulls them in. Tower range (8 and 10 m [VERIFIED: data/buildings/tower.tres:9-16 `attack_range = 8.0` / `10.0`]) exceeds melee aggro, so towers fire as grunts approach: outer buildings really act as buffers, and the king can pull aggro.
- **Ground size:** the ground plane is 140 x 140 m [VERIFIED: presentation/map/prototype_map.tscn:17 `size = Vector2(140, 140)`], so spawn points at 66-70 m sit on the map edge. Widen the plane to about 180 m (scene edit, no gameplay impact) so enemies do not appear at a cliff edge.
- **Separation (optional but recommended):** a push-out of overlapping enemies computed from the per-tick position snapshot, applied in id order. Without it, melee attackers stack on one point and screenshots read as one enemy. Cost is O(n^2) over tens of enemies.
- **Cost evidence:** a standalone scratch benchmark of 40 enemies, 10 targets, full O(n^2) separation at 30 Hz for 1800 ticks (60 simulated seconds) took **261 ms (145 us/tick)** in headless GDScript [VERIFIED: probe2; it is a stand-in for the real systems, not the shipped code]. A full 8-night run is therefore on the order of seconds [ASSUMED extrapolation: about 2,700 ticks per 90 s night, so about 21,600 ticks per 8-night run; real systems will cost more than the stand-in, so budget a 3x margin].
- **What this does not paint into a corner:** the same `EnemyMover.desired_step()` seam is replaced by a flow-field lookup in Phase 4; `TargetQuery` becomes a spatial hash; storage becomes packed arrays; combat, events and tests stay unchanged because everything is id-based and event-driven.
- **Do not build:** NavigationRegion/agent baking, RVO avoidance, `Area3D` aggro, per-enemy collision shapes.

### Starter numbers (ASSUMED, all data; the replay harness retunes them)
| Item | Starter value | Reason |
|------|---------------|--------|
| Sim step | 1/30 s | DR-2 |
| King | max_health 30, passive reach 3.0 m, damage 3, interval 0.8 s (3.75 dps) | D-04: handles about 3 grunts alone, not a wave |
| Grunt | hp 6, speed 3.2 m/s, damage 2, interval 1.0 s, attack_range 1.2, aggro 6, radius 0.5 | tower T1 (2 dmg/1.0 s) needs 3 s per grunt |
| Ranged | hp 4, speed 2.8, damage 2, interval 1.6 s, attack_range 7, aggro 9, projectile 14 m/s; first appears night 4 | D-08 "a few nights in" |
| Tower | T1 hp 20, 8 m, 2 dmg, 1.0 s; T2 hp 30, 10 m, 4 dmg, 0.8 s | extends existing `attack_range`/`attack_damage` data |
| House hp / castle hp | 8 / 12 / 16 by tier; castle 40 | buffers die before the castle |
| Respawn | start 6 s, +4 s per further knockout, cap 15 s (6, 10, 14, 15, 15...) | D-01/D-02 |
| Enemies per night | 5, 8, 11, 14, 18, 22, 27, 33 across 1, 1, 2, 2, 2, 3, 3, 3 spawn points | D-07/D-09; spawn stagger 1-2 s so about 25 alive at peak |

## Data schema (follows the existing `BuildingDef` / `BuildSpotDef` pattern)

- `EnemyDef` (`id, display_name, max_health, move_speed, radius, attack_range, attack_damage, attack_interval, aggro_range, projectile_speed` where 0 means melee).
- `SpawnPointDef` (`id, display_name, position: Vector3, scatter_radius`).
- `SpawnGroupDef` (`spawn_point_id, enemy_id, count, start_delay_seconds, interval_seconds`).
- `NightDef` (`groups: Array[SpawnGroupDef]`).
- `MapConfig` gains `enemies: Array[EnemyDef]`, `spawn_points: Array[SpawnPointDef]`, `nights: Array[NightDef]` (total nights = `nights.size()`, 8 for the prototype), `castle_max_health`. Existing `MapConfig` shape for reference [VERIFIED: simulation/defs/map_config.gd:8-17 `@export var spots: Array[BuildSpotDef] = []` with the comment "Order is significant: it breaks nearest-spot ties and fixes payout order."].
- `BuildingTierDef` currently has `cost`, `dawn_income`, `attack_range`, `attack_damage` [VERIFIED: simulation/defs/building_tier_def.gd:7-15]; add `max_health`, `attack_interval`, `projectile_speed`.
- `KingDef` currently has `walk_speed`, `sprint_multiplier`, `acceleration`, `turn_speed` [VERIFIED: simulation/defs/king_def.gd:5-11]; add `max_health` and the passive attack trio (Phase 10 will lift these into a weapon def).
- `LoopTuning` already holds `placeholder_night_seconds: float = 4.0` and `dawn_seconds: float = 2.0` [VERIFIED: simulation/defs/loop_tuning.gd:38,40]; add respawn start/step/cap (D-01/D-02), loss-beat seconds (D-17), re-scan interval.
- Extend `MapConfig.validate()` (returns strings, never blocks, per the existing T-01-10 pattern): unknown ids, `count <= 0`, negative delays, a night with zero enemies, `max_health <= 0`, per-night enemy caps (resource-exhaustion guard), spawn point count 1..3 for the prototype.
- RunContext keeps the 2-argument constructor used by 15 test files [VERIFIED: grep `RunContext.new` -> 15 files]; add optional trailing parameters (`run_seed: int = 1`, `king_def: KingDef = null`), with `null` falling back to loading the shipped king data. `MapRoot` passes `_king.def` and a run seed.

## RunManager integration (the two designated extension points, plus terminals)

Current code [VERIFIED: simulation/run/run_manager.gd]: `enum RunPhase { DAY, NIGHT_TRANSITION, NIGHT, DAWN }` (line 9); `func _night_should_end() -> bool:` / `return _phase_elapsed >= _tuning.placeholder_night_seconds` (93-94); `_apply_dawn_payout` pays `_buildings.dawn_income_by_spot()` once per DAWN entry (111-119); `start_night()` increments `_night_number`, passes NIGHT_TRANSITION then NIGHT in one call and emits `night_started` (66-73).

Changes:
1. **Append** `WON` and `LOST` to the enum (appending keeps existing integer values; `phase_changed` carries ints and the overlay uses `RunPhase.find_key`). `is_build_allowed()` stays `DAY` only.
2. `start_night()`: after the phase change, call `night.begin_night(_night_number)` (seed stream, load groups) before emitting `night_started`.
3. `_night_should_end()`: `night.is_cleared()` when the map has nights, else the Phase 1 placeholder timer (Pattern 4). In `tick`, if the final night is cleared go to `WON` instead of DAWN; otherwise `_enter_dawn()`.
4. `_enter_dawn()`: `rebuilt = _buildings.rebuild_destroyed()` (marks `rebuilt_this_dawn`), repair surviving buildings and castle, full-heal the king (D-05, and respawn him if still down), emit `buildings_rebuilt(rebuilt)`, then `_apply_dawn_payout()` which skips `rebuilt_this_dawn`. Clear `rebuilt_this_dawn` when the next night starts (so the marker lives through dawn and the following day per D-14 "fades when the day starts" is a presentation timing).
5. A `castle_destroyed` handler **inside RunManager** sets `LOST` immediately (not subject to the one-change-per-tick note; update that comment) and emits `run_ended(&"defeat")`; the sim stops stepping systems when the phase is terminal. The ~1 s loss beat (D-17) is presentation time (`ctx.tuning.loss_beat_seconds`), not sim time.
6. `get_phase_time_remaining()` currently reports the placeholder timer for NIGHT (line 57-58); for real nights return 0.0 and let the overlay show elapsed time and enemies left instead.
7. The source-scan test `test_only_the_run_manager_assigns_the_loop_phase` (regex `(^|[^A-Za-z0-9_])_phase\s*=[^=]` over `simulation`, `input`, `ui`, `presentation` [VERIFIED: tests/unit/test_run_manager.gd:189-203]) stays valid only if no other file assigns a variable literally named `_phase`. Name new fields differently.

**Events to add to `SimEvents`** (proposed): `enemy_spawned(enemy_id, def_id, pos)`, `enemy_damaged(enemy_id, amount, hp)`, `enemy_died(enemy_id, pos)`, `attack_fired(attacker_kind, attacker_id, target_kind, target_id, flight_seconds)`, `building_damaged(spot_id, amount, hp, max_hp)`, `building_destroyed(spot_id)`, `buildings_rebuilt(spot_ids)`, `castle_damaged(amount, hp, max_hp)`, `castle_destroyed`, `king_damaged(amount, hp)`, `king_downed(respawn_seconds, knockout_number)`, `king_respawned`, `run_ended(outcome)`. **Pitfall:** the drift-guard test `test_the_watched_signals_are_every_signal_the_simulation_declares` compares `SimEvents` script signals to `SimSignals.ALL` and fails with "a new SimEvents signal must be added to SimSignals.ALL" [VERIFIED: tests/unit/test_debug_overlay_readonly.gd:87-95; list at tests/support/sim_signals.gd:9-17 `"gold_changed", "building_built", "command_rejected", "phase_changed", "night_started", "dawn_payout", "day_started"`]. Add every new signal to `SimSignals.ALL` in the same task that adds it.

`.gdlintrc` `class-definitions-order` puts `signal` before `enum` before `const`; keep that ordering in new classes.

## Presentation and UI work (all read-only over the sim)

- **Telegraph (LOOP-02):** `WaveSchedule.preview_counts(night_number + 1)` returns spawn_point_id -> count in `MapConfig` order. The camera is a detached rig, fov 40, default offset (0, 20.8, 14.3) [VERIFIED: presentation/camera/camera_rig.gd `@export var offset: Vector3 = Vector3(0.0, 20.8, 14.3)`, scene `fov = 40.0`], so the visible ground footprint is roughly 30 m wide [ASSUMED arithmetic from fov and distance]; spawn points are about 66-70 m from the castle. A world-space icon alone is therefore off-screen. Build a HUD layer that, per spawn point, shows a world-anchored icon when on-screen and otherwise an edge-clamped arrow marker with the count (`unproject_position` + `is_position_behind`), visible only in DAY, and extend the start-night prompt with a one-line summary. Verify with a screenshot scenario.
- **Enemy views:** `EnemyViews` keeps a pool of puppet nodes keyed by enemy id, sets position by lerping `previous_position_of` -> `position_of` with `ctx.alpha()`; distinct silhouette/color per `EnemyDef` (primitives are fine now). Cap pooled visuals the way `CoinDripVfx` does (`MAX_BURST_COINS`).
- **Health bars (D-12):** one reusable billboard `HealthBar3D`, shown only when `hp < max_hp`; used for buildings, castle, king, enemies.
- **Rubble and collapse:** on `building_destroyed` swap the view for a rubble view plus a short tween/`CPUParticles3D` dust; on `buildings_rebuilt` re-instance the model at the same tier. `BuildingViews._on_building_built` currently replaces views by spot id [VERIFIED: presentation/buildings/building_views.gd `_on_building_built`], so it is the integration point; the castle is currently a landmark only (`_add_castle`, "Landmark only in Phase 1 (D-03)") and needs hp bar and collapse (also the D-17 beat).
- **King:** `King` is not in group `run_bound` today (`$King` is referenced directly by `MapRoot`), so `MapRoot` should call a new `king.bind_run(ctx)`; on `king_downed` hide/ghost the model and ignore input, show the HUD countdown, on `king_respawned` teleport to `ctx.map.king_spawn` (`Vector3(0, 0, 7)`, in front of the castle [VERIFIED: prototype_map.tres:63]).
- **Dawn marker (D-14):** `DawnPayoutVfx` is a `Control` overlay that already projects spot anchors; add a crossed-out coin per rebuilt economic spot (those whose tier has `dawn_income > 0`), faded at `day_started`.
- **HUD:** banner copy `"Night %d — no enemies yet"` (hud.gd) becomes real copy; `DayNightLighting._mood_for_phase` should map `LOST` to night and `WON` to dawn (unknown phases fall back to day today).
- **Results screen:** `CanvasLayer` with Victory/Defeat, nights survived of 8, gold earned (sum of dawn payouts), buildings lost, king knockouts (from `RunStats`); "Play again" (`get_tree().reload_current_scene()` works because `RunContext` is built in `MapRoot._ready`) and "Quit" (`get_tree().quit()`); focus the primary button so keyboard/gamepad work. Test the handlers' signals, never call `quit()` in GUT.
- **Night readability:** the lighting moods exist (night sun energy 0.25, ambient 0.3 in the scene); verify enemies, health bars and projectiles read at night with a screenshot, and tune emissive/outline there. Full art pass is Phase 8.

## Debug overlay (DEV-03 extension)

`DebugOverlay.register_section(title, provider, lifetime_owner)` and the model's `register_section` are the documented extension path ("Phase 2 and later add sections (wave state, enemy paths) through this, not by editing the model" [VERIFIED: ui/overlay/debug_overlay.gd]); default titles `["Perf", "Loop", "Agents"]` cannot be reused [VERIFIED: debug_overlay_model.gd `DEFAULT_TITLES`]. `RunContext.get_enemy_count()` currently returns 0 [VERIFIED: run_context.gd:32-33] and feeds the default Agents section, so wiring it to `night.enemy_count()` gives live enemy counts for free. Add sections "Wave" (night n/total, spawned/total, alive, next spawn in ticks, cleared), "King" (hp, knockouts, respawn countdown), "Paths" (count of active paths plus nearest target per spawn point). The overlay is text-only, so draw the **path gizmo** as a small `Node3D` using `ImmediateMesh`/`ArrayMesh` lines from each enemy to its current target and from each spawn point to the castle, visible only while the overlay is visible. Register the sections from a helper called by `DebugOverlay.bind_run` (so `DebugOverlayModel` stays unchanged and `test_default_sections_are_perf_loop_agents_in_order` keeps passing, since it uses a bare model). Check `tests/unit/test_debug_overlay_registration.gd` and the overlay text assertions before adding sections to the live overlay.

## Replay, CI and the playtest gate (DEV-05, D-18)

**ReplayDriver** (`tools/replay/replay_driver.gd`): builds a `RunContext(map, tuning, seed)`, runs a `PlaytestBot` each tick (`think(ctx, tick)` issues `BuildIntent`/`StartNightIntent` and pushes the king position), calls `ctx.step()`, stops on `WON`/`LOST` or `max_ticks`, and returns `{outcome, ticks, digest, per_night[]}`.

**SimRecorder** (`tools/replay/sim_recorder.gd` or in `simulation/` if the in-game desync log is wanted): connects to every `SimEvents` signal with explicit handlers and appends canonical lines `"<tick> <event> <int args>"`; digest = `String.sha256_text()` of the joined lines. Add a drift test mirroring the `SimSignals` guard so a new signal cannot be left unrecorded.

**CLI** (`tools/replay/replay_cli.gd`, `extends SceneTree`, run via `tools/replay.sh` which does the headless `--import` warm-up like `tools/test.sh`, wraps `timeout`, and writes `build/replay/<scenario>.json`): args `--scenario=<allowlisted name> --seed=<int> --twice --expect=<digest|golden-file> --out=<dir under build/>`. Exit 0 only when a sentinel line `REPLAY_OK scenario=... seed=... digest=...` was printed.
- **Hazard verified this session:** a runtime error inside a function called from `_initialize` prints `SCRIPT ERROR` but the process still exits **0** and the caller carries on with a default value (probe3: `code=0`, `exit=0`). So the wrapper must (a) require the sentinel line, and (b) grep the output for `SCRIPT ERROR|Parse Error|Failed to load script` the way `tools/test.sh` does for parse errors, and (c) always run under `timeout` (earlier probes on this machine hung).
- **CI:** add a step to the existing `test` job after "Headless import and GUT": `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json`, and upload `build/replay/` with the existing `gut-results` artifact. The workflow already runs on every push with read-only permissions [VERIFIED: .github/workflows/ci.yml `permissions: contents: read`]; keep action SHA pins untouched.
- **Also in GUT** (so `tools/test.sh` locally covers it): `tests/integration/test_determinism.gd` runs two contexts with the same seed/script and asserts equal digest and equal final state, different seeds give different digests (spawn scatter is seeded), and compares to the golden. A same-process double run is the primary DEV-05 proof.

**Balance report for the gate (D-18):** `tools/playtest.sh` runs a matrix of `PlaytestBot` build orders x seeds on the shipped map and writes `build/playtest/report.json` plus a markdown table (copy the final table into the phase directory as the gate evidence). Suggested bots: `no_build` (sanity: should lose early), `houses_first`, `towers_first`, `balanced`, `greedy_economy` (D-10: should lose mid-run), each with a king behavior (`idle_at_castle`, `defend_nearest_threat` moving at `KingDef` speeds with sprint). Metrics per night: enemies, kills by king/towers, buildings lost, king knockouts, castle hp, night duration (s), gold at dawn. Run-level: outcome, nights survived, total gold earned. Acceptance for tuning: `balanced` wins most seeds, `greedy_economy` and `no_build` lose, losses cluster around the middle nights (D-10). Use a small seed set in CI-adjacent runs and a larger local sweep (about 21,600 ticks per full run, see cost note). Optional low-cost stretch: have the real game write the king-position trace and commands of an owner run to `user://` so the owner's one or two runs can be replayed and measured by the same harness.

**Screenshots (DEV-04 extension):** add shots for `spawn_telegraph`, `night_combat`, `building_destroyed`, `dawn_rebuilt`, `king_down_countdown`, `results_victory`, `results_defeat`, `overlay_paths`. The shot list lives in **two** places that must change together: `tools/screenshot.sh:21` `ALL_SHOTS=(day_overview ... king_behind_keep)` and `tools/screenshot/shot_scenarios.gd:31` `const ALL_SHOTS`. A scenario cannot wait real-time for a 60-90 s night; add a `MapRoot.fast_forward(seconds)` that calls `ctx.step()` in a loop (the same path as headless), then wait a few frames and capture. Screenshots never run under `--headless` (runner exits 2 there).

**Owner gate:** per D-18 the owner plays one or two runs after the balance table and screenshots exist; the sign-off or tuning list is recorded through `/gsd-verify-work` (a `checkpoint:human-verify` task). No meta-progression work is scheduled before it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Random numbers | A custom PRNG | `RandomNumberGenerator` per stream, plus the 6-line splitmix seed mixer | PCG32 is built in and pinned by a first-values contract test; only the seed derivation needs code because similar seeds give similar streams. |
| Hashing the replay | A custom checksum | `String.sha256_text()` / `HashingContext` | Verified output `ba7816bf...15ad` for "abc". |
| Enemy pathing | A navmesh or flow-field now | Straight-line march behind `EnemyMover` | Phase 2 has no obstacles; Phase 4 adds the real solution. |
| Projectiles | Physics bodies or sim projectile collision | Pending hits + cosmetic puppets | Deterministic, cheap, scales. |
| World-to-screen markers | Manual matrix math | `Camera3D.unproject_position` / `is_position_behind` | Engine-provided. |
| Test runner / junit | A custom runner | GUT (`tools/test.sh`) | Existing, JUnit XML for CI. |
| Fixed-step loop | Per-frame variable delta | Accumulator in `RunContext.advance` | Determinism and clamped catch-up. |
| Health bars, rubble, results screen | Per-feature one-off nodes | One reusable `HealthBar3D`, one `RubbleView`, one `ResultsScreen` | Phase 3 HUD and Phase 6 roster reuse them. |

**Key insight:** the expensive bugs here are ordering bugs (who acts first, who is removed when), not math bugs. A single documented step order plus an id total order removes the class.

## Common Pitfalls

### Pitfall 1: The SimSignals drift guard fails the suite
**What goes wrong:** adding a `SimEvents` signal without adding it to `SimSignals.ALL` fails `test_the_watched_signals_are_every_signal_the_simulation_declares`.
**How to avoid:** make "add to SimSignals.ALL (and to SimRecorder)" part of the same task as each new signal.
**Warning signs:** red `test_debug_overlay_readonly.gd` after an events change.

### Pitfall 2: About a dozen Phase 1 tests and tools assume the 4 s placeholder night
**What goes wrong:** once nights have enemies, `tick(placeholder_night_seconds + 0.1)` no longer reaches DAWN.
**Affected files** [VERIFIED: grep of `placeholder_night_seconds|NIGHT_BANNER|no enemies yet|run_manager.tick|get_phase_time_remaining`]: `tests/e2e/test_dawn_payout.gd`, `tests/e2e/test_start_night_hold.gd`, `tests/integration/test_loop_gold_carryover.gd`, `tests/support/overlay_test_support.gd`, `tests/unit/test_build_phase_guard.gd`, `tests/unit/test_dawn_income.gd`, `tests/unit/test_debug_overlay_timed_phases.gd`, `tests/unit/test_e2e_support_tuning.gd`, `tests/unit/test_run_manager.gd`, `tools/screenshot/shot_scenarios.gd`, `ui/hud/hud.gd` and `hud.tscn`, `presentation/map/map_root.gd`, `ui/overlay/debug_overlay_model.gd`.
**How to avoid:** waveless fallback (Pattern 4) plus a `waveless_prototype_map()` helper, done in Wave 1 before combat code lands.

### Pitfall 3: Unstable sort and global RNG slip in
**How to avoid:** DR-5 source-scan test; review every `sort_custom` for an id tie-break.

### Pitfall 4: Script runtime errors exit 0 in CLI runs
**How to avoid:** sentinel line + stderr grep + `timeout` in `tools/replay.sh` (verified hazard above).

### Pitfall 5: Telegraph icons are off-screen
**How to avoid:** edge-clamped markers; screenshot scenario asserts non-blank and the plan's UAT checks it at the castle position.

### Pitfall 6: Enemies stack into one blob and the night "looks empty"
**How to avoid:** separation pass and per-enemy position scatter at spawn (seeded).

### Pitfall 7: A night that never ends
**What goes wrong:** LOOP-03 ends only on all-dead; a spawn group scheduled but never due, or an enemy that cannot reach any target, softlocks.
**How to avoid:** `is_cleared()` requires all groups finished spawning and alive == 0; validate every night has at least one enemy; a test that every shipped night completes under a bot within a tick budget; overlay shows "spawned x/y".

### Pitfall 8: Loss/win tie and double transitions
**How to avoid:** DR-8 tie rule and a test where the last enemy and the castle die in the same step.

### Pitfall 9: Presentation reading half-updated state
**What goes wrong:** signals are synchronous, so a listener sees the sim mid-step.
**How to avoid:** views read getters only in their own `_process`, using events for one-shots (spawn/die/hit), never to mutate.

### Pitfall 10: GUT counts engine errors as failures
**How to avoid:** rejected operations return values; no `push_error` in expected paths. Commit each `.gd.uid` with its script; run `bash tools/lint.sh --fix` before commits; `.gdlintrc` caps (20 public methods, 100 columns).

### Pitfall 11: Shared `.tres` mutation across tests
**How to avoid:** `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` for any data variation (DR-12).

### Pitfall 12: Python/PowerShell quoting and em dashes
**What goes wrong:** Phase 1 note: Python edits of files containing an em dash need `encoding="utf-8"` on Windows. The HUD banner copy contains an em dash.

## Code Examples

### Two-phase night step (order is the contract)
```gdscript
# Source: design for this phase (DR-8). All timers are int ticks; positions are Vector2.
func step(tick: int) -> void:
	_spawner.step(tick)                 # 1a spawn due groups, draws from the night's spawn stream
	_king.step(tick, _enemies)          # 1b respawn timer; passive attack enqueues a PendingHit
	_towers.step(tick, _enemies)        # 1c nearest in range, tie lower id
	_enemies.step(tick)                 # 1d id order: aggro/retarget, steer, separate, attack
	_hits.resolve(tick)                 # 1e (arrival_tick, seq) order; castle loss emits here
	_enemies.remove_dead()              # 1f id order, emits enemy_died
```

### Source-scan guard (modelled on the existing phase-writer test)
```gdscript
# Source: pattern from tests/unit/test_run_manager.gd:189-203 (RegEx over source roots)
const FORBIDDEN: Array[String] = [
	"(^|[^A-Za-z0-9_.])randi\\(", "(^|[^A-Za-z0-9_.])randf\\(", "randomize\\(",
	"\\.shuffle\\(", "\\.pick_random\\(", "Time\\.", "OS\\.", "get_tree\\(",
	"NavigationServer", "PhysicsServer",
]
func test_the_simulation_uses_no_nondeterministic_engine_facilities() -> void:
	var offenders: Array[String] = []
	for path: String in _gd_files("res://simulation"):
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			# skip comment-only lines, then test each pattern
			...
	assert_eq(offenders, [], "no forbidden call in simulation/")
```

### CLI skeleton with sentinel (the verified exit-code hazard)
```gdscript
# Source: probe2.gd/probe3.gd pattern run this session
extends SceneTree

func _initialize() -> void:
	var args: Dictionary = _parse(OS.get_cmdline_user_args())   # allowlist scenario, int-check seed
	var result: Dictionary = ReplayDriver.run(args)             # a runtime error inside still returns
	if result.is_empty() or not result.has("digest"):
		printerr("REPLAY_FAILED")
		quit(1)
		return
	print("REPLAY_OK scenario=%s seed=%d digest=%s" % [args["scenario"], args["seed"], result["digest"]])
	quit(0)   # tools/replay.sh ALSO requires the sentinel and greps for SCRIPT ERROR
```

### Recorder digest of integer events
```gdscript
# Source: design; ints only so the digest is robust to float formatting
func _on_enemy_died(enemy_id: int, pos: Vector2) -> void:
	_lines.append("%d enemy_died %d %d %d" % [_ctx.tick_count, enemy_id, roundi(pos.x * 100.0), roundi(pos.y * 100.0)])
# digest = "\n".join(_lines).sha256_text()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Variable-delta sim tick from `_process` (Phase 1 `MapRoot`) | Fixed-step accumulator, integer ticks | This phase | Required for DEV-05. |
| Placeholder 4 s night | Clear-on-all-dead with a waveless fallback | This phase | LOOP-03. |
| Text-only overlay | Sections via `register_section` + 3D path gizmo | This phase | DEV-03 extension. |
| Godot physics default | Godot 4.6 made Jolt the default 3D engine (web-search report) | 2026-01 | Irrelevant to the sim by design (DR-1); only the king node uses physics. |

**Deprecated/outdated:** `GutTest.wait_frames` is deprecated in GUT 9.7.1 (use `wait_process_frames`, STATE note 01-02).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Windows and Linux CI produce identical integer digests for the same seed | Determinism caveat | Golden compare fails on one platform; mitigation: per-platform goldens, double-run gate stays. |
| A2 | NavigationServer RVO is not reproducible across runs/threads | DR-9 | If it were deterministic, an alternative path existed; decision still stands because of tick coupling and tree dependence. |
| A3 | libm transcendental results and FMA contraction can differ across platforms | DR-5, DR-7 | Over-restriction costs little; under-restriction would break goldens. |
| A4 | Starter combat numbers and the 8-night enemy ramp (5..33) | Starter numbers | Wrong balance; the harness exists to retune before the owner plays. |
| A5 | Visible ground footprint at default zoom is about 30 m wide | Presentation | If wider, world icons might be on-screen sooner; edge markers remain correct and harmless. |
| A6 | A full 8-night headless run takes seconds (3x margin on the 145 us/tick stand-in) | Replay | If much slower, shrink seed matrix in CI. |
| A7 | Surviving buildings and the castle are fully repaired at dawn | RunManager integration | Not stated in CONTEXT.md; without repair damage snowballs. Confirm with owner (Open Question 1). |
| A8 | Final night goes straight to WON without a dawn payout | RunManager integration | Cosmetic; "gold earned" stat unaffected. |
| A9 | 30 Hz with prev->curr interpolation reads smooth enough at 60 fps | DR-2 | If puppets look choppy, switch the step to 60 Hz (one constant plus regenerated goldens). |

## Open Questions

1. **Are damaged-but-surviving buildings and the castle repaired at dawn?**
   - Known: D-05 covers only the king; LOOP-04 covers destroyed buildings.
   - Unclear: nothing in CONTEXT says whether surviving damage persists.
   - Recommendation: repair everything at dawn (matches "all units restored at dawn" in UNIT-07); flag to the owner at the gate.
2. **Final night: payout or straight to results?** Recommendation: straight to `WON` when the last enemy dies (a dawn payout has no use after the last night).
3. **King down when the night ends:** recommendation: respawn him at dawn with a full heal.
4. **Sim step 30 vs 60 Hz and ground width 140 vs 180 m:** recommendations above; the planner may defer to the executor with the contract-test pinning rule.
5. **Real enemy art:** primitives now vs KayKit Skeletons (owner approval + attribution entries). Recommendation: primitives.
6. **Golden cross-platform stability:** resolved empirically on the first CI run; mitigation defined.
7. **Record the owner's human runs for replay?** Optional, cheap; recommended if the sim input boundary (DR-10) is already a log.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot (console binary under `.tools/godot/4.7.2-stable/`) | all tests, replay CLI | yes | 4.7.2-stable (probe banner) | none needed |
| Git Bash + `tools/*.sh` | tests, lint, replay, screenshots | yes | working (unit suite ran) | — |
| GUT | tests | yes | 9.7.1; 223 unit tests passed | — |
| gdtoolkit venv | lint | present (`.tools/venv/Scripts` listed) | 4.5.0 pinned | CI installs from `tools/requirements-lint.txt` |
| Real renderer for screenshots | DEV-04 extension | not probed this session (Phase 1 ran them; CI uses xvfb + Compatibility) | — | CI screenshot job |
| `gh` / network | not required this phase | n/a | — | — |

**Missing dependencies with no fallback:** none.
**Probe hygiene:** all probes lived in the scratch directory, ended with `quit()`, ran under `timeout 60`; `tasklist` showed no Godot process after each run.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT 9.7.1 on Godot 4.7.2-stable, headless |
| Config file | `.gutconfig.json` (dirs `res://tests/unit/`, `res://tests/integration/`, `res://tests/e2e/`, `include_subdirs: true`, prefix `test_`, JUnit to `res://build/test-results/gut-junit.xml`) [VERIFIED: file read] |
| Quick run command | `bash tools/test.sh -gdir=res://tests/unit` (baseline 223 tests, 16 s) |
| Full suite command | `bash tools/test.sh` then `bash tools/lint.sh` |
| Single file | `bash tools/test.sh -gselect=test_<name>.gd` |
| Replay/determinism | `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` (new) |
| Balance report | `bash tools/playtest.sh` (new, local; not a CI gate) |
| Screenshots | `bash tools/screenshot.sh [shot]` (real renderer, never headless) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOOP-01 | Day never advances without the hold; hold is the only exit | unit + e2e | `-gselect=test_run_manager.gd`, `-gselect=test_start_night_hold.gd` | exists (extend) |
| LOOP-02 | Per-spawn-point counts for the coming night; markers on/off-screen | unit + e2e | `-gselect=test_wave_schedule.gd`, `-gselect=test_spawn_telegraph.gd` | Wave 0 |
| LOOP-03 | Night ends only when all groups spawned and all enemies dead; no early/late end | integration | `-gselect=test_night_loop.gd` | Wave 0 |
| LOOP-04 | Destroyed buildings return free at same tier at dawn | unit | `-gselect=test_dawn_rebuild.gd` | Wave 0 |
| LOOP-05 | Survivors pay tier income; rebuilt pay 0; `buildings_rebuilt` marks | unit + e2e | `-gselect=test_dawn_rebuild.gd`, `-gselect=test_dawn_rebuilt_marker.gd` | Wave 0 |
| LOOP-06 | Castle at 0 -> LOST that step; loss beats a same-tick win | integration | `-gselect=test_run_outcomes.gd` | Wave 0 |
| LOOP-07 | Last night cleared -> WON, `run_ended`, stats | integration | `-gselect=test_run_outcomes.gd` | Wave 0 |
| KING-03 | Passive attack nearest in range, cadence from data | unit | `-gselect=test_king_combat.gd` | Wave 0 |
| KING-06 | Downed, countdown 6/10/14/15/15 from data, respawn full hp at `king_spawn`, dawn reset | unit | `-gselect=test_king_respawn.gd` | Wave 0 |
| BLDG-07 | Damage, health bar threshold event, destroy at 0, rubble state | unit + e2e | `-gselect=test_building_damage.gd`, `-gselect=test_building_rubble.gd` | Wave 0 |
| DEV-05 | Same seed+script -> identical digest (in-process and CLI); different seed differs; golden matches; forbidden-API scan; RNG pin | integration + script | `-gselect=test_determinism.gd`, `-gselect=test_sim_rules_guard.gd`, `-gselect=test_sim_rng.gd`, `bash tools/replay.sh ...` | Wave 0 |
| D-07..D-10 | Data contract: 8 nights, 2 enemy types, 1->3 spawn points, ranged not before night 3, respawn data | unit | `-gselect=test_night_data_contract.gd` | Wave 0 |
| DEV-03 ext | Overlay shows enemy counts, wave state, path rows; read-only | unit | `-gselect=test_debug_overlay_night_sections.gd` | Wave 0 |

### Sampling Rate
- **Per task commit:** `bash tools/test.sh -gdir=res://tests/unit` (about 16 s now; keep new unit tests pure-sim and fast) plus the single new file.
- **Per wave merge:** `bash tools/test.sh` (full, about 134 s in Phase 1) + `bash tools/lint.sh` + `bash tools/replay.sh --scenario=smoke --twice`.
- **Phase gate:** full suite green, lint clean, replay double-run green and golden matching, new screenshots captured and non-blank, balance report generated; then `/gsd-verify-work` with the owner's one-or-two-run sign-off.

### Wave 0 Gaps
- [ ] `tests/unit/test_sim_rules_guard.gd`, `test_sim_rng.gd`, `test_sim_clock.gd` — DR rules before combat code
- [ ] `tests/unit/test_night_data_contract.gd`, `test_wave_schedule.gd`
- [ ] `tests/unit/test_enemy_targeting.gd`, `test_tower_combat.gd`, `test_king_combat.gd`, `test_king_respawn.gd`, `test_building_damage.gd`, `test_dawn_rebuild.gd`
- [ ] `tests/integration/test_night_loop.gd`, `test_run_outcomes.gd`, `test_determinism.gd`; `tests/golden/`
- [ ] `E2eSupport.waveless_prototype_map()` helper and migration of the Phase 1 placeholder-night tests (list in Pitfall 2)
- [ ] Update `tests/support/sim_signals.gd` with every new signal
- [ ] `tools/replay/*`, `tools/replay.sh`, `tools/playtest.sh`; CI step in `.github/workflows/ci.yml`
- [ ] No framework install needed.

Manual-only (justified): owner's feel judgment of tension, readability and gold trade-offs at the gate (D-18); readability of night visuals is checked through screenshots plus the owner.

## Security Domain

`security_enforcement` is enabled (ASVS level 1, block on high). This is an offline single-player game; the realistic surface is the new CLI tools, data files and CI.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | no accounts or network |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | CLI args allowlisted and parsed (`--scenario` from a fixed list, `--seed` via `is_valid_int`, `--out` confined to `build/`); `MapConfig.validate()` extended with caps on counts/delays; no runtime loading of user-supplied `.tres`/JSON |
| V6 Cryptography | no | `sha256_text` is an integrity digest for tests, not a security control |
| V12 Files | yes | replay/playtest outputs only under `build/` (git-ignored, excluded from export); goldens are repo files |
| V14 Configuration | yes | CI keeps `permissions: contents: read`, SHA-pinned actions, no secrets; `tools/*` stays excluded from exports |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `--out=` writing outside the project | Tampering | Resolve and require a path under `build/`; reject otherwise |
| Unbounded loops or spawn counts from bad data (hung CLI or game) | DoS | `max_ticks`, per-night enemy cap in `validate()`, `timeout` in `tools/replay.sh` |
| Debug overlay and path gizmo shipping in release | Information disclosure (low) | Already accepted for the overlay (T-01-15, read-only); revisit gating before Phase 13 |
| Results "Quit" or "Play again" misuse in tests | n/a | Test handler signals, never call `quit()` in GUT |
| New third-party art without license record | Legal | ASSETS.md + `attribution.json` + `test_attribution_log` (only if the owner approves a pack) |

## Sources

### Primary (HIGH confidence)
- In-repo files read this session (cited with paths above): `simulation/run/run_manager.gd`, `run_context.gd`, `simulation/buildings/*`, `simulation/defs/*`, `simulation/events/sim_events.gd`, `simulation/commands/*`, `data/**/*.tres`, `presentation/map/map_root.gd`, `prototype_map.tscn`, `presentation/buildings/building_views.gd`, `presentation/king/*`, `presentation/camera/camera_rig.gd`, `presentation/environment/day_night_lighting.gd`, `ui/overlay/*`, `ui/hud/*`, `input/*`, `tools/*.sh`, `tools/screenshot/*`, `tools/sandbox/hold_pacing_sandbox.gd`, `tests/**` samples, `.gutconfig.json`, `.gdlintrc`, `export_presets.cfg`, `.github/workflows/ci.yml`, `project.godot`, planning docs (CONTEXT, STATE, REQUIREMENTS, research/ARCHITECTURE, FEATURES, PITFALLS).
- Engine probes run this session on 4.7.2-stable (scratch scripts outside the repo): RNG sequence, dictionary order, int overflow, Vector2 float32, unstable sort, global randi, physics ticks, SceneTree CLI args/exit code, script-error exit code, 40-enemy tick cost, seed mixing.
- https://docs.godotengine.org/en/stable/classes/class_array.html — sort not stable; `shuffle`/`pick_random` use the global seed.
- https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html — PCG32 implementation detail; seed/state; no avalanche.

### Secondary (MEDIUM confidence)
- https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html — `velocity_computed` emitted every update; no determinism guarantee stated.
- https://github.com/godot-jolt/godot-jolt (via web search) — Godot Jolt disclaims determinism guarantees.
- https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0 (via web search) — optional CC0 enemy models.

### Tertiary (LOW confidence)
- Reasoned platform floating-point claims (A1, A3), starter balance numbers (A4), camera footprint arithmetic (A5).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - nothing new; versions run this session.
- Determinism rules: HIGH for same-binary replay (probed); MEDIUM for cross-platform identity (assumption with mitigation).
- Architecture/integration: HIGH - based on reading every file the phase extends.
- Pathing/targeting recommendation: HIGH for correctness and Phase 4 seams; MEDIUM for feel (tuned by harness and owner).
- Balance numbers: LOW (starter values only).
- Pitfalls: HIGH - most are observed in the existing code or tests.

**Research date:** 2026-10-03
**Valid until:** 2026-11-02 (engine and tooling pinned; repo state is the moving part, re-check if Phase 1 follow-up fixes land first)
