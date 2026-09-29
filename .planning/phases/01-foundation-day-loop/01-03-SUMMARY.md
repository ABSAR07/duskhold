---
phase: 01-foundation-day-loop
plan: 03
subsystem: infra
tags: [godot, github-actions, ci, windows-export, git-lfs, gh-cli]

requires:
  - phase: 01-foundation-day-loop
    provides: "01-01 toolchain (tools/bootstrap.py, test.sh, lint.sh, _common.sh, godot_sha512sums.txt); 01-02 simulation core and GUT suite that CI runs"
provides:
  - "Command-line Windows export (export_presets.cfg + tools/export.sh) that produces build/windows/Duskhold.exe + Duskhold.pck with no Wine/rcedit"
  - "tools/prepush_check.sh: blocks pushes that would publish local tooling, generated output, credential-shaped strings or unrouted large binaries; prints author identities"
  - ".github/workflows/ci.yml: lint, test (headless GUT) and export jobs on every push, export gated by needs [lint, test], read-only token, no secrets"
  - "Public repository https://github.com/ABSAR07/duskhold with origin set and the phase branch pushed"
  - "A green CI run producing the downloadable duskhold-windows artifact and the gut-results artifact"
affects: [01-09 screenshot CI job, 01-10, phase-13 release/itch.io pipeline]

actuals:
  tokens: 3500
  tasks: 3
  commits: 1
plan_head_before: 8add2d85ac385b4e1854456e26eb1e86c8dd7290
plan_head_after: f0e665b

tech-stack:
  added: [github-actions (checkout@v7, setup-python@v7, cache@v6, upload-artifact@v7)]
  patterns:
    - "Same wrapper scripts locally and in CI (bash tools/test.sh, bash tools/export.sh, bootstrap.py)"
    - "Shared LFS-cache pattern: checkout without LFS, hash the LFS object list, cache .git/lfs, then git lfs pull"
    - "Pre-push safety gate run before every push to a public remote"

key-files:
  created:
    - export_presets.cfg
    - tools/export.sh
    - tools/prepush_check.sh
    - .github/workflows/ci.yml
  modified:
    - tools/bootstrap.py

key-decisions:
  - "Owner chose to publish ABSAR07/duskhold and push only the phase branch gsd/phase-01-foundation-day-loop (not master, no tags)"
  - "Local absolute paths (C:/Users/burha/...) in the 10 tracked PLAN files were accepted as-is"
  - "GitHub default branch is the phase branch (first pushed); owner can switch it to master after merging"

requirements-completed: [DEV-02]

coverage:
  - id: D1
    description: "Windows export from the command line: bash tools/export.sh produces Duskhold.exe (109,268,480 B) and Duskhold.pck (50,204 B) with no rcedit/missing-template lines and no tests/GUT/tools packed; the release exe boots headless and exits 0"
    requirement: "DEV-02"
    verification:
      - kind: e2e
        ref: "bash tools/export.sh && build/windows/Duskhold.exe --headless --quit-after 120"
        status: pass
    human_judgment: false
  - id: D2
    description: "CI workflow with independent lint and test jobs and an export job gated by needs [lint, test]; no path filters; permissions contents read; uploads duskhold-windows"
    requirement: "DEV-02"
    verification:
      - kind: e2e
        ref: "gh run 36550012976 (ci.yml on gsd/phase-01-foundation-day-loop @ 88a39c2): lint, test, export all success"
        status: pass
    human_judgment: false
  - id: D3
    description: "Pre-push safety check blocks tooling, generated output and credential-shaped strings across all history and lists author identities"
    verification:
      - kind: other
        ref: "bash tools/prepush_check.sh (exit 0 on real history; exit 1 on scratch repo with committed settings.local.json + fake ghp_ token, token masked)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Public repo published under the owner-approved name with only the approved branch pushed"
    verification:
      - kind: other
        ref: "gh repo view ABSAR07/duskhold --json visibility -> PUBLIC; git ls-remote --heads origin -> only gsd/phase-01-foundation-day-loop; no tags"
        status: pass
    human_judgment: true
    rationale: "Publication is a one-way door decided by the owner at the blocking Task 2 checkpoint; automation only confirms the resulting state"

duration: 71 min wall clock (includes the owner-decision wait between Task 1 and Task 3)
completed: 2026-09-29
status: complete
---

# Phase 1 Plan 03: Windows export, pre-push check and CI Summary

**Command-line Windows export, a credential/tooling pre-push gate, and a GitHub Actions lint/test/export pipeline that went green on its first run on the newly published public repo ABSAR07/duskhold, producing a downloadable `duskhold-windows` artifact.**

