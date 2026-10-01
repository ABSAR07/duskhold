---
phase: 01-foundation-day-loop
fixed_at: 2026-10-01T07:37:00Z
review_path: .planning/phases/01-foundation-day-loop/01-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 1: Code Review Fix Report

**Fixed at:** 2026-10-01T07:37:00Z
**Source review:** .planning/phases/01-foundation-day-loop/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: Horse licence record cites the QAL "time you obtained" clause, but the retrieval date falls after the QAL took effect

**Files modified:** `ASSETS.md`, `assets/third_party/quaternius_horse/License.txt`, `assets/attribution.json`
**Commit:** 6cdf386
**Applied fix:** All three records now say the same thing: the QAL v1.0 (last updated 8/28/2026) predates the 2026-09-29 retrieval, so its "version in effect at the time you obtained the Assets" clause does not by itself favour CC0. The keep decision rests on the author's 2021 pack page and the Poly Pizza page both stating CC0 at retrieval (checked 2026-09-29, re-checked 2026-10-01) and on an earlier CC0 dedication being irrevocable, and the owner accepts the residual risk (2026-10-01). The old "obtained as CC0" claims were reworded to rest on that, and all existing quotes and dates were kept. Only the `quaternius-horse` entry's `notes` changed in the JSON. The review's optional archive.org/screenshot suggestion was not taken (no external fetches, per the orchestrator's instruction). Documentation-only change; the reasoning in the records is for the owner to confirm.

### IN-01: ASSETS.md says every SHA256 is of a downloaded archive, which is not true for the horse or GUT

**Files modified:** `ASSETS.md`
**Commit:** 1784ffe, 1ce2f94 (follow-up, see below)
**Applied fix:** Rewrote the "Archive checksums and download evidence" paragraph as a per-entry list, checked against `assets/attribution.json` and the files on disk. The Kenney hashes cover the downloaded zips, which are not in the repo. The GUT hash covers the v9.7.1 source zip, whose contents are vendored under `addons/gut/` (no zip is present in the repo; the text does not claim anything about whether it was deleted). The horse hash covers the single GLB kept in the repo, and `sha256sum` on the file matches the table. Godot has no SHA256 and is verified by SHA512 via `tools/godot_sha512sums.txt`. The first commit dropped the `curl --fail` / no-redirect remark as unconfirmed.

Follow-up commit 1ce2f94 (`ASSETS.md` only, requested by the orchestrator) restored that evidence after it was confirmed in `01-07-SUMMARY.md` (lines 132 and 214: `curl --fail`, `redirects=0`, each size matched the owner-approved figure). It is scoped to the three Kenney zips and the horse GLB only. The GUT bullet now notes the zip came through `tools/bootstrap.py` (plan 01-01, per `01-01-SUMMARY.md` and the script), and nothing new is claimed about how Godot was downloaded.

## Verification

- Where it ran: the main checkout, not an isolated worktree (the work was documentation-only, and a worktree has no `.godot` import cache for the Godot test run). Files were staged by explicit path; the pre-existing uncommitted `.planning/config.json` change was left alone and never staged.
- `node` JSON.parse of `assets/attribution.json`: OK. The three files contain only ASCII.
- `bash tools/test.sh -gselect=test_attribution_log.gd`: 17/17 passing, run after each commit's edits.
- Full `bash tools/test.sh`: 36 scripts, 290/290 tests passing. No Godot process was left running.

---

_Fixed: 2026-10-01T07:37:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
