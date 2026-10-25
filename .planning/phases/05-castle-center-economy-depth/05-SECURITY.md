---
phase: "05"
slug: "castle-center-economy-depth"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-22"
---

# Phase 5 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Built from the `<threat_model>` blocks of plans 05-01 to 05-12 and the SUMMARY threat flags (all twelve report "None" beyond the planned surface). Verified at ASVS level 1 (grep depth) by the execute-phase orchestrator on 2026-10-22 at commit 06f3755; with `threats_open: 0` and a plan-time register at level 1, the workflow's short-circuit rule applied and no auditor subagent was spawned. Paths are relative to the repository root. Extended on 2026-10-25 with gap round 1 (plans 05-13 to 05-24): threats T-05-25 to T-05-45, all closed at the same depth (see the Security Audit section of that date).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Data (.tres cards, castle tiers, curves, requirements) -> StatStack and the build gate | Untrusted numbers and ids drive every bonus, payout and lock | Modifier kinds and values, choice ids, tier requirements, curve fields |
| BuildIntent (player hold, bot, test) -> CommandProcessor | A choice id or a locked tier arrives through the one intent path | spot id, tier, choice_id |
| Simulation -> presentation, input and overlay | CardRow, CardPicker, the Economy and Stats overlay sections and the building views read the stack, the income state and the ledger every frame; a write back would break replay identity | Stat sums, picks, boats, awake flags (read-only) |
| Enemy deaths -> Shrine wake and synergy | Kill credit near a Shrine wakes it and resizes one stat source | Death positions and max health, awake counts |
| Golden files and the balance report -> CI verdicts | A regenerated golden or a moved digest can hide a regression | smoke, army, walls, economy digests; full_idle recorded before and after |
| Local repo -> GitHub and CI runners | Pushed code runs in CI with the workflow's permissions | Source, workflow YAML, artifacts |
| CLI arguments -> playtest and replay tools | Untrusted strings choose strategies, seeds and output folders | Names from allowlists, bounded integers, folders under build/ |
| Project -> Windows export | Tools, tests and the GUT addon must not ship; the native DLL must be the pinned build | Export filter, stamped DLL |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-05-01 | Tampering / Denial of Service | StatStack.add_source with huge or unknown modifiers | medium | mitigate | `simulation/stats/stat_stack.gd:20-26` `MAX_ABS_BASE 100000`, `MAX_MULTIPLIERS_PER_STAT 4`, `PERCENT_SUM_MIN -90`, `PERCENT_SUM_MAX 1000`; `add_source` returns false and applies nothing on any bad modifier (lines 46, 58, 206); pinned by `tests/unit/test_stat_stack.gd` | closed |
| T-05-02 | Tampering | simulation/stats determinism | medium | mitigate | `tests/unit/test_sim_rules_guard.gd:17` lists `res://simulation/stats` in MATH_ROOTS; integer arithmetic with one half-up rounding (docs/STAT_MODIFIERS.md, `test_stat_contract`); the five replays byte-identical for the whole phase except the recorded full_idle move | closed |
| T-05-03 | Tampering | presentation and overlay reading the stack | low | mitigate | `ui/overlay/stat_overlay_sections.gd:31-47` calls only `modified_stats`, `int_value`, `float_value` and `sums_of`; `test_collecting_the_stats_rows_never_writes_the_stack` (05-01) and `test_debug_overlay_readonly` guard it | closed |
| T-05-04 | Tampering | BuildIntent.choice_id from a bot or test | medium | mitigate | `simulation/commands/command_processor.gd:222-233` answers `BAD_CHOICE` for an id outside the next tier's list or at a plain tier and `CHOICE_REQUIRED` for none, before any spend; `command_rejected` announces it; pinned by `tests/unit/test_build_choice.gd` | closed |
| T-05-05 | Tampering | card modifiers armed on a pick | low | mitigate | `simulation/buildings/choice_ledger.gd:71` arms through `StatStack.add_source`, which refuses unregistered or out-of-range modifiers whole (T-05-01); `ChoiceValidation` reports bad card data at construction (T-05-07) | closed |
| T-05-06 | Repudiation | replay identity of picks | low | mitigate | `simulation/events/sim_events.gd:87` `choice_picked`; `tests/support/sim_signals.gd:40` and `tools/replay/sim_recorder.gd:43,90,237` record it; `test_determinism` drift check; economy golden `f4b98093` pins a pick | closed |
| T-05-07 | Tampering | card and castle data files | medium | mitigate | `simulation/defs/choice_validation.gd:18` `problems()` (ids, text, modifiers, castle counts) and `simulation/defs/castle_validation.gd:16` `problems()` (one castle plot, tier I without choices, distance); `simulation/run/run_context.gd:40` pushes every `map_config.validate()` error at construction; pinned by `tests/unit/test_choice_validation.gd` | closed |
| T-05-08 | Denial of Service | card text rendered in world space | low | mitigate | `simulation/defs/choice_validation.gd:12-13` `MAX_NAME_LENGTH 24`, `MAX_FLAVOUR_LENGTH 70`; CardRow wraps at a fixed width; pinned by `test_choice_validation` and `test_ability_data` | closed |
| T-05-09 | Tampering | CardPicker mouse handling | low | mitigate | `input/card_picker.gd:67` `_input` consumes a press only when `CardRowModel.hit_test` finds a card and writes only its own highlight; the only purchase path stays the hold's BuildIntent through CommandProcessor; `tests/e2e/test_card_mouse.gd` asserts gold, tier, selection and `command_rejected` unchanged after a click | closed |
| T-05-10 | Repudiation / licensing | card icons and keep scenes | low | mitigate | `ASSETS.md:84-93` `## First-party assets`: twelve SVG icons at `assets/first_party/card_icons/` as CC0-1.0; keep scenes `presentation/buildings/models/castle_center_t2..t4.tscn` compose only the logged Kenney Castle Kit GLBs; `tests/unit/test_attribution_log.gd` and `test_card_icons.gd` green; no download in the phase | closed |
| T-05-11 | Tampering / Denial of Service | requirement data (cycle, missing spot, impossible tier) | medium | mitigate | `simulation/defs/build_requirement_validation.gd:16` `problems()` reports a castle tier the castle cannot reach, a `requires_spot` naming itself or a missing plot, a tier outside the required building's range and a cycle (line 29 `_check_cycles`); RunContext pushes the errors; pinned by `tests/unit/test_build_requirement_validation.gd` | closed |
| T-05-12 | Tampering | BuildIntent on a locked tier | low | mitigate | `simulation/commands/build_requirements.gd:31-36` returns `CASTLE_TIER` or `NEEDS_SPOT` before any spend; `command_processor.gd:27` announces it through `command_rejected`; `tests/unit/test_build_requirements.gd` checks gold unchanged | closed |
| T-05-13 | Tampering | curve data (negative or huge steps, floors, payouts) | medium | mitigate | `simulation/defs/economy_validation.gd:26` `MAX_CURVE_VALUE 1000`, lines 69-73 range and misplaced-field checks; the payout counter is an integer that never grows; pinned by `tests/unit/test_economy_validation.gd` and `test_economy_data_contract.gd` | closed |
| T-05-14 | Tampering (integrity) | dawn payout | medium | mitigate | `simulation/buildings/building_system.gd:99` lists FLAT curves only; `simulation/economy/income_state.gd:8-9,77` pays every non-FLAT curve and nothing else; one `dawn_payout` per dawn whose total equals the sum (`tests/integration/test_dawn_payout_economy.gd`); full_idle digest `afc11cd0` guards the order | closed |
| T-05-15 | Tampering | Field lock bypass through a BuildIntent | low | mitigate | `simulation/commands/build_requirements.gd:34-36` refuses `NEEDS_SPOT` while the required plot is below the required tier; pinned by `tests/unit/test_mill_fields.gd` and `tests/e2e/test_mill_fields_scene.gd` (gold unchanged, `command_rejected` announced) | closed |
| T-05-16 | Denial of Service / Tampering | boat_cap, boat_income and pond data | medium | mitigate | `simulation/defs/economy_validation.gd:30` `MAX_POND_RADIUS 30.0`, lines 86-90 `boat_cap` 1..MAX_BOAT_CAP (20) and `boat_income` 1..1000, finite centre, plots, spawns and roads kept `POND_ROAD_CLEARANCE` off the pond; the pond never enters NavGrid (`tests/unit/test_nav_layout_pin.gd`, `test_pond_layout.gd`; gate stress unchanged) | closed |
| T-05-17 | Denial of Service / Tampering | wake radius, threshold, synergy and stat ids | medium | mitigate | `simulation/defs/economy_validation.gd:35-36` `MAX_WAKE_RADIUS 40.0`, `MAX_WAKE_THRESHOLD 100000`, lines 99-104 finite and bounded `wake_radius`, `synergy_percent` 0..100, attack numbers and known stat ids required on AWAKENED tiers; the death handler is one squared-distance test per Shrine; pinned by `tests/unit/test_shrine_validation.gd` | closed |
| T-05-18 | Tampering | shrine_synergy stacking | low | mitigate | `simulation/economy/income_state.gd:41,215,221` one `SYNERGY_SOURCE` removed and re-added on every change, never appended, under StatStack's percent-sum bound; pinned by `tests/unit/test_shrine_synergy.gd` | closed |
| T-05-19 | Tampering | golden digests | medium | mitigate | `tests/golden/economy.json` has exactly one commit (061e51b, plan 05-10); smoke `2599c7c2`, army `f7a967ed` and walls `bfb05fc7` never moved; full_idle's one move is recorded with before and after in 05-BALANCE-REPORT.md:48-49 (D-08); CI run 39751537305 checks all four goldens under GCC and MSVC | closed |
| T-05-20 | Elevation of Privilege | .github/workflows/ci.yml (05-10) | low | mitigate | Two replay lines added (`ci.yml:160,219`); `permissions: contents: read` (lines 25-26); every `uses:` pinned to a 40-hex SHA (21 lines, all pinned); no `secrets.` reference; ReplayCli accepts only the names in `ReplayScenarios.NAMES` | closed |
| T-05-21 | Repudiation / Tampering | balance pins and the full_idle digest | medium | mitigate | Pins, data and 05-BALANCE-REPORT.md landed in one commit (5d4a227); the report's after digest `afc11cd0...` is the one `bash tools/replay.sh --scenario=full_idle --twice` prints (05-12 local pass and CI); the before digest `4385f569...` is kept; the bar was not lowered (`tests/integration/test_balance_acceptance.gd`) | closed |
| T-05-22 | Information disclosure / Tampering | report and playtest outputs | low | mitigate | `tools/playtest.sh:4` `--out=build/<dir>` only; `tools/replay/replay_cli.gd:59-60,70,112` `safe_dir` under build/ with a usage error otherwise; no path is taken from data; the one committed output is the report | closed |
| T-05-23 | Elevation of Privilege / Information disclosure | CI workflow and the push (05-12) | low | mitigate | 05-12 changed one comment line in ci.yml (570ff8d); `permissions: contents: read`, no secrets and every pinned `uses:` SHA kept; `tools/prepush_check.sh` ran before the one push with the gh credential-helper command verbatim; CI run 39751537305 green on all six jobs | closed |
| T-05-24 | Tampering | the exported build | low | mitigate | `tools/export.sh:28,66-67` demands `libduskhold_sim.windows.x86_64.dll` (built from the pinned sources) beside the exe and fails otherwise; the launch check `timeout 90 build/windows/Duskhold.exe --headless --quit-after 120` exited 0 on the export of 2026-10-22 (109,268,480 bytes plus the 670,720-byte DLL) | closed |
| T-05-25 | Tampering | the half-flipped shipped data between plans 05-13 and 05-14 | medium | mitigate | 05-13 (4749f2b) and 05-14 (7c8a516) ran back to back in one local chain; nothing was pushed (origin still at 570ff8d) or exported until the flip was complete; the post-merge gate between them was compared with the planner's expected-failure list | closed |
| T-05-26 | Tampering | a mis-typed product or a missed field | medium | mitigate | The exact-x100 check (rebuild from ce3fcea with only the six health and damage field names multiplied, diff against the working file) prints EXACT_X100 for all sixteen rescaled files it covers today (the Fishing Harbor and the map were changed again by 05-22 by design); every executor ran it verbatim | closed |
| T-05-27 | Repudiation | full_idle and the balance pins moving with the data | medium | mitigate | full_idle recorded at every step (afc11cd0 before the round, cec3eb71 after the rescale, 6fd6121e and c68254cd after the Harbor) in the SUMMARYs and 05-BALANCE-REPORT.md; only GRUNT_MAX_HEALTH moved in test_balance_acceptance, with the gap-round header paragraph | closed |
| T-05-28 | Tampering | the eighteen flipped data files and Royal Training | medium | mitigate | Royal Training's diff against ce3fcea is exactly `value = 1` to `value = 100`; the exact-x100 check covers the other files; the eleven other cards changed only where plan 05-21 recut them | closed |
| T-05-29 | Tampering | the golden fixture maps and their king and tuning copies | high | mitigate | `git diff --quiet ce3fcea -- tests/golden` plus the seven golden fixture resources exits 0; smoke 2599c7c2, army f7a967ed, walls bfb05fc7 and economy f4b98093 replayed byte-identical after every plan of the round and in 05-24's closing pass | closed |
| T-05-30 | Tampering | a test weakened while scaling (fixtures and wall tests) | low | mitigate | Every test script the round edited keeps its ce3fcea test count (the only change is test_king_widget's 15 to 16, the new Royal Training fit test of 05-20); 05-15 changed literal amounts and messages only, expected tick counts kept | closed |
| T-05-31 | Denial of service | int overflow at the 10000000 and 1000000000 pools | low | mitigate | `tools/stress/data/stress_wall.tres:9` max_health 10000000 and the stress castle 10000000 sit under the PackedInt32Array ceiling of `simulation/walls/wall_system.gd:26-27`; the 1000000000 castle of step_bench.gd is int64; no card arms on the stress map; the gate stress and the fill pins ran green | closed |
| T-05-32 | Tampering | the PLAT-01 pins edited to pass (stress data) | medium | mitigate | `git diff --quiet ce3fcea` over test_enemy_fill_pins.gd and test_projectile_fill_pins.gd exits 0; both passed unedited after the stress rescale | closed |
| T-05-33 | Repudiation | contract pins moved without a trace | low | mitigate | All ten re-pinned contract and label scripts carry the `Gap round G-05-2` header (test_weapon_def:6, test_military_data_contract:10, test_castle_data_contract:9, test_map_validate_castle:12, test_castle_label:7, test_wall_data_contract:6, test_economy_data_contract:12, test_ability_data:11, test_spot_label_model:4, test_economy_overlay_sections:8); counts unchanged | closed |
| T-05-34 | Tampering | the PLAT-01 pins (native parity) | high | mitigate | The diff of the nine `tests/unit/test_*_pins.gd` scripts against ce3fcea holds no added or removed 64-hex digest, `"most_` or `"frames` line (PINS_INTACT); only inputs moved, and the decision worlds are frozen at PHASE_FOUR_WALL_HEALTH; all nine pin scripts pass | closed |
| T-05-35 | Tampering | a test weakened while scaling (combat tests) | low | mitigate | 05-18's ten scripts keep their ce3fcea test counts and every expected value; only literal amounts and the one frozen-input helper changed | closed |
| T-05-36 | Tampering | a test weakened while scaling (felling blows) | low | mitigate | 05-19 changed seven felling blows and one header note per file; counts equal ce3fcea; the eight scripts whose 1000 still fells a footman were left alone | closed |
| T-05-37 | Tampering | the king widget's wider row covering other HUD | low | mitigate | `tests/e2e/test_king_widget.gd:18` pins WIDGET_RIGHT 408 against `ui/hud/king_widget.gd:32` LABEL_MIN_WIDTH 128; test_start_night_plate and test_hud_contract green; ten real-window shots read (the row ends near x 403, clear of the plate at x 440) | closed |
| T-05-38 | Repudiation | card numbers retuned without a trace | low | mitigate | `tests/unit/test_ability_data.gd:15` opens the card-recut paragraph with each old and new value and its reason; 05-21's before and after tables are copied into 05-BALANCE-REPORT.md | closed |
| T-05-39 | Tampering | a later data edit reintroducing a base too small to resolve a percent, or one past the stack's clamp | medium | mitigate | `tests/unit/test_card_resolution.gd` (8 tests) reads every base from the shipped files, bands every card at 0.5 to 1.5 times its text (`:252`), bounds every integer health and damage base between 100 and StatStack.MAX_ABS_BASE (`:325-335`) and carries the negative control (`:341`); the validate-phase probe with the footman back at 1 damage was caught (3 failures) | closed |
| T-05-40 | Tampering | the moved pond and plot (nav and routes) | medium | mitigate | `tests/unit/test_pond_layout.gd:43` derives the road distance as pond_radius + POND_ROAD_CLEARANCE and `:89` keeps the dock's body out of the water; MapConfig.validate() and EconomyValidation reported nothing; test_nav_layout_pin unchanged and green; the pond stays visual only | closed |
| T-05-41 | Repudiation | the 12 m road rule relaxed silently | low | mitigate | `tests/unit/test_prototype_map_economy.gd:19` states the owner's reason and `:57-61` gives harbor_1 alone its 9.0 to 10.5 m band; every other Phase 5 plot keeps 12 m; test_harbor_exposure derives both edges from the shipped enemy data | closed |
| T-05-42 | Repudiation / Tampering | balance pins and the full_idle digests | medium | mitigate | Commit 624444d carries 05-BALANCE-REPORT.md and test_balance_acceptance.gd together; the report keeps afc11cd0 and cec3eb71 and records the final c68254cd, which 05-24's closing run printed; no bar constant moved | closed |
| T-05-43 | Information disclosure | probe scripts and playtest outputs | low | mitigate | No probe or scratch file appears in any commit since ce3fcea; the probes ran from the executors' scratch folders; build/ (playtest and replay outputs) is git-ignored | closed |
| T-05-44 | Tampering | the exported build | low | mitigate | `tools/export.sh:28` requires libduskhold_sim.windows.x86_64.dll beside the exe; the export of 2026-10-25 (Duskhold.exe 109,268,480 bytes, the 670,720-byte DLL) passed the headless launch check (exit 0 in 8 s) | closed |
| T-05-45 | Repudiation | card numbers shipped on arithmetic alone and the display choice | low | mitigate | 05-PLAYTEST-GATE.md's gap-round section names every card the bots cannot judge (Commander, the four tier III and four tier IV cards), Prosperity's measured shortfall, each with its numbers, basis, alternatives and a recommendation, and the 'divided by 100' display choice | closed |
| T-05-SC | Tampering | package installs (every plan) | low | accept | No npm, pip or cargo installs and no downloaded asset in any of the twelve plans (RESEARCH Package Legitimacy Audit: none); the card icons are first-party SVGs, every building model composes already-logged Kenney GLBs or engine primitives (AR-05-01) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Unregistered Flags

None. Every SUMMARY's `## Threat Flags` section reports "None" beyond the planned surface. Two execution facts touch the register without opening a threat: the orchestrator's post-merge fix after wave 10 (commit f39b578) changed three tests and one screenshot script to meet the castle-II gate, no rule or data; and 05-12's one ci.yml edit is a comment line (T-05-23 evidence).

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-05-01 | T-05-SC | No package manager installs in the phase; no new third-party asset was downloaded (the twelve card icons are first-party CC0-1.0 SVGs logged in ASSETS.md, the key tiles and every building model come from already-logged Kenney kits or code-built primitives) | Planner (every plan's threat model), confirmed by the orchestrator at verification | 2026-10-22 |
| AR-05-02 | T-05-03 | The Stats and Economy debug overlay sections ship in the export like the existing F3 overlay (T-01-15 accepted in Phase 1, AR-04-02 in Phase 4); they are read-only views of the simulation and show no data a player could not infer | Planner (05-01 and 05-06 threat models), confirmed by the orchestrator at verification | 2026-10-22 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-22 | 25 (T-05-01 to T-05-24 plus the per-plan T-05-SC row) | 25 | 0 | execute-phase orchestrator (ASVS L1 grep verification, short-circuit rule; HEAD 06f3755; CI run 39751537305 green on 570ff8d) |
| 2026-10-25 | 21 new (T-05-25 to T-05-45, gap round 1, plus the per-plan T-05-SC row, accepted under AR-05-01) | 21 | 0 | execute-phase orchestrator (ASVS L1 grep verification, short-circuit rule; HEAD af53a14; not yet pushed) |


## Security Audit 2026-10-25 (gap round 1, plans 05-13 to 05-24)
| Metric | Count |
|--------|-------|
| Threats found | 21 |
| Closed | 21 |
| Open | 0 |

Built from the `<threat_model>` blocks of the twelve gap plans (every one authored at plan time) and their SUMMARY threat flags (all twelve report no new surface). The round changed data, tests, two shot scenarios and one UI constant (the king widget's label width); it added no endpoint, file access, network call, dependency or asset, so the trust boundaries above are unchanged. Two threats are rated high, T-05-29 (the golden inputs) and T-05-34 (the PLAT-01 pins); both are closed by byte-level checks against ce3fcea. With `threats_open: 0`, a plan-time register and ASVS level 1, the short-circuit rule applies and no auditor was spawned; the evidence column cites the grep or diff result for each row (scratch `sec_grep_round1.sh` at HEAD af53a14).

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-22 (secure-phase, state B, ASVS L1 short-circuit; no auditor spawn needed); re-verified 2026-10-25 after gap round 1 (secure-phase, state A, ASVS L1 short-circuit over T-05-25 to T-05-45; no auditor spawn needed)
