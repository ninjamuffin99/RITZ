package props;

import flixel.math.FlxPoint;

class Hook extends flixel.FlxSprite
{
    inline static public var DROOP = 32;
    
    inline static var RADIUS = 8;
    
    public var centerX(get, never):Float;
    public var centerY(get, never):Float;
    inline public function get_centerX() return x + RADIUS;
    inline public function get_centerY() return y + RADIUS;
    
    public function new(x:Float, y:Float)
    {
        super(x, y, "assets/images/hook.png");
        setGraphicSize(RADIUS * 2, RADIUS * 2);
        updateHitbox();
        x -= Math.floor(width / 2);
        y -= Math.floor(height / 2);
    }
    
    public function getCenter(?p:FlxPoint):FlxPoint
    {
        if (p == null)
            p = FlxPoint.get();
        
        return p.set(centerX, centerY);
    }
}