class_name PlayerCamera extends Camera2D

# Screen shake parameters
var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_frequency: float = 30.0  # Hz

# Smooth following
@export var follow_offset: Vector2 = Vector2(200, 0)  # Look ahead
@export var follow_smoothness: float = 5.0

# Target (usually the player)
var follow_target: Node2D = null

# Original position for shake
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
    # Find player automatically
    call_deferred("_find_player")

func _find_player() -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player:
        follow_target = player

func _process(delta: float) -> void:
#    if follow_target:
#        _follow_target(delta)

    if shake_timer > 0:
        _apply_shake(delta)

func _follow_target(delta: float) -> void:
    var target_pos = follow_target.global_position + follow_offset
    global_position = global_position.lerp(target_pos, follow_smoothness * delta)

func _apply_shake(delta: float) -> void:
    shake_timer -= delta

    if shake_timer > 0:
        # Random shake with sine wave for natural feel
        var shake_offset = Vector2(
                               randf_range(-shake_amount, shake_amount) * sin(shake_timer * shake_frequency),
                               randf_range(-shake_amount, shake_amount) * cos(shake_timer * shake_frequency * 1.3)
                           )
        offset = original_offset + shake_offset
    else:
        # Shake finished, reset
        offset = original_offset
        shake_timer = 0.0
        shake_amount = 0.0

func apply_shake(duration: float, intensity: float) -> void:
    shake_duration = duration
    shake_timer = duration
    shake_amount = intensity
    original_offset = offset

func set_follow_target(target: Node2D) -> void:
    follow_target = target

func set_look_ahead(ahead: float) -> void:
    follow_offset.x = ahead