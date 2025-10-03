shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.2, 0.5, 1.0, 0.3);
uniform float grid_size : hint_range(10.0, 200.0) = 50.0;
uniform float line_width : hint_range(1.0, 5.0) = 2.0;
uniform float scroll_speed : hint_range(0.0, 500.0) = 100.0;
uniform float time_scale : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	// Calculate scrolling offset
	float scroll_offset = TIME * scroll_speed * time_scale;
	
	// Adjusted UV with scrolling
	vec2 uv = UV * vec2(1000.0, 1000.0);  // Scale up
	uv.x += scroll_offset;
	
	// Grid lines
	vec2 grid = abs(fract(uv / grid_size - 0.5) - 0.5) / fwidth(uv / grid_size);
	float line = min(grid.x, grid.y);
	
	// Apply line width
	float grid_line = 1.0 - min(line / line_width, 1.0);
	
	// Output color
	vec4 color = line_color;
	color.a *= grid_line;
	
	COLOR = color;
}