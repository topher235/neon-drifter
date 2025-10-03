class_name FreeMovementController
extends PlayerController

## Free movement controller for daily challenge mode
## Player controls both X and Y position directly with mouse/touch

var target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()

func get_target_position(current_position: Vector2, delta: float) -> Vector2:
	return target_position

func handle_input() -> void:
	if Input.is_action_pressed("touch"):
		var viewport_size = player.get_viewport_rect().size
		var mouse_pos = player.get_viewport().get_mouse_position()

		# Convert screen position to game world position
		# X: screen X (0 to viewport_width) to game X (-tunnel_half_width to +tunnel_half_width)
		var normalized_x = (mouse_pos.x / viewport_size.x) - 0.5  # -0.5 to 0.5
		target_position.x = normalized_x * (tunnel_half_width * 2)
		target_position.x = clamp(target_position.x, -tunnel_half_width, tunnel_half_width)

		# Y: Convert screen Y to world Y (camera follows player, so we need offset)
		# Screen space is 0 at top, viewport_height at bottom
		# World space moves upward (negative Y)
		# Top of screen = forward movement (more negative Y in world space)
		var camera_y = camera.get_screen_center_position().y
		var screen_to_world_y = mouse_pos.y - (viewport_size.y / 2.0)
		target_position.y = camera_y + screen_to_world_y
	else:
		# Keep current position when not touching
		target_position = player.current_position
