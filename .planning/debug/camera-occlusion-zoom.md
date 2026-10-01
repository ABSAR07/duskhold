---
status: diagnosed
trigger: "UAT G-01-3 (test 3, Follow camera framing): king hidden behind buildings; camera too close; no zoom buttons"
created: 2026-10-01T21:52:26Z
updated: 2026-10-01T22:40:00Z
goal: find_root_cause_only
bug_class: Bohrbug (deterministic; reproduces every time) - feature/design gap rather than a code defect
---

## Current Focus

hypothesis: CONFIRMED (three independent parts) - 1) no rendering path lets the king show through opaque buildings (no x-ray/silhouette/fade anywhere), and the 55.5 deg pitch vs a 10.1 m castle makes a ~4 m band behind the keep where the king is hidden; 2) the untuned first-pass framing (offset (0,16,11) = 19.4 m, fov 40) shows only ~25 x 18 m of ground; 3) zoom was deliberately excluded in plan 01-04 (no action, no state, no logic)
test: done - headless ray-cast occlusion measurement against the real meshes, windowed Forward+ and Compatibility renders of the king behind the keep, runtime feasibility probe of 3 occlusion techniques in both renderers, analytic framing table
expecting: n/a (diagnose-only)
next_action: return ROOT CAUSE FOUND to orchestrator (goal find_root_cause_only); no fix applied

reasoning_checkpoint:
  hypothesis: "Part 1: the king vanishes behind buildings because every king and building material is a plain opaque, depth-tested BaseMaterial3D and the project has no occlusion-reveal mechanism (no stencil x-ray, no inverted-depth pass, no occluder fade); with the fixed 55.5 deg pitch, any building taller than the king hides him within a band behind it (castle keep 10.12 m -> ~4 m band). Part 2: the camera is too close because CameraRig.offset defaults to (0,16,11) (19.4 m) with Camera3D fov 40, an untuned first-pass value. Part 3: there is no zoom because plan 01-04 specified 'no rotate, zoom or mouse handling' and no zoom action exists."
  confirming_evidence:
    - "grep: no stencil/x-ray/next_pass/render_priority/transparency/fade/shader anywhere in game code; only SpotLabel uses no_depth_test"
    - "Headless ray-cast vs real meshes: king 100% hidden 0.5 m behind the castle's north face, 85% at 1.5 m, 74% at 2.5 m, 29% at 3.5 m, 0% from 4.5 m; tower_t2 100% to 3.5 m; house_t3 100% to 2.5 m; control in front 0%"
    - "Windowed Forward+ render at (0,0,-5.5): only arm tips and a crown sliver visible; same frame with castle hidden shows the full king at screen centre"
    - "Spawn frame at (0,0,7): castle top cut off by the frame, House plots at (+-9,9) at the screen edges -> framing too tight"
    - "camera_rig.gd:4 'no zoom, no orbit, no mouse'; 01-04-PLAN.md:178,238; project.godot has 8 actions, none for zoom"
  falsification_test: "If an occlusion mechanism existed, the windowed render at (0,0,-5.5) would show the king (it does not). If pulling back alone fixed occlusion, the 1.5x same-angle ray-cast would read ~0% (it reads 100/68/51/18%)."
  fix_rationale: "Part 1 needs a rendering-level reveal; stencil X-Ray on the king's materials was verified at runtime to draw a silhouette only where occluded, in both Forward+ and Compatibility, with no false positives when unoccluded. Part 2 is a tuning change to the offset default (and optionally exporting fov). Part 3 is a new presentation-only feature (dolly along the fixed offset direction, clamped) plus new Input Map actions inside the existing contract."
  blind_spots: "Gamepad/real-player feel of zoom range not testable here; X-Ray look at night lighting (UI-05) not rendered; perf cost of stencil passes measured only on an RTX 3060, not the GTX 970 target; Compatibility verified on the Windows NVIDIA GL driver, not on CI's Mesa llvmpipe under xvfb"
  candidate_causes:
    - "code: no occlusion-reveal path for the king (primary, part 1); CameraRig has no zoom state or input (part 3)"
    - "config/data: offset (0,16,11) + fov 40 framing (part 2); camera pitch 55.5 deg vs building heights (castle 10.12 m, tower_t2 7.83 m, house_t3 6.6 m) sets the occlusion band (contributing to part 1); buildings have no collision, so the king can ride flush against or into them (contributing)"
    - "environment: renderer - eliminated (same occlusion in Forward+ and Compatibility)"
    - "process: 01-04 human-check on framing/readability was never performed (01-04-SUMMARY.md:107,205), so framing went unreviewed until UAT"
  and_gate: "yes for part 1 - occlusion requires BOTH a tall opaque building between camera and king (geometry/data) AND no reveal mechanism (code). The geometry condition cannot be removed in a Thronefall-style angled view (1.5x distance or a 65 deg pitch still hides the king), so the actionable cause is the missing reveal mechanism. Parts 2 and 3 are single-cause."

