class_name PlayerLine
extends Node2D

# Configuration
@export_group("Movement")
@export var movement_smoothing: float = 0.15
@export_enum("AutoRun", "FreeMovement") var movement_mode: String = "AutoRun"

@export_group("Trail")
@export var line_width: float = 8.0
@export var max_trail_points: int = 50
@export var trail_point_distance: float = 5.0  # Minimum distance between points

@export_group("Collision")
@export var collision_radius: float = 12.0
@export var invulnerability_time: float = 0.0  # For testing/powerups

# Components
@onready var line_renderer: Line2D = $Line2D
@onready var collision_area: Area2D = $CollisionArea
@onready var collision_shape: CollisionShape2D = $CollisionArea/CollisionShape2D
@onready var camera: PlayerCamera = $Camera2D
@onready var particle_trail: GPUParticles2D = $ParticleTrail

# Movement controller
var movement_controller: PlayerController

# State
var trail_points: Array[Vector2] = []
var target_position: Vector2 = Vector2.ZERO
var current_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var is_alive: bool = true
var invulnerable: bool = false
var invulnerability_timer: float = 0.0

# Movement bounds
var tunnel_half_width: float = 125.0  # Half of 250

# Trail optimization
var last_trail_point: Vector2 = Vector2.ZERO
var distance_since_last_point: float = 0.0

func _ready() -> void:
    _setup_line_renderer()
    _setup_collision()
    _setup_camera()
    _setup_particles()

    # Start well above the starting segment (which is at Y=0)
    # Starting segment has south wall at Y=0, so start at -200 to be safe
    current_position = Vector2(0, -200)
    target_position = Vector2(0, -200)
    position = current_position  # Set node position immediately

    # Add initial trail points so player line is visible from start
    # Add a point below (positive Y) to show trail
    trail_points.append(Vector2(0, -150))  # Trail point below player
    trail_points.append(current_position)  # Current position
    last_trail_point = current_position

    # Connect to game signals
    GameManager.game_started.connect(_on_game_started)
    GameManager.game_over.connect(_on_game_over)

    # Setup controller after everything else (allows movement_mode to be set first)
    call_deferred("_setup_movement_controller")

func _process(delta: float) -> void:
    if not GameManager.is_playing() or not is_alive:
        return

    _update_invulnerability(delta)
    _handle_input()
    _update_position(delta)
    _update_trail()
    _check_bounds()

func _physics_process(_delta: float) -> void:
    if not GameManager.is_playing() or not is_alive:
        return

    _check_collisions()

# Input Handling
func _handle_input() -> void:
    if movement_controller:
        movement_controller.handle_input()

# Position Updates
func _update_position(delta: float) -> void:
    if movement_controller:
        target_position = movement_controller.get_target_position(current_position, delta)

    # Apply movement based on controller type
    if movement_controller is AutoRunController:
        # AutoRun: Smooth X only, Y moves directly
        var x_diff = target_position.x - current_position.x
        velocity.x = x_diff / movement_smoothing
        current_position.x += velocity.x * delta
        current_position.y = target_position.y  # Direct Y movement
    else:
        # FreeMovement: Smooth both axes
        var diff = target_position - current_position
        velocity = diff / movement_smoothing
        current_position += velocity * delta

    position = current_position

func _check_bounds() -> void:
    # Hard clamp if somehow outside bounds
    if abs(current_position.x) > tunnel_half_width:
        current_position.x = clamp(current_position.x, -tunnel_half_width, tunnel_half_width)
        position = current_position

# Trail Rendering
func _update_trail() -> void:
    # Only add point if we've moved enough distance
    var distance_moved = current_position.distance_to(last_trail_point)

    if distance_moved >= trail_point_distance:
        trail_points.append(current_position)
        last_trail_point = current_position

        # Remove old points
        if trail_points.size() > max_trail_points:
            trail_points.pop_front()

    # Update Line2D
    _render_trail()

func _render_trail() -> void:
    line_renderer.clear_points()

    for i in range(trail_points.size()):
        var point = trail_points[i]
        # Convert to local space
        var local_point = point - current_position
        line_renderer.add_point(local_point)

# Collision Detection
func _check_collisions() -> void:
    if invulnerable:
        return

    # Check Area2D overlaps (obstacles and collectibles)
    var overlapping_areas = collision_area.get_overlapping_areas()
    for area in overlapping_areas:
        if area.is_in_group("obstacles"):
            _handle_obstacle_collision(area)
        elif area.is_in_group("collectibles"):
            _handle_collectible_collision(area)

    # Check StaticBody2D overlaps (walls)
    var overlapping_bodies = collision_area.get_overlapping_bodies()
    for body in overlapping_bodies:
        if body is StaticBody2D and body.collision_layer == 8:  # Wall collision
            _handle_wall_collision(body)

