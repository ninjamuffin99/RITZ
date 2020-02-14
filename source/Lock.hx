package;

import zero.utilities.OgmoUtils;

class Lock extends flixel.FlxSprite
{
    public var amountNeeded:Int = 0;
    
    public function new (tall = false, x = 0.0, y = 0.0, width = 64, height = 32, amountNeeded = 32)
    {
        super(x, y, tall ? AssetPaths.door_tall__png : AssetPaths.door__png);
        setGraphicSize(width, height);
        updateHitbox();
        immovable = true;
        this.amountNeeded = amountNeeded;
    }
    
    static public function fromOgmo(data:EntityData)
    {
        return new Lock
            ( data.name == "locked_tall"
            , data.x, data.y
            , data.width, data.height
            , data.values.amountNeeded
            );
    }
}