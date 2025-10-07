# Tasks

## Pause Menu

- [X] Create a Paused scene that gets displayed when the game is paused
- [X] Fix player movement so that it does not follow when player clicks Pause button
- [ ] Fix scene unpausing instead of immediately going to main menu

## Main Menu

- [ ] Add checkmark to Daily Challenge button that is visible when the daily is completed

## Settings

- [ ] Create settings scene
- [ ] Toggle music and sfx
- [ ] Save user choices between games
- [ ] Allow changing settings from pause menu

## Audio

- [ ] Add background music
- [ ] Add sfx to button presses
- [ ] Add sfx to collisions and collectible pickups

## Game Over

- [ ] Redesign UI layout
- [ ] Fix retry button to fully reload the level, using the same seed
- [ ] Use different wording for RUSH and daily mode (game over sounds like a lose state, not a win state)

## Daily Challenge Mode

- [X] Modify procedural algorithm to use seed and contain X segments
- [X] Create end segment that triggers the completion of the run
- [X] Fix points to be calculated based on collectibles only
- [X] Award bonus points for time
- [X] Add timer to force player to complete in X seconds

## Collectibles

Don't forget to add these to the sandbox as well.

- [X] Star - grants invincibility for X seconds
- [X] Magnet - attracts nearby orbs for X seconds
- [X] Stopwatch - slows game speed back down (if it increases speed due to distance)
- [ ] Hourglass - adds time to daily challenge

## Obstacles

Don't forget to add these to the sandbox as well.

- [X] Wall - horizontal collision that ends the run
- [X] Pulse wall - horizontal collision that ends the run, pulses on and off
- [ ] Laser - horizontal collision extending from one wall to the other, shoots every X seconds
- [ ] Gravity well - pulls player toward center as they pass, ends the run if in center
- [ ] Crusher walls - two walls slam together, ends run if crushes player (only for daily challenge)
- [X] Shockwave - sends out a small shockwave every X seconds, ends run if touches player
- [X] Smoke screen - obscures vision of an area
- [X] Fork - vertical wall that forces the player to choose a side
- [X] Jagged edges - sharp triangles extending from the wall, ends run if player touches

- [ ] Refactor to create a KillsPlayer component that sets up the collision
- [ ] Refactor to try to use on_area_entered signal instead of checking collisions in _process

## Tunnel Segments

- [X] Make all tunnel segments the same width (obstacles will be the difficulty)
- [ ] Fix player can move outside starting segment if they move fast enough
- [ ] Procedural generation

## Stats

- [ ] Track number of dailies completed
- [ ] Show top speed for today's daily

## Polish

- [ ] New animation for title
- [ ] Add explosion particles when player dies
- [ ] Add particles when player picks up collectible
- [ ] New animations for HUD elements (score, distance, speed, etc.)

## Rush Mode

Players can share seeds and times.

- [ ] Add mode that functions like the daily but you can use any seed
- [ ] Display seed on HUD

## Meta Progression

### Trail Cosmetics

- Default Trail (cyan, free)
- Rainbow Trail (collect 500 orbs total)
- Fire Trail (reach 50,000 score in one run)
- Ghost Trail (complete 10 daily challenges)
- Lightning Trail (achieve 10x combo)
- Starfield Trail (travel 10,000m total)
- Midnight Trail (play 5 runs after 10pm)
- Golden Trail (beat your high score 5 times)

### Achievements

Distance Milestones:
- 🏃 Sprinter: 1,000m total → Unlock "Speed Trail"
- 🚀 Marathon: 10,000m total → Unlock "Endurance Trail"
- 🌟 Ultra Runner: 50,000m total → Unlock "Champion Trail"

Score Milestones:
- 🥉 Bronze Scorer: 10,000 career points
- 🥈 Silver Scorer: 100,000 career points
- 🥇 Gold Scorer: 500,000 career points

Skill Milestones:
- 🎯 Perfectionist: Collect 100% collectibles in daily run
- 💨 Speed Demon: Complete daily in under 60s
- 🔥 Combo Master: Achieve 20x combo
- 👻 Near Miss: Pass within 5px of 100 obstacles
- ⚡ No Boost: Complete daily without speed boosts

## Ads

- [ ] Add small button to main menu to watch a rewarded ad
- [ ] Add continue button to game over screen that will play an ad and then continue the run
- [ ] Force an ad to play every other run

## IAPs

- [ ] Purchase ad removal

## Ghost system

- [ ] Create playback system
- [ ] Overlay ghost trail in seed-based modes
- [ ] Toggle on/off in settings