extends Node

## Global manager for achievements
## Handles achievement definitions, unlock checking, and rewards

# Signals
signal achievement_unlocked(achievement: Achievement)
signal achievement_progress_updated(achievement_id: String, progress: float)
# Achievement storage
var achievements: Dictionary = {}  # achievement_id -> Achievement


func _ready() -> void:
    _initialize_achievements()
    _load_achievement_progress()
    _connect_to_stats_signals()
    print("AchievementManager: Initialized with %d achievements" % achievements.size())


func _initialize_achievements() -> void:
    """Create all achievement definitions"""

    # === Milestone Achievements ===

    # Speed Bump - Die within 5 seconds
    var speed_bump = Achievement.new()
    speed_bump.achievement_id = "speed_bump"
    speed_bump.achievement_name = "Speed Bump"
    speed_bump.achievement_description = "Die within 5 seconds"
    speed_bump.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    speed_bump.stat_name = "fastest_death_time"
    speed_bump.threshold_value = 5.0
    speed_bump.comparison_op = "<="
    speed_bump.orb_reward = 10
    achievements[speed_bump.achievement_id] = speed_bump

    # Untouchable - Complete 10 daily challenges without dying
    var untouchable = Achievement.new()
    untouchable.achievement_id = "untouchable"
    untouchable.achievement_name = "Untouchable"
    untouchable.achievement_description = "Complete 10 daily challenges without dying"
    untouchable.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    untouchable.stat_name = "daily_challenges_perfect"
    untouchable.threshold_value = 10
    untouchable.comparison_op = ">="
    untouchable.orb_reward = 250
    achievements[untouchable.achievement_id] = untouchable

    # Daily Grind - 10 day streak
    var daily_grind = Achievement.new()
    daily_grind.achievement_id = "daily_grind"
    daily_grind.achievement_name = "Daily Grind"
    daily_grind.achievement_description = "Maintain a 10-day streak"
    daily_grind.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    daily_grind.stat_name = "best_daily_streak"
    daily_grind.threshold_value = 10
    daily_grind.comparison_op = ">="
    daily_grind.orb_reward = 300
    achievements[daily_grind.achievement_id] = daily_grind

    # Collector - Unlock 5 trails
    var collector = Achievement.new()
    collector.achievement_id = "collector"
    collector.achievement_name = "Collector"
    collector.achievement_description = "Unlock 5 trail cosmetics"
    collector.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    collector.stat_name = "cosmetics_unlocked"
    collector.threshold_value = 5
    collector.comparison_op = ">="
    collector.orb_reward = 100
    achievements[collector.achievement_id] = collector

    # Getting Better - Break personal record 10 times
    var getting_better = Achievement.new()
    getting_better.achievement_id = "getting_better"
    getting_better.achievement_name = "Getting Better"
    getting_better.achievement_description = "Break your personal record 10 times"
    getting_better.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    getting_better.stat_name = "personal_records_broken"
    getting_better.threshold_value = 10
    getting_better.comparison_op = ">="
    getting_better.orb_reward = 150
    achievements[getting_better.achievement_id] = getting_better

    # Anxious - Pause 100 times
    var anxious = Achievement.new()
    anxious.achievement_id = "anxious"
    anxious.achievement_name = "Anxious"
    anxious.achievement_description = "Pause the game 100 times"
    anxious.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    anxious.stat_name = "times_paused"
    anxious.threshold_value = 100
    anxious.comparison_op = ">="
    anxious.orb_reward = 50
    achievements[anxious.achievement_id] = anxious

    # === Distance Milestones ===

    # Sprinter - 1,000m total
    var sprinter = Achievement.new()
    sprinter.achievement_id = "sprinter"
    sprinter.achievement_name = "Sprinter"
    sprinter.achievement_description = "Travel 1,000m total distance"
    sprinter.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    sprinter.stat_name = "total_distance"
    sprinter.threshold_value = 1000.0
    sprinter.comparison_op = ">="
    sprinter.orb_reward = 50
    achievements[sprinter.achievement_id] = sprinter

    # Marathon - 10,000m total
    var marathon = Achievement.new()
    marathon.achievement_id = "marathon"
    marathon.achievement_name = "Marathon"
    marathon.achievement_description = "Travel 10,000m total distance"
    marathon.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    marathon.stat_name = "total_distance"
    marathon.threshold_value = 10000.0
    marathon.comparison_op = ">="
    marathon.orb_reward = 200
    achievements[marathon.achievement_id] = marathon

    # Ultra Runner - 50,000m total
    var ultra_runner = Achievement.new()
    ultra_runner.achievement_id = "ultra_runner"
    ultra_runner.achievement_name = "Ultra Runner"
    ultra_runner.achievement_description = "Travel 50,000m total distance"
    ultra_runner.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    ultra_runner.stat_name = "total_distance"
    ultra_runner.threshold_value = 50000.0
    ultra_runner.comparison_op = ">="
    ultra_runner.orb_reward = 500
    achievements[ultra_runner.achievement_id] = ultra_runner

    # === Score Milestones ===

    # Bronze Scorer - 25,000 total points
    var bronze_scorer = Achievement.new()
    bronze_scorer.achievement_id = "bronze_scorer"
    bronze_scorer.achievement_name = "Bronze Scorer"
    bronze_scorer.achievement_description = "Earn 25,000 total points"
    bronze_scorer.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    bronze_scorer.stat_name = "total_score"
    bronze_scorer.threshold_value = 25000
    bronze_scorer.comparison_op = ">="
    bronze_scorer.orb_reward = 100
    achievements[bronze_scorer.achievement_id] = bronze_scorer

    # Silver Scorer - 125,000 total points
    var silver_scorer = Achievement.new()
    silver_scorer.achievement_id = "silver_scorer"
    silver_scorer.achievement_name = "Silver Scorer"
    silver_scorer.achievement_description = "Earn 125,000 total points"
    silver_scorer.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    silver_scorer.stat_name = "total_score"
    silver_scorer.threshold_value = 125000
    silver_scorer.comparison_op = ">="
    silver_scorer.orb_reward = 250
    achievements[silver_scorer.achievement_id] = silver_scorer

    # Gold Scorer - 500,000 total points
    var gold_scorer = Achievement.new()
    gold_scorer.achievement_id = "gold_scorer"
    gold_scorer.achievement_name = "Gold Scorer"
    gold_scorer.achievement_description = "Earn 500,000 total points"
    gold_scorer.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    gold_scorer.stat_name = "total_score"
    gold_scorer.threshold_value = 500000
    gold_scorer.comparison_op = ">="
    gold_scorer.orb_reward = 500
    achievements[gold_scorer.achievement_id] = gold_scorer

    # Platinum Scorer - 1,000,000 total points
    var platinum_scorer = Achievement.new()
    platinum_scorer.achievement_id = "platinum_scorer"
    platinum_scorer.achievement_name = "Platinum Scorer"
    platinum_scorer.achievement_description = "Earn 1,000,000 total points"
    platinum_scorer.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    platinum_scorer.stat_name = "total_score"
    platinum_scorer.threshold_value = 1000000
    platinum_scorer.comparison_op = ">="
    platinum_scorer.orb_reward = 1000
    achievements[platinum_scorer.achievement_id] = platinum_scorer

    # === Skill Milestones ===

    # Perfectionist - Collect 100% collectibles in daily run
    var perfectionist = Achievement.new()
    perfectionist.achievement_id = "perfectionist"
    perfectionist.achievement_name = "Perfectionist"
    perfectionist.achievement_description = "Collect 100% of collectibles in a daily challenge"
    perfectionist.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    perfectionist.stat_name = "best_daily_collectible_percentage"
    perfectionist.threshold_value = 100.0
    perfectionist.comparison_op = ">="
    perfectionist.orb_reward = 200
    achievements[perfectionist.achievement_id] = perfectionist

    # Speed Demon - Complete daily in under 10s
    var speed_demon = Achievement.new()
    speed_demon.achievement_id = "speed_demon"
    speed_demon.achievement_name = "Speed Demon"
    speed_demon.achievement_description = "Complete a daily challenge in under 10 seconds"
    speed_demon.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    speed_demon.stat_name = "best_daily_completion_time"
    speed_demon.threshold_value = 10.0
    speed_demon.comparison_op = "<="
    speed_demon.orb_reward = 300
    achievements[speed_demon.achievement_id] = speed_demon

    # Near Miss - Pass within 5px of obstacle
    var near_miss = Achievement.new()
    near_miss.achievement_id = "near_miss"
    near_miss.achievement_name = "Near Miss"
    near_miss.achievement_description = "Pass within 5px of an obstacle"
    near_miss.criteria_type = Achievement.CriteriaType.STAT_THRESHOLD
    near_miss.stat_name = "closest_obstacle_pass"
    near_miss.threshold_value = 5.0
    near_miss.comparison_op = "<="
    near_miss.orb_reward = 150
    achievements[near_miss.achievement_id] = near_miss


