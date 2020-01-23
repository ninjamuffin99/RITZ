package;

import flixel.FlxG;
import flixel.util.FlxColor;

class SpikeObstacle extends Obstacle
{
    public function new(x:Float, y:Float) {
        super(x, y);

        loadGraphic('assets/images/tac' + FlxG.random.int(1, 3) + ".png");
        offset.y = 3;
        height -= 4;
        offset.x = 13;
        width -= (offset.x * 2) + 1;

        this.y += 5;
        this.x += 13;
        
    }
}