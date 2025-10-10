class_name SettingsModal
extends Control

## Settings modal for configuring game audio settings
## Can be used in main menu or pause menu

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var music_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Settings/SettingsVBox/MusicSetting/MusicCheckButton
@onready var sound_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Settings/SettingsVBox/SoundSetting/SoundCheckButton
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var settings_data: SettingsData


func _ready() -> void:
    settings_data = SettingsData.new()

    # Hide modal initially
    visible = false

    # Connect signals
    music_check.toggled.connect(_on_music_toggled)
    sound_check.toggled.connect(_on_sound_toggled)
    close_button.pressed.connect(_on_close_button_pressed)

    # Set default tab to Settings (index 0)
    tab_container.current_tab = 0

    # Initialize UI with current settings
    _load_settings_to_ui()

    # Apply settings to AudioManager
    settings_data.apply_settings()


func _load_settings_to_ui() -> void:
    # Set button states without triggering signals
    music_check.set_pressed_no_signal(settings_data.music_enabled)
    sound_check.set_pressed_no_signal(settings_data.sound_enabled)


func _on_music_toggled(button_pressed: bool) -> void:
    settings_data.set_music_enabled(button_pressed)


func _on_sound_toggled(button_pressed: bool) -> void:
    settings_data.set_sound_enabled(button_pressed)


func _on_close_button_pressed() -> void:
    close_settings()


## Public method to open the settings modal
func open_settings() -> void:
    print("open settings")
    _load_settings_to_ui()
    visible = true  # Make modal visible

    # Reset animation to beginning first
    animation_player.stop()
    animation_player.play("RESET")
    await get_tree().process_frame

    # Play open animation
    animation_player.play("open")


## Public method to close the settings modal
func close_settings() -> void:
    if animation_player.has_animation("open"):
        animation_player.play_backwards("open")
        await animation_player.animation_finished
    visible = false  # Hide modal after animation
