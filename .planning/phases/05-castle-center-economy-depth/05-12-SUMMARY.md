---
phase: 05-castle-center-economy-depth
plan: 12
subsystem: testing
tags: [phase-gate, ci, screenshots, export, playtest-packet, godot, github-actions]

requires:
  - phase: 05-castle-center-economy-depth
    provides: plans 05-01 to 05-11 (stat stack, castle tiers and cards, gate, Mine, Mill, Harbor, Shrine, economy golden, balance report)
provides:
  - "The whole Phase 5 verified in one local sitting and on CI (run 39751537305, all six jobs green on the first push)"
  - "A launch-checked Windows export (build/windows/Duskhold.exe)"
  - "05-PLAYTEST-GATE.md: the owner's packet for /gsd-verify-work 5"
affects: [phase-05-verification, phase-06]

actuals:
  tokens: 14000
  tasks: 3
  commits: 3

plan_head_before: 82928bdeb1d8d74ad7c1a2bdf3ec0922799cd1f8
plan_head_after: a49e2beb27f18cb73471f66038a503c982ed9603

tech-stack:
  added: []
  patterns:
    - "Phase gate = local pass in one sitting, one push, CI watch, artifact review, export launch check, owner packet (the Phase 4 shape)"

key-files:
  created:
    - .planning/phases/05-castle-center-economy-depth/05-PLAYTEST-GATE.md
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "No presentation fix was made in the four declared files: the eleven local shots read; the HUD-banner overlap on a raised card, the cropped tier IV roof and the small buildings in economy_day are listed as owner open points instead"
  - "The only ci.yml change is one stale comment line (economy named beside smoke, army and walls); no timeout change was needed because the screenshots job passed on the first push"

patterns-established:
  - "Plan-head ledger: .git/gsd-plan-head-before-05-12 recorded before the first commit and read back at SUMMARY time"

requirements-completed: [BLDG-05, BLDG-08, BLDG-09, ECON-03, ECON-04, ECON-05, ECON-06, META-08, UI-02]

coverage:
  - id: D1
    description: "Full local pass in one sitting: suite, five replays, gate stress, all 44 screenshots, lint"
    verification:
      - kind: integration
        ref: "bash tools/test.sh (279 scripts, 2653 tests, 2653 passing); bash tools/replay.sh x5; bash tools/gate_stress.sh --twice; bash tools/screenshot.sh (44 PNGs); bash tools/lint.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "CI green on every job for the pushed HEAD, with REPLAY_OK for five scenarios, GATE_OK and 44 screenshots"
    verification:
      - kind: integration
        ref: "https://github.com/ABSAR07/duskhold/actions/runs/39751537305"
        status: pass
    human_judgment: false
  - id: D3
    description: "Launch-checked Windows build"
    verification:
      - kind: other
        ref: "bash tools/export.sh; timeout 90 build/windows/Duskhold.exe --headless --quit-after 120 (exit 0 in 8 s)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The castle cards read in world space and pick well by key and mouse, including re-appearing on every pass (A7, A10)"
    verification: []
    human_judgment: true
    rationale: "Legibility and feel; shots were reviewed but the owner judges the feel at /gsd-verify-work"
  - id: D5
    description: "The twelve abilities are worth a pick and distinct (D-02)"
    verification: []
    human_judgment: true
    rationale: "Numbers are Claude's draft; the bots never reach tiers III and IV; only the owner can judge worth"
  - id: D6
    description: "The four new buildings and the castle tiers make the day's gold decisions deeper and still fun (core value)"
    verification: []
    human_judgment: true
    rationale: "Bots only measure win rates; fun is a human judgment"

duration: 51min
completed: 2026-10-22
status: complete
---

# Phase 5 Plan 12: Phase Gate Summary

**The whole castle-and-economy phase passes locally (2653 tests, five replays, the gate stress, 44 screenshots) and on CI (run 39751537305, six jobs green on the first push), with a launch-checked Windows build and an owner packet of 23 numbered assumptions.**

## Performance

- **Duration:** 51 min
- **Started:** 2026-10-22T08:26:19Z
- **Completed:** 2026-10-22T09:17:00Z
- **Tasks:** 3
- **Files modified:** 2 (05-PLAYTEST-GATE.md created, ci.yml comment line)

## Accomplishments

