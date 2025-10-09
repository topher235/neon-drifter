# Tasks

## Pause Menu

- [X] Create a Paused scene that gets displayed when the game is paused
- [X] Fix player movement so that it does not follow when player clicks Pause button
- [ ] Fix scene unpausing instead of immediately going to main menu

## Main Menu

- [X] Add checkmark to Daily Challenge button that is visible when the daily is completed

## Settings

- [X] Create settings scene
- [X] Toggle music and sfx
- [X] Save user choices between games
- [X] Allow changing settings from pause menu
- [ ] Disable buy button if not enough orbs

## Audio

- [ ] Add background music
- [ ] Add sfx to button presses
- [ ] Add sfx to collisions and collectible pickups

## Game Over

- [X] Redesign UI layout
- [X] Fix retry button to fully reload the level, using the same seed
- [ ] Use different wording for RUSH and daily mode (game over sounds like a lose state, not a win state)
- [ ] Save stats (distance, score, etc.)
- [ ] Save orb count

## Daily Challenge Mode

- [X] Modify procedural algorithm to use seed and contain X segments
- [X] Create end segment that triggers the completion of the run
- [X] Fix points to be calculated based on collectibles only
- [X] Award bonus points for time
- [X] Add timer to force player to complete in X seconds

## Collectibles

Don't forget to add these to the sandbox as well.

- [ ] Brainstorm new collectibles
- [ ] Add to shop to unlock using orbs in a new tab

- [X] Star - grants invincibility for X seconds
- [X] Magnet - attracts nearby orbs for X seconds
- [X] Stopwatch - slows game speed back down (if it increases speed due to distance)
    - [ ] Remove from daily challenge since it has no effect there
- [ ] Hourglass - adds time to daily challenge
- [ ] Multiplier - orbs count as double for X seconds (diamond shape)
- [ ] Size - double the player size for X seconds
- [ ] Bomb - destroys obstacles in this segment (and the next?)
    - [ ] Add screen shake when collected
    - [ ] Emit particles from destroyed obstacles when collected

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

## Tunnel Segments

- [X] Make all tunnel segments the same width (obstacles will be the difficulty)
- [X] Fix player can move outside starting segment if they move fast enough
- [X] Procedural generation

## Stats

- [ ] Track number of dailies completed
- [ ] Distance traveled
- [ ] Orbs collected

## Polish

- [X] New animation for title
- [X] Add explosion particles when player dies
- [X] Add particles when player picks up collectible
- [ ] New animations for HUD elements (score, distance, speed, etc.)

## Rush Mode

Players can share seeds and times.

- [X] Add mode that functions like the daily but you can use any seed
- [X] Display seed on game over
- [ ] Refine styling of the modal
- [X] Update player movement to match daily mode
- [X] Set a max number of segments, similar to daily mode

## Meta Progression

### Trail Cosmetics

Can probably be managed through the settings menu with tabs.

- [X] Add flag for purchasable (to separate achievement or rewarded cosmetics)
    - [X] Don't list non-purchasable in settings until they are unlocked
- [ ] Add global modal that will accept global event (cosmetic_id, message) to display "congrats message" and execute
  unlock

- Default Trail (cyan, free)
- Rainbow Trail (collect 500 orbs total)
- Fire Trail (reach 50,000 score in one run)
- Ghost Trail (complete 10 daily challenges)
- Lightning Trail (achieve 10x combo)
- Starfield Trail (travel 10,000m total)
- Midnight Trail (play 5 runs after 10pm)
- Golden Trail (beat your high score 5 times)

### Achievements

- [ ] Decide between GooglePlay/AppStore or just internal achievements

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
- [ ] Purchase orbs for unlocking cosmetics

## Review Prompt

- [ ] Every X games/sessions, prompt the user to review the app
    - [ ] Maybe offer a cosmetic for completing

## Ghost system

- [ ] Create playback system
- [ ] Overlay ghost trail in seed-based modes
- [ ] Toggle on/off in settings