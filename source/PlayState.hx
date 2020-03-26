package;

import Cheese;
import OgmoPath;
import OgmoTilemap;
import props.Platform;
import props.BlinkingPlatform;
import props.MovingPlatform;
import ui.BitmapText;
import ui.DialogueSubstate;
import ui.Inputs;
import ui.PauseSubstate;
import ui.MinimapSubstate;
import ui.Minimap;

import io.newgrounds.NG;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;

import flixel.addons.display.FlxBackdrop;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

class PlayState extends flixel.FlxState
{
	inline static var USE_NEW_CAMERA = true;
	inline static var FIRST_CHEESE_MSG = "Thanks for the cheese, buddy! ";
	
	var level:OgmoTilemap;
	var minimap:Minimap;
	var player:Player;
	var tileSize = 0;

	var foreground = new FlxGroup();
	var background = new FlxGroup();
	var playerLayer = new FlxGroup();
	var grpCheese = new FlxTypedGroup<Cheese>();
	var grpPlatforms = new FlxTypedGroup<TriggerPlatform>();
	var grpOneWayPlatforms = new FlxTypedGroup<Platform>();
	var grpSpikes = new FlxTypedGroup<SpikeObstacle>();
	var curCheckpoint:Checkpoint;
	var grpCheckpoint = new FlxTypedGroup<Checkpoint>();
	var grpLockedDoors = new FlxTypedGroup<Lock>();
	var grpMusicTriggers = new FlxTypedGroup<MusicTrigger>();
	var grpSecretTriggers = new FlxTypedGroup<SecretTrigger>();
	var musicQueue:String = "pillow";

	var gaveCheese = false;
	var cheeseCountText:BitmapText;
	var dialogueBubble:FlxSprite;
	var cheeseCount = 0;
	var cheeseNeeded = 0;
	var totalCheese = 0;
	var cheeseNeededText:LockAmountText;
	
	override public function create():Void
	{
		musicHandling();
		
		var bg:FlxSprite = new FlxBackdrop(AssetPaths.dumbbg__png);
		bg.scrollFactor.set(0.75, 0.75);
		bg.alpha = 0.75;
		#if debug bg.ignoreDrawDebug = true; #end
		add(bg);
		
		var levelPath = 
			// AssetPaths.dumbassLevel__json;
			// AssetPaths.normassLevel__json;
			AssetPaths.smartassLevel__json;
		var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, levelPath);
		minimap = new Minimap(levelPath);
		level = new OgmoTilemap(ogmo, 'tiles', 0, 3);
		level.setTilesCollisions(40, 4, FlxObject.UP);
		#if debug level.ignoreDrawDebug = true; #end
		var crack = new OgmoTilemap(ogmo, 'Crack', "assets/images/");
		#if debug crack.ignoreDrawDebug = true; #end
		
		var decalGroup = ogmo.level.get_decal_layer('decals').get_decal_group('assets/images/decals');
		for (decal in decalGroup)
		{
			(cast decal:FlxObject).moves = false;
			#if debug
			(cast decal:FlxSprite).ignoreDrawDebug = true;
			#end
		}
		
		add(crack);
		add(background);
		add(level);
		add(decalGroup);
		add(foreground);
		add(playerLayer);
		
		//FlxG.sound.playMusic(AssetPaths.pillow__mp3, 0.7);
		//FlxG.sound.music.loopTime = 4450;

		dialogueBubble = new FlxSprite().loadGraphic(AssetPaths.dialogue__png, true, 32, 32);
		dialogueBubble.animation.add('play', [0, 1, 2, 3], 6);
		dialogueBubble.animation.play('play');
		add(dialogueBubble);
		dialogueBubble.visible = false;

		ogmo.level.get_entity_layer('BG entities').load_entities(entity_loader.bind(_, background));
		ogmo.level.get_entity_layer('FG entities').load_entities(entity_loader.bind(_, foreground));
		trace('Total cheese: $totalCheese');
		if (player == null)
			throw "player missing";
		
		var uiGroup = new FlxGroup();
		var bigCheese = new DisplayCheese(10, 10);
		bigCheese.scrollFactor.set();
		#if debug bigCheese.ignoreDrawDebug = true; #end
		uiGroup.add(bigCheese);
		
		cheeseCountText = new BitmapText(40, 12, "");
		cheeseCountText.scrollFactor.set();
		#if debug cheeseCountText.ignoreDrawDebug = true; #end
		uiGroup.add(cheeseCountText);
		add(uiGroup);
		
		super.create();
		
