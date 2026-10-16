---
phase: 04
review: 04-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "MIN_GAP_METRES (3 m) does not keep a gap routable on the 2 m grid; the documented guarantee is wrong"
  - id: WR-02
    severity: warning
    disposition: open
    title: "A circle resting exactly on a wall is reported as blocked by the wall behind it (no tangency epsilon in `first_blocking`)"
  - id: WR-03
    severity: warning
    disposition: open
    title: "An enemy outside the nav grid counts as walled off from the castle"
  - id: WR-04
    severity: warning
    disposition: open
    title: "`WallValidation` never checks that a wall plot's tiers have health"
  - id: WR-05
    severity: warning
    disposition: open
    title: "`tools/stress.sh` accepts `--duration=08` and then dies in bash arithmetic; `STRESS_EXTRA_TIMEOUT_S` is evaluated as arithmetic"
  - id: WR-06
    severity: warning
    disposition: open
    title: "Balance acceptance for the wall bots passes whether or not walls were ever bought or mattered"
  - id: WR-07
    severity: warning
    disposition: open
    title: "`test_wall_tracer_scene` bounds a night by wall-clock time"
  - id: IN-01
    severity: info
    disposition: open
    title: "Hot-path allocations in the enemy phase, with the concrete fixes"
  - id: IN-02
    severity: info
    disposition: open
    title: "`segments_near` cost grows with the square of the query reach in `first_blocking`"
  - id: IN-03
    severity: info
    disposition: open
    title: "`UnitViews.MAX_VIEWS` (256) is smaller than the simulation can field"
  - id: IN-04
    severity: info
    disposition: open
    title: "The nav grid ignores the king's radius"
  - id: IN-05
    severity: info
    disposition: open
    title: "Key-packing code is copied into six classes"
  - id: IN-06
    severity: info
    disposition: open
    title: "`frame_report_cli._write` can leave a file handle open on a partial failure"
open: 13
total: 13
recorded: 2026-10-16T20:48:01.367Z
---

# Phase 04: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | open | - |
| WR-06 | warning | open | - |
| WR-07 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
