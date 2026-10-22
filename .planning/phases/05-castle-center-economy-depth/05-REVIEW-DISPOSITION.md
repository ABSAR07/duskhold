---
phase: 05
review: 05-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "A refused `add_source` is ignored after the gold is spent and the pick is recorded"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Castle tiers II to IV are not validated, so a bad row silently disarms the keep; the CastleAttack header still claims otherwise"
  - id: WR-03
    severity: warning
    disposition: open
    title: "`StatModifierDef.problems()` accepts a bucket that is not one of the three"
  - id: WR-04
    severity: warning
    disposition: open
    title: "The \"no income\" coin is drawn over a rebuilt Shrine that has not woken and pays nothing anyway"
  - id: WR-05
    severity: warning
    disposition: open
    title: "IncomeState's per-death handler allocates and rescans every plot for each enemy death"
  - id: IN-01
    severity: info
    disposition: open
    title: "`CastleAttack._map` is a dead field after 05-02"
  - id: IN-02
    severity: info
    disposition: open
    title: "A digit key above the card count clears the highlight instead of being ignored"
  - id: IN-03
    severity: info
    disposition: open
    title: "`StatStack` allocates an empty Dictionary on every read, and `CastleAttack` reads the stack several times per tick"
  - id: IN-04
    severity: info
    disposition: open
    title: "The card picker and the requirement check do avoidable work every frame near a plot"
  - id: IN-05
    severity: info
    disposition: open
    title: "`dawn_income` set on a BOATS tier is silently never paid and not reported"
  - id: IN-06
    severity: info
    disposition: open
    title: "The castle-raising helper exists twice, fails silently, and the shot version writes the economy directly"
  - id: IN-07
    severity: info
    disposition: open
    title: "`PondView.bind_run` dereferences spot entries without a null check"
  - id: IN-08
    severity: info
    disposition: open
    title: "A wall-clock loop in an e2e test makes the shake assertion machine-dependent"
  - id: IN-09
    severity: info
    disposition: open
    title: "The transcendental guard does not scan the Phase 5 simulation folders that make decisions"
open: 14
total: 14
recorded: 2026-10-22T09:57:30.706Z
---

# Phase 05: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |
| IN-07 | info | open | - |
| IN-08 | info | open | - |
| IN-09 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
