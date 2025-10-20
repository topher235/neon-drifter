class_name SegmentData
extends Resource

# Identity
@export var segment_id: String = ""
@export var segment_type: String = "straight"  # straight, curve, s_curve, fork
# Dimensions
@export var segment_length: float = 800.0
@export var tunnel_width: float = 400.0
# Geometry
@export var curvature: float = 0.0  # Degrees (-90 to 90, negative = left)
@export var curve_type: String = "none"  # none, gentle, sharp, s_shape

# Difficulty
@export_range(0, 10) var min_difficulty: int = 0

@export_range(0, 10) var max_difficulty: int = 10
@export var complexity: int = 1  # How many obstacles/features
# Content
@export var obstacles: Array[Dictionary] = []
# Structure: {"type": "pillar", "position": Vector2, "radius": float, "rotation_speed": float}

@export var collectibles: Array[Dictionary] = []
# Structure: {"type": "orb", "position": Vector2, "value": int}

# Special features
@export var has_fork: bool = false
@export var has_gravity_shift: bool = false
# Visual
@export var background_color_tint: Color = Color.WHITE


# Validation
func is_valid() -> bool:
    return segment_length > 0 and tunnel_width > 0


func _duplicate_deep() -> SegmentData:
    var dup = self.duplicate()
    dup.obstacles = obstacles.duplicate(true)
    dup.collectibles = collectibles.duplicate(true)
    return dup
