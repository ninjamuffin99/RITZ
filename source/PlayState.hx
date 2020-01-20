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

	private var grpCheese:FlxTypedGroup<Cheese>;
	private var grpMovingPlatforms:FlxTypedGroup<MovingPlatform>;
	private var coinCount:Int = 0;

	override public function create():Void
	{
		bgColor = FlxColor.WHITE;

		var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, AssetPaths.dumbassLevel__json);
		level.load_tilemap(ogmo, 'assets/data/');
		add(level);

		grpCheese = new FlxTypedGroup<Cheese>();
		add(grpCheese);

		grpMovingPlatforms = new FlxTypedGroup<MovingPlatform>();
		add(grpMovingPlatforms);

		ogmo.level.get_entity_layer('entities').load_entities(entity_loader);

		FlxG.camera.follow(player, FlxCameraFollowStyle.PLATFORMER, 0.3);
		FlxG.camera.followLead.set(1.7, 1.2);

		
		FlxG.worldBounds.set(0, 0, level.width, level.height);
		FlxG.camera.setScrollBounds(0, level.width, 0, level.height);

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
			case "player": add(player = new Player(e.x, e.y));
			case "coins":
				var daCoin:Cheese = new Cheese(e.x, e.y);
				grpCheese.add(daCoin);
			case "movingPlatform":
				var platform:MovingPlatform = new MovingPlatform(e.x, e.y, getPathData(e));
				platform.makeGraphic(e.width, e.height);
				platform.updateHitbox();
				platform.path.setProperties(e.values.speed, FlxPath.LOOP_FORWARD);
				grpMovingPlatforms.add(platform);

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
		debug.text = "Cheese: " + coinCount;
		debug.text += "\nCamera: " + FlxG.camera.zoom;
		
		super.update(elapsed);
		FlxG.collide(grpMovingPlatforms, player);
		FlxG.collide(level, player);
		
		if (FlxG.keys.justPressed.Q)
			FlxG.camera.zoom *= 0.7;
		if (FlxG.keys.justPressed.E)
			FlxG.camera.zoom *= 1.3;

		FlxG.overlap(player, grpCheese, function(p, cheese)
		{
			cheese.kill();
			coinCount += 1;
		});

	}
}
