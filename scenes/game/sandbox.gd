extends Node2D

@onready var player: PlayerLine = $Player
@onready var sandbox_ui: SandboxUi = $UI/SandboxUI

# Prefabs for spawning
var pillar_scene := preload("res://scenes/obstacles/pillar.tscn")
var orb_scene := preload("res://scenes/collectibles/orb.tscn")
var shockwave_scene := preload("res://scenes/obstacles/shockwave.tscn")
var star_scene := preload("res://scenes/collectibles/star.tscn")
var magnet_scene := preload("res://scenes/collectibles/magnet.tscn")
var stopwatch_scene := preload("res://scenes/collectibles/stopwatch.tscn")

# Spawn container
var spawn_container: Node2D

# Input mode
var current_input_mode: String = "spawn"  # "spawn" or "move"

func _ready() -> void:
    # Create a container for spawned objects
    spawn_container = Node2D.new()
    spawn_container.name = "SpawnedObjects"
    add_child(spawn_container)

    # Move it before player in tree so objects render behind player
    move_child(spawn_container, get_child_count() - 2)

    # Start GameManager in playing state so player updates
    GameManager.start_game()

    # Initialize player for sandbox
    if player:
        # Ensure player is visible
        player.visible = true
        player.modulate = Color.WHITE

        # Initialize player
        player.is_alive = true
        player.current_position = Vector2(0, -200)
        player.target_position = Vector2(0, -200)
        player.position = player.current_position

        # Make sure trail is visible
        if player.has_node("Line2D"):
            player.get_node("Line2D").visible = true

        # Enable camera
        if player.has_node("Camera2D"):
            var cam = player.get_node("Camera2D")
            cam.enabled = true

    # Connect UI signals
    if sandbox_ui:
        sandbox_ui.spawn_pillar_requested.connect(_on_spawn_pillar)
        sandbox_ui.spawn_orb_requested.connect(_on_spawn_orb)
        sandbox_ui.spawn_shockwave_requested.connect(_on_spawn_shockwave)
        sandbox_ui.spawn_star_requested.connect(_on_spawn_star)
        sandbox_ui.spawn_magnet_requested.connect(_on_spawn_magnet)
        sandbox_ui.spawn_stopwatch_requested.connect(_on_spawn_stopwatch)
        sandbox_ui.clear_requested.connect(_on_clear_all)
        sandbox_ui.input_mode_changed.connect(_on_input_mode_changed)

    # Add a visual marker at origin for reference
    _add_origin_marker()

func _add_origin_marker() -> void:
    # Create a visual marker at 0,0 to help with positioning
    var marker = ColorRect.new()
    marker.size = Vector2(20, 20)
    marker.position = Vector2(-10, -10)
    marker.color = Color.RED
    var canvas = CanvasLayer.new()
    canvas.layer = 10
    add_child(canvas)

    var marker_label = Label.new()
    marker_label.text = "Origin (0,0)"
    marker_label.position = Vector2(15, -10)

    # Position based on camera
    if player and player.has_node("Camera2D"):
        var cam = player.get_node("Camera2D")
        marker.position = Vector2(-10, -210)  # Near player start
        marker_label.position = Vector2(15, -210)

func _input(event: InputEvent) -> void:
    # Only handle spawning if in spawn mode
    if current_input_mode == "spawn":
        player.is_alive = false
        # Left click to spawn item at mouse position
        if event is InputEventMouseButton:
            if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
                # Check if clicking on interactive UI (buttons, etc.)
                var ui_clicked = _is_clicking_interactive_ui(event.position)

                if not ui_clicked:
                    # Convert screen position to world position via camera
                    var camera = player.get_node("Camera2D") if player else null
                    var world_pos: Vector2

                    if camera:
                        # Get camera's position and convert screen to world
                        var viewport_size = get_viewport_rect().size
                        var screen_pos = event.position
                        var camera_pos = camera.get_screen_center_position()

                        # Convert screen coordinates to world coordinates
                        world_pos = camera_pos + (screen_pos - viewport_size / 2.0)
                    else:
                        # Fallback to global mouse position
                        world_pos = get_global_mouse_position()

                    print("Click at screen: ", event.position, " -> world: ", world_pos)
                    _spawn_item_at_position(world_pos)
                    get_viewport().set_input_as_handled()
    # In move mode, let the player movement controller handle input
    else:
        player.is_alive = true

