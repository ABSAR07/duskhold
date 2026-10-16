---
phase: 04-crowd-scale-battles-walls
plan: 10
subsystem: replay-goldens-and-balance
tags: [godot, gdscript, replay, golden, walls, balance, playtest-bots, d-14, d-15, tracer]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: WallSystem, the wall plots and the break-or-detour rule (04-04 to 04-07), the CI test job layout (04-08), the simulation code the balance is measured on (04-09, halted, lever (a) not run so simulation/ is exactly 04-08's)
provides:
  - The fourth replay golden, walls, on a frozen self-contained fixture (tests/golden/walls.json, bfb05fc7...), checked twice in CI beside smoke and army
  - balanced_no_walls and army_balanced_no_walls (the Phase 3 orders) and wall-buying balanced and army_balanced orders
  - ReplayDriver per-night walls_broken and the Walls broken column of the balance report
  - Success criterion 4 shown as a byte-identical Phase 3 versus Phase 4 balance report, and the Phase 2 bar met with walls
  - 04-BALANCE-REPORT.md (outcome, success criterion 4, with and without walls, search log, squads with walls, goldens decision)
affects: [04-11 phase gate and push (carries the open points below into 04-PLAYTEST-GATE.md), /gsd-verify-work 4]

actuals:
  tokens: 21500
  tasks: 2
  commits: 2

plan_head_before: 7347672895d0b8c1314a81533c2eb738de614a8b
plan_head_after: 94fff12f36e47a0f71d48f73eaf21395202b546c

tech-stack:
  added: []
  patterns:
    - "A replay scenario on a frozen fixture with inline copies of the shipped numbers (walls, like smoke and army), plus a test that steps the scenario's own bot again to watch positions the event log does not carry (which crossings used the gap)"
    - "Phase N orders kept as named strategy twins (_no_walls) so a later phase can show the earlier results unchanged in the same report"
    - "A scratch candidate runner (order or wall costs swapped in memory, same ReplayDriver) to search bot orders in parallel without touching shipped files"

key-files:
  created:
    - tests/fixtures/fixture_map_replay_walls.tres
    - tests/golden/walls.json
    - tests/integration/test_walls_replay_golden.gd
    - tests/integration/test_balance_report_walls.gd
    - .planning/phases/04-crowd-scale-battles-walls/04-BALANCE-REPORT.md
  modified:
    - tools/replay/replay_scenarios.gd
    - tools/replay.sh
    - .github/workflows/ci.yml
    - tests/unit/test_replay_cli_args.gd
    - tools/replay/playtest_strategies.gd
    - tools/replay/replay_driver.gd
    - tools/replay/balance_report.gd
    - tools/playtest.sh
    - tests/unit/test_playtest_strategies.gd
    - tests/integration/test_balance_acceptance.gd
    - tests/integration/test_balance_report.gd

key-decisions:
  - "Success criterion 4 holds exactly: the Phase 3 orders on the Phase 4 code give a byte-identical report.json (md5 001778e71f38ecd0424f65e0ef9977f8) to the Phase 3 tree over 60 runs, and the 60 non-wall rows of the final matrix equal Phase 3 field for field"
  - "The plan's first wall order (each road run right after its tower) broke the Phase 2 bar: balanced 4 of 10 and army_balanced 2 of 10. D-15's ladder moved the wall entries later; both bots now win 8 of 10 and lose exactly the Phase 3 seeds (3 and 9; 1 and 9). No night count, wall cost or other data moved"
  - "Honest limit: the bots earn 22 and 15 gold a run, so the shipped orders buy walls only in the last days before the final nights (21 tier I walls over 20 runs, 0 segments broken in the sweep); free walls still cost the army bot four seeds, the cheapest D-03 prices (1 / 3 / 5) still leave the first order at 5 and 4 wins"
  - "full_idle stays intentionally unpinned; its digest moved f417c7f5... (6941 ticks) to 4385f569... (6911 ticks) because the balanced bot's order changed, and 04-BALANCE-REPORT.md is the only record of both"
  - "The walls fixture's night 2 stragglers arrive every 3.0 s, not the 1.5 s the plan sketched: at 1.5 s one of eight walked round and five broke through; at 3.0 s all eight take the gap (a fixture-only change the plan allows)"

patterns-established:
  - "Pins that belonged to a bot order the plan changes move to a named twin that keeps the old order, and the changed order gets its own pins with a history comment"

requirements-completed: [BLDG-10, ENMY-04]

coverage:
  - id: D1
    description: "The walls golden: a frozen fixture where a 12-grunt crowd breaks a segment, 8 stragglers walk round through the gap and dawn restores the wall; digest bfb05fc7... (1961 ticks) equals tests/golden/walls.json twice in one process and in CI"
    requirement: BLDG-10
    verification:
      - kind: integration
        ref: "tests/integration/test_walls_replay_golden.gd"
        status: pass
      - kind: e2e
        ref: "bash tools/replay.sh --scenario=walls --twice --expect-file=tests/golden/walls.json (REPLAY_OK scenario=walls)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Success criterion 4 read per D-14: the Phase 3 orders give the Phase 3 results run for run on the Phase 4 code (byte-identical report.json), and smoke and army never moved"
    requirement: ENMY-04
    verification:
      - kind: e2e
        ref: "bash tools/playtest.sh --seeds=10 on e3b8a74 against a clean Phase 3 export: cmp of report.json, 60 runs"
        status: pass
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd#test_balanced_no_walls_loses_only_seeds_three_and_nine_and_never_before_night_three"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Phase 2 bar with walls: balanced and army_balanced win 8 of seeds 1 to 10 and lose the Phase 3 seeds; squad value ratio 0.915 on the twin (bar 0.8) and 0.888 with walls"
    requirement: ENMY-04
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_acceptance.gd"
        status: pass
    human_judgment: true
    rationale: "The bots buy walls only late and never break one; whether walls feel worth their gold in play is the owner's call at the gate"
  - id: D4
    description: "walls_broken per night in the replay driver and the balance report, equal to the wall_segment_broken lines and not moving any digest"
    requirement: BLDG-10
    verification:
      - kind: integration
        ref: "tests/integration/test_balance_report_walls.gd"
        status: pass
    human_judgment: false

duration: 128 min
completed: 2026-10-16
status: complete
---

# Phase 4 Plan 10: The Walls Golden and the Balance With Walls Summary

**A fourth replay golden pins the wall rules in CI, Phase 3's nights are shown byte-identical on the Phase 4 code, and the balanced and army bots buy the four wall runs and still win 8 of 10 after the plan's first wall order broke the bar and D-15's ladder moved the entries later**

## Performance

- **Duration:** 128 min
- **Started:** 2026-10-16T17:11:16Z
- **Completed:** 2026-10-16T19:19:21Z
- **Tasks:** 2 (Task 1 the tracer, Task 2 the regeneration commit)
- **Files modified:** 18 in the plan range (5 created: fixture, golden, two test scripts, the report; 11 modified; one new .uid)

## Accomplishments

- **Task 1, the tracer (e3b8a74).** `walls` joins `ReplayScenarios.NAMES` with `WALLS_MAP`, `WALLS_BUILD_ORDER`, `WALLS_MAX_TICKS` 8000 and `WALLS_HOLD_POINT`. The fixture `tests/fixtures/fixture_map_replay_walls.tres` is self-contained (inline wall and tower defs with the shipped numbers, grunt, inline `NavTuning`, castle 70 hp, a 60 m run at x -20 with one gap at z 22 to 26, a tower, starting gold 20). Night 1: 12 grunts 0.2 s apart break segments 10 and 11 and stream through the hole; dawn restores; night 2: 8 stragglers 3.0 s apart all cross the wall line at z 23.4, inside the gap. The golden `bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58` (1961 ticks, seed 1) was written once with `--write-golden`. `test_walls_replay_golden` (8 tests) pins the digest, the wall events (`building_built`, `wall_damaged`, `wall_segment_broken`, one `walls_restored`, an `attack_fired` at a wall target, two `night_started`), the crossings (it steps the scenario's own bot again), the fixture's self-containment and `MapConfig.validate()` clean. CI runs the walls replay after army; `permissions: contents: read` and every pinned SHA are untouched and the YAML parses. Tracer verify ran end to end ("Tracer verified end-to-end, expanding"): suite 189 scripts, 1785 tests; walls, smoke, army replays; lint.
- **Task 2, success criterion 4 (before any strategy changed).** `bash tools/playtest.sh --seeds=10` on the Phase 4 code with the Phase 3 orders (60 runs) and the same command on a clean `git archive` of the Phase 3 tree (75183fe, imported in a scratch directory) gave **byte-identical `report.json` (md5 001778e71f38ecd0424f65e0ef9977f8) and `report.md`**. The per-seed rows equal 03-BALANCE-REPORT.md Round 2 (balanced lost 3 on night 8 and 9 on night 3; army lost 1 on night 7 and 9 on night 6; towers_first 0 of 10; houses_first 4 of 10).
- **Wall-buying bots.** `balanced_no_walls` and `army_balanced_no_walls` are the Phase 3 orders; `balanced` and `army_balanced` carry the four runs. `ReplayDriver` counts `walls_broken` per night from `wall_segment_broken` and `BalanceReport` prints it as a column (`NIGHT_ROW_FORMAT`).
- **The plan's first order broke the bar.** Each road run right after its tower (and the ring, and one upgrade per run): balanced **4 of 10**, army_balanced **2 of 10**. That is D-15's "6 or fewer" branch. The levers in order: the bot's wall entries moved later (found by a 133-measurement search, every candidate logged in the report), then wall costs within D-03. The order lever alone worked, so no price moved: the shipped orders put the three road runs right after the first tower upgrade (balanced) or the first Archery Range (army), the ring after `house_5`, the road upgrades last. **Both win 8 of 10 and lose exactly the Phase 3 seeds.** Night counts were never touched (no 9 or 10 wins).
- **Re-pinned balance tests.** The Phase 3 pins (lost seeds [3, 9], first loss night 3, 8 of 10 for the army twin with seeds 1 and 9 lost, the squad value bar 0.8) live on the twins; the with-walls bots are pinned at 7 or 8 wins with their measured lost seeds, and a test requires that they pay for at least one wall over the ten seeds. `test_balance_acceptance` has 15 tests; the new `test_balance_report_walls` has 4.
- **04-BALANCE-REPORT.md** has the eight sections (Outcome; Nights play the same (success criterion 4); With and without walls; What changed; Search log; Squads with walls; Goldens decision; What the numbers say, and what they cannot).

## Task Commits

1. **Task 1: Tracer, the walls replay golden on a frozen fixture, checked twice in CI** - `e3b8a74` (feat)
2. **Task 2: the bots buy walls; balance measured with and without them; the D-14 regeneration commit** - `94fff12` (feat; message names D-14 and D-15)

**Plan metadata:** committed after this file (docs: complete plan).

## Numbers for the record

- Final matrix, `bash tools/playtest.sh --seeds=10`: `PLAYTEST_OK runs=80` (about 5 minutes). Wins: no_build 0, greedy_economy 0, houses_first 4, towers_first 0, **balanced 8, army_balanced 8, balanced_no_walls 8, army_balanced_no_walls 8**. The four non-wall strategies and the two twins equal their Phase 3 runs in all 60 rows.
- Squad value ratio: 0.915 (army_balanced_no_walls, 4.31 / 4.70), **0.888 with walls** (4.64 / 5.22). The plan's first order read 1.133; the bar is 0.8 and was not missed.
- Wall purchases by the shipped orders: balanced 15 tier I walls over 10 seeds (after night 6 or 7), army_balanced 6; **0 segments broken** in any run of the sweep.
- Goldens: smoke `2599c7c2...` (703 ticks) and army `f7a967ed...` (1353 ticks) unchanged for the whole phase (`git diff 75183fe HEAD` on both golden files is empty); walls `bfb05fc7...` (1961 ticks) new; **full_idle moved from `f417c7f500d1e9978ebdb01fcbda35628607a904a58e2959061c1325d8aca064` (6941 ticks) to `4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf` (6911 ticks)**, still unpinned by design, recorded only in the report.
- Suite at the end: **190 scripts, 1794 tests, 27553 asserts, all passing** (12 m 54 s); lint clean on 334 files.

## Decisions Made

See `key-decisions` above. Readings the plan leaves open, none a deviation:

- The plan's step 2 order (walls right after their towers) is what was measured first and the ladder in step 4 then replaced it, as step 4 says. The final orders are a measuring choice, searched and logged, not a game rule.
- Picked the placements that lose exactly the seeds the Phase 3 orders lose and buy the most walls; earlier placements (balanced 7 wins with seed 10 or 6 lost) change an outcome, which D-14's "same outcomes" reading avoids.
- The squad value bar stays on `army_balanced_no_walls`; the with-walls ratio (0.888) is reported, not pinned.
- Open points for the owner at the gate (carried to 04-11): wall prices against the bots' 15 to 22 gold a run (a barricade at 1 gold did not rescue the first order); whether the walls feel worth buying before night 6; the army bot losing four seeds even with free walls (a likely cause is the squads following a king who walks round walls, not isolated by a run).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The new walls_broken test lives in its own script**
- **Found during:** Task 2 (lint)
- **Issue:** the plan adds one test to `test_balance_report.gd`, but that script was at gdlint's 20-method cap (19 tests plus `before_all`), so one more failed `max-public-methods`.
- **Fix:** `tests/integration/test_balance_report_walls.gd` (4 tests: the column adds up in the balanced run and in the walls scenario where segments fall, the tally's open-night rule, the digest unchanged by the bookkeeping). The existing report test only gained the `walls_broken` key and the extra column in its column counts.
- **Files modified:** tests/integration/test_balance_report_walls.gd (new), tests/integration/test_balance_report.gd
- **Verification:** both scripts pass; lint clean.
- **Committed in:** `94fff12`

**2. [Rule 1 - Stale test] Two Phase 3 strategy tests pinned the old lists**
- **Found during:** Task 2
- **Issue:** `test_the_six_named_strategies_are_listed`, `test_only_the_balanced_pair_prefers_telegraphed_towers` and the army early-build test (the Range "within the first six entries") described the six-strategy world; with wall entries inserted the Range sits at index 6 of the new order.
- **Fix:** renamed and widened them to the eight strategies and the balanced family; the Range pin counts non-wall entries (the Range is still the sixth non-wall entry). Added two tests for the twins' orders and the wall placement.
- **Files modified:** tests/unit/test_playtest_strategies.gd
- **Committed in:** `94fff12`

### Plan-sanctioned adjustments (recorded because a literal changes)

- Task 1 step 1 sketches night 2 as 8 grunts at 1.5 s; the fixture uses **3.0 s** because at 1.5 s one of eight walked round and five broke through, and step 3 allows adjusting the fixture "until both happen" (all eight go round at 3.0 s, the crowd of night 1 still breaks the wall).
- Task 2 step 2's wall placement was measured first and then superseded by step 4's ladder (see Decisions).
- `tools/replay/balance_report.gd` now builds the night row format from `NIGHT_ROW_FORMAT` (a multi-line constant) because the longer literal exceeded the 100-character line cap.

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 stale test) plus 3 plan-sanctioned adjustments
**Impact on plan:** none on the contract; every acceptance criterion holds. The one substantive result is that the plan's first wall order breaks the Phase 2 bar and the ladder, not a data change, was needed.

## Issues Encountered

- A shell heredoc with backticks (`w e n r` in a replacement string) executed the words as commands once while patching the search log; the patch did not apply and was redone from a file. No project file was affected.
- `git.base-branch --is-protected` was not run: the branch is the phase branch `gsd/phase-01-foundation-day-loop`, which plans 04-01 to 04-09 committed on the same way; HEAD is a non-default, non-detached branch.
- Several tracked files have CRLF endings in the working copy; `gdformat` normalised the touched ones to LF and git prints its CRLF warning on `add`.

## Known Stubs

None.

## Threat Flags

None. T-04-26 (golden tampering): the walls golden is a new file, smoke and army are byte-identical, and the only regeneration is the single commit `94fff12` with 04-BALANCE-REPORT.md giving before and after and the reason. T-04-27 (CI): one replay command added to an existing step, `permissions: contents: read`, no secrets, pinned SHAs unchanged. T-04-SC: no packages.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **For 04-11 (gate and push):** the CI test job gained one replay line (walls); the gate stress, the 37 shots and this plan's replays first run on the plan 04-11 push. Carry into 04-PLAYTEST-GATE.md: the open points above, D-14's reading and that the owner can ask for the literal reading (every digest regenerated), the unmet PLAT-01 budget and the 13 ms wall-break rebuild hitch from 04-09.
- No blocker. Plan 04-10 changed no simulation code, so the frame report of 04-09 stands.

## Self-Check: PASSED

- Created files exist: `tests/fixtures/fixture_map_replay_walls.tres`, `tests/golden/walls.json`, `tests/integration/test_walls_replay_golden.gd`, `tests/integration/test_balance_report_walls.gd`, `04-BALANCE-REPORT.md`.
- Commits `e3b8a74` and `94fff12` are in `git log`; `git rev-list --count 7347672..HEAD` was 2 before this file.
- Acceptance criteria re-run: `NAMES` has `&"walls"` and `WALLS_BUILD_ORDER`; `walls.json` has `"scenario": "walls"` and a 64-character digest; the fixture has no `res://data/` path; ci.yml runs the walls replay with `--expect-file=tests/golden/walls.json`; `NAMES` has the two twins and `_BALANCED` holds the four wall ids; the acceptance test pins [3, 9] on `balanced_no_walls` and the measured with-walls lost seeds [3, 9] on `balanced`; the report has the eight sections and both full_idle digests; `git show --stat HEAD` shows the strategies, the balance tests and the report in one commit whose message names D-14.
- Plan verification: `PLAYTEST_OK runs=80`, full suite 1794 of 1794, the four replays REPLAY_OK, lint clean.

---
*Phase: 04-crowd-scale-battles-walls*
*Completed: 2026-10-16*
