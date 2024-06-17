package;

import flixel.FlxGame;
import openfl.display.Sprite;
import lime.app.Application;

class Main extends Sprite
{
	public function new()
	{
		super();

		#if web
		// pixel perfect render fix!
		Application.current.window.element.style.setProperty("image-rendering", "pixelated");
		#end

		addChild(new FlxGame(480, 288, BootState, 60, 60, true));
	}
}
