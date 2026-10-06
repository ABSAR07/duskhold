---
status: diagnosed
trigger: "UAT Test 14 of Phase 2 (round 2, gap G-02-14): the owner played the fresh build with the new night fast-forward (hold F or the gamepad left trigger during a night to run the game at 2x, added by plan 02-13) and said: \"speed up should be togglable instead of hold to speed up. everything else is pass\" (the 12 m/s sprint, the 60 m/s^2 braking, the 2x pace, the HUD label and the night-only rule all pass)."
created: 2026-10-06T20:39:46Z
updated: 2026-10-06T20:52:08Z
---

## Current Focus

hypothesis: CONFIRMED (a design change request, not a defect). The hold lives in one line, input/fast_forward_controller.gd:82, `scale_for(phase, Input.is_action_pressed(ACTION), _ctx.tuning)`, run from _process every frame (61-63) and from the phase_changed handler (77-78). The controller stores no on/off state, so the engine time scale follows the key level frame by frame. That is exactly what plan 02-13 specified ("Holding the new fast_forward action", 02-13-PLAN.md:37; "it is a hold, not a toggle", :92) and what 9 of the 19 fast-forward tests pin.
test: done (full reads of the controller, HUD wiring, input map, both suites and the docs; a headless scratch probe of trigger-axis edges, action_press timing and a scratch latch through the real scale_for; baseline run of both suites, 19/19 passing)
expecting: n/a
next_action: none (diagnose-only); hand back ROOT CAUSE FOUND to the caller
bug_class: Bohrbug (deterministic; specified behavior the owner has now rejected)
reasoning_checkpoint:
  hypothesis: "The owner's 'should be togglable instead of hold' is fully explained by FastForwardController._apply (fast_forward_controller.gd:82) reading the live key level, Input.is_action_pressed(ACTION), on every frame and in every phase_changed, with no latched state. A toggle needs a latched bool flipped on a press edge, fed to the same scale_for."
  confirming_evidence:
    - "Line 82 is the only place the key state enters the controller. _process (61-63) and _on_phase_changed (77-78) both call _apply. scale_for (35-41) takes a plain `held: bool`, and no other script reads the fast_forward action (grep)."
    - "Baseline 19/19 passing. Unit tests 5-9 and e2e tests 1, 2 and 5 assert the level-follow contract: 'released is real time', 'the held key resumes fast-forward as the night begins', 'hidden at dawn even while the key is still held'."
    - "Scratch probe D: replacing the level read with a latch (flipped on the edge only in NIGHT, cleared by phase_changed out of NIGHT) and feeding it to the REAL scale_for gives press on (2.0, stays on with the key up), press off (1.0), a drop to 1.0 inside the step that reaches DAWN or LOST, a night 2 that starts at 1.0 even with the key held from day, and presses outside NIGHT ignored."
  falsification_test: "If anything besides line 82 put key state into the time scale (another reader of fast_forward, the HUD, the simulation), or if the left-trigger axis could not produce a single press edge per pull, a latch inside the controller would not be enough. Measured: no other reader exists, and is_action_just_pressed fires once per pull (probe A)."
  fix_rationale: "The request concerns the input semantics only. A latch inside the controller changes the semantics at their single source. scale_for keeps the night-only clamp, phase_changed keeps the same-step drop, which now also clears the latch, and _exit_tree keeps the restore, so the HUD contract, the single-writer rule and determinism are untouched."
  blind_spots: "Not observed on a real gamepad: the axis edges were fed as synthetic InputEventJoypadMotion. Trigger chatter around the 0.5 deadzone re-fires just_pressed on every upward crossing (probe A), which matters under a toggle and did not under a hold. A latch survives window focus loss (Godot releases held actions on focus-out, so the hold self-cancelled on alt-tab, but the latch does not). Owner-facing choices left to the planner and owner: whether the latch resets each night (default yes) and whether presses by day pre-arm the next night (default no)."
  candidate_causes:
    - "code: the per-frame level read at fast_forward_controller.gd:82 with no latch (CONFIRMED)"
    - "config: the InputMap binding (axis trigger, deadzone 0.5) forcing hold-like behaviour (ELIMINATED: same binding yields one just_pressed per pull; binding is semantics-neutral)"
    - "spec/data: the 02-13 plan truth and the owner packet (assumption 14, controls table) specified a hold (CONFIRMED as the origin of the code, not a separate defect)"
  and_gate: "No multi-condition failure. One design choice (a hold, specified in 02-13 and recorded for the owner) is implemented by one level read. Its tests and docs follow from it and must change with it, but they do not cause it."
