class_name SimRng
extends RefCounted
## Seeded random streams for the simulation (DR-4). Only explicitly seeded RandomNumberGenerator
## instances are used, one per (night, purpose). A stream seed mixes the run seed, the night number
## and a stream id with splitmix64, because the engine generator "can output similar random streams
## given similar seeds": a stream seed is never `seed + n`.

## Stream id for spawn scatter.
const STREAM_SPAWN: int = 1
## splitmix64 constants as signed int64 values (a hex literal of them does not parse).
const GOLDEN: int = -7046029254386353131
const MIX_1: int = -4658895280553007687
const MIX_2: int = -7723592293110705685
## Masks that turn the arithmetic right shift into a logical one (GDScript has no >>>).
const MASK_30: int = 0x3FFFFFFFF
const MASK_27: int = 0x1FFFFFFFFF
const MASK_31: int = 0x1FFFFFFFF


## splitmix64 finaliser. int wraps on overflow, which is what the algorithm needs.
static func mix(x: int) -> int:
	var z: int = x + GOLDEN
	z = (z ^ ((z >> 30) & MASK_30)) * MIX_1
	z = (z ^ ((z >> 27) & MASK_27)) * MIX_2
	return z ^ ((z >> 31) & MASK_31)


## The seed of one stream: the run seed, then the night, then the stream id, each folded in.
static func stream_seed(run_seed: int, night: int, stream: int) -> int:
	return mix(mix(mix(run_seed) + night) + stream)


## A new generator for one stream. The caller owns it; draw only at spawn time, in spawn order.
static func make(run_seed: int, night: int, stream: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = stream_seed(run_seed, night, stream)
	return rng
