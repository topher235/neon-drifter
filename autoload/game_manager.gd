extends Node

# Signals
signal game_started
signal game_over(final_score: int, distance: float)
signal game_paused
signal game_resumed
signal score_changed(new_score: int)
signal speed_changed(new_speed: float)
signal combo_changed(combo: int)
signal timer_changed(time_remaining: float)
signal orb_multiplier_changed(active: bool, time_remaining: float)
# Game State
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
enum GameMode { CLASSIC, DAILY_CHALLENGE, RUSH }
var current_state: GameState    = GameState.MENU
var current_game_mode: GameMode = GameMode.CLASSIC
# Score System
var current_score: int    = 0
var combo_multiplier: int = 1
var max_combo: int        = 0
var orbs_collected: int   = 0
# Distance & Speed
var distance_traveled: float       = 0.0
var current_speed: float           = 300.0
var base_speed: float              = 300.0
var max_speed: float               = 800.0
var speed_increase_rate: float     = 2.0  # speed increase per distance milestone
var speed_increase_interval: float = 20.0  # distance units between speed increases
var speed_boost_multiplier: float  = 1.5
var speed_boost_duration: float    = 0.0
var slowdown_multiplier: float     = 1.0
var slowdown_duration: float       = 0.0
var orb_multiplier_active: bool    = false
var orb_multiplier_duration: float = 0.0
var orb_point_multiplier: int      = 2  # Doubles orb value
# Difficulty
var game_time: float  = 0.0
var difficulty: float = 0.0
# Seeds & Challenges
var daily_seed: int                       = 0
var rush_seed: int                        = 0  # User-specified seed for RUSH mode
var current_run_seed: int                 = 0  # The actual seed used for the current run (for retry)
var daily_challenge_time_limit: float     = 40.0
var daily_challenge_time_remaining: float = 40.0
var rush_time_limit: float                = 60.0  # RUSH mode has 60 seconds
var rush_time_remaining: float            = 60.0
# High Scores
var high_score: int         = 0
var longest_distance: float = 0.0
# Death tracking
var death_cause: String = ""  # "pillar", "pulse_gate", "timeout"
# Collectible tracking (for daily challenge stats)
var total_collectibles_in_run: int     = 0
var collectibles_collected_in_run: int = 0


func _ready() -> void:
    daily_seed = _calculate_daily_seed()
    _load_high_scores()
    SaveManager.check_and_reset_daily_challenge()  # Reset daily challenge flag on new day
    process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
    if current_state == GameState.PLAYING:
        _update_game_time(delta)
        _update_speed(delta)
        _update_distance(delta)
        _update_difficulty()
        _update_daily_challenge_timer(delta)
        _update_orb_multiplier(delta)


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
    orb_multiplier_active = false
    orb_multiplier_duration = 0.0
    death_cause = ""  # Reset death cause
    total_collectibles_in_run = 0
    collectibles_collected_in_run = 0

    # Initialize timers for timed modes
    if current_game_mode == GameMode.DAILY_CHALLENGE:
        daily_challenge_time_remaining = daily_challenge_time_limit
        timer_changed.emit(daily_challenge_time_remaining)
    elif current_game_mode == GameMode.RUSH:
        rush_time_remaining = rush_time_limit
        timer_changed.emit(rush_time_remaining)

    game_started.emit()
    print("Game started")


func end_game() -> void:
    if current_state != GameState.PLAYING:
        return

    current_state = GameState.GAME_OVER

    # Record stats before checking high scores
    StatsManager.add_distance(distance_traveled)
    StatsManager.add_score(current_score)

    # Record death if there was one
    if death_cause != "":
        StatsManager.record_death(death_cause, game_time)

    _check_high_scores()

    # Add collected orbs to player's totals
    if orbs_collected > 0:
        SaveManager.add_orbs(orbs_collected)

    game_over.emit(current_score, distance_traveled)
    print("Game Over - Score: %d, Distance: %.1f, Orbs: %d" % [current_score, distance_traveled, orbs_collected])


func complete_daily_challenge() -> void:
    # Called when player reaches the end segment in daily challenge mode
    if current_state != GameState.PLAYING:
        return

    print("Daily Challenge Complete!")

    # Calculate time bonus based on remaining time
    var time_bonus = _calculate_time_bonus(daily_challenge_time_remaining)
    if time_bonus > 0:
        add_score(time_bonus)
        print("Time bonus: %d points (%.2f seconds remaining)" % [time_bonus, daily_challenge_time_remaining])

    # Calculate collectible percentage
    var collectible_percent = 0.0
    if total_collectibles_in_run > 0:
        collectible_percent = (float(collectibles_collected_in_run) / float(total_collectibles_in_run)) * 100.0

    # Record stats
    var completion_time = daily_challenge_time_limit - daily_challenge_time_remaining
    StatsManager.record_daily_challenge_complete(false, completion_time, collectible_percent)

    # Mark daily challenge as completed
    SaveManager.mark_daily_challenge_complete()

    end_game()  # Use the normal end game flow


