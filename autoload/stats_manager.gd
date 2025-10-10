extends Node

## Central statistics tracking manager
## Tracks all player statistics and emits signals for achievement checking

# Signals
signal stat_changed(stat_name: String, new_value)
signal death_recorded(obstacle_type: String, total_deaths: int)
signal daily_streak_updated(streak: int)
signal personal_record_broken()
signal proximity_record_broken(distance: float)

# Stats data structure
var stats_data = {
	# Death tracking
	"deaths_by_pillar": 0,
	"deaths_by_pulse_gate": 0,
	"deaths_by_timeout": 0,
	"total_deaths": 0,

	# Distance & Score (cumulative across all runs)
	"total_distance": 0.0,
	"total_score": 0,

	# Daily challenge tracking
	"daily_challenges_completed": 0,
	"daily_challenges_perfect": 0,  # Completed without dying
	"current_daily_streak": 0,
	"best_daily_streak": 0,
	"last_daily_played_date": "",
	"best_daily_completion_time": 999.0,
	"best_daily_collectible_percentage": 0.0,

	# RUSH challenge tracking
	"rush_challenges_completed": 0,
	"rush_challenges_perfect": 0,
	"best_rush_completion_time": 999.0,

	# Milestones
	"personal_records_broken": 0,
	"times_paused": 0,
	"cosmetics_unlocked": 0,

	# Proximity tracking
	"closest_obstacle_pass": 999.0,  # Closest distance in pixels

	# Fast death tracking
	"fastest_death_time": 999.0  # Death within 5 seconds
}


func _ready() -> void:
	_load_stats()


# Death tracking
func record_death(obstacle_type: String, time_survived: float) -> void:
	"""Record a player death by obstacle type"""
	stats_data.total_deaths += 1

	match obstacle_type:
		"pillar":
			stats_data.deaths_by_pillar += 1
		"pulse_gate":
			stats_data.deaths_by_pulse_gate += 1
		"timeout":
			stats_data.deaths_by_timeout += 1

	# Track fastest death (for "Speed Bump" achievement)
	if time_survived < stats_data.fastest_death_time:
		stats_data.fastest_death_time = time_survived
		stat_changed.emit("fastest_death_time", time_survived)

	death_recorded.emit(obstacle_type, stats_data.total_deaths)
	stat_changed.emit("total_deaths", stats_data.total_deaths)
	_save_stats()


func get_deaths_by_type(type: String) -> int:
	"""Get death count for specific obstacle type"""
	match type:
		"pillar":
			return stats_data.deaths_by_pillar
		"pulse_gate":
			return stats_data.deaths_by_pulse_gate
		"timeout":
			return stats_data.deaths_by_timeout
	return 0


func get_total_deaths() -> int:
	"""Get total death count across all types"""
	return stats_data.total_deaths


# Streak management
func update_daily_streak() -> void:
	"""Update daily challenge streak (call when daily completed)"""
	var today = _get_date_string()

	# Check if this is consecutive day
	if stats_data.last_daily_played_date == "":
		# First ever daily
		stats_data.current_daily_streak = 1
	elif _is_consecutive_day(stats_data.last_daily_played_date, today):
		stats_data.current_daily_streak += 1
	else:
		# Streak broken, reset to 1
		stats_data.current_daily_streak = 1

	stats_data.last_daily_played_date = today

	# Update best streak
	if stats_data.current_daily_streak > stats_data.best_daily_streak:
		stats_data.best_daily_streak = stats_data.current_daily_streak

	daily_streak_updated.emit(stats_data.current_daily_streak)
	stat_changed.emit("current_daily_streak", stats_data.current_daily_streak)
	stat_changed.emit("best_daily_streak", stats_data.best_daily_streak)
	_save_stats()


func break_daily_streak() -> void:
	"""Reset daily streak to 0"""
	stats_data.current_daily_streak = 0
	daily_streak_updated.emit(0)
	stat_changed.emit("current_daily_streak", 0)
	_save_stats()


func get_current_daily_streak() -> int:
	"""Get current daily challenge streak"""
	return stats_data.current_daily_streak


