class_name SegmentLibrary
extends RefCounted

var all_segments: Array[SegmentData] = []
var segments_by_type: Dictionary = {}
var segments_by_difficulty: Dictionary = {}

func _init() -> void:
    _create_segments()
    _index_segments()

func _create_segments() -> void:
    # Basic segments
    all_segments.append(_create_straight_empty())
    all_segments.append(_create_shockwave_zone())
    all_segments.append(_create_fog_zone())
    all_segments.append(_create_spike_corridor())
    all_segments.append(_create_split_path())
    all_segments.append(_create_simple_static_wall())
    all_segments.append(_create_straight_single_pillar())
    all_segments.append(_create_straight_double_pillar())
    all_segments.append(_create_straight_gate())

    # Curve segments
    all_segments.append(_create_gentle_left())
    all_segments.append(_create_gentle_right())
    all_segments.append(_create_sharp_left())
    all_segments.append(_create_sharp_right())

    # Complex segments
    all_segments.append(_create_s_curve())
    all_segments.append(_create_slalom())
    all_segments.append(_create_narrow_passage())
    all_segments.append(_create_wall_gauntlet())
    all_segments.append(_create_pulse_timing())

    print("Loaded %d segment templates" % all_segments.size())

# ===== BASIC STRAIGHT SEGMENTS =====

func _create_straight_empty() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "straight_empty"
    seg.segment_type = "straight"
    seg.segment_length = 600.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 2
    seg.complexity = 0

    # Just collectibles, no obstacles
    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 300), "value": 10},
        {"type": "magnet", "position": Vector2(0, 450), "duration": 5.0},
        {"type": "stopwatch", "position": Vector2(0, 150), "duration": 5.0, "slow_factor": 0.5}
    ] as Array[Dictionary]

    return seg

func _create_straight_single_pillar() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "straight_single_pillar"
    seg.segment_type = "straight"
    seg.segment_length = 700.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 1
    seg.max_difficulty = 8
    seg.complexity = 1

    seg.obstacles = [
        {"type": "pillar", "position": Vector2(0, 350), "radius": 30.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(40, 200), "value": 10},
        {"type": "orb", "position": Vector2(-40, 200), "value": 10},
        {"type": "orb", "position": Vector2(0, 500), "value": 10}
    ] as Array[Dictionary]

    return seg

func _create_straight_double_pillar() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "straight_double_pillar"
    seg.segment_type = "straight"
    seg.segment_length = 800.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 2
    seg.max_difficulty = 10
    seg.complexity = 2

    seg.obstacles = [
        {"type": "pillar", "position": Vector2(50, 300), "radius": 30.0},
        {"type": "pillar", "position": Vector2(-50, 500), "radius": 30.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-60, 300), "value": 10},
        {"type": "orb", "position": Vector2(60, 500), "value": 10}
    ] as Array[Dictionary]

    return seg

func _create_straight_gate() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "straight_gate"
    seg.segment_type = "straight"
    seg.segment_length = 700.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 3
    seg.max_difficulty = 10
    seg.complexity = 2

    seg.obstacles = [
        {"type": "pulse_gate", "position": Vector2(0, 400), "rotation_speed": 0.2}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 200), "value": 10},
        {"type": "orb", "position": Vector2(0, 600), "value": 20}  # Bonus after gate
    ] as Array[Dictionary]

    return seg

func _create_shockwave_zone() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "shockwave_zone"
    seg.segment_type = "straight"
    seg.segment_length = 800.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 10
    seg.complexity = 0

    seg.obstacles = [
        {"type": "shockwave", "position": Vector2(0, 400), "core_radius": 20.0, "shockwave_max_radius": 50.0, "shockwave_interval": 2.0, "shockwave_duration": 1.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(60, 250), "value": 10},
        {"type": "orb", "position": Vector2(-60, 250), "value": 10},
        {"type": "orb", "position": Vector2(70, 550), "value": 10},
        {"type": "orb", "position": Vector2(-70, 550), "value": 10}
    ] as Array[Dictionary]

    return seg

# ===== CURVE SEGMENTS =====

func _create_gentle_left() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "gentle_left"
    seg.segment_type = "curve"
    seg.segment_length = 800.0
    seg.tunnel_width = 250.0
    seg.curvature = -25.0
    seg.curve_type = "gentle"
    seg.min_difficulty = 1
    seg.max_difficulty = 7
    seg.complexity = 1

    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-40, 400), "radius": 30.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(40, 300), "value": 10},
        {"type": "orb", "position": Vector2(40, 500), "value": 10}
    ] as Array[Dictionary]

    return seg

