extends Node2D

@onready var tunnel_generator: TunnelGenerator = $TunnelGenerator
@onready var player: PlayerLine = $Player
@onready var hud: CanvasLayer = $UI/Hud
@onready var game_over_screen: Control = $UI/GameOverLayer/GameOver

func _ready() -> void:
    player.add_to_group("player")

    # Set player movement mode based on game mode
    if GameManager.current_game_mode == GameManager.GameMode.DAILY_CHALLENGE:
        player.movement_mode = "FreeMovement"
    else:
        player.movement_mode = "AutoRun"

    # Initialize systems
    tunnel_generator.initialize()

    # Start game
    call_deferred("_start_game")

func _start_game() -> void:
    GameManager.start_game()
    AudioManager.play_music("gameplay", false)

func _process(_delta: float) -> void:
    if GameManager.is_playing():
        # Update tunnel generation based on player position
        tunnel_generator.update_generation(player.get_world_position().y)
