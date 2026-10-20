---
phase: 04
review: 04-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: open
    title: "A failed library copy leaves a valid-looking stamp, so a stale native library passes every guard and can be exported"
  - id: WR-08
    severity: warning
    disposition: open
    title: "The \"no native library, no game\" guard in `MapRoot._ready` cannot run in the case it guards"
  - id: WR-09
    severity: warning
    disposition: open
    title: "`test_native_rules_guard.gd` does not scan for the rule `gd_math.h` says it enforces (no `std::max/min/clamp` on floats)"
  - id: WR-10
    severity: warning
    disposition: open
    title: "`native_build.sh` verifies the godot-cpp commit but not that the checkout is unmodified"
  - id: WR-11
    severity: warning
    disposition: open
    title: "`separation_displacements_bucketed` does unbounded work for a small caller-chosen `cell`, from a bound static method"
  - id: IN-07
    severity: info
    disposition: open
    title: "The view layers still do per-enemy, per-frame script work that the next gap plan can remove"
  - id: IN-08
    severity: info
    disposition: open
    title: "`CrowdBatch.commit()` uploads the whole buffer every frame, even for an idle batch, and `DeathPuffBatch` scans all slots per death"
  - id: IN-09
    severity: info
    disposition: open
    title: "Native helpers copied across files: `wrap_add`/`wrap_mul` six times, `cell_key` four times, `walk_ticks` twice"
  - id: IN-10
    severity: info
    disposition: open
    title: "Public GDScript facade methods that only tests call, which also force the private-member access `pathing._route`"
  - id: IN-11
    severity: info
    disposition: open
    title: "Test-only probe code ships in the production library"
  - id: IN-12
    severity: info
    disposition: open
    title: "No sanitizer or static-analysis pass over the new C++"
  - id: IN-13
    severity: info
    disposition: open
    title: "The `export` job downloads native artifacts by pattern, not by exact name"
  - id: IN-14
    severity: info
    disposition: open
    title: "`step_bench.gd --map=stress` runs and reports a different enemy count than it was given"
  - id: IN-15
    severity: info
    disposition: open
    title: "Float-to-integer casts and boundary values cross into C++ unchecked"
  - id: IN-16
    severity: info
    disposition: open
    title: "`test_living_within_lists_every_living_enemy_in_reach_ascending` asserts the opposite of the documented contract and passes by call order"
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
    title: "Key-packing code is copied into six classes (now also into five C++ files)"
  - id: IN-06
    severity: info
    disposition: open
    title: "`frame_report_cli._write` can leave a file handle open on a partial failure"
open: 28
total: 28
recorded: 2026-10-20T06:30:02.977Z
---

# Phase 04: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | open | - |
| WR-08 | warning | open | - |
| WR-09 | warning | open | - |
| WR-10 | warning | open | - |
| WR-11 | warning | open | - |
| IN-07 | info | open | - |
| IN-08 | info | open | - |
| IN-09 | info | open | - |
| IN-10 | info | open | - |
| IN-11 | info | open | - |
| IN-12 | info | open | - |
| IN-13 | info | open | - |
| IN-14 | info | open | - |
| IN-15 | info | open | - |
| IN-16 | info | open | - |
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
