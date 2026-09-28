# Architecture Research

**Domain:** Thronefall-like minimalist low-poly 3D strategy / tower-defense / day-night base-defense game (Windows PC)
**Researched:** 2026-09-28
**Confidence:** MEDIUM-HIGH (core patterns are well-established game-architecture practice, verified against current Godot 4 docs/community sources; Unity 6 notes are secondary since Godot is the likely engine per stack research; some numeric performance claims are MEDIUM confidence — validate empirically once vertical slice exists)

## Standard Architecture

### System Overview

Games in this genre (Thronefall, Kingdom Rush, Kingdom Two Crowns, Bad North) split cleanly into a **simulation layer** (deterministic-ish game rules, no rendering awareness) and a **presentation layer** (rendering, camera, VFX, audio, UI) connected by an **event/signal bus**. This split is what makes headless testing possible.

```
┌──────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION LAYER                          │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────────────┐ │
│  │    HUD     │  │  3D Scene  │  │   Audio    │  │  Camera / Input    │ │
│  │  (Control) │  │ (meshes,   │  │  (SFX bus) │  │  Picking            │ │
│  │            │  │  MultiMesh)│  │            │  │                     │ │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └──────────┬──────────┘ │
│        │  listens to    │  listens to   │  listens to        │ raw input  │
├────────┴────────────────┴───────────────┴─────────────────────┴─────────┤
│                          EVENT / SIGNAL BUS                              │
│   gold_changed · building_built · unit_spawned · unit_died · night_start │
│   wave_spawned · king_hit · building_destroyed · dawn_payout · game_over │
├────────────────────────────────────────────────────────────────────────┤
│                             SIMULATION LAYER                             │
│ ┌────────────┐ ┌───────────┐ ┌────────────┐ ┌───────────┐ ┌───────────┐ │
│ │ RunManager │ │  Economy  │ │  Buildings │ │   Units/   │ │  Enemies/ │ │
│ │ (state     │ │  (gold,   │ │  (build    │ │  Squads    │ │  Waves/   │ │
│ │  machine)  │ │  income)  │ │  spots,    │ │  (command, │ │  Spawner  │ │
│ │            │ │           │ │  upgrades) │ │  AI)       │ │           │ │
│ └────────────┘ └───────────┘ └────────────┘ └────────────┘ └───────────┘ │
│ ┌────────────┐ ┌───────────┐ ┌────────────┐ ┌───────────┐ ┌───────────┐ │
│ │   King     │ │  Combat/  │ │  Health &  │ │  Perks &   │ │  Scoring  │ │
│ │ Controller │ │  Targeting│ │  Destruct- │ │  Mutators  │ │           │ │
│ │ + Weapons  │ │/Projectile│ │  ion       │ │ (modifiers)│ │           │ │
│ └────────────┘ └───────────┘ └────────────┘ └───────────┘ └───────────┘ │
├────────────────────────────────────────────────────────────────────────┤
│                             DATA LAYER (read-only at runtime)            │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐  │
│  │ Building   │ │ Unit/Enemy│ │  Wave      │ │ Perk/     │ │  Map      │  │
│  │ Defs       │ │ Stat Defs │ │  Tables    │ │ Mutator   │ │  Configs  │  │
│  │ (Resource) │ │(Resource) │ │(Resource)  │ │ Defs      │ │(Resource) │  │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘ └───────────┘  │
├────────────────────────────────────────────────────────────────────────┤
│                        META / PERSISTENCE LAYER                          │
│        SaveGame (unlocks, XP, high scores) — JSON/ConfigFile on disk     │
└────────────────────────────────────────────────────────────────────────┘
```

