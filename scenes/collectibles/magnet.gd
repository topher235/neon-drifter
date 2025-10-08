extends BaseCollectible

@export var magnet_duration: float = 5.0
@export var magnet_color: Color = Color(0.2, 0.5, 1.0, 1.0)  # Blue

@onready var magnet_visual: Polygon2D = %MagnetVisual

func _ready() -> void:
    super._ready()

func _animate(delta: float) -> void:
    super._animate(delta)

    # Add gentle rotation animation
    if magnet_visual:
        magnet_visual.rotation = sin(bob_offset * 0.5) * 0.4


func _on_collected() -> void:
    # Activate magnet effect on player
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_method("activate_magnet"):
        player.activate_magnet(magnet_duration)

    AudioManager.play_sfx("orb_collect", -0.3)  # Lower pitch for magnet
    _spawn_particles()
