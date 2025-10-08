shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 3.0) = 1.5;

void fragment() {
    // Use the color from Line2D's gradient system
    vec4 line_color = COLOR;  // Get Line2D's color (supports gradient)

    // Apply glow strength while preserving color hue
    // Only boost the alpha/brightness, not the RGB channels directly
    COLOR = line_color;
    COLOR.a *= glow_strength;  // Make the glow more intense via alpha
}
