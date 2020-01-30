package;

import CameraTilemap;

import io.newgrounds.NG;
import flixel.FlxBasic;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.text.FlxTypeText;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.util.FlxPath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.FlxCamera.FlxCameraFollowStyle;
import flixel.FlxG;
import flixel.tile.FlxTilemap;
import flixel.FlxState;
import flixel.FlxObject;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;
using StringTools;


class PlayState extends FlxState
{
	var level:FlxTilemap = new FlxTilemap();
	var player:Player;
	var debug:FlxText;
	var tileSize = 0;
	private var cheeseNeeded:Int = 32;
	private var totalCheese:Int = 0;

	private var grpCheese:FlxTypedGroup<Cheese>;
	private var grpMovingPlatforms:FlxTypedGroup<MovingPlatform>;

	private var grpObstacles:FlxTypedGroup<Obstacle>;
	private var coinCount:Int = 0;
	private var curCheckpoint:Checkpoint;
	private var grpCheckpoint:FlxTypedGroup<Checkpoint>;

	private var grpMusicTriggers:FlxTypedGroup<MusicTrigger>;
	private var grpSecretTriggers:FlxTypedGroup<SecretTrigger>;
	private var musicQueue:String = "pillow";

	private var curTalking:Bool = false;

	private var cheeseHolding:Array<Dynamic> = [];
	private var locked:FlxSprite;
	private var dialogueBubble:FlxSprite;
	private var grpDisplayCheese:FlxGroup;
	
	/**
	 * Too high and it can be disorienting,
	 * too low and the player won't see ahead of their path
	 */
	inline static var CAMERA_LERP = 0.2;
	inline static var PAN_DOWN_DELAY = 0.25;
	inline static var PAN_DOWN_END_DELAY = 0.75;
	inline static var PAN_DOWN_DISTANCE = 4;//tiles
	inline static var PAN_DOWN_TIME = 0.5;
	/** Used to pan down the camera smoothly */
	private var panDownTimer = 0.0;
	/** Offset for when the player is looking down */
	private var camYPanOffset = 0.0;
	inline static var PAN_LEAD_SHIFT_TIME = 0.5;
	inline static var PAN_LEAD_TILES = 1;
	/** TODO: The default offset of a given area, should point up normally, and down in areas that lead downwards*/
	private var camYLeadOffset = 0.0;
	private var camYLeadAmount = 0.0;
	inline static var FALL_LEAD_DELAY = 0.15;
	private var camTargetFallTimer = 0.0;
	/** Time it takes to snap to the new platforms height */
	inline static var PAN_SNAP_TIME = 0.3;
	/** Used to snap the camera to a new ground height when landing */
	private var camYSnapOffset = 0.0;
	private var camYSnapTimer = 0.0;
	private var camYSnapAmount = 0.0;
	private var cameraTilemap:CameraTilemap;
	private var lastCameraPos = new FlxPoint();
	#if debug
	private var debugDeadZone:FlxObject;
	#end
	override public function create():Void
	{
		FlxG.camera.fade(FlxColor.BLACK, 2, true);
		musicHandling();
		
		var bg:FlxSprite = new FlxBackdrop(AssetPaths.dumbbg__png);
		bg.scrollFactor.set(0.75, 0.75);
		bg.alpha = 0.75;
		add(bg);

		var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, AssetPaths.dumbassLevel__json);
		level.load_tilemap(ogmo, 'assets/data/');
		tileSize = Std.int(level.frames.getByIndex(0).frame.height);
		add(ogmo.level.get_decal_layer('decalbg').get_decal_group('assets'));
		cameraTilemap = new CameraTilemap(ogmo);

		grpMovingPlatforms = new FlxTypedGroup<MovingPlatform>();
		add(grpMovingPlatforms);

		grpObstacles = new FlxTypedGroup<Obstacle>();
		add(grpObstacles);

		grpCheckpoint = new FlxTypedGroup<Checkpoint>();
		add(grpCheckpoint);

		grpMusicTriggers = new FlxTypedGroup<MusicTrigger>();
		add(grpMusicTriggers);

		grpSecretTriggers = new FlxTypedGroup<SecretTrigger>();
		add(grpSecretTriggers);
		

