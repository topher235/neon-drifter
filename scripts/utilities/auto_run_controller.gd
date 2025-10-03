class_name AutoRunController
extends PlayerController

## Auto-run controller for classic mode
## Player controls X position, Y moves automatically upward

var target_x: float = 0.0
var auto_speed_multiplier: float = 1.2

func _ready() -> void:
    super._ready()

func get_target_position(current_position: Vector2, delta: float) -> Vector2:
    var target := Vector2.ZERO

    # X position - will be smoothed by PlayerLine
    target.x = target_x

    # Y position - calculate direct movement (no smoothing)
    var forward_speed := GameManager.current_speed * auto_speed_multiplier
    target.y = current_position.y - (forward_speed * delta)

    return target

func handle_input() -> void:
    if Input.is_action_pressed("touch"):
        var viewport_size = player.get_viewport_rect().size
        var mouse_pos = player.get_viewport().get_mouse_position()

        # Convert screen X (0 to viewport_width) to game X (-tunnel_half_width to +tunnel_half_width)
        var normalized_x = (mouse_pos.x / viewport_size.x) - 0.5  # -0.5 to 0.5
        target_x = normalized_x * (tunnel_half_width * 2)
        target_x = clamp(target_x, -tunnel_half_width, tunnel_half_width)
    else:
        # Return to center when not touching
        target_x = 0.0