## Symptoms

expected: The camera keeps one fixed angle (the player cannot rotate it), trails slightly behind the king and catches up, and keeps the king readable near the centre of the screen.
actual: (owner, verbatim) "mostly good, but when the king goes behind a building like behind the castle, his silhouette is not visible. The king disappears behind stuff basically. Is that intentional? / I think we should move the camera a bit further away. Also should have buttons that zoom out or zoom in, to a certain extent"
errors: None reported
reproduction: UAT test 3 - ride the king behind the castle keep or a House in the prototype map
started: Discovered during UAT on 2026-10-02 (behaviour present since plan 01-04 / 01-07)

## Eliminated

- hypothesis: An occlusion-reveal mechanism exists but is misconfigured or broken
  evidence: repo-wide grep finds no stencil/x-ray/next_pass/render_priority/transparency/fade/shader code for the king or buildings; the king and building scenes use unmodified GLB StandardMaterial3Ds
  timestamp: 2026-10-01T22:05:00Z

- hypothesis: Moving the camera further away (the part-2 fix) also solves occlusion
  evidence: headless ray-cast at 1.5x offset, same angle (0,24,16.5): king still 100% / 68% / 51% / 18% hidden at 0.5 / 1.5 / 2.5 / 3.5 m behind the castle (vs 100 / 85 / 74 / 29% at 1.0x)
  timestamp: 2026-10-01T22:10:00Z

- hypothesis: A steeper fixed pitch alone removes occlusion
  evidence: at about 65 deg (0,18,8.4) the king is still 93% hidden 0.5 m behind the castle and 100% behind tower_t2 to 2.4 m; the band shrinks but does not go away, and a steeper pitch moves away from the three-quarter Thronefall view
  timestamp: 2026-10-01T22:10:00Z

- hypothesis: Occlusion is renderer-specific (Forward+ vs Compatibility)
  evidence: the king is hidden identically in the Forward+ baseline and in the Compatibility run (compat_0_baseline and compat_C, where instance transparency is ignored)
  timestamp: 2026-10-01T22:25:00Z

- hypothesis: Fading occluders with GeometryInstance3D.transparency is a cross-renderer fix
  evidence: runtime probe - castle meshes transparency=0.65 fade in Forward+ but are IGNORED in Compatibility (king still hidden in compat_C_castle_instance_transparency.png); Forward+ also shows sorting artifacts on the faded keep
  timestamp: 2026-10-01T22:25:00Z

## Evidence

- timestamp: 2026-10-01T21:52:26Z
  checked: .planning/debug/ and knowledge-base.md
  found: directory did not exist; no knowledge base, no prior sessions; MemPalace not consulted (no KB to fall back on)
  implication: no known-pattern candidate; investigate from scratch

- timestamp: 2026-10-01T22:00:00Z
  checked: presentation/camera/camera_rig.gd (all 27 lines), presentation/map/prototype_map.tscn:78-83
  found: CameraRig exports offset = Vector3(0,16,11) (line 8) and follow_sharpness = 6.0 (line 10); bind_run snaps to king+offset and calls _camera.look_at(king) ONCE (lines 17-20); _physics_process only lerps position (lines 23-27). Camera3D child in prototype_map.tscn:81-83 has fov = 40.0 (vertical, default keep_aspect) and current = true; fov is NOT exported on the rig, it lives only in the scene. Class doc line 4 states "no zoom, no orbit, no mouse".
  implication: framing is fully determined by offset (distance ~19.4 m, pitch ~55.5 deg down, yaw 0) plus fov 40; there is no zoom state, no zoom input read, no clamp. Pitch is implied by offset direction, so scaling offset by a scalar keeps the angle (KING-02) intact.