func get_best_daily_streak() -> int:
	"""Get best daily challenge streak"""
	return stats_data.best_daily_streak


# Distance & Score
func add_distance(distance: float) -> void:
	"""Add distance from completed run"""
	stats_data.total_distance += distance
	stat_changed.emit("total_distance", stats_data.total_distance)
	_save_stats()


func add_score(score: int) -> void:
	"""Add score from completed run"""
	stats_data.total_score += score
	stat_changed.emit("total_score", stats_data.total_score)
	_save_stats()


func get_total_distance() -> float:
	"""Get total distance traveled across all runs"""
	return stats_data.total_distance


func get_total_score() -> int:
	"""Get total score accumulated across all runs"""
	return stats_data.total_score


# Milestone tracking
func record_personal_record_broken() -> void:
	"""Record that player broke their personal record"""
	stats_data.personal_records_broken += 1
	personal_record_broken.emit()
	stat_changed.emit("personal_records_broken", stats_data.personal_records_broken)
	_save_stats()


func record_pause() -> void:
	"""Record that player paused the game"""
	stats_data.times_paused += 1
	stat_changed.emit("times_paused", stats_data.times_paused)
	_save_stats()


func record_cosmetic_unlocked() -> void:
	"""Record that player unlocked a cosmetic"""
	stats_data.cosmetics_unlocked += 1
	stat_changed.emit("cosmetics_unlocked", stats_data.cosmetics_unlocked)
	_save_stats()


func get_personal_records_broken() -> int:
	"""Get number of times personal record was broken"""
	return stats_data.personal_records_broken


func get_times_paused() -> int:
	"""Get number of times game was paused"""
	return stats_data.times_paused


func get_cosmetics_unlocked() -> int:
	"""Get number of cosmetics unlocked"""
	return stats_data.cosmetics_unlocked


# Proximity tracking
func record_obstacle_proximity(distance: float) -> void:
	"""Record how close player passed to an obstacle"""
	if distance < stats_data.closest_obstacle_pass:
		stats_data.closest_obstacle_pass = distance
		proximity_record_broken.emit(distance)
		stat_changed.emit("closest_obstacle_pass", distance)
		_save_stats()


func get_closest_obstacle_pass() -> float:
	"""Get closest distance player has passed an obstacle"""
	return stats_data.closest_obstacle_pass


# Daily challenge stats
func record_daily_challenge_complete(died: bool, time: float, collectible_percent: float) -> void:
	"""Record daily challenge completion statistics"""
	stats_data.daily_challenges_completed += 1

	if not died:
		stats_data.daily_challenges_perfect += 1
		stat_changed.emit("daily_challenges_perfect", stats_data.daily_challenges_perfect)

	# Track best completion time
	if time < stats_data.best_daily_completion_time:
		stats_data.best_daily_completion_time = time
		stat_changed.emit("best_daily_completion_time", time)

	# Track best collectible percentage
	if collectible_percent > stats_data.best_daily_collectible_percentage:
		stats_data.best_daily_collectible_percentage = collectible_percent
		stat_changed.emit("best_daily_collectible_percentage", collectible_percent)

	# Update streak
	update_daily_streak()

	stat_changed.emit("daily_challenges_completed", stats_data.daily_challenges_completed)
	_save_stats()


func record_rush_challenge_complete(died: bool, time: float) -> void:
	"""Record RUSH challenge completion statistics"""
	stats_data.rush_challenges_completed += 1

	if not died:
		stats_data.rush_challenges_perfect += 1
		stat_changed.emit("rush_challenges_perfect", stats_data.rush_challenges_perfect)

	# Track best completion time
	if time < stats_data.best_rush_completion_time:
		stats_data.best_rush_completion_time = time
		stat_changed.emit("best_rush_completion_time", time)

	stat_changed.emit("rush_challenges_completed", stats_data.rush_challenges_completed)
	_save_stats()


func get_daily_challenges_completed() -> int:
	"""Get number of daily challenges completed"""
	return stats_data.daily_challenges_completed


func get_daily_challenges_perfect() -> int:
	"""Get number of daily challenges completed without dying"""
	return stats_data.daily_challenges_perfect


