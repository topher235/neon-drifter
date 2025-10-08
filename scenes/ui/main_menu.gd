extends Control

@onready var play_button: Button = %PlayButton
@onready var daily_button: Button = %DailyChallengeButton
@onready var daily_checkmark: Label = %DailyCheckmark
@onready var quit_button: Button = %QuitButton
@onready var high_score_label: Label = %HighScoreLabel
@onready var title_label: Label = %TitleLabel
@onready var settings_button: Button = %SettingsButton
@onready var settings_modal: Control = $SettingsModal

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	daily_button.pressed.connect(_on_daily_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

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
	# Pulse animation for title
	var tween = create_tween().set_loops()
	tween.tween_property(title_label, "scale", Vector2(1.05, 1.05), 1.0)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.0)

func _on_play_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_start_game(false)

func _on_daily_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_start_game(true)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if settings_modal.has_method("open_settings"):
		settings_modal.open_settings()
	else:
		settings_modal.visible = true

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
