#pragma once

#include <cstdint>
#include <vector>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include "native_mirror.h"

namespace godot {

// The arrow ring and the per-frame flight of ProjectileVfx (presentation/vfx/projectile_vfx.gd) in
// C++ (PLAT-01, plan 04-25, G-04-5): what the GDScript did every frame for each of the 512 ring
// slots (advance the clock, re-read the target, work out the arrow's pose, write the instance) is
// one call, fill. ProjectileVfx stays the facade: it decides what to draw (the attack_fired
// events, the slash, the colours, the launch points, unit and building targets) and hands the
// results here; the hit itself was decided by the simulation by id and nothing here writes it.
//
// EXACT PORT. Line by line the GDScript it replaces, under exact_port_rules 1 to 6, 10 and 12 of
// the plan: Vector3 values are real_t, every GDScript float a double, a scalar meets a vector only
// through a cast to real_t at the operator, slots are visited in ascending order, nothing is
// reassociated, and the vector maths is native/src/gd_math.h's (proven bit-equal to the engine by
// tests/unit/test_native_view_math_contract.gd). Every constant of the GDScript (the ring size, the
// arc numbers, the heading step, the target height) comes in through configure; C++ holds no copy.
// The pins of tests/unit/test_projectile_fill_pins.gd, computed on the GDScript flight before this
// file existed, are the proof that the batch mirror, its count and the launch points are the same.
//
// THE MIRROR. The class fills its own PackedFloat32Array copy of the batch's CPU mirror (set_mirror
// at bind), writing exactly the floats CrowdBatch.add_transform wrote; the floats past the count
// keep what earlier frames left, so the whole mirror, stale tail included, is the GDScript's.
// GDScript hands it back with CrowdBatch.commit_buffer(mirror(), count()).
//
// BAD INPUT. Every slot, size and code that crosses from GDScript is checked: an unconfigured ring
// or a missing mirror draws nothing, enemy arrays of different sizes find no enemy, an unknown
// target code behaves as a fixed target, and a slot outside the ring (or not in flight) answers -1
// or the zero vector and changes nothing (exact_port_rules 10). One thread only.
class NativeArrows : public RefCounted {
	GDCLASS(NativeArrows, RefCounted)

protected:
	static void _bind_methods();

public:
	// The target codes ProjectileVfx passes to launch: where the arrow's target comes from each
	// frame. FIXED keeps the launch target (a building, castle or wall target resolves to the same
	// point every frame); ENEMY follows the enemy read view by id and keeps the last target once the
	// enemy is gone or dead; UNIT is resolved by GDScript before each fill (set_target); KING
	// follows the king.
	enum {
		TARGET_FIXED = 0,
		TARGET_ENEMY = 1,
		TARGET_UNIT = 2,
		TARGET_KING = 3,
	};
	// The most slots configure accepts.
	static constexpr int64_t MAX_CAPACITY = 65536;

	// Allocates the ring (every slot free, cursor 0) and takes the GDScript constants. A capacity
	// outside 1..MAX_CAPACITY leaves the ring unconfigured.
	void configure(
			int64_t capacity,
			double arc_per_metre,
			double max_arc_height,
			double heading_step,
			double unit_height);
	// Takes the batch's mirror (CrowdBatch.mirror()) and its layout (CrowdBatch.layout()). False,
	// and nothing changes, for a layout that does not describe a mirror of this size.
	bool set_mirror(const PackedFloat32Array &mirror, const PackedInt64Array &layout);
	// Starts a flight in the next free slot at or after the cursor and moves the cursor past it:
	// -1 when no slot is free or the ring is not configured. The duration is stored as a float32
	// and the target id as an int32, as the packed arrays of the GDScript ring stored them.
	int64_t launch(
			const Vector3 &origin,
			const Vector3 &target,
			double duration,
			int64_t target_code,
			int64_t target_id,
			const Color &color);
	// One frame: every flight in ascending slot order advances by `delta`, re-reads its target
	// (ENEMY from the ascending `enemy_ids` with the matching positions and living flags, KING from
	// `king_ground`), works out its pose and is written into the mirror as the next instance; a
	// flight whose progress reached 1 is freed after it is written. Answers the instances written.
	int64_t fill(
			double delta,
			const Vector2 &king_ground,
			const PackedInt64Array &enemy_ids,
			const PackedVector2Array &enemy_current,
			const PackedByteArray &enemy_living);

	// The mirror as the latest fill left it, and how many instances it holds.
	PackedFloat32Array mirror() const;
	int64_t count() const;
	// Flights in the air.
	int64_t live_count() const;
	// Flights in the air whose target code is TARGET_UNIT: GDScript resolves those before each
	// fill and skips the scan while there are none.
	int64_t unit_flights() const;
	// The launch point of the arrow written as instance `index` by the latest fill; the zero
	// vector outside 0..count - 1.
	Vector3 drawn_launch(int64_t index) const;
	// The slots in flight whose target code is `target_code`, ascending.
	PackedInt32Array slots_targeting(int64_t target_code) const;
	// The target id and the current target of a slot in flight; -1 and the zero vector for any
	// other slot.
	int64_t target_id_at(int64_t slot) const;
	Vector3 target_at(int64_t slot) const;
	// Replaces the current target of a slot in flight; any other slot is left alone.
	void set_target(int64_t slot, const Vector3 &target);

	// ProjectileVfx.arc_height: the height above the straight line at progress `t` of a shot over
	// `distance` metres, the peak distance * arc_per_metre never above max_arc_height.
	static double arc_height(double t, double distance, double arc_per_metre, double max_arc_height);
	// ProjectileVfx.arrow_transform: where an arrow flying from `origin` to `target` is at progress
	// `t` (clamped to 0..1), turned along its path; the identity basis when origin and target
	// coincide.
	static Transform3D arrow_transform(
			const Vector3 &origin,
			const Vector3 &target,
			double t,
			double arc_per_metre,
			double max_arc_height,
			double heading_step);

private:
	// The pose of an arrow as its three basis columns and its position.
	struct Pose {
		Vector3 x_axis;
		Vector3 y_axis;
		Vector3 z_axis;
		Vector3 position;
	};
	static Pose pose_of(
			const Vector3 &origin,
			const Vector3 &target,
			double t,
			double arc_per_metre,
			double max_arc_height,
			double heading_step);
	static Vector3 path_point(
			const Vector3 &origin,
			const Vector3 &target,
			double t,
			double distance,
			double arc_per_metre,
			double max_arc_height);
	bool in_flight(int64_t slot) const;

	// The ring, parallel arrays indexed by slot (the packed arrays of the GDScript).
	std::vector<Vector3> origins_;
	std::vector<Vector3> targets_;
	std::vector<float> elapsed_;
	std::vector<float> durations_;
	std::vector<int32_t> target_ids_;
	std::vector<int32_t> target_codes_;
	std::vector<Color> colors_;
	std::vector<uint8_t> active_;
	// The launch point of each instance the latest fill wrote, in instance order.
	std::vector<Vector3> drawn_launches_;
	int64_t cursor_ = 0;
	int64_t live_ = 0;
	int64_t unit_live_ = 0;
	int64_t count_ = 0;

	double arc_per_metre_ = 0.0;
	double max_arc_height_ = 0.0;
	double heading_step_ = 0.0;
	double unit_height_ = 0.0;

	PackedFloat32Array mirror_;
	duskhold::MirrorLayout layout_;
	bool mirror_ready_ = false;
};

} // namespace godot
