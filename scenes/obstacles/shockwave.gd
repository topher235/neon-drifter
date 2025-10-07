extends BaseObstacle

@export var core_radius: float = 20.0
@export var shockwave_max_radius: float = 100.0
@export var shockwave_interval: float = 2.0  # Time between shockwaves
@export var shockwave_duration: float = 1.0  # Time for shockwave to expand
@export var core_color: Color = Color(1, 1, 0, 1)  # Yellow
@export var shockwave_color: Color = Color(1, 1, 0, 0.8)  # Yellow with slight transparency
@export var jagged_points: int = 20  # Number of points for jagged edge
@export var jagged_variation: float = 10.0  # How much the points vary in radius

# Visual elements
@onready var core_visual: Polygon2D = $CoreVisual
@onready var core_glow: PointLight2D = $CoreGlow
@onready var shockwave_line: Line2D = $ShockwaveLine
@onready var shockwave_collision: CollisionShape2D = $ShockwaveCollision

var _initialized: bool = false
var _time_since_last_shockwave: float = 0.0
var _shockwave_active: bool = false
var _shockwave_timer: float = 0.0
var _core_pulse_time: float = 0.0

func _ready() -> void:
	super._ready()
	if not _initialized:
		call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if _initialized:
		return
	_initialized = true
	_setup_core_visuals()
	_setup_core_collision()
	_setup_shockwave_visuals()
	_setup_shockwave_collision()

func _setup_core_visuals() -> void:
	# Setup the core circle (Polygon2D is already a circle, just set color and scale)
	if core_visual:
		core_visual.color = core_color
		# The polygon is created at 20px radius, so scale it to match core_radius
		var scale_factor = core_radius / 20.0
		core_visual.scale = Vector2(scale_factor, scale_factor)

	if core_glow:
		core_glow.enabled = true
		core_glow.energy = 1.8
		core_glow.color = core_color
		core_glow.texture_scale = core_radius / 32.0
		core_glow.blend_mode = Light2D.BLEND_MODE_ADD

func _setup_core_collision() -> void:
	# Core always has collision
	var shape = CircleShape2D.new()
	shape.radius = core_radius
	collision_shape.shape = shape

func _setup_shockwave_visuals() -> void:
	if shockwave_line:
		shockwave_line.width = 3.0
		shockwave_line.default_color = shockwave_color
		shockwave_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		shockwave_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		shockwave_line.joint_mode = Line2D.LINE_JOINT_SHARP
		shockwave_line.visible = false

func _setup_shockwave_collision() -> void:
	if shockwave_collision:
		var shape = CircleShape2D.new()
		shape.radius = 0  # Start with no collision
		shockwave_collision.shape = shape
		shockwave_collision.disabled = true

func update_obstacle(delta: float) -> void:
	_update_core_pulse(delta)
	_update_shockwave(delta)

func _update_core_pulse(delta: float) -> void:
	_core_pulse_time += delta

	# Pulse the core size slightly
	var pulse_scale = 1.0 + sin(_core_pulse_time * 3.0) * 0.2
	if core_visual:
		var base_scale = core_radius / 20.0
		core_visual.scale = Vector2(base_scale, base_scale) * pulse_scale

	# Pulse the glow energy
	if core_glow:
		core_glow.energy = 1.8 + sin(_core_pulse_time * 3.0) * 0.4

func _update_shockwave(delta: float) -> void:
	_time_since_last_shockwave += delta

	# Check if we should emit a new shockwave
	if not _shockwave_active and _time_since_last_shockwave >= shockwave_interval:
		_emit_shockwave()

	# Update active shockwave
	if _shockwave_active:
		_shockwave_timer += delta
		var progress = _shockwave_timer / shockwave_duration

		if progress >= 1.0:
			_end_shockwave()
		else:
			_update_shockwave_expansion(progress)

func _emit_shockwave() -> void:
	_shockwave_active = true
	_shockwave_timer = 0.0
	_time_since_last_shockwave = 0.0

	if shockwave_line:
		shockwave_line.visible = true

	if shockwave_collision:
		shockwave_collision.disabled = false

func _end_shockwave() -> void:
	_shockwave_active = false

	if shockwave_line:
		shockwave_line.visible = false
		shockwave_line.clear_points()

	if shockwave_collision:
		shockwave_collision.disabled = true
		var shape = shockwave_collision.shape as CircleShape2D
		if shape:
			shape.radius = 0

func _update_shockwave_expansion(progress: float) -> void:
	# Calculate current radius with ease-out curve
	var ease_progress = 1.0 - pow(1.0 - progress, 2.0)
	var current_radius = core_radius + (shockwave_max_radius - core_radius) * ease_progress

	# Update collision shape
	if shockwave_collision:
		var shape = shockwave_collision.shape as CircleShape2D
		if shape:
			shape.radius = current_radius

	# Update jagged visual
	_draw_jagged_circle(current_radius, progress)

func _draw_jagged_circle(radius: float, progress: float) -> void:
	if not shockwave_line:
		return

	shockwave_line.clear_points()

	# Create jagged circle with random variations
	var angle_step = TAU / jagged_points

	for i in range(jagged_points + 1):  # +1 to close the circle
		var angle = i * angle_step

		# Add random variation to radius for jagged effect
		var variation = randf_range(-jagged_variation, jagged_variation)
		var point_radius = radius + variation

		var x = cos(angle) * point_radius
		var y = sin(angle) * point_radius

		shockwave_line.add_point(Vector2(x, y))

	# Fade out shockwave as it expands
	var alpha = 1.0 - progress
	if shockwave_line:
		shockwave_line.default_color = Color(shockwave_color.r, shockwave_color.g, shockwave_color.b, alpha * 0.8)
