shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, shadows_disabled;
// A death puff: a small sphere that grows and fades with its age. The age (0 at the death, 1 at
// the end of its life) rides in INSTANCE_CUSTOM.x and the enemy's colour in COLOR. Replaces one
// particle node and one timer per death.

uniform float grow = 1.0;

varying float age;
varying vec3 tint;

void vertex() {
	age = clamp(INSTANCE_CUSTOM.x, 0.0, 1.0);
	tint = COLOR.rgb;
	VERTEX *= 1.0 + age * grow;
}

void fragment() {
	ALBEDO = tint;
	ALPHA = 1.0 - age;
}
