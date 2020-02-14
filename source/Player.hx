package;

import Dust;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;

class Player extends FlxSprite
{
    static inline var USE_NEW_SETTINGS = true;
    
    static inline var TILE_SIZE = 32;
    public static inline var MAX_APEX_TIME = USE_NEW_SETTINGS ? 0.35 : 0.35;
    public static inline var MIN_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 1.5 : 2.5);
    public static inline var MAX_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 3.5 : 4.5);
    public static inline var AIR_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 2.0 : 2.0);
    public static inline var FALL_JUMP = TILE_SIZE * (USE_NEW_SETTINGS ? 3.0 : 4.0);
    
    static inline var MIN_APEX_TIME = 2 * MAX_APEX_TIME * MIN_JUMP / (MIN_JUMP + MAX_JUMP);
    static inline var GRAVITY = 2 * MIN_JUMP / MIN_APEX_TIME / MIN_APEX_TIME;
    static inline var JUMP_SPEED = -2 * MIN_JUMP / MIN_APEX_TIME;
    static inline var JUMP_HOLD_TIME = (MAX_JUMP - MIN_JUMP) / -JUMP_SPEED;
    static var airJumpSpeed(default, never) = -Math.sqrt(2 * GRAVITY * AIR_JUMP);
    
    public inline static var JUMP_DISTANCE = TILE_SIZE * (USE_NEW_SETTINGS ? 5 : 5);
    public inline static var GROUND_SLOW_DOWN_TIME = (USE_NEW_SETTINGS ? 0.3 : 0.135);
    public inline static var GROUND_SPEED_UP_TIME  = (USE_NEW_SETTINGS ? 0.25 : 0.16);
    public inline static var AIR_SLOW_DOWN_TIME    = (USE_NEW_SETTINGS ? 0.2 : 0.135);
    public inline static var AIR_SPEED_UP_TIME     = (USE_NEW_SETTINGS ? 0.36 : 0.16);
    public inline static var AIRHOP_SPEED_UP_TIME  = (USE_NEW_SETTINGS ? 0.5 : 0.5);
    public inline static var FALL_SPEED = (USE_NEW_SETTINGS ? -JUMP_SPEED : 520.0);
    
    inline static var MAXSPEED = JUMP_DISTANCE / MAX_APEX_TIME / 2;
    inline static var GROUND_ACCEL = MAXSPEED / GROUND_SPEED_UP_TIME;
    inline static var AIR_ACCEL = MAXSPEED / AIR_SPEED_UP_TIME;
    inline static var AIRHOP_ACCEL = MAXSPEED / AIRHOP_SPEED_UP_TIME;
    inline static var GROUND_DRAG = MAXSPEED / GROUND_SLOW_DOWN_TIME;
    inline static var AIR_DRAG = MAXSPEED / AIR_SLOW_DOWN_TIME;
    
    private var baseJumpStrength:Float = 120;
    private var apexReached:Bool = true;

    // Not a boost per se, simply a counter for the cos wave thing
    private var jumpBoost:Int = 0;

    public var gettingHurt:Bool = false;
    
    /** Input buffering, allow normal jump slightly after walking off a ledge */
    static inline var COYOTE_TIME = 0.1;
    private var coyoteTimer:Float = 0;
    private var airHopped:Bool = false;
    private var jumped:Bool = false;
    private var jumpTimer:Float = 0;
    private var hovering:Bool = false;
    private var wallClimbing:Bool = false;
    public var onGround      (default, null):Bool = false;
    public var wasOnGround   (default, null):Bool = false;
    public var onCoyoteGround(default, null):Bool = false;
    
    public var dust:FlxTypedGroup<Dust> = new FlxTypedGroup();
    public var platform:MovingPlatform = null;
    
    public var cheese = new List<Cheese>();
    
    var left:Bool;
    var right:Bool;
    var jump:Bool;
    var jumpP:Bool;
    var down:Bool;

    public function new(x:Float, y:Float):Void
    {
        super(x, y);

        loadGraphic(AssetPaths.ritz_spritesheet__png, true, 32, 32);
        animation.add('idle', [0]);
        animation.add('walk', [1, 2, 2, 0], 12);
        animation.add('jumping', [2]);
        animation.add('skid', [3]);
        animation.add('falling', [4]);
        animation.add('fucking died lmao', [7, 8, 9, 10, 11], 12);

        animation.play("idle");

        width  -= 20;
        height -= 8;
        offset.y = 6;
        offset.x = 10;

        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);
        
        drag.x = AIR_DRAG;
        acceleration.y = GRAVITY;
        maxVelocity.x = MAXSPEED;
        maxVelocity.y = FALL_SPEED;
    }
    
    public function hurtAndRespawn(x, y):Void
    {
        for (c in cheese)
            c.resetToSpawn();
        cheese.clear();
        
        gettingHurt = true;
        animation.play('fucking died lmao');
        FlxG.sound.play('assets/sounds/damageTaken' + BootState.soundEXT, 0.6);

        new FlxTimer().start(0.5, (_)->respawn(x, y));
    }
    
    public function respawn(x, y):Void
    {
        reset(x, y);
        platform = null;
        gettingHurt = false;
        acceleration.y = GRAVITY;
    }

    override public function update(elapsed:Float):Void
    {
        if (gettingHurt)
        {
            velocity.set();
            acceleration.set();
        }
        else
        {
            movement(elapsed);
        }
        super.update(elapsed);
    }

    static final leftButtons :Array<FlxGamepadInputID> = [DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT ];
    static final rightButtons:Array<FlxGamepadInputID> = [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT];
    static final jumpButtons :Array<FlxGamepadInputID> = [A];
    static final downButtons :Array<FlxGamepadInputID> = [DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN ];
    
    static final jumpKeys :Array<FlxKey> = [SPACE, W, UP, Z, Y];
    static final downKeys :Array<FlxKey> = [DOWN, S];
    static final leftKeys :Array<FlxKey> = [LEFT, A];
    static final rightKeys:Array<FlxKey> = [RIGHT, D];
    private function movement(elapsed:Float):Void
    {
        
        jump  = FlxG.keys.anyPressed(jumpKeys);
        down  = FlxG.keys.anyPressed(downKeys);
        left  = FlxG.keys.anyPressed(leftKeys);
        right = FlxG.keys.anyPressed(rightKeys);
        
        var jumpR  = FlxG.keys.anyJustReleased(jumpKeys);
        var downR  = FlxG.keys.anyJustReleased(downKeys);
        var leftR  = FlxG.keys.anyJustReleased(leftKeys);
        var rightR = FlxG.keys.anyJustReleased(rightKeys);
        
        var jumpP  = FlxG.keys.anyJustPressed(jumpKeys);
        var downP  = FlxG.keys.anyJustPressed(downKeys);
        var leftP  = FlxG.keys.anyJustPressed(leftKeys);
        var rightP = FlxG.keys.anyJustPressed(rightKeys);
        
        var gamepad = FlxG.gamepads.lastActive;
        if (gamepad != null)
        {
            left  = left  || gamepad.anyPressed(leftButtons);
            right = right || gamepad.anyPressed(rightButtons);
            jump  = jump  || gamepad.anyPressed(jumpButtons);
            down  = down  || gamepad.anyPressed(downButtons);
            
            leftP  = leftP  || gamepad.anyJustPressed(leftButtons);
            rightP = rightP || gamepad.anyJustPressed(rightButtons);
            jumpP  = jumpP  || gamepad.anyJustPressed(jumpButtons);
            downP  = downP  || gamepad.anyJustPressed(downButtons);
            
            leftR  = leftR  || gamepad.anyJustReleased(leftButtons);
            rightR = rightR || gamepad.anyJustReleased(rightButtons);
            jumpR  = jumpR  || gamepad.anyJustReleased(jumpButtons);
            downR  = downR  || gamepad.anyJustReleased(downButtons);
        }
        
        if (velocity.y > 0)
            maxVelocity.y = FALL_SPEED;
        
        wasOnGround = onGround;
        onGround = isTouching(FlxObject.FLOOR);
        if (onGround)
        {
            coyoteTimer = 0;
            onCoyoteGround = true;
            
            if (!wasOnGround)
                makeDust(Land);
        }
        else if (coyoteTimer < COYOTE_TIME)
        {
            coyoteTimer += elapsed;
            onCoyoteGround = true;
        }
        else
            onCoyoteGround = false;
        
        if (onGround != wasOnGround)
            drag.x = onGround ? GROUND_DRAG : AIR_DRAG;
        
        if (isTouching(FlxObject.CEILING) || jumpR)
            apexReached = true;
        
        if (left != right)
        {
            var accel:Float = GROUND_ACCEL;
            if (!onCoyoteGround)
            {
                if (airHopped && velocity.y > 0)
                    accel = AIRHOP_ACCEL;
                else
                    accel = AIR_ACCEL;
            }

            // if (hovering)
            //     hoverMulti = 0.6;
            
            acceleration.x = (left ? -1 : 1) * accel;
        }
        else
            acceleration.x = 0;
        
        if (velocity.x != 0)
        {
            facing = velocity.x > 0 ? FlxObject.RIGHT : FlxObject.LEFT;
            if (acceleration.x == 0 || FlxMath.sameSign(velocity.x, acceleration.x))
                animation.play('walk');
            else
            {
                if (onCoyoteGround && animation.curAnim.name == "walk")
                    makeDust(Skid);
                animation.play('skid');
            }
        }
        else if (acceleration.x == 0)
            animation.play('idle');

        //wallJumping();      
        
        if (onCoyoteGround)
        {
            airHopped = false;
            jumped = false;
            hovering = false;
            apexReached = false;
            jumpBoost = 0;
            jumpTimer = 0;

            if (jumpP)
                startJump();
        }
        else
        {
            if (jumped)
                animation.play(velocity.y < 0 ? 'jumping' : "falling");
            
            if (USE_NEW_SETTINGS)
                variableJump_new(elapsed);
            else
            {
                variableJump_old(elapsed);
                jumpTimer = Math.POSITIVE_INFINITY;
            }
            
            
            if (jumpP && !airHopped && !wallClimbing)
            {
                velocity.y = 0;
                
                if (USE_NEW_SETTINGS &&  left != right)
                    velocity.x = maxVelocity.x * (left ? -1 : 1);
                
                // if ((velocity.x > 0 && left) || (velocity.x < 0 && right))
                // {
                //     sorta sidejump style boost thingie
                //     velocity.y -= 200;
                //     velocity.x *= -0.1;
                // }
                    
                // velocity.y = -600;
                velocity.y = airJumpSpeed;
                airHopped = true;
                FlxG.sound.play('assets/sounds/doubleJump' + BootState.soundEXT, 0.75);
            }
        }

        
        
        /* 
        if (airHopped && velocity.y > 0)
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
            airHopped = false;
            hovering = false;
        }
    }
    
    function startJump()
    {
        //quick change jump dir
        if (USE_NEW_SETTINGS && left != right)
            velocity.x = maxVelocity.x * (left ? -1 : 1);
        
        maxVelocity.y = Math.max(-airJumpSpeed, -JUMP_SPEED);
        if (platform != null)
        {
            if (platform.velocity.y < 0)
                maxVelocity.y += -platform.velocity.y;
            
            velocity.y = platform.velocity.y;
            velocity.x += platform.velocity.x;
            platform = null;
        }
        
        velocity.y += JUMP_SPEED;
        jumped = true;
        onGround = false;
        onCoyoteGround = false;
        wasOnGround = true;
        FlxG.sound.play('assets/sounds/jump' + BootState.soundEXT, 0.5);
        coyoteTimer = COYOTE_TIME;
    }
    
    function variableJump_new(elapsed:Float):Void
    {
        if (jump && !apexReached)
        {
            if (!jumped)
            {
                velocity.y = 0;
                startJump();
            }
            
            jumpTimer += elapsed;
            if (jumpTimer < JUMP_HOLD_TIME)
            {
                if (velocity.y > JUMP_SPEED)
                    velocity.y = JUMP_SPEED;
            }
            else
            {
                jumpTimer = JUMP_HOLD_TIME;
                apexReached = true;
            }
        }
    }
    
    function variableJump_old(elapsed:Float):Void
    {
        if (jump && !apexReached)
        {
            jumped = true;
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
                    acceleration.y = -GROUND_ACCEL * 0.8;
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
    
    function makeDust(type:DustType):Dust
    {
        var newDust = dust.recycle(Dust);
        newDust.place(type, x + width / 2, y + height, flipX);
        if (type == Skid)
        {
            newDust.x += (flipX ? 1 : -1) * width;
            newDust.velocity.x = velocity.x / 4;
            newDust.drag.x = Math.abs(newDust.velocity.x) * 2;
        }
        return newDust;
    }
}