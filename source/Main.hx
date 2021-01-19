package;

import flixel.FlxG;

class Main extends openfl.display.Sprite
{
	inline static var SCALE:Int = 2;
	public function new()
	{
		super();
		addChild(
			new beat.BeatGame(
				Std.int(stage.stageWidth / SCALE),
				Std.int(stage.stageHeight / SCALE),
				states.BootState,
				1, 60, 60, true
			)
		);
		
		FlxG.mouse.useSystemCursor = true;
	}
}
