package;

import flixel.util.FlxPath;
import flixel.FlxSprite;

class MovingPlatform extends FlxSprite
{  
    public var disintigrating:Bool = false;
    public var disS:Float = 1;
    public var curDisintigrating:Bool = false;
    public function new(x:Float, y:Float, p:FlxPath) {
        super(x, y);

        path = p;
        path.autoCenter = false;
        path.start(null, 50, FlxPath.LOOP_FORWARD);
        immovable = true;
    }
}