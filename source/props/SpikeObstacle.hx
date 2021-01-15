package props;

import beat.BeatGame;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

class SpikeObstacle extends Obstacle
{
    inline static var SIZE = 32;
    // inline static var
    
    public function new(x:Float, y:Float, rotation:Float)
    {
        super(x, y);
        angle = rotation;
        immovable = true;
        moves = false;
        
        loadGraphic("assets/images/spike.png", true, SIZE, SIZE);
        animation.add('idle', [1, 2, 3, 0, 0, 0], 0);
        var anim = animation.getByName('idle');
        anim.frameRate = BeatGame.beatsPerSecond * anim.numFrames;
        animation.play('idle', false, false, FlxMath.wrap(Std.int((x+y) / SIZE * anim.numFrames / 2) , 0, anim.numFrames - 1));
        
        switch(rotation)
        {
            case 0:
                // offset.x = 6;
                // width -= (offset.x * 2) + 1;
                // offset.y = 3;
                // height -= 4;
            case 90:
                this.x -= SIZE;
                // offset.x = 3;
                // width -= 4;
                // offset.y = 6;
                // height -= (offset.y * 2) + 1;
            case 180|-180:
                this.x -= SIZE;
                this.y -= SIZE;
                // offset.x = 6;
                // width -= (offset.x * 2) + 1;
                // offset.y = 4;
                // height -= 3;
            case -90 | 270:
                this.y -= SIZE;
                // offset.x = 4;
                // width -= 3;
                // offset.y = 6;
                // height -= (offset.y * 2) + 1;
            default:
                throw 'unhandled angle: $rotation @($x,$y)';
        }
        this.x += offset.x;
        this.y += offset.y;
    }
    
    inline function setKillMode():Void
    {
        allowCollisions = switch(angle)
        {
            case   0: FlxObject.UP;
            case  90: FlxObject.RIGHT;
            case 180: FlxObject.DOWN;
            case -90: FlxObject.LEFT;
            default: throw 'unhandled angle: $angle';
        }
    }
    
    inline function setCollideMode():Void
    {
        allowCollisions = switch(angle)
        {
            case   0|180: FlxObject.RIGHT | FlxObject.LEFT;
            case  90|-90: FlxObject.UP    | FlxObject.DOWN;
            default: throw 'unhandled angle: $angle';
        }
    }
    
    inline static var HALF_SIZE = SIZE / 2;
    /**
     * Pixel-perfect collision with the specified object bounds
     * @return true if the object overlaps the spike graphic
     */
    override function hitObject(obj:FlxObject):Bool
    {
        //Note: this is called after a simple bounding box check, obj's rect overlaps with this rect
        inline function checkCollision(moving:Bool, dir:Int):Bool
            return moving && (allowCollisions & dir) > 0;
        
        if (allowCollisions != FlxObject.ANY
        &&  !checkCollision(obj.velocity.y > 0, FlxObject.UP)
        &&  !checkCollision(obj.velocity.x < 0, FlxObject.RIGHT)
        &&  !checkCollision(obj.velocity.y < 0, FlxObject.DOWN)
        &&  !checkCollision(obj.velocity.x > 0, FlxObject.LEFT))
            return false;
        
        /** distance from base of spike */
        var normDis = 0.0;
        /** distance perp to spike axis */
        var wallPos = 0.0;
        /** size of obj perp to spike axis */
        var objEdge = 0.0;
        
        switch(angle)
        {
            case 0://UP
                objEdge = obj.width;
                wallPos = obj.x - x;
                normDis = (y + height) - (obj.y + obj.height);
                
            case 90://RIGHT
                objEdge = obj.height;
                wallPos = obj.y - y;
                normDis = obj.x - x;
                
            case 180://DOWN
                objEdge = obj.width;
                wallPos = obj.x - x;
                normDis = obj.y - y;
                
            case -90 | 270://LEFT
                objEdge = obj.height;
                wallPos = obj.y - y;
                normDis = (x + width) - (obj.x + obj.width);
        }
        
        // spike center axis to closest corner of object
        var disFromCenter = 
            if (HALF_SIZE > (wallPos + objEdge))
                HALF_SIZE - (wallPos + objEdge);
            else if (wallPos > HALF_SIZE)
                wallPos - HALF_SIZE;
            else 0.0;
        
        return normDis <= SIZE - disFromCenter * 2;
    }
    
    /** Reused group for collide calls */
    static var collideGroup = new FlxTypedGroup<SpikeObstacle>();
    static public function checkKillOrCollide(spikes:FlxTypedGroup<SpikeObstacle>, objectOrGroup, ?notifyCallback):Bool
    {
        if (FlxG.overlap(spikes, objectOrGroup, (spike, _)->collideGroup.add(spike)))
        {
            inline collideGroup.forEach(spike->spike.setKillMode());
            var touching = Obstacle.overlap(cast collideGroup, objectOrGroup, notifyCallback);
            if (!touching)
            {
                inline collideGroup.forEach(spike->spike.setCollideMode());
                //TODO: collide and process via cone shape
                FlxG.collide(collideGroup, objectOrGroup, notifyCallback);
            }
            inline collideGroup.forEach(spike->
                {
                    spike.allowCollisions = FlxObject.ANY;
                    collideGroup.remove(spike);
                }
            );
            return touching;
        }
        return false;
    }
    
    inline static public function overlap
        ( spikes:FlxTypedGroup<SpikeObstacle>
        , objectOrGroup
        , ?notifyCallback:(SpikeObstacle, Dynamic)->Void
        ):Bool
        return Obstacle.overlap(cast spikes, objectOrGroup, cast notifyCallback);
}