---
phase: 02-night-defense-playtest-gate
plan: 09
subsystem: testing
tags: [godot, gdscript, replay, determinism, golden-digest, ci, cli, dev-05]

requires:
  - phase: 02-night-defense-playtest-gate
    provides: ReplayDriver with won/lost outcomes and a stats block, SimRecorder with an integer-only event log, PlaytestBot (plans 02-01, 02-07)
provides:
  - tools/replay/replay_cli.gd, a headless SceneTree CLI with an argument allowlist, path confinement and a REPLAY_OK sentinel (DEV-05)
  - tools/replay.sh, a bounded wrapper that requires the sentinel, a clean log and the timeout not firing
  - ReplayScenarios (smoke on frozen fixtures, full_idle on the shipped data) and the shared golden_digest lookup
  - tests/golden/smoke.json, the checked-in smoke digest, plus three self-contained smoke fixtures
  - a CI step "Seeded replay determinism" and a green CI run on the pushed branch, with Linux matching the Windows digest
affects: [02-10, 02-11, balance, playtest, ci]

actuals:
  tokens: 9000
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "A CLI run counts as passed only on its sentinel line plus a clean log: a script runtime error inside Godot still exits 0"
    - "A golden-digest scenario runs on frozen fixture data that embeds its own defs, so a balance retune of data/ never moves the golden"
    - "CLI argument parsing is a pure static function on the SceneTree script, preloaded by the unit test, so the allowlist is tested without spawning a process"

key-files:
  created:
    - tools/replay/replay_cli.gd
    - tools/replay/replay_scenarios.gd
    - tools/replay.sh
    - tests/fixtures/fixture_map_replay_smoke.tres
    - tests/fixtures/fixture_king_replay_smoke.tres
    - tests/fixtures/fixture_tuning_replay_smoke.tres
    - tests/golden/smoke.json
    - tests/integration/test_replay_golden.gd
    - tests/unit/test_replay_cli_args.gd
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "The smoke fixture embeds copies of the grunt, skirmisher, House and tower defs (no res://data/ reference), so retuning data/ in plan 02-10 cannot change the golden"
  - "The CLI also writes <out>/<scenario>.log (the canonical event lines) next to the summary JSON, so a platform disagreement can be diffed from the CI artifact"
  - "A run that ends in a loss is a valid replay result (only the timeout outcome fails), because the CLI proves reproducibility, not winnability; full_idle currently loses on night 1"
  - "--write-golden and --expect-file together are a usage error, so one run cannot both define and check the golden"
  - "Linux reproduced the Windows digest exactly, so tests/golden/smoke.json keeps only the default key and no per-platform fallback was added"

patterns-established:
  - "tools/replay.sh mirrors tools/test.sh and tools/screenshot.sh: usage comment, set -u, _common.sh, exit 3 for a missing Godot, headless --import warm-up, timeout, PIPESTATUS"
  - "TDD tasks commit a RED test commit with only stubs that fail on assertions, then a GREEN feat commit (continued)"

requirements-completed: [DEV-05]

coverage:
  - id: D1
    description: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json replays the seeded scripted run twice in one process and passes only when both digests match each other and the golden"
    requirement: DEV-05
    verification:
      - kind: integration
        ref: "tests/integration/test_replay_golden.gd#test_two_runs_of_the_smoke_scenario_give_the_same_digest_as_the_golden"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "The smoke scenario runs on self-contained fixtures and its log exercises spawns, king and tower attacks, ranged shots, building destruction, a king knockout, castle damage and a victory"
    requirement: DEV-05
    verification:
      - kind: integration
        ref: "tests/integration/test_replay_golden.gd#test_the_smoke_log_exercises_every_event_family_the_digest_must_guard"
        status: pass
      - kind: integration
        ref: "tests/integration/test_replay_golden.gd#test_the_smoke_fixtures_reference_nothing_in_data"
        status: pass
      - kind: integration
        ref: "tests/integration/test_replay_golden.gd#test_the_smoke_scenario_is_a_win"
        status: pass
    human_judgment: false
  - id: D3
    description: "The full_idle scenario replays two complete runs on the shipped prototype data and passes only when their digests match"
    requirement: DEV-05
    verification:
      - kind: other
        ref: "bash tools/replay.sh --scenario=full_idle --twice (REPLAY_OK, build/replay/full_idle.json written)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The CLI allowlist: unknown or missing scenario and non-integer seeds exit 64; 0 and negative seeds are accepted; --out and --expect-file are confined to build/ and tests/golden/ and reject .., outside absolute paths and prefix siblings; a timeout outcome exits 1; no output file is written on a usage error"
    requirement: DEV-05
    verification:
      - kind: unit
        ref: "tests/unit/test_replay_cli_args.gd (11 tests)"
        status: pass
      - kind: other
        ref: "bash tools/replay.sh --scenario=nope exits 64 and writes no scenario file; --seed=abc and --out=../x exit 64; --seed=-3 passes"
        status: pass
    human_judgment: false
  - id: D5
    description: "A replay passes only on the REPLAY_OK sentinel, a log with no SCRIPT ERROR, Parse Error or Failed to load script, and a run inside its timeout"
    requirement: DEV-05
    verification:
      - kind: other
        ref: "tools/replay.sh sentinel, error grep and timeout (usage error run exits 64 with 'no REPLAY_OK line')"
        status: pass
    human_judgment: false
  - id: D6
    description: "CI runs both replay checks in the test job on every push and uploads build/replay/; the pushed branch's latest CI run is green for HEAD"
    requirement: DEV-05
    verification:
      - kind: other
        ref: "https://github.com/ABSAR07/duskhold/actions/runs/37307329290 (success, head 0b66929, REPLAY_OK scenario=smoke in the log)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Windows and Linux produce the same smoke digest (RESEARCH assumption A1, Open Question 6)"
    requirement: DEV-05
    verification:
      - kind: other
        ref: "CI run 37307329290 Linux: REPLAY_OK digest=2599c7c2... equals the Windows golden; no REPLAY_GOLDEN_MISMATCH"
        status: pass
    human_judgment: false