func _connect_to_stats_signals() -> void:
    """Connect to StatsManager signals to check achievements"""
    if StatsManager:
        StatsManager.stat_changed.connect(_on_stat_changed)
        StatsManager.death_recorded.connect(_on_death_recorded)
        StatsManager.daily_streak_updated.connect(_on_daily_streak_updated)
        StatsManager.personal_record_broken.connect(_on_personal_record_broken)
        StatsManager.proximity_record_broken.connect(_on_proximity_record_broken)


func _on_stat_changed(stat_name: String, _new_value) -> void:
    """Check achievements when any stat changes"""
    _check_all_achievements()


func _on_death_recorded(_obstacle_type: String, _total_deaths: int) -> void:
    """Check achievements when player dies"""
    _check_all_achievements()


func _on_daily_streak_updated(_streak: int) -> void:
    """Check achievements when daily streak changes"""
    _check_all_achievements()


func _on_personal_record_broken() -> void:
    """Check achievements when personal record is broken"""
    _check_all_achievements()


func _on_proximity_record_broken(_distance: float) -> void:
    """Check achievements when proximity record is broken"""
    _check_all_achievements()


func _check_all_achievements() -> void:
    """Check all unlocked achievements against current stats"""
    for achievement_id in achievements:
        var achievement = achievements[achievement_id]
        if not achievement.is_unlocked():
            if achievement.check_unlock_criteria(StatsManager):
                _unlock_achievement(achievement)


