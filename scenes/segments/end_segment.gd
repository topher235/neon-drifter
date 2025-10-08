class_name EndSegment
extends BaseSegment

## Special ending segment that marks the end of the tunnel for daily challenges
## Has walls on west (left), east (right), and north (top)
## Features a checkerboard pattern visual and trigger area to end the run

signal run_completed

@export var trigger_area: Area2D

func _ready() -> void:
    initialize_end_segment()
    position = Vector2(250, 700)


func initialize_end_segment(tunnel_width: float = 250.0, length: float = 600.0) -> void:
    # Create minimal segment data
    var data = SegmentData.new()
    data.segment_id = "end_segment"
    data.segment_type = "ending"
    data.segment_length = length
    data.tunnel_width = tunnel_width
    data.obstacles = [] as Array[Dictionary]
    data.collectibles = [] as Array[Dictionary]

    initialize(data, 9999)  # High index to mark as special end segment

    # Draw the three walls (west, east, north)
    _draw_ending_walls()

    # Create the checkerboard pattern
    _draw_checkerboard_pattern()

    # Setup the trigger area
    _setup_trigger_area()

func _draw_ending_walls() -> void:
    # Clear any existing walls first
    for child in walls_container.get_children():
        child.queue_free()

    var half_width = segment_data.tunnel_width / 2.0  # Always 125.0
    var length = segment_data.segment_length

    # All tunnels are now 250px wide, so walls are at fixed positions
    var wall_line_position = half_width
    var wall_thickness = 8.0

    # Left wall (west) - extends downward from top
    _create_wall_with_collision(Vector2(-wall_line_position, 0), Vector2(-wall_line_position, -length), wall_thickness, false)

    # Right wall (east) - extends downward from top
    _create_wall_with_collision(Vector2(wall_line_position, 0), Vector2(wall_line_position, -length), wall_thickness, false)

    # Top wall (north) - connects left and right at the top (far end)
    _create_wall_with_collision(Vector2(-wall_line_position, -length), Vector2(wall_line_position, -length), wall_thickness, true)

func _draw_checkerboard_pattern() -> void:
    # Create a checkerboard pattern in the background as a visual cue
    var checker_size = 50.0  # Size of each checker square
    var half_width = segment_data.tunnel_width / 2.0
    var length = segment_data.segment_length

    # Calculate how many checkers we need
    var cols = int(segment_data.tunnel_width / checker_size)
    var rows = int(length / checker_size) + 1

    for row in range(rows):
        for col in range(cols):
            # Alternate pattern: even+even or odd+odd = light, even+odd or odd+even = dark
            var is_light = (row + col) % 2 == 0

            if is_light:
                var checker = ColorRect.new()
                checker.color = Color(1.0, 1.0, 1.0, 0.3)  # Semi-transparent white
                checker.size = Vector2(checker_size, checker_size)
                checker.position = Vector2(
                    -half_width + col * checker_size,
                    -row * checker_size
                )
                background.add_child(checker)

func _setup_trigger_area() -> void:
    # Create the trigger area if it doesn't exist
    if not trigger_area:
        trigger_area = Area2D.new()
        add_child(trigger_area)

        var collision = CollisionShape2D.new()
        var shape = RectangleShape2D.new()

        # Make the trigger area span the full width and be at the end
        var thickness := segment_data.segment_length
        shape.size = Vector2(segment_data.tunnel_width, thickness)
        collision.shape = shape

        # Position at the north wall (end of segment)
        trigger_area.position = Vector2(0, -segment_data.segment_length)

        trigger_area.add_child(collision)

        # Set up collision layers - layer 16 for triggers
        trigger_area.collision_layer = 16
        trigger_area.collision_mask = 1  # Detect player on layer 1

        # Connect signal
        trigger_area.body_entered.connect(_on_trigger_entered)
        trigger_area.area_entered.connect(_on_trigger_area_entered)

func _on_trigger_entered(body: Node2D) -> void:
    # Check if it's the player
    if body.is_in_group("player"):
        run_completed.emit()
        _complete_run()

func _on_trigger_area_entered(area: Area2D) -> void:
    # Alternative check in case player uses Area2D
    if area.get_parent() and area.get_parent().is_in_group("player"):
        run_completed.emit()
        _complete_run()

func _complete_run() -> void:
    # Notify GameManager that the run is complete
    if GameManager:
        GameManager.complete_daily_challenge()

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
