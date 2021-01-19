package props;

import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.geom.Rectangle;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

@:allow(props.Player)
class Tail extends FlxSprite
{
    inline static var TILE_SIZE = Player.TILE_SIZE;
    inline static var TILE_SIZE_HALF = Player.TILE_SIZE >> 1;
    inline static var LENGTH = 64;
    inline static var WHIP_TIME = 0.15;
    
    public var state(default, null):State = Idle;
    public var holdTail = false;
    public var whipRight(default, null) = true;
    
    public var length(default, null) = 0.0;
    public var endX(get, never):Float;
    public var endY(get, never):Float;
    var timer = 0.0;
    
    function new ()
    {
        super();
        makeGraphic(LENGTH, 4, FlxColor.BLACK);
        graphic.bitmap.fillRect(new Rectangle(1, 1, LENGTH - 2, height - 2), 0xFFffbacf);
        visible = false;
        origin.set(1, 1);
        offset.set(1, 1);
    }
    
    public function checkMapCollision(map:FlxTilemap):Void
    {
        if (map.overlaps(this))
        {
            final index = map.getTileIndexByCoords(FlxPoint.weak(whipRight ? x : x + length, y + height));
            final columns = map.widthInTiles;
            var tileY = Std.int(index / columns);
            var tileX = index % columns;
            
            if (whipRight)
            {
                while (tileX < columns - 1 && map.getTileCollisions(map.getTile(tileX, tileY)) & FlxObject.WALL == 0)
                    tileX++;
            }
            else
            {
                while (tileX > 0 && map.getTileCollisions(map.getTile(tileX, tileY)) & FlxObject.WALL == 0)
                    tileX--;
            }
            
            final buffer = 8;
            if (whipRight)
            {
                final hitX = map.x + tileX * TILE_SIZE;
                setLength(hitX - x + buffer);
            }
            else
            {
                final hitX = map.x + (tileX + 1) * TILE_SIZE;
                setLength(x + length - hitX + buffer);
            }
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        switch(state)
        {
            case Extending:
                
                timer += elapsed;
                if (timer > WHIP_TIME)
                {
                    timer = WHIP_TIME;
                    setState(Extended);
                }
                else
                    setLength(LENGTH * FlxEase.quintOut(timer / WHIP_TIME));
                
            case Retracting:
                
                timer += elapsed;
                if (timer > WHIP_TIME)
                {
                    timer = WHIP_TIME;
                    setState(Idle);
                }
                else
                    setLength(LENGTH * FlxEase.quintOut((WHIP_TIME - timer) / WHIP_TIME));
            case Idle:
            case Extended:
                if (!holdTail)
                    setState(Retracting);
            case Hooking(x, y):
                drawTo(x, y);
        }
    }
    
    inline function whip(toRight:Bool)
    {
        if (state == Idle)
        {
            whipRight = toRight;
            setState(Extending);
        }
    }
    inline function retract():Void setState(Retracting);
    inline function cancel():Void setState(Idle);
    
    function drawTo(x:Float, y:Float)
    {
        var line = FlxVector.get(x - this.x, y - this.y);
        setGraphicSize(Std.int(Math.max(line.length, 1)), Std.int(height));
        angle = line.degrees;
    }
    
    function setState(toState:State)
    {
        final fromState = this.state;
        if (toState == fromState)
            return;
        
        visible = !toState.match(Idle);
        
        switch(toState)
        {
            case Idle:
                setLength(0);
                angle = 0;
            case Extending if (fromState.match(Idle)):
                timer = 0;
            case Extended if (fromState.match(Extending)):
                setLength(LENGTH);
            case Retracting if (fromState.match(Extended)):
                timer = 0;
            case Hooking(x,y) if (fromState.match(Extending | Extended | Retracting)):
                drawTo(x,y);
            default:
                throw 'Invalid state change to:$toState from:$fromState';
        }
        this.state = toState;
    }
    
    function setLength(value:Float):Float
    {
        // if (value == 0)
        //     return length = width = 0;
        
        if (!whipRight)
            x += length - value;
        
        setGraphicSize(Std.int(Math.max(value, 1)), Std.int(height));
        width = value;
        return length = value;
    }
    
    function get_endX()
    {
        return switch state
        {
            case Hooking(x, _): x;
            default: whipRight ? x + length : x;
        }
    }
    
    function get_endY()
    {
        return switch state
        {
            case Hooking(_, y): y;
            default: y;
        }
    }
    
    inline public function isWhipping() return state.match(Extending | Extended | Retracting);
    inline public function isHooked() return state.match(Hooking(_, _));
}
private enum State
{
    Idle;
    Extending;
    Extended;
    Retracting;
    Hooking(x:Float, y:Float);
}