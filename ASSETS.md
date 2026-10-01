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
| Kenney Castle Kit 2.0 | model | CC0-1.0 | Kenney (www.kenney.nl) | https://kenney.nl/assets/castle-kit | `assets/third_party/kenney_castle_kit/` (7 GLBs + colormap; tower tiers I-II, castle center) | 2026-09-29 | `921f3f73927bb23106cae34bc21d5ab4b033a9fc120475e96f714a406e3169df` |
| Kenney Fantasy Town Kit 2.0 | model | CC0-1.0 | Kenney (www.kenney.nl) | https://kenney.nl/assets/fantasy-town-kit | `assets/third_party/kenney_fantasy_town_kit/` (7 GLBs + colormap; House tiers I-III) | 2026-09-29 | `1a7530c09f4d2fa2cdee259876f089334f8b1f27fa86a0c4f54ef86cdd8676ef` |
| Kenney Mini Characters 1.0 | model | CC0-1.0 | Kenney (www.kenney.nl) | https://kenney.nl/assets/mini-characters | `assets/third_party/kenney_mini_characters/` (1 GLB + colormap; the king's rider) | 2026-09-29 | `9e1d48e6d7b8479ebbe84df71eb5bd8e1b3f0da546dea641890dccc8a02d0999` |
| Horse (animated), Quaternius 2021 | model | CC0-1.0 | Quaternius | https://poly.pizza/m/qvTrSG9pZF (file: https://static.poly.pizza/d37dbc87-ca61-4b2c-a2da-d2f0c4240bef.glb) | `assets/third_party/quaternius_horse/` (1 GLB; the king's horse) | 2026-09-29 | `fae7a7ec91e0d6a33554efb896fac9c4e8c632644183bcb8cc962f673d3ce609` (of the GLB itself) |

## Archive checksums and download evidence

What each SHA256 in the table covers (all retrieved 2026-09-29; each entry's `notes` in
`assets/attribution.json` has the download URL and byte size):

- Kenney Castle Kit, Fantasy Town Kit and Mini Characters: the zip archive as downloaded (these three zips
  and the horse GLB below were fetched with `curl --fail`, no redirects, and each size matched the
  owner-approved figure exactly; recorded in plan 01-07's summary). Only the files
  listed in each entry's `notes` were extracted into the repository, so the archives themselves are not
  here and the hash cannot be recomputed from the repository. Each pack's `License.txt` (CC0, with the
  Creative Commons Zero link) sits beside its files.
- GUT 9.7.1: the v9.7.1 source zip. The zip is not in the repository; its contents are vendored under
  `addons/gut/`, so the hash does not match any file here. It was fetched by `tools/bootstrap.py` (plan
  01-01), not by the `curl` downloads above.
- Horse: the single GLB downloaded from Poly Pizza (no archive exists), which is the file kept in
  `assets/third_party/quaternius_horse/`, so that hash can be recomputed from the repository.
- Godot Engine: no SHA256 is recorded (the table shows "n/a"). The editor and export-template archives are
  verified by SHA512 against the official sums pinned in `tools/godot_sha512sums.txt`.

## Horse licence: re-checked and kept (2026-10-01)

The horse comes from Quaternius's 2021 "Ultimate Animated Animals" pack via Poly Pizza. On 2026-09-29 its Poly
Pizza page stated "Public Domain (CC0)" and linked the CC0 1.0 deed, and the 2021 pack page stated "License
CC0". Quaternius's licence page (https://quaternius.com/license.html) now shows the "Quaternius Asset License
(QAL) v1.0", last updated 8/28/2026, which forbids redistributing "the Assets themselves ... as a standalone
asset" and says "the version in effect at the time you obtained the Assets governs your use of them".

Re-checked on 2026-10-01: https://quaternius.com/packs/ultimateanimatedanimals.html still states "License:
CC0" and links the CC0 1.0 deed, and https://poly.pizza/m/qvTrSG9pZF still states "Public Domain (CC0)". The QAL
v1.0 page says nothing about assets earlier released under CC0.

The two quotes of the 2021 pack page ("License CC0" on 2026-09-29, "License: CC0" on 2026-10-01) are the same
licence line transcribed on different dates; the 2026-10-01 re-check came from a web-to-markdown fetch, which may
have added the colon. Both name CC0, and neither quote has been altered from what was recorded.

The QAL v1.0 (last updated 8/28/2026) predates the 2026-09-29 retrieval, so its "version in effect at the time
you obtained the Assets" clause does not by itself favour CC0. The keep decision rests on the author's own 2021
pack page and the Poly Pizza page both stating CC0 when the model was retrieved (checked 2026-09-29, re-checked
2026-10-01), and on an earlier CC0 dedication being irrevocable. The owner accepts the residual risk
(2026-10-01).

Owner decision (2026-10-01): keep the horse, recorded as CC0-1.0, on the grounds above. It is used inside a
game, but the unmodified GLB is also committed (Git LFS) to the public repository ABSAR07/duskhold and ships in
the exported build. CC0 allows both; if the QAL governed instead, the public copy could count as the "standalone
asset" redistribution it forbids. The owner also accepts this risk (2026-10-01). The same evidence is kept in
`assets/third_party/quaternius_horse/License.txt` and in the `quaternius-horse` entry's `notes` in
`assets/attribution.json`.

## Composition notes

- The Fantasy Town Kit has no complete house model, so the three House tiers are composed from its wall,
  roof and chimney pieces in the wrapper scenes under `presentation/buildings/models/`.
- The Mini Characters pack has no crowned figure. `character-male-b` is the rider; the gold crown is a small
  primitive added in `presentation/king/king_model.tscn`.

## How to add an asset

1. Put the files in a new folder `assets/third_party/<pack_id>/`. Never nest one pack folder inside another.
2. Keep the pack's own license file in that folder.
3. Verify the license on the source's own license page (not a marketplace listing) and record it as `CC0-1.0` or `MIT`.
4. Add an entry to `assets/attribution.json` (keep entries sorted by `id`): `id`, `name`, `kind`, `license`, `author`, `source_url`, `license_url`, `paths`, `retrieved`, `sha256` (of the downloaded archive, or of the file itself when there is no archive; say which in `notes`, see "Archive checksums and download evidence" above), `ships_in_build` and `notes`.
5. Add the matching row to the table above, in the same order.
6. Run `bash tools/test.sh`; `test_attribution_log` fails if anything is uncovered, unsorted or under a disallowed license.