- **Local pass (Task 1, commit `60d48ef`):** `bash tools/test.sh` gave 279 scripts, 2653 tests, 2653 passing, 60264 asserts, exit 0 in 876 s (no flake; the orchestrator's baseline quoted 60608 asserts, which I did not reproduce: my run counts 60264 asserts on the same 279 scripts and 2653 tests, all passing). The five replays agree twice in one process: smoke `2599c7c2` (703 ticks), army `f7a967ed` (1353), walls `bfb05fc7` (1961), economy `f4b98093` (1842) on their golden files, and `full_idle` won at 7000 ticks with digest `afc11cd0322cdaf3cc037a0ad2f595c5e4bff01fb85bc743cced5a240c84ed14`, which 05-BALANCE-REPORT.md records. The gate stress is `GATE_OK enemies=300 crossed=300 stuck=0 median_cross_s=14.93 max_cross_s=21.93 longest_flag_s=3.37 wall_hits=0`. All 44 screenshots saved with no script error; lint is clean (446 files unchanged). No golden moved, so no D-08 stop rule.
- **Push and CI (Task 2, commit `570ff8d`):** `bash tools/prepush_check.sh` passed, the push used the literal credential-helper command (`8f78ebe..570ff8d`), and CI run **https://github.com/ABSAR07/duskhold/actions/runs/39751537305** concluded success on lint, native-linux, native-windows, test, screenshots and export on the first push (no fix cycle, no timeout change). Its log has `REPLAY_OK` for smoke, army, walls, economy and full_idle twice each (Linux test job and the Windows library, so the economy golden's first GCC and MSVC runs match the local digest) and `GATE_OK enemies=300 crossed=300 stuck=0` twice; the artifact `duskhold-screenshots` holds 44 PNGs; `permissions: contents: read` is intact.
- **Export and packet (Task 3, commit `a49e2be`):** `bash tools/export.sh` printed `Export OK`; `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exited 0 in 8 s. 05-PLAYTEST-GATE.md carries the five sections, seven open points and 23 numbered assumptions.

### The eleven local shots (reviewed with the Read tool)

- `day_overview`: tier I keep top-centre, two Houses and two tower discs, banner and gold read.
- `spot_label`: "House I / +1 gold at dawn" over the plot, readable.
- `build_in_progress`: "Tower I / Range 9.0 · Damage 3" with coin dots filling.
- `dawn_payout`: coins fly to the counter at the dark dawn tint.
- `castle_cards`: four tier II cards with icons, key tiles and flavour; the pointed card is raised and shows its effect; the HUD banner overlaps the raised card's top edge (open point).
- `castle_tier_four`: tall tier IV keep, label "Castle IV / Max tier / Royal Training · Engineers · Golden Age"; roof tip and flag cropped at the default zoom (known from 05-04).
- `field_locked`: "Field I / +1 gold at dawn / Needs a Mill".
- `harbor_pond`: blue pond, three boats, dock reaching the hut, "+4 gold" after the payout.
- `shrine_awake_night`: awake Shrine with a pale-violet orb and a bolt in flight, tower arrows beside it.
- `castle_gate_locked`: "Tower II / Range 10.5 · Damage 6 / Needs Castle II".
- `economy_day`: the whole economy in one wide frame; the buildings are small at that zoom.

### The seven Phase 5 CI shots (Compatibility renderer, flatter and lighter, same content)

- `castle_cards`: same four cards and raised Commander, lighter ground; the banner overlap is the same.
- `castle_tier_four`: same keep, paler stone; roof tip cropped as locally.
- `field_locked`: same label, sandy plots lighter.
- `harbor_pond`: a brighter blue pond, three boats and the dock; reads.
- `shrine_awake_night`: orb, bolt and arrows visible; flatter lighting.
- `castle_gate_locked`: "Needs Castle II" label reads; the tower is lighter.
- `economy_day`: Harbor, Mine, Mill and Fields all in frame, same as local.

## Task Commits

1. **Task 1: local pass, the eleven shot reviews and the packet's check section** - `60d48ef` (docs)
2. **Task 2: push, CI watch, artifact review** - `570ff8d` (chore: the one-line CI comment update that rode the push; the CI result itself needs no commit)
3. **Task 3: export, launch check and the completed packet** - `a49e2be` (docs)

**Plan metadata:** the commit that adds this SUMMARY (docs: complete plan).

## Files Created/Modified

- `.planning/phases/05-castle-center-economy-depth/05-PLAYTEST-GATE.md` - the owner's gate packet
- `.github/workflows/ci.yml` - one comment line: the economy golden named beside smoke, army and walls; permissions, secrets and every pinned `uses:` SHA unchanged

## Decisions Made

- No change to card_row.gd, spot_label.gd, pond_view.gd or building_views.gd: every readability problem seen (banner over a raised card, cropped tier IV roof, small buildings in the wide shot) is either known from 05-04 or a camera-distance matter, and each is a feel call listed for the owner instead of a rushed offset change.
- The packet lists seven open points apart from the assumptions so the owner sees what Claude saw and left.

## Deviations from Plan

None - plan executed exactly as written. The ci.yml comment edit is the comment-only fix the dispatch note allowed; no timeout change or other CI fix was needed.

## Issues Encountered

- **Assert total differs from the dispatch baseline:** 60264 here against 60608 quoted; scripts (279), tests (2653) and passes (2653) are identical and the suite exited 0. Left as an observation; the count is a GUT total that does not gate anything.
- The `ubuntu-latest` to Ubuntu 26 notice appears as an annotation on the lint and native-linux jobs only; every job passed, so the screenshots job's apt packages worked.

## Authentication Gates

None (`gh auth status` exited 0 before the push).

## User Setup Required

None - no external service configuration required.

## Known Stubs

None found in the two files this plan touched.

## Threat Flags

None - no new network endpoint, auth path or file access; T-05-23 (ci.yml untouched beyond a comment, contents: read, pinned SHAs, verbatim push command) and T-05-24 (export demands the stamped native DLL, launch check run) are mitigated as planned.

## Next Phase Readiness

- Wave 11 of 11 is complete; the verifier runs next. The three backstop truths (cards read and pick well, twelve abilities worth a pick, the economy deepens the day) are owner feel items answered at `/gsd-verify-work 5` from 05-PLAYTEST-GATE.md.
- Open owner points that may become gap plans: Shrine reach and plot, Harbor dominance, castle tier III and IV reach, the card-row banner overlap and dismiss, the cropped tier IV roof.

## Self-Check: PASSED

- 05-PLAYTEST-GATE.md exists with all five sections and the balance report reference.
- Commits `60d48ef`, `570ff8d` and `a49e2be` exist and `git rev-list --count 82928bd..HEAD` gave 3 before this SUMMARY.
- `build/windows/Duskhold.exe`, `Duskhold.pck` and `libduskhold_sim.windows.x86_64.dll` exist; CI run 39751537305 concluded success for HEAD at the time of the check.

---
*Phase: 05-castle-center-economy-depth*
*Completed: 2026-10-22*
