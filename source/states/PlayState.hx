package states;

import OgmoPath;
import beat.BeatGame;
import data.Level;
import data.OgmoTilemap;
import data.PlayerSettings;
import props.Checkpoint;
import props.Cheese;
import props.Lock;
import props.SpikeObstacle;
import props.Player;
import props.Platform;
import props.BlinkingPlatform;
import props.MovingPlatform;
import props.SecretTrigger;
import props.MusicTrigger;
import ui.BitmapText;
import ui.Controls;
import ui.DialogueSubstate;
import ui.DeviceManager;
import ui.pause.PauseSubstate;

import io.newgrounds.NG;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

import flixel.addons.display.FlxBackdrop;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

class PlayState extends flixel.FlxState
{
	inline static var USE_NEW_CAMERA = true;
	inline static var FIRST_CHEESE_MSG = "Thanks for the cheese, buddy! ";
	
	var levels:Map<String, Level> = [];
	
	var bg:FlxBackdrop;
	var foreground = new FlxGroup();
	var background = new FlxGroup();
	var grpCracks = new FlxTypedGroup<OgmoTilemap>();
	var grpPlayers = new FlxTypedGroup<Player>();
	var grpCheese = new FlxTypedGroup<Cheese>();
	var grpTilemaps = new FlxTypedGroup<OgmoTilemap>();
	var grpPlatforms = new FlxTypedGroup<TriggerPlatform>();
	var grpOneWayPlatforms = new FlxTypedGroup<Platform>();
	var grpSpikes = new FlxTypedGroup<SpikeObstacle>();
	var grpCheckpoint = new FlxTypedGroup<Checkpoint>();
	var grpLockedDoors = new FlxTypedGroup<Lock>();
	var grpMusicTriggers = new FlxTypedGroup<MusicTrigger>();
	var grpSecretTriggers = new FlxTypedGroup<SecretTrigger>();
	var grpCameraTiles = new FlxTypedGroup<CameraTilemap>();
	var grpDecalLayers = new FlxTypedGroup<FlxGroup>();
	var musicName:String;

	var gaveCheese = false;
	var cheeseCountText:BitmapText;
	var dialogueBubble:FlxSprite;
	var cheeseCount = 0;
	var cheeseNeeded = 0;
	var totalCheese = 0;
	var curCheckpoint:Checkpoint;
	var cheeseNeededText:LockAmountText;
	
	override public function create():Void
	{
		playMusic("pillow");
		
		bg = new FlxBackdrop(AssetPaths.dumbbg__png);
		bg.scrollFactor.set(0.75, 0.75);
		bg.alpha = 0.75;
		#if debug bg.ignoreDrawDebug = true; #end
		
		add(bg);
		add(grpCracks);
		add(background);
		add(grpTilemaps);
		add(grpDecalLayers);
		add(foreground);
		add(grpPlayers);
		
		dialogueBubble = new FlxSprite().loadGraphic(AssetPaths.dialogue__png, true, 32, 32);
		dialogueBubble.animation.add('play', [0, 1, 2, 3], 6);
		dialogueBubble.animation.play('play');
		add(dialogueBubble);
		dialogueBubble.visible = false;
		
		FlxG.worldBounds.set(0, 0, 0, 0);
		FlxG.cameras.remove(FlxG.camera);
		FlxG.camera = null;
		FlxCamera.defaultCameras = [];// Added to in createPlayer
		createInitialLevel();
		createUI();
	}
	
	function createInitialLevel()
	{
	}
	
	function createUI()
	{
		var uiGroup = new FlxGroup();
		var bigCheese = new DisplayCheese(10, 10);
		bigCheese.scrollFactor.set();
		#if debug bigCheese.ignoreDrawDebug = true; #end
		uiGroup.add(bigCheese);
		
		cheeseCountText = new BitmapText(40, 12, "");
		cheeseCountText.scrollFactor.set();
		#if debug cheeseCountText.ignoreDrawDebug = true; #end
		uiGroup.add(cheeseCountText);
		uiGroup.camera = FlxG.camera;
		add(uiGroup);
	}
	
	function createLevel(levelPath:String, x = 0.0, y = 0.0):FlxGroup
	{
		var level = new Level();
		var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, levelPath);
		var map = new OgmoTilemap(ogmo, 'tiles', 0, 3);
		#if debug map.ignoreDrawDebug = true; #end
		map.setTilesCollisions(40, 4, FlxObject.UP);
		level.map = map;
		grpTilemaps.add(map);
		
