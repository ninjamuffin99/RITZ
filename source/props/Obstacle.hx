package props;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;

class Obstacle extends FlxSprite
{
    public function new(x:Float, y:Float) {
        super(x, y);

        // makeGraphic(32, 16, FlxColor.BLUE);
    }
    
    public function hitObject(obj:FlxObject):Bool { return true; }
    
    public static function overlap
        ( obstacles:FlxTypedGroup<Obstacle>
        , objectOrGroup:FlxBasic
        , ?notifyCallback:(Obstacle, Dynamic)->Void
        ):Bool
    {
        return FlxG.overlap(obstacles, objectOrGroup, notifyCallback, processCallback);
    }
    static function processCallback(obstacle:Obstacle, victim:FlxBasic):Bool
    {
        return !Std.is(victim, FlxObject) || obstacle.hitObject(cast victim);
    }
}