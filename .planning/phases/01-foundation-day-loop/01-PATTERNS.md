# Phase 1: Foundation & Day Loop - Pattern Map

**Mapped:** 2026-09-29
**Files analyzed:** 34 (scaffolding + gameplay files implied by CONTEXT.md/RESEARCH.md)
**Analogs found:** 0 / 34 (greenfield repository — no in-repo analogs exist)

## Greenfield Notice

This repository contains **no Godot project and no game source code** yet. Verified this
session: aside from `.git/`, `.claude/` (GSD tooling install, not a game-code analog), and
`.planning/` (docs), the repository root is empty. Every file the plans create in Phase 1 is a
first-of-its-kind file — there is nothing to copy an established in-repo pattern from.

Per the orchestrator note, I have **not** invented analogs and have **not** pointed at anything
under `.claude/` (JS tooling, wrong language/domain, gitignored/mirror-risk territory per the
tracked-source gate). Instead, every "Pattern Assignments" entry below points at the concrete,
already-locked reference material in `.planning/research/ARCHITECTURE.md` and this phase's own
`01-RESEARCH.md` (§"Code Examples", §"Recommended Project Structure", §"Architecture Patterns"),
which the planner should treat as the de facto analog source for Phase 1. All of these are
CITED/ASSUMED-tagged in RESEARCH.md, not verified-working code — the executor should expect
light iteration.

Because there is no code to classify against existing files, this document is organized as
**File Classification** (role/data-flow only, no analog) + **Reference Pattern Assignments**
(pointing to the RESEARCH.md/ARCHITECTURE.md excerpts each file should follow) + **Shared
Patterns** (cross-cutting conventions every file must obey) + **No Analog Found** (all files,
by definition, listed once for completeness).

## File Classification

| New File | Role | Data Flow | Reference Source (no in-repo analog) |
|----------|------|-----------|----------------------------------------|
| `autoload/EventBus.gd` | provider (signal bus) | event-driven | RESEARCH.md Architecture Diagram + ARCHITECTURE.md Pattern 4 |
| `autoload/RunManager.gd` | service (state machine) | event-driven | ARCHITECTURE.md Pattern 1; RESEARCH.md "Day/Night/Dawn loop" row |
| `simulation/economy/Economy.gd` | service | CRUD (gold ledger) | ARCHITECTURE.md `simulation/economy/`; RESEARCH.md Architectural Responsibility Map |
| `simulation/buildings/BuildingSystem.gd` | service | CRUD | ARCHITECTURE.md Pattern 7 (command/intent validation); RESEARCH.md diagram |
| `simulation/buildings/BuildSpot.gd` | model | CRUD | ARCHITECTURE.md Pattern 2 (data-driven definitions) |
| `simulation/buildings/BuildingInstance.gd` | model | CRUD | ARCHITECTURE.md Pattern 2 |
| `simulation/run/CommandProcessor.gd` | controller (intent validator) | request-response | ARCHITECTURE.md Pattern 7; RESEARCH.md Pitfall 4 |
| `data/buildings/house.tres`, `tower.tres` | config (Resource data) | CRUD | ARCHITECTURE.md Pattern 2; RESEARCH.md "Don't Hand-Roll" (stat data as `.tres`) |
| `data/maps/prototype_map.tres` | config (Resource data) | CRUD | ARCHITECTURE.md §"Recommended Project Structure" |
| `input/BuildHoldController.gd` | controller (input/intent) | event-driven | RESEARCH.md §"Code Examples" → "Hold-to-build coin drip" (full code, lines ~444-477) |
| `input/StartNightHoldController.gd` | controller (input/intent) | event-driven | Same pattern as `BuildHoldController.gd`, per D-11 |
| `input/BuildSpotProximity.gd` | controller (Area3D proximity) | event-driven | RESEARCH.md Architectural Responsibility Map, "Build-spot proximity" row |
| `presentation/scenes/king.tscn` + `King.gd` | component (CharacterBody3D controller) | request-response (per-frame input) | RESEARCH.md §"Code Examples" → "King movement with sprint" (full code, lines ~424-441) |
| `presentation/camera/CameraRig.gd` | component | transform (per-frame) | RESEARCH.md §"Code Examples" → "Fixed isometric-style follow camera" (full code, lines ~406-422) |
| `presentation/scenes/house.tscn`, `tower.tscn`, `prototype_map.tscn` | component | request-response | ARCHITECTURE.md §"Day-phase build flow"; RESEARCH.md diagram (presentation layer reacts to EventBus) |
| `ui/hud/GoldCounter.gd` | component (HUD) | event-driven (EventBus subscriber) | ARCHITECTURE.md Pattern 4; RESEARCH.md Architectural Responsibility Map "Debug overlay" row (same read-only-subscriber shape) |
| `ui/hud/SpotLabel.gd` | component (world-space label, D-07) | event-driven | RESEARCH.md phase_requirements row BLDG-02 |
| `ui/overlay/DebugOverlay.gd` | component | event-driven (read-only) | RESEARCH.md Pitfall 5 (must stay read-only); ARCHITECTURE.md Pattern 4 |
| `tests/unit/test_economy_gold.gd`, `test_dawn_income.gd`, `test_build_spot.gd`, `test_build_spot_affordability.gd`, `test_build_phase_guard.gd`, `test_king_movement_config.gd`, `test_debug_overlay_readonly.gd` | test | request-response (assertions) | RESEARCH.md §"Validation Architecture" → Phase Requirements → Test Map table (exact file names + one-line intent per test) |
| `tests/integration/test_build_flow.gd`, `test_upgrade_flow.gd`, `test_loop_gold_carryover.gd`, `test_build_hold_refund.gd` | test | request-response | Same table as above |
| `tools/screenshot/*.gd` (5 scripted scenes) | utility (headful capture script) | file-I/O | RESEARCH.md Pattern 2 "Screenshot capture requires a different CLI mode than tests" (full code, lines ~302-319) |
| `.github/workflows/ci.yml` | config (CI) | batch | RESEARCH.md Pattern 1 (GUT invocation), Pattern 3 (Windows export), Pitfalls 1-3 |
| `.gutconfig.json` | config | — | RESEARCH.md Pattern 1, full JSON example (lines ~289-299) |
| `export_presets.cfg` | config | — | RESEARCH.md Pattern 3 (disable `application/modify_resources`) |
| `project.godot` `[input]` section | config | — | RESEARCH.md Pattern 4, full example (lines ~334-352) |
| `.gitattributes`, `.gitignore` | config | — | RESEARCH.md Installation block (D-16); CONTEXT.md D-16 |
| `ASSETS.md` | config/docs (attribution log) | — | RESEARCH.md Standard Stack (Kenney packs), ART-02 |
| `setup_godot.{sh,ps1}` or similar | utility (tooling script) | file-I/O | CONTEXT.md D-14/D-15; RESEARCH.md Installation block + Open Question #2 |

