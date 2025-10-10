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

func destroy_with_effect() -> void:
    # Spawn destroy particles
    _spawn_destroy_particles()

    # Play destruction sound
    AudioManager.play_sfx("orb_collect", -0.3)  # Lower pitch for explosion

    # Deactivate and remove
    is_active = false
    queue_free()

func _spawn_destroy_particles() -> void:
    # Create particle effect at obstacle position
    var particles_scene = preload("res://scenes/obstacles/destroy_particles.tscn")
    var particles = particles_scene.instantiate()

    # Add to world (not as child, since this obstacle is being destroyed)
    var world = get_tree().root
    if get_parent():
        world = get_parent()

    world.add_child(particles)
    particles.global_position = global_position
    particles.emitting = true

    # Auto-cleanup after particles finish
    await get_tree().create_timer(2.0).timeout
    if is_instance_valid(particles):
        particles.queue_free()