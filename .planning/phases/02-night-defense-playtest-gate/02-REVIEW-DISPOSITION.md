---
phase: 02
review: 02-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "MapConfig.validate() cannot catch enemy data that makes a night impossible to end, and a real night has no clock"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "The per-night enemy cap is advisory only; at runtime it is not enforced"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "The action key is also the menu accept key, so mashing it at the end of a run restarts the game"
  - id: IN-01
    severity: info
    disposition: open
    title: "`preview_counts` counts groups that `WaveSchedule` skips"
  - id: IN-02
    severity: info
    disposition: open
    title: "An arrow in flight when the last enemy dies is dropped, though it is drawn landing"
  - id: IN-03
    severity: info
    disposition: open
    title: "`BuildingViews.bind_run` and `DayNightLighting.bind_run` have no repeat-bind guard"
  - id: IN-04
    severity: info
    disposition: open
    title: "replay.sh and playtest.sh do not fail on `push_error` output"
  - id: IN-05
    severity: info
    disposition: open
    title: "Some end-to-end tests budget real seconds against a clamped simulation clock"
  - id: IN-06
    severity: info
    disposition: open
    title: "Screenshot job worst-case time equals the job timeout"
open: 6
total: 9
recorded: 2026-10-05T16:08:39.442Z
---

# Phase 02: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 02-REVIEW-FIX.md |
| WR-02 | warning | fixed | 02-REVIEW-FIX.md |
| WR-03 | warning | fixed | 02-REVIEW-FIX.md |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
