#include "native_enemy_views.h"

#include <algorithm>
#include <cstdint>

#include <godot_cpp/core/class_db.hpp>
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

void NativeEnemyViews::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("configure", "max_views", "lifts", "bar_clearance", "flash_seconds"),
			&NativeEnemyViews::configure);
	ClassDB::bind_method(D_METHOD("set_mirror", "batch", "mirror", "layout"), &NativeEnemyViews::set_mirror);
	ClassDB::bind_method(D_METHOD("on_spawned", "id", "kind", "max_hp"), &NativeEnemyViews::on_spawned);
	ClassDB::bind_method(D_METHOD("on_damaged", "id", "hp", "hit_ms"), &NativeEnemyViews::on_damaged);
	ClassDB::bind_method(D_METHOD("forget", "id"), &NativeEnemyViews::forget);
	ClassDB::bind_method(D_METHOD("clear"), &NativeEnemyViews::clear);
	ClassDB::bind_method(D_METHOD("known_count"), &NativeEnemyViews::known_count);
	ClassDB::bind_method(
			D_METHOD("fill", "frame_ms", "blend", "ids", "previous", "current"),
			&NativeEnemyViews::fill);
	ClassDB::bind_method(D_METHOD("mirror", "batch"), &NativeEnemyViews::mirror);
	ClassDB::bind_method(D_METHOD("count", "batch"), &NativeEnemyViews::count);
	ClassDB::bind_method(D_METHOD("drawn_count"), &NativeEnemyViews::drawn_count);
	ClassDB::bind_method(D_METHOD("has_view", "id"), &NativeEnemyViews::has_view);
	ClassDB::bind_method(D_METHOD("puppet_position", "id"), &NativeEnemyViews::puppet_position);
	ClassDB::bind_method(D_METHOD("flash_of", "id"), &NativeEnemyViews::flash_of);
	ClassDB::bind_method(D_METHOD("hp_of", "id"), &NativeEnemyViews::hp_of);
	ClassDB::bind_method(D_METHOD("max_hp_of", "id"), &NativeEnemyViews::max_hp_of);

	BIND_CONSTANT(BATCH_BARS);
	BIND_CONSTANT(BATCH_TOTAL);
}

void NativeEnemyViews::configure(
		int64_t max_views,
		const PackedFloat32Array &lifts,
		double bar_clearance,
		double flash_seconds) {
	bar_clearance_ = bar_clearance;
	flash_seconds_ = flash_seconds;
	lifts_.clear();
	for (int64_t index = 0; index < lifts.size(); index++) {
		lifts_.push_back(lifts[index]);
	}
	drawn_ = 0;
	drawn_ids_.clear();
	drawn_origins_.clear();
	max_views_ = 0;
	configured_ = false;
	if (max_views < 1 || max_views > MAX_VIEWS_LIMIT || lifts_.empty()) {
		return;
	}
	max_views_ = max_views;
	drawn_ids_.assign(static_cast<size_t>(max_views), 0);
	drawn_origins_.assign(static_cast<size_t>(max_views), Vector3(0.0f, 0.0f, 0.0f));
	configured_ = true;
}

bool NativeEnemyViews::set_mirror(
		int64_t batch, const PackedFloat32Array &mirror, const PackedInt64Array &layout) {
	if (batch < 0 || batch >= BATCH_TOTAL) {
		return false;
	}
	duskhold::MirrorLayout parsed;
	if (!duskhold::layout_from(layout, mirror.size(), parsed)) {
		return false;
	}
	const size_t at = static_cast<size_t>(batch);
	mirrors_[at] = mirror;
	layouts_[at] = parsed;
	mirror_ready_[at] = true;
	counts_[at] = 0;
	return true;
}

NativeEnemyViews::Record *NativeEnemyViews::find(int64_t id) {
	const auto at = std::lower_bound(
			records_.begin(), records_.end(), id, [](const Record &record, int64_t wanted) {
				return record.id < wanted;
			});
	if (at == records_.end() || at->id != id) {
		return nullptr;
	}
	return &*at;
}

