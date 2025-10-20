class_name SegmentLibrary
extends RefCounted

var all_segments: Array[SegmentData]   = []
var segments_by_type: Dictionary       = {}
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

    # New segments - Complexity 0-1 (Beginner)
    all_segments.append(_create_orb_highway())
    all_segments.append(_create_gentle_weave())
    all_segments.append(_create_side_paths())
    all_segments.append(_create_breathing_room())

    # New segments - Complexity 2-3 (Intermediate)
    all_segments.append(_create_chicane())
    all_segments.append(_create_pillar_forest())
    all_segments.append(_create_gate_sequence())
    all_segments.append(_create_curve_and_dodge())
    all_segments.append(_create_hourglass())
    all_segments.append(_create_smoke_and_mirrors())

    # New segments - Complexity 4-5 (Advanced)
    all_segments.append(_create_double_helix())
    all_segments.append(_create_gauntlet_run())
    all_segments.append(_create_pulse_corridor())
    all_segments.append(_create_spiral_descent())
    all_segments.append(_create_wall_maze())
    all_segments.append(_create_fork_in_road())

    # New segments - Complexity 6+ (Expert/Chaos)
    all_segments.append(_create_chaos_zone())
    all_segments.append(_create_death_spiral())
    all_segments.append(_create_bullet_hell())
    all_segments.append(_create_the_grinder())
    all_segments.append(_create_asymmetric_madness())
    all_segments.append(_create_spike_valley())

    # Special/Situational segments
    all_segments.append(_create_rest_zone())
    all_segments.append(_create_speed_trial())
    all_segments.append(_create_treasure_room())

    print("Loaded %d segment templates" % all_segments.size())


# ===== BASIC STRAIGHT SEGMENTS =====

func _create_straight_empty() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "straight_empty"
    seg.segment_type = "straight"
    seg.segment_length = 600.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 2
    seg.complexity = 0

    # Just collectibles, no obstacles
    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 150), "value": 10},
        {"type": "orb", "position": Vector2(-40, 300), "value": 10},
        {"type": "orb", "position": Vector2(40, 450), "value": 10}
    ] as Array[Dictionary]

    return seg


func _create_straight_single_pillar() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "straight_single_pillar"
    seg.segment_type = "straight"
    seg.segment_length = 700.0
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
        {"type": "multiplier", "position": Vector2(0, 850), "duration": 5.0}  # Reward for completing S-curve
    ] as Array[Dictionary]

    return seg


func _create_slalom() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "slalom"
    seg.segment_type = "straight"
    seg.segment_length = 900.0
    seg.tunnel_width = 300.0
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
        {"type": "bomb", "position": Vector2(0, 150)}, # Bomb before the slalom
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
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 7
    seg.max_difficulty = 10
    seg.complexity = 3

    seg.obstacles = [
        {"type": "pulse_gate", "position": Vector2(0, 300), "rotation_speed": 0.4},
        {"type": "pillar", "position": Vector2(0, 500), "radius": 25.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "bomb", "position": Vector2(-60, 150)}, # Bomb to clear the narrow passage
        {"type": "stopwatch", "position": Vector2(60, 400), "duration": 6.0, "slow_factor": 0.4}
    ] as Array[Dictionary]

    return seg


