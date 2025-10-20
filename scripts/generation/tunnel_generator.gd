class_name TunnelGenerator
extends Node

# Signals
signal segment_spawned(segment: BaseSegment)
signal segment_despawned(segment: BaseSegment)
# Configuration
@export var segments_ahead: int = 4
@export var segments_behind: int = 2  # Keep 2 behind (plus starting segment)
@export var use_pooling: bool = true
@export var pool_size: int = 15  # Increased from 10 for buffer

# State
var active_segments: Array[BaseSegment] = []
var starting_segment: StartingSegment   = null  # Special starting segment (never despawns)
var end_segment: EndSegment             = null  # Special ending segment for daily challenge
var segment_pool: Array[BaseSegment]    = []
var current_difficulty: float           = 0.0
var segments_generated: int             = 0
var last_segment_y: float               = 0.0
var max_segments: int                   = -1  # -1 = infinite (classic mode), positive = fixed count (daily challenge)
var is_seeded_mode: bool                = false  # True for DAILY_CHALLENGE and RUSH (deterministic generation)
# Library & RNG
var segment_library: SegmentLibrary
var rng: RandomNumberGenerator
# Segment tracking for rules
var recent_segments: Array[SegmentData] = []  # Store full data instead of just types
var segments_since_straight: int        = 0
var segments_since_fork: int            = 0
var has_spike_corridor: bool            = false  # Track if spike corridor has been generated (for seeded modes)


func _ready() -> void:
    segment_library = SegmentLibrary.new()
    rng = RandomNumberGenerator.new()


func initialize(seed_value: int = -1, is_daily_challenge: bool = false, is_rush: bool = false) -> void:
    if seed_value == -1:
        rng.seed = GameManager.daily_seed
    else:
        rng.seed = seed_value

    segments_generated = 0
    current_difficulty = 0.0
    last_segment_y = 0.0
    recent_segments.clear()
    segments_since_straight = 0
    segments_since_fork = 0
    has_spike_corridor = false

    # Set max segments for limited modes (daily challenge and rush)
    if is_daily_challenge or GameManager.current_game_mode == GameManager.GameMode.DAILY_CHALLENGE:
        max_segments = 10  # 10 middle segments (plus start and end)
        is_seeded_mode = true  # Enable deterministic generation
    elif is_rush or GameManager.current_game_mode == GameManager.GameMode.RUSH:
        max_segments = 15  # 15 middle segments (plus start and end) for RUSH mode
        is_seeded_mode = true  # Enable deterministic generation
    else:
        max_segments = -1  # Infinite generation for classic mode
        is_seeded_mode = false  # Classic mode can have random variation

    _clear_segments()
    _initialize_pool()
    _generate_initial_segments()

    print("Tunnel Generator initialized with seed: %d, max_segments: %d, seeded_mode: %s" % [rng.seed, max_segments, is_seeded_mode])


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

    # Initialize last_segment_y to the top of the starting segment
    # Starting segment is 600px long at Y=0, so its top is at Y=-600
    last_segment_y = -600.0

    # Then spawn regular segments ahead
    for i in range(segments_ahead + 2):
        _spawn_next_segment()


func _create_starting_segment() -> void:
    # Create the permanent starting segment using the scene directly
    var start_segment_scene = preload("res://scenes/segments/starting_segment.tscn")
    starting_segment = start_segment_scene.instantiate()
    get_parent().add_child(starting_segment)

    # Initialize at position 0
    starting_segment.position = Vector2(0, 0)
    starting_segment.initialize_starting_segment(300.0, 600.0)

    print("Starting segment created at position 0")


func _spawn_end_segment() -> void:
    # Create the ending segment for daily challenge using the scene directly
    var end_segment_scene = preload("res://scenes/segments/end_segment.tscn")
    end_segment = end_segment_scene.instantiate()
    get_parent().add_child(end_segment)

    # Position at the end of the last spawned segment
    var spawn_y = last_segment_y
    end_segment.position = Vector2(0, spawn_y)
    end_segment.initialize_end_segment(300.0, 600.0)

    # Update tracking
    last_segment_y = spawn_y - 600.0  # End segment length

    print("End segment created at position: ", spawn_y)