## Reference Pattern Assignments

### King movement & camera (`presentation/scenes/king.tscn`, `King.gd`, `presentation/camera/CameraRig.gd`)

**Reference:** `01-RESEARCH.md` §"Code Examples" (both snippets are complete, not excerpts — copy in full and adapt):

```gdscript
class_name King
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_multiplier: float = 1.6  # Thronefall reference ratio per CONTEXT.md discretion note

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var speed := walk_speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    move_and_slide()
```

```gdscript
class_name CameraRig
extends Node3D

@export var target: Node3D
@export var follow_speed: float = 6.0
@export var offset: Vector3 = Vector3(0, 14, 10)

func _physics_process(delta: float) -> void:
    if target == null:
        return
    var desired: Vector3 = target.global_position + offset
    global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
    # Fixed angle — rotation is set once at scene setup, never touched here (KING-02: no rotation).
```

Both are LOW-MEDIUM confidence (original synthesis, not fetched from a single official doc) —
expect iteration once a real scene exists.

---

### Hold-to-build / hold-to-start-night (`input/BuildHoldController.gd`, `input/StartNightHoldController.gd`)

**Reference:** `01-RESEARCH.md` §"Code Examples" → "Hold-to-build coin drip" (full code, project-specific
synthesis, not externally verified):

```gdscript
class_name BuildHoldController
extends Node

var _active_spot_id: StringName = &""
var _coins_dripped: int = 0
var _total_cost: int = 0
var _drip_timer: float = 0.0
const DRIP_INTERVAL := 0.2  # seconds/coin, within CONTEXT.md's 0.15-0.3s discretion range

func _process(delta: float) -> void:
    if _active_spot_id == &"":
        return
    if not Input.is_action_pressed("action_build") or not _king_in_range(_active_spot_id):
        _cancel_and_refund()
        return
    _drip_timer += delta
    if _drip_timer >= DRIP_INTERVAL:
        _drip_timer = 0.0
        _coins_dripped += 1
        if _coins_dripped >= _total_cost:
            _complete_build()

func _complete_build() -> void:
    var intent := BuildIntent.new(_active_spot_id)
    CommandProcessor.submit(intent)  # single mutation point — simulation validates again here
    _reset_hold_state()

func _cancel_and_refund() -> void:
    # No simulation-layer gold was ever deducted (D-06) — this just clears input-layer UI state.
    _reset_hold_state()
```

**Critical rule from RESEARCH.md Pitfall 4:** `CommandProcessor` must re-validate
`phase == RunPhase.DAY` at both hold-start (affordance) and hold-completion (mutation gate) —
never trust the hold controller's own phase snapshot. Apply the identical timer/cancel/refund
shape to `StartNightHoldController.gd` per D-11 (dedicated action, same ephemeral-state
discipline, no partial state stored).

---

### Simulation layer (`Economy.gd`, `BuildingSystem.gd`, `RunManager.gd`, `CommandProcessor.gd`)

**Reference:** `01-RESEARCH.md` System Architecture Diagram (lines ~200-242) and Architectural
Responsibility Map table (lines ~114-126), backed by `.planning/research/ARCHITECTURE.md`
Patterns 1, 2, 4, 7 (locked, not re-litigated per CONTEXT.md). Key rules to copy into every
simulation-layer file:
- Simulation code must never import `Node3D`/scene-tree presentation types (Anti-Pattern 1).
- Only `RunManager` may change `RunPhase`; everything else reacts via `EventBus` signals
  (`gold_changed`, `building_built`, `night_started`, `dawn_payout`, ...).
