extends BaseObstacle

@export var wall_height: float = 800.0  # Will be set to segment length
@export var thickness: float = 8.0
@export var color: Color = Color(1, 1, 1, 1)  # White

@onready var visual: ColorRect = $Visual

var _initialized: bool = false

func _ready() -> void:
	super._ready()
	# Defer setup to allow properties to be set first
	if not _initialized:
		call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if _initialized:
		return
	_initialized = true
	_setup_visuals()
	_setup_collision()

func _setup_visuals() -> void:
	if visual:
		visual.size = Vector2(thickness, wall_height)
		visual.position = -visual.size / 2  # Center the wall
		visual.color = color

func _setup_collision() -> void:
	var shape = RectangleShape2D.new()
	shape.size = Vector2(thickness, wall_height)
	collision_shape.shape = shape

func update_obstacle(_delta: float) -> void:
	# Static wall, no animation
	pass
