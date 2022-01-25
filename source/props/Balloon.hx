package props;

import ui.Minimap;
import data.OgmoTilemap;

import flixel.FlxSprite;

class Balloon extends FlxSprite implements Bouncer
{
    static inline var POP_TIME = 5;
    static inline var BLINK_TIME = 0.5;
    static inline var BLINK_RATE = 0.1;
    
    public var bumpMin(default, null) = 1.0;
    public var bumpMax(default, null) = 1.0;
    
    var timer = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x + 2, y + 19);
        loadGraphic("assets/images/balloon.png", true, 32, 32);
        offset.x = 4;
        offset.y = 6;
        width -= offset.x * 2;
        height -= offset.y * 2;
    }
    
    public function pop()
    {
        solid = false;
        visible = false;
        timer = POP_TIME;
    }
    
    function unpop()
    {
        solid = true;
        visible = true;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (timer > 0)
        {
            timer -= elapsed;
            if (timer <= 0)
                unpop();
            else if (timer < BLINK_TIME)
                visible = (timer % BLINK_RATE) > (BLINK_RATE / 2);
        }
    }
    
    static public function fromOgmo(data:EntityData)
    {
        return new Balloon(data.x, data.y);
    }
    
    static public function forEachFromMap(map:OgmoTilemap, handler:Balloon->Void)
    {
        map.swapAllTiles(BALLOON, (p)->handler(new Balloon(p.x, p.y)));
    }
}