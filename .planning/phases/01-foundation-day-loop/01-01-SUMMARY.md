---
phase: 01-foundation-day-loop
plan: 01
subsystem: infra
tags: [godot, gdscript, gut, gdtoolkit, gdlint, gdformat, sha512, git-lfs, bootstrap]

requires:
  - phase: none
    provides: first plan of the project
provides:
  - Consent-gated, checksum-verified toolchain bootstrap (tools/bootstrap.py)
  - Pinned Godot 4.7.2-stable, self-contained, with Windows export templates under .tools/ (git-ignored)
  - Vendored GUT 9.7.1 (addons/gut/) and gdtoolkit 4.5.0 in .tools/venv
  - Wrappers tools/godot.sh, tools/test.sh (headless GUT + JUnit XML), tools/lint.sh (gdformat + gdlint)
  - Initial project.godot (Forward+, 1280x720, untyped_declaration=2)
  - Repo hygiene (.gitignore, .gitattributes with LFS routing, .gdignore markers)
affects: [01-02, 01-03, 01-04, 01-05, 01-06, 01-07, 01-08, 01-09, 01-10, all later phases]

actuals:
  tokens: 7700   # chars/4 over first-party files changed (vendored addons/gut excluded)
  tasks: 3
  commits: 2
plan_head_before: 6026a067c88cc4040d4a3dc016dddc2473eb5ae5
plan_head_after: 804dcda821b9831c76d3878ec00c2326b7221584

tech-stack:
  added: [Godot 4.7.2-stable (standard), GUT 9.7.1, gdtoolkit 4.5.0]
  patterns:
    - "Every script sources tools/_common.sh; DUSKHOLD_ROOT_NATIVE (cygpath -m) is the path form passed to native Godot"
    - "Single version pin in tools/godot_version.txt; SHA512 pin committed in tools/godot_sha512sums.txt"
    - "Downloads only via tools/bootstrap.py, refused without --yes (exit 2)"
    - "Lint targets first-party dirs only; addons/ is never passed to gdlint/gdformat"

key-files:
  created:
    - .gitignore
    - .gitattributes
    - build/.gdignore
    - screenshots/.gdignore
    - tools/godot_version.txt
    - tools/_common.sh
    - tools/bootstrap.py
    - tools/godot.sh
    - tools/requirements-lint.txt
    - tools/godot_sha512sums.txt
    - tools/test.sh
    - tools/lint.sh
    - project.godot
    - .gutconfig.json
    - .gdlintrc
    - tests/unit/test_toolchain_smoke.gd
    - addons/gut/
  modified: []

key-decisions:
  - "Phase 1 work lands on branch gsd/phase-01-foundation-day-loop (owner decision); master holds Task 1 only and the owner merges later"
  - "Godot runs in self-contained mode (_sc_ file); export templates kept only for Windows, tpz archive deleted after extraction"
  - "untyped_declaration=2 makes untyped first-party GDScript a compile error; addons stay exempt"
  - "Rejected operations return values rather than push_error, because GUT 9.7 can count engine errors as test failures"

patterns-established:
  - "Godot 4.7 writes a .gd.uid per script; commit each .uid together with its script"
  - "GUT user:// temp output goes to %APPDATA%/Godot/app_userdata/Duskhold (_sc_ covers editor data only)"
  - "Wrappers exit non-zero on missing JUnit XML or Parse Error / Failed to load script outside addons/gut"

requirements-completed: [DEV-01, DEV-02]

coverage:
  - id: D1
    description: "tools/bootstrap.py refuses to download without --yes (exit 2) and prints the dry-run table; nothing was downloaded before owner approval"
    requirement: "DEV-01"
    verification:
      - kind: other
        ref: "python tools/bootstrap.py --godot; test $? -eq 2 (Task 1 verify, passed before Task 2 checkpoint)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Godot 4.7.2-stable installed self-contained with Windows export templates, both archives checksum-verified against official SHA512-SUMS.txt"
    requirement: "DEV-01"
    verification:
      - kind: other
        ref: "bash tools/godot.sh --version | grep -q '^4\\.7\\.2\\.stable' && Task 3 verify chain"
        status: pass
    human_judgment: false
  - id: D3
    description: "Headless GUT 9.7.1 run through tools/test.sh with JUnit XML output; toolchain smoke test passes 2/2"
    requirement: "DEV-01"
    verification:
      - kind: unit
        ref: "tests/unit/test_toolchain_smoke.gd#test_engine_is_pinned_version"
        status: pass
      - kind: unit
        ref: "tests/unit/test_toolchain_smoke.gd#test_untyped_declarations_are_errors"
        status: pass
    human_judgment: false
  - id: D4
    description: "tools/lint.sh runs gdformat --check and gdlint on first-party GDScript only and exits 0"
    requirement: "DEV-02"
    verification:
      - kind: other
        ref: "bash tools/lint.sh (exit 0, output never mentions addons/gut)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Repo hygiene keeps local tooling out of git (.claude/* except CLAUDE.md, .tools/, .godot/, build and screenshots output) with LFS routing for binary assets"
    requirement: "DEV-01"
    verification:
      - kind: other
        ref: "Task 1 verify: git check-ignore chain + git ls-files .claude == .claude/CLAUDE.md"
        status: pass
    human_judgment: false
  - id: D6
    description: "DEV-02 (lint, test, screenshot, export headlessly on every push) is only partly delivered here; the CI workflow and Windows export land in plan 01-03"
    requirement: "DEV-02"
    verification: []
    human_judgment: true
    rationale: "Local lint and test halves are proven; the on-every-push half depends on CI from plan 01-03 and cannot be asserted by this plan's tests"

