#pragma once

#include <cstdint>

#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_int64_array.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace duskhold {

// The instance layout of a CrowdBatch (presentation/crowd/crowd_batch.gd) and the writer of one
// instance, shared by every native view fill (PLAT-01, plan 04-25: the arrows; 04-26 and 04-27 the
// enemy, unit and puff batches). A native fill works on its own copy of the batch's CPU mirror and
// GDScript hands the filled copy back with CrowdBatch.commit_buffer, so the mirror stays the one
// readable truth of what is drawn.
//
// Per instance, in floats: [12 transform: xx xy xz ox, yx yy yz oy, zx zy zz oz][4 colour, only
// with colours][4 custom]. CrowdBatch.layout() answers {capacity, stride, colour offset or -1,
// custom offset}.
constexpr int64_t TRANSFORM_FLOATS = 12;
constexpr int64_t COLOR_FLOATS = 4;
constexpr int64_t CUSTOM_FLOATS = 4;

struct MirrorLayout {
	int64_t capacity = 0;
	int64_t stride = 0;
	// Offset of the colour inside an instance, -1 for a batch without colours.
	int64_t color_offset = -1;
	int64_t custom_offset = 0;
};

// Reads CrowdBatch.layout() for a mirror of `mirror_size` floats. False, and `out` untouched, unless
// there are four values, the capacity is above 0, the mirror is exactly capacity * stride floats
// and the transform, the colour (when there is one) and the custom data each fit inside the stride
// behind the previous one (exact_port_rules 10: a bad layout never lets a writer leave the mirror).
inline bool layout_from(
		const godot::PackedInt64Array &layout, int64_t mirror_size, MirrorLayout &out) {
	if (layout.size() != 4) {
		return false;
	}
	MirrorLayout candidate;
	candidate.capacity = layout[0];
	candidate.stride = layout[1];
	candidate.color_offset = layout[2];
	candidate.custom_offset = layout[3];
	if (candidate.capacity <= 0 || candidate.stride < TRANSFORM_FLOATS + CUSTOM_FLOATS) {
		return false;
	}
	if (candidate.capacity > INT64_MAX / candidate.stride) {
		return false;
	}
	if (mirror_size != candidate.capacity * candidate.stride) {
		return false;
	}
	if (candidate.color_offset != -1 &&
			(candidate.color_offset < TRANSFORM_FLOATS ||
					candidate.color_offset > candidate.stride - COLOR_FLOATS)) {
		return false;
	}
	if (candidate.custom_offset < TRANSFORM_FLOATS ||
			candidate.custom_offset > candidate.stride - CUSTOM_FLOATS) {
		return false;
	}
	out = candidate;
	return true;
}

// CrowdBatch.add_transform's floats for instance `index` of the mirror `m` (index below
// layout.capacity, m holding capacity * stride floats): row r of the basis is x_axis[r], y_axis[r],
// z_axis[r]; the origin sits at offsets 3, 7 and 11; the colour only when the batch has colours;
// then the custom data. Every float is a plain store of an operand, no arithmetic.
inline void write_transform(
		float *m,
		const MirrorLayout &layout,
		int64_t index,
		const godot::Vector3 &x_axis,
		const godot::Vector3 &y_axis,
		const godot::Vector3 &z_axis,
		const godot::Vector3 &origin,
		const godot::Color &custom,
		const godot::Color &color) {
	float *at = m + index * layout.stride;
	at[0] = x_axis.x;
	at[1] = y_axis.x;
	at[2] = z_axis.x;
	at[4] = x_axis.y;
	at[5] = y_axis.y;
	at[6] = z_axis.y;
	at[8] = x_axis.z;
	at[9] = y_axis.z;
	at[10] = z_axis.z;
	at[3] = origin.x;
	at[7] = origin.y;
	at[11] = origin.z;
	if (layout.color_offset >= 0) {
		float *tint = at + layout.color_offset;
		tint[0] = color.r;
		tint[1] = color.g;
		tint[2] = color.b;
		tint[3] = color.a;
	}
	float *data = at + layout.custom_offset;
	data[0] = custom.r;
	data[1] = custom.g;
	data[2] = custom.b;
	data[3] = custom.a;
}

} // namespace duskhold
