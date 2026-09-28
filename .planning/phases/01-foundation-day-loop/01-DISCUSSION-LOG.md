# Phase 1: Foundation & Day Loop - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-29
**Phase:** 01-foundation-day-loop
**Areas discussed:** Prototype map & look, Hold-to-build feel, Economy & day end, Repo, CI & Godot setup

---

## Prototype map & look

**Q: What should Phase 1 look like on screen?**

| Option | Description | Selected |
|--------|-------------|----------|
| Grey shapes + a few CC0 models | Real CC0 models for the king, House, tower and castle; plain shapes for everything else. Screenshots stay readable and the license log gets real entries; the full art pass waits for Phase 8 | ✓ |
| Pure grey shapes | Only capsules, boxes and planes. Fastest, but screenshots are harder to read and the license log stays empty | |
| Full CC0 look now | Dress the whole map with one pack. Looks good early, but pulls art-normalization work into Phase 1 | |

**Q: What decides which building goes on a build spot?**

| Option | Description | Selected |
|--------|-------------|----------|
| Each spot has one fixed type | The map fixes what each spot can hold (as in Thronefall). The action key just builds or upgrades it, with no picker menu | ✓ |
| Pick at the spot | Any spot can hold any building; choose from a small picker before holding. More freedom, but adds a menu step and departs from Thronefall | |

**Q: How big should the prototype map be?**

| Option | Description | Selected |
|--------|-------------|----------|
| Small: castle + ~8 spots | About 5 House plots and 3 tower plots, 20–30 s to ride edge to edge. Enough for trade-offs, quick to test | ✓ |
| Medium: castle + ~14 spots | Closer to a real Thronefall map. Longer rides and more layout work | |
| Tiny: castle + 4 spots | Bare minimum. Too few choices to judge the economy | |

**Q: What happens to the prototype map once the real campaign maps exist?**

| Option | Description | Selected |
|--------|-------------|----------|
| Keep it as a test map | Permanent sandbox for tests, screenshots and replays; never ships as a campaign level. Campaign maps are designed fresh in Phase 9 | ✓ |
| Grow it into campaign map 1 | Saves a map, but changes to map 1 would break the test and screenshot scenes | |

**User's choice:** All recommended options.

---

## Hold-to-build feel

**Q: How long does the build hold take?**

| Option | Description | Selected |
|--------|-------------|----------|
| Coins drip in one by one | Coins fly from the king into the spot at a steady rate, so pricier builds take a bit longer (Thronefall-like) | ✓ |
| Fixed short hold | Every build takes the same ~0.8 s hold with a filling ring | |

**Q: If you let go partway through paying, what happens to the coins already paid?**

| Option | Description | Selected |
|--------|-------------|----------|
| Refund and reset | The full cost is needed to start; letting go early refunds everything | ✓ |
| Paid coins stay on the spot | Partial payment is saved and can be finished later; the spot must remember its progress | |

**Q: When the king is near a spot, where does its info appear?**

| Option | Description | Selected |
|--------|-------------|----------|
| Floating above the spot | A world-space label with the cost as coin icons that fill as you pay, plus a one-line effect | ✓ |
| Panel at the bottom of the HUD | A fixed on-screen panel; more room for text, but your eyes leave the map | |

**Q: What happens when you hold the action key near a spot you can't afford?**

| Option | Description | Selected |
|--------|-------------|----------|
| Red cost + a 'no' bump | Cost always red; holding plays a shake and a denied sound, and no coins move | ✓ |
| Red cost only | Cost turns red and holding does nothing; can read as the key not working | |

**User's choice:** All recommended options.

---

## Economy & day end

**Q: How tight should gold feel on day 1?**

| Option | Description | Selected |
|--------|-------------|----------|
| Tight: ~2 Houses or 1 tower | A real trade-off from the first minute; income fills the map over several days | ✓ |
| Comfortable: about half the map | 4–5 builds on day 1; easier to test, weaker early choices | |
| Very tight: 1 House | Slow snowball; punishing and drags a short prototype run | |

**Q: How many upgrade tiers should the House and the basic tower have in Phase 1?**

| Option | Description | Selected |
|--------|-------------|----------|
| House 3 tiers, tower 2 | Two House upgrades with rising income; one tower upgrade. Enough to test without inventing unusable tower stats | ✓ |
| Both 3 tiers | Symmetric, but tower tiers can't be felt until Phase 2 | |
| Both 2 tiers | Minimum proof of upgrading; little "upgrade vs build new" tension | |

**Q: How does the player end the day in Phase 1?**

| Option | Description | Selected |
|--------|-------------|----------|
| Final hold-to-confirm now | Build the real "start night" hold input now; Phase 2 just adds enemies behind it | ✓ |
| Simple key press for now | One tap ends the day; hold-to-confirm swapped in during Phase 2 | |

**Q: What should the placeholder night and the dawn payout look like?**

| Option | Description | Selected |
|--------|-------------|----------|
| Short dusk, then visible payout | A few seconds of night lighting with a "Night N — no enemies yet" banner; at dawn coins fly from each House to the gold counter, then a "+X gold" total | ✓ |
| Quick fade, number only | Fade to black and back; the gold counter jumps with a "+X" label | |

**User's choice:** All recommended options.

---

## Repo, CI & Godot setup

**Q: Should the GitHub repo be public or private?**

| Option | Description | Selected |
|--------|-------------|----------|
| Public | Portfolio project; full history visible; unlimited free Actions minutes; CC0 assets make it safe | ✓ |
| Private for now | Work in progress hidden until release; free monthly Actions minutes should suffice | |

**Q: How should the project get Godot 4.7.2?**

| Option | Description | Selected |
|--------|-------------|----------|
| A setup script fetches a pinned copy | Downloads the official 4.7.2, checks its checksum, stores it in a git-ignored project folder; local and CI use the same version; asks before the first download | ✓ |
| You install it yourself | Manual install plus a GODOT environment variable | |

**Q: Where should Windows builds come from in Phase 1?**

| Option | Description | Selected |
|--------|-------------|----------|
| CI builds it; local build is optional | CI makes a downloadable build every run; the local export script fetches templates on first use | |
| Local and CI from the start | The setup script downloads the export templates (~1 GB) up front so local .exe export works immediately | ✓ |

**Q: When should the repo start using Git LFS for binary assets?**

| Option | Description | Selected |
|--------|-------------|----------|
| Set up LFS from the first commit | Binary types go to LFS from day one; no history rewrite later | ✓ |
| Plain git until the art pass | Small Phase 1 models in normal git; LFS added in Phase 8 with a migration | |

**User's choice:** Public repo, pinned setup script, local + CI export from the start (the only non-recommended pick), LFS from the first commit.

---

## Claude's Discretion

- Camera angle, projection, framing and follow smoothing (fixed isometric-style, following the king)
- King walk/sprint speeds and turning feel
- Interaction radius, nearest-spot selection, moving while holding, coin drip rate, max-tier behavior
- Exact gold numbers, costs, income per tier, tower stats, animation timing
- Default key/button bindings (no conflict between the build hold and the start-night hold)
- Debug overlay layout and toggle key; screenshot scene list; attribution log format
- CC0 pack choice for the four models
- Project folder layout, GUT test organization, CI workflow structure, optional pre-commit lint hook
- Optional groundwork: fixed-step simulation tick and seeded RNG service for Phase 2 determinism

## Deferred Ideas

None. The discussion stayed within the phase scope.
