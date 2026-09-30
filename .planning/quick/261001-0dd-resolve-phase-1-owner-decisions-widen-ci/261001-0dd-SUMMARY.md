---
phase: quick-261001-0dd
plan: 01
subsystem: attribution-and-ci
tags: [licence, attribution, ci, github-actions]
requires: []
provides:
  - "Horse licence keep decision recorded in ASSETS.md, License.txt and attribution.json (ART-02)"
  - "CI triggers on every push to any branch or tag, plus pull_request and workflow_dispatch (DEV-02)"
affects: [ASSETS.md, assets/attribution.json, assets/third_party/quaternius_horse/License.txt, .github/workflows/ci.yml]
key-files:
  modified:
    - ASSETS.md
    - assets/attribution.json
    - assets/third_party/quaternius_horse/License.txt
    - .github/workflows/ci.yml
decisions:
  - "Owner keeps the Quaternius horse, recorded as CC0-1.0 (2026-10-01 re-check)"
  - "CI push trigger has no branch filter; pull_request (never pull_request_target) kept"
metrics:
  tasks: 2
  completed: 2026-10-01
status: complete
commits: 2
plan_head_before: f5cfdfe7aba5e4a6c08c44c14df2346ffb78ddb1
plan_head_after: bfe3c972059e5fdf8ae9fd9d0d7bda4147066c55
actuals:
  tokens: 6000
  tasks: 2
  commits: 2
---

# Quick Task 261001-0dd: Resolve Phase 1 owner decisions, widen CI Summary

Horse licence re-check and keep decision recorded in all three attribution records, and CI widened to run on every push to any branch or tag with permissions, concurrency and jobs untouched.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 (tracer) | Record horse licence re-check and keep decision (ART-02) | 622a93b |
| 2 | Run CI on every push to any branch or tag (DEV-02) | bfe3c97 |

## What changed

- `ASSETS.md`: the "Horse licence caveat" section is now "Horse licence: re-checked and kept (2026-10-01)" with the 2026-09-29 evidence, the re-check and the owner decision. Nothing else in the file changed.
- `License.txt`: insertions only (11 lines): re-check and decision blocks above the unchanged `Licence:` line.
- `attribution.json`: one line differs (quaternius-horse `notes`); `retrieved` stays 2026-09-29, all other fields, ids and ordering unchanged.
- `ci.yml`: `push:` has no branch filter; header comment rewritten. Everything from `permissions:` to EOF is byte-identical to f5cfdfe.

## Verification

- `test_attribution_log.gd` 17/17; full GUT suite 290/290; `tools/lint.sh` clean.
- ci.yml triggers parse as exactly push, pull_request, workflow_dispatch; no `pull_request_target`, no secrets context reference (T-01-07 holds).
- Files changed since f5cfdfe outside `.planning/`: only the four plan files; `.planning/phases/` untouched; `.planning/config.json` left modified and unstaged.
- No Godot process left running. Nothing pushed.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

Commits 622a93b and bfe3c97 exist; all four files verified.
