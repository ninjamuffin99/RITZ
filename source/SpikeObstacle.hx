package;

import flixel.util.FlxColor;

class SpikeObstacle extends Obstacle
{
    public function new(x:Float, y:Float) {
        super(x, y);

        makeGraphic(30, 30, FlxColor.RED);
        
    }
}