---
phase: 01-foundation-day-loop
reviewed: 2026-10-01T07:15:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .github/workflows/ci.yml
  - ASSETS.md
  - assets/attribution.json
  - assets/third_party/quaternius_horse/License.txt
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: issues_found
---

# Phase 1: Code Review Report

**Reviewed:** 2026-10-01T07:15:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Scope is the change since 8dd458c (quick task 261001-0dd): the CI push trigger lost its branch filter, and the horse licence re-check and keep decision was recorded in ASSETS.md, License.txt and attribution.json.

CI: the workflow change is correct and minimal. `push:` with no filter fires for every branch and tag; permissions, concurrency and jobs are unchanged. Push and pull_request runs use different `github.ref` values (`refs/heads/x` vs `refs/pull/N/merge`), so the concurrency group does not make them cancel each other. Tag pushes are cancellable by a newer push of the same tag, which is harmless. The header comment matches the behaviour. No CI findings.

Attribution: the horse record is identical across the three files (same dates, same quotes, same decision). The JSON is valid and the entry is still sorted by `id`. The ASSETS.md table row is unchanged, so `test_attribution_log` stays in sync. The only defect is in the reasoning the record gives for keeping the model, plus one older inaccuracy in ASSETS.md.

I did not re-fetch the quaternius.com or poly.pizza pages. The re-check statements ("still states License: CC0", "QAL v1.0 page says nothing about assets earlier released under CC0") are taken from the files as the owner's evidence and are not verified here.

## Warnings

### WR-01: Horse licence record cites the QAL "time you obtained" clause, but the retrieval date falls after the QAL took effect

**File:** `assets/third_party/quaternius_horse/License.txt:18-23`, `ASSETS.md:29-44`, `assets/attribution.json:96`
**Issue:** All three records quote the QAL v1.0 sentence "the version in effect at the time you obtained the Assets governs your use of them" and then justify CC0 by saying the model "was obtained as CC0". The same records state that QAL v1.0 was last updated 8/28/2026 and that the horse was retrieved on 2026-09-29, which is a month later. Read literally, the clause points at the QAL, not at the older CC0 terms, because the QAL was already live at retrieval. The CC0 position can still hold on a different ground: the 2021 pack was released under CC0 by its author, and the Poly Pizza and pack pages still state CC0 on the retrieval date. But the records never make that argument. They imply the clause supports the keep decision when it cuts the other way, so a later reader or itch.io reviewer would find the stated reasoning unsound. "The CC0 1.0 waiver is irrevocable" is also only true for a waiver the rights holder actually applied. Here the only evidence is third-party pages (Poly Pizza, and the pack page, which is first party but undated), not a dated copy of the 2021 release.
**Fix:** Add one sentence to each of the three records that says this openly. For example: "The QAL v1.0 (last updated 8/28/2026) predates the 2026-09-29 retrieval, so the 'time you obtained' clause does not by itself favour CC0. The keep decision rests on the author's own pack page and Poly Pizza page both stating CC0 on the retrieval date, and on the irrevocability of an earlier CC0 dedication (owner accepts this residual risk)." Optionally store a dated archive.org snapshot URL or screenshot of the pack page as durable evidence, and keep the three texts identical so they do not drift.

## Info

### IN-01: ASSETS.md says every SHA256 is of a downloaded archive, which is not true for the horse or GUT

**File:** `ASSETS.md:22-27`
**Issue:** "The SHA256 values above are of the archives exactly as downloaded ... The archives were deleted after extracting only the listed files". The horse hash is of the single GLB (no archive; the table cell says "of the GLB itself"), and the GUT hash is of the v9.7.1 source zip, which was not deleted but is vendored under `addons/gut/`. Godot has no SHA256 at all. This predates the change but sits in a file in scope, and it is the evidence section a reviewer would read to audit the hashes.
**Fix:** Reword to "The SHA256 values for the Kenney packs and GUT are of the archives as downloaded; the horse value is of the GLB itself (no archive exists)", or say "see each entry's `notes` for what the hash covers".

---

_Reviewed: 2026-10-01T07:15:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
