class_name ReviewPromptModal
extends Control

## Review prompt modal that appears before the native platform review flow
## Provides context and options to the user

# Signals
signal review_requested  # User clicked "Rate Now"
signal review_dismissed  # User clicked "Maybe Later"
signal review_dismissed_permanently  # User clicked "Don't Ask Again"

# UI nodes (will be created in scene)
@onready var panel: Panel = $Panel
@onready var rate_now_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/RateNowButton
@onready var maybe_later_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/MaybeLaterButton
@onready var dont_ask_button: Button = $Panel/MarginContainer/VBoxContainer/DontAskButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# Hide modal initially
	visible = false

	# Connect button signals
	if rate_now_button:
		rate_now_button.pressed.connect(_on_rate_now_pressed)
	if maybe_later_button:
		maybe_later_button.pressed.connect(_on_maybe_later_pressed)
	if dont_ask_button:
		dont_ask_button.pressed.connect(_on_dont_ask_pressed)


func show_prompt() -> void:
	"""Display the review prompt modal with animation"""
	AudioManager.play_sfx("ui_modal_open")
	visible = true

	# Reset animation to beginning first
	if animation_player:
		animation_player.stop()
		animation_player.play("RESET")
		await get_tree().process_frame

		# Play open animation
		animation_player.play("open")


func hide_prompt() -> void:
	"""Hide the review prompt modal with animation"""
	AudioManager.play_sfx("ui_modal_close")

	if animation_player and animation_player.has_animation("open"):
		animation_player.play_backwards("open")
		await animation_player.animation_finished

	visible = false


func _on_rate_now_pressed() -> void:
	"""User wants to leave a review"""
	AudioManager.play_sfx("ui_click")
	await hide_prompt()
	review_requested.emit()

	# Tell ReviewManager to trigger the native review flow
	ReviewManager.request_review_prompt()


func _on_maybe_later_pressed() -> void:
	"""User dismissed for now, will ask again later"""
	AudioManager.play_sfx("ui_click")
	await hide_prompt()
	review_dismissed.emit()

	# Tell ReviewManager to reset counter
	ReviewManager.dismiss_review_temporarily()


func _on_dont_ask_pressed() -> void:
	"""User never wants to see this again"""
	AudioManager.play_sfx("ui_click")
	await hide_prompt()
	review_dismissed_permanently.emit()

	# Tell ReviewManager to permanently disable
	ReviewManager.dismiss_review_permanently()
