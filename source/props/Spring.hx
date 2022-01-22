package props;

import flixel.FlxSprite;

import zero.utilities.OgmoUtils;

class Spring extends FlxSprite implements Bouncer
{
    public var bumpMin(default, null) = 2.0;
    public var bumpMax(default, null) = 2.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        loadGraphic("assets/images/spring.png", true, 32, 32);
        offset.x = 2;
        offset.y = 19;
        width -= offset.x * 2;
        height -= offset.y;
    }
    
    static public function fromOgmo(data:EntityData)
    {
        return new Spring(data.x + 2, data.y + 19);
    }
}