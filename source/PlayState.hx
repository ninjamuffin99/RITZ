package;

import js.html.AbortController;
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

	override public function create():Void
	{
		FlxG.camera.fade(FlxColor.BLACK, 2, true);
		FlxG.sound.playMusic('assets/music/' + musicQueue + ".mp3", 0.7);

		var bg:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.dumbbg__png);
		bg.scrollFactor.set(0.045, 0.045);
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

		

		ogmo.level.get_entity_layer('entities').load_entities(entity_loader);

		FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON, 0.15);
		FlxG.worldBounds.set(0, 0, level.width, level.height);
		level.follow(FlxG.camera);

		FlxG.mouse.visible = false;

		

		debug = new FlxText(10, 10, 0, "", 16);
		debug.scrollFactor.set(0, 0);
		debug.color = FlxColor.BLACK;
		add(debug);

		
		

		super.create();
	}

	function entity_loader(e:EntityData) 
	{
		switch(e.name)
		{
			case "player": 
				add(player = new Player(e.x, e.y));
				curCheckpoint = new Checkpoint(e.x, e.y);
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
				platform.makeGraphic(e.width, e.height);
				platform.updateHitbox();
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
				grpCheckpoint.add(new Checkpoint(e.x, e.y));
			case "musicTrigger":
				grpMusicTriggers.add(new MusicTrigger(e.x, e.y, e.width, e.height, e.values.song, e.values.fadetime));
			case "secretTrigger":
				trace('ADDED SECRET');
				grpSecretTriggers.add(new SecretTrigger(e.x, e.y, e.width, e.height));
			case 'locked':
				locked = new FlxSprite(e.x, e.y).makeGraphic(e.width, e.height);
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

	override public function update(elapsed:Float):Void
	{
		FlxG.watch.addMouse();
		debug.text = "Cheese: " + coinCount + "/" + totalCheese;
		
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

		if (player.x > level.width)
			FlxG.switchState(new EndState());
		
		if (FlxG.collide(locked, player))
		{
			if (coinCount >= 30)
			{
				locked.kill();
				FlxG.sound.play(AssetPaths.allcheesesunlocked__mp3);
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
				FlxG.sound.play(AssetPaths.discoverysound__mp3, 1, false, null, true, function()
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

				player.gettingHurt = true;
				player.animation.play('fucking died lmao');
				FlxG.sound.play(AssetPaths.damageTaken__mp3, 0.6);

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

		FlxG.overlap(grpCheckpoint, player, function(c:Checkpoint, p:Player)
		{
			if (c != curCheckpoint)
			{
				grpCheckpoint.forEach(function(c)
					{
						c.isCurCheckpoint = false;
					});

				c.isCurCheckpoint = true;
				curCheckpoint = c;
				FlxG.sound.play(AssetPaths.checkpoint__mp3, 0.8);

				coinCount += cheeseHolding.length;
				cheeseHolding = [];
			}

			if (cheeseHolding.length > 0)
			{
				coinCount += cheeseHolding.length;
				cheeseHolding = [];
			}

			
				
		});
		
		if (FlxG.keys.justPressed.Q)
			FlxG.camera.zoom *= 0.7;
		if (FlxG.keys.justPressed.E)
			FlxG.camera.zoom *= 1.3;

		FlxG.overlap(player, grpCheese, function(p, daCheese)
		{
			if (!p.gettingHurt)
			{
				FlxG.sound.play(AssetPaths.collectCheese__mp3, 0.6);
				cheeseHolding.push(daCheese);
				grpCheese.remove(daCheese, true);
				//coinCount += 1;
			}
			
		});

	}

	private function musicHandling():Void
	{
		FlxG.sound.playMusic('assets/music/' + musicQueue + ".mp3", 0.7);
		switch (musicQueue)
		{
			case "pillow":
				FlxG.sound.music.loopTime = 4450;
			case "ritz":
				FlxG.sound.music.loopTime = 0;
		}
	}
}