tdd_checkpoint: (n/a, diagnose-only)

## Symptoms

expected: Holding F or the gamepad left trigger at night runs the game at 2x and the 'Fast-forward 2x' label is legible; the game returns to real time at dawn, in the defeat beat and on the results screen.
actual: speed up should be togglable instead of hold to speed up. everything else is pass
errors: None reported
reproduction: Test 14 in 02-UAT.md (owner play on build/windows/Duskhold.exe exported 2026-10-06 from commit a483ff6)
started: Discovered during round-2 UAT on 2026-10-06/07; the fast-forward landed in plan 02-13 the same day as a hold-to-speed-up by design (02-13-PLAN.md truths and 02-13-SUMMARY.md "Night-only decision")

## Eliminated

- hypothesis: The gamepad left trigger cannot serve a toggle because an axis action is "pressed" continuously, so the binding itself forces hold semantics
  evidence: Probe A on the real InputMap (deadzone 0.5). Input.is_action_just_pressed fired once per upward crossing of 0.5 (one pull 0.6..1.0..0.7 gave one edge), so the same F / left-trigger binding drives a toggle. The binding is semantics-neutral. Only the per-event InputEvent.is_action_pressed is continuous (true for every motion event at or above 0.5), which rules out an _unhandled_input toggle, not the binding.
  timestamp: 2026-10-06T20:52:08Z

- hypothesis: Another node (HUD, MapRoot, King, the results screen) also reads the fast_forward key and would keep hold behaviour after the controller changes
  evidence: grep of first-party .gd. The only reader of ACTION fast_forward is fast_forward_controller.gd:82. The HUD only listens to the controller's changed signal (hud.gd:88-92, 161-163). MapRoot, King and RunContext never mention fast-forward. Only the HUD and the tests consume is_active, get_scale, scale_for and the class.
  timestamp: 2026-10-06T20:52:08Z

- hypothesis: The change could move determinism or the smoke golden (fast-forward semantics feeding the simulation)
  evidence: No file under simulation/ mentions time_scale (grep, and test_nothing_under_simulation_mentions_the_time_scale passes). loop_tuning.gd only declares the data field. Replays and the smoke golden run ctx.step with no controller in the tree, and tools/replay/ and tests/golden/ never mention fast-forward. The input semantics only decide when Engine.time_scale is 2.0. They never touch what a step does.
  timestamp: 2026-10-06T20:52:08Z

## Evidence

- timestamp: 2026-10-06T20:42:43Z
  checked: Knowledge base (.planning/debug/knowledge-base.md) and MemPalace
  found: knowledge-base.md does not exist; no MemPalace available. No known-pattern candidate.
  implication: Investigate from scratch.

