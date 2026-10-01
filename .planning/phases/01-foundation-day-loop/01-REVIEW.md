---
phase: 01-foundation-day-loop
reviewed: 2026-10-01T08:05:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - ASSETS.md
  - assets/attribution.json
  - assets/third_party/quaternius_horse/License.txt
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-10-01T08:05:00Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed review-fix pass 25 (commits 6cdf386, 1784ffe, 1ce2f94): the horse licence records and the ASSETS.md
checksum section. Both prior findings are resolved. The horse records no longer rely on the QAL "time you
obtained" clause, and ASSETS.md now says what each SHA256 covers.

Checked against the repo:
- The horse GLB hashes to `fae7a7ec...ce609` and is 1108124 bytes, matching the table, the manifest `sha256`
  and the notes.
- `GUT_ZIP_SHA256` in `tools/bootstrap.py` equals the manifest hash, and `GUT_ZIP_URL` is the GitHub tag zip.
- 01-07-SUMMARY.md lines 132 and 214 support the `curl --fail` / no-redirect / size-matched claim.
- The Mini Characters hash and URL match the 01-07 summary.
- `exclude_filter` in `export_presets.cfg` excludes `addons/gut/*`, matching `ships_in_build: false`.
- The three files agree with each other on dates, evidence wording and the decision.

The keep decision and the risk acceptance are the owner's and are not judged here. One factual claim in the
rationale does not match the repo (WR-01), and there are two minor wording inconsistencies. I could not
independently re-fetch the Quaternius and Poly Pizza pages, so the quoted page text is taken as recorded.

## Warnings

### WR-01: "Not redistributed as a standalone asset" is inaccurate for a public repository

**File:** `ASSETS.md:59-60`, `assets/third_party/quaternius_horse/License.txt:25`, `assets/attribution.json:96`
**Issue:** All three files justify the keep partly with "it is used inside a game, not redistributed as a
standalone asset". But `assets/third_party/quaternius_horse/horse_animated.glb` is tracked in git (via LFS) as an
unmodified standalone file, and `origin` is the public repo `ABSAR07/duskhold`. The ASSETS.md table also links the
original GLB. The QAL clause quoted in the same records forbids redistributing "the Assets themselves ... as a
standalone asset". Publishing the raw GLB in a public repository is arguably exactly that, so the stated
mitigation is contradicted by how the repo is published. The exported .pck also ships the GLB, extractable
unmodified. The owner has accepted the residual risk, but the record should not claim a mitigation that does not
hold. The other CC0 packs are unaffected, since CC0 allows redistribution.
**Fix:** Reword the sentence in all three places to state the real position, for example: "It is used inside a
game, but the unmodified GLB is also committed to the public repository and shipped in the build; the owner
accepts the residual risk if QAL were held to apply." Leave the CC0-1.0 classification and the keep decision as
they are.

## Info

### IN-01: "How to add an asset" still describes `sha256` as always "of the downloaded archive"

**File:** `ASSETS.md:76`
**Issue:** The new section above (lines 22-39) says the horse hash is of a single GLB, GUT's is of a source zip
that is not in the repo, and Godot has none. Step 4 of the checklist still says `sha256` (of the downloaded
archive), which is now partly wrong for the horse.
**Fix:** Change step 4 to "`sha256` (of the downloaded archive, or of the file itself when it was not an
archive; say which in `notes`)".

### IN-02: The same source page is quoted two ways

**File:** `ASSETS.md:45` and `ASSETS.md:49`; `assets/attribution.json:96`; `assets/third_party/quaternius_horse/License.txt:17` and `:29`
**Issue:** The 2021 pack page is quoted as `"License CC0"` for the 2026-09-29 check and as `"License: CC0"` for
the 2026-10-01 re-check, in all three files. A reader may wonder whether the page text changed between checks.
It looks like one transcription difference, but the records give no way to tell.
**Fix:** Use the verbatim page text in both places, or add "(punctuation as transcribed)".

---

_Reviewed: 2026-10-01T08:05:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
