package props;

import openfl.geom.Point;
import openfl.geom.Rectangle;

import flixel.FlxG;
import flixel.FlxObject;

import zero.utilities.OgmoUtils;

@:noCompletion
typedef PlatformValues = {
    ?graphic       :String,
    ?oneWayPlatform:Bool
}
@:noCompletion
typedef TriggerPlatformValues = PlatformValues & { trigger:Trigger }

class Platform extends flixel.FlxSprite
{
    public var oneWayPlatform(default, set) = false;
    public var enabled(default, set) = true;
    // set false to allow the player to pass through
    public var cloudSolid(default, set) = true;
    
    function new(x:Float, y:Float)
    {
        super(x, y);
        
        immovable = true;
    }
    
    function setOgmoProperties(data:EntityData)
    {
        var values:PlatformValues = cast data.values;
        oneWayPlatform = values.oneWayPlatform != null ? values.oneWayPlatform : data.name.indexOf("cloud") == 0;
        final type = oneWayPlatform ? "cloud" : "solid";
        
        loadGraphic(getImageFromOgmo(values.graphic, data.width, data.height, type));
        switch (values.graphic)
        {
            case null|"auto":
            case "none":
                visible = false;
            // Deprecated
            default:
                setGraphicSize(data.width, data.height);
        }
        updateHitbox();
    }
    
    function set_oneWayPlatform(value:Bool)
    {
        oneWayPlatform = value;
        updateCollision();
        return value;
    }
    
    function set_enabled(value:Bool)
    {
        enabled = value;
        updateCollision();
        return value;
    }
    
    function set_cloudSolid(value:Bool)
    {
        cloudSolid = value;
        updateCollision();
        return value;
    }
    
    inline function updateCollision()
    {
        allowCollisions = enabled && cloudSolid ? (oneWayPlatform ? FlxObject.UP : FlxObject.ANY) : FlxObject.NONE;
    }
    
    static function getImageFromOgmo(graphic:Null<String>, width:Int, height:Int, type:String)
    {
        return switch(graphic)
        {
            case null|"auto"       : getImage(width, height, type);
            case "movingSingle"    : getImage( 32,  32, type);
            case "movingShort"     : getImage( 64,  32, type);
            case "movingLongside"  : getImage( 96,  32, type);
            case "movingLongerside": getImage(128,  32, type);
            case "movingLong"      : getImage( 32,  96, type);
            case "movingLonger"    : getImage( 32, 128, type);
            case "none": FlxG.bitmap.create(width, height, 0, false, 'nonePlatform_${width}x${height}');
            default: throw 'Unhandled graphic:$graphic';
        }
    }
    
    static function getImage(width:Int, height:Int, type:String)
    {
        final key = '${type}_platform${width}x${height}';
        
        if (FlxG.bitmap.checkCache(key))
            return FlxG.bitmap.get(key);
        
        if (!FlxG.bitmap.checkCache('source_$key'))
            FlxG.bitmap.add('assets/images/${type}_platform.png', 'source_$key');
        
        final source = FlxG.bitmap.get('source_$key');
        final graphic = FlxG.bitmap.create(width, height, 0, false, key);
        graphic.destroyOnNoUse = false;
        // graphic.persist = true;
        
        var sourceRect = new Rectangle(0, 0, 32, 32);
        var destPoint = new Point();
        inline function stamp(sourceTileX:Int, sourceTileY:Int, destTileX:Int, destTileY:Int):Void
        {
            sourceRect.x = sourceTileX << 5;
            sourceRect.y = sourceTileY << 5;
            destPoint.x  = destTileX << 5;
            destPoint.y  = destTileY << 5;
            graphic.bitmap.copyPixels(source.bitmap, sourceRect, destPoint);
        }
        
        inline function getSourceTile(pos:Int, size:Int)
            return size == 1 ? 0 : switch(pos) { case 0: 1; case _ if (pos == size - 1): 3; default: 2; }
        
        final tilesX = width  >> 5;
        final tilesY = height >> 5;
        for (y in 0...tilesY)
        {
            var sourceY = getSourceTile(y, tilesY);
            for (x in 0...tilesX)
                stamp(getSourceTile(x, tilesX), sourceY, x, y);
        }
        return graphic;
    }
}

class TriggerPlatform extends Platform
{
    public var triggered(default, null) = false;
    public var trigger(default, null):Trigger = Load;
    
    override function setOgmoProperties(data:EntityData)
    {
        super.setOgmoProperties(data);
        
        trigger = data.values.trigger;
        
        if (active)
        {
            resetTrigger();
            if (trigger == Load)
                fire();
        }
    }
    
    override function update(elapsed:Float)
    {
        if (!triggered)
        {
            switch (trigger)
            {
                case Load:
                case OnScreen:
                    if (isOnScreen()) fire();
                case Collide:
                    if (touching > 0)
                        fire();
                case Ground:
                    if (touching & FlxObject.CEILING > 0) fire();
            }
        }
        
        super.update(elapsed);
    }
    
    public function fire() { triggered = true; }
    
    public function resetTrigger()
    {
        triggered = false;
        if (trigger == Load)
            fire();
    }
}

enum abstract Trigger(String) to String from String
{
    var Load;
    var OnScreen;
    var Collide;
    var Ground;
}