func _create_gentle_right() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "gentle_right"
    seg.segment_type = "curve"
    seg.segment_length = 800.0
    seg.tunnel_width = 250.0
    seg.curvature = 25.0
    seg.curve_type = "gentle"
    seg.min_difficulty = 1
    seg.max_difficulty = 7
    seg.complexity = 1

    seg.obstacles = [
        {"type": "pillar", "position": Vector2(40, 400), "radius": 30.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-40, 300), "value": 10},
        {"type": "orb", "position": Vector2(-40, 500), "value": 10}
    ] as Array[Dictionary]

    return seg

func _create_sharp_left() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "sharp_left"
    seg.segment_type = "curve"
    seg.segment_length = 600.0
    seg.tunnel_width = 250.0
    seg.curvature = -60.0
    seg.curve_type = "sharp"
    seg.min_difficulty = 4
    seg.max_difficulty = 10
    seg.complexity = 2

    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-30, 300), "radius": 25.0},
        {"type": "pillar", "position": Vector2(20, 450), "radius": 25.0}
    ] as Array[Dictionary]

    return seg

func _create_sharp_right() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "sharp_right"
    seg.segment_type = "curve"
    seg.segment_length = 600.0
    seg.tunnel_width = 250.0
    seg.curvature = 60.0
    seg.curve_type = "sharp"
    seg.min_difficulty = 4
    seg.max_difficulty = 10
    seg.complexity = 2

    seg.obstacles = [
        {"type": "pillar", "position": Vector2(30, 300), "radius": 25.0},
        {"type": "pillar", "position": Vector2(-20, 450), "radius": 25.0}
    ] as Array[Dictionary]

    return seg

# ===== COMPLEX SEGMENTS =====

func _create_s_curve() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "s_curve"
    seg.segment_type = "s_curve"
    seg.segment_length = 1000.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0  # Net zero, but curves both ways
    seg.curve_type = "s_shape"
    seg.min_difficulty = 5
    seg.max_difficulty = 10
    seg.complexity = 3

    seg.obstacles = [
        {"type": "pillar", "position": Vector2(40, 350), "radius": 28.0},
        {"type": "pillar", "position": Vector2(-40, 650), "radius": 28.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-50, 350), "value": 15},
        {"type": "orb", "position": Vector2(50, 650), "value": 15},
        {"type": "speed_boost", "position": Vector2(0, 850), "value": 0}
    ] as Array[Dictionary]

    return seg

func _create_slalom() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "slalom"
    seg.segment_type = "straight"
    seg.segment_length = 900.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 6
    seg.max_difficulty = 10
    seg.complexity = 4

    # Alternating pillars forcing S-pattern movement
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(50, 250), "radius": 30.0},
        {"type": "pillar", "position": Vector2(-50, 450), "radius": 30.0},
        {"type": "pillar", "position": Vector2(50, 650), "radius": 30.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-60, 250), "value": 15},
        {"type": "orb", "position": Vector2(60, 450), "value": 15},
        {"type": "orb", "position": Vector2(-60, 650), "value": 15},
        {"type": "magnet", "position": Vector2(0, 800), "duration": 5.0}
    ] as Array[Dictionary]

    return seg

func _create_narrow_passage() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "narrow_passage"
    seg.segment_type = "straight"
    seg.segment_length = 600.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 7
    seg.max_difficulty = 10
    seg.complexity = 3

    seg.obstacles = [
        {"type": "pulse_gate", "position": Vector2(0, 300), "rotation_speed": 0.4},
        {"type": "pillar", "position": Vector2(0, 500), "radius": 25.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "speed_boost", "position": Vector2(0, 150), "value": 0},
        {"type": "stopwatch", "position": Vector2(60, 400), "duration": 6.0, "slow_factor": 0.4}
    ] as Array[Dictionary]

    return seg

func _create_wall_gauntlet() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "wall_gauntlet"
    seg.segment_type = "straight"
    seg.segment_length = 800.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 4
    seg.max_difficulty = 10
    seg.complexity = 3

    # Staggered horizontal walls forcing vertical dodging
    seg.obstacles = [
        {"type": "horizontal_wall", "position": Vector2(-40, 250)},
        {"type": "horizontal_wall", "position": Vector2(40, 400)},
        {"type": "horizontal_wall", "position": Vector2(-40, 550)}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(50, 250), "value": 10},
        {"type": "orb", "position": Vector2(-50, 400), "value": 10},
        {"type": "orb", "position": Vector2(50, 550), "value": 10}
    ] as Array[Dictionary]

    return seg

func _create_pulse_timing() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "pulse_timing"
    seg.segment_type = "straight"
    seg.segment_length = 900.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 5
    seg.max_difficulty = 10
    seg.complexity = 3

    # Three pulsing walls that require timing to pass through
    seg.obstacles = [
        {"type": "pulsing_wall", "position": Vector2(0, 300), "pulse_interval": 1.0},
        {"type": "pulsing_wall", "position": Vector2(-50, 500), "pulse_interval": 1.0},
        {"type": "pulsing_wall", "position": Vector2(50, 700), "pulse_interval": 1.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-60, 300), "value": 15},
        {"type": "orb", "position": Vector2(60, 500), "value": 15},
        {"type": "orb", "position": Vector2(-60, 700), "value": 15}
    ] as Array[Dictionary]

    return seg