const NativeEnemyViews::Record *NativeEnemyViews::find(int64_t id) const {
	const auto at = std::lower_bound(
			records_.begin(), records_.end(), id, [](const Record &record, int64_t wanted) {
				return record.id < wanted;
			});
	if (at == records_.end() || at->id != id) {
		return nullptr;
	}
	return &*at;
}

void NativeEnemyViews::on_spawned(int64_t id, int64_t kind, int64_t max_hp) {
	const auto at = std::lower_bound(
			records_.begin(), records_.end(), id, [](const Record &record, int64_t wanted) {
				return record.id < wanted;
			});
	if (at != records_.end() && at->id == id) {
		at->kind = kind;
		at->max_hp = max_hp;
		return;
	}
	Record fresh;
	fresh.id = id;
	fresh.kind = kind;
	fresh.max_hp = max_hp;
	records_.insert(at, fresh);
}

void NativeEnemyViews::on_damaged(int64_t id, int64_t hp, int64_t hit_ms) {
	Record *record = find(id);
	if (record == nullptr) {
		return;
	}
	record->hit_ms = hit_ms;
	record->has_hp = true;
	record->hp = hp;
}

void NativeEnemyViews::forget(int64_t id) {
	const auto at = std::lower_bound(
			records_.begin(), records_.end(), id, [](const Record &record, int64_t wanted) {
				return record.id < wanted;
			});
	if (at != records_.end() && at->id == id) {
		records_.erase(at);
	}
}

void NativeEnemyViews::clear() {
	records_.clear();
}

int64_t NativeEnemyViews::known_count() const {
	return static_cast<int64_t>(records_.size());
}

double NativeEnemyViews::flash_amount(Record &record) const {
	const int64_t hit = record.hit_ms;
	if (hit < 0) {
		return 0.0;
	}
	// int64 subtraction wraps as the engine's does.
	const int64_t since = static_cast<int64_t>(static_cast<uint64_t>(frame_ms_) - static_cast<uint64_t>(hit));
	const double elapsed_s = static_cast<double>(gd::maxi(since, 0)) / 1000.0;
	const double amount = 1.0 - elapsed_s / flash_seconds_;
	if (amount <= 0.0) {
		record.hit_ms = -1;
		return 0.0;
	}
	return amount;
}

bool NativeEnemyViews::ready() const {
	if (!configured_) {
		return false;
	}
	for (int64_t batch = 0; batch < BATCH_TOTAL; batch++) {
		if (!mirror_ready_[batch]) {
			return false;
		}
	}
	return true;
}

