extends GutTest
## DR-4: seeded streams. The first outputs of the engine generator are pinned so an engine change
## that alters the algorithm fails loudly, and stream seeds must not be a bare `seed + n`.


func test_the_engine_generator_gives_the_pinned_sequence_for_seed_12345() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	assert_eq(rng.randi(), 1321476956, "first output")
	assert_eq(rng.randi(), 17539747, "second output")
	assert_eq(rng.randi(), 3348728241, "third output")


func test_the_splitmix_mixer_is_pinned() -> void:
	assert_eq(SimRng.mix(1), -7995527694508729151, "mix(1)")
	assert_eq(SimRng.mix(2), -7541218347953203506, "mix(2)")


func test_every_part_of_a_stream_seed_changes_it() -> void:
	var seeds: Array[int] = [
		SimRng.stream_seed(1, 1, 1),
		SimRng.stream_seed(1, 2, 1),
		SimRng.stream_seed(1, 1, 2),
		SimRng.stream_seed(2, 1, 1),
	]
	for first: int in range(seeds.size()):
		for second: int in range(first + 1, seeds.size()):
			assert_ne(seeds[first], seeds[second], "seeds %d and %d differ" % [first, second])


func test_the_same_stream_gives_the_same_draws() -> void:
	var one: RandomNumberGenerator = SimRng.make(7, 3, SimRng.STREAM_SPAWN)
	var two: RandomNumberGenerator = SimRng.make(7, 3, SimRng.STREAM_SPAWN)
	for _i: int in range(5):
		assert_eq(one.randi(), two.randi(), "same seed, same draw")