func _create_wall_gauntlet() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "wall_gauntlet"
    seg.segment_type = "straight"
    seg.segment_length = 800.0
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
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
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 9
    seg.complexity = 0

    # Triangle spikes on alternating walls pointing inward
    # Point is at the position, base extends backward
    # Left wall: rotation=0° (base at wall, extends right into tunnel)
    # Right wall: rotation=180° (base at wall, extends left into tunnel)
    seg.obstacles = [
        {"type": "triangle_spike", "position": Vector2(-125, 250), "rotation_degrees": 0, "size": 30.0}, # Neg X = right wall
        {"type": "triangle_spike", "position": Vector2(125, 400), "rotation_degrees": 180, "size": 30.0}, # Pos x = left wall
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
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 9
    seg.complexity = 0

    # Smoke screen obscures vision, with pillars hidden inside
    seg.obstacles = [
        {"type": "smoke_screen", "position": Vector2(0, 0), "width": 300.0, "height": 500.0, "opacity": 0.9},
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
    seg.tunnel_width = 300.0
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


# ===== NEW SEGMENTS - COMPLEXITY 0-1 (BEGINNER) =====

func _create_orb_highway() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "orb_highway"
    seg.segment_type = "straight"
    seg.segment_length = 700.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 3
    seg.complexity = 0

    # No obstacles, just orbs for easy collection
    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 150), "value": 10},
        {"type": "orb", "position": Vector2(0, 250), "value": 10},
        {"type": "orb", "position": Vector2(0, 350), "value": 10},
        {"type": "orb", "position": Vector2(0, 450), "value": 10},
        {"type": "orb", "position": Vector2(0, 550), "value": 10}
    ] as Array[Dictionary]

    return seg


func _create_gentle_weave() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "gentle_weave"
    seg.segment_type = "curve"
    seg.segment_length = 800.0
    seg.tunnel_width = 300.0
    seg.curvature = 15.0
    seg.curve_type = "gentle"
    seg.min_difficulty = 0
    seg.max_difficulty = 4
    seg.complexity = 1

    # Two pillars on opposite sides
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-50, 300), "radius": 28.0},
        {"type": "pillar", "position": Vector2(50, 550), "radius": 28.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(50, 300), "value": 10},
        {"type": "orb", "position": Vector2(-50, 550), "value": 10}
    ] as Array[Dictionary]

    return seg


func _create_side_paths() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "side_paths"
    seg.segment_type = "straight"
    seg.segment_length = 700.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 4
    seg.complexity = 1

    # Horizontal walls create lanes
    seg.obstacles = [
        {"type": "horizontal_wall", "position": Vector2(-60, 300)},
        {"type": "horizontal_wall", "position": Vector2(60, 300)}
    ] as Array[Dictionary]

    # Orb clusters in each lane
    seg.collectibles = [
        {"type": "orb", "position": Vector2(-60, 200), "value": 10},
        {"type": "orb", "position": Vector2(-60, 400), "value": 10},
        {"type": "orb", "position": Vector2(60, 200), "value": 10},
        {"type": "orb", "position": Vector2(60, 400), "value": 10}
    ] as Array[Dictionary]

    return seg


func _create_breathing_room() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "breathing_room"
    seg.segment_type = "straight"
    seg.segment_length = 1000.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 5
    seg.complexity = 0

    # Minimal obstacles, lots of orbs for recovery
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(0, 500), "radius": 25.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-50, 200), "value": 10},
        {"type": "orb", "position": Vector2(50, 200), "value": 10},
        {"type": "hourglass", "position": Vector2(0, 500), "time_bonus": 5.0}, # Time bonus in breathing room
        {"type": "orb", "position": Vector2(-50, 700), "value": 10},
        {"type": "orb", "position": Vector2(50, 700), "value": 10},
        {"type": "orb", "position": Vector2(0, 900), "value": 15}
    ] as Array[Dictionary]

    return seg


# ===== NEW SEGMENTS - COMPLEXITY 2-3 (INTERMEDIATE) =====

func _create_chicane() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "chicane"
    seg.segment_type = "s_curve"
    seg.segment_length = 800.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0  # Net zero, alternating curves
    seg.curve_type = "zigzag"
    seg.min_difficulty = 3
    seg.max_difficulty = 7
    seg.complexity = 2

    # Pillars in each turn to force commitment
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-40, 300), "radius": 28.0},
        {"type": "pillar", "position": Vector2(40, 500), "radius": 28.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(40, 300), "value": 10},
        {"type": "orb", "position": Vector2(-40, 500), "value": 10},
        {"type": "orb", "position": Vector2(0, 700), "value": 15}
    ] as Array[Dictionary]

    return seg