int64_t NativeEnemyViews::fill(
		int64_t frame_ms,
		double blend,
		const PackedInt64Array &ids,
		const PackedVector2Array &previous,
		const PackedVector2Array &current) {
	frame_ms_ = frame_ms;
	// CrowdBatch.begin() for every batch: no instance is held until one is written.
	for (int64_t batch = 0; batch < BATCH_TOTAL; batch++) {
		counts_[batch] = 0;
	}
	drawn_ = 0;
	const int64_t total = ids.size();
	if (!ready() || previous.size() != total || current.size() != total) {
		return 0;
	}
	const int64_t archetypes = std::min(static_cast<int64_t>(lifts_.size()), static_cast<int64_t>(BATCH_BARS));
	const real_t weight = static_cast<real_t>(blend);
	const int64_t *id_at = ids.ptr();
	const Vector2 *previous_at = previous.ptr();
	const Vector2 *current_at = current.ptr();
	// A mirror is taken for writing only when its first instance is written, so a frame that draws
	// nothing into a batch never copies the mirror that batch still shares (review IN-08).
	float *buffers[BATCH_TOTAL] = { nullptr, nullptr, nullptr, nullptr };
	const Color no_tint = Color(1.0f, 1.0f, 1.0f, 1.0f);

	for (int64_t slot = 0; slot < total; slot++) {
		if (drawn_ >= max_views_) {
			break;
		}
		const int64_t enemy_id = id_at[slot];
		Record *record = find(enemy_id);
		if (record == nullptr) {
			continue;
		}
		const int64_t kind = record->kind;
		if (kind < 0 || kind >= archetypes) {
			continue;
		}
		const Vector2 ground = gd::lerp(previous_at[slot], current_at[slot], weight);
		const float lift = lifts_[static_cast<size_t>(kind)];
		const Vector3 origin = Vector3(ground.x, lift, ground.y);
		// The flash is worked out before the add, so a hit is forgotten even when the batch is full.
		const double flash = flash_amount(*record);
		const Color custom = Color(static_cast<float>(flash), 0.0f, 0.0f, 0.0f);
		if (counts_[kind] >= layouts_[kind].capacity) {
			continue;
		}
		if (buffers[kind] == nullptr) {
			buffers[kind] = mirrors_[kind].ptrw();
		}
		duskhold::write_origin(buffers[kind], layouts_[kind], counts_[kind], origin, custom, no_tint);
		counts_[kind]++;
		drawn_ids_[static_cast<size_t>(drawn_)] = static_cast<int32_t>(enemy_id);
		drawn_origins_[static_cast<size_t>(drawn_)] = Vector3(ground.x, 0.0f, ground.y);
		drawn_++;
		if (record->has_hp && bar_shows(record->hp, record->max_hp) &&
				counts_[BATCH_BARS] < layouts_[BATCH_BARS].capacity) {
			const Vector3 bar_origin = Vector3(
					ground.x, static_cast<real_t>(static_cast<double>(lift) * 2.0 + bar_clearance_), ground.y);
			const Color ratio = Color(
					static_cast<float>(static_cast<double>(record->hp) / static_cast<double>(record->max_hp)),
					0.0f,
					0.0f,
					0.0f);
			if (buffers[BATCH_BARS] == nullptr) {
				buffers[BATCH_BARS] = mirrors_[BATCH_BARS].ptrw();
			}
			duskhold::write_origin(
					buffers[BATCH_BARS], layouts_[BATCH_BARS], counts_[BATCH_BARS], bar_origin, ratio, no_tint);
			counts_[BATCH_BARS]++;
		}
	}
	return drawn_;
}

PackedFloat32Array NativeEnemyViews::mirror(int64_t batch) const {
	if (batch < 0 || batch >= BATCH_TOTAL) {
		return PackedFloat32Array();
	}
	return mirrors_[batch];
}

int64_t NativeEnemyViews::count(int64_t batch) const {
	if (batch < 0 || batch >= BATCH_TOTAL) {
		return 0;
	}
	return counts_[batch];
}

int64_t NativeEnemyViews::drawn_count() const {
	return drawn_;
}

int64_t NativeEnemyViews::drawn_slot(int64_t id) const {
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

bool NativeEnemyViews::has_view(int64_t id) const {
	return drawn_slot(id) >= 0;
}

Vector3 NativeEnemyViews::puppet_position(int64_t id) const {
	const int64_t slot = drawn_slot(id);
	if (slot < 0) {
		return Vector3(0.0f, 0.0f, 0.0f);
	}
	return drawn_origins_[static_cast<size_t>(slot)];
}

double NativeEnemyViews::flash_of(int64_t id) {
	if (drawn_slot(id) < 0) {
		return 0.0;
	}
	Record *record = find(id);
	if (record == nullptr) {
		return 0.0;
	}
	return flash_amount(*record);
}

int64_t NativeEnemyViews::hp_of(int64_t id) const {
	const Record *record = find(id);
	if (record == nullptr || !record->has_hp) {
		return -1;
	}
	return record->hp;
}

int64_t NativeEnemyViews::max_hp_of(int64_t id) const {
	const Record *record = find(id);
	if (record == nullptr) {
		return 0;
	}
	return record->max_hp;
}