func get_best_daily_completion_time() -> float:
	"""Get best daily challenge completion time"""
	return stats_data.best_daily_completion_time


func get_best_daily_collectible_percentage() -> float:
	"""Get best collectible percentage in daily challenge"""
	return stats_data.best_daily_collectible_percentage


func get_rush_challenges_completed() -> int:
	"""Get number of RUSH challenges completed"""
	return stats_data.rush_challenges_completed


func get_rush_challenges_perfect() -> int:
	"""Get number of RUSH challenges completed without dying"""
	return stats_data.rush_challenges_perfect


func get_best_rush_completion_time() -> float:
	"""Get best RUSH challenge completion time"""
	return stats_data.best_rush_completion_time


# Stat retrieval by name (for achievement checking)
func get_stat(stat_name: String):
	"""Get any stat by name"""
	if stats_data.has(stat_name):
		return stats_data[stat_name]
	return null


# Persistence
func _save_stats() -> void:
	"""Save stats to SaveManager"""
	SaveManager.save_stats(stats_data)


func _load_stats() -> void:
	"""Load stats from SaveManager"""
	var loaded_stats = SaveManager.load_stats()
	if loaded_stats:
		# Merge loaded stats with defaults (in case new stats were added)
		for key in loaded_stats:
			if key in stats_data:
				stats_data[key] = loaded_stats[key]
		print("Stats loaded successfully")
	else:
		print("No stats found, using defaults")


# Utility functions
func _get_date_string() -> String:
	"""Get current date as string (YYYY-MM-DD)"""
	var date = Time.get_date_dict_from_system()
	return "%d-%02d-%02d" % [date.year, date.month, date.day]


func _is_consecutive_day(last_date: String, current_date: String) -> bool:
	"""Check if current_date is the day after last_date"""
	if last_date == "":
		return false

	# Parse last date
	var last_parts = last_date.split("-")
	if last_parts.size() != 3:
		return false

	var last_year = int(last_parts[0])
	var last_month = int(last_parts[1])
	var last_day = int(last_parts[2])

	# Parse current date
	var current_parts = current_date.split("-")
	if current_parts.size() != 3:
		return false

	var current_year = int(current_parts[0])
	var current_month = int(current_parts[1])
	var current_day = int(current_parts[2])

	# Convert to Unix time and check if difference is ~1 day
	var last_dict = {"year": last_year, "month": last_month, "day": last_day}
	var current_dict = {"year": current_year, "month": current_month, "day": current_day}

	var last_unix = Time.get_unix_time_from_datetime_dict(last_dict)
	var current_unix = Time.get_unix_time_from_datetime_dict(current_dict)

	var diff_days = (current_unix - last_unix) / 86400.0  # Seconds in a day

	# Allow for 1 day difference (with some tolerance for timezone issues)
	return diff_days >= 0.8 and diff_days <= 1.2


# Debug methods
func reset_all_stats() -> void:
	"""Reset all stats to default values (for testing/debugging)"""
	stats_data = {
		"deaths_by_pillar": 0,
		"deaths_by_pulse_gate": 0,
		"deaths_by_timeout": 0,
		"total_deaths": 0,
		"total_distance": 0.0,
		"total_score": 0,
		"daily_challenges_completed": 0,
		"daily_challenges_perfect": 0,
		"current_daily_streak": 0,
		"best_daily_streak": 0,
		"last_daily_played_date": "",
		"best_daily_completion_time": 999.0,
		"best_daily_collectible_percentage": 0.0,
		"rush_challenges_completed": 0,
		"rush_challenges_perfect": 0,
		"best_rush_completion_time": 999.0,
		"personal_records_broken": 0,
		"times_paused": 0,
		"cosmetics_unlocked": 0,
		"closest_obstacle_pass": 999.0,
		"fastest_death_time": 999.0
	}
	_save_stats()
	print("All stats reset to defaults")


func print_stats() -> void:
	"""Print all current stats (for debugging)"""
	print("=== Current Stats ===")
	for key in stats_data:
		print("%s: %s" % [key, str(stats_data[key])])
	print("===================")
