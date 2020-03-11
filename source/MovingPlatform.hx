package;

import OgmoPath;

import flixel.FlxObject;
import flixel.math.FlxVector;
import flixel.util.FlxTimer;

import zero.utilities.OgmoUtils;

@:noCompletion
typedef EntityValues = {
    graphic       :String,
    oneWayPlatform:Bool,
    trigger       :Trigger
}

class MovingPlatform extends flixel.FlxSprite
{
    inline static var TRANSFER_DELAY = 0.2;
    
    /** The velocity it transfers to rits when he jumps */
    public var transferVelocity(default, null):ReadonlyVector = FlxVector.get();
    var timer = 0.0;
    
    public var ogmoPath(get, set):Null<OgmoPath>;
    inline function get_ogmoPath() return cast(path, OgmoPath);
    inline function set_ogmoPath(value:OgmoPath) return cast path = value;
    
    public var oneWayPlatform(default, null) = false;
    public var trigger(default, null):Trigger = Load;
    
    public function new(x:Float, y:Float) {
        super(x, y);
        
        immovable = true;
    }
    
    inline public function createPathSprite()
    {
        var path = ogmoPath.createPathSprite();
        path.x += width / 2;
        path.y += height / 2;
        return path;
    }
    
    override function update(elapsed:Float)
    {
        if (ogmoPath != null && !path.active)
        {
            switch (trigger)
            {
                case Load:
                case OnScreen:
                    if (isOnScreen())
                        ogmoPath.restart();
                case Collide:
                    if (touching > 0)
                        ogmoPath.restart();
                case Ground:
                    if (touching & FlxObject.CEILING > 0)
                        ogmoPath.restart();
            }
        }
        
        super.update(elapsed);
        
        if (velocity.x != 0 || velocity.y != 0)
        {
            velocity.copyTo(cast transferVelocity);
            timer = TRANSFER_DELAY;
        }
        else if (timer > 0)
        {
            timer -= elapsed;
            if (timer <= 0)
                velocity.copyTo(cast transferVelocity);
        }
    }
    
    inline function setOgmoProperties(data:EntityData)
    {
        var values:EntityValues = cast data.values;
        oneWayPlatform = values.oneWayPlatform;
        trigger = values.trigger;
        
        var graphic = values.graphic;
        if (graphic == "auto")
        {
            switch(data.width >> 5)
            {
                case 1:
                    switch(data.height >> 5)
                    {
                        case 1: graphic = "movingSingle";
                        case 3: graphic = "movingLong";
                        case 4: graphic = "movingLong";//<--stretched
                        case 5: graphic = "movingLonger";
                        case _: throw 'Cannot autodetermine graphics from size (32x${data.height})';
                    }
                case 2: graphic = "movingShort";
                case 3: graphic = "movingLongside";
                case 4: graphic = "movingLongside";
                case 5: graphic = "movingLongerside";
                case _: throw 'Cannot autodetermine graphics from size (${data.width}x${data.height})';
            }
        }
        
        if (graphic == "none")
        {
            makeGraphic(data.width, data.height);
            visible = false;
        }
        else
        {
            graphic += "_" + (oneWayPlatform ? "cloud" : "solid");
            loadGraphic('assets/images/$graphic.png');
            setGraphicSize(data.width, data.height);
        }
        updateHitbox();
        
        ogmoPath = OgmoPath.fromEntity(data);
        if (ogmoPath != null)
        {
            ogmoPath.autoCenter = false;
            if (trigger == Load)
                ogmoPath.restart();
            else
                ogmoPath.onLoopComplete = (_)->ogmoPath.pause();
        }
        
        if (values.oneWayPlatform)
            allowCollisions = FlxObject.UP;
    }
    
    public function resetPath()
    {
        if (path.active && trigger != Load)
        {
            path.restart();
            path.active = false;
            reset(path.nodes[path.nodeIndex].x, path.nodes[path.nodeIndex].y);
        }
    }
    
    inline static public function fromOgmo(data:EntityData)
    {
        var platform = new MovingPlatform(data.x, data.y);
        platform.setOgmoProperties(data);
        return platform;
    }
}

enum abstract Trigger(String) to String from String
{
    var Load;
    var OnScreen;
    var Collide;
    var Ground;
}

abstract ReadonlyVector(FlxVector) from FlxVector
{
    public var x(get, never):Float; inline function get_x() return this.x;
    public var y(get, never):Float; inline function get_y() return this.y;
}