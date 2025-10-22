shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	// Invert black to white, then tint with target color
	float brightness = 1.0 - tex_color.r;
	COLOR = vec4(target_color.rgb * brightness, tex_color.a);
}
