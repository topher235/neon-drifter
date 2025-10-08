extends BaseCollectible

@export var invincibility_duration: float = 5.0
@export var star_color: Color = Color(1, 1, 0, 1)  # Yellow
@export var rotation_speed: float = 2.0  # Radians per second
@export var pulse_speed: float = 2.5
@export var pulse_amount: float = 0.2

@onready var star_visual: Polygon2D = $StarVisual
@onready var star_glow: PointLight2D = $StarGlow

var _rotation_angle: float = 0.0
var _pulse_time: float = 0.0

func _ready() -> void:
	super._ready()
	_setup_visual()
	_setup_collision()

func _setup_visual() -> void:
	if star_visual:
		star_visual.color = star_color

	if star_glow:
		star_glow.enabled = true
		star_glow.color = star_color
		star_glow.energy = 2.0
		star_glow.texture_scale = 1.5
		star_glow.blend_mode = Light2D.BLEND_MODE_ADD

func _setup_collision() -> void:
	# Use a circle collision that encompasses the star
	var shape = CircleShape2D.new()
	shape.radius = 20.0  # Matches outer radius of star
	collision_shape.shape = shape

func _animate(delta: float) -> void:
	super._animate(delta)

	# Rotate the star
	_rotation_angle += rotation_speed * delta
	if star_visual:
		star_visual.rotation = _rotation_angle

	# Pulse the scale
	_pulse_time += delta * pulse_speed
	var pulse_scale = 1.0 + sin(_pulse_time) * pulse_amount
	if star_visual:
		star_visual.scale = Vector2(pulse_scale, pulse_scale)

	# Pulse the glow
	if star_glow:
		star_glow.energy = 2.0 + sin(_pulse_time) * 0.5

func _on_collected() -> void:
	# Grant invincibility to player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("activate_invincibility"):
		player.activate_invincibility(invincibility_duration)

	AudioManager.play_sfx("orb_collect", 0.2)  # Using orb sound for now
	_spawn_particles()
