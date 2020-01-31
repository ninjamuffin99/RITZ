package;

import io.newgrounds.NG;
import flixel.FlxBasic;
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
	
	override public function create():Void
	{
		musicHandling();
		
		var bg:FlxSprite = new FlxBackdrop(AssetPaths.dumbbg__png);
		bg.scrollFactor.set(0.75, 0.75);
		bg.alpha = 0.75;
		add(bg);

		var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, AssetPaths.dumbassLevel__json);
		level.load_tilemap(ogmo, 'assets/data/');
		add(ogmo.level.get_decal_layer('decalbg').get_decal_group('assets'));

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
		
		var camera = PlayCamera.replaceCurrentCamera();
		camera.tileSize = Std.int(level.frames.getByIndex(0).frame.height);
		camera.cameraTilemap = new CameraTilemap(ogmo);
		camera.init(player);
		FlxG.worldBounds.set(0, 0, level.width, level.height);
		level.follow(camera);
		FlxG.camera.fade(FlxColor.BLACK, 2, true);
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
