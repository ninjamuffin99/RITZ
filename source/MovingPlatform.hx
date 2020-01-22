package;

import flixel.util.FlxPath;
import flixel.FlxSprite;

class MovingPlatform extends FlxSprite
{
    public function new(x:Float, y:Float, p:FlxPath) {
        super(x, y);

        path = p;
        path.autoCenter = false;
        path.start(null, 50, FlxPath.LOOP_FORWARD);
        immovable = true;
    }
}