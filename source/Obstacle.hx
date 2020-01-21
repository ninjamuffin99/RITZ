package;

import flixel.util.FlxColor;
import flixel.FlxSprite;

class Obstacle extends FlxSprite
{
    public function new(x:Float, y:Float) {
        super(x, y);

        makeGraphic(32, 16, FlxColor.BLUE);
    }
}