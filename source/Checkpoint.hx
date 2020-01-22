package;

import flixel.util.FlxColor;
import flixel.FlxSprite;

class Checkpoint extends FlxSprite
{
    public function new(x:Float, y:Float) {
        super(x, y);
        makeGraphic(8, 8, FlxColor.GREEN);
    }
}