func complete_rush_challenge() -> void:
    # Called when player reaches the end segment in RUSH mode
    if current_state != GameState.PLAYING:
        return

    print("RUSH Challenge Complete!")

    # Calculate time bonus based on remaining time
    var time_bonus = _calculate_time_bonus(rush_time_remaining)
    if time_bonus > 0:
        add_score(time_bonus)
        print("Time bonus: %d points (%.2f seconds remaining)" % [time_bonus, rush_time_remaining])

    # Record stats
    var completion_time = rush_time_limit - rush_time_remaining
    StatsManager.record_rush_challenge_complete(false, completion_time)

    end_game()  # Use the normal end game flow


func _calculate_time_bonus(time_remaining: float) -> int:
    # Time bonus calculation for daily challenge
    # More time remaining = higher bonus
    # Base thresholds (with 60s time limit):
    # - 40s+ remaining: 1000 bonus (completed in under 20s)
    # - 30s+ remaining: 750 bonus (completed in under 30s)
    # - 20s+ remaining: 500 bonus (completed in under 40s)
    # - 10s+ remaining: 250 bonus (completed in under 50s)
    # - 0s+ remaining: 100 bonus (completed in under 60s)

    if time_remaining >= 40.0:
        return 1000
    elif time_remaining >= 30.0:
        return 750
    elif time_remaining >= 20.0:
        return 500
    elif time_remaining >= 10.0:
        return 250
    else:
        return 100


func pause_game() -> void:
    if current_state == GameState.PLAYING:
        current_state = GameState.PAUSED
        get_tree().paused = true
        StatsManager.record_pause()
        game_paused.emit()


func resume_game() -> void:
    if current_state == GameState.PAUSED:
        current_state = GameState.PLAYING
        get_tree().paused = false
        game_resumed.emit()


func return_to_menu() -> void:
    get_tree().paused = false
    current_state = GameState.MENU
    # Clear the current run seed so next game gets a fresh seed
    current_run_seed = 0


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
    # Apply orb multiplier if active
    var actual_value = value
    if orb_multiplier_active:
        actual_value = value * orb_point_multiplier
    add_score(actual_value)
    increase_combo()


func activate_speed_boost(duration: float) -> void:
    speed_boost_duration = duration


func activate_slowdown(duration: float, factor: float) -> void:
    slowdown_duration = duration
    slowdown_multiplier = factor
    print("Slowdown activated: ", factor, "x for ", duration, "s")


func activate_orb_multiplier(duration: float) -> void:
    orb_multiplier_active = true
    orb_multiplier_duration = duration
    orb_multiplier_changed.emit(true, duration)
    print("Orb multiplier activated: %dx for %.1fs" % [orb_point_multiplier, duration])


func add_daily_challenge_time(bonus_time: float) -> void:
    if current_game_mode == GameMode.DAILY_CHALLENGE:
        daily_challenge_time_remaining += bonus_time
        # Cap at the original time limit
        daily_challenge_time_remaining = min(daily_challenge_time_remaining, daily_challenge_time_limit)
        timer_changed.emit(daily_challenge_time_remaining)
        print("Time bonus collected: +%.1fs (now: %.1fs)" % [bonus_time, daily_challenge_time_remaining])
    elif current_game_mode == GameMode.RUSH:
        rush_time_remaining += bonus_time
        # Cap at the original time limit
        rush_time_remaining = min(rush_time_remaining, rush_time_limit)
        timer_changed.emit(rush_time_remaining)
        print("Time bonus collected: +%.1fs (now: %.1fs)" % [bonus_time, rush_time_remaining])


# Speed & Distance
func _update_game_time(delta: float) -> void:
    game_time += delta


func _update_speed(delta: float) -> void:
    # Natural speed increase based on distance traveled
    # Calculate how many distance milestones have been reached
    var distance_milestones = floor(distance_traveled / speed_increase_interval)
    var target_speed        = min(base_speed + (distance_milestones * speed_increase_rate), max_speed)

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
            Events.crt_disabled.emit()

    current_speed = target_speed
    speed_changed.emit(current_speed)


