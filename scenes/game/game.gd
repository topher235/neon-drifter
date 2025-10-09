extends Node2D

@onready var tunnel_generator: TunnelGenerator = $TunnelGenerator
@onready var player: PlayerLine = $Player
@onready var hud: CanvasLayer = $UI/Hud
@onready var pause_screen: PauseScreen = $UI/PauseLayer/PauseScreen
@onready var game_over_screen: Control = $UI/GameOverLayer/GameOver
@onready var crt_overlay: ColorRect = $UI/CanvasLayer/CRTOverlay

var crt_shader: ShaderMaterial

func _ready() -> void:
    player.add_to_group("player")

    # Set player movement mode based on game mode
    if GameManager.current_game_mode == GameManager.GameMode.DAILY_CHALLENGE:
        player.movement_mode = "FreeMovement"
    else:
        player.movement_mode = "AutoRun"

    # Connect to GameManager signals
    GameManager.game_paused.connect(_on_game_paused)
    GameManager.game_resumed.connect(_on_game_resumed)
    
    # Connect to global signals
    Events.crt_enabled.connect(enable_crt_effect)
    Events.crt_disabled.connect(disable_crt_effect)

    # Initialize systems with appropriate seed based on game mode
    var seed_value = GameManager.get_current_seed()
    var is_daily = GameManager.current_game_mode == GameManager.GameMode.DAILY_CHALLENGE
    tunnel_generator.initialize(seed_value, is_daily)

    print("Game initialized with seed: %d, mode: %s" % [seed_value, _get_mode_name()])

    # Start game
    call_deferred("_start_game")

func _get_mode_name() -> String:
    match GameManager.current_game_mode:
        GameManager.GameMode.CLASSIC:
            return "CLASSIC"
        GameManager.GameMode.DAILY_CHALLENGE:
            return "DAILY_CHALLENGE"
        GameManager.GameMode.RUSH:
            return "RUSH"
        _:
            return "UNKNOWN"

func _start_game() -> void:
    GameManager.start_game()
    AudioManager.play_music("gameplay", false)

func _unhandled_input(event: InputEvent) -> void:
    # Handle pause input
    if event.is_action_pressed("pause") and GameManager.is_playing():
        GameManager.pause_game()
        get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    if GameManager.is_playing():
        # Update tunnel generation based on player position
        tunnel_generator.update_generation(player.get_world_position().y)

func _on_game_paused() -> void:
    if pause_screen.has_method("show_pause_screen"):
        pause_screen.show_pause_screen()
    else:
        pause_screen.visible = true

func _on_game_resumed() -> void:
    if pause_screen.has_method("hide_pause_screen"):
        pause_screen.hide_pause_screen()
    else:
        pause_screen.visible = false


func enable_crt_effect() -> void:
    if crt_overlay:
        crt_overlay.visible = true

func disable_crt_effect() -> void:
    if crt_overlay:
        crt_overlay.visible = false