duration: 2h 41m wall-clock (includes the owner wait at the Task 2 checkpoint and the branch decision after the pre-commit halt)
completed: 2026-09-29
status: complete
---

# Phase 1 Plan 01: Toolchain Bootstrap Summary

**Consent-gated, SHA512-verified bootstrap for Godot 4.7.2-stable (self-contained, Windows export templates), vendored GUT 9.7.1 and gdtoolkit 4.5.0, with `tools/godot.sh`, `tools/test.sh` and `tools/lint.sh` proven by a green headless smoke test and clean lint**

## Performance

- **Duration:** 2h 41m wall-clock, dominated by waiting (Task 2 owner checkpoint, then the branch decision)
- **Started:** 2026-09-28T23:39Z approx. (plan start; Task 1 committed 2026-09-29 06:47 +0500)
- **Completed:** 2026-09-29T04:21Z
- **Tasks:** 3 (Task 2 was the blocking-human checkpoint)
- **Files modified:** 279 in git (259 vendored under addons/gut/, 20 first-party)

## Accomplishments

- `tools/bootstrap.py` cannot download anything without `--yes` (exits 2 with the dry-run table), verifies the editor zip and templates tpz against the official checksums and the committed pin, and rejects zip-slip members.
- Godot 4.7.2-stable installed in self-contained mode: `bash tools/godot.sh --version` prints `4.7.2.stable.official.ed1daf0bf`, editor data lives in `.tools/godot/4.7.2-stable/editor_data/`, and Windows export templates sit at `editor_data/export_templates/4.7.2.stable/`.
- GUT 9.7.1 vendored into `addons/gut/`; `bash tools/test.sh` runs headless (import pass, then GUT), writes `build/test-results/gut-junit.xml` and passes 2/2 tests.
- `bash tools/lint.sh` runs `gdformat --check` and `gdlint` (gdtoolkit 4.5.0) over first-party dirs only, exit 0, and never touches `addons/gut`.
- `project.godot` sets `debug/gdscript/warnings/untyped_declaration=2`, so untyped first-party declarations fail to compile.

## Task Commits

1. **Task 1: Repo hygiene and a consent-gated bootstrap script (no downloads)** - `84cc667` (feat)
2. **Task 2: Owner approves the toolchain downloads** - checkpoint, no commit
3. **Task 3: Install the approved toolchain; headless GUT smoke test + clean lint** - `804dcda` (feat)

**Plan metadata:** committed as `docs(01-01): complete toolchain bootstrap plan` (see git log)

**Branch note:** the previous run halted at the pre-commit HEAD safety assertion because HEAD was on `master` (protected). Per owner decision, Phase 1 work now lands on `gsd/phase-01-foundation-day-loop`, created from `84cc667`. `master` holds Task 1 only; the owner merges the branch later. No config was changed to bypass the assertion.

## Owner Approval (Task 2 checkpoint)

Owner reply, verbatim: `approved` (all five local downloads plus the later CI downloads; nothing excluded).

Downloaded exactly:
- `Godot_v4.7.2-stable_win64.exe.zip`
- `SHA512-SUMS.txt`
- `Godot_v4.7.2-stable_export_templates.tpz` (about 1.28 GB; only Windows templates kept, archive deleted)
- GUT v9.7.1 source zip
- `gdtoolkit==4.5.0` plus its pip dependencies

The Linux editor zip was NOT downloaded locally; its hash is pinned for CI use only.

## Provenance and Versions

- Both Godot archives: "Checksum OK" against the official `SHA512-SUMS.txt`. `tools/godot_sha512sums.txt` has exactly 3 lines (win64 zip, linux zip, templates tpz).
- **GUT v9.7.1 zip SHA256:** `14969aa46adc84aa08cdd21b9f6d1a64addd92ae60b36f02d0521ed305aa4086` (plan 01-07 copies this into the attribution log).
- gdtoolkit: gdlint 4.5.0. Pip dependencies: colorama 0.4.6, docopt-ng 0.9.0, lark 1.2.2, mando 0.7.1, pyyaml 6.0.3, radon 6.0.1, regex 2026.9.29, setuptools 84.0.0, six 1.17.0.
- CLI fallback: none needed. `--import` worked on 4.7.2, so the `--editor --quit` fallback was not used. Self-contained `editor_data/` was created by it.

## Files Created/Modified

