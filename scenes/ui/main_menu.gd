extends Control

@onready var play_button: Button = %PlayButton
@onready var daily_button: Button = %DailyChallengeButton
@onready var rush_button: Button = %RushButton
@onready var daily_checkmark: Label = %DailyCheckmark
@onready var quit_button: Button = %QuitButton
@onready var high_score_label: Label = %HighScoreLabel
@onready var title_label: Label = %TitleLabel
@onready var settings_button: Button = %SettingsButton
@onready var shop_button: Button = %ShopButton
@onready var settings_modal: SettingsModal = $SettingsModal
@onready var shop_modal: ShopModal = $ShopModal
@onready var rush_seed_input: RushSeedInput = $RushSeedInput

var title_character_labels: Array[Label] = []
var title_original_y: float = 0.0

func _ready() -> void:
    play_button.pressed.connect(_on_play_pressed)
    daily_button.pressed.connect(_on_daily_pressed)
    if rush_button:
        rush_button.pressed.connect(_on_rush_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    shop_button.pressed.connect(_on_shop_pressed)

    # Connect RUSH seed input signals
    if rush_seed_input:
        rush_seed_input.seed_confirmed.connect(_on_rush_seed_confirmed)
        rush_seed_input.cancelled.connect(_on_rush_seed_cancelled)

    _update_high_score()
    _update_daily_checkmark()
    _animate_title()

    # Play menu music
    AudioManager.play_music("menu")

func _update_high_score() -> void:
    high_score_label.text = "High Score: %d" % GameManager.high_score

func _update_daily_checkmark() -> void:
    # Show checkmark if daily challenge is completed
    if SaveManager.is_daily_challenge_completed():
        daily_checkmark.visible = true
    else:
        daily_checkmark.visible = false

func _animate_title() -> void:
    # Create individual labels for each character
    if not title_label:
        return

    var title_text = title_label.text

    # Get original label properties
    var original_font = title_label.get_theme_font("font")
    var original_font_size = 72 # title_label.get_theme_font_size("font_size")
    var original_color = title_label.get_theme_color("font_color")

    # Get the title_label's parent (should be a Control wrapper)
    var wrapper = title_label.get_parent()
    if not wrapper:
        return

    # Hide the original label
    title_label.visible = false

    # Create a container inside the wrapper
    var container = HBoxContainer.new()
    container.alignment = BoxContainer.ALIGNMENT_CENTER
    container.set_anchors_preset(Control.PRESET_FULL_RECT)
    wrapper.add_child(container)

    # Create a label for each character
    for i in range(title_text.length()):
        var char_label = Label.new()
        char_label.text = title_text[i]

        # Copy styling from original label
        if original_font:
            char_label.add_theme_font_override("font", original_font)
        if original_font_size > 0:
            char_label.add_theme_font_size_override("font_size", original_font_size)
        char_label.add_theme_color_override("font_color", original_color)

        container.add_child(char_label)
        title_character_labels.append(char_label)

func _process(_delta: float) -> void:
    # Animate each character with a phase offset
    var time = Time.get_ticks_msec() / 1000.0

    for i in range(title_character_labels.size()):
        var char_label = title_character_labels[i]
        var phase_offset = i * 0.3  # Offset each character's wave
        var wave_offset = sin(time * 2.0 + phase_offset) * 8.0
        char_label.position.y = wave_offset

func _on_play_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    _start_game(false)

func _on_daily_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    _start_game(true)

func _on_rush_pressed() -> void:
    """Open seed input dialog for RUSH mode"""
    AudioManager.play_sfx("ui_click")
    if rush_seed_input:
        rush_seed_input.open_seed_input()

func _on_rush_seed_confirmed(seed_value: int) -> void:
    """Start RUSH mode with the specified seed"""
    print("Starting RUSH mode with seed: %d" % seed_value)
    GameManager.set_rush_seed(seed_value)
    _start_game_rush()

func _on_rush_seed_cancelled() -> void:
    """User cancelled seed input"""
    print("RUSH mode cancelled")

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_settings_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    settings_modal.open_settings()

func _on_shop_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    shop_modal.open_shop()

func _start_game(daily_challenge: bool) -> void:
    # Set game mode in GameManager
    if daily_challenge:
        GameManager.current_game_mode = GameManager.GameMode.DAILY_CHALLENGE
    else:
        GameManager.current_game_mode = GameManager.GameMode.CLASSIC

    # Transition to game scene
    AudioManager.stop_music(true)

    # Use SceneManager for smooth transition
    await SceneManager.goto_game()

func _start_game_rush() -> void:
    """Start RUSH mode (seeded run)"""
    # Set game mode in GameManager
    GameManager.current_game_mode = GameManager.GameMode.RUSH

    # Transition to game scene
    AudioManager.stop_music(true)

    # Use SceneManager for smooth transition
    await SceneManager.goto_game()
