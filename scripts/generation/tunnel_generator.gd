class_name TunnelGenerator
extends Node

# Signals
signal segment_spawned(segment: BaseSegment)
signal segment_despawned(segment: BaseSegment)

# Configuration
@export var segments_ahead: int = 4
@export var segments_behind: int = 2  # Keep 2 behind (plus starting segment)
@export var use_pooling: bool = true
@export var pool_size: int = 10

# State
var active_segments: Array[BaseSegment] = []
var starting_segment: StartingSegment = null  # Special starting segment (never despawns)
var segment_pool: Array[BaseSegment] = []
var current_difficulty: float = 0.0
var segments_generated: int = 0
var last_segment_y: float = 0.0

# Library & RNG
var segment_library: SegmentLibrary
var rng: RandomNumberGenerator

# Segment tracking for rules
var recent_segment_types: Array[String] = []
var segments_since_straight: int = 0
var segments_since_fork: int = 0

func _ready() -> void:
    segment_library = SegmentLibrary.new()
    rng = RandomNumberGenerator.new()

func initialize(seed_value: int = -1) -> void:
    if seed_value == -1:
        rng.seed = GameManager.daily_seed
    else:
        rng.seed = seed_value

    segments_generated = 0
    current_difficulty = 0.0
    last_segment_y = 0.0
    recent_segment_types.clear()
    segments_since_straight = 0
    segments_since_fork = 0

    _clear_segments()
    _initialize_pool()
    _generate_initial_segments()

    print("Tunnel Generator initialized with seed: %d" % rng.seed)

func _initialize_pool() -> void:
    if not use_pooling:
        return

    segment_pool.clear()
    for i in pool_size:
        var segment = _create_segment_instance()
        get_parent().add_child(segment)
        segment.visible = false
        segment.process_mode = Node.PROCESS_MODE_DISABLED
        segment_pool.append(segment)

func _generate_initial_segments() -> void:
    # First, create the starting segment at position 0
    _create_starting_segment()

    # Then spawn regular segments ahead
    for i in range(segments_ahead + 2):
        _spawn_next_segment()

func _create_starting_segment() -> void:
    # Create the permanent starting segment
    var start_segment_scene = preload("res://scenes/segments/base_segment.tscn")
    starting_segment = StartingSegment.new()

    # Copy structure from base segment
    var temp_segment = start_segment_scene.instantiate()
    get_parent().add_child(temp_segment)

    # Setup the starting segment structure
    starting_segment.obstacles_container = Node2D.new()
    starting_segment.collectibles_container = Node2D.new()
    starting_segment.walls_container = Node2D.new()
    starting_segment.background = Node2D.new()

    get_parent().add_child(starting_segment)
    starting_segment.add_child(starting_segment.obstacles_container)
    starting_segment.add_child(starting_segment.collectibles_container)
    starting_segment.add_child(starting_segment.walls_container)
    starting_segment.add_child(starting_segment.background)

    # Clean up temp
    temp_segment.queue_free()

    # Initialize at position 0
    starting_segment.position = Vector2(0, 0)
    starting_segment.initialize_starting_segment(250.0, 600.0)

    print("Starting segment created at position 0")

func update_generation(player_y: float) -> void:
    # Spawn new segments ahead
    while _should_spawn_segment(player_y):
        _spawn_next_segment()

    # Despawn old segments behind
    _despawn_old_segments(player_y)

    # Update difficulty
    _update_difficulty()

func _should_spawn_segment(player_y: float) -> bool:
    if active_segments.is_empty():
        return true

    var spawn_distance = segments_ahead * 800.0  # Average segment length
    # Changed: spawn ahead (negative Y direction = upward)
    return last_segment_y > player_y - spawn_distance

func _spawn_next_segment() -> BaseSegment:
    # Get valid segment options
    var valid_segments := _get_valid_segments()

    if valid_segments.is_empty():
        push_warning("No valid segments available!")
        valid_segments = [segment_library.get_fallback_segment()]

    # Choose segment
    var chosen_data := _weighted_random_segment(valid_segments)

    # Apply procedural variation
    chosen_data = _apply_variation(chosen_data)

    # Get or create segment instance
    var segment: BaseSegment = _acquire_segment()

    # Position segment (spawn upward = negative Y)
    var spawn_y = last_segment_y

    segment.position = Vector2(0, spawn_y)
    segment.initialize(chosen_data, segments_generated)
    segment.visible = true
    segment.process_mode = Node.PROCESS_MODE_INHERIT

    # Update state
    active_segments.append(segment)
    # Changed: subtract segment length (moving upward = negative Y)
    last_segment_y = spawn_y - chosen_data.segment_length
    segments_generated += 1

    # Track for generation rules
    recent_segment_types.append(chosen_data.segment_type)
    if recent_segment_types.size() > 5:
        recent_segment_types.pop_front()

    if abs(chosen_data.curvature) < 5.0:
        segments_since_straight = 0
    else:
        segments_since_straight += 1

    segments_since_fork += 1

    segment_spawned.emit(segment)
    return segment

