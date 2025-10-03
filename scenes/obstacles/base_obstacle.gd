class_name BaseObstacle extends Area2D

# Signals
signal obstacle_passed

# State
var is_active: bool = true
var has_been_passed: bool = false
var player_x_position: float = 0.0

# Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    add_to_group("obstacles")
    collision_layer = 2  # Obstacle layer
    collision_mask = 1   # Collide with player layer

    # Connect to area detection for "passed" logic
    area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
    if not is_active:
        return

    _check_if_passed()
    update_obstacle(_delta)

func _check_if_passed() -> void:
    if has_been_passed:
        return

    # Get player position (from game world)
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player_x_position = player.global_position.x

        # Check if player has passed this obstacle
        if player_x_position > global_position.x + 50:  # 50px grace distance
            has_been_passed = true
            _on_obstacle_passed()

func _on_obstacle_passed() -> void:
    obstacle_passed.emit()
# Could award points here for "near miss" mechanics

func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("player_collision"):
        _on_hit_player()

func _on_hit_player() -> void:
    # Override in derived classes for specific behavior
    pass

# Virtual method - override in derived classes
func update_obstacle(_delta: float) -> void:
    pass

func deactivate() -> void:
    is_active = false
    queue_free()