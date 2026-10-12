---
phase: 03
review: 03-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: open
    title: "A unit with `max_health <= 0` hangs the game in an unbounded spawn loop; the validation only reports it"
  - id: WR-01
    severity: warning
    disposition: open
    title: "The king's in-world health bar never follows regeneration"
  - id: WR-02
    severity: warning
    disposition: open
    title: "`tools/screenshot.sh` cannot see script errors, unlike the replay and playtest wrappers"
  - id: WR-03
    severity: warning
    disposition: open
    title: "A refused squad order is silent; nothing in the player-facing code reports it"
  - id: IN-01
    severity: info
    disposition: open
    title: "Patrol leg budget is assigned and immediately overwritten"
  - id: IN-02
    severity: info
    disposition: open
    title: "The ground-bounds rule exists twice"
  - id: IN-03
    severity: info
    disposition: open
    title: "`UnitSystem.separate` and `EnemySystem._separate` are the same 35 lines"
  - id: IN-04
    severity: info
    disposition: open
    title: "Test-only accessors on production classes"
  - id: IN-05
    severity: info
    disposition: open
    title: "Unused `ext_resource` entries in three building scenes"
  - id: IN-06
    severity: info
    disposition: open
    title: "The eighth patrol click is dropped without a word"
open: 10
total: 10
recorded: 2026-10-12T08:59:10.798Z
---

# Phase 03: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | open | - |
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
