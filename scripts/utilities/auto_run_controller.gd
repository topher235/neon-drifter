class_name AutoRunController
extends PlayerController

## Auto-run controller for classic mode
## Player controls X position, Y moves automatically upward

var target_x: float              = 0.0
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
        # Check if mouse is over UI
        var viewport  = player.get_viewport()
        var mouse_pos = viewport.get_mouse_position()

        # Check if there's a Control node at this position (UI element)
        var ui_at_point = _is_ui_at_position(viewport, mouse_pos)

        # Only move player if not clicking on UI
        if not ui_at_point:
            var viewport_size = player.get_viewport_rect().size

            # Convert screen X (0 to viewport_width) to game X (-tunnel_half_width to +tunnel_half_width)
            var normalized_x = (mouse_pos.x / viewport_size.x) - 0.5  # -0.5 to 0.5
            target_x = normalized_x * (tunnel_half_width * 3)
            target_x = clamp(target_x, -tunnel_half_width, tunnel_half_width)
    else:
        # Keep X position when not touching
        target_x = target_x


func _is_ui_at_position(viewport: Viewport, position: Vector2) -> bool:
    # Get all nodes at this position by checking Control nodes in the scene
    var root = viewport.get_tree().root
    return _check_control_at_position(root, position)


func _check_control_at_position(node: Node, position: Vector2) -> bool:
    # Check if this node is an interactive UI element at the position
    if node is Control:
        var control := node as Control
        if control.visible and control.get_global_rect().has_point(position):
            # Only block input for interactive controls (buttons, sliders, etc.)
            # Allow input through panels, labels, containers, etc.
            if control.mouse_filter == Control.MOUSE_FILTER_STOP:
                # This is an interactive element that wants to stop mouse input
                if control is BaseButton or control is LineEdit or control is TextEdit or control is Slider:
                    return true

    # Recursively check children (front to back for proper layering)
    for child in node.get_children():
        if _check_control_at_position(child, position):
            return true

    return false
