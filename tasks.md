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

## Daily Challenge Mode

- [ ] Fix points to be calculated based on collectibles only
- [ ] Award bonus points for time

## Collectibles

- [ ] Star - grants invincibility for X seconds
- [ ] Magnet - attracts nearby orbs for X seconds
- [ ] Stopwatch - slows game speed back down (if it increases speed due to distance)

## Obstacles

- [ ] Wall - horizontal collision that ends the run
- [ ] Pulse wall - horizontal collision that ends the run, pulses on and off
- [ ] Laser wall - horizontal collision extending from one wall to the other, shoots every X seconds
- [ ] Gravity well - pulls player toward center as they pass, ends the run if in center
- [ ] Crusher walls - two walls slam together, ends run if crushes player (only for daily challenge)
- [ ] Shockwave - sends out a small shockwave every X seconds, ends run if touches player
- [ ] Smoke screen - obscures vision of an area
- [ ] Fork - vertical wall that forces the player to choose a side
- [ ] Jagged edges - sharp triangles extending from the wall, ends run if player touches

## Tunnel Segments

- [ ] Make all tunnel segments the same width (obstacles will be the difficulty)
- [ ] Fix player can move outside starting segment if they move fast enough

## Stats

- [ ] Track number of dailies completed
- [ ] Show top speed for today's daily

## Polish

- [ ] New animation for title
- [ ] Add explosion particles when player dies
- [ ] Add particles when player picks up collectible
- [ ] New animations for HUD elements (score, distance, speed, etc.)

## Ads

- [ ] Add small button to main menu to watch a rewarded ad
- [ ] Add continue button to game over screen that will play an ad and then continue the run
- [ ] Force an ad to play every other run

## IAPs

- [ ] Purchase ad removal
