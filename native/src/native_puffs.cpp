#include "native_puffs.h"

#include <cstdint>

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void NativePuffs::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("configure", "capacity", "puff_seconds", "never_born_s"), &NativePuffs::configure);
	ClassDB::bind_method(D_METHOD("set_mirror", "mirror", "layout"), &NativePuffs::set_mirror);
	ClassDB::bind_method(D_METHOD("spawn", "origin", "now_s", "color"), &NativePuffs::spawn);
	ClassDB::bind_method(D_METHOD("refresh", "now_s"), &NativePuffs::refresh);
	ClassDB::bind_method(D_METHOD("active_count"), &NativePuffs::active_count);
	ClassDB::bind_method(D_METHOD("mirror"), &NativePuffs::mirror);
}

void NativePuffs::configure(int64_t capacity, double puff_seconds, double never_born_s) {
	puff_seconds_ = puff_seconds;
	next_ = 0;
	origins_.clear();
	born_.clear();
	colors_.clear();
	if (capacity < 1 || capacity > MAX_CAPACITY) {
		return;
	}
	const size_t slots = static_cast<size_t>(capacity);
	origins_.assign(slots, Vector3(0.0f, 0.0f, 0.0f));
	born_.assign(slots, never_born_s);
	// A PackedColorArray resized in GDScript holds the default colour (black, opaque) in a slot
	// nothing was written to; such a slot is never drawn.
	colors_.assign(slots, Color(0.0f, 0.0f, 0.0f, 1.0f));
}

bool NativePuffs::set_mirror(const PackedFloat32Array &mirror, const PackedInt64Array &layout) {
	duskhold::MirrorLayout parsed;
	if (!duskhold::layout_from(layout, mirror.size(), parsed)) {
		return false;
	}
	mirror_ = mirror;
	layout_ = parsed;
	mirror_ready_ = true;
	return true;
}

void NativePuffs::spawn(const Vector3 &origin, double now_s, const Color &color) {
	if (born_.empty()) {
		return;
	}
	now_s_ = now_s;
	if (active_count() >= static_cast<int64_t>(born_.size())) {
		return;
	}
	const size_t at = static_cast<size_t>(next_);
	origins_[at] = origin;
	colors_[at] = color;
	born_[at] = now_s;
	next_ = (next_ + 1) % static_cast<int64_t>(born_.size());
}

int64_t NativePuffs::refresh(double now_s) {
	if (born_.empty()) {
		return 0;
	}
	now_s_ = now_s;
	if (!mirror_ready_) {
		return 0;
	}
	const int64_t slots = static_cast<int64_t>(born_.size());
	int64_t written = 0;
	// The buffer is taken for writing only once a puff is drawn, so a frame with none standing
	// never copies the mirror the batch still shares.
	float *buffer = nullptr;
	for (int64_t step = 0; step < slots; step++) {
		const size_t slot = static_cast<size_t>((next_ + step) % slots);
		const double age = (now_s - born_[slot]) / puff_seconds_;
		if (age < 0.0 || age >= 1.0) {
			continue;
		}
		if (written >= layout_.capacity) {
			continue;
		}
		if (buffer == nullptr) {
			buffer = mirror_.ptrw();
		}
		const Color custom = Color(static_cast<float>(age), 0.0f, 0.0f, 0.0f);
		duskhold::write_origin(buffer, layout_, written, origins_[slot], custom, colors_[slot]);
		written++;
	}
	return written;
}

int64_t NativePuffs::active_count() const {
	int64_t standing = 0;
	for (size_t slot = 0; slot < born_.size(); slot++) {
		const double age = (now_s_ - born_[slot]) / puff_seconds_;
		if (age >= 0.0 && age < 1.0) {
			standing++;
		}
	}
	return standing;
}

PackedFloat32Array NativePuffs::mirror() const {
	return mirror_;
}
