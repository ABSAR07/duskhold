---
phase: "1"
slug: "foundation-day-loop"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `01-RESEARCH.md` § Validation Architecture. Task IDs, plans and waves are filled in once the plans exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT (Godot Unit Test) 9.7.1 on Godot 4.7.2-stable (standard build), run headless |
| **Config file** | none yet — Wave 0 creates `.gutconfig.json` at the project root |
| **Quick run command** | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit` |
| **Full suite command** | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit,res://tests/integration -gexit` |
| **Estimated runtime** | ~30 seconds (estimate, including engine start-up; confirm after Wave 0) |

`godot` stands for the pinned binary the setup script installs under `.tools/godot/` (D-14); the plans define the wrapper scripts that resolve it. Run `godot --headless --path . --import --quit` once after a fresh checkout so imports exist before the first test run.

Screenshots (DEV-04) use a different mode: a real rendering driver under a virtual display (`xvfb-run ... --rendering-driver opengl3`, no `--headless`) on Linux CI, or a normal window locally. Never capture screenshots under `--headless`: it produces blank images without erroring.

---

## Sampling Rate

- **After every task commit:** Run the quick run command (unit tests)
- **After every plan wave:** Run the full suite command (unit + integration) plus `gdlint` on changed scripts
- **Before `/gsd-verify-work`:** Full suite green, lint clean, and the five DEV-04 screenshots reviewed (not blank)
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | BLDG-01 | — | N/A | unit | `-gtest=res://tests/unit/test_build_spot.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BLDG-02 | — | N/A | unit | `-gtest=res://tests/unit/test_build_spot_affordability.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BLDG-03 | T-1 (input validation) | Build applied only after simulation-side validation | integration | `-gtest=res://tests/integration/test_build_flow.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BLDG-04 | T-1 (input validation) | Upgrade applied only after simulation-side validation | integration | `-gtest=res://tests/integration/test_upgrade_flow.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BLDG-06 | T-1 (input validation) | Build/upgrade rejected outside the day phase, checked when applied | unit | `-gtest=res://tests/unit/test_build_phase_guard.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ECON-01 | — | Gold never goes negative | unit | `-gtest=res://tests/unit/test_economy_gold.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ECON-02 | — | N/A | unit | `-gtest=res://tests/unit/test_dawn_income.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ECON-07 | — | N/A | integration | `-gtest=res://tests/integration/test_loop_gold_carryover.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | D-06 refund | — | No partial payment state persists | integration | `-gtest=res://tests/integration/test_build_hold_refund.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | KING-01/02 | — | N/A | unit (config constants) + screenshot | `-gtest=res://tests/unit/test_king_movement_config.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DEV-03 | T-2 (debug overlay) | Overlay reads state, never mutates it | unit | `-gtest=res://tests/unit/test_debug_overlay_readonly.gd` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DEV-04 | — | N/A | screenshot (non-blank check) | `xvfb-run --auto-servernum godot --path . --rendering-driver opengl3 ...` | ❌ W0 | ⬜ pending |

Each `-gtest=` entry runs as `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=<file> -gexit`. Threat refs are placeholders until the plans' `<threat_model>` blocks assign real IDs.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `addons/gut/` — GUT 9.7.1 installed and enabled
- [ ] `.gutconfig.json` — shared config for local and CI runs
- [ ] `tests/unit/`, `tests/integration/`, `tests/fixtures/` — directory scaffolding
- [ ] `tests/fixtures/` — minimal `MapConfig` / `BuildingDef` test resources
- [ ] `tools/screenshot/` — the screenshot capture script(s), with a non-blank image check
- [ ] gdtoolkit 4.5.0 installed (`gdlint`, `gdformat`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Riding feel: walk/sprint speed, turning, camera follow | KING-01, KING-02 | Movement feel can't be unit-tested | Play the prototype map with keyboard and gamepad; ride edge to edge (~20–30 s at walk speed per D-03); confirm the camera never rotates |
| Floating spot label, coin drip, denied shake | BLDG-02, BLDG-03, D-07, D-08 | Visual and feel checks | Ride to each spot type; hold to build with enough gold and without; release early to confirm the refund |
| Dawn payout animation and banners | ECON-02, D-12 | Visual check | End the day with the start-night hold; confirm the night banner, then the coins flying to the HUD and the "+X gold" total |
| Screenshot contents | DEV-04 | Needs someone to look at the images | Open the five captured PNGs (day overview, near-spot label, build in progress, dawn payout, overlay on) and confirm each shows its scene |
| Attribution log completeness | ART-02 | Compares files against a document | Every third-party file under the asset folders has an entry in the attribution log |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
