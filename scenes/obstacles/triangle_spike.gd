extends BaseObstacle

@export var size: float = 30.0  # Base size of the triangle
@export var color: Color = Color(1, 0.2, 0.5, 1)  # Pink-red (matches pillar)

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

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
    if not visual:
        return

    # Create equilateral triangle with point at origin (0, 0) and base extending backward
    # When rotation = 0°, point at (0,0) aims right, base at (-size, ±height)
    var height := size * 0.866  # sqrt(3)/2 for equilateral triangle
    visual.polygon = PackedVector2Array([
        Vector2(0, 0),            # Point at origin
        Vector2(-size, -height),  # Base top
        Vector2(-size, height)    # Base bottom
    ])
    visual.color = color


func _setup_collision() -> void:
    # Create a triangle collision shape matching visual
    var shape = ConvexPolygonShape2D.new()
    var height = size * 0.866
    shape.points = PackedVector2Array([
        Vector2(0, 0),            # Point at origin
        Vector2(-size, -height),  # Base top
        Vector2(-size, height)    # Base bottom
    ])
    collision_shape.shape = shape


func update_obstacle(_delta: float) -> void:
    # Static obstacle, no animation
    pass