- timestamp: 2026-10-06T20:42:43Z
  checked: input/fast_forward_controller.gd (all 87 lines)
  found: The key state enters in exactly one place, _apply (line 81-87), `scale_for(phase, Input.is_action_pressed(ACTION), _ctx.tuning)` at line 82. _apply is called from _process every frame (lines 61-63) and from _on_phase_changed (lines 77-78, connected in bind_run line 48). scale_for (lines 35-41) takes `held: bool` and returns REAL_TIME unless phase == NIGHT and held, then the clamped tuning scale (NaN/INF -> 1.0, clamp 1.0..4.0). _apply writes Engine.time_scale and emits changed(active, scale) only when the value changes (lines 83-87). _exit_tree (66-72) disconnects and restores 1.0 if raised. The header doc (lines 3-16) states the hold rule twice: "Hold-to-fast-forward during a night" (line 3) and "A key held across dawn into the next night resumes fast-forward when that night starts (it is a hold, not a toggle)" (lines 15-16).
  implication: Hold semantics = the per-frame level read of Input.is_action_pressed at line 82. Nothing latches. scale_for itself is semantics-neutral (it only takes a bool), so a toggle can feed it a latched bool and keep the night-only clamp, the single-writer rule and the phase_changed same-step drop unchanged.

- timestamp: 2026-10-06T20:42:43Z
  checked: project.godot [input] fast_forward (lines 79-84); presentation/map/prototype_map.tscn node order (lines 63-77); presentation/map/map_root.gd _process (39-42)
  found: fast_forward = deadzone 0.5, InputEventKey physical_keycode 70 (F) and InputEventJoypadMotion axis 4 (JOY_AXIS_TRIGGER_LEFT) axis_value 1.0. FastForward is a child of the MapRoot after King, BuildHold and StartNightHold. MapRoot._process calls ctx.advance(delta) first (parent processes before children), so phase_changed reaches _on_phase_changed inside the simulation step and FastForward._process runs later in the same frame.
  implication: Same bindings serve a toggle. Because the trigger is an axis, the toggle must react to the action-state edge (pressed after not pressed), not to every motion event above the deadzone; to be verified empirically.

- timestamp: 2026-10-06T20:42:43Z
  checked: Input precedents in the repo (grep just_pressed / is_action_pressed / _unhandled_input in input/, presentation/, ui/)
  found: ui/overlay/debug_overlay.gd:117 is an existing press-to-toggle (`if Input.is_action_just_pressed(TOGGLE_ACTION): visible = not visible`) on F3 / gamepad Back, driven in tests/e2e/test_debug_overlay_toggle.gd:69-73 by Input.action_press + wait_process_frames(2) + action_release + wait_process_frames(2). input/build_hold_controller.gd:59-69 detects a press edge with `Input.is_action_just_pressed(ACTION) or (pressed and not _was_pressed)` and stores _was_pressed each frame. No first-party script uses _unhandled_input or _input for gameplay actions.
  implication: The repo already has both edge idioms a toggle needs; a press-to-toggle in _process with the build-hold style edge (just_pressed OR level-rise against a stored previous level) follows house style and is robust to the harness frame on which action_press lands.

- timestamp: 2026-10-06T20:42:43Z
  checked: ui/hud/hud.gd (lines 23-25, 62, 88-92, 160-163) and ui/hud/hud.tscn FastForwardLabel (104-120)
  found: HUD finds the FastForward node in bind_run and connects changed -> _on_fast_forward_changed, which sets label.visible = active and text "Fast-forward %sx". The label is hidden in the scene. No "hold" wording in the HUD: the label says only "Fast-forward 2x"; there is no fast-forward input hint anywhere in the HUD.
  implication: The HUD reacts to the changed signal only, so it needs no change for a toggle as long as the controller keeps emitting changed(true, 2.0) when latched on at night and changed(false, 1.0) when off or when the night ends.

