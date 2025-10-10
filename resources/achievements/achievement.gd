extends Resource
class_name Achievement

## Defines an achievement that can be unlocked by meeting specific criteria
## Supports stat thresholds, event triggers, and custom unlock logic

# Unlock criteria types
enum CriteriaType {
	STAT_THRESHOLD,      # Single stat reaches value (e.g., pause 100 times)
	STAT_COMPARISON,     # Compare stat against value with operator
	MULTI_STAT,          # Multiple stats must meet criteria (not yet implemented)
	EVENT_TRIGGERED,     # Unlocked by specific event (not yet implemented)
	CUSTOM               # Custom check function (not yet implemented)
}

# Achievement metadata
@export var achievement_id: String = ""
@export var achievement_name: String = ""
@export var achievement_description: String = ""
@export var icon_path: String = ""  # Path to achievement icon (for future UI)
@export var hidden: bool = false  # Hidden until unlocked

# Unlock criteria
@export var criteria_type: CriteriaType = CriteriaType.STAT_THRESHOLD
@export var stat_name: String = ""  # Stat to check (e.g., "times_paused")
@export var threshold_value: float = 0.0  # Value to reach
@export var comparison_op: String = ">="  # ">=", "<=", "==", ">", "<"

# Rewards
@export var orb_reward: int = 0  # Orbs awarded when unlocked
@export var unlocks_cosmetic: String = ""  # Cosmetic ID to unlock (if any)

# State (not exported, managed at runtime)
var unlock_date: String = ""  # Date when achievement was unlocked (YYYY-MM-DD)
var is_new: bool = false  # True if just unlocked this session


func is_unlocked() -> bool:
	"""Check if achievement has been unlocked"""
	return unlock_date != ""


func check_unlock_criteria(stats_manager: Node) -> bool:
	"""
	Check if unlock criteria are met based on current stats
	Returns true if achievement should be unlocked
	"""
	if is_unlocked():
		return false  # Already unlocked

	match criteria_type:
		CriteriaType.STAT_THRESHOLD, CriteriaType.STAT_COMPARISON:
			return _check_stat_threshold(stats_manager)
		_:
			push_warning("Unimplemented criteria type for achievement: " + achievement_id)
			return false


func _check_stat_threshold(stats_manager: Node) -> bool:
	"""Check if a stat meets the threshold criteria"""
	if stat_name == "":
		return false

	var stat_value = stats_manager.get_stat(stat_name)
	if stat_value == null:
		return false

	# Convert to float for comparison
	var value = float(stat_value)
	var threshold = float(threshold_value)

	match comparison_op:
		">=":
			return value >= threshold
		"<=":
			return value <= threshold
		"==":
			return value == threshold
		">":
			return value > threshold
		"<":
			return value < threshold
		_:
			push_warning("Unknown comparison operator: " + comparison_op)
			return false


func unlock() -> void:
	"""Mark achievement as unlocked"""
	unlock_date = _get_date_string()
	is_new = true


func _get_date_string() -> String:
	"""Get current date as string (YYYY-MM-DD)"""
	var date = Time.get_date_dict_from_system()
	return "%d-%02d-%02d" % [date.year, date.month, date.day]


func get_progress(stats_manager: Node) -> float:
	"""
	Get progress toward unlocking this achievement (0.0 to 1.0)
	Returns 1.0 if already unlocked
	"""
	if is_unlocked():
		return 1.0

	match criteria_type:
		CriteriaType.STAT_THRESHOLD, CriteriaType.STAT_COMPARISON:
			var stat_value = stats_manager.get_stat(stat_name)
			if stat_value == null:
				return 0.0

			var value = float(stat_value)
			var threshold = float(threshold_value)

			if threshold == 0.0:
				return 0.0

			# Calculate progress based on comparison operator
			match comparison_op:
				">=", ">":
					return clamp(value / threshold, 0.0, 1.0)
				"<=", "<":
					# For "less than" achievements, progress is inverted
					if value <= threshold:
						return 1.0
					else:
						return 0.0
				"==":
					# For exact matches, it's either 0 or 1
					return 1.0 if value == threshold else 0.0
				_:
					return 0.0
		_:
			return 0.0


func to_dict() -> Dictionary:
	"""Convert achievement state to dictionary for saving"""
	return {
		"achievement_id": achievement_id,
		"unlock_date": unlock_date,
		"is_new": is_new
	}


func from_dict(data: Dictionary) -> void:
	"""Load achievement state from dictionary"""
	if data.has("unlock_date"):
		unlock_date = data.unlock_date
	if data.has("is_new"):
		is_new = data.is_new