func _get_valid_segments() -> Array[SegmentData]:
    # Get segments appropriate for current difficulty
    var candidates = segment_library.get_segments_by_difficulty(current_difficulty)
    var valid: Array[SegmentData] = []
    
    print(candidates[0].complexity)

    for seg_data in candidates:
        if _validate_segment_rules(seg_data):
            valid.append(seg_data)

    return valid

func _validate_segment_rules(seg_data: SegmentData) -> bool:
    # Rule 1: No more than 2 sharp turns in a row
    if abs(seg_data.curvature) > 45:
        var sharp_count = 0
        for i in range(max(0, recent_segment_types.size() - 2), recent_segment_types.size()):
            # We'd need to store curvature info, simplified for now
            if recent_segment_types[i] == "curve":
                sharp_count += 1

        if sharp_count >= 2:
            push_warning("No more than 2 sharp turns in a row")
            return false

    # Rule 2: Must have straight segment every 5-6 segments
    if segments_since_straight >= 5:
        # Only allow straight segments
        if abs(seg_data.curvature) > 5.0:
            push_warning("Must have straight segment every 5-6 segments")
        return abs(seg_data.curvature) < 5.0

    # Rule 3: Limit consecutive similar types
#    if recent_segment_types.size() >= 3:
#        var last_three = recent_segment_types.slice(recent_segment_types.size() - 3)
#        if last_three[0] == seg_data.segment_type and \
#        last_three[1] == seg_data.segment_type and \
#        last_three[2] == seg_data.segment_type:
#            push_warning("Limit consecutive similar types")
#            return false  # Don't allow 4 in a row

    # Rule 4: Early game should be easier
    if segments_generated < 5:
        if seg_data.complexity >= 1:
            push_warning("Early game should be easier")
        return seg_data.complexity <= 1

    return true

func _weighted_random_segment(segments: Array[SegmentData]) -> SegmentData:
    if segments.is_empty():
        return segment_library.get_fallback_segment()

    # Calculate weights based on difficulty match
    var weights: Array[float] = []
    var total_weight: float = 0.0

    for seg in segments:
        # Calculate how well this segment matches current difficulty
        var seg_mid_difficulty = (seg.min_difficulty + seg.max_difficulty) / 2.0
        var diff_distance = abs(seg_mid_difficulty - current_difficulty)

        # Weight decreases with distance from ideal difficulty
        var weight = 1.0 / (1.0 + diff_distance * 0.5)

        # Boost weight for variety (penalize recently used types)
        if not seg.segment_type in recent_segment_types:
            weight *= 1.5

        weights.append(weight)
        total_weight += weight

    # Weighted random selection
    var rand_value = rng.randf() * total_weight
    var cumulative = 0.0

    for i in segments.size():
        cumulative += weights[i]
        if rand_value <= cumulative:
            return segments[i]

    # Fallback (shouldn't reach here)
    return segments[-1]

func _apply_variation(data: SegmentData) -> SegmentData:
    # Clone to avoid modifying original
    var varied = data.duplicate_deep()

    # Use consistent tunnel width across all segments
    varied.tunnel_width = 250.0

    # Randomize obstacle positions slightly
    for obs in varied.obstacles:
        if obs.has("position"):
            var pos: Vector2 = obs.position
            pos.x += rng.randf_range(-20, 20)  # Left/right variance
            pos.y += rng.randf_range(-30, 30)  # Forward/back variance
            # Keep within bounds (X is left/right)
            pos.x = clamp(pos.x, -varied.tunnel_width/2 + 40, varied.tunnel_width/2 - 40)
            obs.position = pos

    # Randomize collectible positions
    for col in varied.collectibles:
        if col.has("position"):
            var pos: Vector2 = col.position
            pos.x += rng.randf_range(-15, 15)  # Left/right variance
            pos.y += rng.randf_range(-20, 20)  # Forward/back variance
            col.position = pos

    # Add extra obstacles at higher difficulty
    if current_difficulty > 5.0 and rng.randf() < 0.3:  # 30% chance
        _add_random_obstacle(varied)

    # Add extra collectibles randomly
    if rng.randf() < 0.2:  # 20% chance
        _add_random_collectible(varied)

    return varied

