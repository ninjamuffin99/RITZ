package;

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
	private var curCheckpoint:FlxPoint = new FlxPoint();
	private var grpCheckpoint:FlxTypedGroup<Checkpoint>;

	override public function create():Void
	{
		bgColor = FlxColor.WHITE;

		grpMovingPlatforms = new FlxTypedGroup<MovingPlatform>();
		add(grpMovingPlatforms);

		grpObstacles = new FlxTypedGroup<Obstacle>();
		add(grpObstacles);

		grpCheckpoint = new FlxTypedGroup<Checkpoint>();
		add(grpCheckpoint);

		var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, AssetPaths.dumbassLevel__json);
		level.load_tilemap(ogmo, 'assets/data/');
		add(level);

		grpCheese = new FlxTypedGroup<Cheese>();
		add(grpCheese);

		FlxG.sound.playMusic(AssetPaths.pillow__mp3, 0.7);
		FlxG.sound.music.loopTime = 4450;

		

		ogmo.level.get_entity_layer('entities').load_entities(entity_loader);

		FlxG.camera.follow(player, FlxCameraFollowStyle.SCREEN_BY_SCREEN);
		
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
				curCheckpoint.set(e.x, e.y);
			case "coins":
				var daCoin:Cheese = new Cheese(e.x, e.y);
				grpCheese.add(daCoin);
				totalCheese += 1;
			case "movingPlatform":
				var platform:MovingPlatform = new MovingPlatform(e.x, e.y, getPathData(e));
				platform.makeGraphic(e.width, e.height);
				platform.updateHitbox();
				platform.path.setProperties(e.values.speed, FlxPath.LOOP_FORWARD);
				grpMovingPlatforms.add(platform);
			case "spike":
				var spikeAmount = Std.int(e.width / 32);
				for (i in 0...spikeAmount)
				{
					var daSpike:SpikeObstacle = new SpikeObstacle(e.x + (i * 32), e.y);
					grpObstacles.add(daSpike);
				}
			case "checkpoint":
				grpCheckpoint.add(new Checkpoint(e.x, e.y));

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
		debug.text += "\nCamera: " + FlxG.camera.zoom;
		
		super.update(elapsed);
		FlxG.collide(grpMovingPlatforms, player);
		FlxG.collide(level, player);

		if (FlxG.overlap(grpObstacles, player))
		{
			player.setPosition(curCheckpoint.x, curCheckpoint.y - 16);
			player.velocity.set();

			FlxG.sound.play(AssetPaths.damageTaken__mp3, 0.6);
		}

		FlxG.overlap(grpCheckpoint, player, function(c:Checkpoint, p:Player)
		{
			if (c.x != curCheckpoint.x || c.y != curCheckpoint.y)
			{
				curCheckpoint.set(c.x, c.y);
				FlxG.sound.play(AssetPaths.checkpoint__mp3, 0.8);
			}
				
		});
		
		if (FlxG.keys.justPressed.Q)
			FlxG.camera.zoom *= 0.7;
		if (FlxG.keys.justPressed.E)
			FlxG.camera.zoom *= 1.3;

		FlxG.overlap(player, grpCheese, function(p, cheese)
		{
			cheese.kill();
			FlxG.sound.play(AssetPaths.collectCheese__mp3, 0.6);
			coinCount += 1;
		});

	}
}
