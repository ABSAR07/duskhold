---
phase: 05
review: 05-REVIEW.md
titles: json
findings:
  - id: WR-06
    severity: warning
    disposition: open
    title: "step_bench's `CASTLE_HEALTH` never reaches the castle on the prototype shape: the castle plot is built to tier II, whose 10000 replaces it"
  - id: WR-07
    severity: warning
    disposition: open
    title: "The \"building fell\" integration test no longer fells the Barracks after the x100 rescale (file missed by the re-pin)"
  - id: WR-08
    severity: warning
    disposition: open
    title: "`castle_tier_four` and `crowd_stress_night` press `zoom_out` without `_drop_pad_zoom_events`, so a connected pad still cancels their zoom"
  - id: IN-10
    severity: info
    disposition: open
    title: "New header note calls 300 \"the king's base\"; the shipped king's base is 500"
  - id: IN-11
    severity: info
    disposition: open
    title: "Test name says \"a million health\" but its thousand-attacker case now uses a hundred million"
  - id: IN-12
    severity: info
    disposition: open
    title: "Wall \"break\" before the grid rebuild no longer breaks the 3000-health segment (file missed by the re-pin)"
  - id: IN-13
    severity: info
    disposition: open
    title: "`KILL_DAMAGE` 9900 kills nobody in the hurt run, so its \"killed outright\" path has never been pinned"
  - id: IN-14
    severity: info
    disposition: open
    title: "The old 376 px right edge survives in `hud.tscn` and in the contrast probe's documented label rect"
  - id: IN-15
    severity: info
    disposition: open
    title: "CLAUDE.md still says the WASD and sprint actions each have keyboard and gamepad bindings"
  - id: IN-16
    severity: info
    disposition: open
    title: "`COMMAND_BUTTONS` comment still says B lets a pad player deselect and ride again"
  - id: IN-17
    severity: info
    disposition: open
    title: "The class doc still says the Shrine reads \"Asleep: 30 of 100 enemy health\" while the same file's `_shrine_effect` doc says 3000 of 10000"
  - id: IN-18
    severity: info
    disposition: open
    title: "Doc comments in unchanged simulation files still give the pre-rescale numbers as \"the shipped\" ones"
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
open: 26
total: 26
recorded: 2026-10-25T23:42:34.375Z
---

# Phase 05: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-06 | warning | open | - |
| WR-07 | warning | open | - |
| WR-08 | warning | open | - |
| IN-10 | info | open | - |
| IN-11 | info | open | - |
| IN-12 | info | open | - |
| IN-13 | info | open | - |
| IN-14 | info | open | - |
| IN-15 | info | open | - |
| IN-16 | info | open | - |
| IN-17 | info | open | - |
| IN-18 | info | open | - |
| WR-01 | warning | open | - (not in the current review) |
| WR-02 | warning | open | - (not in the current review) |
| WR-03 | warning | open | - (not in the current review) |
| WR-04 | warning | open | - (not in the current review) |
| WR-05 | warning | open | - (not in the current review) |
| IN-01 | info | open | - (not in the current review) |
| IN-02 | info | open | - (not in the current review) |
| IN-03 | info | open | - (not in the current review) |
| IN-04 | info | open | - (not in the current review) |
| IN-05 | info | open | - (not in the current review) |
| IN-06 | info | open | - (not in the current review) |
| IN-07 | info | open | - (not in the current review) |
| IN-08 | info | open | - (not in the current review) |
| IN-09 | info | open | - (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
