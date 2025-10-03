shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 3.0) = 3.0;
uniform float tail_fade : hint_range(0.0, 1.0) = 0.0;  // Alpha at tail
uniform float head_alpha : hint_range(0.0, 1.0) = 1.0;  // Alpha at head

void fragment() {
    // Use UV.y (perpendicular distance from line center) and VERTEX position
    // For Line2D, we need to use the actual COLOR.a that Line2D might provide
    // Or we can use a distance-based fade

    // Get distance along the line using VERTEX.x (screen space position)
    // This won't work well, so let's use a simpler approach:
    // Just apply the COLOR that Line2D provides with gradient support

    vec4 line_color = COLOR;  // Get Line2D's color (supports gradient)

    COLOR = glow_color;
    COLOR.rgb *= glow_strength;
    COLOR.a *= line_color.a;  // Use Line2D's alpha from gradient
}
