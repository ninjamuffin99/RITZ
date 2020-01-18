package;

import flixel.FlxSprite;

class Player extends FlxSprite
{
    public function new(x:Float, y:Float):Void
    {
        makeGraphic(32, 32);

        super(x, y);
    }
}