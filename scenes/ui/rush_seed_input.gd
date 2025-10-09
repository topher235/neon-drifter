class_name RushSeedInput
extends Control

## UI for inputting a seed value for RUSH mode
## Allows player to enter a custom seed to replay specific tunnel layouts

signal seed_confirmed(seed_value: int)
signal cancelled

@export var seed_input: LineEdit
@export var confirm_button: Button
@export var cancel_button: Button
@export var random_button: Button
@export var seed_label: Label

func _ready() -> void:
    # Connect button signals
    if confirm_button:
        confirm_button.pressed.connect(_on_confirm_pressed)
    if cancel_button:
        cancel_button.pressed.connect(_on_cancel_pressed)
    if random_button:
        random_button.pressed.connect(_on_random_pressed)

    # Set up input validation
    if seed_input:
        seed_input.text_changed.connect(_on_seed_text_changed)
        seed_input.text = str(randi())  # Start with random seed

    visible = false

func open_seed_input() -> void:
    """Show the seed input dialog"""
    visible = true
    if seed_input:
        seed_input.grab_focus()
        seed_input.select_all()

func close_seed_input() -> void:
    """Hide the seed input dialog"""
    visible = false

func _on_confirm_pressed() -> void:
    if not seed_input:
        return

    var seed_text = seed_input.text.strip_edges()

    # Validate input
    if seed_text.is_empty():
        seed_text = "0"

    # Convert to int (GDScript handles invalid strings by returning 0)
    var seed_value = seed_text.to_int()

    # If text was not a valid number, use hash of the string
    if seed_value == 0 and seed_text != "0":
        seed_value = seed_text.hash()

    AudioManager.play_sfx("ui_click")
    seed_confirmed.emit(seed_value)
    close_seed_input()

func _on_cancel_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    cancelled.emit()
    close_seed_input()

func _on_random_pressed() -> void:
    """Generate a new random seed"""
    AudioManager.play_sfx("ui_click")
    if seed_input:
        seed_input.text = str(randi())

func _on_seed_text_changed(new_text: String) -> void:
    """Update the seed preview label"""
    if not seed_label:
        return

    var seed_value = new_text.to_int()
    if seed_value == 0 and new_text != "0" and not new_text.is_empty():
        # Invalid number, show hash
        seed_label.text = "Seed: %d (hash)" % new_text.hash()
    elif new_text.is_empty():
        seed_label.text = "Seed: (empty)"
    else:
        seed_label.text = "Seed: %d" % seed_value
