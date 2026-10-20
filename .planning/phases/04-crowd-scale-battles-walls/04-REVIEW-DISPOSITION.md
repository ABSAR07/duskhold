---
phase: 04
review: 04-REVIEW.md
titles: json
findings:
  - id: WR-12
    severity: warning
    disposition: open
    title: "The stamp records the sources as of install time, so an edit during the build still yields a library with a valid-looking stamp"
  - id: WR-13
    severity: warning
    disposition: open
    title: "`tools/native_stamp_probe.sh`, the only proof of the fail-closed stamp guard, is run by nothing and has no stale-sources case"
  - id: IN-17
    severity: info
    disposition: open
    title: "`tools/_common.sh` contains a raw carriage return and raw newlines inside quoted strings"
  - id: IN-18
    severity: info
    disposition: open
    title: "`layout_from` accepts a custom-data offset that overlaps the colour, against its own comment"
  - id: IN-19
    severity: info
    disposition: open
    title: "`configure` takes non-positive or NaN time constants, which make the flash and the puff age NaN"
  - id: IN-20
    severity: info
    disposition: open
    title: "Numeric codes are declared twice (C++ enum and GDScript constants) with no test that they agree"
  - id: IN-21
    severity: info
    disposition: open
    title: "Small per-frame allocations and one avoidable mirror copy remain in the view layer"
  - id: IN-22
    severity: info
    disposition: open
    title: "`NativeUnitViews` keeps the per-fill write pointers in a member"
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
  - id: IN-08
    severity: info
    disposition: fixed
    title: "`CrowdBatch.commit()` uploads the whole buffer every frame, even for an idle batch, and `DeathPuffBatch` scans all slots per death"
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "A failed library copy leaves a valid-looking stamp, so a stale native library passes every guard and can be exported"
  - id: IN-07
    severity: info
    disposition: fixed
    title: "The view layers still do per-enemy, per-frame script work that the next gap plan can remove"
open: 33
total: 36
recorded: 2026-10-20T16:25:02.228Z
---

# Phase 04: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-12 | warning | open | - |
| WR-13 | warning | open | - |
| IN-17 | info | open | - |
| IN-18 | info | open | - |
| IN-19 | info | open | - |
| IN-20 | info | open | - |
| IN-21 | info | open | - |
| IN-22 | info | open | - |
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | open | - |
| WR-06 | warning | open | - |
| WR-07 | warning | open | - |
| WR-08 | warning | open | - |
| WR-09 | warning | open | - |
| WR-10 | warning | open | - |
| WR-11 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |
| IN-09 | info | open | - |
| IN-10 | info | open | - |
| IN-11 | info | open | - |
| IN-12 | info | open | - |
| IN-13 | info | open | - |
| IN-14 | info | open | - |
| IN-15 | info | open | - |
| IN-16 | info | open | - |
| IN-08 | info | fixed | plan 04-26 (4b1022c): CrowdBatch.commit idle skip, native puff scans, lazy mirror take; Fix IN-08 verified in 04-REVIEW.md reviewed 2026-10-20T16:16:53Z (not in the current review) |
| CR-01 | critical | fixed | plan 04-24 (commits 9ccc0d7, d888c74: duskhold_native_install, two-line stamp, native_stamp_probe.sh 7 cases); Fix CR-01 verified in 04-REVIEW.md reviewed 2026-10-20T16:16:53Z (residuals WR-12, WR-13, IN-17) (not in the current review) |
| IN-07 | info | fixed | plans 04-25 (af0a80b), 04-26 (d521b38), 04-27 (e0ecde0): the three per-frame view fills run in C++ over packed read views; Fix IN-07 verified in 04-REVIEW.md reviewed 2026-10-20T16:16:53Z (residual IN-21) (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
