extends BaseCollectible

@export var point_value: int = 10
@export var orb_color: Color = Color(0, 1, 1, 1)  # Cyan
@export var orb_radius: float = 15.0

var polygon_node: Polygon2D = null


func _ready() -> void:
    super._ready()
    add_to_group("orb")
    _setup_visual()
    _setup_collision()


func _setup_visual() -> void:
    if visual:
        # Create circular shape using Polygon2D
        var circle_polygon = Polygon2D.new()

        # Generate circle points
        var num_points = 32
        var points = PackedVector2Array()

        for i in range(num_points):
            var angle = (float(i) / num_points) * TAU
            var x = cos(angle) * orb_radius
            var y = sin(angle) * orb_radius
            points.append(Vector2(x, y))

        circle_polygon.polygon = points
        circle_polygon.color = orb_color

        # Remove the ColorRect visual
        visual.queue_free()

        # Add circle as a child
        add_child(circle_polygon)
        polygon_node = circle_polygon


func _setup_collision() -> void:
    var shape = CircleShape2D.new()
    shape.radius = orb_radius
    collision_shape.shape = shape


func _on_collected() -> void:
    GameManager.collect_orb(point_value)
    AudioManager.play_sfx("orb_collect")
    _spawn_particles()
