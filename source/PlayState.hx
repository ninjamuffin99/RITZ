package;

import OgmoTilemap;

import io.newgrounds.NG;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.tweens.FlxEase;

import flixel.addons.display.FlxBackdrop;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;
using StringTools;


class PlayState extends FlxState
{
	inline static var USE_NEW_CAMERA = true;
	
	var level:OgmoTilemap;
	var player:Player;
	var tileSize = 0;

	private var grpCheese = new FlxTypedGroup<Cheese>();
	private var grpMovingPlatforms = new FlxTypedGroup<MovingPlatform>();

	private var grpObstacles = new FlxTypedGroup<Obstacle>();
	private var curCheckpoint:Checkpoint;
	private var grpCheckpoint = new FlxTypedGroup<Checkpoint>();
	private var grpLockedDoors = new FlxTypedGroup<Lock>();

	private var grpMusicTriggers = new FlxTypedGroup<MusicTrigger>();
	private var grpSecretTriggers = new FlxTypedGroup<SecretTrigger>();
	private var musicQueue:String = "pillow";

	private var curTalking:Bool = false;

	var cheeseCountText:FlxText;
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

		var ogmo = FlxOgmoUtils.get_ogmo_package
			( AssetPaths.levelProject__ogmo
			// , AssetPaths.dumbassLevel__json
			, AssetPaths.normassLevel__json
			// , AssetPaths.smartassLevel__json
			);
		level = new OgmoTilemap(ogmo, 'tiles', 0, 4);
		#if debug level.ignoreDrawDebug = true; #end
		var crack = new OgmoTilemap(ogmo, 'Crack', "assets/images/");
		#if debug crack.ignoreDrawDebug = true; #end
		
		add(crack);
		add(grpMovingPlatforms);
		add(grpObstacles);
		add(level);
		add(grpCheckpoint);
		add(grpMusicTriggers);
		add(grpSecretTriggers);
		add(grpLockedDoors);

		var decalGroup = ogmo.level.get_decal_layer('decals').get_decal_group('assets');
		#if debug
		(cast decalGroup:FlxTypedGroup<FlxSprite>).forEach((decal)->decal.ignoreDrawDebug = true);
		#end
		add(decalGroup);

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
		trace('Total cheese: $totalCheese');
		if (player == null)
			throw "player missing";
		
		var uiGroup = new FlxGroup();
		var bigCheese:Cheese = new Cheese(10, 10);
		bigCheese.scrollFactor.set();
		#if debug bigCheese.ignoreDrawDebug = true; #end
		uiGroup.add(bigCheese);
		
		cheeseCountText = new FlxText(40, 12, 0, "", 16);
		cheeseCountText.scrollFactor.set(0, 0);
		cheeseCountText.color = FlxColor.BLACK;
		cheeseCountText.setFormat(null, 16, FlxColor.WHITE, null, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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

	function entity_loader(e:EntityData) 
	{
		switch(e.name)
		{
			case "player": 
				player = new Player(e.x, e.y);
				add(player.dust);
				add(player);
				curCheckpoint = new Checkpoint(e.x, e.y, "");
			case "spider":
				add(new Enemy(e.x, e.y, OgmoPath.fromEntity(e), e.values.speed));
				trace('spider added');
			case "coins":
				grpCheese.add(new Cheese(e.x, e.y));
				totalCheese++;
			case "movingPlatform":
				grpMovingPlatforms.add(MovingPlatform.fromOgmo(e));
			case "spike":
				grpObstacles.add(new SpikeObstacle(e.x, e.y, e.rotation));
			case "checkpoint":
				grpCheckpoint.add(new Checkpoint(e.x, e.y, e.values.dialogue));
			case "musicTrigger":
				grpMusicTriggers.add(new MusicTrigger(e.x, e.y, e.width, e.height, e.values.song, e.values.fadetime));
			case "secretTrigger":
				trace('ADDED SECRET');
				grpSecretTriggers.add(new SecretTrigger(e.x, e.y, e.width, e.height));
			case 'locked' | 'locked_tall':
				grpLockedDoors.add(Lock.fromOgmo(e));
		}
	}
	
	private var ending:Bool = false;
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!player.active)
			return;
		
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
		
		player.platform = null;
		FlxG.collide(grpMovingPlatforms, player, 
			function(platform:MovingPlatform, _)
			{
				if (player.platform == null || (platform.velocity.y < player.platform.velocity.y))
					player.platform = platform;
			}
		);
		
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

		if (!player.gettingHurt && Obstacle.overlap(grpObstacles, player))
			player.hurtAndRespawn(curCheckpoint.x, curCheckpoint.y - 16);
		
		dialogueBubble.visible = false;

		FlxG.overlap(grpCheckpoint, player, function(checkpoint:Checkpoint, _)
		{
			dialogueBubble.visible = true;
			dialogueBubble.setPosition(checkpoint.x + 20, checkpoint.y - 10);

			var gamepad = FlxG.gamepads.lastActive;
			if (FlxG.keys.anyJustPressed([E, F, X]) || (gamepad != null && gamepad.justPressed.X))
			{
				persistentUpdate = true;
				persistentDraw = true;
				player.active = false;
				var oldZoom = FlxG.camera.zoom;
				var subState = new DialogueSubstate(checkpoint.dialogue, false,
					()->
					{
						persistentUpdate = false;
						persistentDraw = false;
						FlxTween.tween(FlxG.camera, { zoom: oldZoom }, 0.25, { onComplete: (_)->player.active = true } );
					}
				);
				openSubState(subState);
				FlxTween.tween(FlxG.camera, { zoom: oldZoom * 2 }, 0.25, {onComplete:(_)->subState.start() });
			}
			
			if (checkpoint != curCheckpoint)
			{
				curCheckpoint.isCurCheckpoint = false;
				checkpoint.isCurCheckpoint = true;
				curCheckpoint = checkpoint;
				FlxG.sound.play('assets/sounds/checkpoint' + BootState.soundEXT, 0.8);
			}

			if (!player.cheese.isEmpty())
			{
				player.cheese.first().sendToCheckpoint(checkpoint, ()->{ cheeseCount++; });
				player.cheese.clear();
			}
		});


		FlxG.overlap(player, grpCheese, function(_, cheese:Cheese)
		{
			if (!player.gettingHurt)
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
			}
			
		});
		
		#if debug
		if (FlxG.keys.justPressed.B)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		
		if (FlxG.keys.justPressed.T)
			cheeseCount++;
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

@:forward
abstract LockAmountText(FlxText) to FlxText
{
	inline public function new (x, y, amount:Int)
	{
		this = new FlxText(x, y, 0, Std.string(amount), 16);
		this.setFormat(null, 16, FlxColor.WHITE, null, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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