---
phase: 04-crowd-scale-battles-walls
plan: 16
subsystem: infra
tags: [ci, github-actions, gdextension, native, gcc, msvc, artifacts, determinism]
gap_closure: true
gap_ids: [G-04-5]

requires:
  - phase: 04-crowd-scale-battles-walls
    provides: plan 04-14 build script and source stamp, 04-22 guards in every wrapper, 04-15 native push-apart
provides:
  - "ci.yml: native-linux (GCC) and native-windows (MSVC) jobs that build both libraries from the pinned sources with tools/native_build.sh and hand them to test, screenshots and export as same-run artifacts"
  - "native-windows replays the four goldens and the gate on the Windows DLL; the Linux test job does the same on the GCC .so: identical digests on both compilers"
  - "A CI-built Windows export that packs libduskhold_sim.windows.x86_64.dll next to Duskhold.exe and launches here"
  - "tools/native_build.sh builds in parallel on Linux when Ninja is absent"
affects: [04-17, 04-18, 04-19, 04-20, 04-21, 04-23]

actuals:
  tokens: 5200
  tasks: 2
  commits: 1

plan_head_before: 4874dba90f3ce5f7ecf92bae18dd6bf0e7ed85c8
plan_head_after: c420beff05a1386eee27451e08fefeedcf4e54c9

tech-stack:
  added: ["actions/download-artifact v8.0.2 (SHA-pinned)"]
  patterns:
    - "Libraries are built in the workflow run that uses them and passed between jobs by artifact name; nothing binary is committed"
    - "The source stamp covers sources only, so linux.stamp and windows.stamp are valid for every job of the run"
    - "The export job downloads native-* with merge-multiple into addons/duskhold_sim/bin so the Windows preset's import pass on Linux sees the .so and the export packs the .dll"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - tools/native_build.sh

key-decisions:
  - "Owner decision 2026-10-19 (Task 1 checkpoint): option-a, CI builds both libraries from the pinned sources. Options B (mingw-w64 cross-compile) and C (DLL committed under Git LFS) were not built; native/cmake/mingw_w64_x86_64.cmake, .gitignore and .gitattributes are untouched"
  - "Failure logs of native-windows upload as windows-replay-logs, not native-*, so the export job's native-* download pattern can never pick them up"
  - "Git's usr/bin is put first on PATH in the Windows job (GITHUB_PATH, nothing installed) so find, sort and cygpath resolve to the GNU tools the scripts expect, as in the developer's Git Bash"
  - "Only the godot-cpp checkout is cached (key: OS plus the pin file), as the plan says; the cold build was 5 min on Linux and 9.5 min on Windows including the replays, so a build-directory cache was not added"

patterns-established:
  - "Same build script locally and in CI (bash tools/native_build.sh --fetch); a stale or missing library is exit 3 in every job"

requirements-completed: [PLAT-01]

coverage:
  - id: D1
    description: "CI builds the native library on Linux (GCC) and Windows (MSVC) from the pinned sources and hands it to test, screenshots and export; every job of the run is green"
    requirement: "PLAT-01"
    verification:
      - kind: integration
        ref: "https://github.com/ABSAR07/duskhold/actions/runs/39267563785 (headSha c420bef, conclusion success; lint, native-linux, native-windows, test, export, screenshots all success)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The native push-apart gives the same goldens on GCC and MSVC: smoke 2599c7c2, army f7a967ed, walls bfb05fc7, full_idle 4385f569 and the gate e448ffdb, each printed once by the Linux test job and once by native-windows"
    requirement: "PLAT-01"
    verification:
      - kind: integration
        ref: "build/ci-run.log: 4 REPLAY_OK per job (test, native-windows) and GATE_OK enemies=300 crossed=300 stuck=0 per job; digests identical across the two"
        status: pass
    human_judgment: false
  - id: D3
    description: "The CI-built Windows export carries the DLL next to Duskhold.exe and launches and quits inside 90 s on this machine"
    requirement: "PLAT-01"
    verification:
      - kind: other
        ref: "gh run download 39267563785 -n duskhold-windows -D build/ci-export; timeout 90 build/ci-export/Duskhold.exe --headless --quit-after 120 rc 0 (2.3 s)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The workflow keeps contents: read, every uses: pinned to a 40-character SHA (download-artifact included) and no secret"
    requirement: "PLAT-01"
    verification:
      - kind: other
        ref: "grep -q 'contents: read' ci.yml and no uses: line without @<40 hex>; grep secrets. finds only a comment"
        status: pass
    human_judgment: false
  - id: D5
    description: "Plan 04-13's overlay sits below the Night banner on the Linux fallback font in the CI screenshot"
    requirement: "PLAT-01"
    verification: []
    human_judgment: true
    rationale: "Layout adequacy of the CI overlay_field_gate.png was judged by reading the image (below); the layout test itself passed in the 1873-test suite, but a human may want to look at the picture"

