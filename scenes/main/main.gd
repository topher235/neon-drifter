extends Node
## Main - Root scene entry point
##
## This is the main entry point for the game. It initializes global systems
## and transitions to the main menu when ready.

func _ready() -> void:
	# Initialize game systems
	_initialize_systems()

	# Wait one frame to ensure everything is ready
	await get_tree().process_frame

	# Transition to main menu
	SceneManager.goto_main_menu(false, true)

func _initialize_systems() -> void:
	"""Initialize any global game systems that need setup at startup"""
	# Systems are autoloaded, so they're already initialized
	# This is a placeholder for any additional startup logic
	pass
