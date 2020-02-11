package;

import zero.utilities.OgmoUtils;

class Lock extends flixel.FlxSprite
{
    public var amountNeeded:Int = 0;
    
    public function new (x = 0.0, y = 0.0, width = 64, height = 32, amount = 32)
    {
        super(x, y, AssetPaths.door__png);
        setGraphicSize(width, height);
        updateHitbox();
        immovable = true;
        amountNeeded = amount;
    }
    
    static public function fromOgmo(data:EntityData)
    {
        return new Lock(data.x, data.y, data.width, data.height, data.values.amount);
    }
}