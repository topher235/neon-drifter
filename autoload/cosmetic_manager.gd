extends Node

## Global manager for player trail cosmetics
## Handles cosmetic library, selection, and unlocking

signal cosmetic_changed(cosmetic: TrailCosmetic)
signal cosmetic_unlocked(cosmetic_id: String)
var cosmetics: Dictionary        = {}  # cosmetic_id -> TrailCosmetic
var selected_cosmetic_id: String = "white_default"


func _ready() -> void:
    _initialize_cosmetics()
    _load_selection()


func _initialize_cosmetics() -> void:
    """Initialize all available cosmetics"""

    # Default White Trail
    var white_cosmetic = TrailCosmetic.new()
    white_cosmetic.cosmetic_id = "white_default"
    white_cosmetic.cosmetic_name = "White"
    white_cosmetic.cosmetic_type = TrailCosmetic.CosmenticType.SOLID
    white_cosmetic.solid_color = Color(1, 1, 1)  # White
    white_cosmetic.unlocked_by_default = true
    white_cosmetic.buyable = false  # Default cosmetic, not purchasable
    white_cosmetic.orb_cost = 0
    cosmetics["white_default"] = white_cosmetic

    # Cyan Trail
    var cyan_cosmetic = TrailCosmetic.new()
    cyan_cosmetic.cosmetic_id = "cyan"
    cyan_cosmetic.cosmetic_name = "Cyan"
    cyan_cosmetic.cosmetic_type = TrailCosmetic.CosmenticType.SOLID
    cyan_cosmetic.solid_color = Color(0, 1, 1)  # Cyan
    cyan_cosmetic.unlocked_by_default = false
    cyan_cosmetic.buyable = true  # Can be purchased with orbs
    cyan_cosmetic.orb_cost = 50
    cosmetics["cyan"] = cyan_cosmetic

    # Rainbow Gradient Trail
    var rainbow_cosmetic = TrailCosmetic.new()
    rainbow_cosmetic.cosmetic_id = "rainbow_gradient"
    rainbow_cosmetic.cosmetic_name = "Rainbow"
    rainbow_cosmetic.cosmetic_type = TrailCosmetic.CosmenticType.ANIMATED
    rainbow_cosmetic.animation_speed = 0.5  # Slow, smooth animation
    rainbow_cosmetic.unlocked_by_default = true  # Set to false to require unlock
    rainbow_cosmetic.buyable = true  # Can be purchased with orbs
    rainbow_cosmetic.orb_cost = 100  # Cost if locked

    # Create rainbow gradient
    var rainbow_gradient = Gradient.new()
    rainbow_gradient.set_color(0, Color(1, 0, 0))      # Red
    rainbow_gradient.set_offset(0, 0.0)
    rainbow_gradient.add_point(0.17, Color(1, 0.5, 0)) # Orange
    rainbow_gradient.add_point(0.33, Color(1, 1, 0))   # Yellow
    rainbow_gradient.add_point(0.5, Color(0, 1, 0))    # Green
    rainbow_gradient.add_point(0.67, Color(0, 0, 1))   # Blue
    rainbow_gradient.add_point(0.83, Color(0.5, 0, 1)) # Indigo
    rainbow_gradient.set_color(1, Color(1, 0, 1))      # Violet
    rainbow_gradient.set_offset(1, 1.0)

    rainbow_cosmetic.gradient = rainbow_gradient
    cosmetics["rainbow_gradient"] = rainbow_cosmetic


func get_cosmetic(cosmetic_id: String) -> TrailCosmetic:
    """Get a cosmetic by ID"""
    return cosmetics.get(cosmetic_id, cosmetics["cyan_default"])


func get_selected_cosmetic() -> TrailCosmetic:
    """Get the currently selected cosmetic"""
    return get_cosmetic(selected_cosmetic_id)


func select_cosmetic(cosmetic_id: String) -> bool:
    """
    Select a cosmetic if it's unlocked
    Returns true if selection succeeded
    """
    if not cosmetics.has(cosmetic_id):
        push_warning("Cosmetic not found: " + cosmetic_id)
        return false

    var cosmetic = cosmetics[cosmetic_id]

    # Check if unlocked
    if not is_cosmetic_unlocked(cosmetic_id):
        push_warning("Cosmetic is locked: " + cosmetic_id)
        return false

    selected_cosmetic_id = cosmetic_id
    _save_selection()
    cosmetic_changed.emit(cosmetic)
    return true


func is_cosmetic_unlocked(cosmetic_id: String) -> bool:
    """Check if a cosmetic is unlocked"""
    if not cosmetics.has(cosmetic_id):
        return false

    var cosmetic = cosmetics[cosmetic_id]

    # Always unlocked if marked as default
    if cosmetic.unlocked_by_default:
        return true

    # Check SaveManager for unlock status
    return SaveManager.is_cosmetic_unlocked(cosmetic_id)


func unlock_cosmetic(cosmetic_id: String) -> bool:
    """
    Unlock a cosmetic (typically by spending orbs)
    Returns true if unlock succeeded
    """
    if not cosmetics.has(cosmetic_id):
        return false

    if is_cosmetic_unlocked(cosmetic_id):
        return true  # Already unlocked

    var cosmetic = cosmetics[cosmetic_id]

    # Check if player has enough orbs
    if SaveManager.save_data.total_orbs_collected < cosmetic.orb_cost:
        return false

    # Unlock the cosmetic
    SaveManager.unlock_cosmetic(cosmetic_id)
    cosmetic_unlocked.emit(cosmetic_id)
    return true


func get_all_cosmetics() -> Array[TrailCosmetic]:
    """Get all cosmetics as an array"""
    var result: Array[TrailCosmetic] = []
    for cosmetic in cosmetics.values():
        result.append(cosmetic)
    return result


func _save_selection() -> void:
    """Save the current selection to SaveManager"""
    SaveManager.save_data.selected_trail = selected_cosmetic_id
    SaveManager.save_game()


func _load_selection() -> void:
    """Load the saved selection from SaveManager"""
    if SaveManager.save_data.has("selected_trail"):
        var saved_id = SaveManager.save_data.selected_trail
        if cosmetics.has(saved_id) and is_cosmetic_unlocked(saved_id):
            selected_cosmetic_id = saved_id
