### Reward System

Automatically grants orb rewards and can unlock special cosmetics.

### Persistence

All achievement progress saved to JSON via SaveManager.

## How It Works

1. Stats Change → StatsManager emits signal
2. AchievementManager receives signal → checks all locked achievements
3. Criteria Met → Achievement unlocked
4. Rewards Granted → Orbs added, cosmetics unlocked
5. State Saved → Progress written to save file

## Example Usage

### Get all achievements

var all_achievements = AchievementManager.get_all_achievements()

### Check progress on specific achievement

var progress = AchievementManager.get_achievement_progress("speed_demon")

### Get completion percentage

var percent = AchievementManager.get_completion_percentage()

### Debug: Force unlock

AchievementManager.unlock_achievement_debug("speed_bump")

### Debug: Print all achievements and status

AchievementManager.print_achievements()