func _unlock_achievement(achievement: Achievement) -> void:
    """Unlock an achievement and grant rewards"""
    achievement.unlock()

    print("Achievement Unlocked: %s - %s" % [achievement.achievement_name, achievement.achievement_description])

    # Grant orb reward
    #	if achievement.orb_reward > 0:
    #		SaveManager.add_orbs(achievement.orb_reward)
    #		print("  Reward: %d orbs" % achievement.orb_reward)

    # Unlock cosmetic if specified
    #    if achievement.unlocks_cosmetic != "":
    #        if CosmeticManager:
    #            # Award cosmetic without spending orbs
    #            SaveManager.unlock_cosmetic(achievement.unlocks_cosmetic)
    #            print("  Reward: Unlocked cosmetic '%s'" % achievement.unlocks_cosmetic)

    # Save achievement progress
    _save_achievement_progress()

    # Emit signal for UI
    achievement_unlocked.emit(achievement)


func get_achievement(achievement_id: String) -> Achievement:
    """Get an achievement by ID"""
    return achievements.get(achievement_id, null)


func get_all_achievements() -> Array[Achievement]:
    """Get all achievements as an array"""
    var result: Array[Achievement] = []
    for achievement in achievements.values():
        result.append(achievement)
    return result


func get_unlocked_achievements() -> Array[Achievement]:
    """Get only unlocked achievements"""
    var result: Array[Achievement] = []
    for achievement in achievements.values():
        if achievement.is_unlocked():
            result.append(achievement)
    return result


func get_locked_achievements() -> Array[Achievement]:
    """Get only locked achievements"""
    var result: Array[Achievement] = []
    for achievement in achievements.values():
        if not achievement.is_unlocked():
            result.append(achievement)
    return result


func get_achievement_progress(achievement_id: String) -> float:
    """Get progress toward achievement (0.0 to 1.0)"""
    var achievement = get_achievement(achievement_id)
    if achievement:
        return achievement.get_progress(StatsManager)
    return 0.0


func get_total_unlocked_count() -> int:
    """Get total number of unlocked achievements"""
    var count = 0
    for achievement in achievements.values():
        if achievement.is_unlocked():
            count += 1
    return count


func get_completion_percentage() -> float:
    """Get percentage of achievements unlocked"""
    if achievements.size() == 0:
        return 0.0
    return (float(get_total_unlocked_count()) / float(achievements.size())) * 100.0


# Persistence
func _save_achievement_progress() -> void:
    """Save achievement progress to SaveManager"""
    var achievement_data = {}
    for achievement_id in achievements:
        var achievement = achievements[achievement_id]
        achievement_data[achievement_id] = achievement.to_dict()

    SaveManager.save_achievements(achievement_data)


func _load_achievement_progress() -> void:
    """Load achievement progress from SaveManager"""
    var achievement_data = SaveManager.load_achievements()

    for achievement_id in achievement_data:
        if achievements.has(achievement_id):
            var achievement = achievements[achievement_id]
            achievement.from_dict(achievement_data[achievement_id])


# Debug methods
func unlock_achievement_debug(achievement_id: String) -> void:
    """Force unlock an achievement (for testing)"""
    var achievement = get_achievement(achievement_id)
    if achievement and not achievement.is_unlocked():
        _unlock_achievement(achievement)


func reset_all_achievements() -> void:
    """Reset all achievements (for testing)"""
    for achievement in achievements.values():
        achievement.unlock_date = ""
        achievement.is_new = false
    _save_achievement_progress()
    print("All achievements reset")


func print_achievements() -> void:
    """Print all achievements and their status (for debugging)"""
    print("=== Achievements ===")
    print("Total: %d, Unlocked: %d (%.1f%%)" % [
    achievements.size(),
    get_total_unlocked_count(),
    get_completion_percentage()
    ])
    print("")

    for achievement_id in achievements:
        var achievement = achievements[achievement_id]
        var status      = "UNLOCKED" if achievement.is_unlocked() else "LOCKED"
        var progress    = achievement.get_progress(StatsManager) * 100.0
        print("[%s] %s - %s (%.1f%%)" % [
        status,
        achievement.achievement_name,
        achievement.achievement_description,
        progress
        ])
    print("===================")
