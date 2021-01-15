package props;

import flixel.FlxG;
import flixel.FlxSprite;

class Dust extends FlxSprite
{
    static inline var WIDTH = 32;
    static inline var HEIGHT = 14;
    public function new(x = 0.0, y = 0.0)
    {
        super(x, y);
        
        offset.y = HEIGHT;
        #if debug ignoreDrawDebug = true; #end
    }
    
    inline public function place(type:DustType, x:Float, y:Float, flipX:Bool)
    {
        reset(x, y);
        this.flipX = flipX;
        
        var width = WIDTH;
        var graphic = "dust";
        if (type == Skid)
        {
            graphic = "dust" + FlxG.random.int(1, 2);
            width = Std.int(WIDTH / 2);
        }
        loadGraphic('assets/images/$graphic.png', true, width, HEIGHT);
        animation.add("play", [0, 1, 2, 2, 2, 3], FlxG.random.int(19,24), false);
        animation.play('play');
        offset.x = width / 2;
    }

    override function update(elapsed:Float) {
        if (animation.curAnim.finished)
            kill();
        
        super.update(elapsed);
    }
}
enum DustType
{
    Land;
    Skid;
}