func _add_random_obstacle(data: SegmentData) -> void:
    var obstacle_types = ["pillar"]
    if current_difficulty > 4.0:
        obstacle_types.append("pulse_gate")

    var obs_type = obstacle_types[rng.randi_range(0, obstacle_types.size() - 1)]

    var new_obstacle = {
                           "type": obs_type,
                           "position": Vector2(
                               rng.randf_range(-data.tunnel_width/2 + 50, data.tunnel_width/2 - 50),
                               rng.randf_range(200, data.segment_length - 200)
                           )
                       }

    if obs_type == "pillar":
        new_obstacle["radius"] = rng.randf_range(25.0, 35.0)
    elif obs_type == "pulse_gate":
        new_obstacle["rotation_speed"] = rng.randf_range(0.6, 1.2)

    data.obstacles.append(new_obstacle)

func _add_random_collectible(data: SegmentData) -> void:
    var col_type = "orb"
    if current_difficulty > 6.0 and rng.randf() < 0.15:  # Rare speed boosts
        col_type = "speed_boost"

    var new_collectible = {
                              "type": col_type,
                              "position": Vector2(
                                  rng.randf_range(-data.tunnel_width/2 + 30, data.tunnel_width/2 - 30),
                                  rng.randf_range(150, data.segment_length - 150)
                              )
                          }

    if col_type == "orb":
        new_collectible["value"] = 10 if rng.randf() < 0.8 else 20  # 80% normal, 20% bonus

    data.collectibles.append(new_collectible)

func _despawn_old_segments(player_y: float) -> void:
    var despawn_distance = segments_behind * 800.0

    # Keep at least segments_behind number of segments
    while active_segments.size() > segments_behind:
        var first_segment = active_segments[0]
        # Changed: segment end is now in negative direction (upward = negative Y)
        var segment_end_y = first_segment.position.y - first_segment.segment_data.segment_length

        # Changed: despawn segments that are below (positive Y direction = downward/behind)
        if segment_end_y > player_y + despawn_distance:
            # Remember the position of the despawned segment
            var despawned_position = first_segment.position.y

            active_segments.pop_front()
            segment_despawned.emit(first_segment)
            _release_segment(first_segment)

            # Move starting segment to replace the despawned segment's position
            if starting_segment:
                starting_segment.position.y = despawned_position
        else:
            break  # All remaining segments are still in range

func _update_difficulty() -> void:
    # Difficulty ramps up over time
    var time_factor = GameManager.game_time / 60.0  # 0 to ~1 over first minute
    var speed_factor = (GameManager.current_speed - GameManager.base_speed) / \
                      (GameManager.max_speed - GameManager.base_speed)

    # Combine factors
    var base_difficulty = (time_factor * 4.0) + (speed_factor * 6.0)

    # Add some randomness for variety
    var variation = rng.randf_range(-0.5, 0.5)

    current_difficulty = clamp(base_difficulty + variation, 0.0, 10.0)

# ===== OBJECT POOLING =====

func _acquire_segment() -> BaseSegment:
    if use_pooling and not segment_pool.is_empty():
        return segment_pool.pop_back()
    else:
        var segment = _create_segment_instance()
        get_parent().add_child(segment)
        return segment

func _release_segment(segment: BaseSegment) -> void:
    segment.deactivate()

    if use_pooling and segment_pool.size() < pool_size:
        segment.visible = false
        segment.process_mode = Node.PROCESS_MODE_DISABLED
        segment_pool.append(segment)
    else:
        segment.queue_free()

func _create_segment_instance() -> BaseSegment:
    var segment_scene = preload("res://scenes/segments/base_segment.tscn")
    return segment_scene.instantiate()

# ===== CLEANUP =====

func _clear_segments() -> void:
    for segment in active_segments:
        segment.queue_free()
    active_segments.clear()

    # Also clear starting segment
    if starting_segment:
        starting_segment.queue_free()
        starting_segment = null

    last_segment_y = 0.0

func cleanup() -> void:
    _clear_segments()
    for segment in segment_pool:
        segment.queue_free()
    segment_pool.clear()