duration: 28min
completed: 2026-10-05
status: complete
plan_head_before: 637471fd3eb1a4590495ebf8ed03b93603abd908
plan_head_after: 0b6692917125a864789b8905b0e94bf243d47fd5
---

# Phase 2 Plan 09: Replay CLI, golden digest and CI determinism check Summary

**A bounded headless replay CLI (allowlisted arguments, REPLAY_OK sentinel, timeout, script-error grep) with a frozen-fixture smoke scenario whose golden digest 2599c7c2... reproduces on both Windows and CI's Linux runner**

## Performance

- **Duration:** 28 min
- **Started:** 2026-10-05T11:44:59Z
- **Completed:** 2026-10-05T12:13:00Z
- **Tasks:** 2
- **Files modified:** 10 (9 created, 1 modified)

## Accomplishments

- `bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json` runs the seeded scripted smoke run twice in one process and passes only when both digests match each other and the checked-in golden; `full_idle` does the same double run on the shipped data.
- The smoke scenario runs on three self-contained fixtures (its own map with embedded defs, king, tuning). Seed 1 wins in 703 ticks and the log holds every family the digest must guard: spawns, king strikes, tower arrows, skirmisher projectiles, house destroyed, two king knockouts, castle damage and a victory.
- The wrapper cannot pass silently: it needs the REPLAY_OK line, a log free of `SCRIPT ERROR`, `Parse Error` and `Failed to load script`, and the `timeout` not firing; an unknown scenario exits 64 and writes no output file.
- CI's test job now runs both replay checks after "Headless import and GUT" and uploads `build/replay/` with the GUT results. The first Linux run matched Windows on both digests, so no per-platform golden key was needed.

## Golden digests and CI outcome

