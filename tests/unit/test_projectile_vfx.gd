extends GutTest
## D-13 made visible: the pure helpers behind the cosmetic projectiles. A projectile flies for
## exactly the simulation's flight time and rises and falls on a parabola whose peak grows with the
## distance up to a ceiling.

const DISTANCE_M: float = 10.0
const FAR_M: float = 1000.0
const EPSILON: float = 0.0001


func test_a_projectile_flies_for_the_simulations_flight_time() -> void:
	assert_eq(ProjectileVfx.flight_seconds(30), SimClock.seconds(30), "30 ticks is one second")
	assert_almost_eq(ProjectileVfx.flight_seconds(30), 1.0, EPSILON, "a second")
	assert_eq(ProjectileVfx.flight_seconds(0), 0.0, "no flight, no time")


func test_the_arc_starts_and_ends_on_the_ground() -> void:
	assert_eq(ProjectileVfx.arc_height(0.0, DISTANCE_M), 0.0, "the launch is at height zero")
	assert_eq(ProjectileVfx.arc_height(1.0, DISTANCE_M), 0.0, "the landing is at height zero")


func test_the_arc_peaks_halfway_at_a_height_that_grows_with_distance() -> void:
	var peak: float = ProjectileVfx.arc_height(0.5, DISTANCE_M)
	assert_almost_eq(peak, DISTANCE_M * ProjectileVfx.ARC_PER_METRE, EPSILON, "peak per metre")
	assert_gt(peak, ProjectileVfx.arc_height(0.25, DISTANCE_M), "lower a quarter of the way")
	assert_almost_eq(
		ProjectileVfx.arc_height(0.25, DISTANCE_M),
		ProjectileVfx.arc_height(0.75, DISTANCE_M),
		EPSILON,
		"symmetric"
	)
	assert_gt(peak, ProjectileVfx.arc_height(0.5, DISTANCE_M * 0.5), "a longer shot arcs higher")


func test_the_arc_peak_has_a_ceiling_and_a_zero_distance_has_no_arc() -> void:
	assert_eq(
		ProjectileVfx.arc_height(0.5, FAR_M),
		ProjectileVfx.MAX_ARC_HEIGHT,
		"a very long shot is capped"
	)
	assert_eq(ProjectileVfx.arc_height(0.5, 0.0), 0.0, "a point-blank shot does not arc")


func test_progress_outside_zero_to_one_stays_on_the_ground() -> void:
	assert_eq(ProjectileVfx.arc_height(-0.5, DISTANCE_M), 0.0, "before the launch")
	assert_eq(ProjectileVfx.arc_height(1.5, DISTANCE_M), 0.0, "after the landing")


func test_the_projectile_cap_is_128() -> void:
	assert_eq(ProjectileVfx.MAX_PROJECTILES, 128, "T-02-10: a fixed ceiling on live projectiles")
