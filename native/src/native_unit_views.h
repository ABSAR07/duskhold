#pragma once

#include <cstdint>
#include <vector>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include "native_mirror.h"

namespace godot {

// The per-unit fill of UnitViews (presentation/units/unit_views.gd) in C++ (PLAT-01, plan 04-27,
// G-04-5, review IN-07): what the GDScript did every frame for each drawn friendly unit (the
// interpolated ground point, the instance write into its type's batch, the hurt-only bar) is one
// call, fill. UnitViews stays the facade: it owns the nodes, the baked models, the batches and the
// event handlers, and feeds this class what it needs (max hit points, hits, deaths) and the packed
// army read view (UnitSystem.read_view()); the simulation is only read.
//
// EXACT PORT. Line by line the GDScript it replaces, under exact_port_rules 1 to 6, 10 and 12 of
// the plan: a GDScript float is a double here (the blend, the bar height, the bar ratio), a
// Vector2 or Vector3 component or a Color component is a float narrowed exactly where GDScript
// narrows it, the lerp is native/src/gd_math.h's (proven bit-equal to the engine), units are
// visited in the read view's order (ascending id), and no expression is reassociated. The pins of
// tests/unit/test_unit_fill_pins.gd, computed on the GDScript fill before this file existed, are
// the proof that the mirrors and every count are the same. The one rule copied from GDScript is
// HealthBar3D.should_show (presentation/vfx/health_bar_3d.gd): max_hp > 0 and hp > 0 and
// hp < max_hp; every constant (the draw cap and the bar height, PUPPET_HEIGHT + BAR_CLEARANCE as
// GDScript adds them) comes in through configure.
//
// THE MIRRORS. The class fills its own PackedFloat32Array copy of each batch's CPU mirror
// (set_mirror at the moment the type's batch exists, set_bar_mirror at bind), writing exactly the
// floats CrowdBatch.add wrote; the floats past a count keep what earlier frames left, so each
// whole mirror, stale tail included, is the GDScript's. GDScript hands each back with
// CrowdBatch.commit_buffer(mirror(i), count(i)) after the fill call.
//
// BAD INPUT. Every id, size and index that crosses from GDScript is checked: arrays of different
// sizes or an unset bar mirror draw nothing, a hit for a unit with no maximum is ignored, a def
// slot with no batch (out of range, -1 or a batch whose mesh is not ready) skips its unit like a
// type that is not ready, an unknown batch answers an empty mirror and a count of 0, and a unit
// that is not drawn answers the zero vector, -1 or 0 (exact_port_rules 10). One thread only.
class NativeUnitViews : public RefCounted {
	GDCLASS(NativeUnitViews, RefCounted)

protected:
	static void _bind_methods();

public:
	// The most unit types configure accepts, and the most units it will draw.
	static constexpr int64_t MAX_TYPES_LIMIT = 1024;
	static constexpr int64_t MAX_VIEWS_LIMIT = 65536;

	// Takes the draw cap (UnitViews.MAX_VIEWS), the bar height above the ground (PUPPET_HEIGHT +
	// BAR_CLEARANCE) and the number of unit-type batches. A cap outside 1..MAX_VIEWS_LIMIT or a
	// type count outside 0..MAX_TYPES_LIMIT leaves the fill unconfigured (it draws nothing). The
	// type mirrors are forgotten (set_mirror again); the known units are kept.
	void configure(int64_t max_views, double bar_height, int64_t type_count);
	// Takes the mirror (CrowdBatch.mirror()) and layout (CrowdBatch.layout()) of type batch
	// `batch`. False, and nothing changes, for a batch outside 0..type_count or a layout that does
	// not describe a mirror of this size.
	bool set_mirror(int64_t batch, const PackedFloat32Array &mirror, const PackedInt64Array &layout);
	// The same for the bar batch.
	bool set_bar_mirror(const PackedFloat32Array &mirror, const PackedInt64Array &layout);

	// unit_spawned (and the bind seeding): remembers unit `id` with `max_hp`; a known id keeps its
	// hit points and takes the new maximum (the dictionary was overwritten).
	void set_max_hp(int64_t id, int64_t max_hp);
	// unit_damaged: remembers the hit points of a unit that has a maximum; an unknown id is
	// ignored.
	void set_hp(int64_t id, int64_t hp);
	// squad_restored: the unit is whole again, its hit points are forgotten, its maximum kept.
	void forget_hp(int64_t id);
	// unit_died: drops everything about unit `id`.
	void forget(int64_t id);
	// Units remembered.
	int64_t known_count() const;

	// One frame: every unit of the read view (`ids`, `previous`, `current`, `def_slots`, same
	// size) in the view's order, at the blend of its previous and current ground point, is
	// written into the batch `batch_of_def[def_slots[slot]]` and, when it is hurt, into the bars.
	// Answers the units drawn.
	int64_t fill(
			double blend,
			const PackedInt64Array &ids,
			const PackedVector2Array &previous,
			const PackedVector2Array &current,
			const PackedInt32Array &def_slots,
			const PackedInt32Array &batch_of_def);

	// Type batch `batch`'s mirror as the latest fill left it and how many instances it holds;
	// empty and 0 for an unknown batch.
	PackedFloat32Array mirror(int64_t batch) const;
	int64_t count(int64_t batch) const;
	// The bar batch's mirror and count.
	PackedFloat32Array bar_mirror() const;
	int64_t bar_count() const;
	// Units drawn by the latest fill.
	int64_t drawn_count() const;
	// True when unit `id` was drawn by the latest fill.
	bool has_view(int64_t id) const;
	// The ground point (y = 0) where unit `id` was drawn by the latest fill; the zero vector when
	// it was not.
	Vector3 puppet_position(int64_t id) const;
	// The hit points as of the last hit (-1 for a unit never hit, restored or unknown) and the
	// maximum (0 for an unknown unit).
	int64_t hp_of(int64_t id) const;
	int64_t max_hp_of(int64_t id) const;

private:
	// One remembered unit: the two dictionaries of the GDScript in one record.
	struct Record {
		int64_t id = 0;
		int64_t max_hp = 0;
		bool has_hp = false;
		int64_t hp = 0;
	};

	// The remembered units, ascending by id.
	std::vector<Record> records_;
	Record *find(int64_t id);
	const Record *find(int64_t id) const;
	// Slot of unit `id` among the drawn ids, or -1 (UnitViews._find).
	int64_t drawn_slot(int64_t id) const;
	bool ready() const;

	int64_t max_views_ = 0;
	double bar_height_ = 0.0;
	int64_t type_count_ = 0;
	bool configured_ = false;

	std::vector<PackedFloat32Array> mirrors_;
	std::vector<duskhold::MirrorLayout> layouts_;
	std::vector<uint8_t> mirror_ready_;
	std::vector<int64_t> counts_;
	// The mirror pointers a frame took for writing; null until a batch's first instance.
	std::vector<float *> buffers_;
	PackedFloat32Array bar_mirror_;
	duskhold::MirrorLayout bar_layout_;
	bool bar_ready_ = false;
	int64_t bar_count_ = 0;

	// The latest fill: the units drawn ascending as the GDScript's int32 array held them and the
	// ground point of each.
	int64_t drawn_ = 0;
	std::vector<int32_t> drawn_ids_;
	std::vector<Vector3> drawn_origins_;
};

} // namespace godot