		var worldBounds = FlxG.worldBounds;
		if (map.x < worldBounds.x) worldBounds.x = map.x;
		if (map.y < worldBounds.y) worldBounds.y = map.y;
		if (map.x + map.width  > worldBounds.right) worldBounds.right = map.x + map.width;
		if (map.y + map.height > worldBounds.bottom) worldBounds.bottom = map.y + map.height;
		
		var crack = new OgmoTilemap(ogmo, 'Crack', "assets/images/");
		#if debug crack.ignoreDrawDebug = true; #end
		grpCracks.add(crack);
		
		var decalGroup = ogmo.level.get_decal_layer('decals').get_decal_group('assets/images/decals');
		for (decal in decalGroup.members)
		{
			(cast decal:FlxObject).moves = false;
			#if debug
			(cast decal:FlxSprite).ignoreDrawDebug = true;
			#end
		}
		
		level.add(map);
		level.add(crack);
		level.add(decalGroup);
		
		ogmo.level.get_entity_layer('BG entities').load_entities(entity_loader.bind(_, background, level));
		ogmo.level.get_entity_layer('FG entities').load_entities(entity_loader.bind(_, foreground, level));
		
		level.cameraTiles = new CameraTilemap(ogmo);
		grpCameraTiles.add(level.cameraTiles);
		