- timestamp: 2026-10-01T22:00:00Z
  checked: grep across repo (excluding addons/) for zoom|occlu|silhouette|xray|see-through|outline|no_depth_test|depth_test|render_priority|next_pass|transparen|fade
  found: only hits in game code are ui/world/spot_label.tscn (Label3D no_depth_test + outline, lines 14/23/36) and spot_label.gd:92 (coin sprites no_depth_test); camera_rig.gd:4 comment "no zoom". No ShaderMaterial / .gdshader anywhere in tracked files; no next_pass, no render_priority, no transparency, no fade logic on buildings, no RayCast/occlusion check in camera or building views.
  implication: NOTHING in the project handles king occlusion. The king renders with ordinary opaque depth-tested materials and is hidden whenever any opaque building fragment is nearer to the camera.

- timestamp: 2026-10-01T22:00:00Z
  checked: presentation/king/king.tscn, presentation/king/king_model.tscn, presentation/king/king.gd
  found: King = CharacterBody3D + capsule collision + Model/KingModel. KingModel = Quaternius horse GLB (scale 0.42) + Kenney character-male-b GLB (scale 1.6, y 1.4) + Crown MeshInstance3D with a plain StandardMaterial3D (king_model.tscn:6-9: albedo gold, metallic 0.6, roughness 0.35). No surface_material_override, no material_overlay, no next_pass, no render layers set on any king mesh; GLB-imported materials are used unchanged.
  implication: there is no hook (overlay/next_pass/second mesh) on the king that could draw a silhouette when occluded.

