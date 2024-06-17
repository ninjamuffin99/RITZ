package;

import flixel.FlxBasic;
import flixel.FlxCamera.FlxCameraFollowStyle;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.text.FlxTypeText;
import flixel.addons.tile.FlxTilemapExt;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.path.FlxPath;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import io.newgrounds.NG;

using StringTools;
using zero.flixel.utilities.FlxOgmoUtils;
using zero.utilities.OgmoUtils;


class PlayState extends FlxState
{
	var level:FlxTilemapExt = new FlxTilemapExt();
	var levelDecalBG:FlxTilemapExt = new FlxTilemapExt();
	var decalsGrp:FlxTypedGroup<FlxSprite>;

	var player:Player;
	var debug:FlxText;
	private var cheeseNeeded:Int = 32;
	private var totalCheese:Int = 0;

	function set_coinCount(v:Int):Int
	{
		coinCount = v;
		debug.text = coinCount + "/" + cheeseNeeded;

		return coinCount;
	}

	private var grpCheese:FlxTypedGroup<Cheese>;
	private var grpMovingPlatforms:FlxTypedGroup<MovingPlatform>;

	private var grpObstacles:FlxTypedGroup<Obstacle>;
	private var coinCount(default, set):Int = 0;
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
		FlxG.camera.fade(FlxColor.BLACK, 2, true);
		musicHandling();

		var bg:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.dumbbg__png);
		bg.scrollFactor.set(0.045, 0.045);
		bg.active = false;
		bg.color = 0xFFBFBFBF;
		add(bg);

		var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, AssetPaths.dumbassLevel__json);
		level.load_tilemap(ogmo, 'assets/data/');
		levelDecalBG.load_tilemap(ogmo, 'assets/data/', "decal_tiles");

		add(levelDecalBG);

		grpMovingPlatforms = new FlxTypedGroup<MovingPlatform>();
		add(grpMovingPlatforms);

		grpObstacles = new FlxTypedGroup<Obstacle>();
		add(grpObstacles);

		grpCheckpoint = new FlxTypedGroup<Checkpoint>();
		add(grpCheckpoint);

		grpMusicTriggers = new FlxTypedGroup<MusicTrigger>();
		add(grpMusicTriggers);

		grpSecretTriggers = new FlxTypedGroup<SecretTrigger>();
		// add(grpSecretTriggers);
		

		add(level);
		decalsGrp = cast ogmo.level.get_decal_layer('decals').get_decal_group('assets');
		decalsGrp.active = false;
		add(decalsGrp);

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

		FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON, 0.15);
		FlxG.camera.focusOn(player.getPosition());
		FlxG.worldBounds.set(0, 0, level.width, level.height);
		level.follow(FlxG.camera);

		var displayCheese:Cheese = new Cheese(10, 10);
		displayCheese.scrollFactor.set();
		add(displayCheese);

		grpDisplayCheese = new FlxGroup();
		add(grpDisplayCheese);

		debug = new FlxText(40, 12, 0, "", 16);
		debug.scrollFactor.set(0, 0);
		debug.color = FlxColor.BLACK;
		debug.setFormat(null, 16, FlxColor.WHITE, null, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		debug.borderSize = 1;
		debug.borderQuality = 1;
		add(debug);

		coinCount = 0;

		#if !debug
		new FlxTimer().start(100, function(_)
		{
			NG.core.calls.gateway.ping().send();
		}, 0);
		NG.core.calls.app.logView().send();
		#end

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
				
				platform.path.setProperties(e.values.speed, LOOP_FORWARD);
				platform.visible = e.values.visible;

				if (e.values.onewayplatform)
				{
					platform.allowCollisions = UP;
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
	private var cheeseAdding:Float = 0;
	private var addingCheese:Bool = false;
	private var ending:Bool = false;
	override public function update(elapsed:Float):Void
	{
		for (decal in decalsGrp.members)
			decal.visible = spriteOnScreen(decal);
		


		FlxG.watch.addMouse();

		FlxG.watch.addQuick("daCheeses", cheeseHolding.length + " " + cheeseHolding.length);
			

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
		FlxG.collide(player, level);

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
				sT.hasTriggered = true;
				var oldVol:Float = FlxG.sound.music.volume;
				FlxG.sound.music.volume = 0.1;
				FlxG.sound.play('assets/sounds/discoverysound' + BootState.soundEXT, 1, false, null, true, function()
					{
						FlxG.sound.music.volume = oldVol;
					});
			}
				
	
		});

		for (spike in grpObstacles.members)
			spike.active = spriteOnScreen(spike);

		if (FlxG.overlap(player, grpObstacles))
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

		if (player.justTouched(FLOOR))
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
			cheeseAdding += elapsed;

			if (cheeseAdding >= 10 / 60)
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
					// if (!hornyMedal.unlocked)
						hornyMedal.sendUnlock();
				}
			}
			
		});

	}

	public static function spriteOnScreen(s:FlxSprite):Bool
	{
		return s.x > FlxG.camera.scroll.x - (s.frameWidth * 2)
			&& s.x + s.frameWidth < FlxG.camera.scroll.x + FlxG.width + (s.frameWidth * 2)
			&& s.y > FlxG.camera.scroll.y - (s.frameWidth * 2)
			&& s.y + s.frameHeight < FlxG.camera.scroll.y + FlxG.height + (s.frameHeight * 2);
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