## Performance

- **Duration:** 71 min wall clock (includes the owner-decision wait)
- **Started:** 2026-09-29T08:24:49Z
- **Completed:** 2026-09-29T09:36Z
- **Tasks:** 3 (Task 1 auto, Task 2 owner decision, Task 3 auto)
- **Files modified:** 5 (4 created, 1 modified)

## Accomplishments

- `bash tools/export.sh` exports the Windows build headlessly: `build/windows/Duskhold.exe` (109,268,480 B) and `Duskhold.pck` (50,204 B). There are no rcedit or missing-template log lines, and no tests, GUT or tools are packed. The release exe boots with `--headless --quit-after 120` (exit 0, about 6 s).
- `tools/prepush_check.sh` guards the one-way publication step (T-01-06). It blocks tracked tooling and generated output, credential-shaped strings anywhere in history across all refs, and large binaries not routed through LFS. It prints the tracked tree and author identities. It was proven to fail on a scratch repo with a committed `.claude/settings.local.json` and a fake `ghp_` token (exit 1, token masked).
- `.github/workflows/ci.yml` runs `lint`, `test` and `export` on every push, with no path filters. `lint` and `test` are independent, and `export` has `needs: [lint, test]`. The token is `permissions: contents: read`, there are no secrets, and the trigger is `pull_request`, never `pull_request_target`.
- The public repo now exists and CI is green on the first run. The Linux export (the real test of assumption A2, `application/modify_resources`) passed `tools/export.sh`'s no-rcedit/no-missing-template checks.

## Owner Decision (Task 2, checkpoint:decision, gate=blocking-human), verbatim

- Publish: "ABSAR07/duskhold, phase branch (Recommended)"
- Local paths: "Accept as-is (Recommended)"

Effect: the plan's `master` wording for Task 3 was replaced by the phase branch throughout. The public repo `ABSAR07/duskhold` was created and ONLY `gsd/phase-01-foundation-day-loop` was pushed. It contains master's history. `master` was not pushed, no tags were pushed and no other refs were pushed. The `C:/Users/burha/...` absolute-path lines in the 10 tracked PLAN files were left untouched.

## Publication and CI Record

- **Repo URL:** https://github.com/ABSAR07/duskhold (visibility PUBLIC)
- **origin:** `https://github.com/ABSAR07/duskhold.git`
- **Pushed ref:** `gsd/phase-01-foundation-day-loop` only (`git ls-remote --heads origin` shows just this branch; no tags)
- **What became public** (`tools/prepush_check.sh` on the pushed history): 378 tracked files, 25 commits across all refs, a single author identity `Ahmad Burhan Sarfraz <115086070+ABSAR07@users.noreply.github.com>` (GitHub noreply address), and a clean credential scan.
- **CI run:** https://github.com/ABSAR07/duskhold/actions/runs/36550012976 (run ID 36550012976, head 88a39c2, matches the local HEAD at push time). Jobs `lint`, `test` and `export` all succeeded on the first attempt, so no fix cycles were needed.
- **Artifacts:** `duskhold-windows` (39,002,879 B) and `gut-results` (4,828 B).
- **Default branch:** GitHub's default branch is now `gsd/phase-01-foundation-day-loop`, because it was the first branch pushed. The owner can switch it to `master` after merging.

## Task Commits

1. **Task 1: Command-line Windows export, pre-push safety check, and the CI workflow** - `f0e665b` (feat)
2. **Task 2: Owner decides the public repository name** - decision only, no commit
3. **Task 3: Create the approved public repo, push, watch CI** - no code changes were needed (CI green on the first run); the actions were `gh repo create`, `git push` and observing the run

**Plan metadata:** the `docs(01-03)` commit that carries this SUMMARY, STATE.md, ROADMAP.md and REQUIREMENTS.md.

Note: commits 31ddc13, 9eb8e8d, a7b25f3, 6fb92c3 and 88a39c2 (plan 01-04) landed on the branch between Task 1 and Task 3. They are not part of this plan and are not counted in `actuals.commits`. `plan_head_after` is therefore the last 01-03 production commit, `f0e665b`.

## Files Created/Modified

- `export_presets.cfg` - "Windows Desktop" preset: `modify_resources=false` (no rcedit/Wine), `embed_pck=false`, x86_64, excludes `tests/*, addons/gut/*, tools/*`
- `tools/export.sh` - headless export with artifact checks (exit status, exe > 1 MB, pck present, no rcedit/missing-template log lines)
- `tools/prepush_check.sh` - the public-push safety gate
- `.github/workflows/ci.yml` - lint, test and export jobs with LFS and Godot caching
- `tools/bootstrap.py` - `--templates` now skips when the Windows release template already exists (`--force` reinstalls) so the CI cache is effective

