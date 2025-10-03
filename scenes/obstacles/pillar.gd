extends BaseObstacle

@export var radius: float = 30.0
@export var color: Color = Color(1, 0.2, 0.5, 1)  # Pink-red
@export var glow_enabled: bool = true

@onready var visual: ColorRect = $Visual
@onready var glow: PointLight2D = $Glow

func _ready() -> void:
    super._ready()
    _setup_visuals()
    _setup_collision()

func _setup_visuals() -> void:
    # For MVP, use ColorRect as simple circular visual
    if visual:
        visual.size = Vector2(radius * 2, radius * 2)
        visual.position = -visual.size / 2
        visual.color = color

    # Make it circular with shader or accept square for MVP
    # We can add a circular shader later

    if glow and glow_enabled:
        glow.enabled = true
        glow.energy = 1.5
        glow.color = color
        glow.texture_scale = radius / 32.0
        glow.blend_mode = Light2D.BLEND_MODE_ADD

func _setup_collision() -> void:
    var shape = CircleShape2D.new()
    shape.radius = radius
    collision_shape.shape = shape

func update_obstacle(_delta: float) -> void:
    # Pillars are static, but could add pulse animation
    if glow_enabled and glow:
        # Subtle pulse
        glow.energy = 1.5 + sin(Time.get_ticks_msec() * 0.003) * 0.3
