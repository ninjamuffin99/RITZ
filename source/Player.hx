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
    private var wallClimbing:Bool = false;

    var left:Bool;
    var right:Bool;
    var jump:Bool;
    var jumpP:Bool;
    var down:Bool;

    public function new(x:Float, y:Float):Void
    {
        super(x, y);

        loadGraphic(AssetPaths.ritz__png, true, 32, 32);
        animation.add('idle', [0]);
        animation.add('walk', [0, 1, 2, 2], 12);
        animation.add('jumping', [2]);

        animation.play("idle");

        height -= 2;
        width -= 12;
        offset.x = 6;

        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);

        drag.x = 700;
        maxVelocity.x = 150;
        maxVelocity.y = 520;
    }

    override public function update(e:Float):Void
    {

        if (!wallClimbing)
        {
            acceleration.y = 900;
            drag.y = 0;
        }
        else
        {
            if (velocity.y > 0)
                drag.y = 700;
            else
                drag.y = 1000;
        }
            

        movement();
        super.update(e);

        

        

    }

    private function movement():Void
    {
        left = FlxG.keys.anyPressed(['LEFT', 'A']);
        right = FlxG.keys.anyPressed(['RIGHT', 'D']);
        jump = FlxG.keys.anyPressed(['SPACE', 'W', 'UP']);
        jumpP = FlxG.keys.anyJustPressed(['SPACE', "W", 'UP', 'Z']);
        down = FlxG.keys.anyPressed(['S', 'DOWN']);

        if (left && right)
            left = right = false;

        if ((left || right))
        {
            if (velocity.x != 0)
                animation.play('walk');

            var hoverMulti:Float = 1;

            if (!isTouching(FlxObject.FLOOR) && doubleJumped && velocity.y > 0)
                hoverMulti = 0.3;

            if (hovering)
                hoverMulti = 0.6;
            
            if (left)
            {
                facing = FlxObject.LEFT;
                acceleration.x = -speed * hoverMulti;
            }
            if (right)
            {
                facing = FlxObject.RIGHT;
                acceleration.x = speed * hoverMulti;
            }
        }
        else
        {
            acceleration.x = 0;
            animation.play('idle');
        }
            
        
        if (isTouching(FlxObject.FLOOR))
        {
            doubleJumped = false;
            jumped = false;
            hovering = false;
            coyoteTime = 0;

            if (jump)
            {
                velocity.y -= 480;
                jumped = true;
                FlxG.sound.play(AssetPaths.jump__mp3, 0.5);
            }   
        }

        wallJumping();

        



        if (!isTouching(FlxObject.FLOOR))
        {
            animation.play('jumping');

            if (!jumped)
                coyoteTime += FlxG.elapsed;

            if (jumpP && !doubleJumped && !wallClimbing)
            {
                velocity.y = 0;
                if ((velocity.x > 0 && left) || (velocity.x < 0 && right))
                {
                    velocity.y -= 200;
                    velocity.x *= -0.1;
                }
                    
                velocity.y -= 300;
                doubleJumped = true;
                FlxG.sound.play(AssetPaths.doubleJump__mp3, 0.5);
            }
            
        }
        
        /* 
        if (doubleJumped && velocity.y > 0)
        {
            drag.x = 200;

            if (jump)
            {
                hovering = true;
            }
            else
            {
                hovering = false;
            }
        }
        */
        
        if (wallClimbing)
        {
            doubleJumped = false;
            hovering = false;
        }
            


        if (hovering)
        {
            velocity.y = 100;
            drag.x = 150;
        }
        else
        {
            drag.x = 1700;
        }
        
        
    }

    private function wallJumping():Void
    {
        if (isTouching(FlxObject.WALL))
        {
            
            if (jump && down)
                jump = down = false;
            
            if (jump || down)
            {
                if (jump)
                {
                    acceleration.y = -speed;
                }
    
                if (down)
                {
                    acceleration.y = 900;
                }
            }
            else
            {
                acceleration.y = 0;
            }
            
    
    
            wallClimbing = true;
        }
        else
        {
            wallClimbing = false;
        }

    }
}