func _create_split_path() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "split_path"
    seg.segment_type = "straight"
    seg.segment_length = 1600.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 2
    seg.max_difficulty = 8
    seg.complexity = 1

    # Vertical wall down the center forces player to choose left or right
    seg.obstacles = [
        {"type": "vertical_wall", "position": Vector2(0, 0), "thickness": 16.0}
    ] as Array[Dictionary]

    # Orbs on both sides reward either path choice
    seg.collectibles = [
        {"type": "orb", "position": Vector2(-60, 300), "value": 10},
        {"type": "orb", "position": Vector2(60, 300), "value": 10},
        {"type": "orb", "position": Vector2(-60, 500), "value": 10},
        {"type": "orb", "position": Vector2(60, 500), "value": 10}
    ] as Array[Dictionary]

    return seg

func _create_spike_corridor() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "spike_corridor"
    seg.segment_type = "straight"
    seg.segment_length = 900.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 9
    seg.complexity = 0

    # Triangle spikes on alternating walls pointing inward
    # Point is at the position, base extends backward
    # Left wall: rotation=0° (base at wall, extends right into tunnel)
    # Right wall: rotation=180° (base at wall, extends left into tunnel)
    seg.obstacles = [
        {"type": "triangle_spike", "position": Vector2(-125, 250), "rotation_degrees": 0, "size": 30.0},  # Neg X = right wall
        {"type": "triangle_spike", "position": Vector2(125, 400), "rotation_degrees": 180, "size": 30.0},  # Pos x = left wall
        {"type": "triangle_spike", "position": Vector2(-125, 550), "rotation_degrees": 0, "size": 30.0},
        {"type": "triangle_spike", "position": Vector2(75, 700), "rotation_degrees": 180, "size": 50.0}
        # TODO: figure out the forumla for calculating position based on what the triangle size is
        #  e.g. why is x=50 correct for size 50 instead of ~100? Probably geometry
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 300), "value": 10},
        {"type": "orb", "position": Vector2(0, 500), "value": 10},
        {"type": "orb", "position": Vector2(0, 700), "value": 15}
    ] as Array[Dictionary]

    return seg

func _create_fog_zone() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "fog_zone"
    seg.segment_type = "straight"
    seg.segment_length = 800.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 9
    seg.complexity = 0

    # Smoke screen obscures vision, with pillars hidden inside
    seg.obstacles = [
        {"type": "smoke_screen", "position": Vector2(0, 0), "width": 250.0, "height": 500.0, "opacity": 0.9},
        {"type": "pillar", "position": Vector2(-40, 350), "radius": 25.0},
        {"type": "pillar", "position": Vector2(40, 450), "radius": 25.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 250), "value": 10},
        {"type": "orb", "position": Vector2(0, 550), "value": 15}
    ] as Array[Dictionary]

    return seg

func _create_simple_static_wall() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "simple_wall"
    seg.segment_type = "straight"
    seg.segment_length = 800.0
    seg.tunnel_width = 250.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 3
    seg.complexity = 2

    # Staggered horizontal walls forcing vertical dodging
    seg.obstacles = [
        {"type": "horizontal_wall", "position": Vector2(-40, 250)},
        {"type": "horizontal_wall", "position": Vector2(40, 550)}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(50, 250), "value": 10},
        {"type": "orb", "position": Vector2(-50, 400), "value": 10},
        {"type": "orb", "position": Vector2(50, 550), "value": 10}
    ] as Array[Dictionary]

    return seg

# ===== INDEXING =====

func _index_segments() -> void:
    for seg in all_segments:
        # Index by type
        if not seg.segment_type in segments_by_type:
            segments_by_type[seg.segment_type] = []
        segments_by_type[seg.segment_type].append(seg)

        # Index by difficulty range
        for diff in range(seg.min_difficulty, seg.max_difficulty + 1):
            if not diff in segments_by_difficulty:
                segments_by_difficulty[diff] = []
            segments_by_difficulty[diff].append(seg)

# ===== QUERY METHODS =====

func get_segments_by_difficulty(difficulty: float) -> Array:
    var diff_int := int(clamp(difficulty, 0, 10))
    if diff_int in segments_by_difficulty:
        return segments_by_difficulty[diff_int]
    return []

func get_segments_by_type(type: String) -> Array:
    if type in segments_by_type:
        return segments_by_type[type]
    return []

func get_fallback_segment() -> SegmentData:
    return _create_straight_empty()

func get_random_segment(rng: RandomNumberGenerator) -> SegmentData:
    if all_segments.is_empty():
        return get_fallback_segment()
    return all_segments[rng.randi_range(0, all_segments.size() - 1)]
