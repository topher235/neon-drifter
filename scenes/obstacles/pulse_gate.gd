extends BaseObstacle

@export var rotation_speed: float = 0.5  # Rotations per second
@export var bar_length: float = 150.0
@export var bar_width: float = 15.0
@export var gap_size: float = 80.0  # Opening size
@export var color: Color = Color(1, 0.5, 0, 1)  # Orange

@onready var bar_1: ColorRect = $Bar1
@onready var bar_2: ColorRect = $Bar2
@onready var collision_1: CollisionShape2D = $CollisionShape1
@onready var collision_2: CollisionShape2D = $CollisionShape2

var current_rotation: float = 0.0

func _ready() -> void:
    super._ready()
    _setup_bars()

func _setup_bars() -> void:
    # Bar 1 (top)
    if bar_1:
        bar_1.size = Vector2(bar_width, bar_length)
        bar_1.position = Vector2(-bar_width/2, -gap_size/2 - bar_length)
        bar_1.color = color

    # Bar 2 (bottom)
    if bar_2:
        bar_2.size = Vector2(bar_width, bar_length)
        bar_2.position = Vector2(-bar_width/2, gap_size/2)
        bar_2.color = color

    # Setup collision shapes
    if collision_1:
        var shape = RectangleShape2D.new()
        shape.size = Vector2(bar_width, bar_length)
        collision_1.shape = shape
        collision_1.position = bar_1.position + Vector2(bar_width/2, bar_length/2)

    if collision_2:
        var shape = RectangleShape2D.new()
        shape.size = Vector2(bar_width, bar_length)
        collision_2.shape = shape
        collision_2.position = bar_2.position + Vector2(bar_width/2, bar_length/2)

func update_obstacle(delta: float) -> void:
    # Rotate the entire gate
    current_rotation += rotation_speed * TAU * delta  # TAU = 2*PI
    rotation = current_rotation

    # Visual pulse (optional)
    var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.1
    scale = Vector2(pulse, pulse)
