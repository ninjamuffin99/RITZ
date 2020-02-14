package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(480, 288, BootState, 1, 60, 60, true));
		FlxG.mouse.useSystemCursor = true;
	}
}
