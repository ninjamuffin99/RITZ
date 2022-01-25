package props;

import data.OgmoTilemap;
import ui.Minimap;

import flixel.FlxSprite;

class Spring extends FlxSprite implements Bouncer
{
    public var bumpMin(default, null) = 1.0;
    public var bumpMax(default, null) = 1.0;
    
    public function new (x = 0.0, y = 0.0, rotation:Float)
    {
        super(x + 2, y + 19);
        loadGraphic("assets/images/spring.png", true, 32, 32);
        offset.x = 2;
        offset.y = 19;
        width -= offset.x * 2;
        height -= offset.y;
        
        switch(rotation)
        {
            case 0: 
                bumpMin = 1.0;
                bumpMax = 1.0;
            default:
                throw "invalid angle";
        }
    }
    
    static public function fromOgmo(data:EntityData)
    {
        return new Spring(data.x, data.y, data.rotation);
    }
    
    static public function forEachFromMap(map:OgmoTilemap, handler:Spring->Void)
    {
        map.swapAllTiles(SPRING_U, (p)->handler(new Spring(p.x, p.y,   0)));
        map.swapAllTiles(SPRING_R, (p)->handler(new Spring(p.x, p.y,  90)));
        map.swapAllTiles(SPRING_D, (p)->handler(new Spring(p.x, p.y, 180)));
        map.swapAllTiles(SPRING_L, (p)->handler(new Spring(p.x, p.y, -90)));
    }
}