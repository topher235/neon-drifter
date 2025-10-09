class_name PlayerLine
extends Node2D

# Configuration
@export_group("Movement")
@export var movement_smoothing: float = 15.0  # Higher = snappier (lerp speed)
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
@onready var death_particles: GPUParticles2D = $DeathParticles

# Movement controller
var movement_controller: PlayerController

# State
var trail_points: Array[Vector2] = []
var target_position: Vector2 = Vector2.ZERO
var current_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var is_alive: bool = true
var invulnerable: bool = false
var invulnerable_timer: Timer
var magnet_active: bool = false
var magnet_timer: Timer
var magnet_range: float = 200.0  # Range to attract orbs

# Movement bounds
var tunnel_half_width: float = 125.0  # Half of 250

# Trail optimization
var last_trail_point: Vector2 = Vector2.ZERO
var distance_since_last_point: float = 0.0

# Cosmetics
var current_cosmetic: TrailCosmetic = null

func _ready() -> void:
    add_to_group("player")

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

    # Connect to cosmetic system
    CosmeticManager.cosmetic_changed.connect(_on_cosmetic_changed)
    _apply_cosmetic(CosmeticManager.get_selected_cosmetic())

    # Setup controller after everything else (allows movement_mode to be set first)
    call_deferred("_setup_movement_controller")

func _process(delta: float) -> void:
    if not GameManager.is_playing() or not is_alive:
        return

    _handle_input()
    _update_position(delta)
    _update_trail()
    _update_trail_colors()  # Update colors every frame for animated cosmetics
    _check_bounds()

    if magnet_active:
        _attract_orbs(delta)

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
        # Use lerp for consistent smoothing speed regardless of distance
        var lerp_speed = movement_smoothing * delta
        current_position.x = lerp(current_position.x, target_position.x, lerp_speed)
        current_position.y = target_position.y  # Direct Y movement
        velocity.x = (current_position.x - position.x) / delta if delta > 0 else 0
    else:
        # FreeMovement: Smooth both axes
        var lerp_speed = movement_smoothing * delta
        current_position = current_position.lerp(target_position, lerp_speed)
        velocity = (current_position - position) / delta if delta > 0 else Vector2.ZERO

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

    # Check Area2D overlaps (obstacles, collectibles, and triggers)
    var overlapping_areas = collision_area.get_overlapping_areas()
    for area in overlapping_areas:
        if area.is_in_group("obstacles"):
            _handle_obstacle_collision(area)
        elif area.is_in_group("collectibles"):
            _handle_collectible_collision(area)
        elif area.collision_layer == 16:  # End segment trigger
            _handle_end_segment_trigger(area)
        elif area.is_in_group("boundary_kill_zone"):  # Boundary kill zone
            _handle_boundary_collision(area)

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

func _handle_boundary_collision(_boundary: Area2D) -> void:
    if is_alive:
        is_alive = false
        kill()

func _handle_collectible_collision(collectible: Area2D) -> void:
    if collectible.has_method("collect"):
        collectible.collect()

func _handle_end_segment_trigger(trigger: Area2D) -> void:
    # Player reached the end segment in daily challenge or rush mode
    print("Player reached end segment trigger!")
    if GameManager.current_game_mode == GameManager.GameMode.DAILY_CHALLENGE:
        GameManager.complete_daily_challenge()
    elif GameManager.current_game_mode == GameManager.GameMode.RUSH:
        GameManager.complete_rush_challenge()

func _die() -> void:
    print("Player collision detected!")
    AudioManager.play_sfx("collision")
    _spawn_death_particles()
    _trigger_screen_shake()
    await get_tree().create_timer(death_particles.lifetime * 0.7).timeout
    GameManager.end_game.call_deferred()

    # Visual feedback
    modulate = Color(1, 0.2, 0.2, 0.5)

func _spawn_death_particles() -> void:
    # Stop trail particles
    if particle_trail:
        particle_trail.emitting = false

    # Add to parent so it persists after player is removed
    death_particles.global_position = global_position
    death_particles.emitting = true

    
func _trigger_screen_shake() -> void:
    if camera:
        camera.apply_shake(0.3, 20.0)  # We'll implement this in camera

# Invulnerability (for powerups/testing)
func make_invulnerable(duration: float) -> void:
    print("player IS invulnerable")
    invulnerable = true
    modulate = Color(1, 1, 1, 0.5)

    # If already invulnerable, add the new duration to remaining time
    var time_left := 0.0
    if invulnerable_timer and invulnerable_timer.time_left > 0.0:
        time_left = invulnerable_timer.time_left
        invulnerable_timer.stop()
        invulnerable_timer.queue_free()

    # Create and start new timer with combined duration
    invulnerable_timer = Timer.new()
    invulnerable_timer.wait_time = duration + time_left
    invulnerable_timer.one_shot = true
    invulnerable_timer.timeout.connect(_disable_invulnerability)
    add_child(invulnerable_timer)
    invulnerable_timer.start()

func activate_invincibility(duration: float) -> void:
    """Public method called by star collectible"""
    make_invulnerable(duration)


func _disable_invulnerability() -> void:
    print("player is NOT invulnerable")
    invulnerable = false
    modulate = Color.WHITE
    if invulnerable_timer:
        invulnerable_timer.queue_free()
        invulnerable_timer = null