- timestamp: 2026-10-06T20:42:43Z
  checked: tests/unit/test_fast_forward_rules.gd (all 243 lines, 14 tests) and the open review finding WR-01 (02-REVIEW.md:82-96, open in 02-REVIEW-DISPOSITION.md:6,51)
  found: Tests 1-4 pin scale_for(phase, held, tuning) as a pure table (held true/false, phases, clamp, NaN/INF). Tests 5-9 drive the controller with Input.action_press/action_release and assert a level-follow contract: test 5 "held by day stays at real time" then "held at night runs at 2x" then "released is real time" with changed [[true,2.0],[false,1.0]]; test 6 "the held key resumes fast-forward as the night begins" (press by day, then StartNightIntent, expect 2.0 at once); test 7 defeat drop; test 8 dawn drop "with the key still held"; test 9 free restores 1.0. Tests 10-14 (scene node, doubled deltas, clamp, single-writer scan, simulation scan) are semantics-neutral. _controller_on (42-47) uses add_child without autofree: WR-01 says GUT keeps one test-script node per file, so every earlier controller stays in the tree polling input against its old NIGHT context, masking test 6's assertion.
  implication: Under a toggle, a leaked controller is worse than under a hold: release_all_actions in after_each no longer resets a latched controller, and every later press would toggle all stale NIGHT controllers too (writing Engine.time_scale and appending to the shared _changes). WR-01 must be fixed in the same plan.

- timestamp: 2026-10-06T20:42:43Z
  checked: tests/e2e/test_fast_forward.gd (all 145 lines, 5 tests)
  found: All five drive the action with Input.action_press and never call action_release mid-test except test 2. Test 1 holds by day (expects 1.0, label hidden). Test 2 presses at night (2.0, label visible, text Fast-forward 2x) then releases (expects 1.0, "released is real time", label hidden). Test 3 (king pace) presses once before the second ride and keeps it held. Test 4 (tick rate) presses once before the fast measurement and keeps it held. Test 5 holds through dawn (label hidden at dawn "with the key still down", scale 1.0). after_each resets Engine.time_scale and releases all actions; the map is add_child_autofree, so its controller is freed (and _exit_tree restores 1.0) after each test.
  implication: Tests 3 and 4 keep passing under a toggle if the single press latches on (a press that stays held reads as one press). Tests 1, 2 and 5 change meaning (see Resolution).

- timestamp: 2026-10-06T20:44:27Z
  checked: Every other test that names fast_forward / FastForward (grep tests/), tests/unit/test_input_map.gd (lines 7-58, 144-149), tests/unit/test_loop_tuning_contract.gd (167-186), tests/e2e/test_map_binding.gd (78-108)
  found: test_input_map.gd pins only bindings (fast_forward in GAMEPLAY_ACTIONS, KEY_F, no button, JOY_AXIS_TRIGGER_LEFT +1.0, deadzone 0.5, no mouse, no sharing); its only hold wording is the doc comment at 144 ("Fast-forward is a hold on the left trigger ... reads like a button"). test_loop_tuning_contract.gd pins the data (field stored, default 1.0, cap 4.0, written in the .tres, 1.5..3.0); hold wording only in its doc comment at 167 ("holding fast_forward at night"). test_map_binding.gd's no-double-connection table does not include FastForwardController.changed (Hud.bind_run has its own repeat guard). No other HUD test reads %FastForwardLabel; the label is covered only by tests/e2e/test_fast_forward.gd. The other fast-forward hits (test_build_hold_long.gd:132, test_loop_tuning_contract.gd:118, tools/screenshot/shot_scenarios.gd _fast_forward) are the unrelated build-hold "nothing is fast-forwarded" wording and the screenshot tool's scripted ctx.step loop.
  implication: Assertions to change are confined to test_fast_forward_rules.gd tests 5-9 (plus new toggle tests) and test_fast_forward.gd tests 1, 2 and 5 (3 and 4 survive a press-to-latch unchanged). test_input_map.gd and test_loop_tuning_contract.gd change only in doc comments.

