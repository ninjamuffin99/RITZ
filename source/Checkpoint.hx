package;

import flixel.util.FlxColor;
import flixel.FlxSprite;

class Checkpoint extends FlxSprite
{
    public var isCurCheckpoint:Bool = false;

    public function new(x:Float, y:Float) {
        super(x, y);
        loadGraphic(AssetPaths.checkpoint_rat__PNG, true, 32, 32);
        offset.y -= 2;
        animation.add('idle', [0, 1, 2, 3], 10);
        animation.add('play', [4, 5, 6, 7], 10);
        animation.play('idle');
    }

    override function update(elapsed:Float) {
        if (isCurCheckpoint)
            animation.play('play');
        else
            animation.play('idle');
        super.update(elapsed);
    }
}