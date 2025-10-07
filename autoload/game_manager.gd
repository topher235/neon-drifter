extends Node

# Signals
signal game_started
signal game_over(final_score: int, distance: float)
signal game_paused
signal game_resumed
signal score_changed(new_score: int)
signal speed_changed(new_speed: float)
signal combo_changed(combo: int)

# Game State
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
enum GameMode { CLASSIC, DAILY_CHALLENGE }
var current_state: GameState = GameState.MENU
var current_game_mode: GameMode = GameMode.CLASSIC

# Score System
var current_score: int = 0
var combo_multiplier: int = 1
var max_combo: int = 0
var orbs_collected: int = 0

# Distance & Speed
var distance_traveled: float = 0.0
var current_speed: float = 300.0
var base_speed: float = 300.0
var max_speed: float = 800.0
var speed_increase_rate: float = 2.0  # pixels/sec increase per second
var speed_boost_multiplier: float = 1.5
var speed_boost_duration: float = 0.0
var slowdown_multiplier: float = 1.0
var slowdown_duration: float = 0.0

# Difficulty
var game_time: float = 0.0
var difficulty: float = 0.0

# Daily Challenge
var daily_seed: int = 0

# High Scores
var high_score: int = 0
var longest_distance: float = 0.0

func _ready() -> void:
    daily_seed = _calculate_daily_seed()
    _load_high_scores()
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    if current_state == GameState.PLAYING:
        _update_game_time(delta)
        _update_speed(delta)
        _update_distance(delta)
        _update_difficulty()

func start_game() -> void:
    current_state = GameState.PLAYING
    current_score = 0
    combo_multiplier = 1
    max_combo = 0
    orbs_collected = 0
    distance_traveled = 0.0
    current_speed = base_speed
    game_time = 0.0
    difficulty = 0.0
    speed_boost_duration = 0.0
    slowdown_multiplier = 1.0
    slowdown_duration = 0.0
    game_started.emit()
    print("Game started")

func end_game() -> void:
    if current_state != GameState.PLAYING:
        return

    current_state = GameState.GAME_OVER
    _check_high_scores()
    game_over.emit(current_score, distance_traveled)
    print("Game Over - Score: %d, Distance: %.1f" % [current_score, distance_traveled])

func pause_game() -> void:
    if current_state == GameState.PLAYING:
        current_state = GameState.PAUSED
        get_tree().paused = true
        game_paused.emit()

func resume_game() -> void:
    if current_state == GameState.PAUSED:
        current_state = GameState.PLAYING
        get_tree().paused = false
        game_resumed.emit()

func return_to_menu() -> void:
    get_tree().paused = false
    current_state = GameState.MENU

# Score Management
func add_score(points: int) -> void:
    var actual_points = points * combo_multiplier
    current_score += actual_points
    score_changed.emit(current_score)

func increase_combo() -> void:
    combo_multiplier = min(combo_multiplier + 1, 10)  # Max 10x
    max_combo = max(max_combo, combo_multiplier)
    combo_changed.emit(combo_multiplier)

func reset_combo() -> void:
    combo_multiplier = 1
    combo_changed.emit(combo_multiplier)

func collect_orb(value: int) -> void:
    orbs_collected += 1
    add_score(value)
    increase_combo()

func activate_speed_boost(duration: float) -> void:
    speed_boost_duration = duration

func activate_slowdown(duration: float, factor: float) -> void:
    slowdown_duration = duration
    slowdown_multiplier = factor
    print("Slowdown activated: ", factor, "x for ", duration, "s")

# Speed & Distance
func _update_game_time(delta: float) -> void:
    game_time += delta

func _update_speed(delta: float) -> void:
    # Natural speed increase
    var target_speed = min(base_speed + (game_time * speed_increase_rate), max_speed)

    # Apply speed boost
    if speed_boost_duration > 0.0:
        speed_boost_duration -= delta
        target_speed *= speed_boost_multiplier

    # Apply slowdown
    if slowdown_duration > 0.0:
        slowdown_duration -= delta
        target_speed *= slowdown_multiplier
        if slowdown_duration <= 0.0:
            slowdown_multiplier = 1.0

    current_speed = target_speed
    speed_changed.emit(current_speed)

func _update_distance(delta: float) -> void:
    distance_traveled += current_speed * delta
    # Every 100 pixels = 1 point
    var distance_score = int(distance_traveled / 100.0)
    if distance_score > int((distance_traveled - current_speed * delta) / 100.0):
        add_score(1)

func _update_difficulty() -> void:
    # Difficulty scales from 0 to 10 based on time and speed
    var time_factor = game_time / 60.0  # 0 to ~1 over first minute
    var speed_factor = (current_speed - base_speed) / (max_speed - base_speed)
    difficulty = clamp((time_factor * 5.0) + (speed_factor * 5.0), 0.0, 10.0)

# Daily Seed
func _calculate_daily_seed() -> int:
    var date = Time.get_date_dict_from_system()
    return date.year * 10000 + date.month * 100 + date.day

# High Scores
func _check_high_scores() -> void:
    if current_score > high_score:
        high_score = current_score
        SaveManager.save_high_score(high_score)

    if distance_traveled > longest_distance:
        longest_distance = distance_traveled
        SaveManager.save_longest_distance(longest_distance)

func _load_high_scores() -> void:
    high_score = SaveManager.load_high_score()
    longest_distance = SaveManager.load_longest_distance()

# Utility
func get_difficulty() -> float:
    return difficulty

func is_playing() -> bool:
    return current_state == GameState.PLAYING