- timestamp: 2026-10-06T20:44:27Z
  checked: Determinism surface (grep time_scale over first-party .gd; grep fast_forward/FastForward under simulation/, tools/replay/, tests/golden/)
  found: Only input/fast_forward_controller.gd writes Engine.time_scale (lines 72 and 86); the only other mentions are comments in debug_overlay.gd:111-112 and test files (the scan skips tests/). Under simulation/ the only hit is simulation/defs/loop_tuning.gd declaring the data field fast_forward_scale and FAST_FORWARD_MAX_SCALE (no time_scale). tools/replay/ and tests/golden/ never mention fast-forward. Fast-forward reaches the simulation only as a larger delta into MapRoot._process -> RunContext.advance (clamped to MAX_ADVANCE_SECONDS); headless replays call ctx.step directly with no controller in the tree.
  implication: Changing hold to toggle is presentation-input only. The smoke golden (frozen fixtures, ctx.step loop) and full_idle digests cannot move; test_doubled_frame_deltas, the clamp test and both source scans stay valid as long as the toggle still writes Engine.time_scale only from this controller and never from simulation/.

- timestamp: 2026-10-06T20:44:27Z
  checked: Documentation and player-facing text stating the hold (grep fast-forward with hold/held/toggle across first-party .gd/.tscn and .planning live docs; README absent, only ASSETS.md at root)
  found: Code docs - input/fast_forward_controller.gd:3-4 ("Hold-to-fast-forward ... While the fast_forward action is held") and 15-16 ("A key held across dawn ... resumes fast-forward ... (it is a hold, not a toggle)"), 32 (scale_for doc "unless the action is held during NIGHT"); simulation/defs/loop_tuning.gd:53 ("while the fast_forward input is held during a night"); tests/unit/test_input_map.gd:144; tests/unit/test_loop_tuning_contract.gd:167; tests/unit/test_fast_forward_rules.gd:2; tests/e2e/test_fast_forward.gd:2-3. Player text - none: the HUD label reads only "Fast-forward 2x" and there is no in-game controls hint for it. Planning docs - 02-PLAYTEST-GATE.md:20 ("hold F or the left trigger at night"), :30 controls table row "Fast-forward (hold, night only, 2x) | F | left trigger", :72 assumption 14 ("with F or the left trigger held ... a key held across dawn resumes it when the next night starts"); 02-BALANCE-REPORT.md:24 ("hold F or left trigger, night only"); 02-SECURITY.md:67 T-02-29 ("returns 1.0 outside NIGHT or when not held"); 02-VERIFICATION.md:88, 114, 167, 188; ROADMAP.md:150 ("night-only hold-to-fast-forward"). 02-13-PLAN/SUMMARY, STATE.md:170 and 02-REVIEW.md:74 are historical records.
  implication: A toggle plan has a bounded doc sweep: the controller header and scale_for doc, loop_tuning.gd:53, four test doc comments, and the round-3 owner packet (02-PLAYTEST-GATE controls row and assumption 14), with ROADMAP/VERIFICATION/SECURITY wording refreshed at re-verification. No player-facing string says "hold".

- timestamp: 2026-10-06T20:48:41Z
  checked: GUT 9.7.1 frame waits (addons/gut/awaiter.gd:57-67) and the night start (simulation/run/run_manager.gd:105-111)
  found: The awaiter counts frames on get_tree().process_frame, which SceneTree emits before any node _process, so a test that resumes from wait_process_frames and calls Input.action_press does so before every scene node processes that frame. NIGHT_TRANSITION passes through to NIGHT inside the same StartNightIntent call, so there is no frame in which a press could land in NIGHT_TRANSITION.
  implication: The existing e2e idiom (action_press, wait_process_frames(2), action_release, wait) drives an is_action_just_pressed toggle reliably, exactly as tests/e2e/test_debug_overlay_toggle.gd already does for F3.

