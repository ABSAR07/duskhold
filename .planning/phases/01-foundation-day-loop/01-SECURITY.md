---
phase: "1"
slug: "foundation-day-loop"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-09-29"
---

# Phase 1 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Built from the `<threat_model>` blocks of plans 01-01 to 01-10 and the SUMMARY threat flags (all ten report "None" beyond the planned surface). Verified after the code-review fixes.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Internet → local toolchain | Godot editor, export templates, GUT source and PyPI packages enter `.tools/` and `addons/gut/` | Executable binaries and code (high integrity sensitivity) |
| Agent → owner's machine | An autonomous executor could fetch large binaries or assets without consent | Downloads, disk writes (consent) |
| Working tree → git index → public GitHub | Everything staged and pushed becomes world-readable, permanent history (repo ABSAR07/duskhold is public) | Source, history, author identities; risk of credentials or local tooling leaking |
| GitHub Actions runner ↔ third-party actions and downloads | Workflow code, `actions/*`, PyPI, Godot releases and apt packages run with the workflow token | Code execution in CI; read-only token |
| Pull requests → CI | Untrusted contributor code could run in CI | Untrusted code |
| Device input → Input Map → simulation | Input becomes BuildIntent / StartNightIntent; the simulation must not trust the input layer's cached view | Local single-player input (integrity of game rules only) |
| Authored `.tres` data → simulation | First-party but hand-edited map and building data | Game data (integrity) |
| Third-party asset sites → repository and shipped build | Model files and their licences enter a public repo and the export | Binary assets, licence claims (legal/provenance) |
| Debug tooling → simulation | The overlay must never become a mutation surface, including in release exports | Read-only game state |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-01-01 | Tampering | `tools/bootstrap.py` editor + templates download | high | mitigate | SHA512 checked against official `SHA512-SUMS.txt` and the committed pin `tools/godot_sha512sums.txt`; mismatch deletes the file and exits 1 (`bootstrap.py` ~L193–262); `safe_members()` rejects absolute, `..`-escaping and symlink zip members | closed |
| T-01-02 | Elevation of Privilege | `tools/bootstrap.py` consent | medium | mitigate | Downloads require both a component flag and `--yes`; otherwise `return 2` ("Downloads require --yes (owner approval)"); owner approved the file list at the 01-01 Task 2 blocking checkpoint | closed |
| T-01-03 | Information Disclosure | `.gitignore` / staging | high | mitigate | `git check-ignore` confirms `.claude/settings.local.json`, `.claude/gsd-core/*`, `.tools/`, `.godot/` ignored and `.claude/CLAUDE.md` trackable; 0 tracked files under `.tools/` or `.godot/` | closed |
| T-01-SC (01-01) | Tampering | pip `gdtoolkit`, GUT source zip | high | mitigate | `tools/requirements-lint.txt` pins `gdtoolkit==4.5.0`; `GUT_TAG = "v9.7.1"`, `addons/gut/plugin.cfg` version 9.7.1; GUT zip SHA256 recorded and tied to the manifest by `test_bootstrap_gut_sha256_matches_the_manifest` | closed |
| T-01-04 | Tampering | `CommandProcessor.submit` / `Economy.try_spend` | medium | mitigate | `_submit_build` re-runs `validate_build` at apply time; `try_spend` refuses unaffordable or negative costs and changes nothing; since review-fix pass 5 `BuildingSystem.apply_next_tier` itself refuses an unknown building or a tier past the last; since pass 7 `get_instance`/`apply_next_tier` hand out snapshots, so no reader can mutate building state; `test_build_flow.gd`, `test_economy_gold.gd`, `test_building_system_data_errors.gd` green | closed |
| T-01-05 | Tampering | `BuildHoldController` partial-payment state | low | mitigate | Nothing is deducted while coins drip; completion goes through `commands.submit(BuildIntent)`; refund is a pure reset (D-06); `test_build_hold_refund.gd` green | closed |
| T-01-06 | Information Disclosure | First push / `tools/prepush_check.sh` | high | mitigate | Pre-push check scans current tree and `git log --all` for local tooling, generated output, credential-shaped values (plus gitleaks when installed) and >5 MB blobs, and prints identities for owner review; re-run 2026-09-29: PASSED | closed |
| T-01-07 | Elevation of Privilege | `.github/workflows/ci.yml` | medium | mitigate | `permissions: contents: read`; `pull_request` trigger only (no `pull_request_target`); no `secrets.` references; every action from the `actions/` org, pinned to a full commit SHA (stronger than the planned major tags; 17/17 `uses:` lines re-checked after the IN-04 change) | closed |
| T-01-08 | Denial of Service | Git LFS quota in CI | low | mitigate | `.git/lfs` cache keyed on `hashFiles('.lfs-assets-id')`; lint job checks out with `lfs: false` | closed |
| T-01-SC (01-03) | Tampering | CI Godot/templates/pip installs | high | mitigate | CI runs `python tools/bootstrap.py --godot [--templates] --yes --platform linux`, which verifies against the committed pin; lint installs `-r tools/requirements-lint.txt` (pinned) | closed |
| T-01-09 | Tampering | `project.godot` `[input]` | low | mitigate | `test_input_map.gd` fails on any mouse binding in a project action, any missing keyboard/gamepad binding, or binding-table drift; green | closed |
| T-01-10 | Tampering | `MapConfig` / `.tres` data | low | mitigate | `MapConfig.validate()` reports empty entries, duplicate/empty ids (building ids too since review-fix pass 2, WR-01), empty tier lists and non-positive costs (hardened by review fix IN-02); `BuildingSystem` skips null building/spot entries instead of crashing, and since pass 3 lists a duplicate spot id once (the first definition wins) and skips unknown building ids in dawn income; since pass 4 a duplicate building id also keeps the first definition and `spot_ids()` returns a copy; since pass 5 empty-id spots are skipped, and since pass 6 empty-id buildings too; `test_prototype_map_data.gd` and `test_building_system_data_errors.gd` green | closed |
| T-01-11 | Tampering | `BuildHoldController` completion after leaving range, phase change or loss of affordability | medium | mitigate | Focus lock on the active spot; every frame cancels if the key is released, the spot is out of `interaction_radius` or `is_build_allowed()` is false; `submit` re-validates at completion; `test_build_hold_refund.gd`, `test_build_denied.gd` green | closed |
| T-01-12 | Repudiation | `assets/attribution.json` licensing claims | medium | mitigate | `ALLOWED_LICENSES = ["CC0-1.0", "MIT"]` and full-coverage checks in `test_attribution_log.gd`; `License.txt` kept beside each of the 4 third-party asset folders; archive SHA256 on every model entry; source wording quoted in 01-07-SUMMARY | closed |
| T-01-13 | Tampering | IP exposure in game content | medium | mitigate | Plan-scoped check `git grep -il thronefall -- data simulation input presentation ui assets project.godot export_presets.cfg ASSETS.md` is clean; only Kenney/Quaternius sources used | closed |
| T-01-SC (01-07) | Tampering | CC0 archive downloads | high | mitigate | Owner approved exact URLs and sizes (01-07 Task 2); `curl --fail`; SHA256 recorded per archive in `attribution.json` (4 model entries); only chosen files extracted | closed |
| T-01-14 | Tampering | `RunManager` transitions and dawn payout | low | mitigate | `start_night()` returns false unless `_phase == DAY`; `test_only_the_run_manager_assigns_the_loop_phase` source-scan test; `CommandProcessor` rejects StartNightIntent outside DAY; `test_run_manager.gd`, `test_build_phase_guard.gd`, `test_loop_gold_carryover.gd` green | closed |
| T-01-15 | Elevation of Privilege | DebugOverlay in release builds | low | accept | See AR-01 (since pass 3 the read-only test watches all 7 simulation signals, and malformed provider rows are dropped) | closed |
| T-01-16 | Information Disclosure | `duskhold-screenshots` CI artifact | low | accept | See AR-02 (`retention-days: 7` confirmed in `ci.yml`; since IN-04 the upload runs `if: always()` and also carries `build/screenshot-import.log`) | closed |
| T-01-17 | Information Disclosure | `git push` of new history | high | mitigate | `bash tools/prepush_check.sh` before every push; re-run 2026-09-30 over all refs, including the 311 local commits not yet pushed: PASSED | closed |
| T-01-SC (01-10) | Tampering | apt packages on the CI runner | low | accept | See AR-03 | closed |
| T-01-SC (no-install plans) | Tampering | Package installs in 01-02, 01-04, 01-05, 01-06, 01-08, 01-09 | low | accept | See AR-04 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

