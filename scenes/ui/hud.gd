extends CanvasLayer

# UI Elements
@onready var score_label: Label = %ScoreLabel
@onready var distance_label: Label = %DistanceLabel
@onready var combo_label: Label = %ComboLabel
@onready var speed_label: Label = %SpeedLabel
@onready var pause_button: Button = %PauseButton

# Animation
var combo_tween: Tween

func _ready() -> void:
    # Connect to game signals
    GameManager.score_changed.connect(_on_score_changed)
    GameManager.speed_changed.connect(_on_speed_changed)
    GameManager.combo_changed.connect(_on_combo_changed)
    GameManager.game_started.connect(_on_game_started)
    GameManager.game_over.connect(_on_game_over)

    pause_button.pressed.connect(_on_pause_pressed)

    _update_display()

func _process(_delta: float) -> void:
    if GameManager.is_playing():
        _update_distance()

func _update_display() -> void:
    score_label.text = "Score: %d" % GameManager.current_score
    distance_label.text = "%.0fm" % (GameManager.distance_traveled / 10.0)
    combo_label.text = "x%d" % GameManager.combo_multiplier
    speed_label.text = "%.0f km/h" % (GameManager.current_speed / 5.0)  # Arbitrary conversion

func _update_distance() -> void:
    distance_label.text = "%.0fm" % (GameManager.distance_traveled / 10.0)

func _on_score_changed(_new_score: int) -> void:
    score_label.text = "Score: %d" % _new_score
    _animate_label(score_label)

func _on_speed_changed(_new_speed: float) -> void:
    speed_label.text = "%.0f km/h" % (_new_speed / 5.0)

func _on_combo_changed(combo: int) -> void:
    combo_label.text = "x%d" % combo

    if combo > 1:
        combo_label.visible = true
        _animate_combo(combo)
    else:
        combo_label.visible = false

func _animate_label(label: Label) -> void:
    var tween = create_tween()
    tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
    tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)

func _animate_combo(combo: int) -> void:
    # Cancel existing tween
    if combo_tween and combo_tween.is_running():
        combo_tween.kill()

    combo_tween = create_tween()
    combo_tween.set_parallel(true)

    # Scale bounce
    combo_label.scale = Vector2(1.5, 1.5)
    combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

    # Color flash (more intense for higher combos)
    var flash_color = Color(1, 1, 0, 1) if combo < 5 else Color(1, 0.5, 0, 1)
    combo_label.modulate = flash_color
    combo_tween.tween_property(combo_label, "modulate", Color.WHITE, 0.3)

func _on_game_started() -> void:
    visible = true
    _update_display()

func _on_game_over(_score: int, _distance: float) -> void:
    # Keep HUD visible to show final stats
    pass

func _on_pause_pressed() -> void:
    GameManager.pause_game()
    # Show pause menu
    get_tree().call_group("pause_menu", "show_menu")
    