- All mutation happens through one method per verb (`Economy.deduct()`,
  `Economy.apply_dawn_income()`, `BuildingSystem.build(spot_id)`) invoked only from
  `CommandProcessor`, never directly from UI/input.
- No partial-payment state is ever stored on a `BuildSpot` (D-06) — the hold controller owns
  that ephemerality, not the simulation model.

---

### Debug overlay (`ui/overlay/DebugOverlay.gd`)

**Reference:** RESEARCH.md Pitfall 5 (read-only-boundary requirement) — the overlay may only
call `EventBus` signal subscriptions and read-only getters (`RunManager.phase`, `Economy.gold`);
it must never import from `simulation/` for anything other than read access, and must never
expose a setter. Extensibility requirement (DEV-03, CONTEXT.md discretion): design the overlay's
data source as a small struct/dictionary so Phase 2 can add wave state and enemy paths without
restructuring it.

---

### Screenshot capture (`tools/screenshot/*.gd`)

**Reference:** RESEARCH.md Pattern 2 (full code, lines ~302-319):

```gdscript
await RenderingServer.frame_post_draw
var img := get_viewport().get_texture().get_image()
img.save_png("res://screenshots/day_overview.png")
```

Invoked via `xvfb-run --auto-servernum godot --path . --rendering-driver opengl3 --resolution
1280x720 res://tools/screenshot/day_overview.tscn --quit-after 60` — **never** under
`--headless` (Pitfall 1: silently produces black/empty PNGs). At minimum capture the 5 scenes
CONTEXT.md names: day overview, spot label, build in progress, dawn payout, overlay on.

---

### CI workflow (`.github/workflows/ci.yml`)

**Reference:** RESEARCH.md Patterns 1 and 3, and Pitfalls 1-3 (full detail, not reproduced here
to avoid duplication — planner/executor should read those sections directly). Three logically
separate jobs: (1) lint via gdtoolkit, (2) `--headless` GUT tests, (3) screenshot capture
(Xvfb + real rendering driver) and Windows export (`--export-release`, `modify_resources=false`
to avoid the Wine/rcedit dependency).

---

### GUT tests (`tests/unit/*.gd`, `tests/integration/*.gd`)

**Reference:** RESEARCH.md §"Validation Architecture" → "Phase Requirements → Test Map" table
(lines ~542-557) gives the exact file names and one-line intent for every required test. Use
`.gutconfig.json` (full JSON example, lines ~291-299) as the shared local/CI config.

## Shared Patterns

### Sim/presentation/data split (all simulation + presentation files)
**Source:** `.planning/research/ARCHITECTURE.md` Patterns 1-2 (locked), reinforced by
RESEARCH.md Anti-Patterns section.
**Apply to:** every file under `simulation/`, `presentation/`, `input/`, `ui/`.
Rule: simulation code is headless-testable with zero scene-tree dependency; presentation reads
simulation state only via `EventBus` signals or explicit read-only getters, never by importing
simulation internals for direct mutation.

### Event bus as the only cross-cutting notification channel
**Source:** RESEARCH.md diagram (`EventBus (autoload)` node in the architecture diagram).
**Apply to:** `RunManager.gd`, `Economy.gd`, `BuildingSystem.gd` (emitters); `ui/`,
`presentation/` (subscribers).

### Command/intent validation gate
**Source:** RESEARCH.md Pitfall 4 + Architectural Responsibility Map "Hold-to-build" row.
**Apply to:** `CommandProcessor.gd`, both hold controllers. Validate `RunPhase`, spot validity,
and affordability at both hold-start and hold-completion — never trust a cached snapshot.

### Data-driven numbers, never hardcoded constants
**Source:** RESEARCH.md "Don't Hand-Roll" table, row "Stat/cost data for buildings".
**Apply to:** `data/buildings/house.tres`, `tower.tres`, `data/maps/prototype_map.tres`, and any
script that reads costs/income/tiers — always via `.tres` `BuildingDef`/`UpgradeTier`
`Resource` references, never inline numeric constants in `.gd` files (required for D-09's
Phase-2-playtest-gate tuning).

## No Analog Found

Every file in this phase has no in-repo analog — the table below is the full file list for
completeness (role/data-flow already given in File Classification above; reason is identical
for all rows).

| File | Reason |
|------|--------|
| All 34 files listed above | Greenfield repository — repo root contains only `.git/`, `.claude/` (GSD tooling, wrong language/domain), and `.planning/` (docs) as of 2026-09-29. No Godot project or GDScript file exists yet to serve as an analog. Use the RESEARCH.md/ARCHITECTURE.md reference material cited above instead. |

## Metadata

**Analog search scope:** entire repository root (`find . -maxdepth 2`, excluding `.git`,
`.claude`, `.planning`) — confirmed empty this session, 2026-09-29.
**Files scanned:** 0 (no game source exists)
**Pattern extraction date:** 2026-09-29
