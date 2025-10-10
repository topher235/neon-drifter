extends Node

## Global manager for collectibles (non-orb types)
## Handles collectible library, unlocking, and spawn availability

signal collectible_unlocked(collectible_id: String)

var collectibles: Dictionary = {}  # collectible_id -> CollectibleData


func _ready() -> void:
	_initialize_collectibles()


func _initialize_collectibles() -> void:
	"""Initialize all available collectibles"""

	# Orbs - always unlocked by default (not purchasable)
	var orb_data = CollectibleData.new()
	orb_data.collectible_id = "orb"
	orb_data.collectible_name = "Orb"
	orb_data.description = "Collect orbs to earn points and currency for unlocking items."
	orb_data.collectible_type = "orb"
	orb_data.collectible_color = Color(0, 1, 1)  # Cyan
	orb_data.unlocked_by_default = true
	orb_data.buyable = false
	orb_data.orb_cost = 0
	collectibles["orb"] = orb_data

	# Magnet - Attracts nearby orbs
	var magnet_data = CollectibleData.new()
	magnet_data.collectible_id = "magnet"
	magnet_data.collectible_name = "Magnet"
	magnet_data.description = "Automatically attracts nearby orbs to you for a limited time."
	magnet_data.collectible_type = "magnet"
	magnet_data.collectible_color = Color(0.2, 0.5, 1.0)  # Blue
	magnet_data.unlocked_by_default = false
	magnet_data.buyable = true
	magnet_data.orb_cost = 150
	collectibles["magnet"] = magnet_data

	# Multiplier - Increases score multiplier
	var multiplier_data = CollectibleData.new()
	multiplier_data.collectible_id = "multiplier"
	multiplier_data.collectible_name = "Multiplier"
	multiplier_data.description = "Doubles your score multiplier temporarily."
	multiplier_data.collectible_type = "multiplier"
	multiplier_data.collectible_color = Color(1.0, 0.8, 0.0)  # Gold
	multiplier_data.unlocked_by_default = false
	multiplier_data.buyable = true
	multiplier_data.orb_cost = 200
	collectibles["multiplier"] = multiplier_data

	# Star - Bonus points
	var star_data = CollectibleData.new()
	star_data.collectible_id = "star"
	star_data.collectible_name = "Star"
	star_data.description = "Collect for a large point bonus!"
	star_data.collectible_type = "star"
	star_data.collectible_color = Color(1.0, 1.0, 0.0)  # Yellow
	star_data.unlocked_by_default = false
	star_data.buyable = true
	star_data.orb_cost = 100
	collectibles["star"] = star_data

	# Stopwatch - Slows down time
	var stopwatch_data = CollectibleData.new()
	stopwatch_data.collectible_id = "stopwatch"
	stopwatch_data.collectible_name = "Stopwatch"
	stopwatch_data.description = "Slows down time temporarily, making obstacles easier to dodge."
	stopwatch_data.collectible_type = "stopwatch"
	stopwatch_data.collectible_color = Color(0.6, 0.6, 0.6)  # Silver
	stopwatch_data.unlocked_by_default = false
	stopwatch_data.buyable = true
	stopwatch_data.orb_cost = 250
	collectibles["stopwatch"] = stopwatch_data

	# Hourglass - Time bonus
	var hourglass_data = CollectibleData.new()
	hourglass_data.collectible_id = "hourglass"
	hourglass_data.collectible_name = "Hourglass"
	hourglass_data.description = "Adds bonus time in time-based game modes."
	hourglass_data.collectible_type = "hourglass"
	hourglass_data.collectible_color = Color(0.8, 0.6, 0.4)  # Sand/Bronze
	hourglass_data.unlocked_by_default = false
	hourglass_data.buyable = true
	hourglass_data.orb_cost = 175
	collectibles["hourglass"] = hourglass_data

	# Bomb - Clears nearby obstacles
	var bomb_data = CollectibleData.new()
	bomb_data.collectible_id = "bomb"
	bomb_data.collectible_name = "Bomb"
	bomb_data.description = "Clears all nearby obstacles when collected."
	bomb_data.collectible_type = "bomb"
	bomb_data.collectible_color = Color(1.0, 0.3, 0.0)  # Orange/Red
	bomb_data.unlocked_by_default = false
	bomb_data.buyable = true
	bomb_data.orb_cost = 300
	collectibles["bomb"] = bomb_data


func get_collectible(collectible_id: String) -> CollectibleData:
	"""Get a collectible by ID"""
	return collectibles.get(collectible_id, null)


func is_collectible_unlocked(collectible_id: String) -> bool:
	"""Check if a collectible is unlocked"""
	if not collectibles.has(collectible_id):
		return false

	var collectible = collectibles[collectible_id]

	# Always unlocked if marked as default
	if collectible.unlocked_by_default:
		return true

	# Check SaveManager for unlock status
	return SaveManager.is_collectible_unlocked(collectible_id)


func unlock_collectible(collectible_id: String) -> bool:
	"""
	Unlock a collectible by spending orbs
	Returns true if unlock succeeded
	"""
	if not collectibles.has(collectible_id):
		return false

	if is_collectible_unlocked(collectible_id):
		return true  # Already unlocked

	var collectible = collectibles[collectible_id]

	# Check if player has enough orbs and spend them
	if not SaveManager.spend_orbs(collectible.orb_cost):
		return false

	# Unlock the collectible
	SaveManager.unlock_collectible(collectible_id)
	collectible_unlocked.emit(collectible_id)
	return true


func get_all_collectibles() -> Array[CollectibleData]:
	"""Get all collectibles as an array"""
	var result: Array[CollectibleData] = []
	for collectible in collectibles.values():
		result.append(collectible)
	return result


func get_unlocked_collectible_types() -> Array[String]:
	"""Get array of collectible types that are unlocked (for spawning in segments)"""
	var unlocked_types: Array[String] = []
	for collectible_id in collectibles.keys():
		if is_collectible_unlocked(collectible_id):
			var collectible = collectibles[collectible_id]
			unlocked_types.append(collectible.collectible_type)
	return unlocked_types


func can_spawn_collectible(collectible_type: String) -> bool:
	"""Check if a collectible type can be spawned (is unlocked)"""
	# Orbs are always spawnnable
	if collectible_type == "orb":
		return true

	# Find the collectible_id for this type and check if unlocked
	for collectible_id in collectibles.keys():
		var collectible = collectibles[collectible_id]
		if collectible.collectible_type == collectible_type:
			return is_collectible_unlocked(collectible_id)

	return false
