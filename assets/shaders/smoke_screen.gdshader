shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float time : hint_range(0.0, 100.0) = 1.0;
uniform float scroll_speed = 0.02;
uniform vec2 scroll_direction = vec2(0.3, 0.7);
uniform float edge_fade = 0.1; // How much to fade at edges (0.0-0.5)

void fragment() {
	// Scroll the UV coordinates over time and wrap seamlessly
	vec2 scrolled_uv = fract(UV + scroll_direction * time * scroll_speed);

	// Sample the noise texture with scrolling UVs
	vec4 noise = texture(noise_texture, scrolled_uv);

	// Calculate edge fade to keep smoke within bounds
	float fade_left = smoothstep(0.0, edge_fade, UV.x);
	float fade_right = smoothstep(1.0, 1.0 - edge_fade, UV.x);
	float fade_top = smoothstep(0.0, edge_fade, UV.y);
	float fade_bottom = smoothstep(1.0, 1.0 - edge_fade, UV.y);
	float edge_mask = fade_left * fade_right * fade_top * fade_bottom;

	// Use noise to create wispy smoke effect with edge fadeout
	// Multiply by COLOR to respect the sprite's modulate (opacity)
	float alpha = noise.r * edge_mask;
	COLOR = vec4(vec3(0.9, 0.9, 1.0), alpha) * COLOR;
}
