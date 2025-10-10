class_name BaseSegment
extends Node2D

# Configuration
var segment_data: SegmentData
var segment_index: int = 0

# Components
@export var obstacles_container: Node2D
@export var collectibles_container: Node2D
@export var walls_container: Node2D
@export var background: Node2D

# State
var is_active: bool = false

func initialize(data: SegmentData, index: int) -> void:
    segment_data = data
    segment_index = index
    is_active = true

    _clear_containers()
    _spawn_obstacles()
    _spawn_collectibles()
    _setup_walls()
    _setup_background()

func _clear_containers() -> void:
    # Clear any existing children (for pooling)
    for child in obstacles_container.get_children():
        child.queue_free()
    for child in collectibles_container.get_children():
        child.queue_free()

func _spawn_obstacles() -> void:
    for obs_data in segment_data.obstacles:
        var obstacle = _create_obstacle(obs_data)
        if obstacle:
            obstacles_container.add_child(obstacle)
            # Convert positive Y (distance into segment) to negative Y (upward direction)
            var pos = obs_data.position
            obstacle.position = Vector2(pos.x, -pos.y)

func _create_obstacle(data: Dictionary) -> Node2D:
    var obs_type = data.get("type", "pillar")

    match obs_type:
        "pillar":
            var pillar = preload("res://scenes/obstacles/pillar.tscn").instantiate()
            pillar.radius = data.get("radius", 30.0)
            return pillar

        "pulse_gate":
            var gate = preload("res://scenes/obstacles/pulse_gate.tscn").instantiate()
            gate.rotation_speed = data.get("rotation_speed", 1.0)
            return gate

        "horizontal_wall":
            var wall = preload("res://scenes/obstacles/horizontal_wall.tscn").instantiate()
            wall.wall_length = data.get("wall_length", 80)
            wall.thickness = data.get("thickness", 16.0)
            return wall

        "pulsing_wall":
            var pwall = preload("res://scenes/obstacles/pulsing_wall.tscn").instantiate()
            pwall.wall_length = data.get("wall_length", 80)
            pwall.thickness = data.get("thickness", 16.0)
            pwall.pulse_interval = data.get("pulse_interval", 1.0)
            return pwall

        "vertical_wall":
            var vwall = preload("res://scenes/obstacles/vertical_wall.tscn").instantiate()
            vwall.wall_height = data.get("wall_height", segment_data.segment_length)
            vwall.thickness = data.get("thickness", 16.0)
            return vwall

        "triangle_spike":
            var spike = preload("res://scenes/obstacles/triangle_spike.tscn").instantiate()
            spike.size = data.get("size", 30.0)
            spike.rotation_degrees = data.get("rotation_degrees", 0.0)
            return spike

        "smoke_screen":
            var smoke = preload("res://scenes/obstacles/smoke_screen.tscn").instantiate()
            smoke.width = data.get("width", 250.0)
            smoke.height = data.get("height", 300.0)
            smoke.opacity = data.get("opacity", 0.6)
            return smoke

        "shockwave":
            var shockwave = preload("res://scenes/obstacles/shockwave.tscn").instantiate()
            shockwave.core_radius = data.get("core_radius", 20.0)
            shockwave.shockwave_max_radius = data.get("shockwave_max_radius", 100.0)
            shockwave.shockwave_interval = data.get("shockwave_interval", 2.0)
            shockwave.shockwave_duration = data.get("shockwave_duration", 1.0)
            return shockwave

        _:
            push_warning("Unknown obstacle type: " + obs_type)
            return null

func _spawn_collectibles() -> void:
    for col_data in segment_data.collectibles:
        var collectible = _create_collectible(col_data)
        if collectible:
            collectibles_container.add_child(collectible)
            # Convert positive Y (distance into segment) to negative Y (upward direction)
            var pos = col_data.position
            collectible.position = Vector2(pos.x, -pos.y)

