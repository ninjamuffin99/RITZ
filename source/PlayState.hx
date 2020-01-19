package;

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

	override public function create():Void
	{
		var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, AssetPaths.dumbassLevel__json);
		level.load_tilemap(ogmo, 'assets/data/');
		add(level);

		ogmo.level.get_entity_layer('entities').load_entities(entity_loader);

		FlxG.camera.follow(player, FlxCameraFollowStyle.PLATFORMER, 0.9);
		FlxG.worldBounds.set(0, 0, level.width, level.height);
		FlxG.camera.setScrollBounds(0, level.width, 0, level.height);

		FlxG.mouse.visible = false;

		debug = new FlxText(10, 10, 0, "", 16);
		debug.scrollFactor.set(0, 0);
		add(debug);

		super.create();
	}

	function entity_loader(e:EntityData) 
	{
		trace(e.name);
		switch(e.name)
		{
			case "player": add(player = new Player(e.x, e.y));
		}
	}

	override public function update(elapsed:Float):Void
	{
		FlxG.watch.addMouse();
		debug.text = "Velocity " + player.velocity.y;
		debug.text += "\nTochinWall " + player.isTouching(FlxObject.WALL);
		
		super.update(elapsed);
		FlxG.collide(level, player);
	}
}
