---
phase: 03-king-combat-troops
plan: 14
subsystem: presentation
tags: [godot, gdscript, king, health-bar, regeneration, gap-closure, tdd]
gap_closure: true
gap_ids: [G-03-4]

requires:
  - phase: 03-king-combat-troops
    provides: "03-04 KingState regeneration and SimEvents.king_healed(amount, hp, max_hp); KingWidget polling the simulation"
provides:
  - "King._on_king_healed: the floating HealthBar3D over the king follows every regeneration point and hides again at full health"
  - "A real-scene test that heals the shipped 50 hp king and pins bar, widget label and per-event bar ratio"
affects: [03-18]

actuals:
  tokens: 1636
  tasks: 2
  commits: 2

plan_head_before: 2bb71dd2f9677cbe2bd39b311d7eb68d141d3043
plan_head_after: ee21f6f863ea69542f765b058f2c79eb3cf092a4
commits: 2

tech-stack:
  added: []
  patterns:
    - "A scene test that must see every event connects its recorder after the node under test, so the node's own handler has already run when the recorder samples the node's state"

key-files:
  created: []
  modified:
    - presentation/king/king.gd
    - tests/e2e/test_king_knockout.gd

key-decisions:
  - "The handler passes the event's own hp and max_hp to HealthBar3D.set_health, exactly like _on_king_damaged; nothing under simulation/, HealthBar3D or KingWidget changed (the plan's prohibition holds)"
  - "The test's _spawn helper gained a king_health parameter (default the old 4, 0 keeps the shipped king) instead of a second spawn helper, so the four existing cases are untouched"

patterns-established:
  - "Regeneration waits in scene tests derive from KingDef.regen_delay_seconds and regen_fraction_per_second through SimClock, with a 3 s real-time slack"

requirements-completed: [KING-05, UI-01]

coverage:
  - id: D1
    description: "After every regeneration point the floating bar over the king shows the simulation's hp / max_hp, and the bottom-left widget label reads the same numbers"
    requirement: KING-05
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_knockout.gd#test_after_regeneration_the_king_bar_follows_each_heal_and_hides_at_full"
        status: pass
      - kind: other
        ref: "real-window probe (scratch): sim_ratio equals floating_bar_ratio on all ten heals, widget_bar_settled equal"
        status: pass
    human_judgment: false
  - id: D2
    description: "The floating bar hides again when regeneration brings the king back to full health"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_knockout.gd#test_after_regeneration_the_king_bar_follows_each_heal_and_hides_at_full"
        status: pass
      - kind: other
        ref: "real-window probe (scratch): heal#10 hp=50/50 floating_bar_visible=false"
        status: pass
    human_judgment: false
  - id: D3
    description: "Existing bar behaviour is unchanged: shows after a hit, hides at full health, knockout, respawn and the dawn payout still refresh it"
    requirement: UI-01
    verification:
      - kind: e2e
        ref: "tests/e2e/test_king_knockout.gd (the four earlier cases) and tests/e2e/test_king_widget.gd, tests/integration/test_king_ride.gd"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-13
status: complete
---

# Phase 3 Plan 14: King bar follows regeneration Summary

**The floating bar over the king now listens to king_healed, so it climbs with the HUD widget through every regeneration point and hides again at full health (G-03-4, review finding WR-01).**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-10-13T16:15:00Z
- **Tasks:** 2 (Task 1 as RED then GREEN commits, Task 2 verification only)
- **Files modified:** 2

## Accomplishments

- `King.bind_run` connects `ctx.events.king_healed` to the new `_on_king_healed(_amount, hp, max_hp)`, which calls `_health_bar.set_health(hp, max_hp)`; `HealthBar3D.should_show` hides the bar at full health. The class header doc now lists everything the bar follows.
- One new scene test in `tests/e2e/test_king_knockout.gd` (5 tests there now): the real map with the shipped 50 hp king, 10 damage through `ctx.king.take_damage`, a recorder connected after the king's own handler that stores the bar ratio at each `king_healed` event, then bar ratio equal to the simulation, the widget label equal to `"%d / %d"`, and at full health the bar hidden and the label `50 / 50`. All waits derive from the def (`regen_delay_seconds`, `regen_fraction_per_second`) via `SimClock`, plus 3 s of slack.
- Real-window confirmation of the fix on the shipped map (below).

## Real-window measurement (windowed Forward+, RTX 3060, fixed seed 1, shipped prototype map)

Pre-fix UAT p4 values for comparison: `sim_ratio=0.980 floating_bar_ratio=0.960 widget_bar=0.981`.

