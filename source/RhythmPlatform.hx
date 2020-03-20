package;
import zero.utilities.OgmoUtils;

class RhythmPlatform extends MovingPlatform
{
    public var beatSwap:Int = 0;
    public function new(x:Float, y:Float) 
    {
        super(x, y);
    }

    inline static public function fromOgmo(data:EntityData)
    {
        var platform = new RhythmPlatform(data.x, data.y);
        platform.setOgmoProperties(data);


        return platform;
    }
}