func _create_pillar_forest() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "pillar_forest"
    seg.segment_type = "straight"
    seg.segment_length = 900.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 4
    seg.max_difficulty = 9
    seg.complexity = 3

    # 4-5 pillars in staggered pattern requiring weaving
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-40, 250), "radius": 27.0},
        {"type": "pillar", "position": Vector2(50, 400), "radius": 27.0},
        {"type": "pillar", "position": Vector2(0, 550), "radius": 27.0},
        {"type": "pillar", "position": Vector2(-50, 700), "radius": 27.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(50, 250), "value": 12},
        {"type": "orb", "position": Vector2(-50, 400), "value": 12},
        {"type": "orb", "position": Vector2(60, 550), "value": 12},
        {"type": "orb", "position": Vector2(50, 700), "value": 15}
    ] as Array[Dictionary]

    return seg


func _create_gate_sequence() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "gate_sequence"
    seg.segment_type = "straight"
    seg.segment_length = 800.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 3
    seg.max_difficulty = 8
    seg.complexity = 2

    # Two pulse gates with different rotation speeds
    seg.obstacles = [
        {"type": "pulse_gate", "position": Vector2(0, 300), "rotation_speed": 0.3},
        {"type": "pulse_gate", "position": Vector2(0, 550), "rotation_speed": 0.5}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 150), "value": 10},
        {"type": "orb", "position": Vector2(0, 425), "value": 15},
        {"type": "orb", "position": Vector2(0, 700), "value": 15}
    ] as Array[Dictionary]

    return seg


func _create_curve_and_dodge() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "curve_and_dodge"
    seg.segment_type = "curve"
    seg.segment_length = 850.0
    seg.tunnel_width = 300.0
    seg.curvature = 30.0
    seg.curve_type = "gentle"
    seg.min_difficulty = 4
    seg.max_difficulty = 8
    seg.complexity = 3

    # Gentle curve combined with 2-3 obstacles
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(35, 300), "radius": 28.0},
        {"type": "pillar", "position": Vector2(-20, 500), "radius": 28.0},
        {"type": "pillar", "position": Vector2(40, 700), "radius": 28.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-40, 300), "value": 12},
        {"type": "orb", "position": Vector2(40, 500), "value": 12},
        {"type": "orb", "position": Vector2(-40, 700), "value": 15}
    ] as Array[Dictionary]

    return seg


func _create_hourglass() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "hourglass"
    seg.segment_type = "straight"
    seg.segment_length = 700.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 3
    seg.max_difficulty = 7
    seg.complexity = 2

    # Horizontal walls create narrow center section
    seg.obstacles = [
        {"type": "horizontal_wall", "position": Vector2(-70, 250)},
        {"type": "horizontal_wall", "position": Vector2(70, 250)},
        {"type": "horizontal_wall", "position": Vector2(-70, 450)},
        {"type": "horizontal_wall", "position": Vector2(70, 450)}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 150), "value": 10},
        {"type": "orb", "position": Vector2(0, 350), "value": 15},
        {"type": "orb", "position": Vector2(0, 600), "value": 10}
    ] as Array[Dictionary]

    return seg


func _create_smoke_and_mirrors() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "smoke_and_mirrors"
    seg.segment_type = "straight"
    seg.segment_length = 750.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 4
    seg.max_difficulty = 9
    seg.complexity = 3

    # Smoke screen with triangle spikes hidden inside
    seg.obstacles = [
        {"type": "smoke_screen", "position": Vector2(0, 0), "width": 300.0, "height": 550.0, "opacity": 0.85},
        {"type": "triangle_spike", "position": Vector2(-125, 300), "rotation_degrees": 0, "size": 35.0},
        {"type": "triangle_spike", "position": Vector2(125, 450), "rotation_degrees": 180, "size": 35.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 200), "value": 10},
        {"type": "orb", "position": Vector2(0, 600), "value": 15}
    ] as Array[Dictionary]

    return seg


