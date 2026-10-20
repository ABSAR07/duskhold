#pragma once

#include <cstdint>
#include <vector>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include "native_mirror.h"

namespace godot {

// The per-enemy fill of EnemyViews (presentation/enemies/enemy_views.gd) in C++ (PLAT-01, plan
// 04-26, G-04-5, review IN-07): what the GDScript did every frame for each drawn enemy (the
// interpolated ground point, the hit flash, the instance write into its archetype's batch, the
// hurt-only bar) is one call, fill. EnemyViews stays the facade: it owns the nodes, the batches
// and the event handlers, and feeds this class what it needs (spawn, damage, death) and the packed
// enemy read view; the simulation is only read.
//
// EXACT PORT. Line by line the GDScript it replaces, under exact_port_rules 1 to 6, 10 and 12 of
// the plan: a GDScript float is a double here (the flash, the bar ratio, the bar height and the
// flash window), a Vector2 or Vector3 component or a Color component is a float narrowed exactly
// where GDScript narrows it, the lerp is native/src/gd_math.h's (proven bit-equal to the engine),
// enemies are visited in the read view's order, and no expression is reassociated. The pins of
// tests/unit/test_enemy_fill_pins.gd, computed on the GDScript fill before this file existed,
// are the proof that the four mirrors and every count are the same. The one rule copied from
// GDScript is HealthBar3D.should_show (presentation/vfx/health_bar_3d.gd): max_hp > 0 and hp > 0
// and hp < max_hp; every constant (the draw cap, the lifts, the bar clearance and the flash
// window) comes in through configure.
//
// THE MIRRORS. The class fills its own PackedFloat32Array copy of each batch's CPU mirror
// (set_mirror at bind: batches 0 to 2 the archetypes, 3 the bars), writing exactly the floats
// CrowdBatch.add wrote; the floats past a count keep what earlier frames left, so each whole
// mirror, stale tail included, is the GDScript's. GDScript hands each back with
// CrowdBatch.commit_buffer(mirror(i), count(i)).
//
// NO CLOCK. The frame milliseconds and every hit time come in as arguments; nothing here reads
// the engine's clock, a random number or a singleton.
//
// BAD INPUT. Every id, size and index that crosses from GDScript is checked: arrays of different
// sizes or an unset mirror draw nothing, a damage event for an enemy never spawned is ignored,
// an unknown batch answers an empty mirror and a count of 0, and an enemy that is not drawn
// answers the zero vector, 0.0, -1 or 0 (exact_port_rules 10). One thread only.
class NativeEnemyViews : public RefCounted {
	GDCLASS(NativeEnemyViews, RefCounted)

protected:
	static void _bind_methods();

public:
	// The batches set_mirror takes: the three archetypes of EnemyViews, then the bars.
	enum {
		BATCH_BARS = 3,
		BATCH_TOTAL = 4,
	};
	// The most enemies configure accepts.
	static constexpr int64_t MAX_VIEWS_LIMIT = 65536;

	// Takes the draw cap (EnemyViews.MAX_VIEWS), the height of the body centre per archetype
	// (EnemyViews._lifts, one per archetype batch), the bar clearance and the flash window in
	// seconds. A cap outside 1..MAX_VIEWS_LIMIT or no lift leaves the fill unconfigured (it draws
	// nothing). Known enemies are kept.
	void configure(
			int64_t max_views,
			const PackedFloat32Array &lifts,
			double bar_clearance,
			double flash_seconds);
	// Takes the mirror (CrowdBatch.mirror()) and layout (CrowdBatch.layout()) of batch `batch`.
	// False, and nothing changes, for an unknown batch or a layout that does not describe a mirror
	// of this size.
	bool set_mirror(int64_t batch, const PackedFloat32Array &mirror, const PackedInt64Array &layout);

