extends BaseCollectible

@export var multiplier_duration: float = 5.0
@export var multiplier_color: Color = Color(1, 1, 1, 1)  # White
@export var diamond_size: float = 20.0

func _ready() -> void:
	super._ready()
	add_to_group("multiplier")
	_setup_visual()
	_setup_collision()

func _setup_visual() -> void:
	if visual:
		# Create a diamond shape using a rotated square
		visual.size = Vector2(diamond_size, diamond_size)
		visual.position = -visual.size / 2
		visual.color = multiplier_color
		# Rotate 45 degrees to make it diamond-shaped
		visual.rotation_degrees = 45

func _setup_collision() -> void:
	# Use a circular collision shape for easier collection
	var shape = CircleShape2D.new()
	shape.radius = diamond_size * 0.7  # Slightly smaller than visual for better feel
	collision_shape.shape = shape

func _on_collected() -> void:
	GameManager.activate_orb_multiplier(multiplier_duration)
	AudioManager.play_sfx("orb_collect", 0.2)  # Slightly different pitch
	_spawn_particles()
