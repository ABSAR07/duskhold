shader_type spatial;
// One body of a crowd batch. The flash amount rides in INSTANCE_CUSTOM.x (1.0 at a hit, falling
// to 0.0) and a per-instance tint in COLOR; both reach the fragment stage as varyings. The tint is
// white for enemies and carries the arrow colours of the projectile batch (sRGB, converted below). Verified in Forward+ and
// Compatibility (RESEARCH F6).

uniform vec4 albedo : source_color = vec4(1.0);
uniform float calm_energy = 0.35;
uniform float flash_energy = 3.0;

varying float flash;
varying vec3 tint;

// An instance colour reaches the shader as written, in linear space, while the colours this game
// authors (arrow gold, skirmisher violet) are sRGB like every other colour it sets; convert so a
// tinted arrow matches the StandardMaterial3D arrow it replaced.
vec3 srgb_to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

void vertex() {
	flash = INSTANCE_CUSTOM.x;
	tint = srgb_to_linear(COLOR.rgb);
}

void fragment() {
	vec3 base = albedo.rgb * tint;
	ALBEDO = base;
	EMISSION = base * mix(calm_energy, flash_energy, clamp(flash, 0.0, 1.0));
}