# ===== NEW SEGMENTS - COMPLEXITY 4-5 (ADVANCED) =====

func _create_double_helix() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "double_helix"
    seg.segment_type = "s_curve"
    seg.segment_length = 1000.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0  # Net zero, sharp alternating curves
    seg.curve_type = "sharp_s"
    seg.min_difficulty = 6
    seg.max_difficulty = 10
    seg.complexity = 4

    # Sharp S-curve with pillars forcing a spiral path
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-45, 300), "radius": 28.0},
        {"type": "pillar", "position": Vector2(45, 500), "radius": 28.0},
        {"type": "pillar", "position": Vector2(-45, 750), "radius": 28.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(45, 300), "value": 15},
        {"type": "orb", "position": Vector2(-45, 500), "value": 15},
        {"type": "multiplier", "position": Vector2(45, 750), "duration": 6.0}  # Reward for navigating helix
    ] as Array[Dictionary]

    return seg


func _create_gauntlet_run() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "gauntlet_run"
    seg.segment_type = "straight"
    seg.segment_length = 900.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 7
    seg.max_difficulty = 10
    seg.complexity = 5

    # Dense field of 6-7 pillars in cluster formation
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-50, 250), "radius": 26.0},
        {"type": "pillar", "position": Vector2(40, 350), "radius": 26.0},
        {"type": "pillar", "position": Vector2(-30, 450), "radius": 26.0},
        {"type": "pillar", "position": Vector2(50, 550), "radius": 26.0},
        {"type": "pillar", "position": Vector2(0, 650), "radius": 26.0},
        {"type": "pillar", "position": Vector2(-40, 750), "radius": 26.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(50, 250), "value": 15},
        {"type": "orb", "position": Vector2(-40, 350), "value": 15},
        {"type": "orb", "position": Vector2(40, 550), "value": 20},
        {"type": "hourglass", "position": Vector2(50, 800), "time_bonus": 12.0}  # Big time bonus for surviving gauntlet
    ] as Array[Dictionary]

    return seg


func _create_pulse_corridor() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "pulse_corridor"
    seg.segment_type = "straight"
    seg.segment_length = 1000.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 6
    seg.max_difficulty = 10
    seg.complexity = 4

    # 3-4 pulsing gates in sequence with different timing
    seg.obstacles = [
        {"type": "pulse_gate", "position": Vector2(0, 250), "rotation_speed": 0.35},
        {"type": "pulse_gate", "position": Vector2(0, 450), "rotation_speed": 0.45},
        {"type": "pulse_gate", "position": Vector2(0, 700), "rotation_speed": 0.40}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 100), "value": 12},
        {"type": "orb", "position": Vector2(0, 350), "value": 15},
        {"type": "orb", "position": Vector2(0, 575), "value": 15},
        {"type": "multiplier", "position": Vector2(0, 850), "duration": 7.0}  # Big reward for clearing pulse corridor
    ] as Array[Dictionary]

    return seg


func _create_spiral_descent() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "spiral_descent"
    seg.segment_type = "curve"
    seg.segment_length = 1100.0
    seg.tunnel_width = 300.0
    seg.curvature = 45.0  # Continuous curve that tightens
    seg.curve_type = "tightening"
    seg.min_difficulty = 6
    seg.max_difficulty = 10
    seg.complexity = 4

    # Long continuous curve with pillars on outer edge
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(50, 350), "radius": 28.0},
        {"type": "pillar", "position": Vector2(55, 650), "radius": 28.0},
        {"type": "pillar", "position": Vector2(60, 900), "radius": 28.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-50, 350), "value": 15},
        {"type": "orb", "position": Vector2(-55, 650), "value": 15},
        {"type": "orb", "position": Vector2(-60, 900), "value": 20}
    ] as Array[Dictionary]

    return seg


