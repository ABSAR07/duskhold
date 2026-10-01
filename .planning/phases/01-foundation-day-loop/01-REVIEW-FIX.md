---
phase: 01-foundation-day-loop
fixed_at: 2026-10-01T08:16:05Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-10-01T08:16:05Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1 (review-fix pass 26)

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

All three findings were documentation fixes. Only the `quaternius-horse` entry's `notes` in
`assets/attribution.json` changed; no other field and no ASSETS.md table row was touched. All three files remain
pure ASCII.

**Verification:** run in the main checkout (not an isolated worktree; the orchestrator's run was sequential and
the tests need the main checkout's Godot import cache and `addons/gut`). `bash tools/test.sh
-gselect=test_attribution_log.gd` passed 17/17 after each fix. The full suite `bash tools/test.sh` passed
290/290 (36 scripts) after the last commit. No Godot process was left running. The pre-existing uncommitted
change to `.planning/config.json` was left alone and never staged.

## Fixed Issues

### WR-01: "Not redistributed as a standalone asset" is inaccurate for a public repository

**Files modified:** `ASSETS.md`, `assets/attribution.json`, `assets/third_party/quaternius_horse/License.txt`
**Commit:** f84de3b
**Applied fix:** Replaced the "used inside a game, not redistributed as a standalone asset" wording in all three
records with the accurate position. The unmodified GLB is also committed (Git LFS) to the public repository
ABSAR07/duskhold and ships in the exported build. CC0 allows both. If the Quaternius Asset License governed
instead, the public copy could count as the "standalone asset" redistribution it forbids. The owner also accepts
this risk (2026-10-01). The owner's two decisions (keep the horse and accept the licence risk; accept the
public, unmodified GLB) were made on 2026-10-01 and are recorded as the owner's, not the fixer's. All quoted
source wording, dates, the CC0-1.0 classification and the keep decision were left as they were.
**Status:** fixed (wording of a record, no logic; no human verification needed beyond the owner's own decisions)

### IN-01: "How to add an asset" still describes `sha256` as always "of the downloaded archive"

**Files modified:** `ASSETS.md`
**Commit:** 49fb595
**Applied fix:** Step 4 now reads "`sha256` (of the downloaded archive, or of the file itself when there is no
archive; say which in `notes`, see "Archive checksums and download evidence" above)".

### IN-02: The same source page is quoted two ways

**Files modified:** `ASSETS.md`, `assets/attribution.json`, `assets/third_party/quaternius_horse/License.txt`
**Commit:** 70f4030
**Applied fix:** Following the orchestrator's instruction not to fetch any external site and not to rewrite
either quote, left both quotes ("License CC0" for 2026-09-29, "License: CC0" for 2026-10-01) verbatim and added
a short note beside them in all three records. The note says they are the same licence line transcribed on
different dates, that the 2026-10-01 re-check came from a web-to-markdown fetch which may have added the colon,
and that both name CC0. Neither record can establish whether the colon is page text or formatting, and the note
does not claim to.

---

_Fixed: 2026-10-01T08:16:05Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
