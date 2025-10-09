class_name SettingsModal extends Control

## Settings modal for configuring game audio settings and cosmetics
## Can be used in main menu or pause menu

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var orb_count_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Cosmetics/CosmeticsVBox/OrbCountLabel
@onready var cosmetics_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/TabContainer/Cosmetics/CosmeticsVBox/ScrollContainer/CosmeticsGrid
@onready var music_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Settings/SettingsVBox/MusicSetting/MusicCheckButton
@onready var sound_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Settings/SettingsVBox/SoundSetting/SoundCheckButton
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const CosmeticPreviewScene = preload("res://scenes/ui/cosmetic_preview.tscn")

var settings_data: SettingsData
var cosmetic_previews: Array[CosmeticPreview] = []

func _ready() -> void:
    settings_data = SettingsData.new()

    # Hide modal initially
    visible = false

    # Connect signals
    music_check.toggled.connect(_on_music_toggled)
    sound_check.toggled.connect(_on_sound_toggled)
    close_button.pressed.connect(_on_close_button_pressed)
    CosmeticManager.cosmetic_changed.connect(_on_cosmetic_changed)
    CosmeticManager.cosmetic_unlocked.connect(_on_cosmetic_unlocked)

    # Initialize cosmetics grid
    _populate_cosmetics_grid()

    # Set default tab to Cosmetics (index 0)
    tab_container.current_tab = 0

    # Initialize UI with current settings
    _load_settings_to_ui()

    # Apply settings to AudioManager
    settings_data.apply_settings()

func _load_settings_to_ui() -> void:
    # Set button states without triggering signals
    music_check.set_pressed_no_signal(settings_data.music_enabled)
    sound_check.set_pressed_no_signal(settings_data.sound_enabled)

    # Update orb count
    _update_orb_count()

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


func _populate_cosmetics_grid() -> void:
    """Populate the cosmetics grid with all available cosmetics"""
    # Clear existing previews
    for preview in cosmetic_previews:
        preview.queue_free()
    cosmetic_previews.clear()

    # Get all cosmetics from manager
    var all_cosmetics = CosmeticManager.get_all_cosmetics()

    # Create preview for each cosmetic
    for cosmetic in all_cosmetics:
        # Find the cosmetic ID
        var cosmetic_id = ""
        for id in CosmeticManager.cosmetics.keys():
            if CosmeticManager.cosmetics[id] == cosmetic:
                cosmetic_id = id
                break

        # Only show cosmetics that are buyable OR already unlocked
        var is_unlocked = CosmeticManager.is_cosmetic_unlocked(cosmetic_id)
        if not cosmetic.buyable and not is_unlocked:
            continue  # Skip non-buyable cosmetics that aren't unlocked yet

        var preview = CosmeticPreviewScene.instantiate()
        cosmetics_grid.add_child(preview)

        # Setup preview
        preview.setup(cosmetic, cosmetic_id)

        # Connect signals
        preview.unlock_requested.connect(_on_cosmetic_unlock_requested)
        preview.select_requested.connect(_on_cosmetic_select_requested)

        cosmetic_previews.append(preview)


func _on_cosmetic_unlock_requested(cosmetic_id: String) -> void:
    """Handle unlock button pressed"""
    var success = CosmeticManager.unlock_cosmetic(cosmetic_id)

    if success:
        AudioManager.play_sfx("ui_click")
        _refresh_all_previews()
    else:
        # Not enough orbs
        AudioManager.play_sfx("collision")
        print("Not enough orbs to unlock %s" % cosmetic_id)


func _on_cosmetic_select_requested(cosmetic_id: String) -> void:
    """Handle select button pressed"""
    var success = CosmeticManager.select_cosmetic(cosmetic_id)

    if success:
        AudioManager.play_sfx("ui_click")
        _refresh_all_previews()


func _on_cosmetic_changed(_cosmetic: TrailCosmetic) -> void:
    """Handle cosmetic changed signal from manager"""
    _refresh_all_previews()


func _on_cosmetic_unlocked(_cosmetic_id: String) -> void:
    """Handle cosmetic unlocked signal from manager"""
    _refresh_all_previews()


func _refresh_all_previews() -> void:
    """Refresh all cosmetic preview button states"""
    for preview in cosmetic_previews:
        preview.refresh()


func _update_orb_count() -> void:
    """Update the orb count label"""
    var total_orbs = SaveManager.save_data.total_orbs_collected
    orb_count_label.text = "Orbs: %d" % total_orbs
