package data;

import zero.utilities.OgmoUtils;
import flixel.FlxObject;


@:forward(overlaps, getHitbox, x, y, width, height)
abstract Room(FlxObject) to FlxObject
{
    public var left(get, never):Float;
    inline function get_left() return this.x;
    public var right(get, never):Float;
    inline function get_right() return this.x + this.width;
    public var top(get, never):Float;
    inline function get_top() return this.y;
    public var bottom(get, never):Float;
    inline function get_bottom() return this.y + this.height;
    
    inline public function new (x = 0.0, y = 0.0, width = 0.0, height = 0.0)
    {
        this = new FlxObject(x, y, width, height);
    }
    
    inline static public function fromOgmo(e:EntityData)
    {
        return new Room(e.x, e.y, e.width, e.height);
    }
}