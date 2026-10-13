---
phase: 03
review: 03-REVIEW.md
titles: json
findings:
  - id: WR-04
    severity: warning
    disposition: open
    title: "The contrast probe's pure functions (path guard and measurement) have no automated test"
  - id: IN-07
    severity: info
    disposition: open
    title: "`to_markdown` indexes the new run keys strictly while `summary` reads them tolerantly"
  - id: IN-08
    severity: info
    disposition: open
    title: "The queue action name is a literal in two controllers and a constant in a third"
  - id: IN-09
    severity: info
    disposition: open
    title: "The panel colour #14141A at alpha 0.78 is written out in three places"
  - id: CR-01
    severity: critical
    disposition: open
    title: "A unit with `max_health <= 0` hangs the game in an unbounded spawn loop; the validation only reports it"
  - id: WR-01
    severity: warning
    disposition: fixed
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
open: 13
total: 14
recorded: 2026-10-13T19:50:43.130Z
---

# Phase 03: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-04 | warning | open | - |
| IN-07 | info | open | - |
| IN-08 | info | open | - |
| IN-09 | info | open | - |
| CR-01 | critical | open | - (not in the current review) |
| WR-01 | warning | fixed | plan 03-14 (commit ee21f6f: King.bind_run connects king_healed to _on_king_healed); re-verified fixed by the 2026-10-13 review (03-REVIEW.md section "WR-01 from the previous review") (not in the current review) |
| WR-02 | warning | open | - (not in the current review) |
| WR-03 | warning | open | - (not in the current review) |
| IN-01 | info | open | - (not in the current review) |
| IN-02 | info | open | - (not in the current review) |
| IN-03 | info | open | - (not in the current review) |
| IN-04 | info | open | - (not in the current review) |
| IN-05 | info | open | - (not in the current review) |
| IN-06 | info | open | - (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
