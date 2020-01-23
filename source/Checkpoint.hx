package;

import flixel.util.FlxColor;
import flixel.FlxSprite;

class Checkpoint extends FlxSprite
{
    public function new(x:Float, y:Float) {
        super(x, y);
        loadGraphic(AssetPaths.checkpoint_rat__PNG, true, 32, 32);
        
    }
}