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
        width = RADIUS * 2;
        height = RADIUS * 2;
        offset.x -= Math.floor(width / 4);
        offset.y -= Math.floor(height / 4);
    }
    
    public function getCenter(?p:FlxPoint):FlxPoint
    {
        if (p == null)
            p = FlxPoint.get();
        
        return p.set(centerX, centerY);
    }
}