---
phase: 02
review: 02-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "A huge finite castle_attack_interval passes validate(), arms the castle and fires it every tick"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "The single-writer scan for Engine.time_scale misses compound assignments and reflective setters"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "BALANCED_MIN_WINS = 7 is unreachable, and one test name is stale"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "CastleAttack.is_armed() does not check the projectile speed, contradicting its \"unvalidated data\" claim"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "MapConfig.validate() accepts a NaN or infinite castle_radius and NaN enemy floats"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "Orphaned line in the fast_forward_scale doc comment"
  - id: IN-05
    severity: info
    disposition: open
    title: "Some end-to-end tests budget real seconds against a clamped simulation clock"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "The action key is also the menu accept key, so mashing it at the end of a run restarts the game"
  - id: IN-06
    severity: info
    disposition: open
    title: "Screenshot job worst-case time equals the job timeout"
open: 2
total: 9
recorded: 2026-10-08T05:57:02.845Z
---

# Phase 02: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 02-REVIEW-FIX.md |
| WR-02 | warning | fixed | 02-REVIEW-FIX.md |
| IN-01 | info | fixed | 02-REVIEW-FIX.md |
| IN-02 | info | fixed | 02-REVIEW-FIX.md |
| IN-03 | info | fixed | 02-REVIEW-FIX.md |
| IN-04 | info | fixed | 02-REVIEW-FIX.md |
| IN-05 | info | open | - (not in the current review) |
| WR-03 | warning | fixed | 02-REVIEW-FIX.md (not in the current review) |
| IN-06 | info | open | - (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
