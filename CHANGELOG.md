# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]
### Added
- MAIN MENU ADDED. Cooler UI, feels like an actual game now.
- Minimap generation from the OGMO level data. Shows when a key gets pressed (M key/SELECT/Y on gamepad or something like that)
- Minimap also shows areas they've been, and the cheese and checkpoints they've collected.
- Able to warp to any checkpoint you've already reached.
- A PAUSE SCREEN, which shows all game controls for both keyboard and gamepad. Also allows you to mute and restart the game.
- Holding down pans the camera down temporarily to see below
- Moving platforms can stop at a node, instead of constantly moving. Can also pause at the start of a loop.
- Moving platforms can have a 'trigger' thing, which will keep the platform still until the specified trigger is fired.


### Changed
- PLAYER MOVEMENT
- Min jump height: 2.5 tiles -> 1.5 tiles
- Max jump height: 4.5 tiles -> 3.5 tiles
- (Air hop height unchanged, jump duration and distance compensated for above values)
- (Ground) Stop to full speed:    0.16  s -> 0.25 s;
- (Ground) Stop from full speed:  0.135 s -> 0.3  s;
- (Air)    Stop to full speed:    0.16  s -> 0.36 s;
- (Air)    Stop from full speed:  0.135 s -> 0.2  s;
- Post air hop acceleration unchanged
- Camera zooms in on rats while they talk. Ionno I thought it looked cool.
- Spikes no longer use a box for a hitshape, the collision matches the triangle graphic.
- Changed the camera logic a bit. Made camera move less during jumps.
- Deadzone covers total jump height upwards and 3 tiles downwards without moving
- Landing at a new hieght (within the deadzone) gradually snaps the camera to the new height
- Sections of levels can specify camera modes, which currently only affect whether to show more above or below the player
- Falling more than 3 tiles will make the camera pan down
- Intro sequence, now it plays a jingle, Ritz jumps into the title ina  different way.
- Title screen doesn't immediately put you into the game


## [1.0.0] - 2020-01-25
### Added
- Uh everything. This was the release for Pixel Day 2020 on Newgrounds.