| What | Value |
|------|-------|
| smoke, seed 1, Windows (golden, `default` key) | `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (won, 703 ticks, 136 lines) |
| smoke, seed 1, Linux (CI run 37307329290) | `2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f` (identical) |
| full_idle, seed 1, Windows | `2997cb6d77b51b3b9baa0f4b2b9a690dcfd00308f535cb6e8b8a474842e2623a` (lost, 1012 ticks) |
| full_idle, seed 1, Linux | `2997cb6d77b51b3b9baa0f4b2b9a690dcfd00308f535cb6e8b8a474842e2623a` (identical; no golden stored) |

Cross-platform outcome: **Linux matched the Windows golden**, so the first of the plan's cases happened (no `Linux` key added). Only one push cycle was needed (of the 3 allowed). CI run: https://github.com/ABSAR07/duskhold/actions/runs/37307329290 (conclusion success, head 0b66929, lint, test and export jobs green; the GUT suite including test_replay_golden passed on Linux).

## Task Commits

1. **Task 1: Replay CLI and wrapper, frozen smoke fixtures, golden digest and its GUT twin**
   - RED `6c6fd18` (test): failing tests for the CLI arguments and the smoke golden, with assertion-failing stubs
   - GREEN `cdd1bec` (feat): ReplayScenarios, replay_cli.gd, replay.sh, three fixtures, smoke.json
   - REFACTOR `a30fad8` (refactor): `quit(64)` kept literal at its single use (acceptance grep)
2. **Task 2: Replay checks in CI, push, cross-platform golden settled** - `0b66929` (chore)

**Plan metadata:** recorded in the docs commit that carries this summary.

## Files Created/Modified

- `tools/replay/replay_cli.gd` - SceneTree CLI: `parse_args` allowlist, path confinement, run once or twice, golden compare/write, sentinel and exit codes
- `tools/replay/replay_scenarios.gd` - `ReplayScenarios`: NAMES, `has`, `default_seed`, `max_ticks`, `run`, `golden_digest` (platform key then `default`)
- `tools/replay.sh` - bounded wrapper: import warm-up, `timeout`, sentinel and script-error checks
- `tests/fixtures/fixture_map_replay_smoke.tres`, `fixture_king_replay_smoke.tres`, `fixture_tuning_replay_smoke.tres` - frozen smoke data
- `tests/golden/smoke.json` - golden digest
- `tests/integration/test_replay_golden.gd` - 7 tests (same run and lookup the CLI uses)
- `tests/unit/test_replay_cli_args.gd` - 11 tests of the argument allowlist
- `.github/workflows/ci.yml` - "Seeded replay determinism" step and `build/replay/` in the results artifact

## Decisions Made

See `key-decisions` above. The smoke fixture numbers were tuned (castle 20 hp, king 6 hp holding at (-16, 0), a second tower covering the castle's north face, 18 starting gold so the whole build order is placed on day 1) until the run met every event family and won; they now only change with a deliberate golden regeneration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test counted tower arrows as non-flying attacks**
- **Found during:** Task 1 (first full suite run after GREEN)
- **Issue:** `test_the_smoke_log_exercises_every_event_family...` required a building attack with `flight_ticks == 0`, but tower arrows always fly (flight > 0), so the assertion could never hold.
- **Fix:** The helper takes a minimum flight tick count: king and building attacks need at least 0, the skirmisher's at least 1.
- **Files modified:** tests/integration/test_replay_golden.gd
- **Verification:** both new test scripts then pass (18 tests); full suite 681 passing
- **Committed in:** cdd1bec (part of the GREEN commit)

**2. [Rule 3 - Blocking] Lint limits (max-returns 6, max-line-length 100)**
- **Found during:** Task 1 (gdlint)
- **Issue:** `_execute` had 7 returns; one doc line in replay_scenarios.gd was 101 characters.
- **Fix:** Split the post-run checks into `_conclude`; rewrapped the doc line.
- **Files modified:** tools/replay/replay_cli.gd, tools/replay/replay_scenarios.gd
- **Verification:** `bash tools/lint.sh` clean
- **Committed in:** cdd1bec

**3. [Rule 2 - Missing critical] Golden lookup on a missing file**
- **Found during:** Task 1 (design, before GREEN)
- **Issue:** `JSON.parse_string` on a missing or empty file logs an engine error that GUT reports as an unexpected error.
- **Fix:** `golden_digest` checks `FileAccess.file_exists` first and returns "" for a missing file, a non-object or a missing digests table.
- **Files modified:** tools/replay/replay_scenarios.gd
- **Verification:** test_an_unknown_scenario_has_no_digest_and_no_golden_is_empty passes
- **Committed in:** cdd1bec

---

**Total deviations:** 3 auto-fixed (1 bug, 1 blocking, 1 missing critical)
**Impact on plan:** All three were needed for correctness; no scope change. Additions beyond the plan, all small: `ReplayScenarios.max_ticks()` (used by the win test and the bound), the `<scenario>.log` artifact, and the `--write-golden` + `--expect-file` conflict check.

## Issues Encountered

- **full_idle loses on night 1.** With 4 starting gold the idle bot can afford one or two buildings, starts night 1 at once and the castle falls at tick 1012 (1 night started, 86 log lines). It is a valid, reproducible replay (only the timeout outcome fails), but it exercises far less than "two complete runs" of eight nights. Two build orders tried (House first, tower first) both lose on night 1. Plan 02-10 retunes the shipped data and the playtest bots, and should revisit this scenario's build order or king mode so it covers more nights.
- The bot starts every night the moment the day allows, so gold earned at dawn is the only income; the smoke fixture therefore starts with 18 gold to build its whole order on day 1.

## User Setup Required

None - no external service configuration required.

## Threat Surface

No new surface beyond the plan's threat model: the CLI's path rules and allowlist (T-02-18), the timeout, sentinel and error grep (T-02-19), the unchanged workflow permissions and action SHAs (T-02-20) and the prepush check before the single allowed push command (T-02-17) were all applied.

## Next Phase Readiness

- Any later change to the night simulation that alters the smoke log now fails the golden test locally and in CI; a deliberate rule change regenerates it with `bash tools/replay.sh --scenario=smoke --write-golden`.
- 02-10 can retune `data/` freely: the smoke golden is independent of it, and `full_idle` has no golden.

## Self-Check: PASSED

- Files exist: replay_cli.gd, replay_scenarios.gd, replay.sh, the three smoke fixtures, tests/golden/smoke.json, test_replay_golden.gd, test_replay_cli_args.gd (checked with `[ -f ]`).
- Commits exist: 6c6fd18, cdd1bec, a30fad8, 0b66929.
- Plan-level verification: `bash tools/test.sh` 681 passing in 80 scripts with both new suites in the JUnit XML; both replay commands exit 0; `--scenario=nope` exits 64; `bash tools/lint.sh` clean; CI run for HEAD green with REPLAY_OK for smoke.

---
*Phase: 02-night-defense-playtest-gate*
*Completed: 2026-10-05*
