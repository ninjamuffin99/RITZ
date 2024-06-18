package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;

class Player extends FlxSprite
{

    private var speed:Float = 1400;
    private var baseJumpStrength:Float = 120;
    private var apexReached:Bool = true;
    private var canJump:Bool = false;

    // Not a boost per se, simply a counter for the cos wave thing
	private var jumpBoost:Float = 0;

    public var gettingHurt:Bool = false;


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

        loadGraphic(AssetPaths.ritz_spritesheet__PNG, true, 32, 32);
        animation.add('idle', [0]);
        animation.add('walk', [1, 2, 2, 0], 12);
        animation.add('jumping', [2]);
        animation.add('fucking died lmao', [7, 8, 9, 10, 11], 12);

        animation.play("idle");

		height -= 12;
		offset.y = 11;
        width -= 12;
        offset.x = 6;

        setFacingFlip(LEFT, false, false);
        setFacingFlip(RIGHT, true, false);

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

        if (gettingHurt)
        {
            velocity.set();
            acceleration.set();
        }
        else
        {
            movement();
        }
        super.update(e);
    }

    private function movement():Void
    {
        left = FlxG.keys.anyPressed(['LEFT', 'A']);
        right = FlxG.keys.anyPressed(['RIGHT', 'D']);
        jump = FlxG.keys.anyPressed(['SPACE', 'W', 'UP', 'Z']);
        jumpP = FlxG.keys.anyJustPressed(['SPACE', "W", 'UP', 'Z']);
        down = FlxG.keys.anyPressed(['S', 'DOWN']);


        // THESE VARIABLES HAVE UNDERSCORES SIMPLY BECAUSE I COPY PASTED IT FROM CITYHOPPIN LMAOOO
        // https://github.com/ninjamuffin99/cityhoppin/blob/master/source/player/Player4Keys.hx
        var _upR:Bool = false;
		var _downR:Bool = false;
		var _leftR:Bool = false;
		var _rightR:Bool = false;
		
		_upR = FlxG.keys.anyJustReleased([UP, W, SPACE, Z]);
		_downR = FlxG.keys.anyJustReleased([DOWN, S]);
		_leftR = FlxG.keys.anyJustReleased([LEFT, A]);
        _rightR = FlxG.keys.anyJustReleased([RIGHT, D]);
        

		var _downP:Bool = false;
		var _leftP:Bool = false;
		var _rightP:Bool = false;
		
		_downP = FlxG.keys.anyJustPressed([DOWN, S]);
		_leftP = FlxG.keys.anyJustPressed([LEFT, A]);
        _rightP = FlxG.keys.anyJustPressed([RIGHT, D]);

        var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			if (gamepad.anyPressed(["LEFT", "DPAD_LEFT", "LEFT_STICK_DIGITAL_LEFT"]))
			{
				left = true;
			}
			
			if (gamepad.anyPressed(["RIGHT", "DPAD_RIGHT","LEFT_STICK_DIGITAL_RIGHT"]))
			{
				right = true;
			}

            if (gamepad.anyPressed([A]))
			{
				jump = true;
			}
			
			if (gamepad.anyPressed(["DOWN", "DPAD_DOWN","LEFT_STICK_DIGITAL_DOWN"]))
			{
				down = true;
			}

            if (gamepad.anyJustPressed(["LEFT", "DPAD_LEFT", "LEFT_STICK_DIGITAL_LEFT"]))
			{
				_leftP = true;
			}
			
			if (gamepad.anyJustPressed(["RIGHT", "DPAD_RIGHT","LEFT_STICK_DIGITAL_RIGHT"]))
			{
				_rightP = true;
			}

            if (gamepad.anyJustPressed([A]))
			{
				jumpP = true;
			}
			
			if (gamepad.anyJustPressed(["DOWN", "DPAD_DOWN","LEFT_STICK_DIGITAL_DOWN"]))
			{
				_downP = true;
			}

		}
        



        if (left && right)
            left = right = false;

        if ((left || right))
        {
            if (velocity.x != 0)
                animation.play('walk');

            var hoverMulti:Float = 1;

            if (!isTouching(FLOOR) && doubleJumped && velocity.y > 0)
                hoverMulti = 0.3;

            if (hovering)
                hoverMulti = 0.6;
            
            if (left)
            {
                facing = LEFT;
                acceleration.x = -speed * hoverMulti;
            }
            if (right)
            {
                facing = RIGHT;
                acceleration.x = speed * hoverMulti;
            }
        }
        else
        {
            acceleration.x = 0;
            animation.play('idle');
        }

        //wallJumping();      
        
        if (isTouching(FLOOR))
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
                FlxG.sound.play('assets/sounds/jump' + BootState.soundEXT, 0.5);
            }   
        }
        else
        {
            animation.play('jumping');

            if (isTouching(CEILING))  
                apexReached = true;

            if (jump && !apexReached && canJump)
            {
				jumpBoost += (1 / 60) / FlxG.elapsed;
				var dipshitMultiplier:Float = FlxG.elapsed / (1 / 60);

				var C = FlxMath.fastCos((10.7 * dipshitMultiplier) * jumpBoost * FlxG.elapsed);
                FlxG.watch.addQuick('Cos', C);
                if (C < 0)
                {
                    apexReached = true;
                }
                else
                {
					velocity.y -= (C * (baseJumpStrength * 1.6) * 2);
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
                    // sorta sidejump style boost thingie
                    //velocity.y -= 200;
                    //velocity.x *= -0.1;
                }
                    
                velocity.y -= 600;
                doubleJumped = true;
                FlxG.sound.play('assets/sounds/doubleJump' + BootState.soundEXT, 0.75);
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
        if (isTouching(WALL))
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