class_name BaseCollectible
extends Area2D

# Signals
signal collected(collectible: BaseCollectible)

# State
var is_collected: bool = false
var bob_offset: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO
var particles: Node

# Visual
@export var visual: ColorRect
@export var collision_shape: CollisionShape2D

func _ready() -> void:
    add_to_group("collectibles")
    collision_layer = 4  # Collectible layer
    collision_mask = 1   # Collide with player

    spawn_position = position
    bob_offset = randf() * TAU  # Random phase for bobbing

    # Spawn particle effect at orb position
    var particles_scene = preload("res://scenes/collectibles/collect_particles.tscn")
    particles = particles_scene.instantiate()
    var parent = get_parent()
    if parent:
        parent.add_child(particles)

    area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
    if is_collected:
        return

    _animate(delta)

func _animate(delta: float) -> void:
    # Bob up and down
    bob_offset += delta * 3.0
    if visual:
        visual.position.y = sin(bob_offset) * 5.0

func _on_area_entered(area: Area2D) -> void:
    if area.get_parent().is_in_group("player") and not is_collected:
        collect()

func collect() -> void:
    if is_collected:
        return

    is_collected = true
    _on_collected()
    collected.emit(self)
    _play_collect_animation()

# Virtual method - override in derived classes
func _on_collected() -> void:
    pass

func _play_collect_animation() -> void:
    # Scale up and fade out
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "scale", Vector2(2, 2), 0.3)
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.chain().tween_callback(queue_free)


func _spawn_particles() -> void:
    # Set global position to this collectible's position, then emit
    particles.global_position = global_position
    particles.emitting = true

    # Clean up particles after they finish
    await get_tree().create_timer(particles.lifetime).timeout
    if is_instance_valid(particles):
        particles.queue_free()