class_name CollectibleShopItem
extends PanelContainer

## Preview display for a single collectible in the shop
## Shows icon preview, name, and unlock button
## Clicking the panel shows the collectible description

signal unlock_requested(collectible_id: String)
signal item_clicked(collectible_id: String, description: String)
@onready var preview_icon: ColorRect = $MarginContainer/VBoxContainer/PreviewContainer/PreviewIcon
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var unlock_button: Button = $MarginContainer/VBoxContainer/UnlockButton
@onready var cost_label: Label = $MarginContainer/VBoxContainer/CostLabel
@onready var unlocked_label: Label = $MarginContainer/VBoxContainer/UnlockedLabel

var collectible: CollectibleData
var collectible_id: String


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

    # Set preview icon color
    preview_icon.color = collectible.collectible_color

    # Update button states
    _update_button_states()


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
