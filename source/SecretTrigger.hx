package;

import flixel.FlxObject;

class SecretTrigger extends FlxObject
{
    public var hasTriggered:Bool = false;

    public function new(x:Float, y:Float, w:Float, h:Float) {
        super(x, y);
        width = w;
        height = h;

        trace('YEP I BEEN ADDED LMAO');
    }
}