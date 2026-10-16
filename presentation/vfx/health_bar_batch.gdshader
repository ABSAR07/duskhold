shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled;
// A billboard health bar drawn once per instance. The fill ratio rides in INSTANCE_CUSTOM.x: the
// left `ratio` of the quad is the fill (a slimmer band than the background, as HealthBar3D draws
// it) and the rest is the dark background. The quad turns to face the camera and keeps the
// instance's scale. Verified in Forward+ and Compatibility (RESEARCH F6).

uniform vec4 fill_color : source_color = vec4(0.85, 0.2, 0.18, 1.0);
uniform vec4 background_color : source_color = vec4(0.08, 0.08, 0.1, 0.8);
// The fill spans this share of the bar's height, centred.
uniform float fill_band = 0.7;

varying float ratio;

void vertex() {
	ratio = INSTANCE_CUSTOM.x;
	mat4 view_model = VIEW_MATRIX * MODEL_MATRIX;
	view_model[0] = vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0);
	view_model[1] = vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0);
	view_model[2] = vec4(0.0, 0.0, 1.0, 0.0);
	MODELVIEW_MATRIX = view_model;
}

void fragment() {
	float half_gap = (1.0 - fill_band) * 0.5;
	bool in_band = UV.y >= half_gap && UV.y <= 1.0 - half_gap;
	vec4 shown = (UV.x <= ratio && in_band) ? fill_color : background_color;
	ALBEDO = shown.rgb;
	ALPHA = shown.a;
}
