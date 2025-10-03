class_name StartingSegment
extends BaseSegment

## Special starting segment that forms the base of the tunnel
## Has walls on west (left), east (right), and south (bottom)
## No obstacles or collectibles

func initialize_starting_segment(tunnel_width: float = 250.0, length: float = 600.0) -> void:
    # Create minimal segment data
    var data = SegmentData.new()
    data.segment_id = "starting_segment"
    data.segment_type = "starting"
    data.segment_length = length
    data.tunnel_width = tunnel_width
    data.obstacles = [] as Array[Dictionary]
    data.collectibles = [] as Array[Dictionary]

    initialize(data, -1)  # Index -1 to mark as special

    # Draw the three walls (west, east, south)
    _draw_starting_walls()

func _draw_starting_walls() -> void:
    # Clear any existing walls first
    for child in walls_container.get_children():
        child.queue_free()

    var half_width = segment_data.tunnel_width / 2.0
    var length = segment_data.segment_length

    # Calculate wall positioning (same as base segment)
    var max_tunnel_half_width = 140.0
    var wall_line_position = (half_width + max_tunnel_half_width) / 2.0
    var wall_thickness = max_tunnel_half_width - half_width

    if wall_thickness < 8.0:
        wall_thickness = 8.0
        wall_line_position = half_width + (wall_thickness / 2.0)

    # Left wall (west) - extends upward from bottom
    _create_wall_with_collision(Vector2(-wall_line_position, 0), Vector2(-wall_line_position, -length), wall_thickness)

    # Right wall (east) - extends upward from bottom
    _create_wall_with_collision(Vector2(wall_line_position, 0), Vector2(wall_line_position, -length), wall_thickness)

    # Bottom wall (south) - connects left and right at the bottom
    _create_wall_with_collision(Vector2(-wall_line_position, 0), Vector2(wall_line_position, 0), wall_thickness)

func _create_wall_with_collision(start_pos: Vector2, end_pos: Vector2, thickness: float) -> void:
    # Create visual wall (Line2D)
    var wall_visual = Line2D.new()
    wall_visual.add_point(start_pos)
    wall_visual.add_point(end_pos)
    wall_visual.width = thickness
    wall_visual.default_color = Color(0.4, 0.7, 1.0, 0.8)
    wall_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
    wall_visual.end_cap_mode = Line2D.LINE_CAP_ROUND

    # Create collision (StaticBody2D with rectangular shape)
    var wall_collision = StaticBody2D.new()
    var collision_shape = CollisionShape2D.new()
    var shape = RectangleShape2D.new()

    # Calculate rectangle dimensions and position
    var wall_length = start_pos.distance_to(end_pos)
    var wall_direction = (end_pos - start_pos).normalized()
    var wall_angle = wall_direction.angle()

    shape.size = Vector2(thickness, wall_length)

    # Position collision at midpoint of the wall
    var midpoint = (start_pos + end_pos) / 2.0
    wall_collision.position = midpoint
    wall_collision.rotation = wall_angle + PI/2  # Rotate to align with wall direction

    collision_shape.shape = shape
    wall_collision.add_child(collision_shape)

    # Set collision layers: walls on layer 8
    wall_collision.collision_layer = 8
    wall_collision.collision_mask = 0  # Walls don't detect anything, just block

    walls_container.add_child(wall_visual)
    walls_container.add_child(wall_collision)
