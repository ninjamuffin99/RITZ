package data;

import data.OgmoTilemap;
import props.Player;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;

class Section extends FlxGroup
{
    public var map:OgmoTilemap;
    public var cameraTiles:CameraTilemap;
    public var offset(default, null) = FlxPoint.get();
    
    public function new (offset:FlxPoint)
    {
        this.offset.copyFrom(offset);
        super();
    }
    
    public function contains(x:Float, y:Float)
    {
        return containsPoint(FlxPoint.weak(x, y));
    }
    
    public function overlaps(obj:FlxObject)
    {
        return map.overlaps(obj);
    }
    
    inline public function containsPoint(p:FlxPoint)
    {
        return map.overlapsPoint(p);
    }
}