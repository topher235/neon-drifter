extends BaseCollectible

@export var time_bonus: float = 10.0  # Seconds to add
@export var hourglass_color: Color = Color(1, 1, 1, 1)  # White
@export var hourglass_size: float = 24.0


func _ready() -> void:
    super._ready()
    add_to_group("hourglass")
    # Not setting up visual since we're using an icon now
    #    _setup_visual()
    _setup_collision()


func _setup_visual() -> void:
    if visual:
        # Create hourglass shape using Polygon2D
        var polygon = Polygon2D.new()

        # Define hourglass shape (two triangles meeting at center)
        # Top triangle pointing down, bottom triangle pointing up
        var half_size  = hourglass_size / 2.0
        var neck_width = hourglass_size / 6.0  # Narrow middle

        var points = PackedVector2Array([
        # Top triangle (pointing down)
        Vector2(-half_size, -half_size), # Top left
        Vector2(half_size, -half_size), # Top right
        Vector2(neck_width, 0), # Middle right
        Vector2(-neck_width, 0), # Middle left
        # Bottom triangle (pointing up) - going clockwise
        Vector2(-neck_width, 0), # Middle left
        Vector2(neck_width, 0), # Middle right
        Vector2(half_size, half_size), # Bottom right
        Vector2(-half_size, half_size)        # Bottom left
        ])

        polygon.polygon = points
        polygon.color = hourglass_color

        # Remove the ColorRect visual and add our polygon instead
        if visual:
            visual.queue_free()

        # Add polygon as a child of this collectible
        add_child(polygon)


# Update the visual reference to point to a dummy node (since base class expects ColorRect)
# We'll handle rendering with the polygon instead

func _setup_collision() -> void:
    # Use a circular collision shape for easier collection
    var shape = CircleShape2D.new()
    shape.radius = hourglass_size * 0.6
    collision_shape.shape = shape


func _on_collected() -> void:
    GameManager.add_daily_challenge_time(time_bonus)
    AudioManager.play_sfx("item_collect", -0.1)  # Lower pitch than orb
    _spawn_particles()
