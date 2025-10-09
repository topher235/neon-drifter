extends Resource
class_name TrailCosmetic

## Defines a cosmetic appearance for the player's trail
## Supports solid colors, gradients, and animated effects

enum CosmenticType {
	SOLID,      ## Single solid color
	GRADIENT,   ## Static gradient
	ANIMATED    ## Animated gradient (color shifts over time)
}

@export var cosmetic_id: String = ""
@export var cosmetic_name: String = "Unnamed Trail"
@export var cosmetic_type: CosmenticType = CosmenticType.SOLID

## For SOLID type: single color
@export var solid_color: Color = Color.CYAN

## For GRADIENT type: gradient resource
@export var gradient: Gradient = null

## For ANIMATED type: animation speed (cycles per second)
@export var animation_speed: float = 1.0

## Whether this cosmetic is unlocked by default
@export var unlocked_by_default: bool = false

## Whether this cosmetic can be purchased with orbs
## If false, cosmetic must be awarded through achievements, reviews, etc.
@export var buyable: bool = true

## Price in orbs (0 = free/default)
@export var orb_cost: int = 0


func get_color_at_position(trail_index: int, trail_length: int, time: float = 0.0) -> Color:
	"""
	Returns the color for a specific point on the trail
	trail_index: 0 = newest point, trail_length-1 = oldest point
	time: current game time for animations
	"""
	match cosmetic_type:
		CosmenticType.SOLID:
			return solid_color

		CosmenticType.GRADIENT:
			if gradient == null:
				return solid_color
			var t = float(trail_index) / max(1.0, float(trail_length - 1))
			return gradient.sample(t)

		CosmenticType.ANIMATED:
			if gradient == null:
				return solid_color
			# Animate the gradient sampling position based on time
			var t = float(trail_index) / max(1.0, float(trail_length - 1))
			var animated_offset = fmod(time * animation_speed, 1.0)
			var sample_pos = fmod(t + animated_offset, 1.0)
			return gradient.sample(sample_pos)

	return solid_color