The plans list T-01-SC seven times; the six identical "this plan installs no packages" acceptances are merged into the last row, leaving 22 register rows.

### Observations (non-blocking)

- **T-01-06 / T-01-17: enforcement is procedural.** `.git/hooks/pre-push` only runs Git LFS, so nothing forces `tools/prepush_check.sh` to run before a push. Run it before pushing the 311 pending local commits (it passes today). Optional hardening: call it from the pre-push hook.
- **T-01-12: residual licence risk.** The allow-list test trusts each entry's declared `license` field. The Quaternius horse is logged as CC0-1.0, based on the 2021 Poly Pizza CC0 statement, while Quaternius now publishes its own Asset License. That is review finding WR-06, disposition skipped, owner decision pending. It is also listed as a human verification item.
- **T-01-13: out-of-scope mention.** A comment on line 3 of `tools/_common.sh` names the local checkout folder, which contains the reference game's name. `tools/*` is not game content and is excluded from the export (`exclude_filter="tests/*, addons/gut/*, tools/*"`). The owner may still want to reword it before release.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-01-15 | The overlay only calls getters. `test_debug_overlay_readonly.gd` shows 200 collects change no state and emit no events. Leaving the F3 / gamepad-Back toggle in Phase 1 release builds therefore gives no gameplay advantage. Revisit gating before the Phase 13 release. | Plan 01-08 threat model (recorded in STATE.md decisions) | 2026-09-29 |
| AR-02 | T-01-16 | The screenshot artifact holds only the game's own frames of public content in a public repo, with 7-day retention. Since review fix IN-04 it also carries the Godot `--import` log: engine banner and import progress for the public repo's own files on an ephemeral runner, from a job with no secrets. | Plan 01-10 threat model; log added by review-fix pass 2 | 2026-09-29 |
| AR-03 | T-01-SC (01-10) | apt/Mesa packages come from Ubuntu's signed archive on an ephemeral runner, with no secrets in the job and a read-only token. Nothing is installed on the owner's machine. | Plan 01-10 threat model | 2026-09-29 |
| AR-04 | T-01-SC (01-02, 01-04, 01-05, 01-06, 01-08, 01-09) | These plans install no packages; the toolchain was pinned and owner-approved in 01-01. | Plan threat models | 2026-09-29 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-29 | 22 | 22 | 0 | secure-phase orchestrator (ASVS L1 grep-depth; short-circuit, no auditor spawn) |
| 2026-09-29 (re-audit) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 2) |
| 2026-09-29 (re-audit 2) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 3) |
| 2026-09-30 (re-audit 3) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 4) |
| 2026-09-30 (re-audit 4) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 5) |
| 2026-09-30 (re-audit 5) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 6) |
| 2026-09-30 (re-audit 6) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 7) |
| 2026-09-30 (re-audit 7) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 8) |
| 2026-09-30 (re-audit 8) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 9) |
| 2026-09-30 (re-audit 9) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 10) |
| 2026-09-30 (re-audit 10) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 11) |
| 2026-09-30 (re-audit 11) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 12) |
| 2026-09-30 (re-audit 12) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 13) |
| 2026-09-30 (re-audit 13) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 14) |
| 2026-09-30 (re-audit 14) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 15) |
| 2026-09-30 (re-audit 15) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 16) |
| 2026-09-30 (re-audit 16) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 17) |
| 2026-09-30 (re-audit 17) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 18) |
| 2026-09-30 (re-audit 18) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 19) |
| 2026-09-30 (re-audit 19) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 20) |
| 2026-09-30 (re-audit 20) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 21) |
| 2026-09-30 (re-audit 21) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 22) |
| 2026-09-30 (re-audit 22) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked mitigations touched by review-fix pass 23) |
| 2026-09-30 (re-audit 23) | 22 | 22 | 0 | secure-phase orchestrator (State A; re-checked after review-fix pass 24, test-only) |

