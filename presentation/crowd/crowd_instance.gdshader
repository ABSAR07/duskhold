shader_type spatial;
// One body of a crowd batch. The flash amount rides in INSTANCE_CUSTOM.x (1.0 at a hit, falling
// to 0.0) and a per-instance tint in COLOR; both reach the fragment stage as varyings. The tint is
// white for enemies and carries the arrow colours of the projectile batch. Verified in Forward+ and
// Compatibility (RESEARCH F6).

uniform vec4 albedo : source_color = vec4(1.0);
uniform float calm_energy = 0.35;
uniform float flash_energy = 3.0;

varying float flash;
varying vec3 tint;

void vertex() {
	flash = INSTANCE_CUSTOM.x;
	tint = COLOR.rgb;
}

void fragment() {
	vec3 base = albedo.rgb * tint;
	ALBEDO = base;
	EMISSION = base * mix(calm_energy, flash_energy, clamp(flash, 0.0, 1.0));
}
