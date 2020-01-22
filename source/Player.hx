package;

import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.FlxG;
import flixel.FlxSprite;

class Player extends FlxSprite
{

    private var speed:Float = 1400;
    private var baseJumpStrength:Float = 120;
    private var apexReached:Bool = true;
    private var canJump:Bool = false;

    // Not a boost per se, simply a counter for the cos wave thing
    private var jumpBoost:Int = 0;


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
        animation.add('walk', [1, 2, 2, 0], 12);
        animation.add('jumping', [2]);

        animation.play("idle");

        height -= 2;
        width -= 12;
        offset.x = 6;

        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);

        drag.x = 700;
        maxVelocity.x = 230;
        maxVelocity.y = 520;
    }

    override public function update(e:Float):Void
    {

        if (!wallClimbing)
        {
            acceleration.y = 2500;
            drag.y = 2000;
        }
        else
        {
            if (velocity.y > 0)
                drag.y = 1000;
            else
                drag.y = 1200;
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


        // THESE VARIABLES HAVE UNDERSCORES SIMPLY BECAUSE I COPY PASTED IT FROM CITYHOPPIN LMAOOO
        // https://github.com/ninjamuffin99/cityhoppin/blob/master/source/player/Player4Keys.hx
        var _upR:Bool = false;
		var _downR:Bool = false;
		var _leftR:Bool = false;
		var _rightR:Bool = false;
		
		_upR = FlxG.keys.anyJustReleased([UP, W, SPACE]);
		_downR = FlxG.keys.anyJustReleased([DOWN, S]);
		_leftR = FlxG.keys.anyJustReleased([LEFT, A]);
        _rightR = FlxG.keys.anyJustReleased([RIGHT, D]);
        

		var _downP:Bool = false;
		var _leftP:Bool = false;
		var _rightP:Bool = false;
		
		_downP = FlxG.keys.anyJustPressed([DOWN, S]);
		_leftP = FlxG.keys.anyJustPressed([LEFT, A]);
        _rightP = FlxG.keys.anyJustPressed([RIGHT, D]);
        



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

        wallJumping();      
        
        if (isTouching(FlxObject.FLOOR))
        {
            doubleJumped = false;
            jumped = false;
            hovering = false;
            apexReached = false;
            canJump = true;
            jumpBoost = 0;
            coyoteTime = 0;

            if (jumpP)
            {
                //velocity.y -= 480;
                velocity.y -= baseJumpStrength * 2;
                jumped = true;
                FlxG.sound.play(AssetPaths.jump__mp3, 0.5);
            }   
        }
        else
        {
            animation.play('jumping');

            if (isTouching(FlxObject.CEILING))  
                apexReached = true;

            if (jump && !apexReached && canJump)
            {
                jumpBoost++;

                var C = FlxMath.fastCos(10.7 * jumpBoost * FlxG.elapsed);
                FlxG.watch.addQuick('Cos', C);
                if (C < 0)
                {
                    apexReached = true;
                }
                else
                {
                    velocity.y -= C * (baseJumpStrength * 1.6) * 2;
                }
            }

            if (_upR)
                apexReached = true;

            if (!jumped)
                coyoteTime += FlxG.elapsed;

            if (jumpP && !doubleJumped && !wallClimbing)
            {
                velocity.y = 0;
                if ((velocity.x > 0 && left) || (velocity.x < 0 && right))
                {
                    //velocity.y -= 200;
                    //velocity.x *= -0.1;
                }
                    
                velocity.y -= 600;
                doubleJumped = true;
                FlxG.sound.play(AssetPaths.doubleJump__mp3, 0.75);
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
                    acceleration.y = -speed * 0.8;
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