- `.gitignore`, `.gitattributes` - ignore local tooling and generated output; LF for text; Git LFS routing for binary assets
- `build/.gdignore`, `screenshots/.gdignore` - keep generated output out of Godot's import scan
- `tools/godot_version.txt`, `tools/requirements-lint.txt` - single-line version pins
- `tools/_common.sh`, `tools/godot.sh` - shared helpers and pinned-binary launcher
- `tools/bootstrap.py` - consent-gated, checksum-verified installer
- `tools/godot_sha512sums.txt` - committed SHA512 pin for the three Godot assets
- `tools/test.sh`, `tools/lint.sh` - headless test and lint wrappers
- `project.godot`, `.gutconfig.json`, `.gdlintrc` - project, GUT and lint config
- `tests/unit/test_toolchain_smoke.gd` (+ `.uid`) - engine-version and typed-declaration smoke tests
- `tests/{integration,e2e,fixtures}/.gitkeep` - placeholder folders
- `addons/gut/` - vendored GUT 9.7.1

## Decisions Made

- Phase 1 commits land on `gsd/phase-01-foundation-day-loop` per owner decision after the protected-branch halt.
- Self-contained Godot (`_sc_`) keeps editor settings and templates inside git-ignored `.tools/`.
- Only Windows export templates are retained locally (D-15) to keep the disk footprint near 0.2 GB instead of 1.28 GB.
- Static typing is enforced by the engine (`untyped_declaration=2`) rather than by lint alone.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Ignore GSD runtime state files**
- **Found during:** Task 1 (repo hygiene)
- **Issue:** GSD writes `.gsd/`, `.planning/milestone.lock` and `.planning/state.json` at runtime; unignored, they could reach the public repo (D-16, threat T-01-03).
- **Fix:** Added `/.gsd/`, `/.planning/milestone.lock` and `/.planning/state.json` to `.gitignore`.
- **Files modified:** `.gitignore`
- **Verification:** `git check-ignore` on each path
- **Committed in:** `84cc667`

**2. [Rule 3 - Blocking] gdtoolkit 4.5.0 `--dump-default-config` behavior**
- **Found during:** Task 3 (lint harness)
- **Issue:** The flag is `-d` and it writes a `gdlintrc` file in the cwd instead of printing to stdout, so the plan's redirect approach does not work.
- **Fix:** Regenerated the config with `-d`, added `addons`, `.godot`, `.tools`, `build`, `screenshots` to `excluded_directories`, saved as `.gdlintrc`, removed the temporary file.
- **Files modified:** `.gdlintrc`
- **Verification:** `bash tools/lint.sh` exits 0 and never mentions `addons/gut`
- **Committed in:** `804dcda`

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking)
**Impact on plan:** Both were needed for correctness/security or to complete the task. No scope creep.

## Issues Encountered

- The first Task 3 commit attempt halted at the pre-commit HEAD safety assertion because HEAD was on `master` (protected/default). The owner chose a phase branch; the orchestrator created it from `84cc667`, the staged work carried over, and the assertion passed unmodified (`git.base-branch --is-protected` returned `false`).
- Post-halt re-verification: the full Task 3 verify chain passed again on the staged tree before commit, and the commit added no tracked deletions and no untracked files.

## Notes for Later Plans

- Godot 4.7 writes a `.gd.uid` file per script; commit it alongside the script.
- GUT temp output goes to `%APPDATA%/Godot/app_userdata/Duskhold`; `_sc_` covers editor data only.
- Rejected operations must return values, not `push_error`: GUT 9.7 can count engine errors as failures.
- `.planning/config.json` carries an uncommitted orchestrator change (`workflow._auto_chain_active: false`); it was intentionally not staged.

## Known Stubs

None. `tests/{integration,e2e,fixtures}/.gitkeep` are intentional empty-folder placeholders; plans 01-02 onward fill them.

## Threat Flags

None. The plan's threat register (T-01-01, T-01-02, T-01-03, T-01-SC) was mitigated as specified: SHA512 verification against the official file and the pin, `--yes` consent gate plus the Task 2 blocking-human checkpoint, ignore rules verified with `git check-ignore`, and exact version pins with the GUT `plugin.cfg` 9.7.1 assert and recorded zip SHA256.

## User Setup Required

None - no external service configuration required. (Later, plan 01-03 needs owner approval for the public repo before CI downloads run.)

## Next Phase Readiness

- Toolchain is in place for plan 01-02 (walking-skeleton tracer): `tools/godot.sh`, `tools/test.sh`, `tools/lint.sh` all work.
- DEV-02 remains partly open: the CI-on-every-push and headless export/screenshot halves arrive in plan 01-03 and later.
- Owner must merge `gsd/phase-01-foundation-day-loop` into `master` when ready; `master` currently holds Task 1 only.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*

## Self-Check: PASSED

- All key files exist on disk; commits 84cc667 and 804dcda found in git log.
- Task 3 verify chain re-run before commit: all checks passed (test 2/2, lint exit 0).
- `git ls-files .claude` is only `.claude/CLAUDE.md`; nothing under `.tools/` or `.godot/` is tracked.
- `requirements.ready-ids` returned 0/2 ready: DEV-01 and DEV-02 are also declared by plans 01-02, 01-03 and 01-10 without SUMMARYs, so they are not marked Complete yet (shared-ID gate, #2388).
