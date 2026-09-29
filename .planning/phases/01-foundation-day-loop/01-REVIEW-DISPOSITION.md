---
phase: 01
review: 01-REVIEW.md
titles: json
findings:
  - id: WR-06
    severity: warning
    disposition: skipped
    title: "License allow-list guard is defeated by self-declaration, and the horse asset conflicts with the CC0-only constraint"
  - id: WR-10
    severity: warning
    disposition: fixed
    title: "The `MAX_COINS` cap is soft, and the \"stays inside the dawn window\" guarantee does not hold for many paying spots or a shorter dawn"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "`BuildingViews._instance_model` leaks the instantiated scene when its root is not a `Node3D`"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "`MapConfig.validate` has gaps that let unbuildable or crashing data through"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "`StartNightHoldController._confirm` emits `night_requested` regardless of the submit result"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "`tools/export.sh` ignores the import pass's exit status"
  - id: IN-05
    severity: info
    disposition: fixed
    title: "`tools/screenshot.sh` expands possibly-empty arrays under `set -u`"
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
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "`MapRoot` binds every `run_bound` node in the whole tree, so a second map cross-binds and duplicates the first map's views"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Dawn payout readout lag is unbounded and the HUD gold label can go negative"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "`tools/bootstrap.py --all` always exits 1 on a normal checkout and never installs the lint tools"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "`download_asset` fails permanently on Windows once a target file already exists, and has no timeout"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "GUT is downloaded from a mutable tag and never checked against a pin, and a failed check destroys the committed addon"
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
total: 20
recorded: 2026-09-29T13:12:01.010Z
---

# Phase 01: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-06 | warning | skipped | 01-REVIEW-FIX.md |
| WR-10 | warning | fixed | 01-REVIEW-FIX.md |
| IN-01 | info | fixed | 01-REVIEW-FIX.md |
| IN-02 | info | fixed | 01-REVIEW-FIX.md |
| IN-03 | info | fixed | 01-REVIEW-FIX.md |
| IN-04 | info | fixed | 01-REVIEW-FIX.md |
| IN-05 | info | fixed | 01-REVIEW-FIX.md |
| IN-06 | info | fixed | 01-REVIEW-FIX.md |
| IN-07 | info | fixed | 01-REVIEW-FIX.md |
| IN-08 | info | fixed | 01-REVIEW-FIX.md |
| IN-09 | info | fixed | 01-REVIEW-FIX.md |
| IN-10 | info | fixed | 01-REVIEW-FIX.md |
| WR-01 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-02 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-03 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-04 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-05 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-07 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-08 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |
| WR-09 | warning | fixed | 01-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
