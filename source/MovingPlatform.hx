package;

import OgmoPath;

import openfl.display.Bitmap;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxVector;
import flixel.util.FlxTimer;

import zero.utilities.OgmoUtils;

@:noCompletion
typedef EntityValues = {
    ?graphic       :String,
    ?oneWayPlatform:Bool,
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
        trigger = values.trigger;
        oneWayPlatform = values.oneWayPlatform != null ? values.oneWayPlatform : data.name == "cloudPlatform";
        final type = oneWayPlatform ? "cloud" : "solid";
        
        switch (values.graphic)
        {
            case null|"auto":
                loadGraphic(getImage(data.width, data.height, type));
            case "none":
                makeGraphic(data.width, data.height);
                visible = false;
            // Deprecated
            case graphic:
                loadGraphic
                (
                    switch(graphic)
                    {
                        case "movingSingle"    : getImage( 32,  32, type);
                        case "movingShort"     : getImage( 64,  32, type);
                        case "movingLongside"  : getImage( 96,  32, type);
                        case "movingLongerside": getImage(128,  32, type);
                        case "movingLong"      : getImage( 32,  96, type);
                        case "movingLonger"    : getImage( 32, 128, type);
                        default: throw 'Unhandled graphic:$graphic';
                    }
                );
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
    
    static function getImage(width:Int, height:Int, type:String)
    {
        final key = '${type}Platform${width}x${height}';
        
        if (FlxG.bitmap.checkCache(key))
            return FlxG.bitmap.get(key);
        
        if (!FlxG.bitmap.checkCache('source_$key'))
            FlxG.bitmap.add('assets/images/${type}Platform.png', 'source_$key');
        
        final source = FlxG.bitmap.get('source_$key');
        final graphic = FlxG.bitmap.create(width, height, 0, false, key);
        
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