		var camera = FlxG.camera;
		if (USE_NEW_CAMERA)
		{
			var tileSize = Std.int(level.frames.getByIndex(0).frame.height);
			var cameraTiles = new CameraTilemap(ogmo);
			#if debug cameraTiles.ignoreDrawDebug = true; #end
			camera = PlayCamera.replaceCurrentCamera()
				.init(player, tileSize, cameraTiles);
		}
		else
		{
			camera.follow(player, FlxCameraFollowStyle.PLATFORMER, 0.15);
			camera.focusOn(player.getPosition());
		}
		FlxG.worldBounds.set(0, 0, level.width, level.height);
		level.follow(camera);
		camera.fade(FlxColor.BLACK, 2, true);
		camera.bgColor = FlxG.stage.color;
		bg.camera = camera;//prevents it from showing in the dialog substates camera
	}

	function entity_loader(e:EntityData, layer:FlxGroup)
	{
		switch(e.name)
		{
			case "player": 
				player = new Player(e.x, e.y);
				player.onRespawn.add(onPlayerRespawn);
				playerLayer.add(player.dust);
				playerLayer.add(player);
				#if debug
				if (player.jumpSprite != null)
				{
					playerLayer.add(player.jumpSprite);
					player.jumpSprite.x = player.x;
					player.jumpSprite.y = player.y;
				}
				#end
				curCheckpoint = new Checkpoint(e.x, e.y, "");
				//layer not used
			case "spider":
				layer.add(new Enemy(e.x, e.y, OgmoPath.fromEntity(e), e.values.speed));
				trace('spider added');
			case "coins" | "cheese":
				var cheese = new Cheese(e.x, e.y, e.id, true);
				layer.add(cheese);
				grpCheese.add(cheese);
				totalCheese++;
			case "blinkingPlatform"|"solidBlinkingPlatform"|"cloudBlinkingPlatform":
				var platform = BlinkingPlatform.fromOgmo(e);
				// if (platform.active)
				// {
				// 	var path = platform.createPathSprite();
				// 	layer.add(path);
				// 	layer.add(platform);
				// 	layer.add(path.bolt);
				// }
				// else // Add platform only
					layer.add(platform);
				
				grpPlatforms.add(platform);
				if (platform.oneWayPlatform)
					grpOneWayPlatforms.add(platform);
			case "movingPlatform"|"solidMovingPlatform"|"cloudMovingPlatform":
				var platform = MovingPlatform.fromOgmo(e);
				if (platform.visible && platform.ogmoPath != null)
				{
					var path = platform.createPathSprite();
					layer.add(path);
					layer.add(platform);
					layer.add(path.bolt);
				}
				else // Add platform only
					layer.add(platform);
				
				grpPlatforms.add(platform);
				if (platform.oneWayPlatform)
					grpOneWayPlatforms.add(platform);
			case "spike":
				var spike = new SpikeObstacle(e.x, e.y, e.rotation);
				layer.add(spike);
				grpSpikes.add(spike);
			case "checkpoint":
				var rat = Checkpoint.fromOgmo(e);
				layer.add(rat);
				grpCheckpoint.add(rat);
				#if debug
				if (!minimap.checkpoints.exists(rat.ID))
					throw "Non-existent checkpoint id:" + rat.ID;
				#end
			case "musicTrigger":
				grpMusicTriggers.add(new MusicTrigger(e.x, e.y, e.width, e.height, e.values.song, e.values.fadetime));
			case "secretTrigger":
				trace('ADDED SECRET');
				grpSecretTriggers.add(new SecretTrigger(e.x, e.y, e.width, e.height));
			case 'locked' | 'locked_tall':
				var gate = Lock.fromOgmo(e);
				grpLockedDoors.add(gate);
				layer.add(gate);
			case unhandled:
				throw 'Unhandled token:$unhandled';
		}
	}
	
	private var ending:Bool = false;
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!player.active)
			return;
		
		minimap.updateSeen(FlxG.camera);
		
		cheeseCountText.text = cheeseCount + (cheeseNeeded > 0 ? "/" + cheeseNeeded : "");

		if (cheeseCount >= totalCheese)
		{
			if (NGio.isLoggedIn)
			{
				var hornyMedal = NG.core.medals.get(58884);
				if (!hornyMedal.unlocked)
					hornyMedal.sendUnlock();
			}
		}
		
		// Disable one way platforms when pressing down
		if (player.down)
			grpOneWayPlatforms.forEach((platform)->platform.cloudSolid = false);
		
		var oldPlatform = player.platform;
		player.platform = null;
		FlxG.collide(grpPlatforms, player, 
			function(platform:Platform, _)
			{
				if (Std.is(platform, MovingPlatform)
				&& (player.platform == null || (platform.velocity.y < player.platform.velocity.y)))
					player.platform = cast platform;
			}
		);
		if (player.platform == null && oldPlatform != null)
			player.onSeparatePlatform(oldPlatform);
		else if (player.platform != null && oldPlatform == null)
			player.onLandPlatform(player.platform);
		
		// Re-enable one way platforms in case other things collide
		grpOneWayPlatforms.forEach((platform)->platform.cloudSolid = true);
		
		level.setTilesCollisions(40, 4, player.down ? FlxObject.NONE : FlxObject.UP);
		FlxG.collide(level, player);

		if (player.x > level.width && !ending)
		{
			ending = true;
			FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.switchState(new EndState());
				});
		}
		
		FlxG.collide(grpLockedDoors, player,
			function (lock:Lock, _)
			{
				if (cheeseNeededText == null)
				{
					if (cheeseCount >= lock.amountNeeded)
					{
						// Open door
						cheeseNeededText = new LockAmountText
							( lock.x + lock.width  / 2
							, lock.y + lock.height / 2
							, lock.amountNeeded
							);
						add(cheeseNeededText);
						cheeseNeededText.showLockAmount(()->
						{
							lock.kill();
							FlxG.sound.play('assets/sounds/allcheesesunlocked' + BootState.soundEXT);
							FlxG.camera.shake(0.05, 0.15);
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
						cheeseNeededText = new LockAmountText
							( lock.x + lock.width  / 2
							, lock.y + lock.height / 2
							, lock.amountNeeded
							);
						add(cheeseNeededText);
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

		// collide with sides but die by the point, didn't like it but keeping the code
		// if (player.state == Alive && SpikeObstacle.checkKillOrCollide(grpSpikes, player))
		// 	player.state = Hurt;
		if (player.state == Alive && SpikeObstacle.overlap(grpSpikes, player))
			player.state = Hurt;
		
		if (player.state == Hurt)
			player.hurtAndRespawn(curCheckpoint.x, curCheckpoint.y - 16);
		
		dialogueBubble.visible = false;
		if (player.onGround)
		{
			FlxG.overlap(grpCheckpoint, player, function(checkpoint:Checkpoint, _)
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
				minimap.showCheckpointGet(checkpoint.ID);
				
				if (Inputs.justPressed.TALK || autoTalk)
				{
					checkpoint.onTalk();
					persistentUpdate = true;
					persistentDraw = true;
					player.active = false;
					var oldZoom = FlxG.camera.zoom;
					var subState = new DialogueSubstate(dialogue, false);
					subState.closeCallback = ()->
					{
						persistentUpdate = false;
						persistentDraw = false;
						final tweenTime = 0.3;
						FlxTween.tween(FlxG.camera, { zoom: oldZoom }, tweenTime, { onComplete: (_)->player.active = true } );
						if (checkpoint.cameraOffsetX != 0)
							FlxTween.tween(FlxG.camera.targetOffset, { x:0 }, tweenTime);
					};
					openSubState(subState);
					final tweenTime = 0.25;
					FlxTween.tween(FlxG.camera, { zoom: oldZoom * 2 }, tweenTime, {onComplete:(_)->subState.start() });
					if (checkpoint.cameraOffsetX != 0)
						FlxTween.tween(FlxG.camera.targetOffset, { x:checkpoint.cameraOffsetX }, tweenTime);
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
					player.cheese.first().sendToCheckpoint(checkpoint,
						(cheese)->
						{
							cheeseCount++;
							minimap.showCheeseGet(cheese.ID);
						}
					);
					player.cheese.clear();
				}
			});
		}


		if (player.state == Alive)
		{
			FlxG.overlap(player, grpCheese, function(_, cheese:Cheese)
			{
				FlxG.sound.play('assets/sounds/collectCheese' + BootState.soundEXT, 0.6);
				cheese.startFollow(player);
				player.cheese.add(cheese);
				
				if (NGio.isLoggedIn)
				{
					var hornyMedal = NG.core.medals.get(58879);
					if (!hornyMedal.unlocked)
						hornyMedal.sendUnlock();
				}
			});
		}
		
		if (Inputs.justPressed.MAP)
			openSubState(new MinimapSubstate(minimap, player, player.hurtAndRespawn));
		
		if (Inputs.justPressed.PAUSE)
			openSubState(new PauseSubstate());
		
		#if debug
		if (FlxG.keys.justPressed.B)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		
		if (FlxG.keys.justPressed.T)
			cheeseCount++;
		#end
	}
	
	function onPlayerRespawn():Void
	{
		// Reset moving platform
		for (i in 0...grpPlatforms.members.length)
		{
			if (grpPlatforms.members[i] != null)
				grpPlatforms.members[i].resetTrigger();
		}
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

@:forward
abstract LockAmountText(BitmapText) to BitmapText
{
	inline public function new (x, y, amount:Int)
	{
		this = new BitmapText(x, y, Std.string(amount));
		#if debug this.ignoreDrawDebug = true; #end
		this.offset.x = this.width / 2;
		this.offset.y = this.height / 2;
	}
	
	inline public function animateTo(x:Float, y:Float, callback:()->Void):Void
	{
		showLockAmount
		(   ()->
			{
				this.x -= this.camera.scroll.x;
				this.y -= this.camera.scroll.y;
				this.scrollFactor.set();
			}
		).then(FlxTween.tween
			( this
			, { x:x, y:y }
			,   { ease:FlxEase.cubeIn
				, onComplete:(_)->callback()
				}
			)
		);
	}
	
	inline static var RISE_AMOUNT = 32;
	inline public function showLockAmount(callback:()->Void)
	{
		var onComplete:TweenCallback = null;
		if (callback != null)
			onComplete = (_)->callback();
		
		return FlxTween.tween
			( this
			, { y:this.y - RISE_AMOUNT }
			, 0.5
			,   { ease:FlxEase.backOut
				, onComplete:onComplete
			 	}
			);
	}
}