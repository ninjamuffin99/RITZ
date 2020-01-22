package;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class Cheese extends FlxSprite
{
    public function new(x:Float, y:Float) 
    {
        super(x, y);

        loadGraphic(AssetPaths.cheese_idle__png, true, 32, 32);
        animation.add('idle', [0, 1, 2, 3, 4, 5, 6], 12);
        animation.play('idle', false, false, -1);
        offset.x = 2;
        width -= 5;
        offset.y = 2;
        height -= 7;
    }
}