```
start max_hp=50 sim=50/50 floating_visible=false
hit sim_ratio=0.800 floating_bar_ratio=0.800 floating_bar_visible=true widget_label='50 / 50'
heal#1 hp=41/50 sim_ratio=0.820 floating_bar_ratio=0.820 floating_bar_visible=true widget_bar_settled=0.820 widget_label='41 / 50'
heal#2 hp=42/50 sim_ratio=0.840 floating_bar_ratio=0.840 floating_bar_visible=true widget_bar_settled=0.840 widget_label='42 / 50'
heal#3 hp=43/50 sim_ratio=0.860 floating_bar_ratio=0.860 floating_bar_visible=true widget_bar_settled=0.860 widget_label='43 / 50'
heal#4 hp=44/50 sim_ratio=0.880 floating_bar_ratio=0.880 floating_bar_visible=true widget_bar_settled=0.880 widget_label='44 / 50'
heal#5 hp=45/50 sim_ratio=0.900 floating_bar_ratio=0.900 floating_bar_visible=true widget_bar_settled=0.900 widget_label='45 / 50'
heal#6 hp=46/50 sim_ratio=0.920 floating_bar_ratio=0.920 floating_bar_visible=true widget_bar_settled=0.920 widget_label='46 / 50'
heal#7 hp=47/50 sim_ratio=0.940 floating_bar_ratio=0.940 floating_bar_visible=true widget_bar_settled=0.940 widget_label='47 / 50'
heal#8 hp=48/50 sim_ratio=0.960 floating_bar_ratio=0.960 floating_bar_visible=true widget_bar_settled=0.960 widget_label='48 / 50'
heal#9 hp=49/50 sim_ratio=0.980 floating_bar_ratio=0.980 floating_bar_visible=true widget_bar_settled=0.980 widget_label='49 / 50'
heal#10 hp=50/50 sim_ratio=1.000 floating_bar_ratio=1.000 floating_bar_visible=false widget_bar_settled=1.000 widget_label='50 / 50'
full sim_ratio=1.000 floating_bar_ratio=1.000 floating_bar_visible=false widget_bar=1.000 widget_label='50 / 50'
```

The widget value was sampled 0.18 s after each heal (after the 0.15 s tween). Heal 9 reads 0.980 / 0.980 / 0.980, where the UAT read 0.980 / 0.960 / 0.981. Screenshot at heal 3 (floating bar short of full, widget "43 / 50"): `C:/Users/burha/AppData/Local/Temp/claude/C--Users-burha-Desktop-Projects-Thronefall-like-Game/f8b6d77d-09df-4298-8835-f2870e4d8fc3/scratchpad/executor-03-14/heal_mid_regen.png` (outside the repository, session scratch).

## Task Commits

1. **Task 1 RED:** `cc6f2e0` (test) - failing regeneration case; failed on the fill-ratio assertion (bar stuck at 0.800 against 0.82, 0.84 ... 1.00) and the hide-at-full assertion, the other four cases passing, no script error
2. **Task 1 GREEN:** `ee21f6f` (fix) - `_on_king_healed` and its connection in `bind_run`
3. **Task 2:** no commit (verification only; the full suite needed no fix)

**Plan metadata:** the docs commit that carries this SUMMARY, STATE.md, ROADMAP.md and REQUIREMENTS.md.

## Verification

- `bash tools/test.sh -gselect=test_king_knockout.gd`: 5/5 tests, 52 asserts (RED run: 4 pass, 1 fail, 40/52 asserts)
- `bash tools/test.sh -gselect=test_king_widget.gd`: 14/14, 81 asserts; `-gselect=test_king_ride.gd`: 10/10, 22 asserts
- Full suite `bash tools/test.sh`: 148 scripts, 1378 tests, 1378 passing, 15461 asserts, 560.6 s, exit 0 (baseline 1377; +1 is the new test). The JUnit XML names the new test and `test_king_regen`.
- `bash tools/lint.sh`: 262 files left unchanged, no problems.
- Acceptance criteria: `king_healed.connect(_on_king_healed)` at king.gd:54, `func _on_king_healed(` at king.gd:103; the test name present and its waits derived from `regen_delay_seconds` and `regen_fraction_per_second`.

## Decisions Made

- The test's recorder connects after the king's own handler (signal connection order is call order), so each event's recorded bar ratio is the bar's state after the king reacted; every heal of the run is therefore checked, not only the first.
- The widget check is a bounded wait for `label.text == "hp / max"` of the current simulation, because the widget polls once per frame and a heal can land between its poll and the test's read; the bar check is exact and synchronous (the bar is set inside the event).

## Deviations from Plan

None - plan executed exactly as written. (The `_spawn` helper gained an optional parameter to keep the shipped king, which the plan names as "a spawn variant or a parameter".)

## Issues Encountered

None. The 03-REVIEW.md ledger row for WR-01 is left to the next code-review pass, as the plan specifies.

## Known Stubs

None.

## Threat Flags

None. `_on_king_healed` only reads the event's numbers and writes the HealthBar3D; no KingState writer is called and nothing under `simulation/` changed (T-03-23 mitigated).

## Self-Check: PASSED

- FOUND: presentation/king/king.gd, tests/e2e/test_king_knockout.gd, this SUMMARY
- FOUND commits: cc6f2e0, ee21f6f
- `git rev-list --count 2bb71dd..HEAD` = 2 at SUMMARY time, matching `commits: 2`

---
*Phase: 03-king-combat-troops*
*Completed: 2026-10-13*