func _update_distance(delta: float) -> void:
    # Divide distance by 10 so we're working with smaller numbers
    distance_traveled += (current_speed * delta) / 10
    # Every 100 pixels = 1 point (only in classic mode)
    if current_game_mode == GameMode.CLASSIC:
        var distance_score = int(distance_traveled / 100.0)
        if distance_score > int((distance_traveled - current_speed * delta) / 100.0):
            add_score(1)


func _update_difficulty() -> void:
    # Difficulty scales from 0 to 10 based on time and speed
    var time_factor  = game_time / 60.0  # 0 to ~1 over first minute
    var speed_factor = (current_speed - base_speed) / (max_speed - base_speed)
    difficulty = clamp((time_factor * 5.0) + (speed_factor * 5.0), 0.0, 10.0)


func _update_daily_challenge_timer(delta: float) -> void:
    # Update timer for both daily challenge and rush modes
    if current_game_mode == GameMode.DAILY_CHALLENGE:
        daily_challenge_time_remaining -= delta
        timer_changed.emit(daily_challenge_time_remaining)

        # Check if time has run out
        if daily_challenge_time_remaining <= 0.0:
            daily_challenge_time_remaining = 0.0
            print("Daily Challenge: Time's up!")
            death_cause = "timeout"
            end_game()  # Player dies as if they hit an obstacle
    elif current_game_mode == GameMode.RUSH:
        rush_time_remaining -= delta
        timer_changed.emit(rush_time_remaining)

        # Check if time has run out
        if rush_time_remaining <= 0.0:
            rush_time_remaining = 0.0
            print("RUSH Mode: Time's up!")
            death_cause = "timeout"
            end_game()  # Player dies as if they hit an obstacle


func _update_orb_multiplier(delta: float) -> void:
    if orb_multiplier_active:
        orb_multiplier_duration -= delta
        orb_multiplier_changed.emit(true, orb_multiplier_duration)

        if orb_multiplier_duration <= 0.0:
            orb_multiplier_active = false
            orb_multiplier_duration = 0.0
            orb_multiplier_changed.emit(false, 0.0)
            print("Orb multiplier expired")


# Seed Management
func _calculate_daily_seed() -> int:
    var date = Time.get_date_dict_from_system()
    return date.year * 10000 + date.month * 100 + date.day


func get_current_seed() -> int:
    """Returns the appropriate seed based on current game mode"""
    var seed_value: int

    match current_game_mode:
        GameMode.DAILY_CHALLENGE:
            # For daily challenge, use stored seed if retrying, otherwise use daily seed
            if current_run_seed != 0:
                seed_value = current_run_seed
            else:
                seed_value = daily_seed
        GameMode.RUSH:
            # For RUSH mode, use stored seed if retrying, otherwise use rush seed
            if current_run_seed != 0:
                seed_value = current_run_seed
            else:
                seed_value = rush_seed
        GameMode.CLASSIC:
            # For classic mode, use stored seed if retrying, otherwise generate new
            if current_run_seed != 0:
                seed_value = current_run_seed
            else:
                seed_value = randi()
        _:
            seed_value = randi()

    # Store the seed for retry functionality
    current_run_seed = seed_value
    return seed_value


func set_rush_seed(seed_value: int) -> void:
    """Set the seed to be used for RUSH mode"""
    rush_seed = seed_value
    print("RUSH seed set to: %d" % rush_seed)


func get_current_run_seed() -> int:
    """Returns the seed being used for the current run (useful for displaying to player)"""
    return current_run_seed


# High Scores
func _check_high_scores() -> void:
    var broke_record = false

    if current_score > high_score:
        high_score = current_score
        SaveManager.save_high_score(high_score)
        broke_record = true

    if distance_traveled > longest_distance:
        longest_distance = distance_traveled
        SaveManager.save_longest_distance(longest_distance)
        broke_record = true

    if broke_record:
        StatsManager.record_personal_record_broken()


func _load_high_scores() -> void:
    high_score = SaveManager.load_high_score()
    longest_distance = SaveManager.load_longest_distance()


# Utility
func get_difficulty() -> float:
    return difficulty


func is_playing() -> bool:
    return current_state == GameState.PLAYING


# Death tracking
func record_obstacle_death(obstacle_type: String) -> void:
    """Called by player when they hit an obstacle"""
    death_cause = obstacle_type


# Collectible tracking
func register_collectible() -> void:
    """Called when a collectible is spawned in the level"""
    total_collectibles_in_run += 1


func record_collectible_collected() -> void:
    """Called when player collects a collectible"""
    collectibles_collected_in_run += 1