package props;

import OgmoPath;
import props.Platform;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxVector;

import zero.utilities.OgmoUtils;

class MovingPlatform extends TriggerPlatform
{
    inline static var TRANSFER_DELAY = 0.2;
    
    /** The velocity it transfers to rits when he jumps */
    public var transferVelocity(default, null):ReadonlyVector = FlxVector.get();
    var timer = 0.0;
    
    public var ogmoPath(get, set):Null<OgmoPath>;
    inline function get_ogmoPath() return cast(path, OgmoPath);
    inline function set_ogmoPath(value:OgmoPath) return cast path = value;
    var pathSprite:PathSprite;
    var bolt:Bolt;
    
    public function new(x:Float, y:Float) { super(x, y); }
    
    inline function createPathSprite()
    {
        var sprite = ogmoPath.createPathSprite();
        sprite.x += width / 2;
        sprite.y += height / 2;
        return sprite;
    }
    
    override function setOgmoProperties(data:EntityData)
    {
        ogmoPath = OgmoPath.fromEntity(data);
        if (ogmoPath == null)
            active = false;
        
        super.setOgmoProperties(data);
        if (ogmoPath != null)
        {
            ogmoPath.autoCenter = false;
            
            if (trigger != Load)
                ogmoPath.onLoopComplete = (_)->resetTrigger();
            
            pathSprite = createPathSprite();
            bolt = new Bolt();
        }
    }
    
    override function update(elapsed:Float)
    {
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
        
        bolt.update(elapsed);
    }
    
    override function draw()
    {
        pathSprite.draw();
        super.draw();
        bolt.drawCenteredOn(this);
    }
    
    override function fire()
    {
        super.fire();
        
        ogmoPath.restart();
    }
    
    override function resetTrigger()
    {
        if (path != null && path.active)
        {
            path.restart();
            path.active = false;
            reset(path.nodes[path.nodeIndex].x, path.nodes[path.nodeIndex].y);
        }
        super.resetTrigger();
    }
    
    inline static public function fromOgmo(data:EntityData)
    {
        var platform = new MovingPlatform(data.x, data.y);
        platform.setOgmoProperties(data);
        return platform;
    }
}

abstract Bolt(FlxSprite) to FlxSprite
{
    public function new()
    {
        this = new FlxSprite();
        this.loadGraphic("assets/images/path_bolt.png", true, 7, 7);
        this.animation.add("stopped", [0]); 
        this.animation.add("moving", [0, 1, 2, 3], 8); 
        this.offset.set(Math.floor(this.width / 2), Math.floor(this.height / 2));
    }
    
    inline public function update(elapsed:Float)
    {
        this.animation.play(this.x == this.last.x && this.y == this.last.y ? "stopped" : "moving");
        this.update(elapsed);
    }
    
    inline public function drawCenteredOn(target:FlxObject)
    {
        this.x = target.x + target.width  / 2;
        this.y = target.y + target.height / 2;
        this.draw();
    }
}

abstract ReadonlyVector(FlxVector) from FlxVector
{
    public var x(get, never):Float; inline function get_x() return this.x;
    public var y(get, never):Float; inline function get_y() return this.y;
}