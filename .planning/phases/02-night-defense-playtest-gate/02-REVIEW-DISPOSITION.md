---
phase: 02
review: 02-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Leaked FastForwardControllers make \"a held key resumes fast-forward as the night begins\" unable to fail"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Castle attack validation does not prevent a castle that fires on every tick (non-finite or sub-step interval), contradicting T-02-33"
  - id: IN-01
    severity: info
    disposition: open
    title: "The dawn_payout signal documentation still says per_spot maps only spot ids"
  - id: IN-02
    severity: info
    disposition: open
    title: "test_results_layout pins the 11 px constant rather than measuring the visible gap it exists for"
  - id: IN-05
    severity: info
    disposition: open
    title: "Some end-to-end tests budget real seconds against a clamped simulation clock"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "The \"shipped grace is set in the data file\" test cannot see the data file"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "The grace value has no upper bound"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "The action key is also the menu accept key, so mashing it at the end of a run restarts the game"
  - id: IN-06
    severity: info
    disposition: open
    title: "Screenshot job worst-case time equals the job timeout"
open: 6
total: 9
recorded: 2026-10-06T14:32:32.881Z
---

# Phase 02: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-05 | info | open | - (not in the current review) |
| IN-03 | info | fixed | 02-REVIEW-FIX.md (not in the current review) |
| IN-04 | info | fixed | 02-REVIEW-FIX.md (not in the current review) |
| WR-03 | warning | fixed | 02-REVIEW-FIX.md (not in the current review) |
| IN-06 | info | open | - (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
