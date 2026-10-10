class_name HudRoot
extends Control
## The one container every Phase 3 HUD widget lives under (D-21): the day counter, the king widget,
## the squad strip, the toast and the prompts are all its children. It carries the shared HUD theme
## (ui/theme/hud_theme.tres: white text with a black outline of 6) and spans the whole screen.
## It is mouse_filter IGNORE so it never swallows a click meant for the world (RESEARCH Pitfall 8);
## only an individual button-like widget (a squad slot) may be STOP. It holds no logic.