## Security Audit 2026-09-29

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Evidence gathered for this audit: grep-level inspection of `tools/bootstrap.py`, `tools/prepush_check.sh`, `.github/workflows/ci.yml`, `export_presets.cfg`, `simulation/commands/command_processor.gd`, `simulation/economy/economy.gd`, `input/build_hold_controller.gd`, `simulation/defs/map_config.gd`, `simulation/run/run_manager.gd`, `assets/attribution.json`. Also: `git check-ignore` probes; full GUT suite 201/201 green; `tools/prepush_check.sh` PASSED; export and headless launch OK.

## Security Audit 2026-09-29 (re-audit after review-fix pass 2)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 10 fix commits (`83b1c10`..`a8b919e`):
- **T-01-07:** `ci.yml` is still `permissions: contents: read` with no `pull_request_target` and no secrets. All 17 `uses:` lines are SHA-pinned `actions/*`.
- **T-01-16:** the screenshot artifact is still on 7-day retention. It now also uploads the non-sensitive import log.
- **T-01-10:** strengthened. Empty building ids are reported, and null entries are skipped.
- **T-01-15:** the overlay stays read-only. The new non-Array guard only skips; the 200-collect snapshot test is still green.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 47 unpushed commits.
- **Tests:** full suite 206/206.

## Security Audit 2026-09-29 (re-audit after review-fix pass 3)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 7 fix commits (`ecea4ff`..`9cae015`):
- **T-01-10:** strengthened. Duplicate spot ids are skipped, and unknown building ids are read through `_defs.get()` with a null check.
- **T-01-15:** the overlay model still makes no mutating calls. Malformed rows are dropped, and the read-only test now watches all 7 `SimEvents` signals, with a guard against unwatched additions.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 62 unpushed commits.
- **CI:** `ci.yml` is unchanged in this pass, so T-01-07 and T-01-16 stand as last audited.
- **Tests:** full suite 215/215.