		levels[levelPath] = level;
		return level;
	}
	
	function createPlayer(x:Float, y:Float):Player
	{
		var avatar = new Player(x, y);
		var settings = PlayerSettings.addAvatar(avatar);
		avatar.onRespawn.add(onPlayerRespawn);
		grpPlayers.add(avatar);
		
		return avatar;
	}
	
	@:allow(ui.pause.MainPage)
	@:allow(ui.DeviceManager)
	function createSecondPlayer()
	{
		if (PlayerSettings.player1 == null || PlayerSettings.player1.avatar == null)
			throw "Creating second player before first";
		if (PlayerSettings.player2 != null && PlayerSettings.player2.avatar != null)
			throw "Only 2 players allowed right now";
		
		final firstPlayer = PlayerSettings.player1.avatar;
		createPlayer(firstPlayer.x, firstPlayer.y);
	}
	
	@:allow(ui.pause.MainPage)
	function removeSecondPlayer(avatar:Player)
	{
		grpPlayers.remove(avatar);
		avatar.destroy();
	}
	
	function entity_loader(e:EntityData, layer:FlxGroup, level:Level)
	{
		var entity:FlxBasic = null;
		switch(e.name)
		{
			case "player": 
				if (curCheckpoint == null)
					curCheckpoint = new Checkpoint(e.x, e.y, "");
			
				var player = createPlayer(e.x, e.y);
				FlxG.camera = player.playCamera;
				level.player = player;
				level.add(player);
				// entity = level.player;
				//layer not used
			case "spider":
				// layer.add(new Enemy(e.x, e.y, OgmoPath.fromEntity(e), e.values.speed));
			case "coins" | "cheese":
				totalCheese++;
				entity = grpCheese.add(new Cheese(e.x, e.y, e.id, true));
			case "blinkingPlatform"|"solidBlinkingPlatform"|"cloudBlinkingPlatform":
				var platform = BlinkingPlatform.fromOgmo(e);
				grpPlatforms.add(platform);
				if (platform.oneWayPlatform)
					grpOneWayPlatforms.add(platform);
				entity = platform;
			case "movingPlatform"|"solidMovingPlatform"|"cloudMovingPlatform":
				var platform = MovingPlatform.fromOgmo(e);
				grpPlatforms.add(platform);
				if (platform.oneWayPlatform)
					grpOneWayPlatforms.add(platform);
				entity = platform;
			case "spike":
				entity = grpSpikes.add(new SpikeObstacle(e.x, e.y, e.rotation));
			case "checkpoint":
				entity = grpCheckpoint.add(Checkpoint.fromOgmo(e));
				// #if debug
				// if (!minimap.checkpoints.exists(rat.ID))
				// 	throw "Non-existent checkpoint id:" + rat.ID;
				// #end
			case "musicTrigger":
				entity = grpMusicTriggers.add(new MusicTrigger(e.x, e.y, e.width, e.height, e.values.song, e.values.fadetime));
			case "secretTrigger":
				trace('ADDED SECRET');
				entity = grpSecretTriggers.add(new SecretTrigger(e.x, e.y, e.width, e.height));
			case 'locked' | 'locked_tall':
				entity = grpLockedDoors.add(Lock.fromOgmo(e));
			case unhandled:
				throw 'Unhandled token:$unhandled';
		}
		
		if (entity != null)
		{
			layer.add(entity);
			level.add(entity);
		}
	}
	
	override function update(elapsed)
	{
		super.update(elapsed);
		
		if (DeviceManager.alertPending())
		{
			openSubState(new DeviceManager());
			return;
		}
		
		updateCollision();
		
		var pauseSubstate:PauseSubstate = null;
		grpPlayers.forEach
		(
			player->
			{
				checkPlayerState(player);
				
				if (pauseSubstate == null && player.controls.PAUSE)
				{
					if (PlayerSettings.numPlayers == 1)
						pauseSubstate = new PauseSubstate(PlayerSettings.player1);
					else
						pauseSubstate = new PauseSubstate(PlayerSettings.player1, PlayerSettings.player2);
				}
			}
		);
		
		if (pauseSubstate != null)
			openSubState(pauseSubstate);
		
		cheeseCountText.text = cheeseCount + (cheeseNeeded > 0 ? "/" + cheeseNeeded : "");
		
		#if debug updateDebugFeatures(); #end
	}
	
	function warpTo(x:Float, y:Float):Void
	{
		grpPlayers.forEach(player->player.hurtAndRespawn(x,y));
	}
	
	inline function updateCollision()
	{
		grpPlayers.forEach(updatePlatforms);
		
		checkDoors();
		updateTriggers();
	}
	
	function updatePlatforms(player:Player)
	{
		// Disable one way platforms when pressing down
		grpOneWayPlatforms.forEach((platform)->platform.cloudSolid = !player.controls.DOWN);
		grpTilemaps.forEach((level)->level.setTilesCollisions(40, 4, player.controls.DOWN ? FlxObject.NONE : FlxObject.UP));
		FlxG.collide(grpTilemaps, player);
		
		var oldPlatform = player.platform;
		player.platform = null;
		FlxG.collide(grpPlatforms, player,
			function(platform:TriggerPlatform, _)
			{
				var movingPlatform = Std.downcast(platform, MovingPlatform);
				if (movingPlatform != null && (player.platform == null || (platform.velocity.y < player.platform.velocity.y)))
					player.platform = movingPlatform;
			}
		);
		
		if (player.platform == null && oldPlatform != null)
			player.onSeparatePlatform(oldPlatform);
		else if (player.platform != null && oldPlatform == null)
			player.onLandPlatform(player.platform);
	}
	
	inline function checkDoors()
	{
		FlxG.collide(grpLockedDoors, grpPlayers,
			function (lock:Lock, player)
			{
				if (cheeseNeededText == null)
				{
					if (cheeseCount >= lock.amountNeeded)
					{
						// Open door
						add(cheeseNeededText = lock.createText());
						cheeseNeededText.showLockAmount(()->
						{
							lock.open();
							cheeseNeededText.kill();
							cheeseNeededText = null;
							if (cheeseNeeded <= lock.amountNeeded)
								cheeseNeeded = 0;
						});
						// FlxG.sound.music.volume = 0;
					}
					else if (cheeseNeeded != lock.amountNeeded)
					{
						// replace current goal with door's goal
						add(cheeseNeededText = lock.createText());
						cheeseNeededText.animateTo
							( cheeseCountText.x + cheeseCountText.width
							, cheeseCountText.y + cheeseCountText.height / 2
							,   ()->
								{
									cheeseNeeded = lock.amountNeeded;
									cheeseNeededText.kill();
									cheeseNeededText = null;
									FlxFlicker.flicker(cheeseCountText, 1, 0.12);
								}
							);
					}
				}
			}
		);
	}
	
	inline function updateTriggers()
	{
		FlxG.overlap(grpPlayers, grpMusicTriggers, function(_, trigger:MusicTrigger)
		{
			if (musicName != trigger.daSong)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.fadeOut(3, 0, (_)->playMusic(trigger.daSong));
				else
					playMusic(trigger.daSong);
			}
		});
		
		FlxG.overlap(grpPlayers, grpSecretTriggers, function(_, trigger:SecretTrigger)
		{
			if (!trigger.hasTriggered)
			{
				if (trigger.medal != null)
					NGio.unlockMedal(trigger.medal);
				
				trigger.hasTriggered = true;
				var oldVol:Float = FlxG.sound.music.volume;
				FlxG.sound.music.volume = 0.1;
				FlxG.sound.play('assets/sounds/discoverysound' + BootState.soundEXT, 1, false, null, true, function()
					{
						FlxG.sound.music.volume = oldVol;
					});
			}
		});
	}
	
	
	inline function checkPlayerState(player:Player)
	{
		if (player.state == Alive)
		{
			if (player.x > FlxG.worldBounds.width)
			{
				player.state = Won;
				FlxG.camera.fade(FlxColor.BLACK, 2, false, FlxG.switchState.bind(new EndState()));
			}
			
			if (SpikeObstacle.overlap(grpSpikes, player))
				player.state = Hurt;
			
			FlxG.overlap(grpCameraTiles, player, 
				(cameraTiles:CameraTilemap, _)->
				{
					player.playCamera.leading = cameraTiles.getTileTypeAt(player.x, player.y);
				}
			);
		}
		
		if (player.state == Hurt)
			player.hurtAndRespawn(curCheckpoint.x, curCheckpoint.y - 16);
		
		dialogueBubble.visible = false;
		if (player.state == Alive)
		{
			if (player.onGround)
				FlxG.overlap(grpCheckpoint, player, handleCheckpoint);
			
			collectCheese();
		}
	}
	
	function handleCheckpoint(checkpoint:Checkpoint, player:Player)
	{
		var autoTalk = checkpoint.autoTalk;
		var dialogue = checkpoint.dialogue;
		if (!gaveCheese && player.cheese.length > 0)
		{
			gaveCheese = true;
			autoTalk = true;
			dialogue = FIRST_CHEESE_MSG + dialogue;
		}
		
		dialogueBubble.visible = true;
		dialogueBubble.setPosition(checkpoint.x + 20, checkpoint.y - 10);
		
		if (player.controls.TALK || autoTalk)
		{
			checkpoint.onTalk();
			player.state = Talking;
			var focalPoint = checkpoint.getGraphicMidpoint(FlxPoint.weak());
			focalPoint.x += checkpoint.cameraOffsetX;
			add(new ZoomDialogueSubstate
				( dialogue
				, focalPoint
				, player.settings
				, ()->player.state = Alive
				)
			);
		}
		
		if (checkpoint != curCheckpoint)
		{
			curCheckpoint.deactivate();
			checkpoint.activate();
			curCheckpoint = checkpoint;
			FlxG.sound.play('assets/sounds/checkpoint' + BootState.soundEXT, 0.8);
		}
		
		if (!player.cheese.isEmpty())
		{
			player.cheese.first().sendToCheckpoint(checkpoint, onFeedCheese);
			player.cheese.clear();
		}
	}
	
	function onFeedCheese(cheese:Cheese)
	{
		cheeseCount++;
	}
	
	function collectCheese()
	{
		FlxG.overlap(grpPlayers, grpCheese, function(player:Player, cheese:Cheese)
		{
			FlxG.sound.play('assets/sounds/collectCheese' + BootState.soundEXT, 0.6);
			cheese.startFollow(player);
			player.cheese.add(cheese);
			NGio.unlockMedal(58879);
		});
		
		if (cheeseCount >= totalCheese)
			NGio.unlockMedal(58884);
	}
	
	inline function updateDebugFeatures()
	{
		if (FlxG.keys.justPressed.B)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		
		if (FlxG.keys.justPressed.T)
			cheeseCount++;

		// if (FlxG.keys.justPressed.SEVEN)
		// 	PlayerSettings.player1.rebindKeys();

		// if (FlxG.keys.justPressed.EIGHT)
		// 	PlayerSettings.player2.rebindKeys();
	}
	
	function onPlayerRespawn():Void
	{
		// Reset moving platform
		for (i in 0...grpPlatforms.members.length)
		{
			if (grpPlatforms.members[i] != null && grpPlatforms.members[i].trigger != Load)
				grpPlatforms.members[i].resetTrigger();
		}
	}
	
	private function playMusic(name:String):Void
	{
		FlxG.sound.playMusic('assets/music/' + name + BootState.soundEXT, 0.7);
		switch (name)
		{
			case "pillow":
				FlxG.sound.music.loopTime = 4450;
				BeatGame.beatsPerMinute = 110;
			case "ritz":
				FlxG.sound.music.loopTime = 0;
				BeatGame.beatsPerMinute = 60;//not needed
		}
		musicName = name;
	}
	
	function getOtherPlayer(player:Player):Player
	{
		return grpPlayers.members[player == grpPlayers.members[0] ? 1 : 0];
	}
}