package;

import flixel.FlxSprite;
import flixel.path.FlxPath;

class MovingPlatform extends FlxSprite
{  
    public var disintigrating:Bool = false;
    public var disS:Float = 1;
    public var curDisintigrating:Bool = false;
    public function new(x:Float, y:Float, p:FlxPath) {
        super(x, y);

        path = p;
        path.centerMode = TOP_LEFT;
        path.start(null, 50, LOOP_FORWARD);
        immovable = true;
    }
	override function draw()
	{
		super.draw();

	}
}