## Security Audit 2026-09-30 (re-audit after review-fix pass 4)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 8 fix commits (`2d8dd35`..`2fe6dc1`):
- **T-01-10:** strengthened. Duplicate building ids now keep the first definition, matching spots, and `spot_ids()` returns a copy.
- **T-01-15:** the overlay model still makes no mutating calls. Providers that need an argument are skipped.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 77 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 218/218.

## Security Audit 2026-09-30 (re-audit after review-fix pass 5)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 9 fix commits (`e83e5e0`..`17c661d`):
- **T-01-04:** strengthened. `apply_next_tier` refuses an unknown building or a tier past the last, with no mutation or event.
- **T-01-10:** strengthened. Empty-id spots are skipped.
- **T-01-15:** the overlay model still makes no mutating calls. Registering a title twice replaces the section.
- **New `payout_started` signal:** it is presentation-only (VFX to HUD) and adds no simulation write path.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 93 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 227/227.

## Security Audit 2026-09-30 (re-audit after review-fix pass 6)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 8 fix commits (`723080f`..`1c3e320`):
- **T-01-10:** strengthened. Empty-id buildings are skipped.
- **T-01-15:** the overlay model still makes no mutating calls. A skipped provider now triggers a `push_warning`, once per title.
- **New HUD `physical_label_resolver` seam:** it only maps a keycode to a display label (`DisplayServer.keyboard_get_label_from_physical`, headless-safe) and adds no simulation write path.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 108 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 232/232.

