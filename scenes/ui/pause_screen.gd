class_name PauseScreen extends Control

@onready var continue_button: Button = %ContinueButton
@onready var menu_button: Button = %MenuButton
@onready var music_check: CheckButton = %MusicCheckButton
@onready var sound_check: CheckButton = %SoundCheckButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var settings_data: SettingsData

func _ready() -> void:
	visible = false
	settings_data = SettingsData.new()

	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	music_check.toggled.connect(_on_music_toggled)
	sound_check.toggled.connect(_on_sound_toggled)

	# Load initial settings
	_load_settings_to_ui()

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
	# Reload settings in case they changed elsewhere
	_load_settings_to_ui()

	visible = true

	# Reset and play animation
	animation_player.stop()
	animation_player.play("RESET")
	await get_tree().process_frame

	# Play open animation
	animation_player.play("open")

func hide_pause_screen() -> void:
	if animation_player.has_animation("open"):
		animation_player.play_backwards("open")
		await animation_player.animation_finished
	visible = false

func _load_settings_to_ui() -> void:
	# Set button states without triggering signals
	music_check.set_pressed_no_signal(settings_data.music_enabled)
	sound_check.set_pressed_no_signal(settings_data.sound_enabled)

func _on_music_toggled(button_pressed: bool) -> void:
	settings_data.set_music_enabled(button_pressed)

func _on_sound_toggled(button_pressed: bool) -> void:
	settings_data.set_sound_enabled(button_pressed)
