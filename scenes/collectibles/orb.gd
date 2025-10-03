extends BaseCollectible

@export var point_value: int = 10
@export var orb_color: Color = Color(0, 1, 1, 1)  # Cyan
@export var orb_radius: float = 15.0

#@onready var visual: ColorRect = $Visual

func _ready() -> void:
    super._ready()
    _setup_visual()
    _setup_collision()

func _setup_visual() -> void:
    if visual:
        visual.size = Vector2(orb_radius * 2, orb_radius * 2)
        visual.position = -visual.size / 2
        visual.color = orb_color

func _setup_collision() -> void:
    var shape = CircleShape2D.new()
    shape.radius = orb_radius
    collision_shape.shape = shape

func _on_collected() -> void:
    GameManager.collect_orb(point_value)
    AudioManager.play_sfx("orb_collect", 0.1)
    _spawn_particles()

func _spawn_particles() -> void:
    # Simple particle effect for collection
    # Could create a dedicated particle scene
    pass
