extends BaseObstacle

@export var wall_length: float = 80
@export var thickness: float = 8.0
@export var color: Color = Color(1, 1, 1, 1)  # White
@export var pulse_interval: float = 1.0  # Toggle every 1 second

@onready var visual: ColorRect = $Visual
@onready var pulse_timer: Timer = $PulseTimer

var is_visible_state: bool = true
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
	_setup_timer()

func _setup_visuals() -> void:
	if visual:
		visual.size = Vector2(wall_length, thickness)
		visual.position = -visual.size / 2  # Center the wall
		visual.color = color

func _setup_collision() -> void:
	var shape = RectangleShape2D.new()
	shape.size = Vector2(wall_length, thickness)
	collision_shape.shape = shape

func _setup_timer() -> void:
	if not pulse_timer:
		pulse_timer = Timer.new()
		add_child(pulse_timer)

	pulse_timer.wait_time = pulse_interval
	pulse_timer.one_shot = false
	pulse_timer.timeout.connect(_on_pulse_timeout)
	pulse_timer.start()

func _on_pulse_timeout() -> void:
	is_visible_state = !is_visible_state

	# Update visual and collision
	if visual:
		visual.visible = is_visible_state
	collision_shape.disabled = !is_visible_state

func update_obstacle(_delta: float) -> void:
	# No longer needed - using Timer instead
	pass
