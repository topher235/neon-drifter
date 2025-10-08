class_name PauseScreen extends Control

@onready var continue_button: Button = %ContinueButton
@onready var menu_button: Button = %MenuButton
@onready var music_check: CheckButton = %MusicCheckButton
@onready var sound_check: CheckButton = %SoundCheckButton

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
	visible = true
	modulate = Color(1, 1, 1, 0)

	# Reload settings in case they changed elsewhere
	_load_settings_to_ui()

	# Create a tween that works when paused
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func hide_pause_screen() -> void:
	visible = false

func _load_settings_to_ui() -> void:
	# Set button states without triggering signals
	music_check.set_pressed_no_signal(settings_data.music_enabled)
	sound_check.set_pressed_no_signal(settings_data.sound_enabled)

func _on_music_toggled(button_pressed: bool) -> void:
	settings_data.set_music_enabled(button_pressed)

func _on_sound_toggled(button_pressed: bool) -> void:
	settings_data.set_sound_enabled(button_pressed)