func update_generation(player_y: float) -> void:
    # Spawn new segments ahead
    while _should_spawn_segment(player_y):
        _spawn_next_segment()

    # Despawn old segments behind
    _despawn_old_segments(player_y)

    # Update difficulty
    _update_difficulty()


func _should_spawn_segment(player_y: float) -> bool:
    # Check if we've reached max segments for daily challenge
    if max_segments > 0 and segments_generated >= max_segments:
        # Stop spawning if we've reached the limit and haven't placed end segment yet
        if not end_segment:
            _spawn_end_segment()
        return false

    if active_segments.is_empty():
        return true

    var spawn_distance = _calculate_lookahead_distance()
    # Changed: spawn ahead (negative Y direction = upward)
    return last_segment_y > player_y - spawn_distance


func _calculate_lookahead_distance() -> float:
    # Base on actual active segment lengths for more accurate spawning
    if active_segments.is_empty():
        return segments_ahead * 800.0  # Default fallback

    var total_length = 0.0
    for seg in active_segments:
        if seg.segment_data:
            total_length += seg.segment_data.segment_length

    var avg_length = total_length / active_segments.size()
    return segments_ahead * avg_length


func _calculate_despawn_distance() -> float:
    # Base on actual active segment lengths for more accurate despawning
    if active_segments.is_empty():
        return segments_behind * 800.0  # Default fallback

    var total_length = 0.0
    for seg in active_segments:
        if seg.segment_data:
            total_length += seg.segment_data.segment_length

    var avg_length = total_length / active_segments.size()
    return segments_behind * avg_length


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
    recent_segments.append(chosen_data)
    if recent_segments.size() > 5:
        recent_segments.pop_front()

    if abs(chosen_data.curvature) < 5.0:
        segments_since_straight = 0
    else:
        segments_since_straight += 1

    segments_since_fork += 1

    # Track if spike corridor has been generated (for seeded modes)
    if chosen_data.segment_id == "spike_corridor":
        has_spike_corridor = true

    segment_spawned.emit(segment)
    return segment


func _get_valid_segments() -> Array[SegmentData]:
    # In seeded modes, use all segments regardless of difficulty (just filter by complexity)
    # In classic mode, use difficulty-appropriate segments
    var candidates: Array
    if is_seeded_mode:
        candidates = segment_library.all_segments
    else:
        candidates = segment_library.get_segments_by_difficulty(current_difficulty)

    var valid: Array[SegmentData] = []

    for seg_data in candidates:
        # Filter out complexity 0-1 segments in seeded modes (DAILY_CHALLENGE and RUSH)
        if is_seeded_mode and seg_data.complexity <= 1:
            continue

        if _validate_segment_rules(seg_data):
            valid.append(seg_data)

    return valid


func _validate_segment_rules(seg_data: SegmentData) -> bool:
    # Seeded mode rule: Force spike corridor if not yet generated and approaching midpoint
    if is_seeded_mode and not has_spike_corridor:
        # Force spike corridor around the middle of the run (segment 5-7 for daily, 7-10 for rush)
        var force_spike_at = 6 if max_segments == 10 else 9  # Middle segment
        if segments_generated == force_spike_at:
            # Only accept spike corridor at this point
            return seg_data.segment_id == "spike_corridor"
        elif segments_generated > force_spike_at:
            # Fallback: if we missed forcing it, strongly prefer it now
            if seg_data.segment_id == "spike_corridor":
                return true  # Always accept spike corridor if we haven't had one yet

    # Rule 1: No more than 2 sharp turns in a row
    if abs(seg_data.curvature) > 45:
        var sharp_count = 0
        # Check last 2 segments for sharp turns
        for recent in recent_segments:
            if abs(recent.curvature) > 45:
                sharp_count += 1

        if sharp_count >= 2:
            return false  # Already have 2 sharp turns, don't add another

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

    # Rule 4: Early game should be easier (disabled in seeded modes since we filter complexity 0-1)
    if not is_seeded_mode and segments_generated < 5:
        if seg_data.complexity >= 1:
            push_warning("Early game should be easier")
        return seg_data.complexity <= 1

    return true


