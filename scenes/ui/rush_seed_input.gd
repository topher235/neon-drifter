class_name RushSeedInput
extends Control

## UI for inputting a seed value for RUSH mode
## Allows player to enter a custom seed to replay specific tunnel layouts

signal seed_confirmed(seed_value: int)
signal cancelled
@onready var seed_input: LineEdit = %SeedInput
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton
@onready var random_button: Button = %RandomButton
@onready var seed_label: Label = %SeedLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer


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
        seed_input.max_length = 12  # Limit to 12 digits
        # Set up character filtering for numbers only
        var regex = RegEx.new()
        regex.compile("^[0-9]*$")  # Only allow digits
        seed_input.text = str(randi())  # Start with random seed

    visible = false


func open_seed_input() -> void:
    """Show the seed input dialog with animation"""
    visible = true
    AudioManager.play_sfx("ui_modal_open")
    if animation_player:
        animation_player.play("open")
    if seed_input:
        # Delay focus grab to after animation starts
        await get_tree().create_timer(0.1).timeout


func close_seed_input() -> void:
    """Hide the seed input dialog"""
    AudioManager.play_sfx("ui_modal_close")
    if animation_player:
        animation_player.play_backwards("open")
        await animation_player.animation_finished
    visible = false


func _on_confirm_pressed() -> void:
    if not seed_input:
        return

    var seed_text = seed_input.text.strip_edges()

    # Validate input - default to 0 if empty
    if seed_text.is_empty():
        seed_text = "0"

    # Convert to int (guaranteed to be numeric due to filtering)
    var seed_value = seed_text.to_int()

    AudioManager.play_sfx("ui_start_game")
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
    """Update the seed preview label and filter non-numeric input"""
    if not seed_input:
        return

    # Filter out non-numeric characters
    var filtered_text = ""
    for character in new_text:
        if character.is_valid_int():
            filtered_text += character

    # Update the input if filtering occurred
    if filtered_text != new_text:
        seed_input.text = filtered_text
        seed_input.caret_column = filtered_text.length()
        return

    # Update label
    if not seed_label:
        return

    if filtered_text.is_empty():
        seed_label.text = "Seed: (empty)"
    else:
        var seed_value = filtered_text.to_int()
        seed_label.text = "Seed: %d" % seed_value