func _create_wall_maze() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "wall_maze"
    seg.segment_type = "straight"
    seg.segment_length = 850.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 7
    seg.max_difficulty = 10
    seg.complexity = 5

    # Multiple horizontal walls creating maze-like path
    seg.obstacles = [
        {"type": "horizontal_wall", "position": Vector2(-50, 200)},
        {"type": "horizontal_wall", "position": Vector2(50, 350)},
        {"type": "horizontal_wall", "position": Vector2(-50, 500)},
        {"type": "horizontal_wall", "position": Vector2(50, 650)},
        {"type": "shockwave", "position": Vector2(0, 400), "core_radius": 18.0, "shockwave_max_radius": 45.0, "shockwave_interval": 2.5, "shockwave_duration": 1.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(60, 200), "value": 15},
        {"type": "orb", "position": Vector2(-60, 350), "value": 15},
        {"type": "orb", "position": Vector2(60, 500), "value": 15},
        {"type": "orb", "position": Vector2(0, 750), "value": 20}
    ] as Array[Dictionary]

    return seg


func _create_fork_in_road() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "fork_in_road"
    seg.segment_type = "straight"
    seg.segment_length = 1200.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 5
    seg.max_difficulty = 9
    seg.complexity = 4

    # Vertical wall splits path, one side has obstacles
    seg.obstacles = [
        {"type": "vertical_wall", "position": Vector2(0, 0), "thickness": 16.0},
        {"type": "pillar", "position": Vector2(50, 400), "radius": 28.0},
        {"type": "pillar", "position": Vector2(50, 700), "radius": 28.0}
    ] as Array[Dictionary]

    # Hard path (right) has more/better orbs
    seg.collectibles = [
        {"type": "orb", "position": Vector2(-60, 300), "value": 10},
        {"type": "orb", "position": Vector2(-60, 600), "value": 10},
        {"type": "orb", "position": Vector2(-60, 900), "value": 12},
        {"type": "orb", "position": Vector2(50, 550), "value": 20},
        {"type": "orb", "position": Vector2(50, 1000), "value": 25}
    ] as Array[Dictionary]

    return seg


# ===== NEW SEGMENTS - COMPLEXITY 6+ (EXPERT/CHAOS) =====

func _create_chaos_zone() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "chaos_zone"
    seg.segment_type = "straight"
    seg.segment_length = 1000.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 8
    seg.max_difficulty = 10
    seg.complexity = 6

    # Mix of ALL obstacle types
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-50, 250), "radius": 26.0},
        {"type": "pillar", "position": Vector2(50, 400), "radius": 26.0},
        {"type": "pulse_gate", "position": Vector2(0, 550), "rotation_speed": 0.4},
        {"type": "pulsing_wall", "position": Vector2(-40, 700), "pulse_interval": 1.2},
        {"type": "triangle_spike", "position": Vector2(-125, 850), "rotation_degrees": 0, "size": 32.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(50, 250), "value": 20},
        {"type": "orb", "position": Vector2(-50, 400), "value": 20},
        {"type": "orb", "position": Vector2(0, 850), "value": 30}
    ] as Array[Dictionary]

    return seg


func _create_death_spiral() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "death_spiral"
    seg.segment_type = "curve"
    seg.segment_length = 900.0
    seg.tunnel_width = 300.0
    seg.curvature = -60.0  # Sharp continuous curve
    seg.curve_type = "sharp"
    seg.min_difficulty = 8
    seg.max_difficulty = 10
    seg.complexity = 6

    # Sharp curve with rotating obstacles requiring precise timing
    seg.obstacles = [
        {"type": "pulse_gate", "position": Vector2(-30, 300), "rotation_speed": 0.35},
        {"type": "pillar", "position": Vector2(-40, 500), "radius": 27.0},
        {"type": "pulse_gate", "position": Vector2(-35, 700), "rotation_speed": 0.42}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(40, 300), "value": 20},
        {"type": "orb", "position": Vector2(40, 500), "value": 20},
        {"type": "orb", "position": Vector2(40, 700), "value": 25}
    ] as Array[Dictionary]

    return seg


