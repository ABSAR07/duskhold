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
| T-01-04 | Tampering | `CommandProcessor.submit` / `Economy.try_spend` | medium | mitigate | `_submit_build` re-runs `validate_build` at apply time; `try_spend` refuses unaffordable or negative costs and changes nothing; `test_build_flow.gd`, `test_economy_gold.gd` green | closed |
| T-01-05 | Tampering | `BuildHoldController` partial-payment state | low | mitigate | Nothing is deducted while coins drip; completion goes through `commands.submit(BuildIntent)`; refund is a pure reset (D-06); `test_build_hold_refund.gd` green | closed |
| T-01-06 | Information Disclosure | First push / `tools/prepush_check.sh` | high | mitigate | Pre-push check scans current tree and `git log --all` for local tooling, generated output, credential-shaped values (plus gitleaks when installed) and >5 MB blobs, and prints identities for owner review; re-run 2026-09-29: PASSED | closed |
| T-01-07 | Elevation of Privilege | `.github/workflows/ci.yml` | medium | mitigate | `permissions: contents: read`; `pull_request` trigger only (no `pull_request_target`); no `secrets.` references; every action from the `actions/` org, pinned to a full commit SHA (stronger than the planned major tags) | closed |
| T-01-08 | Denial of Service | Git LFS quota in CI | low | mitigate | `.git/lfs` cache keyed on `hashFiles('.lfs-assets-id')`; lint job checks out with `lfs: false` | closed |
| T-01-SC (01-03) | Tampering | CI Godot/templates/pip installs | high | mitigate | CI runs `python tools/bootstrap.py --godot [--templates] --yes --platform linux`, which verifies against the committed pin; lint installs `-r tools/requirements-lint.txt` (pinned) | closed |
| T-01-09 | Tampering | `project.godot` `[input]` | low | mitigate | `test_input_map.gd` fails on any mouse binding in a project action, any missing keyboard/gamepad binding, or binding-table drift; green | closed |
| T-01-10 | Tampering | `MapConfig` / `.tres` data | low | mitigate | `MapConfig.validate()` reports empty entries, duplicate/empty ids, empty tier lists and non-positive costs (hardened by review fix IN-02); `test_prototype_map_data.gd` green | closed |
| T-01-11 | Tampering | `BuildHoldController` completion after leaving range, phase change or loss of affordability | medium | mitigate | Focus lock on the active spot; every frame cancels if the key is released, the spot is out of `interaction_radius` or `is_build_allowed()` is false; `submit` re-validates at completion; `test_build_hold_refund.gd`, `test_build_denied.gd` green | closed |
| T-01-12 | Repudiation | `assets/attribution.json` licensing claims | medium | mitigate | `ALLOWED_LICENSES = ["CC0-1.0", "MIT"]` and full-coverage checks in `test_attribution_log.gd`; `License.txt` kept beside each of the 4 third-party asset folders; archive SHA256 on every model entry; source wording quoted in 01-07-SUMMARY | closed |
| T-01-13 | Tampering | IP exposure in game content | medium | mitigate | Plan-scoped check `git grep -il thronefall -- data simulation input presentation ui assets project.godot export_presets.cfg ASSETS.md` is clean; only Kenney/Quaternius sources used | closed |
| T-01-SC (01-07) | Tampering | CC0 archive downloads | high | mitigate | Owner approved exact URLs and sizes (01-07 Task 2); `curl --fail`; SHA256 recorded per archive in `attribution.json` (4 model entries); only chosen files extracted | closed |
| T-01-14 | Tampering | `RunManager` transitions and dawn payout | low | mitigate | `start_night()` returns false unless `_phase == DAY`; `test_only_the_run_manager_assigns_the_loop_phase` source-scan test; `CommandProcessor` rejects StartNightIntent outside DAY; `test_run_manager.gd`, `test_build_phase_guard.gd`, `test_loop_gold_carryover.gd` green | closed |
| T-01-15 | Elevation of Privilege | DebugOverlay in release builds | low | accept | See AR-01 | closed |
| T-01-16 | Information Disclosure | `duskhold-screenshots` CI artifact | low | accept | See AR-02 (`retention-days: 7` confirmed in `ci.yml`) | closed |
| T-01-17 | Information Disclosure | `git push` of new history | high | mitigate | `bash tools/prepush_check.sh` before every push; re-run 2026-09-29 over all refs, including the 28 local review-fix commits not yet pushed: PASSED | closed |
| T-01-SC (01-10) | Tampering | apt packages on the CI runner | low | accept | See AR-03 | closed |
| T-01-SC (no-install plans) | Tampering | Package installs in 01-02, 01-04, 01-05, 01-06, 01-08, 01-09 | low | accept | See AR-04 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

The plans list T-01-SC seven times; the six identical "this plan installs no packages" acceptances are merged into the last row, leaving 22 register rows.

### Observations (non-blocking)

- **T-01-06 / T-01-17: enforcement is procedural.** `.git/hooks/pre-push` only runs Git LFS, so nothing forces `tools/prepush_check.sh` to run before a push. Run it before pushing the 28 pending review-fix commits (it passes today). Optional hardening: call it from the pre-push hook.
- **T-01-12: residual licence risk.** The allow-list test trusts each entry's declared `license` field. The Quaternius horse is logged as CC0-1.0, based on the 2021 Poly Pizza CC0 statement, while Quaternius now publishes its own Asset License. That is review finding WR-06, disposition skipped, owner decision pending. It is also listed as a human verification item.
- **T-01-13: out-of-scope mention.** A comment on line 3 of `tools/_common.sh` names the local checkout folder, which contains the reference game's name. `tools/*` is not game content and is excluded from the export (`exclude_filter="tests/*, addons/gut/*, tools/*"`). The owner may still want to reword it before release.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-01-15 | The overlay only calls getters. `test_debug_overlay_readonly.gd` shows 200 collects change no state and emit no events. Leaving the F3 / gamepad-Back toggle in Phase 1 release builds therefore gives no gameplay advantage. Revisit gating before the Phase 13 release. | Plan 01-08 threat model (recorded in STATE.md decisions) | 2026-09-29 |
| AR-02 | T-01-16 | The screenshot artifact holds only the game's own frames of public content in a public repo, with 7-day retention. | Plan 01-10 threat model | 2026-09-29 |
| AR-03 | T-01-SC (01-10) | apt/Mesa packages come from Ubuntu's signed archive on an ephemeral runner, with no secrets in the job and a read-only token. Nothing is installed on the owner's machine. | Plan 01-10 threat model | 2026-09-29 |
| AR-04 | T-01-SC (01-02, 01-04, 01-05, 01-06, 01-08, 01-09) | These plans install no packages; the toolchain was pinned and owner-approved in 01-01. | Plan threat models | 2026-09-29 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-29 | 22 | 22 | 0 | secure-phase orchestrator (ASVS L1 grep-depth; short-circuit, no auditor spawn) |

## Security Audit 2026-09-29

| Metric | Count |
|--------|-------|
| Threats found | 22 |
| Closed | 22 |
| Open | 0 |

Evidence gathered for this audit: grep-level inspection of `tools/bootstrap.py`, `tools/prepush_check.sh`, `.github/workflows/ci.yml`, `export_presets.cfg`, `simulation/commands/command_processor.gd`, `simulation/economy/economy.gd`, `input/build_hold_controller.gd`, `simulation/defs/map_config.gd`, `simulation/run/run_manager.gd`, `assets/attribution.json`. Also: `git check-ignore` probes; full GUT suite 201/201 green; `tools/prepush_check.sh` PASSED; export and headless launch OK.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-29
