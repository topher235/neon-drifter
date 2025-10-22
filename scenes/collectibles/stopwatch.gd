extends BaseCollectible

@export var slow_duration: float = 5.0
@export var slow_factor: float = 0.5  # Multiply speed by 0.5 (50% slower)
@export var stopwatch_color: Color = Color(1.0, 1.0, 1.0, 1.0)  # White

@onready var stopwatch_visual: Polygon2D = %StopwatchVisual


func _ready() -> void:
    super._ready()


func _animate(delta: float) -> void:
    super._animate(delta)

    # Add gentle rotation animation (like a ticking watch)
    if stopwatch_visual:
        stopwatch_visual.rotation = sin(bob_offset * 2.0) * 0.15


func _on_collected() -> void:
    # Activate slow effect on player/game
    if GameManager.has_method("activate_slowdown"):
        GameManager.activate_slowdown(slow_duration, slow_factor)

    # Enable CRT effect
    Events.crt_enabled.emit()

    AudioManager.play_sfx("item_collect", -0.5)  # Even lower pitch for stopwatch
    _spawn_particles()
