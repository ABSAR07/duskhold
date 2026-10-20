#pragma once

#include <cstdint>
#include <vector>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include "native_mirror.h"

namespace godot {

// The death-puff ring of DeathPuffBatch (presentation/vfx/death_puff_batch.gd) in C++ (PLAT-01,
// plan 04-26, G-04-5, review IN-08): the 128-slot scan per death and per frame runs here, and a
// refresh is one call. DeathPuffBatch stays the facade: it builds the mesh and the batch, hands
// the mirror over at setup and uploads what refresh wrote.
//
// EXACT PORT. Line by line the GDScript it replaces, under exact_port_rules 1 to 6, 10 and 12 of
// the plan: the birth times and the clock are doubles, the age is (now - born) / puff_seconds in
// double and narrowed once into the custom colour, a slot counts as standing for an age of at
// least 0.0 and below 1.0 in the counting scan and as skipped for an age below 0.0 or at least
// 1.0 in the drawing scan (a NaN age is drawn and not counted, as in GDScript), slots are visited
// from the cursor round the ring, and nothing is reassociated. The pins of
// tests/unit/test_enemy_fill_pins.gd hash the puff batch, so they prove the mirror and its count
// are the GDScript's. The ring size, the lifetime and the never-born birth time come in through
// configure.
//
// THE MIRROR. The class fills its own PackedFloat32Array copy of the batch's CPU mirror (set_mirror
// at setup), writing exactly the floats CrowdBatch.add wrote (the origin, the colour, the custom
// data); the floats past the count keep what earlier frames left. GDScript hands it back with
// CrowdBatch.commit_buffer(mirror(), refresh(now)).
//
// NO CLOCK. The clock comes in as an argument in seconds; nothing here reads it from the engine.
//
// BAD INPUT. An unconfigured ring does nothing and has no puffs standing; a refresh without a
// mirror draws nothing; a mirror that does not fit is refused (exact_port_rules 10). One thread
// only.
class NativePuffs : public RefCounted {
	GDCLASS(NativePuffs, RefCounted)

protected:
	static void _bind_methods();

public:
	// The most slots configure accepts.
	static constexpr int64_t MAX_CAPACITY = 65536;

	// Allocates the ring (every slot born `never_born_s`, cursor 0) and takes the lifetime in
	// seconds. A capacity outside 1..MAX_CAPACITY leaves the ring unconfigured.
	void configure(int64_t capacity, double puff_seconds, double never_born_s);
	// Takes the batch's mirror (CrowdBatch.mirror()) and its layout (CrowdBatch.layout()). False,
	// and nothing changes, for a layout that does not describe a mirror of this size.
	bool set_mirror(const PackedFloat32Array &mirror, const PackedInt64Array &layout);
	// Stores `now_s`, then starts a puff at `origin` in `color` in the slot at the cursor and moves
	// the cursor on, unless every slot already stands (the puff is then not drawn).
	void spawn(const Vector3 &origin, double now_s, const Color &color);
	// Stores `now_s`, then writes every puff standing at `now_s` into the mirror as the next
	// instance with its age in the custom data. Answers the instances written.
	int64_t refresh(double now_s);
	// Puffs standing as of the latest spawn or refresh.
	int64_t active_count() const;
	// The mirror as the latest refresh left it.
	PackedFloat32Array mirror() const;

private:
	// The ring, parallel arrays indexed by slot (the packed arrays of the GDScript).
	std::vector<Vector3> origins_;
	std::vector<double> born_;
	std::vector<Color> colors_;
	int64_t next_ = 0;
	double now_s_ = 0.0;
	double puff_seconds_ = 0.0;

	PackedFloat32Array mirror_;
	duskhold::MirrorLayout layout_;
	bool mirror_ready_ = false;
};

} // namespace godot
