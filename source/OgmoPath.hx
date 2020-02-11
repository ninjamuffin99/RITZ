package;

import flixel.math.FlxPoint;
import flixel.util.FlxPath;

import zero.utilities.OgmoUtils;

class OgmoPath extends FlxPath
{
    public var holdPerNode = 0.0;
    public var holdPerLoop = 0.0;
    public var mode(get, set):Int;
    inline function get_mode() return _mode;
    inline function set_mode(value:Int) return _mode = value;
    
    public var onLoopComplete:(OgmoPath)->Void;
    
    var holdTimer = 0.0;
    var wasFirstUpdate = false;
    
    function new () { super(); }
    
    override function update(elapsed:Float)
    {
        wasFirstUpdate = _firstUpdate;
        super.update(elapsed);
        holdTimer -= elapsed;
    }
    
    override function advancePath(Snap:Bool = true):FlxPoint
    {
        if (!wasFirstUpdate)
            holdTimer = holdPerNode;
        
        var oldIndex = nodeIndex;
        var point = super.advancePath(Snap);
        if (oldIndex == 0 && !wasFirstUpdate)
        {
            holdTimer += holdPerLoop;
            if (onLoopComplete != null)
                onLoopComplete(this);
        }
        return point;
    }
    
    override function calculateVelocity(node:FlxPoint, horizontalOnly:Bool, verticalOnly:Bool)
    {
        if (holdTimer <= 0)
            super.calculateVelocity(node, horizontalOnly, verticalOnly);
        else
            object.velocity.set();
    }
    
    inline public function resume():Void { active = true; }
    inline public function pause():Void { active = false; }
    
    static public function fromEntity(data:EntityData):OgmoPath
    {
        if (data.nodes == null)
            return null;
        
        var path = new OgmoPath();
        path.add(data.x, data.y);
        
        for (point in data.nodes)
            path.add(point.x, point.y);
        
        if (Reflect.hasField(data.values, "speed"))
            path.speed = data.values.speed;
        
        if (Reflect.hasField(data.values, "type"))
            path.mode = (data.values.type:PathType).getFlxPathMode();
        
        if (Reflect.hasField(data.values, "holdPerNode"))
            path.holdPerNode = data.values.holdPerNode;
        
        if (Reflect.hasField(data.values, "holdPerLoop"))
            path.holdPerLoop = data.values.holdPerLoop ;
        
        path.setProperties(path.speed, path.mode);
        return path;
    }
}

enum abstract PathType(String) to String from String
{
    var LOOP_FORWARD;
    var LOOP_BACKWARD;
    var FORWARD;
    var BACKWARD;
    var YOYO;
    
    inline public function getFlxPathMode():Int
    {
        return switch this
        {
            case LOOP_FORWARD : FlxPath.LOOP_FORWARD;
            case LOOP_BACKWARD: FlxPath.LOOP_BACKWARD;
            case FORWARD      : FlxPath.FORWARD;
            case BACKWARD     : FlxPath.BACKWARD;
            case YOYO         : FlxPath.YOYO;
            default: throw "Unhandled PathType:" + this;
        }
    }
}