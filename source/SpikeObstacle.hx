package;

import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.util.FlxColor;

class SpikeObstacle extends Obstacle
{
    inline static var SIZE = 32;
    
    public function new(x:Float, y:Float, rotation:Float) {
        super(x, y);
        angle = rotation;
        
        loadGraphic(AssetPaths.spike__png, true, SIZE, SIZE);
        animation.add('idle', [0, 1, 2, 3], 10);
        animation.play('idle', false, false, FlxMath.wrap(Std.int(x / SIZE * 2), 0, 3));
        
        switch(rotation)
        {
            case 0:
                offset.x = 6;
                width -= (offset.x * 2) + 1;
                offset.y = 3;
                height -= 4;
            case 90:
                this.x -= SIZE;
                offset.x = 3;
                width -= 4;
                offset.y = 6;
                height -= (offset.y * 2) + 1;
            case 180:
                this.x -= SIZE;
                this.y -= SIZE;
                offset.x = 6;
                width -= (offset.x * 2) + 1;
                offset.y = 4;
                height -= 3;
            case -90
                | 270:
                this.y -= SIZE;
                offset.x = 4;
                width -= 3;
                offset.y = 6;
                height -= (offset.y * 2) + 1;
            default:
                trace("unhandled angle: " + rotation);
        }
        this.x += offset.x;
        this.y += offset.y;
    }
}