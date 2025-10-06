extends BaseObstacle

@export var size: float = 30.0  # Base size of the triangle
@export var color: Color = Color(1, 0.2, 0.5, 1)  # Pink-red (matches pillar)

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
    super._ready()
    _setup_visuals()
    _setup_collision()

    
func setup_position(value: Vector2) -> void:
    position = value
    visual.position = Vector2(-30, 0)
    collision.position = Vector2(-30, 0)


func _setup_visuals() -> void:
    if not visual:
        return
    
    # Create equilateral triangle with base at x=0 (wall position) pointing right
    # Base from (0, -height) to (0, height), point at (size, 0)
    var height := size * 0.866  # sqrt(3)/2 for equilateral triangle
    visual.polygon = PackedVector2Array([
        Vector2(size, 0),         # Point (extends inward)
        Vector2(0, -height),      # Base top (at wall)
        Vector2(0, height)        # Base bottom (at wall)
    ])
    visual.color = color


func _setup_collision() -> void:
    # Create a triangle collision shape matching visual
    var shape = ConvexPolygonShape2D.new()
    var height = size * 0.866
    shape.points = PackedVector2Array([
        Vector2(size, 0),         # Point (extends inward)
        Vector2(0, -height),      # Base top (at wall)
        Vector2(0, height)        # Base bottom (at wall)
    ])
    collision_shape.shape = shape


func update_obstacle(_delta: float) -> void:
    # Static obstacle, no animation
    pass