	// enemy_spawned: remembers enemy `id` as archetype `kind` with `max_hp`; a known id keeps its
	// hit and hit points and takes the new kind and maximum (the dictionaries were overwritten).
	void on_spawned(int64_t id, int64_t kind, int64_t max_hp);
	// enemy_damaged: for a known enemy, remembers its hit points and the millisecond of the hit
	// (the flash starts from it); an unknown id is ignored.
	void on_damaged(int64_t id, int64_t hp, int64_t hit_ms);
	// enemy_died: drops everything about enemy `id`.
	void forget(int64_t id);
	// Drops everything about every enemy.
	void clear();
	// Enemies remembered.
	int64_t known_count() const;

	// One frame: every enemy of the read view (`ids`, `previous`, `current`, same size) in the
	// view's order, at the blend of its previous and current ground point, is written into its
	// archetype's mirror with its flash, and a hurt one also into the bars. `frame_ms` is the
	// frame's millisecond sample and `blend` the interpolation weight. Answers the enemies drawn.
	int64_t fill(
			int64_t frame_ms,
			double blend,
			const PackedInt64Array &ids,
			const PackedVector2Array &previous,
			const PackedVector2Array &current);

	// Batch `batch`'s mirror as the latest fill left it and how many instances it holds; empty
	// and 0 for an unknown batch.
	PackedFloat32Array mirror(int64_t batch) const;
	int64_t count(int64_t batch) const;
	// Enemies drawn by the latest fill.
	int64_t drawn_count() const;
	// True when enemy `id` was drawn by the latest fill.
	bool has_view(int64_t id) const;
	// The ground point (y = 0) where enemy `id` was drawn by the latest fill; the zero vector when
	// it was not.
	Vector3 puppet_position(int64_t id) const;
	// The flash of a drawn enemy at the latest fill's milliseconds: 1.0 at its hit, falling
	// linearly to 0.0 over the flash window; 0.0 when it was not hit lately or is not drawn. An
	// expired hit is forgotten, as in the fill.
	double flash_of(int64_t id);
	// The hit points as of the last hit (-1 for an enemy never hit or unknown) and the maximum
	// (0 for an unknown enemy).
	int64_t hp_of(int64_t id) const;
	int64_t max_hp_of(int64_t id) const;

private:
	// One remembered enemy: the four dictionaries of the GDScript in one record.
	struct Record {
		int64_t id = 0;
		int64_t kind = 0;
		int64_t max_hp = 0;
		bool has_hp = false;
		int64_t hp = 0;
		// The millisecond of the last hit; below 0 for none.
		int64_t hit_ms = -1;
	};

	// The remembered enemies, ascending by id.
	std::vector<Record> records_;
	Record *find(int64_t id);
	const Record *find(int64_t id) const;
	// EnemyViews._flash_amount: 0.0 without a hit; else 1.0 minus the seconds since the hit over
	// the window, an expired hit being forgotten.
	double flash_amount(Record &record) const;
	// Slot of enemy `id` among the drawn ids, or -1 (EnemyViews._find).
	int64_t drawn_slot(int64_t id) const;
	bool ready() const;

	int64_t max_views_ = 0;
	std::vector<float> lifts_;
	double bar_clearance_ = 0.0;
	double flash_seconds_ = 0.0;
	bool configured_ = false;

	PackedFloat32Array mirrors_[BATCH_TOTAL];
	duskhold::MirrorLayout layouts_[BATCH_TOTAL];
	bool mirror_ready_[BATCH_TOTAL] = { false, false, false, false };
	int64_t counts_[BATCH_TOTAL] = { 0, 0, 0, 0 };

	// The latest fill: the frame's milliseconds, the enemies drawn ascending as the GDScript's
	// int32 array held them and the ground point of each.
	int64_t frame_ms_ = 0;
	int64_t drawn_ = 0;
	std::vector<int32_t> drawn_ids_;
	std::vector<Vector3> drawn_origins_;
};

} // namespace godot