func _create_collectible(data: Dictionary) -> Node2D:
    var col_type = data.get("type", "orb")

    match col_type:
        "orb":
            var orb = preload("res://scenes/collectibles/orb.tscn").instantiate()
            orb.point_value = data.get("value", 10)
            return orb

        "star":
            var star = preload("res://scenes/collectibles/star.tscn").instantiate()
            star.invincibility_duration = data.get("duration", 5.0)
            return star

        "magnet":
            var magnet = preload("res://scenes/collectibles/magnet.tscn").instantiate()
            magnet.magnet_duration = data.get("duration", 5.0)
            return magnet

        "stopwatch":
            var stopwatch = preload("res://scenes/collectibles/stopwatch.tscn").instantiate()
            stopwatch.slow_duration = data.get("duration", 5.0)
            stopwatch.slow_factor = data.get("slow_factor", 0.5)
            return stopwatch

        "multiplier":
            var multiplier = preload("res://scenes/collectibles/multiplier.tscn").instantiate()
            multiplier.multiplier_duration = data.get("duration", 5.0)
            return multiplier

        "hourglass":
            # Only spawn hourglass in DAILY_CHALLENGE or RUSH mode
            if GameManager.current_game_mode == GameManager.GameMode.DAILY_CHALLENGE or \
               GameManager.current_game_mode == GameManager.GameMode.RUSH:
                var hourglass = preload("res://scenes/collectibles/hourglass.tscn").instantiate()
                hourglass.time_bonus = data.get("time_bonus", 10.0)
                return hourglass
            else:
                # Replace with orb in other game modes
                var orb = preload("res://scenes/collectibles/orb.tscn").instantiate()
                orb.point_value = data.get("value", 20)  # Higher value to compensate
                return orb

#        "speed_boost":
#            var boost = preload("res://scenes/collectibles/speed_boost.tscn").instantiate()
#            boost.boost_duration = data.get("duration", 3.0)
#            return boost

        _:
            push_warning("Unknown collectible type: " + col_type)
            return null

func _setup_walls() -> void:
    # Clear existing walls
    for child in walls_container.get_children():
        child.queue_free()

    var half_width = segment_data.tunnel_width / 2.0  # Always 125.0
    var length = segment_data.segment_length
    var wall_thickness = 16.0

    # Check if this is a curved segment
    if abs(segment_data.curvature) < 0.1:
        # Straight tunnel - use simple line
        _create_wall_with_collision(Vector2(-half_width, 0), Vector2(-half_width, -length), wall_thickness)
        _create_wall_with_collision(Vector2(half_width, 0), Vector2(half_width, -length), wall_thickness)
    else:
        # Curved tunnel - use smooth curve
        _create_curved_walls(half_width, length, segment_data.curvature, wall_thickness)

func _create_curved_walls(half_width: float, length: float, curvature_degrees: float, thickness: float) -> void:
    # Generate smooth curved walls using a sine-based curve
    # Negative curvature = curve left, positive = curve right

    var num_points = max(int(length / 20.0), 10)  # Point every ~20px, minimum 10 points
    var left_points: PackedVector2Array = []
    var right_points: PackedVector2Array = []

    # Calculate curve intensity based on curvature
    # Use sine wave for smooth S-curve effect
    var curve_intensity = curvature_degrees / 60.0  # Normalize to -1 to 1 range

    for i in range(num_points + 1):
        var t = float(i) / float(num_points)
        var y = -length * t  # Negative Y = upward

        # Smooth curve using sine wave
        # sin(t * PI) creates a smooth bulge from 0 to 1 (starts at 0, peaks at 0.5, ends at 0)
        var curve_offset = sin(t * PI) * half_width * 0.4 * curve_intensity

        left_points.append(Vector2(-half_width + curve_offset, y))
        right_points.append(Vector2(half_width + curve_offset, y))

    # Create curved walls with Line2D and collision
    _create_curved_wall_line(left_points, thickness)
    _create_curved_wall_line(right_points, thickness)

