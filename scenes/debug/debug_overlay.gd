extends CanvasLayer

@onready var debug_label: Label = $DebugLabel

var show_debug: bool = false

func _ready() -> void:
    visible = false

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F3:
            show_debug = not show_debug
            visible = show_debug

func _process(_delta: float) -> void:
    if not show_debug:
        return

    var debug_text = ""
    debug_text += "FPS: %d\n" % Engine.get_frames_per_second()
    debug_text += "Difficulty: %.1f\n" % GameManager.get_difficulty()
    debug_text += "Speed: %.0f\n" % GameManager.current_speed
    debug_text += "Distance: %.0f\n" % GameManager.distance_traveled
    debug_text += "Segments: %d\n" % get_tree().get_nodes_in_group("segments").size()

    if is_instance_valid(get_tree().get_first_node_in_group("player")):
        var player = get_tree().get_first_node_in_group("player")
        debug_text += "Player Y: %.1f\n" % player.position.y

    debug_label.text = debug_text