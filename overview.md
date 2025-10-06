# NeonDrift - Project Overview

## Project Description
NeonDrift is a mobile, top-down infinite runner game built with Godot 4.4. The player controls a circle using touch input, navigating through a procedurally generated tunnel while avoiding obstacles and collecting items. The game features a minimalist neon-highlighted aesthetic.

## Technical Stack
- **Engine**: Godot 4.4
- **Language**: GDScript
- **Platform**: Mobile (portrait orientation, 720x1280)
- **Rendering**: OpenGL compatibility mode with MSAA 2D

## Project Structure

### Core Directories
```
NeonDrift/
├── autoload/           # Global singletons (autoloaded scripts)
├── scenes/            # Scene files (.tscn) organized by type
│   ├── collectibles/  # Orbs and pickups
│   ├── debug/         # Debug overlay
│   ├── game/          # Main game scene
│   ├── main/          # World environment
│   ├── obstacles/     # Pillars, gates, etc.
│   ├── player/        # Player character (PlayerLine)
│   ├── segments/      # Tunnel segments
│   └── ui/            # HUD, menus, game over screen
├── scripts/           # Utility scripts
│   ├── generation/    # Procedural generation logic
│   └── utilities/     # Helper classes
├── resources/         # Game resources
│   ├── materials/     # Shaders and materials
│   └── segments/      # Segment data definitions
└── assets/            # Art and audio assets
    └── shaders/       # GLSL shaders
```

## Core Architecture

### Autoload Singletons (Global Managers)

#### GameManager (`autoload/game_manager.gd`)
Central game state controller that manages:
- **Game States**: MENU, PLAYING, PAUSED, GAME_OVER
- **Score System**: Tracks score, combo multipliers (1x-10x), orbs collected
- **Distance & Speed**:
  - Base speed: 300 px/s
  - Max speed: 800 px/s
  - Speed increases at 2 px/s² over time
  - Speed boost multiplier: 1.5x
- **Difficulty**: Scales 0-10 based on time and speed
- **High Scores**: Integrates with SaveManager for persistence
- **Daily Seed**: Generates daily challenge seed from system date

**Key Signals**:
- `game_started`, `game_over(score, distance)`, `score_changed`, `speed_changed`, `combo_changed`

#### SaveManager (`autoload/save_manager.gd`)
Handles persistent save data using JSON:
- High score & longest distance
- Games played & total orbs collected
- Unlocked/selected trail customization
- Audio volume settings (SFX: 0.8, Music: 0.6)
- First launch flag

