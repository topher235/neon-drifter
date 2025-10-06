extends BaseObstacle

@export var wall_length: float = 80
@export var thickness: float = 8.0
@export var color: Color = Color(1, 1, 1, 1)  # White

@onready var visual: ColorRect = $Visual

func _ready() -> void:
	super._ready()
	_setup_visuals()
	_setup_collision()

func _setup_visuals() -> void:
	if visual:
		visual.size = Vector2(wall_length, thickness)
		visual.position = -visual.size / 2  # Center the wall
		visual.color = color

func _setup_collision() -> void:
	var shape = RectangleShape2D.new()
	shape.size = Vector2(wall_length, thickness)
	collision_shape.shape = shape

func update_obstacle(_delta: float) -> void:
	# Static wall, no animation
	pass