# Magnet Powerup
func activate_magnet(duration: float) -> void:
    """Public method called by magnet collectible"""
    print("Magnet activated for ", duration, " seconds")
    magnet_active = true

    # If already active, add the new duration to remaining time
    var time_left := 0.0
    if magnet_timer and magnet_timer.time_left > 0.0:
        time_left = magnet_timer.time_left
        magnet_timer.stop()
        magnet_timer.queue_free()

    # Create and start new timer with combined duration
    magnet_timer = Timer.new()
    magnet_timer.wait_time = duration + time_left
    magnet_timer.one_shot = true
    magnet_timer.timeout.connect(_disable_magnet)
    add_child(magnet_timer)
    magnet_timer.start()

func _disable_magnet() -> void:
    print("Magnet deactivated")
    magnet_active = false
    if magnet_timer:
        magnet_timer.queue_free()
        magnet_timer = null

func _attract_orbs(delta: float) -> void:
    # Find all collectibles in range and pull orbs toward player
    var collectibles = get_tree().get_nodes_in_group("collectibles")

    for collectible in collectibles:
        # Only attract orbs, not other collectibles
        if not collectible.is_in_group("orb"):
            continue

        # Check if collectible is already collected
        if collectible.has_method("is_collected") and collectible.is_collected:
            continue

        var distance = current_position.distance_to(collectible.global_position)

        # If within range, attract the orb
        if distance < magnet_range and distance > collision_radius:
            var direction = (current_position - collectible.global_position).normalized()
            var attraction_strength = 800.0  # Pixels per second
            var pull_velocity = direction * attraction_strength * delta

            # Move the orb toward the player
            collectible.global_position += pull_velocity


# Setup Methods
func _setup_line_renderer() -> void:
    line_renderer.width = line_width
    line_renderer.default_color = Color(0, 1, 1, 1)  # Cyan (default)
    line_renderer.begin_cap_mode = Line2D.LINE_CAP_ROUND
    line_renderer.end_cap_mode = Line2D.LINE_CAP_ROUND
    line_renderer.joint_mode = Line2D.LINE_JOINT_ROUND
    line_renderer.antialiased = true
    # Gradient will be set by cosmetic system

func _setup_collision() -> void:
    var shape = CircleShape2D.new()
    shape.radius = collision_radius
    collision_shape.shape = shape

    collision_area.collision_layer = 1  # Player layer
    collision_area.collision_mask = 62  # Obstacles (2) + Collectibles (4) + Walls (8) + Triggers (16) + Boundary (32)

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
    make_invulnerable(0.1)  # 100ms grace period

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

    
func kill() -> void:
    _die()


# Cosmetic System
func _apply_cosmetic(cosmetic: TrailCosmetic) -> void:
    """Apply a cosmetic to the trail"""
    current_cosmetic = cosmetic
    _update_trail_colors()


func _update_trail_colors() -> void:
    """Update trail colors based on current cosmetic"""
    if not current_cosmetic or not line_renderer:
        return

    var trail_length = trail_points.size()
    if trail_length == 0:
        return

    # For solid colors, use a simple fade gradient
    if current_cosmetic.cosmetic_type == TrailCosmetic.CosmenticType.SOLID:
        var fade_gradient = Gradient.new()
        var color = current_cosmetic.solid_color
        fade_gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))  # Transparent at tail
        fade_gradient.add_point(0.5, Color(color.r, color.g, color.b, 0.5))  # Semi-transparent mid
        fade_gradient.set_color(1, Color(color.r, color.g, color.b, 1.0))  # Opaque at head
        line_renderer.gradient = fade_gradient

    # For gradients and animated, apply gradient with alpha multiplier
    else:
        # Clone the cosmetic's gradient and apply alpha fade
        var base_gradient = current_cosmetic.gradient
        if not base_gradient:
            return

        var custom_gradient = Gradient.new()
        var time = Time.get_ticks_msec() / 1000.0

        # For animated gradients, we need to offset the sampling
        var time_offset = 0.0
        if current_cosmetic.cosmetic_type == TrailCosmetic.CosmenticType.ANIMATED:
            time_offset = fmod(time * current_cosmetic.animation_speed, 1.0)

        # Sample the gradient at multiple points and apply alpha fade
        var num_samples = 20
        for j in range(num_samples + 1):
            var t = float(j) / float(num_samples)

            # For animated, offset the sample position
            var sample_pos = t
            if current_cosmetic.cosmetic_type == TrailCosmetic.CosmenticType.ANIMATED:
                sample_pos = fmod(t + time_offset, 1.0)

            var color = base_gradient.sample(sample_pos)

            # Apply alpha fade (transparent at tail, opaque at head)
            var alpha = lerp(0.0, 1.0, t)
            color.a = alpha

            if j == 0:
                custom_gradient.set_color(0, color)
                custom_gradient.set_offset(0, 0.0)
            elif j == num_samples:
                custom_gradient.set_color(1, color)
                custom_gradient.set_offset(1, 1.0)
            else:
                custom_gradient.add_point(t, color)

        line_renderer.gradient = custom_gradient


func _on_cosmetic_changed(cosmetic: TrailCosmetic) -> void:
    """Handle cosmetic change signal"""
    _apply_cosmetic(cosmetic)
