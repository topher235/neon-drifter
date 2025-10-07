class_name SandboxUi extends Control

signal spawn_pillar_requested(world_pos: Vector2)
signal spawn_orb_requested(world_pos: Vector2)
signal spawn_shockwave_requested(world_pos: Vector2)
signal spawn_star_requested(world_pos: Vector2)
signal clear_requested
signal input_mode_changed(mode: String)

@onready var spawn_mode_label: Label = %SpawnModeLabel
@onready var pillar_button: Button = %PillarButton
@onready var orb_button: Button = %OrbButton
@onready var shockwave_button: Button = %ShockwaveButton
@onready var star_button: Button = %StarButton
@onready var clear_button: Button = %ClearButton
@onready var input_mode_button: Button = %InputModeButton
@onready var help_label: Label = %HelpLabel

var current_spawn_mode: String = "pillar"
var current_input_mode: String = "spawn"  # "spawn" or "move"
var player: PlayerLine

func _ready() -> void:
	pillar_button.pressed.connect(_on_pillar_button_pressed)
	orb_button.pressed.connect(_on_orb_button_pressed)
	shockwave_button.pressed.connect(_on_shockwave_button_pressed)
	star_button.pressed.connect(_on_star_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	input_mode_button.pressed.connect(_on_input_mode_button_pressed)

	_update_spawn_mode_display()
	_update_input_mode_display()

func _unhandled_input(event: InputEvent) -> void:
	# Space to toggle spawn mode
	if event.is_action_pressed("ui_accept"):
		_toggle_spawn_mode()
		get_viewport().set_input_as_handled()

	# Right click to spawn at mouse position
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			_spawn_at_mouse_position(mouse_pos)

func _toggle_spawn_mode() -> void:
	if current_spawn_mode == "pillar":
		current_spawn_mode = "orb"
	elif current_spawn_mode == "orb":
		current_spawn_mode = "shockwave"
	elif current_spawn_mode == "shockwave":
		current_spawn_mode = "star"
	else:
		current_spawn_mode = "pillar"
	_update_spawn_mode_display()

func _update_spawn_mode_display() -> void:
	spawn_mode_label.text = "Mode: " + current_spawn_mode.capitalize()

	# Update button states
	pillar_button.button_pressed = (current_spawn_mode == "pillar")
	orb_button.button_pressed = (current_spawn_mode == "orb")
	shockwave_button.button_pressed = (current_spawn_mode == "shockwave")
	star_button.button_pressed = (current_spawn_mode == "star")

func _on_pillar_button_pressed() -> void:
	current_spawn_mode = "pillar"
	_update_spawn_mode_display()

func _on_orb_button_pressed() -> void:
	current_spawn_mode = "orb"
	_update_spawn_mode_display()

func _on_shockwave_button_pressed() -> void:
	current_spawn_mode = "shockwave"
	_update_spawn_mode_display()

func _on_star_button_pressed() -> void:
	current_spawn_mode = "star"
	_update_spawn_mode_display()

func _on_clear_button_pressed() -> void:
	clear_requested.emit()

func _on_input_mode_button_pressed() -> void:
	# Toggle between spawn and move modes
	if current_input_mode == "spawn":
		current_input_mode = "move"
	else:
		current_input_mode = "spawn"
	_update_input_mode_display()
	input_mode_changed.emit(current_input_mode)

func _update_input_mode_display() -> void:
	if current_input_mode == "spawn":
		input_mode_button.text = "Mode: SPAWN"
		help_label.text = "Left-click to spawn\nSpace to toggle mode\n(or use buttons)"
	else:
		input_mode_button.text = "Mode: MOVE"
		help_label.text = "Touch to move player\nSpace toggles spawn/move"

func _spawn_at_mouse_position(screen_pos: Vector2) -> void:
	# Convert screen position to world position
	var camera = get_viewport().get_camera_2d()
	if camera:
		var world_pos = camera.get_screen_center_position() + (screen_pos - get_viewport_rect().size / 2)

		if current_spawn_mode == "pillar":
			spawn_pillar_requested.emit(world_pos)
		elif current_spawn_mode == "orb":
			spawn_orb_requested.emit(world_pos)
		elif current_spawn_mode == "shockwave":
			spawn_shockwave_requested.emit(world_pos)
		elif current_spawn_mode == "star":
			spawn_star_requested.emit(world_pos)
