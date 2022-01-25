package props;

import props.Player;

import flixel.FlxSprite;

enum abstract PowerUpType(String)
{
    var TAIL_WHIP = "tail_whip";
    /** Double jump in da house */
    var AIR_HOP = "air_hop";
    /** Able to jump after walking off a ledge. NOT coyote jumping, just a different air hop */
    var LATE_HOP = "late_hop";
    
    static var list = [TAIL_WHIP, AIR_HOP, LATE_HOP];
    
    static public function validate(str:String)
    {
        var type:PowerUpType = cast str;
        if (list.contains(type))
            return type;
        
        throw "Unexpected PowerUpType: " + str;
    }
}

class PowerUp extends FlxSprite
{
    public var type(default, null):PowerUpType;
    
    public function new (type:PowerUpType, x = 0.0, y = 0.0)
    {
        this.type = type;
        super(x, y);
        this.makeGraphic(32, 32, 0xFFff0000);
    }
    
    static public function fromOgmo(data:EntityData)
    {
        return new PowerUp(cast data.values.ability, data.x, data.y);
    }
}