## Decisions Made

- Publish only the phase branch to the public repo (owner decision above); master stays local until the owner merges.
- Keep the export free of Wine/rcedit (`application/modify_resources=false`) since Phase 1 has no custom icon. A custom icon or version resource in a later phase will need rcedit or a Windows export step.
- One-off git credential override for the push (see Issues Encountered), rather than changing persistent git configuration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] GitHub Action major versions bumped to the current releases**
- **Found during:** Task 1 (workflow authoring)
- **Issue:** The plan pinned checkout@v4, setup-python@v5, cache@v4 and upload-artifact@v4, but the plan itself says to use a newer major if one exists.
- **Fix:** Used checkout@v7, setup-python@v7, cache@v6 and upload-artifact@v7 (the orchestrator confirmed these are the latest releases: v7.0.1, v7.0.0, v6.1.0, v7.0.1). All are from the `actions/` org, so T-01-07 still holds.
- **Files modified:** .github/workflows/ci.yml
- **Committed in:** f0e665b

**2. [Rule 1/3 - Bug/Blocking] `bootstrap.py --templates` was not idempotent**
- **Found during:** Task 1
- **Issue:** It re-downloaded the roughly 1.28 GB templates even when they were already present, which makes the CI Godot cache useless.
- **Fix:** It now skips when `editor_data/export_templates/*/windows_release_x86_64.exe` exists. `--force` reinstalls.
- **Files modified:** tools/bootstrap.py
- **Committed in:** f0e665b

**3. [Rule 3 - Blocking] Push authenticated as the wrong GitHub account**
- **Found during:** Task 3, step 3
- **Issue:** The first `git push` failed with 403: "Permission to ABSAR07/duskhold.git denied to absarfraz-tenx". Git's stored Windows credential (credential.helper `manager`) belongs to a different account. `gh` is correctly logged in as ABSAR07.
- **Fix:** Pushed with a one-off, non-persistent helper that uses the gh login: `git -c credential.helper= -c "credential.helper=!gh auth git-credential" push -u origin gsd/phase-01-foundation-day-loop`. No git or gh settings were changed and no credential was stored. This is still the owner-authorized action (push of the approved branch as ABSAR07).
- **Verification:** The push succeeded and LFS uploaded 9 objects. The remote has only the approved branch.
- **Committed in:** n/a (no file change)

---

**Total deviations:** 3 auto-fixed (1 Rule 3 versions, 1 Rule 1/3 bootstrap idempotence, 1 Rule 3 credential account)
**Impact on plan:** No scope creep. No fix cycles were needed after the first push.

## Issues Encountered

- The machine's stored git credential is a different GitHub account (absarfraz-tenx). Any further push to `ABSAR07/duskhold` from this machine needs the one-off helper above, or the owner can run `gh auth setup-git` to make git use the gh login permanently. This was not done here because it changes the owner's global git config.
- Assumption A2 (`application/modify_resources` key name) could not be confirmed from the Windows log. The Linux CI export is the real test, and it passed all export.sh checks (no rcedit, no missing template).
- CI annotation (informational, not a failure): `ubuntu-latest` migrates to Ubuntu 26 beginning October 19, 2026. If a later run fails after that date, pin `ubuntu-24.04` or re-verify the Godot Linux binary and LFS steps.

## Known Stubs

None.

## Threat Flags

None. The new surface (public repo, CI workflow) is the one in the plan's threat model. T-01-06 was mitigated by running `tools/prepush_check.sh` on the current history immediately before publication. T-01-07 is met: `permissions: contents: read`, `pull_request` trigger, no secrets, first-party actions only. T-01-SC is met: CI runs the same checksum-verifying bootstrap.

## User Setup Required

None required. Optional: run `gh auth setup-git` (owner's choice) so plain `git push` uses the ABSAR07 login, and switch the GitHub default branch to `master` after merging the phase branch.

## Next Phase Readiness

- DEV-02 is observable: every push now runs lint, test and export in CI, and a Windows build artifact is downloadable from the run.
- Plan 01-09's CI screenshot job can extend this workflow.
- Pushing further commits needs the credential override described above.

---
*Phase: 01-foundation-day-loop*
*Completed: 2026-09-29*

## Self-Check: PASSED

All five key files exist on disk, commit f0e665b exists, the workflow contains the required needs/lfs-assets-id/bootstrap strings, and the adapted verify passed against run 36550012976 (head SHA equals local HEAD at push time, conclusion success, duskhold-windows and gut-results present, repo PUBLIC).
