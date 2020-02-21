package;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.util.FlxColor;

class SpikeObstacle extends Obstacle
{
    inline static var SIZE = 32;
    
    public function new(x:Float, y:Float, rotation:Float) {
        super(x, y);
        angle = rotation;
        
        loadGraphic(AssetPaths.spike__png, true, SIZE, SIZE);
        animation.add('idle', [0, 1, 2, 3], 10);
        animation.play('idle', false, false, FlxMath.wrap(Std.int((x+y) / SIZE), 0, 3));
        
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
            case 180:
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
                trace('unhandled angle: $rotation @($x,$y)');
        }
        this.x += offset.x;
        this.y += offset.y;
    }
    
    inline static var HALF_SIZE = SIZE / 2;
    /**
     * Pixel-perfect collision with the specified object bounds
     * @return true if the object overlaps the spike graphic
     */
    override function hitObject(obj:FlxObject):Bool
    {
        //Note: this is called after a simple bounding box check, obj's rect overlaps with this rect
        
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
}