---
phase: 01
review: 01-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Start-night hint reports \"(unbound)\" for bindings that work"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "HUD readout lag is derived independently of the VFX, so it holds only by an unenforced invariant"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "The coin cap and the \"fits the dawn window\" guarantee are not actually enforced"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "BuildingSystem hardening is inconsistent: empty-id spots are kept and `apply_next_tier` is unguarded"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "Two e2e tests claim more than they assert"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "Orphaned comment above the house constants"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "PAD_BUTTON_NAMES is Xbox-only"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "`_coin_share` does integer division through floats"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "Default-binding test depends on suite order"
  - id: IN-05
    severity: info
    disposition: fixed
    title: "Debug overlay accepts duplicate titles and cannot detect impure providers"
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "WR-10 stagger fix is a no-op; the computed `stagger` is never used"
  - id: WR-06
    severity: warning
    disposition: skipped
    title: "License allow-list guard is defeated by self-declaration, and the horse asset conflicts with the CC0-only constraint"
  - id: WR-10
    severity: warning
    disposition: fixed
    title: "The `MAX_COINS` cap is soft, and the \"stays inside the dawn window\" guarantee does not hold for many paying spots or a shorter dawn"
  - id: IN-06
    severity: info
    disposition: fixed
    title: "Loose or timing-dependent test assertions"
  - id: IN-07
    severity: info
    disposition: fixed
    title: "`DebugOverlay` ships in release exports and its section providers are called unguarded"
  - id: IN-08
    severity: info
    disposition: fixed
    title: "CI runs every push twice on PR branches, and `cancel-in-progress` applies to `main`"
  - id: IN-09
    severity: info
    disposition: fixed
    title: "`test_a_second_map_does_not_hear_the_first_maps_phase_changes` never triggers a phase change"
  - id: IN-10
    severity: info
    disposition: fixed
    title: "The GUT SHA256 pin in `bootstrap.py` duplicates `assets/attribution.json` with nothing tying them together"
  - id: WR-07
    severity: warning
    disposition: fixed
    title: "Simulation clock takes raw frame `delta` with no clamp"
  - id: WR-08
    severity: warning
    disposition: fixed
    title: "`prepush_check.sh` credential regex misses common token formats"
  - id: WR-09
    severity: warning
    disposition: fixed
    title: "CI actions are pinned to mutable major tags, and the LFS cache key omits pointer verification"
open: 0
total: 21
recorded: 2026-09-30T07:11:08.325Z
---

# Phase 01: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 01-REVIEW-FIX.md |
| WR-02 | warning | fixed | 01-REVIEW-FIX.md |
| WR-03 | warning | fixed | 01-REVIEW-FIX.md |
| WR-04 | warning | fixed | 01-REVIEW-FIX.md |
| WR-05 | warning | fixed | 01-REVIEW-FIX.md |
| IN-01 | info | fixed | 01-REVIEW-FIX.md |
| IN-02 | info | fixed | 01-REVIEW-FIX.md |
| IN-03 | info | fixed | 01-REVIEW-FIX.md |
| IN-04 | info | fixed | 01-REVIEW-FIX.md |
| IN-05 | info | fixed | 01-REVIEW-FIX.md |
| CR-01 | critical | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-06 | warning | skipped | 01-REVIEW-FIX.md (not in the current review) |
| WR-10 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| IN-06 | info | fixed | 01-REVIEW-FIX.md (not in the current review) |
| IN-07 | info | fixed | 01-REVIEW-FIX.md (not in the current review) |
| IN-08 | info | fixed | 01-REVIEW-FIX.md (not in the current review) |
| IN-09 | info | fixed | 01-REVIEW-FIX.md (not in the current review) |
| IN-10 | info | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-07 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-08 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-09 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