- timestamp: 2026-10-06T20:48:41Z
  checked: Scratch probe A (scratchpad/ff_toggle_probe.gd, headless Godot 4.7.2 on the project's real InputMap; one InputEventJoypadMotion on JOY_AXIS_TRIGGER_LEFT per frame through Input.parse_input_event; legacy_just_pressed_behavior false)
  found: deadzone reads 0.5. Sequence 0.0, 0.3, 0.6, 0.8, 1.0, 1.0, 0.7, 0.3, 0.0, 0.9, 0.0, then 0.49/0.51 x3, 0.0, 0.0 (19 events). Input.is_action_just_pressed was true on exactly 5 frames: the first rise to 0.6, the second pull to 0.9, and each of the three 0.49 -> 0.51 upward crossings. It stayed false through 0.8, 1.0, 1.0 and 0.7 of the same pull. In _unhandled_input (which does receive the events headless), InputEvent.is_action_pressed(fast_forward) was true for 9 of the 19 events, i.e. for EVERY motion event at or above 0.5 (0.6, 0.8, 1.0, 1.0, 0.7 of one pull count as 5).
  implication: (1) A toggle keyed on Input.is_action_just_pressed fires once per trigger pull, as wanted. (2) A toggle written as `_unhandled_input(event): if event.is_action_pressed(ACTION)` would flip once per motion event, i.e. several times during a single pull of the trigger, and is the wrong mechanism for this binding. (3) Godot applies no hysteresis to an action deadzone: a trigger hovering around 0.5 re-fires just_pressed on every upward crossing. Under a hold that chatter only flickers 1x/2x while it lasts; under a toggle each crossing flips the latch, so a half-pulled trigger could toggle repeatedly. That is a new risk a toggle introduces (mitigation for the planner: a small real-time debounce on toggles, a higher deadzone for this action, or re-arming only after the trigger falls well below the deadzone).

- timestamp: 2026-10-06T20:48:41Z
  checked: Scratch probe C (Input.action_press timing seen by a node processed after the resume point)
  found: C1 press on process_frame (the GUT resume point): jp=true pressed=true level_edge=true that frame, then jp=false while held. C2 press and release in the same frame: jp=true, pressed=false, level_edge=false (only just_pressed sees a sub-frame tap). C3 a node processed AFTER the observer calls action_press: the observer sees jp=false that frame and jp=false the next frame, but pressed=true / level_edge=true the next frame (only the stored-level edge sees it).
  implication: The build-hold idiom `Input.is_action_just_pressed(ACTION) or (pressed and not _was_pressed)` with _was_pressed stored every frame (in every phase) catches all three cases, each exactly once, and never double-counts (C1 has both true on the same frame, giving one toggle). Storing the level every frame in every phase also means a key held from day into the night shows no edge, so it does not toggle on by itself.

- timestamp: 2026-10-06T20:48:41Z
  checked: Scratch probe D (a scratch latch toggle Node: latched flips on that combined edge only while phase == NIGHT; phase_changed to any non-NIGHT phase clears the latch and re-applies; the scale comes from the REAL FastForwardController.scale_for(phase, latched, tuning); waveless prototype map, seed 7, shipped loop_tuning.tres)
  found: D1 tap by day -> 1.0, latch false. D2 night starts with no key -> 1.0. D3 tap at night -> 2.0, still 2.0 five frames later with the key up. D4 tap -> 1.0. D5 tap -> 2.0. D6 ctx.step() until the timed night ends: DAWN after 121 steps, scale 1.0 and latch false with no frame passed (inside the step, through phase_changed). D7 key pressed and held by day -> 1.0. D8 night 2 starts with the key still held -> 1.0, latch false (no edge). D9 fresh tap in night 2 -> 2.0. D10 end_run_in_defeat -> 1.0 at once, latch false. D11 tap on LOST -> 1.0. changed sequence: NIGHT->2.0, NIGHT->1.0, NIGHT->2.0, DAWN->1.0, NIGHT->2.0, LOST->1.0.
  implication: The default semantics (press on, press off, reset to off when the night ends, presses outside NIGHT ignored, same bindings) are implementable entirely inside FastForwardController by replacing the level read with a latch. scale_for, the phase_changed same-step drop, _exit_tree, the single-writer rule and the HUD changed contract all keep working unchanged.

- timestamp: 2026-10-06T20:52:08Z
  checked: Baseline run `bash tools/test.sh -gselect=test_fast_forward` (log in scratchpad/ff_suite.log) and the controller's consumers (grep is_active / get_scale / scale_for / FastForwardController)
  found: Exit 0, Scripts 2, Tests 19, Passing 19 (test_fast_forward_rules.gd 14, test_fast_forward.gd 5). The only non-test consumer of the controller is ui/hud/hud.gd:88-92 (find FastForward, connect changed). git status after the run shows only the two untracked debug files (build/ is git-ignored).
  implication: The hold contract is green as specified, and the change has no consumers to update outside the controller, its two test files and the docs.

## Resolution

root_cause: "Design change, not a defect. input/fast_forward_controller.gd implements fast-forward as a hold. _apply (line 82) computes `scale_for(phase, Input.is_action_pressed(ACTION), _ctx.tuning)` and is called every frame from _process (61-63) and inside the simulation step from _on_phase_changed (77-78), so Engine.time_scale follows the live key level and no on/off state exists. This is the behavior plan 02-13 specified ('Holding the new fast_forward action ...' 02-13-PLAN.md:37; 'it is a hold, not a toggle' :92 and fast_forward_controller.gd:15-16). The owner (UAT test 14, G-02-14) wants a toggle: press once for 2x, press again for real time."
fix: "(not applied - diagnose-only) Suggested direction, non-binding. Inside FastForwardController only: add a latched `_wanted_on: bool` and a stored `_was_pressed: bool`. In _process, compute `pressed = Input.is_action_pressed(ACTION)` and `edge = Input.is_action_just_pressed(ACTION) or (pressed and not _was_pressed)` (the input/build_hold_controller.gd:59-69 idiom), store _was_pressed every frame in every phase, flip _wanted_on on an edge only while phase == NIGHT, then _apply via `scale_for(phase, _wanted_on, tuning)` (rename `held` to `on`; body unchanged). In _on_phase_changed, clear _wanted_on when new_phase != NIGHT before _apply, so dawn, victory and defeat drop to 1.0 in the same step and each night starts at real time. Keep the bindings, _exit_tree, the changed signal and the HUD as they are. Do NOT toggle from _unhandled_input on event.is_action_pressed (probe A: every trigger motion event above 0.5 reports pressed, so one pull would flip it several times). Consider a small real-time debounce or a higher deadzone against trigger chatter at 0.5. Fix WR-01 (add_child_autofree in _controller_on) in the same change, because a leaked latched controller would flip on every later test's press."
verification: "Diagnosis verified by full reads, greps, a headless scratch probe on the project's real InputMap and real scale_for (axis edges, action_press timing, a scratch latch through dawn, a second night and defeat), and a baseline run of both fast-forward suites (19/19). No source, scene, test or doc file changed."
files_changed: []
tests_that_change_meaning:
  unit_test_fast_forward_rules:
    - "_controller_on (42-47): add_child -> add_child_autofree (WR-01). Under a toggle a leaked controller stays latched after release_all_actions and flips on every later press, writing Engine.time_scale and appending to the shared _changes."
    - "T1 test_the_shipped_scale_applies_only_to_a_held_night (63-65) and T2 test_every_other_phase_runs_at_real_time_even_when_held (68-76): assertions stay (scale_for's bool now means 'switched on'). Names and messages change ('held at night' -> 'switched on at night', 'not held' -> 'switched off')."
    - "T5 test_fast_forward_held_by_day_changes_nothing_then_runs_the_night_at_2x (95-111): 'held by day stays at real time' becomes 'a press by day changes nothing and does not arm the next night'. Then press at night -> 2.0 with changed [[true,2.0]], release -> STILL 2.0 (new), press again -> 1.0 with [[true,2.0],[false,1.0]]. 'released is real time' becomes 'pressed again is real time'."
    - "T6 test_a_night_that_starts_while_the_key_is_already_down_runs_fast (114-121): inverts to 'a key held from day into the night does not switch fast-forward on; the night starts at real time until a fresh press'. This is the test WR-01 masks."
    - "T7 defeat drop (123-130): setup becomes press-and-release to switch on (not a hold). The same-step 1.0 assertion stays. Add: the switch is cleared (is_active false) and a press on LOST does nothing."
    - "T8 dawn drop (133-145): 'with the key still held' becomes 'with fast-forward still switched on'. 'a key held across dawn resumes fast-forward when the next night starts' becomes 'the switch resets at dawn, so the next night starts at real time unless pressed again' (step on to DAY, start night 2, expect 1.0)."
    - "T9 free restores (148-155): setup becomes switched on (press, release). The assertion stays."
    - "T10-T14 (scene node, doubled deltas, clamp, single-writer scan, simulation scan): unchanged."
    - "New toggle tests to add: one long hold (many frames) toggles once; one trigger pull fed as several InputEventJoypadMotion above 0.5 toggles once (guards the _unhandled_input trap); a sub-frame tap still toggles; victory (WON) also clears the switch."
  e2e_test_fast_forward:
    - "header (2-4): 'holding the fast_forward input' -> pressing it toggles."
    - "E1 test_holding_fast_forward_by_day_changes_nothing (71-81): becomes 'pressing by day changes nothing'. Optionally add: the night then starts at 1.0 with the label hidden."
    - "E2 test_the_label_shows_while_a_night_is_fast_forwarded_and_hides_on_release (84-99): 'hides on release' becomes 'stays shown after release, hides on the second press'. After action_release expect 2.0 and label visible, then press again and expect 1.0 and label hidden."
    - "E3 king pace (102-112) and E4 tick rate (115-125): pass unchanged under press-to-latch (the press they keep held counts as one press). Better to release after the press so they prove the latch."
    - "E5 test_the_label_is_hidden_at_dawn_even_while_the_key_is_still_held (128-145): becomes 'hidden at dawn while fast-forward is still switched on'. Add: the next night starts with the label hidden."
    - "after_each (22-24) stays (Engine.time_scale = 1.0, release_all_actions). The map is add_child_autofree, so a latched controller dies with it and _exit_tree restores 1.0."
  other_tests:
    - "tests/unit/test_input_map.gd: bindings unchanged. Doc comment 144 ('is a hold on the left trigger') changes. FAST_FORWARD_DEADZONE (58, 146-149) changes only if the planner raises the deadzone against chatter."
    - "tests/unit/test_loop_tuning_contract.gd:167 doc comment only ('holding fast_forward at night')."
    - "No HUD test reads %FastForwardLabel besides test_fast_forward.gd. test_map_binding.gd's connection table does not include changed."
docs_that_state_the_hold:
  - "input/fast_forward_controller.gd:3-4, 15-16 (hold, not a toggle), 32 (scale_for doc 'held')"
  - "simulation/defs/loop_tuning.gd:53 ('while the fast_forward input is held')"
  - "tests: test_fast_forward_rules.gd:2, test_fast_forward.gd:2-3, test_input_map.gd:144, test_loop_tuning_contract.gd:167"
  - ".planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md:20 (hold F), :30 controls row 'Fast-forward (hold, night only, 2x)', :72 assumption 14 ('held ... a key held across dawn resumes it')"
  - "02-BALANCE-REPORT.md:24, 02-SECURITY.md:67 (T-02-29 'or when not held'), 02-VERIFICATION.md:88/114/167/188, ROADMAP.md:150 ('night-only hold-to-fast-forward')"
  - "No player-facing string says hold: the HUD label reads only 'Fast-forward 2x', and no in-game controls hint exists"
determinism: "Unaffected. Only fast_forward_controller.gd writes Engine.time_scale. Nothing under simulation/ mentions time_scale. Replays and the smoke golden bypass the controller (ctx.step). The smoke and full_idle digests cannot move."