- timestamp: 2026-10-01T22:00:00Z
  checked: presentation/buildings/models/*.tscn (castle_center, house_t1..t3, tower_t1..t2)
  found: all are Node3D wrappers that instance Kenney GLB pieces under a scaled Model node (castle x2.4 with keep base+mid+roof-high+flag at y up to 3.35 units and 4 corner turrets at +-1 unit; house x2 with 1-2 wall storeys + gable/high-gable roof; tower x1.8 with 3-4 storeys). No material overrides, no transparency, no per-building fade script, no collision shapes.
  implication: buildings are fully opaque, tall relative to the 2.5 m king, and have no mechanism to become see-through.

- timestamp: 2026-10-01T22:00:00Z
  checked: project.godot [input] (lines 30-84), tests/unit/test_input_map.gd
  found: exactly 8 project actions: move_left (A, Left, LX-), move_right (D, Right, LX+), move_forward (W, Up, LY-), move_back (S, Down, LY+), sprint (Shift, joy 10 RB), action_build (Space, E, joy 0 A), start_night (N, joy 3 Y), toggle_debug_overlay (F3, joy 4 Back). No zoom action. test_input_map.gd: GAMEPLAY_ACTIONS list (6-15), EXPECTED_KEYS (17-26) and EXPECTED_BUTTONS (28-33) tables with exact count asserts (93, 102), test_no_project_action_has_a_mouse_binding (124-128) iterates EVERY non-ui_ action, every GAMEPLAY_ACTION needs >=1 key and >=1 pad event (75-86).
  implication: no zoom input exists; a zoom action added to project.godot is automatically subject to the no-mouse test (so mouse wheel is forbidden), and should be added to GAMEPLAY_ACTIONS + EXPECTED_KEYS + EXPECTED_BUTTONS/AXES to stay inside the contract.

- timestamp: 2026-10-01T22:00:00Z
  checked: tests/e2e/test_king_ride.gd:111-161, tools/screenshot/shot_scenarios.gd, ui/world/spot_label.tscn, ui/hud/dawn_payout_vfx.gd:314-329, tests/e2e/test_dawn_payout.gd:236-258
  found: camera tests read rig.offset dynamically (138, 153) rather than literals, assert XZ within 0.5 m of king+offset after 1 s (132-144), lag >1 m then catch-up within 2 s after a 25 m teleport (147-161), and camera.global_basis unchanged after riding all 4 directions (120-129). No test pins fov or the literal (0,16,11). Screenshot scenarios wait CAMERA_SETTLE_S = 1.2 s and only blank-check images. SpotLabel Label3Ds are world-sized (pixel_size 0.01, no fixed_size), so they shrink on screen as the camera moves away. dawn_payout_vfx unprojects plot positions through the current camera (with behind-camera fallback).
  implication: changing the offset default does not break existing tests as long as settle stays within 1 s/2 s; a zoom that changes the rig's effective offset must keep basis constant and keep the "settles at rig offset" contract coherent (test reads rig.offset, so the zoomed offset must be what rig.offset reports or the test must read the effective offset). Label legibility (UAT 6) bounds the max zoom-out.

- timestamp: 2026-10-01T22:08:00Z
  checked: grep for StaticBody3D/CollisionShape3D/collision_layer in presentation, ui, input, simulation; presentation/map/prototype_map.tscn Ground node
  found: the only collision shape in the game is the king's own capsule (king.tscn:15). Buildings, castle and ground have no bodies (BuildingViews only adds MeshInstance3D; the ground is a bare PlaneMesh).
  implication: contributing condition - the king can ride flush against or into the castle and houses, deepening occlusion. Not the root cause: he is also hidden 1.5 to 3.5 m clear of the walls.

- timestamp: 2026-10-01T22:10:00Z
  checked: scratch headless script (scratchpad/occlusion.gd, outside repo) - trimesh colliders from the real building meshes' get_faces(), physics ray-casts from camera (king + offset) to 405 sampled king-model vertices, king walked north from each building's north face
  found: model sizes - castle_center 7.2 x 10.12 x 7.2 m (AABB y top 10.12); house_t1 2.2 x 3.14 x 2.14; house_t3 4.2 x 6.6 x 2.27; tower_t2 1.8 x 7.83 x 1.8; king model 1.23 x 2.62 x 2.38. Occluded fraction at the CURRENT offset (0,16,11), metres behind the north face - castle 0.5:100% 1.5:85% 2.5:74% 3.5:29% 4.5:0%; tower_t2 0.5-2.5:100% 3.5:93% 4.5:27%; house_t3 0.5:99% 1.5:100% 2.5:59%; house_t1 0.5:60% 1.5:18%. Control (king on the camera side): 0% for every building.
  implication: occlusion is deterministic and geometric. Every model taller than the king creates a hidden band behind it, about 4 m for the castle keep (the owner's example).

- timestamp: 2026-10-01T22:15:00Z
  checked: windowed Forward+ render (RTX 3060, Vulkan) of the real prototype_map.tscn via a scratch SceneTree script; king teleported, camera allowed to settle 1.5 s; images in session scratchpad (fwd_a/b/c/d_*.png)
  found: (b) king at (0,0,-5.5), 1.9 m behind the keep - only two arm tips and a sliver of crown poke out beside the roof spire; (c) the same frame with CastleCenter.visible=false shows the full king at screen centre; (d) at 3.0 m behind, the spire still splits the king. Camera reports fov 40, pitch -55.49 deg, and the rotation is unchanged after moves. (a) control at spawn (0,0,7): king fully visible, but the castle (centre 7 m away) runs off the top of the frame and the House plots at (+-9, 9) sit at the left/right screen edges.
  implication: direct visual reproduction of part 1; (a) is direct evidence for part 2 (framing too tight to show the castle plus the first House ring).

- timestamp: 2026-10-01T22:20:00Z
  checked: ClassDB of the pinned Godot 4.7.2 binary (scratch classdb.gd)
  found: BaseMaterial3D has stencil_mode {Disabled, Outline, X-Ray, Custom}, stencil_color, stencil_flags/compare/reference, depth_test {Default, Inverted}, no_depth_test, distance_fade_mode, plus Material.next_pass/render_priority. GeometryInstance3D has material_overlay, material_override and transparency.
  implication: the engine offers built-in, shader-free x-ray and silhouette primitives (added in 4.5); the project uses none of them.

- timestamp: 2026-10-01T22:25:00Z
  checked: runtime feasibility probe (scratch techniques.gd), king at (0,0,-5.5), rendered in Forward+ and in Compatibility (--rendering-method gl_compatibility --rendering-driver opengl3, the CI screenshot renderer)
  found: A) duplicating the king's 11 surface materials (Horse surfaces, body-mesh, head-mesh, Crown - all StandardMaterial3D) with stencil_mode = STENCIL_MODE_XRAY and stencil_color draws a flat cyan silhouette exactly where the keep hides the king, while the visible parts (arms, crown) stay normally shaded - works in BOTH renderers. B) a material_overlay StandardMaterial3D (unshaded, depth_test = DEPTH_TEST_INVERTED, depth_draw never) also works in both, but tints the king's own self-occluded parts (cyan stripes on the visible arms). C) GeometryInstance3D.transparency = 0.65 on the castle meshes fades the keep in Forward+ (with sorting artifacts) and is IGNORED in Compatibility (the king stays hidden).
  implication: stencil X-Ray on the king's materials is the approach that fits this project (Forward+ locally and Compatibility in CI). Occluder fading via instance transparency fails in CI screenshots, and a material-alpha fade would also need per-frame occluder detection, which is harder because buildings have no physics bodies.

- timestamp: 2026-10-01T22:32:00Z
  checked: falsification of the X-Ray direction - king in the open at (-4,0,14), X-Ray applied, cropped 2x in both renderers; control crop without X-Ray
  found: with X-Ray the crops are identical to the no-X-Ray control. The blue collar and head sliver are the Kenney texture's own colours, and there is no tint on self-overlap and no hoof/ground z-fighting.
  implication: the stencil X-Ray preset has no false positives when the king is unoccluded.

- timestamp: 2026-10-01T22:35:00Z
  checked: analytic framing of the current rig (offset (0,16,11), vertical fov 40, 1280x720) and of same-angle dolly scales
  found: 1.00x = 19.4 m from the king, pitch 55.5 deg, ground visible z -11.4..+6.9 m around the king (18.3 m deep) by 25.1 m wide at the king, about 51 px/m -> SpotLabel title (font 48 x pixel_size 0.01 = 0.48 m) about 24 px tall. 1.25x = 24.3 m, 31.4 x 22.9 m, title about 20 px. 1.5x = 29.1 m, 37.7 x 27.4 m, title about 16 px. 1.75x = 34.0 m, 44 x 32 m, title about 14 px. 2.0x = 38.8 m, 50 x 37 m, title about 12 px. The base core (castle plus five House plots incl. marker radius) spans about 39 m (x +-19.6) by 36 m (z -25.6..+10.6); the map spans 110 m.
  implication: the current view cannot even hold the castle plus the first House ring. About 1.5x distance frames the whole base core. Label legibility (world-sized Label3D) is the practical cap on zoom-out unless the labels move to fixed_size or scale with zoom.

- timestamp: 2026-10-01T22:36:00Z
  checked: .planning/phases/01-foundation-day-loop/01-04-PLAN.md:175-178,191,238; 01-04-SUMMARY.md:12,107,205; 01-RESEARCH.md:414; 01-CONTEXT.md:120; REQUIREMENTS.md:24
  found: the offset (0,16,11), fov 40 and "no rotate, zoom or mouse handling" were the planner's discretionary first pass ("Angle and offset are exported properties that can be tuned at the Phase 2 playtest"); research had suggested an even closer (0,14,10). The plan's human-check on framing and readability was never performed (01-04-SUMMARY:107, 205). KING-02 reads only "The camera follows the king from a fixed isometric-style angle" - it forbids rotation, not zoom.
  implication: parts 2 and 3 are untuned and unreviewed design defaults, not code defects. A zoom that dollies along the fixed offset direction is compatible with KING-02.

- timestamp: 2026-10-01T22:37:00Z
  checked: REQUIREMENTS.md KING-04, UNIT-05, UNIT-06, INPT-01; ROADMAP.md Phase 3 criteria 2-4, Phase 13 rebinding
  found: Phase 3 will add an active-ability action and unit hold/follow hotkeys (all units or one unit type), all on keyboard and gamepad with device-aware prompts. Phase 13 adds rebinding.
  implication: zoom bindings should avoid the keys and buttons Phase 3 is likely to want (face buttons B/X, bumpers, keys next to WASD such as Q/R/F/1-4) and use the axes that have no other use under a fixed camera.

## Resolution

root_cause: "Part 1 (king hidden): the project has no occlusion-reveal path. The king's GLB StandardMaterial3Ds (king_model.tscn: Horse, Rider body/head, Crown) and the building models are ordinary opaque, depth-tested materials. No stencil x-ray, inverted-depth silhouette, outline or occluder fade exists anywhere, so at the fixed 55.5 deg pitch any model taller than the 2.6 m king hides him in a band behind it (castle keep 10.12 m -> ~4 m band: 100/85/74/29% hidden at 0.5/1.5/2.5/3.5 m). Contributing: buildings have no collision, so the king can ride flush against or into them. Part 2 (too close): CameraRig.offset defaults to Vector3(0,16,11) (camera_rig.gd:8; the prototype_map.tscn CameraRig node does not override it) with Camera3D fov 40 (prototype_map.tscn:82, not exported on the rig). That is 19.4 m from the king, a 25 x 18 m ground window that cannot hold the castle plus the first House ring - an untuned first-pass value whose human framing check was skipped in 01-04. Part 3 (no zoom): by design in plan 01-04 (camera_rig.gd:4 'no zoom, no orbit, no mouse'; 01-04-PLAN.md:178,238). No zoom action exists in project.godot [input], and CameraRig has no zoom state, clamp or input read."
fix: (diagnose only - not applied)
verification: (diagnose only)
files_changed: []