**Save Location**: `res://neon_drift_save.json` (TODO: change to user://)

#### AudioManager (`autoload/audio_manager.gd`)
Audio system with pooling:
- **SFX Pool**: 16 AudioStreamPlayer instances for overlapping sounds
- **Music Player**: Single instance with fade in/out support
- **Audio Buses**: Master, Music, SFX (created dynamically if missing)
- **Library**: References for orb_collect, speed_boost, collision, combo, ui_click SFX
- **Music Tracks**: gameplay, menu (files not yet created)

### Player System

#### PlayerLine (`scenes/player/player_line.gd`)
The player character - a circle with trailing line visualization:

**Movement**:
- Touch input controls horizontal position (-125 to +125, matching tunnel half-width)
- Automatic forward movement at `GameManager.current_speed * 1.2`
- Smooth interpolation: `x_diff / movement_smoothing` (0.15 default)
- Returns to center when touch released

**Rendering**:
- Line2D trail with up to 50 points
- Trail points added every 5 pixels of movement
- Cyan color (0, 1, 1) with glow material
- 8px line width with rounded caps/joints

**Collision**:
- 12px radius CircleShape2D
- Detects obstacles (group: "obstacles") → triggers death
- Detects collectibles (group: "collectibles") → calls collect()
- Optional invulnerability system for powerups

**Camera**:
- Attached Camera2D with position smoothing (speed: 5.0)
- Screen shake on death (0.3s duration, 20.0 intensity)

### Procedural Generation System

#### TunnelGenerator (`scripts/generation/tunnel_generator.gd`)
Manages infinite tunnel generation:

**Configuration**:
- Keeps 4 segments ahead, 1 segment behind player
- Uses object pooling (pool size: 10)
- Seeded RNG (uses GameManager.daily_seed or custom seed)

**Generation Logic**:
1. Tracks player position to spawn/despawn segments
2. Queries SegmentLibrary for valid segments based on difficulty
3. Validates segments against generation rules
4. Applies procedural variation to obstacles/collectibles
5. Spawns segment at `last_segment_y` and updates tracking

**Generation Rules**:
- No more than 2 sharp turns consecutively
- Must have straight segment every 5-6 segments
- Early game (first 5 segments) limited to complexity ≤1
- Segments weighted by difficulty match and variety

**Procedural Variation**:
- Tunnel width: Fixed at 250px (no variation)
- Obstacle positions: ±20px horizontal, ±30px vertical
- Collectible positions: ±15px horizontal, ±20px vertical
- 30% chance to add extra obstacle at difficulty >5
- 20% chance to add extra collectible

**Difficulty Scaling**:
```gdscript
time_factor = game_time / 60.0  # 0-1 over first minute
speed_factor = (current_speed - base_speed) / (max_speed - base_speed)
difficulty = clamp((time_factor * 4) + (speed_factor * 6) + random(-0.5, 0.5), 0, 10)
```

#### SegmentLibrary (`scripts/generation/segment_library.gd`)
Contains 11 pre-designed segment templates:

**Basic Straight** (Difficulty 0-2):
- `straight_empty`: Just collectibles, 600px long
- `straight_single_pillar`: 1 pillar, 3 orbs, 700px
- `straight_double_pillar`: 2 pillars offset, 2 orbs, 800px
- `straight_gate`: 1 pulse_gate, 2 orbs, 700px

**Curves** (Difficulty 1-7):
- `gentle_left/right`: ±25° curvature, 1 pillar, 2 orbs, 800px
- `sharp_left/right`: ±60° curvature, 2 pillars, 600px

**Complex** (Difficulty 5-10):
- `s_curve`: 1000px S-shape, 2 pillars, 2 orbs + speed boost
- `slalom`: 3 alternating pillars forcing weaving, 900px
- `narrow_passage`: pulse_gate + pillar, 600px

**Indexing**:
- By type: straight, curve, s_curve
- By difficulty: Arrays for difficulty levels 0-10

#### SegmentData (`resources/segments/segment_data.gd`)
Resource class defining segment properties:
- **Identity**: segment_id, segment_type
- **Dimensions**: segment_length (default 800), tunnel_width (default 250)
- **Geometry**: curvature (-90 to 90), curve_type
- **Difficulty**: min_difficulty, max_difficulty (0-10), complexity
- **Content**: obstacles[] and collectibles[] (Dictionary arrays)
- **Features**: has_fork, has_gravity_shift flags (future)

#### BaseSegment (`scenes/segments/base_segment.gd`)
Scene instance that renders a segment:

**Containers**:
- `obstacles_container`: Holds pillar/gate instances
- `collectibles_container`: Holds orb instances
- `walls_container`: Line2D left/right tunnel boundaries
- `background`: Reserved for visual effects

**Initialization**:
1. Receives SegmentData and index
2. Clears previous content (for pooling)
3. Spawns obstacles from templates
4. Spawns collectibles from templates
5. Draws tunnel walls (3px blue lines)

**Obstacle Factory**:
- "pillar" → `res://scenes/obstacles/pillar.tscn` with radius
- "pulse_gate" → `res://scenes/obstacles/pulse_gate.tscn` with rotation_speed

**Collectible Factory**:
- "orb" → `res://scenes/collectibles/orb.tscn` with point_value
- "speed_boost" → (commented out, not yet implemented)

### Game Entities

#### Obstacles

**BaseObstacle** (`scenes/obstacles/base_obstacle.gd`):
- Extends Node2D
- Has Area2D + CollisionShape2D
- Groups itself as "obstacles"

**Pillar** (`scenes/obstacles/pillar.gd`):
- Circular obstacle (default 30px radius)
- ColorRect visual + PointLight2D glow
- Pink-red color (1, 0.2, 0.5)
- Subtle pulse animation on glow (energy 1.5 ± 0.3 via sine wave)

**PulseGate** (`scenes/obstacles/pulse_gate.gd`):
- Rotating obstacle with configurable rotation_speed
- (Implementation details not read - likely rotates to create timing challenge)

#### Collectibles

**BaseCollectible** (`scenes/collectibles/base_collectible.gd`):
- Extends Node2D
- Has Area2D + CollisionShape2D
- Groups itself as "collectibles"
- Implements collect() method that calls _on_collected() and queue_free()

**Orb** (`scenes/collectibles/orb.gd`):
- Circular collectible (15px radius)
- Cyan color (0, 1, 1)
- Default 10 points (can be 20 for bonus orbs)
- Calls `GameManager.collect_orb(point_value)` when collected
- Plays "orb_collect" SFX with 0.1 pitch variation

### UI System

**HUD** (`scenes/ui/hud.gd`):
- Shows current score
- Shows distance traveled
- Shows combo multiplier
- Shows current speed

**GameOverScreen** (`scenes/ui/game_over.gd`):
- Displays final score and distance
- Shows high score comparison
- Retry and menu buttons

**MainMenu** (`scenes/ui/main_menu.gd`):
- Start game button
- Settings access
- Daily challenge mode

### Main Game Scene

**Game** (`scenes/game/game.gd`):
- Root scene for gameplay
- Contains: TunnelGenerator, Player, HUD, GameOverScreen
- Initializes tunnel generator on ready
- Calls `GameManager.start_game()` deferred
- Updates tunnel generation each frame based on player Y position

## Gameplay Loop

1. **Initialization**:
   - Game scene loads
   - GameManager starts game (resets score, distance, speed)
   - TunnelGenerator generates initial 6 segments
   - Player spawns at (0, 0)

2. **Runtime**:
   - Player moves forward automatically at increasing speed
   - Player controls X position via touch input
   - TunnelGenerator spawns segments ahead, despawns behind
   - Difficulty increases based on time + speed
   - Collision with obstacles triggers death
   - Collecting orbs increases score and combo

3. **Scoring**:
   - Distance: 1 point per 100 pixels traveled
   - Orbs: 10 or 20 points × combo multiplier
   - Combo: Increases by 1 per orb (max 10x), resets on... (not shown in code)

4. **Game Over**:
   - Player collision detected
   - GameManager.end_game() called
   - High scores saved if beaten
   - Game Over screen shows final stats

## Key Game Parameters

### Speeds
- Base speed: 300 px/s
- Speed increase: 2 px/s per second
- Max speed: 800 px/s
- Player speed multiplier: 1.2x (moves faster than tunnel scroll)

### Dimensions
- Viewport: 720×1280 (portrait)
- Tunnel width: 250px (125px left/right of center, fixed across all segments)
- Player collision radius: 12px
- Pillar radius: 25-35px (varied)
- Orb radius: 15px

### Segments
- Default length: 800px (varies 600-1000px)
- Segments ahead: 4
- Segments behind: 1
- Pool size: 10

### Difficulty
- Scale: 0-10
- Based on: 40% time factor, 60% speed factor
- First 5 segments: easy (complexity ≤1)
- Affects segment selection and obstacle density

## Physics & Input

**Physics**:
- 2D with zero gravity
- No default physics simulation on player (kinematic movement)
- Area2D for collision detection (not physics bodies)

**Input**:
- Touch action: Left mouse button (mouse emulates touch)
- Pause: Escape key
- Restart: R key
- Touch deadzone: 0.2

## Rendering & Aesthetics

**Rendering**:
- OpenGL compatibility mode
- MSAA 2D antialiasing
- Canvas items stretch mode

**Color Palette** (Neon Theme):
- Player trail: Cyan (0, 1, 1)
- Orbs: Cyan (0, 1, 1)
- Pillars: Pink-red (1, 0.2, 0.5)
- Tunnel walls: Light blue (0.3, 0.6, 1.0, 0.5)

**Visual Effects**:
- Trail glow material (preloaded: `res://resources/materials/trail_glow.tres`)
- PointLight2D glow on obstacles
- Particle trail on player (GPUParticles2D, 50 particles, 0.5s lifetime)
- Death particles (not yet implemented)
- Screen shake on collision

## Known TODOs & Missing Features

From code comments and incomplete implementations:

1. **SaveManager**: Change save path from "res://" to "user://"
2. **Speed Boost Collectible**: Commented out in BaseSegment
3. **Combo Reset Logic**: Not shown (when does combo reset besides death?)
4. **Audio Files**: SFX and music files don't exist yet (paths defined but skipped)
5. **Camera Shake**: Method called but not implemented (camera_controller.gd not read)
6. **Death Particles**: Stub in player_line.gd
7. **Background Grid**: Stub in base_segment.gd
8. **Segment Curvature**: Defined but not visually applied (tunnels appear straight)
9. **Fork Segments**: Flag exists but not implemented
10. **Gravity Shift**: Flag exists but not implemented
11. **Trail Customization**: Save system supports it but no implementation
12. **Daily Challenge**: Seed generated but no special mode

## Debug Features

**DebugOverlay** (`scenes/debug/debug_overlay.gd`):
- (Not read - likely shows FPS, difficulty, segment info)

**Debug Controls**:
- R key: Restart game
- Escape: Pause

## Class Reference

### Key Classes
- `PlayerLine`: Player character with trail rendering
- `TunnelGenerator`: Procedural generation controller
- `SegmentLibrary`: Segment template database
- `SegmentData`: Segment configuration resource
- `BaseSegment`: Instantiated segment scene
- `BaseObstacle`: Parent for pillar/gate
- `BaseCollectible`: Parent for orb/boost

### Autoloads (Access via name)
- `GameManager`: Game state, score, speed
- `AudioManager`: Sound effects and music
- `SaveManager`: Persistence layer

## Development Notes

**Current State**: MVP / Early Development
- Core gameplay loop functional
- Basic procedural generation working
- Placeholder visuals (ColorRect instead of sprites/shaders)
- Audio system in place but no audio files
- Save system functional
- Several features stubbed out for future

**Performance Optimizations**:
- Object pooling for segments (10 instances)
- SFX player pooling (16 instances)
- Trail point limiting (50 max)
- Segment despawning behind player

**Extensibility**:
- Easy to add new segment templates to SegmentLibrary
- Obstacle/collectible factory pattern for new types
- Difficulty-based content selection
- Resource-based segment definitions (could load from files)

## Git Status
Repository is not initialized as a git repository (as of inspection time).

## Getting Started (For LLMs)

When working with this codebase:

1. **Game Flow**: Start at `scenes/game/game.gd` → understand how GameManager and TunnelGenerator interact
2. **Generation**: Read `TunnelGenerator` → `SegmentLibrary` → `BaseSegment` to understand level creation
3. **Player**: `PlayerLine` is self-contained - movement, collision, rendering all in one class
4. **Adding Content**: New obstacles/collectibles need:
   - Scene file (.tscn)
   - GDScript extending Base class
   - Factory case in `BaseSegment._create_obstacle/collectible()`
   - Template entries in `SegmentLibrary`
5. **Global State**: Always check GameManager for game state, score, speed before acting
6. **Signals**: Many systems communicate via signals - check GameManager signals especially

## File References

**Main Scene**: `res://scenes/game/game.tscn` (referenced as UID in project.godot)

**Critical Scripts**:
- `/autoload/game_manager.gd` - Game state (165 lines)
- `/scenes/player/player_line.gd` - Player logic (250 lines)
- `/scripts/generation/tunnel_generator.gd` - Generation (360 lines)
- `/scripts/generation/segment_library.gd` - Templates (316 lines)

**Scene Files**: 13 .tscn files across scenes/ directory

**Icon**: `icon.png` (3461 bytes)