duration: 26min
completed: 2026-10-19
status: complete
---

# Phase 4 Plan 16: CI Builds the Native Library Summary

**CI now builds libduskhold_sim with GCC on Linux and MSVC on Windows from the pinned sources (owner's option A), hands each library to the jobs that load it as a same-run artifact, and the very first native push-apart push went green on the first run: identical goldens and gate digests on both compilers, 1873 tests passing, and a CI-built Windows export that launches here.**

## Performance

- **Duration:** 26 min (dispatch 2026-10-19T14:13:38Z to about 14:39Z; the CI run itself took 17 min 57 s)
- **Tasks:** 2 (Task 1 checkpoint resolved by the owner before dispatch, Task 2 tracer)
- **Files modified:** 2 (.github/workflows/ci.yml, tools/native_build.sh)

## Task 1: owner decision (checkpoint resolved)

**Recorded choice: `option-a`, decided by the owner on 2026-10-19 at this plan's checkpoint (answered through the orchestrator before dispatch).** CI builds both libraries from the pinned sources.

Rationale, as the plan's option block gives it: nothing binary enters git (so no one-way door and no LFS history); a native-linux job (GCC) and a native-windows job (MSVC, the same compiler family as the development machine) build with tools/native_build.sh and pass the libraries to test, screenshots and export as artifacts of the same run; the native-windows job also replays the four goldens and the gate, so the DLL that ships is the DLL that was checked; free on a public repository. Costs accepted: two more jobs and a cold godot-cpp build per run (mitigated by caching the godot-cpp checkout), and one new pinned action. Options B (mingw-w64 cross-compile) and C (committed DLL under LFS) were not built; `native/cmake/mingw_w64_x86_64.cmake`, `.gitignore` and `.gitattributes` are untouched. For the later plans: the local MSVC build stays the development build, and no DLL needs re-committing after a C++ change (CI rebuilds it from the sources).

## Accomplishments

- `.github/workflows/ci.yml` gained `native-linux` (ubuntu-latest, 30 min: bootstrap Godot for linux, cache of `.tools/godot-cpp` keyed on the OS and `tools/godot_cpp_pin.txt`, `bash tools/native_build.sh --fetch`, upload of `addons/duskhold_sim/bin/` as `native-linux`) and `native-windows` (windows-latest, 45 min, `defaults: run: shell: bash`, the same steps with `--platform windows`, LFS pulled like the test job, upload as `native-windows`, then the four replays and `gate_stress.sh --twice` exactly as the test job runs them, with `build/replay/` and `build/stress/` uploaded as `windows-replay-logs` on failure).
- Wiring: test `needs: [native-linux]` and downloads it before the import; screenshots `needs: [test, native-linux]` and downloads it; export `needs: [lint, test, native-linux, native-windows]` and downloads both with `pattern: native-*` and `merge-multiple: true` into `addons/duskhold_sim/bin` before `tools/export.sh` (its import pass on Linux loads the .gdextension, so the .so must be there too). The header comments say which job builds what and that the token and pin rules still hold.
- `actions/download-artifact` pinned to `9000827ccba6bdab643e8b6fd33ac0654aef8333` (v8.0.2, the newest release by `git ls-remote --tags` on 2026-10-19; v8 sits on the same v4+ artifact backend as upload-artifact v7.0.1). Every other pin is unchanged; `permissions: contents: read` kept; no secret.
- `tools/native_build.sh` Linux branch: `cmake --build ... --parallel "$(nproc)"`, because without Ninja the generator is Unix Makefiles and builds one file at a time (found in the dry read of the Linux branch before the push).
- **The goldens hold across compilers.** The native Separation compiled with GCC for the first time in this run (`-Wall -Wextra -Werror`, `-ffp-contract=off`, clean) and the Linux test job's replays printed the same digests as the MSVC job, which are the pinned ones. No C++ change, no golden or pin touched.
- The CI-built Windows export (`duskhold-windows` artifact) holds `Duskhold.exe` (109268480 bytes), `Duskhold.pck` (1471040) and `libduskhold_sim.windows.x86_64.dll` (337408), and launched and quit here (`timeout 90 build/ci-export/Duskhold.exe --headless --quit-after 120`, rc 0, 2.3 s).

## CI evidence

- **Run:** https://github.com/ABSAR07/duskhold/actions/runs/39267563785, head `c420beff05a1386eee27451e08fefeedcf4e54c9`, conclusion `success`, first push, no fix cycle (0 of 3 used). The earlier green run for comparison was 38959046206 (a8c57ab).
- **Job durations (startedAt to completedAt):** lint 39 s; native-linux 5 min 17 s (cold, 14:17:10Z to 14:22:27Z); native-windows 9 min 35 s (cold, including the replays and the gate; 14:17:10Z to 14:26:45Z); test 9 min 36 s (14:22:30Z to 14:32:06Z); export 34 s; screenshots 2 min 55 s. Wall clock 17 min 57 s (14:17:07Z to 14:35:04Z).
- **Build lines (build/ci-run.log):**
  - `NATIVE_BUILD_OK platform=linux lib=libduskhold_sim.linux.x86_64.so godot_cpp=2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec api=4.7.2`
  - `NATIVE_BUILD_OK platform=windows lib=libduskhold_sim.windows.x86_64.dll godot_cpp=2bb1acf6f8ae1ce96ac7b9ba3a10b499c59c49ec api=4.7.2`
  - both jobs: `API diff: identical apart from the header (bundled 4.7.0, dumped 4.7.2)`
- **REPLAY_OK, Linux (GCC .so, job test) and Windows (MSVC .dll, job native-windows), identical lines:**
  - `REPLAY_OK scenario=smoke seed=1 outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f`
  - `REPLAY_OK scenario=army seed=1 outcome=won ticks=1353 digest=f7a967edc68054f2a75ae55a54100cfc3f069d8f3029e8299cd31fec7a8959c4`
  - `REPLAY_OK scenario=walls seed=1 outcome=won ticks=1961 digest=bfb05fc7e4c7b956eb8a6c3a16bdcaa546fd8558853878897704c32311ab8b58`
  - `REPLAY_OK scenario=full_idle seed=1 outcome=won ticks=6911 digest=4385f569c3e05d69d769fd6c75441637cd8543888d01cdabbcf08924cfdd2faf`
- **GATE_OK, both jobs, identical:** `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0 digest=e448ffdbd4d1ea8fcfd5c7b8c7dc3a257cd17b1ebdb52a6552cd7572efd5336a`
- **Full suite on CI (Linux, GCC library):** Scripts 200, Tests 1873, Passing 1873, Asserts 30965 (local baseline 200 / 1873 / 30942; the assert total moves between identical runs, see 04-22).
- **CI overlay screenshot review (overlay_field_gate.png from artifact duskhold-screenshots, opened with the Read tool):** on the Linux fallback font the debug overlay panel starts below the "Night 1 of 1 - 300 enemies left" banner and does not touch it; two columns (Perf/Loop/Agents/Wave/King/Paths, and Squads/Walls/Field/Crowd) all readable, nothing clipped. Plan 04-13's layout holds on Linux, so no spacing fix was needed.
- GitHub annotation on every ubuntu job: "The ubuntu-latest label will migrate to Ubuntu 26 beginning October 19, 2026" (runner-images issue 14748). Informational; this run already used the current image and passed. Watch the next runs for toolchain changes (GCC and CMake versions) when the label moves.

## Task Commits

1. **Task 1: owner decision (checkpoint)** - no commit; resolved by the owner (option-a), recorded above
2. **Task 2 (tracer): native-linux and native-windows jobs, artifact wiring, parallel Linux build** - `c420bef` (ci); pushed `a8c57ab..c420bef` with the permitted command after `bash tools/prepush_check.sh` passed; one run, green

**Plan metadata:** the docs commit that carries this SUMMARY (see git log).

## Files Created/Modified

- `.github/workflows/ci.yml` - native-linux and native-windows jobs, needs and download steps for test, screenshots and export, header comments, one new SHA-pinned action
- `tools/native_build.sh` - parallel cmake build in the Linux branch

## Decisions Made

See key-decisions: option-a recorded; failure logs not named native-*; Git usr/bin first on PATH on Windows; only the godot-cpp checkout cached.

## Deviations from Plan

None - plan executed exactly as written. (The `--parallel` edit to tools/native_build.sh is inside the plan's files_modified list and its step 2 job description; it came out of the planned dry read of the Linux branch, and the CI run proved the branch end to end.)

## Issues Encountered

None. The first push went green; no Linux-only digest difference, no GCC warning under `-Werror`, no overlay layout failure.

## Authentication Gates

None. `gh auth status` was logged in as ABSAR07 and the push used the credential-helper command only.

## Known Stubs

None.

## Threat Flags

None. T-04-40 (token and pins: `contents: read`, 40-character SHAs including download-artifact, no secret, prepush check before the push) and T-04-41 (artifacts built in the same run from the pinned sources, downloaded by name from that run only, the Windows job replaying the goldens on the DLL the export ships) are mitigated as planned; T-04-43 (export excludes native/*, tests/*, tools/*, addons/gut/*) unchanged. The extra step that writes a path to `$GITHUB_PATH` only prepends the runner's own Git tools directory.

## Notes for the next plans

- CI never needs a committed binary. After any edit under native/ the local library must be rebuilt (`bash tools/native_build.sh`, 25 to 40 s incremental) for the wrappers; CI rebuilds both from the sources on every run (about 5 min Linux, 9.5 min Windows with replays, cold godot-cpp).
- Before a push that touches native/ code, the Linux compile is only proven by CI (no GCC on this machine); the first run showed `-Wall -Wextra -Werror` clean for gd_math.h and native_separation.cpp, so later C++ should keep the same exact_port_rules and avoid constructs MSVC tolerates and GCC rejects (unused parameters and variables, sign-compare, implicit narrowing in brace init).
- Both libraries and both stamps are needed in addons/duskhold_sim/bin for the export job; a new job that runs the Windows preset must download `native-*` with merge-multiple as export does.

## Self-Check: PASSED

- `.github/workflows/ci.yml` and `tools/native_build.sh` exist and are tracked; `build/ci-export/Duskhold.exe` and `libduskhold_sim.windows.x86_64.dll` exist (untracked, git-ignored build output).
- Commit `c420bef` found in git log; `git rev-list --count 4874dba..HEAD` = 1 at the time of the run; run 39267563785 headSha equals `c420beff05a1386eee27451e08fefeedcf4e54c9`.
- The plan's automated verify chain exited 0 on HEAD c420bef before this SUMMARY commit: latest run is for HEAD and `success`; 2 REPLAY_OK per smoke, army, walls (and full_idle) and 2 GATE_OK; `NATIVE_BUILD_OK platform=linux` present; the CI export holds the DLL and launches; `contents: read` present and no unpinned `uses:`.
