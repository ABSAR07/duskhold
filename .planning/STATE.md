---
gsd_state_version: "1.0"
current_phase: 01
current_phase_name: Foundation & Day Loop
status: verifying
stopped_at: Completed 01-12-PLAN.md
last_updated: "2026-10-02T07:29:47.315Z"
last_activity: 2026-10-02
last_activity_desc: Gap-closure plans 01-11 to 01-13 complete (UAT gaps G-01-3, G-01-4)
state_head: 9d2c0244e34092a31b1e833cba1328c5d220780a
progress:
  total_phases: 13
  completed_phases: 0
  total_plans: 13
  completed_plans: 13
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-28)

**Core value:** The day/night build-then-defend loop must feel as tight and satisfying as Thronefall's, with meaningful gold trade-offs by day and readable, tense defense by night. It must be fun on a single map with zero meta-progression.
**Current focus:** Phase 01 — Foundation & Day Loop

## Current Position

Phase: 01 (Foundation & Day Loop) — EXECUTING
Plan: 13 of 13
Status: Phase complete — ready for verification
Last activity: 2026-10-02 — Gap-closure plans 01-11 to 01-13 complete (UAT gaps G-01-3, G-01-4)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01 P01 | 2h 41m | 3 tasks | 279 files |
| Phase 01 P02 | ~4h (incl. gate wait) | 2 tasks | 33 files |
| Phase 01 P04 | 5 min | 2 tasks | 9 files |
| Phase 01 P03 | 71 min (incl. owner-decision wait) | 3 tasks | 5 files |
| Phase 01 P05 | 25 min | 2 tasks | 12 files |
| Phase 01 P06 | 14 min | 3 tasks | 21 files |
| Phase 01 P07 | ~35 min (continuation) | 3 tasks | 90 files |
| Phase 01 P08 | 5 min | 2 tasks | 7 files |
| Phase 01 P09 | 20 min | 3 tasks | 23 files |
| Phase 01 P10 | 19 min | 3 tasks | 10 files |
| Phase 01 P11 | 11 min | 2 tasks | 7 files |
| Phase 01 P13 | 7 min | 2 tasks | 7 files |
| Phase 01 P12 | 16 min | 2 tasks | 7 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Requirements]: Controls changed from the initial keyboard + mouse plan (click-to-build, mouse unit commands) to Thronefall's original scheme (owner decision, 2026-09-28). The king rides to a build spot and the player holds the action key to build or upgrade, units get hotkey commands (hold; follow the king — all or one unit type), gameplay is keyboard + gamepad, and the mouse is for menus only. Research docs carry an inline "Controls decision update" note wherever they described the old plan.
- [Roadmap]: The core-loop slice is split in two (owner feedback, 2026-09-29). Phase 1 covers Godot 4.7.2 scaffolding, the agent-verification tooling (GUT, lint, CI with Windows export, screenshots, debug overlay, asset log), and a playable day phase. Phase 2 adds nights, dawn, win/loss, and seeded replays, and it ends in the first human playtest gate.
- [Roadmap]: Phase 1 includes an enemy-free placeholder night between days so House income and gold carryover are verifiable. Phase 2 fills that same loop state machine with real nights instead of replacing it.
- [Roadmap]: Data-oriented scale-up (Phase 4) comes before content breadth (Phases 5–7)
- [Roadmap]: META-08 stat-modifier order lands in Phase 5 with the first buffs, and META-09 save versioning lands in Phase 9 with the first save; later phases extend both
- [Roadmap]: Scoring stabilizes in Phase 9 before mutators are tuned in Phase 10 (second playtest gate)
- [Roadmap]: Research buildings are isolated in Phase 12 as the designated scope cut; no other phase depends on them
- [Phase 01]: [01-01] Phase 1 work lands on branch gsd/phase-01-foundation-day-loop; master holds Task 1 only, owner merges later — Owner decision after the pre-commit protected-branch halt
- [Phase 01]: [01-01] Godot 4.7.2 runs self-contained (_sc_); only Windows export templates kept locally; untyped_declaration=2 enforced — Keeps editor data inside git-ignored .tools/ and enforces static typing at compile time
- [Phase 01]: [01-01] Rejected operations return values, not push_error — GUT 9.7 can count engine errors as test failures
- [Phase 01]: 01-02: RunManager.get_elapsed() and CommandProcessor.UNKNOWN_INTENT added; BuildingSystem.apply_next_tier returns null for unknown spot
- [Phase 01]: 01-02: not-day revalidation test writes RunManager._phase directly; plan 01-08 should switch to public start_night
- [Phase 01]: 01-02: use GUT wait_process_frames (wait_frames deprecated in 9.7.1); commit each .gd.uid with its script
- [Phase 01]: 01-04: CameraRig is a detached perspective rig (fov 40, offset (0,16,11), yaw 0); rotation written only once in bind_run, position follows via exp() smoothing — Fixed angle the player cannot rotate (KING-02); offset and follow_sharpness are exported for Phase 2 playtest tuning
- [Phase 01]: 01-04: KingDef acceleration 40 m/s^2 and turn_speed 12 rad/s are first-pass feel values; the plan's human-check (windowed keyboard + gamepad feel pass) is still outstanding — Plan only required > 0; values keep the sprint/walk distance ratio inside the 15% band
- [Phase 01]: [01-03] Owner published ABSAR07/duskhold (public) with only the phase branch gsd/phase-01-foundation-day-loop pushed; master and tags stay local. GitHub default branch is the phase branch until the owner switches it after merging — Owner decision at the blocking Task 2 checkpoint (D-13 one-way door); local absolute paths in tracked PLAN files accepted as-is
- [Phase 01]: [01-03] Pushes to origin need the gh login: git's stored credential is account absarfraz-tenx (403). Use git -c credential.helper= -c 'credential.helper=!gh auth git-credential' push, or owner runs gh auth setup-git — Avoids changing the owner's global git config without approval
- [Phase 01]: [01-03] Windows export uses application/modify_resources=false (no Wine/rcedit); a custom icon or version resource in a later phase will need rcedit — Phase 1 has no custom icon; Linux CI export verified green
- [Phase 01]: 01-05: MapConfig.validate() logs via RunContext push_error but never blocks construction; ride-time contract measures the farthest pair among spots, castle and king spawn (110 m, 22 s)
- [Phase 01]: 01-06: Hold start is edge-triggered and the is_build_allowed/radius checks run every frame ahead of any drip, so a denial fires once per press and no coin lands after the day ends
- [Phase 01]: 01-06: SpotLabelModel.affordable is true when gold covers the cost or a hold is under way, and always at max tier, so red never shows on a running hold or a finished building
- [Phase 01]: 01-07: Owner approved Kenney Castle Kit, Fantasy Town Kit, Mini Characters and the animated Quaternius horse (4b); horse recorded CC0-1.0 with the Quaternius QAL v1.0 wording quoted beside the Poly Pizza CC0 statement — Auditable provenance; obtained as CC0 and used inside a game, not redistributed standalone
- [Phase 01]: 01-07: Houses and castle keep are composed from kit pieces in text wrapper scenes; king is Kenney character-male-b plus a gold crown primitive on the Quaternius horse (bind pose) — Neither kit ships a complete house or keep and the pack has no crowned figure; animation and normalization deferred to Phase 8
- [Phase 01]: 01-08: debug overlay renders immediately on show then every 0.25 s; ships in all builds (T-01-15 accepted, revisit gating before Phase 13); extended via register_section
- [Phase 01]: 01-09: RunManager is the only phase writer (enforced by a source-scan test); Phase 2 replaces only _night_should_end and _apply_dawn_payout — Keeps one owner for the loop and gives Phase 2 two well-defined extension points
- [Phase 01]: 01-09: start-night hold requires a fresh press after a confirm or a night held through, and is ignored outside DAY; night_number increments before the NIGHT_TRANSITION step — D-11 deliberate input, and listeners on phase_changed see the correct night number
- [Phase 01]: 01-09: Python edits of files with an em dash must use encoding utf-8 on Windows (cp1252 broke the HUD script load) — Avoids invalid-UTF-8 script load errors in later plans
- [Phase 01]: 01-10: dawn payout VFX is display only; HUD readout lags the ledger by coins still in flight (Hud._payout_pending) and settles exactly on Economy gold
- [Phase 01]: 01-10: screenshot tooling never runs under --headless; runner exits 2 there and exits 1 on blank frames; CI screenshots run under xvfb with the Compatibility renderer
- [Phase 01]: 01-11: camera default offset (0,20.8,14.3) = 1.3x UAT; zoom 0.7-1.5x via zoom_in/zoom_out (=/- , keypad, right stick); SpotLabel scales by camera distance/16.9 m
- [Phase 01]: 01-13: coin_drip_interval raised 0.2 -> 0.3 s (top of D-05 range) and coin flight cap 0.18 -> 0.27 s; no hold floor in code, pacing stays linear
- [Phase 01]: [01-12]: king silhouette through buildings uses the engine stencil X-Ray preset (light cyan 0.4/0.9/1.0, unshaded) on per-instance duplicated materials via XRaySilhouette; the king only; seventh screenshot king_behind_keep

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 1]: 15 requirements. plan-phase should split it into several plans (project scaffolding + CI/lint/export, headless test and screenshot harness, king movement/camera, build spots/building/upgrading, gold/income/day transition, debug overlay + asset log)
- [Phase 2]: King respawn rules (timer, location) are a design decision because the sources don't document them; settle them in Phase 2's discuss-phase
- [Phase 2]: Determinism (DEV-05) has to cover every night system added in Phase 2 (spawning, targeting, combat, destruction), so seeded-RNG and fixed-step rules should be fixed before combat code is written
- [Phase 4]: Research flag: validate MultiMesh + NavigationServer3D avoidance vs flow fields empirically on Godot 4.7; decide GTX 970-class measurement method
- [Phase 6/8]: Night readability under hundreds of units needs automated screenshot review throughout the content phases
- [Phase 11]: Boss-night difficulty cliffs; tune with seeded simulated playthroughs plus owner playtest
- [Phase 13]: SmartScreen/AV behavior of unsigned export only known after clean-machine test

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 261001-0dd | Resolve Phase 1 owner decisions: widen CI to every push (DEV-02) and record the horse licence keep decision (ART-02) | 2026-09-30 | bfe3c97 | [261001-0dd-resolve-phase-1-owner-decisions-widen-ci](./quick/261001-0dd-resolve-phase-1-owner-decisions-widen-ci/) |

## Deferred Items

Items acknowledged and deferred at milestone close, most recent first:

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| *(none)* | | | | |

## Session Continuity

Last session: 2026-10-02T07:29:47.208Z
Stopped at: Completed 01-12-PLAN.md
Resume file: None
