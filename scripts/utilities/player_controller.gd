class_name PlayerController
extends Node

## Base class for player movement controllers
## Subclasses implement different movement behaviors (auto-run, free movement, etc.)

# Signals
signal movement_updated(target_position: Vector2)
# Configuration
var tunnel_half_width: float  = 150.0
var movement_smoothing: float = 0.15
# References
var player: Node2D
var camera: Camera2D


func _ready() -> void:
    set_physics_process(false)


func initialize(player_node: Node2D, camera_node: Camera2D) -> void:
    player = player_node
    camera = camera_node
    set_physics_process(true)


## Override in subclasses to implement movement logic
## Returns the target position the player should move towards
func get_target_position(current_position: Vector2, delta: float) -> Vector2:
    return current_position


## Override to handle input (optional)
func handle_input() -> void:
    pass


## Override for any per-frame updates
func update_controller(delta: float) -> void:
    pass
