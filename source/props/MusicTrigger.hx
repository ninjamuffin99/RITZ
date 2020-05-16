package props;

import flixel.FlxObject;

class MusicTrigger extends FlxObject
{
    public var daSong:String = "";
    public var fadeTime:Float = 4;

    public function new(x:Float, y:Float, w:Float, h:Float, song:String, fade:Float) {
        super(x, y);

        daSong = song;
        fadeTime = fade;

        width = w;
        height = h;
    }
}