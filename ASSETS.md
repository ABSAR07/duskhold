# Third-party assets and attribution

Every third-party file in this repository is listed here and in the machine-readable manifest
`assets/attribution.json` (reused by the Phase 13 credits screen). Only these licenses are allowed:

- **CC0-1.0** for art, audio and other assets
- **MIT** for the engine and code

`tests/unit/test_attribution_log.gd` enforces the rules: every file under `assets/third_party/` and
`addons/` belongs to exactly one entry, entry paths never nest, entries are sorted by `id`, and this
table lists them in the same order.

| Name | Kind | License | Author | Source | Paths | Retrieved | SHA256 |
|------|------|---------|--------|--------|-------|-----------|--------|
| Godot Engine 4.7.2 | engine | MIT | Godot Engine contributors | https://godotengine.org/ | none (not in the repository; verified by SHA512, see `tools/godot_sha512sums.txt`) | 2026-09-29 | n/a |
| GUT (Godot Unit Test) 9.7.1 | code | MIT | Tom "Butch" Wesley (bitwes) and contributors | https://github.com/bitwes/Gut/releases/tag/v9.7.1 | `addons/gut/` (test only, not shipped) | 2026-09-29 | `14969aa46adc84aa08cdd21b9f6d1a64addd92ae60b36f02d0521ed305aa4086` |

## How to add an asset

1. Put the files in a new folder `assets/third_party/<pack_id>/`. Never nest one pack folder inside another.
2. Keep the pack's own license file in that folder.
3. Verify the license on the source's own license page (not a marketplace listing) and record it as `CC0-1.0` or `MIT`.
4. Add an entry to `assets/attribution.json` (keep entries sorted by `id`): `id`, `name`, `kind`, `license`, `author`, `source_url`, `license_url`, `paths`, `retrieved`, `sha256` (of the downloaded archive), `ships_in_build` and `notes`.
5. Add the matching row to the table above, in the same order.
6. Run `bash tools/test.sh`; `test_attribution_log` fails if anything is uncovered, unsorted or under a disallowed license.
