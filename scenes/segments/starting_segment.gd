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

    # Set segment data directly without calling base initialize
    segment_data = data
    segment_index = -1
    is_active = true

    # Clear containers but don't spawn anything
    _clear_containers()

    # Draw the three walls (west, east, south)
    _draw_starting_walls()

    # Add kill zone below the south wall
    _create_boundary_kill_zone()

func _draw_starting_walls() -> void:
    # Clear any existing walls first
    for child in walls_container.get_children():
        child.queue_free()

    var half_width = segment_data.tunnel_width / 2.0  # Always 125.0
    var length = segment_data.segment_length

    # All tunnels are now 250px wide, so walls are at fixed positions
    var wall_line_position = half_width
    var wall_thickness = 16.0

    # Left wall (west) - extends upward from bottom
    _create_wall_with_collision(Vector2(-wall_line_position, 0), Vector2(-wall_line_position, -length), wall_thickness, false)

    # Right wall (east) - extends upward from bottom
    _create_wall_with_collision(Vector2(wall_line_position, 0), Vector2(wall_line_position, -length), wall_thickness, false)

    # Bottom wall (south) - connects left and right at the bottom
    _create_wall_with_collision(Vector2(-wall_line_position, 0), Vector2(wall_line_position, 0), wall_thickness, true)

func _create_wall_with_collision(start_pos: Vector2, end_pos: Vector2, thickness: float, use_round_caps: bool = false) -> void:
    # Create visual wall (Line2D)
    var wall_visual = Line2D.new()
    wall_visual.add_point(start_pos)
    wall_visual.add_point(end_pos)
    wall_visual.width = thickness
    wall_visual.default_color = Color(0.4, 0.7, 1.0, 0.8)

    if use_round_caps:
        wall_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
        wall_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
    else:
        wall_visual.begin_cap_mode = Line2D.LINE_CAP_NONE  # No cap at segment boundary
        wall_visual.end_cap_mode = Line2D.LINE_CAP_BOX  # Cap at far end

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

func _create_boundary_kill_zone() -> void:
    # Create an Area2D that triggers player death if they go below the south wall
    var kill_zone = Area2D.new()
    var kill_shape = CollisionShape2D.new()
    var shape = RectangleShape2D.new()

    var half_width = segment_data.tunnel_width / 2.0

    # Create a large zone below the south wall (Y=0)
    # Zone extends from south wall (Y=0) down to Y=200
    shape.size = Vector2(segment_data.tunnel_width + 100, 400)  # Extra wide to catch any edge cases

    # Position at center of kill zone (Y=100, below the south wall at Y=0)
    kill_zone.position = Vector2(0, 200)
    kill_shape.shape = shape
    kill_zone.add_child(kill_shape)

    # Set collision layer 32 for boundary kill zones
    kill_zone.collision_layer = 32
    kill_zone.collision_mask = 0
    kill_zone.add_to_group("boundary_kill_zone")

    walls_container.add_child(kill_zone)
