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

1. White (default) - The default white trail, unlocked by default, not buyable
2. Cyan (cyan) - Cyan trail, can be purchased for 50 orbs
3. Rainbow (rainbow_gradient) - Animated rainbow gradient trail, currently set to unlocked by default, can be purchased
   for 100 orbs

## Buyable vs. Award Cosmetics

The `buyable` flag determines how cosmetics appear in the shop:

- **Buyable cosmetics** (`buyable = true`): Always visible in the cosmetics shop, showing purchase button and orb cost
  when locked
- **Award cosmetics** (`buyable = false`): Only appear in the shop AFTER being unlocked through achievements, reviews,
  or special events

This allows you to create exclusive cosmetics that can't be purchased, making achievements and other rewards more
meaningful.

## Adding New Cosmetics

Edit /autoload/cosmetic_manager.gd in the _initialize_cosmetics() function:

### Buyable Cosmetic (Can be purchased with orbs)

var new_cosmetic = TrailCosmetic.new()
new_cosmetic.cosmetic_id = "my_cosmetic"
new_cosmetic.cosmetic_name = "My Cool Trail"
new_cosmetic.cosmetic_type = TrailCosmetic.CosmenticType.SOLID # or GRADIENT, ANIMATED
new_cosmetic.solid_color = Color(1, 0, 0)  # Red
new_cosmetic.unlocked_by_default = false
new_cosmetic.buyable = true # Can be purchased in the shop
new_cosmetic.orb_cost = 500
cosmetics["my_cosmetic"] = new_cosmetic

### Special/Award Cosmetic (Cannot be purchased, must be unlocked via achievements)

var award_cosmetic = TrailCosmetic.new()
award_cosmetic.cosmetic_id = "achievement_trail"
award_cosmetic.cosmetic_name = "Achievement Trail"
award_cosmetic.cosmetic_type = TrailCosmetic.CosmenticType.ANIMATED
award_cosmetic.unlocked_by_default = false
award_cosmetic.buyable = false # Cannot be purchased - only awarded
award_cosmetic.orb_cost = 0 # No cost since it can't be bought
cosmetics["achievement_trail"] = award_cosmetic

# Then unlock it when achievement is earned:

# CosmeticManager.unlock_cosmetic("achievement_trail")

## Notable Files

- resources/cosmetics/trail_cosmetic.gd - TrailCosmetic resource class
- autoload/cosmetic_manager.gd - Global cosmetic manager

The selection is automatically saved and will persist across game sessions!
