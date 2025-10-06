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
            obstacle.position = obs_data.position

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

        _:
            push_warning("Unknown obstacle type: " + obs_type)
            return null

func _spawn_collectibles() -> void:
    for col_data in segment_data.collectibles:
        var collectible = _create_collectible(col_data)
        if collectible:
            collectibles_container.add_child(collectible)
            collectible.position = col_data.position

func _create_collectible(data: Dictionary) -> Node2D:
    var col_type = data.get("type", "orb")

    match col_type:
        "orb":
            var orb = preload("res://scenes/collectibles/orb.tscn").instantiate()
            orb.point_value = data.get("value", 10)
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

    # All tunnels are now 250px wide, so walls are at fixed positions
    var wall_line_position = half_width
    var wall_thickness = 8.0

    # Create left wall with collision
    _create_wall_with_collision(Vector2(-wall_line_position, 0), Vector2(-wall_line_position, -length), wall_thickness)

    # Create right wall with collision
    _create_wall_with_collision(Vector2(wall_line_position, 0), Vector2(wall_line_position, -length), wall_thickness)

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