func _handle_obstacle_collision(obstacle: Area2D) -> void:
    if is_alive and not invulnerable:
        is_alive = false
        _die()

func _handle_wall_collision(wall: StaticBody2D) -> void:
    if is_alive and not invulnerable:
        is_alive = false
        _die()

func _handle_collectible_collision(collectible: Area2D) -> void:
    if collectible.has_method("collect"):
        collectible.collect()

func _die() -> void:
    print("Player collision detected!")
    AudioManager.play_sfx("collision")
    _spawn_death_particles()
    _trigger_screen_shake()
    GameManager.end_game()

    # Visual feedback
    modulate = Color(1, 0.2, 0.2, 0.5)

func _spawn_death_particles() -> void:
    # Create explosion effect
    if particle_trail:
        particle_trail.emitting = false

# Could spawn a separate explosion particle system here

func _trigger_screen_shake() -> void:
    if camera:
        camera.apply_shake(0.3, 20.0)  # We'll implement this in camera

# Invulnerability (for powerups/testing)
func make_invulnerable(duration: float) -> void:
    invulnerable = true
    invulnerability_timer = duration
    modulate = Color(1, 1, 1, 0.5)

func _update_invulnerability(delta: float) -> void:
    if invulnerable:
        invulnerability_timer -= delta
        if invulnerability_timer <= 0:
            invulnerable = false
            modulate = Color.WHITE

# Setup Methods
func _setup_line_renderer() -> void:
    line_renderer.width = line_width
    line_renderer.default_color = Color(0, 1, 1, 1)  # Cyan
    line_renderer.begin_cap_mode = Line2D.LINE_CAP_ROUND
    line_renderer.end_cap_mode = Line2D.LINE_CAP_ROUND
    line_renderer.joint_mode = Line2D.LINE_JOINT_ROUND
    line_renderer.antialiased = true

    # Set up gradient for trail fade
    var gradient = Gradient.new()
    gradient.set_color(0.3, Color(0, 1, 1, 0.0))  # Fully transparent at tail (oldest)
    gradient.add_point(0.8, Color(0, 1, 1, 0.5))  # Semi-transparent mid-trail
    gradient.set_color(1, Color(0, 1, 1, 1.0))  # Fully opaque at head (newest)
    line_renderer.gradient = gradient

func _setup_collision() -> void:
    var shape = CircleShape2D.new()
    shape.radius = collision_radius
    collision_shape.shape = shape

    collision_area.collision_layer = 1  # Player layer
    collision_area.collision_mask = 14  # Obstacles (2) + Collectibles (4) + Walls (8)

func _setup_camera() -> void:
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    # Offset camera so player appears lower on screen (positive Y offset = camera looks up)
    # This shows more tunnel ahead (upward/negative Y direction)
    camera.offset = Vector2(0, -300)  # Negative offset = camera positioned above player

func _setup_particles() -> void:
    if particle_trail:
        particle_trail.emitting = false
        # Configure particle settings
        particle_trail.amount = 50
        particle_trail.lifetime = 0.5
        particle_trail.local_coords = false
# We'll set up the particle material later

func _setup_movement_controller() -> void:
    # Create appropriate controller based on movement mode
    if movement_mode == "FreeMovement":
        movement_controller = FreeMovementController.new()
    else:  # AutoRun (default)
        movement_controller = AutoRunController.new()

    add_child(movement_controller)
    movement_controller.tunnel_half_width = tunnel_half_width
    movement_controller.movement_smoothing = movement_smoothing
    movement_controller.initialize(self, camera)

# Signal Handlers
func _on_game_started() -> void:
    is_alive = true
    # Start well above the starting segment (which is at Y=0)
    current_position = Vector2(0, -200)
    target_position = Vector2(0, -200)
    position = current_position  # Set node position immediately
    trail_points.clear()
    # Add initial trail points so player line is visible from start
    trail_points.append(Vector2(0, -150))  # Trail point below player
    trail_points.append(current_position)  # Current position
    last_trail_point = current_position
    line_renderer.clear_points()
    modulate = Color.WHITE

    # Give brief invulnerability at start to prevent immediate collision
    invulnerable = true
    invulnerability_timer = 0.1  # 100ms grace period

    if particle_trail:
        particle_trail.emitting = true

func _on_game_over(_score: int, _distance: float) -> void:
    if particle_trail:
        particle_trail.emitting = false

# Public Methods
func get_world_position() -> Vector2:
    return current_position

func reset() -> void:
    current_position = Vector2.ZERO
    target_position = Vector2.ZERO
    velocity = Vector2.ZERO
    trail_points.clear()
    is_alive = true
    invulnerable = false