func _is_clicking_interactive_ui(screen_pos: Vector2) -> bool:
    # Check if the click is on interactive UI elements (buttons)
    # We only want to block spawning if clicking on actual buttons, not just UI panels
    if sandbox_ui:
        # Check if clicking on the panel area
        var panel = sandbox_ui.get_node_or_null("Panel")
        if panel:
            var panel_rect = panel.get_global_rect()
            if panel_rect.has_point(screen_pos):
                # Clicking on UI panel, block spawning
                return true
    return false

func _spawn_item_at_position(world_pos: Vector2) -> void:
    # Alternate between spawning pillars and orbs based on current mode
    if sandbox_ui and sandbox_ui.current_spawn_mode == "pillar":
        _create_pillar(world_pos)
    elif sandbox_ui and sandbox_ui.current_spawn_mode == "orb":
        _create_orb(world_pos)
    elif sandbox_ui and sandbox_ui.current_spawn_mode == "shockwave":
        _create_shockwave(world_pos)
    elif sandbox_ui and sandbox_ui.current_spawn_mode == "star":
        _create_star(world_pos)
    elif sandbox_ui and sandbox_ui.current_spawn_mode == "magnet":
        _create_magnet(world_pos)
    elif sandbox_ui and sandbox_ui.current_spawn_mode == "stopwatch":
        _create_stopwatch(world_pos)

func _on_spawn_pillar(world_pos: Vector2) -> void:
    _create_pillar(world_pos)

func _on_spawn_orb(world_pos: Vector2) -> void:
    _create_orb(world_pos)

func _on_spawn_shockwave(world_pos: Vector2) -> void:
    _create_shockwave(world_pos)

func _on_spawn_star(world_pos: Vector2) -> void:
    _create_star(world_pos)

func _on_spawn_magnet(world_pos: Vector2) -> void:
    _create_magnet(world_pos)

func _on_spawn_stopwatch(world_pos: Vector2) -> void:
    _create_stopwatch(world_pos)

func _create_pillar(world_pos: Vector2) -> void:
    var pillar = pillar_scene.instantiate()
    spawn_container.add_child(pillar)
    pillar.position = world_pos
    pillar.visible = true
    pillar.z_index = 10

func _create_orb(world_pos: Vector2) -> void:
    var orb = orb_scene.instantiate()
    spawn_container.add_child(orb)
    orb.position = world_pos
    orb.visible = true
    orb.z_index = 10

func _create_shockwave(world_pos: Vector2) -> void:
    var shockwave = shockwave_scene.instantiate()
    spawn_container.add_child(shockwave)
    shockwave.position = world_pos
    shockwave.visible = true
    shockwave.z_index = 10

func _create_star(world_pos: Vector2) -> void:
    var star = star_scene.instantiate()
    spawn_container.add_child(star)
    star.position = world_pos
    star.visible = true
    star.z_index = 10

func _create_magnet(world_pos: Vector2) -> void:
    var magnet = magnet_scene.instantiate()
    spawn_container.add_child(magnet)
    magnet.position = world_pos
    magnet.visible = true
    magnet.z_index = 10

func _create_stopwatch(world_pos: Vector2) -> void:
    var stopwatch = stopwatch_scene.instantiate()
    spawn_container.add_child(stopwatch)
    stopwatch.position = world_pos
    stopwatch.visible = true
    stopwatch.z_index = 10

func _on_clear_all() -> void:
    # Remove all spawned objects
    for child in spawn_container.get_children():
        child.queue_free()
    # This will reset the player, useful if they died testing an obstacle
    GameManager.start_game()

func _on_input_mode_changed(mode: String) -> void:
    current_input_mode = mode