func _create_bullet_hell() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "bullet_hell"
    seg.segment_type = "straight"
    seg.segment_length = 1100.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 9
    seg.max_difficulty = 10
    seg.complexity = 7

    # 8-10 pillars in pseudo-random pattern with smoke screen
    seg.obstacles = [
        {"type": "smoke_screen", "position": Vector2(0, 0), "width": 300.0, "height": 400.0, "opacity": 0.75},
        {"type": "pillar", "position": Vector2(-60, 250), "radius": 25.0},
        {"type": "pillar", "position": Vector2(40, 300), "radius": 25.0},
        {"type": "pillar", "position": Vector2(-30, 400), "radius": 25.0},
        {"type": "pillar", "position": Vector2(55, 480), "radius": 25.0},
        {"type": "pillar", "position": Vector2(-45, 580), "radius": 25.0},
        {"type": "pillar", "position": Vector2(30, 680), "radius": 25.0},
        {"type": "pillar", "position": Vector2(-50, 780), "radius": 25.0},
        {"type": "pillar", "position": Vector2(45, 880), "radius": 25.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "bomb", "position": Vector2(0, 100)}, # Bomb at start of bullet hell
        {"type": "orb", "position": Vector2(0, 1000), "value": 50}  # Massive reward at end
    ] as Array[Dictionary]

    return seg


func _create_the_grinder() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "the_grinder"
    seg.segment_type = "s_curve"
    seg.segment_length = 1000.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0  # Net zero, S-curve
    seg.curve_type = "s_shape"
    seg.min_difficulty = 8
    seg.max_difficulty = 10
    seg.complexity = 6

    # S-curve with pulsing walls at each turn point
    seg.obstacles = [
        {"type": "pulsing_wall", "position": Vector2(-40, 300), "pulse_interval": 1.0},
        {"type": "triangle_spike", "position": Vector2(-125, 450), "rotation_degrees": 0, "size": 30.0},
        {"type": "pulsing_wall", "position": Vector2(40, 650), "pulse_interval": 1.0},
        {"type": "triangle_spike", "position": Vector2(125, 800), "rotation_degrees": 180, "size": 30.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "bomb", "position": Vector2(0, 150)}, # Bomb to clear the grinder
        {"type": "orb", "position": Vector2(40, 300), "value": 20},
        {"type": "orb", "position": Vector2(-40, 650), "value": 20},
        {"type": "orb", "position": Vector2(0, 950), "value": 30}
    ] as Array[Dictionary]

    return seg


func _create_asymmetric_madness() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "asymmetric_madness"
    seg.segment_type = "curve"
    seg.segment_length = 950.0
    seg.tunnel_width = 300.0
    seg.curvature = 45.0
    seg.curve_type = "gentle"
    seg.min_difficulty = 8
    seg.max_difficulty = 10
    seg.complexity = 7

    # Curve with obstacles on inside edge forcing player to outside
    seg.obstacles = [
        {"type": "triangle_spike", "position": Vector2(80, 250), "rotation_degrees": 180, "size": 35.0},
        {"type": "pillar", "position": Vector2(50, 400), "radius": 28.0},
        {"type": "triangle_spike", "position": Vector2(90, 550), "rotation_degrees": 180, "size": 35.0},
        {"type": "pillar", "position": Vector2(55, 700), "radius": 28.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(-60, 250), "value": 20},
        {"type": "orb", "position": Vector2(-60, 550), "value": 20},
        {"type": "orb", "position": Vector2(-60, 850), "value": 25}
    ] as Array[Dictionary]

    return seg