		add(level);
		add(ogmo.level.get_decal_layer('decals').get_decal_group('assets'));

		grpCheese = new FlxTypedGroup<Cheese>();
		add(grpCheese);

		//FlxG.sound.playMusic(AssetPaths.pillow__mp3, 0.7);
		//FlxG.sound.music.loopTime = 4450;

		dialogueBubble = new FlxSprite().loadGraphic(AssetPaths.dialogue__png, true, 32, 32);
		dialogueBubble.animation.add('play', [0, 1, 2, 3], 6);
		dialogueBubble.animation.play('play');
		add(dialogueBubble);
		dialogueBubble.visible = false;

		ogmo.level.get_entity_layer('entities').load_entities(entity_loader);

		var camera = FlxG.camera;
		camera.follow(player, FlxCameraFollowStyle.PLATFORMER, CAMERA_LERP);
		camera.focusOn(player.getPosition());
		var w = (camera.width / 8);
		var h = (camera.height * 2 / 3);
		camera.deadzone.set((camera.width - w) / 2, (camera.height - h) / 2, w, h);
		camYLeadOffset = camYLeadAmount = tileSize * -PAN_LEAD_TILES;
		FlxG.worldBounds.set(0, 0, level.width, level.height);
		level.follow(camera);

		FlxG.mouse.visible = false;

		var displayCheese:Cheese = new Cheese(10, 10);
		displayCheese.scrollFactor.set();
		add(displayCheese);

		grpDisplayCheese = new FlxGroup();
		add(grpDisplayCheese);

		trace(grpCheese.length);

		debug = new FlxText(40, 12, 0, "", 16);
		debug.scrollFactor.set(0, 0);
		debug.color = FlxColor.BLACK;
		debug.setFormat(null, 16, FlxColor.WHITE, null, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(debug);

		super.create();
	}

	function entity_loader(e:EntityData) 
	{
		switch(e.name)
		{
			case "player": 
				add(player = new Player(e.x, e.y));
				curCheckpoint = new Checkpoint(e.x, e.y, "");
			case "spider":
				var spider:Enemy = new Enemy(e.x, e.y, getPathData(e), e.values.speed);
				add(spider);
				trace('spider added');
			case "coins":
				var daCoin:Cheese = new Cheese(e.x, e.y);
				grpCheese.add(daCoin);
				totalCheese += 1;
			case "movingPlatform":
				var platform:MovingPlatform = new MovingPlatform(e.x, e.y, getPathData(e));
				platform.disintigrating = e.values.disintigrate;
				platform.disS = e.values.disintigrateSeconds;
				if (e.values.graphic != "none")
				{
					platform.loadGraphic('assets/images/' + e.values.graphic + '.png');
				}
				else
				{
					platform.makeGraphic(e.width, e.height);
					platform.updateHitbox();
				}
				
				platform.path.setProperties(e.values.speed, FlxPath.LOOP_FORWARD);
				platform.visible = e.values.visible;

				if (e.values.onewayplatform)
				{
					platform.allowCollisions = FlxObject.UP;
				}
				
				var lastStringbit:String = Std.string(e.values.color).substring(1, 7);
				var firstStringbit:String = Std.string(e.values.color).substring(7, 10);

				platform.color = FlxColor.fromString(Std.string("#" + firstStringbit + lastStringbit).toUpperCase());
				
				grpMovingPlatforms.add(platform);

			case "spike":
				var spikeAmount = Std.int(e.width / 32);
				for (i in 0...spikeAmount)
				{
					var daSpike:SpikeObstacle = new SpikeObstacle(e.x + (i * 32), e.y);
					daSpike.angle = e.values.angle;
					grpObstacles.add(daSpike);
				}
			case "checkpoint":
				grpCheckpoint.add(new Checkpoint(e.x, e.y, e.values.dialogue));
			case "musicTrigger":
				grpMusicTriggers.add(new MusicTrigger(e.x, e.y, e.width, e.height, e.values.song, e.values.fadetime));
			case "secretTrigger":
				trace('ADDED SECRET');
				grpSecretTriggers.add(new SecretTrigger(e.x, e.y, e.width, e.height));
			case 'locked':
				locked = new FlxSprite(e.x, e.y).loadGraphic(AssetPaths.door__png);
				locked.setGraphicSize(192, 64);
				locked.updateHitbox();
				locked.immovable = true;
				add(locked);
		}
	}

