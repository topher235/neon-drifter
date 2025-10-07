extends BaseObstacle

@export var width: float = 250.0  # Default tunnel width
@export var height: float = 300.0  # Height of smoke area
@export var opacity: float = 0.6  # How opaque the smoke is

@onready var smoke_visual: ColorRect = $SmokeVisual

var _initialized: bool = false

func _ready() -> void:
    super._ready()
    if not _initialized:
        call_deferred("_deferred_setup")

func _deferred_setup() -> void:
    if _initialized:
        return
    _initialized = true
    _setup_visuals()

func _setup_visuals() -> void:
    if smoke_visual:
        # Position and size the visual rect
        smoke_visual.size = Vector2(width, height)
        smoke_visual.position = Vector2(-width / 2, -height / 2)
        smoke_visual.color = Color(0.85, 0.85, 0.95, opacity)


func update_obstacle(delta: float) -> void:
    # Update shader time for animated smoke effect
    if smoke_visual and smoke_visual.material:
        var shader_mat = smoke_visual.material as ShaderMaterial
        if shader_mat:
            var current_time = shader_mat.get_shader_parameter("time")
            var new_time = current_time + delta
            shader_mat.set_shader_parameter("time", new_time)
