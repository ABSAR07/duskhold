---
phase: 02-night-defense-playtest-gate
reviewed: 2026-10-06T14:31:33Z
depth: standard
files_reviewed: 50
files_reviewed_list:
  - data/king/king.tres
  - data/maps/prototype_map.tres
  - data/tuning/loop_tuning.tres
  - input/fast_forward_controller.gd
  - input/fast_forward_controller.gd.uid
  - presentation/map/prototype_map.tscn
  - presentation/vfx/projectile_vfx.gd
  - project.godot
  - simulation/defs/king_def.gd
  - simulation/defs/loop_tuning.gd
  - simulation/defs/map_config.gd
  - simulation/night/castle_attack.gd
  - simulation/night/castle_attack.gd.uid
  - simulation/night/night_sim.gd
  - simulation/run/run_context.gd
  - simulation/run/run_manager.gd
  - tests/e2e/test_dawn_payout.gd
  - tests/e2e/test_dawn_payout_castle.gd
  - tests/e2e/test_dawn_payout_castle.gd.uid
  - tests/e2e/test_fast_forward.gd
  - tests/e2e/test_fast_forward.gd.uid
  - tests/e2e/test_king_ride.gd
  - tests/e2e/test_projectiles_visible.gd
  - tests/e2e/test_results_layout.gd
  - tests/e2e/test_results_layout.gd.uid
  - tests/e2e/test_start_night_hold.gd
  - tests/integration/test_balance_acceptance.gd
  - tests/integration/test_balance_acceptance.gd.uid
  - tests/integration/test_balance_report.gd
  - tests/integration/test_loop_gold_carryover.gd
  - tests/unit/test_building_damage.gd
  - tests/unit/test_castle_attack.gd
  - tests/unit/test_castle_attack.gd.uid
  - tests/unit/test_dawn_income.gd
  - tests/unit/test_dawn_rebuild.gd
  - tests/unit/test_fast_forward_rules.gd
  - tests/unit/test_fast_forward_rules.gd.uid
  - tests/unit/test_input_map.gd
  - tests/unit/test_king_movement_config.gd
  - tests/unit/test_loop_tuning_contract.gd
  - tests/unit/test_map_validate_castle.gd
  - tests/unit/test_map_validate_castle.gd.uid
  - tests/unit/test_map_validate_income.gd
  - tests/unit/test_map_validate_income.gd.uid
  - tools/replay/balance_report.gd
  - tools/replay/replay_driver.gd
  - ui/hud/dawn_payout_vfx.gd
  - ui/hud/hud.gd
  - ui/hud/hud.tscn
  - ui/results/results_screen.tscn
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 2: Code Review Report (fourth review, gap-closure plans 02-12 to 02-16)

**Reviewed:** 2026-10-06T14:31:33Z
**Depth:** standard
**Files Reviewed:** 50
**Status:** issues_found

## Summary

Scope was the diff `2adf91a..HEAD` on the listed files: the base dawn income (RunManager, MapConfig, DawnPayoutVfx), the 12 m/s sprint, the night-only hold-to-fast-forward (FastForwardController, HUD label, input action), the castle ranged attack (CastleAttack, NightSim order, ProjectileVfx), the results-button margin and the seeded balance acceptance test.

The simulation changes hold up. CastleAttack uses only integer ticks, SimClock and TargetQuery, steps between towers and enemies as DR-8 requires, resets in begin_night, and is off at the data defaults, so the smoke golden is unaffected. The base income is added to a fresh Dictionary returned by `dawn_income_by_spot()` (checked: no shared state is mutated), is listed last, and the total equals the sum of per_spot. FastForwardController is the only writer of Engine.time_scale, nothing under simulation/ reads it, the scale drops inside the same step that leaves NIGHT (including defeat), and `_exit_tree` restores 1.0. The HUD scale text was checked against Godot 4.7.2 directly (2.0 reads "2", 1.5 reads "1.5", 2.5 reads "2.5"). No new test uses `pending()`, and no new test budgets real seconds tightly against the clamped clock (the dawn and arrow waits give 3 s or more against a 0.5 s simulated night).

Two things need attention. The castle-attack validation claims a guarantee it does not give (a data value can make the castle fire on every tick). Separately, the leaked controllers in test_fast_forward_rules.gd make one of its tests unable to fail on the behaviour it names.

## Warnings

### WR-01: Leaked FastForwardControllers make "a held key resumes fast-forward as the night begins" unable to fail

**File:** `tests/unit/test_fast_forward_rules.gd:54-59` (helper), `tests/unit/test_fast_forward_rules.gd:113-121` (affected test)
**Issue:** `_controller_on` does `add_child(controller)` with no autofree. GUT keeps one test-script node for the whole file, so every controller created by an earlier test stays in the tree for the rest of the file, still polling `Input.is_action_pressed` each frame against its own old RunContext. The first controller test (`test_fast_forward_held_by_day_changes_nothing_then_runs_the_night_at_2x`) leaves its context in NIGHT, so that stale controller applies `Engine.time_scale = 2.0` whenever the action is held, for every later test.