func _create_spike_valley() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "spike_valley"
    seg.segment_type = "straight"
    seg.segment_length = 800.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 7
    seg.max_difficulty = 10
    seg.complexity = 5

    # Alternating triangle spikes from both walls creating valley path
    seg.obstacles = [
        {"type": "triangle_spike", "position": Vector2(-125, 200), "rotation_degrees": 0, "size": 40.0},
        {"type": "triangle_spike", "position": Vector2(100, 300), "rotation_degrees": 180, "size": 35.0},
        {"type": "triangle_spike", "position": Vector2(-125, 400), "rotation_degrees": 0, "size": 38.0},
        {"type": "triangle_spike", "position": Vector2(105, 500), "rotation_degrees": 180, "size": 40.0},
        {"type": "triangle_spike", "position": Vector2(-125, 600), "rotation_degrees": 0, "size": 35.0},
        {"type": "triangle_spike", "position": Vector2(100, 700), "rotation_degrees": 180, "size": 38.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "orb", "position": Vector2(0, 250), "value": 15},
        {"type": "orb", "position": Vector2(0, 450), "value": 15},
        {"type": "orb", "position": Vector2(0, 650), "value": 20}
    ] as Array[Dictionary]

    return seg


# ===== SPECIAL/SITUATIONAL SEGMENTS =====

func _create_rest_zone() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "rest_zone"
    seg.segment_type = "straight"
    seg.segment_length = 1400.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 0
    seg.max_difficulty = 2
    seg.complexity = 0

    # Very long, obstacle-free segment for recovery
    seg.collectibles = [
        {"type": "orb", "position": Vector2(-50, 300), "value": 10},
        {"type": "orb", "position": Vector2(50, 300), "value": 10},
        {"type": "hourglass", "position": Vector2(0, 500), "time_bonus": 8.0}, # Time bonus in rest zone
        {"type": "orb", "position": Vector2(-50, 700), "value": 10},
        {"type": "orb", "position": Vector2(50, 700), "value": 10},
        {"type": "orb", "position": Vector2(0, 900), "value": 12},
        {"type": "orb", "position": Vector2(-50, 1100), "value": 12},
        {"type": "orb", "position": Vector2(50, 1100), "value": 12}
    ] as Array[Dictionary]

    return seg


func _create_speed_trial() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "speed_trial"
    seg.segment_type = "straight"
    seg.segment_length = 1000.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 4
    seg.max_difficulty = 7
    seg.complexity = 3

    # Stopwatch collectible with orb gauntlet
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(-50, 500), "radius": 28.0},
        {"type": "pillar", "position": Vector2(50, 700), "radius": 28.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "stopwatch", "position": Vector2(0, 200), "duration": 8.0, "slow_factor": 0.3},
        {"type": "orb", "position": Vector2(50, 400), "value": 15},
        {"type": "orb", "position": Vector2(-50, 600), "value": 15},
        {"type": "orb", "position": Vector2(0, 800), "value": 20},
        {"type": "orb", "position": Vector2(0, 900), "value": 20}
    ] as Array[Dictionary]

    return seg


func _create_treasure_room() -> SegmentData:
    var seg = SegmentData.new()
    seg.segment_id = "treasure_room"
    seg.segment_type = "straight"
    seg.segment_length = 600.0
    seg.tunnel_width = 300.0
    seg.curvature = 0.0
    seg.min_difficulty = 3
    seg.max_difficulty = 6
    seg.complexity = 2

    # Multiplier and magnet collectibles surrounded by ring of orbs
    seg.obstacles = [
        {"type": "pillar", "position": Vector2(0, 200), "radius": 25.0}
    ] as Array[Dictionary]

    seg.collectibles = [
        {"type": "multiplier", "position": Vector2(-40, 350), "duration": 5.0}, # Multiplier collectible
        {"type": "magnet", "position": Vector2(40, 350), "duration": 6.0},
        {"type": "orb", "position": Vector2(-60, 300), "value": 15},
        {"type": "orb", "position": Vector2(60, 300), "value": 15},
        {"type": "orb", "position": Vector2(-60, 400), "value": 15},
        {"type": "orb", "position": Vector2(60, 400), "value": 15},
        {"type": "orb", "position": Vector2(0, 450), "value": 20}
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
