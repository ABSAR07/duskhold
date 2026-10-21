#include "native_unit_views.h"

#include <algorithm>
#include <cstdint>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include "gd_math.h"

using namespace godot;

namespace {

// presentation/vfx/health_bar_3d.gd HealthBar3D.should_show: hurt and still alive. The one rule
// copied from GDScript (exact_port_rules 12).
bool bar_shows(int64_t hp, int64_t max_hp) {
	return max_hp > 0 && hp > 0 && hp < max_hp;
}

} // namespace

void NativeUnitViews::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("configure", "max_views", "bar_height", "type_count"), &NativeUnitViews::configure);
	ClassDB::bind_method(D_METHOD("set_mirror", "batch", "mirror", "layout"), &NativeUnitViews::set_mirror);
	ClassDB::bind_method(D_METHOD("set_bar_mirror", "mirror", "layout"), &NativeUnitViews::set_bar_mirror);
	ClassDB::bind_method(D_METHOD("set_max_hp", "id", "max_hp"), &NativeUnitViews::set_max_hp);
	ClassDB::bind_method(D_METHOD("set_hp", "id", "hp"), &NativeUnitViews::set_hp);
	ClassDB::bind_method(D_METHOD("forget_hp", "id"), &NativeUnitViews::forget_hp);
	ClassDB::bind_method(D_METHOD("forget", "id"), &NativeUnitViews::forget);
	ClassDB::bind_method(D_METHOD("known_count"), &NativeUnitViews::known_count);
	ClassDB::bind_method(
			D_METHOD("fill", "blend", "ids", "previous", "current", "def_slots", "batch_of_def"),
			&NativeUnitViews::fill);
	ClassDB::bind_method(D_METHOD("mirror", "batch"), &NativeUnitViews::mirror);
	ClassDB::bind_method(D_METHOD("count", "batch"), &NativeUnitViews::count);
	ClassDB::bind_method(D_METHOD("bar_mirror"), &NativeUnitViews::bar_mirror);
	ClassDB::bind_method(D_METHOD("bar_count"), &NativeUnitViews::bar_count);
	ClassDB::bind_method(D_METHOD("drawn_count"), &NativeUnitViews::drawn_count);
	ClassDB::bind_method(D_METHOD("has_view", "id"), &NativeUnitViews::has_view);
	ClassDB::bind_method(D_METHOD("puppet_position", "id"), &NativeUnitViews::puppet_position);
	ClassDB::bind_method(D_METHOD("hp_of", "id"), &NativeUnitViews::hp_of);
	ClassDB::bind_method(D_METHOD("max_hp_of", "id"), &NativeUnitViews::max_hp_of);
}

void NativeUnitViews::configure(int64_t max_views, double bar_height, int64_t type_count) {
	bar_height_ = bar_height;
	drawn_ = 0;
	drawn_ids_.clear();
	drawn_origins_.clear();
	mirrors_.clear();
	layouts_.clear();
	mirror_ready_.clear();
	counts_.clear();
	bar_count_ = 0;
	max_views_ = 0;
	type_count_ = 0;
	configured_ = false;
	if (max_views < 1 || max_views > MAX_VIEWS_LIMIT || type_count < 0 || type_count > MAX_TYPES_LIMIT) {
		return;
	}
	max_views_ = max_views;
	type_count_ = type_count;
	const size_t types = static_cast<size_t>(type_count);
	mirrors_.assign(types, PackedFloat32Array());
	layouts_.assign(types, duskhold::MirrorLayout());
	mirror_ready_.assign(types, 0);
	counts_.assign(types, 0);
	drawn_ids_.assign(static_cast<size_t>(max_views), 0);
	drawn_origins_.assign(static_cast<size_t>(max_views), Vector3(0.0f, 0.0f, 0.0f));
	configured_ = true;
}

bool NativeUnitViews::set_mirror(
		int64_t batch, const PackedFloat32Array &mirror, const PackedInt64Array &layout) {
	if (!configured_ || batch < 0 || batch >= type_count_) {
		return false;
	}
	duskhold::MirrorLayout parsed;
	if (!duskhold::layout_from(layout, mirror.size(), parsed)) {
		return false;
	}
	const size_t at = static_cast<size_t>(batch);
	mirrors_[at] = mirror;
	layouts_[at] = parsed;
	mirror_ready_[at] = 1;
	counts_[at] = 0;
	return true;
}

