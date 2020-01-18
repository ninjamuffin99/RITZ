package;

import flixel.FlxObject;
import flixel.FlxG;
import flixel.FlxSprite;

class Player extends FlxSprite
{

    private var speed:Float = 1400;
    private var doubleJumped:Bool = false;
    private var jumped:Bool = false;
    private var coyoteTime:Float = 0;
    private var hovering:Bool = false;

    public function new(x:Float, y:Float):Void
    {
        super(x, y);

        makeGraphic(32, 32);

        drag.x = 700;
        maxVelocity.x = 1100;
    }

    override public function update(e:Float):Void
    {
        movement();
        super.update(e);

        acceleration.y = 900;

        

    }

    private function movement():Void
    {
        var left:Bool = FlxG.keys.anyPressed(['LEFT', 'A']);
        var right:Bool = FlxG.keys.anyPressed(['RIGHT', 'D']);

        var jump:Bool = FlxG.keys.anyPressed(['SPACE', 'W', 'UP']);
        var jumpP:Bool = FlxG.keys.anyJustPressed(['SPACE', "W", 'UP', 'Z']);

        if (left && right)
            left = right = false;

        if (left || right)
        {
            if (left)
            {
                acceleration.x = -speed;
            }
            if (right)
            {
                acceleration.x = speed;
            }
        }
        else
            acceleration.x = 0;
        
        if (isTouching(FlxObject.FLOOR))
        {
            doubleJumped = false;
            jumped = false;
            coyoteTime = 0;

            if (jump)
            {
                velocity.y -= 600;
                jumped = true;
            }   
        }



        if (!isTouching(FlxObject.FLOOR))
        {
            if (!jumped)
                coyoteTime += FlxG.elapsed;

            if (jumpP && !doubleJumped)
            {
                velocity.y = 0;
                velocity.y -= 500;
                
                doubleJumped = true;
            }
            
        }

        if (jump && doubleJumped && velocity.y > 0)
        {
            hovering = true;
        }
        else
            hovering = false;


        if (hovering)
        {
            velocity.y = 100;
            drag.x = 1700;
        }
        else
        {
            drag.x = 700;
        }
    }
}