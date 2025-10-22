extends Node

# TODO: change 'res' to 'user'
const SAVE_PATH = "res://neon_drift_save.json"

# Save data structure
var save_data = {
                    "high_score": 0,
                    "longest_distance": 0.0,
                    "games_played": 0,
                    "total_orbs_collected": 0,
                    "current_orbs": 0,
                    "unlocked_trails": ["default"],
                    "selected_trail": "default",
                    "unlocked_collectibles": ["orb"], # Orbs always unlocked by default
                    "sfx_volume": 1.0,
                    "music_volume": 0.4,
                    "first_launch": true,
                    "daily_challenge_completed": false,
                    "last_daily_completion_date": "",
                    "stats": {}, # StatsManager data
                    "achievements": {},  # AchievementManager data
                    "review_data": {  # ReviewManager data
                        "games_since_last_prompt": 0,
                        "review_prompt_shown_count": 0,
                        "last_review_prompt_date": "",
                        "user_dismissed_permanently": false,
                        "user_left_review": false
                    }
                }


func _ready() -> void:
    _load_save_data()


func save_high_score(score: int) -> void:
    save_data.high_score = score
    _write_save_data()


func load_high_score() -> int:
    return save_data.high_score


func save_longest_distance(distance: float) -> void:
    save_data.longest_distance = distance
    _write_save_data()


func load_longest_distance() -> float:
    return save_data.longest_distance


func increment_games_played() -> void:
    save_data.games_played += 1
    _write_save_data()


func add_orbs_collected(count: int) -> void:
    save_data.total_orbs_collected += count
    _write_save_data()


func add_orbs(count: int) -> void:
    """Add orbs to both total_orbs_collected and current_orbs"""
    save_data.total_orbs_collected += count
    save_data.current_orbs += count
    _write_save_data()
    Events.orb_count_updated.emit()


func spend_orbs(amount: int) -> bool:
    """
    Spend orbs from current_orbs if player can afford it
    Returns true if purchase succeeded
    """
    if save_data.current_orbs >= amount:
        save_data.current_orbs -= amount
        _write_save_data()
        Events.orb_count_updated.emit()
        return true
    return false


func get_current_orbs() -> int:
    """Get the player's current orb balance"""
    return save_data.current_orbs


func get_total_orbs_collected() -> int:
    """Get the total orbs collected over all time"""
    return save_data.total_orbs_collected


# Stats persistence
func save_stats(stats: Dictionary) -> void:
    """Save stats data from StatsManager"""
    save_data.stats = stats
    _write_save_data()


func load_stats() -> Dictionary:
    """Load stats data for StatsManager"""
    if save_data.has("stats"):
        return save_data.stats
    return {}


# Achievement persistence
func save_achievements(achievements: Dictionary) -> void:
    """Save achievements data from AchievementManager"""
    save_data.achievements = achievements
    _write_save_data()


func load_achievements() -> Dictionary:
    """Load achievements data for AchievementManager"""
    if save_data.has("achievements"):
        return save_data.achievements
    return {}


func unlock_trail(trail_id: String) -> void:
    if not trail_id in save_data.unlocked_trails:
        save_data.unlocked_trails.append(trail_id)
        _write_save_data()


func is_trail_unlocked(trail_id: String) -> bool:
    return trail_id in save_data.unlocked_trails


# Cosmetic system compatibility (forwards to trail methods)
func unlock_cosmetic(cosmetic_id: String) -> void:
    unlock_trail(cosmetic_id)


func is_cosmetic_unlocked(cosmetic_id: String) -> bool:
    return is_trail_unlocked(cosmetic_id)


# Collectible system
func unlock_collectible(collectible_id: String) -> void:
    if not save_data.has("unlocked_collectibles"):
        save_data.unlocked_collectibles = ["orb"]  # Ensure orb is always there
    if not collectible_id in save_data.unlocked_collectibles:
        save_data.unlocked_collectibles.append(collectible_id)
        _write_save_data()


func is_collectible_unlocked(collectible_id: String) -> bool:
    if not save_data.has("unlocked_collectibles"):
        return collectible_id == "orb"  # Orb always unlocked
    return collectible_id in save_data.unlocked_collectibles


func save_game() -> void:
    _write_save_data()


func set_selected_trail(trail_id: String) -> void:
    if is_trail_unlocked(trail_id):
        save_data.selected_trail = trail_id
        _write_save_data()


func get_selected_trail() -> String:
    return save_data.selected_trail


func save_audio_settings(sfx: float, music: float) -> void:
    save_data.sfx_volume = sfx
    save_data.music_volume = music
    _write_save_data()


func get_sfx_volume() -> float:
    return save_data.sfx_volume


func get_music_volume() -> float:
    return save_data.music_volume


func is_first_launch() -> bool:
    return save_data.first_launch


func set_first_launch_complete() -> void:
    save_data.first_launch = false
    _write_save_data()


func mark_daily_challenge_complete() -> void:
    save_data.daily_challenge_completed = true
    save_data.last_daily_completion_date = _get_date_string()
    _write_save_data()


func is_daily_challenge_completed() -> bool:
    return save_data.daily_challenge_completed


func check_and_reset_daily_challenge() -> void:
    # Check if it's a new day
    var today = _get_date_string()
    if save_data.last_daily_completion_date != today:
        save_data.daily_challenge_completed = false
        _write_save_data()


func can_afford_buyable(cost: int) -> bool:
    return cost <= save_data.current_orbs


func _get_date_string() -> String:
    var date = Time.get_date_dict_from_system()
    return "%d-%02d-%02d" % [date.year, date.month, date.day]


func _load_save_data() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        print("No save file found, using defaults")
        return

    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        file.close()

        var json         = JSON.new()
        var parse_result = json.parse(json_string)

        if parse_result == OK:
            var loaded_data = json.get_data()
            # Merge loaded data with defaults (in case new fields were added)
            for key in loaded_data:
                if key in save_data:
                    save_data[key] = loaded_data[key]
            print("Save data loaded successfully")
        else:
            push_error("Failed to parse save file")


func _write_save_data() -> void:
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        var json_string = JSON.stringify(save_data, "\t")
        file.store_string(json_string)
        file.close()
    else:
        push_error("Failed to write save file")


func reset_save_data() -> void:
    save_data = {
        "high_score": 0,
        "longest_distance": 0.0,
        "games_played": 0,
        "total_orbs_collected": 0,
        "current_orbs": 0,
        "unlocked_trails": ["default"],
        "selected_trail": "default",
        "unlocked_collectibles": ["orb"],
        "sfx_volume": 0.8,
        "music_volume": 0.6,
        "first_launch": false,
        "daily_challenge_completed": false,
        "last_daily_completion_date": "",
        "stats": {},
        "achievements": {},
        "review_data": {
            "games_since_last_prompt": 0,
            "review_prompt_shown_count": 0,
            "last_review_prompt_date": "",
            "user_dismissed_permanently": false,
            "user_left_review": false
        }
    }
    _write_save_data()


# Review data persistence
func save_review_data(review_data: Dictionary) -> void:
    """Save review data from ReviewManager"""
    save_data.review_data = review_data
    _write_save_data()


func load_review_data() -> Dictionary:
    """Load review data for ReviewManager"""
    if save_data.has("review_data"):
        return save_data.review_data
    return {}