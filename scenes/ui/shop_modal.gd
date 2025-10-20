class_name ShopModal
extends Control

## Shop modal for purchasing and managing cosmetics
## Can be used in main menu

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var orb_count_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Cosmetics/CosmeticsVBox/OrbCountLabel
@onready var cosmetics_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/TabContainer/Cosmetics/CosmeticsVBox/ScrollContainer/CosmeticsGrid
@onready var collectibles_orb_count_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Collectibles/CollectiblesVBox/OrbCountLabel
@onready var description_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Collectibles/CollectiblesVBox/DescriptionPanel/MarginContainer/DescriptionLabel
@onready var collectibles_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/TabContainer/Collectibles/CollectiblesVBox/ScrollContainer/CollectiblesGrid
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton
@onready var animation_player: AnimationPlayer    = $AnimationPlayer
const CosmeticPreviewScene                        = preload("res://scenes/ui/cosmetic_preview.tscn")
const CollectibleShopItemScene                    = preload("res://scenes/ui/collectible_shop_item.tscn")
var cosmetic_previews: Array[CosmeticPreview]     = []
var collectible_items: Array[CollectibleShopItem] = []


func _ready() -> void:
    # Hide modal initially
    visible = false

    # Connect signals
    close_button.pressed.connect(_on_close_button_pressed)
    CosmeticManager.cosmetic_changed.connect(_on_cosmetic_changed)
    CosmeticManager.cosmetic_unlocked.connect(_on_cosmetic_unlocked)
    CollectibleManager.collectible_unlocked.connect(_on_collectible_unlocked)

    # Initialize grids
    _populate_cosmetics_grid()
    _populate_collectibles_grid()

    # Set default tab to Cosmetics (index 0)
    tab_container.current_tab = 0

    # Update orb count
    if not Events.orb_count_updated.is_connected(_update_orb_count):
        Events.orb_count_updated.connect(_update_orb_count)
    _update_orb_count()


func _on_close_button_pressed() -> void:
    close_shop()


## Public method to open the shop modal
func open_shop() -> void:
    print("open shop")
    _update_orb_count()
    visible = true  # Make modal visible

    # Reset animation to beginning first
    animation_player.stop()
    animation_player.play("RESET")
    await get_tree().process_frame

    # Play open animation
    animation_player.play("open")


## Public method to close the shop modal
func close_shop() -> void:
    if animation_player.has_animation("open"):
        animation_player.play_backwards("open")
        await animation_player.animation_finished
    visible = false  # Hide modal after animation


func _populate_cosmetics_grid() -> void:
    """Populate the cosmetics grid with all available cosmetics"""
    # Clear existing previews
    for preview in cosmetic_previews:
        preview.queue_free()
    cosmetic_previews.clear()

    # Get all cosmetics from manager
    var all_cosmetics = CosmeticManager.get_all_cosmetics()

    # Create preview for each cosmetic
    for cosmetic in all_cosmetics:
        # Find the cosmetic ID
        var cosmetic_id = ""
        for id in CosmeticManager.cosmetics.keys():
            if CosmeticManager.cosmetics[id] == cosmetic:
                cosmetic_id = id
                break

        # Only show cosmetics that are buyable OR already unlocked
        var is_unlocked = CosmeticManager.is_cosmetic_unlocked(cosmetic_id)
        if not cosmetic.buyable and not is_unlocked:
            continue  # Skip non-buyable cosmetics that aren't unlocked yet

        var preview = CosmeticPreviewScene.instantiate()
        cosmetics_grid.add_child(preview)

        # Setup preview
        preview.setup(cosmetic, cosmetic_id)

        # Connect signals
        preview.unlock_requested.connect(_on_cosmetic_unlock_requested)
        preview.select_requested.connect(_on_cosmetic_select_requested)

        cosmetic_previews.append(preview)


func _on_cosmetic_unlock_requested(cosmetic_id: String) -> void:
    """Handle unlock button pressed"""
    var success = CosmeticManager.unlock_cosmetic(cosmetic_id)

    if success:
        AudioManager.play_sfx("ui_click")
        _refresh_all_previews()
    else:
        # Not enough orbs
        AudioManager.play_sfx("collision")
        print("Not enough orbs to unlock %s" % cosmetic_id)


func _on_cosmetic_select_requested(cosmetic_id: String) -> void:
    """Handle select button pressed"""
    var success = CosmeticManager.select_cosmetic(cosmetic_id)

    if success:
        AudioManager.play_sfx("ui_click")
        _refresh_all_previews()


func _on_cosmetic_changed(_cosmetic: TrailCosmetic) -> void:
    """Handle cosmetic changed signal from manager"""
    _refresh_all_previews()


func _on_cosmetic_unlocked(_cosmetic_id: String) -> void:
    """Handle cosmetic unlocked signal from manager"""
    _refresh_all_previews()


func _refresh_all_previews() -> void:
    """Refresh all cosmetic preview button states"""
    for preview in cosmetic_previews:
        preview.refresh()


func _update_orb_count() -> void:
    """Update the orb count labels"""
    var total_orbs = SaveManager.get_current_orbs()
    orb_count_label.text = "Orbs: %d" % total_orbs
    collectibles_orb_count_label.text = "Orbs: %d" % total_orbs


# ===== COLLECTIBLES TAB =====

func _populate_collectibles_grid() -> void:
    """Populate the collectibles grid with all available collectibles"""
    # Clear existing items
    for item in collectible_items:
        item.queue_free()
    collectible_items.clear()

    # Get all collectibles from manager
    var all_collectibles = CollectibleManager.get_all_collectibles()

    # Create shop item for each collectible
    for collectible in all_collectibles:
        # Find the collectible ID
        var collectible_id = ""
        for id in CollectibleManager.collectibles.keys():
            if CollectibleManager.collectibles[id] == collectible:
                collectible_id = id
                break

        # Only show collectibles that are buyable OR already unlocked
        var is_unlocked = CollectibleManager.is_collectible_unlocked(collectible_id)
        if not collectible.buyable and not is_unlocked:
            continue  # Skip non-buyable collectibles that aren't unlocked yet

        var shop_item = CollectibleShopItemScene.instantiate()
        collectibles_grid.add_child(shop_item)

        # Setup shop item
        shop_item.setup(collectible, collectible_id)

        # Connect signals
        shop_item.unlock_requested.connect(_on_collectible_unlock_requested)
        shop_item.item_clicked.connect(_on_collectible_item_clicked)

        collectible_items.append(shop_item)


func _on_collectible_unlock_requested(collectible_id: String) -> void:
    """Handle unlock button pressed for collectible"""
    var success = CollectibleManager.unlock_collectible(collectible_id)

    if success:
        AudioManager.play_sfx("ui_click")
        _refresh_all_collectible_items()
    else:
        # Not enough orbs
        AudioManager.play_sfx("collision")
        print("Not enough orbs to unlock collectible %s" % collectible_id)


func _on_collectible_item_clicked(collectible_id: String, description: String) -> void:
    """Handle collectible item clicked - show description in panel"""
    var collectible_name = ""
    if CollectibleManager.collectibles.has(collectible_id):
        collectible_name = CollectibleManager.collectibles[collectible_id].collectible_name

    description_label.text = "%s" % [description]  # "%s\n\n%s" % [collectible_name, description]


func _on_collectible_unlocked(_collectible_id: String) -> void:
    """Handle collectible unlocked signal from manager"""
    _refresh_all_collectible_items()


func _refresh_all_collectible_items() -> void:
    """Refresh all collectible shop item button states"""
    for item in collectible_items:
        item.refresh()
