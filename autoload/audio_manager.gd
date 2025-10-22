extends Node

# Audio buses
var master_bus_idx: int
var music_bus_idx: int
var sfx_bus_idx: int
# Music player
var music_player: AudioStreamPlayer
# SFX pool
const MAX_SFX_PLAYERS                     = 16
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_index: int                 = 0

# Audio files (to be loaded)
var sfx_library: Dictionary = {
                                  "orb_collect": "res://assets/audio/sfx/orb_collect.wav",
                                  "item_collect": "res://assets/audio/sfx/item_collect.wav",
                                  "speed_boost": "res://assets/audio/sfx/speed_boost.wav",
                                  "collision": "res://assets/audio/sfx/collision.wav",
                                  "combo": "res://assets/audio/sfx/combo.wav",
                                  "unlock": "res://assets/audio/sfx/unlock.wav",
                                  "ui_click": "res://assets/audio/sfx/ui_click.wav",
                                  "ui_modal_open": "res://assets/audio/sfx/ui_modal_open.wav",
                                  "ui_modal_close": "res://assets/audio/sfx/ui_modal_close.wav",
                                  "ui_pause_open": "res://assets/audio/sfx/ui_pause_open.wav",
                                  "ui_start_game": "res://assets/audio/sfx/ui_start_game.wav",
                                  "ui_error": "res://assets/audio/sfx/ui_error.wav",
                                  "ui_back": "res://assets/audio/sfx/ui_back.wav",
                              }

var music_tracks: Dictionary = {
                                   "gameplay": "res://assets/audio/music/gameplay_loop.wav",
                                   "menu": "res://assets/audio/music/atmosphere-loop.wav"
                               }

var fade_tween: Tween


func _ready() -> void:
    _setup_audio_buses()
    _create_music_player()
    _create_sfx_pool()
    _load_audio_settings()


func _setup_audio_buses() -> void:
    master_bus_idx = AudioServer.get_bus_index("Master")
    music_bus_idx = AudioServer.get_bus_index("Music")
    sfx_bus_idx = AudioServer.get_bus_index("SFX")

    # Create buses if they don't exist
    if music_bus_idx == -1:
        AudioServer.add_bus(1)
        AudioServer.set_bus_name(1, "Music")
        AudioServer.set_bus_send(1, "Master")
        music_bus_idx = 1

    if sfx_bus_idx == -1:
        AudioServer.add_bus(2)
        AudioServer.set_bus_name(2, "SFX")
        AudioServer.set_bus_send(2, "Master")
        sfx_bus_idx = 2


func _create_music_player() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.bus = "Music"
    add_child(music_player)


func _create_sfx_pool() -> void:
    for i in MAX_SFX_PLAYERS:
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        sfx_players.append(player)


func _load_audio_settings() -> void:
    set_music_volume(SaveManager.get_music_volume())
    set_sfx_volume(SaveManager.get_sfx_volume())


# Music Control
func play_music(track_name: String, fade_in: bool = true) -> void:
    if not track_name in music_tracks:
        push_warning("Music track not found: " + track_name)
        return

    # For MVP, skip actual file loading if files don't exist yet
    if not ResourceLoader.exists(music_tracks[track_name]):
        print("Music file not yet created: " + track_name)
        return

    # Kill any existing tweens on the music player first
    if fade_tween:
        fade_tween.kill()

    # Stop any currently playing music
    music_player.stop()

    var stream = load(music_tracks[track_name])
    music_player.stream = stream

    if fade_in:
        music_player.volume_db = -80
        music_player.play()
        fade_tween = create_tween()
        fade_tween.tween_property(music_player, "volume_db", 0, 1.0)
    else:
        music_player.volume_db = 0
        music_player.play()


func stop_music(fade_out: bool = true) -> void:
    if fade_out:
        if fade_tween:
            fade_tween.kill()

        fade_tween = create_tween()
        fade_tween.tween_property(music_player, "volume_db", -80, 1.0)
        fade_tween.tween_callback(music_player.stop)
    else:
        music_player.stop()


# SFX Control
func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
    if not sfx_name in sfx_library:
        push_warning("SFX not found: " + sfx_name)
        return

    # For MVP, skip if files don't exist
    if not ResourceLoader.exists(sfx_library[sfx_name]):
        print("SFX file not yet created: " + sfx_name)
        return

    var player = sfx_players[sfx_player_index]
    sfx_player_index = (sfx_player_index + 1) % MAX_SFX_PLAYERS

    player.stream = load(sfx_library[sfx_name])
    if pitch_variation > 0.0:
        player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
    else:
        player.pitch_scale = 1.0

    player.play()


# Volume Control
func set_music_volume(volume: float) -> void:
    var db = linear_to_db(volume)
    AudioServer.set_bus_volume_db(music_bus_idx, db)
    AudioServer.set_bus_mute(music_bus_idx, volume < 0.01)


func set_sfx_volume(volume: float) -> void:
    var db = linear_to_db(volume)
    AudioServer.set_bus_volume_db(sfx_bus_idx, db)
    AudioServer.set_bus_mute(sfx_bus_idx, volume < 0.01)


func get_music_volume() -> float:
    return db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))


func get_sfx_volume() -> float:
    return db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))


# Mute/Unmute Control
func mute_music() -> void:
    AudioServer.set_bus_mute(music_bus_idx, true)


func unmute_music() -> void:
    AudioServer.set_bus_mute(music_bus_idx, false)


func mute_sfx() -> void:
    AudioServer.set_bus_mute(sfx_bus_idx, true)


func unmute_sfx() -> void:
    AudioServer.set_bus_mute(sfx_bus_idx, false)


func is_music_muted() -> bool:
    return AudioServer.is_bus_mute(music_bus_idx)


func is_sfx_muted() -> bool:
    return AudioServer.is_bus_mute(sfx_bus_idx)


# Utility
func linear_to_db(linear: float) -> float:
    if linear <= 0.0:
        return -80.0
    return 20.0 * log(linear) / log(10.0)


func db_to_linear(db: float) -> float:
    if db <= -80.0:
        return 0.0
    return pow(10.0, db / 20.0)