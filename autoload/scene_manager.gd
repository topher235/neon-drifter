extends Node
## SceneManager - Handles scene transitions and loading
##
## This autoload singleton manages all scene transitions in the game,
## providing smooth fade in/out effects and loading state management.

signal scene_loading_started(scene_path: String)
signal scene_loading_finished(scene_path: String)
signal transition_started
signal transition_finished
## Scene paths for easy reference
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const GAME_SCENE      := "res://scenes/game/game.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over.tscn"
## Transition settings
@export var fade_duration: float = 0.3
@export var fade_color: Color = Color.BLACK

## Reference to the transition overlay (ColorRect)
var transition_overlay: ColorRect
var is_transitioning: bool     = false
var current_scene_path: String = ""


func _ready() -> void:
    # Create the transition overlay
    _create_transition_overlay()

    # Track the initial scene
    var root          = get_tree().root
    var current_scene = root.get_child(root.get_child_count() - 1)
    current_scene_path = current_scene.scene_file_path


func _create_transition_overlay() -> void:
    """Create a fullscreen ColorRect for fade transitions"""
    transition_overlay = ColorRect.new()
    transition_overlay.name = "TransitionOverlay"
    transition_overlay.color = fade_color
    transition_overlay.modulate.a = 0.0
    transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # Make it fullscreen
    transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    transition_overlay.z_index = 1000  # Ensure it's on top

    # Add to the scene tree (as a child of root, not current scene)
    get_tree().root.add_child.call_deferred(transition_overlay)


func change_scene(scene_path: String, fade_out: bool = true, fade_in: bool = true) -> void:
    """
    Change to a new scene with optional fade transitions.

    Args:
        scene_path: Path to the scene file to load
        fade_out: Whether to fade out before switching
        fade_in: Whether to fade in after switching
    """
    if is_transitioning:
        push_warning("SceneManager: Scene transition already in progress")
        return

    is_transitioning = true
    transition_started.emit()
    scene_loading_started.emit(scene_path)

    # Ensure overlay is on top and can block input during transition
    if fade_out or fade_in:
        transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

    if fade_out:
        await _fade_out()

    # Change the scene
    var error = get_tree().change_scene_to_file(scene_path)
    if error != OK:
        push_error("SceneManager: Failed to load scene: %s (Error: %d)" % [scene_path, error])
        is_transitioning = false
        transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return

    current_scene_path = scene_path

    # Wait one frame for the scene to be ready
    await get_tree().process_frame

    if fade_in:
        await _fade_in()

    transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    is_transitioning = false
    scene_loading_finished.emit(scene_path)
    transition_started.emit()


func change_scene_to_packed(packed_scene: PackedScene, fade_out: bool = true, fade_in: bool = true) -> void:
    """
    Change to a new scene using a preloaded PackedScene.

    Args:
        packed_scene: The preloaded PackedScene to switch to
        fade_out: Whether to fade out before switching
        fade_in: Whether to fade in after switching
    """
    if is_transitioning:
        push_warning("SceneManager: Scene transition already in progress")
        return

    is_transitioning = true
    transition_started.emit()

    # Ensure overlay is on top and can block input during transition
    if fade_out or fade_in:
        transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

    if fade_out:
        await _fade_out()

    # Change the scene
    var error = get_tree().change_scene_to_packed(packed_scene)
    if error != OK:
        push_error("SceneManager: Failed to load packed scene (Error: %d)" % error)
        is_transitioning = false
        transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return

    current_scene_path = ""  # Unknown path for packed scenes

    # Wait one frame for the scene to be ready
    await get_tree().process_frame

    if fade_in:
        await _fade_in()

    transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    is_transitioning = false
    transition_finished.emit()


func reload_current_scene(fade_out: bool = true, fade_in: bool = true) -> void:
    """Reload the current scene with optional fade transitions"""
    if current_scene_path.is_empty():
        push_warning("SceneManager: Cannot reload scene - path unknown")
        return

    await change_scene(current_scene_path, fade_out, fade_in)


func goto_main_menu(fade_out: bool = true, fade_in: bool = true) -> void:
    """Convenience method to go to main menu"""
    await change_scene(MAIN_MENU_SCENE, fade_out, fade_in)


func goto_game(fade_out: bool = true, fade_in: bool = true) -> void:
    """Convenience method to start the game"""
    await change_scene(GAME_SCENE, fade_out, fade_in)


func _fade_out() -> void:
    """Fade to black (or fade_color)"""
    var tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 1.0, fade_duration)
    await tween.finished


func _fade_in() -> void:
    """Fade from black (or fade_color) to transparent"""
    var tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 0.0, fade_duration)
    await tween.finished
