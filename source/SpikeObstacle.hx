package;

import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.util.FlxColor;

class SpikeObstacle extends Obstacle
{
    public function new(x:Float, y:Float) {
        super(x, y);

        loadGraphic(AssetPaths.spike__png, true, 32, 32);
        animation.add('idle', [0, 1, 2, 3], 10);
        animation.play('idle', false, false, FlxMath.wrap(Std.int(x / 64), 0, 3));

        offset.y = 3;
        height -= 4;
        offset.x = 10;
        width -= (offset.x * 2) + 1;

        this.y += 2;
        this.x += 13;
        
    }
}