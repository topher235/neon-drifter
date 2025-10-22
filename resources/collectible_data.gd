class_name CollectibleData
extends Resource

## Represents a collectible type's metadata for the shop/unlock system
## Not to be confused with SegmentData collectible definitions

@export var collectible_id: String = ""
@export var collectible_name: String = ""
@export var description: String = ""  # What the collectible does
@export var icon_texture: Texture2D  # Preview icon for shop (for PNG-based collectibles)
@export var collectible_color: Color = Color.WHITE  # Visual color for preview
@export var scene_path: String = ""  # Path to collectible scene for preview rendering

# Unlock system
@export var unlocked_by_default: bool = true  # True for orbs
@export var buyable: bool = false  # Can be purchased with orbs
@export var orb_cost: int = 0  # Cost to unlock if buyable

# Collectible type reference (for spawning)
@export var collectible_type: String = ""  # e.g., "orb", "magnet", "star", etc.