`test_a_night_that_starts_while_the_key_is_already_down_runs_fast` presses the action, awaits one frame (during which the stale controller from the earlier test already sets 2.0, because its own night is running), and only then submits StartNightIntent. Its assertion `Engine.time_scale == 2.0` is therefore already true before the new controller's `phase_changed` handler runs. If that handler were deleted or disconnected the test would still pass. The same masking applies to the "fast at night" pre-assertions in `test_freeing_the_controller_while_fast_restores_real_time` and `test_the_scale_drops_inside_the_step_that_reaches_dawn`. The three whole-feature-off mutation probes would not expose this, because a partial regression (the handler only) is what slips through.
**Fix:** Own each controller with the test, so nothing outlives it:
```gdscript
func _controller_on(ctx: RunContext) -> FastForwardController:
	var controller: FastForwardController = FastForwardController.new()
	add_child_autofree(controller)
	controller.bind_run(ctx, null)
	controller.changed.connect(_on_changed)
	return controller
```
`test_freeing_the_controller_while_fast_restores_real_time` frees the controller itself, which autofree tolerates (GUT checks for a freed instance). Then confirm by mutation that removing the `phase_changed` connection fails `test_a_night_that_starts_while_the_key_is_already_down_runs_fast`.

### WR-02: Castle attack validation does not prevent a castle that fires on every tick (non-finite or sub-step interval), contradicting T-02-33

**File:** `simulation/defs/map_config.gd:164-184` (`_validate_castle_attack`), `simulation/night/castle_attack.gd:38-43` (`is_armed`), `simulation/night/castle_attack.gd:66`
**Issue:** The class comment and the map comment say bad data can never make the castle fire every tick. The check only rejects negatives and exact zeros. I ran it on 4.7.2-stable. With `castle_attack_damage = 1`, `castle_attack_range = INF` and `castle_attack_interval = INF`, `validate()` returns `[]`. `SimClock.ticks(INF)` is 1, so `_ready_at = tick + 1` and the castle shoots every 33 ms. `castle_attack_interval = 0.001` (also valid) does the same, since `ticks()` has a floor of 1. With a NaN range or interval `validate()` is also clean, but `is_armed()` is false (NaN > 0 is false), so the castle is silently off with no error. The sibling control, `FastForwardController.scale_for`, does handle NaN and INF (T-02-29), so the castle numbers are the inconsistent case. A shipped .tres is authored data, so this is not exploitable, but it breaks the stated invariant and can swing balance or flood PendingHits and the projectile cap.
**Fix:** In `_validate_castle_attack` reject non-finite values and require at least one step:
```gdscript
for field: String in ["castle_attack_range", "castle_attack_interval", "castle_projectile_speed"]:
	var value: float = get(field)
	if is_nan(value) or is_inf(value):
		errors.append("%s is not finite (%s)" % [field, value])
if castle_attack_damage > 0 and castle_attack_interval > 0.0 and castle_attack_interval < SimClock.STEP:
	errors.append("castle_attack_interval is below one simulation step (%s)" % castle_attack_interval)
```
Also make `CastleAttack.is_armed` use `is_finite()` on the range and interval so a map that was never validated cannot arm the castle with INF. Add the INF, NaN and 0.001 cases to `tests/unit/test_map_validate_castle.gd`. If a sub-step interval is meant to be legal, correct the "can never fire every tick" wording in `castle_attack.gd` and `map_config.gd` instead.

## Info

### IN-01: The dawn_payout signal documentation still says per_spot maps only spot ids

**File:** `simulation/events/sim_events.gd:16` (related: `simulation/run/run_manager.gd:196-205`)
**Issue:** The doc reads "`per_spot` maps spot_id to amount in MapConfig order, amount > 0 only". Since 02-12 it can also carry `MapConfig.CASTLE_PAYOUT_KEY` (&"castle"), listed last, which is not a spot. Consumers were checked and cope (DawnPayoutVfx projects the key above the castle, SimRecorder logs it, the others ignore the dictionary), but the next consumer that does `get_spot(key)` will get null.
**Fix:** Update the comment: "...in MapConfig order, then `MapConfig.CASTLE_PAYOUT_KEY` for the castle's base income when the map pays one."

### IN-02: test_results_layout pins the 11 px constant rather than measuring the visible gap it exists for

**File:** `tests/e2e/test_results_layout.gd:49-57`
**Issue:** `test_buttons_sit_the_row_gap_plus_the_leading_below_the_last_stat` asserts `play_again.y == knockouts.end.y + separation + 11`, which restates the scene's `margin_top = 11`. The owner's complaint (the visible gap from the last stat's capitals to the button edge equals the stat-row gap) is not measured; the font-leading arithmetic lives in a comment and in a debug note. A theme or font change that alters the leading passes this test and re-introduces the uneven gap. The file comment says so openly, so this is a limitation, not a defect.
**Fix:** Optional. Derive the leading from the font (`font.get_ascent(size)` minus cap height) for a font with known metrics and assert the visible gap against the row gap within 1 px. Otherwise keep the current test and the focus-expand sentinel.

---

_Reviewed: 2026-10-06T14:31:33Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
