package props;

import flixel.FlxObject;

class SecretTrigger extends FlxObject
{
    public var hasTriggered:Bool = false;
    public var medal:Null<Int>;

    public function new(x:Float, y:Float, w:Float, h:Float, ?medal:Int) {
        super(x, y);
        width = w;
        height = h;
        this.medal = medal;

        trace('YEP I BEEN ADDED LMAO');
    }
}