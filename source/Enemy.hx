package;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class Enemy extends FlxSprite
{
    public function new(x:Float, y:Float) {
        super(x, y);

        makeGraphic(32, 32, FlxColor.MAGENTA);
    }
}