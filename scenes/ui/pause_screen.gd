class_name PauseScreen extends Control

@onready var continue_button: Button = %ContinueButton
@onready var menu_button: Button = %MenuButton

func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.resume_game()
	hide_pause_screen()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.return_to_menu()
	hide_pause_screen()
	await SceneManager.goto_main_menu()

func show_pause_screen() -> void:
	visible = true
	modulate = Color(1, 1, 1, 0)

	# Create a tween that works when paused
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func hide_pause_screen() -> void:
	visible = false