bool NativeUnitViews::set_bar_mirror(const PackedFloat32Array &mirror, const PackedInt64Array &layout) {
	duskhold::MirrorLayout parsed;
	if (!duskhold::layout_from(layout, mirror.size(), parsed)) {
		return false;
	}
	bar_mirror_ = mirror;
	bar_layout_ = parsed;
	bar_ready_ = true;
	bar_count_ = 0;
	return true;
}

NativeUnitViews::Record *NativeUnitViews::find(int64_t id) {
	const auto at = std::lower_bound(
			records_.begin(), records_.end(), id, [](const Record &record, int64_t wanted) {
				return record.id < wanted;
			});
	if (at == records_.end() || at->id != id) {
		return nullptr;
	}
	return &*at;
}

const NativeUnitViews::Record *NativeUnitViews::find(int64_t id) const {
	const auto at = std::lower_bound(
			records_.begin(), records_.end(), id, [](const Record &record, int64_t wanted) {
				return record.id < wanted;
			});
	if (at == records_.end() || at->id != id) {
		return nullptr;
	}
	return &*at;
}

void NativeUnitViews::set_max_hp(int64_t id, int64_t max_hp) {
	const auto at = std::lower_bound(
			records_.begin(), records_.end(), id, [](const Record &record, int64_t wanted) {
				return record.id < wanted;
			});
	if (at != records_.end() && at->id == id) {
		at->max_hp = max_hp;
		return;
	}
	Record fresh;
	fresh.id = id;
	fresh.max_hp = max_hp;
	records_.insert(at, fresh);
}

void NativeUnitViews::set_hp(int64_t id, int64_t hp) {
	Record *record = find(id);
	if (record == nullptr) {
		return;
	}
	record->has_hp = true;
	record->hp = hp;
}

void NativeUnitViews::forget_hp(int64_t id) {
	Record *record = find(id);
	if (record == nullptr) {
		return;
	}
	record->has_hp = false;
	record->hp = 0;
}

void NativeUnitViews::forget(int64_t id) {
	const auto at = std::lower_bound(
			records_.begin(), records_.end(), id, [](const Record &record, int64_t wanted) {
				return record.id < wanted;
			});
	if (at != records_.end() && at->id == id) {
		records_.erase(at);
	}
}

int64_t NativeUnitViews::known_count() const {
	return static_cast<int64_t>(records_.size());
}

bool NativeUnitViews::ready() const {
	return configured_ && bar_ready_;
}