**The critical architectural decision for this project:** the simulation layer must be runnable with zero rendering — no `Node3D`/`MeshInstance3D` required to resolve "who took damage, who died, what gold was earned, did the run end." That is what lets an AI coding agent (no eyes on screen) run a night's combat in a script/headless test and assert on numbers/logs instead of pixels.

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **RunManager / GameStateMachine** | Owns top-level state (boot→menu→loadout→run→results) and day/night/dawn sub-states; the only thing allowed to trigger phase transitions | Autoload/singleton (Godot) or persistent manager scene; explicit enum-based FSM, not scattered booleans |
| **Economy** | Tracks gold, applies dawn income from surviving buildings, validates spend requests | Plain class/Node holding `int gold`; emits `gold_changed(amount)` |
| **BuildSpot / BuildingSystem** | Owns fixed build-spot slots per map, current building+tier per spot, upgrade-tree branching, build/upgrade validation & cost | Each build spot is a data record (spot id, position, current building id, tier) + a `BuildingDef` resource graph describing upgrade branches |
| **KingController** | WASD movement, HP, knockout/respawn timer, equips one weapon (passive auto-attack + active ability on cooldown) | CharacterBody3D (physics-driven, singular — not batched, since it's one entity with player input) |
| **Weapon system** | Defines passive attack pattern + active ability behavior, damage, cooldowns; swappable per weapon definition | Strategy pattern: `WeaponDef` resource + a small set of weapon "behavior scripts" referenced by id, not one script per weapon class exploding via inheritance |
| **Unit/Squad system** | Spawns troops from military buildings, holds squad membership, executes player commands (select/rally/hold) and autonomous combat AI when idle | Data-oriented: units are lightweight structs/records processed in a manager, not one heavyweight Node per unit (see Unit Movement & AI at Scale) |
| **Enemy Spawner + Wave defs** | Reads a `WaveDef` (list of spawn events: enemy type, count, spawn point, delay) for the current night and executes it on a timeline | A `WaveTimeline` resource per map per night; spawner is a simple event-driven scheduler, not "AI" |
| **Targeting/Combat/Projectiles** | Resolves who attacks whom, applies damage, spawns/moves projectiles, resolves hits | Shared logic used by king, units, enemies, and towers alike — one `CombatResolver`, not four separate combat systems |
| **Health & Destruction/Restoration** | HP tracking, death/destruction events, dawn-time restoration of destroyed buildings | Component attached to any damageable entity (building, unit, enemy, king); `RestorationService` runs at dawn transition |
| **Perks & Mutators** | Stat modifiers applied at run start (perks chosen in loadout) or globally (mutators); pure data + modifier stack, no bespoke code per perk where avoidable | `StatModifier` resources applied to a `ModifiableStats` container (see Stat/Modifier System below) |
| **Scoring** | Accumulates score events (gold earned, waves survived, night completed, mutator multipliers) into a run score; persists high score at run end | Listens to bus events; simple accumulator, decoupled from every other system |
| **Meta-progression + Persistence** | Per-map XP/level, unlocked weapons/perks, high scores; save/load to disk | `SaveGame` resource serialized to JSON (or Godot's `ConfigFile`) on disk in user:// |
| **UI/HUD layer** | Renders gold, day/night counter, build costs, upgrade choice popups, unit selection box, results screen | Pure presentation; reads state via bus signals + polling accessors, never mutates simulation directly except by issuing *commands* (e.g. "player wants to build X at spot Y") that the simulation validates |
| **Input layer** | Keyboard movement, mouse picking of build spots/units (raycast or 2D screen-space box select), translates raw input into simulation-facing intents | Thin translation layer: `MoveIntent`, `BuildIntent(spot_id, building_id)`, `SelectUnitsIntent(ids)`, `RallyIntent(position)` — never lets input code touch simulation internals directly, always through a Command/Intent API |
| **Audio (SFX) layer** | Plays one-shot SFX in reaction to bus events (hit, building placed, coin, UI click, night start, dawn) | Listens to the same event bus as UI; zero simulation knowledge, purely reactive |

## Recommended Project Structure

Godot-flavored (per likely engine choice; GDScript file extensions shown, but the folder shape is engine-agnostic — Unity equivalents noted inline). Adjust `res://` prefix away if Unity is chosen.

```
project/
├── data/                          # Resource (.tres) definitions — pure data, no logic
│   ├── buildings/                 # BuildingDef.tres per building, incl. upgrade tree refs
│   ├── units/                     # UnitDef.tres (friendly troop stats)
│   ├── enemies/                   # EnemyDef.tres (enemy stats, movement type, AI archetype)
│   ├── weapons/                   # WeaponDef.tres (king weapons: passive + active)
│   ├── perks/                     # PerkDef.tres (StatModifier bundles)
│   ├── mutators/                  # MutatorDef.tres (StatModifier bundles + score multiplier)
│   ├── waves/                     # WaveDef.tres per map per night (spawn timeline)
│   └── maps/                      # MapConfig.tres (build spot layout, spawn points, night count)
├── simulation/                    # Headless-safe game logic — NO Node3D/rendering deps
│   ├── run/                       # RunManager (state machine), RunContext (current run state)
│   ├── economy/                   # Economy, income calculation
│   ├── buildings/                 # BuildSpot, BuildingInstance, upgrade resolution
│   ├── combat/                    # CombatResolver, TargetingService, ProjectileSim (data, not visuals)
│   ├── units/                     # UnitManager (data-oriented pool), SquadCommand
│   ├── enemies/                   # SpawnScheduler, EnemyManager
│   ├── stats/                     # ModifiableStats, StatModifier, ModifierStack
│   ├── health/                    # HealthComponent, DestructionService, RestorationService
│   ├── scoring/                   # ScoreTracker
│   └── events/                    # EventBus (signal definitions / typed event structs)
├── presentation/                  # Rendering, VFX, camera — reacts to events, reads sim state
│   ├── scenes/                    # 3D scenes per map, king, buildings, units, enemies visuals
│   ├── vfx/                       # Particle/impact effects
│   └── camera/                    # Camera rig, follow/pan logic
├── ui/                            # HUD, menus, loadout screen, results screen
│   ├── hud/
│   ├── menus/
│   └── components/                # Reusable UI widgets (button, tooltip, health bar)
├── input/                         # Raw input → Intent translation (mouse picking, WASD, box select)
├── audio/                         # SFX bus, event-reactive SFX player
├── meta/                          # SaveGame resource, persistence read/write, unlock logic
├── autoload/ (Godot) | Bootstrap/ (Unity)  # Singletons: EventBus, RunManager, SaveManager, GameStateMachine
├── tests/                         # Headless test suite (GUT/GdUnit4 for Godot; NUnit/Unity Test Framework for Unity)
│   ├── unit/                      # Pure logic tests: stat stacking, upgrade validation, targeting math
│   ├── integration/                # Full night simulation: spawn wave → resolve combat → assert outcome
│   └── fixtures/                   # Small test-only MapConfig/WaveDef resources
└── tools/                         # Editor tooling: debug overlays, headless screenshot capture script
```

### Structure Rationale

- **`data/` is separated from `simulation/` and `presentation/`:** designers (or the AI agent) add a building/enemy/wave/perk by adding a `.tres` file, never by touching code. This is what makes content "cheap to add."
- **`simulation/` has a hard rule: no dependency on `Node3D`, `MeshInstance3D`, `AnimationPlayer`, or any rendering API.** It may depend on Godot's core types (Vector3, math) but must be testable by instantiating scripts/objects directly in a headless test, not by loading a 3D scene. This is the single most important structural decision for AI-agent testability.
- **`presentation/` only reads simulation state and event bus signals; it never mutates simulation state directly.** Visual entities (a building's mesh, a unit's model) hold a reference to their simulation-layer counterpart (id or object) and sync visuals from it each frame/on-event — never the reverse.
- **`input/` exists as a boundary layer so mouse-picking (which needs a Camera3D and viewport, i.e. presentation-adjacent) never lets the *simulation* assume a screen exists.** Input translates raw device state into intents that are just data (structs/dictionaries), which the simulation validates and applies. This also means intents are trivially fabricated in tests without any input hardware.
- **`tests/integration/` is the payoff:** a test can build a `MapConfig` fixture with a couple of build spots and a `WaveDef` with a handful of enemies, spin up `RunManager` + subsystems with no scene tree, advance to night, tick simulation N times, and assert final gold/HP/survivors — all without a window, camera, or GPU.

## Architectural Patterns

### Pattern 1: Explicit top-level state machine with nested day/night sub-state

**What:** A single `RunManager` (or `GameStateMachine`) owns an enum of top-level states — `Boot → MainMenu → MapSelect → Loadout → InRun → Results` — and, while `InRun`, a nested enum — `Day → NightTransition → Night → Dawn → (loop or GameOver)`. Only this manager may change state; everything else reacts to `state_changed` / `phase_changed` signals.

**When to use:** Always, for this genre. Thronefall's whole design (telegraphed spawns during day, player-triggered night start, dawn payout/restoration) *is* this state machine. Get it right first — it's Phase 1 of the roadmap by necessity.

**Trade-offs:** Slightly more boilerplate than "just use booleans," but eliminates an entire class of bugs (build actions accepted mid-combat, dawn payout firing twice, pause during a transition animation) that are exactly the kind of thing hard to catch without visually watching the game. An explicit FSM is also trivially unit-testable: assert `state == Night` after calling `start_night()`, assert it rejects `start_night()` again while already `Night`.

**Example (Godot-flavored pseudocode):**
```gdscript
enum RunPhase { DAY, NIGHT_TRANSITION, NIGHT, DAWN, GAME_OVER, VICTORY }

class_name RunManager
extends Node  # or plain RefCounted for pure headless use

var phase: RunPhase = RunPhase.DAY
signal phase_changed(old_phase, new_phase)

func start_night() -> bool:
    if phase != RunPhase.DAY:
        return false  # reject invalid transition — testable
    _set_phase(RunPhase.NIGHT_TRANSITION)
    wave_spawner.begin(current_wave_def)
    _set_phase(RunPhase.NIGHT)
    return true

func _on_all_enemies_cleared():
    if phase == RunPhase.NIGHT:
        _set_phase(RunPhase.DAWN)
        economy.apply_dawn_income(buildings.surviving_economic_buildings())
        buildings.restore_destroyed()
        _set_phase(RunPhase.DAY)

func _set_phase(p):
    var old = phase
    phase = p
    phase_changed.emit(old, p)
```

### Pattern 2: Data-driven definitions as Resources (Godot) / ScriptableObjects (Unity), referenced by id

**What:** Every piece of content — building, upgrade tier, unit, enemy, weapon, perk, mutator, wave, map — is a data resource, not a script subclass. Behavior differences are expressed through small enums/strategy references *inside* the data (e.g. `AttackPattern.MELEE_SWING` vs `AttackPattern.PROJECTILE`), not through one GDScript/C# class per content item.

**When to use:** Always for content in this genre — Thronefall itself has 50+ perks, 9 weapons, dozens of building tiers; that volume only stays manageable if adding one is "author a `.tres`/`.asset` file," not "write a new script and wire it into five systems."

**Trade-offs:** Requires more upfront design of a generic-enough behavior vocabulary (attack patterns, targeting rules, modifier types) so most content fits without new code. Occasionally a genuinely unique mechanic (a boss ability, a unique perk like "gold doubles on odd nights") needs bespoke code — solve this with a small **behavior id → script** lookup table (strategy pattern) rather than abandoning the data-driven approach.

**Godot specifics (verified):** `Resource` is Godot's direct analog to Unity's `ScriptableObject` — a serializable data container loaded once and shared by reference (flyweight). `.tres` (text) is git-diffable and preferred during development; export to `.res` (binary) for the shipped build. This text-based format is a major win for an AI coding agent: it can read and hand-edit `.tres` files directly, unlike Unity's YAML `.asset` files which are technically diffable but far less ergonomic to hand-author.

**Example:**
```gdscript
# data/buildings/archery_range.tres (conceptual — actual .tres is serialized)
extends Resource
class_name BuildingDef

@export var id: StringName = "archery_range"
@export var display_name: String = "Archery Range"
@export var base_cost: int = 40
@export var category: BuildingCategory = BuildingCategory.MILITARY
@export var upgrade_tiers: Array[UpgradeTier]  # branching choices per tier
@export var spawns_unit: UnitDef                 # if military
```

### Pattern 3: Additive-then-multiplicative stat modifier stack (perks/mutators/upgrades)

**What:** Every modifiable numeric stat (king damage, unit HP, gold income, enemy speed, etc.) is represented not as a raw number but as a **base value + list of active modifiers**, recomputed on demand or cached and invalidated on modifier change. Standard RPG/roguelite convention (Diablo-style, Vampire Survivors-style, Slay the Spire-style) resolves in this order:

1. Sum all **flat/additive** modifiers, add to base.
2. Sum all **percentage-additive** modifiers (perk A +10% and perk B +15% become +25%, not +10% then +15% compounded), multiply the result once.
3. Apply any **multiplicative** modifiers (rare — usually reserved for mutators like "enemies deal 2x damage") as separate sequential multiplications.

`final = (base + sum(flat)) * (1 + sum(percent_additive)) * product(multiplicative)`

**When to use:** Any time perks, mutators, and building/weapon upgrades all need to stack predictably on the same stat without special-casing every combination. This is essential for this project since perks + mutators + weapon upgrades all touch overlapping stats (damage, HP, gold, speed).

**Trade-offs:** Slightly more indirection than `unit.damage += 5`, but it is what makes the perk/mutator system genuinely data-driven (a new perk is "add a `StatModifier` resource," not "add an `if` branch in combat code") and what makes stacking behavior *testable*: assert `compute_stat(base=10, modifiers=[flat(+2), percent(+50%)]) == 18`.

**Example:**
```gdscript
class_name StatModifier
extends Resource
enum ModType { FLAT, PERCENT_ADD, MULTIPLICATIVE }
@export var stat: StringName        # e.g. "king_damage"
@export var type: ModType
@export var value: float
@export var source: StringName      # perk/mutator id, for debug/removal

class_name ModifiableStats
extends RefCounted
var base_values: Dictionary = {}
var active_modifiers: Array[StatModifier] = []

func get_stat(stat_name: StringName) -> float:
    var base = base_values.get(stat_name, 0.0)
    var flat = 0.0
    var percent = 0.0
    var mult = 1.0
    for m in active_modifiers:
        if m.stat != stat_name: continue
        match m.type:
            StatModifier.ModType.FLAT: flat += m.value
            StatModifier.ModType.PERCENT_ADD: percent += m.value
            StatModifier.ModType.MULTIPLICATIVE: mult *= m.value
    return (base + flat) * (1.0 + percent) * mult
```
This is pure data manipulation with no engine dependency — trivially unit-testable headlessly.

### Pattern 4: Event/signal bus for cross-cutting concerns; direct references for tight ownership

**What:** Not every relationship should go through a bus. Use a **global event bus** (Godot: an autoload singleton emitting/relaying signals; Unity: a static C# event aggregator or a lightweight ScriptableObject-based event channel) specifically for **one-to-many, decoupled, "something happened" broadcasts** that UI/audio/scoring/meta-progression all care about: `gold_changed`, `building_destroyed`, `unit_died`, `night_started`, `dawn_payout`, `king_knocked_out`, `run_ended`. Use **direct references / composition** for tight one-to-one or parent-owns-child relationships: a `BuildSpot` directly owns its current `BuildingInstance`; a `Squad` directly owns its member unit ids; `CombatResolver` directly queries `UnitManager` for candidate targets (a hot-path query, not an event).

**When to use:** Bus for anything UI, audio, or scoring needs to react to. Direct calls/queries for hot-path per-frame logic (targeting, movement) where event overhead and indirection would hurt performance and clarity.

**Trade-offs:** A bus for *everything* (including per-frame combat queries) causes both performance problems (signal dispatch overhead at scale) and debugging difficulty (stack traces get murky, ordering becomes implicit). A bus for *nothing* re-couples UI/audio directly to simulation internals, which breaks headless testability (tests would need to stub out UI/audio nodes) and makes adding new reactive systems (e.g. a future analytics logger) require touching simulation code. The line: **state-changing broadcasts → bus; state-querying hot paths → direct calls.**

**Example:**
```gdscript
# autoload/EventBus.gd
extends Node
signal gold_changed(new_amount: int, delta: int)
signal building_destroyed(spot_id: StringName)
signal night_started(night_number: int)
signal dawn_payout(total_gold: int)
signal run_ended(victory: bool, score: int)

# audio/SfxReactor.gd — presentation layer, zero simulation knowledge
func _ready():
    EventBus.building_destroyed.connect(_on_building_destroyed)
func _on_building_destroyed(_spot_id):
    sfx_player.play("building_collapse")
```

### Pattern 5: Data-oriented unit management at scale (not one Node per unit)

**What:** For friendly troops and enemies (hundreds on screen), avoid one heavyweight scene-tree node (`CharacterBody3D` with physics + `AnimationPlayer` + collision) per agent. Instead: unit **data** lives in flat arrays/structs managed by a central `UnitManager`/`EnemyManager` (positions, velocities, HP, target id, state enum), processed in batched loops; unit **visuals** are drawn via `MultiMeshInstance3D` (Godot) with per-instance transform updates written from the manager, and only the small subset of "visually distinct" needs (king, maybe elites/bosses) get individual scene nodes.

**When to use:** As soon as unit counts plausibly exceed ~50 on screen simultaneously — which this project will regularly hit (troops + multiple enemy waves + projectiles). Verified: Godot's `CharacterBody3D` is built for a handful of player-driven characters, not hundreds of simultaneously-ticking physics bodies; community consensus and documented practice is that performance degrades sharply past roughly 50 such nodes, while `MultiMeshInstance3D` can render thousands of instances in a single draw call because it is GPU-instanced. (Source: Godot official "Optimization using MultiMeshes" docs; community write-ups on CharacterBody3D vs MultiMesh scaling.)

**Trade-offs:** MultiMesh gives up per-instance frustum culling (the whole MultiMesh is culled as one block) and can only draw one mesh per MultiMesh (so group by unit type/silhouette, one MultiMesh per enemy/unit archetype). Movement, collision avoidance, and targeting must be done manually in code (via `NavigationServer3D`/flow fields queried directly, not `NavigationAgent3D` nodes, and via manual sphere/AABB overlap or spatial hashing instead of the physics engine) rather than "for free" via physics nodes. This is a deliberate complexity trade: it is *more* code but the only path to hundreds of units at 60fps on modest hardware (project's stated GTX 970-class target).

**Practical scale plan for this project:**
- **King:** single `CharacterBody3D`, full physics/animation — it's one entity, deserves the cost.
- **Friendly units + enemies:** data-oriented manager + `MultiMeshInstance3D` per archetype, custom movement/avoidance, `Area3D`/manual sphere overlap only for interaction triggers where unavoidable (e.g. king melee range) — kept sparse.
- **Projectiles:** always pooled + MultiMesh or even simpler (a lot of tower-defense projectiles can be pure raycast/instant-resolve with a visual tracer, sidestepping physics entirely).

### Pattern 6: Flow-field or shared-grid pathfinding for crowd movement, not per-agent NavMesh queries

**What:** Rather than each of hundreds of units independently querying a navmesh (`NavigationAgent3D` per unit) for a path to a potentially-shared destination (the castle, a rally point, an enemy target zone), compute a **flow field** (a grid where each cell stores a direction toward the goal) once per goal-change and have all agents heading to that goal simply read their cell's direction each tick. Godot's `NavigationServer3D` can still be used to *generate* the underlying walkable grid/cost field (respecting walls/buildings as obstacles), but per-tick per-agent direction lookup is O(1) grid read, not O(path length) graph search.

**When to use:** Whenever many agents share a small number of destinations — which is exactly this game's shape: enemies converge on a handful of spawn→castle lanes, friendly units converge on a rally point or "hold" position. Verified via multiple independent sources (Red Blob Games' canonical "Flow Field Pathfinding for Tower Defense" article; RTS pathfinding case studies): flow fields have a higher one-time setup cost than a single A* query but scale far better than navmesh/A* once agent counts reach the hundreds, precisely because the cost is paid once per goal, not once per agent.

**Godot-specific caution (verified):** Godot's built-in RVO avoidance (`NavigationAgent3D` avoidance, tied to `NavigationServer3D`) has a documented, non-trivial performance cost per registered avoidance agent and known behavioral rough edges in non-trivial (non-flat, multi-navmesh) scenes — agents can stall or get pushed off-mesh in crowded situations. Recommendation: use `NavigationServer3D`/baked navmesh data only to *build* the flow field / walkable cost grid (a one-time or per-map-change bake), implement movement and light local separation (simple neighbor-repulsion, not full RVO) by hand in the unit manager, and reserve Godot's built-in per-agent avoidance nodes only if agent counts stay in the dozens (e.g. just the king plus a small squad), not for full crowds of hundreds.

**Trade-offs:** Flow fields are less precise for long, winding, rarely-traveled paths and re-baking on every wall/building change has a cost — but Thronefall-style maps have fixed build spots and fixed lanes, so the field only needs rebuilding when a wall/blocking building is built, destroyed, or restored (a low-frequency event, not per-frame), which fits this architecture well.

### Pattern 7: Command/Intent layer between input and simulation

**What:** Mouse picking (raycast against build spots, box-select over units) and keyboard input never call simulation mutators directly. Instead, input code produces small intent objects (`BuildIntent`, `RallyIntent`, `SelectUnitsIntent`, `ActivateAbilityIntent`) that a thin `CommandProcessor` validates against current simulation state and applies. UI buttons (e.g. "confirm upgrade choice") go through the same intent path as direct world clicks.

**When to use:** Always — this is what lets tests fabricate "the player clicked build spot 3 and chose tier-2 archery range" as a plain data object with no mouse, camera, or viewport involved, and assert on the resulting gold deduction and building state.

**Trade-offs:** One extra layer of indirection versus calling `buildings.build(spot)` straight from a click handler — worth it because it's also where validation (can afford it? spot empty? not mid-night?) naturally lives once, instead of being duplicated between UI-affordance checks and actual mutation.

## Data Flow

### Day-phase build flow

```
Mouse click (screen pos)
    ↓
[Input layer] raycast → build_spot_id
    ↓
[Input layer] emits BuildIntent(spot_id, building_choice)
    ↓
[CommandProcessor] validates: phase==DAY, spot empty/upgradable, gold sufficient
    ↓ (valid)
[BuildingSystem] creates/upgrades BuildingInstance from BuildingDef (data layer)
    ↓
[Economy] deducts gold → emits gold_changed
    ↓
[EventBus] building_built(spot_id, building_id)
    ↓
[Presentation] spawns/updates mesh at spot's world position
[Audio] plays "build" SFX
[UI] refreshes gold display, closes build menu
```

### Night-phase combat flow (per tick)

```
[RunManager] phase == NIGHT → simulation tick loop runs
    ↓
[SpawnScheduler] reads WaveDef timeline → spawns EnemyInstances (data layer → simulation)
    ↓
[UnitManager / EnemyManager] batched update:
    - flow-field lookup → desired velocity
    - light separation → adjusted velocity
    - integrate position
    ↓
[TargetingService] finds nearest valid target per agent (spatial hash query)
    ↓
[CombatResolver] resolves attacks in range → applies damage via HealthComponent
    ↓
[HealthComponent] HP <= 0 → emits unit_died / building_destroyed
    ↓
[EventBus] relays events
    ↓
[Presentation] plays death VFX, removes/updates MultiMesh instance
[Audio] plays hit/death SFX
[ScoreTracker] accumulates score-relevant events
    ↓
[RunManager] checks win condition (all enemies dead → DAWN) / loss condition (castle HP <= 0 → GAME_OVER)
```

### Dawn transition flow

```
[RunManager] phase → DAWN
    ↓
[BuildingSystem] queries surviving economic buildings
    ↓
[Economy] apply_dawn_income(surviving_buildings) → gold_changed
    ↓
[RestorationService] resets HP of destroyed buildings, re-flags them active
    ↓
[EventBus] dawn_payout(total), buildings_restored
    ↓
[Presentation] restored buildings fade back in; UI shows payout summary
    ↓
[RunManager] phase → DAY (next night) or, if final night survived, → VICTORY → Results
```

### Key data flows

1. **Definitions flow one-way, data layer → simulation, at load/spawn time only.** A `BuildingDef` or `EnemyDef` is read to *construct* a runtime instance (`BuildingInstance`, `EnemyInstance`); after that, the instance holds its own current-state numbers (current HP, current tier) and the definition is never mutated. This keeps data files reusable/shareable and side-effect-free.
2. **Simulation → presentation is signal/event-driven, never polled every frame for correctness** (though presentation may poll simulation state for smooth interpolation, e.g. reading a unit's current position each frame to update its MultiMesh transform — that's a read, not a mutation).
3. **Presentation/UI/input → simulation is always through the Intent/Command layer**, never direct mutation calls from a `_input()` handler or a UI button's `pressed` signal reaching into `BuildingSystem` internals.
4. **Meta-progression (SaveGame) is read once at run start** (to know unlocked weapons/perks for the loadout screen) **and written once at run end/results** (XP gained, high score, new unlocks) — not continuously synced during a run, minimizing save-corruption risk if the game crashes mid-night.

## Scaling Considerations

For a single-player Windows game, "scale" here means simulation load (unit/enemy/projectile counts, map count, content volume), not concurrent users.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Vertical slice (1 map, ~20-50 units/enemies) | Node-per-unit is fine even; MultiMesh optional. Focus entirely on getting the state machine, build/economy, and one full night-combat loop correct and headlessly testable. |
| Full v1 (3-5 maps, hundreds of units/enemies per night, 9 weapons, 50+ perks) | MultiMesh + data-oriented unit manager becomes necessary (per verified CharacterBody3D ceiling around ~50 nodes). Flow-field pathfinding replaces per-agent navmesh queries. Spatial hashing needed for targeting queries (avoid O(n²) nearest-enemy scans). Content volume (perks/weapons) must lean fully on the data-driven Resource pattern — no more "one perk = one script." |
| Hypothetical stretch (many maps, larger battles) | Not a v1 concern per project scope (3-5 maps, no procedural content), but if pursued: object pooling for projectiles/VFX becomes mandatory, tick-budget slicing (update only a subset of idle/off-screen agents per frame) for AI decision-making (movement/rendering still every frame), and LOD on MultiMesh mesh detail at distance. |

### Scaling Priorities

1. **First bottleneck: per-agent physics/scene nodes for units.** Verified as the first wall (CharacterBody3D-based crowds break down around ~50 agents). Fix: data-oriented `UnitManager`/`EnemyManager` + `MultiMeshInstance3D` rendering, decided *before* writing the wave/enemy-roster content (Phase 2-3 of roadmap), not retrofitted later — retrofitting a physics-node-per-unit prototype into data-oriented batched simulation is close to a rewrite.
2. **Second bottleneck: naive O(n²) targeting (every agent scanning every potential target each tick).** Fix: spatial hashing (uniform grid bucketing by position, updated incrementally) so "nearest enemy to this unit" is a small-bucket lookup, not a full scan. Needed once enemy+unit counts are in the hundreds simultaneously (a full night late in the campaign).
3. **Third-order concern: pathfinding re-bake cost when walls/buildings change.** Since build spots are fixed and wall placement only happens during the day phase (not during combat), flow-field rebaking can be done once per build action rather than every tick — a non-issue if the architecture respects the day/night phase boundary (another reason the state machine matters).

## Anti-Patterns

### Anti-Pattern 1: Coupling simulation logic to scene-tree nodes / MonoBehaviours

**What people do:** Put gold/HP/damage/AI logic directly in the same `Node3D`-derived script that also handles the mesh, animation, and camera-facing billboard for a unit — "it's just easier, everything's right there."
**Why it's wrong:** Makes the simulation impossible to run headlessly (instantiating game logic requires instantiating a full scene tree, which typically wants a `SceneTree`/viewport context) and impossible to unit-test in isolation (asserting "unit takes 5 damage, dies" requires spinning up rendering). This directly conflicts with the project's core testability requirement (AI agent, no screen).
**Do this instead:** Simulation-layer classes (in `simulation/`) are plain objects/`RefCounted` (Godot) or plain C# classes (Unity) holding only data + logic; presentation-layer nodes hold a reference *to* a simulation object and sync FROM it, never embed simulation state as their own fields.

### Anti-Pattern 2: One script/class per content item (per-perk, per-weapon, per-building scripts)

**What people do:** For each of 50 perks, write a `Perk_GoldRushScript.gd` with hardcoded logic; for each of 9 weapons, a full class hierarchy.
**Why it's wrong:** Content volume in this genre is exactly what Thronefall's own devs note as the danger — with 50+ perks and 9 weapons and dozens of building tiers, one-class-per-item means every new piece of content is a code change, which is slow, error-prone, and exactly what an AI agent burns the most tokens/turns on when it could instead be writing/adjusting data files.
**Do this instead:** Data-driven Resources (Pattern 2) with a constrained vocabulary of reusable behavior ids/strategies; reserve bespoke scripts only for the rare truly-unique mechanic, referenced by id from otherwise-standard data.

### Anti-Pattern 3: Bus-for-everything (including hot-path per-frame queries)

**What people do:** Route combat targeting, movement queries, or per-frame position updates through the global signal bus because "the bus pattern is good, use it everywhere."
**Why it's wrong:** Signal/event dispatch has real overhead at hundreds-of-agents-per-frame scale, and using events for synchronous "give me the answer right now" queries (as opposed to "notify everyone this happened") inverts the natural call direction and makes hot-path code harder to trace/profile/test.
**Do this instead:** Bus only for broadcast-style state-change notifications consumed by UI/audio/scoring/meta systems. Direct method calls/manager queries for anything inside the per-tick simulation hot path (targeting, movement, combat resolution).

### Anti-Pattern 4: Skipping the state machine ("just use a few booleans")

**What people do:** `is_night`, `is_paused`, `is_transitioning` booleans scattered across managers instead of one explicit enum-state owner.
**Why it's wrong:** Combinatorial bugs (paused during dawn transition, build accepted mid-night, dawn payout double-firing) are exactly the class of bug hardest to catch without visually watching play, and hardest to unit-test with boolean soup (tests must assert on multiple flags in combination rather than one clear state value).
**Do this instead:** Pattern 1 — one explicit state machine, one authority for transitions, everything else reacts.

### Anti-Pattern 5: Premature RVO/physics-based crowd avoidance

**What people do:** Reach for Godot's built-in `NavigationAgent3D` avoidance (RVO) or Unity's NavMesh Obstacle avoidance for every unit "because it's built in and free."
**Why it's wrong:** Verified: per-agent avoidance cost is non-trivial and known to misbehave (stalling, off-mesh pushes) once scenes aren't flat/simple or agent counts get into the hundreds — exactly this project's target scale on modest hardware.
**Do this instead:** Flow-field movement (Pattern 6) with simple hand-rolled local separation for hundreds of agents; reserve engine-native avoidance nodes, if used at all, for small elite/boss counts.

## Integration Points

### External Services

None — this is an offline, single-player, non-networked Windows game with no backend, no analytics service, and no Steam integration (explicitly out of scope). The only "external" surface is the local filesystem (save file) and CC0 asset files bundled with the build.

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Local filesystem (save data) | Godot `user://` directory (or Unity `Application.persistentDataPath`) with a JSON or engine-native serialized `SaveGame` resource | Write-on-results-screen only (see Data Flow #4); keep the save schema versioned (`save_version` field) from day one so future content additions don't break old saves |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Input ↔ Simulation | Intent/Command objects (Pattern 7) | Never direct mutation from input handlers |
| Simulation → UI/Audio/Presentation | Event bus signals (Pattern 4) | One-way notification; these layers never call back into simulation except via Intents |
| Simulation internal (Economy ↔ Buildings ↔ Combat ↔ Health) | Direct references/method calls within `simulation/` | Tight coupling is fine and expected *within* the simulation layer; the boundary that matters is simulation vs presentation, not sub-module purity within simulation |
| Data layer → Simulation | Read-only resource loading at construction time | Definitions never mutated at runtime; runtime state lives in instances, not defs |
| Meta/Persistence ↔ Simulation | RunManager reads SaveGame at loadout, writes at results | Not a live sync; see Data Flow #4 |
| Tests ↔ Simulation | Direct instantiation of simulation classes/scenes with fixture data, no scene tree/viewport required | This is the crux of the "AI agent verifies without seeing the screen" requirement — validated by Godot's documented headless (`--headless`) CLI mode plus a test runner (GUT or GdUnit4) that can run entirely from command line and return a process exit code |

## Testability & Debuggability Without a Screen (concrete strategy)

This directly answers the project's core constraint: an AI coding agent working via files + shell, no editor GUI, must be able to verify behavior.

1. **Headless simulation tests (primary verification method).** Because `simulation/` has zero rendering dependency, tests can: construct a `MapConfig` fixture (a couple of build spots, one lane), construct a `WaveDef` fixture (3 enemies), spin up `RunManager` + `Economy` + `BuildingSystem` + `UnitManager` + `EnemyManager` + `CombatResolver` with no scene tree, call `run.start_night()`, advance simulation ticks in a `for` loop (calling an explicit `tick(delta)` method — not relying on Godot's `_process`), and assert final state: `assert_eq(economy.gold, expected)`, `assert_true(all enemies dead)`, `assert_eq(run.phase, RunPhase.DAY)`. Verified: Godot 4 runs fully headlessly via `--headless` CLI flag (no display, no Xvfb needed), and both GUT (`bitwes/Gut`) and GdUnit4 support command-line test execution with a proper process exit code for pass/fail — both scriptable by an agent via Bash without any GUI. A documented gotcha: run a `--headless --import --quit` warm-up pass before tests so resources are registered, and consider `GODOT_DISABLE_LEAK_CHECKS=1` to avoid noisy false-negative exit codes from engine shutdown warnings.
2. **Deterministic tick-based simulation.** Give the simulation an explicit `tick(delta: float)` method driven by a test-controlled loop (not implicit `_process`/`_physics_process` engine callbacks) so tests can advance time in controlled, reproducible steps. Seed any randomness (enemy spawn jitter, damage variance if any) with an explicit RNG object passed in, not `randi()`/global RNG, so a test can assert exact outcomes.
3. **Structured logging as a secondary verification channel.** Emit structured (JSON-lines or clearly delimited) log events for major simulation events (`{"event":"building_destroyed","spot":"tower_1","night":3}`) that can be grepped/parsed from a log file after a manual playtest run, letting the agent infer what happened in a real play session it didn't watch.
4. **Debug overlay as a *visual* aid for human playtesting, not a substitute for automated tests.** A simple on-screen text overlay (state, gold, agent counts, FPS) helps a human confirm behavior quickly, but since the agent can't see it live, it's secondary to (1) and (3).
5. **Automated screenshot capture for spot-checks.** Godot can run headlessly and still render to an off-screen viewport; a small CLI-invokable script (in `tools/`) can load a specific scene/state, force a render, and call `get_viewport().get_texture().get_image().save_png(path)`, letting the agent capture a screenshot for its own later multimodal inspection (it can `Read` an image file) even though it can't watch gameplay live. Use sparingly — this is for visual/layout sanity checks (does the HUD overlap, does a building mesh look placed correctly), not for verifying game logic, which belongs in headless tests.
6. **Keep presentation bugs and simulation bugs separably diagnosable.** Because presentation only reads simulation state, a simulation test passing but the game "looking wrong" narrows the bug to the presentation layer immediately — valuable when the agent's only feedback loop for presentation issues is slower (human playtest reports or screenshots) than its feedback loop for logic issues (instant headless test runs).

## Suggested Build Order (dependencies between components)

This is the dependency-ordered backbone a vertical-slice-first roadmap should follow — build the day/night loop on one trivial map before any content breadth:

1. **State machine skeleton** (Pattern 1) — Boot→Menu→Run stub, Day↔Night↔Dawn phases with no real content, just transitions. Testable immediately: assert phase transitions happen/are rejected correctly.
2. **Data layer scaffolding** (Pattern 2) — define the `Resource`/data-file shapes for `BuildingDef`, `MapConfig`, `EnemyDef`, `WaveDef` even before they're fully featured; this shape rarely needs to change later once picked.
3. **One trivial map + build spots + Economy** — a `MapConfig` fixture with 2-3 build spots, gold tracking, one placeholder building (no upgrade tree yet). Enables build-phase testing headlessly.
4. **King controller (movement only, no combat yet)** — WASD movement, HP stub. Needed before night combat since the king participates in every night.
5. **Health/Destruction component + CombatResolver skeleton** — generic damage application usable by anything; test with synthetic "unit A deals 5 to unit B" before any real enemies exist.
6. **Minimal enemy + SpawnScheduler + WaveDef** — one enemy type, one trivial wave, spawned via the scheduler. This is the first point the full Day→Night→combat→Dawn loop can run end-to-end, even with placeholder art/one box-mesh enemy. **This is the vertical slice milestone** — the core loop proven on one map with zero content breadth, matching the project's "must already be fun on a single map with zero meta-progression" requirement.
7. **Stat/Modifier system** (Pattern 3) — introduce once there's at least one real number worth modifying (king damage or unit HP); build perks/mutators against this from the start rather than hardcoding then refactoring.
8. **Unit/Squad system + command intents** (Pattern 7) — friendly troop spawning, selection, rally/hold commands. Depends on CombatResolver and Health already existing.
9. **Data-oriented scale-up** (Patterns 5 & 6: MultiMesh, flow fields, spatial hashing) — once the loop is proven correct at small scale (step 6-8), convert unit/enemy representation to the batched/data-oriented approach before adding wave/roster content volume, so content doesn't have to be re-touched for a performance refactor later.
10. **Building upgrade trees, weapon system, perks, mutators, meta-progression/persistence, additional maps** — now purely additive content work layered on a proven, tested core, exactly the "cheap to add" state the architecture was built to reach.
11. **UI/HUD polish, audio layer, menus, results/scoring screen** — presentation-layer work that can proceed in parallel with later content steps once the event bus contract (which events exist, what data they carry) is stable from step 6 onward.

**Ordering rationale:** State machine and data shapes first because everything else depends on them and they're expensive to change later. King + combat + one enemy next because that's the smallest possible "full loop" — the single most valuable thing to get right and playtested before any content breadth, per the project's own core-value statement. Scale-up (MultiMesh/flow-fields) is deliberately sequenced *before* content breadth (step 9 before step 10) because retrofitting a data-oriented unit system after dozens of enemy/unit types and waves already exist is far more expensive than building content against the scalable system from the start.

## Sources

- [Godot Docs — Optimization using MultiMeshes](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html) — HIGH confidence, official docs
- [Godot Docs — Using MultiMeshInstance3D](https://docs.godotengine.org/en/stable/tutorials/3d/using_multi_mesh_instance.html) — HIGH confidence, official docs
- Godot 4 CharacterBody3D vs MultiMesh scaling community write-up (slashskill.com) — MEDIUM confidence, single community source corroborating official docs' framing; validate empirically for this project's exact unit complexity
- [Red Blob Games — Flow Field Pathfinding for Tower Defense](https://www.redblobgames.com/pathfinding/tower-defense/) — HIGH confidence, widely-cited canonical reference for this exact genre
- [jdxdev — RTS Pathfinding: Flowfields](https://www.jdxdev.com/blog/2020/05/03/flowfields/) — MEDIUM-HIGH confidence, practitioner case study corroborating Red Blob Games
- Godot navigation-avoidance proposals/issues (godot-proposals #4522, #8939) and NavigationAgent3D docs — MEDIUM confidence (GitHub issue discussion, not a formal doc claim, but consistent across multiple threads) — validate against the specific Godot 4.x version chosen by stack research, as avoidance behavior has shifted across 4.x releases
- [Medium — Resource-based architecture for Godot 4](https://medium.com/@sfmayke/resource-based-architecture-for-godot-4-25bd4b2d9018) and [GDQuest Glossary — Resource](https://school.gdquest.com/glossary/resource) — MEDIUM-HIGH confidence, corroborated by multiple independent sources describing Resource-as-ScriptableObject-equivalent and .tres-vs-.res convention
- Godot 4 headless CI testing sources: [saltares.com — Run automated tests for your Godot game on CI](https://saltares.com/run-automated-tests-for-your-godot-game-on-ci/), [bitwes/Gut GitHub](https://github.com/bitwes/Gut/issues/491), [gdUnit4Net discussion](https://github.com/godot-gdunit-labs/gdUnit4Net/discussions/350), [helpmetest.com — CI/CD for Godot Projects](https://helpmetest.com/blog/godot-ci-cd-testing/) — MEDIUM-HIGH confidence, multiple corroborating community sources plus official `--headless` CLI flag behavior; re-verify exact GUT/GdUnit4 CLI flags against whichever version is installed once stack research finalizes the engine version
- Thronefall developer background: [Wikipedia — Thronefall](https://en.wikipedia.org/wiki/Thronefall), [Game Developer — Mastering minimalism and layering complexity with strategy game Thronefall](https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall), [Game Dev Journey — Thronefall Unity Diaries](https://www.gamedevjourney.co.uk/home/developer-diaries/unity-diaries/thronefall) — MEDIUM confidence; confirms Thronefall itself is built in Unity with scene-per-level, MonoBehaviour-per-object structure, which is a data point for the Unity-idiom notes above but does not itself validate the Godot-specific recommendations in this document (those are separately sourced)
- General stat-modifier stacking convention (additive-then-multiplicative) reflects widely-documented RPG/roguelite design practice (Diablo-style itemization, common in Vampire Survivors-likes) — MEDIUM confidence as a design convention rather than a single authoritative source; treat as an established pattern to adapt, not a rule to follow blindly if playtesting reveals a different stacking order feels better for this specific game's power curve

---
*Architecture research for: Thronefall-like day-night base-defense strategy game*
*Researched: 2026-09-28*
