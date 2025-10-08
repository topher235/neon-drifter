class_name SettingsData
extends RefCounted

## Handles loading and saving user settings to a configuration file
## Can be reused across different UI components (Settings Modal, Pause Menu, etc.)

const CONFIG_PATH = "res://user-settings.cfg"
const SECTION_AUDIO = "audio"

# Audio settings
var music_enabled: bool = true
var sound_enabled: bool = true

# Signals for settings changes
signal music_toggled(enabled: bool)
signal sound_toggled(enabled: bool)

func _init() -> void:
	load_settings()

## Load settings from the config file
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)

	if err != OK:
		# File doesn't exist or couldn't be loaded, use defaults
		print("Settings file not found, using defaults")
		save_settings()  # Create the file with defaults
		return

	# Load audio settings
	music_enabled = config.get_value(SECTION_AUDIO, "music_enabled", true)
	sound_enabled = config.get_value(SECTION_AUDIO, "sound_enabled", true)

	print("Settings loaded: Music=%s, Sound=%s" % [music_enabled, sound_enabled])

## Save current settings to the config file
func save_settings() -> void:
	var config = ConfigFile.new()

	# Set audio settings
	config.set_value(SECTION_AUDIO, "music_enabled", music_enabled)
	config.set_value(SECTION_AUDIO, "sound_enabled", sound_enabled)

	# Save to file
	var err = config.save(CONFIG_PATH)
	if err != OK:
		push_error("Failed to save settings: %d" % err)
	else:
		print("Settings saved: Music=%s, Sound=%s" % [music_enabled, sound_enabled])

## Toggle music setting
func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	save_settings()
	music_toggled.emit(enabled)

	# Apply to AudioManager
	if AudioManager:
		if enabled:
			AudioManager.unmute_music()
		else:
			AudioManager.mute_music()

## Toggle sound setting
func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	save_settings()
	sound_toggled.emit(enabled)

	# Apply to AudioManager
	if AudioManager:
		if enabled:
			AudioManager.unmute_sfx()
		else:
			AudioManager.mute_sfx()

## Apply current settings to AudioManager
func apply_settings() -> void:
	if AudioManager:
		if music_enabled:
			AudioManager.unmute_music()
		else:
			AudioManager.mute_music()

		if sound_enabled:
			AudioManager.unmute_sfx()
		else:
			AudioManager.mute_sfx()