## Security Audit 2026-09-30 (re-audit after review-fix pass 7)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 6 fix commits (`b789dde`..`d4ef4f5`):
- **T-01-04:** strengthened. External reads get `BuildingInstance` snapshots via `_snapshot`, and only `apply_next_tier` mutates.
- **T-01-15:** the overlay model still makes no mutating calls. It now also warns once for a non-Array provider.
- **Payout VFX:** it coerces untyped amounts and still makes no simulation writes.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 121 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 235/235.

## Security Audit 2026-09-30 (re-audit after review-fix pass 8)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 5 fix commits (`60d4881`..`30d0dd4`), which changed only `ui/hud/dawn_payout_vfx.gd` and `ui/overlay/debug_overlay_model.gd`:
- **T-01-15:** the overlay model still makes no mutating calls. It counts buildings via the `current_tier` getter and refuses section titles that shadow a default section.
- **Payout VFX:** it validates payout keys and amounts, and still makes no simulation writes.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 133 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 237/237.

## Security Audit 2026-09-30 (re-audit after review-fix pass 9)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 6 fix commits (`7cd97d9`..`1a0bb93`), which changed only `ui/hud/dawn_payout_vfx.gd` and `ui/overlay/debug_overlay_model.gd`:
- **T-01-15:** the overlay model still makes no mutating calls. It drops a provider whose owner was freed after one warning.
- **Payout VFX:** it clamps amounts to ±`MAX_AMOUNT` so an overflow cannot defeat the coin cap, and still makes no simulation writes.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 146 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 241/241.

## Security Audit 2026-09-30 (re-audit after review-fix pass 10)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 4 fix commits (`f1806f5`..`c3905c7`), which changed only `ui/hud/dawn_payout_vfx.gd` and `ui/overlay/debug_overlay_model.gd`, plus tests:
- **T-01-15:** the overlay model still makes no mutating calls. Its only simulation calls are getters (`get_phase`, `get_day_number`, `get_night_number`, `get_gold`, `get_phase_time_remaining`, `spot_ids`, `current_tier`). Re-arming its one-shot warning touches only the model's own `_warned` dictionary.
- **Payout VFX:** the landing margin and the `start_point` guard are display-only. It still makes no simulation writes; it emits only its own `payout_started` and `coin_landed` presentation signals.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 157 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 243/243.

## Security Audit 2026-09-30 (re-audit after review-fix pass 11)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 3 fix commits (`a273e88`..`f66045f`), which changed only `ui/overlay/debug_overlay_model.gd`, `ui/overlay/debug_overlay.gd` and `ui/hud/dawn_payout_vfx.gd`, plus tests:
- **T-01-15:** the overlay model still makes no mutating calls; its only simulation calls are getters. The new optional `owner` argument of `register_section` is held as a `WeakRef`, so the overlay never keeps an owner alive; a section whose owner was freed is warned about once and dropped. `debug_overlay.gd` only forwards the argument.
- **Payout VFX:** reordered and re-documented only (test hooks grouped under a banner). It still makes no simulation writes.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 167 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 245/245.

