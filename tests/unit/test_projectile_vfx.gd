extends GutTest
## D-13 made visible: the pure helpers behind the cosmetic projectiles. A projectile flies for
## exactly the simulation's flight time and rises and falls on a parabola whose peak grows with the
## distance up to a ceiling; an arrow's pose follows that path, turned along its direction of
## travel.

const DISTANCE_M: float = 10.0
const FAR_M: float = 1000.0
const EPSILON: float = 0.0001
const LEVEL_ORIGIN := Vector3(0.0, 1.2, 0.0)
const LEVEL_TARGET := Vector3(0.0, 1.2, 10.0)
const UP_TOLERANCE: float = 0.01


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


func test_the_projectile_cap_is_512() -> void:
	assert_eq(ProjectileVfx.MAX_PROJECTILES, 512, "T-04-03: a fixed ceiling on live arrows")


func test_an_arrow_starts_at_the_origin_and_lands_on_the_target() -> void:
	var start: Transform3D = ProjectileVfx.arrow_transform(LEVEL_ORIGIN, LEVEL_TARGET, 0.0)
	var landed: Transform3D = ProjectileVfx.arrow_transform(LEVEL_ORIGIN, LEVEL_TARGET, 1.0)
	assert_almost_eq(start.origin.distance_to(LEVEL_ORIGIN), 0.0, EPSILON, "at the origin at t 0")
	assert_almost_eq(landed.origin.distance_to(LEVEL_TARGET), 0.0, EPSILON, "on the target at t 1")
	var mid: Transform3D = ProjectileVfx.arrow_transform(LEVEL_ORIGIN, LEVEL_TARGET, 0.5)
	var peak: float = ProjectileVfx.arc_height(0.5, DISTANCE_M)
	assert_almost_eq(mid.origin.y, LEVEL_ORIGIN.y + peak, EPSILON, "and over the arc halfway")


func test_the_arrow_basis_is_orthonormal_along_the_flight_direction() -> void:
	for step: int in range(0, 11):
		var t: float = float(step) / 10.0
		var basis: Basis = ProjectileVfx.arrow_transform(LEVEL_ORIGIN, LEVEL_TARGET, t).basis
		assert_almost_eq(basis.x.length(), 1.0, EPSILON, "x is a unit vector at t %.1f" % t)
		assert_almost_eq(basis.y.length(), 1.0, EPSILON, "y is a unit vector at t %.1f" % t)
		assert_almost_eq(basis.z.length(), 1.0, EPSILON, "z is a unit vector at t %.1f" % t)
		assert_almost_eq(basis.x.dot(basis.y), 0.0, EPSILON, "x and y are square at t %.1f" % t)
		assert_almost_eq(basis.y.dot(basis.z), 0.0, EPSILON, "y and z are square at t %.1f" % t)
		assert_almost_eq(basis.x.dot(basis.z), 0.0, EPSILON, "x and z are square at t %.1f" % t)


func test_the_arrow_points_along_its_path_including_the_arc() -> void:
	var rising: Basis = ProjectileVfx.arrow_transform(LEVEL_ORIGIN, LEVEL_TARGET, 0.2).basis
	assert_gt(rising.z.y, 0.0, "it climbs on the way up")
	assert_gt(rising.z.z, 0.9, "and mostly points at the target")
	var level: Basis = ProjectileVfx.arrow_transform(LEVEL_ORIGIN, LEVEL_TARGET, 0.5).basis
	assert_almost_eq(level.z.y, 0.0, UP_TOLERANCE, "it is level at the top of the arc")
	assert_almost_eq(level.z.z, 1.0, UP_TOLERANCE, "pointing straight at the target")
	assert_almost_eq(level.y.y, 1.0, UP_TOLERANCE, "with its y axis upward for a level shot")
	var falling: Basis = ProjectileVfx.arrow_transform(LEVEL_ORIGIN, LEVEL_TARGET, 0.8).basis
	assert_lt(falling.z.y, 0.0, "it dives on the way down")


func test_a_vertical_or_zero_length_shot_still_has_a_valid_basis() -> void:
	var up: Transform3D = ProjectileVfx.arrow_transform(Vector3.ZERO, Vector3(0.0, 5.0, 0.0), 0.5)
	assert_true(up.basis.z.is_finite() and up.basis.x.is_finite(), "a straight-up shot is finite")
	assert_almost_eq(up.basis.x.length(), 1.0, EPSILON, "x stays a unit vector")
	var still: Transform3D = ProjectileVfx.arrow_transform(LEVEL_ORIGIN, LEVEL_ORIGIN, 0.5)
	assert_eq(still.basis, Basis.IDENTITY, "no distance, no turn")
	assert_eq(still.origin, LEVEL_ORIGIN, "and it stays where it is")
