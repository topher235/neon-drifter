class_name CollectibleShopItem
extends PanelContainer

## Preview display for a single collectible in the shop
## Shows icon preview, name, and unlock button
## Clicking the panel shows the collectible description

signal unlock_requested(collectible_id: String)
signal item_clicked(collectible_id: String, description: String)
@onready var preview_icon: TextureRect = $MarginContainer/VBoxContainer/PreviewContainer/PreviewIcon
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var unlock_button: Button = $MarginContainer/VBoxContainer/UnlockButton
@onready var cost_label: Label = $MarginContainer/VBoxContainer/CostLabel
@onready var unlocked_label: Label = $MarginContainer/VBoxContainer/UnlockedLabel

var collectible: CollectibleData
var collectible_id: String
var preview_instance: Node2D = null  # Instance of the actual collectible for preview
# Shader for icon colorization
var neon_shader: Shader = preload("res://assets/shaders/neon_icon.gdshader")


func _ready() -> void:
    unlock_button.pressed.connect(_on_unlock_pressed)


func _gui_input(event: InputEvent) -> void:
    """Handle clicks on the panel to show description"""
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if collectible:
                item_clicked.emit(collectible_id, collectible.description)
                AudioManager.play_sfx("ui_click")


func setup(p_collectible: CollectibleData, p_collectible_id: String) -> void:
    """Initialize the shop item with a collectible"""
    collectible = p_collectible
    collectible_id = p_collectible_id

    if not is_node_ready():
        await ready

    # Set name
    name_label.text = collectible.collectible_name

    # Clear any existing preview instance
    if preview_instance:
        preview_instance.queue_free()
        preview_instance = null

    # Set preview based on what's available
    if collectible.scene_path and not collectible.scene_path.is_empty():
        # Use the actual collectible scene for preview
        _setup_scene_preview()
    elif collectible.icon_texture:
        # Use the icon texture
        _setup_texture_preview()
    else:
        # Fallback: use simple color
        _setup_fallback_preview()

    # Update button states
    _update_button_states()


func _setup_scene_preview() -> void:
    """Load and instantiate the actual collectible scene for preview"""
    # Hide the texture rect since we're using a scene instance
    preview_icon.visible = false

    var scene = load(collectible.scene_path)
    if scene:
        preview_instance = scene.instantiate()

        # Find the preview container to add the instance to
        var preview_container = preview_icon.get_parent()
        if preview_container and preview_container is CenterContainer:
            # Create a SubViewportContainer to properly render Node2D in UI
            var viewport_container = SubViewportContainer.new()
            viewport_container.custom_minimum_size = Vector2(60, 60)
            viewport_container.stretch = true

            # Create a SubViewport to hold the 2D scene
            var viewport = SubViewport.new()
            viewport.size = Vector2i(60, 60)
            viewport.transparent_bg = true
            viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

            viewport_container.add_child(viewport)
            viewport.add_child(preview_instance)
            preview_container.add_child(viewport_container)

            # Center the preview instance within the viewport
            preview_instance.position = Vector2(30, 30)  # Center in 60x60 viewport

            # Scale down the collectible to fit in the preview area
            preview_instance.scale = Vector2(0.8, 0.8)

            # Disable any collision or interactive behavior
            if preview_instance.has_node("CollisionShape2D"):
                var collision = preview_instance.get_node("CollisionShape2D")
                collision.disabled = true

            # Disable any Area2D monitoring
            if preview_instance is Area2D:
                preview_instance.monitoring = false
                preview_instance.monitorable = false

            # Stop any animations or physics
            preview_instance.set_process(false)
            preview_instance.set_physics_process(false)


func _setup_texture_preview() -> void:
    """Use the icon texture for preview"""
    preview_icon.visible = true
    preview_icon.texture = collectible.icon_texture

    # Apply shader with collectible color for colorization
    var shader_material = ShaderMaterial.new()
    shader_material.shader = neon_shader
    shader_material.set_shader_parameter("target_color", collectible.collectible_color)
    preview_icon.material = shader_material


func _setup_fallback_preview() -> void:
    """Fallback to simple color preview"""
    preview_icon.visible = true
    preview_icon.texture = null
    preview_icon.modulate = collectible.collectible_color


func _update_button_states() -> void:
    """Update button visibility based on unlock state"""
    var is_unlocked = CollectibleManager.is_collectible_unlocked(collectible_id)
    # Non-buyable collectibles should never show unlock button
    var can_be_purchased = collectible.buyable if collectible else true

    unlock_button.visible = not is_unlocked and can_be_purchased
    cost_label.visible = not is_unlocked and can_be_purchased
    unlocked_label.visible = is_unlocked

    unlock_button.disabled = not SaveManager.can_afford_buyable(collectible.orb_cost)

    # Update cost label text
    if not is_unlocked and collectible and can_be_purchased:
        cost_label.text = "%d orbs" % collectible.orb_cost


func refresh() -> void:
    """Refresh button states (call when collectibles are unlocked)"""
    _update_button_states()


func _on_unlock_pressed() -> void:
    unlock_requested.emit(collectible_id)
