package;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class Obstacle extends FlxSprite
{
    public function new(x:Float, y:Float) {
        super(x, y);

        makeGraphic(32, 16, FlxColor.BLUE);
    }
	override function draw()
	{
		if (PlayState.spriteOnScreen(this))
		{
			super.draw();
		}
	}
}