int64_t NativeUnitViews::fill(
		double blend,
		const PackedInt64Array &ids,
		const PackedVector2Array &previous,
		const PackedVector2Array &current,
		const PackedInt32Array &def_slots,
		const PackedInt32Array &batch_of_def) {
	// CrowdBatch.begin() for every batch: no instance is held until one is written.
	for (size_t batch = 0; batch < counts_.size(); batch++) {
		counts_[batch] = 0;
	}
	bar_count_ = 0;
	drawn_ = 0;
	const int64_t total = ids.size();
	if (!ready() || previous.size() != total || current.size() != total || def_slots.size() != total) {
		return 0;
	}
	const real_t weight = static_cast<real_t>(blend);
	const int64_t *id_at = ids.ptr();
	const Vector2 *previous_at = previous.ptr();
	const Vector2 *current_at = current.ptr();
	const int32_t *slot_at = def_slots.ptr();
	const int32_t *batch_at = batch_of_def.ptr();
	const int64_t defs = batch_of_def.size();
	// A mirror is taken for writing only when its first instance is written, so a frame that draws
	// nothing into a batch never copies the mirror that batch still shares (review IN-08).
	// The mirror pointers of this frame only, null until a batch's first instance: they are
	// locals because a later set_mirror or configure replaces the arrays they point into.
	std::vector<float *> buffers(counts_.size(), nullptr);
	float *bar_buffer = nullptr;
	const Color no_tint = Color(1.0f, 1.0f, 1.0f, 1.0f);
	const Color no_custom = Color(0.0f, 0.0f, 0.0f, 0.0f);

	for (int64_t slot = 0; slot < total; slot++) {
		if (drawn_ >= max_views_) {
			break;
		}
		const int64_t def_slot = static_cast<int64_t>(slot_at[slot]);
		if (def_slot < 0 || def_slot >= defs) {
			continue;
		}
		const int64_t batch = static_cast<int64_t>(batch_at[def_slot]);
		if (batch < 0 || batch >= type_count_ || mirror_ready_[static_cast<size_t>(batch)] == 0) {
			continue;
		}
		const Vector2 ground = gd::lerp(previous_at[slot], current_at[slot], weight);
		const Vector3 origin = Vector3(ground.x, 0.0f, ground.y);
		const size_t type = static_cast<size_t>(batch);
		if (counts_[type] >= layouts_[type].capacity) {
			continue;
		}
		if (buffers[type] == nullptr) {
			buffers[type] = mirrors_[type].ptrw();
		}
		duskhold::write_origin(buffers[type], layouts_[type], counts_[type], origin, no_custom, no_tint);
		counts_[type]++;
		const int64_t unit_id = id_at[slot];
		drawn_ids_[static_cast<size_t>(drawn_)] = static_cast<int32_t>(unit_id);
		drawn_origins_[static_cast<size_t>(drawn_)] = origin;
		drawn_++;
		const Record *record = find(unit_id);
		if (record != nullptr && record->has_hp && bar_shows(record->hp, record->max_hp) &&
				bar_count_ < bar_layout_.capacity) {
			const Vector3 bar_origin = origin + Vector3(0.0f, 1.0f, 0.0f) * static_cast<real_t>(bar_height_);
			const Color ratio = Color(
					static_cast<float>(static_cast<double>(record->hp) / static_cast<double>(record->max_hp)),
					0.0f,
					0.0f,
					0.0f);
			if (bar_buffer == nullptr) {
				bar_buffer = bar_mirror_.ptrw();
			}
			duskhold::write_origin(bar_buffer, bar_layout_, bar_count_, bar_origin, ratio, no_tint);
			bar_count_++;
		}
	}
	return drawn_;
}

PackedFloat32Array NativeUnitViews::mirror(int64_t batch) const {
	if (batch < 0 || batch >= type_count_) {
		return PackedFloat32Array();
	}
	return mirrors_[static_cast<size_t>(batch)];
}

int64_t NativeUnitViews::count(int64_t batch) const {
	if (batch < 0 || batch >= type_count_) {
		return 0;
	}
	return counts_[static_cast<size_t>(batch)];
}

PackedFloat32Array NativeUnitViews::bar_mirror() const {
	return bar_mirror_;
}

int64_t NativeUnitViews::bar_count() const {
	return bar_count_;
}

int64_t NativeUnitViews::drawn_count() const {
	return drawn_;
}

int64_t NativeUnitViews::drawn_slot(int64_t id) const {
	int64_t low = 0;
	int64_t high = drawn_ - 1;
	while (low <= high) {
		const int64_t middle = (low + high) >> 1;
		const int64_t found = static_cast<int64_t>(drawn_ids_[static_cast<size_t>(middle)]);
		if (found == id) {
			return middle;
		}
		if (found < id) {
			low = middle + 1;
		} else {
			high = middle - 1;
		}
	}
	return -1;
}

bool NativeUnitViews::has_view(int64_t id) const {
	return drawn_slot(id) >= 0;
}

Vector3 NativeUnitViews::puppet_position(int64_t id) const {
	const int64_t slot = drawn_slot(id);
	if (slot < 0) {
		return Vector3(0.0f, 0.0f, 0.0f);
	}
	return drawn_origins_[static_cast<size_t>(slot)];
}

int64_t NativeUnitViews::hp_of(int64_t id) const {
	const Record *record = find(id);
	if (record == nullptr || !record->has_hp) {
		return -1;
	}
	return record->hp;
}

int64_t NativeUnitViews::max_hp_of(int64_t id) const {
	const Record *record = find(id);
	if (record == nullptr) {
		return 0;
	}
	return record->max_hp;
}
