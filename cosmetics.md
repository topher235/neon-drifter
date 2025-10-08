# Cosmetics

## Using

Change cosmetics in GDScript:
### Select the rainbow trail
CosmeticManager.select_cosmetic("rainbow_gradient")

### Select the default cyan trail
CosmeticManager.select_cosmetic("cyan_default")

Check available cosmetics:
### Get all cosmetics
var all_cosmetics = CosmeticManager.get_all_cosmetics()

### Check if a cosmetic is unlocked
if CosmeticManager.is_cosmetic_unlocked("rainbow_gradient"):
print("Rainbow trail is unlocked!")

### Unlock a cosmetic (if you set unlocked_by_default to false)
CosmeticManager.unlock_cosmetic("rainbow_gradient")

Built-in Cosmetics

1. Cyan (cyan_default) - The original cyan trail, unlocked by default
2. Rainbow (rainbow_gradient) - Animated rainbow gradient trail, currently set to unlocked by default

## Adding New Cosmetics

Edit /autoload/cosmetic_manager.gd in the _initialize_cosmetics() function:

var new_cosmetic = TrailCosmetic.new()
new_cosmetic.cosmetic_id = "my_cosmetic"
new_cosmetic.cosmetic_name = "My Cool Trail"
new_cosmetic.cosmetic_type = TrailCosmetic.CosmenticType.SOLID  # or GRADIENT, ANIMATED
new_cosmetic.solid_color = Color(1, 0, 0)  # Red
new_cosmetic.unlocked_by_default = false
new_cosmetic.orb_cost = 500
cosmetics["my_cosmetic"] = new_cosmetic

## Notable Files

- resources/cosmetics/trail_cosmetic.gd - TrailCosmetic resource class
- autoload/cosmetic_manager.gd - Global cosmetic manager

The selection is automatically saved and will persist across game sessions!