func _create_curved_wall_line(points: PackedVector2Array, thickness: float) -> void:
    # Create visual curved wall using Line2D
    var wall_visual = Line2D.new()
    for point in points:
        wall_visual.add_point(point)

    wall_visual.width = thickness
    wall_visual.default_color = Color(0.4, 0.7, 1.0, 0.8)
    wall_visual.begin_cap_mode = Line2D.LINE_CAP_NONE  # No cap at segment boundary
    wall_visual.end_cap_mode = Line2D.LINE_CAP_BOX     # Cap at far end
    wall_visual.joint_mode = Line2D.LINE_JOINT_ROUND   # Smooth joints for curves
    wall_visual.antialiased = true

    walls_container.add_child(wall_visual)

    # Create collision along the curved path
    # Use multiple small segments for accurate collision
    var num_collision_segments = max(int(points.size() / 3), 3)  # Fewer collision segments than visual points

    for i in range(num_collision_segments):
        var segment_start_idx = int(float(i) / float(num_collision_segments) * (points.size() - 1))
        var segment_end_idx = int(float(i + 1) / float(num_collision_segments) * (points.size() - 1))

        var start_pos = points[segment_start_idx]
        var end_pos = points[segment_end_idx]

        # Create StaticBody2D for this segment
        var wall_collision = StaticBody2D.new()
        var collision_shape = CollisionShape2D.new()
        var shape = RectangleShape2D.new()

        # Calculate segment dimensions and position
        var segment_length = start_pos.distance_to(end_pos)
        var segment_angle = start_pos.angle_to_point(end_pos)

        shape.size = Vector2(thickness, segment_length)

        # Position at midpoint and rotate to match segment direction
        var midpoint = (start_pos + end_pos) / 2.0
        wall_collision.position = midpoint
        wall_collision.rotation = segment_angle + PI / 2.0  # Rotate to align with segment

        collision_shape.shape = shape
        wall_collision.add_child(collision_shape)

        # Set collision layers: walls on layer 8
        wall_collision.collision_layer = 8
        wall_collision.collision_mask = 0  # Walls don't detect anything, just block

        walls_container.add_child(wall_collision)

func _create_wall_with_collision(start_pos: Vector2, end_pos: Vector2, thickness: float) -> void:
    # Create visual wall (Line2D)
    var wall_visual = Line2D.new()
    wall_visual.add_point(start_pos)
    wall_visual.add_point(end_pos)
    wall_visual.width = thickness
    wall_visual.default_color = Color(0.4, 0.7, 1.0, 0.8)
    wall_visual.begin_cap_mode = Line2D.LINE_CAP_NONE  # No cap at segment boundary (y=0)
    wall_visual.end_cap_mode = Line2D.LINE_CAP_BOX  # Cap at far end (y=-length)

    # Create collision (StaticBody2D with rectangular shape)
    var wall_collision = StaticBody2D.new()
    var collision_shape = CollisionShape2D.new()
    var shape = RectangleShape2D.new()

    # Calculate rectangle dimensions and position
    var wall_length = start_pos.distance_to(end_pos)
    shape.size = Vector2(thickness, wall_length)

    # Position collision at midpoint of the wall
    var midpoint = (start_pos + end_pos) / 2.0
    wall_collision.position = midpoint

    collision_shape.shape = shape
    wall_collision.add_child(collision_shape)

    # Set collision layers: walls on layer 8
    wall_collision.collision_layer = 8
    wall_collision.collision_mask = 0  # Walls don't detect anything, just block

    walls_container.add_child(wall_visual)
    walls_container.add_child(wall_collision)

func _setup_background() -> void:
    # Simple grid background for MVP
    # Could be enhanced with shaders later
    pass

func _process(delta: float) -> void:
    if is_active:
        _update_animations(delta)

func _update_animations(_delta: float) -> void:
    # Update any animated elements
    for child in obstacles_container.get_children():
        if child.has_method("update_obstacle"):
            child.update_obstacle(_delta)

func deactivate() -> void:
    is_active = false
    # Don't queue_free here if using pooling
