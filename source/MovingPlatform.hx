package;

import OgmoPath;

import flixel.FlxObject;
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
    public var ogmoPath(get, set):Null<OgmoPath>;
    inline function get_ogmoPath() return cast(path, OgmoPath);
    inline function set_ogmoPath(value:OgmoPath) return cast path = value;
    
    public var oneWayPlatform(default, null) = false;
    
    var trigger:Trigger = Load;
    public function new(x:Float, y:Float) {
        super(x, y);
        
        immovable = true;
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