---
schema_version: 1
open_count: 3
waived_count: 1
fixed_count: 0
total_count: 4
last_updated: 2026-10-14T12:23:42.334Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | stub | presentation/buildings/building_views.gd |  | Placeholder primitive shapes for spots/buildings until CC0 models (plan 01-07) | open |  | 2026-09-29T08:22:35.384Z |  |
| 2 | 03 | stub | presentation/buildings/building_views.gd |  | Barracks and Archery Range draw as the House-style primitive box (no building_view_catalog entry); only the plot marker is distinct. A later Phase 3 plan owns military building visuals | open |  | 2026-10-10T09:03:52.508Z |  |
| 3 | 03 | stub | simulation/defs/building_tier_def.gd |  | squad_respawn_seconds is authored (10/7/4 s) but not read until the night respawn rule in plan 03-02 | open |  | 2026-10-10T09:03:53.157Z |  |
| 4 | 03 | unmet-truth | tools/screenshot/shot_army_scenarios.gd |  | 03-12 E6: the longest toast is 526 px wide at x 377..903 (one line, below the clear centre), 7 px past the literal x 384..896 band; owner decides at the Phase 3 gate | waived | Owner decision D-29 (UAT round 3, 2026-10-14): both long toasts (526 px and 540 px, y 504..536, below the protected centre) are accepted as written and the UI-SPEC toast bound is amended to the measured lines; the x 384..896 band binds the protected rectangle, not the toast row | 2026-10-12T08:02:41.697Z | 2026-10-14T12:23:42.334Z |

````json
[
  {
    "id": 1,
    "kind": "stub",
    "phase": "01",
    "file": "presentation/buildings/building_views.gd",
    "line": null,
    "description": "Placeholder primitive shapes for spots/buildings until CC0 models (plan 01-07)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-29T08:22:35.384Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 2,
    "kind": "stub",
    "phase": "03",
    "file": "presentation/buildings/building_views.gd",
    "line": null,
    "description": "Barracks and Archery Range draw as the House-style primitive box (no building_view_catalog entry); only the plot marker is distinct. A later Phase 3 plan owns military building visuals",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-10T09:03:52.508Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 3,
    "kind": "stub",
    "phase": "03",
    "file": "simulation/defs/building_tier_def.gd",
    "line": null,
    "description": "squad_respawn_seconds is authored (10/7/4 s) but not read until the night respawn rule in plan 03-02",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-10T09:03:53.157Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 4,
    "kind": "unmet-truth",
    "phase": "03",
    "file": "tools/screenshot/shot_army_scenarios.gd",
    "line": null,
    "description": "03-12 E6: the longest toast is 526 px wide at x 377..903 (one line, below the clear centre), 7 px past the literal x 384..896 band; owner decides at the Phase 3 gate",
    "status": "waived",
    "reason": "Owner decision D-29 (UAT round 3, 2026-10-14): both long toasts (526 px and 540 px, y 504..536, below the protected centre) are accepted as written and the UI-SPEC toast bound is amended to the measured lines; the x 384..896 band binds the protected rectangle, not the toast row",
    "recorded_at": "2026-10-12T08:02:41.697Z",
    "resolved_at": "2026-10-14T12:23:42.334Z",
    "milestone": null
  }
]
````
