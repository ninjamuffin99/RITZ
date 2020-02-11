package;

import OgmoTilemap;

import io.newgrounds.NG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
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
import flixel.tile.FlxTilemap;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.tweens.FlxEase;

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
	private var coinCount:Int = 0;
	private var curCheckpoint:Checkpoint;
	private var grpCheckpoint = new FlxTypedGroup<Checkpoint>();
	private var grpLockedDoors = new FlxTypedGroup<Lock>();

	private var grpMusicTriggers = new FlxTypedGroup<MusicTrigger>();
	private var grpSecretTriggers = new FlxTypedGroup<SecretTrigger>();
	private var musicQueue:String = "pillow";

	private var curTalking:Bool = false;

	var cheeseCount:FlxText;
	var cheeseHolding:Array<Cheese> = [];
	var dialogueBubble:FlxSprite;
	var grpDisplayCheese:FlxGroup;
	var cheeseNeeded = 0;
	var totalCheese = 0;
	var cheeseNeededText:LockAmountText;
	
	override public function create():Void
	{
		musicHandling();
		
		var bg:FlxSprite = new FlxBackdrop(AssetPaths.dumbbg__png);
		bg.scrollFactor.set(0.75, 0.75);
		bg.alpha = 0.75;
		bg.ignoreDrawDebug = true;
		add(bg);

		var ogmo = FlxOgmoUtils.get_ogmo_package
			( AssetPaths.levelProject__ogmo
			// , AssetPaths.dumbassLevel__json
			, AssetPaths.smartassLevel__json
			);
		level = new OgmoTilemap(ogmo, 'tiles', 0, 4);
		level.ignoreDrawDebug = true;
		var crack = new OgmoTilemap(ogmo, 'Crack', "assets/images/");
		crack.ignoreDrawDebug = true;
		add(crack);

		add(grpMovingPlatforms);
		add(grpObstacles);
		add(grpCheckpoint);
		add(grpMusicTriggers);
		add(grpSecretTriggers);
		add(grpLockedDoors);

		add(level);
		var decalGroup = ogmo.level.get_decal_layer('decals').get_decal_group('assets');
		(cast decalGroup:FlxTypedGroup<FlxSprite>).forEach((decal)->decal.ignoreDrawDebug = true);
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

		FlxG.mouse.visible = false;
		
		var uiGroup = new FlxGroup();
		var bigCheese:Cheese = new Cheese(10, 10);
		bigCheese.scrollFactor.set();
		bigCheese.ignoreDrawDebug = true;
		uiGroup.add(bigCheese);

		grpDisplayCheese = new FlxGroup();
		uiGroup.add(grpDisplayCheese);
		
		cheeseCount = new FlxText(40, 12, 0, "", 16);
		cheeseCount.scrollFactor.set(0, 0);
		cheeseCount.color = FlxColor.BLACK;
		cheeseCount.setFormat(null, 16, FlxColor.WHITE, null, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cheeseCount.ignoreDrawDebug = true;
		uiGroup.add(cheeseCount);
		add(uiGroup);
		
		super.create();
		
		var camera = FlxG.camera;
		if (USE_NEW_CAMERA)
		{
			var tileSize = Std.int(level.frames.getByIndex(0).frame.height);
			var cameraTiles = new CameraTilemap(ogmo);
			cameraTiles.ignoreDrawDebug = true;
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
		FlxG.camera.fade(FlxColor.BLACK, 2, true);
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
				totalCheese += 1;
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
			case 'locked':
				grpLockedDoors.add(Lock.fromOgmo(e));
		}
	}

	// These are stupid awful and confusing names for these variables
	// One of them is a ticker (cheeseAdding) and the other is to see if its in the state of adding cheese
	private var cheeseAdding:Int = 0;
	private var addingCheese:Bool = false;
	private var ending:Bool = false;
	override public function update(elapsed:Float):Void
	{
		FlxG.watch.addMouse();
		cheeseCount.text = coinCount + (cheeseNeeded > 0 ? "/" + cheeseNeeded : "");

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
		
		FlxG.collide(grpMovingPlatforms, player);
		
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
					if (coinCount >= lock.amountNeeded)
					{
						lock.kill();
						FlxG.sound.play('assets/sounds/allcheesesunlocked' + BootState.soundEXT);
						FlxG.sound.music.volume = 0;
					}
					else if (cheeseNeeded != lock.amountNeeded)
					{
						cheeseNeededText = new LockAmountText
							( lock.x + lock.width  / 2
							, lock.y + lock.height / 2
							, lock.amountNeeded
							);
						add(cheeseNeededText);
						cheeseNeededText.animateTo
							( cheeseCount.x + cheeseCount.width
							, cheeseCount.y + cheeseCount.height / 2
							,   ()->
								{
									cheeseNeeded = lock.amountNeeded;
									cheeseNeededText.kill();
									cheeseNeededText = null;
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

		FlxG.overlap(player, grpCheese, function(_, daCheese:Cheese)
		{
			if (!player.gettingHurt)
			{
				FlxG.sound.play('assets/sounds/collectCheese' + BootState.soundEXT, 0.6);
				cheeseHolding.push(daCheese);
				grpCheese.remove(daCheese, true);

				var daCheese:Cheese = new Cheese(0, 0);
				daCheese.scrollFactor.set();
				daCheese.ignoreDrawDebug = true;
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
		
		if (FlxG.keys.justPressed.B)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
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
		this.ignoreDrawDebug = true;
		this.offset.x = this.width / 2;
		this.offset.y = this.height / 2;
	}
	
	inline static var RISE_AMOUNT = 32;
	inline public function animateTo(x:Float, y:Float, callback:()->Void):Void
	{
		FlxTween.tween
			( this
			, { y:this.y - RISE_AMOUNT }
			, 0.5
			,   { ease:FlxEase.backOut
				, onComplete:(_)->
					{
						this.x -= this.camera.scroll.x;
						this.y -= this.camera.scroll.y;
						this.scrollFactor.set();
					}
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
}