	private function getPathData(o:EntityData):FlxPath
	{
		var daPath:Array<FlxPoint> = [new FlxPoint(o.x, o.y)];

		for (point in o.nodes)
		{
			daPath.push(new FlxPoint(point.x, point.y));
		}

		return new FlxPath(daPath);
	}


	// These are stupid awful and confusing names for these variables
	// One of them is a ticker (cheeseAdding) and the other is to see if its in the state of adding cheese
	private var cheeseAdding:Int = 0;
	private var addingCheese:Bool = false;
	private var ending:Bool = false;
	override public function update(elapsed:Float):Void
	{
		FlxG.watch.addMouse();
		debug.text = coinCount + "/" + cheeseNeeded;

		FlxG.watch.addQuick("daCheeses", cheeseHolding.length + " " + cheeseHolding.length);

		if (coinCount >= 55)
		{
			if (NGio.isLoggedIn)
			{
				var hornyMedal = NG.core.medals.get(58884);
				if (!hornyMedal.unlocked)
					hornyMedal.sendUnlock();
			}
		}
			

		/* 
		if (cheeseHolding.length > grpDisplayCheese.length)
		{
			for (i in grpDisplayCheese.length...cheeseHolding.length)
			{
				var daCheese:Cheese = cheeseHolding[i];
				daCheese.scrollFactor.set();
				daCheese.setGraphicSize(Std.int(daCheese.width / 2));
				daCheese.updateHitbox();
				daCheese.setPosition(90 + (10 * (i % 6)), 10 + (10 * Math.floor(i / 6)));
				grpDisplayCheese.add(daCheese);
			}
		}
		*/
		
		super.update(elapsed);
		
		FlxG.collide(grpMovingPlatforms, player, function(platform:MovingPlatform, p:Player)
		{
			if (platform.disintigrating && !platform.curDisintigrating)
			{
				platform.curDisintigrating = true;
				new FlxTimer().start(platform.disS, function(t:FlxTimer)
					{
						platform.kill();
					});
			}

		});
		FlxG.collide(level, player);

		if (player.x > level.width && !ending)
		{
			ending = true;
			FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.switchState(new EndState());
				});
		}
		
		if (FlxG.collide(locked, player))
		{
			if (coinCount >= cheeseNeeded)
			{
				locked.kill();
				FlxG.sound.play('assets/sounds/allcheesesunlocked' + BootState.soundEXT);
				FlxG.sound.music.volume = 0;
			}
		}

		FlxG.overlap(player, grpMusicTriggers, function(p:Player, mT:MusicTrigger)
		{
			if (musicQueue != mT.daSong)
			{
				musicQueue = mT.daSong;

				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.fadeOut(3, 0, function(t:FlxTween)
					{
						musicHandling();
					});
				}
				else
					musicHandling();
			}

		});

		FlxG.overlap(player, grpSecretTriggers, function(p:Player, sT:SecretTrigger)
		{
			if (!sT.hasTriggered)
			{
				if (NGio.isLoggedIn)
				{
					var hornyMedal = NG.core.medals.get(58883);
					if (!hornyMedal.unlocked)
						hornyMedal.sendUnlock();
				}

				sT.hasTriggered = true;
				var oldVol:Float = FlxG.sound.music.volume;
				FlxG.sound.music.volume = 0.1;
				FlxG.sound.play('assets/sounds/discoverysound' + BootState.soundEXT, 1, false, null, true, function()
					{
						FlxG.sound.music.volume = oldVol;
					});
			}
				
	
		});

		if (FlxG.overlap(grpObstacles, player))
		{
			if (!player.gettingHurt)
			{
				for (ch in 0...cheeseHolding.length)
				{
					grpCheese.add(cheeseHolding[ch]);
				}
				cheeseHolding = [];

				grpDisplayCheese.members = [];

				player.gettingHurt = true;
				player.animation.play('fucking died lmao');
				FlxG.sound.play('assets/sounds/damageTaken' + BootState.soundEXT, 0.6);

				new FlxTimer().start(0.5, function (tmr:FlxTimer)
				{
					player.setPosition(curCheckpoint.x, curCheckpoint.y - 16);
					player.velocity.set();
					player.gettingHurt = false;
				});
			}
		}

		if (player.justTouched(FlxObject.FLOOR))
			add(new Dust(player.x, player.y));
		
		dialogueBubble.visible = false;

		FlxG.overlap(grpCheckpoint, player, function(c:Checkpoint, p:Player)
		{
			dialogueBubble.visible = true;
			dialogueBubble.setPosition(c.x + 20, c.y - 10);

			if (FlxG.keys.anyJustPressed([E, F, X]))
			{
				persistentUpdate = false;
				openSubState(new DialogueSubstate(c.dialogue));
			}

			var gamepad = FlxG.gamepads.lastActive;
			if (gamepad != null)
			{
				if (gamepad.justPressed.X)
				{
					persistentUpdate = false;
					openSubState(new DialogueSubstate(c.dialogue));
				}
			}

			if (c != curCheckpoint)
			{
				grpCheckpoint.forEach(function(c)
					{
						c.isCurCheckpoint = false;
					});

				c.isCurCheckpoint = true;
				curCheckpoint = c;
				FlxG.sound.play('assets/sounds/checkpoint' + BootState.soundEXT, 0.8);
			}

			if (cheeseHolding.length > 0)
			{

				addingCheese = true;
			}
				
		});

		if (addingCheese)
		{
			cheeseAdding++;

			if (cheeseAdding >= 10)
			{
				coinCount += 1;
				cheeseHolding.pop();
				grpDisplayCheese.members.pop();
				cheeseAdding = 0;

				FlxG.sound.play('assets/sounds/Munchsound' + FlxG.random.int(1, 4) + BootState.soundEXT, FlxG.random.float(0.7, 1));
			}

			if (cheeseHolding.length == 0)
				addingCheese = false;

			
		}

		FlxG.overlap(player, grpCheese, function(p, daCheese)
		{
			if (!p.gettingHurt)
			{
				FlxG.sound.play('assets/sounds/collectCheese' + BootState.soundEXT, 0.6);
				cheeseHolding.push(daCheese);
				grpCheese.remove(daCheese, true);

				var daCheese:Cheese = new Cheese(0, 0);
				daCheese.scrollFactor.set();
				daCheese.setGraphicSize(Std.int(daCheese.width / 2));
				daCheese.updateHitbox();
				daCheese.setPosition(95 + (10 * ((cheeseHolding.length - 1) % 6)), 10 + (10 * Math.floor((cheeseHolding.length - 1) / 6)));
				grpDisplayCheese.add(daCheese);
				//coinCount += 1;

				if (NGio.isLoggedIn)
				{
					var hornyMedal = NG.core.medals.get(58879);
					if (!hornyMedal.unlocked)
						hornyMedal.sendUnlock();
				}
			}
			
		});
		
		updateCamera(elapsed);
	}
	
	function updateCamera(elapsed:Float):Void
	{
		// Deadzone: taller when jumping, but snap to center when on the ground
		var camera = FlxG.camera;
		var zone = camera.deadzone;
		if (!player.gettingHurt && player.onGround != player.wasOnGround)
		{
			if (player.onGround)
			{
				zone.height = player.height;
				zone.y = (camera.height - zone.height) / 2 - (tileSize * 1);
			}
			else
			{
				zone.height = camera.height * 2 / 3;
				zone.y = (camera.height - zone.height) / 2 - (tileSize * 2);
			}
			
			// Snap to new ground height
			if (player.onGround)
			{
				// Compute the amount of y dis to move the camera
				camera.targetOffset.y = camYLeadOffset + camYPanOffset;
				var oldCam = FlxPoint.get().copyFrom(camera.scroll);
				camera.snapToTarget();
				camYSnapTimer = 0;
				camYSnapAmount = -(camera.scroll.y - oldCam.y);
				camera.scroll.copyFrom(oldCam);
				oldCam.put();
			}
		}
		
		// actual snapping
		if (camYSnapAmount != 0)
		{
			camYSnapTimer += elapsed;
			if (camYSnapTimer > PAN_SNAP_TIME)
				camYSnapOffset = camYSnapAmount = 0;
			else
				camYSnapOffset = camYSnapAmount * /*FlxEase.smootherStepInOut*/(1.0 - (camYSnapTimer / PAN_SNAP_TIME));
		}
		
		// Look down while pressing down
		var downPress = FlxG.keys.anyPressed([S, DOWN]);
		var gamepad = FlxG.gamepads.lastActive;
		if (!downPress && gamepad != null)
			downPress = gamepad.anyPressed([DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN]);
		
		if (downPress)
		{
			panDownTimer += elapsed;
			if (panDownTimer > PAN_DOWN_DELAY + PAN_DOWN_TIME)
				// stay down after releasing the button for a bit
				panDownTimer = PAN_DOWN_DELAY + PAN_DOWN_TIME + PAN_DOWN_END_DELAY;
		}
		else if (panDownTimer < PAN_DOWN_DELAY)
			panDownTimer = 0;
		else
			panDownTimer -= elapsed;
		
		if (panDownTimer > 0)
		{
			if (panDownTimer > PAN_DOWN_DELAY)
				camYPanOffset
					= tileSize * PAN_DOWN_DISTANCE
					* /*FlxEase.smoothStepInOut*/(Math.min(panDownTimer - PAN_DOWN_DELAY, PAN_DOWN_TIME) / PAN_DOWN_TIME);
		}
		
		// Tilemap leading bias, Look up unless it's a downward section of the level (indicated in ogmo)
		var leading = cameraTilemap.getTileTypeAt(player.x, player.y);
		if (leading != Down)
		{
			if (player.velocity.y > 0 && camera.scroll.y > lastCameraPos.y)
			{
				// Lead down when falling for some time
				camTargetFallTimer += elapsed;
				trace(camTargetFallTimer);
				if (camTargetFallTimer > FALL_LEAD_DELAY)
					leading = CameraTileType.Down;
			}
			else
				camTargetFallTimer = 0;
		}
		
		switch (leading)
		{
			case Up  : camYLeadAmount = tileSize * -PAN_LEAD_TILES;
			case Down: camYLeadAmount = tileSize *  PAN_LEAD_TILES;
		}
		
		// linear shift because I'm lazy and this can get weird if player keeps going back and forth
		if (camYLeadOffset != camYLeadAmount)
		{
			var leadSpeed = 2 * PAN_LEAD_TILES * tileSize / PAN_LEAD_SHIFT_TIME * elapsed;
			if (camYLeadOffset < camYLeadAmount)
			{
				camYLeadOffset += leadSpeed;
				if (camYLeadOffset > camYLeadAmount)// bound
					camYLeadOffset = camYLeadAmount;
			}
			else
			{
				camYLeadOffset -= leadSpeed;
				if (camYLeadOffset < camYLeadAmount)// bound
					camYLeadOffset = camYLeadAmount;
			}
		}
		
		// Combine all the camera offsets
		camera.targetOffset.y = camYSnapOffset + camYPanOffset + camYLeadOffset;
		lastCameraPos.copyFrom(camera.scroll);
		
		#if debug
		if (FlxG.keys.justPressed.C)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		
		if (FlxG.debugger.drawDebug)
		{
			if (debugDeadZone == null)
			{
				debugDeadZone = new FlxObject();
				debugDeadZone.scrollFactor.set();
				
				forEach((child)->
				{
					if (Std.is(child, FlxObject))
						(cast child:FlxObject).ignoreDrawDebug = true;
				}, true);
				add(debugDeadZone);
			}
			
			debugDeadZone.x = zone.x - camera.targetOffset.x;
			debugDeadZone.y = zone.y - camera.targetOffset.y;
			debugDeadZone.width = zone.width;
			debugDeadZone.height = zone.height;
		}
		#end
	}

	private function musicHandling():Void
	{
		FlxG.sound.playMusic('assets/music/' + musicQueue + BootState.soundEXT, 0.7);
		switch (musicQueue)
		{
			case "pillow":
				FlxG.sound.music.loopTime = 4450;
			case "ritz":
				FlxG.sound.music.loopTime = 0;
		}
	}
}
