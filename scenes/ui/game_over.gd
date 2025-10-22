extends Control

@onready var final_score_label: Label = %FinalScoreLabel
@onready var distance_label: Label = %DistanceLabel
@onready var max_combo_label: Label = %MaxComboLabel
@onready var high_score_label: Label = %HighScoreLabel
@onready var seed_label: Label = %SeedLabel
@onready var time_taken_label: Label = %TimeTakenLabel
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton

var final_score: int      = 0
var final_distance: float = 0.0


func _ready() -> void:
    visible = false
    retry_button.pressed.connect(_on_retry_pressed)
    menu_button.pressed.connect(_on_menu_pressed)

    GameManager.game_over.connect(_on_game_over)


func _on_game_over(score: int, distance: float) -> void:
    final_score = score
    final_distance = distance

    _display_stats()
    _show_screen()


func _display_stats() -> void:
    final_score_label.text = "Score: %d" % final_score
    distance_label.text = "Distance: %.0fm" % (final_distance / 10.0)
    max_combo_label.text = "Max Combo: x%d" % GameManager.max_combo

    if final_score >= GameManager.high_score:
        high_score_label.text = "NEW HIGH SCORE!"
        high_score_label.modulate = Color(1, 1, 0, 1)  # Yellow
    else:
        high_score_label.text = "High Score: %d" % GameManager.high_score
        high_score_label.modulate = Color.WHITE

    # Show seed if in RUSH mode
    if GameManager.current_game_mode == GameManager.GameMode.RUSH:
        seed_label.visible = true
        seed_label.text = "Seed: %d" % GameManager.current_run_seed
    else:
        seed_label.visible = false

    # Show time taken for DAILY and RUSH modes
    if GameManager.current_game_mode == GameManager.GameMode.DAILY_CHALLENGE:
        time_taken_label.visible = true
        var time_taken = GameManager.daily_challenge_time_limit - GameManager.daily_challenge_time_remaining
        time_taken_label.text = "Time: %.2fs" % time_taken
    elif GameManager.current_game_mode == GameManager.GameMode.RUSH:
        time_taken_label.visible = true
        var time_taken = GameManager.rush_time_limit - GameManager.rush_time_remaining
        time_taken_label.text = "Time: %.2fs" % time_taken
    else:
        time_taken_label.visible = false


func _show_screen() -> void:
    visible = true
    modulate = Color(1, 1, 1, 0)

    var tween = create_tween()
    tween.tween_property(self, "modulate", Color.WHITE, 0.3)


func _on_retry_pressed() -> void:
    AudioManager.play_sfx("ui_start_game")
    visible = false
    # Reload the scene completely to reset everything with the same seed
    # The seed is preserved in GameManager.current_run_seed
    await SceneManager.reload_current_scene()


func _on_menu_pressed() -> void:
    AudioManager.play_sfx("ui_back")
    GameManager.return_to_menu()
    await SceneManager.goto_main_menu()