func _weighted_random_segment(segments: Array[SegmentData]) -> SegmentData:
    if segments.is_empty():
        return segment_library.get_fallback_segment()

    # Calculate weights based on difficulty match
    var weights: Array[float] = []
    var total_weight: float   = 0.0

    for seg in segments:
        var weight = 1.0

        # In seeded modes, ignore difficulty matching (all complexities are equally valid)
        # In classic mode, weight by difficulty match
        if not is_seeded_mode:
            # Calculate how well this segment matches current difficulty
            var seg_mid_difficulty = (seg.min_difficulty + seg.max_difficulty) / 2.0
            var diff_distance      = abs(seg_mid_difficulty - current_difficulty)
            # Weight decreases with distance from ideal difficulty
            weight = 1.0 / (1.0 + diff_distance * 0.5)

        # Apply variety penalty/bonus based on recent usage
        var times_used = 0
        for recent in recent_segments:
            if recent.segment_id == seg.segment_id:
                times_used += 1

        if times_used == 0:
            # Big bonus for segments not used recently
            weight *= 2.0
        else:
            # Exponential penalty for repeated segments
            # 1 use = 0.5x, 2 uses = 0.25x, 3 uses = 0.125x, etc.
            weight *= pow(0.5, times_used)

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
    var varied = data._duplicate_deep()

    # Use consistent tunnel width across all segments
    varied.tunnel_width = 300.0

    # Skip random variation in seeded modes (DAILY_CHALLENGE and RUSH)
    # This ensures deterministic, reproducible tunnel layouts
    if is_seeded_mode:
        return varied

    # Scale variation with difficulty (1.0x to 1.5x)
    var variance_scale = 1.0 + (current_difficulty / 10.0) * 0.5

    # Randomize obstacle positions (but not precision obstacles)
    var precision_obstacles = ["smoke_screen", "pulsing_wall", "shockwave"]
    for obs in varied.obstacles:
        if obs.has("position") and not obs.get("type") in precision_obstacles:
            var pos: Vector2 = obs.position
            # Increased variance with difficulty scaling
            pos.x += rng.randf_range(-30, 30) * variance_scale  # Up from ±20
            pos.y += rng.randf_range(-50, 50) * variance_scale  # Up from ±30
            # Keep within bounds
            pos.x = clamp(pos.x, -varied.tunnel_width/2 + 40, varied.tunnel_width/2 - 40)
            obs.position = pos

    # Randomize collectible positions
    for col in varied.collectibles:
        if col.has("position"):
            var pos: Vector2 = col.position
            pos.x += rng.randf_range(-20, 20) * variance_scale  # Up from ±15
            pos.y += rng.randf_range(-30, 30) * variance_scale  # Up from ±20
            col.position = pos

    # Add extra obstacles at higher difficulty (increased from 30% to 50%)
    if current_difficulty > 5.0 and rng.randf() < 0.5:
        _add_random_obstacle(varied)

    # Add extra collectibles randomly (increased from 20% to 35%)
    if rng.randf() < 0.35:
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
    if current_difficulty > 6.0 and rng.randf() < 0.15: # Rare speed boosts
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
    # Calculate adaptive despawn distance based on actual segment lengths
    var despawn_distance = _calculate_despawn_distance()

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

            # Move starting segment to follow behind player
            # This keeps the player from seeing empty space behind them
            if starting_segment:
                starting_segment.position.y = despawned_position
        else:
            break  # All remaining segments are still in range


func _update_difficulty() -> void:
    # Use GameManager's difficulty directly for consistency
    var base_difficulty = GameManager.get_difficulty()

    # Add some randomness for variety (but not in seeded modes)
    var variation = 0.0
    if not is_seeded_mode:
        variation = rng.randf_range(-0.5, 0.5)

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

    # Also clear ending segment
    if end_segment:
        end_segment.queue_free()
        end_segment = null

    last_segment_y = 0.0


func cleanup() -> void:
    _clear_segments()
    for segment in segment_pool:
        segment.queue_free()
    segment_pool.clear()
