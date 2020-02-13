package;

import flixel.util.FlxColor;
import flixel.FlxSprite;

class Checkpoint extends FlxSprite
{
    public var isCurCheckpoint:Bool = false;
    public var dialogue:String = "";

    public function new(x:Float, y:Float, d:String) {
        super(x, y + 2);
        loadGraphic(AssetPaths.checkpoint_rat__png, true, 32, 32);
        animation.add('idle', [0, 1, 2, 3], 10);
        animation.add('play', [4, 5, 6, 7], 10);
        animation.play('idle');

        dialogue = d;
    }

    override function update(elapsed:Float) {
        if (isCurCheckpoint)
            animation.play('play');
        else
            animation.play('idle');
        super.update(elapsed);
    }
}