## Security Audit 2026-09-30 (re-audit after review-fix pass 12)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 5 commits (`8ee2508`..`7e7a1f2`), which changed only `ui/overlay/debug_overlay.gd`, `ui/overlay/debug_overlay_model.gd` and `ui/hud/dawn_payout_vfx.gd`, plus tests:
- **T-01-15:** strengthened evidence. The overlay model still makes no mutating calls; its only simulation calls are getters.
  - Sections registered before `bind_run` are held with their owner as a `WeakRef` and replayed on bind. A repeat `bind_run` is ignored.
  - The 200-collect read-only check (AR-01's basis) now also runs by night and by dawn (`test_debug_overlay_timed_phases.gd`), not only by day.
- **Payout VFX:** it now counts and frees only its own coins (group `payout_coin`), and still makes no simulation writes.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 179 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 258/258.

## Security Audit 2026-09-30 (re-audit after review-fix pass 13)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 5 commits (`b223b55`..`6c38829`), which changed only `ui/overlay/debug_overlay_model.gd` and `ui/hud/dawn_payout_vfx.gd`, plus tests:
- **T-01-15:** strengthened evidence. The overlay model still makes no mutating calls; its only simulation calls are getters. Malformed provider rows now produce one warning per failure streak.
  - The night/dawn 200-collect read-only check (AR-01's basis) now also snapshots every spot's tier and the unit/enemy counts.
- **Payout VFX:** a payout that claims no gold but lists per-spot amounts now warns. It still makes no simulation writes; the only emits are its own `payout_started` and `coin_landed` presentation signals.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 191 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 260/260.

## Security Audit 2026-09-30 (re-audit after review-fix pass 14)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 5 commits (`24f0e1e`..`3f3ee45`), which changed only `ui/overlay/debug_overlay_model.gd`, plus tests and the new test-only `tests/support/sim_signals.gd`:
- **T-01-15:** the overlay model still makes no mutating calls; its only simulation calls are getters. Skip handling now branches on `Skip` codes rather than message text, with no change to what is shown or dropped.
  - The read-only suites (AR-01's basis) now watch one shared, drift-guarded `SimSignals.ALL` list, so a new `SimEvents` signal cannot be silently left unwatched by the night/dawn checks.
- **Export surface:** `tests/support/` is test-only and falls under the export's `exclude_filter` (`tests/*`), so it never ships.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 203 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 260/260.

## Security Audit 2026-09-30 (re-audit after review-fix pass 15)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 6 commits (`639f5fd`..`4fac944`), which changed only `ui/overlay/debug_overlay_model.gd` and `ui/overlay/debug_overlay.gd`, plus tests and the new test-only `tests/support/overlay_test_support.gd`:
- **T-01-15:** the overlay model still makes no mutating calls; its only simulation calls are getters.
  - The one-shot warning is now keyed by the kind of problem.
  - `register_section` refuses an already-freed `lifetime_owner` with a warning instead of a script error. Its owner is still held only as a `WeakRef`.
  - The 200-collect read-only assertion (AR-01's basis) now lives in the shared helper, used by the day, night and dawn checks.
- **Export surface:** `tests/support/` stays under the export's `exclude_filter` (`tests/*`).
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 216 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 265/265.

## Security Audit 2026-09-30 (re-audit after review-fix pass 16)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 3 commits (`187f47a`..`49f4ae9`), which changed only `ui/overlay/debug_overlay.gd` and `ui/overlay/debug_overlay_model.gd`, plus tests and the test-only `tests/support/overlay_test_support.gd`:
- **T-01-15:** the overlay model still makes no mutating calls; its only simulation calls are getters.
  - Owner checks are now one shared static helper (`owner_problem`, `owner_ref`, `warn_not_registered`). A non-Object owner is refused, and an accepted owner is still held only as a `WeakRef`.
  - `get_text()` returns "" before the overlay is ready.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 226 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 268/268.

## Security Audit 2026-09-30 (re-audit after review-fix pass 17)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 3 commits (`457e334`..`8a440c0`), which changed only `ui/overlay/debug_overlay.gd` and `ui/overlay/debug_overlay_model.gd`, plus tests and the test-only `tests/support/overlay_test_support.gd`:
- **T-01-15:** the overlay model still makes no mutating calls; its only simulation calls are getters.
  - The view now keeps the `RunContext` it was bound to, but only to compare against a repeat `bind_run`, which warns. It makes no calls on it.
  - Default titles are refused before `bind_run` too.
- **Test isolation:** the shared overlay test helper now deep-copies building definitions and tiers. Test runs cannot leak edits into the cached map resources, which strengthens the read-only evidence behind AR-01.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 236 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 275/275.

## Security Audit 2026-09-30 (re-audit after review-fix pass 18)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 4 commits (`546c3dc`..`c886c04`), which changed only `ui/overlay/debug_overlay.gd` and `ui/overlay/debug_overlay_model.gd`, plus tests and the test-only `tests/support/overlay_test_support.gd`:
- **T-01-15:** the overlay model still makes no mutating calls; its only simulation calls are getters.
  - `bind_run` with no `RunContext` is refused with a warning and leaves the overlay unbound.
  - Rows must be exactly [label, value]; longer rows are dropped and counted.
- **Test isolation:** the shared helper now deep-copies tuning as well as the map.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 247 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 276/276.

## Security Audit 2026-09-30 (re-audit after review-fix pass 19)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 4 commits (`a7d732d`..`79b4513`), which changed only doc comments and one local variable name in `ui/overlay/debug_overlay.gd` and `ui/overlay/debug_overlay_model.gd`, plus tests:
- **T-01-15:** the overlay model still makes no mutating calls; its only simulation calls are getters. The `lifetime_owner` doc now states its RefCounted limit, pinned by tests, and there is no behaviour change.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 258 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 279/279.

## Security Audit 2026-09-30 (re-audit after review-fix pass 20)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 4 commits (`66e7307`..`9ef9e59`), which changed only `ui/overlay/debug_overlay.gd`, plus two test files:
- **T-01-15:** the overlay still makes no mutating calls on the simulation; the model's only simulation calls are getters. A section registered twice before `bind_run` now replaces its pending entry in place, and owners are still held only as `WeakRef`s.
- **Test isolation:** the map-copy test restores the cached map it writes to.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 269 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 283/283.

## Security Audit 2026-09-30 (re-audit after review-fix pass 21)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 6 commits (`8c56d50`..`6b073d9`), which changed only `ui/overlay/debug_overlay.gd` and `ui/overlay/debug_overlay.tscn`, plus three test files:
- **T-01-15 / AR-01:** the overlay still makes no mutating calls on the simulation; the model's only simulation calls are getters. Two changes, neither of which gives the overlay any write path:
  - `bind_run` refreshes an already-visible overlay at once.
  - The overlay scene now uses `process_mode = PROCESS_MODE_ALWAYS`, so F3 and the refresh keep working while the tree is paused.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 282 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 286/286.

## Security Audit 2026-09-30 (re-audit after review-fix pass 22)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked the mitigations touched by the 4 commits (`e91aa07`..`e7a605d`), which changed only `ui/overlay/debug_overlay.gd`, plus two test files:
- **T-01-15 / AR-01:** the overlay still makes no mutating calls on the simulation; the model's only simulation calls are getters.
  - Its refresh clock now runs on real time (`Time.get_ticks_usec`) instead of scaled delta. That is display timing only, with no write path.
  - The new pause test builds through the normal command gate, which is test code, not overlay code.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 293 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 289/289.

## Security Audit 2026-09-30 (re-audit after review-fix pass 23)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked after the single commit `625a89d`, which changed only one constant in `tests/e2e/test_debug_overlay_toggle.gd` (test-only, excluded from the export):
- **No mitigation touched:** no production file changed, so every register row stands as last audited.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 301 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 289/289.

## Security Audit 2026-09-30 (re-audit after review-fix pass 24)

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Re-checked after the 3 commits `e720f2c`..`da45f5c`, which changed only `tests/e2e/test_debug_overlay_toggle.gd` (test-only, excluded from the export):
- **No mitigation touched:** no production file changed, so every register row stands as last audited. The overlay's read-only e2e evidence (T-01-15) now checks row values, not just substrings.
- **T-01-13:** the scoped name check is clean.
- **T-01-06 / T-01-17:** `tools/prepush_check.sh` PASSED over all refs, including the 311 unpushed commits.
- **CI:** `ci.yml` is unchanged.
- **Tests:** full suite 290/290.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-29
