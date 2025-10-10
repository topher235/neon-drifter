class_name ShopModal
extends Control

## Shop modal for purchasing and managing cosmetics
## Can be used in main menu

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var orb_count_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Cosmetics/CosmeticsVBox/OrbCountLabel
@onready var cosmetics_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/TabContainer/Cosmetics/CosmeticsVBox/ScrollContainer/CosmeticsGrid
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
const CosmeticPreviewScene                     = preload("res://scenes/ui/cosmetic_preview.tscn")
var cosmetic_previews: Array[CosmeticPreview]  = []


func _ready() -> void:
	# Hide modal initially
	visible = false

	# Connect signals
	close_button.pressed.connect(_on_close_button_pressed)
	CosmeticManager.cosmetic_changed.connect(_on_cosmetic_changed)
	CosmeticManager.cosmetic_unlocked.connect(_on_cosmetic_unlocked)

	# Initialize cosmetics grid
	_populate_cosmetics_grid()

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
	"""Update the orb count label"""
	var total_orbs = SaveManager.get_current_orbs()
	orb_count_label.text = "Orbs: %d" % total_orbs
