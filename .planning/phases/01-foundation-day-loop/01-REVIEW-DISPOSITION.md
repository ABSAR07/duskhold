---
phase: 01
review: 01-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "WR-10 stagger fix is a no-op; the computed `stagger` is never used"
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "`MapConfig.validate()` misses an empty building id, and `RunContext` proceeds on invalid data"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "A payout with `total > 0` but no schedulable coins never shows a total and can leave the HUD lagging"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Registered overlay providers are trusted to return an `Array`; a bad one crashes every refresh"
  - id: WR-04
    severity: warning
    disposition: open
    title: "`screenshot.sh` discards the import output, so an import failure is undiagnosable"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "`test_each_house_spawns_as_many_coins_as_it_pays` is coupled to balance data and to real time"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "Unused constant `HOUSE_SPOT`"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "The `view_source` assertion compares an empty string to an empty string"
  - id: IN-03
    severity: info
    disposition: skipped
    title: "CI runs each push twice once a `gsd/**` branch has a pull request"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "The screenshot job's artifact upload is skipped when capture fails"
  - id: IN-05
    severity: info
    disposition: open
    title: "Redundant `get_spot` lookups and a magic-number spacing in `_add_marker`"
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
open: 3
total: 21
recorded: 2026-09-29T14:36:08.177Z
---

# Phase 01: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | fixed | 01-REVIEW-FIX.md |
| WR-01 | warning | fixed | 01-REVIEW-FIX.md |
| WR-02 | warning | fixed | 01-REVIEW-FIX.md |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | fixed | 01-REVIEW-FIX.md |
| IN-01 | info | fixed | 01-REVIEW-FIX.md |
| IN-02 | info | fixed | 01-REVIEW-FIX.md |
| IN-03 | info | skipped | 01-REVIEW-FIX.md |
| IN-04 | info | fixed | 01-REVIEW-FIX.md |
| IN-05 | info | open | - |
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
